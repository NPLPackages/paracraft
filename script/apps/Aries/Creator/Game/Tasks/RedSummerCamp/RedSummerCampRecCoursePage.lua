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

RedSummerCampRecCoursePage.courses = {
	{ id = 29477, label = L"欢迎来到帕拉卡",  icon = "Texture/Aries/Creator/keepwork/RedSummerCamp/courses/icons/welcome_32bits.png;0 0 195 100",  },
	{ id = 42701, label = L"建模入门",  icon = "Texture/Aries/Creator/keepwork/RedSummerCamp/courses/icons/lala_32bits.png;0 0 195 100",  },
	{ id = 42457, label = L"编程入门",  icon = "Texture/Aries/Creator/keepwork/RedSummerCamp/courses/icons/papa_32bits.png;0 0 195 100",  },

	{ id = 42670, label = L"动画入门",  icon = "Texture/Aries/Creator/keepwork/RedSummerCamp/courses/icons/kaka_32bits.png;0 0 195 100",  },
	{ id = 455, label = L"有了想法怎么做",  icon = "Texture/Aries/Creator/keepwork/RedSummerCamp/courses/icons/idea_32bits.png;0 0 195 100",  },
	{ id = 113, label = L"肇庆市第一中学",  icon = "Texture/Aries/Creator/keepwork/RedSummerCamp/courses/icons/ke1_195x100_32bits.png;0 0 195 100",  },

	
	{ id = 2769, label = L"象形之美",  icon = "Texture/Aries/Creator/keepwork/RedSummerCamp/courses/icons/ke2_195x100_32bits.png;0 0 195 100",  },
	{ id = 1082, label = L"火星探险",  icon = "Texture/Aries/Creator/keepwork/RedSummerCamp/courses/icons/ke3_195x100_32bits.png;0 0 195 100",  },
	{ id = 475, label = L"男孩与苹果树",  icon = "Texture/Aries/Creator/keepwork/RedSummerCamp/courses/icons/ke4_195x100_32bits.png;0 0 195 100",  },
}

function RedSummerCampRecCoursePage.Show()
	ParacraftLearningRoomDailyPage.ShowPage_RedSummerCamp();
end
