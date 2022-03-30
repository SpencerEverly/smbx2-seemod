local smallSwitch = {}

local npcManager = require("npcManager")
local switchcolors = require("switchcolors")

smallSwitch.sharedSettings = {
	gfxwidth = 32,
	gfxheight = 32,
	gfxoffsetx = 0,
	gfxoffsety = 2,
	width = 32,
	height = 32,
	nogravity = false,
	frames = 1,
	framestyle = 0,
	framespeed = 8,
	noblockcollision = false,
	playerblock = true,
	playerblocktop = true,
	npcblock = true,
	npcblocktop = true,
	speed = 1,
	foreground = 0,
	jumphurt = true,
	nohurt = true,
	score = 0,
	noiceball = true,
	nowaterphysics = false,
	foreground = true,
	noyoshi = false,
	grabside = true,
	harmlessgrab = true,
	harmlessthrown = true,
	ignorethrownnpcs = true,
	--Custom settings
	switchon = true, --Whether the switch transforms "off" blocks into "on" blocks.
	switchoff = true, --Whether the switch transforms existing "on" blocks into off blocks.
	blockon = 1, --The ID of the switch's "on" blocks.
	blockoff = 2, --The ID of the switch's "off" blocks.
	effect = 81,
	iscustomswitch = true
}

local settings = {}
smallSwitch.settings = settings

local topCollisionBox = Colliders.Box(0,0,0,1)

local switchColorFunctions = {}

function smallSwitch.registerSwitch(config)
	if settings[id] ~= nil then
		error("This NPC is already registered as a switch. Use NPC.config to change the settings of registered switches.")
	end
	local customSettings = table.join(config, smallSwitch.sharedSettings)
	settings[customSettings.id] = npcManager.setNpcSettings(customSettings)
	npcManager.registerEvent(customSettings.id, smallSwitch, "onTickNPC")
	local func, col = switchcolors.registerColor(customSettings.color)
	switchColorFunctions[col] = func
end

local function doSwitch(settings)
	local blocks_a = Block.get(settings.blockoff)
	local blocks_b = Block.get(settings.blockon)
	if settings.switchon and settings.switchon ~= 0 then
		for _,v in ipairs(blocks_a) do
			v.id = settings.blockon
		end
	end
	if settings.switchoff and settings.switchoff ~= 0 then
		for _,v in ipairs(blocks_b) do
			v.id = settings.blockoff
		end
	end
	switchColorFunctions[switchcolors.colors[settings.color]]()
end

function smallSwitch:press()
	doSwitch(NPC.config[self.id])
	SFX.play(32)
	Animation.spawn(NPC.config[self.id].effect, self.x, self.y)
	self:kill()
end

function smallSwitch:onTickNPC()
	if Defines.levelFreeze then
		return
	end
	self.speedX = self.speedX * 0.96 --temporary, how exactly do you do this?
	if math.abs(self.speedX) < 0.1 then
		self.speedX = 0
	end
	for _,p in ipairs(Player.get()) do
		if p.standingNPC ~= nil and self.idx == p.standingNPC.idx then --temporary, when we get FFI NPCs, they should be cached so the objects themselves should be equal
			smallSwitch.press(self)
			break
		end
	end
	if self:mem(0x12A, FIELD_WORD) <= 0 or self:mem(0x138, FIELD_WORD) > 0 or self:mem(0x12C, FIELD_WORD) > 0 or self.friendly then
		return
	end
	topCollisionBox.x = self.x
	topCollisionBox.y = self.y - 1
	topCollisionBox.width = self.width
	for k,v in ipairs(Colliders.getColliding{
		a = topCollisionBox,
		b = NPC.HITTABLE .. NPC.UNHITTABLE,
		btype = Colliders.NPC,
		filter = function(other)
			return NPC.config[other.id].isheavy
		end
	}) do
		if v:mem(0x12A, FIELD_WORD) > 0 and v:mem(0x138, FIELD_WORD) == 0 and v:mem(0x12C, FIELD_WORD) == 0 then
			smallSwitch.press(self)
			break
		end
	end

end

return smallSwitch