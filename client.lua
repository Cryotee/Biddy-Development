local QBCore = exports['qb-core']:GetCoreObject()
local hookers = {} -- Table to store hooker peds and their states
local hookerModel = "s_f_y_hooker_01"
local showingUI = false
local displayedHooker = nil

-- Helper function for logging without timestamp
local function DebugLog(level, message)
    print(string.format("[%s] %s", level, message))
end

-- Random service phrases for the hooker to say
local serviceLines = {
    "Hey honey, looking for a good time? $%s and I'm yours.",
    "Need some company tonight? $%s and I'm yours.",
    "You look tense... I can help with that. Just $%s.",
    "Hey handsome, wanna party? $%s for a special service.",
    "I can make all your troubles go away for just $%s.",
}

-- Function to get a random service line
local function GetRandomServiceLine()
    return serviceLines[math.random(#serviceLines)]
end

-- Draw floating text above NPC's head
local function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if onScreen then
        SetTextScale(0.30, 0.30)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
        
        -- Black background with alpha
        local factor = (string.len(text)) / 370
        DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 0, 0, 0, 155)
    end
end

-- Spawn Hookers at all configured locations
function SpawnHookers()
    for i, location in ipairs(Config.Hooker.locations) do
        DebugLog("INFO", "Attempting to spawn hooker at " .. tostring(location.coords))
        RequestModel(hookerModel)
        while not HasModelLoaded(hookerModel) do
            DebugLog("DEBUG", "Waiting for hooker model to load: " .. hookerModel)
            Citizen.Wait(500)
        end

        local hooker = CreatePed(4, GetHashKey(hookerModel), location.coords.x, location.coords.y, location.coords.z - 1.0, location.heading, false, true)
        
        if DoesEntityExist(hooker) then
            DebugLog("INFO", "Hooker spawned successfully at " .. tostring(location.coords))
            SetEntityInvincible(hooker, false)
            SetBlockingOfNonTemporaryEvents(hooker, true)
            FreezeEntityPosition(hooker, true)
            hookers[i] = { ped = hooker, coords = location.coords, isBusy = false }
        else
            DebugLog("ERROR", "Failed to spawn hooker at " .. tostring(location.coords))
        end
    end
end

-- Find nearest hooker
function GetNearestHooker(playerCoords)
    local nearestHooker = nil
    local minDistance = math.huge

    for i, hooker in ipairs(hookers) do
        if not hooker.isBusy then
            local distance = #(playerCoords - hooker.coords)
            if distance < minDistance and distance < 10.0 then
                minDistance = distance
                nearestHooker = hooker
                nearestHooker.index = i
            end
        end
    end

    return nearestHooker
end

-- Detect Honk to Start Service
CreateThread(function()
    while true do
        Citizen.Wait(0)
        local playerPed = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        local playerCoords = GetEntityCoords(playerPed)

        if IsPedInAnyVehicle(playerPed, false) then
            if IsControlJustPressed(0, 86) then
                local nearestHooker = GetNearestHooker(playerCoords)
                if nearestHooker then
                    DebugLog("INFO", "Player honked near hooker at " .. tostring(nearestHooker.coords) .. ", starting service")
                    TriggerServerEvent("hooker:chargePlayer", nearestHooker.index)
                end
            end
        end
    end
end)

-- Service Sequence
RegisterNetEvent("hooker:startService", function(hookerIndex)
    DebugLog("DEBUG", "Received startService event for hookerIndex: " .. tostring(hookerIndex))
    local hookerData = hookers[hookerIndex]
    if not hookerData then
        DebugLog("ERROR", "Service cannot start: hooker data not found for index " .. tostring(hookerIndex))
        TriggerEvent("QBCore:Notify", "Service failed: Hooker not found!", "error")
        return
    end
    if hookerData.isBusy then
        DebugLog("ERROR", "Service cannot start: hooker is busy at index " .. tostring(hookerIndex))
        TriggerEvent("QBCore:Notify", "Service failed: Hooker is busy!", "error")
        return
    end
    if not DoesEntityExist(hookerData.ped) then
        DebugLog("ERROR", "Service cannot start: hooker ped does not exist at index " .. tostring(hookerIndex))
        TriggerEvent("QBCore:Notify", "Service failed: Hooker not found!", "error")
        return
    end

    hookerData.isBusy = true
    local hooker = hookerData.ped
    DebugLog("INFO", "Starting service for player at " .. tostring(hookerData.coords))

    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)

    if vehicle == 0 then
        DebugLog("ERROR", "Player not in vehicle")
        TriggerEvent("QBCore:Notify", "You need to be in a vehicle!", "error")
        hookerData.isBusy = false
        return
    end

    -- Unfreeze ped and ensure it can move
    FreezeEntityPosition(hooker, false)
    ClearPedTasks(hooker)
    DebugLog("DEBUG", "Unfroze hooker and cleared tasks at " .. tostring(hookerData.coords))

    -- Ensure vehicle has an available seat
    local seatAvailable = IsVehicleSeatFree(vehicle, 0)
    if not seatAvailable then
        DebugLog("ERROR", "No available seat in vehicle")
        TriggerEvent("QBCore:Notify", "No available seat in the vehicle!", "error")
        hookerData.isBusy = false
        FreezeEntityPosition(hooker, true)
        return
    end

    DebugLog("DEBUG", "Hooker attempting to enter vehicle, seat 0")
    TaskEnterVehicle(hooker, vehicle, 10000, 0, 2.0, 1, 0)
    Citizen.Wait(5000)

    if GetVehiclePedIsIn(hooker, false) == vehicle then
        DebugLog("INFO", "Hooker successfully entered vehicle")
    else
        DebugLog("ERROR", "Hooker failed to enter vehicle, aborting service")
        TriggerEvent("QBCore:Notify", "Service failed, please try again.", "error")
        hookerData.isBusy = false
        FreezeEntityPosition(hooker, true)
        return
    end

    DebugLog("DEBUG", "Fading screen out")
    DoScreenFadeOut(3000)
    Citizen.Wait(6000)
    DoScreenFadeIn(3000)

    DebugLog("DEBUG", "Hooker exiting vehicle")
    TaskLeaveVehicle(hooker, vehicle, 0)
    Citizen.Wait(2000)

    if GetVehiclePedIsIn(hooker, false) == 0 then
        DebugLog("INFO", "Hooker successfully exited vehicle")
    else
        DebugLog("ERROR", "Hooker failed to exit vehicle")
    end

    DebugLog("DEBUG", "Hooker returning to original position")
    TaskGoStraightToCoord(hooker, hookerData.coords.x, hookerData.coords.y, hookerData.coords.z, 2.0, -1, 0.0, 0.0)
    Citizen.Wait(5000)
    FreezeEntityPosition(hooker, true)

    DebugLog("INFO", "Service completed, triggering stress reduction")
    TriggerServerEvent("hooker:reduceStress")

    if math.random(100) <= Config.Hooker.stdChance then
        local stdType = GetRandomSTD()
        DebugLog("WARNING", "Player contracted STD: " .. stdType .. ", notification will appear in " .. Config.Hooker.notificationDelay .. " seconds")
        
        -- Delayed STD notification and application
        Citizen.CreateThread(function()
            Citizen.Wait(Config.Hooker.notificationDelay * 1000) -- Convert to milliseconds
            DebugLog("INFO", "Delayed STD notification time reached, showing STD symptoms now")
            TriggerServerEvent("hooker:applySTD", stdType)
            TriggerEvent("QBCore:Notify", "You feel... different. Might want to see a doctor. 🤔", "error")
        end)
    end

    DebugLog("INFO", "Resetting hooker for next player at " .. tostring(hookerData.coords))
    hookerData.isBusy = false
end)

