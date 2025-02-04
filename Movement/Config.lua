--[[ Imports ]]
local Config = {}

local Common = require("Movement.Common")
local G = require("Movement.Globals")
local json = require("Movement.Json")

local Log = Common.Log
local Notify = Common.Notify
Log.Level = 0

local Lua__fullPath = GetScriptName()
local Lua__fileName = Lua__fullPath:match("\\([^\\]-)$"):gsub("%.lua$", "")
local folder_name = string.format([[Lua %s]], Lua__fileName)

filesystem.CreateDirectory(folder_name)
local filePath = folder_name .. "/config.json"

-- Default configuration table
local defaultConfig = {
    Menu = G.Default_Menu,
    -- Add other default configurations here
}

-- Helper function: copyMatchingKeys
local function copyMatchingKeys(src, filter, copies)
    copies = copies or {}
    if type(src) ~= "table" then
        return src
    end
    if copies[src] then
        return copies[src]
    end
    local result = {}
    copies[src] = result
    for key, fval in pairs(filter) do
        local sval = src[key]
        if type(fval) == "table" then
            if type(sval) == "table" then
                result[key] = copyMatchingKeys(sval, fval, copies)
            else
                result[key] = sval
            end
        else
            if type(sval) ~= "function" then
                result[key] = sval
            end
        end
    end
    return result
end

-- Utility: recursively check that every key in 'expected' exists in 'loaded'.
local function deepCheck(expected, loaded)
    for key, value in pairs(expected) do
        if loaded[key] == nil then
            return false
        end
        if type(value) == "table" then
            if type(loaded[key]) ~= "table" then
                return false
            end
            if not deepCheck(value, loaded[key]) then
                return false
            end
        end
    end
    return true
end

-- Save the current configuration to file (in JSON format)
function Config:Save()
    local file = io.open(filePath, "w")
    if file then
        -- Create a deep copy of the configuration data using defaultConfig as a filter.
        local dataToSave = copyMatchingKeys(G, defaultConfig)
        local content = json.encode(dataToSave)
        file:write(content)
        file:close()
        printc(100, 183, 0, 255, "Success Saving Config: " .. filePath)
    else
        printc(255, 0, 0, 255, "Failed to open file for writing: " .. filePath)
    end
end

-- Load configuration from file.
function Config:Load()
    local file = io.open(filePath, "r")
    if file then
        local content = file:read("*a")
        file:close()
        local loadedConfig, decodeErr = json.decode(content)
        if loadedConfig and deepCheck(defaultConfig, loadedConfig) and not input.IsButtonDown(KEY_LSHIFT) then
            -- Overwrite our configuration values with those from the file.
            for key, value in pairs(loadedConfig) do
                G[key] = value
            end
            printc(100, 183, 0, 255, "Success Loading Config: " .. filePath)
            Notify.Simple("Success! Loaded Config from", filePath, 5)
        else
            local warnMsg = decodeErr or "Config is outdated or invalid. Creating a new config."
            printc(255, 0, 0, 255, warnMsg)
            Notify.Simple("Warning", warnMsg, 5)
            self:Save()
        end
    else
        local warnMsg = "Config file not found. Creating a new config."
        printc(255, 0, 0, 255, warnMsg)
        Notify.Simple("Warning", warnMsg, 5)
        self:Save()
    end
end

local function OnUnload()
    Config:Save()
end

callbacks.Unregister("Unload", "Movement_Unload")
callbacks.Register("Unload", "Movement_Unload", OnUnload)

-- Auto-load the configuration when the module is required.
Config:Load()

return Config