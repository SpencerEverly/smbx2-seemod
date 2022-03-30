local npcManager = require("npcManager")

local parabeetle = {}

function parabeetle.register(id)
    npcManager.registerEvent(id, parabeetle, "onTickEndNPC")
end

function parabeetle.onInitAPI()
	registerEvent(parabeetle, "onTick", "onTick", false)
	registerEvent(parabeetle, "onDrawEnd")
end

local riddenNPCs = {}

function parabeetle.onTick()
	--find the NPC the player is standing on
	for _,p in ipairs(Player.get()) do	
		local riddenNPCIndex = p:mem(0x176, FIELD_WORD)
		if (riddenNPCIndex > 0) then
			riddenNPCs[NPC(riddenNPCIndex-1).uid] = true
		end
	end
end

function parabeetle.onDrawEnd()
	riddenNPCs = {}
end

function parabeetle.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data._basegame
	
	if v.isHidden or v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x124, FIELD_WORD) == 0 or v:mem(0x138, FIELD_WORD) > 0 then
		data.isRidden = false
		data.preventEffectTimer = 0
		data.returnDelayTimer = 0
		return
	end
	
	if (data.preventEffectTimer == nil) then
		data.preventEffectTimer = 0
		data.returnDelayTimer = 0
	end
	if data.isRidden == nil then
		data.isRidden = false;
    end
    
    local cfg = NPC.config[v.id]
	
	if cfg.returndelay > 0 and data.startY == nil and v:mem(0x12C, FIELD_WORD) == 0 then
		if math.abs(v.speedY) < 1 then
			data.startY = v.y
		end
	end
	
	--movement left/right
    v.speedX = v.direction * cfg.speed
	--movement up/down
	if (riddenNPCs[v.uid]) then
		--player rides on the parabeetle
		--make the parabeetle flutter faster
        v.animationTimer = v.animationTimer + 1;
        
        if cfg.ridespeed ~= 0 then --using constant ride speed if set
            v.speedY = cfg.ridespeed
        else
            --make the parabeetle lose altitude, then fly back up
            if (not data.isRidden and data.preventEffectTimer == 0) then
                v.speedY = cfg.ridespeedstart;
            elseif(cfg.ridespeedstart > cfg.ridespeedend) then
                v.speedY = math.max(cfg.ridespeedend, v.speedY - cfg.ridespeeddelta);
            elseif(cfg.ridespeedstart < cfg.ridespeedend) then
                v.speedY = math.min(cfg.ridespeedend, v.speedY + cfg.ridespeeddelta);
            end

        end
		data.isRidden = true;
	else
		--player does not ride on the parabeetle
		if (data.isRidden) then
			data.isRidden = false
			data.preventEffectTimer = 10 --prevent repeatedly causing the "jumped on" effect when Mario stands on the edge of the npc.
			data.returnDelayTimer = cfg.returndelay
		elseif (data.preventEffectTimer > 0) then
			data.preventEffectTimer = data.preventEffectTimer - 1
        end
        
        if cfg.returndelay > 0 then --parabeetle should return to original position rather than a straight flight
            if (data.returnDelayTimer > 0) then
                data.returnDelayTimer = data.returnDelayTimer - 1
            else
                if (data.startY) then
                    if v.y > data.startY then
                        v.speedY = math.max(cfg.returnspeed, v.speedY - cfg.returnspeeddelta)
                    else 
                        v.speedY = 0
                    end
                end
            end
        else
            --reset the parabeetle's speedY back to 0
            if (v.speedY > 0) then
                v.speedY = math.max(0, v.speedY - cfg.returnspeeddelta);
            elseif (v.speedY < 0) then
                v.speedY = math.min(0, v.speedY + cfg.returnspeeddelta);
            end
        end
	end
end
	
return parabeetle
