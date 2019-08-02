--[[
Title: Find Block Task Command
Author(s): LiXizhi
Date: 2019/6/10
Desc: Ctrl+F to activate this dialog.

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/FindBlockTask.lua");
local FindBlockTask = commonlib.gettable("MyCompany.Aries.Game.Tasks.FindBlockTask");
local task = MyCompany.Aries.Game.Tasks.FindBlockTask:new()
task:Run();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityManager.lua");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local FindBlockTask = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.FindBlockTask"));

-- whether to suppress any gui pop up. 
FindBlockTask:Property({"text", nil, "GetText", "SetText", auto=true});

FindBlockTask.resultDS = {};
FindBlockTask.selectedIndex = 1;
function FindBlockTask:ctor()
end

local page
function FindBlockTask.OnInit()
	page = document:GetPageCtrl();
end

function FindBlockTask:ShowPage(bShow)
	curInstance = self;
	FindBlockTask.filteredResultDS = nil;
	FindBlockTask.resultDS = {};
	FindBlockTask.selectedResultIndex = nil
	local width, height = 512, 400;
	System.App.Commands.Call("File.MCMLWindowFrame", {
			url = "script/apps/Aries/Creator/Game/Tasks/FindBlockTask.html", 
			name = "FindBlockTask.ShowPage", 
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			isShowTitleBar = false,
			bShow = bShow,
			DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
			style = CommonCtrl.WindowFrame.ContainerStyle,
			zorder = 1,
			allowDrag = true,
			enable_esc_key = true,
			directPosition = true,
				align = "_ctt",
				x = 0,
				y = 0,
				width = width,
				height = height,
		});
	if(bShow) then
		FindBlockTask.FindAll();
	end
end


-- @param bIsDataPrepared: true if data is prepared. if nil, we will prepare the data from input params.
function FindBlockTask:Run()
	self:ShowPage(true);
end

function FindBlockTask.FindAll()
	local entities = EntityManager.FindEntities({category="searchable", });
	FindBlockTask.SetResults(entities)
	FindBlockTask.UpdateResult();
end

function FindBlockTask.SetResults(entities)
	if(entities) then
		local resultDS = {};
		for i, entity in ipairs(entities) do
			local item = entity:GetItemClass()
			local name = entity:GetDisplayName();
			if(item and name and name~="") then
				resultDS[#resultDS+1] = {name="block", attr={index=i,name=name, icon = item:GetIcon()}};
			end
		end
		FindBlockTask.resultDS = resultDS;
		FindBlockTask.results = entities;
	end
end

function FindBlockTask.GetResultAt(index)
	if(index and FindBlockTask.results) then
		return FindBlockTask.results[index];
	end
end

function FindBlockTask.FilterResult(text)
	
	if(text and text~="") then
		local resultFiltered = {};
		for i, result in ipairs(FindBlockTask.resultDS) do
			if(result.attr.name:match(text)) then
				resultFiltered[#resultFiltered+1] = result;
			end
		end
		FindBlockTask.filteredResultDS = resultFiltered;
	else
		FindBlockTask.filteredResultDS = nil;
	end
	FindBlockTask.SetSelectedIndex(1)
	FindBlockTask.UpdateResult()
end

function FindBlockTask.UpdateResult()
	FindBlockTask.timerResult = FindBlockTask.timerResult or commonlib.Timer:new({callbackFunc = function(timer)
		if(page) then
			page:CallMethod("result", "SetDataSource", FindBlockTask.GetDataSource());
			page:CallMethod("result", "DataBind", true);
		end
	end})
	FindBlockTask.timerResult:Change(10);
end

function FindBlockTask.GetDataSource()
	return FindBlockTask.filteredResultDS or FindBlockTask.resultDS;
end

function FindBlockTask.OnClickItem(treenode)
	local index = treenode.mcmlNode:GetPreValue("this").index;

	FindBlockTask.SetSelectedResultIndex(index)
	FindBlockTask.OpenItemAtIndex(index);

	if(mouse_button == "left") then
		FindBlockTask.OnClose()
	end
end

function FindBlockTask.OpenItemAtIndex(index)
	local entity = FindBlockTask.GetResultAt(index);
	if(entity) then
		local x, y, z = entity:GetBlockPos()
		if(x) then
			GameLogic.RunCommand(string.format("/goto %d %d %d", x, y, z));
		end
	end
end

function FindBlockTask.OnClose()
	if(page) then
		page:CloseWindow();
	end
end

function FindBlockTask.OnKeyUp()
	local selectedIndex;
	if(virtual_key == Event_Mapping.EM_KEY_UP) then
		selectedIndex = FindBlockTask.selectedIndex - 1;
	elseif(virtual_key == Event_Mapping.EM_KEY_DOWN) then	
		selectedIndex = FindBlockTask.selectedIndex + 1;
	end
	if(selectedIndex) then
		if(selectedIndex and selectedIndex<1) then
			selectedIndex = 1;
		elseif(selectedIndex > #FindBlockTask.GetDataSource()) then
			selectedIndex = #FindBlockTask.GetDataSource();
		end
		FindBlockTask.SetSelectedIndex(selectedIndex);
	end
end

function FindBlockTask.GetSelectedIndex()
	return FindBlockTask.selectedIndex or 1;
end

function FindBlockTask.SetSelectedIndex(selectedIndex)
	if(FindBlockTask.selectedIndex~=selectedIndex) then
		FindBlockTask.selectedIndex = selectedIndex
	end
	local ds = FindBlockTask.GetDataSource()
	if(ds and ds[FindBlockTask.GetSelectedIndex()]) then
		FindBlockTask.SetSelectedResultIndex(ds[FindBlockTask.GetSelectedIndex()].attr.index)
	else
		FindBlockTask.SetSelectedResultIndex(1)
	end
end

function FindBlockTask.SetSelectedResultIndex(index)
	if(FindBlockTask.selectedResultIndex ~= index) then
		FindBlockTask.selectedResultIndex = index;
		if(page) then
			page:CallMethod("result", "ScrollToRow", FindBlockTask.GetSelectedIndex());
		end
		FindBlockTask.UpdateResult();
	end
end

function FindBlockTask.GetSelectedResultIndex()
	return FindBlockTask.selectedResultIndex or 1;
end

function FindBlockTask.OnOpen()
	FindBlockTask.OpenItemAtIndex(FindBlockTask.GetSelectedResultIndex());
	FindBlockTask.OnClose();
end

function FindBlockTask.OnTextChange()
	FindBlockTask.timer = FindBlockTask.timer or commonlib.Timer:new({callbackFunc = function(timer)
		if(page) then
			FindBlockTask.FilterResult(page:GetValue("text"))
		end
	end})
	FindBlockTask.timer:Change(500);
end