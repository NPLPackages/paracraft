
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");


--用户拥有的课包权限
--RELEASE http://yapi.kp-para.cn/project/32/interface/api/4804
--ONLINE
HttpWrapper.Create("keepwork.courses.userCourses", "%MAIN%/core/v0/courses/userCourses", "GET", true)


--课程包列表
--RELEASE http://yapi.kp-para.cn/project/32/interface/api/4794
--ONLINE
HttpWrapper.Create("keepwork.courses.query", "%MAIN%/core/v0/courses/query", "POST", true)


--  单个课程包数据
-- http://yapi.kp-para.cn/project/32/interface/api/4799
HttpWrapper.Create("keepwork.courses.course_info", "%MAIN%/core/v0/courses/:id", "GET", true)


-- 课程包分类列表
-- http://yapi.kp-para.cn/project/32/interface/api/4854
HttpWrapper.Create("keepwork.courses.course_class", "%MAIN%/core/v0/courseClassifies/query", "POST", true)


-- 根据课程包分类查询课程
-- http://yapi.kp-para.cn/project/32/interface/api/4864
HttpWrapper.Create("keepwork.courses.query_courses", "%MAIN%/core/v0/courses/:courseClassifyId/query", "POST", true)

--[[
courseId	number	必须 课程id	
isFinished	number	必须 课程是否完成时评价标识: 未完成: 0, 已完成: 1	
interestLevel	number	非必须 兴趣程度：没意思:1, 有兴趣: 5, 十分有兴趣: 10	
difficultyLevel	number	非必须 困难程度：没意思:1, 有兴趣: 5, 十分有兴趣: 10	
masteryLevel	number	非必须 没学会:1, 掌握了一部分: 5, 全部掌握了: 10	
feedback	string	非必须 反馈内容：限制128个字	
extra	object	非必须
sectionIndex	number	必须章节序号
]]

--用户评价
--http://10.28.18.44:3001/project/32/interface/api/4961
HttpWrapper.Create("keepwork.courses.doCourseEvaluations", "%MAIN%/core/v0/courseEvaluations", "POST", true)

--[[
isFinished	否	0 课程是否完成时评价标识: 未完成: 0, 已完成: 1
courseId	是	课程id
sectionIndex	是	章节序号
]]
--获取用户评价
--http://10.28.18.44:3001/project/32/interface/api/4963
HttpWrapper.Create("keepwork.courses.getCourseEvaluations", "%MAIN%/core/v0/courseEvaluations", "GET", true)

--记录章节
--http://10.28.18.44:3001/project/32/interface/api/4985
HttpWrapper.Create("keepwork.courses.setSectionStudyProgresses", "%MAIN%/core/v0/sectionStudyProgresses", "POST", true)

--章节完成记录
--http://10.28.18.44:3001/project/32/interface/api/4989
HttpWrapper.Create("keepwork.courses.getSectionStudyProgresses", "%MAIN%/core/v0/sectionStudyProgresses", "GET", true)

--记录课程
--http://10.28.18.44:3001/project/32/interface/api/4969
HttpWrapper.Create("keepwork.courses.setCourseStudyProgresses", "%MAIN%/core/v0/courseStudyProgresses", "POST", true)

--课程完成记录
--http://10.28.18.44:3001/project/32/interface/api/4987
HttpWrapper.Create("keepwork.courses.getCourseStudyProgresses", "%MAIN%/core/v0/courseStudyProgresses", "GET", true)

--获取课程章节权限
--http://yapi.kp-para.cn/project/130/interface/api/5119
HttpWrapper.Create("keepwork.courses.getCourseSectionAuths", "%MAIN%/accounting/users/schedules/sections", "GET", true)