Set = {}
Set.__index = Set

function Set:new(list)
    local s = {}
    setmetatable(s, self)
    for _, v in ipairs(list or {}) do
        s[v] = true
    end
    return s
end

function Set:add(value)
    self[value] = true
end

function Set:remove(value)
    self[value] = nil
end

function Set:has(value)
    return self[value] ~= nil
end

function Set:toTable()
    local t = {}
    for k in pairs(self) do
        t[k] = true
    end
    return t
end

return Set
