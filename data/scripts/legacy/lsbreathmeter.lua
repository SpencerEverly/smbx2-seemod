local LsBreathMeter_API = {}

local LsFrameHudN64 = {} -- don't mess with those empty table, need it to load stuff properly
local LsFrameP2HudN64 = {}

 for i=1, 9 do
 _G["hudAirMeter"   ..i] = Graphics.loadImage(Misc.resolveFile("legacy/LsBreathMeter/hudAirMeter"  .. i ..".png"));  LsFrameHudN64[i] =  _G["hudAirMeter"   ..i]
 _G["hudP2AirMeter" ..i] = Graphics.loadImage(Misc.resolveFile("legacy/LsBreathMeter/hudP2AirMeter".. i ..".png"));  LsFrameP2HudN64[i] =  _G["hudP2AirMeter"   ..i]
end
local hudAirMeterShape       =   Graphics.loadImage(Misc.resolveFile("legacy/LsBreathMeter/hudAirMeterShape.png"));  -- let's load elipse pix all parts
local hudAirMeterBackGround  =   Graphics.loadImage(Misc.resolveFile("legacy/LsBreathMeter/hudAirMeterBackGround.png")); -- let's load background pix part

local hudBreath       = true -- Activate, Deactivate API for all
local ControlFlood    = false
local BreathKillP1    = true -- Activate, Deactivate Kill from missing air for Player 1
local BreathKillP2    = true -- Activate, Deactivate Kill from missing air for Player 2
local P1InWater 	  = 0    -- detect players 1 in water !!
local P2InWater 	  = 0    -- detect players 2 in water !!
local AirOfPlayer1    = 100   -- Air Of Player1 
local GaugeLevel1     = 9    -- dividing number frame from air breathing (need this because of pix (9)) , Dont change it if u have 9 pictures...
local AirOfPlayer2    = 100   -- Air Of Player2 
local GaugeLevel2     = 9    -- dividing number frame from air breathing (need this because of pix (9)) , Dont change it if u have 9 pictures...
local ActivateWater   = 0    -- Cheats Water for P1 Anywhere ! leave as is pls !
local AirMultiplierP1 = 1    -- Settings API for Adjusting Time decreasing of the Breath --> 1 or less decreasing slower, 1 and more decreasing faster.
local AirMultiplierP2 = 1

function LsBreathMeter_API.onInitAPI()
registerEvent(LsBreathMeter_API, "onTick", "onTick")
registerEvent(LsBreathMeter_API, "onDraw", "onDraw")
registerEvent(LsBreathMeter_API, "onKeyboardPress", "onKeyboardPress")
end

function LsBreathMeter_API.onKeyboardPress(keyCode)
  if (ControlFlood) then
	if (keyCode == VK_CONTROL)  then ActivateWater = ActivateWater + 1 end -- Key "Ctrl"  Invisible flooding for test cheat anywhere !! 
  else end
end

function LsBreathMeter_API.onDraw()
if (hudBreath) then

SplitX = 0; if (mem(0x00B25132, FIELD_WORD) ~= 5) then SplitX =  -393 else SplitX = 0 end  

if (P1InWater > 0)   then ThatAir1 =  -0.07   end if (P1InWater == 0)  then ThatAir1 = 0.1 end 
if (AirOfPlayer1 <= 0)  then AirOfPlayer1 = 0  end if (AirOfPlayer1 >= 60) then AirOfPlayer1 = 60 end
AirOfPlayer1 = AirOfPlayer1 + ThatAir1

if (P1InWater > 0) or (AirOfPlayer1 < 60) then 
  if player:mem(0x13E , FIELD_WORD) ~= 0 or player:mem(0x13C , FIELD_WORD) ~= 0 then AirOfPlayer1 = 60 else
   Graphics.drawImageToSceneWP( LsFrameHudN64[math.ceil(GaugeLevel1)], player.x - 6, player.y - 42, 1.0, 3.1)
   Graphics.drawImageToSceneWP( hudAirMeterShape, player.x - 6, player.y - 42, 1.0, 3.2)
   Graphics.drawImageToSceneWP( hudAirMeterBackGround, player.x - 8, player.y - 44, 1.0, 3.0) end else end 
if (tonumber(AirOfPlayer1) <= 7) then if (BreathKillP1) then player:kill() else end end
  
if (Player(2).isValid) then
if (P2InWater > 0)  then ThatAir2 = -0.07   end if (P2InWater == 0) then ThatAir2 = 0.1 end
if (AirOfPlayer2 <= 0)  then AirOfPlayer2 = 0  end if (AirOfPlayer2 >= 60) then AirOfPlayer2 = 60 end
AirOfPlayer2 = AirOfPlayer2 + ThatAir2

if (P2InWater > 0) or (AirOfPlayer2 < 60) then 
  if player2:mem(0x13E , FIELD_WORD) ~= 0 or player2:mem(0x13C , FIELD_WORD) ~= 0 then AirOfPlayer2 = 60  else
   Graphics.drawImageToSceneWP( LsFrameHudN64[math.ceil(GaugeLevel2)], player2.x - 6, player2.y - 42, 1.0, 3.1)
   Graphics.drawImageToSceneWP( hudAirMeterShape, player2.x - 6, player2.y - 42, 1.0, 3.2)
   Graphics.drawImageToSceneWP( hudAirMeterBackGround, player2.x - 8, player2.y - 44, 1.0, 3.0) end else end 
  if (tonumber(AirOfPlayer2) <= 7) then if (BreathKillP2) then player2:kill() else end end else end
else end
end

function LsBreathMeter_API.onTick()
if (hudBreath) then

if (ActivateWater > 1) then ActivateWater = 0 end
if (ActivateWater == 1) then if (AirOfPlayer1 > 0) then player:mem(0x34, FIELD_WORD, 2) else end
if (Player(2).isValid) then  if (AirOfPlayer2 > 0) then Player(2):mem(0x34, FIELD_WORD, 2) else end else end else end

P1InWater = player:mem(0x34, FIELD_WORD)
if (Player(2).isValid) then P2InWater =  Player(2):mem(0x34, FIELD_WORD) 
for f = 1 ,  math.ceil(AirOfPlayer2 / 6.66)  - 1  do if f < 2 then f = 1 end GaugeLevel2 = f end
if (Player(2):mem(0x13E, FIELD_WORD) ~= 0) then GaugeLevel2 = 1   else end   end

for i = 1 , math.ceil(AirOfPlayer1 / 6.66) - 1  do if i < 2 then i = 1 end GaugeLevel1 = i end
if (player:mem(0x13E, FIELD_WORD) ~= 0) then GaugeLevel1 = 1   else end

else end 
end 

function LsBreathMeter_API.hudBreath(set_me)
 hudBreath = set_me
end

function LsBreathMeter_API.ControlFlood(set_me)
 ControlFlood = set_me
end

function LsBreathMeter_API.ReturnAirTimeP1()
  return AirOfPlayer1;
end

function LsBreathMeter_API.ReturnAirTimeP2()
  return AirOfPlayer2;
end

function LsBreathMeter_API.AirMultiplierP1(set_me)
 AirMultiplierP1 = set_me
end

function LsBreathMeter_API.AirMultiplierP2(set_me)
 AirMultiplierP2 = set_me
end

return LsBreathMeter_API