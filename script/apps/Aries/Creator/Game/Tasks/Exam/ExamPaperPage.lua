--[[
Title: ExamPaperPage
Author(s): hyz
Date: 2022/6/7
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Exam/ExamPaperPage.lua");
local ExamPaperPage = commonlib.gettable("MyCompany.Aries.Game.Tasks.Exam.ExamPaperPage");
ExamPaperPage.ShowPage(true)
--]]

NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Exam/quiz/auth.lua");
local auth = commonlib.gettable("MyCompany.Aries.Game.Tasks.Exam.quiz.auth");
local ExamPaperPage = commonlib.gettable("MyCompany.Aries.Game.Tasks.Exam.ExamPaperPage");
local Screen = commonlib.gettable("System.Windows.Screen");

local page;

function ExamPaperPage.OnInit()
	page = document:GetPageCtrl();
    page.OnClose = ExamPaperPage.OnClosed;
    page.OnCreate = ExamPaperPage.OnCreated;

	GameLogic:Connect("WorldUnloaded", ExamPaperPage, ExamPaperPage.OnWorldUnload, "UniqueConnection");
end

function ExamPaperPage.OnCreated()

end

function ExamPaperPage.OnClosed()
    page = nil 
end

function ExamPaperPage.OnWorldUnload()
	GameLogic:Disconnect("WorldUnloaded", ExamPaperPage, ExamPaperPage.OnWorldUnload);
    auth.clear()
	ExamPaperPage.ShowPage(false)
end

