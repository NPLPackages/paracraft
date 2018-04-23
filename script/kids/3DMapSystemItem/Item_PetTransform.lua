--[[
Title: transform items
Author(s): WangTian
Date: 2009/8/18
Desc: Item_PetTransform
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemItem/Item_PetTransform.lua");
------------------------------------------------------------
]]

local Item_PetTransform = {};
commonlib.setfield("Map3DSystem.Item.Item_PetTransform", Item_PetTransform)

local VIP = commonlib.gettable("MyCompany.Aries.VIP");
local Scene = commonlib.gettable("MyCompany.Aries.Scene");

---------------------------------
-- functions
---------------------------------

function Item_PetTransform:new(o)
	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self
	return o
end

-- When item is clicked through pe:slot
function Item_PetTransform:OnClick(mouse_button, bSkipMessageBox, bForceUsing)
	local ItemManager = Map3DSystem.Item.ItemManager;
	if(mouse_button == "left") then
		
		---- NOTE: the dragon is not adoptable
		---- skip useitem if mount pet adopted
		--if(MyCompany.Aries.Pet.IsAdopted()) then
			--_guihelper.MessageBox([[<div style="margin-left:20px;margin-top:20px;">你的抱抱龙现在寄养在安吉奶奶那里，先把他领回来才能照顾他哦。</div>]]);
			--return;
		--end
		--
		--local Pet = MyCompany.Aries.Pet;
		--if(not Pet.IsMyDragonFetchedFromSophie()) then
			--_guihelper.MessageBox([[<div style="margin-left:20px;margin-top:20px;">先去苏菲那把抱抱龙龙领回来吧，苏菲一直在龙龙乐园等你呢！</div>]]);
			--return;
		--end
		
		-- pill
		local marker_gsid = ItemManager.GetTransformMarker_from_Pill(self.gsid);
		if(marker_gsid) then
			local hasGSItem = ItemManager.IfOwnGSItem;
			local bHas, guid = hasGSItem(marker_gsid);
			if(bHas) then
				local item = ItemManager.GetItemByGUID(guid)
				if(item and item.guid > 0) then
					if(item.bag ~= 0) then
						if(System.options.version == "kids") then
							local gsItem = ItemManager.GetGlobalStoreItemInMemory(self.gsid);
							if(gsItem) then
								-- added 16079_SmallEagle VIP limit
								if(self.gsid == 16079 and VIP.GetMagicStarLevel() < 3) then
									_guihelper.MessageBox(string.format([[<div style="margin-left:15px;margin-top:20px;">%s需要3级魔法星能量才能驾驭哦</div>]], gsItem.template.name));
									return;
								end
								-- added 16081_SmallEagle_Black VIP limit
								if(self.gsid == 16081 and VIP.GetMagicStarLevel() < 3) then
									_guihelper.MessageBox(string.format([[<div style="margin-left:15px;margin-top:20px;">%s需要3级魔法星能量才能驾驭哦</div>]], gsItem.template.name));
									return;
								end

								-- added 16083_MechanicalMount VIP limit
								if(self.gsid == 16083 and VIP.GetMagicStarLevel() < 1) then
									_guihelper.MessageBox(string.format([[<div style="margin-left:15px;margin-top:20px;">%s需要1级魔法星能量才能驾驭哦</div>]], gsItem.template.name));
									return;
								end
							end
						end
					end

					item:OnClick("left");
					return;
				end
			end
		end
		
		-- tramsform to the target animal
		local gsid = self.gsid;
		local gsItem = ItemManager.GetGlobalStoreItemInMemory(gsid);
		if(gsItem) then
			if(gsItem.template.stats[51]) then
				local pill_name = gsItem.template.name;
				local related_animal_name;
				if(not related_animal_name or related_animal_name == "") then
					related_animal_name = pill_name;
				end
				
				-- 46 MountPet? _Transform_Duration_Days(C) 变身药丸的坐骑维持时间 
				-- 51 MountPet? _Transform_Duration_Marker_ExtendedCost_ID (CS) 
				-- 180 vip_items(C)VIP专属物品  
				local exid = gsItem.template.stats[51];
				
				local required_level = gsItem.template.stats[138];
				if(required_level) then
					local my_level = MyCompany.Aries.Combat.GetMyCombatLevel();
					if(my_level < required_level) then
						_guihelper.MessageBox(string.format([[<div style="margin-left:20px;margin-top:20px;">%s需要%d级以上才能使用哦，先快快升级吧！</div>]], pill_name, required_level));
						return;
					end
				end
				
				if(not gsItem.template.stats[180] or (gsItem.template.stats[180] and VIP.IsVIP())) then
					
					if(System.options.version == "kids") then
						-- added 16079_SmallEagle VIP limit
						if(self.gsid == 16079 and VIP.GetMagicStarLevel() < 3) then
							_guihelper.MessageBox(string.format([[<div style="margin-left:15px;margin-top:20px;">%s需要3级魔法星能量才能驾驭哦</div>]], gsItem.template.name));
							return;
						end
						-- added 16081_SmallEagle_Black VIP limit
						if(self.gsid == 16081 and VIP.GetMagicStarLevel() < 3) then
							_guihelper.MessageBox(string.format([[<div style="margin-left:15px;margin-top:20px;">%s需要3级魔法星能量才能驾驭哦</div>]], gsItem.template.name));
							return;
						end

						-- added 16083_MechanicalMount VIP limit
						if(self.gsid == 16083 and VIP.GetMagicStarLevel() < 1) then
							_guihelper.MessageBox(string.format([[<div style="margin-left:15px;margin-top:20px;">%s需要1级魔法星能量才能驾驭哦</div>]], gsItem.template.name));
							return;
						end
					end

					-- check transform target gsid
					local transform_target_gsid;
					local exTemplate = ItemManager.GetExtendedCostTemplateInMemory(exid);
					if(exTemplate) then
						local i, to;
						for i, to in ipairs(exTemplate.tos) do
							local gsItem = ItemManager.GetGlobalStoreItemInMemory(to.key);
							if(gsItem) then
								-- 33 Transformation Marker
								if(gsItem.template.inventorytype == 33) then
									transform_target_gsid = to.key;
									break;
								end
							end
						end
					end

					if(not transform_target_gsid) then
						log("+++++++ no transform target gsid found for transform: "..tostring(gsid).."+++++++\n")
						return;
					end

					local total_marker_count = 0;
					-- check current marker gsid
					local current_marker_gsid;
					-- 33 Transformation Marker
					local item_marker = ItemManager.GetItemByBagAndPosition(0, 33);
					if(item_marker and item_marker.guid > 0) then
						current_marker_gsid = item_marker.gsid;
						total_marker_count = total_marker_count + 1;
					end

					--if(System.options.version == "teen") then
						--local count = ItemManager.GetItemCountInBag(26)
						--total_marker_count = total_marker_count + count;
						--if(total_marker_count >= 3) then
							--_guihelper.MessageBox([[<div style="margin-left:15px;margin-top:20px;">最多同时拥有3个变身状态</div>]]);
							--return;
						--end
					--end

					local hasGSItem = ItemManager.IfOwnGSItem;
					local bHas, transform_target_guid = hasGSItem(transform_target_gsid);
					if(bHas) then
						local item = ItemManager.GetItemByGUID(transform_target_guid)
						if(item and item.guid > 0) then
							if(item.bag == 0) then
								_guihelper.MessageBox(string.format([[<div style="margin-left:15px;margin-top:20px;">你的坐骑现在已经变成%s了，不需要重复使用哦！</div>]], related_animal_name));
								return;
							elseif(item.bag == 1) then
								item:OnClick("left");
								_guihelper.MessageBox(string.format([[<div style="margin-left:15px;margin-top:20px;">你的坐骑现在已经切换成%s了，不需要重复使用哦！</div>]], related_animal_name));
								return;
							end
						end
					end

					NPL.load("(gl)script/apps/Aries/DealDefend/DealDefend.lua");
					local DealDefend = commonlib.gettable("MyCompany.Aries.DealDefend.DealDefend");
					local can_pass = DealDefend.CanPass();
					if(not can_pass)then
						return
					end

					local text;
					if(System.options.version == "kids") then
						if(gsItem.template.stats[46]) then
							text = string.format([[<div style="margin-left:15px;margin-top:20px;">现在要使用%s吗？使用后，接下来的%d天你的坐骑就会变成%s的样子哦！</div>]], pill_name, gsItem.template.stats[46], related_animal_name);
						else
							text = string.format([[<div style="margin-left:15px;margin-top:20px;">现在要使用%s吗？使用后，你的坐骑就会变成%s的样子哦！</div>]], pill_name, related_animal_name);
						end
					else
						--text = "召唤坐骑将消耗这个召唤石, 确定要召唤吗?"
						if(gsItem.template.stats[46]) then
							text = string.format("%s将跟随你%d天，确定召唤吗？",related_animal_name or "", tostring(gsItem.template.stats[46]));
						else
							text = string.format("%s将永久跟随你，确定召唤吗？",related_animal_name or "");
						end
					end

					local function DoUseMountPill()
						local serverdate = Scene.GetServerDate();
						local serverseconds = Scene.GetLastAuthServerTimeSince0000()
						local year, month, day = string.match(serverdate or "", "^(.+)%-(.+)%-(.+)$");
						if(serverdate and serverseconds and year and month and day) then
							year = tonumber(year)
							month = tonumber(month)
							day = tonumber(day)
							local daysfrom_1900_1_1 = commonlib.GetDaysFrom_1900_1_1(year, month, day);
							local hasGSItem = ItemManager.IfOwnGSItem;

							-- 51 MountPet? _Transform_Duration_Marker_ExtendedCost_ID (CS) 
							local exid = gsItem.template.stats[51];
							ItemManager.ExtendedCost(exid, nil, nil, function(msg)end, function(msg) 
								log("+++++++ExtendedCost transform marker "..exid.." return: +++++++\n")
								commonlib.echo(msg);
								if(msg and msg.issuccess == true) then
									local hasGSItem = ItemManager.IfOwnGSItem;
									local bHas, transform_target_guid = hasGSItem(transform_target_gsid);
									if(bHas) then
										local item = ItemManager.GetItemByGUID(transform_target_guid)
										if(item and item.guid > 0 and item.bag == 26) then
											item:OnClick("left", function()
											end);
											MyCompany.Aries.Player.SetTransformGSIDFromItem(gsid, daysfrom_1900_1_1, serverseconds);
											-- auto refresh
											Map3DSystem.Item.ItemManager.RefreshMyself();
											if(System.options.version == "kids") then
												---- hide main window
												NPL.load("(gl)script/apps/Aries/Inventory/TabMountExPage.lua");
												MyCompany.Aries.Inventory.TabMountExPage.ClosePage();
											elseif(System.options.version == "teen") then
												-- by Xizhi: fixed mount follow bug. PetPage.Refresh() will be called in callback. 
												-- NPL.load("(gl)script/apps/Aries/Inventory/PetPage.lua");
												--local PetPage = commonlib.gettable("MyCompany.Aries.Inventory.PetPage");
												-- PetPage.ClosePage();
											end
										end
									end
								end
							end);
						end
					end
					if(System.options.version == "kids" and MyCompany.Aries.Player.GetLevel() <=10) then
						-- no ask for player with level < 10
						DoUseMountPill();
					else
						_guihelper.MessageBox(text, 
							function(res)	
								if(res and res == _guihelper.DialogResult.Yes) then
									DoUseMountPill();
								end
							end, _guihelper.MessageBoxButtons.YesNo)
					end
				else
					if(System.options.version == "kids") then
						local s = format("需要魔法星的力量才能使用<pe:item gsid='%d' style='width:32px;height:32px;' isclickable='false'/>哦！<br/>",gsid);
						Map3DSystem.Item.ItemManager.UseOrBuy_EnergyStone(nil,function(msg)
							return s;
						end);
					else
						NPL.load("(gl)script/apps/Aries/Desktop/GUIHelper/CustomMessageBox.lua");
						_guihelper.Custom_MessageBox("你还没有魔法星哦，【"..gsItem.template.name.."】需要魔法星的力量才能使用哦！",function(result)
							if(result == _guihelper.DialogResult.No)then
								--NPL.load("(gl)script/apps/Aries/VIP/PurChaseEnergyStone.lua");
								--local PurchaseEnergyStone = commonlib.gettable("MyCompany.Aries.Inventory.PurChaseEnergyStone");
								--PurchaseEnergyStone.Show();
								local gsid=998;
								Map3DSystem.mcml_controls.pe_item.OnClickGSItem(gsid,true);	
							end
						end,_guihelper.MessageBoxButtons.YesNo,{yes = "Texture/Aries/Common/IKnow_32bits.png; 0 0 153 49", no = "Texture/Aries/Common/GotMagicStone_32bits.png; 0 0 153 49"});
					end
				end
			--else
				-- NOTE 2011/11/23: this piece of code can't be invoked
				-- all mount pet transform is time limited by days

				--local related_animal_name = gsItem.template.description;
				--local pill_name = gsItem.template.name;
				--local petLevel = 0;
				---- get pet level
				--local bean = MyCompany.Aries.Pet.GetBean();
				--if(bean) then
					--petLevel = bean.level or 0;
					--if(System.options.version == "kids") then
						--if(petLevel < 3) then
							--_guihelper.MessageBox(string.format([[<div style="margin-left:20px;margin-top:20px;">%s需要抱抱龙3级以上才能使用哦，先让你的抱抱龙快快长大吧！</div>]], pill_name));
							--return;
						--end
					--end
				--end
				--local string_format_string = [[<div style="margin-left:15px;margin-top:20px;">现在要使用%s吗？使用后，接下来的1个小时抱抱龙就会变成%s的样子哦！</div>]];
				--if(System.options.version == "teen") then
					--string_format_string = [[<div style="margin-left:15px;margin-top:20px;">现在要使用%s吗？使用后，接下来的1个小时坐骑就会变成%s的样子！</div>]];
				--end
				--_guihelper.MessageBox(string.format(string_format_string, pill_name, related_animal_name), 
				--function(res)	
					--if(res and res == _guihelper.DialogResult.Yes) then
						--local serverdate = Scene.GetServerDate();
						--local serverseconds = Scene.GetLastAuthServerTimeSince0000()
						--local year, month, day = string.match(serverdate or "", "^(.+)%-(.+)%-(.+)$");
						--if(serverdate and serverseconds and year and month and day) then
							--year = tonumber(year)
							--month = tonumber(month)
							--day = tonumber(day)
							--local daysfrom_1900_1_1 = commonlib.GetDaysFrom_1900_1_1(year, month, day);
							--ItemManager.DestroyItem(self.guid, 1, function(msg)
								--if(msg) then
									--log("+++++++Destroy Item_PetTransform return: #"..tostring(self.guid).." +++++++\n")
									--commonlib.echo(msg);
									--if(msg.issuccess == true) then
										---- 33 Transformation Marker
										--local item_marker = ItemManager.GetItemByBagAndPosition(0, 33);
										--if(item_marker and item_marker.guid > 0) then
											--local log_str = tostring(item_marker.gsid);
											--ItemManager.DestroyItem(item_marker.guid, 1, function(msg)
												--log("+++++++Destroy previous marker return: #"..log_str.." +++++++\n")
												---- set the dragon tranform gsid
												--MyCompany.Aries.Player.SetTransformGSIDFromItem(gsid, daysfrom_1900_1_1, serverseconds);
												------ hide main window
												--MyCompany.Aries.Inventory.TabMountExPage.ClosePage();
											--end);
										--else
											---- set the dragon tranform gsid
											--MyCompany.Aries.Player.SetTransformGSIDFromItem(gsid, daysfrom_1900_1_1, serverseconds);
											------ hide main window
											--MyCompany.Aries.Inventory.TabMountExPage.ClosePage();
										--end
									--end
								--end
							--end);
						--end
					--end
				--end, _guihelper.MessageBoxButtons.YesNo)
			end
		end
		 
	elseif(mouse_button == "right") then
		---- destroy the item
		--_guihelper.MessageBox("你确定要销毁 #"..tostring(self.guid).." 物品么？", function(result) 
			--if(_guihelper.DialogResult.Yes == result) then
				--Map3DSystem.Item.ItemManager.DestroyItem(self.guid, 1, function(msg)
					--if(msg) then
						--log("+++++++Destroy item return: #"..tostring(self.guid).." +++++++\n")
						--commonlib.echo(msg);
					--end
				--end);
			--elseif(_guihelper.DialogResult.No == result) then
				---- doing nothing if the user cancel the add as friend
			--end
		--end, _guihelper.MessageBoxButtons.YesNo);
	end
end

function Item_PetTransform:GetTooltip()
	local ItemManager = Map3DSystem.Item.ItemManager;
	local gsItem = ItemManager.GetGlobalStoreItemInMemory(self.gsid)
	local tooltip = "";
	if(gsItem) then
		if(self.gsid >= 16032 and self.gsid <= 16044) then
			local name = gsItem.template.name;
			tooltip = "名称："..name.."\n";
			tooltip = tooltip.."使用等级要求：3级以上\n";
			tooltip = tooltip.."药丸有效期：3天\n";
		elseif(gsItem.template.stats[46]) then
			return "page://script/apps/Aries/Desktop/ApparelTooltip.html?gsid="..self.gsid.."&guid="..self.guid;
		else
			local name = gsItem.template.name;
			tooltip = "名称："..name.."\n";
			tooltip = tooltip.."使用等级要求：3级以上\n";
			tooltip = tooltip.."药丸有效期：3天\n";
		end
		return tooltip;
	end
end