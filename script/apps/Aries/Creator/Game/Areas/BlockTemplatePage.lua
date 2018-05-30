--[[
Title: The dock page
Author(s): LiXizhi
Date: 2012/12/28
Desc:  
There dock has 2 mode: one for editor and one for creator
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/BlockTemplatePage.lua");
local BlockTemplatePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.BlockTemplatePage");
BlockTemplatePage.ShowPage(true, blocks)
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/LuaXML.lua");
NPL.load("(gl)script/ide/XPath.lua");
NPL.load("(gl)script/kids/3DMapSystemUI/ScreenShot/SnapshotPage.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BuildQuestProvider.lua");
local BuildQuestProvider =  commonlib.gettable("MyCompany.Aries.Game.Tasks.BuildQuestProvider");
local Desktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local block = commonlib.gettable("MyCompany.Aries.Game.block")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")

local BlockTemplatePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.BlockTemplatePage");

BlockTemplatePage.DefaultSnapShot = "Screen Shots/block_template.jpg";

-- max number blocks in a template. 
BlockTemplatePage.max_blocks_per_template = 5000000;

BlockTemplatePage.global_template_dir = "worlds/DesignHouse/blocktemplates/"

local default_template_dir = "worlds/DesignHouse/blocktemplates/";

-- this be used in paracraft 
BlockTemplatePage.isSaveInLocalWorld = false;

local page;
function BlockTemplatePage.OnInit()
	page = document:GetPageCtrl();
	page:SetNodeValue("CurrentSnapshot", BlockTemplatePage.DefaultSnapShot);

	if(BlockTemplatePage.blocks) then
		page:SetNodeValue("statsButton", format("%d", #(BlockTemplatePage.blocks)));
		--if(System.options.mc) then
			--page:SetNodeValue("statsButton", format("%d", #(BlockTemplatePage.blocks)));
		--else
			--page:SetNodeValue("statsButton", format("模板使用了%d个积木", #(BlockTemplatePage.blocks)));
		--end
	end
	BlockTemplatePage.isSaveInBuildingTask = false;
end

-- @param blocks: array of {x,y,z,block_id}
function BlockTemplatePage.ShowPage(bShow, blocks, pivot)
	BlockTemplatePage.pivot = pivot;
	if(bShow) then
		BlockTemplatePage.OnClickTakeSnapshot();
		BlockTemplatePage.blocks = blocks;
	end
	--local width = 400;
	--local height = 250;
	--if(System.options.mc) then
		--width = 210;
		--height = 290;
	--end

	width = 420;
	height = 400;

	System.App.Commands.Call("File.MCMLWindowFrame", {
			url = "script/apps/Aries/Creator/Game/Areas/BlockTemplatePage.html", 
			name = "BlockTemplatePage.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			bShow = bShow,
			directPosition = true,
				align = "_ct",
				x = -width/2,
				y = -height/2,
				width = width,
				height = height,
		});
end

function BlockTemplatePage.OnClickTakeSnapshot()
	NPL.load("(gl)script/kids/3DMapSystemUI/ScreenShot/SnapshotPage.lua");
	if(MyCompany.Apps.ScreenShot.SnapshotPage.TakeSnapshot(BlockTemplatePage.DefaultSnapShot, 64, 64, false, false)) then
		-- refresh image
		ParaAsset.LoadTexture("", BlockTemplatePage.DefaultSnapShot,1):UnloadAsset();
	else
		_guihelper.MessageBox(L"截图失败了, 请确定您有权限读写磁盘")
	end
end

function BlockTemplatePage.CreateBuildingTaskFile(filename, blocksfilename, taskname, _blocks, desc)
	local blocks = _blocks;
	local file = ParaIO.open(filename, "w");
	if(file:IsValid()) then
		
		local o = {name="Task", attr = {name = taskname, click_once_deploy="true", icon = "", image = "", desc = desc or taskname, UseAbsolutePos = "false"},};

		o[1] = {name="Step", attr = {auto_create = "true", src = blocksfilename:gsub("(.*)[^\\/]+$", ""),},};

		local blocksNum;
		if(blocks) then
			blocksNum = #blocks;
		else
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SelectBlocksTask.lua");
			local select_task = MyCompany.Aries.Game.Tasks.SelectBlocks.GetCurrentInstance();
			if(select_task) then
				local blocks = select_task:GetCopyOfBlocks();
				blocksNum = #blocks;
			else
				file:close();
				return;
			end
		end


		o[1][1] = {name = "tip", attr = {block = string.format("0-%d",blocksNum - 1)},}

		file:WriteString(commonlib.Lua2XmlString(o, true));
		file:close();
		return true;
	end
end

function BlockTemplatePage.OnClickSave()
	if(not page) then
		return;
	end
	local template_dir = page:GetValue("template_dir");
	local isSaveInLocalWorld;
	if(template_dir == 0) then
		isSaveInLocalWorld = true;
		template_dir = nil;
	elseif(template_dir == -1) then
		template_dir = "";
	end

	local template_base_dir = BlockTemplatePage.template_save_dir or default_template_dir;
    local name = page:GetUIValue("name") or page:GetUIValue("tl_name") or "";
	local desc = page:GetUIValue("template_desc") or page:GetUIValue("template_desc") or "";
    desc = string.gsub(desc,"\r?\n","<br/>")
	name = name:gsub("%s", "");
	if(name == "")  then
		_guihelper.MessageBox(L"名字不能为空~")
		return;
	end
	local name_normalized = commonlib.Encoding.Utf8ToDefault(name);

	local isThemedTemplate = template_dir and template_dir ~= "";
	local bSaveSnapshot = false; -- not isThemedTemplate and not isSaveInLocalWorld;

    local filename,taskfilename;

	if(isSaveInLocalWorld) then
		filename = format("%s%s.blocks.xml", GameLogic.current_worlddir.."blocktemplates/", name_normalized);
	elseif(isThemedTemplate) then
		ParaIO.CreateDirectory(template_base_dir);
		local subdir = template_dir; -- commonlib.Encoding.Utf8ToDefault(template_dir);
		filename = format("%s%s.blocks.xml", template_base_dir..subdir.."/"..name_normalized.."/", name_normalized);
		taskfilename = format("%s%s.xml", template_base_dir..subdir.."/"..name_normalized.."/", name_normalized);
	else
		filename = format("%s%s.blocks.xml", template_base_dir, name_normalized);
	end

	local function doSave_()
		local x, y, z = ParaScene.GetPlayer():GetPosition();
		local bx, by, bz = BlockEngine:block(x,y,z)
		local player_pos = string.format("%d,%d,%d",bx,by,bz);
		local pivot = string.format("%d,%d,%d",BlockTemplatePage.pivot[1],BlockTemplatePage.pivot[2],BlockTemplatePage.pivot[3]);
		BlockTemplatePage.SaveToTemplate(filename, BlockTemplatePage.blocks, {
			name = name,
			author_nid = System.User.nid,
			creation_date = ParaGlobal.GetDateFormat("yyyy-MM-dd").."_"..ParaGlobal.GetTimeFormat("HHmmss"),
			player_pos = player_pos,
			pivot = pivot,
			relative_motion = page:GetValue("checkboxRelativeMotion", false),
		},function ()
			if(isThemedTemplate) then
				BlockTemplatePage.CreateBuildingTaskFile(taskfilename, commonlib.Encoding.DefaultToUtf8(filename), name, BlockTemplatePage.blocks,desc);
				BuildQuestProvider.RefreshDataSource();
			end
			GameLogic.GetFilters():apply_filters("file_exported", "template", filename);
		end, bSaveSnapshot);
	end
	if(ParaIO.DoesFileExist(filename)) then
		_guihelper.MessageBox(format(L"模板文件%s已经存在, 是否要覆盖之前的文件?", commonlib.Encoding.DefaultToUtf8(filename)), function(res)
			if(res and res == _guihelper.DialogResult.Yes) then
				doSave_();
			end
		end, _guihelper.MessageBoxButtons.YesNo);
	else
		doSave_();
	end
end

-- @params params: attributes like author, creation_date, name, etc. 
function BlockTemplatePage.SaveToTemplate(filename, blocks, params, callbackFunc, bSaveSnapshot)
	if( not GameLogic.IsOwner()) then
		--_guihelper.MessageBox(format("只有世界的作者, 才能保存模板. 请尊重别人的创意,不要盗版!", tostring(WorldCommon.GetWorldTag("nid"))));
		--return;
		GameLogic.AddBBS("copyright_respect", L"请尊重别人的创意,不要盗版!", 6000, "0 255 0");
	end

	if(not blocks or #blocks<1) then
		_guihelper.MessageBox(L"需要选中多块才能存为模板");
		return;
	end
	if(#blocks > BlockTemplatePage.max_blocks_per_template) then
		_guihelper.MessageBox(format(L"模板最多能保存%d块", BlockTemplatePage.max_blocks_per_template))
		return;
	end

	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BlockTemplateTask.lua");
	local BlockTemplate = commonlib.gettable("MyCompany.Aries.Game.Tasks.BlockTemplate");
	local task = BlockTemplate:new({operation = BlockTemplate.Operations.Save, filename = filename, params = params, blocks = blocks})

	if(task:Run()) then
		BroadcastHelper.PushLabel({id="BlockTemplatePage", label = format(L"模板成功保存到:%s", commonlib.Encoding.DefaultToUtf8(filename)), max_duration=4000, color = "0 255 0", scaling=1.1, bold=true, shadow=true,});
		page:CloseWindow();
		callbackFunc();
		if(bSaveSnapshot) then
			ParaIO.CopyFile(BlockTemplatePage.DefaultSnapShot, filename:gsub("xml$", "jpg"), true);	
		end
		_guihelper.MessageBox(L"保存成功！ 您可以从【建造】->【模板】中创建这个模板的实例了～");
	end
end

local cached_ds = {};
-- get all template ds
function BlockTemplatePage.GetAllTemplatesDS(bForceRefresh)
	if(not cached_ds[GameLogic.current_worlddir] or bForceRefresh) then
		NPL.load("(gl)script/ide/Files.lua");
	
		local root = {name="root", attr={},};
	
		local folder_global = {name="folder", attr={text=L"全局模板"},};
		root[#root+1] = folder_global;
		local folder_local = {name="folder", attr={text=L"本地模板", expanded=true},};
		root[#root+1] = folder_local;

		-- global dir and all of its sub directories.
		local result = commonlib.Files.Find({}, BlockTemplatePage.global_template_dir, 2, 500, "*.blocks.xml")
		local _, file
		for _, file in ipairs(result) do 
			file.text = file.filename:match("([^/\\]+)%.blocks%.xml$")
			if(file.text) then
				file.text = commonlib.Encoding.url_decode(commonlib.Encoding.DefaultToUtf8(file.text));
				file.filename = BlockTemplatePage.global_template_dir..file.filename;
				folder_global[#folder_global+1] = {name="file", attr=file};
			end
		end

		-- local dir
		local result = commonlib.Files.Find({}, GameLogic.current_worlddir.."blocktemplates/", 0, 500, function(item)
			if(item.filename:match("%.bmax$") or item.filename:match("%.blocks%.xml$")) then
				return true;
			end
		end)
		
		for _, file in ipairs(result) do 
			file.text = file.filename:match("([^/\\]+)%.blocks%.xml$")
			if(not file.text) then
				file.text = file.filename:match("([^/\\]+%.bmax)$")
			end
			if(file.text) then
				file.text = commonlib.Encoding.url_decode(commonlib.Encoding.DefaultToUtf8(file.text));
				file.filename = GameLogic.current_worlddir.."blocktemplates/"..file.filename;
				folder_local[#folder_local+1] = {name="file", attr=file};
			end
		end
		cached_ds[GameLogic.current_worlddir] = root;
	end
	return cached_ds[GameLogic.current_worlddir];
end

function BlockTemplatePage.CreateFromTemplate(filename, x, y, z)
	if(not x) then
		x, y, z = ParaScene.GetPlayer():GetPosition();
	end

	local bx, by, bz = BlockEngine:block(x, y+0.1, z);
	
	if(not BlockTemplatePage.LoadTemplate(filename, bx, by, bz, true)) then
		_guihelper.MessageBox(format(L"无法打开文件:%s", commonlib.Encoding.DefaultToUtf8(filename)))
	end
end

-- public function to load from a template to a given scene position.
-- @return true if created
function BlockTemplatePage.LoadTemplate(filename, bx, by, bz, bSelect)
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BlockTemplateTask.lua");
	local BlockTemplate = commonlib.gettable("MyCompany.Aries.Game.Tasks.BlockTemplate");
	local task = BlockTemplate:new({operation = BlockTemplate.Operations.Load, filename = filename,
		blockX = bx,blockY = by, blockZ = bz, bSelect=bSelect
		})
	return task:Run();
end



function BlockTemplatePage.OnClickOpenTemplateDir()
	ParaGlobal.ShellExecute("open", ParaIO.GetCurDirectory(0)..BlockTemplatePage.global_template_dir, "", "", 1); 
end

local category_ds = nil;
function BlockTemplatePage.GetCategoryDS()
	if(not category_ds) then
		category_ds = {
			{value = "1",template_save_dir = "worlds/DesignHouse/blocktemplates/",tag="template",text = L"世界模板",selected = true,},
			{value = "2",template_save_dir = "config/Aries/creator/blocktemplates/buildingtask/",tag="tutorial",text = L"新手教程",},
			-- {value = "3",template_save_dir = "config/Aries/creator/blocktemplates/blockwiki/",tag="blockwiki",text = L"建筑百科"},
			
		}
	end
	return category_ds;
end

function BlockTemplatePage.ChangeCategory(name,value)
	local index = tonumber(value);
	BlockTemplatePage.category_index = index;
	local ds = BlockTemplatePage.GetCategoryDS();
	ds[index]["selected"] = true;
	BlockTemplatePage.template_save_dir = ds[index]["template_save_dir"];
	local theme_category_ds = BlockTemplatePage.GetCategoryDS();
	BlockTemplatePage.themeKey = theme_category_ds[BlockTemplatePage.category_index or 1]["tag"];
	ParaIO.CreateDirectory(BlockTemplatePage.template_save_dir);
end
