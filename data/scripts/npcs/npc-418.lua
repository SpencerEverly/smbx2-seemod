local arrowLift = {}

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

arrowLift.ghostdir = {0, 1, 0, 2}
local npcID = NPC_ID

local config = npcManager.setNpcSettings({
	id = npcID,
	gfxwidth = 0,
	gfxheight = 0,
	width = 64,
	height = 32,
	frames = 5,
	framespeed = 8,
	framestyle = 0,
	score = 0,
	npcblocktop = true,
	playerblocktop = true,
	playerblock = false,
	npcblock = false,
	nohurt = true,
	nogravity = true,
	noblockcollision = true,
	noiceball = true,
	noyoshi = true,
	foreground = true,
	notcointransformable = true,
	nospecialanimation = false,
	dirlist = {0, 1, 0, 2},
	life = 500,
	speed = 1
})

local function ghostDataCheck(npc)
	local data = npc.data._basegame
	local settings = npc.data._settings
	if settings.type == -1 then
		settings.type = config.dirlist[1]
	end
	if data.onLand == nil then
		data.onLand = {}
		settings.type = settings.type or 0
		settings.sp = settings.sp or false
		data.spdir = 1
		data.animation = 0
		data.timer = 0
		data.parent = nil
		if not settings.override then
			settings.life = config.life
			settings.speed = config.speed
		end
	end
end

function arrowLift.onTickEndNPC(npc)
	if Defines.levelFreeze or npc:mem(0x12A, FIELD_WORD) <= 0 then return end
	local data = npc.data._basegame
	if npc.direction == 0 then npc.direction = 1 end
	ghostDataCheck(npc)

	if data.animation > 0 then
		data.animation = data.animation - 1
	end
	local settings = npc.data._settings
	if npc:mem(0x12E, FIELD_WORD) == 0 then -- 0x12E: If not being grabbed
		data.timer = data.timer + 1
		if data.timer >= settings.life and settings.life > 0 then
			npc:kill()
		end
	end

	--if ghost is in Jump Mode (sp)
	if settings.sp then
		local pjump = {}
		for _, p in ipairs(Player.get()) do
			if p.standingNPC then
				pjump[p.idx] = p.standingNPC == npc
			end
			-- This is true the first frame the player jumps on the NPC
			if pjump[p.idx] and not data.onLand[p.idx] and data.timer > 1 then
				data.animation = 8
				data.spdir = data.spdir + 1
				if data.spdir > #config.dirlist then
					data.spdir = 1
				end
				settings.type = config.dirlist[data.spdir]
			end
		end
		data.onLand = pjump
	end

	--set speed depending on direction
	if settings.type == 0 then
		npc.speedX = 0
		npc.speedY = -settings.speed
	elseif settings.type == 1 then
		npc.speedX = -settings.speed
		npc.speedY = 0
	elseif settings.type == 2 then
		npc.speedX = settings.speed
		npc.speedY = 0
	elseif settings.type == 3 then
		npc.speedX = 0
		npc.speedY = settings.speed
	end

	if not config.nospecialanimation then
		local t = settings.type + 1
		if data.animation > 0 then
			t = 5
		elseif not (data.timer < settings.life - 120 or data.timer%6 <= 2) and settings.life > 0 then
			t = 0
		end
		local tf = config.frames * 0.2
		local offset = (t-1) * tf
		local gap = config.frames - (5-t) * tf
		npcutils.restoreAnimation(npc)
		npc.animationFrame = npcutils.getFrameByFramestyle(npc, {
			frames = tf,
			offset = offset,
			gap = gap
		})
	end
end

function arrowLift.onInitAPI()
	npcManager.registerEvent(npcID, arrowLift, "onTickEndNPC")
end

return arrowLift

--BASE
-- npc.data.type {
-- 	/What Type?
--    0 = !
-- 	  1 = Up
-- 	  2 = Left
-- 	  3 = Right
--   }
-- npc.data.life {
--   /How long should the ghost created last?
--   }
-- npc.data.speed {
--   /He speed
-- }

--Ghost
-- npc.data.type {
-- 	/Direction?
-- 	0 = up
-- 	1 = Left
-- 	2 = Right
-- }
-- npc.data.sp {
-- 	/Should change direction when jumped on?
-- 	true = Yes
-- 	false = No
-- }
-- npc.data.life {
--   /How long should the ghost last?
-- }
-- npc.data.speed {
--   /He speed
-- }
