--[[
Title: For files from blue tooth. 
Author(s): LiXizhi
Date: 2013/1/26
Desc: Drag and drop *.block.xml block template file to game to create blocks where it is. 
when the file changes, the block is automatically updated. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BlockFileMonitorTask.lua");
local task = MyCompany.Aries.Game.Tasks.BlockFileMonitor:new({filename="worlds/DesignHouse/blockdisk/box.blocks.xml", cx=nil, cy=nil, cz = nil })
task:Run();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Assets/AssetsCommon.lua");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local BlockFileMonitor = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.BlockFileMonitor"));

-- this is always a top level task. 
BlockFileMonitor.is_top_level = true;

local cur_instance;

function BlockFileMonitor:ctor()
end

function BlockFileMonitor.RegisterHooks()
	local self = cur_instance;
	self:LoadSceneContext();
end

function BlockFileMonitor.UnregisterHooks()
	local self = cur_instance;
	if(self) then
		self:UnloadSceneContext();
	end
end

function BlockFileMonitor:Run()
	if(not TaskManager.AddTask(self)) then
		-- ignore the task if there is other top-level tasks.
		return;
	end

	cur_instance = self;
	
	if(not self.filename or not ParaIO.DoesFileExist(self.filename)) then
		return
	end

	local bx, by, bz = EntityManager.GetPlayer():GetBlockPos();
	self.cx = self.cx or bx;
	self.cy = self.cy or by;
	self.cz = self.cz or bz;
	

	BlockFileMonitor.mytimer = commonlib.Timer:new({callbackFunc = function(timer)
		BlockFileMonitor.OnUpdateBlocks();
	end})
	BlockFileMonitor.mytimer:Change(0, 200);

	BlockFileMonitor.finished = false;
	BlockFileMonitor.RegisterHooks();
	BlockFileMonitor.ShowPage();
end

function BlockFileMonitor:OnExit()
	BlockFileMonitor.EndEditing();
end


-- @param bCommitChange: true to commit all changes made 
function BlockFileMonitor.EndEditing(bCommitChange)
	BlockFileMonitor.finished = true;
	BlockFileMonitor.ClosePage()
	BlockFileMonitor.UnregisterHooks();
	if(cur_instance) then
		local self = cur_instance;
		cur_instance = nil
	end
	if(BlockFileMonitor.mytimer) then
		BlockFileMonitor.mytimer:Change();
		BlockFileMonitor.mytimer = nil;
	end
end

function BlockFileMonitor:mousePressEvent(event)
end

function BlockFileMonitor:mouseMoveEvent(event)
end

function BlockFileMonitor:mouseReleaseEvent(event)
end

function BlockFileMonitor:keyPressEvent(event)
	local dik_key = event.keyname;

	if(dik_key == "DIK_ESCAPE")then
		-- exit editing mode without commit any changes. 
		BlockFileMonitor.EndEditing(false);
	elseif(dik_key == "DIK_DELETE" or dik_key == "DIK_DECIMAL")then
		BlockFileMonitor.DeleteAll()
	end	
end

function BlockFileMonitor:FrameMove()
end

------------------------
-- page function 
------------------------
local page;
function BlockFileMonitor.ShowPage()
	System.App.Commands.Call("File.MCMLWindowFrame", {
			url = "script/apps/Aries/Creator/Game/Tasks/BlockFileMonitorTask.html", 
			name = "BlockFileMonitorTask.ShowPage", 
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			isShowTitleBar = false, 
			DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
			style = CommonCtrl.WindowFrame.ContainerStyle,
			zorder = 1,
			allowDrag = false,
			click_through = true,
			directPosition = true,
				align = "_lt",
				x = 0,
				y = 80,
				width = 128,
				height = 512,
		});
	MyCompany.Aries.Creator.ToolTipsPage.ShowPage(false);
end

function BlockFileMonitor.ClosePage()
	if(page) then
		page:CloseWindow();
	end
