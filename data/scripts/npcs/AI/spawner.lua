-- Spawners! Well, what do they do? If you know Lunar Magic, they might seem familiar...
-- Put one down to make something happen when it comes onscreen.

local npcManager = require("npcmanager")
local npcutils = require("npcs/npcutils")

local spawner = {}

local spawnerSettings = {
	--Sprite size
	gfxheight = 32,
	gfxwidth = 32,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 32,
	height = 32,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 1,
	framestyle = 0,
	framespeed = 8, --# frames between frame change
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt=true,
	nogravity = true,
	noblockcollision = true,
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = true,
	--Various interactions
	jumphurt = true, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = true, --Held NPC hurts other NPCs if false
	harmlessthrown = true, --Thrown NPC hurts other NPCs if false

	grabside=false,
    grabtop=false,
    
    padding = 32 -- pixels of camera padding where spawn will still be registered
}

local spawnerMap = {}

function spawner.register(id, activationFunction)
    spawnerMap[id] = activationFunction
    npcManager.registerEvent(id, spawner, "onTickEndNPC", "onTickEndSpawner")
    npcManager.registerEvent(id, spawner, "onDrawNPC", "onDrawSpawner")
    npcManager.setNpcSettings(table.join(spawnerSettings, {id=id}));
end

-- Manually invoke the spawner function. Need to pass the equivalent to a v.data._settings table, and the camera to pass on.
function spawner.invoke(id, cam, settings)
    spawnerMap[id](cam, settings)
end

function spawner.onTickEndSpawner(v)
    if Defines.levelFreeze then return end
    local data = v.data._basegame
    if v.despawnTimer <= 0 then
        data.triggered = false
        data.preSpawned = false
        data.spawnedCamera = 0
        return
    end

    if v:mem(0x138, FIELD_WORD) > 0 then
        data.preSpawned = true
        return
    end

    if not data.triggered then
        data.triggered = true
        if data.preSpawned then
            Effect.spawn(147, v)
            SFX.play(66)
        end
        if camera2.isSplit or camera.isSplit then
            for k,c in ipairs(Camera.get()) do
                if c.x + c.width + 32 > v.x and c.x - 32 < v.x + v.width and c.y - 32 < v.y + v.height and c.y + c.height + 32 > v.y then
                    spawnerMap[v.id](c, v.data._settings)
                end
            end
        else
            if camera.x + camera.width + 32 > v.x and camera.x - 32 < v.x + v.width and camera.y - 32 < v.y + v.height and camera.y + camera.height + 32 > v.y then
                spawnerMap[v.id](camera, v.data._settings)
            end
        end
        v.despawnTimer = 0
        v:mem(0x124, FIELD_BOOL, false)
    end
end

function spawner.onDrawSpawner(v)
    if v.despawnTimer <= 0 then return end
    local data = v.data._basegame
    if not data.preSpawned then
        npcutils.hideNPC(v)
    end
end

return spawner