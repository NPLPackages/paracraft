--[[
Title: quest rewards
Author(s): WangTian
Date: 2009/9/21
Desc: Item_QuestReward type of item is a special item type that can be used for rewards
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemItem/Item_QuestReward.lua");
------------------------------------------------------------
]]

local Item_QuestReward = {};
commonlib.setfield("Map3DSystem.Item.Item_QuestReward", Item_QuestReward)

---------------------------------
-- functions
---------------------------------

function Item_QuestReward:new(o)
	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self
	return o
end

-- When item is clicked through pe:slot
function Item_QuestReward:OnClick(mouse_button, callbackFunc)
	local ItemManager = Map3DSystem.Item.ItemManager;
	if(mouse_button == "left") then
		
		--MyCompany.Aries.Pet.DoFeed(nid,item,function(msg)
			----MyCompany.Aries.Inventory.ShowMainWnd(false);
			--MyCompany.Aries.Inventory.RefreshMainWnd(2);
			--if(msg.issuccess)then
				--self:UpdateBag(bagfamily,bag)
				------ call hook for pet feed
				----local msg = { aries_type = "PetFeed", gsid = self.gsid, wndName = "main"};
				----CommonCtrl.os.hook.Invoke(CommonCtrl.os.hook.HookType.WH_CALLWNDPROCRET, 0, "Aries", msg);
				--MyCompany.Aries.Pet.DoRefreshPetsInHomeland();
			--end
		--end);
		
		local ItemManager = System.Item.ItemManager;
		local stats = {};
		local gsItem = ItemManager.GetGlobalStoreItemInMemory(self.gsid)
		if(gsItem) then
			stats = gsItem.template.stats;
		end
		
		local pet_item = ItemManager.GetMyMountPetItem();
		if(not pet_item or pet_item.guid <= 0) then
			log("error: invalid pet item got in Item_QuestReward:OnClick()\n")
			return;
		end
		
		local msg = {
			nid = System.App.profiles.ProfileManager.GetNID(),
			itemguid = self.guid,
			petid = pet_item.guid,
			bag = self.bag,
			--------------- for local server optimization -------------
			gsid = self.gsid,
			add_strong = stats[3] or 0, -- strong
			add_cleanness = stats[4] or 0, -- cleanness
			add_mood = stats[5] or 0, -- mood
			add_friendliness = stats[7] or 0, -- friendliness
			heal_pet = stats[8] or 0,
			revive_pet = stats[9] or 0,
			add_kindness = stats[17] or 0, -- kindness
			add_intelligence = stats[18] or 0, -- intelligence
			add_agility = stats[19] or 0, -- agility
			add_strength = stats[20] or 0, -- strength
			add_archskillpts = stats[21] or 0, -- archskillpts
			--------------- for local server optimization -------------
		}
		paraworld.homeland.petevolved.UseItem(msg, "QuestReward", function(msg)	
			if(msg.issuccess == true) then
				-- update the item bag
				if(gsItem) then
					-- automatically update the items in the homeland bag
					ItemManager.GetItemsInBag(gsItem.template.bagfamily, "UpdateHomeBagAfterGetQuestReward_", function(msg)
						-- update all page controls containing the pe:slot tag
						-- TODO: update only the PageCtrl with the same bag
						Map3DSystem.mcml_controls.GetClassByTagName("pe:slot").RefreshContainingPageCtrls();
					end, "access plus 3 minutes");
				end
				if(callbackFunc and type(callbackFunc) == "function")then
					callbackFunc(msg);
				end

				--local bean = msg;
				--commonlib.echo("after reward with item gsid:"..tostring(self.gsid).." :");
				--commonlib.echo(bean);
				--if(bean) then
					--MyCompany.Aries.Pet.SetBean(nil, bean);
					--MyCompany.Aries.Pet.Update();
					--
					---- Product BUG:
					---- 1. don't open any inventory window
					---- 2. complete quest with friendliness reward
					---- [string "script/kids/3DMapSystemItem/Item_QuestReward.lua"]:79: attempt to call field 'RefreshMainWnd' (a nil value) <Runtime error>
					---- this don't bothers user experience though, the window will be refreshed on the next show
					--MyCompany.Aries.Inventory.RefreshMainWnd(2);
					--msg.issuccess = true;
					--if(callbackFunc and type(callbackFunc) == "function")then
						--callbackFunc(msg);
					--end
				--end
			end
		end);
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