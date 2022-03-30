---
--@script Textplus

-- textplus --------------------------------------------------------
-- Created by rockythechao - 2018 ----------------------------------
-- Open-Source SMBX Text Library -----------------------------------
-- incomplete WIP version ------------------------------------------
-- Documentation: http://wohlsoft.ru/pgewiki/Textplus.lua ----------

-- To-do: ----------------------------------------------------------
--- a lot ----------------------------------------------------------

-- Potential feature ideas: ----------------------------------------
--- render targets -------------------------------------------------
--- label transformations ------------------------------------------
--- typewriter effect per-character animation customization --------
--- marquee stuff somehow? (possible style function candidate) -----
--- stop tag that requires the player to give further input --------

-- Notes:
--- distinction between cue functions and style functions
--- layout pass caches layout and cue/timing data
--- per-page behaviors, non-funct style properties, and space allocation for insertion commands are processed during layout pass
--- insert commands have fixed spacing
--- style functs only affect rendering, not layout
--- same with text appear and disappear animations
--- try to incorporate auto-wrapping and mid-word breaks


local textplus = {} --Package table
textplus.version = "0.1"

local tplusParse = require('textplus/tplusparse')
local tplusLayout = require('textplus/tpluslayout')
local tplusFont = require('textplus/tplusfont')
local tplusRender = require('textplus/tplusrender')
local tplusUtils = require('textplus/tplusutils')

textplus.settings = { effectScale = 1 }

tplusRender.getSettings = function() return textplus.settings end

--- Functions.
-- @section Functions

--- Parses input text with specified formatting data
--@function textplus.parse
--@tparam 	   string text Text input to prase.
--@tparam[opt] table  fmt  Optional formatting data.
--@return Table representing formatted text
function textplus.parse(text, fmt, customTags, customAutoSelfClosingTags)
	-- Make blank format table if we aren't given one
	if (fmt == nil) then
		fmt = {}
	end

	-- TODO: Should defaults be handled at this stage... or be deferred to the
	--       render function in tplusrender.lua? I started doing it in both but
	--       it should really only be in one.
	--       The input side is a better choice if we want to allow tags to
	--       manipulate things in a way that is conditional depending on what
	--       the parent formatting settings already are.
	if (fmt.font == nil) then
		fmt.font = tplusFont.font4
	end
	if (fmt.color == nil) then
		fmt.color = Color.white
	end
	if (fmt.xscale == nil) then
		fmt.xscale = 1
	end
	if (fmt.yscale == nil) then
		fmt.yscale = 1
	end
	
	local formattedText
	if (fmt.plaintext) then
		-- Handle the case of fully forced plaintext input
		formattedText = {tplusUtils.strToCodes(text)}
		formattedText[1].fmt = fmt
	else
		-- Parse and resolve the formatting
		formattedText = tplusParse.parseAndFormat(text, fmt, customTags, customAutoSelfClosingTags)
	end
	
	return formattedText
end

--- Performs layout (i.e. wrapping) of formatted text
--@function textplus.layout
--@tparam 	   table  input    The formatted text to produce a layout of.
--@tparam[opt] number maxWidth Optional maximum width to format the text to fit in.
--@return Table representing the text layout
function textplus.layout(input, maxWidth, fmt, customTags, customAutoSelfClosingTags)
	local formattedText
	if type(input) == "string" then
		formattedText = textplus.parse(input, fmt, customTags, customAutoSelfClosingTags)
	else
		formattedText = input
	end
	
	-- Perform layout of the text
	local textLayout = tplusLayout.Layout(formattedText, maxWidth)
	
	return textLayout
end

