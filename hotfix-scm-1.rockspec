package = "hotfix"
version = "scm-1"
source = {
   url = "*** please add URL for source tarball, zip or repository here ***"
}
description = {
   detailed = [[
Usage
-----
```lua
local hotfix = require("hotfix")
hotfix.hotfix_module("mymodule.sub_module")
```]],
   homepage = "*** please enter a project homepage ***",
   license = "*** please specify a license ***"
}
dependencies = {}
build = {
   type = "builtin",
   modules = {
      functions_replacer = "functions_replacer.lua",
      ["helper.hotfix_helper"] = "helper/hotfix_helper.lua",
      ["helper.hotfix_module_names"] = "helper/hotfix_module_names.lua",
      ["helper.main"] = "helper/main.lua",
      ["helper.test"] = "helper/test.lua",
      hotfix = "hotfix.lua",
      module_updater = "module_updater.lua",
      ["test.main"] = "test/main.lua",
      ["test.test"] = "test/test.lua"
   }
}
