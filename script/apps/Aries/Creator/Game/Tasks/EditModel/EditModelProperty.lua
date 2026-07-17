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
NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/OpenAssetFileDialog.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/PlayerAssetFile.lua");
local EditModelProperty = commonlib.gettable("MyCompany.Aries.Game.Tasks.EditModelProperty");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local Color = commonlib.gettable("System.Core.Color");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local OpenAssetFileDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.OpenAssetFileDialog");
local PlayerAssetFile = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerAssetFile")
local page;
EditModelProperty.mountpoint_expanded = false;
local function StringToBooleanNil(value)
	if type(value) == "boolean" then
		return value
	elseif(value == "true") then
		return true
	elseif(value == "false") then
		return false
	end
end

function EditModelProperty.OnInit()
	page = document:GetPageCtrl();
end

function EditModelProperty.GetEntity()
	return EditModelProperty.entity;
end

-- @param modelEntity: EntityBlockModel or EntityLiveModel
function EditModelProperty.ShowForEntity(modelEntity, callbackFunc)
	EditModelProperty.entity = modelEntity;
	if(modelEntity) then
		local mountpoints
		if(modelEntity:GetMountPoints()) then
			mountpoints = {};
			for i = 1, modelEntity:GetMountPoints():GetCount() do 
				local mp = modelEntity:GetMountPoints():GetMountPoint(i)
				mountpoints[#mountpoints + 1] = {index = i, name = mp:GetName()}
			end
		end
		local physicsType;
		if(modelEntity:IsDynamicPhysicsEnabled()) then
			physicsType = "dynamic"..modelEntity:GetPhysicsShape();
		else
			physicsType = modelEntity:HasRealPhysics()
		end
		
		EditModelProperty.ShowPage(function(values)
			if(values) then
				if(modelEntity:GetName()~=values.name) then
					-- entity live model must use globally unique name. entity block model can share the same name
					local isNameGloballyUnique = (not modelEntity:isa(EntityManager.EntityBlockBase))
					if(not isNameGloballyUnique or not EntityManager.GetEntity(values.name)) then
						modelEntity:SetName(values.name)
					else
						_guihelper.MessageBox(format(L"%s名字已经存在了, 无法改名。请换个名字", values.name or ""))
					end
				end
				-- tricky: we may transform from block model to live model in this case. 
				modelEntity = modelEntity:SetCanDrag(values.canDrag) or modelEntity;
				modelEntity:SetIsStackable(values.isStackable)
				modelEntity:SetStackHeight(values.stackHeight)
				modelEntity:SetFrameMoveInterval(values.framemove_interval);
				if(modelEntity.SetDragDisplayOffsetY) then
					modelEntity:SetDragDisplayOffsetY(values.dragDisplayOffsetY)
				end				
				modelEntity:SetIdleAnim(values.idleAnim or 0)
				if(modelEntity.SetAnimFrame) then
					modelEntity:SetAnimFrame(values.animFrame)
				end
				modelEntity:SetAutoTurningDuringDragging(values.autoTurning)
				modelEntity:SetDisplayModel(values.isDisplayModel~=false)
				modelEntity:EnableDropFall(values.enableDropFall~=false)
				modelEntity:SetTrigger(values.isTrigger == true)
				if(values.onTriggerEnterEvent == "") then
					values.onTriggerEnterEvent = nil
				end
				modelEntity:SetOnTriggerEnterEvent(values.onTriggerEnterEvent)
				if(values.onTriggerExitEvent == "") then
					values.onTriggerExitEvent = nil
				end
				modelEntity:SetOnTriggerExitEvent(values.onTriggerExitEvent)

				modelEntity:SetLocked(values.isLocked)
				
				local opacity = tonumber(values.opacity)
				if(opacity and opacity>=0 and opacity<=1) then
					modelEntity:SetOpacity(opacity);
				end
				
				local color = values.color
				if(color and color ~= "") then
					modelEntity:SetColor(color);
				else
					modelEntity:SetColor(nil);
				end
				
				local bootHeight = tonumber(values.bootHeight)
				if(bootHeight and modelEntity.SetBootHeight ~= nil) then
					modelEntity:SetBootHeight(bootHeight);
				end

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

				if(values.onTickEvent == "") then
					values.onTickEvent = nil
				end
				modelEntity:SetOnTickEvent(values.onTickEvent)

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
				
				if(type(values.hasRealPhysics) == "string" and values.hasRealPhysics:match("^dynamic")) then
					local shape = values.hasRealPhysics:match("^dynamic(.*)");
					if(shape and shape ~= "" and modelEntity:GetPhysicsShape() ~= shape) then
						modelEntity:EnableDynamicPhysics(false)
						modelEntity:SetPhysicsShape(shape);
					end
					modelEntity:EnableDynamicPhysics(true)
				else
					if(modelEntity:IsDynamicPhysicsEnabled()) then
						modelEntity:EnableDynamicPhysics(false)
					end
					modelEntity:EnablePhysics(StringToBooleanNil(values.hasRealPhysics))
				end
				if(callbackFunc) then
					callbackFunc(modelEntity)
				end
			end
		end, {
			name=modelEntity:GetName(), 
			itemId = modelEntity:GetItemId(),
			hasRealPhysics = physicsType,
			isStackable = modelEntity.isStackable,
			isDisplayModel = modelEntity:IsDisplayModel(),
			enableDropFall = modelEntity:IsDropFallEnabled(),
			isLocked = modelEntity:IsLocked(),
			opacity = modelEntity:GetOpacity(),
			color = Color.FromValueToStr(modelEntity:GetColor()),
			bootHeight = modelEntity.GetBootHeight ~= nil and modelEntity:GetBootHeight() or 0,
			stackHeight = modelEntity.stackHeight,
			framemove_interval = modelEntity.framemove_interval,
			dragDisplayOffsetY = modelEntity.dragDisplayOffsetY,
			autoTurning = modelEntity.bIsAutoTurning,
			canDrag = modelEntity.canDrag,
			isTrigger = modelEntity.isTrigger,
			onTriggerEnterEvent = modelEntity:GetOnTriggerEnterEvent(),
			onTriggerExitEvent = modelEntity:GetOnTriggerExitEvent(),
			onClickEvent = modelEntity:GetOnClickEvent(),
			onHoverEvent = modelEntity:GetOnHoverEvent(),
			onMountEvent = modelEntity:GetOnMountEvent(),
			onBeginDragEvent = modelEntity:GetOnBeginDragEvent(),
			onEndDragEvent = modelEntity:GetOnEndDragEvent(),
			onTickEvent = modelEntity:GetOnTickEvent(),
			tag = modelEntity:GetTag(),
			staticTag = modelEntity:GetStaticTag(),
			category = modelEntity:GetCategory(),
			modelfile = modelEntity:GetModelFile(),			idleAnim = modelEntity:GetIdleAnim(),
			animFrame = modelEntity.GetAnimFrame and modelEntity:GetAnimFrame() or nil,
			mountpoints = mountpoints,
		})
	end
end

local dropNames = {"framemove_interval","category","dragDisplayOffsetY","idleAnim","animFrame","stackHeight","isStackable","canDrag","autoTurning","hasRealPhysics"}
function EditModelProperty.HideDropdownList()
	if(page) then
		for i, name in ipairs(dropNames) do
			local ctrl = page:FindControl(name);
			if ctrl and ctrl.Destroy then
				ctrl:Destroy()
			end
		end
	end
end

-- @param OnClose: function(values) end 
-- @param last_values: {name, ...}
function EditModelProperty.ShowPage(OnClose, last_values)
	EditModelProperty.result = last_values;
	EditModelProperty.mountpoint_expanded = false;
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
			-- isTopLevel = true,
			zorder = -1,
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			directPosition = true,
				align = "_ct",
				x = -320,
				y = -210,
				width = 650,
				height = 410,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);

	EditModelProperty.UpdateUIFromValue(last_values);
	
	params._page.OnClose = function()
		if(OnClose) then
			OnClose(EditModelProperty.result);
			EditModelProperty.HideDropdownList()
		end
	end
