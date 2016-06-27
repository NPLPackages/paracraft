--[[
Title: 
Author(s): Leio
Date: 2010/01/23
Desc:  script/apps/Aries/Creator/Pages/OpenWorldPage.html
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Pages/OpenWorldPage.lua");
MyCompany.Aries.Creator.OpenWorldPage.ShowPage()
-------------------------------------------------------
]]
local OpenWorldPage = {
	state = 0,--0 or 1,0 is world template,1 is my world
	selected_index = nil,
	worlds_template = {
		{name = "官方世界", world_path = "",icon = "",},
		{name = "官方世界", world_path = "",icon = "",},
		{name = "官方世界", world_path = "",icon = "",},
		{name = "官方世界", world_path = "",icon = "",},
		{name = "官方世界", world_path = "",icon = "",},
		{name = "官方世界", world_path = "",icon = "",},
		{name = "官方世界", world_path = "",icon = "",},
		{name = "官方世界", world_path = "",icon = "",},
		{name = "官方世界", world_path = "",icon = "",},
		{name = "官方世界", world_path = "",icon = "",},
		{name = "官方世界", world_path = "",icon = "",},
		{name = "官方世界", world_path = "",icon = "",},
	},
	my_worlds = {
		{name = "我的世界", world_path = "",icon = "",},
		{name = "我的世界", world_path = "",icon = "",},
		{name = "我的世界", world_path = "",icon = "",},
		{name = "我的世界", world_path = "",icon = "",},
		{name = "我的世界", world_path = "",icon = "",},
		{name = "我的世界", world_path = "",icon = "",},
		{name = "我的世界", world_path = "",icon = "",},
		{name = "我的世界", world_path = "",icon = "",},
		{name = "我的世界", world_path = "",icon = "",},
		{name = "我的世界", world_path = "",icon = "",},
		{name = "我的世界", world_path = "",icon = "",},
		{name = "我的世界", world_path = "",icon = "",},
		{name = "我的世界", world_path = "",icon = "",},
	},
};
commonlib.setfield("MyCompany.Aries.Creator.OpenWorldPage", OpenWorldPage);

function OpenWorldPage.DS_Func_World_Template(index)
	local self = OpenWorldPage;
	if(not self.worlds_template)then return 0 end
	if(index == nil) then
		return #(self.worlds_template);
	else
		return self.worlds_template[index];
	end
end
function OpenWorldPage.DS_Func_MyWorlds(index)
	local self = OpenWorldPage;
	if(not self.my_worlds)then return 0 end
	if(index == nil) then
		return #(self.my_worlds);
	else
		return self.my_worlds[index];
	end
end
function OpenWorldPage.OnInit()
	local self = OpenWorldPage;
	self.page = document:GetPageCtrl();
end
function OpenWorldPage.ShowPage()
	local self = OpenWorldPage;
	System.App.Commands.Call("File.MCMLWindowFrame", {
			url = "script/apps/Aries/Creator/Pages/OpenWorldPage.html", 
			name = "OpenWorldPage.ShowPage", 
			--app_key=MyCompany.Aries.app.app_key, 
			app_key=MyCompany.Taurus.app.app_key, 
			isShowTitleBar = false,
			DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
			style = CommonCtrl.WindowFrame.ContainerStyle,
			zorder = 1,
			allowDrag = false,
			directPosition = true,
				align = "_ct",
				x = -400,
				y = -300,
				width = 800,
				height = 600,
		});
end
function OpenWorldPage.ClosePage()
	local self = OpenWorldPage;
	Map3DSystem.App.Commands.Call("File.MCMLWindowFrame", {name="OpenWorldPage.ShowPage", 
			app_key=MyCompany.Taurus.app.app_key, 
			bShow = false,bDestroy = true,});
end
function OpenWorldPage.ChangeState(sName)
	local self = OpenWorldPage;
	if(sName == "template_world")then
		self.state = 0;
	else
		self.state = 1;
	end
	self.selected_index = nil;
	if(self.page)then
		self.page:Refresh(0);
	end
end
function OpenWorldPage.DoCreate()
	local self = OpenWorldPage;
	local item = self.GetItem();
	if(not item)then
		_guihelper.MessageBox("空");
		return
	end
	_guihelper.MessageBox(commonlib.serialize(item));
end
function OpenWorldPage.DoOpen()
	local self = OpenWorldPage;
	local item = self.GetItem();
	if(not item)then
		_guihelper.MessageBox("空");
		return
	end
	--_guihelper.MessageBox(commonlib.serialize(item));
	NPL.load("(gl)script/apps/Aries/Creator/CreatorCanvas.lua");
	local canvas = MyCompany.Aries.Creator.CreatorCanvas:new();
	canvas:BuildNodes();
	self.ClosePage();
end
function OpenWorldPage.OnSelected(index)
	local self = OpenWorldPage;
	self.selected_index = tonumber(index);
end
function OpenWorldPage.GetItem()
	local self = OpenWorldPage;
	if(self.selected_index)then
		local list;
		if(self.state == 0)then
			list = self.worlds_template;
		else
			list = self.my_worlds;
		end
		if(list)then
			return list[self.selected_index];
		end
	end
end
