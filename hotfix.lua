--[[
Lua 5.2/5.3 hotfix. Hot update functions and keep old data.
Author: Jin Qing ( http://blog.csdn.net/jq0123 )
--]]

local M = {}

local update_table
local update_func

-- Updated signature set to prevent self-reference dead loop.
local updated_sig = {}

-- Map old function to new functions.
-- Used to replace functions finally.
local updated_func_map = {}

-- Objects that have replaced functions.
local replaced_obj = {}

-- Do not update and replace protected objects.
local protected = {}

-- Check if function or table has been updated. Return true if updated.
local function check_updated(new_obj, old_obj, name, deep)
    local signature = string.format("new(%s) old(%s)",
        tostring(new_obj), tostring(old_obj))
    M.log_debug(string.format("%sUpdate %s: %s", deep, name, signature))

    if new_obj == old_obj then
        M.log_debug(deep .. "  Same")
        return true
    end
    if updated_sig[signature] then
        M.log_debug(deep .. "  Already updated")
        return true
    end
    updated_sig[signature] = true
    return false
end

-- Update new function with upvalues of old function.
-- Parameter name and deep are only for log.
function update_func(new_func, old_func, name, deep)
    assert("function" == type(new_func))
    assert("function" == type(old_func))
    if protected[old_func] then return end
    if check_updated(new_func, old_func, name, deep) then return end
    deep = deep .. "  "
    updated_func_map[old_func] = new_func

    -- Get upvalues of old function.
    local old_upvalue_map = {}
    for i = 1, math.huge do
        local name, value = debug.getupvalue(old_func, i)
        if not name then break end
        old_upvalue_map[name] = value
    end

    local function log_dbg(name, from, to)
        M.log_debug(string.format("%ssetupvalue %s: (%s) -> (%s)",
            deep, name, tostring(from), tostring(to)))
    end

    -- Update new upvalues with old.
    for i = 1, math.huge do
        local name, value = debug.getupvalue(new_func, i)
        if not name then break end
        local old_value = old_upvalue_map[name]
        if old_value then
            local type_old_value = type(old_value)
            if type_old_value ~= type(value) then
                debug.setupvalue(new_func, i, old_value)
                log_dbg(name, value, old_value)
            elseif type_old_value == "function" then
                update_func(value, old_value, name, deep)
            elseif type_old_value == "table" then
                update_table(value, old_value, name, deep)
                debug.setupvalue(new_func, i, old_value)
            else
                debug.setupvalue(new_func, i, old_value)
                log_dbg(name, value, old_value)
            end
        end  -- if old_value
    end  -- for i
end  -- update_func()

-- Compare 2 tables and update old table. Keep the old data.
function update_table(new_table, old_table, name, deep)
    assert("table" == type(new_table))
    assert("table" == type(old_table))
    if protected[old_table] then return end
    if check_updated(new_table, old_table, name, deep) then return end
    deep = deep .. "  "

    -- Compare 2 tables, and update old table.
    for key, value in pairs(new_table) do
        local old_value = old_table[key]
        local type_value = type(value)
        if type_value ~= type(old_value) then
            old_table[key] = value
            M.log_debug(string.format("%sUpdate field %s: (%s) -> (%s)",
                deep, key, tostring(old_value), tostring(value)))
        elseif type_value == "function" then
            update_func(value, old_value, key, deep)
        elseif type_value == "table" then
            update_table(value, old_value, key, deep)
        end
    end  -- for

    -- Update metatable.
    local old_meta = debug.getmetatable(old_table)
    local new_meta = debug.getmetatable(new_table)
    if type(old_meta) == "table" and type(new_meta) == "table" then
        update_table(new_meta, old_meta, name.."'s Meta", deep)
    end
end  -- update_table()

-- Update new loaded object with package.loaded[module_name].
local function update_loaded_module(new_obj, module_name)
    assert(nil ~= new_obj)
    assert("string" == type(module_name))
    local old_obj = package.loaded[module_name]
    local new_type = type(new_obj)
    local old_type = type(old_obj)
    if new_type == old_type then
        if "table" == new_type then
            update_table(new_obj, old_obj, module_name, "")
            return
        end
        if "function" == new_type then
            update_func(new_obj, old_obj, module_name, "")
            return;
        end
    end  -- if new_type == old_type
    M.log_debug(string.format("Directly replace module: old(%s) -> new(%s)",
        tostring(old_obj), tostring(new_obj)))
    package.loaded[module_name] = new_obj
end  -- update_loaded_module

-- Replace all updated functions.
-- Record all visited objects.
local function replace_functions(obj)
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
    end  -- for k, v
    for k, v in pairs(new) do obj[k] = v end
end  -- replace_functions(obj)

-- To protect self.
local function add_self_to_protect()
    M.add_protect{
        M,
        M.hotfix_module,
        M.log_error,
        M.log_info,
        M.log_debug,
        M.add_protect,
        M.remove_protect,
    }
end  -- add_self_to_protect

-- Usage: hotfix_module("mymodule.sub_module")
-- Returns package.loaded[module_name].
function M.hotfix_module(module_name)
    assert("string" == type(module_name))
    M.log_debug("Hot fix module: " .. module_name)
    add_self_to_protect()

    local file_path = assert(package.searchpath(module_name, package.path))
    local fp = assert(io.open(file_path))
    local chunk = fp:read("*all")
    fp:close()

    -- Load chunk.
    local func = assert(load(chunk, '@'..file_path))
    local ok, obj = assert(pcall(func))
    if nil == obj then obj = true end  -- obj may be false

    -- Update package.loaded[module_name].
    updated_sig = {}
    updated_func_map = {}
    do
        update_loaded_module(obj, module_name)

        if next(updated_func_map) then
            replaced_obj = {}
            replace_functions(_G)
            replace_functions(debug.getregistry())
            replaced_obj = {}
        end  -- if
    end  -- do
    updated_func_map = {}
    updated_sig = {}
    return package.loaded[module_name]
end

-- User can set log functions. Default is no log.
-- Like: require("hotfix").log_info = function(s) mylog:info(s) end
function M.log_error(msg_str) end
function M.log_info(msg_str) end
function M.log_debug(msg_str) end

-- Add objects to protect.
-- Example: add_protect({table, math, print})
function M.add_protect(object_array)
    for _, obj in pairs(object_array) do
        protected[obj] = true
    end
end  -- add_protect()

-- Remove objects in protected set.
-- Example: remove_protect({table, math, print})
function M.remove_protect(object_array)
    for _, obj in pairs(object_array) do
        protected[obj] = nil
    end
end  -- remove_protect()

return M
