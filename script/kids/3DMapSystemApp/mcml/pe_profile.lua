--[[
Title: all controls for profile tag controls.
Author(s): WangTian, LiXizhi
Date: 2008/3/10, refactored 2008.5.5 LXZ
Desc: pe:profile, pe:profile-mini, pe:profile-pic, 


---++ pe:profile-photo
Renders the user's photo in specific size (defined in style). It just turns into an img tag for the specified user's profile picture. 

---+++ Attributes:

| Required | Name | Type | Description |
| required | uid | uid | The ID of the user or Page whose name you want to show. You can also use "loggedinuser" or "profileowner". |
| | linked | bool | Link to the user's profile. (default value is true) |
| | size | string | it can be "square"(50*50), "normal"(200*150), "small"(90*60 default), "thumb"(50*50)|
| | height | number | image height in pixel |
| | width | number | image width in pixel |

---+++ Examples

<verbatim>
<div style="float:left;margin:5px">
    <pe:profile-photo uid="6ea770c6-92b2-4b2b-86da-6f574641ec11"  linked="true"/><br />
    <pe:name uid="6ea770c6-92b2-4b2b-86da-6f574641ec11"/>
</div>
<div style="float:left;margin:5px">
    <pe:profile-photo uid="loggedinuser"/><br />
    <pe:name uid="loggedinuser"/>
</div>
</verbatim>

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_profile.lua");
-------------------------------------------------------
]]
local L = CommonCtrl.Locale("IDE");

if(not Map3DSystem.mcml_controls) then Map3DSystem.mcml_controls = {} end

----------------------------------------------------------------------
-- pe:profile control: handles MCML tag <pe:profile>
----------------------------------------------------------------------
local pe_profile = {};
Map3DSystem.mcml_controls.pe_profile = pe_profile;

function pe_profile.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	
	local uid = mcmlNode:GetAttributeWithCode("uid");
	
	Map3DSystem.App.profiles.ProfileManager.DownloadFullProfile(uid, pe_profile.DownloadCallbackFunc);
	
	NPL.load("(gl)script/kids/3DMapSystemApp/mcml/PageCtrl.lua");
	-- create class
	local MyPage = Map3DSystem.mcml.PageCtrl:new({url = "script/kids/3DMapSystemApp/Profiles/ProfilePage.html"});
	pe_profile.ProfilePage = MyPage;
	-- one can create a UI instance like this.
	
	width = parentLayout:GetPreferredSize();
	
	if(parentLayout ~= nil) then
		width = parentLayout:GetPreferredSize();
		if(640 > width) then
			parentLayout:NewLine();
			width = parentLayout:GetMaxSize();
		end
		left, top = parentLayout:GetAvailablePos();
	end
	
	MyPage:Create("ProfilePage", _parent, "_lt", left, top, width, 640);
	
	-- load the profile window
	NPL.load("(gl)script/kids/3DMapSystemApp/profiles/ProfileWnd.lua");
	
	-- TODO: render the profile page in MCML
	--Map3DSystem.App.profiles.ShowProfile(uid);
	
	parentLayout:AddObject(width, 640);
end

function pe_profile.DownloadCallbackFunc()
	_guihelper.MessageBox("Profile refreshed\n");
	pe_profile.ProfilePage:Refresh();
end

----------------------------------------------------------------------
-- pe:profile-mini control: handles MCML tag <pe:profile-mini>
----------------------------------------------------------------------
local pe_profile_mini = {};
Map3DSystem.mcml_controls.pe_profile_mini = pe_profile_mini;

function pe_profile_mini.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	
	local uid = mcmlNode:GetAttributeWithCode("uid")
	
	-- load the mini profile window
	NPL.load("(gl)script/kids/3DMapSystemApp/profiles/ProfileWnd.lua");
	--Map3DSystem.App.profiles.ShowMiniProfile(uid);
end


----------------------------------------------------------------------
-- pe:profile-photo: handles MCML tag <pe:profile-photo>
-- Turns into an img tag for the specified user's profile picture. 
----------------------------------------------------------------------
local pe_profile_photo = {};
Map3DSystem.mcml_controls.pe_profile_photo = pe_profile_photo;

