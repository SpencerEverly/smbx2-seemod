local pAnim = {}

registerEvent(pAnim, "onTick");
registerEvent(pAnim, "onCameraDraw", "onCameraDraw", true);

local playerAnims = {};
local playerFrame = {};

local playerslist = {};

local anim_mt = {};
anim_mt.__index = anim_mt;

local function initPlayer(idx)
	if(not playerAnims[idx]) then
		playerAnims[idx] = {};
		table.insert(playerslist,idx);
	end
end

function pAnim.play(p, anim, speed, loop, priority, absolute)
	if(anim[1] == nil) then
		speed = anim.speed;
		loop = anim.loop;
		priority = anim.priority;
		absolute = anim.absolute;
		anim = anim.anim or anim.animation;
	end
	speed = speed or 8;
	if(loop == nil) then
		loop = true;
	end
	absolute = absolute or false;

	local idx = p.idx;
	
	local inst = {anim = anim, speed = speed, loop = loop, frame = 1, framecounter = 0, priority = priority, absolute = absolute, paused = false, isValid = true, _pid = idx};
	setmetatable(inst, anim_mt);
	initPlayer(idx);
	
	if(priority == nil) then
		if(#playerAnims[idx] > 0) then
			inst.priority = playerAnims[idx][#playerAnims[idx]].priority;
		else
			inst.priority = 0;
		end
		table.insert(playerAnims[idx], inst);
	elseif(#playerAnims[idx] > 0) then
		for i = 1,#playerAnims[idx] do
			if(priority < playerAnims[idx][i].priority) then
				table.insert(playerAnims[idx], i-1, inst);
			end
		end
	else
		table.insert(playerAnims[idx], inst);
	end
	
	return inst;
end

function pAnim.setFrame(p, idx, absolute)
	local pidx = p.idx;
	if(absolute and p.FacingDirection == -1) then
		idx = -idx;
	end
	initPlayer(pidx);
	playerFrame[pidx] = idx;
end

function pAnim.convertFrame(f, direction)
	direction = direction or 1;
	if(direction > 0) then
		return math.floor((f-1)/10)+5, (f-1)%10;
	else
		return 4-math.floor((f)/10), 9-(f)%10;
	end
end

function pAnim.getFrame(p, absolute)
	local pidx = p.idx;
	if(absolute == nil) then
		absolute = false;
	end
	local f = playerFrame[pidx] or p:mem(0x114, FIELD_WORD);
	
	if(absolute) then
		return pAnim.convertFrame(f, p.direction);
	else
		return f;
	end
end

function anim_mt.pause(animinst)
	animinst.paused = true;
end

function anim_mt.resume(animinst)
	animinst.paused = false;
end

function anim_mt.isPlaying(animinst)
	return not animinst.paused and animinst.isValid;
end

function anim_mt.stop(animinst)
	if(playerAnims[animinst._pid] == nil) then
		return false;
	end
	
	for i = 1,#playerAnims[animinst._pid] do
		if(playerAnims[animinst._pid][i] == animinst) then
			table.remove(playerAnims[animinst._pid],i);
			animinst.isValid = false;
			return true;
		end
	end
	
	return false;
end

function anim_mt.update(inst) 
	if(not inst.paused) then
		inst.framecounter = inst.framecounter + 1;
		if(inst.framecounter > inst.speed) then
			inst.frame = inst.frame + 1;
			inst.framecounter = 0;
			if(inst.frame > #inst.anim) then
				if(not inst.loop) then
					return false;
				else
					inst.frame = 1;
				end
			end
		end
	end
	return true;
end

function pAnim.onTick()
	for _,idx in ipairs(playerslist) do
		local removalList = {};
		for k,v in ipairs(playerAnims[idx]) do
			if(not v:update()) then
				table.insert(removalList, k);
			end
		end
		for i = #removalList,1,-1 do
			table.remove(playerAnims[idx], removalList[i]);
		end
	end
end

function pAnim.onCameraDraw(idx)
	if idx ~= 1 then return end
	local i = 1
	while i <= #playerslist do
		local idx = playerslist[i]
		local p = Player(idx)
		if p.isValid then
			if(playerFrame[idx] ~= nil) then
				p:mem(0x114, FIELD_WORD, playerFrame[idx]);
				playerFrame[idx] = nil;
			elseif(#playerAnims[idx] > 0) then
				local obj = playerAnims[idx][#playerAnims[idx]];
				local f = obj.anim[obj.frame];
				if(obj.absolute and Player(idx).FacingDirection == -1) then
					f = -f;
				end
				p:mem(0x114, FIELD_WORD, f);
			end
			i = i+1
		else
			table.remove(playerslist, i)
		end
	end
		
end

Player.playAnim = pAnim.play;
Player.setFrame = pAnim.setFrame;
Player.getFrame = pAnim.getFrame;
Player.convertFrame = pAnim.convertFrame;

return pAnim;