# hotfix helper
Example to use hotfix.

hotfix_helper uses lfs to record file time and hotfix modified modules in check().
hotfix_helper reloads hotfix_module_names to get module names,
 which can add or remove dynamically.

How to run
-----------
Need lfs (https://github.com/keplerproject/luafilesystem)

<pre>
E:\Git\Lua\hotfix\helper>lua53pp.exe
Lua 5.3.2  Copyright (C) 1994-2015 Lua.org, PUC-Rio
> package.path = "../lua/?.lua;" .. package.path
> require("main").run()
test    1       2       3
Hot fix module test (E:\Git\Lua\hotfix\helper\test.lua)
Hot fix module: test
Update test: new(table: 00552758) old(table: 00561CC0)
  Update func: new(function: 005527A8) old(function: 00561D38)
    Update _ENV: new(table: 0054F208) old(table: 0054F208)
      Same
    setupvalue d_count: (0) -> (2)
    Update test: new(table: 00552758) old(table: 00561CC0)
      Already updated
test    1       4       6
test    2       6       9
test    3       8       12
test    4       10      15
Hot fix module test (E:\Git\Lua\hotfix\helper\test.lua)
Hot fix module: test
Update test: new(table: 0056C6D8) old(table: 00561CC0)
  Update func: new(function: 005714A8) old(function: 005527A8)
    Update _ENV: new(table: 0054F208) old(table: 0054F208)
      Same
    setupvalue d_count: (0) -> (10)
    Update test: new(table: 0056C6D8) old(table: 00561CC0)
      Already updated
test XXX        1       12      18
test XXX        2       14      21
test XXX        3       16      24
</pre>
