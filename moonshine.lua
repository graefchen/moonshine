-- NOTE: Lujit seems to have problems with the imports, can not find 'djot' and
-- failes on the import of "lfs"
local lfs = require "lfs"
local djot = require "djot"
local etlua = require "etlua"
local utils = require "moonshine.utils"

local moonshine = {}

-- Return a single array/table of all files that can be found in a directory
-- while ignoring specific directorys.
-- For this function it should be ".", ".." and some more that are
-- specified as an argument.

-- This function returns an array of tables with the fields "__children", "name"
-- and "type". Notable is that the "__children" field, which is also a table of
-- the same fields, exist only when the "type" equals "dir", but it can be empty.
-- What is returned is essentially a file tree.
function get_files(dir, exclude)
    local tree = {}

    for file in lfs.dir(dir) do
        -- we do not care about the "." and ".." folders
        -- that are in every(?) OS file directory.
        if file ~= "." and file ~= ".." then
            -- NOTE: We need to concatenate the file with the current
            -- directory else the lfs function in "utils.is_dir" looks for
            -- the file in the *current* directory.
            if utils.is_dir(dir .. file) then
                -- NOTE: We need to add an "/" to the end of the directory
                -- else it would not use the correct path.
                -- For example: "example/1/" instead of "example/1".
                local list = get_files(dir .. file .. "/", exclude)
                table.insert(tree, {
                    type = "dir",
                    name = file,
                    __children = list
                })
            else
                table.insert(tree, {
                    type = "file",
                    name = file
                })
            end
        end
    end

    return tree
end

--- getting the templete
local function get_template(file)
    local f = io.open(file, "r")
    local template = f:read("*a")
    f:close()
    return etlua.compile(template)
end

--- getting djot
local function get_djot(file)
    local f = io.open(file, "r")
    local input = f:read("*a")
    f:close()
    local doc = djot.parse(input)
    return djot.render_html(doc)
end

-- building the site
-- accept a table with the configuration
function moonshine.build(config)
    if config == nil then
        return error("No config given")
    end

    if config.src ~= nil then
        -- creating the destinatin directory
        -- might do that in another function ... and maybe at the end
        -- if config.dst ~= nil then
        --     lfs.mkdir(config.dst)
        -- else
        --     lfs.mkdir("_site")
        -- end
        local file_table = {}

        local file_list = get_files(config.src, config.dst)

        for _, file in pairs(file_list) do
            local fname = utils.get_filename(file)
            if file_table[fname] == nil then
                file_table[fname] = {
                    content = "",
                    template = ""
                }
            end

            if utils.get_extension(file) == "djot" then
                file_table[fname]["content"] = get_djot(file)
            elseif utils.get_extension(file) == "etlua" then
                file_table[fname]["template"] = get_template(file)
            end
        end

        -- TODO: Refactor
        -- build the website
        -- NOTE: Be careful about the destination and how to
        -- change the source to *correctly* change the
        -- NOTE: It also is important to create the directory's
        -- For that we need to crawl along the directory and create new one
        -- before creating a new file
        -- TODO: Refactor and maybe think about using a file tree for this.
        -- Major refactoring would be probably needed, but could possible be
        -- done because the system is currently fairly good.
        for k, v in pairs(file_table) do
            -- when the file isn't index creates a new directory
            if k ~= "index" then
                print(k, v.template({
                    content = v.content
                }))
            end
        end
    else
        print("No source given");
    end
end

local config = {
    src = "example/blog/"
    -- dst = "example/_site"
}
moonshine.build(config)

return moonshine
