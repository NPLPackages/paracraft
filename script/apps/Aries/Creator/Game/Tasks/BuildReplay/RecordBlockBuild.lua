--[[
Title: 建造世界过程中，记录玩家方块操作，并标记的热点区域
Author(s): hyz
Date: 2022/7/11
Desc: 划分区域，记录每个区域内鼠标操作的点击次数，记为热力值，后边选取热力值最大的进行回放
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BuildReplay/RecordBlockBuild.lua");
local RecordBlockBuild = commonlib.gettable("MyCompany.Aries.Game.Tasks.BuildReplay.RecordBlockBuild");
RecordBlockBuild:Init()
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/SelectionManager.lua");
local SelectionManager = commonlib.gettable("MyCompany.Aries.Game.SelectionManager");

NPL.load("(gl)script/apps/Aries/Creator/Game/block_engine.lua");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SelectBlocksTask.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/BlockTemplatePage.lua");
local BlockTemplatePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.BlockTemplatePage");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityManager.lua");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityCamera.lua");
local EntityCamera = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityCamera")
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/block_types.lua");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BlockTemplateTask.lua");
local BlockTemplate = commonlib.gettable("MyCompany.Aries.Game.Tasks.BlockTemplate");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TaskManager.lua");
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local ReplayManager = commonlib.gettable("MyCompany.Aries.Game.Tasks.BuildReplay.ReplayManager");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");

local SelectBlocks = commonlib.gettable("MyCompany.Aries.Game.Tasks.SelectBlocks");

local RecordBlockBuild = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Tasks.BuildReplay.RecordBlockBuild"));
local _regionSize = 16 --每个划分区域的大小

local MIN_HOT_THRESHOLD = 50 --最小阈值
local MAX_TEMPLATE_NUM = 5; --最多记录几个template模板
local MIN_BLOCK_NUM = 50 --最少要有几个方块才算目标建筑
local BLOCK_FPS = 1000/30 --Game.FrameMove的刷新是30毫秒
local TIME_SPEED = 1 --默认一次刷新生成多少块
local MAX_TIME = 5 --一个动画的最大时间
local lookAroundTime = 1 --生成完以后环视一周的时间

function RecordBlockBuild.SetConfig(config)
    config = config or {}
    if config.MIN_HOT_THRESHOLD then
        MIN_HOT_THRESHOLD = config.MIN_HOT_THRESHOLD
    end
    if config.MAX_TEMPLATE_NUM then
        MAX_TEMPLATE_NUM = config.MAX_TEMPLATE_NUM
    end
    if config.MIN_BLOCK_NUM then
        MIN_BLOCK_NUM = config.MIN_BLOCK_NUM
    end
    if config.TIME_SPEED then
        TIME_SPEED = config.TIME_SPEED
    end
    if config.MAX_TIME then
        MAX_TIME = config.MAX_TIME
    end
end

local _startClock = nil
local _lastClock = nil
local function _logClock(tag)
    if true then
        return
    end
    local _now = os.clock()
    if _lastClock then
        print(string.format("curClock:%s,%s,execClock:%s,allExecClock:%s",math.floor(_now*100)/100,tag or "",math.floor((_now-_lastClock)*100)/100,math.floor((_now-_startClock)*100)/100))
    else
        _startClock = _now
        print(string.format("curClock:%s,%s",math.floor(_now*100)/100,tag or ""))
    end
    _lastClock = _now
end

--每次进世界调用
function RecordBlockBuild:OnEnterWorld()
    self._hotValMap = {} --统计热力区域
    self._minYs = {} --记录每个区域的操作的最小y坐标
    self._maxYs = {} --记录每个区域的操作的最大y坐标
    self._averageCenter = {} --记录区域内每次操作的坐标的平均值(select方块时如有多个离散建筑，只取热点中心附近的那一个)
    self._Buildings = {}
    RecordBlockBuild._isPlaying = nil
    self:_loadHistory()
    
    if self._camera then
        self._camera = nil
    end

    local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
	local generatorName = WorldCommon.GetWorldTag("world_generator")
    self._IsMiniWorld = generatorName == "paraworldMini"
    self._IsSuperflatWorld = generatorName == "superflat"
end

function RecordBlockBuild:OnExitWorld()
    self:_saveHistory()
    if self._movieTimer then
        self._movieTimer:Change()
        self._movieTimer = nil
    end
    print("RecordBlockBuild:OnExitWorld")
end

function RecordBlockBuild.OnMouseReleaseEvent(_,event)
    if not ReplayManager:IsRecording() then
        return
    end
    if GameLogic.GetGameMode()~="edit" then
        return
    end
    local result = SelectionManager:GetPickingResult()
    local bx,by,bz = result.bx,result.by,result.bz
    if bx==nil then
        return _,event
    end
    -- echo(result)
    -- GameLogic.AddBBS(nil,string.format("blockSide:%s,side:%s",result.blockSide,result.side))
    commonlib.TimerManager.SetTimeout(function()
        RecordBlockBuild:_markAreaByPoint(bx,by,bz,result.side)
    end,0)
    
    return _,event
end

