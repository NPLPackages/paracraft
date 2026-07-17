--[[
Title: keepwork.class
Author(s): chenjinxian
Date: 2020/8/9
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/keepwork.class.lua");
]]
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");

--http://yapi.kp-para.cn/project/25/interface/api/2622
HttpWrapper.Create("keepwork.classes.get", "%MAIN%/accounting/org/classes", "GET", true)

--http://yapi.kp-para.cn/project/25/interface/api/2652
HttpWrapper.Create("keepwork.classroom.post", "%MAIN%/accounting/org/classroom", "POST", true)

--http://yapi.kp-para.cn/project/25/interface/api/2667
HttpWrapper.Create("keepwork.classroom.get", "%MAIN%/accounting/org/classroom", "GET", true)

--http://yapi.kp-para.cn/project/25/interface/api/2692
HttpWrapper.Create("keepwork.info.get", "%MAIN%/accounting/org/classroom/info", "GET", true)

--http://yapi.kp-para.cn/project/25/interface/api/2697
HttpWrapper.Create("keepwork.dismiss.post", "%MAIN%/accounting/org/classroom/dismiss", "POST", true)

--http://yapi.kp-para.cn/project/25/interface/api/612
HttpWrapper.Create("keepwork.userOrgInfo.get", "%MAIN%/accounting/org/userOrg", "GET", true)


--通过邀请码加入班级
--http://yapi.kp-para.cn/project/130/interface/api/5025
HttpWrapper.Create("keepwork.userclass.joinclass", "%MAIN%/accounting/orgClassInvitationCodes/joinClass", "POST", true)

--获取用户所有的教学班
--http://yapi.kp-para.cn/project/130/interface/api/5027
HttpWrapper.Create("keepwork.userclass.getclasses", "%MAIN%/accounting/orgClass/userTeachingClasses", "GET", true)

-->>>>>>>>>>>>> 课程表 start >>>>>>>>>>>>
--开始上课
-- http://yapi.kp-para.cn/project/130/interface/api/5085
HttpWrapper.Create("keepwork.schedule.startCourse", "%MAIN%/accounting/users/schedules/start", "POST", true)

--下课
-- http://yapi.kp-para.cn/project/130/interface/api/5087
HttpWrapper.Create("keepwork.schedule.endCourse", "%MAIN%/accounting/users/schedules/finish", "POST", true)

--学生上课打卡考勤
-- http://yapi.kp-para.cn/project/130/interface/api/5089
HttpWrapper.Create("keepwork.schedule.attendance", "%MAIN%/accounting/users/schedules/signIn", "POST", true)

--当前时间的课表（登陆上来时请求判断是否有正在上的课）
--http://yapi.kp-para.cn/project/130/interface/api/5091
HttpWrapper.Create("keepwork.schedule.currentSchedule", "%MAIN%/accounting/users/schedules", "GET", true)

--查询课表
--http://yapi.kp-para.cn/project/130/interface/api/5093
HttpWrapper.Create("keepwork.schedule.searchSchedule", "%MAIN%/accounting/users/schedules/search", "POST", true)

-- 学生提交上课数据
-- http://yapi.kp-para.cn/project/130/interface/api/5127
HttpWrapper.Create("keepwork.schedule.scheduleReports", "%MAIN%/accounting/users/scheduleReports/submit", "POST", true)

--<<<<<<<<<<<<< 课程表 end <<<<<<<<<<<<

-- http://yapi.kp-para.cn/project/655/interface/api/5822
HttpWrapper.Create("keepwork.classrooms.query", "%MAIN%/edu/v0/clients/classrooms/query", "POST", true)

--学生加入课堂
--http://yapi.kp-para.cn/project/655/interface/api/5615
HttpWrapper.Create("keepwork.classrooms.signin", "%MAIN%/edu/v0/classroomStudents/signIn", "POST", true)

--校验用户无权限课包
--http://yapi.kp-para.cn/project/655/interface/api/7167
HttpWrapper.Create("keepwork.lessonPackage.checkLessonNoAuth", "%MAIN%/edu/v0/lessonPackages/:id/checkNoAuthPackages", "POST", true)

-- 查询课堂学生
-- http://yapi.kp-para.cn/project/655/interface/api/7631
HttpWrapper.Create("keepwork.classrooms.students", "%MAIN%/edu/v0/classrooms/student/search", "GET", true)



