--[[
Title: Mobile Context
Author(s): Pbb
Date: 2022/10/31
Desc: mobile mode for paracraft. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Mobile/MobilePlayContext.lua")
local MobilePlayContext = commonlib.gettable("MyCompany.Aries.Creator.Game.Mobile.MobilePlayContext");
------------------------------------------------------------
]]
_G.MOBILE_BUTTON_STATE = {
	STATE_BATCH = 1,
	STATE_SELECT = 2,
    STATE_DELETE = 3,
	STATE_DRAW = 4,
	STATE_REPLACE = 5,
    STATE_OTHER = -1,
}
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local MobilePlayContext = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.SceneContext.PlayContext"), commonlib.gettable("MyCompany.Aries.Creator.Game.Mobile.MobilePlayContext"));

MobilePlayContext:Property("Name", "MobilePlayContext");

function MobilePlayContext:ctor()
	self.isSelectContext = false
end

-- virtual function: 
-- try to select this context. 
function MobilePlayContext:OnSelect()
	MobilePlayContext._super.OnSelect(self);
end

-- virtual function: 
-- return true if we are not in the middle of any operation and fire unselected signal. 
-- or false, if we can not unselect the scene tool context at the moment. 
function MobilePlayContext:OnUnselect()
	MobilePlayContext._super.OnUnselect(self);
	return true;
end

function MobilePlayContext:handleRightClickScene(event, result) 
	local click_data = self:GetClickData();
	local ctrl_pressed, shift_pressed, alt_pressed;
	if(event) then
		ctrl_pressed, shift_pressed, alt_pressed = event.ctrl_pressed, event.shift_pressed, event.alt_pressed
	else
		ctrl_pressed = ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LCONTROL) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_RCONTROL);
		shift_pressed = ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LSHIFT) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_RSHIFT);
		alt_pressed = ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LMENU) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_RMENU);
	end
	if(result and not shift_pressed and not ctrl_pressed and not alt_pressed) then
		local isProcessed
		if(result.entity and result.entity:IsBlockEntity() and result.entity:GetBlockId() == result.block_id) then
			-- this fixed a bug where block entity is larger than the block like the physics block model.
			local bx, by, bz = result.entity:GetBlockPos();
			isProcessed = GameLogic.GetPlayerController():OnClickBlock(result.block_id, bx, by, bz, event.mouse_button, EntityManager.GetPlayer(), result.side);
		else
			isProcessed = GameLogic.GetPlayerController():OnClickBlock(result.block_id, result.blockX, result.blockY, result.blockZ, event.mouse_button, EntityManager.GetPlayer(), result.side);
		end
		event:accept();
	end
end

function MobilePlayContext:handleLeftClickScene(event, result) 
	local click_data = self:GetClickData();
	local result = result or self:CheckMousePick();
	local ctrl_pressed, shift_pressed, alt_pressed,isOperate;
	if(event) then
		ctrl_pressed, shift_pressed, alt_pressed = event.ctrl_pressed, event.shift_pressed, event.alt_pressed
	else
		ctrl_pressed = ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LCONTROL) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_RCONTROL);
		shift_pressed = ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LSHIFT) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_RSHIFT);
		alt_pressed = ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LMENU) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_RMENU);
	end
	if(result) then
		local mode = GameLogic.GetMode();
		if(result.obj and (not result.block_id or result.block_id == 0)) then
			-- for scene object selection, blocks has higher selection priority.  
			if( mode == "game" or mode == "survival") then
				-- for game mode, we will display a quest dialog for character object
				if(result.entity) then
					-- we will not display anything if it is from an entity object. 

				elseif(result.obj:IsCharacter()) then
					if(result.obj:GetField("GroupID", 0) == 0 ) then
						NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SelectCharacterTask.lua");
						local task = MyCompany.Aries.Game.Tasks.SelectCharacter:new({obj=result.obj})
						task:Run();
						isOperate = true	
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
									isOperate = true
								end
							end
						end
					end
				end
			end
		end
		
		if(mode == "game") then
			-- left click to move player to point
			if(not GameLogic.IsFPSView and System.options.leftClickToMove) then
				if(result and result.x) then
					System.HandleMouse.MovePlayerToPoint(result.x, result.y, result.z, true);
					isOperate = true
				end
			end
		end
		if not isOperate and result and not shift_pressed and not alt_pressed and not ctrl_pressed then
			local isProcessed
			if(result.entity and result.entity:IsBlockEntity() and result.entity:GetBlockId() == result.block_id) then
				-- this fixed a bug where block entity is larger than the block like the physics block model.
				local bx, by, bz = result.entity:GetBlockPos();
				isProcessed = GameLogic.GetPlayerController():OnClickBlock(result.block_id, bx, by, bz, event.mouse_button, GameLogic.EntityManager.GetPlayer(), result.side);
			else
				isProcessed = GameLogic.GetPlayerController():OnClickBlock(result.block_id, result.blockX, result.blockY, result.blockZ, event.mouse_button, GameLogic.EntityManager.GetPlayer(), result.side);
			end
			if isProcessed then
				return 
			end
			local itemStack = GameLogic.EntityManager.GetPlayer():GetItemInRightHand();
			local block_id = 0
			if(itemStack) then
				block_id = itemStack.id
			end
			if result.blockX then
				local x,y,z = BlockEngine:GetBlockIndexBySide(result.blockX,result.blockY,result.blockZ,result.side);
				self:OnCreateSingleBlock(x,y,z, block_id, result)
			end
		end	
		event:accept();
	end
end




