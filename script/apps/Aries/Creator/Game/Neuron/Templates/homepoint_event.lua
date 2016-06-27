-- system event is only received by HomePoint entity. 

-- example of user defined entity event handler
-- run following command to call this event handler
-- /sendevent helloworld 
function helloworld(entity, event)
	cmd("/tip "..event:GetType());
end

-- whenever timer is enabled. 
function timerEvent(entity, event)
	cmd("/tip "..event:GetType());
end

-- system event: when a block near active players ticks
function blockTickEvent(entity, event)
	cmd("/tip "..event:GetType());
	-- TODO: randomly generate some creatures here?
end
