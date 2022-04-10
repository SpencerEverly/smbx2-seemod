local pipecannon = API.load("pipecannon")

pipecannon.exitspeed = {0,20}
pipecannon.SFX = 22
pipecannon.effect = 10

function onEvent(eventname)
	if eventname=="ShowSand" then
		Audio.playSFX("redSwitchTimer.ogg")
	end
end