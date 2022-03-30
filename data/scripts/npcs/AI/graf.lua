local graf = {}

local npcManager = require("npcManager")
local rng = require("rng")
local particles = require("particles")

local trails = {}

graf.sharedSettings = {
	width = 32,
	height = 32,
	gfxwidth = 32,
	gfxheight = 32,
	frames = 2,
	framespeed = 8,
	framestyle = 1,
	score = 2,
	nogravity = true,
	jumphurt = false,
	nofireball = false,
	noiceball = false,
	noyoshi = false,
	noblockcollision = true,
	
	--lua settings
	forcespawn = false,
	setpos = true,
	relativecoords = true,
	blocks = true,
	seconds = true,
	invert = true,
	absolutetime = false,
    parametric = true,
    ribbon = false
}

local proxytbl = {
	rng = rng,
	lunatime = lunatime,
	e = 2.718281828459,
	toBlocks = function(pixels)
		return pixels / 32
	end,
	toPixels = function(blocks)
		return blocks * 32
	end
}

local proxymt = {
	__index = function(t, k)
		return lunatime[k] or rng[k] or math[k] or _G[k]
	end,
	__newindex = function() end
}
setmetatable(proxytbl, proxymt)

function graf.register(config)
	npcManager.registerEvent(config.id, graf, "onStartNPC")
    npcManager.registerEvent(config.id, graf, "onTickNPC")
    npcManager.setNpcSettings(table.join(config, graf.sharedSettings))
end

function graf.onInitAPI()
	registerEvent(graf, "onDraw")
end

local funcCache = {}

local parse -- Local outside for recursion
function parse(msg, recurse)
	if funcCache[msg] then
		return funcCache[msg]
	end
	local str = [[
		return function(npc, self, v, x, y, t)
			return {]] .. msg .. [[}
		end
	]]
	local chunk, err = load(str, str, "t", proxytbl)
	if chunk then
		local func = chunk()
		funcCache[msg] = func
		return func
	elseif not recurse then
		-- attempt adding line separators
		-- this might further break a graf setup that's already invalid
		-- but that really shouldn't matter
		return parse(msg:gsub("\r?\n", ";\n"), true)
	else
		return nil, err
	end
end

local function call(npc)
	local data = npc.data._basegame
	local settings = NPC.config[npc.id]
	
	local xPos = npc.x
	local yPos = npc.y
	-- If using relative coords, subtract spawn coords
	if settings.relativecoords then
		local spawnX = data.origin.x
		local spawnY = data.origin.y
		xPos = xPos - spawnX
		yPos = yPos - spawnY
	end
	-- If using blocks, divide by 32
	if settings.blocks then
		xPos = xPos / 32
		yPos = yPos / 32
	end
	-- If flipping the y-axis, do so
	if settings.invert then
		yPos = -yPos
	end
	
	local timer 
	if settings.absolutetime then	
		timer = lunatime.tick()
	else
		timer = data.timer
	end
	-- If using seconds, convert to seconds
	if settings.seconds then
		timer = lunatime.toSeconds(timer)
	end
	
	local tbl = data.func(npc, npc, npc, xPos, yPos, timer)

	local x = tbl.x or 0
	local y = tbl.y or tbl[1] or 0
	local speedX = tbl.speedX or 0
	local speedY = tbl.speedY or 0
	
	-- If using blocks, multiply by 32
	if settings.blocks then
		x = x * 32
		y = y * 32
		speedX = speedX * 32
		speedY = speedY * 32
	end
	-- If using seconds, reduce speed accordingly
	if settings.seconds then
		speedX = lunatime.toSeconds(speedX)
		speedY = lunatime.toSeconds(speedY)
	end
	-- If flipping the y-axis, flip the returned value
	if settings.invert then
		y = -y
		speedY = -speedY
	end
	
	-- If the speed variables aren't in the table, erase them here
	if not tbl.speedX then
		speedX = nil
	end
	if not tbl.speedY then
		speedY = nil
	end
	
	return x, y, speedX, speedY
end

function graf:onStartNPC()
	local data = self.data._basegame
	local settings = self.data._settings
	local func, err = parse(settings.parserInput or "")
	if not err then
		data.func = func
	end
	data.origin = {
		x = self:mem(0xA8, FIELD_DFLOAT),
		y = self:mem(0xB0, FIELD_DFLOAT)
	}
	
	if NPC.config[self.id].ribbon then
		local trail = particles.Ribbon(0, 0, Misc.resolveFile("particles/r_trail.ini"))
		trail:Attach(self)
		trail:setParam("lifetime", 5)
		trails[self] = trail
	end
end

function graf:onTickNPC()
	if Defines.levelFreeze then return end
	local data = self.data._basegame
	local s = self.data._settings
	local settings = NPC.config[self.id]
	data.timer = data.timer or 0
	if settings.forcespawn then
		self:mem(0x12A, FIELD_WORD, 180)
	end
	if self:mem(0x12A, FIELD_WORD) > 0 then
		if type(data.func) == "function" then
			local x, y, speedX, speedY = call(self)
			if speedY then
				self.speedY = speedY
			else
				if settings.setpos then
					self.y = y + data.origin.y
				else
					local relativeY = self.y - data.origin.y
					self.speedY = y - relativeY
				end
			end
			if settings.parametric then
				if speedX then
					self.speedX = speedX
				else
					if settings.setpos then
						local oldX = self.x
						self.x = x + data.origin.x
						if self.x > oldX then
							self.direction = DIR_RIGHT
						elseif self.x < oldX then
							self.direction = DIR_LEFT
						end
					else
						local relativeX = self.x - data.origin.x
						self.speedX = x - relativeX
					end
				end
			end
		elseif s.parserInput ~= nil and s.parserInput ~= "" then
			graf.onStartNPC(self)
		end
		data.timer = data.timer + 1
	else
		data.timer = 0
	end
end

function graf.onDraw()
	for npc, trail in pairs(trails) do
		if npc.isValid or trail:Count()>0 then
			trail:Draw(-60)
		else
			trails[npc] = nil
		end
	end
end

return graf