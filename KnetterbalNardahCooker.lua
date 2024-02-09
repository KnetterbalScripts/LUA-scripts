--[[
-------------=====CREDITS=====-------------
        Higgins for teaching and GUI.
-------------=====CREDITS=====-------------

-----------=====DESCRIPTION=====-----------
    * Cooks every food in Nardah on the clay oven *
    * Checks bank for amount of raw food. *
    * Will shutdown if out of food. *
-----------=====DESCRIPTION=====-----------

-----------=====HOW TO USE=====------------
    * Set the FoodID you want to cook. *
    * Set the preset to what you are using *
    * Start with full inventory in the bank *
-----------=====HOW TO USE=====------------
]]

local API = require("api")
local startTime = os.time()
MAX_IDLE_TIME_MINUTES = 8
afk = os.time()
local startXp = API.GetSkillXP("COOKING")


local ID = {
    RAW_DESERT_SOLE = 40287,
    RAW_CATFISH = 40289,
    RAW_BELTFISH = 40291,
    RAW_BASS = 43850,
    RAW_COD = 43852,
    RAW_CRAYFISH = 43853,
    RAW_BARON_SHARK = 43855,
    RAW_GREAT_WHITE_SHARK = 43856,
    RAW_LOBSTER = 43859,
    RAW_MANTA_RAY = 43861,
    RAW_MONKFISH = 43863,
    RAW_PIKE = 43864,
    RAW_SALMON = 43865,
    RAW_SARDINE = 43866,
    RAW_SEA_TURTLE = 43867,
    RAW_SHARK = 43868,
    RAW_SHRIMP = 43869,
    RAW_SWORDFISH = 43870,
    RAW_TROUT = 43871,
    RAW_TUNA = 43872,
    RAW_SAILFISH = 43873,
    RAW_GREEN_BLUBBER_JELLYFISH = 43874,
    RAW_BLUE_BLUBBER_JELLYFISH = 43875,
}

----------==Settings==-------------

local FoodID = ID.RAW_BELTFISH
local preset = 2
----------==Settings==-------------

-- ========GUI stuff======== From Higgins !!
local startXp = API.GetSkillXP("COOKING")
local totalFishCooked = 0 -- Variable to store the total number of fish caught


local function round(val, decimal)
    if decimal then
        return math.floor((val * 10 ^ decimal) + 0.5) / (10 ^ decimal)
    else
        return math.floor(val + 0.5)
    end
end

function formatNumber(num)
    if num >= 1e6 then
        return string.format("%.1fM", num / 1e6)
    elseif num >= 1e3 then
        return string.format("%.1fK", num / 1e3)
    else
        return tostring(num)
    end
end

-- Format script elapsed time to [hh:mm:ss]
local function formatElapsedTime(startTime)
    local currentTime = os.time()
    local elapsedTime = currentTime - startTime
    local hours = math.floor(elapsedTime / 3600)
    local minutes = math.floor((elapsedTime % 3600) / 60)
    local seconds = elapsedTime % 60
    return string.format("[%02d:%02d:%02d]", hours, minutes, seconds)
end

local function calcProgressPercentage(skill, currentExp)
    local currentLevel = API.XPLevelTable(API.GetSkillXP(skill))
    if currentLevel == 120 then
        return 100
    end
    local nextLevelExp = XPForLevel(currentLevel + 1)
    local currentLevelExp = XPForLevel(currentLevel)
    local progressPercentage = (currentExp - currentLevelExp) / (nextLevelExp - currentLevelExp) * 100
    return math.floor(progressPercentage)
end