function ExamPaperPage.ShowPage(bShow)
	if bShow==false then 
		if page then 
			page:CloseWindow()
			page = nil 
		end
		return 
	end
	local params = {
			url = "script/apps/Aries/Creator/Game/Tasks/Exam/ExamPaperPage.html", 
			name = "ExamPaperPage.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			bToggleShowHide=false, 
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = false,
			enable_esc_key = true,
			bShow = true,
			click_through = false, 
			zorder = 0,
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
            DesignResolutionWidth = 1280,
		    DesignResolutionHeight = 720,
            isTopLevel = true,
			directPosition = true,
				align = "_ct",
				x = -652/2,
				y = -442/2,
				width = 652,
				height = 442,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
    GameLogic.GetFilters():apply_filters("user_behavior", 1, "competition.choicequestion",{open=true,useNoId=true})
    GameLogic.AddBBS(nil,L"开始考试")
    ExamPaperPage.UpdateClock()
    ExamPaperPage.UpdateAnswerProgress()
    ExamPaperPage.UpdateQuestionUI()
end


function ExamPaperPage.CheckShow(rules,endTime,showScore)
    ExamPaperPage.endTime = endTime
    if showScore == nil or showScore == true or showScore == "true" then
        ExamPaperPage.showScore = true
    else
        ExamPaperPage.showScore  = false
    end
    if rules==nil then
        rules = ExamPaperPage.GetPaperParam()
    elseif type(rules)=="string" then
        local xmlpath = rules
        rules = ExamPaperPage.GetPaperParam(xmlpath)
    end

    if not rules then
        GameLogic.AddBBS(nil,L"缺少考试规则")
        return
    end
    keepwork.user.server_time(nil,function(err,msg,data)
        if err~=200 then
            return
        end
        ExamPaperPage.timeDiff = ExamPaperPage.GetServerTime() - math.floor(data.timestamp/1000)
        print("====time",ExamPaperPage.GetServerTime(),ExamPaperPage.timeDiff)
        auth.checkAuth(function()
            ExamPaperPage.rules = rules
            ExamPaperPage.GeneratePaper(function()
                if ExamPaperPage.IsCommited() then --已经交卷了
                    print("交卷了")
                    GameLogic.GetFilters():apply_filters("user_behavior", 1, "competition.choicequestion",{open=false,result="答题已结束", score=ExamPaperPage.paper_data.score, useNoId=true})
                    ExamPaperPage.showResultPage(ExamPaperPage.paper_data.score,L"答题已结束")
                else
                    if #ExamPaperPage.paper_data.questions==0 then
                        GameLogic.AddBBS(nil,"试题为空")
                        GameLogic.GetFilters():apply_filters("user_behavior", 1, "competition.choicequestion",{open=false,result="试题为空",useNoId=true})
                        return
                    end
                    ExamPaperPage.ShowPage(true)
                end
            end)
        end)
    end)
    
end

--是否可以重考
function ExamPaperPage.CheckCanReExamine()
    return auth.max_commitTimes>auth.committedTimes
end

function ExamPaperPage.IsExamed()
    return auth.committedTimes and auth.committedTimes > 0
end

--生成试卷的参数
function ExamPaperPage.GetPaperParam(xmlpath)
    local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
    xmlpath = Files.GetWorldFilePath(xmlpath or "exam_config.xml");

    print("---------xmlpath",xmlpath)
    if xmlpath==nil then
        return nil 
    end
    local xmlRoot = ParaXML.LuaXML_ParseFile(xmlpath);
    if xmlRoot==nil then
        return nil 
    end
    -- print("xmlRoot",xmlRoot)
    -- echo(xmlRoot,true)
    
    local configs = commonlib.XPath.selectNode(xmlRoot, "/configs")
    -- print("configs:")
    -- echo(configs,true)
    ExamPaperPage.totalTime = configs.attr.time or 45*60;
    local rules = {}
    for k,v in ipairs(configs) do
        rules[#rules+1] = v.attr
    end
    
    return rules,time
end

--获得试卷
function ExamPaperPage.GeneratePaper(callback,forceUpdate)
    keepwork.exampaper.generatePaper({
        projectId = GameLogic.options:GetProjectId() or 4,
        rules = ExamPaperPage.rules,
        forceUpdate = forceUpdate,
    },function(err,msg,data)
        print("-------sserr",err)
        echo(data,true)

        if err~=200 then
            if(type(data) == "string") then
                data = commonlib.Json.Decode(data) or data;
            end
            print("GeneratePaper error:")
            echo(data,true)
            return
        end
        
        if type(data)=="table" and data.data then
            ExamPaperPage.paper_data = data.data

            ExamPaperPage._questionDetails = {}
            for k,v in pairs(ExamPaperPage.paper_data.questions) do --按照索引存一份试题
                ExamPaperPage._questionDetails[v.index] = v
            end

            for k,v in pairs(ExamPaperPage.paper_data.answers) do --按照索引存一份答案，没有的就是还没答
                local info = ExamPaperPage._questionDetails[v.index]
                info.answer = v.answer
                info.correct = v.correct
            end

            -- ExamPaperPage.curQuestionDetail = nil --当前回答到哪一道题了
            for k,v in pairs(ExamPaperPage._questionDetails) do
                if v.answer==nil or k==#ExamPaperPage.paper_data.questions then
                    ExamPaperPage.curQuestionDetail = v
                    break
                end
            end
            -- if System.options.isDevEnv then 
                print("===========试卷")
                echo(ExamPaperPage.paper_data,true)

                print("试题")
                echo(ExamPaperPage._questionDetails,true)
            -- end
            if callback then
                callback()
            end
        else
        end
    end)
end

--刷新答题倒计时
function ExamPaperPage.UpdateClock()
    if not page then
        return
    end
    local totalTime = ExamPaperPage.totalTime or 45*60

    if ExamPaperPage.paper_data then
        local leftTime = 0
        if ExamPaperPage.endTime ~= nil then
            leftTime = ExamPaperPage.endTime - ExamPaperPage.GetServerTime() + ExamPaperPage.timeDiff
        else
            local start_stamp = commonlib.timehelp.GetTimeStampByDateTime(ExamPaperPage.paper_data.startAt)
            leftTime = totalTime - (ExamPaperPage.GetServerTime()-start_stamp ) + ExamPaperPage.timeDiff
        end
        ExamPaperPage.isTimeout = leftTime<0
        ExamPaperPage.curTimeVal = L"剩余时间".." "..os.date("%M:%S",math.max(leftTime,0))
        page:SetUIValue("label_left_time",ExamPaperPage.curTimeVal)
    end
    if not ExamPaperPage.isTimeout then
        commonlib.TimerManager.SetTimeout(ExamPaperPage.UpdateClock,1000)
    else
        ExamPaperPage.showTimeoutTip()
    end
end

--刷新答题进度
function ExamPaperPage.UpdateAnswerProgress()
    if not page then
        return
    end
    if ExamPaperPage.paper_data==nil then
        page:SetUIValue("text_progress","")
    end

    local acc = 0
    for k,v in pairs(ExamPaperPage.paper_data.answers) do
        if v.answer then
            acc = acc + 1
        end
    end
    page:SetUIValue("text_progress",string.format("%s/%s",acc,#ExamPaperPage.paper_data.questions))
end

--题目数据详情，包含问题和4个选项
function ExamPaperPage._getQuestionDetail(index,callback)
    
    if ExamPaperPage._questionDetails[index].question then
        callback(ExamPaperPage._questionDetails[index])
        return
    end
    local questionId = ExamPaperPage.getQuestionIdByIndex(index)
    -- print("找题 index:",index)
    keepwork.exampaper.getQuestion({
        questionIds = {questionId}
    },function(err,msg,data)
        print("err",err)

        if err~=200 then
            GameLogic.AddBBS(nil,L"获取考题失败")
            print("data",data)
            return
        end

        for k,v in pairs(data.data[1]) do
            ExamPaperPage._questionDetails[index][k] = v
        end
        echo(ExamPaperPage._questionDetails[index],true)
        callback(ExamPaperPage._questionDetails[index])
    end)
end

function ExamPaperPage.getQuestionIdByIndex(index)
    for k,v in pairs(ExamPaperPage._questionDetails) do
        if v.index==index then
            return v.questionId
        end
    end
    return nil
end

--刷新右侧题目
function ExamPaperPage.UpdateQuestionUI()
    if ExamPaperPage.curQuestionDetail==nil then
        return
    end
    
    ExamPaperPage._getQuestionDetail(ExamPaperPage.curQuestionDetail.index,function(info)
        for k,v in pairs(info) do
            if ExamPaperPage.curQuestionDetail[k]==nil then
                ExamPaperPage.curQuestionDetail[k] = v
            end
        end
        
        if page then
            local oldPosY;
            if page:GetNode("index_gridview") then
                oldPosY = page:GetNode("index_gridview"):GetChild("pe:treeview").control.ClientY
            end
            page:Refresh(0)
            if ExamPaperPage.curQuestionDetail.answer then
                page:SetValue("answerItem", ExamPaperPage.curQuestionDetail.answer)
            end
            if oldPosY then
                page:GetNode("index_gridview"):GetChild("pe:treeview").control.ClientY = oldPosY
                page:GetNode("index_gridview"):GetChild("pe:treeview").control:Update()
            end
        end
    end)
end

function ExamPaperPage.GetCurQuestionXmlInfo(param)
    local detail = ExamPaperPage.curQuestionDetail
    if detail==nil or detail.question==nil then
        return nil
    end

    local str = [[<div>]].."\n"
    local titleInfo = detail.question
    if titleInfo.text and titleInfo.text~="" then
        local titleStr = string.format("%s.%s",detail.index,titleInfo.text)
        -- str = str..string.format([[<label value='%s' style="margin-left: 0px; margin-top: 0px;font-size:14px; font-weight:bold;color:#333333;"></label>]],titleStr).."\n"
        str = str..string.format([[<div style="float: left; width: 418px; margin-left: 0px; margin-top: 0px;font-size:14px; font-weight:bold;color:#333333;">%s</div>]],titleStr).."\n"
    end
    if titleInfo.img and titleInfo.img.url and titleInfo.img.url~="" then
        local imgStr = string.format([[<img style="margin-top:4px;margin-left:2px; background:url(%s);width:%spx;height:%spx;" />]],titleInfo.img.url,titleInfo.img.width,titleInfo.img.height)
        str = str..imgStr.."\n"
    end
    str = str .. [[</div>]].."\n"
    str = str .. [[<div height="1px" width="448px" style="background-color: #ff000000;"></div>]] .. "\n"

    local arr = {"itemA","itemB","itemC","itemD"}
    local mutiImg = true --一行显示两个图片答案选项
    for i=1,#arr do
        local item = detail[arr[i]];
        if item and item.text and item.text~="" then
            mutiImg = false
            break
        end
        if item and item.img and item.img.url and item.img.url~="" then
            if item.img.width>160 then
                mutiImg = false
                break
            end
        end
    end
    if not mutiImg then --顺序向下
        for i=1,#arr do
            local item = detail[arr[i]];
            if item and (item.text or item.img) then
                local answerIdx = string.gsub(arr[i],"item","")
                str = str .. string.format([[<div style="padding-top: 6px; padding-bottom: 6px; background-color: #ff000000;" name="%s" onclick="onClickDiv"> ]],"item"..answerIdx).."\n"
                str = str .. [[    <div style="position: relative;">]] .."\n"
                str = str .. string.format([[        <input type="radio" name="answerItem" value="%s" onclick="onClickRadio" CheckedBG="<%%=GetCheckBg()%%>" UncheckedBG="<%%=GetUnCheckBg()%%>" style="margin-top: 3px;" />]],answerIdx).."\n"
                str = str .. [[    </div>]].."\n"
                if true then
                    local quesStr = string.format("%s.%s",answerIdx,item.text or "")
                    str = str..string.format([[    <div style="float: left; width: 418px; margin-left: 22px; margin-top: 0px;font-size:14px; font-weight:normal;color:#333333;">%s</div>]],quesStr).."\n"
                    
                end
                if item.img and item.img.url and item.img.url~="" then
                    local imgStr = string.format([[    <img style="margin-top:4px;margin-left:20px; background:url(%s);width:%spx;height:%spx;" />]],item.img.url,item.img.width,item.img.height)
                    str = str..imgStr.."\n"
                end
                str = str .. [[</div>]].."\n"
            end
        end
    else
        
        for i=1,#arr do
            if i==1 or i==3 then
                str = str..[[<div width="420px">]].."\n"
            end
            local item = detail[arr[i]];
            if item and (item.text or item.img) then
                local answerIdx = string.gsub(arr[i],"item","")
                str = str .. string.format([[<div style="padding-top: 6px; padding-bottom: 6px; background-color: #ff000000; width: 210px; float: left;" name="%s" onclick="onClickDiv"> ]],"item"..answerIdx).."\n"
                str = str .. [[    <div style="position: relative;">]] .."\n"
                str = str .. string.format([[    <input type="radio" name="answerItem" value="%s" onclick="onClickRadio" CheckedBG="<%%=GetCheckBg()%%>" UncheckedBG="<%%=GetUnCheckBg()%%>" style="margin-top: 3px;" />]],answerIdx).."\n"
                str = str .. [[    </div>]].."\n"
                if true then
                    local titleStr = string.format("%s.%s",answerIdx,"")
                    str = str..string.format([[    <div style="position: relative;float: left; width: 418px; margin-left: 22px; margin-top: 0px;font-size:14px; font-weight:normal;color:#333333;">%s</div>]],titleStr).."\n"
                end
                if item.img and item.img.url and item.img.url~="" then
                    local imgStr = string.format([[    <img style="margin-top:0px;margin-left:52px; background:url(%s);width:%spx;height:%spx;" />]],item.img.url,item.img.width,item.img.height)
                    str = str..imgStr.."\n"
                end
                str = str .. [[</div>]].."\n"
                if i==2 or i==4 then
                    str = str .. [[</div>]].."\n"
                end
            end
        end
        
    end
    -- print("--------str,")
    -- echo(str,true)
    return str
end

--当前是否第一题
function ExamPaperPage.IsCurFirstQuestion()
    local detail = ExamPaperPage.curQuestionDetail
    if detail==nil then
        return
    end
    local curIdx = detail.index
    return curIdx==1
end

--当前是否最后一题
function ExamPaperPage.IsCurLastQuestion()
    local detail = ExamPaperPage.curQuestionDetail
    if detail==nil then
        return
    end
    local curIdx = detail.index
    return curIdx==#ExamPaperPage.paper_data.questions
end

--当前这一题是否回答了
function ExamPaperPage.IsCurQuestionAnswered()
    local detail = ExamPaperPage.curQuestionDetail
    if detail==nil then
        return
    end
    local index = detail.index
    local info = ExamPaperPage._questionDetails[index] 
    local hasAnswer = info.answer and info.answer~=""
    return hasAnswer==true
end

--选择答题
function ExamPaperPage.onClickRadio(value)
    local detail = ExamPaperPage.curQuestionDetail
    if detail==nil then
        return
    end
    if ExamPaperPage.isTimeout then
        GameLogic.AddBBS(nil,L"答题已超时，请交卷");
        return
    end
    
    detail.answer = value
    print("value",value)

    local oldPosY = page:FindControl("scroll_content").ClientY
    ExamPaperPage._questionDetails[detail.index].answer = value
    ExamPaperPage.UpdateQuestionUI()
    page:FindControl("scroll_content").ClientY = oldPosY
    page:FindControl("scroll_content"):Update()
    
    keepwork.exampaper.commitAnswer({
        router_params = {
            pid = ExamPaperPage.paper_data.pid,
        },
        
        answers = {
            {
                answer = value,
                index = detail.index
            }
        }
    },function(err,msg,data)
        -- print("--------更新答案 err=",err,data)
        -- echo(data)
        
        if ExamPaperPage.IsCurLastQuestion() then
            ExamPaperPage.showFinishLastTip()
        end
    end)
end

function ExamPaperPage.CheckCommit()
    if ExamPaperPage.IsAllFinished() then
        ExamPaperPage.DoCommit()
    else
        ExamPaperPage.showCommitConfirmPage()
    end
end

function ExamPaperPage.DoCommit()
    keepwork.exampaper.commitPaper({
        router_params = {
            pid = ExamPaperPage.paper_data.pid,
        },
        
    },function(err,msg,data)
        -- print("--------交卷 err=",err,data)
        -- echo(data,true)

        if err==200 and data and data.data then
            ExamPaperPage.ShowPage(false)
            ExamPaperPage.paper_data = data.data
            auth.committedTimes = auth.committedTimes + 1
            
            ExamPaperPage.showResultPage(ExamPaperPage.paper_data.score,L"考试成绩已成功上传")
            auth.submit_score(ExamPaperPage.paper_data.score)
            GameLogic.GetFilters():apply_filters("user_behavior", 1, "summit.competition.choicequestion",{score=ExamPaperPage.paper_data.score,useNoId=true})
        else
            GameLogic.GetFilters():apply_filters("user_behavior", 1, "summit.competition.choicequestion",{result="选择题提交失败",useNoId=true})
        end
    end)
end

--所有题目都回答完了
function ExamPaperPage.IsAllFinished()
    local acc_1 = 0;
    local acc_2 = 0;
    for k,v in pairs(ExamPaperPage._questionDetails) do
        if v.answer then
            acc_2 = acc_2 + 1
        end
        acc_1 = acc_1 + 1
    end
    return acc_2==acc_1
end

--是否已经交卷了
function ExamPaperPage.IsCommited()
    print("ExamPaperPage.paper_data.status",ExamPaperPage.paper_data.status)
    if ExamPaperPage.IsExamed() then
        return ExamPaperPage.paper_data.status==1
    end
    return false
end

function ExamPaperPage.onBtnClick(name)
    local detail = ExamPaperPage.curQuestionDetail
    if detail==nil then
        return
    end
    local curIdx = detail.index

    if name=="btn_commit" then
        ExamPaperPage.CheckCommit()
    elseif name=="btn_pre" then
        if ExamPaperPage.isTimeout then
            GameLogic.AddBBS(nil,L"答题已超时，请交卷");
            return
        end
        if curIdx==1 then
            return;
        end
        local idx = detail.index-1
        ExamPaperPage.curQuestionDetail = ExamPaperPage._questionDetails[idx]
        print("-------上一题",idx, ExamPaperPage.curQuestionDetail)
        ExamPaperPage.UpdateQuestionUI()
    elseif name=="btn_next" then
        if ExamPaperPage.isTimeout then
            GameLogic.AddBBS(nil,L"答题已超时，请交卷");
            return
        end
        if detail.answer==nil then
            GameLogic.AddBBS(nil,L"请先回答本题");
            return
        end
        if curIdx==#ExamPaperPage.paper_data.questions then
            GameLogic.AddBBS(nil,L"已经是最后一题");
            return;
        end
        local idx = detail.index+1
        ExamPaperPage.curQuestionDetail = ExamPaperPage._questionDetails[idx]
        print("-------下一题",idx, ExamPaperPage.curQuestionDetail)
        ExamPaperPage.UpdateQuestionUI()
    end
end

function ExamPaperPage.GetServerTime()
    if System.options.isDevMode then
        return os.time()
    end
    local timp_stamp = GameLogic.GetFilters():apply_filters('service.session.get_current_server_time')
    return timp_stamp or os.time()
end

--得分
function ExamPaperPage.showResultPage(score,tip)
    local params = {
        url = string.format("script/apps/Aries/Creator/Game/Tasks/Exam/ExamResultPage.html?score=%s&tip=%s",score,tip), 
        name = "ExamResultPage.ShowPage", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        bToggleShowHide=false, 
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = true,
        bShow = true,
        click_through = false, 
        zorder = 0,
        app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
        DesignResolutionWidth = 1280,
		DesignResolutionHeight = 720,
        isTopLevel = true,
        directPosition = true,
            align = "_ct",
            x = -460/2,
            y = -320/2,
            width = 460,
            height = 320,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
    GameLogic.AddBBS(nil,L"考试结束5秒后即将退出考试世界");
    commonlib.TimerManager.SetTimeout(function()
        if not ExamPaperPage.reExam then
            local WorldExitDialog = NPL.load('Mod/WorldShare/cellar/WorldExitDialog/WorldExitDialog.lua')
            WorldExitDialog.OnDialogResult(_guihelper.DialogResult.No)
        else
            GameLogic.AddBBS(nil,L"正在重新考试");
        end
        ExamPaperPage.reExam = false
    end,5000)
end

function ExamPaperPage.OnReExamine()
    local forceUpdate = true
    ExamPaperPage.GeneratePaper(function()
        if ExamPaperPage.IsCommited() then --已经交卷了
            print("交卷了")
            ExamPaperPage.showResultPage(ExamPaperPage.paper_data.score,L"答题已结束")
        else
            if #ExamPaperPage.paper_data.questions==0 then
                GameLogic.AddBBS(nil,"试题为空")
                return
            end
            ExamPaperPage.reExam = true
            ExamPaperPage.ShowPage(true)
        end
    end,forceUpdate)
end

--超时了
function ExamPaperPage.showTimeoutTip()
    local params = {
        url = string.format("script/apps/Aries/Creator/Game/Tasks/Exam/ExamTimeoutTip.html?tip=%s",L"考试时间已到，请交卷"), 
        name = "ExamResultPage.ShowPage", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        bToggleShowHide=false, 
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = true,
        bShow = true,
        click_through = false, 
        zorder = 0,
        app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
        DesignResolutionWidth = 1280,
		DesignResolutionHeight = 720,
        isTopLevel = true,
        directPosition = true,
            align = "_ct",
            x = -460/2,
            y = -320/2,
            width = 460,
            height = 320,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end


--回答了最后一题
function ExamPaperPage.showFinishLastTip()
    local params = {
        url = string.format("script/apps/Aries/Creator/Game/Tasks/Exam/ExamFinishLastTip.html?tip=%s",L"当前这是最后一题，请检查答案或交卷"), 
        name = "ExamFinishLastTip.ShowPage", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        bToggleShowHide=false, 
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = true,
        bShow = true,
        click_through = false, 
        zorder = 0,
        isTopLevel = true,
        app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
        DesignResolutionWidth = 1280,
		DesignResolutionHeight = 720,
        directPosition = true,
            align = "_ct",
            x = -460/2,
            y = -320/2,
            width = 460,
            height = 320,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end

--有题目未完成，交卷确认
function ExamPaperPage.showCommitConfirmPage()
    local params = {
        url = string.format("script/apps/Aries/Creator/Game/Tasks/Exam/ExamCommitConfirm.html?tip=%s",L"有题目未完成，确定交卷？"), 
        name = "ExamCommitConfirm.ShowPage", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        bToggleShowHide=false, 
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = true,
        bShow = true,
        click_through = false, 
        isTopLevel = true,
        zorder = 0,
        app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
        DesignResolutionWidth = 1280,
		DesignResolutionHeight = 720,
        directPosition = true,
            align = "_ct",
            x = -460/2,
            y = -320/2,
            width = 460,
            height = 320,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end

--提交视频文件
function ExamPaperPage.showUploadVideoFilePage(qiuzi)
    echo(qiuzi,false)
    ExamPaperPage.testC_qiuziId = qiuzi and qiuzi.id
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/Exam/ExamUploadVideoFile.html", 
        name = "ExamPaperPage.showUploadVideoFilePage", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        bToggleShowHide=false, 
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = true,
        bShow = true,
        click_through = false, 
        isTopLevel = true,
        zorder = 0,
        app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
        DesignResolutionWidth = 1280,
		DesignResolutionHeight = 720,
        directPosition = true,
            align = "_ct",
            x = -572/2,
            y = -248/2,
            width = 572,
            height = 248,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end

local _pageVideo = nil
function ExamPaperPage.OnInitCommitVideo(page)
    _pageVideo = page
end

function ExamPaperPage.CloseUploadVideoPage()
    if _pageVideo then
        _pageVideo:CloseWindow()
        _pageVideo = nil 
    end
end

function ExamPaperPage.OnBtnClick_videoPage(name)
    if name=="btn_commit_video" then
        ExamPaperPage.openExplorer(function(filepath)
            if filepath==nil or filepath=="" then 
                GameLogic.AddBBS(nil,"无")
                return
            end
            ExamPaperPage.UpLoadFile(filepath,function(url)
                print("------返回上传url",url)
                auth.submit_score_c(ExamPaperPage.testC_qiuziId,url,function()
                    GameLogic.AddBBS(nil,L"视频提交成功")
                end)
                
                ExamPaperPage.CloseUploadVideoPage()
            end)
        end)
    elseif name=="btn_open_netdisk" then
        ExamPaperPage.CloseUploadVideoPage()
        local token = commonlib.getfield("System.User.keepworktoken")
        local KeepworkService = NPL.load('(gl)Mod/WorldShare/service/KeepworkService.lua')
        local urlbase = KeepworkService:GetKeepworkUrl()

        local method = '/p/skyDrive'
        local url = format('%s/p?url=%s&token=%s', urlbase, Mod.WorldShare.Utils.EncodeURIComponent(method), token or "")
        -- local url = string.format("%s/p/skyDrive?token=%s",urlbase,token or "")
        print("url",url)
        
        GameLogic.RunCommand("/open "..url)
    end
end

function ExamPaperPage.openExplorer(callback)
    local filters = {
        {L"全部文件(*.mp4,*.3gp,*.avi,*.rmvb)",  "*.mp4;*.3gp;*.avi;*.rmvb"},
        {L"mp4(*.mp4)",  "*.mp4"},
        {L"3gp(*.3gp)",  "*.3gp"},
        {L"rmvb(*.rmvb)",  "*.rmvb"},
        {L"avi(*.avi)",  "*.avi"},
    };
    local title = L"选择本地视频文件"
    NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/OpenFileDialog.lua");
    local OpenFileDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.OpenFileDialog");
    local IsSaveMode = false
    local searchPath = ParaWorld.GetWorldDirectory()
    if (System.os.GetPlatform() == "win32") then 
		local filepath = CommonCtrl.OpenFileDialog.ShowDialog_Win32(filters, title,searchPath, IsSaveMode);
		if callback then
            callback(filepath)
        end
	elseif (System.os.GetPlatform() == "mac") then 
		local filepath = CommonCtrl.OpenFileDialog.ShowDialog_Mac(filters, title,searchPath, IsSaveMode);
		if callback then
            callback(filepath)
        end		
	elseif (System.os.GetPlatform() == "android") then
		CommonCtrl.OpenFileDialog.ShowDialog_Android(filters, function(filepath)
            if callback then
                callback(filepath)
            end
		end)
	elseif (System.os.GetPlatform() == "ios") then
		CommonCtrl.OpenFileDialog.ShowDialog_iOS(filters, function(filepath)
			-- TODO: 
            if callback then
                callback(filepath)
            end	
		end)
 	end 
end

function ExamPaperPage.UpLoadFile(filename,callback)
	local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
	local profile = KeepWorkItemManager.GetProfile()
	if not profile.id then
		return
	end

    local function _cb(url)
        Mod.WorldShare.MsgBox:Close()
        if callback then
            callback(url)
        end
    end

    local file = ParaIO.open(filename, "rb");
    if (not file:IsValid()) then
        file:close();
        print("-------文件读取失败")
        GameLogic.AddBBS(nil,L"文件读取失败");
        _cb(nil)
        return;
    end
    local size = file:GetFileSize();
    if size>200*1024*1024 then
        GameLogic.AddBBS(1,"上传的视频过大,请上传200M以内的视频")
        return
    end

    Mod.WorldShare.MsgBox:Show(L'正在获取上传凭证...')
	local key = string.format("exam_video_upload_%s_%s", profile.id, ParaMisc.md5(filename))
    keepwork.privateToken.getToken({
        router_params = {
            id = key,
        }
    },function(err, msg, data)
        -- print("zzz上传 err",err)
        -- echo(data,true)
		if err == 200 then
			local token = data.data.token
			local fileId = data.data.fileId
			local file_name = commonlib.Encoding.DefaultToUtf8(ParaIO.GetFileName(filename));
			
			local content = file:GetText(0, -1);
			file:close();
            -- print("key",key)
            -- print("file_name",file_name)
            Mod.WorldShare.MsgBox:Close()
            Mod.WorldShare.MsgBox:Show(L'正在上传视频...',1000*60*10)
			GameLogic.GetFilters():apply_filters(
				'qiniu_upload_file',
				token,
				key,
				file_name,
				content,
				function(result, err)
					-- print("-------上传结果xxx")
                    -- echo(result,true)
                    if result.message~="success" then
                        print("-------上传失败")
                        GameLogic.AddBBS(nil,L"上传失败")
                        _cb(nil)
                        return;
                    end
                    Mod.WorldShare.MsgBox:Close()
                    Mod.WorldShare.MsgBox:Show(L'正在获取视频链接...')
                    keepwork.rawUrlById.get({
                        router_params = {
                            id = fileId,
                        }
                    },function(err,msg,data)
                        -- print("=========err",err)
                        -- echo(data,true)
                        if err~=200 then
                            print("获取上传地址失败")
                            GameLogic.AddBBS(nil,L"获取上传地址失败")
                            _cb(nil)
                        end
                        -- GameLogic.AddBBS(nil,L"视频上传成功")
                        _cb(data.data)
                    end)
				end
			)
		end
        collectgarbage("collect");
    end)
end