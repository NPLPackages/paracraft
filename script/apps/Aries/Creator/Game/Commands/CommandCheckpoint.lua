--[[
Title: Block commands
Author(s): Dummy
Date: 2017/12/6
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandCheckpoint.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/STL.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CmdParser.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/CheckPointIO.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityCheckpoint.lua");


local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
	
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local block = commonlib.gettable("MyCompany.Aries.Game.block")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");

local CheckPointIO = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CheckPointIO")
local EntityCheckpoint = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityCheckpoint");

local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");



Commands["checkpoint"] = {
	name="checkpoint", 
	quick_ref="/checkpoint", 
	desc=[[
/checkpoint list	
/checkpoint save [name] [x y z] [-force]
/checkpoint load [name]
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		
		local cp_options, cmd_text = CmdParser.ParseString(cmd_text);
		
		if cp_options == "list" then
			CheckPointIO.readAll();
			for _, v in pairs(CheckPointIO.check_points) do
				commonlib.echo(string.format("check point name:%s status:%s", v.name, tostring(v.isOpen or false)));
			end	
		elseif cp_options == "save" then	
			local name, posX, posY, posZ, isForce;
			name, cmd_text = CmdParser.ParseString(cmd_text);
			posX, posY, posZ, cmd_text = CmdParser.ParsePos(cmd_text);
			--isUser, cmd_text = CmdParser.ParseBool(cmd_text);
			
			local cmd_list;
			if posX then
				local entity = BlockEngine:GetBlockEntity(posX, posY, posZ);
				cmd_list = entity:GetCommand()
			end	
			local attr = 
			{
				x = posX;
				y = posY + 1;
				z = posZ;
				cmdList = cmd_list;
			}
			CheckPointIO.write(name, attr, true);
		elseif cp_options == "load" then	
			local name;
			name, cmd_text = CmdParser.ParseString(cmd_text);
			if not name then
				local loadData = CheckPointIO.readUser(EntityCheckpoint.getLoadInx());
				if loadData then
					name = loadData.name;
				end
			end
			
			if name then
				local ret = CheckPointIO.read(name);
				if ret then
					local gotoCmd = string.format("/goto @a %d %d %d", ret.attr.x, ret.attr.y, ret.attr.z);
					GameLogic.RunCommand(gotoCmd);
					
					--local player = EntityManager.GetPlayer();
					--player:TeleportToBlockPos(ret.attr.x, ret.attr.y + 10, ret.attr.z);
					
					local last_result;
					if (ret.attr.cmdList) then
						local player = EntityManager.GetPlayer();
						if(player) then
							local cmdList = CommandManager:GetCmdList(ret.attr.cmdList)
							last_result = CommandManager:RunCmdList(cmdList, player:GetVariables(), self);
						end
						
					end
				end
			end
		elseif cp_options == "setLoad" then
			local loaderInx;
			loaderInx, cmd_text = CmdParser.ParseString(cmd_text);
			EntityCheckpoint.setLoadInx(loaderInx);
		end
	end,
};