-- ==========================================
-- 可拖动悬浮窗：全量动作抓包 (杀戮链路)
-- ==========================================
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LP = Players.LocalPlayer

local container = (type(gethui) == "function") and gethui() or game:GetService("CoreGui")
if container:FindFirstChild("KillDiag") then container.KillDiag:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "KillDiag"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 999999
gui.Parent = container

-- [ 主窗口 ]
local main = Instance.new("Frame")
main.Size = UDim2.new(0, 500, 0, 400)
main.Position = UDim2.new(0, 50, 0, 50)
main.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
main.BackgroundTransparency = 0.1
main.BorderSizePixel = 0
main.Parent = gui

-- [ 拖动标题栏 ]
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 35)
titleBar.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
titleBar.BorderSizePixel = 0
titleBar.Parent = main

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, -60, 1, 0)
titleText.Position = UDim2.new(0, 10, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = " 按住此红色条拖动 | KILL-DIAG"
titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Font = Enum.Font.SourceSansBold
titleText.TextSize = 16
titleText.Parent = titleBar

-- [ 关闭按钮 ]
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 40, 1, 0)
closeBtn.Position = UDim2.new(1, -40, 0, 0)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.TextSize = 18
closeBtn.Parent = titleBar
closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

-- [ 滚动区 ]
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -10, 1, -45)
scroll.Position = UDim2.new(0, 5, 0, 40)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 8
scroll.ScrollBarImageColor3 = Color3.fromRGB(200, 0, 0)
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.Parent = main

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 2)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scroll

-- ==========================================
-- 拖动逻辑实现 (手指触控支持)
-- ==========================================
local dragging = false
local dragStart = nil
local startPos = nil

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = main.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- ==========================================
-- 抓包核心逻辑
-- ==========================================
local Queue = {}
local MAX_LINES = 60

local function pushLog(text)
    table.insert(Queue, text)
    if #Queue > MAX_LINES then table.remove(Queue, 1) end
end

local function simpleSer(v)
    local t = typeof(v)
    if t == "Instance" then return v.ClassName .. ":" .. v.Name
    elseif t == "Vector3" then return string.format("V3(%.1f,%.1f,%.1f)", v.X, v.Y, v.Z)
    elseif t == "CFrame" then return "CF"
    elseif t == "table" then return "{...}"
    else return tostring(v) end
end

-- 1. 底层 Hook 监听 Remote
local ok, mt = pcall(function() return getrawmetatable(game) end)
if ok then
    local oldNamecall = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if method == "FireServer" or method == "InvokeServer" then
            pcall(function()
                local n = tostring(self.Name):lower()
                -- 过滤高频无意义包，只抓动作包
                if not (n:find("pos") or n:find("cframe") or n:find("ping") or n:find("move") or n:find("mouse")) then
                    local args = {...}
                    local parts = {}
                    for i = 1, math.min(#args, 5) do
                        parts[i] = simpleSer(args[i])
                    end
                    pushLog("[" .. method .. "] " .. self.Name)
                    pushLog(" -> " .. table.concat(parts, ", "))
                    pushLog("----------")
                end
            end)
        end
        return oldNamecall(self, ...)
    end)
    setreadonly(mt, true)
else
    pushLog("执行器不支持 getrawmetatable，抓不到 Remote。")
end

-- 2. 监听武器开火 (如果有 Tool)
local function watchTool(char)
    char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            pushLog(">> 装备了武器: " .. child.Name)
            child.Activated:Connect(function()
                pushLog(">>> 触发了 Tool.Activated <<<")
            end)
        end
    end)
end

if LP.Character then watchTool(LP.Character) end
LP.CharacterAdded:Connect(watchTool)

-- 3. 监听所有人掉血
for _, p in ipairs(Players:GetPlayers()) do
    if p.Character then
        local hum = p.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            local lastHp = hum.Health
            hum.HealthChanged:Connect(function(hp)
                if hp < lastHp then
                    pushLog("!! [" .. p.Name .. "] 掉血: " .. math.floor(lastHp) .. " -> " .. math.floor(hp))
                end
                lastHp = hp
            end)
        end
    end
end

-- ==========================================
-- 独立渲染线程 (防止卡顿)
-- ==========================================
task.spawn(function()
    local lastCount = 0
    while task.wait(0.3) do
        if #Queue ~= lastCount then
            lastCount = #Queue
            
            -- 清理旧标签 (只清理并重绘，这次足够快)
            for _, c in ipairs(scroll:GetChildren()) do
                if c:IsA("TextLabel") then c:Destroy() end
            end
            
            -- 渲染新标签
            for i, text in ipairs(Queue) do
                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(1, -10, 0, 0)
                lbl.AutomaticSize = Enum.AutomaticSize.Y
                lbl.BackgroundTransparency = 1
                lbl.Text = text
                lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.TextYAlignment = Enum.TextYAlignment.Top
                lbl.Font = Enum.Font.Code
                lbl.TextSize = 12
                lbl.TextWrapped = true
                lbl.Parent = scroll
            end
            
            scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
            scroll.CanvasPosition = Vector2.new(0, scroll.CanvasSize.Y.Offset)
        end
    end
end)

pushLog("【抓包已启动】")
pushLog("1. 拿枪开火，看有无 [FireServer] 输出。")
pushLog("2. 如果没有，看有无 [Activated] 输出。")
pushLog("3. 如果只有掉血日志，说明开火不走 Remote。")