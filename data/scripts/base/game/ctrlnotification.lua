local ctrlNotification = {}
local textplus = require('textplus')

local textFmt = {xscale=1, yscale=1, priority = 5, font = textplus.loadFont("textplus/font/6.ini")}

local currentText = nil
local currentOpacity = 0.0
local currentPlayerNum = 1

local batteryTimer = 0.0
local batteryCooldown = 0.0

Graphics.sprites.Register("hardcoded", "hardcoded-54")

function ctrlNotification.onChangeController(name, playerNum)
	local selectedText = "Selected"
	if Player.count() > 1 then
		selectedText = "Player " .. tostring(playerNum)
	end
	currentText = textplus.layout(selectedText .. " Controller: " .. name, 780, textFmt)
	currentOpacity = 1.0
	currentPlayerNum = playerNum
end

function ctrlNotification.onDraw()
	if currentOpacity > 0 then
		local power = Misc.GetSelectedControllerPowerLevel(currentPlayerNum)
		local x = 10
		local y = 600-10-currentText.height
		if power >= 0 and power < 4 then
			Graphics.drawImageWP(Graphics.sprites.hardcoded[54].img, 10, 600-10-32, 0, 32*(3-power), 32, 32, currentOpacity, 10)
			x = 10+32+10
			y = 600-10-16-(currentText.height*0.5)
		end
		textplus.render{layout=currentText, x=x, y=y, color={currentOpacity, currentOpacity, currentOpacity, currentOpacity}, priority = 10}
		
		currentOpacity = math.max(0, currentOpacity - 0.01)
		
		if currentOpacity == 0 then
			currentText = nil
		end
	elseif batteryCooldown <= 0 then
		-- TODO: Sensibly handle second player controller power checking?
		local power = Misc.GetSelectedControllerPowerLevel()
		if power == 1 or power == 0 then
			if batteryTimer <= 0 then
				batteryTimer = lunatime.toTicks(4)
				if power == 1 then
					currentText = textplus.layout("Low Controller Battery", 780, textFmt)
				elseif power == 0 then
					currentText = textplus.layout("Controller Battery Empty", 780, textFmt)
				end
			else
				batteryTimer = batteryTimer - 1
				if batteryTimer <= 0 then
					batteryCooldown = lunatime.toTicks(60)
				else
					if power == 1 then
						Graphics.drawImageWP(Graphics.sprites.hardcoded[54].img, 10, 600-10-32, 0, 64+32*math.floor((batteryTimer%32)/16), 32, 32, 0.75, 10)
					elseif power == 0 then
						Graphics.drawImageWP(Graphics.sprites.hardcoded[54].img, 10, 600-10-32, 0, 96, 32, 32, 0.75*math.floor((batteryTimer%16)/8), 10)
					end
					
					textplus.render{layout=currentText, x=10+32+10, y=600-10-16-(currentText.height*0.5), color={0.75,0.75,0.75,0.75}, priority = 10}
				end
			end
		else
			batteryTimer = 0
			batteryCooldown = lunatime.toTicks(60)
		end
	else
		batteryCooldown = batteryCooldown - 1
	end
end

function ctrlNotification.onInitAPI()
	registerEvent(ctrlNotification, "onChangeController")
	registerEvent(ctrlNotification, "onDraw")
end

return ctrlNotification
