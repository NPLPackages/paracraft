--[[
Title: CommandTexture
Author(s): LiXizhi
Date: 2014/3/10
Desc: template related command
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandTexture.lua");
-------------------------------------------------------
]]
local SlashCommand = commonlib.gettable("MyCompany.Aries.SlashCommand.SlashCommand");
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");	
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local block = commonlib.gettable("MyCompany.Aries.Game.block")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local LocalTextures = commonlib.gettable("MyCompany.Aries.Game.Materials.LocalTextures");
local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");


Commands["replacetexture"] = {
	name="replacetexture", 
	quick_ref="/replacetexture from_id to_id_or_filename", 
	desc=[[replace a block texture to another texture or 0
/replacetexture 62 0
/replacetexture 62 61
/replacetexture 62 62
/replacetexture 62 preview.jpg
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local from_id, to_id, to_filename;
		from_id, cmd_text = CmdParser.ParseBlockId(cmd_text);
		to_id, cmd_text = CmdParser.ParseBlockId(cmd_text);
		if(not to_id) then
			to_filename, cmd_text = CmdParser.ParseString(cmd_text);
			if(to_filename) then
				to_filename = LocalTextures:GetByFileName(to_filename);
			else
				to_id = from_id;
			end
		end
		
		if(from_id and (to_id or to_filename)) then
			local from_block = block_types.get(from_id);
			if(from_block) then
				if(not to_filename and to_id) then
					if(to_id~=0) then
						local to_block = block_types.get(to_id);
						if(to_block) then
							to_filename = to_block:GetTexture();
						end
					end
					to_filename = to_filename or "Texture/Transparent.png";
				end
				from_block:ReplaceTexture(to_filename);
			end
		end
	end,
};


Commands["applytexturepack"] = {
	name="applytexturepack", 
	quick_ref="/applytexturepack [folder_or_zipfile]", 
	desc=[[apply a given texture pack if not exist download from the provided url
if texture not exist, the cmd return false. one may use /install cmd to install from web. 
/applytexturepack														restore to default
/applytexturepack blocktexture_FangKuaiGaiNian_16Bits					use a given texture
it may use relative to "worlds/BlockTextures/" path or a relative to root dir path. 
both zip and file folder is supported. 
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
	-- local block "worlds/BlockTextures/"
		local localFileName = cmd_text;
		NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/TextureModPage.lua");
		local TextureModPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.TextureModPage");
		NPL.load("(gl)script/apps/Aries/Creator/Game/Materials/TexturePackageList.lua");
		local TexturePackageList = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.TexturePackageList");
		
		if(cmd_text ~= "") then
			localFileName = commonlib.Encoding.Utf8ToDefault(localFileName);
			if(not ParaIO.DoesFileExist(localFileName)) then
				localFileName = "worlds/BlockTextures/"..localFileName;
				if(not ParaIO.DoesFileExist(localFileName)) then
					return false;
				end
			end
		end

		TexturePackageList.GetTexturePackage(nil,localFileName,nil,nil, function (package)
			if(package) then
				TextureModPage.OnApplyTexturePack(nil,nil,nil,package);
			end
		end)
	end,
};


Commands["texgen"] = {
	name="texgen", 
	quick_ref="/texgen [-all] [-i] [unit_size] [altas_size]", 
	desc=[[generate texture altas for all blocks. See log.txt for output files
@param	-i: whether to save as individual file. 

/texgen -all 32 512		 generate all textures 32*32 each
/texgen -all			 same as above.
/texgen -all 64 512		 generate all textures 64*64 each on several textures
/texgen -all -i 64		generate individual image file for each block. 
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local options;
		options,cmd_text = CmdParser.ParseOptions(cmd_text);
		
		if(options["all"]) then
			local unit_size, altas_size;
			unit_size, cmd_text = CmdParser.ParseInt(cmd_text);
			altas_size, cmd_text = CmdParser.ParseInt(cmd_text);
			unit_size = unit_size or 32;
			altas_size = altas_size or 512;
			NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/TextureAtlas.lua");
			local TextureAtlas = commonlib.gettable("MyCompany.Aries.Game.blocks.TextureAtlas")
			local texture_atlas = TextureAtlas:new():init("block_icon_altas", altas_size, altas_size, unit_size);
			local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
			local ds_src = ItemClient.GetBlockDS("all");
			
			if(ds_src) then
				if(unit_size == altas_size) then
					-- TODO: if image size equals we will save to default texture path
					for _,category_ds in pairs(ds_src) do
						for index, item in ipairs(category_ds) do 
							local block_id = item.id;
							if(block_id and block_id>0 and block_id < 512) then
								texture_atlas:AddRegionByBlockId(block_id);
							end
						end	
					end
				else
					-- if(options["perspective"]) then
					for _,category_ds in pairs(ds_src) do
						for index, item in ipairs(category_ds) do 
							local block_id = item.id;
							if(block_id and block_id>0 and block_id < 512) then
								texture_atlas:AddRegionByBlockId(block_id);
							end
						end	
					end
					texture_atlas:ScheduleFunctionCall(2000, texture_atlas, texture_atlas.SaveAsIndividualFiles);
				end
				
			end
			
			GameLogic.AddBBS("cmd", "texture gen completed: see log.txt or temp/blockitems/ folder ");
		end
	end,
};

Commands["createtexturepack"] = {
	name="createtexturepack", 
	quick_ref="/createtexturepack [DefaultPackName]", 
	desc=[[generate all replaceable textures to default name. duplicated_texture are named duplicate_block_id_filename 
/createtexturepack         create to default directory. Clear the dir first. 
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local name;
		name, cmd_text = CmdParser.ParseString(cmd_text);
		
		NPL.load("(gl)script/apps/Aries/Creator/Game/Materials/LocalTextures.lua");
		local LocalTextures = commonlib.gettable("MyCompany.Aries.Game.Materials.LocalTextures");

		-- mapping from texture filename to id. 
		local textures = {};
		local textures_rep = {};
		name = name or "DefaultTexturePack";
		local dest_dir = "temp/"..name.."/";
		ParaIO.CreateDirectory(dest_dir);
		local count = 0;
		local filename = "config/Aries/creator/block_types.xml";

		local function CopyTexture(src, dest, bOverwrite)
			local filename, max_seq = dest:match("^(.*%d+_a)(%d%d%d)%.png$");
			if(max_seq) then
				max_seq = tonumber(max_seq);
				for i=1, max_seq do
					local dest = string.format("%s%03d.png", filename, i);
					ParaIO.CopyFile(src, dest, bOverwrite);
				end
			else
				ParaIO.CopyFile(src, dest, bOverwrite);
			end
		end
		LocalTextures:SetBlockReplacebleTexture(LocalTextures:LoadBlockReplacebleTexture(nil, true));
		local xmlRoot = ParaXML.LuaXML_ParseFile(filename);
		if(xmlRoot) then
			for node in commonlib.XPath.eachNode(xmlRoot, "/blocks/block") do
				local attr = node.attr;
				local block_id = tonumber(attr.id);
				if(block_id and block_id>=0 and block_id<512 and attr.texture) then
					local texture = LocalTextures:GetBlockTexture(attr.texture, true);
					if(not textures[texture]) then
						local oldfilename = texture:match("[^/\\]+$");
						local target_filename = format("%s%d_%s", dest_dir, block_id, oldfilename);
							
						if(texture == attr.texture) then
							textures[texture] = block_id;
							CopyTexture(texture, target_filename, true);
						else
							-- we will always delay replaced textures
							if(not textures_rep[texture]) then
								textures_rep[texture] = {texture = attr.texture, block_id = block_id};
							else
								local oldfilename = texture:match("[^/\\]+$");
								local target_filename = format("%sduplicated_%d_%s", dest_dir, block_id, oldfilename);
								CopyTexture(texture, target_filename, true);
							end
						end
					else
						local oldfilename = texture:match("[^/\\]+$");
						local target_filename = format("%sduplicated_%d_%s", dest_dir, block_id, oldfilename);
						CopyTexture(texture, target_filename, true);
					end
					count = count + 1;
				end
			end
			-- we will always delay replaced textures
			for texture, item in pairs(textures_rep) do
				local block_id = item.block_id;
				if(not textures[texture]) then
					local oldfilename = texture:match("[^/\\]+$");
					local target_filename = format("%s%d_%s", dest_dir, block_id, oldfilename);
					textures[texture] = block_id;
					CopyTexture(texture, target_filename, true);
				else
					local oldfilename = texture:match("[^/\\]+$");
					local target_filename = format("%sduplicated_%d_%s", dest_dir, block_id, oldfilename);
					CopyTexture(texture, target_filename, true);
				end
			end
			if(count) then
				_guihelper.MessageBox(format("%d successfully created to %s", count, dest_dir), function()
					System.App.Commands.Call("File.WinExplorer", ParaIO.GetCurDirectory(0)..dest_dir);
				end);
			end
		end
		LocalTextures:SetBlockReplacebleTexture(nil);
	end,
};
