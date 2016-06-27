--[[
Title: Save World Page
Author(s): LiXizhi
Date: 2013/6/30
Desc: save world
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/SaveWorldPage.lua");
local SaveWorldPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.Areas.SaveWorldPage");
SaveWorldPage.ShowPage()
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/main.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/WorldUploadPage.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/GameMarket/OtherPeopleWorlds.lua");
NPL.load("(gl)script/kids/3DMapSystemApp/localserver/UrlHelper.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/game_logic.lua");
NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local OtherPeopleWorlds = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.OtherPeopleWorlds");
local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
local WorldUploadPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.WorldUploadPage");
local Desktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop");
local ItemManager = commonlib.gettable("Map3DSystem.Item.ItemManager");
local EnterGamePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.EnterGamePage");

local SaveWorldPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.Areas.SaveWorldPage");

SaveWorldPage.empty_records = {};

local page;
function SaveWorldPage.OnInit()
	page = document:GetPageCtrl();
	SaveWorldPage.worldname = WorldCommon.GetWorldTag("name");
	page:SetValue("worldname", SaveWorldPage.worldname)
	if(SaveWorldPage.image_filepath) then
		page:SetValue("WorldImage", SaveWorldPage.image_filepath);
	end
end

-- @param slot_id: if not nil, it will highlight a given world record
function SaveWorldPage.ShowPage(bShow)
	local width, height = 310, 270;
	System.App.Commands.Call("File.MCMLWindowFrame", {
			url = "script/apps/Aries/Creator/Game/Areas/SaveWorldPage.html", 
			name = "MCNewSaveWorldPage.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			enable_esc_key = true, 
			style = CommonCtrl.WindowFrame.ContainerStyle,
			bShow = bShow,
			zorder = 10,
			directPosition = true,
				align = "_ct",
				x = -width/2,
				y = -height/2,
				width = width,
				height = height,
		});
	-- only take if file does not exist. 
	SaveWorldPage.TakeImage(true);
end

function SaveWorldPage.OnSaveWorld(worldname)
	if(not worldname or worldname=="" or WorldCommon.GetWorldTag("name") == worldname) then
        GameLogic.QuickSave();
    else
		if(not EnterGamePage.CheckRight("uploadgame")) then
			return;
		end
        local cur_dir = ParaWorld.GetWorldDirectory();
        local filepath = cur_dir:gsub("[^/\\]+[/\\]$", worldname.."/")
        _guihelper.MessageBox(format("确定要另存为:%s", filepath), function(res)
			filepath = commonlib.Encoding.Utf8ToDefault(filepath);
            local res = Map3DSystem.CreateWorld(filepath, ParaWorld.GetWorldDirectory(), true, true, true, true);
	        if(res == true) then
                _guihelper.MessageBox("保存成功");

				local tag_filename = filepath.."/tag.xml"
				local xmlRoot = ParaXML.LuaXML_ParseFile(tag_filename);
				if(xmlRoot) then
					local node;
					for node in commonlib.XPath.eachNode(xmlRoot, "/pe:mcml/pe:world") do
						if(node.attr) then
							node.attr.name = worldname;
							break;
						end
					end
					NPL.load("(gl)script/ide/LuaXML.lua");
					local file = ParaIO.open(tag_filename, "w");
					if(file:IsValid()) then
						-- create the tag.xml file under the world root directory. 
						file:WriteString(commonlib.Lua2XmlString(xmlRoot, true) or "");
						file:close();
					end
				end

            elseif(type(res) == "string") then  
                _guihelper.MessageBox(res);
            end    
        end)
    end
end

function SaveWorldPage.TakeImage(bTakeIfFileDoesNotExist)
	--local page = SaveWorldPage.sharepage;
	NPL.load("(gl)script/kids/3DMapSystemUI/ScreenShot/SnapshotPage.lua");	
	local filepath = ParaWorld.GetWorldDirectory().."preview.jpg";
	SaveWorldPage.image_filepath = filepath;
	
	local function SaveAsWorldPreview()
		if(MyCompany.Apps.ScreenShot.SnapshotPage.TakeSnapshot(filepath,300,200, false)) then
			--page:SetUIValue("result", string.format("世界截图保存成功:%s", filepath));
			page:SetUIValue("WorldImage", filepath);
		end
	end
	
	if(ParaIO.DoesFileExist(filepath, true)) then
		if(not bTakeIfFileDoesNotExist) then
			SaveAsWorldPreview();
			ParaAsset.LoadTexture("",filepath,1):UnloadAsset();
		else
			page:SetUIValue("WorldImage", filepath);
		end

        --[[
		_guihelper.MessageBox(string.format("世界预览图已经存在, 是否要覆盖它?"), function()
			SaveAsWorldPreview();
			ParaAsset.LoadTexture("",filepath,1):UnloadAsset();
		end);
        ]]
	else
		SaveAsWorldPreview();
	end

end