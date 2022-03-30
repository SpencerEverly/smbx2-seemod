--- Image drawing and vertex buffer library to simplify certain common drawing problems (such as rotating images).
-- @module imagic

local vectr = require("vectr");

local imagic = {}

--*************--
--** DEFINES **--
--*************--

--- Constants.
--
-- @section Constants

--- Primitive object types, used when creating imagic vertex buffers.
-- @field TYPE_BOX Rectangular objects.
-- @field TYPE_CIRCLE Triangular objects.
-- @field TYPE_TRI Circular objects.
-- @field TYPE_POLY Simple polygonal objects.
-- @field TYPE_BOXBORDER Hollow rectangular object borders.
-- @field TYPE_CIRCLEBORDER Hollow circular object borders.
-- @table Primitive

imagic.TYPE_BOX = 1;
imagic.TYPE_CIRCLE = 2;
imagic.TYPE_TRI = 3;
imagic.TYPE_POLY = 4;

imagic.TYPE_BOXBORDER = 5;
imagic.TYPE_CIRCLEBORDER = 6;

--- Texture fill types, used when creating imagic vertex buffers to determine how to position the texture.
-- @field TEX_FILL Stretch the texture to fit the given object.
-- @field TEX_PLACE Keep the texture's native size, and position it regardless of the size of the given object.
-- @table FillType

imagic.TEX_FILL = 1;
imagic.TEX_PLACE = 2;

--- Alignment constants, used to determine the pivot points of objects and textures.
-- @field ALIGN_LEFT Align to the left-centre side. (aliases: `ALIGN_CENTERLEFT`, `ALIGN_CENTRELEFT`, `ALIGN_MIDDLELEFT`)
-- @field ALIGN_CENTER Align to the centre. (aliases: `ALIGN_CENTRE`, `ALIGN_MIDDLE`)
-- @field ALIGN_RIGHT Align to the right-centre side. (aliases: `ALIGN_CENTERRIGHT`, `ALIGN_CENTRERIGHT`, `ALIGN_MIDDLERIGHT`)
-- @field ALIGN_TOP Align to the top-centre side. (aliases: `ALIGN_TOPCENTER`, `ALIGN_TOPCENTRE`, `ALIGN_TOPMIDDLE`)
-- @field ALIGN_BOTTOM Align to the bottom-centre side. (aliases: `ALIGN_BOTTOMCENTER`, `ALIGN_BOTTOMCENTRE`, `ALIGN_BOTTOMMIDDLE`)
-- @field ALIGN_TOPLEFT Align to the top-left corner.
-- @field ALIGN_TOPRIGHT Align to the top-right corner.
-- @field ALIGN_BOTTOMLEFT Align to the bottom-left corner.
-- @field ALIGN_BOTTOMRIGHT Align to the bottom-right corner.
-- @table Alignment

imagic.ALIGN_LEFT = 1;
imagic.ALIGN_CENTRE = 2;
imagic.ALIGN_CENTER = imagic.ALIGN_CENTRE;
imagic.ALIGN_MIDDLE = imagic.ALIGN_CENTRE;
imagic.ALIGN_RIGHT = 3;
imagic.ALIGN_TOP = 4;
imagic.ALIGN_BOTTOM = 5;

imagic.ALIGN_TOPLEFT = 6;
imagic.ALIGN_TOPCENTRE = imagic.ALIGN_TOP;
imagic.ALIGN_TOPCENTER = imagic.ALIGN_TOPCENTRE;
imagic.ALIGN_TOPMIDDLE = imagic.ALIGN_TOPCENTRE;
imagic.ALIGN_TOPRIGHT = 7;

imagic.ALIGN_CENTRELEFT = imagic.ALIGN_LEFT;
imagic.ALIGN_CENTRERIGHT = imagic.ALIGN_RIGHT;
imagic.ALIGN_CENTERLEFT = imagic.ALIGN_CENTRELEFT;
imagic.ALIGN_MIDDLELEFT = imagic.ALIGN_CENTRELEFT;
imagic.ALIGN_CENTERRIGHT = imagic.ALIGN_CENTRERIGHT;
imagic.ALIGN_MIDDLERIGHT = imagic.ALIGN_CENTRERIGHT;

imagic.ALIGN_BOTTOMLEFT = 8;
imagic.ALIGN_BOTTOMCENTRE = imagic.ALIGN_BOTTOM;
imagic.ALIGN_BOTTOMCENTER = imagic.ALIGN_BOTTOMCENTRE;
imagic.ALIGN_BOTTOMMIDDLE = imagic.ALIGN_BOTTOMCENTRE;
imagic.ALIGN_BOTTOMRIGHT = 9;


--- Constant values.
-- @field DEG2RAD Multiply by this to convert degrees to radians.
-- @field RAD2DEG Multiply by this to convert radians to degrees.
-- @table Constants

imagic.DEG2RAD = 0.01745329251;
imagic.RAD2DEG = 57.2957795131;

--**************************--
--** CONVERSION FUNCTIONS **--
--**************************--

local function convertCol(hex)
	if(type(hex) == "Color") then
		return hex;
	else
		return Color.fromHexRGBA(hex);
	end
end

--***************************--
--** DRAW OBJECT FUNCTIONS **--
--***************************--

--- A vertex buffer object.
-- @type Object

---
-- @tparam number x The x coordinate of the object.
-- @tparam number y The y coordinate of the object.
-- @tparam Texture texture The texture assigned to the object.
-- @tparam bool scene Whether the object exists in screen space or world space.
-- @tparam number rotation The clockwise rotation of the object in degrees.
-- @tparam Vector2 position The position of the object relative to its pivot.
-- @tparam Vector2 size The scale of the object, as a multiplier of its original size.
-- @tparam number texrotation The clockwise rotation of the texture in degrees.
-- @tparam Vector2 texposition The position of the texture relative to the object pivot.
-- @tparam Vector2 texsize The scale of the texture, as a multiplier of its original size.
-- @tparam number texoffsetX Offset of the texture in the x direction (in UV space).
-- @tparam number texoffsetY Offset of the texture in the y direction (in UV space).
-- @tparam table verts A list of the vertices stored in the vertex buffer object.
-- @tparam table uvs A list of the UV coordinates stored in the vertex buffer object.
-- @tparam table vertexColors A list of the vertex colors stored in the vertex buffer object (See `Graphics.glDraw`).
-- @tparam table outlineverts A list of the vertices for the outline of the object.
-- @tparam Object border The vertex buffer storing the objects border.
-- @table _

local Object = {}
Object.__index = function(tbl, key)
	if(Object[key]) then
		return Object[key];
	elseif(key == "rotation") then
		return tbl.__rot;
	elseif(key == "position") then
		return vector.v2(tbl.__pos);
	elseif(key == "size") then
		return vector.v2(tbl.__scl);	
	elseif(key == "texrotation") then
		return tbl.__texrot;
	elseif(key == "texposition") then
		return vector.v2(tbl.__texpos);
	elseif(key == "texsize") then
		return vector.v2(tbl.__texscl);	
	end
end

Object.__newindex = function(tbl,key,val)
	if(key == "rotation") then
		Object.rotate(tbl, val-tbl.__rot);
	elseif(key == "position") then
		Object.translate(tbl, val.x-tbl.__pos.x, val.y-tbl.__pos.y);
	elseif(key == "size") then
		Object.scale(tbl, val.x/tbl.__scl.x, val.y/tbl.__scl.y);
	elseif(key == "texrotation") then
		Object.rotateTexture(tbl, val-tbl.__texrot);
	elseif(key == "texposition") then
		Object.translateTexture(tbl, val.x-tbl.__texpos.x, val.y-tbl.__texpos.y);
	elseif(key == "texsize") then
		Object.scaleTexture(tbl, val.x/tbl.__texscl.x, val.y/tbl.__texscl.y);
	else
		rawset(tbl, key, val);
	end
end

--- Draws the object to the screen.
-- @function Object:draw
-- @param args
-- @tparam[opt=white] Color args.color A color tint when drawing the object. (aliases: `colour`)
-- @tparam[opt=white] Color args.bordercolor A color tint to the border when drawing the object if a border exists. (aliases: `bordercolour`, `bordercol`)
-- @tparam[opt=true] bool args.outline Whether to draw the object's outline or not, if one exists.
-- @tparam[opt=white] Color args.outlinecolor A color tint to the outline when drawing the object if outlines are enabled. (aliases: `outlinecolour`, `outlinecol`)
-- @tparam[opt] number args.priority The render priority to draw the object at. (aliases: `z`)
-- @tparam[opt] Shader args.shader A shader to apply when drawing the object.
-- @tparam[opt] table args.uniforms A table of uniform variables to apply when drawing the object with a shader.
-- @tparam[opt] table args.attributes A table of attribute variables to apply when drawing the object with a shader.
-- @tparam[opt] Shader args.bordershader A shader to apply to the border when drawing the object if a border exists.
-- @tparam[opt] table args.borderuniforms A table of uniform variables to apply to the border when drawing the object with a shader if a border exists.
-- @tparam[opt] table args.borderattributes A table of attribute variables to apply to the border when drawing the object with a shader if a border exists.
-- @tparam[opt] CaptureBuffer args.target A render target to draw the object to.
-- @usage myObject:Draw{color = Color.red, outline = false, priority = -50}
-- @usage myObject:Draw{shader = myShader, uniforms = {myValue = 10}}

