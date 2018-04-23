--[[
Title: Game ContextMenu for 3d map system
Author(s): LiXizhi
Date: 2007/9/27
Desc: it only shows valid menu actions for a given object
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemUI/Desktop/ContextMenu.lua");
Map3DSystem.UI.ContextMenu.ShowMenuForObject(obj);
-------------------------------------------------------
]]
local L = CommonCtrl.Locale("ParaWorld");


-- common control library
NPL.load("(gl)script/ide/ContextMenu.lua");
NPL.load("(gl)script/ide/Encoding.lua");

if(not Map3DSystem.UI.ContextMenu) then Map3DSystem.UI.ContextMenu={}; end

--@param bShow: boolean to show or hide.
--@param obj: the character or model object to display the menu for. 
function Map3DSystem.UI.ContextMenu.ShowMenuForObject(obj)
	local _this,_parent;
	-- tricky. we shall hide any previous property panel, if contextmenu changes
	Map3DSystem.App.Commands.Call("Creation.DefaultProperty", {target=""});
	Map3DSystem.obj.SetObject(obj, "contextmenu");
	
	Map3DSystem.UI.ContextMenu.mouse_x = mouse_x;
	Map3DSystem.UI.ContextMenu.mouse_y = mouse_y;
	
	local ctl = CommonCtrl.GetControl("InGameContextMenu");
	if(ctl==nil)then
		ctl = CommonCtrl.ContextMenu:new{
			name = "InGameContextMenu",
			width = 130,
			height = 150,
			--container_bg = "Texture/3DMapSystem/ContextMenu/BG2.png:8 8 8 8",
			container_bg = "Texture/3DMapSystem/ContextMenu/BG3.png:8 8 8 8",
			--DrawNodeHandler = Map3DSystem.UI.ContextMenu.DrawMenuItemHandler,
		};
		local node = ctl.RootNode;
		local subNode;
		-- name node: for displaying name of the selected object. Click to display property
		node = ctl.RootNode:AddChild(CommonCtrl.TreeNode:new{Text = "name", Name = "name", Type="Title", NodeHeight = 26 });
		node = ctl.RootNode:AddChild(CommonCtrl.TreeNode:new{Text = "----------------------", Name = "titleseparator", Type="separator", NodeHeight = 4 });
		-- for character
		node = ctl.RootNode:AddChild(CommonCtrl.TreeNode:new{Text = "char", Name = "char", Type = "Group", NodeHeight = 0 });
			--node:AddChild(CommonCtrl.TreeNode:new({Text = L"编辑", Name = "edit", Icon = "Texture/3DMapSystem/common/cog.png", onclick = Map3DSystem.UI.ContextMenu.OnCharEdit}));
			--node:AddChild(CommonCtrl.TreeNode:new({Text = L"对话", Name = "dialog", Type = "Menuitem", onclick = Map3DSystem.UI.ContextMenu.OnDialog}));
			node:AddChild(CommonCtrl.TreeNode:new({Text = L"属性", Name = "property", Type = "Menuitem", onclick = Map3DSystem.UI.ContextMenu.OnCharShowProperty, Icon = "Texture/3DMapSystem/common/color_swatch.png"}));
			node:AddChild(CommonCtrl.TreeNode:new({Text = L"附身", Name = "switch", Type = "Menuitem", onclick = Map3DSystem.UI.ContextMenu.OnSwitch}));
			node:AddChild(CommonCtrl.TreeNode:new({Text = L"保存", Name = "SaveCharacter", Type = "Menuitem", onclick = Map3DSystem.UI.ContextMenu.OnSaveCharacter, Icon = "Texture/3DMapSystem/common/disk.png",}));	
			node:AddChild(CommonCtrl.TreeNode:new({Text = L"驾驶", Name = "mount", Type = "Menuitem", onclick = Map3DSystem.UI.ContextMenu.OnMount}));
			subNode = node:AddChild(CommonCtrl.TreeNode:new({Text = L"电影", Name = "movie", Type = "Menuitem", Expanded=false, Icon = "Texture/3DMapSystem/common/film.png"}));
				subNode:AddChild(CommonCtrl.TreeNode:new({Text = L"录制", Name = "Record", Type = "Menuitem", onclick = Map3DSystem.UI.ContextMenu.OnMovieRecord}));
				subNode:AddChild(CommonCtrl.TreeNode:new({Text = L"暂停", Name = "Pause", Type = "Menuitem", onclick = Map3DSystem.UI.ContextMenu.OnMoviePause}));
				subNode:AddChild(CommonCtrl.TreeNode:new({Text = L"停止", Name = "Stop", Type = "Menuitem", onclick = Map3DSystem.UI.ContextMenu.OnMovieStop}));
				subNode:AddChild(CommonCtrl.TreeNode:new({Text = L"相对播放", Name = "Replay", Type = "Menuitem", onclick = Map3DSystem.UI.ContextMenu.OnMovieReplayRelative}));
				subNode:AddChild(CommonCtrl.TreeNode:new({Text = L"绝对播放", Name = "Replay", Type = "Menuitem", onclick = Map3DSystem.UI.ContextMenu.OnMovieReplay}));
				subNode:AddChild(CommonCtrl.TreeNode:new({Text = L"保存...", Name = "Save_record", Type = "Menuitem", onclick = Map3DSystem.UI.ContextMenu.OnMovieSave_record}));
				subNode:AddChild(CommonCtrl.TreeNode:new({Text = L"载入...", Name = "Load_record", Type = "Menuitem", onclick = Map3DSystem.UI.ContextMenu.OnMovieLoad_record}));
			subNode = node:AddChild(CommonCtrl.TreeNode:new({Text = L"人工智能", Name = "AI", Type = "Menuitem", Expanded=false, Icon = "Texture/3DMapSystem/common/eye.png",}));
				subNode:AddChild(CommonCtrl.TreeNode:new({Text = L"对话", Name = "AI_talk", Type = "Menuitem", onclick = Map3DSystem.UI.ContextMenu.OnAI_Talk, }));
				subNode:AddChild(CommonCtrl.TreeNode:new({Text = L"随机走动", Name = "AI_randomwalk", Type = "Menuitem", onclick = Map3DSystem.UI.ContextMenu.OnAI_randomwalk}));
				subNode:AddChild(CommonCtrl.TreeNode:new({Text = L"跟屁虫", Name = "AI_follower", Type = "Menuitem", onclick = Map3DSystem.UI.ContextMenu.OnAI_follower}));
				subNode:AddChild(CommonCtrl.TreeNode:new({Text = L"NPC(RPG游戏)", Name = "AI_NPC", Type = "Menuitem", onclick = Map3DSystem.UI.ContextMenu.OnAI_NPC}));
				subNode:AddChild(CommonCtrl.TreeNode:new({Text = L"电影人", Name = "AI_movie", Type = "Menuitem", onclick = Map3DSystem.UI.ContextMenu.OnAI_movie,}));
				subNode:AddChild(CommonCtrl.TreeNode:new({Text = L"空白(无智能)", Name = "AI_empty", Type = "Menuitem", onclick = Map3DSystem.UI.ContextMenu.OnAI_empty}));
			node:AddChild(CommonCtrl.TreeNode:new({Text = L"删除", Name = "delete", Type = "Menuitem", onclick = Map3DSystem.UI.ContextMenu.OnDelete, Icon = "Texture/3DMapSystem/common/delete.png"}));
		
		node = ctl.RootNode:AddChild(CommonCtrl.TreeNode:new{Text = "charOPC", Name = "charOPC", Type = "Group", NodeHeight = 0 });
			-- agent only: same as pe:name right click 
			node:AddChild(CommonCtrl.TreeNode:new({Text = "查看信息", Name = "viewprofile", Type = "Menuitem", onclick = Map3DSystem.UI.ContextMenu.OnViewProfile, Icon = "Texture/3DMapSystem/common/userInfo.png",}));
			node:AddChild(CommonCtrl.TreeNode:new({Text = "加为好友", Name = "addasfriend",Type = "Menuitem", onclick = Map3DSystem.UI.ContextMenu.OnAddAsFriend, Icon = "Texture/3DMapSystem/common/user_add.png",}));	
			node:AddChild(CommonCtrl.TreeNode:new({Text = "私聊", Name = "chat", Type = "Menuitem", onclick = Map3DSystem.UI.ContextMenu.OnChatWith, Icon = "Texture/3DMapSystem/common/chat.png",}));
			node:AddChild(CommonCtrl.TreeNode:new({Text = "打个招呼", Name = "poke", Type = "Menuitem", onclick = Map3DSystem.UI.ContextMenu.OnPokeUser, Icon = "Texture/3DMapSystem/common/wand.png",}));
			node:AddChild(CommonCtrl.TreeNode:new({Text = "去他的房间", Name = "teleport", Type = "Menuitem", onclick = Map3DSystem.UI.ContextMenu.OnVisitHouse, Icon = "Texture/3DMapSystem/common/house.png",}));
			node:AddChild(CommonCtrl.TreeNode:new({Text = "去他的星球", Name = "teleport", Type = "Menuitem", onclick = Map3DSystem.UI.ContextMenu.OnVisitPlanet, Icon = "Texture/3DMapSystem/common/page_world.png",}));	
			node:AddChild(CommonCtrl.TreeNode:new({Text = "去找他", Name = "teleport", Type = "Menuitem", onclick = Map3DSystem.UI.ContextMenu.OnTeleportToUser, Icon = "Texture/3DMapSystem/common/transmit.png",}));
			node:AddChild(CommonCtrl.TreeNode:new({Text = "屏蔽", Name = "blockuser", Type = "Menuitem", onclick = Map3DSystem.UI.ContextMenu.OnBlockUser, Icon = "Texture/3DMapSystem/common/cancel.png",}));
			
		-- for mesh
		node = ctl.RootNode:AddChild(CommonCtrl.TreeNode:new{Text = "mesh", Name = "mesh", Type = "Group", NodeHeight = 0 });
			node:AddChild(CommonCtrl.TreeNode:new({Text = L"编辑", Name = "edit", Type = "Menuitem", onclick = Map3DSystem.UI.ContextMenu.OnPopupEditMesh, Icon = "Texture/3DMapSystem/common/wand.png"}));
			node:AddChild(CommonCtrl.TreeNode:new({Text = L"属性", Name = "property", Type = "Menuitem", onclick = Map3DSystem.UI.ContextMenu.OnMeshProperty, Icon = "Texture/3DMapSystem/common/color_swatch.png", }));
			--node:AddChild(CommonCtrl.TreeNode:new({Text = L"URL跳转", Name = "JumpToURL", Type = "Menuitem", }));
			--node:AddChild(CommonCtrl.TreeNode:new({Text = L"交互", Name = "act", Type = "Menuitem", }));
			--node:AddChild(CommonCtrl.TreeNode:new({Text = L"坐在这里", Name = "sit", Type = "Menuitem", }));
			--node:AddChild(CommonCtrl.TreeNode:new({Text = L"驾驶", Name = "mount", Type = "Menuitem", onclick = Map3DSystem.UI.ContextMenu.OnMount}));
			--node:AddChild(CommonCtrl.TreeNode:new({Text = L"收藏", Name = "AddToFavourite", Type = "Menuitem", }));
			node:AddChild(CommonCtrl.TreeNode:new({Text = L"复制", Name = "copy", Type = "Menuitem", onclick = Map3DSystem.UI.ContextMenu.OnCopy, Icon = "Texture/3DMapSystem/common/cut_red.png" }));
			node:AddChild(CommonCtrl.TreeNode:new({Text = L"移动", Name = "move", Type = "Menuitem", onclick = Map3DSystem.UI.ContextMenu.OnMove }));
			node:AddChild(CommonCtrl.TreeNode:new({Text = L"删除", Name = "delete", Type = "Menuitem", onclick = Map3DSystem.UI.ContextMenu.OnDelete, Icon = "Texture/3DMapSystem/common/delete.png"}));
	end
	
	-- fill the menu item according to object type. 
	

	if(not obj or not obj:IsValid()) then
		-- selected nothing.
		return ctl:Hide();
		-- log(" \n selected nothing \n")
		
	elseif(obj:IsCharacter()) then
		-- selected character.
		local namenode = ctl.RootNode:GetChildByName("name");
		local charNode = ctl.RootNode:GetChildByName("char");
		local charOPCNode = ctl.RootNode:GetChildByName("charOPC");
		local meshNode = ctl.RootNode:GetChildByName("mesh");
		
		-- set name: first try the dynamic property, then the name property, finally the asset name
		local name = obj:GetAttributeObject():GetDynamicField("name", "");
		if(name=="") then name = obj.name end
		if(name == nil or name == "") then
			local _,_, assetname = string.find(obj:GetPrimaryAsset():GetKeyName(), ".*[/\\]([^/\\]+)%..*$");
			if(assetname~=nil) then 
				name = assetname
			end
		end
		namenode.Text = name;
		
		-- set whether mountable
		charNode:GetChildByName("mount").Invisible = (obj:HasAttachmentPoint(0)==false);
		-- whether is OPC
		local IsOPC = obj:IsOPC() or obj:GetAttributeObject():GetDynamicField("IsOPC", false);
		charOPCNode.Invisible = not IsOPC;
		if(not charOPCNode.Invisible) then
			local bIsAgent = obj:GetAttributeObject():GetDynamicField("IsAgent", false)
			charOPCNode:GetChildByName("TeleportAgent").visible = bIsAgent;
			charOPCNode:GetChildByName("blockAgent").visible = bIsAgent;
		end
		charNode.Invisible = IsOPC; -- make charNode and charOPCNode mutually exclusive?
		
		-- can switch to the character: if and only if object is global, non OPC character, non current player
		charNode:GetChildByName("switch").Invisible = (ParaScene.GetPlayer():equals(obj)) or (obj:IsGlobal() == false) or (IsOPC);
		
		-- hide mesh
		meshNode.Invisible = true;
		
		ctl:SetModified(true);
		
		local _root = ParaUI.GetUIObject("root");
		local _, __, width, height = _root:GetAbsPosition();
		local posX = Map3DSystem.UI.ContextMenu.mouse_x;
		local posY = Map3DSystem.UI.ContextMenu.mouse_y;
		
		if((ctl.width + Map3DSystem.UI.ContextMenu.mouse_x) > width) then
			posX = Map3DSystem.UI.ContextMenu.mouse_x - ctl.width;
		end
		
		if((ctl.height + Map3DSystem.UI.ContextMenu.mouse_y) > height) then
			posY = Map3DSystem.UI.ContextMenu.mouse_y - ctl.height;
		end
		
		ctl:Show(posX, posY, nil);
		return true
	else
		-- selected mesh object.
		local namenode = ctl.RootNode:GetChildByName("name");
		local charNode = ctl.RootNode:GetChildByName("char");
		local charOPCNode = ctl.RootNode:GetChildByName("charOPC");
		local meshNode = ctl.RootNode:GetChildByName("mesh");
		
		-- set name: first try the dynamic property, then the name property, finally the asset name
		local name = obj:GetAttributeObject():GetDynamicField("name", "");
		if(name=="") then name = obj.name end
		if(name == nil or name == "") then
			local _,_, assetname = string.find(obj:GetPrimaryAsset():GetKeyName(), ".*[/\\]([^/\\]+)%..*$");
			if(assetname~=nil) then 
				name = commonlib.Encoding.DefaultToUtf8(assetname)
			end
		end
		namenode.Text = name;
		
		-- hide character items
		charNode.Invisible = true;
		charOPCNode.Invisible = true;
		
		-- show mesh items
		meshNode.Invisible = false;
		
		---- whether mesh has URL.
		--local url= obj:GetAttributeObject():GetDynamicField("URL", "");
		--meshNode:GetChildByName("JumpToURL").Invisible = (url=="");
		
		-- whether has replaceable texture
		-- meshNode:GetChildByName("property").Invisible = (obj:GetNumReplaceableTextures() ==0);
		
		---- set whether mountable
		--meshNode:GetChildByName("mount").Invisible = (obj:HasAttachmentPoint(0)==false);
		--
		---- for action scripts in the mesh
		--meshNode:GetChildByName("act").Invisible = true;
		--meshNode:GetChildByName("sit").Invisible = true;
		
		--local nXRefCount = obj:GetXRefScriptCount();
		--local i=0;
		--
		--for i=0,nXRefCount-1 do
			--local script = obj:GetXRefScript(i);
			--if(string.find(script, "model/scripts/.+_point.*") ~= nil) then
				--meshNode:GetChildByName("act").Invisible = false;
			--elseif(string.find(script, "model/scripts/.+chair.*") ~= nil) then
				--meshNode:GetChildByName("sit").Invisible = false;
			--else
				--meshNode:GetChildByName("act").Invisible = false;
			--end
		--end
		
		ctl:SetModified(true);
		
		local _root = ParaUI.GetUIObject("root");
		local _, __, width, height = _root:GetAbsPosition();
		local posX = Map3DSystem.UI.ContextMenu.mouse_x;
		local posY = Map3DSystem.UI.ContextMenu.mouse_y;
		
		if((ctl.width + Map3DSystem.UI.ContextMenu.mouse_x) > width) then
			posX = Map3DSystem.UI.ContextMenu.mouse_x - ctl.width;
		end
		
		if((ctl.height + Map3DSystem.UI.ContextMenu.mouse_y) > height) then
			posY = Map3DSystem.UI.ContextMenu.mouse_y - ctl.height;
		end
		
		ctl:Show(posX, posY, nil);
		local x,y,z = obj:GetPosition();
		-- face the current player to the target. 
		Map3DSystem.Animation.SendMeMessage({type = Map3DSystem.msg.ANIMATION_Character, animationName = "SelectObject",facingTarget = {x=x, y=y, z=z},});
		return true
	end
	
