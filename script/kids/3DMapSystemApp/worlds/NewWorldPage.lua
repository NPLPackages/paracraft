--[[
Title: New world page
Author(s): LiXizhi
Date: 2008/4/7
Desc: 
the new world wizard provides the user the world templates to choose from.
The templates comes in categories from local and online community.
Currently local categories containing: empty world, installed templates, popular templates
Online categories containing: offical categories defined on the PEDN wiki sites. 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/worlds/NewWorldPage.lua");
-------------------------------------------------------
]]

-- create class
local NewWorldPage = {};
commonlib.setfield("Map3DSystem.App.worlds.NewWorldPage", NewWorldPage)

-- when no world info page is provided, we will show this one. 
-- it takes worldpath as parameter like WorldInfoPage.html?worldpath=worlds/MyWorlds/abc
NewWorldPage.DefaultWorldInfoPage = "script/kids/3DMapSystemApp/worlds/WorldInfoPage.html"

-- show the default category page. 
function NewWorldPage.OnInit()
	local page = document:GetPageCtrl();
	local default_category = page:GetNodeValue("default_category");
	if(default_category) then
		page:SetNodeValue("TempListFrame", default_category);
	end
	local default_worldtemplate = page:GetNodeValue("default_worldtemplate");
	if(default_worldtemplate) then
		page:SetNodeValue("WorldInfoFrame", NewWorldPage.SetCurrentWorldTemplate(default_worldtemplate));
		page:SetNodeValue("templatename", default_worldtemplate);
	end	
end

-- Select a given template and show its world info page
function NewWorldPage.OnSelectTemplate(worldpath)
	local infopage = NewWorldPage.SetCurrentWorldTemplate(worldpath);
	
	-- navigate to info page. 
	if(document and infopage) then
		local page = document:GetPageCtrl();
		if(page) then
			local ctl = page:FindControl("WorldInfoFrame");
			if(not ctl) then
				-- search the parent of page. 
				page = page:GetParentPage();
				if(page) then
					ctl = page:FindControl("WorldInfoFrame");
				end
			end
			if(ctl) then
				ctl:Goto(infopage)
			end
			page:SetNodeValue("templatename", worldpath);
			local node = page:GetNode("parentworld");
			if(node) then	
				page:SetUIValue("parentworld", worldpath)
			end
		end
	end
end

-- private: set current world path
-- @return infopage: return the world info page url. if we will use the default worldinfopage if the template world does not provide one 
function NewWorldPage.SetCurrentWorldTemplate(worldpath)
	if(not worldpath) then return end
	local infopage = worldpath.."/WorldInfo.html";
	if(ParaIO.DoesFileExist(infopage, true)) then
	else
		-- if we will use the default worldinfopage if the template world does not provide one 
		infopage = System.localserver.UrlHelper.BuildURLQuery(NewWorldPage.DefaultWorldInfoPage, {worldpath=worldpath})
	end
	return infopage
end


-- User clicks simple create world button 
function NewWorldPage.OnCreateWorld(btnName, values)
	local page = document:GetPageCtrl();
	values.parentworld = values.parentworld or page:GetNodeValue("templatename");
	
	local worldpath, msg = NewWorldPage.CreateWorld(values); 
	page:SetUIValue("result", msg)
	if(worldpath) then
		page.RecentCreatedWorldPath = worldpath;
		
		-- set enter world button highlighted
		local btnEnterWorld = page:FindControl("EnterCreatedWorld");
		if(btnEnterWorld) then
			btnEnterWorld.enabled=true;
		end
	end
end
 
-- user clicks the advanced creation option. 
function NewWorldPage.OnCreateWorldAdvanced(btnName, values)
	local page = document:GetPageCtrl();
	local worldpath, msg = NewWorldPage.CreateWorld(values); 
	
	page:SetUIValue("result_adv", msg)
	if(worldpath) then
		page.RecentCreatedWorldPath = worldpath;
		
		-- set enter world button highlighted
		local btnEnterWorld = page:FindControl("EnterCreatedWorld");
		if(btnEnterWorld) then
			btnEnterWorld.enabled=true;
		end
	end
end

-- private: create world according to attributes in values input  
-- @param values: it is a table of {worldname or name, parentworld, creationfolder, inherit_scene, inherit_char, author, level, desc,}
-- @return: return worldpath, message. If not succeeded, worldpath is nil. 
function NewWorldPage.CreateWorld(values)
	local worldname = values.worldname or values.name
	local worldfolder = values.creationfolder or "worlds/MyWorlds/"
	local parentworld = values.parentworld;
	if(parentworld==nil or parentworld=="") then parentworld=nil end 
	local inherit_scene = values.inherit_scene
	if(inherit_scene == nil) then inherit_scene=true end
	local inherit_char = values.inherit_char
	if(inherit_char == nil) then inherit_char=true end
	
	if(worldname == nil or worldname=="") then
		return nil, "世界名字不能为空"
	elseif(worldname == "_emptyworld") then
		return nil, "您不能使用这个名字, 请换个名字"
	else
		local worldpath = commonlib.Encoding.Utf8ToDefault(worldfolder..worldname);-- append the world dir name
		parentworld = commonlib.Encoding.Utf8ToDefault(parentworld);

		-- create a new world
		local res = Map3DSystem.CreateWorld(worldpath, parentworld, inherit_char, inherit_scene);
		if(res == true) then
			-- load success UI
			return worldpath, string.format("世界创建成功:%s, 请点击进入世界", worldpath);
		elseif(type(res) == "string") then
			return nil, res
		end
	end
	return nil, "未知错误"
end

-- user clicks to enter a recently created world.
function NewWorldPage.OnEnterCreatedWorld()
	local page = document:GetPageCtrl();
	if(page.RecentCreatedWorldPath) then
		page:SetUIValue("result", "请稍候")
		
		-- call the load world command.
		Map3DSystem.App.Commands.Call(Map3DSystem.App.Commands.GetLoadWorldCommand(), {worldpath = page.RecentCreatedWorldPath});
	else
		page:SetUIValue("result","请先创建世界, 才能进入世界")
	end
end
