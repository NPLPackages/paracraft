--[[
Title: transform item marker
Author(s): WangTian
Date: 2011/11/24
Desc: Item_PetTransformMarker
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemItem/Item_PetTransformMarker.lua");
------------------------------------------------------------
]]

local Item_PetTransformMarker = {};
commonlib.setfield("Map3DSystem.Item.Item_PetTransformMarker", Item_PetTransformMarker)

local VIP = commonlib.gettable("MyCompany.Aries.VIP");
local Scene = commonlib.gettable("MyCompany.Aries.Scene");

---------------------------------
-- functions
---------------------------------

function Item_PetTransformMarker:new(o)
	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self
	return o
end

-- When item is clicked through pe:slot
function Item_PetTransformMarker:OnClick(mouse_button, callback_func)
	if(self.nid and self.nid ~= ProfileManager.GetNID()) then
		LOG.std(nil, "error", "Item_Apparel", "can't equip other user's items");
		return;
	end
	if(mouse_button == "left") then
		-- mount or use the item
		if(self.bag == 0 and self.position) then
			Map3DSystem.Item.ItemManager.UnEquipItem(self.position, function(msg) 
				-- check transform
				MyCompany.Aries.Player.CheckTransform()
				-- refresh the avatar, mount pet and follow pet
				Map3DSystem.Item.ItemManager.RefreshMyself();
				-- refresh all <pe:player>
				Map3DSystem.mcml_controls.GetClassByTagName("pe:player").RefreshContainingPageCtrls();
				
				-- call hook for OnEquipItem
				local hook_msg = { aries_type = "OnUnEquipItem", wndName = "main"};
				CommonCtrl.os.hook.Invoke(CommonCtrl.os.hook.HookType.WH_CALLWNDPROCRET, 0, "Aries", hook_msg);

				if(callback_func) then
					callback_func();
				end
				
				if(System.options.version == "kids") then
					-- refresh mount tab
					if(MyCompany.Aries.Inventory.TabMountExPage) then
						MyCompany.Aries.Inventory.TabMountExPage.ShowItemView1("1");
					end
				elseif(System.options.version == "teen") then
					NPL.load("(gl)script/apps/Aries/Inventory/PetPage.lua");
					local PetPage = commonlib.gettable("MyCompany.Aries.Inventory.PetPage");
					PetPage.RefreshPage();
				end
			end);
		else
			local pill_gsid = Map3DSystem.Item.ItemManager.GetTransformPill_from_Marker(self.gsid);
			if(pill_gsid) then
				local gsItem = Map3DSystem.Item.ItemManager.GetGlobalStoreItemInMemory(pill_gsid);
				if(gsItem) then
					if(System.options.version == "kids") then
						-- added 16079_SmallEagle VIP limit
						if(pill_gsid == 16079 and VIP.GetMagicStarLevel() < 3) then
							_guihelper.MessageBox(string.format([[<div style="margin-left:15px;margin-top:20px;">%s需要3级魔法星能量才能驾驭哦</div>]], gsItem.template.name));
							return;
						end
						-- added 16081_SmallEagle_Black VIP limit
						if(pill_gsid == 16081 and VIP.GetMagicStarLevel() < 3) then
							_guihelper.MessageBox(string.format([[<div style="margin-left:15px;margin-top:20px;">%s需要3级魔法星能量才能驾驭哦</div>]], gsItem.template.name));
							return;
						end

						-- added 16083_MechanicalMount VIP limit
						if(pill_gsid == 16083 and VIP.GetMagicStarLevel() < 1) then
							_guihelper.MessageBox(string.format([[<div style="margin-left:15px;margin-top:20px;">%s需要1级魔法星能量才能驾驭哦</div>]], gsItem.template.name));
							return;
						end
					end
				end
			end

			local function OnMountProcess()
				Map3DSystem.Item.ItemManager.EquipItem(self.guid, function(msg) 
					-- check transform
					MyCompany.Aries.Player.CheckTransform()
					-- refresh the avatar, mount pet and follow pet
					Map3DSystem.Item.ItemManager.RefreshMyself();
					-- refresh all <pe:player>
					Map3DSystem.mcml_controls.GetClassByTagName("pe:player").RefreshContainingPageCtrls();
				
					-- call hook for OnEquipItem
					local hook_msg = { aries_type = "OnEquipItem", wndName = "main"};
					CommonCtrl.os.hook.Invoke(CommonCtrl.os.hook.HookType.WH_CALLWNDPROCRET, 0, "Aries", hook_msg);

					-- play mount pet mount spell
					NPL.load("(gl)script/apps/Aries/Combat/SpellCast.lua");
					local SpellCast = commonlib.gettable("MyCompany.Aries.Combat.SpellCast");
					local spell_file;
					if(System.options.version == "teen")then
						spell_file = "config/Aries/Spells/Action_OnMount_teen.xml";
					else
						spell_file = "config/Aries/Spells/Action_OnMount.xml";
					end
					local current_playing_id = ParaGlobal.GenerateUniqueID();
					SpellCast.EntitySpellCast(0, ParaScene.GetPlayer(), 1, ParaScene.GetPlayer(), 1, spell_file, nil, nil, nil, nil, nil, function()
					end, nil, true, current_playing_id, true);

					if(callback_func) then
						callback_func();
					end
				
					if(System.options.version == "kids") then
						-- refresh mount tab
						MyCompany.Aries.Inventory.TabMountExPage.ShowItemView1("1");
					elseif(System.options.version == "teen") then
						NPL.load("(gl)script/apps/Aries/Inventory/PetPage.lua");
						local PetPage = commonlib.gettable("MyCompany.Aries.Inventory.PetPage");
						PetPage.RefreshPage();
					end
				end);
			end
			NPL.load("(gl)script/apps/Aries/ServerObjects/Gatherer/GathererBarPage.lua");
			local GathererBarPage = commonlib.gettable("MyCompany.Aries.ServerObjects.GathererBarPage");
			GathererBarPage.Start({duration = 1000,}, nil, function()
				OnMountProcess();
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

function Item_PetTransformMarker:GetTooltip()
	local ItemManager = Map3DSystem.Item.ItemManager;
	local gsItem = ItemManager.GetGlobalStoreItemInMemory(self.gsid)
	local tooltip = "";
	if(gsItem) then
		local pill_gsid = ItemManager.GetTransformPill_from_Marker(self.gsid);
		if(pill_gsid) then
			return "page://script/apps/Aries/Desktop/ApparelTooltip.html?gsid="..pill_gsid;
		else
			local name = gsItem.template.name;
			tooltip = "名称："..name.."\n";
		end
		return tooltip;
	end
end