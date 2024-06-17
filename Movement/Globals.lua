local G = {}

G.lastAngle = nil ---@type number
G.vHitbox = { Vector3(-23.99, -23.99, 0), Vector3(23.99, 23.99, 82) }
G.pLocal = entities.GetLocalPlayer()
G.onGround = true
G.Ducking = false
G.PredPos = Vector3(0, 0, 0)
G.PredData = {}
G.JumpPeekPos = Vector3(0, 0, 0)
G.ShouldJump = false
G.lastAngle = 0
G.strafeAngle = 0

-- State Definitions
G.STATE_IDLE = "STATE_IDLE"
G.STATE_PREPARE_JUMP = "STATE_PREPARE_JUMP"
G.STATE_CTAP = "STATE_CTAP"
G.STATE_ASCENDING = "STATE_ASCENDING"
G.STATE_DESCENDING = "STATE_DESCENDING"

-- Initial state
G.jumpState = G.STATE_IDLE

-- Constants for angle thresholds
G.MAX_JUMP_HEIGHT = Vector3(0, 0, 72) -- Example maximum jump height vector
G.MAX_WALKABLE_ANGLE = 45 -- Maximum angle considered walkable
--local MAX_CLIMBABLE_ANGLE = 55 -- Maximum angle considered climbable
G.gravity = 800 --gravity per second
G.jumpForce = 277 -- Initial vertical boost for a duck jump

G.Default_Menu = {
    Enable = true,
    DuckJump = true,
    SmartJump = true,
    EdgeJump = true,
    Visuals = true,
}

G.Menu = {
    Enable = true,
    DuckJump = true,
    SmartJump = true,
    EdgeJump = true,
    Visuals = true,
}

return G