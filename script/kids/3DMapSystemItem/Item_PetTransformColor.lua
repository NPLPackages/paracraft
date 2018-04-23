--[[
Title: transform items
Author(s): WangTian
Date: 2009/8/18
Desc: Item_PetTransformColor
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemItem/Item_PetTransformColor.lua");
------------------------------------------------------------
]]

local Item_PetTransformColor = {};
commonlib.setfield("Map3DSystem.Item.Item_PetTransformColor", Item_PetTransformColor)

---------------------------------
-- functions
---------------------------------

function Item_PetTransformColor:new(o)
	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self
	return o
end


-- When item is clicked through pe:slot
function Item_PetTransformColor:OnClick(mouse_button)
	local ItemManager = Map3DSystem.Item.ItemManager;
	if(mouse_button == "left") then
	
		-- skip useitem if mount pet adopted
		if(MyCompany.Aries.Pet.IsAdopted()) then
			_guihelper.MessageBox([[<div style="margin-left:20px;margin-top:20px;">你的抱抱龙现在寄养在安吉奶奶那里，先把他领回来才能照顾他哦。</div>]]);
			return;
		end
		
		local Pet = MyCompany.Aries.Pet;
		if(not Pet.IsMyDragonFetchedFromSophie()) then
			_guihelper.MessageBox([[<div style="margin-left:20px;margin-top:20px;">先去苏菲那把抱抱龙龙领回来吧，苏菲一直在龙龙乐园等你呢！</div>]]);
			return;
		end
		-- tramsform to the target animal
		local gsid = self.gsid;
		local gsItem = ItemManager.GetGlobalStoreItemInMemory(gsid);
		if(gsItem) then
			local related_color_name = gsItem.template.description;
			local pill_name = gsItem.template.name;
			local petLevel = 0;
			-- get pet level
			local bean = MyCompany.Aries.Pet.GetBean();
			if(bean) then
				petLevel = bean.level or 0;
				if(System.options.version == "kids") then
					if(petLevel < 3) then
						_guihelper.MessageBox(string.format([[<div style="margin-left:20px;margin-top:20px;">%s需要抱抱龙3级以上才能使用哦，先让你的抱抱龙快快长大吧！</div>]], pill_name));
						return;
					end
				end
			end
			local to_color_gsid = gsItem.template.stats[32];
			if(to_color_gsid) then
				-- get current pet color
				local from_color_gsid;
				local item = ItemManager.GetItemByBagAndPosition(0, 40);
				if(item and item.guid ~= 0) then
					from_color_gsid = item.gsid;
					if(item.clientdata and item.clientdata ~= "") then
						local gsid, date = string.match(item.clientdata, "^(.+)%+(.+)$");
						if(gsid and date) then
							gsid = tonumber(gsid);
							if(date == MyCompany.Aries.Scene.GetServerDate()) then
								from_color_gsid = gsid;
							end
						end
					end
				end
				if(from_color_gsid == to_color_gsid) then
					_guihelper.MessageBox(string.format([[<div style="margin-left:15px;margin-top:20px;">你的抱抱龙现在就是这个颜色哦，不需要再变化啦，试试其他药丸吧!</div>]], related_color_name));
					return;
				end
				local Player = MyCompany.Aries.Player;
				if(Player.transform_gsid) then
					_guihelper.MessageBox(string.format([[<div style="margin-left:15px;margin-top:20px;">抱抱龙处于变身状态不能使用变色药丸，等恢复抱抱龙形态时再使用吧！</div>]], related_color_name));
					return;
				end
				-- if 32 Transformed_Color_GSID(C) is valid, indicating the color is a base color item
				_guihelper.MessageBox(string.format([[<div style="margin-left:15px;margin-top:20px;">抱抱龙现在要使用%s吗？使用后，抱抱龙可以长期变成%s色哦！</div>]], pill_name, related_color_name), 
				function(res)	
					if(res and res == _guihelper.DialogResult.Yes) then
						ItemManager.DestroyItem(self.guid, 1, function(msg)
							if(msg) then
								log("+++++++Destroy Item_PetTransformColor return: #"..tostring(self.guid).." +++++++\n")
								commonlib.echo(msg);
								if(msg.issuccess == true) then
									-- get current pet color
									local from_color_gsid;
									local item = ItemManager.GetItemByBagAndPosition(0, 40);
									if(item and item.guid ~= 0) then
										from_color_gsid = item.gsid;
										if(item.clientdata and item.clientdata ~= "") then
											local gsid, date = string.match(item.clientdata, "^(.+)%+(.+)$");
											if(gsid and date) then
												gsid = tonumber(gsid);
												if(date == MyCompany.Aries.Scene.GetServerDate()) then
													from_color_gsid = gsid;
												end
											end
										end
									end
									if(from_color_gsid) then
										-- change base color
										Item_PetTransformColor.ChangeBaseColor(from_color_gsid, to_color_gsid);
									end
									-- hide main window
									MyCompany.Aries.Inventory.HideMainWnd();
								end
							end
						end);
					end
				end, _guihelper.MessageBoxButtons.YesNo);
			else
				-- get current pet color
				local from_color_gsid;
				local item = ItemManager.GetItemByBagAndPosition(0, 40);
				if(item and item.guid ~= 0) then
					from_color_gsid = item.gsid;
					if(item.clientdata and item.clientdata ~= "") then
						local gsid, date = string.match(item.clientdata, "^(.+)%+(.+)$");
						if(gsid and date) then
							gsid = tonumber(gsid);
							if(date == MyCompany.Aries.Scene.GetServerDate()) then
								from_color_gsid = gsid;
							end
						end
					end
				end
				if(from_color_gsid == self.gsid) then
					_guihelper.MessageBox(string.format([[<div style="margin-left:15px;margin-top:20px;">你的抱抱龙现在就是这个颜色哦，不需要再变化啦，试试其他药丸吧!</div>]], related_color_name));
					return;
				end
				local Player = MyCompany.Aries.Player;
				if(Player.transform_gsid) then
					_guihelper.MessageBox(string.format([[<div style="margin-left:15px;margin-top:20px;">抱抱龙处于变身状态不能使用变色药丸，等恢复抱抱龙形态时再使用吧！</div>]], related_color_name));
					return;
				end
				-- if 32 Transformed_Color_GSID(C) is not valid, it is a temporary color item
				_guihelper.MessageBox(string.format([[<div style="margin-left:15px;margin-top:20px;">抱抱龙现在要使用%s吗？使用后，今天抱抱龙就会变成%s色哦！</div>]], pill_name, related_color_name), 
				function(res)	
					if(res and res == _guihelper.DialogResult.Yes) then
						ItemManager.DestroyItem(self.guid, 1, function(msg)
							if(msg) then
								log("+++++++Destroy Item_PetTransformColor return: #"..tostring(self.guid).." +++++++\n")
								commonlib.echo(msg);
								if(msg.issuccess == true) then
									---------------------------------------------------------------------
									---- set the dragon tranform gsid
									--MyCompany.Aries.Player.SetTransformGSIDFromItem(gsid);
									---------------------------------------------------------------------
									-- change temp color
									Item_PetTransformColor.ChangeTempColor(self.gsid);
									-- hide main window
									MyCompany.Aries.Inventory.HideMainWnd();
								end
							end
						end);
					end
				end, _guihelper.MessageBoxButtons.YesNo);
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

