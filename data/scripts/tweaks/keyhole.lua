local keyhole = {}

keyhole.mask = false
keyhole.size = 0
keyhole.counter = 0
keyhole.lockObj = nil
keyhole.lockOffsets = {}
keyhole.roundPoints = 21
keyhole.radius = 30
keyhole.circleMidY = -25
keyhole.animationEnabled = true


local holdsHigh = { 
					[CHARACTER_WARIO] = true
				  }
local levelEnded = false

local tableinsert = table.insert
local mathpi = math.pi
local mathsin = math.sin
local mathcos = math.cos
local mathlerp = math.lerp
local mathhuge = math.huge
local mathsqrt = math.sqrt

-- Frame buffer
local frameBuffer = Graphics.CaptureBuffer(800, 600)

function keyhole.onInitAPI()
	registerEvent(keyhole, "onStart", "onStart", true)
	registerEvent(keyhole, "onCameraDraw", "onCameraDraw", true)
end

local function worldToScreen(x,y,camNumber)
	camNumber = camNumber or 1

	local cam = Camera(camNumber)
	local x1 = x-cam.x
	local y1 = y-cam.y
	return x1,y1
end	


-- Define the lock mesh offsets
function keyhole.onStart()
	
	-- Bottom mid and bottom left
	keyhole.lockOffsets = {00,25,-30,25}
	
	-- Circular part
	local circleY, r = keyhole.circleMidY, 30
	for i = 0,keyhole.roundPoints do
		local degrees = mathlerp(180-45, 360+45, i/keyhole.roundPoints)
		local angle = degrees * mathpi / 180
		local ptx, pty = r * mathcos(angle), circleY + r * mathsin(angle)
		tableinsert(keyhole.lockOffsets, ptx)
		tableinsert(keyhole.lockOffsets, pty)
	end
	
	-- Bottom right
	tableinsert(keyhole.lockOffsets, 30)
	tableinsert(keyhole.lockOffsets, 25)
end


-- Handle the rendering and stuff
function keyhole.onCameraDraw(cameraIndex)
    if frameBuffer.width ~= camera.width or frameBuffer.height ~= camera.height then
        frameBuffer = Graphics.CaptureBuffer(camera.width,camera.height)
    end

	for _,p in ipairs(Player.get()) do
	
		local doStep2 = true
			
		-- If characters are particularly tall, then they might be unable to touch the keyhole, so do that manually.
		if Level.winState() == 0 and holdsHigh[p.character] and p.holdingNPC and p.holdingNPC.id == 31 then
			for  k,v in ipairs(newBGOSystem.getIntersecting(p.x, p.y, p.x + p.width, p.y + p.height)) do
				if v.id == 35 and not v.isHidden then
					Level.winState(3)
					Audio.SeizeStream(p.section)
					Audio.MusicStop()
					SFX.play(31)
					keyhole.lockObj = v
					doStep2 = false
					break
				end
			end
		end
		
		if Level.winState() == 3 and not levelEnded then
			levelEnded = true

			local nearbyObj
			
			-- If Link, riding Yoshi, or can't otherwise reach the keyhole, warping is based on player position
			if p:mem(0x12, FIELD_BOOL) or  p:mem(0x108, FIELD_WORD) == 3 then
				nearbyObj = p
			
				-- Get all intersecting BGOs
				for  k2,v2 in ipairs(newBGOSystem.getIntersecting(p.x - 32, p.y - 32, p.x + p.width + 32, p.y + p.height + 32)) do
					
					-- If the BGO is a lock and not hidden, then that's the lock object and we can skip everything else
					if  v2.id == 35  and  not v2.isHidden  then
						keyhole.lockObj = v2
						doStep2 = false
						break
					end
				end	

				
			-- If Klonoa, check EVERY KEY EVER IN THE SECTION for keyhole overlap
			elseif p.character == CHARACTER_KLONOA  then
				
				for  k1,v1 in ipairs(NPC.get(31, p.section))  do
					
					-- Non-hidden keys only
					if  not v1:mem(0x40, FIELD_BOOL)  then
						
						-- Get all intersecting BGOs
						for  k2,v2 in ipairs(newBGOSystem.getIntersecting(v1.x, v1.y, v1.x + v1.width, v1.y + v1.height)) do
							
							-- If the BGO is a lock and not hidden, then that's the lock object and we can skip everything else
							if  v2.id == 35  and  not v2.isHidden  then
								keyhole.lockObj = v2
								doStep2 = false
								break
							end
						end				
						if keyhole.lockObj ~= nil then  
							break
						end
					end
					if keyhole.lockObj ~= nil then  
						break  
					end
				end
			
			-- Otherwise, is based on the held key's position
			elseif p.holdingNPC then
				nearbyObj = p.holdingNPC
			
			--if all else fails, pick the player position
			else
				nearbyObj = p
			end
			
			-- Get the lock from the reference instance
			if doStep2 then
				local minDist = mathhuge
				for k,v in ipairs(newBGOSystem.getIntersecting(nearbyObj.x, nearbyObj.y, nearbyObj.x+nearbyObj.width, nearbyObj.y+nearbyObj.height)) do
					local w1,h1 = v.x-nearbyObj.x, v.y-nearbyObj.y
					local dist = mathsqrt(w1^2 + h1^2)
					if dist < minDist and v.id == 35 and not v.isHidden then
						keyhole.lockObj = v
						minDist = dist
					end
				end
			end
		end
	end
		
	if levelEnded and keyhole.animationEnabled then
		keyhole.counter = keyhole.counter + 1
		
		if      keyhole.counter < 60  then
			keyhole.size = 5*(keyhole.counter/60)
		elseif  keyhole.counter < 120  then
			keyhole.size = 5
		elseif  keyhole.counter == 120 then
			i = 1
			
		elseif  keyhole.counter < 180  then
			keyhole.mask = true
			if  keyhole.lockObj ~= nil  then
				keyhole.lockObj.isHidden = true
			end
			keyhole.size = 5 - 5*((keyhole.counter-120)/60)
		else
			keyhole.size = 0
		end
		
		frameBuffer:captureAt (-55.1)
		keyhole.render(keyhole.size, keyhole.mask, cameraIndex)
	end
