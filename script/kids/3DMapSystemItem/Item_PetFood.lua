--[[
Title: food items for pet growing
Author(s): WangTian
Date: 2009/7/10
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemItem/Item_PetFood.lua");
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Pet/main.lua");
NPL.load("(gl)script/apps/Aries/Inventory/MainWnd.lua");
local Item_PetFood = commonlib.gettable("Map3DSystem.Item.Item_PetFood")

---------------------------------
-- functions
---------------------------------

function Item_PetFood:new(o)
	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self
	return o
end

-- When item is clicked through pe:slot
-- @param silent: if true no UIs are shown
function Item_PetFood:OnClick(mouse_button)
	if(mouse_button == "left") then
		
		-- skip useitem if mount pet adopted
		if(MyCompany.Aries.Pet.IsAdopted()) then
			_guihelper.MessageBox([[<div style="margin-left:20px;margin-top:20px;">你的抱抱龙现在寄养在安吉奶奶那里，先把他领回来才能照顾他哦。</div>]]);
			return;
		end
		
		local nid = Map3DSystem.User.nid;
		local ItemManager = Map3DSystem.Item.ItemManager;
		local gsItem = ItemManager.GetGlobalStoreItemInMemory(self.gsid)
		if(gsItem) then
			--commonlib.echo("喂食的gsItem");
			--commonlib.echo(gsItem);
			local class = tonumber(gsItem.template.class);
			local subclass = tonumber(gsItem.template.subclass);
			local item = {
					guid = self.guid,
					bag = self.bag,
				}
			local bagfamily = gsItem.template.bagfamily;
			local bag = self.bag;
			if(class == 2 and subclass == 1) then
				-- this is a food 吃
				commonlib.echo("=========begin do feed:");
				MyCompany.Aries.Pet.DoFeed(nid,item,function(msg)
					--MyCompany.Aries.Inventory.ShowMainWnd(false);
					MyCompany.Aries.Inventory.RefreshMainWnd(2);
					commonlib.echo("=========do feed:");
					commonlib.echo(item);
					commonlib.echo(msg);
					if(msg.issuccess)then
						self:UpdateBag(bagfamily,bag)
						-- call hook for pet feed
						local msg = { aries_type = "PetFeed", gsid = self.gsid, wndName = "main"};
						CommonCtrl.os.hook.Invoke(CommonCtrl.os.hook.HookType.WH_CALLWNDPROCRET, 0, "Aries", msg);
						MyCompany.Aries.Quest.MoodPerDay.SendFeedMsg(self.gsid,"onPetFeed_MPD");
						MyCompany.Aries.Pet.DoRefreshPetsInHomeland();
					else
						self:ShowError(msg.error);
					end
				end);
			elseif(class == 2 and subclass == 2) then
				-- this is a body lotion 洗澡
				commonlib.echo("=========begin do bath:");
				MyCompany.Aries.Pet.DoBath(nid,item,function(msg)
					--MyCompany.Aries.Inventory.ShowMainWnd(false);
					MyCompany.Aries.Inventory.RefreshMainWnd(2);
					commonlib.echo("=========do bath:");
					commonlib.echo(item);
					commonlib.echo(msg);
					if(msg.issuccess)then
						self:UpdateBag(bagfamily,bag)
						-- call hook for pet bath
						local msg = { aries_type = "PetBath", gsid = self.gsid, wndName = "main"};
						CommonCtrl.os.hook.Invoke(CommonCtrl.os.hook.HookType.WH_CALLWNDPROCRET, 0, "Aries", msg);
						MyCompany.Aries.Quest.MoodPerDay.SendFeedMsg(self.gsid,"onPetBath_MPD");
						MyCompany.Aries.Pet.DoRefreshPetsInHomeland();
					else
						self:ShowError(msg.error);
					end
				end);
			elseif(class == 2 and subclass == 3) then
				-- this is a toy 玩具
				commonlib.echo("=========begin do play toy:");
				MyCompany.Aries.Pet.DoPlayToy(nid,item,function(msg)
					--MyCompany.Aries.Inventory.ShowMainWnd(false);
					MyCompany.Aries.Inventory.RefreshMainWnd(2);
					commonlib.echo("=========do play toy:");
					commonlib.echo(item);
					commonlib.echo(msg);
					if(msg.issuccess)then
						self:UpdateBag(bagfamily,bag);
						-- call hook for pet play toy
						local msg = { aries_type = "PetPlayToy", gsid = self.gsid, wndName = "main"};
						CommonCtrl.os.hook.Invoke(CommonCtrl.os.hook.HookType.WH_CALLWNDPROCRET, 0, "Aries", msg);
						MyCompany.Aries.Pet.DoRefreshPetsInHomeland();
					else
						self:ShowError(msg.error);
					end
				end);
			elseif(class == 2 and subclass == 4) then
				-- this is a medichine 药 或者复活
				if(gsItem.template.stat_type_1 == 8)then
					commonlib.echo("=========begin do medicine:");
					MyCompany.Aries.Pet.DoMedicine(nid,item,function(msg)
						--MyCompany.Aries.Inventory.ShowMainWnd(false);
						MyCompany.Aries.Inventory.RefreshMainWnd(2);
						commonlib.echo("=========do medicine:");
						commonlib.echo(item);
						commonlib.echo(msg);
						if(msg.issuccess)then
							self:UpdateBag(bagfamily,bag);
							-- call hook for pet medicine
							local msg = { aries_type = "PetMedicine", gsid = self.gsid, wndName = "main"};
							CommonCtrl.os.hook.Invoke(CommonCtrl.os.hook.HookType.WH_CALLWNDPROCRET, 0, "Aries", msg);
							MyCompany.Aries.Pet.DoRefreshPetsInHomeland();
						else
							self:ShowError(msg.error);
						end
					end);
				elseif(gsItem.template.stat_type_1 == 9)then
					commonlib.echo("=========begin do relive:");
					MyCompany.Aries.Pet.DoRelive(nid,item,function(msg)
						--MyCompany.Aries.Inventory.ShowMainWnd(false);
						MyCompany.Aries.Inventory.RefreshMainWnd(2);
						commonlib.echo("=========do relive:");
						commonlib.echo(item);
						commonlib.echo(msg);
						if(msg.issuccess)then
							self:UpdateBag(bagfamily,bag)
							-- call hook for pet revive
							local msg = { aries_type = "PetRevive", gsid = self.gsid, wndName = "main"};
							CommonCtrl.os.hook.Invoke(CommonCtrl.os.hook.HookType.WH_CALLWNDPROCRET, 0, "Aries", msg);
							-- auto follow the user for newly revived dragon
							local item = ItemManager.GetMyMountPetItem();
							if(item and item.guid > 0) then
								-- make the mount pet follow the user
								item:FollowMe(function(msg)
									-- refresh the status for dragon wish
									if(commonlib.getfield("MyCompany.Aries.Quest.NPCs.DragonWish.RefreshStatus")) then
										MyCompany.Aries.Quest.NPCs.DragonWish.RefreshStatus();
									end
									-- create effect of newly born pet
									local _pet = MyCompany.Aries.Pet.GetUserMountObj();
									if(_pet and _pet:IsValid() == true) then
										local params = {
											asset_file = "character/v5/temp/Effect/DampenMagic_Impact_Base.x",
											binding_obj_name = _pet.name,
											duration_time = 2000,
											end_callback = function()
											end
										};
										local EffectManager = MyCompany.Aries.EffectManager;
										EffectManager.CreateEffect(params);
									end
								end);
							end
							---- the clientdata is set immediately so refresh homeland pets
							--MyCompany.Aries.Pet.DoRefreshPetsInHomeland();
						else
							self:ShowError(msg.error);
						end
					end);
				end
				
			end
		else
			log("error: invalid use of item for pet food guid:"..self.guid.."\n");
			return;
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

function Item_PetFood:GetTooltip()
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
		local strength = gsItem.template.stats[20];
		if(strength) then
			tooltip = tooltip.."\n".."力量值+"..strength;
		end
		local agility = gsItem.template.stats[19];
		if(agility) then
			tooltip = tooltip.."\n".."敏捷值+"..agility;
		end
		local intelligence = gsItem.template.stats[18];
		if(intelligence) then
			tooltip = tooltip.."\n".."智慧值+"..intelligence;
		end
		local kindness = gsItem.template.stats[17];
		if(kindness) then
			tooltip = tooltip.."\n".."爱心值+"..kindness;
		end
		local arch_pts = gsItem.template.stats[21];
		if(arch_pts) then
			tooltip = tooltip.."\n".."建造熟练度+"..arch_pts;
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

function Item_PetFood:ShowError(error)
	local info = Map3DSystem.App.HomeLand.HomeLandError[error];
	if(info)then
			info = info.error;
	end
	commonlib.echo({error,info});
	--Map3DSystem.App.HomeLand.HomeLandError.ShowInfo(info);
end
function Item_PetFood:UpdateBag(bagfamily, bag)
	-- we don't need to update the bag aggressively with "access plus 0 day"
	-- item system has destoryed the used item silently in local server
	if(bagfamily) then
		Map3DSystem.Item.ItemManager.GetItemsInBag(bagfamily, "", function(msg3)
			Map3DSystem.mcml_controls.GetClassByTagName("pe:slot").RefreshContainingPageCtrls();
		end, "access plus 3 minute");
	end
	if(bag and bag ~= bagfamily) then
		Map3DSystem.Item.ItemManager.GetItemsInBag(bag, "", function(msg)
			Map3DSystem.mcml_controls.GetClassByTagName("pe:slot").RefreshContainingPageCtrls();
		end, "access plus 3 minute");
	end
end
function Item_PetFood:Prepare(mouse_button)
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