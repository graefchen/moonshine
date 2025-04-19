local lfs = require "lfs"
local djot = require "djot"
local etlua = require "etlua"

-- utils
local utils = {}

function utils.is_dir(path)
    return path:sub(-1) == "/" or lfs.attributes(path, "mode") == "directory"
end

function utils.get_dir(filename)
    return filename:match("^(.+)/.+$")
end

function utils.get_extension(filename)
    return filename:match(".+%.(%w+)$") or "none"
end

function utils.get_filename(filename)
    return filename:match("([/%. %w]+)%.%w+$")
end

function utils.split(input, seperator)
    if seperator == nil then
        seperator = "%s"
    end
    -- NOTE: input can be nil (for whatever reason)
    if input == nil then
        return {}
    end
    local t = {}
    for str in string.gmatch(input, "([^" .. seperator .. "]+)") do
        table.insert(t, str)
    end
    return t
end

-- getting the last object out of the table
function utils:last_obj(table)
    if table == nil then
        return nil
    end
    return table[#table]
end

-- misc

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

local function get_files(path, exclude)
    local list = {}
    for file in lfs.dir(path) do
        if file ~= "." and file ~= ".." then
            local filepath = path .. file
            if filepath == exclude then
                goto continue
            end
            if utils.is_dir(filepath) then
                for _, value in pairs(get_files(filepath .. "/", exclude)) do
                    table.insert(list, value)
                end
            else
                local extension = utils.get_extension(file)
                if extension == "djot" or extension == "etlua" then
                    table.insert(list, filepath)
                end
            end
            ::continue::
        end
    end
    return list
end

local function get_contents(list, basepath)
    local table = {}
    for _, value in pairs(list) do
        local extension = utils.get_extension(value)
        local name = utils.get_filename(value)
        if table[name] == nil then
            table[name] = {}
        end
        if extension == "djot" then
            table[name]["content"] = get_djot(value)
        elseif extension == "etlua" then
            table[name]["template"] = get_template(value)
        end
    end
    -- creating a table that takes in as the key a directory name
    -- and as its value the etlua template function
    local dir_template = {}
    -- first looping throught the first table and filling the table
    for key, _ in pairs(table) do
        if key:match("index") then
            -- adding the template to the `dir_template` table
            if table[key]["template"] ~= nil then
                dir_template[utils.get_dir(key)] = table[key]["template"]
            end
        end
    end
    -- second loop throgh table to add the missing etlua template functions
    for key, _ in pairs(table) do
        if table[key]["template"] == nil then
            local str = ""
            -- checking for the template function (also overwriting it when
            -- found on an upper level in the table)
            for _, part in pairs(utils.split(key, "/")) do
                if dir_template[str] ~= nil then
                    table[key]["template"] = table[dir_template]["template"]
                    str = str .. "/" .. part
                end
            end
        end
    end
    -- Last run to prune the full path of the table to the relative path we
    -- want. For example we got the key: `example/blog/index` and the
    -- basepath: `example/blog/`, then we get as a return the key `index`
    -- This makes it easier to create the static site in the 
    -- `create_site` function, as it now just creates the `index.html` file
    -- inside its given folder instead of the `example/blog/index.html` file.
    local return_table = {}
    for key, value in pairs(table) do
        return_table[string.sub(key, string.len(basepath) + 1)] = value
    end
    return return_table
end

local function write_file(file, value)
    local file = io.open(file, "w")
    local content = value["content"] or ""
    local html = value.template({
        content = content
    })
    file:write(html)
    file:close()
end

local function create_site(list, dir)
    lfs.mkdir(dir)
    for key, value in pairs(list) do
        local directory = dir
        for _, part in pairs(utils.split(utils.get_dir(key), "/")) do
            directory = directory .. part .. "/"
            lfs.mkdir(directory)
        end
        local filename = utils:last_obj(utils.split(key, "/"))
        if filename == "index" then
            write_file(directory .. "index.html", value)
        else
            lfs.mkdir(directory .. filename)
            write_file(directory .. filename .. "/index.html", value)
        end
    end
end

-- TODO: Rewrite that it is not using external commands.
-- Additionally it can be put into the `moonshine` table
local function copy_dir(from, to)
    os.execute("cp " .. from .. " " .. to)
end

-- moonshine
local moonshine = {}

function moonshine.build(config)
    if config == nil then
        return error("No config given")
    end
    if config.src ~= nil then
        print("moonshine \u{1F943}")
        print("🧊 Starting to generate")
        local start_time = os.time()
        local files = get_files(config.src, config.dst)
        local contents = get_contents(files, config.src)
        create_site(contents, config.dst)
        local end_time = os.time()
        print("🧊 Finished generating")
        local elapsed_time = os.difftime(end_time, start_time)
        print("Lua took " .. elapsed_time .. "s to generate the blog")
    else
        return error("No config source given")
    end
end

moonshine.build({
    src = "example/blog/",
    dst = "example/_site/"
})

return moonshine
