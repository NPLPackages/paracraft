--[[
Title:avatar tag control
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
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_avatar.lua");
-------------------------------------------------------
]]

if(not Map3DSystem.mcml_controls) then Map3DSystem.mcml_controls = {} end

-----------------------------------
-- pe:avatar control
-----------------------------------
local pe_avatar = commonlib.gettable("Map3DSystem.mcml_controls.pe_avatar");

function pe_avatar.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	
	local uid = mcmlNode:GetAttributeWithCode("uid");
	
	if(uid == "loggedinuser") then
		-- get current user ID as the uid
		uid = Map3DSystem.App.profiles.ProfileManager.GetUserID();
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
					if(string.find(profile.CharParams.AssetFile, "can")) then
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
					if(string.find(profile.CharParams.AssetFile, "ElfFemale.xml")) then
						ctl:CameraSetLookAtPos(0, 0.75053763389587, 0);
						ctl:CameraSetEyePosByAngle(-1.6270221471786, 0.10000000149012, 3.0698845386505);
					end
				end
				
				if(IsFacePortrait == true) then
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
					if(string.find(profile.CharParams.AssetFile, "ElfFemale.xml")) then
						ctl:CameraSetLookAtPos(0, 0.90813940763474, -0.01);
						ctl:CameraSetEyePosByAngle(-1.5990210771561, 0.10000523924828, 1.7753294229507);
					end
				end
				
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
local pe_player = commonlib.gettable("Map3DSystem.mcml_controls.pe_player");

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
		RenderTargetSize = mcmlNode:GetNumber("RenderTargetSize") or 256,
		IsInteractive = IsInteractive,
		autoRotateSpeed = autoRotateSpeed,
	};
	ctl:Show(true);
	
	Map3DSystem.mcml_controls.pe_player_all = Map3DSystem.mcml_controls.pe_player_all or {};
	--table.insert(Map3DSystem.mcml_controls.pe_player_all, instName.."_player")
	Map3DSystem.mcml_controls.pe_player_all[instName.."_player"] = miniSceneName;
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
				-- NOTE: there is a chance that the target object is not refreshed according to cloedobjname
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
					local player = ParaScene.GetCharacter(ctl.ClonedObjName);
					if(player and player:IsValid() == true) then
						ctl:ShowModel(CloneObj(player));
						
						local assetfile = player:GetPrimaryAsset():GetKeyName();
						
						if(assetfile == "character/v3/Elf/Female/ElfFemale.xml") then
							-- this is for elf/female character only 
							ctl:CameraSetLookAtPos(0, 0.75700056552887, 0);
							ctl:CameraSetEyePosByAngle(3.1121213436127, 0.10053723305464, 3.3980791568756);
						end
						if(string.find(assetfile, "ElfFemaleFreezed")) then
							-- this is for ElfFemaleFreezed character only 
							ctl:CameraSetLookAtPos(0, 0.82573479413986, 0);
							ctl:CameraSetEyePosByAngle(3.36399102211, 0.35200002789497, 3.8270018100739);
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