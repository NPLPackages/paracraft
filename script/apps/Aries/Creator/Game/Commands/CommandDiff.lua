--[[
Title: CommandDiff
Author(s): LiXizhi
Date: 2020/9/15
Desc: generate NPL documentation for NPL language service. 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandDiff.lua");
-------------------------------------------------------
]]
local SlashCommand = commonlib.gettable("MyCompany.Aries.SlashCommand.SlashCommand");
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");	
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local block = commonlib.gettable("MyCompany.Aries.Game.block")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");

local DiffTool = commonlib.inherit({});

Commands["diff"] = {
	name="diff", 
	quick_ref="/diff [-selection] [remote_ip_port]", 
	desc=[[show differences between all entities in current world and others in remote or local computer. 
Usage: load two worlds in two processes; start NPL code wiki (F11) in first process, and run /diff in the other process. 
@param remote_ip_port: default value is "127.0.0.1:8099"
@param -selection: only compare selected blocks
e.g.
/diff 127.0.0.1:8100
/diff 
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local options;
		options, cmd_text = CmdParser.ParseOptions(cmd_text);
		local remote_ip_port;
		remote_ip_port, cmd_text = CmdParser.ParseString(cmd_text);

		if(not remote_ip_port or remote_ip_port=="") then
			remote_ip_port = "127.0.0.1:8099"
		end			
			
		local diff = DiffTool:new():Init(remote_ip_port, options.selection);
		diff:Run(function(bSucceed, results)
			if(bSucceed) then
				diff:ShowDiff(results)
			end
		end)
	end,
};

-- @param remote_ip_port: such as "127.0.0.1:8100"
-- @param bCompareSelection: if compare only selected blocks in current world
function DiffTool:Init(remote_ip_port, bCompareSelection)
	self.remote_ip_port = remote_ip_port;
	self.bCompareSelection = bCompareSelection
	return self;
end

-- get entity text at a remote block.
-- @param callbackFunc: function(bSucceed, text) end
function DiffTool:GetText(remote_ip_port, x, y, z, callbackFunc)
	local code = {};
	code[#code + 1] = format([[local entity = GameLogic.EntityManager.GetBlockEntity(%d, %d, %d)]], x, y, z)
	code[#code + 1] = [[
local result = ""
if(entity) then
	result = entity:GetText();
end
return result or "";
]]
	code = table.concat(code, "\n");
	System.os.GetUrl({url = format("http://%s/ajax/console?action=runcode", remote_ip_port), json = true, 
		form = {text=code, src="temp.npl"} }, function(err, msg, data)		
	    if(data and data.result) then
			callbackFunc(true, data.result);
		else
			callbackFunc(false);
		end
	end);
end

-- @param callbackFunc: called when finished, function(succeed, tasks) end 
function DiffTool:Run(callbackFunc)
	local entities = EntityManager.FindEntities({category="b", }) or {};
	local tasks = {};
	self.tasks = tasks;
	for _, entity in ipairs(entities) do
		if(entity.GetText) then
			local text = entity:GetText()
			if(text) then
				local x, y, z = entity:GetBlockPos();
				tasks[#tasks+1] = {x=x, y=y, z=z, text = text};
			end
		end
	end
	self:CompareNext(1, callbackFunc)
end

function DiffTool:CompareNext(index, callbackFunc)
	local tasks = self.tasks;
	if(index > #tasks) then
		callbackFunc(true, tasks);
		return
	end
	local task = tasks[index]

	GameLogic.AddBBS("DiffTool", format("comparing %dth block", index), 1000, "0 255 0")
	self:GetText(self.remote_ip_port, task.x, task.y, task.z, function(succeed, text)
		if(succeed) then
			task.remote_text = text;
			self:CompareNext(index+1, callbackFunc)
		else
			callbackFunc(false);
		end
	end)
end

-- @param results: array of {x, y, z, text, remote_text}
function DiffTool:ShowDiff(results)
	if(results) then
		local o = {};
		for _, result in ipairs(results) do
			if(result.text ~= result.remote_text) then
				o[#o+1] = format("-------------- block diff: %d %d %d", result.x, result.y, result.z);
				-- TODO: more diff result here, possibly showing left and right and lines
			end
		end
		if(#o == 0) then
			_guihelper.MessageBox(L"files are identical", function()
			end);
		else
			-- TODO: show more diff result here in mcml window in left and right pannel.
			local text = table.concat(o,"\n");
			echo(text);
			_guihelper.MessageBox(text, function()
			end);
		end
	end
end

