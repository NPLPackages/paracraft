--[[
Title: Page Control test
Author(s): LiXizhi
Date: 2008/3/21
Desc: 
if one have a NPL file dedicated to a MCML file, one can create the NPL file like in this file. 
more information, please see script/kids/3DMapSystemApp/mcml/PageCtrl.lua
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/test/test_MyPageCtrl.lua");
test.MyPage.test_page();
-------------------------------------------------------
]]

NPL.load("(gl)script/kids/3DMapSystemApp/mcml/PageCtrl.lua");

-- create class
local MyPage = Map3DSystem.mcml.PageCtrl:new({url="script/kids/3DMapSystemApp/mcml/test/MyPageControl_UI.html"});
commonlib.setfield("test.MyPage", MyPage)
 
-- start the test
function MyPage.test_page(input)
	-- one can create a UI instance like this. 
	test.MyPage:Create("instanceName", nil, "_lt", 0, 0, 500, 350);
end

-- this function is overridable. it is called before page UI is about to be created. 
-- @param self.mcmlNode: the root pe:mcml node, one can modify it here before the UI is created, such as filling in default data. 
function MyPage:OnLoad()
	-- anything here applied to self.mcmlNode
end

-- this function is overridable. it is called after page UI is created. 
-- one can have direct access to UI object created in the control, such as modifying them. Note that some UI are lazy created 
-- such as treeview item and tab view items. They may not be available here. 
function MyPage:OnCreate()
	-- anything here applied to UI
end

-- One can also override the default refresh method to implement owner draw. 
-- in most cases one can remove this function
function MyPage:OnRefresh(_parent)
	Map3DSystem.mcml.PageCtrl.OnRefresh(self, _parent);
end
