local npcManager = require("npcmanager");

local rockyWrench = {};

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
		[HARM_TYPE_JUMP] = 194,
		[HARM_TYPE_FROMBELOW] = 194,
		[HARM_TYPE_NPC] = 194,
		[HARM_TYPE_PROJECTILE_USED] = 194,
		[HARM_TYPE_HELD] = 194,
		[HARM_TYPE_TAIL] = 194,
		[HARM_TYPE_LAVA] = {id = 13, xoffset = 0.5, xoffsetBack = 0, yoffset = 1, yoffsetBack = 1.5}
	}
);

npcManager.setNpcSettings(
	{
		id = npcID, 
		gfxwidth = 32, 
		gfxheight = 32, 
		width = 32, 
		height = 32,
		frames = 4,
		framespeed = 8,
		framestyle = 1,
		score = 2,
		nogravity = true,
		noblockcollision = true,
		playerblock = false,
		npcblock = false,
		playerblocktop = true,

		wrenchdiagonal = -32,
		vwrenchoffset = 10,
		hwrenchoffset = 18,
		revealspeed = 1,
		hidespeed = 2,
		peektime = 90,
		cooldown = 40,
		spawnid = 396
	}
);

-- AI states

rockyWrench.STATE = {
	INACTIVE = 0,
	REVEALING = 1,
	STALLED = 2,
	THROWING = 3,
	HIDING = 4,
	IDLE = 5
};

-- rocky wrench initialization function
local function init(npc)
	local data = npc.data._basegame;

	npc.y = npc.y + NPC.config[npc.id].height; -- move NPC down one multiple of its height where it will start to reveal itself
	
	npc.height = 0;

	data.counter = 0;
	data.state = rockyWrench.STATE.INACTIVE;
	data.animFrame = 1;
	data.hasPeeked = false;
	data.peekCounter = 0;
	data.wrench = nil;
	data.direction = npc.direction
	data.friendly = npc.friendly;
end
	
function rockyWrench.onInitAPI()
	npcManager.registerEvent(npcID, rockyWrench, "onTickNPC", "onTickRocky");
	npcManager.registerEvent(npcID, rockyWrench, "onDrawNPC");

	registerEvent(rockyWrench, "onNPCKill");
end

-- rocky wrench AI
function rockyWrench.onTickRocky(npc)
	if Defines.levelFreeze then return end
	local data = npc.data._basegame;
	
	local layer = npc.layerObj;
	

	if npc.isHidden or npc:mem(0x12A, FIELD_WORD) <= 0 then
		-- wrenches will be destroyed if they have not yet been thrown
		
		if (data.wrench) and (data.wrench.isValid) and (data.wrench.data) and (data.wrench.data._basegame.stalled) then
			(data.wrench):kill(HARM_TYPE_OFFSCREEN);
		end
		data.state = nil
		return
	end
	
	if data.state == nil then
		init(npc);
	end

	npc.speedX = 0;
	npc.speedY = 0
	
	data.startY = npc.y + npc.height;

	if npc:mem(0x138, FIELD_WORD) > 0 or npc:mem(0x12C, FIELD_WORD) > 0 then
		data.state = rockyWrench.STATE.IDLE;
		return
	end
	local cfg = NPC.config[npc.id]

	if (data.wrench) and (data.wrench.isValid) and (data.wrench.data) and (data.wrench.data._basegame.stalled) then
	data.wrench.x = npc.x + (1 + data.direction)*npc.width/2 - data.direction*cfg.hwrenchoffset - NPC.config[cfg.spawnid].width/2
	data.wrench.y = npc.y + cfg.vwrenchoffset - NPC.config[cfg.spawnid].height/2
	end
	
	if data.state == rockyWrench.STATE.INACTIVE then
		-- if onscreen and currently is offscreen begin AI cycle
	
		data.state = rockyWrench.STATE.REVEALING;
		data.counter = 0;
		data.hasPeeked = false;
		data.peekCounter = 0;	
		
		-- safeguarding for the NPC's y-position
		
		npc.y = data.startY;
	elseif data.state == rockyWrench.STATE.REVEALING then
		-- logic for the rocky wrench revealing itself
	
		data.spawnedWrench = false;
		npc.height = data.counter;
	
		if data.counter < 10 then
			-- movement to reveal itself
		
			data.counter = data.counter + 2;
			npc.speedY = -2;
		elseif not data.hasPeeked then
			-- stalling phase during which the NPC is partially revealed
		
			if data.peekCounter < cfg.peektime then
				data.peekCounter = data.peekCounter + 1;
				
				if data.peekCounter == math.floor(cfg.peektime/2) then
					-- adjust the NPC's direction based on player position

					local p = Player.getNearest(npc.x, npc.y)
					
					if p.x + p.width/2 < npc.x + npc.width/2 then
						npc.direction = -1;
						data.direction = -1
					else
						npc.direction = 1;
						data.direction = 1
					end
				end
			else
				data.hasPeeked = true;
			end
			
			npc.speedY = 0;
		elseif data.hasPeeked then
			-- after the rocky has paused on its way up
		
			local trueHeight = cfg.height;
		
			if npc.height < trueHeight then				
				data.counter = data.counter + cfg.revealspeed;
				npc.speedY = -cfg.revealspeed;
			elseif npc.height == trueHeight then
				-- when the rocky reaches its full height go to the next phase
			
				data.animFrame = 2;
			
				data.state = rockyWrench.STATE.STALLED;
				data.counter = 0;

				npc.speedY = 0;
			end
		end
	elseif (data.state == rockyWrench.STATE.STALLED) or (data.state == rockyWrench.STATE.THROWING) then
		-- general counter logic for movement and forced animation frames
	
		data.counter = data.counter + 1;
		
		if data.counter == 30 then
			data.state = rockyWrench.STATE.THROWING;
		elseif data.counter == 40 then
			data.animFrame = 3;
		elseif data.counter == 80 then
			data.state = rockyWrench.STATE.HIDING;
			data.counter = 0;
		end
		
		if (data.state == rockyWrench.STATE.STALLED) and (not data.spawnedWrench) then
			-- spawn a wrench
		
			local wrench = NPC.spawn(
								cfg.spawnid,
								npc.x + (1 + data.direction)*npc.width/2 - data.direction*cfg.hwrenchoffset - NPC.config[cfg.spawnid].width/2,
								npc.y + cfg.vwrenchoffset - NPC.config[cfg.spawnid].height/2,
								npc:mem(0x146, FIELD_WORD)
							)
			
			if wrench.data._basegame == nil then
				wrench.data._basegame = {};
			end
			
			wrench.direction = data.direction;
			wrench.friendly = true;
			wrench.layerName = "Spawned NPCs"
			
			local wrenchData = wrench.data._basegame;

			wrenchData.friendly = npc.friendly;
			wrenchData.rocky = npc;
			wrenchData.counter = 0;
			wrenchData.stalled = true;

			data.wrench = wrench;
			data.spawnedWrench = true;
		end
		
		npc.speedY = 0;
	elseif data.state == rockyWrench.STATE.HIDING then
		-- rocky returning to its hidden state
	
		data.animFrame = 1;
		npc.height = cfg.height - data.counter;

		if npc.height > 0 then
			data.counter = data.counter + cfg.hidespeed;
			npc.speedY = cfg.hidespeed;
		elseif npc.height == 0 then
			data.state = rockyWrench.STATE.IDLE;
			data.counter = 0;
			
			npc.speedY = 0;
		end
	elseif data.state == rockyWrench.STATE.IDLE then
		-- idle state involves pausing and being unharmable; killed rocky wrenches that will respawn default first to this state
	
		data.counter = data.counter + 1;
		
		if npc.height > 0 then
			npc.y = npc.y + npc.height;
			npc.height = 0;
		end

		npc.friendly = true;
		
		if data.counter >= cfg.cooldown then
			data.state = rockyWrench.STATE.INACTIVE;
			
			npc.friendly = data.friendly;
		end
		
		npc.speedY = 0;
	end
	if layer and not layer:isPaused() then
		data.startY = data.startY + layer.speedY
		npc.speedX = npc.speedX + layer.speedX
		npc.speedY = npc.speedY + layer.speedY
	end
	
	if data.state >= 1 and data.state <= 4 then
		for k,p in ipairs(Player.get()) do
			if (Colliders.speedCollide(p, npc)) and (not p:isGroundTouching()) and (p.speedY > npc.speedY) then
				npc:kill(HARM_TYPE_JUMP);
				
				Colliders.bounceResponse(p);
			end
		end
	end
