-- 最基础兼容版本，放弃高级排版
local Queue = {}
local MAX_LINES = 50
local container = game:GetService("CoreGui")

local gui = Instance.new("ScreenGui")
gui.Name = "Z"
gui.DisplayOrder = 9999999
gui.IgnoreGuiInset = true
gui.Parent = container

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 450, 0, 500)
frame.Position = UDim2.new(0, 10, 0, 10)
frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
frame.BackgroundTransparency = 0.2
frame.BorderSizePixel = 1
frame.BorderColor3 = Color3.fromRGB(255, 255, 255)
frame.Parent = gui

local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, -20, 1, -20)
label.Position = UDim2.new(0, 10, 0, 10)
label.BackgroundTransparency = 1
label.Text = "等待抓包..."
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.TextXAlignment = Enum.TextXAlignment.Left
label.TextYAlignment = Enum.TextYAlignment.Top
label.Font = Enum.Font.Code
label.TextSize = 11
label.TextWrapped = true
label.Parent = frame

-- 核心抓包逻辑
local function simpleSer(v)
    local t = typeof(v)
    if t == "Instance" then return v.ClassName .. ":" .. v.Name
    elseif t == "Vector3" then return "V3"
    elseif t == "CFrame" then return "CF"
    elseif t == "table" then return "{...}"
    else return tostring(v) end
end

local ok, mt = pcall(function() return getrawmetatable(game) end)
if not ok then
    print("[抓包失败] 不支持 getrawmetatable")
    label.Text = "不支持 getrawmetatable"
    return
end

local oldNamecall = mt.__namecall
setreadonly(mt, false)
mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if method == "FireServer" or method == "InvokeServer" then
        pcall(function()
            local n = tostring(self.Name):lower()
            -- 过滤高频垃圾包
            if not (n:find("pos") or n:find("cframe") or n:find("ping") or n:find("move") or n:find("mouse") or n:find("update")) then
                local args = {...}
                local parts = {}
                for i = 1, math.min(#args, 5) do
                    parts[i] = simpleSer(args[i])
                end
                local line = "["..method.."] "..self.Name.." -> "..table.concat(parts, ", ")
                
                -- 1. 塞进面板
                table.insert(Queue, line)
                if #Queue > MAX_LINES then table.remove(Queue, 1) end
                
                -- 2. 塞进控制台
                print("[NET] " .. line)
            end
        end)
    end
    return oldNamecall(self, ...)
end)
setreadonly(mt, true)

-- 独立 UI 刷新
task.spawn(function()
    local lastCount = 0
    while task.wait(0.5) do
        if #Queue ~= lastCount then
            lastCount = #Queue
            label.Text = table.concat(Queue, "\n")
        end
    end
end)

print("极简版抓包已启动。去开枪。")