--[[
Title: Role Play Movie Context
Author(s): LiXizhi
Date: 2021/9/27
Desc: Role playing mode for movie block. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/RolePlayMode/RolePlayMovieContext.lua");
local RolePlayMovieContext = commonlib.gettable("MyCompany.Aries.Game.SceneContext.RolePlayMovieContext");
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/World/CameraController.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/RolePlayMode/RolePlayMovieController.lua");
local RolePlayMovieController = commonlib.gettable("MyCompany.Aries.Game.Movie.RolePlayMode.RolePlayMovieController");
local CameraController = commonlib.gettable("MyCompany.Aries.Game.CameraController")
local MovieUISound = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieUISound");
local SelectionManager = commonlib.gettable("MyCompany.Aries.Game.SelectionManager");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local MovieManager = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieManager");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local BaseContext = commonlib.gettable("MyCompany.Aries.Game.SceneContext.BaseContext");
local RolePlayMovieContext = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.SceneContext.EditContext"), commonlib.gettable("MyCompany.Aries.Game.SceneContext.RolePlayMovieContext"));

RolePlayMovieContext:Property("Name", "RolePlayMovieContext");
RolePlayMovieContext:Signal("boneChanged", function(boneEntity) end);
local state_config = {
	state_glove = 1,
	state_brush = 2,
	state_paint = 3,
	state_other = 4,
}
RolePlayMovieContext.move_timer = nil

RolePlayMovieContext.m_select_state = state_config.state_other
function RolePlayMovieContext:ctor()
end

-- virtual function: 
-- try to select this context. 
function RolePlayMovieContext:OnSelect()
	RolePlayMovieContext._super.OnSelect(self);
	self:updateManipulators();
end

-- virtual function: 
-- return true if we are not in the middle of any operation and fire unselected signal. 
-- or false, if we can not unselect the scene tool context at the moment. 
function RolePlayMovieContext:OnUnselect()
	RolePlayMovieContext._super.OnUnselect(self);
	return true;
end

function RolePlayMovieContext:updateManipulators()
	self:DeleteManipulators();
end


function RolePlayMovieContext:HandleGlobalKey(event)
	local dik_key = event.keyname;
	local ctrl_pressed = event.ctrl_pressed;
	if(System.options.isAB_SDK or System.options.mc) then
		if(dik_key == "DIK_F12" and not ctrl_pressed) then
			System.App.Commands.Call("Help.Debug");
			event:accept();
		elseif(dik_key == "DIK_F3" and ctrl_pressed) then
			System.App.Commands.Call("File.MCMLBrowser");
			event:accept();
		elseif(dik_key == "DIK_F4") then
			if(ctrl_pressed) then
				System.App.Commands.Call("Help.ToggleReportAndBoundingBox");
			else
				System.App.Commands.Call("Help.ToggleWireFrame");
			end
			event:accept();
		end
		if(event:isAccepted()) then
			return true;
		end
	end
	
	if(GameLogic.GameMode:IsAllowGlobalEditorKey()) then
		if(dik_key == "DIK_TAB") then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TeleportPlayerTask.lua");
			local task = MyCompany.Aries.Game.Tasks.TeleportPlayer:new({mode="vertical", isUpward = not event.shift_pressed, add_to_history=false});
			task:Run();
			event:accept();
		elseif(dik_key == "DIK_F3") then
			if(event.shift_pressed) then
				NPL.load("(gl)script/ide/GUI_inspector_simple.lua");
				-- call this function at any time to inspect UI at the current mouse position
				CommonCtrl.GUI_inspector_simple.InspectUI(); 
			else
				if(not ctrl_pressed) then
					GameLogic.RunCommand("/show info");
				end
			end
			event:accept();
		elseif(ctrl_pressed and dik_key == "DIK_P") then
			GameLogic.RunCommand("/stop");
			event:accept();
		else
			-- ctrl + Keys
			if(ctrl_pressed) then
				if(dik_key == "DIK_O") then
					-- show module manager
					GameLogic.RunCommand("/menu file.loadworld");
					event:accept();
				elseif(dik_key == "DIK_N") then
					-- show module manager
					GameLogic.RunCommand("/menu file.createworld");
					event:accept();
				end
				if not GameLogic.IsReadOnly() then
					if(dik_key == "DIK_F") then
						-- find block 
						if(event.shift_pressed) then
							GameLogic.RunCommand("/findfile");
						else
							GameLogic.RunCommand("/menu window.find");
						end
						event:accept();
					elseif(dik_key == "DIK_C" or dik_key == "DIK_V") then
						NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SelectBlocksTask.lua");
						local SelectBlocks = commonlib.gettable("MyCompany.Aries.Game.Tasks.SelectBlocks");
							
						if(dik_key == "DIK_C") then
							-- copy current mouse cursor block to clipboard
							SelectBlocks.CopyToClipboard();
						elseif(dik_key == "DIK_V") then
							-- paste from clipboard
							SelectBlocks.PasteFromClipboard();
						end
						event:accept();
						
						if(GameLogic.Macros:IsRecording()) then
							local angleX, angleY = GameLogic.Macros.GetSceneClickParams();
							GameLogic.Macros:AddMacro("NextKeyPressWithMouseMove", angleX, angleY);
						end
					end
				end
				
			end
		end
	end
	
	if(dik_key == "DIK_ESCAPE") then
		-- handle escape key
		self:HandleEscapeKey();
		event:accept();
	elseif(dik_key == "DIK_LWIN") then
		-- the menu key on andriod. 
		if(System.options.IsMobilePlatform and ParaScene.IsSceneEnabled()) then
			GameLogic.ToggleDesktop("esc");
		end
	elseif(dik_key == "DIK_RETURN") then
		if not GameLogic.GetFilters():apply_filters("HandleGlobalKeyByRETURN") then
			if(GameLogic.GameMode:CanChat()) then
				NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/ChatWindow.lua");
				MyCompany.Aries.ChatSystem.ChatWindow.ShowAllPage(true);
				event:accept();
			end
		end
	elseif(dik_key == "DIK_S" and ctrl_pressed) then
		event:accept();
		if not GameLogic.IsReadOnly() then
			GameLogic.RunCommand("/save");
		end
	elseif(dik_key == "DIK_I" and ctrl_pressed and event.shift_pressed) then
		GameLogic.RunCommand("/open npl://debugger");
		event:accept();
	elseif(dik_key == "DIK_F1") then
		GameLogic.RunCommand("/menu help.help");
		event:accept();
	elseif(dik_key == "DIK_F7") then
		local RedSummerCampMainWorldPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampMainWorldPage.lua");
		local RedSummerCampPPtPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampPPtPage.lua");
		if RedSummerCampMainWorldPage.IsOpen() then
			RedSummerCampPPtPage.ClosePPtAllPage()
		else
			RedSummerCampMainWorldPage.SetOpenFromCommandMenu(true)
			RedSummerCampMainWorldPage.Show();
			
			RedSummerCampPPtPage.OpenLastPPtPage()
		end
		event:accept();
	end

	if (ctrl_pressed and event.alt_pressed) then
		if (dik_key == "DIK_1") then
			GameLogic.RunCommand("share", "10");
			event:accept();
		elseif (dik_key == "DIK_3") then
			GameLogic.RunCommand("share", "30");
			event:accept();
		end
	end
	return event:isAccepted();
end

function RolePlayMovieContext:handlePlayerKeyEvent(event)
	local dik_key = event.keyname;
	if(not event.ctrl_pressed and not event.alt_pressed) then
		if(dik_key == "DIK_SPACE") then
			GameLogic.DoJump();
			event:accept();
		elseif(dik_key == "DIK_F") then
			-- fly mode
			if(GameLogic.GameMode:CanFly()) then
				GameLogic.ToggleFly();
			else
				NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
				local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
				local generatorName = WorldCommon.GetWorldTag("world_generator");
				if (generatorName == "paraworld") then
					GameLogic.IsVip("FlyOnParaWorld", true, function(result)
						if result then
							GameLogic.options:SetCanJumpInAir(true);
							GameLogic.ToggleFly();
						end
					end)
				else
                    _guihelper.CloseMessageBox();
					_guihelper.MessageBox(L"此世界禁止飞行哦！");
				end
			end
			event:accept();
		elseif(dik_key == "DIK_Q") then
			GameLogic.GetPlayerController():ThrowBlockInHand();
			event:accept();
		end
	end
	return event:isAccepted()
end

-- virtual: 
function RolePlayMovieContext:mousePressEvent(event)
	local result = self:CheckMousePick();
	local click_data = self:GetClickData();
	if(event.mouse_button == "left") then --这里是左键删除方块的逻辑
		-- play touch step sound when left click on an object
		if(result and result.block_id and result.block_id > 0) then
			click_data.last_mouse_down_block.blockX, click_data.last_mouse_down_block.blockY, click_data.last_mouse_down_block.blockZ = result.blockX,result.blockY,result.blockZ;
			local block = block_types.get(result.block_id);
			if(block and result.blockX) then
				-- block:OnMouseDown(result.blockX,result.blockY,result.blockZ, event.mouse_button);
				event:accept();
			end
		end
	end
	if(event:isAccepted()) then
		return
	end
	RolePlayMovieContext._super.mousePressEvent(self, event);
end

-- virtual: 
function RolePlayMovieContext:mouseMoveEvent(event)
	RolePlayMovieContext._super.mouseMoveEvent(self, event);
	if(event:isAccepted()) then
		return
	end
end

function RolePlayMovieContext:mouseReleaseEvent(event)
	local mouseCaptureEntity = self.mouseCaptureEntity;
	self.mouseCaptureEntity = nil;
	if mouseCaptureEntity then
		mouseCaptureEntity:mouseReleaseEvent(event)
	end
	if(event:isAccepted()) then
		return
	end
	RolePlayMovieContext:HandleKeyRelease(event)
	if(event:isAccepted()) then
		return
	end
	RolePlayMovieContext._super.mouseReleaseEvent(self, event);	
end

-- this function is called repeatedly if MousePickTimer is enabled. 
-- it can also be called independently. 
-- @return the picking result table
function RolePlayMovieContext:CheckMousePick()
	if(self.mousepick_timer) then
		self.mousepick_timer:Change(50, nil);
	end

	local result = SelectionManager:MousePickBlock();
	if(self:GetEditMarkerBlockId() and result and result.block_id and result.block_id>0 and result.blockX) then
		local y = BlockEngine:GetFirstBlock(result.blockX, result.blockY, result.blockZ, self:GetEditMarkerBlockId(), 5);
		if(y<0) then
			-- if there is no helper blocks below the picking position, we will return nothing. 
			SelectionManager:ClearPickingResult();
			self:ClearPickDisplay();
			return;
		end
	end

	--CameraController.OnMousePick(result, SelectionManager:GetPickingDist());
	if(result.length and result.blockX) then
        if(EntityManager.GetFocus())then
            if(not EntityManager.GetFocus():CanReachBlockAt(result.blockX,result.blockY,result.blockZ)) then
			    SelectionManager:ClearPickingResult();
		    end
        end
	end
	-- highlight the block or terrain that the mouse picked --and GameLogic.GameMode:CanSelect()
	if(result.length and result.length<SelectionManager:GetPickingDist() ) then
		if (GameLogic.GameMode:IsEditor()) then
			self:HighlightPickBlock(result);
		end
		self:HighlightPickEntity(result);
		return result;
	else
		self:ClearPickDisplay();
	end
end

function RolePlayMovieContext:HandleKeyRelease(event)
	local result = self:CheckMousePick();
	if not result then
		return 
	end
	local x,y,z = BlockEngine:GetBlockIndexBySide(result.blockX,result.blockY,result.blockZ,result.side);
	local itemStack = EntityManager.GetPlayer():GetItemInRightHand();
	local block_id = 0;
	local block_data = nil;
	if(itemStack) then
		block_id = itemStack.id;
		local item = itemStack:GetItem();
		if(item) then
			block_data = item:GetBlockData(itemStack);
		else
			LOG.std(nil, "debug", "RolePlayMovieContext", "no block definition for %d", block_id or 0);
			return;
		end
	end
	local click_data = self:GetClickData()
	if click_data.left_holding_time < 400 and result and result.blockX then
		if RolePlayMovieContext.GetIsSelectPaint() then
			event:accept();
			if(block_id and block_id > 0) or result.block_id == block_types.names.water then
				-- if ctrl key is pressed, we will replace block at the cursor with the current block in right hand. 
				NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ReplaceBlockTask.lua");
				local task = MyCompany.Aries.Game.Tasks.ReplaceBlock:new({blockX = result.blockX,blockY = result.blockY, blockZ = result.blockZ, to_id = block_id or 0, to_data = block_data, max_radius = RolePlayMovieContext.paint_radius or 10, preserveRotation=true})
				task:Run();
				return 
			end
			-- GameLogic.AddBBS(nil,"请选择你要使用的方块")
			
		end
		if RolePlayMovieContext.GetIsSelectBrush() then
			event:accept()
			if(block_id and block_id > 0) then
				-- if alt key is pressed, we will replace block at the cursor with the current block in right hand. 
				NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ReplaceBlockTask.lua");
				local task = MyCompany.Aries.Game.Tasks.ReplaceBlock:new({blockX = result.blockX,blockY = result.blockY, blockZ = result.blockZ, to_id = block_id, max_radius = 0, side = result.side, preserveRotation=true})
				task:Run();
				return 
			end
			-- GameLogic.AddBBS(nil,"请选择你要使用的方块")
		end
		if RolePlayMovieContext.GetIsSelectGlove() then
			if block_id and block_id > 0  then
				-- print("block_id==============",block_id)
				--选择拿起的方块

				return
			end
			-- GameLogic.AddBBS(nil,"请去世界里寻找你需要放置的物品，然后使用手套获取")
		end
		
		if self.GetIsSelectOther() then
			return
		end
	end
end

-- virtual: actually means key stroke. 
function RolePlayMovieContext:keyPressEvent(event)
	RolePlayMovieContext._super.keyPressEvent(self, event);
	if(event:isAccepted()) then
		return
	end
end

-- @param block: if nil, means toggle
function RolePlayMovieContext:ToggleLockAllActors(block)
	local movieclip = MovieManager:GetActiveMovieClip();
	if(movieclip and not movieclip:IsPlayingMode()) then
		if(movieclip:IsPaused()) and RolePlayMovieController.ToggleLockAllActors then
			RolePlayMovieController.ToggleLockAllActors(false);
		end
		return true;
	end
end

function RolePlayMovieContext.FindDecorateEntity() --双击吸取方块
	
end

function RolePlayMovieContext.GetDecorateOnHand() --把方块拿在手上
	if not RolePlayMovieContext.GetIsSelectGlove() then
		return 
	end
	local entity = RolePlayMovieContext.FindDecorateEntity()
	if entity and entity.GetItemClass then
		local item_class = entity:GetItemClass();
		if(item_class) then
			local itemStack = item_class:ConvertEntityToItem(entity);
			if(itemStack) then
				GameLogic.GetPlayerController():SetBlockInRightHand(itemStack);
			end
		end
	end	
end

function RolePlayMovieContext.SetIsSelectPaint() --油漆桶
	RolePlayMovieContext.m_select_state = state_config.state_paint
end

function RolePlayMovieContext.GetIsSelectPaint()
	return RolePlayMovieContext.m_select_state == state_config.state_paint
end

function RolePlayMovieContext.SetPaintRadius(radius)
	RolePlayMovieContext.paint_radius = radius or 30
	if RolePlayMovieContext.paint_radius > 100 then
		RolePlayMovieContext.paint_radius = 100
	end
end

function RolePlayMovieContext.SetIsSelectBrush() --刷子
	RolePlayMovieContext.m_select_state = state_config.state_brush
end

function RolePlayMovieContext.GetIsSelectBrush()
	return RolePlayMovieContext.m_select_state == state_config.state_brush
end

function RolePlayMovieContext.SetIsSelectGlove() --手套
	RolePlayMovieContext.m_select_state = state_config.state_glove
end

function RolePlayMovieContext.GetIsSelectGlove()
	return RolePlayMovieContext.m_select_state == state_config.state_glove
end

function RolePlayMovieContext.SetIsSelectOther()
	RolePlayMovieContext.m_select_state = state_config.state_other
end

function RolePlayMovieContext.GetIsSelectOther()
	return RolePlayMovieContext.m_select_state == state_config.state_other
end

 

