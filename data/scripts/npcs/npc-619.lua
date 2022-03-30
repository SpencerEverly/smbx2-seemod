-- CRATE NPCs - Spawn Objects -----------------------------------------------------------------------------------------
-- Creator: Ohmato
-----------------------------------------------------------------------------------------------------------------------
local npcManager = require("npcManager");
local rng = require("rng");
local npcutils = require("npcs/npcutils")

local crate_spawnobj = {};

local npcID = NPC_ID



function crate_spawnobj.onInitAPI()
	registerEvent(crate_spawnobj, "onNPCKill", "onNPCKill", false)
end
npcManager.registerEvent(npcID, crate_spawnobj, "onTickNPC")
npcManager.registerEvent(npcID, crate_spawnobj, "onDrawNPC")
npcManager.setNpcSettings({
	id = npcID,
	gfxoffsetx        = 0,
	gfxoffsety        = 0,
	width             = 32,
	height            = 32,
	gfxwidth          = 32,
	gfxheight         = 32,
	speed             = 1,
	isshell           = 0,
	npcblock          = 0,
	npcblocktop       = 0,
	isinteractable    = 0,
	iscoin            = 0,
	isvine            = 0,
	iscollectablegoal = 0,
	isflying          = 0,
	iswaternpc        = 0,
	jumphurt          = 1,
	noblockcollision  = 0,
	score             = 0,
	playerblocktop    = 0,
	grabtop           = 0,
	cliffturn         = 0,
	nohurt            = 1,
	playerblock       = 0,
	grabside          = 0,
	isshoe            = 0,
	isyoshi           = 0,
	noyoshi           = 1,
	foreground        = 0,
	isbot             = 0,
	isvegetable       = 0,
	nofireball        = 1,
	noiceball         = 1,
	nogravity         = 0,
	frames            = 0,
	framespeed        = 0,
	framestyle        = 0,
	iswalker          = 0,
	harmlessthrown	  = 1,
	ignorethrownnpcs  = 1,
});


-- // -----------------------------------------------------------------------------------------------------------------
-- NPC IDs for special cases
local ID_HERB =				91;
local ID_BLARGG =			199;
local ID_FIREBAR =			260;
local ID_BOO =				43;
local ID_BOO_CIRCLE =		294;
local ID_MUTANTVINE =		552;
local ID_MUTANTVINE_THORN =	554;

local OFFSET_HERB = 16;			-- Graphical offset to draw herb container
local OFFSET_BLARGG = 96;		-- Blargg needs to be moved into the ground the first time it spawns
local OFFSET_MUTANTVINE = 8;	-- The amount of space that should be added between mutant vine tiles in a stack
-- // -----------------------------------------------------------------------------------------------------------------





-- // -----------------------------------------------------------------------------------------------------------------
local FRICTION = 0.10;			-- Friction when sliding on ground
local EPS_SPEEDX = 0.02;		-- Minimum horizontal speed under friction before snapping to 0
local AIR_RESIST = 0.05;		-- Air resistance for floating spawn objects
local DEF_LIFE_MAX = 90;		-- Total frames spent on the ground before releasing child
local LIFE_CRITFRAC = 0.5;		-- Percentage of maximum life where blinking gets faster
local BLINK_FRAMES = 5;			-- Frames spent before changing opacity (creates blinking effect)
local BLINK_CRITFRAMES = 2;		-- Blink frames when at critical life
local OPAQ_HIGH = 0.7;			-- High opacity level for blinking state
local OPAQ_LOW = 0.3;			-- Low opacity level for blinking state


