--[[
Title: all controls for Aries specific tags
Author(s): WangTian
Date: 2009/8/3
Desc: all aries specific tags

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/mcml/pe_aries.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/kids/3DMapSystemItem/ItemManager.lua");
local ItemManager = commonlib.gettable("Map3DSystem.Item.ItemManager");
NPL.load("(gl)script/apps/Aries/Service/CommonClientService.lua");
local CommonClientService = commonlib.gettable("MyCompany.Aries.Service.CommonClientService");			
----------------------------------------------------------------------
-- aries:userinfo: handles MCML tag <aries:userinfo>
-- it renders the name of the user field specified
----------------------------------------------------------------------
local aries_userinfo = commonlib.gettable("MyCompany.Aries.mcml_controls.aries_userinfo");

local Combat = commonlib.gettable("MyCompany.Aries.Combat");

-- aries_userinfo is just a wrapper of button control with user field value as text
function aries_userinfo.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local nid = mcmlNode:GetAttributeWithCode("nid") or mcmlNode:GetAttributeWithCode("uid");
	if(nid == nil or nid == "" or nid == "loggedinuser") then
		-- get current user ID as the nid
		nid = Map3DSystem.App.profiles.ProfileManager.GetNID();
	end
	nid = tonumber(nid);
	if(nid == nil or nid == "")  then return end
	
	-- field of the user info, default to birthday
	local field = mcmlNode:GetString("field", "birthday");
	
	
	--
	-- build the user info field content
	--
	-- use the value attribute as name if it exists
	local name = mcmlNode:GetAttributeWithCode("value");
	if(name == nil) then
		local bLocalVersion = true;
		Map3DSystem.App.profiles.ProfileManager.GetUserInfo(nid, "aries_userinfo_"..tostring(nid), function(msg)
			if(msg and msg.users and msg.users[1]) then
				local user = msg.users[1];
				local fieldvalue = user[field] or "";
				
				local function AutoRefresh(newName)
					if(newName and newName ~= name) then
						-- only refresh if name is different from last
						name = newName;
						
						local pageCtrl = mcmlNode:GetPageCtrl();
						if(pageCtrl) then
							-- needs to refresh for newly fetched version.
							mcmlNode:SetAttribute("value", name)
							if(not bLocalVersion) then
								pageCtrl:Refresh();
							end	
						end
					end
				end
				if(fieldvalue ~= nil and fieldvalue ~= "") then
					if(field == "birthday") then
						local month, day, year, hour, minute, second = string.match(fieldvalue, "(%d+)/(%d+)/(%d+) (%d+):(%d+):(%d+)");
						if(month and day and year and hour and minute and second) then
							year = tonumber(year);
							month = tonumber(month);
							day = tonumber(day);
							hour = tonumber(hour);
							minute = tonumber(minute); 
							second = tonumber(second);
							fieldvalue = year.."-"..month.."-"..day;
						end
					elseif(field == "nid") then
						fieldvalue = MyCompany.Aries.ExternalUserModule:GetNidDisplayForm(fieldvalue);
					end
					AutoRefresh(fieldvalue);
				end
			end	
		end)
		bLocalVersion = false;
	end
		
	-- TODO: each time we will rebuilt child nodes however, we can also reuse previously created ones. 
	mcmlNode:ClearAllChildren();

	local userinfo = Map3DSystem.App.profiles.ProfileManager.GetUserInfoInMemory(nid);
	if(userinfo) then
		if(field ~= "birthday" and field ~= "nid") then
			local value = userinfo[field];
			if(value) then
				name = value;
			end
		end
	end
	
	if(name) then
		-- set inner text
		mcmlNode:SetInnerText(tostring(name));
		-- just use the standard style to create the control	
		Map3DSystem.mcml_controls.pe_simple_styles.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout);
	end
end

----------------------------------------------------------------------
-- aries:mountpetname: handles MCML tag <aries:mountpetname>
----------------------------------------------------------------------
local aries_mountpetname = commonlib.gettable("MyCompany.Aries.mcml_controls.aries_mountpetname");

-- aries_mountpetname is just a wrapper of button control with mount pet name as text
function aries_mountpetname.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	
	--local guid = mcmlNode:GetNumber("guid");
	--if(guid == nil or guid == "mydragon") then
		---- get current user ID as the nid
		--guid = Map3DSystem.App.profiles.ProfileManager.GetNID();
		--NPL.load("(gl)script/kids/3DMapSystemItem/ItemManager.lua");
		--local item = ItemManager.GetMyMountPetItem();
		--if(item and item.guid > 0) then
			--guid = item.guid;
		--else
			--log("error: not valid guid for aries:mountpetname\n");
			--return;
		--end
	--end
	local nid = mcmlNode:GetAttributeWithCode("nid");
	if(nid == nil or nid == "" or nid == "loggedinuser") then
		-- get current user ID as the nid
		nid = Map3DSystem.App.profiles.ProfileManager.GetNID();
	end
	nid = tonumber(nid);
	
	---- Link to the user's profile. (default value is false) 
	--local linked = mcmlNode:GetBool("linked", false);
	
	--
	-- build the user name content: first check the userinfo.nickname if not found, check the profile app's mcml box. 
	--
	-- use the value attribute as name if it exists
	local name = mcmlNode:GetAttributeWithCode("value"); 
	if(name == nil) then
		local bLocalVersion = true;
		local function GetPetName(nid, guid)
			local msg = {
				nid = nid,
				id = guid,
			};
			paraworld.homeland.petevolved.Get(msg, nil, function(msg)
				if(msg and msg.petname) then
					local petname = msg.petname;
					
					local function AutoRefresh(newName)
						if(newName and newName ~= name) then
							-- only refresh if name is different from last
							name = newName;
							
							local pageCtrl = mcmlNode:GetPageCtrl();
							if(pageCtrl) then
								-- needs to refresh for newly fetched version.
								mcmlNode:SetAttribute("value", name)
								if(not bLocalVersion) then
									pageCtrl:Refresh(0.1);
								end	
							end
						end
					end
					
					if(petname == nil or petname == "") then
						petname = "抱抱龙";
					end
					AutoRefresh(petname);
				end	
			end, "access plus 5 minutes");
		end
		
		if(nid == Map3DSystem.App.profiles.ProfileManager.GetNID()) then
			local item = ItemManager.GetMyMountPetItem();
			if(item and item.guid > 0) then
				GetPetName(nid, item.guid);
			else
				log("error: not valid guid for nid:"..nid.."in aries:mountpetname\n");
				return;
			end
		else
			
			ItemManager.GetItemsInOPCBag(nid, 0, "pe:aries_nid"..nid, function(msg)
				local item = ItemManager.GetOPCMountPetItem(nid);
				if(item and item.guid > 0) then
					GetPetName(nid, item.guid);
				else
					log("error: not valid guid for nid:"..nid.."in aries:mountpetname\n");
					return;
				end
			end, "access plus 5 minutes");
		end
		bLocalVersion = false;
	end
		
	
	-- TODO: each time we will rebuilt child nodes however, we can also reuse previously created ones. 
	mcmlNode:ClearAllChildren();
	if(name) then
		---- add a <a> node
		--if(linked) then
			--local linkNode = Map3DSystem.mcml.new(nil, {name="a"});
			--linkNode:SetAttribute("target", "_mcmlblank");
			--if(nid) then
				--linkNode:SetAttribute("onclick", "Map3DSystem.mcml_controls.aries_mountpetname.OnClick");
				--linkNode:SetAttribute("param1", nid);
			--end	
			--linkNode:SetAttribute("tooltip", string.format("点击查看宠物%s的信息", tostring(name)));
			--if(mcmlNode:GetAttribute("a_class")) then
				--linkNode:SetAttribute("class", mcmlNode:GetAttribute("a_class"));
			--end
			--local shadowstyle = "";
			--if(style) then
				--if(style["text-shadow"]) then
					--shadowstyle = "text-shadow:true;";
				--end
			--end
			--if(mcmlNode:GetAttribute("a_style")) then
				--linkNode:SetAttribute("style", "height:19px;"..shadowstyle..mcmlNode:GetAttribute("a_style"));
			--else
				--linkNode:SetAttribute("style", "height:19px;"..shadowstyle..("" or mcmlNode:GetAttribute("style")));
			--end
			--linkNode:SetInnerText(name);
			--mcmlNode:AddChild(linkNode, nil);
			----commonlib.log("TODO: name(%s) NODE added\n", name)
		--else
			--mcmlNode:SetInnerText(name);
		--end
		
		-- directly set the inner text
		mcmlNode:SetInnerText(name);
		
		-- just use the standard style to create the control	
		Map3DSystem.mcml_controls.pe_simple_styles.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout);
	end
end

