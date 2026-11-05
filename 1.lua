-- ============================================
-- DeepSeek Studio (神级满配 · 粒子红心文字启动)
-- ============================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- 1. 安全容器
local container = game:GetService("CoreGui")
pcall(function() if gethui then container = gethui() end end)

local mainGui = Instance.new("ScreenGui")
mainGui.Name = tostring(math.random(100000, 999999))
mainGui.ResetOnSpawn = false
mainGui.IgnoreGuiInset = true
mainGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
mainGui.Parent = container

local Config = { 
    ESP = false, 
    Highlight = false,
    SilentAim = false,
    FOV = 150,
    Fly = false, FlySpeed = 100,
    Speed = false, SpeedVal = 100,
    Jump = false, JumpVal = 150,
    Filters = {
        ["平民"] = true, ["警察"] = true, ["医生"] = true,
        ["消防员"] = true, ["厨师"] = true, ["快递员"] = true,
        ["农夫"] = true, ["囚犯"] = true, ["其他"] = true
    }
}

local Colors = {
    Bg = Color3.fromRGB(240, 242, 245),
    Panel = Color3.fromRGB(255, 255, 255),
    Sidebar = Color3.fromRGB(235, 237, 240),
    TextDark = Color3.fromRGB(30, 30, 30),
    TextLight = Color3.fromRGB(120, 120, 120),
    AccentBlue = Color3.fromRGB(0, 110, 255),
    ToggleOff = Color3.fromRGB(200, 200, 200),
}

-- ==========================================
-- UI 构建 (优先执行，绝对保底)
-- ==========================================
local Main = Instance.new("Frame")
Main.AnchorPoint = Vector2.new(0.5, 0)
Main.Position = UDim2.new(0.5, 0, 0, 10)
Main.Size = UDim2.fromOffset(110, 32)
Main.BackgroundColor3 = Colors.Bg
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Parent = mainGui
local MainCorner = Instance.new("UICorner", Main)
MainCorner.CornerRadius = UDim.new(1, 0)

local CapsuleText = Instance.new("TextLabel")
CapsuleText.Size = UDim2.new(1, 0, 1, 0)
CapsuleText.BackgroundTransparency = 1
CapsuleText.Text = "DeepSeek"
CapsuleText.TextColor3 = Colors.TextDark
CapsuleText.Font = Enum.Font.GothamBold
CapsuleText.TextSize = 13
CapsuleText.Parent = Main

local CapsuleBtn = Instance.new("TextButton")
CapsuleBtn.Size = UDim2.fromScale(1, 1)
CapsuleBtn.BackgroundTransparency = 1
CapsuleBtn.Text = ""
CapsuleBtn.Parent = Main

local MainContent = Instance.new("Frame")
MainContent.Size = UDim2.fromScale(1, 1)
MainContent.BackgroundTransparency = 1
MainContent.Visible = false
MainContent.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.fromOffset(200, 30)
Title.Position = UDim2.fromOffset(16, 5)
Title.BackgroundTransparency = 1
Title.Text = "DeepSeek Studio"
Title.TextColor3 = Colors.TextDark
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = MainContent

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.fromOffset(32, 32)
CloseBtn.Position = UDim2.new(1, -40, 0, 4)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Colors.TextLight
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 20
CloseBtn.ZIndex = 10
CloseBtn.Parent = MainContent

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.fromOffset(120, 250)
Sidebar.Position = UDim2.fromOffset(8, 40)
Sidebar.BackgroundColor3 = Colors.Sidebar
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainContent
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 10)

local NavContainer = Instance.new("Frame")
NavContainer.Size = UDim2.new(1, 0, 1, 0)
NavContainer.BackgroundTransparency = 1
NavContainer.Parent = Sidebar
local NavLayout = Instance.new("UIListLayout", NavContainer)
NavLayout.Padding = UDim.new(0, 4)
NavLayout.SortOrder = Enum.SortOrder.LayoutOrder

