local __title = "SMB3 Inventory Mod";
local __version = "1.0";
local __description = "Adds a inventory to the world map.";
local __author = "XNBlank";
local __url = "https://github.com/XNBlank";

local smbthreeInventory_API = {}

local resPath = getSMBXPath() .. "\\scripts\\Legacy\\smb3inventory"; --res path
local bg = Graphics.loadImage(resPath .. "\\back.png");
local mushroom = Graphics.loadImage(resPath .. "\\mushroom.png");
local flower = Graphics.loadImage(resPath .. "\\flower.png");
local leaf = Graphics.loadImage(resPath .. "\\leaf.png");
local hammer = Graphics.loadImage(resPath .. "\\hammer.png");
local tanooki = Graphics.loadImage(resPath .. "\\tanooki.png");
local iceflower = Graphics.loadImage(resPath .. "\\iceflower.png");
local selection = Graphics.loadImage(resPath .. "\\selection.png");

local invOpen = false;
local openTimer = 60;
local items = {mushroom,flower,leaf,hammer,tanooki,iceflower};
local slots = {1,2,3,4,5,6};
local thisSlot = 1;
local player = Player();

local selectionx = 290;
local selectiony = 85;

function smbthreeInventory_API.onInitAPI()
	if(m_type == LUNALUA_WORLD) then
		_G["isOverworld"] = true;
	end
	registerEvent(smbthreeInventory_API, "onLoop", "onLoopOverride");
	registerEvent(smbthreeInventory_API, "onInputUpdate", "onInputUpdateOverride");
end

function smbthreeInventory_API.onLoopOverride()

	Graphics.activateOverworldHud(WHUD_NONE);

	--Text.print(tostring(openTimer), 0, 0);
	--Text.print(tostring(player.dropItemKeyPressing), 0, 16);
	if(invOpen == false) then
		Text.print("Press RUN to open the Inv", 250, 100);
	elseif(invOpen == true) then
		Text.print("Press \"DROP ITEM\" to use item.", 245, 55);
	end
	--Graphics.placeSprite(1,bg,280,75);

	if(thisSlot > 6) then
		thisSlot = 1;
	end

	if(thisSlot < 1) then
		thisSlot = 6;
	end

	if(openTimer >= 60) then
		openTimer = 60;
	end

	if(openTimer <= 0) then
		openTimer = 0;
	end

	if(invOpen) then
		if(thisSlot == 1) then
			Graphics.unplaceSprites(selection);
			Graphics.placeSprite(1,selection,selectionx,selectiony);
		elseif(thisSlot == 2) then
			Graphics.unplaceSprites(selection);
			Graphics.placeSprite(1,selection,selectionx+40,selectiony);
		elseif(thisSlot == 3) then
			Graphics.unplaceSprites(selection);
			Graphics.placeSprite(1,selection,selectionx+80,selectiony);
		elseif(thisSlot == 4) then
			Graphics.unplaceSprites(selection);
			Graphics.placeSprite(1,selection,selectionx+120,selectiony);
		elseif(thisSlot == 5) then
			Graphics.unplaceSprites(selection);
			Graphics.placeSprite(1,selection,selectionx+160,selectiony);
		elseif(thisSlot == 6) then
			Graphics.unplaceSprites(selection);
			Graphics.placeSprite(1,selection,selectionx+200,selectiony);
		end
	end

	if(player.runKeyPressing == true) and (invOpen == false) and (openTimer >= 60) then
		Graphics.placeSprite(1,bg,280,75);
		Graphics.placeSprite(1,items[1], 290, 85);
		Graphics.placeSprite(1,items[2], 330, 85);
		Graphics.placeSprite(1,items[3], 370, 85);
		Graphics.placeSprite(1,items[4], 410, 85);
		Graphics.placeSprite(1,items[5], 450, 85);
		Graphics.placeSprite(1,items[6], 490, 85);
		invOpen = true;
		playSFXSDL(resPath .. "\\inv.wav");
		openTimer = openTimer - 30;
	elseif(player.runKeyPressing == true) and (invOpen == true) and (openTimer >= 60) then
		Graphics.unplaceSprites(bg);
		Graphics.unplaceSprites(items[1]);
		Graphics.unplaceSprites(items[2]);
		Graphics.unplaceSprites(items[3]);
		Graphics.unplaceSprites(items[4]);
		Graphics.unplaceSprites(items[5]);
		Graphics.unplaceSprites(items[6]);
		Graphics.unplaceSprites(selection);
		invOpen = false;
		playSFXSDL(resPath .. "\\inv.wav");
		openTimer = openTimer - 30;
	else
		openTimer = openTimer + 1;
	end



end

function smbthreeInventory_API.onInputUpdateOverride()


	if(invOpen) then
		if(player.dropItemKeyPressing == true) and (openTimer >= 60) then
			if(thisSlot == 1) then
				if(player.powerup <= 1) then
					player.powerup = 2;
                    world.playerPowerup = 2;
				end
			elseif(thisSlot == 2) then
				player.powerup = 3;
                world.playerPowerup = 3;
            elseif(thisSlot == 3) then
				player.powerup = 4;
                world.playerPowerup = 4;
			elseif(thisSlot == 4) then
				player.powerup = 6;
                world.playerPowerup = 6;
			elseif(thisSlot == 5) then
				player.powerup = 5;
                world.playerPowerup = 5;
			elseif(thisSlot == 6) then
				player.powerup = 7;
                world.playerPowerup = 7;
			end
			playSFXSDL(resPath .. "\\powerup.wav");
			openTimer = openTimer - 59;
			player.dropItemKeyPressing = false;
		end

		if(player.rightKeyPressing == true) and (openTimer >= 60) then
			thisSlot = thisSlot + 1;
			openTimer = openTimer - 15;
			playSFXSDL(resPath .. "\\slide.ogg");
		end

		if(player.leftKeyPressing == true) and (openTimer >= 60) then
			thisSlot = thisSlot - 1;
			openTimer = openTimer - 15;
			playSFXSDL(resPath .. "\\slide.ogg");
		end
	end

	if(invOpen) then
			player.upKeyPressing = false;
			player.downKeyPressing = false;
			player.leftKeyPressing = false;
			player.rightKeyPressing = false;
			player.jumpKeyPressing = false;
			player.altJumpKeyPressing = false;
	end

end


return smbthreeInventory_API;