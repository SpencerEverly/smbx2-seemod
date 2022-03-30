local npcManager = require("npcManager")

local diagonals = {}

function diagonals.register(id)
    npcManager.registerEvent(id, diagonals, "onDrawNPC")
    npcManager.registerEvent(id, diagonals, "onTickNPC")
    npcManager.registerEvent(id, diagonals, "onDrawEndNPC")
end

local speed = 3;
local buffer = 1;

function diagonals.onTickNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data._basegame
    
    local cfg = NPC.config[v.id]
	
	if not data.init then
		data.init = true;
		data.velocity = (vector.right2 * v.direction - vector.up2):normalise() * speed;
		data.hCollider = Colliders.Box(v.x-buffer,v.y+buffer,v.width+2*buffer,v.height-2*buffer);
		data.vCollider = Colliders.Box(v.x+buffer,v.y-buffer,v.width-2*buffer,v.height+2*buffer);
		data.frame = v.animationFrame;
		data.frameOffset = 0;
        data.despawned = true;
        data.hasTail = cfg.taillength
		if(data.hasTail) then
			data.tail = {};
			data.tailIndex = 0;
			data.tailCounter = 0;
			data.tailOffset = 0;
		end
	end
			
	if(not data.hasTail) then
		if(data.despawned and v:mem(0x124,FIELD_WORD) ~= 0) then
			data.velocity = (vector.right2 * -v.direction + vector.up2):normalise() * -speed;
		end
	end
	
	if not data.despawned then
		
	
		do
			local id = v.id;
			local x = v.x;
			local y = v.y;
			local width = v.width;
			local height = v.height;
		
		
			v.speedX = data.velocity.x * cfg.speed;
			v.speedY = data.velocity.y * cfg.speed;
			
			data.hCollider.x = x-buffer;
			data.hCollider.y = y+buffer;
			data.hCollider.width = width+2*buffer;
			data.hCollider.height = height-2*buffer;
			
			data.vCollider.x = x+buffer;
			data.vCollider.y = y-buffer;
			data.vCollider.width = width-2*buffer;
			data.vCollider.height = height+2*buffer;
		end
	
		if(v:mem(0x120,FIELD_BOOL) and not v.collidesBlockLeft and not v.collidesBlockRight) then
			data.velocity.x = -data.velocity.x;
		elseif(data.velocity.x < 0 and v.collidesBlockLeft) or (data.velocity.x > 0 and v.collidesBlockRight) then
			local bs = Colliders.getColliding{a=data.hCollider, b=Block.ALL, btype = Colliders.BLOCK};
			if(#bs > 0) then
				if(Block.SLOPE_MAP[bs[1].id]) then
					data.velocity.y = -data.velocity.y;
				end
				data.velocity.x = -data.velocity.x;
			end
		end
		if((data.velocity.y < 0 and v.collidesBlockUp) or (data.velocity.y > 0 and v.collidesBlockBottom)) then
			local bs = Colliders.getColliding{a=data.vCollider, b=Block.ALL, btype = Colliders.BLOCK};
			if(#bs > 0) then
				if(Block.SLOPE_MAP[bs[1].id]) then
					data.velocity.x = -data.velocity.x;
				end
				data.velocity.y = -data.velocity.y;
			else
				bs = Colliders.getColliding{a=data.vCollider, b=NPC.ALL, btype = Colliders.NPC};
				for _,w in ipairs(bs) do
					if(w.idx ~= v.idx) then
						if(NPC.config[w.id].npcblocktop) then
							data.velocity.y = -data.velocity.y;
							break;
						end
					end
				end
			end
		end
		
		if(not data.hasTail) then
			if(data.velocity.y > 0) then
				data.frameOffset = cfg.frames*2;
			else
				data.frameOffset = 0;
			end
		else
			if(data.despawned and v:mem(0x124,FIELD_WORD) == -1 or data.tail == nil) then
				data.tailCounter = 0;
				data.tail = {};
			end
			if(v:mem(0x138, FIELD_WORD) == 0) then --Mid generating or inside a container
				if (not v.friendly) and v:mem(0x12C, FIELD_WORD) == 0 then
					for l,w in ipairs(data.tail) do	
						for _,p in ipairs(Player.get()) do
							if(Colliders.collide(p,w.hitbox)) then
								p:harm();
							end
						end
					end
				end
				data.tailCounter = data.tailCounter+1;
				if(data.tailCounter > 8) then
					if(#data.tail >= cfg.taillength) then
						table.remove(data.tail,1);
					end
					table.insert(data.tail, {x = v.x, y = v.y,frame=data.tailIndex, offset=data.tailOffset,direction=v.direction, hitbox = Colliders.Box(v.x+2,v.y+2,math.max(1,v.width-4),math.max(1,v.height-4))});
					data.tailIndex = (data.tailIndex+1)%3;
					if(data.tailIndex == 0) then
						data.tailOffset = 1-data.tailOffset;
					end
					data.tailCounter = 0;
				end
			end
		end
	else
		v.speedX = 0;
		v.speedY = 0;
	end
	data.despawned = v:mem(0x124,FIELD_WORD) == 0 or v.isHidden;
end

function diagonals.onDrawNPC(v)	
	local data = v.data._basegame
	
    if data.despawned then return end
    
    local cfg = NPC.config[v.id]
	
	data.frame = v.animationFrame;
	if((not data.hasTail) and cfg.framestyle > 0 and data.velocity ~= nil) then
		if(data.velocity.y > 0 and v.animationFrame < cfg.frames*2) then
			v.animationFrame = v.animationFrame+data.frameOffset;
		end
	else
		if(cfg.framestyle > 0) then
			data.frameOffset = (math.floor((v.direction+1)*0.5))*(cfg.frames*3);
			v.animationFrame = v.animationFrame+data.frameOffset;
		end
        if data.tail == nil then data.tail = {} end
        local bw = cfg.gfxwidth
        if bw == 0 then bw = cfg.width end
        local bh = cfg.gfxheight
        if bh == 0 then bw = cfg.height end
		for l,w in ipairs(data.tail) do
			Graphics.drawImageToSceneWP(
				Graphics.sprites.npc[v.id].img,
				w.x,
				w.y,
				0,
				math.floor((w.offset + (w.frame+1)*cfg.frames + (math.floor((w.direction+1)*0.5))*(cfg.frames*4))*bh),
				bw,
				bh,
				-55
			)
		end
	end
end

function diagonals.onDrawEndNPC(v)	
	local data = v.data._basegame
	
	if(data.frame) then
		v.animationFrame = data.frame;
	end
end
	
return diagonals