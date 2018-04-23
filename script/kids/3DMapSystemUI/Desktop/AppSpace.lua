--[[
Title: Application space in Map3DSystem user interface
Author(s): WangTian
Date: 2008/6/3
Desc: A lot of applications are shown on the screen. Application space is a mechanism to pile up windows. Application space is to group 
	the application windows and banish clutter completely. It also gives the user an easy way to switch between spaces.
	
	Each application can create its own space, such as CCS and Creator. Organize each space just the way each application wants it.
	Application have a whole screen to decorated the windows, panels, even an inside dock.
	
	Generally each space contains at least one windowframe object. Application can register an application space at UI setup, switching or execute.
	It can also add and remove window frame object into the space on the fly. One window frame can belongs and only belongs to one space. 
	But there is one exception -- the pinned window. The pinned window is useful especially for chat window and chat channels. Those windows are 
	not sensitive to application switching. They stay on the screen perminently, in window frame or minimized tab.
	
	Space is organized in grid form, so the whole "Space" is like a tiled display. And only one application space is focused in the user screen.
	Basicly application switching is like moving the camera from one screen to another. We also provide a thumb view to give the user a better visual clue.
	Each thumb represents one application space, and delivers an overall idea of which is my current focus, where are the other spaces.
	
	In thumb view, spaces can also be swapped between each other by dragging one thumb over the other. The user can better acquaint with 
	the overall decoration. It's easy to organize and reorganize.
	
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemUI/Desktop/AppSpace.lua");
------------------------------------------------------------
]]



local libName = "AppSpace";
local libVersion = "1.0";

local AppSpace = commonlib.LibStub:NewLibrary(libName, libVersion)
Map3DSystem.UI.AppSpace = AppSpace;

local sampleParam = {
	name = "Blablabla", --  application space name
	};

-- all spaces
AppSpace.spaces = {};

-- create an application space
-- Application can register an application space at UI setup, switching or execute.
-- @param o: parameter to define the application space
function AppSpace:new(space)
	local i, v;
	for i, v in ipairs(AppSpace.spaces) do
		if(space.name == v.name) then
			log("Error: create application space that already exists, check space name param.\n");
			return;
		end
	end
	
	local nCount = table.getn(AppSpace.spaces);
	AppSpace.spaces[nCount + 1] = space;
	
	AppSpace.UpdateRowsAndColumns();
	
	space.frames = {}; --  set of hosting WindowFrame object
	
	setmetatable(space, self);
	self.__index = self;
	return space;
end

-- destroy the application space
-- this function will set all inner windowframe objects to its application's application space according to the app_key
function AppSpace:destroy()
	local index;
	local i, v;
	for i, v in ipairs(AppSpace.spaces) do
		if(self.name == v.name) then
			index = i;
		end
	end
	if(index ~= nil) then
		-- TODO: set all inner windowframe objects to its application's application space according to the app_key
		table.remove(AppSpace.spaces, i);
		
		AppSpace.UpdateRowsAndColumns()
	else
		log("Error: application space not found on destroy()");
	end
end

-- clear all spaces
-- this function is often used when leaving world, before UI objects are reset
function AppSpace:clearall()
	AppSpace.spaces = {};
end

-- register a window frame to the application space
-- @param frame: WindowFrame object
function AppSpace:RegisterWindow(frame)
	if(frame ~= nil) then
		local appName = frame.wnd.app.name;
		local wndName = frame.wnd.name;
		
		-- NOTE: By xizhi space concept allow window frame assigned to different AppSpace
		--if(AppSpace.GetHostAppSpace(frame) ~= nil) then
			--log(string.format("Error: WindowFrame object:@q already assigned to AppSpace object:@q\n", 
				--wndName.."@"..appName, AppSpace.GetHostAppSpace(frame).name));
			--return;
		--end
		
		table.insert(self.frames, {appName = appName, wndName = wndName});
	end
end

-- unregister a window frame from the application space
-- @param frame: WindowFrame object
function AppSpace:UnregisterWindow(frame)
	if(frame ~= nil) then
		local appName = frame.wnd.app.name;
		local wndName = frame.wnd.name;
		
		local i, frame;
		for i, frame in ipairs(self.frames) do
			if(frame.appName == appName and frame.wndName == wndName) then
				table.remove(self.frames, i);
				return;
			end
		end
	end
end

-- get the index in the AppSpace.spaces table
-- @return index
function AppSpace:GetIndex()
	local i, space;
	for i, space in ipairs(AppSpace.spaces) do
		if(self.name == space.name) then
			return i;
		end
	end
end

-- NOTE: the spaces are organized in width-first grid form, that is columns is equal to rows or rows + 1, e.x.
--	5 spaces:
--		1 2 3
--		4 5
--	7 spaces:
--		1 2 3
--		4 5 6
--		7
-- get the row and column of the application space
-- @return row, column
function AppSpace:GetRowAndColumn()
	AppSpace.UpdateRowsAndColumns();
	local index = self:GetIndex();
	local row = math.ceil(index / AppSpace.columns);
	local column = index - (row - 1) * columns;
	
	return row, column;