end

function Map3DSystem.UI.ContextMenu.OnMove()
	local obj_params = Map3DSystem.obj.GetObjectParams("contextmenu");
	if(obj_params~=nil and not obj_params.IsCharacter) then
		Map3DSystem.SendMessage_obj({type = Map3DSystem.msg.OBJ_BeginMoveObject, obj_params = obj_params});
	end
end

function Map3DSystem.UI.ContextMenu.OnCopy()
	local obj_params = Map3DSystem.obj.GetObjectParams("contextmenu");
	if(obj_params~=nil and not obj_params.IsCharacter) then
		Map3DSystem.SendMessage_obj({type = Map3DSystem.msg.OBJ_CopyObject, obj_params = obj_params});
	end
end

function Map3DSystem.UI.ContextMenu.OnSwitch()
	local obj = Map3DSystem.obj.GetObject("contextmenu");
	if(obj~=nil and obj:IsCharacter()) then
		obj:ToCharacter():SetFocus();
	end
end

function Map3DSystem.UI.ContextMenu.OnMount()
	local obj = Map3DSystem.obj.GetObject("contextmenu");
	if(obj~=nil) then
		-- mount current player to it
		Map3DSystem.MountPlayerOnChar(ParaScene.GetPlayer(), obj, true);
	end
end

