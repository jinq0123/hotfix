package = "hotfix"
version = "0.1-1"
source = {
   url = "git://github.com/jinq0123/hotfix",
   tag = "v0.1",
}
description = {
   summary = "Lua 5.2/5.3 hotfix. Hot update functions and keep old data.",
   homepage = "https://github.com/jinq0123/hotfix",
   license = "Apache License 2.0",

   detailed = [[
hotfix reloads the module and updates the old module, keeping the old data.

Usage:

local hotfix = require("hotfix")
hotfix.hotfix_module("mymodule.sub_module")

The module is reloaded and the returned value is updated to package.loaded[module_name].

Functons are updated to new ones but old upvalues are kept.
Old tables are kept and new fields are inserted.
All references to old functions are replaced to new ones.
]],
}

dependencies = {
   "lua >= 5.2",
}

build = {
   type = "builtin",
   modules = {
      ["hotfix.hotfix"] = "lua/hotfix/hotfix.lua",
      ["hotfix.internal.functions_replacer"] = "lua/hotfix/internal/functions_replacer.lua",
      ["hotfix.internal.module_updater"] = "lua/hotfix/internal/module_updater.lua",
   },
   copy_directories = {
      "helper",
   },
}