-- Renders the user's photo in specific size(defined in style)
function pe_profile_photo.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local uid = mcmlNode:GetAttributeWithCode("uid");
	if(uid == "loggedinuser") then
		-- get current user ID as the uid
		uid = Map3DSystem.App.profiles.ProfileManager.GetUserID();
	end
	if(uid == nil or uid=="") then
		log("error: pe:name must provide uid attribute\n");
		return;
	end
	
	-- Link to the user's profile. (default value is false) 
	local linked = mcmlNode:GetBool("linked");
	
	-- width and height of the image to display
	-- NOTE: most mode is fixed width display: thumb, small and normal
	local imgWidth = mcmlNode:GetNumber("width");
	local imgHeight = mcmlNode:GetNumber("height");
	
	if(imgWidth) then
		if(not imgHeight) then
			imgHeight = imgWidth;
		end
	else
		-- image size
		local size = mcmlNode:GetString("size");
		
		if(size == "thumb") then
			imgWidth = 50;
			imgHeight = imgWidth;
		elseif(size == "small") then
			imgWidth = 90;
			imgHeight = 60;
		elseif(size == "normal") then
			imgWidth = 200;
			imgHeight = 150;
		elseif(size == "square") then
			imgWidth = 50;
			imgHeight = imgWidth;
		else
			-- default: -- TODO: shall we get image info from image?
			imgWidth = 90;
			imgHeight = 60;
		end
	end
	
	--
	-- get photo URL: first check userinfo, if not found, chekc the profile app's mcml box
	--
	-- use the value attribute as url if it exists
	local photoURL = mcmlNode:GetAttributeWithCode("value"); 
	if(photoURL==nil) then
		local bLocalVersion = true;
		Map3DSystem.App.profiles.ProfileManager.GetUserInfo(uid, "pe:profile-photo"..tostring(uid), function(msg)
			if(msg and msg.users and msg.users[1]) then
				local user = msg.users[1];
				local photo = user.photo;
				local function AutoRefresh(newPhoto)
					if(newPhoto and newPhoto ~= photoURL) then
						-- only refresh if name is different from last
						photoURL = newPhoto;
						
						local pageCtrl = mcmlNode:GetPageCtrl();
						if(pageCtrl) then
							-- needs to refresh for newly fetched version.
							mcmlNode:SetAttribute("value", photoURL)
							if(not bLocalVersion) then
								pageCtrl:Refresh();
							end
						end
					end
				end
				
				if(photo==nil or photo=="") then
					-- if no photo is provided, we will check its photo in its profile, instead. 
					local profile = Map3DSystem.App.profiles.ProfileManager.GetProfile(uid);
					if(profile==nil) then
						Map3DSystem.App.profiles.ProfileManager.DownloadMiniProfile(uid, function(uid, appkey, bSucceed)
							local profile = Map3DSystem.App.profiles.ProfileManager.GetProfile(uid);
							if(profile) then
								photo = profile:getUserPhoto() or "";
								AutoRefresh(photo);
							end
						end)
					else
						photo = profile:getUserPhoto() or "";
						AutoRefresh(photo);
					end	
				else
					AutoRefresh(photo);
				end
			end	
		end)
		bLocalVersion = false;
	end
	
	-- TODO: each time we will rebuilt child nodes however, we can also reuse previously created ones. 
	mcmlNode:ClearAllChildren();
	local ImgNodeParent = mcmlNode;
	if(linked) then
		local linkNode = Map3DSystem.mcml.new(nil, {name="a"});
		linkNode:SetAttribute("onclick", "Map3DSystem.App.Commands.Call");
		linkNode:SetAttribute("param1", Map3DSystem.options.ViewProfileCommand);
		linkNode:SetAttribute("param2", uid);
		linkNode:SetAttribute("tooltip", L"click to view its profile");
		mcmlNode:AddChild(linkNode, nil);
		ImgNodeParent = linkNode;
	end
	local imgNode = Map3DSystem.mcml.new(nil, {name="img"});
	imgNode:SetAttribute("width", imgWidth);
	imgNode:SetAttribute("height", imgHeight);
	if(photoURL == nil) then
		-- wait for photo path information
		photoURL = "Texture/3DMapSystem/brand/pleasewait.dds"; 
	elseif(photoURL == "") then
		-- user does not have profile photo
		photoURL = "Texture/3DMapSystem/brand/noimageavailable.dds";
	else
		-- non-empty string: photo url
	end
	imgNode:SetAttribute("src", photoURL);
	ImgNodeParent:AddChild(imgNode, nil);
	
	-- just use the standard style to create the control	
	Map3DSystem.mcml_controls.pe_simple_styles.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout);
end