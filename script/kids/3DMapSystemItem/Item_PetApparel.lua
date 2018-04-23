--[[
Title: apparel items for pet customization
Author(s): WangTian
Date: 2009/7/10
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemItem/Item_PetApparel.lua");
------------------------------------------------------------
]]

local Item_PetApparel = {};
commonlib.setfield("Map3DSystem.Item.Item_PetApparel", Item_PetApparel)

---------------------------------
-- functions
---------------------------------

function Item_PetApparel:new(o)
	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self
	return o
end

-- When item is clicked through pe:slot
function Item_PetApparel:OnClick(mouse_button)
	if(mouse_button == "left") then
		-- mount or use the item
		if(self.bag == 0 and self.position) then
			Map3DSystem.Item.ItemManager.UnEquipItem(self.position, function(msg) 
				-- refresh the avatar, mount pet and follow pet
				Map3DSystem.Item.ItemManager.RefreshMyself();
				-- refresh all <pe:player>
				Map3DSystem.mcml_controls.GetClassByTagName("pe:player").RefreshContainingPageCtrls();
				
			end);
		else
			Map3DSystem.Item.ItemManager.EquipItem(self.guid, function(msg) 
				-- refresh the avatar, mount pet and follow pet
				Map3DSystem.Item.ItemManager.RefreshMyself();
				-- refresh all <pe:player>
				Map3DSystem.mcml_controls.GetClassByTagName("pe:player").RefreshContainingPageCtrls();
				
			end);
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

function Item_PetApparel:Prepare(mouse_button)
end



			--CS_HEAD =0,
			--CS_NECK = 1,
			--CS_SHOULDER = 2,
			--CS_BOOTS = 3,
			--CS_BELT = 4,
			--CS_SHIRT = 5,
			--CS_PANTS = 6,
			--CS_CHEST = 7,
			--CS_BRACERS = 8,
			--CS_GLOVES = 9,
			--CS_HAND_RIGHT = 10,
			--CS_HAND_LEFT = 11,
			--CS_CAPE = 12,
			--CS_TABARD = 13,
			--CS_FACE_ADDON = 14, // newly added by andy -- 2009.5.10, Item type: IT_MASK 26
			--CS_WINGS = 15, // newly added by andy -- 2009.5.11, Item type: IT_WINGS 27
			--CS_ARIES_CHAR_SHIRT = 16, // newly added by andy -- 2009.6.16, Item type: IT_WINGS 28
			--CS_ARIES_CHAR_PANT = 17,
			--CS_ARIES_CHAR_HAND = 18,
			--CS_ARIES_CHAR_FOOT = 19,
			--CS_ARIES_CHAR_GLASS = 20,
			--CS_ARIES_CHAR_WING = 21,
			--CS_ARIES_PET_HEAD = 22,
			--CS_ARIES_PET_BODY = 23,
			--CS_ARIES_PET_TAIL = 24,
			--CS_ARIES_PET_WING = 25,
			
			
			
			
	--enum ItemTypes {
		--IT_ALL = 0,
		--IT_HEAD = 1,
		--IT_NECK,
		--IT_SHOULDER,
		--IT_SHIRT,
		--IT_CHEST,
		--IT_BELT,
		--IT_PANTS,
		--IT_BOOTS,
		--IT_BRACERS,
		--IT_GLOVES,
		--IT_RINGS,
		--IT_OFFHAND,
		--IT_DAGGER,
		--IT_SHIELD,
		--IT_BOW,
		--IT_CAPE,
		--IT_2HANDED,
		--IT_QUIVER,
		--IT_TABARD,
		--IT_ROBE,
		--IT_1HANDED,
		--IT_CLAW,
		--IT_ACCESSORY,
		--IT_THROWN,
		--IT_GUN,
		--IT_MASK, // CS_FACE_ADDON
		--IT_WINGS, // CS_WINGS
--
		--IT_ARIES_CHAR_SHIRT,
		--IT_ARIES_CHAR_PANT,
		--IT_ARIES_CHAR_HAND,
		--IT_ARIES_CHAR_FOOT,
		--IT_ARIES_CHAR_GLASS,
		--IT_ARIES_CHAR_WING,
		--IT_ARIES_PET_HEAD,
		--IT_ARIES_PET_BODY,
		--IT_ARIES_PET_TAIL,
		--IT_ARIES_PET_WING,
--
		--NUM_ITEM_TYPES
	--};