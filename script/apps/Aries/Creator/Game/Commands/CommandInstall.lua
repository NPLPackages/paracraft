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
	quick_ref="/install [-mod|bmax] [-filename str] [-ext str] [url]", 
	desc=[[install a texture package, mod or bmax file from url
/install http://cc.paraengine.com/twiki/pub/CCWeb/Installer/blocktexture_FangKuaiGaiNian_16Bits.zip
/install -mod https://keepwork.com/wiki/mod/packages/packages_install/paracraft?id=12
/install -mod https://cdn.keepwork.com/paracraft/Mod/MovieCodecPluginV9.zip
/install -bmax -filename car https://cdn.keepwork.com/paracraft/officialassets/car.bmax
/install -ext bmax -filename car https://cdn.keepwork.com/paracraft/officialassets/car.bmax
/install -ext fbx -filename car https://cdn.keepwork.com/paracraft/officialassets/car.fbx
/install -ext x -filename car https://cdn.keepwork.com/paracraft/officialassets/car.x
/install -ext blocks -filename car https://cdn.keepwork.com/paracraft/officialassets/car.blocks.xml
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		local options;
		
		local options = {};
		local option, value;
		while(true) do
			option, cmd_text = CmdParser.ParseOption(cmd_text);	
			if(not option) then
				break;
			elseif(option == "filename") then
				-- supporting spaces in filename
				value, cmd_text = cmd_text:match("^%s*(.+)%s+(https?://.*)$");
				if(value and value ~= "") then
					value = value:gsub("[& ]+", "_");
				end
				options[option] = value;

			elseif(option == "md5" or option == "crc32"  or option == "ext" ) then
				value, cmd_text = CmdParser.ParseString(cmd_text, fromEntity);
				options[option] = value;
			else
				options[option] = true;
			end
		end

		if(not cmd_text) then
			return 
		end
		local url = cmd_text:gsub("^%s*", ""):gsub("%s*$", "");
		
		if(options["mod"]) then
			if(url:match("^https?://")) then
				if(url:match("%.zip[^/]*$")) then
					-- download zip directly
					NPL.load("(gl)script/apps/Aries/Creator/Game/Mod/ModManager.lua");
					local ModManager = commonlib.gettable("Mod.ModManager");
					ModManager:GetLoader():InstallFromUrl(url, function(bSucceed, msg, package) 
						LOG.std(nil, "info", "CommandInstall", "bSucceed:  %s: %s", tostring(bSucceed), msg or "");
						if(bSucceed and package) then
							ModManager:GetLoader():LoadPlugin(package.name);
							ModManager:GetLoader():RebuildModuleList();
							ModManager:GetLoader():EnablePlugin(package.name, true, true);
							ModManager:GetLoader():SaveModTableToFile();
						end
					end);
				else
					GameLogic.RunCommand("/show mod")
					ParaGlobal.ShellExecute("open", url, "", "", 1);
				end
			end
		elseif((options["bmax"] or options["ext"]) and options["filename"]) then
			if(url:match("^https?://")) then
				local filename = options["filename"];
				local ext = options["ext"] or "bmax";
				if(ext ~= "bmax" and ext ~= "x" and ext ~= "fbx" and ext ~= "blocks") then
					LOG.std(nil, "warn", "CommandInstall", "unknown file extension %s for %s", ext, filename);
					return;
				end
				if((ext == "blocks" or ext == "blocks.xml" or ext == "template") and not filename:match("%.blocks%.xml$")) then
					filename = filename..".blocks.xml";
				elseif(not filename:match("%."..ext.."$")) then
					filename = filename.."."..ext;
				end
				filename = "blocktemplates/"..filename;
				NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
				local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
				local dest = Files.WorldPathToFullPath(commonlib.Encoding.Utf8ToDefault(filename))
				local function TakeBlockModel_(filename)
					GameLogic.AddBBS("install", format(L"模型已经安装到 %s", filename), 5000, "0 255 0");
					GameLogic.RunCommand(string.format("/take BlockModel {tooltip=%q}", filename));
				end

				GameLogic.GetFilters():apply_filters("OnInstallModel", filename, url);


				if(ParaIO.DoesFileExist(dest, true)) then
					TakeBlockModel_(filename)
				else
					NPL.load("(gl)script/ide/System/localserver/factory.lua");
					local cache_policy = System.localserver.CachePolicy:new("access plus 1 year");
					local ls = System.localserver.CreateStore();
					if(not ls) then
						log("error: failed creating local server resource store \n")
						return
					end
					GameLogic.AddBBS("install", L"正在下载请稍后", 5000, "0 255 0");
					ls:GetFile(cache_policy, url, function(entry)
						if(entry and entry.entry and entry.entry.url and entry.payload and entry.payload.cached_filepath) then
							ParaIO.CreateDirectory(dest);
							if(ParaIO.CopyFile(entry.payload.cached_filepath, dest, true)) then
								Files.NotifyNetworkFileChange(dest)
								TakeBlockModel_(filename)
							else
								LOG.std(nil, "warn", "CommandInstall", "failed to copy from %s to %s", entry.payload.cached_filepath, dest);
							end
						end
					end);	
				end
			end
		else
			if(url:match("^https?://")) then
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


Commands["makeapp"] = {
	name="makeapp", 
	quick_ref="/makeapp", 
	desc=[[make current world into a standalone app file (zip)
e.g.
/makeapp 
]], 
	handler = function(cmd_name, cmd_text, cmd_params)
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MakeAppTask.lua");
		local MakeApp = commonlib.gettable("MyCompany.Aries.Game.Tasks.MakeApp");
		local task = MyCompany.Aries.Game.Tasks.MakeApp:new()
		task:Run();
	end,
};
