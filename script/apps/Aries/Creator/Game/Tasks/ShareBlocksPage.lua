--[[
Title: 
Author(s): yangguiyi
Date: 2021/11/24
Desc: 
------------------------------------------------------------
local ShareBlocksPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ShareBlocksPage.lua");
ShareBlocksPage.ShowPage()
-------------------------------------------------------
]]
local SelectBlocks = commonlib.gettable("MyCompany.Aries.Game.Tasks.SelectBlocks");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local ShareBlocksPage = NPL.export();
local page;

function ShareBlocksPage.OnInit()
	page = document:GetPageCtrl();
	page.OnClose = ShareBlocksPage.OnClose
end

function ShareBlocksPage.ShowPage(bShow)
	if not GameLogic.GetFilters():apply_filters('is_signed_in') then
		GameLogic.GetFilters():apply_filters('check_signed_in', "请先登录", function(result)
			if result == true then
				ShareBlocksPage.ShowPage(bShow)
			end
		end)

		return
	end

	ShareBlocksPage.selected_count = SelectBlocks.selected_count or 0
	ShareBlocksPage.selected_range = 16
	SelectBlocks.ClosePage();
	-- display a page containing all operations that can apply to current selection, like deletion, extruding, coloring, etc. 
	local x, y, width, height = 0, 160, 140, 330;
	System.App.Commands.Call("File.MCMLWindowFrame", {
			url = "script/apps/Aries/Creator/Game/Tasks/ShareBlocksPage.html", 
			name = "ShareBlocksPage.ShowPage", 
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			isShowTitleBar = false,
			DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
			style = CommonCtrl.WindowFrame.ContainerStyle,
			zorder = 1,
			allowDrag = true,
			click_through = true,
			directPosition = true,
				align = "_lt",
				x = x,
				y = y,
				width = width,
				height = height,
		});

	if ShareBlocksPage.selected_count == 0 then
		commonlib.TimerManager.SetTimeout(function()  
			ShareBlocksPage.AutoSelect()
		end, 100);
	end
end

function ShareBlocksPage.OnClose()
	page = nil
	ShareBlocksPage.LastCenterPos = nil
	SelectBlocks.CancelSelection()
end

function ShareBlocksPage.Close()
	if page then
		page:CloseWindow()
		page = nil
	end
end

function ShareBlocksPage.IsOpen()
	return page ~= nil and page:IsVisible()
end

function ShareBlocksPage.UpdateBlockNumber(count)
	if(page) then
		if(ShareBlocksPage.selected_count ~= count) then
			if( not (count > 1 and ShareBlocksPage.selected_count>1) ) then
				ShareBlocksPage.selected_count = count;
				page:Refresh(0.01);
			else
				ShareBlocksPage.selected_count = count;
				page:SetUIValue("title", format(L"选中了%d块",count or 1));
			end
		end
	end

	local cur_select_task = SelectBlocks.GetCurrentInstance()
	if cur_select_task then
		local x,y,z = cur_select_task:GetSelectionPivot()
		ShareBlocksPage.LastCenterPos = {x,y,z}
	end
end

function ShareBlocksPage.CancelSelection()
	ShareBlocksPage.selected_count = 0
	page:Refresh(0.01);
end

function ShareBlocksPage.AutoSelect()
	local player = EntityManager.GetPlayer();
	if not player then
		return
	end

	ShareBlocksPage.SelectBlockPosList = {}
	local x, y, z = player:GetBlockPos();
	local radius = math.floor(ShareBlocksPage.selected_range/2)
	local start_x = x - radius
	local start_z = z - radius

	ShareBlocksPage.SelectBlock(start_x, start_z, y, ShareBlocksPage.selected_range)
end