function Map3DSystem.UI.ContextMenu.OnDelete()
	local obj_params = Map3DSystem.obj.GetObjectParams("contextmenu");
	if(obj_params~=nil) then
		Map3DSystem.SendMessage_obj({type = Map3DSystem.msg.OBJ_DeleteObject, obj_params = obj_params});
		Map3DSystem.obj.SetObject(nil, "contextmenu");
	end
end

function Map3DSystem.UI.ContextMenu.OnPopupEditMesh()
	local obj_params = Map3DSystem.obj.GetObjectParams("contextmenu");
	if(obj_params~=nil) then
		Map3DSystem.ObjectWnd.DisableMouseMove = true;
		Map3DSystem.SendMessage_obj({type = Map3DSystem.msg.OBJ_BeginMoveObject, obj_params = obj_params,});
		Map3DSystem.SendMessage_obj({type = Map3DSystem.msg.OBJ_PopupEditObject, target = "cursorObj", mouse_x=mouse_x, mouse_y=mouse_y, onclose=Map3DSystem.UI.ContextMenu.OnPopupEditMesh_Close});
	end
end

function Map3DSystem.UI.ContextMenu.OnMeshProperty()
	Map3DSystem.App.Commands.Call("Creation.DefaultProperty", {target="contextmenu"});
