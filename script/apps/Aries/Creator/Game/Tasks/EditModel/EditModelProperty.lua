--[[
Title: edit model property
Author(s): LiXizhi
Date: 2022/1/1
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EditModel/EditModelProperty.lua");
local EditModelProperty = commonlib.gettable("MyCompany.Aries.Game.Tasks.EditModelProperty");
EditModelProperty.ShowForEntity(modelEntity)
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

-- @param modelEntity: EntityBlockModel or EntityLiveModel
function EditModelProperty.ShowForEntity(modelEntity)
	if(modelEntity) then
		local mountpoints
		if(modelEntity:GetMountPoints()) then
			mountpoints = {};
			for i = 1, modelEntity:GetMountPoints():GetCount() do 
				local mp = modelEntity:GetMountPoints():GetMountPoint(i)
				mountpoints[#mountpoints + 1] = {index = i, name = mp:GetName()}
			end
		end
		EditModelProperty.ShowPage(function(values)
			if(values) then
				if(modelEntity:GetName()~=values.name and not modelEntity:isa(EntityManager.EntityBlockBase)) then
					if(not EntityManager.GetEntity(values.name)) then
						modelEntity:SetName(values.name)
					else
						_guihelper.MessageBox(L"%s名字已经存在了, 无法改名。请换个名字")
					end
				end
				modelEntity:SetIsStackable(values.isStackable)
				modelEntity:SetStackHeight(values.stackHeight)
				modelEntity:SetIdleAnim(values.idleAnim or 0)
				modelEntity:SetCanDrag(values.canDrag)
				modelEntity:SetAutoTurningDuringDragging(values.autoTurning)
				modelEntity.isDisplayModel = values.isDisplayModel~=false;
					
				if(values.onClickEvent == "") then
					values.onClickEvent = nil
				end
				modelEntity:SetOnClickEvent(values.onClickEvent)
					
				if(values.onHoverEvent == "") then
					values.onHoverEvent = nil
				end
				modelEntity:SetOnHoverEvent(values.onHoverEvent)
					
				if(values.onMountEvent == "") then
					values.onMountEvent = nil
				end
				modelEntity:SetOnMountEvent(values.onMountEvent)

				if(values.onBeginDragEvent == "") then
					values.onBeginDragEvent = nil
				end
				modelEntity:SetOnBeginDragEvent(values.onBeginDragEvent)

				if(values.onEndDragEvent == "") then
					values.onEndDragEvent = nil
				end
				modelEntity:SetOnEndDragEvent(values.onEndDragEvent)

				if(values.tag == "") then
					values.tag = nil
				end
				modelEntity:SetTag(values.tag)

				if(values.staticTag == "") then
					values.staticTag = nil
				end
				modelEntity:SetStaticTag(values.staticTag)

				if(values.category == "") then
					values.category = nil
				end
				modelEntity:SetCategory(values.category)

				if(values.modelfile ~= modelEntity:GetModelFile()) then
					modelEntity:SetModelFile(values.modelfile)
				end
				if(values.mountpoints and modelEntity:GetMountPoints()) then
					for i, mp in ipairs(values.mountpoints) do
						local mountpoint = modelEntity:GetMountPoints():GetMountPoint(i)
						if(mountpoint) then
							mountpoint.name = mp.name;
						end
					end
				end
				-- this one needs to be called last, since it may change entity.  
				modelEntity:EnablePhysics(values.hasRealPhysics)
			end
		end, {
			name=modelEntity:GetName(), 
			itemId = modelEntity:GetItemId(),
			hasRealPhysics = modelEntity:HasRealPhysics(),
			isStackable = modelEntity.isStackable,
			isDisplayModel = modelEntity:IsDisplayModel(),
			stackHeight = modelEntity.stackHeight,
			autoTurning = modelEntity.bIsAutoTurning,
			canDrag = modelEntity.canDrag,
			onClickEvent = modelEntity:GetOnClickEvent(),
			onHoverEvent = modelEntity:GetOnHoverEvent(),
			onMountEvent = modelEntity:GetOnMountEvent(),
			onBeginDragEvent = modelEntity:GetOnBeginDragEvent(),
			onEndDragEvent = modelEntity:GetOnEndDragEvent(),
			tag = modelEntity:GetTag(),
			staticTag = modelEntity:GetStaticTag(),
			category = modelEntity:GetCategory(),
			modelfile = modelEntity:GetModelFile(),
			idleAnim = modelEntity:GetIdleAnim(),
			mountpoints = mountpoints, 
		})
	end
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
			isDisplayModel = page:GetValue("isDisplayModel"),
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
		page:SetValue("isDisplayModel", values.isDisplayModel);
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