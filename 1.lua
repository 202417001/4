local LINES = {}
local MAX_LINES = 100
local container = (type(gethui) == "function") and gethui() or game:GetService("CoreGui")
local gui = Instance.new("ScreenGui", container); gui.Name = "x"

-- 主面板
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 500, 0, 550)
frame.Position = UDim2.new(0, 15, 0, 50)
frame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
frame.BackgroundTransparency = 0.1
frame.BorderSizePixel = 1
frame.BorderColor3 = Color3.fromRGB(100, 100, 100)

-- 标题（提醒可以滑动）
local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
title.Text = " 抓包中... 手指按住内容区上下滑动"
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
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)

local layout = Instance.new("UIListLayout", scroll)
layout.Padding = UDim.new(0, 2)
layout.SortOrder = Enum.SortOrder.LayoutOrder

local function log(s)
    table.insert(LINES, s)
    if #LINES > MAX_LINES then table.remove(LINES, 1) end
    
    -- 清空旧的显示，重新渲染，防止排版混乱
    for _, child in ipairs(scroll:GetChildren()) do
        if child:IsA("TextLabel") then child:Destroy() end
    end
    
    for i, v in ipairs(LINES) do
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, -10, 0, 0)
        l.AutomaticSize = Enum.AutomaticSize.Y
        l.BackgroundTransparency = 1
        l.Text = v
        l.TextColor3 = Color3.fromRGB(200, 200, 200)
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.TextYAlignment = Enum.TextYAlignment.Top
        l.Font = Enum.Font.Code
        l.TextSize = 12
        l.TextWrapped = true
        l.Parent = scroll
    end
    
    -- 自动滚到最底
    task.defer(function()
        scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
        scroll.CanvasPosition = Vector2.new(0, layout.AbsoluteContentSize.Y)
    end)
end

local function ser(v)
    local t = typeof(v)
    if t == "Instance" then return v.ClassName .. ":" .. v.Name
    elseif t == "Vector3" then return string.format("V3(%.1f,%.1f,%.1f)", v.X, v.Y, v.Z)
    elseif t == "CFrame" then return "CF"
    elseif t == "table" then 
        local str = "{"
        local c = 0
        for k, val in pairs(v) do 
            c = c + 1
            if c > 4 then str = str .. "...}" break end
            str = str .. tostring(k) .. "=" .. tostring(val) .. "," 
        end
        return str .. "}"
    else return tostring(v) end
end

local ok, oldNamecall = pcall(function() return getrawmetatable(game).__namecall end)
if not ok then
    log("你的执行器不支持 getrawmetatable。")
    return
end

setreadonly(getrawmetatable(game), false)
getrawmetatable(game).__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if method == "FireServer" or method == "InvokeServer" then
        local args = {...}
        local parts = {}
        for i = 1, math.min(#args, 6) do
            parts[i] = ser(args[i])
        end
        
        local n = tostring(self.Name):lower()
        -- 过滤高频无意义的包，只要动作包
        if not (n:find("pos") or n:find("cframe") or n:find("ping") or n:find("mouse") or n:find("camera") or n:find("move")) then
            log("["..method.."] "..self.Name)
            log(" -> "..table.concat(parts, ", "))
            log("----------")
        end
    end
    return oldNamecall(self, ...)
end)
setreadonly(getrawmetatable(game), true)

log("全量抓包已启动。开枪/挥刀，别动鼠标视角。")