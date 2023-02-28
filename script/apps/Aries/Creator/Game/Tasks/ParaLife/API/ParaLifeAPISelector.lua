--[[
Title: Paralife API selector page
Author(s): LiXizhi
Date: 2022/4/1
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/API/ParaLifeAPISelector.lua");
local ParaLifeAPISelector = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.ParaLifeAPISelector")
ParaLifeAPISelector.ShowPage(true, category, callbackFunc)
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/API/ParaLifeAPI.lua");
local API = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.API")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local ParaLifeAPISelector = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.ParaLifeAPISelector")

local page;
local self = ParaLifeAPISelector;
function ParaLifeAPISelector.OnInit()
	page = document:GetPageCtrl();
end

function ParaLifeAPISelector.ShowPage(bShow, category, callbackFunc, lastValue, properties)
	ParaLifeAPISelector.callbackFunc = callbackFunc;
	ParaLifeAPISelector.category = category;
	ParaLifeAPISelector.SetLastValue(lastValue)
	ParaLifeAPISelector.properties = properties or {};
	local width, height = 500, 520;
	local params = {
			url = "script/apps/Aries/Creator/Game/Tasks/ParaLife/API/ParaLifeAPISelector.html", 
			name = "ParaLifeAPISelector.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			bToggleShowHide=false, 
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			isTopLevel = true,
			click_through = false, 
			enable_esc_key = true,
			bShow = bShow~=false,
			directPosition = true,
				align = "_ct",
				x = -width/2,
				y = -height/2,
				width = width,
				height = height,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function ParaLifeAPISelector.GetDataSource()
	return API.GetFunctionsDataSource(ParaLifeAPISelector.category)
end

function ParaLifeAPISelector.SetLastValue(value)
	ParaLifeAPISelector.values = commonlib.OrderedArraySet:new();
	ParaLifeAPISelector.text = nil;
	if(value) then
		for func in string.gmatch(value, "%s*([^;]+)%s*") do
			if(func:match("^API%.")) then
				ParaLifeAPISelector.values:add(func);
			else
				ParaLifeAPISelector.text = func;
			end
		end
	end
end

function ParaLifeAPISelector.GetValueCount()
	return ParaLifeAPISelector.values and ParaLifeAPISelector.values:size() or 0;
end

function ParaLifeAPISelector.IsFunctionChecked(name)
	return ParaLifeAPISelector.values:contains(name or "");
end

function ParaLifeAPISelector.OnClickItem(bChecked,mcmlNode)
	local nameNode = mcmlNode:GetAttribute("name");
	local value = nameNode.value
	if(value) then
		if(ParaLifeAPISelector.values:contains(value)) then
			ParaLifeAPISelector.values:removeByValue(value);
		else
			ParaLifeAPISelector.values:insert(1, value);
		end
		local checked = ParaLifeAPISelector.IsFunctionChecked(value) 
		local paramIndex = 1
		for paramIndex = 1, 10 do
			local param = nameNode["param"..paramIndex]
			if(param) then
				local value = ParaLifeAPISelector.properties and ParaLifeAPISelector.properties[param]
				if(value == nil) then
					value = nameNode["default"..paramIndex]
				end
				value = tostring(value)
				ParaLifeAPISelector.properties[param] = checked and value or nil
				ParaLifeAPISelector.properties[param.."_checked"] = checked
			else
				break;
			end
		end
		ParaLifeAPISelector.RefreshPage()
	end
end

function ParaLifeAPISelector.RefreshPage()
	if(page) then
		ParaLifeAPISelector.text = page:GetValue("text");
		page:Refresh(0.01);
	end
end

function ParaLifeAPISelector.GetTitle()
	local ds = API.GetFunctionsDataSource(ParaLifeAPISelector.category)
	if(ds and ds.attr) then
		return ds.attr.text;
	end
end

function ParaLifeAPISelector.Close()
	if(page) then
		page:CloseWindow()
		page = nil;
	end
end

function ParaLifeAPISelector.GetValueFromUI()
	if(page) then
		local value = "";
		for i=1, #(ParaLifeAPISelector.values) do
			if(value~="") then
				value = value..";";
			end
			value = value..ParaLifeAPISelector.values[i];
		end
		text = page:GetValue("text")
		if(value and value~="") then
			if(text and text~="") then
				value = value..";"..text;
			end
		else
			value = text or "";
		end
		return value;
	end
end

function ParaLifeAPISelector.OnOK()
	local value = ParaLifeAPISelector.GetValueFromUI()
	ParaLifeAPISelector.Close()
	if(ParaLifeAPISelector.callbackFunc) then
		ParaLifeAPISelector.callbackFunc(value)
	end
end

function ParaLifeAPISelector.OnClear()
	ParaLifeAPISelector.values:clear();
	ParaLifeAPISelector.RefreshPage();
end

function ParaLifeAPISelector.GetText(attr)
	local text = attr.text;
	local paramIndex = 1
	for paramIndex = 1, 10 do
		local param = attr["param"..paramIndex]
		if(param) then
			local displayText = attr["text"..paramIndex]
			local value = ParaLifeAPISelector.properties and ParaLifeAPISelector.properties[param]
			local color;
			if(value == nil) then
				value = attr["default"..paramIndex]
				color = "#000000"
			end
			value = tostring(value);
			if(value == "") then
				value = "\"\""
			end
			if(commonlib.Encoding.HasXMLEscapeChar(value)) then
				value = commonlib.Encoding.EncodeStr(value)
			end

			value = string.format([[<input type="button" name="%s" class="mc_button_grey" uiname='ParaLifeAPISelector.edit_%s' style='color:%s;margin-top:1px;min-width:20px;height:20px;' value="%s" onclick="ParaLifeAPISelector.OnClickEditItem" tooltip="%s" param1 = "%s"/>]], 
				param, param.."_"..attr.value,
				color or "#33ff33", value, displayText or "",attr.value)
			text = text:gsub("%%"..paramIndex, value);
		else
			break;
		end
	end
    return text;
end

function ParaLifeAPISelector.OnClickEditItem(paramName, mcmlNode)
	local displayName = mcmlNode:GetAttribute("tooltip")
	local oldValue = ParaLifeAPISelector.properties and ParaLifeAPISelector.properties[paramName]
	if(oldValue == nil) then
		oldValue = mcmlNode:GetValue() or "";
		if(oldValue == "\"\"") then
			oldValue = ""
		end
	end
	oldValue = tostring(oldValue);
	NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EnterTextDialog.lua");
	local EnterTextDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.EnterTextDialog");
	EnterTextDialog.ShowPage(format(L"请输入'%s'的值, %s:", displayName or "", paramName), function(result)
		if(result ~= oldValue) then
			if(result and result ~= "") then
				local param1 = mcmlNode:GetAttribute("param1")
				local checked = ParaLifeAPISelector.IsFunctionChecked(param1) 
				ParaLifeAPISelector.properties[paramName] = result;
				ParaLifeAPISelector.properties[paramName.."_checked"] = checked
			else
				if(ParaLifeAPISelector.properties) then
					ParaLifeAPISelector.properties[paramName] = nil;
				end
			end
			ParaLifeAPISelector.RefreshPage();
		end
	end, oldValue)
end