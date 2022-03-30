local bit_band = bit.band
local bit_bor = bit.bor

local savestate = {
    STATE_NPC         = 0x1,
    STATE_PLAYER      = 0x2,
    STATE_ANIM        = 0x4,
	STATE_LAYEREVENT  = 0x18, -- Plus blocks
    STATE_LAYEREVENT2 = 0x08,
	STATE_BLOCK       = 0x10,
    STATE_ALL         = 0x1F,
}

local GM_LAYER_ARRAY_PTR = 0x00B2C6B0
local LAYER_ARRAY_PTR = mem(GM_LAYER_ARRAY_PTR, FIELD_DWORD)

local SAVABLE_DATA = {
    npc={
        flag=savestate.STATE_NPC,
        ptr=mem(0x00B259E8, FIELD_DWORD) + 0xAD58,
        count_ptr=0x00B2595A,
        entry_size=0x158,
		max_count=5000,
		momentum_offset=0x78,
        field_type={
            [0x00]=FIELD_STRING,
            [0x2C]=FIELD_STRING,
            [0x30]=FIELD_STRING,
            [0x34]=FIELD_STRING,
            [0x38]=FIELD_STRING,
            [0x3C]=FIELD_STRING,
            [0x4C]=FIELD_STRING,
        },
    },
    player={
        flag=savestate.STATE_PLAYER,
        ptr=mem(0x00B25A20, FIELD_DWORD)+0x184,
        count=2,
        --count_ptr=0x00B2595E,
        entry_size=0x184
    },
    anim={
        flag=savestate.STATE_ANIM,
        ptr=mem(0x00B259CC, FIELD_DWORD),
        count_ptr=0x00B2595C,
        entry_size=0x44
    },

    layers={
        flag=savestate.STATE_LAYEREVENT2,
        ptr=mem(0x00B2C6B0, FIELD_DWORD),
        count=100,
        entry_size=0x14,
        field_type={
            [0x04]=FIELD_STRING,
        },
    },    
    blocks={
        flag=savestate.STATE_BLOCK,
        ptr=mem(0x00B25A04, FIELD_DWORD)+0x68,
        count_ptr=0x00B25956,
        entry_size=0x68,
		max_count=16383,
		momentum_offset=0x20,
        field_type={
            [0x0C]=FIELD_STRING,
            [0x10]=FIELD_STRING,
            [0x14]=FIELD_STRING,
            [0x18]=FIELD_STRING,
        },
    },
    bgos={
        flag=savestate.STATE_LAYEREVENT2,
        ptr=mem(0x00B259B0, FIELD_DWORD),
        count_ptr=0x00B25958,
        entry_size=0x38,
        field_type={
            [0x00]=FIELD_STRING,
        },
    },
    water={
        flag=savestate.STATE_LAYEREVENT2,
        ptr=mem(0x00B256F4, FIELD_DWORD)+0x40,
        count_ptr=0x00B25700,
        entry_size=0x40,
        field_type={
            [0x00]=FIELD_STRING,
        },
    },
    warps={
        flag=savestate.STATE_LAYEREVENT2,
        ptr=mem(0x00B258F4, FIELD_DWORD),
        count_ptr=0x00B258E2,
        entry_size=0x90,
        field_type={
            [0x08]=FIELD_STRING,
            [0x78]=FIELD_STRING,
        },
    },
    events={
        flag=savestate.STATE_LAYEREVENT2,
        ptr=mem(0x00B2C6CC, FIELD_DWORD),
        count_ptr=0x00B2D710,
        entry_size=0x588,
        field_type={
            [0x04]=FIELD_STRING,
            [0x08]=FIELD_STRING,
            [0x0C]=FIELD_STRING,
            [0x10]=FIELD_STRING,
            [0x14]=FIELD_STRING,
            [0x18]=FIELD_STRING,
            [0x1C]=FIELD_STRING,
            [0x20]=FIELD_STRING,
            [0x24]=FIELD_STRING,
            [0x28]=FIELD_STRING,
            [0x2C]=FIELD_STRING,
            [0x30]=FIELD_STRING,
            [0x34]=FIELD_STRING,
            [0x38]=FIELD_STRING,
            [0x3C]=FIELD_STRING,
            [0x40]=FIELD_STRING,
            [0x44]=FIELD_STRING,
            [0x48]=FIELD_STRING,
            [0x4C]=FIELD_STRING,
            [0x50]=FIELD_STRING,
            [0x54]=FIELD_STRING,
            [0x58]=FIELD_STRING,
            [0x5C]=FIELD_STRING,
            [0x60]=FIELD_STRING,
            [0x64]=FIELD_STRING,
            [0x68]=FIELD_STRING,
            [0x6C]=FIELD_STRING,
            [0x70]=FIELD_STRING,
            [0x74]=FIELD_STRING,
            [0x78]=FIELD_STRING,
            [0x7C]=FIELD_STRING,
            [0x80]=FIELD_STRING,
            [0x84]=FIELD_STRING,
            [0x88]=FIELD_STRING,
            [0x8C]=FIELD_STRING,
            [0x90]=FIELD_STRING,
            [0x94]=FIELD_STRING,
            [0x98]=FIELD_STRING,
            [0x9C]=FIELD_STRING,
            [0xA0]=FIELD_STRING,
            [0xA4]=FIELD_STRING,
            [0xA8]=FIELD_STRING,
            [0xAC]=FIELD_STRING,
            [0xB0]=FIELD_STRING,
            [0xB4]=FIELD_STRING,
            [0xB8]=FIELD_STRING,
            [0xBC]=FIELD_STRING,
            [0xC0]=FIELD_STRING,
            [0xC4]=FIELD_STRING,
            [0xC8]=FIELD_STRING,
            [0xCC]=FIELD_STRING,
            [0xD0]=FIELD_STRING,
            [0xD4]=FIELD_STRING,
            [0xD8]=FIELD_STRING,
            [0xDC]=FIELD_STRING,
            [0xE0]=FIELD_STRING,
            [0xE4]=FIELD_STRING,
            [0xE8]=FIELD_STRING,
            [0xEC]=FIELD_STRING,
            [0xF0]=FIELD_STRING,
            [0xF4]=FIELD_STRING,
            [0xF8]=FIELD_STRING,
            [0xFC]=FIELD_STRING,
            [0x100]=FIELD_STRING,
            [0x104]=FIELD_STRING,
            [0x550]=FIELD_STRING,
            [0x570]=FIELD_STRING,
        },
    },
    eventtimes={
        flag=savestate.STATE_LAYEREVENT2,
        ptr=0x00B2D104,--mem(0x00B2D104, FIELD_DWORD),
        count=1,
        entry_size=400,
    }
}

