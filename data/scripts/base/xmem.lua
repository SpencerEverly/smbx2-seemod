--USAGE WARNING
--This library is highly subject to future changes that will almost certainly break code using it. Use this library at your own risk.

local xmem = {}
local textplus = require("textplus");

local FONT = {priority = 10, xscale=1, yscale=1, font = textplus.loadFont("textplus/font/6.ini")}

local filename;
local logFile;
local startClock;
local framecount;


xmem.NPC_MEM = {}
do --Define NPC mem types
xmem.NPC_MEM[0x00] = FIELD_STRING
xmem.NPC_MEM[0x04] = FIELD_WORD
xmem.NPC_MEM[0x06] = FIELD_WORD
xmem.NPC_MEM[0x08] = FIELD_BOOL
xmem.NPC_MEM[0x0A] = FIELD_WORD
xmem.NPC_MEM[0x0C] = FIELD_WORD
xmem.NPC_MEM[0x0E] = FIELD_WORD
xmem.NPC_MEM[0x10] = FIELD_WORD
xmem.NPC_MEM[0x12] = FIELD_WORD
xmem.NPC_MEM[0x14] = FIELD_WORD
xmem.NPC_MEM[0x16] = FIELD_WORD
xmem.NPC_MEM[0x18] = FIELD_FLOAT
xmem.NPC_MEM[0x1C] = FIELD_WORD
xmem.NPC_MEM[0x1E] = FIELD_WORD
xmem.NPC_MEM[0x20] = FIELD_WORD
xmem.NPC_MEM[0x22] = FIELD_WORD
xmem.NPC_MEM[0x24] = FIELD_WORD
xmem.NPC_MEM[0x26] = FIELD_WORD
xmem.NPC_MEM[0x28] = FIELD_WORD
xmem.NPC_MEM[0x2A] = FIELD_WORD
xmem.NPC_MEM[0x2C] = FIELD_STRING
xmem.NPC_MEM[0x30] = FIELD_STRING
xmem.NPC_MEM[0x34] = FIELD_STRING
xmem.NPC_MEM[0x38] = FIELD_STRING
xmem.NPC_MEM[0x3C] = FIELD_STRING
xmem.NPC_MEM[0x40] = FIELD_BOOL
xmem.NPC_MEM[0x42] = FIELD_BOOL
xmem.NPC_MEM[0x44] = FIELD_BOOL
xmem.NPC_MEM[0x46] = FIELD_BOOL
xmem.NPC_MEM[0x48] = FIELD_BOOL
xmem.NPC_MEM[0x4A] = FIELD_BOOL
xmem.NPC_MEM[0x4C] = FIELD_STRING
xmem.NPC_MEM[0x50] = FIELD_FLOAT
xmem.NPC_MEM[0x54] = FIELD_WORD
xmem.NPC_MEM[0x56] = FIELD_WORD
xmem.NPC_MEM[0x58] = FIELD_WORD
xmem.NPC_MEM[0x5A] = FIELD_WORD
xmem.NPC_MEM[0x5C] = FIELD_FLOAT
xmem.NPC_MEM[0x60] = FIELD_WORD
xmem.NPC_MEM[0x62] = FIELD_WORD
xmem.NPC_MEM[0x64] = FIELD_WORD
xmem.NPC_MEM[0x68] = FIELD_WORD
xmem.NPC_MEM[0x6A] = FIELD_WORD
xmem.NPC_MEM[0x6C] = FIELD_FLOAT
xmem.NPC_MEM[0x70] = FIELD_WORD
xmem.NPC_MEM[0x72] = FIELD_WORD
xmem.NPC_MEM[0x74] = FIELD_BOOL
xmem.NPC_MEM[0x76] = FIELD_WORD
xmem.NPC_MEM[0x78] = FIELD_DFLOAT
xmem.NPC_MEM[0x80] = FIELD_DFLOAT
xmem.NPC_MEM[0x88] = FIELD_DFLOAT
xmem.NPC_MEM[0x90] = FIELD_DFLOAT
xmem.NPC_MEM[0x98] = FIELD_DFLOAT
xmem.NPC_MEM[0xA0] = FIELD_DFLOAT
xmem.NPC_MEM[0xA8] = FIELD_DFLOAT
xmem.NPC_MEM[0xB0] = FIELD_DFLOAT
xmem.NPC_MEM[0xB8] = FIELD_DFLOAT
xmem.NPC_MEM[0xC0] = FIELD_DFLOAT
xmem.NPC_MEM[0xC8] = FIELD_WORD
xmem.NPC_MEM[0xCA] = FIELD_WORD
xmem.NPC_MEM[0xCC] = FIELD_WORD
xmem.NPC_MEM[0xCE] = FIELD_WORD
xmem.NPC_MEM[0xD0] = FIELD_WORD
xmem.NPC_MEM[0xD2] = FIELD_WORD
xmem.NPC_MEM[0xD4] = FIELD_WORD
xmem.NPC_MEM[0xD6] = FIELD_WORD
xmem.NPC_MEM[0xD8] = FIELD_FLOAT
xmem.NPC_MEM[0xDC] = FIELD_WORD
xmem.NPC_MEM[0xDE] = FIELD_WORD
xmem.NPC_MEM[0xE0] = FIELD_WORD
xmem.NPC_MEM[0xE2] = FIELD_WORD
xmem.NPC_MEM[0xE4] = FIELD_WORD
xmem.NPC_MEM[0xE6] = FIELD_WORD
xmem.NPC_MEM[0xE8] = FIELD_FLOAT
xmem.NPC_MEM[0xEC] = FIELD_FLOAT
xmem.NPC_MEM[0xF0] = FIELD_DFLOAT
xmem.NPC_MEM[0xF8] = FIELD_DFLOAT
xmem.NPC_MEM[0x100] = FIELD_DFLOAT
xmem.NPC_MEM[0x108] = FIELD_DFLOAT
xmem.NPC_MEM[0x110] = FIELD_DFLOAT
xmem.NPC_MEM[0x118] = FIELD_FLOAT
xmem.NPC_MEM[0x11C] = FIELD_FLOAT
xmem.NPC_MEM[0x120] = FIELD_BOOL
xmem.NPC_MEM[0x122] = FIELD_BOOL
xmem.NPC_MEM[0x124] = FIELD_BOOL
xmem.NPC_MEM[0x126] = FIELD_BOOL
xmem.NPC_MEM[0x128] = FIELD_BOOL
xmem.NPC_MEM[0x12A] = FIELD_WORD
xmem.NPC_MEM[0x12C] = FIELD_WORD
xmem.NPC_MEM[0x12E] = FIELD_WORD
xmem.NPC_MEM[0x130] = FIELD_WORD
xmem.NPC_MEM[0x132] = FIELD_WORD
xmem.NPC_MEM[0x134] = FIELD_WORD
xmem.NPC_MEM[0x136] = FIELD_BOOL
xmem.NPC_MEM[0x138] = FIELD_WORD
xmem.NPC_MEM[0x13A] = FIELD_WORD
xmem.NPC_MEM[0x13C] = FIELD_DFLOAT
xmem.NPC_MEM[0x144] = FIELD_WORD
xmem.NPC_MEM[0x146] = FIELD_WORD
xmem.NPC_MEM[0x148] = FIELD_FLOAT
xmem.NPC_MEM[0x14C] = FIELD_WORD
xmem.NPC_MEM[0x14E] = FIELD_WORD
xmem.NPC_MEM[0x150] = FIELD_WORD
xmem.NPC_MEM[0x152] = FIELD_WORD
xmem.NPC_MEM[0x154] = FIELD_WORD
xmem.NPC_MEM[0x156] = FIELD_WORD
end

