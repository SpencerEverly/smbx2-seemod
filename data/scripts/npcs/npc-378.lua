local npcManager = require("npcManager");
local utils = require("npcs/npcutils")

local popupCoins = {};

local npcID = NPC_ID;

npcManager.setNpcSettings({
	id = npcID, 
	gfxwidth = 32, 
	gfxheight = 32, 
	width = 32, 
	height = 32, 
	frames = 2,
	framespeed = 8;
	score = 0,
	playerblock = false,
	npcblock = false,
	nogravity = true,
	harmlessgrab=true,
	noblockcollision = true,
	nofireball = true,
	noiceball = true,
	noyoshi = true,
	grabside = false,
	ignorethrownnpcs = true,
	isshoe = false,
	isyoshi = false,
	nohurt = true,
	jumphurt = true,
	notcointransformable = true,
	defaultcontents=10
});

npcManager.registerHarmTypes(npcID, {}, {});

local shader = Misc.multiResolveFile("popupcoin.frag", "shaders\\npc\\popupcoin.frag")

function popupCoins.onInitAPI()
	npcManager.registerEvent(npcID, popupCoins, "onTickEndNPC");
	npcManager.registerEvent(npcID, popupCoins, "onDrawNPC");
end

function popupCoins.onTickEndNPC(v)
	if v:mem(0x12A, FIELD_WORD) <= 0 then return end
	
	local data = v.data._basegame;

	if v.ai1 <= 0 then v.ai1 = NPC.config[v.id].defaultcontents end

	local cfg = NPC.config[v.ai1];
	local h = cfg.gfxheight * 0.5;
	local w = cfg.gfxwidth * 0.5;
	if(h == 0) then
		h = cfg.height;
	end
	if(w == 0) then
		w = cfg.width;
	end

	local x, y = v.x + 0.5 * v.width - w, v.y + 0.5 * v.height - h

	if not cfg.noblockcollision then
		y = v.y + v.height - 2 * h
	end

	x, y = x + cfg.gfxoffsetx, y + cfg.gfxoffsety

	local players = Player.getIntersecting(x, y, x + 2*w, y+2*h);
	
	if #players > 0 then
		data.intersecting = true;
		data.direction = players[1].direction
	end
	
	if Defines.levelFreeze then return end
	local lspdx,lspdy = utils.getLayerSpeed(v)
	v.x = v.x + lspdx
	v.speedY = lspdy
	if (#players == 0) and data.intersecting then
		data.intersecting = false;
		local d = data.direction
		v:transform(v.ai1, true, true);
		SFX.play(29)
		v.direction = d
		v.speedX = 0
		v.speedY = 0
	end
end

function popupCoins.onDrawNPC(v)

	if(type(shader) == "string") then
		local s = Shader();
		s:compileFromFile(nil, shader);
		shader = s;
	end
	
	if v.ai1 <= 0 then v.ai1 = 10 end
	
	local id = v.ai1;
	if(id > 0) then
		local i = Graphics.sprites.npc[id].img;
		local cfg = NPC.config[id];
		local h = cfg.gfxheight;
		local w = cfg.gfxwidth;
		if(h == 0) then
			h = cfg.height;
		end
		if(w == 0) then
			w = cfg.width;
		end
		
		local x,y = v.x + v.width * 0.5 - w*0.5, v.y + v.height * 0.5 - h*0.5;

		if not cfg.noblockcollision then
			y = v.y + v.height - h
		end
		
		x = x + cfg.gfxoffsetx;
		y = y + cfg.gfxoffsety;
		
		Graphics.drawBox{
							x = x, y = y, 
							textureCoords = {0,0,1,0,1,h/i.height,0,h/i.height}, 
							width = w, height = h, 
							shader = shader, texture = i, 
							uniforms = { iResolution = {i.width, i.height, 0}, maxh = h/i.height, val = v.animationFrame % 2},
							priority=-55, sceneCoords=true
						}
	end
end

return popupCoins