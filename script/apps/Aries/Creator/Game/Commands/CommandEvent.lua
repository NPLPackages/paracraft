--[[
Title: sendevent command
Author(s): LiXizhi
Date: 2014/3/5
Desc: sendevent can be used to connect items in the world.
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandEvent.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Core/Event.lua");
local Event = commonlib.gettable("System.Core.Event");
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");
local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");

Commands["sendevent"] = {
	name="sendevent", 
	quick_ref="/sendevent [@entityname] event_name [cmd_text]", 
	desc=[[ send a custom event to given entity
@param entityname: if not specified, it means a global event, which is handled by home point entity. 
it will try scene entity first, and then code block actor name.
@param cmd_text: additional parameter saved to event.cmd_text. 
Examples:
/sendevent start 
/sendevent HelloEvent 
/sendevent @test HelloEvent {data=1}
]], 
	category="logic",
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local targetEntity, eventname, _, playerName;
		targetEntity, cmd_text, _, playerName = CmdParser.ParsePlayer(cmd_text, fromEntity);
		eventname, cmd_text = CmdParser.ParseString(cmd_text);
		if(eventname) then
			local event = Event:new():init(eventname);	
			event.cmd_text = cmd_text;
			if(targetEntity) then
				return targetEntity:event(event);
			else
				if(playerName and playerName ~= "") then
					-- try sending to code block actor with the exact name
					event.dest = playerName
				end
				return GameLogic:event(event);
			end
		end
	end,
};
