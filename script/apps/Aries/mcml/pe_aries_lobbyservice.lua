--[[
Title: 
Author(s): Leio
Date: 2011/08/16
Desc: 

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/mcml/pe_aries_lobbyservice.lua");
-------------------------------------------------------
]]
	
NPL.load("(gl)script/apps/Aries/Service/CommonClientService.lua");
local CommonClientService = commonlib.gettable("MyCompany.Aries.Service.CommonClientService");	
local pe_aries_lobbyservice_template = commonlib.gettable("MyCompany.Aries.mcml_controls.pe_aries_lobbyservice_template");
local pe_aries_lobbyservice_template_item = commonlib.gettable("MyCompany.Aries.mcml_controls.pe_aries_lobbyservice_template_item");

NPL.load("(gl)script/apps/Aries/Quest/NPCList.lua");
local NPCList = commonlib.gettable("MyCompany.Aries.Quest.NPCList");

NPL.load("(gl)script/apps/Aries/Scene/WorldManager.lua");
local WorldManager = commonlib.gettable("MyCompany.Aries.WorldManager");

function pe_aries_lobbyservice_template.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local childnode;
	for childnode in mcmlNode:next() do
		Map3DSystem.mcml_controls.create(rootName, childnode, bindingContext, _parent, left, top, width, height, style, parentLayout);
	end
end
function pe_aries_lobbyservice_template_item.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	NPL.load("(gl)script/apps/Aries/CombatRoom/LobbyClientServicePage.lua");
	local LobbyClientServicePage = commonlib.gettable("MyCompany.Aries.CombatRoom.LobbyClientServicePage");
	local parentNode = mcmlNode:GetParent("aries:lobbyservice_template");
	local keyname;
	local search_worldname;
	if(parentNode)then
		keyname = parentNode:GetAttributeWithCode("keyname",nil,true);
		search_worldname = parentNode:GetAttributeWithCode("worldname",nil,true);
	end
	local property = mcmlNode:GetAttributeWithCode("property");
	local tempaltes = LobbyClientServicePage.GetGameTemplates();
    local template;
	--先找worldname
	if(search_worldname)then
		local k,v;
		for k,v in pairs(tempaltes) do
			if(v and v.worldname == search_worldname)then
				template = v;
				break;
			end
		end
	elseif(keyname)then
		template = tempaltes[keyname];
	end
	if(not template)then
		return
	end
	if(property == "loots_menu")then
		NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_togglebuttons.lua");
		local pe_togglebuttons = commonlib.gettable("Map3DSystem.mcml_controls.pe_togglebuttons");

		local mode = template.mode_list or "1,2,3";
		local selected_mode = parentNode:GetAttributeWithCode("selected_mode",nil,true) or 1;
		local onclick = mcmlNode:GetAttributeWithCode("onclick",nil,true);
		local OnlyShowSelectedMode = mcmlNode:GetBool("OnlyShowSelectedMode");
		local mode_list = LobbyClientServicePage.LoadModeList(keyname)

		local result = {};
		local k,v;
		for k,v in ipairs(mode_list) do
			
			local label = v.lable_1 or "";
			label = label.."难度掉落";
			local node = { label = label, mode = v.mode, };
			if(selected_mode == v.mode)then
				node.selected = true;
			end
			if(OnlyShowSelectedMode)then
				if(node.selected)then
					table.insert(result,node);
				end
			else
				table.insert(result,node);
			end
		end
		mcmlNode:SetAttribute("DataSource",result);
		mcmlNode:SetAttribute("onclick",onclick);
		pe_togglebuttons.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	elseif(property == "pic")then
		local worldname = template.worldname;
		local pic = template.pic;
		local usesmaller = mcmlNode:GetBool("usesmaller");
		if(not pic)then
			if(CommonClientService.IsKidsVersion())then
				pic = string.format("Texture/Aries/LobbyService/WorldPic/%s.png",worldname);
			else
				if(usesmaller)then
					pic = string.format("Texture/Aries/LobbyService/WorldPic/Teen/%s_64.png",worldname);
				else
					pic = string.format("Texture/Aries/LobbyService/WorldPic/Teen/%s.png",worldname);
				end
			end
		end
		mcmlNode:SetAttribute("src", pic);
		Map3DSystem.mcml_controls.pe_img.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout);
	elseif(property == "worldname" or property == "world_label" or property == "world_description" )then
		local value;
		if(property == "worldname")then
			value = template.worldname;
		elseif(property == "world_label")then
			value = template.name;
		elseif(property == "world_description")then
			value = template.desc;
		end
		mcmlNode:SetInnerText(value);
		Map3DSystem.mcml_controls.pe_simple_styles.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout);
	end
