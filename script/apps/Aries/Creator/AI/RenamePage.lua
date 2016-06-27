--[[
Title: RenamePage.html code-behind script
Author(s): LiXizhi, Leio
Date: 2010/2/7
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/AI/RenamePage.lua");
MyCompany.Aries.Creator.AI.RenamePage.ShowPage(npc_name);
-------------------------------------------------------
]]
local RenamePage = commonlib.gettable("MyCompany.Aries.Creator.AI.RenamePage")

local page;

function RenamePage.OnInit()
	page = document:GetPageCtrl();	
	
	if(RenamePage.npc_name) then
		local char = ParaScene.GetObject(RenamePage.npc_name);
		
		if(char:IsCharacter()) then
			-- change character name directly. 
			local name = char:GetDynamicField("DisplayName", "");
			page:SetNodeValue("_name", name);
			page:SetNodeValue("assetfile", char:GetPrimaryAsset():GetKeyName());
		end	
	end	
end

function RenamePage.ClosePage()
	page:CloseWindow();
end

function RenamePage.ShowPage(npc_name)
	RenamePage.npc_name = npc_name;
	
	System.App.Commands.Call("File.MCMLWindowFrame", {
			url = "script/apps/Aries/Creator/AI/RenamePage.html", 
			name = "RenamePage.ShowPage", 
			app_key=MyCompany.Aries.app.app_key, 
			isShowTitleBar = false,
			DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
			style = CommonCtrl.WindowFrame.ContainerStyle,
			zorder = 3,
			isTopLevel = true,
			allowDrag = true,
			directPosition = true,
				align = "_ct",
				x = -150,
				y = -200,
				width = 350,
				height = 200,
		});
end

function RenamePage.DoSave()
	local name = page:GetValue("_name");
	name = string.gsub(name,"%s","");
	local name_len = ParaMisc.GetUnicodeCharNum(name);
	--if(name_len == 0)then
	    --_guihelper.MessageBox("<div style='margin-left:15px;margin-top:35px;text-align:center'>名字不能为空哦！</div>");
        --return;
    --end
	if(name_len > 16)then
		_guihelper.MessageBox("<div style='margin-left:15px;margin-top:35px;text-align:center'>名字不能超过16个字，请重新输入吧。</div>");
		return
	end
	
	local char = ParaScene.GetObject(RenamePage.npc_name);
	
	if(char:IsCharacter()) then
		-- change character name directly. 
		char:SetDynamicField("DisplayName", name);
		local NPC = commonlib.gettable("MyCompany.Aries.Quest.NPC");
		Map3DSystem.ShowHeadOnDisplay(true, char, name, NPC.HeadOnDisplayColor);

		local assetfile = page:GetValue("assetfile");
		if(assetfile) then
			assetfile = assetfile:gsub("%s", "");
		end
		local old_assetfile = char:GetPrimaryAsset():GetKeyName();
		if(assetfile and old_assetfile~=assetfile and assetfile:match("^[cC]haracter/.*%.x$")) then
			if(ParaIO.DoesAssetFileExist(assetfile, true)) then
				char:ToCharacter():ResetBaseModel(ParaAsset.LoadParaX("", assetfile));
			end
		end
	end
	
	RenamePage.ClosePage();
end