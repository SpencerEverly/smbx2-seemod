local mem = mem
local ffi_utils = require("ffi_utils")

local playerLavaFieldsArray = nil
do
	ffi.cdef([[
		const char* LunaLuaGetPlayerLavaFieldsStruct();
	]])
    local LunaDLL = ffi.load("LunaDll.dll")

	-- Define structure
	ffi.cdef(ffi.string(LunaDLL.LunaLuaGetPlayerLavaFieldsStruct()))

	ffi.cdef([[
		PlayerLavaFields* LunaLuaGetPlayerLavaFieldsArray();
	]])
	playerLavaFieldsArray = LunaDLL.LunaLuaGetPlayerLavaFieldsArray()
end

----------------------
-- FFI DECLARATIONS --
----------------------
ffi.cdef[[
void LunaLuaKillPlayer(short playerIndex);
void LunaLuaHarmPlayer(short playerIndex);

short* LunaLuaGetValidCharacterIDArray();
unsigned int LunaLuaGetTemplateAddressForCharacter(int id);

typedef struct ExtendedPlayerFields
{
    bool noblockcollision;
    bool nonpcinteraction;
    bool noplayerinteraction;
    unsigned int collisionGroup;
} ExtendedPlayerFields;
ExtendedPlayerFields* LunaLuaGetPlayerExtendedFieldsArray();

typedef struct _LunaLuaKeyMap {
    short    up; //Up
    short    down; //Down
    short    left; //Left
    short    right; //Right
    short    jump; //Jump
    short    altJump; //Spin Jump
    short    run;  //Run
    short    altRun; //Alt Run
    short    dropItem; //Select/Drop Item
    short    pause; //Pause
} LunaLuaKeyMap;
LunaLuaKeyMap* LunaLuaGetRawKeymapArray(void);
]]
local LunaDLL = ffi.load("LunaDll.dll")

-------------------------------
-- Get pointer to raw keymap --
-------------------------------
local rawKeymap = LunaDLL.LunaLuaGetRawKeymapArray();

----------------------
-- MEMORY ADDRESSES --
----------------------
local GM_PLAYERS_ADDR = mem(0x00B25A20, FIELD_DWORD)
local GM_PLAYERS_COUNT_ADDR = 0x00B2595E

-----------------------------
-- CONVERSIONS AND GETTERS --
-----------------------------

local function sectionToSectionObj(idx)
	if (idx >= 21) then
		return nil
	end
	return Section(idx)
end

local function npcIdxToNpcObj(idx)
	if (idx <= 0) then
		return nil
	end
	return NPC(idx-1)
end

local function climbingStateToBool(st)
	return st > 0
end

local function playerGetScreenCoords(pl)
	local cam = camera
	local px = pl.x
	local py = pl.y
	local cx = cam.x
	local cy = cam.y
	local r = {}
	r.left = px - cx
	r.top = py - cy
	r.right = (px - cx) + pl.width
	r.bottom = (py - cy) + pl.height
	return r
end

local function playerGetIdx(pl)
	return pl._idx
end

local function playerGetIsValid(pl)
	local idx = pl._idx

	if (idx >= 0) and (idx <= mem(GM_PLAYERS_COUNT_ADDR, FIELD_WORD)) then
		return true
	end

	if (idx >= 1000) then
		return true
	end

	return false
end

local playerKeys = {}
local function playerGetKeysTable(pl)
	return playerKeys[pl.idx]
end

local rawPlayerKeys = {}
local function playerGetRawKeysTable(pl)
	return rawPlayerKeys[pl.idx]
end

-- megashroom is loaded later in execution than the FFI classes.
-- By the time this function gets called, Player._isMega should exist.
local function playerGetIsMega(pl)
	return pl:_isMega()
end

-- starman is the same situation as megashroom
local function playerGetHasStarman(pl)
	return pl:_hasStarman()
end

