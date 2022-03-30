local effect = {}

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
	noblockcollision = true
}

npcManager.registerEvent(npcID, effect, "onTickNPC")
npcManager.registerEvent(npcID, effect, "onDrawNPC")
registerEvent(effect, "onNPCHarm")
registerEvent(effect, "onNPCKill", "onNPCHarm")

--Particle source

local function init(v)
	local data = v.data._basegame
	local s = v.data._settings or { }
	local e = s.particle or "p_smoke_small.ini"
	e = Misc.multiResolveFile(e, "particles/"..e)
	data.effect = { particle = Particles.Emitter(v.x+v.width*0.5,v.y+v.height*0.5,e,s.prewarm), nocull = s.nocull or false, priority = s.priority or -60, tint = Color.parse(s.tint or "white"), timescale = s.timescale or 1 }
	data.effect.particle:attach(v, true)
end

function effect:onTickNPC()
	local data = self.data._basegame
	if data.effect == nil then
		init(self)
	end
	
	local cx = self.x + self.width*0.5
	local cy = self.y + self.height*0.5
	
	if not data.effect.nocull then
		local e = data.effect.particle
		for _,c in ipairs(Camera.get()) do
			if cx + e.boundright > c.x and cx + e.boundleft < c.x + c.width and 
			   cy + e.boundbottom > c.y and cy + e.boundtop < c.y + c.height then
				if not self:mem(0x124, FIELD_BOOL) then
					self:mem(0x124, FIELD_BOOL, true)
				end
				self:mem(0x12A, FIELD_WORD, 180)
			end
		end
	else
		self:mem(0x12A, FIELD_WORD, 180)
	end
	
	utils.applyLayerMovement(self)
end

function effect.onNPCHarm(eventobj, npc)
	if npc.id == npcID then
		eventobj.cancelled = true
	end
end

function effect:onDrawNPC()
	local data = self.data._basegame
	
	if data.effect ~= nil then
		data.effect.particle.enabled = not self.isHidden
		data.effect.particle:draw(data.effect.priority, data.effect.nocull, nil, true, data.effect.tint, data.effect.timescale)
	end
end

return effect
