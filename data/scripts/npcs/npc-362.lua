local fire = {}

local npcManager = require("npcManager")
local npcID = NPC_ID

npcManager.setNpcSettings({
	id = npcID,
	gfxoffsetx = 0,
	gfxoffsety = 0,
	gfxwidth = 32, 
	gfxheight = 64, 
	width = 32,
	height = 32,
	frames = 2,
	harmlessgrab=true,
	framespeed = 4,
	framestyle = 0,
	ignorethrownnpcs = true,
	nofireball=1,
	noiceball=-1,
	noyoshi=1,
	nogravity=-1,
	noblockcollision=true,
	spinjumpsafe = false,
	jumphurt = 1,
	lightradius=64,
	lightbrightness=1,
	lightcolor=Color.orange,

	spread=2,
	delay=20,
	top=7,
	ishot = true,
	durability = -1
})

function fire.onInitAPI()
	npcManager.registerEvent(npcID, fire, "onTickNPC")
	npcManager.registerEvent(npcID, fire, "onDrawNPC")
end

local function initFire(v, f, dir)
	f.data._basegame = {}
	f.data._basegame.dir = dir
	f.data._basegame.spread = v.data._basegame.spread - 1
	f.data._basegame.wasThrown = v.data._basegame.wasThrown or false
	if v.data._basegame.friendly ~= nil then
		f.friendly = v.data._basegame.friendly
	else
		f.friendly = v.friendly
	end
	f.layerName = "Spawned NPCs"
	return f
end

local function checkBlockValidity(v)
	if v.isHidden or (v:mem(0x5A, FIELD_WORD) ~= 0)
	or ((not Block.SOLID_MAP[v.id])
	  and (not Block.SEMISOLID_MAP[v.id])
	  and (not Block.PLAYER_MAP[v.id])
	  and (not Block.SIZEABLE_MAP[v.id])) then
		return false
	end
	return true
end

local function calculateBlock(v,direction)
	local founda = false
	local foundb = false
	if direction ~= -1 then
		local dontBother = false
		for k,v in ipairs(Block.getIntersecting(v.x + 2 * v.width - 2, v.y + v.height - 12, v.x + 2 * v.width - 1, v.y + v.height - 11)) do
			if (not v.isHidden) and (Block.SOLID_MAP[v.id] or Block.PLAYER_MAP[v.id]) then
				dontBother = true
				break
			end
		end
		if not dontBother then
			local blocks = Block.getIntersecting(v.x + 2 * v.width - 2, v.y + v.height + 2, v.x + 2 * v.width - 1, v.y + v.height + 3)
			for k,v in ipairs(blocks) do
				if checkBlockValidity(v)  then
					founda = true
					break
				end
			end
			
			if direction ~= nil and founda then
				return true
			end
		end
	end
	if direction ~= 1 then
		local dontBother = false
		for k,v in ipairs(Block.getIntersecting(v.x - v.width + 2, v.y + v.height - 12, v.x - v.width + 3, v.y + v.height - 11)) do
			if (not v.isHidden) and (Block.SOLID_MAP[v.id] or Block.PLAYER_MAP[v.id]) then
				dontBother = true
				break
			end
		end
		if not dontBother then
		
			local blocks = Block.getIntersecting(v.x - v.width + 2, v.y + v.height + 2, v.x - v.width + 3, v.y + v.height + 3)
			for k,v in ipairs(blocks) do
				if checkBlockValidity(v) then
					foundb = true
					break
				end
			end
			
			if direction ~= nil and foundb then
				return true
			end
		end
	end
	if direction == nil or direction == 0 then
		return founda, foundb
	end
end

function fire.onTickNPC(v)
	if Defines.levelFreeze
		or v.isHidden
		or v:mem(0x138, FIELD_WORD) > 0
		or v:mem(0x12A, FIELD_WORD) <= 0 then return end

	if v:mem(0x12C, FIELD_WORD) > 0
	or v:mem(0x136, FIELD_WORD) > 0
		then
			v:mem(0x12C, FIELD_WORD, 0)
			v:mem(0x136, FIELD_BOOL, false)
			v.speedX = 0
			v.speedY = 0
	end
	
	local data = v.data._basegame
	
	if data.timer == nil then
		data.timer = 0
		data.state = 1
		data.flipped = false
		data.friendly = v.friendly
		if data.wasThrown then
			data.friendly = true
		end
	end
	local cfg = NPC.config[v.id]
	if data.dir == nil then
		data.dir = 0
		data.friendly = v.friendly
		data.spread = cfg.spread
		if data.wasThrown then
			data.friendly = true
		end
	end
	
	v.friendly = true
	
	if data.state >= 2 then
		v.friendly = data.friendly
		if data.wasThrown then
			for k,n in ipairs(NPC.getIntersecting(v.x, v.y, v.x + v.width, v.y + v.height)) do
				if NPC.HITTABLE_MAP[n.id]
				and (not n.isHidden)
				and (not n.friendly)
				and n:mem(0x12A, FIELD_WORD) > 0
				and n:mem(0x64, FIELD_BOOL) == false
				and n:mem(0x12C, FIELD_WORD) == 0
				and n:mem(0x138, FIELD_WORD) == 0 then
					n:harm(HARM_TYPE_LAVA)
				end
			end
		end
	end
	
	data.timer = data.timer + 1
	
	if data.timer == cfg.delay and data.spread ~= 0 then
		if data.dir == 0 then
			if not cfg.noblockcollision then
				local r, l = calculateBlock(v)
				if l then
					local f = NPC.spawn(npcID, v.x - v.width, v.y, player.section)
					initFire(v, f, -1)
				end
				if r then
					local f = NPC.spawn(npcID, v.x + v.width, v.y, player.section)
					initFire(v, f, 1)
				end
			else
				local f = NPC.spawn(npcID, v.x - v.width, v.y, player.section)
				initFire(v, f, -1)
				local f = NPC.spawn(npcID, v.x + v.width, v.y, player.section)
				initFire(v, f, 1)
			end
		else
			if not cfg.noblockcollision then
				local that = calculateBlock(v, data.dir)
				if that then
					local f = NPC.spawn(npcID, v.x + v.width * data.dir, v.y, player.section)
					initFire(v, f, data.dir)
				end
			else
				local f = NPC.spawn(npcID, v.x + v.width * data.dir, v.y, player.section)
				initFire(v, f, data.dir)
			end
		end
	end
	
	if (data.state > 3 or data.flipped)
		and data.timer > (cfg.delay * 0.6 * cfg.top)
		and data.timer%(math.floor(cfg.delay * 0.6)) == 0 then
		
		data.flipped = true
		data.state = data.state - 1
	end
	
	if data.timer % (math.floor(cfg.delay * 0.6)) == 0
		and data.state < 4
		and data.flipped == false then
		
		data.state = data.state + 1
	end
	
	if data.state < -1 then
		v:kill(9)
	end
end

function fire.onDrawNPC(v)
	if v.isHidden
		or v:mem(0x12A, FIELD_WORD) <= 0
		or not v.data._basegame.state then return end
	
	local cfg = NPC.config[v.id]
	local data = v.data._basegame

	v.animationTimer = 500
	if data.timer then
		v.animationFrame = (math.floor(data.timer/cfg.framespeed)%cfg.frames) - cfg.frames + data.state * cfg.frames
	else
		v.animationFrame = 0
	end
end

return fire