end

-- change the focus of the application space from one to another
-- NOTE: initially the application space focus to no one, we assume the screen focus on the left top corner space(#1)
-- @param space: destination AppSpace
function AppSpace.ChangeFocus(space)
	if(space == nil or space.name == nil) then
		log("Error: AppSpace.ChangeFocus(space) parameter AppSpace object expected, got nil\n");
		return;
	end
	
	if(table.getn(AppSpace.spaces) < 1) then
		log("Error: AppSpace.ChangeFocus(space) no space avaible for changing\n");
		return;
	end
	
	if(AppSpace.isSwitching == true) then
		log("Error: AppSpace.ChangeFocus(space) is not avaiable because we currently don't support merge between application switching\n");
		return;
	end
	
	AppSpace.CurrentFocusSpaceIndex = AppSpace.CurrentFocusSpaceIndex or 1;
	
	if(space:GetIndex() == AppSpace.CurrentFocusSpaceIndex) then
		log("Warning: AppSpace.ChangeFocus(space) destination AppSpace is the same as the current AppSpace\n");
		return;
	end
	
	AppSpace.ChangeFocusBegin(space:GetIndex());
	
	local i, space;
	for i, space in ipairs(AppSpace.spaces) do
		AppSpace.ChangeFocusSpace(space)
	end
	-- TODO: this function is usually called when the switching animaition is complete
	--AppSpace.ChangeFocusEnd();
end

--------------------------------------------------------------------------------------------
-- every change focus operation leads to a ChangeFocusBegin and ChangeFocusEnd
-- between the function call pair it will change each AppSpace in the spaces list
-- also note that bewteen these function calls, AppSpace.ChangeFocus(space) function 
-- is not avaiable because we currently don't support merge between application switching.
-- 
function AppSpace.ChangeFocusBegin(destIndex)
	AppSpace.isSwitching = true;
	AppSpace.fromIndex = AppSpace.CurrentFocusSpaceIndex;
	AppSpace.toIndex = destIndex;
	AppSpace.fromRow, AppSpace.fromColumn = AppSpace.spaces[AppSpace.CurrentFocusSpaceIndex]:GetRowAndColumn();
	AppSpace.toRow, AppSpace.toColumn = AppSpace.spaces[destIndex]:GetRowAndColumn();
	
end
-- change the focus of a single space
function AppSpace.ChangeFocusSpace(space)
	local row, column = space:GetRowAndColumn();
	
	
	NPL.load("(gl)script/kids/3DMapSystemUI/UICommon.lua");
	local _, _, resWidth, resHeight = ParaUI.GetUIObject("root"):GetAbsPosition();
	
	---- frame 0:
	--(row - AppSpace.fromRow) * (resHeight + 64)
	--(column - AppSpace.fromColumn) * (resWidth + 64)
	--
	---- frame 100:
	--(AppSpace.toRow - row) * (resHeight + 64)
	--(AppSpace.toColumn - column) * (resWidth + 64)
	
	-- NOTE: application space switching halted
end
-- this function is usually called when the switching animaition is complete
function AppSpace.ChangeFocusEnd()
	AppSpace.isSwitching = false;
	AppSpace.fromIndex = nil;
	AppSpace.toIndex = nil;
	AppSpace.fromRow, AppSpace.fromColumn = nil, nil;
	AppSpace.toRow, AppSpace.toColumn = nil, nil;
end
--------------------------------------------------------------------------------------------


-- NOTE: the spaces are organized in width-first grid form, that is columns is equal to rows or rows + 1, e.x.
--	5 spaces:
--		1 2 3
--		4 5
--	7 spaces:
--		1 2 3
--		4 5 6
--		7
-- update the rows and columns of the spaces
--
-- NOTE: this function is usually called on AppSpace change such as new() and destory()
function AppSpace.UpdateRowsAndColumns()
	local nCount = table.getn(AppSpace.spaces);
	if(table.getn(AppSpace.spaces) == 0) then
		AppSpace.rows = 0;
		AppSpace.columns = 0;
	else
		local columns = 1;
		while(n > (columns * columns)) do
			columns = columns + 1;
		end
		local rows = math.ceil(n / columns);
		AppSpace.rows = rows;
		AppSpace.columns = columns;
	end
end

-- get the application space that hosts the window frame
-- @param frame: WindowFrame object
-- @return: the AppSpace object or nil on not found
function AppSpace.GetHostAppSpace(frame)
	if(frame ~= nil) then
		local appName = frame.wnd.app.name;
		local wndName = frame.wnd.name;
		
		local i, space;
		for i, space in ipairs(AppSpace.spaces) do
			local j, frame;
			for j, frame in ipairs(space.frames) do
				if(frame.appName == appName and frame.wndName == wndName) then
					return space;
				end
			end
		end
	end
end

-------------------------------------------------------------------------
------------------ functions added after xizhi concept ------------------

-- show all window frames inside the AppSpace
function AppSpace:ShowAllWindowFrames()
	local i, frame;
	for i, frame in ipairs(self.frames) do
		frame:Show(true);
	end
end