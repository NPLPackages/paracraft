--[[
Title: the create cmd
Author(s): LiXizhi
Date: 2014/7/28
Desc: 
use the lib:
------------------------------------------------------------
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local SlashCommand = commonlib.gettable("MyCompany.Aries.SlashCommand.SlashCommand");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");	
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");

local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");

Commands["create"] = {
	name="create", 
	quick_ref="/create [id|filename] [bx] [by] [bz]", 
	desc=[[ create item, entity, block, etc. 
/create filename.x
/create 20012 				create rail car at player position. 
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local filename, bx, by, bz;
		options, cmd_text = CmdParser.ParseOptions(cmd_text);
		filename, cmd_text = CmdParser.ParseString(cmd_text);
		bx, by, bz, cmd_text = CmdParser.ParsePos(cmd_text);
		if(not bx) then
			bx,by,bz = EntityManager.GetFocus():GetBlockPos();	
		end

		if(filename~="") then
			if(filename:match("[/\\%.]")) then
				-- create from model filename(.x file)
				if(GameLogic.GameMode:CanPlaceExternalModel()) then
					local filename = Files.GetWorldFilePath(filename);
					if(filename) then
						local objParams = {};
						objParams.AssetFile = filename;
						objParams.x, objParams.y, objParams.z = BlockEngine:real(bx,by,bz);
						if(filename:match("^character")) then
							objParams.IsCharacter = true;
						end
			
						NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/CreateModelTask.lua");
						local task = MyCompany.Aries.Game.Tasks.CreateModel:new({obj_params = objParams})
						task:Run();
					end
				else
					BroadcastHelper.PushLabel({id="cmdcreate", label = L"当前模式暂时不允许导入外部模型", max_duration=6000, color = "255 0 0", scaling=1.1, bold=true, shadow=true,});
				end
			elseif(filename:match("^%d+$")) then
				-- create by item id (Entity)
				local item_id = tonumber(filename);
				if(item_id) then
					local item = ItemClient.GetItem(item_id);
					if(item) then
						item:TryCreate(nil, fromEntity, bx,by,bz);
					end
				end
			end
		end
	end,
};