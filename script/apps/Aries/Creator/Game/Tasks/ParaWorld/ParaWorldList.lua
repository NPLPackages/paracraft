--[[
Title: paraworld list
Author(s): chenjinxian
Date: 2020/9/8
Desc: 
use the lib:
------------------------------------------------------------
local ParaWorldList = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldList.lua");
ParaWorldList.ShowPage();
-------------------------------------------------------
]]
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local KeepworkServiceSchoolAndOrg = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/SchoolAndOrg.lua")
NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/keepwork.world.lua");
local ParaWorldList = NPL.export();

ParaWorldList.Current_Item_DS = {};

local myParaWorldCount = 0;
local currentRegion = nil;
local page;
function ParaWorldList.OnInit()
	page = document:GetPageCtrl();
end

function ParaWorldList.ShowPage()
	ParaWorldList.provinces = {
		{
			text = L"省",
			value = 0,
			selected = true,
		}
	}

	ParaWorldList.cities = {
		{
			text = L"市",
			value = 0,
			selected = true,
		}
	}

	ParaWorldList.areas = {
		{
			text = L"区",
			value = 0,
			selected = true,
		}
	}
	for i = #(ParaWorldList.Current_Item_DS), 1, -1 do
		ParaWorldList.Current_Item_DS[i] = nil;
	end

	local params = {
		url = "script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldList.html",
		name = "ParaWorldList.ShowPage", 
		isShowTitleBar = false,
		DestroyOnClose = true,
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = true,
		enable_esc_key = true,
		app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
		directPosition = true,
		align = "_ct",
		x = -860 / 2,
		y = -560 / 2,
		width = 860,
		height = 560,
	};
	System.App.Commands.Call("File.MCMLWindowFrame", params);

	currentRegion = nil;
	commonlib.TimerManager.SetTimeout(function()
		ParaWorldList.LoadAllWorlds(function(loaded)
			page:Refresh(0);
			if (loaded) then
				ParaWorldList.GetRegionData();
			end
		end);
	end, 10);
end

function ParaWorldList.OnClose()
	page:CloseWindow();
end

function ParaWorldList.OnClickItem(index)
	local item = ParaWorldList.Current_Item_DS[index];
	if (item and item.projectId) then
		GameLogic.RunCommand("/loadworld -force "..item.projectId);
	end
end

function ParaWorldList.SetDefaultWorld(index)
	if (not index) then return end
	local item = ParaWorldList.Current_Item_DS[index];
	if (item and item.projectId) then
		keepwork.world.defaultParaWorld({paraWorldId = item.id}, function(err, msg, data)
			if (err == 200) then
				Mod.WorldShare.Store:Set("world/paraWorldId", item.id);
				for i = #(ParaWorldList.Current_Item_DS), 1, -1 do
					ParaWorldList.Current_Item_DS[i] = nil;
				end
				ParaWorldList.LoadAllWorlds(function(loaded)
					if (loaded) then
						page:Refresh(0);
					end
				end);
			end
		end);
	end
end

function ParaWorldList.ResetDefaultWorld(index)
	if (not index) then return end
	local item = ParaWorldList.Current_Item_DS[index];
	if (item and item.projectId) then
		keepwork.world.defaultParaWorld({paraWorldId = 0}, function(err, msg, data)
			if (err == 200) then
				Mod.WorldShare.Store:Set("world/paraWorldId", 0);
				for i = #(ParaWorldList.Current_Item_DS), 1, -1 do
					ParaWorldList.Current_Item_DS[i] = nil;
				end
				ParaWorldList.LoadAllWorlds(function(loaded)
					if (loaded) then
						page:Refresh(0);
					end
				end);
			end
		end);
	end
end

function ParaWorldList.IsDefaultWorld(index)
	if (not index) then return end
	local default = Mod.WorldShare.Store:Get("world/paraWorldId");
	local item = ParaWorldList.Current_Item_DS[index];
	if (item and item.id == default and default > 0) then
		return true;
	else
		return false;
	end
end

function ParaWorldList.GetRegionData()
	ParaWorldList.GetProvinces(function(data)
		if type(data) ~= "table" then
			return false
		end

		ParaWorldList.provinces = data

		if (page) then
			page:Refresh(0);
		end
	end)
end

function ParaWorldList.GetProvinces(callback)
	KeepworkServiceSchoolAndOrg:GetSchoolRegion("province", nil, function(data)
		if type(data) ~= "table" then
			return false
		end

		if type(callback) == "function" then
			for key, item in ipairs(data) do
				item.text = item.name
				item.value = item.id
			end

			data[#data + 1] = {
				text = L"省",
				value = 0,
				selected = true,
			}

			callback(data)
		end
	end)
end

function ParaWorldList.GetCities(id, callback)
	KeepworkServiceSchoolAndOrg:GetSchoolRegion("city", id, function(data)
		if type(data) ~= "table" then
			return false
		end

		if type(callback) == "function" then
			for key, item in ipairs(data) do
				item.text = item.name
				item.value = item.id
			end

			data[#data + 1] = {
				text = L"市",
				value = 0,
				selected = true,
			}

			callback(data)
		end
	end)
