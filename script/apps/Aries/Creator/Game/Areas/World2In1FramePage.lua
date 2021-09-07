--[[
Title: Builder Frame Page
Author(s): yangguiyi
Date: 2021/8/10
Desc: 
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/World2In1FramePage.lua");
local World2In1FramePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.World2In1FramePage");
World2In1FramePage.ShowPage(true)
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/BlockTemplatePage.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/CreateBlockTask.lua");

local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local BlockTemplatePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.BlockTemplatePage");
local Desktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local pe_gridview = commonlib.gettable("Map3DSystem.mcml_controls.pe_gridview");
local pe_treeview = commonlib.gettable("Map3DSystem.mcml_controls.pe_treeview");
local World2In1 = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/World2In1.lua");
local BuilderFramePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.BuilderFramePage");

local World2In1FramePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.World2In1FramePage");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BlockTemplateTask.lua");
local BlockTemplate = commonlib.gettable("MyCompany.Aries.Game.Tasks.BlockTemplate");
local page;

World2In1FramePage.category_index = 1;
World2In1FramePage.Current_Item_DS = {};

World2In1FramePage.uiversion = 1;
World2In1FramePage.isSearching = false;
World2In1FramePage.EmptyText = L"搜索: 输入ID或名字";

function World2In1FramePage.OnInit(uiversion)
	World2In1FramePage.category_index = 1;
	page = document:GetPageCtrl();
	World2In1FramePage.InitData()
	-- World2In1FramePage.OnChangeCategory(nil, false);
	if not World2In1FramePage.has_bind then
		World2In1FramePage.SaveTemplatePath = World2In1FramePage.SelectTemplatePath
		GameLogic:Connect("WorldSaved", World2In1FramePage, World2In1FramePage.SaveToXml, "UniqueConnection");
		World2In1FramePage.has_bind = true
	end
end

function World2In1FramePage.GetCategoryButtons()
	-- if World2In1FramePage.category_ds == nil then
	-- 	World2In1FramePage.InitData()
	-- end

	return World2In1FramePage.category_ds;
end

-- clicked a block item
function World2In1FramePage.OnClickBlock(index)
-- echo(block_id_or_item, true)
	local block_item =  World2In1FramePage.Current_Item_DS[index]
	if block_item.isvip and not GameLogic.IsVip() then
		local VipPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/VipPage.lua");
		VipPage.ShowPage("world2in1_tool");
		return
	end
	if block_item.is_agent_item then
		BuilderFramePage.OnClickBlock(block_item.blcok_item_data)
		return
	end

	if block_item.price and block_item.price ~= 0 then
		local world_data = Mod.WorldShare.Store:Get('world/currentWorld')
		local currentEnterWorld = Mod.WorldShare.Store:Get('world/currentEnterWorld')
		if world_data == nil or world_data.kpProjectId == nil or world_data.kpProjectId == 0 or world_data.kpProjectId == currentEnterWorld.kpProjectId then
			local World2In1 = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/World2In1.lua");
			if World2In1.GetIsWorld2In1() and World2In1.GetRegionType() == "creator" then
				_guihelper.MessageBox("该功能需要上传项目后才能使用，是否立即上传", function()	
					World2In1.OnSaveWorld()
				end)
			end 			
			return
		end

		-- 有价格的话 查询表 看是否已经购买
		local result = World2In1FramePage.CheckItemPurchases(block_item)
		if not result then
			local desc = string.format("%s需要%s个知识豆，确定购买吗", block_item.name, block_item.price)
			_guihelper.MessageBox(desc, function()	
				local bean_gsid = 998;
				local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
				local bHas,guid,bagid,copies,goods_item = KeepWorkItemManager.HasGSItem(bean_gsid)
				copies = copies or 0;	

				if copies < block_item.price then
					_guihelper.MessageBox("您的知识豆不足")			
					return		
				end

				keepwork.user.bean_reduce({
					count = block_item.price
				}, function(err, msg, data)
					if err == 200 then
						GameLogic.AddBBS(nil, L"购买成功");
						goods_item.copies = data.bean
						local key = world_data.kpProjectId .. "_" .. block_item.block_id
						if World2In1FramePage.ItemReceiptData == nil then
							World2In1FramePage.ItemReceiptData = {}
						end

						World2In1FramePage.ItemReceiptData[#World2In1FramePage.ItemReceiptData + 1] = {name="goods", attr={key=key}}
						World2In1FramePage.SaveToXml()

						World2In1FramePage.OnClickBlock(index)
					end
				end)
			end)
			return
		end
	end

	if block_item.type == "skybox" then
		-- 天空盒之类的处理
		if index == 1 then
			NPL.load("(gl)script/apps/Aries/Creator/Env/SkyPage.lua");
			local SkyPage = commonlib.gettable("MyCompany.Aries.Creator.SkyPage");
			SkyPage.OnChangeSkybox(1);
		else
			local filename = block_item.filename
			if filename then
				local file = string.format("model/skybox/%s/%s.x", filename, filename)
				CommandManager:RunCommand("/sky "..file);
			end
		end
	elseif block_item.type == "sandtable" then
		local filename = block_item.filename
		if filename then
			local file = string.format("config/Aries/creator/template/sandtable/%s.xml", filename)
			--CommandManager:RunCommand("/loadtemplate "..file);
			World2In1FramePage.SelectTemplatePath = file
			World2In1FramePage.CreateSandTable()
			--World2In1FramePage.SaveToXml()
		end
	elseif block_item.block_id then
		local item = ItemClient.GetItem(block_item.block_id)
		if(item) then
			item:OnClick();
		end
	end
end

function World2In1FramePage.CreateSandTable()
	if World2In1FramePage.SelectTemplatePath == nil or World2In1FramePage.SelectTemplatePath == "" then
		return
	end

	local file = World2In1FramePage.SelectTemplatePath
	local task = BlockTemplate:new({operation = BlockTemplate.Operations.Load, filename = file,
	blockX = 19136,blockY = 2, blockZ = 19136, bSelect=false
	})
	task:Run();
end

function World2In1FramePage.OnHelpBlock(block_id)
end

function World2In1FramePage.OnChangeCategory(index, bRefreshPage)
	World2In1FramePage.category_index = index

	World2In1FramePage.Current_Item_DS = {}
	if World2In1FramePage.category_ds[index] then
		World2In1FramePage.Current_Item_DS = World2In1FramePage.category_ds[index].item_list
	end

	if(page) then
		page:Refresh(0);
	end
end

--- @param search_text string
--- @return nil
function World2In1FramePage.SearchTemplate(search_text)
end

function World2In1FramePage.InitData()
	World2In1FramePage.category_ds = World2In1.GetToolItems()
	World2In1FramePage.Current_Item_DS = {}
	if World2In1FramePage.category_ds[1] then
		World2In1FramePage.Current_Item_DS = World2In1FramePage.category_ds[1].item_list
	end

	World2In1FramePage.LoadXmlData()
end

function World2In1FramePage.IsSandTable()
	local category_data = World2In1FramePage.category_ds[World2In1FramePage.category_index]
	if category_data == nil then
		return
	end
	
	return category_data.type == "sandtable"
end

function World2In1FramePage.SetSign()
	local str = page:GetValue("block_sign_text_ctl")

	if not str or str == "" then
		return
	end

	local str_lenth = #str
	
	for i=1,str_lenth do
		local cur_byte = string.byte(str, i)
		local is_lower_letter = cur_byte >= 97 and cur_byte <= 122
		local is_capital_latter = cur_byte >= 65 and cur_byte <= 90
		local is_num = cur_byte >= 48 and cur_byte <= 57

		if not is_lower_letter and not is_capital_latter and not is_num then
			GameLogic.AddBBS(nil, L"含有非法字符，只支持英文或数字");
			return
		end
	end

	if str_lenth > 15 then
		GameLogic.AddBBS(nil, L"超过限定长度，只支持15个英文或数字");
		return
	end



	local upperstr = string.upper(str);
	World2In1FramePage.CharTemplateData = {}
	for i=1,str_lenth do
		local cur_char = string.sub(upperstr, i, i)
		local filename = cur_char
		local file = string.format("config/Aries/creator/template/letter/%s.blocks.xml", filename)

		local blocks = World2In1FramePage.LoadTemplateFile(file)
		World2In1FramePage.CharTemplateData[i] = blocks
		
		-- local task = MyCompany.Aries.Game.Tasks.CreateBlock:new({blockX = pos_x,blockY = pos_y, blockZ = pos_z, blocks = blocks, bSelect=false, nohistory = true})
		-- task:Run();
	end

	if World2In1FramePage.SignWordBegainPos == nil then
		World2In1FramePage.SignWordBegainPos = {
			{19263,3,19136}, -- 这个位置 z++ 是文字的正方向
			{19136,3,19263}, -- z-- 是文字的方向
			{19136,3,19136}, -- x++ 是文字的方向
			{19263,3,19263}, -- x-- 是文字的方向
		}
	end

	for i, v in ipairs(World2In1FramePage.SignWordBegainPos) do
		World2In1FramePage.CreateTemplateBlock(i, v)
	end
end

function World2In1FramePage.CreateTemplateBlock(index, begain_pos)
	-- 先清理
	local width = 128
	local height = 8
	local change_pos_data = commonlib.copy(begain_pos);

	local change_index
	local change_dir

	if index == 1 then -- z++ 
		change_index = 3
		change_dir = 1
	elseif index == 2 then -- z--
		change_index = 3
		change_dir = -1
	elseif index == 3 then -- x++
		change_index = 1
		change_dir = 1
	else
		-- x--
		change_index = 1
		change_dir = -1
	end

	-- for i1 = 1, width do
	-- 	for i2 = 1, height do
	-- 		change_pos_data[change_index] = begain_pos[change_index] + (i1 - 1) * change_dir
	-- 		change_pos_data[2] = begain_pos[2] + i2 - 1
	-- 		BlockEngine:SetBlock(change_pos_data[1], change_pos_data[2], change_pos_data[3], 0);
	-- 	end
	-- end
	World2In1FramePage.CreateSandTable()

	-- 计算出文字占据的方块宽度
	local letter_block_width = 5
	local interval = 2
	local word_num = #World2In1FramePage.CharTemplateData
	local word_block_width = word_num * letter_block_width + (word_num-1) * interval
	local mid_pos = begain_pos[change_index] + width/2 * change_dir
	local word_begain_pos = math.floor(mid_pos - word_block_width/2 * change_dir)

	change_pos_data = commonlib.copy(begain_pos);

	commonlib.TimerManager.SetTimeout(function()  
		for i, v in ipairs(World2In1FramePage.CharTemplateData) do
			local blocks = World2In1FramePage.ChangeBlocksPos(v, index)
			change_pos_data[change_index] = word_begain_pos + ((i-1)*letter_block_width+2*(i-1)) * change_dir
			
			local task = MyCompany.Aries.Game.Tasks.CreateBlock:new({blockX = change_pos_data[1],blockY = change_pos_data[2], blockZ = change_pos_data[3], blocks = blocks, bSelect=false, nohistory = true})
			task:Run();
		end
	end, 200);

end

-- 根据方向转换成对应的方块位置
function World2In1FramePage.ChangeBlocksPos(blocks, type_index)
	local result = {}
	local letter_block_width = 5
	-- 默认字的template是x,y不变 z++
	for i, v in ipairs(blocks) do
		local data = {v[1],v[2],v[3],v[4]}
		
		if type_index == 1 then

		elseif type_index == 2 then
			data[3] = letter_block_width - v[3] - letter_block_width
		elseif type_index == 3 then
			data[1] = v[3]
			data[3] = v[1]
		elseif type_index == 4 then
			data[1] = v[3]
			data[3] = v[1]

			data[1] = letter_block_width - data[1] - letter_block_width
		end

		if World2In1FramePage.SignBlockId then
			data[4] = World2In1FramePage.SignBlockId
		end

		result[i] = data
	end

	return result
end

function World2In1FramePage.LoadTemplateFile(filename)
	local xmlRoot = ParaXML.LuaXML_ParseFile(filename or "");
	if(not xmlRoot) then
		xmlRoot = ParaXML.LuaXML_ParseFile(commonlib.Encoding.Utf8ToDefault(filename));
	end
	if(xmlRoot) then
		local node = commonlib.XPath.selectNode(xmlRoot, "/pe:blocktemplate/pe:blocks");
		if(node and node[1]) then
			local blocks = NPL.LoadTableFromString(node[1]);

			return blocks
		end
	end
end

local lessonbox_tool_filename = "lessonbox_tool.xml";
function World2In1FramePage.SaveToXml()
	local world_data = Mod.WorldShare.Store:Get('world/currentWorld')
	local disk_folder = world_data.worldpath
	local filename = disk_folder .. lessonbox_tool_filename;
	local root = {name='lessonbox', attr={file_version="0.1"} }
	local select_template = World2In1FramePage.SaveTemplatePath or ""
	local use_sandtable = {name="use_sandtable", attr={select_template = World2In1FramePage.SaveTemplatePath}}
	root[1] = use_sandtable;

	--root[2] = {}

	root[2] = World2In1FramePage.ItemReceiptData or {}
	root[2].name="receipt"

	local xml_data = commonlib.Lua2XmlString(root, true, true) or "";
	local file = ParaIO.open(filename, "w");
	if(file:IsValid()) then
		file:WriteString(xml_data);
		file:close();
	end
end

function World2In1FramePage.LoadXmlData()
	local world_data = Mod.WorldShare.Store:Get('world/currentWorld')
	local disk_folder = world_data.worldpath
	local filename = disk_folder .. lessonbox_tool_filename;
	local xmlRoot = ParaXML.LuaXML_ParseFile(filename or "");
	if(not xmlRoot) then
		xmlRoot = ParaXML.LuaXML_ParseFile(commonlib.Encoding.Utf8ToDefault(filename));
	end

	if(xmlRoot) then
		local root = commonlib.XPath.selectNode(xmlRoot, "/lessonbox");
		-- 1是沙盒数据
		if(root and root[1] and root[1].attr) then
			local use_sandtable_data = root[1];
			World2In1FramePage.SelectTemplatePath = use_sandtable_data.attr.select_template
			World2In1FramePage.SaveTemplatePath = World2In1FramePage.SelectTemplatePath
			--return blocks
		end

		-- 2是物品购买数据
		if(root and root[2]) then
			local receipt = root[2];
			World2In1FramePage.ItemReceiptData = root[2]
			--return blocks
		end

	end
end

function World2In1FramePage.CheckItemPurchases(item)
	-- 购买后的物品以 projectid_blockid 的形式保存 所以如果没有blockid 返回true
	if World2In1FramePage.ItemReceiptData == nil or #World2In1FramePage.ItemReceiptData == 0 then
		return false
	end

	if not item.block_id then
		return true
	end

    local world_data = Mod.WorldShare.Store:Get('world/currentWorld')
	if world_data == nil or world_data.kpProjectId == nil then
		return true
	end

	local key = world_data.kpProjectId .. "_" .. item.block_id

	for k, v in pairs(World2In1FramePage.ItemReceiptData) do
		if type(v) == "table" and v.attr and v.attr.key == key then
			return true
		end
	end

	return false
end

function World2In1FramePage.GetToolTip(index)
	local block_item =  World2In1FramePage.Current_Item_DS[index]
	if not block_item then
		return
	end

	if block_item.tips then
		return block_item.tips
	end

	return block_item.name
end

function World2In1FramePage.IsResourceType()
	local category_data = World2In1FramePage.category_ds[World2In1FramePage.category_index]
	if category_data == nil then
		return false
	end

	return category_data.type == "resource"
end