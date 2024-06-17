--[[
    Movement lua
        -smartjump and more
    Autor: Titaniummachine1
]]

--[[ actiave the script Modules]]
local Common = require("Movement.Common")
local G = require("Movement.Globals")
require("Movement.Config")
require("Movement.Visuals") --wake up the visuals
require("Movement.Menu")--wake up the menu

local function OnCreateMove(cmd)
    -- Get the local player
    G.pLocal = entities.GetLocalPlayer()
    local WLocal = Common.WPlayer.GetLocal()

    -- Check if the local player is valid and alive
    if not G.Menu.Enable or not G.pLocal or not G.pLocal:IsAlive() or not WLocal then
        G.jumpState = G.STATE_IDLE  -- Reset to STATE_IDLE state if player is not valid or alive
        return
    end

    -- cache player flags
    G.onGround = Common.isPlayerOnGround(G.pLocal)
    G.Ducking = Common.isPlayerDucking(G.pLocal)

    -- Calculate the strafe angle
    G.strafeAngle = Common.CalcStrafe(WLocal)

    --fix the hitbox
    if G.Ducking then
        G.vHitbox[2].z = 62
    else
        G.vHitbox[2].z = 82
    end

    -- Check if the player is on the ground and fully crouched, and handle edge case
    if G.onGround and (G.pLocal:GetPropVector("m_vecViewOffset[0]").z < 65 or G.Ducking) and G.jumpState ~= G.STATE_CTAP then
        G.jumpState = G.STATE_CTAP  -- Transition to STATE_CTAP to resolve the logical error
    end

    -- State machine for CTAP and jumping
    if G.jumpState == G.STATE_IDLE then
        -- STATE_IDLE: Waiting for jump commands
        Common.SmartJump(cmd) --do smartjump logic

        if G.onGround or G.ShouldJump then
            if G.ShouldJump then
                G.jumpState = G.STATE_PREPARE_JUMP  -- Transition to STATE_PREPARE_JUMP if jump key is pressed or ShouldJump is true
            end
        end

    elseif G.jumpState == G.STATE_PREPARE_JUMP then
        -- STATE_PREPARE_JUMP: Start crouching
        cmd:SetButtons(cmd.buttons | IN_DUCK)  -- Duck
        cmd:SetButtons(cmd.buttons & (~IN_JUMP))  -- Uncrouch
        G.jumpState = G.STATE_CTAP  -- Transition to STATE_CTAP to prepare for jump
        return

    elseif G.jumpState == G.STATE_CTAP then
        -- STATE_CTAP: Uncrouch and jump
        cmd:SetButtons(cmd.buttons & (~IN_DUCK))  -- UnDuck
        cmd:SetButtons(cmd.buttons | IN_JUMP)     -- Jump
        G.jumpState = G.STATE_ASCENDING  -- Transition to STATE_ASCENDING after initiating jump
        return

    elseif G.jumpState == G.STATE_ASCENDING then
        -- STATE_ASCENDING: Player is moving upwards
        cmd:SetButtons(cmd.buttons | IN_DUCK)  -- Crouch mid-air
        if G.pLocal:EstimateAbsVelocity().z <= 0 then
            G.jumpState = G.STATE_DESCENDING  -- Transition to STATE_DESCENDING once upward velocity stops
        end
        return

    elseif G.jumpState == G.STATE_DESCENDING then
        -- STATE_DESCENDING: Player is falling down
        cmd:SetButtons(cmd.buttons & (~IN_DUCK))  -- UnDuck when falling

        G.PredData = Common.Prediction.Player(WLocal, 1, G.strafeAngle, nil)
        if not G.PredData then return end

        G.PredPos = G.PredData.pos[1] --update predpos

        if not G.PredData.onGround[1] or not G.onGround then --when on ground or will be on ground next tick
            Common.SmartJump(cmd)
            if ShouldJump then
                cmd:SetButtons(cmd.buttons & (~IN_DUCK))
                cmd:SetButtons(cmd.buttons | IN_JUMP)
                G.jumpState = G.STATE_PREPARE_JUMP  -- Transition back to STATE_PREPARE_JUMP for bhop
            end
        else
            cmd:SetButtons(cmd.buttons | IN_DUCK)
            G.jumpState = G.STATE_IDLE  -- Transition back to STATE_IDLE once player lands
        end
    end
end

callbacks.Unregister("CreateMove", "jumpbughanddd")
callbacks.Register("CreateMove", "jumpbughanddd", OnCreateMove)