end

function ParaWorldList.GetAreas(id, callback)
	KeepworkServiceSchoolAndOrg:GetSchoolRegion('area', id, function(data)
		if type(data) ~= "table" then
			return false
		end

		if type(callback) == "function" then
			for key, item in ipairs(data) do
				item.text = item.name
				item.value = item.id
			end

			data[#data + 1] = {
				text = L"区",
				value = 0,
				selected = true,
			}

			callback(data)
		end
	end)
end

function ParaWorldList.SelectProvince(name, value)
	if value == 0 then
		return false
	end

	ParaWorldList.GetCities(value, function(data)
		ParaWorldList.cities = data
		ParaWorldList.areas = {
			{
			text = L"区",
			value = 0,
			selected = true,
			}
		}
		ParaWorldList.SeachParaWorld(nil, value);
	end)
end

function ParaWorldList.SelectCity(name, value)
	if value == 0 then
		return false
	end

	ParaWorldList.GetAreas(value, function(data)
		ParaWorldList.areas = data
		ParaWorldList.SeachParaWorld(nil, value);
	end)
end

function ParaWorldList.SelectArea(name, value)
	if value == 0 then
		return false
	end

	ParaWorldList.SeachParaWorld(nil, value);
end

function ParaWorldList.SeachParaWorld(keyWord, regionId)
	for i = #(ParaWorldList.Current_Item_DS), 1, -1 do
		ParaWorldList.Current_Item_DS[i] = nil;
	end
	currentRegion = regionId or currentRegion;
	if ((keyWord == nil or keyWord == "") and currentRegion == nil) then
		ParaWorldList.LoadAllWorlds(function(loaded)
			if (loaded) then
				page:Refresh(0);
				page:SetValue("seach_text", nil);
				page:FindControl('seach_text'):Focus();
			end
		end);
	else
		ParaWorldList.LoadWorldsByRegion(keyWord, currentRegion, function()
			page:Refresh(0);
			if (keyWord) then
				page:SetValue("seach_text", keyWord);
				page:FindControl('seach_text'):Focus();
				page:FindControl('seach_text'):SetCaretPosition(-1);
			end
		end);
	end
end

function ParaWorldList.LoadAllWorlds(callback)
	keepwork.world.list({}, function(err, msg, data)
		if (data and data.rows) then
			for i = 1, #(data.rows) do
				if (data.rows[i].topNo > 0) then
					ParaWorldList.Current_Item_DS[#ParaWorldList.Current_Item_DS+1] = data.rows[i];
				end
			end
			if (callback) then
				callback(false);
			end
		end

		keepwork.world.mylist(nil, function(err, msg, mydata)
			if (err == 200 and mydata) then
				for i = 1, #mydata do
					local exist = false;
					for j = 1, #ParaWorldList.Current_Item_DS do
						if (ParaWorldList.Current_Item_DS[j].projectId == mydata[i].projectId and ParaWorldList.Current_Item_DS[j].name == mydata[i].name) then
							ParaWorldList.Current_Item_DS[j].isMine = true;
							exist = true;
							break;
						end
					end
					if (not exist) then
						ParaWorldList.Current_Item_DS[#ParaWorldList.Current_Item_DS+1] = mydata[i];
						ParaWorldList.Current_Item_DS[#ParaWorldList.Current_Item_DS].isMine = true;
					end
				end
			end

			for i = 1, #(data.rows) do
				if (data.rows[i].topNo == 0) then
					local exist = false;
					for j = 1, #ParaWorldList.Current_Item_DS do
						if (ParaWorldList.Current_Item_DS[j].projectId == data.rows[i].projectId and ParaWorldList.Current_Item_DS[j].name == data.rows[i].name) then
							exist = true;
							break;
						end
					end
					if (not exist) then
						ParaWorldList.Current_Item_DS[#ParaWorldList.Current_Item_DS+1] = data.rows[i];
					end
				end
			end

			if (callback) then
				callback(true);
			end
		end);
	end);
end

function ParaWorldList.LoadWorldsByRegion(keyWord, regionId, callback)
	keepwork.world.list({keyword = keyWord, regionId = currentRegion}, function(err, msg, data)
		if (data and data.rows) then
			for i = 1, #(data.rows) do
				local exist = false;
				for j = 1, #ParaWorldList.Current_Item_DS do
					if (ParaWorldList.Current_Item_DS[j].projectId == data.rows[i].projectId and ParaWorldList.Current_Item_DS[j].name == data.rows[i].name) then
						exist = true;
						break;
					end
				end
				if (not exist) then
					ParaWorldList.Current_Item_DS[#ParaWorldList.Current_Item_DS+1] = data.rows[i];
				end
			end

			if (callback) then
				callback();
			end
		end
	end);
end