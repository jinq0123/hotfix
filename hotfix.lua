--[[
Lua 5.2/5.3 hotfix. Hot update functions and keep old data.
Author: Jin Qing ( http://blog.csdn.net/jq0123 )
--]]

local M = {}

local update_table
local update_func

-- Visited signatures to prevent dead loop.
local visited_sig = {}

-- Todo: only need table?
local protection = {
    setmetatable = true,
    pairs = true,
    ipairs = true,
    next = true,
    require = true,
    _ENV = true,
}

-- Update new function with upvalues of old function. Keep the old upvalues data.
-- Parameter name and deep are only for log.
local function update_func(new_func, old_func, name, deep)
    assert("function" == type(new_func))
    assert("function" == type(old_func))
    -- Todo: Check protection
    -- Todo: Check visited_sig
    M.log_debug(string.format("%sUpdate function upvalues: %s, new(%s), old(%s)",
        deep, name, tostring(new_func), tostring(old_func)))
    deep = deep .. "  "

    -- Get upvalues of old function.
    local old_upvalue_map = {}
    for i = 1, math.huge do
        local name, value = debug.getupvalue(old_func, i)
        if not name then break end
        old_upvalue_map[name] = value
    end

    M.log_debug(deep .. "Old upvalues:")
    for name in pairs(old_upvalue_map) do M.log_debug(deep .. "  " .. name) end

    -- Update new upvalues with old.
    for i = 1, math.huge do
        local name, value = debug.getupvalue(new_func, i)
        if not name then break end
        local old_value = old_upvalue_map[name]
        if old_value then
            if type(old_value) ~= type(value) then
                debug.setupvalue(new_func, i, old_value)
            elseif type(old_value) == "function" then
                update_func(value, old_value, name, deep)
            elseif type(old_value) == "table" then
                update_table(value, old_value, name, deep)
                debug.setupvalue(new_func, i, old_value)
            else
                debug.setupvalue(new_func, i, old_value)
            end
        else
            M.log_debug(string.format("%sIgnore name %s", deep, name))
        end
    end
end  -- update_func()

-- Compare 2 tables and update old table. Keep the old data.
function update_table(new_table, old_table, name, deep)
    assert("table" == type(new_table))
    assert("table" == type(old_table))

    M.log_debug(string.format("%sUpdate table: %s, new(%s), old(%s)",
        deep, name, tostring(new_table), tostring(old_table)))
    deep = deep .. "  "
    if protection[new_table] or protection[old_table] then return end
    if new_table == old_table then return end  -- same address

    local signature = tostring(old_table)..tostring(new_table)
    if visited_sig[signature] then return end
    visited_sig[signature] = true

    M.log_debug(deep .. "New table:")
    for k, v in pairs(new_table) do M.log_debug(string.format("%s  %s(%s)", deep, k, tostring(v))) end

    -- Compare 2 tables, and update old table.
    -- Same as _ENV and _G in hotfix()?
    for name, value in pairs(new_table) do
        local old_value = old_table[name]
        if type(value) ~= type(old_value) then
            old_table[name] = value
        elseif type(value) == "function" then
            update_func(value, old_value, name, deep)
            old_table[name] = value  -- Set new function with old upvalues.
        elseif type(value) == "table" then
            update_table(value, old_value, name, deep)
        end
    end  -- for

    -- Update metatable.
    local old_meta = debug.getmetatable(old_table)
    local new_meta = debug.getmetatable(new_table)
    if type(old_meta) == "table" and type(new_meta) == "table" then
        update_table(new_meta, old_meta, name.."'s Meta", deep)
    end
end  -- update_table()

function M.hotfix(chunk, chunk_name)
    assert("table" == type(_G))

    -- Load data to _ENV.
    local env = {}
    setmetatable(env, { __index = _G })
    local _ENV = env
    local f, err = load(chunk, chunk_name, "t", env)
    assert(f, err)
    assert(pcall(f))

    -- Update _G.
    visited_sig = {}
    update_table(env, _G, chunk_name, "")
    visited_sig = {}
end  -- hotfix()

function M.hotfix_file(file_path)
    local fp = io.open(file_path)
    if not fp then
        M.log_debug("Can not open " .. file_path)
        return
    end

    io.input(file_path)
    local file_str = io.read("*all")
    io.close(fp)

    if not file_str then
        M.log_debug("Can not read " .. file_path)
        return
    end
    M.hotfix(file_str, file_path)
end  -- hotfix_file()

-- Usage: hotfix_module("mymodule.sub_module")
function M.hotfix_module(module_name)
    assert("string" == type(module_name))
    M.log_debug("Hot fix module " .. module_name)
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
end

-- User can set log functions. Default is no log.
-- Like: require("hotfix").log_info = function(s) mylog:info(s) end
function M.log_error(msg_str) end
function M.log_info(msg_str) end
function M.log_debug(msg_str) end

return M