local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1, -136, 1, -50)
ContentFrame.Position = UDim2.fromOffset(128, 40)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainContent

local Pages = {}
local NavButtons = {}

local function CreatePage(name)
    local sf = Instance.new("ScrollingFrame")
    sf.Size = UDim2.new(1, 0, 1, 0)
    sf.BackgroundTransparency = 1
    sf.BorderSizePixel = 0
    sf.ScrollBarThickness = 3
    sf.ScrollBarImageColor3 = Colors.ToggleOff
    sf.CanvasSize = UDim2.new(0, 0, 0, 0)
    sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
    sf.Parent = ContentFrame
    sf.Visible = false
    local layout = Instance.new("UIListLayout", sf)
    layout.Padding = UDim.new(0, 8)
    Pages[name] = sf
    return sf
end

local function SwitchPage(name)
    for pName, pFrame in pairs(Pages) do pFrame.Visible = (pName == name) end
    for bName, btn in pairs(NavButtons) do
        btn.BackgroundColor3 = (bName == name) and Colors.Panel or Colors.Sidebar
        btn.TextColor3 = (bName == name) and Colors.AccentBlue or Colors.TextLight
    end
end

local function CreateNavBtn(name)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -12, 0, 32)
    btn.Position = UDim2.fromOffset(6, 8)
    btn.BackgroundColor3 = Colors.Sidebar
    btn.Text = "  " .. name
    btn.TextColor3 = Colors.TextLight
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Parent = NavContainer
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(function() SwitchPage(name) end)
    NavButtons[name] = btn
end

