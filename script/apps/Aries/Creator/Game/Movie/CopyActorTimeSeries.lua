--[[
Title: copy actor time series
Author(s): LiXizhi
Date: 2020/3/9
Desc: copy and paste actor time series
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/CopyActorTimeSeries.lua");
local CopyActorTimeSeries = commonlib.gettable("MyCompany.Aries.Game.Movie.CopyActorTimeSeries");
CopyActorTimeSeries.ShowPage(actor, fromTime, toTime)
CopyActorTimeSeries.PasteToActor(actor)
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/MovieClipTimeLine.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Clipboard.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/TimeSeries.lua");
local TimeSeries = commonlib.gettable("MyCompany.Aries.Game.Common.TimeSeries");
local Clipboard = commonlib.gettable("MyCompany.Aries.Game.Common.Clipboard");
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local MovieClipTimeLine = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieClipTimeLine");

local CopyActorTimeSeries = commonlib.gettable("MyCompany.Aries.Game.Movie.CopyActorTimeSeries");

local page;
local nameDS = {};
CopyActorTimeSeries.isSelectAll = true;

function CopyActorTimeSeries.OnInit()
	page = document:GetPageCtrl();
end

function CopyActorTimeSeries.GetDs(index)
	if(not index) then
		return #nameDS;
	else
		return nameDS[index];
	end
end

function CopyActorTimeSeries.CreatePropertyDs(actor)
	local ds = {};
	if(actor) then
--		if(actor:CanShowCommandVariables()) then
--			local cmdActor = MovieClipTimeLine:GetCmdActor(true);
--			if(cmdActor) then
--				for index, name in ipairs(cmdActor:GetEditableVariableList()) do
--					if(name ~= "---") then
--						ds[#ds+1] = {name=name, displayName = MovieClipTimeLine:GetVariableDisplayName(name), checked = CopyActorTimeSeries.isSelectAll};
--					end
--				end
--			end
--		end
		for index, name in ipairs(actor:GetEditableVariableList()) do
			if(name ~= "---") then
				local checked = CopyActorTimeSeries.isSelectAll;
				if(name == "pos") then
					checked = false;
				end
				ds[#ds+1] = {name=name, displayName = MovieClipTimeLine:GetVariableDisplayName(name), checked = checked};
			end
		end
	end
	return ds
end

function CopyActorTimeSeries.GetItemStack()
	return CopyActorTimeSeries.itemStack
end

function CopyActorTimeSeries.GetActor()
	return CopyActorTimeSeries.actor;
end

function CopyActorTimeSeries.ToggleSelect(bSelectAll)
	CopyActorTimeSeries.isSelectAll = bSelectAll;
	local checked = bSelectAll
	echo({checked})
	for _, item in ipairs(nameDS) do
		item.checked = checked
	end
	if(page) then
		page:CallMethod("nameGvw", "DataBind")
	end
end

-- @param OnOK: function(values) end 
-- @param old_value: {name="ximi", isAgent=true, isServer=false}
function CopyActorTimeSeries.ShowPage(actor, fromTime, toTime)
	CopyActorTimeSeries.result = nil;
	
	actor = actor or MovieClipTimeLine:GetSelectedActor();
	if(not actor) then
		return
	end
	nameDS = CopyActorTimeSeries.CreatePropertyDs(actor)
	CopyActorTimeSeries.itemStack = actor:GetItemStack();
	CopyActorTimeSeries.actor = actor;

	local params = {
		url = "script/apps/Aries/Creator/Game/Movie/CopyActorTimeSeries.html", 
		name = "CopyActorTimeSeries.ShowPage", 
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

	if(page) then
		page:SetUIValue("fromTime", tostring(fromTime or 0))
		page:SetUIValue("toTime", tostring(toTime or ""))
	end
end


function CopyActorTimeSeries.UpdateUIFromValue(values)
	if(page and values) then
		page:SetValue("name", values.name or "");
	end
end

function CopyActorTimeSeries.ToggleVariable(bChecked, mcmlNode)
	local item = mcmlNode:GetPreValue("this", true);
	if(item and item.checked~=nil) then
		item.checked = bChecked;
	end
end

function CopyActorTimeSeries.OnClickCopy()
	if(page and CopyActorTimeSeries.GetActor()) then
		local v = {};
		local actor = CopyActorTimeSeries.GetActor();
		local mainTs = actor:GetTimeSeries()
		for _, item in ipairs(nameDS) do
			if(item.checked) then
				local var = mainTs:GetVariable(item.name);
				if(not var) then
					local ts = mainTs:GetChild(item.name);
					if(ts) then
						var = ts:SaveToTable();
					end
				end
				v[item.name] = var;
			end
		end
		local fromTime = tonumber(page:GetUIValue("fromTime", 0));
		local toTime = tonumber(page:GetUIValue("toTime", 0));

		if(next(v)) then
			Clipboard.Save("ActorTimeSeries", {data = v, fromTime=fromTime, toTime = toTime, itemId = CopyActorTimeSeries.GetItemStack().id})	
			-- GameLogic.AddBBS(nil, L"", 4000, "0 255 0")
		end

		page:CloseWindow();
	end
end

-- public method:
function CopyActorTimeSeries.PasteToActor(actor)
	actor = actor or MovieClipTimeLine:GetSelectedActor();
	if(not actor) then
		return
	end
	local itemStack = actor:GetItemStack();
	local obj = Clipboard.LoadByType("ActorTimeSeries")
	if(obj and itemStack) then
		if(obj.itemId == itemStack.id) then
			actor:BeginUpdate();
			actor:BeginModify();
			local fromTime = obj.fromTime or 0;
			local toTime = obj.toTime;
			local pasteFromTime = actor:GetTime() or 0;
			local ts = TimeSeries:new();
			ts:LoadFromTable(obj.data);
			for i=1, ts:GetVariableCount() do
				local fromVar = ts:GetVariableByIndex(i);
				local var = actor:GetVariable(ts:GetVariableName(i));
				if(var and fromVar) then
					var:RemoveKeysInTimeRange(pasteFromTime+fromTime, toTime and (pasteFromTime+toTime));
					for time, v in fromVar:GetKeys_Iter(1, fromTime-1, fromVar:GetLastTime()) do
						var:UpsertKeyFrame(pasteFromTime+fromTime+time, v)
					end
				end
			end
			
			local tsBones = ts:GetChild("bones");
			if(tsBones) then
				local boneVars = actor:GetBonesVariable();
				if(boneVars) then
					for i=1, tsBones:GetVariableCount() do
						local fromVar = tsBones:GetVariableByIndex(i);
						local boneName = tsBones:GetVariableName(i)
						local var = boneVars:GetBoneAttributeVariableByName(boneName);
						-- only pasting on matching bone names
						if(var and fromVar) then
							var:RemoveKeysInTimeRange(pasteFromTime+fromTime, toTime and (pasteFromTime+toTime));
							for time, v in fromVar:GetKeys_Iter(1, fromTime-1, fromVar:GetLastTime()) do
								var:UpsertKeyFrame(pasteFromTime+fromTime+time, v)
							end
						end
					end
				end
			end
			actor:EndModify();
			actor:EndUpdate();
			actor:FrameMovePlaying(0);
			GameLogic.AddBBS(nil, L"成功粘贴参数", 4000, "0 255 0");
		else
			local item = ItemClient.GetItem(obj.itemId);
			if(item) then
				_guihelper.MessageBox(format(L"目标类型不匹配, 请选择 %s 粘贴", item:GetDisplayName()));
			end
		end
	end
end


function CopyActorTimeSeries.OnClose()
	page:CloseWindow();
end
