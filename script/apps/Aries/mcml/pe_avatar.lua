--[[
Title: avatar tag control(override the default mcml avatar tag)
Author(s): WangTian
Date: 2008/3/10
Revised: 2008/3/21 LiXizhi 2008/4/3 LiXizhi (fully implemented with MCML functions)
Desc: pe:avatar is used to render the 3d avatar of a given user or just any avatar. 
one can use mouse to rotate and scale the avatar. The inner node of pe:avatar is rendered inside the avatar window.  
<verbatim>
	<pe:avatar uid = "loggedinuser" style="width:256px;height:256px;"/>
	<pe:avatar uid = "loggedinuser" name="avatar" style="width:256px;height:256px;padding:5px">
		<pe:if-is-user uid="loggedinuser">
			<a type="button" onclick="Map3DSystem.App.CCS.AvatarRegPage.TakeAvatarSnapshot">快照</a>
		</pe:if-is-user>
	</pe:avatar>
</verbatim>

| *property* | *desc*|
| RenderTargetSize | default to 256 | 
| miniscenegraphname| default to pe:name | 
| IsActiveRendering | default to true| 
| IsInteractive | whether it will receive and responds to mouse event | 
| autoRotateSpeed | how many degrees (in radian) to rotate around the Y axis per second. if nil or 0 it will not rotate. common values are 0.12 | 
| MaskTexture | mini scene mask texture |

| *method*		| *description* | 
| TakeSnapshot  | take a snapshot of the current avatar. |

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/mcml/pe_avatar.lua");
local pe_avatar = commonlib.gettable("MyCompany.Aries.mcml_controls.pe_avatar");
pe_player.GetCCSParams(nid_number, "self", function(params)
	if(params) then
		pe_player.ApplyCCSParamsToChar(para_obj, params);
	end
end)
-------------------------------------------------------
]]
local string_find = string.find;

NPL.load("(gl)script/kids/3DMapSystemItem/ItemManager.lua");
local ItemManager = commonlib.gettable("Map3DSystem.Item.ItemManager");
local Player = commonlib.gettable("MyCompany.Aries.Player");
local Pet = commonlib.gettable("MyCompany.Aries.Pet");

if(not Map3DSystem.mcml_controls) then Map3DSystem.mcml_controls = {} end

-----------------------------------
-- pe:avatar control
-----------------------------------
local pe_avatar = commonlib.gettable("MyCompany.Aries.mcml_controls.pe_avatar");

