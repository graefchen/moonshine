-- █▀▄▀█ █▀█ █▀█ █▄░█ █▀ █░█ █ █▄░█ █▀▀
-- █░▀░█ █▄█ █▄█ █░▀█ ▄█ █▀█ █ █░▀█ ██▄.lua
--
-- A Lua static site library that uses the Djot markup language and
-- the etlua template engine to generate static sites.
--
-- NOTE: (2026-06-29) Vendor them? - graef
--       (2026-07-02) Nah, to much work - graef
lfs = require "lfs"
djot = require "djot"
etlua = require "etlua"

-- utils
utils = {}

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
    t = {}
    for str in string.gmatch(input, "([^" .. seperator .. "]+)") do
        table.insert(t, str)
    end
    return t
end

-- getting the last object out of the table `t`
function utils.last_obj(t)
    if t == nil then
        return nil
    end
    return t[#t]
end

-- getting the size of a table `t`
function utils.size(t)
    count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

-- misc

function get_file(file)
    f = io.open(file, "r")
    document = f:read("*a")
    f:close()
    return document
end

function get_template(file)
    return etlua.compile(get_file(file))
end

function get_djot(file)
    return djot.render_html(djot.parse(get_file(file)))
end

function get_files(path, exclude)
    list = {}
    for file in lfs.dir(path) do
        if file ~= "." and file ~= ".." then
            filepath = path .. file
            -- skip the loop when filepath is where the site is build
            if filepath == exclude then
                goto continue
            end
            if utils.is_dir(filepath) then
                for _, value in pairs(get_files(filepath .. "/", exclude)) do
                    table.insert(list, value)
                end
            else
                extension = utils.get_extension(file)
                if extension == "djot" or extension == "etlua" then
                    table.insert(list, filepath)
                end
            end
            -- why? ohh.... see goto above
            ::continue::
        end
    end
    return list
end

function get_contents(list, basepath)
    t = {}
    for _, value in pairs(list) do
        extension = utils.get_extension(value)
        name = utils.get_filename(value)
        if t[name] == nil then
            t[name] = {}
        end
        if extension == "djot" then
            t[name]["content"] = get_djot(value)
        elseif extension == "etlua" then
            t[name]["template"] = get_template(value)
        end
    end
    -- creating a table that takes in as the key a directory name
    -- and as its value the etlua template function
    dir_template = {}
    -- first looping throught the first table and filling the table
    for key, _ in pairs(t) do
        if key:match("index") then
            -- adding the template to the `dir_template` table
            if t[key]["template"] ~= nil then
                dir_template[utils.get_dir(key)] = t[key]["template"]
            end
        end
    end
    -- second loop throgh table to add the missing etlua template functions
    for key, _ in pairs(t) do
        if t[key]["template"] == nil then
            str = ""
            -- checking for the template function (also overwriting it when
            -- found on an upper level in the table)
            for _, part in pairs(utils.split(key, "/")) do
                if dir_template[str] ~= nil then
                    t[key]["template"] = t[dir_template]["template"]
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
    ret = {}
    for key, value in pairs(t) do
        ret[string.sub(key, string.len(basepath) + 1)] = value
    end
    return ret
end

-- writing a file with the filename and the given value
-- we expect that "value" is a table with a template function "template"
-- and a html field "content"
function write_file(file, value)
    file = io.open(file, "w")
    content = value["content"] or ""
    html = value.template({
        content = content
    })
    file:write(html)
    file:close()
end

function create_site(list, dir)
    lfs.mkdir(dir)
    for key, value in pairs(list) do
        directory = dir
        for _, part in pairs(utils.split(utils.get_dir(key), "/")) do
            directory = directory .. part .. "/"
            lfs.mkdir(directory)
        end
        filename = utils.last_obj(utils.split(key, "/"))
        if filename == "index" then
            write_file(directory .. "index.html", value)
        else
            lfs.mkdir(directory .. filename)
            write_file(directory .. filename .. "/index.html", value)
        end
        print("🧊 " .. (filename == "index" and "index.html" or (filename .. "/index.html")))
    end
end

-- TODO: (2025-04-19) Rewrite that it is not using external commands.
-- Additionally it can be put into the `moonshine` table
-- (it would be probably be very smart to use lsf for it)
function copy_dir(from, to)
    os.execute("cp -r " .. from .. " " .. to)
end

-- moonshine
moonshine = {}

function moonshine.build(config)
    if config == nil then
        return error("No config given")
    end
    if config.src ~= nil then
        print("moonshine 🥃")
        print("Starting to generate")
        start_time = os.clock()
        files = get_files(config.src, config.dst)
        contents = get_contents(files, config.src)
        -- getting the amount of pages we build
        size = utils.size(contents)
        create_site(contents, config.dst)
        end_time = os.clock()
        print("🍨 Finished generating into \"" .. config.dst .. "\"")
        elapsed_time = string.format("%.3f", end_time - start_time)
        -- "files" is technically not correct, but whatever, it will be fine
        print("Lua took " .. elapsed_time .. " sec to generate the blog of " .. size .. " files")
    else
        return error("No config source given")
    end
end

moonshine.build({
    src = "./blog/",
    dst = "./_site/"
})

-- return moonshine
