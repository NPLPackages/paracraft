--[[
Title: Item Editable World Point
Author(s): LiXizhi
Date: 2025/10/10
Desc: When clicked, it will spawn an editable point entity into the world. 
      The point entity, once clicked, will open the EasyEditableWorld window.
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemEditableWorld.lua");
local ItemEditableWorld = commonlib.gettable("MyCompany.Aries.Game.Items.ItemEditableWorld");
local item_ = ItemEditableWorld:new({block_id, text, icon, tooltip, max_count, scaling, filename, name[optional, global name]});
-------------------------------------------------------
]]
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");

local ItemEditableWorld = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Items.Item"), commonlib.gettable("MyCompany.Aries.Game.Items.ItemEditableWorld"));

block_types.RegisterItemClass("ItemEditableWorld", ItemEditableWorld);

function ItemEditableWorld:ctor()
	
end

-- virtual function: use the item. 
function ItemEditableWorld:OnUse()
end

-- virtual function: when selected in right hand
function ItemEditableWorld:OnSelect()
	
end

-- virtual function: when deselected in right hand
function ItemEditableWorld:OnDeSelect()
	
end

-- virtual function:
-- @param result: picking result. {side, blockX, blockY, blockZ}
-- @return: return true if created
function ItemEditableWorld:OnCreate(result)
	if(result.blockX) then
		local bx,by,bz = result.blockX,result.blockY,result.blockZ;
        if(not EntityManager.HasNonPlayerEntityInBlock(bx,by,bz) and not GameLogic.isRemote) then 
            NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EnterTextDialog.lua");
            local EnterTextDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.EnterTextDialog");
            EnterTextDialog.ShowPage(L"请输入存档点名称，格式: [显示名称](英文标识)", function(result)
                if(result and result ~= "") then
                    local displayname, subtag = result:match("^%[(.+)%]%(([%w_]+)%)$");
                    if(not displayname or not subtag) then
                        -- 格式不匹配，默认 actionname=subtag
                        displayname = result;
                        subtag = result;
                        if not subtag:match("^%w+$") then
                            _guihelper.MessageBox(L"英文标识只能包含字母、数字和下划线");
                            return;
                        end
                    end
                    
                    local entity_class = EntityManager.GetEntityClass(self.entity_class or "LiveModel")
                    if(entity_class) then
                        local entity = entity_class:Create({bx=bx,by=by,bz=bz, name = displayname});
                        entity:SetModelFile("character/CC/05effect/fireglowingcircle.x")
                        entity:SetStaticTag("actionname", displayname)
                        entity:SetStaticTag("subtag", subtag)
                        entity:SetAnimFrame(0);
                        entity:SetCanDrag(false)
                        entity:SetOnClickEvent("API.OpenEditableWorld");
                        entity:SetTrigger(true)
                        entity:SetOnTriggerEnterEvent("API.EnterEditableWorld");
                        entity:SetOnTriggerExitEvent("API.LeaveEditableWorld");
                        entity:Attach();

                        if(GameLogic.CreateGetEditableWorld():IsWorldFrozen()) then
                            entity:SetPersistent(false)
                            GameLogic.CreateGetEditableWorld():AddLiveEntity(entity)
                        end

                        -- add to history command
                        NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/DragEntityTask.lua");
                        local task = MyCompany.Aries.Game.Tasks.DragEntity:new({addToHistory=true})
                        task:CreateEntity(entity);
                        return true;
                    end
                end
            end)
        end
	end
end