local playerKeepMegaPower = {}

local function playerGetMegaPowerKeep(pl)
	return playerKeepMegaPower[pl.idx] or false
end

local function playerSetMegaPowerKeep(pl, v)
	playerKeepMegaPower[pl.idx] = v
end

local function playerSetLavaStatus(pl, v)
    if not Misc.getWeakLava() then
        if v < 1 and v > 3 then
            v = 1
        end
        playerLavaFieldsArray[pl.idx].lavaTouchingStatus = v
    else
        return
    end
    
end

local function playerGetLavaStatus(pl)
    return playerLavaFieldsArray[pl.idx].lavaTouchingStatus
end

------------------------
-- CONSTANTS          --
------------------------

-- Alias for POWERUP_TANOOKIE, as defined in C++
_G["POWERUP_TANOOKI"] = 5

_G["MOUNT_NONE"] = 0
_G["MOUNT_BOOT"] = 1
_G["MOUNT_CLOWNCAR"] = 2
_G["MOUNT_YOSHI"] = 3

_G["BOOTCOLOR_GREEN"] = 1
_G["BOOTCOLOR_RED"] = 2
_G["BOOTCOLOR_BLUE"] = 3

_G["YOSHICOLOR_GREEN"] = 1
_G["YOSHICOLOR_BLUE"] = 2
_G["YOSHICOLOR_YELLOW"] = 3
_G["YOSHICOLOR_RED"] = 4
_G["YOSHICOLOR_BLACK"] = 5
_G["YOSHICOLOR_PURPLE"] = 6
_G["YOSHICOLOR_PINK"] = 7
_G["YOSHICOLOR_CYAN"] = 8

_G["FORCEDSTATE_NONE"] = 0
_G["FORCEDSTATE_POWERUP_BIG"] = 1
_G["FORCEDSTATE_POWERDOWN_SMALL"] = 2
_G["FORCEDSTATE_PIPE"] = 3
_G["FORCEDSTATE_POWERUP_FIRE"] = 4
_G["FORCEDSTATE_POWERUP_LEAF"] = 5
_G["FORCEDSTATE_RESPAWN"] = 6
_G["FORCEDSTATE_DOOR"] = 7
_G["FORCEDSTATE_INVISIBLE"] = 8
_G["FORCEDSTATE_ONTONGUE"] = 9
_G["FORCEDSTATE_SWALLOWED"] = 10
_G["FORCEDSTATE_POWERUP_TANOOKI"] = 11
_G["FORCEDSTATE_POWERUP_HAMMER"] = 12
_G["FORCEDSTATE_POWERUP_ICE"] = 41
_G["FORCEDSTATE_POWERDOWN_FIRE"] = 227
_G["FORCEDSTATE_POWERDOWN_ICE"] = 228
_G["FORCEDSTATE_MEGASHROOM"] = 499
_G["FORCEDSTATE_TANOOKI_POOF"] = 500

