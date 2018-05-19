package = "hotfix"
version = "scm-1"
source = {
   url = "git://github.com/jinq0123/hotfix",
}
description = {
   summary = "Lua 5.2/5.3 hotfix. Hot update functions and keep old data.",

   detailed = [[
hotfix reload the module and update the old module, keeping the old data.

Usage:

local hotfix = require("hotfix")
hotfix.hotfix_module("mymodule.sub_module")

hotfix_module() uses package.searchpath(module_name, package.path)
 to search the path of module.
The module is reloaded and the returned value is updated to package.loaded[module_name].

hotfix_module() will skip unloaded module to avoid unexpected loading.

Functons are updated to new ones but old upvalues are kept.
Old tables are kept and new fields are inserted.
All references to old functions are replaced to new ones.
]],

   homepage = "https://github.com/jinq0123/hotfix",
   license = "Apache License 2.0",
}

dependencies = {
   "lua >= 5.2",
}

build = {
   type = "builtin",
   modules = {
      functions_replacer = "functions_replacer.lua",
      hotfix = "hotfix.lua",
      module_updater = "module_updater.lua",
   },
   copy_directories = {
      "helper",
   },
}
