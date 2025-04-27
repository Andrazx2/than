local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local character = player.Character or player.CharacterAdded:Wait()

-- GUI Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = player.PlayerGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 200, 0, 150)
Frame.Position = UDim2.new(0, 10, 0.5, -75)
Frame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
Frame.BorderSizePixel = 0
Frame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Text = "Jule Tools"
Title.Parent = Frame

-- Hitbox Controls
local hitboxEnabled = false
local hitboxSize = 15

local HitboxButton = Instance.new("TextButton")
HitboxButton.Size = UDim2.new(0.8, 0, 0, 25)
HitboxButton.Position = UDim2.new(0.1, 0, 0.3, 0)
HitboxButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
HitboxButton.TextColor3 = Color3.fromRGB(255, 255, 255)
HitboxButton.Text = "Hitbox: OFF"
HitboxButton.Parent = Frame

local HitboxSize = Instance.new("TextBox")
HitboxSize.Size = UDim2.new(0.8, 0, 0, 25)
HitboxSize.Position = UDim2.new(0.1, 0, 0.5, 0)
HitboxSize.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
HitboxSize.TextColor3 = Color3.fromRGB(255, 255, 255)
HitboxSize.Text = tostring(hitboxSize)
HitboxSize.PlaceholderText = "Hitbox Size"
HitboxSize.Parent = Frame

-- Auto Click Controls
local autoClickEnabled = false
local holdTimer = 0
local holdDuration = 10 -- 10 seconds hold
local holdConnection = nil

-- Fix missing TimeLabel
local TimeLabel = Instance.new("TextLabel")
TimeLabel.Size = UDim2.new(0.8, 0, 0, 20)
TimeLabel.Position = UDim2.new(0.1, 0, 0.85, 0)
TimeLabel.BackgroundTransparency = 1
TimeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TimeLabel.Text = "Time: 0s"
TimeLabel.Parent = Frame

-- Add missing block breaking elements
local blockBreakEnabled = false
local breakTime = 1
local breakProgress = 0
local currentBlock = nil
local breakingConnection = nil

local ProgressBar = Instance.new("Frame")
ProgressBar.Size = UDim2.new(0, 100, 0, 10)
ProgressBar.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
ProgressBar.Visible = false
ProgressBar.Parent = ScreenGui

local ProgressFill = Instance.new("Frame")
ProgressFill.Size = UDim2.new(0, 0, 1, 0)
ProgressFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
ProgressFill.Parent = ProgressBar

-- Block Break Button
local BlockBreakButton = Instance.new("TextButton")
BlockBreakButton.Size = UDim2.new(0.8, 0, 0, 25)
BlockBreakButton.Position = UDim2.new(0.1, 0, 0.9, 0)
BlockBreakButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
BlockBreakButton.TextColor3 = Color3.fromRGB(255, 255, 255)
BlockBreakButton.Text = "Block Break: OFF"
BlockBreakButton.Parent = Frame

-- Add AutoClickButton (add after other GUI elements)
local AutoClickButton = Instance.new("TextButton")
AutoClickButton.Size = UDim2.new(0.8, 0, 0, 25)
AutoClickButton.Position = UDim2.new(0.1, 0, 0.7, 0)
AutoClickButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
AutoClickButton.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoClickButton.Text = "Auto Hold: OFF"
AutoClickButton.Parent = Frame

-- Add block highlight
local blockHighlight = Instance.new("SelectionBox")
blockHighlight.LineThickness = 0.05
blockHighlight.Color3 = Color3.fromRGB(255, 255, 0)
blockHighlight.Parent = ScreenGui