------------------------
-- FIELD DECLARATIONS --
------------------------
local PlayerFields = {
		idx                     = {get=playerGetIdx, readonly=true, alwaysValid=true},
		isValid                 = {get=playerGetIsValid, readonly=true, alwaysValid=true},
		screen                  = {get=playerGetScreenCoords, readonly=true},
		keys                    = {get=playerGetKeysTable, readonly=true},
		rawKeys                 = {get=playerGetRawKeysTable, readonly=true},
		isMega                  = {get=playerGetIsMega, readonly=true},
		hasStarman              = {get=playerGetHasStarman, readonly=true},
		keepPowerOnMega         = {get=playerGetMegaPowerKeep, set=playerSetMegaPowerKeep},

		section                 = {0x15A, FIELD_WORD},
		sectionObj              = {0x15A, FIELD_WORD, decoder=sectionToSectionObj, readonly=true},
		x                       = {0x0C0, FIELD_DFLOAT},
		y                       = {0x0C8, FIELD_DFLOAT},
		width                   = {0x0D8, FIELD_DFLOAT},
		height                  = {0x0D0, FIELD_DFLOAT},
		speedX                  = {0x0E0, FIELD_DFLOAT},
		speedY                  = {0x0E8, FIELD_DFLOAT},
		climbing                = {0x040, FIELD_WORD, decoder=climbingStateToBool, readonly=true},
		climbingNPC             = {0x02C, FIELD_DFLOAT, decoder=npcIdxToNpcObj, readonly=true}, -- NOT cleared when player stops climbing
		powerup                 = {0x112, FIELD_WORD},
		character               = {0x0F0, FIELD_WORD},
		reservePowerup          = {0x158, FIELD_WORD},
		holdingNPC              = {0x154, FIELD_WORD, decoder=npcIdxToNpcObj, readonly=true},
		upKeyPressing           = {0x0F2, FIELD_BOOL},
		downKeyPressing         = {0x0F4, FIELD_BOOL},
		leftKeyPressing         = {0x0F6, FIELD_BOOL},
		rightKeyPressing        = {0x0F8, FIELD_BOOL},
		jumpKeyPressing         = {0x0FA, FIELD_BOOL},
		altJumpKeyPressing      = {0x0FC, FIELD_BOOL},
		runKeyPressing          = {0x0FE, FIELD_BOOL},
		altRunKeyPressing       = {0x100, FIELD_BOOL},
		dropItemKeyPressing     = {0x102, FIELD_BOOL},
		pauseKeyPressing        = {0x104, FIELD_BOOL},

		direction               = {0x106, FIELD_WORD},
		deathTimer              = {0x13E, FIELD_WORD},
		standingNPC             = {0x176, FIELD_WORD, decoder=npcIdxToNpcObj, readonly=true},
		mount                   = {0x108, FIELD_WORD},
		mountColor              = {0x10A, FIELD_WORD},
		frame                   = {0x114, FIELD_WORD},
		forcedState             = {0x122, FIELD_WORD},
		forcedTimer             = {0x124, FIELD_DFLOAT},
        warpIndex               = {0x05A, FIELD_WORD},

        lavaStatus              = {get=playerGetLavaStatus, set=playerSetLavaStatus},

		----------------------------------
		-- LEGACY AUTO-GENERATED FIELDS --
		----------------------------------

		ToadDoubleJReady        = {0x000, FIELD_WORD},
		SparklingEffect         = {0x002, FIELD_WORD},
		UnknownCTRLLock1        = {0x004, FIELD_WORD},
		UnknownCTRLLock2        = {0x006, FIELD_WORD},
		QuicksandEffectTimer    = {0x008, FIELD_WORD},
		OnSlipperyGround        = {0x00A, FIELD_WORD},

		IsAFairy                = {0x00C, FIELD_WORD},
		FairyAlreadyInvoked     = {0x00E, FIELD_WORD},
		FairyFramesLeft         = {0x010, FIELD_WORD},
		SheathHasKey            = {0x012, FIELD_WORD},
		SheathAttackCooldown    = {0x014, FIELD_WORD},
		Hearts                  = {0x016, FIELD_WORD},

		PeachHoverAvailable     = {0x018, FIELD_WORD},
		PressingHoverButton     = {0x01A, FIELD_WORD},
		PeachHoverTimer         = {0x01C, FIELD_WORD},
		Unused1                 = {0x01E, FIELD_WORD},
		PeachHoverTrembleSpeed  = {0x020, FIELD_FLOAT},
		PeachHoverTrembleDir    = {0x024, FIELD_WORD},

		ItemPullupTimer         = {0x026, FIELD_WORD},
		ItemPullupMomentumSave  = {0x028, FIELD_FLOAT},

		-- The following four fields are an incorrect way to read climbingNPC
		-- and are kept for compatibility
		Unused2                 = {0x02C, FIELD_WORD},
		UnkClimbing1            = {0x02E, FIELD_WORD},
		UnkClimbing2            = {0x030, FIELD_WORD},
		UnkClimbing3            = {0x032, FIELD_WORD},

		WaterState              = {0x034, FIELD_WORD},
		WaterOrQuicksandState   = {0x034, FIELD_WORD}, -- alias
		IsInWater               = {0x036, FIELD_WORD},
		WaterStrokeTimer        = {0x038, FIELD_WORD},

		UnknownHoverTimer       = {0x03A, FIELD_WORD},
		SlidingState            = {0x03C, FIELD_WORD},
		SlidingGroundPuffs      = {0x03E, FIELD_WORD},

		ClimbingState           = {0x040, FIELD_WORD},

		UnknownTimer            = {0x042, FIELD_WORD},
		UnknownFlag             = {0x044, FIELD_WORD},
		UnknownPowerupState     = {0x046, FIELD_WORD},
		SlopeRelated            = {0x048, FIELD_WORD},

		TanookiStatueActive     = {0x04A, FIELD_WORD},
		TanookiMorphCooldown    = {0x04C, FIELD_WORD},
		TanookiActiveFrameCount = {0x04E, FIELD_WORD},

		IsSpinjumping           = {0x050, FIELD_WORD},
		SpinjumpStateCounter    = {0x052, FIELD_WORD},
		SpinjumpLandDirection   = {0x054, FIELD_WORD},

		CurrentKillCombo        = {0x056, FIELD_WORD},
		GroundSlidingPuffsState = {0x058, FIELD_WORD},
		WarpNearby              = {0x05A, FIELD_WORD}, -- alias
		NearbyWarpIndex         = {0x05A, FIELD_WORD},
		Unknown5C               = {0x05C, FIELD_WORD},
		Unknown5E               = {0x05E, FIELD_WORD},

		HasJumped               = {0x060, FIELD_WORD},

		CurXPos                 = {0x0C0, FIELD_DFLOAT},
		CurYPos                 = {0x0C8, FIELD_DFLOAT},
		Height                  = {0x0D0, FIELD_DFLOAT},
		Width                   = {0x0D8, FIELD_DFLOAT},
		CurXSpeed               = {0x0E0, FIELD_DFLOAT},
		CurYSpeed               = {0x0E8, FIELD_DFLOAT},

		Identity                = {0x0F0, FIELD_WORD},

		UKeyState               = {0x0F2, FIELD_WORD},
		DKeyState               = {0x0F4, FIELD_WORD},
		LKeyState               = {0x0F6, FIELD_WORD},
		RKeyState               = {0x0F8, FIELD_WORD},
		JKeyState               = {0x0FA, FIELD_WORD},
		SJKeyState              = {0x0FC, FIELD_WORD},
		XKeyState               = {0x0FE, FIELD_WORD},
		RNKeyState              = {0x100, FIELD_WORD},
		SELKeyState             = {0x102, FIELD_WORD},
		STRKeyState             = {0x104, FIELD_WORD},

		FacingDirection         = {0x106, FIELD_WORD},

		MountType               = {0x108, FIELD_WORD},
		MountColor              = {0x10A, FIELD_WORD},
		MountState              = {0x10C, FIELD_WORD},
		MountHeightOffset       = {0x10E, FIELD_WORD},
		MountGfxIndex           = {0x110, FIELD_WORD},

		CurrentPowerup          = {0x112, FIELD_WORD},
		CurrentPlayerSprite     = {0x114, FIELD_WORD},
		Unused116               = {0x116, FIELD_WORD},
		GfxMirrorX              = {0x118, FIELD_FLOAT},
		UpwardJumpingForce      = {0x11C, FIELD_WORD},
		JumpButtonHeld          = {0x11E, FIELD_WORD},
		SpinjumpButtonHeld      = {0x120, FIELD_WORD},

		ForcedAnimationState    = {0x122, FIELD_WORD},
		ForcedAnimationTimer    = {0x124, FIELD_DFLOAT},

		DownButtonMirror        = {0x12C, FIELD_WORD},
		InDuckingPosition       = {0x12E, FIELD_WORD},
		SelectButtonMirror      = {0x130, FIELD_WORD},
		Unknown132              = {0x132, FIELD_WORD},
		DownButtonTapped        = {0x134, FIELD_WORD},
		Unknown136              = {0x136, FIELD_WORD},
		XMomentumPush           = {0x138, FIELD_FLOAT},

		DeathState              = {0x13C, FIELD_WORD},
		DeathTimer              = {0x13E, FIELD_WORD},

		BlinkTimer              = {0x140, FIELD_WORD},
		BlinkState              = {0x142, FIELD_WORD},
		Unknown144              = {0x144, FIELD_WORD},

		LayerStateStanding      = {0x146, FIELD_WORD},
		LayerStateLeftContact   = {0x148, FIELD_WORD},
		LayerStateTopContact    = {0x14A, FIELD_WORD},
		LayerStateRightContact  = {0x14C, FIELD_WORD},
		PushedByMovingLayer     = {0x14E, FIELD_WORD},
		Unused150               = {0x150, FIELD_WORD},
		Unused152               = {0x152, FIELD_WORD},

		HeldNPCIndex            = {0x154, FIELD_WORD},
		Unknown156              = {0x156, FIELD_WORD},
		PowerupBoxContents      = {0x158, FIELD_WORD},

		CurrentSection          = {0x15A, FIELD_WORD},
		WarpTimer               = {0x15C, FIELD_WORD}, -- alias
		WarpCooldownTimer       = {0x15C, FIELD_WORD},
		TargetWarpIndex         = {0x15E, FIELD_WORD},

		ProjectileTimer1        = {0x160, FIELD_WORD},
		ProjectileTimer2        = {0x162, FIELD_WORD},
		TailswipeTimer          = {0x164, FIELD_WORD},
		Unknown166              = {0x166, FIELD_WORD},

		TakeoffSpeed            = {0x168, FIELD_FLOAT},
		CanFly                  = {0x16C, FIELD_WORD},
		IsFlying                = {0x16E, FIELD_WORD},
		FlightTimeRemaining     = {0x170, FIELD_WORD},
		HoldingFlightRunButton  = {0x172, FIELD_WORD},
		HoldingFlightButton     = {0x174, FIELD_WORD},

		NPCBeingStoodOnIndex    = {0x176, FIELD_WORD},
		Unknown178              = {0x178, FIELD_WORD},

		Unknown17A              = {0x17A, FIELD_WORD},
		Unused17C               = {0x17C, FIELD_WORD},
		Unused17E               = {0x17E, FIELD_WORD},
		Unused180               = {0x180, FIELD_WORD},
		Unused182               = {0x182, FIELD_WORD},
}

