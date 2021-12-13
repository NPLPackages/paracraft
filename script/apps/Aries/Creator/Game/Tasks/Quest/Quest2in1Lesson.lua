NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkAPI.lua");
local Quest2in1Lesson = NPL.export()


--[[
    course_id:课程id，一个课程世界一个id
    progress:{stepNum = 10,curNum = 2},
    lessonId:配置的每一课的索引
    status：课程完成情况，非必须 1完成 0未完成
]]
function Quest2in1Lesson.UpdateLessonProgress(course_id,lessonId,progress,status,callback)
    keepwork.lesson2in1.set_useraction({
        courseId = course_id,
        num = lessonId,
        progress = progress,
        status = status,
    },function(err,msg,data)
        if err == 200 then
            if callback then
                callback(data)
            end
            return
        end
        callback()
        --GameLogic.AddBBS(nil,"更新课程进度数据异常~")
    end)
end

--[[
    获取课程进度
    course_id：一个课程世界一个course_id，一般是固定的
]]
function Quest2in1Lesson.GetLessonProgress(course_id,callback)
    keepwork.lesson2in1.get_useraction({
        courseId = course_id
    },function(err,msg,data)
        if err == 200 then
            if callback then
                callback(data)
            end
            return
        end
        callback()
        GameLogic.AddBBS(nil,"获取课程进度数据异常~")
    end)
end