function pe_avatar.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	
	local uid = mcmlNode:GetAttributeWithCode("uid");
	
	if(uid == "loggedinuser") then
		-- get current user ID as the uid
		uid = System.User.nid;
	end
	if(uid == nil) then
		log("error: must specify uid or \"loggedinuser\" for pe:avatar MCML tag\n");
		return;
	end
	
	local left, top, width, height = parentLayout:GetPreferredRect();
	
	local css = mcmlNode:GetStyle(Map3DSystem.mcml_controls.pe_html.css["pe:filebrowser"], style) or {};
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
	
	local IsFacePortrait = mcmlNode:GetBool("IsFacePortrait")
	if(IsFacePortrait == nil) then
		IsFacePortrait = false;
	end
	
	-- create the 3d canvas for avatar display
	local instName = mcmlNode:GetInstanceName(rootName);
	NPL.load("(gl)script/ide/Canvas3D.lua");
	local ctl = CommonCtrl.Canvas3D:new{
		name = instName,
		alignment = "_lt",
		left = left,
		top = top,
		width = width - left,
		height = height - top,
		background = mcmlNode:GetString("background") or css.background,
		parent = _parent,
		IsActiveRendering = IsActiveRendering,
		miniscenegraphname = mcmlNode:GetAttributeWithCode("miniscenegraphname") or "pe:name",
		RenderTargetSize = mcmlNode:GetNumber("RenderTargetSize") or 256,
		IsInteractive = IsInteractive,
		autoRotateSpeed = autoRotateSpeed,
	};
	ctl:Show();
	
	------------------------------------
	-- load avatar information
	------------------------------------
	local assetName;
	local appearanceInfo;
	
	-- TODO 2008.4.3: while we are retrieving information from server, shall we display a waiting animation in 3d HERE?
	--ctl:ShowModel({
			--["IsCharacter"] = true,
			--["y"] = 0,
			--["x"] = 0,
			--["facing"] = -1.57,
			--["name"] = "pe:avatar",
			--["z"] = 0,
			--["AssetFile"] = "character/common/headquest/headquest.x",
			--["CCSInfoStr"] = nil,
		--});
	
	--					
	-- get avatar information from uid
	--
	
	-- TODO: accept both nid and uid
	--- just in case it is an nid
	Map3DSystem.App.profiles.ProfileManager.GetUserInfo(uid, "pe:avatar_"..tostring(uid), function(msg)
		if(msg and msg.users and msg.users[1]) then
			local user = msg.users[1];
			local userid = user.userid;
			
			Map3DSystem.App.profiles.ProfileManager.GetMCML(userid, Map3DSystem.App.appkeys["CCS"], 
			function(uid, app_key, bSucceed, profile)
				if(profile and profile.CharParams and profile.CharParams.AssetFile) then
					if(ctl) then
						ctl:ShowModel({
							["IsCharacter"] = true,
							["y"] = 0,
							["x"] = 0,
							["facing"] = -1.57,
							["name"] = "pe:avatar",
							["z"] = 0,
							["AssetFile"] = profile.CharParams.AssetFile,
							["CCSInfoStr"] = profile.CharParams.CCSInfoStr,
						});
					end
				else
					ctl:ShowModel({
							["IsCharacter"] = true,
							["y"] = 0,
							["x"] = 0,
							["facing"] = -1.57,
							["name"] = "pe:avatar",
							["z"] = 0,
							["AssetFile"] = "character/common/headquest/headquest.x",
							["CCSInfoStr"] = nil,
						});
				end
				
				--[[if(profile) then
					-- set the camera position to take portait view of avatar
					if(IsPortrait == true) then
						-- TODO: get the portait shot camera setting from the character or model asset description
						-- take the portrait shot of the avatar
						if(profile.CharParams.AssetFile == "character/v3/Human/Male/HumanMale.xml") then
							ctl:CameraSetLookAtPos(0, 1.4654281139374, 0);
							ctl:CameraSetEyePosByAngle(2.7281620502472, 0.31596618890762, 2.5371053218842);
						end
						if(profile.CharParams.AssetFile == "character/v3/Human/Female/HumanFemale.xml") then
							ctl:CameraSetLookAtPos(0, 1.4654281139374, 0);
							ctl:CameraSetEyePosByAngle(2.7281620502472, 0.31596618890762, 2.5371053218842);
						end
						if(string_find(profile.CharParams.AssetFile, "can")) then
							ctl:CameraSetLookAtPos(0, 0.9654281139374, 0);
							ctl:CameraSetEyePosByAngle(2.7281620502472, 0.31596618890762, 3.5371053218842);
						end
						ctl:ShowModel({
							["IsCharacter"] = true,
							["y"] = 0,
							["x"] = 0,
							["facing"] = 0,
							["name"] = "pe:avatar",
							["z"] = 0,
							["AssetFile"] = profile.CharParams.AssetFile,
							["CCSInfoStr"] = profile.CharParams.CCSInfoStr,
						});
						if(string_find(profile.CharParams.AssetFile, "ElfFemale.xml")) then
							ctl:CameraSetLookAtPos(0, 0.75053763389587, 0);
							ctl:CameraSetEyePosByAngle(-1.6270221471786, 0.10000000149012, 3.0698845386505);
						end
					elseif(IsFacePortrait == true) then
						-- TODO: get the portait shot camera setting from the character or model asset description
						-- take the portrait shot of the avatar
						ctl:ShowModel({
							["IsCharacter"] = true,
							["y"] = 0,
							["x"] = 0,
							["facing"] = 0,
							["name"] = "pe:avatar",
							["z"] = 0,
							["AssetFile"] = profile.CharParams.AssetFile,
							["CCSInfoStr"] = profile.CharParams.CCSInfoStr,
						});
						if(string_find(profile.CharParams.AssetFile, "ElfFemale.xml")) then
							ctl:CameraSetLookAtPos(0, 0.90813940763474, -0.01);
							ctl:CameraSetEyePosByAngle(-1.5990210771561, 0.10000523924828, 1.7753294229507);
						end
					end
				end]]
				-- set the mask texture
				local MaskTexture = mcmlNode:GetAttributeWithCode("MaskTexture")
				if(MaskTexture ~= nil and MaskTexture ~= "") then
					ctl:SetMaskTexture(MaskTexture);
				end
			end)
		end
	end);
	
	-- if user is current user, display some buttons. 
	if(uid == Map3DSystem.App.profiles.ProfileManager.GetUserID()) then
		-- TODO:
	end
	
	-- create inner child if any . 
	if(myLayout) then
		local childnode;
		for childnode in mcmlNode:next() do
			local left, top, width, height = myLayout:GetPreferredRect();
			Map3DSystem.mcml_controls.create(rootName, childnode, bindingContext, _parent, left, top, width, height, nil, myLayout)
		end
	end
end

-- take a snapshot
-- @param filename: where to save the snap shot. default to "Screen Shots/pe_avatar_snapshot.png" 
--  we support ".dds", ".jpg", ".png" files. If the file extension is not recognized, ".png" file is used. 
-- @param nImageSize: if this is nil or zero, the original size is used. If it is dds, all mip map levels are saved.
function pe_avatar.TakeSnapshot(mcmlNode, pageInstName, filename, nImageSize)
	filename = filename or "Screen Shots/pe_avatar_snapshot.png";
	nImageSize = nImageSize or 0;
	local ctl = mcmlNode:GetControl(pageInstName);
	if(ctl and ctl.SaveToFile) then
		return ctl:SaveToFile(filename, nImageSize);
	end
end


-- pe:player is an Aries specified control that will read local visualized characters first and then fetch from item system information

-----------------------------------
-- pe:player control
-----------------------------------
local pe_player = commonlib.gettable("MyCompany.Aries.mcml_controls.pe_player");

-- mapping from camera name to camera settings. 

local CamSetting = {
	ElfFemale = {
		LookAt = {0, 0.75700056552887, 0},
		EyePos = {3.1121213436127, 0.10053723305464, 3.3980791568756},
	},
	ElfFemaleHead = {
		LookAt = {0, 1, 0},
		EyePos = {3.1121213436127, 0.10053723305464, 2.6},
	},
	ElfFemaleFreezed = {
		LookAt = {0, 0.82573479413986, 0},
		EyePos = {3.36399102211, 0.35200002789497, 3.8270018100739},
	},
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
	MysteryAcinusTree = {
		LookAt = {0, 1.3436055898666, 0},
		EyePos = {-1.3432075977325, 0.28798785805702, 10.3661255836487},
	},
	DragonTotem = {
		LookAt = {0, 3.9842195987701, 0},
		EyePos = {1.0959913730621, 0.28399962186813, 72.633911132813},
	},
	DragonBaby = {
		LookAt = {0, 0.84263616800308, 0},
		EyePos = {2.5885643959045, 0.099945321679115, 6.2741990089417},
	},
};

if(pe_player.CamSetting) then
	local name, value 
	for name, value in pairs(CamSetting) do
		pe_player.CamSetting[name] = pe_player.CamSetting[name] or value;
	end
else
	pe_player.CamSetting = CamSetting;
