-- EZR_Compatible.lua
-- Compatible with Xan UI Onboarding
-- Loads EZR features into the selected Xan UI layout

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ✅ EZR Feature Module
local EZR = {}

-- ✅ Initialize Lighting
function EZR.InitLighting()
    Lighting.Brightness = 1
    Lighting.Ambient = Color3.fromRGB(128, 128, 128)
    Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    Lighting.FogEnd = 1000

    for _, effect in pairs(Lighting:GetChildren()) do
        if effect:IsA("PostEffect") then
            effect:Destroy()
        end
    end
end

-- ✅ Rejoin Function
function EZR.Rejoin()
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end

-- ✅ Error Prompt Handler
CoreGui.ChildAdded:Connect(function(child)
    if child:IsA("ScreenGui") and child.Name == "ErrorPrompt" then
        task.wait(2)
        EZR.Rejoin()
    end
end)

-- ✅ Hitbox System
local hitboxScale = 5.0
local hitboxEnabled = false

function EZR.SetHitboxScale(scale)
    hitboxScale = scale
    if hitboxEnabled then
        EZR.UpdateHitboxes()
    end
end

function EZR.ToggleHitboxes(enabled)
    hitboxEnabled = enabled
    if enabled then
        EZR.UpdateHitboxes()
    else
        EZR.RemoveHitboxes()
    end
end

function EZR.UpdateHitboxes()
    for _, model in ipairs(Workspace:GetChildren()) do
        if model:IsA("Model") and model.Name:match("^CLIENT_BALL_%d+$") then
            local ball = model:FindFirstChild("Ball.001")
            if not ball then
                ball = Instance.new("Part")
                ball.Name = "Ball.001"
                ball.Shape = Enum.PartType.Ball
                ball.Size = Vector3.new(2, 2, 2) * hitboxScale
                ball.CFrame = model:GetPivot()
                ball.Anchored = true
                ball.CanCollide = false
                ball.Transparency = 0.7
                ball.Material = Enum.Material.ForceField
                ball.Color = Color3.fromRGB(0, 255, 0)
                ball.Parent = model
            else
                ball.Size = Vector3.new(2, 2, 2) * hitboxScale
            end
        end
    end
end

function EZR.RemoveHitboxes()
    for _, model in ipairs(Workspace:GetChildren()) do
        if model:IsA("Model") and model.Name:match("^CLIENT_BALL_%d+$") then
            local ball = model:FindFirstChild("Ball.001")
            if ball then
                ball:Destroy()
            end
        end
    end
end

-- ✅ Character Features
local autoShiftLock = true
local airMovement = false
local airMovementSpeed = 16
local bodyVelocity = nil

function EZR.SetAutoShiftLock(enabled)
    autoShiftLock = enabled
end

function EZR.SetAirMovement(enabled)
    airMovement = enabled
    if not enabled then
        EZR.RemoveAirControl()
    end
end

function EZR.SetAirSpeed(speed)
    airMovementSpeed = speed
end

function EZR.RemoveAirControl()
    if bodyVelocity then
        bodyVelocity:Destroy()
        bodyVelocity = nil
    end
end

function EZR.ApplyAirControl(rootPart)
    if bodyVelocity then return end
    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(1e5, 0, 1e5)
    bodyVelocity.Velocity = Vector3.zero
    bodyVelocity.P = 2500
    bodyVelocity.Name = "AirControlVelocity"
    bodyVelocity.Parent = rootPart
end

