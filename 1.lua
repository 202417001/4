-- ==========================================
-- 暴力美学 UI：粒子爱心 + 完整功能菜单
-- ==========================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

local container = (type(gethui) == "function") and gethui() or game:GetService("CoreGui")

-- 清理旧 UI 防止重叠
if container:FindFirstChild("RemUI") then container.RemUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RemUI"
ScreenGui.IgnoreGuiInset = true
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999999
ScreenGui.Parent = container

-- ==========================================
-- 第一部分：开场粒子爱心动画
-- ==========================================
local introFrame = Instance.new("Frame")
introFrame.Size = UDim2.new(1, 0, 1, 0)
introFrame.BackgroundColor3 = Color3.fromRGB(5, 5, 5)
introFrame.BackgroundTransparency = 0
introFrame.ZIndex = 10
introFrame.Parent = ScreenGui

local function createParticle(startX, startY, targetX, targetY, delay)
    local p = Instance.new("Frame")
    p.Size = UDim2.new(0, 4, 0, 4)
    p.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    p.BorderSizePixel = 0
    p.Position = UDim2.new(0, startX, 0, startY)
    p.ZIndex = 11
    local corner = Instance.new("UICorner", p)
    corner.CornerRadius = UDim.new(1, 0)
    p.Parent = introFrame

    task.delay(delay, function()
        local tween = TweenService:Create(p, TweenInfo.new(1.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, targetX, 0, targetY)
        })
        tween:Play()
    end)
    return p
end

-- 计算爱心轨迹参数方程
local heartPoints = {}
local centerX = ScreenGui.AbsoluteSize.X / 2 or 960 / 2
local centerY = ScreenGui.AbsoluteSize.Y / 2 or 540 / 2
-- 如果 AbsoluteSize 为 0，给个默认值
if centerX == 0 then centerX = 500; centerY = 300 end

for i = 0, math.pi * 2, 0.15 do
    local x = 16 * math.pow(math.sin(i), 3)
    local y = -(13 * math.cos(i) - 5 * math.cos(2*i) - 2 * math.cos(3*i) - math.cos(4*i))
    -- 放大并居中
    local px = centerX + x * 7
    local py = centerY + y * 7
    table.insert(heartPoints, {x = px, y = py})
end

-- 生成粒子
local particles = {}
for _, pt in ipairs(heartPoints) do
    local startX = math.random(0, ScreenGui.AbsoluteSize.X or 1000)
    local startY = math.random(0, ScreenGui.AbsoluteSize.Y or 600)
    local delay = math.random(1, 20) / 10
    table.insert(particles, createParticle(startX, startY, pt.x, pt.y, delay))
end

-- 文字显示容器
local textContainer = Instance.new("Frame")
textContainer.Size = UDim2.new(1, 0, 0, 200)
textContainer.Position = UDim2.new(0, 0, 0.5, -100)
textContainer.BackgroundTransparency = 1
textContainer.ZIndex = 12
textContainer.Parent = introFrame

local introText = Instance.new("TextLabel")
introText.Size = UDim2.new(1, 0, 1, 0)
introText.BackgroundTransparency = 1
introText.Text = ""
introText.TextColor3 = Color3.fromRGB(255, 50, 50)
introText.Font = Enum.Font.GothamBold
introText.TextSize = 28
introText.TextTransparency = 1
introText.TextWrapped = true
introText.ZIndex = 12
introText.Parent = textContainer

-- 动画序列
task.spawn(function()
    task.wait(2.5) -- 等待爱心聚合
    
    -- 粒子散开
    for _, p in ipairs(particles) do
        TweenService:Create(p, TweenInfo.new(1), {
            Position = UDim2.new(0, p.Position.X.Offset + math.random(-200, 200), 0, p.Position.Y.Offset + math.random(-200, 200)),
            BackgroundTransparency = 1
        }):Play()
    end

    task.wait(0.5)
    
    -- 文字演变
    local messages = {
        "别人成双成对，你也不必羡慕。",
        "孤独，是强者的必修课。",
        "既然世界对你无情，",
        "那就用最暴力的手段回击。",
        "我来帮助你。"
    }

    for _, msg in ipairs(messages) do
        introText.Text = msg
        introText.Position = UDim2.new(0, 0, 0, 0)
        TweenService:Create(introText, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
        task.wait(2)
        TweenService:Create(introText, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
        task.wait(0.6)
    end

    -- 结束动画，淡出黑幕
    TweenService:Create(introFrame, TweenInfo.new(1), {BackgroundTransparency = 1}):Play()
    TweenService:Create(introText, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
    task.wait(1)
    introFrame:Destroy()
    
    -- 显示主菜单
    if _G.ShowMainMenu then _G.ShowMainMenu() end
end)


-- ==========================================
-- 第二部分：主功能面板
-- ==========================================
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 480, 0, 600)
mainFrame.Position = UDim2.new(0.5, -240, 0.5, -300)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
mainFrame.BackgroundTransparency = 0.1
mainFrame.BorderSizePixel = 2
mainFrame.BorderColor3 = Color3.fromRGB(200, 0, 0)
mainFrame.Visible = false
mainFrame.Parent = ScreenGui

-- 标题栏
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = Color3.fromRGB(30, 0, 0)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, -20, 1, 0)
titleText.Position = UDim2.new(0, 10, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "REVENGE // 终极火力"
titleText.TextColor3 = Color3.fromRGB(255, 50, 50)
titleText.Font = Enum.Font.GothamBold
titleText.TextSize = 18
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleBar

-- 关闭按钮
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 40, 1, 0)
closeBtn.Position = UDim2.new(1, -40, 0, 0)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 18
closeBtn.Parent = titleBar
closeBtn.MouseButton1Click:Connect(function() mainFrame.Visible = false end)

-- 滑动列表区
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -20, 1, -60)
scroll.Position = UDim2.new(0, 10, 0, 50)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 6
scroll.ScrollBarImageColor3 = Color3.fromRGB(255, 0, 0)
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.Parent = mainFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 10)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = scroll