end

-- mapping from asset string to camera name
local CameraNameByAssetMap = {
["TeenElfFemale"] = "ElfFemale",
["TeenElfMale"] = "ElfFemale",
["ElfFemale"] = "ElfFemale",
["ElfFemaleFreezed"] = "ElfFemaleFreezed",
["PurpleDragonMajor"] = "PurpleDragonMajor",
["PurpleDragonMinor"] = "PurpleDragonMinor",
["PurpleDragonEgg"] = "PurpleDragonEgg",
["MysteryAcinusTree"] = "MysteryAcinusTree",
["DragonTotem"] = "DragonTotem",
["DragonBaby"] = "DragonBaby",
}

local function GetFacialInfoStringFromEquips(facial_plus_cartoonface)
	if(type(facial_plus_cartoonface) == "string") then
		local facial, cartoonface = string.match(facial_plus_cartoonface, "^([^@]-)@([^@]-)@$");
		if(facial and cartoonface) then
			return facial;
		end
	end
	return "0#1#0#1#1#";
end
local function GetCartoonfaceInfoStringFromEquips(facial_plus_cartoonface)
	if(type(facial_plus_cartoonface) == "string") then
		local facial, cartoonface = string.match(facial_plus_cartoonface, "^([^@]-)@([^@]-)@$");
		if(facial and cartoonface) then
			return cartoonface;
		end
	end
	return "0#F#0#0#0#0#0#F#0#0#0#0#0#F#0#0#0#0#0#F#0#0#0#0#0#F#0#0#0#0#0#F#0#0#0#0#0#F#0#0#0#0#";
end

local function GetTeenGSID(gsid, isFemale)
	if(gsid <= 0) then
		return 0;
	end
	local isUniSex = false;
	local gsItem = ItemManager.GetGlobalStoreItemInMemory(gsid)
	if(gsItem) then
		-- 187 is_unisex_teen(C)
		if(gsItem.template.stats[187] == 1) then
			isUniSex = true;
		end
	end
	if(isUniSex == true) then
		gsid = gsid + 30000;
	else
		if(isFemale) then
			gsid = gsid + 40000;
		else
			gsid = gsid + 30000;
		end
	end
	return gsid;
end

local need_replace_equip_positions = {2,5,7,8};

local function GetCharacterSlotInfoStringFromEquips(equips, object)
	--"0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#1008#1009#1003#1010#1021#0#0#0#0#0#";
	if(object == "self") then
		if(System.options.version == "teen") then
			local isFemale = false;
			if(equips[25] == 982) then
				isFemale = true;
			end
			return GetTeenGSID(equips[2], isFemale).."#0#0#0#0#0#0#0#0#0#"..GetTeenGSID(equips[11], isFemale).."#"..GetTeenGSID(equips[10], isFemale).."#0#0#"..GetTeenGSID(equips[1], isFemale).."#0#"..GetTeenGSID(equips[5], isFemale).."#"..GetTeenGSID(equips[6], isFemale).."#"..GetTeenGSID(equips[9], isFemale).."#"..GetTeenGSID(equips[7], isFemale).."#"..GetTeenGSID(equips[4], isFemale).."#"..GetTeenGSID(equips[8], isFemale).."#0#0#0#0#";
		else
			local i;
			local replace_equips = {};
			commonlib.mincopy(replace_equips, equips);
			for i = 1,#need_replace_equip_positions do
				local position = need_replace_equip_positions[i];
				if(replace_equips[position]) then
					local gsid = replace_equips[position];
					local gsItem = ItemManager.GetGlobalStoreItemInMemory(gsid)
					if(gsItem) then
						-- Replacement_GSID
						local replacement_gsid = gsItem.template.stats[53];
						if(replacement_gsid) then
							replace_equips[position] = replacement_gsid;
						end
					end
				end
			end
			return replace_equips[2].."#0#0#0#0#0#0#0#0#0#"..replace_equips[11].."#"..replace_equips[10].."#0#0#"..replace_equips[1].."#0#"..replace_equips[5].."#"..replace_equips[6].."#"..replace_equips[9].."#"..replace_equips[7].."#"..replace_equips[4].."#"..replace_equips[8].."#0#0#0#0#";
		end
	elseif(object == "mount") then
		return "0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#"..equips[41].."#"..equips[42].."#"..equips[43].."#"..equips[44].."#";
	elseif(object == "follow") then
		return "";
	end
end

