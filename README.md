# hotfix
Lua 5.2/5.3 hotfix. Hot update functions and keep old data.

Reference:
* hotfix by tickbh

  http://www.cnblogs.com/tickbh/articles/5459120.html (In Chinese)
  
  Can only update global functions.
  
```
local M = {}
+ function M.foo() end  -- Can not add M.foo().
return M
```  
  
* lua_hotupdate

  https://github.com/asqbtcupid/lua_hotupdate
  
  For Lua 5.1.
  
  Can not init new local variables.
  
```
local M = {}
+ local log = require("log")  -- Can not require!
function M.foo()
+    log.info("test")
end
return M
```  
  
