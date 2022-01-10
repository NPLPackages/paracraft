--[[
Title: edit movie text
Author(s): LiXizhi
Date: 2014/5/12
Desc: edit movie text page
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EditModel/EditModelProperty.lua");
local EditModelProperty = commonlib.gettable("MyCompany.Aries.Game.Tasks.EditModelProperty");
EditModelProperty.ShowPage(function(values)
	echo(values);
end, {name="1", itemId, canDrag=true})
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EditModel/EditModelProperty.lua");
local EditModelProperty = commonlib.gettable("MyCompany.Aries.Game.Tasks.EditModelProperty");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");


local page;
function EditModelProperty.OnInit()
	page = document:GetPageCtrl();
end

-- @param OnClose: function(values) end 
-- @param last_values: {name, ...}
function EditModelProperty.ShowPage(OnClose, last_values)
	EditModelProperty.result = last_values;
	if(last_values) then
		EditModelProperty.mountpoints = last_values.mountpoints
	end
	local params = {
			url = "script/apps/Aries/Creator/Game/Tasks/EditModel/EditModelProperty.html", 
			name = "EditModelProperty.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			bToggleShowHide=false, 
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			click_through = false, 
			enable_esc_key = true,
			bShow = true,
			isTopLevel = true,
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			directPosition = true,
				align = "_ct",
				x = -320,
				y = -200,
				width = 640,
				height = 350,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);

	EditModelProperty.UpdateUIFromValue(last_values);
	
	params._page.OnClose = function()
		if(OnClose) then
			OnClose(EditModelProperty.result);
		end
	end
end

local function StringToBooleanNil(value)
	if(value == "true") then
		return true
	elseif(value == "false") then
		return false
	end
end

function EditModelProperty.OnOK()
	if(page) then
		local name = page:GetValue("name");
		
		local stackHeight = page:GetValue("stackHeight")
		if(stackHeight~="nil") then
			stackHeight = tonumber(stackHeight) or 0.2;
			stackHeight = math.min(math.max(stackHeight, 0), 10);
		end
		local idleAnim = tonumber(page:GetValue("idleAnim", 0)) or 0
		local hasRealPhysics = StringToBooleanNil(page:GetValue("hasRealPhysics"))
		local autoTurning = StringToBooleanNil(page:GetValue("autoTurning"))
		local isStackable = StringToBooleanNil(page:GetValue("isStackable"))
		local canDrag = StringToBooleanNil(page:GetValue("canDrag"))

		EditModelProperty.result = {
			name = name,
			stackHeight = stackHeight,
			idleAnim = idleAnim, 
			hasRealPhysics = hasRealPhysics,
			autoTurning = autoTurning,
			isStackable = isStackable,
			canDrag = canDrag,
			onClickEvent = page:GetValue("onClickEvent"),
			onHoverEvent = page:GetValue("onHoverEvent"),
			onMountEvent = page:GetValue("onMountEvent"),
			onBeginDragEvent = page:GetValue("onBeginDragEvent"),
			onEndDragEvent = page:GetValue("onEndDragEvent"),
			modelfile = page:GetValue("modelfile"),
			tag = page:GetValue("tag"),
			staticTag = page:GetValue("staticTag"),
			category = page:GetValue("category"),
			mountpoints = EditModelProperty.mountpoints,
		};
		page:CloseWindow();
	end
end

function EditModelProperty.UpdateUIFromValue(values)
	if(page and values) then
		if(values.name) then
			page:SetValue("name", values.name);
		end
		page:SetValue("isStackable", tostring(values.isStackable));
		page:SetValue("stackHeight", tostring(values.stackHeight));
		page:SetValue("idleAnim", tostring(values.idleAnim));
		page:SetValue("hasRealPhysics", tostring(values.hasRealPhysics));
		page:SetValue("autoTurning", tostring(values.autoTurning));
		page:SetValue("canDrag", tostring(values.canDrag));
		page:SetValue("onClickEvent", tostring(values.onClickEvent or ""));
		page:SetValue("onHoverEvent", tostring(values.onHoverEvent or ""));
		page:SetValue("onMountEvent", tostring(values.onMountEvent or ""));
		page:SetValue("onBeginDragEvent", tostring(values.onBeginDragEvent or ""));
		page:SetValue("onEndDragEvent", tostring(values.onEndDragEvent or ""));
		page:SetValue("modelfile", tostring(values.modelfile or ""));
		page:SetValue("staticTag", tostring(values.staticTag or ""));
		page:SetValue("category", tostring(values.category or ""));
		EditModelProperty.mountpoints = values.mountpoints;
		page:CallMethod("mountpoints", "DataBind");
	end
end

function EditModelProperty.OnClose()
	page:CloseWindow();
end

function EditModelProperty.OnReset()
	if(EditModelProperty.result) then
		EditModelProperty.UpdateUIFromValue(EditModelProperty.result);
	end
end

function EditModelProperty.GetItemID()
	if(EditModelProperty.result) then
		return EditModelProperty.result.itemId
	end
end

function EditModelProperty.OnOpenModelFile()
end

function EditModelProperty.OnTextChange(name, mcmlNode)
	local index = name and name:match("%d+")
	if(index) then
		index = tonumber(index)
		local text = mcmlNode:GetUIValue()
		if(EditModelProperty.mountpoints) then
			EditModelProperty.mountpoints[index].name = text;
		end
	end
end