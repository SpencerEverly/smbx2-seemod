local npcManager = require("npcManager");
local npcutils = require("NPCs/npcutils");

local tiltlift = {};

tiltlift.UP = 1;
tiltlift.RIGHT = 2;
tiltlift.DOWN = 3;
tiltlift.LEFT = 4;

tiltlift.speeds = {
	[tiltlift.UP] = {x = 0, y = -1},
	[tiltlift.RIGHT] = {x = 1, y = 0},
	[tiltlift.DOWN] = {x = 0, y = 1},
	[tiltlift.LEFT] = {x = -1, y = 0}
};

local defaultConfig = {
	gfxheight = 32,
    height = 32,
    gfxwidth=32,
    width=32,
	frames = 1,
	nogravity = true,
	noblockcollision = true,
	playerblock = false,
    playerblocktop = true,
    ignorethrownnpcs = true,
	npcblock = true,
	npcblocktop = true,
	nohurt = true,
    noyoshi = true,
    nofireball=1,
    noiceball=1,
	notcointransformable = true,
    
    inertia = 32, --laziness when switching directions, higher is lazier
    defaultarrow = 0, --which arrow to default to when the player steps off. 0 = none, -1 = keepMoving
    needsactivation = true, --do we need to step on it once before it moves in defaultArrow direction?
    inset = 0, --maybe we don't want arrows hugging the edges???
    effectid = 266, --arrow effect, we're only using the sprite though
};

local tiltliftconfigs = {}

local tiltliftIDs = {}

--Arrow directions are vararg
function tiltlift.register(id, npcsettings, ...)
    local arrows = {...}

    npcManager.setNpcSettings(table.join({id = id}, npcsettings or {}, defaultConfig))

    tiltliftconfigs[id] = {
        arrows = arrows,
    }

    table.insert(tiltliftIDs, id)
    npcManager.registerEvent(id, tiltlift, "onTickNPC");
    npcManager.registerEvent(id, tiltlift, "onDrawNPC");
end

function tiltlift.onInitAPI()
    registerEvent(tiltlift, "onStart")
end

function tiltlift.onStart()
    for k,v in ipairs(tiltliftIDs) do
        local cfg = NPC.config[v]
        tiltliftconfigs[v].speed = cfg.speed
        cfg.speed = 1


        if cfg.inertia and cfg.inertia <= 0 then
            cfg.inertia = 1
        end

        local arrows = tiltliftconfigs[v].arrows
    
        local arrowPositions = {}
        local width = cfg.width - 32 - 2 * cfg.inset

        --No room for this many arrows!
        for i=#arrows, math.floor(width/32), -1 do
            arrows[i] = nil
        end


        if #arrows == 1 then
            arrowPositions[1] = width * 0.5
        else
            for k,v in ipairs(arrows) do
                arrowPositions[k] = (k-1) * width/(#arrows-1)
            end
        end
        tiltliftconfigs[v].arrowPositions = arrowPositions
    end
end

function tiltlift.onTickNPC(v)
	if Defines.levelFreeze then return end

	local data = v.data._basegame;

	if v:mem(0x12A, FIELD_WORD) <= 0 then
		data.init = false
	end
    
    local cfg = NPC.config[v.id]

    local tlc = tiltliftconfigs[v.id]

	if not data.init then
		data.direction = 0; --deactivated
		data.incSpeedX, data.incSpeedY = 0, 0;
		data.incCounter = 0;
        data.currentActivePlayer = nil
        if not cfg.needsactivation then
            if cfg.defaultarrow > 0 then
                data.direction = tlc.arrows[math.min(cfg.defaultarrow, #tlc.arrows)]
            end
        end
        data.prevDirection = data.direction;
        data.init = true
    end

    if v:mem(0x136, FIELD_BOOL) then
        v:mem(0x136, FIELD_BOOL, false)
        v.speedX = 0
        v.speedY = 0
    end

    if data.currentActivePlayer == nil then
        for k,p in ipairs(Player.get()) do
            if p:mem(0x13E, FIELD_WORD) == 0 then
                local standingNPC = p.standingNPC;
            
                if (standingNPC) and (standingNPC == v) then
                    data.currentActivePlayer = p
                    data.active = true
                end
            end
        end
    end
    
    if data.currentActivePlayer then
        local p = data.currentActivePlayer
        local playerXOffset = player.x + player.width * 0.5 - v.x

        if p.standingNPC and p.standingNPC == v then
            for k,o in ipairs(tlc.arrowPositions) do
                if playerXOffset >= o and playerXOffset < o + 32 then
                    data.direction = tlc.arrows[k]
                    break
                end
            end
        else
            data.currentActivePlayer = nil
            if cfg.defaultarrow > 0 then
                data.direction = tlc.arrows[math.min(cfg.defaultarrow, #tlc.arrows)]
            elseif cfg.defaultarrow == 0 then
                data.direction = 0
                v.speedX = 0
                v.speedY = 0
            end
        end
    end

	if data.direction > 0 and not v.dontMove then
        local speeds = tiltlift.speeds[data.direction];
        local sx = speeds.x * tlc.speed
        local sy = speeds.y * tlc.speed
	
		if data.direction ~= data.prevDirection then
			if sx ~= v.speedX then
				data.incSpeedX = (sx - v.speedX)/cfg.inertia;
			end
			
			if sy ~= v.speedY then
				data.incSpeedY = (sy - v.speedY)/cfg.inertia;
			end
			data.incCounter = cfg.inertia;
		end
		
		if data.incCounter > 0 then
			if math.abs(v.speedX) < math.abs(sx) then
				v.speedX = v.speedX + data.incSpeedX * tlc.speed;
			else
				data.incSpeedX = 0;
			end

			if math.abs(v.speedY) < math.abs(sy) then
				v.speedY = v.speedY + data.incSpeedY  * tlc.speed;
			else
				data.incSpeedY = 0;
			end
			
			data.incCounter = data.incCounter - 1;
		else
			v.speedX, v.speedY = sx, sy;
		end
	end
	
	data.prevDirection = data.direction;
end

function tiltlift.onDrawNPC(v)
	if Defines.levelFreeze then return end

	if v:mem(0x12A, FIELD_WORD) <= 0 then
		return
	end
	
	local data = v.data._basegame;
    
    if not data.init then return end

    local cfg = NPC.config[v.id]

    local tlc = tiltliftconfigs[v.id]
	
    local arrowImage = Graphics.sprites.effect[cfg.effectid].img
    
    local p = -45
    if cfg.foreground then p = -15 end
    npcutils.drawNPC(v)
    npcutils.hideNPC(v)
    for k,a in ipairs(tlc.arrowPositions) do
        local yOffset = 0
        if tlc.arrows[k] == data.direction then
            yOffset = 32
        end
        local xOffset = 32 * (tlc.arrows[k] - 1)
        Graphics.drawImageToSceneWP(arrowImage, v.x + a + cfg.gfxoffsetx, v.y + cfg.gfxoffsety, xOffset, yOffset, 32, 32, p)  
    end
end

return tiltlift