xmem.BLOCK_MEM = {}
do --Define BLOCK mem types
xmem.BLOCK_MEM[0x00] = FIELD_WORD
xmem.BLOCK_MEM[0x02] = FIELD_WORD
xmem.BLOCK_MEM[0x04] = FIELD_WORD
xmem.BLOCK_MEM[0x06] = FIELD_WORD
xmem.BLOCK_MEM[0x08] = FIELD_BOOL
xmem.BLOCK_MEM[0x0A] = FIELD_WORD
xmem.BLOCK_MEM[0x0C] = FIELD_STRING
xmem.BLOCK_MEM[0x10] = FIELD_STRING
xmem.BLOCK_MEM[0x14] = FIELD_STRING
xmem.BLOCK_MEM[0x18] = FIELD_STRING
xmem.BLOCK_MEM[0x1C] = FIELD_WORD
xmem.BLOCK_MEM[0x1E] = FIELD_WORD
xmem.BLOCK_MEM[0x20] = FIELD_DFLOAT
xmem.BLOCK_MEM[0x28] = FIELD_DFLOAT
xmem.BLOCK_MEM[0x30] = FIELD_DFLOAT
xmem.BLOCK_MEM[0x38] = FIELD_DFLOAT
xmem.BLOCK_MEM[0x40] = FIELD_DFLOAT
xmem.BLOCK_MEM[0x48] = FIELD_DFLOAT
xmem.BLOCK_MEM[0x50] = FIELD_WORD
xmem.BLOCK_MEM[0x52] = FIELD_WORD
xmem.BLOCK_MEM[0x54] = FIELD_WORD
xmem.BLOCK_MEM[0x56] = FIELD_WORD
xmem.BLOCK_MEM[0x58] = FIELD_WORD
xmem.BLOCK_MEM[0x5A] = FIELD_WORD
xmem.BLOCK_MEM[0x5C] = FIELD_WORD
xmem.BLOCK_MEM[0x5E] = FIELD_WORD
xmem.BLOCK_MEM[0x60] = FIELD_WORD
xmem.BLOCK_MEM[0x62] = FIELD_WORD
xmem.BLOCK_MEM[0x64] = FIELD_WORD
xmem.BLOCK_MEM[0x66] = FIELD_WORD
end


