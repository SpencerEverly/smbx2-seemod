local blert = {}
local npcManager = require("npcManager")

local blertID = {
                 normal = 490,
                 gol = 491
                }
local blertIDMap = {}

local killEffect = 10


-- Register properties, harm types, etc. for each blert type
local blertBase = {}
for  k,v in pairs(blertID)  do
	blertIDMap[v] = k

	blertBase[k] = {
		config = npcManager.setNpcSettings({
			id = v,
			gfxwidth = 36,
			gfxheight = 36,
			gfxoffsety = 0,
			width = 32,
			height = 32,
			frames = 6,
			framespeed = 8,
			framestyle = 0,
			score = 0,
			blocknpctop = 0,
			blocknpc = 0,
			playerblocktop = 0,
			playerblock = 0,
			nohurt = 0,
			nogravity = 1,
			noblockcollision = 1,
			jumphurt = 0
		})
	}

	npcManager.registerHarmTypes(
		v,
		{
			HARM_TYPE_JUMP,
			HARM_TYPE_FROMBELOW,
			HARM_TYPE_NPC,
			HARM_TYPE_HELD,
			HARM_TYPE_TAIL,
			HARM_TYPE_SPINJUMP,
			HARM_TYPE_SWORD,
			HARM_TYPE_LAVA
		},
		{
			[HARM_TYPE_JUMP]=10,
			[HARM_TYPE_FROMBELOW]=10,
			[HARM_TYPE_NPC]=10,
			[HARM_TYPE_HELD]=10,
			[HARM_TYPE_TAIL]=10,
			[HARM_TYPE_SPINJUMP]=10,
			[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}
		}
	)
end



local function round(val)
	local int,frac = math.modf(val)
	if frac >= 0.5  then
		return math.ceil(val)
	else
		return math.floor(val)
	end
end



