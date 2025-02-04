-- services

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

-- variables

local UI = game:GetObjects("rbxassetid://104460751016406")[1]
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Template = UI.Background.Players.Template
Template.Parent = nil
local ChatLogs = {}
local Connections = {}
local Viewing = nil

-- functions

local function Drag()
    local MouseStart = UserInputService:GetMouseLocation()
    local UIStart = UI.Background.Position

    while task.wait() and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
        local MouseNow = UserInputService:GetMouseLocation()
        local Offset = (MouseNow - MouseStart)

        UI.Background:TweenPosition(UIStart + UDim2.new(0, Offset.X, 0, Offset.Y), "Out", "Linear", 0.01, true)
    end
end

local function Clean()
    for _,v in Connections do
        v:Disconnect()
    end

    Camera.CameraSubject = LocalPlayer.Character
end

local function UpdateSearch()
    local Term = UI.Background.Search.Box.Text:lower()

    for _,v in UI.Background.Players:GetChildren() do
        if not v:IsA("Frame") then continue end
        v.Visible = v.Name:lower():find(Term)
    end
end

local function AddPlayer(Player: Player)
    if not ChatLogs[Player.Name] then
        ChatLogs[Player.Name] = {}
    end

    Player.Chatted:Connect(function(Message: string)
        ChatLogs[Player.Name][Workspace:GetServerTimeNow()] = Message
    end)

    local NewPlayer = Template:Clone()
    NewPlayer.Name = `{Player.DisplayName}_{Player.Name}_{Player.UserId}`
    NewPlayer.User.Text = `{Player.DisplayName}({Player.Name})`
    NewPlayer.Icon.Image = Players:GetUserThumbnailAsync(Player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size180x180)
    NewPlayer.Listen.Visible = Player:FindFirstChild("AudioDeviceInput")
    NewPlayer.Parent = UI.Background.Players

    NewPlayer.View.MouseButton1Down:Connect(function()
        Clean()
        if Viewing == Player then
            Viewing = nil
        else
            Viewing = Player
        end

        if Viewing then
            Connections.Respawn = Player.CharacterAdded:Connect(function(Character: Model)
                Character:WaitForChild("HumanoidRootPart")
                Camera.CameraSubject = Character
            end)
            Camera.CameraSubject = Player.Character
        end
        
        for _,v in UI.Background.Players:GetChildren() do
            if not v:IsA("Frame") then continue end
            
            local IsMe = Viewing and `{Viewing.DisplayName}_{Viewing.Name}_{Viewing.UserId}` == v.Name or false
            v.View.Text = IsMe and "UNVIEW" or "VIEW"
            v.View.BackgroundColor3 = IsMe and Color3.fromRGB(255, 56, 56) or Color3.fromRGB(85, 170, 0)
        end
    end)

    UpdateSearch()
end

local function SetUp()
    for _,v in Players:GetPlayers() do
        if v == LocalPlayer then continue end

        AddPlayer(v)
    end

    UI.Parent = CoreGui
end

SetUp()
UI.Background.Title.MouseButton1Down:Connect(Drag)
UI.Background.Search.Box:GetPropertyChangedSignal("Text"):Connect(UpdateSearch)
Players.PlayerAdded:Connect(AddPlayer)
Players.PlayerRemoving:Connect(function(Player: Player)
    local Exists = UI.Background.Players:FindFirstChild(Player.DisplayName)
    if Exists then
        Exists:Destroy()
    end

    if Viewing and Viewing == Player then
        Clean()
        Viewing = nil
    end
end)
