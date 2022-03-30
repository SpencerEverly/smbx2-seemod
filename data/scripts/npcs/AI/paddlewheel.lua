local npcManager = require("npcManager");
local orbits = require("orbits");
local lineguide = require("base/lineguide");

local paddleWheel = {};

local AXIS = {
    HORIZ = 0,
    VERT = 1
};

function paddleWheel.register(id)
	npcManager.registerEvent(id, paddleWheel, "onTickNPC", "onTickPaddleWheel");
	npcManager.registerEvent(id, paddleWheel, "onDrawNPC", "onDrawPaddleWheel");
    lineguide.registerNpcs(id);

    lineguide.properties[id] = {
        lineSpeed = 0,
    }
end

function paddleWheel.onTickPaddleWheel(npc)

	local data = npc.data._basegame;
    
    local cfg = NPC.config[npc.id]
	local settings = npc.data._settings
	if data.wheel == nil then		
		if settings.number == nil then settings.number = 4; end
		if data.direction == nil then data.direction = npc.direction; end
		if settings.radius == nil then settings.radius = 64; end
		if settings.axis == nil then settings.axis = AXIS.HORIZ; end
		data.wheel = orbits.new{
			attachToNPC=npc,
			id=cfg.platformid,
			number=settings.number,
			radius=settings.radius,
			section=npc:mem(0x146, FIELD_WORD),
			rotationSpeed=0,
			angleDegs=npc.direction * (settings.startrot or 25),
			friendly=npc.friendly 
		};
	end
	if Defines.levelFreeze then return end
    local wheel = data.wheel;
    local maxRotSpeed = 64 * cfg.maxrotspeed / wheel.radius;
    
    if not cfg.autorotate then

        local off = 0;
        local ps = Player.get();
        
        for _, p in ipairs(ps) do
            local platform;
            
            if p.standingNPC then
                local standingNPC = p.standingNPC;
            
                for k, pf in ipairs(wheel.orbitingNPCs) do
                    if standingNPC == pf then
                        platform = pf;
                        
                        break;
                    end
                end
            end
            
            if platform then
                local xmod = 0.01 * (platform.x + platform.width / 2 - npc.x - npc.width / 2) / wheel.radius;
                local ymod = NPC.config[npc.id].resist * (npc.y - platform.y) / wheel.radius + 1;
                
                local speed = math.clamp(-maxRotSpeed, ymod * (wheel.rotationSpeed + xmod), maxRotSpeed);
                
                if math.abs(speed) < 0.05 and math.abs(npc.x + npc.width/2 - platform.x - platform.width / 2) < 1 then
                    wheel.rotationSpeed = 0;
                    
                    break;
                else
                    wheel.rotationSpeed = speed;
                end
            else
                off = off + 1;
            end
        end
		
        if wheel.rotationSpeed ~= 0 and off == #ps then
            wheel.rotationSpeed = wheel.rotationSpeed * 0.97;
            
            if math.abs(wheel.rotationSpeed) < 0.05 then
                wheel.rotationSpeed = 0;
            end
        end
    else
        wheel.rotationSpeed = maxRotSpeed
    end
	
	if npc.data._basegame.lineguide.state == lineguide.states.ONLINE then		
		npc.data._basegame.lineguide.lineSpeed = wheel.rotationSpeed * cfg.linespeedmultiplier;
	else
        if npc:mem(0x132, FIELD_WORD) == 0 then
            local mod = 1
            if cfg.autorotate then
                mod = data.direction
            end
			if settings.axis == AXIS.HORIZ then
				npc.speedX = cfg.speed * wheel.rotationSpeed * mod / maxRotSpeed;
			else
				npc.speedY = cfg.speed * wheel.rotationSpeed * mod / maxRotSpeed;
			end
		else
			npc.speedX = 0;
			
			if cfg.nogravity then
				npc.speedY = 0;
			else
				npc.speedY = -Defines.npc_grav;
			end
		end
	end
    if cfg.autorotate then
        wheel.rotationSpeed = maxRotSpeed * data.direction
    end
end

function paddleWheel.onDrawPaddleWheel(npc)
	local data = npc.data._basegame;

	if not data.wheel then return end
	
	if data.wheel.onscreen and data.wheel.onscreen > 0 then
		local p = -45.01;
		
		if NPC.config[npc.id].foreground then
			p = -15.01;
		end

		local x1 = npc.x + 0.5 * npc.width;
		local y1 = npc.y + 0.5 * npc.height;
		
		for _, platform in ipairs(data.wheel.orbitingNPCs) do
			if platform.isValid then			
				local x2 = platform.x + 0.5 * platform.width;
				local y2 = platform.y + 0.5 * platform.height;
				
				local rot = platform.data._orbits.rotationCounter - 0.5 * math.pi;

				Graphics.glDraw{
					vertexCoords={
						x1 - math.cos(rot), y1 - math.sin(rot),
						x2 - math.cos(rot), y2 - math.sin(rot),
						x1 + math.cos(rot), y1 + math.sin(rot),
						x2 + math.cos(rot), y2 + math.sin(rot)
					},
					primitive=Graphics.GL_TRIANGLE_STRIP,
					priority=p,
					sceneCoords=true
				};
			end
		end
	end
end

return paddleWheel