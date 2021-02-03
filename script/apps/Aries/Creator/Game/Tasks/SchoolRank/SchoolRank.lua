--[[

    local SchoolRank = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SchoolRank/SchoolRank.lua");
    SchoolRank.ShowView()
]]
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
local SchoolRank = NPL.export()
SchoolRank.rank_data = {}
local page 

function SchoolRank.OnInit()
	page = document:GetPageCtrl();
end

function SchoolRank.WordsLimit(str)
    if (_guihelper.GetTextWidth(str, "System;16") > 132) then
        local text = commonlib.utf8.sub(str, 1, 8) .. "...";
        return text
    end
    return str
end

function SchoolRank.getTempData()
    SchoolRank.rank_data = {}
    for i = 1,10 do
        local temp = {}
        temp.rank = i
        temp.schoolname = "深圳市南山区外国语国际学校_"..i
        temp.schoolid = 274840
        temp.isvipschool = 0
        temp.grades=(4 * 1000 + i).."分"
        temp.gsId=90004
        temp.id=2
        temp.schoolId = 274840
        temp.userCount=4 

        SchoolRank.rank_data[#SchoolRank.rank_data + 1] = temp
    end
    echo(SchoolRank.rank_data)
end
--[[
    
      createdAt="2021-01-19T02:26:57.000Z",
      C=4,
      gsId=90004,
      id=2,
      rank=1,
      school={
        createdAt="2020-07-20T01:50:45.000Z",
        id=274840,
        isVip=0,
        name="延边大学",
        orgId=128,
        regionId=845,
        status=1,
        type="大学",
        updatedAt="2020-12-22T09:48:18.000Z",
        userCount=1,
        userId=0 
      },
      schoolId=274840,
      updatedAt="2021-01-19T02:27:16.000Z",
      userCount=4 
    },
]]
function SchoolRank.getPageData(data)
    SchoolRank.rank_data = {}
    local rank_num = #data
    for i=1,rank_num do
        local temp = {}
        temp.rank = data[i].rank
        temp.schoolname = data[i].school.name 
        temp.schoolid = data[i].schoolId
        temp.grades=data[i].grades.."分"
        temp.projectId = data[i].schoolParaWorld and data[i].schoolParaWorld.projectId or -1
        SchoolRank.rank_data[#SchoolRank.rank_data + 1] = temp
    end
end

function SchoolRank.ShowView()
    keepwork.wintercamp.rank({
        gsId = 90004,
        top = 10,
    },function(err, msg, data)
        if err == 200 then
            SchoolRank.getPageData(data.data)
            local view_width = 740
            local view_height = 566
            local params = {
                url = "script/apps/Aries/Creator/Game/Tasks/SchoolRank/SchoolRank.html",
                name = "SchoolRank.ShowView", 
                isShowTitleBar = false,
                DestroyOnClose = true,
                style = CommonCtrl.WindowFrame.ContainerStyle,
                allowDrag = true,
                enable_esc_key = true,
                zorder = 0,
                app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
                directPosition = true,
                    align = "_ct",
                    x = -view_width/2,
                    y = -view_height/2,
                    width = view_width,
                    height = view_height,
            };
            System.App.Commands.Call("File.MCMLWindowFrame", params);  
        else
            
        end
    end)
     
end