-- private: user clicks on the nid. left mouse button to open its profile page, right mouse button to open contextmenu.
function aries_mountpetname.OnClick(nid)
	log("TODO: show profile mount pet of nid:"..nid.."\n");
	--if(mouse_button == "left") then
		--Map3DSystem.App.Commands.Call("", nid)
	--end
end

-----------------------------------
-- aries:mountpet control
-----------------------------------
local aries_mountpet = commonlib.gettable("MyCompany.Aries.mcml_controls.aries_mountpet");

local CamSetting = {
	PurpleDragonEgg = {
		LookAt = {0, 0.36514848470688, 0},
		EyePos = {2.7000000476837, 0.30000001192093, 2.930297088623},
	},
	PurpleDragonMinor = {
		LookAt = {0, 0.69411826133728, 0},
		EyePos = {2.7526597976685, 0.10025001317263, 4.9751110076904},
	},
	PurpleDragonMajor = {
		LookAt = {0, 0.84263616800308, 0},
		EyePos = {2.5885643959045, 0.099945321679115, 6.2741990089417},
	},
	ZodiacAnimal = {
		LookAt = { 0, 0.67766433954239, 0 },
		EyePos = { 2.4886975288391, 0.10000000149012, 5.4713144302368 },
	},
};

-- @param assetfile: string name.
-- return LookAt, EyePos if available, otherwise it will return nil.
local function GetCameraSettingByAssetFile(assetfile)
	if(assetfile) then
		local LookAt, EyePos;
			
		if(string.find(assetfile, "ZodiacAnimal")) then
			-- this is for dragon mount pet only 
			LookAt = CamSetting.ZodiacAnimal.LookAt;
			EyePos = CamSetting.ZodiacAnimal.EyePos;
		elseif(string.find(assetfile, "PurpleDragonMajor")) then
			-- this is for dragon mount pet only 
			LookAt = CamSetting.PurpleDragonMajor.LookAt;
			EyePos = CamSetting.PurpleDragonMajor.EyePos;
		elseif(string.find(assetfile, "PurpleDragonMinor")) then
			-- this is for dragon mount pet only 
			LookAt = CamSetting.PurpleDragonMinor.LookAt;
			EyePos = CamSetting.PurpleDragonMinor.EyePos;
		elseif(string.find(assetfile, "PurpleDragonEgg")) then
			-- this is for dragon mount pet only 
			LookAt = CamSetting.PurpleDragonEgg.LookAt;
			EyePos = CamSetting.PurpleDragonEgg.EyePos;
		end
		return LookAt, EyePos;
	end
