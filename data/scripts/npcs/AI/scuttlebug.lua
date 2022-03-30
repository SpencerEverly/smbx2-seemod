local npcManager = require("npcmanager");

local scuttlebug = {};

local abandonnedStrings = {};

local idMap = {}

-- helper function to draw scuttlebug strings
local function drawString(x, y1, y2, p, c)
	Graphics.drawLine{x1 = x, y1 = y1, x2 = x, y2 = y2, priority = p, color = c, sceneCoords = true};
end

-- creator function for a string object after a scuttlebug is killed
local function abandonnedString(npc, cfg)
	local data = npc.data._basegame;

	local str;
	
	if data ~= nil then
		str = {layer = data.layer, x = npc.x + npc.width/2, y2 = npc.y + npc.height/4};

		if data.usesSectionTop then
			str.y1 = Section(npc:mem(0x146, FIELD_WORD)).boundary.top;
		else
			str.y1 = data.topY;
		end
		str.speed = cfg.stringretractspeed
		str.priority = cfg.stringpriority
		str.color = cfg.stringcolor
	end
	
	table.insert(abandonnedStrings, str);
end

-- helper function to determine if a scuttlebug should bounce to change direction
local function shouldBounceCheck(npc)
	local data = npc.data._basegame;

	if not npc.collidesBlockBottom then return false end
	
	local p = Player.getNearest(npc.x + 0.5 * npc.width, npc.y)
	local playerCenterX, npcCenterX = p.x + p.width/2, npc.x + npc.width/2;
	
	return (((playerCenterX < npcCenterX) and (npc.direction == 1)) or ((playerCenterX > npcCenterX) and (npc.direction == -1)))
end

function scuttlebug.register(id)
	idMap[id] = true
	npcManager.registerEvent(id, scuttlebug, "onTickNPC", "onTickHangingNPC");
	npcManager.registerEvent(id, scuttlebug, "onDrawNPC", "onDrawHangingNPC");
end
	
function scuttlebug.onInitAPI()
	registerEvent(scuttlebug, "onTick");
	registerEvent(scuttlebug, "onDraw");
	registerEvent(scuttlebug, "onNPCKill");
end

-- hanging scuttlebug AI
function scuttlebug.onTickHangingNPC(npc)
	if Defines.levelFreeze then return end
	if npc:mem(0x138, FIELD_WORD) == 2 then return end

	local data = npc.data._basegame;

	if data.targetY == nil then
		local p = Player.getNearest(npc.x, npc.y)
		if npc.section == p.section then
			-- initialization for hanging scuttlebugs in the player's section

			data.dropping = false; -- whether the NPC is dropping downwards
			data.oscillationCounter = 0; -- determines sinusoidal change in y-position while swinging
			data.verticalDirection = 1; -- 1=down, -1=up
			data.swinging = false; -- whether or not the NPC is swinging
			
			-- determine whether its string attaches to a block or the section top
			local sec = Section(p.section)
			local rangeBlocks = Block.getIntersecting(npc.x, sec.boundary.top, npc.x + npc.width, npc.y); -- can only hook onto solid blocks or section top
			if #rangeBlocks > 0 then
				local blocks = {}

				for k,v in ipairs(rangeBlocks) do
					if not v.isHidden and v:mem(0x5A, FIELD_WORD) == 0 and (Block.SOLID_MAP[v.id] or Block.SEMISOLID_MAP[v.id]) then
						table.insert(blocks, v)
					end
				end
				if #blocks > 0 then
					local checkIntersecting = true;
					local top = sec.boundary.top;
					local centerX = npc.x + npc.width/2;
					
					while not data.topY do
						-- repeats this process until there are no more intersecting blocks as some may not be viable (hidden, etc.)
					
						local intersects, _, _, block = Colliders.linecast({centerX + 0.0000001, npc.y}, {centerX, top}, blocks); -- linecast up to the top of the section
					
						if intersects then
							-- if a colliding semi-/solid block is found
							data.topY = block.y + block.height;
							data.usesSectionTop = false;
							data.layer = block.layerObj;
						else
							-- use the top of the section if no viable blocks are found
						
							data.topY = sec.boundary.top - npc.height - 32;
							data.usesSectionTop = true;
							data.layer = npc.layerObj
						end
					end
				else
					data.topY = sec.boundary.top - npc.height - 32;
					data.usesSectionTop = true;
					data.layer = npc.layerObj
				end
			else
				data.topY = sec.boundary.top - npc.height - 32;
				data.usesSectionTop = true;
				data.layer = npc.layerObj
			end
			-- move the NPC to the start position (original placed position is saved as target)
			data.targetY = npc.y;
			npc.y = data.topY;
			npc:mem(0x124, FIELD_BOOL,true)
		end
	end

	if data.targetY == nil then
		return
	end

	-- main logic
	
	if npc:mem(0x124, FIELD_BOOL) then
		npc:mem(0x12A, FIELD_WORD, 180); -- set the NPC to act as if it is onscreen as it will be dopping from offscreen
		local p = Player.getNearest(npc.x, npc.y)
		local cam = Camera(p.idx)
		if (not data.dropping) and (not data.swinging) and (((npc.x >= cam.x) and (npc.x + npc.width <= (cam.x + cam.width)))) then
			-- begin dropping logic if the NPC is within the camera bounds horizontally
			if npc:mem(0x136, FIELD_BOOL) or npc:mem(0x138, FIELD_WORD) > 0 then
				data.swinging = true
				npc.y = data.targetY
			else
				data.dropping = true;
			end
		end

		if (data.dropping) or (data.swinging) then
			-- logic for vertical movement
			local cfg = NPC.config[npc.id]
			if (npc.y < data.targetY) and (data.verticalDirection == 1) and (not data.swinging) then
				npc.speedY = cfg.dropspeed; -- constant speed
			elseif data.swinging then
				-- transform logic
				
				if cfg.hangtime > -1 then
					if (cfg.hangtime == 0) or ((data.transformCountdown) and (data.transformCountdown == 0)) then
						-- transform into walking scuttlebug and create abandonned string
					
						abandonnedString(npc, cfg);
					
						npc:transform(cfg.spawnid, true);
						
						return;
					else
						-- timer
					
						if data.transformCountdown == nil then
							data.transformCountdown = cfg.hangtime;
						end
						
						data.transformCountdown = data.transformCountdown - 1;
					end
				end
			
				-- vertical oscillations
			
				npc.speedY = -cfg.hangspeed*(math.sin(math.pi*data.oscillationCounter/cfg.hangheight));
				
				data.oscillationCounter = data.oscillationCounter + 1;
			end
			
			if npc.y >= data.targetY then
				-- don't let the NPC pass its target y-position
			
				npc.y = data.targetY;
				data.verticalDirection = -1;
				
				data.swinging = true; -- starts swinging if not already started
			end
		end
	else
		-- holds the NPC at its top point while offscreen
		npc.y = data.topY or npc.y;
		data.dropping = false;
		data.swinging = false;
	end

	if npc:mem(0x138, FIELD_WORD) == 5 and not data.lostString then
		abandonnedString(npc, NPC.config[npc.id])
		data.lostString = true
	end

	-- move while in a layer
	
	local layer = data.layer;
	
	if layer and not layer:isPaused() then
		npc.x = npc.x + layer.speedX;
		npc.y = npc.y + layer.speedY;
		data.topY = data.topY + layer.speedY;
	end
