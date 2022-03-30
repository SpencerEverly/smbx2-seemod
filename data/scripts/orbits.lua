--[[
		   _ _ _ _ _
 _ _ _ _  /O	  o \  _ _ _ _
/  _ _ _ /		o	 \ _ _ _  \
| /	    |	O		 C|     \  \
| \_ _ _|		o     |_ _ _/  /
\_ _ _ _ \	0	 o	 / _ _ _ _/
	      \_ _ _ _ _/ RBITS.lua v2]]

-- @author PixelPest

local colliders = require("colliders");

local orbits = {};

orbits.DEFAULT_RADIUS = 96; -- the default radius of all orbits if not specified
orbits.DEFAULT_CENTERID = 630; -- default orbit center ID (the SMB3 dungeon stone ball)
orbits.DEFAULT_ROTATIONSPEED = 1; -- the default speed of rotation (in revolutions per second)

math.randomseed(os.time());

local Orbit = {};
Orbit.orbits = {};

local orbitMetatable = {__index = Orbit};

--- Creator function for orbits within the Orbit class.
-- Required named args:
-- x, y
-- or
-- attachToNPC (NPC object or {x = x-position, y = y-position, id = NPC ID})
-- and
-- section
-- Other named args:
-- speedX (default: 0), speedY (default: 0)
-- radius (default: orbits.DEFAULT_RADIUS (96)), radiusX, radiusY
-- id (NPC ID of orbiting NPCs; default: 10)
-- number (default: 4)
-- rotationSpeed (speed of rotation (in revolutions per second); default: orbits.DEFAULT_ROTATIONSPEED (1))
-- friendly (makes the orbiting NPCs friendly (true) or unfriendly (false); default: false)
-- centerID (NPC ID of the block to place in the center of the orbiting NPCs; default: orbits.DEFAULT_CENTERID (630))
-- placeCenter (if true places a block with the ID centerID in the center of the orbiting NPCs; default: false)
-- angleDegs, angleRads (the angle at which each successive NPC is offset from its default position upon being spawned; default: 0)
-- Accessible after instantiation within an Orbit class object:
-- attachedNPC (if attachToNPC was defined, this holds a reference to the NPC acting as the center of the orbit)
-- orbitingNPCs (contains a table of all of the NPCs in the orbit)
-- onscreen (whether or not the orbit is on or offscreen)
-- startPoints, countX, countY, initialized (these are not very useful)
-- @param args Table of named args
-- @return Orbit class object
function Orbit.new(args)
	local t = setmetatable({}, orbitMetatable);

	t.uid = math.random(); -- generate a unique identifier for the orbit

	-- determining the position of the orbit

	t.layer = Layer.get(args.layer or "Default")

	if (args.x ~= nil) and (args.y ~= nil) then
		t.x = args.x;
		t.y = args.y;

		if args.speedX ~= nil then
			t.speedX = args.speedX;
		else
			t.speedX = 0;
		end

		if args.speedY ~= nil then
			t.speedY = args.speedY;
		else
			t.speedY = 0;
		end
	elseif (args.attachToNPC ~= nil) then
		local foundNPC;

		if type(args.attachToNPC) == "NPC" then
			foundNPC = args.attachToNPC;
		else
			Misc.warn("Invalid type passed to orbits attachToNPC: "..type(args.attachToNPC), 2)
		end
		--[[
		elseif (type(args.attachToNPC) == "table") and (not args.attachToNPC:mem(0x64, FIELD_BOOL)) then
			for _, v in ipairs(NPC.getIntersecting(args.attachToNPC.x - 2, args.attachToNPC.y - 2, args.attachToNPC.x + 2, args.attachToNPC.y + 2)) do
				if v.id == args.attachToNPC.id and not v:mem(0x64, FIELD_BOOL) then
					foundNPC = v;

					break;
				else
					error("No NPC found to follow. Check x and y-values as well as the ID specified.");
				end
			end
		elseif (type(args.attachToNPC) == "userdata") or ((type(args.attachToNPC) == "table") and (not args.attachToNPC.isGenerator)) then
			foundNPC = args.attachToNPC;
		end]]

		t.attachedNPC = foundNPC;

		local npc = foundNPC;

		npc.data._orbits = {};

		local data = npc.data._orbits;

		data.orbitCenter = t.uid;
	else
		error("Parameters x and y must be defined by some means.");
	end

	t.section = args.section or error("Section must be defined.");

	-- determining the radius/radii of the orbit

	if args.radius ~= nil then
		t.radius = args.radius;
	elseif (args.radiusX ~= nil) and (args.radiusY ~= nil) then
		-- for elliptical shapes horizontal and vertical radii can be specified

		t.radiusX = args.radiusX;
		t.radiusY = args.radiusY;
	else
		-- if a radius is not specified the default will be used

		t.radius = orbits.DEFAULT_RADIUS;
	end

	-- other properties

	t.id = args.id or 10;
	t.number = args.number or 4;
	t.rotationSpeed = args.speed or args.rotationSpeed or orbits.DEFAULT_ROTATIONSPEED;

	t.friendly = args.friendly or false;

	if (args.placeCenter) and (t.speedX == 0) and (t.speedY == 0) and (args.attachToNPC == nil) then
		-- can place a dungeon stone ball in the middle, but will only do so if the orbit is not moving or attached to an NPC

		local blockID;

		if args.centerID == nil then
			blockID = orbits.DEFAULT_CENTERID;
		else
			blockID = args.centerID;
		end

		t.centerID = blockID;
	end

	if args.angleDegs ~= nil then
		t.angleRads = args.angleDegs*(math.pi/180);
	elseif args.angleRads ~= nil then
		t.angleRads = args.angleRads;
	end

	-- the following values have no args associated with them and are just for handling purposes

	-- determine the angles to the center at which the NPCs start

	t.startPoints = {};

	for i = 1, t.number do
		table.insert(t.startPoints, (2*i*math.pi)/t.number + (t.angleRads or t.angleDegs or 0));
	end

	t.countX = 0;
	t.countY = 0;
	t.initialized = false;

	if (player.character == 5) and (t.id == 10) then
		t.id = 251;
	end

	t.orbitingNPCs = {};

	table.insert(Orbit.orbits, t);

	return t;
