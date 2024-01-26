------------------------------
-- Profiler memory checking --
------------------------------

do
	ffi.cdef([[
		typedef struct
		{
			uint32_t totalWorking;
			uint32_t imgRawMem;
			uint32_t imgCompMem;
			uint32_t sndMem;
			double   imgGpuMem;
		} LunaLuaMemUsageData;
		const LunaLuaMemUsageData* LunaLuaGetMemUsage();
	]])
	local LunaDLL = ffi.load("LunaDll.dll")
	
	Misc.GetMemUsage = function()
		local data = LunaDLL.LunaLuaGetMemUsage()
		return {
			totalWorking = data.totalWorking,
			imgRawMem    = data.imgRawMem,
			imgCompMem   = data.imgCompMem,
			sndMem       = data.sndMem,
			imgGpuMem    = data.imgGpuMem
		}
	end
end

---------------------------
-- High resolution clock --
---------------------------
do
	ffi.cdef[[
		typedef long            BOOL;
		BOOL QueryPerformanceFrequency(int64_t *lpFrequency);
		BOOL QueryPerformanceCounter(int64_t *lpPerformanceCount);
	]]
	local kernel32 = ffi.load("kernel32.dll")
	
	local function GetPerformanceFrequency()
		local anum = ffi.new("int64_t[1]")
		if kernel32.QueryPerformanceFrequency(anum) == 0 then
			return nil
		end
		return tonumber(anum[0])
	end
	local function GetPerformanceCounter()
		local anum = ffi.new("int64_t[1]")
		if kernel32.QueryPerformanceCounter(anum) == 0 then
			return nil
		end
		return tonumber(anum[0])
	end
	local performanceCounterFreq = GetPerformanceFrequency()
	Misc.clock = function()
		return GetPerformanceCounter() / performanceCounterFreq
	end
end

---------------------
-- Key state array --
---------------------

do
	ffi.cdef([[
		unsigned char* LunaLuaGetKeyStateArray();
	]])
	local LunaDLL = ffi.load("LunaDll.dll")
	local keyArray = LunaDLL.LunaLuaGetKeyStateArray()
	
	function Misc.GetKeyState(keycode)
		if (type(keycode) ~= "number") or (keycode < 0) or (keycode > 255) then
			error("Invalid keycode")
		end
		return keyArray[keycode] ~= 0
	end
end

--------------
-- GameData --
--------------

