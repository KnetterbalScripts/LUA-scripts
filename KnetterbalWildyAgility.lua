--[[

--==< KnetterbalWildyAgility 1.0 >==--

--==< Credits: Higgins for GUI and teaching me a BUNCH >==--

--==< Description: >==--
- Will do the Wilderness Agility Course
- Will recover if you fail the obstacle (Surefooted is recommended tho)
- Will use Eat food ability when dropping below 60 hp and after an XP drop
- Use Demonic skull for XP boost but BEWARE PK'ers
- GUI is added poorly due to waits in the script. The rates, however, do somewhat compare to Runemetrics

]]

local API = require("api")
local UTILS = require("utils")
local startTime = os.time()
local lastXpDropTime = startTime

local ID = {
    OBSTACLE_PIPE = 65362,
    ROPESWING = 64696,
    STEPPING_STONE = 64699,
    LOG_BALANCE = 64698,
    CLIFFSIDE = 65734,
    LADDER = 32015
}

--== Settings ==--

local foodID = 40293 -- Change this to your specific food ID

--== Settings ==--

local lastXpDropTime = 0 -- Initialize lastXpDropTime variable

local function healthCheck()
    local hp = API.GetHPrecent()
    local xp = API.GetSkillXP("AGILITY")

    if hp < 60 and xp > lastXpDropTime then
        API.WaitUntilMovingandAnimEnds()
        if API.InvItemFound2(foodID) then
            API.DoAction_Ability("Eat Food", 1, API.OFF_ACT_GeneralInterface_route)
            API.RandomSleep2(800, 800, 800)
            lastXpDropTime = xp -- Update lastXpDropTime
        else
            print("Out of food. Stopping the script.")
            API.RandomSleep2(2000, 2000, 2000) -- Add a sleep for visibility
            API.Write_LoopyLoop(false)         -- Stop the script if out of food
            return false                       -- Stop the script if out of food
        end
    end

    return true -- Continue script execution
end

-- ========GUI stuff========

local startXp = API.GetSkillXP("AGILITY")

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
    local skill = "AGILITY"
    local currentXp = API.GetSkillXP(skill)
    local elapsedMinutes = (os.time() - startTime) / 60
    local diffXp = math.abs(currentXp - startXp);
    local xpPH = round((diffXp * 60) / elapsedMinutes);
    local time = formatElapsedTime(startTime)
    local currentLevel = API.XPLevelTable(API.GetSkillXP(skill))
    IGP.radius = calcProgressPercentage(skill, API.GetSkillXP(skill)) / 100
    IGP.string_value = time .. " | " .. string.lower(skill):gsub("^%l", string.upper) .. ": " .. currentLevel ..
        " | XP/H: " .. formatNumber(xpPH) .. " | XP: " .. formatNumber(diffXp)
end

local function setupGUI()
    IGP = API.CreateIG_answer()
    IGP.box_start = FFPOINT.new(5, 5, 0)
    IGP.box_name = "PROGRESSBAR"
    IGP.colour = ImColor.new(6, 82, 221);
    IGP.string_value = "AGILITY"
end

local function drawGUI()
    DrawProgressBar(IGP)
end

setupGUI()

local function sleep()
    API.RandomSleep2(700, 100, 100)
end

local function interact_with_obstacle(id)
    API.DoAction_Object1(0xb5, 0, { id }, 50, API.OFF_ACT_GeneralObject_route0)
end

local function FailedObstacleCheck(currentObstacle)
    if API.PInArea21(2993, 3007, 10340, 10365) then
        print('In the dungeon... Getting out')
        interact_with_obstacle(ID.LADDER)
        API.RandomSleep2(600, 600, 600)
    elseif currentObstacle == ID.ROPESWING then
        print("Need to go to the tile before the ropeswing")
        local targetTile = WPOINT.new(3005 + API.Math_RandomNumber(1), 3951 + API.Math_RandomNumber(1), 0) -- Replace with the correct waypoint
        API.DoAction_Tile(targetTile)                                                                      -- Click on the tile
        API.RandomSleep2(600, 600, 600)                                                                    -- Add another random sleep after ladder interaction
        API.WaitUntilMovingandAnimEnds()                                                                   -- Wait for the animation to end (optional)
    end
end

-- Flags to track obstacle completion
local obstacleCompleted = {
    [ID.OBSTACLE_PIPE] = false,
    [ID.ROPESWING] = false,
    [ID.STEPPING_STONE] = false,
    [ID.LOG_BALANCE] = false,
    [ID.CLIFFSIDE] = false
}

local lastObstacle = nil                 -- Store the last progressed obstacle
local lastXP = API.GetSkillXP("AGILITY") -- Store the last XP

local function checkForXPDrop()
    local currentXP = API.GetSkillXP("AGILITY")
    if currentXP > lastXP then
        lastXP = currentXP
        lastXpDropTime = os.time() -- Update the last XP drop time
        return true
    else
        return false
    end
end

local function obstacleFail(currentObstacle)
    if currentObstacle == ID.ROPESWING then
        FailedObstacleCheck(currentObstacle)
        API.RandomSleep2(600, 600, 600)
        interact_with_obstacle(ID.ROPESWING)
    elseif currentObstacle == ID.LOG_BALANCE then
        FailedObstacleCheck(currentObstacle)
        API.RandomSleep2(600, 600, 600)
        interact_with_obstacle(ID.LOG_BALANCE)
    end
end

local function waitForXPDrop()
    local maxWaitTime = 10
    local startTime = os.time()

    while true do
        if os.time() - startTime > maxWaitTime then
            return false
        end

        if checkForXPDrop() then
            return true
        end

        sleep()
    end
end

local function interactWithObstacle(obstacle)
    interact_with_obstacle(obstacle)
    API.RandomSleep2(800, 800, 800)
    API.WaitUntilMovingandAnimEnds()
    lastObstacle = obstacle
    if obstacle == ID.OBSTACLE_PIPE then
        API.RandomSleep2(600, 600, 600)
    end
end

while API.Read_LoopyLoop(true) do
    if not healthCheck() then
        break
    end

    drawGUI()

    local currentObstacle = lastObstacle or ID.OBSTACLE_PIPE

    if not obstacleCompleted[currentObstacle] then
        interactWithObstacle(currentObstacle)
        if waitForXPDrop() then
            obstacleCompleted[currentObstacle] = true
        else
            if not obstacleFail(currentObstacle) then
                interactWithObstacle(currentObstacle)
            else
                lastObstacle = nil
            end
        end
    else
        if currentObstacle == ID.OBSTACLE_PIPE then
            lastObstacle = ID.ROPESWING
        elseif currentObstacle == ID.ROPESWING then
            lastObstacle = ID.STEPPING_STONE
        elseif currentObstacle == ID.STEPPING_STONE then
            lastObstacle = ID.LOG_BALANCE
        elseif currentObstacle == ID.LOG_BALANCE then
            lastObstacle = ID.CLIFFSIDE
        elseif currentObstacle == ID.CLIFFSIDE then
            lastObstacle = ID.OBSTACLE_PIPE
        end

        obstacleCompleted[currentObstacle] = false
    end

    printProgressReport()
end