end

function keyhole.render (scale, mask)
	local lockObj = keyhole.lockObj or player

	-- Determine the keyhole position
	local midX,midY = worldToScreen(lockObj.x+0.5*lockObj.width, lockObj.y+0.5*lockObj.height)
	local midY2 = midY-30*scale
	
	-- Calculate the relative points of the lock
	local lockPoints = {}
	
		for  k,v in ipairs (keyhole.lockOffsets)  do
			if  k%2 == 0  then
				lockPoints[k] = midY + v*scale
			else
				lockPoints[k] = midX + v*scale
			end
		end

		
	-- Update the mesh points	
	local meshPoints = {}
	
	-- Cut out the lock
	if  mask  then
		local l,r,t,b,mx,my = -800, 1600, -600, 1200, 400,300
		
		-- Get the bottom half of the lock
		meshPoints = {  r,t, lockPoints[#lockPoints-3],lockPoints[#lockPoints-2], r,b,
						r,b, lockPoints[#lockPoints-3],lockPoints[#lockPoints-2], lockPoints[#lockPoints-1],lockPoints[#lockPoints],
						r,b, lockPoints[#lockPoints-1],lockPoints[#lockPoints], lockPoints[1],lockPoints[2],
						r,b, lockPoints[1],lockPoints[2], l,b,
						l,b, lockPoints[1],lockPoints[2], lockPoints[3],lockPoints[4],
						l,b, lockPoints[3],lockPoints[4], lockPoints[5],lockPoints[6],
						l,b, lockPoints[5],lockPoints[6], l,t--,
					 }
		
		-- Attempt to automate the triangulation of the circular part
		local cmx, cmy = midX,  midY - (keyhole.circleMidY * scale)
		local ct,cb = cmy + (keyhole.circleMidY - keyhole.radius) * scale,  cmy + (keyhole.circleMidY + keyhole.radius) * scale
		local cl,cr = cmx - (keyhole.radius * scale), cmx + (keyhole.radius * scale)
		
		for  i=5, #lockPoints-5, 2  do
			
			-- Determine the corners
			local cornerX1 = l
			if  lockPoints[i] > cmx  then
				cornerX1 = r
			end
			local cornerY1 = t
			if  lockPoints[i+1] > cmy  then
				cornerY1 = b
			end
			local cornerX2 = l
			if  lockPoints[i+2] > cmx  then
				cornerX2 = r
			end
			local cornerY2 = t
			if  lockPoints[i+3] > cmy  then
				cornerY2 = b
			end

			-- Insert tri to fill the gap between switching corners if necessary
			if  cornerX1 ~= cornerX2  or  cornerY1 ~= cornerY2  then
				tableinsert (meshPoints, cornerX1)
				tableinsert (meshPoints, cornerY1)
				
				tableinsert (meshPoints, lockPoints[i])
				tableinsert (meshPoints, lockPoints[i+1])
				
				tableinsert (meshPoints, cornerX2)
				tableinsert (meshPoints, cornerY2)
			end

			
			-- Insert the tri with the line segment to the nearest corner
			tableinsert (meshPoints, cornerX2)
			tableinsert (meshPoints, cornerY2)
			
			tableinsert (meshPoints, lockPoints[i])
			tableinsert (meshPoints, lockPoints[i+1])
			
			tableinsert (meshPoints, lockPoints[i+2])
			tableinsert (meshPoints, lockPoints[i+3])
		end
	

	-- Draw just the lock
	else
		meshPoints = {lockPoints[1],lockPoints[2]}
		local i = 3
		while  i+1 <= #lockPoints  do
			tableinsert (meshPoints, lockPoints[i])
			tableinsert (meshPoints, lockPoints[i+1])
			tableinsert (meshPoints, midX)
			tableinsert (meshPoints, midY2)
			tableinsert (meshPoints, lockPoints[i])
			tableinsert (meshPoints, lockPoints[i+1])
			i = i+2
		end
		local cur = #meshPoints
		meshPoints[cur+1] = lockPoints[1]
		meshPoints[cur+2] = lockPoints[2]
	end	
	
	-- UVs
	local vertColors = {}
	local uvPoints = {}
	for  i=1,#meshPoints-1,2  do
		uvPoints[i] = meshPoints[i]/camera.width
		uvPoints[i+1] = meshPoints[i+1]/camera.height
	end
	
	-- vertex colors (for debugging)
	for i=1,#uvPoints  do
		vertColors[2*(i-1)+1] = RNG.random(10)/10
		vertColors[2*(i-1)+2] = RNG.random(10)/10
	end
	
	-- Draw the lock
	if  mask  then
		Graphics.drawScreen{color=Color.black, priority = -55.1}
		if  scale > 0  then
			Graphics.glDraw {vertexCoords=meshPoints, texture=frameBuffer, textureCoords=uvPoints, primitive=Graphics.GL_TRIANGLE, priority=-24.9}
		else
			Graphics.drawScreen{texture=frameBuffer, priority = -24.9}
		end
	else
		Graphics.glDraw {vertexCoords=meshPoints, primitive=Graphics.GL_TRIANGLE_STRIP, color={0,0,0,1}, priority=-56}
	end
end

return keyhole