end

--- Orbit class object destructor function.
-- @param poof Whether or not to show the poof animation (default: false).
function Orbit:destroy(poof)
	for _, npc in ipairs(self.orbitingNPCs) do
		if npc.isValid then
			if poof then
				Animation.spawn(10, npc.x + 0.5*npc.width - 16, npc.y + 0.5*npc.height - 16); --poof effects are fun (and default)
			end

			npc:kill(HARM_TYPE_OFFSCREEN);
		end
	end
end

-- provide direct references to the Orbit class and Orbit class constructor function for the orbits library

orbits.Orbit = Orbit;
orbits.new = Orbit.new;

function orbits.onInitAPI()
	registerEvent(orbits, "onStart");
	registerEvent(orbits, "onTickEnd");
end

local movementGracePeriod = 2

function orbits.onStart()
	for _, npc in ipairs(NPC.get()) do

		if (not npc.isGenerator) and (npc.data.orbit) then
			local orbit = npc.data.orbit;

			orbit.id = npc.id;
			orbit.section = npc:mem(0x146, FIELD_WORD);

			if orbit.x == nil then
				orbit.x, orbit.y = npc.x + npc.width/2, npc.y + npc.height/2;
			end

			npc.data._orbits = orbits.new(orbit);
			npc.data.orbit = nil;

			npc:kill(HARM_TYPE_OFFSCREEN);
		end
	end
end

