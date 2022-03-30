local npcManager = require("npcmanager");

local rockyWrench = {};

local npcID = NPC_ID

npcManager.registerHarmTypes(npcID, {HARM_TYPE_LAVA}, {[HARM_TYPE_LAVA] = {id = 13, xoffset = 0.5, xoffsetBack = 0, yoffset = 1, yoffsetBack = 1.5}});

npcManager.setNpcSettings{
	id = npcID, 
	gfxwidth = 16, 
	gfxheight = 16, 
	width = 16, 
	height = 16,
	frames = 4,
	framespeed = 3, 
	framestyle = 1,
	score = 0,
	speed = 1.5,
	noblockcollision = true,
	playerblock = false,
	npcblock = false,
	jumphurt = true,
	nofireball = true,
	noiceball = true,
	ignorethrownnpcs = true,
	linkshieldable = true,
	noshieldfireeffect = true,
	nofireball = true
};
	
function rockyWrench.onInitAPI()
	npcManager.registerEvent(npcID, rockyWrench, "onTickEndNPC", "onTickEndWrench");
	npcManager.registerEvent(npcID, rockyWrench, "onDrawNPC");
end

-- wrench AI
function rockyWrench.onTickEndWrench(npc)
	if Defines.levelFreeze then return end
	local data = npc.data._basegame;
	-- only perform logic for wrenches created by the rocky wrench logic
	local cfg = NPC.config[npc.id]
	local wrenchSpeed = cfg.speed;

	if data.stalled then
		-- during the time when the rocky is waiting to throw but the wrench is spawned
	
		data.counter = data.counter + 1;
		
		if (data.rocky) and (data.rocky.isValid) then
			local cfgp = NPC.config[data.rocky.id]
			if cfgp.hwrenchoffset then
				npc.direction = data.rocky.data._basegame.direction;
				npc.x = data.rocky.x + (1 + npc.direction)*data.rocky.width/2 - npc.direction*cfgp.hwrenchoffset - npc.width/2
				npc.y = data.rocky.y + cfgp.vwrenchoffset - npc.height/2
				if data.counter == 32 then
					data.stalled = false;			
					data.diagonalCounter = math.ceil(math.abs(cfgp.wrenchdiagonal));
					data.diagonal = math.sign(cfgp.wrenchdiagonal) * wrenchSpeed
					npc.friendly = data.friendly;
					npc.layerName = "Spawned NPCs"
				end
			else
				data.rocky = nil
			end
		end
		
	elseif data.free == false then
		-- performed while the wrench is on its diagonal trajectory
	
		if data.diagonalCounter > 0 then
			data.diagonalCounter = data.diagonalCounter - 1;
			
			if data.diagonalCounter > 5 then
				npc.speedX, npc.speedY = wrenchSpeed*npc.direction, data.diagonal - Defines.npc_grav;
			else
				-- lerp the last few steps to ease the diagonal trajectory into a 1D trajectory
			
				npc.speedX = math.lerp(wrenchSpeed*npc.direction, wrenchSpeed, 1 - data.diagonalCounter/5);
				npc.speedY = math.lerp(
					data.diagonal - Defines.npc_grav,
					-Defines.npc_grav,
					1 - data.diagonalCounter/5
				);
			end
		else
			-- wrench moves freely in a straight line in its direction after the diagonal trajectory is finished
		
			data.free = true;
		end
	else
		-- moving free wrenches
	
		npc.speedX, npc.speedY = wrenchSpeed*npc.direction, -Defines.npc_grav;
	end
end

function rockyWrench.onDrawNPC(npc)
	if npc:mem(0x12A, FIELD_WORD) <= 0 then return end

	local data = npc.data._basegame;

	if data.stalled then
		npc.animationFrame = 3;
	end
end

return rockyWrench