-----------------------
-- CLASS DECLARATION --
-----------------------

local Player = {__type="Player"}
local PlayerMT = ffi_utils.implementClassMT("Player", Player, PlayerFields, playerGetIsValid)
local PlayerCache = {}

-- Declare this function first so it can be used in the constructor without its definition being out of place
local registerKeys

-- Constructor
setmetatable(Player, {__call=function(Player, idx)
	-- Default to idx 1 if given nil for some reason (apparently this is needed for compatibility)
	if (idx == nil) then
		idx = 1
	end

	if PlayerCache[idx] then
		return PlayerCache[idx]
	end

	local ptr = 0
	if (idx < 201) then
		-- Regular player object
		ptr = GM_PLAYERS_ADDR + idx*0x184
	elseif (idx >= 1000) then
		-- Character template player object
		ptr = LunaDLL.LunaLuaGetTemplateAddressForCharacter(idx-1000)
	end

	if (ptr == 0) then
		-- Invalid player object index
		error("Invalid player index")
	end

	local pl = {_idx=idx, _ptr=ptr}
	setmetatable(pl, PlayerMT)
	PlayerCache[idx] = pl
	registerKeys(pl)
	return pl
end})

----------------
-- KEYS TABLE --
----------------

local keysList = {
	"up",
	"down",
	"left",
	"right",
	"jump",
	"altJump",
	"run",
	"altRun",
	"dropItem",
	"pause"
}

