local powerblock = {}
local blockutils = require("blocks/blockutils")
local blockmanager = require("blockmanager")
local bowser = require("characters/bowser")
local megaman = require("characters/megaman")

local idMap = {}

function powerblock.register(id, value)
    blockmanager.registerEvent(id, blockutils, "onTickEndBlock", "bumpDuringTimeFreeze")
    idMap[id] = value
end

function powerblock.onInitAPI()
    registerEvent(powerblock, "onPostBlockHit")
end

local powerSounds = {}
powerSounds[1] = 5;
powerSounds[2] = 6;
powerSounds[3] = 6;
powerSounds[4] = 6;
powerSounds[7] = 6;

local powerNPCs = {}
powerNPCs[3] = 14;
powerNPCs[4] = 34;
powerNPCs[5] = 169;
powerNPCs[6] = 170;
powerNPCs[7] = 264;

local powerTimers = {}
powerTimers[2] = 48;
powerTimers[3] = 48;
powerTimers[4] = 0;
powerTimers[5] = 0;
powerTimers[6] = 0;
powerTimers[7] = 48;

local function setPowerup(p, power)
	if p:mem(0x140,FIELD_WORD) <= 0 and p:mem(0x13E,FIELD_WORD) == 0 and (p.powerup ~= power or (p.character==CHARACTER_BOWSER and power == 2 and bowser.getHP() == 1)) then
		Animation.spawn(10,p.x,p.y+p.height-16)

		if(powerNPCs[power] == nil) then
			if(powerSounds[power] ~= nil) then
					if(p.powerup > 2 and power == 2)  then
						playSFX(5)
					else
						playSFX(powerSounds[power])
					end
			else
				playSFX(34)
			end
			if(power == 2) then
				if(p.character==CHARACTER_BOWSER) then
					bowser.setHP(2);
				elseif(p.character==CHARACTER_MEGAMAN) then
					megaman.resetPowerups();
					megaman.resetHealth();
				end
			elseif(power == 1) then
				p.reservePowerup = 0
				if(p.character==CHARACTER_MEGAMAN) then
					megaman.resetPowerups();
					megaman.makeSmall();
				end
			end
			p.powerup = power;
			p:mem(0x140,FIELD_WORD,32)
		else
			local n = NPC.spawn(powerNPCs[power],p.x,p.y,p.section);
			n.data._fromPowerBlock = powerTimers[power];
		end
	end
	--Reset the reserve PW if one exists and on reset block.
	if p:mem(0x140,FIELD_WORD) == 0 and p:mem(0x13E,FIELD_WORD) == 0 and p.reservePowerup ~= 0 and power == 1 then
		p:mem(0x140,FIELD_WORD,32)
		p.reservePowerup = 0
		playSFX(powerSounds[power])
	end
end

function powerblock.onPostBlockHit(v, fromUpper, playerOrNil)
    if not idMap[v.id] then return end
    if playerOrNil ~= nil then
        setPowerup(playerOrNil,idMap[v.id]);
    end
end

return powerblock