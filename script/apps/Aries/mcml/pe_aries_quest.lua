--[[
Title: 
Author(s): Leio
Date: 2011/01/18
Desc: 

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/mcml/pe_aries_quest.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Service/CommonClientService.lua");
local CommonClientService = commonlib.gettable("MyCompany.Aries.Service.CommonClientService");
NPL.load("(gl)script/apps/Aries/Quest/QuestHelp.lua");
local QuestHelp = commonlib.gettable("MyCompany.Aries.Quest.QuestHelp");	
local pe_aries_quest = commonlib.gettable("MyCompany.Aries.mcml_controls.pe_aries_quest");
local pe_aries_quest_item = commonlib.gettable("MyCompany.Aries.mcml_controls.pe_aries_quest_item");
local pe_aries_quest_repeat_item = commonlib.gettable("MyCompany.Aries.mcml_controls.pe_aries_quest_repeat_item");
local pe_html = commonlib.gettable("Map3DSystem.mcml_controls.pe_html");
local mcml_controls = commonlib.gettable("Map3DSystem.mcml_controls");

NPL.load("(gl)script/kids/3DMapSystemApp/mcml/default_css.lua");
local pe_css = commonlib.gettable("Map3DSystem.mcml_controls.pe_css");


NPL.load("(gl)script/apps/Aries/Quest/NPCList.lua");
local NPCList = commonlib.gettable("MyCompany.Aries.Quest.NPCList");

NPL.load("(gl)script/apps/Aries/Scene/WorldManager.lua");
local WorldManager = commonlib.gettable("MyCompany.Aries.WorldManager");
NPL.load("(gl)script/apps/Aries/Quest/QuestWeekRepeat.lua");
local QuestWeekRepeat = commonlib.gettable("MyCompany.Aries.Quest.QuestWeekRepeat");
function pe_aries_quest_item.IsTeen()
	if(System.options.version and System.options.version == "teen")then
		return true;
	end
end

pe_css.SetDefault("aries:quest_item", {float="left", });

function pe_aries_quest.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local css = mcmlNode:GetStyle(mcml_controls.pe_css.default[mcmlNode.name], style) or {};
	Map3DSystem.mcml.baseNode.DrawChildBlocks_Callback(mcmlNode, rootName, bindingContext, _parent, left, top, width, height, parentLayout, css)
	--local childnode;
	--for childnode in mcmlNode:next() do
		--Map3DSystem.mcml_controls.create(rootName, childnode, bindingContext, _parent, left, top, width, height, style, parentLayout);
	--end
end
function pe_aries_quest_item.tableHasValue(template,key)
     if(template)then
        local v = template[key];
        if(v)then
            local len = #v;
            if(len > 0)then
                return true;
            end
        end
    end
end
function pe_aries_quest_item.goalProgress(template,questid,provider,key)
    if(template and questid and provider and key)then
        local q_item = provider:GetQuest(questid);
        local req_p = template[key];
        if(req_p)then
            local cur_p;
            if(q_item  and key == "Goal")then
                cur_p = q_item.Cur_Goal;
            elseif(q_item  and key == "GoalItem")then
                cur_p = q_item.Cur_GoalItem;
            elseif(q_item  and key == "ClientGoalItem")then
                cur_p = q_item.Cur_ClientGoalItem;
            elseif(q_item  and key == "ClientExchangeItem")then
                cur_p = q_item.Cur_ClientExchangeItem;
            elseif(q_item  and key == "FlashGame")then
                cur_p = q_item.Cur_FlashGame;
            elseif(q_item  and key == "ClientDialogNPC")then
                cur_p = q_item.Cur_ClientDialogNPC;
              elseif(q_item  and key == "CustomGoal")then
                cur_p = q_item.Cur_CustomGoal;
            elseif(key == "RequestAttr")then
                 cur_p = provider:GetUserRequestAttr(template.RequestAttr);
            end
            local condition = req_p.condition;
            local result = { condition = condition };
            local k,v;
            for k,v in ipairs(req_p) do
                local id = v.id;
                local value = v.value;
                local producer_id = v.producer_id;
                --任务还没有接取
                if(not cur_p or q_item.QuestState == 5)then
					local cur_value = 0;
					if(id == 20046 or id == 20048)then
						cur_value = cur_value + 1000;
						value = value + 1000;
					end
                    local item = { id = id, cur_value = cur_value, req_value = value, producer_id = producer_id,};
                    table.insert(result,item);    
                else
                    local kk,vv;
                    for kk,vv in ipairs(cur_p) do
                        local cur_id = vv.id;
                        local cur_value = vv.value;
                        if(id == cur_id)then
							if(id == 20046 or id == 20048)then
								cur_value = cur_value + 1000;
								value = value + 1000;
							end
                            local item = { id = id, cur_value = cur_value, req_value = value, producer_id = producer_id,};
                            table.insert(result,item);    
                        end
                    end                
                end
            end
            return result;
        end
    end
end
--自己是否在 副本世界
function pe_aries_quest_item.checkIsInInstanceWorld()
	local canpass = WorldManager:CanTeleport_CurrentWorld();
	if(not canpass)then
        _guihelper.MessageBox("<div style='margin-left:15px;margin-top:15px;text-align:center'>你还在副本世界中，不能追踪目标！先离开副本世界吧。</div>");
	end
    return canpass;
end
--目标世界是否是 同一个世界
function pe_aries_quest_item.checkWorld(arg1,arg2)
    local canpass = true;
	local worldname;
    if(arg1 == "byname")then
		worldname = arg2;
    else
		worldname = QuestHelp.WorldNumToWorldName(arg2);
    end
	local cur_world_info = WorldManager:GetCurrentWorld();
	if(cur_world_info.name ~= worldname)then
		canpass = false;
	end
    if(not canpass)then
		WorldManager:TeleportTo_CurrentWorld_Captain_PreDialog(worldname);
    end
    return canpass;
end
--目标世界是否 是副本世界
function pe_aries_quest_item.checkInstanceWorld(arg1,arg2)
    local canpass = true;
	local worldname;
    if(arg1 == "byname")then
		worldname = arg2;
    else
        worldname = QuestHelp.WorldNumToWorldName(arg2);
    end
	local is_instance = WorldManager:IsInstanceWorld(worldname);
	if(is_instance)then
		canpass = false;
	end
	local chkEntry = WorldManager:GetWorldInstanceEntry(worldname);
	if(chkEntry and chkEntry.island_name and chkEntry.island_name == worldname) then
		_guihelper.Custom_MessageBox("<div style='margin-left:15px;margin-top:35px;text-align:center'>该目标在本岛的副本世界中，只能传送到副本门口，是否马上过去？</div>",function(result)
			if(result == _guihelper.DialogResult.Yes)then
				facing = 0;
				local radius = 5;
				local end_pos = chkEntry.entry_pos;
				if(end_pos)then
					local  x,y,z = end_pos[1],end_pos[2],end_pos[3];
					x = x + radius * math.sin(facing);
					z = z + radius * math.cos(facing);
					if(x and y and z)then
						local Position = {x,y,z, facing+1.57};
						local CameraPosition = { 15, 0.27, facing + 1.57 - 1};
						local msg = { aries_type = "OnMapTeleport", 
									position = Position, 
									camera = CameraPosition, 
									bCheckBagWeight = true,
									wndName = "map", 
								};
							CommonCtrl.os.hook.Invoke(CommonCtrl.os.hook.HookType.WH_CALLWNDPROCRET, 0, "Aries", msg);
					end
				end
			end
		end,_guihelper.MessageBoxButtons.YesNo,{yes = "Texture/Aries/Common/Coming_32bits.png; 0 0 153 49", no = "Texture/Aries/Common/Later_32bits.png; 0 0 153 49"});
	end
    return canpass;
end
--目标世界是否是vip世界
function pe_aries_quest_item.checkVipWorld(arg1,arg2)
	return true;
end
function pe_aries_quest_item.do_help_func(s)
	local id,key,instName,func_str = string.match(s,"(.+)_(.+)@(.+)@(.+)");
	if(func_str)then
		NPL.DoString(func_str);
		--local func = commonlib.getfield(func_str);
		--if(func)then
			--func();
		--end
	end
end
function pe_aries_quest_item.has_help_func(key,map,id)
	if(key and map and id)then
		if(key == "StartNPC" or key == "EndNPC" or key == "ClientDialogNPC" or key == "ClientExchangeItem")then
			return false;
		else
			local item = map[id];
			if(item)then
				local helpfunction = item.helpfunction;
				if(helpfunction and helpfunction ~= "")then
					return true,helpfunction;
				end
			end
		end
	end
end
function pe_aries_quest_item.has_pos(key,map,id)
	if(key and map and id)then
		if(key == "StartNPC" or key == "EndNPC" or key == "ClientDialogNPC" or key == "ClientExchangeItem")then
			local npc, __, npc_data = NPCList.GetNPCByIDAllWorlds(id);
			if(npc)then
				local end_pos = npc.position;
				if(end_pos)then
					return true;
				end
			end
		else
			local item = map[id];
			if(item)then
				local position = item.position;
				if(position and position ~= "")then
					return true;
				end
			end
		end
	end
end
--return worldname,position,camera
--note: only available in teen version
function pe_aries_quest_item.get_goto_pos_info_teen(id,key)
	if(not id or not key)then return end
	if(WorldManager:IsInInstanceWorld())then
        _guihelper.MessageBox("你目前在副本当中，不能追踪！");
        return
    end
	if(key == "StartNPC" or key == "EndNPC" or key == "ClientDialogNPC" or key == "ClientExchangeItem")then
		local npc, worldname, npc_data = NPCList.GetNPCByIDAllWorlds(id);
		local facing = npc.facing or 0;
        facing = facing + 1.57
        local radius = 5;
        local end_pos = npc.position;
        if(end_pos)then
            local  x,y,z = end_pos[1],end_pos[2],end_pos[3];
            x = x + radius * math.sin(facing);
			z = z + radius * math.cos(facing);
            if(x and y and z)then
                local Position = {x,y,z, facing+1.57};
			    local CameraPosition = { 15, 0.27, facing + 1.57 - 1};
				return worldname,Position,CameraPosition;
			end
		end
	else
		local list,map;
		local world,position;
		local worldname;
		if(key == "Goal" or key == "GoalItem")then
			list,map = QuestHelp.GetGoalList();
		elseif(key == "ClientGoalItem")then
			list,map = QuestHelp.GetClientItemList();
		elseif(key == "FlashGame")then
			list,map = QuestHelp.GetFlashGameList();
		elseif(key == "CustomGoal")then
			list,map = QuestHelp.GetCustomGoalList();
		end
		if(map)then
			local item = map[id];
			if(item)then
				world = tonumber(item.world) or 0;
				position = item.position;
				worldname = item.worldname;
			end
		end
		if(world and position)then
			local x,y,z,camera_x,camera_y,camera_z;
			local all_info = QuestHelp.GetPosAndCameraFromString(position);
			if(all_info)then
				local len = #all_info;
				if(len > 0)then
					local index = math.random(len);
					local info = all_info[index];
					if(info)then
						local pos_info = info.pos;
						if(pos_info)then
							x,y,z = pos_info[1],pos_info[2],pos_info[3];
						end
						local camera_info = info.camera;
						if(camera_info)then
							camera_x,camera_y,camera_z = camera_info[1],camera_info[2],camera_info[3];
						end
					end
				end
			end
            
            if(x and y and z and camera_x and camera_y and camera_z )then
				if(not worldname)then
					worldname = QuestHelp.WorldNumToWorldName(world);
				end
                local Position = {x,y,z};
			    local CameraPosition = {camera_x,camera_y,camera_z};
				return worldname,Position,CameraPosition;
			end
		end
	end
end
function pe_aries_quest_item.goto_pos(s)
	if(not s)then return end
	local questid,id,key,instName = string.match(s,"(.+)_(.+)_(.+)@(.+)");
	questid = tonumber(questid);
    id = tonumber(id);
    if(not id or not key or not instName)then return end
	if(key == "ClientDialogNPC")then
		if(not QuestHelp.Jump_Enabled_Kids(questid,true))then
			return;
		end
	end
	--local worldname,position,camera;
	--if(System.options.version == "teen")then
		--worldname,position,camera = pe_aries_quest_item.get_goto_pos_info_teen(id,key);
	--else
		--if(key == "StartNPC" or key == "EndNPC" or key == "ClientDialogNPC" or key == "ClientExchangeItem")then
			--pe_aries_quest_item.goto_pos1(id,key);
		--else
			--pe_aries_quest_item.goto_pos2(id,key);
		--end
	--end
	NPL.load("(gl)script/apps/Aries/Quest/QuestTrackerPane.lua");
	local QuestTrackerPane = commonlib.gettable("MyCompany.Aries.Quest.QuestTrackerPane");
	QuestTrackerPane.DoJump(questid,id,key);

	if(pe_aries_quest_item.goto_map and pe_aries_quest_item.goto_map[instName])then
		local node = pe_aries_quest_item.goto_map[instName];
		local mcmlNode = node.mcmlNode;
		if(mcmlNode)then
			local ongoto = mcmlNode:GetString("ongoto") or "";
			local btnName = mcmlNode:GetAttributeWithCode("name"); 
			if(ongoto)then
				Map3DSystem.mcml_controls.OnPageEvent(mcmlNode, ongoto, btnName, mcmlNode,worldname,position,camera);
			end
		end
	end
	
end
function pe_aries_quest_item.goto_pos1(id,key)
	NPL.load("(gl)script/apps/Aries/Quest/NPCList.lua");
	local NPCList = commonlib.gettable("MyCompany.Aries.Quest.NPCList");
    if(not id or not key)then return end
	local npc, worldname, npc_data = NPCList.GetNPCByIDAllWorlds(id);

    local canpass = pe_aries_quest_item.checkIsInInstanceWorld();
    if(not canpass)then
        --自己是否在副本世界中
        return;
    end
    canpass = pe_aries_quest_item.checkInstanceWorld("byname",worldname);
    if(not canpass)then
        --副本不能跳转
        return;
    end
    canpass = pe_aries_quest_item.checkWorld("byname",worldname);
    if(not canpass)then
        --不在同一个世界
        return;
    end
    canpass = pe_aries_quest_item.checkVipWorld("byname",worldname);
    if(not canpass)then
        --vip世界只有vip可以跳转
        return;
    end
        
    if(npc)then
        local facing = npc.facing or 0;
        facing = facing + 1.57
        local radius = 5;
        local end_pos = npc.position;
        if(end_pos)then
            local  x,y,z = end_pos[1],end_pos[2],end_pos[3];
            x = x + radius * math.sin(facing);
			z = z + radius * math.cos(facing);
            if(x and y and z)then

                local Position = {x,y,z, facing+1.57};
			    local CameraPosition = { 15, 0.27, facing + 1.57 - 1};
                local msg = { aries_type = "OnMapTeleport", 
							position = Position, 
							camera = CameraPosition, 
							bCheckBagWeight = true,
							wndName = "map", 
							end_callback = function()
								-- automatically open dialog when talking to npc. added by Xizhi to simplify user actions.
								local npc_id = tonumber(npc.npc_id);
								if(npc_id) then
									local TargetArea = commonlib.gettable("MyCompany.Aries.Desktop.TargetArea");
									TargetArea.TalkToNPC(npc_id, nil, false);
								end	
							end
						};
				CommonCtrl.os.hook.Invoke(CommonCtrl.os.hook.HookType.WH_CALLWNDPROCRET, 0, "Aries", msg);
            end
        end
    end
end
function pe_aries_quest_item.goto_pos2(id,key)
	NPL.load("(gl)script/apps/Aries/Quest/QuestHelp.lua");
	local QuestHelp = commonlib.gettable("MyCompany.Aries.Quest.QuestHelp");
    if(not id or not key)then return end
    local list,map;
    local world,position;
    if(key == "Goal" or key == "GoalItem")then
        list,map = QuestHelp.GetGoalList();
    elseif(key == "ClientGoalItem")then
		list,map = QuestHelp.GetClientItemList();
	elseif(key == "FlashGame")then
		list,map = QuestHelp.GetFlashGameList();
	elseif(key == "CustomGoal")then
		list,map = QuestHelp.GetCustomGoalList();
    end
    if(map)then
        local item = map[id];
        if(item)then
            world = tonumber(item.world) or 0;
            position = item.position;
        end
    end
    if(world and position)then
        local canpass = pe_aries_quest_item.checkIsInInstanceWorld();
        if(not canpass)then
            --自己是否在副本世界中
            return;
        end
        canpass = pe_aries_quest_item.checkInstanceWorld("bynum",world);
        if(not canpass)then
            --副本不能跳转
            return;
        end
        canpass = pe_aries_quest_item.checkWorld("bynum",world);
        if(not canpass)then
            --不在同一个世界
            return;
        end
        canpass = pe_aries_quest_item.checkVipWorld("bynum",world);
        if(not canpass)then
            --vip世界只有vip可以跳转
            return;
        end
        if(position)then
            local x,y,z,camera_x,camera_y,camera_z;
			local all_info = QuestHelp.GetPosAndCameraFromString(position);
			if(all_info)then
				local len = #all_info;
				if(len > 0)then
					local index = math.random(len);
					local info = all_info[index];
					if(info)then
						local pos_info = info.pos;
						if(pos_info)then
							x,y,z = pos_info[1],pos_info[2],pos_info[3];
						end
						local camera_info = info.camera;
						if(camera_info)then
							camera_x,camera_y,camera_z = camera_info[1],camera_info[2],camera_info[3];
						end
					end
				end
			end
            
            if(x and y and z and camera_x and camera_y and camera_z )then
                local Position = {x,y,z};
			    local CameraPosition = {camera_x,camera_y,camera_z};
                local msg = { aries_type = "OnMapTeleport", 
							position = Position, 
							camera = CameraPosition, 
							bCheckBagWeight = true,
							wndName = "map", 
						};
					CommonCtrl.os.hook.Invoke(CommonCtrl.os.hook.HookType.WH_CALLWNDPROCRET, 0, "Aries", msg);
            end
        end
    end
end
function pe_aries_quest_item.getRequestQuestString(questid,templates,provider,ShowRequestQuestLink)
	NPL.load("(gl)script/apps/Aries/Combat/main.lua");
	local Combat = commonlib.gettable("MyCompany.Aries.Combat");
	local ItemManager = System.Item.ItemManager;
	local hasGSItem = ItemManager.IfOwnGSItem;
	local equipGSItem = ItemManager.IfEquipGSItem;
	NPL.load("(gl)script/apps/Aries/Quest/QuestHelp.lua");
	local QuestHelp = commonlib.gettable("MyCompany.Aries.Quest.QuestHelp");
	if(not questid or not templates or not provider)then return end
	local template = templates[questid];
    if(template)then
        local str = "";
        --前置条件
        local str_attr = "";
        --前置任务
        local str_quest = nil;

        local RequestAttr = template.RequestAttr;
        if(RequestAttr)then
            local len = #RequestAttr;
            if(len > 0)then
                local k,v;
                for k,v in ipairs(RequestAttr)do
                    local id = v.id;
                    local value = v.value;
                    id = tonumber(id)
                    value = tonumber(value) or 0
					if(CommonClientService.IsTeenVersion())then
						if(id == 214)then
							--战斗等级
							if(v.topvalue)then
								local topvalue = tonumber(v.topvalue);
								str_attr = string.format("战斗等级%d-%d级 %s",value,topvalue,str_attr);
							else
								str_attr = string.format("战斗等级%d级 %s",value,str_attr);
							end
						elseif(id == 0)then
							local name = "银币";
							if(v.topvalue)then
								local topvalue = tonumber(v.topvalue);
								str_attr = string.format("[%s]%d-%d个 %s",name,value,topvalue,str_attr);
							else
								str_attr = string.format("[%s]%d个 %s",name,value,str_attr);
							end
						elseif(id == 79033)then
							--本系攻击力
							if(v.topvalue)then
								local topvalue = tonumber(v.topvalue);
								str_attr = string.format("本系攻击力%d-%d %s",value,topvalue,str_attr);
							else
								str_attr = string.format("本系攻击力%d %s",value,str_attr);
							end
						elseif(id == 79034)then
							--最大防御力
							if(v.topvalue)then
								local topvalue = tonumber(v.topvalue);
								str_attr = string.format("最大防御力%d-%d %s",value,topvalue,str_attr);
							else
								str_attr = string.format("最大防御力%d %s",value,str_attr);
							end
						else
							local is_gsItem, __, gsItem = provider:OnlyGSItemIsValid(id);
							if(is_gsItem and gsItem)then
								local name = gsItem.template.name;
								if(v.topvalue)then
									local topvalue = tonumber(v.topvalue);
									str_attr = string.format("[%s]%d-%d个 %s",name,value,topvalue,str_attr);
								else
									str_attr = string.format("[%s]%d个 %s",name,value,str_attr);
								end
							end
						end
					else
						if(id == 214)then
							--战斗等级
							if(v.topvalue)then
								local topvalue = tonumber(v.topvalue);
								str_attr = string.format("战斗等级%d-%d级 %s",value,topvalue,str_attr);
							else
								str_attr = string.format("战斗等级%d级 %s",value,str_attr);
							end
						elseif(id == 79033)then
							--本系攻击力
							if(v.topvalue)then
								local topvalue = tonumber(v.topvalue);
								str_attr = string.format("本系攻击力%d%%-%d%% %s",value,topvalue,str_attr);
							else
								str_attr = string.format("本系攻击力%d%% %s",value,str_attr);
							end
						elseif(id == 79034)then
							--最大防御力
							if(v.topvalue)then
								local topvalue = tonumber(v.topvalue);
								str_attr = string.format("最大防御力%d%%-%d%% %s",value,topvalue,str_attr);
							else
								str_attr = string.format("最大防御力%d%% %s",value,str_attr);
							end
						elseif(id == 50351)then
							local name = "巨龙之牙";
							str_attr = string.format("具有[%s]信仰 %s",name,str_attr);
						elseif(id == 50352)then
							local name = "巨龙之爪";
							str_attr = string.format("具有[%s]信仰 %s",name,str_attr);
						elseif(id == 50353)then
							local name = "巨龙之鳞";
							str_attr = string.format("具有[%s]信仰 %s",name,str_attr);
						elseif(id == 50354)then
							local name = "巨龙之心";
							str_attr = string.format("具有[%s]信仰 %s",name,str_attr);
						elseif(id == 50359)then
							NPL.load("(gl)script/apps/Aries/Desktop/CombatCharacterFrame/TotemPage.lua");
							local TotemPage = commonlib.gettable("MyCompany.Aries.Desktop.TotemPage");
							local __,node = TotemPage.HasLearned();
							if(node and node.gsid)then
								local name = node.name or "";
								if(v.topvalue)then
									local topvalue = tonumber(v.topvalue);
									local __,__, min_level  = Combat.GetStatsFromDragonTotemProfessionAndExp(node.gsid, 50359, value);
									local __,__, max_level  = Combat.GetStatsFromDragonTotemProfessionAndExp(node.gsid, 50359, topvalue);
									--min_level = math.floor(min_level/3)+1
									--max_level = math.floor(max_level/3)+1
									str_attr = string.format("%s%d-%d级 %s",name,min_level,max_level,str_attr);
								else
									local __,__, min_level  = Combat.GetStatsFromDragonTotemProfessionAndExp(node.gsid, 50359, value);
									--min_level = math.floor(min_level/3)+1
									str_attr = string.format("%s%d级 %s",name,min_level,str_attr);
								end
							end
						elseif(id == 50362)then
							local name = "灵兽猎人";
							str_attr = string.format("成为[%s] %s",name,str_attr);
						elseif(id == 50363)then
							local name = "魔法鉴定师";
							str_attr = string.format("成为[%s] %s",name,str_attr);
						elseif(id == 50364)then
							local name = "魔法工匠";
							str_attr = string.format("成为[%s] %s",name,str_attr);
						elseif(id == 50355 or id == 50356 or id == 50357)then
							local name;
							local learned_gsid;
							local learned_exp_gsid = id;
							if(id == 50355)then
								name = "灵兽猎人";
								learned_gsid= 50362;
							elseif(id == 50356)then
								name = "魔法鉴定师";
								learned_gsid= 50363;
							elseif(id == 50357)then
								name = "魔法工匠";
								learned_gsid= 50364;
							end
							if(v.topvalue)then
								local topvalue = tonumber(v.topvalue);
								local __,__, min_level = Combat.GetStatsFromDragonTotemProfessionAndExp(learned_gsid, learned_exp_gsid, value);
								local __,__, max_level = Combat.GetStatsFromDragonTotemProfessionAndExp(learned_gsid, learned_exp_gsid, topvalue);
								str_attr = string.format("%s%d-%d级 %s",name,min_level,max_level,str_attr);
							else
								local __,__, min_level = Combat.GetStatsFromDragonTotemProfessionAndExp(learned_gsid, learned_exp_gsid, value);
								str_attr = string.format("%s%d级 %s",name,min_level,str_attr);
							end
						elseif(id == 0)then
							local name = "奇豆";
							if(v.topvalue)then
								local topvalue = tonumber(v.topvalue);
								str_attr = string.format("[%s]%d-%d个 %s",name,value,topvalue,str_attr);
							else
								str_attr = string.format("[%s]%d个 %s",name,value,str_attr);
							end
						else
							local is_gsItem, __, gsItem = provider:OnlyGSItemIsValid(id);
							if(is_gsItem and gsItem)then
								local name = gsItem.template.name;
								if(v.topvalue)then
									local topvalue = tonumber(v.topvalue);
									str_attr = string.format("[%s]%d-%d个 %s",name,value,topvalue,str_attr);
								else
									str_attr = string.format("[%s]%d个 %s",name,value,str_attr);
								end
							end
						end
					end
                    
                end
            end
        end
        local RequestQuest = template.RequestQuest;
        if(RequestQuest)then
            local len = #RequestQuest;
            local __,map = QuestHelp.GetAttrList();
            if(len > 0)then
                local k,v;
                for k,v in ipairs(RequestQuest)do
                    local id = v.id;
                    local value = v.value;
                    id = tonumber(id)
                    value = tonumber(value) or 0

                    local pre_template = templates[id];
                    if(pre_template)then
                        --目前前置任务 只判断一个
                        str_quest = string.format("完成%s",pre_template.Title or "");
						if(CommonClientService.IsTeenVersion() and ShowRequestQuestLink)then
							str_quest = string.format([[<input type="button" name="%s" value="%s" style="margin-left:2px;" onclick="MyCompany.Aries.mcml_controls.pe_aries_quest_item.show_quest_page"/>]],tostring(id),str_quest);
						end
                        break;
                    end
                end
            end
        end
        local state = provider:GetState(questid);
		str = string.format("%s %s",str_attr or "",str_quest or "");
        --if(str_attr and str_quest)then
            --str = string.format("战斗等级%s %s",str_attr,str_quest);
        --elseif(str_attr)then
            --str = string.format("战斗等级%s",str_attr);
        --elseif(str_quest)then
            --str = string.format("%s",str_quest);
        --end
        if(state == 9)then
            str = string.format([[<div style="color:#c70f36;float:left">%s</div>]],str);
        end
		str = string.format([[<div>%s</div>]],str or "");
        return str;
    end
end
function pe_aries_quest_item.show_quest_page(id)
	id = tonumber(id);
	if(not id)then return end
	NPL.load("(gl)script/apps/Aries/Quest/QuestPane.lua");
	local QuestPane = commonlib.gettable("MyCompany.Aries.Quest.QuestPane");
	QuestPane.ShowPage("template_quest",id);
end
function pe_aries_quest_item.buildGoalString(instName,template,questid,provider,property)
	NPL.load("(gl)script/apps/Aries/Quest/QuestHelp.lua");
	local QuestHelp = commonlib.gettable("MyCompany.Aries.Quest.QuestHelp");
	if(instName and template and provider and property)then
		local progress_list = pe_aries_quest_item.goalProgress(template,questid,provider,property);

		if(progress_list)then
			local map;
			local info = "";
			local show_goto_btn;
			local type_str_1;
			local type_str_2;
			if(property == "Goal")then
				local __,_map = QuestHelp.GetGoalList();
				map = _map;
				show_goto_btn = true;
				type_str_1 = "消灭";
				type_str_2 = "个";
			elseif(property == "GoalItem")then
				local __,_map = QuestHelp.GetQuestItemList();
				map = _map;
				show_goto_btn = true;
				type_str_1 = "找到";
				type_str_2 = "个";
			elseif(property == "ClientGoalItem")then
				local __,_map = QuestHelp.GetClientItemList();
				map = _map;
				show_goto_btn = false;
				type_str_1 = "收集";
				type_str_2 = "个";
			elseif(property == "ClientExchangeItem")then
				local __,_map = QuestHelp.GetClientExchangeItemList();
				map = _map;
				show_goto_btn = true;
				type_str_1 = "合成";
				type_str_2 = "次";
			elseif(property == "FlashGame")then
				local __,_map = QuestHelp.GetFlashGameList();
				map = _map;
				show_goto_btn = true;
				type_str_1 = "玩小游戏";
				type_str_2 = "次";
			elseif(property == "ClientDialogNPC")then
				local __,_map = QuestHelp.GetNpcList();
				map = _map;
				show_goto_btn = true;
				type_str_1 = "对话";
				type_str_2 = "次";
			elseif(property == "CustomGoal")then
				local __,_map = QuestHelp.GetCustomGoalList();
				map = _map;
				show_goto_btn = false;
				type_str_1 = "获得";
				type_str_2 = "个";
			end
			local function CanShowAutoTip()
				NPL.load("(gl)script/apps/Aries/Pet/main.lua");
				local bean = MyCompany.Aries.Pet.GetBean();
				if(bean and bean.combatlel <= 3 and System.options.version and System.options.version == "kids") then
					return true;
				end
			end
			if(map)then
				for k,v in ipairs(progress_list)do
					local mobid = v.id;
					
					local item = map[mobid]
					local label = "";
					--自定义显示标签
					local customlabel;
					local cur_value = v.cur_value or 0;
					local req_value = v.req_value or 0;
					if(item)then
						label = item.label;
						customlabel = item.customlabel;
					end
					local temp_map = map;
					--合成只能在这个位置
					if(property == "ClientExchangeItem")then
						mobid = 30345;
					elseif(property == "GoalItem")then
						mobid =  v.producer_id or 0;
						__,temp_map = QuestHelp.GetGoalList();
					end
					local has_pos = pe_aries_quest_item.has_pos(property,temp_map,mobid);
					local has_help_func,func_str = pe_aries_quest_item.has_help_func(property,temp_map,mobid);
					local goto_btn_str = "";
					if(has_pos)then
						if(CanShowAutoTip())then
							goto_btn_str = string.format([[<input type="button" name="%d_%d_%s@%s" onclick="MyCompany.Aries.mcml_controls.pe_aries_quest_item.goto_pos" tooltip="立即过去" style="width:25px;height:21px;margin-top:-4px;background:url(Texture/Aries/Quest/QuestList/jumparrow_32bits.png#0 0 25 21)"/>
							<pe:arrowpointer name="p_%d_%s@%s" direction="1" style="float:left;position:relative;margin-left:10px;margin-top:-45px;width:32px;height:32px;" />]],questid,mobid,property,instName,mobid,property,instName);
							if(pe_aries_quest_item.IsTeen())then
								goto_btn_str = string.format([[<input type="button" name="%d_%d_%s@%s" onclick="MyCompany.Aries.mcml_controls.pe_aries_quest_item.goto_pos" tooltip="立即过去" style="width:16px;height:16px;margin-top:2px;background:url(Texture/Aries/Common/ThemeTeen/others/quest_jump_stone_32bits.png)"/>
							<pe:arrowpointer name="p_%d_%s@%s" direction="1" style="float:left;position:relative;margin-left:10px;margin-top:-45px;width:32px;height:32px;" />]],questid,mobid,property,instName,mobid,property,instName);
							end
						else
							goto_btn_str = string.format([[<input type="button" name="%d_%d_%s@%s" onclick="MyCompany.Aries.mcml_controls.pe_aries_quest_item.goto_pos" tooltip="立即过去" style="width:25px;height:21px;margin-top:-4px;background:url(Texture/Aries/Quest/QuestList/jumparrow_32bits.png#0 0 25 21)"/>]],questid,mobid,property,instName);
							if(pe_aries_quest_item.IsTeen())then
								goto_btn_str = string.format([[<input type="button" name="%d_%d_%s@%s" onclick="MyCompany.Aries.mcml_controls.pe_aries_quest_item.goto_pos" tooltip="立即过去" style="width:16px;height:16px;margin-top:2px;background:url(Texture/Aries/Common/ThemeTeen/others/quest_jump_stone_32bits.png)"/>]],questid,mobid,property,instName);
							end
						end
					elseif(has_help_func)then
						goto_btn_str = string.format([[<input type="button" name="%d_%s@%s@%s" onclick="MyCompany.Aries.mcml_controls.pe_aries_quest_item.do_help_func" tooltip="立即过去" style="width:25px;height:21px;margin-top:-4px;background:url(Texture/Aries/Quest/QuestList/jumparrow_32bits.png#0 0 25 21)"/>]],mobid,property,instName,func_str or "");
						if(pe_aries_quest_item.IsTeen())then
							goto_btn_str = string.format([[<input type="button" name="%d_%s@%s@%s" onclick="MyCompany.Aries.mcml_controls.pe_aries_quest_item.do_help_func" tooltip="立即过去" style="width:16px;height:16px;margin-top:2px;background:url(Texture/Aries/Common/ThemeTeen/others/quest_jump_stone_32bits.png)"/>]],mobid,property,instName,func_str or "");
						end
					end
					local s;
					if(CommonClientService.IsTeenVersion())then
						s = string.format([[<div>%s<span style="color:#9cff98">【%s】</span>%d%s(%d/%d)%s</div><br/>]],type_str_1,label,req_value,type_str_2,cur_value,req_value,goto_btn_str);
					else
						s = string.format([[<div>%s【%s】%d%s(%d/%d)%s</div><br/>]],type_str_1,label,req_value,type_str_2,cur_value,req_value,goto_btn_str);
					end
					--自定义显示任务标签
					if(customlabel)then
						customlabel = string.format(customlabel,req_value);
						s = string.format([[<div>%s(%d/%d)%s</div><br/>]],customlabel,cur_value,req_value,goto_btn_str);
					end
					info = info .. s;
				end
			end
			info = string.format([[<div>%s</div>]],info);
			return info;
		end
	end
end
function pe_aries_quest_item.hasReward(template)
     if(template)then
        local v = template["Reward"];
        if(v and v[1])then
            local len = #v[1];
            if(len > 0)then
                return true;
            end
        end
    end
end
--index:0 自动发放 1 手动选择
function pe_aries_quest_item.hasReward_state(template,index)
     if(template and index)then
        index = index + 1;
        local v = template["Reward"];
        if(v and v[index])then
            local len = #v[index];
            if(len > 0)then
                return true;
            end
        end
    end
end
--额外奖励是否 全部自动选中
function pe_aries_quest_item.getReward_1_isAllAutoChecked(template)
     if(template)then
        local v = template["Reward"];
        if(v and v[2])then
            local info = "";
            local list = v[2];
            local choice = list.choice or 0;
            local k,v;
            local len = #list;
            if(choice >= len)then
                return true;
            end
        end
    end
end
function pe_aries_quest_item.getReward_0(template)
	NPL.load("(gl)script/apps/Aries/Quest/QuestHelp.lua");
	local QuestHelp = commonlib.gettable("MyCompany.Aries.Quest.QuestHelp");

     if(template)then
        local __,map = QuestHelp.GetRewardList();
        local v = template["Reward"];
        if(v and v[1] and map)then
            local info = "";
            local list = v[1];
            local k,v;
            for k,v in ipairs(list) do
                local id = v.id;
                local value = v.value;
                local label = "";
                local item = map[id];
                if(item)then
                    label = item.label;
                end
                local s;
				if(CommonClientService.IsTeenVersion())then
					s = string.format([[<span style="color:#ffea8f">%s:%d</span>]],label,value);
				else
					s = string.format([[<span>%s:%d</span>]],label,value);
				end
                info = info .. s;
            end
            info = string.format([[<div>任务奖励：<span style="font-weight:bold;">%s</span></div>]],info);
            return info;
        end
    end
end
function pe_aries_quest_item.getReward_1(template,quest_can_finished)
	NPL.load("(gl)script/apps/Aries/Quest/QuestHelp.lua");
	local QuestHelp = commonlib.gettable("MyCompany.Aries.Quest.QuestHelp");
	NPL.load("(gl)script/kids/3DMapSystemItem/ItemManager.lua");
	local ItemManager = commonlib.gettable("Map3DSystem.Item.ItemManager");

     if(template)then
        local __,map = QuestHelp.GetRewardList();
        local v = template["Reward"];
        if(v and v[2] and map)then
            local info = "";
            local list = v[2];
            local choice = list.choice or 0;
            local k,v;
            local len = #list;
            local allChecked="false";
            if(choice >= len)then
                allChecked = "true";
            end
            for k,v in ipairs(list) do
                local id = v.id;
                local value = v.value;
                local label = "";
                local item = map[id];
                if(item)then
                    label = item.label;
                end
                local checked = allChecked;
                local s;
                local width = 36;
                local height = 36;
                local path;
                local gsItem = ItemManager.GetGlobalStoreItemInMemory(id);
                local img = "";
                if(gsItem) then
					local isCard = false;
					if(id >= 22101 and id <= 22999) then
						isCard = true;
					elseif(id >= 41101 and id <= 41999) then
						isCard = true;
					elseif(id >= 42101 and id <= 42999) then
						isCard = true;
					elseif(id >= 43101 and id <= 43999) then
						isCard = true;
					elseif(id >= 44101 and id <= 44999) then
						isCard = true;
					end
                    if(isCard) then
                       path = string.format("%s;0 0 45 44",gsItem.descfile);
                        img = string.format([[<pe:item gsid="%d" icon="%s" isclickable="false" showdefaulttooltip="true" style="float:left;width:%dpx;height:%dpx;"/>]],id,path,width,height);
                    else
                       path = gsItem.icon;
                       img = string.format([[<pe:item gsid="%d" isclickable="false" showdefaulttooltip="true" style="float:left;width:%dpx;height:%dpx;"/>]],id,width,height);

                    end
                end
                path = path or "Texture/alphadot.png";
                if(quest_can_finished)then
                    if(allChecked == "true")then
                        local item_str = string.format([[<div style="float:left;">%s<div style="float:left;margin-left:2px;margin-top:15px;">x%d</div></div>]],img,value);
                        s = string.format([[<div>%s</div><br/>]],item_str);
                    else
                        local item_str = string.format([[<div style="float:left;">%s<div style="float:left;margin-left:2px;margin-top:15px;">x%d</div></div>]],img,value);
                        s = string.format([[<div>%s<input style="float:left;margin-left:2px;margin-top:15px;" type="radio" name="reward_group" max="%d" value="%d" checked="%s"/></div><br/>]],item_str,choice,k,checked);
                    end
                else
                    s = string.format([[<div style="float:left;">%s<div style="float:left;margin-left:2px;margin-top:15px;">x%d</div></div>]],img,value);
                end
                info = info .. s;
            end
            if(allChecked == "true")then
                info = string.format([[<div><b>你还可以得到：</b><br/>%s</div>]],info);
            else
                info = string.format([[<div><b>你还可以选择其中%d项：</b><br/>%s</div>]],choice or 0,info);
            end
            return info;
        end
    end
end
function pe_aries_quest_item.getNpcString(questid,instName,template,key)
	NPL.load("(gl)script/apps/Aries/Quest/QuestHelp.lua");
	local QuestHelp = commonlib.gettable("MyCompany.Aries.Quest.QuestHelp");
	NPL.load("(gl)script/apps/Aries/Quest/NPCList.lua");
	local NPCList = commonlib.gettable("MyCompany.Aries.Quest.NPCList");
	if(not template or not key)then return end
	local item;
	local __,map = QuestHelp.GetNpcList();
    if(template and key and map)then
        local v = template[key];
        if(v)then
            item = map[v];
        end
    end
	if(not item)then
		return
	end
	local id = item.id;
	local name = item.label or "";
	local place = item.place or "";
	if(id and place)then
		local str = "";
		local npc, worldname, npc_data = NPCList.GetNPCByIDAllWorlds(id);
		local world_info = WorldManager:GetWorldInfo(worldname);
		
		local goto_btn_str = string.format([[<input type="button" name="%d_%d_%s@%s" onclick="MyCompany.Aries.mcml_controls.pe_aries_quest_item.goto_pos" tooltip="立即过去" style="width:25px;height:21px;margin-top:-4px;background:url(Texture/Aries/Quest/QuestList/jumparrow_32bits.png#0 0 25 21)"/>]],questid,id,key,instName);
		if(pe_aries_quest_item.IsTeen())then
			goto_btn_str = string.format([[<input type="button" name="%d_%d_%s@%s" onclick="MyCompany.Aries.mcml_controls.pe_aries_quest_item.goto_pos" tooltip="立即过去" style="width:16px;height:16px;margin-top:2px;background:url(Texture/Aries/Common/ThemeTeen/others/quest_jump_stone_32bits.png)"/>]],questid,id,key,instName);
		end
		local label = world_info.world_title or "";
		if(place == "")then
			str = string.format([[<div>%s(%s)%s</div>]],name,label,goto_btn_str)
		else
			if(QuestHelp.InSameWorldByKey(worldname))then
				str = string.format([[<div>%s(%s)%s</div>]],name,place,goto_btn_str)
			else
				str = string.format([[<div>%s(%s,%s)%s</div>]],name,label,place,goto_btn_str)
			end
		end
		return str;
	end
end
	
pe_aries_quest_item.goto_map = {};
function pe_aries_quest_item.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	NPL.load("(gl)script/apps/Aries/Quest/QuestHelp.lua");
	local QuestHelp = commonlib.gettable("MyCompany.Aries.Quest.QuestHelp");

	NPL.load("(gl)script/apps/Aries/Quest/QuestClientLogics.lua");
	local QuestClientLogics = commonlib.gettable("MyCompany.Aries.Quest.QuestClientLogics");

	NPL.load("(gl)script/kids/3DMapSystemItem/ItemManager.lua");
	local ItemManager = commonlib.gettable("Map3DSystem.Item.ItemManager");

	if(type(childnode) == "table" and childnode.name =="aries:quest_item")then
			childnode.questid = questid;
		end
	local parentNode = mcmlNode:GetParent("aries:quest");
	local questid;
	if(parentNode)then
		questid = parentNode:GetAttributeWithCode("questid",nil,true);
	end
	questid = tonumber(questid);
	if(not questid)then return end
	local provider = QuestClientLogics.GetProvider();
	local templates = provider:GetTemplateQuests();
	local template;
	if(templates)then
		template = templates[questid];
	end
	if(not template)then return end
	local property = mcmlNode:GetAttributeWithCode("property");
	local value = template[property];
	if(property and property == "Title_Track")then
		value = template["Title"];
	end
	--任务类型：0 主线任务，1 支线任务
	local QuestGroup1 = template.QuestGroup1 or 0;
	local TimeStamp = template.TimeStamp;
	local WeekRepeat = template.WeekRepeat;
	local function get_bool(key)
		if(not key)then return end
		local v = mcmlNode:GetAttributeWithCode(key) or "";
		if(v == "true" or v == "True")then
			v = true
		else
			v = false;
		end
		return v;
	end
	local instName = mcmlNode:GetInstanceName(rootName);
	pe_aries_quest_item.goto_map[instName] = {mcmlNode = mcmlNode,};

	local css = mcmlNode:GetStyle(mcml_controls.pe_css.default[mcmlNode.name], style) or {};

	local function createNode(textbuffer)
		if(not textbuffer or textbuffer == "")then return end
		--local childNode = mcmlNode:GetChild("div");
		local childNode;
		if(not childNode) then
			local xmlRoot = ParaXML.LuaXML_ParseString(textbuffer);
			if(type(xmlRoot)=="table" and table.getn(xmlRoot)>0) then
				local xmlRoot = Map3DSystem.mcml.buildclass(xmlRoot);
				childNode = xmlRoot[1];
				mcmlNode:AddChild(childNode);
			end	
		end
		if(childNode) then
			Map3DSystem.mcml_controls.create(rootName,  childNode, bindingContext, _parent, left, top, width, height, css, parentLayout);
		end
	end
	if(property == "Id" or property == "Title" or property == "Title_Track" or property == "Detail" or property == "RecommendLevel" or property == "RecommendMembers")then
		local textbuffer = tostring(value);
		if(textbuffer)then
			
			if(property == "Title_Track")then
				local canAccept = provider:CanAccept(questid);
				local canFinished = provider:CanFinished(questid);
	            local hasAccept = provider:HasAccept(questid);
				local s = "";

				local color = "#00fefa";
				local state = "";
				if(canAccept)then
					state = "(可接)";
				elseif(hasAccept and canFinished)then
					state = "(完成)";
				elseif(hasAccept and not canFinished)then
					state = "(进行)";
				end
				if(TimeStamp)then
					color = "#ffed74";
					if(TimeStamp == 0)then
						s = "[每日]"
					elseif(TimeStamp == 1)then
						s = "[每周]"
					end
				end
				if(QuestGroup1 == 1)then
					textbuffer = string.format([[<div style="color:%s">%s%s(支线)%s</div>]],color,s,textbuffer,state);
				else
					textbuffer = string.format([[<div style="color:%s">%s%s%s</div>]],color,s,textbuffer,state);
				end
			else
				if(property == "Title" and System.options.isAB_SDK)then
					textbuffer = string.format("%s(%d)",textbuffer,questid);
				end
				if(property == "RecommendMembers")then
					local arr = commonlib.split(textbuffer,"#")
					if(arr and #arr > 1)then
						textbuffer = string.format("%s-%s",arr[1],arr[2]);
					end
				end
				textbuffer = string.format([[<span>%s</span>]],textbuffer);
			end
			createNode(textbuffer);
		end
	elseif(property == "Goal" or property == "GoalItem" or property == "ClientGoalItem" or property == "ClientExchangeItem" or property == "FlashGame" or property == "ClientDialogNPC" or property == "CustomGoal")then
		local hasValue = pe_aries_quest_item.tableHasValue(template,property);
		if(hasValue)then
			local textbuffer = pe_aries_quest_item.buildGoalString(instName,template,questid,provider,property);
			createNode(textbuffer);
		end

	elseif(property == "RequestAttr" or property == "RequestQuest" )then
		local hasValue = pe_aries_quest_item.tableHasValue(template,"RequestAttr") or pe_aries_quest_item.tableHasValue(template,"RequestQuest");
		if(hasValue)then
			local ShowRequestQuestLink = mcmlNode:GetBool("ShowRequestQuestLink");
			local textbuffer = pe_aries_quest_item.getRequestQuestString(questid,templates,provider,ShowRequestQuestLink);
			createNode(textbuffer);
		end
	elseif(property == "TimeStamp")then
		if(QuestHelp.HasTimeStamp(questid))then
			local textbuffer = QuestHelp.GetTimeStampString(questid);
			textbuffer = string.format("<div>%s</div>",textbuffer or "");
			createNode(textbuffer);
		end
	elseif(property == "WeekRepeat")then
		local __,template = QuestWeekRepeat.HasTemplate(WeekRepeat);
		if(template)then
			local textbuffer = string.format("<div>%s</div>",template.label or "");
			createNode(textbuffer);
		end
	--显示全部奖励
	elseif(property == "Reward")then
		if(pe_aries_quest_item.hasReward_state(template,0))then
			local textbuffer = pe_aries_quest_item.getReward_0(template);
			createNode(textbuffer);
		end
		if(pe_aries_quest_item.hasReward_state(template,1))then
			local quest_can_finished = provider:CanFinished(questid);
			local textbuffer = pe_aries_quest_item.getReward_1(template,quest_can_finished);
			createNode(textbuffer);
		end
	--显示奖励分类0
	elseif(property == "Reward_0")then
		if(pe_aries_quest_item.hasReward_state(template,0))then
			local textbuffer = pe_aries_quest_item.getReward_0(template);
			createNode(textbuffer);
		end
	--显示奖励分类1
	elseif(property == "Reward_1")then
		if(pe_aries_quest_item.hasReward_state(template,1))then
			local quest_can_finished = provider:CanFinished(questid);
			local textbuffer = pe_aries_quest_item.getReward_1(template,quest_can_finished);
			createNode(textbuffer);
		end
	elseif(property == "StartNPC" or property == "EndNPC")then
		local textbuffer = pe_aries_quest_item.getNpcString(questid,instName,template,property);
		createNode(textbuffer);
	end
end
function pe_aries_quest_repeat_item.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	NPL.load("(gl)script/apps/Aries/Quest/QuestHelp.lua");
	local QuestHelp = commonlib.gettable("MyCompany.Aries.Quest.QuestHelp");

	NPL.load("(gl)script/apps/Aries/Quest/QuestClientLogics.lua");
	local QuestClientLogics = commonlib.gettable("MyCompany.Aries.Quest.QuestClientLogics");

	NPL.load("(gl)script/kids/3DMapSystemItem/ItemManager.lua");
	local ItemManager = commonlib.gettable("Map3DSystem.Item.ItemManager");
	local property = mcmlNode:GetAttributeWithCode("property");
	local parentNode = mcmlNode:GetParent("aries:quest");
	local questid;
	if(parentNode)then
		questid = parentNode:GetAttributeWithCode("questid",nil,true);
	end
	questid = tonumber(questid);
	if(not questid)then return end
	local provider = QuestClientLogics.GetProvider();
	local template = QuestHelp.BuildQuestShowInfo(questid,true);
	if(not template)then return end
	local property = mcmlNode:GetAttributeWithCode("property");
	if(property == "Goal" or property == "GoalItem" or property == "ClientGoalItem" or property == "ClientExchangeItem" or property == "FlashGame" or property == "ClientDialogNPC" or property == "CustomGoal")then
		local value = template[property];
		if(value and type(value) == "table")then
			--标记任务id
			local k,v;
			for k,v in ipairs(value) do
				v._internal_quest_id = questid;
			end
			mcmlNode:SetAttribute("DataSource",value);
			Map3DSystem.mcml_controls.pe_repeat.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
		end
	end
end