local function AddCard(parent, text, toggleKey)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 44)
    card.BackgroundColor3 = Colors.Panel
    card.BorderSizePixel = 0
    card.Parent = parent
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -60, 1, 0)
    lbl.Position = UDim2.fromOffset(16, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Colors.TextDark
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = card
    
    local track = Instance.new("Frame")
    track.Size = UDim2.fromOffset(40, 22)
    track.Position = UDim2.new(1, -56, 0.5, -11)
    track.BackgroundColor3 = Colors.ToggleOff
    track.BorderSizePixel = 0
    track.Parent = card
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
    
    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(18, 18)
    knob.Position = UDim2.fromOffset(2, 2)
    knob.BackgroundColor3 = Colors.Panel
    knob.Parent = track
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.fromScale(1,1)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = card
    
    local isOn = Config[toggleKey] or false
    if isOn then track.BackgroundColor3 = Colors.AccentBlue; knob.Position = UDim2.fromOffset(20, 2) end

    btn.MouseButton1Click:Connect(function()
        isOn = not isOn
        if toggleKey then Config[toggleKey] = isOn end
        if isOn then
            TweenService:Create(track, TweenInfo.new(0.2), {BackgroundColor3 = Colors.AccentBlue}):Play()
            TweenService:Create(knob, TweenInfo.new(0.2), {Position = UDim2.fromOffset(20, 2)}):Play()
        else
            TweenService:Create(track, TweenInfo.new(0.2), {BackgroundColor3 = Colors.ToggleOff}):Play()
            TweenService:Create(knob, TweenInfo.new(0.2), {Position = UDim2.fromOffset(2, 2)}):Play()
        end
    end)
end

local function AddSlider(parent, text, minVal, maxVal, defaultVal, callback)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 60)
    card.BackgroundColor3 = Colors.Panel
    card.BorderSizePixel = 0
    card.Parent = parent
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -30, 0, 20)
    lbl.Position = UDim2.fromOffset(16, 6)
    lbl.BackgroundTransparency = 1
    lbl.Text = text .. ": " .. defaultVal
    lbl.TextColor3 = Colors.TextDark
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = card

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -32, 0, 6)
    track.Position = UDim2.new(0, 16, 1, -16)
    track.BackgroundColor3 = Colors.ToggleOff
    track.BorderSizePixel = 0
    track.Parent = card
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((defaultVal-minVal)/(maxVal-minVal), 0, 1, 0)
    fill.BackgroundColor3 = Colors.AccentBlue
    fill.BorderSizePixel = 0
    fill.Parent = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(16, 16)
    knob.Position = UDim2.new((defaultVal-minVal)/(maxVal-minVal), -8, 0.5, 0)
    knob.AnchorPoint = Vector2.new(0, 0.5)
    knob.BackgroundColor3 = Colors.Panel
    knob.Parent = track
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local touchArea = Instance.new("TextButton")
    touchArea.Size = UDim2.new(1, 0, 1, 0)
    touchArea.BackgroundTransparency = 1
    touchArea.Text = ""
    touchArea.Parent = card

    local isDragging = false
    local function updateVal(xPos)
        local relX = math.clamp((xPos - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local val = math.floor(minVal + (maxVal - minVal) * relX)
        fill.Size = UDim2.new(relX, 0, 1, 0)
        knob.Position = UDim2.new(relX, -8, 0.5, 0)
        lbl.Text = text .. ": " .. val
        callback(val)
    end

    touchArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = true; updateVal(input.Position.X)
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if isDragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            updateVal(input.Position.X)
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = false
        end
    end)
end

CreateNavBtn("视觉")
CreateNavBtn("战斗")
CreateNavBtn("移动")
local page_Visual = CreatePage("视觉")
AddCard(page_Visual, "玩家透视", "ESP")
AddCard(page_Visual, "人物高亮", "Highlight")
local page_Combat = CreatePage("战斗")
AddCard(page_Combat, "静默自瞄", "SilentAim")
AddSlider(page_Combat, "瞄准范围 (FOV)", 50, 600, Config.FOV, function(v) Config.FOV = v end)
local page_Move = CreatePage("移动")
AddCard(page_Move, "开启飞行", "Fly")
AddSlider(page_Move, "飞行速度", 50, 300, Config.FlySpeed, function(v) Config.FlySpeed = v end)
AddCard(page_Move, "极速移动", "Speed")
AddCard(page_Move, "高跳", "Jump")

SwitchPage("视觉")
local isOpen = false
local isAnimating = false
local function ToggleUI(openState)
    if isAnimating then return end
    isAnimating = true
    isOpen = openState
    if isOpen then
        MainContent.Visible = true
        CapsuleText.Visible = false
        CapsuleBtn.Visible = false
        TweenService:Create(Main, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.fromOffset(480, 320), Position = UDim2.new(0.5, 0, 0, 40)}):Play()
        TweenService:Create(MainCorner, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {CornerRadius = UDim.new(0, 12)}):Play()
        task.wait(0.4)
    else
        MainContent.Visible = false
        TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Size = UDim2.fromOffset(110, 32), Position = UDim2.new(0.5, 0, 0, 10)}):Play()
        TweenService:Create(MainCorner, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {CornerRadius = UDim.new(1, 0)}):Play()
        task.wait(0.3)
        CapsuleText.Visible = true
        CapsuleBtn.Visible = true
    end
    isAnimating = false
end
CapsuleBtn.MouseButton1Click:Connect(function() ToggleUI(true) end)
CloseBtn.MouseButton1Click:Connect(function() ToggleUI(false) end)

