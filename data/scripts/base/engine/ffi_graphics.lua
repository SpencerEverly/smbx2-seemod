local Graphics = {}
local Text = {}
local Globals = {}

-------------------
-- Cached locals --
-------------------
local table_insert = table.insert
local bit_rshift = bit.rshift
local ffi_new = ffi.new
local ffi_cast = ffi.cast
local ffi_typeof = ffi.typeof
local ffi_sizeof = ffi.sizeof
local math_floor = math.floor
local math_ceil = math.ceil
local math_sqrt = math.sqrt
local math_sin = math.sin
local math_cos = math.cos
local makeSafeAbsolutePath = io.makeSafeAbsolutePath

----------------------
-- FFI Declerations --
----------------------

ffi.cdef[[
typedef struct _LunaImageRef LunaImageRef;
typedef struct _CaptureBufferRef CaptureBufferRef;
typedef struct _FFI_ShaderObj FFI_ShaderObjRef;

typedef struct _FFI_GL_Draw_Var
{
    unsigned int mId;
    unsigned int mType;
    unsigned int mCount;
    void* mData;
} FFI_GL_Draw_Var;

typedef struct _FFI_GL_Draw_Cmd
{
    CaptureBufferRef* mTarget;
    LunaImageRef* mImg;
    CaptureBufferRef* mCap;
    float mColor[4];
    uint32_t mType;
    uint32_t mCount;
    bool mSceneCoords;
    bool mDepthTest;
	bool mLinearFiltered;
    const float* mVert;
    const float* mTex;
    const float* mVertColor;
    FFI_ShaderObjRef* mShader;
    unsigned int mAttrCount;
    FFI_GL_Draw_Var* mAttrs;
    unsigned int mUnifCount;
    FFI_GL_Draw_Var* mUnifs;
    double mPriority;
} FFI_GL_Draw_Cmd;

typedef struct _FFI_ShaderVariableInfo
{
    int varInfoType;
    int id;
    int arrayCount;
    unsigned int type;
    const char* name;
    const char* rawName;
    int arrayDepth;
} FFI_ShaderVariableInfo;

typedef struct _FrameStatStruct
{
	unsigned long long skipCount;
	unsigned long long totalCount;
} FrameStatStruct;

typedef struct _GLConstants
{
	const char* pcVENDOR;
	const char* pcRENDERER;
	const char* pcVERSION;
	const char* pcSHADING_LANGUAGE_VERSION;
	int iMAJOR_VERSION;
	int iMINOR_VERSION;
	int iMAX_COMPUTE_SHADER_STORAGE_BLOCKS;
	int iMAX_COMBINED_SHADER_STORAGE_BLOCKS;
	int iMAX_COMPUTE_UNIFORM_BLOCKS;
	int iMAX_COMPUTE_TEXTURE_IMAGE_UNITS;
	int iMAX_COMPUTE_UNIFORM_COMPONENTS;
	int iMAX_COMPUTE_ATOMIC_COUNTERS;
	int iMAX_COMPUTE_ATOMIC_COUNTER_BUFFERS;
	int iMAX_COMBINED_COMPUTE_UNIFORM_COMPONENTS;
	int iMAX_COMPUTE_WORK_GROUP_INVOCATIONS;
	int iMAX_COMPUTE_WORK_GROUP_COUNT;
	int iMAX_COMPUTE_WORK_GROUP_SIZE;
	int iMAX_DEBUG_GROUP_STACK_DEPTH;
	int iMAX_3D_TEXTURE_SIZE;
	int iMAX_ARRAY_TEXTURE_LAYERS;
	int iMAX_CLIP_DISTANCES;
	int iMAX_COLOR_TEXTURE_SAMPLES;
	int iMAX_COMBINED_ATOMIC_COUNTERS;
	int iMAX_COMBINED_FRAGMENT_UNIFORM_COMPONENTS;
	int iMAX_COMBINED_GEOMETRY_UNIFORM_COMPONENTS;
	int iMAX_COMBINED_TEXTURE_IMAGE_UNITS;
	int iMAX_COMBINED_UNIFORM_BLOCKS;
	int iMAX_COMBINED_VERTEX_UNIFORM_COMPONENTS;
	int iMAX_CUBE_MAP_TEXTURE_SIZE;
	int iMAX_DEPTH_TEXTURE_SAMPLES;
	int iMAX_DRAW_BUFFERS;
	int iMAX_DUAL_SOURCE_DRAW_BUFFERS;
	int iMAX_ELEMENTS_INDICES;
	int iMAX_ELEMENTS_VERTICES;
	int iMAX_FRAGMENT_ATOMIC_COUNTERS;
	int iMAX_FRAGMENT_SHADER_STORAGE_BLOCKS;
	int iMAX_FRAGMENT_INPUT_COMPONENTS;
	int iMAX_FRAGMENT_UNIFORM_COMPONENTS;
	int iMAX_FRAGMENT_UNIFORM_VECTORS;
	int iMAX_FRAGMENT_UNIFORM_BLOCKS;
	int iMAX_FRAMEBUFFER_WIDTH;
	int iMAX_FRAMEBUFFER_HEIGHT;
	int iMAX_FRAMEBUFFER_LAYERS;
	int iMAX_FRAMEBUFFER_SAMPLES;
	int iMAX_GEOMETRY_ATOMIC_COUNTERS;
	int iMAX_GEOMETRY_SHADER_STORAGE_BLOCKS;
	int iMAX_GEOMETRY_INPUT_COMPONENTS;
	int iMAX_GEOMETRY_OUTPUT_COMPONENTS;
	int iMAX_GEOMETRY_TEXTURE_IMAGE_UNITS;
	int iMAX_GEOMETRY_UNIFORM_BLOCKS;
	int iMAX_GEOMETRY_UNIFORM_COMPONENTS;
	int iMAX_INTEGER_SAMPLES;
	int iMAX_LABEL_LENGTH;
	int iMAX_PROGRAM_TEXEL_OFFSET;
	int iMAX_RECTANGLE_TEXTURE_SIZE;
	int iMAX_RENDERBUFFER_SIZE;
	int iMAX_SAMPLE_MASK_WORDS;
	int iMAX_SERVER_WAIT_TIMEOUT;
	int iMAX_SHADER_STORAGE_BUFFER_BINDINGS;
	int iMAX_TESS_CONTROL_ATOMIC_COUNTERS;
	int iMAX_TESS_EVALUATION_ATOMIC_COUNTERS;
	int iMAX_TESS_CONTROL_SHADER_STORAGE_BLOCKS;
	int iMAX_TESS_EVALUATION_SHADER_STORAGE_BLOCKS;
	int iMAX_TEXTURE_BUFFER_SIZE;
	int iMAX_TEXTURE_IMAGE_UNITS;
	int iMAX_TEXTURE_LOD_BIAS;
	int iMAX_TEXTURE_SIZE;
	int iMAX_UNIFORM_BUFFER_BINDINGS;
	int iMAX_UNIFORM_BLOCK_SIZE;
	int iMAX_UNIFORM_LOCATIONS;
	int iMAX_VARYING_COMPONENTS;
	int iMAX_VARYING_VECTORS;
	int iMAX_VARYING_FLOATS;
	int iMAX_VERTEX_ATOMIC_COUNTERS;
	int iMAX_VERTEX_ATTRIBS;
	int iMAX_VERTEX_SHADER_STORAGE_BLOCKS;
	int iMAX_VERTEX_TEXTURE_IMAGE_UNITS;
	int iMAX_VERTEX_UNIFORM_COMPONENTS;
	int iMAX_VERTEX_UNIFORM_VECTORS;
	int iMAX_VERTEX_OUTPUT_COMPONENTS;
	int iMAX_VERTEX_UNIFORM_BLOCKS;
	int iMAX_VIEWPORT_DIMS;
	int iMAX_VIEWPORTS;
	int iMAX_VERTEX_ATTRIB_RELATIVE_OFFSET;
	int iMAX_VERTEX_ATTRIB_BINDINGS;
	int iMAX_ELEMENT_INDEX;
} GLConstants;

// LuaImageResource class
LunaImageRef* __fastcall FFI_ImageLoad(const char* filename, uint32_t* sizeOut);
void __fastcall FFI_ImageFree(LunaImageRef* img);
uint32_t __fastcall FFI_ImageGetDataPtr(LunaImageRef* img);

// GLDraw things
void __fastcall FFI_GLDraw(const FFI_GL_Draw_Cmd* cmd);

// Shader FFI Calls
FFI_ShaderObjRef* __fastcall FFI_ShaderFromStrings(const char* vertexSource, const char* fragmentSource);
void __fastcall FFI_ShaderFree(FFI_ShaderObjRef* obj);
bool __fastcall FFI_ShaderCompile(FFI_ShaderObjRef* obj);
const char* __fastcall FFI_ShaderError(FFI_ShaderObjRef* obj);
FFI_ShaderVariableInfo* __fastcall FFI_GetAttributeInfo(FFI_ShaderObjRef* obj, uint32_t idx);
FFI_ShaderVariableInfo* __fastcall FFI_GetUniformInfo(FFI_ShaderObjRef* obj, uint32_t idx);
FFI_ShaderObjRef* __fastcall FFI_ShaderFromStrings(const char* vertexSource, const char* fragmentSource);

// Deprecated sprite calls
bool __fastcall FFI_SpriteImageLoad(const char* filename, int resNumber, int transColor);
void __cdecl FFI_SpritePlace(int type, int resNumber, LunaImageRef* img, int xPos, int yPos, const char* extra, int time);
void __fastcall FFI_SpriteUnplace(LunaImageRef* img);
void __cdecl FFI_SpriteUnplaceWithPos(LunaImageRef* img, int x, int y);

// Regular Drawing
void __cdecl FFI_ImageDraw(LunaImageRef* img, double x, double y, double sx, double sy, double sw, double sh, double priority, float opacity, bool sceneCoords);

// Text Drawing
void __cdecl FFI_TextDraw(const char* text, int type, int x, int y, double priority, bool sceneCoords);

// Sprites API
void __fastcall FFI_SetSpriteOverride(const char* name, LunaImageRef* img);
LunaImageRef* __fastcall FFI_GetSpriteOverride(const char* name, uint32_t* sizeOut);
void __fastcall FFI_RegisterExtraSprite(const char* folderName, const char* name);

// Capture Buffer
CaptureBufferRef* __fastcall FFI_CaptureBuffer(uint32_t w, uint32_t h, bool nonskippable);
void __fastcall FFI_CaptureBufferFree(CaptureBufferRef* img);
void __cdecl FFI_CaptureBufferCaptureAt(CaptureBufferRef* img, double priority);
void __cdecl FFI_CaptureBufferClear(CaptureBufferRef* img, double priority);

// HUD Control
void __fastcall FFI_GraphicsActivateHud(bool activate);
bool __fastcall FFI_GraphicsIsHudActivated();
void __fastcall FFI_GraphicsActivateOverworldHud(int activateFlag);
int __fastcall FFI_GraphicsGetOverworldHudState();

// Other
void* LunaLuaAlloc(size_t size);
bool __fastcall FFI_GraphicsIsSoftwareGL();
void __fastcall FFI_GraphicsGetFrameStats(FrameStatStruct* frameStats);
const GLConstants* __fastcall FFI_GraphicsGetConstants();
void FFI_GraphicsSetMainFramebufferSize(int width, int height);
]]
local LunaDLL = ffi.load("LunaDll.dll")

-----------------------
-- Utility Functions --
-----------------------

local function nil_or(a, b)
	if (a ~= nil) then
		return a
	else
		return b
	end
end


---------------------------------------
-- Graphics.loadImage Implementation --
---------------------------------------

local LuaImageResourceMT = {
__index = { __type="LuaImageResource" },
__type="LuaImageResource",
}

local tmpSize = ffi_new("uint32_t[2]")
function Graphics.loadImage(path, DEPRECATEDresNumber, DEPRECATEDtransColor)
	if(path == nil) then
		error("Invalid path 'nil' passed to loadImage.",2);
	end
	
	-- Make sure the path is good
	-- TODO: Fix this, when path is not absolute, this should use the custom resource folder, not top level folder like is the norm for makeSafeAbsolutePath
	-- path = makeSafeAbsolutePath(path)
	
	-- Handle deprecates overload for sprite system
	if (DEPRECATEDresNumber ~= nil) then
		return LunaDLL.FFI_SpriteImageLoad(path, DEPRECATEDresNumber, DEPRECATEDtransColor)
	end
	
	-- Run image loading
	local imgRef = ffi.gc(LunaDLL.FFI_ImageLoad(path, tmpSize), LunaDLL.FFI_ImageFree)
	
	if (imgRef == nil) then
		-- Apparently the old version didn't actually error?
		-- error("Could not load image '" .. path .. "'")
		return nil
	end
	
	return setmetatable({_ref=imgRef, width=tmpSize[0], height=tmpSize[1]}, LuaImageResourceMT)
end

-- Helper function for loadImage
function Graphics.loadImageResolved(file)
	local path = Misc.resolveGraphicsFile(file)
	if (path == nil) then
		error("Cannot find image: " .. file)
	end
	return Graphics.loadImage(path)
end

---------------------------------------------
-- Graphics.isOpenGLEnabled Implementation --
---------------------------------------------

function Graphics.isOpenGLEnabled()
	return true
end


------------------------------------
-- Graphics.glDraw Implementation --
------------------------------------

