--[[
Title: Game ContextMenu for 3d map system
Author(s): LiXizhi
Date: 2007/9/27
Desc: it only shows valid menu actions for a given object
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/ContextMenu.lua");
MyCompany.Aries.Creator.ContextMenu.ShowMenuForObject(obj);
MyCompany.Aries.Creator.ContextMenu.CancelOperation();
-------------------------------------------------------
]]
-- common control library
NPL.load("(gl)script/ide/ContextMenu.lua");
NPL.load("(gl)script/apps/Aries/Creator/Assets/AssetsCommon.lua");

local ContextMenu = commonlib.gettable("MyCompany.Aries.Creator.ContextMenu");
local AssetsCommon = commonlib.gettable("MyCompany.Aries.Creator.AssetsCommon")

--@param bShow: boolean to show or hide.
--@param obj: the character or model object to display the menu for. 
function ContextMenu.ShowMenuForObject(obj)
	local _this,_parent;
	-- tricky. we shall hide any previous property panel, if contextmenu changes
	Map3DSystem.App.Commands.Call("Creation.DefaultProperty", {target=""});
	Map3DSystem.obj.SetObject(obj, "contextmenu");
	
	ContextMenu.mouse_x = mouse_x;
	ContextMenu.mouse_y = mouse_y;
	
	local ctl = CommonCtrl.GetControl("AriesCreatorCMenu");
	if(ctl==nil)then
		ctl = CommonCtrl.ContextMenu:new{
			name = "AriesCreatorCMenu",
			width = 130,
			height = 150,
			container_bg = "Texture/Aries/Dock/menu_lvl2_bg_32bits.png:39 30 24 30",
		};
		local node = ctl.RootNode;
		local subNode;
		-- name node: for displaying name of the selected object. Click to display property
		node = ctl.RootNode:AddChild(CommonCtrl.TreeNode:new{Text = "name", Name = "name", Type="Title", NodeHeight = 26 });
		node = ctl.RootNode:AddChild(CommonCtrl.TreeNode:new{Text = "----------------------", Name = "titleseparator", Type="separator", NodeHeight = 4 });
		-- for character
		node = ctl.RootNode:AddChild(CommonCtrl.TreeNode:new{Text = "char", Name = "char", Type = "Group", NodeHeight = 0 });
			--node:AddChild(CommonCtrl.TreeNode:new({Text = "属性", Name = "property", Type = "Menuitem", onclick = ContextMenu.OnCharShowProperty, Icon = "Texture/3DMapSystem/common/color_swatch.png"}));
			--node:AddChild(CommonCtrl.TreeNode:new({Text = "附身", Name = "switch", Type = "Menuitem", onclick = ContextMenu.OnSwitch}));
			--node:AddChild(CommonCtrl.TreeNode:new({Text = "保存", Name = "SaveCharacter", Type = "Menuitem", onclick = ContextMenu.OnSaveCharacter, Icon = "Texture/3DMapSystem/common/disk.png",}));	
			--node:AddChild(CommonCtrl.TreeNode:new({Text = "驾驶", Name = "mount", Type = "Menuitem", onclick = ContextMenu.OnMount, Icon = "Texture/3DMapSystem/common/anchor.png"}));
			node:AddChild(CommonCtrl.TreeNode:new({Text = "起名", Name = "rename", Type = "Menuitem", onclick = ContextMenu.OnRename, Icon = "Texture/3DMapSystem/common/anchor.png"}));
			
			subNode = node:AddChild(CommonCtrl.TreeNode:new({Text = "人工智能", Name = "AI", Type = "Menuitem", Expanded=false, Icon = "Texture/3DMapSystem/common/eye.png",}));
				subNode:AddChild(CommonCtrl.TreeNode:new({Text = "对话", Name = "AI_talk", Type = "Menuitem", onclick = ContextMenu.OnAI_Talk, }));
				-- subNode:AddChild(CommonCtrl.TreeNode:new({Text = "随机走动", Name = "AI_randomwalk", Type = "Menuitem", onclick = ContextMenu.OnAI_randomwalk}));
				--subNode:AddChild(CommonCtrl.TreeNode:new({Text = "跟屁虫", Name = "AI_follower", Type = "Menuitem", onclick = ContextMenu.OnAI_follower}));
				--subNode:AddChild(CommonCtrl.TreeNode:new({Text = "NPC(RPG游戏)", Name = "AI_NPC", Type = "Menuitem", onclick = ContextMenu.OnAI_NPC}));
				subNode:AddChild(CommonCtrl.TreeNode:new({Text = "空白(无智能)", Name = "AI_empty", Type = "Menuitem", onclick = ContextMenu.OnAI_empty}));
			node:AddChild(CommonCtrl.TreeNode:new({Text = "移动", Name = "move", Type = "Menuitem", onclick = ContextMenu.OnMove, Icon = "Texture/3DMapSystem/common/dragmove.png" }));	
			node:AddChild(CommonCtrl.TreeNode:new({Text = "删除", Name = "delete", Type = "Menuitem", onclick = ContextMenu.OnDelete, Icon = "Texture/3DMapSystem/common/delete.png"}));
		
		-- for mesh
		node = ctl.RootNode:AddChild(CommonCtrl.TreeNode:new{Text = "mesh", Name = "mesh", Type = "Group", NodeHeight = 0 });
			node:AddChild(CommonCtrl.TreeNode:new({Text = "移动", Name = "move", Type = "Menuitem", onclick = ContextMenu.OnMove, Icon = "Texture/3DMapSystem/common/dragmove.png" }));
			node:AddChild(CommonCtrl.TreeNode:new({Text = "复制", Name = "copy", Type = "Menuitem", onclick = ContextMenu.OnCopy, Icon = "Texture/3DMapSystem/common/cut_red.png" }));
			node:AddChild(CommonCtrl.TreeNode:new({Text = "编辑", Name = "edit", Type = "Menuitem", onclick = ContextMenu.OnPopupEditMesh, Icon = "Texture/3DMapSystem/common/wand.png"}));
			-- node:AddChild(CommonCtrl.TreeNode:new({Text = "属性", Name = "property", Type = "Menuitem", onclick = ContextMenu.OnMeshProperty, Icon = "Texture/3DMapSystem/common/color_swatch.png", }));
			node:AddChild(CommonCtrl.TreeNode:new({Text = "删除", Name = "delete", Type = "Menuitem", onclick = ContextMenu.OnDelete, Icon = "Texture/3DMapSystem/common/delete.png"}));
	end
	
	-- fill the menu item according to object type. 
	
	if(not obj or not obj:IsValid()) then
		-- selected nothing.
		return ctl:Hide();
		-- log(" \n selected nothing \n")
	end
		
	if(obj:IsCharacter()) then
		-- selected character.
		-- whether is OPC
		local IsOPC = obj:IsOPC() or obj:GetAttributeObject():GetDynamicField("IsOPC", false);
		if(IsOPC or ParaScene.GetPlayer():equals(obj)) then
			return ctl:Hide();
		end
		-- set name: first try the dynamic property, then the name property, finally the asset name
		local name = obj:GetAttributeObject():GetDynamicField("DisplayName", "");
		if(name == "") then 
			name = obj:GetAttributeObject():GetDynamicField("name", "");
			if(name == "") then 
				name = obj.name
			end	
		end
		if(name == nil or name == "") then
			local _,_, assetname = string.find(obj:GetPrimaryAsset():GetKeyName(), ".*[/\\]([^/\\]+)%..*$");
			if(assetname~=nil) then 
				name = assetname
			end
		end
		
		if(string.match(name, "%+mountpet%-follow$") or string.match(name, "%+driver$") or string.match(name, "%+followpet$")) then
			-- do not show menu for driver, follow and mount pet. 
			return ctl:Hide();
		end
		
		local namenode = ctl.RootNode:GetChildByName("name");
		local charNode = ctl.RootNode:GetChildByName("char");
		local meshNode = ctl.RootNode:GetChildByName("mesh");
		
		local name_len = ParaMisc.GetUnicodeCharNum(name);
		if(name_len > 10) then
			name = ParaMisc.UniSubString(name, 1, 10);
		end
		
		namenode.Text = name;
		
		-- set whether mountable
		-- charNode:GetChildByName("mount").Invisible = (obj:HasAttachmentPoint(0)==false);
		charNode.Invisible = false;
		
		-- can switch to the character: if and only if object is global, non OPC character, non current player
		-- charNode:GetChildByName("switch").Invisible = (ParaScene.GetPlayer():equals(obj)) or (obj:IsGlobal() == false) or (IsOPC);
		
		-- hide mesh
		meshNode.Invisible = true;
	else
		-- selected mesh object.
		local namenode = ctl.RootNode:GetChildByName("name");
		local charNode = ctl.RootNode:GetChildByName("char");
		local meshNode = ctl.RootNode:GetChildByName("mesh");
		
		-- set name: first try the dynamic property, then the name property, finally the asset name
		local name = obj:GetAttributeObject():GetDynamicField("name", "");
		if(name=="") then name = obj.name end
		if(name == nil or name == "") then
			local _,_, assetname = string.find(obj:GetPrimaryAsset():GetKeyName(), ".*[/\\]([^/\\]+)%..*$");
			if(assetname~=nil) then 
				name = assetname;
			end
		end
		local name_len = ParaMisc.GetUnicodeCharNum(name);
		if(name_len > 10) then
			name = ParaMisc.UniSubString(name, 1, 10);
		end
		namenode.Text = name;
		
		-- hide character items
		charNode.Invisible = true;
		
		-- show mesh items
		meshNode.Invisible = false;
		
		local x,y,z = obj:GetPosition();
		
		-- face the current player to the target. 
		GameLogic.PlayAnimation({animationName = "SelectObject",facingTarget = {x=x, y=y, z=z},});
	end
	
	ctl:SetModified(true);
		
	local _root = ParaUI.GetUIObject("root");
	local _, __, width, height = _root:GetAbsPosition();
	local posX = ContextMenu.mouse_x;
	local posY = ContextMenu.mouse_y;
	
	if((ctl.width + ContextMenu.mouse_x) > width) then
		posX = ContextMenu.mouse_x - ctl.width;
	end
	
	if((ctl.height + ContextMenu.mouse_y) > height) then
		posY = ContextMenu.mouse_y - ctl.height;
	end
	
	ctl:Show(posX, posY, nil);
	return true