--- Draws the object to the screen.
-- @tparam[opt] number priority The render priority to draw the object at.
-- @tparam[opt=white] Color color A color tint when drawing the object.
-- @tparam[opt] CaptureBuffer target A render target to draw the object to.
-- @usage myObject:draw(-50, Color.red)
function Object:draw(priority, colour, target)
	local v = {}
	for i = 1,#self.verts,2 do
		v[i] = self.verts[i] + self.x;
		v[i+1] = self.verts[i+1] + self.y;
	end
	local t = nil;
	if(self.uvs ~= nil) then
		t = {};
		for i = 1,#self.uvs,2 do
			t[i] = self.uvs[i] + self.texoffsetX;
			t[i+1] = self.uvs[i+1] + self.texoffsetY;
		end
	end
	local bordercol = 0xFFFFFFFF;
	local outline = true;
	local outlinecol = 0xFFFFFFFF;
	local shader = nil;
	local uniforms = nil;
	local attributes = nil;
	local bordershader = nil;
	local borderuniforms = nil;
	local borderattributes = nil;
	
	if(type(priority) == "table") then	
		bordercol = priority.bordercolour or priority.bordercolor or priority.bordercol or bordercol;
		colour = priority.colour or priority.color or colour;
		
		if(priority.outline ~= nil) then
			outline = priority.outline;
		end
		
		outlinecol = priority.outlinecolour or priority.outlinecolor or priority.outlinecol or outlinecol;
		
		shader = priority.shader;
		uniforms = priority.uniforms;
		attributes = priority.attributes;
		bordershader = priority.bordershader;
		borderuniforms = priority.borderuniforms;
		borderattributes = priority.borderattributes;
		target = priority.target;
		
		priority = priority.priority or priority.z;
	end		
	
	if(colour ~= nil and type(colour) == "number") then
		colour = convertCol(colour);
	end
	Graphics.glDraw{vertexCoords = v, textureCoords = t, vertexColors = self.vertexColors, texture = self.texture, 
					primitive = self._renderType or Graphics.GL_TRIANGLES, priority = priority, color=colour, sceneCoords = self.scene,
					shader = shader, uniforms = uniforms, attributes = attributes, target = target};
	
	if(self.border ~= nil) then
		self.border:Draw{priority = priority, colour = bordercol, shader = bordershader, uniforms = borderuniforms, attributes = borderattributes, target = target};
	end
	
	if(self.outlineverts ~= nil and outline) then
		v = {};
		for i = 1,#self.outlineverts,2 do
			v[i] = self.outlineverts[i] + self.x;
			v[i+1] = self.outlineverts[i+1] + self.y;
		end
		
		if(outlinecol ~= nil and type(outlinecol) == "number") then
			outlinecol = convertCol(outlinecol);
		end
		Graphics.glDraw{vertexCoords = v, primitive = Graphics.GL_LINE_LOOP, priority = priority, color=outlinecol, sceneCoords = self.scene, 
						shader = shader, uniforms = uniforms, attributes = attributes, target = target};
	end
end

Object.Draw = Object.draw;

--- Transforms the vertices of an object with a given matrix.
-- @function Object:transform
-- @tparam Mat2 matrix The 2D matrix to transform the vertices with.
-- @usage myObject:transform(myMatrix)

--- Transforms the vertices of an object with a given matrix.
-- @tparam Mat3 matrix The 3D matrix to transform the vertices with.
-- @usage myObject:transform(myMatrix)
function Object:transform(matrix)
	local mat3 = matrix._type == "Mat3";
	for i = 1,#self.verts,2 do
		local v;
		if(mat3) then	
			v = matrix * vectr.v3(self.verts[i],self.verts[i+1],1);
		else
			v = matrix * vectr.v2(self.verts[i],self.verts[i+1]);
		end
		self.verts[i] = v.x;
		self.verts[i+1] = v.y;
	end
	
	if(self.border ~= nil) then
		self.border:transform(matrix);
	end
end
Object.Transform = Object.transform;

--- Rotates the vertices of an object clockwise around its pivot.
-- @tparam number degrees The number of degrees to rotate the object by. Positive rotates clockwise, negative rotates anticlockwise.
-- @usage myObject:rotate(45)
function Object:rotate(degrees)
	local cs = math.cos(degrees*imagic.DEG2RAD);
	local sn = math.sin(degrees*imagic.DEG2RAD);
	self.__rot = self.__rot + degrees;
	
	for i = 1,#self.verts,2 do
		local x = self.verts[i];
		local y = self.verts[i+1];
		self.verts[i] = cs*x - sn*y;
		self.verts[i+1] = sn*x + cs*y;
	end
	
	if(self.border ~= nil) then
		self.border:rotate(degrees);
	end
	--self:Transform(vectr.mat2({cs, -sn}, {sn, cs}));
end
Object.Rotate = Object.rotate;

--- Moves the vertices of an object around its pivot. This will reposition the vertices relative to the object pivot.
-- @tparam number x
-- @tparam number y
-- @usage myObject:translate(10,10)
function Object:translate(x, y)
	self.__pos = vector.v2(self.__pos.x + x, self.__pos.y + y);
	
	for i = 1,#self.verts,2 do
		self.verts[i] = self.verts[i] + x;
		self.verts[i+1] = self.verts[i+1] + y;
	end
	
	if(self.border ~= nil) then
		self.border:translate(x,y);
	end
	--self:Transform(vectr.mat3({1,0,x}, {0,1,y}, {0,0,1}));
end
Object.Translate = Object.translate;

--- Scales the vertices of an object around its pivot, relative to its current scale (i.e. a scale of 1 will leave the vertices unchanged).
-- @tparam number x
-- @tparam number y
-- @usage myObject:scale(2,2)
function Object:scale(x, y)
	y = y or x;
	self.__scl = vector.v2(self.__scl.x * x, self.__scl.y * y);
	
	for i = 1,#self.verts,2 do
		self.verts[i] = self.verts[i]*x;
		self.verts[i+1] = self.verts[i+1]*y;
	end
	
	if(self.border ~= nil) then
		self.border:scale(x,y);
	end
	--self:Transform(vectr.mat2({x,0}, {0,y}));
end

Object.Scale = Object.scale;
Object.Resize = Object.scale;
Object.resize = Object.scale;

--- Transforms the texture coordinates of an object with a given matrix.
-- @function Object:transformTexture
-- @tparam Mat2 matrix The 2D matrix to transform the texture with.
-- @usage myObject:transformTexture(myMatrix)

--- Transforms the texture coordinates of an object with a given matrix.
-- @tparam Mat3 matrix The 3D matrix to transform the texture with.
-- @usage myObject:TransformTexture(myMatrix)
function Object:transformTexture(matrix)
	if(self.uvs == nil) then return; end
	local mat3 = matrix._type == "Mat3";
	for i = 1,#self.uvs,2 do
		local v;
		if(mat3) then
			v = matrix * vectr.v3(self.uvs[i]-0.5,self.uvs[i+1]-0.5,1);
		else
			v = matrix * vectr.v2(self.uvs[i]-0.5,self.uvs[i+1]-0.5);
		end
		self.uvs[i] = v.x+0.5;
		self.uvs[i+1] = v.y+0.5;
	end
	if(self.border ~= nil) then
		self.border:transformTexture(matrix);
	end
end
Object.TransformTexture = Object.transformTexture;

--- Rotates the texture of an object clockwise around its pivot.
-- @tparam number degrees The number of degrees to rotate the texture by. Positive rotates clockwise, negative rotates anticlockwise.
-- @usage myObject:rotateTexture(45)
function Object:rotateTexture(degrees)
	local cs = math.cos(-degrees*imagic.DEG2RAD);
	local sn = math.sin(-degrees*imagic.DEG2RAD);
	self.__texrot = self.__texrot + degrees;
	
	for i = 1,#self.uvs,2 do
		local x = self.uvs[i]-0.5;
		local y = self.uvs[i+1]-0.5;
		self.uvs[i] = cs*x - sn*y + 0.5;
		self.uvs[i+1] = sn*x + cs*y + 0.5;
	end
	
	if(self.border ~= nil) then
		self.border:rotateTexture(degrees);
	end
	
	--self:TransformTexture(vectr.mat2({cs, -sn}, {sn, cs}));
end
Object.RotateTexture = Object.rotateTexture;

--- Moves the texture of an object around its pivot. This will reposition the texture relative to the object pivot.
-- @tparam number x
-- @tparam number y
-- @usage myObject:translateTexture(10,10)
function Object:translateTexture(x, y)
	self.__texpos = vector.v2(self.__texpos.x + x, self.__texpos.y + y);
	
	for i = 1,#self.uvs,2 do
		self.uvs[i] = self.uvs[i] + x;
		self.uvs[i+1] = self.uvs[i+1] + y;
	end
	
	if(self.border ~= nil) then
		self.border:translateTexture(x,y);
	end
	--self:TransformTexture(vectr.mat3({1,0,-y}, {0,1,x}, {0,0,1}));
end

Object.TranslateTexture = Object.translateTexture;