function crate_spawnobj.onTickNPC(obj)
	if Defines.levelFreeze then return end
	if obj.isValid then
		local objdata = obj.data._basegame;
		
		-- Reduce timers
		if objdata.initialized then
			-- Tick down if the object touches the ground, hits water, or floats in the air
			if obj.collidesBlockBottom or obj.underwater or objdata.floaty then objdata.aging = true; end
			-- Do not tick down if time is stopped
			if not Defines.levelFreeze then
				if objdata.aging then objdata.life = objdata.life - 1; end
				objdata.blinker = objdata.blinker - 1;
			end
			
			-- Terminate if time is up
			if objdata.life <= 0 then obj:kill(9); end
			
			-- Reset blinker
			if objdata.blinker <= 0 then
				objdata.blinker = BLINK_FRAMES;
				-- Blink faster if below critical age
				if objdata.life <= objdata.maxlife*LIFE_CRITFRAC then objdata.blinker = BLINK_CRITFRAMES; end					
				-- Toggle between high and low opacity levels
				objdata.opaq = not objdata.opaq;
			end
			
			-- Keep from despawning
			obj:mem(0x12A, FIELD_WORD, 180);
		else
			-- Check if invincibility phase duration is set
			objdata.maxlife = DEF_LIFE_MAX;
			if objdata.npcdata and objdata.npcdata.delay then
				objdata.maxlife = objdata.npcdata.delay;
			end
			if objdata.maxlife <= 0 then obj:kill(9); end;
			
			-- Initialize life and blinker timers
			objdata.life = objdata.maxlife;
			objdata.blinker = BLINK_FRAMES;
			objdata.opaq = true;			-- Opacity level to use for blinking state
			objdata.aging = false;			-- Should the life timer tick down?
			objdata.initialized = true;		-- All variables initialized
		end
		
		-- Physics
		if not Defines.levelFreeze then
			-- Apply friction if sliding on ground
			if obj.collidesBlockBottom then
				obj.speedX = obj.speedX - FRICTION*obj.speedX;
				if math.abs(obj.speedX) < EPS_SPEEDX then obj.speedX = 0; end
				
				-- Comes to a stop underwater, for some reason it keeps sliding if you don't do this
				if obj.underwater then obj.dontMove = true; end
			end
			
			-- Suspend spawn objects in the air if they should float
			if objdata.floaty then
				obj.speedX = obj.speedX - AIR_RESIST*obj.speedX
				if math.abs(obj.speedX) < Defines.npc_grav then obj.speedX = 0; end
				obj.speedY = obj.speedY - AIR_RESIST*obj.speedY
				obj.speedY = obj.speedY - Defines.npc_grav;
				if math.abs(obj.speedY) < Defines.npc_grav then obj.speedY = -Defines.npc_grav; end
			end
		end
	
	end
end
-- // -----------------------------------------------------------------------------------------------------------------







-- // -----------------------------------------------------------------------------------------------------------------
function crate_spawnobj.onNPCKill(eventObj, npc, killReason)
	-- Check for death of spawn object
	if npc.id == npcID then
		local obj = npc;
		if obj.isValid then
			local objdata = obj.data._basegame;
			
			-- Get config table for contained NPC
			local myNpc = objdata.npcdata;
			if myNpc and myNpc.id > 0 then
				
				-- Spawn contained entity
				local child = NPC.spawn(
					myNpc.id,
					obj.x, obj.y,
					npc:mem(0x146, FIELD_WORD), myNpc.respawn or false, false);
				child:mem(0x124, FIELD_BOOL, true);		-- Respawned, but onscreen (must be true for new NPCs)
				-- Set spawn direction
				child.direction = myNpc.direction or obj.direction;
				if child.direction == 0 then child.direction = rng.irandomEntry({-1,1}); end
				child:mem(0xD8, FIELD_FLOAT, child.direction);
				-- Set speed if the intangibility phase is skipped
				if myNpc.delay and myNpc.delay <= 0 then
					child.speedX = obj.speedX;
					child.speedY = obj.speedY;
				end
				-- Dust cloud
				Animation.spawn(10, obj.x + obj.width/2 - 16, obj.y + obj.height/2 - 16);
				
				
				
				-- Alter NPC fields as specified
				child.ai1 = myNpc.ai1 or child.ai1;
				child.ai2 = myNpc.ai2 or child.ai2;
				child.ai3 = myNpc.ai3 or child.ai3;
				child.ai4 = myNpc.ai4 or child.ai4;
				child.ai5 = myNpc.ai5 or child.ai5;
				
				child.friendly = myNpc.friendly or child.friendly;
				child.dontMove = myNpc.dontMove or child.dontMove;
				child.msg = myNpc.msg or child.msg;
				
				child.noMoreObjInLayer = myNpc.noMoreObjInLayer or child.noMoreObjInLayer;
				child.deathEventName = myNpc.deathEventName or child.deathEventName;
				child.talkEventName = myNpc.talkEventName or child.talkEventName;
				child.layerName = myNpc.layerName or "Spawned NPCs";
				
				
				
				-- // SPECIAL CASES -----------------------------------------------------------------------------------
				-- Special case for herb containers (91), push it into the ground
				if myNpc.id == ID_HERB then
					child.y = child.y + OFFSET_HERB;
					child:mem(0xB0, FIELD_DFLOAT, child.y);
				end
				-- Special case for mutant vines (552/554), space them out to connect appropriately
				if myNpc.id == ID_MUTANTVINE or myNpc.id == ID_MUTANTVINE_THORN then
					if objdata.stackpos ~= 0 then child.y = child.y - objdata.stackdir*OFFSET_MUTANTVINE; end
				end
				-- Special case for firebars (260), must have field 0xDE equal to 'ai1' field
				if myNpc.id == ID_FIREBAR then
					-- Increase distance from center depending on position in stack
					child.ai1 = child.ai1 + objdata.stackdir*objdata.stackpos;
					child:mem(0xDE, FIELD_WORD, child.ai1);
				end
				-- Special case for Blarggs (199), must be pushed into the ground the first time it spawns
				if myNpc.id == ID_BLARGG then child.y = child.y + OFFSET_BLARGG; end
				-- // -------------------------------------------------------------------------------------------------
				
				
				
				-- If in a stack, spawn a copy of itself above or below (depending on stack direction)
				if myNpc.stack and objdata.stackpos / myNpc.stack < 1 then
					local nextObj = NPC.spawn(
						npcID,
						child.x,
						child.y - objdata.stackdir*child.height,
						player.section, false, false);
					nextObj:mem(0x124, FIELD_BOOL, true);	-- Respawned, but onscreen (must be true for new NPCs)
					
					-- Initialize
					if nextObj.isValid then
						nextObjdata = nextObj.data._basegame;
						
						-- Decrement stack
						nextObjdata.stackpos = objdata.stackpos + objdata.stackdir;
						nextObjdata.stackdir = objdata.stackdir;
						
						-- Copy over NPC data to the next spawn
						nextObjdata.npcdata = myNpc;
						
						-- Configure dimensions
						nextObj.width = NPC.config[myNpc.id].width;
						nextObj.height = NPC.config[myNpc.id].height;
						
						-- Set to spawn on the next frame
						nextObjdata.life = 1;
						nextObjdata.blinker = BLINK_FRAMES;
						nextObjdata.opaq = true;
						nextObjdata.aging = true;
						nextObjdata.initialized = true;
						
					end
				end
				
			end
		end
	end