end

-- draw logic for rocky wrenches
function rockyWrench.onDrawNPC(npc)
	if npc:mem(0x12A, FIELD_WORD) <= 0 then return end

	local data = npc.data._basegame;

	if data.state == nil then return end
		
	if (data.state ~= rockyWrench.STATE.INACTIVE) and (data.state ~= rockyWrench.STATE.IDLE) then
		-- only draw visible rocky wrenches
		local cfg = NPC.config[npc.id]
		npc.animationFrame = -1;
		local offsetX;
		
		if data.direction == -1 then
			offsetX = 0;
		else
			offsetX = 3*cfg.height;
		end
		
		-- somewhat awkward draw logic based on some position shenanigans
		
		local modifier;
		local ext = 0;
		
		if npc.layerObj and npc.layerObj.speedY < 0 then
			modifier = 1;
		else
			modifier = 0;
		end
	
		if data.state == rockyWrench.STATE.REVEALING then
			if data.hasPeeked then
				ext = 1;
			elseif data.peekCounter == 0 then
				ext = 2;
			end
		end

		local p = -75
		if cfg.foreground then
			p = -15
		end

		Graphics.drawImageToSceneWP(
			Graphics.sprites.npc[npc.id].img,
			npc.x + cfg.gfxoffsetx,
			npc.y + cfg.gfxoffsety + modifier,
			0,
			offsetX + cfg.height*(data.animFrame - 1),
			npc.width,
			npc.height + ext,
			p
		);
	elseif (npc:mem(0x138, FIELD_WORD) > 0 or npc:mem(0x12C, FIELD_WORD) > 0) and data.animFrame then
		npc.animationFrame = 1.5 + 1.5 * npc.direction
	else
		npc.animationFrame = -1
	end
end

-- detect killed rocky wrenches, specifically generators, and respawn them to the idle state
function rockyWrench.onNPCKill(eventObj, killedNPC, killReason)
	if (killedNPC.id == npcID) and (killReason ~= HARM_TYPE_OFFSCREEN) and (killReason ~= HARM_TYPE_LAVA) then
		local data = killedNPC.data;
		
		if data._basegame then
			data = data._basegame;
		
			if (data.wrench) and (data.wrench.isValid) and (data.wrench.data) and (data.wrench.data._basegame.stalled) then
				-- make stalled wrenches just fall upon a rocky wrench being killed
			
				data.wrench.data._basegame.rocky = nil;
			end
		end
	end
end

return rockyWrench