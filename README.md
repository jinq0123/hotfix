# hotfix
Lua 5.2/5.3 hotfix. Hot update functions and keep old data.

What does hotfix do
---------------------
If we has a test.lua
```lua
local M = {}

M.count = 0

function M.func()
    M.count = M.count + 1
    return "v1"
end

return M
```

Require test and call func(), then count will be 1.
```
> test = require("test")                              
> test.func()                                         
v1                                                    
> test.count                                          
1                                                     
```

Change "v1" to "v2" in test.lua, then hotfix module test and call func() again.
The result shows that func() has been updated, but the count is kept.
```
> hotfix = require("hotfix.hotfix")                          
> hotfix.hotfix_module("test")                        
table: 0000000002752060                               
> test.func()                                         
v2                                                    
> test.count                                          
2                                                     
```

Install
-------
Using [LuaRocks](https://luarocks.org): 
```
luarocks install --server=http://luarocks.org/dev hotfix
```

Or manually copy `lua/hotfix` directory into your Lua module path.

Usage
-----
```lua
local hotfix = require("hotfix.hotfix")
hotfix.hotfix_module("mymodule.sub_module")
```

[`helper/hotfix_helper.lua`](helper/hotfix_helper.lua)
 is an example to hotfix modified modules using `lfs`.
 Please see [helper/README.md](helper/README.md).

`hotfix_module(module_name)`
---------------------------
`hotfix_module()` uses `package.searchpath(module_name, package.path)`
 to search the path of module.
The module is reloaded and the returned value is updated to `package.loaded[module_name]`.
If the returned value is `nil`, then `package.loaded[module_name]` is assigned to `true`.
`hotfix_module()` returns the final value of `package.loaded[module_name]`.

`hotfix_module()` will skip unloaded module to avoid unexpected loading,
and also to work around the issue of
 ["Three dots module name will be nil"](https://github.com/jinq0123/hotfix#three-dots-module-name-will-be-nil).

Functons are updated to new ones but old upvalues are kept.
Old tables are kept and new fields are inserted.
All references to old functions are replaced to new ones.

The module may change any global variables if it wants to.
See ["Why not protect the global variables" below](#why-not-protect-the-global-variables).

Local variable which is not referenced by `_G` is not updated.
```lua
-- test.lua: return { function func() return "old" end }
local test = require("test")  -- referenced by _G.package.loaded["test"]
local func = test.func        -- is not upvalue nor is referenced by _G
-- test.lua: return { function func() return "new" end }
require("hotfix.hotfix").hotfix_module("test")
test.func()  -- "new"  
func()       -- "old"
```

Why not protect the global variables
-------------------------------------
We can protect the global variables on loading in some ways, but there are other problems.

* [1] uses a read only `ENV` to load.
```lua
    local env = {}
    setmetatable(env, { __index = _G })
    load(chunk, check_name, 't', env)
```

But it can not stop indirect write.
Global variables may be changed.
In the following example, `t` is OK but `math.sin` is changed.

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

* [2] uses a fake `ENV` to load and ignores all operations.
In this case, we can not init new local variables.
```lua
local M = {}
+ local log = require("log")  -- Can not require!
function M.foo()
+    log.info("test")
end
return M
```

Another problem is the new function's `_ENV` is not the real `ENV`.
Following test will fail because `set_global()` has a protected `ENV`.
```lua
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
        assert(11111 == global_test)  -- FAIL!
        global_test = nil
    end)
```

How to run test
------------------
Run `main.lua` in test dir.
`main.lua` will write a `test.lua` file and hotfix it.
`main.lua` will write log to `log.txt`.
<pre>
D:\Jinq\Git\hotfix\test>..\..\..\tools\lua-5.3.2_Win64_bin\lua53
Lua 5.3.2  Copyright (C) 1994-2015 Lua.org, PUC-Rio
> require("main").run()
main.lua:80: assertion failed!
</pre>

Unexpected update
-------------------
`log` function is changed from `print` to an empty function.
The hotfix will replace all `print` to an empty function which is totally unexpected.
```lua
local M = {}
local log = print
function M.foo() log("Old") end
return M
```
```lua
local M = {}
local log = function() end
function M.foo() log("Old") end
return M
```
`hotfix.add_protect{print}` can protect `print` function from being replaced.
But it also means that `log` can not be updated.

Known issue
--------------
### Can not load utf8 with BOM.
```
hotfix.lua:210: file.lua:1: unexpected symbol near '<\239>'
```
### Three dots module name will be `nil`.
```lua
--- test.lua.
-- @module test
local module_name = ...
print(module_name)
```
`require("test")` will print "test", but hotfix which uses `load()` will print "nil".

Reference
---------
* [1] hotfix by tickbh
  <br>https://github.com/tickbh/td_rlua/blob/11523931b0dd271ad4c5e9c532a9d3bae252a264/td_rlua/src/hotfix.rs
  <br>http://www.cnblogs.com/tickbh/articles/5459120.html (In Chinese)
  <br>Lua 5.2/5.3.
  
  Can only update global functions.
  
```lua
local M = {}
+ function M.foo() end  -- Can not add M.foo().
return M
```  
  
* [2] lua_hotupdate
  <br>https://github.com/asqbtcupid/lua_hotupdate
  <br>Lua 5.1.

  Using a fake `ENV`, the module's init statements result in noop.