do
	local FFI_voidptr = ffi_typeof("void*")
	local FFI_nullptr = ffi_cast(FFI_voidptr, 0)
	local FFI_floatptr = ffi_typeof("float*")
	local gldraw_cmd_tmp = ffi_new("FFI_GL_Draw_Cmd")--FFI_GL_Draw_Cmd()
	local attrs_tmp = ffi_new("FFI_GL_Draw_Var[256]")
	local unifs_tmp = ffi_new("FFI_GL_Draw_Var[256]")

	Graphics.GL_POINTS         = 0
	Graphics.GL_LINES          = 1
	Graphics.GL_LINE_LOOP      = 2
	Graphics.GL_LINE_STRIP     = 3
	Graphics.GL_TRIANGLES      = 4
	Graphics.GL_TRIANGLE_STRIP = 5
	Graphics.GL_TRIANGLE_FAN   = 6

	local function safeMallocArray(typeName, count)
		local byteSize = ffi_sizeof(typeName)
		if(byteSize == nil) then
			error("Invalid type for allocating native array!", 2)
		end
		local ptrData = LunaDLL.LunaLuaAlloc(count * byteSize)
		return ffi_cast(typeName, ptrData)
	end

	local function convertGlArray(arr, arr_len, glArrayType)
		if (arr == nil) then return nil end
		local mallocType = nil_or(glArrayType, FFI_floatptr)
		local arr_raw = safeMallocArray(mallocType, arr_len)
		if (arr[0] == nil) then
			for i = 0,arr_len-1 do
				arr_raw[i] = arr[i+1]
			end
		else
			for i = 0,arr_len-1 do
				arr_raw[i] = arr[i]
			end
		end
		return arr_raw
	end

	local function getGlElementCount(arr, divisor)
		local len = #arr
		if (arr[0] ~= nil) then len = len + 1 end
		if (divisor == 1) then return len end
		if (divisor == 2) then return bit_rshift(len, 1) end
		if (divisor == 4) then return bit_rshift(len, 2) end
		if (divisor == 8) then return bit_rshift(len, 3) end
		return math_floor((#arr + len_offset) / divisor)
	end

	local glTypeTable = {
		[GL_FLOAT]              = {glType = "number",   rawType = ffi_typeof("float*"),				glComponentSize = 1,	glMaxComponentSize = 4},
		[GL_FLOAT_VEC2]         = {glType = "table",    rawType = ffi_typeof("float*"),				glComponentSize = 2,	glMaxComponentSize = 4,			glTableSize = 2},   -- 1x2
		[GL_FLOAT_VEC3]         = {glType = "table",    rawType = ffi_typeof("float*"),				glComponentSize = 3,	glMaxComponentSize = 4,			glTableSize = 3},   -- 1x3
		[GL_FLOAT_VEC4]         = {glType = "table",    rawType = ffi_typeof("float*"),				glComponentSize = 4,	glMaxComponentSize = 4,			glTableSize = 4},   -- 1x4
		[GL_FLOAT_MAT2]         = {glType = "table",    rawType = ffi_typeof("float*"),				glComponentSize = 8,	glMaxComponentSize = 8,			glTableSize = 4},   -- 2x2
		[GL_FLOAT_MAT3]         = {glType = "table",    rawType = ffi_typeof("float*"),				glComponentSize = 12,	glMaxComponentSize = 12,			glTableSize = 9},   -- 3x3
		[GL_FLOAT_MAT4]         = {glType = "table",    rawType = ffi_typeof("float*"),				glComponentSize = 16,	glMaxComponentSize = 16,			glTableSize = 16},  -- 4x4
		[GL_FLOAT_MAT2x3]       = {glType = "table",    rawType = ffi_typeof("float*"),				glComponentSize = 8,	glMaxComponentSize = 12,			glTableSize = 6},   -- 2x3
		[GL_FLOAT_MAT2x4]       = {glType = "table",    rawType = ffi_typeof("float*"),				glComponentSize = 8,	glMaxComponentSize = 16,			glTableSize = 8},   -- 2x4
		[GL_FLOAT_MAT3x2]       = {glType = "table",    rawType = ffi_typeof("float*"),				glComponentSize = 8,	glMaxComponentSize = 8,			glTableSize = 6},   -- 3x2
		[GL_FLOAT_MAT3x4]       = {glType = "table",    rawType = ffi_typeof("float*"),				glComponentSize = 12,	glMaxComponentSize = 16,			glTableSize = 12},  -- 3x4
		[GL_FLOAT_MAT4x2]       = {glType = "table",    rawType = ffi_typeof("float*"),				glComponentSize = 8,	glMaxComponentSize = 8,			glTableSize = 8},   -- 4x2
		[GL_FLOAT_MAT4x3]       = {glType = "table",    rawType = ffi_typeof("float*"),				glComponentSize = 12,	glMaxComponentSize = 12,			glTableSize = 12},  -- 4x3
		[GL_INT]                = {glType = "number",   rawType = ffi_typeof("int*"),				glComponentSize = 1,	glMaxComponentSize = 4},  
		[GL_INT_VEC2]           = {glType = "table",    rawType = ffi_typeof("int*"),				glComponentSize = 2,	glMaxComponentSize = 4,            glTableSize = 2},   -- 1x2
		[GL_INT_VEC3]           = {glType = "table",    rawType = ffi_typeof("int*"),				glComponentSize = 3,	glMaxComponentSize = 4,            glTableSize = 3},   -- 1x3
		[GL_INT_VEC4]           = {glType = "table",    rawType = ffi_typeof("int*"),				glComponentSize = 4,	glMaxComponentSize = 4,            glTableSize = 4},   -- 1x4
		[GL_UNSIGNED_INT]       = {glType = "number",   rawType = ffi_typeof("unsigned int*"),		glComponentSize = 1,	glMaxComponentSize = 4},  
		[GL_UNSIGNED_INT_VEC2]  = {glType = "table",    rawType = ffi_typeof("unsigned int*"),		glComponentSize = 2,	glMaxComponentSize = 4,   			glTableSize = 2},   -- 1x2
		[GL_UNSIGNED_INT_VEC3]  = {glType = "table",    rawType = ffi_typeof("unsigned int*"),		glComponentSize = 3,	glMaxComponentSize = 4,   			glTableSize = 3},   -- 1x3
		[GL_UNSIGNED_INT_VEC4]  = {glType = "table",    rawType = ffi_typeof("unsigned int*"),		glComponentSize = 4,	glMaxComponentSize = 4,   			glTableSize = 4},   -- 1x4
		[GL_DOUBLE]             = {glType = "number",   rawType = ffi_typeof("double*"),			glComponentSize = 2,	glMaxComponentSize = 8},
		[GL_DOUBLE_VEC2]        = {glType = "table",    rawType = ffi_typeof("double*"),			glComponentSize = 4,	glMaxComponentSize = 8,			glTableSize = 2},   -- 1x2
		[GL_DOUBLE_VEC3]        = {glType = "table",    rawType = ffi_typeof("double*"),			glComponentSize = 6,	glMaxComponentSize = 8,			glTableSize = 3},   -- 1x3
		[GL_DOUBLE_VEC4]        = {glType = "table",    rawType = ffi_typeof("double*"),			glComponentSize = 8,	glMaxComponentSize = 8,			glTableSize = 4},   -- 1x4
		[GL_DOUBLE_MAT2]        = {glType = "table",    rawType = ffi_typeof("double*"),			glComponentSize = 16,	glMaxComponentSize = 16,			glTableSize = 4},   -- 2x2
		[GL_DOUBLE_MAT3]        = {glType = "table",    rawType = ffi_typeof("double*"),			glComponentSize = 24,	glMaxComponentSize = 24,			glTableSize = 9},   -- 3x3
		[GL_DOUBLE_MAT4]        = {glType = "table",    rawType = ffi_typeof("double*"),			glComponentSize = 32,	glMaxComponentSize = 32,			glTableSize = 16},  -- 4x4
		[GL_DOUBLE_MAT2x3]      = {glType = "table",    rawType = ffi_typeof("double*"),			glComponentSize = 16,	glMaxComponentSize = 24,			glTableSize = 6},   -- 2x3
		[GL_DOUBLE_MAT2x4]      = {glType = "table",    rawType = ffi_typeof("double*"),			glComponentSize = 16,	glMaxComponentSize = 32,			glTableSize = 8},   -- 2x4
		[GL_DOUBLE_MAT3x2]      = {glType = "table",    rawType = ffi_typeof("double*"),			glComponentSize = 16,	glMaxComponentSize = 16,			glTableSize = 6},   -- 3x2
		[GL_DOUBLE_MAT3x4]      = {glType = "table",    rawType = ffi_typeof("double*"),			glComponentSize = 24,	glMaxComponentSize = 32,			glTableSize = 12},  -- 3x4
		[GL_DOUBLE_MAT4x2]      = {glType = "table",    rawType = ffi_typeof("double*"),			glComponentSize = 16,	glMaxComponentSize = 16,			glTableSize = 8},   -- 4x2
		[GL_DOUBLE_MAT4x3]      = {glType = "table",    rawType = ffi_typeof("double*"),			glComponentSize = 24,	glMaxComponentSize = 24,			glTableSize = 12},  -- 4x3
		[GL_SAMPLER_2D]         = {glType = "image",    rawType = ffi_typeof("void**"),				glComponentSize = 8,	glMaxComponentSize = 8, 			glTableSize = 2}
	}
	
	--[[Note on component sizes: Pre-GeForce 8xxx hardware, and all ATi hardware does this. In this case, you should assume that each separate uniform takes up 4 components, much like it would in D3D. That means a "uniform float" is 4 components, a mat2x4 is 16 components (each row is 4 components), but a mat4x2 is 8 components. --]]
	
	local glTypeAliasTable = 
	{
		Vector2 = "table",
		Vector3 = "table",
		Vector4 = "table",
		Mat2 = "table",
		Mat3 = "table",
		Mat4 = "table",
		Color = "table",
		Complex = "table"
	}
	
	function Graphics.glGetComponentSize(typ, maximal)
		if maximal then
			return glTypeTable[typ].glMaxComponentSize
		else
			return glTypeTable[typ].glComponentSize
		end
	end
	
	local hextocolor
	do
		local bitand = bit.band;
		local bitrshift = bit.rshift;
		
		local normaliser = 1/0xFF;
		
		function hextocolor(c, t)
			t[0] = bitand(bitrshift(c, 24), 0xFF)*normaliser
			t[1] = bitand(bitrshift(c, 16), 0xFF)*normaliser
			t[2] = bitand(bitrshift(c, 8), 0xFF)*normaliser
			t[3] = bitand(c, 0xFF)*normaliser
		end
	end

	local unboundVariableNames = {
		iChannel0=true,
		gl_Vertex=true,
		gl_Color=true,
		gl_MultiTexCoord0=true
	}
	
	local function validateAndConvertVariableTable(variableArgs, variableInfoTable, variableTypeName, arrayLen, varOutTable, allowNilInits)
		
		--[[
		variableArgs 
			--> named table where each key (attribute/uniform name) maps to a value
				i.e. { x = 50, y = 50}
				type: table
				key: attribute/uniform name
				value: value for the attribute/uniform [number or table]
		variableInfoTable
			--> The info (attribute/uniform) table from a shader (returned from shader:getUniformInfo() or shader:getAttributeInfo())
				type: table
		variableTypeName
			--> Type name (either "attribute" or "uniform"). Required for proper error handling.
				type: string
		arrayLen
			--> Vertex only: How many vertices (Value pack per vertex)
				Note: With attribute this value is always 1
				
		returns:
			--> named table with the converted data
				type: table
				key: the attribute/uniform id
				value: table containing following values:
					glType: the used gltype from Graphics.glTypeTable
					data: the raw allocated data
					count: how many elements of this type (if >1 then it is an array)
		]]
		
		local varOutCount = 0
		for _,varInfo in ipairs(variableInfoTable) do
			local varName = varInfo.rawName
			if not unboundVariableNames[varName] then
				local varValue = variableArgs[varName]
				
				-- TODO: Support multi-dimensional arrays
				if(varInfo.arrayDepth > 1) then
					error("Multi-dimensional arrays are not supported yet!", 3)
				end
				
				-- Variable type: GL_FLOAT, GL_FLOAT_VEC2, ...
				local variableType = varInfo.type
				-- Get metadata of the given type
				local glTypeOfVariable = glTypeTable[variableType]
				
				-- Check if we should skip this variable due to being passed a nil value
				if(not allowNilInits or varValue ~= nil or glTypeOfVariable.glType == "image") then
					-- Get the lua type of the value
					local glTypeOfVariableInArg = type(varValue)
					
					--Support for alias types (e.g. vectors)
					if(glTypeAliasTable[glTypeOfVariableInArg]) then
						glTypeOfVariableInArg = glTypeAliasTable[glTypeOfVariableInArg];
					end
					
					local sizeOfType = glTypeOfVariable.glTableSize or 1
					local totalNumberOfExpectedElements = varInfo.arrayCount * sizeOfType * arrayLen
					
					local flatternedResult = nil -- This array will be the input array
					if(glTypeOfVariable.glType == "number" and arrayLen == 1) then -- myUniformVar = 1.0
						if(glTypeOfVariableInArg == "number") then
							flatternedResult = {varValue}
						elseif(glTypeOfVariableInArg == "table") then -- myUniformVar = {1.0, 1.0, 1.0}
							flatternedResult = varValue
						else
							error("Invalid type for " .. variableTypeName .. " " .. varName .. " (expected number or table got " .. type(varValue) .. ")", 3)
						end
					elseif(glTypeOfVariable.glType == "table" or (glTypeOfVariable.glType == "number" and arrayLen > 1)) then -- arrayLen > 1
						if (glTypeOfVariableInArg == "table") then
							local firstElem = varValue[1]
							local typeOfFirstElem = type(firstElem)
							if(typeOfFirstElem == "number") then -- myUniformVar = {1.0, 1.0, 1.0, 1.0}
								flatternedResult = varValue
							else
								error("Invalid type for " .. variableTypeName .. " " .. varName .. " (expected table got " .. type(varValue) .. ")", 3)
							end
						else
							error("Invalid type for " .. variableTypeName .. " " .. varName .. " (expected table got " .. type(varValue) .. ")", 3)
						end
					elseif(glTypeOfVariable.glType == "image") then
						if (glTypeOfVariableInArg == "LuaImageResource") then
							flatternedResult = {varValue._ref, FFI_nullptr}
						elseif (glTypeOfVariableInArg == "CaptureBuffer") then
							flatternedResult = {FFI_nullptr, varValue._ref}
						elseif (glTypeOfVariableInArg == "table") and (type(varValue[1]) == "LuaImageResource") then
							flatternedResult = {}
							for _,v in ipairs(varValue) do
								local isLuaImageResource = (type(v) == "LuaImageResource")
								local isCaptureBuffer = (type(v) == "CaptureBuffer")
								local isNil = (type(v) == "nil")
								
								if (isLuaImageResource) then
									table_insert(flatternedResult, v._ref)
									table_insert(flatternedResult, FFI_nullptr)
								elseif (isCaptureBuffer) then
									table_insert(flatternedResult, FFI_nullptr)
									table_insert(flatternedResult, v._ref)
								elseif (isNil) then
									table_insert(flatternedResult, FFI_nullptr)
									table_insert(flatternedResult, FFI_nullptr)
								else
									error("Invalid type for " .. variableTypeName .. " " .. varName .. " (expected image)", 3)
								end
							end
						elseif (glTypeOfVariableInArg == "nil") then
							flatternedResult = {FFI_nullptr, FFI_nullptr}
						else
							error("Invalid type for " .. variableTypeName .. " " .. varName .. " (expected image)", 3)
						end
					else
						error("Internal error! Cannot convert unknown type: " + glTypeOfVariable.glType)
					end
					
					local actualNumberOfExpectedElements = #flatternedResult
					if(totalNumberOfExpectedElements ~= actualNumberOfExpectedElements) then
						optionalVerticesMultiplierStr = ""
						if arrayLen > 1 then
							optionalVerticesMultiplierStr = " * " .. arrayLen .. " vertices"
						end
					
						error("Invalid number of elements for " .. variableTypeName .. " " .. varName .. " (expected " .. totalNumberOfExpectedElements .. " values --> [" .. varInfo.arrayCount .. "x" .. sizeOfType .. "]" .. optionalVerticesMultiplierStr .. ", got " .. actualNumberOfExpectedElements .. ")", 3)
					end
					
					local var = varOutTable[varOutCount]
					var.mId = varInfo.id
					var.mType = varInfo.type
					var.mCount = varInfo.arrayCount*arrayLen
					var.mData = convertGlArray(flatternedResult, totalNumberOfExpectedElements, glTypeOfVariable.rawType)
					varOutCount = varOutCount + 1
				end
			end
		end
		return varOutCount
	end 

	function Graphics.glDraw(args)
		-- Deal with args...
		local target = args['target']
		local priority = nil_or(args['priority'], 1.0)
		local texture = args['texture']
		local color = args['color']
		local vertCoords = args['vertexCoords']
		local texCoords = args['textureCoords']
		local vertColor = args['vertexColors']
		local shader = args['shader']
		local attributeArgs = args['attributes']
		local uniformArgs = args['uniforms']
		local primitive = nil_or(args['primitive'], Graphics.GL_TRIANGLES)
		local sceneCoords = nil_or(args['sceneCoords'], false)
		local depthTest = nil_or(args['depthTest'], false)
		local linearFiltered = nil_or(args['linearFiltered'], false)
		args = nil
		
		local arr_len = nil
		if (vertCoords == nil) then
			error("Missing required argument: vertexCoords",2)
		end
		local arr_len = getGlElementCount(vertCoords, 2)
		if (texCoords ~= nil) then
			if (arr_len ~= getGlElementCount(texCoords, 2)) then
				error("Array length mismatch: textureCoords",2)
			end
		end
		if (vertColor ~= nil) then
			if (arr_len ~= getGlElementCount(vertColor, 4)) then
				error("Array length mismatch: vertexColors",2)
			end
		end
		vertCoords = convertGlArray(vertCoords, arr_len*2)
		texCoords = convertGlArray(texCoords, arr_len*2)
		vertColor = convertGlArray(vertColor, arr_len*4)
		
		
		if (shader) then
			shader:_tryShaderCompile()
			if(not shader.isCompiled) then
				shader = nil
			end
		end
		
		-- Validate attributes
		local attributeArgsCount = 0
		if(attributeArgs ~= nil and shader ~= nil) then
			attributeArgsCount = validateAndConvertVariableTable(attributeArgs, shader:getAttributeInfo(), "attribute", arr_len, attrs_tmp, false)
		end
		
		-- Validate uniforms
		-- TODO: Also accept uniforms/attributes with named argument, i.e. {x = 5, y = 5}
		local uniformArgsCount = 0
		if(uniformArgs ~= nil and shader ~= nil) then
			uniformArgsCount = validateAndConvertVariableTable(uniformArgs, shader:getUniformInfo(), "uniform", 1, unifs_tmp, true)
		end
		
		local targetRef = nil
		if (target ~= nil) and (type(target) == "CaptureBuffer") then
			targetRef = target._ref
		end
		
		local imgRef = nil
		local capRef = nil
		if (texture ~= nil) and (type(texture) == "LuaImageResource") then
			imgRef = texture._ref
		elseif (texture ~= nil) and (type(texture) == "CaptureBuffer") then
			capRef = texture._ref
		elseif (texture ~= nil) then
			error("Invalid texture type!")
		end
		
		gldraw_cmd_tmp.mTarget = targetRef
		gldraw_cmd_tmp.mImg = imgRef
		gldraw_cmd_tmp.mCap = capRef
		
		if (color == nil) then
			gldraw_cmd_tmp.mColor[0] = 1.0
			gldraw_cmd_tmp.mColor[1] = 1.0
			gldraw_cmd_tmp.mColor[2] = 1.0
			gldraw_cmd_tmp.mColor[3] = 1.0
		elseif (type(color) == "number") then
			hextocolor(color, gldraw_cmd_tmp.mColor)
		elseif (#color == 3) then
			gldraw_cmd_tmp.mColor[0] = color[1]
			gldraw_cmd_tmp.mColor[1] = color[2]
			gldraw_cmd_tmp.mColor[2] = color[3]
			gldraw_cmd_tmp.mColor[3] = 1.0
		else
			gldraw_cmd_tmp.mColor[0] = color[1]
			gldraw_cmd_tmp.mColor[1] = color[2]
			gldraw_cmd_tmp.mColor[2] = color[3]
			gldraw_cmd_tmp.mColor[3] = color[4]
		end
		
		gldraw_cmd_tmp.mType = primitive
		gldraw_cmd_tmp.mCount = arr_len
		gldraw_cmd_tmp.mSceneCoords = sceneCoords
		gldraw_cmd_tmp.mDepthTest = depthTest
		gldraw_cmd_tmp.mLinearFiltered = linearFiltered
		gldraw_cmd_tmp.mVert = vertCoords
		gldraw_cmd_tmp.mTex = texCoords
		gldraw_cmd_tmp.mVertColor = vertColor
		if (shader) then	
			gldraw_cmd_tmp.mShader = shader._cobj._obj
			gldraw_cmd_tmp.mAttrCount = attributeArgsCount
			gldraw_cmd_tmp.mAttrs = attrs_tmp
			gldraw_cmd_tmp.mUnifCount = uniformArgsCount
			gldraw_cmd_tmp.mUnifs = unifs_tmp
		else
			gldraw_cmd_tmp.mShader = nil
			gldraw_cmd_tmp.mAttrCount = 0
			gldraw_cmd_tmp.mAttrs = nil
			gldraw_cmd_tmp.mUnifCount = 0
			gldraw_cmd_tmp.mUnifs = nil
		end
		gldraw_cmd_tmp.mPriority = priority
		LunaDLL.FFI_GLDraw(gldraw_cmd_tmp)
	end
end

---------------------------------
-- Shader Class Implementation --
---------------------------------
do
	local function loadShaderFile(filename)
		if (filename == nil) then
			return nil
		end
		if (filename:find("%a:[/\\]") ~= 1) then
			local resolvedFilename = Misc.resolveFile(filename)
			if (resolvedFilename == nil) then
				error("Cannot find shader '" .. filename .. "'")
				return nil
			end
			filename = resolvedFilename
		end
		local source = io.readFile(filename);
		if (source == nil) then
			error("Could not open shader file.\nPath: " .. filename)
		end
		return source
	end
	
	-- Get standard vertex/fragment source
	local standardVertexSource = loadShaderFile(getSMBXPath().."\\scripts\\shaders\\standard.vert");
	local standardFragmentSource = loadShaderFile(getSMBXPath().."\\scripts\\shaders\\standard.frag");
	
	-- Function to read/process attribute/uniform info
	local function GetVariableInfo(shader, getter)
		local tbl = {}
		local idx = 0
		
		while true do
			local struct = getter(shader, idx)
			if (struct == nil) then
				break
			end
			idx = idx + 1
			
			if (struct.id ~= -1) then
				local data = {
					varInfoType=tonumber(struct.varInfoType),
					id=tonumber(struct.id),
					arrayCount=tonumber(struct.arrayCount),
					type=tonumber(struct.type),
					name=ffi.string(struct.name),
					rawName=ffi.string(struct.rawName),
					arrayDepth=tonumber(struct.arrayDepth)
				}
				table_insert(tbl, data)
			end
		end
		
		return tbl
	end
	local function GetAttributeInfo(shader)
		return GetVariableInfo(shader, LunaDLL.FFI_GetAttributeInfo)
	end
	local function GetUniformInfo(shader)
		return GetVariableInfo(shader, LunaDLL.FFI_GetUniformInfo)
	end
	
	-- Function to try to compile the shader
	local function TryShaderCompile(obj)
		if (obj == nil) then
			return false
		end
		local cobj = obj._cobj
		if (cobj == nil) or (cobj._obj == nil) or (cobj._error) then
			return false
		end
		if (cobj._isCompiled) then
			return true
		end
		
		-- Attempt to compile
		local compileRet = LunaDLL.FFI_ShaderCompile(cobj._obj);
		
		-- Handle errors
		if (not compileRet) then
			local err = LunaDLL.FFI_ShaderError(cobj._obj)
			if err ~= nil then
				-- Actual error
				cobj._error = true
				error(ffi.string(err))
				return false
			else
				-- Couldn't compile yet, but not because anything was wrong
				-- with the shader
				return false
			end
		end
		
		cobj._uniformInfo = GetUniformInfo(cobj._obj)
		cobj._attributeInfo = GetAttributeInfo(cobj._obj)
		cobj._isCompiled = true
		return true
	end
	
	
	-- Set up the preprocessor
	local shader_preprocessor = {}
	
	-- Shader Preprocessor
	if(lpeg ~= nil) then
		do
			shader_preprocessor.macros = { stack = {}, definedinfile = {}, used = {}, luadef = {} };
			shader_preprocessor.cache = {};
			shader_preprocessor.parser = {};
			
				
			local tableinsert = table.insert;
			local tableconcat = table.concat;
			

			local function parsebool(b)
				if(b) then
					return 1;
				else
					return 0;
				end
			end
			
			-- Preprocessor macro datatype parsing - allows tables and other objects to be passed as macros to a shader
			do
				local function tbltypecheck(t,typ)
					for _,v in ipairs(t) do
						if(type(v) ~= typ) then
							return false;
						end
					end
					return true;
				end
				
				local macrotypes = {}
				
				do
					function macrotypes.string(v) return v end
					
					macrotypes.number = macrotypes.string
					
					function macrotypes.boolean(v) return tostring(parsebool(v)) end
					
					function macrotypes.Vector2(v) return "(vec2("..v[1]..","..v[2].."))" end
					function macrotypes.Vector3(v) return "(vec3("..v[1]..","..v[2]..","..v[3].."))" end
					function macrotypes.Vector4(v) return "(vec4("..v[1]..","..v[2]..","..v[3]..","..v[4].."))" end
					
					macrotypes.Color = macrotypes.Vector4
					macrotypes.Complex = macrotypes.Vector2
					
					function macrotypes.Mat2(v) return "(mat2("..v[1]..","..v[2]..","..v[3]..","..v[4].."))" end
					function macrotypes.Mat3(v) return "(mat3("..v[1]..","..v[2]..","..v[3]..","..v[4]..","..v[5]..","..v[6]..","..v[7]..","..v[8]..","..v[9].."))" end
					function macrotypes.Mat4(v) return "(mat4("..v[1]..","..v[2]..","..v[3]..","..v[4]..","..v[5]..","..v[6]..","..v[7]..","..v[8]..","..v[9]..","..v[10]..","..v[11]..","..v[12]..","..v[13]..","..v[14]..","..v[15]..","..v[16].."))" end
					
					function macrotypes.table(v)
						if #v == 2 and tbltypecheck(v,"number") then
							return "(vec2("..v[1]..","..v[2].."))"
						elseif #v == 3 and tbltypecheck(v,"number") then
							return "(vec3("..v[1]..","..v[2]..","..v[3].."))"
						elseif #v == 4 and tbltypecheck(v,"number") then
							return "(vec4("..v[1]..","..v[2]..","..v[3]..","..v[4].."))"
						elseif #v == 9 and tbltypecheck(v,"number") then
							return "(mat3("..v[1]..","..v[2]..","..v[3]..","..v[4]..","..v[5]..","..v[6]..","..v[7]..","..v[8]..","..v[9].."))"
						elseif #v == 16 and tbltypecheck(v,"number") then
							return "(mat4("..v[1]..","..v[2]..","..v[3]..","..v[4]..","..v[5]..","..v[6]..","..v[7]..","..v[8]..","..v[9]..","..v[10]..","..v[11]..","..v[12]..","..v[13]..","..v[14]..","..v[15]..","..v[16].."))"
						end
						
						return nil
					end
				end
					
				function shader_preprocessor.macros.parse(v)
					local t = type(v)
					if macrotypes[t] then
						t = macrotypes[t](v)
					else 
						t = nil
					end
					
					if t then
						return t
					else
						local s = "Invalid type passed to shader macro. Expected "
						for k,_ in pairs(macrotypes) do
							s = s..k..", "
						end
						s = s.."or table, got ".. type(v).."."
						error(s, 2)
					end
				end
			end
			
			-- Substitutes a macro for its value
			function shader_preprocessor.parser.subMacro(c)
				local v = shader_preprocessor.macros.stack[c];
				if(v == nil) then
					return c;
				elseif(type(v) == "table") then
					return shader_preprocessor.parser.subFunMacro(c, nil);
				else
					tableinsert(shader_preprocessor.macros.used, c);
					return v;--shader_preprocessor.macros.parse(v);
				end
			end
			
			-- Pushes a new macro substitution onto the stack (#define)
			function shader_preprocessor.parser.pushMacro(k,v)
				if(shader_preprocessor.macros.stack[k] == nil or shader_preprocessor.macros.definedinfile[k] ~= nil) then 
					if(shader_preprocessor.macros.luadef[k] ~= nil) then
						shader_preprocessor.macros.stack[k] = shader_preprocessor.macros.luadef[k];
					else
						shader_preprocessor.macros.stack[k] = v; 
						shader_preprocessor.macros.definedinfile[k] = true;
					end
				end
			end
			
			
			-- Substitutes a function macro for its value, inserting the relevant arguments
			function shader_preprocessor.parser.subFunMacro(c, args)
				local v = shader_preprocessor.macros.stack[c];
				if(v == nil) then
					return c.."("..tableconcat(args,",")..")";
				elseif(type(v) ~= "table") then
					return shader_preprocessor.parser.subMacro(c).."("..tableconcat(args,",")..")";
				else
					tableinsert(shader_preprocessor.macros.used, c);
					local t = {};
					for k,w in ipairs(v.val) do
						if(type(w) == "number") then
							if(args == nil or args[w] == nil) then
								error("Not enough arguments supplied to function "..c, 10);
							end
							tableinsert(t, args[w]);
						elseif #t >0 then
							t[#t] = t[#t]..w;
						else 
							t[1] = w
						end
					end
					
					return tableconcat(t);
				end
			end
			
			-- Pushes a new function macro substitution onto the stack (#define)
			function shader_preprocessor.parser.pushFunMacro(k,args,v)
				if(shader_preprocessor.macros.stack[k] == nil or shader_preprocessor.macros.definedinfile[k] ~= nil) then
					if(shader_preprocessor.macros.luadef[k] ~= nil) then
						shader_preprocessor.macros.stack[k] = shader_preprocessor.macros.luadef[k];
					else
						local t = {};
						for l,w in ipairs(args) do
							t[w] = l;
						end
						shader_preprocessor.macros.funargs = t;
						shader_preprocessor.macros.stack[k] = {args = args, val = lpeg.match(shader_preprocessor.parser.fungrammar, v)};
						shader_preprocessor.macros.definedinfile[k] = true;
					end
				end
			end
			
			-- Pops a macro substitution from the stack (#undef)
			function shader_preprocessor.parser.popMacro(k,v)
				if(shader_preprocessor.macros.stack[k] ~= nil) then 
					if(shader_preprocessor.macros.definedinfile[k] == nil) then
						shader_preprocessor.macros.luadef[k] = shader_preprocessor.macros.stack[k];
					end
					shader_preprocessor.macros.stack[k] = nil; 
					shader_preprocessor.macros.definedinfile[k] = nil;
				end
			end
			
			-- Preprocesses the source of a given file and substitutes it into the original file (#include)
			function shader_preprocessor.parser.include(input)
				local initial = input;
				if(input:match("^[A-Za-z]:") == nil) then
					input = Misc.resolveFile(input);
				end
				if(input == nil) then
					error("Cannot find shader '" .. initial .. "'", 18)
				end
				return shader_preprocessor.preprocess(loadShaderFile(input));
			end
			
			-- Parses each "word" in a line to see if it needs to do a macro substitution
			function shader_preprocessor.parser.doMacro(c)
				for i = 1,#c do
					c[i] = shader_preprocessor.parser.subMacro(c[i]);
				end
				return tableconcat(c);
			end
			
			local argSubGrammar
			do		
				local white = lpeg.locale().space;
				local letter = lpeg.locale().alpha + "_";
				local space = lpeg.S(" \t");
				local any = lpeg.R("\000\255")
				local literal = ('"' * lpeg.C((any - '"')^0) * '"') + ("'" * lpeg.C((any - "'")^0) * "'")
				local var = (letter^1)*((lpeg.R("\048\057")+letter)^0);
				local num = lpeg.locale().digit;
				local prep = "#"*space^0;
				
				local newline = lpeg.P("\r\n") + lpeg.P("\n")
				local endif = white^0 * prep * "endif" * space^0;
				local els = white^0 * prep * "else" * space^0;
				local elif = white^0 * prep * "elif" * space^1 * lpeg.V("unparsed") * space^0;
				
				argSubGrammar = lpeg.P { 
										"expr", 
										expr = lpeg.Ct(lpeg.C((literal + var + num + lpeg.V("unparsed")))^1), 
										unparsed = any - newline - endif - els - elif 
									}
			end
			
			-- Parses each "word" in a line to see if it needs to do a macro substitution
			function shader_preprocessor.parser.subArgs(c)
				local r = {}
				for i = 1,#c do
					--May not be totally safe to assume splitting has already happened if things were nested, so split on word boundaries before performing variable substitution
					local t = lpeg.match(argSubGrammar, c[i])
						
					for j = 1,#t do
						t[j] = shader_preprocessor.parser.subMacro(t[j]);
						if(shader_preprocessor.macros.funargs[t[j]]) then
							t[j] = shader_preprocessor.macros.funargs[t[j]];
						end
						
						--Combine string elements because it's less messy that way
						if #r > 0 and type(r[#r]) ~= "number" and type(t[j]) ~= "number" then
							r[#r] = r[#r]..t[j]
						else
							tableinsert(r,t[j])
						end
					end
				end
				return r;
			end
			
			-- Parses ifdef statements, recursively parsing the body
			function shader_preprocessor.parser.ifdef(var, newline, body, body2)
				if(shader_preprocessor.macros.stack[var] ~= nil) then
					return tableconcat(lpeg.match(shader_preprocessor.parser.grammar, newline..tableconcat(body)));
				else
					tableinsert(shader_preprocessor.macros.used, var);
					if(body2) then
						return tableconcat(lpeg.match(shader_preprocessor.parser.grammar, newline..tableconcat(body2)));
					else
						return "";
					end
				end
			end
			
			-- Parses ifndef statements, recursively parsing the body
			function shader_preprocessor.parser.ifndef(var, newline, body)
				if(shader_preprocessor.macros.stack[var] ~= nil) then
					return "";
				else
					return tableconcat(lpeg.match(shader_preprocessor.parser.grammar, newline..tableconcat(body)));
				end
			end


			-- Parses if statements, recursively parsing the body
			function shader_preprocessor.parser.condition(cond, newline, body, body2)
				-- Perform macro/defined subtitution
				cond = lpeg.match(shader_preprocessor.parser.cgrammar_macrosub, cond)
				
				-- Evaluate expression
				cond = lpeg.match(shader_preprocessor.parser.cgrammar, cond)
				
				-- Handle propagated error string
				if (type(cond) ~= "number") then
					error("Invalid operand to GLSL preprocessor expression: "..tostring(cond), 12);
				end
				
				if(cond ~= 0) then
					return tableconcat(lpeg.match(shader_preprocessor.parser.grammar, newline..tableconcat(body)));
				elseif(body2) then
					if type(body2) == "table" then
						body2 = tableconcat(body2)
					end
					return tableconcat(lpeg.match(shader_preprocessor.parser.grammar, newline..body2));
				else
					return "";
				end
			end

			function shader_preprocessor.parser.c_unary(op, val)
				if (type(val) ~= "number") then
					-- Propagate invalid value, to error at top level
					return val;
				elseif(op == "+") then
					return val;
				elseif(op == "-") then
					return -val;
				elseif(op == "!") then
					return parsebool(not(val ~= 0));
				elseif(op == "~") then
					return bit.bnot(val);
				end
			end

			function shader_preprocessor.parser.c_defined(val)
				local v = shader_preprocessor.macros.stack[val]
				if v == nil then
					tableinsert(shader_preprocessor.macros.used, val);
				end
				return tostring(parsebool(v ~= nil));
			end
			
			function shader_preprocessor.parser.c_subMacro(val)
				local t = shader_preprocessor.parser.subMacro(val)
				t = lpeg.match(shader_preprocessor.parser.cgrammar_macrosub, t)
				local r = lpeg.match(shader_preprocessor.parser.cgrammar, t)
				
				-- Handle propagated error string
				if (type(r) ~= "number") then
					error("Invalid macro type used in GLSL preprocessor condition: "..tostring(t), 12);
				end
				return r
			end
				
			function shader_preprocessor.parser.c_binop(a, op, b)
				if(type(a) ~= "number") then
					-- Propagate invalid value, to error at top level
					return a;
				end
				if(type(b) ~= "number") then
					if (op == "&&") and not (a ~= 0) then
						-- Second argument won't matter for (false && ...)
						return parsebool(false);
					elseif (op == "||") and (a ~= 0) then
						-- Second argument won't matter for (true || ...)
						return parsebool(true);
					else
						-- Propagate invalid value, to error at top level
						return b;
					end
				end
				if(op == "||") then
					return parsebool(a ~= 0 or b ~= 0);
				elseif(op == "&&") then
					return parsebool(a ~= 0 and b ~= 0);
				elseif(op == "&") then
					return bit.band(a,b);
				elseif(op == "|") then
					return bit.bor(a,b);
				elseif(op == "^") then
					return bit.bxor(a,b);
				elseif(op == "<<") then
					return bit.lshift(a,b);
				elseif(op == ">>") then
					return bit.rshift(a,b);
				elseif(op == "==") then
					return parsebool(a == b);
				elseif(op == "!=") then
					return parsebool(a ~= b);
				elseif(op == "<") then
					return parsebool(a < b);
				elseif(op == ">") then
					return parsebool(a > b);
				elseif(op == "<=") then
					return parsebool(a <= b);
				elseif(op == ">=") then
					return parsebool(a >= b);
				elseif(op == "*") then
					return a*b;
				elseif(op == "/") then
					return a/b;
				elseif(op == "%") then
					return a%b;
				elseif(op == "+") then
					return a+b;
				elseif(op == "-") then
					return a-b;
				end
			end
			
			-- Define the preprocessor grammar
			do
				local white = lpeg.locale().space;
				local letter = lpeg.locale().alpha + "_";
				local space = lpeg.S(" \t");
				local any = lpeg.R("\000\255")
				local newline = lpeg.P("\r\n") + lpeg.P("\n")
				local literal = ('"' * lpeg.C((any - '"')^0) * '"') + ("'" * lpeg.C((any - "'")^0) * "'")
				local nonvar = (white - (lpeg.locale().alnum + "_"));
				local var = (letter^1)*((lpeg.R("\048\057")+letter)^0);
				local anyline = (any - newline) ^ 1;
				local prep = "#"*space^0;
				
				local endif = white^0 * prep * "endif" * space^0;
				local els = white^0 * prep * "else" * space^0;
				local elif = white^0 * prep * "elif" * space^1 * lpeg.V("unparsed") * space^0;
				local fullLine = (any - newline)^0 * newline;
				
				local ifdefin = (white^0 * prep * "ifdef" * space^1 * lpeg.C(var) * space^0 * lpeg.C(newline));
				local ifndefin = (white^0 * prep * "ifndef" * space^1 * lpeg.C(var) * space^0 * lpeg.C(newline));
				
				local condbody = (lpeg.V("cond")+lpeg.C(fullLine-endif-els-elif))^0;
				
				local endiforelse = (endif + (lpeg.V("elif")) + (els * lpeg.Ct(condbody) * endif));
				
				local args = "(" * ((space^0 * ")") + ((space^0 * lpeg.C(var) * space^0 * ",")^0 * space^0 * lpeg.C(var) * space^0 * ")"));
				
				local function concatexpr(c1,c2)
					return c1..c2;
				end
				
				local exprargs = "(" * ((space^0 * ")") + ((space^0 * lpeg.Cf(lpeg.V("funexpr")^1, concatexpr) * space^0 * ",")^0 * space^0 * lpeg.Cf(lpeg.V("funexpr")^1, concatexpr) * space^0 * ")"));

				local function removecomment() return "" end

				shader_preprocessor.parser.commentgrammar = lpeg.P
				{
					"shader",
					shader = lpeg.Ct((lpeg.C(any-"/*"-"//")+lpeg.V("comment"))^0);
					comment = lpeg.C(("//" * anyline) + ("/*" * (any-"*/")^0 * ("*/" + any^-1))) / removecomment;
				};
				
				shader_preprocessor.parser.fungrammar = lpeg.P
				{
					"expr",
					expr = lpeg.Ct((lpeg.V("macro") + lpeg.C(any - newline - endif - els - elif))^1) / shader_preprocessor.parser.subArgs,
					
					macro = lpeg.V("funmacro") + lpeg.V("objmacro"),
					objmacro = var / shader_preprocessor.parser.subMacro,
					funterm = (lpeg.V("macro") + lpeg.C((any - newline - "," - "(" - ")")));
					funexpr = (lpeg.V("funterm") + lpeg.Cf(lpeg.C("(")*lpeg.V("funexpr")^1*lpeg.C(")"), concatexpr))^1;
					funmacro = (lpeg.C(var) * space^0 * lpeg.Ct(exprargs)) / shader_preprocessor.parser.subFunMacro;
					unparsed = lpeg.Ct((lpeg.V("macro") + lpeg.C(any - newline - endif - els - elif))^1) / shader_preprocessor.parser.doMacro,
				};
				
				shader_preprocessor.parser.grammar = lpeg.P
				{
					"shader",
					shader = lpeg.Ct((lpeg.V("body")*lpeg.C(newline))^0 * lpeg.V("body")^-1),
					body = lpeg.V("comment") + lpeg.V("include") + lpeg.V("fundef") + lpeg.V("define") + lpeg.V("undef") + lpeg.V("cond") + lpeg.V("unparsed") + "",
					include = (white^0 * prep * "include" * space^1 * lpeg.V("literalormacro") * space^0) / shader_preprocessor.parser.include,
					macro = lpeg.V("funmacro") + lpeg.V("objmacro"),
					objmacro = var / shader_preprocessor.parser.subMacro,
					funterm = (lpeg.V("macro") + lpeg.C((any - newline - "," - "(" - ")")));
					funexpr = (lpeg.V("funterm") + lpeg.Cf(lpeg.C("(")*lpeg.V("funexpr")^1*lpeg.C(")"), concatexpr))^1;
					funmacro = (lpeg.C(var) * space^0 * lpeg.Ct(exprargs)) / shader_preprocessor.parser.subFunMacro;
					literalormacro = lpeg.V("macro") + literal,
					define = (white^0 * prep * "define" * space^1 * lpeg.C(var) * space^1 * (literal + lpeg.V("unparsed")) * space^0) / shader_preprocessor.parser.pushMacro,
					fundef = (white^0 * prep * "define" * space^1 * lpeg.C(var) * space^0 * lpeg.Ct(args) * space^1 * (lpeg.V("unparsed")) * space^0) / shader_preprocessor.parser.pushFunMacro,
					undef = (white^0 * prep * "undef" * space^1 * lpeg.C(var) * space^0) / shader_preprocessor.parser.popMacro,
					cond = (lpeg.V("iff") + lpeg.V("ifdef") + lpeg.V("ifndef")),
					iff = (white^0 * prep * "if" * space^1 * lpeg.Cg((any - newline - endif - els - elif)^1) * space^0 * lpeg.C(newline) * lpeg.Ct(condbody) * endiforelse)/shader_preprocessor.parser.condition,
					elif = (white^0 * prep * "elif" * space^1 * lpeg.Cg((any - newline - endif - els - elif)^1) * space^0 * lpeg.C(newline) * lpeg.Ct(condbody) * endiforelse) / shader_preprocessor.parser.condition,
					ifdef = (ifdefin * lpeg.Ct(condbody) * endiforelse)/shader_preprocessor.parser.ifdef,
					ifndef = (ifndefin * lpeg.Ct(condbody) * endiforelse)/shader_preprocessor.parser.ifndef,
					unparsed = lpeg.Ct((lpeg.V("macro") + lpeg.C(any - newline - endif - els - elif))^1) / shader_preprocessor.parser.doMacro,
					comment = lpeg.C(("//" * anyline) + ("/*" * (white+anyline)^0 * "*/"))
				};

				local function str_concat(a, b)
					return a .. b
				end
				
				shader_preprocessor.parser.cgrammar_macrosub = lpeg.P
				{
					"cexpr",
					macro = lpeg.V("cdefin") + lpeg.V("funmacro") + lpeg.V("objmacro"),
					objmacro = var / shader_preprocessor.parser.subMacro,
					funterm = (lpeg.V("macro") + lpeg.C((any - newline - "," - "(" - ")"))),
					funexpr = (lpeg.V("funterm") + lpeg.Cf(lpeg.C("(")*lpeg.V("funexpr")^1*lpeg.C(")"), concatexpr))^1,
					funmacro = (lpeg.C(var) * space^0 * lpeg.Ct(exprargs)) / shader_preprocessor.parser.subFunMacro,
					
					cdefin = ("defined"*((space^0 * "(" * space^0 * lpeg.C(var) * space^0 * ")") + (space^1 * lpeg.C(var))))/shader_preprocessor.parser.c_defined,
					
					-- We leave literally anything that doesn't match as a macro alone, and concat everything together
					cexpr = lpeg.Cf((lpeg.V("macro") + lpeg.C((any - lpeg.V("macro"))^1))^0, str_concat)
				};
				
				shader_preprocessor.parser.cgrammar = lpeg.P
				{
					"cexpr",
					
					-- Match normal macro syntax without actually expanding... we should only see undefined things here
					macro = lpeg.V("funmacro") + lpeg.V("objmacro"),
					objmacro = var,
					funterm = (lpeg.V("macro") + lpeg.C((any - newline - "," - "(" - ")"))),
					funexpr = (lpeg.V("funterm") + lpeg.Cf(lpeg.C("(")*lpeg.V("funexpr")^1*lpeg.C(")"), concatexpr))^1,
					funmacro = lpeg.C(var) * space^0 * lpeg.Ct(exprargs),
					
					cterm = lpeg.V("macro") + (lpeg.R("09")^1 * ("." * lpeg.R("09")^1)^-1) / tonumber,
					cexpr = space^0 * ("(" * lpeg.Cg(lpeg.V("cexpr")) * ")") + lpeg.Cg(lpeg.V("cunary") + lpeg.V("cbinary") + lpeg.V("cterm")) * space^0,
					cunary = (lpeg.C(lpeg.S("+-~!"))*lpeg.Cg(lpeg.V("cexpr"))) / shader_preprocessor.parser.c_unary,
					cbinary = space^0 * lpeg.Cf(lpeg.V("clogand") * space^0 * lpeg.Cg(lpeg.C("||") * lpeg.V("clogand"))^0, shader_preprocessor.parser.c_binop),
					clogand = space^0 * lpeg.Cf(lpeg.V("cbitor") * space^0 * lpeg.Cg(lpeg.C("&&") * lpeg.V("cbitor"))^0, shader_preprocessor.parser.c_binop),
					cbitor = space^0 * lpeg.Cf(lpeg.V("cbitxor") * space^0 * lpeg.Cg(lpeg.C("|") * lpeg.V("cbitxor"))^0, shader_preprocessor.parser.c_binop),
					cbitxor = space^0 * lpeg.Cf(lpeg.V("cbitand") * space^0 * lpeg.Cg(lpeg.C("^") * lpeg.V("cbitand"))^0, shader_preprocessor.parser.c_binop),
					cbitand = space^0 * lpeg.Cf(lpeg.V("ceq") * space^0 * lpeg.Cg(lpeg.C("&") * lpeg.V("ceq"))^0, shader_preprocessor.parser.c_binop),
					ceq = space^0 * lpeg.Cf(lpeg.V("crel") * space^0 * lpeg.Cg(lpeg.C(lpeg.P("==")+lpeg.P("!=")) * lpeg.V("crel"))^0, shader_preprocessor.parser.c_binop),
					crel = space^0 * lpeg.Cf(lpeg.V("cbitshift") * space^0 * lpeg.Cg(lpeg.C(lpeg.P("<")+lpeg.P(">")+lpeg.P("<=")+lpeg.P(">=")) * lpeg.V("cbitshift"))^0, shader_preprocessor.parser.c_binop),
					cbitshift = space^0 * lpeg.Cf(lpeg.V("cadd") * space^0 * lpeg.Cg(lpeg.C(lpeg.P("<<")+lpeg.P(">>")) * lpeg.V("cadd"))^0, shader_preprocessor.parser.c_binop),
					cadd = space^0 * lpeg.Cf(lpeg.V("cmul") * space^0 * lpeg.Cg(lpeg.C(lpeg.S("+-")) * lpeg.V("cmul"))^0, shader_preprocessor.parser.c_binop),
					cmul = space^0 * lpeg.Cf(lpeg.V("cmulterm") * space^0 * lpeg.Cg(lpeg.C(lpeg.S("*/%")) * lpeg.V("cmulterm"))^0, shader_preprocessor.parser.c_binop),
					cmulterm = space^0 * (lpeg.Cg(lpeg.V("cunary") + lpeg.V("cterm")) + ("("*space^0*lpeg.V("cexpr")*space^0*")"));
				};
			end
			
			-- Perform a preprocess pass on the source
			function shader_preprocessor.preprocess(source)
				return tableconcat(lpeg.match(shader_preprocessor.parser.grammar, tableconcat(lpeg.match(shader_preprocessor.parser.commentgrammar, source))));
			end
			
			-- Get preprocessed source from the cache, if it exists, returns nil otherwise
			function shader_preprocessor.cache.get(shader, macros)
				local cache = shader_preprocessor.cache[shader];
				if(cache == nil) then 
					return nil;
				else
					if(macros == nil and cache.macros == nil) then
						return cache.source;
					end
					
					if(macros == nil or cache.macros == nil) then
						return nil;
					end
					
					for _,v in ipairs(shader_preprocessor.macros.used) do
						if(macros[v] ~= cache.macros[v]) then
							return nil;
						end
					end
					return cache.source;
				end
			end

			-- Pushes newly preprocessed source into the cache
			function shader_preprocessor.cache.push(raw, shader, macros)
				local cache = {source = shader};
				
				if(macros ~= nil) then
					cache.macros = {};
					
					for _,v in ipairs(shader_preprocessor.macros.used) do
						cache.macros[v] = macros[v];
					end
				end
				
				shader_preprocessor.cache[raw] = cache;
			end
			
			function shader_preprocessor.execute(source, macrolist, _depth, _filepath)
				local s = shader_preprocessor.cache.get(source, macrolist);
				
				if(s ~= nil) then
					return s;
				else
					shader_preprocessor.macros.stack = {};
					shader_preprocessor.macros.definedinfile = {};
					
					if macrolist ~= nil then
						for k,v in pairs(macrolist) do
							shader_preprocessor.macros.stack[k] = shader_preprocessor.macros.parse(v)
						end
					end
					
					local safe, parsed = pcall(shader_preprocessor.preprocess, source, macrolist);
					if(safe) then
						shader_preprocessor.cache.push(source, parsed, macrolist);
						return parsed;
					elseif(_filepath) then
						error("Shader preprocessor error in "..(_filepath:match(".-([^\\]-[^%.]+)$") or _filepath)..": "..parsed, _depth);
					else
						error("Shader preprocessor error: "..parsed, _depth);
					end
				end
			end
		end
	else
		function shader_preprocessor.execute(source, macrolist)
			return source;
		end
	end
	--End Preprocessor
	
	local shaderCache = {}	
	
	-- Functions for feeding in shader source code
	local shaderCompileFromSource = function(obj, vertexSource, fragmentSource, macrolist, _depth, _vertpath, _fragpath)
		if (vertexSource == nil) then
			vertexSource = standardVertexSource
		else
			vertexSource = shader_preprocessor.execute(vertexSource, macrolist, _depth or 3, _vertpath);
		end
		if (fragmentSource == nil) then
			fragmentSource = standardFragmentSource
		else
			fragmentSource = shader_preprocessor.execute(fragmentSource, macrolist, _depth or 3, _fragpath);
		end
		
		local shaderCacheC1 = shaderCache[fragmentSource]
		if shaderCacheC1 == nil then
			shaderCacheC1 = {}
			shaderCache[fragmentSource] = shaderCacheC1
		end
		local shaderCacheObj = shaderCacheC1[vertexSource]
		if shaderCacheObj == nil then
			shaderCacheObj = {
					_attributeInfo={},
					_uniformInfo={},
					_isCompiled=false
				}
			shaderCacheC1[vertexSource] = shaderCacheObj
			
			shaderCacheObj._obj = ffi.gc(LunaDLL.FFI_ShaderFromStrings(vertexSource, fragmentSource), LunaDLL.FFI_ShaderFree)
		end
		obj._cobj = shaderCacheObj
		if (not shaderCacheObj._isCompiled) then
			TryShaderCompile(obj)
		end
	end
	
	local shaderCompileFromFile = function(obj, vertexFile, fragmentFile, macrolist)
		shaderCompileFromSource(obj, loadShaderFile(vertexFile), loadShaderFile(fragmentFile), macrolist, 4, vertexFile or "standard.vert", fragmentFile or "standard.frag")
	end
	
	-- Getters for uniform/attribute info
	local shaderGetUniformInfo = function(obj)
		if (not obj._cobj._isCompiled) then
			TryShaderCompile(obj)
		end
		return obj._cobj._uniformInfo
	end
	local shaderGetAttributeInfo = function(obj)
		if (not obj._cobj._isCompiled) then
			TryShaderCompile(obj)
		end
		return obj._cobj._attributeInfo
	end
	
	-- Shader class metatable
	local shaderMT = {}
	shaderMT.__index = function(obj, key)
		if key == 'isCompiled' then return obj._cobj._isCompiled
		elseif key == 'getAttributeInfo' then return shaderGetAttributeInfo
		elseif key == 'getUniformInfo' then return shaderGetUniformInfo
		elseif key == 'compileFromSource' then return shaderCompileFromSource
		elseif key == 'compileFromFile' then return shaderCompileFromFile
		elseif key == '_tryShaderCompile' then return TryShaderCompile
		else return nil end
	end
	shaderMT.__newindex = function(obj, key, val)
	end
	
	-- Shader class
	Graphics.Shader = setmetatable({}, {
		__call = function ()
			return setmetatable({
				_cobj={
					_obj={},
					_attributeInfo={},
					_uniformInfo={},
					_isCompiled=false
					},
			}, shaderMT)
		end,
	});
end

------------------------------------------------------------------
-- Graphics.placeSprite (& friends) implementation (DEPRECATED) --
------------------------------------------------------------------

function Graphics.placeSprite(ty, img, x, y, extra, t)
	local imgRef = nil;
	local resNum = -1;
	
	-- Work out if we're dealing with a resource number of image reference
	if type(img) == "number" then
		resNum = img
	elseif type(img) == "LuaImageResource" then
		imgRef = img._ref
	else
		error("invalid type for img")
	end
	
	-- Default arguments
	extra = nil_or(extra, "")
	t     = nil_or(t,     0)
	
	LunaDLL.FFI_SpritePlace(ty, resNum, imgRef, x, y, extra, t);
end

function Graphics.unplaceSprites(img, x, y)
	local imgRef = nil
	if type(img) == "LuaImageResource" then
		imgRef = img._ref
	else
		error("invalid type for img")
	end
	
	if (x == nil) or (y == nil) then
		LunaDLL.FFI_SpriteUnplace(imgRef)
	else
		LunaDLL.FFI_SpriteUnplaceWithPos(imgRef, x, y)
	end
end

----------------------------------------------------------------------
-- Graphics.glDrawTriangles (& friends) implementation (DEPRECATED) --
----------------------------------------------------------------------

do
	local currentColor = {1.0, 1.0, 1.0, 1.0}
	local currentTexture = nil
	
	function Graphics.glDrawTriangles(vertexCoords, textureCoords, vertexCount)
		local arrLen = 2 * vertexCount
		local vcRaw = {}
		local tcRaw = {}
		for i = 1,arrLen do
			vcRaw[i] = vertexCoords[i-1] or 0
		end
		for i = 1,arrLen do
			tcRaw[i] = textureCoords[i-1] or 0
		end
	
		Graphics.glDraw{
			vertexCoords  = vcRaw,
			textureCoords = tcRaw,
			texture       = currentTexture,
			color         = currentColor,
			primitive     = Graphics.GL_TRIANGLES
		}
	end
	
	function Graphics.glSetTexture(tex, h)
		currentTexture = tex
		if (h ~= nil) then
			currentColor = {(math_floor(h/(256*256)))/255,(math_floor(h/256)%256)/255,(h%256)/255,1}
		else
			currentColor = {1.0, 1.0, 1.0, 1.0}
		end
	end
	
	function Graphics.glSetTextureRGBA(tex, h)
		currentTexture = tex
		if (h ~= nil) then
			currentColor = {(math_floor(h/(256*256*256)))/255,(math_floor(h/(256*256))%256)/255,(math_floor(h/256)%256)/255,(h%256)/255}
		else
			currentColor = {1.0, 1.0, 1.0, 1.0}
		end
	end
end

---------------------------------------
-- Graphics.drawImage Implementation --
---------------------------------------

-- void __cdecl FFI_ImageDraw(LunaImageRef* img, double x, double y, double sx, double sy, double sw, double sh, double priority, float opacity, bool sceneCoords);

local function baseDrawImage(img, x, y, withPriority, sceneCoords, arg4, arg5, arg6, arg7, arg8, arg9)
	local imgRef = nil
	if type(img) == "LuaImageResource" then
		imgRef = img._ref
	else
		error("Invalid type for img")
	end
	
	if (x == nil) or (y == nil) then
		error("Position is required")
	end
	
	-- Default parameters
	local sx = 0
	local sy = 0
	local sw = img.width
	local sh = img.height
	local priority = 1.0
	local opacity = 1.0
	
	if (arg4 ~= nil) and (arg5 ~= nil) and (arg6 ~= nil) and (arg7 ~= nil) and (arg8 ~= nil) and ((not withPriority) or (arg9 ~= nil)) then
		-- drawImage(img, x, y, sx, sy, sw, sh, opacity)
		sx = arg4
		sy = arg5
		sw = arg6
		sh = arg7
		opacity = arg8
		if (withPriority) then priority = arg9 end
	elseif (arg4 ~= nil) and (arg5 ~= nil) and (arg6 ~= nil) and (arg7 ~= nil) and ((not withPriority) or (arg8 ~= nil)) then
		-- drawImage(img, x, y, sx, sy, sw, sh)
		sx = arg4
		sy = arg5
		sw = arg6
		sh = arg7
		if (withPriority) then priority = arg8 end
	elseif (arg4 ~= nil) and (arg5 ~= nil) and (arg6 ~= nil) and ((not withPriority) or (arg7 ~= nil)) then
		-- drawImage(img, x, y, sx, sy, opacity)
		sx = arg4
		sy = arg5
		opacity = arg6
		if (withPriority) then priority = arg7 end
	elseif (arg4 ~= nil) and (arg5 ~= nil) and ((not withPriority) or (arg6 ~= nil)) then
		-- drawImage(img, x, y, sx, sy)
		sx = arg4
		sy = arg5
		if (withPriority) then priority = arg6 end
	elseif (arg4 ~= nil) and ((not withPriority) or (arg5 ~= nil)) then
		-- drawImage(img, x, y, opacity)
		opacity = arg4
		if (withPriority) then priority = arg5 end
	elseif withPriority then
		priority = arg4
	else
		-- drawImage(img, x, y)
	end
	
	LunaDLL.FFI_ImageDraw(imgRef, x, y, sx, sy, sw, sh, priority, opacity, sceneCoords)
end

function Graphics.drawImage(img, x, y, arg4, arg5, arg6, arg7, arg8, arg9)
	baseDrawImage(img, x, y, false, false, arg4, arg5, arg6, arg7, arg8, arg9)
end

function Graphics.drawImageWP(img, x, y, arg4, arg5, arg6, arg7, arg8, arg9)
	baseDrawImage(img, x, y, true, false, arg4, arg5, arg6, arg7, arg8, arg9)
end

function Graphics.drawImageToScene(img, x, y, arg4, arg5, arg6, arg7, arg8, arg9)
	baseDrawImage(img, x, y, false, true, arg4, arg5, arg6, arg7, arg8, arg9)
end

function Graphics.drawImageToSceneWP(img, x, y, arg4, arg5, arg6, arg7, arg8, arg9)
	baseDrawImage(img, x, y, true, true, arg4, arg5, arg6, arg7, arg8, arg9)
end

---------------------------------
-- Text Drawing Implementation --
---------------------------------

-- NOTE: This is overwriting things in the Text namespace which is maybe not the best fit for here???

local function TextDraw(text, t, x, y, priority)
	LunaDLL.FFI_TextDraw(tostring(text), nil_or(t, 3), x, y, nil_or(priority, 3.0), false)
end

function Text.print(text, arg2, arg3, arg4)
	if (arg2 ~= nil) and (arg3 ~= nil) and (arg4 ~= nil) then
		-- Text.print(text, type, x, y)
		TextDraw(text, arg2, arg3, arg4)
	elseif (arg2 ~= nil) and (arg3 ~= nil) then
		-- Text.print(text, x, y)
		TextDraw(text, nil, arg2, arg3)
	else
		error("Invalid Arguments")
	end
end

function Text.printWP(text, arg2, arg3, arg4, arg5)
	if (arg2 ~= nil) and (arg3 ~= nil) and (arg4 ~= nil) and (arg5 ~= nil) then
		-- Text.print(text, type, x, y, priority)
		TextDraw(text, arg2, arg3, arg4, arg5)
	elseif (arg2 ~= nil) and (arg3 ~= nil) and (arg4 ~= nil) then
		-- Text.print(text, x, y, priority)
		TextDraw(text, nil, arg2, arg3, arg4)
	else
		error("Invalid Arguments")
	end
end

----------------------------------
-- Graphics.draw Implementation --
----------------------------------

function Graphics.draw(args)
	if (type(args) ~= "table") then
		error("Argument #1 must be a table with named arguments!")
	end

	-- Get general args
	local x = args.x
	local y = args.y
	local sceneCoords = nil_or(
			args.isSceneCoordinates,
			nil_or(args.isSceneCoords,
				nil_or(args.sceneCoords, false)
			)
		)
	
	-- Require coordinates
	if (x == nil) or (y == nil) then
		error("Missing coordinates")
	end

	if (args.type == RTYPE_IMAGE) then
		-- Check image reference
		local img = args.image
		local imgRef = nil
		if type(img) == "LuaImageResource" then
			imgRef = img._ref
		else
			error("Invalid type for image.")
		end
		
		-- Get image drawing specific args
		local sx = nil_or(args.sourceX, 0.0)
		local sy = nil_or(args.sourceY, 0.0)
		local sw = nil_or(args.sourceWidth, img.width)
		local sh = nil_or(args.sourceHeight, img.height)
		local opacity = nil_or(args.opacity, 1.0)
		local priority = nil_or(args.priority, 1.0)
		
		-- Skip drawing if 0 opacity
		if (opacity == 0.0) then return end
		
		LunaDLL.FFI_ImageDraw(imgRef, x, y, sx, sy, sw, sh, priority, opacity, sceneCoords)
	elseif (args.type == RTYPE_TEXT) then
		local text     = args.text
		local fontType = nil_or(args.fontType, 3)
		local priority = nil_or(args.priority, 3.0)
		
		LunaDLL.FFI_TextDraw(tostring(text), fontType, x, y, priority, sceneCoords)
	else
		error("No valid 'type'. Must be RTYPE_TEXT or RTYPE_IMAGE")
	end
end

-------------------------------------
-- Graphics.sprites implementation --
-------------------------------------

-- void __fastcall FFI_SetSpriteOverride(const char* name, LunaImageRef* img);
-- LunaImageRef* __fastcall FFI_GetSpriteOverride(const char* name);

do
	local spriteCache = {}
	
	-- Clear sprite cache upon onStart
	if registerEvent then
		local spriteCacheReset = { onStart = function ()
			spriteCache = {}
		end	}
		registerEvent(spriteCacheReset, "onStart", "onStart", true)
	end

	local function SetSpriteOverride(name, img)
		local imgRef = nil
		if (img == nil) then
			imgRef = nil
		elseif (type(img) == "LuaImageResource") then
			imgRef = img._ref
		else
			error("Invalid type for image.")
		end
		
		LunaDLL.FFI_SetSpriteOverride(name, imgRef)
		spriteCache[name] = img
	end

	local function GetSpriteOverride(name)
		local sprite = spriteCache[name]
		if sprite ~= nil then
			return sprite
		end
		
		-- Get the image
		local imgRef = ffi.gc(LunaDLL.FFI_GetSpriteOverride(name, tmpSize), LunaDLL.FFI_ImageFree)
		
		if (imgRef == nil) then
			return nil
		end
		
		sprite = setmetatable({_ref=imgRef, width=tmpSize[0], height=tmpSize[1]}, LuaImageResourceMT)
		spriteCache[name] = sprite
		return sprite
	end

	-- This function creates the "virtual" attributes for the sprite table.
	local spriteMT = {
		__index = function(tbl, key)
			if (key == "img") then
				return GetSpriteOverride(tbl._name)
			end
			error("'" .. tbl._name .. "'." .. tostring(key) .. " does not exist")
		end,
		__newindex = function(tbl,key,val)
			if (key == "img") then
				return SetSpriteOverride(tbl._name, val)
			end
			error("'" .. tbl._name .. "'." .. tostring(key) .. " does not exist")
		end
	}
	
	local bgospriteMT = {
		__index = spriteMT.__index,
		__newindex = function(tbl,key,val)
			if (key == "img") then
				local r = SetSpriteOverride(tbl._name, val)
				BGO.config.__updateCache(tbl._id)
				return r
			end
			error("'" .. tbl._name .. "'." .. tostring(key) .. " does not exist")
		end
	}
	
	local function makeSpriteTable(spriteTypeKey, spriteIdx)
		local name = spriteTypeKey .. "-" .. tostring(spriteIdx)
		if spriteTypeKey == "background" then
			return setmetatable({_name=name, _id=spriteIdx}, bgospriteMT);
		else
			return setmetatable({_name=name}, spriteMT);
		end
	end

	-- This function will create the Graphics.sprite.**** table, where **** is spriteTypeKey
	-- i.e Graphics.sprite.block
	local spriteTypeMT = {
		__index = function(tbl, spriteIdx)
			local ret = makeSpriteTable(tbl._spriteTypeKey, spriteIdx)
			rawset(tbl, spriteIdx, ret)
			return ret
		end,
		__newindex = function(tbl,key,val)
			error("Cannot write to Graphics.sprites." .. tbl._spriteTypeKey .. " table")
		end
	}
	local function makeSpriteTypeTable(spriteTypeKey)
		return setmetatable({_spriteTypeKey=spriteTypeKey}, spriteTypeMT)
	end

	-- To improve performance, we can cache those type tables
	local spritesMetatable = {
		__index = function(tbl, spriteTypeKey)
			local ret = makeSpriteTypeTable(spriteTypeKey)
			rawset(tbl, spriteTypeKey, ret)
			return ret
		end,
		__newindex = function(tbl,key,val)
			error("Cannot write to Graphics.sprites table")
		end
	}
	
	-- Create Graphics.sprites table
	Graphics.sprites = {}
	
	-- Function to register extra sprites
	function Graphics.sprites.Register(folderName, name)
		LunaDLL.FFI_RegisterExtraSprite(folderName, name);
	end
	
	-- Finalize metatable
	Graphics.sprites = setmetatable(Graphics.sprites, spritesMetatable);
end

--------------------------
-- Image Data Retrieval --
--------------------------

local FFI_uint32_t = ffi_typeof("uint32_t*")

local bits32MT = {
-- Metamethods
	__index = function(tbl, key)
		if(0 > key or tbl.__maxidx < key) then error("Bit-Array out of bounds. (Valid index: 0-" .. tbl.__maxidx .. ", got " .. key .. ")", 2) end
		return tbl.__data[key]
	end,
	__newindex = function(tbl, key, value)
		if(0 > key or tbl.__maxidx < key) then error("Bit-Array out of bounds. (Valid index: 0-" .. tbl.__maxidx .. ", got " .. key .. ")", 2) end
		tbl.__data[key] = value
	end
}
function Graphics.getBits32(img)
	local imgRef = nil
	if (type(img) == "LuaImageResource") then
		imgRef = img._ref
	else
		error("Invalid type for image.")
	end
	
	local w = img.width
	local h = img.height
	local raw = ffi_cast(FFI_uint32_t, LunaDLL.FFI_ImageGetDataPtr(imgRef))
	
	local tbl = setmetatable({
	-- Normal Fields
		__data = raw,
		__maxidx = w * h - 1,
		__resImgRef = img -- Hold a strong reference, to prevent deallocation to the data
	}, bits32MT)
	
	return tbl
end

function Graphics.getPixelData(img)
	local imgRef = nil
	if (type(img) == "LuaImageResource") then
		imgRef = img._ref
	else
		error("Invalid type for image.")
	end
	
	local w = img.width
	local h = img.height
	local raw = ffi_cast(FFI_uint32_t, LunaDLL.FFI_ImageGetDataPtr(imgRef))
	
	local data = {}
	for i=0,w*h-1 do
		data[i+1] = raw[i]
	end
	
	return data, w, h
end

--------------------
-- Capture Buffer --
--------------------

local CaptureBufferFuncs = {__type="CaptureBuffer"}
local CaptureBufferMT = {__index=CaptureBufferFuncs, __type="CaptureBuffer"}

function CaptureBufferFuncs:captureAt(priority)
	local ref = nil
	if (type(self) == "CaptureBuffer") then
		ref = self._ref
	else
		error("Invalid type for capture buffer.")
	end

	LunaDLL.FFI_CaptureBufferCaptureAt(ref, priority)
end

function CaptureBufferFuncs:clear(priority)
	local ref = nil
	if (type(self) == "CaptureBuffer") then
		ref = self._ref
	else
		error("Invalid type for capture buffer.")
	end
	
	LunaDLL.FFI_CaptureBufferClear(ref, priority)
end

function Graphics.CaptureBuffer(w, h, nonskippable)
	w = nil_or(w, 800)
	h = nil_or(h, 600)
	nonskippable = nil_or(nonskippable, false)
	
	-- Create Capture Buffer Object
	local ref = ffi.gc(LunaDLL.FFI_CaptureBuffer(w, h, nonskippable), LunaDLL.FFI_CaptureBufferFree)
	
	if (ref == nil) then
		error("Could not create CaptureBuffer")
		return nil
	end

	return setmetatable({_ref=ref, width = w, height = h}, CaptureBufferMT)
end

-----------------------
-- Level HUD Control --
-----------------------

if (not isOverworld) then
	function Graphics.activateHud(value)
		LunaDLL.FFI_GraphicsActivateHud(value)
	end

	function Graphics.isHudActivated()
		return LunaDLL.FFI_GraphicsIsHudActivated()
	end
end

---------------------------
-- Overworld HUD Control --
---------------------------

if (isOverworld) then
	function Graphics.activateOverworldHud(value)
		LunaDLL.FFI_GraphicsActivateOverworldHud(value)
	end

	function Graphics.getOverworldHudState()
		return LunaDLL.FFI_GraphicsGetOverworldHudState()
	end
end

----------------------
-- Helper Functions --
----------------------

do
	--Please update this as more args are added to glDraw
	local glDrawArgs = {"target", "priority", "texture", "color", "vertexCoords", "textureCoords", "vertexColors", "shader", "attributes", "uniforms", "primitive", "sceneCoords", "depthTest", "linearFiltered" }
	
	
	local function cloneDrawTable(args, rtrn)
		if rtrn == nil then rtrn = {} end
		for _,v in ipairs(glDrawArgs) do
			rtrn[v] = args[v];
		end
		return rtrn;
	end
	
	--Making this publicly accessible so other libraries can use it if necessary
	Graphics.__copyDrawTable = cloneDrawTable
	
	local function getTexCoords(args)
		local sx,sy = args.sourceX or 0, args.sourceY or 0
		local sw, sh = args.sourceWidth, args.sourceHeight
		if args.texture then
			sx,sy = sx/args.texture.width, sy/args.texture.height
			if sw then
				sw = sw/args.texture.width
			else
				sw = 1
			end
			if sh then
				sh = sh/args.texture.height
			else
				sh = 1
			end
		else
			sw = 1
			sh = 1
		end
		return sx,sy,sw,sh
	end

	function Graphics.drawBox(args)
		local t = cloneDrawTable(args);
		t.x = args.x;
		t.y = args.y;
		
		local sx,sy,sw,sh = getTexCoords(args)
		t.w = args.width or args.w or t.texture.width*sw;
		t.h = args.height or args.h or t.texture.height*sh;
		
		if args.centered or args.centred then
			local w,h = t.w*0.5, t.h*0.5
			
			if args.rotation ~= nil and args.rotation ~= 0 then
				local angle = math.rad(args.rotation or 0)
				local sn = math_sin(angle);
				local cs = math_cos(angle);
				
				local w1 = cs*w
				local w2 = sn*w
				local h1 = sn*h
				local h2 = cs*h
				
				t.vertexCoords = t.vertexCoords or {t.x+h1-w1,t.y-h2-w2,t.x+h1+w1,t.y-h2+w2,t.x-h1+w1,t.y+h2+w2,t.x-h1-w1,t.y+h2-w2};
			else
				t.vertexCoords = t.vertexCoords or {t.x-w,t.y-h,t.x+w,t.y-h,t.x+w,t.y+h,t.x-w,t.y+h};
			end
		else
				
			if args.rotation ~= nil and args.rotation ~= 0 then
			
				local angle = math.rad(args.rotation or 0)
				local sn = math_sin(angle);
				local cs = math_cos(angle);
				
				local w1 = cs*t.w
				local w2 = sn*t.w
				local h1 = sn*t.h
				local h2 = cs*t.h
				
				t.vertexCoords = t.vertexCoords or {t.x,t.y,t.x+w1,t.y+w2,t.x+w1-h1,t.y+w2+h2,t.x-h1,t.y+h2};
			else
				t.vertexCoords = t.vertexCoords or {t.x,t.y,t.x+t.w,t.y,t.x+t.w,t.y+t.h,t.x,t.y+t.h};
			end
		end
		
		t.textureCoords = t.textureCoords or {sx,sy,sx+sw,sy,sx+sw,sy+sh,sx,sy+sh};
		t.primitive = t.primitive or Graphics.GL_TRIANGLE_FAN;
		
		Graphics.glDraw(t);
	end

	function Graphics.drawScreen(args)
		local t = cloneDrawTable(args);
		t.camera = args.camera or args.cam or camera;
		t.x = 0-- t.camera.renderX;
		t.y = 0-- t.camera.renderY;
		t.w = t.camera.width;
		t.h = t.camera.height;
		t.vertexCoords = t.vertexCoords or {t.x,t.y,t.x+t.w,t.y,t.x+t.w,t.y+t.h,t.x,t.y+t.h};
		
		local sx,sy,sw,sh = getTexCoords(args)
		t.textureCoords = t.textureCoords or {sx,sy,sx+sw,sy,sx+sw,sy+sh,sx,sy+sh};
		t.primitive = t.primitive or Graphics.GL_TRIANGLE_FAN;
		
		Graphics.glDraw(t);
	end

	function Graphics.drawLine(args)
		local t = cloneDrawTable(args);
		if(args.start ~= nil) then
			t.x1 = args.start.x or args.start[1] or args.x1;
			t.y1 = args.start.y or args.start[2] or args.y1;
		else
			t.x1 = args.x1;
			t.y1 = args.y1;
		end
		if(args.stop ~= nil) then
			t.x2 = args.stop.x or args.stop[1] or args.x2;
			t.y2 = args.stop.y or args.stop[2] or args.y2;
		else
			t.x2 = args.x2;
			t.y2 = args.y2;
		end
		
		t.vertexCoords = t.vertexCoords or {t.x1,t.y1,t.x2,t.y2};
		t.primitive = t.primitive or Graphics.GL_LINES;
		Graphics.glDraw(t);
	end
	
	function Graphics.drawCircle(args)
		local t = cloneDrawTable(args);
		t.x = args.x;
		t.y = args.y;
		t.radius = args.radius;
		if(t.vertexCoords == nil or t.textureCoords == nil) then
			local vs = {t.x, t.y};
			
			local sx,sy,sw,sh = getTexCoords(args)
			local tx = {sx + sw*0.5,sy + sh*0.5};
			local angle = 0;
			local res = math_ceil(math_sqrt(t.radius))*4;
			if(res < 2) then
				res = 2;
			end
			local da = 6.28318530718/res; --2pi/res
			local offset = math.rad(args.rotation or 0)
			for i=1,res+1 do
				local sn = math_sin(angle - offset);
				local cs = math_cos(angle - offset);
				table_insert(vs, t.x+t.radius*sn)
				table_insert(vs, t.y+t.radius*cs)
				if offset ~= 0 then
					sn = math_sin(angle);
					cs = math_cos(angle);
				end
				table_insert(tx, sx + sw*0.5+sw*0.5*sn)
				table_insert(tx, sy + sh*0.5+sh*0.5*cs)
				angle = angle + da;
			end
			t.vertexCoords = t.vertexCoords or vs;
			t.textureCoords = t.textureCoords or tx;
		end
		t.primitive = t.primitive or Graphics.GL_TRIANGLE_FAN;
		
		Graphics.glDraw(t);
	end
end

--------------------
-- Misc Functions --
--------------------
local cachedIsSoftwareGL = LunaDLL.FFI_GraphicsIsSoftwareGL()
function Graphics.isSoftwareGL()
	return cachedIsSoftwareGL
end

local tmpFrameStats = ffi_new("FrameStatStruct")
function Graphics.getFrameStats()
	LunaDLL.FFI_GraphicsGetFrameStats(tmpFrameStats)
	return tonumber(tmpFrameStats.totalCount), tonumber(tmpFrameStats.skipCount)
end

---------------------
-- Globals Classes --
---------------------
Globals.CaptureBuffer = Graphics.CaptureBuffer
Globals.Shader = Graphics.Shader

------------------------
-- Globals Deprecated --
------------------------

do
	local textPrint = Text.print
	local graphicsLoadImage = Graphics.loadImage
	local graphicsPlaceSprite = Graphics.placeSprite

	function Globals.printText(text, arg2, arg3, arg4)
		textPrint(text, arg2, arg3, arg4)
	end
	
	function Globals.loadImage(path, DEPRECATEDresNumber, DEPRECATEDtransColor)
		return graphicsLoadImage(path, DEPRECATEDresNumber, DEPRECATEDtransColor)
	end
	
	function Globals.placeSprite(ty, img, x, y, extra, t)
		graphicsPlaceSprite(ty, img, x, y, extra, t)
	end
	
	if (not isOverworld) then
		function Globals.hud(value)
			LunaDLL.FFI_GraphicsActivateHud(value)
		end
	end
end

---------------
-- Constants --
---------------

do
	local constants = LunaDLL.FFI_GraphicsGetConstants()
	if (constants.pcVENDOR ~= nil) then
		Graphics.GL_VENDOR = ffi.string(constants.pcVENDOR)
	else
		Graphics.GL_VENDOR = ""
	end
	if (constants.pcRENDERER ~= nil) then
		Graphics.GL_RENDERER = ffi.string(constants.pcRENDERER)
	else
		Graphics.GL_RENDERER = ""
	end
	if (constants.pcVERSION ~= nil) then
		Graphics.GL_VERSION = ffi.string(constants.pcVERSION)
	else
		Graphics.GL_VERSION = ""
	end
	if (constants.pcSHADING_LANGUAGE_VERSION ~= nil) then
		Graphics.GL_SHADING_LANGUAGE_VERSION = ffi.string(constants.pcSHADING_LANGUAGE_VERSION)
	else
		Graphics.GL_SHADING_LANGUAGE_VERSION = ""
	end
	Graphics.GL_MAJOR_VERSION = tonumber(constants.iMAJOR_VERSION)
	Graphics.GL_MINOR_VERSION = tonumber(constants.iMINOR_VERSION)
	Graphics.GL_MAX_COMPUTE_SHADER_STORAGE_BLOCKS = tonumber(constants.iMAX_COMPUTE_SHADER_STORAGE_BLOCKS)
	Graphics.GL_MAX_COMBINED_SHADER_STORAGE_BLOCKS = tonumber(constants.iMAX_COMBINED_SHADER_STORAGE_BLOCKS)
	Graphics.GL_MAX_COMPUTE_UNIFORM_BLOCKS = tonumber(constants.iMAX_COMPUTE_UNIFORM_BLOCKS)
	Graphics.GL_MAX_COMPUTE_TEXTURE_IMAGE_UNITS = tonumber(constants.iMAX_COMPUTE_TEXTURE_IMAGE_UNITS)
	Graphics.GL_MAX_COMPUTE_UNIFORM_COMPONENTS = tonumber(constants.iMAX_COMPUTE_UNIFORM_COMPONENTS)
	Graphics.GL_MAX_COMPUTE_ATOMIC_COUNTERS = tonumber(constants.iMAX_COMPUTE_ATOMIC_COUNTERS)
	Graphics.GL_MAX_COMPUTE_ATOMIC_COUNTER_BUFFERS = tonumber(constants.iMAX_COMPUTE_ATOMIC_COUNTER_BUFFERS)
	Graphics.GL_MAX_COMBINED_COMPUTE_UNIFORM_COMPONENTS = tonumber(constants.iMAX_COMBINED_COMPUTE_UNIFORM_COMPONENTS)
	Graphics.GL_MAX_COMPUTE_WORK_GROUP_INVOCATIONS = tonumber(constants.iMAX_COMPUTE_WORK_GROUP_INVOCATIONS)
	Graphics.GL_MAX_COMPUTE_WORK_GROUP_COUNT = tonumber(constants.iMAX_COMPUTE_WORK_GROUP_COUNT)
	Graphics.GL_MAX_COMPUTE_WORK_GROUP_SIZE = tonumber(constants.iMAX_COMPUTE_WORK_GROUP_SIZE)
	Graphics.GL_MAX_DEBUG_GROUP_STACK_DEPTH = tonumber(constants.iMAX_DEBUG_GROUP_STACK_DEPTH)
	Graphics.GL_MAX_3D_TEXTURE_SIZE = tonumber(constants.iMAX_3D_TEXTURE_SIZE)
	Graphics.GL_MAX_ARRAY_TEXTURE_LAYERS = tonumber(constants.iMAX_ARRAY_TEXTURE_LAYERS)
	Graphics.GL_MAX_CLIP_DISTANCES = tonumber(constants.iMAX_CLIP_DISTANCES)
	Graphics.GL_MAX_COLOR_TEXTURE_SAMPLES = tonumber(constants.iMAX_COLOR_TEXTURE_SAMPLES)
	Graphics.GL_MAX_COMBINED_ATOMIC_COUNTERS = tonumber(constants.iMAX_COMBINED_ATOMIC_COUNTERS)
	Graphics.GL_MAX_COMBINED_FRAGMENT_UNIFORM_COMPONENTS = tonumber(constants.iMAX_COMBINED_FRAGMENT_UNIFORM_COMPONENTS)
	Graphics.GL_MAX_COMBINED_GEOMETRY_UNIFORM_COMPONENTS = tonumber(constants.iMAX_COMBINED_GEOMETRY_UNIFORM_COMPONENTS)
	Graphics.GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS = tonumber(constants.iMAX_COMBINED_TEXTURE_IMAGE_UNITS)
	Graphics.GL_MAX_COMBINED_UNIFORM_BLOCKS = tonumber(constants.iMAX_COMBINED_UNIFORM_BLOCKS)
	Graphics.GL_MAX_COMBINED_VERTEX_UNIFORM_COMPONENTS = tonumber(constants.iMAX_COMBINED_VERTEX_UNIFORM_COMPONENTS)
	Graphics.GL_MAX_CUBE_MAP_TEXTURE_SIZE = tonumber(constants.iMAX_CUBE_MAP_TEXTURE_SIZE)
	Graphics.GL_MAX_DEPTH_TEXTURE_SAMPLES = tonumber(constants.iMAX_DEPTH_TEXTURE_SAMPLES)
	Graphics.GL_MAX_DRAW_BUFFERS = tonumber(constants.iMAX_DRAW_BUFFERS)
	Graphics.GL_MAX_DUAL_SOURCE_DRAW_BUFFERS = tonumber(constants.iMAX_DUAL_SOURCE_DRAW_BUFFERS)
	Graphics.GL_MAX_ELEMENTS_INDICES = tonumber(constants.iMAX_ELEMENTS_INDICES)
	Graphics.GL_MAX_ELEMENTS_VERTICES = tonumber(constants.iMAX_ELEMENTS_VERTICES)
	Graphics.GL_MAX_FRAGMENT_ATOMIC_COUNTERS = tonumber(constants.iMAX_FRAGMENT_ATOMIC_COUNTERS)
	Graphics.GL_MAX_FRAGMENT_SHADER_STORAGE_BLOCKS = tonumber(constants.iMAX_FRAGMENT_SHADER_STORAGE_BLOCKS)
	Graphics.GL_MAX_FRAGMENT_INPUT_COMPONENTS = tonumber(constants.iMAX_FRAGMENT_INPUT_COMPONENTS)
	Graphics.GL_MAX_FRAGMENT_UNIFORM_COMPONENTS = tonumber(constants.iMAX_FRAGMENT_UNIFORM_COMPONENTS)
	Graphics.GL_MAX_FRAGMENT_UNIFORM_VECTORS = tonumber(constants.iMAX_FRAGMENT_UNIFORM_VECTORS)
	Graphics.GL_MAX_FRAGMENT_UNIFORM_BLOCKS = tonumber(constants.iMAX_FRAGMENT_UNIFORM_BLOCKS)
	Graphics.GL_MAX_FRAMEBUFFER_WIDTH = tonumber(constants.iMAX_FRAMEBUFFER_WIDTH)
	Graphics.GL_MAX_FRAMEBUFFER_HEIGHT = tonumber(constants.iMAX_FRAMEBUFFER_HEIGHT)
	Graphics.GL_MAX_FRAMEBUFFER_LAYERS = tonumber(constants.iMAX_FRAMEBUFFER_LAYERS)
	Graphics.GL_MAX_FRAMEBUFFER_SAMPLES = tonumber(constants.iMAX_FRAMEBUFFER_SAMPLES)
	Graphics.GL_MAX_GEOMETRY_ATOMIC_COUNTERS = tonumber(constants.iMAX_GEOMETRY_ATOMIC_COUNTERS)
	Graphics.GL_MAX_GEOMETRY_SHADER_STORAGE_BLOCKS = tonumber(constants.iMAX_GEOMETRY_SHADER_STORAGE_BLOCKS)
	Graphics.GL_MAX_GEOMETRY_INPUT_COMPONENTS = tonumber(constants.iMAX_GEOMETRY_INPUT_COMPONENTS)
	Graphics.GL_MAX_GEOMETRY_OUTPUT_COMPONENTS = tonumber(constants.iMAX_GEOMETRY_OUTPUT_COMPONENTS)
	Graphics.GL_MAX_GEOMETRY_TEXTURE_IMAGE_UNITS = tonumber(constants.iMAX_GEOMETRY_TEXTURE_IMAGE_UNITS)
	Graphics.GL_MAX_GEOMETRY_UNIFORM_BLOCKS = tonumber(constants.iMAX_GEOMETRY_UNIFORM_BLOCKS)
	Graphics.GL_MAX_GEOMETRY_UNIFORM_COMPONENTS = tonumber(constants.iMAX_GEOMETRY_UNIFORM_COMPONENTS)
	Graphics.GL_MAX_INTEGER_SAMPLES = tonumber(constants.iMAX_INTEGER_SAMPLES)
	Graphics.GL_MAX_LABEL_LENGTH = tonumber(constants.iMAX_LABEL_LENGTH)
	Graphics.GL_MAX_PROGRAM_TEXEL_OFFSET = tonumber(constants.iMAX_PROGRAM_TEXEL_OFFSET)
	Graphics.GL_MAX_RECTANGLE_TEXTURE_SIZE = tonumber(constants.iMAX_RECTANGLE_TEXTURE_SIZE)
	Graphics.GL_MAX_RENDERBUFFER_SIZE = tonumber(constants.iMAX_RENDERBUFFER_SIZE)
	Graphics.GL_MAX_SAMPLE_MASK_WORDS = tonumber(constants.iMAX_SAMPLE_MASK_WORDS)
	Graphics.GL_MAX_SERVER_WAIT_TIMEOUT = tonumber(constants.iMAX_SERVER_WAIT_TIMEOUT)
	Graphics.GL_MAX_SHADER_STORAGE_BUFFER_BINDINGS = tonumber(constants.iMAX_SHADER_STORAGE_BUFFER_BINDINGS)
	Graphics.GL_MAX_TESS_CONTROL_ATOMIC_COUNTERS = tonumber(constants.iMAX_TESS_CONTROL_ATOMIC_COUNTERS)
	Graphics.GL_MAX_TESS_EVALUATION_ATOMIC_COUNTERS = tonumber(constants.iMAX_TESS_EVALUATION_ATOMIC_COUNTERS)
	Graphics.GL_MAX_TESS_CONTROL_SHADER_STORAGE_BLOCKS = tonumber(constants.iMAX_TESS_CONTROL_SHADER_STORAGE_BLOCKS)
	Graphics.GL_MAX_TESS_EVALUATION_SHADER_STORAGE_BLOCKS = tonumber(constants.iMAX_TESS_EVALUATION_SHADER_STORAGE_BLOCKS)
	Graphics.GL_MAX_TEXTURE_BUFFER_SIZE = tonumber(constants.iMAX_TEXTURE_BUFFER_SIZE)
	Graphics.GL_MAX_TEXTURE_IMAGE_UNITS = tonumber(constants.iMAX_TEXTURE_IMAGE_UNITS)
	Graphics.GL_MAX_TEXTURE_LOD_BIAS = tonumber(constants.iMAX_TEXTURE_LOD_BIAS)
	Graphics.GL_MAX_TEXTURE_SIZE = tonumber(constants.iMAX_TEXTURE_SIZE)
	Graphics.GL_MAX_UNIFORM_BUFFER_BINDINGS = tonumber(constants.iMAX_UNIFORM_BUFFER_BINDINGS)
	Graphics.GL_MAX_UNIFORM_BLOCK_SIZE = tonumber(constants.iMAX_UNIFORM_BLOCK_SIZE)
	Graphics.GL_MAX_UNIFORM_LOCATIONS = tonumber(constants.iMAX_UNIFORM_LOCATIONS)
	Graphics.GL_MAX_VARYING_COMPONENTS = tonumber(constants.iMAX_VARYING_COMPONENTS)
	Graphics.GL_MAX_VARYING_VECTORS = tonumber(constants.iMAX_VARYING_VECTORS)
	Graphics.GL_MAX_VARYING_FLOATS = tonumber(constants.iMAX_VARYING_FLOATS)
	Graphics.GL_MAX_VERTEX_ATOMIC_COUNTERS = tonumber(constants.iMAX_VERTEX_ATOMIC_COUNTERS)
	Graphics.GL_MAX_VERTEX_ATTRIBS = tonumber(constants.iMAX_VERTEX_ATTRIBS)
	Graphics.GL_MAX_VERTEX_SHADER_STORAGE_BLOCKS = tonumber(constants.iMAX_VERTEX_SHADER_STORAGE_BLOCKS)
	Graphics.GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS = tonumber(constants.iMAX_VERTEX_TEXTURE_IMAGE_UNITS)
	Graphics.GL_MAX_VERTEX_UNIFORM_COMPONENTS = tonumber(constants.iMAX_VERTEX_UNIFORM_COMPONENTS)
	Graphics.GL_MAX_VERTEX_UNIFORM_VECTORS = tonumber(constants.iMAX_VERTEX_UNIFORM_VECTORS)
	Graphics.GL_MAX_VERTEX_OUTPUT_COMPONENTS = tonumber(constants.iMAX_VERTEX_OUTPUT_COMPONENTS)
	Graphics.GL_MAX_VERTEX_UNIFORM_BLOCKS = tonumber(constants.iMAX_VERTEX_UNIFORM_BLOCKS)
	Graphics.GL_MAX_VIEWPORT_DIMS = tonumber(constants.iMAX_VIEWPORT_DIMS)
	Graphics.GL_MAX_VIEWPORTS = tonumber(constants.iMAX_VIEWPORTS)
	Graphics.GL_MAX_VERTEX_ATTRIB_RELATIVE_OFFSET = tonumber(constants.iMAX_VERTEX_ATTRIB_RELATIVE_OFFSET)
	Graphics.GL_MAX_VERTEX_ATTRIB_BINDINGS = tonumber(constants.iMAX_VERTEX_ATTRIB_BINDINGS)
	Graphics.GL_MAX_ELEMENT_INDEX = tonumber(constants.iMAX_ELEMENT_INDEX)
end

---------
-- NYI --
---------

function Graphics.loadAnimatedImage()
	error("NYI")
end

-----------------------
-- Framebuffer Stuff --
-----------------------

function Graphics.setFramebufferSize(width,height)
    return LunaDLL.FFI_GraphicsSetMainFramebufferSize(width,height)
end

----------------------------
-- Assign to global table --
----------------------------
_G.Graphics = Graphics
for k, v in pairs(Text) do
	_G.Text[k] = v
end
for k, v in pairs(Globals) do
	_G[k] = v
end

-------------------------------------
-- Return the "Graphics" namespace --
-------------------------------------
return Graphics
