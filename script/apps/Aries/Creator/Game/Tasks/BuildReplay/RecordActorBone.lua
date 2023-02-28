--[[
    author:{pbb}
    time:2022-07-22 17:58:40
    uselib:
        NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BuildReplay/RecordActorBone.lua");
        local RecordActorBone = commonlib.gettable("MyCompany.Aries.Game.Tasks.RecordActorBone");
        local num = RecordActorBone:GenerateBoneDatas()
        tip("num========"..(num or 0))
        if(num > 0) then
            local time = 3
            RecordActorBone:StartPlay(time,function()
                GameLogic.AddBBS(nil,"播放完成了"..num)
            end)
        end
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityMovieClip.lua");
local EntityMovieClip = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityMovieClip")
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/MovieClipController.lua");
local MovieClipController = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieClipController");
NPL.load("(gl)script/ide/System/Core/ToolBase.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/block_engine.lua");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityManager.lua");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemStack.lua");
local ItemStack = commonlib.gettable("MyCompany.Aries.Game.Items.ItemStack");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/MovieManager.lua")
local MovieManager = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieManager")
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local normalserverData = {
	timeseries = {
		blockinhand = {times = {},data = {},ranges = {},type = "Discrete",name = "blockinhand",},
		x = {times = {0,},data = {20009.89459,},ranges = {{1,1,},},type = "Linear",	name = "x",},
		y = {times = {0,},data = {100,},ranges = {{1,1,},},type = "Linear",name = "y",},
        z = {times = {0,},data = {20014.06125,},ranges = {{1,1,},},type = "Linear",name = "z",},
		isAgent = {times = {},data = {},ranges = {},type = "Discrete",name = "isAgent",	},
		parent = {times = {},data = {},ranges = {},type = "LinearTable",name = "parent",},
		isIgnoreSkin = {times = {},data = {},ranges = {},type = "Discrete",name = "isIgnoreSkin",},
		roll = {times = {},data = {},ranges = {},type = "LinearAngle",name = "roll",},
		block = {times = {},data = {},ranges = {},type = "Discrete",name = "block",},
		scaling = {times = {},data = {},ranges = {},type = "Linear",name = "scaling",},
		gravity = {times = {},data = {},ranges = {},type = "Discrete",name = "gravity",	},
		HeadUpdownAngle = {times = {},data = {},ranges = {},type = "Linear",name = "HeadUpdownAngle",},
		anim = {times = {},data = {},ranges = {},type = "Discrete",name = "anim",},
		facing = {times = {},data = {},ranges = {},type = "LinearAngle",name = "facing",},
		assetfile = {times = {},data = {},ranges = {},type = "Discrete",name = "assetfile",},
		speedscale = {times = {},data = {},ranges = {},type = "Discrete",name = "speedscale",},
		isServer = {times = {},data = {},ranges = {},type = "Discrete",name = "isServer",},
		skin = {times = {},data = {},ranges = {},type = "Discrete",name = "skin",},
		pitch = {times = {},data = {},ranges = {},type = "LinearAngle",	name = "pitch",	},
		cam_dist = {times = {},data = {},ranges = {},type = "Discrete",name = "cam_dist",},
		HeadTurningAngle = {times = {},data = {},ranges = {},type = "Linear",name = "HeadTurningAngle",},
		name = {times = {},data = {},ranges = {},type = "Discrete",name = "name",},
		opacity = {times = {},data = {},ranges = {},type = "Linear",name = "opacity",},
	},
}
local xmlSavePath = "user_bones_data.xml"
local RecordActorBone = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"),"MyCompany.Aries.Game.Tasks.RecordActorBone")
function RecordActorBone:ctor()
    
end

function RecordActorBone:OnInit()
    self:RegisterEvent()
    self.record_data = {}
    self.bone_data = {}
    self.current_movieclip = nil
    self.play_index = 1
    self.max_play_index = 1
    self.play_bone_data = nil
end

function RecordActorBone:RegisterEvent()
    GameLogic.GetFilters():add_filter("MovieClipEditorOpened",function(movieclip)
        self:OnSetMovieEntity(movieclip)
	end)
    GameLogic.GetFilters():add_filter("OnCloseMovieController",function(movieclip)
        self:OnCloseMovieEditor(movieclip)
	end)

    GameLogic.GetFilters():add_filter("OnMoviePlayFinish",function(movieclip)
        
	end)
end

function RecordActorBone:OnSetMovieEntity(movieclip) --打开电影方块
    if not movieclip then
        return
    end
    if self.current_movieclip == nil then
        self:StartEditMovie(movieclip)
        self.current_movieclip = movieclip
        return 
    end

    if self.current_movieclip ~= movieclip then
        self.current_movieclip = movieclip
        self:StartEditMovie(self.current_movieclip)
    end
end


function RecordActorBone:CloneMovieEntity(entity)
    if not entity or entity.class_name ~= "EntityMovieClip" then
        return 
    end
    local xmlNode = entity:SaveToXMLNode()
    if xmlNode then
        xmlNode.attr.name = nil;
        local x, y, z = entity:GetPosition()
        local newentity = EntityMovieClip:new()
        newentity:LoadFromXMLNode(xmlNode);
        return newentity
    end
end

function RecordActorBone:StartEditMovie(movieclip)
    local entity = movieclip:GetEntity()
    local entityId = entity.entityId
    local bx,by,bz = entity:GetBlockPos()
    local mx,my,mz = self:GetMovieBlockPos()
    if mx == bx and my == by and mz == bz then
        return 
    end
    local posKey =  (bx or 0) * 100000000 +  (by or 0) * 1000000 + (bz or 0);
    local record_key = posKey
    if not self.record_data[record_key] then
        self.record_data[record_key] = {}
    end
    self.record_data[record_key].pos = {bx,by,bz}
    self.record_data[record_key].startEntity = self:CloneMovieEntity(entity)
end

function RecordActorBone:EndEditMovie(movieclip)
    local entity = movieclip:GetEntity()
    local entityId = entity.entityId
    local bx,by,bz = entity:GetBlockPos()
    local mx,my,mz = self:GetMovieBlockPos()
    if mx == bx and my == by and mz == bz then
        return 
    end
    local posKey =  (bx or 0) * 100000000 +  (by or 0) * 1000000 + (bz or 0);
    local record_key = posKey
    if self.record_data[record_key] ~= nil then
        self.record_data[record_key].endEntity = entity
        local startEntity = self.record_data[record_key].startEntity
        self.current_movieclip = nil
        local diffNum,result = entity:CompareActorBones(startEntity) 
        local boneData
        if diffNum > 0 then
            boneData = self:GetActorBoneDatasByEntity(entity) 
        else
            diffNum,result = entity:CompareSlot(startEntity)
            if diffNum > 0 then
                boneData = self:GetActorBoneDatasByEntity(entity) 
            end
        end
        self.record_data[record_key].startEntity = nil
        if boneData ~= nil then
            self.record_data[record_key].boneData = boneData
            self.record_data[record_key].editTime = os.time()
        end
    end
end

function RecordActorBone:GetActorBoneDatasByEntity(entity) 
    if not entity then
        return 
    end
    local boneData = {}
    local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
    local movieClip = entity:GetMovieClip()
    if movieClip then
        local slotCount = entity.inventory:GetSlotCount()
        for i=1,slotCount do
            local itemStack = entity.inventory:GetItem(i);
            if itemStack and itemStack.id == block_types.names.TimeSeriesNPC then
                local timeseries = itemStack.serverdata.timeseries
                if timeseries and timeseries.bones and self:CheckHaseBoneData(timeseries.bones) then
                    if true then --timeseries.bones.times and #timeseries.bones.times > 1 --骨骼动画的帧数大于1
                        local temp = {}
                        temp.bones = timeseries.bones
                        temp.assetfile = (timeseries.assetfile and timeseries.assetfile.data and timeseries.assetfile.data[1]) and timeseries.assetfile.data[1] or ""
                        temp.skin = (timeseries.skin and timeseries.skin.data) and timeseries.skin.data[1] or ""
                        temp.facing = (timeseries.facing and timeseries.facing.data) and timeseries.facing.data[1] or 0
                        temp.scaling = (timeseries.scaling and timeseries.scaling.data) and timeseries.scaling.data[1] or 1
                        temp.x = (timeseries.x and timeseries.x.data) and timeseries.x.data[1] or 0
                        temp.y = (timeseries.y and timeseries.y.data) and timeseries.y.data[1] or 0
                        temp.z = (timeseries.z and timeseries.z.data) and timeseries.z.data[1] or 0
                        boneData[#boneData + 1] = temp
                    end
                end
            end
        end
    end
    if #boneData > 0 then
        return boneData
    end
end

local defaultIkBoneCfg = {
    L_Foot = {"L_Thigh","L_Calf"},
    R_Foot = {"R_Thigh","R_Calf"},
    L_Hand = {"L_UpperArm","L_Forearm"},
    R_Hand = {"R_UpperArm","R_Forearm"},
}
--"boneName_rot", "boneName_trans", "boneName_scale"
function RecordActorBone:GetBoneDataByBones(bones)
    if not bones or not self:CheckHaseBoneData(bones) then
        return 
    end
    local tempDt = {}
    local rotDt = {}
    local rotKeys = {}
    for k,v in pairs(bones) do
        if string.find(k,"trans") then
            tempDt[#tempDt + 1] = {key = k,data = v}
        end
        if string.find(k,"rot") then
            rotDt[#rotDt + 1] = {key = k,data = v,is_use = false}
            local boneName, typeName = k:match("^(.*)_(%w+)$")
            rotKeys[boneName] = true
        end
        if string.find(k,"scale") then
            tempDt[#tempDt + 1] = {key = k,data = v}
        end
    end
    local tempBones = {}
    for k,v in pairs(defaultIkBoneCfg) do
        local data = {}
        if rotKeys[v[1]] and rotKeys[v[2]] then
            for i=1,#rotDt do
                local key,_ = rotDt[i].key:match("^(.*)_(%w+)$")
                if key == v[1] or key == v[2] then
                    rotDt[i].is_use = true
                    data[#data + 1] = {key = rotDt[i].key ,data = rotDt[i].data}
                end
            end
            tempBones[k] = data
        end
    end
    for k,v in pairs(tempBones) do 
        tempDt[#tempDt + 1] = {key = k,data = v}
    end
    for i=1,#rotDt do
        if not rotDt[i].is_use then
            tempDt[#tempDt + 1] = {key = rotDt[i].key,data = rotDt[i].data}
        end
    end
    return tempDt
end

function RecordActorBone:CheckHaseBoneData(bones)
    local isHave = false
    if bones then
        for k,v in pairs(bones) do
            if string.find(k,"tran") or string.find(k,"rot") or string.find(k,"scal") then
                return true
            end
        end
    end
    return false
end

function RecordActorBone:OnCloseMovieEditor(movieclip)
    if movieclip then
        self:EndEditMovie(movieclip)
    end
end

function RecordActorBone:GenerateItemServerData(boneDt)
    if not boneDt then
        return
    end
    local serverDts = {}
    local assetfile = boneDt.assetfile
    local skin = boneDt.skin 
    local new_bone_dts = boneDt.new_bone_data 
    local boneDtNum = #new_bone_dts
    --构建单独骨骼的serverdata
    for i=1,boneDtNum do
        local dt ={}
        local serverdata = commonlib.copy(normalserverData)
        local timeseries = serverdata.timeseries
        --timeseries.facing = {times = {},data = {},ranges = {},type = "LinearAngle",name = "facing",}
        timeseries.assetfile = {times={0,},data={assetfile,},ranges={{1,1,},},type="Discrete",name="assetfile",}
        timeseries.skin = {times={0,},data={skin,},ranges={{1,1,},},type="Discrete",name="skin",}
        local temp = new_bone_dts[i]
        local key = temp.key
        local data = temp.data
        local select_bone_name = ""
        local bone_type
        local bones = {}
        bones.isContainer=true
        bones.range={times={},data={},ranges={},type="Discrete",name="range",}
        if string.find(key,"trans") or string.find(key,"rot") or string.find(key,"scale") then --选中单根骨骼
            select_bone_name ,bone_type = key:match("^(.*)_(%w+)$")
            bones[key] = data
        else --选中ik骨骼
            select_bone_name = key
            bone_type = "IK"
            for j=1,#data do
                local keyName = data[j].key
                local keyData = data[j].data
                bones[keyName] = keyData
            end
        end
        timeseries.bones = bones
        dt.select_bone_name = select_bone_name
        dt.serverdata = serverdata
        dt.bone_type = bone_type
        serverDts[#serverDts + 1] = dt
    end

    --构建整个角色的serverdata
    local serverdata1 = commonlib.copy(normalserverData)
    local timeseries = serverdata1.timeseries
    timeseries.assetfile = {times={0,},data={assetfile,},ranges={{1,1,},},type="Discrete",name="assetfile",}
    timeseries.skin = {times={0,},data={skin,},ranges={{1,1,},},type="Discrete",name="skin",}
    local bones = {}
    bones.isContainer=true
    bones.range={times={},data={},ranges={},type="Discrete",name="range",}
    for i=1,boneDtNum do
        local temp = new_bone_dts[i]
        local key = temp.key
        local data = temp.data
        local select_bone_name = ""
        local bone_type
        if string.find(key,"trans") or string.find(key,"rot") or string.find(key,"scale") then 
            bones[key] = data
        else
            for j=1,#data do
                local keyName = data[j].key
                local keyData = data[j].data
                bones[keyName] = keyData
            end
        end
    end
    timeseries.bones = commonlib.copy(bones)
    serverDts[#serverDts + 1] = {select_bone_name = select_bone_name,serverdata = serverdata1,bone_type = bone_type}
    --构建完成
    return serverDts
end

function RecordActorBone:GenerateBoneDatas()
    self.play_bone_data = {}
    local num = 0
    for k,v in pairs(self.record_data) do
        if v.pos and not v.boneData then
            local bx,by,bz = unpack(v.pos)
            local entity = EntityManager.GetBlockEntity(bx,by,bz)
            if(entity and entity.class_name == "EntityMovieClip")then
                local boneDt = self:GetActorBoneDatasByEntity(entity) 
                if boneDt then
                    v.boneData = boneDt
                end
            end
        end
        if v.boneData and #v.boneData > 0 then --bones
            local boneNum = #v.boneData
            for i=1,boneNum do
                local curBone = v.boneData[i]
                local boneDt = self:GetBoneDataByBones(v.boneData[i].bones)
                if boneDt then
                    -- curBone.bones = nil
                    curBone.new_bone_data = boneDt
                    
                    local serverDts = self:GenerateItemServerData(curBone)
                    if serverDts and #serverDts > 0 then
                        num = num + 1
                        self.play_bone_data[#self.play_bone_data + 1] = serverDts
                    end
                end
            end
        end
    end
    return num
end

function RecordActorBone:StartPlay(playtime,finish_callback)
    self.finish_call_back = finish_callback
    if not self.play_bone_data or #self.play_bone_data <= 0 then
        if finish_callback then
            finish_callback()
        end
        return 
    end
    self:StopPlay()
    self.isStopPlay = false
    self.play_index = 1
    self.max_play_index = #self.play_bone_data
    self:PlayBoneAni(playtime)
    if playtime and playtime > 0 then
        local time = playtime * 1000
        self.play_bone_timer = self.play_bone_timer or commonlib.Timer:new({callbackFunc = function(timer)
            if finish_callback then
                finish_callback()
            end
            self:StopPlay()
        end})
        self.play_bone_timer:Change(time);
    end
end

function RecordActorBone:PlayBoneAni(playtime)
    if self.play_index > self.max_play_index then
        if self.finish_call_back then
            self.finish_call_back()
        end
        self:StopPlay()
        return 
    end
    if playtime and playtime > 0 then
        local time = playtime * 1000
        local blockNum = math.min(self.max_play_index,5)
        local everyBlockTime = math.floor(time/blockNum + 0.5)
        local curPlayServerDatas = self.play_bone_data[self.play_index]
        local serverdataNum = #curPlayServerDatas
        local everyClipTime = math.floor(everyBlockTime/serverdataNum + 0.5)
        self:ChangeServerDataTimes(curPlayServerDatas,everyClipTime)
        if System.options.isDevMode then
            echo(curPlayServerDatas)
            print("play bone data ======","total time===="..time,"per block time=="..everyBlockTime,"actor num=="..serverdataNum,"per actor time=="..everyClipTime)
        end
        local aniIndex = 1
        local maxAniIndex = serverdataNum
        if maxAniIndex > 0 then
            play = function()
                if aniIndex <= maxAniIndex then
                    local serverdata = curPlayServerDatas[aniIndex].serverdata
                    local select_bone_name = curPlayServerDatas[aniIndex].select_bone_name or ""
                    local bone_type = curPlayServerDatas[aniIndex].bone_type
                    self:CreateEntityAndActor(serverdata,select_bone_name,bone_type)
                    aniIndex  = aniIndex  + 1
                    commonlib.TimerManager.SetTimeout(function()
                        play()
                    end, everyClipTime)
                else
                    self.play_index = self.play_index + 1
                    self:PlayBoneAni(playtime)
                end
            end
            play()
        end
    end
end

function RecordActorBone:ChangeServerDataTimes(serverdatas,everyClipTime)
    if serverdatas and everyClipTime and everyClipTime > 0 then
        local num = #serverdatas
        for i=1,num do
            local curData = serverdatas[i]
            local serverdata = curData.serverdata
            local bones = (curData and curData.serverdata and curData.serverdata.timeseries and curData.serverdata.timeseries.bones) and curData.serverdata.timeseries.bones or nil
            if bones then
                for key,bone in pairs(bones) do
                    if string.find(key,"trans") or string.find(key,"rot") or string.find(key,"scale") then
                        local times = bone.times
                        local frameNum = #times
                        local delta = math.floor(everyClipTime/frameNum + 0.5)
                        for i=1,frameNum do
                            bone.times[i] = (i-1) *delta
                        end
                    end
                end
            end
        end
    end
end

function RecordActorBone:StopPlay()
    MovieClipController.OnClose()
    local bx, by, bz = self:GetMovieBlockPos()
    BlockEngine:SetBlockToAir(bx, by, bz)

    if self.play_bone_timer then
        self.play_bone_timer:Change()
        self.play_bone_timer = nil
    end
end

function RecordActorBone:GetMovieBlockPos()
    return 19205,200,19201
end


function RecordActorBone:CreateEntityAndActor(serverdata,select_bone_name,bone_type)
    NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/MovieClipTimeLine.lua");
    local MovieClipTimeLine = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieClipTimeLine") 
    local SelectionManager = commonlib.gettable("MyCompany.Aries.Game.SelectionManager");
    local bx, by, bz = self:GetMovieBlockPos()
    BlockEngine:SetBlockToAir(bx, by, bz)
    local isSuc = BlockEngine:SetBlock(bx, by, bz,228)
    if isSuc then
        local entity = BlockEngine:GetBlockEntity(bx, by, bz);
        if(entity and entity.class_name == "EntityMovieClip")then
            entity:OpenEditor("entity", entity)
            local actor = self:CreateGetActor(entity,serverdata)
            if actor then
                local index = actor:FindEditVariableByName("bones");
                actor:SetCurrentEditVariableIndex(index);
                local manipCont = actor:GetBoneManipContainer()
                if select_bone_name and select_bone_name ~= "" and manipCont and manipCont.GetBonesManip then
                    local boneManip = manipCont:GetBonesManip()
                    if boneManip then
                        local selected_bone = boneManip:GetBoneByName(select_bone_name)
                        if selected_bone then
                            boneManip:SetSelectedBone(selected_bone, bone_type);
                        end
                    end
                end
            end
        end
        MovieClipController.OnPlay()
    end
end

function RecordActorBone:CreateGetActor(entity,serverdata)
	if not entity then
        return 
    end
    local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
    if(entity) then
        local new_itemstack = ItemStack:new():Init(block_types.names.TimeSeriesNPC, 1,serverdata);
        local itemStack = entity:CreateNpcByItemStack(new_itemstack)
        if itemStack then
            MovieClipController.SetFocusToItemStack(itemStack);
            local movieClip = MovieManager:GetActiveMovieClip()
            if(movieClip) then
                local actor = movieClip:GetActorFromItemStack(itemStack);
                if(actor) then
                    return actor;
                end
            end
        end
    end
end

function RecordActorBone:GetTempPath()
    return ParaIO.GetWritablePath().."temp/"
end

function RecordActorBone:IsReadOnlyWorld()
    return GameLogic.IsReadOnly()
end

function RecordActorBone:OnWorldLoaded()
    self.record_data = {}
    self.bone_data = {}
    self.current_movieclip = nil
    self:MoveXmlBoneFile()
    self:LoadBoneData()
end


function RecordActorBone:OnWorldUnloaded()
    if self:IsReadOnlyWorld() then --存储只读世界的骨骼编辑
        --有可能得拷贝资源文件到temp目录
        -- self:CopyFileToTempPath()
    end
end

function RecordActorBone:IsOfficailAssets(assetfile)
    if assetfile and assetfile ~= "" then
        local filepath = Files.GetFilePath(assetfile); 
        local file1 = "worlds/DesignHouse/"
        if string.find(filepath,file1) then
            return false
        end
        return true
    end
end

function RecordActorBone:LoadBoneData()
    local filename1 = GameLogic.GetWorldDirectory().."stats/"..xmlSavePath
    local filename = GameLogic.GetWorldDirectory()..xmlSavePath
    if self:LoadWorldBoneData(filename1) then
        self:LoadWorldBoneData(filename)
    end
end

function RecordActorBone:LoadWorldBoneData(filename)
    -- local filename = GameLogic.GetWorldDirectory()..xmlSavePath
    local xmlRoot = ParaXML.LuaXML_ParseFile(filename);
    if(xmlRoot) then
        local arr = commonlib.XPath.selectNodes(xmlRoot, "/user_bone_map");
        if arr and arr[1] then
            local list = arr[1]
            for k,v in ipairs(list) do
                local obj = v.attr
                local pos = NPL.LoadTableFromString(obj.pos)
                local bx,by,bz = unpack(NPL.LoadTableFromString(obj.pos))
                self.record_data[obj.id] = {}
                self.record_data[obj.id].pos = pos
                self.record_data[obj.id].editTime = tonumber(obj.editTime) or 0
            end
        end
        return true
    end
end

function RecordActorBone:MoveXmlBoneFile()
    if self:IsReadOnlyWorld() then
        return 
    end
    local filename1 = GameLogic.GetWorldDirectory().."stats/"..xmlSavePath
    local filename = GameLogic.GetWorldDirectory()..xmlSavePath
    local stats_folder = GameLogic.GetWorldDirectory().."stats/"
    if not ParaIO.DoesFileExist(stats_folder) then
        ParaIO.CreateDirectory(stats_folder)
    end
    
    if not ParaIO.DoesFileExist(filename1) and ParaIO.DoesFileExist(filename) then
        ParaIO.MoveFile(filename,filename1)
    end
end

function RecordActorBone:SaveWorldBoneData()
    if self:IsReadOnlyWorld() then
        return 
    end
    local filename = GameLogic.GetWorldDirectory().."stats/"..xmlSavePath
    local root = {name='user_bone_map', attr={file_version="0.1"} }
    for k,v in pairs(self.record_data) do
        local pos = v.pos
        local bx,by,bz = unpack(pos)
        local newKey = (bx or 0) * 100000000 +  (by or 0) * 1000000 + (bz or 0)
        if (v.boneData ~= nil and self:IsMovieEntityBlock(bx,by,bz)) then
            root[#root+1] = {
                name = "value",
                attr = {id = newKey,pos = commonlib.serialize_compact(pos),editTime = v.editTime or 0}
            }
        end
    end
    local xml_data = commonlib.Lua2XmlString(root, true, true) or "";
    local writer = ParaIO.CreateZip(filename, "");
    if (writer:IsValid()) then
        writer:ZipAddData("data", xml_data);
        writer:close();
    end
end

function RecordActorBone:IsMovieEntityBlock(bx,by,bz)
    local entity = BlockEngine:GetBlockEntity(bx, by, bz)
    if(entity and entity.class_name == "EntityMovieClip")then
        return true
    end
    return false
end

--设置只读世界数据，暂时不搞(怎么保证数据和文件的一致性)
--还有问题  1.拷贝文件到temp目录，文件名一样的处理
--          2.合并文件到世界目录，文件名一样的处理
function RecordActorBone:CopyFileToTempPath()
    if not self:IsReadOnlyWorld() then
        return 
    end
    local temp = {}
    local have = {}
    for k,v in pairs(self.record_data) do
        if v.boneData ~= nil and #v.boneData > 0 then
            for i=1,#v.boneData do
                local assets = v.boneData[i].assetfile
                if not self:IsOfficailAssets(assets) and not have[assets] then
                    temp[#temp + 1] = assets
                    have[assets] = true
                end
            end
        end
    end
    if #temp > 0 then
        self:CopyWorldToTemp(temp)
    end
end

function RecordActorBone:OpenFile(fileName)
    local file = ParaIO.open(fileName, "r");
    local strContent
    if(file and file:IsValid()) then
        strContent = file:GetText(0,-1)
        file:close();
    end
    return strContent
end

function RecordActorBone:GetBoneFilePath()
    return self:GetTempPath().."replay/bonedata.txt"
end

function RecordActorBone:LoadBoneDataFromTempFile()
    local boneInfo = {}
    local path = self:GetBoneFilePath()
    if not ParaIO.DoesFileExist(path) then
       return boneInfo
    end
    local strContent = self:OpenFile(path)
    if strContent then
        local data = commonlib.LoadTableFromString(strContent)
        if not data then
            ParaIO.DeleteFile(path)
            return boneInfo
        end
        boneInfo = data
    end
    return boneInfo
end


function RecordActorBone:SaveReadOnlyWorldBoneData()
    if not self:IsReadOnlyWorld() then
        return 
    end
    local path = self:GetBoneFilePath()
    local file_size = ParaIO.GetFileSize(path) or 0;
    file_size = math.floor(file_size/1024 + 0.5)
    if file_size >= 500 then
        return 
    end
    local saveData = {}
    for k,v in pairs(self.record_data) do
        if v.boneData ~= nil and #v.boneData > 0 then
            saveData[k] = v
        end
    end
    local curData = self:LoadBoneDataFromTempFile() or {}
    for k,v in pairs(saveData) do
        if curData[k] ~= nil then
            local key = ParaGlobal.GenerateUniqueID()
            curData[key] = v
        else
            curData[k] = v
        end
    end
    local saveStr = commonlib.serialize_compact(curData)
    if saveStr ~= "" then
        local path = self:GetBoneFilePath()
        if not ParaIO.DoesFileExist(path) then
            ParaIO.CreateDirectory(path)
        end
        local file = ParaIO.open(path, "w")
        if(file:IsValid()) then
            file:WriteString(saveStr);
            file:close();
        end
    end
end

-- @return true if succeed
function RecordActorBone:CopyWorldToTemp(sourseFiles)
    local worldzipfile = System.World.worldzipfile;
    if not worldzipfile or worldzipfile == "" or not sourseFiles or #sourseFiles == 0 then
        return
    end
    local maxIndex = #sourseFiles
    local zip_archive = ParaEngine.GetAttributeObject():GetChild("AssetManager"):GetChild("CFileManager"):GetChild(worldzipfile);
    local zipParentDir = zip_archive:GetField("RootDirectory", "");
    local filesOut = {};
    commonlib.Files.Find(filesOut, "", 0, 10000, ":.", worldzipfile);
    for i=1,maxIndex do
        local curFile = sourseFiles[i]
        for k = 1,#filesOut do
            local item = filesOut[k]
            local filename = item.filename
            filename = filename:gsub("^[^/]+/?", "")
            if(item.filesize > 0 and string.find(filename,curFile)) then
                local source_path = zipParentDir..item.filename
                local tempPath = self:GetTempPath().."replay/"
                local destFilename = tempPath..curFile
                if not ParaIO.DoesFileExist(destFilename) then
                    ParaIO.CreateDirectory(destFilename)
                end
                local re = ParaIO.CopyFile(source_path, destFilename, true)
                print("re====",tostring(re),source_path,destFilename)
            end
        end
    end
end

--合并只读世界的骨骼数据
function RecordActorBone:MergeBoneDataFromTempPath()
    
end

function RecordActorBone:CopyFileFromTempToWorld()
    local path = self:GetTempPath()
    local worldPath =GameLogic.GetWorldDirectory()
    local outfiles = {}
    commonlib.Files.Find(outfiles, "", 0, 10000, ":.", path);
    local num = #outfiles
    for i=1,num do
        local item = outfiles[i]
        local filename = item.filename
        if not self:IsDataFile(filename) then
            local destFile = worldPath..filename
            local re = ParaIO.CopyFile(path..filename, destFile, true)
        end
    end
end

function RecordActorBone:IsDataFile(filename)
    local filename = filename or ""
    return string.find(filename,"bonedata.txt") or string.find(filename,"codeblock.txt")
end


RecordActorBone:InitSingleton()