--[[
Title: code behind for page KeepWorkSingleItem.html
Author(s): yangguiyi
Date: 2020/7/21
Desc:  script/apps/Aries/Creator/Game/KeepWork/KeepWorkSingleItem.html
Use Lib:
-------------------------------------------------------
    local KeepWorkSingleItem = NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWork/KeepWorkSingleItem.lua");
    KeepWorkSingleItem.ShowNotification()
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/PlayerAssetFile.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/PlayerSkins.lua");
local PlayerSkins = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerSkins");
local PlayerAssetFile = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerAssetFile")
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local KeepWorkMallPage = NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWork/KeepWorkMallPageV2.lua");
local KeepWorkSingleItem = NPL.export()

local startX,startY
function KeepWorkSingleItem.ShowNotification(item_data,posParams)
    echo(item_data)
    if not item_data then
        return 
    end
    startX,startY = posParams.x,posParams.y
    -- print("pos===========",startX,startY)
    KeepWorkSingleItem.item_data = item_data
	local _notification = ParaUI.GetUIObject("AriesNotification");
	if(_notification:IsValid() == false ) then
		_notification = ParaUI.CreateUIObject("container", "AriesNotification", "_lt", startX, startY, 170, 170);
		_notification.background = "";
		_notification.zorder = 13;
		_notification:AttachToRoot();
	end
	
	_notification.visible = true;
	
	local _ownerDrawCanvas = _notification:GetChild("OwnerDrawCanvas");
	if(_ownerDrawCanvas:IsValid() == true) then
		_ownerDrawCanvas:RemoveAll();
	end
	local _ownerDrawCanvas = _notification:GetChild("OwnerDrawCanvas");
    if(_ownerDrawCanvas:IsValid() == false) then
        _ownerDrawCanvas = ParaUI.CreateUIObject("container", "OwnerDrawCanvas", "_fi", 0, 0, -100, 0);
        _ownerDrawCanvas.background = "";
        _notification:AddChild(_ownerDrawCanvas);
    end
    _ownerDrawCanvas:RemoveAll();
    
    local NotificationPage = System.mcml.PageCtrl:new({url = "script/apps/Aries/Creator/Game/KeepWork/KeepWorkSingleItem.html"});
    NotificationPage:Create("AriesNotificationPage", _ownerDrawCanvas, "_fi", 0, 0, 0, 0);
	
	if _notification:IsValid() then
        -- local block = UIDirectAnimBlock:new();
        -- block:SetUIObject(_notification);
        -- block:SetTime(200);
        -- block:SetAlphaRange(0, 1);
        -- block:SetTranslationYRange(128, 0);
        -- block:SetApplyAnim(true); 
        -- UIAnimManager.PlayDirectUIAnimation(block);
        UIAnimManager.StopDirectAnimation(_notification)
        commonlib.TimerManager.SetTimeout(function()
            KeepWorkSingleItem.DoNotificationTimer()
        end, 100)
    end
end

function KeepWorkSingleItem.DoNotificationTimer()
	local _notification = ParaUI.GetUIObject("AriesNotification");
    if(_notification:IsValid() == true) then
        NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/QuickSelectBar.lua");
        local QuickSelectBar = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.QuickSelectBar");
        local destX,destY = QuickSelectBar.GetSelectControlPos()
        _notification.x = destX
        _notification.y = destY

        -- print("pos===========",destX,destY,startX,startY,destX-startX,destY - startY)
        local block = UIDirectAnimBlock:new();
        block:SetUIObject(_notification);
        block:SetTime(1200);
        block:SetAlphaRange(1, 0);
        block:SetXRange(startX,destX - 170/2 + 20) --缩放是以中心点缩放的，而位移是以左上角为中心点
        block:SetYRange(startY,destY - 170/2 + 20)
       
        block:SetScalingXRange(1, 0);
        block:SetScalingYRange(1, 0);
        block:SetApplyAnim(true); 
        block:SetCallback(function ()
            _notification.visible = false;
            KeepWorkSingleItem.item_data = nil
        end); 
        UIAnimManager.PlayDirectUIAnimation(block);
    end
end

function KeepWorkSingleItem.CanUserCanva3d()
    return KeepWorkMallPage.CanUseCanvas3dIcon(KeepWorkSingleItem.item_data)
end

function KeepWorkSingleItem.GetLiveModelXmlInfo()
    local item_data = KeepWorkSingleItem.item_data
    if item_data.isLiveModel then
        return item_data.xmlInfo
    end
end

function KeepWorkSingleItem.IsLiveModel()
    local item_data = KeepWorkSingleItem.item_data
    return item_data.isLiveModel
end

function KeepWorkSingleItem.IsSpecialModel()
    return KeepWorkMallPage.IsSpecialModel(KeepWorkSingleItem.item_data)
end

function KeepWorkSingleItem.GetModelFile()
    local item_data = KeepWorkSingleItem.item_data
    if item_data.isLiveModel then
		return nil
	else
		local good_data = item_data and item_data.goods_data and item_data.goods_data[1]
		local model_url = good_data and good_data.modelUrl or (item_data and item_data.modelUrl)
		local filename = ""
		if model_url and model_url:match("^https?://") then
			filename = item_data.tooltip
		elseif model_url and model_url:match("character/") then
			filename = model_url
		else
			return nil
		end
		local filepath = PlayerAssetFile:GetValidAssetByString(filename)
		if not filepath and filename then
			filepath = Files.GetTempPath()..filename
		end
	
		local ReplaceableTextures, CCSInfoStr, CustomGeosets;
	
		local skin = nil
		if skin then
			CustomGeosets = skin
		elseif(PlayerAssetFile:IsCustomModel(filepath)) then
			CCSInfoStr = PlayerAssetFile:GetDefaultCCSString()
		elseif(PlayerSkins:CheckModelHasSkin(filepath)) then
			-- TODO:  hard code worker skin here
			ReplaceableTextures = {[2] = PlayerSkins:GetSkinByID(12)};
		end
		return {
			AssetFile = filepath, IsCharacter=true, x=0, y=0, z=0,
			ReplaceableTextures=ReplaceableTextures, CCSInfoStr=CCSInfoStr, CustomGeosets = CustomGeosets
		}
	end
end

