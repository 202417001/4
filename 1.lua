-- 移动端底层 __namecall Hook 诊断
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local LINES = {}

local container = (type(gethui) == "function") and gethui() or game:GetService("CoreGui")
local gui = Instance.new("ScreenGui", container); gui.Name = "x"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 500, 0, 500)
frame.Position = UDim2.new(0, 20, 0, 20)
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
frame.BackgroundTransparency = 0.1

local label = Instance.new("TextLabel", frame)
label.Size = UDim2.new(1, -10, 1, -10)
label.Position = UDim2.new(0, 5, 0, 5)
label.BackgroundTransparency = 1
label.TextColor3 = Color3.fromRGB(200, 200, 200)
label.TextXAlignment = Enum.TextXAlignment.Left
label.TextYAlignment = Enum.TextYAlignment.Top
label.Font = Enum.Font.Code
label.TextSize = 12
label.TextWrapped = true

local function log(s)
    table.insert(LINES, s)
    if #LINES > 50 then table.remove(LINES, 1) end
    label.Text = table.concat(LINES, "\n")
end

local function ser(v)
    local t = typeof(v)
    if t == "Instance" then return v.ClassName .. ":" .. v.Name
    elseif t == "Vector3" then return string.format("V3(%.1f,%.1f,%.1f)", v.X, v.Y, v.Z)
    elseif t == "CFrame" then return "CFrame"
    elseif t == "table" then return "Table"
    else return tostring(v) end
end

-- 尝试底层 Hook
local ok, oldNamecall = pcall(function() return getrawmetatable(game).__namecall end)
if not ok then
    log("你的执行器不支持 getrawmetatable，抓包彻底失败。")
    return
end

setreadonly(getrawmetatable(game), false)
getrawmetatable(game).__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if method == "FireServer" or method == "InvokeServer" then
        local args = {...}
        local parts = {}
        for i = 1, math.min(#args, 5) do
            parts[i] = ser(args[i])
        end
        
        -- 过滤只打印相关的 Remote，避免刷屏
        local n = tostring(self.Name):lower()
        if n:find("weapon") or n:find("combat") or n:find("hit") or n:find("damage") or n:find("shoot") or n:find("gun") or n:find("eat") or n:find("stam") then
            log("["..method.."] "..self:GetFullName())
            log("  -> "..table.concat(parts, ", "))
        end
    end
    return oldNamecall(self, ...)
end)
setreadonly(getrawmetatable(game), true)

log("底层 Hook 成功。开枪/挥刀/吃东西，看面板。")