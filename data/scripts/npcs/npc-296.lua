local rng = require("rng")
local npcManager = require("npcManager")

local bonybeetle = {}

local npcID = NPC_ID

local bonybeetlesettings = {
	id = npcID,
	gfxheight = 32,
	gfxwidth = 32,
	width = 32,
	height = 32,
	frames = 12,
	framestyle = 0,
	jumphurt = 0,
	nofireball=1,
	noyoshi=1,
	speed = 1,
	luahandlesspeed=true
}
local configFile = npcManager.setNpcSettings(bonybeetlesettings)

npcManager.registerHarmTypes(npcID, 
	{
		HARM_TYPE_JUMP,
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_HELD,
		HARM_TYPE_NPC,
		HARM_TYPE_LAVA,
		HARM_TYPE_SWORD,
		HARM_TYPE_TAIL
	}, 
	{
		[HARM_TYPE_JUMP] = 160,
		[HARM_TYPE_FROMBELOW]=163,
		[HARM_TYPE_PROJECTILE_USED]=163,
		[HARM_TYPE_HELD]=163,
		[HARM_TYPE_NPC]=163,
		[HARM_TYPE_TAIL]=163,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}
	});

local frameMod = {}
local FR_WALK = 1
local FR_SPIKE = 2
local FR_COLLAPSE = 3

local collapseFrames = {}
local spikeFrames = {}
local walkFrames = {}

function bonybeetle.onInitAPI()
	npcManager.registerEvent(npcID, bonybeetle, "onTickEndNPC", "onTickEndBeetle")
	registerEvent(bonybeetle, "onNPCHarm", "onNPCHarm", false)
	registerEvent(bonybeetle, "onStart", "onStart", false)
end

local STATE_WALK = 1
local STATE_BOPPED = 2
local STATE_BEFORESPIKES = 3
local STATE_SPIKES = 4

local stateSwitch = {3,1,4,1}
local timerLimit = {352, 180, 56, 104}

local function chasePlayers(v)
	local p = Player.getNearest(v.x + 0.5 * v.width, v.y)
	local dir = -1
	if p.x + 0.5 * p.width > v.x + 0.5 * v.width then
		dir = 1
	end
	v.direction = dir
end

local function initialise(v)
	local data = v.data._basegame
	
	if v.direction == 0 then
		v.direction = 1
		if rng.randomInt(0,1) == 1 then
			v.direction = -1
		end
	end
	if v.friendly == false then
		if v.collidesBlockBottom then
			v.speedX = 0
		end
	else
		v.speedX = NPC.config[v.id].speed * v.direction;
	end
	if v.collidesBlockBottom then
		data.state = STATE_BEFORESPIKES
	else
		data.state = STATE_WALK
	end
	data.timer = timerLimit[data.state]
	data.vanillaFriendly = v.friendly
end

function bonybeetle.onStart()
	local frames = NPC.config[npcID].frames
	frameMod = {(frames - 8) * 0.5,2,2}
	collapseFrames = {
		[-1] = frames - 4,
		[0] = frames - 4,
		[1] = frames - 2
	}
	spikeFrames = {
		[-1] = frames - 8,
		[0] = frames - 8,
		[1] = frames - 6
	}
	
	walkFrames = {
		[-1] = 0,
		[0] = 0,
		[1] = math.floor((frames - 8) * 0.5)
	}
end

function bonybeetle.onTickEndBeetle(v)
	if Defines.levelFreeze then return end
	
	local data = v.data._basegame
	
	if v.isHidden or v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x124, FIELD_WORD) == 0 then
		if data.vanillaFriendly == nil then
			data.vanillaFriendly = v.friendly
		end
		v.friendly = data.vanillaFriendly
		data.state = nil;
		return
	end
	
	if(v:mem(0x12C, FIELD_WORD) ~= 0 or v:mem(0x12E, FIELD_WORD) ~= 0 or v:mem(0x132, FIELD_WORD) ~= 0 or v:mem(0x138, FIELD_WORD)> 0) then
		data.state = STATE_WALK;
		data.timer = timerLimit[data.state];
	end
	
	if data.state == nil then
		initialise(v)
	end
	
	if data.timer > 0 then
		if not data.vanillaFriendly then
			data.timer = data.timer - 1
		end
	else
		data.state = stateSwitch[data.state]
		data.timer = timerLimit[data.state]
		
		--bopped state switch handled in onNPCKill
		if not data.vanillaFriendly then
			v.friendly = false
		end
		if not (data.state == STATE_SPIKES) then
			chasePlayers(v)
		end
	end

									
	local fs = configFile.framespeed or 8
	
	if data.state == STATE_WALK then
		
		if data.timer % 128 == 0 then
			chasePlayers(v)
		end
		local cap = NPC.config[v.id].speed
		if math.abs(v.speedX) > cap then
			v.speedX = v.speedX * 0.98
		else
			v.speedX = v.direction * cap
		end
		v.animationFrame = v.animationFrame % frameMod[FR_WALK] + walkFrames[v.direction] 
		
	elseif data.state == STATE_BOPPED then
		v.speedX = 0
		v.animationTimer = 0
		v.animationFrame = collapseFrames[v.direction]
		
		if data.timer > fs and data.timer < timerLimit[data.state] - fs then
			v.animationFrame = v.animationFrame + 1
			--butt shake
			if data.timer < fs * 5 then
				if data.timer%4 > 0 and data.timer%4 < 3 then
					v.x = v.x + 2
				else
					v.x = v.x - 2
				end
			end
		end
		
	elseif data.state == STATE_BEFORESPIKES then
		v.speedX = 0
		v.animationTimer = 0
		v.animationFrame = walkFrames[v.direction]
	else
		v.speedX = 0
		
		v.animationTimer = 0
		v.animationFrame = spikeFrames[v.direction]
		if data.timer > fs and data.timer < timerLimit[data.state] - fs then
			v.animationFrame = v.animationFrame + 1
		end
	end
end

function bonybeetle.onNPCHarm(eventObj,v,killReason, culprit)
	if v.id ~= npcID then return end
	
	if not v.data._basegame then v.data._basegame = {} end
	
	local data = v.data._basegame
	if killReason == 1 or killReason == 8 then
		eventObj.cancelled = true;
		if data.state == STATE_SPIKES then
			if culprit then
				culprit:harm()
			end
		else
			SFX.play(57)
			data.state = STATE_BOPPED
			data.timer = timerLimit[data.state]
			if not data.vanillaFriendly then
				v.friendly = true
			end
		end
	end
	
	if killReason == 10 then
		eventObj.cancelled = true
		SFX.play(57)
		data.state = STATE_BOPPED
		data.timer = timerLimit[data.state]
		if not data.vanillaFriendly then
			v.friendly = true
		end
	end
end

return bonybeetle;