xmem.PLAYER_MEM = {}
do --Define Player mem types
xmem.PLAYER_MEM[0x00] = FIELD_BOOL;
xmem.PLAYER_MEM[0x02] = FIELD_WORD;
xmem.PLAYER_MEM[0x04] = FIELD_WORD;
xmem.PLAYER_MEM[0x06] = FIELD_BOOL;
xmem.PLAYER_MEM[0x08] = FIELD_WORD;
xmem.PLAYER_MEM[0x0A] = FIELD_BOOL;
xmem.PLAYER_MEM[0x0C] = FIELD_BOOL;
xmem.PLAYER_MEM[0x0E] = FIELD_BOOL;
xmem.PLAYER_MEM[0x10] = FIELD_WORD;
xmem.PLAYER_MEM[0x12] = FIELD_BOOL;
xmem.PLAYER_MEM[0x14] = FIELD_WORD;
xmem.PLAYER_MEM[0x16] = FIELD_WORD;
xmem.PLAYER_MEM[0x18] = FIELD_BOOL;
xmem.PLAYER_MEM[0x1A] = FIELD_BOOL;
xmem.PLAYER_MEM[0x1C] = FIELD_WORD;
xmem.PLAYER_MEM[0x1E] = FIELD_WORD;
xmem.PLAYER_MEM[0x20] = FIELD_FLOAT;
xmem.PLAYER_MEM[0x24] = FIELD_WORD;
xmem.PLAYER_MEM[0x26] = FIELD_WORD;
xmem.PLAYER_MEM[0x28] = FIELD_FLOAT;
xmem.PLAYER_MEM[0x2C] = FIELD_DFLOAT;
xmem.PLAYER_MEM[0x34] = FIELD_WORD;
xmem.PLAYER_MEM[0x36] = FIELD_BOOL;
xmem.PLAYER_MEM[0x38] = FIELD_WORD;
xmem.PLAYER_MEM[0x3A] = FIELD_WORD;
xmem.PLAYER_MEM[0x3C] = FIELD_BOOL;
xmem.PLAYER_MEM[0x3E] = FIELD_BOOL;
xmem.PLAYER_MEM[0x40] = FIELD_WORD;
xmem.PLAYER_MEM[0x42] = FIELD_WORD;
xmem.PLAYER_MEM[0x44] = FIELD_BOOL;
xmem.PLAYER_MEM[0x46] = FIELD_WORD;
xmem.PLAYER_MEM[0x48] = FIELD_WORD;
xmem.PLAYER_MEM[0x4A] = FIELD_BOOL;
xmem.PLAYER_MEM[0x4C] = FIELD_WORD;
xmem.PLAYER_MEM[0x4E] = FIELD_WORD;
xmem.PLAYER_MEM[0x50] = FIELD_WORD;
xmem.PLAYER_MEM[0x52] = FIELD_WORD;
xmem.PLAYER_MEM[0x54] = FIELD_WORD;
xmem.PLAYER_MEM[0x56] = FIELD_WORD;
xmem.PLAYER_MEM[0x58] = FIELD_WORD;
xmem.PLAYER_MEM[0x5A] = FIELD_WORD;
xmem.PLAYER_MEM[0x5C] = FIELD_WORD;
xmem.PLAYER_MEM[0x5E] = FIELD_WORD;
xmem.PLAYER_MEM[0x60] = FIELD_BOOL;
xmem.PLAYER_MEM[0x62] = FIELD_WORD;
xmem.PLAYER_MEM[0x64] = FIELD_BOOL;
xmem.PLAYER_MEM[0x66] = FIELD_BOOL;
xmem.PLAYER_MEM[0x68] = FIELD_BOOL;
xmem.PLAYER_MEM[0x6A] = FIELD_WORD;
xmem.PLAYER_MEM[0x6C] = FIELD_WORD;
xmem.PLAYER_MEM[0x6E] = FIELD_WORD;
xmem.PLAYER_MEM[0x70] = FIELD_WORD;
xmem.PLAYER_MEM[0x72] = FIELD_WORD;
xmem.PLAYER_MEM[0x74] = FIELD_WORD;
xmem.PLAYER_MEM[0x76] = FIELD_WORD;
xmem.PLAYER_MEM[0x78] = FIELD_WORD;
xmem.PLAYER_MEM[0x7A] = FIELD_WORD;
xmem.PLAYER_MEM[0x7C] = FIELD_WORD;
xmem.PLAYER_MEM[0x7E] = FIELD_WORD;
xmem.PLAYER_MEM[0x80] = FIELD_DFLOAT;
xmem.PLAYER_MEM[0x88] = FIELD_DFLOAT;
xmem.PLAYER_MEM[0x90] = FIELD_DFLOAT;
xmem.PLAYER_MEM[0x98] = FIELD_DFLOAT;
xmem.PLAYER_MEM[0xA0] = FIELD_DFLOAT;
xmem.PLAYER_MEM[0xA8] = FIELD_DFLOAT;
xmem.PLAYER_MEM[0xB0] = FIELD_FLOAT;
xmem.PLAYER_MEM[0xB4] = FIELD_WORD;
xmem.PLAYER_MEM[0xB6] = FIELD_BOOL;
xmem.PLAYER_MEM[0xB8] = FIELD_WORD;
xmem.PLAYER_MEM[0xBA] = FIELD_WORD;
xmem.PLAYER_MEM[0xBC] = FIELD_WORD;
xmem.PLAYER_MEM[0xBE] = FIELD_WORD;
xmem.PLAYER_MEM[0xC0] = FIELD_DFLOAT;
xmem.PLAYER_MEM[0xC8] = FIELD_DFLOAT;
xmem.PLAYER_MEM[0xD0] = FIELD_DFLOAT;
xmem.PLAYER_MEM[0xD8] = FIELD_DFLOAT;
xmem.PLAYER_MEM[0xE0] = FIELD_DFLOAT;
xmem.PLAYER_MEM[0xE8] = FIELD_DFLOAT;
xmem.PLAYER_MEM[0xF0] = FIELD_WORD;
xmem.PLAYER_MEM[0xF2] = FIELD_BOOL;
xmem.PLAYER_MEM[0xF4] = FIELD_BOOL;
xmem.PLAYER_MEM[0xF6] = FIELD_BOOL;
xmem.PLAYER_MEM[0xF8] = FIELD_BOOL;
xmem.PLAYER_MEM[0xFA] = FIELD_BOOL;
xmem.PLAYER_MEM[0xFC] = FIELD_BOOL;
xmem.PLAYER_MEM[0xFE] = FIELD_BOOL;
xmem.PLAYER_MEM[0x100] = FIELD_BOOL;
xmem.PLAYER_MEM[0x102] = FIELD_BOOL;
xmem.PLAYER_MEM[0x104] = FIELD_BOOL;
xmem.PLAYER_MEM[0x106] = FIELD_WORD;
xmem.PLAYER_MEM[0x108] = FIELD_WORD;
xmem.PLAYER_MEM[0x10A] = FIELD_WORD;
xmem.PLAYER_MEM[0x10C] = FIELD_WORD;
xmem.PLAYER_MEM[0x10E] = FIELD_WORD;
xmem.PLAYER_MEM[0x110] = FIELD_WORD;
xmem.PLAYER_MEM[0x112] = FIELD_WORD;
xmem.PLAYER_MEM[0x114] = FIELD_WORD;
xmem.PLAYER_MEM[0x116] = FIELD_WORD;
xmem.PLAYER_MEM[0x118] = FIELD_FLOAT;
xmem.PLAYER_MEM[0x11C] = FIELD_WORD;
xmem.PLAYER_MEM[0x11E] = FIELD_WORD;
xmem.PLAYER_MEM[0x120] = FIELD_BOOL;
xmem.PLAYER_MEM[0x122] = FIELD_WORD;
xmem.PLAYER_MEM[0x124] = FIELD_DFLOAT;
xmem.PLAYER_MEM[0x12C] = FIELD_BOOL;
xmem.PLAYER_MEM[0x12E] = FIELD_BOOL;
xmem.PLAYER_MEM[0x130] = FIELD_BOOL;
xmem.PLAYER_MEM[0x132] = FIELD_BOOL;
xmem.PLAYER_MEM[0x134] = FIELD_BOOL;
xmem.PLAYER_MEM[0x136] = FIELD_BOOL;
xmem.PLAYER_MEM[0x138] = FIELD_FLOAT;
xmem.PLAYER_MEM[0x13C] = FIELD_BOOL;
xmem.PLAYER_MEM[0x13E] = FIELD_WORD;
xmem.PLAYER_MEM[0x140] = FIELD_WORD;
xmem.PLAYER_MEM[0x142] = FIELD_BOOL;
xmem.PLAYER_MEM[0x144] = FIELD_WORD;
xmem.PLAYER_MEM[0x146] = FIELD_WORD;
xmem.PLAYER_MEM[0x148] = FIELD_WORD;
xmem.PLAYER_MEM[0x14A] = FIELD_WORD;
xmem.PLAYER_MEM[0x14C] = FIELD_WORD;
xmem.PLAYER_MEM[0x14E] = FIELD_WORD;
xmem.PLAYER_MEM[0x150] = FIELD_WORD;
xmem.PLAYER_MEM[0x152] = FIELD_WORD;
xmem.PLAYER_MEM[0x154] = FIELD_WORD;
xmem.PLAYER_MEM[0x156] = FIELD_BOOL;
xmem.PLAYER_MEM[0x158] = FIELD_WORD;
xmem.PLAYER_MEM[0x15A] = FIELD_WORD;
xmem.PLAYER_MEM[0x15C] = FIELD_WORD;
xmem.PLAYER_MEM[0x15E] = FIELD_WORD;
xmem.PLAYER_MEM[0x160] = FIELD_WORD;
xmem.PLAYER_MEM[0x162] = FIELD_WORD;
xmem.PLAYER_MEM[0x164] = FIELD_WORD;
xmem.PLAYER_MEM[0x166] = FIELD_WORD;
xmem.PLAYER_MEM[0x168] = FIELD_FLOAT;
xmem.PLAYER_MEM[0x16C] = FIELD_BOOL;
xmem.PLAYER_MEM[0x16E] = FIELD_BOOL;
xmem.PLAYER_MEM[0x170] = FIELD_WORD;
xmem.PLAYER_MEM[0x172] = FIELD_BOOL;
xmem.PLAYER_MEM[0x174] = FIELD_BOOL;
xmem.PLAYER_MEM[0x176] = FIELD_WORD;
xmem.PLAYER_MEM[0x178] = FIELD_WORD;
xmem.PLAYER_MEM[0x17A] = FIELD_BOOL;
xmem.PLAYER_MEM[0x17C] = FIELD_WORD;
xmem.PLAYER_MEM[0x17E] = FIELD_WORD;
xmem.PLAYER_MEM[0x180] = FIELD_WORD;
xmem.PLAYER_MEM[0x182] = FIELD_WORD;
xmem.PLAYER_MEM[0x184] = FIELD_WORD;
end
	
