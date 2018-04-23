--[[
Title: save world and publish world UI
Author(s): LiXizhi(code&logic)
Date: 2006/2/27
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/worlds/saveworld.lua");
Map3DSystem.UI.SaveWorldDialog.Show(true)
------------------------------------------------------------
]]
-- TODO: change this locale file
local L = CommonCtrl.Locale("KidsUI");

if(not Map3DSystem.UI.SaveWorldDialog) then Map3DSystem.UI.SaveWorldDialog={}; end

function Map3DSystem.UI.SaveWorldDialog.Show(bShow,_parent,parentWindow)
	local _this;
	Map3DSystem.UI.SaveWorldDialog.parentWindow = parentWindow;
	
	if(Map3DSystem.world.readonly) then
		_guihelper.MessageBox(L"This world is ready-only, you can not save it.");
		Map3DSystem.UI.SaveWorldDialog.OnClose();
		return
	elseif(not Map3DSystem.User.HasRight("Save")) then
		_guihelper.MessageBox(L"You do not have permission to save the world");
		Map3DSystem.UI.SaveWorldDialog.OnClose();
		return
	else
		-- this asks the user to upload images
		if(not Map3DSystem.User.userinfo.HasUploadedUserWork)then
			_guihelper.MessageBox(L"Do you know that you can upload screen shot of your 3d world to our community website? Please click the flashing button on the left bottom of the screen.");
		end	
	end	
	
	-- display a dialog asking for options
	local temp = ParaUI.GetUIObject("Map3DSystem.UI.SaveWorldDialog");
	_this=ParaUI.GetUIObject("Map3DSystem.UI.SaveWorldDialog");
	if(_this:IsValid()) then
		_this.visible = bShow;
		if(not bShow) then
			Map3DSystem.UI.SaveWorldDialog.OnDestory();
		end
	else
		local width, height = 461, 240
		_this=ParaUI.CreateUIObject("container","Map3DSystem.UI.SaveWorldDialog", "_ct",-width/2,-height/2-50,width, height);
		_this.background="Texture/msg_box.png";
		if(_parent==nil) then
			_this:AttachToRoot();
			 -- _this.candrag and TopLevel and not be true simultanously 
			_this:SetTopLevel(true);
		else
			_parent:AddChild(_this);
		end
		_parent = _this;
		
		_this = ParaUI.CreateUIObject("button", "button1", "_lt", 33, 23, 64, 64)
		_this.background="Texture/kidui/right/btn_save.png";
		_this.tooltip = L"Click the save button to save your current world";
		_guihelper.SetUIColor(_this, "255 255 255");
		_parent:AddChild(_this);

		_this = ParaUI.CreateUIObject("text", "label1", "_lt", 105, 43, 300, 16)
		_this.text = L"Do you want to save your current world?";
		_parent:AddChild(_this);

		_this = ParaUI.CreateUIObject("text", "label3", "_lt", 105, 71, 256, 16)
		_this.text = Map3DSystem.world.name;
		_this:GetFont("text").color = "0 100 0";
		_parent:AddChild(_this);
		
		_this = ParaUI.CreateUIObject("button", "button2", "_rb",  -326, -50, 92, 27)
		_this.text=L"Save";
		_this.tooltip=L"Save only modified content (fast)";
		_this.onclick=";Map3DSystem.UI.SaveWorldDialog.OnOK(false);";
		_parent:AddChild(_this);

		_this = ParaUI.CreateUIObject("button", "button3", "_rb", -228, -50, 92, 27)
		_this.text=L"Save Full";
		_this.tooltip=L"Save everything in the scene (slow)";
		_this.onclick=";Map3DSystem.UI.SaveWorldDialog.OnOK(true);";
		_parent:AddChild(_this);

		_this = ParaUI.CreateUIObject("button", "button4", "_rb", -113, -50, 92, 27)
		_this.text=L"Cancel";
		_this.onclick=";Map3DSystem.UI.SaveWorldDialog.OnClose();";	
		_parent:AddChild(_this);

		-- panel1
		_this = ParaUI.CreateUIObject("container", "panel1", "_fi", 19, 107, 21, 56)
		_this.background="Texture/whitedot.png;0 0 0 0";
		_parent:AddChild(_this);
		_parent = _this;

		_this = ParaUI.CreateUIObject("text", "label2", "_lt", 103, 11, 296, 16)
		_this.text = L"Upload my 3D world to community site";
		_parent:AddChild(_this);

		_this = ParaUI.CreateUIObject("text", "label4", "_lt", 103, 42, 296, 16)
		_this.text = L"Upload my screen shot";
		_parent:AddChild(_this);

		_this = ParaUI.CreateUIObject("button", "button5", "_lt", 14, 7, 83, 25)
		_this.text = L"publish";
		_this.onclick = ";Map3DSystem.UI.SaveWorldDialog.OnClickPublishWorld();"
		--_this.background = "Texture/kidui/explorer/button.png";
		_parent:AddChild(_this);

		_this = ParaUI.CreateUIObject("button", "button6", "_lt", 14, 38, 83, 25)
		_this.text = L"snapshot";
		--_this.background = "Texture/kidui/explorer/button.png";
		_this.onclick = ";Map3DSystem.UI.SaveWorldDialog.OnClickUpload();"
		_this.tooltip = L"Upload your work";
		_parent:AddChild(_this);
	end	