end

-- cancel operation 
function ContextMenu.CancelOperation()
	ContextMenu.ShowMenuForObject(nil);
	ContextMenu.OnPopupEditMesh_Close(true);
end

function ContextMenu.OnMove()
	local obj_params = Map3DSystem.obj.GetObjectParams("contextmenu");
	if(obj_params~=nil) then
		Map3DSystem.SendMessage_obj({type = Map3DSystem.msg.OBJ_BeginMoveObject, obj_params = obj_params});
	end
end

function ContextMenu.OnCopy()
	local obj_params = Map3DSystem.obj.GetObjectParams("contextmenu");
	if(obj_params~=nil and not obj_params.IsCharacter) then
		Map3DSystem.SendMessage_obj({type = Map3DSystem.msg.OBJ_CopyObject, obj_params = obj_params});
	end
end

function ContextMenu.OnSwitch()
	local obj = Map3DSystem.obj.GetObject("contextmenu");
	if(obj~=nil and obj:IsCharacter()) then
		obj:ToCharacter():SetFocus();
	end
end

function ContextMenu.OnMount()
	_guihelper.MessageBox("目前版本, 暂时不支持驾驶, 看策划设计了")
	--local obj = Map3DSystem.obj.GetObject("contextmenu");
	--if(obj~=nil) then
		---- mount current player to it
		--Map3DSystem.MountPlayerOnChar(ParaScene.GetPlayer(), obj, true);
	--end
