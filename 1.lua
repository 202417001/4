-- 最稳的抓包悬浮窗，绝对不报错
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LP = Players.LocalPlayer

-- 强制用 PlayerGui，兼容性最高
local pGui = LP:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "DiagGui"
gui.ResetOnSpawn = false
gui.Parent = pGui

-- 主面板
local main = Instance.new("Frame")
main.Size = UDim2.new(0, 450, 0, 400)
main.Position = UDim2.new(0, 20, 0, 100)
main.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
main.BorderSizePixel = 0
main.Active = true -- 开启输入事件支持
main.Parent = gui

-- 拖动条
local dragBar = Instance.new("TextButton") -- 直接用按钮做拖动条，兼容性更好
dragBar.Size = UDim2.new(1, 0, 0, 35)
dragBar.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
dragBar.Text = " 按住我拖动 | 抓包诊断"
dragBar.TextColor3 = Color3.new(1, 1, 1)
dragBar.Font = Enum.Font.SourceSansBold
dragBar.TextSize = 16
dragBar.BorderSizePixel = 0
dragBar.Parent = main

-- 显示区域
local textBox = Instance.new("TextLabel")
textBox.Size = UDim2.new(1, -20, 1, -45)
textBox.Position = UDim2.new(0, 10, 0, 40)
textBox.BackgroundTransparency = 1
textBox.Text = "等待数据..."
textBox.TextColor3 = Color3.fromRGB(0, 255, 0)
textBox.TextXAlignment = Enum.TextXAlignment.Left
textBox.TextYAlignment = Enum.TextYAlignment.Top
textBox.Font = Enum.Font.Code
textBox.TextSize = 12
textBox.TextWrapped = true
textBox.Parent = main

-- ==========================================
-- 最简单的拖动逻辑
-- ==========================================
local dragging = false
local startPos
local startMouse

dragBar.MouseButton1Down:Connect(function()
    dragging = true
    startMouse = UserInputService:GetMouseLocation()
    startPos = main.Position
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        local delta = UserInputService:GetMouseLocation() - startMouse
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- ==========================================
-- 抓包核心
-- ==========================================
local logQueue = {}

local function log(text)
    table.insert(logQueue, text)
    if #logQueue > 30 then table.remove(logQueue, 1) end
    textBox.Text = table.concat(logQueue, "\n")
end

local ok, mt = pcall(function() return getrawmetatable(game) end)
if ok then
    local oldNamecall = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if method == "FireServer" or method == "InvokeServer" then
            pcall(function()
                local n = tostring(self.Name):lower()
                if not (n:find("pos") or n:find("ping") or n:find("move")) then
                    local args = {...}
                    local parts = {}
                    for i = 1, math.min(#args, 3) do
                        parts[i] = typeof(args[i]) == "Instance" and args[i].Name or tostring(args[i])
                    end
                    log("["..method.."] "..self.Name.."\n -> "..table.concat(parts, ", "))
                end
            end)
        end
        return oldNamecall(self, ...)
    end)
    setreadonly(mt, true)
    log("底层抓包已启动。")
else
    log("hook 失败，无法抓包。")
end

-- 监听掉血
for _, p in ipairs(Players:GetPlayers()) do
    if p.Character then
        local hum = p.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            local last = hum.Health
            hum.HealthChanged:Connect(function(h)
                if h < last then
                    log("["..p.Name.."] 掉血: "..math.floor(last).." -> "..math.floor(h))
                end
                last = h
            end)
        end
    end
end