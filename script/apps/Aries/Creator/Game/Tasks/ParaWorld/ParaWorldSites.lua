--[[
Title: paraworld list
Author(s): chenjinxian
Date: 2020/9/8
Desc: 
use the lib:
------------------------------------------------------------
local ParaWorldSites = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldSites.lua");
ParaWorldSites.ShowPage();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/keepwork.world.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldLoginAdapter.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/World/generators/ParaWorldMiniChunkGenerator.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/BlockTemplatePage.lua");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local BlockTemplatePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.BlockTemplatePage");
local ParaWorldMiniChunkGenerator = commonlib.gettable("MyCompany.Aries.Game.World.Generators.ParaWorldMiniChunkGenerator");
local ParaWorldLoginAdapter = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaWorld.ParaWorldLoginAdapter");
local ParaWorldTakeSeat = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldTakeSeat.lua");
local ParaWorldSites = NPL.export();

ParaWorldSites.SitesNumber = {};
ParaWorldSites.Current_Item_DS = {};
ParaWorldSites.RowNumbers = {{}, {}, {}, {}, {}, {}, {}, {}, {}, {}};
ParaWorldSites.Locked = 1;
ParaWorldSites.Checked = 2;
ParaWorldSites.Selected = 3;
ParaWorldSites.Available = 4;

ParaWorldSites.currentRow = 5;
ParaWorldSites.currentColumn = 5;
ParaWorldSites.currentName = L"主世界";

ParaWorldSites.paraWorldName = L"并行世界";

ParaWorldSites.IsOwner = false;

local rows = 10;
local columns = 10;
local mainRange = {rows*4+5, rows*4+6, rows*5+5, rows*5+6};

local page;
function ParaWorldSites.OnInit()
	page = document:GetPageCtrl();
end

function ParaWorldSites.ShowPage()
	ParaWorldSites.currentRow = 5;
	ParaWorldSites.currentColumn = 5;
	ParaWorldSites.currentName = L"主世界";
	if (not ParaWorldSites.SitesNumber or #ParaWorldSites.SitesNumber < 1) then
		ParaWorldSites.InitSitesNumber();
	end
	if (not ParaWorldSites.Current_Item_DS or #ParaWorldSites.Current_Item_DS < 1) then
		ParaWorldSites.InitSitesData();
	end

	local params = {
		url = "script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldSites.html",
		name = "ParaWorldSites.ShowPage", 
		isShowTitleBar = false,
		DestroyOnClose = true,
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = true,
		enable_esc_key = true,
		app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
		directPosition = true,
		align = "_ct",
		x = -520 / 2,
		y = -392 / 2,
		width = 520,
		height = 392,
	};
	System.App.Commands.Call("File.MCMLWindowFrame", params);

	ParaWorldSites.IsOwner = false;
	if (ParaWorldLoginAdapter.ParaWorldId) then
		commonlib.TimerManager.SetTimeout(function()
			ParaWorldSites.UpdateSitesState();
			ParaWorldSites.CheckIsMyParaworld(function(world)
				ParaWorldSites.IsOwner = true;
			end);
		end, 100);
	end
end

function ParaWorldSites.OnClose()
	page:CloseWindow();
end

function ParaWorldSites.GetParaWorldName()
	return ParaWorldSites.paraWorldName;
end

function ParaWorldSites.UpdateSitesState()
	local state = ParaWorldSites.Locked;
	if (ParaWorldLoginAdapter.ParaWorldId) then
		state = ParaWorldSites.Available;
	end
	for i = 1, #ParaWorldSites.Current_Item_DS do
		ParaWorldSites.Current_Item_DS[i].state = state;
		ParaWorldSites.Current_Item_DS[i].name = L"空地";
	end
	keepwork.world.get({router_params={id=ParaWorldLoginAdapter.ParaWorldId}}, function(err, msg, data)
		if (data and data.sites) then
			ParaWorldSites.paraWorldName = data.name;
			ParaWorldSites.SetCurrentSite(data.sites);
			page:Refresh(0);
		end
	end);
end

function ParaWorldSites.CheckIsMyParaworld(callback)
	local projectId = GameLogic.options:GetProjectId();
	if (not projectId) then return end
	projectId = tonumber(projectId);
	if (not projectId) then return end
	local userId = tonumber(Mod.WorldShare.Store:Get("user/userId"));

	keepwork.world.joined_list({}, function(err, msg, data)
		if (data and type(data) == "table") then
			for i = 1, #data do
				local world = data[i];
				if (world.projectId == projectId and world.userId == userId) then
					if (callback) then
						callback(world);
					end
					break;
				end
			end
		end
	end);
end

function ParaWorldSites.SetCurrentSite(sites)
	for i = 1, #sites do
		local seat = sites[i];
		if (seat.sn and seat.status) then
			local pos = ParaWorldSites.SitesNumber[seat.sn];
			for j = 1, #ParaWorldSites.Current_Item_DS do
				local item = ParaWorldSites.Current_Item_DS[j];
				if (item.x == pos.row and item.y == pos.column) then
					if (seat.status == "locked") then
						item.state = ParaWorldSites.Locked;
					elseif (seat.status == "checked") then
						item.state = ParaWorldSites.Checked;
					end
					if (seat.paraMini and seat.paraMini.name) then
						item.name = seat.paraMini.name;
					end
					break;
				end
			end
		end
	end
end

function ParaWorldSites.InitSitesData()
	local state = ParaWorldSites.Locked;
	if (ParaWorldLoginAdapter.ParaWorldId) then
		state = ParaWorldSites.Available;
	end
	for i = 1, 10 do
		for j = 1, 10 do
			local valid = true;
			local index = (i-1) * rows + j;
			for k = 1, #mainRange do
				if (index == mainRange[k]) then
					valid = false;
					break;
				end
			end
			ParaWorldSites.Current_Item_DS[index] = {x = i, y = j, valid=valid, state=state};
		end
	end
end

function ParaWorldSites.InitSitesNumber()
	-- counterclockwise, start from row=5, column=4
	-- first down to radius unit, then right to radius unit, up to radius unit, last left to radius unit
	-- radius from 3 to 9, 3 5 7 9
	local index = 1;
	local radius = 3;
	local corner1, corner2 = 4, 7;
	for radius = 3, 9, 2 do
		-- down
		for i = 1, radius do
			ParaWorldSites.SitesNumber[index] = {row=corner1+i, column=corner1};
			index = index + 1;
		end
		-- right
		for i = 1, radius do
			ParaWorldSites.SitesNumber[index] = {row=corner2, column=corner1+i};
			index = index + 1;
		end
		-- up
		for i = 1, radius do
			ParaWorldSites.SitesNumber[index] = {row=corner2-i, column=corner2};
			index = index + 1;
		end
		-- left
		for i = 1, radius do
			ParaWorldSites.SitesNumber[index] = {row=corner1, column=corner2-i};
			index = index + 1;
		end
		corner1 = corner1 - 1;
		corner2 = corner2 + 1;
	end
end

function ParaWorldSites.GetIndexFromPos(row, column)
	for i = 1, #ParaWorldSites.SitesNumber do
		local pos = ParaWorldSites.SitesNumber[i];
		if (pos.row == row and pos.column == column) then
			return i;
		end
	end
end

function ParaWorldSites.OnClickItem(index)
	local projectId = GameLogic.options:GetProjectId();
	local item = ParaWorldSites.Current_Item_DS[index];
	if (item and projectId and tonumber(projectId)) then
		ParaWorldSites.currentRow, ParaWorldSites.currentColumn = item.x, item.y;
		if (item.state == ParaWorldSites.Locked) then
			ParaWorldSites.currentName = L"该地块已锁定";
			page:Refresh(0);
			if (ParaWorldSites.IsOwner) then
				_guihelper.MessageBox("该地块已锁定，你确定要解锁吗？", function(res)
					if(res and res == _guihelper.DialogResult.OK) then
						local id = ParaWorldSites.GetIndexFromPos(item.x, item.y);
						keepwork.world.unlock_seat({paraWorldId=ParaWorldLoginAdapter.ParaWorldId, sn=id}, function(err, msg, data)
							if (err == 200) then
								ParaWorldSites.UpdateSitesState();
							end
						end);
					end
				end, _guihelper.MessageBoxButtons.OKCancel);
			end
		elseif (item.state == ParaWorldSites.Checked) then
			ParaWorldSites.currentName = item.name or L"该地块已有人入驻";
			page:Refresh(0);
		else
			ParaWorldSites.currentName = item.name or L"空地";
			ParaWorldSites.Current_Item_DS[index].state = ParaWorldSites.Selected;
			page:Refresh(0);

			if (ParaWorldSites.IsOwner) then
				_guihelper.MessageBox(L"该地块为空地，你确定要锁定吗（否则占座）？", function(res)
					if(res and res == _guihelper.DialogResult.OK) then
						local id = ParaWorldSites.GetIndexFromPos(item.x, item.y);
						keepwork.world.lock_seat({paraWorldId=ParaWorldLoginAdapter.ParaWorldId, sn=id}, function(err, msg, data)
							if (err == 200) then
								ParaWorldSites.UpdateSitesState();
							end
						end);
					else
						ParaWorldSites.ShowTakeSeat(item, index);
					end
				end, _guihelper.MessageBoxButtons.OKCancel_CustomLabel,nil,nil,nil,nil,{ ok = L"锁定", cancel = L"占座", });
			else
				ParaWorldSites.ShowTakeSeat(item, index);
			end
		end
	end
end

function ParaWorldSites.ShowTakeSeat(item, index)
	local function resetState()
		ParaWorldSites.Current_Item_DS[index].state = ParaWorldSites.Available;
		page:Refresh(0);
	end
	
	ParaWorldTakeSeat.ShowPage(function(res, worldId)
		if (res) then
			local id = ParaWorldSites.GetIndexFromPos(item.x, item.y);
			if (not id) then
				resetState();
				_guihelper.MessageBox(L"所选的座位无效！");
				return;
			end
			keepwork.world.take_seat({paraMiniId=worldId, paraWorldId=ParaWorldLoginAdapter.ParaWorldId, sn=id}, function(err, msg, data)
				if (err == 200) then
					_guihelper.MessageBox(L"入驻成功！");
				else
					_guihelper.MessageBox(L"该座位已被占用，请选择其他座位入驻！");
				end
				ParaWorldSites.UpdateSitesState();
			end);
		else
			ParaWorldSites.Current_Item_DS[index].state = ParaWorldSites.Available;
			page:Refresh(0);
		end
	end);
end

function ParaWorldSites.OnClickMain()
	ParaWorldSites.currentRow = 5;
	ParaWorldSites.currentColumn = 5;
	ParaWorldSites.currentName = L"主世界";
	page:Refresh(0);
end

function ParaWorldSites.LoadMiniWorldOnSeat(row, column)
	if (not ParaWorldSites.SitesNumber or #ParaWorldSites.SitesNumber < 1) then
		ParaWorldSites.InitSitesNumber();
	end

	local sn = ParaWorldSites.GetIndexFromPos(row, column);
	keepwork.world.get({router_params={id=ParaWorldLoginAdapter.ParaWorldId}}, function(err, msg, data)
		if (data and data.sites) then
			for i = 1, #data.sites do
				local seat = data.sites[i];
				if (seat.sn and seat.paraMini and seat.sn == sn) then
					local path = ParaWorldMiniChunkGenerator:GetTemplateFilepath();
					local filename = ParaIO.GetFileName(path);
					local KeepworkServiceWorld = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/World.lua");
					KeepworkServiceWorld:GetSingleFile(seat.paraMini.projectId, filename, function(content)
						if (not content) then return end

						local name = commonlib.Encoding.Utf8ToDefault(seat.paraMini.name);
						local template_file = ParaIO.GetCurDirectory(0)..BlockTemplatePage.global_template_dir..name..".xml";
						local file = ParaIO.open(template_file, "w");
						if (file:IsValid()) then
							file:write(content, #content);
							file:close();
							local gen = GameLogic.GetBlockGenerator();
							local x, y = gen:GetGridXYBy2DIndex(column,row);
							local bx, by, bz = gen:GetBlockOriginByGridXY(x, y);
							gen:LoadTemplateAtGridXY(x, y, template_file);
						end
					end);
					break;
				end
			end
		end
	end);
end

function ParaWorldSites.LoadMiniWorldOnPos(x, z)
	if (GameLogic.IsReadOnly() and ParaWorldLoginAdapter.ParaWorldId and WorldCommon.GetWorldTag("world_generator") == "paraworld") then
		local gen = GameLogic.GetBlockGenerator();
		local gridX, gridY = gen:FromWorldPosToGridXY(x, z);
		local row, column = gen:Get2DIndexByGridXY(gridX, gridY);
		ParaWorldSites.LoadMiniWorldOnSeat(row, column);
	end
end
