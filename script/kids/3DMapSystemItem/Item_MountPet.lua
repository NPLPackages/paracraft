--[[
Title: mount pet 
Author(s): WangTian
Date: 2009/6/17
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemItem/Item_MountPet.lua");
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Pet/main.lua");
NPL.load("(gl)script/kids/3DMapSystemUI/HomeLand/HomeLandError.lua");
NPL.load("(gl)script/ide/Storyboard/Storyboard.lua");
NPL.load("(gl)script/ide/Storyboard/TimeSpan.lua");
NPL.load("(gl)script/kids/3DMapSystemUI/HomeLand/PetState.lua");
local Item_MountPet = commonlib.gettable("Map3DSystem.Item.Item_MountPet")

---------------------------------
-- functions
---------------------------------

function Item_MountPet:new(o)
	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self
	return o
end

-- When item is clicked through pe:slot
function Item_MountPet:OnClick(mouse_button)
	if(mouse_button == "left") then
		---- mount or use the item
		--if(self.bag == 0 and self.position) then
			--self:GoHome();
		--else
			--self:MountMe();
		--end
		
	elseif(mouse_button == "right") then
		---- destroy the item
		--_guihelper.MessageBox("你确定要销毁 #"..tostring(self.guid).." 物品么？", function(result) 
			--if(_guihelper.DialogResult.Yes == result) then
				--Map3DSystem.Item.ItemManager.DestroyItem(self.guid, 1, function(msg)
					--if(msg) then
						--log("+++++++Destroy item return: #"..tostring(self.guid).." +++++++\n")
						--commonlib.echo(msg);
						--NPL.load("(gl)script/apps/Aries/Pet/main.lua");
						--MyCompany.Aries.Pet.RemovePet();
					--end
				--end);
			--elseif(_guihelper.DialogResult.No == result) then
				---- doing nothing if the user cancel the add as friend
			--end
		--end, _guihelper.MessageBoxButtons.YesNo);
	end
end

function Item_MountPet:Prepare(mouse_button)
end

-- mount the mount pet to user
function Item_MountPet:MountMe()
	if(MyCompany.Aries.Player.IsFlying()) then
		return;
	end
	if(MyCompany.Aries.Player.IsInAir()) then
		return;
	end
	local result, error = self:CanMount();
	if(not result) then
		local info = Map3DSystem.App.HomeLand.HomeLandError[error];
		if(info) then
			info = info.error;
		end
		Map3DSystem.App.HomeLand.HomeLandError.ShowInfo(info);
		return
	end
	
	-- NOTE: dragon state is now binding to the clientdata of the dragon item structure
	--		1. one don't need to transfer dragon item between bag 0 and bag 10010
	--		2. mount follow and home state is now set directly in clientdata
	--		3. clientdata setting is immediately valid, the remote calls won't effect the data in memory, once failed setting the data
	--			it will automatically set again according to the current clientdata in memory
	--		4. the worst case is the data is never successfully set but it will never affect the user's belongings, the dragon itself
	
	-- NOTE: currently the dragon item will be only valid in bag 0
	if(self.bag == 0) then
		Map3DSystem.Item.ItemManager.SetClientData(self.guid, "mount", function(msg)
			if(msg.issuccess == false) then
				log("error: failed modify clientdata of mount pet\n")
			end
		end, 0); -- force bag 0
		-- NOTE: clientdata is immediately set with "mount" after ItemManager.SetClientData
		-- refresh the avatar, mount pet and follow pet
		Map3DSystem.Item.ItemManager.RefreshMyself();
		---- refresh all <pe:player>
		--Map3DSystem.mcml_controls.GetClassByTagName("pe:player").RefreshContainingPageCtrls();
		MyCompany.Aries.Pet.DoRide();

		MyCompany.Aries.Player.RefreshDensity();
	end
	
	--if(self.bag == 0 and self.position) then
		--self.clientdata = "mount";
		--local msg = {
			--guid = self.guid,
			--bag = 0, 
			--clientdata = "mount",
		--};
		--paraworld.inventory.SetClientData(msg, "MountMePositionSetClientdata_"..self.guid, function(msg)
			--if(msg.issuccess == false) then
				--log("error: failed modify position of mount pet\n")
			--end
		--end);
		---- refresh the avatar, mount pet and follow pet
		--Map3DSystem.Item.ItemManager.RefreshMyself();
		--MyCompany.Aries.Pet.DoRide();
	--else
		--Map3DSystem.Item.ItemManager.EquipItem(self.guid, function(msg) 
			--if(msg.issuccess == true) then
				--local item = Map3DSystem.Item.ItemManager.GetItemByGUID(self.guid);
				--if(item and item.guid > 0) then
					--item.clientdata = "mount";
					--local msg = {
						--guid = self.guid,
						--bag = self.bag, -- it must be 10010
						--clientdata = "mount",
					--};
					--paraworld.inventory.SetClientData(msg, "MountMePositionSetClientdata_"..self.guid, function(msg)
						--if(msg.issuccess == false) then
							--log("error: failed modify position of mount pet\n")
						--end
					--end);
				--end
				---- refresh the avatar, mount pet and follow pet
				--Map3DSystem.Item.ItemManager.RefreshMyself();
				---- refresh all <pe:player>
				--Map3DSystem.mcml_controls.GetClassByTagName("pe:player").RefreshContainingPageCtrls();
				--MyCompany.Aries.Pet.DoRide();
			--end
		--end);
	--end
end

-- follow the mount pet to user
-- @param (optional)callbackFunc: the callback function(msg) end
-- @param (optional)bForceFollow: this tag is used in AuntAngel to allow adopted dragon to follow the user even with clientdata "follow"
function Item_MountPet:FollowMe(callbackFunc, bForceFollow)
	if(MyCompany.Aries.Player.IsFlying()) then
		return;
	end
	if(MyCompany.Aries.Player.IsInAir()) then
		return;
	end
	if(not bForceFollow) then
		local result, error = self:CanFollow();
		if(not result) then
			local info = Map3DSystem.App.HomeLand.HomeLandError[error];
			if(info) then
				info = info.error;
			end
			Map3DSystem.App.HomeLand.HomeLandError.ShowInfo(info);
			return
		end
	end
	
	-- NOTE: currently the dragon item will be only valid in bag 0
	if(self.bag == 0 and self.position) then
		Map3DSystem.Item.ItemManager.SetClientData(self.guid, "follow", function(msg)
			if(msg.issuccess == false) then
				log("error: failed modify position of mount pet\n")
			end
		end, 0); -- force bag 0
		if(Map3DSystem.App.HomeLand.HomeLandGateway.IsInMyHomeland()) then
				-- refresh the pets in homeland
				MyCompany.Aries.Pet.RefreshMyPetsFromMemoryInHomeland();
		end
		-- NOTE: clientdata is immediately set with "follow" after ItemManager.SetClientData
		-- refresh the avatar, mount pet and follow pet
		Map3DSystem.Item.ItemManager.RefreshMyself();
		---- refresh all <pe:player>
		--Map3DSystem.mcml_controls.GetClassByTagName("pe:player").RefreshContainingPageCtrls();
		MyCompany.Aries.Pet.DoFollow();
		MyCompany.Aries.Player.RefreshDensity();

		-- invoke the callback if needed
		if(type(callbackFunc) == "function") then
			callbackFunc(msg);
		end
	end
	
	--if(self.bag == 0 and self.position) then
		--self.clientdata = "follow";
		--local msg = {
			--guid = self.guid,
			--bag = 0, 
			--clientdata = "follow",
		--};
		--paraworld.inventory.SetClientData(msg, "FollowMePositionSetClientdata_"..self.guid, function(msg)
			--if(msg.issuccess == false) then
				--log("error: failed modify position of mount pet\n")
			--end
		--end);
		---- refresh the avatar, mount pet and follow pet
		--Map3DSystem.Item.ItemManager.RefreshMyself();
		--MyCompany.Aries.Pet.DoFollow();
	--else
		--Map3DSystem.Item.ItemManager.EquipItem(self.guid, function(msg) 
			--if(msg.issuccess == true) then
				---- TODO: blablabla
				--local item = Map3DSystem.Item.ItemManager.GetItemByGUID(self.guid);
				--if(item and item.guid > 0) then
					--item.clientdata = "follow";
					--local msg = {
						--guid = self.guid,
						--bag = self.bag, -- it must be 10010
						--clientdata = "follow",
					--};
					--paraworld.inventory.SetClientData(msg, "FollowMePositionSetClientdata_"..self.guid, function(msg)
						--
						--if(msg.issuccess == false) then
							--log("error: failed modify position of mount pet\n")
						--end
					--end);
				--end
				--
				---- refresh the avatar, mount pet and follow pet
				--Map3DSystem.Item.ItemManager.RefreshMyself();
				---- refresh all <pe:player>
				--Map3DSystem.mcml_controls.GetClassByTagName("pe:player").RefreshContainingPageCtrls();
				--MyCompany.Aries.Pet.DoFollow();
				--
				--if(type(callbackFunc) == "function") then
					--callbackFunc(msg);
				--end
			--end
		--end);
	--end
end

-- send the mount pet to homeland
-- @param immediate: true for immediate GoHome, used in walking through teleport portal
function Item_MountPet:GoHome(internalGo, callbackFunc, immediate)
	if(MyCompany.Aries.Player.IsFlying()) then
		return;
	end
	if(MyCompany.Aries.Player.IsInAir()) then
		return;
	end
	local result,error = self:CanGoHome();
	if(not result)then
		local info = Map3DSystem.App.HomeLand.HomeLandError[error];
		if(info)then
			info = info.error;
		end
		if(not internalGo)then
			Map3DSystem.App.HomeLand.HomeLandError.ShowInfo(info);
			-- NOTE: leio confirm the internalGo will continue the following set clientdata process 2009/9/1
			return;
		end
	end
	
	-- NOTE: currently the dragon item will be only valid in bag 0
	if(self.bag == 0 and self.position) then
		Map3DSystem.Item.ItemManager.SetClientData(self.guid, "home", function(msg)
			if(msg.issuccess == false) then
				log("error: failed modify position of mount pet\n")
			end
		end, 0); -- force bag 0
		-- NOTE: clientdata is immediately set with "home" after ItemManager.SetClientData
		
		MyCompany.Aries.Pet.DoGoHome();
		MyCompany.Aries.Player.RefreshDensity();

		if(Map3DSystem.App.HomeLand.HomeLandGateway.IsInMyHomeland()) then
			-- refresh the pets in homeland
			MyCompany.Aries.Pet.RefreshMyPetsFromMemoryInHomeland();
			-- refresh the avatar, mount pet and follow pet
			Map3DSystem.Item.ItemManager.RefreshMyself();
		end
		
		if(callbackFunc and type(callbackFunc) == "function") then
			callbackFunc();
		end
		
		if(immediate == true) then
			-- refresh the avatar, mount pet and follow pet
			Map3DSystem.Item.ItemManager.RefreshMyself();
		else
			local const_waitDuration = Map3DSystem.App.HomeLand.PetState.const_waitDuration or "00:00:01";
			local frame = CommonCtrl.Storyboard.TimeSpan.GetFrames(const_waitDuration);
			local storyboard = CommonCtrl.Storyboard.Storyboard:new();
			storyboard:SetDuration(frame);
			storyboard.OnEnd = function(s)
				if(Map3DSystem.App.HomeLand.HomeLandGateway.IsInMyHomeland()) then
					-- refresh the pets in homeland
					MyCompany.Aries.Pet.RefreshMyPetsFromMemoryInHomeland();
				end
				-- refresh the avatar, mount pet and follow pet
				Map3DSystem.Item.ItemManager.RefreshMyself();
				---- refresh all <pe:player>
				--Map3DSystem.mcml_controls.GetClassByTagName("pe:player").RefreshContainingPageCtrls();
			end
			storyboard:Play();
		end
	end
	
	--
	--MyCompany.Aries.Pet.DoGoHome();
	--
	--local const_waitDuration = Map3DSystem.App.HomeLand.PetState.const_waitDuration or "00:00:01";
	--local frame = CommonCtrl.Storyboard.TimeSpan.GetFrames(const_waitDuration);
	--local storyboard = CommonCtrl.Storyboard.Storyboard:new();
	--storyboard:SetDuration(frame);
	--storyboard.OnEnd = function(s)
		--Map3DSystem.Item.ItemManager.UnEquipItem(self.position, function(msg) 
		--if(Map3DSystem.App.HomeLand.HomeLandGateway.IsInMyHomeland()) then
			---- refresh the pets in homeland
			--MyCompany.Aries.Pet.RefreshMyPetsFromMemoryInHomeland();
		--end
		---- refresh the avatar, mount pet and follow pet
		--Map3DSystem.Item.ItemManager.RefreshMyself();
		--
		----重新加载一次自己
		--local new_item;
		--local ItemManager = Map3DSystem.Item.ItemManager;
			--new_item= ItemManager.GetMyMountPetItem();
			--if(callbackFunc and type(callbackFunc) == "function")then
				--callbackFunc(new_item);
			--end
		---- refresh all <pe:player>
		--Map3DSystem.mcml_controls.GetClassByTagName("pe:player").RefreshContainingPageCtrls();
		--
	--end);
	--end
	--storyboard:Play();
end

-- 返回目前坐骑的详细数据
--[[
/// 返回值：
/// petid 
/// nickname 昵称
/// birthday 生日
/// level 级别
/// friendliness 亲密度
/// strong 体力值
/// cleanness 清洁值
/// mood 心情值
/// nextlevelfr 长级到下一级所需的亲密度
/// health 健康状态
--]]
function Item_MountPet:GetBean()
	return MyCompany.Aries.Pet.GetBean();
end
-- 是否可以驾驭
-- 在已经驾驭，家园内，宠物蛋，生病，死亡阶段返回false
function Item_MountPet:CanMount()
	return MyCompany.Aries.Pet.CanRide();
end
-- 是否可以跟随
-- 在已经跟随，生病，死亡阶段返回false
function Item_MountPet:CanFollow()
	return MyCompany.Aries.Pet.CanFollow();
end
function Item_MountPet:CanGoHome()
	return MyCompany.Aries.Pet.CanGoHome();
end
-- get pet place status, 
-- NOTE: currently we only support mount and homeland
-- return "home", "mount", "follow", "unknown"
function Item_MountPet:WhereAmI()
	if(self.clientdata == "mount") then
		return "mount"
	elseif(self.clientdata == "follow") then
		return "follow"
	elseif(self.clientdata == "home" or self.clientdata == "") then
		return "home"
	else
		return "unknown"
	end
end
function Item_MountPet:IsDead()
	return MyCompany.Aries.Pet.IsDead(self.nid);
end
function Item_MountPet:IsSick()
	return MyCompany.Aries.Pet.IsSick(self.nid);
end
-- return the asset file index in the desc file
function Item_MountPet:GetAssetFileIndex()
	return MyCompany.Aries.Pet.GetLevel(self.nid)
end

-- get pet name in homeland
function Item_MountPet:GetSceneObjectNameInHomeland()
	if(self:WhereAmI() ~= "home") then
		--log("error: mountpet not at home. nid:"..(self.nid or "myself").." guid:"..self.guid.."\n")
		return;
	end
	if(self.nid == nil or self.nid == System.App.profiles.ProfileManager.GetNID()) then
		return "MyMountPet:"..self.guid;
	else
		return self.nid.."MountPet:"..self.guid;
	end
end

-- get scene object in homeland
function Item_MountPet:GetSceneObjectInHomeland()
	local _pet = ParaScene.GetCharacter(self:GetSceneObjectNameInHomeland());
	if(_pet and _pet:IsValid() == true) then
		return _pet;
	end
end

-- create the scene object in homeland
function Item_MountPet:CreateSceneObjectInHomeland()
	local ItemManager = Map3DSystem.Item.ItemManager;
	local name = self:GetSceneObjectNameInHomeland();
	local gsItem = ItemManager.GetGlobalStoreItemInMemory(self.gsid);
	local Pet = MyCompany.Aries.Pet;
	local player = Pet.GetUserCharacterObj();
	if(name and gsItem and player and player:IsValid() == true) then
		-- spawn position
		local x, y, z = player:GetPosition();
		-- 10 meter in front of the player's position
		x = x + 25 * math.cos(player:GetFacing());
		z = z - 25 * math.sin(player:GetFacing());
		-- for 0821_homeland use hard coded position
		x = 19960.26953125;
		z = 20306.703125;
		
		
		-- create pet in homeland scene
		local assetfile = gsItem.assetfile;
		
		local _pet = ParaScene.GetCharacter(name);
		if(_pet and _pet:IsValid() == true) then
		else
			local obj_params = {};
			obj_params.name = name;
			obj_params.x = x + math.random(-3, 3);
			obj_params.y = y;
			obj_params.z = z + math.random(-3, 3);
			obj_params.AssetFile = assetfile;
			obj_params.IsCharacter = true;
			-- skip saving to history for recording or undo.
			System.SendMessage_obj({
				type = System.msg.OBJ_CreateObject, 
				obj_params = obj_params, 
				SkipHistory = true,
				silentmode = true,
			});
			_pet = ParaScene.GetCharacter(name);
		end
		
		-- change the asset file according to the asset file index
		local assetfile_index = 0;
		assetfile_index = self:GetAssetFileIndex();
		assetfile = ItemManager.GetAssetFileFromGSIDAndIndex(self.gsid, assetfile_index);
		
		local Player = MyCompany.Aries.Player;
		-- transformed gsid
		local transform_gsid = Player.transform_gsid;
		if(transform_gsid and self.nid == nil) then
			local gsItem = ItemManager.GetGlobalStoreItemInMemory(transform_gsid);
			if(gsItem) then
				transform_gsid = gsItem.template.stats[29];
				local gsItem = ItemManager.GetGlobalStoreItemInMemory(transform_gsid);
				if(gsItem) then
					assetfile = gsItem.assetfile;
				end
			end
		end
		
		-- modify the asset file
		System.SendMessage_obj({
			type = System.msg.OBJ_ModifyObject, 
			obj_params = _pet, 
			SkipHistory = true,
			asset_file = assetfile,
		});
		
		-- check dead or sick
		local isdead = false;
		local issick = false;
		isdead = self:IsDead();
		issick = self:IsSick();
		
		-- play animation if sick or dead
		if(issick) then
			if(assetfile_index == 1) then
				--System.Animation.PlayAnimationFile("character/Animation/v5/longbaobao/PurpleDragonEgg_sick_loop.x", _pet);
				System.Animation.PlayAnimationFile("character/Animation/v5/xiaolong/PurpleDragonMinor_sick_loop.x", _pet);
			elseif(assetfile_index == 2) then
				System.Animation.PlayAnimationFile("character/Animation/v5/xiaolong/PurpleDragonMinor_sick_loop.x", _pet);
			elseif(assetfile_index == 3) then
				System.Animation.PlayAnimationFile("character/Animation/v5/dalong/PurpleDragoonMajorFemale_sick_loop.x", _pet);
			end
		end
		if(isdead) then
			if(assetfile_index == 1) then
				--System.Animation.PlayAnimationFile("character/Animation/v5/longbaobao/PurpleDragonEgg_death_loop.x", _pet);
				System.Animation.PlayAnimationFile("character/Animation/v5/xiaolong/PurpleDragonMinor_death_loop.x", _pet);
			elseif(assetfile_index == 2) then
				System.Animation.PlayAnimationFile("character/Animation/v5/xiaolong/PurpleDragonMinor_death_loop.x", _pet);
			elseif(assetfile_index == 3) then
				System.Animation.PlayAnimationFile("character/Animation/v5/dalong/PurpleDragoonMajorFemale_death_loop.x", _pet);
			end
		end
		
		-- apply the skin color of the mount pet
		local skincolor_item;
		if(self.nid == nil or self.nid == System.App.profiles.ProfileManager.GetNID()) then
			skincolor_item = Map3DSystem.Item.ItemManager.GetItemByBagAndPosition(0, 40);
		else
			skincolor_item = Map3DSystem.Item.ItemManager.GetOPCItemByBagAndPosition(self.nid, 0, 40);
		end
		local skin_gsid = 11009;
		if(skincolor_item and skincolor_item.guid > 0) then
			skin_gsid = skincolor_item.gsid;
			if(skincolor_item.clientdata and skincolor_item.clientdata ~= "") then
				local gsid, date = string.match(skincolor_item.clientdata, "^(.+)%+(.+)$");
				if(gsid and date) then
					gsid = tonumber(gsid);
					if(date == MyCompany.Aries.Scene.GetServerDate()) then
						skin_gsid = gsid;
					end
				end
			end
		end
		local skincolor_texture;
		if(assetfile_index == 1) then -- egg
			if(skin_gsid == 11009) then
				--skincolor_texture = "character/v3/PurpleDragonEgg/SkinColor01.dds";
				skincolor_texture = "character/v3/PurpleDragonMinor/SkinColor01.dds";
			elseif(skin_gsid == 11010) then
				--skincolor_texture = "character/v3/PurpleDragonEgg/SkinColor02.dds";
				skincolor_texture = "character/v3/PurpleDragonMinor/SkinColor02.dds";
			elseif(skin_gsid == 11011) then
				--skincolor_texture = "character/v3/PurpleDragonEgg/SkinColor03.dds";
				skincolor_texture = "character/v3/PurpleDragonMinor/SkinColor03.dds";
			elseif(skin_gsid == 11012) then
				--skincolor_texture = "character/v3/PurpleDragonEgg/SkinColor04.dds";
				skincolor_texture = "character/v3/PurpleDragonMinor/SkinColor04.dds";
			elseif(skin_gsid == 16049) then
				--skincolor_texture = "character/v3/PurpleDragonEgg/SkinColor05.dds";
				skincolor_texture = "character/v3/PurpleDragonMinor/SkinColor05.dds";
			elseif(skin_gsid == 16050) then
				--skincolor_texture = "character/v3/PurpleDragonEgg/SkinColor06.dds";
				skincolor_texture = "character/v3/PurpleDragonMinor/SkinColor06.dds";
			end
		elseif(assetfile_index == 2) then -- minor
			if(skin_gsid == 11009) then
				skincolor_texture = "character/v3/PurpleDragonMinor/SkinColor01.dds";
			elseif(skin_gsid == 11010) then
				skincolor_texture = "character/v3/PurpleDragonMinor/SkinColor02.dds";
			elseif(skin_gsid == 11011) then
				skincolor_texture = "character/v3/PurpleDragonMinor/SkinColor03.dds";
			elseif(skin_gsid == 11012) then
				skincolor_texture = "character/v3/PurpleDragonMinor/SkinColor04.dds";
			elseif(skin_gsid == 16049) then
				skincolor_texture = "character/v3/PurpleDragonMinor/SkinColor05.dds";
			elseif(skin_gsid == 16050) then
				skincolor_texture = "character/v3/PurpleDragonMinor/SkinColor06.dds";
			end
		elseif(assetfile_index == 3) then -- major
			if(_pet and _pet:IsValid() == true) then
				if(skin_gsid == 11009) then
					_pet:ToCharacter():SetBodyParams(1, -1, -1, -1, -1);
				elseif(skin_gsid == 11010) then
					_pet:ToCharacter():SetBodyParams(2, -1, -1, -1, -1);
				elseif(skin_gsid == 11011) then
					_pet:ToCharacter():SetBodyParams(3, -1, -1, -1, -1);
				elseif(skin_gsid == 11012) then
					_pet:ToCharacter():SetBodyParams(4, -1, -1, -1, -1);
				elseif(skin_gsid == 16049) then
					_pet:ToCharacter():SetBodyParams(5, -1, -1, -1, -1);
				elseif(skin_gsid == 16050) then
					_pet:ToCharacter():SetBodyParams(6, -1, -1, -1, -1);
				end
			end
		end
		if(skincolor_texture) then
			if(_pet and _pet:IsValid() == true) then
				_pet:SetReplaceableTexture(1, ParaAsset.LoadTexture("", skincolor_texture, 1));
			end
		end
		
		-- hide display name of the pet when selected
		_pet:SetDynamicField("name", "");
		
		-- NOTE: special scaling for Aries project to scale the avatar to 1.6105, including avatars, dragons, follow pets, NPCs, GameObjects
		_pet:SetScale(Pet.GetMountPetScaling());
		-- set physics
		_pet:SetPhysicsRadius(0.8); -- follow pet
		_pet:SetPhysicsHeight(1.8);
		
		-- NOTE by Andy 2009/6/18: Group special for Aries project
		local SentientGroupIDs = MyCompany.Aries.SentientGroupIDs;
		_pet:SetGroupID(SentientGroupIDs["FollowPet"]);
		_pet:SetSentientField(SentientGroupIDs["Player"], true);
		_pet:SetSentientField(SentientGroupIDs["OPC"], true);
		_pet:SetPerceptiveRadius(1000);
		_pet:SetAlwaysSentient(true);
		local att = _pet:GetAttributeObject();
		att:SetField("Sentient Radius", 1000);
		
		-- set the follow pet AI template in homeland
		local playerChar = _pet:ToCharacter();
		playerChar:Stop();
		local att = _pet:GetAttributeObject();
		_pet:SnapToTerrainSurface(0);
		att:SetField("AlwaysSentient", true);
		att:SetField("Sentient", true);
		att:SetField("OnLoadScript", "");
		att:SetField("On_Perception", ";MyCompany.Aries.Pet.On_Perception();");
		att:SetField("On_EnterSentientArea", "");
		att:SetField("On_LeaveSentientArea", "");
		
		-- apply the default idle AI template
		self:ApplyIdle_AITemplate();
		-- apply the ai template in memory
		local ai_inmemory = Item_MountPet.pet_ai_mapping[tostring(self.nid or System.App.profiles.ProfileManager.GetNID())..":"..tostring(self.guid)];
		if(ai_inmemory == "follow") then
			self:ApplyFollow_AITemplate();
		end
		-- apply the sick AI template
		if(issick) then
			self:ApplySick_AITemplate();
		end
		-- apply the dead AI template
		if(isdead) then
			self:ApplyDead_AITemplate();
		end
		--if(not isdead and not issick) then
			--att:SetField("On_FrameMove", [[;NPL.load("(gl)script/apps/Aries/Pet/AI/MountPet_Homeland.lua");_AI_templates.MountPet_HomelandAI.On_FrameMove();]]);
		--end
		-- special click callback for leio
		-- TODO: remove from the On_Click field
		att:SetField("On_Click", ";MyCompany.Aries.Pet.On_MountPetClick('guest');");
	end
end

-- mount pet and ai template name mapping
Item_MountPet.pet_ai_mapping = {};

-- get ai template name
-- @return: "idle" | "follow"
function Item_MountPet:GetAITemplateName()
	local name = Item_MountPet.pet_ai_mapping[tostring(self.nid or System.App.profiles.ProfileManager.GetNID())..":"..tostring(self.guid)];
	return name or "idle";
end

-- apply idle ai template
function Item_MountPet:ApplyIdle_AITemplate()
	Item_MountPet.pet_ai_mapping[tostring(self.nid or System.App.profiles.ProfileManager.GetNID())..":"..tostring(self.guid)] = "idle";
	local name = self:GetSceneObjectNameInHomeland();
	if(name) then
		local _pet = ParaScene.GetCharacter(name);
		if(_pet and _pet:IsValid() == true) then
			local att = _pet:GetAttributeObject();
			att:SetField("On_FrameMove", 
				[[;NPL.load("(gl)script/apps/Aries/Pet/AI/MountPet_Homeland.lua");_AI_templates.MountPet_HomelandAI.On_FrameMove_Idle();]]
			);
		end
	end
end

-- apply sick ai template
function Item_MountPet:ApplySick_AITemplate()
	local name = self:GetSceneObjectNameInHomeland();
	if(name) then
		local _pet = ParaScene.GetCharacter(name);
		if(_pet and _pet:IsValid() == true) then
			local att = _pet:GetAttributeObject();
			att:SetField("On_FrameMove", "");
		end
	end
end

-- apply dead ai template
function Item_MountPet:ApplyDead_AITemplate()
	local name = self:GetSceneObjectNameInHomeland();
	if(name) then
		local _pet = ParaScene.GetCharacter(name);
		if(_pet and _pet:IsValid() == true) then
			local att = _pet:GetAttributeObject();
			att:SetField("On_FrameMove", "");
		end
	end
end

-- apply follow ai template
function Item_MountPet:ApplyFollow_AITemplate()
	Item_MountPet.pet_ai_mapping[tostring(self.nid or System.App.profiles.ProfileManager.GetNID())..":"..tostring(self.guid)] = "follow";
	local name = self:GetSceneObjectNameInHomeland();
	if(name) then
		local _pet = ParaScene.GetCharacter(name);
		if(_pet and _pet:IsValid() == true) then
			local att = _pet:GetAttributeObject();
			att:SetField("On_FrameMove", 
				[[;NPL.load("(gl)script/apps/Aries/Pet/AI/MountPet_Homeland.lua");_AI_templates.MountPet_HomelandAI.On_FrameMove_Follow();]]
			);
		end
	end
end


--Async bug
	--local player = ParaScene.GetPlayer();
	--
	--local x,y,z = player:GetPosition();
	--local name = "test1"..ParaGlobal.GenerateUniqueID();
	--local obj_params = {};
	--obj_params.name = name;
	--obj_params.x = x + math.random(-3, 3);
	--obj_params.y = y;
	--obj_params.z = z + math.random(-3, 3);
	--obj_params.AssetFile = "character/v3/PurpleDragonMinor/PurpleDragonMinor.xml";
	--obj_params.IsCharacter = true;
	---- skip saving to history for recording or undo.
	--System.SendMessage_obj({
		--type = System.msg.OBJ_CreateObject, 
		--obj_params = obj_params, 
		--SkipHistory = true,
		--silentmode = true,
	--});
	--_pet = ParaScene.GetCharacter(name);
	--_pet:SetReplaceableTexture(1, ParaAsset.LoadTexture("", "character/v3/PurpleDragonMinor/SkinColor03.dds", 1));