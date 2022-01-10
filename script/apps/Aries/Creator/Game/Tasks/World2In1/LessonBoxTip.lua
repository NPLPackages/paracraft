--[[
    author:pbb
    date:
    Desc:
    use lib:
        local LessonBoxTip = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/World2In1/LessonBoxTip.lua") 
        LessonBoxTip.ShowView()
]]

-- selection group index used to show the frame
local groupindex_hint_auto = 6;
local groupindex_wrong = 3;
local groupindex_hint = 5; -- when placeable but not matching hand block

--check_button_status
local check_width_bak = 0
local check_height_bak = 0
local ChatWindow = commonlib.gettable("MyCompany.Aries.ChatSystem.ChatWindow");
NPL.load("(gl)script/apps/Aries/Creator/Game/Sound/SoundManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/block_engine.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua");
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local SoundManager = commonlib.gettable("MyCompany.Aries.Game.Sound.SoundManager");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local LessonBoxCompare = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/World2In1/LessonBoxCompare.lua");
local World2In1 = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/World2In1.lua");
local LessonBoxTip = NPL.export()

local compare_type = -1
local tip_timer
local scale_timer
local errblock_timer 
local check_timer = nil
local lockarea_timer
LessonBoxTip.CheckBLockTips={
    [5]="我已经无法形容我的心情了！你已经可以担当一名小老师了！一起进行下一步吧！",
    [4]="我的天！你简直是一个天才！事不宜迟，马上开始下一步！",
    [3]="棒极了！你是我见到过的最聪明的学生！我想你已经等不及要下一步的吧？",
    [2]="太棒了！让我们进入下一步吧！",
    [1]="很好！那么让我们立即进入下一步！",
    [-1]="唔？好像有不对的地方，让我们再做一遍吧！",
    [-2]="可惜，还是有不对的地方，再好好检查一下？",
    [-3]="呃……这个可能确实有点难，好好回忆一下我的提示，再做一遍看看？",
    [-4]="还是不太对！别灰心，这个很容易，让我们再试一次！",
    [-5]="不要放弃！距离成功已经很接近了！让我们再来一次！",
    [-6]="好吧，我承认这个确实有一点难，我带着你手把手做一次吧？",
}

LessonBoxTip.RoleAni={
    [5]={{3,"Texture/blocks/Paperman/eye/eye_boy_I_01.png"},{4,"Texture/blocks/Paperman/mouth/mouth_girl_03_01.png"}},
    [4]={{3,"Texture/blocks/Paperman/eye/eye_boy_I_01.png"},{4,"Texture/blocks/Paperman/mouth/mouth_boy_05_01.png"}},
    [3]={{3,"Texture/blocks/Paperman/eye/eye_fanpai_le.png"},{4,"Texture/blocks/Paperman/mouth/mouth_boy_05_01.png"}},
    [2]={{3,"Texture/blocks/Paperman/eye/eye_fanpai_le.png"},{4,"Texture/blocks/Paperman/mouth/mouth_04.png"}},
    [1]={{3,"Texture/blocks/Paperman/eye/eye_fanpai_le.png"}},
    [-1]={{3,"Texture/blocks/Paperman/eye/eye_boy_L_01.png"}},
    [-2]={{3,"Texture/blocks/Paperman/eye/eye_boy_M_01.png"}},
    [-3]={{3,"Texture/blocks/Paperman/eye/eye_boy_R_01.png"}},
    [-4]={{3,"Texture/blocks/Paperman/eye/eye_boy_M_01.png"}},
    [-5]={{3,"Texture/blocks/Paperman/eye/eye_boy_S_01.png"}},
    [-6]={{3,"Texture/blocks/Paperman/eye/eye_boy_T_01.png"}},
}

LessonBoxTip.CheckMovieTips={
    slot = "没能在电影方块中找到对应的【摄影机】/【演员】，请先检查一下是否正确添加了【摄影机】/【演员】，或是调换了位置？",
    time = "电影方块的时长错了，正确的时长是【%s】，请重新设定",
    movie_clip = "没能在【摄影机】/【演员】上找到关键帧，请再核对一下",
    movie_prop_accurate = "",
    movie_prop_vague = "",
    actor_prop_accurate = "",
    actor_prop_vague = "",
}

LessonBoxTip.NomalTip = {
    check="仔细观察一下我这边，在绿色的格子中，摆放合适的方块吧！",
    movietarget="在电影方块中，%s",
    notfinish="像我这样，完成全部的操作吧！",
    no_change="这一步不需要改动地图，在熟悉完老师讲授的知识后，点击“开始检查”即可",
}
local checkIndex = 0
local page = nil
local page_root = nil
local lessonConfig = nil
local checkBtnType ="start"
local isFinishStage = false
LessonBoxTip.m_nCorrectCount = 0 --连续检查正确的次数
LessonBoxTip.NeedChangeBlocks = {} --检查以后错误的方块
LessonBoxTip.AllNeedBuildBlock = {} --小节开始时，所有需要创建或者删除的方块，用于备份
LessonBoxTip.CurNeedBuildBlock = {} --当前小节需要创建或者删除的方块
LessonBoxTip.m_nCreateBoxCount = 0
LessonBoxTip.m_nCurStageIndex = 0
LessonBoxTip.m_nMaxStageIndex = 0
LessonBoxTip.m_tblAllStageConfig = {}

function LessonBoxTip.OnInit()
    page = document:GetPageCtrl();
    if page and page:IsVisible() then
        page_root = page:GetParentUIObject()  
    end
end


function LessonBoxTip.ShowView()
    local view_width = 620
    local view_height = 220
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/World2In1/LessonBoxTip.html",
        name = "LessonBoxTip.ShowView", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        click_through = true,
        enable_esc_key = false,
        zorder = -13,
        app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key,
        directPosition = true,
        align = "_fi",
            x = 0,
            y = 0,
            width = 0,
            height = 0,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
    LessonBoxTip.UpdateCheckBtnScale()
    LessonBoxTip.RegisterEvent()
    commonlib.TimerManager.SetTimeout(function ()
        LessonBoxTip.InitTeacherPlayer()
    end, 100);
end


function LessonBoxTip.RegisterEvent()
    GameLogic:Connect("WorldUnloaded", LessonBoxTip, LessonBoxTip.OnWorldUnload, "UniqueConnection");
    World2In1.SetIsLessonBox(true)
end