end

-- destory the control
function Map3DSystem.UI.SaveWorldDialog.OnDestory()
	ParaUI.Destroy("Map3DSystem.UI.SaveWorldDialog");
end

function Map3DSystem.UI.SaveWorldDialog.OnClose()
	if(Map3DSystem.UI.SaveWorldDialog.parentWindow~=nil) then
		-- send a message to its parent window to tell it to close. 
		Map3DSystem.UI.SaveWorldDialog.parentWindow:SendMessage(Map3DSystem.UI.SaveWorldDialog.parentWindow.name, CommonCtrl.os.MSGTYPE.WM_CLOSE);
	else
		Map3DSystem.UI.SaveWorldDialog.OnDestory()
	end
end

function Map3DSystem.UI.SaveWorldDialog.OnClickUpload()
	Map3DSystem.UI.SaveWorldDialog.OnClose();
end

function Map3DSystem.UI.SaveWorldDialog.OnClickPublishWorld()
	Map3DSystem.UI.SaveWorldDialog.OnClose();
	
	if(not Map3DSystem.User.IsAuthenticated) then
		_guihelper.MessageBox(L"In order to upload your work, you need to login to our community web site", function ()
			NPL.load("(gl)script/network/LoginBox.lua");
			LoginBox.Show(true, Map3DSystem.UI.SaveWorldDialog.PublishWorld_imp);
		end)
	else
		Map3DSystem.UI.SaveWorldDialog.PublishWorld_imp();
	end	
end

function Map3DSystem.UI.SaveWorldDialog.PublishWorld_imp()
	NPL.load("(gl)script/network/KM_WorldUploader.lua");
	KM_WorldUploader.ShowUIForTask(KM_WorldUploader.NewTask({source=Map3DSystem.world.name, type = KM_WorldUploader.TaskType.NormalWorld}));
end


-- save all modified terrain
-- @param bSaveEverything: if true everything is saved, if false only modified content are saved. 
function Map3DSystem.UI.SaveWorldDialog.OnOK(bSaveEverything)
	Map3DSystem.UI.SaveWorldDialog.OnClose();
	
	-- save to database
	Map3DSystem.world:SaveWorldToDB();
	
	if(bSaveEverything)then 
		-- save everything
		ParaScene.SetModified(true);
		local x,y,z = ParaScene.GetPlayer():GetPosition();
		
		-- save everything within 500 meters radius from the current character
		ParaTerrain.SetContentModified(x,z, true, 65535);
		ParaTerrain.SetContentModified(x+500,z+500, true, 65535);
		ParaTerrain.SetContentModified(x+500,z-500, true, 65535);
		ParaTerrain.SetContentModified(x-500,z+500, true, 65535);
		ParaTerrain.SetContentModified(x-500,z-500, true, 65535);
		ParaTerrain.SaveTerrain(true,true);
		
		local nCount = ParaScene.SaveAllCharacters();
		_guihelper.MessageBox(string.format(L"%d loaded characters in the scene are saved. All visible world near the current player are saved.",nCount));
	else
		-- save others
		if( ParaTerrain.IsModified() == true) then
			ParaTerrain.SaveTerrain(true,true);
			local player = ParaScene.GetObject("<player>");
			
			if(player:IsValid()==true) then
				local x,y,z = player:GetPosition();
				local OnloadScript = ParaTerrain.GetTerrainOnloadScript(x,z);
				_guihelper.MessageBox(L"scene has been saved to:\n"..OnloadScript);
			else
				_guihelper.MessageBox(L"scene has been saved.\n");
			end
		else 
			_guihelper.MessageBox(L"scene is not modified");
		end
	end	
end
