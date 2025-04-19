package = "moonshine"
version = "dev-1"

source = {
   url = "https://github.com/graefchen/moonshine/moonshine.lua"
}

description = {
   summary = "A Lua static site builder/library that uses Djot.",
   detailed = [[
      A Lua static site library that uses the Djot markup language and
      the etlua template engine to generate static sites.
   ]],
   maintainer = "graefchen",
   homepage = "https://github.com/graefchen/moonshine",
   license = "MIT"
}

build = {
   modules = {
      ["moonshine"] = "moonshine.lua",
   },
   type = "builtin",
}

dependencies = {
   "lua >= 5.1",
   "djot >= 0.2.1-1",
   "luafilesystem >= 1.8.0-1",
   "etlua >= 1.3.0-1",
}