-- ✅ Character Setup
function EZR.SetupCharacter(character)
    local humanoid = character:WaitForChild("Humanoid")
    local rootPart = character:WaitForChild("HumanoidRootPart")

    humanoid:GetPropertyChangedSignal("Jump"):Connect(function()
        if humanoid.Jump and autoShiftLock then
            task.defer(function()
                task.wait(0.03)
                local lookVector = Vector3.new(Camera.CFrame.LookVector.X, 0, Camera.CFrame.LookVector.Z)
                if lookVector.Magnitude > 0 then
                    rootPart.CFrame = CFrame.lookAt(rootPart.Position, rootPart.Position + lookVector.Unit)
                    humanoid.AutoRotate = false
                end
            end)
        else
            humanoid.AutoRotate = true
        end
    end)

    humanoid.StateChanged:Connect(function(_, newState)
        if newState == Enum.HumanoidStateType.Freefall then
            if airMovement then
                EZR.ApplyAirControl(rootPart)
            end
        elseif newState == Enum.HumanoidStateType.Landed then
            EZR.RemoveAirControl()
            humanoid.AutoRotate = true
        end
    end)
end

-- ✅ Visual Features
local nightMode = false
local fullbright = false

function EZR.SetNightMode(enabled)
    nightMode = enabled
    Lighting.Ambient = enabled and Color3.fromRGB(20, 20, 20) or Color3.fromRGB(128, 128, 128)
    Lighting.Brightness = 1
end

function EZR.SetFullbright(enabled)
    fullbright = enabled
    Lighting.Brightness = enabled and 3 or 1
    Lighting.Ambient = enabled and Color3.new(1, 1, 1) or Color3.fromRGB(128, 128, 128)
    Lighting.OutdoorAmbient = enabled and Color3.new(1, 1, 1) or Color3.fromRGB(128, 128, 128)
end

-- ✅ Lines System
local linesEnabled = true
local lineDistance = 50
local lines = {}

function EZR.ToggleLines(enabled)
    linesEnabled = enabled
    if not enabled then
        for player in pairs(lines) do
            EZR.RemoveLine(player)
        end
    end
end

function EZR.SetLineDistance(distance)
    lineDistance = distance
end

function EZR.RemoveLine(player)
    local data = lines[player]
    if data then
        if data.beam then data.beam:Destroy() end
        if data.target then data.target:Destroy() end
        if data.attachment then data.attachment:Destroy() end
        lines[player] = nil
    end
end

function EZR.UpdateLine(player, index)
    if not linesEnabled then
        EZR.RemoveLine(player)
        return
    end

    local character = player.Character
    if not character or not character:FindFirstChild("Head") then
        EZR.RemoveLine(player)
        return
    end

    local head = character.Head
    if not lines[player] then
        local attachment = Instance.new("Attachment", head)
        local target = Instance.new("Part")
        target.Anchored = true
        target.CanCollide = false
        target.Transparency = 1
        target.Size = Vector3.new(0.1, 0.1, 0.1)
        target.Parent = Workspace

        local targetAttachment = Instance.new("Attachment", target)
        local beam = Instance.new("Beam")
        beam.Attachment0 = attachment
        beam.Attachment1 = targetAttachment
        beam.Width0 = 0.25
        beam.Width1 = 0.25
        beam.FaceCamera = true
        beam.LightEmission = 1
        beam.Transparency = NumberSequence.new(0.3)
        beam.Color = ColorSequence.new(Color3.fromHSV((index * 0.1) % 1, 1, 1))
        beam.Parent = head

        lines[player] = {
            beam = beam,
            target = target,
            attachment = attachment
        }
    end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if rootPart then
        lines[player].target.Position = head.Position + rootPart.CFrame.LookVector * lineDistance
    end
end

-- ✅ Render Loop
RunService.RenderStepped:Connect(function()
    if airMovement and bodyVelocity and LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
        if humanoid then
            bodyVelocity.Velocity = humanoid.MoveDirection * airMovementSpeed
        end
    end

    if linesEnabled then
        for index, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Team ~= LocalPlayer.Team then
                EZR.UpdateLine(player, index)
            else
                EZR.RemoveLine(player)
            end
        end
    else
        for player in pairs(lines) do
            EZR.RemoveLine(player)
        end
    end
end)

-- ✅ Character Events
if LocalPlayer.Character then
    EZR.SetupCharacter(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(EZR.SetupCharacter)
Players.PlayerRemoving:Connect(function(player)
    EZR.RemoveLine(player)
end)

-- ✅ Return Module
return EZR