end
local pe_aries_lobbyservice = commonlib.gettable("MyCompany.Aries.mcml_controls.pe_aries_lobbyservice");
local pe_aries_lobbyservice_item = commonlib.gettable("MyCompany.Aries.mcml_controls.pe_aries_lobbyservice_item");
function pe_aries_lobbyservice.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local childnode;
	for childnode in mcmlNode:next() do
		Map3DSystem.mcml_controls.create(rootName, childnode, bindingContext, _parent, left, top, width, height, style, parentLayout);
	end
end
function pe_aries_lobbyservice_item.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	NPL.load("(gl)script/apps/Aries/CombatRoom/LobbyClientServicePage.lua");
	local LobbyClientServicePage = commonlib.gettable("MyCompany.Aries.CombatRoom.LobbyClientServicePage");
	local parentNode = mcmlNode:GetParent("aries:lobbyservice");
	local gameinfo;
	if(parentNode)then
		gameinfo = parentNode:GetAttributeWithCode("gameinfo",nil,true);
	end
	if(not gameinfo)then return end
	local property = mcmlNode:GetAttributeWithCode("property");
	local label = mcmlNode:GetAttributeWithCode("label");
	local tempaltes = LobbyClientServicePage.GetGameTemplates();
	local keyname = gameinfo.keyname;
    local template = tempaltes[keyname];
	if(not template)then
		return
	end
	if(property == "pic")then
		local worldname = template.worldname;
		local pic = template.pic;
		if(not pic)then
			pic = string.format("Texture/Aries/LobbyService/WorldPic/%s.png",worldname);
		end
		mcmlNode:SetAttribute("src", pic);
		Map3DSystem.mcml_controls.pe_img.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout);
	elseif(property == "worldname" or property == "world_label" or property == "world_label_and_level_range" or property == "world_description" )then
		local value;
		if(property == "worldname")then
			value = template.worldname;
		elseif(property == "world_label_and_level_range")then
			local name = template.name;
			local min_level = template.min_level or 0;
			local max_level = template.max_level or 100;
			--value = string.format("%s(%d-%d)",name,min_level,max_level);
			value = string.format("%s(%d)",name,min_level);
		elseif(property == "world_label")then
			value = template.name;
		elseif(property == "world_description")then
			value = template.desc;
		end
		value = tostring(value) ;
		if(not value or value == "" or value == "nil")then
			value = "无";
		end
		if(not label or label == "" or label == "nil")then
			value = string.format("%s",value);
		else
			value = string.format("%s:%s",label or "",value);
		end
		mcmlNode:SetInnerText(value);
		Map3DSystem.mcml_controls.pe_simple_styles.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout);
	elseif(property == "id" or property == "name" or property == "leader_text" 
			or property == "min_level" or property == "max_level" 
			or property == "status" or property == "player_count" 
			or property == "requirement_tag" or property == "max_players" 
			or property == "password" or property == "owner_nid" 
			or property == "magic_star_level" or property == "attack" 
			or property == "hit" or property == "hp" 
			or property == "mode" 
			or property == "cure" or property == "guard_map" )then

			local value = gameinfo[property];
			if(property == "mode")then
				value = value or 1;
				if(value == 1)then
					value = "简单";
				elseif(value == 2)then
					value = "普通";
				elseif(value == 3)then
					value = "精英";
				end
			elseif(property == "requirement_tag")then
				if(value)then
					value = string.gsub(value,"storm","风暴系")
					value = string.gsub(value,"fire","烈火系")
					value = string.gsub(value,"life","生命系")
					value = string.gsub(value,"death","死亡系")
					value = string.gsub(value,"ice","寒冰系")
				end
			elseif(property == "guard_map")then
				local function get_value(guard_map,key,label)
					if(guard_map)then
						local v = guard_map[key];
						v = tostring(v);
						if(v and v ~= "" and v ~= "nil")then
							v = string.format("%s %s%%",label,v);
							return v;
						end
					end
				end
				local function link_str(v1,v2)
					if(v1 and v2 and v1~="" and v2~="")then
						local v = string.format("%s,%s",v1,v2);
						return v;
					end
				end
				local s = "";
				local v = get_value(value,"storm","风暴");
				if(v)then
					s = v;
				end
				v = get_value(value,"fire","烈火");
				if(v)then
					s = s..","..v;
				end
				v = get_value(value,"life","生命");
				if(v)then
					s = s..","..v;
				end
				v = get_value(value,"death","死亡");
				if(v)then
					s = s..","..v;
				end
				v = get_value(value,"ice","寒冰");
				if(v)then
					s = s..","..v;
				end
				
				value = s;
			else
				value = tostring(value) ;
			end

			if(not value or value == "" or value == "nil")then
				value = "无";
			end
			if(not label or label == "" or label == "nil")then
				value = string.format("%s",value);
			else
				if(value == "无")then
					value = "";
				else
					value = string.format("%s:%s",label or "",value);
				end
			end
			mcmlNode:SetInnerText(value);
			Map3DSystem.mcml_controls.pe_simple_styles.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout);
	end
end