end
-- aries mount pet object
function aries_mountpet.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	-- get user nid
	local nid = mcmlNode:GetAttributeWithCode("nid");
	if(nid == "loggedinuser") then
		-- get current user ID as the uid
		nid = Map3DSystem.App.profiles.ProfileManager.GetNID();
	end
	nid = tonumber(nid);
	if(nid == nil) then
		log("error: must specify nid or \"loggedinuser\" for aries:mountpet MCML tag\n");
		return;
	end
	
	local left, top, width, height = parentLayout:GetPreferredRect();
	
	local css = mcmlNode:GetStyle(Map3DSystem.mcml_controls.pe_html.css["aries:mountpet"], style) or {};
	local padding_left, padding_top, padding_bottom, padding_right = 
		(css["padding-left"] or css["padding"] or 0),(css["padding-top"] or css["padding"] or 0),
		(css["padding-bottom"] or css["padding"] or 0),(css["padding-right"] or css["padding"] or 0);
	local margin_left, margin_top, margin_bottom, margin_right = 
			(css["margin-left"] or css["margin"] or 0),(css["margin-top"] or css["margin"] or 0),
			(css["margin-bottom"] or css["margin"] or 0),(css["margin-right"] or css["margin"] or 0);	
	if(css.width) then
		if((left + css.width)<width) then
			width = left + css.width + margin_left  + margin_right
		end
	end
	if(css.height) then
		if((top + css.height)<height) then
			height = top + css.height + margin_top  + margin_bottom
		end
	end
	local myLayout;
	if(mcmlNode:GetChildCount()>0) then
		myLayout = parentLayout:clone();
		myLayout:SetUsedSize(0,0);
		myLayout:OffsetPos(padding_left+margin_left, padding_top+margin_top);
		myLayout:IncHeight(-padding_bottom-margin_bottom);
		myLayout:IncWidth(-padding_right-margin_right);
	end	
	
	parentLayout:AddObject(width-left, height-top);

	left = left + margin_left
	top = top + margin_top;
	width = width - margin_right;
	height = height - margin_bottom;
	
	local IsActiveRendering = mcmlNode:GetBool("IsActiveRendering")
	if(IsActiveRendering == nil) then
		IsActiveRendering = true
	end
	
	local IsInteractive = mcmlNode:GetBool("IsInteractive")
	if(IsInteractive == nil) then
		IsInteractive = true;
	end
	
	local autoRotateSpeed = mcmlNode:GetNumber("autoRotateSpeed")
	if(autoRotateSpeed == nil) then
		autoRotateSpeed = 0;
	end
	
	local IsPortrait = mcmlNode:GetBool("IsPortrait")
	if(IsPortrait == nil) then
		IsPortrait = false;
	end
	
	local miniSceneName = mcmlNode:GetAttributeWithCode("miniscenegraphname") or "aries:mountpet"..ParaGlobal.GenerateUniqueID();
	
	-- create the 3d canvas for avatar display
	local instName = mcmlNode:GetInstanceName(rootName);
	NPL.load("(gl)script/ide/Canvas3D.lua");
	local ctl = CommonCtrl.Canvas3D:new{
		name = instName.."_mountpet",
		alignment = "_lt",
		left = left,
		top = top,
		width = width - left,
		height = height - top,
		background = mcmlNode:GetString("background") or css.background,
		parent = _parent,
		IsActiveRendering = IsActiveRendering,
		miniscenegraphname = miniSceneName,
		RenderTargetSize = mcmlNode:GetNumber("RenderTargetSize") or 256,
		IsInteractive = IsInteractive,
		autoRotateSpeed = autoRotateSpeed,
	};
	ctl:Show(true);
	
	--Map3DSystem.mcml_controls.aries_mountpet_all = Map3DSystem.mcml_controls.aries_mountpet_all or {};
	--Map3DSystem.mcml_controls.aries_mountpet_all[instName.."_mountpet"] = miniSceneName;
	
	if(not commonlib.getfield("MyCompany.Aries")) then
		log("error: call pe:player outside the Aries project\n");
		return;
	end
	
	local Pet = MyCompany.Aries.Pet;
	local Quest = MyCompany.Aries.Quest;
	local player;
	player = Pet.GetUserMountObj(nid);
	
	local function PlayAnimIfSickOrDead()
		-- play sick or dead animation if appropriate
		local isdead = false;
		local issick = false;
		local item;
		if(nid == System.App.profiles.ProfileManager.GetNID()) then
			-- my mount
			item = ItemManager.GetMyMountPetItem();
		else
			-- OPC mount
			item = ItemManager.GetOPCMountPetItem(nid);
		end
		if(item and item.guid > 0 and type(item.IsDead) == "function" and type(item.IsSick) == "function") then
			isdead = item:IsDead();
			issick = item:IsSick();
		end
		local miniGraph = ParaScene.GetMiniSceneGraph(miniSceneName);
		if(miniGraph and miniGraph:IsValid() == true) then
			local obj = miniGraph:GetObject(miniSceneName.."_obj");
			if(obj and obj:IsValid() == true) then
				if(issick) then
					local index = item:GetAssetFileIndex();
					if(index == 1) then
						System.Animation.PlayAnimationFile("character/Animation/v5/xiaolong/PurpleDragonMinor_sick_loop.x", obj);
						--System.Animation.PlayAnimationFile("character/Animation/v5/longbaobao/PurpleDragonEgg_sick_loop.x", obj);
					elseif(index == 2) then
						System.Animation.PlayAnimationFile("character/Animation/v5/xiaolong/PurpleDragonMinor_sick_loop.x", obj);
					elseif(index == 3) then
						System.Animation.PlayAnimationFile("character/Animation/v5/dalong/PurpleDragoonMajorFemale_sick_loop.x", obj);
					end
				end
				if(isdead) then
					local index = item:GetAssetFileIndex();
					if(index == 1) then
						System.Animation.PlayAnimationFile("character/Animation/v5/xiaolong/PurpleDragonMinor_death_loop.x", obj);
						--System.Animation.PlayAnimationFile("character/Animation/v5/longbaobao/PurpleDragonEgg_death_loop.x", obj);
					elseif(index == 2) then
						System.Animation.PlayAnimationFile("character/Animation/v5/xiaolong/PurpleDragonMinor_death_loop.x", obj);
					elseif(index == 3) then
						System.Animation.PlayAnimationFile("character/Animation/v5/dalong/PurpleDragoonMajorFemale_death_loop.x", obj);
					end
				end
			end
		end
	end
	
	if(player and player:IsValid() == true) then
		-- clone the player apparence information and apply to pe:player
		if(ctl) then
			local function CloneObj(obj)
				local ret_obj;
				if(obj and obj:IsValid() == true) then
					if(obj:IsCharacter()) then
						local asset = obj:GetPrimaryAsset();
						-- remove the zodiac animal lilypad
						local asset_file = string.gsub(asset:GetKeyName(), "_withlilypad", "");
						if(asset_file ~= asset:GetKeyName()) then
							asset = ParaAsset.LoadParaX("", asset_file);
						end
						
						ret_obj = ParaScene.CreateCharacter(miniSceneName.."_obj", asset, "", true, 0.35, -1.57, 1);
						local replaceable_r1 = obj:GetReplaceableTexture(1):GetFileName();
						ret_obj:SetReplaceableTexture(1, ParaAsset.LoadTexture("", replaceable_r1, 1));
					end
					if(obj:ToCharacter():IsCustomModel()) then
						local facial_info_string = Map3DSystem.UI.CCS.Predefined.GetFacialInfoString(obj);
						local cartoonface_info_string = Map3DSystem.UI.CCS.DB.GetCartoonfaceInfoString(obj);
						local characterslot_info_string = Map3DSystem.UI.CCS.Inventory.GetCharacterSlotInfoString(obj);
						Map3DSystem.UI.CCS.Predefined.ApplyFacialInfoString(ret_obj, facial_info_string);
						Map3DSystem.UI.CCS.DB.ApplyCartoonfaceInfoString(ret_obj, cartoonface_info_string);
						Map3DSystem.UI.CCS.Inventory.ApplyCharacterSlotInfoString(ret_obj, characterslot_info_string);
					end
				end
				return ret_obj;
			end
			
			local LookAt, EyePos = GetCameraSettingByAssetFile(player:GetPrimaryAsset():GetKeyName());
			
			ctl:ShowModel(CloneObj(player), LookAt==nil);
			ctl.ClonedObjName = player.name;
			PlayAnimIfSickOrDead();

			if(LookAt) then
				ctl:CameraSetLootAtPos(LookAt[1], LookAt[2], LookAt[3]);
				ctl:CameraSetEyePosByAngle(EyePos[1], EyePos[2], EyePos[3]);
			end

			-- set the mask texture
			local MaskTexture = mcmlNode:GetAttributeWithCode("MaskTexture");
			if(ctl and MaskTexture ~= nil and MaskTexture ~= "") then
				ctl:SetMaskTexture(MaskTexture);
			end
		end
	else
		local ItemManager = Map3DSystem.Item.ItemManager;
		ItemManager.GetItemsInOPCBag(nid, 0, nid.."_GetItemsInOPCBag", function(msg)
			local item;
			if(nid == System.App.profiles.ProfileManager.GetNID()) then
				-- my mount
				item = ItemManager.GetMyMountPetItem();
			else
				-- OPC mount
				item = ItemManager.GetOPCMountPetItem(nid);
			end
			if(item and item.guid > 0) then
				local msg = {
					nid = nid,
					id = item.guid,
				};
				paraworld.homeland.petevolved.Get(msg, "aries_getpet", function(msg)
					if(msg and not msg.errorcode) then
						local assetfile;
						local replaceable_r1;
						-- hard code the pet level here, TODOL remove to the mount item
						local mountPetStage;
						if(msg.level < 3) then
							mountPetStage = 1;
						elseif(msg.level < 8) then
							mountPetStage = 2;
						else
							mountPetStage = 3;
						end
						assetfile = ItemManager.GetAssetFileFromGSIDAndIndex(item.gsid, mountPetStage);
						if(ctl) then
							local asset = ParaAsset.LoadParaX("", assetfile);
							local obj = ParaScene.CreateCharacter(miniSceneName.."_obj", asset, "", true, 0.35, -1.57, 1);
							
							local basecolor_gsid;
							local item_skin;
							if(nid == System.App.profiles.ProfileManager.GetNID()) then
								-- my mount
								item_skin = ItemManager.GetItemByBagAndPosition(0, 40);
							else
								-- OPC mount
								item_skin = ItemManager.GetOPCItemByBagAndPosition(nid, 0, 40);
							end

							if (System.options.version == "kids") then
								if(item_skin and item_skin.guid > 0) then
									basecolor_gsid = item_skin.gsid;
									if(item_skin.clientdata and item_skin.clientdata ~= "") then
										local gsid, date = string.match(item_skin.clientdata, "^(.+)%+(.+)$");
										if(gsid and date) then
											gsid = tonumber(gsid);
											if(date == MyCompany.Aries.Scene.GetServerDate()) then
												basecolor_gsid = gsid;
											end
										end
									end
								end
								if(mountPetStage == 1) then -- egg
									if(basecolor_gsid == 11009) then
										--replaceable_r1 = "character/v3/PurpleDragonEgg/SkinColor01.dds";
										replaceable_r1 = "character/v3/PurpleDragonMinor/SkinColor01.dds";
									elseif(basecolor_gsid == 11010) then
										--replaceable_r1 = "character/v3/PurpleDragonEgg/SkinColor02.dds";
										replaceable_r1 = "character/v3/PurpleDragonMinor/SkinColor02.dds";
									elseif(basecolor_gsid == 11011) then
										--replaceable_r1 = "character/v3/PurpleDragonEgg/SkinColor03.dds";
										replaceable_r1 = "character/v3/PurpleDragonMinor/SkinColor03.dds";
									elseif(basecolor_gsid == 11012) then
										--replaceable_r1 = "character/v3/PurpleDragonEgg/SkinColor04.dds";
										replaceable_r1 = "character/v3/PurpleDragonMinor/SkinColor04.dds";
									elseif(basecolor_gsid == 16049) then
										--replaceable_r1 = "character/v3/PurpleDragonEgg/SkinColor05.dds";
										replaceable_r1 = "character/v3/PurpleDragonMinor/SkinColor05.dds";
									elseif(basecolor_gsid == 16050) then
										--replaceable_r1 = "character/v3/PurpleDragonEgg/SkinColor06.dds";
										replaceable_r1 = "character/v3/PurpleDragonMinor/SkinColor06.dds";
									end
								elseif(mountPetStage == 2) then -- minor
									if(basecolor_gsid == 11009) then
										replaceable_r1 = "character/v3/PurpleDragonMinor/SkinColor01.dds";
									elseif(basecolor_gsid == 11010) then
										replaceable_r1 = "character/v3/PurpleDragonMinor/SkinColor02.dds";
									elseif(basecolor_gsid == 11011) then
										replaceable_r1 = "character/v3/PurpleDragonMinor/SkinColor03.dds";
									elseif(basecolor_gsid == 11012) then
										replaceable_r1 = "character/v3/PurpleDragonMinor/SkinColor04.dds";
									elseif(basecolor_gsid == 16049) then
										replaceable_r1 = "character/v3/PurpleDragonMinor/SkinColor05.dds";
									elseif(basecolor_gsid == 16050) then
										replaceable_r1 = "character/v3/PurpleDragonMinor/SkinColor06.dds";
									end
								elseif(mountPetStage == 3) then -- major
									if(basecolor_gsid == 11009) then
										obj:ToCharacter():SetBodyParams(1, -1, -1, -1, -1);
									elseif(basecolor_gsid == 11010) then
										obj:ToCharacter():SetBodyParams(2, -1, -1, -1, -1);
									elseif(basecolor_gsid == 11011) then
										obj:ToCharacter():SetBodyParams(3, -1, -1, -1, -1);
									elseif(basecolor_gsid == 11012) then
										obj:ToCharacter():SetBodyParams(4, -1, -1, -1, -1);
									elseif(basecolor_gsid == 16049) then
										obj:ToCharacter():SetBodyParams(5, -1, -1, -1, -1);
									elseif(basecolor_gsid == 16050) then
										obj:ToCharacter():SetBodyParams(6, -1, -1, -1, -1);
									end
								end
							
								if(replaceable_r1) then
									obj:SetReplaceableTexture(1, ParaAsset.LoadTexture("", replaceable_r1, 1));
								end
							else
								-- teen version here
							end

							--if(obj:ToCharacter():IsCustomModel() == true) then
								--local facial_info_string = GetFacialInfoStringFromEquips(equips);
								--local cartoonface_info_string = GetCartoonfaceInfoStringFromEquips(equips);
								--local characterslot_info_string = GetCharacterSlotInfoStringFromEquips(equips, object);
								--Map3DSystem.UI.CCS.Predefined.ApplyFacialInfoString(obj, facial_info_string);
								--Map3DSystem.UI.CCS.DB.ApplyCartoonfaceInfoString(obj, cartoonface_info_string);
								--Map3DSystem.UI.CCS.Inventory.ApplyCharacterSlotInfoString(obj, characterslot_info_string);
							--end
							
							local LookAt, EyePos = GetCameraSettingByAssetFile(assetfile);
							ctl:ShowModel(obj, LookAt==nil);
							
							if(LookAt) then
								ctl:CameraSetLootAtPos(LookAt[1], LookAt[2], LookAt[3]);
								ctl:CameraSetEyePosByAngle(EyePos[1], EyePos[2], EyePos[3]);
							end
							
							local issick = false;
							local isdead = false;
							--if(msg.health == 1) then
								--issick = true;
							--elseif(msg.health == 2) then
								--isdead = true;
							--end
							--if(issick) then
								--local index = mountPetStage;
								--if(index == 1) then
									--System.Animation.PlayAnimationFile("character/Animation/v5/longbaobao/PurpleDragonEgg_sick_loop.x", obj);
								--elseif(index == 2) then
									--System.Animation.PlayAnimationFile("character/Animation/v5/xiaolong/PurpleDragonMinor_sick_loop.x", obj);
								--elseif(index == 3) then
									--System.Animation.PlayAnimationFile("character/Animation/v5/dalong/PurpleDragoonMajorFemale_sick_loop.x", obj);
								--end
							--end
							--if(isdead) then
								--local index = mountPetStage;
								--if(index == 1) then
									--System.Animation.PlayAnimationFile("character/Animation/v5/longbaobao/PurpleDragonEgg_death_loop.x", obj);
								--elseif(index == 2) then
									--System.Animation.PlayAnimationFile("character/Animation/v5/xiaolong/PurpleDragonMinor_death_loop.x", obj);
								--elseif(index == 3) then
									--System.Animation.PlayAnimationFile("character/Animation/v5/dalong/PurpleDragoonMajorFemale_death_loop.x", obj);
								--end
							--end
						end
					end
				end, "access plus 5 minutes");
			else
				return;
			end
			
		end);
	end
	
	------------------------------------
	-- load avatar information
	------------------------------------
	
