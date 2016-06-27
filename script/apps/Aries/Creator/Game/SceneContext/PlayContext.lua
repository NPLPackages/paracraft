--[[
Title: Play Context
Author(s): LiXizhi
Date: 2015/7/10
Desc: handles scene key/mouse events. This is the default play mode scene context 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/PlayContext.lua");
local PlayContext = commonlib.gettable("MyCompany.Aries.Game.SceneContext.PlayContext");
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/BaseContext.lua");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local GameMode = commonlib.gettable("MyCompany.Aries.Game.GameLogic.GameMode");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local PlayContext = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.SceneContext.BaseContext"), commonlib.gettable("MyCompany.Aries.Game.SceneContext.PlayContext"));

PlayContext:Property("Name", "PlayContext");

function PlayContext:ctor()
	self:EnableAutoCamera(true);
end

-- virtual function: 
-- try to select this context. 
function PlayContext:OnSelect()
	PlayContext._super.OnSelect(self);
	self:EnableMousePickTimer(true);
end

-- virtual function: 
-- return true if we are not in the middle of any operation and fire unselected signal. 
-- or false, if we can not unselect the scene tool context at the moment. 
function PlayContext:OnUnselect()
	PlayContext._super.OnUnselect(self);
	return true;
end

function PlayContext:OnLeftLongHoldBreakBlock()
	self:TryDestroyBlock(Game.SelectionManager:GetPickingResult());
end

-- For Numeric key 1-9
function PlayContext:HandleQuickSelectKey(event)
	if(not System.options.IsMobilePlatform) then
		-- For Numeric key 1-9
		local key_index = event.keyname:match("^DIK_(%d)");
		if(key_index) then
			key_index = tonumber(key_index);
			NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/QuickSelectBar.lua");
			local QuickSelectBar = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.QuickSelectBar");
			QuickSelectBar.OnSelectByKeyIndex(key_index);
			event:accept();
			return true;
		end
	end
end

-- virtual: 
function PlayContext:mousePressEvent(event)
	PlayContext._super.mousePressEvent(self, event);
	if(event:isAccepted()) then
		return
	end
	local click_data = self:GetClickData();

	self:EnableMouseDownTimer(true);

	local result = self:CheckMousePick();
	self:UpdateClickStrength(0, result);

	if(event.mouse_button == "left") then
		-- play touch step sound when left click on an object
		if(result and result.block_id and result.block_id > 0) then
			click_data.last_mouse_down_block.blockX, click_data.last_mouse_down_block.blockY, click_data.last_mouse_down_block.blockZ = result.blockX,result.blockY,result.blockZ;
			local block = block_types.get(result.block_id);
			if(block and result.blockX) then
				block:OnMouseDown(result.blockX,result.blockY,result.blockZ, event.mouse_button);
			end
		end
	end
end

-- virtual: 
function PlayContext:mouseMoveEvent(event)
	PlayContext._super.mouseMoveEvent(self, event);
	if(event:isAccepted()) then
		return
	end
	local result = self:CheckMousePick();
end

function PlayContext:handleLeftClickScene(event, result)
	local mode = GameLogic.GetMode();
	local click_data = self:GetClickData();
	if( click_data.left_holding_time < 150) then
		if(result and result.obj and (not result.block_id or result.block_id == 0)) then
			-- for scene object selection, blocks has higher selection priority.  
			if( mode == "game" or mode == "survival") then
				-- for game mode, we will display a quest dialog for character object
				if(result.obj:IsCharacter()) then
					if(result.obj:GetField("GroupID", 0) == 0 ) then
						NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SelectCharacterTask.lua");
						local task = MyCompany.Aries.Game.Tasks.SelectCharacter:new({obj=result.obj})
						task:Run();	
					else
						local name = result.obj.name;
						local nid = string.match(name, "^%d+");
						if(nid) then
							if(nid ~= tostring(System.User.nid)) then
								if(System.GSL_client and System.GSL_client:FindAgent(nid)) then
									-- clicked some other player in the scene. 
									NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SelectOPCTask.lua");
									local task = MyCompany.Aries.Game.Tasks.SelectOPC:new({nid=nid})
									task:Run();
								end
							end
						end
					end
				end
			end
		else
			-- for blocks
			local is_shift_pressed = event.shift_pressed;
			local ctrl_pressed = event.ctrl_pressed;
			local alt_pressed = event.alt_pressed;

			local is_processed
			if(not is_shift_pressed and not alt_pressed and not ctrl_pressed and result and result.blockX) then
				-- if it is a left click, first try the game logics if it is processed. such as an action neuron block.
				is_processed = GameLogic.GetPlayerController():OnClickBlock(result.block_id, result.blockX, result.blockY, result.blockZ, event.mouse_button, EntityManager.GetPlayer(), result.side);
			end
			if(is_processed) then
				-- do nothing if processed
			elseif(mode == "game") then
				-- left click to move player to point
				if(not GameLogic.IsFPSView and System.options.leftClickToMove) then
					if(result and result.x) then
						System.HandleMouse.MovePlayerToPoint(result.x, result.y, result.z, true);
					end
				end
			elseif(mode == "survival") then
				-- do nothing
			end
		end
	elseif( click_data.left_holding_time > self.max_break_time) then
		if(mode == "survival") then
			-- long hold left click to delete the block
			self:TryDestroyBlock(result, true);	
		end
	end
end

-- virtual: 
function PlayContext:mouseReleaseEvent(event)
	PlayContext._super.mouseReleaseEvent(self, event);
	if(event:isAccepted()) then
		return
	end

	if(self.is_click) then
		local result = self:CheckMousePick();
		local isClickProcessed;
		
		-- escape alt key for entity event, since alt key is for picking entity. 
		if( not event.alt_pressed and result and result.obj and result.entity and (not result.block_id or result.block_id == 0)) then
			-- for entities. 
			isClickProcessed = GameLogic.GetPlayerController():OnClickEntity(result.entity, result.blockX, result.blockY, result.blockZ, event.mouse_button);
		end

		if(isClickProcessed) then	
			-- do nothing
		elseif(event.mouse_button == "left") then
			self:handleLeftClickScene(event, result)
		elseif(event.mouse_button == "right") then
			self:handleRightClickScene(event, result);
		end
	end
end

-- virtual: 
function PlayContext:mouseWheelEvent(event)
	PlayContext._super.mouseWheelEvent(self, event);
	if(event:isAccepted()) then
		return
	end
end

-- virtual: actually means key stroke. 
function PlayContext:keyPressEvent(event)
	PlayContext._super.keyPressEvent(self, event);
	if(event:isAccepted()) then
		return
	end
	if( self:handlePlayerKeyEvent(event)) then
		return;
	end

	local dik_key = event.keyname;
	if(dik_key == "DIK_B") then
		if(System.options.mc) then
			GameLogic.ToggleDesktop("bag");
		end
	elseif(dik_key == "DIK_Q") then
		GameLogic.GetPlayerController():ThrowBlockInHand();
	elseif(self:HandleQuickSelectKey(event)) then
		-- quick select key
	end
end