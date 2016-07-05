local M = {}

local hotfix_helper = require("hotfix_helper")
local test = require("test")

local function sleep(sec)
  local end_time = os.time() + sec
  while os.time() < end_time do end
end  -- sleep()

function M.run()
  hotfix_helper.init()
  while true do
    test.func()
    sleep(2)
    hotfix_helper.check()
  end
end  -- run()

return M