local function cor_spawnBlert(args)
	local blob = args.parent
	local parentData = blob.data._basegame
	args.x = round(args.x  or  0)
	args.y = round(args.y  or  0)
	local w,h = round(blob.width),round(blob.height)

	--windowDebug (tostring(args.x)..", "..tostring(args.y))

	local x1,y1,x2,y2 = blob.x+args.x+2, blob.y+args.y+2, blob.x+args.x+w-2, blob.y+args.y+h-2
	local npcFree = (#NPC.getIntersecting(x1,y1,x2,y2) == 0)
	local blockFree = (#Block.getIntersecting(x1,y1,x2,y2) == 0)

	if  npcFree  and  blockFree  and  blob.isValid  then
		parentData.animFrame = 1
		Routine.waitFrames(20)

		if  blob.isValid  then
			npcFree = (#NPC.getIntersecting(x1,y1,x2,y2) == 0)
			blockFree = (#Block.getIntersecting(x1,y1,x2,y2) == 0)

			if  npcFree  and  blockFree  then
				SFX.play(72)
				local child = NPC.spawn (blob.id, blob.x+args.x, blob.y+args.y, player.section, false)
				child.data._basegame = {
				                        parent = parentData.parent  or  blob,
				                        radius = parentData.radius,
				                        growrate = parentData.growrate,
				                        spawned = true
				                       }
			end
		end
	end
end

local function cor_trySpawn(v)
	local blob = v
	local size = {}
	local data = blob.data._basegame

	local parent = data.parent  or  blob
	if  blob.isValid  and  parent.isValid  then
		local x1,x2,y1,y2 = blob.x+0.5*blob.width,parent.x+0.5*parent.width, blob.y+0.5*blob.height,parent.y+0.5*parent.height
		--windowDebug(tostring(x1)..","..tostring(x2)..","..tostring(y1)..","..tostring(y2))

		local distance = math.sqrt((x2-x1)*(x2-x1) + (y2-y1)*(y2-y1))
		data.distance = distance

		local surrounding = NPC.getIntersecting(blob.x-0.5*blob.width, blob.y-0.5*blob.height, blob.x+1.5*blob.width, blob.y+1.5*blob.height)

		if  #surrounding < 9  and  distance < data.radius*math.min(blob.width, blob.height)  and  not data.killChain  then
			for  _,v in ipairs{{x=blob.width},{x=-blob.width},{y=blob.height},{y=-blob.height}}  do
				v.parent = blob
				Routine.run(cor_spawnBlert, v)
			end
		end

		Routine.skip()
		if  blob.isValid  then
			if  data.animFrame ~= 0  then
				if  blob.isValid  then
					data.animFrame = 1
					Routine.waitFrames(4)
				end

				if  blob.isValid  then
					data.animFrame = 2
					Routine.waitFrames(16)
				end

				if  blob.isValid  then
					data.animFrame = 3
					Routine.waitFrames(4)
				end
				
				if  blob.isValid  then
					data.animFrame = 0
				end
			end
		end
	end
end

local function cor_blertDie(args)
	SFX.play(38)
	local blob = args.npc
	local data = blob.data._basegame
	data.animFrame = 1
	Routine.waitFrames(4)
	data.animFrame = 2

	if  blob.isValid  then
		local size = {width=round(blob.width), height=round(blob.height), id=blob.id}
		blob.speedX = 0
		blob.speedY = 0

		-- Only go through with the pop effect and ripple kill if the parent reference is a valid normal blert
		if  data.parent.isValid  and  size.id == blertID.normal  then

			-- If killing the core, destroy all others in a ripple
			if  data.parent == blob  then

				-- Make all the surrounding blerts look dead
				local x1,y1 = blob.x + 0.5*size.width, blob.y + 0.5*size.height
				local x2,y2,x3,y3 = x1-size.width*(data.radius+1), y1-size.height*(data.radius+1), x1+size.width*(data.radius+1), y1+size.height*(data.radius+1)

				local surrounding = NPC.getIntersecting(x2,y2,x3,y3)
				for  k,v in ipairs(surrounding)  do
					if  v.id == size.id  and  not v:mem(0x64,FIELD_BOOL)  then
						if  v.data._basegame.parent == blob  then
							v.data._basegame.killChain = true
						end
					end
				end

				-- Make the core invisible
				blob.isHidden = true
				Routine.waitFrames(32)

				-- Double-check (I'm sure there's a much better way to handle this)
				surrounding = NPC.getIntersecting(x2,y2,x3,y3)
				for  k,v in ipairs(surrounding)  do
					if  v.id == size.id  and  not v:mem(0x64,FIELD_BOOL)  then
						if  v.data._basegame.parent == blob  then
							v.data._basegame.killChain = true
						end
					end
				end

				-- Kill the blerts ring by ring
				SFX.play(41)
				for  i=1,data.radius+1,0.25  do
					local surroundingB = NPC.getIntersecting(x1-i*size.width, y1-i*size.height, x1+i*size.width, y1+i*size.height)

					for  k,v in ipairs(surroundingB)  do
						if  v.id == size.id  and  not v:mem(0x64,FIELD_BOOL)  then
							if  v.data._basegame.killChain == true  then
								v.data._basegame.dead = true
								v:kill()
							end
						end
					end
					Routine.skip()
				end

			else
				local x1,y1 = blob.x + 0.5*size.width, blob.y + 0.5*size.height

				local surroundingA = NPC.getIntersecting(x1-2*size.width, y1-2*size.height, x1+2*size.width, y1+2*size.height)
				local surroundingB = NPC.getIntersecting(x1-size.width,   y1-1,             x1+size.width,   y1+1)
				local surroundingC = NPC.getIntersecting(x1-1,            y1-size.height,   x1+1,            y1+size.height)

				for  k,v in ipairs(surroundingA)  do
					if  v.id == size.id  and  not v:mem(0x64,FIELD_BOOL)  then
						v.data._basegame.timer = v.data._basegame.growrate*32  or  32
					end
				end

				for  k,v in ipairs(table.append(surroundingB,surroundingC))  do
					if  v.id == size.id  and  not v:mem(0x64,FIELD_BOOL)  and  v ~= args.npc  then
						if  v ~= v.data._basegame.parent  then
							v.data._basegame.dead = true
						end
						v:kill()
					end
				end
			end
		end

		-- Final kill
		Routine.waitFrames(4)
		if  blob.isValid  then
			data.dead = true
			blob:kill()
		end
	end
end


function dieCheck(v)
end


function blert.onTickNPC(v)
	local blob = v


	-- Initialize properties
	if  blob.data._basegame == nil  then 
		blob.data._basegame = {spawned = false}
	end
	local data = blob.data._basegame

	data.growrate = data.growrate  or  blob.data.growrate  or  1
	data.radius = data.radius  or  blob.data.radius  or  3
	data.parent = data.parent  or  blob
	data.distance = data.distance  or  0

	-- Never despawn offscreen, but don't start multiplying until onscreen
	if  blob:mem(0x12A, FIELD_WORD) == 180  then
		data.spawned = true
	end
	if  data.spawned == true  then
		blob:mem(0x12A, FIELD_WORD, 179)
	end

	-- Manage animation
	data.animFrame = data.animFrame  or  0
	if  not data.parent.isValid  or  data.killChain == true  then
		data.animFrame = 4
	end

	blob.animationFrame = data.animFrame


	-- Manage multiplication timer
	if  data.timer == nil  then  data.timer = data.growrate*65;  end;
	data.timer = data.timer-1

	if  data.timer <= 0  and  blob.isValid  and  not data.killChain  and  data.spawned  then
		data.timer = data.growrate*65
		Routine.run(cor_trySpawn, blob)
		dieCheck (blob)
	end


	-- Force speed to 0
	--blob.speedX = 0
	--blob.speedY = 0
end


function blert.onNPCKill(eventobj, npc, reason)
	if (not npc.isValid) then
		return;
	end

	if  npc.id == blertID.normal  and  not npc:mem(0x64,FIELD_BOOL)  and  reason ~= HARM_TYPE_OFFSCREEN  then
		local blob = npc
		local data = blob.data._basegame
		if  data.dead ~= true  then
			eventobj.cancelled = true
			Routine.run(cor_blertDie, {npc=npc})
		else
			Animation.spawn(killEffect, npc.x, npc.y)
		end
	end
end


function blert.onInitAPI()
	for  k,v in pairs(blertID) do
		npcManager.registerEvent(v, blert, "onTickNPC")
	end

	registerEvent(blert, "onNPCKill")
end

return blert

--BASE
  -- v.ai1 // v.data.type {
	-- 	/What Type?
  --    0 = !
	-- 	  1 = Up
	-- 	  2 = Left
	-- 	  3 = Right
	--   }
	-- v.ai2 v.data.life {
	--   /How long should the ghost created last?
	--   }

--Ghost
  -- v.ai1 v.data.type {
	-- 	/Direction?
	-- 	0 = up
	-- 	1 = Left
	-- 	2 = Right
	-- }
	-- v.ai2 v.data.sp {
	-- 	/Should change direction when jumped?
	-- 	true = Yes
	-- 	false = No
	-- }
	-- v.ai3 v.data.life {
	--   /How long should the ghost last?
  -- }