end

-- draw logic for hanging scuttlebug strings
function scuttlebug.onDrawHangingNPC(npc)
	local data = npc.data._basegame;
	
	if (not npc.isHidden) and (npc:mem(0x124, FIELD_BOOL)) and ((data.dropping) or (data.swinging)) and npc:mem(0x138, FIELD_WORD) < 5 then
		-- draw strings only for visible NPCs
	
		local x, y2 = npc.x + npc.width/2, npc.y + npc.height/4;
		local y1 = data.topY;
		
		drawString(x, y1, y2, NPC.config[npc.id].stringpriority, NPC.config[npc.id].stringcolor);
	end
end

-- misc logic
function scuttlebug.onTick()
	-- create abandonned strings from frozen scuttlebugs

	-- NEEDS ONNPCIDCHANGE STAT!
	for _, iceblock in ipairs(NPC.get(263, Section.getActiveIndices())) do
		if idMap[iceblock.ai1] then
			local data = iceblock.data._basegame;

			if (data ~= nil) and (not data.lostString) then
				abandonnedString(iceblock, NPC.config[iceblock.ai1]);
				
				data.lostString = true;
			end
		end
	end

	-- logic performed on abandonned strings

	for i=#abandonnedStrings, 1, -1 do
		local str = abandonnedStrings[i]
		-- sync with moving layers and shrink
	
		str.x = str.x + str.layer.speedX;
		str.y1 = str.y1 + str.layer.speedY;
		str.y2 = str.y2 - str.speed + str.layer.speedY;
		
		if str.y2 <= str.y1 then
			table.remove(abandonnedStrings, i); -- remove retracted strings
		end
	end
end

-- draw logic for abandonned strings (killed or frozen scuttlebugs)
function scuttlebug.onDraw()
	for _, str in ipairs(abandonnedStrings) do
		drawString(str.x, str.y1, str.y2, str.priority, str.color);
	end
end

-- create a string object for the scuttlebug's string so that it can be drawn retracting upon death
function scuttlebug.onNPCKill(_, killedNPC, killReason)
	if idMap[killedNPC.id] and (killReason ~= HARM_TYPE_OFFSCREEN) then
		if not killedNPC.data._basegame.lostString then	
			abandonnedString(killedNPC, NPC.config[killedNPC.id]);
		end
	end
end

return scuttlebug