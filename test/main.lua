package.path = "../lua/?.lua;" .. package.path

local M = {}

local hotfix = require("hotfix.hotfix")
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
        assert(11111 == global_test)
        global_test = nil
    end)

log("Test table key...")
run_test([[
        local M = {}
        M[print] = function() return "old" end
        M[M] = "old"
        return M
    ]],
    function() assert(nil == global_test) end,
    [[
        local M = {}
        M[print] = function() return "new" end
        M[M] = "new"
        return M
    ]],
    function()
        assert("new" == test[print]())
        assert("old" == test[test])
    end)

log("Test table.fuction.table.function...")
run_test([[
        local M = {}
        local t = { tf = function() end }
        function M.mf() t.t = 123 end
        return M
    ]], nil, [[
        local M = {}
        local t = { tf = function() end }
        function M.mf() t.test = 123 end
        return M
    ]], nil)

log("Test same upvalue (issue #1) ...")
run_test([[
        local M = {}
        local l = {}
        
        function M.func1()
        end
        function M.func2()
            l[10] = 10
            return l
        end

        return M
    ]],
    function() assert(test.func2()[10] == 10) end,
    [[
        local M = {}
        local l = {}
        
        function M.func1()
            l[10] = 10
            return l
        end
        function M.func2()
            l[10] = 10
            return l
        end
        
        return M
    ]],
    function()
        assert(tostring(test.func1()) == tostring(test.func2()))
    end)

log("Test upvalue (issue #3) ...")
run_test([[
        local M = {}
        local t = {}

        function M.hello() return "hello" end

        t.hello = M.hello

        function M.func()
            return t.hello()
        end

        return M
    ]],
    function() assert(test.func() == "hello") end,
    [[
        local M = {}
        local t = {}

        function M.hello() return "hello2" end

        t.hello = M.hello

        function M.func()
            return t.hello()
        end

        return M
    ]],
    function()
        assert(test.func() == "hello2")
    end)

log("Test module returns false...")
run_test([[
        local M = {}
        return false
    ]], nil,
    [[
        local M = {}
        return M
    ]],
    function()
        -- Because module is considered unloaded, and will not hotfix.
        assert(test == false)
    end)

log("Test three dots module name...")
run_test([[
        local M = {}
        M.module_name = ...
        return M
    ]],
    function() assert(test.module_name == "test") end,
    [[
        local M = {}
        M.module_name2 = ...
        return M
    ]],
    function()
        assert(test.module_name == "test")
        -- See https://github.com/jinq0123/hotfix#three-dots-module-name-will-be-nil
        -- assert(test.module_name2 == "test")
        assert(test.module_name2 == nil)
    end)

-- Todo: Test metatable update
-- Todo: Test registry update

log("Test OK!")
print("Test OK!")

end  -- run()

return M

