--[[
ESP LIBRARY BY VIVID.01
]]

local Workspace, RunService, Players, CoreGui, Lighting = cloneref(game:GetService("Workspace")), cloneref(game:GetService("RunService")), cloneref(game:GetService("Players")), game:GetService("CoreGui"), cloneref(game:GetService("Lighting"))

function isTeammate(character)
    local success, humanoidRootPart =
        pcall(
        function()
            return character:FindFirstChild("HumanoidRootPart")
        end
    )
    if success and humanoidRootPart and humanoidRootPart:FindFirstChild("TeammateLabel") then
        return true
    else
        return false
    end
end

local function getWeaponName(player)  
    for _, viewModel in pairs(workspace.ViewModels:GetChildren()) do
        if string.match(viewModel.Name, "^" .. player.Name .. " -") then
            local parts = {}
            for part in string.gmatch(viewModel.Name, "[^%-]+") do
                table.insert(parts, part)
            end
            local gunName = parts[2]
            return gunName
        end
    end
    return "none"
end

local ESP = getgenv().ESP
-- Def & Vars
local Euphoria = ESP.Connections;
local lplayer = Players.LocalPlayer;
local camera = game.Workspace.CurrentCamera;
local Cam = Workspace.CurrentCamera;
local RotationAngle, Tick = -45, tick();

-- Global connection storage for cleanup
local GlobalConnections = {}
local PlayerESPData = {}

-- Weapon Images
local Weapon_Icons = {
    ["Wooden Bow"] = "http://www.roblox.com/asset/?id=17677465400",
    ["Crossbow"] = "http://www.roblox.com/asset/?id=17677473017",
    ["Salvaged SMG"] = "http://www.roblox.com/asset/?id=17677463033",
    ["Salvaged AK47"] = "http://www.roblox.com/asset/?id=17677455113",
    ["Salvaged AK74u"] = "http://www.roblox.com/asset/?id=17677442346",
    ["Salvaged M14"] = "http://www.roblox.com/asset/?id=17677444642",
    ["Salvaged Python"] = "http://www.roblox.com/asset/?id=17677451737",
    ["Military PKM"] = "http://www.roblox.com/asset/?id=17677449448",
    ["Military M4A1"] = "http://www.roblox.com/asset/?id=17677479536",
    ["Bruno's M4A1"] = "http://www.roblox.com/asset/?id=17677471185",
    ["Military Barrett"] = "http://www.roblox.com/asset/?id=17677482998",
    ["Salvaged Skorpion"] = "http://www.roblox.com/asset/?id=17677459658",
    ["Salvaged Pump Action"] = "http://www.roblox.com/asset/?id=17677457186",
    ["Military AA12"] = "http://www.roblox.com/asset/?id=17677475227",
    ["Salvaged Break Action"] = "http://www.roblox.com/asset/?id=17677468751",
    ["Salvaged Pipe Rifle"] = "http://www.roblox.com/asset/?id=17677468751",
    ["Salvaged P250"] = "http://www.roblox.com/asset/?id=17677447257",
    ["Nail Gun"] = "http://www.roblox.com/asset/?id=17677484756"
};

-- Functions
local Functions = {}
do
    function Functions:Create(Class, Properties)
        local _Instance = typeof(Class) == 'string' and Instance.new(Class) or Class
        for Property, Value in pairs(Properties) do
            _Instance[Property] = Value
        end
        return _Instance;
    end
    --
    function Functions:FadeOutOnDist(element, distance)
        local transparency = math.max(0.1, 1 - (distance / ESP.MaxDistance))
        if element:IsA("TextLabel") then
            element.TextTransparency = 1 - transparency
        elseif element:IsA("ImageLabel") then
            element.ImageTransparency = 1 - transparency
        elseif element:IsA("UIStroke") then
            element.Transparency = 1 - transparency
        elseif element:IsA("Frame") then
            element.BackgroundTransparency = 1 - transparency
        elseif element:IsA("Highlight") then
            element.FillTransparency = 1 - transparency
            element.OutlineTransparency = 1 - transparency
        end;
    end;
    
    -- Cleanup function to prevent memory leaks
    function Functions:CleanupPlayer(plr)
        if PlayerESPData[plr] then
            -- Disconnect player-specific connection
            if PlayerESPData[plr].Connection then
                PlayerESPData[plr].Connection:Disconnect()
            end
            
            -- Destroy UI elements
            if PlayerESPData[plr].Elements then
                for _, element in pairs(PlayerESPData[plr].Elements) do
                    if element and element.Parent then
                        element:Destroy()
                    end
                end
            end
            
            PlayerESPData[plr] = nil
        end
    end
    
    -- Global cleanup function
    function Functions:CleanupAll()
        -- Cleanup all player data
        for plr, _ in pairs(PlayerESPData) do
            Functions:CleanupPlayer(plr)
        end
        
        -- Disconnect global connections
        for _, connection in pairs(GlobalConnections) do
            if connection then
                connection:Disconnect()
            end
        end
        GlobalConnections = {}
    end