xmem.GLOBAL_MEM = {}
do --Define global mem types
xmem.GLOBAL_MEM[0x00B25A20] = FIELD_DWORD;
xmem.GLOBAL_MEM[0x00B2595E] = FIELD_WORD;
xmem.GLOBAL_MEM[0x00CF74D8] = FIELD_DWORD;
xmem.GLOBAL_MEM[0x00B259E8] = FIELD_DWORD;
xmem.GLOBAL_MEM[0x00B2595A] = FIELD_WORD;
xmem.GLOBAL_MEM[0x00B251E0] = FIELD_WORD;
xmem.GLOBAL_MEM[0x00B2C5A8] = FIELD_WORD;
xmem.GLOBAL_MEM[0x00B2C5AC] = FIELD_FLOAT;
xmem.GLOBAL_MEM[0x00B2C8E4] = FIELD_WORD;
xmem.GLOBAL_MEM[0x00B250E2] = FIELD_WORD;
xmem.GLOBAL_MEM[0x00B2C880] = FIELD_WORD;
xmem.GLOBAL_MEM[0x00B25028] = FIELD_DWORD;
xmem.GLOBAL_MEM[0x00B2C620] = FIELD_WORD;
xmem.GLOBAL_MEM[0x00B2C89C] = FIELD_DWORD;
end

