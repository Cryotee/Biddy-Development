local QBCore = exports['qb-core']:GetCoreObject()

-- Helper function to format logs with timestamp
local function DebugLog(level, message)
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    print(string.format("[%s] [%s] %s", timestamp, level, message))
end

-- Load STD for a player
local function LoadPlayerSTD(citizenid, src)
    DebugLog("DEBUG", "Loading STD for citizenid: " .. citizenid)
    local result = exports.oxmysql:fetchSync("SELECT std FROM player_stds WHERE citizenid = ?", {citizenid})
    if result and result[1] and result[1].std then
        DebugLog("INFO", "Loaded STD: " .. result[1].std .. " for citizenid: " .. citizenid)
        local disease = Config.STDs[result[1].std]
        if disease then
            TriggerClientEvent("QBCore:Notify", src, disease.message, "error")
            if disease.healthDrain == "instant" then
                DebugLog("WARNING", "Player ID: " .. src .. " has Super AIDS, will die in 60 seconds")
                Citizen.CreateThread(function()
                    Citizen.Wait(60000)
                    if QBCore.Functions.GetPlayer(src) then
                        DropPlayer(src, "☠️ You succumbed to an unknown illness.")
                        DebugLog("INFO", "Player ID: " .. src .. " dropped due to Super AIDS")
                    end
                end)
            elseif disease.healthDrain > 0 then
                DebugLog("INFO", "Starting health drain for Player ID: " .. src .. ": -" .. disease.healthDrain .. " HP/min")
                TriggerClientEvent("hooker:startHealthDrain", src, disease.healthDrain)
            end
        else
            DebugLog("ERROR", "Invalid STD loaded: " .. result[1].std .. " for citizenid: " .. citizenid)
        end
    else
        DebugLog("INFO", "No STD found for citizenid: " .. citizenid)
    end
end

-- Save STD for a player
local function SavePlayerSTD(citizenid, std)
    if std then
        exports.oxmysql:executeSync("INSERT INTO player_stds (citizenid, std) VALUES (?, ?) ON DUPLICATE KEY UPDATE std = ?", {citizenid, std, std})
        DebugLog("INFO", "Saved STD: " .. std .. " for citizenid: " .. citizenid)
    else
        exports.oxmysql:executeSync("DELETE FROM player_stds WHERE citizenid = ?", {citizenid})
        DebugLog("INFO", "Cleared STD for citizenid: " .. citizenid)
    end
end

-- Load STDs when player logs in
AddEventHandler("playerConnecting", function(name, setKickReason, deferrals)
    local src = source
    deferrals.defer()
    Citizen.Wait(100)
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        local citizenid = Player.PlayerData.citizenid
        DebugLog("INFO", "Player connecting, checking STD for citizenid: " .. citizenid)
        LoadPlayerSTD(citizenid, src)
        deferrals.done()
    else
        DebugLog("ERROR", "Failed to get player data for ID: " .. src .. " on connect")
        deferrals.done()
    end
end)

-- Charge Player for Service
RegisterNetEvent("hooker:chargePlayer", function(hookerIndex)
    local src = source
    DebugLog("DEBUG", "Processing chargePlayer for Player ID: " .. src .. ", hookerIndex: " .. tostring(hookerIndex))
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then
        DebugLog("ERROR", "Player ID: " .. src .. " not found!")
        TriggerClientEvent("QBCore:Notify", src, "Error: Player data not found!", "error")
        return
    end

    local amount = Config.Hooker.price
    DebugLog("INFO", "Attempting to charge Player ID: " .. src .. " $" .. amount)
    
    if Player.Functions.RemoveMoney("cash", amount, "hooker-service") then
        DebugLog("INFO", "Player ID: " .. src .. " paid $" .. amount .. " for service")
        TriggerClientEvent("hooker:startService", src, hookerIndex)
    else
        DebugLog("ERROR", "Player ID: " .. src .. " does not have enough money")
        TriggerClientEvent("QBCore:Notify", src, "❌ Not enough cash!", "error")
    end
end)

-- Reduce Stress
RegisterNetEvent("hooker:reduceStress", function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player then
        DebugLog("ERROR", "Player ID: " .. src .. " not found for stress reduction")
        return
    end

    DebugLog("INFO", "Reducing stress for Player ID: " .. src)
    TriggerClientEvent("hud:client:UpdateStress", src, 0)
    TriggerClientEvent("QBCore:Notify", src, "😌 You feel completely relieved.", "success")
end)

