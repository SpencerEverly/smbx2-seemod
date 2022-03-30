local animDefaults = {}

local numberOfPowerupStates = 7
local pausedFrame = {}

function animDefaults.init(character)
	animDefaults[character] = {}
	
	for i=1, numberOfPowerupStates do
		animDefaults[character][i] = {}
	end
end

--MARIO--
animDefaults.init(CHARACTER_MARIO)
animDefaults[CHARACTER_MARIO][1] = {
	idle = {1},
	walk = {1,2},
	jump = {3},
	turn = {4},
	hold = {5},
	holdwalk = {5,6},
	holdjump = {6},
	door = {13},
	pipe = {15},
	grab = {22, 23},
	slide = {24},
	climb = {25, 26},
	yoshi = {30},
	yoshiduck = {31},
	swim = {40, 41, 42, 43},
	swimidle = {40, 41},
	spin = {1,13, -1, 15}
}

animDefaults[CHARACTER_MARIO][2] = {
	idle = {1},
	walk = {1,2,3},
	jump = {4},
	fall = {5},
	turn = {6},
	duck = {7},
	hold = {8},
	holdwalk = {8,9,10},
	holdjump = {10},
	door = {13},
	pipe = {15},
	grab = {22, 23},
	slide = {24},
	climb = {25, 26},
	yoshi = {30},
	yoshiduck = {31},
	swim = {40, 41, 42, 43, 44},
	swimidle = {40, 41, 22},
	spin = {1,13, -1, 15}
}

animDefaults[CHARACTER_MARIO][3] = table.clone(animDefaults[CHARACTER_MARIO][2])
animDefaults[CHARACTER_MARIO][3].fire = {12, 11}

animDefaults[CHARACTER_MARIO][4] = table.clone(animDefaults[CHARACTER_MARIO][2])
animDefaults[CHARACTER_MARIO][4].hover = {11, 3, 5}
animDefaults[CHARACTER_MARIO][4].spin = {12, 13, 14, 15}
animDefaults[CHARACTER_MARIO][4].pspeed = {16, 17, 18}
animDefaults[CHARACTER_MARIO][4].fly = {19, 20, 21}

animDefaults[CHARACTER_MARIO][5] = table.clone(animDefaults[CHARACTER_MARIO][4])
animDefaults[CHARACTER_MARIO][5].statue = {0}


animDefaults[CHARACTER_MARIO][6] = table.clone(animDefaults[CHARACTER_MARIO][3])

animDefaults[CHARACTER_MARIO][7] = table.clone(animDefaults[CHARACTER_MARIO][3])

--LUIGI--
animDefaults[CHARACTER_LUIGI] = table.deepclone(animDefaults[CHARACTER_MARIO])

--PEACH--
animDefaults.init(CHARACTER_PEACH)
animDefaults[CHARACTER_PEACH][1] = {
	idle = {1},
	walk = {1,2, 3},
	jump = {4},
	hover = {4, 5},
	fall = {5},
	turn = {6},
	duck = {7},
	hold = {8},
	holdwalk = {8,9,10},
	holdjump = {10},
	door = {13},
	pipe = {15},
	grab = {22, 23},
	climb = {25, 26},
	holdduck = {27}
}
animDefaults[CHARACTER_PEACH][2] = table.clone(animDefaults[CHARACTER_PEACH][1])

animDefaults[CHARACTER_PEACH][3] = table.clone(animDefaults[CHARACTER_PEACH][1])
animDefaults[CHARACTER_PEACH][3].fire = {12, 11}

animDefaults[CHARACTER_PEACH][4] = table.clone(animDefaults[CHARACTER_PEACH][1])
animDefaults[CHARACTER_PEACH][4].spin = {12, 13, 14, 15}
animDefaults[CHARACTER_PEACH][4].pspeed = {1, 2, 3}
animDefaults[CHARACTER_PEACH][4].fly = {19, 20, 21}

animDefaults[CHARACTER_PEACH][5] = table.clone(animDefaults[CHARACTER_PEACH][4])
animDefaults[CHARACTER_PEACH][5].statue = {0}

animDefaults[CHARACTER_PEACH][6] = table.clone(animDefaults[CHARACTER_PEACH][3])
animDefaults[CHARACTER_PEACH][7] = table.clone(animDefaults[CHARACTER_PEACH][3])

--TOAD--
animDefaults.init(CHARACTER_TOAD)
animDefaults[CHARACTER_TOAD][1] = table.clone(animDefaults[CHARACTER_PEACH][1])
animDefaults[CHARACTER_TOAD][1].spin = {1, 13, -1, 15}

animDefaults[CHARACTER_TOAD][2] = table.clone(animDefaults[CHARACTER_TOAD][1])
animDefaults[CHARACTER_TOAD][2].fire = {12, 11}

animDefaults[CHARACTER_TOAD][3] = table.clone(animDefaults[CHARACTER_TOAD][2])

animDefaults[CHARACTER_TOAD][4] = table.clone(animDefaults[CHARACTER_TOAD][1])
animDefaults[CHARACTER_TOAD][4].holdhover = {10, 11}
animDefaults[CHARACTER_TOAD][4].spin = {12, 13, 14, 15}
animDefaults[CHARACTER_TOAD][4].pspeed = {16,17,18}
animDefaults[CHARACTER_TOAD][4].fly = {19,20,21}
animDefaults[CHARACTER_TOAD][4].slide = {24}
animDefaults[CHARACTER_TOAD][4].yoshi = {30}
animDefaults[CHARACTER_TOAD][4].yoshiduck = {31}

animDefaults[CHARACTER_TOAD][5] = table.clone(animDefaults[CHARACTER_TOAD][4])
animDefaults[CHARACTER_TOAD][5].statue = {0}

animDefaults[CHARACTER_TOAD][6] = table.clone(animDefaults[CHARACTER_TOAD][2])
animDefaults[CHARACTER_TOAD][6].slide = {24}
animDefaults[CHARACTER_TOAD][6].yoshi = {30}
animDefaults[CHARACTER_TOAD][6].yoshiduck = {31}

animDefaults[CHARACTER_TOAD][7] = table.clone(animDefaults[CHARACTER_TOAD][2])

--LINK--
animDefaults.init(CHARACTER_LINK)
animDefaults[CHARACTER_LINK][1] = {
	idle = {1},
	walk = {2, 3, 4},
	jump = {5},
	fall = {5},
	slash = {6, 7},
	duck = {5},
	duckslash = {8},
	downstab = {9},
	upstab = {10},
	hurt = {11}
}
animDefaults[CHARACTER_LINK][2] = table.clone(animDefaults[CHARACTER_LINK][1])

animDefaults[CHARACTER_LINK][3] = table.clone(animDefaults[CHARACTER_LINK][1])

animDefaults[CHARACTER_LINK][4] = table.clone(animDefaults[CHARACTER_LINK][1])

animDefaults[CHARACTER_LINK][5] = table.clone(animDefaults[CHARACTER_LINK][1])
animDefaults[CHARACTER_TOAD][5].statue = {12}

animDefaults[CHARACTER_LINK][6] = table.clone(animDefaults[CHARACTER_LINK][1])

animDefaults[CHARACTER_LINK][7] = table.clone(animDefaults[CHARACTER_LINK][1])

return animDefaults