end

-----------------------------------
-- aries:followpet control
-----------------------------------
local aries_followpet = commonlib.gettable("MyCompany.Aries.mcml_controls.aries_followpet");

-- aries follow pet object
function aries_followpet.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	-- get user nid
	local nid = mcmlNode:GetAttributeWithCode("nid");
	if(nid == "loggedinuser") then
		-- get current user ID as the uid
		nid = Map3DSystem.App.profiles.ProfileManager.GetNID();
	end
	nid = tonumber(nid);
	if(nid == nil) then
		log("error: must specify nid or \"loggedinuser\" for aries:followpet MCML tag\n");
		return;
	end
	
	local guid = mcmlNode:GetAttributeWithCode("guid");
	guid = tonumber(guid);
	if(guid == nil) then
		log("error: must specify guid for aries:followpet MCML tag\n");
		return;
	end
	
	local left, top, width, height = parentLayout:GetPreferredRect();
	
	local css = mcmlNode:GetStyle(Map3DSystem.mcml_controls.pe_html.css["aries:followpet"], style) or {};
	local padding_left, padding_top, padding_bottom, padding_right = 
		(css["padding-left"] or css["padding"] or 0),(css["padding-top"] or css["padding"] or 0),
		(css["padding-bottom"] or css["padding"] or 0),(css["padding-right"] or css["padding"] or 0);
	local margin_left, margin_top, margin_bottom, margin_right = 
			(css["margin-left"] or css["margin"] or 0),(css["margin-top"] or css["margin"] or 0),
			(css["margin-bottom"] or css["margin"] or 0),(css["margin-right"] or css["margin"] or 0);	
	if(css.width) then
		if((left + css.width)<width) then
			width = left + css.width + margin_left  + margin_right
		end
	end
	if(css.height) then
		if((top + css.height)<height) then
			height = top + css.height + margin_top  + margin_bottom
		end
	end
	local myLayout;
	if(mcmlNode:GetChildCount()>0) then
		myLayout = parentLayout:clone();
		myLayout:SetUsedSize(0,0);
		myLayout:OffsetPos(padding_left+margin_left, padding_top+margin_top);
		myLayout:IncHeight(-padding_bottom-margin_bottom);
		myLayout:IncWidth(-padding_right-margin_right);
	end	
	
	parentLayout:AddObject(width-left, height-top);

	left = left + margin_left
	top = top + margin_top;
	width = width - margin_right;
	height = height - margin_bottom;
	
	local IsActiveRendering = mcmlNode:GetBool("IsActiveRendering")
	if(IsActiveRendering == nil) then
		IsActiveRendering = true
	end
	
	local IsInteractive = mcmlNode:GetBool("IsInteractive")
	if(IsInteractive == nil) then
		IsInteractive = true;
	end
	
	local autoRotateSpeed = mcmlNode:GetNumber("autoRotateSpeed")
	if(autoRotateSpeed == nil) then
		autoRotateSpeed = 0;
	end
	
	local IsPortrait = mcmlNode:GetBool("IsPortrait")
	if(IsPortrait == nil) then
		IsPortrait = false;
	end
	
	local miniSceneName = mcmlNode:GetAttributeWithCode("miniscenegraphname") or "pe:name"..ParaGlobal.GenerateUniqueID();
	
	-- create the 3d canvas for avatar display
	local instName = mcmlNode:GetInstanceName(rootName);
	NPL.load("(gl)script/ide/Canvas3D.lua");
	local ctl = CommonCtrl.Canvas3D:new{
		name = instName.."_followpet",
		alignment = "_lt",
		left = left,
		top = top,
		width = width - left,
		height = height - top,
		background = mcmlNode:GetString("background") or css.background,
		parent = _parent,
		IsActiveRendering = IsActiveRendering,
		miniscenegraphname = miniSceneName,
		RenderTargetSize = mcmlNode:GetNumber("RenderTargetSize") or 256,
		IsInteractive = IsInteractive,
		autoRotateSpeed = autoRotateSpeed,
	};
	ctl:Show(true);
	
	--Map3DSystem.mcml_controls.aries_followpet_all = Map3DSystem.mcml_controls.aries_followpet_all or {};
	--table.insert(Map3DSystem.mcml_controls.aries_followpet_all, instName.."_followpet")
	
	if(not commonlib.getfield("MyCompany.Aries")) then
		log("error: call pe:player outside the Aries project\n");
		return;
	end
	
	local ItemManager = Map3DSystem.Item.ItemManager;
	local item;
	if(nid == Map3DSystem.App.profiles.ProfileManager.GetNID()) then
		item = ItemManager.GetItemByGUID(guid);
	else
		item = ItemManager.GetOPCItemByGUID(nid, guid);
	end
	
	if(item and item.guid > 0) then
		local gsItem = ItemManager.GetGlobalStoreItemInMemory(item.gsid);
		if(gsItem) then
			local assetfile = gsItem.assetfile;
			if(ctl) then
				local asset = ParaAsset.LoadParaX("", assetfile);
				local obj = ParaScene.CreateCharacter(miniSceneName.."_obj", asset, "", true, 0.35, -1.57, 1);
				ctl:ShowModel(obj, true);
			end
		end
	end
	
	------------------------------------
	-- load avatar information
	------------------------------------
end

-------------------------------------
---- aries:mountpet-health control
-------------------------------------
local aries_mountpet_health = commonlib.gettable("MyCompany.Aries.mcml_controls.aries_mountpet_health");

local healthy_icon = "Texture/Aries/Inventory/healthy_icon_32bits.png";
local sick_icon = "Texture/Aries/Inventory/sick_icon_32bits.png";
local dead_icon = "Texture/Aries/Inventory/dead_icon_32bits.png";

