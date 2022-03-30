--original by PixelPest but Enjl WAS evil and modified it BUT THEN...PixelPest modified it again so you could call this 1.2 or something
local altpsystem = {};

--GLOBAL CONSTANTS
altpsystem.SYSTEM_WII = 1; --one of three possible power-up systems based on NSMBWii
altpsystem.SYSTEM_DS = 2; --one of three possible power-up systems based on NSMBDS
altpsystem.SYSTEM_SMW = 3; --one of three possible power-up systems based on SMW

--GLOBAL VARIABLE
altpsystem.usingSystem = nil --the system as listed above that is being used
altpsystem.hideDeathAnim = false; --hides the death animation when the player falls into a pit

--LOCAL VARIABLES
local storedPower = false; --true if player has power-up other than mushroom
local canChange = false; --true if it is safe to change the player's power-up
local needChange = false; --true if the player's power-up needs to be changed
local disableInv = false
local doDisable = false
local storedFrames = 0

local deathAnims = {[1] = 3,
	[2] = 5,
	[3] = 129,
	[4] = 130,
	[5] = 134,
	[6] = 149,
	[7] = 150,
	[8] = 151,
	[9] = 152,
	[10] = 0, --no moving effect for Ninja Bomberman
	[11] = 154,
	[12] = 155,
	[13] = 156,
	[14] = 0, --no moving effect for Ultimate Rinka
	[15] = 158,
	[16] = 159,
	[17] = 0, --no moving effect for Princess Rinka
	[18] = 161};

function altpsystem.onInitAPI()
	registerEvent(altpsystem, "onDraw", "onDraw", false);
	registerEvent(altpsystem, "onTick", "onTick", false);
	registerEvent(altpsystem, "onNPCKill", "onNPCKill", false);
end

function altpsystem.onDraw()
	local section = Section(player.section);
	local bounds = section.boundary;

	if (altpsystem.hideDeathAnim) and
		(player:mem(0x13E, FIELD_WORD) > 0) and
		(player.y > (bounds.bottom + player.height + 2)) and
		(deathAnims[player.character] > 0) then --if the player is dead, well below the bottom section bound, and has a moving death animation
			for _, v in pairs(Animation.get(deathAnims[player.character])) do
				v.timer = 0; --terminate the playing of the death animation
			end
	end
end

function altpsystem.onTick()
	if altpsystem.usingSystem ~= nil then
		if player.powerup > 2 then --if the player has a power-up other than a mushroom
			storedPower = true;
		end
		
		if player.powerup == 1 then
			disableInv = true;
		end
		
		if (player:mem(0x122,FIELD_WORD) == 2) and (storedPower) then --if the player is powering down (hit by an ememy but not killed)
			needChange = true; --the player's power-up needs to be changed from default, but cannot be yet, as it will cause an error while powering down
		end
		
		if (player:mem(0x122,FIELD_WORD) ~= 2) and (needChange) then --if the player is not powering down
			player.powerup = PLAYER_BIG; --the player is now Big Mario
			canChange = false; --reset all values to false
			needChange = false;
			storedPower = false;
		end
		
		if ((player:mem(0x122,FIELD_WORD) == 1) or 
			(player:mem(0x122,FIELD_WORD) == 4) or 
			(player:mem(0x122,FIELD_WORD) == 5) or 
			(player:mem(0x122,FIELD_WORD) == 11) or 
			(player:mem(0x122,FIELD_WORD) == 12) or 
			(player:mem(0x122,FIELD_WORD) == 41)) and
			(disableInv) then
				doDisable = true;
				storedFrames = player:mem(0x140, FIELD_WORD);
		end
		
		if (player:mem(0x122,FIELD_WORD) == 0) and (doDisable) and (disableInv) then
			doDisable = false;
			disableInv = false;
			player:mem(0x140, FIELD_WORD, storedFrames);
		end
		
		if altpsystem.usingSystem == altpsystem.SYSTEM_WII then
			player.reservePowerup = 0; --scrap the reserve power-up system
		end
		
		if (player:mem(0x122,FIELD_WORD) == 2) and (altpsystem.usingSystem == altpsystem.SYSTEM_SMW) then --if the player is hurt while using SMW system
			player.dropItemKeyPressing = true; --make the item drop
		end
	end
end

function altpsystem.onNPCKill(killObj, killedNPC, killReason)
	if altpsystem.usingSystem == altpsystem.SYSTEM_SMW then
		if (killReason == 9) and
			(((killedNPC.id == 9) or
			(killedNPC.id == 184) or
			(killedNPC.id == 185)) and
			(killedNPC:mem(0x12A, FIELD_WORD) == 3600)) or
			((killedNPC.id == 250) and
			(killedNPC:mem(0x12A, FIELD_WORD) == 180)) then
				player.reservePowerup = killedNPC.id;
		end
	end
end

return altpsystem