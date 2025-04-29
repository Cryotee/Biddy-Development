Config = {}

-- Debug Mode
Config.Debug = true -- Enables debug commands like /checkstd

-- Hooker System Configurations
Config.Hooker = {
    price = 500,  -- Cost of service
    stdChance = 25, -- 25% chance to get an STD
    notificationDelay = 300, -- Delay in seconds before STD notification appears (300 = 5 minutes)
    locations = { -- List of hooker spawn locations
        { coords = vector3(139.64, -1306.44, 28.95), heading = 0.0 },
        -- Add more locations here, e.g.:
        -- { coords = vector3(x, y, z), heading = 0.0 },
    }
}

-- STD System Configurations
Config.STDs = {
    ["Chlamydia"] = {
        healthDrain = 5, -- Lose 5 HP per minute
        requiresMedicine = true,
        curable = true,
        message = "You feel a burning sensation... maybe see a doctor? 🩺"
    },
    ["Gonorrhea"] = {
        healthDrain = 3,
        requiresMedicine = true,
        curable = true,
        message = "Something feels off down there... 👀"
    },
    ["Syphilis"] = {
        healthDrain = 7,
        requiresMedicine = true,
        curable = true,
        message = "You feel light-headed and dizzy... 🌀"
    },
    ["Herpes"] = {
        healthDrain = 1, -- No health drain, but permanent
        requiresMedicine = true,
        curable = false,
        message = "It comes and goes... but it never leaves. 😞"
    },
    ["HIV"] = {
        healthDrain = 2,
        requiresMedicine = true,
        curable = false,
        message = "Your immune system feels weaker over time. 🦠"
    },
    ["AIDS"] = {
        healthDrain = 10,
        requiresMedicine = false,
        curable = false,
        message = "You feel extremely weak... see a doctor immediately! 🚑"
    },
    ["Super AIDS"] = {
        healthDrain = "instant", -- Kills player in 60 seconds
        requiresMedicine = false,
        curable = false,
        message = "A sudden sickness overtakes your body... it's fatal. ☠️"
    }
}

-- Medicine for STDs
Config.Medicines = {
    ["doxycycline"] = { cures = "Chlamydia" },
    ["ceftriaxone"] = { cures = "Gonorrhea" },
    ["penicillin"] = { cures = "Syphilis" },
    ["antiviral"] = { cures = "HIV" },
}