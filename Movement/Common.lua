---@diagnostic disable: duplicate-set-field, undefined-field
---@class Common
local Common = {}

pcall(UnloadLib) -- if it fails then forget about it it means it wasnt loaded in first place and were clean

local libLoaded, Lib = pcall(require, "LNXlib")
assert(libLoaded, "LNXlib not found, please install it!")
assert(Lib.GetVersion() >= 1.0, "LNXlib version is too old, please update it!")

Common.Lib = Lib
Common.Log = Lib.Utils.Logger.new("Movement")
Common.Notify = Lib.UI.Notify
Common.TF2 = Common.Lib.TF2
Common.Math, Common.Conversion = Common.Lib.Utils.Math, Common.Lib.Utils.Conversion
Common.WPlayer, Common.PR = Common.TF2.WPlayer, Common.TF2.PlayerResource
Common.Prediction = Common.TF2.Prediction
Common.Helpers = Common.TF2.Helpers

local G = require("Movement.Globals")


-- Function to normalize a vector
function Common.Normalize(vector)
    local length = vector:Length()
    return Vector3(vector.x / length, vector.y / length, vector.z / length)
end


function Common.RotateVectorByYaw(vector, yaw)
    local rad = math.rad(yaw)
    local cos, sin = math.cos(rad), math.sin(rad)

    return Vector3(
        cos * vector.x - sin * vector.y,
        sin * vector.x + cos * vector.y,
        vector.z
    )
end

-- Function to check the angle of the surface
function Common.isSurfaceWalkable(normal)
    local vUp = Vector3(0, 0, 1)
    local angle = math.deg(math.acos(normal:Dot(vUp)))
    return angle < G.MAX_WALKABLE_ANGLE
end

-- Helper function to check if the player is on the ground
function Common.isPlayerOnGround(player)
    local pFlags = player:GetPropInt("m_fFlags")
    return (pFlags & FL_ONGROUND) == FL_ONGROUND
end

-- Helper function to check if the player is on the ground
function Common.isPlayerDucking(player)
    return (player:GetPropInt("m_fFlags") & FL_DUCKING) == FL_DUCKING
end

---@param me WPlayer?
function Common.CalcStrafe(me)
    if not me then return end --nil check

    -- Reset data for dormant or dead players and teammates
    local angle = me:EstimateAbsVelocity():Angles() -- get angle of velocity vector

    -- Calculate the delta angle
    local delta = 0
    if G.lastAngle then
        delta = angle.y - G.lastAngle
        delta = Common.Math.NormalizeAngle(delta)
    end

    return delta
end

-- Function to calculate the jump peak
function Common.GetJumpPeak(horizontalVelocityVector, startPos)

    -- Calculate the time to reach the jump peak
    local timeToPeak = G.jumpForce / G.gravity

    -- Calculate horizontal velocity length
    local horizontalVelocity = horizontalVelocityVector:Length()

    -- Calculate distance traveled horizontally during time to peak
    local distanceTravelled = horizontalVelocity * timeToPeak

    -- Calculate peak position vector
    local peakPosVector = startPos + Common.Normalize(horizontalVelocityVector) * distanceTravelled

    -- Calculate direction to peak position
    local directionToPeak = Common.Normalize(peakPosVector - startPos)

    return peakPosVector, directionToPeak
end

--make the velocity adjusted towards direction we wanna walk
function Common.SmartVelocity(cmd)
    if not G.pLocal then return end --nil check

    -- Calculate the player's movement direction
    local moveDir = Vector3(cmd.forwardmove, -cmd.sidemove, 0)
    local viewAngles = engine.GetViewAngles()
    local rotatedMoveDir = Common.RotateVectorByYaw(moveDir, viewAngles.yaw)
    local normalizedMoveDir = Common.Normalize(rotatedMoveDir)
    local vel = G.pLocal:EstimateAbsVelocity()

    -- Normalize moveDir if its length isn't 0, then ensure velocity matches the intended movement direction
    if moveDir:Length() > 0 then
        if G.onGround then
        -- Calculate the intended speed based on input magnitude. This could be a fixed value or based on current conditions like player's max speed.
        local intendedSpeed = math.max(1, vel:Length()) -- Ensure the speed is at least 1

        -- Adjust the player's velocity to match the intended direction and speed
        vel = normalizedMoveDir * intendedSpeed
        end
    else
        -- If there's no input, you might want to handle the case where the player should stop or maintain current velocity
        vel = Vector3(0, 0, 0)
    end
    return vel
end


-- Smart jump logic
function Common.SmartJump(cmd)
    if not G.pLocal then return end

    -- Get the player's data
    local pLocalPos = G.pLocal:GetAbsOrigin()
    local vel = Common.SmartVelocity(cmd) -- Adjust velocity based on movement input

    if G.Menu.SmartJump and G.onGround then
        local JumpPeekPerfectPos, JumpDirection = Common.GetJumpPeak(vel, pLocalPos)
        G.JumpPeekPos = JumpPeekPerfectPos

        -- Trace to the peak position
        local trace = engine.TraceHull(pLocalPos, G.JumpPeekPos, G.vHitbox[1], G.vHitbox[2], MASK_PLAYERSOLID_BRUSHONLY)
        G.JumpPeekPos = trace.endpos

        if trace.fraction < 1 then
            -- Move up by jump height
            local startrace = trace.endpos + G.MAX_JUMP_HEIGHT

            -- Move one unit forward
            local endtrace = startrace + JumpDirection * 1

            -- Forward trace to check for sliding on possible walls
            local forwardTrace = engine.TraceHull(startrace, endtrace, G.vHitbox[1], G.vHitbox[2], MASK_PLAYERSOLID_BRUSHONLY)
            G.JumpPeekPos = forwardTrace.endpos

            -- Lastly, trace down to check for landing
            local traceDown = engine.TraceHull(G.JumpPeekPos, G.JumpPeekPos - G.MAX_JUMP_HEIGHT, G.vHitbox[1], G.vHitbox[2], MASK_PLAYERSOLID_BRUSHONLY)
            G.JumpPeekPos = traceDown.endpos

            if traceDown.fraction > 0 and traceDown.fraction < 0.75 then
                local normal = traceDown.plane
                if Common.isSurfaceWalkable(normal) then
                    G.ShouldJump = true
                else
                    G.ShouldJump = false
                end
            end
        end
    elseif input.IsButtonDown(KEY_SPACE) then
        G.ShouldJump = true
    else
        G.ShouldJump = false
    end
end

--[[ Callbacks ]]
local function OnUnload() -- Called when the script is unloaded
    pcall(UnloadLib) --unloading lualib
    client.Command('play "ui/buttonclickrelease"', true) -- Play the "buttonclickrelease" sound
end

--[[ Unregister previous callbacks ]]--
callbacks.Unregister("Unload", "Movement_Unload")                                -- unregister the "Unload" callback
--[[ Register callbacks ]]--
callbacks.Register("Unload", "Movement_Unload", OnUnload)                         -- Register the "Unload" callback

return Common