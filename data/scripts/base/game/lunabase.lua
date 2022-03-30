SaveData.__launcher = SaveData.__launcher or {} --launcher customisation table

require("base/game/pluginManager");
require("animDefaults");
local ed = require("expandedDefines");
require("HUDOverride");
require("playerManager");
require("base/xmem");
require("base/audiomaster");

--Register Graphics.sprites (done here to ensure they're available early)
do
	Graphics.sprites.Register("hardcoded", "hardcoded-30-5")	--Load screen icon
	Graphics.sprites.Register("hardcoded", "hardcoded-30-6")	--Test menu icons
	Graphics.sprites.Register("hardcoded", "hardcoded-34-1")	--Menu up arrow
	Graphics.sprites.Register("hardcoded", "hardcoded-34-2")	--Menu down arrow
	Graphics.sprites.Register("hardcoded", "hardcoded-50-10")	--Text /
	Graphics.sprites.Register("hardcoded", "hardcoded-50-11")	--Text infinity
	Graphics.sprites.Register("hardcoded", "hardcoded-50-12")	--Text up arrow
	Graphics.sprites.Register("hardcoded", "hardcoded-50-13")	--Text down arrow
	Graphics.sprites.Register("hardcoded", "hardcoded-51-0")	--Starcoin uncollected
	Graphics.sprites.Register("hardcoded", "hardcoded-51-1")	--Starcoin collected
	Graphics.sprites.Register("hardcoded", "hardcoded-52")		--Timer icon
	Graphics.sprites.Register("hardcoded", "hardcoded-53-0")	--White noise
	Graphics.sprites.Register("hardcoded", "hardcoded-53-1")	--Perlin noise
	Graphics.sprites.Register("hardcoded", "hardcoded-53-2")	--Caustics
	Graphics.sprites.Register("hardcoded", "hardcoded-55")		--Default achievement icon
	Graphics.sprites.Register("hardcoded", "hardcoded-56")		--Large menu arrow
	Graphics.sprites.Register("hardcoded", "hardcoded-57-0")	--Controller config base
	Graphics.sprites.Register("hardcoded", "hardcoded-57-1")	--Controller config buttons
end

--Early load APIs for non-overworld
if(not isOverworld) then
	require("base/game/bgoconfig");
	require("base/game/betterbgo");
	require("base/game/bettereffects");
	
	require("base/darkness");
end

require("progress");
require("base/game/newcheats");
require("base/game/marioChallenge");
require("base/game/repl");
require("base/editorevents");
require("base/game/ctrlnotification");

if (not isOverworld) then
	local block_APIs = {
		"extensions/configextensions",            --for blocks without AI
		--"newblocks",
		--"breakingdirt",              --694, what's going on enjl
		--"clearpipe",                   --701-723,
		--"suits",                       --724-731/746-749
		--"synced",				   	   --1271-1278
	};
	for _,v in ipairs(block_APIs) do
		API.load("blocks/"..v);
	end
	local npc_APIs = {
		--"graf",                        --42/492/493 --YEEEEEEEEEEEEEEAH!!!!!!!!!!!!!
		"extensions/vanillabosses",               --HP support
		"extensions/configextensions",            --isheavy and stuff
		"extensions/flyingnpcplus",               --more options
		"extensions/waternpcplus",                --more options
		"extensions/shellnpcplus",                --more options
		--"swooper",                     --271 --yeah!!!
		--"starman",                     --292/559 -- npc-293 and 559.lua
		--"thwomps",                     --295/432/425/437
		--"bonyBeetle",                  --296
		--"maverickThwomp",              --295 --(Separate API for some compatibility stuff)
		--"booCircles",                  --294
		--"rebound",                   --297/298
		--"diagonals",                   --297/298
		--"magikoopa",                   --299/300
		--"thwimp",                    --301 -- This has been moved to npc-301.lua as an initial test
		--"blurp",                       --302
		--"parabeetle",                  --303/304
		--"torpedoTed",                  --305/306
		--"firesnake",                   --307/308
		--"montyMoles",                  --309
		--"starcoin",                    --310
		--"chargingChuck",               --311
		--"clappingChuck",               --312
		--"pitchingChuck",               --313/319
		--"splittingChuck",              --314
		--"bouncingChuck",               --315
		--"diggingChuck",                --316
		--"puntingChuck",                --318
		--"rocks",                       --320
		--"footballs",                   --321
		--"gasBubble",                   --322
		--"stretcherBoo",                --323/324
		--"grinders",                    --334/485-487
		--"engineblocks",                --335-338/533-536
		--"platforms",                    --339-343/476-484
		--"snakeBlock",                  --344
		--"panser",                      --345-348
		--"trouter",                     --350
		--"fryguy",                      --351/352
		--"bowserStatues",               --355/357
		--"hoppingFlame",                --358/359
		--"sumobros",                    --360-362
		--"seaMines",                    --363
		--"turnBlock",                   --364
		--"spike",                       --365/366
		--"smwMovingPlatforms",          --367
		--"mechakoopa",                  --368/369
		--"phanto",                      --370/625/626
		--"cobrats",                     --372/373
		--"flurry",                      --374
		--"ptooie",                      --375-377
		--"popupCoins",                  --378 --lol Pyro get wrecked ;) --Fik U Pixelpest! !
		--"shoegoomba",                  --379
		--"flyingSpiny",                 --380/381
		--"dinosaurs",                   --382-385
		--"ripvanfish",                  --386
		--"firebros",                    --389
		--"enemyfire",                   --390
		--"rockyWrench",                 --395/396
		--"berries",                     --397-399
		--"checkpoint",                  --400
		--"foo",                         --401
		--"hotFoot",                     --402
		--"fishbone",                    --406
		--"ninji",                       --407
		--"bobomb",                      --408/409
		--"minigameCloud",               --410/411
		--"hiddenItem",                  --412
		--"reznor",                      --413/414
		--"drybones",                    --415-417
		--"fuzzy",                       --420
		--"arrowLift",                   --418/419
		--"paddleWheel",                 --421/422
		--"megaSpike",                   --423/424
		--"megashroom",                  --425
		--"bowlingBall",                 --426
		--"megan",                       --427
		--"kingbill",                    --428/429
		--"chargedSpiny",                --431
		--"crate",                       --434
		--"ub_rang",                     --436
		--"billBlaster",                 --438/439
		--"bigSwitch",                   --440-443/445/450
		--"boohemoth",                   --444
		--"wiggler",                     --446-449
		--"smallSwitch",                 --451-454
		--"springs",                     --457/458
		--"dolphins",                    --459-461
		--"heart",                       --462
		--"cloudDrop",                   --463/464
		--"triggerbox",                  --465
		--"bigGoomba",                   --466/467
		--"clearpipe_npc",               --468
		--"snifits",                     --470/471
		--"waddledoo",                   --472/473
		--"filthcoating",                --488
		--"blert",                       --490
		--"monitorsShields",             --494-498
		--"asteron",                     --499/500
		--"birb",                        --501-504
		--"scuttlebug",                  --509/510
		--"newPlants",                   --511-525
		--"porcupo",                     --530
		--"grrrol",                      --531/532
		--"fliprus",                     --539/540
		--"mutantVine",                  --552-555
		--"multiArrowLift",              --556/557
		--"cherries",                    --558
		--"shyspring",                   --562
		--"tantrunt",                    --564
		--"rotaryLift",                  --570
		--"bombshellKoopa",              --578, 579
		--"bunbun",                      --580, 581
		--"bumper",                      --582
		--"reverseboo",                  --586
		--"diggerbeetle",                --587, 588
		--"iceblock",                    --589, 590
		--"launchBarrel",                --600-603
		--"lakitu",                      --610
		--"spiny",                       --611/612
		--"flutters",                    --613
		--"crate_spawnobj",			   --619
		--"playerrinkashooters"          --666, 667 --Aww, that's rad!
	};
	--there is a basis
	--for aligning with spaces
	--tabs are not fine
	--when you need to align
	for _,v in ipairs(npc_APIs) do
		API.load("NPCs/"..v);
	end
	
	-- Load npc-*.lua code
	local npcmanager = require("npcmanager")
	npcmanager.loadNpcCode()
	
	--After loading NPCs, load NPC.txt files
	NPC.config.loadAllTxt()
	
	-- Load block-*.lua code
	local blockmanager = require("blockmanager")
	blockmanager.loadBlockCode()

	-- Deja vu!
	Block.config.loadAllTxt()

	ed.initializeLists()
	
	require("tweaks/keyhole");
	require("redirector");
	require("base/game/tweaks");
	require("paralX2");
	require("orbits");
	require("base/game/sizable");
else
	require("base/game/switchpalace");
	require("maplevelanimator");
end

--Do stuff that has to be done extremely early in execution here
if (isOverworld or Section(player.section).musicID == 0) then
	Audio.MusicStop();
	Audio.ReleaseStream(-1);
end

if not isOverworld and GameData.SMBXLP_activated and Level.filename() ~= "SMBX Level Player.lvlx" then require(getSMBXPath().."\\worlds\\"..GameData.SMBXLP_foldername.."\\SMBXLP.lua") end