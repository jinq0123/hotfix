--[[
Lua 5.2/5.3 hotfix. Hot update functions and keep old data.
Author: Jin Qing ( http://blog.csdn.net/jq0123 )
--]]

local M = {}

local update_table
local update_func

-- Visited signatures to prevent dead loop.
local visited_sig = {}  -- TODO delete

-- Record undated old tables to prevent self-reference dead loop.
local updated_old_tables = {}

-- Map old function to new functions.
-- To prevent self-reference dead loop.
-- Also used to replace functions finally.
local updated_func_map = {}

-- Update new function with upvalues of old function. Keep the old upvalues data.
-- Parameter name and deep are only for log.
local function update_func(new_func, old_func, name, deep)
    assert("function" == type(new_func))
    assert("function" == type(old_func))

    M.log_debug(string.format("%sUpdate function %s(): new(%s), old(%s)",
        deep, name, tostring(new_func), tostring(old_func)))
    deep = deep .. "  "

    if old_func == new_func then return end
    if updated_func_map[old_func] then return end
    updated_func_map[old_func] = new_func

    -- Get upvalues of old function.
    local old_upvalue_map = {}
    for i = 1, math.huge do
        local name, value = debug.getupvalue(old_func, i)
        if not name then break end
        old_upvalue_map[name] = value
    end

    local function log_dbg(name, from, to)
        M.log_debug(string.format("%ssetupvalue '%s': (%s) -> (%s)",
            deep, name, tostring(from), tostring(to)))
    end

    -- Update new upvalues with old.
    for i = 1, math.huge do
        local name, value = debug.getupvalue(new_func, i)
        if not name then break end
        local old_value = old_upvalue_map[name]
        if old_value then
            if type(old_value) ~= type(value) then
                debug.setupvalue(new_func, i, old_value)
                log_dbg(name, value, old_value)
            elseif type(old_value) == "function" then
                update_func(value, old_value, name, deep)
            elseif type(old_value) == "table" then
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

    M.log_debug(string.format("%sUpdate table '%s': new(%s), old(%s)",
        deep, name, tostring(new_table), tostring(old_table)))
    deep = deep .. "  "
    if new_table == old_table then return end  -- same address

    local signature = tostring(old_table)..tostring(new_table)
    if visited_sig[signature] then return end
    visited_sig[signature] = true

    -- Compare 2 tables, and update old table.
    for name, value in pairs(new_table) do
        local old_value = old_table[name]
        if type(value) ~= type(old_value) then
            old_table[name] = value
            M.log_debug(string.format("%sUpdate field '%s': (%s) -> (%s)",
                deep, name, tostring(old_value), tostring(value)))
        elseif type(value) == "function" then
            update_func(value, old_value, name, deep)
            old_table[name] = value  -- Set new function with old upvalues.
        elseif type(value) == "table" then
            update_table(value, old_value, name, deep)
        end
        -- Todo: Delete keys that are old functions.
    end  -- for

    -- Update metatable.
    local old_meta = debug.getmetatable(old_table)
    local new_meta = debug.getmetatable(new_table)
    if type(old_meta) == "table" and type(new_meta) == "table" then
        update_table(new_meta, old_meta, name.."'s Meta", deep)
    end
end  -- update_table()

-- Usage: hotfix_module("mymodule.sub_module")
-- Returns package.loaded[module_name].
function M.hotfix_module(module_name)
    assert("string" == type(module_name))
    M.log_debug("Hot fix module: " .. module_name)
    local file_path = assert(package.searchpath(module_name, package.path))
    local fp = assert(io.open(file_path))
    io.input(file_path)
    local chunk = io.read("*all")
    io.close(fp)

    -- Load data to _ENV.
    local env = {package = {loaded = {}}}
    assert("table" == type(_G))
    setmetatable(env, { __index = _G })
    local _ENV = env
    local func = assert(load(chunk, module_name, "t", env))
    local ok, result = assert(pcall(func))
    if nil == result then result = true end  -- result may be false
    env.package.loaded[module_name] = result  -- like require()

    -- Update _G.
    visited_sig = {}
    update_table(env, _G, "_G", "")
    visited_sig = {}
    return _G.package.loaded[module_name]
end

-- User can set log functions. Default is no log.
-- Like: require("hotfix").log_info = function(s) mylog:info(s) end
function M.log_error(msg_str) end
function M.log_info(msg_str) end
function M.log_debug(msg_str) end

return M
