-- Configuration
local TARGET_MAP = "Blade Works" 
local SHORT_DELAY = 5
local LONG_DELAY = 30
local DIFFICULTY_VOTE = "Easy"
local TELEPORT_GAME_ID = 9503261072 -- TDX Lobby ID
local MATCH_DURATION_WAIT = 570 -- 9 minutes 30 seconds
local SOLO_CHECK_TIME = 10 -- Time to wait before checking player count

local APCs = workspace:FindFirstChild("APCs") 

-----------------------------------------------------------
-- Utility Functions
-----------------------------------------------------------

function getCash()
    local player = game:GetService("Players").LocalPlayer
    local cashValue = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Cash")
    return cashValue and cashValue.Value or 0
end

-- Increased wait time to 3 seconds for cash stability 
function waitForCash(minAmount)
    local cash = getCash()
    while cash < minAmount do
        task.wait(3) -- Wait 3 seconds to ensure cash has updated and stabilized
        cash = getCash()
    end
end

function getElevatorFolders()
    local APCs = workspace:WaitForChild("APCs")
    local APCs2 = workspace:WaitForChild("APCs2")
    local elevatorFolders = {}
    
    for i = 1, 10 do
        local folder = APCs:FindFirstChild(tostring(i))
        if folder then table.insert(elevatorFolders, folder) end
    end
    for i = 11, 16 do
        local folder = APCs2:FindFirstChild(tostring(i))
        if folder then table.insert(elevatorFolders, folder) end
    end
    return elevatorFolders
end

function safeFire(remoteName, args)
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Remotes = ReplicatedStorage:WaitForChild("Remotes")
    local remote = Remotes:WaitForChild(remoteName)
    
    pcall(function()
        if args then
            remote:FireServer(unpack(args))
        else
            remote:FireServer()
        end
    end)
    task.wait(0.5)
end

function safeInvoke(remoteName, args)
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Remotes = ReplicatedStorage:WaitForChild("Remotes")
    local remote = Remotes:WaitForChild(remoteName)
    
    local success, result = pcall(function()
        return remote:InvokeServer(unpack(args))
    end)
    task.wait(0.5)
    return success, result
end

function generatePlaceToken()
    return os.clock() + (math.random() * 0.001)
end

-----------------------------------------------------------
-- Tower Placement and Upgrade Sequence Data (STRICT BLOCKS)
-----------------------------------------------------------