-- ==========================================
-- 核心启动动画：红心汇聚 -> 文字重组 (不遮挡背景)
-- ==========================================
local function PlayIntroAnimation()
    local particles = {}
    local NUM_PARTICLES = 150
    
    -- 1. 生成四周的红色粒子
    for i = 1, NUM_PARTICLES do
        local p = Instance.new("Frame")
        p.Size = UDim2.fromOffset(math.random(3, 6), math.random(3, 6))
        p.BackgroundColor3 = Color3.fromRGB(255, 50, 80)
        p.BorderSizePixel = 0
        p.ZIndex = 100
        p.Parent = mainGui
        Instance.new("UICorner", p).CornerRadius = UDim.new(1, 0)
        
        -- 随机四周边缘起始点
        local edge = math.random(1, 4)
        local sx, sy
        if edge == 1 then sx, sy = 0, math.random() 
        elseif edge == 2 then sx, sy = 1, math.random()
        elseif edge == 3 then sx, sy = math.random(), 0
        else sx, sy = math.random(), 1 end
        p.Position = UDim2.new(sx, 0, sy, 0)
        
        table.insert(particles, p)
    end
    
    task.wait(0.1)
    
    -- 2. 汇聚成红心 (使用参数方程)
    local cx, cy = 0.5, 0.4 -- 屏幕中心偏上
    local scale = 0.08
    for i, p in ipairs(particles) do
        local t = (i / NUM_PARTICLES) * math.pi * 2
        -- 心形公式
        local x = 16 * math.pow(math.sin(t), 3)
        local y = 13 * math.cos(t) - 5 * math.cos(2*t) - 2 * math.cos(3*t) - math.cos(4*t)
        
        local tx = cx + (x * scale / 16) * 0.6
        local ty = cy - (y * scale / 16) * 0.6
        
        local tweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        TweenService:Create(p, tweenInfo, {Position = UDim2.new(tx, 0, ty, 0)}):Play()
    end
    
    task.wait(2.0) -- 等待心形定格
    
    -- 3. 散开
    local scatterTween = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    for i, p in ipairs(particles) do
        local currentPos = p.Position
        local randomOffsetX = (math.random() - 0.5) * 0.4
        local randomOffsetY = (math.random() - 0.5) * 0.4
        TweenService:Create(p, scatterTween, {
            Position = UDim2.new(currentPos.X.Scale + randomOffsetX, 0, currentPos.Y.Scale + randomOffsetY, 0),
            BackgroundTransparency = 0.5
        }):Play()
    end
    
    task.wait(0.6)
    
    -- 4. 重组成文字
    -- 由于直接拼出那么长的句子不现实，为了兼顾美观与性能，这里让粒子组成一段排版精美的文字
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 0, 100)
    textLabel.Position = UDim2.new(0, 0, 0.35, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = "别人成双成对\n你不必羡慕\n\n我来帮助你"
    textLabel.TextColor3 = Color3.fromRGB(255, 50, 80)
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextSize = 28
    textLabel.TextTransparency = 1
    textLabel.ZIndex = 99
    textLabel.Parent = mainGui
    
    -- 让粒子围绕文字飞舞
    for i, p in ipairs(particles) do
        local tx = cx + (math.random() - 0.5) * 0.8
        local ty = cy + (math.random() - 0.5) * 0.3
        local convergeTween = TweenInfo.new(1.0, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut)
        TweenService:Create(p, convergeTween, {
            Position = UDim2.new(tx, 0, ty, 0),
            BackgroundTransparency = 1
        }):Play()
    end
    
    -- 文字淡入
    TweenService:Create(textLabel, TweenInfo.new(1.5), {TextTransparency = 0}):Play()
    task.wait(3.0)
    
    -- 结束，淡出
    TweenService:Create(textLabel, TweenInfo.new(1.0), {TextTransparency = 1}):Play()
    task.wait(1.0)
    
    -- 销毁所有粒子
    for _, p in ipairs(particles) do p:Destroy() end
    textLabel:Destroy()
end

-- 异步启动动画，不阻塞主线程
task.spawn(PlayIntroAnimation)


-- ==========================================
-- 核心功能：防闪退子弹追踪
-- ==========================================
local cachedTarget = nil
local seatCooldown = false
local lastSitState = false

task.spawn(function()
    while task.wait(0.1) do
        local char = LP.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local isSitting = hum and hum.Sit
        if isSitting ~= lastSitState then
            lastSitState = isSitting
            seatCooldown = true
            cachedTarget = nil 
            task.wait(1.0) 
            seatCooldown = false
        end
    end
end)

task.spawn(function()
    while task.wait(0.05) do
        if Config.SilentAim and not seatCooldown then
            local closest, minDist = nil, math.huge
            local center = Camera.ViewportSize / 2
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LP and plr.Character then
                    local part = plr.Character:FindFirstChild("Head") or plr.Character:FindFirstChild("HumanoidRootPart")
                    local thum = plr.Character:FindFirstChildOfClass("Humanoid")
                    if part and thum and thum.Health > 0 then
                        if not plr.Team or plr.Team ~= LP.Team then
                            local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                            if onScreen then
                                local distToCenter = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                                if distToCenter <= Config.FOV then
                                    local dist3D = (Camera.CFrame.Position - part.Position).Magnitude
                                    if dist3D < minDist then minDist = dist3D; closest = part end
                                end
                            end
                        end
                    end
                end
            end
            cachedTarget = closest
        else
            cachedTarget = nil
        end
    end
end)

pcall(function()
    if hookmetamethod then
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            if not checkcaller() and Config.SilentAim and cachedTarget and not seatCooldown then
                local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
                if hum and not hum.Sit then
                    if method == "Raycast" then
                        local args = {...}
                        if typeof(args[1]) == "Vector3" and typeof(args[2]) == "Vector3" then
                            local myHRP = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                            if myHRP and (args[1] - myHRP.Position).Magnitude < 15 then
                                args[2] = (cachedTarget.Position - args[1]).Unit * 9999
                                return oldNamecall(self, unpack(args))
                            end
                        end
                    end
                end
            end
            return oldNamecall(self, ...)
        end)
    end
end)