local function printProgressReport(final)
    local skill = "COOKING"
    local currentXp = API.GetSkillXP(skill)
    local elapsedMinutes = (os.time() - startTime) / 60
    local diffXp = math.abs(currentXp - startXp);
    local xpPH = round((diffXp * 60) / elapsedMinutes, 1);
    local time = formatElapsedTime(startTime)
    local currentLevel = API.XPLevelTable(API.GetSkillXP(skill))
    IGP.radius = calcProgressPercentage(skill, API.GetSkillXP(skill)) / 100
    IGP.string_value = time .. " | " .. string.lower(skill):gsub("^%l", string.upper) .. ": " .. currentLevel ..
        " | XP/H: " ..
        formatNumber(xpPH) .. " | XP: " .. formatNumber(diffXp) .. " | Food Cooked: " .. totalFishCooked
end

local function setupGUI()
    IGP = API.CreateIG_answer()
    IGP.box_start = FFPOINT.new(5, 5, 0)
    IGP.box_name = "PROGRESSBAR"
    IGP.colour = ImColor.new(128, 0, 128);
    IGP.string_value = "Knetterbal Nardah Cooker"
end

local function drawGUI()
    DrawProgressBar(IGP)
end

setupGUI()

local function checkbank()
    local items = API.FetchBankArray()
    local foundRawFood = false

    for k, v in pairs(items) do
        if v.itemid1 == FoodID then
            print("Found: " .. v.itemid1_size .. " Raw food.")
            if v.itemid1_size > 0 then
                foundRawFood = true
                return -- Exit the function immediately if raw food is found
            end
        end
    end

    -- If no raw food is found, perform necessary actions
    print("Out of Raw food.")
    FoodBanked = false
    API.Write_LoopyLoop(false)
    print("Shutting down.. Get more food :)")
end

local cookingInterface = {
    InterfaceComp5.new(1371, 7, -1, -1, 0),
}

local function cookingInterfacePresent()
    local result = API.ScanForInterfaceTest2Get(true, cookingInterface)
    return #result > 0
end

local function cook()
    if API.InvItemcount_1(FoodID) > 0 and not API.isProcessing() and not API.CheckAnim(10) then
        --API.DoAction_Object_string1(0x5, 80, { "Clay Oven" }, 50, false)
        API.DoAction_Object1(0x40, 0, { 10377 }, 50)
        API.RandomSleep2(4000, 1000, 1500)
        -- Now we check if the cooking interface is open before performing the action
    end
end

local function bank()
    if not API.BankOpen2() and not API.CheckAnim(10) then
        API.DoAction_Object_string1(0x5, 80, { "Bank booth" }, 50, false) -- Interact with chest
        API.RandomSleep2(3500, 1000, 1500)
    end
end

local function invCheck()
    if API.InvItemcount_1(FoodID) == 0 and not API.BankOpen2() and not API.isProcessing() then
        print("Banking...")
        bank()
    end
end

local function idleCheck()
    local timeDiff = os.difftime(os.time(), afk)
    local randomTime = math.random((MAX_IDLE_TIME_MINUTES * 60) * 0.6, (MAX_IDLE_TIME_MINUTES * 60) * 0.9)

    if timeDiff > randomTime then
        API.PIdle2()
        afk = os.time()
    end
end

totalFishCooked = 0
local lastXP = API.GetSkillXP("COOKING") -- Initialize lastXP to the current XP

local function checkForXPDrop()
    local currentXP = API.GetSkillXP("COOKING")
    if currentXP > lastXP then
        lastXP = currentXP
        totalFishCooked = totalFishCooked + 1 -- Increment totalFishCooked when XP increases
        return true
    else
        return false
    end
end

while API.Read_LoopyLoop(true) do
    drawGUI()
    idleCheck()
    checkForXPDrop()
    if not API.CheckAnim(35) then
        invCheck()
        if API.BankOpen2() then
            checkbank()
            API.DoAction_Interface(0x24, 0xffffffff, 1, 517, 119, preset, 3808)
        else
            cook()
            if cookingInterfacePresent() then
                API.DoAction_Interface(0xffffffff, 0xffffffff, 0, 1370, 30, -1, 2912)
            end
        end
    end




    printProgressReport()
end
