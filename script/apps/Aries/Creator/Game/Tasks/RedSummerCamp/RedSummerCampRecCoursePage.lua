--[[
Title: RedSummerCampRecCoursePage
Author(s): leio
Date: 2021/7/6
Desc:  the recommended course page for red summer camp 2021
Use Lib:
-------------------------------------------------------
local RedSummerCampRecCoursePage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampRecCoursePage.lua");
RedSummerCampRecCoursePage.Show();
--]]

local ParacraftLearningRoomDailyPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParacraftLearningRoom/ParacraftLearningRoomDailyPage.lua");

local RedSummerCampRecCoursePage = NPL.export();
RedSummerCampRecCoursePage.courses_1 = {
 { id = 29477, label = L"欢迎来到帕拉卡",  icon = "Texture/Aries/Creator/keepwork/RedSummerCamp/courses/icons/welcome_32bits.png;0 0 195 100",  },
 { id = 455, label = L"有了想法怎么做",  icon = "Texture/Aries/Creator/keepwork/RedSummerCamp/courses/icons/idea_32bits.png;0 0 195 100",  },
 { id = 79969, label = L"乐园设计师",  icon = "Texture/Aries/Creator/keepwork/RedSummerCamp/courses/icons/1_211X106_32bits.png;0 0 195 100",  },
}

RedSummerCampRecCoursePage.courses_2 = {
 { id = 42670, label = L"动画入门",  icon = "Texture/Aries/Creator/keepwork/RedSummerCamp/courses/icons/kaka_32bits.png;0 0 195 100",  },
 { id = 42701, label = L"建模入门",  icon = "Texture/Aries/Creator/keepwork/RedSummerCamp/courses/icons/lala_32bits.png;0 0 195 100",  },
 { id = 42457, label = L"编程入门",  icon = "Texture/Aries/Creator/keepwork/RedSummerCamp/courses/icons/papa_32bits.png;0 0 195 100",  },
}

RedSummerCampRecCoursePage.courses_3 = {
 { id = 19405, label = L"孙子兵法",  icon = "Texture/Aries/Creator/keepwork/RedSummerCamp/courses/icons/sunzibingfa_32bits.png;0 0 195 100",  },
 { id = 70351, label = L"夏令营每日一课",  icon = "Texture/Aries/Creator/keepwork/RedSummerCamp/courses/icons/list_32bits.png;0 0 195 100",  },
 { id = 0, name="codewar", label = L"玩学课堂",  icon = "Texture/Aries/Creator/keepwork/RedSummerCamp/courses/icons/wanxue_32bits.png;0 0 195 100",  },
}
function RedSummerCampRecCoursePage.Show()
	ParacraftLearningRoomDailyPage.ShowPage_RedSummerCamp();
end