end

function Map3DSystem.UI.ContextMenu.OnPopupEditMesh_Close(bIsCancel)
	Map3DSystem.ObjectWnd.DisableMouseMove = nil;
	if(bIsCancel) then
		-- cancel move
		Map3DSystem.SendMessage_obj({type = Map3DSystem.msg.OBJ_CancelMoveCopyObject});
	else
		-- confirm move
		Map3DSystem.SendMessage_obj({type = Map3DSystem.msg.OBJ_EndMoveObject});
	end
end

function Map3DSystem.UI.ContextMenu.OnSaveCharacter()
	if(not Map3DSystem.User.CheckRight("Save")) then return end
	local obj = Map3DSystem.obj.GetObject("contextmenu");
	if(obj~=nil and obj:IsCharacter()) then
		Map3DSystem.SendMessage_obj({type = Map3DSystem.msg.OBJ_SaveCharacter, obj=obj})
	end
end

function Map3DSystem.UI.ContextMenu.OnCharEdit()
end

function Map3DSystem.UI.ContextMenu.OnCharShowProperty()
	Map3DSystem.App.Commands.Call("Creation.DefaultProperty", {target="contextmenu"});
end

-----------------------------
-- remote player
-----------------------------
-- return the JID of the selected object. 
local function GetSelectionJID()
	local obj = Map3DSystem.obj.GetObject("contextmenu");
	local IsOPC = obj and (obj:IsOPC() or obj:GetAttributeObject():GetDynamicField("IsOPC", false));
	if(IsOPC) then
		local JID = obj:GetAttributeObject():GetDynamicField("JID", "");
		if(JID and JID~="") then
			return JID;
		end
	end
