--[[ Movement Recorder ]]
--[[Credits to:lnx for lnxlib,menu and the base of the recorder]]

---@type boolean, lnxLib
local libLoaded, lnxLib = pcall(require, "lnxLib")
assert(libLoaded, "lnxLib not found, please install it!")
assert(lnxLib.GetVersion() >= 0.965, "lnxLib version is too old, please update it!")

local Fonts = lnxLib.UI.Fonts

---@type boolean, ImMenu
local menuLoaded, ImMenu = pcall(require, "ImMenu")
assert(menuLoaded, "ImMenu not found, please install it!")
assert(ImMenu.GetVersion() >= 0.66, "ImMenu version is too old, please update it!")

local Common = require("Movement.Common")
local G = require("Movement.Globals")
local Config = require("Movement.Config")

local Recorder = {}

-- Constants for minimum and maximum speed
local MIN_SPEED = 100  -- Minimum speed to avoid jittery movements
local MAX_SPEED = 450 -- Maximum speed the player can move

-- Function to compute the move direction
local function ComputeMove(pCmd, a, b)
    local diff = (b - a)
    if diff:Length() == 0 then return Vector3(0, 0, 0) end

    local x = diff.x
    local y = diff.y
    local vSilent = Vector3(x, y, 0)

    local ang = vSilent:Angles()
    local cPitch, cYaw, cRoll = pCmd:GetViewAngles()
    local yaw = math.rad(ang.y - cYaw)
    local pitch = math.rad(ang.x - cPitch)
    local move = Vector3(math.cos(yaw) * MAX_SPEED, -math.sin(yaw) * MAX_SPEED, -math.cos(pitch) * MAX_SPEED)

    return move
end

-- Function to make the player walk to a destination smoothly
local function WalkTo(pCmd, pLocal, pDestination)
    local localPos = pLocal:GetAbsOrigin()
    local distVector = pDestination - localPos
    local dist = distVector:Length()
    local velocity = pLocal:EstimateAbsVelocity():Length()

    -- If distance is greater than 1, proceed with walking
    if dist > 1 then
        local result = ComputeMove(pCmd, localPos, pDestination)
        -- If distance is less than 10, scale down the speed further
        if dist < 10 + velocity then
            local scaleFactor = dist / 100
            pCmd:SetForwardMove(result.x * scaleFactor)
            pCmd:SetSideMove(result.y * scaleFactor)
        else
            pCmd:SetForwardMove(result.x)
            pCmd:SetSideMove(result.y)
        end
    end
end

Recorder.currentTick = 0
Recorder.currentData = {}
Recorder.currentSize = 1

Recorder.isRecording = false
Recorder.isPlaying = false

Recorder.doRepeat = false
Recorder.doViewAngles = true

Recorder.recordings = {}
Recorder.selectedRecording = nil

local vHitbox = {Min = Vector3(-23, -23, 0), Max = Vector3(23, 23, 81)}
local setuptimer = 128
local AtRightPos = false