-- ==========================================
-- 飞行与移动模块
-- ==========================================
local flyBV = nil
local flyBG = nil
local originalSpeed = 16
local originalJump = 50

RunService.Heartbeat:Connect(function()
    local char = LP.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    
    if hrp and hum then
        -- 速度/跳跃
        if Config.Speed then hum.WalkSpeed = Config.SpeedVal else hum.WalkSpeed = originalSpeed end
        if Config.Jump then hum.JumpPower = Config.JumpVal else hum.JumpPower = originalJump end
        
        -- 飞行逻辑
        if Config.Fly and not hum.Sit then
            if not flyBV then
                flyBV = Instance.new("BodyVelocity")
                flyBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                flyBV.Velocity = Vector3.new(0,0,0)
                flyBV.Parent = hrp
                
                flyBG = Instance.new("BodyGyro")
                flyBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
                flyBG.P = 1000
                flyBG.Parent = hrp
            end
            
            local moveDir = Vector3.new()
            local camCFrame = Camera.CFrame
            
            if UIS:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camCFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camCFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - camCFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + camCFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
            if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0, 1, 0) end
            
            flyBV.Velocity = moveDir * Config.FlySpeed
            flyBG.CFrame = camCFrame
        else
            if flyBV then flyBV:Destroy(); flyBV = nil end
            if flyBG then flyBG:Destroy(); flyBG = nil end
        end
    end
end)

-- ==========================================
-- 透视与高亮模块
-- ==========================================
local HIGHLIGHT_POOL_SIZE = 20
local highlightPool = {}
local hlFolder = Instance.new("Folder")
hlFolder.Name = tostring(math.random(10000, 99999))
pcall(function() hlFolder.Parent = container end)
if not hlFolder.Parent then hlFolder.Parent = workspace end

for i = 1, HIGHLIGHT_POOL_SIZE do
    local hl = Instance.new("Highlight")
    hl.DepthMode = Enum.HighlightDepthMode.Occluded
    hl.OutlineTransparency = 1
    hl.FillTransparency = 0.5
    hl.Adornee = nil
    hl.Parent = hlFolder
    table.insert(highlightPool, hl)
end