local placementAndUpgradeSequence = {
    -- ID 1 & 2: Initial Shotgunners (4,2)
    { type = "place", cost = 325, tower = "Shotgunner", position = vector.create(11.974782943725586, 59.612266540527344, -215.88894653320312) },
    { type = "place", cost = 325, tower = "Shotgunner", position = vector.create(4.968108177185059, 59.611785888671875, -216.96536254882812) }, 
    
    -- ID 1 (4,2)
    { type = "upgrade", cost = 200, towerId = 1, path = 1 }, 
    { type = "upgrade", cost = 325, towerId = 1, path = 1 }, 
    { type = "upgrade", cost = 100, towerId = 1, path = 2 }, 
    { type = "upgrade", cost = 375, towerId = 1, path = 2 }, 
    { type = "upgrade", cost = 1950, towerId = 1, path = 1 }, 
    { type = "upgrade", cost = 2400, towerId = 1, path = 1 }, 

    -- ID 2 (4,2)
    { type = "upgrade", cost = 200, towerId = 2, path = 1 }, 
    { type = "upgrade", cost = 325, towerId = 2, path = 1 }, 
    { type = "upgrade", cost = 100, towerId = 2, path = 2 }, 
    { type = "upgrade", cost = 375, towerId = 2, path = 2 }, 
    { type = "upgrade", cost = 1950, towerId = 2, path = 1 }, 
    { type = "upgrade", cost = 2400, towerId = 2, path = 1 }, 

    -- ID 3: Shotgunner 3 (4,2)
    { type = "place", cost = 325, tower = "Shotgunner", position = vector.create(12.07552719116211, 59.61406707763672, -219.36883544921875) }, 
    { type = "upgrade", cost = 100, towerId = 3, path = 2 }, 
    { type = "upgrade", cost = 375, towerId = 3, path = 2 }, 
    { type = "upgrade", cost = 200, towerId = 3, path = 1 }, 
    { type = "upgrade", cost = 325, towerId = 3, path = 1 }, 
    { type = "upgrade", cost = 1950, towerId = 3, path = 1 }, 
    { type = "upgrade", cost = 2400, towerId = 3, path = 1 }, 

    -- ID 4: Cryo Blaster (5,2)
    { type = "place", cost = 225, tower = "Cryo Blaster", position = vector.create(4.887417793273926, 59.6136360168457, -213.9490966796875) }, 
    { type = "upgrade", cost = 450, towerId = 4, path = 2 }, 
    { type = "upgrade", cost = 550, towerId = 4, path = 2 }, 
    { type = "upgrade", cost = 225, towerId = 4, path = 1 }, 
    { type = "upgrade", cost = 400, towerId = 4, path = 1 }, 
    { type = "upgrade", cost = 1200, towerId = 4, path = 1 }, 
    { type = "upgrade", cost = 2750, towerId = 4, path = 1 }, 
    { type = "upgrade", cost = 7500, towerId = 4, path = 1 }, 

    -- Sell ID 3 and Final Upgrade ID 1 & 2
    { type = "sell", cost = 0, towerId = 3 },
    { type = "upgrade", cost = 10000, towerId = 2, path = 1 }, 
    { type = "upgrade", cost = 10000, towerId = 1, path = 1 }, 

    -- ID 5: EDJ (2,4) - Discount Path 2 completed first
    { type = "place", cost = 2450, tower = "EDJ", position = vector.create(12.339020729064941, 59.614013671875, -225.45384216308594) }, 
    { type = "upgrade", cost = 850, towerId = 5, path = 2 }, 
    { type = "upgrade", cost = 1100, towerId = 5, path = 2 }, 
    { type = "upgrade", cost = 3250, towerId = 5, path = 2 }, 
    { type = "upgrade", cost = 7000, towerId = 5, path = 2 }, 

    -- ID 6: Juggernaut (2,4)
    { type = "place", cost = 6350, tower = "Juggernaut", position = vector.create(14.839522361755371, 59.613525390625, -228.8924560546875) }, 
    { type = "upgrade", cost = 600, towerId = 6, path = 2 }, 
    { type = "upgrade", cost = 3650, towerId = 6, path = 2 }, 
    { type = "upgrade", cost = 7500, towerId = 6, path = 2 }, 
    { type = "upgrade", cost = 14000, towerId = 6, path = 2 }, 

    -- ID 7: EDJ (5,2) - Rate of Fire Path 1 completed first
    { type = "place", cost = 2450, tower = "EDJ", position = vector.create(7.598991394042969, 59.61127471923828, -231.6349334716797) }, 
    { type = "upgrade", cost = 500, towerId = 7, path = 1 }, -- P1 L1
    { type = "upgrade", cost = 1500, towerId = 7, path = 1 }, -- P1 L2
    { type = "upgrade", cost = 4300, towerId = 7, path = 1 }, -- P1 L3
    { type = "upgrade", cost = 5500, towerId = 7, path = 1 }, -- P1 L4
    { type = "upgrade", cost = 19500, towerId = 7, path = 1 }, -- P1 L5 (The expensive part!)

    -- ID 5: EDJ Final Upgrades to 2,5
    { type = "upgrade", cost = 500, towerId = 5, path = 1 }, 
    { type = "upgrade", cost = 1500, towerId = 5, path = 1 }, 
    { type = "upgrade", cost = 4300, towerId = 5, path = 1 }, 
    { type = "upgrade", cost = 5500, towerId = 5, path = 1 }, 
    { type = "upgrade", cost = 19500, towerId = 5, path = 1 }, 

    -- ID 8: Juggernaut (2,4)
    { type = "place", cost = 6350, tower = "Juggernaut", position = vector.create(17.892009735107422, 59.6129264831543, -232.20303344726562) }, 
    { type = "upgrade", cost = 600, towerId = 8, path = 2 }, 
    { type = "upgrade", cost = 3650, towerId = 8, path = 2 }, 
    { type = "upgrade", cost = 7500, towerId = 8, path = 2 }, 
    { type = "upgrade", cost = 14000, towerId = 8, path = 2 }, 

    -- ID 9: Juggernaut (2,4)
    { type = "place", cost = 6350, tower = "Juggernaut", position = vector.create(9.600579261779785, 59.6124267578125, -235.2817840576172) }, 
    { type = "upgrade", cost = 600, towerId = 9, path = 2 }, 
    { type = "upgrade", cost = 3650, towerId = 9, path = 2 }, 
    { type = "upgrade", cost = 7500, towerId = 9, path = 2 }, 
    { type = "upgrade", cost = 14000, towerId = 9, path = 2 }, 

    -- ID 10: Juggernaut (2,4)
    { type = "place", cost = 6350, tower = "Juggernaut", position = vector.create(4.72822380065918, 59.61183547973633, -228.603515625) }, 
    { type = "upgrade", cost = 600, towerId = 10, path = 2 }, 
    { type = "upgrade", cost = 3650, towerId = 10, path = 2 }, 
    { type = "upgrade", cost = 7500, towerId = 10, path = 2 }, 
    { type = "upgrade", cost = 14000, towerId = 10, path = 2 }, 

    -- ID 11: Juggernaut (2,4)
    { type = "place", cost = 6350, tower = "Juggernaut", position = vector.create(20.218395233154297, 59.61244201660156, -238.4785919189453) }, 
    { type = "upgrade", cost = 600, towerId = 11, path = 2 }, 
    { type = "upgrade", cost = 3650, towerId = 11, path = 2 }, 
    { type = "upgrade", cost = 7500, towerId = 11, path = 2 }, 
    { type = "upgrade", cost = 14000, towerId = 11, path = 2 }, 

    -- ID 12: Juggernaut (2,4)
    { type = "place", cost = 6350, tower = "Juggernaut", position = vector.create(19.86153793334961, 59.612510681152344, -245.67332458496094) }, 
    { type = "upgrade", cost = 600, towerId = 12, path = 2 }, 
    { type = "upgrade", cost = 3650, towerId = 12, path = 2 }, 
    { type = "upgrade", cost = 7500, towerId = 12, path = 2 }, 
    { type = "upgrade", cost = 14000, towerId = 12, path = 2 }, 

    -- Juggernauts: Complete Path 1 L1 & L2 for Ability Activation
    { type = "upgrade", cost = 850, towerId = 6, path = 1 }, 
    { type = "upgrade", cost = 1600, towerId = 6, path = 1 }, 
    { type = "upgrade", cost = 850, towerId = 8, path = 1 }, 
    { type = "upgrade", cost = 1600, towerId = 8, path = 1 }, 
    { type = "upgrade", cost = 850, towerId = 9, path = 1 }, 
    { type = "upgrade", cost = 1600, towerId = 9, path = 1 }, 
    { type = "upgrade", cost = 850, towerId = 10, path = 1 }, 
    { type = "upgrade", cost = 1600, towerId = 10, path = 1 }, 
    { type = "upgrade", cost = 850, towerId = 11, path = 1 }, 
    { type = "upgrade", cost = 1600, towerId = 11, path = 1 }, 
    { type = "upgrade", cost = 850, towerId = 12, path = 1 }, 
    { type = "upgrade", cost = 1600, towerId = 12, path = 1 }, 

    -- Final Action: EDJ 5 Ability
    { type = "ability", cost = 0, towerId = 5 } 
}