end
function Map3DSystem.UI.ContextMenu.OnViewProfile()
	Map3DSystem.App.Commands.Call(Map3DSystem.options.ViewProfileCommand, GetSelectionJID())
end

function Map3DSystem.UI.ContextMenu.OnAddAsFriend()
	Map3DSystem.App.Commands.Call("Profile.Aquarius.AddAsFriend", {JID = GetSelectionJID()});
end

function Map3DSystem.UI.ContextMenu.OnChatWith()
	Map3DSystem.App.Commands.Call("Profile.Chat.ChatWithContactImmediate", {JID = GetSelectionJID()});
end

function Map3DSystem.UI.ContextMenu.OnPokeUser()
	Map3DSystem.App.profiles.ProfileManager.Poke(GetSelectionJID())
end

function Map3DSystem.UI.ContextMenu.OnVisitHouse()
	Map3DSystem.App.Commands.Call("Profile.Aquarius.NA");
end

function Map3DSystem.UI.ContextMenu.OnVisitPlanet()
	Map3DSystem.App.Commands.Call("Profile.Aquarius.NA");
end

function Map3DSystem.UI.ContextMenu.OnTeleportToUser()
	Map3DSystem.App.profiles.ProfileManager.TeleportToUser(GetSelectionJID())
end

function Map3DSystem.UI.ContextMenu.OnBlockUser()
	Map3DSystem.App.Commands.Call("Profile.Aquarius.NA");
