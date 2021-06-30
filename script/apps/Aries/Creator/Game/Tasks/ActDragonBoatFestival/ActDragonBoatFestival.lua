
--[[
Title: Act Dragon Boat Festival
Author(s): big
Date: 2021.6.8
Desc:  action page for dragon boat festival
Use Lib:
-------------------------------------------------------
local ActDragonBoatFestival = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ActDragonBoatFestival/ActDragonBoatFestival.lua");
ActDragonBoatFestival:Init();
--]]

local ActDragonBoatFestival = NPL.export()

ActDragonBoatFestival.data = {};

function ActDragonBoatFestival:Init()
    self:GetData(function(data, err)
        if (type(data) == "table") then
            self.data = data;
            self:Show();
        end
    end);
end

function ActDragonBoatFestival:Show()
    System.App.Commands.Call("File.MCMLWindowFrame", {
        url = "script/apps/Aries/Creator/Game/Tasks/ActDragonBoatFestival/ActDragonBoatFestival.html",
        name = "Tasks.ActDragonBoatFestival",
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        zorder = 0,
        allowDrag = false,
        bShow = nil,
        directPosition = true,
        align = "_ct",
        x = -912 / 2,
        y = -546 / 2,
        width = 912,
        height = 546,
        cancelShowAnimation = true,
        bToggleShowHide = true,
    });
end

function ActDragonBoatFestival:GetData(callback)
    GameLogic.GetFilters():apply_filters("api.keepwork.dragon_boat.process", callback);
end

function ActDragonBoatFestival:SetRice(callback)
    GameLogic.GetFilters():apply_filters("api.keepwork.dragon_boat.rice", callback);
end

function ActDragonBoatFestival:GetGifts(step, callback)
    GameLogic.GetFilters():apply_filters("api.keepwork.dragon_boat.gifts", step, callback, callback);
end