-- aries mount pet health object
function aries_mountpet_health.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local nid = mcmlNode:GetAttributeWithCode("nid");
	if(nid == "loggedinuser") then
		-- get current user nid as the nid
		nid = Map3DSystem.App.profiles.ProfileManager.GetNID();
	end
	nid = tonumber(nid);
	if(nid == nil) then
		log("error: must specify nid or \"loggedinuser\" for aries:mountpet-health MCML tag\n");
		return;
	end
	
	local value = mcmlNode:GetAttributeWithCode("value"); 
	if(value == nil) then
		local bLocalVersion = true;
		local function GetPetHealth(nid, guid)
			local msg = {
				nid = nid,
				id = guid,
			};
			paraworld.homeland.petevolved.Get(msg, "aries:mountpet_health"..tostring(nid).."_"..tostring(guid), function(msg)
				if(msg and msg.health) then
					local health = msg.health;
					
					local function AutoRefresh(newValue)
						if(newValue and newValue ~= value) then
							-- only refresh if value is different from last
							value = newValue;
							
							local pageCtrl = mcmlNode:GetPageCtrl();
							if(pageCtrl) then
								-- needs to refresh for newly fetched version.
								mcmlNode:SetAttribute("value", value)
								if(not bLocalVersion) then
									pageCtrl:Refresh(0.1);
								end	
							end
						end
					end
					
					if(health == nil or health == "") then
						health = 1;
					end
					AutoRefresh(health);
				end	
			end, "access plus 5 minutes");
		end
		
		if(nid == Map3DSystem.App.profiles.ProfileManager.GetNID()) then
			local item = ItemManager.GetMyMountPetItem();
			if(item and item.guid > 0) then
				GetPetHealth(nid, item.guid);
			else
				log("error: not valid guid for nid:"..nid.."in aries:mountpet-health\n");
				return;
			end
		else
			ItemManager.GetItemsInOPCBag(nid, 0, "aries:mountpet_health_"..nid, function(msg)
				local item = ItemManager.GetOPCMountPetItem(nid);
				if(item and item.guid > 0) then
					GetPetHealth(nid, item.guid);
				else
					log("error: not valid guid for nid:"..nid.."in aries:mountpet-health\n");
					return;
				end
			end, "access plus 5 minutes");
		end
		bLocalVersion = false;
	end
	
	-- render the data directly in local server
	if(value == nil) then
		local guid;
		if(nid == Map3DSystem.App.profiles.ProfileManager.GetNID()) then
			local item = ItemManager.GetMyMountPetItem();
			if(item and item.guid > 0) then
				guid = item.guid;
			end
		else
			local item = ItemManager.GetOPCMountPetItem(nid);
			if(item and item.guid > 0) then
				guid = item.guid;
			end
		end
		if(nid and guid) then
			local msg = paraworld.homeland.petevolved.get_get_inlocalserver(nid, guid);
			if(msg) then
				value = msg.health;
			end
		end
	end
	
	local src = "";
	local tooltip = "";
	--if(value == nil) then
		src = mcmlNode:GetAttributeWithCode("healthy_icon") or healthy_icon;
		tooltip = "健康";
	--elseif(value == 0) then
		--src = mcmlNode:GetAttributeWithCode("healthy_icon") or healthy_icon;
		--tooltip = "健康";
	--elseif(value == 1) then
		--src = mcmlNode:GetAttributeWithCode("sick_icon") or sick_icon;
		--tooltip = "生病";
	--elseif(value == 2) then
		--src = mcmlNode:GetAttributeWithCode("dead_icon") or dead_icon;
		--tooltip = "死亡";
	--end
	
	local allowtooltip = mcmlNode:GetBool("allowtooltip", false);
	if(allowtooltip) then
		mcmlNode:SetAttribute("tooltip", tooltip);
	end
	mcmlNode:SetAttribute("src", src);
	-- create as an <img> tag
	Map3DSystem.mcml_controls.pe_img.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout);
end


-------------------------------------
---- aries:mountpet-level control
-------------------------------------
local aries_mountpet_level = commonlib.gettable("MyCompany.Aries.mcml_controls.aries_mountpet_level");

local healthy_icon = "Texture/Aries/Inventory/healthy_icon_32bits.png";
local sick_icon = "Texture/Aries/Inventory/sick_icon_32bits.png";
local dead_icon = "Texture/Aries/Inventory/dead_icon_32bits.png";

-- aries mount pet level object
function aries_mountpet_level.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local nid = mcmlNode:GetAttributeWithCode("nid");
	if(nid == "loggedinuser") then
		-- get current user nid as the nid
		nid = Map3DSystem.App.profiles.ProfileManager.GetNID();
	end
	nid = tonumber(nid);
	if(nid == nil) then
		log("error: must specify nid or \"loggedinuser\" for aries:mountpet-level MCML tag\n");
		return;
	end
	
	local value = mcmlNode:GetAttributeWithCode("value");
	if(value == nil) then
		local bLocalVersion = true;
		
		if(nid == Map3DSystem.App.profiles.ProfileManager.GetNID()) then
			value = MyCompany.Aries.Player.GetDragonLevel();
			mcmlNode:SetAttribute("value", value);
		else
			System.App.profiles.ProfileManager.GetUserInfo(nid, "UpdateUserInfoInMemoryAfterSellItem", 
				function(msg) 
					local myInfo = System.App.profiles.ProfileManager.GetUserInfoInMemory(nid);
					if(myInfo and myInfo.level and value~=myInfo.level) then
						mcmlNode:SetAttribute("value", if_else(myInfo.level>=0, myInfo.level, 0));
						local pageCtrl = mcmlNode:GetPageCtrl();
						if(pageCtrl) then
							pageCtrl:Refresh(0.1);
						end
					end
				end, "access plus 1 hour");
		end
		bLocalVersion = false;
	end
	
	-- render the data directly in local server
	if(value == nil) then
		local guid;
		if(nid == Map3DSystem.App.profiles.ProfileManager.GetNID()) then
			local item = ItemManager.GetMyMountPetItem();
			if(item and item.guid > 0) then
				guid = item.guid;
			end
		else
			local item = ItemManager.GetOPCMountPetItem(nid);
			if(item and item.guid > 0) then
				guid = item.guid;
			end
		end
		if(nid and guid) then
			local msg = paraworld.homeland.petevolved.get_get_inlocalserver(nid, guid);
			if(msg) then
				value = msg.level;
			end
		end
	end
	
	-- default to 0;
	value = value or 0;
	
	local allowtooltip = mcmlNode:GetAttributeWithCode("allowtooltip");
	if(allowtooltip) then
		mcmlNode:SetAttribute("tooltip", "等级:"..value);
		mcmlNode:SetAttribute("alwaysmouseover", true);
	end
	-- create the background part as an <img> tag
	Map3DSystem.mcml_controls.pe_img.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout);
	
	local node = Map3DSystem.mcml.new(nil, {name = "aries:textsprite"});
	node:SetAttribute("text", value);
	node:SetAttribute("spritestyle", "DragonLevel");
	node:SetAttribute("color", "");
	node:SetAttribute("fontsize", "26");
	local allowtooltip = mcmlNode:GetAttributeWithCode("allowtooltip");
	if(allowtooltip) then
		node:SetAttribute("tooltip", "等级:"..value);
	end
	mcmlNode:AddChild(node, nil);
	local level_number_margin_left = 14;
	if(value < 10) then
		level_number_margin_left = 23;
	elseif(value < 20) then
		level_number_margin_left = 16;
	else
		level_number_margin_left = 14;
	end
	local level_number_margin_top = 16;
	-- create the text part as an <aries:textsprite> tag
	local myLayout = Map3DSystem.mcml_controls.layout:new();
	myLayout:reset(left + level_number_margin_left, top + level_number_margin_top, width, height);
	Map3DSystem.mcml_controls.create(rootName, node, bindingContext, _parent, left, top, width, height, nil, myLayout);
end


-------------------------------------
---- aries:mountpet-status control
-------------------------------------
local aries_mountpet_status = commonlib.gettable("MyCompany.Aries.mcml_controls.aries_mountpet_status");

local healthy_icon = "Texture/Aries/Inventory/healthy_icon_32bits.png";
local sick_icon = "Texture/Aries/Inventory/sick_icon_32bits.png";
local dead_icon = "Texture/Aries/Inventory/dead_icon_32bits.png";

