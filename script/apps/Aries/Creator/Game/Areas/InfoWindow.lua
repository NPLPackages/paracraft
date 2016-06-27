--[[
Title: display debug or helper info in left top corner
Author(s): LiXizhi
Date: 2014/2/18
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/InfoWindow.lua");
local InfoWindow = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.InfoWindow");
InfoWindow.CopyToClipboard("mousepos")
InfoWindow.ShowPage()
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Direction.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SelectBlocksTask.lua");
local SelectBlocks = commonlib.gettable("MyCompany.Aries.Game.Tasks.SelectBlocks")
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local InfoWindow = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.InfoWindow");

local page;
local my_timer;

local engine_attr = ParaEngine.GetAttributeObject();

function InfoWindow.OnInit()
	page = document:GetPageCtrl();
	my_timer = my_timer or commonlib.Timer:new({callbackFunc = InfoWindow.OnTimer})
	my_timer:Change(300, 300);
end

function InfoWindow.ShowPage(bShow)
	System.App.Commands.Call("File.MCMLWindowFrame", {
			url = "script/apps/Aries/Creator/Game/Areas/InfoWindow.html", 
			name = "InfoWindow.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = false,
			bShow = bShow,
			bToggleShowHide=true, 
			zorder = 10,
			click_through = true,
			directPosition = true,
				align = "_lt",
				x = 36,
				y = 32,
				width = 300,
				height = 200,
		});
end

local last_info = {};

-- @return the info
function InfoWindow.UpdateInfo()
	local entityPlayer = EntityManager.GetFocus();
	if(not entityPlayer) then
		return;
	end
	local x, y, z = entityPlayer:GetBlockPos();
	local dir = Direction.directions[Direction.GetDirection2DFromCamera()];
	--local mx, my = ParaUI.GetMousePosition();
	--last_info.playerpos = format("%d %d %d:%s mouse:%d %d", x, y, z, dir or "", mx, my);
	last_info.playerpos = format("%d %d %d:%s", x, y, z, dir or "");
	
	local result = Game.SelectionManager:GetPickingResult();
	if(result and result.blockX) then
		local curSelection = SelectBlocks.GetCurrentSelection();
		local curSelectionInstance = SelectBlocks.GetCurrentInstance();
		local relTargetName;
		if(curSelectionInstance and curSelection and #curSelection > 1 and curSelectionInstance.aabb) then
			-- multi selection. 
			local x,y,z = curSelectionInstance.aabb:GetMinValues();
			local dx,dy,dz = curSelectionInstance.aabb:GetMaxValues();
			local rx, ry, rz = dx-x, dy-y, dz-z;

			last_info.mousepos = string.format("%d %d %d (%d %d %d)", x,y,z, rx, ry, rz);
			last_info.mouseposText = string.format("sel_min %d %d %d size(%d %d %d)", x,y,z, rx, ry, rz);
			
			local triggerEntity = EntityManager.GetLastTriggerEntity() or entityPlayer;
			local ox,oy,oz = triggerEntity:GetBlockPos();
			if(triggerEntity == EntityManager.GetPlayer()) then
				relTargetName = "player";
			else
				relTargetName = triggerEntity:GetName() or triggerEntity.class_name or "Last";
			end
			last_info.relativemousepos = string.format("~%d ~%d ~%d (%d %d %d)", x-ox,y-oy,z-oz, rx, ry, rz);
			last_info.relativemouseposText = string.format("%s: ~%d ~%d ~%d (%d %d %d)", relTargetName or "", x-ox,y-oy,z-oz, rx, ry, rz);
		else
			last_info.mousepos = string.format("%d %d %d", result.blockX,result.blockY,result.blockZ);
			local block_data = BlockEngine:GetBlockData(result.blockX,result.blockY,result.blockZ);
			local block_template = BlockEngine:GetBlock(result.blockX,result.blockY,result.blockZ);
			local block_name = "";
			if(block_template) then
				block_name = block_template:GetDisplayName();
			end
			
			last_info.mouseposText = string.format("%s:%s:%d side(%d)", last_info.mousepos, block_name, block_data, result.side or -1);
		
			if(curSelection and #curSelection == 1) then
				-- single selection
				local b = curSelection[1];
				x,y,z = b[1], b[2], b[3];
				relTargetName = "seletion";
			else
				local triggerEntity = EntityManager.GetLastTriggerEntity() or entityPlayer;
				x,y,z = triggerEntity:GetBlockPos();
				if(triggerEntity == EntityManager.GetPlayer()) then
					relTargetName = "player";
				else
					relTargetName = triggerEntity:GetName() or triggerEntity.class_name or "Last";
				end
			end
			local dx,dy,dz = BlockEngine:GetBlockIndexBySide(result.blockX,result.blockY,result.blockZ,result.side)
			if(dx) then
				local rx, ry, rz = dx-x, dy-y, dz-z;
				last_info.relativemousepos = string.format("~%d ~%d ~%d", rx, ry, rz);
				last_info.relativemouseposText = string.format("%s: ~%d ~%d ~%d", relTargetName or "", rx, ry, rz);
			end
		end
	else
		last_info.mousepos = "";
		last_info.relativemousepos = "";
	end
	
	local player = ParaScene.GetPlayer();
	local x,y,z = player:GetPosition();
	local tile_x, tile_z = BlockEngine:GetRegionPos(x,z);
	last_info.worldpos = string.format("%.2f %.2f %.2f (%.2f) Region(%d,%d)", x, y, z, player:GetFacing(), tile_x, tile_z);

	-- FPS, draw count, triangle count, memory used in MB, vertex buffer pool size in MB
	last_info.render_stats = string.format("FPS:%.0f Draw:%d Tri:%d Mem:%d VB:%d", engine_attr:GetField("FPS", 0), engine_attr:GetField("DrawCallCount", 0), engine_attr:GetField("TriangleCount", 0),
		engine_attr:GetField("CurrentMemoryUse", 0)/1048576, engine_attr:GetField("VertexBufferPoolTotalBytes", 0)/1048576)

	return last_info;
end

-- @param data_type: "mousepos", "relativemousepos", "worldpos", "playerpos", etc. 
function InfoWindow.CopyToClipboard(data_type)
	local info = InfoWindow.UpdateInfo();
	local text = info[data_type or "mousepos"];
	if(text) then
		ParaMisc.CopyTextToClipboard(text);
		local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
		BroadcastHelper.PushLabel({id="infowindow", label = text, max_duration=10000, color = "0 0 0", scaling=1, bold=true, shadow=true,});
	end
end

function InfoWindow.OnTimer(timer)
	if(not page:IsVisible()) then
		-- timer:Change();
		return;
	end
	local entityPlayer = EntityManager.GetPlayer();
	if(not entityPlayer) then
		return;
	end
	info = InfoWindow.UpdateInfo();

	page:SetUIValue("render_stats", info.render_stats);
	page:SetUIValue("playerpos", info.playerpos);
	page:SetUIValue("mousepos", info.mouseposText);
	page:SetUIValue("relativemousepos", info.relativemouseposText);
	page:SetUIValue("worldpos", info.worldpos);
end