--- Scales the texture of an object around its pivot, relative to its current scale (i.e. a scale of 1 will leave the texture unchanged).
-- @tparam number x
-- @tparam number y
-- @usage myObject:scaleTexture(2,2)
function Object:scaleTexture(x, y)
	y = y or x;
	self.__texscl = vector.v2(self.__texscl.x * x, self.__texscl.y * y);
	
	for i = 1,#self.uvs,2 do
		self.uvs[i] = (self.uvs[i]-0.5)*x + 0.5;
		self.uvs[i+1] = (self.uvs[i+1]-0.5)*y + 0.5;
	end
	
	if(self.border ~= nil) then
		self.border:scaleTexture(x,y);
	end
	
	--self:TransformTexture(vectr.mat2({1/x,0}, {0,1/y}));
end

Object.ScaleTexture = Object.scaleTexture;

--**************--
--** WRAPPERS **--
--**************--

--- A vertex buffer wrapper object. This has all the properties of a vertex buffer @{Object}, but retains some information about its construction, allowing initial parameters to be modified after construction.
-- @type Wrapper

--- Wrapper objects contain all the same fields as vertex buffer @{Object}s, and may contain the following, which will be used to construct a new object when the `Reconstruct` function is called:
-- @tparam number width The width of the object.
-- @tparam number height The height of the object.
-- @tparam number radius The radius of the object.
-- @tparam Primitive primitive The type of the object.
-- @tparam Alignment align How the object should be aligned to its pivot coordinate.
-- @tparam Alignment texalign How the texture should be aligned to its pivot coordinate (ignored unless using `TEX_PLACE` fill type).
-- @tparam FillType filltype How the texture should be applied to the object.
-- @tparam bool outline Whether or not to create an outline for this object.
-- @tparam[opt] number/BorderLayout borderwidth How wide the border on this object should be. If not supplied, no border will be created.
-- @tparam[opt] Texture/BorderImage bordertexture The texture to apply to the objects border. (aliases: `bordertex`)
-- @table _

--- Reconstucts the object from its base parameters. Until this function is called, changes to the initial parameters will have no effect on the object.
-- @function Wrapper:reconstruct
-- @usage myWrapper.width = 10
-- myWrapper:reconstruct()



local Wrapper = {};
local Wrapper_MT = {};

-- Reconstructs the internal imagic object --
local function Reconstruct(obj)
	rawset(obj,"__internal",imagic.Create(rawget(obj,"__rawdata")));
	rawset(obj,"__dirty",false);
end

-- Creates a wrapper functions that first checks if the object needs reconstructing (and does so if necessary) before drawing the object --
local function FuncWrapper(funcName)
	return function(obj, ...)
		if(rawget(obj,"__dirty")) then
			obj:Reconstruct();
		end
		rawget(obj,"__internal")[funcName](rawget(obj,"__internal"), ...);
	end
end

local wrappers = {};

-- Accessor table for wrapper objects --
Wrapper_MT.__index = function(tbl,key)
	if(key == "reconstruct" or key == "Reconstruct") then
		return Reconstruct;
	elseif(type(rawget(tbl,"__internal")[key]) == "function") then
		if(wrappers[key] == nil) then
			wrappers[key] = FuncWrapper(key);
		end
		return wrappers[key];
	elseif(rawget(tbl,"__internal")[key] ~= nil) then
		return rawget(tbl,"__internal")[key];
	else
		return rawget(tbl,"__rawdata")[key];
	end
end

-- Mutator table for wrapper objects --
Wrapper_MT.__newindex = function(tbl,key,val)

	local int = rawget(tbl,"__internal");
	if(int[key] ~= nil) then
		int[key] = val;
	end
	
	local dat = rawget(tbl,"__rawdata");
	if(key ~= "primitive" and val ~= dat[key]) then
		dat[key] = val;
		rawset(tbl,"__dirty",true);
	end
	
end

--- Functions.
-- @section Functions

--- Creates a wrapper object with the given primitive.
-- @tparam Primitive primitive The primitive type to construct (e.g. `TYPE_BOX`).
-- @tparam table args The argument table. See `imagic.Create`.
-- @return @{Wrapper}
-- @see Create
-- @see Box
-- @see Circle
-- @see Tri
-- @see Poly
-- @usage imagic.Wrapper(imagic.TYPE_BOX, {x=0, y=0, width=10, height=10})
function imagic.Wrapper(primitive, args)
	local t = {};
	t.__rawdata = {};
	for k,v in pairs(args) do
		t.__rawdata[k] = v;
	end
	t.__rawdata.primitive = primitive;
	setmetatable(t,Wrapper_MT);
	t:Reconstruct();
	return t;
end

-- Creates a Box wrapper object
-- This behaves like a box-type drawable object, but arguments are accessible as mutable fields
-- Required arguments are:
-- x, y, width, height
--
-- Optional named arguments are: 				
-- texture, scene, align, texalign, texrotation, filltype, texoffsetX, texoffsetY, outline, borderwidth, bordertexture, bordertex
--

--- Creates a Box wrapper object. (Equivalent to `imagic.Wrapper(imagic.TYPE_BOX, args)`)
-- @tparam table args The argument table.
-- @tparam number args.x The x coordinate of the object.
-- @tparam number args.y The y coordinate of the object.
-- @tparam number args.width The width of the object.
-- @tparam number args.height The height of the object.
-- @tparam[opt] Texture args.texture The texture to apply to the object.
-- @tparam[opt] bool args.scene Whether the object should be drawn in screen space or world space. (aliases: `sceneCoords`)
-- @tparam[opt=ALIGN_TOPLEFT] Alignment args.align How the object should be aligned to its pivot coordinate.
-- @tparam[opt=ALIGN_CENTER] Alignment args.texalign How the texture should be aligned to its pivot coordinate (ignored unless using `TEX_PLACE` fill type).
-- @tparam[opt] number args.texrotation The clockwise rotation of the texture in degrees.
-- @tparam[opt=TEX_FILL] FillType args.filltype How the texture should be applied to the object.
-- @tparam[opt] number args.texoffsetX Offset to apply to the texture in the x direction (in UV space).
-- @tparam[opt] number args.texoffsetY Offset to apply to the texture in the y direction (in UV space).
-- @tparam[opt] bool args.outline Whether or not to create an outline for this object.
-- @tparam[opt] number/BorderLayout args.borderwidth How wide the border on this object should be. If not supplied, no border will be created.
-- @tparam[opt] Texture/BorderImage args.bordertexture The texture to apply to the objects border. (aliases: `bordertex`)
-- @tparam[opt] table args.vertColors A list of Color objects. Must be of equal length to the number of vertices in the object.
-- @return @{Wrapper}
-- @see Create
-- @see Wrapper
-- @usage imagic.Box{x=0, y=0, width=10, height=10}
function imagic.Box(args)
	return imagic.Wrapper(imagic.TYPE_BOX, args);
end

-- Creates a Circle wrapper object
-- This behaves like a circle-type drawable object, but arguments are accessible as mutable fields
-- Required arguments are:
-- x, y, radius
--
-- Optional named arguments are: 				
-- texture, scene, align, texalign, texrotation, filltype, texoffsetX, texoffsetY, outline, borderwidth, bordertexture, bordertex, density

--- Creates a Circle wrapper object. (Equivalent to `imagic.Wrapper(imagic.TYPE_CIRCLE, args)`)
-- @tparam table args The argument table.
-- @tparam number args.x The x coordinate of the object.
-- @tparam number args.y The y coordinate of the object.
-- @tparam number args.radius The radius of the object.
-- @tparam[opt] Texture args.texture The texture to apply to the object.
-- @tparam[opt] bool args.scene Whether the object should be drawn in screen space or world space. (aliases: `sceneCoords`)
-- @tparam[opt=ALIGN_CENTER] Alignment args.align How the object should be aligned to its pivot coordinate.
-- @tparam[opt=ALIGN_CENTER] Alignment args.texalign How the texture should be aligned to its pivot coordinate (ignored unless using `TEX_PLACE` fill type).
-- @tparam[opt] number args.texrotation The clockwise rotation of the texture in degrees.
-- @tparam[opt=TEX_FILL] FillType args.filltype How the texture should be applied to the object.
-- @tparam[opt] number args.texoffsetX Offset to apply to the texture in the x direction (in UV space).
-- @tparam[opt] number args.texoffsetY Offset to apply to the texture in the y direction (in UV space).
-- @tparam[opt] bool args.outline Whether or not to create an outline for this object.
-- @tparam[opt] number/BorderLayout args.borderwidth How wide the border on this object should be. If not supplied, no border will be created.
-- @tparam[opt] Texture/BorderImage args.bordertexture The texture to apply to the objects border. (aliases: `bordertex`)
-- @return @{Wrapper}
-- @see Create
-- @see Wrapper
-- @usage imagic.Circle{x=0, y=0, radius=5}
function imagic.Circle(args)
	return imagic.Wrapper(imagic.TYPE_CIRCLE, args);
end

-- Creates a Tri wrapper object
-- This behaves like a tri-type drawable object, but arguments are accessible as mutable fields
-- Required arguments are:
-- x, y, verts
--
-- Optional named arguments are: 				
-- texture, scene, align, texalign, texrotation, filltype, texoffsetX, texoffsetY, outline
--