local keysMap = {}
for _,v in ipairs(keysList) do
	keysMap[v] = PlayerFields[v .. "KeyPressing"][1]
end

local KEYS_UP = false
local KEYS_RELEASED = nil
local KEYS_PRESSED = 1
local KEYS_DOWN = true

local keysMT = {}
function keysMT.__index(tbl, key)
	local last = tbl._last[key] or false
	local now = tbl._now[key] or false
	if (not last) and (not now) then
		return KEYS_UP
	elseif last and (not now) then
		return KEYS_RELEASED
	elseif (not last) and now then
		return KEYS_PRESSED
	elseif last and now then
		return KEYS_DOWN
	end
end

function keysMT.__newindex(tbl, key, val)
	--Explicitly convert val to a boolean
	if val then
		val = true
	else
		val = false
	end
	tbl._parent:mem(keysMap[key], FIELD_BOOL, val)
end

do
	local keysNextMap = {};

	for k,v in ipairs(keysList) do
		keysNextMap[v] = keysList[k+1];
	end
	keysNextMap[""] = keysList[1];

	local function iter(t, k)
		local v = keysNextMap[k];
		if v ~= nil then
			return v,t[v];
		end
	end

	function keysMT.__pairs(tbl)
		return iter, tbl, "";
	end
end

