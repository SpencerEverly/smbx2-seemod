--classExpander.lua
--v1.0.1
--Created by Horikawa Otane, 2016
--Contact me at https://www.youtube.com/subscription_center?add_user=msotane

local rng = require("rng");
local testmodemenu
local playerManager;
--local megashroom = require("NPCs/megashroom"); -- Used for invincibility checking

local useOldLevelLoad = true

local EP_LIST_PTR = mem(0x00B250FC, FIELD_DWORD);

local ce = {}

function ce.onInitAPI()
	registerEvent(ce, "onStart")
end

function ce.onStart()
	if Misc.inEditor() and not isOverworld then
		testmodemenu = require("engine/testmodemenu")
	end
end

do
	local player_visible_animstates = 
	{
		[0] = true,
		[1] = true,
		[2] = true,
		[3] = true,
		[4] = true,
		[5] = true,
		[6] = true,
		[7] = true,
		[8] = false,
		[9] = true,
		[10] = false,
		[11] = true,
		[12] = true,
		[41] = true,
		[499] = true, --Mega mode transition
		[500] = true,
	}
	
	
	--Draws a sprite using mount settings
	local function drawMount(self, x, y, args, width, height, frame, img, sceneCoords, p)
	
		--Compute frame y coordinate and height, in texture space
		local fy = (frame*height)/img.height;
		local fh = height/img.height;
		--Draw the sprite
		Graphics.glDraw	{
							vertexCoords = 	{x, y, x + width, y, x + width, y + height, x, y + height},
							textureCoords = {0, fy, 1, fy, 1, fy+fh, 0, fy+fh},
							primitive = Graphics.GL_TRIANGLE_FAN,
							texture = img,
							sceneCoords = sceneCoords,
							priority = args.priority or p,
							shader = args.mountshader,
							uniforms = args.mountuniforms,
							attributes = args.mountattributes,
							color = args.mountcolor or args.color,
							target = args.target
						}
	end
	
	local clowncaroffsets =
	{	
		[CHARACTER_MARIO] = { [1] = 24, [2] = 63 },
		[CHARACTER_LUIGI] = { [1] = 24, [2] = 68 },
		[CHARACTER_PEACH] = { [1] = 24, [2] = 30 },
		[CHARACTER_TOAD] =  { [1] = 24, [2] = 30 },
		[CHARACTER_LINK] =  { [1] = 30, [2] = 30 }
	}
	
	local megashroom;
	
	function Player:render(args)
		if(playerManager == nil) then
			playerManager = require("playerManager");
		end
		
		--Initialise frame variables
		local tx1,ty1;
		local f = args.frame;
		local d = args.direction;
		
		--Initialise character variables
		local powerup = args.powerup or self.powerup;
		local character = args.character or self.character;
		
		local oldchar = self.character
		self.character = character
		if character ~= oldchar then
			playerManager.refreshHitbox(character)
		end
		--Initialise ini files
		local basechar = playerManager.getBaseID(character);
		local ps = PlayerSettings.get(basechar, powerup);
		
		--Initialise priority and mount priority
		local p = -25;
		local mountp = -25;
		
		local drawplayer = args.drawplayer;
		if(drawplayer == nil) then
			drawplayer = true;
		end
		
		--Initialise mount variables
		local drawmounts = args.drawmounts;
		if(drawmounts == nil) then
			drawmounts = true;
		end
		local mount = args.mount or self:mem(0x108, FIELD_WORD);
		local mounttype = args.mounttype or self:mem(0x10A, FIELD_WORD)
		
		--Get frame location and offsets
		if(f or d) then
			f = f or self:getFrame()
			d = d or player.direction
			tx1,ty1 = Player.convertFrame(f, d)
		else
			tx1,ty1 = self:getFrame(true)
			d = d or player.direction
		end
		
		if(tx1 < 0 or ty1 < 0) then
			return;
		end
		local xOffset = ps:getSpriteOffsetX(tx1, ty1);
		local yOffset = ps:getSpriteOffsetY(tx1, ty1);
		
		--Adjust offsets for mounts
		if(mount == 3) then --Yoshi
		
			yOffset = yOffset + self:mem(0x10E,FIELD_WORD);
			
		elseif(mount == 2) then --Clown car
		
			xOffset = xOffset + math.floor((math.ceil(self.width) - ps.hitboxWidth)/2);
			
			local h = clowncaroffsets[basechar][math.min(2,powerup)];
			
			--Small characters, and those based on Toad, Link or Peach, use hardcoded offsets - Mario and Luigi adjust offsets to their hitboxes
			if(powerup == 1 or basechar == CHARACTER_LINK or basechar == CHARACTER_PEACH or basechar == CHARACTER_TOAD) then
				yOffset = yOffset-h;
			else
				yOffset = yOffset-h+ps.hitboxHeight*0.5;
			end
			
		--[[elseif(mount == 1) then
			if(basechar == CHARACTER_LINK or basechar == CHARACTER_PEACH or basechar == CHARACTER_TOAD) then
				--xOffset = xOffset-0.45;
			end]]
		end
		
		--Convert frames to texture coordinates (sheets are 10x10 of 100 pixels)
		tx1 = tx1*0.1;
		ty1 = ty1*0.1;
		local tx2,ty2 = tx1+0.1,ty1+0.1;
			
		local rawx = (args.x or self.x);
		local rawy = (args.y or self.y);
			
		--Calculate render position
		local x = rawx+xOffset
		local y = rawy+yOffset;
		
		--Check visibility states
		local forcedAnimState = self.forcedState;
		local flashing = self:mem(0x142, FIELD_BOOL);
		
		--If we want to ignore visibility states, then reset them to visible values
		if(args.ignorestate) then
			forcedAnimState = 0;
			flashing = false;
		elseif(self.deathTimer > 0) then
			return;
		end
		
		--Adjust priority if we're going through a pipe
		if(forcedAnimState == 3) then
			p = -70;
			mountp = -70;
		end
		
		--Hierarchy for mount priority
		mountp = args.mountpriority or args.priority or mountp;
		
		--If we should render the sprite, let's DO IT
		if(player_visible_animstates[forcedAnimState] and (not flashing or self.isMega)) then
		
			--Set up scene coordinate values
			local sceneCoords = args.sceneCoords;
			if(sceneCoords == nil) then
				sceneCoords = true;
			end
			
			--Initialise render height (100 is the entire frame)
			local h = 100;
			local mountheight = h;
			
			if(mount == 1) then
				y = y+0.01
				
				--When in a boot, height is equal to height in big state unless you're toad or peach
				--When on yoshi, height is equal to height in big state if in small state, otherwise it's 60
				--Height is sometimes wrong before ducking thanks to the height field not being updated
				--[[
				if basechar == CHARACTER_TOAD or basechar == CHARACTER_PEACH then
					
					if self:mem(0x12E, FIELD_BOOL) then --is ducking
						mountheight = 30
					else
						mountheight = 54
					end
					if powerup == 1 then
						y = y+6
					end
				else
					local mountsettings =  PlayerSettings.get(basechar, 2)
					if self:mem(0x12E, FIELD_BOOL) then --is ducking
						mountheight = mountsettings.hitboxDuckHeight
					else
						mountheight = mountsettings.hitboxHeight
					end
				end]]
				if basechar == CHARACTER_TOAD or basechar == CHARACTER_PEACH then
					if powerup == 1 then
						y = y+6
					end
				end
				mountheight = self.height
			end
			
			--If we should draw mounts, let's try
			if(drawmounts) then
			
				--Get render height if we're in a boot (we only want the head of the character)
				if(mount == 1) then
					h = mountheight-26-yOffset --self.height-26-yOffset --height in a boot is the same as "height while big"
					
					--GDI redigit why is your code so weird
					if(basechar == CHARACTER_MARIO or basechar == CHARACTER_LUIGI or basechar == CHARACTER_TOAD) then
						h = h-self:mem(0x10E, FIELD_WORD);
					else
						h = h-2;
					end
					
					ty2 = ty1+(h/1000);
				end
				
				--If we're in a yoshi, render that first (since it's behind the player)
				if(mount == 3) then --YOSHO
				
					--Ensure mount type is valid
					if(mounttype > 8 or mounttype < 1) then
						mounttype = 1;
					end
					
					--Tongue
					   --  Tongue offset > 0	      or   	  Head offset is correct for one of the "using tongue" frames		   and      	   Head frame is one of the "using tongue" frames
					if(self:mem(0xB4, FIELD_WORD) > 0 or ((self:mem(0x6E, FIELD_WORD) == 28 or  self:mem(0x6E, FIELD_WORD) == -36) and (self:mem(0x72, FIELD_WORD) == 9 or self:mem(0x72, FIELD_WORD) == 4))) then

						local tw = self:mem(0xB4, FIELD_WORD)+2;
						local tx;
						if(d == -1) then
							tx = self:mem(0x80, FIELD_DFLOAT)+16;
						else
							tx = rawx + self:mem(0x6E,FIELD_WORD) + 16;
						end
						local ty = self:mem(0x88, FIELD_DFLOAT);
						
						--Draw tongue body
						Graphics.glDraw {
											vertexCoords = {tx, ty, tx+tw, ty, tx+tw, ty+16, tx, ty+16},
											textureCoords = {0,0,tw/416,0,tw/416,1,0,1},
											primitive = Graphics.GL_TRIANGLE_FAN,
											sceneCoords = sceneCoords,
											texture = Graphics.sprites.hardcoded["21-2"].img,
											priority = mountp,
											shader = args.mountshader,
											uniforms = args.mountuniforms,
											attributes = args.mountattributes,
											color = args.mountcolor or args.color,
											target = args.target
										}
						
						--Draw tongue head
						drawMount(self, self:mem(0x80, FIELD_DFLOAT), self:mem(0x88, FIELD_DFLOAT), args, 16, 16, math.max(0,-d), Graphics.sprites.hardcoded["21-1"].img, sceneCoords, mountp);
					end
					
					local bodyframe = self:mem(0x7A, FIELD_WORD)
					local headframe = self:mem(0x72, FIELD_WORD)
					local headoffset = self:mem(0x6E,FIELD_WORD)
					
					--Flip the direction of yoshi if we need to
					if d == 1 and bodyframe < 7 then
						bodyframe = bodyframe + 7
					elseif d == -1 and bodyframe >= 7 then
						bodyframe = bodyframe - 7
					end
					
					if d == 1 and headframe < 5 then
						headframe = headframe + 5
						headoffset = -headoffset - 8
					elseif d == -1 and headframe >= 5 then
						headframe = headframe - 5
						headoffset = -headoffset - 8
					end
					
					--Draw Yoshi body
					drawMount(self, rawx - 4, rawy + self:mem(0x78, FIELD_WORD), args, 32, 32, bodyframe, Graphics.sprites.yoshib[mounttype].img, sceneCoords, mountp);
					--Draw Yoshi head
					drawMount(self, rawx + headoffset, rawy + self:mem(0x70,FIELD_WORD), args, 32, 32, headframe, Graphics.sprites.yoshit[mounttype].img, sceneCoords, mountp);
				end
			end
			
			--If we're ducking in a boot (clap your hands) - don't render the character
			if((mount ~= 1 or not self:mem(0x12E, FIELD_BOOL)) and drawplayer) then
			
				if(self.isMega) then
					if(megashroom == nil) then
						megashroom = require("NPCs/ai/megashroom");
					end
					megashroom.drawPlayer(self, sceneCoords, args.priority or p, args.shader, args.uniforms, args.attributes, args.color, args.target);
				else	
					--Draw the character
					Graphics.glDraw	{	
										vertexCoords = 	{x, y, x + 100, y, x + 100, y + h, x, y + h},
										textureCoords = {tx1, ty1, tx2, ty1, tx2, ty2, tx1, ty2},
										primitive = Graphics.GL_TRIANGLE_FAN,
										texture = args.texture or Graphics.sprites[playerManager.getName(character)][powerup].img,
										sceneCoords = sceneCoords,
										priority = args.priority or p,
										shader = args.shader,
										uniforms = args.uniforms,
										attributes = args.attributes,
										color = args.color or Color.white,
										target = args.target
									}
				end
			end
				
			--If we should draw mounts, try to
			if(drawmounts) then			
					
				local mountframe = self:mem(0x110, FIELD_WORD)
			
				if(mount == 1) then --We're in a boot
				
					--Ensure mount type is valid
					if(mounttype > 3 or mounttype < 1) then
						mounttype = 1;
					end
					
					--Flip the direction of the mount if we need to
					if d == 1 and mountframe < 2 then
						mountframe = mountframe + 2
					elseif d == -1 and mountframe >= 2 then
						mountframe = mountframe - 2
					end
					
					--Draw the boot
					drawMount(self, rawx + ps.hitboxWidth*0.5 - 16, rawy + mountheight--[[self.height]]-30, args, 32, 32, mountframe, Graphics.sprites.hardcoded["25-"..mounttype].img, sceneCoords, mountp);
					
				elseif(mount == 2) then --We're in a clown car
				
					--Flip the direction of the mount if we need to
					if d == 1 and mountframe < 4 then
						mountframe = mountframe + 4
					elseif d == -1 and mountframe >= 4 then
						mountframe = mountframe - 4
					end
					
					--Draw the clown car
					drawMount(self, rawx, rawy, args, 128, 128, mountframe, Graphics.sprites.hardcoded["26-2"].img, sceneCoords, mountp);
					
				end
			end
		end
		
		self.character = oldchar
		if character ~= oldchar then
			playerManager.refreshHitbox(oldchar)
		end
	end
