local sumobro = {}

local npcManager = require("npcManager")

local npcID = NPC_ID

npcManager.setNpcSettings({
	id = npcID,
	gfxoffsety = 2,
	gfxwidth = 60, 
	gfxheight = 48, 
	width = 20,
	height = 28,
	frames = 2,
	framespeed = 12,
	framestyle = 1,
	nofireball=1,
	noiceball=-1,
	harmlessgrab=true,
	noyoshi=1,
	jumphurt=1,
	nowaterphysics=true,
	spinjumpsafe = true,

	stomps=1,
	earthquake=5,
	stompframes = 3,
	spawnid = 361
})

npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_NPC,
		HARM_TYPE_HELD,
		HARM_TYPE_SWORD,
		HARM_TYPE_TAIL,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_FROMBELOW
	}, 
	{
		[HARM_TYPE_NPC]=180,
		[HARM_TYPE_HELD]=180,
		[HARM_TYPE_PROJECTILE_USED]=180,
		[HARM_TYPE_TAIL]=180,
		[HARM_TYPE_FROMBELOW]=180,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}
	}
);

function sumobro.onInitAPI()
	npcManager.registerEvent(npcID, sumobro, "onTickNPC")
	npcManager.registerEvent(npcID, sumobro, "onDrawNPC")
end

local timerLimits = {65, 5 * NPC.config[npcID].framespeed - 2, 55, 45, 40}

function sumobro.onTickNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data._basegame
	
	if v.isHidden or v:mem(0x12A, FIELD_WORD) <= 0 then
		data.timer = nil
		return
	end

	local cfg = NPC.config[v.id]

	if data.timer == nil then
		data.timer = 0
		data.state = 1
		data.timerLimit = timerLimits
		data.timerLimit[2] = 5 * cfg.framespeed - 2 --yknow... runtime changes
		data.wave = 1
	end
	
	if v.collidesBlockBottom then
		if v:mem(0x136, FIELD_BOOL) or math.abs(v.speedX) > 3 then
			v.speedX = 0
		end
		data.timer = data.timer + 1
	end
	
	local add = 0
	
	if v.direction == 1 then
		add = cfg.frames + cfg.stompframes
	end
	
	if data.timer > data.timerLimit[data.state] and v.collidesBlockBottom then --switch state
	
		data.state = (data.state % 5) + 1
		data.timer = 0
		v.speedX = 0
		
		if data.state == 2 then
			data.frame = cfg.frames + add
		elseif data.state == 3 then
			if cfg.earthquake > 0 then
				Defines.earthquake = math.min(Defines.earthquake + cfg.earthquake, math.max(cfg.earthquake, Defines.earthquake))
			end
			SFX.play(37)
			local l = NPC.spawn(cfg.spawnid, v.x + 0.5 * v.width, v.y + 0.5 * v.height, player.section, false, true)
			l.friendly = v.friendly
			l.layerName = "Spawned NPCs"
			if data.wave < cfg.stomps then
				data.state = 2
				data.timer = 0
				data.frame = cfg.frames + add
				data.wave = data.wave + 1
			else
				data.wave = 1
			end
		elseif data.state == 5 then
			v.direction = -v.direction
		end
		
	end
	
	if data.state == 1 or data.state == 4 then --state animation
		data.frame = 0 + add
	elseif data.state == 2 then
		if data.timer%cfg.framespeed == cfg.framespeed - 1 then
			data.frame = math.min(data.frame + 1, cfg.frames + cfg.stompframes + add - 1)
		end
	elseif data.state == 3 then
		data.frame = cfg.frames + add
	elseif data.state == 5 then
		if v.collidesBlockBottom then
			v.speedX = 0
			if data.timer%8 == 0 then
				v.speedX = 6 * v.direction
			end
		else
			v.speedX = 4 * v.direction
		end
		if data.timer%math.ceil(cfg.framespeed/3) == 0 then
			data.frame = data.frame - add
			data.frame = add + ((data.frame + 1) % (cfg.frames))
		end
	end
end

function sumobro.onDrawNPC(v)
	if Defines.levelFreeze
		or v.isHidden
		or v:mem(0x12A, FIELD_WORD) <= 0
		or not v.data._basegame.frame then return end
	
	v.animationTimer = 500
	
	v.animationFrame = v.data._basegame.frame
end

return sumobro