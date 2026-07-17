--[[
Title: Select a model or character task
Author(s): pbb
Date: 2024/8/26
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EditModel/EditMountPointTask.lua");
local task = MyCompany.Aries.Game.Tasks.EditMountPointTask:new({manip = manip ,point = point})
task:Run();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/UndoManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityManager.lua");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local UndoManager = commonlib.gettable("MyCompany.Aries.Game.UndoManager");
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local EditMountPointTask = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.EditMountPointTask"));

local cur_instance;
local page;

function EditMountPointTask:ctor()
end


-- get current instance
function EditMountPointTask.GetInstance()
	return cur_instance;
end

function EditMountPointTask:FrameMove()
	--if(self.entity) then
		--if(self.entity.bx) then
			--ParaTerrain.SelectBlock(self.entity.bx, self.entity.by, self.entity.bz, true);
		--end
	--end
end

function EditMountPointTask:Run()
	if not self.manip or not self.point then
		return;
	end
	cur_instance = self;
	self.finished = false;
	self:ShowPage(true);
end	

-- @param bCommitChange: true to commit all changes made 
function EditMountPointTask:EndEditing(bCommitChange)
    local self = EditMountPointTask.GetInstance();
    if self then
        if self.manip then
            self.manip:UnselectAll();
        end
        self:OnExit()
    end
end

function EditMountPointTask:OnExit()
    self.manip = nil;
    self.point = nil;
    self:SetFinished();
	if(page) then
		page:CloseWindow();
		page = nil;
	end
    cur_instance = nil;
    page = nil;
end

function EditMountPointTask:UpdateManipulators(manip)
    local self = EditMountPointTask.GetInstance();
    if self then
        if manip and self.manip and self.manip ~= manip then
            self.manip = manip;
        end
    end
end

function EditMountPointTask:ShowPage(bShow)
	if(not page) then
		local width, height = 200, 300;
		local params = {
			url = "script/apps/Aries/Creator/Game/Tasks/EditModel/EditMountPointTask.html", 
			name = "EditMountPointTask.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			bToggleShowHide=false, 
			style = CommonCtrl.WindowFrame.ContainerStyle,
			enable_esc_key = false,
			allowDrag = true,
			click_through = false, 
			bShow = (bShow ~= false),
			directPosition = true,
			align = "_lt",
			x = 10,
			y = 120,
			width = width,
			height = height,
		};
		System.App.Commands.Call("File.MCMLWindowFrame", params);
		if(params._page) then
			params._page.OnClose = function()
				page = nil;
			end
		end
	else
		if(bShow == false) then
			page:CloseWindow();
		else
			page:Refresh(0.1);
		end
	end
	if(bShow and page) then
		page:SetValue("point_name", EditMountPointTask.GetPointName())
	end
end

function EditMountPointTask.OnInit(Page)
	page = Page
end

function EditMountPointTask.DoClick(name)
	local self = EditMountPointTask.GetInstance();
	if(name == "move")then
		self.DoMoveNode();
	elseif(name == "rot")then
		self.DoFacing();
	elseif(name == "remove")then
		self.DoRemove();
	elseif(name == "scale")then
		self.DoScaling();
    elseif(name == "ok")then
		self.DoPointChange();
    elseif(name == "cancel")then
		self:EndEditing()
	end
end

function EditMountPointTask.DoPointChange()
    local self = EditMountPointTask.GetInstance();
    if self then
        local name = page:GetValue("point_name");
        local pointName = self.point.name;
        if name ~= pointName then
			self.point.name = name;
            self:EndEditing(true)
        else
            self:EndEditing()
        end
    end
end

function EditMountPointTask.OnPointNameChange()
	if not page then return end
	-- update point name
	local name = page:GetValue("point_name");
	local self = EditMountPointTask.GetInstance();
	if self then
		self.point.name = name;
	end
end

function EditMountPointTask.GetPointName()
    local self = EditMountPointTask.GetInstance();
    if(self)then
        return self.point.name;
    end
end

-- translation
function EditMountPointTask.DoMoveNode()
	local self = EditMountPointTask.GetInstance();
	if(self)then
		self.manip:SetSelectedMountPoint(self.point,"trans");
	end
end

-- rotation
function EditMountPointTask.DoFacing()
	local self = EditMountPointTask.GetInstance();
	if(self)then
		self.manip:SetSelectedMountPoint(self.point,nil);
	end
end
-- scaling
function EditMountPointTask.DoScaling()
	local self = EditMountPointTask.GetInstance();
	if(self)then
		self.manip:SetSelectedMountPoint(self.point,"scale");
	end
end

-- remove
function EditMountPointTask.DoRemove()
	local self = EditMountPointTask.GetInstance();
	if(self and self.manip)then
        if self.manip:GetMountPoints() then
            self.manip:DeleteMountPoint(self.point)
            self:OnExit()
        end
	end
end