end

-----------------------------
-- movie related
-----------------------------

function Map3DSystem.UI.ContextMenu.OnMovieRecord()
	local obj_params = Map3DSystem.obj.GetObjectParams("contextmenu");
	local obj = Map3DSystem.obj.GetObject("contextmenu");
	
	Map3DSystem.SendMessage_movie({type = Map3DSystem.msg.MOVIE_ACTOR_Record, obj=obj, obj_params=obj_params})
end

function Map3DSystem.UI.ContextMenu.OnMoviePause()
	local obj_params = Map3DSystem.obj.GetObjectParams("contextmenu");
	local obj = Map3DSystem.obj.GetObject("contextmenu");
	
	Map3DSystem.SendMessage_movie({type = Map3DSystem.msg.MOVIE_ACTOR_Pause, obj=obj, obj_params=obj_params})
end

function Map3DSystem.UI.ContextMenu.OnMovieStop()
	local obj_params = Map3DSystem.obj.GetObjectParams("contextmenu");
	local obj = Map3DSystem.obj.GetObject("contextmenu");
	
	Map3DSystem.SendMessage_movie({type = Map3DSystem.msg.MOVIE_ACTOR_Stop, obj=obj, obj_params=obj_params})
end


function Map3DSystem.UI.ContextMenu.OnMovieReplayRelative()
	local obj_params = Map3DSystem.obj.GetObjectParams("contextmenu");
	local obj = Map3DSystem.obj.GetObject("contextmenu");
	Map3DSystem.SendMessage_movie({type = Map3DSystem.msg.MOVIE_ACTOR_ReplayRelative, obj=obj, obj_params=obj_params})