function registerKeys(obj)
	local keys = {}
	keys._last = {}
	keys._now = {}
	keys._parent = obj
	setmetatable(keys, keysMT)

	local nowMT = {}
	function nowMT.__index(tbl, key)
		return obj:mem(keysMap[key], FIELD_BOOL)
	end
	setmetatable(keys._now, nowMT)

	playerKeys[obj.idx] = keys
end

local lastKeys

local keyseventtable = {}

--WEIRD workaround for the odd overworld input loop
if isOverworld then
	lastKeys = {}
	local function updateOverworldKeys()
		for _,p in ipairs(Player.get()) do
			lastKeys[p] = lastKeys[p] or {}
			lastKeys[p].left = p.keys._now.left
			lastKeys[p].right = p.keys._now.right
		end
	end
	keyseventtable.onDraw = updateOverworldKeys
end

local function updateKeys()
	for _,p in ipairs(Player.get()) do
		for _,key in ipairs(keysList) do
			if isOverworld and lastKeys[p][key] then
				p.keys._last[key] = lastKeys[p][key]
			else
				p.keys._last[key] = p.keys._now[key]
			end
		end
	end
end

if isOverworld then
	registerEvent(keyseventtable, "onDraw", "onDraw", false)
end

keyseventtable.onDrawEnd = updateKeys
registerEvent(keyseventtable, "onDrawEnd", "onDrawEnd", false)

--------------
-- RAW KEYS --
--------------

local function setupRawKeys(idx)
	local idx = idx - 1
	if (idx ~= 0) and (idx ~= 1) then
		return nil
	end
	
	local rawKeysMT = {
	__index = function(tbl, key)
		if keysMap[key] == nil then
			return nil
		end
		local now = rawKeymap[idx][key] ~= 0
		local last = rawKeymap[idx+2][key] ~= 0
		if (not last) and (not now) then
			return KEYS_UP
		elseif last and (not now) then
			return KEYS_RELEASED
		elseif (not last) and now then
			return KEYS_PRESSED
		elseif last and now then
			return KEYS_DOWN
		end
	end,
	__newindex = function(tbl, key, val)
	end
	}
	
	rawKeysMT.__pairs = keysMT.__pairs
	
	rawPlayerKeys[idx+1] = setmetatable({}, rawKeysMT)