local function saveArr(arrPtr, arrLen, entryLen, fieldTypes, cond)
    local arr = {}
	local idx2 = 0
    for idx = 0,arrLen-1 do
        local ptr = arrPtr+entryLen*idx
		if (cond == nil) or (cond(ptr)) then
			local obj = {}
			for field_off = 0,entryLen-4,4 do
				if (fieldTypes ~= nil) and (fieldTypes[field_off] == FIELD_STRING) then
					obj[field_off] = tostring(mem(ptr + field_off, FIELD_STRING))
				else
					obj[field_off] = mem(ptr + field_off, FIELD_DWORD)
				end
			end
			arr[idx2] = obj
			idx2 = idx2 + 1
		end
    end
    return arr, idx2
end

local function loadArr(arr, arrPtr, arrLen, entryLen, fieldTypes, maxCount)
    for idx = 0,arrLen-1 do
        local ptr = arrPtr+entryLen*idx
        local obj = arr[idx]
        if (obj ~= nil) then
            for field_off = 0,entryLen-4,4 do
                if (fieldTypes ~= nil) and (fieldTypes[field_off] == FIELD_STRING) then
                    mem(ptr + field_off, FIELD_STRING, obj[field_off])
                else
                    mem(ptr + field_off, FIELD_DWORD, obj[field_off])
                end
            end
        end
    end
	if (maxCount ~= nil) then
    for idx = arrLen,maxCount-1 do
        local ptr = arrPtr+entryLen*idx
		for field_off = 0,entryLen-4,4 do
			if (fieldTypes ~= nil) and (fieldTypes[field_off] == FIELD_STRING) then
				mem(ptr + field_off, FIELD_STRING, "")
			else
				mem(ptr + field_off, FIELD_DWORD, 0)
			end
		end
    end
	end