-- aries mount pet status object
function aries_mountpet_status.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local nid = mcmlNode:GetAttributeWithCode("nid");
	if(nid == "loggedinuser") then
		-- get current user nid as the nid
		nid = Map3DSystem.App.profiles.ProfileManager.GetNID();
	end
	nid = tonumber(nid);
	if(nid == nil) then
		log("error: must specify nid or \"loggedinuser\" for aries:mountpet-status MCML tag\n");
		return;
	end
	
	local type = mcmlNode:GetAttributeWithCode("type");
	if(not type) then
		log("error: must specify type for aries:mountpet-status MCML tag\n");
		return;
	end
	
	local value2 = mcmlNode:GetAttributeWithCode("value2");
	if(value2 == nil) then
		local bLocalVersion = true;
		local function GetPetStatus(nid, guid)
			local msg = {
				nid = nid,
				id = guid,
			};
			paraworld.homeland.petevolved.Get(msg, nil, function(msg)
				if(msg and msg[type]) then
					local status = "0/500";
					if(type == "friendliness") then
						status = msg.friendliness.."/"..(msg.nextlevelfr or (msg.friendliness + 1));
					elseif(type == "strong") then
						status = msg.strong.."/500";
					elseif(type == "cleanness") then
						status = msg.cleanness.."/500";
					elseif(type == "mood") then
						status = msg.mood.."/500";
					end
					
					local function AutoRefresh(newValue)
						if(newValue and newValue ~= value2) then
							-- only refresh if value is different from last
							value2 = newValue;
							local pageCtrl = mcmlNode:GetPageCtrl();
							if(pageCtrl) then
								-- needs to refresh for newly fetched version.
								mcmlNode:SetAttribute("value2", value2)
								if(not bLocalVersion) then
									pageCtrl:Refresh(0.1);
								end	
							end
						end
					end
					if(status == nil or status == "") then
						status = "0/500";
					end
					AutoRefresh(status);
				end	
			end, "access plus 5 minutes");
		end
		
		if(nid == Map3DSystem.App.profiles.ProfileManager.GetNID()) then
			local item = ItemManager.GetMyMountPetItem();
			if(item and item.guid > 0) then
				GetPetStatus(nid, item.guid);
			else
				log("error: not valid guid for nid:"..nid.."in aries:mountpet-status\n");
				return;
			end
		else
			ItemManager.GetItemsInOPCBag(nid, 0, "aries:mountpet_status_"..nid, function(msg)
				local item = ItemManager.GetOPCMountPetItem(nid);
				if(item and item.guid > 0) then
					GetPetStatus(nid, item.guid);
				else
					log("error: not valid guid for nid:"..nid.."in aries:mountpet-status\n");
					return;
				end
			end, "access plus 5 minutes");
		end
		bLocalVersion = false;
	end
	
	
	-- render the data directly in local server
	if(value2 == nil) then
		local guid;
		if(nid == Map3DSystem.App.profiles.ProfileManager.GetNID()) then
			local item = ItemManager.GetMyMountPetItem();
			if(item and item.guid > 0) then
				guid = item.guid;
			end
		else
			local item = ItemManager.GetOPCMountPetItem(nid);
			if(item and item.guid > 0) then
				guid = item.guid;
			end
		end
		if(nid and guid) then
			local msg = paraworld.homeland.petevolved.get_get_inlocalserver(nid, guid);
			if(msg) then
				local status = "0/500";
				if(type == "friendliness") then
					value2 = msg.friendliness.."/"..(msg.nextlevelfr or (msg.friendliness + 1));
				elseif(type == "strong") then
					value2 = msg.strong.."/500";
				elseif(type == "cleanness") then
					value2 = msg.cleanness.."/500";
				elseif(type == "mood") then
					value2 = msg.mood.."/500";
				end
			end
		end
	end
	
	-- default to "0/500";
	value2 = value2 or "0/500";
	
	local current, max = string.match(value2, "^(%d+)/(%d+)$");
	current = tonumber(current) or 0;
	max = tonumber(max) or 500;
	
	mcmlNode:SetAttribute("Value", current);
	mcmlNode:SetAttribute("Maximum", max);
	
	mcmlNode:SetAttribute("background", "Texture/Aries/Inventory/Empty_slot_32bits.png;0 0 32 26: 14 13 14 12");
	if(type == "friendliness") then
		mcmlNode:SetAttribute("blockimage", "Texture/Aries/Inventory/purple_fill_32bits.png;0 0 32 26: 14 13 14 12");
	elseif(type == "strong" or type == "cleanness" or type == "mood") then
		if(current <= 150) then
			mcmlNode:SetAttribute("blockimage", "Texture/Aries/Inventory/orange_fill_32bits.png;0 0 32 26: 14 13 14 12");
		elseif(current <= 300) then
			mcmlNode:SetAttribute("blockimage", "Texture/Aries/Inventory/blue_fill_32bits.png;0 0 32 26: 14 13 14 12");
		elseif(current <= 500) then
			mcmlNode:SetAttribute("blockimage", "Texture/Aries/Inventory/green_fill_32bits.png;0 0 32 26: 14 13 14 12");
		end
	end
	-- create the background part as an <pe:progressbar> tag
	Map3DSystem.mcml_controls.pe_progressbar.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout);
end

-------------------------------------
---- aries:mountpet-status2 control
-------------------------------------
local aries_mountpet_status2 = commonlib.gettable("MyCompany.Aries.mcml_controls.aries_mountpet_status2");

local healthy_icon = "Texture/Aries/Inventory/healthy_icon_32bits.png";
local sick_icon = "Texture/Aries/Inventory/sick_icon_32bits.png";
local dead_icon = "Texture/Aries/Inventory/dead_icon_32bits.png";

