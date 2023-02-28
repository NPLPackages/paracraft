--[[
Title: 建造世界过程中，记录玩家路径
Author(s): hyz
Date: 2022/7/19
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BuildReplay/RecordUserPath.lua");
local RecordUserPath = commonlib.gettable("MyCompany.Aries.Game.Tasks.RecordUserPath");
RecordUserPath:Init()
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/SelectionManager.lua");
local SelectionManager = commonlib.gettable("MyCompany.Aries.Game.SelectionManager");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityManager.lua");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
NPL.load("(gl)script/apps/Aries/Creator/Game/block_engine.lua");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlockWindow.lua");
local CodeBlockWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockWindow");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Direction.lua");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityCamera.lua");
local EntityCamera = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityCamera")
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/block_types.lua");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
NPL.load("(gl)script/ide/System/Scene/Cameras/Cameras.lua");
local Cameras = commonlib.gettable("System.Scene.Cameras");

local ReplayManager = commonlib.gettable("MyCompany.Aries.Game.Tasks.BuildReplay.ReplayManager");

local RecordUserPath = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Tasks.BuildReplay.RecordUserPath"));

local REFRESH_RATE = 1 --每隔几秒钟记录一次
local MAX_RECORD_NUM = 2000 --最大记录多少条数据
local TIME_SPEED = 1 --几倍速播放
local MAX_TIME = 10 --最大几秒钟

function RecordUserPath.SetConfig(config)
    config = config or {}
    if config.REFRESH_RATE then
        REFRESH_RATE = config.REFRESH_RATE
    end
    if config.TIME_SPEED then
        TIME_SPEED = config.TIME_SPEED
    end
    
    if config.MAX_TIME then
        MAX_TIME = config.MAX_TIME
    end
    if config.MAX_RECORD_NUM then
        MAX_RECORD_NUM = config.MAX_RECORD_NUM
    end
end

local _EnumActions = {
    WaitBorn = "WaitBorn", --出生之前隐藏（动画用）
    Born = "Born", --进入世界
    Walking = "Walking", --在走路
    Flying = "Flying", --在飞
    Idle = "Idle", --停留，什么也没干
    Building = "Building", --停留，建造中
    Coding = "Coding", --停留，敲代码中
}

function RecordUserPath:OnEnterWorld()
    self._userPaths = {}
    self._lastPos = "0,0,0" --上次的位置
    self._lastAction = _EnumActions.Idle --上次的动作
    self._entities = {}
    RecordUserPath._isPlaying = nil
    RecordUserPath:_loadHistory()

    if RecordUserPath._camera then
        RecordUserPath._camera = nil
    end

    commonlib.TimerManager.SetTimeout(function()
        
        local player = EntityManager.GetPlayer()
        if player then
            local x,y,z = player:GetBlockPos()
            local key = string.format("%s,%s,%s",x,y,z)
            self._lastPos = key --上次的位置
        end
        self._lastAction = _EnumActions.Born --上次的动作
    end,0)

    if self._posTimer then
        self._posTimer:Change()
        self._posTimer = nil
    end
    self._posTimer = self._posTimer or commonlib.Timer:new({callbackFunc=function()
        RecordUserPath:OnUpdate()
    end})
    self._posTimer:Change(0,REFRESH_RATE*1000)--每秒刷新
end

function RecordUserPath:OnExitWorld()
    if self._posTimer then
        self._posTimer:Change()
        self._posTimer = nil
    end
    if self._movieTimer then
        self._movieTimer:Change()
        self._movieTimer = nil
    end
    if RecordUserPath._movieTimer2 then
        RecordUserPath._movieTimer2:Change()
        RecordUserPath._movieTimer2 = nil
    end
    RecordUserPath:_saveHistory()
    self:StopAllEntityAni()
    print("RecordUserPath:OnExitWorld")
end

--用于判断这一秒有没有在建造
function RecordUserPath.OnMouseReleaseEvent()
    if not ReplayManager:IsRecording() then
        return
    end
    local result = SelectionManager:GetPickingResult()
    local bx,by,bz = result.bx,result.by,result.bz
    if bx==nil then
        return _,event
    end
    RecordUserPath._isBuilding = true --正在建造
end

local idleAcc = 0
--每秒执行记录操作
function RecordUserPath.OnUpdate()
    if not ReplayManager:IsRecording() then
        return
    end
    if RecordUserPath.isPlaying then
        return
    end
    local self = RecordUserPath
    local player = EntityManager.GetPlayer()
    if player==nil then
        if self._posTimer then
            self._posTimer:Change()
            self._posTimer = nil
        end
        return
    end
    local x,y,z = player:GetBlockPos()

    local key = string.format("%s,%s,%s",x,y,z)

    if self._lastPos==key then --跟上1秒还在同一个位置
        if CodeBlockWindow:IsVisibleAndFocus() then --正在写代码
            self._lastAction = _EnumActions.Coding
            idleAcc = 0
        elseif self._isBuilding then
            self._lastAction = _EnumActions.Building
            idleAcc = 0
        else
            idleAcc = idleAcc + 1
            if self._lastAction == _EnumActions.Walking or self._lastAction == _EnumActions.Flying then
                self._lastAction = _EnumActions.Idle
            elseif self._lastAction ~= _EnumActions.Born then
                if idleAcc==10 then --发呆超过10秒才算发呆
                    self._lastAction = _EnumActions.Idle
                end
            end
        end
    else
        idleAcc = 0
        if player:IsFlying() then
            self._lastAction = _EnumActions.Flying
        else
            self._lastAction = _EnumActions.Walking
        end
    end

    self._lastPos = key

    

    local obj = self._userPaths[#self._userPaths]
    if obj==nil or obj.action~=self._lastAction  then --状态发生改变
        obj = {
            key = key,
            x = x,y = y,z = z,
            action = self._lastAction,
            seconds = 0,
        }
        table.insert(self._userPaths,obj)
    else
        if obj.key==key then --同一状态，同一位置
            obj.seconds = obj.seconds + REFRESH_RATE
        else --同一状态，不同位置，(基本上就是飞行或者走路)
            if self._lastAction==_EnumActions.Walking or self._lastAction == _EnumActions.Flying then --一直在走
                obj.seconds = obj.seconds + REFRESH_RATE
                if obj.seconds>=3 then --连续走了超过3秒才记录位置，不然一直走的话数据就太多了
                    obj = {
                        key = key,
                        x = x,y = y,z = z,
                        action = self._lastAction,
                        seconds = 0,
                    }
                    table.insert(self._userPaths,obj)
                end
            end
        end
        
    end
    -- GameLogic.AddBBS("nil",string.format("%s: %s,%s秒",obj.key,obj.action,obj.seconds),1000)
    self._isBuilding = false

    if #self._userPaths>MAX_RECORD_NUM then --记录太多了，删除旧的
        table.remove(self._userPaths,1)
    end
end

local xmlSavePath = "user_action_path.xml";
function RecordUserPath:_saveHistory()
    if GameLogic.GetGameMode()~="edit" then
        return
    end
    if self._userPaths == nil then
        return
    end
    local stats_folder = GameLogic.GetWorldDirectory().."stats/"
    if not ParaIO.DoesFileExist(stats_folder) then
        ParaIO.CreateDirectory(stats_folder)
    end
    local filename = stats_folder..xmlSavePath;
	local root = {name='user_action_path', attr={file_version="0.1"} }
    for id,v in ipairs(self._userPaths) do
        root[#root+1] = {
            name = "value",
            attr = {key=v.key,action=v.action,seconds=v.seconds}
        }
    end
	local xml_data = commonlib.Lua2XmlString(root, true, true) or "";
	-- local file = ParaIO.open(filename, "w");
	-- if(file:IsValid()) then
	-- 	file:WriteString(xml_data);
	-- 	file:close();
	-- end
    local writer = ParaIO.CreateZip(filename, "");
    if (writer:IsValid()) then
        writer:ZipAddData("data", xml_data);
        writer:close();
    end
    local player = EntityManager.GetPlayer()
    if player and player:GetSkin() then
        WorldCommon.SetWorldTag("player_skin",player:GetSkin())
        WorldCommon.SaveWorldTag()
    end
	
	return true;
end

function RecordUserPath:_loadHistory()
    if(GameLogic.isRemote) then
        return
    end
    
    self._userPaths = {}
    local function LoadFromHistoryFile_(filename)
        local xmlRoot = ParaXML.LuaXML_ParseFile(filename);
        if(xmlRoot) then
            local arr = commonlib.XPath.selectNodes(xmlRoot, "/user_action_path");
            if arr and arr[1] then
                local list = arr[1]
                for k,v in ipairs(list) do
                    local obj = v.attr
                    obj.x,obj.y,obj.z = unpack(commonlib.split(obj.key,","))
                    self._userPaths[k] = {
                        key=obj.key,
                        x=tonumber(obj.x),
                        y=tonumber(obj.y),
                        z=tonumber(obj.z),
                        action=obj.action,
                        seconds=tonumber(obj.seconds),
                    }
                end

                -- print("=========self._userPaths")
                -- echo(self._userPaths,true)
            end
        end	
    end

    local stats_folder = GameLogic.GetWorldDirectory().."stats/"
	local filename = stats_folder..xmlSavePath

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
    从总库里筛选出目标点附近的点，组成路径
]]
function RecordUserPath:FilterPathsWithPos(cx,cz,radius)
    local retArr = {}
    local len = #self._userPaths
    for k=1,len do
        local v = self._userPaths[k]
        if math.abs(cx-v.x)<radius and math.abs(cz-v.z)<radius then
            table.insert(retArr,v)
        end
    end
    return retArr
