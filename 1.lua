local Queue = {}
local MAX_LINES = 80
local container = (type(gethui) == "function") and gethui() or game:GetService("CoreGui")
local gui = Instance.new("ScreenGui", container); gui.Name = "x"

-- 主面板
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 520, 0, 550)
frame.Position = UDim2.new(0, 15, 0, 50)
frame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
frame.BackgroundTransparency = 0.1

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
title.Text = " 抓包中... 随便开枪，不会卡死。按住上下滑"
title.TextColor3 = Color3.fromRGB(0, 255, 0)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left

-- 滚动区
local scroll = Instance.new("ScrollingFrame", frame)
scroll.Size = UDim2.new(1, -10, 1, -35)
scroll.Position = UDim2.new(0, 5, 0, 35)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 8

-- 单一超大 Label 用于显示（不再每帧重建实例）
local label = Instance.new("TextLabel", scroll)
label.Size = UDim2.new(1, -10, 0, 0)
label.AutomaticSize = Enum.AutomaticSize.Y
label.BackgroundTransparency = 1
label.TextColor3 = Color3.fromRGB(200, 200, 200)
label.TextXAlignment = Enum.TextXAlignment.Left
label.TextYAlignment = Enum.TextYAlignment.Top
label.Font = Enum.Font.Code
label.TextSize = 12
label.TextWrapped = true

-- ========== 抓包部分 ==========
local function simpleSer(v)
    local t = typeof(v)
    if t == "Instance" then return v.ClassName .. ":" .. v.Name
    elseif t == "Vector3" then return "V3"
    elseif t == "CFrame" then return "CF"
    elseif t == "table" then return "{...}"
    else return tostring(v) end
end

local oldNamecall
local ok, mt = pcall(function() return getrawmetatable(game) end)
if not ok then
    title.Text = " 你的执行器不支持 getrawmetatable。"
    return
end

oldNamecall = mt.__namecall
setreadonly(mt, false)
mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if method == "FireServer" or method == "InvokeServer" then
        -- 必须用 pcall 包住，抓包出错绝对不能影响游戏原本开枪
        pcall(function()
            local n = tostring(self.Name):lower()
            if not (n:find("pos") or n:find("cframe") or n:find("ping") or n:find("move") or n:find("mouse")) then
                local args = {...}
                local parts = {}
                for i = 1, math.min(#args, 5) do
                    parts[i] = simpleSer(args[i])
                end
                local line = "["..method.."] "..self.Name.."\n -> "..table.concat(parts, ", ")
                table.insert(Queue, line)
                if #Queue > MAX_LINES then table.remove(Queue, 1) end
            end
        end)
    end
    return oldNamecall(self, ...)
end)
setreadonly(mt, true)

-- ========== UI 刷新线程（独立运行，不阻塞抓包） ==========
task.spawn(function()
    local lastCount = 0
    while task.wait(0.3) do
        if #Queue ~= lastCount then
            lastCount = #Queue
            label.Text = table.concat(Queue, "\n----------\n")
            scroll.CanvasSize = UDim2.new(0, 0, 0, label.AbsoluteContentSize.Y + 10)
            -- 自动滚到底部
            scroll.CanvasPosition = Vector2.new(0, scroll.CanvasSize.Y.Offset)
        end
    end
end)

print("抓包已启动。开枪测试，不会卡死了。")