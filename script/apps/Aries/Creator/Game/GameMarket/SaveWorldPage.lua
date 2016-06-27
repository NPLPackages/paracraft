--[[
Title: Save World Page
Author(s): LiXizhi
Date: 2013/6/30
Desc: save world
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/GameMarket/SaveWorldPage.lua");
local SaveWorldPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.SaveWorldPage");
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
local SaveWorldPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.SaveWorldPage");
local ItemManager = commonlib.gettable("Map3DSystem.Item.ItemManager");
local EnterGamePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.EnterGamePage");

SaveWorldPage.empty_records = {};

local page;
function SaveWorldPage.OnInit()
	page = document:GetPageCtrl();
	page:SetValue("worldname", WorldCommon.GetWorldTag("name"))
end

-- @param slot_id: if not nil, it will highlight a given world record
function SaveWorldPage.ShowPage(bShow)
	local width, height = 380, 300;
	System.App.Commands.Call("File.MCMLWindowFrame", {
			url = "script/apps/Aries/Creator/Game/GameMarket/SaveWorldPage.html", 
			name = "MCSaveWorldPage.ShowPage", 
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