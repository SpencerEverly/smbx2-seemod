local mem = mem
local math_floor = math.floor
local math_ceil = math.ceil
local ffi_utils = require("ffi_utils")

----------------------
-- MEMORY ADDRESSES --
----------------------
local GM_CAMERA_ADDR = mem(0x00B25124, FIELD_DWORD)
local GM_CAMERA_X = mem(0x00B2B984, FIELD_DWORD)
local GM_CAMERA_Y = mem(0x00B2B9A0, FIELD_DWORD)

-----------------------------
-- CONVERSIONS AND GETTERS --
-----------------------------
local function cameraGetIdx(cam)
	return cam._idx
end

local function cameraGetIsValid(cam)
	local idx = cam._idx

	if (idx >= 1) and (idx <= 2) then
		return true
	end

	return false
end

local function cameraGetX(cam)
	return -readmem(GM_CAMERA_X + 0x08*cam._idx, FIELD_DFLOAT)
end

local function cameraGetY(cam)
	return -readmem(GM_CAMERA_Y + 0x08*cam._idx, FIELD_DFLOAT)
end

local function round(val)
	if (val >= 0) then
		return math_floor(val + 0.5)
	else
		return math_ceil(val - 0.5)
	end
end

local function cameraSetX(cam, val)
	writemem(GM_CAMERA_X + 0x08*cam._idx, FIELD_DFLOAT, -round(val))
end

local function cameraSetY(cam, val)
	writemem(GM_CAMERA_Y + 0x08*cam._idx, FIELD_DFLOAT, -round(val))
end

local function cameraGetBounds(cam)
	local r = {}
	r.left = -readmem(GM_CAMERA_X + 0x08*cam._idx, FIELD_DFLOAT)
	r.top = -readmem(GM_CAMERA_Y + 0x08*cam._idx, FIELD_DFLOAT)
	r.right = r.left + readmem(GM_CAMERA_ADDR + cam._idx*0x38 + 0x10, FIELD_DFLOAT)
	r.bottom = r.top + readmem(GM_CAMERA_ADDR + cam._idx*0x38 + 0x18, FIELD_DFLOAT)
	return r
end

------------------------
-- FIELD DECLARATIONS --
------------------------
local CameraFields = {
	idx     = {get=cameraGetIdx, readonly=true, alwaysValid=true},
	isValid = {get=cameraGetIsValid, readonly=true, alwaysValid=true},

	x       = {get=cameraGetX, set=cameraSetX},
	y       = {get=cameraGetY, set=cameraSetY},

	renderX = {0x00, FIELD_DFLOAT},
	renderY = {0x08, FIELD_DFLOAT},
	width   = {0x10, FIELD_DFLOAT},
	height  = {0x18, FIELD_DFLOAT},
	bounds  = {get=cameraGetBounds, readonly=true},
	isSplit = {0x20, FIELD_BOOL}
}

-----------------------
-- CLASS DECLARATION --
-----------------------
local Camera = {}
local CameraMT = ffi_utils.implementClassMT("Camera", Camera, CameraFields, cameraGetIsValid)
local CameraCache = {}

-- Constructor
setmetatable(Camera, {__call = function(Camera, idx)
	if CameraCache[idx] then
		return CameraCache[idx]
	end

	local cam = {_idx = idx, _ptr = GM_CAMERA_ADDR + idx*0x38}
	setmetatable(cam, CameraMT)
	CameraCache[idx] = cam
	return cam
end})

-------------------------
-- METHOD DECLARATIONS --
-------------------------

-- 'mem' implementation
function Camera:mem(offset, dtype, val)
	if not cameraGetIsValid(self) then
		error("Invalid Camera object")
	end

	return mem(self._ptr + offset, dtype, val)
end

--------------------
-- STATIC METHODS --
--------------------
local camera, camera2 = Camera(1), Camera(2)

function Camera.get()
	return {camera, camera2}
end

---------------------------
-- SET GLOBAL AND RETURN --
---------------------------
_G.Camera = Camera
_G.camera = camera
_G.camera2 = camera2
return Camera
