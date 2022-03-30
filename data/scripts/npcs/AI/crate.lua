-- CRATE NPCs ---------------------------------------------------------------------------------------------------------
-- Creator: Ohmato
-----------------------------------------------------------------------------------------------------------------------
-- KNOWN SPAWN BEHAVIOR: ----------------------------------------------------------------------------------------------
-- Vine heads (225/226) crash SMBX on spawn (caused by lineNPCs.lua)
-- Stretcher boos (323/324) crash due to nil 'stretchTimer'/'stretchState' properties
-- Checkpoint flags (430) crash due to nil 'checkpoint' property (NPC.spawn issue)
-- NPCs are spawned after onTickNPC has occurred and before onDrawNPC, so some values are not set? See todo list.

-- TODO: --------------------------------------------------------------------------------------------------------------
-- Frame drawn by spawn objects does not match respective direction of contained NPC
-- Clean up/streamline stack spawn algorithm in crate_spawnobj.lua
-- Maybe create spawn queue system so NPCs are spawned on the next frame before the main tick


-- CRATE CONFIG FLAGS: ------------------------------------------------------------------------------------------------
-- explosive			If TRUE, crate creates an explosion on impact. Defaults to FALSE.

-- CONTENT CONFIG FLAGS: ----------------------------------------------------------------------------------------------
-- id					ID of contained NPC. REQUIRED.
-- count				Number of NPCs of specified ID to spawn. Defaults to 1.
-- ai1,...,ai5			Respective AI field of spawned NPC.
-- friendly				.friendly field of spawned NPC.
-- dontMove				.dontMove field of spawned NPC.
-- msg					Message text of spawned NPC.
-- noMoreObjInLayer		Names of respective events.
-- deathEventName			|
-- talkEventName			|
-- layerName				V
-- stack				Spawns additional NPCs in a stack above/below the original. Can be positive or negative. Useful for ladders and Pokeys.
-- respawn				Should the NPC respawn if moved offscreen? Defaults to FALSE;
-- direction			Direction the NPC faces after spawning.
-- speed				Magnitude of NPC velocity upon ejection from crate.
-- angle				Angle of NPC velocity upon ejection from crate.
-- delay				Invincibility frames of NPC before physically spawning. Defaults to 60.
-- floaty				Causes the NPC to ignore gravity during its delay phase. Defaults to FALSE.
-----------------------------------------------------------------------------------------------------------------------

local npcManager = require("npcManager");
local rng = require("rng");

local crates = {};

local defaultCrateConfig = {
	gfxoffsetx=0,
	gfxoffsety=0,
	gfxwidth=48,
	gfxheight=48,
	foreground=0,
	width=48,
	height=48,
	score=0,
	playerblock=0,
	playerblocktop=1,
	npcblock=0,
	npcblocktop=1,
	grabside=1,
	grabtop=1,
	jumphurt=0,
	nohurt=1,
	speed=1,
	noblockcollision=0,
	cliffturn=0,
	noyoshi=0,
	nofireball=1,
	nogravity=0,
	noiceball=1,
	frames=1,
	framespeed=8,
	framestyle=0,
	nohammer=1,
    noshell=1,
    harmlessgrab = true,
    
    explosive = false,
}

local crateIDs = {}
local crateIDMap = {}

function crates.register(id, config)
    table.insert(crateIDs, id)
    crateIDMap[id] = true
    npcManager.registerEvent(id, crates, "onTickNPC")

    npcManager.setNpcSettings(table.join(config, defaultCrateConfig))
end

function crates.onInitAPI()
	registerEvent(crates, "onTickEnd", "onTickEnd", false)
	registerEvent(crates, "onNPCHarm", "onNPCHarm", false)
end




-- Visual/audio effects -----------------------------------------------------------------------------------------------
local sfx = Misc.resolveSoundFile("crate_break")			-- SFX for when crate breaks
local impactZones = {};								-- Places where crates have broken, used to spawn visual effects
local DUST_CLOUD_COUNT = 6;							-- Number of dust clouds to spawn when a crate breaks

