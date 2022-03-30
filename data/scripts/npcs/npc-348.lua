local npcManager = require("npcManager")

local panser = {}

local npcID = NPC_ID

npcManager.setNpcSettings({
	id=npcID,
	width=20,
	height=20,
	gfxheight=32,
	gfxwidth=32,
	framestyle=1,
	framespeed=4,
	frames=3,
	gfxoffsety=4,
	ignorethrownnpcs = true,
	linkshieldable = true,
	noblockcollision=true,
	spinjumpsafe = false,
	npcblock=false,
	effectID=10,
	lightradius=64,
	lightcolor=Color.orange,
	lightbrightness=1,
	jumphurt=true,
	nofireball=true,
	ishot = true,
	durability = 3
})

npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_SWORD,
		HARM_TYPE_LAVA
	}, 
	{
		[HARM_TYPE_FROMBELOW]=10,
		[HARM_TYPE_NPC]=10,
		[HARM_TYPE_HELD]=10,
		[HARM_TYPE_TAIL]=10,
		[HARM_TYPE_PROJECTILE_USED]=10,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}
	}
);

function panser.onInitAPI()
	npcManager.registerEvent(npcID, panser, "onTickEndNPC")
end

--Fireballs
function panser.onTickEndNPC(v)
	--Local variable for data
	local data = v.data._basegame
	
	if not data.ally then return end

	-- If not offscreen
	if  v:mem(0x12A, FIELD_WORD) > 0  then
			--v.friendly = true
		for k,n in ipairs(Colliders.getColliding{
			a = v,
			b = NPC.HITTABLE,
			btype = Colliders.NPC,
			filter = function(w)
				if (not w.isHidden) and w:mem(0x64, FIELD_BOOL) == false and w:mem(0x12A, FIELD_WORD) > 0 and w:mem(0x138, FIELD_WORD) == 0 and w:mem(0x12C, FIELD_WORD) == 0 then
					return true
				end
				return false
			end
		}) do
			v:kill(3)
			n:harm(3)
			return
		end
	end
end

return panser
