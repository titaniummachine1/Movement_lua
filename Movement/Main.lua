--[[
    Movement lua
        -smartjump and more
    Autor: Titaniummachine1
]]

--[[ Activate the script Modules ]]
local Common = require("Movement.Common")
local G = require("Movement.Globals")
require("Movement.Config")
require("Movement.Visuals") -- wake up the visuals
require("Movement.Menu")    -- wake up the menu
local SmartJump = require("Movement.Modules.SmartJump") -- Import the SmartJump module

local function OnCreateMove(cmd)
    -- Get the local player
    G.pLocal = entities.GetLocalPlayer()
    local WLocal = Common.WPlayer.GetLocal()

    -- Check if the local player is valid and alive
    if not G.Menu.Enable or not G.pLocal or not G.pLocal:IsAlive() or not WLocal then
        G.jumpState = G.STATE_IDLE  -- Reset state if player is not valid or alive
        return
    end

    -- Cache player flags
    G.onGround = Common.isPlayerOnGround(G.pLocal)
    G.Ducking = Common.isPlayerDucking(G.pLocal)

    -- Calculate the strafe angle
    G.strafeAngle = Common.CalcStrafe(WLocal)

    -- Fix the hitbox based on ducking state
    if G.Ducking then
        G.vHitbox[2].z = 62
    else
        G.vHitbox[2].z = 82
    end

    -- Remove the forced state change based solely on crouch and view offset.
    -- Instead, let the smartjump logic decide when to jump.

    -- State machine for jump logic
    if G.jumpState == G.STATE_IDLE then
        -- STATE_IDLE: Waiting for jump commands.
        SmartJump.Execute(cmd) -- Execute smartjump logic which sets G.ShouldJump

        if G.onGround and G.ShouldJump then
            G.jumpState = G.STATE_PREPARE_JUMP  -- Transition if jump is desired
            G.ShouldJump = false                -- Reset the flag so it doesn't persist
        end

    elseif G.jumpState == G.STATE_PREPARE_JUMP then
        -- STATE_PREPARE_JUMP: Start crouching.
        cmd:SetButtons(cmd.buttons | IN_DUCK)   -- Begin crouching
        cmd:SetButtons(cmd.buttons & (~IN_JUMP))  -- Ensure jump button is not active yet
        G.jumpState = G.STATE_CTAP              -- Transition to CTAP state
        return

    elseif G.jumpState == G.STATE_CTAP then
        -- STATE_CTAP: Uncrouch and initiate jump.
        cmd:SetButtons(cmd.buttons & (~IN_DUCK))  -- UnDuck
        cmd:SetButtons(cmd.buttons | IN_JUMP)     -- Press jump
        G.jumpState = G.STATE_ASCENDING           -- Transition to ascending state
        return

    elseif G.jumpState == G.STATE_ASCENDING then
        -- STATE_ASCENDING: Player is moving upward.
        cmd:SetButtons(cmd.buttons | IN_DUCK)  -- Maintain crouch mid-air
        if G.pLocal:EstimateAbsVelocity().z <= 0 then
            G.jumpState = G.STATE_DESCENDING  -- Transition when upward velocity stops
        end
        return

    elseif G.jumpState == G.STATE_DESCENDING then
        -- STATE_DESCENDING: Player is falling.
        cmd:SetButtons(cmd.buttons & (~IN_DUCK))  -- UnDuck while descending

        G.PredData = Common.Prediction.Player(WLocal, 1, G.strafeAngle, nil)
        if not G.PredData then return end

        G.PredPos = G.PredData.pos[1]  -- Update predicted landing position

        if not G.PredData.onGround[1] or not G.onGround then
            SmartJump.Execute(cmd)
            if G.ShouldJump then
                cmd:SetButtons(cmd.buttons & (~IN_DUCK))
                cmd:SetButtons(cmd.buttons | IN_JUMP)
                G.jumpState = G.STATE_PREPARE_JUMP  -- Re-initiate jump (for bunny hopping)
                G.ShouldJump = false                -- Reset jump flag after processing
            end
        else
            cmd:SetButtons(cmd.buttons | IN_DUCK)
            G.jumpState = G.STATE_IDLE  -- Once landed, reset to idle
        end
    end
end

callbacks.Unregister("CreateMove", "jumpbughanddd")
callbacks.Register("CreateMove", "jumpbughanddd", OnCreateMove)