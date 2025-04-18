-- NOTE: Lujit seems to have problems with the imports, can not find 'djot' and
-- failes on the import of "lfs"
local lfs = require "lfs"
local djot = require "djot"
local etlua = require "etlua"
local utils = require "moonshine.utils"
local pprint = require "moonshine.pprint"

local moonshine = {}

local function get_template(file)
    local f = io.open(file, "r")
    local template = f:read("*a")
    f:close()
    return etlua.compile(template)
end

local function get_djot(file)
    local f = io.open(file, "r")
    local input = f:read("*a")
    f:close()
    local doc = djot.parse(input)
    return djot.render_html(doc)
end

function get_sites(tree)
    local sites = {}
    for _, site in pairs(tree) do
        if site.type == "dir" then
            local list = get_sites(site)
            table.insert(sites, {
                type = site.type,
                name = site.name,
                __children = list
            })
        else
            table.insert(sites, {
                type = site.type,
                name = site.name
            })
        end
    end
    return sites
end

function get_content(file)
    local extension = utils.get_extension(file)
    if extension == "djot" then
        return get_djot(file)
    elseif extension == "etlua" then
        return get_template(file)
    else
        return ""
    end
end

function get_files(dir, exclude)
    local tree = {}

    for file in lfs.dir(dir) do
        if file ~= "." and file ~= ".." then
            if utils.is_dir(dir .. file) then
                local list = get_files(dir .. file .. "/", exclude)
                table.insert(tree, {
                    type = "dir",
                    name = file,
                    path = dir .. file .. "/",
                    __children = list
                })
            else
                local content = get_content(dir .. file)
                table.insert(tree, {
                    type = "file",
                    name = file,
                    path = dir .. file,
                    content = content
                })
            end
        end
    end

    return tree
end

function moonshine.build(config)
    if config == nil then
        return error("No config given")
    end

    if config.src ~= nil then
        local file_table = {}

        local file_list = get_files(config.src, config.dst)

        pprint(file_list)
    else
        print("No source given");
    end
end

local config = {
    src = "example/",
    dst = "example/_site"
}
moonshine.build(config)

return moonshine
