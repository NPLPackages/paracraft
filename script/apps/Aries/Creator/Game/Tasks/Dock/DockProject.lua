--[[
    DockProject.lua
    Author: pbb
    Date: 2025-04-03
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Dock/DockLayer.lua")
local DockLayer = commonlib.gettable("MyCompany.Aries.Game.Tasks.DockLayer")
local DockProject = NPL.export()

local worldParams;
local currentId;
local isLiked = false;
local likeCount = 0;
local isFavorited= false;
local favoriteCount = 0;

local dock_config = {
    {name = "like", align = "_rt",  width=45,height=32, bg="Texture/Aries/Creator/keepwork/dock/meiyoudianzan_45x45_32bits.png#0 0 64 45",},
    {name = "favorite", align = "_rt",  width=45,height=32, bg="Texture/Aries/Creator/keepwork/dock/meiyoushoucang_45x45_32bits.png#0 0 64 45",},
    {name = "share", align = "_rt", width=45,height=32, bg="Texture/Aries/Creator/keepwork/dock/zhuanfa_45x45_32bits.png#0 0 64 45",},
}

function DockProject.Show()
    if DockProject.IsDockVisible() then
        DockProject.Hide()
        return
    end
    local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
	local kpProjectId = GameLogic.options:GetProjectId()
	kpProjectId = tonumber(kpProjectId);
	if (not kpProjectId) then return end
    DockProject.ShowDock()
    keepwork.world.detail({router_params = {id = kpProjectId}}, function(err, msg, data)
		if (data) then
            worldParams = data
			likeCount = data.star or 0;
			favoriteCount = data.favorite or 0;
		end
		keepwork.world.is_stared({router_params = {id = kpProjectId}}, function(err, msg, data)
			if (err == 200) then
				isLiked = data == true;
			end
			keepwork.world.is_favorited({objectId = kpProjectId, objectType = 5}, function(err, msg, data)
				if (err == 200) then
					isFavorited = data == true;
                    DockProject.UpdateNum()
				end
			end);
		end);
	end);
end

function DockProject.IsDockVisible()
    local _projecr_container = ParaUI.GetUIObject("DockProject.ProjectContainer");
    return _projecr_container and _projecr_container:IsValid()
end

function DockProject.ShowDock()
    local dianzan_dock = GameLogic.DockManager:GetDockByName("dianzan")
    if(not dianzan_dock) then
        return
    end
    local x,y,width,height = dianzan_dock:GetAbsPosition()
    local parent = DockLayer:GetParentLayer()
    if not parent or not parent:IsValid() then
        return
    end
    local _btn = ParaUI.GetUIObject("DockProject.OutClickSense");
    if not _btn or not _btn:IsValid() then
       _btn = ParaUI.CreateUIObject("button", "DockProject.OutClickSense", "_fi", 0, 0, 0, 0);
       _btn.background = "";
       _btn.zorder = -1;
       _btn:SetScript("onclick",function()
           DockProject.Hide()
       end)
   
       _btn:SetScript("onmousedown", function() 
           DockProject.Hide()
       end);
   
       _btn:SetScript("onmouseup", function() 
           DockProject.Hide()
       end);
       parent:AddChild(_btn);
    end

    local _projecr_container = ParaUI.GetUIObject("DockProject.ProjectContainer");
    if not _projecr_container or not _projecr_container:IsValid() then
        local posX = math.floor(x - width - 70)
        local posY = y + height + 16
        _projecr_container = ParaUI.CreateUIObject("container", "DockProject.ProjectContainer", "_lt", posX, posY, 180, 52);
        _projecr_container.background = "Texture/Aries/Creator/keepwork/dock/bg_32x32_32bits.png;0 0 32 32:14 14 14 14";
        parent:AddChild(_projecr_container);
    end
    _projecr_container:RemoveAll();
    local startX = 16
    local startY = 10
    for i, v in pairs(dock_config) do
        local x = startX + (i - 1)* 58
        local btn_dock = ParaUI.CreateUIObject("button", "DockProject."..v.name, "_lt", x, startY, v.width, v.height);
        btn_dock.background = v.bg
        _projecr_container:AddChild(btn_dock)
        if v.tooltip and v.tooltip~="" then
            btn_dock.tooltip =v.tooltip
        end
        if v.text and v.text ~="" then
            btn_dock.text = v.text
        end
        btn_dock:SetScript("onclick",function()
            DockProject.OnClick(v)
        end)
    end
end

function DockProject.OnClick(node)
    if not node then
        return
    end
    if node.name == "like" then
        DockProject.OnClickLike()
        GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.dock.like");
    elseif node.name == "favorite" then
        if isFavorited then
            DockProject.OnClickUnFavorite()
        else
            DockProject.OnClickFavorite()
        end
        GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.dock.favorite");
    elseif node.name == "share" then
        GameLogic.RunCommand("/menu share.video_or_panorama")
        DockProject.Hide()
        GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.dock.share");
    end
end

function DockProject.Hide()
    ParaUI.Destroy("DockProject.ProjectContainer")
    ParaUI.Destroy("DockProject.OutClickSense")
end


function DockProject.OnClickLike()
    if isLiked then
        return 
    end
    local kpProjectId = GameLogic.options:GetProjectId()
    if not kpProjectId or tonumber(kpProjectId) == 0 then
        return
    end
	keepwork.world.star({router_params = {id = kpProjectId}}, function(err, msg, data)
		if (err == 200) then
			isLiked = true;
            DockProject.UpdateNum()
		end
	end);
end

function DockProject.OnClickFavorite()
    local kpProjectId = GameLogic.options:GetProjectId()
    if not kpProjectId or tonumber(kpProjectId) == 0 then
        return
    end
	keepwork.world.favorite({objectId = kpProjectId, objectType = 5}, function(err, msg, data)
		if (err == 200) then
			isFavorited = true;
            DockProject.UpdateNum()
		end
	end);
end

function DockProject.OnClickUnFavorite()
    local kpProjectId = GameLogic.options:GetProjectId()
    if not kpProjectId or tonumber(kpProjectId) == 0 then
        return
    end
	keepwork.world.unfavorite({objectId = kpProjectId, objectType = 5}, function(err, msg, data)
		if (err == 200) then
			isFavorited = false;
            DockProject.UpdateNum()
		end
	end);
end

function DockProject.UpdateNum()
    local kpProjectId = GameLogic.options:GetProjectId()
    if not kpProjectId or tonumber(kpProjectId) == 0 then
        return
    end
    keepwork.world.detail({router_params = {id = kpProjectId}}, function(err, msg, data)
        if (data) then
            likeCount = data.star or 0;
            favoriteCount = data.favorite or 0;
            DockProject.SetLike(isLiked)
            DockProject.SetFavorite(isFavorited)
            DockProject.SetFavoriteNum(favoriteCount)
            DockProject.SetLikeNum(likeCount)
        end
    end);
end

function DockProject.SetLike(bLike) --点赞
    local like_dock = ParaUI.GetUIObject("DockProject.like")
    if like_dock and like_dock:IsValid() then
        local likeBg = "Texture/Aries/Creator/keepwork/dock/dianzan_45x45_32bits.png;0 0 64 45"
        if likeCount <= 0 then
            likeBg = "Texture/Aries/Creator/keepwork/dock/meiyoudianzan_45x45_32bits.png;0 0 64 45"
        end
        if bLike then
            likeBg= "Texture/Aries/Creator/keepwork/dock/dianliangdianzan_45x45_32bits.png;0 0 64 45"
        end
        like_dock.background = (likeBg)
    end
end

function DockProject.SetFavorite(bStar) --收藏
    local favorite_dock = ParaUI.GetUIObject("DockProject.favorite")
    if favorite_dock and favorite_dock:IsValid() then
        local favoriteBg = "Texture/Aries/Creator/keepwork/dock/shoucang_45x45_32bits.png;0 0 64 45"
        if favoriteCount <= 0 then
           favoriteBg = "Texture/Aries/Creator/keepwork/dock/meiyoushoucang_45x45_32bits.png;0 0 64 45" 
        end
        if bStar then
            favoriteBg = "Texture/Aries/Creator/keepwork/dock/dianliangshoucang_45x45_32bits.png;0 0 64 45"
        end
        favorite_dock.background = (favoriteBg)
    end
end

function DockProject.SetFavoriteNum(num)
    local text = num > 0 and string.format("%d", num) or ""
    local favorite_dock = ParaUI.GetUIObject("DockProject.favorite")
    if favorite_dock and favorite_dock:IsValid() then
        favorite_dock.text = text
        favorite_dock:SetField("TextOffsetX", -6)
        favorite_dock:SetField("TextOffsetY", 11)
        favorite_dock.font = "System;10;norm";
        _guihelper.SetFontColor(favorite_dock, "#ffffff");
    end
end

function DockProject.SetLikeNum(num)
    local text = num > 0 and string.format("%d", num) or ""
    local like_dock = ParaUI.GetUIObject("DockProject.like")
    if like_dock and like_dock:IsValid() then
        like_dock.text = text
        like_dock:SetField("TextOffsetX", -6)
        like_dock:SetField("TextOffsetY", 11)
        like_dock.font = "System;10;norm";
        _guihelper.SetFontColor(like_dock, "#ffffff");
    end
end