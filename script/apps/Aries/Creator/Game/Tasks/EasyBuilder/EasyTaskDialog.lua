--[[
Title: EasyBuilder Branch Task UI
Author(s): 
Date: 2025/12/15
Desc: Branch task dialog UI

Use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyTaskDialog.lua");
local EasyTaskDialog = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyTaskDialog");
EasyTaskDialog:ShowPage(GameLogic.EntityManager.GetPlayer())
EasyTaskDialog:CloseWindow()
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Core/SceneContextManager.lua")
local SceneContextManager = commonlib.gettable("System.Core.SceneContextManager")
local ObjEditor = commonlib.gettable("ObjEditor")
local EasyTaskDialog = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyTaskDialog"))

local page

function EasyTaskDialog.InitPage(Page)
	page = Page
	page.OnCreate = function()
		EasyTaskDialog.UpdateEntity()
	end
end

function EasyTaskDialog:ShowPage(targetEntity, taskData)
	 if EasyTaskDialog.targetEntity ~= targetEntity then
        -- disconnect previous copilot listener if any
        if EasyTaskDialog.targetEntity and EasyTaskDialog.targetEntity.copilot then
            EasyTaskDialog.targetEntity.copilot:Disconnect("taskChanged", EasyTaskDialog, EasyTaskDialog.OnCopilotTaskChanged);
        end
        -- disconnect previous beforeDestroyed listener if any
        if EasyTaskDialog.targetEntity then
            EasyTaskDialog.targetEntity:Disconnect("beforeDestroyed", EasyTaskDialog, EasyTaskDialog.OnEntityDestroyed);
        end
    end
	
	EasyTaskDialog.targetEntity = targetEntity
	local bShow = targetEntity ~= nil
    if(bShow) then
        commonlib.TimerManager.SetTimeout(function()
            SceneContextManager:Connect("mousePressed", EasyTaskDialog, EasyTaskDialog.OnSceneClicked, "UniqueConnection");
        end, 100);
    end

	EasyTaskDialog.taskData = taskData or {
		name = "任务名",
		description = "任务描述",
	}
     if targetEntity and targetEntity.copilot then
        targetEntity.copilot:Connect("taskChanged", EasyTaskDialog, EasyTaskDialog.OnCopilotTaskChanged, "UniqueConnection");
    end
    -- connect to beforeDestroyed signal to close page when entity is destroyed
    if targetEntity then
        targetEntity:Connect("beforeDestroyed", EasyTaskDialog, EasyTaskDialog.OnEntityDestroyed, "UniqueConnection");
    end
	if not page then
		local width, height = 400, 240
		local params = {
			url = "script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyTaskDialog.html",
			name = "EasyTaskDialog.ShowPage",
			isShowTitleBar = false,
			DestroyOnClose = true,
			bToggleShowHide = false,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			enable_esc_key = true,
			allowDrag = true,
			click_through = false,
			zorder = 1,
			directPosition = true,
			align = "_ctb",
			x = 0,
			y = 0,
			width = width,
			height = height,
		}
		System.App.Commands.Call("File.MCMLWindowFrame", params)
		if(params._page) then
			params._page.OnClose = function()
				-- disconnect copilot listener if any
				local ent = EasyTaskDialog.targetEntity
				if ent and ent.copilot then
					ent.copilot:Disconnect("taskChanged", EasyTaskDialog, EasyTaskDialog.OnCopilotTaskChanged);
				end

				-- disconnect beforeDestroyed listener if any
				if ent then
					ent:Disconnect("beforeDestroyed", EasyTaskDialog, EasyTaskDialog.OnEntityDestroyed);
				end

				EasyTaskDialog.targetEntity = nil
				page = nil;
				SceneContextManager:Disconnect("mousePressed", EasyTaskDialog, EasyTaskDialog.OnSceneClicked);
			end
		end
	else
        if(bShow == false) then
            page:CloseWindow();
        else
            page:Refresh(0.1);
        end
    end
end

function EasyTaskDialog:CloseWindow()
    if(page) then
        page:CloseWindow();
    end
end

function EasyTaskDialog:OnSceneClicked(event)
    SceneContextManager:Disconnect("mousePressed", EasyTaskDialog, EasyTaskDialog.OnSceneClicked);
    EasyTaskDialog.OnClickClose()
end

-- Handler for entity beforeDestroyed signal. Closes the window when entity is destroyed.
function EasyTaskDialog:OnEntityDestroyed()
    EasyTaskDialog.OnClickClose()
end

function EasyTaskDialog:RefreshPage()
    if(page) then
        page:Refresh(0.01);
    end
end

-- Handler for copilot taskChanged signal. Invalidates cache and refreshes UI.
function EasyTaskDialog:OnCopilotTaskChanged(task, eventType)
	if eventType == "started" then
		EasyTaskDialog.OnClickClose()
	else
		if page then
			page:Refresh(0.01)
		end
	end
end

function EasyTaskDialog.OnClickClose()
	if page then
		page:CloseWindow()
		page = nil
	end
end

function EasyTaskDialog.GetRunningTaskInstance()
	if not EasyTaskDialog.targetEntity or not EasyTaskDialog.targetEntity.copilot then return end
	local taskData = EasyTaskDialog.taskData
	if not taskData then return end
	
	-- If taskData has an ID, look it up in the copilot
	if taskData.id then
		 local task = EasyTaskDialog.targetEntity.copilot:GetTask(taskData.id)
		 -- The task returned by GetTask is a wrapper {id, name, taskInstance, ...}
		 if task and task.taskInstance then
			 return task.taskInstance
		 end
	end
	return nil
end

function EasyTaskDialog.GetRunningTaskInfo()
	if not EasyTaskDialog.targetEntity or not EasyTaskDialog.targetEntity.copilot then return end
	local taskData = EasyTaskDialog.taskData
	if not taskData then return end
	
	-- If taskData has an ID, look it up in the copilot
	if taskData.id then
		 local task = EasyTaskDialog.targetEntity.copilot:GetTask(taskData.id)
		 -- The task returned by GetTask is a wrapper {id, name, taskInstance, ...}
		 if task and task.taskInstance then
			 return task.taskInstance:GetStatus()
		 end
	end
	return nil
end

function EasyTaskDialog.IsRunning()
	local info = EasyTaskDialog.GetRunningTaskInfo()
	return info and info.isRunning
end

function EasyTaskDialog.IsPaused()
	local info = EasyTaskDialog.GetRunningTaskInfo()
	return info and info.isPaused
end

function EasyTaskDialog.IsAccepted()
	local info = EasyTaskDialog.GetRunningTaskInfo()
	return info and info.isAccepted
end

function EasyTaskDialog.OnClickPause()
	if EasyTaskDialog.IsRunning() then
		--  EasyTaskDialog.targetEntity.copilot:PauseRunningTask()
		local taskInstance = EasyTaskDialog.GetRunningTaskInstance()
		 if taskInstance and type(taskInstance.OnClickActionButton) == "function" then
           taskInstance:OnClickActionButton("pause")
        end
	end
end

function EasyTaskDialog.OnClickResume()
	if EasyTaskDialog.IsPaused() then
		--  EasyTaskDialog.targetEntity.copilot:ResumeRunningTask()
		local taskInstance = EasyTaskDialog.GetRunningTaskInstance()
		if taskInstance and type(taskInstance.OnClickActionButton) == "function" then
           taskInstance:OnClickActionButton("resume")
        end
	end
end

function EasyTaskDialog.OnClickStop()
	if EasyTaskDialog.targetEntity and EasyTaskDialog.targetEntity.copilot then
		-- EasyTaskDialog.targetEntity.copilot:StopRunningTask()
		local taskInstance = EasyTaskDialog.GetRunningTaskInstance()
		if taskInstance and type(taskInstance.OnClickActionButton) == "function" then
           taskInstance:OnClickActionButton("stop")
        end
	end
	EasyTaskDialog.OnClickClose()
end

function EasyTaskDialog.OnClickStart()
	-- EasyTaskDialog.OnClickClose() -- Keep open to show running status? Or let user decide? 
	-- If we keep it open, we can show "Running" state.
	-- Let's check if the user wants it to close.
	-- The original code closed it. But if we want to show "Running", maybe we should keep it open?
	-- Let's keep it open for now, as that's usually better for "Control" dialogs.
	
	if EasyTaskDialog.taskData and EasyTaskDialog.taskData.onStart then
		EasyTaskDialog.taskData.onStart()
	end
	EasyTaskDialog.OnClickClose()
end

function EasyTaskDialog.OnClickCancel()
	EasyTaskDialog.OnClickClose()
	if EasyTaskDialog.taskData and EasyTaskDialog.taskData.onCancel then
		EasyTaskDialog.taskData.onCancel()
	end
end

function EasyTaskDialog.GetEntityParams()
	local entity = EasyTaskDialog.targetEntity
	if entity and entity.GetInnerObject then
		local obj = entity:GetInnerObject()
		if obj then
			local params = ObjEditor.GetObjectParams(obj)
			if params.IsCharacter then
				if obj:GetNumReplaceableTextures() > 0 then
					params.ReplaceableTextures = params.ReplaceableTextures or {}
					for i = 1, obj:GetNumReplaceableTextures() do
						local tex = obj:GetReplaceableTexture(i - 1)
						if tex and tex:IsValid() then
							params.ReplaceableTextures[i] = tex:GetFileName()
						end
					end
				end
				params.scaling = 0.5
				params.CustomGeosets = entity:GetSkin()
			end
			return params
		end
	end
	return "character/CC/02human/CustomGeoset/actor.x"
end

function EasyTaskDialog.UpdateEntity()
	if not page then
		return
	end
	local ctlName = "canvas3d_copilot_role"
	local module_ctl = page:FindControl(ctlName)
	if not module_ctl then
		return
	end
	local scene = ParaScene.GetMiniSceneGraph(module_ctl.resourceName);
	if scene and scene:IsValid() then
		local player = scene:GetObject(module_ctl.obj_name);
		if player then
			player:SetFacing(2.8);
			player:SetField("HeadUpdownAngle", 0.2);
			player:SetField("HeadTurningAngle", 0);
			
		end
	end
end

function EasyTaskDialog.GetTaskName()
	return EasyTaskDialog.taskData and EasyTaskDialog.taskData.name or ""
end

function EasyTaskDialog.GetTaskDescription()
	return EasyTaskDialog.taskData and EasyTaskDialog.taskData.description or ""
end