--[[
    根据鼠标操作的点，标记该区域的热力值
    每个区域是16x16
    side: 0:x负 1:x正 2:z负 3:z正 4:y负 5:y正
]]
function RecordBlockBuild:_markAreaByPoint(bx,by,bz,side)
    local blockId = BlockEngine:GetBlockId(bx,by,bz)
    if blockId==0 then --删除的不记录
        return
    end
    -- GameLogic.AddBBS(nil,string.format("鼠标松开 (%s,%s,%s).ID=%s",bx,by,bz,blockId))
    
    local id = string.format("%s,%s",math.floor(bx/_regionSize),math.floor(bz/_regionSize))
    local count = (self._hotValMap[id] or 0) + 1
    self._hotValMap[id] = count
    if side==5 then
        by = by + 1 --很关键，避免记录草地上的
    end
    if self._minYs[id]==nil then
        self._minYs[id] = by 
        self._maxYs[id] = by 
        self._averageCenter[id] = {bx,by,bz, bx,by,bz, 1}
    else
        self._minYs[id] = math.min(self._minYs[id],by)
        self._maxYs[id] = math.max(self._maxYs[id],by)

        if self._averageCenter[id]==nil then
            self._averageCenter[id] = {bx,by,bz, bx,by,bz, 1}
        end

        self._averageCenter[id][1] = math.floor(((self._averageCenter[id][1] or bx)*(count-1)+bx)/count*1000)/1000
        self._averageCenter[id][2] = math.floor(((self._averageCenter[id][2] or by)*(count-1)+by)/count*1000)/1000
        self._averageCenter[id][3] = math.floor(((self._averageCenter[id][3] or bz)*(count-1)+bz)/count*1000)/1000

    end
end

local xmlSavePath = "block_hotVal_map.xml";
function RecordBlockBuild:_saveHistory()
    if GameLogic.GetGameMode()~="edit" then
        return
    end
    if self._hotValMap==nil then
        return
    end
    local stats_folder = GameLogic.GetWorldDirectory().."stats/"
    if not ParaIO.DoesFileExist(stats_folder) then
        ParaIO.CreateDirectory(stats_folder)
    end
	local filename = stats_folder..xmlSavePath;
	local root = {name='block_hotVal_map', attr={file_version="0.1"} }
    for id,v in pairs(self._hotValMap) do
        root[#root+1] = {
            name = "value",
            attr = {id = id,minY = self._minYs[id],maxY = self._maxYs[id], hotVal = v, center=string.format("%s,%s,%s",self._averageCenter[id][1] or "",self._averageCenter[id][2] or "",self._averageCenter[id][3] or "")}
        }
    end
	local xml_data = commonlib.Lua2XmlString(root, true, true) or "";
    local writer = ParaIO.CreateZip(filename, "");
    if (writer:IsValid()) then
        writer:ZipAddData("data", xml_data);
        writer:close();
    end
	
	return true;
end

function RecordBlockBuild:_loadHistory()
    if(GameLogic.isRemote) then
        return
    end

    local function LoadFromHistoryFile_(filename)
        local xmlRoot = ParaXML.LuaXML_ParseFile(filename);
        if(xmlRoot) then
            local arr = commonlib.XPath.selectNodes(xmlRoot, "/block_hotVal_map");
            if arr and arr[1] then
                local list = arr[1]
                for k,v in ipairs(list) do
                    local obj = v.attr
                    self._hotValMap[obj.id] = tonumber(obj.hotVal)
                    self._minYs[obj.id] = tonumber(obj.minY)
                    self._maxYs[obj.id] = tonumber(obj.maxY)
                    local cx,cy,cz = unpack(commonlib.split(obj.center,","))
                    -- print("=====cx,cy,cz",cx,cy,cz)
                    self._averageCenter[obj.id] = {tonumber(cx),tonumber(cy),tonumber(cz)}
                end
            end
            return true
        end	
    end

    local stats_folder = GameLogic.GetWorldDirectory().."stats/"
	local filename = stats_folder..xmlSavePath

    if GameLogic.GetGameMode()=="edit" then
        if not ParaIO.DoesFileExist(filename) and not ParaIO.DoesFileExist(GameLogic.GetWorldDirectory()..xmlSavePath) then --第一次更新到视频集锦这里，先清空以前统计的totalWorkScore信息
            NPL.load("(gl)script/apps/Aries/Creator/Game/Common/UserJobStatistics.lua");
            local UserJobStatistics = commonlib.gettable("MyCompany.Aries.Game.Common.UserJobStatistics")
            UserJobStatistics.clear()
        end
    end

    if GameLogic.IsReadOnly() then
        if not LoadFromHistoryFile_(filename) then
            LoadFromHistoryFile_(GameLogic.GetWorldDirectory()..xmlSavePath)
        end
    else
        if not ParaIO.DoesFileExist(stats_folder) then
            ParaIO.CreateDirectory(stats_folder)
        end
        
        if not ParaIO.DoesFileExist(filename) and ParaIO.DoesFileExist(GameLogic.GetWorldDirectory()..xmlSavePath) then
            ParaIO.MoveFile(GameLogic.GetWorldDirectory()..xmlSavePath,filename)
        end
        
        LoadFromHistoryFile_(filename)
    end