end

function BlockFileMonitor.OnInit()
	page = document:GetPageCtrl();
end

function BlockFileMonitor.RefreshPage()
	if(page) then
		page:Refresh(0.01);
	end
end

function BlockFileMonitor.DoClick(name)
	local self = cur_instance;
	if(not self) then
		return
	end 

	if(name == "camera_up") then
		self.dy = 1;
		BlockFileMonitor.OnUpdateBlocks()
	elseif(name == "camera_down") then
		self.dy = -1;
		BlockFileMonitor.OnUpdateBlocks()
	elseif(name == "delete") then
		BlockFileMonitor.DeleteAll()
	elseif(name == "save_template") then
		if(self.blocks) then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/BlockTemplatePage.lua");
			local BlockTemplatePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.BlockTemplatePage");
			BlockTemplatePage.ShowPage(true, self.blocks);
		end
	end
end

function BlockFileMonitor.DeleteAll()
	local self = cur_instance;
	if(not self) then
		return
	end 

	self.filename = nil;

	local cx, cy, cz = self.cx, self.cy, self.cz;
	local blocks = self.blocks or {};
	local _, b;
	for _, b in ipairs(blocks) do
		if(b[1]) then
			local x, y, z = cx+b[1], cy+b[2], cz+b[3];
			BlockEngine:SetBlock(x,y,z, 0);
		end
	end
	BlockFileMonitor.EndEditing();
end

function BlockFileMonitor.OnUpdateBlocks()
	local self = cur_instance;
	if(not self) then
		return
	end 
	
	--[[ TODO: detect file change
	local sInitDir = self.filename:gsub("([^/\\]+)$", "");
	sInitDir = sInitDir:gsub("\\", "/");
	local filename = self.filename:match("([^/\\]+)$");
	
	if(not filename) then
		return;
	end

	local search_result = ParaIO.SearchFiles(sInitDir,filename, "", 0, 1, 0);
	local nCount = search_result:GetNumOfResult();		
	local i;
	if(nCount>=1)  then
		local item = search_result:GetItemData(0, {});
		local date = item.writedate;
	end
	]]

	local xmlRoot = ParaXML.LuaXML_ParseFile(self.filename);
	if(xmlRoot) then
		local node = commonlib.XPath.selectNode(xmlRoot, "/pe:blocktemplate/pe:blocks");
		if(node and node[1]) then
			local blocks = NPL.LoadTableFromString(node[1]);
			if(blocks and #blocks > 0) then
				self.cy = self.cy + (self.dy or 0);
				local cx, cy, cz = self.cx, self.cy, self.cz;
				local last_blocks = self.blocks or {};
				
				blocks.map = {};
				last_blocks.map = last_blocks.map or {};
				local _, b
				for _, b in ipairs(blocks) do
					if(b[1]) then
						local x, y, z = cx+b[1], cy+b[2], cz+b[3];
						local sparse_index =x*30000*30000+y*30000+z;
						local new_id = b[4] or 96;
						blocks.map[sparse_index] = new_id;

						if(last_blocks.map[sparse_index] ~= new_id) then
							BlockEngine:SetBlock(x,y,z, new_id, b[5], nil, b[6]);
						end
					end
				end
				
				if(self.dy) then
					cy = cy - self.dy;
					self.dy = nil;
				end
				for _, b in ipairs(last_blocks) do
					if(b[1]) then
						local x, y, z = cx+b[1], cy+b[2], cz+b[3];
						local sparse_index =x*30000*30000+y*30000+z;
						if(not blocks.map[sparse_index]) then
							BlockEngine:SetBlock(x,y,z, 0);
						end
					end
				end

				self.blocks = blocks;
				if(#blocks~=self.block_count) then
					self.block_count = #blocks;
					if(page) then
						page:SetValue("blockcount", self.block_count);
					end
				end
			end
		end
	end

end
