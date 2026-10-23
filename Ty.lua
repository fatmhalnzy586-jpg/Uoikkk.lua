-- // Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

-- // Local Player & Camera
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- // Settings
local Settings = {
    AimbotEnabled = true,
    AimbotKey = Enum.UserInputType.MouseButton2, -- زر الفأرة الأيمن للتصويب
    Smoothness = 0.2, -- درجة نعومة التتبع (من 0.1 إلى 1)
    FOV_Radius = 150, -- حجم دائرة التصويب
    
    ESP_Enabled = true,
    TeamCheck = true -- عدم استهداف أو كشف أعضاء فريقك
}

-- // FOV Circle Setup
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1.5
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Filled = false
FOVCircle.Transparency = 1
FOVCircle.Visible = true

-- // Wall Check Function (التحقق من وجود جدار)
local function IsVisible(targetCharacter, targetPart)
    if not targetCharacter or not targetPart then return false end
    
    local origin = Camera.CFrame.Position
    local destination = targetPart.Position
    local direction = (destination - origin)
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, targetCharacter, Camera}
    raycastParams.IgnoreWater = true
    
    local result = Workspace:Raycast(origin, direction, raycastParams)
    
    -- إذا لم يصطدم الشعاع بأي جدار/عائق في الطريق، فالهدف مرئي
    return result == nil
end

-- // Get Closest Visible Target
local function GetClosestTarget()
    local closestPlayer = nil
    local shortestDistance = Settings.FOV_Radius
    local mousePos = UserInputService:GetMouseLocation()

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            
            -- Team Check
            if Settings.TeamCheck and player.Team == LocalPlayer.Team then
                continue
            end
            
            local head = player.Character:FindFirstChild("Head")
            if head then
                local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                
                if onScreen then
                    local distanceToMouse = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    
                    if distanceToMouse < shortestDistance then
                        -- التحقق من الرؤية (Wall Check)
                        if IsVisible(player.Character, head) then
                            shortestDistance = distanceToMouse
                            closestPlayer = head
                        end
                    end
                end
            end
        end
    end
    
    return closestPlayer
end

-- // Aimbot Loop
local isAiming = false

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Settings.AimbotKey or input.KeyCode == Settings.AimbotKey then
        isAiming = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Settings.AimbotKey or input.KeyCode == Settings.AimbotKey then
        isAiming = false
    end
end)

RunService.RenderStepped:Connect(function()
    -- تحديث موقع دائرة الـ FOV
    local mousePos = UserInputService:GetMouseLocation()
    FOVCircle.Position = mousePos
    FOVCircle.Radius = Settings.FOV_Radius

    -- تشغيل الإيمبوت عند الضغط
    if Settings.AimbotEnabled and isAiming then
        local targetHead = GetClosestTarget()
        if targetHead then
            local targetCFrame = CFrame.new(Camera.CFrame.Position, targetHead.Position)
            Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, Settings.Smoothness)
        end
    end
end)

-- // ESP System
local function CreateESP(player)
    local Box = Drawing.new("Square")
    Box.Thickness = 1.5
    Box.Color = Color3.fromRGB(255, 50, 50)
    Box.Filled = false
    Box.Visible = false

    local NameTag = Drawing.new("Text")
    NameTag.Size = 14
    NameTag.Color = Color3.fromRGB(255, 255, 255)
    NameTag.Center = true
    NameTag.Outline = true
    NameTag.Visible = false

    local connection
    connection = RunService.RenderStepped:Connect(function()
        if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            
            if Settings.TeamCheck and player.Team == LocalPlayer.Team then
                Box.Visible = false
                NameTag.Visible = false
                return
            end

            local hrp = player.Character.HumanoidRootPart
            local head = player.Character:FindFirstChild("Head")
            
            local hrpPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)

            if onScreen and Settings.ESP_Enabled then
                local headPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                local legPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))

                local boxHeight = math.abs(headPos.Y - legPos.Y)
                local boxWidth = boxHeight / 1.8

                Box.Size = Vector2.new(boxWidth, boxHeight)
                Box.Position = Vector2.new(hrpPos.X - boxWidth / 2, hrpPos.Y - boxHeight / 2)
                Box.Visible = true

                NameTag.Text = player.Name
                NameTag.Position = Vector2.new(hrpPos.X, hrpPos.Y - (boxHeight / 2) - 15)
                NameTag.Visible = true
            else
                Box.Visible = false
                NameTag.Visible = false
            end
        else
            Box.Visible = false
            NameTag.Visible = false
            if not Players:FindFirstChild(player.Name) then
                Box:Remove()
                NameTag:Remove()
                connection:Disconnect()
            end
        end
    end)
end

-- تطبيق ESP على جميع اللاعبين
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        CreateESP(player)
    end
end

Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        CreateESP(player)
    end
end)
