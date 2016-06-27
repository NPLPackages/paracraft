--[[
Title: Command Install
Author(s): LiXizhi
Date: 2014/1/22
Desc: slash command 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandInstall.lua");
-------------------------------------------------------
]]
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");	
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");

Commands["install"] = {
	name="install", 
	quick_ref="/install [url]", 
	desc=[[install a texture package from url
/install http://cc.paraengine.com/twiki/pub/CCWeb/Installer/blocktexture_FangKuaiGaiNian_16Bits.zip
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		if(cmd_text) then
			local url = cmd_text:gsub("^%s*", ""):gsub("%s*$", "");
			if(url:match("^http://")) then
				-- if it is a texture package mod, download and install
				if(url:match("/blocktexture_")) then
					NPL.load("(gl)script/apps/Aries/Creator/Game/API/FileDownloader.lua");
					local FileDownloader = commonlib.gettable("MyCompany.Aries.Creator.Game.API.FileDownloader");
					FileDownloader:new():Init("TexturePack", url, "worlds/BlockTextures/", function(bSucceed, localFileName)
						if(bSucceed) then
							NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/TextureModPage.lua");
							local TextureModPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.TextureModPage");
							TextureModPage.OnApplyTexturePack(localFileName);
							TextureModPage.ShowPage(true);
						else
							_guihelper.MessageBox(localFileName);
						end
					end);
				else
					-- TODO: for world or other mods
				end
			end
		end
	end,
};

Commands["rsync"] = {
	name="rsync", 
	quick_ref="/rsync [-asset] [src]", 
	desc=[[sync all files from source folder. 
-asset only sync remote asset manifest files from src. 
examples:
/rsync -asset D:\lxzsrc\ParaCraftSDKGit\build\ParacraftBuild\res
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		local options;
		options, cmd_text = CmdParser.ParseOptions(cmd_text);
		if(options["asset"]) then
			-- sync asset manifest only
			NPL.load("(gl)script/ide/Files.lua");
			local src_folder = cmd_text;
			src_folder = src_folder:gsub("^%s+", "");
			src_folder = src_folder:gsub("%s+$", "");
			if(src_folder ~= "") then
				local result = commonlib.Files.Find({}, src_folder, 10, 50000, function(item)
					return true;
				end)
				if(result) then
					NPL.load("(gl)script/ide/FileLoader.lua");
					local fileLoader = CommonCtrl.FileLoader:new();
					fileLoader:SetMaxConcurrentDownload(5);

					-- reset all replace files just in case texture pack is in effect. 
					ParaIO.LoadReplaceFile("", true);

					for _, file in ipairs(result) do
						if(file.filename and file.filesize~=0) then
							echo(file.filename);
							fileLoader:AddFile(file.filename);
						end
					end
					LOG.std(nil, "info", "rsync", "%d files synced in folder %s", #result, src_folder);
					GameLogic.AddBBS("rsync", string.format("rsync %d files", #result));

					fileLoader:AddEventListener("loading",function(self,event)
						if(event and event.percent)then
							GameLogic.AddBBS("rsync", string.format("rsync progress: %f%%", event.percent*100));
						end
					end,{});
					fileLoader:AddEventListener("finish",function(self,event)
						GameLogic.AddBBS("rsync", string.format("rsync finished: %d files", #result));
					end,{});
					fileLoader:Start();
				end
			end
		end
	end,
};