local function CreateImpactZone(center, r, bomb)	-- Tracks area of impact, computes positions to spawn effects
	if DUST_CLOUD_COUNT > 0 then
		-- Record area of impact
		impactZones[#impactZones + 1] = {
			gfxSpawnTimer = DUST_CLOUD_COUNT,
			gfxSpawnPos = {},
			expired = false,
			explode = bomb
		};
		
		-- Generate positions to spawn dust cloud animations
		local anglePhase = rng.random(360);
		local angleSpacing = 360 / (DUST_CLOUD_COUNT-1);
		for i = 1, DUST_CLOUD_COUNT-1 do
			-- Calculate vector dividing circular area where dust clouds will be spawned
			local angle = i*angleSpacing + anglePhase + rng.random(-angleSpacing/4, angleSpacing/4);
			impactZones[#impactZones].gfxSpawnPos[i] = vector.up2 * rng.random(r/2, r);
			impactZones[#impactZones].gfxSpawnPos[i] = center + impactZones[#impactZones].gfxSpawnPos[i]:rotate(angle);
		end
		impactZones[#impactZones].gfxSpawnPos[DUST_CLOUD_COUNT] = center;
		
		-- Shuffle positions
		local n = DUST_CLOUD_COUNT;
		local t, k;
		while n > 0 do
			t = impactZones[#impactZones].gfxSpawnPos[n];
			k = rng.randomInt(1, n);
			impactZones[#impactZones].gfxSpawnPos[n] = impactZones[#impactZones].gfxSpawnPos[k];
			impactZones[#impactZones].gfxSpawnPos[k] = t;
			n = n - 1;
        end
        
        Effect.spawn(239, center.x, center.y)
	end
end
local function SpawnGFX()							-- Spawns explosion/dust cloud effects where a crate breaks
	-- Manage table of areas of impact
	for i, zone in ipairs(impactZones) do
		-- Remove expired zones
		if zone.expired then table.remove(impactZones, i);
		else
			-- Spawn dust clouds at existing zones of impact
			local pos = zone.gfxSpawnPos[zone.gfxSpawnTimer];
			Animation.spawn(10, pos.x - 16, pos.y - 16);
			zone.gfxSpawnTimer = zone.gfxSpawnTimer - 1;
			if zone.gfxSpawnTimer == 0 then zone.expired = true; end
			
			-- If the crate is explosive, make an explosion
			if zone.explode then
				local c = zone.gfxSpawnPos[DUST_CLOUD_COUNT];
				Explosion.spawn(c.x, c.y, 2);
				zone.explode = false;
			end
		end
	end
end

function crates.onTickEnd()
    if Defines.levelFreeze then return end
    if #impactZones > 0 then
        SpawnGFX()
    end
end
-----------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------




-- Initialization/physics ---------------------------------------------------------------------------------------------
local MINIMUM_IMPACT = 9;					-- Minimum acceleration required to shatter crate
local FRICTION = 0.12;						-- Friction of crate when sliding on ground
local DEF_EJECTSPEED = 4.5;					-- Maximum momentum of NPCs upon being spawned from the crate

function crates.onTickNPC(crate)
	-- Crate logic
	if crate.isValid then
		local cratedata = crate.data._basegame;
		local settings = crate.data._settings;
	
		-- Initialization
        if not cratedata.init then
            if settings.contents and type(settings.contents) == "string" and settings.contents ~= "" then
                local f, errorStr = loadstring ([[return {]]..settings.contents.."}");

                -- Does the parsed table return any errors?
                if  f == nil  then
                    error("Couldn't parse crate content table.")
                end
                settings.contents = f()
            end
			-- Physics
			cratedata.vel = vector.v2(crate.speedX, crate.speedY);	-- Velocity vector
			cratedata.accel = vector.v2(0, 0);						-- Acceleration vector
			cratedata.static = crate.dontMove;
			
			cratedata.init = true;
		end
		
		-- Is the crate being held?
		cratedata.grabbed = (crate:mem(0x12c, FIELD_WORD) ~= 0);
		-- Is it on the ground and not being held?
		cratedata.grounded = crate.collidesBlockBottom and not cratedata.grabbed;
		-- Grab timer, starts at 30 then counts down to 0 when released
		cratedata.grabTimer = crate:mem(0x12e, FIELD_WORD);
		
		-- Physics
		if not Defines.levelFreeze then
			-- Apply friction if sliding on ground
			if cratedata.grounded then
				crate.speedX = crate.speedX - FRICTION*crate.speedX;
				if math.abs(crate.speedX) < 0.02 then crate.speedX = 0; end
				
				-- Prevent sliding underwater
				if crate.underwater then crate.dontMove = true;
				else crate.dontMove = cratedata.static; end
			end
			
			if not crate.friendly then
				-- Calculate change in velocity across frame
				local newvel = vector.v2(crate.speedX, crate.speedY);
				cratedata.accel = cratedata.vel - newvel;
				cratedata.vel = newvel;
				
				-- Destroy crate on sufficient impact
				if math.abs(cratedata.accel.length) > MINIMUM_IMPACT and cratedata.grabTimer == 0 then crate:harm(); end
			end
		end
		
	end
end
-----------------------------------------------------------------------------------------------------------------------




-- Spawning NPCs from crates ------------------------------------------------------------------------------------------
function crates.onNPCHarm(eventObj, npc, harmType, culprit)
	if crateIDMap[npc.id] then
		local crate = npc
		if crate.isValid and not crate.friendly then
			local cratedata = crate.data._basegame;
		
			-- Check if the culprit, if an NPC, is not an explosion
			local validHarm = true;
			if harmType == HARM_TYPE_NPC and culprit then
				if culprit.id ~= 0 then
					eventObj.cancelled = true;
					validHarm = false;
				end;
			end
			
			-- Cancel momentum and prevent clipping on contact with lava
			if harmType == HARM_TYPE_LAVA then
				crate.y = crate.y - cratedata.vel.y;
				cratedata.vel = vector.zero2;
			end
			
			if validHarm then
				-- Centerpoint of crate
				local center = vector.v2(crate.x + crate.width/2, crate.y + crate.height/2)		
				-- Record area of impact
				CreateImpactZone(center, crate.width * 2/3, NPC.config[crate.id].explosive);
				-- Play sound effect
				SFX.play(sfx)
				
				
			local settings = crate.data._settings;
				
				-- Spawn contents
                if settings.contents and type(settings.contents) ~= "string" then
					for _, myNpc in ipairs(settings.contents) do
					
						-- Check for shortcut notation, only continue if ID is specified
						if type(myNpc) == "number" then myNpc = {id = myNpc}; end
						if myNpc.id then
							for i = 1, (myNpc.count or 1) do
								
								-- Spawn NPC
								local obj = NPC.spawn(
									619,
									crate.x + crate.width/2,
									crate.y + crate.height - 4,
									player.section, false, false);
								obj:mem(0x124, FIELD_BOOL, true);	-- Respawned, but onscreen (must be true for new NPCs)
								obj:mem(0x136, FIELD_BOOL, true);	-- Thrown state
								obj.layerName = "Spawned NPCs";
								
								-- Configure container dimensions and reposition
								obj.width = NPC.config[myNpc.id].width;
								obj.height = NPC.config[myNpc.id].height;
								obj.x = obj.x - obj.width/2;
								obj.y = obj.y - obj.height;
								
								
								
								-- Box-Muller transform to compute exit momentum
								local u1, u2 = rng.random(), rng.random();
								local r = math.sqrt(-2*math.log(u1)) / 3 * DEF_EJECTSPEED;
								local theta = 2*math.pi*u2;
								
								-- Give the crate a speed if you hit it with your tail
								if harmType == HARM_TYPE_TAIL or harmType == HARM_TYPE_SWORD then
									cratedata.vel = vector.up2:rotate(180 + player.direction*45) * DEF_EJECTSPEED * 1.1;
								end
								
								-- Velocity vector of NPCs as they are spawned from the crate
								local exitvel = cratedata.vel + vector.v2(r * math.cos(theta), r * math.sin(theta));
								
								-- Check if the speed of exiting NPCs is defined
								if myNpc.speed then exitvel = myNpc.speed * exitvel:normalize(); end
								-- Check if the angle of the exit velocity is defined
								if myNpc.angle then exitvel = vector.up2:rotate(180 + myNpc.angle) * exitvel.length; end
								
								-- Set direction
								if exitvel.x < 0 then obj.direction = -1
								else obj.direction = 1; end
								obj.speedX = exitvel.x; obj.speedY = exitvel.y;
								
								
								
								-- Store NPC configuration
								local objdata = obj.data._basegame;
								objdata.npcdata = myNpc;
								objdata.floaty = (myNpc.floaty or false);
								objdata.stackpos = 0;
								if myNpc.stack then
									if myNpc.stack < 0 then objdata.stackdir = -1;
									else objdata.stackdir = 1; end
								end
								
							end
						end
						
					end
				end
			end
			
		end
	end
end
-----------------------------------------------------------------------------------------------------------------------




return crates;