end

function Map3DSystem.UI.ContextMenu.OnMovieReplay()
	local obj_params = Map3DSystem.obj.GetObjectParams("contextmenu");
	local obj = Map3DSystem.obj.GetObject("contextmenu");
	Map3DSystem.SendMessage_movie({type = Map3DSystem.msg.MOVIE_ACTOR_Replay, obj=obj, obj_params=obj_params})
end

-- save movie to file
function Map3DSystem.UI.ContextMenu.OnMovieSave_record()
	if(not Map3DSystem.User.CheckRight("Save")) then return end
	local obj_params = Map3DSystem.obj.GetObjectParams("contextmenu");
	NPL.load("(gl)script/ide/OpenFileDialog.lua");
	local ctl = CommonCtrl.OpenFileDialog:new{
		name = "OpenFileDialog1",
		alignment = "_ct",
		left=-256, top=-150,
		width = 512,
		height = 380,
		parent = nil,
		fileextensions = {L"人物电影文件(*.txt)", L"全部文件(*.*)",},
		folderlinks = {
			{path = ParaWorld.GetWorldDirectory().."actors/", text = L"场景角色"},
			{path = "temp/", text = L"临时文件"},
			{path = "character/movies/", text = L"人物电影"},
		},
		CheckFileExists = false,
		FileName =  ParaWorld.GetWorldDirectory().."actors/"..tostring(obj_params.name)..".movie.txt",
		onopen =  Map3DSystem.UI.ContextMenu.OnMovieSaveRecordAs,
	};
	ctl:Show(true);
end

function Map3DSystem.UI.ContextMenu.OnMovieSaveRecordAs(ctrlName, filename)
	--if(ParaIO.CopyFile(Map3DSystem.UI.ContextMenu.RecorderMovieTempfile, filename, true)) then
	--	_guihelper.MessageBox("成功保存到: "..filename.."\n");
	--end	
	if(ParaIO.CreateDirectory(filename)) then
		local obj_params = Map3DSystem.obj.GetObjectParams("contextmenu");
		local obj = Map3DSystem.obj.GetObject("contextmenu");
		Map3DSystem.SendMessage_movie({type = Map3DSystem.msg.MOVIE_ACTOR_Save, obj=obj, obj_params=obj_params, filename=filename})
	else
		_guihelper.MessageBox(L"无法创建:"..filename.."");
	end	
end

-- load from file.
function Map3DSystem.UI.ContextMenu.OnMovieLoad_record()
	local obj_params = Map3DSystem.obj.GetObjectParams("contextmenu");
	NPL.load("(gl)script/ide/OpenFileDialog.lua");
	local ctl = CommonCtrl.OpenFileDialog:new{
		name = "OpenFileDialog1",
		alignment = "_ct",
		left=-256, top=-150,
		width = 512,
		height = 380,
		parent = nil,
		fileextensions = {L"人物电影文件(*.txt)", L"全部文件(*.*)",},
		folderlinks = {
			{path = ParaWorld.GetWorldDirectory().."actors/", text = L"场景角色"},
			{path = "temp/", text = L"临时文件"},
			{path = "character/movies/", text = L"人物电影"},
		},
		CheckFileExists = true,
		FileName =  ParaWorld.GetWorldDirectory().."actors/"..tostring(obj_params.name)..".movie.txt",
		onopen =  Map3DSystem.UI.ContextMenu.OnMovieLoadRecordFromFile,
	};
	ctl:Show(true);
end

