--[[
Title: character animation
Author(s): WangTian
Date: 2009/7/31
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemItem/Item_CharacterAnimation.lua");
------------------------------------------------------------
]]

local Item_CharacterAnimation = {};
commonlib.setfield("Map3DSystem.Item.Item_CharacterAnimation", Item_CharacterAnimation)
						
---------------------------------
-- functions
---------------------------------

function Item_CharacterAnimation:new(o)
	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self
	return o
end

-- When item is clicked through pe:slot
function Item_CharacterAnimation:OnClick(mouse_button)
	if(self:IsClickable() == false) then
		return;
	end
	local ItemManager = Map3DSystem.Item.ItemManager;
	if(mouse_button == "left") then
		if(self:IsClickable()) then
			log("TODO: distinguish character animation and animation that played if user in mounted on pet\n")
			MyCompany.Aries.Player.PlayAnimationFromValue(nil, self.gsid);
			local x, y, z = ParaScene.GetPlayer():GetPosition();
			local anim_value = string.format("%s:%f %f %f", self.gsid, x, y, z);
			-- broadcast to all clients
			Map3DSystem.GSL_client:AddRealtimeMessage({name="anim", value=anim_value});
		
			-- call hook for OnPlayCharAnim
			local hook_msg = { aries_type = "OnPlayCharAnim", gsid = self.gsid, wndName = "main"};
			CommonCtrl.os.hook.Invoke(CommonCtrl.os.hook.HookType.WH_CALLWNDPROCRET, 0, "Aries", hook_msg);
		end
		
	elseif(mouse_button == "right") then
		---- destroy the item
		--_guihelper.MessageBox("你确定要销毁 #"..tostring(self.guid).." 物品么？", function(result) 
			--if(_guihelper.DialogResult.Yes == result) then
				--Map3DSystem.Item.ItemManager.DestroyItem(self.guid, 1, function(msg)
					--if(msg) then
						--log("+++++++Destroy item return: #"..tostring(self.guid).." +++++++\n")
						--commonlib.echo(msg);
					--end
				--end);
			--elseif(_guihelper.DialogResult.No == result) then
				---- doing nothing if the user cancel the add as friend
			--end
		--end, _guihelper.MessageBoxButtons.YesNo);
	end
end

function Item_CharacterAnimation:IsClickable()
	local ItemManager = Map3DSystem.Item.ItemManager;
	local item = ItemManager.GetMyMountPetItem();
	if(item and item.guid > 0) then
		if(item:WhereAmI() == "mount") then
			return false;
		end
	end
	if(System.options.version == "kids") then
		
		local Player = MyCompany.Aries.Player;
		-- asset_gsid gsid
		local asset_gsid = Player.asset_gsid;
		if(asset_gsid == 10226) then
			return false;
		end

		-- TODO: hardcoded the solute action of police
		if(self.gsid == 9001) then
			local equipGSItem = ItemManager.IfEquipGSItem;
			if(not equipGSItem(1008) or not equipGSItem(1009) or not equipGSItem(1010) or not equipGSItem(1011)) then
				return false;
			end
		-- TODO: hardcoded the solute action of ambassidor
		elseif(self.gsid == 9004) then
			local equipGSItem = ItemManager.IfEquipGSItem;
			if(not equipGSItem(1075) or not equipGSItem(1076) or not equipGSItem(1077) or not equipGSItem(1079)) then
				return false;
			end
		end
	end
	return true;
end

function Item_CharacterAnimation:GetTooltip()
	if(System.options.version == "kids") then
		-- TODO: hardcoded the solute action of police
		if(self.gsid == 9001 and self:IsClickable() == false) then
			return "需穿戴警察制服";
		end
		-- TODO: hardcoded the solute action of police
		if(self.gsid == 9004 and self:IsClickable() == false) then
			return "需穿戴大使服";
		end
	end
	local gsItem = Map3DSystem.Item.ItemManager.GetGlobalStoreItemInMemory(self.gsid);
	if(gsItem) then
		return gsItem.template.name;
	end
	return "";
end