end

--[[
    根据一系列状态点得到路径动画
    返回一个动画播放task
]]
function RecordUserPath:GetPlayTasksWithDotList(arr)
    if arr==nil or #arr==0 then
        return
    end
    
    local taskGroup = {}
    taskGroup._timeSpeed = TIME_SPEED

    local player = EntityManager.GetPlayer()
    local tweenObj = {val=0}
    local tweenParam = {
        obj = tweenObj,
        prop="val",
        begin=0,
        change=1,
        duration=0,
        UseCommonlibTimer = true,
    }
    taskGroup._totalTime = 0
    local _task,_param,x,y,z,facing
    for i=1,#arr do
        local pre = arr[i-1]
        local v = arr[i]
        taskGroup._totalTime = taskGroup._totalTime + v.seconds
        _param = commonlib.copy(tweenParam)
        _param.origin_dur = math.max(v.seconds,0.01)
        _param.func = CommonCtrl.TweenEquations.easeNone
        _param.MotionFinish = function()
            if v.action~=_EnumActions.Walking and v.action~=_EnumActions.Flying then
                if taskGroup.entity and not taskGroup.entity:IsDead() then
                    taskGroup.entity:SetAnimation(0)
                end
            end
            if _task then
                _task:StopEnterFrame()
            end
            taskGroup:runNext()
        end
        
        if pre and ((v.action==_EnumActions.Walking or v.action==_EnumActions.Flying) or (pre.action==_EnumActions.Walking or pre.action==_EnumActions.Flying)) then
            if (v.action==_EnumActions.Walking or v.action==_EnumActions.Flying) then 
                if not (pre.action==_EnumActions.Walking or pre.action==_EnumActions.Flying) then --静止状态到走路状态
                    _param.origin_dur = math.max(v.seconds*0.5,0.01)
                else --连续走路状态
                    _param.origin_dur = math.max((v.seconds+pre.seconds)*0.5,0.01)
                end
            else --走路状态到静止状态
                _param.origin_dur = math.max(pre.seconds*0.5,0.01)
            end
            _param.MotionStart = function()
                x = v.x-pre.x
                y = v.y-pre.y
                z = v.z-pre.z
                facing = Direction.GetFacingFromOffset(x,y,z)
                if taskGroup.entity and not taskGroup.entity:IsDead() then
                    taskGroup.entity:SetAnimation(v.action==_EnumActions.Walking and 5 or 38)
                    taskGroup.entity:SetFacing(facing)
                end
            end
            _param.MotionChange = function(time,val,tween)
                x,y,z = pre.x+val*(v.x-pre.x),pre.y+val*(v.y-pre.y),pre.z+val*(v.z-pre.z)
                -- GameLogic.AddBBS(1,string.format("%s,%s,%s",x,y,z))
                x,y,z = BlockEngine:real(x,y,z)
                y = y - 0.5
                if taskGroup.entity and not taskGroup.entity:IsDead() then
                    taskGroup.entity:SetPosition(x,y,z)
                end
            end
        elseif v.action==_EnumActions.Idle or v.action==_EnumActions.Born then
            _param.MotionStart = function()
                if taskGroup.entity and not taskGroup.entity:IsDead() then
                    taskGroup.entity:SetVisible(true)
                    taskGroup.entity:SetBlockPos(v.x,v.y,v.z)
                    taskGroup.entity:SetAnimation(0)
                    taskGroup.entity:Say(nil)
                end
            end
        elseif v.action==_EnumActions.Building then
            _param.MotionStart = function()
                if taskGroup.entity and not taskGroup.entity:IsDead() then
                    taskGroup.entity:SetVisible(true)
                    taskGroup.entity:SetBlockPos(v.x,v.y,v.z)
                    taskGroup.entity:SetAnimation(0)
                    if v.seconds>5 then
                        taskGroup.entity:Say(L"正在建造...",v.seconds/taskGroup._timeSpeed)
                    end
                end
            end
        elseif v.action==_EnumActions.Coding then
            _param.MotionStart = function()
                if taskGroup.entity and not taskGroup.entity:IsDead() then
                    taskGroup.entity:SetVisible(true)
                    taskGroup.entity:SetBlockPos(v.x,v.y,v.z)
                    taskGroup.entity:SetAnimation(0)
                    if v.seconds>5 then
                        taskGroup.entity:Say(L"正在Coading...",v.seconds/taskGroup._timeSpeed)
                    end
                end
            end
        elseif v.action==_EnumActions.WaitBorn then
            _param.MotionStart = function()
                if taskGroup.entity and not taskGroup.entity:IsDead() then
                    taskGroup.entity:SetVisible(false)
                end
            end
        end
        
        table.insert(taskGroup,CommonCtrl.Tween:new(_param))
    end

    function taskGroup:runNext()
        _task = table.remove(self,1)
        if _task then
            _task.duration = _param.origin_dur/self._timeSpeed
            _task:Start()
        else
            -- GameLogic.AddBBS(7,"結束")
            if self.entity and self.entity.bx and not self.entity:IsDead() and RecordUserPath._entities[tostring(self)]  then
                self.entity:Say(nil)
                self.entity:SetDead()
                RecordUserPath._entities[tostring(self)] = nil
                self.entity = nil
            end
            if self._onComplete then
                self._onComplete()
                self._onComplete = nil
            end
        end
    end

    function taskGroup:startRun(options,callback)
        if RecordUserPath._isStoped then
            return
        end
        if #self==0 then
            return
        end
        options = options or {}
        if options.speed then
            self._timeSpeed = options.speed
        elseif options.maxTime then 
            self._timeSpeed = math.floor(self._totalTime/options.maxTime*100)/100
        end
        if options.repeat_count and options.repeat_count>0 then
            local len = #self
            for i=1,options.repeat_count do
                for j=1,len do
                    table.insert(self,self[j])
                end
            end
        end
        self._onComplete = callback
        if self.entity==nil then
            local entity = GameLogic.EntityManager.EntityLiveModel:Create()
            entity:SetModelFile("character/CC/02human/CustomGeoset/actor.x")
            local skin = WorldCommon.GetWorldTag("player_skin")
            if skin==nil or skin=="" then
                skin = player:GetSkin()
            end
            entity:SetSkin(skin)
            entity:Attach()
            self.entity = entity

            RecordUserPath._entities[tostring(self)] = self.entity
            self.entity.taskGroup = taskGroup
        end
        self:runNext()
    end

    function taskGroup:stopTasks()
        if _task then
            _task:StopEnterFrame()
        end
        if self.entity and self.entity.bx and not self.entity:IsDead() and RecordUserPath._entities[tostring(self)] then
            self.entity:SetDead()
            
            RecordUserPath._entities[tostring(self)] = nil
            self.entity = nil
        end
        for k,v in ipairs(self) do
            if v.StopEnterFrame then
                v:StopEnterFrame()
            end
        end
    end

    return taskGroup
