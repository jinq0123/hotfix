package.path = "../?.lua;" .. package.path

local function log(msg)
    local f = assert(io.open("log.txt", "a+"))
    f:write(msg.."\n")
    assert(f:close())
end  -- log

local hotfix = require("hotfix")
hotfix.log_error = log
hotfix.log_info = log
hotfix.log_debug = log
log("--------------------")

local TEST = "test.lua"

local function write_test(s)
    local f = assert(io.open(TEST, "w"))
    f:write(s)
    assert(f:close())
end  -- write_test()

write_test("")
local test = require("test")

log("Test keeping upvalue data.")
write_test([[
local a = 1
function get_a()
    return a
end
]])
hotfix.hotfix_module("test")
assert(1 == get_a())
write_test([[
local a = 2
function get_a()
    return a
end
]])
hotfix.hotfix_module("test")
assert(1 == get_a())

log("Test adding functions.")
write_test([[
local M = {}
return M
]])
hotfix.hotfix_module("test")

write_test([[
local M = {}
function g_foo() return 123 end
function M.foo() return 1234 end
return M
]])
hotfix.hotfix_module("test")
assert(123 == g_foo())
assert(1234 == test.foo())

assert(os.remove(TEST))