-- aries mount pet status object
function aries_mountpet_status2.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local nid = mcmlNode:GetAttributeWithCode("nid",nil,true);
	if(nid == "loggedinuser") then
		-- get current user nid as the nid
		nid = Map3DSystem.App.profiles.ProfileManager.GetNID();
	end
	nid = tonumber(nid);
	if(nid == nil) then
		log("error: must specify nid or \"loggedinuser\" for aries:mountpet-status2 MCML tag\n");
		return;
	end
	
	local type = mcmlNode:GetAttributeWithCode("type");
	if(not type) then
		log("error: must specify type for aries:mountpet-status2 MCML tag\n");
		return;
	end
	
	local value2 = mcmlNode:GetAttributeWithCode("value2");
	local bHideIfNotVIP = mcmlNode:GetBool("hideifnotvip");
	local bShowZero = mcmlNode:GetBool("showzero");
	local luck_map = {
		[0] = {text = "大凶"},
		[1] = {text = "凶"},
		[2] = {text = "正常"},
		[3] = {text = "小吉"},
		[4] = {text = "吉"},
	}
	--[[
		m_nextlelm 经验进度数字
		add_hp hp加成 
		add_attack 攻击加成
		add_guard 防御加成
		add_exp 经验加成
		add_hit 命中加成
	--]]
	local function get_extend_value(pet,type)
		if(pet)then
			local energy = pet.energy or 0;
			local mlel = pet.mlel or 0;
			if(energy <= 0)then
				if(type == "m_nextlelm")then
					return "0/0";
				else
					return "0";
				end
			end
			local specialList;
			local options = commonlib.gettable("System.options");
			if(options.version and options.version == "teen")then
				specialList = {
					{ speed="20",exp="0",HP="0",  vipright="优先进入满员服务器，死亡装备无损与满血复活"},
					{ speed="20",exp="40",HP="0", vipright="随身商店 5 折"},
					{ speed="20",exp="40",HP="50", vipright="加快的生产、采集速度"},
					{ speed="30",exp="40",HP="50", vipright="随身交易所"},
					{ speed="30",exp="60",HP="50", vipright="公会活跃度双倍"},
					{ speed="30",exp="60",HP="70", vipright="自由传送特权"},
					{ speed="40",exp="60",HP="70", vipright=""},
					{ speed="40",exp="80",HP="70", vipright=""},
					{ speed="40",exp="80",HP="90", vipright=""},
					{ speed="50",exp="100",HP="100", vipright=""},
					--{ HP="3",attack="3",guard="2",cure="2",hit="2",exp="50"},
					--{ HP="3",attack="3",guard="2",cure="3",hit="2",exp="55"},
					--{ HP="3",attack="3",guard="2",cure="3",hit="3",exp="60"},
					--{ HP="4",attack="4",guard="3",cure="4",hit="3",exp="65"},
					--{ HP="4",attack="4",guard="3",cure="4",hit="4",exp="70"},
					--{ HP="4",attack="4",guard="3",cure="4",hit="4",exp="75"},
					--{ HP="5",attack="5",guard="4",cure="5",hit="5",exp="80"},
					--{ HP="5",attack="5",guard="4",cure="5",hit="5",exp="85"},
					--{ HP="5",attack="5",guard="4",cure="5",hit="6",exp="90"},
					--{ HP="6",attack="6",guard="5",cure="5",hit="6",exp="100"},
				};
				mlel = mlel + 1;
				mlel = math.min(mlel,10);
			else
				 specialList = {
					{ HP="5",attack="5",guard="4",cure="2",becured="2",hit="2",exp="150"},
					{ HP="5",attack="5",guard="5",cure="3",becured="3",hit="2",exp="155"},
					{ HP="5",attack="5",guard="6",cure="4",becured="3",hit="3",exp="160"},
					{ HP="6",attack="6",guard="6",cure="4",becured="3",hit="3",exp="165"},
					{ HP="6",attack="6",guard="7",cure="4",becured="5",hit="4",exp="170"},
					{ HP="6",attack="7",guard="7",cure="5",becured="5",hit="4",exp="175"},
					{ HP="7",attack="7",guard="7",cure="5",becured="6",hit="4",exp="180"},
					{ HP="7",attack="7",guard="8",cure="6",becured="6",hit="5",exp="185"},
					{ HP="7",attack="8",guard="8",cure="6",becured="7",hit="5",exp="190"},
					{ HP="8",attack="9",guard="8",cure="6",becured="7",hit="5",exp="195"},
					{ HP="10",attack="10",guard="9",cure="8",becured="8",hit="6",exp="200"},
				};
				mlel = mlel + 1;
				mlel = math.min(mlel,11);
			end
			
			local node = specialList[mlel];
			if (options.version and options.version == "teen")then
				if(type == "m_nextlelm")then
					local nextlelm = pet.nextlelm or 0;
					return string.format("%d/%d",pet.m or 0,nextlelm);
				elseif(type == "add_hp")then
					return string.format("+%s%%",node.HP);
				elseif(type == "add_exp")then
					return string.format("+%s%%",node.exp);
				else
					return "";
				end
			else
				if(type == "m_nextlelm")then
					local nextlelm = pet.nextlelm or 0;
					return string.format("%d/%d",pet.m or 0,nextlelm);
				elseif(type == "add_hp")then
					return string.format("+%s%%",node.HP);
				elseif(type == "add_attack")then
					return string.format("+%s%%",node.attack);
				elseif(type == "add_guard")then
					return string.format("+%s%%",node.guard);
				elseif(type == "add_exp")then
					return string.format("+%s%%",node.exp);
				elseif(type == "add_hit")then
					return string.format("+%s%%",node.hit);
				end
			end
		end
	end
	if(value2 == nil) then
		local bLocalVersion = true;
		local function GetPetStatus(nid, guid)
			local msg = {
				nid = nid,
				id = guid,
			};
			System.App.profiles.ProfileManager.GetUserInfo(nid, "UpdateUserInfo", function(msg)
			--paraworld.homeland.petevolved.Get(msg, nil, function(msg)
				msg = msg.users[1]; 
				if(msg) then
					local status;
					if(type == "m_nextlelm" or type == "add_hp" or type == "add_attack" or type == "add_guard" or type == "add_exp" or type == "add_hit")then
						status = get_extend_value(msg,type);
					elseif(type == "luck_text" )then
						local luck = msg.luck or 2;
						local node = luck_map[luck];
						if(node)then
							status = node.text or "";
						end
					else
						status = msg[type] or "";
					end
					--if(msg.energy <= 0 and bHideIfNotVIP == true) then
					-- NOTE: dirty code why is bHideIfNotVIP nil
					if (System.options.version == "kids") then
						if(msg.energy and msg.energy <= 0 and type == "mlel") then
							status = "";
							if(bShowZero)then
								status = "0";
							end
						end
					else
						if(msg.mlel and msg.mlel <= 0 and type == "mlel")then
							status = "";
							if(bShowZero)then
								status = "0";
							end
						end
					end
					local function AutoRefresh(newValue)
						if(newValue and newValue ~= value2) then
							-- only refresh if value is different from last
							value2 = newValue;
							local pageCtrl = mcmlNode:GetPageCtrl();
							if(pageCtrl) then
								-- needs to refresh for newly fetched version.
								mcmlNode:SetInnerText(value2)
								if(not bLocalVersion) then
									pageCtrl:Refresh(0.1);
								end	
							end
						end
					end
					AutoRefresh(status);
				end	
			end, "access plus 5 minutes");
		end
		
		if(nid == Map3DSystem.App.profiles.ProfileManager.GetNID()) then
			local item = ItemManager.GetMyMountPetItem();
			if(item and item.guid > 0) then
				GetPetStatus(nid, item.guid);
			else
				log("error: not valid guid for nid:"..nid.."in aries:mountpet-status\n");
				return;
			end
		else
			ItemManager.GetItemsInOPCBag(nid, 0, "aries:mountpet_status_"..nid, function(msg)
				local item = ItemManager.GetOPCMountPetItem(nid);
				if(item and item.guid > 0) then
					GetPetStatus(nid, item.guid);
				else
					log("error: not valid guid for nid:"..nid.."in aries:mountpet-status\n");
					return;
				end
			end, "access plus 5 minutes");
		end
		bLocalVersion = false;
	end
	
	
	-- render the data directly in local server
	if(value2 == nil) then
		local guid;
		if(nid == Map3DSystem.App.profiles.ProfileManager.GetNID()) then
			local item = ItemManager.GetMyMountPetItem();
			if(item and item.guid > 0) then
				guid = item.guid;
			end
		else
			local item = ItemManager.GetOPCMountPetItem(nid);
			if(item and item.guid > 0) then
				guid = item.guid;
			end
		end
		if(nid and guid) then
			local msg = paraworld.homeland.petevolved.get_get_inlocalserver(nid, guid);
			if(msg) then
				value2 = msg[type];
				if(msg.energy <= 0 and bHideIfNotVIP == true) then
					value2 = "";
				end
			end
		end
	end
	
	-- default to "0";
	value2 = value2 or "";
	
	mcmlNode:SetInnerText(tostring(value2));
	--mcmlNode:SetValue(tostring(value2));
	-- create the background part as an <label> tag
	Map3DSystem.mcml_controls.pe_label.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout);
end
local function gsid_to_schoolimg(gsid)
	local school = "";
	if(gsid == 986) then
		school = "Texture/Aries/Team/fire_32bits.png" --"烈火";
	elseif(gsid == 987) then
		school = "Texture/Aries/Team/ice_32bits.png"--"寒冰";
	elseif(gsid == 988) then
		school = "Texture/Aries/Team/storm_32bits.png" --"风暴";
	elseif(gsid == 989) then
		school = "Texture/Aries/Team/myth_32bits.png" -- "神秘系";
	elseif(gsid == 990) then
		school = "Texture/Aries/Team/life_32bits.png" --"生命";
	elseif(gsid == 991) then
		school = "Texture/Aries/Team/death_32bits.png"--"死亡";
	elseif(gsid == 992) then
		school = "Texture/Aries/Team/balance_32bits.png" -- "平衡系";
	end
	return school;
end
local function gsid_to_schoolname(gsid)
	-- 986_CombatSchool_Fire
	-- 987_CombatSchool_Ice
	-- 988_CombatSchool_Storm
	-- 989_CombatSchool_Myth
	-- 990_CombatSchool_Life
	-- 991_CombatSchool_Death
	-- 992_CombatSchool_Balance
	local school = "风暴";
	if(gsid == 986) then
		school = "烈火";
	elseif(gsid == 987) then
		school = "寒冰";
	elseif(gsid == 988) then
		school = "风暴";
	--elseif(gsid == 989) then
		--school = "神秘系";
	elseif(gsid == 990) then
		school = "生命";
	elseif(gsid == 991) then
		school = "死亡";
	--elseif(gsid == 992) then
		--school = "平衡系";
	end
	return school;
end

-------------------------------------
---- aries:mountpet-combatschool control
-------------------------------------
local aries_mountpet_combatschool = commonlib.gettable("MyCompany.Aries.mcml_controls.aries_mountpet_combatschool");