do
	ffi.cdef([[
		typedef struct
		{
			int len;
			char data[0];
		} GameDataStruct;
		
		void LunaLuaSetGameData(const char* dataPtr, int dataLen);
		GameDataStruct* LunaLuaGetGameData();
		void LunaLuaFreeReturnedGameData(GameDataStruct* cpy);
	]])
	local LunaDLL = ffi.load("LunaDll.dll")
	
	function Misc.SetRawGameData(v)
		LunaDLL.LunaLuaSetGameData(v, #v)
	end
	
	function Misc.GetRawGameData()
		local ptr = LunaDLL.LunaLuaGetGameData();
		if ptr == nil then
			return ""
		end
		local ret = ffi.string(ptr.data, ptr.len)
		LunaDLL.LunaLuaFreeReturnedGameData(ptr)
		return ret
	end
end

--------------------------------
-- Get controller information --
--------------------------------

do
	ffi.cdef([[
		int LunaLuaGetSelectedControllerPowerLevel(int playerNum);
		const char* LunaLuaGetSelectedControllerName(int playerNum);
		void LunaLuaRumbleSelectedController(int playerNum, int ms, float strength);
	]])
	local LunaDLL = ffi.load("LunaDll.dll")
	
	function Misc.GetSelectedControllerPowerLevel(playerNum)
		if (playerNum == nil) then
			playerNum = 1
		end
		return LunaDLL.LunaLuaGetSelectedControllerPowerLevel(playerNum)
	end
	
	function Misc.GetSelectedControllerName(playerNum)
		if (playerNum == nil) then
			playerNum = 1
		end
		local strPtr = LunaDLL.LunaLuaGetSelectedControllerName(playerNum)
		if strPtr == nil then
			return "Unknown"
		end
		return ffi.string(strPtr)
	end
	
	function Misc.RumbleSelectedController(playerNum, ms, strength)
		if (playerNum == nil) then
			playerNum = 1
		end
		if (ms == nil) then
			ms = 1000
		end
		if (strength == nil) then
			strength = 1.0
		end
		if (ms > 0) and (strength > 0) then
			LunaDLL.LunaLuaRumbleSelectedController(playerNum, ms, strength)
		end
	end
end

---------------------
-- Disabling fixes --
---------------------

do
	ffi.cdef([[
		void LunaLuaSetPlayerFilterBounceFix(bool enable);
		void LunaLuaSetPlayerDownwardClipFix(bool enable);
		void LunaLuaSetNPCDownwardClipFix(bool enable);
	]])
	local LunaDLL = ffi.load("LunaDll.dll")

	function Misc.SetPlayerFilterBounceFix(enable)
		if enable then
			enable = true
		else
			enable = false
		end
		LunaDLL.LunaLuaSetPlayerFilterBounceFix(enable)
	end
	
	function Misc.SetPlayerDownwardClipFix(enable)
		if enable then
			enable = true
		else
			enable = false
		end
		LunaDLL.LunaLuaSetPlayerDownwardClipFix(enable)
	end
	
	function Misc.SetNPCDownwardClipFix(enable)
		if enable then
			enable = true
		else
			enable = false
		end
		LunaDLL.LunaLuaSetNPCDownwardClipFix(enable)
	end
end

------------
-- Timing --
------------

do
	ffi.cdef([[
        void LunaLuaSetFrameTiming(double value);
        double LunaLuaGetFrameTiming();
	]])
	local LunaDLL = ffi.load("LunaDll.dll")
	
	local currentTickTimeMs = LunaDLL.LunaLuaGetFrameTiming()
	local currentTps = 1000.0 / currentTickTimeMs
	local currentSpeed = 15.6 / currentTickTimeMs
	
	function Misc.SetEngineTickDuration(t)
		if (currentTickTimeMs ~= t) then
			if (lunatime ~= nil) and (lunatime._notifyTickDurationChange ~= nil) then
				lunatime._notifyTickDurationChange()
			end
			LunaDLL.LunaLuaSetFrameTiming(t)
			currentTickTimeMs = t
			currentTps = 1000.0 / t
			currentSpeed = 15.6 / t
		end
	end
	local Misc_SetEngineTickDuration = Misc.SetEngineTickDuration
	
	function Misc.GetEngineTickDuration(t)
		return currentTickTimeMs
	end
	
	function Misc.SetEngineTPS(tps)
		Misc_SetEngineTickDuration(1000.0 / tps)
	end
	
	function Misc.GetEngineTPS(tps)
		return currentTps
	end
	
	function Misc.SetEngineSpeed(ratio)
		Misc_SetEngineTickDuration(15.6 / ratio)
	end
	
	function Misc.GetEngineSpeed(ratio)
		return currentSpeed
	end
end

do
	ffi.cdef([[
		void LunaLuaSetBackgroundRenderFlag(bool val);
	]])
	local LunaDLL = ffi.load("LunaDll.dll")

	function Misc._SetVanillaBackgroundRenderFlag(val)
		LunaDLL.LunaLuaSetBackgroundRenderFlag(val)
	end
end

do
	-- mda wuz ere (:<
	--Spencer Everly lol
	ffi.cdef([[
		typedef struct _LunaImageRef LunaImageRef;
        
		void LunaLuaSetWindowTitle(const char* newName);
		void LunaLuaSetWindowIcon(LunaImageRef* img, int iconType);
        
        void LunaLuaSetWindowPosition(int x, int y);
        void LunaLuaToggleWindowFocus(bool enable);
        void LunaLuaCenterWindow();
        void LunaLuaSetFullscreen(bool enable);
        double LunaLuaGetXWindowPosition();
        double LunaLuaGetYWindowPosition();
        double LunaLuaGetXWindowPositionCenter();
        double LunaLuaGetYWindowPositionCenter();
        void LunaLuaSetWindowSize(int width, int height);
        int LunaLuaGetWindowWidth();
        int LunaLuaGetWindowHeight();
        bool LunaLuaIsFullscreen();
        bool LunaLuaIsRecordingGIF();
        bool LunaLuaIsFocused();
        double LunaLuaGetScreenResolutionWidth();
        double LunaLuaGetScreenResolutionHeight();
        bool LunaLuaIsSetToRunWhenUnfocused();
        
        void LunaLuaTestModeDisable(void);
        void LunaLuaTestModeEditLevel(const char* filename);
        bool LunaLuaInSMASPlusPlus();
        void LunaLuaSetEpisodeName(const char* name);
        
        void LunaLuaSetWeakLava(bool value);
        bool LunaLuaGetWeakLava();
        
        void LunaLuaSetCursor(LunaImageRef* img, uint32_t xHotspot, uint32_t yHotspot);
        void LunaLuaSetCursorHide(void);
        
        typedef struct
		{
			double x;
            double y;
		} MousePos;
        
        MousePos LunaLuaGetMousePosition();
        
        void LunaLuaSetSEEModFeatureBool(bool enable);
        bool LunaLuaGetSEEModFeatureBool();
	]])
	local LunaDLL = ffi.load("LunaDll.dll")

	function Misc.setWindowTitle(newName)
		if type(newName) ~= "string" then
			error("Invalid type for window title.")
		end

		-- Originally implemented via C++ side but it's here now
		-- for consistency with setWindowIcon, since it needed it.
		LunaDLL.LunaLuaSetWindowTitle(newName)
	end

	function Misc.setWindowIcon(iconImageSmall,iconImageBig)
		if type(iconImageSmall) ~= "LuaImageResource" then
			error("Invalid type for window icon.")
		end

		if iconImageBig == nil then
			-- Only one image, use small for both
			LunaDLL.LunaLuaSetWindowIcon(iconImageSmall._ref,0)
		elseif type(iconImageBig) == "LuaImageResource" then
			-- Two images, use each
			LunaDLL.LunaLuaSetWindowIcon(iconImageSmall._ref,1)
			LunaDLL.LunaLuaSetWindowIcon(iconImageBig._ref,2)
		else
			error("Invalid type for window icon.")
		end

		--[[local smallImageRef,bigImageRef

		if type(iconImageSmall) == "LuaImageResource" then
			smallImageRef = iconImageSmall._ref

			if type(iconImageBig) == "LuaImageResource" then
				bigImageRef = iconImageBig._ref
			elseif iconImageBig == nil then
				bigImageRef = smallImageRef
			else
				error("Invalid type for window icon.")
			end
		else
			error("Invalid type for window icon.")
		end

		LunaDLL.LunaLuaSetWindowIcon(smallImageRef,bigImageRef)]]
	end
    
    
    function Misc.setWindowPosition(x, y)
        if x == nil then
            return
        end
        if y == nil then
            return
        end
        LunaDLL.LunaLuaSetWindowPosition(x, y)
    end
    function Misc.runWhenUnfocused(enable)
        if enable == nil then
            Misc.warn("Value has not been set.")
            return
        end
        if enable then
            enable = true
        else
            enable = false
        end
        LunaDLL.LunaLuaToggleWindowFocus(enable)
    end
    function Misc.centerWindow()
        LunaDLL.LunaLuaCenterWindow()
    end
    function Misc.setFullscreen(enable)
        if enable == nil then
            Misc.warn("Value has not been set.")
            return
        end
        if enable then
            enable = true
        else
            enable = false
        end
        LunaDLL.LunaLuaSetFullscreen(enable)
    end
    function Misc.getWindowXPosition()
        return LunaDLL.LunaLuaGetXWindowPosition()
    end
    function Misc.getWindowYPosition()
        return LunaDLL.LunaLuaGetYWindowPosition()
    end
    function Misc.getCenterWindowXPosition()
        return LunaDLL.LunaLuaGetXWindowPositionCenter()
    end
    function Misc.getCenterWindowYPosition()
        return LunaDLL.LunaLuaGetYWindowPositionCenter()
    end
    function Misc.isFullscreen()
        return LunaDLL.LunaLuaIsFullscreen()
    end
    function Misc.isGIFRecording()
        return LunaDLL.LunaLuaIsRecordingGIF()
    end
    function Misc.isWindowFocused()
        return LunaDLL.LunaLuaIsFocused()
    end
    function Misc.getWidthScreenResolution()
        return LunaDLL.LunaLuaGetScreenResolutionWidth()
    end
    function Misc.getHeightScreenResolution()
        return LunaDLL.LunaLuaGetScreenResolutionHeight()
    end
    function Misc.isSetToRunWhenUnfocused()
        return LunaDLL.LunaLuaIsSetToRunWhenUnfocused()
    end
    
    function Misc.setNewTestModeLevelData(newLevel)
        if not Misc.inEditor() then
            return
        end
        
		if type(newLevel) ~= "string" then
            error("Invalid type for level name.")
            return
		end
        
		LunaDLL.LunaLuaTestModeEditLevel(Misc.episodePath()..newLevel)
	end
    
    function Misc.inSuperMarioAllStarsPlusPlus()
		LunaDLL.LunaLuaInSMASPlusPlus()
	end
    
    function Misc.setEpisodeName(newName)
		LunaDLL.LunaLuaSetEpisodeName(newName)
	end
    
    function Misc.setWeakLava(boole)
        if type(newLevel) ~= "boolean" then
			error("Invalid type for weak lava setting.")
            return
		end
        
        LunaDLL.LunaLuaSetWeakLava(boole)
    end
    
    function Misc.getWeakLava()
        return LunaDLL.LunaLuaGetWeakLava()
    end
    
    function Misc.setCursor(cursor,xHotspot,yHotspot)
        if xHotspot == nil then
            xHotspot = 0
        end
        if yHotspot == nil then
            yHotspot = 0
        end
        
        local imgRef
        
        if cursor == nil then
            return LunaDLL.LunaLuaSetCursor(nil,xHotspot,yHotspot)
        end
        
        if type(cursor) == "boolean" and cursor == false then
            return LunaDLL.LunaLuaSetCursorHide()
        end
        
        if type(cursor) ~= "LuaImageResource" then
			error("Invalid type for cursor image.")
            return
		end
        
        if type(cursor) == "LuaImageResource" then
            imgRef = cursor._ref
        end
        
        
        LunaDLL.LunaLuaSetCursor(imgRef,xHotspot,yHotspot)
    end
    
    function Misc.getCursorPosition()
        local data = LunaDLL.LunaLuaGetMousePosition()
        return {
            data.x,
            data.y,
        }
    end
    
    function Misc.SEEModFeaturesSetBool(enable)
        if type(enable) == "boolean" then
            LunaDLL.LunaLuaSetSEEModFeatureBool(enable)
        else
            error("Invalid type for toggle.")
            return
        end
    end
    
    function Misc.SEEModFeaturesGetBool()
        return LunaDLL.LunaLuaGetSEEModFeatureBool()
    end
end
