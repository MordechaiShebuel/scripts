local function jsonEscape(s)
    return '"' .. s:gsub('[%z\1-\31\\"]', function(c)
        local escapes = {
            ['"'] = '\\"',
            ['\\'] = '\\\\',
            ['\b'] = '\\b',
            ['\f'] = '\\f',
            ['\n'] = '\\n',
            ['\r'] = '\\r',
            ['\t'] = '\\t',
        }
        return escapes[c] or string.format("\\u%04x", c:byte())
    end) .. '"'
end

local function toJson(value, seen)
    local kind = type(value)

    if kind == "nil" then
        return "null"
    elseif kind == "boolean" or kind == "number" then
        return tostring(value)
    elseif kind == "string" then
        return jsonEscape(value)
    elseif kind ~= "table" then
        error("Unsupported JSON value type: " .. kind)
    end

    seen = seen or {}
    assert(not seen[value], "Cannot encode a cyclic table")
    seen[value] = true

    local parts = {}
    local isArray = true
    local count = 0

    for key in pairs(value) do
        count = count + 1
        if type(key) ~= "number" or key < 1 or key % 1 ~= 0 then
            isArray = false
        end
    end

    if isArray then
        for i = 1, count do
            assert(value[i] ~= nil, "Cannot encode sparse array")
            parts[i] = toJson(value[i], seen)
        end
        seen[value] = nil
        return "[" .. table.concat(parts, ",") .. "]"
    end

    for key, item in pairs(value) do
        assert(type(key) == "string", "JSON object keys must be strings")
        parts[#parts + 1] = jsonEscape(key) .. ":" .. toJson(item, seen)
    end

    seen[value] = nil
    return "{" .. table.concat(parts, ",") .. "}"
end

return toJson
