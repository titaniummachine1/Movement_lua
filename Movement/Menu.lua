--[[ Imports ]]
local Common   = require("Movement.Common")
local G        = require("Movement.Globals")
local Recorder = require("Movement.Modules.Recorder")

local Menu = {}

local Lib   = Common.Lib
local Fonts = Lib.UI.Fonts

---@type boolean, ImMenu
local menuLoaded, ImMenu = pcall(require, "ImMenu")
assert(menuLoaded, "ImMenu not found, please install it!")
assert(ImMenu.GetVersion() >= 0.66, "ImMenu version is too old, please update it!")

-- Set default menu values if not already defined.
G.Default_Menu = {
    Enable    = true,
    DuckJump  = true,
    SmartJump = true,
    EdgeJump  = true,
    Visuals   = true,
}
G.Menu = G.Menu or {}
G.Menu.Enable    = G.Menu.Enable    or G.Default_Menu.Enable
G.Menu.SmartJump = G.Menu.SmartJump or G.Default_Menu.SmartJump
G.Menu.Visuals   = G.Menu.Visuals   or G.Default_Menu.Visuals

--[[ DrawMainMenu ]]
local function DrawMainMenu()
    if ImMenu.Begin("Movement", true) then
        draw.SetFont(Fonts.Verdana)
        draw.Color(255, 255, 255, 255)

        -- Use a vertical layout so each control is on its own row.
        ImMenu.BeginFrame(ImAlign.Vertical)
            local newEnable, _ = ImMenu.Checkbox("Enable", G.Menu.Enable)
            G.Menu.Enable = newEnable

            local newSmartJump, _ = ImMenu.Checkbox("SmartJump", G.Menu.SmartJump)
            G.Menu.SmartJump = newSmartJump

            local newVisuals, _ = ImMenu.Checkbox("Visuals", G.Menu.Visuals)
            G.Menu.Visuals = newVisuals
        ImMenu.EndFrame()
        
        ImMenu.End()
    end
end

--[[ DrawRecorderMenu ]]
local function DrawRecorderMenu()
    if ImMenu.Begin("Movement Recorder", true) then
        ImMenu.BeginFrame(ImAlign.Vertical)
            -- Recordings Combo
            ImMenu.PushStyle("ItemSize", { 385, 30 })
                local recordings = Recorder.GetRecordings() or {}
                local selectedRecording = Recorder.GetSelectedRecording() or 1
                local newSelected = ImMenu.Combo("Recordings", selectedRecording, recordings)
                if newSelected ~= selectedRecording then
                    Recorder.SelectRecording(newSelected)
                    selectedRecording = newSelected
                end
            ImMenu.PopStyle()

            -- Progress bar slider
            ImMenu.PushStyle("ItemSize", { 385, 30 })
                local MaxSize = Recorder.currentSize
                if Recorder.isRecording then
                    if Recorder.currentSize > 0 and Recorder.currentSize < 1000 and not Recorder.isPlaying then
                        MaxSize = 1000
                    end
                    if Recorder.currentSize > MaxSize or Recorder.currentTick > MaxSize then
                        MaxSize = math.max(Recorder.currentSize, Recorder.currentTick)
                    end
                    Recorder.currentTick, _ = ImMenu.Slider("Tick", Recorder.currentTick, 0, MaxSize)
                else
                    Recorder.currentTick, _ = ImMenu.Slider("Tick", Recorder.currentTick, 0, Recorder.currentSize)
                end
            ImMenu.PopStyle()

            -- Buttons (arranged in a vertical column)
            ImMenu.PushStyle("ItemSize", { 125, 30 })
                if ImMenu.Button("New Recording") then
                    Recorder.StartNewRecording()
                end

                if ImMenu.Button("Delete Recording") then
                    Recorder.DeleteSelectedRecording()
                end

                local recordButtonText = Recorder.isRecording and "Stop Recording" or "Start Recording"
                if ImMenu.Button(recordButtonText) then
                    Recorder.ToggleRecording()
                end

                local playButtonText = Recorder.isPlaying and "Pause" or "Play"
                if ImMenu.Button(playButtonText) then
                    Recorder.TogglePlayback()
                end

                if ImMenu.Button("Reset") then
                    Recorder.Reset()
                end
            ImMenu.PopStyle()

            -- Options
            local newRepeat, _ = ImMenu.Checkbox("Auto Repeat", Recorder.doRepeat)
            Recorder.doRepeat = newRepeat

            local newViewAngles, _ = ImMenu.Checkbox("Apply View Angles", Recorder.doViewAngles)
            Recorder.doViewAngles = newViewAngles
        ImMenu.EndFrame()
        
        ImMenu.End()
    end
end

--[[ DrawMenu: called when the GUI is open ]]
local function DrawMenu()
    if gui.IsMenuOpen() then
        DrawMainMenu()
        DrawRecorderMenu()
    end
end

--[[ Callbacks ]]
callbacks.Unregister("Draw", "Menu-MCT_Draw")
callbacks.Register("Draw", "Menu-MCT_Draw", DrawMenu)

return Menu
