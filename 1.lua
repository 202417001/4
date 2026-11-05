-- 诊断面板：显示饥饿/耐力相关数值落点，供截屏
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LP = Players.LocalPlayer
local LINES = {}
local MAX_LINES = 400

local function push(s)
    table.insert(LINES, tostring(s))
    if #LINES > MAX_LINES then table.remove(LINES, 1) end
end

-- ---------- 容器：优先 gethui，退回 CoreGui ----------
local container
if type(gethui) == "function" then
    container = gethui()
else
    container = game:GetService("CoreGui")
end

local gui = Instance.new("ScreenGui")
gui.Name = "a"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999
gui.Parent = container

-- ---------- 面板主体 ----------
local frame = Instance.new("Frame")
frame.Name = "b"
frame.Size = UDim2.new(0, 520, 0, 640)
frame.Position = UDim2.new(0, 20, 0, 20)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.BackgroundTransparency = 0.15
frame.BorderSizePixel = 0
frame.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 28)
title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
title.BorderSizePixel = 0
title.Text = "  DIAG  |  饥饿/耐力诊断  |  滚动查看  "
title.TextColor3 = Color3.fromRGB(0, 220, 120)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.SourceSansBold
title.TextSize = 16
title.Parent = frame

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -8, 1, -36)
scroll.Position = UDim2.new(0, 4, 0, 32)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 6
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.Parent = frame

local list = Instance.new("UIListLayout")
list.Padding = UDim.new(0, 1)
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Parent = scroll

local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, -8, 0, 0)
label.BackgroundTransparency = 1
label.Text = ""
label.TextColor3 = Color3.fromRGB(230, 230, 230)
label.TextXAlignment = Enum.TextXAlignment.Left
label.TextYAlignment = Enum.TextYAlignment.Top
label.Font = Enum.Font.Code
label.TextSize = 13
label.TextWrapped = true
label.AutomaticSize = Enum.AutomaticSize.Y
label.Parent = scroll

-- 实时输出区（Remote 触发）
local liveBox = Instance.new("TextLabel")
liveBox.Size = UDim2.new(1, -8, 0, 90)
liveBox.Position = UDim2.new(0, 4, 1, -94)
liveBox.BackgroundColor3 = Color3.fromRGB(30, 10, 10)
liveBox.BackgroundTransparency = 0.2
liveBox.BorderSizePixel = 0
liveBox.Text = "LIVE REMOTE:\n"
liveBox.TextColor3 = Color3.fromRGB(255, 180, 80)
liveBox.TextXAlignment = Enum.TextXAlignment.Left
liveBox.TextYAlignment = Enum.TextYAlignment.Top
liveBox.Font = Enum.Font.Code
liveBox.TextSize = 12
liveBox.TextWrapped = true
liveBox.Parent = frame

-- ---------- 写日志 ----------
local function log(s)
    push(s)
    label.Text = table.concat(LINES, "\n")
    task.defer(function()
        scroll.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 10)
    end)
end

local liveLines = {}
local function live(s)
    table.insert(liveLines, s)
    if #liveLines > 6 then table.remove(liveLines, 1) end
    liveBox.Text = "LIVE REMOTE:\n" .. table.concat(liveLines, "\n")
end

-- ---------- 扫描函数 ----------
local function dumpAttrs(obj, tag)
    log("== ATTR " .. tag .. " ==")
    local ok, attrs = pcall(function() return obj:GetAttributes() end)
    if not ok or not attrs or next(attrs) == nil then
        log("  (empty)"); return
    end
    for k, v in pairs(attrs) do
        log("  " .. tostring(k) .. " = " .. tostring(v))
    end
end

local function dumpKids(obj, tag)
    log("== CHILD " .. tag .. " ==")
    local ok, kids = pcall(function() return obj:GetChildren() end)
    if not ok or not kids or #kids == 0 then
        log("  (empty)"); return
    end
    for _, c in ipairs(kids) do
        local ex = ""
        if c:IsA("ValueBase") then
            ex = "  = " .. tostring(c.Value)
        elseif c:IsA("LocalScript") then
            ex = "  Disabled=" .. tostring(c.Disabled)
        elseif c:IsA("Tool") then
            ex = "  [TOOL]"
        end
        log("  " .. c.ClassName .. " : " .. c.Name .. ex)
    end
end

local function walkScripts(node, depth)
    if depth > 4 then return end
    for _, c in ipairs(node:GetChildren()) do
        if c:IsA("LocalScript") then
            log(string.rep("  ", depth) .. "LS: " .. c.Name .. "  Disabled=" .. tostring(c.Disabled))
        end
        walkScripts(c, depth + 1)
    end
end

local function dumpGUI()
    log("== PlayerGui LocalScripts ==")
    local pg = LP:FindFirstChild("PlayerGui")
    if not pg then log("  (no PlayerGui)"); return end
    pcall(walkScripts, pg, 1)
end

-- Remote hook
local hooked = {}
local function hookRoot(root, tag)
    local function scan(node, d)
        if d > 3 then return end
        for _, c in ipairs(node:GetChildren()) do
            if c:IsA("RemoteEvent") and not hooked[c] then
                hooked[c] = true
                pcall(function()
                    c.OnClientEvent:Connect(function(...)
                        local args = {...}
                        local parts = {}
                        for i = 1, math.min(#args, 5) do
                            parts[i] = tostring(args[i])
                        end
                        local name = c.Name:lower()
                        local hit = name:find("hung") or name:find("stam")
                            or name:find("energy") or name:find("food")
                            or name:find("eat") or name:find("drink")
                            or name:find("stat") or name:find("survival")
                        local line = (hit and ">> " or "   ") .. c.Name .. "(" .. #args .. "): " .. table.concat(parts, ", ")
                        live(line)
                        if hit then log("[HIT] " .. line) end
                    end)
                end)
            end
            scan(c, d + 1)
        end
    end
    pcall(scan, root, 1)
end

-- ---------- 全量执行 ----------
local function fullScan()
    LINES = {}
    log("#### FULL SCAN START ####")
    dumpAttrs(LP, "LocalPlayer")
    dumpKids(LP, "LocalPlayer")

    local ch = LP.Character
    if ch then
        dumpAttrs(ch, "Character")
        dumpKids(ch, "Character")
        local hum = ch:FindFirstChildOfClass("Humanoid")
        if hum then dumpAttrs(hum, "Humanoid") end
    else
        log("(no Character yet)")
    end

    dumpGUI()
    log("== Remote Hooks installed ==")
    hookRoot(ReplicatedStorage, "RS")
    hookRoot(game:GetService("Workspace"), "WS")
    log("#### SCAN DONE ####")
    log("正常吃喝/跑步，让数值变化，看 LIVE 区哪条参数在动。")
end

fullScan()

LP.CharacterAdded:Connect(function()
    task.wait(2)
    log("#### RESPAWN RESCAN ####")
    dumpAttrs(LP.Character, "Character(new)")
    dumpKids(LP.Character, "Character(new)")
end)