end

function EditModelProperty.OnOK()
	if(page) then
		local name = page:GetValue("name");
		
		local stackHeight = page:GetValue("stackHeight")
		if(stackHeight~="nil") then
			stackHeight = tonumber(stackHeight) or 0.2;
			stackHeight = math.min(math.max(stackHeight, 0), 10);
		else
			stackHeight = nil;
		end
		local framemove_interval = page:GetValue("framemove_interval")
		framemove_interval = tonumber(framemove_interval);
		
		local category = page:GetValue("category")
		local dragDisplayOffsetY = page:GetValue("dragDisplayOffsetY")
		if(category == "staticblock") then
			dragDisplayOffsetY = 0;
		else
			if(dragDisplayOffsetY~="nil") then
				dragDisplayOffsetY = tonumber(dragDisplayOffsetY) or 0.3;
				dragDisplayOffsetY = math.min(math.max(dragDisplayOffsetY, -1), 1);
			else
				dragDisplayOffsetY = nil;
			end
		end
		local idleAnim = tonumber(page:GetValue("idleAnim", 0)) or 0
		local animFrame = page:GetValue("animFrame")
		if(animFrame == "") then
			animFrame = nil
		elseif(animFrame) then
			animFrame = tonumber(animFrame)
		end
		local hasRealPhysics = page:GetValue("hasRealPhysics")
		local autoTurning = StringToBooleanNil(page:GetValue("autoTurning"))
		local isStackable = StringToBooleanNil(page:GetValue("isStackable"))
		local canDrag = StringToBooleanNil(page:GetValue("canDrag"))
		local isTrigger = StringToBooleanNil(page:GetValue("isTrigger"))

		EditModelProperty.result = {
			name = name,
			stackHeight = stackHeight,
			framemove_interval = framemove_interval,			dragDisplayOffsetY = dragDisplayOffsetY,
			idleAnim = idleAnim,
			animFrame = animFrame,
			hasRealPhysics = hasRealPhysics,
			isDisplayModel = page:GetValue("isDisplayModel"),
			enableDropFall = page:GetValue("enableDropFall"),
			isLocked = page:GetValue("isLocked"),
			opacity = page:GetValue("opacity"),
			color = page:GetValue("color"),
			bootHeight = page:GetValue("bootHeight"),
			autoTurning = autoTurning,
			isStackable = isStackable,
			canDrag = canDrag,
			isTrigger = isTrigger,
			onTriggerEnterEvent = page:GetValue("onTriggerEnterEvent"),
			onTriggerExitEvent = page:GetValue("onTriggerExitEvent"),
			onClickEvent = page:GetValue("onClickEvent"),
			onHoverEvent = page:GetValue("onHoverEvent"),
			onMountEvent = page:GetValue("onMountEvent"),
			onBeginDragEvent = page:GetValue("onBeginDragEvent"),
			onEndDragEvent = page:GetValue("onEndDragEvent"),
			onTickEvent = page:GetValue("onTickEvent"),
			modelfile = page:GetValue("modelfile"),
			tag = page:GetValue("tag"),
			staticTag = page:GetValue("staticTag"),
			category = category,
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
		page:SetValue("enableDropFall", values.enableDropFall);
		page:SetValue("isLocked", values.isLocked);
		page:SetValue("opacity", math.floor(values.opacity*100)/100);
		page:SetValue("color", tostring(values.color or ""));
		page:SetValue("bootHeight", values.bootHeight);
		page:SetValue("stackHeight", tostring(values.stackHeight));
		page:SetValue("framemove_interval", tostring(values.framemove_interval or ""));
		page:SetValue("dragDisplayOffsetY", tostring(values.dragDisplayOffsetY));		page:SetValue("idleAnim", tostring(values.idleAnim));
		page:SetValue("animFrame", tostring(values.animFrame or ""));
		page:SetValue("hasRealPhysics", tostring(values.hasRealPhysics));
		page:SetValue("autoTurning", tostring(values.autoTurning));
		page:SetValue("canDrag", tostring(values.canDrag));
		page:SetValue("isTrigger", values.isTrigger);
		page:SetValue("onTriggerEnterEvent", tostring(values.onTriggerEnterEvent or ""));
		page:SetValue("onTriggerExitEvent", tostring(values.onTriggerExitEvent or ""));
		page:SetValue("onClickEvent", tostring(values.onClickEvent or ""));
		page:SetValue("onHoverEvent", tostring(values.onHoverEvent or ""));
		page:SetValue("onMountEvent", tostring(values.onMountEvent or ""));
		page:SetValue("onBeginDragEvent", tostring(values.onBeginDragEvent or ""));
		page:SetValue("onEndDragEvent", tostring(values.onEndDragEvent or ""));
		page:SetValue("onTickEvent", tostring(values.onTickEvent or ""));
		page:SetValue("modelfile", tostring(values.modelfile or ""));
		page:SetValue("tag", tostring(values.tag or ""));
		page:SetValue("staticTag", tostring(values.staticTag or ""));
		page:SetValue("category", tostring(values.category or ""));
		EditModelProperty.mountpoints = values.mountpoints;
		page:CallMethod("mountpoints", "DataBind");
	end
end

function EditModelProperty.OnClose()
	if(page) then
		page:CloseWindow();
	end
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

function EditModelProperty.OnClickExpand()
	if not page then
		return
	end
	local morePoint = ParaUI.GetUIObject("EditModelProperty.mountpoints_container");
	if morePoint and morePoint:IsValid() then
		EditModelProperty.mountpoint_expanded = not EditModelProperty.mountpoint_expanded;
		morePoint.visible = EditModelProperty.mountpoint_expanded;
	end
end

function EditModelProperty.OnClickBuildinFunctions(name)
	name = name:gsub("More$", "")
	local oldValue = page:GetValue(name);
	local staticTag = page:GetValue("staticTag");
	local properties = commonlib.totable(staticTag)
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/API/ParaLifeAPISelector.lua");
	local ParaLifeAPISelector = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.ParaLifeAPISelector")
	ParaLifeAPISelector.ShowPage(true, name, function(value)
		if(page) then
			page:SetValue(name, value);
			-- apply properties to static tag. 
			local oldProperties = commonlib.totable(staticTag);
			if(not commonlib.compare(oldProperties, properties)) then
				local staticTag = commonlib.serialize_compact(properties)
				page:SetValue("staticTag", staticTag);
			end
		end
	end, oldValue, properties)
end

function EditModelProperty.GetModelAnimDs()
	local animIds = {}
	if not EditModelProperty.result or not EditModelProperty.result.modelfile then
		return animIds
	end
	local modelfile = EditModelProperty.result.modelfile
	modelfile = PlayerAssetFile:GetValidAssetByString(modelfile);
	if not modelfile then
		return animIds
	end
	local options = OpenAssetFileDialog.GetAnimIdsByFilename(modelfile);
	
	if(options) then
		for i, anim in ipairs(options) do
			animIds[i] = {value=anim.value.."",text=anim.text}
			if i==1 then
				animIds[i].selected = true
			end
		end
	end
	return animIds
end

function EditModelProperty.OnClickEmptyRuleSlot(slotNumber)
	local entity = EditModelProperty.GetEntity()
	if(entity) then
		local contView = entity.rulebagView;
		if(contView and slotNumber) then
			local slot = contView:GetSlot(slotNumber);
			entity:OnClickEmptySlot(slot);
		end
	end
end

function EditModelProperty.ShowStaticPhysicsPropertiesEditor()
	-- print("========================EditModelProperty.ShowStaticPhysicsPropertiesEditor=======================")
	local entity = EditModelProperty.GetEntity()
	if (not entity) then return end
	-- _G.IsDevEnv = true;
	-- NPL.load("script/ide/System/UI/TableEditor/TableEditor.lua", true);
	NPL.load("script/ide/System/UI/TableEditor/TableEditor.lua");
	local TableEditor = commonlib.gettable("System.UI.TableEditor.TableEditor");
	TableEditor:ShowLiveModelStaticPhysicsProperties(entity);
end

function EditModelProperty.OnChangeSkin()
	local entity = EditModelProperty.GetEntity()
	if(entity) then
		EditModelProperty.OnClose()
		NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/PlayerSkins.lua");
		local PlayerSkins = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerSkins")
		PlayerSkins:OpenEditor(entity, function(bSucceed, newSkin, oldSkin)
			if(bSucceed) then
				if(not GameLogic.IsVip()) then
					if(oldSkin) then
						entity:SetSkin(oldSkin);
						GameLogic.AddBBS(nil, L"只有VIP用户才可以更换皮肤。", 7000, "255 0 0");
					end
				end
			end
		end)
	end
end

function EditModelProperty.OnChooseColor()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SelectColor/SelectColor.lua");
	local SelectColor = commonlib.gettable("MyCompany.Aries.Game.Tasks.SelectColor");
	local task = SelectColor:new();
	task:ShowDialogPage(function(colorDWORD)
		if(colorDWORD) then
			local colorStr = Color.FromValueToStr(colorDWORD);
			page:SetValue("color", colorStr);
		end
	end);
end