local blockmanager = require("blockmanager")
local blockutils = require("blocks/blockutils")

local block = {}

local blockdata

local sound = Misc.resolveSoundFile("crash-switch")

function block.registerSwitch(id, func, hitid)
	if blockdata == nil then
		blockdata = {}
		registerEvent(block, "onPostBlockHit", "onPostBlockHit", false)
	end
	blockdata[id] = {f = func, hitid = hitid}   
	blockmanager.registerEvent(id, block, "onTickBlock")
	blockmanager.registerEvent(id, block, "onPostExplosionBlock")
end

local function trigger(v)
	Effect.spawn(274, v.x + v.width*0.5, v.y + v.height*0.5)
	Defines.earthquake = 8
	SFX.play(sound)
	local id = v.id
	v.id = blockdata[v.id].hitid
	
	blockutils.bump(v)
	blockdata[id].f(v)
	
	if v:mem(0x58, FIELD_WORD) ~= -1 then
		local e = v:mem(0x0C, FIELD_STRING)
		if e ~= nil and e ~= "" then
			triggerEvent(e)
		end
	end
end

function block.onPostBlockHit(v)
	if blockdata[v.id] == nil then return end
	trigger(v)
end

function block:onPostExplosionBlock(c)
	local data = self.data._basegame
	if (data.timer == nil or data.timer >= 0) and Colliders.collide(c.collider,self) then
		data.timer = -12;
	end
end

function block.onTickBlock(v)
	if v.isHidden or v:mem(0x5A, FIELD_BOOL) then return end
	local data = v.data._basegame
	
	if v:mem(0x54,FIELD_WORD) == 12 then
		if data.timer == nil or data.timer >= 0 then
			data.timer = -12
		end
	end
	
	if data.timer then
		if data.timer < 0 then
			data.timer = data.timer+1
			if data.timer == 0 then
				local obj = {cancelled = false}
				EventManager.callEvent("onBlockHit", obj, v.idx, false, 0)
			end
		end
	else
	
		local collider = blockutils.getHitbox(v, 1)
	
		--TODO: Replace with better bouncing
		for _,w in ipairs(Player.get()) do
			if w.speedY > 0 and w.x < v.x+v.width and w.x + w.width > v.x and Colliders.bounce(w, collider) then
				local obj = {cancelled = false}
				EventManager.callEvent("onBlockHit", obj, v.idx, true, w.idx)
				if not obj.cancelled then
					Colliders.bounceResponse(w)
					break
				end
			end
		end
		
	end
end

return block