-- entity events like NPC

-- example of user defined entity event handler
-- run following command to call this event handler
-- /sendevent helloworld 
function helloworld(entity, event)
	cmd("/tip entity received: "..event:GetType());
end
