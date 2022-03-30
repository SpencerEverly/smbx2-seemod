local playerAnim = {}

local queue = {};
local animSet = {};
local pauseQueue = {};

local mt = {}
mt.__newindex =
function(tb,k,v) 
	for tk,_ in pairs(tb) do
		if(tk == k) then
			k = tk;
			break;
		end
	end
	rawset(tb,k,v);
end

mt.__index =
function(tb,k) 
	for tk,_ in pairs(tb) do
		if(tk == k) then
			k = tk;
			break;
		end
	end
	return rawget(tb,k);
end

setmetatable(queue, mt)
setmetatable(animSet, mt)

function playerAnim.onInitAPI()
	registerEvent(playerAnim,"onDraw","onDraw",true);
end

local Animation = {}
Animation.__index = Animation;



function playerAnim.Anim(x1,y1,x2,y2,speed)
	local a = {};
	if(type(x1) == "table") then
		speed = y1;
		a.frames = x1;
		if(#a.frames > 0) then
			if(type(a.frames[1])== "table") then
				a.absolute = true;
				for k,v in ipairs(a.frames) do
					if(v.x ~= nil) then
						a.frames[k] = (v.x*10+v.y)-49;
					else
						a.frames[k] = (v[1]*10+v[2])-49;
					end
				end
			end
		end
		a.speed = speed or 8;
	else
		if(y2 == nil) then -- index-based frames
			a.startFrame = x1;
			a.stopFrame = y1;
			a.absolute = false;
			a.speed = x2 or 8;
		else -- coordinate-based frames
			a.startFrame = (x1*10+y1)-49;
			a.stopFrame = (x2*10+y2)-49;
			a.absolute = true;
			a.speed = speed or 8;
		end
	end
	setmetatable(a,Animation)
	return a;
end

function Animation:getSpeed()
	if(pauseQueue[self] ~= nil) then
		return pauseQueue[self];
	else
		return self.speed;
	end
end

function Animation:setSpeed(x)
	if(pauseQueue[self] ~= nil) then
		pauseQueue[self] = x;
	else
		self.speed = x;
	end
end

function Animation:reverse()
	local newend = self.startFrame;
	self.startFrame = self.stopFrame;
	self.stopFrame = newend;
end

function Animation:play(p)
	playerAnim.playAnimation(p,self);
end

function Animation:stop(p)
	if(animSet[p] ~= nil and animSet[p].anim == self) then
		playerAnim.stopAnimation(p);
	end
end

function Animation:pause()
	pauseQueue[self] = self.speed;
	self.speed = 0;
end

function Animation:resume()
	if(pauseQueue[self] ~= nil) then
		self.speed = pauseQueue[self];
		pauseQueue[self] = nil;
	end
end

function Animation:isPlaying(p)
	return pauseQueue[self] == nil and animSet[p] ~= nil and animSet[p].anim == self
end

function Animation:togglePause()
	if(pauseQueue[self] ~= nil) then
		self:resume();
	else
		self:pause();
	end
end

function playerAnim.getFrameRaw(p, absolute)
	if(absolute == nil) then
		absolute = false;
	end
	if(absolute) then
		local base = p:mem(0x114,FIELD_WORD);
		if(p:mem(0x106,FIELD_WORD) > 0) then
			return math.floor((base-1)/10)+5, (base-1)%10;
		else
			return 4-math.floor((base)/10), 9-(base)%10;
		end
	else
		return p:mem(0x114,FIELD_WORD);
	end
end

function playerAnim.getFrame(p, absolute)
	if(absolute == nil) then
		absolute = false;
	end
	if(queue[p] == nil) then
		return playerAnim.getFrameRaw(p,absolute);
	else
		if(absolute) then
			local base = queue[p][1];
			if(p:mem(0x106,FIELD_WORD) > 0) then
				return math.floor((base-1)/10)+5, (base-1)%10;
			else
				return 4-math.floor((base)/10), 9-(base)%10;
			end
		else
			return queue[p][1];
		end
	end
end

function playerAnim.setFrame(p,x,y)
	if(y == nil) then
		queue[p] = {x,false};
	else
		queue[p] = {(x*10+y)-49,true};
	end
end

function playerAnim.playAnimation(p,a)
	if(a == nil) then
		animSet[p] = nil;
	else
		animSet[p] = {anim = a, frame = 0, counter = 0};
	end
end

function playerAnim.stopAnimation(p)
	animSet[p] = nil;
end

function playerAnim.onDraw()
	for k,v in pairs(animSet) do
		local dirmod = 1;
		if(v.anim.startFrame ~= nil) then
			if(v.anim.stopFrame < v.anim.startFrame) then
				dirmod = -1;
			end
		end
		if(v.anim.speed > 0) then
			if not Misc.isPaused() then
				v.counter = v.counter + 1;
				if(v.counter >= v.anim.speed) then
					if(v.anim.startFrame ~= nil) then
						v.frame = (v.frame+1)%(math.abs(v.anim.stopFrame-v.anim.startFrame)+1);
					else
						v.frame = (v.frame+1)%#v.anim.frames;
					end
					v.counter = 0;
				end
			end
		end
		if(queue[k] == nil) then
			if(v.anim.startFrame ~= nil) then
				queue[k] = {v.anim.startFrame + v.frame*dirmod, v.anim.absolute};
			else
				queue[k] = {v.anim.frames[v.frame+1], v.anim.absolute};
			end
		end
	end
	for k,v in pairs(queue) do
		local mod = 1;
		if(v[2]) then mod = k:mem(0x106,FIELD_WORD) end
		k:mem(0x114,FIELD_WORD,v[1]*mod);
		queue[k] = nil;
	end
end

return playerAnim;