-- Random STD Selection
function GetRandomSTD()
    local stds = {}
    for k in pairs(Config.STDs) do table.insert(stds, k) end
    local selected = stds[math.random(#stds)]
    DebugLog("DEBUG", "Selected random STD: " .. selected)
    return selected
end

-- Auto-Spawn Hookers
CreateThread(function()
    Citizen.Wait(5000)
    SpawnHookers()
end)

-- Debug Command to Check STD
RegisterCommand("checkstd", function()
    if not Config.Debug then
        TriggerEvent("QBCore:Notify", "Debug mode is disabled!", "error")
        return
    end
    DebugLog("INFO", "Player requested STD status check")
    TriggerServerEvent("hooker:checkSTD")
end, false)

-- Handle STD Status Response
RegisterNetEvent("hooker:receiveSTDStatus", function(std)
    DebugLog("DEBUG", "Received STD status: " .. (std or "None"))
    if std then
        TriggerEvent("QBCore:Notify", "You have: " .. std, "error")
    else
        TriggerEvent("QBCore:Notify", "You have no STDs.", "success")
    end
end)

-- Client-side Health Drain
RegisterNetEvent("hooker:startHealthDrain", function(drainAmount)
    DebugLog("INFO", "Client-side health drain started: -" .. drainAmount .. " HP/min")
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(60000) -- Wait 1 minute
            local playerPed = PlayerPedId()
            if not DoesEntityExist(playerPed) then
                DebugLog("ERROR", "Player ped not found, stopping health drain")
                break
            end

            local currentHealth = GetEntityHealth(playerPed)
            DebugLog("DEBUG", "Current health: " .. currentHealth .. ", applying drain: -" .. drainAmount)

            if currentHealth <= 100 then
                DebugLog("WARNING", "Player died from disease")
                TriggerServerEvent("hooker:playerDiedFromDisease")
                break
            else
                ApplyDamageToPed(playerPed, drainAmount, false)
                DebugLog("INFO", "Applied " .. drainAmount .. " damage. New health: " .. (currentHealth - drainAmount))
            end
        end
    end)
end)

-- Stop Health Drain when STD is cured
RegisterNetEvent("hooker:stopHealthDrain", function()
    DebugLog("INFO", "Stopping health drain - STD cured")
    -- This event will break the health drain thread since we check within the loop
    -- No need for additional code as the drain thread will naturally end after this event
    TriggerEvent("QBCore:Notify", "You're starting to feel healthier!", "success")
end)

-- UI Thread for hooker speech bubbles
CreateThread(function()
    while true do
        Citizen.Wait(0)
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local nearestHooker = GetNearestHooker(playerCoords)
        
        -- Show UI only when player is close and not busy with service
        if nearestHooker and not nearestHooker.isBusy then
            local distance = #(playerCoords - nearestHooker.coords)
            
            -- Only show text when close enough (within 5.0 units)
            if distance <= 5.0 then
                -- Only update displayed message periodically
                if displayedHooker ~= nearestHooker.index or not showingUI then
                    displayedHooker = nearestHooker.index
                    showingUI = true
                    messageText = string.format(GetRandomServiceLine(), Config.Hooker.price)
                end
                
                -- Get hooker position to draw text
                local hookerPos = GetEntityCoords(nearestHooker.ped)
                
                -- Main service offer text
                DrawText3D(hookerPos.x, hookerPos.y, hookerPos.z + 1.0, messageText)
                
                -- Instruction text
                local instructionText = "~g~Honk~w~ to get my attention"
                if not IsPedInAnyVehicle(playerPed, false) then
                    instructionText = "Get in a ~y~vehicle~w~ and honk"
                end
                
                -- Draw instruction text slightly below the main message
                DrawText3D(hookerPos.x, hookerPos.y, hookerPos.z + 0.85, instructionText)
            else
                -- Reset when moving away from hooker
                if displayedHooker == nearestHooker.index then
                    showingUI = false
                    displayedHooker = nil
                end
            end
        else
            -- No hooker nearby or hooker is busy
            showingUI = false
            displayedHooker = nil
            Citizen.Wait(500) -- Wait longer when no hookers nearby to reduce resource usage
        end
    end
end)