-- 功能开关生成器
local function createToggle(name, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 45)
    btn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    btn.BorderSizePixel = 1
    btn.BorderColor3 = Color3.fromRGB(60, 60, 60)
    btn.Text = "  [ OFF ]  " .. name
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 16
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Parent = scroll

    local state = false
    btn.MouseButton1Click:Connect(function()
        state = not state
        if state then
            btn.Text = "  [ ON  ]  " .. name
            btn.TextColor3 = Color3.fromRGB(255, 50, 50)
            btn.BorderColor3 = Color3.fromRGB(255, 0, 0)
        else
            btn.Text = "  [ OFF ]  " .. name
            btn.TextColor3 = Color3.fromRGB(200, 200, 200)
            btn.BorderColor3 = Color3.fromRGB(60, 60, 60)
        end
        if callback then callback(state) end
    end)
end

-- ==========================================
-- 第三部分：核心功能实现 (飞行/透视/自瞄)
-- ==========================================

-- 1. 子弹追踪 / 静默自瞄 (骨架，依赖执行器 Hook)
local SilentAimEnabled = false
local OriginalNamecall = getrawmetatable(game).__namecall
setreadonly(getrawmetatable(game), false)
getrawmetatable(game).__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if SilentAimEnabled and (method == "Raycast" or method == "FindPartOnRay") then
        -- 简单寻找最近的头部
        local target = nil
        local shortest = math.huge
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
                local head = p.Character.Head
                local dist = (head.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                if dist < shortest then
                    shortest = dist
                    target = head
                end
            end
        end
        if target then
            -- 篡改方向指向目标
            local args = {...}
            -- 假设 Args[2] 是 Direction
            if typeof(args[2]) == "Vector3" then
                args[2] = (target.Position - args[1]).Unit * 999
            end
            return OriginalNamecall(self, table.unpack(args))
        end
    end
    return OriginalNamecall(self, ...)
end)
setreadonly(getrawmetatable(game), true)

-- 2. 飞行功能
local FlyEnabled = false
local BodyVel, BodyGyro
local function toggleFly(state)
    FlyEnabled = state
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    
    if state and hrp then
        BodyVel = Instance.new("BodyVelocity", hrp)
        BodyVel.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        BodyVel.Velocity = Vector3.new(0,0,0)
        BodyGyro = Instance.new("BodyGyro", hrp)
        BodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        BodyGyro.P = 10000
        BodyGyro.CFrame = hrp.CFrame
    else
        if BodyVel then BodyVel:Destroy() end
        if BodyGyro then BodyGyro:Destroy() end
    end
end

RunService.RenderStepped:Connect(function()
    if FlyEnabled and BodyVel and BodyGyro then
        local moveDir = workspace.CurrentCamera.CFrame.LookVector * 50
        BodyVel.Velocity = moveDir
        BodyGyro.CFrame = workspace.CurrentCamera.CFrame
    end
end)
LocalPlayer.CharacterAdded:Connect(function() if FlyEnabled then task.wait(1); toggleFly(true) end end)

-- 3. 人物高亮透视 (受掩体影响)
local ESPEnabled = false
local ESPTable = {}
local function toggleESP(state)
    ESPEnabled = state
    if not state then
        for _, hl in pairs(ESPTable) do hl:Destroy() end
        ESPTable = {}
        return
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local hl = Instance.new("Highlight")
            hl.Name = "ESP_HL"
            hl.Adornee = p.Character
            hl.FillColor = (p.Team and p.Team.TeamColor.Color) or Color3.fromRGB(255, 255, 255)
            hl.FillTransparency = 0.5
            hl.OutlineTransparency = 1
            hl.DepthMode = Enum.HighlightDepthMode.Occluded -- 受掩体影响
            hl.Parent = game:GetService("CoreGui") -- 放在 CoreGui 避免角色污染
            ESPTable[p] = hl
        end
    end
end

-- ==========================================
-- 第四部分：填充列表并显示
-- ==========================================
createToggle("静默自瞄 (子弹追踪)", function(s) SilentAimEnabled = s end)
createToggle("无敌飞行", function(s) toggleFly(s) end)
createToggle("障碍物高亮透视", function(s) toggleESP(s) end)

-- 设置滑动区域高度
task.defer(function()
    scroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 20)
end)

-- 动画结束后显示的入口
_G.ShowMainMenu = function()
    mainFrame.Visible = true
    mainFrame.Size = UDim2.new(0, 0, 0, 0)
    TweenService:Create(mainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 480, 0, 600)
    }):Play()
end

-- 兜底：如果动画脚本卡住，5秒后强制显示
task.delay(5, function()
    if not mainFrame.Visible then _G.ShowMainMenu() end
end)