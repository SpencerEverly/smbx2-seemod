local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local chucks = {}

-- Essentially, this file exists because all Chucks share hurt and death animations.

--***************************************************************************************************
--                                                                                                  *
--              DEFAULTS AND NPC CONFIGURATION                                                      *
--                                                                                                  *
--***************************************************************************************************

local isChuck = {}
local chuckInfo = {}

local sharedChuckSettings = {
	--npconhit = 311,
	hurteffect = 252,
	deatheffect = 171,
	health = 3
}

function chucks.register(id, hurtFunction, hurtEndFunction)
	isChuck[id] = true
	
	local info = {}
	info.hurtFunction = hurtFunction;
	info.hurtEndFunction = hurtEndFunction;
	chuckInfo[id] = info;
	
	npcManager.registerEvent(id, chucks, "onTickEndNPC")
	npcManager.registerEvent(id, chucks, "onDrawNPC")
	
	npcManager.setNpcSettings(table.join(sharedChuckSettings, {id=id}));
end

function chucks.onInitAPI()
	registerEvent(chucks, "onNPCHarm")
	registerEvent(chucks, "onNPCKill")
end

--*********************************************
--                                            *
--                     AI                     *
--                                            *
--*********************************************

function chucks.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data._basegame
	
	if (v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x136, FIELD_BOOL) or v:mem(0x138, FIELD_WORD) > 0) then	
		v.ai1 = NPC.config[v.id].health; --Health
		return
	end
	
	-- Chuck initializing
	if (data.hurt == nil) then
		data.hurt = false;
		data.hurtTimer = 0;
		data.frame = 0;
	end
	
	-- Hurt animations
	if (data.hurt) then
		-- hurt animations
		data.hurtTimer = data.hurtTimer - 1;
		if v.collidesBlockBottom then
			v.speedX = 0
		end
		
		-- update effect
		if (data.hurtEffect ~= nil) then
			local diffX = v.x - data.hurtEffect.x
			local diffY = v.y - data.hurtEffect.y
			data.hurtEffect.x = v.x;
			data.hurtEffect.y = v.y;
			local needsRealign = false
			for k,e in ipairs(data.hurtEffect.effects) do
				if e.isHidden then
					e.isHidden = false
					needsRealign = true
				end
			end
			if needsRealign then
				data.hurtEffect:realignChildren()
			end
		end
		
		if (data.hurtTimer == 0) then
			-- change into regular chuck
			if (v.id ~= NPC.config[v.id].npconhit) then
				v.id = NPC.config[v.id].npconhit;
			end
				
			data.hurt = false;
			chuckInfo[v.id].hurtEndFunction(v);
		end
	end
end

-- override chuck sprite when displaying hurt effect
function chucks.onDrawNPC(v)
	if v:mem(0x12A, FIELD_WORD) <= 0 then return end
	local data = v.data._basegame
	if (data.hurt) then
		v.animationFrame = -1;
	end
end

function chucks.onNPCKill(eventObj, v, killReason)
	if isChuck[v.id] then
		local data = v.data._basegame
		if (data ~= nil and data.hurtEffect ~= nil) then
			data.hurtEffect:kill();
		end
	end
end

function chucks.onNPCHarm(eventObj, v, killReason, culprit)
	if isChuck[v.id] then
		-- Check if it's a fireball coming!
		local data = v.data._basegame
		if culprit then
			if culprit.__type == "NPC" and culprit.id == 13 then
				
				-- ignore damage from hit
				if v.ai1 > 1 then
					v.ai1 = v.ai1 - 0.8
				else
					v.ai1 = v.ai1 - 0.4
				end
				SFX.play(9)
				if v.ai1 > 0 then eventObj.cancelled = true end
			-- otherwise check if it's the player or the clown car or whatever
			elseif culprit.__type == "Player" and (killReason == 1 or killReason == 8 or killReason == 10) then
				if culprit.mount == 2 then
					v.ai3 = 0
					return
				end
				
				if (v.ai1 > 1 and not v.data._basegame.hurt) then
					if (culprit.x + 0.5 * culprit.width) < (v.x + v.width*0.5) then
						culprit.speedX = -4;
					else
						culprit.speedX = 4;
					end
				end
				if killReason == 8 and culprit.downKeyPressing then
					Colliders.bounceResponse(culprit, 6)
				end
			end
		end
		
		if (killReason == 1 or killReason == 8 or killReason == 10) then
			local data = v.data._basegame
			-- Don't kill npc if they're in a stun state
			if data.hurt then
				eventObj.cancelled = true;
				v.speedX = 0;
			-- Otherwise, begin hurt animation
			else
				-- decrement health
				v.ai1 = v.ai1 - 1;
				
				-- If there's still health left, trigger hurt animation
				if v.ai1 >= 1 then
					eventObj.cancelled = true;
				
					SFX.play(39);
					v.speedX = 0;
					data.frame = 8;
					
					data.hurt = true;
					data.hurtTimer = Effect.config[NPC.config[v.id].hurteffect][1].lifetime;
					if data.hurtEffect then data.hurtEffect:kill() end
					data.hurtEffect = Effect.spawn(NPC.config[v.id].hurteffect, v)
					data.hurtEffect.direction = v.direction;
					
					-- call the npc's specific hurt functions
					chuckInfo[NPC.config[v.id].npconhit].hurtFunction(v);
				-- otherwise, die
				else
					local e = Effect.spawn(NPC.config[v.id].deatheffect, v)
					e.direction = v.direction;
					SFX.play(9);
				end
			end
		end
	end
end

return chucks;