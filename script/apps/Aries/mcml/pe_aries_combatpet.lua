--[[
Title: 
Author(s): Leio
Date: 2011/07/19
Desc: 
---++ aries:combatpet attributes 
| gsid | pet gsid |
| show_icon | show the pet icon, grey icon is shown if we do not own the pet |
| show_if_not_owned | default to false. if true, it will hide the entire mcml node if the current user already owned the pet. plus it will show full color icon instead of greyed icon. |
| click_teleport | if true, clicking the icon will automatically teleport to the place where we can catch the pet. |
| enable_tooltip | true to enable mouseover tooltip |
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/mcml/pe_aries_combatpet.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Service/CommonClientService.lua");
local CommonClientService = commonlib.gettable("MyCompany.Aries.Service.CommonClientService");		
local pe_aries_combatpet = commonlib.gettable("MyCompany.Aries.mcml_controls.pe_aries_combatpet");
local pe_aries_combatpet_item = commonlib.gettable("MyCompany.Aries.mcml_controls.pe_aries_combatpet_item");
local Combat = commonlib.gettable("MyCompany.Aries.Combat");
NPL.load("(gl)script/kids/3DMapSystemItem/ItemManager.lua");
local ItemManager = commonlib.gettable("Map3DSystem.Item.ItemManager");
NPL.load("(gl)script/apps/Aries/Scene/main.lua");
local Scene = commonlib.gettable("MyCompany.Aries.Scene");

function pe_aries_combatpet.render_callback(mcmlNode, rootName, bindingContext, _parent, left, top, right, bottom, myLayout, css)
	local gsid = tonumber(mcmlNode:GetAttributeWithCode("gsid", nil, true));

	if(gsid) then
		local gsItem = ItemManager.GetGlobalStoreItemInMemory(gsid);
		if(gsItem) then
			local show_icon = mcmlNode:GetBool("show_icon");
			local use_trans = mcmlNode:GetBool("use_trans");
			
			if(show_icon) then
				local bOwn = ItemManager.IfOwnGSItem(gsid);
				local show_if_not_owned = mcmlNode:GetBool("show_if_not_owned");
				if(show_if_not_owned and bOwn) then
					return;
				end
				local icon = gsItem.icon;
				if(not bOwn and gsItem.icon and not show_if_not_owned) then
					icon = gsItem.icon:gsub("(%.png)$" , "_grey.png");
					if(not ParaIO.DoesAssetFileExist(icon, true)) then
						icon = gsItem.icon;
					end
				end
				if(use_trans)then
					icon = gsItem.icon:gsub("(%.png)$" , "_tran_32bits.png");
					if(not ParaIO.DoesAssetFileExist(icon, true)) then
						icon = gsItem.icon;
					end
				end
				local _this=ParaUI.CreateUIObject("button","b","_lt", left, top, right-left, bottom-top);
				_this.background = icon or "";
				if(css["background-color"]) then
					_guihelper.SetUIColor(_this, css["background-color"]);
				else
					_guihelper.SetUIColor(_this, "255 255 255 255");
				end	
				_parent:AddChild(_this);

				if(css and css.background2) then
					_guihelper.SetVistaStyleButton2(_this, nil, css.background2);
				end

				local zorder = mcmlNode:GetNumber("zorder");
				if(zorder) then
					_this.zorder = zorder;
				end

				local enable_tooltip;
				local tooltip_headerline;
				if(mcmlNode:GetBool("click_teleport")) then
					enable_tooltip = true;
					if(bOwn) then
						tooltip_headerline = "点击传送"
					else
						tooltip_headerline = "未获得(点击传送)"
					end
					_this:SetScript("onclick", function()
						NPL.load("(gl)script/apps/Aries/CombatPet/CombatPetHelper.lua");
						local CombatPetHelper = commonlib.gettable("MyCompany.Aries.CombatPet.CombatPetHelper");
						local provider = CombatPetHelper.GetClientProvider();
						if(provider)then
							provider:DoTrack(gsid);
						end
					end)
				end
				enable_tooltip = enable_tooltip or mcmlNode:GetBool("enable_tooltip");
				if(enable_tooltip) then
					local tooltip_page = "script/apps/Aries/Desktop/GenericTooltip_InOne.html?gsid="..tostring(gsid);
					if(tooltip_page) then
						local is_lock_position, use_mouse_offset;
						if(mcmlNode:GetAttribute("tooltip_is_lock_position") == "true") then
							is_lock_position, use_mouse_offset = true, false
						end
						tooltip_headerline = mcmlNode:GetAttributeWithCode("tooltip_headerline") or tooltip_headerline;
						if(tooltip_headerline) then
							tooltip_page = format("%s&hdr=%s", tooltip_page, tooltip_headerline);
						end
						CommonCtrl.TooltipHelper.BindObjTooltip(_this.id, tooltip_page, mcmlNode:GetNumber("tooltip_offset_x"), mcmlNode:GetNumber("tooltip_offset_y"),
							nil,nil,nil, nil, nil, nil, is_lock_position, use_mouse_offset);
					end
				end
			end
		end
	end
	mcmlNode:DrawChildBlocks_Callback(rootName, bindingContext, _parent, left, top, right, bottom, myLayout, css)
	-- ignore background color
	return nil, true;
end

function pe_aries_combatpet.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	return mcmlNode:DrawDisplayBlock(rootName, bindingContext, _parent, left, top, width, height, parentLayout, style, pe_aries_combatpet.render_callback);
end


local function Get_Cards_Info(t)

   local s="";
    if(t)then
        local k,v;
        for k,v in ipairs(t) do
            local gsItem = ItemManager.GetGlobalStoreItemInMemory(v);
            if(gsItem)then
                local  path = string.format("%s;0 0 45 44",gsItem.descfile);
                local str = string.format([[<pe:item gsid="%d"  isclickable="false" style="float:left;margin-left:2px;width:36px;height:36px;"/>]],v,path);
                s = s .. str;
            end
        end
    end
    s = string.format([[<div style="float:left;">%s</div>]],s);
    return s;
end
local function Get_Props_Info(t)
    local s="";
    if(t)then
        local k,v;
        for k,v in pairs(t) do
            local str = Combat.GetStatWord_OfTypeValue(k,v);
            if(str)then
                if(s=="")then
                    s = s .. str;
                else
                    s = s ..",".. str;
                end
            end
        end
    end

    s = string.format([[<div style="float:left;">%s</div>]],s);
    return s;
end
function pe_aries_combatpet_item.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	if(CommonClientService.IsTeenVersion())then
		pe_aries_combatpet_item.create_teens(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	else
		pe_aries_combatpet_item.create_kids(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	end
end
function pe_aries_combatpet_item.create_teens(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	NPL.load("(gl)script/apps/Aries/CombatPet/CombatPetConfig.lua");
	local CombatPetConfig = commonlib.gettable("MyCompany.Aries.CombatPet.CombatPetConfig");
	local pet_config = CombatPetConfig.GetInstance_Client();
	NPL.load("(gl)script/kids/3DMapSystemItem/ItemManager.lua");
	local ItemManager = commonlib.gettable("Map3DSystem.Item.ItemManager");
	local hasGSItem = ItemManager.IfOwnGSItem;
	local parentNode = mcmlNode:GetParent("aries:combatpet");
	local pet_gsid;
	if(parentNode)then
		pet_gsid = parentNode:GetAttributeWithCode("pet_gsid",nil,true);
	end
	pet_gsid = tonumber(pet_gsid);
	if(not pet_gsid)then return end
	local instName = mcmlNode:GetInstanceName(rootName);
	local css = mcmlNode:GetStyle(style) or {};
	local function createNode(textbuffer)
		if(not textbuffer or textbuffer == "")then return end
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
	local gsItem = ItemManager.GetGlobalStoreItemInMemory(pet_gsid);
	local property = mcmlNode:GetAttributeWithCode("property");

	local exp = 0;
	local bhas,guid = hasGSItem(pet_gsid);
	if(bhas)then
		local item = ItemManager.GetItemByGUID(guid);
		if(item and item.GetServerData)then
		 local serverdata = item:GetServerData();
			exp = serverdata.exp or 0;
		end
	end
	local levels_info = pet_config:GetLevelsInfo(pet_gsid,exp);
	local row = pet_config:GetRow(pet_gsid);
	if(levels_info)then
		if(property == "petname")then
			local bhas,guid = hasGSItem(pet_gsid);
			local name;
			if(gsItem)then
				name = gsItem.template.name;
			end
			if(bhas)then
				local item = ItemManager.GetItemByGUID(guid);
				if(item.GetName_client)then
					name = item:GetName_client();
				end
			end
			if(name)then
				name = string.format([[<div>%s</div>]],name);
				createNode(name);
			end
		elseif(property == "cur_level")then
			local textbuffer = tostring(levels_info.cur_level);
			if(textbuffer)then
				textbuffer= string.format([[<div>%s</div>]],textbuffer);
				createNode(textbuffer);
			end
		elseif(property == "school")then
			local school = tostring(row.school);
			local s="";
			local label;
			if(school == "6")then
				s = "Texture/Aries/Team/fire_32bits.png";
				label = "烈火系";
			elseif(school == "7")then
				s = "Texture/Aries/Team/ice_32bits.png";
				label = "寒冰系";
			elseif(school == "8")then
				s = "Texture/Aries/Team/storm_32bits.png";
				label = "风暴系";
			elseif(school == "9")then
				s = "Texture/Aries/Team/myth_32bits.png";
				label = "神秘系";
			elseif(school == "10")then
				s = "Texture/Aries/Team/life_32bits.png";
				label = "生命系";
			elseif(school == "11")then
				s = "Texture/Aries/Team/death_32bits.png";
				label = "死亡系";
			elseif(school == "12")then
				s = "Texture/Aries/Team/balance_32bits.png";
				label = "平衡系";
			end
			mcmlNode:SetAttribute("src", s);
			mcmlNode:SetAttribute("tooltip", label);
			Map3DSystem.mcml_controls.pe_img.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout);
		end
	end
end
function pe_aries_combatpet_item.create_kids(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	NPL.load("(gl)script/apps/Aries/CombatPet/CombatPetHelper.lua");
	local CombatPetHelper = commonlib.gettable("MyCompany.Aries.CombatPet.CombatPetHelper");

	NPL.load("(gl)script/kids/3DMapSystemItem/ItemManager.lua");
	local ItemManager = commonlib.gettable("Map3DSystem.Item.ItemManager");
	local hasGSItem = ItemManager.IfOwnGSItem;
	local parentNode = mcmlNode:GetParent("aries:combatpet");
	local pet_gsid;
	if(parentNode)then
		pet_gsid = parentNode:GetAttributeWithCode("pet_gsid",nil,true);
	end
	pet_gsid = tonumber(pet_gsid);
	if(not pet_gsid)then return end
	local provider = CombatPetHelper.GetClientProvider();
	if(not provider)then return end

	local instName = mcmlNode:GetInstanceName(rootName);
	local css = mcmlNode:GetStyle(style) or {};
	local function createNode(textbuffer)
		if(not textbuffer or textbuffer == "")then return end
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
	local combat_pet_props = provider:GetPropertiesByID(pet_gsid);
	local property = mcmlNode:GetAttributeWithCode("property");
	local params_place_index = mcmlNode:GetAttributeWithCode("params_place_index",nil,true);

	local params_exp_level = mcmlNode:GetAttributeWithCode("params_exp_level",nil,true);
	local params_append_card_level = mcmlNode:GetAttributeWithCode("params_append_card_level",nil,true);
	local params_append_prop_level = mcmlNode:GetAttributeWithCode("params_append_prop_level",nil,true);

	local params_senior_exp_level = mcmlNode:GetAttributeWithCode("params_senior_exp_level",nil,true);
	local params_senior_append_card_level = mcmlNode:GetAttributeWithCode("params_senior_append_card_level",nil,true);
	local params_senior_append_prop_level = mcmlNode:GetAttributeWithCode("params_senior_append_prop_level",nil,true);

	local gsItem = ItemManager.GetGlobalStoreItemInMemory(pet_gsid);
	local exp = 0;
	local bhas,guid = hasGSItem(pet_gsid);
	if(bhas)then
		local item = ItemManager.GetItemByGUID(guid);
		if(item and item.GetServerData)then
		 local serverdata = item:GetServerData();
			exp = serverdata.exp or 0;
		end
	end
	if(combat_pet_props)then
		if(property == "petname")then
			local bhas,guid = hasGSItem(pet_gsid);
			local name;
			if(gsItem)then
				name = gsItem.template.name;
			end
			if(bhas)then
				local item = ItemManager.GetItemByGUID(guid);
				if(item.GetName_client)then
					name = item:GetName_client();
				end
			end
			if(name)then
				name = string.format([[<div>%s</div>]],name);
				createNode(name);
			end
		elseif(property == "icon")then
			local bhas,guid = hasGSItem(pet_gsid);
			local src = "";
			if(gsItem)then
				src = gsItem.icon;
				src = src:gsub("(%.png)$" , "_tran_32bits.png");
				if(not ParaIO.DoesAssetFileExist(src, true)) then
					src = gsItem.icon;
				end
				local tooltip_page = "script/apps/Aries/CombatPet/CombatPetPropsTip.teen.html";
				mcmlNode:SetAttribute("bindtooltip", tooltip_page);
				mcmlNode:SetAttribute("src", src);
				mcmlNode:SetAttribute("onclick", "MyCompany.Aries.CombatPet.CombatPetPane.ShowPage()");
				Map3DSystem.mcml_controls.pe_img.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout);
			end
		elseif(property == "detail_level")then
			local textbuffer = provider:GetLevel(pet_gsid,exp)
			if(textbuffer)then
				textbuffer= string.format([[<div>%s</div>]],textbuffer);
				createNode(textbuffer);
			end
		elseif(property == "school")then
			local school = combat_pet_props.school;
			local s="";
			local label;
			if(school == "6")then
				s = "Texture/Aries/Team/fire_32bits.png";
				label = "烈火系";
			elseif(school == "7")then
				s = "Texture/Aries/Team/ice_32bits.png";
				label = "寒冰系";
			elseif(school == "8")then
				s = "Texture/Aries/Team/storm_32bits.png";
				label = "风暴系";
			elseif(school == "9")then
				s = "Texture/Aries/Team/myth_32bits.png";
				label = "神秘系";
			elseif(school == "10")then
				s = "Texture/Aries/Team/life_32bits.png";
				label = "生命系";
			elseif(school == "11")then
				s = "Texture/Aries/Team/death_32bits.png";
				label = "死亡系";
			elseif(school == "12")then
				s = "Texture/Aries/Team/balance_32bits.png";
				label = "平衡系";
			end
			mcmlNode:SetAttribute("src", s);
			mcmlNode:SetAttribute("tooltip", label);
			Map3DSystem.mcml_controls.pe_img.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout);
		elseif(property == "level" or property == "cur_feed_num" or property == "left_feed_num")then
			local exp = 0;
			local cur_feed_num = 0;
			local bhas,guid = hasGSItem(pet_gsid);
			if(bhas)then
				local item = ItemManager.GetItemByGUID(guid);
				if(item and item.GetServerData)then
					local serverdata = item:GetServerData();
					exp = serverdata.exp or 0;
					cur_feed_num = serverdata.cur_feed_num or 0;

					local serverdate = Scene.GetServerDate() or ParaGlobal.GetDateFormat("yyyy-MM-dd");
					local cur_feed_date = serverdata.cur_feed_date;
					if(not cur_feed_date)then
						cur_feed_num = 0;
					else
						--如果不是今天
						if(cur_feed_date ~= serverdate)then
							cur_feed_num = 0;
						end
					end
				end
			end
			local is_combat,isvip = provider:IsCombatPet(pet_gsid);
			local level,cur_exp,total_exp,isfull = provider:GetLevelInfo(pet_gsid,exp);
			local senior_level,senior_cur_exp,senior_total_exp,senior_isfull = provider:GetSeniorLevelInfo(pet_gsid,exp);
			--喂养只对战宠有效
			if(is_combat)then
				local textbuffer;
				if(property == "level")then
					textbuffer = tostring(level);
				elseif(property == "senior_level")then
					textbuffer = tostring(senior_level);
				elseif(property == "cur_feed_num")then
					textbuffer = tostring(cur_feed_num);
				elseif(property == "left_feed_num")then
					cur_feed_num = 15 - cur_feed_num;
					cur_feed_num = math.max(cur_feed_num,0);
					textbuffer = tostring(cur_feed_num);
				end
				if(textbuffer)then
					textbuffer= string.format([[<div>%s</div>]],textbuffer);
					createNode(textbuffer);
				end
			end
		elseif(property == "place")then
			params_place_index = tonumber(params_place_index) or 1;
			local textbuffer = provider:GetPlace(pet_gsid,params_place_index);
			if(textbuffer)then
				textbuffer= string.format([[<div>%s</div>]],textbuffer);
				createNode(textbuffer);
			end
		elseif(property == "gsid" or property == "max_exp" or property == "max_level" or property == "req_magic_level" or property == "add_exp_max_default" or property == "add_exp_percent_default"
				or property == "senior_max_exp" or property == "senior_max_level" 
		)then
			local textbuffer = combat_pet_props[property];
			if(textbuffer)then
				textbuffer = tostring(textbuffer);
				textbuffer= string.format([[<div>%s</div>]],textbuffer);
				createNode(textbuffer);
			end
		elseif(property == "get_exp_by_level")then
			params_exp_level = tonumber(params_exp_level) or 1
			local exp_level_list = combat_pet_props.exp_level;
			if(exp_level_list)then
				local s = exp_level_list[params_exp_level];
				if(s)then
					s = tostring(s);
					s = string.format([[<div>%s</div>]],s);
					createNode(s);
				end
			end
		elseif(property == "get_senior_exp_by_level")then
			params_senior_exp_level = tonumber(params_senior_exp_level) or 1
			local senior_exp_level_list = combat_pet_props.senior_exp_level;
			if(senior_exp_level_list)then
				local s = senior_exp_level_list[params_senior_exp_level];
				if(s)then
					s = tostring(s);
					s = string.format([[<div>%s</div>]],s);
					createNode(s);
				end
			end
		elseif(property == "get_card_by_level")then
			params_append_card_level = tonumber(params_append_card_level) or 1
			local append_card_level_list = combat_pet_props.append_card_level;
			if(append_card_level_list)then
				local cards = append_card_level_list[params_append_card_level];
				if(cards)then
					local s = Get_Cards_Info(cards);
					createNode(s);
				end
			end
		elseif(property == "get_senior_card_by_level")then
			params_senior_append_card_level = tonumber(params_senior_append_card_level) or 1
			local senior_append_card_level_list = combat_pet_props.senior_append_card_level;
			if(senior_append_card_level_list)then
				local cards = senior_append_card_level_list[params_senior_append_card_level];
				if(cards)then
					local s = Get_Cards_Info(cards);
					createNode(s);
				end
			end
		elseif(property == "get_prop_by_level")then
			params_append_prop_level = tonumber(params_append_prop_level) or 1
			local append_prop_level_list = combat_pet_props.append_prop_level;
			if(append_prop_level_list)then
				local props = append_prop_level_list[params_append_prop_level];
				if(props)then
					local s = Get_Props_Info(props);
					createNode(s);
				end
			end
		elseif(property == "get_senior_prop_by_level")then
			params_senior_append_prop_level = tonumber(params_senior_append_prop_level) or 1
			local append_senior_prop_level_list = combat_pet_props.append_senior_prop_level;
			if(append_senior_prop_level_list)then
				local props = append_senior_prop_level_list[params_senior_append_prop_level];
				if(props)then
					local s = Get_Props_Info(props);
					createNode(s);
				end
			end
		elseif(property == "senior_gsid")then
			local senior_gsid_str = combat_pet_props.senior_gsid_str;
			createNode(senior_gsid_str);
		end
	end
end