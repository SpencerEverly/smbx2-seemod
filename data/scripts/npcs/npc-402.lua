local hotFoot = {}

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local npcID = NPC_ID

local config = npcManager.setNpcSettings({
  id = npcID,
  width = 16,
  height = 32,
  gfxwidth = 16,
  gfxheight = 32,
  framestyle = 1,
  frames = 4,
  jumphurt = true,
  nofireball = true,
  spinjumpsafe = true,
  speed = 1,
  restingframes = -1,
  nospecialanimation = false,
  lightcolor=Color.orange,
  lightradius=64,
  lightbrightness=1,
	ishot = true,
	durability = -1
})

npcManager.registerHarmTypes(npcID,
  {HARM_TYPE_NPC, HARM_TYPE_HELD, HARM_TYPE_SWORD, HARM_TYPE_FROMBELOW, HARM_TYPE_LAVA, HARM_TYPE_PROJECTILE_USED},
  {
    [HARM_TYPE_HELD] = 10,
    [HARM_TYPE_NPC] = 10,
    [HARM_TYPE_PROJECTILE_USED] = 10,
    [HARM_TYPE_SWORD] = 10,
    [HARM_TYPE_FROMBELOW] = 10,
    [HARM_TYPE_LAVA] = {id = 13, xoffset = 0.5, xoffsetBack = 0, yoffset = 1, yoffsetBack = 1.5}
  }
)

if config.restingframes == -1 then
    config.restingframes = math.floor(config.frames*0.5)
end

local function facing(npc)
  local P
  local Dist

  -- Find the closest player to the NPC (only X axis)
  for _, p in ipairs(Player.get()) do
    local dist = npc.x + npc.width - (p.x + p.width)
    if not Dist or math.abs(dist) < math.abs(Dist) then
      Dist = dist
      P = p
    end
  end

  local dir = P.direction
  if (Dist > 0 and dir == 1) or (Dist < 0 and dir == -1) or P:mem(0x50,FIELD_WORD) == -1  then --If the player is spinjumping
    return true
  else
    npc.direction = dir
    return false
  end
end

function hotFoot.onTickNPC(v)
  if Defines.levelFreeze or v:mem(0x12A, FIELD_WORD) <= 0 or v.dontMove or v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x136, FIELD_BOOL) or v:mem(0x138, FIELD_WORD) > 0 then return end

  local data = v.data._basegame

  data.facing = facing(v)

  if data.facing then
    v.speedX = 0
  else
    v.speedX = v.direction
  end
end

function hotFoot.onDrawNPC(n)
  if Defines.levelFreeze or n:mem(0x12A, FIELD_WORD) <= 0 or config.nospecialanimation then return end
  local data = n.data._basegame
		
  local frames = config.restingframes
  local offset = 0
  local gap = config.frames - config.restingframes
  if (not data.facing) and not n.dontMove then
    n:mem(0x120, FIELD_BOOL, false) --bounced off block
    frames = config.frames - config.restingframes
    offset = config.restingframes
    gap = 0
  end
  npcutils.restoreAnimation(n)
  n.animationFrame = npcutils.getFrameByFramestyle(n, {
    frames = frames,
    offset = offset,
    gap = gap
  })
end

function hotFoot.onInitAPI()
  npcManager.registerEvent(npcID, hotFoot, "onTickNPC")
  npcManager.registerEvent(npcID, hotFoot, "onDrawNPC")
end

return hotFoot
