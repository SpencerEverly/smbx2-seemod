local light = {}

local npcManager = require("npcManager")
local utils = require("npcs/npcutils")

local npcID = NPC_ID

local lightConfig = npcManager.setNpcSettings {
	id = npcID,
	gfxheight = 0,
	gfxwidth = 0,
	width = 32,
	height = 32,
	frames = 1,
	framestyle = 0,
	ignorethrownnpcs = true,
	jumphurt = true,
	nofireball = true,
	noiceball = true,
	noyoshi = true,
	nogravity = true,
	nohurt = true,
	noblockcollision = true,
	notcointransformable = true
}

npcManager.registerEvent(npcID, light, "onTickNPC")
registerEvent(light, "onNPCHarm")
registerEvent(light, "onNPCKill", "onNPCHarm")

--Light source

local function init(v)
	local data = v.data._basegame
	local s = v.data._settings or { color = Color.white, radius = 64, brightness = 1 }
	data.light = Darkness.light(0,0,s.radius or 64,s.brightness,s.color,s.flicker)
	data.light:attach(v, true)
	Darkness.addLight(data.light)
end

function light:onTickNPC()
	local data = self.data._basegame
	if data.light == nil then
		init(self)
	end
	
	local cx = self.x + self.width*0.5
	local cy = self.y + self.height*0.5
	local r = data.light.radius
	for _,c in ipairs(Camera.get()) do
		if cx + r > c.x and cx - r < c.x + c.width and 
		   cy + r > c.y and cy - r < c.y + c.height then
			if not self:mem(0x124, FIELD_BOOL) then
				self:mem(0x124, FIELD_BOOL, true)
			end
			self:mem(0x12A, FIELD_WORD, 180)
		end
	end
	
	data.light.enabled = not self.isHidden
	
	utils.applyLayerMovement(self)
end

function light.onNPCHarm(eventobj, npc)
	if npc.id == npcID then
		eventobj.cancelled = true
	end
end

return light
