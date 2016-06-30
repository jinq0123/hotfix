--[[
Lua 5.2/5.3 hotfix. Hot update functions and keep old data.
Author: Jin Qing ( http://blog.csdn.net/jq0123 )
--]]

local M = {}

local update_table
local update_func

-- Update new function evn_f with upvalues of old function g_f.
-- Todo: name is not used? Add debug log...
local function update_func(env_f, g_f, name, deep)
    assert('function' == type(env_f))
    assert('function' == type(g_f))
    -- Todo: Check protection?
    log_debug(deep .. "Update function " .. name)

    -- Get upvalues of old function.
    local old_upvalue_map = {}
    for i = 1, math.huge do
        local name, value = debug.getupvalue(g_f, i)
        if not name then break end
        old_upvalue_map[name] = value
    end

    -- Update new upvalues with old.
    for i = 1, math.huge do
        local name, value = debug.getupvalue(env_f, i)
        if not name then break end
        local old_value = old_upvalue_map[name]
        if old_value then
            if type(old_value) ~= type(value) then
                debug.setupvalue(env_f, i, old_value)
            elseif type(old_value) == 'function' then
                update_func(value, old_value, name, deep..'  '..name..'  ')
            elseif type(old_value) == 'table' then
                update_table(value, old_value, name, deep..'  '..name..'  ')
                debug.setupvalue(env_f, i, old_value)
            else
                debug.setupvalue(env_f, i, old_value)
            end
        end
    end
end  -- update_func()

-- Todo: only need table?
local protection = {
    setmetatable = true,
    pairs = true,
    ipairs = true,
    next = true,
    require = true,
    _ENV = true,
}

-- Visited signatures to prevent dead loop.
local visited_sig = {}

-- Compare 2 tables and update new table env_t.
function update_table(env_t, g_t, name, deep)
    assert('table' == type(env_t))
    assert('table' == type(g_t))

    if protection[env_t] or protection[g_t] then return end
    if env_t == g_t then return end  -- same address

    local signature = tostring(g_t)..tostring(env_t)
    if visited_sig[signature] then return end
    visited_sig[signature] = true
    log_debug(deep .. "Update table " .. name)

    -- Compare env_t and g_t, and update g_t.
    -- Same as _ENV and _G in hotfix()?
    for name, value in pairs(env_t) do
        local old_value = g_t[name]
        if type(value) == type(old_value) then
            if type(value) == 'function' then
                update_func(value, old_value, name, deep..'  '..name..'  ')
                g_t[name] = value
            elseif type(value) == 'table' then
                update_table(value, old_value, name, deep..'  '..name..'  ')
            end
        else
            g_t[name] = value
        end
    end  -- for

    -- Update metatable.
    local old_meta = debug.getmetatable(g_t)
    local new_meta = debug.getmetatable(env_t)
    if type(old_meta) == 'table' and type(new_meta) == 'table' then
        update_table(new_meta, old_meta, name..'s Meta', deep..'  '..name..'s Meta'..'  ' )
    end
end  -- update_table()

function M.hotfix(chunk, check_name)
    -- Load data to _ENV.
    local env = {}
    setmetatable(env, { __index = _G })
    local _ENV = env
    local f, err = load(chunk, check_name, 't', env)
    assert(f, err)
    assert(pcall(f))

    -- Compare _ENV and _G, and update _G.
    for name, value in pairs(env) do
        local g_value = _G[name]
        if type(g_value) ~= type(value) then
            log_debug(string.format("Update %s from %s to %s.",
                name, type(g_value), type(value)))
            _G[name] = value
        elseif type(value) == 'function' then
            update_func(value, g_value, name, '')
            _G[name] = value
        elseif type(value) == 'table' then
            update_table(value, g_value, name, '')
        end
    end  -- for
end  -- hotfix()

function M.hotfix_file(file_path)
    local fp = io.open(file_path)
    if not fp then return end

    io.input(file_path)
    local file_str = io.read('*all')
    io.close(fp)

    if not file_str then return end
    M.hotfix(file_str, file_path)
end  -- hotfix_file()

-- User can set log functions. Default is no log.
-- Like: require("hotfix").log_info = function(s) mylog:info(s) end
function M.log_error(msg_str) end
function M.log_info(msg_str) end
function M.log_debug(msg_str) end

return M
