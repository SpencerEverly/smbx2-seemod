local npcManager = require("npcmanager");

local scuttlebug = {};

local npcID = NPC_ID

npcManager.registerHarmTypes(
	npcID,
	{
		HARM_TYPE_JUMP,
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_SPINJUMP,
		HARM_TYPE_SWORD,
		HARM_TYPE_LAVA
	},
	{
		[HARM_TYPE_JUMP] = 226,
		[HARM_TYPE_FROMBELOW] = 225,
		[HARM_TYPE_NPC] = 225,
		[HARM_TYPE_PROJECTILE_USED] = 225,
		[HARM_TYPE_HELD] = 225,
		[HARM_TYPE_TAIL] = 225,
		[HARM_TYPE_LAVA] = {id = 13, xoffset = 0.5, xoffsetBack = 0, yoffset = 1, yoffsetBack = 1.5}
	}
);

npcManager.setNpcSettings{
	id = npcID,
	gfxwidth = 94,
	gfxheight = 50,
	width = 64,
	height = 48,
	frames = 4,
	framestyle = 1,
	framespeed = 3,
	gfxoffsety = 2,
	speed = 1.8,
	isWalker = true,
	
	boostheight = 12, -- boostheight*Defines.npc_grav is used for NPC.speedY when bouncing to change direction
	bouncewaitdelay = 15 -- how often it can bounce to change direction
};

-- helper function to determine if a scuttlebug should bounce to change direction
local function shouldBounceCheck(npc)
	local data = npc.data._basegame;

	if not npc.collidesBlockBottom then return false end
	
	local p = Player.getNearest(npc.x + 0.5 * npc.width, npc.y)
	local playerCenterX, npcCenterX = p.x + p.width/2, npc.x + npc.width/2;
	
	return (((playerCenterX < npcCenterX) and (npc.direction == 1)) or ((playerCenterX > npcCenterX) and (npc.direction == -1)))
end
	
function scuttlebug.onInitAPI()
	npcManager.registerEvent(npcID, scuttlebug, "onTickNPC", "onTickNPC");
	npcManager.registerEvent(npcID, scuttlebug, "onTickEndNPC", "onTickEndNPC");
end

-- walking scuttlebug AI
function scuttlebug.onTickNPC(npc)

	if Defines.levelFreeze then return end

	local data = npc.data._basegame;
	
	if data.bounceWaitTime == nil then
		-- simple initialization
	
		data.bounceWaitTime = 0; -- time before it can bounce and change direction
		data.dontMove = npc.dontMove; -- helps manage walker movemement
	end

	if npc.dontMove then return end

	local p = Player.getNearest(npc.x + 0.5 * npc.width, npc.y + 0.5 * npc.height)

	if (p:mem(0x13E, FIELD_WORD) == 0) then
		-- main logic to perform if the NPC can move and the player isn't dead
	
		if data.bounceWaitTime == 0 then
			-- perform the bounce and change direction
		
			npc.dontMove = true; -- must be set to change a walker NPC's speed/direction
			npc.direction = -npc.direction;
			npc.speedX = -npc.speedX;
			npc.speedY = -NPC.config[npc.id].boostheight*Defines.npc_grav; -- vertical bounce
			
			data.bounceWaitTime = -1;
		elseif data.bounceWaitTime == -1 then
			-- reset if it has bounced and should bounce again
		
			if shouldBounceCheck(npc) then
				data.bounceWaitTime = NPC.config[npc.id].bouncewaitdelay;
			end
		elseif shouldBounceCheck(npc) then
			-- reduce the counter only if the scuttlebug should bounce
		
			data.bounceWaitTime = data.bounceWaitTime - 1;
		else
			-- reset wait time if it no longer needs to bounce
		
			data.bounceWaitTime = NPC.config[npc.id].bouncewaitdelay;
		end
	end
end

-- manage NPC.dontMove field for walking scuttlebugs
-- changed upon bouncing to allow manipiulation of speed/direction fields
function scuttlebug.onTickEndNPC(npc)
	if Defines.levelFreeze then return end
	local data = npc.data._basegame;
	
	if (npc.dontMove) and (not data.dontMove) then
		npc.dontMove = false;
	end
end

return scuttlebug