function orbits.onTickEnd()
	for _, orbit in ipairs(Orbit.orbits) do
		local centerX, centerY;
		local radiusX, radiusY;

		-- determine the center of the circle

		if orbit.attachedNPC == nil then
			centerX, centerY = orbit.x, orbit.y;

			if orbit.centerID ~= nil then
				local b = Block.spawn(orbit.centerID, orbit.x - Block.config[orbit.centerID].width * 0.5, orbit.y - Block.config[orbit.centerID].height * 0.5);
				orbit.centerID = nil;
				orbit.centerBlock = b
				--b.layerName = orbit.layer.layerName
			end
		elseif orbit.attachedNPC.isValid then
			centerX, centerY = orbit.attachedNPC.x + 0.5*orbit.attachedNPC.width, orbit.attachedNPC.y + 0.5*orbit.attachedNPC.height;
		end

		if centerX == nil then
			-- destroy orbit if there is no centerX of the orbit (usually upon the followed NPC being killed)

			orbit:destroy();
		else
			-- determine the radii of the orbit (horizontal and vertical)

			if orbit.radius ~= nil then
				radiusX, radiusY = orbit.radius, orbit.radius;
			else
				radiusX, radiusY = orbit.radiusX, orbit.radiusY;
			end

			if not orbit.initialized then
				-- spawn NPCs (first tick only)

				for i = 1, orbit.number do
					local rotationCounter = orbit.startPoints[i];

					local spawnedNPC = NPC.spawn(orbit.id, centerX + radiusX*math.cos(rotationCounter), centerY + radiusY*math.cos(rotationCounter), orbit.section, true, true)

					spawnedNPC.layerName = orbit.layer.layerName;

					if orbit.attachedNPC and orbit.attachedNPC.isValid then
						spawnedNPC.layerName = orbit.attachedNPC.layerName
					end

					spawnedNPC.data._orbits = {}; -- data for orbits.lua is stored in NPC.data._orbits

					local data = spawnedNPC.data._orbits;

					-- initialize data fields

					data.rotationCounter = rotationCounter;

					-- set NPC properties based on orbit properties

					if orbit.friendly then
						spawnedNPC.friendly = true;
					end

					table.insert(orbit.orbitingNPCs, spawnedNPC);
				end

				orbit.initialized = true;
			end

			local offscreenCount = 0; -- used to determine if the orbit is on or offscreen

			-- counters and movement for NPCs in orbits

			for i=#orbit.orbitingNPCs, 1, -1 do
				local npc = orbit.orbitingNPCs[i]
				if npc.isValid then
					local data = npc.data._orbits;

					if (player.holdingNPC ~= nil) and (player.holdingNPC == npc) then
						-- remove NPCs from orbits that are held by the player
						table.remove(orbit.orbitingNPCs, i)
						data.orbit = nil;
					elseif (not data.orbitCenter) or ((data.orbitCenter ~= nil) and (data.orbitCenter ~= orbit.uid)) then
						if centerX == nil then
							-- kill the NPC if there is no centerX of the orbit (usually upon the followed NPC being killed)

							Animation.spawn(10, npc.x + 0.5*npc.width - 16, npc.y + 0.5*npc.height - 16);
							npc:kill(HARM_TYPE_OFFSCREEN);
						else
							if npc:mem(0x12A, FIELD_WORD) <= 1 then
								-- increase the offscreen count if the NPC is offscreen

								offscreenCount = offscreenCount + 1;
							end
						end
					end
				end
			end

			if (player.holdingNPC ~= nil) and (player.holdingNPC == orbit.attachedNPC) then
				-- remove NPCs from orbits that are held by the player
				orbit.attachedNPC = nil
				orbit.attachedNPC.data._orbits.orbit = nil;
				centerX = nil
			end

			-- determine whether the orbit is onscreen or not (onscreen or offscreen)
			-- if one NPC in the orbit or the followed NPC is onscreen the orbit is onscreen

			local orbitTechnicallyOnscreen = false

			if centerX + radiusX >= camera.x and centerX - radiusX <= camera.x + camera.width and centerY + radiusY >= camera.y and centerY - radiusY <= camera.y + camera.height then
				orbitTechnicallyOnscreen = true
			end

			if (offscreenCount < #orbit.orbitingNPCs) or ((orbit.attachedNPC) and orbit.attachedNPC:mem(0x12A, FIELD_WORD) > 0) or orbitTechnicallyOnscreen then
				-- movement, etc. if the orbit is onscreen

				if (orbit.x ~= nil) and (orbit.y ~= nil) then
					-- increment necessary counters when onscreen

					orbit.countX = orbit.countX + orbit.speedX;
					orbit.countY = orbit.countY + orbit.speedY;
					orbit.x = orbit.x + orbit.speedX;
					orbit.y = orbit.y + orbit.speedY;
					if orbit.centerBlock then
						orbit.centerBlock.x = orbit.centerBlock.x + orbit.speedX
						orbit.centerBlock.y = orbit.centerBlock.y + orbit.speedY
					end
					if (not orbit.layer:isPaused()) and movementGracePeriod > 0 then
						orbit.x = orbit.x + orbit.layer.speedX
						orbit.y = orbit.y + orbit.layer.speedY
						if orbit.centerBlock then
							orbit.centerBlock.x = orbit.centerBlock.x + orbit.layer.speedX
							orbit.centerBlock.y = orbit.centerBlock.y + orbit.layer.speedY
						end
					end
				end
				
				for _, npc in ipairs(orbit.orbitingNPCs) do
					local data = npc.data._orbits;

					if npc.isValid then
						local max = npc:mem(0x12A, FIELD_WORD)
						npc:mem(0x12A, FIELD_WORD, math.max(2, max)); -- set the NPC onscreen for one tick

						-- convert the orbit's rotationSpeed field to a usable value

						local rotationSpeed = orbit.rotationSpeed;

						if math.abs(rotationSpeed) > 0 then
							rotationSpeed = rotationSpeed*2*math.pi/lunatime.toTicks(1);
						end

						if orbit.initialized then
							-- determine the current and immediately next positions of the NPC

							local x1 = centerX + radiusX*math.cos(data.rotationCounter) - 0.5*npc.width;
							local y1 = centerY + radiusY*math.sin(data.rotationCounter) - 0.5*npc.height;

							if (not NPC.config[npc.id].isWalker) and (NPC.config[npc.id].playerblocktop) and (player:mem(0x34, FIELD_WORD) ~= 2) then
								-- set the NPC's speed to interact properly with the player

								local x2 = centerX + radiusX*math.cos(data.rotationCounter + rotationSpeed) - 0.5*npc.width;
								local y2 = centerY + radiusY*math.sin(data.rotationCounter + rotationSpeed) - 0.5*npc.height;

								local speedX, speedY;

								if orbit.attachedNPC then
									speedX, speedY = orbit.attachedNPC.speedX, orbit.attachedNPC.speedY;
								else
									speedX, speedY = orbit.speedX, orbit.speedY;
								end

								npc.speedX = x2 - x1 + speedX;
								npc.speedY = y2 - y1 + speedY;
							elseif not NPC.config[npc.id].nogravity then
								npc.speedX = 0
								npc.speedY = -Defines.npc_grav
							end

							-- make sure the NPC is in the proper position

							npc.x = x1;
							npc.y = y1;

							-- increment the NPC's rotation counter

							if not Defines.levelFreeze then
								data.rotationCounter = data.rotationCounter + rotationSpeed;
							end
						end
					end
				end

				if (orbit.attachedNPC) and (orbit.attachedNPC.isValid) then
					-- if there is an attached NPC make sure it is also onscreen for one tick

					local max = orbit.attachedNPC:mem(0x12A, FIELD_WORD)
					orbit.attachedNPC:mem(0x12A, FIELD_WORD, math.max(2, max));
				end
				orbit.onscreen = 1
			else
				-- manage the orbit going/being offscreen
				if orbit.onscreen ~= 0 then
					orbit.onscreen = 0

					for k, npc in ipairs(orbit.orbitingNPCs) do
						if npc.isValid then
							npc:mem(0xDC, FIELD_WORD, npc.id);
							npc:mem(0x12A, FIELD_WORD, -1);
						end
					end

					if orbit.attachedNPC and orbit.attachedNPC.isValid then
						-- if there is an attached NPC set it offscreen and make it able to respawn

						orbit.attachedNPC:mem(0xDC, FIELD_WORD, orbit.attachedNPC.id);
						orbit.attachedNPC:mem(0x12A, FIELD_WORD, -1);
					end
				end
			end
		end
	end
	if Defines.levelFreeze then
		movementGracePeriod = movementGracePeriod - 1
	else
		movementGracePeriod = 2
	end
end

return orbits
