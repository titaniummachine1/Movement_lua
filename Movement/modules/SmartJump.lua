---@diagnostic disable: duplicate-set-field, undefined-field
---@class SmartJump
local SmartJump = {}

local Common = require("Movement.Common")
local G = require("Movement.Globals")

-- Function to calculate the jump peak
local function GetJumpPeak(horizontalVelocityVector, startPos)
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

-- Smart jump logic
function SmartJump.Execute(cmd)
    if not G.pLocal then return end

    -- Get the player's data
    local pLocalPos = G.pLocal:GetAbsOrigin()
    local vel = Common.SmartVelocity(cmd) -- Adjust velocity based on movement input

    if G.Menu.SmartJump and G.onGround then
        local JumpPeekPerfectPos, JumpDirection = GetJumpPeak(vel, pLocalPos)
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

return SmartJump
