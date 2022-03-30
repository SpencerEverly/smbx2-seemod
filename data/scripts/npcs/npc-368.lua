local npcManager = require("npcManager")
local utils = require("npcs/npcutils")

local mechafriend = {}

local npcID = NPC_ID

npcManager.setNpcSettings({
	id = npcID,
	gfxoffsety=2,
	gfxheight = 48,
	gfxwidth = 68,
	width = 32,
	height = 30,
	frames = 4,
	framespeed=6,
	framestyle = 1,
	jumphurt = 0,
	nogravity = 0,
	nofireball=-1,
	noiceball=-1,
	noyoshi=-1,
	cliffturn=0,
	stunid = 369
})

npcManager.registerHarmTypes(npcID, 
	{
		HARM_TYPE_JUMP,
		HARM_TYPE_NPC,
		HARM_TYPE_HELD,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_SPINJUMP,
		HARM_TYPE_SWORD,
		HARM_TYPE_LAVA
	}, 
	{
		[HARM_TYPE_JUMP]=10,
		[HARM_TYPE_NPC]=183,
		[HARM_TYPE_PROJECTILE_USED]=183,
		[HARM_TYPE_HELD]=183,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}
	}
);

function mechafriend.onInitAPI()
	npcManager.registerEvent(npcID, mechafriend, "onTickNPC", "onTickKoopa")
	registerEvent(mechafriend, "onNPCKill", "onNPCKill", false)
end

function mechafriend.onNPCKill(obj, npc, rsn)
	if rsn ~= 1 or npc.id ~= npcID then return end
	
	obj.cancelled = true
	npc:transform(NPC.config[npc.id].stunid)
end

function mechafriend.onTickKoopa(v)
	if Defines.levelFreeze then return end
	
	local data = v.data._basegame
	
	if v.isHidden or v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x124, FIELD_WORD) == 0 or v:mem(0x138, FIELD_WORD) > 0 or v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x136, FIELD_BOOL) then
		data.turnTimer = 0
		return
	end
	
	if data.turnTimer == nil then
		data.turnTimer = 0
	end
	data.turnTimer = data.turnTimer + 1
	if data.turnTimer >= 65 then
		utils.faceNearestPlayer(v)
		data.turnTimer = 0
	end
	v.speedX = 0.7 * v.direction
end
	
return mechafriend