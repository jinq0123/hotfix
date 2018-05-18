--- Replace functions of table or upvalue.

local M = {}

-- Map old function to new functions.
-- Used to replace functions finally.
M.updated_func_map = {}

-- Objects that have replaced functions.
M.replaced_obj = {}

-- Do not update and replace protected objects.
-- Set to hotfix.protected
M.protected = {}

-- Replace all updated functions.
-- Record all replaced objects in M.replaced_obj.
function M.replace_functions(obj)
    if protected[obj] then return end
    local obj_type = type(obj)
    if "function" ~= obj_type and "table" ~= obj_type then return end
    if replaced_obj[obj] then return end
    replaced_obj[obj] = true
    assert(obj ~= updated_func_map)

    if "function" == obj_type then
        for i = 1, math.huge do
            local name, value = debug.getupvalue(obj, i)
            if not name then return end
            local new_func = updated_func_map[value]
            if new_func then
                assert("function" == type(value))
                debug.setupvalue(obj, i, new_func)
                replace_functions(new_func)
            else
                replace_functions(value)
            end
        end  -- for
        assert(false, "Can not reach here!")
    end  -- if "function"

    -- for table
    replace_functions(debug.getmetatable(obj))
    local new = {}  -- to assign new fields
    for k, v in pairs(obj) do
        local new_k = updated_func_map[k]
        local new_v = updated_func_map[v]
        if new_k then
            obj[k] = nil  -- delete field
            new[new_k] = new_v or v
        else
            obj[k] = new_v or v
            replace_functions(k)
        end
        if not new_v then replace_functions(v) end
        if new_k then replace_functions(new_k) end
        if new_v then replace_functions(new_v) end
    end  -- for k, v
    for k, v in pairs(new) do obj[k] = v end
end  -- replace_functions(obj)

return M
