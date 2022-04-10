function onEvent(eventname)
	if eventname == "PlayNewSong" then
		Audio.MusicChange(1, "Preformance.mp3", -1)
	end
end