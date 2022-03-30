--------------------------------------------------------------------
--============== Persistent Block Reference Framework ==============--
--==============          DUMMY VERSION             ==============--
--------------------------------------------------------------------

if (not API.isLoadingShared()) then
	Misc.warning("pblock API should be loaded shared")
end

local pBlock = {}

function pBlock.getExistingWrapper(block)
	return block
end

function pBlock.wrap(block)
	return block
end

return pBlock