function Map3DSystem.UI.ContextMenu.OnMovieLoadRecordFromFile(ctrlName, filename)
	local obj_params = Map3DSystem.obj.GetObjectParams("contextmenu");
	local obj = Map3DSystem.obj.GetObject("contextmenu");
	Map3DSystem.SendMessage_movie({type = Map3DSystem.msg.MOVIE_ACTOR_Load, obj=obj, obj_params=obj_params, filename=filename, afterloadmsgtype = Map3DSystem.msg.MOVIE_ACTOR_Pause})
end

-----------------------------
-- AI related
-----------------------------

function Map3DSystem.UI.ContextMenu.OnAI_Talk()
	NPL.load("(gl)script/kids/3DMapSystemUI/Creator/CharPropertyPage.lua");
	Map3DSystem.App.Creator.CharPropertyPage.OnAssignAIClick(1, "contextmenu")
end

function Map3DSystem.UI.ContextMenu.OnAI_randomwalk()
	NPL.load("(gl)script/kids/3DMapSystemUI/Creator/CharPropertyPage.lua");
	Map3DSystem.App.Creator.CharPropertyPage.OnAssignAIClick(2, "contextmenu")
end

function Map3DSystem.UI.ContextMenu.OnAI_follower()
	NPL.load("(gl)script/kids/3DMapSystemUI/Creator/CharPropertyPage.lua");
	Map3DSystem.App.Creator.CharPropertyPage.OnAssignAIClick(3, "contextmenu")
end

function Map3DSystem.UI.ContextMenu.OnAI_NPC()
	-- TODO:
end

function Map3DSystem.UI.ContextMenu.OnAI_movie()
	local obj_params = Map3DSystem.obj.GetObjectParams("contextmenu");
	-- select a movie file
	NPL.load("(gl)script/ide/OpenFileDialog.lua");
	local ctl = CommonCtrl.OpenFileDialog:new{
		name = "OpenFileDialog1",
		alignment = "_ct",
		left=-256, top=-150,
		width = 512,
		height = 380,
		parent = nil,
		fileextensions = {L"人物电影文件(*.txt)", L"全部文件(*.*)",},
		folderlinks = {
			{path = ParaWorld.GetWorldDirectory().."actors/", text = L"场景角色"},
			{path = "temp/", text = L"临时文件"},
			{path = "character/movies/", text = L"人物电影"},
		},
		CheckFileExists = true,
		FileName =  ParaWorld.GetWorldDirectory().."actors/"..tostring(obj_params.name)..".movie.txt",
		onopen =  Map3DSystem.UI.ContextMenu.OnAI_movie_imp
	};
	ctl:Show(true);
end

function Map3DSystem.UI.ContextMenu.OnAI_movie_imp(ctrl, filename)
	local obj = Map3DSystem.obj.GetObject("contextmenu");
	if(obj~=nil and obj:IsCharacter()) then
		-- load movie
		Map3DSystem.SendMessage_movie({type = Map3DSystem.msg.MOVIE_ACTOR_Load, obj=obj, obj_params=obj_params, filename=filename, afterloadmsgtype = Map3DSystem.msg.MOVIE_ACTOR_Pause})
		
		-- apply movie AI
		local playerChar = obj:ToCharacter();
		local att = obj:GetAttributeObject();
		
		playerChar:Stop();
		playerChar:AssignAIController("face", "true");
		playerChar:AssignAIController("follow", "false");
		playerChar:AssignAIController("movie", "false");
		playerChar:AssignAIController("sequence", "false");
		att:SetField("OnLoadScript", string.format([[;NPL.load("(gl)script/AI/templates/AIMoviePlayer.lua");_AI_templates.AIMoviePlayer.On_Load(%q);]], filename));
		att:SetField("On_Perception", "");
		att:SetField("On_FrameMove", "");
		att:SetField("On_EnterSentientArea", "");
		att:SetField("On_LeaveSentientArea", "");
		--att:SetField("On_Click", "");
	end	
end

function Map3DSystem.UI.ContextMenu.OnAI_empty()
	NPL.load("(gl)script/kids/3DMapSystemUI/Creator/CharPropertyPage.lua");
	Map3DSystem.App.Creator.CharPropertyPage.OnAssignAIClick(5, "contextmenu")
end