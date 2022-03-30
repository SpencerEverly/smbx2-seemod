local npcManager = require("npcManager")
local utils = require("npcs/npcutils")

local mechafriend = {}

local npcID = NPC_ID

npcManager.registerHarmTypes(npcID, 
	{
		HARM_TYPE_NPC,
		HARM_TYPE_HELD,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_SWORD,
		HARM_TYPE_LAVA
	}, 
	{
		[HARM_TYPE_NPC]=184,
		[HARM_TYPE_HELD]=184,
		[HARM_TYPE_PROJECTILE_USED]=184,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}
	}
);

npcManager.setNpcSettings({
	id = npcID,
	gfxoffsety=2,
	grabside=1,
	nohurt=-1,
	gfxheight = 48,
	gfxwidth = 68,
	width = 32,
	height = 30,
	frames = 3,
	framespeed=8,
	framestyle = 1,
	noiceball=-1,
	jumphurt = 1,
	nofireball=-1,
	noyoshi=-1,
	recoverid = 368
})

function mechafriend.onInitAPI()
	npcManager.registerEvent(npcID, mechafriend, "onTickEndNPC", "onTickStun")
end

local function setDir(dir, v)
	if dir then
		v.direction = 1
	else
		v.direction = -1
	end
end

function mechafriend.onTickStun(v)
	if Defines.levelFreeze then return end
	
	local data = v.data._basegame
	
	if data.animTimer == nil then
		data.wakeTimer = 0 --7 seconds and then 8.5
		data.animTimer = 0
	end
	
	if v.isHidden or v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x124, FIELD_WORD) == 0 or v:mem(0x138, FIELD_WORD) > 0 then
		data.wakeTimer = 0
		data.animTimer = 0
		return
	end
	
	
	if data.wakeTimer > 585 then
		data.wakeTimer = 0
	end
	if v.collidesBlockBottom and data.animTimer <= 0 then
		v.speedX = 0
	end
	
	
	data.wakeTimer = data.wakeTimer + 1
	data.animTimer = data.animTimer - 1
	

	-- Kick physics (physics falls over)
	if v:mem(0x12C, FIELD_WORD) ~= 0 then
		data.animTimer = -50
	else
		for _,w in ipairs(Player.get()) do
			if Colliders.collide(w, v) and data.animTimer <= -8 and v.collidesBlockBottom then
			
				setDir(w.x < v.x, v)
				
				v.speedX = 3 * v.direction
				if v.speedY < -1 and w.upKeyPressing and not (w.leftKeyPressing or w.rightKeyPressing) then
					v.speedX = 0
				else
					SFX.play(9)
				end
				data.animTimer = 8
				data.wakeTimer = 0
			end
		end
	end
	
	if data.wakeTimer > 585 then
		v:transform(NPC.config[v.id].recoverid)
		utils.faceNearestPlayer(v)
		if v:mem(0x12C, FIELD_WORD) ~= 0 then
			Player(v:mem(0x12C, FIELD_WORD)):mem(0x154, FIELD_WORD, -1)
		end
	end
	
	
	v.animationTimer = 500
	v.animationFrame = 0
	
	if data.animTimer > -10 then
		v.animationFrame = 2
	end
	if data.wakeTimer >= 455 and data.wakeTimer%8 > 3 then
		v.animationFrame = 1
	end
	
	if v.direction == 1 then
		v.animationFrame = v.animationFrame + 3
	end
end
	
return mechafriend