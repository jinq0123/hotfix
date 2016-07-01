package.path = "../?.lua;" .. package.path
local hotfix = require("hotfix")
local test  -- = require("test")

local function log(msg)
    local f = assert(io.open("log.txt", "a+"))
    f:write(msg.."\n")
    assert(f:close())
end  -- log

local function write_test_lua(s)
    local f = assert(io.open("test.lua", "w"))
    f:write(s)
    assert(f:close())
end  -- write_test_lua()

local function run_test(old, new, check)
    assert("string" == type(old))
    assert("string" == type(new))
    assert("function" == type(check))
    write_test_lua(old);
    package.loaded["test"] = nil
    test = require("test")
    write_test_lua(new)
    test = hotfix.hotfix_module("test")
    check()
end  -- run_test()

hotfix.log_error = log
hotfix.log_info = log
hotfix.log_debug = log
log("--------------------")
log("Test keeping upvalue data...")
run_test([[
        local a = 1
        function get_a()
            return a
        end
    ]],
    [[
        local a = 2
        function get_a()
            return a
        end
    ]],
    function()
        assert(1 == get_a())
    end)

log("Test adding functions...")
run_test([[
        local M = {}
        return M
    ]],
    [[
        local M = {}
        function g_foo() return 123 end
        function M.foo() return 1234 end
        return M
    ]],
    function()
        assert(123 == g_foo())
        assert(1234 == test.foo())
    end)

print("Test OK!")
