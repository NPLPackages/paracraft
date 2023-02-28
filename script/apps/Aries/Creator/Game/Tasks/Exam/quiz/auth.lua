NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local KeepWorkItemManager = GameLogic.KeepWorkItemManager
local KeepWorkItemManager = GameLogic.KeepWorkItemManager
local submitApi_b = commonlib.getfield('keepwork.quiz.submit.b.score')
local submitApi_c = commonlib.getfield('keepwork.quiz.submit.c.score')

local checkApi = commonlib.getfield('keepwork.quiz.checkavailable')
local cache_policy='access plus 0'

local auth = commonlib.gettable("MyCompany.Aries.Game.Tasks.Exam.quiz.auth");

auth.quiz_id = nil
auth.item_id = nil

local function table_is_empty(t)
    return next(t) == nil
end

local function initStatus()
    --[[
		status structure

		quiz_id = {
	        type="quiz_template_1",
			score = 0, -- total
			problem = {
				problem_id = {
					score = 0,
				}
			}
		}
	]]
    local init_status = {}

    local item_id = auth.item_id
    local status = KeepWorkItemManager.GetClientData(item_id)

    if status == nil or table_is_empty(status) then
        return init_status
    else
        return status
    end
end

local function leaveWorld()
    -- commonlib.TimerManager.SetTimeout(function()
    --     GameLogic.RunCommand("/leaveworld")
    -- end, 3000)
end

local function tip(str)
    print("tip:",str)
    GameLogic.AddBBS(nil,str)
end

function auth.clear()
    auth.quiz_id = nil
    auth.item_id = nil
end

function auth.checkAuth(callback)
    if auth.quiz_id then
        if callback then
            callback(auth)
        end
        return
    end
    local world_id = WorldCommon.GetWorldTag("kpProjectId")
    print("======world_id",world_id)
    if world_id==nil or world_id=="" then
        tip(L"本地世界无法考试")
        return
    end
    checkApi({projectId=world_id, cache_policy=cache_policy}, function (err, msg, data)
        if err ~= 200 then
            tip("something wrong with check user auth api! please check log.txt")
            echo({err, msg, data})
            return
        end

        local ret = data.data.ret
        local reason = data.data.reason

        echo("quiz | check user auth api return")
        echo({data})

        -- not permitted
        if not ret then
            if reason == 1 then
                tip(L"考试还没开始")
            elseif reason == 2 then
                tip(L"考试已经结束")
            elseif reason == 3 then
                tip(L"你没报名考试")
            end
            return
        end

        if reason == 4 then
            -- tip(L"这不是考试世界")
            return
        end


        local quiz_id = data.data.unitId
        local item_id = data.data.gsId

        if not quiz_id then
            tip("考试id不可用")
            return
        end

        if not item_id then
            tip("报名无法验证，请检查登录")
            return
        end

        local hasItem = KeepWorkItemManager.HasGSItem(item_id)

        local cb = function()
            if not hasItem then
                tip(L"报名后请重新登陆")
                return
            end
            -- fixme for leio: kp itemmanager only accept string as table key
            auth.quiz_id = tostring(quiz_id)
            auth.item_id = tonumber(item_id)

            auth.startTimestamp = tonumber(data.data.startTimestamp)
            auth.endTimestamp = tonumber(data.data.endTimestamp)
            auth.timeDelta = tonumber(data.data.curTimestamp) - os.time()

            auth.status = initStatus()
            auth.max_commitTimes = tonumber(data.data.commitTimes) or 1
            auth.committedTimes = tonumber(data.data.committedTimes) or 0

            if callback then
                callback(auth)
            end
        end
        if hasItem then
            cb()
        else
            print("-------no item ,to pull")
            KeepWorkItemManager.LoadItems(nil, function()
                hasItem = KeepWorkItemManager.HasGSItem(item_id)
                print("--------repulled hasItem?",hasItem)
                cb()
            end)
        end

    end)
end

-- function recorder.record(problem_id, score)
--     local quiz_id = auth.quiz_id
--     local status = auth.status
    
--     if not status[quiz_id] then
--         status[quiz_id] = {
--             type = "quiz_template_1",
--             score = 0,
--             problem = {}
--         }
--     end
    
--     if not status[quiz_id]['problem'] then
--         status[quiz_id]['problem'] = {}
--     end
    
--     if status[quiz_id]['problem'][problem_id] then
--         return
--     end
    
--     status[quiz_id]['problem'][problem_id] = {}
--     status[quiz_id]['problem'][problem_id]['score'] = score
--     status[quiz_id]['score'] = status[quiz_id]['score'] + score


--     echo("quiz | record status")
--     echo(status)
-- end


function auth.submit_score(score)
    local item_id = auth.item_id
    local status = auth.status
    local quiz_id = auth.quiz_id

    echo("quiz | save client data")
    echo({status})

    if quiz_id==nil or item_id==nil then
        return
    end
    local hasItem = KeepWorkItemManager.HasGSItem(item_id)

    if hasItem then
        KeepWorkItemManager.SetClientData(item_id, status)
    else
        tip(string.format("you've got no item %d! we can't record your score detail.", item_id))

        leaveWorld()
        return
    end
    

    echo("quiz | submit score")
    echo({unitId=quiz_id, score=score})

    submitApi_b({
        unitId = tonumber(quiz_id),
        score = tonumber(score),
        cache_policy=cache_policy
    }, function (err, msg, data)
        echo("quiz | submit api return")

        if tonumber(err) ~= 200 then
            tip("submit score api behavior badly! check the log.txt")
            echo({err, msg, data})
        else
            echo(data)
        end
    end)
end

function auth.submit_score_c(quiz_id,url,callback)
    if quiz_id==nil then
        return
    end
    
    echo("quiz | submit url")
    local obj = {
        unitId = tonumber(quiz_id),
        url = url,
        cache_policy=cache_policy
    }
    echo(obj,true)

    submitApi_c(obj, function (err, msg, data)
        echo("quiz | submit api return")

        if tonumber(err) ~= 200 then
            tip("submit score api behavior badly! check the log.txt")
            -- echo({err, msg, data})
            print("--------提交失败")
            echo(data,true)
        else
            if callback then
                callback(data)
            end
            print("------提交成功")
            echo(data)
        end
    end)
end 

local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua");
local LoginModal = NPL.load("(gl)Mod/WorldShare/cellar/LoginModal/LoginModal.lua")

if(KeepworkService and KeepworkService:IsSignedIn()) then
    auth.checkAuth()
end

function callback(bSucceed)
    if(bSucceed) then
        auth.checkAuth()
    else
        commonlib.TimerManager.SetTimeout(function ()
            LoginModal:Close()
            LoginModal:Init(callback)
        end, 1000)
    end
end

LoginModal:Init(callback)