-- Improved Hold Function
local function startHolding()
    holdTimer = 0
    spawn(function()
        if holdConnection then holdConnection:Disconnect() end
        
        -- Initial press
        mouse1press()
        
        holdConnection = RunService.Heartbeat:Connect(function(delta)
            if not autoClickEnabled then
                mouse1release()
                holdConnection:Disconnect()
                TimeLabel.Text = "Time: 0s"
                return
            end
            
            holdTimer = holdTimer + delta
            TimeLabel.Text = string.format("Time: %.1fs", math.min(holdTimer, holdDuration))
            
            if holdTimer >= holdDuration then
                mouse1release()
                autoClickEnabled = false
                holdConnection:Disconnect()
                AutoClickButton.Text = "Auto Hold: OFF"
                AutoClickButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                TimeLabel.Text = "Time: 0s"
            end
        end)
    end)
end

-- Add error handling for hitbox function
local function updateHitbox()
    if not character then return end
    
    pcall(function()
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") and part:FindFirstChild("OriginalSize") then
                if hitboxEnabled then
                    part.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
                    part.Transparency = 0.5
                else
                    part.Size = part.OriginalSize.Value
                    part.Transparency = 0
                end
            end
        end
    end)
end

-- Block Breaking Functions
local function startBreaking(block)
    if not blockBreakEnabled or not block or not block:IsA("BasePart") then return end
    
    currentBlock = block
    breakProgress = 0
    ProgressBar.Visible = true
    
    if breakingConnection then breakingConnection:Disconnect() end
    
    breakingConnection = RunService.RenderStepped:Connect(function(delta)
        if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
            breakProgress = 0
            ProgressFill.Size = UDim2.new(0, 0, 1, 0)
            ProgressBar.Visible = false
            breakingConnection:Disconnect()
            return
        end
        
        breakProgress = math.min(breakProgress + delta, breakTime)
        ProgressFill.Size = UDim2.new(breakProgress/breakTime, 0, 1, 0)
        
        if breakProgress >= breakTime then
            block:Destroy()
            breakProgress = 0
            ProgressFill.Size = UDim2.new(0, 0, 1, 0)
            ProgressBar.Visible = false
            breakingConnection:Disconnect()
        end
    end)
end

-- Mouse Events
mouse.Button1Down:Connect(function()
    local target = mouse.Target
    if target then
        startBreaking(target)
    end
end)

-- Button Handlers
HitboxButton.MouseButton1Click:Connect(function()
    hitboxEnabled = not hitboxEnabled
    HitboxButton.Text = "Hitbox: " .. (hitboxEnabled and "ON" or "OFF")
    HitboxButton.BackgroundColor3 = hitboxEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(60, 60, 60)
    updateHitbox()
end)

HitboxSize.FocusLost:Connect(function()
    local newSize = tonumber(HitboxSize.Text)
    if newSize then
        hitboxSize = newSize
        if hitboxEnabled then
            updateHitbox()
        end
    else
        HitboxSize.Text = tostring(hitboxSize)
    end
end)

-- Update ProgressBar Position
RunService.RenderStepped:Connect(function()
    if currentBlock and ProgressBar.Visible then
        local pos = currentBlock.Position
        local screenPos, onScreen = workspace.CurrentCamera:WorldToScreenPoint(pos)
        if onScreen then
            ProgressBar.Position = UDim2.new(0, screenPos.X - 50, 0, screenPos.Y - 30)
        else
            ProgressBar.Visible = false
        end
    end
end)

-- Add to RunService connection for block highlighting
RunService.RenderStepped:Connect(function()
    local target = mouse.Target
    if target and blockBreakEnabled then
        blockHighlight.Adornee = target
        blockHighlight.Visible = true
        
        -- Make hitbox slightly larger than block
        local size = target.Size
        blockHighlight.SurfaceTransparency = 0.9
        blockHighlight.Transparency = 0
    else
        blockHighlight.Visible = false
    end
end)

-- Initialize
saveOriginalSizes()

-- Character respawn handler
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    wait(1) -- Wait for character to load
    saveOriginalSizes()
    if hitboxEnabled then
        updateHitbox()
    end
end)

print("Combat tools loaded successfully!")