function ShareBlocksPage.SelectBlock(start_x, start_z, search_y, range1, range2)
	range2 = range2 or range1
	local is_need_find_next_layer = false
	for index_x = 1, range1 do
		local select_x = start_x + index_x
		for index_z = 1, range2 do
			local select_z = start_z + index_z
			local cur_layer_block_id = BlockEngine:GetBlockId(select_x,search_y,select_z)
			local next_layer_block_id = BlockEngine:GetBlockId(select_x,search_y + 1,select_z)
			if next_layer_block_id and next_layer_block_id ~= 0 then
				is_need_find_next_layer = true
			end
			if cur_layer_block_id and cur_layer_block_id ~= 0 then
				ShareBlocksPage.SelectBlockPosList[#ShareBlocksPage.SelectBlockPosList + 1] = {select_x, search_y, select_z}
			end
			
		end
	end

	if is_need_find_next_layer then
		ShareBlocksPage.SelectBlock(start_x, start_z, search_y + 1,range1, range2)
	else
		if #ShareBlocksPage.SelectBlockPosList > 0 then
			local task = MyCompany.Aries.Game.Tasks.SelectBlocks:new({blocks=ShareBlocksPage.SelectBlockPosList})
			task:Run();
			ShareBlocksPage.SelectBlockPosList = {}
		end
	end
end

function ShareBlocksPage.ChangeRange(name)
	local cur_select_task = SelectBlocks.GetCurrentInstance()
	if not cur_select_task then
		if name == "add" then
			if ShareBlocksPage.LastCenterPos then
				local task = MyCompany.Aries.Game.Tasks.SelectBlocks:new({blocks={ShareBlocksPage.LastCenterPos}})
				task:Run();
			else
				ShareBlocksPage.AutoSelect()
			end
		end
		return
	end

	local center_x, center_y, center_z = cur_select_task:GetSelectionPivot()
	-- if cur_select_task then
	-- 	center_x, center_y, center_z = cur_select_task:GetSelectionPivot()
	-- elseif ShareBlocksPage.LastCenterPos then
	-- 	local last_center_pos = ShareBlocksPage.LastCenterPos
	-- 	center_x, center_y, center_z = last_center_pos[1],last_center_pos[2],last_center_pos[3]
	-- end

	if nil == center_x then
		return
	end
	
	-- 取出距离最远的坐标
	local max_dis = -1
	local max_dis_pos


	for key, v in pairs(cur_select_task.blocks) do
		local dis = (v[1] - center_x)^2 + (v[2] - center_y)^2 + (v[3] - center_z)^2;
		if dis > max_dis then
			max_dis = dis
			max_dis_pos = v
		end
	end
	
	if not max_dis_pos then
		return
	end

	local direct_x = 0
	if max_dis_pos[1] > center_x then
		direct_x = 1
	elseif max_dis_pos[1] < center_x then
		direct_x = -1
	end

	local direct_z = 0
	if max_dis_pos[3] > center_z then
		direct_z = 1
	elseif max_dis_pos[3] < center_z then
		direct_z = -1
	end

	local target_pos_list = {}
	if name == "add" then	
		if #cur_select_task.blocks == 1 then
			direct_x = 1
			direct_z = 1
		end

		max_dis_pos[1] = max_dis_pos[1] + direct_x
		max_dis_pos[3] = max_dis_pos[3] + direct_z
	else
		max_dis_pos[1] = max_dis_pos[1] - direct_x
		max_dis_pos[3] = max_dis_pos[3] - direct_z
	end

	local x_times = math.abs(max_dis_pos[1] - center_x) * 2 + 1
	local z_times = math.abs(max_dis_pos[3] - center_z) * 2 + 1


	
		if #cur_select_task.blocks == 1 then
			if name == "add" then	
				direct_x = 1
				direct_z = 1
			else
				x_times = 0
				z_times = 0
			end
		end


	local function auto_select(select_y)
		local is_need_find_next_layer = false
		for x_index = 1, x_times do
			local target_x = max_dis_pos[1] - (x_index - 1) * direct_x
			for z_index = 1, z_times do
				local target_z = max_dis_pos[3] - (z_index - 1) * direct_z
				local block_id = BlockEngine:GetBlockId(target_x, select_y, target_z)
				local next_layer_block_id = BlockEngine:GetBlockId(target_x,select_y + 1,target_z)
				if block_id ~= 0 then
					target_pos_list[#target_pos_list + 1] = {target_x, select_y, target_z}
				end

				if next_layer_block_id ~= 0 then
					is_need_find_next_layer = true
				end
	
				-- ShareBlocksPage.AutoSelectY(target_x, center_y, target_z)
			end
		end

		if is_need_find_next_layer then
			auto_select(select_y + 1)
		else
			SelectBlocks.CancelSelection();
			if #target_pos_list > 0 then
				commonlib.TimerManager.SetTimeout(function()  
					local task = MyCompany.Aries.Game.Tasks.SelectBlocks:new({blocks=target_pos_list})
					task:Run();
				end, 100);
			end
		end
	end
	
	auto_select(center_y)
end

function ShareBlocksPage.AutoSelectY(x_times, z_times, max_dis_pos, direct_x, direct_z, target_pos_list)
	for x_index = 1, x_times do
		local target_x = max_dis_pos[1] - (x_index - 1) * direct_x
		for z_index = 1, z_times do
			local target_z = max_dis_pos[3] - (z_index - 1) * direct_z
			local block_id = BlockEngine:GetBlockId(target_x, targer_y, targer_z)
			local next_layer_block_id = BlockEngine:GetBlockId(select_x,targer_y + 1,select_z)
			if block_id ~= 0 then
				-- body
			end

			-- ShareBlocksPage.AutoSelectY(target_x, center_y, target_z)
		end
	end

	-- local block_id = BlockEngine:GetBlockId(target_x, targer_y, targer_z)
	-- if block_id ~= 0 then
	-- 	-- target_pos_list[#target_pos_list + 1] = {target_x, center_y, target_z}
	-- 	local block_data = ParaTerrain.GetBlockUserDataByIdx(target_x, targer_y, targer_z);
	-- 	local cur_select_task = SelectBlocks.GetCurrentInstance()
	-- 	cur_select_task:SelectSingleBlock(target_x, targer_y, targer_z, block_id, block_data);

	-- 	ShareBlocksPage.AutoSelectY(target_x, targer_y + 1, targer_z)
	-- else
		
	-- end
end

function ShareBlocksPage.GetSelectCount()
	local cur_select_task = SelectBlocks.GetCurrentInstance()
	if cur_select_task then
		return #cur_select_task.blocks
	end

	return 0
end

function ShareBlocksPage.ShareBlcok()
	-- 先保存templete到temp目录下

	ShareBlocksPage.SaveBlockAndShare()
end

function ShareBlocksPage.SaveBlockAndShare()
	local cur_select_task = SelectBlocks.GetCurrentInstance()
	if not cur_select_task then
		_guihelper.MessageBox("请先选择方块");
		return
	end

	local pivot_x, pivot_y, pivot_z = cur_select_task:GetSelectionPivot();
	if(cur_select_task.UsePlayerPivotY) then
		local x,y,z = ParaScene.GetPlayer():GetPosition();
		local _, by, _ = BlockEngine:block(0,y+0.1,0);
		pivot_y = by;
	end
	local pivot = {pivot_x, pivot_y, pivot_z};

	local blocks = cur_select_task:GetCopyOfBlocks(pivot);
	
	-- NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/BlockTemplatePage.lua");
	-- local BlockTemplatePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.BlockTemplatePage");
	-- BlockTemplatePage.ShowPage(true, blocks, pivot);
	local name = "share_file_" .. os.time()
	local name_normalized = commonlib.Encoding.Utf8ToDefault(name);
	local template_dir = "temp/ShareBlock/"
	-- local isThemedTemplate = template_dir and template_dir ~= "";
	local bSaveSnapshot = false;
	local filename, taskfilename;
	ParaIO.CreateDirectory(template_dir);
	filename = format("%s%s.blocks.xml", template_dir, name_normalized);
	taskfilename = format("%s%s.xml", template_dir, name_normalized);

	local function doSave_()
		NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/BlockTemplatePage.lua");
		local BlockTemplatePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.BlockTemplatePage");
		local x, y, z = ParaScene.GetPlayer():GetPosition();
		local bx, by, bz = BlockEngine:block(x,y,z)
		local player_pos = string.format("%d,%d,%d",bx,by,bz);

		-- replace cob web block with air 0, if it is a task file.
		if(taskfilename) then
			local cobWebBlock = 118; -- id for cob web block. 
			for _, b in ipairs(blocks) do
				if(b[4] == cobWebBlock) then
					b[4] = 0;
				end
			end
		end

		local isSilenceSave = true
		pivot = string.format("%d,%d,%d",pivot[1],pivot[2],pivot[3]);
		BlockTemplatePage.SaveToTemplate(filename, blocks, {
			name = name,
			author_nid = System.User.nid,
			creation_date = ParaGlobal.GetDateFormat("yyyy-MM-dd").."_"..ParaGlobal.GetTimeFormat("HHmmss"),
			player_pos = player_pos,
			pivot = pivot,
			relative_motion = false,
			hollow = false,
			exportReferencedFiles = false,
		},function ()
			ShareBlocksPage.UpLoadFile(filename)
		end, bSaveSnapshot, isSilenceSave);
	end
	
	doSave_();
end

function ShareBlocksPage.UpLoadFile(filename)
	local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
	local profile = KeepWorkItemManager.GetProfile()
	if not profile.id then
		return
	end


	local key = string.format("model-share-%s-%s", profile.id, ParaMisc.md5(filename))
    keepwork.shareBlock.getToken({
        router_params = {
            id = key,
        }
    },function(err, msg, data)
		if err == 200 then
			local token = data.data.token
			local file_name = commonlib.Encoding.DefaultToUtf8(ParaIO.GetFileName(filename));
			local file = ParaIO.open(filename, "rb");
			if (not file:IsValid()) then
				file:close();
				return;
			end
			local content = file:GetText(0, -1);
			file:close();
			GameLogic.GetFilters():apply_filters(
				'qiniu_upload_file',
				token,
				key,
				file_name,
				content,
				function(result, err)
					-- print("pppppppppppppppeeee", err)
					-- echo(result, true)
					-- print("qiniu-public-temporary-dev.keepwork.com/" .. key)
					-- print("qiniu-public-temporary.keepwork.com/" .. key)
					-- local key = "model-share-162199-97f741d183885f245c4534661cd0c2a7"
					ShareBlocksPage.Close()
					local FriendsPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Friend/FriendsPage.lua");
					FriendsPage.Show(2, {msg_type = 2, content = "qiniu-public-temporary.keepwork.com/" .. key})
					if err ~= 200 then
						return;
					end
				end
			)
		end
    end)
end