end

local function _getLineCenter(i,d)
    return i - (i-1)%d + math.floor(d/2)
end

--获取某个点所在长方体区域的中心点
local function _getAreaCenter(pos,dx,dy,dz)
    return _getLineCenter(pos.x,dx),_getLineCenter(pos.y,dy),_getLineCenter(pos.z,dz)
end

local function _getKeyOfAreaCenter(pos)
    return string.format("%s-%s-%s",_getAreaCenter(pos,5,3,5))
end

--[[
    从出生点开始播放路径动画
    {
        speed = speed,
        repeat_count = repeat_count,
    }
]]
function RecordUserPath:PlayPathAnimsFromBorn(param,onCompleted)
    if self._userPaths==nil then
        self:OnEnterWorld()
        if self._userPaths==nil then
            if onCompleted then
                onCompleted()
                onCompleted = nil
            end
            return
        end 
    end
    if #self._userPaths==0 then
        if onCompleted then
            onCompleted()
            onCompleted = nil
        end
        return
    end
    if RecordUserPath._isPlaying then
        return
    end
    RecordUserPath._isStoped = false
    RecordUserPath._isPlaying = true
    math.randomseed(os.time()..os.clock())
    math.randomseed(os.time()..os.clock())
    math.randomseed(os.time()..os.clock())

    local len = #self._userPaths

    local lookPosKeyAccArr,mostPos,maxAcc = {},nil,0
    local pathArrs = {}
    local arr = nil 
    for k=1,len do
        local v = self._userPaths[k]
        local lastV = self._userPaths[k-1]
        if lastV==nil or (v.key~=lastV.key) then --连续重复的点不计算
            local _key = _getKeyOfAreaCenter(v)
            lookPosKeyAccArr[_key] = (lookPosKeyAccArr[_key] or 0) + 1
            if lookPosKeyAccArr[_key] and lookPosKeyAccArr[_key]>maxAcc then --找出重复的最多的区域
                maxAcc = lookPosKeyAccArr[_key]
                mostPos = v --重复次数最多的位置
            end
        end
    end
    for k=1,len do
        local v = self._userPaths[k]
        if _getKeyOfAreaCenter(v)==_getKeyOfAreaCenter(mostPos) or k==len then
            if arr and (#arr>3 or k==len) then
                table.insert(pathArrs,arr)
                arr = nil
            end
        end
        arr = arr or {}
        table.insert(arr,v)
    end
    if mostPos==nil then
        if onCompleted then
            onCompleted()
            onCompleted = nil
        end
        return
    end
    
    if param.withCameraOn then --有摄像机的话，只观察最热闹的那个点
        local len = #pathArrs
        print("--------len",len)
        for i=len,1,-1 do
            local arr = pathArrs[i]
            if arr[1]==nil or _getKeyOfAreaCenter(arr[1])~=_getKeyOfAreaCenter(mostPos) then
                table.remove(pathArrs)
            end
        end
        len = #pathArrs
        print("--------len1",len)
        if len<8 and len>0 then
            local repeatNum = math.max(math.floor(8/len),1)
            for i=1,repeatNum do
                for j=1,len do
                    local arr = pathArrs[j]
                    local tmp = commonlib.copy(arr)
                    for k,v in pairs(tmp) do
                        v.x = v.x + math.random(-5,5)
                        v.z = v.z + math.random(-5,5)
                    end
                    local waitObj = commonlib.copy(tmp[1])
                    waitObj.action = _EnumActions.WaitBorn
                    waitObj.seconds = math.random(500,2000)/1000*j
                    table.insert(tmp,waitObj)

                    table.insert(pathArrs,tmp)
                end

            end
        end
        print("--------len2",#pathArrs)
    end

    local _taskGroupArr = {}

    for _,arr in ipairs(pathArrs) do
        local taskGroup = self:GetPlayTasksWithDotList(arr)
        table.insert(_taskGroupArr,taskGroup)
    end

    local _timer;

    local old_focus = GameLogic.EntityManager.GetFocus()
    local old_dist, old_pitch, old_yaw = ParaCamera.GetEyePos();
    local _callback = function()
        if param.withCameraOn then
            if old_focus and old_focus==GameLogic.EntityManager.GetPlayer() then
                old_focus:SetFocus()
                ParaCamera.SetEyePos(old_dist, old_pitch, old_yaw)
            end
        end
        RecordUserPath._isPlaying = nil
        
        if RecordUserPath._movieTimer2 then
            RecordUserPath._movieTimer2:Change()
            RecordUserPath._movieTimer2 = nil
        end
        -- GameLogic.AddBBS(1,"路径动画完成"..tostring(onCompleted))
        if _timer then
            _timer:Change()
        end
        if onCompleted then
            onCompleted()
            onCompleted = nil
        end
        if GameLogic.EntityManager.GetPlayer() and Game.is_started then
            GameLogic.RunCommand("/show player")
        end
    end

    if #_taskGroupArr==0 then
        if _callback then
            _callback()
            _callback = nil
        end
        return
    end

    if param.maxTime then
        _timer = commonlib.TimerManager.SetTimeout(function()
            for k,group in ipairs(_taskGroupArr) do
                group:stopTasks()
            end
            if _callback then
                _callback()
                _callback = nil
            end
        end,param.maxTime)
    end

    local _camera

    if not mostPos then
        param.withCameraOn = nil
    end
    if param.withCameraOn then
        _camera = self:_createOrGetCamera()
        local cx,cy,cz = mostPos.x,mostPos.y,mostPos.z
        -- print("----cx,cy,cz",cx,cy,cz)
        -- local cx,cy,cz = 19201,5,19200
        local x,y,z = BlockEngine:real(cx,cy,cz)
        _camera:SetPosition(x,y,z)
    
        _camera:SetFocus();
        _camera:HideCameraModel();
        -- _camera:ShowCameraModel();

        local dist = 10
        local pitch = 25
        local yaw = ReplayManager:_getRandomAngle()
        local eye_pos = {}
                
        eye_pos = {ReplayManager:getEyePos(x,y,z,dist, pitch*math.pi/180, yaw*3.14/180)}
        local hasOcclude = ReplayManager:checkHasBlockBetween(eye_pos,{x,y,z},dist-1)
        if hasOcclude then
            for i=15,360,15 do
                local tempYaw = yaw + i 
                eye_pos = {ReplayManager:getEyePos(x,y,z,dist, pitch*math.pi/180, (tempYaw)*3.14/180)}
                hasOcclude = ReplayManager:checkHasBlockBetween(eye_pos,{x,y,z},dist-1)
                local a,b,c = BlockEngine:block(eye_pos[1],eye_pos[2],eye_pos[3])
                -- print(string.format("tempYaw:%s,new (x,z) = (%s,%s)",tempYaw,a-cx,c-cz))
                if not hasOcclude then
                    yaw = tempYaw
                    break 
                end
            end
        end
        if hasOcclude then
            
        end
        ParaCamera.SetEyePos(dist, pitch*math.pi/180, yaw*3.14/180);
        if RecordUserPath._movieTimer2 then
            RecordUserPath._movieTimer2:Change()
            RecordUserPath._movieTimer2 = nil
        end
        RecordUserPath._movieTimer2 = commonlib.Timer:new({callbackFunc=function()
            pitch = (pitch + 0.01)%360
            ParaCamera.SetEyePos(dist, pitch*math.pi/180, yaw*3.14/180);
            x = x - 0.02
            y = y + 0.01
            _camera:SetPosition(x,y,z)
        end})
        RecordUserPath._movieTimer2:Change(0,1)
    end

    GameLogic.RunCommand("/hide player")

    local len = #_taskGroupArr
    local acc = 0
    for k,group in ipairs(_taskGroupArr) do
        group:startRun(param,function()
            acc = acc + 1
            if acc==len then
                if _timer then
                    _timer:Change()
                    _timer = nil
                end
                if _callback then
                    _callback()
                    _callback = nil
                end
            end
        end)
    end
end

function RecordUserPath:StopAllEntityAni()
    RecordUserPath._isStoped = true
    RecordUserPath._isPlaying = false
    if self._entities then
        for k,v in pairs(self._entities) do
            if not v:IsDead() and v.bx then
                v:SetDead()
                v.taskGroup.entity = nil
            end
        end
    end
    self._entities = {}
    if RecordUserPath._movieTimer then
        RecordUserPath._movieTimer:Change()
        RecordUserPath._movieTimer = nil
    end
    if RecordUserPath._movieTimer2 then
        RecordUserPath._movieTimer2:Change()
        RecordUserPath._movieTimer2 = nil
    end
end

function RecordUserPath:_createOrGetCamera()
    local _camera = RecordUserPath._camera
    if _camera==nil then
        _camera = EntityCamera:Create({item_id = block_types.names.TimeSeriesCamera});
        RecordUserPath._camera = _camera
        _camera:SetPersistent(false);
		_camera:Attach();
    end
    return _camera
end

--播放某个点附近的路径动画
--[[
    param:{
        withCameraOn = true,
        repeat_count = 3,
        speed = 10,
        path_repeat = 2,
    }
]]
function RecordUserPath:PlayPathAnimsNearPos(cx,cy,cz,radius,param,onCompleted)
    if self._userPaths==nil then
        self:OnEnterWorld()
        if self._userPaths==nil then
            if onCompleted then
                onCompleted()
                onCompleted = nil
            end
            return
        end 
    end
    if RecordUserPath._isPlaying then
        return
    end
    RecordUserPath._isStoped = false
    RecordUserPath._isPlaying = true
    math.randomseed(os.time()..os.clock())
    math.randomseed(os.time()..os.clock())
    math.randomseed(os.time()..os.clock())
    param = param or {}
    local _taskGroupArr = {}
    local _listArr = {}
    local list = self:FilterPathsWithPos(cx,cz,radius)
    -- echo(list,true)
    print("----------list",#list)
    local tempArr = {} --如果队列太长，就分成100一个的几段
    if #list>200 then
        while #list>100 do
            if #tempArr>=100 then
                table.insert(_listArr,tempArr)
                tempArr = {}
                if #list<=100 then
                    break
                end
            end
            table.insert(tempArr,table.remove(list,#list))
        end
    end
    table.insert(_listArr,list)
    local time = 0
    for i=1,#list do
        local v = list[i]
        if v.seconds>30 and (v.action==_EnumActions.Born or v.action==_EnumActions.Idle) then
            v.seconds = 30
        end
        time = time + v.seconds
    end
    local repeat_count = 1
    if time<60*2 then
        repeat_count = 3
    elseif time<60*3 then
        repeat_count = 2
    end
    if param.repeat_count then
        repeat_count = param.repeat_count
    end

    local len = #_listArr
    local path_repeat = param.path_repeat or 2
    if len<8 then
        path_repeat = math.ceil(8/len)
    end
    for i=1,path_repeat do
        for j=1,len do
            local tempArr = commonlib.copy(_listArr[j])
            for i=1,#tempArr do
                local v = list[i]
                v.x = v.x + math.random(-5,5)
                v.z = v.z + math.random(-5,5)
            end
            table.insert(_listArr,tempArr)
        end
    end
    for k,v in ipairs(_listArr) do
        local taskGroup = self:GetPlayTasksWithDotList(v)
        if taskGroup then
            table.insert(_taskGroupArr,taskGroup)
        end
    end

    local _timer;
    if param.maxTime then
        _timer = commonlib.TimerManager.SetTimeout(function()
            for k,group in ipairs(_taskGroupArr) do
                group:stopTasks()
            end
            if onComplete then
                onComplete()
            end
        end,param.maxTime)
    end

    GameLogic.RunCommand("/hide player")
    local old_focus = GameLogic.EntityManager.GetFocus()
    local old_dist, old_pitch, old_yaw = ParaCamera.GetEyePos();
    local _callback = function()
        if param.withCameraOn then
            if old_focus and old_focus==GameLogic.EntityManager.GetPlayer() then
                old_focus:SetFocus()
                ParaCamera.SetEyePos(old_dist, old_pitch, old_yaw)
            end
        end
        RecordUserPath._isPlaying = nil
        
        if RecordUserPath._movieTimer then
            RecordUserPath._movieTimer:Change()
            RecordUserPath._movieTimer = nil
        end
        -- GameLogic.AddBBS(1,"路径动画完成"..tostring(onCompleted))
        if _timer then
            _timer:Change()
        end
        if onCompleted then
            onCompleted()
            onCompleted = nil
        end
        if GameLogic.EntityManager.GetPlayer() and Game.is_started then
            GameLogic.RunCommand("/show player")
        end
    end

    local _camera
    if param.withCameraOn then
        _camera = self:_createOrGetCamera()
        -- print("cx,cy,cz",cx,cy,cz)

        local x,y,z = BlockEngine:real(cx,cy,cz)
        _camera:SetPosition(x,y,z)
    
        _camera:SetFocus();
        _camera:HideCameraModel();
        -- _camera:ShowCameraModel();

        local dist = 18
        local pitch = 25
        local yaw = 0
        ParaCamera.SetEyePos(dist, pitch*math.pi/180, yaw*3.14/180);

        if RecordUserPath._movieTimer then
            RecordUserPath._movieTimer:Change()
            RecordUserPath._movieTimer = nil
        end
        RecordUserPath._movieTimer = commonlib.Timer:new({callbackFunc=function()
            yaw = (yaw + 0.2)%360
            ParaCamera.SetEyePos(dist, pitch*math.pi/180, yaw*3.14/180);
        end})
        RecordUserPath._movieTimer:Change(0,1)
    end

    if #_taskGroupArr==0 then
        _callback()
    end
    
    for k,taskGroup in pairs(_taskGroupArr) do
        local delay = (k-1)*math.random(500,2000)
        commonlib.TimerManager.SetTimeout(function()
            local param = {
                repeat_count = repeat_count,
                speed = param.speed or TIME_SPEED,
            }
            taskGroup:startRun(param,function()
                if k==#_taskGroupArr then
                    _callback()
                end     
            end)
        end,delay)
    end
end

RecordUserPath:InitSingleton()
