
--[[ Imports ]]
local Common = require("Movement.Common")
--local FileBrowser = require("Cheater_Detection.Modules.FileBrowser")
local G = require("Movement.Globals")

local Menu = {}


local Lib = Common.Lib
local Fonts = Lib.UI.Fonts

---@type boolean, ImMenu
local menuLoaded, ImMenu = pcall(require, "ImMenu")
assert(menuLoaded, "ImMenu not found, please install it!")
assert(ImMenu.GetVersion() >= 0.66, "ImMenu version is too old, please update it!")

local lastToggleTime = 0
local Lbox_Menu_Open = true
local toggleCooldown = 0.1  -- 200 milliseconds

function Menu.HandleMenuShow()
    if input.IsButtonPressed(KEY_INSERT) then
        local currentTime = globals.RealTime()
        if currentTime - lastToggleTime >= toggleCooldown then
            Lbox_Menu_Open = not Lbox_Menu_Open  -- Toggle the state
            lastToggleTime = currentTime  -- Reset the last toggle time
        end
    end
end

G.Default_Menu = {
    Enable = true,
    DuckJump = true,
    SmartJump = true,
    EdgeJump = true,
    Visuals = true,
}

local function DrawMenu()
    Menu.HandleMenuShow()

    if Lbox_Menu_Open == true and ImMenu.Begin("Movement", true) then
        draw.SetFont(Fonts.Verdana)
        draw.Color(255, 255, 255, 255)

        -- Enable_bhop
        ImMenu.BeginFrame(1)
            G.Menu.Enable = ImMenu.Checkbox("Enable", G.Menu.Enable)
        ImMenu.EndFrame()

        -- Enable_SmartJump
        ImMenu.BeginFrame(1)
            G.Menu.SmartJump = ImMenu.Checkbox("SmartJump", G.Menu.SmartJump)
        ImMenu.EndFrame()

        -- Enable_Visuals
        ImMenu.BeginFrame(1)
            --G.Menu.EdgeJump = true = ImMenu.Checkbox("bhop    ", Main.BhopDetection.Enable)
            G.Menu.Visuals = ImMenu.Checkbox("Visuals", G.Menu.Visuals)
        ImMenu.EndFrame()
    ImMenu.End()
    end
end

--[[ Callbacks ]]
callbacks.Unregister("Draw", "Menu-MCT_Draw")                                   -- unregister the "Draw" callback
callbacks.Register("Draw", "Menu-MCT_Draw", DrawMenu)                              -- Register the "Draw" callback 

return Menu