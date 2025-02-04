--[[ Imports ]]
local Common = require("Movement.Common")
local G = require("Movement.Globals")
local Recorder = require("Movement.Modules.Recorder")

local Menu = {}

local Lib = Common.Lib
local Fonts = Lib.UI.Fonts

---@type boolean, ImMenu
local menuLoaded, ImMenu = pcall(require, "ImMenu")
assert(menuLoaded, "ImMenu not found, please install it!")
assert(ImMenu.GetVersion() >= 0.66, "ImMenu version is too old, please update it!")

G.Default_Menu = {
    Enable = true,
    DuckJump = true,
    SmartJump = true,
    EdgeJump = true,
    Visuals = true,
}

local function DrawMainMenu()
    if ImMenu.Begin("Movement", true) then
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
            G.Menu.Visuals = ImMenu.Checkbox("Visuals", G.Menu.Visuals)
        ImMenu.EndFrame()

        ImMenu.End()
    end
end

local function DrawRecorderMenu()
    if ImMenu.Begin("Movement Recorder", true) then
        -- Progress bar
        ImMenu.BeginFrame(1)
        ImMenu.PushStyle("ItemSize", { 385, 30 })

        local MaxSize = (Recorder.currentSize > 0 and Recorder.currentSize < 1000 and Recorder.isRecording and not Recorder.isPlaying) and 1000 or Recorder.currentSize
        if Recorder.isRecording and (Recorder.currentSize > MaxSize or Recorder.currentTick > MaxSize) then
            MaxSize = math.max(Recorder.currentSize, Recorder.currentTick)
        end
        if Recorder.isRecording then
            Recorder.currentTick = ImMenu.Slider("Tick", Recorder.currentTick, 0, MaxSize)
        else
            Recorder.currentTick = ImMenu.Slider("Tick", Recorder.currentTick, 0, Recorder.currentSize)
        end

        ImMenu.PopStyle()
        ImMenu.EndFrame()

        -- Buttons
        ImMenu.BeginFrame(1)
        ImMenu.PushStyle("ItemSize", { 125, 30 })

            local recordButtonText = Recorder.isRecording and "Stop Recording" or "Start Recording"
            if ImMenu.Button(recordButtonText) then
                Recorder.isRecording = not Recorder.isRecording
                if Recorder.isRecording then
                    Recorder.isPlaying = false
                    Recorder.currentTick = 0
                    Recorder.currentData = {}
                    Recorder.currentSize = 1
                else
                    Recorder.isPlaying = true
                end
            end

            local playButtonText
            if Recorder.currentData[Recorder.currentTick] == nil and Recorder.currentTick == 0 then
                playButtonText = "No Record"
            elseif Recorder.isPlaying then
                playButtonText = "Pause"
            else
                playButtonText = "Play"
            end

            if ImMenu.Button(playButtonText) then
                if Recorder.isRecording then
                    Recorder.isRecording = false
                    Recorder.isPlaying = true
                    Recorder.currentTick = 0
                elseif Recorder.isPlaying then
                    Recorder.isPlaying = false
                else
                    Recorder.isPlaying = true
                    Recorder.currentTick = 0
                end
            end

            if ImMenu.Button("Reset") then
                Recorder.Reset()
            end

        ImMenu.PopStyle()
        ImMenu.EndFrame()

        -- Options
        ImMenu.BeginFrame(1)

            Recorder.doRepeat = ImMenu.Checkbox("Auto Repeat", Recorder.doRepeat)
            Recorder.doViewAngles = ImMenu.Checkbox("Apply View Angles", Recorder.doViewAngles)

        ImMenu.EndFrame()

        ImMenu.End()
    end
end

local function DrawMenu()
    if gui.IsMenuOpen() then
        DrawMainMenu()
        DrawRecorderMenu()
    end
end

--[[ Callbacks ]]
callbacks.Unregister("Draw", "Menu-MCT_Draw")                                   -- unregister the "Draw" callback
callbacks.Register("Draw", "Menu-MCT_Draw", DrawMenu)                              -- Register the "Draw" callback 

return Menu