end
-- // -----------------------------------------------------------------------------------------------------------------






-- // -----------------------------------------------------------------------------------------------------------------
function crate_spawnobj.onDrawNPC(obj)
	if obj.isValid then
		local objdata = obj.data._basegame;
			
		-- Render contained NPC
		if objdata.npcdata and objdata.npcdata.id then
			local npcid = objdata.npcdata.id;
			
			
			-- // SPECIAL CASE: Change image ID for Boo circle to regular Boo
			if npcid == ID_BOO_CIRCLE then npcid = ID_BOO; end
			
			
			-- Get gfx dimensions
			local gfxwidth = NPC.config[npcid].gfxwidth;
			if gfxwidth == 0 then gfxwidth = obj.width; end
			local gfxheight = NPC.config[npcid].gfxheight;
			if gfxheight == 0 then gfxheight = obj.height; end
			-- Get gfxoffsets
			local gfxoffsetx = NPC.config[npcid].gfxoffsetx - (gfxwidth - obj.width)/2;
			local gfxoffsety = NPC.config[npcid].gfxoffsety - (gfxheight - obj.height);
			
			
			-- // SPECIAL CASE: Add additional offset for herb containers ---------------
			if npcid == ID_HERB then gfxoffsety = gfxoffsety + OFFSET_HERB; end
			
			
			-- Set opacity
			local opacitylvl = OPAQ_LOW;
			if objdata.opaq then opacitylvl = OPAQ_HIGH; end
			-- Render priority
			local renderPriority = -45;
			if NPC.config[npcid].foreground then renderPriority = -15; end
			
			
			-- Render frame
			Graphics.draw {
				x = obj.x + gfxoffsetx,
				y = obj.y + gfxoffsety,
				type = RTYPE_IMAGE,
				isSceneCoordinates = true,
				priority = renderPriority,
				
				image = Graphics.sprites.npc[npcid].img,
				sourceWidth = gfxwidth,
				sourceHeight = gfxheight,
				opacity = opacitylvl,
			}
		end
	end
end
-- // -----------------------------------------------------------------------------------------------------------------



return crate_spawnobj;