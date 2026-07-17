--[[
Title: UserJobStatistics
Author(s): hyz
Date: 2022/2/18
Desc: 世界内用户操作行为统计

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/UserJobStatistics.lua");
local UserJobStatistics = commonlib.gettable("MyCompany.Aries.Game.Common.UserJobStatistics")
-------------------------------------------------------
]]

NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")


local UserJobStatistics = commonlib.gettable("MyCompany.Aries.Game.Common.UserJobStatistics")
local this = UserJobStatistics

function UserJobStatistics.OnInit()
    if UserJobStatistics.isInited then 
        return
    end
    UserJobStatistics.isInited = true
    GameLogic:Connect("WorldLoaded", UserJobStatistics, UserJobStatistics.OnWorldLoaded, "UniqueConnection");
    GameLogic:Connect("WorldUnloaded", UserJobStatistics, UserJobStatistics.OnWorldUnload, "UniqueConnection");
end

function UserJobStatistics.OnWorldLoaded()
    GameLogic.GetFilters():add_filter("DesktopModeChanged", UserJobStatistics.OnChangeDesktopMode);
    GameLogic.GetFilters():add_filter("create_block_event",UserJobStatistics.OnCreateBlock)
    GameLogic.GetCodeGlobal():RegisterKeyPressedEvent(UserJobStatistics.OnKeyPressed)
    
    this._info = {
        totalEditSeconds = WorldCommon.GetWorldTag("totalEditSeconds"),
        totalClicks = WorldCommon.GetWorldTag("totalClicks"),
        totalKeyStrokes = WorldCommon.GetWorldTag("totalKeyStrokes"),
        totalSingleBlocks = WorldCommon.GetWorldTag("totalSingleBlocks"),
    }
end

function UserJobStatistics.OnWorldUnload()
    GameLogic.GetFilters():remove_filter("DesktopModeChanged", UserJobStatistics.OnChangeDesktopMode);
    GameLogic.GetFilters():remove_filter("create_block_event",UserJobStatistics.OnCreateBlock)
    GameLogic.GetCodeGlobal():UnregisterKeyPressedEvent(UserJobStatistics.OnKeyPressed)
end

-- virtual: called when a desktop mode is changed such as from game mode to edit mode. 
-- return true to prevent further processing.
function UserJobStatistics.OnChangeDesktopMode(mode)
    local _isEditor = mode == "editor"
    if _isEditor then
        this.lastRecordTime = os.clock()
        this.openTimer_6000()
    else
        if this.lastRecordTime then --编辑还不满60秒就切模式了;也有可能不在焦点，乘0.8估算下
            this._addWorldInfoTagValue("totalEditSeconds",(os.clock() - this.lastRecordTime)*0.8)
            this.lastRecordTime = nil
        end
        this.openTimer_6000(false)
    end
    return mode
end

function UserJobStatistics.openTimer_6000(bOpen)
    if this.timer_5000 then
        this.timer_5000:Change()
    end
    if bOpen==false then 
        return
    end
    this.timer_5000 = this.timer_5000 or commonlib.Timer:new({callbackFunc = function(timer) --每隔5s检查一下是否在焦点
        local bAppHasFocus = ParaEngine.GetAttributeObject():GetField("AppHasFocus", true);
        if bAppHasFocus then
            this._addWorldInfoTagValue("totalEditSeconds",timer.delta/1000)
        end
        if this.lastRecordTime then
            this.lastRecordTime = nil
        end
    end})
    this.timer_5000:Change(0, 1000*5)
end

function UserJobStatistics.OnKeyPressed(_,msg)
    if GameLogic.GetMode()~="editor" then
        return
    end
    if msg.keyname=="mouse_wheel" 
        or msg.keyname=="DIK_LCONTROL" or  msg.keyname=="DIK_LSHIFT" or  msg.keyname=="DIK_RCONTROL" or  msg.keyname=="DIK_RSHIFT"
        or msg.keyname=="DIK_LALT" or msg.keyname=="DIK_RALT"
    then 
        return
    end
    if msg.keyname=="mouse_buttons" then --鼠标点击
        this._addWorldInfoTagValue("totalClicks",1)
    else --键盘点击
        this._addWorldInfoTagValue("totalKeyStrokes",1)
    end
end

function UserJobStatistics.OnCreateBlock(...)
    this._addWorldInfoTagValue("totalSingleBlocks",1)
    return ...
end

--val：change value
function UserJobStatistics._addWorldInfoTagValue(key,val)
    if this._info[key] then 
        this._info[key] = this._info[key] + val
        WorldCommon.SetWorldTag(key,this._info[key])
    end
end

--清理以前的数据（集锦视频发版之前已经有很多数据了，清理掉并备份）
function UserJobStatistics.clear()
    -- local old_score = WorldCommon.GetWorldInfo():GetTotalWorkScore() or 0
    -- WorldCommon.SetWorldTag("totalWorkScore_bak",old_score)
    -- local arr = {
    --     "totalClicks",
    --     "totalKeyStrokes",
    --     "totalSingleBlocks",
    --     "totalEditSeconds",
    -- }
    -- for k,key in pairs(arr) do
    --     this._info[key] = 0
    --     WorldCommon.SetWorldTag(key,this._info[key])
    -- end
    -- WorldCommon.SaveWorldTag()
end

return UserJobStatistics