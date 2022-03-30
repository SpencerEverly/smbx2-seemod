local megaSpike =  {}

local npcManager = require("npcManager")
local rng = require("rng")
local smallSwitch = require("npcs/ai/smallswitch")
local donutblock = require("npcs/ai/donutblock")
local utils = require("npcs/npcutils")

megaSpike.speedYThreshold = 0.02; --To fix the dumb gravity bug and allow megaspikes to be used next to walls

--ai2 = length of spike in blocks

local DEBUG = false;

local buffers = {}
local skewerIDs = {}

function megaSpike.register(id)
    buffers[id] = {vt = {}, tx = {}, idx = 1}
    table.insert(skewerIDs, id)
    npcManager.registerEvent(id, megaSpike, "onStartNPC");
    npcManager.registerEvent(id, megaSpike, "onTickNPC");
    npcManager.registerEvent(id, megaSpike, "onDrawNPC");
    npcManager.registerEvent(id, megaSpike, "onCameraDrawNPC");
end

--Register events
function megaSpike.onInitAPI()
	registerEvent(megaSpike, "onDraw", "onDraw", false);
end

--Play the screenshake and sound effect
local function playEffect()
	Defines.earthquake = 8;
	SFX.play(37);
end

--New skewers require certain data when spawned. Set that up here.
function megaSpike.onStartNPC(v)
	if(v.direction == 0) then
		v.direction = rng.randomInt(0,1)*2 - 1;
	end
	if(v.dontMove) then
		v.data._basegame.dontmovedir = v.direction;
	end
	if(v.ai2 == 0) then
		v.ai2 = 20;
	end
	v.data._basegame.maxlength = math.max(v.ai2,1)*32;
	v.data._basegame.collider = Colliders.Box(v.x,v.y,0,0);
	v.data._basegame.hitcollider = Colliders.Box(v.x,v.y,0,0);
	v.data._basegame.length = 32;
	v.data._basegame.time = 0;
	v.data._basegame.extended = false;
end

