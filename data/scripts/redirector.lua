local redirector = {
	UP = 191,
	DOWN = 192,
	LEFT = 193,
	RIGHT = 194,
	UP_LEFT = 195,
	UP_RIGHT = 196,
	DOWN_RIGHT = 197,
	DOWN_LEFT = 198,
	TERMINUS = 199,
	TOGGLER = 221, TOGGLE = 221,
	SOLIDTOGGLER = 222, SOLIDTOGGLE = 222,
}

-- ID map
do
	local r = redirector
	redirector.MAP = {
		[r.UP] = 1,
		[r.DOWN] = 1,
		[r.LEFT] = 1,
		[r.RIGHT] = 1,
		[r.UP_LEFT] = 2,
		[r.UP_RIGHT] = 2,
		[r.DOWN_RIGHT] = 2,
		[r.DOWN_LEFT] = 2,
		[r.TERMINUS] = 3,
		[r.TOGGLER] = 4,
		[r.SOLIDTOGGLER] = 4
	}
end

-- Vector map
do
	local vectr = require("vectr")
	local r = redirector
	local v2 = vectr.v2
	redirector.VECTORS = {
		[r.UP] = v2(0, -1),
		[r.DOWN] = v2(0, 1),
		[r.LEFT] = v2(-1, 0),
		[r.RIGHT] = v2(1, 0),
		[r.UP_LEFT] = v2(-1, -1),
		[r.UP_RIGHT] = v2(1, -1),
		[r.DOWN_RIGHT] = v2(1, 1),
		[r.DOWN_LEFT] = v2(-1, 1),
		[r.TOGGLER] = v2(0, 0),
		[r.SOLIDTOGGLER] = v2(0, 0),
	}
end

return redirector