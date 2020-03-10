--[[
Title: copy actor time series
Author(s): LiXizhi
Date: 2020/3/9
Desc: copy and paste actor time series
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/CopyActorTimeSeries.lua");
local CopyActorTimeSeries = commonlib.gettable("MyCompany.Aries.Game.Movie.CopyActorTimeSeries");
CopyActorTimeSeries.ShowPage()
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/MovieClipTimeLine.lua");
local MovieClipTimeLine = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieClipTimeLine");

local CopyActorTimeSeries = commonlib.gettable("MyCompany.Aries.Game.Movie.CopyActorTimeSeries");

local page;
local nameDS = {};
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
		if(actor:CanShowCommandVariables()) then
			local cmdActor = self:GetCmdActor(true);
			if(cmdActor) then
				for index, name in ipairs(cmdActor:GetEditableVariableList()) do
					if(name ~= "---") then
						ds[#ds+1] = {name=name, displayName = MovieClipTimeLine:GetVariableDisplayName(name), };
					end
				end
			end
		end
		for index, name in ipairs(actor:GetEditableVariableList()) do
			if(name ~= "---") then
				ds[#ds+1] = {name=name, displayName = MovieClipTimeLine:GetVariableDisplayName(name), };
			end
		end
	end
	return ds
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
end


function CopyActorTimeSeries.UpdateUIFromValue(values)
	if(page and values) then
		page:SetValue("name", values.name or "");
	end
end

function CopyActorTimeSeries.OnClickCopy()
	if(page) then
		local v = {};
		local isServer = page:GetValue("isServer") or false;
		v.isServer = isServer;
		CopyActorTimeSeries.last_values = v;
		page:CloseWindow();
	end
end

function CopyActorTimeSeries.OnClose()
	page:CloseWindow();
end