end;

do -- Initialize
    local ScreenGui = Functions:Create("ScreenGui", {
        Parent = CoreGui,
        Name = "ESPHolder",
    });

    local DupeCheck = function(plr)
        if ScreenGui:FindFirstChild(plr.Name) then
            ScreenGui[plr.Name]:Destroy()
        end
        -- Clean up existing data
        Functions:CleanupPlayer(plr)
    end

    local ESP_Function = function(plr)
        coroutine.wrap(DupeCheck)(plr) -- Dupecheck
        
        -- Create UI elements
        local Name = Functions:Create("TextLabel", {Parent = ScreenGui, Position = UDim2.new(0.5, 0, 0, -11), Size = UDim2.new(0, 100, 0, 20), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(255, 255, 255), Font = Enum.Font.Code, TextSize = ESP.FontSize, TextStrokeTransparency = 0, TextStrokeColor3 = Color3.fromRGB(0, 0, 0), RichText = true, Visible = false})
        local Distance = Functions:Create("TextLabel", {Parent = ScreenGui, Position = UDim2.new(0.5, 0, 0, 11), Size = UDim2.new(0, 100, 0, 20), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(255, 255, 255), Font = Enum.Font.Code, TextSize = ESP.FontSize, TextStrokeTransparency = 0, TextStrokeColor3 = Color3.fromRGB(0, 0, 0), RichText = true, Visible = false})
        local Weapon = Functions:Create("TextLabel", {Parent = ScreenGui, Position = UDim2.new(0.5, 0, 0, 31), Size = UDim2.new(0, 100, 0, 20), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(255, 255, 255), Font = Enum.Font.Code, TextSize = ESP.FontSize, TextStrokeTransparency = 0, TextStrokeColor3 = Color3.fromRGB(0, 0, 0), RichText = true, Visible = false})
        local Box = Functions:Create("Frame", {Parent = ScreenGui, BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 0.75, BorderSizePixel = 0, Visible = false})
        local Gradient1 = Functions:Create("UIGradient", {Parent = Box, Enabled = ESP.Drawing.Boxes.GradientFill, Color = ColorSequence.new{ColorSequenceKeypoint.new(0, ESP.Drawing.Boxes.GradientFillRGB1), ColorSequenceKeypoint.new(1, ESP.Drawing.Boxes.GradientFillRGB2)}})
        local Outline = Functions:Create("UIStroke", {Parent = Box, Enabled = ESP.Drawing.Boxes.Gradient, Transparency = 0, Color = Color3.fromRGB(255, 255, 255), LineJoinMode = Enum.LineJoinMode.Miter})
        local Gradient2 = Functions:Create("UIGradient", {Parent = Outline, Enabled = ESP.Drawing.Boxes.Gradient, Color = ColorSequence.new{ColorSequenceKeypoint.new(0, ESP.Drawing.Boxes.GradientRGB1), ColorSequenceKeypoint.new(1, ESP.Drawing.Boxes.GradientRGB2)}})
        local Healthbar = Functions:Create("Frame", {Parent = ScreenGui, BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0, Visible = false})
        local BehindHealthbar = Functions:Create("Frame", {Parent = ScreenGui, ZIndex = -1, BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 0, Visible = false})
        local HealthbarGradient = Functions:Create("UIGradient", {Parent = Healthbar, Enabled = ESP.Drawing.Healthbar.Gradient, Rotation = -90, Color = ColorSequence.new{ColorSequenceKeypoint.new(0, ESP.Drawing.Healthbar.GradientRGB1), ColorSequenceKeypoint.new(0.5, ESP.Drawing.Healthbar.GradientRGB2), ColorSequenceKeypoint.new(1, ESP.Drawing.Healthbar.GradientRGB3)}})
        local HealthText = Functions:Create("TextLabel", {Parent = ScreenGui, Position = UDim2.new(0.5, 0, 0, 31), Size = UDim2.new(0, 100, 0, 20), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(255, 255, 255), Font = Enum.Font.Code, TextSize = ESP.FontSize, TextStrokeTransparency = 0, TextStrokeColor3 = Color3.fromRGB(0, 0, 0), Visible = false})
        local Chams = Functions:Create("Highlight", {Parent = ScreenGui, FillTransparency = 1, OutlineTransparency = 0, OutlineColor = Color3.fromRGB(119, 120, 255), DepthMode = "AlwaysOnTop", Enabled = false})
        local WeaponIcon = Functions:Create("ImageLabel", {Parent = ScreenGui, BackgroundTransparency = 1, BorderColor3 = Color3.fromRGB(0, 0, 0), BorderSizePixel = 0, Size = UDim2.new(0, 40, 0, 40), Visible = false})
        local Gradient3 = Functions:Create("UIGradient", {Parent = WeaponIcon, Rotation = -90, Enabled = ESP.Drawing.Weapons.Gradient, Color = ColorSequence.new{ColorSequenceKeypoint.new(0, ESP.Drawing.Weapons.GradientRGB1), ColorSequenceKeypoint.new(1, ESP.Drawing.Weapons.GradientRGB2)}})
        local LeftTop = Functions:Create("Frame", {Parent = ScreenGui, BackgroundColor3 = ESP.Drawing.Boxes.Corner.RGB, Position = UDim2.new(0, 0, 0, 0), Visible = false})
        local LeftSide = Functions:Create("Frame", {Parent = ScreenGui, BackgroundColor3 = ESP.Drawing.Boxes.Corner.RGB, Position = UDim2.new(0, 0, 0, 0), Visible = false})
        local RightTop = Functions:Create("Frame", {Parent = ScreenGui, BackgroundColor3 = ESP.Drawing.Boxes.Corner.RGB, Position = UDim2.new(0, 0, 0, 0), Visible = false})
        local RightSide = Functions:Create("Frame", {Parent = ScreenGui, BackgroundColor3 = ESP.Drawing.Boxes.Corner.RGB, Position = UDim2.new(0, 0, 0, 0), Visible = false})
        local BottomSide = Functions:Create("Frame", {Parent = ScreenGui, BackgroundColor3 = ESP.Drawing.Boxes.Corner.RGB, Position = UDim2.new(0, 0, 0, 0), Visible = false})
        local BottomDown = Functions:Create("Frame", {Parent = ScreenGui, BackgroundColor3 = ESP.Drawing.Boxes.Corner.RGB, Position = UDim2.new(0, 0, 0, 0), Visible = false})
        local BottomRightSide = Functions:Create("Frame", {Parent = ScreenGui, BackgroundColor3 = ESP.Drawing.Boxes.Corner.RGB, Position = UDim2.new(0, 0, 0, 0), Visible = false})
        local BottomRightDown = Functions:Create("Frame", {Parent = ScreenGui, BackgroundColor3 = ESP.Drawing.Boxes.Corner.RGB, Position = UDim2.new(0, 0, 0, 0), Visible = false})
        local Flag1 = Functions:Create("TextLabel", {Parent = ScreenGui, Position = UDim2.new(1, 0, 0, 0), Size = UDim2.new(0, 100, 0, 20), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(255, 255, 255), Font = Enum.Font.Code, TextSize = ESP.FontSize, TextStrokeTransparency = 0, TextStrokeColor3 = Color3.fromRGB(0, 0, 0), Visible = false})
        local Flag2 = Functions:Create("TextLabel", {Parent = ScreenGui, Position = UDim2.new(1, 0, 0, 0), Size = UDim2.new(0, 100, 0, 20), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(255, 255, 255), Font = Enum.Font.Code, TextSize = ESP.FontSize, TextStrokeTransparency = 0, TextStrokeColor3 = Color3.fromRGB(0, 0, 0), Visible = false})
        
        -- Store elements for cleanup
        local elements = {
            Name, Distance, Weapon, Box, Healthbar, BehindHealthbar, HealthText, 
            Chams, WeaponIcon, LeftTop, LeftSide, RightTop, RightSide, BottomSide, 
            BottomDown, BottomRightSide, BottomRightDown, Flag1, Flag2
        }
        
        local function HideESP()
            for _, element in pairs(elements) do
                if element and element.Parent then
                    if element:IsA("Highlight") then
                        element.Enabled = false
                    else
                        element.Visible = false
                    end
                end
            end
        end
        
        local function UpdateESP()
            -- Check if ESP is globally enabled first - CRITICAL OPTIMIZATION
            if not ESP.Enabled then
                HideESP()
                return
            end
            
            if not plr or not plr.Parent then
                HideESP()
                return
            end
            
            if not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") then
                HideESP()
                return
            end
            
            local HRP = plr.Character.HumanoidRootPart
            local Humanoid = plr.Character:FindFirstChild("Humanoid")
            if not Humanoid then
                HideESP()
                return
            end
            
            local Pos, OnScreen = Cam:WorldToScreenPoint(HRP.Position)
            local Dist = (Cam.CFrame.Position - HRP.Position).Magnitude / 3.5714285714
            
            if not OnScreen or Dist > ESP.MaxDistance then
                HideESP()
                return
            end
            
            -- Team check optimization
            if ESP.TeamCheck and plr ~= lplayer and (not isTeammate(plr.Character)) then
                local Size = HRP.Size.Y
                local scaleFactor = (Size * Cam.ViewportSize.Y) / (Pos.Z * 2)
                local w, h = 3 * scaleFactor, 4.5 * scaleFactor

                -- Only process fade-out if enabled
                if ESP.FadeOut.OnDistance then
                    for _, element in pairs(elements) do
                        Functions:FadeOutOnDist(element, Dist)
                    end
                end

                -- Only process chams if enabled
                if ESP.Drawing.Chams.Enabled then
                    Chams.Adornee = plr.Character
                    Chams.Enabled = true
                    Chams.FillColor = ESP.Drawing.Chams.FillRGB
                    Chams.OutlineColor = ESP.Drawing.Chams.OutlineRGB
                    
                    if ESP.Drawing.Chams.Thermal then
                        local breathe_effect = math.atan(math.sin(tick() * 2)) * 2 / math.pi
                        Chams.FillTransparency = ESP.Drawing.Chams.Fill_Transparency * breathe_effect * 0.01
                        Chams.OutlineTransparency = ESP.Drawing.Chams.Outline_Transparency * breathe_effect * 0.01
                    end
                    
                    Chams.DepthMode = ESP.Drawing.Chams.VisibleCheck and "Occluded" or "AlwaysOnTop"
                else
                    Chams.Enabled = false
                end

                -- Only process corner boxes if enabled
                if ESP.Drawing.Boxes.Corner.Enabled then
                    LeftTop.Visible = true
                    LeftTop.Position = UDim2.new(0, Pos.X - w / 2, 0, Pos.Y - h / 2)
                    LeftTop.Size = UDim2.new(0, w / 5, 0, 1)
                    
                    LeftSide.Visible = true
                    LeftSide.Position = UDim2.new(0, Pos.X - w / 2, 0, Pos.Y - h / 2)
                    LeftSide.Size = UDim2.new(0, 1, 0, h / 5)
                    
                    BottomSide.Visible = true
                    BottomSide.Position = UDim2.new(0, Pos.X - w / 2, 0, Pos.Y + h / 2)
                    BottomSide.Size = UDim2.new(0, 1, 0, h / 5)
                    BottomSide.AnchorPoint = Vector2.new(0, 5)
                    
                    BottomDown.Visible = true
                    BottomDown.Position = UDim2.new(0, Pos.X - w / 2, 0, Pos.Y + h / 2)
                    BottomDown.Size = UDim2.new(0, w / 5, 0, 1)
                    BottomDown.AnchorPoint = Vector2.new(0, 1)
                    
                    RightTop.Visible = true
                    RightTop.Position = UDim2.new(0, Pos.X + w / 2, 0, Pos.Y - h / 2)
                    RightTop.Size = UDim2.new(0, w / 5, 0, 1)
                    RightTop.AnchorPoint = Vector2.new(1, 0)
                    
                    RightSide.Visible = true
                    RightSide.Position = UDim2.new(0, Pos.X + w / 2 - 1, 0, Pos.Y - h / 2)
                    RightSide.Size = UDim2.new(0, 1, 0, h / 5)
                    RightSide.AnchorPoint = Vector2.new(0, 0)
                    
                    BottomRightSide.Visible = true
                    BottomRightSide.Position = UDim2.new(0, Pos.X + w / 2, 0, Pos.Y + h / 2)
                    BottomRightSide.Size = UDim2.new(0, 1, 0, h / 5)
                    BottomRightSide.AnchorPoint = Vector2.new(1, 1)
                    
                    BottomRightDown.Visible = true
                    BottomRightDown.Position = UDim2.new(0, Pos.X + w / 2, 0, Pos.Y + h / 2)
                    BottomRightDown.Size = UDim2.new(0, w / 5, 0, 1)
                    BottomRightDown.AnchorPoint = Vector2.new(1, 1)
                else
                    LeftTop.Visible = false
                    LeftSide.Visible = false
                    BottomSide.Visible = false
                    BottomDown.Visible = false
                    RightTop.Visible = false
                    RightSide.Visible = false
                    BottomRightSide.Visible = false
                    BottomRightDown.Visible = false
                end

                -- Only process full boxes if enabled
                if ESP.Drawing.Boxes.Full.Enabled then
                    Box.Position = UDim2.new(0, Pos.X - w / 2, 0, Pos.Y - h / 2)
                    Box.Size = UDim2.new(0, w, 0, h)
                    Box.Visible = true

                    if ESP.Drawing.Boxes.Filled.Enabled then
                        Box.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        Box.BackgroundTransparency = ESP.Drawing.Boxes.GradientFill and ESP.Drawing.Boxes.Filled.Transparency or 1
                        Box.BorderSizePixel = 1
                    else
                        Box.BackgroundTransparency = 1
                    end
                    
                    if ESP.Drawing.Boxes.Animate then
                        RotationAngle = RotationAngle + (tick() - Tick) * ESP.Drawing.Boxes.RotationSpeed * math.cos(math.pi / 4 * tick() - math.pi / 2)
                        Gradient1.Rotation = RotationAngle
                        Gradient2.Rotation = RotationAngle
                    else
                        Gradient1.Rotation = -45
                        Gradient2.Rotation = -45
                    end
                    Tick = tick()
                else
                    Box.Visible = false
                end

                -- Only process healthbar if enabled
                if ESP.Drawing.Healthbar.Enabled then
                    local health = Humanoid.Health / Humanoid.MaxHealth;
                    Healthbar.Visible = true
                    Healthbar.Position = UDim2.new(0, Pos.X - w / 2 - 6, 0, Pos.Y - h / 2 + h * (1 - health))  
                    Healthbar.Size = UDim2.new(0, ESP.Drawing.Healthbar.Width, 0, h * health)  
                    
                    BehindHealthbar.Visible = true
                    BehindHealthbar.Position = UDim2.new(0, Pos.X - w / 2 - 6, 0, Pos.Y - h / 2)  
                    BehindHealthbar.Size = UDim2.new(0, ESP.Drawing.Healthbar.Width, 0, h)
                    
                    if ESP.Drawing.Healthbar.HealthText then
                        local healthPercentage = math.floor(Humanoid.Health / Humanoid.MaxHealth * 100)
                        HealthText.Position = UDim2.new(0, Pos.X - w / 2 - 6, 0, Pos.Y - h / 2 + h * (1 - healthPercentage / 100) + 3)
                        HealthText.Text = tostring(healthPercentage)
                        HealthText.Visible = Humanoid.Health < Humanoid.MaxHealth
                        
                        if ESP.Drawing.Healthbar.Lerp then
                            local color = health >= 0.75 and Color3.fromRGB(0, 255, 0) or health >= 0.5 and Color3.fromRGB(255, 255, 0) or health >= 0.25 and Color3.fromRGB(255, 170, 0) or Color3.fromRGB(255, 0, 0)
                            HealthText.TextColor3 = color
                        else
                            HealthText.TextColor3 = ESP.Drawing.Healthbar.HealthTextRGB
                        end
                    else
                        HealthText.Visible = false
                    end
                else
                    Healthbar.Visible = false
                    BehindHealthbar.Visible = false
                    HealthText.Visible = false
                end

                -- Only process names if enabled
                if ESP.Drawing.Names.Enabled then
                    Name.Visible = true
                    if ESP.Options.Friendcheck and lplayer:IsFriendsWith(plr.UserId) then
                        Name.Text = string.format('(<font color="rgb(%d, %d, %d)">F</font>) %s', ESP.Options.FriendcheckRGB.R * 255, ESP.Options.FriendcheckRGB.G * 255, ESP.Options.FriendcheckRGB.B * 255, plr.Name)
                    else
                        Name.Text = string.format('(<font color="rgb(%d, %d, %d)">E</font>) %s', 255, 0, 0, plr.Name)
                    end
                    Name.Position = UDim2.new(0, Pos.X, 0, Pos.Y - h / 2 - 9)
                else
                    Name.Visible = false
                end
                
                -- Only process distance if enabled
                if ESP.Drawing.Distances.Enabled then
                    if ESP.Drawing.Distances.Position == "Bottom" then
                        Weapon.Position = UDim2.new(0, Pos.X, 0, Pos.Y + h / 2 + 18)
                        WeaponIcon.Position = UDim2.new(0, Pos.X - 21, 0, Pos.Y + h / 2 + 15);
                        Distance.Position = UDim2.new(0, Pos.X, 0, Pos.Y + h / 2 + 7)
                        Distance.Text = string.format("%d meters", math.floor(Dist))
                        Distance.Visible = true
                    elseif ESP.Drawing.Distances.Position == "Text" then
                        Weapon.Position = UDim2.new(0, Pos.X, 0, Pos.Y + h / 2 + 8)
                        WeaponIcon.Position = UDim2.new(0, Pos.X - 21, 0, Pos.Y + h / 2 + 5);
                        Distance.Visible = false
                        if ESP.Drawing.Names.Enabled then
                            if ESP.Options.Friendcheck and lplayer:IsFriendsWith(plr.UserId) then
                                Name.Text = string.format('(<font color="rgb(%d, %d, %d)">F</font>) %s [%d]', ESP.Options.FriendcheckRGB.R * 255, ESP.Options.FriendcheckRGB.G * 255, ESP.Options.FriendcheckRGB.B * 255, plr.Name, math.floor(Dist))
                            else
                                Name.Text = string.format('(<font color="rgb(%d, %d, %d)">E</font>) %s [%d]', 255, 0, 0, plr.Name, math.floor(Dist))
                            end
                            Name.Visible = true
                        end
                    end
                else
                    Distance.Visible = false
                end

                -- Only process weapons if enabled
                if ESP.Drawing.Weapons.Enabled then
                    Weapon.Text = getWeaponName(plr)
                    Weapon.Visible = true
                else
                    Weapon.Visible = false
                end
            else
                HideESP()
            end
        end
        
        -- Create connection and store it for cleanup
        local Connection = Euphoria.RunService.RenderStepped:Connect(UpdateESP)
        
        -- Store player data for cleanup
        PlayerESPData[plr] = {
            Connection = Connection,
            Elements = elements
        }
    end
    
    -- Clean up when players leave
    local function onPlayerRemoving(plr)
        Functions:CleanupPlayer(plr)
    end
    
    -- Initialize ESP for existing players
    for _, v in pairs(Players:GetPlayers()) do
        if v.Name ~= lplayer.Name then
            coroutine.wrap(ESP_Function)(v)
        end      
    end
    
    -- Connect events and store connections for cleanup
    GlobalConnections[#GlobalConnections + 1] = Players.PlayerAdded:Connect(function(v)
        coroutine.wrap(ESP_Function)(v)
    end)
    
    GlobalConnections[#GlobalConnections + 1] = Players.PlayerRemoving:Connect(onPlayerRemoving)
    
    -- Cleanup function that can be called externally to stop all ESP
    getgenv().CleanupESP = function()
        Functions:CleanupAll()
        if ScreenGui and ScreenGui.Parent then
            ScreenGui:Destroy()
        end
    end
    
    -- Optional: Add a connection to clean up when the script is reloaded
    if getgenv().ESPCleanupConnection then
        getgenv().ESPCleanupConnection:Disconnect()
    end
    
    getgenv().ESPCleanupConnection = game:GetService("Players").PlayerRemoving:Connect(function(plr)
        if plr == lplayer then
            getgenv().CleanupESP()
        end
    end)
end;
