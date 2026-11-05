-- 杀戮链路诊断：Tool 结构 + Remote 参数 + 血量变化
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LP = Players.LocalPlayer
local LINES = {}
local MAX = 500

local function push(s)
    table.insert(LINES, tostring(s))
    if #LINES > MAX then table.remove(LINES, 1) end
end

local container = (type(gethui) == "function") and gethui() or game:GetService("CoreGui")

local gui = Instance.new("ScreenGui")
gui.Name = "a"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true
gui.DisplayOrder = 999; gui.Parent = container

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 560, 0, 680)
frame.Position = UDim2.new(0, 20, 0, 20)
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
frame.BackgroundTransparency = 0.1
frame.BorderSizePixel = 0
frame.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 28)
title.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
title.BorderSizePixel = 0
title.Text = "  KILL-DIAG  |  装备武器挥刀  |  Remote参数 / Tool结构 / 血量变化  "
title.TextColor3 = Color3.fromRGB(255, 100, 100)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.SourceSansBold
title.TextSize = 15
title.Parent = frame

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -8, 1, -36)
scroll.Position = UDim2.new(0, 4, 0, 32)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 6
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.Parent = frame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 1)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scroll

local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, -8, 0, 0)
label.BackgroundTransparency = 1
label.Text = ""
label.TextColor3 = Color3.fromRGB(230, 230, 230)
label.TextXAlignment = Enum.TextXAlignment.Left
label.TextYAlignment = Enum.TextYAlignment.Top
label.Font = Enum.Font.Code
label.TextSize = 12
label.TextWrapped = true
label.AutomaticSize = Enum.AutomaticSize.Y
label.Parent = scroll

local function log(s)
    push(s)
    label.Text = table.concat(LINES, "\n")
    task.defer(function()
        scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
    end)
end

-- 序列化参数，尽量把 Instance/Vector3/table 展开
local function ser(v, depth)
    depth = depth or 0
    if depth > 2 then return "..." end
    local t = typeof(v)
    if t == "Instance" then
        return v.ClassName .. ":" .. v.Name .. (v.Parent and ("<" .. v.Parent.Name) or "")
    elseif t == "Vector3" then
        return string.format("V3(%.1f,%.1f,%.1f)", v.X, v.Y, v.Z)
    elseif t == "CFrame" then
        local p = v.Position
        return string.format("CF(%.1f,%.1f,%.1f)", p.X, p.Y, p.Z)
    elseif t == "table" then
        local parts = {}
        local n = 0
        for k, vv in pairs(v) do
            n = n + 1
            if n > 8 then parts[#parts+1] = "..."; break end
            parts[#parts+1] = tostring(k) .. "=" .. ser(vv, depth + 1)
        end
        return "{" .. table.concat(parts, ",") .. "}"
    else
        return tostring(v)
    end
end

-- ---------- Tool 结构 ----------
local function dumpTool(tool)
    log("======== TOOL: " .. tool.Name .. " ========")
    local ok, kids = pcall(function() return tool:GetChildren() end)
    if not ok then log("  (读不到子物体)"); return end
    for _, c in ipairs(kids) do
        local ex = ""
        if c:IsA("ValueBase") then ex = "  = " .. tostring(c.Value)
        elseif c:IsA("ModuleScript") then ex = "  [Module]"
        elseif c:IsA("LocalScript") or c:IsA("Script") then ex = "  Disabled=" .. tostring(c.Disabled)
        end
        log("  " .. c.ClassName .. " : " .. c.Name .. ex)
    end
    local ok2, attrs = pcall(function() return tool:GetAttributes() end)
    if ok2 and attrs and next(attrs) then
        for k, v in pairs(attrs) do
            log("  [ATTR] " .. tostring(k) .. " = " .. tostring(v))
        end
    end
end

-- ---------- Remote hook ----------
local hookedE, hookedF = {}, {}

local function hookEvent(ev)
    if hookedE[ev] then return end
    hookedE[ev] = true
    local ok = pcall(function()
        local orig = ev.FireServer
        ev.FireServer = function(self, ...)
            local args = {...}
            local parts = {}
            for i = 1, math.min(#args, 8) do
                parts[i] = ser(args[i])
            end
            log("[FIRE] " .. ev:GetFullName() .. " (" .. #args .. ")")
            log("   " .. table.concat(parts, " | "))
            return orig(self, ...)
        end
    end)
    if not ok then log("[hook失败] " .. ev:GetFullName()) end
end

local function hookFunc(rf)
    if hookedF[rf] then return end
    hookedF[rf] = true
    local ok = pcall(function()
        local orig = rf.InvokeServer
        rf.InvokeServer = function(self, ...)
            local args = {...}
            local parts = {}
            for i = 1, math.min(#args, 8) do
                parts[i] = ser(args[i])
            end
            log("[INVOKE] " .. rf:GetFullName() .. " (" .. #args .. ")")
            log("   " .. table.concat(parts, " | "))
            return orig(self, ...)
        end
    end)
    if not ok then log("[hook失败] " .. rf:GetFullName()) end
end

local function scanRemotes(root, depth)
    if depth > 4 then return end
    for _, c in ipairs(root:GetChildren()) do
        if c:IsA("RemoteEvent") then hookEvent(c)
        elseif c:IsA("RemoteFunction") then hookFunc(c)
        end
        scanRemotes(c, depth + 1)
    end
end

-- ---------- Humanoid.Health 监控 ----------
local healthWatch = {}
local function watchCharacter(ch)
    local hum = ch:FindFirstChildOfClass("Humanoid")
    if not hum or healthWatch[hum] then return end
    healthWatch[hum] = true
    local last = hum.Health
    hum.HealthChanged:Connect(function(h)
        local name = ch.Name
        log("[HP] " .. name .. "  " .. string.format("%.1f -> %.1f", last, h))
        last = h
    end)
end

-- ---------- 装备武器时触发 dump ----------
local function onCharacter(ch)
    ch.ChildAdded:Connect(function(c)
        if c:IsA("Tool") then
            task.wait(0.1)
            dumpTool(c)
            log(">> 装备工具，挥刀观察 [FIRE]/[INVOKE] 输出")
        end
    end)
    watchCharacter(ch)
end

-- ---------- 启动 ----------
log("#### KILL-DIAG START ####")
log("1. 扫描 ReplicatedStorage / Workspace 下 Remote ...")
scanRemotes(ReplicatedStorage, 1)
scanRemotes(game:GetService("Workspace"), 1)
log("2. Remote hook 完成")

local ch = LP.Character
if ch then onCharacter(ch) end
LP.CharacterAdded:Connect(onCharacter)

-- 现有角色里如果已经拿着工具
if ch then
    for _, c in ipairs(ch:GetChildren()) do
        if c:IsA("Tool") then dumpTool(c) end
    end
end

-- 监控所有玩家血量，方便看谁被打了
for _, p in ipairs(Players:GetPlayers()) do
    if p.Character then watchCharacter(p.Character) end
    p.CharacterAdded:Connect(watchCharacter)
end
Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(watchCharacter)
end)

log("#### READY — 装备武器，挥几刀，截屏面板 ####")