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
function utils:last_obj(table)
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
            if path .. file == exclude then
                goto continue
            end
            if utils.is_dir(path .. file) then
                for k, v in pairs(get_files(path .. file .. "/", exclude)) do
                    table.insert(list, v)
                end
            else
                local ex = utils.get_extension(file)
                if ex == "djot" or ex == "etlua" then
                    table.insert(list, path .. file)
                end
            end
            ::continue::
        end
    end
    return list
end
local function get_contents(list, basepath)
    local t = {}
    for k, v in pairs(list) do
        local ex = utils.get_extension(v)
        local name = utils.get_filename(v)
        if t[name] == nil then
            t[name] = {}
        end
        if ex == "djot" then
            t[name]["content"] = get_djot(v)
        elseif ex == "etlua" then
            t[name]["template"] = get_template(v)
        end
    end
    local dir_template = {}
    for k, v in pairs(t) do
        if k:match("index") then
            if t[k]["template"] ~= nil then
                dir_template[utils.get_dir(k)] = t[k]["template"]
            end
        end
        if t[k]["template"] == nil then
            local bool = false
            local str = ""
            local split = utils.split(k, "/")
            for k1, v1 in pairs(split) do
                if bool then
                    goto continue
                end
                if dir_template[str] ~= nil then
                    t[k]["template"] = t[dir_template]["template"]
                    str = str .. "/" .. v1
                end
            end
            ::continue::
        end
    end
    -- last run to prune the ...
    local ret = {}
    for k, v in pairs(t) do
        ret[string.sub(k, string.len(basepath) + 1)] = v
    end
    return ret
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
    for k, v in pairs(list) do
        local str = dir
        local sp = utils.split(utils.get_dir(k), "/")
        for k1, v1 in pairs(sp) do
            str = str .. v1 .. "/"
            lfs.mkdir(str)
        end
        local filename = utils:last_obj(utils.split(k, "/"))
        if filename == "index" then
            write_file(str .. "index.html", v)
        else
            lfs.mkdir(str .. filename)
            write_file(str .. filename .. "/index.html", v)
        end
    end
end
-- TODO: Rewrite that it is not using external commands.
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
        print("Starting to generate")
        local start_time = os.time()
        local files = get_files(config.src, config.dst)
        local contents = get_contents(files, config.src)
        create_site(contents, config.dst)
        local end_time = os.time()
        print("Finished generating")
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