end
setupRawKeys(1)
setupRawKeys(2)

-------------------------
-- METHOD DECLARATIONS --
-------------------------

-- 'mem' implementation
function Player:mem(offset, dtype, val)
	if not playerGetIsValid(self) then
		error("Invalid player object")
	end

	return mem(self._ptr + offset, dtype, val)
end

-- 'kill' implementation
function Player:kill()
	if not playerGetIsValid(self) then
		error("Invalid player object")
	end

	if (self.idx >= 1000) then
		error("Cannot kill template players")
	end

	-- Don't use FFI call since this can trigger Lua events
	Misc._playerKill(self.idx)
end

-- 'harm' implementation
function Player:harm()
	if not playerGetIsValid(self) then
		error("Invalid player object")
	end

	if (self.idx >= 1000) then
		error("Cannot harm template players")
	end

	-- Don't use FFI call since this can trigger Lua events
	Misc._playerHarm(self.idx)
end

-- 'teleport' implementation
function Player:teleport(x, y, bottomCenterAligned)
	if not playerGetIsValid(self) then
		error("Invalid player object")
	end

	if (self.idx >= 1000) then
		error("Cannot teleport template players")
	end

	-- If using bottom center aligned coordinates, handle that sensibly
	if bottomCenterAligned then
		x = x - (self.width * 0.5)
		y = y - self.height
	end

	-- Move the player and update section, including music
	local oldSection = self.section
	local newSection = Section.getIdxFromCoords(x, y)
	self.x, self.y = x, y
	if (newSection ~= oldSection) then
		self.section = newSection
		playMusic(newSection)
	end
end

-- 'getCurrentPlayerSetting' implementation
function Player:getCurrentPlayerSetting()
	if not playerGetIsValid(self) then
		error("Invalid player object")
	end

	return PlayerSettings.get(self.character, self.powerup)
end

-- 'getCurrentSpriteIndex' implementation
function Player:getCurrentSpriteIndex()
	if not playerGetIsValid(self) then
		error("Invalid player object")
	end

	-- Port of the C++ implementation
	local index = self.CurrentPlayerSprite * self.FacingDirection

	y = math.floor((index + 49) % 10)
	x = math.floor(((index + 49) - (index + 49) % 10) / 10)
	return x, y
end

-- 'setCurrentSpriteIndex' implementation
function Player:setCurrentSpriteIndex(indexX, indexY, forceDirection)
	if (type(indexX) ~= "number") or (type(indexX) ~= "number") then
		error("Invalid parameters to setCurrentSpriteIndex")
	end

	if not playerGetIsValid(self) then
		error("Invalid player object")
	end

	-- Port of the C++ implementation
	local index = (indexY + 10 * indexX) - 49

	if forceDirection then
		if index < 0 then
			self.FacingDirection = -1
		else
			self.FacingDirection = 1
		end
	end
	self.CurrentPlayerSprite = index
end

-- 'transform' implementation
function Player:transform(id, effect)

	if(self.character == id) then return end

	local temp = Player.getTemplate(self.character);
	for i=0x00,0x182,0x02 do
		temp:mem(i,FIELD_WORD,self:mem(i,FIELD_WORD));
	end
	temp = Player.getTemplate(id);
	self.powerup = temp.powerup;
	self.reservePowerup = temp.reservePowerup;
	self:mem(0x108, FIELD_WORD, temp:mem(0x108,FIELD_WORD));
	self:mem(0x10A, FIELD_WORD, temp:mem(0x10A,FIELD_WORD));
	self:mem(0x16, FIELD_WORD, temp:mem(0x16,FIELD_WORD));

	self.character = id;

	if(effect) then
		self:mem(0x140, FIELD_WORD, 50);
		local a = Animation.spawn(10, self.x+self.width*0.5, self.y+self.height*0.5);
		a.x = a.x - a.width*0.5;
		a.y = a.y - a.height*0.5;
		Audio.playSFX(34);
	end