-- get ccs params of a given nid. 
-- @param nid: number or string, where number is preferred. if nil it is current player
-- @param object: "self", "follow", "mount"
-- @param func_callback: function(params)  end
function pe_player.GetCCSParams(nid, object, func_callback)
	nid = tonumber(nid or System.User.nid);
	object = object or "self";
	Map3DSystem.Item.ItemManager.GetEquips(nid, function(msg)
		if(msg and msg.equips and msg.equips[1] and msg.equips[1].gsids) then
			local equips = {};
			local i;
			for i = 1, 44 do
				equips[i] = 0;
			end
			local equipstr = msg.equips[1].gsids;
			local gsid;
			local i = 0;
			for gsid in string.gmatch(equipstr, "[^,]+") do
				i = i + 1;
				equips[i] = tonumber(gsid);
			end
			local assetfile;
			local replaceable_r1;

			if(object == "self") then
				assetfile = Player.GetAvaterAssetFileByID(equips[25]);
			elseif(object == "mount") then
				local gsid = equips[31];
				if(gsid ~= 0) then
					if(nid == Map3DSystem.App.profiles.ProfileManager.GetNID()) then
						-- check if the mount pet is at home
						local item
						if(nid == System.App.profiles.ProfileManager.GetNID()) then
							-- my mount
							local ItemManager = System.Item.ItemManager;
							item = ItemManager.GetMyMountPetItem();
						else
							-- OPC mount
							item = ItemManager.GetOPCMountPetItem(nid);
						end
						if(item and item.guid > 0 and (System.options.version=="kids")) then
						
							gsid = item.gsid;
							local mountPetStage = item:GetAssetFileIndex();
							assetfile = ItemManager.GetAssetFileFromGSIDAndIndex(item.gsid, item:GetAssetFileIndex());
							local basecolor_gsid = equips[40];

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
								end
							elseif(mountPetStage == 3) then -- major
								if(basecolor_gsid == 11009) then
									replaceable_r1 = "character/v3/PurpleDragonMajor/Female/SkinColor01.dds";
								elseif(basecolor_gsid == 11010) then
									replaceable_r1 = "character/v3/PurpleDragonMajor/Female/SkinColor02.dds";
								elseif(basecolor_gsid == 11011) then
									replaceable_r1 = "character/v3/PurpleDragonMajor/Female/SkinColor03.dds";
								elseif(basecolor_gsid == 11012) then
									replaceable_r1 = "character/v3/PurpleDragonMajor/Female/SkinColor04.dds";
								end
							end
						else
							return;
						end
					else
						return;
					end
				end
			elseif(object == "follow") then
				local gsid = equips[32];
				if(gsid == 0) then
					return
				end
				local gsItem = ItemManager.GetGlobalStoreItemInMemory(gsid)
				if(gsItem) then
					assetfile = gsItem.assetfile;
				end
			end

			-- get ccs string
			local facial_info_string = GetFacialInfoStringFromEquips(equips);
			local cartoonface_info_string = GetCartoonfaceInfoStringFromEquips(equips);
			local characterslot_info_string = GetCharacterSlotInfoStringFromEquips(equips, object);

			if(func_callback) then
				func_callback({facial_info_string=facial_info_string, cartoonface_info_string=cartoonface_info_string, characterslot_info_string=characterslot_info_string, replaceable_r1=replaceable_r1, assetfile=assetfile});
			end
		else
			if(func_callback) then
				func_callback();
			end
		end
	end);
end

-- Apply CCS params to character
-- @param obj: the ParaObject of the character
function pe_player.ApplyCCSParamsToChar(obj, params)
	if(not params) then return end
	if(params.assetfile and obj:GetPrimaryAsset():GetKeyName()~= params.assetfile) then
		local asset = ParaAsset.LoadParaX("", params.assetfile);
		obj:ToCharacter():ResetBaseModel(asset);
	end

	if(params.replaceable_r1) then
		obj:SetReplaceableTexture(1, ParaAsset.LoadTexture("", params.replaceable_r1, 1));
	end
	if(obj:ToCharacter():IsCustomModel() == true) then
		local facial_info_string = params.facial_info_string;
		local cartoonface_info_string = params.cartoonface_info_string;
		local characterslot_info_string = params.characterslot_info_string;
		Map3DSystem.UI.CCS.Predefined.ApplyFacialInfoString(obj, facial_info_string);
		Map3DSystem.UI.CCS.DB.ApplyCartoonfaceInfoString(obj, cartoonface_info_string);


		local sInfo = characterslot_info_string;

		local playerChar;
		-- get player character
		if(obj ~= nil and obj:IsValid() == true) then
			if(obj:IsCharacter() == true) then
				playerChar = obj:ToCharacter();
			end
		end
		if( playerChar ~= nil and playerChar:IsCustomModel() == true ) then
		
			local slot = 0;
			local itemID;
			for itemID in string.gfind(sInfo, "([^#]+)") do
									
				local gsid = tonumber(itemID);

				if(gsid) then
					if(slot == 21) then
						local gsItem = ItemManager.GetGlobalStoreItemInMemory(gsid);
						if(gsItem) then
							-- reset the base model to mount pet asset
							local bForceAttBack = gsItem.template.stats[13];
							if(bForceAttBack == 1) then
								slot = 26; -- CS_BACK 
								playerChar:SetCharacterSlot(21, 0);
							else
								slot = 21; -- CS_ARIES_CHAR_GLASS 
								playerChar:SetCharacterSlot(26, 0);
							end
						end
					end
									
					playerChar:SetCharacterSlot(slot, gsid);
				end

				slot = slot + 1;
			end
		else
			--log("error: attempt to set a non character ccs information or non custom character.\n");
		end
	end
						
	-- NOTE 2010/8/30: for all characters with hat, hide the hair, hair is included in the hat model
	if(obj:ToCharacter():GetCharacterSlotItemID(0) > 1) then -- IT_Head
		obj:ToCharacter():SetBodyParams(-1, -1, 0, 0, -1); -- int hairColor, int hairStyle
	end
end