end

function savestate.save(stateMask)
    if (stateMask == nil) then stateMask = savestate.STATE_ALL end
    local state = {}
    
    -- Save data
    for key,datatype in pairs(SAVABLE_DATA) do
        if (bit_band(stateMask, datatype.flag) ~= 0) then
            local data = {}
            local arr_count = 0
            if (datatype.count_ptr ~= nil) then
                data.count = mem(datatype.count_ptr, FIELD_WORD)
                arr_count = mem(datatype.count_ptr, FIELD_WORD)
            end
            if (datatype.count ~= nil) then
                arr_count = datatype.count
            end
            data.arr, data.count = saveArr(datatype.ptr, arr_count, datatype.entry_size, datatype.field_type)
            state[key] = data
        end
    end
    
    return state
end

function savestate.load(state, stateMask)
    if (stateMask == nil) then stateMask = savestate.STATE_ALL end
    
    -- Load data
    for key,datatype in pairs(SAVABLE_DATA) do
        local data = state[key]
        if (bit_band(stateMask, datatype.flag) ~= 0) and (data ~= nil) then
            local arr_count = 0
            if (datatype.count_ptr ~= nil) then
                mem(datatype.count_ptr, FIELD_WORD, data.count)
                arr_count = data.count
            end
            if (datatype.count ~= nil) then
                arr_count = datatype.count
            end
            loadArr(data.arr, datatype.ptr, arr_count, datatype.entry_size, datatype.field_type, datatype.max_count)
        end
    end
    
    return state
end

local function getOrigSectionBounds(section)
	local ptr    = mem(0x00B2587C, FIELD_DWORD) + 0x30 * section
	local left   = mem(ptr + 0x00, FIELD_DFLOAT)
	local top    = mem(ptr + 0x08, FIELD_DFLOAT)
	local bottom = mem(ptr + 0x10, FIELD_DFLOAT)
	local right  = mem(ptr + 0x18, FIELD_DFLOAT)
	return left, top, bottom, right
end

local function isObjWithinSection(bl, bt, bb, br, ptr)
	local left   = mem(ptr + 0x00, FIELD_DFLOAT)
	if (left   > br) then return false end
	local top    = mem(ptr + 0x08, FIELD_DFLOAT)
	if (top    > bb) then return false end
	local bottom = top +  mem(ptr + 0x10, FIELD_DFLOAT)
	if (bottom < bt) then return false end
	local right  = left + mem(ptr + 0x18, FIELD_DFLOAT)
	if (right  < bl) then return false end
	return true
end

function savestate.saveSectionNPCs(section)
    local stateMask = savestate.STATE_NPC
    local state = {}
	local bl, bt, bb, br = getOrigSectionBounds(section)
    bl = bl - 100
	bt = bt - 100
	bb = bb + 100
	br = br + 100
	
    -- Save data
    for key,datatype in pairs(SAVABLE_DATA) do
        if (bit_band(stateMask, datatype.flag) ~= 0) then
            local data = {}
            local arr_count = 0
            if (datatype.count_ptr ~= nil) then
                data.count = mem(datatype.count_ptr, FIELD_WORD)
                arr_count = mem(datatype.count_ptr, FIELD_WORD)
            end
            if (datatype.count ~= nil) then
                arr_count = datatype.count
            end
            data.arr, data.count = saveArr(datatype.ptr, arr_count, datatype.entry_size, datatype.field_type, 
			function (ptr)
				--return mem(ptr + 0x146, FIELD_WORD) == section
				return isObjWithinSection(bl, bt, bb, br, ptr + datatype.momentum_offset)
			end
			)
            state[key] = data
        end
    end
    
    return state
end

return savestate