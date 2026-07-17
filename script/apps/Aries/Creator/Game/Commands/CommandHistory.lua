--[[

]]
NPL.load("(gl)script/apps/Aries/SlashCommand/SlashCommand.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CmdParser.lua");
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");
local SlashCommand = commonlib.gettable("MyCompany.Aries.SlashCommand.SlashCommand");
local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");
local command_history_key = "command_history"..((System.options.channelId and System.options.channelId ~= "") and ("_paracraft_"..System.options.channelId) or "_paracraft");
local command_index = 0
local max_history_size = 10;
local function AddCommandToHistory(command_history,command_name)
    local history = command_history or {};
    local history_size = #history;
    local findIndex = -1;
    for i,v in ipairs(history) do
        if v == command_name then
            findIndex = i;
            break;
        end
    end

    if findIndex == -1 then
        if history_size >= max_history_size then
            table.remove(history,history_size);
        end
        table.insert(history,1,command_name);
    else
        table.remove(history,findIndex);
        table.insert(history,1,command_name);
    end
    GameLogic.GetPlayerController():SaveLocalData(command_history_key,history);
end



Commands["history"] = {
    name="history", 
	quick_ref="/history [-type save|load] [command_name]", 
	desc=[[save and load command history
    e.g:
        /history -1 -- load command 1
        /history -previous -- load previous command
        /history -next  -- load next command
        /history -init  -- init command index
        /history -c|clear -- clear command history
        /history -type load -- load all command
        /history -type load 5 -- load 5 command 
        /history -type save /loadworld -s -auto 530 -- save command
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
        local history_type = "load";
		local option_name, cmd_text = CmdParser.ParseOption(cmd_text);
        local command_history = GameLogic.GetPlayerController():LoadLocalData(command_history_key,{});
        local commandIndex = tonumber(option_name)
        if commandIndex and commandIndex > 0 and command_history[commandIndex] then
            return command_history[commandIndex];
        end
        if option_name and option_name == "previous" then
            if command_index > 1 then
                command_index = command_index - 1;
                return command_history[command_index];
            end
            return 
        end
        if option_name and option_name == "next" then
            if command_index < #command_history then
                command_index = command_index + 1;
                return command_history[command_index];
            end
            return 
        end
        if option_name and option_name == "init" then
            command_index = 0;
            return true
        end

        if option_name and option_name == "clear" or option_name == "c" then
            command_index = 0
            command_history = {}
            GameLogic.GetPlayerController():SaveLocalData(command_history_key,command_history)
            return 
        end
        
        if option_name and option_name == "type" then
            history_type,cmd_text = CmdParser.ParseString(cmd_text);
        end

        if history_type == "load" then
            local num = tonumber(cmd_text)
            if num and num > 0 then
                local temp = {}
                for i,v in ipairs(command_history) do
                    if i <= num then
                        table.insert(temp,v)
                    end
                end
                return temp
            end
            return command_history
        end
        if history_type == "save" then
            local command_name = cmd_text;
            AddCommandToHistory(command_history,command_name)
        end
	end,
};