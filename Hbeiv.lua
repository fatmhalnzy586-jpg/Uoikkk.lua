-- Delta Compatible Aimbot & ESP Script
-- Features: Wall Check, Team Check, Raycasting Protection

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- [[ Settings / إعدادات ]]
local Settings = {
    AimbotEnabled = true,
    AimbotKey = Enum.UserInputType.MouseButton2, -- زر الفأرة الأيمن (أو التجميع التلقائي للجوال)
    AimbotFOV = 150,               -- نطاق الدائرة
    Smoothness = 0.2,              -- نعومة السحب (0.1 سريع ، 0.5 بطيء)
    WallCheck = true,              -- عدم الشبك من خلف الجدار
    TeamCheck = true,              -- عدم استهداف أعضاء فريقك
    
    ESPEnabled = true,
    ESPColor = Color3.fromRGB(255, 50, 50),
    TeamColor = Color3.fromRGB(50, 255, 50)
}

-- [[ FOV Circle / رسم دائرة النطاق ]]
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1.5
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Filled = false
FOVCircle.Transparency = 0.7
FOVCircle.Visible = true
FOVCircle.Radius = Settings.AimbotFOV

-- [[ Wall Check Function / فحص وجود جدار ]]
local function IsVisible(targetPart)
    if not Settings.WallCheck then return true end
    
    local origin = Camera.CFrame.Position
    local destination = targetPart.Position
    local direction = (destination - origin)
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = RaycastFilterType.Exclude
    
    -- استثناء الشخصية الخاصة بك والهدف من الاكتشاف
    local ignoreList = {LocalPlayer.Character}
    if targetPart.Parent then
        table.insert(ignoreList, targetPart.Parent)
    end
    raycastParams.FilterDescendantsInstances = ignoreList
    
    local result = Workspace:Raycast(origin, direction, raycastParams)
    
    -- إذا لم يصطدم الشعاع بأي جدار/عائق، فالهدف مرئي
    return result == nil
end

-- [[ Get Closest Player / البحث عن أقرب هدف ]]
local function GetClosestPlayer()
    local closestPlayer = nil
    local shortestDistance = Settings.AimbotFOV
    local mousePos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChildOfClass("Humanoid") then
            -- Team Check
            if Settings.TeamCheck and player.Team ~= nil and player.Team == LocalPlayer.Team then
                continue
            end
            
            -- Check Health
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid.Health <= 0 then continue end

            local head = player.Character:FindFirstChild("Head") or player.Character.HumanoidRootPart
            local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)

            if onScreen then
                local distanceToMouse = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                if distanceToMouse < shortestDistance then
                    -- Wall Check
                    if IsVisible(head) then
                        shortestDistance = distanceToMouse
                        closestPlayer = head
                    end
                end
            end
        end
    end

    return closestPlayer
end

-- [[ ESP System / نظام كشف الأماكن ]]
local function ApplyESP(player)
    local Highlight = Instance.new("Highlight")
    Highlight.Name = "ESPHighlight"
    Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    Highlight.FillTransparency = 0.5
    Highlight.OutlineTransparency = 0

    local function updateCharacter(char)
        if char then
            Highlight.Parent = char
            if Settings.TeamCheck and player.Team == LocalPlayer.Team then
                Highlight.FillColor = Settings.TeamColor
            else
                Highlight.FillColor = Settings.ESPColor
            end
        end
    end

    if player.Character then updateCharacter(player.Character) end
    player.CharacterAdded:Connect(updateCharacter)
end

-- تطبيق ESP على جميع اللاعبين
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        ApplyESP(player)
    end
end
Players.PlayerAdded:Connect(ApplyESP)

-- [[ Main Loop / الحلقة البرمجية الرئيسية ]]
local isAiming = false

UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and (input.UserInputType == Settings.AimbotKey or input.KeyCode == Enum.KeyCode.ButtonR2) then
        isAiming = true
    end
end)

UserInputService.InputEnded:Connect(function(input, gpe)
    if input.UserInputType == Settings.AimbotKey or input.KeyCode == Enum.KeyCode.ButtonR2 then
        isAiming = false
    end
end)

RunService.RenderStepped:Connect(function()
    -- تحديث موقع دائرة الـ FOV لمنتصف الشاشة
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    if Settings.AimbotEnabled and (isAiming or UserInputService:IsMouseButtonPressed(Settings.AimbotKey)) then
        local target = GetClosestPlayer()
        if target then
            -- توجيه الكاميرا بنعومة نحو الهدف
            local targetCFrame = CFrame.new(Camera.CFrame.Position, target.Position)
            Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, Settings.Smoothness)
        end
    end
end)