-- TODO: this is just a temparory tag for offline mode
function pe_player.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	-- get user nid
	local nid = mcmlNode:GetAttributeWithCode("nid",nil,true);
	if(nid == "loggedinuser") then
		-- get current user ID as the uid
		nid = Map3DSystem.App.profiles.ProfileManager.GetNID();
	end
	nid = tonumber(nid);
	if(nid == nil) then
		log("error: must specify nid or \"loggedinuser\" for pe:player MCML tag\n");
		return;
	end
	-- get display object
	local object = mcmlNode:GetAttributeWithCode("object");
	if(not object) then
		object = "self";
	end
	
	---- NOTE by Andy: why object = "npc" can pass the condition
	--if(object ~= "self" or object ~= "mount" or object ~= "follow" or object ~= "npc") then
		--object = "self";
	--end
	
	local left, top, width, height = parentLayout:GetPreferredRect();
	
	local css = mcmlNode:GetStyle(Map3DSystem.mcml_controls.pe_html.css["pe:player"], style) or {};
	local padding_left, padding_top, padding_bottom, padding_right = 
		(css["padding-left"] or css["padding"] or 0),(css["padding-top"] or css["padding"] or 0),
		(css["padding-bottom"] or css["padding"] or 0),(css["padding-right"] or css["padding"] or 0);
	local margin_left, margin_top, margin_bottom, margin_right = 
			(css["margin-left"] or css["margin"] or 0),(css["margin-top"] or css["margin"] or 0),
			(css["margin-bottom"] or css["margin"] or 0),(css["margin-right"] or css["margin"] or 0);	
	if(css.width) then
		if((left + css.width)<width) then
			parentLayout:NewLine();
			left, top, width, height = parentLayout:GetPreferredRect();
		end
		width = left + css.width + margin_left + margin_right
	end
	if(css.height) then
		height = top + css.height + margin_top  + margin_bottom
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
	
	local miniSceneName = mcmlNode:GetAttributeWithCode("miniscenegraphname") or "pe:player"..ParaGlobal.GenerateUniqueID();
	
	-- create the 3d canvas for avatar display
	local instName = mcmlNode:GetInstanceName(rootName);
	NPL.load("(gl)script/ide/Canvas3D.lua");
	local ctl = CommonCtrl.Canvas3D:new{
		name = instName.."_player",
		alignment = "_lt",
		left = left,
		top = top,
		width = width - left,
		height = height - top,
		background = mcmlNode:GetString("background") or css.background,
		parent = _parent,
		IsActiveRendering = IsActiveRendering,
		miniscenegraphname = miniSceneName,
		DefaultRotY = mcmlNode:GetNumber("DefaultRotY"),
		RenderTargetSize = mcmlNode:GetNumber("RenderTargetSize") or 256,
		IsInteractive = IsInteractive,
		autoRotateSpeed = autoRotateSpeed,
	};
	ctl:Show(true);
	
	Map3DSystem.mcml_controls.pe_player_all = Map3DSystem.mcml_controls.pe_player_all or {};
	--table.insert(Map3DSystem.mcml_controls.pe_player_all, instName.."_player")
	Map3DSystem.mcml_controls.pe_player_all[instName.."_player"] = miniSceneName;
	
	if(not commonlib.getfield("MyCompany.Aries")) then
		log("error: call pe:player outside the Aries project\n");
		return;
	end
	
	local Pet = MyCompany.Aries.Pet;
	local Quest = MyCompany.Aries.Quest;
	local player;
	local char_asset, mesh_asset, player_name;
	if(object == "self") then
		player = Pet.GetUserCharacterObj(nid);
		if(player and player:GetPrimaryAsset():GetKeyName() == "") then
			player = nil;
		end
	elseif(object == "mount") then
		player = Pet.GetUserMountObj(nid);
	elseif(object == "follow") then
		player = Pet.GetUserFollowObj(nid);
	elseif(object == "homelandpet") then
		local guid = mcmlNode:GetAttributeWithCode("guid");
		if(guid) then
			guid = tonumber(guid);
			if(nid == Map3DSystem.App.profiles.ProfileManager.GetNID()) then
				local name;
				local ItemManager = System.Item.ItemManager;
				local item = ItemManager.GetItemByGUID(guid);
				if(item and item.guid > 0 and item.GetSceneObjectNameInHomeland) then
					name = item:GetSceneObjectNameInHomeland();
				end
				if(name) then
					local obj = ParaScene.GetCharacter(name);
					if(obj:IsValid() == true) then
						player = obj;
					end
				end
			else
				local name;
				local ItemManager = System.Item.ItemManager;
				local item = ItemManager.GetOPCItemByGUID(nid, guid);
				if(item and item.guid > 0 and item.GetSceneObjectNameInHomeland) then
					name = item:GetSceneObjectNameInHomeland();
				end
				if(name) then
					local obj = ParaScene.GetCharacter(name);
					if(obj:IsValid() == true) then
						player = obj;
					end
				end
			end
		end
	elseif(object == "npc") then
		-- if npc object, nid means the npc_id
		local instance = mcmlNode:GetAttributeWithCode("instance");
		if(instance) then
			instance = tonumber(instance);
			-- singleton npc
			if(instance == 0) then
				instance = nil;
			end
		end
		
		player = Quest.NPC.GetNpcCharacterFromIDAndInstance(nid, instance);
		if(player) then
			if(string_find(player:GetPrimaryAsset():GetKeyName(), "character/common/dummy/")) then
				local model = Quest.NPC.GetNpcModelFromIDAndInstance(nid, instance)
				player = model;
			end
		end
		
		if(not player) then
			local NPCList = commonlib.gettable("MyCompany.Aries.Quest.NPCList");
			local npc_data = NPCList.GetNPCByID(nid);
			if(npc_data) then
				player_name = npc_data.name or "";
				if(not npc_data.skiprender_char) then
					char_asset = npc_data.assetfile_char;
				elseif(not npc_data.skiprender_mesh) then
					mesh_asset = npc_data.assetfile_model 
				end
			end
		end

	elseif(object == "gameobject") then
		-- if game object object, nid means the gameobj_id
		player = Quest.GameObject.GetGameObjectCharacterFromIDAndInstance(nid);

		if(not player) then
			local GameObjectList = commonlib.gettable("MyCompany.Aries.Quest.GameObjectList");
			local gameobj_data = GameObjectList.GetGameObjectByID(nid);
			if(gameobj_data) then
				player_name = gameobj_data.name or "";
				if(not gameobj_data.skiprender_char) then
					char_asset = gameobj_data.assetfile_char;
				elseif(not gameobj_data.skiprender_mesh) then
					mesh_asset = gameobj_data.assetfile_model 
				end
			end
		end
	end
	
	local function PlayAnimIfSickOrDead()
		if(object == "mount") then
			-- play sick or dead animation if appropriate
			local isdead = false;
			local issick = false;
			local item;
			if(nid == System.App.profiles.ProfileManager.GetNID()) then
				-- my mount
				local ItemManager = System.Item.ItemManager;
				item = ItemManager.GetMyMountPetItem();
			else
				-- OPC mount
				local ItemManager = System.Item.ItemManager;
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
	end
	
	if( (char_asset or mesh_asset) or (player and player:IsValid()) ) then
	
		-- clone the player apparence information and apply to pe:player
		if(ctl) then
			local miniscene_obj;
			if(char_asset) then
				if(type(char_asset) == "string") then
					char_asset = ParaAsset.LoadParaX("", char_asset);
				end
				miniscene_obj = ParaScene.CreateCharacter(miniSceneName.."_obj", char_asset, "", true, 0.35, -1.57, 1);
			elseif(mesh_asset) then
				if(type(mesh_asset) == "string") then
					mesh_asset = ParaAsset.LoadStaticMesh("", mesh_asset);
				end
				miniscene_obj = ParaScene.CreateMeshPhysicsObject(miniSceneName.."_obj", mesh_asset, 1,1,1, false, "1,0,0,0,1,0,0,0,1,0,0,0");
			else
				-- clone the object
				local function CloneObj(obj)
					local ret_obj;
					if(obj and obj:IsValid() == true) then
						if(obj:IsCharacter()) then
							local asset = obj:GetPrimaryAsset();
							ret_obj = ParaScene.CreateCharacter(miniSceneName.."_obj", asset, "", true, 0.35, -1.57, 1);
							local replaceable_r1 = obj:GetReplaceableTexture(1):GetFileName();
							if(replaceable_r1 and replaceable_r1~="") then
								-- this fixed a bug of PoliceDog.x rendering 
								ret_obj:SetReplaceableTexture(1, ParaAsset.LoadTexture("", replaceable_r1, 1));
							end
							if(obj:ToCharacter():IsCustomModel()) then
								local facial_info_string = Map3DSystem.UI.CCS.Predefined.GetFacialInfoString(obj);
								local cartoonface_info_string = Map3DSystem.UI.CCS.DB.GetCartoonfaceInfoString(obj);
								local characterslot_info_string = Map3DSystem.UI.CCS.Inventory.GetCharacterSlotInfoString(obj);
								Map3DSystem.UI.CCS.Predefined.ApplyFacialInfoString(ret_obj, facial_info_string);
								Map3DSystem.UI.CCS.DB.ApplyCartoonfaceInfoString(ret_obj, cartoonface_info_string);
								Map3DSystem.UI.CCS.Inventory.ApplyCharacterSlotInfoString(ret_obj, characterslot_info_string);

								--if(mcmlNode.IsSelfAndForceUseOriginalCCS) then
									---- force reload the original ccs info
									--local gsid = 0;
									--local item = Map3DSystem.Item.ItemManager.GetItemByBagAndPosition(0, 2);
									--if(item and item.guid ~= 0) then
										--gsid = item.gsid;
									--end
									--ret_obj:ToCharacter():SetCharacterSlot(0, gsid);
								--
									--local gsid = 0;
									--local item = Map3DSystem.Item.ItemManager.GetItemByBagAndPosition(0, 5);
									--if(item and item.guid ~= 0) then
										--gsid = item.gsid;
									--end
									--ret_obj:ToCharacter():SetCharacterSlot(16, gsid);
								--
									--local gsid = 0;
									--local item = Map3DSystem.Item.ItemManager.GetItemByBagAndPosition(0, 6);
									--if(item and item.guid ~= 0) then
										--gsid = item.gsid;
									--end
									--ret_obj:ToCharacter():SetCharacterSlot(17, gsid);