--- Creates a Triangle wrapper object. (Equivalent to `imagic.Wrapper(imagic.TYPE_TRI, args)`)
-- @tparam table args The argument table.
-- @tparam number args.x The x coordinate of the object.
-- @tparam number args.y The y coordinate of the object.
-- @tparam table args.verts A list of vector vertex positions.
-- @tparam[opt] Texture args.texture The texture to apply to the object.
-- @tparam[opt] bool args.scene Whether the object should be drawn in screen space or world space. (aliases: `sceneCoords`)
-- @tparam[opt=ALIGN_TOPLEFT] Alignment args.align How the object should be aligned to its pivot coordinate.
-- @tparam[opt=ALIGN_CENTER] Alignment args.texalign How the texture should be aligned to its pivot coordinate (ignored unless using `TEX_PLACE` fill type).
-- @tparam[opt] number args.texrotation The clockwise rotation of the texture in degrees.
-- @tparam[opt=TEX_FILL] FillType args.filltype How the texture should be applied to the object.
-- @tparam[opt] number args.texoffsetX Offset to apply to the texture in the x direction (in UV space).
-- @tparam[opt] number args.texoffsetY Offset to apply to the texture in the y direction (in UV space).
-- @tparam[opt] bool args.outline Whether or not to create an outline for this object.
-- @tparam[opt] table args.vertColors A list of Color objects. Must be of equal length to the number of vertices in the object.
-- @return @{Wrapper}
-- @see Create
-- @see Wrapper
-- @usage imagic.Tri{x=0, y=0, {vector.v2(0,0), vector.v2(10,-10), vector.v2(10,10)}}
function imagic.Tri(args)
	return imagic.Wrapper(imagic.TYPE_TRI, args);
end

-- Creates a Poly wrapper object
-- This behaves like a poly-type drawable object, but arguments are accessible as mutable fields
-- Required arguments are:
-- x, y, verts
--
-- Optional named arguments are: 				
-- texture, scene, align, texalign, texrotation, filltype, texoffsetX, texoffsetY, outline
--

--- Creates a Polygon wrapper object. (Equivalent to `imagic.Wrapper(imagic.TYPE_POLY, args)`)
-- @tparam table args The argument table.
-- @tparam number args.x The x coordinate of the object.
-- @tparam number args.y The y coordinate of the object.
-- @tparam table args.verts A list of vector vertex positions.
-- @tparam[opt] Texture args.texture The texture to apply to the object.
-- @tparam[opt] bool args.scene Whether the object should be drawn in screen space or world space. (aliases: `sceneCoords`)
-- @tparam[opt=ALIGN_TOPLEFT] Alignment args.align How the object should be aligned to its pivot coordinate.
-- @tparam[opt=ALIGN_CENTER] Alignment args.texalign How the texture should be aligned to its pivot coordinate (ignored unless using `TEX_PLACE` fill type).
-- @tparam[opt] number args.texrotation The clockwise rotation of the texture in degrees.
-- @tparam[opt=TEX_FILL] FillType args.filltype How the texture should be applied to the object.
-- @tparam[opt] number args.texoffsetX Offset to apply to the texture in the x direction (in UV space).
-- @tparam[opt] number args.texoffsetY Offset to apply to the texture in the y direction (in UV space).
-- @tparam[opt] bool args.outline Whether or not to create an outline for this object.
-- @tparam[opt] table args.vertColors A list of Color objects. Must be of equal length to the number of vertices in the object.
-- @return @{Wrapper}
-- @see Create
-- @see Wrapper
-- @usage imagic.Poly{x=0, y=0, {vector.v2(0,5), vector.v2(0,-5), vector.v2(10,-10), vector.v2(10,10)}}
function imagic.Poly(args)
	return imagic.Wrapper(imagic.TYPE_POLY, args);
end


--**********************--
--** HELPER FUNCTIONS **--
--**********************--

-- Gets an offset based on an alignment method --
local function getAlignOffset(align, width, height)
	local xoffset = 0;
	local yoffset = 0;
	
	if(align == imagic.ALIGN_TOPLEFT) then return 0,0 end;
	
	
	if(align == imagic.ALIGN_TOPRIGHT or align == imagic.ALIGN_RIGHT or align == imagic.ALIGN_BOTTOMRIGHT) then
		xoffset = width;
	elseif(align == imagic.ALIGN_TOPCENTRE or align == imagic.ALIGN_CENTRE or align == imagic.ALIGN_BOTTOMCENTRE) then
		xoffset = width*0.5;
	end
	
	if(align == imagic.ALIGN_BOTTOMLEFT or align == imagic.ALIGN_BOTTOM or align == imagic.ALIGN_BOTTOMRIGHT) then
		yoffset = height;
	elseif(align == imagic.ALIGN_CENTRELEFT or align == imagic.ALIGN_CENTRE or align == imagic.ALIGN_CENTRERIGHT) then
		yoffset = height*0.5;
	end
	
	return xoffset,yoffset;
end

-- Re-aligns vertices based on an alignment method --
local function alignVerts(vs, width, height, align, default)
	if(vs == nil) then return; end
	local xoffset, yoffset = getAlignOffset(default or imagic.ALIGN_TOPLEFT, width, height);
	
	if(align == imagic.ALIGN_TOPRIGHT or align == imagic.ALIGN_RIGHT or align == imagic.ALIGN_BOTTOMRIGHT) then
		xoffset = xoffset-width;
	elseif(align == imagic.ALIGN_TOPCENTRE or align == imagic.ALIGN_CENTRE or align == imagic.ALIGN_BOTTOMCENTRE) then
		xoffset = xoffset-width*0.5;
	end
	
	if(align == imagic.ALIGN_BOTTOMLEFT or align == imagic.ALIGN_BOTTOM or align == imagic.ALIGN_BOTTOMRIGHT) then
		yoffset = yoffset-height;
	elseif(align == imagic.ALIGN_CENTRELEFT or align == imagic.ALIGN_CENTRE or align == imagic.ALIGN_CENTRERIGHT) then
		yoffset = yoffset-height*0.5;
	end
	
	for i = 1,#vs,2 do
		vs[i] = vs[i] + xoffset;
		vs[i+1] = vs[i+1] + yoffset;
	end
end

-- Gets an offset for UVs based on an alignment method --
local function getUVAlignOffset(align, width, height)
	local xoffset = 0;
	local yoffset = 0;
	
	if(align == imagic.ALIGN_TOPLEFT) then return 0,0 end;
	
	
	if(align == imagic.ALIGN_TOPRIGHT or align == imagic.ALIGN_RIGHT or align == imagic.ALIGN_BOTTOMRIGHT) then
		xoffset = width-1;
	elseif(align == imagic.ALIGN_TOPCENTRE or align == imagic.ALIGN_CENTRE or align == imagic.ALIGN_BOTTOMCENTRE) then
		xoffset = (width-1)*0.5;
	end
	
	if(align == imagic.ALIGN_BOTTOMLEFT or align == imagic.ALIGN_BOTTOM or align == imagic.ALIGN_BOTTOMRIGHT) then
		yoffset = height-1;
	elseif(align == imagic.ALIGN_CENTRELEFT or align == imagic.ALIGN_CENTRE or align == imagic.ALIGN_CENTRERIGHT) then
		yoffset = (height-1)*0.5;
	end
	
	return xoffset,yoffset;
end

-- Re-aligns UVs based on an alignment method --
local function alignUVs(vs, width, height, align, default)
	if(vs == nil) then return; end
	local xoffset, yoffset = getUVAlignOffset(default or imagic.ALIGN_TOPLEFT, width, height);
	
	if(align == imagic.ALIGN_TOPRIGHT or align == imagic.ALIGN_RIGHT or align == imagic.ALIGN_BOTTOMRIGHT) then
		xoffset = xoffset+(1-width);
	elseif(align == imagic.ALIGN_TOPCENTRE or align == imagic.ALIGN_CENTRE or align == imagic.ALIGN_BOTTOMCENTRE) then
		xoffset = xoffset+(1-width)*0.5;
	end
	
	if(align == imagic.ALIGN_BOTTOMLEFT or align == imagic.ALIGN_BOTTOM or align == imagic.ALIGN_BOTTOMRIGHT) then
		yoffset = yoffset+(1-height);
	elseif(align == imagic.ALIGN_CENTRELEFT or align == imagic.ALIGN_CENTRE or align == imagic.ALIGN_CENTRERIGHT) then
		yoffset = yoffset+(1-height)*0.5;
	end
	
	for i = 1,#vs,2 do
		vs[i] = vs[i] + xoffset;
		vs[i+1] = vs[i+1] + yoffset;
	end
end

-- Adjusts vertices to account for borders --
local function adjustVariableVerts(obj, adjLeft, adjTop, adjRight, adjBottom, alignment)
	if(adjustment ~= 0) then
		local ax,ay = getAlignOffset(alignment, 1, 1);
		local xs,ys = 2*(0.5-ax), 2*(0.5-ay);
		if(xs < 0) then
			xs = xs * adjRight;
		else
			xs = xs * adjLeft;
		end
		if(ys < 0) then
			ys = ys * adjBottom;
		else
			ys = ys * adjTop;
		end
		obj:Translate(xs,ys);
	end
end

