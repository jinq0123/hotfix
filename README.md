# hotfix
Lua 5.2/5.3 hotfix. Hot update functions and keep old data.

Reference:
* hotfix by tickbh
  <br>https://github.com/tickbh/td_rlua/blob/11523931b0dd271ad4c5e9c532a9d3bae252a264/td_rlua/src/hotfix.rs
  <br>http://www.cnblogs.com/tickbh/articles/5459120.html (In Chinese)
  <br>Lua 5.2/5.3.
  
  Can only update global functions.
  
```
local M = {}
+ function M.foo() end  -- Can not add M.foo().
return M
```  
  
* lua_hotupdate
  <br>https://github.com/asqbtcupid/lua_hotupdate
  <br>Lua 5.1.
  
  Can not init new local variables.
  
```
local M = {}
+ local log = require("log")  -- Can not require!
function M.foo()
+    log.info("test")
end
return M
```  
  
