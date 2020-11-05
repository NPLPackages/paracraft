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
local KeepworkServiceSchoolAndOrg = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/SchoolAndOrg.lua")
NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/keepwork.world.lua");
local ParaWorldList = NPL.export();

ParaWorldList.Current_Item_DS = {};
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


local myParaWorldCount = 0;
local currentRegion = nil;
local page;
function ParaWorldList.OnInit()
	page = document:GetPageCtrl();
end

function ParaWorldList.ShowPage()
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

	for i = #(ParaWorldList.Current_Item_DS), 1, -1 do
		ParaWorldList.Current_Item_DS[i] = nil;
	end
	myParaWorldCount = 0;
	currentRegion = nil;
	commonlib.TimerManager.SetTimeout(function()
		keepwork.world.mylist(nil, function(err, msg, data)
			if (err == 200 and data) then
				for i = 1, #data do
					ParaWorldList.Current_Item_DS[#ParaWorldList.Current_Item_DS+1] = data[i];
					ParaWorldList.Current_Item_DS[#ParaWorldList.Current_Item_DS].top = true;
				end
				myParaWorldCount = #data;
			end

			keepwork.world.list(nil, function(err, msg, data)
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
					page:Refresh(0);
					ParaWorldList.GetRegionData();
				end
			end);
		end);
	end, 10);
end

function ParaWorldList.OnClose()
	page:CloseWindow();
end

function ParaWorldList.OnClickItem(index)
	local item = ParaWorldList.Current_Item_DS[index];
	if (item and item.projectId) then
		page:CloseWindow();
		GameLogic.RunCommand("/loadworld -force "..item.projectId);
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
		keepwork.world.mylist(nil, function(err, msg, data)
			if (err == 200 and data) then
				for i = 1, #data do
					ParaWorldList.Current_Item_DS[#ParaWorldList.Current_Item_DS+1] = data[i];
					ParaWorldList.Current_Item_DS[#ParaWorldList.Current_Item_DS].top = true;
				end
				myParaWorldCount = #data;
			end

			keepwork.world.list(nil, function(err, msg, data)
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
					page:Refresh(0);
					page:SetValue("seach_text", nil);
					page:FindControl('seach_text'):Focus();
				end
			end);
		end);
	else
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
				page:Refresh(0);
				if (keyWord) then
					page:SetValue("seach_text", keyWord);
					page:FindControl('seach_text'):Focus();
					page:FindControl('seach_text'):SetCaretPosition(-1);
				end
			end
		end);
	end
end