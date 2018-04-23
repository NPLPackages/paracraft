--[[
Title: 
Author(s): Leio
Date: 2010/04/19
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemItem/Item_FollowPet_Skills.lua");
Map3DSystem.Item.Item_FollowPet_Skills.CrystalBunny();
------------------------------------------------------------
]]

local Item_FollowPet_Skills = {};
commonlib.setfield("Map3DSystem.Item.Item_FollowPet_Skills", Item_FollowPet_Skills);

local ItemManager = Map3DSystem.Item.ItemManager;
local hasGSItem = ItemManager.IfOwnGSItem;
	
function Item_FollowPet_Skills.CrystalBunny_Action()
	local gsObtain = ItemManager.GetGSObtainCntInTimeSpanInMemory(50305);
	local hasItem,guid,bag,copies = hasGSItem(50305);
	if(gsObtain and gsObtain.inday > 0) then
		_guihelper.MessageBox([[<div style="margin-left:20px;margin-top:20px;">水晶兔已经给你变了一套合成材料啦，明天再让它给你变吧！</div>]]);
		return;
	end
	copies = copies or 0
	if(guid and copies == 1 and gsObtain and gsObtain.inday == 0)then
		ItemManager.DestroyItem(guid,1,function(msg) end,function(msg)
			commonlib.echo("=====destroy 50305_HasCollectMaterialToday");
			commonlib.echo(msg);
		end)
	end
	function parseExID(item)
		if(not item or not item.request_items)then return end
		local request_items = item.request_items;
		local item_str;
		local s = "";
		for item_str in string.gfind(request_items, "[^|]+") do
			local __,__,gsid,num = string.find(item_str,"(.+),(.+)");
			gsid = tonumber(gsid);
			num = tonumber(num);
			if(gsid and num)then
				local gsItem = ItemManager.GetGlobalStoreItemInMemory(gsid)
				if(gsItem) then
					local name = gsItem.template.name or "";
					local ss = string.format("%s,",name);
					s = s .. ss;
				end
			end
		end
		return s;
	end
	function getItems()
		local items = {
			{ level = 0, exID = 407, name = "巧克力花圃", gsid = 30136, request_items = "17094,2",},
			{ level = 0, exID = 408, name = "奶酪复古电话", gsid = 30137, request_items = "17095,2|17056,3",},
			{ level = 1, exID = 409, name = "橘子糖挂钟",  gsid = 30138, request_items = "17076,2|17066,3",},
			{ level = 1, exID = 410, name = "草莓地毯",  gsid = 30139, request_items = "17091,2|17034,2",},
			{ level = 2, exID = 411, name = "拐棍糖秋千",  gsid = 30140, request_items = "17090,3|17014,2|17057,2",},
		}	
		local r = math.random(100);
		local level = 0;
		if(r <= 25)then
			level = 0;
		elseif(r >25 and r <=50)then
			level = 2;
		else
			level = 1;
		end
		local result = {};
		local k,item;
		for k,item in ipairs(items) do
			if (item.level == level) then
				table.insert(result,item);
			end
		end
		local len = #result;
		if(len > 0)then
			local index = math.random(len);
			return result[index];
		end
	end
		
	local item = getItems();
	if(item and item.exID)then
		local exID = item.exID;
		local name = item.name;
		local item_str = parseExID(item);
		commonlib.echo("=========before CrystalBunny_Action");
		ItemManager.ExtendedCost(exID, nil, nil, function(msg)end, function(msg) 
			commonlib.echo("=========after CrystalBunny_Action");
			commonlib.echo(msg);
			if(msg and msg.issuccess)then
				local s = string.format([[<div style="margin-left:20px;margin-top:20px;"> 水晶兔真厉害，已经给你变出一套【%s】家园合成材料啦，快去建造台合成看看吧！ </div>]],name or "");
				_guihelper.MessageBox(s,function(res)
				
				end, _guihelper.MessageBoxButtons.OK);
			end
		end);
		
	end
end