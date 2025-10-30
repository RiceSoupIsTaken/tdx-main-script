-- Configuration
local TARGET_MAP = "Blade Works" 
local SHORT_DELAY = 5
local LONG_DELAY = 15
local DIFFICULTY_VOTE = "Easy"
local TELEPORT_GAME_ID = 9503261072 -- TDX Lobby ID
local MATCH_DURATION_WAIT = 530 -- 9 minutes 30 seconds
local SOLO_CHECK_TIME = 1 -- Time to wait before checking player count

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
    -- 1. Initial Shotgunners (ID 1 & 2) - Upgraded to 4,2
    { type = "place", cost = 325, tower = "Shotgunner", position = vector.create(4.939697742462158, 59.611793518066406, -216.55397033691406) }, -- ID 1
    { type = "place", cost = 325, tower = "Shotgunner", position = vector.create(11.798023223876953, 59.610450744628906, -216.46444702148438) },  -- ID 2

    -- ID 2: P2 L1, P2 L2, P1 L1, P1 L2
    { type = "upgrade", cost = 100, towerId = 2, path = 2 }, 
    { type = "upgrade", cost = 375, towerId = 2, path = 2 }, 
    { type = "upgrade", cost = 200, towerId = 2, path = 1 }, 
    { type = "upgrade", cost = 325, towerId = 2, path = 1 }, 

    -- ID 1: P2 L1, P2 L2, P1 L1, P1 L2
    { type = "upgrade", cost = 100, towerId = 1, path = 2 }, 
    { type = "upgrade", cost = 375, towerId = 1, path = 2 }, 
    { type = "upgrade", cost = 200, towerId = 1, path = 1 }, 
    { type = "upgrade", cost = 325, towerId = 1, path = 1 }, 

    -- ID 2: P1 L3, P1 L4
    { type = "upgrade", cost = 1950, towerId = 2, path = 1 }, 
    { type = "upgrade", cost = 2400, towerId = 2, path = 1 }, 

    -- ID 1: P1 L3, P1 L4
    { type = "upgrade", cost = 1950, towerId = 1, path = 1 }, 
    { type = "upgrade", cost = 2400, towerId = 1, path = 1 }, 

    -- 2. Shotgunner 3 (ID 3) - Upgraded to 4,2
    { type = "place", cost = 325, tower = "Shotgunner", position = vector.create(4.983882904052734, 59.611785888671875, -219.7416534423828) }, -- ID 3
    
    -- ID 3: P1 L1, P2 L1, P1 L2, P2 L2, P1 L3, P1 L4
    { type = "upgrade", cost = 200, towerId = 3, path = 1 }, 
    { type = "upgrade", cost = 100, towerId = 3, path = 2 }, 
    { type = "upgrade", cost = 325, towerId = 3, path = 1 }, 
    { type = "upgrade", cost = 375, towerId = 3, path = 2 }, 
    { type = "upgrade", cost = 1950, towerId = 3, path = 1 }, 
    { type = "upgrade", cost = 2400, towerId = 3, path = 1 }, 
    
    -- 3. Cryo Blaster 4 (ID 4) - Upgraded to 5,2 
    { type = "place", cost = 225, tower = "Cryo Blaster", position = vector.create(4.586745262145996, 59.61369323730469, -213.0032196044922) }, -- ID 4
    
    -- ID 4: P1 L1, P2 L1, P1 L2, P2 L2, P1 L3, P1 L4, P1 L5
    { type = "upgrade", cost = 225, towerId = 4, path = 1 }, 
    { type = "upgrade", cost = 450, towerId = 4, path = 2 }, -- P2 L1
    { type = "upgrade", cost = 400, towerId = 4, path = 1 }, 
    { type = "upgrade", cost = 550, towerId = 4, path = 2 }, -- P2 L2 (Stop here for 5,2)
    { type = "upgrade", cost = 1200, towerId = 4, path = 1 }, 
    { type = "upgrade", cost = 2750, towerId = 4, path = 1 }, 
    { type = "upgrade", cost = 7500, towerId = 4, path = 1 }, -- P1 L5 (The 5 in 5,2)
    
    -- 4. Final SG Upgrades to 5,2
    { type = "upgrade", cost = 10000, towerId = 2, path = 1 }, -- SG 2: P1 L5
    { type = "upgrade", cost = 10000, towerId = 1, path = 1 }, -- SG 1: P1 L5
    { type = "upgrade", cost = 10000, towerId = 3, path = 1 }, -- SG 3: P1 L5

    -- 5. Shotgunner 5 (ID 5) - Upgraded to 5,2
    { type = "place", cost = 325, tower = "Shotgunner", position = vector.create(11.958147048950195, 59.61408996582031, -219.5897216796875) }, -- ID 5
    
    -- ID 5: P1 L1, P1 L2, P2 L1, P2 L2, P1 L3, P1 L4, P1 L5
    { type = "upgrade", cost = 200, towerId = 5, path = 1 }, 
    { type = "upgrade", cost = 325, towerId = 5, path = 1 }, 
    { type = "upgrade", cost = 100, towerId = 5, path = 2 }, 
    { type = "upgrade", cost = 375, towerId = 5, path = 2 }, 
    { type = "upgrade", cost = 1950, towerId = 5, path = 1 }, 
    { type = "upgrade", cost = 2400, towerId = 5, path = 1 }, 
    { type = "upgrade", cost = 10000, towerId = 5, path = 1 }, 

    -- 6. Cryo Blaster 6 (ID 6) - Upgraded to 2,5
    { type = "place", cost = 225, tower = "Cryo Blaster", position = vector.create(11.646870613098145, 59.61048126220703, -223.11021423339844) }, -- ID 6
    
    -- ID 6: P1 L1, P1 L2, P2 L1, P2 L2, P2 L3, P2 L4, P2 L5
    { type = "upgrade", cost = 225, towerId = 6, path = 1 }, -- P1 L1
    { type = "upgrade", cost = 400, towerId = 6, path = 1 }, -- P1 L2 (Stops here for 2,5)
    { type = "upgrade", cost = 450, towerId = 6, path = 2 }, 
    { type = "upgrade", cost = 550, towerId = 6, path = 2 }, 
    { type = "upgrade", cost = 2100, towerId = 6, path = 2 }, 
    { type = "upgrade", cost = 5675, towerId = 6, path = 2 }, 
    { type = "upgrade", cost = 14000, towerId = 6, path = 2 }, 

    -- 7. Remaining Cryo Blasters (ID 7 - 14) - Upgraded to 2,5
    -- CB 7
    { type = "place", cost = 225, tower = "Cryo Blaster", position = vector.create(12.336172103881836, 59.614013671875, -226.0918731689453) }, -- ID 7
    { type = "upgrade", cost = 225, towerId = 7, path = 1 }, 
    { type = "upgrade", cost = 400, towerId = 7, path = 1 },
    { type = "upgrade", cost = 450, towerId = 7, path = 2 }, 
    { type = "upgrade", cost = 550, towerId = 7, path = 2 }, 
    { type = "upgrade", cost = 2100, towerId = 7, path = 2 }, 
    { type = "upgrade", cost = 5675, towerId = 7, path = 2 }, 
    { type = "upgrade", cost = 14000, towerId = 7, path = 2 }, 

    -- CB 8
    { type = "place", cost = 225, tower = "Cryo Blaster", position = vector.create(14.266560554504395, 59.6136360168457, -228.57217407226562) }, -- ID 8
    { type = "upgrade", cost = 225, towerId = 8, path = 1 }, 
    { type = "upgrade", cost = 400, towerId = 8, path = 1 },
    { type = "upgrade", cost = 450, towerId = 8, path = 2 }, 
    { type = "upgrade", cost = 550, towerId = 8, path = 2 }, 
    { type = "upgrade", cost = 2100, towerId = 8, path = 2 }, 
    { type = "upgrade", cost = 5675, towerId = 8, path = 2 }, 
    { type = "upgrade", cost = 14000, towerId = 8, path = 2 }, 
    
    -- CB 9
    { type = "place", cost = 225, tower = "Cryo Blaster", position = vector.create(5.0366668701171875, 59.61177444458008, -223.255859375) }, -- ID 9
    { type = "upgrade", cost = 225, towerId = 9, path = 1 }, 
    { type = "upgrade", cost = 400, towerId = 9, path = 1 },
    { type = "upgrade", cost = 450, towerId = 9, path = 2 }, 
    { type = "upgrade", cost = 550, towerId = 9, path = 2 }, 
    { type = "upgrade", cost = 2100, towerId = 9, path = 2 }, 
    { type = "upgrade", cost = 5675, towerId = 9, path = 2 }, 
    { type = "upgrade", cost = 14000, towerId = 9, path = 2 }, 
    
    -- CB 10
    { type = "place", cost = 225, tower = "Cryo Blaster", position = vector.create(4.880904197692871, 59.6118049621582, -226.31199645996094) }, -- ID 10
    { type = "upgrade", cost = 225, towerId = 10, path = 1 }, 
    { type = "upgrade", cost = 400, towerId = 10, path = 1 },
    { type = "upgrade", cost = 450, towerId = 10, path = 2 }, 
    { type = "upgrade", cost = 550, towerId = 10, path = 2 }, 
    { type = "upgrade", cost = 2100, towerId = 10, path = 2 }, 
    { type = "upgrade", cost = 5675, towerId = 10, path = 2 }, 
    { type = "upgrade", cost = 14000, towerId = 10, path = 2 }, 
    
    -- CB 11
    { type = "place", cost = 225, tower = "Cryo Blaster", position = vector.create(6.013155460357666, 59.6115837097168, -229.71517944335938) }, -- ID 11
    { type = "upgrade", cost = 225, towerId = 11, path = 1 }, 
    { type = "upgrade", cost = 400, towerId = 11, path = 1 },
    { type = "upgrade", cost = 450, towerId = 11, path = 2 }, 
    { type = "upgrade", cost = 550, towerId = 11, path = 2 }, 
    { type = "upgrade", cost = 2100, towerId = 11, path = 2 }, 
    { type = "upgrade", cost = 5675, towerId = 11, path = 2 }, 
    { type = "upgrade", cost = 14000, towerId = 11, path = 2 }, 
    
    -- CB 12
    { type = "place", cost = 225, tower = "Cryo Blaster", position = vector.create(2.013970375061035, 59.61236572265625, -224.58604431152344) }, -- ID 12
    { type = "upgrade", cost = 225, towerId = 12, path = 1 }, 
    { type = "upgrade", cost = 400, towerId = 12, path = 1 },
    { type = "upgrade", cost = 450, towerId = 12, path = 2 }, 
    { type = "upgrade", cost = 550, towerId = 12, path = 2 }, 
    { type = "upgrade", cost = 2100, towerId = 12, path = 2 }, 
    { type = "upgrade", cost = 5675, towerId = 12, path = 2 }, 
    { type = "upgrade", cost = 14000, towerId = 12, path = 2 }, 
    
    -- CB 13
    { type = "place", cost = 225, tower = "Cryo Blaster", position = vector.create(2.833608627319336, 59.612205505371094, -229.4172821044922) }, -- ID 13
    { type = "upgrade", cost = 225, towerId = 13, path = 1 }, 
    { type = "upgrade", cost = 400, towerId = 13, path = 1 },
    { type = "upgrade", cost = 450, towerId = 13, path = 2 }, 
    { type = "upgrade", cost = 550, towerId = 13, path = 2 }, 
    { type = "upgrade", cost = 2100, towerId = 13, path = 2 }, 
    { type = "upgrade", cost = 5675, towerId = 13, path = 2 }, 
    { type = "upgrade", cost = 14000, towerId = 13, path = 2 }, 
    
    -- CB 14
    { type = "place", cost = 225, tower = "Cryo Blaster", position = vector.create(8.245016098022461, 59.611148834228516, -232.0863800048828) }, -- ID 14
    { type = "upgrade", cost = 225, towerId = 14, path = 1 }, 
    { type = "upgrade", cost = 400, towerId = 14, path = 1 },
    { type = "upgrade", cost = 450, towerId = 14, path = 2 }, 
    { type = "upgrade", cost = 550, towerId = 14, path = 2 }, 
    { type = "upgrade", cost = 2100, towerId = 14, path = 2 }, 
    { type = "upgrade", cost = 5675, towerId = 14, path = 2 }, 
    { type = "upgrade", cost = 14000, towerId = 14, path = 2 }, 
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
