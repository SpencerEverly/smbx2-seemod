local npcManager = require("npcManager")
local colliders = require("colliders")

local hiddenItem = {}

local npcID = NPC_ID

local regularSettings = {
	id = npcID,
	gfxheight = 32,
	gfxwidth = 32,
	width = 32,
	height = 32,
	frames = 1,
	framespeed=6,
	framestyle = 0,
	nohurt = 1,
	jumphurt = 1,
	ignorethrownnpcs = true,
	nogravity = 1,
	nofireball=-1,
	noiceball=-1,
	noyoshi=-1,
	cliffturn=0, 
	noblockcollision=-1,
	notcointransformable = true
}

npcManager.setNpcSettings(regularSettings)

function hiddenItem.onInitAPI()
	npcManager.registerEvent(npcID, hiddenItem, "onTickNPC", "onTickItem")
	registerEvent(hiddenItem, "onTickEnd");
end

local hiddenItems = {};

local function transform(p, v)
	if colliders.collide(p, v) then
		v:transform(v.ai1)
		v.speedY = -10
		v.direction = p.direction
		v.speedX = p.direction
		v:mem(0xDC, FIELD_WORD, 0)
		if(not v.friendly) then
			v.friendly = true
			v.data._basegame = {}
			v.data._basegame.itemReleaseTimer = 50
			table.insert(hiddenItems, v);
		end
		SFX.play(7)
	end
end

function hiddenItem.onTickItem(v)
	if v.isHidden or v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x124, FIELD_WORD) == 0 then
		return;
	end
	
	if v.ai1 > 0 then
		transform(player, v)
		if player2 then
			transform(player2, v)
		end
	end
end

function hiddenItem.onTickEnd()
	if Defines.levelFreeze then return end
	for i = #hiddenItems,1,-1 do
		local v = hiddenItems[i];
		if (v.isValid and not v.isHidden and v:mem(0x12A, FIELD_WORD) > 0) then
			v.data._basegame.itemReleaseTimer = v.data._basegame.itemReleaseTimer - 1
			if (v.data._basegame.itemReleaseTimer == 0) then
				v.friendly = false;
				table.remove(hiddenItems,i);
			end
		end
	end
end
	
return hiddenItem