function LessonBoxTip.OnWorldUnload()
    LessonBoxTip.EndTip()
    checkIndex = 0
    page = nil
    page_root = nil
    lessonConfig = nil
    checkBtnType ="start"
    LessonBoxTip.m_nCorrectCount = 0 --连续检查正确的次数
    LessonBoxTip.NeedChangeBlocks = {} --检查以后错误的方块
    LessonBoxTip.AllNeedBuildBlock = {} --小节开始时，所有需要创建或者删除的方块，用于备份
    LessonBoxTip.CurNeedBuildBlock = {} --当前小节需要创建或者删除的方块
    LessonBoxTip.m_nCreateBoxCount = 0
    LessonBoxTip.m_nCurStageIndex = 0
    LessonBoxTip.m_nMaxStageIndex = 0
    LessonBoxTip.m_tblAllStageConfig = {}
    LessonBoxTip.UnregisterHooks()
    LessonBoxTip.ClearBlockTip()
    LessonBoxTip.ClearErrorBlockTip()
    LessonBoxTip.ClosePage()
    LessonBoxTip.StopStageMovie()
    LessonBoxTip.EndAllTimer()
    ChatWindow.is_shown = true
    isFinishStage = false
end

function LessonBoxTip.InitTeacherPlayer()
    if page and page:IsVisible() then
        local module_ctl = page:FindControl("teacher_role")
        local scene = ParaScene.GetMiniSceneGraph(module_ctl.resourceName);
        if scene and scene:IsValid() then
            local player = scene:GetObject(module_ctl.obj_name);
            if player then
                player:SetScale(1)
                player:SetFacing(1.57);
                player:SetField("HeadUpdownAngle", 0.3);
                player:SetField("HeadTurningAngle", 0);
                player:SetField("assetfile","character/CC/02human/paperman/principal.x")
            end
        end
    end
end

local reset_timer = nil
function LessonBoxTip.PlayRoleAni(index)
    if page and page:IsVisible() then
        local module_ctl = page:FindControl("teacher_role")
        local scene = ParaScene.GetMiniSceneGraph(module_ctl.resourceName);
        if scene and scene:IsValid() then
            local player = scene:GetObject(module_ctl.obj_name);
            local aniConfig = LessonBoxTip.RoleAni[index]
            if aniConfig then
                for i=1,#aniConfig do
                    local cur = aniConfig[i]
                    player:SetReplaceableTexture(cur[1],ParaAsset.LoadTexture("",cur[2],1))
                end
            end
            if(reset_timer) then
                reset_timer:Change();
            end
            reset_timer = commonlib.TimerManager.SetTimeout(function ()
                player:SetReplaceableTexture(3,player:GetDefaultReplaceableTexture(3))
                player:SetReplaceableTexture(4,player:GetDefaultReplaceableTexture(4))
            end, 1500);
        end
    end
end

function LessonBoxTip.AddOperateCount(count)
    if type(count) == "number" then
        LessonBoxTip.m_nCreateBoxCount = LessonBoxTip.m_nCreateBoxCount + count
        return 
    end
    LessonBoxTip.m_nCreateBoxCount = LessonBoxTip.m_nCreateBoxCount + 1