--
									--local gsid = 0;
									--local item = Map3DSystem.Item.ItemManager.GetItemByBagAndPosition(0, 8);
									--if(item and item.guid ~= 0) then
										--gsid = item.gsid;
									--end
									--ret_obj:ToCharacter():SetCharacterSlot(21, gsid);
								--
									--local gsid = 0;
									--local item = Map3DSystem.Item.ItemManager.GetItemByBagAndPosition(0, 7);
									--if(item and item.guid ~= 0) then
										--gsid = item.gsid;
									--end
									--ret_obj:ToCharacter():SetCharacterSlot(19, gsid);
								--end
							end
						else
							local asset = obj:GetPrimaryAsset();
							ret_obj = ParaScene.CreateMeshPhysicsObject(miniSceneName.."_obj", asset, 1,1,1, false, "1,0,0,0,1,0,0,0,1,0,0,0");
						end
					end
					return ret_obj;
				end
				miniscene_obj = CloneObj(player);
			end

			if(not miniscene_obj) then
				return;
			end
			-- apply camera settings
			local camera_name = mcmlNode:GetAttributeWithCode("CameraName");
			local camera_setting;
			if(camera_name) then
				camera_setting = pe_player.CamSetting[camera_name];
				ctl.__camera_name = camera_name;
			else
				local assetfile = miniscene_obj:GetPrimaryAsset():GetKeyName();
				local name_, camera_name_
				for name_, camera_name_ in pairs(CameraNameByAssetMap) do
					if(assetfile:match(name_)) then
						camera_setting = pe_player.CamSetting[camera_name_];
						break;
					end
				end
			end

			ctl:ShowModel(miniscene_obj, camera_setting==nil);
			ctl.ClonedObjName = player_name or player.name;
			ctl.nid = nid;
			PlayAnimIfSickOrDead();

			if(camera_setting) then
				local LookAt = camera_setting.LookAt;
				local EyePos = camera_setting.EyePos;
				ctl:CameraSetLookAtPos(LookAt[1], LookAt[2], LookAt[3]);
				ctl:CameraSetEyePosByAngle(EyePos[1], EyePos[2], EyePos[3]);
			end

			-- set the mask texture
			local MaskTexture = mcmlNode:GetAttributeWithCode("MaskTexture");
			if(ctl and MaskTexture ~= nil and MaskTexture ~= "") then
				ctl:SetMaskTexture(MaskTexture);
			end
		end
	else
		if(object == "npc") then
			-- do nothing to show 
			-- NPC related pe:player is always shown when the NPC is insight
			LOG.std("", "warn", "mcml", "visualize non-insight NPC in pe:avatar tag");
		elseif(object == "gameobject") then
			-- do nothing to show 
			-- game object related pe:player is always shown when the game object is insight
			LOG.std("", "warn", "mcml", "visualize non-insight gameobject in pe:avatar tag");
		else
			-- set the mask texture
			local MaskTexture = mcmlNode:GetAttributeWithCode("MaskTexture");
			local ItemManager = System.Item.ItemManager;
			ItemManager.GetItemsInOPCBag(nid, 0, "pe_player", function(msg)
				if(msg and msg.items) then
					local equips = {};
					local i;
					for i = 1, 44 do
						equips[i] = 0;
					end
					local i;
					for i = 1, 44 do
						local item = ItemManager.GetOPCItemByBagAndPosition(nid, 0, i);
						if(item and item.guid > 0) then
							equips[i] = item.gsid;
						end
					end
					local facial_plus_cartoonface = "";
					local item = ItemManager.GetOPCItemByBagAndPosition(nid, 0, 21);
					if(item and item.guid > 0) then
						facial_plus_cartoonface = item.clientdata;
					end
					local assetfile;
					local replaceable_r1;
					if(object == "self") then
						assetfile = Player.GetAvaterAssetFileByID(equips[25]);
					elseif(object == "mount") then
						local gsid = equips[31];
						if(gsid ~= 0) then
							if(nid == Map3DSystem.App.profiles.ProfileManager.GetNID()) then
								-- check if the mount pet is at home
								local item
								if(nid == System.App.profiles.ProfileManager.GetNID()) then
									-- my mount
									local ItemManager = System.Item.ItemManager;
									item = ItemManager.GetMyMountPetItem();
								else
									-- OPC mount
									item = ItemManager.GetOPCMountPetItem(nid);
								end
								if(item and item.guid > 0 and (System.options.version=="kids")) then
									gsid = item.gsid;
									local mountPetStage = item:GetAssetFileIndex();
									assetfile = ItemManager.GetAssetFileFromGSIDAndIndex(item.gsid, item:GetAssetFileIndex());
									local basecolor_gsid = equips[40];
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
										end
									elseif(mountPetStage == 3) then -- major
										if(basecolor_gsid == 11009) then
											replaceable_r1 = "character/v3/PurpleDragonMajor/Female/SkinColor01.dds";
										elseif(basecolor_gsid == 11010) then
											replaceable_r1 = "character/v3/PurpleDragonMajor/Female/SkinColor02.dds";
										elseif(basecolor_gsid == 11011) then
											replaceable_r1 = "character/v3/PurpleDragonMajor/Female/SkinColor03.dds";
										elseif(basecolor_gsid == 11012) then
											replaceable_r1 = "character/v3/PurpleDragonMajor/Female/SkinColor04.dds";
										end
									end
								else
									return;
								end
							else
								return;
							end
						end
						--local gsItem = ItemManager.GetGlobalStoreItemInMemory(gsid)
						--if(gsItem) then
							--assetfile = gsItem.assetfile;
						--end
					elseif(object == "follow") then
						local gsid = equips[32];
						if(gsid == 0) then
							return
						end
						local gsItem = ItemManager.GetGlobalStoreItemInMemory(gsid)
						if(gsItem) then
							assetfile = gsItem.assetfile;
						end
					end
					if(ctl) then
						local asset = ParaAsset.LoadParaX("", assetfile);
						local obj = ParaScene.CreateCharacter(miniSceneName.."_obj", asset, "", true, 0.35, -1.57, 1);
						
						if(replaceable_r1) then
							obj:SetReplaceableTexture(1, ParaAsset.LoadTexture("", replaceable_r1, 1));
						end
						
						if(obj:ToCharacter():IsCustomModel() == true) then
							local facial_info_string = GetFacialInfoStringFromEquips(facial_plus_cartoonface);
							local cartoonface_info_string = GetCartoonfaceInfoStringFromEquips(facial_plus_cartoonface);
							local characterslot_info_string = GetCharacterSlotInfoStringFromEquips(equips, object);
							Map3DSystem.UI.CCS.Predefined.ApplyFacialInfoString(obj, facial_info_string);
							Map3DSystem.UI.CCS.DB.ApplyCartoonfaceInfoString(obj, cartoonface_info_string);

							--Map3DSystem.UI.CCS.Inventory.ApplyCharacterSlotInfoString(obj, characterslot_info_string);

							local sInfo = characterslot_info_string;
							local playerChar;
							-- get player character
							if(obj ~= nil and obj:IsValid() == true) then
								if(obj:IsCharacter() == true) then
									playerChar = obj:ToCharacter();
								end
							end
							if( playerChar ~= nil and playerChar:IsCustomModel() == true ) then
		
								local slot = 0;
								local itemID;
								for itemID in string.gfind(sInfo, "([^#]+)") do
									
									local gsid = tonumber(itemID);

									if(gsid) then
										if(slot == 16) then
											local gsItem = ItemManager.GetGlobalStoreItemInMemory(gsid);
											if(gsItem) then
												local ground_effect_id = gsItem.template.stats[181];
												if(ground_effect_id and ground_effect_id > 1000) then
													playerChar:SetCharacterSlot(27, ground_effect_id);
												else
													playerChar:SetCharacterSlot(27, 0);
												end
											end
										end
										if(slot == 21) then
											local gsItem = ItemManager.GetGlobalStoreItemInMemory(gsid);
											if(gsItem) then
												-- reset the base model to mount pet asset
												local bForceAttBack = gsItem.template.stats[13];
												if(bForceAttBack == 1) then
													slot = 26; -- CS_BACK 
													playerChar:SetCharacterSlot(21, 0);
												else
													slot = 21; -- CS_ARIES_CHAR_GLASS 
													playerChar:SetCharacterSlot(26, 0);
												end
											end
										end
										if(slot ~= 27) then
											playerChar:SetCharacterSlot(slot, gsid);
										end
										--playerChar:SetCharacterSlot(slot, gsid);
									end

									slot = slot + 1;
								end
							else
								--log("error: attempt to set a non character ccs information or non custom character.\n");
							end
						end
						
						-- NOTE 2010/8/30: for all characters with hat, hide the hair, hair is included in the hat model
						if(obj:ToCharacter():GetCharacterSlotItemID(0) > 1) then -- IT_Head
							obj:ToCharacter():SetBodyParams(-1, -1, 0, 0, -1); -- int hairColor, int hairStyle
						end

						-- apply camera settings
						local camera_name = mcmlNode:GetAttributeWithCode("CameraName");
						local camera_setting;
						if(camera_name) then
							camera_setting = pe_player.CamSetting[camera_name];
							ctl.__camera_name = camera_name;
						elseif(assetfile) then
							local name_, _
							local char_map = {
								"TeenElfFemale",
								"TeenElfMale",
								"ElfFemale",
								"ElfFemaleFreezed",
								"PurpleDragonMajor",
								"PurpleDragonEgg",
							};
							for _, name_ in ipairs(char_map) do
								if(assetfile:match(name_)) then
									local camera_name = CameraNameByAssetMap[name_];
									if(camera_name) then
										camera_setting = pe_player.CamSetting[camera_name];
									end
									break;
								end
							end
						end

						ctl:ShowModel(obj, camera_setting==nil);
						PlayAnimIfSickOrDead();

						if(camera_setting) then
							local LookAt = camera_setting.LookAt;
							local EyePos = camera_setting.EyePos;
							ctl:CameraSetLookAtPos(LookAt[1], LookAt[2], LookAt[3]);
							ctl:CameraSetEyePosByAngle(EyePos[1], EyePos[2], EyePos[3]);
						end
						
						if(ctl and MaskTexture ~= nil and MaskTexture ~= "") then
							ctl:SetMaskTexture(MaskTexture);
						end
					end
				end
			end);
		end
	end
	-- create inner child if any. 
	if(myLayout) then
		local childnode;
		for childnode in mcmlNode:next() do
			local left, top, width, height = myLayout:GetPreferredRect();
			Map3DSystem.mcml_controls.create(rootName, childnode, bindingContext, _parent, left, top, width, height, nil, myLayout)
		end
	end
	------------------------------------
	-- load avatar information
	------------------------------------