end

do
	local function countSubstring(s1, s2)
		return select(2, s1:gsub(s2, ""))
	end

	function Text.getSize(str, style)
		--3 is default
		local charWidth = 16
		local spaceWidth = 16
		local padding = 2
		
		local textWidth = 0
		local textHeight = 16
		
		if style == 1 then
			textHeight = 14
			spaceWidth = 0
		elseif style == 2 then
			padding = 0
		elseif style == 4 then
			charWidth = 15
			charHeight = 16
			spaceWidth = 18
			padding = 3
		end
		
		local spaceCount = countSubstring(str, " ")
		local strCount = #str
		local charCount = #str - spaceCount
		
		textWidth = charCount * charWidth + math.max(charCount - 1,0) * padding + spaceCount * spaceWidth
		
		return textWidth, textHeight
	end
end

function Misc.episodePath()
	return Native.getEpisodePath()
end

function Misc.episodeName()
	local idx = mem(0x00B2C628, FIELD_WORD) - 1
	if(idx < 0) then
		return "SMBX2"
	end
	return tostring(mem(EP_LIST_PTR + (idx * 0x18), FIELD_STRING))
end

if not isOverworld then
	function Misc.levelFolder()
		local f = Level.filename()
		local i = f:match(".*%.()")
		if i == nil then 
			return nil 
		else
			return (f:sub(1,(i-2))).."/"
		end
	end

	function Misc.levelPath()
		local f = Level.filename()
		local i = f:match(".*%.()")
		if i == nil then 
			return nil 
		else
			return Misc.episodePath()..(f:sub(1,(i-2))).."/"
		end
	end