-- Adjusts vertices to account for borders --
local function adjustVerts(obj, adjustment, alignment)
	adjustVariableVerts(obj, adjustment, adjustment, adjustment, adjustment, alignment);
end

-- Checks if a field is nil and errors if it is --
local function nilcheck(tbl, name)
	if(tbl[name] == nil) then
		error("Field \""..name.."\" cannot be nil.",2);
	end
end

-- Used during polygon triangulation, tests which side of a line a point is on --
local function isLeft(a, p0, p1)
	return ((p0.x or p0[1]) - (a.x or a[1])) * ((p1.y or p1[2]) - (a.y or a[2])) - ((p1.x or p1[1]) - (a.x or a[1])) * ((p0.y or p0[2]) - (a.y or a[2]));
end

-- Make a vertex list for box-type borders --
local function makeVariableBoxBorderVerts(depthleft, depthtop, depthright, depthbottom, width, height)
		return 	  {0,					0,
				   depthleft,			0,
				   0,					depthtop,
				   0,					depthtop,
				   depthleft,			0,
				   depthleft,			depthtop,
				   
				   depthleft,			0,
				   width-depthright,	depthtop,
				   depthleft,			depthtop,
				   width-depthright,	depthtop,
				   depthleft,			0,
				   width-depthright,	0,
				   
				   width,				0,
				   width,				depthtop,
				   width-depthright,	0,
				   width-depthright,	0,
				   width,				depthtop,
				   width-depthright,	depthtop,
					
				   width,				depthtop,
				   width-depthright,	height-depthbottom,
				   width-depthright,	depthtop,
				   width,				depthtop,
				   width-depthright,	height-depthbottom, 
				   width,				height-depthbottom,
				   
				   width,				height,
				   width-depthright,	height,
				   width,				height-depthbottom,
				   width,				height-depthbottom,
				   width-depthright,	height,
				   width-depthright,	height-depthbottom,
				   
				   width-depthright,	height,
				   depthleft,			height-depthbottom,
				   width-depthright,	height-depthbottom,
				   depthleft,			height-depthbottom,
				   width-depthright,	height,
				   depthleft,			height,
				   
				   0,					height,
				   0,					height-depthbottom,
				   depthleft,			height,
				   depthleft,			height,
				   0,					height-depthbottom,
				   depthleft,			height-depthbottom,
				   
				   0,					height-depthbottom,
				   depthleft,			depthtop,
				   depthleft,			height-depthbottom,
				   depthleft,			depthtop,
				   0,					height-depthbottom,
				   0,					depthtop
				   }
end

-- Make a vertex list for box-type borders --
local function makeBoxBorderVerts(depth, width, height)
		return makeVariableBoxBorderVerts(depth,depth,depth,depth,width,height);
end

--*****************************--
--** BORDER LAYOUT FUNCTIONS **--
--*****************************--

-- Create a border image layout, allows custom segmentation of an image
-- Pass in place of the "bordertexture" field
-- Box-type borders will use 8 segments, circle-type borders will use the middle top segment
--
-- Required named arguments are:
-- texture
--
-- Optional named arguments are:
-- left, right, top, bottom, width


--- Create a border image layout, allowing custom segmentation of an image. Values are measured in image-space pixels.
-- Box-type borders will use 8 segments, circle-type borders will use the middle top segment. By default, the image will be segmented into thirds.
-- @tparam table args
-- @tparam Texture args.texture The segmentable texture to use.
-- @tparam[opt] number args.left The width of the left-side segment.
-- @tparam[opt] number args.right The width of the right-side segment.
-- @tparam[opt] number args.top The width of the top-side segment.
-- @tparam[opt] number args.bottom The width of the bottom-side segment.
-- @tparam[opt] number args.width A default fixed-width for any side that is not specified.
-- @return BorderImage
-- @usage local img = imagic.BorderImage{texture = myImage, width = 8, top = 4}
--imagic.Box{x = 0, y = 0, width = 10, height = 10, borderwidth = 8, bordertexture = img}
function imagic.BorderImage(args)
	nilcheck(args, "texture");
	local p = {};
	p.texture = args.texture;
	p.left = args.left or args.width or args.right or args.top or args.bottom or args.texture.width/3;
	p.right = args.right or args.width or args.left or args.top or args.bottom or args.texture.width/3;
	p.top = args.top or args.width or args.bottom or args.left or args.right or args.texture.height/3;
	p.bottom = args.bottom or args.width or args.top or args.left or args.right or args.texture.height/3;
	
	p.left = p.left/args.texture.width;
	p.right = p.right/args.texture.width;
	p.top = p.top/args.texture.height;
	p.bottom = p.bottom/args.texture.height;
	
	p.__type = "BorderImage";
	return p;
end

-- Create a physical border layout, allows variable width for box-type borders
-- Pass in place of the "borderwidth" field
--
-- Optional named arguments are:
-- left, right, top, bottom, width
--
-- At least one argument must be given

--- Create a physical border layout, allows variable width for box-type borders. At least one argument must be given.
-- @tparam table args
-- @tparam[opt] number args.left The width of the left-side segment.
-- @tparam[opt] number args.right The width of the right-side segment.
-- @tparam[opt] number args.top The width of the top-side segment.
-- @tparam[opt] number args.bottom The width of the bottom-side segment.
-- @tparam[opt] number args.width A default fixed-width for any side that is not specified.
-- @return BorderLayout
-- @usage local layout = imagic.BorderLayout{width = 8, top = 4}
--imagic.Box{x = 0, y = 0, width = 10, height = 10, borderwidth = layout}
function imagic.BorderLayout(args)
	if(args.left == nil and args.right == nil and args.top == nil and args.bottom == nil and args.width == nil) then
		error("Must define some widths for a Border Layout.", 2);
	end
	local p = {};
	p.left = args.left or args.width or args.right or args.top or args.bottom;
	p.right = args.right or args.width or args.left or args.top or args.bottom;
	p.top = args.top or args.width or args.bottom or args.left or args.right;
	p.bottom = args.bottom or args.width or args.top or args.left or args.right;
	
	p.__type = "BorderLayout";
	return p;
end

--***********************--
--** CREATION FUNCTION **--
--***********************--

-- Creates a new drawable object
-- Required arguments for all types are:
-- x, y, primitive
--
-- Optional named arguments for all types are: 				
-- texture, scene, align, texalign, texrotation, filltype, texoffsetX, texoffsetY, outline
--
-- Required arguments for BOX types are:
-- width, height
--
-- Optional named arguments for BOX types are:
-- borderwidth, bordertexture, bordertex
--
-- Required arguments for CIRCLE types are:
-- radius
--
-- Optional named arguments for CIRCLE types are:
-- density, borderwidth, bordertexture, bordertex
--
-- Required arguments for TRI types are:
-- verts
--
-- Required arguments for POLY types are:
-- verts
--

