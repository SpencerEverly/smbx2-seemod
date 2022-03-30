local npcManager = require("npcManager")

local rangs = {};
local npcID = NPC_ID

function rangs.onInitAPI()
	npcManager.registerEvent(npcID, rangs, "onTickNPC")
	npcManager.registerEvent(npcID, rangs, "onDrawNPC")
end

local rangData = {};
rangData.config = npcManager.setNpcSettings({
	id = npcID,
	gfxoffsety=6,
	gfxwidth=48,
	gfxheight=32,
	width=32,
	height=20,
	framestyle=0,
	frames=6,
	framespeed=1,
	foreground=1,
	speed=0,
	score=0,
	playerblock=0,
	playerblocktop=0,
	npcblock=0,
	npcblocktop=0,
	grabside=0,
	grabtop=0,
	jumphurt=1,
	nohurt=1,
	noblockcollision=1,
	cliffturn=0,
	noyoshi=1,
	nofireball=1,
	nogravity=1,
	noiceball=1,
	ignorethrownnpcs = true,
	nohammer=1,
	noshell=1,
	moving=1,
	health=3,
});

local HAMMER_MAXDIST = 256			-- Max distance a boomerang will travel before returning
local HAMMER_MAXSPEED = 12			-- Speed at which a boomerang is thrown
local HAMMER_VERTSPEED = 1.4		-- Speed at which boomerang can be moved vertically
local HAMMER_LIFETIME = 1.5			-- Number of seconds a boomerang will remain before vanishing

local BLOCK_BRICK = table.map{4,60,188,226};
local NPC_POWERUP = table.map{9,14,34,90,153,169,170,182,183,184,185,186,187,188,249,250,254,264,273,277,287,287,293}

function rangs.onTickNPC(rang)
	if Defines.levelFreeze then return end
	local data = rang.data._basegame
	
	if rang.isValid then

		if rang:mem(0x138, FIELD_WORD) > 0 then data.initialized = false return end

		local holdingPlayer = rang:mem(0x12C, FIELD_WORD)
		if rang:mem(0x132, FIELD_WORD) > 0 then
			rang:mem(0x13A, FIELD_WORD, rang:mem(0x132, FIELD_WORD))
		end
		local associatedPlayer = rang:mem(0x13A, FIELD_WORD) -- "Unknown"... Might need a more robust solution when this offset's purpose is found.

		-- Initialize freshly spawned boomerangs
		if not data.initialized and holdingPlayer == 0 then
			data.t = 0;										-- Timer for parabolic motion
			data.direction = rang.direction;				-- Direction the boomerang is headed in
			data.afterimagepos = {};							-- Table of positions for afterimages
			data.startX = rang.x;								-- Starting x position
			data.lifetime = HAMMER_LIFETIME*2500/39;
			local thrownPlayer = rang:mem(0x130, FIELD_WORD)
			if thrownPlayer > 0 then
				local p = Player(thrownPlayer)
				if p.upKeyPressing then
					data.vertdir = -1
				elseif p.downKeyPressing then
					data.vertdir = 1
				else
					data.vertdir = 0
				end
			else
				data.vertdir = math.sign(rang.speedY);
			end
			data.expired = false;
			data.health = math.max(NPC.config[rang.id].health, 1)
			
			-- Constants for parabolic motion
			data.a = -HAMMER_MAXSPEED*HAMMER_MAXSPEED/4/HAMMER_MAXDIST*data.direction;
			data.b = HAMMER_MAXSPEED*data.direction;
			-- Time at which velocity = 0
			data.vertex_t = -data.b/data.a/2;
			
			data.initialized = true;
		end

		if holdingPlayer > 0 then
			rang.direction = Player(holdingPlayer).direction
			data.initialized = false
			return
		end

		if associatedPlayer > 0 then
			associatedPlayer = Player(associatedPlayer)
			if associatedPlayer.upKeyPressing then data.vertdir = data.vertdir - 0.1; end
			if associatedPlayer.downKeyPressing then data.vertdir = data.vertdir + 0.1; end
			if data.vertdir > 1 then data.vertdir = 1; end
			if data.vertdir < -1 then data.vertdir = -1; end
		end
		
		if not rang.dontMove then
			-- Parabolic motion
			local a = data.a; local b = data.b; local t = data.t;			
			local dx = a*t*t + b*t;
			rang.x = data.startX + dx;
			rang.y = rang.y + data.vertdir*HAMMER_VERTSPEED;
			rang.speedX = 2*a*t + b;
			rang.speedY = data.vertdir*HAMMER_VERTSPEED;
			if math.abs(rang.speedX) > HAMMER_MAXSPEED then rang.speedX = -HAMMER_MAXSPEED*data.direction; end
		end
		data.t = data.t + 1;
		
		local cfg = NPC.config[rang.id]

		-- Remember positions
		if #data.afterimagepos < 8 then
			data.afterimagepos[#data.afterimagepos + 1] = {x = rang.x - 8, y = rang.y - 6};
		else
			for i = 1, #data.afterimagepos-1 do data.afterimagepos[i] = data.afterimagepos[i+1]; end
			data.afterimagepos[#data.afterimagepos] = {x = rang.x - 8 + cfg.gfxoffsetx, y = rang.y - cfg.gfxoffsety};
		end
		
		if not rang.friendly then
			-- Interact with NPCs as a projectile
			for _,npc in ipairs(NPC.getIntersecting(rang.x, rang.y, rang.x + rang.width, rang.y + rang.height)) do
				if NPC.HITTABLE_MAP[npc.id] and npc:mem(0x12A, FIELD_WORD) > 0 and npc:mem(0x12C, FIELD_WORD) == 0 and npc:mem(0x138, FIELD_WORD) == 0 and not npc.friendly then
					npc:harm(HARM_TYPE_EXT_HAMMER);
					data.health = data.health - 1
				end
			end			
			
			-- Destroy bricks
			for _,block in ipairs(Block.getIntersecting(rang.x, rang.y, rang.x + rang.width, rang.y + rang.height)) do
				-- If block is visible
				if (not block.isHidden) then
					if block.contentID ~= 0 then
						block:hit()
						data.health = 0
						break
					end
					if Block.MEGA_SMASH_MAP[block.id] and block:mem(0x5a, FIELD_WORD) == 0 then
						if block.contentID == 0 then
							block:remove(true)
							data.health = data.health - 1
						end
					end
				end
			end
		end
		
		-- Expire old boomerangs
		if data.t > data.lifetime then data.expired = true; end
		if data.expired or data.health <= 0 then
			Animation.spawn(63, rang.x + rang.width/2, rang.y + rang.height/2);
			rang:kill(HARM_TYPE_OFFSCREEN);
		end
	end
end

function rangs.onDrawNPC(rang)
	-- Render afterimages for boomerangs
	local data = rang.data._basegame
	if rang.isValid and data.initialized then
		for i,pos in ipairs(data.afterimagepos) do
			if NPC.config[npcID].foreground then
				prio = -15.1
			else
				prio = -45.1
			end
			Graphics.draw {x = pos.x, y = pos.y, type = RTYPE_IMAGE, image = Graphics.sprites.npc[npcID].img,
							isSceneCoordinates = true, opacity = 0.7*i/(#data.afterimagepos + 1), priority = prio,
							sourceY = ((rang.animationFrame + i*3)%6)*32, sourceHeight = 32};
		end
	end
end



return rangs;
