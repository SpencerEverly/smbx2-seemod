local npcManager = require("npcManager")
local colliders = require("colliders")
local vectr = require("vectr")
local whistle = require("npcs/ai/whistle")

local asteron = {}
local npcID = NPC_ID;

--***************************************************************************************************
--                                                                                                  *
--              DEFAULTS AND NPC CONFIGURATION                                                      *
--                                                                                                  *
--***************************************************************************************************

local asteronSettings = {
	id = npcID, 
	gfxwidth = 64, 
	gfxheight = 56, 
	width = 64, 
	height = 56, 
	frames = 1,
	framespeed = 8, 
	framestyle = 0,
	score = 0,
	nogravity = 1,
	jumphurt = 1,
	speed = .85,
	nowaterphysics = 1,
	spinjumpsafe = 1,
	nogravity = -1, 
	noiceball=-1,
	nofireball=-1,
	noyoshi=-1,
	noblockcollision=-1,
	-- Custom
	searchradius = 160,
	warningtime = 75,
	spikexspeeds = {0, -5.5, 5.5, -4.5, 4.5},
	spikeyspeeds = {-6, -1, -1, 6, 6},
	spikeid = 500
}

local configFile = npcManager.setNpcSettings(asteronSettings)

npcManager.registerHarmTypes(npcID, 	
{
	HARM_TYPE_NPC,
	HARM_TYPE_PROJECTILE_USED,
	HARM_TYPE_HELD,
	HARM_TYPE_SWORD,
}, 
{
	[HARM_TYPE_NPC]=223,
	[HARM_TYPE_PROJECTILE_USED]=223,
	[HARM_TYPE_HELD]=223,
	[HARM_TYPE_SWORD]=223
});

asteron.warnSound = Misc.resolveSoundFile("sonic-beep")
asteron.breakSound = Misc.resolveSoundFile("sonic-break")

-- ready set go
function asteron.onInitAPI()
	npcManager.registerEvent(npcID, asteron, "onTickEndNPC")
end

--***************************************************************************************************
--                                                                                                  *
--              BEHAVIOR                                                                            *
--                                                                                                  *
--***************************************************************************************************

function asteron.onTickEndNPC(v)
	if Defines.levelFreeze then return end

	local data = v.data._basegame

	if v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x138, FIELD_WORD) > 0 or v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x136, FIELD_BOOL) then
		data.exists = nil
		return
	end
	
	-- setup
	if data.exists == nil then
		data.exists = true;
		data.targetX = 0;
		data.targetY = 0;
		data.forceFrame = 0;

		if data.detectCollider then return end

		data.detectCollider = colliders.Box(v.x - configFile.searchradius, v.y - configFile.searchradius, 2 * configFile.searchradius + v.width, 2 * configFile.searchradius + v.height);
	end

	-- Detect if player is nearby
	if v.ai1 == 0 then
		local p = Player.getNearest(v.x, v.y)
		if colliders.collide(data.detectCollider,p) or whistle.getActive() then
			v.ai1 = 1;
			data.forceFrame = 1;

			local dirVector = vectr.v2(p.x + (0.5 * p.width) - (v.x + 0.5 * v.width), 
						p.y + (0.5 * p.height) - (v.y + 0.5 * v.height))
						
			dirVector = dirVector:normalize()
			dirVector = dirVector * configFile.speed;
			if not v.dontMove then
				v.speedX = dirVector.x
				v.speedY = dirVector.y
			end
			SFX.play(asteron.warnSound)
		end
	end
	
	-- Destroy timer
	if v.ai1 > 0 then
		v.ai1 = v.ai1 + 1;
		
		if v.ai1 >= configFile.warningtime then
			v:kill(HARM_TYPE_FROMBELOW)
			SFX.play(asteron.breakSound)
			for i=1, 5 do
				local mySpike = NPC.spawn(configFile.spikeid, v.x + (0.5 * v.width), v.y + (0.5 * v.height), player.section, false, true)
				mySpike.ai1 = i - 1
				mySpike.speedX = configFile.spikexspeeds[i] or 0
				mySpike.speedY = configFile.spikeyspeeds[i] or 0
				mySpike.friendly = v.friendly
				mySpike.layerName = "Spawned NPCs"
			end
		end
	end
		
	-- make sure collider is attached
	data.detectCollider.x = v.x - configFile.searchradius;
	data.detectCollider.y = v.y - configFile.searchradius;
	
	v.animationFrame = (math.floor(v.ai1 / 2) % 2);
end

return asteron;