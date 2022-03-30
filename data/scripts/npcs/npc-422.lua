local npcManager = require("npcManager");

local paddleWheel = {};

local npcID = NPC_ID

paddleWheel.platformConfig = npcManager.setNpcSettings{
	id=npcID, 
	gfxwidth=64, 
	gfxheight=32, 
	width=64, 
	height=32, 
	frames=1,
	score=0,
	playerblock=false,
	playerblocktop=true,
	ignorethrownnpcs = true,
	npcblock=false,
	npcblocktop=true,
	nogravity=true,
	noblockcollision=true,
	nofireball=true,
	noiceball=true,
	noyoshi=true,
	grabside=false,
	isshoe=false,
	isyoshi=false,
	iscoin=false,
	nohurt=true,
	nogliding=true,
	notcointransformable = true
};

function paddleWheel.onInitAPI()
	npcManager.registerEvent(npcID, paddleWheel, "onTickNPC", "onTickPlatform");
end

function paddleWheel.onTickPlatform(npc)
	if Defines.levelFreeze then return end
	
	if npc.data._orbits == nil then
		if npc:mem(0x132, FIELD_WORD) > 0 then
			npc.speedX, npc.speedY = 0, 0;
			
			npc:mem(0x132, FIELD_WORD, 0);
		end
	end
end

return paddleWheel