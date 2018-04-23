--[[
Title: 
Author(s): Leio
Date: 2013/07/05
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/mcml/pe_aries_user.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/ApparelTranslation/GemTranslationHelper.lua");
local GemTranslationHelper = commonlib.gettable("MyCompany.Aries.ApparelTranslation.GemTranslationHelper");
NPL.load("(gl)script/apps/Aries/UserBag/BagHelper.lua");
local BagHelper = commonlib.gettable("MyCompany.Aries.Inventory.BagHelper");
NPL.load("(gl)script/kids/3DMapSystemItem/ItemManager.lua");
local ItemManager = Map3DSystem.Item.ItemManager;
local hasGSItem = ItemManager.IfOwnGSItem;
local equipGSItem = ItemManager.IfEquipGSItem;

local pe_aries_user = commonlib.gettable("MyCompany.Aries.mcml_controls.pe_aries_user");
function pe_aries_user.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local nid = mcmlNode:GetAttributeWithCode("nid",nil,true);
	nid = tonumber(nid);
	nid = nid or Map3DSystem.App.profiles.ProfileManager.GetNID();
	
	--profile or bag
	local group = mcmlNode:GetString("group") or "profile";
	local defaul_value="";
	mcmlNode:SetInnerText(defaul_value);
	Map3DSystem.mcml_controls.pe_label.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout);
	local function set_ui_value(value)
		if(mcmlNode.uiobject_id)then
			local obj = ParaUI.GetUIObject(mcmlNode.uiobject_id);
			if(obj and obj.text)then
				obj.text = tostring(value);
			end
		end
	end
	--个人信息
	if(not group or group == "" or group == "profile")then
		local key = mcmlNode:GetString("key");
		System.App.profiles.ProfileManager.GetUserInfo(nid, "UpdateUserInfo", function(msg)
				local user = msg.users[1]; 
				if(msg) then
					if(key)then
						local value = user[key];
						set_ui_value(value);
					end
				end	
			end, "access plus 5 minutes");
	end
	if(group == "bag")then
		local gsid = mcmlNode:GetNumber("gsid");
		if(gsid)then
			local gsItem = ItemManager.GetGlobalStoreItemInMemory(gsid);
			if(gsItem)then
				local bag = gsItem.template.bagfamily;
				BagHelper.SearchBag(nid,{bag = bag, search_bag_all = true,},function()
					local item = GemTranslationHelper.GetUserItem(nid,gsid);
					if(item)then
						set_ui_value(item.copies or 0);
					else
						set_ui_value(0);
					end
				end,"access plus 5 minutes")
			end
		end
	end
	
	
end