end

--[[
    根据标记的数据，找到热力值达标的区域，识别出用户建造的方块建筑
]]
function RecordBlockBuild:SearchHotBuildings()
    if self._hotValMap==nil then
        self:OnEnterWorld()
        if self._hotValMap==nil then
            self._Buildings = {}
            return self._Buildings
        end
    end
    _logClock()
    local areaIds = {} --记录每个达标的热点区域
    local areaRects = {} --合并后的热点区域

    local idArr = {}
    for id,v in pairs(self._hotValMap) do
        table.insert(idArr,id)
    end
    table.sort(idArr,function(a,b)
        return self._hotValMap[a]>self._hotValMap[b]
    end)

    --按照热力值排序，找出最大的几个区域
    for i=1,#idArr do
        local id = idArr[i]
        local hot = self._hotValMap[id]
        if hot>=MIN_HOT_THRESHOLD then
            areaIds[id] = id
            -- print("=======areaId",id)
        end
    end

    local temp = {}
    
    --合并相邻的区域
    local key = next(areaIds)
    while key do
        temp[key] = true
        local out = {key} --记录相邻的area
        _logClock("---start 相邻area,"..key)
        self:_checkMergeAreas(key,areaIds,out,temp)
        _logClock("---end 相邻area,"..key)
        -- print("-----------合并:",key,"=>",table.concat(out," | "))

        local min_x,min_y,min_z = 99999999,99999999,99999999
        local max_x,max_y,max_z = 0,0,0
        local cx,cy,cz,hot = nil,nil,nil,nil
        for k,id in ipairs(out) do
            local bx,bz = unpack(commonlib.split(id,","))
            bx,bz = tonumber(bx)*_regionSize,tonumber(bz)*_regionSize
            min_x = math.min(min_x,bx)
            min_z = math.min(min_z,bz)
            min_y = math.min(min_y,self._minYs[id])

            max_x = math.max(max_x,bx + _regionSize-1)
            max_z = math.max(max_z,bz + _regionSize-1)
            max_y = math.max(max_y,self._maxYs[id])

            if self._IsSuperflatWorld then
                min_y = 5
            elseif self._IsMiniWorld then
                min_y = 12
            end

            if hot==nil then
                hot = self._hotValMap[id]
                cx,cy,cz = self._averageCenter[id][1],self._averageCenter[id][2],self._averageCenter[id][3]
            else
                if self._hotValMap[id]>hot then
                    hot = self._hotValMap[id]
                    cx,cy,cz = self._averageCenter[id][1],self._averageCenter[id][2],self._averageCenter[id][3]
                end
            end
        end
        -- print("=======ddddddd cx,cy,cz",cx,cy,cz)
        -- echo(out,true)
        table.insert(areaRects,{min_x,min_y,min_z, max_x,max_y,max_z, cx,cy,cz,hot,key,out})
        key = next(areaIds,key)
    end

    self._Buildings = {}
    for k,v in pairs(areaRects) do
        -- print("===============areaRects k:",k,"v:",unpack(v))
        local obj = self:_searchAndSaveBlocksOfAreaRect(v)
        if obj then
            table.insert(self._Buildings,obj)
        end
    end
    table.sort(self._Buildings,function(a,b)
        return a.count>b.count
    end)
    print("======self._Buildings",#self._Buildings)
    -- echo(self._Buildings,true)
    
    
    return self._Buildings
    
end

--[[
    idx==nil 播放所有的建造动画
    idx不为nil，播放指定索引
]]
function RecordBlockBuild:PlayBuildAnimations(idx,onCompleted,onStartPlayOne)
    if #self._Buildings==0 then
        if onCompleted then
            onCompleted()
        end
        return
    end
    
    local old_focus = GameLogic.EntityManager.GetFocus()
    local old_dist, old_pitch, old_yaw = ParaCamera.GetEyePos();

    local function _callback()
        if old_focus and old_focus==GameLogic.EntityManager.GetPlayer() then
            old_focus:SetFocus()
            ParaCamera.SetEyePos(old_dist, old_pitch, old_yaw)
        end
        if onCompleted then
            onCompleted()
        end
    end

    if idx and self._Buildings[idx] then
        local obj = self._Buildings[idx]
        self:PlayOneBuildAni(obj,_callback)
        return
    end

    while #self._Buildings>MAX_TEMPLATE_NUM do
        table.remove(self._Buildings,#self._Buildings)
    end

    local _playOne
    _playOne = function()
        if #self._Buildings==0 then
            _callback()
            return
        end
        local obj = table.remove(self._Buildings,1)
        self:PlayOneBuildAni(obj,_playOne)
        if onStartPlayOne then
            onStartPlayOne(obj)
        end
    end
    _playOne()
end

--判断两个相邻的区域是否真的建筑相邻
function RecordBlockBuild:_isAdjacent(mainAreaId,subAreaId,dirX,dirZ)
    local hasHot = self._hotValMap[subAreaId]
    if not hasHot then
        return false 
    end
    
    local bx_1,bz_1 = unpack(commonlib.split(mainAreaId,",")) 
    local bx_2,bz_2 = unpack(commonlib.split(subAreaId,","))

    bx_1,bz_1 = tonumber(bx_1)*_regionSize,tonumber(bz_1)*_regionSize
    bx_2,bz_2 = tonumber(bx_2)*_regionSize,tonumber(bz_2)*_regionSize

    local minY = math.max(self._minYs[mainAreaId],self._minYs[subAreaId])
    local maxY = math.min(self._maxYs[mainAreaId],self._maxYs[subAreaId])

    local blockId
    if dirX==0 then
        if dirZ==1 then --上边界墙是否有连接
            for i=0,_regionSize-1 do
                for j=minY,maxY do
                    blockId = BlockEngine:GetBlockId(bx_1+i,j,bz_2)
                    if blockId~=0 and blockId==BlockEngine:GetBlockId(bx_1+i,j,bz_2-1) then
                        -- print("--------上相邻:",mainAreaId,subAreaId)
                        -- print(string.format("main:(%s,%s,%s)=>%s",bx_1+i,j,bz_2,blockId))
                        -- print(string.format("subb:(%s,%s,%s)=>%s",bx_1+i,j,bz_2-1,BlockEngine:GetBlockId(bx_1+i,j,bz_2-1)))
                        return true
                    end
                end
            end
        elseif dirZ==-1 then --下边界墙是否有连接
            for i=0,_regionSize-1 do
                for j=minY,maxY do
                    blockId = BlockEngine:GetBlockId(bx_1+i,j,bz_1)
                    if blockId~=0 and blockId==BlockEngine:GetBlockId(bx_1+i,j,bz_1-1) then
                        -- print("--------下相邻:",mainAreaId,subAreaId)
                        -- print(string.format("main:(%s,%s,%s)=>%s",bx_1+i,j,bz_1,blockId))
                        -- print(string.format("subb:(%s,%s,%s)=>%s",bx_1+i,j,bz_1-1,BlockEngine:GetBlockId(bx_1+i,j,bz_1-1)))
                        return true
                    end
                end
            end
        end
    elseif dirZ==0 then
        if dirX==1 then --右边界墙
            for k=0,_regionSize-1 do
                for j=minY,maxY do
                    blockId = BlockEngine:GetBlockId(bx_2,j,bz_2+k)
                    if blockId~=0 and blockId==BlockEngine:GetBlockId(bx_2-1,j,bz_2+k) then
                        -- print("--------右相邻:",mainAreaId,subAreaId)
                        -- print(string.format("main:(%s,%s,%s)=>%s",bx_2,j,bz_2+k,blockId))
                        -- print(string.format("subb:(%s,%s,%s)=>%s",bx_2-1,j,bz_2+k,BlockEngine:GetBlockId(bx_2-1,j,bz_2+k)))
                        return true
                    end
                end
            end
        elseif dirX==-1 then --左边界墙
            for k=0,_regionSize-1 do
                for j=minY,maxY do
                    blockId = BlockEngine:GetBlockId(bx_1,j,bz_2+k)
                    if blockId~=0 and blockId==BlockEngine:GetBlockId(bx_1-1,j,bz_2+k) then
                        -- print("--------左相邻:",mainAreaId,subAreaId)
                        -- print(string.format("main:(%s,%s,%s)=>%s",bx_1,j,bz_2+k,blockId))
                        -- print(string.format("subb:(%s,%s,%s)=>%s",bx_1-1,j,bz_2+k,BlockEngine:GetBlockId(bx_1-1,j,bz_2+k)))
                        return true
                    end
                end
            end
        end
    end

    xxssdd = nil
    
    return false
end

--合并相邻的区域
function RecordBlockBuild:_checkMergeAreas(id,areaIds,out,temp)
    local bx,bz = unpack(commonlib.split(id,","))
    bx,bz = tonumber(bx),tonumber(bz)
    for i=-1,1,2 do
        local key = string.format("%s,%s",bx + i ,bz)
        if not temp[key] and self:_isAdjacent(id,key,i,0) then
            if areaIds[key] then
                areaIds[key] = nil 
            end
            table.insert(out,key)
            temp[key] = true

            self:_checkMergeAreas(key,areaIds,out,temp)
        end
    end

    for i=-1,1,2 do
        local key = string.format("%s,%s",bx,bz + i)
        if  not temp[key] and self:_isAdjacent(id,key,0,i) then
            if areaIds[key] then
                areaIds[key] = nil 
            end
            table.insert(out,key)
            temp[key] = true
            self:_checkMergeAreas(key,areaIds,out,temp)
        end
    end
end

local _acc = 0
local function _mark(_x,_y,_z,map,out,arr)
    local key = string.format("%s,%s,%s",_x,_y,_z)
    if map[key] then
        table.insert(out,map[key])
        map[key] = nil
        table.insert(arr,{_x,_y,_z})
    end
    _acc = _acc + 1
end

local cx,cy,cz
local function _tempDis(out)
    cx,cy,cz = 0,0,0
    for _,obj in ipairs(out) do
        cx = cx + obj[1]
        cy = cy + obj[2]
        cz = cz + obj[3]
    end
    if #out>0 then
        cx = cx / #out
        cy = cy / #out
        cz = cz / #out
    end
    out.dis = (cx-RecordBlockBuild.search_CX)*(cx-RecordBlockBuild.search_CX)+(cy-RecordBlockBuild.search_CY)*(cy-RecordBlockBuild.search_CY)+(cz-RecordBlockBuild.search_CZ)*(cz-RecordBlockBuild.search_CZ)
    return out.dis
end

--从map里递归查询相邻的方块，存到out
function RecordBlockBuild._search(x,y,z,map,out,dir,deep)
    if deep>500 then --防止递归深度过大引起报错
        return deep
        -- print("----deep",deep)
    end
    if RecordBlockBuild.search_disMin then
        if #out>math.max(math.min(2*RecordBlockBuild.search_tempBlockNum,200),100) then --找[100,200]个方块，看看距离中心是不是比较远，是的话就不继续递归了
            if _tempDis(out)>RecordBlockBuild.search_disMin then
                return deep
            end
        end
    end
    local arr,i,j,k,key
    if dir~="-1,0,0" then
        --x正方向锥面
        arr = {}
        i = 1
        for j=-math.abs(i),math.abs(i) do
            for k=-math.abs(i),math.abs(i) do
                _mark(x+i,y+j,z+k,map,out,arr)
            end
        end
        for i=1,#arr do
            deep = math.max(deep,RecordBlockBuild._search(arr[i][1],arr[i][2],arr[i][3],map,out,"1,0,0",deep+1))
        end
    end

    if dir~="1,0,0" then
        --x负方向锥面
        arr = {}
        i = -1
        for j=-math.abs(i),math.abs(i) do
            for k=-math.abs(i),math.abs(i) do
                _mark(x+i,y+j,z+k,map,out,arr)
            end
        end
        for i=1,#arr do
            deep = math.max(deep,RecordBlockBuild._search(arr[i][1],arr[i][2],arr[i][3],map,out,"-1,0,0",deep+1))
        end
    end
    if dir~="0,-1,0" then
        --y正方向锥面
        arr = {}
        j = 1
        for i=-math.abs(j),math.abs(j) do
            for k=-math.abs(j),math.abs(j) do
                _mark(x+i,y+j,z+k,map,out,arr)
            end
        end
        for i=1,#arr do
            deep = math.max(deep,RecordBlockBuild._search(arr[i][1],arr[i][2],arr[i][3],map,out,"0,1,0",deep+1))
        end
    end
    if dir~="0,1,0" then
        --y负方向锥面
        arr = {}
        j = -1
        for i=-math.abs(j),math.abs(j) do
            for k=-math.abs(j),math.abs(j) do
                _mark(x+i,y+j,z+k,map,out,arr)
            end
        end
        for i=1,#arr do
            deep = math.max(deep,RecordBlockBuild._search(arr[i][1],arr[i][2],arr[i][3],map,out,"0,-1,0",deep+1))
        end
    end
    if dir~="0,0,-1" then
        --z正方向锥面
        arr = {}
        k = 1
        for i=-math.abs(k),math.abs(k) do
            for j=-math.abs(k),math.abs(k) do
                _mark(x+i,y+j,z+k,map,out,arr)
            end
        end
        for i=1,#arr do
            deep = math.max(deep,RecordBlockBuild._search(arr[i][1],arr[i][2],arr[i][3],map,out,"0,0,1",deep+1))
        end
    end
    if dir~="0,0,1" then
        --z负方向锥面
        arr = {}
        k = -1
        for i=-math.abs(k),math.abs(k) do
            for j=-math.abs(k),math.abs(k) do
                _mark(x+i,y+j,z+k,map,out,arr)
            end
        end
        for i=1,#arr do
            deep = math.max(deep,RecordBlockBuild._search(arr[i][1],arr[i][2],arr[i][3],map,out,"0,0,-1",deep+1))
        end
    end
    
    
    key = string.format("%s,%s,%s",x,y,z)
    if map[key] then
        table.insert(out,map[key])
        map[key] = nil
    end

    return deep
end

local function _getNearestBlock(keys)
    local _key = nil --从离热点中心最近的点开始找
    local min_dis,dis = 9999999999
    for k,obj in pairs(keys) do
        dis = (obj[1]-RecordBlockBuild.search_CX)*(obj[1]-RecordBlockBuild.search_CX)+(RecordBlockBuild.search_CY-obj[2])*(RecordBlockBuild.search_CY-obj[2])+(RecordBlockBuild.search_CZ-obj[3])*(RecordBlockBuild.search_CZ-obj[3])
        if dis<min_dis then
            min_dis = dis
            _key = k
        end
    end
    return _key
end

--[[
    找到区域内热点建筑（剔除掉非热点建筑方块，并需要判断相邻区域有无相连的方块）
    并且保存为template
    return {
        filename = filename, --保存的文件名
        blocks = blocks, --方块
        pivot = pivot,--存模型的锚点（再次load模型时的位置）

        meanCenter = {meanCX,meanCY,meanCZ}, --估算的中心点
        radius = radius, --水平方向上，以meanCenter为中心点的最小包围半径
        count = #blocks, --方块数量
        minPos = {min_x,min_y,min_z}, --包围盒起点
        maxPos = {max_x,max_y,max_z}, --包围盒终点
    }
]]
function RecordBlockBuild:_searchAndSaveBlocksOfAreaRect(param)
    local minX,minY,minZ, maxX,maxY,maxZ, centerX,centerY,centerZ,hot,areaId,areaIds = unpack(param)

    local keys = {}
    for x=minX,maxX do
        for y=minY,maxY do
            for z=minZ,maxZ do
                local blockId = BlockEngine:GetBlockId(x,y,z)
                if blockId~=0 then
                    keys[string.format("%s,%s,%s",x,y,z)] = {x,y,z,blockId}
                end
            end
        end
    end

    --这三个参数是给搜索的时候剪枝用
    RecordBlockBuild.search_CX = centerX
    RecordBlockBuild.search_CY = centerY
    RecordBlockBuild.search_CZ = centerZ
    RecordBlockBuild.search_disMin = nil
    RecordBlockBuild.search_tempBlockNum = nil

    --从离热点中心最近的点开始找
    local _key = _getNearestBlock(keys)

    local outs = {}--分割成几段离散的方块堆
    local obj
    local totalAcc = 0
    while _key do
        obj = keys[_key]
        local out = {}
        local x,y,z = obj[1],obj[2],obj[3]
        -- print("------x,y,z：",x,y,z)
        _acc = 0

        _logClock(string.format("---start _search,%s",key))
        local deep = 0
        deep = RecordBlockBuild._search(x,y,z,keys,out,nil,deep)
        _logClock(string.format("---end _search,%s",key))
        -- print("#out",#out,"deep",deep)
        if #out>=MIN_BLOCK_NUM then
            table.insert(outs,out)
            -- print("count:",#out,"计算次数",_acc)
            totalAcc = totalAcc + _acc
            if totalAcc>=50000 then
                break
            end

            out.dis = _tempDis(out)
            if RecordBlockBuild.search_tempBlockNum==nil or RecordBlockBuild.search_tempBlockNum>out.dis then
                RecordBlockBuild.search_disMin = out.dis
                RecordBlockBuild.search_tempBlockNum = #out
            end
        end

        _key = _getNearestBlock(keys)
    end
    
    local min_distance,ret,dis = 9999999999,nil,nil
    for k,out in pairs(outs) do --遍历找出来的方块堆，找到离热力中心最近的那一堆
        
        if out.dis and out.dis<min_distance then
            min_distance = out.dis
            ret = out
        end
        -- print("=========k",k,#out,"dis",out.dis)
    end
    
    --将找出来的方块堆存成template
    if ret and #ret>1 then
        ret.dis = nil
        local min_x,min_y,min_z = 99999999,99999999,99999999
        local max_x,max_y,max_z = 0,0,0
        local meanCX,meanCY,meanCZ = 0,0,0  --估算template中心锚点
        for k,v in ipairs(ret) do
            local x,y,z = v[1],v[2],v[3]
            
            min_x = math.min(min_x,x)
            min_z = math.min(min_z,z)
            min_y = math.min(min_y,y)

            max_x = math.max(max_x,x)
            max_z = math.max(max_z,z)
            max_y = math.max(max_y,y)

            meanCX = meanCX + x
            meanCZ = meanCZ + z
            -- BlockEngine:SetBlock(x,y,z,6)
        end
        meanCX = math.floor(meanCX/#ret)
        meanCZ = math.floor(meanCZ/#ret)
        meanCY = math.floor(min_y)

        -- if self._IsSuperflatWorld then
        --     min_y = 5
        -- elseif self._IsMiniWorld then
        --     min_y = 12
        -- end

        local cmd = string.format("/select %s %s %s (%s %s %s)",min_x,min_y,min_z,max_x-min_x,max_y-min_y,max_z-min_z)
        -- print("=========cmd",cmd)
        GameLogic.RunCommand(cmd)
        local select_task = SelectBlocks.GetCurrentInstance();
        local count = #(SelectBlocks.GetSelectedBlocks() or {})
        -- print("-----count",count)
        while count>8000 do
            if max_y-min_y>30 then
                min_y = max_y - 30
            elseif max_y-min_y>10 then
                min_y = min_y + 1
            end
            if max_x-min_x>30 then
                min_x = max_x - 30
            elseif max_x-min_x>10 then
                min_x = min_x + 1
            end
            if max_z-min_z>30 then
                min_z = max_z - 30
            elseif max_z-min_z>10 then
                min_z = min_z + 1
            end
            SelectBlocks.CancelSelection();
            TaskManager.RemoveTask(select_task)

            cmd = string.format("/select %s %s %s (%s %s %s)",min_x,min_y,min_z,max_x-min_x,max_y-min_y,max_z-min_z)
            GameLogic.RunCommand(cmd)
            select_task = SelectBlocks.GetCurrentInstance();
            count = #(SelectBlocks.GetSelectedBlocks() or {})
            -- print("=========cmd",cmd)
            -- print("-----count",count)
        end

        local pivot = select_task:GetPivotPoint();
        local blocks = SelectBlocks.GetSelectedBlocks() or {}

        --判断一下，玩家有在地平线以下操作时，大致去掉默认的草地方块（可能会有误差）
        for i=#blocks,1,-1 do
            local v = blocks[i]
            if self._IsSuperflatWorld and v[2]<=4  then --and (v[4]==62 or v[4]==55)
                table.remove(blocks,i)
            elseif self._IsMiniWorld and v[2]<=11  then --and (v[4]==62 or v[4]==55)
                table.remove(blocks,i)
            end
        end

        local copyBlocks = select_task:GetCopyOfBlocks(pivot)
        local x, y, z = ParaScene.GetPlayer():GetPosition();
		local bx, by, bz = BlockEngine:block(x,y,z)
		local player_pos = string.format("%d,%d,%d",bx,by,bz);

        SelectBlocks.CancelSelection();
        TaskManager.RemoveTask(select_task)
        print("#copyBlocks",#copyBlocks)
        local filename = string.format("%s/%s_%s.blocks.xml",ParaIO.GetWritablePath().."temp/temp_templates",GameLogic.getCurrentWorldId() or "",areaId)
        -- print("=======filename",filename,"pivot",string.format("%d,%d,%d",pivot[1],pivot[2],pivot[3]))
        BlockTemplatePage.SaveToTemplate(filename,copyBlocks,{
            name = areaId,
			author_nid = System.User.nid,
			creation_date = ParaGlobal.GetDateFormat("yyyy-MM-dd").."_"..ParaGlobal.GetTimeFormat("HHmmss"),
			player_pos = player_pos,
			pivot = string.format("%d,%d,%d",pivot[1],pivot[2],pivot[3]),
			relative_motion = false,
			hollow = false,
			exportReferencedFiles = false,
        },function() end, false, true, nil)

        local radius = 0;
        local xArr,zArr = {min_x,max_x},{min_z,max_z}
        for i=1,#xArr do
            for j=1,#zArr do
                local dis = (meanCX-xArr[i])*(meanCX-xArr[i])+(meanCZ-zArr[j])*(meanCZ-zArr[j])
                if dis>radius then
                    radius = dis
                end
            end
        end
        radius = math.sqrt(radius)
        -- print("======radius",math.sqrt(radius))
        return {
            filename = filename,
            blocks = blocks,
            pivot = pivot,

            meanCenter = {meanCX,meanCY,meanCZ}, --估算的中心点
            radius = radius,
            count = #blocks,
            minPos = {min_x,min_y,min_z},
            maxPos = {max_x,max_y,max_z},
            areaIds = areaIds
        }
    end
    _logClock("结束")
end

function RecordBlockBuild:_createOrGetCamera()
    local _camera = RecordBlockBuild._camera
    if _camera==nil then
        _camera = EntityCamera:Create({item_id = block_types.names.TimeSeriesCamera});
        RecordBlockBuild._camera = _camera
        _camera:SetPersistent(false);
		_camera:Attach();
    end
    return _camera
end

function RecordBlockBuild:GetDefaultPlayTimeOfBlockCount(count,speed)
    speed = speed or 1
    local blocks_per_tick = speed --一帧生成多少块
    local speed_block = blocks_per_tick*BLOCK_FPS; --一秒钟生成多少块
    local second = count/speed_block;
    while second>(MAX_TIME-lookAroundTime) do
        blocks_per_tick = blocks_per_tick + 1
        speed_block = blocks_per_tick*BLOCK_FPS
        second = count/speed_block;
    end

    return second+lookAroundTime,speed_block,blocks_per_tick
end

--[[
    loadtemplate 播放一个建筑的建造动画，
    摄像机由下至上运动，俯仰角缓慢增加，绕目标建筑不停水平旋转，直至loadtemplate播放完成，再迅速转360°
]]
function RecordBlockBuild:PlayOneBuildAni(obj,callback)
    if RecordBlockBuild._isPlaying then
        return
    end
    RecordBlockBuild._isPlaying = true
    --先把原有的blocks清空
    local oldBlocks = obj.blocks
    for k,v in pairs(oldBlocks) do
        local x,y,z = v[1],v[2],v[3]
        local last_block = BlockEngine:GetBlock(x,y,z)
        if last_block and last_block:GetBlockEntity(x,y,z) then
            BlockEngine:SetBlock(x,y,z,0)
        else
            BlockEngine:SetBlock(x,y,z,0,nil,0)
        end
    end
    -- obj.blocks = nil
    -- print("============areaIds",unpack(obj.areaIds))
    -- print("======template file",obj.filename)
    -- echo(obj,true)

    local pivot_x, pivot_y, pivot_z = unpack(obj.pivot)
    local meanCX,meanCY,meanCZ = unpack(obj.meanCenter)
    local radius, count = obj.radius,obj.count
    local min_x,min_y,min_z = unpack(obj.minPos)
    local max_x,max_y,max_z= unpack(obj.maxPos)
    
    local _camera = self:_createOrGetCamera()
    local cm_x,cm_y_min,cm_z = BlockEngine:real(meanCX,meanCY,meanCZ)
    local cm_y_max;
    cm_x,cm_y_max,cm_z = BlockEngine:real(meanCX,max_y,meanCZ)

    local cm_y = cm_y_min
    _camera:SetPosition(cm_x,cm_y,cm_z)
    -- print("====ggggg,cm_x,cm_y,cm_z",cm_x,cm_y,cm_z)
    _camera:SetFocus();
    _camera:HideCameraModel();

    if RecordBlockBuild._movieTimer then
        RecordBlockBuild._movieTimer:Change()
        RecordBlockBuild._movieTimer = nil
    end
    local old_dist, old_pitch, old_yaw = ParaCamera.GetEyePos();

    -- print('ParaEngine.GetAttributeObject():GetField("FPS", 0)',ParaEngine.GetAttributeObject():GetField("FPS", 0))
    -- print('ParaMovie.GetAttributeObject():GetField("RecordingFPS", 0)',ParaMovie.GetAttributeObject():GetField("RecordingFPS", 0))

    local _,speed_block,blocks_per_tick = self:GetDefaultPlayTimeOfBlockCount(count,TIME_SPEED)
    local dist = radius + 8
    local yaw = old_yaw
    local pitch = 10
    local max_pitch = 30
    local speed_pitch = 0.1 --镜头俯仰角变化速度
    local speed_yaw = obj.speed_yaw or 1
    local speed_y = 0.04*math.max(BLOCK_FPS,speed_block)/BLOCK_FPS --镜头上升速度

    --记录大致形状
    local ratio_zx = 1
    local ratio_yx = 1
    local ratio_yz = 1
    if max_x-min_x>0 then
        ratio_zx = math.floor((max_z-min_z)/(max_x-min_x)*100)/100
        ratio_yx = math.floor((max_y-min_y)/(max_x-min_x)*100)/100
    end
    if max_z-min_z>0 then
        ratio_yz = math.floor((max_y-min_y)/(max_z-min_z)*100)/100
    end
    if ratio_yx>2 or ratio_yz>2 then
        max_pitch = 45
    elseif ratio_yx>3 or ratio_yz>3 then
        max_pitch = 60
    end

    local task = BlockTemplate:new(
        {
            operation = BlockTemplate.Operations.AnimLoad,
            filename = obj.filename,
            blockX = pivot_x,
            blockY = pivot_y,
            blockZ = pivot_z,
            nohistory = true,
            load_anim_duration = nil,
            blocks_per_tick = blocks_per_tick,
        }
    );
    task:Run();
   
    local _begin = os.clock()
    RecordBlockBuild._movieTimer = commonlib.Timer:new({callbackFunc=function()
        yaw = (yaw + speed_yaw)%360

        if pitch<max_pitch and not task:IsAnimloadFinished() then
            pitch = pitch + speed_pitch
        end
        
        if cm_y<cm_y_max and not task:IsAnimloadFinished() then
            cm_y = cm_y + speed_y
            _camera:SetPosition(cm_x,cm_y,cm_z)
        end

        ParaCamera.SetEyePos(dist, pitch*math.pi/180, yaw*3.14/180);

        if task:IsAnimloadFinished() then
            -- print("=====勇士",os.clock()-_begin)
            if RecordBlockBuild._movieTimer then
                RecordBlockBuild._movieTimer:Change()
                RecordBlockBuild._movieTimer = nil
            end

            local _aniType = obj.animType or 1
            --加速转一圈
            local _tween;
            _tween = CommonCtrl.Tween:new{
                obj={val=val},
                func = CommonCtrl.TweenEquations.easeInOutSine,
                prop="val",
                begin=val,
                change=1,
                duration=lookAroundTime,
                MotionChange = function(time,val,tween)
                    
                    if _aniType==1 then
                        ParaCamera.SetEyePos(dist, pitch*math.pi/180, yaw+val*360*3.14/180);
                    elseif _aniType==2 then
                        _camera:SetPosition(cm_x,cm_y + val*5,cm_z)
                        ParaCamera.SetEyePos(dist-8+val*30, ((pitch + val*5)%360)*math.pi/180, yaw*3.14/180);
                    elseif _aniType==3 then
                        _camera:SetPosition(cm_x,cm_y + val*5,cm_z)
                        ParaCamera.SetEyePos(dist-8+val*30, ((pitch + val*5)%360)*math.pi/180, yaw-val*360*3.14/180);
                    end
                end,
                MotionFinish = function()
                    RecordBlockBuild._isPlaying = false

                    local delay = math.max(lookAroundTime - _tween.duration,0)
                    commonlib.TimerManager.SetTimeout(function()
                        if callback then
                            callback()
                            callback = nil
                        else
                            print("=========errorxxxxxx 1")
                        end
                    end,delay*1000)
                end
            }
            if _aniType==2 then
                _tween.duration = 0.5
            end
            _tween:Start()
        end
    end})
    RecordBlockBuild._movieTimer:Change(0,1)
end

RecordBlockBuild:InitSingleton();