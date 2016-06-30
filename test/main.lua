package.path = package.path .. ";../?.lua"

local hotfix = require("hotfix")
hotfix.log_error = print
hotfix.log_info = print
hotfix.log_debug = print

local TEST = "test.lua"

local function write_test(s)
    local f = assert(io.open(TEST, "w"))
    f:write(s)
    assert(f:close())
end  -- write_test()

write_test([[
local M = {}
return M
]])

local test = require("test")
hotfix.hotfix_file(TEST)

write_test([[
local M = {}
function M.foo() return 123 end
return M
]])

hotfix.hotfix_file(TEST)
assert(123 == test.foo())

assert(os.remove(TEST))
