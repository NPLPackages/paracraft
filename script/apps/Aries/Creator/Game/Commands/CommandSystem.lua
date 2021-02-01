--[[
Title: system command
Author(s): LiXizhi
Date: 2014/11/21
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandSystem.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local SlashCommand = commonlib.gettable("MyCompany.Aries.SlashCommand.SlashCommand");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");	
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");

local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");

Commands["system"] = {
	name="system", 
	quick_ref="/system [settingchange|exit]", 
	desc=[[refresh system settings
/system settingchange
]] , 
	handler = function(cmd_name, cmd_text, cmd_params)
		local name;
		name, cmd_text = CmdParser.ParseString(cmd_text);

		if(not name or name=="settingchange") then
			GameLogic.GetEvents():DispatchEvent({type = "System.SettingChange", });
		elseif(name == "exit") then
			-- TODO:
		end
	end,
};

Commands["texture"] = {
	name="texture", 
	quick_ref="/texture [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16]", 
	mode_deny = "",
	mode_allow = "",
	desc=[[set texture packs. default to 0
/texture 0   --默认材质
/texture 1   --混搭材质包
/texture 2   --折纸材质包
/texture 3   --折纸材质包2
/texture 4   --孙子兵法折纸风格
/texture 5   --奇幻混搭风材质包
/texture 6   --商业市区材质包
	]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		if(cmd_text) then
			local texture_type = tonumber(cmd_text:match("([%d%.]+)") or 1);
			if (texture_type < 0 or texture_type > 6) then
				return;
			end
			NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/TextureModPage.lua");
			local TextureModPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.TextureModPage");
			local package;
			if (texture_type == 0) then
				package = TextureModPage.GetLocalTexturePackDS()[1];
			elseif (texture_type == 6) then
				package = TextureModPage.GetOfficialTexturePackDS()[16];
			else
				package = TextureModPage.GetOfficialTexturePackDS()[texture_type];
			end
			if (package) then
				if (package:IsDownloaded()) then
					TextureModPage.OnApplyTexturePack(nil, nil, nil, package);
				else
					package:DownloadRemoteFile(function (bSuccess)
						if(bSuccess) then
							TextureModPage.OnApplyTexturePack(nil, nil, nil, package);
						else
							_guihelper.MessageBox(string.format(L"官方材质包【%s】下载失败",package.text));
						end	
					end);
				end
			end
		end
	end,
};