-----------------------------------------------------------
-- MAIN FARMING LOOP
-----------------------------------------------------------

while true do
    local APCs = workspace:FindFirstChild("APCs") 
    local timerStartTime = 0

    if APCs then
        local function findAndJoinMatch()
            local player = game:GetService("Players").LocalPlayer
            local elevatorFolders = getElevatorFolders()
            local currentDelay = SHORT_DELAY

            while workspace:FindFirstChild("APCs") do
                local matchFoundAndSeated = false
                
                for _, elevator in ipairs(elevatorFolders) do
                    local mapDisplay = elevator:FindFirstChild("mapdisplay")
                    local rampPart = elevator:FindFirstChild("APC") and elevator.APC:FindFirstChild("Ramp")
                    local seatFolder = elevator:FindFirstChild("APC") and elevator.APC:FindFirstChild("Seats")

                    if mapDisplay and rampPart and seatFolder then
                        local mapNamePath = mapDisplay.screen.displayscreen.map
                        local currentMap = mapNamePath and (mapNamePath.ContentText or mapNamePath.Text)
                        
                        local occupantCount = 0
                        for _, seat in ipairs(seatFolder:GetChildren()) do
                            if seat:IsA("Seat") and seat.Occupant then
                                occupantCount = occupantCount + 1
                            end
                        end

                        if currentMap and currentMap:lower():find(TARGET_MAP:lower()) and occupantCount == 0 then
                            
                            local player = game:GetService("Players").LocalPlayer
                            local character = player.Character or player.CharacterAdded:Wait()
                            
                            if character and character.HumanoidRootPart then
                                character.HumanoidRootPart.CFrame = rampPart.CFrame
                                task.wait(0.5)
                                
                                local humanoid = character.Humanoid
                                for _, seat in ipairs(seatFolder:GetChildren()) do
                                    if seat:IsA("Seat") and seat.Occupant == humanoid then
                                        matchFoundAndSeated = true
                                        break 
                                    end
                                end
                                
                                if matchFoundAndSeated then
                                    break
                                end
                            end
                        end
                    end
                end
                
                if matchFoundAndSeated then
                    currentDelay = LONG_DELAY
                    task.wait(currentDelay)
                    if workspace:FindFirstChild("APCs") then
                        currentDelay = SHORT_DELAY
                    end
                else
                    task.wait(currentDelay)
                end
            end
        end

        findAndJoinMatch()
        
    end

    -----------------------------------------------------------
    -- Match Start Sequence & Solo Check
    -----------------------------------------------------------
    task.wait(10)

    if not workspace:FindFirstChild("Enemies") then 
        local voteArgs = { DIFFICULTY_VOTE }
        safeFire("DifficultyVoteCast", voteArgs)
        
        -- SOLO CHECK HERE
        task.wait(SOLO_CHECK_TIME)
        
        local PlayersService = game:GetService("Players")
        if #PlayersService:GetPlayers() > 1 then
            local TeleportService = game:GetService("TeleportService")
            pcall(function()
                TeleportService:Teleport(TELEPORT_GAME_ID)
            end)
            task.wait(10)
            continue
        end

        -- If Solo, continue setup:
        safeFire("DifficultyVoteReady")
        
        local speedArgs = {
            true,
            true
        }
        safeFire("SoloToggleSpeedControl", speedArgs)
        
        timerStartTime = os.clock()
    end
    
    task.wait(5)

    -----------------------------------------------------------
    -- In-Game Farming Loop
    -----------------------------------------------------------

    for i, action in ipairs(placementAndUpgradeSequence) do
        if action.type == "place" then
            waitForCash(action.cost)
            
            local placeArgs = {
                generatePlaceToken(), 
                action.tower, 
                action.position, 
                0
            }
            
            local success, result = safeInvoke("PlaceTower", placeArgs)

        elseif action.type == "upgrade" then
            waitForCash(action.cost) 
            
            local upgradeArgs = {
                action.towerId, 
                action.path, 
                1 
            }
            
            safeFire("TowerUpgradeRequest", upgradeArgs)

        elseif action.type == "sell" then
            local sellArgs = {
                action.towerId
            }
            safeFire("SellTower", sellArgs)

        elseif action.type == "ability" then
            local abilityArgs = {
                action.towerId,
                1 -- Assume ability slot 1
            }
            safeInvoke("TowerUseAbilityRequest", abilityArgs)
        end
    end
    
    -----------------------------------------------------------
    -- Match Duration Wait & Restart Loop
    -----------------------------------------------------------
    
    if timerStartTime > 0 then
        local elapsedTime = os.clock() - timerStartTime
        local remainingTime = MATCH_DURATION_WAIT - elapsedTime
        
        if remainingTime > 0 then
            task.wait(remainingTime)
        else
            task.wait(0) 
        end
    else
        task.wait(60) 
    end

    local TeleportService = game:GetService("TeleportService")
    local maxRetries = 3
    for attempt = 1, maxRetries do
        local success = pcall(function()
            TeleportService:Teleport(TELEPORT_GAME_ID)
        end)
        if success then
            break
        end
        task.wait(5)
    end
    
    task.wait(10)
end