-- Apply STD to Player
RegisterNetEvent("hooker:applySTD", function(stdType)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local disease = Config.STDs[stdType]

    if not Player then
        DebugLog("ERROR", "Player ID: " .. src .. " not found for STD application")
        return
    end

    if not disease then
        DebugLog("ERROR", "Invalid STD Type: " .. tostring(stdType) .. " for Player ID: " .. src)
        return
    end

    local citizenid = Player.PlayerData.citizenid
    SavePlayerSTD(citizenid, stdType)
    DebugLog("INFO", "Applied STD: " .. stdType .. " to Player ID: " .. src)

    TriggerClientEvent("QBCore:Notify", src, disease.message, "error")

    if disease.healthDrain == "instant" then
        DebugLog("WARNING", "Player ID: " .. src .. " has Super AIDS, will die in 60 seconds")
        Citizen.CreateThread(function()
            Citizen.Wait(60000)
            if QBCore.Functions.GetPlayer(src) then
                DropPlayer(src, "☠️ You succumbed to an unknown illness.")
                DebugLog("INFO", "Player ID: " .. src .. " dropped due to Super AIDS")
            end
        end)
    elseif disease.healthDrain > 0 then
        DebugLog("INFO", "Starting health drain for Player ID: " .. src .. ": -" .. disease.healthDrain .. " HP/min")
        TriggerClientEvent("hooker:startHealthDrain", src, disease.healthDrain)
    end
end)

-- Player Died from Disease
RegisterNetEvent("hooker:playerDiedFromDisease", function()
    local src = source
    DebugLog("WARNING", "Player ID: " .. src .. " died from disease")
    DropPlayer(src, "☠️ Your illness has taken over your body.")
end)

-- Cure STD
RegisterNetEvent("hooker:cureSTD", function(src, medicine)
    -- If called from client, src is the medicine name, and source is the player ID
    if type(src) ~= "number" then
        medicine = src
        src = source
    end
    
    local Player = QBCore.Functions.GetPlayer(src)
    local citizenid = Player and Player.PlayerData.citizenid

    if not Player then
        DebugLog("ERROR", "Player ID: " .. src .. " not found for STD cure")
        return
    end

    DebugLog("DEBUG", "Attempting to cure STD for citizenid: " .. citizenid .. " with medicine: " .. medicine)
    local result = exports.oxmysql:fetchSync("SELECT std FROM player_stds WHERE citizenid = ?", {citizenid})
    local currentSTD = result and result[1] and result[1].std
    local medConfig = Config.Medicines[medicine]

    if not currentSTD then
        DebugLog("INFO", "Player ID: " .. src .. " has no STD to cure")
        TriggerClientEvent("QBCore:Notify", src, "You have no STD to cure!", "error")
        return
    end

    if not medConfig or medConfig.cures ~= currentSTD then
        DebugLog("ERROR", "Medicine " .. medicine .. " cannot cure " .. currentSTD .. " for Player ID: " .. src)
        TriggerClientEvent("QBCore:Notify", src, "This medicine doesn't work for your condition!", "error")
        return
    end

    if not Config.STDs[currentSTD].curable then
        DebugLog("INFO", "STD " .. currentSTD .. " is incurable for Player ID: " .. src)
        TriggerClientEvent("QBCore:Notify", src, "Your condition cannot be cured!", "error")
        return
    end

    SavePlayerSTD(citizenid, nil)
    DebugLog("INFO", "Cured STD " .. currentSTD .. " for Player ID: " .. src)
    TriggerClientEvent("QBCore:Notify", src, "You feel much better now!", "success")
    TriggerClientEvent("hooker:stopHealthDrain", src)
end)

-- Check STD Status
RegisterNetEvent("hooker:checkSTD", function()
    local src = source
    DebugLog("DEBUG", "Processing STD check for Player ID: " .. src)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then
        DebugLog("ERROR", "Player ID: " .. src .. " not found for STD check")
        TriggerClientEvent("QBCore:Notify", src, "Error: Player data not found!", "error")
        return
    end

    local citizenid = Player.PlayerData.citizenid
    DebugLog("DEBUG", "Querying STD for citizenid: " .. citizenid)
    local result = exports.oxmysql:fetchSync("SELECT std FROM player_stds WHERE citizenid = ?", {citizenid})
    local std = result and result[1] and result[1].std
    DebugLog("INFO", "Player ID: " .. src .. " checked STD status: " .. (std or "None"))
    TriggerClientEvent("hooker:receiveSTDStatus", src, std)
end)

-- Register Medicine Items
for medicine, config in pairs(Config.Medicines) do
    QBCore.Functions.CreateUseableItem(medicine, function(source, item)
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player then
            DebugLog("ERROR", "Player ID: " .. src .. " not found for item use: " .. medicine)
            return
        end

        DebugLog("INFO", "Player ID: " .. src .. " used item: " .. medicine)
        if Player.Functions.RemoveItem(medicine, 1) then
            TriggerClientEvent("inventory:client:ItemBox", src, QBCore.Shared.Items[medicine], "remove")
            TriggerEvent("hooker:cureSTD", src, medicine)
        else
            DebugLog("ERROR", "Failed to remove item: " .. medicine .. " from Player ID: " .. src)
            TriggerClientEvent("QBCore:Notify", src, "You don't have that medicine!", "error")
        end
    end)
end