end

--Returns true only when testing in the editor
function Misc.inEditor()
	return mem(0x00B2C62A, FIELD_WORD) == 0;
end

function Misc.isPaused()
	return Misc.isPausedByLua() or mem(0x00B250E2, FIELD_BOOL) or (testmodemenu and testmodemenu.active)
end

function Misc.saveSlot(a)
	if a == nil then
		return mem(0x00B2C62A, FIELD_WORD)
	else
		mem(0x00B2C62A, FIELD_WORD, a)
	end
end

function Misc.getFullPath(file)
	if string.match(file, "^%a:[\\/]") then
		return file
	elseif isOverworld then
		return Misc.episodePath()..file
	else
		return Misc.levelPath()..file
	end
end

local resolvePaths
if isOverworld then
	resolvePaths = {
				Misc.episodePath(),
				getSMBXPath().."\\scripts\\",
				getSMBXPath().."\\"
			}
else
	resolvePaths = {
				Misc.levelPath(),
				Misc.episodePath(),
				getSMBXPath().."\\scripts\\",
				getSMBXPath().."\\"
			}
end

function Misc.multiResolveFile(...)
	local t = {...}
	
	--If passed a complete path, just return it as-is (as long as the file exists)
	for _,v in ipairs(t) do
		if string.match(v, "^%a:[\\/]") and io.exists(v) then
			return v
		end
	end

	for _,p in ipairs(resolvePaths) do
		for _,v in ipairs(t) do
			if io.exists(p..v) then
				return p..v
			end
		end
	end
	return nil