-- aries mount pet level object
function aries_mountpet_combatschool.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local nid = mcmlNode:GetAttributeWithCode("nid",nil,true);
	local is_img = mcmlNode:GetAttributeWithCode("is_img");
	if(is_img == "true" or is_img == "True")then
		is_img = true;
	else
		is_img = false;
	end
	if(nid == "loggedinuser") then
		-- get current user nid as the nid
		nid = Map3DSystem.App.profiles.ProfileManager.GetNID();
	end
	nid = tonumber(nid);
	if(nid == nil) then
		log("error: must specify nid or \"loggedinuser\" for aries:mountpet-level MCML tag\n");
		return;
	end
	
	local value = mcmlNode:GetAttributeWithCode("value");
	if(value == nil) then
		local bLocalVersion = true;
		local function GetCombatSchool(gsid)
			local school = gsid_to_schoolname(gsid).."系";

			local pageCtrl = mcmlNode:GetPageCtrl();
			if(pageCtrl) then
				if(is_img)then
					school = gsid_to_schoolimg(gsid);
					mcmlNode:SetAttribute("src", school)
				else	
					-- needs to refresh for newly fetched version.
					mcmlNode:SetAttribute("value", school)
				end
				if(not bLocalVersion) then
					pageCtrl:Refresh(0.01);
				end	
			end
		end
		
		if(nid == Map3DSystem.App.profiles.ProfileManager.GetNID()) then
			-- combat school integrate in user and dragon info
			local school_gsid = Combat.GetSchoolGSID();
			if(school_gsid and school_gsid > 0) then
				GetCombatSchool(school_gsid);
			else
				log("error: not valid guid for nid:"..nid.."in aries:mountpet-combatschool\n");
				return;
			end
		else
			Map3DSystem.App.profiles.ProfileManager.GetUserInfo(nid, "aries:mountpet_combatschool_"..tostring(nid), function(msg)
				-- combat school integrate in user and dragon info
				local school_gsid = Combat.GetSchoolGSID(nid);
				if(school_gsid and school_gsid > 0) then
					GetCombatSchool(school_gsid);
				else
					log("error: not valid guid for nid:"..nid.."in aries:mountpet-combatschool\n");
					return;
				end
			end, "access plus 10 minutes");
		end
		bLocalVersion = false;
	end
	local school_gsid;
	-- render the data directly in local server
	if(value == nil) then
		school_gsid = Combat.GetSchoolGSID(nid);
		if(school_gsid and school_gsid > 0) then
			value = gsid_to_schoolname(school_gsid).."系";
		end
	end
	
	-- default to 0;
	value = value or "";
	
	
	if(is_img)then
		local icon = gsid_to_schoolimg(school_gsid);
		mcmlNode:SetAttribute("src", icon);
		mcmlNode:SetAttribute("tooltip", value);
		-- create as an <img> tag
		Map3DSystem.mcml_controls.pe_img.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout);
	else
		mcmlNode:SetInnerText(tostring(value));
		--mcmlNode:SetValue(tostring(value2));
		-- create the background part as an <label> tag
		Map3DSystem.mcml_controls.pe_label.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout);
	end
	do return end

	local allowtooltip = mcmlNode:GetAttributeWithCode("allowtooltip");
	if(allowtooltip) then
		mcmlNode:SetAttribute("tooltip", "等级:"..value);
		mcmlNode:SetAttribute("alwaysmouseover", true);
	end
	-- create the background part as an <img> tag
	Map3DSystem.mcml_controls.pe_img.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout);
	
	local node = Map3DSystem.mcml.new(nil, {name = "aries:textsprite"});
	node:SetAttribute("text", value);
	node:SetAttribute("spritestyle", "DragonLevel");
	node:SetAttribute("color", "");
	node:SetAttribute("fontsize", "26");
	local allowtooltip = mcmlNode:GetAttributeWithCode("allowtooltip");
	if(allowtooltip) then
		node:SetAttribute("tooltip", "等级:"..value);
	end
	mcmlNode:AddChild(node, nil);
	local level_number_margin_left = 14;
	if(value < 10) then
		level_number_margin_left = 23;
	elseif(value < 20) then
		level_number_margin_left = 16;
	else
		level_number_margin_left = 14;
	end
	local level_number_margin_top = 16;
	-- create the text part as an <aries:textsprite> tag
	local myLayout = Map3DSystem.mcml_controls.layout:new();
	myLayout:reset(left + level_number_margin_left, top + level_number_margin_top, width, height);
	Map3DSystem.mcml_controls.create(rootName, node, bindingContext, _parent, left, top, width, height, nil, myLayout);
end


-------------------------------------
---- aries:vip-sign control
-------------------------------------
local aries_vip_sign = commonlib.gettable("MyCompany.Aries.mcml_controls.aries_vip_sign");

local default_vip_sign = "Texture/Aries/Dock/Web/magic_star_32bits.png";
-- aries mount pet health object
function aries_vip_sign.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local nid = mcmlNode:GetAttributeWithCode("nid",nil,true);
	if(nid == "loggedinuser") then
		-- get current user nid as the nid
		nid = Map3DSystem.App.profiles.ProfileManager.GetNID();
	end
	nid = tonumber(nid);
	if(nid == nil) then
		log("error: must specify nid or \"loggedinuser\" for aries:mountpet-health MCML tag\n");
		return;
	end
	
	local value = mcmlNode:GetAttributeWithCode("value"); 
	if(value == nil) then
		local bLocalVersion = true;
		local function GetPetHealth(nid, guid)
			local msg = {
				nid = nid,
				id = guid,
			};
			paraworld.homeland.petevolved.Get(msg, nil, function(msg)
				if(msg and msg.energy) then
					local energy;
					if(CommonClientService.IsTeenVersion())then
						energy = msg.mlel;
					else
						energy = msg.energy;
					end
					local function AutoRefresh(newValue)
						if(newValue and newValue ~= value) then
							-- only refresh if value is different from last
							value = newValue;
							
							local pageCtrl = mcmlNode:GetPageCtrl();
							if(pageCtrl) then
								-- needs to refresh for newly fetched version.
								mcmlNode:SetAttribute("value", value)
								if(not bLocalVersion) then
									pageCtrl:Refresh(0.1);
								end	
							end
						end
					end
					
					AutoRefresh(energy);
				end	
			end, "access plus 5 minutes");
		end
		
		if(nid == Map3DSystem.App.profiles.ProfileManager.GetNID()) then
			local item = ItemManager.GetMyMountPetItem();
			if(item and item.guid > 0) then
				GetPetHealth(nid, item.guid);
			else
				log("error: not valid guid for nid:"..nid.."in aries:vip_sign\n");
				return;
			end
		else
			ItemManager.GetItemsInOPCBag(nid, 0, "aries:vip_sign_"..nid, function(msg)
				local item = ItemManager.GetOPCMountPetItem(nid);
				if(item and item.guid > 0) then
					GetPetHealth(nid, item.guid);
				else
					log("error: not valid guid for nid:"..nid.."in aries:vip_sign\n");
					return;
				end
			end, "access plus 1 hour");
		end
		bLocalVersion = false;
	end
	
	-- render the data directly in local server
	if(value == nil) then
		local guid;
		if(nid == Map3DSystem.App.profiles.ProfileManager.GetNID()) then
			local item = ItemManager.GetMyMountPetItem();
			if(item and item.guid > 0) then
				guid = item.guid;
			end
		else
			local item = ItemManager.GetOPCMountPetItem(nid);
			if(item and item.guid > 0) then
				guid = item.guid;
			end
		end
		if(nid and guid) then
			local msg = paraworld.homeland.petevolved.get_get_inlocalserver(nid, guid);
			if(msg) then
				if(CommonClientService.IsTeenVersion())then
					value = msg.mlel;
				else
					value = msg.energy;
				end
			end
		end
	end
	
	local src = "";
	if(value and tonumber(value)) then
		if(tonumber(value) > 0) then
			src = mcmlNode:GetAttributeWithCode("vip_icon") or default_vip_sign;
		else
			src = mcmlNode:GetAttributeWithCode("vip_icon_gray") or "";
		end
	end
	--local tooltip = "";
	--tooltip = "健康";
	
	--local allowtooltip = mcmlNode:GetBool("allowtooltip", false);
	--if(allowtooltip) then
		--mcmlNode:SetAttribute("tooltip", tooltip);
	--end
	mcmlNode:SetAttribute("src", src);
	-- create as an <img> tag
	Map3DSystem.mcml_controls.pe_img.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout);
end
-------------------------------------
---- aries:statslabel control
-------------------------------------
local aries_statslabel = commonlib.gettable("MyCompany.Aries.mcml_controls.aries_statslabel");
aries_statslabel.stat_template_map = {
	[101] = "HP",
	[102] = "超魔生成率",
	[103] = "通用命中",
	[111] = "通用伤害",
	[119] = "通用防御",
	[118] = "闪避",
	[196] = "暴击",
	[204] = "韧性",
	[212] = "穿透",
	[220] = "敏捷",
}
function aries_statslabel.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	
	if(System.options.version == "teen") then
		aries_statslabel.stat_template_map[102] = "双倍魔力生成率";
	end

	local gsid = mcmlNode:GetAttributeWithCode("gsid",nil,true);
	gsid = tonumber(gsid);
	if(not gsid)then
		return
	end
	
	local showstyle = mcmlNode:GetNumber("showstyle") or 1;
	local title = mcmlNode:GetString("title");
	local stat = mcmlNode:GetNumber("stat");
	if(not stat)then
		return
	end
	title = title or aries_statslabel.stat_template_map[stat];
	local value = 0;
	local gsItem = ItemManager.GetGlobalStoreItemInMemory(gsid);
	if(gsItem)then
		value = gsItem.template.stats[stat] or 0;
	end
	local s;
	--格式 HP:+139
	if(showstyle == 1)then
		s = string.format("%s:+%d",title,value);
	--格式 敏捷:+1%
	elseif(showstyle == 2)then
		s = string.format("%s:%d%%",title,value);
	--格式 +1%
	elseif(showstyle == 3)then
		s = string.format("+%d%%",value);
	--格式 +1
	elseif(showstyle == 4)then
		s = string.format("+%d",value);
	end
	mcmlNode:SetInnerText(s);
	Map3DSystem.mcml_controls.pe_label.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout);
end