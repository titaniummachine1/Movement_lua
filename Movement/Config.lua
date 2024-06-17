--[[ Imports ]]
local Config = {}

local Common = require("Movement.Common")
local G = require("Movement.Globals")

local Log = Common.Log
local Notify = Common.Notify
Log.Level = 0

local Lua__fullPath = GetScriptName()
local Lua__fileName = Lua__fullPath:match("\\([^\\]-)$"):gsub("%.lua$", "")
local folder_name = string.format([[Lua %s]], Lua__fileName)

function Config.GetFilePath()
    local success, fullPath = filesystem.CreateDirectory(folder_name)
    return tostring(fullPath .. "/config.cfg")
end

function Config.CreateCFG(table)
    if not table then
        table = G.Default_Menu
    end

    local filepath = Config.GetFilePath()
    local file = io.open(filepath, "w")  -- Define the file variable here
    local filePathstring = tostring(Config.GetFilePath())
    local shortFilePath = filePathstring:match(".*\\(.*\\.*)$")

    if file then
        local function serializeTable(tbl, level)
            level = level or 0
            local result = string.rep("    ", level) .. "{\n"
            for key, value in pairs(tbl) do
                result = result .. string.rep("    ", level + 1)
                if type(key) == "string" then
                    result = result .. '["' .. key .. '"] = '
                else
                    result = result .. "[" .. key .. "] = "
                end
                if type(value) == "table" then
                    result = result .. serializeTable(value, level + 1) .. ",\n"
                elseif type(value) == "string" then
                    result = result .. '"' .. value .. '",\n'
                else
                    result = result .. tostring(value) .. ",\n"
                end
            end
            result = result .. string.rep("    ", level) .. "}"
            return result
        end

        local serializedConfig = serializeTable(table)
        file:write(serializedConfig)
        file:close()

        local successMessage = shortFilePath
        printc(100, 183, 0, 255, "Succes Saving Config: Path:" .. successMessage)
        Notify.Simple("Success! Saved Config to:", successMessage, 5)
    else
        local errorMessage = "Failed to open: " .. tostring(shortFilePath)
        printc( 255, 0, 0, 255, errorMessage)
        Notify.Simple("Error", errorMessage, 5)
    end
end

-- Function to check if all expected keys exist in the loaded config
local function checkAllKeysExist(expectedMenu, loadedMenu)
    for key, value in pairs(expectedMenu) do
        -- If the key from the expected menu does not exist in the loaded menu, return false
        if loadedMenu[key] == nil then
            return false
        end

        -- If the value is a table, check the keys in the nested table
        if type(value) == "table" then
            local result = checkAllKeysExist(value, loadedMenu[key])
            if not result then
                return false
            end
        end
    end
    return true
end

function Config.LoadCFG()
    local filepath = Config.GetFilePath()
    local file = io.open(filepath, "r")
    local filePathstring = tostring(Config.GetFilePath())
    local shortFilePath = filePathstring:match(".*\\(.*\\.*)$")

    if file then
        local content = file:read("*a")
        file:close()
        local chunk, err = load("return " .. content)
        if chunk then
            local loadedMenu = chunk()
            if checkAllKeysExist(G.Default_Menu, loadedMenu) and not input.IsButtonDown(KEY_LSHIFT) then
                local successMessage = shortFilePath
                printc(100, 183, 0, 255, "Succes Loading Config: Path:" .. successMessage)
                Notify.Simple("Success! Loaded Config from", successMessage, 5)

                G.Menu = loadedMenu
            elseif input.IsButtonDown(KEY_LSHIFT) then
                local warningMessage = "Creating a new config."
                printc( 255, 0, 0, 255, warningMessage)
                Notify.Simple("Warning", warningMessage, 5)
                Config.CreateCFG(G.Default_Menu) -- Save the config

                G.Menu = G.Default_Menu
            else
                local warningMessage = "Config is outdated or invalid. Creating a new config."
                printc( 255, 0, 0, 255, warningMessage)
                Notify.Simple("Warning", warningMessage, 5)
                Config.CreateCFG(G.Default_Menu) -- Save the config

                G.Menu = G.Default_Menu
            end
        else
            local errorMessage = "Error executing configuration file: " .. tostring(err)
            printc( 255, 0, 0, 255, errorMessage)
            Notify.Simple("Error", errorMessage, 5)
            Config.CreateCFG(G.Default_Menu) -- Save the config

            G.Menu = G.Default_Menu
        end
    else
        local warningMessage = "Config file not found. Creating a new config."
        printc( 255, 0, 0, 255, warningMessage)
        Notify.Simple("Warning", warningMessage, 5)
        Config.CreateCFG(G.Default_Menu) -- Save the config

        G.Menu = G.Default_Menu
    end
end

--[[ Callbacks ]]
local function OnUnload() -- Called when the script is unloaded
    Config.CreateCFG(G.Menu) -- Save the configurations
end

--[[ Unregister previous callbacks ]]--
callbacks.Unregister("Unload", "Movement_Unload")                                -- unregister the "Unload" callback
--[[ Register callbacks ]]--
callbacks.Register("Unload", "Movement_Unload", OnUnload)                         -- Register the "Unload" callback

return Config