end

function pe_player.RefreshContainingPageCtrls()
	local pe_player_all = Map3DSystem.mcml_controls.pe_player_all or {};
	local invalid_pe_player_names = {};
	local name, miniscenename;
	for name, miniscenename in pairs(pe_player_all) do
		local ctl = CommonCtrl.GetControl(name);
		if(ctl ~= nil) then
			if(not ctl:IsUIValid()) then
				-- NOTE: we check ui object for control validity, remove the name from pe_player_all for invalid controls
				table.insert(invalid_pe_player_names, name);
			else
				-- NOTE (Fixed 2011.12.24): there is a chance that the target object is not refreshed according to cloedobjname
				--		if it is an OPC character the name could be nid or nid+driver. if the user switch states, 
				--		the object with previously inserted name will be invalid or changed to mount pet dragon
				if(ctl.ClonedObjName) then
					-- the refresh page ctrls will only refresh the player if the player is already in the scene
					-- otherwise one shoule refresh the pageCtrl to make sure the pe:player gets the latest player info
					local function CloneObj(obj)
						local ret_obj;
						if(obj and obj:IsValid() == true) then
							if(obj:IsCharacter()) then
								local asset = obj:GetPrimaryAsset();
								ret_obj = ParaScene.CreateCharacter("", asset, "", true, 0.35, -1.57, 1);
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

					-- fixed a bug that switching mount pet will change the appearance. 
					local player;
					if(ctl.nid) then
						player = Pet.GetUserCharacterObj(ctl.nid);
					else
						player = ParaScene.GetCharacter(ctl.ClonedObjName);
					end
					
					if(player and player:IsValid()) then
						
						local camera_name = ctl.__camera_name;
						local camera_setting;
						if(camera_name) then
							camera_setting = pe_player.CamSetting[camera_name];
						else
							local assetfile = player:GetPrimaryAsset():GetKeyName();
							local name_, _;
							local char_map = {
								"ElfFemale",
								"TeenElfFemale",
								"TeenElfMale",
								"ElfFemaleFreezed",
							};
							for name_, _ in pairs(char_map) do
								if(assetfile:match(name_)) then
									local camera_name = CameraNameByAssetMap[name_];
									if(camera_name) then
										camera_setting = pe_player.CamSetting[camera_name];
									end
									break;
								end
							end
						end
						
						ctl:ShowModel(CloneObj(player), camera_setting==nil);

						if(camera_setting) then
							local LookAt = camera_setting.LookAt;
							local EyePos = camera_setting.EyePos;
							ctl:CameraSetLookAtPos(LookAt[1], LookAt[2], LookAt[3]);
							ctl:CameraSetEyePosByAngle(EyePos[1], EyePos[2], EyePos[3]);
						end
					end
				end
			end
		end
	end
	-- clear the invalid pe:player controls
	local i, name;
	for i, name in ipairs(invalid_pe_player_names) do
		Map3DSystem.mcml_controls.pe_player_all[name] = nil;
	end
end