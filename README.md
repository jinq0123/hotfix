# hotfix
Lua 5.2/5.3 hotfix. Hot update functions and keep old data.

Local variables to functions are not updated.
```
-- test.lua: return { function func() return "old" end }
local test = require("test")
local func = test.func
-- test.lua: return { function func() return "new" end }
require("hotfix").hotfix_module("test")
test.func()  -- "new"  
func()       -- "old"
```

hotfix do have side-effect. Global variables may be changed.
In the following example, t is OK but math.sin is changed.

<pre>
Lua 5.3.2  Copyright (C) 1994-2015 Lua.org, PUC-Rio
> math.sin(123)
-0.45990349068959
> do
>> local _ENV = setmetatable({}, {__index = _G})
>> t = 123
>> math.sin = print
>> end
> t
nil
> math.sin(123)
123
</pre>

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

How to run test
------------------
Run main.lua in test dir.
main.lua will write a test.lua file and hotfix it.
main.lua will write log to log.txt.
<pre>
D:\Jinq\Git\hotfix\test>..\..\..\tools\lua-5.3.2_Win64_bin\lua53
Lua 5.3.2  Copyright (C) 1994-2015 Lua.org, PUC-Rio
> dofile("main.lua")
main.lua:80: assertion failed!
</pre>
