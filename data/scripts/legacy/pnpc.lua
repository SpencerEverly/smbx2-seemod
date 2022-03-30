--------------------------------------------------------------------
--============== Persistent NPC Reference Framework ==============--
--==============          DUMMY VERSION             ==============--
--------------------------------------------------------------------

if (not API.isLoadingShared()) then
	Misc.warning("pnpc API should be loaded shared")
end

local pNPC = {}

function pNPC.getExistingWrapper(npc)
	return npc
end

function pNPC.wrap(npc)
	return npc
end

return pNPC
