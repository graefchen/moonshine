package = "moonshine"
version = "dev-1"
source = {
   url = "https://github.com/graefchen/moonshine/moonshine.lua"
}
description = {
   summary = "A Lua static site builder/library that uses Djot."
   detailed = [[]],
   maintainer = "graefchen"
   homepage = "https://github.com/graefchen/moonshine",
   license = "MIT"
}
build = {
   modules = {
      ["moonshine"]: "moonshine.lua"
   },
   type = "builtin",
}
dependecies = {
   "lua >= 5.1",
   "djot >= 0.2.1-1"
   "lfs >= 1.8.0-1"
   "etlua >= 1.3.0-1"
}