end

function Player:isGroundTouching()
	return self:mem(0x146, FIELD_WORD) ~= 0 or self:mem(0x48, FIELD_WORD) ~= 0 or self:mem(0x176, FIELD_WORD) ~= 0
end

Player.isOnGround = Player.isGroundTouching;

function Player:isClimbing()
	return self:mem(0x40, FIELD_WORD) >= 2
end

function Player:isInvincible()
	return ((Defines.cheat_donthurtme) or (self:mem(0x140, FIELD_WORD) ~= 0)) --or (self.isMega) or (self.hasStarman)
end

if isOverworld then
	function Player:_isMega()
		return false
	end
	function Player:_hasStarman()
		return false
	end
end

--------------------
-- STATIC METHODS --
--------------------

function Player.count()
    return mem(GM_PLAYERS_COUNT_ADDR, FIELD_WORD)
end

function Player.setCount(count)
    if count == nil then
        return mem(GM_PLAYERS_COUNT_ADDR, FIELD_WORD)
    elseif count == 0 then
        error("You can't set the count to 0")
        return
    elseif count >= 201 then
        error("You can't set the count higher than 201")
        return
    elseif count then
        return mem(GM_PLAYERS_COUNT_ADDR, FIELD_WORD, count)
    end
end

local getMT = {__pairs = ipairs}

function Player.get()
	local ret = {}
	for idx=1,Player.count() do
		ret[#ret+1] = Player(idx)
	end
	setmetatable(ret, getMT)
	return ret
end

function Player.getIntersecting(x1, y1, x2, y2)
	if (type(x1) ~= "number") or (type(y1) ~= "number") or (type(x2) ~= "number") or (type(y2) ~= "number") then
		error("Invalid parameters to getIntersecting")
	end

	local ret = {}
	for idx=1,Player.count() do
		local pl = Player(idx)
		if ((x2 > pl.x) and
		    (y2 > pl.y) and
			(pl.x + pl.width > x1) and
			(pl.y + pl.height > y1)) then
			ret[#ret+1] = pl
		end
	end
	setmetatable(ret, getMT)
	return ret
end

function Player.getNearest(x, y)
	if type(x) ~= "number" or type(y) ~= "number" then
		error("Invalid parameters to getNearest")
	end
	local players = Player.get()
	if #players == 1 then
		return players[1]
	else
		local p
		local dist = math.huge
		for _, v in ipairs(players) do
			if not v:mem(0x13C, FIELD_BOOL) then
				local dx, dy = math.abs(v.x + v.width / 2 - x), math.abs(v.y + v.height / 2 - y)
				local cdist = math.sqrt(dx * dx + dy * dy)
				if cdist < dist then
					dist = cdist
					p = v
				end
			end
		end
		return p or player
	end
end

function Player.getTemplate(id)
	return Player(id + 1000)
end

function Player.getTemplates()
	local arr = LunaDLL.LunaLuaGetValidCharacterIDArray()
	local ret = {}

	local idx=0
	while arr[idx] ~= 0 do
		ret[arr[idx]] = Player(arr[idx] + 1000)
		idx = idx + 1
	end
	return ret
end

---------------------------
-- SET GLOBAL AND RETURN --
---------------------------
_G.Player = Player
_G.player = Player(1)
if (_G.player2 ~= nil) or (Player.count() > 1) then
	_G.player2 = Player(2)
end

_G.KEYS_UP = KEYS_UP
_G.KEYS_RELEASED = KEYS_RELEASED
_G.KEYS_PRESSED = KEYS_PRESSED
_G.KEYS_DOWN = KEYS_DOWN

return Player
