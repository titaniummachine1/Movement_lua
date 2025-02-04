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

-- Ensure the folder exists
local _, fullPath = filesystem.CreateDirectory(folder_name) --succes shows if folder was created not if it exists or action suceeded

local configFilePath = fullPath .. "/config.json"
local recordingsFilePath = fullPath .. "/recordings.json"

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

-- Save data to file (in JSON format)
local function SaveToFile(filePath, data, successMessage, errorMessage)
    local file = io.open(filePath, "w")
    if file then
        local content = json.encode(data)
        file:write(content)
        file:close()
        printc(100, 183, 0, 255, successMessage .. ": " .. filePath)
        Notify.Simple("Success! " .. successMessage, filePath, 5)
    else
        printc(255, 0, 0, 255, errorMessage .. ": " .. filePath)
        Notify.Simple("Error", errorMessage .. ": " .. filePath, 5)
    end
end

-- Load data from file
local function LoadFromFile(filePath, defaultData, successMessage, errorMessage)
    local file = io.open(filePath, "r")
    if file then
        local content = file:read("*a")
        file:close()
        local loadedData, decodeErr = json.decode(content)
        if loadedData and deepCheck(defaultData, loadedData) and not input.IsButtonDown(KEY_LSHIFT) then
            for key, value in pairs(loadedData) do
                G[key] = value
            end
            printc(100, 183, 0, 255, successMessage .. ": " .. filePath)
            Notify.Simple("Success! " .. successMessage, filePath, 5)
        else
            local warnMsg = decodeErr or "Data is outdated or invalid. Creating a new file."
            printc(255, 0, 0, 255, warnMsg)
            Notify.Simple("Warning", warnMsg, 5)
            SaveToFile(filePath, defaultData, successMessage, errorMessage)
        end
    else
        local warnMsg = "File not found. Creating a new file."
        printc(255, 0, 0, 255, warnMsg)
        Notify.Simple("Warning", warnMsg, 5)
        SaveToFile(filePath, defaultData, successMessage, errorMessage)
    end
end

-- Save the current configuration to file
function Config:Save(fileName)
    local filePath = fullPath .. "/" .. fileName
    SaveToFile(filePath, copyMatchingKeys(G, defaultConfig), "Saved to", "Failed to open file for writing")
end

-- Load configuration from file
function Config:Load(fileName)
    local filePath = fullPath .. "/" .. fileName
    LoadFromFile(filePath, defaultConfig, "Loaded from", "Failed to load")
end

local function OnUnload()
    Config:Save("config.json")
    Config:Save("recordings.json")
end

callbacks.Unregister("Unload", "Movement_Unload")
callbacks.Register("Unload", "Movement_Unload", OnUnload)

-- Auto-load the configuration and recordings when the module is required.
Config:Load("config.json")
Config:Load("recordings.json")

return Config