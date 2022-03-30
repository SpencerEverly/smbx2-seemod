local sound = {}

local npcManager = require("npcManager")
local utils = require("npcs/npcutils")

local typemap = {}

function sound.register(npcID, typ)
	local s = npcManager.setNpcSettings {
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
	
	npcManager.registerEvent(npcID, sound, "onTickNPC")
	
	typemap[npcID] = typ
end

registerEvent(sound, "onNPCHarm")
registerEvent(sound, "onNPCKill", "onNPCHarm")

local falloffmap = { SFX.FALLOFF_SQUARE, SFX.FALLOFF_LINEAR, SFX.FALLOFF_NONE }
local function init(v, typ)
	local data = v.data._basegame
	local s = v.data._settings
	
	if s == nil then
		data.die = true
		v:kill()
		return
	end
	
	local snd = s.source
	
	if snd ~= nil then
		if tonumber(snd) then
			snd = tonumber(snd)
		else
			snd = Misc.resolveFile(snd)
		end
	end
	
	if snd == nil then
		data.die = true
		v:kill()
		return
	end
	
	local siz = {}
	if s.sourceSize then
		siz = s.sourceSize
	elseif s.sourceVector then
		siz = s.sourceVector
	end
	
	data.sound = SFX.create
	{
		x = v.x + v.width*0.5,
		y = v.y + v.height*0.5,
		sound = snd,
		parent = v,
		type = typ,
		volume = s.volume,
		falloffRadius = s.falloffRadius or 128,
		falloffType = falloffmap[(s.falloffType or 0) + 1],
		sourceRadius = s.sourceRadius or 32,
		sourceWidth = siz.w or 32,
		sourceHeight = siz.h or 32,
		sourceVector = vector.v2(siz.x or 64, siz.y or 0)
	}
end

function sound:onTickNPC()
	local data = self.data._basegame
	if data.sound == nil then
		init(self, typemap[self.id])
	end
	
	if data.sound ~= nil then
		local cx = self.x + self.width*0.5
		local cy = self.y + self.height*0.5
		local r = data.sound.falloffRadius
		for _,c in ipairs(Camera.get()) do
			if cx + r > c.x and cx - r < c.x + c.width and 
			   cy + r > c.y and cy - r < c.y + c.height then
				if not self:mem(0x124, FIELD_BOOL) then
					self:mem(0x124, FIELD_BOOL, true)
				end
				self:mem(0x12A, FIELD_WORD, 180)
			end
		end
		
		if self.isHidden and data.sound.playing then
			data.sound:stop()
		elseif not self.isHidden and not data.sound.playing  then
			data.sound:play()
		end
	end
	
	utils.applyLayerMovement(self)
end

function sound.onNPCHarm(eventobj, npc)
	if typemap[npc.id] then
		if npc.isGenerator or not npc.data._basegame.die then
			eventobj.cancelled = true
		elseif npc.data._basegame.sound then
			npc.data._basegame.sound:destroy()
		end
	end
end

return sound