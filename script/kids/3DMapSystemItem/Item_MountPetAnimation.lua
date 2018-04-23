--[[
Title: mount pet animation
Author(s): WangTian
Date: 2009/7/31
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemItem/Item_MountPetAnimation.lua");
------------------------------------------------------------
]]

local Item_MountPetAnimation = {};
commonlib.setfield("Map3DSystem.Item.Item_MountPetAnimation", Item_MountPetAnimation)

---------------------------------
-- functions
---------------------------------

function Item_MountPetAnimation:new(o)
	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self
	return o
end

-- When item is clicked through pe:slot
function Item_MountPetAnimation:OnClick(mouse_button)
	if(self:IsClickable() == false) then
		return;
	end
	local ItemManager = Map3DSystem.Item.ItemManager;
	if(mouse_button == "left") then
		log("TODO: distinguish character animation and animation that played if user in mounted on pet\n")
		MyCompany.Aries.Player.PlayAnimationFromValue(nil, self.gsid);
		local x, y, z = ParaScene.GetPlayer():GetPosition();
		local anim_value = string.format("%s:%f %f %f", self.gsid, x, y, z);
		-- broadcast to all clients
		Map3DSystem.GSL_client:AddRealtimeMessage({name="anim", value=anim_value});
		
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

function Item_MountPetAnimation:GetTooltip()
	local name = "";
	local gsItem = Map3DSystem.Item.ItemManager.GetGlobalStoreItemInMemory(self.gsid);
	if(gsItem) then
		name = gsItem.template.name;
	end
	if(self:IsClickable() == false) then
		local myMount = MyCompany.Aries.Pet.GetUserMountObj();
		if(not myMount or myMount:IsValid() == false) then
			return name.."\n需要抱抱龙在身边";
		end
		-- get pet mood
		local bean = MyCompany.Aries.Pet.GetBean();
		if(bean) then
			if((bean.mood or 0) < 150) then
				return name.."\n抱抱龙心情不好";
			end
		end
	end
	local gsItem = Map3DSystem.Item.ItemManager.GetGlobalStoreItemInMemory(self.gsid);
	if(gsItem) then
		return gsItem.template.name;
	end
	return "";
end


function Item_MountPetAnimation:IsClickable()
	local myMount = MyCompany.Aries.Pet.GetUserMountObj();
	if(myMount and myMount:IsValid() == true) then
		-- get pet mood
		local bean = MyCompany.Aries.Pet.GetBean();
		if(bean) then
			if((bean.mood or 0) >= 150) then
				return true;
			end
		end
	end
	return false;
end