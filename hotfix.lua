--[[
Lua 5.2/5.3 hotfix. Hot update functions and keep old data.
Author: Jin Qing ( http://blog.csdn.net/jq0123 )
--]]

local M = {}

function M.hotfix(chunk, check_name)
end  -- hotfix()

function M.hotfix_file(file_path)
    local fp = io.open(file_path)
    if not fp then return end

    io.input(file_path)
    local file_str = io.read('*all')
    io.close(fp)

    if not file_str then return end
    hotfix(file_str, file_path)
end

return M