do	
	--Add vertices and texture coordinates to the vertical skewer buffers
	local function createVerticalBuffers(v)
		local data = v.data._basegame;
		local direction = v.direction;
		local cfg = NPC.config[v.id];
		local frames = math.max(cfg.frames,1);
		
		--framepos contains the starting point of our current skewer frame, for texture coordinates (units are vanilla size "frames")
		local framepos = frames;
		
		--Adjust frames depending on framestyle
		if(cfg.framestyle > 0) then
			framepos=framepos*2;
		end
		
		--Adjust framepos to second spike set (we don't need to do this if framestyle is 1 or above, since vanilla does it for us)
		if(direction == 1 and cfg.framestyle == 0) then
			framepos = framepos+(3*frames);
		end
		
		--Adjust framepos for animation purposes
		if(frames > 1) then
			framepos = framepos + (v.animationFrame)*3;
		end
		
		--Initialise gfx sizes
		local h = 0;
		if(cfg.gfxheight == 0) then
			h = v.height;
		else
			h = cfg.gfxheight;
		end
		local w = 0;
		if(cfg.gfxwidth == 0) then
			w = v.width;
		else
			w = cfg.gfxwidth;
		end
		
		local img = Graphics.sprites.npc[v.id].img;
		local skewerstart = (framepos*h)/img.height;
		
		--Initialise starting point of loop at the end of the skewer, iterating back towards the base
		local x = v.x - v.direction * cfg.gfxoffsetx;
		local basey = v.y + cfg.gfxoffsety;
		
		local y;
		local baseframepos;
		
		--Position of y (iterator variable) and basey (loop end point) and their respective texture coordinates depend on the direction
		if(direction == 1) then
			basey = basey+v.height;	
			y = basey+data.length;
			baseframepos = framepos;
			framepos = framepos + 3;
		elseif(direction == -1) then
			y = basey-data.length-h;
			baseframepos = framepos + 2;
			framepos = framepos-1;
		end
		
		--Main iterator - step one "layer" at a time, shifting position and texture until we hit the skewer base
		while (direction == 1 and y > basey) or (direction == -1 and y+h < basey) do
			--Adjust vertex positions
			y = y-direction*h;
			
			--Adjust texture coordinates
			framepos = framepos-direction;
			--If texture coordinates step beyond the end of the current skewer frame, reset - this allows the texture to loop
			if (direction == 1 and framepos < baseframepos) or (direction == -1 and framepos > baseframepos) then
				framepos = baseframepos+direction;
			end
			
			--Set up texture y coordinates, which we alter each run through the loop
			local ty1 = framepos*h/img.height;
			local ty2 = (framepos+1)*h/img.height;
			
			--If we've overshot the skewer base, adjust vertex and texture coordinates to snap neatly onto the base
			if (direction == 1 and y < basey) then
				local d = basey-y;
				y = basey;
				ty1 = (framepos*h + d)/img.height;
				h = h-d;
			elseif (direction == -1 and y+h > basey) then
				local d = basey-y;
				ty2 = ((framepos+1)*h - (h-d))/img.height;
				h = d;
			end		
			
			
			--Clamp texture coordinates sliiiightly below their start point to avoid the base showing in rounding errors
			ty1 = math.max(ty1, skewerstart+0.001);
			ty2 = math.max(ty2, skewerstart+0.001);
            --Insert vertices and texture coordinates
            local buf = buffers[v.id]
			buf.vt[buf.idx],buf.vt[buf.idx+1] = x,y;
			buf.vt[buf.idx+2],buf.vt[buf.idx+3] = x+w,y;
			buf.vt[buf.idx+4],buf.vt[buf.idx+5] = x,y+h;
			buf.vt[buf.idx+6],buf.vt[buf.idx+7] = x,y+h;
			buf.vt[buf.idx+8],buf.vt[buf.idx+9] = x+w,y;
			buf.vt[buf.idx+10],buf.vt[buf.idx+11] = x+w,y+h;
			
			buf.tx[buf.idx],buf.tx[buf.idx+1] = 0,ty1;
			buf.tx[buf.idx+2],buf.tx[buf.idx+3] = 1,ty1;
			buf.tx[buf.idx+4],buf.tx[buf.idx+5] = 0,ty2;
			buf.tx[buf.idx+6],buf.tx[buf.idx+7] = 0,ty2;
			buf.tx[buf.idx+8],buf.tx[buf.idx+9] = 1,ty1;
			buf.tx[buf.idx+10],buf.tx[buf.idx+11] = 1,ty2;
			
			buf.idx = buf.idx+12;
		end
	end
	
	--Add vertices and texture coordinates to the horizontal skewer buffers
	local function createHorizontalBuffers(v)
		local data = v.data._basegame;
		local direction = v.direction;
		local cfg = NPC.config[v.id];
		local frames = math.max(cfg.frames,1);
		
		--framepos contains the starting point of our current skewer frame, for texture coordinates (units are vanilla size "frames")
		local framepos = frames;
		

		--Adjust frames depending on framestyle
		if(cfg.framestyle > 0) then
			framepos=framepos*2;
		end
		
		--Adjust framepos to second spike set (we don't need to do this if framestyle is 1 or above, since vanilla does it for us)
		if(direction == 1 and cfg.framestyle == 0) then
			framepos = framepos+frames;
		end
		
		--Adjust framepos for animation purposes
		if(frames > 1) then
			framepos = framepos + v.animationFrame;
		end
		
		--Initialise gfx sizes
		local h = 0;
		if(cfg.gfxheight == 0) then
			h = v.height;
		else
			h = cfg.gfxheight;
		end
		local w = 0;
		if(cfg.gfxwidth == 0) then
			w = v.width;
		else
			w = cfg.gfxwidth;
		end
		
		local img = Graphics.sprites.npc[v.id].img;
		local skewerstart = (framepos*h)/img.height;
		
		--Initialise starting point of loop at the end of the skewer, iterating back towards the base
		local basex = v.x - v.direction * cfg.gfxoffsetx;
		local y = v.y + cfg.gfxoffsety;
		
		local x;
		
		--xframepos is used separately from framepos, since we need to iterate horizontally - since everything else is vertically arranged, our horizontal iteration is a fixed range of 0-2
		local xframepos = 0;
		
		--Position of x (iterator variable) and basex (loop end point) and their respective texture coordinates depend on the direction
		--xframepos is going to be modified immediately, so it needs an off-by-one built in
		if(direction == 1) then
			basex = basex+v.width;	
			x = basex+data.length;
			xframepos = 3;
		elseif(direction == -1) then
			x = basex-data.length-w;
			xframepos = -1;
		end
			
		--We need y coordinates for animation and direction, but since the graphics are horizontal, these are constant for the entire skewer
		local ty1 = framepos*h/img.height;
		local ty2 = (framepos+1)*h/img.height;
		
		--Clamp texture coordinates sliiiightly below their start point to avoid the base showing in rounding errors
		ty1 = math.max(ty1, skewerstart+0.001);
		ty2 = math.max(ty2, skewerstart+0.001);
		
		--Main iterator - step one "layer" at a time, shifting position and texture (both horizontally) until we hit the skewer base
		while (direction == 1 and x > basex) or (direction == -1 and x+w < basex) do
			--Adjust vertex positions
			x = x-direction*w;
			
			--Adjust texture coordinates
			xframepos = xframepos-direction;
			--If texture coordinates step beyond the end of the current skewer frame, reset - this allows the texture to loop
			if (direction == 1 and xframepos < 0) or (direction == -1 and xframepos > 2) then
				xframepos = 1;
			end
			
			--Set up texture x coordinates, which we alter each run through the loop
			local tx1 = (xframepos*w)/img.width;
			local tx2 = ((xframepos+1)*w)/img.width;
			
			--If we've overshot the skewer base, adjust vertex and texture coordinates to snap neatly onto the base
			if (direction == 1 and x < basex) then
				local d = basex-x;
				x = basex;
				tx1 = (xframepos*w + d)/img.width;
				w = w-d;
			elseif (direction == -1 and x+w > basex) then
				local d = basex-x;
				tx2 = ((xframepos+1)*w - (w-d))/img.width;
				w = d;
			end		
			
            local buf = buffers[v.id]
			buf.vt[buf.idx],buf.vt[buf.idx+1] = x,y;
			buf.vt[buf.idx+2],buf.vt[buf.idx+3] = x+w,y;
			buf.vt[buf.idx+4],buf.vt[buf.idx+5] = x,y+h;
			buf.vt[buf.idx+6],buf.vt[buf.idx+7] = x,y+h;
			buf.vt[buf.idx+8],buf.vt[buf.idx+9] = x+w,y;
			buf.vt[buf.idx+10],buf.vt[buf.idx+11] = x+w,y+h;
			
			buf.tx[buf.idx],buf.tx[buf.idx+1] = tx1,ty1;
			buf.tx[buf.idx+2],buf.tx[buf.idx+3] = tx2,ty1;
			buf.tx[buf.idx+4],buf.tx[buf.idx+5] = tx1,ty2;
			buf.tx[buf.idx+6],buf.tx[buf.idx+7] = tx1,ty2;
			buf.tx[buf.idx+8],buf.tx[buf.idx+9] = tx2,ty1;
			buf.tx[buf.idx+10],buf.tx[buf.idx+11] = tx2,ty2;
			
			buf.idx = buf.idx+12;
		end
	end
	
	--Update hitboxes of the given skewer, so they're positioned correctly on the skewer graphic
	local function updatehitbox(v)
        local data = v.data._basegame;
        local cfg = NPC.config[v.id]
		if(cfg.horizontal == false) then
			data.collider.x = v.x+cfg.hitboxoffset;
			data.collider.width = v.width-2*cfg.hitboxoffset;
			
			data.hitcollider.x = data.collider.x;
			data.hitcollider.width = data.collider.width;
			data.hitcollider.height = 16;
			
			if(v.direction == 1) then
				data.collider.y = v.y+v.height;
				data.collider.height = data.length-cfg.hitboxoffset*0.5;
				
				data.hitcollider.y = v.y+v.height+data.length-cfg.hitboxoffset*0.5 - 16;
				
			elseif(v.direction == -1) then
				data.collider.y = v.y-data.length+cfg.hitboxoffset*0.5;
				data.collider.height = v.y-data.collider.y;
				
				data.hitcollider.y = data.collider.y;
				
			end
		else			
			data.collider.y = v.y+cfg.hitboxoffset;
			data.collider.height = v.height-2*cfg.hitboxoffset;
			
			data.hitcollider.y = data.collider.y;
			data.hitcollider.height = data.collider.height;
			data.hitcollider.width = 16;
			
			if(v.direction == 1) then
				data.collider.x = v.x+v.width;
				data.collider.width = data.length-cfg.hitboxoffset*0.5;
				
				data.hitcollider.x = v.x+v.width+data.length-cfg.hitboxoffset*0.5 - 16;
				
			elseif(v.direction == -1) then
				data.collider.x = v.x-data.length+cfg.hitboxoffset*0.5;
				data.collider.width = v.x-data.collider.x;
				
				data.hitcollider.x = data.collider.x;
				
			end
		end
	end
	
	--Spawn a smoke puff at the end of a skewer
	local function spawnPuff(v, offsetx, offsety)
		local e = Effect.spawn(10,v.x+offsetx,v.y+offsety);
        local data = v.data._basegame;
        local cfg = NPC.config[v.id]
		
		if(cfg.horizontal == false) then
			e.x = e.x-0.5*e.width;
			if(v.direction == -1) then
				e.y = v.y-data.length-0.5*e.height;
			elseif(v.direction == 1) then
				e.y = v.y+v.height+data.length-0.5*e.height;
			end
		else
			e.y = e.y-0.5*e.height;
			if(v.direction == -1) then
				e.x = v.x-data.length-0.5*e.width;
			elseif(v.direction == 1) then
				e.x = v.x+v.width+data.length-0.5*e.width;
			end
		end
	end
	
	--Stop a vertical skewer immediately - used when the skewer hits something
	local function blockVertical(v, obj, minx, maxx)
		local data = v.data._basegame;
		if(v.direction == 1) then
			data.length = math.max(32,math.min(data.length, obj.y-(v.y+v.height)));
		elseif(v.direction == -1) then
			data.length = math.max(32,math.min(data.length, v.y-(obj.y+obj.height)));
		end
			minx = math.min(minx, obj.x);
			maxx = math.max(maxx, obj.x + obj.width);
			data.extended = true;
			playEffect();
			data.time = 0;
		return minx,maxx;
	end
	
	--Stop a horizontal skewer immediately - used when the skewer hits something
	local function blockHorizontal(v, obj, miny, maxy)
		local data = v.data._basegame;
		if(v.direction == 1) then
			data.length = math.max(32,math.min(data.length, obj.x-(v.x+v.width)));
		elseif(v.direction == -1) then
			data.length = math.max(32,math.min(data.length, v.x-(obj.x+obj.width)));
		end
			miny = math.min(miny, obj.y);
			maxy = math.max(maxy, obj.y + obj.height);
			data.extended = true;
			playEffect();
			data.time = 0;
		return miny,maxy;
	end
	
	--Checks if the skewer is on screen - useful to check so we don't calculate vertices for offscreen skewers
	local function isOnScreen(v)
		local cfg = NPC.config[v.id];
		local w = cfg.gfxwidth;
		if(w == 0) then
			w = v.width;
		end
		local h = cfg.gfxheight;
		if(h == 0) then
			h = v.height;
		end
		local minx = v.x;
		local maxx = v.x+w;
		local miny = v.y;
		local maxy = v.y+h;
		local data = v.data._basegame;
		if(cfg.horizontal) then
			if(v.direction == -1) then
				minx = math.min(minx - data.length);
			elseif(v.direction == 1) then
				maxx = math.max(maxx + data.length);
			end
		else
			if(v.direction == -1) then
				miny = math.min(miny - data.length);
			elseif(v.direction == 1) then
				maxy = math.max(maxy + data.length);
			end
		end
			
		for _,c in ipairs(Camera.get()) do
			if(maxx > c.x and minx < c.x + c.width and maxy > c.y and miny < c.y + c.height) then
				return true;
			end
		end
		
		return false;
	end
	
	--List of container types (0x138) that should block all behaviour
	local blockingContainers = {[1]=true, [2]=true, [3]=true, [4] = true, [5]=true}
	
	local blockHitExclusions = {
								[681]=true --[[Costume block]], 
							   }
		
	--Exclude character blocks from being hit by skewers
	do
		local playerManager = require("playerManager");
		for _,v in pairs(playerManager.getCharacters()) do
			blockHitExclusions[v.switchBlock] = true;
			blockHitExclusions[v.filterBlock] = true;
		end
	end
	
	function megaSpike.onTickNPC(v)
		local data = v.data._basegame;
		if Defines.levelFreeze then return end
		
		--Some containers do weird things to the state, so we wait to initialise it
		if(blockingContainers[v:mem(0x138, FIELD_WORD)]) then
			data.beingSpawned = true;
			return;
		end
		
		--Hacky fix for the bug that makes NPCs underneath blocks slowly float down
		if(math.abs(v.speedY) < megaSpike.speedYThreshold and v.speedY ~= 0) then
			v.speedY = 0;
		end
		
		--Initialise new skewers if we need to
		if(data.time == nil) then
			megaSpike.onStartNPC(v);
		end
		
		--Skewer is despawned or hidden
		if(v:mem(0x12A, FIELD_WORD) <= 0 or v.isHidden) then
			return;
		end
		
		--Allow skewers to move on layers
		utils.applyLayerMovement(v)
		
		--Skewer update cycle
		if(not Defines.levelFreeze and not v.dontMove) then
			data.time = data.time + 1;
		end
		local t = data.time;
		local extending = false;
        local cfg = NPC.config[v.id]
		
		--Skewer states for anticipation, extending, and retracting
		if(not data.extended and t > cfg.waitDelay - 48 and t < cfg.waitDelay - 16) then
			data.length = math.lerp(32, 16, (t - (cfg.waitDelay - 48))/32);
		elseif(not data.extended and t > cfg.waitDelay and data.length < data.maxlength) then
			data.length = data.length + cfg.extendSpeed;
			extending = true;
			if(data.length >= data.maxlength) then			
				data.extended = true;
				playEffect();
				data.length = data.maxlength;
				data.time = 0;
			end
		elseif(data.extended and t > cfg.extendedDelay) then
			data.length = data.length - cfg.retractSpeed;
			if(data.length <= 32) then
				data.extended = false;
				data.length = 32;
				data.time = 0;
			end
		end
			
		--Skewers can't move - makes things cleaner
		v.speedX = 0;
		v.speedY = 0;
		
		--Adjust hitbox for newly calculated position
		updatehitbox(v);
		
		if(not Defines.levelFreeze) then
			--Compute collisions with things that will stop the skewer
			if(cfg.horizontal == false) then
				if(extending and cfg.hitsblocks) then
					local hitblock = false;
					local minx,maxx = math.huge,-math.huge
					
					--Compute collisions with NPCs
					for _,b in ipairs(Colliders.getColliding{a=data.hitcollider, b=NPC.UNHITTABLE..NPC.SWITCH, btype = Colliders.NPC}) do
						if b ~= v then
							local pressed = false;
							--Only press switches with downward spikes
							if(v.direction == 1) then
								--P-switch/T-switch
								if(b.id == 32 or b.id == 238)then
									b:harm(1);
									pressed = true;
								--Other switches
								elseif(smallSwitch.settings[b.id]) then
									smallSwitch.press(b);
									pressed = true;
								elseif(donutblock.ids[b.id]) then
									donutblock.fall(b);
									pressed = true;
								end
							end
							
							if(pressed or NPC.config[b.id].playerblocktop) then
								hitblock = true;
								minx, maxx = blockVertical(v, b, minx, maxx)
							end
						end
					end
					
					local blockslist = Block.SOLID..Block.PLAYER;
					if(v.direction == 1) then
						blockslist = blockslist..Block.SEMISOLID;
					end
					
					--Compute collisions with blocks
					for _,b in ipairs(Colliders.getColliding{a=data.hitcollider, b=blockslist, btype = Colliders.BLOCK}) do
						if(v.direction == 1 and Block.SEMISOLID_MAP[b.id] and (b.y < data.hitcollider.y+data.hitcollider.height-cfg.extendSpeed)) then
							--Prevents downwards facing skewers from hitting sizables they're in front of
							break
						end
						if(Block.MEGA_SMASH_MAP[b.id]) then
							b:remove(true);
						elseif(not blockHitExclusions[b.id]) then
							b:hit(v.direction == 1);
						end
						hitblock = true;
						minx, maxx = blockVertical(v, b, minx, maxx)
					end
					
					--If the skewer hit something, spawn smoke puffs in appropriate locations
					if(minx < v.x+v.width*0.5) then
						spawnPuff(v, cfg.hitboxoffset, 0);
					end
					if(maxx > v.x+v.width*0.5) then
						spawnPuff(v, v.width-cfg.hitboxoffset, 0);
					end
				end
			else
				if(extending and cfg.hitsblocks) then
					local hitblock = false;
					local miny,maxy = math.huge,-math.huge
					
					--Compute collisions with NPCs
					for _,b in ipairs(Colliders.getColliding{a=data.hitcollider, b=NPC.UNHITTABLE, btype = Colliders.NPC}) do
						if b ~= v then
							if(NPC.config[b.id].npcblock) then
								hitblock = true;
								miny, maxy = blockHorizontal(v, b, miny, maxy)
							end
						end
					end
					
					--Compute collisions with blocks
					for _,b in ipairs(Colliders.getColliding{a=data.hitcollider, b=Block.SOLID..Block.PLAYER, btype = Colliders.BLOCK}) do
						if(Block.MEGA_SMASH_MAP[b.id]) then
							b:remove(true);
						elseif(not blockHitExclusions[b.id]) then
							b:hit();
						end
						hitblock = true;
						miny, maxy = blockHorizontal(v, b, miny, maxy)
					end
					
					--If the skewer hit something, spawn smoke puffs in appropriate locations
					if(miny < v.y+v.height*0.5) then
						spawnPuff(v, 0, cfg.hitboxoffset);
					end
					if(maxy > v.y+v.height*0.5) then
						spawnPuff(v, 0, v.height-cfg.hitboxoffset);
					end
				end
			end
			
			--Since the skewer's length might have changed, the hitbox needs updating again
			updatehitbox(v);
		end
		
		if(not v.friendly) then
			--Harm players
			for _,p in ipairs(Player.get()) do
				if(Colliders.collide(data.collider, p)) then
					p:harm();
				end
			end
			
			--Harm NPCs
			for _,n in ipairs(Colliders.getColliding{a=data.collider, b=NPC.HITTABLE, btype = Colliders.NPC}) do
				n:harm();
			end
		end
	end
	
	function megaSpike.onDrawNPC(v)
		--Don't draw the spikes if the skewer is still spawning
		if(blockingContainers[v:mem(0x138, FIELD_WORD)]) then
			return;
		end
		
		local data = v.data._basegame;
		
		local cfg = NPC.config[v.id];
		--If the skewer has just finished spawning, fix up the state so it looks right
		if(data.beingSpawned) then
			v.width = cfg.width;
			v.height = cfg.height;
			data.beingSpawned = false;
		end
		
		--Initialise skewers if necessary, just in case
		if(data.time == nil) then
			megaSpike.onStartNPC(v);
		end
		
		--Skewer is despawned or hidden
		if(v:mem(0x12A, FIELD_WORD) <= 0 or v.isHidden) then
			return;
		end
		
		--Don't bother drawing the skewer if it's offscreen
		if(not isOnScreen(v)) then return; end
		
		if(v.dontMove) then
			if(data.dontmovedir == nil) then
				data.dontmovedir = v.direction;
			else
				v.direction = data.dontmovedir;
			end
		else
			data.dontmovedir = nil;
		end
		
		v.animationFrame = math.floor((cfg.frames-1) * data.length/data.maxlength);
		if(cfg.framestyle > 0) then
			v.animationFrame = v.animationFrame + cfg.frames * math.max(v.direction,0);
		end
		
		--Add skewers to the relevant buffers
		if(not cfg.horizontal) then
			--Special case for carrying vertical skewers - make them always point UP
			if(v:mem(0x130, FIELD_WORD) > 0) then
				v.direction = -1;
			end
			createVerticalBuffers(v);
		else
			createHorizontalBuffers(v);
		end
			
		--DEBUG STUFF
		if(DEBUG) then
			data.collider:Draw();
			data.hitcollider:Draw();
		end
	end
	
	--Avoid despawning skewers whose base is offscreen, but whose spikes aren't
	function megaSpike.onCameraDrawNPC(v, camidx)
		local data = v.data._basegame;
		if(data.time == nil) then
			return;
		end

		if v:mem(0x12A, FIELD_WORD) <= 0 then return end
		
		local c = Camera(camidx);
		
		local cx,cy,cw,ch = c.x,c.y,c.width,c.height;
        
        local h = NPC.config[v.id].horizontal
		if(h == false and v.x+v.width > cx and v.x < cx+cw) then
			if (v.direction == -1 and v.y-data.length < cy+ch and v.y+v.height > cy) or (v.direction == 1 and v.y+v.height+data.length > cy and v.y < cy+ch) then
				v:mem(0x12A, FIELD_WORD, 180);
			end
		elseif(h and v.y+v.height > cy and v.y < cy+ch) then
			if (v.direction == -1 and v.x-data.length < cx+cw and v.x+v.width > cx) or (v.direction == 1 and v.x+v.width+data.length > cx and v.x < cx+cw) then
				v:mem(0x12A, FIELD_WORD, 180);
			end
		end
	end
	
	--Global onDraw draws the contents of the skewer buffers
    function megaSpike.onDraw()
        for k,v in ipairs(skewerIDs) do
            local buf = buffers[v]

            for i = #buf.vt,buf.idx,-1 do
                buf.vt[i] = nil;
                buf.tx[i] = nil;
            end

            if buf.idx > 1 then
                local cfg = NPC.config[v]
                local p = cfg.foreground
                if(p) then
                    p = -15;
                else
                    p = -45;
                end
                Graphics.glDraw{vertexCoords = buf.vt, textureCoords = buf.tx, sceneCoords = true, priority = p, texture = Graphics.sprites.npc[v].img}
            end
			
            --Reset buffer indices before the next tick
            buf.idx = 1
        end
	end
end


return megaSpike