--[[
Title: edit parent link in ActorNPC
Author(s): LiXizhi
Date: 2018/2/8
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/EditParentLinkPage.lua");
local EditParentLinkPage = commonlib.gettable("MyCompany.Aries.Game.Movie.EditParentLinkPage");
EditParentLinkPage.ShowPage("0", actor, function(values)
	echo(values);
end, {target={}, pos={}, rot={}, use_rot=true})
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CmdParser.lua");
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");
local EditParentLinkPage = commonlib.gettable("MyCompany.Aries.Game.Movie.EditParentLinkPage");

local page;
function EditParentLinkPage.OnInit()
	page = document:GetPageCtrl();
end

-- @param curTime: current time
-- @param actor: actor NPC which would be linked to target bone
-- @param OnOK: function(values) end 
-- @param old_value: {target={}, pos={}, rot={}, use_rot=true}
function EditParentLinkPage.ShowPage(curTime, actor, OnOK, old_value)
	EditParentLinkPage.result = nil;
	EditParentLinkPage.title = format(L"父连接: 起始时间%s", tostring(curTime));
	local lastSelectionName = actor:GetMovieClipEntity():GetLastSelectionName();
	if(lastSelectionName) then
		EditParentLinkPage.lastSelectedBoneName = L"最近选择的骨骼名字: "..lastSelectionName;
	else
		EditParentLinkPage.lastSelectedBoneName = L"请先选骨骼";
	end
	if(old_value) then
		EditParentLinkPage.last_values = old_value;
	else
		EditParentLinkPage.last_values = {target=lastSelectionName, rot={0,0,0}, pos={0,0,0}, use_rot=true};
	end
	
	
	local params = {
			url = "script/apps/Aries/Creator/Game/Movie/EditParentLinkPage.html", 
			name = "EditParentLinkPage.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			bToggleShowHide=false, 
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			click_through = false, 
			enable_esc_key = true,
			bShow = true,
			isTopLevel = true,
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			directPosition = true,
				align = "_ct",
				x = -256,
				y = -200,
				width = 512,
				height = 400,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
	params._page.OnClose = function()
		if(EditParentLinkPage.result == "OK") then
			OnOK(EditParentLinkPage.last_values);
		end
	end

	EditParentLinkPage.OnReset();
end

function EditParentLinkPage:GetLastSelectedBoneName()
	return EditParentLinkPage.lastSelectedBoneName;
end

function EditParentLinkPage.GetTitle()
	return EditParentLinkPage.title;
end

function EditParentLinkPage.OnReset()
	EditParentLinkPage.UpdateUIFromValue(EditParentLinkPage.last_values);
end

function EditParentLinkPage.UpdateUIFromValue(values)
	if(page and values) then
		page:SetValue("target", values.target or "");
		page:SetValue("pos", values.pos and string.format("%f,%f,%f", values.pos[1], values.pos[2], values.pos[3]) or "0,0,0");
		page:SetValue("rot", values.rot and string.format("%f,%f,%f", values.rot[1] / math.pi * 180, values.rot[2] / math.pi * 180, values.rot[3] / math.pi * 180) or "0,0,0");
		page:SetValue("use_rot", values.use_rot and true or false);
	end
end

function EditParentLinkPage.OnDetach()
	page:SetValue("target", "");
	page:SetValue("pos", "0,0,0");
	page:SetValue("rot", "0,0,0");
end

function EditParentLinkPage.OnOK()
	if(page) then
		local v = {};
		local target = page:GetValue("target") or "";
		v.target = target;
		local vars = CmdParser.ParseNumberList(page:GetValue("pos"), nil, "|,%s");
		if(vars and vars[1] and vars[2] and vars[3]) then
			v.pos = {vars[1], vars[2], vars[3]}
		else
			v.pos = {0,0,0}
		end
		local vars = CmdParser.ParseNumberList(page:GetValue("rot"), nil, "|,%s");
		if(vars and vars[1] and vars[2] and vars[3]) then
			v.rot = {vars[1] / 180 * math.pi, vars[2] / 180 * math.pi, vars[3] / 180 * math.pi}
		else
			v.rot = {0,0,0}
		end
		if(page:GetValue("use_rot")) then
			v.use_rot = true;
		end
		EditParentLinkPage.last_values = v;
		EditParentLinkPage.result = "OK";
		page:CloseWindow();
	end
end

function EditParentLinkPage.OnClose()
	page:CloseWindow();
end