--- Renders a text layout
--@function textplus.render
--@tparam table args
--@tparam 				number        args.x           X coordinate to render from
--@tparam 				number        args.y           Y coordinate to render from
--@tparam 				table         args.layout      The text layout to render
--@tparam[opt] 			number        args.limit       Optional maximum number of characters to truncate rendering at
--@tparam[opt=false]	boolean       args.sceneCoords Optional scene coordinates flag
--@tparam[opt=0]		number        args.priority    Optional render priority
--@tparam[opt] 			CaptureBuffer args.target      Optional target capture buffer to render to
--@tparam[opt] 			Shader        args.shader      Optional shader object to render all text with
--@tparam[opt] 			table         args.uniforms    Optional uniforms to supply to the shader
--@tparam[opt] 			Color         args.color       Optional color to tint all text by
--@tparam[opt] 			bool       	  args.smooth      Optional smooth scaling option (will use crisp scaling as long as no shader is applied, otherwise it will use bilinear filtering)
--@return Table representing the text layout
function textplus.render(args)
--x, y, layout, limit, sceneCoords, priority, target, shader, color
	-- TODO: Support different ways of aligning, using the size output 
	
	tplusRender.renderLayout(args.x, args.y, args.layout, args.limit, args.sceneCoords, args.priority, args.target, args.shader, args.uniforms, args.color, args.smooth)
end

--- Convenience function to parse/layout/render text all at once. Accepts all parameters as named
--- arguments, and extra named arguments will be treated as formatting data.
--@function textplus.print
--@param args
--@tparam 			 number        args.x           X coordinate to render from
--@tparam 			 number        args.y           Y coordinate to render from
--@tparam 			 string        args.text        The text to print
--@tparam[opt] 		 number        args.maxWidth    Optional maximum width to format the text to fit in.
--@tparam[opt] 		 number        args.limit       Optional maximum number of characters to truncate rendering at
--@tparam[opt] 		 Vector2       args.pivot       Optional pivot point to align the text against
--@tparam[opt=false] boolean       args.sceneCoords Optional scene coordinates flag
--@tparam[opt=0]	 number        args.priority    Optional render priority
--@tparam[opt] 		 CaptureBuffer args.target      Optional target capture buffer to render to
--@tparam[opt] 		 Shader        args.shader      Optional shader object to render all text with
--@tparam[opt] 		 table         args.uniforms    Optional uniforms to supply to the shader
--@tparam[opt] 		 Color         args.color       Optional color to tint all text by
function textplus.print(args)
	-- TODO: Maybe support numbered arguments as well
	
	-- Extract args that are not formatting
	args = table.clone(args)
	
	local text = args.text
	args.text = nil
	local x = args.x
	args.x = nil
	local y = args.y
	args.y = nil
	local maxWidth = args.maxWidth
	args.maxWidth = nil
	local limit = args.limit
	args.limit = nil
	local sceneCoords = args.sceneCoords
	args.sceneCoords = nil
	local target = args.target
	args.target = nil
	local shader = args.shader
	args.shader = nil
	local pivot = args.pivot
	args.pivot = nil
	local uniforms = args.uniforms
	args.uniforms = nil
	local smooth = args.smooth
	args.smooth = nil
	
	-- Format the text
	local formattedText = textplus.parse(text, args)
	
	-- Perform layout of the text
	local textLayout = textplus.layout(formattedText, maxWidth)
	
	if pivot ~= nil then
		x = x-pivot[1]*textLayout.width
		y = y-pivot[2]*textLayout.height
	end
	
	textplus.render{x = x, y = y, layout = textLayout, limit = limit, sceneCoords = sceneCoords, priority = args.priority, target = target, shader = shader, uniforms = uniforms, smooth = smooth}
end
	
--- Function for loading a font from ini file
--@function textplus.print
--@tparam string filename Filename of the font to load
--@return Returns a font object based on the data in the specified file
function textplus.loadFont(filename)
	return tplusFont.Font.load(filename)
end

--- Function to turn a UTF-8 string into a table of character codes.
--@function textplus.strToCodes
--@tparam string input Input string
--@return Returns a table of character codes
function textplus.strToCodes(input)
	return tplusutils.strToCodes(input)
end

	
return textplus