end
--/select 18870,13,19151(-19,1,-19)
function LessonBoxTip.InitLessonConfig(config)
    if config then
        lessonConfig = config
        echo(config,true)
        LessonBoxTip.InitLessonData()
        LessonBoxTip.m_nMaxStageIndex = #lessonConfig.taskCnf
        LessonBoxTip.m_nCurStageIndex = LessonBoxTip.m_nCurStageIndex + 1
        -- echo(lessonConfig.taskCnf,true)
        -- print("maxstage============",LessonBoxTip.m_nMaxStageIndex,#lessonConfig.taskCnf)
        LessonBoxTip.PrepareStageScene()
    end
end

function LessonBoxTip.ClearLearnArea(area)
    if not area or not area.pos or not area.size then
        return 
    end
    -- print("ClearLearnArea==============")
    -- echo(area)
    GameLogic.RunCommand(string.format("/select %d,%d,%d (%d %d %d)",area.pos[1],area.pos[2],area.pos[3],area.size[1],area.size[2],area.size[3]))
    GameLogic.RunCommand("/del")
    GameLogic.RunCommand("/select -clear")
end

local Isprepare = false
local isStopMovieBySelf = false
--18663,12,19336(49,1,20)
function LessonBoxTip.PrepareStageScene()
    if not lessonConfig then
        GameLogic.AddBBS(nil,"课程初始化失败")
        return 
    end
    Isprepare = true
    isFinishStage = false
    isStopMovieBySelf = false
    LessonBoxTip.EndTip()
    local stagePos = lessonConfig.teachStage
    if stagePos[1] then
        GameLogic.GetPlayer():MountEntity(nil);
        GameLogic.RunCommand(string.format("/goto %d,%d,%d",stagePos[1],stagePos[2],stagePos[3]))
    end
    local lookPos = lessonConfig.lookPos
    if lookPos then
        GameLogic.RunCommand(string.format("/lookat %d,%d,%d",lookPos[1],lookPos[2],lookPos[3]))
    end
    LessonBoxTip.PlayLessonMusic("lesson")
    ChatWindow.is_shown = false
    -- print("runcommand showMask===============start")
    GameLogic.RunCommand("/sendevent showMask")
    -- print("runcommand showMask===============end")
    local taskCnf = lessonConfig.taskCnf[LessonBoxTip.m_nCurStageIndex]
    local moivePos = taskCnf.moviePos
    -- if moivePos[1] then

    -- end
    GameLogic.RunCommand("/sendevent hideNpc")
    GameLogic.GetCodeGlobal():BroadcastTextEvent("playstagemovie", {config = taskCnf});
    GameLogic.RunCommand("/ggs user hidden");
end


function LessonBoxTip.StopStageMovie()
    isStopMovieBySelf = true
    GameLogic.GetCodeGlobal():BroadcastTextEvent("stopStageMovie");
end

function LessonBoxTip.StartCurStage()
    -- print("StartCurStage=============== 18692,13,19355")
    if isStopMovieBySelf then
        isStopMovieBySelf = false
        -- print("cccccccccccccccc")
        return 
    end
    local taskArea = lessonConfig.stageArea
    local posTeacher = lessonConfig.templateteacher
    local posMy = lessonConfig.templatemy
    local taskCnf = lessonConfig.taskCnf[LessonBoxTip.m_nCurStageIndex]
    -- print("clear start")
    LessonBoxTip.ClearLearnArea(taskArea)
    -- print("clear end")
    LessonBoxTip.ShowView()
    commonlib.TimerManager.SetTimeout(function()
        Isprepare = false
        local endTemp = taskCnf.finishtemplate
        local startTemp = taskCnf.starttemplate
        -- print("temp========",endTemp,startTemp)
        -- print(string.format("/loadtemplate %d,%d,%d %s",posMy[1],posMy[2],posMy[3],startTemp))
        -- print(string.format("/loadtemplate %d,%d,%d %s",posTeacher[1],posTeacher[2],posTeacher[3],endTemp))
        -- echo(lessonConfig,true)
        GameLogic.RunCommand("/clearbag")
        GameLogic.RunCommand(string.format("/loadtemplate %d,%d,%d %s",posMy[1],posMy[2],posMy[3],startTemp))
        GameLogic.RunCommand(string.format("/loadtemplate %d,%d,%d %s",posTeacher[1],posTeacher[2],posTeacher[3],endTemp))
        local stagePos = lessonConfig.myStage
        if stagePos[1] then
            GameLogic.GetPlayer():MountEntity(nil);
            GameLogic.RunCommand(string.format("/goto %d,%d,%d",stagePos[1],stagePos[2],stagePos[3]))
            --GameLogic.RunCommand("/camerayaw 1.57")
        end
        LessonBoxTip.PlayLessonMusic("lesson_operate")
        LessonBoxTip.StartTip()
        LessonBoxTip.StartLearn()
    end,700)
end

function LessonBoxTip.ResetMyArea()
    if not lessonConfig then
        return 
    end
    local taskCnf = lessonConfig.taskCnf[LessonBoxTip.m_nCurStageIndex]
    local startTemp = taskCnf.starttemplate
    local posMy = lessonConfig.templatemy
    local regionsrc = lessonConfig.regionMy
    LessonBoxTip.ClearLearnArea(regionsrc)
    commonlib.TimerManager.SetTimeout(function()
        GameLogic.RunCommand(string.format("/loadtemplate %d,%d,%d %s",posMy[1],posMy[2],posMy[3],startTemp))
        GameLogic.AddBBS("resetArea","区域已恢复到初始状态")
        LessonBoxTip.RenderBlockTip()
    end,500)
end

function LessonBoxTip.InitLessonData()
    checkIndex = 0
    checkBtnType ="start"
    LessonBoxTip.m_nCorrectCount = 0 --连续检查正确的次数
    LessonBoxTip.m_nCreateBoxCount = 0
    LessonBoxTip.NeedChangeBlocks = {} --检查以后错误的方块
    LessonBoxTip.AllNeedBuildBlock = {} --小节开始时，所有需要创建或者删除的方块，用于备份
    LessonBoxTip.CurNeedBuildBlock = {} --当前小节需要创建或者删除的方块
    LessonBoxTip.CreatePos = nil
    LessonBoxTip.SrcBlockOrigin = nil
    LessonBoxTip.m_nCurStageIndex = 0
    LessonBoxTip.m_nMaxStageIndex = 0
end

function LessonBoxTip.RegisterHooks()
	GameLogic.events:AddEventListener("CreateBlockTask", LessonBoxTip.OnCreateBlockTask, LessonBoxTip, "LessonBoxTip");
    GameLogic.events:AddEventListener("CreateDiffIdBlockTask", LessonBoxTip.OnCreateBlockTask, LessonBoxTip, "LessonBoxTip");
    GameLogic.events:AddEventListener("DestroyBlockTask", LessonBoxTip.OnDestroyBlockTask, LessonBoxTip, "LessonBoxTip");
    GameLogic.GetFilters():add_filter("lessonbox_change_region_blocks",function(blocks)
        -- echo(commonlib.debugstack(),true)
        -- print("block num changes============",blocks and #blocks or 0)
        -- echo(blocks)
        if type(blocks) == "number" then
            LessonBoxTip.AddOperateCount(blocks)
        elseif type(blocks) == "table" then
            LessonBoxTip.AddOperateCount(#blocks)
        end
        
    end)
end

function LessonBoxTip.UnregisterHooks()
	GameLogic.events:RemoveEventListener("CreateBlockTask", LessonBoxTip.OnCreateBlockTask, LessonBoxTip);
    GameLogic.events:RemoveEventListener("CreateDiffIdBlockTask", LessonBoxTip.OnCreateBlockTask, LessonBoxTip);
    GameLogic.events:RemoveEventListener("DestroyBlockTask", LessonBoxTip.OnDestroyBlockTask, LessonBoxTip);
    GameLogic.GetFilters():remove_filter("lessonbox_change_region_blocks", function() end);
    LessonBoxTip.EndTip()
end

function LessonBoxTip.OnDestroyBlockTask(self,event)
    -- print("OnCreateBlockTask=================1'")
    --echo(self,true)
    -- echo(event,true)
	if(event.x) then
        LessonBoxTip.AddOperateCount()
        local startPos = LessonBoxTip.CreatePos and LessonBoxTip.CreatePos or lessonConfig.regionMy.pos
		local x, y, z = unpack(startPos);
		x, y, z = event.x - x, event.y -y, event.z-z;
        -- echo(startPos)
        -- echo(LessonBoxTip.CreatePos)
		local block = LessonBoxTip.FindBlock(x, y, z);
        -- echo(block and block[4] > 6)
		if(block) then --and block[4] == event.block_id
            LessonBoxTip.FinishBlock(x, y, z)
		end
	end
end

function LessonBoxTip.OnCreateBlockTask(self,event)
    -- print("OnCreateBlockTask=================1'")
    --echo(self,true)
    -- echo(event,true)
	if(event.x) then
        LessonBoxTip.AddOperateCount()
        local startPos = LessonBoxTip.CreatePos and LessonBoxTip.CreatePos or lessonConfig.regionMy.pos
		local x, y, z = unpack(startPos);
		x, y, z = event.x - x, event.y -y, event.z-z;
        -- echo(startPos)
        -- echo(LessonBoxTip.CreatePos)
		local block = LessonBoxTip.FindBlock(x, y, z);
        -- echo(block and block[4] > 6)
		if(block) then --and block[4] == event.block_id
            LessonBoxTip.FinishBlock(x, y, z)
		end
	end
end

function LessonBoxTip.UpdateCreateResult()

end



function LessonBoxTip.StartLearn()
    --print("StartLearn=================")
    if LessonBoxCompare and lessonConfig then
        -- GameLogic.RunCommand(string.format("/loadtemplate 18873,12,19156 %s",lessonConfig.starttemplate))
        local regionsrc = lessonConfig.regionMy
        local regiondest = lessonConfig.regionOther
        --print("StartLearn=================1")
        --echo({regionsrc,regiondest})
        local taskCnf = lessonConfig.taskCnf[LessonBoxTip.m_nCurStageIndex]
        if taskCnf and taskCnf.starttemplate == taskCnf.finishtemplate then
            LessonBoxTip.SetTaskTip("no_change")
            LessonBoxTip.SetRoleName()
            LessonBoxTip.SetLessonTitle()
        else
            LessonBoxCompare.CompareTwoAreas(regionsrc,regiondest,function(needbuild,pivotConfig)
                --echo(needbuild)
                LessonBoxTip.AllNeedBuildBlock = needbuild.blocks
                LessonBoxTip.CurNeedBuildBlock = needbuild.blocks
                LessonBoxTip.CreatePos = pivotConfig.createpos
                LessonBoxTip.SrcBlockOrigin = pivotConfig.srcPivot
                LessonBoxTip.SetLessonTitle()
                compare_type = needbuild.nAddType
                if(#needbuild.blocks == 0 and needbuild.nAddType == 3)then
                    local movieBlocks = needbuild.movies
                    local codeBlocks = needbuild.codes
                    LessonBoxTip.CompareCode(codeBlocks)
                    --LessonBoxTip.CompareMovie(movieBlocks)
                else
                    -- LessonBoxTip.AutoEquipHandTools()
                    LessonBoxTip.RegisterHooks()
                    commonlib.TimerManager.SetTimeout(function()
                        LessonBoxTip.SetTaskTip("check")
                        LessonBoxTip.SetRoleName()
                        LessonBoxTip.UpdateNextBtnStatus()
                        LessonBoxTip.RenderBlockTip()
                    end,200)
                end
            end)
        end
    end
end

function LessonBoxTip.CompareCode(blocks)
    if type(blocks) == "table" then
        if #blocks == 0 then
            LessonBoxTip.RemoveErrBlockTip()
            LessonBoxTip.SetErrorTip(LessonBoxTip.m_nCorrectCount)
            GameLogic.AddBBS(nil,"当前小节已完成，你可以点击检查进入下一小节")
            commonlib.TimerManager.SetTimeout(function()
                LessonBoxTip.ClearErrorBlockTip()
                LessonBoxTip.RemoveErrBlockTip()
                LessonBoxTip.ClearBlockTip()
                -- LessonBoxTip.GotoNextStage()
                
            end,1000)
        else
            for i=1,#blocks do
                local possrc,posdest = LessonBoxTip.AddTwoPosition(blocks[i][1],LessonBoxTip.CreatePos),LessonBoxTip.AddTwoPosition(blocks[i][2],LessonBoxTip.SrcBlockOrigin)
                local entitySrc = EntityManager.GetBlockEntity(possrc)
                local entityDest = EntityManager.GetBlockEntity(posdest)
                local bSame,nType = LessonBoxCompare.CompareCode(entitySrc,entityDest)
                if not bSame then
                    
                    break
                end
            end
        end
    end
end

function LessonBoxTip.CompareMovie(blocks)
    if type(blocks) == "table" then
        if #blocks == 0 then
            LessonBoxTip.RemoveErrBlockTip()
            LessonBoxTip.SetErrorTip(LessonBoxTip.m_nCorrectCount)
            GameLogic.AddBBS(nil,"当前小节已完成，你可以点击检查进入下一小节")
            commonlib.TimerManager.SetTimeout(function()
                LessonBoxTip.ClearErrorBlockTip()
                LessonBoxTip.RemoveErrBlockTip()
                LessonBoxTip.ClearBlockTip()
                -- LessonBoxTip.GotoNextStage()
            end,1000)
        else
            for i=1,#blocks do
                local possrc,posdest = LessonBoxTip.AddTwoPosition(blocks[i][1],LessonBoxTip.CreatePos),LessonBoxTip.AddTwoPosition(blocks[i][2],LessonBoxTip.SrcBlockOrigin)
                local entitySrc = EntityManager.GetBlockEntity(possrc)
                local entityDest = EntityManager.GetBlockEntity(posdest)
                local bSame,type = LessonBoxCompare.CompareMovieClip(entitySrc,entityDest)
                if not bSame then

                    break
                end
            end
        end
    end
    -- LessonBoxCompare.CompareMovieClip
end

function LessonBoxTip.AddTwoPosition(pos1,pos2)
    if not pos1 or not pos2 then
        return 
    end
    local newPos = {}
    newPos = {pos1[1]+pos2[1],pos1[2]+pos2[2],pos1[3]+pos2[3]}
    return newPos
end

function LessonBoxTip.RenderBlockTip()
    local startPos = LessonBoxTip.CreatePos and LessonBoxTip.CreatePos or lessonConfig.regionMy.pos
    for i = 1,#LessonBoxTip.CurNeedBuildBlock do
        local block = LessonBoxTip.CurNeedBuildBlock[i]
        local x,y,z = startPos[1]+block[1],startPos[2]+block[2],startPos[3]+block[3]
        ParaTerrain.SelectBlock(x,y,z, true, groupindex_hint_auto);
        -- print("pos=========",x,y,z)
    end
end

function LessonBoxTip.ClearBlockTip()
    if not lessonConfig then
        return
    end
    local startPos = LessonBoxTip.CreatePos and LessonBoxTip.CreatePos or lessonConfig.regionMy.pos
    for i = 1,#LessonBoxTip.AllNeedBuildBlock do 
        local block = LessonBoxTip.AllNeedBuildBlock[i]
        local x,y,z = startPos[1]+block[1],startPos[2]+block[2],startPos[3]+block[3]
        ParaTerrain.SelectBlock(x,y,z, false, groupindex_hint_auto);
        -- print("ClearBlockTip===========")
    end
end

function LessonBoxTip.RenderErrorBlockTip()
    --clear
    local startPos = LessonBoxTip.CreatePos and LessonBoxTip.CreatePos or lessonConfig.regionMy.pos
    for i = 1,#LessonBoxTip.NeedChangeBlocks do 
        local block = LessonBoxTip.NeedChangeBlocks[i]
        local x,y,z = startPos[1]+block[1],startPos[2]+block[2],startPos[3]+block[3]
        ParaTerrain.SelectBlock(x,y,z, false, groupindex_wrong);
    end
    --set
    local block = LessonBoxTip.NeedChangeBlocks[checkIndex]
    if block then
        local x,y,z = startPos[1]+block[1],startPos[2]+block[2],startPos[3]+block[3]
        ParaTerrain.SelectBlock(x,y,z, true, groupindex_wrong);
        LessonBoxTip.UpdateErrArrow({block[1],block[2],block[3]})
    end    
end

function LessonBoxTip.UpdateErrArrow(pos)
    if not pos or not LessonBoxTip.CreatePos[1] or not LessonBoxTip.SrcBlockOrigin[1] then
        return
    end
    local startPos = LessonBoxTip.CreatePos and LessonBoxTip.CreatePos or lessonConfig.regionMy.pos
    local leftPos = {startPos[1]+pos[1],startPos[2]+pos[2],startPos[3]+pos[3]}
    startPos = LessonBoxTip.SrcBlockOrigin and LessonBoxTip.SrcBlockOrigin or lessonConfig.regionOther.pos
    local rightPos = {startPos[1]+pos[1],startPos[2]+pos[2],startPos[3]+pos[3]}
    GameLogic.GetCodeGlobal():BroadcastTextEvent("showArrow", {leftpos=leftPos,rightpos = rightPos});
end

function LessonBoxTip.ClearErrorBlockTip()
    if not lessonConfig then
        return
    end
    local startPos = LessonBoxTip.CreatePos and LessonBoxTip.CreatePos or lessonConfig.regionMy.pos
    for i = 1,#LessonBoxTip.NeedChangeBlocks do 
        local block = LessonBoxTip.NeedChangeBlocks[i]
        local x,y,z = startPos[1]+block[1],startPos[2]+block[2],startPos[3]+block[3]
        ParaTerrain.SelectBlock(x,y,z, false, groupindex_wrong);
    end
    GameLogic.RunCommand("/sendevent hideArrow")
end

function LessonBoxTip.FindBlock(x, y, z)
    for i = 1,#LessonBoxTip.AllNeedBuildBlock do
        local block = LessonBoxTip.AllNeedBuildBlock[i]
        if block[1] == x and block[2] == y and block[3] == z then
            return block
        end
    end
end

function LessonBoxTip.FinishBlock(x, y, z)
    for i = 1,#LessonBoxTip.CurNeedBuildBlock do
        local block = LessonBoxTip.CurNeedBuildBlock[i]
        if block[1] == x and block[2] == y and block[3] == z then
            block.finish = true
        end
    end
end

function LessonBoxTip.CheckFinishAll()
    local curOperateNum = LessonBoxTip.m_nCreateBoxCount
    -- print("num=============",LessonBoxTip.m_nCreateBoxCount,#LessonBoxTip.CurNeedBuildBlock)
    if curOperateNum >= #LessonBoxTip.CurNeedBuildBlock then
        return true
    end
    return false
    -- local isFinish = true
    -- for i = 1,#LessonBoxTip.CurNeedBuildBlock do
    --     local block = LessonBoxTip.CurNeedBuildBlock[i]
    --     if not block.finish then
    --         isFinish = false
    --         break
    --     end
    -- end
    -- return isFinish
end

function LessonBoxTip.AutoEquipHandTools()
    if not lessonConfig then
        return 
    end
    local part = {}
    for i = 1,#LessonBoxTip.AllNeedBuildBlock do
        local block = LessonBoxTip.AllNeedBuildBlock[i]
        if block and block[4] then
            part[block[4]] = block[4]
        end
    end
    local temp = {}
    for k,v in pairs(part) do
        temp[#temp + 1] = v
    end
    -- echo(temp)

    local player = EntityManager.GetPlayer();
    local count = #temp

    for idx =1, 9 do
        if(idx<=count) then
            player.inventory:SetItemByBagPos(idx, temp[idx]);
            -- print("SetItemByBagPos",idx,temp[idx])
        else
            player.inventory:SetItemByBagPos(idx, 0);
        end
    end
    player.inventory:SetHandToolIndex(1);    
end




function LessonBoxTip.SetRoleName()
    if page and lessonConfig then
        local name = lessonConfig.teacherName or "校长" 
        -- print("SetRoleName===",name)
        page:SetValue("role_name", name);
        
    end
end

function LessonBoxTip.SetTaskTip(type)
    if page then
        local strTip = LessonBoxTip.NomalTip[type]
        page:SetValue("role_tip", strTip);
        if strTip then
            SoundManager:PlayText(strTip,10006)
        end
    end
end

function LessonBoxTip.SetErrorTip(index)
    if page then
        index = index or 1
        local strTip = str or LessonBoxTip.CheckBLockTips[index]
        page:SetValue("role_tip", strTip);
        if strTip then
            LessonBoxTip.PlayRoleAni(index)
            SoundManager:PlayText(strTip,10006)
        end
    end
end

function LessonBoxTip.SetLessonTitle()
    if lessonConfig and page then
        local curStage = LessonBoxTip.m_nCurStageIndex
        local taskCnf = lessonConfig.taskCnf[curStage]
        local strTitle = string.format("%s步骤%d-%s",lessonConfig.stageTitle,lessonConfig.learnIndex,taskCnf.name) 
        page:SetValue("lesson_title", strTitle);
    end
end

function LessonBoxTip.ReplayMovie()
    if LessonBoxTip.CheckHasePlayMovie() or Isprepare == true then
        GameLogic.AddBBS(nil,"当前正在播放其他的动画或动画没有准备好,请稍后")
        return
    end
    LessonBoxTip.EndTip()
    local taskCnf = lessonConfig.taskCnf[LessonBoxTip.m_nCurStageIndex]
    local moivePos = taskCnf.moviePos
    if moivePos[1] then
        LessonBoxTip.ClosePage() 
        local stagePos = lessonConfig.teachStage
        if stagePos[1] then
            GameLogic.RunCommand(string.format("/goto %d,%d,%d",stagePos[1],stagePos[2],stagePos[3]))
        end
        local lookPos = lessonConfig.lookPos
        if lookPos then
            GameLogic.RunCommand(string.format("/lookat %d,%d,%d",lookPos[1],lookPos[2],lookPos[3]))
        end
        GameLogic.GetCodeGlobal():BroadcastTextEvent("playstagemovie", {config = taskCnf,isOnlyPlay = true});
    end
end
--请按照园长的讲解，在自己的区域也练习一遍吧！
function LessonBoxTip.ResumeLessonUI()
    LessonBoxTip.ShowView()
    LessonBoxTip.SetLessonTitle()
    LessonBoxTip.SetTaskTip("check")
    LessonBoxTip.SetRoleName()
    LessonBoxTip.UpdateNextBtnStatus()
    GameLogic.RunCommand("/sendevent showNpc")
    GameLogic.RunCommand("/sendevent showMask")
    local stagePos = lessonConfig.myStage
    if stagePos[1] then
        GameLogic.RunCommand(string.format("/goto %d,%d,%d",stagePos[1],stagePos[2],stagePos[3]))
    end
    GameLogic.RunCommand("/tip")
    LessonBoxTip.StartTip()
    commonlib.TimerManager.SetTimeout(function()
        LessonBoxTip.RenderBlockTip()
    end,200)
end

function LessonBoxTip.StartTip(strType)
    tip_timer = tip_timer or commonlib.Timer:new({callbackFunc = function(timer)
		GameLogic.AddBBS(nil,"请按照讲解练习一遍吧，练习好后点击按钮【开始检查】查看结果！",3000)
	end})
	tip_timer:Change(0, 10000);
end

function LessonBoxTip.EndTip()
    if tip_timer then
        tip_timer:Change()
    end
end

function LessonBoxTip.CheckHaseNextErr(nDis)
    if LessonBoxTip.NeedChangeBlocks[checkIndex + nDis] ~= nil then
        return true
    end
    return false
end

function LessonBoxTip.ClosePage() 
    if page then
        page:CloseWindow()
        page = nil
    end
    if errblock_timer then
        errblock_timer:Change()
        errblock_timer = nil
    end
    if scale_timer then
        scale_timer:Change()
        scale_timer = nil
        check_width_bak = 0
        check_height_bak = 0
    end
end

function LessonBoxTip.IsCompareAutoBlock()
    local blocks = LessonBoxTip.AllNeedBuildBlock
    if blocks and #blocks > 0 then
        for i=1,#blocks do
            if blocks[i][4] == 267 or blocks[i][4] == 103  then
                return true
            end
        end
    end
    return false
end

function LessonBoxTip.IsShowFollowBt()
    local taskCnf = lessonConfig.taskCnf[LessonBoxTip.m_nCurStageIndex]
    if taskCnf and taskCnf.follow and taskCnf.follow[1] then
        return true
    end

    return false
end

function LessonBoxTip.IsShowMoviceBt()
    local taskCnf = lessonConfig.taskCnf[LessonBoxTip.m_nCurStageIndex]
    if taskCnf and taskCnf.moviePos and taskCnf.moviePos[1] then
        return true
    end

    return false
end

function LessonBoxTip.StartCheck()
    local taskCnf = lessonConfig.taskCnf[LessonBoxTip.m_nCurStageIndex]
    if taskCnf and taskCnf.starttemplate == taskCnf.finishtemplate then
        LessonBoxTip.RemoveErrBlockTip()
        LessonBoxTip.SetErrorTip(1)
        isFinishStage = true
        GameLogic.AddBBS(nil,"当前小节已完成，即将进入下一小节的学习")
        commonlib.TimerManager.SetTimeout(function()
            LessonBoxTip.ClearErrorBlockTip()
            LessonBoxTip.RemoveErrBlockTip()
            LessonBoxTip.ClearBlockTip()
            LessonBoxTip.GotoNextStage()
        end,4000)
    end

    if check_timer then
        check_timer:Change()
    end   
    check_timer = commonlib.TimerManager.SetTimeout(function()
        if LessonBoxTip.CheckHasePlayMovie() then
            GameLogic.AddBBS(nil,"先去老师区域，看完操作演示吧")
            return
        end
        if isFinishStage then
            GameLogic.AddBBS(nil,"当前小节已经完成了，正在跳转下一小节，请等待")
            return
        end
        if not LessonBoxTip.CheckFinishAll() and not LessonBoxTip.IsCompareAutoBlock() then
            if compare_type == 1  or compare_type == 3 then
                LessonBoxTip.RemoveErrBlockTip()
                LessonBoxTip.SetTaskTip("notfinish")
                compare_type = -1
                return 
            end
        end
        checkBtnType = "stop"
        LessonBoxTip.UpdateCheckBtnStatus(checkBtnType)
        LessonBoxTip.ClearBlockTip()
        LessonBoxTip.ClearErrorBlockTip()
        if LessonBoxCompare and lessonConfig then
            local regionsrc = lessonConfig.regionMy
            local regiondest = lessonConfig.regionOther
            LessonBoxCompare.CompareTwoAreas(regionsrc,regiondest,function(needbuild,pivot)
                -- echo(needbuild,true)
                local isCorrect = false
                local blocks = needbuild.blocks
                if needbuild.nAddType ~= 3 then
                    -- LessonBoxTip.m_nCorrectCount = 0
                    LessonBoxTip.m_nCorrectCount = LessonBoxTip.m_nCorrectCount - 1
                    LessonBoxTip.NeedChangeBlocks = blocks
                    checkIndex = 1
                    LessonBoxTip.RenderErrorBlockTip()
                    LessonBoxTip.UpdateNextBtnStatus()
                else
                    if #blocks == 0 then
                        if LessonBoxTip.m_nCorrectCount < 0 then
                            LessonBoxTip.m_nCorrectCount = 0
                        end
                        isCorrect = true
                        LessonBoxTip.m_nCorrectCount = LessonBoxTip.m_nCorrectCount + 1
                    else
                        if LessonBoxTip.m_nCorrectCount > 0 then
                            LessonBoxTip.m_nCorrectCount = 0
                        end
                        LessonBoxTip.m_nCorrectCount = LessonBoxTip.m_nCorrectCount - 1
                        LessonBoxTip.NeedChangeBlocks = blocks
                        checkIndex = 1
                        LessonBoxTip.RenderErrorBlockTip()
                        LessonBoxTip.UpdateNextBtnStatus()
                    end
                end
                if isCorrect then
                    LessonBoxTip.RemoveErrBlockTip()
                    LessonBoxTip.SetErrorTip(LessonBoxTip.m_nCorrectCount)
                    isFinishStage = true
                    local finish_desc = lessonConfig.is_lx and "当前练习已完成" or "当前小节已完成，即将进入下一小节的学习"
                    GameLogic.AddBBS(nil,finish_desc)
                    commonlib.TimerManager.SetTimeout(function()
                        LessonBoxTip.ClearErrorBlockTip()
                        LessonBoxTip.RemoveErrBlockTip()
                        LessonBoxTip.ClearBlockTip()
                        if lessonConfig.is_lx then
                            LessonBoxTip.OnRetunMacro(true)
                        else
                            LessonBoxTip.GotoNextStage()
                        end
                        
                    end,5000)
                    return
                end
                if LessonBoxTip.m_nCorrectCount <= -5 then
                    if taskCnf.follow and taskCnf.follow[1] then
                        _guihelper.MessageBox("开启教学模式，跟着帕帕卡卡拉拉一起手把手一步一步完成课程的学习吧！",function()
                            LessonBoxTip.OnStartMacroLearn()
                        end)
                    end

                    if lessonConfig.is_lx then
                        LessonBoxTip.m_nCorrectCount = -5
                    end
                end
                if LessonBoxTip.m_nCorrectCount < - 6 then LessonBoxTip.m_nCorrectCount = -6  end
                if LessonBoxTip.m_nCorrectCount > 5 then LessonBoxTip.m_nCorrectCount = 5 end
                if LessonBoxTip.m_nCorrectCount <=5 and LessonBoxTip.m_nCorrectCount >= -6 then
                    LessonBoxTip.RemoveErrBlockTip()
                    LessonBoxTip.SetErrorTip(LessonBoxTip.m_nCorrectCount)
                    LessonBoxTip.DelayShowErrBlockTip()
                    
                end
            end)
        end
    end,500)
end


function LessonBoxTip.DelayShowErrBlockTip()
    if errblock_timer then
        errblock_timer:Change();
    end
    errblock_timer = commonlib.TimerManager.SetTimeout(function ()
        LessonBoxTip.SetErrBlockTip()
    end, 3000);
end
function LessonBoxTip.UpdateCheckBtnStatus(type)
    if type == "stop" then
        local back1 = "Texture/Aries/Creator/keepwork/macro/lessonbox/btn_sc_128X47_32bits.png;0 0 128 47"
        local back2 = "Texture/Aries/Creator/keepwork/macro/lessonbox/btn_sc1_128X47_32bits.png;0 0 128 47"
        
        local btnObject = ParaUI.GetUIObject("lesson_check_button")
        if (btnObject) then
            btnObject.background = back2
            commonlib.TimerManager.SetTimeout(function()
                btnObject.background = back1
            end,1000)
        end
    end
end

-- @param maxScaling: default to 0.9. usually between [0.8, 1.2]
function LessonBoxTip.UpdateCheckBtnScale(maxScaling)
    local btnObject = ParaUI.GetUIObject("lesson_check_button")
    if (btnObject and btnObject:IsValid()) then
		maxScaling = maxScaling or 0.9;
		local curScaling = 1;
		local scale_state = "add"
		local scaleStep = math.abs(maxScaling - 1) / 20;
		local maxScale = math.max(1, maxScaling)
		local minScale = math.min(1, maxScaling)
        scale_timer = commonlib.Timer:new({callbackFunc = function(timer)
            if scale_state == "add" then
                curScaling = curScaling + scaleStep
				if(curScaling > maxScale) then
					curScaling = maxScale;
					scale_state = "reduce"
				end
            elseif scale_state == "reduce" then
				curScaling = curScaling - scaleStep
				if(curScaling < minScale) then
					curScaling = minScale;
					scale_state = "add"
				end
            end
			btnObject.scalingx = curScaling
			btnObject.scalingy = curScaling
        end})
        scale_timer:Change(0, 30);
    end
end

function LessonBoxTip.UpdateNextBtnStatus()
    local btnNextObject = ParaUI.GetUIObject("lesson_next_button")
    local btnPreObject = ParaUI.GetUIObject("lesson_pre_button")
    btnNextObject.visible = false
    if LessonBoxTip.CheckHaseNextErr(1) then
        btnNextObject.visible = true
    end
    btnPreObject.visible = false
    if LessonBoxTip.CheckHaseNextErr(-1) then
        btnPreObject.visible = true
    end
end

function LessonBoxTip.StopCheck()
    LessonBoxTip.ClearBlockTip()
    LessonBoxTip.ClearErrorBlockTip()
    checkIndex = 0
    LessonBoxTip.NeedChangeBlocks = {}
    LessonBoxTip.UpdateNextBtnStatus()
end

function LessonBoxTip.OnClickPre()
    if not LessonBoxTip.CheckHaseNextErr(-1) then
        GameLogic.AddBBS(nil,"没有更多的错误方块了")
        return 
    end
    checkIndex = checkIndex - 1
    LessonBoxTip.RenderErrorBlockTip()
    LessonBoxTip.UpdateNextBtnStatus()
    LessonBoxTip.SetErrBlockTip()
end

function LessonBoxTip.OnClickNext()
    if not LessonBoxTip.CheckHaseNextErr(1) then
        GameLogic.AddBBS(nil,"没有更多的错误方块了")
        return 
    end
    checkIndex = checkIndex + 1
    LessonBoxTip.RenderErrorBlockTip()
    LessonBoxTip.UpdateNextBtnStatus()
    LessonBoxTip.SetErrBlockTip()
end

--[[红色方框中的方块错了，正确的应该是【iocn】【方块名称】（编号：【方块编号】）。]]
function LessonBoxTip.SetErrBlockTip()
    if not page or not page_root or not page:IsVisible() then
        print("界面初始化失败~")
        return
    end
    local posSrc = LessonBoxTip.SrcBlockOrigin
    local block = LessonBoxTip.NeedChangeBlocks[checkIndex]
    local startPos = posSrc or lessonConfig.regionOther.pos
    if block then
        if page then
            page:SetValue("role_tip", "");
        end
        local x,y,z = startPos[1]+block[1],startPos[2]+block[2],startPos[3]+block[3]
        local blockId,blockData = BlockEngine:GetBlockIdAndData(x,y,z)

        -- print("blockId========",blockId,type(blockId),x,y,z)
        local block_item = ItemClient.GetItem(blockId);
        if blockId == 0 or block_item == nil then
            -- GameLogic.RunCommand(string.format("/goto %d %d %d",x,y,z))
            local strErrTip = string.format("红色方框里面不应该有方块，请将其清除。")
            SoundManager:PlayText(strErrTip,10006)
            local txtErrTip = ParaUI.GetUIObject("lessonbox_err_text")
            if not txtErrTip:IsValid() then
                txtErrTip = ParaUI.CreateUIObject("text", "lessonbox_err_text", "_lt", 240, 70, 330, 100);
                page_root:AddChild(txtErrTip)
            end
            txtErrTip.zorder = 3
            txtErrTip.font = "System;16;normal";
            txtErrTip.text = strErrTip;

            local imgBlock = ParaUI.GetUIObject("lessonbox_err_block")
            if imgBlock and imgBlock:IsValid() then
                ParaUI.Destroy("lessonbox_err_block")
            end
            return
        end
        local background = block_item:GetIcon(blockData):gsub("#", ";");
        local name = block_item:GetStatName()
        --print("block=========",name,background,tooltip)
        -- 电灯特殊处理
        if blockId == 207 then
            blockId = 199
        end

        local strErrTip = string.format("红色方框中的方块错了，正确的应该是【     】【%s】（编号：【%d】）。",name,blockId)
        SoundManager:PlayText(strErrTip,10006)
        local txtErrTip = ParaUI.GetUIObject("lessonbox_err_text")
        if not txtErrTip:IsValid() then
            txtErrTip = ParaUI.CreateUIObject("text", "lessonbox_err_text", "_lt", 240, 70, 330, 100);
            page_root:AddChild(txtErrTip)
        end
        txtErrTip.zorder = 3
        txtErrTip.font = "System;16;normal";
        txtErrTip.text = strErrTip;
        

        if background then
            local imgBlock = ParaUI.GetUIObject("lessonbox_err_block")
            if not imgBlock:IsValid() then
                imgBlock = ParaUI.CreateUIObject("button", "lessonbox_err_block", "_lt", 528, 68, 26, 26);
                page_root:AddChild(imgBlock)
            end
            imgBlock.enable = false
            imgBlock.background = background
        end
    end  
end

function LessonBoxTip.RemoveErrBlockTip()
    if page_root then
        ParaUI.Destroy("lessonbox_err_text")
        ParaUI.Destroy("lessonbox_err_block")
    end
end

function LessonBoxTip.OnStartMacroLearn()
    local taskArea = lessonConfig.stageArea
    local posTeacher = lessonConfig.templateteacher
    local posMy = lessonConfig.templatemy
    local taskCnf = lessonConfig.taskCnf[LessonBoxTip.m_nCurStageIndex]
    LessonBoxTip.ClearLearnArea(taskArea)
    LessonBoxTip.EndTip()
    commonlib.TimerManager.SetTimeout(function()
        local endTemp = taskCnf.finishtemplate
        local startTemp = taskCnf.starttemplate
        GameLogic.RunCommand(string.format("/loadtemplate %d,%d,%d %s",posMy[1],posMy[2],posMy[3],startTemp))
        GameLogic.RunCommand(string.format("/loadtemplate %d,%d,%d %s",posTeacher[1],posTeacher[2],posTeacher[3],endTemp))
        LessonBoxTip.ClearBlockTip()
        LessonBoxTip.ClearErrorBlockTip()
        LessonBoxTip.ClosePage()
        LessonBoxTip.StopStageMovie()
        GameLogic.GetCodeGlobal():BroadcastTextEvent("playFollowMacro", {macroPos = taskCnf.follow, taskCnf.macro_center_pos});
    end,200)
end

function LessonBoxTip.OnRetunMacro(isFinish)
    LessonBoxTip.ClosePage() 
    LessonBoxTip.UnregisterHooks()
    LessonBoxTip.ClearBlockTip()
    LessonBoxTip.ClearErrorBlockTip()
    LessonBoxTip.StopStageMovie()
    LessonBoxTip.EndTip()
    GameLogic.RunCommand("/sendevent hideNpc")
    GameLogic.RunCommand("/ggs user visible");
    LessonBoxTip.PlayLessonMusic("free_world")
    GameLogic.GetCodeGlobal():BroadcastTextEvent("enterMacroMode", {isFinish = isFinish or false, is_lx = lessonConfig.is_lx});
end

function LessonBoxTip.CheckHasePlayMovie()
    local MovieManager = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieManager");
	-- if(#MovieManager.active_clips > 0) then
	-- 	return true
	-- end
    return false
end

function LessonBoxTip.FinishCurStageMacro()
    LessonBoxTip.GotoNextStage()
end

function LessonBoxTip.GotoNextStage()
    LessonBoxTip.ClosePage() 
    GameLogic.RunCommand("/sendevent hideNpc")
    GameLogic.RunCommand("/sendevent showMask")
    checkIndex = 0
    checkBtnType ="start"
    isFinishStage = false
    -- LessonBoxTip.m_nCorrectCount = 0 --连续检查正确的次数
    LessonBoxTip.m_nCreateBoxCount = 0
    LessonBoxTip.NeedChangeBlocks = {} --检查以后错误的方块
    LessonBoxTip.AllNeedBuildBlock = {} --小节开始时，所有需要创建或者删除的方块，用于备份
    LessonBoxTip.CurNeedBuildBlock = {} --当前小节需要创建或者删除的方块
    LessonBoxTip.CreatePos = nil
    LessonBoxTip.SrcBlockOrigin = nil
    LessonBoxTip.m_nCurStageIndex = LessonBoxTip.m_nCurStageIndex + 1
    --print("LessonBoxTip stage===========",LessonBoxTip.m_nCurStageIndex,LessonBoxTip.m_nMaxStageIndex,LessonBoxTip.m_nCurStageIndex )
    if LessonBoxTip.m_nCurStageIndex > LessonBoxTip.m_nMaxStageIndex then
        LessonBoxTip.m_nCurStageIndex = 0
        LessonBoxTip.m_nMaxStageIndex = 0
        -- GameLogic.AddBBS(nil,"当前步骤的所有课程已经全部完成，你可以点击下一个步骤继续学习")
        LessonBoxTip.OnRetunMacro(true)
        return 
    end
    LessonBoxTip.EndTip()
    LessonBoxTip.UpdateCheckBtnStatus(checkBtnType)
    LessonBoxTip.UpdateNextBtnStatus()
    LessonBoxTip.PrepareStageScene()
end

function LessonBoxTip.ExitLesson()
    
end


function LessonBoxTip.LockLessonArea()
    lockarea_timer = lockarea_timer or commonlib.Timer:new({callbackFunc = function(timer)
		if World2In1.GetCurrentType() == "course" then
            local player = EntityManager.GetPlayer()
            if player then
                local x, y, z = player:GetBlockPos();
                local dis = 50
                local minX, minY, minZ = 18626,3,19010;
                local maxX = minX+128 ;
                local maxZ = minZ+128*3 ;
                local newX = math.min(maxX-5, math.max(minX + 2, x));
                local newZ = math.min(maxZ-5, math.max(minZ , z));
                local newY = math.max(minY-1, y);
                if(x~=newX or y~=newY or z~=newZ) then
                    player:SetBlockPos(newX, 12, newZ)
                end
            end
        end
	end})
	lockarea_timer:Change(1000, 500);
    
end

function LessonBoxTip.EndLockArea()
    if lockarea_timer then
        lockarea_timer:Change()
        lockarea_timer = nil
    end
end

function LessonBoxTip.EndAllTimer()
    if lockarea_timer then
        lockarea_timer:Change()
        lockarea_timer = nil
    end
    if tip_timer then
        tip_timer:Change()
        tip_timer = nil
    end
    if scale_timer then
        scale_timer:Change()
        scale_timer = nil
    end
    if errblock_timer then
        errblock_timer:Change()
        errblock_timer = nil
    end
    if check_timer then
        check_timer:Change()
        check_timer = nil
    end
end

function LessonBoxTip.PlayLessonMusic(strType)
    local strType = strType or "free_world"
    if strType == "login" then
        World2In1.PlayLogoMusic()
    elseif strType == "free_world" then
        World2In1.PlayWorldMusic()
    elseif strType == "lesson" then
        World2In1.PlayLessonMusic()
    elseif strType == "lesson_operate" then
        World2In1.PlayOperateMusic()
    elseif strType == "creator" then
        World2In1.PlayCreatorMusic()
    elseif strType == "other" then
        World2In1.PlayOtherMusic()
    end
end


