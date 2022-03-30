--***************************************************************************************
--                                                                                      *
--  mathematX.lua                                                                       *
--  v0.3a                                                                                *
--                                                                                      *
--***************************************************************************************
 local vectr = API.load ("vectr")
 
 
local mathematX = {}

	function mathematX.sign (number)
		if  number > 0  then
			return 1;
		elseif  number < 0  then
			return -1;
		else
			return 0;
		end
	end

	function mathematX.dirSign (direction)
		local dirMult = -1
		if direction == DIR_RIGHT then
				dirMult = 1
		end
	   
		return dirMult
	end

	
	function mathematX.clamp (minVal, maxVal, clampedVal)
		return math.max (minVal, math.min(maxVal, clampedVal))
	end
	
	--[[
	function mathematX.oldwrap(minVal, maxVal, value)
		local newVal = value
		local size = maxVal - minVal
		local wrapAmount = 0
		if      value > maxVal  then
			wrapAmount = math.abs(value-maxVal)%size
			newVal = minVal + wrapAmount
		elseif  value < minVal  then
			wrapAmount = math.abs(minVal-value)%size
			newVal = maxVal - wrapAmount
		end
		return newVal
	end]]
	
	function mathematX.wrap (minVal, maxVal, value)
		--Ensure same behaviour as older version
		if(((value - minVal) % (maxVal - minVal)) == 0) then 
			if(value > maxVal) then
				return minVal
			else
				return maxVal
			end
		else
			return (((value - minVal) % (maxVal - minVal)) + (maxVal - minVal)) % (maxVal - minVal) + minVal;
		end
	end
	
	
	function mathematX.lerp (minVal, maxVal, percentVal)
		return (1-percentVal) * minVal + percentVal*maxVal;
	end


	function mathematX.invLerp (minVal, maxVal, amountVal)                   
		return  math.min(1.00000, math.max(0.0000, math.abs(amountVal-minVal) / math.abs(maxVal - minVal)))
	end


	function mathematX.invLerpUnclamped (minVal, maxVal, amountVal)                   
		return  (amountVal-minVal) / (maxVal - minVal)
	end

	function mathematX.invLerpCycled (minVal, maxVal, amountVal)                   
		local raw = (amountVal-minVal) / (maxVal - minVal)		
		raw = raw%1
		
		return raw
	end

	
	function mathematX.tableMin (t)
		if #t == 0 then return nil, nil end
		local key, value = 1, t[1]
		for i = 2, #t do
			if t[i] < value then
				key, value = i, t[i]
			end
		end
		return key, value
	end
	
	function mathematX.tableMax (t)
		if #t == 0 then return nil, nil end
		local key, value = 1, t[1]
		for i = 2, #t do
			if t[i] > value then
				key, value = i, t[i]
			end
		end
		return key, value
	end

	function mathematX.tableMinMax (t)
		local minI, minVal = mathematX.tableMin (t)
		local maxI, maxVal = mathematX.tableMax (t)
		return minI, minVal, maxI, maxVal
	end
	
	
	function mathematX.magnitude (x,y)
		local vx = x
		local vy = y
	   
		local length = math.sqrt(vx * vx + vy * vy);
		return length
	end

	function mathematX.angle (x,y)
		return math.deg (math.atan2 (y,x)) - 90
	end
	
	function mathematX.normalize (x, y)
		local vx = x
		local vy = y
	   
		local length = mathematX.magnitude(x,y);

		-- normalize vector
		vx = vx/length;
		vy = vy/length;

		return vx,vy
	end


	function mathematX.rotatePoint (ptX, ptY, midX,midY, angle)
		v = vectr2.v2(0)
		v.x = ptX-x;
		v.y = ptY-y;
		v = v:rotate(angle);
		return v.x,v.y	
	end
	
	function mathematX.rotatePoints (pts, x,y, angle)
		local newPts = {}
		local v = vectr.v2 (0,0)
				
		-- Rotate points
		for i=1, (#pts), 2  do
			v.x = pts[i]-x
			v.y = pts[i+1]-y
			v = v:rotate(angle);
			
			local newX,newY = v.x,v.y
			
			newPts[i],newPts[i+1] = newX+x,newY+y
		end
		
		return newPts;
	end
	
	
	function mathematX.lengthdir_x (length, dir)
		return math.sin(math.rad(dir))*length
	end
	
	function mathematX.lengthdir_y (length, dir)
		return math.cos(math.rad(dir))*length
	end

	function mathematX.lengthdir (length, dir)
		return mathematX.lengthdir_x(length, dir), mathematX.lengthdir_y(length, dir)
	end

	

	function mathematX.rotateVector (xMid, yMid, xOff, yOff, angleAdd)
		angleAdd = (angleAdd) * (math.pi/180); -- Convert to radians
	
		local newX = xMid + math.cos(angleAdd) * (xOff - xMid) - math.sin(angleAdd) * (yOff - yMid);
		local newY = yMid + math.sin(angleAdd) * (xOff - xMid) + math.cos(angleAdd) * (yOff - yMid);
 
		return newX,newY
		
	end
	



	function mathematX.intToHexString (hexVal, places)
		places = places or "08"
		return string.format("%"..places.."x", hexVal)
	end

	function mathematX.hexStringToInt (hexString)
		return tonumber(hexString, 16)
	end

	function mathematX.hexColorToTable (hexVal)
		local stringVal = mathematX.intToHexString (hexVal)
		local r, g, b, a = tonumber("0x"..stringVal:sub(1,2)), tonumber("0x"..stringVal:sub(3,4)), tonumber("0x"..stringVal:sub(5,6)), tonumber("0x"..stringVal:sub(7,8))
		
		return {r/255, g/255, b/255, a/255};
	end

	function mathematX.rgbaTableToHex (tableCol)
		local stringVal = "0x"..mathematX.intToHexString(tableCol[1]*255, "02")..mathematX.intToHexString(tableCol[2]*255, "02")..mathematX.intToHexString(tableCol[3]*255, "02")..mathematX.intToHexString(tableCol[4]*255, "02")
		local number = mathematX.hexStringToInt (stringVal)
		
		return number, stringVal;
	end
	
return mathematX