--- Creates a vertex buffer object.
-- @tparam table args The argument table.
-- @tparam number args.x The x coordinate of the object.
-- @tparam number args.y The y coordinate of the object.
-- @tparam Primitive args.primitive The type of the object.
-- @tparam number args.width The width of the object. (Only required when `primitive = TYPE_BOX`)
-- @tparam number args.height The height of the object. (Only required when `primitive = TYPE_BOX`)
-- @tparam number args.radius The radius of the object. (Only required when `primitive = TYPE_CIRCLE`)
-- @tparam table args.verts A list of vector vertex positions. (Only required when `primitive = TYPE_TRI` or `primitive = TYPE_POLY`)
-- @tparam[opt] Texture args.texture The texture to apply to the object.
-- @tparam[opt] bool args.scene Whether the object should be drawn in screen space or world space. (aliases: `sceneCoords`)
-- @tparam[opt] Alignment args.align How the object should be aligned to its pivot coordinate.
-- @tparam[opt=ALIGN_CENTER] Alignment args.texalign How the texture should be aligned to its pivot coordinate (ignored unless using `TEX_PLACE` fill type).
-- @tparam[opt=0] number args.rotation The clockwise rotation of the object in degrees.
-- @tparam[opt=0] number args.texrotation The clockwise rotation of the texture in degrees.
-- @tparam[opt=TEX_FILL] FillType args.filltype How the texture should be applied to the object.
-- @tparam[opt] number args.texoffsetX Offset to apply to the texture in the x direction (in UV space).
-- @tparam[opt] number args.texoffsetY Offset to apply to the texture in the y direction (in UV space).
-- @tparam[opt] bool args.outline Whether or not to create an outline for this object.
-- @tparam[opt] number/BorderLayout args.borderwidth How wide the border on this object should be. If not supplied, no border will be created. (Only supported when `primitive = TYPE_BOX` or `primitive = TYPE_CIRCLE`)
-- @tparam[opt] Texture/BorderImage args.bordertexture The texture to apply to the objects border. (aliases: `bordertex`) (Only supported when `primitive = TYPE_BOX` or `primitive = TYPE_CIRCLE`)
-- @tparam[opt] table args.vertColors A list of Color objects. Must be of equal length to the number of vertices in the object.
-- @return @{Object}
-- @see Wrapper
-- @usage imagic.create{primitive = imagic.TYPE_BOX, x=0, y=0, width=10, height=10}
-- @usage imagic.create{primitive = imagic.TYPE_CIRCLE, x=0, y=0, radius=5}
-- @usage imagic.create{primitive = imagic.TYPE_TRI, x=0, y=0, {vector.v2(0,0), vector.v2(10,-10), vector.v2(10,10)}}
function imagic.create(args)
	local p = {};
	setmetatable(p, Object);
	nilcheck(args,"x");
	nilcheck(args,"y");
	nilcheck(args,"primitive");
	p.x = args.x;
	p.y = args.y;
	p.texture = args.texture;
	p.scene = args.scene;
	
	if(p.scene == nil) then
		p.scene = args.sceneCoords;
	end
	
	p.__rot = 0;
	p.__scl = vector.one2;
	p.__pos = vector.zero2;
	
	p.__texrot = 0;
	p.__texscl = vector.one2;
	p.__texpos = vector.zero2;
	
	local filltype = args.filltype or imagic.TEX_FILL;
	p.texoffsetX = args.texoffsetX or 0;
	p.texoffsetY = args.texoffsetY or 0;
	local rotation = args.rotation or 0;
	local texrotation = args.texrotation or 0;
	local texalign = args.texalign or imagic.ALIGN_CENTRE;
	local align;
	
	-- Create a box --
	if(args.primitive == imagic.TYPE_BOX) then
		nilcheck(args,"width");
		nilcheck(args,"height");
		p._renderType = Graphics.GL_TRIANGLE_STRIP;
		align = args.align or imagic.ALIGN_TOPLEFT;
		
		local bwidth = 0;
		local bdr;
		if(args.borderwidth ~= nil) then
			bdr = imagic.Create{x=args.x, y=args.y, width=args.width, height = args.height, primitive = imagic.TYPE_BOXBORDER, texture = (args.bordertexture or args.bordertex), depth = args.borderwidth, scene = p.scene, align = align};
			bwidth = args.borderwidth;
		end
		
		local w;
		local h;
		if(type(bwidth) == "number") then
			w = args.width-bwidth*2;
			h = args.height-bwidth*2;
		else
			w = args.width - bwidth.left - bwidth.right;
			h = args.height - bwidth.top - bwidth.bottom;
		end
		
		p.verts = {0,0,w,0,0,h,w,h};
		
		alignVerts(p.verts,w, h, align, imagic.ALIGN_TOPLEFT);
		if(p.texture ~= nil) then
			if(filltype == imagic.TEX_FILL) then
				p.uvs = {0,0,1,0,0,1,1,1};
			elseif(filltype == imagic.TEX_PLACE) then
				p.uvs = {0,0,w/p.texture.width,0,0,h/p.texture.height,w/p.texture.width,h/p.texture.height};
				alignUVs(p.uvs, (w/p.texture.width), (h/p.texture.height), texalign, imagic.ALIGN_TOPLEFT);
			end
		end
		if(type(bwidth) == "number") then
			adjustVerts(p,bwidth,align)
		else
			adjustVariableVerts(p,bwidth.left,bwidth.top,bwidth.right,bwidth.bottom,align);
		end
		
		if(args.outline) then
			p.outlineverts = {p.verts[1], p.verts[2], p.verts[3]+1, p.verts[4], p.verts[7]+1, p.verts[8]+1, p.verts[5], p.verts[6]+1};
		end
		
		p.border = bdr;
	
	-- Create a circle --
	elseif(args.primitive == imagic.TYPE_CIRCLE) then
		nilcheck(args,"radius");
		p._renderType = Graphics.GL_TRIANGLE_FAN;
		align = args.align or imagic.ALIGN_CENTRE;
		local density = args.density or math.ceil(math.sqrt(args.radius)*6);
		
		local bwidth = 0;
		local bdr;
		if(args.borderwidth ~= nil) then
			bdr = imagic.Create{x=args.x, y=args.y, radius=args.radius, primitive = imagic.TYPE_CIRCLEBORDER, density = density, texture = (args.bordertexture or args.bordertex), depth = args.borderwidth, scene = args.scene, align = align};
			bwidth = args.borderwidth;
		end
		
		p.verts = {0,0}
		for i=0,density do
			local theta = (i/density)*math.pi*2;
			table.insert(p.verts, math.sin(theta)*(args.radius-bwidth));
			table.insert(p.verts, -math.cos(theta)*(args.radius-bwidth));
		end
		alignVerts(p.verts,2*(args.radius-bwidth),2*(args.radius-bwidth), align, imagic.ALIGN_CENTRE);
		
		if(p.texture ~= nil) then
			if(filltype == imagic.TEX_FILL) then
				p.uvs = {0.5,0.5}
				for i=0,density do
					local theta = (i/density)*math.pi*2;
					table.insert(p.uvs, (math.sin(theta)+1)*0.5);
					table.insert(p.uvs, (-math.cos(theta)+1)*0.5);
				end
			elseif(filltype == imagic.TEX_PLACE) then
				p.uvs = {0.5,0.5}
				for i=0,density do
					local theta = (i/density)*math.pi*2;
					table.insert(p.uvs, (math.sin(theta)*2*(args.radius-bwidth)/p.texture.width+1)*0.5);
					table.insert(p.uvs, (-math.cos(theta)*2*(args.radius-bwidth)/p.texture.height+1)*0.5);
				end
				alignUVs(p.uvs, (2*(args.radius-bwidth)/p.texture.width), (2*(args.radius-bwidth)/p.texture.height), texalign, imagic.ALIGN_CENTRE);
			end
		end
		adjustVerts(p,bwidth,align);
		
		if(args.outline) then
			p.outlineverts = {};
			for i = 3,#p.verts do
				p.outlineverts[i-2] = p.verts[i];
			end
		end
		
		p.border = bdr;
		
	-- Create a triangle --
	elseif(args.primitive == imagic.TYPE_TRI) then
		nilcheck(args,"verts");
		p._renderType = Graphics.GL_TRIANGLES;
		align = args.align or imagic.ALIGN_TOPLEFT;
		if(type(args.verts) ~= "table" or #args.verts ~= 3) then
			error("Incorrect triangle definition.", 1);
		end
		p.verts = {};
		local minx, maxx;
		local miny, maxy;
		for _,v in ipairs(args.verts) do
				local x = v.x or v[1];
				local y = v.y or v[2];
				if(minx == nil) then 
					minx = x;
					maxx = x; 
					miny = y; 
					maxy = y; 
				end;
				table.insert(p.verts,x);
				table.insert(p.verts,y);
				minx = math.min(minx,x);
				maxx = math.max(maxx,x);
				miny = math.min(miny,y);
				maxy = math.max(maxy,y);
		end
		alignVerts(p.verts,maxx-minx,maxy-miny, align, imagic.ALIGN_TOPLEFT);
		
		if(args.outline) then
			p.outlineverts = p.verts;
		end
		
		if(p.texture ~= nil) then
			if(filltype == imagic.TEX_FILL) then
				p.uvs = {};
				for _,v in ipairs(args.verts) do
					local x = v.x or v[1];
					local y = v.y or v[2];
					table.insert(p.uvs, (x-minx)/(maxx-minx))
					table.insert(p.uvs, (y-miny)/(maxy-miny))
				end
			elseif(filltype == imagic.TEX_PLACE) then
				p.uvs = {};
				for _,v in ipairs(args.verts) do
					local x = v.x or v[1];
					local y = v.y or v[2];
					table.insert(p.uvs, (x-minx)/(p.texture.width-minx))
					table.insert(p.uvs, (y-miny)/(p.texture.height-miny))
				end
			alignUVs(p.uvs, ((maxx-minx)/p.texture.width), ((maxy-miny)/p.texture.height), texalign, imagic.ALIGN_TOPLEFT);
			end
		end
		
	-- Create a polygon --
	elseif(args.primitive == imagic.TYPE_POLY) then
		nilcheck(args,"verts");
		p._renderType = Graphics.GL_TRIANGLES;
		align = args.align or imagic.ALIGN_TOPLEFT;
		if(type(args.verts) ~= "table" or #args.verts < 3) then
			error("Incorrect polygon definition.", 1);
		end
		
		local vlist = {};
		local winding = 0;
		local minx, maxx;
		local miny, maxy;
		for k,v in ipairs(args.verts) do
				local x = v.x or v[1];
				local y = v.y or v[2];
				if(minx == nil) then 
					minx = x;
					maxx = x; 
					miny = y; 
					maxy = y; 
				end;
				minx = math.min(minx,x);
				maxx = math.max(maxx,x);
				miny = math.min(miny,y);
				maxy = math.max(maxy,y);
				
				local n = k+1;
				local pr = k-1;
				if(n > #args.verts) then n = 1; end
				if(pr <= 0) then pr = #args.verts end
				winding = winding + (x+(args.verts[n].x or args.verts[n][1]))*(y-(args.verts[n].y or args.verts[n][2]));
		end
		
		if(winding > 0) then
			for i=#args.verts,1,-1 do
				table.insert(vlist,args.verts[i]);
			end
		else
			for _,v in ipairs(args.verts)do
				table.insert(vlist,v);
			end
		end
		
		
		if(args.outline) then
			p.outlineverts = {};
			for i = 1,#vlist do
				table.insert(p.outlineverts, vlist[i].x or vlist[i][1]);
				table.insert(p.outlineverts, vlist[i].y or vlist[i][2]);
			end
		end
		
		p.verts = {};
		--Repeatedly search for and remove convex triangles (ears) from the polygon (as long as they have no other vertices inside them). When the polygon has only 3 vertices left, stop.
		while(#vlist > 3) do
			local count = #vlist;
			for k,v in ipairs(vlist) do
				local n = k+1;
				local pr = k-1;
				if(n > #vlist) then n = 1; end
				if(pr <= 0) then pr = #vlist; end
				
				local x,y = (v.x or v[1]),(v.y or v[2]);
				local nx,ny = (vlist[n].x or vlist[n][1]), (vlist[n].y or vlist[n][2])
				local prx,pry = (vlist[pr].x or vlist[pr][1]), (vlist[pr].y or vlist[pr][2])
				
				
				local lr = x > prx or y > pry;
				if lr then
					lr = 1;
				else
					lr = -1;
				end
				local left = isLeft(vlist[n], vlist[pr], v);
				if(left > 0) then
					local pointin = false;
					for k2,v2 in ipairs(vlist) do
						if(k2 ~= k and k2 ~= n and k2 ~= pr) then
							if(isLeft(vlist[pr], v, v2) > 0 and isLeft(v, vlist[n], v2) > 0 and isLeft(vlist[n], vlist[pr], v2) > 0) then
								pointin = true;
								break;
							end
						end
					end
					if(not pointin) then
						table.insert(p.verts, prx);
						table.insert(p.verts, pry);
						table.insert(p.verts, x);
						table.insert(p.verts, y);
						table.insert(p.verts, nx);
						table.insert(p.verts, ny);
						table.remove(vlist,k);
						break;
					end
				elseif(left == 0) then
					table.remove(vlist,k);
					break;
				end
			end
			if(#vlist == count) then
				error("Polygon is not simple. Please remove any edges that cross over.",2);
			end
		end
	
		--Insert the final triangle to the triangle list.
		table.insert(p.verts, vlist[1].x or vlist[1][1]);
		table.insert(p.verts, vlist[1].y or vlist[1][2]);
		table.insert(p.verts, vlist[2].x or vlist[2][1]);
		table.insert(p.verts, vlist[2].y or vlist[2][2]);
		table.insert(p.verts, vlist[3].x or vlist[3][1]);
		table.insert(p.verts, vlist[3].y or vlist[3][2]);
		
		if(p.texture ~= nil) then
			if(filltype == imagic.TEX_FILL) then
				p.uvs = {};
				for i = 1, #p.verts, 2 do
					local x = p.verts[i];
					local y = p.verts[i+1];
					table.insert(p.uvs, (x-minx)/(maxx-minx))
					table.insert(p.uvs, (y-miny)/(maxy-miny))
				end
			elseif(filltype == imagic.TEX_PLACE) then
				p.uvs = {};
				for i = 1, #p.verts, 2 do
					local x = p.verts[i];
					local y = p.verts[i+1];
					table.insert(p.uvs, (x-minx)/(p.texture.width-minx))
					table.insert(p.uvs, (y-miny)/(p.texture.height-miny))
				end
			alignUVs(p.uvs, ((maxx-minx)/p.texture.width), ((maxy-miny)/p.texture.height), texalign, imagic.ALIGN_TOPLEFT);
			end
		end
		
		alignVerts(p.verts,maxx-minx,maxy-miny, align, imagic.ALIGN_TOPLEFT);
		alignVerts(p.outlineverts,maxx-minx,maxy-miny, align, imagic.ALIGN_TOPLEFT);
		
	-- Create a box-type border (hollow box) --
	elseif(args.primitive == imagic.TYPE_BOXBORDER) then
		nilcheck(args,"width");
		nilcheck(args,"height");
		nilcheck(args,"depth");
		p._renderType = Graphics.GL_TRIANGLES;
		align = args.align or imagic.ALIGN_TOPLEFT;
		if(type(args.depth) == "number") then
			p.verts = makeBoxBorderVerts(args.depth, args.width, args.height);
		else
			p.verts = makeVariableBoxBorderVerts(args.depth.left, args.depth.top, args.depth.right, args.depth.bottom, args.width, args.height);
		end
		alignVerts(p.verts,args.width,args.height, align, imagic.ALIGN_TOPLEFT);
		if(p.texture ~= nil) then
			if(p.texture.__type ~= nil and p.texture.__type == "BorderImage") then
				p.uvs = makeVariableBoxBorderVerts(p.texture.left,p.texture.top,p.texture.right,p.texture.bottom, 1, 1);
				p.texture = p.texture.texture;
			else
				p.uvs = makeBoxBorderVerts(1/3, 1, 1);
			end
		end
		
	-- Create a circle-type border (hollow circle) --
	elseif(args.primitive == imagic.TYPE_CIRCLEBORDER) then
		nilcheck(args,"radius");
		nilcheck(args,"depth");
		p._renderType = Graphics.GL_TRIANGLE_STRIP;
		align = args.align or imagic.ALIGN_CENTRE;
		local density = args.density or math.ceil(math.sqrt(args.radius)*6);
		p.verts = {}
		local theta = 0;
		local st = 0;
		local ct = 1;
		for i=0,density-1 do
			local nt = ((i+1)/density)*math.pi*2;
			local nst = math.sin(nt);
			local nct = math.cos(nt);
			table.insert(p.verts, st*(args.radius-args.depth));
			table.insert(p.verts, -ct*(args.radius-args.depth));
			table.insert(p.verts, st*args.radius);
			table.insert(p.verts, -ct*args.radius);
			table.insert(p.verts, nst*(args.radius-args.depth));
			table.insert(p.verts, -nct*(args.radius-args.depth));
			table.insert(p.verts, nst*args.radius);
			table.insert(p.verts, -nct*args.radius);
			
			theta = nt;
			st = nst;
			ct = nct;
		end
		alignVerts(p.verts,2*args.radius,2*args.radius, align, imagic.ALIGN_CENTRE);
		if(p.texture ~= nil) then
			p.uvs = {}
			local t;
			if(p.texture.__type ~= nil and p.texture.__type == "BorderImage") then
				t = p.texture.top;
				p.texture = p.texture.texture;
			else
				t = 1/3;
			end
			for i=0,density-1 do
				table.insert(p.uvs, t);
				table.insert(p.uvs, t);
				table.insert(p.uvs, t);
				table.insert(p.uvs, 0);
				table.insert(p.uvs, 1-t);
				table.insert(p.uvs, t);
				table.insert(p.uvs, 1-t);
				table.insert(p.uvs, 0);
			end
		end
	end
	
	if(texrotation ~= 0) then
		p:RotateTexture(texrotation);
	end
	
	local vcs = args.vertColors or args.vertexColors or args.vertColours or args.vertexColours;
	if(vcs ~= nil) then
		p.vertexColors = {};
		local i = 1;
		for _,v in ipairs(vcs) do
			local c = convertCol(v);
			p.vertexColors[i] = c[1];
			p.vertexColors[i+1] = c[2];
			p.vertexColors[i+2] = c[3];
			p.vertexColors[i+3] = c[4];
			i=i+4;
		end
	
	end
	
	if(rotation ~= 0) then
		p:Rotate(rotation);
	end
	
	return p;
end

imagic.Create = imagic.create;


-- Function for instant drawing of an image
-- Takes many of the same arguments as Graphics.draw, with the following additions:
-- rotation, colour, color, width, height, scene, vertexColours, vertColours, vertexColors, vertColors, shader, uniforms, attributes, target


--- Instantly draws an image without creating a vertex buffer @{Object}.
-- @tparam table args The argument table.
-- @tparam number args.x The x coordinate of the object.
-- @tparam number args.y The y coordinate of the object.
-- @tparam number args.width The width of the object. (Only required when `texture = nil`)
-- @tparam number args.height The height of the object. (Only required when `texture = nil`)
-- @tparam Texture args.texture The texture to apply to the object.
-- @tparam[opt=ALIGN_TOPLEFT] Alignment args.align How the object should be aligned to its pivot coordinate.
-- @tparam[opt] number args.rotation The clockwise rotation of the object in degrees.
-- @tparam[opt=white] Color args.color A color tint when drawing the object. (aliases: `colour`)
-- @tparam[opt] bool args.scene Whether the object should be drawn in screen space or world space. (aliases: `sceneCoords`)
-- @tparam[opt] number args.priority The render priority to draw the object at. (aliases: `z`)
-- @tparam[opt] number args.sourceX The x-position to sample the texture from in pixels.
-- @tparam[opt] number args.sourceY The y-position to sample the texture from in pixels.
-- @tparam[opt] number args.sourceWidth The width of the texture sample in pixels.
-- @tparam[opt] number args.sourceHeight The height of the texture sample in pixels.
-- @tparam[opt] table args.vertColors A list of Color objects. Must be of equal length to the number of vertices in the object. (aliases: `vertexColors`, `vertexColours`, `vertColours`)
-- @tparam[opt] Shader args.shader A shader to apply when drawing the object.
-- @tparam[opt] table args.uniforms A table of uniform variables to apply when drawing the object with a shader.
-- @tparam[opt] table args.attributes A table of attribute variables to apply when drawing the object with a shader.
-- @tparam[opt] CaptureBuffer args.target A render target to draw the object to.
-- @see create
-- @usage imagic.draw{x=0, y=0, width=10, height=10}
-- @usage imagic.draw{x=0, y=0, width=10, height=10, rotation = 45, color = Color.red}
function imagic.draw(args)
	nilcheck(args, "x");
	nilcheck(args, "y");
	if((args.width == nil or args.height == nil) and args.texture == nil) then
		error("Must define either width, height or a texture to draw.",1);
	end
	local rot = args.rotation or 0;
	rot = rot*imagic.DEG2RAD;
	local col = args.colour or args.color or 0xFFFFFFFF;
	local align = args.align or imagic.ALIGN_TOPLEFT;
	
	local sourceWidth = 0;
	local sourceHeight = 0;
	local sourceX = 0;
	local sourceY = 0;
	local w = 0;
	local h = 0;
	if(args.texture ~= nil) then
		sourceWidth = args.sourceWidth or args.texture.width;
		sourceWidth = math.max(0,math.min(1,sourceWidth/args.texture.width));
		
		sourceHeight = args.sourceHeight or args.texture.height;
		sourceHeight = math.max(0,math.min(1,sourceHeight/args.texture.height));
		
		sourceX = args.sourceX or 0;
		sourceX = math.max(0,math.min(1-sourceWidth,sourceX/args.texture.width));
		
		sourceY = args.sourceY or 0;
		sourceY = math.max(0,math.min(1-sourceHeight,sourceY/args.texture.height));
	
		w = args.width or args.texture.width*sourceWidth;
		h = args.height or args.texture.height*sourceHeight;
	else
		w = args.width or 0;
		h = args.height or 0;
	end
	local scene = args.scene;
	if(scene == nil) then
		scene = args.sceneCoords;
	end
	
	local xoff,yoff = getAlignOffset(align, w, h);
	xoff = -xoff;
	yoff = -yoff;
	
	local vs = {xoff, yoff, xoff+w, yoff, xoff+w, yoff+h, xoff, yoff+h}
	
	local cs = 1;
	local sn = 0;
	if(rot ~= 0) then
		cs = math.cos(rot);
		sn = math.sin(rot);
	end
	for i=1,#vs,2 do
		local v = vs[i];
		vs[i] = (cs*vs[i]) - (sn*vs[i+1]) + args.x;
		vs[i+1] = (cs*vs[i+1]) + (sn*v) + args.y;
	end
	
	local ts = {sourceX, sourceY, math.min(1,sourceX+sourceWidth), sourceY, math.min(1,sourceX+sourceWidth), math.min(1,sourceY+sourceHeight), sourceX, math.min(1,sourceY+sourceHeight)};
	local vcs = args.vertColors or args.vertexColors or args.vertColours or args.vertexColours;
	local vcols;
	if(vcs ~= nil) then	
		vcols = {}
		for i=1,4 do
			local v = convertCol(vcs[i]);
			table.insert(vcols, v[1])
			table.insert(vcols, v[2])
			table.insert(vcols, v[3])
			table.insert(vcols, v[4])
		end
	end
	
	if(col ~= nil and type(col) == "number") then
		col = convertCol(col);
	end
	
	Graphics.glDraw{vertexCoords=vs, textureCoords=ts, vertexColors = vcols, color = col, texture = args.texture, 
					primitive = Graphics.GL_TRIANGLE_FAN, sceneCoords = scene, priority = args.priority or args.z,
					shader = args.shader, uniforms = args.uniforms, attributes = args.attributes, target = args.target}
end

imagic.Draw = imagic.draw;


-- Function for instant drawing of a progress bar
--
-- Required named arguments are:
-- x, y, width, height
--
-- Optional named arguments are:
-- percent, align, baralign, bgwidth, bgheight, scene, sceneCoords, texture, colour, color, bgtexture, bgcolour, bgcolor, bgcol, priority, z, outline, outlinecolour, outlinecolor, outlinecol


--- Specialised drawing of a progress bar.
-- @tparam table args The argument table.
-- @tparam number args.x The x coordinate of the bar.
-- @tparam number args.y The y coordinate of the bar.
-- @tparam number args.width The width of the bar.
-- @tparam number args.height The height of the bar.
-- @tparam[opt=1] number args.percent The filled portion of the bar. Ranges between 0 and 1.
-- @tparam[opt] Texture args.texture The texture to apply to the bar.
-- @tparam[opt=ALIGN_TOPLEFT] Alignment args.align How the bar object should be aligned to its pivot coordinate.
-- @tparam[opt=ALIGN_BOTTOMLEFT] Alignment args.baralign How the bar itself should be aligned. This determines which direction the bar fills.
-- @tparam[opt] number args.bgwidth The width of the bar background. By default, this is 2 pixels larger than the bar itself.
-- @tparam[opt] number args.bgheight The width of the bar background. By default, this is 2 pixels larger than the bar itself.
-- @tparam[opt] bool args.scene Whether the bar should be drawn in screen space or world space. (aliases: `sceneCoords`)
-- @tparam[opt] Color args.color A color tint when drawing the bar. If no texture is supplied, this will default to green. Otherwise, it will default to white. (aliases: `colour`)
-- @tparam[opt] Texture args.bgtexture The texture to apply to the bar background.
-- @tparam[opt] Color args.bgcolor A color tint when drawing the bar background. If no texture is supplied, this will default to black. Otherwise, it will default to white. (aliases: `bgcolour`, `bgcol`)
-- @tparam[opt] number args.priority The render priority to draw the bar at. (aliases: `z`)
-- @tparam[opt=false] bool args.outline Whether to draw an outline or not.
-- @tparam[opt=white] Color args.outlinecolor A color tint to the outline when drawing the bar if outlines are enabled. (aliases: `outlinecolour`, `outlinecol`)
-- @usage imagic.bar{x=0, y=0, width=100, height=10, percent = 0.5}
function imagic.bar(args)
	nilcheck(args, "x")
	nilcheck(args, "y")
	nilcheck(args, "width")
	nilcheck(args, "height")
	args.bgwidth = args.bgwidth or args.width+2;
	args.bgheight = args.bgheight or args.height+2;
	args.scene = args.scene;
	if(args.scene == nil) then
		args.scene = args.sceneCoords;
	end
	if(args.texture ~= nil) then
		args.colour = args.colour or args.color or 0xFFFFFFFF;
	else
		args.colour = args.colour or args.color or 0x00FF00FF;
	end
	args.bgtexture = args.bgtexture or args.bgtex;
	
	if(args.bgtexture ~= nil) then
		args.bgcolour = args.bgcolour or args.bgcolor or args.bgcol or 0xFFFFFFFF;
	else
		args.bgcolour = args.bgcolour or args.bgcolor or args.bgcol or 0x000000FF;
	end
	args.align = args.align or imagic.ALIGN_TOPLEFT;
	args.percent = args.percent or 1;
	args.percent = math.min(1,math.max(0,args.percent));
	local xs,ys = getAlignOffset(args.align, 1, 1);
	xs,ys = args.bgwidth*(0.5-xs), args.bgheight*(0.5-ys);
	imagic.Draw{x = args.x + xs, y = args.y + ys, align = imagic.ALIGN_CENTRE, texture = args.bgtexture, colour = args.bgcolour, width = args.bgwidth, height = args.bgheight, scene=args.scene, priority = args.priority or args.z}
	
	args.baralign = args.baralign or imagic.ALIGN_BOTTOMLEFT;
	if(args.baralign == imagic.ALIGN_TOP or args.baralign == imagic.ALIGN_BOTTOM or args.vertical) then
		-- Vertical bar
		local _,sb = getAlignOffset(args.baralign, 1, 1);
		sb = args.height*(0.5-sb)*(1-args.percent);
		imagic.Draw{x = args.x + xs, y = args.y + ys - sb, align = imagic.ALIGN_CENTRE, texture = args.texture, colour = args.colour, width = args.width, height = args.height*args.percent, scene=args.scene, priority = args.priority or args.z}
	else 
		-- Horizontal bar
		local sb = getAlignOffset(args.baralign, 1, 1);
		sb = args.width*(0.5-sb)*(1-args.percent);
		imagic.Draw{x = args.x + xs - sb, y = args.y + ys, align = imagic.ALIGN_CENTRE, texture = args.texture, colour = args.colour, width = args.width*args.percent, height = args.height, scene=args.scene, priority = args.priority or args.z}
	end
	
	if(args.outline) then
		local outlinecol = args.outlinecolour or args.outlinecolor or args.outlinecol or 0xFFFFFFFF;
		
		if(outlinecol ~= nil and type(outlinecol) == "number") then
			outlinecol = convertCol(outlinecol);
		end
		Graphics.glDraw{vertexCoords = 
		{args.x + xs - args.bgwidth*0.5, args.y + ys - args.bgheight*0.5, args.x + xs + args.bgwidth*0.5 + 1, args.y + ys - args.bgheight*0.5, args.x + xs + args.bgwidth*0.5 + 1, args.y + ys + args.bgheight*0.5 + 1, args.x + xs - args.bgwidth*0.5, args.y + ys + args.bgheight*0.5 + 1}, 
						primitive = Graphics.GL_LINE_LOOP, priority = args.priority or args.z, color=outlinecol, sceneCoords = args.scene};
	end
end

imagic.Bar = imagic.bar;

return imagic;