function xmem.onInitAPI()
	registerEvent(xmem, "onTick", "onTick", true)
end

local dumpx = 0;

function xmem.getSessionLogPath()
	if(filename == nil or Level.filename() == nil) then
		return "";
	end
	
	return getSMBXPath().."\\logs\\"..filename..".log";
end

local function checkLogFile()
	if(logFile == nil) then
			if(pcall(function() logFile = io.open(xmem.getSessionLogPath(),"w") end)) then
				logFile:write("--------------------MEMORY LOG FILE--------------------\n\n\n");
			else
				Misc.dialog("Warning: Memory log file could not be created. Calls to \"memlog\" functions will not behave correctly.")
			end
		end
end

function xmem.onTick()
	if(filename == nil) then
		framecount = 0;
		filename = "mem_log_"..os.date("%d-%m-%y-%H-%M-%S");
		local basefile = filename;
		local counter = 0;
		repeat
			if(pcall(function() logFile = io.open(xmem.getSessionLogPath(),"r") end)) then
				if(logFile ~= nil) then
					logFile:close();
					counter = counter + 1;
					filename = basefile.."_"..tostring(counter);
				end
			else
				logFile = nil;
			end
		until(logFile == nil)
		startClock = os.clock();
	end
	dumpx = 0;
	framecount = framecount+1;
