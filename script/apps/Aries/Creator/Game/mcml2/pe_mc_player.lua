--[[
Title: div element
Author(s): chenjinxian
Date: 2020/8/6
Desc: kp:usertag element
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/mcml2/pe_mc_player.lua");
MyCompany.Aries.Game.mcml2.pe_mc_player:RegisterAs("pe:mc_player");
------------------------------------------------------------
]]

NPL.load("(gl)script/ide/System/Windows/mcml/PageElement.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/mcml2/Canvas3D.lua");
local PageElement = commonlib.gettable("System.Windows.mcml.PageElement");
local Canvas3D = commonlib.gettable("MyCompany.Aries.Game.mcml2.Canvas3D");

local pe_mc_player = commonlib.inherit(commonlib.gettable("System.Windows.mcml.PageElement"), commonlib.gettable("MyCompany.Aries.Game.mcml2.pe_mc_player"));
pe_mc_player:Property({"class_name", "pe:mc_player"});

function pe_mc_player:ctor()
end

function pe_mc_player:LoadComponent(parentElem, parentLayout, style)
	local _this = self.control;
	if(not _this) then
		_this = Canvas3D:new():init(parentElem);
		self:SetControl(_this);
	else
		_this:SetParent(parentElem);
	end

	PageElement.LoadComponent(self, _this, parentLayout, style);
	_this:ApplyCss(self:GetStyle());
end

function pe_mc_player:OnLoadComponentBeforeChild(parentElem, parentLayout, css)
	if(self.control) then
		local IsActiveRendering = self:GetBool("IsActiveRendering");
		if (IsActiveRendering == nil) then
			IsActiveRendering = true;
		end
		local IsInteractive = self:GetBool("IsInteractive");
		if(IsInteractive == nil) then
			IsInteractive = true;
		end
		local autoRotateSpeed = self:GetNumber("AutoRotateSpeed")
		if(autoRotateSpeed == nil) then
			autoRotateSpeed = 0;
		end
		local lookAtHeight = self:GetNumber("LookAtHeight");
		
		
		local cameraObjectDist = self:GetNumber("CameraObjectDist");
		local renderTargetSize = self:GetNumber("RenderTargetSize") or 256;
		local miniSceneName = self:GetAttributeWithCode("miniscenegraphname");

		local _this = self.control;
		_this:SetIsActiveRendering(IsActiveRendering);
		_this:SetIsInteractive(IsInteractive);
		_this:SetAutoRotateSpeed(autoRotateSpeed);
		if (miniSceneName) then
			_this:SetMiniscenegraphname(miniSceneName.."_v2");
		end
		_this:SetLookAtHeight(lookAtHeight or 1.5);
		_this:SetDefaultCameraObjectDist(cameraObjectDist or 7);
		_this:SetRenderTargetSize(renderTargetSize, renderTargetSize);

		local filename = self:GetAttributeWithCode("assetfile");
		NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/PlayerAssetFile.lua");
		local PlayerAssetFile = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerAssetFile")
		PlayerAssetFile:Init();

		local obj_params = ObjEditor.GetObjectParams(ParaScene.GetPlayer());
		if (filename) then
			obj_params.AssetFile = PlayerAssetFile:GetValidAssetByString(filename);
		end

		NPL.load("(gl)script/apps/Aries/Creator/Game/PlayerController.lua");
		
		if(not obj_params.AssetFile or obj_params.AssetFile == "") then
			obj_params = {
				IsCharacter = true, 
				AssetFile = MyCompany.Aries.Game.PlayerController:GetMainAssetPath(),
				x = 0, y=0, z=0, facing=0,
				Attribute = 128,
			};
		end
		obj_params.name = "mc_player";
		self:AutoSetObjectSkin(obj_params)

		if(obj_params.ReplaceableTextures[2]) then
			local player = EntityManager.GetFocus();
			if(player and player.GetSkin) then
				obj_params.ReplaceableTextures[2] = player:GetSkin() or obj_params.ReplaceableTextures[2];
			end
		end
		
		obj_params.facing = 1.57;
		-- MESH_USE_LIGHT = 0x1<<7: use block ambient and diffuse lighting for this model. 
		obj_params.Attribute = 128;

		_this:ShowModel(obj_params);
	end

	pe_mc_player._super.OnLoadComponentBeforeChild(self, parentElem, parentLayout, css)	
end

function pe_mc_player:OnBeforeChildLayout(layout)
	if(#self ~= 0) then
		local myLayout = layout:new();
		local css = self:GetStyle();
		local width, height = layout:GetPreferredSize();
		local padding_left, padding_top = css:padding_left(),css:padding_top();
		myLayout:reset(padding_left,padding_top,width+padding_left, height+padding_top);
		self:UpdateChildLayout(myLayout);
		width, height = myLayout:GetUsedSize();
		width = width - padding_left;
		height = height - padding_top;
		layout:AddObject(width, height);
	end
	return true;
end

-- virtual function: 
-- after child node layout is updated
function pe_mc_player:OnAfterChildLayout(layout, left, top, right, bottom)
	if(self.control) then
		self.control:setGeometry(left, top, right-left, bottom-top);
	end
end

function pe_mc_player:AutoSetObjectSkin(obj_params)
	NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/PlayerSkins.lua");
	local PlayerSkins = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerSkins")
	obj_params.ReplaceableTextures = obj_params.ReplaceableTextures or {};
	if(not PlayerSkins:CheckModelHasSkin(obj_params.AssetFile)) then
		obj_params.ReplaceableTextures[2] = nil;
	else
		obj_params.ReplaceableTextures[2] = MyCompany.Aries.Game.PlayerController:GetSkinTexture();
	end
end