end

function Misc.resolveFile(path)
	--If passed a complete path, just return it as-is (as long as the file exists)
	if string.match(path, "^%a:[\\/]") and io.cachedExists(path) then
		return path
	end
	
	for _,p in ipairs(resolvePaths) do
		p = p..path
		if io.exists(p) then
			return p
		end
	end
	return nil
end

do
	local validAudioFiles = {".ogg", ".mp3", ".wav", ".voc", ".flac", ".spc"}
	
	--table.map doesn't exist yet
	local validFilesMap = {};
	for _,v in ipairs(validAudioFiles) do
		validFilesMap[v] = true;
	end
	
	function Misc.resolveSoundFile(path)
		local p,e = string.match(string.lower(path), "^(.+)(%..+)$")
		local t = {}
		local idx = 1
		local typeslist = validAudioFiles
		if e and validFilesMap[e] then
			--Re-arrange type list to prioritise type that was provided to the resolve function
			if e ~= validAudioFiles[1] then
				typeslist = { e }
				for _,v in ipairs(validAudioFiles) do
					if v ~= e then
						table.insert(typeslist, v)
					end
				end
			end
			path = p
		end
		for _,typ in ipairs(typeslist) do
			t[idx] = path..typ
			t[idx+#typeslist] = "sound/"..path..typ
			t[idx+2*#typeslist] = "sound/extended/"..path..typ
			idx = idx+1
		end
		
		return Misc.multiResolveFile(table.unpack(t))
	end
    
    function Misc.resolveMusicFile(path)
		local t = {}
		local idx = 1

        local folderList
        
        if not isOverworld then
            folderList = {
                Misc.levelPath(),
                Misc.episodePath(),
                getSMBXPath().."\\"
            }
        else
            folderList = {
                Misc.episodePath(),
                getSMBXPath().."\\"
            }
        end

        local existsOrNot;
        local pathDraft1, pathDraft2 = string.find(path, "|")
        local pathFinal = ""
        local pathSlashesResolved = string.gsub(path, "/", "\\")

        if pathDraft1 ~= nil then
            pathFinal = path:sub(1, pathDraft1 - 1)
        else
            pathFinal = path
        end
        
        for k,fold in ipairs(folderList) do
            local dirToFile = fold..pathFinal
            local finalDirToFile = string.gsub(dirToFile, "/", "\\")
            if io.exists(finalDirToFile) then
                existsOrNot = fold..pathSlashesResolved
            end
        end
        
        return existsOrNot
	end
end

local scoreTable = {
	10, 100, 200, 400, 800, 1000, 2000, 4000, 8000
}
local livesTable = {
	1, 2, 3, 5
}

function Misc.givePoints(index, position, supressSound)
	local index = math.min(index, #scoreTable + #livesTable)
	if index > #scoreTable then
		if not supressSound then
			SFX.play(15)
		end
		mem(0x00B2C5AC, FIELD_FLOAT, mem(0x00B2C5AC, FIELD_FLOAT) + livesTable[index - #scoreTable])
	elseif index > 0 then
		if not supressSound then
			SFX.play(14)
		end
		mem(0x00B2C8E4, FIELD_DWORD, mem(0x00B2C8E4, FIELD_DWORD) + scoreTable[index])
	end
	
	if index > 0 then
		Effect.spawn(79, position, index - 1).animationFrame = index - 1
	end
end


local offset_lives = 0x00B2C5AC
local offset_coins = 0x00B2C5A8

local function onMonitorCollected(p)
	SFX.play(56)
	mem(offset_coins, FIELD_WORD, mem(offset_coins, FIELD_WORD)+NPC.config[npcID].value)
							
	-- TODO: 
end

function Misc.coins(n, playCoinSound)
	if n then
		mem(offset_coins, FIELD_WORD, math.max(0, mem(offset_coins, FIELD_WORD)+n))
		if playCoinSound then
			Audio.playSFX(14);
		end

		if(mem(offset_coins, FIELD_WORD) >= 100) then --get 1up
			while mem(offset_coins, FIELD_WORD) >= 100 do
				if mem(offset_lives, FIELD_FLOAT) == 99 then
					mem(offset_coins, FIELD_WORD, 99);
				else
					mem(offset_coins, FIELD_WORD, mem(offset_coins, FIELD_WORD) - 100);
					mem(offset_lives, FIELD_FLOAT, math.min(mem(offset_lives, FIELD_FLOAT) + 1, 99));
					Audio.playSFX(15);
				end
			end
		end
	else
		return mem(offset_coins, FIELD_WORD)
	end
end

function Misc.score(n)
	local t = SaveData._basegame
	if n == nil then
		if t == nil then
			return 0
		else
			t = t.hud
			if t == nil then
				return 0
			else
				return t.score or 0
			end
		end
	else
		if t and t.hud and t.hud.score then
			t.hud.score = t.hud.score + n
		end
	end
end

if useOldLevelLoad then
    if not isOverworld then
        --I want this for overworld too but alas
        function Level.load(filename, episodename, warpindex)
            --Filename specified = new level! Else reload current level.
        
            --warp index should also be settable if reloading into same level
            if warpindex ~= nil and warpindex >= 0 then
                mem(0x00B2C6DA, FIELD_WORD, warpindex)    -- GM_NEXT_LEVEL_WARPIDX
            end
        
            if Misc.inEditor() then
                if (filename ~= nil and episodename ~= nil) then
                    Misc.warn("Loading new episode cancelled. While in the editor, no external episodes are loaded. Cross-episode loading has to be tested in the main game.")
                    return
                end
            end
        
            if filename ~= nil then
                local episodeindex = mem(0x00B2C628, FIELD_WORD) --current episode
        
                local EP_LIST_COUNT = mem(0x00B250E8, FIELD_WORD)
                local EP_LIST_PTR = mem(0x00B250FC, FIELD_DWORD)
                if episodename ~= nil then
                    local hasFound = false
                    for indexer = 1, EP_LIST_COUNT do
                        local name = tostring(mem(EP_LIST_PTR + (indexer - 1) * 0x18 + 0x0, FIELD_STRING))
                        if name == episodename then
                            episodeindex = indexer
                            hasFound = true
                            break
                        end
                    end
                    if hasFound then
                        mem(0x00B25720, FIELD_STRING, filename) -- GM_NEXT_LEVEL_FILENAME
                        mem(0x00B2C628, FIELD_WORD, episodeindex) -- Index of the episode
                    else
                        Misc.warn("Episode of name '" ..episodename.."' could not be found. Aborting.")
                        return
                    end
                else
                    mem(0x00B25720, FIELD_STRING, filename) -- GM_NEXT_LEVEL_FILENAME
                end
            end
            
            -- Force modes such that we trigger level exit
            mem(0x00B250B4, FIELD_WORD, 0)  -- GM_IS_EDITOR_TESTING_NON_FULLSCREEN
            mem(0x00B25134, FIELD_WORD, 0)  -- GM_ISLEVELEDITORMODE
            mem(0x00B2C89C, FIELD_WORD, 0)  -- GM_CREDITS_MODE
            mem(0x00B2C620, FIELD_WORD, 0)  -- GM_INTRO_MODE
            mem(0x00B2C5B4, FIELD_WORD, -1) -- GM_EPISODE_MODE (set to leave level)
        end
    end
else
    function Level.load(fileName, episodeName, warpIndex, suppressSFX)
        --File name specified = new level! Else reload current level.
        local episodeNameFinal = ""

        if suppressSFX == nil then
            suppressSFX = true
        end

        --warp index should also be settable if reloading into same level
        if (warpIndex == nil or warpIndex < 0) then
            warpIndex = 0
        end

        if fileName == nil then
            if not isOverworld then
                fileName = Misc.episodePath()..Level.filename()
            else
                error("Can't reload a level when you're on the map")
                return
            end
        end
    
        if Misc.inEditor() then
            if (episodeName ~= nil) then
                Misc.warn("Loading new episode cancelled. While in the editor, no external episodes are loaded. Cross-episode loading has to be tested in the main game.")
                return
            end
        end
    
        if fileName ~= nil then
            local episodeindex = mem(0x00B2C628, FIELD_WORD) --current episode
    
            local EP_LIST_COUNT = mem(0x00B250E8, FIELD_WORD)
            local EP_LIST_PTR = mem(0x00B250FC, FIELD_DWORD)
            if episodeName ~= nil then
                local hasFound = false
                for indexer = 1, EP_LIST_COUNT do
                    local name = tostring(mem(EP_LIST_PTR + (indexer - 1) * 0x18 + 0x0, FIELD_STRING))
                    if name == episodeName then
                        episodeNameFinal = episodeName
                        hasFound = true
                        break
                    end
                end
                if not hasFound then
                    Misc.warn("Episode of name '" ..episodeName.."' could not be found. Aborting.")
                    return
                end
            else
                episodeNameFinal = ""
            end
        end

        Misc.loadLevel(fileName, episodeNameFinal, warpIndex, suppressSFX)
    end
end

if not isOverworld then	
	function Level.folderPath()
		local n = Level.filename();
		return Misc.episodePath()..n:sub(1,n:find("%.[^%.]*$")-1).."/";
	end
	
	function Level.format()
		local f = Level.filename()
		return f:sub(f:match(".*%.()"))
	end
end

do --Table helper functions
	function table.ifindlast(t, val)
		for i = #t,1,-1 do
			if(t[i] == val) then
				return i;
			end
		end
		return nil;
	end

	function table.findlast(t, val)
		local lst = nil;
		for k,v in pairs(t) do
			if(v == val) then
				lst = k;
			end
		end
		return lst;
	end

	function table.ifind(t, val)
		for k,v in ipairs(t) do
			if(v == val) then
				return k;
			end
		end
		return nil;
	end

	function table.find(t, val)
		for k,v in pairs(t) do
			if(v == val) then
				return k;
			end
		end
		return nil;
	end

	function table.ifindall(t, val)
		local rt = {};
		for k,v in ipairs(t) do
			if(v == val) then
				table.insert(rt,k);
			end
		end
		return rt;
	end

	function table.findall(t, val)
		local rt = {};
		for k,v in pairs(t) do
			if(v == val) then
				table.insert(rt,k);
			end
		end
		return rt;
	end

	function table.icontains(t, val)
		return table.ifind(t, val) ~= nil;
	end

	function table.contains(t, val)
		return table.find(t, val) ~= nil;
	end

	function table.iclone(t)
		local rt = {};
		for k,v in ipairs(t) do
			rt[k] = v;
		end
		setmetatable(rt, getmetatable(t));
		return rt;
	end

	function table.clone(t)
		local rt = {};
		for k,v in pairs(t) do
			rt[k] = v;
		end
		setmetatable(rt, getmetatable(t));
		return rt;
	end

	function table.ideepclone(t)
		local rt = {};
		for k,v in ipairs(t) do
			if(type(v) == "table") then
				rt[k] = table.deepclone(v);
			else
				rt[k] = v;
			end
		end
		setmetatable(rt, getmetatable(t));
		return rt;
	end

	function table.deepclone(t)
		local rt = {};
		for k,v in pairs(t) do
			if(type(v) == "table") then
				rt[k] = table.deepclone(v);
			else
				rt[k] = v;
			end
		end
		setmetatable(rt, getmetatable(t));
		return rt;
	end

	function table.ishuffle(t)
		for i=#t,2,-1 do 
			local j = rng.randomInt(1,i)
			t[i], t[j] = t[j], t[i]
		end
		return t
	end
	
	function table.map(t)
		local t2 = {};
		for _,v in ipairs(t) do
			t2[v] = true;
		end
		return t2;
	end
	
	function table.unmap(t)
		local t2 = {};
		for k,_ in pairs(t) do
			table.insert(t2,k);
		end
		return t2;
	end

	function table.join(...)
		local ts = {...};
		local t = {};
		local ct = #ts;
		for i=ct,1,-1 do
			for k,v in pairs(ts[i]) do
				t[k] = v;
			end
		end
		return t;
	end
	
	function table.append(...)
		local ts = {...}
		local t = {};
		for _,t1 in ipairs(ts) do
			for _,v in ipairs(t1) do
				table.insert(t,v);
			end
		end
		return t;
	end

	function table.reverse(t)
		local len = 0
		for k,_ in ipairs(t) do
			len = k
		end
		local rt = {}
		for i = 1, len do
			rt[len - i + 1] = t[i]
		end
		return rt
	end
	
	function table.flatten(t)
		local t2 = {};
		for _,v in ipairs(t) do
			if(pcall(ipairs(v))) then
				for _,v2 in ipairs(v) do
					table.insert(t2, v2);
				end
			else
				table.insert(t2, v);
			end
		end
		return t2;
	end
end


do --String helper functions

	local string = string
	local stringmt = getmetatable("")
	local string_byte = string.byte
	local string_sub = string.sub
	local string_gsub = string.gsub
	local table_insert = table.insert
		
	--Trim trailing and leading whitespace
	function string.trim(s)
		return string_gsub(s, "^%s*(.-)%s*$", "%1")
	end

	--Split a string on a pattern into a table of strings
	function string.split(s, p, exclude, plain)
		if  exclude == nil  then  exclude = false; end;
		if  plain == nil  then  plain = true; end;

		local t = {};
		local i = 0;
	   
		if(#s <= 1) then
			return {s};
		end
	   
		while true do
			local ls,le = s:find(p, i, plain);	--find next split pattern
			if (ls ~= nil) then
				table_insert(t, string_sub(s, i,le-1));
				i = ls+1;
				if  exclude  then
					i = le+1;
				end
			else
				table_insert(t, string_sub(s, i));
				break;
			end
		end
		
		return t;
	end

	--Compare two strings
	function string.compare(left, right)
		if left == right then
			return 0
		else
			local i = 1
			while true do
				local a = string_byte(left, i)
				local b = string_byte(right, i)
				if b == nil then --left is longer than right
					return 1
				elseif a == nil then --right is longer than left
					return -1
				elseif a > b then --left is lexically greater than right
					return 1
				elseif b > a then --right is lexically greater than left
					return -1
				end
				i = i + 1
			end
		end
	end

	-- Compare two strings using the comparison operators
	local string_compare = string.compare
	function stringmt.__lt(a, b)
		return (string_compare(a, b) < 0)
	end

	function stringmt.__index(obj, key)
		if key == "str" then --Compatibility with silly ol' .str code
			return obj
		elseif type(key) == "number" then --Square-bracket substrings
			local ret = string_sub(obj, key, key)
			if ret == "" then
				return nil
			else
				return ret
			end
		else
			return string[key]
		end
	end

end
	
do --Maths helper functions

	local max = math.max;
	local min = math.min;
	local abs = math.abs;

	function math.lerp(a,b,t)	
		if type(a) == "Quaternion" and type(b) == "Quaternion" and a.__nrm and b.__nrm then
			local q = a*(1-t) + b*t
			q:normalise()
			q.__nrm = true
			return q
		else
			return a*(1-t) + b*t
		end
	end

	--interpolates between 0 and 360, wrapping around the ends
	function math.anglelerp(a,b,t)
		local v = (b - a) % 360;
		return a + (((2*v) % 360) - v)*t;
	end

	function math.invlerp(a,b,v)

		if(type(a) ~= type(b) or type(a) ~= type(v) or (type(a) == "table" and (a.__type ~= b.__type or a.__type ~= v.__type))) then
			error("Types must match when performing an inverse lerp.", 2)
		end
		local v1 = b-a;
		local v2 = v-a;
		if(type(v1) ~= "number") then
			
			--Color or Vector
			local t1 = 0
			local t2 = 0
			
			for k,v in ipairs(v1) do
				t1 = t1 + v
				t2 = t2 + v2[k]
			end
			
			v1 = t1
			v2 = t2
			
		end
		
		return (v2/v1);
	end

	function math.clamp(a,mi,ma)
		mi = mi or 0;
		ma = ma or 1;
		return min(ma,max(mi,a));
	end

	function math.signum(a)
		if a > 0 then
			return 1;
		elseif a == 0 then
			return 0;
		elseif a < 0 then
			return -1;
		end
	end

	math.sign = math.signum;
	math.sgn = math.signum; --ugh
	
	local complex_mt = {}
	
	function complex_mt.__index(t,k)
		if k == "real" or k == "re" then
			return t[1]
		elseif k == "imaginary" or k == "im" then
			return t[2]
		elseif k == "conjugate" then
			return math.complex(t[1],-t[2])
		elseif k == "length" or k == "r" or k == "modulus" or k == "mod" then
			return math.sqrt(t[1]*t[1] + t[2]*t[2])
		elseif k == "angle" or k == "a" or k == "argument" or k == "arg" then
			if t[2] == 0 then
				if t[1] >= 0 then
					return 0
				else
					return math.pi
				end
			end
			return math.atan2(t[2],t[1])
		end
	end
	
	function complex_mt.__newindex(t,k,v)
		if k == "real" or k == "re" then
			t[1] = v
		elseif k == "imaginary" or k == "im" then
			t[2] = v
		elseif k == "length" or k == "r" or k == "modulus" or k == "mod" then
			local a = t.arg
			t[1] = v*math.cos(a)
			t[2] = v*math.sin(a)
		elseif k == "angle" or k == "a" or k == "argument" or k == "arg" then
			local r = t.mod
			t[1] = r*math.cos(v)
			t[2] = r*math.sin(v)
		end
	end
	
	complex_mt.__type = "Complex"
	
	function complex_mt.__add(a,b)
		if type(a) == "Complex" then
			if type(b) == "Complex" then
				return math.complex(a[1]+b[1], a[2]+b[2])
			elseif tonumber(b) then
				return math.complex(a[1]+tonumber(b), a[2])
			else
				error("Cannot add complex number with "..type(b), 2)
			end
		elseif tonumber(a) then
			if type(b) == "Complex" then
				return math.complex(a+b[1], b[2])
			elseif tonumber(b) then
				return tonumber(a)+tonumber(b)
			else
				error("Cannot add "..type(a).." with "..type(b), 2)
			end
		else
			error("Cannot add complex number with "..type(a), 2)
		end
	end
	
	function complex_mt.__sub(a,b)
		if type(a) == "Complex" then
			if type(b) == "Complex" then
				return math.complex(a[1]-b[1], a[2]-b[2])
			elseif tonumber(b) then
				return math.complex(a[1]-tonumber(b), a[2])
			else
				error("Cannot subtract complex number with "..type(b), 2)
			end
		elseif tonumber(a) then
			if type(b) == "Complex" then
				return math.complex(tonumber(a)-b[1], -b[2])
			elseif tonumber(b) then
				return tonumber(a)-tonumber(b)
			else
				error("Cannot subtract "..type(a).." with "..type(b), 2)
			end
		else
			error("Cannot subtract complex number with "..type(a), 2)
		end
	end
	
	function complex_mt.__mul(a,b)
		if type(a) == "Complex" then
			if type(b) == "Complex" then
				return math.complex(a[1]*b[1] - a[2]*b[2], a[1]*b[2] + a[2]*b[1])
			elseif tonumber(b) then
				return math.complex(a[1]*tonumber(b), a[2]*tonumber(b))
			else
				error("Cannot multiply complex number with "..type(b), 2)
			end
		elseif tonumber(a) then
			if type(b) == "Complex" then
				return math.complex(tonumber(a)*b[1], tonumber(a)*b[2])
			elseif tonumber(b) then
				return tonumber(a)*tonumber(b)
			else
				error("Cannot multiply "..type(a).." with "..type(b), 2)
			end
		else
			error("Cannot multiply complex number with "..type(a), 2)
		end
	end
	
	function complex_mt.__div(a,b)
		if type(a) == "Complex" then
			if type(b) == "Complex" then
				local div = (b[1]*b[1]+b[2]*b[2])
				return math.complex((a[1]*b[1] + a[2]*b[2])/div, (a[2]*b[1] - a[1]*b[2])/div)
			elseif tonumber(b) then
				return math.complex(a[1]/tonumber(b), a[2]/tonumber(b))
			else
				error("Cannot divide complex number with "..type(b), 2)
			end
		elseif tonumber(a) then
			if type(b) == "Complex" then
				local div = (b[1]*b[1]+b[2]*b[2])
				return math.complex(tonumber(a)*b[1]/div, -tonumber(a)*b[2]/div)
			elseif tonumber(b) then
				return tonumber(a)/tonumber(b)
			else
				error("Cannot divide "..type(a).." with "..type(b), 2)
			end
		else
			error("Cannot divide complex number with "..type(a), 2)
		end
	end
	
	local function calc_im_to_n(im, n)
		local q = n % 4
		if q == 0 then --b is multiple of 4
			return math.complex(math.pow(im, n), 0)
		elseif q == 1 then --i^b = i
			return math.complex(0, math.pow(im, n))
		elseif q == 2 then --i^b = -1
			return math.complex(-math.pow(im, n), 0)
		else --i^b = 3
			return math.complex(0, -math.pow(im, n))
		end
	end
	
	function complex_mt.__pow(a,b)
		if type(a) == "Complex" then
			if type(b) == "Complex" then
				
				if a[2] == 0 then
					if b[2] == 0 then
						if a[1] >= 0 or math.floor(b[1]) == b[1] then
							return math.complex(math.pow(a[1], b[1]), 0)
						else
							return a^b[1]
							
							--The lines below, while accurate, are lossy - easier to just plug the numbers back in and run the precision special case
							--local m = math.pow(-a[1], b[1])
							--return math.complex(m*math.cos(b[1]*math.pi), m*math.sin(b[1]*math.pi))
						end
					else
						return a[1]^b
					end
				elseif b[2] == 0 then
					return a^b[1]
				end
			
				local r2 = a[1]*a[1] + a[2]*a[2]
				local t = math.atan2(a[2],a[1])
				
				local m = math.pow(r2, b[1]/2)*math.exp(-b[2]*t)
				local int = b[2]*math.log(r2)/2 + b[1]*t
				
				return math.complex(m*math.cos(int), m*math.sin(int))
			elseif tonumber(b) then
				b = tonumber(b)
				if a[1] == 0 --[[result is of the form i^b * a^b]] 
				and math.floor(b) == b then --b is integer
					return calc_im_to_n(a[2], b)
				end
				
				if a[2] == 0 then	
					--These special cases preserve precision
					if a[1] >= 0 or math.floor(b) == b then
						return math.complex(math.pow(a[1], b), 0)
					elseif math.abs(b) >= 0.5 then
						local ba = math.abs(b)
						local mults = math.floor(ba*2)
						local b1 = ba-(mults*0.5)
						
						local bs = math.sign(b)
						return calc_im_to_n(1, bs*mults) * (math.pow(-a[1], bs*mults/2)) * math.complex(a[1],0)^(bs*b1)
					else
						local m = math.pow(-a[1],b)
						local int = b*math.pi
						return math.complex(m*math.cos(int), m*math.sin(int))
					end
				end
				
				local r2 = a[1]*a[1] + a[2]*a[2]
				local t = math.atan2(a[2],a[1])
				local r = math.pow(r2, b/2)
				return math.complex(r*math.cos(b*t), r*math.sin(b*t))
			else
				error("Cannot raise complex number to power "..type(b), 2)
			end
		elseif tonumber(a) then
			if type(b) == "Complex" then
				a = tonumber(a)
				
				if b[2] == 0 then
					--These special cases preserve precision
					if a >= 0 or math.floor(b[1]) == b[1] then
						return math.complex(math.pow(a, b[1]), 0)
					elseif math.abs(b[1]) >= 0.5 then
						local ba = math.abs(b[1])
						local mults = math.floor(ba*2)
						local b1 = ba-(mults*0.5)
						
						local bs = math.sign(b[1])
						return calc_im_to_n(1, bs*mults) * (math.pow(-a, bs*mults/2)) * math.complex(a,0)^(bs*b1)
					else
						local m = math.pow(-a,b[1])
						local int = b[1]*math.pi
						return math.complex(m*math.cos(int), m*math.sin(int))
					end
				end
				
				if a > 0 then
					local m = math.pow(a,b[1])
					local int = b[2]*math.log(a)
					return math.complex(m*math.cos(int), m*math.sin(int))
				elseif a == 0 then
					return math.complex(0/0, 0/0)
				else
					local la = math.log(-a) --note: a < 0
					local m = math.exp(b[1]*la - b[2]*math.pi)
					
					local int = b[1]*math.pi + b[2]*la
					
					return math.complex(m*math.cos(int), m*math.sin(int))
				end
			elseif tonumber(b) then
				return math.pow(tonumber(a), tonumber(b))
			else
				error("Cannot raise "..type(a).." to power "..type(b), 2)
			end
		else
			error("Cannot raise "..type(a) .. " to complex power", 2)
		end
	end
	
	function complex_mt.__unm(a)
		return math.complex(-a[1],-a[2])
	end
	
	function complex_mt.__eq(a,b)
		return type(a)=="Complex" and type(b)=="Complex" and a[1]==b[1] and a[2]==b[2]
	end
	
	local function getistring(n)
		if n == 0 then
			return ""
		elseif n == 1 then
			return "i"
		elseif n == -1 then
			return "-i"
		else
			return tostring(n).."i"
		end
	end
	
	function complex_mt.__tostring(a)
		if a[1] == 0 then
			if a[2] == 0 then
				return "0"
			else
				return getistring(a[2])
			end
		elseif a[2] > 0 then
			return a[1].."+"..getistring(a[2])
		elseif a[2] < 0 then
			return a[1]..getistring(a[2])
		else
			return tostring(a[1])
		end
	end
	
	function complex_mt.__tonumber(a)
		return a[1]
	end
	
	
	
	function math.clog(a)
		if type(a) == "Complex" then	
			if a[1] == 0 and a[2] == 0 then
				return math.complex(-math.huge, 0)
			else
				local r2 = a[1]*a[1] + a[2]*a[2]
				local t = math.atan2(a[2],a[1])
				return math.complex(math.log(r2)/2, t)
			end
		elseif tonumber(a) then
			a = tonumber(a)
			if a == 0 then
				return math.complex(-math.huge, 0)
			end
			local r = math.abs(a)
			local t
			if a >= 0 then
				t = 0
			else
				t = math.pi
			end
			
			return math.complex(math.log(r), t)
		else
			error("bad argument #1 to 'clog' (number or Complex expected, got "..type(a)..")", 2)
		end
	end
	
	function math.complex(r, c)
		return setmetatable({r or 0, c or 0}, complex_mt)
	end
	
	local scomplex_mt = {}
	for k,v in pairs(complex_mt) do
		scomplex_mt[k] = v
	end
	
	scomplex_mt.__newindex = function(t,k,v)
		error("Cannot set the value of a static complex number.", 2)
	end
	
	local function staticComplex(r,c)
		return setmetatable({r or 0, c or 0}, scomplex_mt)
	end
	
	math.i = staticComplex(0,1)
	
	math.e = math.exp(1)
	
	
	do --Serialization

		local serializer = require("ext/serializer")
		
		local numtostring = serializer.convertnumber
		local match = string.match

		local function serializecomplex(v)
			return numtostring(v[1])..":"..numtostring(v[2])
		end
															
		local function parsecomplex(v) 
			local x,y = match(v,"([^:]+):([^:]+)")
			return math.complex(tonumber(x),tonumber(y))
		end												

		serializer.register("Complex", serializecomplex, parsecomplex)
	end
end

return ce