end

function ContextMenu.OnDelete()
	local obj_params = Map3DSystem.obj.GetObjectParams("contextmenu");
	if(obj_params~=nil) then
		Map3DSystem.obj.SetObject(nil, "contextmenu");
		AssetsCommon.DeleteObject({obj_params = obj_params})
	end
end

function ContextMenu.OnPopupEditMesh()
	local obj_params = Map3DSystem.obj.GetObjectParams("contextmenu");
	if(obj_params~=nil) then
		Map3DSystem.ObjectWnd.DisableMouseMove = true;
		Map3DSystem.SendMessage_obj({type = Map3DSystem.msg.OBJ_BeginMoveObject, obj_params = obj_params,});
		Map3DSystem.SendMessage_obj({type = Map3DSystem.msg.OBJ_PopupEditObject, target = "cursorObj", mouse_x=mouse_x, mouse_y=mouse_y, onclose=ContextMenu.OnPopupEditMesh_Close});
	end
end

function ContextMenu.OnMeshProperty()
	Map3DSystem.App.Commands.Call("Creation.DefaultProperty", {target="contextmenu"});
end

function ContextMenu.OnPopupEditMesh_Close(bIsCancel)
	Map3DSystem.ObjectWnd.DisableMouseMove = nil;
	if(bIsCancel) then
		-- cancel move
		Map3DSystem.SendMessage_obj({type = Map3DSystem.msg.OBJ_CancelMoveCopyObject});
	else
		-- confirm move
		Map3DSystem.SendMessage_obj({type = Map3DSystem.msg.OBJ_EndMoveObject});
	end
