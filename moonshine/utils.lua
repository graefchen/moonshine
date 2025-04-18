local lfs = require "lfs"

local utils = {}

--- checks if an file is an directory
function utils.is_dir(path)
    -- lfs.attributes will error on a filename ending in '/'
    return path:sub(-1) == "/" or lfs.attributes(path, "mode") == "directory"
end

function utils.get_dir(filename)
    return filename:match("^(.+)/.+$")
end

--- returns the extension of a filename
function utils.get_extension(filename)
    return filename:match(".+%.(%w+)$") or "none"
end

--- returns the filename of an file wxithout the extension
--- exception are files that start with "."
function utils.get_filename(filename)
    return filename:match("([%. %w]+)%.%w+$")
end

function utils.split(input, seperator)
    if seperator == nil then
        seperator = "%s"
    end
    local t = {}
    for str in string.gmatch(input, "([^" .. seperator .. "]+)") do
        table.insert(t, str)
    end
    return t
end

return utils
