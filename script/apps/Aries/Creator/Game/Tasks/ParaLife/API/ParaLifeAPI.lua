--[[
Title: Paralife Buildin API for Live models
Author(s): LiXizhi
Date: 2022/3/30
Desc: we should edit InitDataSources() function for functions to be included in UI. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/API/ParaLifeAPI.lua");
local API = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.API")
local func = API.GetFunction("API.ShowTag")
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/API/ParaLifeAPI_headon.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/API/ParaLifeAPI_mount.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/API/ParaLifeAPI_clickable.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/API/ParaLifeAPI_hover.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/API/ParaLifeAPI_framemove.lua");
-- TODO: add more api files here

local API = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.API");
local DataSources;
local APIMap = {};
local function InitDataSources()
	DataSources = {}

	-- api item format: {name, isDirectCall:bool, attr = {}, }
	-- @param isDirectCall: we will run the code directly without in code block coroutine, which is faster, 
	-- but there can be no invocations to code block functions like wait()
	local _ = {
		-- headon
		["API.ShowTag"] = {isDirectCall=true, name="function", attr = {value = "API.ShowTag", text=L"头顶显示自定义标签", }}, -- only for debugging, use API.ShowHeadon instead
		["API.ShowHeadon"] = {isDirectCall=true, name="function", attr = {value = "API.ShowHeadon", text=L"头顶显示 %1 持续%2秒 %3", param1="headon", text1=L"头顶文字", default1="", param2="duration", text2=L"持续时间(秒)，-1表示一直显示", default2="4", param3="isAbove3D", text3=L"是否高于3D物品显示true|false", default3="false"}},
		["API.HideHeadon"] = {isDirectCall=true, name="function", attr = {value = "API.HideHeadon", text=L"隐藏头顶文字", }}, 

		-- mount
		["API.DragEndSameTag"] = {name="function", attr = {value = "API.DragEndSameTag", text=L"如果目标的自定义标签与本物体不同则复位并提示 %1", param1="dragSameTagTip", text1=L"复位提示", default1="",}}, 
		["API.DragEndOnlyOne"] = {name="function", attr = {value = "API.DragEndOnlyOne", text=L"如果目标上面已有其它物体则复位并提示 %1", param1="dragOnlyOneTip", text1=L"复位提示", default1="",}}, 
		["API.MountSameTag"] = {name="function", attr = {value = "API.MountSameTag", text=L"只能放与模型的自定义标签相同的物体并提示 %1", param1="mountSameTip", text1=L"复位提示", default1="",}}, 
		["API.MountOnlyOne"] = {name="function", attr = {value = "API.MountOnlyOne", text=L"只能放一个物品并提示 %1", param1="mountOnlyOneTip", text1=L"复位提示", default1="",}}, 
		["API.MountSit"] = {name="function", attr = {value = "API.MountSit", text=L"让物体播放坐下的动画", }}, 
		["API.MountDelete"] = {name="function", attr = {value = "API.MountDelete", text=L"删除拖入的物体(垃圾桶逻辑,需有插件点,位置%1)",param1="mountPivot", text1=L"插件点位置:top|mid|bottom", default1="top", }}, 
		["API.MountRestoreRotation"] = {name="function", attr = {value = "API.MountRestoreRotation", text=L"恢复放在其上物体的旋转(需要有物理)",param1="needPhysics", text1="", default1="true",}}, 
		["API.MountPackToGift"] = {name="function", attr = {value = "API.MountPackToGift", text=L"打包放于其上物体成为礼包(需有插件点,位置%1)",param1="mountPivot", text1=L"插件点位置:top|mid|bottom", default1="top",}}, 

		-- clickable
		["API.LookAt"] = {isDirectCall=true, name="function", attr = {value = "API.LookAt", text=L"摄影机观看本模型", }}, 
		["API.ToggleOpen"] = {name="function", attr = {value = "API.ToggleOpen", text=L"切换模型'xxxopen.bmax','xxx.bmax'", }}, 
		["API.ToggleAnim"] = {name="function", attr = {value = "API.ToggleAnim", text=L"切换动作编号 0, %1", param1="anim", text1=L"动画id", default1=70, }}, 
		["API.PushPull"] = {name="function", attr = {value = "API.PushPull", text=L"推进/拉出 %1 米", param1="length", text1=L"长度(米)", default1=1, }},
		["API.LiftDrop"] = {name="function", attr = {value = "API.LiftDrop", text=L"抬起/落下 %1 米", param1="length", text1=L"长度(米)", default1=1, }},
		["API.Door"] = {name="function", attr = {value = "API.Door", text=L"开/关门: %2轴 %1 度", param1="angle", text1=L"角度:[-360,360]", default1=90, param2="axis", text2=L"旋转轴:x|y|z", default2="y", }}, 
		
		["API.ClickLight"] = {name="function", attr = {value = "API.ClickLight", text=L"开灯/关灯（使用隐形光源）", }}, 
		["API.ToggleMusic"] = {name="function", attr = {value = "API.ToggleMusic", text=L"切换播放音乐文件 %1", param1="sound", text1=L"音乐文件mp3|ogg", default1=""}}, 
		["API.ClickGiftBox"] = {name="function", attr = {value = "API.ClickGiftBox", text=L"点击拆礼盒", }}, 
		["API.Flip"] = {isDirectCall=true, name="function", attr = {value = "API.Flip", text=L"水平翻转", }}, 
		["API.Turn"] = {isDirectCall=true, name="function", attr = {value = "API.Turn", text=L"旋转 %1 度", param1="angle", text1=L"角度:[-180,180]", default1=90}}, 
		
		["API.RandomWalkToSameBlockType"] = {name="function", attr = {value = "API.RandomWalkToSameBlockType", text=L"随机移动到附近同类型方格中能够"}}, 
		["API.FloatToWaterSurface"] = {name="function", attr = {value = "API.FloatToWaterSurface", text=L"漂浮到水面，水下高度%1米", param1="inWaterDepth", text1=L"吃水深度(米)", default1=0.4}}, 

		-- Hover & Drag End
		["API.HoverToPieces"] = {name="function", attr = {value = "API.HoverToPieces", text=L"悬浮其上播放粉碎效果", }}, 
		["API.dragEndMaxDist"] = {name="function", attr = {value = "API.dragEndMaxDist", text=L"拖动距离超过 %1米则复位", param1="maxDragDist", text1=L"最大的可拖动距离", default1=3, }}, 

		-- framemove heart beat ticks
		["API.RandomWalk"] = {name="function", attr = {value = "API.RandomWalk", text=L"随机走动: 半径%1米,速度%2米/秒,间隔%3秒", param1="maxWalkRadius", text1=L"最大行走半径(米)", default1=3, param2="walkSpeed", text2=L"行走速度(米/秒)", default2=4, param3="walkInterval", text3=L"行走时间间隔(秒)", default3=5,}}, 
		["API.Follow"] = {name="function", attr = {value = "API.Follow", text=L"跟随角色%1: 最小半径%2米, 最大半径%3米", param1="followTarget", text1=L"角色名称, @p表示主角", default1="@p", param2="minDist", text2=L"最小半径(米)", default2=1, param3="maxDist", text3=L"最大半径(米)", default3=3,}}, 
	}
	APIMap = _;

	DataSources.onClickEvent = {
		attr = {text=L"当用户点击本模型时:"},
		_["API.ShowHeadon"],
		_["API.LookAt"],
		_["API.ToggleOpen"],
		_["API.ToggleAnim"],
		_["API.PushPull"],
		_["API.LiftDrop"],
		_["API.Door"],
		_["API.ClickLight"],
		_["API.ToggleMusic"],
		_["API.Flip"],
		_["API.Turn"],
		_["API.RandomWalkToSameBlockType"],
		_["API.FloatToWaterSurface"],
	};
	DataSources.onBeginDragEvent = {
		attr = {text=L"当用户开始拖动本模型时:"},
		_["API.ShowHeadon"],
		_["API.Turn"],
	}
	DataSources.onEndDragEvent = {
		attr = {text=L"当用户结束拖动本模型时:"},
		_["API.HideHeadon"],
		_["API.DragEndSameTag"],
		_["API.DragEndOnlyOne"],
		_["API.LookAt"],
		_["API.Flip"],
		_["API.Turn"],
		_["API.dragEndMaxDist"],
		_["API.FloatToWaterSurface"],
	}
	DataSources.onMountEvent = {
		attr = {text=L"当有物体放在本模型之上时:"},
		_["API.MountSameTag"],
		_["API.MountOnlyOne"],
		_["API.MountSit"],
		_["API.MountDelete"],
		_["API.LookAt"],
		_["API.MountRestoreRotation"],
		_["API.MountPackToGift"],
	}
	DataSources.onHoverEvent = {
		attr = {text=L"当有物体悬停在上方时:"},
		_["API.ShowHeadon"],
		_["API.HoverToPieces"],
	}
	DataSources.onTickEvent = {
		attr = {text=L"每隔一定时间自动调用:"},
		_["API.Turn"],
		_["API.RandomWalk"],
		_["API.Follow"],
	}
	
end

-- @param name: such as "API.ShowTag", must begin with "API"
-- @return nil if not found or the function itself. 
function API.GetFunction(name)
	local item = API.GetFunctionItem(name)
	return item and item.func;
end

-- @return nil or {name, func, isDirectCall, attr = {}, }
function API.GetFunctionItem(name)
	if(name) then
		if(not DataSources) then
			InitDataSources();
		end
		local item = APIMap[name]
		if(item) then
			if(not item.func) then
				local shortName = name:gsub("^API%.","")
				if(shortName ~= name) then
					local func = commonlib.getfield(shortName, API)
					if(type(func) == "function") then
						item.func = func;
					end
				end
				if(not item.func) then
					item.func = API.NotFound
					LOG.std(nil, "warn", "ParaLife.API", "%s is not found", name);
				end
			end
			return item
		end
	end
end

function API.NotFound()
end

-- @param category: nil or "onclickEvent", "onhoverEvent", "onmountEvent", "onbeginDragEvent", "onendDragEvent"
function API.GetFunctionsDataSource(category)
	if(not DataSources) then
		InitDataSources();
	end
	return DataSources[category or "onclickEvent"]
end