function Item_PetTransformColor:GetTooltip()
	local ItemManager = Map3DSystem.Item.ItemManager;
	local gsItem = ItemManager.GetGlobalStoreItemInMemory(self.gsid)
	local tooltip = "";
	if(gsItem) then
		--local name = gsItem.template.name;
		--local validtimetext = "";
		--if(self.gsid >= 16045 and self.gsid <= 16048) then
			--validtimetext = "长期";
		--elseif(self.gsid >= 16049 and self.gsid <= 16050) then
			--validtimetext = "今天";
		--end
		--tooltip = "名称："..name.."\n";
		--tooltip = tooltip.."使用等级要求：3级以上\n";
		--tooltip = tooltip.."药丸有效期："..validtimetext.."\n";
		--return tooltip;
		
		return "page://script/apps/Aries/Desktop/ApparelTooltip.html?gsid="..self.gsid;
	end
end

-- extended cost id:
-- 327 TransformPetBaseColor_From_11010_To_11009 
-- 328 TransformPetBaseColor_From_11011_To_11009 
-- 329 TransformPetBaseColor_From_11012_To_11009 
-- 330 TransformPetBaseColor_From_11009_To_11010 
-- 331 TransformPetBaseColor_From_11011_To_11010 
-- 332 TransformPetBaseColor_From_11012_To_11010 
-- 333 TransformPetBaseColor_From_11009_To_11011 
-- 334 TransformPetBaseColor_From_11010_To_11011 
-- 335 TransformPetBaseColor_From_11012_To_11011 
-- 336 TransformPetBaseColor_From_11009_To_11012 
-- 337 TransformPetBaseColor_From_11010_To_11012 
-- 338 TransformPetBaseColor_From_11011_To_11012 

-- NOTE: auto refresh the avatar
-- change base color from to, with extended cost
-- @param from: from color gsid
-- @param to: to color gsid
function Item_PetTransformColor.ChangeBaseColor(from, to)
	local ItemManager = Map3DSystem.Item.ItemManager;
	-- NOTE: the special color is set via the clientdata of the color item
	--		 so check if the color object is the same as the target object
	if(from == 16049 or from == 16050) then
		-- get the real dragon color
		local item = ItemManager.GetItemByBagAndPosition(0, 40);
		if(item and item.guid ~= 0) then
			if(to == item.gsid) then
				-- clear the clientdata instead of item extendedcost
				ItemManager.SetClientData(item.guid, "", function(msg) 
					Map3DSystem.Item.ItemManager.RefreshMyself();
				end);
				return;
			else
				-- set the clientdata via item extendedcost
				from = item.gsid;
			end
		end
	end
	local color_transform_exid;
	local exid;
	for exid = 327, 338 do
		local exTemplate = ItemManager.GetExtendedCostTemplateInMemory(exid);
		if(exTemplate) then
			if(exTemplate.exname == "TransformPetBaseColor_From_"..from.."_To_"..to) then
				color_transform_exid = exid;
				break;
			end
		end
	end
	if(color_transform_exid) then
        ItemManager.ExtendedCost(color_transform_exid, nil, nil, function(msg)end, function(msg)
		    log("+++++++Item_PetTransformColor.ChangeBaseColor from:"..from..", to:"..to.." return: +++++++\n")
		    commonlib.echo(msg);
		    if(msg.issuccess == true) then
				Map3DSystem.Item.ItemManager.RefreshMyself();
		    end
        end, "none");
	end
end

-- set the clientdata of the user
function Item_PetTransformColor.ChangeTempColor(gsid)
	local ItemManager = Map3DSystem.Item.ItemManager;
	local item = ItemManager.GetItemByBagAndPosition(0, 40);
	if(item and item.guid ~= 0) then
		local serverdate = MyCompany.Aries.Scene.GetServerDate() or ParaGlobal.GetDateFormat("yyyy-MM-dd");
		local color_clientdata = gsid.."+"..serverdate;
		ItemManager.SetClientData(item.guid, color_clientdata, function(msg) 
			Map3DSystem.Item.ItemManager.RefreshMyself();
		end);
	end
end