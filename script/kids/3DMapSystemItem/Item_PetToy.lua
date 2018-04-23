--[[
Title: toy items for pet growing
Author(s): WangTian
Date: 2009/7/10
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemItem/Item_PetToy.lua");
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Pet/main.lua");
NPL.load("(gl)script/apps/Aries/Inventory/MainWnd.lua");
local Item_PetToy = {};
commonlib.setfield("Map3DSystem.Item.Item_PetToy", Item_PetToy)

---------------------------------
-- functions
---------------------------------

function Item_PetToy:new(o)
	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self
	return o
end

-- When item is clicked through pe:slot
-- @param silent: if true no UIs are shown
function Item_PetToy:OnClick(mouse_button)
	if(mouse_button == "left") then
		
		-- skip useitem if mount pet adopted
		if(MyCompany.Aries.Pet.IsAdopted()) then
			_guihelper.MessageBox([[<div style="margin-left:20px;margin-top:20px;">你的抱抱龙现在寄养在安吉奶奶那里，先把他领回来才能照顾他哦。</div>]]);
			return;
		end
		
		local ItemManager = System.Item.ItemManager;
		local stats = {};
		local gsItem = ItemManager.GetGlobalStoreItemInMemory(self.gsid)
		if(gsItem) then
			stats = gsItem.template.stats;
		end
		
		local pet_item = ItemManager.GetMyMountPetItem();
		if(not pet_item or pet_item.guid <= 0) then
			log("error: invalid pet item got in Item_PetToy:OnClick()\n")
			return;
		end
		local item = {
			guid = self.guid,
			bag = self.bag,
		}
		-- this is a toy 玩具
		commonlib.echo("=========begin do play toy:");
		MyCompany.Aries.Pet.DoPlayToy(nil,item,function(msg)
			MyCompany.Aries.Inventory.RefreshMainWnd(2);
			commonlib.echo("=========do play toy:");
			commonlib.echo(item);
			commonlib.echo(msg);
			if(msg.issuccess)then
				-- call hook for pet play toy
				local msg = { aries_type = "PetPlayToy", gsid = self.gsid, wndName = "main"};
				CommonCtrl.os.hook.Invoke(CommonCtrl.os.hook.HookType.WH_CALLWNDPROCRET, 0, "Aries", msg);
				MyCompany.Aries.Pet.DoRefreshPetsInHomeland();
			end
		end);	
		--local msg = {
			--nid = System.App.profiles.ProfileManager.GetNID(),
			--itemguid = self.guid,
			--petid = pet_item.guid,
			--bag = self.bag,
			----------------- for local server optimization -------------
			--gsid = self.gsid,
			--add_strong = stats[3] or 0, -- strong
			--add_cleanness = stats[4] or 0, -- cleanness
			--add_mood = stats[5] or 0, -- mood
			--add_friendliness = stats[7] or 0, -- friendliness
			--heal_pet = stats[8] or 0,
			--revive_pet = stats[9] or 0,
			----------------- for local server optimization -------------
		--}
		--paraworld.homeland.petevolved.UseItem(msg, "Item_PetToy", function(msg)	
			--if(msg.issuccess == true) then
				--local bean = msg;
				--commonlib.echo("after play with item gsid:"..tostring(self.gsid).." :");
				--commonlib.echo(bean);
				--if(bean) then
					--MyCompany.Aries.Pet.SetBean(nil, bean);
					--MyCompany.Aries.Pet.Update();
					--MyCompany.Aries.Inventory.RefreshMainWnd(2);
					--msg.issuccess = true;
					--if(callbackFunc and type(callbackFunc) == "function")then
						--callbackFunc(msg);
					--end
				--end
			--end
		--end);
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

function Item_PetToy:GetTooltip()
	local ItemManager = Map3DSystem.Item.ItemManager;
	local gsItem = ItemManager.GetGlobalStoreItemInMemory(self.gsid)
	if(gsItem) then
		local name = gsItem.template.name;
		-- stats
		--3 Add_Pet_Staminia(CS)
		--4 Add_Pet_Clean(CS)
		--5 Add_Pet_Happiness(CS)
		--7 Add_Pet_Friendliness(CS)
		--8 Heal_Pet(CS)
		--9 Revive_Pet(CS)  
		local tooltip = name;
		local heal_pet = gsItem.template.stats[8];
		if(heal_pet) then
			tooltip = tooltip.."\n治疗宠物";
		end
		local revive_pet = gsItem.template.stats[9];
		if(revive_pet) then
			tooltip = tooltip.."\n复活宠物";
		end
		local clean = gsItem.template.stats[4];
		if(clean) then
			tooltip = tooltip.."\n".."清洁值+"..clean;
		end
		local happiness = gsItem.template.stats[5];
		if(happiness) then
			tooltip = tooltip.."\n".."心情值+"..happiness;
		end
		local friendliness = gsItem.template.stats[7];
		if(friendliness) then
			tooltip = tooltip.."\n".."亲密度+"..friendliness;
		end
		local staminia = gsItem.template.stats[3];
		if(staminia) then
			if(staminia >= 0) then
				tooltip = tooltip.."\n".."饥饿值+"..staminia;
			elseif(staminia < 0) then
				tooltip = tooltip.."\n".."饥饿值"..staminia;
			end
		end
		return tooltip;
	end
end
