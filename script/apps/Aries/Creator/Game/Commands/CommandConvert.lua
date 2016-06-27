--[[
Title: Command Convert
Author(s): LiXizhi
Date: 2014/5/15
Desc: Data Conversion related. 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandConvert.lua");
-------------------------------------------------------
]]
local SlashCommand = commonlib.gettable("MyCompany.Aries.SlashCommand.SlashCommand");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");	

local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");

Commands["blockimage"] = {
	name="blockimage", 
	quick_ref="/blockimage [-xy|-yz|-xz] [colors:1|2|3|16] filename [x y z]", 
	desc=[[load image as blocks at given position. Image width better be multiple of 2.
@param [-xy|-yz|-xz]: default to xy plane
@param colors: how many colors to use. default to 65535. For fewer colors, use [1|2|3|16|65535]
@param [x y z]: optionally special a 3d location. default to command container. 

Examples:
-- color blocks is black and white
/blockimage 2 Texture/blocks/sapling_birch.png
-- create in the xz planes, color blocks has 16 colors that best match, this is the default color
/blockimage -xz 16 preview.png 
-- create with full color
/blockimage Texture/blocks/movie_three.png
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		NPL.load("(gl)script/apps/Aries/Creator/Game/Materials/LocalTextures.lua");
		local LocalTextures = commonlib.gettable("MyCompany.Aries.Game.Materials.LocalTextures");
		
		local colors, filename, options
		options, cmd_text = CmdParser.ParseOptions(cmd_text);
		colors, cmd_text = CmdParser.ParseInt(cmd_text);
		colors = colors or 65535;
		filename, cmd_text = CmdParser.ParseString(cmd_text);
		filename = filename or "preview.jpg";
		filename = LocalTextures:GetByFileName(commonlib.Encoding.Utf8ToDefault(filename));

		if(filename) then
			local x, y, z;
			x, y, z, cmd_text = CmdParser.ParsePos(cmd_text, fromEntity);
			if(not x) then
				x,y,z = EntityManager.GetFocus():GetBlockPos();	
			end
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ConvertImageToBlocksTask.lua");
			local Tasks = commonlib.gettable("MyCompany.Aries.Game.Tasks");
			local task = Tasks.ConvertImageToBlocks:new({filename = filename,blockX = x,blockY = y, blockZ = z, colors=colors,options=options})
			task:Run();
		end
	end,
};