end

local  function pairsByKeys (t, f)
      local a = {}
      for n in pairs(t) do table.insert(a, n) end
      table.sort(a, f)
      local i = 0      -- iterator variable
      local iter = function ()   -- iterator function
        i = i + 1
        if a[i] == nil then return nil
        else return a[i], t[a[i]]
        end
      end
      return iter
end
	
do --NPC functions
	function NPC:memdump(lowaddress, highaddress)
		lowaddress = lowaddress or 0;
		highaddress = highaddress or math.huge;
		local x,y = dumpx,0;
		
		FONT.text =  "NPC (ID "..self.id.."):"
		FONT.x = x
		FONT.y = y
		textplus.print(FONT)
		--textblox.printExt (, {x=x, y=y, font=FONT, z=5})
		y = y + 9;
		
		
		for k,v in pairsByKeys(xmem.NPC_MEM) do
			if(k >= lowaddress and k <= highaddress) then
				local hexstr = string.upper(string.format("%x",k));
				if(#hexstr == 1) then
					hexstr = "0"..hexstr;
				end
				
				
				FONT.text =  "0x"..hexstr..": "..tostring(self:mem(k,v))
				if #FONT.text > 16 then
					FONT.text = string.sub(FONT.text,1,16)
				end
				FONT.x = x
				FONT.y = y
				textplus.print(FONT)
				--textblox.printExt ("0x"..hexstr..": "..tostring(self:mem(k,v)),{x=x, y=y, font=FONT, z=5})
				y = y + 9;
				if(y > 600-9) then
					x = x+128;
					y = 0;
				end
				
			end
		end
		
		dumpx = x + 128;
	end

	function NPC:memlog(lowaddress, highaddress)
		checkLogFile();
		
		local t = (os.clock() - startClock);
		
		logFile:write("NPC (ID "..tostring(self.id)..") Logged\nTime "..string.format("%.4f", t).."s\nFrame "..tostring(framecount).."\n------------------------------\n");
		
		lowaddress = lowaddress or 0;
		highaddress = highaddress or math.huge;
		
		for k,v in pairsByKeys(xmem.NPC_MEM) do
			if(k >= lowaddress and k <= highaddress) then
				local hexstr = string.upper(string.format("%x",k));
				if(#hexstr == 1) then
					hexstr = "0"..hexstr;
				end
					logFile:write("0x"..hexstr..": "..tostring(self:mem(k,v)).."\n");
			end
		end
		
		logFile:write("\n");
		logFile:flush();
	end
end

do -- Block functions
	function Block:memdump(lowaddress, highaddress)
		lowaddress = lowaddress or 0;
		highaddress = highaddress or math.huge;
		local x,y = dumpx,0;
		
		FONT.text =  "Block (ID "..self.id.."):"
		FONT.x = x
		FONT.y = y
		textplus.print(FONT)
		--textblox.printExt ("Block (ID "..self.id.."):", {x=x, y=y, font=FONT, z=5})
		y = y + 9;
		
		for k,v in pairsByKeys(xmem.BLOCK_MEM) do
			if(k >= lowaddress and k <= highaddress) then
				local hexstr = string.upper(string.format("%x",k));
				if(#hexstr == 1) then
					hexstr = "0"..hexstr;
				end
				
				FONT.text =  "0x"..hexstr..": "..tostring(self:mem(k,v))
				if #FONT.text > 16 then
					FONT.text = string.sub(FONT.text,1,16)
				end
				FONT.x = x
				FONT.y = y
				textplus.print(FONT)
				--textblox.printExt ("0x"..hexstr..": "..tostring(self:mem(k,v)),{x=x, y=y, font=FONT, z=5})
				y = y + 9;
				if(y > 600-9) then
					x = x+128;
					y = 0;
				end
				
			end
		end
		
		dumpx = x + 128;
		
	end
	
	
	function Block:memlog(lowaddress, highaddress)
		checkLogFile();
		
		local t = (os.clock() - startClock);
		
		logFile:write("Block (ID "..tostring(self.id)..") Logged\nTime "..string.format("%.4f", t).."s\nFrame "..tostring(framecount).."\n------------------------------\n");
		
		lowaddress = lowaddress or 0;
		highaddress = highaddress or math.huge;
		
		for k,v in pairsByKeys(xmem.BLOCK_MEM) do
			if(k >= lowaddress and k <= highaddress) then
				local hexstr = string.upper(string.format("%x",k));
				if(#hexstr == 1) then
					hexstr = "0"..hexstr;
				end
					logFile:write("0x"..hexstr..": "..tostring(self:mem(k,v)).."\n");
			end
		end
		
		logFile:write("\n");
		logFile:flush();
	end
end

do --Player functions	
	function Player:memdump(lowaddress, highaddress)
		lowaddress = lowaddress or 0;
		highaddress = highaddress or math.huge;
		local x,y = dumpx,0;
		
		FONT.text =  "PLAYER ("..self.idx.."):"
		FONT.x = x
		FONT.y = y
		textplus.print(FONT)
		--textblox.print("PLAYER:",x,y,FONT)
		y = y + 9;
		
					
		for k,v in pairsByKeys(xmem.PLAYER_MEM) do
			if(k >= lowaddress and k <= highaddress) then
				local hexstr = string.upper(string.format("%x",k));
				if(#hexstr == 1) then
					hexstr = "0"..hexstr;
				end
				
				FONT.text =  "0x"..hexstr..": "..tostring(self:mem(k,v))
				if #FONT.text > 16 then
					FONT.text = string.sub(FONT.text,1,16)
				end
				FONT.x = x
				FONT.y = y
				textplus.print(FONT)
				--textblox.print("0x"..hexstr..": "..tostring(self:mem(k,v)),x,y,FONT)
				y = y + 9;
				if(y > 600-9) then
					x = x+128;
					y = 0;
				end
				
			end
		end
		
		dumpx = x + 128;
		
	end
	
	function Player:memlog(lowaddress, highaddress)
		checkLogFile();
		
		local t = (os.clock() - startClock);
		
		logFile:write("Player Logged\nTime "..string.format("%.4f", t).."s\nFrame "..tostring(framecount).."\n------------------------------\n");
		
		lowaddress = lowaddress or 0;
		highaddress = highaddress or math.huge;
		
		for k,v in pairsByKeys(xmem.PLAYER_MEM) do
			if(k >= lowaddress and k <= highaddress) then
				local hexstr = string.upper(string.format("%x",k));
				if(#hexstr == 1) then
					hexstr = "0"..hexstr;
				end
					logFile:write("0x"..hexstr..": "..tostring(self:mem(k,v)).."\n");
			end
		end
		
		logFile:write("\n");
		logFile:flush();
	end
end

do --Global functions
	function xmem.memdump(lowaddress, highaddress)
		lowaddress = lowaddress or 0;
		highaddress = highaddress or math.huge;
		local x,y = dumpx,0;
		
		FONT.text =  "GLOBAL:"
		FONT.x = x
		FONT.y = y
		textplus.print(FONT)
		--textblox.print("GLOBAL:",x,y,FONT)
		y = y + 9;
		
		for k,v in pairsByKeys(xmem.GLOBAL_MEM) do
			if(k >= lowaddress and k <= highaddress) then
				local hexstr = string.upper(string.format("%x",k));
				if(#hexstr == 6) then
					hexstr = "00"..hexstr;
				elseif(#hexstr == 7) then
					hexstr = "0"..hexstr;
				end
				
				FONT.text =  "0x"..hexstr..": "..tostring(mem(k,v))
				if #FONT.text > 16 then
					FONT.text = string.sub(FONT.text,1,16)
				end
				FONT.x = x
				FONT.y = y
				textplus.print(FONT)
				--textblox.print("0x"..hexstr..": "..tostring(mem(k,v)),x,y,FONT)
				y = y + 9;
				if(y > 600-9) then
					x = x+164;
					y = 0;
				end
				
			end
		end
		
		dumpx = x + 164;
		
	end
	
	function xmem.memlog(lowaddress, highaddress)
		checkLogFile();
		
		local t = (os.clock() - startClock);
		
		logFile:write("Global Logged\nTime "..string.format("%.4f", t).."s\nFrame "..tostring(framecount).."\n------------------------------\n");
		
		lowaddress = lowaddress or 0;
		highaddress = highaddress or math.huge;
		
		for k,v in pairsByKeys(xmem.GLOBAL_MEM) do
			if(k >= lowaddress and k <= highaddress) then
				local hexstr = string.upper(string.format("%x",k));
				if(#hexstr == 6) then
					hexstr = "00"..hexstr;
				elseif(#hexstr == 7) then
					hexstr = "0"..hexstr;
				end
					logFile:write("0x"..hexstr..": "..tostring(mem(k,v)).."\n");
			end
		end
		
		logFile:write("\n");
		logFile:flush();
	end
end

local function getAddress(list,address)
	local address_up = address;
	while(list[address] == nil) do
		address_up = address_up + 1;
		address = address - 1;
		if(list[address_up] ~= nil) then
			address = address_up;
			break;
		end
	end
	return address;
end

function xmem.getNPCAddress(address)
	return getAddress(xmem.NPC_MEM,address);
end

function xmem.getPlayerAddress(address)
	return getAddress(xmem.PLAYER_MEM,address);
end

function xmem.getGlobalAddress(address)
	return getAddress(xmem.GLOBAL_MEM,address);
end

return xmem;
