local sprite = Graphics.loadImage("redbeetle.png")
local spritecounter = 0
local spriteswitch = 0
local redbeetle = {}

function redbeetle.onInitAPI()
    registerEvent(redbeetle, "onLoop", "ceilingChecker")
end

function redbeetle.ceilingChecker()
	spritecounter = spritecounter + 1
	if spritecounter == 8 then
		if spriteswitch == 0 then
			spriteswitch = 1
		elseif spriteswitch == 1 then
			spriteswitch = 0
		end
	spritecounter = 0
	end
	playercenter = player.x + player.width/2
	redbeetles = NPC.get(205, -1)
	for k,v in ipairs(redbeetles) do
		Defines.effect_Zoomer_killEffectEnabled = false
		v:mem(0x148, FIELD_FLOAT, -0.1)
		Text.print(v.direction,0,0)
		
		if v.direction == -1 then
			if v:mem(0x0A, FIELD_WORD) > 0 then --floor
				if spriteswitch == 0 then
				Graphics.drawImageToSceneWP(sprite,v.x,v.y,0,0,v.width,v.height,-45)
				elseif spriteswitch == 1 then
				Graphics.drawImageToSceneWP(sprite,v.x,v.y,0,1*v.height,v.width,v.height,-45)
				end
			elseif v:mem(0x0C, FIELD_WORD) > 0 then -- left wall
				if v.speedY < 0 then -- check if it crawls up bc redgit was drunk
					if spriteswitch == 0 then
					Graphics.drawImageToSceneWP(sprite,v.x,v.y,0,4*v.height,v.width,v.height,-45)
					elseif spriteswitch == 1 then
					Graphics.drawImageToSceneWP(sprite,v.x,v.y,0,5*v.height,v.width,v.height,-45)
					end
				elseif v.speedY > 0 then -- check if it crawls down bc redgit was drunk
					if spriteswitch == 0 then
					Graphics.drawImageToSceneWP(sprite,v.x,v.y,0,6*v.height,v.width,v.height,-45)
					elseif spriteswitch == 1 then
					Graphics.drawImageToSceneWP(sprite,v.x,v.y,0,7*v.height,v.width,v.height,-45)
					end
				end
			elseif v:mem(0x0E, FIELD_WORD) > 0 then -- ceiling
				if spriteswitch == 0 then
				Graphics.drawImageToSceneWP(sprite,v.x,v.y,0,8*v.height,v.width,v.height,-45)
				elseif spriteswitch == 1 then
				Graphics.drawImageToSceneWP(sprite,v.x,v.y,0,9*v.height,v.width,v.height,-45)
				end
			elseif v.ai5 > 0 then -- when turning
				Graphics.drawImageToSceneWP(sprite,v.x,v.y,0,4*v.height,v.width,v.height,-45)
			end
		elseif v.direction == 1 then
			if v:mem(0x0A, FIELD_WORD) > 0 then --floor
				if spriteswitch == 0 then
				Graphics.drawImageToSceneWP(sprite,v.x,v.y,0,2*v.height,v.width,v.height,-45)
				elseif spriteswitch == 1 then
				Graphics.drawImageToSceneWP(sprite,v.x,v.y,0,3*v.height,v.width,v.height,-45)
				end
			elseif v:mem(0x10, FIELD_WORD) > 0 then -- right wall
				if v.speedY < 0 then -- check if it crawls up bc redgit was drunk
					if spriteswitch == 0 then
					Graphics.drawImageToSceneWP(sprite,v.x,v.y,0,12*v.height,v.width,v.height,-45)
					elseif spriteswitch == 1 then
					Graphics.drawImageToSceneWP(sprite,v.x,v.y,0,13*v.height,v.width,v.height,-45)
					end
				elseif v.speedY > 0 then -- check if it crawls down bc redgit was drunk
					if spriteswitch == 0 then
					Graphics.drawImageToSceneWP(sprite,v.x,v.y,0,14*v.height,v.width,v.height,-45)
					elseif spriteswitch == 1 then
					Graphics.drawImageToSceneWP(sprite,v.x,v.y,0,15*v.height,v.width,v.height,-45)
					end
				end
			elseif v:mem(0x0E, FIELD_WORD) > 0 then -- ceiling
				if spriteswitch == 0 then
				Graphics.drawImageToSceneWP(sprite,v.x,v.y,0,10*v.height,v.width,v.height,-45)
				elseif spriteswitch == 1 then
				Graphics.drawImageToSceneWP(sprite,v.x,v.y,0,11*v.height,v.width,v.height,-45)
				end
			elseif v.ai5 > 0 then -- when turning
				Graphics.drawImageToSceneWP(sprite,v.x,v.y,0,12*v.height,v.width,v.height,-45)
			end
		end
		if playercenter >= v.x-32 and playercenter <= v.x+32 and player.y > v.y and v.id ~= 285 then
				if v:mem(0x0E, FIELD_WORD) == 2 or v:mem(0x0C, FIELD_WORD) == 2 or v:mem(0x10, FIELD_WORD) == 2 then
					v.id = 285
				end
		end
		if player:mem(0x146, FIELD_WORD) == 0 and player.y + player.height == v.y and v.id ~= 174 and v:mem(0x0A, FIELD_WORD) == 2 and playercenter >= v.x-32 and playercenter <= v.x+32 then
			 v.id = 174
			 SFX.play(2)
		end
	end
	
	redshells = NPC.get(285,-1)
	for k,v in ipairs(redshells) do
			if v.id ~= 205 and v:mem(0x0A, FIELD_WORD) == 2 then
				v:mem(0xE4, FIELD_WORD, 2)
				v.id = 205
			end
	end
end

return redbeetle