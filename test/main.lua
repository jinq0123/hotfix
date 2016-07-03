package.path = "../?.lua;" .. package.path

local M = {}

local hotfix = require("hotfix")
local test  -- = require("test")
local tmp = {}  -- to store temp data

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

local function run_testX(old, prepare, new, check)
    log("Skip.")
end

local function run_test(old, prepare, new, check)
    assert("string" == type(old))
    assert(not prepare or "function" == type(prepare))
    assert("string" == type(new))
    assert(not check or "function" == type(check))

    -- Require old code and prepare.
    write_test_lua(old);
    package.loaded["test"] = nil
    test = require("test")
    if prepare then prepare() end

    -- Hot fix and check.
    write_test_lua(new)
    test = hotfix.hotfix_module("test")
    if check then check() end
end  -- run_test()

function M.run()

hotfix.log_error = log
hotfix.log_info = log
hotfix.log_debug = log

log("--------------------")

log("Test changing global function...")
run_test([[
        local a = "old"
        function g_get_a()
            return a
        end
    ]], nil, [[
        local a = "new"
        function g_get_a()
            return a
        end
    ]],
    function()
        -- Global function is reset directly.
        assert("new" == g_get_a())
        g_get_a = nil
    end)

log("Test keeping upvalue data...")
run_test([[
        local a = "old"
        return function() return a end
    ]], nil, [[
        local a = "new"
        return function() return a .. "_x" end
    ]],
    function()
        -- Old upvalue is kept.
        assert("old_x" == test())
    end)

log("Test adding functions...")
run_test([[
        local M = {}
        return M
    ]], nil, [[
        local M = {}
        function g_foo() return 123 end
        function M.foo() return 1234 end
        return M
    ]],
    function()
        assert(123 == g_foo())
        assert(1234 == test.foo())
        g_foo = nil
    end)

log("Hot fix function module...")  -- Module returns a function.
run_test(
    "return function() return 12345 end",
    function() tmp.f = test end,
    "return function() return 56789 end",
    function()
        assert(56789 == test())
        assert(56789 == tmp.f())
    end)

log("Test upvalue self-reference...")
local code = [[
        local fun_a, fun_b
        function fun_a() return fun_b() end
        function fun_b() return fun_a() end
        return fun_b
]]
run_test(code, nil, code, nil)  -- no dead loop

log("Test function table...")
run_test([[
        local M = {}
        function M.foo() return 12345 end
        return M
    ]],
    function() tmp.foo = test.foo end,
    [[
        local M = {}
        function M.foo() return 67890 end
        return M
    ]],
    function()
        assert(67890 == test.foo())
        assert(67890 == tmp.foo())
    end)

log("New upvalue which is a function set global...")
run_test([[
        local M = {}
        function M.foo() return 12345 end
        return M
    ]],
    function() assert(nil == global_test) end,
    [[
        local M = {}
        local function set_global() global_test = 11111 end
        function M.foo()
            set_global()
        end
        return M
    ]],
    function()
        assert(nil == test.foo())
        -- Upvalue _ENV of set_global() should replaced from env to real _ENV.
        assert(11111 == global_test)
        global_test = nil
    end)

log("Test OK!")
print("Test OK!")

end  -- run()

return M