end

-----------------------------
-- character related
-----------------------------

function ContextMenu.OnSaveCharacter()
	if(not Map3DSystem.User.CheckRight("Save")) then return end
	local obj = Map3DSystem.obj.GetObject("contextmenu");
	if(obj~=nil and obj:IsCharacter()) then
		Map3DSystem.SendMessage_obj({type = Map3DSystem.msg.OBJ_SaveCharacter, obj=obj})
	end
end

function ContextMenu.OnCharShowProperty()
	Map3DSystem.App.Commands.Call("Creation.DefaultProperty", {target="contextmenu"});
end

-----------------------------
-- AI related
-----------------------------
NPL.load("(gl)script/apps/Aries/Creator/AI/LocalNPC.lua");
local LocalNPC = commonlib.gettable("MyCompany.Aries.Creator.AI.LocalNPC")

function ContextMenu.OnRename()
	local obj = Map3DSystem.obj.GetObject("contextmenu");
	if(obj~=nil and obj:IsCharacter()) then
		LocalNPC:InvokeEditor(obj, "aimod_base");
	end	
end

function ContextMenu.OnAI_Talk()
	local obj = Map3DSystem.obj.GetObject("contextmenu");
	if(obj~=nil and obj:IsCharacter()) then
		LocalNPC:InvokeEditor(obj, "SimpleTalk");
	end	
end

function ContextMenu.OnAI_randomwalk()
	--NPL.load("(gl)script/kids/3DMapSystemUI/Creator/CharPropertyPage.lua");
	--Map3DSystem.App.Creator.CharPropertyPage.OnAssignAIClick(2, "contextmenu")
end

function ContextMenu.OnAI_follower()
	--NPL.load("(gl)script/kids/3DMapSystemUI/Creator/CharPropertyPage.lua");
	--Map3DSystem.App.Creator.CharPropertyPage.OnAssignAIClick(3, "contextmenu")
end

function ContextMenu.OnAI_NPC()
	-- TODO:
end

function ContextMenu.OnAI_empty()
	local obj = Map3DSystem.obj.GetObject("contextmenu");
	if(obj~=nil and obj:IsCharacter()) then
		LocalNPC:RemoveAllAIMods(obj);
	end	
end