local espCache = {}
local function initPlayer(plr)
    if plr == LP or espCache[plr] then return end
    local box = Instance.new("Frame"); box.BackgroundTransparency = 1; box.BorderSizePixel = 1; box.BorderColor3 = Color3.fromRGB(0, 255, 100); box.Visible = false; box.Parent = mainGui
    local nameTxt = Instance.new("TextLabel"); nameTxt.BackgroundTransparency = 1; nameTxt.TextColor3 = Color3.new(1, 1, 1); nameTxt.TextStrokeTransparency = 0; nameTxt.Font = Enum.Font.SourceSansBold; nameTxt.TextSize = 14; nameTxt.Visible = false; nameTxt.Parent = mainGui
    local distTxt = Instance.new("TextLabel"); distTxt.BackgroundTransparency = 1; distTxt.TextColor3 = Color3.fromRGB(200, 200, 200); distTxt.TextStrokeTransparency = 0; distTxt.Font = Enum.Font.SourceSansBold; distTxt.TextSize = 12; distTxt.Visible = false; distTxt.Parent = mainGui
    espCache[plr] = { box = box, nameTxt = nameTxt, distTxt = distTxt }
end
for _, p in ipairs(Players:GetPlayers()) do initPlayer(p) end
Players.PlayerAdded:Connect(initPlayer)
Players.PlayerRemoving:Connect(function(plr) 
    if espCache[plr] then 
        espCache[plr].box:Destroy(); espCache[plr].nameTxt:Destroy(); espCache[plr].distTxt:Destroy(); espCache[plr] = nil 
    end 
end)

task.spawn(function()
    while task.wait(0.02) do 
        -- 高亮池分配 (低频)
        if Config.Highlight then
            local validTargets = {}
            for plr, _ in pairs(espCache) do
                if plr.Character then
                    local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                    if hrp and hum and hum.Health > 0 then
                        local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
                        table.insert(validTargets, {plr = plr, dist = dist})
                    end
                end
            end
            table.sort(validTargets, function(a, b) return a.dist < b.dist end)
            for i = 1, HIGHLIGHT_POOL_SIZE do
                local hl = highlightPool[i]
                local target = validTargets[i]
                if target and i <= 15 then 
                    hl.Adornee = target.plr.Character
                    hl.FillColor = Color3.fromRGB(255, 50, 50)
                else
                    hl.Adornee = nil
                end
            end
        else
            for i = 1, HIGHLIGHT_POOL_SIZE do highlightPool[i].Adornee = nil end
        end
        
        -- 透视渲染 (高频)
        if not Config.ESP then
            for _, d in pairs(espCache) do d.box.Visible = false; d.nameTxt.Visible = false; d.distTxt.Visible = false end
        else
            for plr, data in pairs(espCache) do
                pcall(function()
                    if plr.Character then
                        local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                        local head = plr.Character:FindFirstChild("Head")
                        local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                        if hrp and head and hum and hum.Health > 0 then
                            local headPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                            if onScreen then
                                local distance = math.floor((Camera.CFrame.Position - hrp.Position).Magnitude / 3)
                                data.box.Visible = true; data.box.Size = UDim2.fromOffset(40, 60); data.box.Position = UDim2.fromOffset(headPos.X - 20, headPos.Y + 10)
                                data.nameTxt.Visible = true; data.nameTxt.Text = plr.Name; data.nameTxt.Position = UDim2.fromOffset(headPos.X, headPos.Y - 10)
                                data.distTxt.Visible = true; data.distTxt.Text = tostring(distance) .. "m"; data.distTxt.Position = UDim2.fromOffset(headPos.X, headPos.Y + 75)
                            else
                                data.box.Visible = false; data.nameTxt.Visible = false; data.distTxt.Visible = false
                            end
                        else
                            data.box.Visible = false; data.nameTxt.Visible = false; data.distTxt.Visible = false
                        end
                    else
                        data.box.Visible = false; data.nameTxt.Visible = false; data.distTxt.Visible = false
                    end
                end)
            end
        end
    end
end)

print("[DeepSeek] 神级满配版加载完毕")