---@param userCmd UserCmd
local function OnCreateMove(userCmd)
    local pLocal = entities.GetLocalPlayer()
    if not pLocal or not pLocal:IsAlive() then return end

    if Recorder.isRecording then
        AtRightPos = false
        local yaw, pitch, roll = userCmd:GetViewAngles()
        Recorder.currentData[Recorder.currentTick] = {
            viewAngles = EulerAngles(yaw, pitch, roll),
            forwardMove = userCmd:GetForwardMove(),
            sideMove = userCmd:GetSideMove(),
            buttons = userCmd:GetButtons(),
            position =  pLocal:GetAbsOrigin(),
        }

        Recorder.currentSize = Recorder.currentSize + 1
        Recorder.currentTick = Recorder.currentTick + 1
    elseif Recorder.isPlaying then
        if userCmd.forwardmove ~= 0 or userCmd.sidemove ~= 0 then return end --input bypass

        if Recorder.currentTick >= Recorder.currentSize - 1 or Recorder.currentTick >= Recorder.currentSize + 1 then
            if Recorder.doRepeat then
                Recorder.currentTick = 0
                AtRightPos = false
            else
                AtRightPos = false
                Recorder.isPlaying = false
            end
        end

        local data = Recorder.currentData[Recorder.currentTick]
        if Recorder.currentData[Recorder.currentTick] == nil then return end --dont do anyyhign if data is inalid

            userCmd:SetViewAngles(data.viewAngles:Unpack())
            userCmd:SetForwardMove(data.forwardMove)
            userCmd:SetSideMove(data.sideMove)
            userCmd:SetButtons(data.buttons)

            if Recorder.doViewAngles then
                engine.SetViewAngles(data.viewAngles)
            end

            local distance = (pLocal:GetAbsOrigin() - data.position):Length()
            local velocityLength = pLocal:EstimateAbsVelocity():Length()

            velocityLength = math.max(0.1, math.min(velocityLength, 50))

            if not AtRightPos then
                WalkTo(userCmd, pLocal, data.position)
                if distance > velocityLength then
                    setuptimer = setuptimer - 1
                    if setuptimer < 1 and velocityLength < 5 or setuptimer < 66 and velocityLength < 1 then --or AntiStucktrace.fraction < 1 and setuptimer < 1 and velocityLength < 5 then
                        AtRightPos = true
                        setuptimer = 128
                    end
                    return
                end
            else
                if (distance < pLocal:EstimateAbsVelocity():Length() + 50) then
                    WalkTo(userCmd, pLocal, data.position)
                    if velocityLength < 1 then--or AntiStucktrace.fraction < 1 and velocityLength < 5 then
                        AtRightPos = true
                    end
                else
                    setuptimer = 128
                    AtRightPos = false
                end
            end

            --local AntiStucktrace = engine.TraceHull(pLocal:GetAbsOrigin(), data.position, vHitbox.Min, vHitbox.Max, MASK_PLAYERSOLID_BRUSHONLY)
            --f AntiStucktrace.fraction < 1 zthen
                Recorder.currentTick = Recorder.currentTick + 1
            --else
            --    Recorder.currentTick = Recorder.currentTick - 1
            --end
    end
end

function Recorder.Reset()
    AtRightPos = false
    Recorder.isRecording = false
    Recorder.isPlaying = false
    Recorder.currentTick = 0
    Recorder.currentData = {}
    Recorder.currentSize = 1
end

function Recorder.GetRecordings()
    local names = {}
    for name, _ in pairs(Recorder.recordings) do
        table.insert(names, name)
    end
    return names
end

function Recorder.GetSelectedRecording()
    return Recorder.selectedRecording
end

function Recorder.SelectRecording(name)
    if Recorder.recordings[name] then
        Recorder.selectedRecording = name
        Recorder.currentData = Recorder.recordings[name].data
        Recorder.currentSize = #Recorder.currentData
        Recorder.currentTick = 0
    end
end

function Recorder.StartNewRecording()
    local name = "Recording " .. tostring(#Recorder.recordings + 1)
    Recorder.recordings[name] = { data = {} }
    Recorder.SelectRecording(name)
    Recorder.isRecording = true
    Recorder.isPlaying = false
end

function Recorder.DeleteSelectedRecording()
    if Recorder.selectedRecording then
        Recorder.recordings[Recorder.selectedRecording] = nil
        Recorder.selectedRecording = nil
        Recorder.Reset()
    end
end

function Recorder.ToggleRecording()
    if Recorder.isRecording then
        Recorder.isRecording = false
        if Recorder.selectedRecording then
            Recorder.recordings[Recorder.selectedRecording].data = Recorder.currentData
        end
    else
        Recorder.isRecording = true
        Recorder.isPlaying = false
    end
end

function Recorder.TogglePlayback()
    if Recorder.isRecording then
        Recorder.isRecording = false
        if Recorder.selectedRecording then
            Recorder.recordings[Recorder.selectedRecording].data = Recorder.currentData
        end
    end
    Recorder.isPlaying = not Recorder.isPlaying
end

-- Save recordings to file
function Recorder.SaveRecordings()
    Config:Save("recordings.json")
end

-- Load recordings from file
function Recorder.LoadRecordings()
    Config:Load("recordings.json")
end

callbacks.Unregister("CreateMove", "LNX.Recorder.CreateMove")
callbacks.Register("CreateMove", "LNX.Recorder.CreateMove", OnCreateMove)

return Recorder
