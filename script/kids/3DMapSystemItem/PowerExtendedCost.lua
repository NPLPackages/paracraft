--[[
Title: Power Extended Cost 
Author(s): LiXizhi
Date: 2013/1/14
Desc: 
	
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemItem/PowerExtendedCost.lua");
local PowerExtendedCost = commonlib.gettable("Map3DSystem.Item.PowerExtendedCost");
PowerExtendedCost.LoadFromConfig();
PowerExtendedCost.ExtendedCost(exid, msg, function(msg) end);

-- On Client Side:
System.GSL_client:SendRealtimeMessage("sPowerAPI", {name="PowerExtendedCost", params={exid="test", from="2067", rate_gsid_count = 0}});
System.GSL_client:SendRealtimeMessage("sPowerAPI", {name="PowerExtendedCost", params={exid="test", from="2067", rate_gsid_count = 99}});

System.GSL_client:SendRealtimeMessage("sPowerAPI", {name="PowerExtendedCost", params={exid="lottery_silver"}});


System.GSL_client:SendRealtimeMessage("sPowerAPI", {name="PowerExtendedCost", params={exid="select_one_test", gsid=2067}});
System.GSL_client:SendRealtimeMessage("sPowerAPI", {name="PowerExtendedCost", params={exid="change_religion", gsid=50351}});
System.GSL_client:SendRealtimeMessage("sPowerAPI", {name="PowerExtendedCost", params={exid="change_skill", gsid=50362}});

System.GSL_client:SendRealtimeMessage("sPowerAPI", {name="PowerExtendedCost", params={exid="add_dragon_belief", gsid=17830}});
------------------------------------------------------------
]]
NPL.load("(gl)script/kids/3DMapSystemApp/API/AriesPowerAPI/AriesServerPowerAPI.lua");

local LOG = LOG;
local type = type;
local PowerExtendedCost = commonlib.gettable("Map3DSystem.Item.PowerExtendedCost");
local PowerItemManager = commonlib.gettable("Map3DSystem.Item.PowerItemManager");
local Player = commonlib.gettable("MyCompany.Aries.Combat_Server.Player");
local gateway = commonlib.gettable("Map3DSystem.GSL.gateway");
local Card = commonlib.gettable("MyCompany.Aries.Combat_Server.Card");

local ex_types = {
	["transfer_with_factor"] = {
		
	},
}

-- mapping from exid name to its definition. 
local exid_map = {};

function PowerExtendedCost.GetExtendedCostTemplateInMemory(exid)
	return exid_map[exid];
end
--获取成功率
function PowerExtendedCost.get_success_rate(ex_template, rate_gsid_count)
	if(not ex_template or not rate_gsid_count)then
		return 0;
	end
	local attr = ex_template.attr;
	if(type(rate_gsid_count) ~= "number" or rate_gsid_count<0 or not ex_template.attr.rate_gsid) then
		rate_gsid_count = 0;
	end
	local success_rate = math.min(attr.base_success_rate+(attr.rate_gsid_factor*(rate_gsid_count or 0)), attr.max_success_rate);
	return success_rate;
end
--根据from_gsid 搜索所有匹配的模板id
-- @param from_gsid:
-- @param type:模板类型
function PowerExtendedCost.SearchTemplateByTransfer(from_gsid,type)
	if(not from_gsid)then
		return
	end
	local result = {};
	from_gsid = tostring(from_gsid);
	local exid,template;
	for exid,template in pairs(exid_map) do
		local k,v;
		type = type or template.attr.type;
		if(type == template.attr.type)then
			for k,v in ipairs(template) do
				if(v.attr and v.attr.from == from_gsid)then
					table.insert(result,{
						exid = exid,
						trans_node = v;			
					});
				end
			end
		end
	end
	return result;
end

-- @param loot_str: such as {[17810,2]=70,[17810,3]=30}
-- @return loot, total_rate
function PowerExtendedCost.ParseLootString(loot_str)
	if(type(loot_str) == "string") then
		local gsid = loot_str:match("^(%d+)$");
		
		local loot = {};
		local total = 0;
		if(not gsid) then
			local gsid, count, rate;
			for gsid, count, rate in loot_str:gmatch("%[(%d-),(%d-)%]=(%d+)") do
				gsid=tonumber(gsid);
				count=tonumber(count);
				rate=tonumber(rate);
				total = total + rate;
				loot[#loot+1] = {gsid=gsid, count=count, rate=rate, accumu_rate=total};
			end
		else
			count = 1;
			rate = 100;
			total = total + rate;
			loot[#loot+1] = {gsid=gsid, count=count, rate=rate, accumu_rate=total};
		end
		return loot, total;
	end
end

-- @param loot_str: such as {[17810,2],[17810,3]}
-- @return loot
function PowerExtendedCost.ParseLootString2(loot_str)
	local loot = {};
	if(type(loot_str) == "string") then
		local gsid, count;
		for gsid, count in string.gmatch(loot_str,"%[(-?%d+),(-?%d+)%]") do
			gsid = tonumber(gsid);
			count = tonumber(count);
			loot[#loot+1] = {gsid=gsid, count=count};
		end
	end
	return loot;
end

-- return the loot item {gsid=gsid, count=count}
function PowerExtendedCost.GetRandomLoot(loots, total_rate)
	local current_rate = math.random(1, total_rate);
			
	-- currently only a single item is selected. 
	local current_loot;
	local _, loot;
	for _, loot in ipairs(loots) do
		if(current_rate<=loot.accumu_rate) then
			current_loot = loot;
			break;
		end
	end
	return current_loot;
end

function PowerExtendedCost.LoadFromConfig(filename)
	if(PowerExtendedCost.is_loaded) then
		return;
	end
	PowerExtendedCost.is_loaded = true;

	if (not filename) then
		if(System.options.version == "kids") then
			filename = "config/Aries/Others/extendedcost.special.kids.xml"
		else
			filename = "config/Aries/Others/extendedcost.special.teen.xml"
		end
	end

	local xmlRoot = ParaXML.LuaXML_ParseFile(filename);
	if(xmlRoot) then
		LOG.std(nil, "debug", "PowerExtendedCost", "loaded file %s", filename);
		local node;
		for node in commonlib.XPath.eachNode(xmlRoot, "/extendedcosts/extendedcost") do
			local attr = node.attr;
			if(attr and attr.type and attr.id) then
				local ex_type = attr.type;

				exid_map[attr.id] = node;
				node.type = ex_types[ex_type];

				if(ex_type == "transfer_with_factor") then
					attr.base_success_rate = tonumber(attr.base_success_rate);
					attr.max_success_rate = tonumber(attr.max_success_rate);
					attr.rate_gsid = tonumber(attr.rate_gsid);
					attr.rate_gsid_factor = tonumber(attr.rate_gsid_factor);
					attr.rate_gsid_min_count = tonumber(attr.rate_gsid_min_count or 0);
					attr.greedy_mode = (attr.greedy_mode == "true");
					if(attr.from) then
						local gsid, count = attr.from:match("(%d+),(%d+)");
						attr.from_gsid = tonumber(gsid);
						attr.from_count = tonumber(count) or 1;
					end
					if(attr.always_to) then
						local gsid, count = attr.always_to:match("(%d+),(%d+)");
						attr.always_to_gsid = tonumber(gsid);
						attr.always_to_count = tonumber(count) or 1;
					end

					local _, transfer 
					for _, transfer in ipairs(node) do
						transfer.attr.to, transfer.attr.to_total_rate = PowerExtendedCost.ParseLootString(transfer.attr.to);
						transfer.attr.fail_to, transfer.attr.fail_to_total_rate = PowerExtendedCost.ParseLootString(transfer.attr.fail_to);
					end

				elseif(ex_type == "advanced_lottery") then
					local gsid, count = attr.from:match("(%d+),(%d+)");
					attr.from_gsid = tonumber(gsid);
					attr.from_count = tonumber(count) or 1;
					attr.count_gsid = tonumber(attr.count_gsid);
					attr.final_reward_gsid = tonumber(attr.final_reward_gsid);
					if(attr.form_item_open and attr.form_item_open == "true") then
						attr.form_item_open = true;
					else
						attr.form_item_open = false;
					end
					if(attr.broadcast_gsid) then
						attr.broadcast_gsid = tonumber(attr.broadcast_gsid);
					end
					if(attr.local_bbs_gsid) then
						local local_bbs_gsid = {};
						local gsid;
						for gsid in attr.local_bbs_gsid:gmatch("%d+") do
							local_bbs_gsid[tonumber(gsid)] = true;
						end
						attr.local_bbs_gsid = local_bbs_gsid;
					end
					attr.no_increase = (attr.no_increase == "true");

					local transfer;
					for transfer in commonlib.XPath.eachNode(node, "/transfer") do
						transfer.attr.count = tonumber(transfer.attr.count or 0);
						transfer.attr.min = tonumber(transfer.attr.min or 1);
						transfer.attr.max = tonumber(transfer.attr.max or transfer.attr.min);
						transfer.attr.loot, transfer.attr.total_rate = PowerExtendedCost.ParseLootString(transfer.attr.loot);
					end
				elseif(ex_type == "select_one") then
					local from = {};
					local gsid;
					for gsid in attr.from:gmatch("(%d+)") do
						from[#from+1] = tonumber(gsid);
					end
					local gsid, count = attr.first_cost:match("(%d+),(%d+)");
					attr.first_cost_gsid = tonumber(gsid);
					attr.first_cost_count = tonumber(count) or 1;

					local gsid, count = attr.change_cost:match("(%d+),(%d+)");
					attr.change_cost_gsid = tonumber(gsid);
					attr.change_cost_count = tonumber(count) or 1;
					
					attr.from = from;
				elseif(ex_type == "RankingPurchase") then
					attr.win_gsid = tonumber(attr.win_gsid);
					attr.lose_gsid = tonumber(attr.lose_gsid);
					attr.min_score = tonumber(attr.min_score);
					attr.from_gsid = tonumber(attr.from_gsid);
					attr.from_gsid_count = tonumber(attr.from_gsid_count) or 1;
					attr.to_gsid = tonumber(attr.to_gsid);
					attr.to_gsid_count = tonumber(attr.to_gsid_count) or 1;
				elseif(ex_type == "RankingPurchaseAccordingGS") then
					attr.max_gs =  tonumber(attr.max_gs);
					attr.min_gs =  tonumber(attr.min_gs);
					attr.to_gsid = tonumber(attr.to_gsid);
					attr.to_gsid_count = tonumber(attr.to_gsid_count) or 1;
				elseif(ex_type == "MemoryExchange") then
					attr.gsid = tonumber(attr.gsid);
					attr.gsid_count = tonumber(attr.gsid_count) or 1;
					attr.max_count = tonumber(attr.max_count);
				elseif(ex_type == "SharedLoot") then
					attr.from_gsid = tonumber(attr.from_gsid);
					attr.from_gsid_count = tonumber(attr.from_gsid_count) or 1;
				elseif(ex_type == "FateCard") then
					attr.from_gsid = tonumber(attr.from_gsid);
					attr.pre_gsid = tonumber(attr.pre_gsid);
					attr.from_gsid_count = tonumber(attr.from_gsid_count) or 1;	
					for transfer in commonlib.XPath.eachNode(node, "/transfer") do
						local min_count,max_count;
						--echo(transfer);
						for min_count,max_count in string.gmatch(transfer.attr.pre_num,"(%d+),(%d+)") do
							if(not transfer.attr.pre) then
								transfer.attr.pre = {};
							end
							transfer.attr.pre = {min = tonumber(min_count),max = tonumber(max_count)};
						end
						local loot;
						transfer.loots = {};
						--PowerExtendedCost.ParseLootString2(loot_str)
						for loot in commonlib.XPath.eachNode(transfer, "/loot") do
							local rate = tonumber(loot.attr.odds);
							--echo(loot.attr.lose);
							transfer.loots[#transfer.loots + 1] = {rate = rate,get = PowerExtendedCost.ParseLootString2(loot.attr.get),lose = PowerExtendedCost.ParseLootString2(loot.attr.lose)};
							
						end
					end	
					--echo(node);
				elseif(ex_type == "FateCardBigAward") then
					attr.to_gsid = tonumber(attr.to_gsid);
					local list = {};
					local gsid;
					for gsid in string.gmatch(attr.from_gsid,"%d+") do
						gsid = tonumber(gsid);
						table.insert(list,gsid);
					end
					attr.from_gsid = list;
				elseif(ex_type == "OneOfMulPreCanGet") then
					attr.to_gsid = tonumber(attr.to_gsid);
					local pre = {};
					local gsid;
					for gsid in string.gmatch(attr.pre_gsids,"%d+") do
						table.insert(pre,tonumber(gsid));
					end
					attr.pre_gsids = pre;
				elseif(ex_type == "CombatPetAdvanced") then
					local from_others = {};
					local gsid,number;
					for gsid,number in attr.from_others:gmatch("(%d+),(%d+)") do
						from_others[#from_others+1] = {gsid = tonumber(gsid),number = tonumber(number)};
					end

					attr.from_others = from_others;

					attr.from_pet_gsid = tonumber(attr.from_pet_gsid);
					attr.to_pet_gsid = tonumber(attr.to_pet_gsid);
					attr.need_pet_exp = tonumber(attr.need_pet_exp);
				end
			end
		end
	end
end

-- extended cost
-- @param exid: extended cost id
-- @param (optional)params: params table
-- @param callbackFunc: the callback function(msg) end immediately after extended cost
function PowerExtendedCost.ExtendedCost(nid, exid, params, callbackFunc)
	local ex_template = PowerExtendedCost.GetExtendedCostTemplateInMemory(exid);
	if(not ex_template) then
		-- unknown extended cost
		return;
	end
	local ex_type = ex_template.attr.type;
	if(ex_type == "transfer_with_factor") then
		PowerExtendedCost.transfer_with_factor(nid, ex_template, params, callbackFunc);
	elseif(ex_type == "advanced_lottery") then
		PowerExtendedCost.advanced_lottery(nid, ex_template, params, callbackFunc);
	elseif(ex_type == "select_one") then
		PowerExtendedCost.select_one(nid, ex_template, params, callbackFunc);
	elseif(ex_type == "dragon_belief") then
		PowerExtendedCost.dragon_belief(nid, ex_template, params, callbackFunc);
	elseif(ex_type == "MemoryExchange") then
		PowerExtendedCost.MemoryExchange(nid, ex_template, params, callbackFunc);
	elseif(ex_type == "SharedLoot") then
		PowerExtendedCost.SharedLoot(nid, ex_template, params, callbackFunc);
	elseif(ex_type == "RankingPurchase") then
		PowerExtendedCost.RankingPurchase(nid, ex_template, params, callbackFunc);
	elseif(ex_type == "RankingPurchaseAccordingGS") then
		PowerExtendedCost.RankingPurchaseAccordingGS(nid, ex_template, params, callbackFunc);
	elseif(ex_type == "FateCard") then
		PowerExtendedCost.NormalExtendCost(nid, ex_template, params, callbackFunc);
	elseif(ex_type == "FateCardBigAward") then
		PowerExtendedCost.FromLotToOneExtendCost(nid, ex_template, params, callbackFunc);
	elseif(ex_type == "OneOfMulPreCanGet") then
		PowerExtendedCost.OneOfMulPreCanGet(nid, ex_template, params, callbackFunc);
	elseif(ex_type == "CombatPetAdvanced") then
		PowerExtendedCost.CombatPetAdvanced(nid, ex_template, params, callbackFunc);
	end
end

--[[
例如将5级宝石合成为更高级别的6，7，8，9级宝石（6级不同品质的）
  type="transfer_with_factor"
  将物品集A(from) 转化为 成功物品集B(to) 或 失败物品集C(fail_to)
  基础成功概率为base_success_rate, 用物品rate_gsid N个， 可以提高成功率到min(base_success_rate+(rate_gsid_factor*N), max_success_rate), 
  其中max_success_rate是最大成功率， 默认为1. 
@param msg: {from=string_src_gsid, rate_gsid_count = number}
]]
function PowerExtendedCost.transfer_with_factor(nid, ex_template, params, callbackFunc)
	local attr = ex_template.attr;
	local nid = tonumber(nid);
	local from = tostring(params.from);
	local from_gsid;
	if(from) then
		from_gsid = tonumber(from);
	end
	if(not from_gsid) then
		return;
	end
	if(type(params.rate_gsid_count) ~= "number" or params.rate_gsid_count<0 or not ex_template.attr.rate_gsid) then
		params.rate_gsid_count = 0;
	end
	if(ex_template.attr.rate_gsid_min_count and ex_template.attr.rate_gsid_min_count>(params.rate_gsid_count or 0)) then
		if(callbackFunc) then
			callbackFunc({issuccess = true, reason="rate_gsid_min_count does not match"});
		end
		return;
	end

	local success_rate = math.min(attr.base_success_rate+(attr.rate_gsid_factor*(params.rate_gsid_count or 0)), attr.max_success_rate);
	
	
	local _, transfer_from 
	for _, transfer_from in ipairs(ex_template) do
		local attr = transfer_from.attr;
		if(attr.from == from) then
			local to;
			if(ParaGlobal.random() <= success_rate) then
				to = PowerExtendedCost.GetRandomLoot(attr.to, attr.to_total_rate);
			else
				to = PowerExtendedCost.GetRandomLoot(attr.fail_to, attr.fail_to_total_rate);
			end
			if(to) then
				local adds_str = "";

				local pres;
				if(ex_template.attr.from_gsid) then
					adds_str = adds_str..format("%d~%d~%s~%s|", ex_template.attr.from_gsid, -ex_template.attr.from_count, "NULL", "NULL");
					pres = (pres or "")..format("%d~%d|", ex_template.attr.from_gsid, ex_template.attr.from_count);
				end

				if(to.gsid ~= from_gsid) then
					adds_str = adds_str..format("%d~%d~%s~%s|", to.gsid, to.count, "NULL", "NULL");
					adds_str = adds_str..format("%d~%d~%s~%s|", from_gsid, -1, "NULL", "NULL");
				end
				if( params.rate_gsid_count > 0) then
					adds_str = adds_str..format("%d~%d~%s~%s|", tonumber(ex_template.attr.rate_gsid), -params.rate_gsid_count, "NULL", "NULL");
					pres = (pres or "")..format("%d~%d|", tonumber(ex_template.attr.rate_gsid), params.rate_gsid_count);
				end

				
				if(adds_str~="") then
					-- add always_to like exp
					if(ex_template.attr.always_to_gsid) then
						adds_str = adds_str..format("%d~%d~%s~%s|", ex_template.attr.always_to_gsid, ex_template.attr.always_to_count, "NULL", "NULL");
					end

					PowerItemManager.ChangeItem(nid, adds_str, nil, function(msg)
						if(msg.issuccess) then
							---- TODO: update the gear with new serverdata
							LOG.std(nil, "debug", "PowerExtendedCost", "PowerExtendedCost.transfer_with_factor %d with exid:%s succeed with %s", nid, ex_template.attr.id or "", adds_str);
						else
							LOG.std(nil, "debug", "PowerExtendedCost", "PowerExtendedCost.transfer_with_factor %d with exid:%s callback function got error msg:%s", nid, ex_template.attr.id or "", commonlib.serialize_compact(msg));
						end
						if(callbackFunc) then
							callbackFunc(msg);
						end
						-- some handler
					end, ex_template.attr.greedy_mode, pres, true); -- false for non-greedy
				else
					if(callbackFunc) then
						callbackFunc({issuccess = true});
					end
				end
			end
			break;
		end
	end
end

--[[
例子： 根据次数来抽奖, 最后有概率中大奖。 
每次执行抽奖， 会消耗from="gsid,count"的物品， 并将物品count_gsid=gsid的个数+1. 每1个transfer 定义了当count_gsid的个数小于transfer.count时，
所采用的掉落。 transfer.loot是本次抽奖的掉落，以及每种物品的相对概率。 min, max 保证至少/至多会有多少个。 
只有一个transfer会被执行。 任何情况下， 只要抽中了final_reward_gsid="gsid,count"中的物品， count_gsid会被重置为0.
type="advanced_lottery"
transfer.count:  count_gsid 小于等级为这个数值时， 采用self.loot 掉落
transfer.loot:  按照配置掉落物品，[gsid, count] = relative_probability.
]]
function PowerExtendedCost.advanced_lottery(nid, ex_template, params, callbackFunc)

	local attr = ex_template.attr;

	local bHas, _, _, copies = PowerItemManager.IfOwnGSItem(nid, attr.from_gsid);
	copies = copies or 0;

	if(copies < attr.from_count) then
		if(callbackFunc) then
			callbackFunc({issuccess=false});
		end
	end
	bHas, _, _, copies = PowerItemManager.IfOwnGSItem(nid, attr.count_gsid);
	copies = copies or 0;
	
	local count = #ex_template;
	local selected_transfer;
	local i;
	for i = 1, count do
		local transfer = ex_template[i];
		transfer.attr.count = tonumber(transfer.attr.count or 0);
		if(copies<=transfer.attr.count or i == count) then
			-- currently only a single item is selected. 
			local current_loot = PowerExtendedCost.GetRandomLoot(transfer.attr.loot, transfer.attr.total_rate)
			
			if(current_loot) then
				local adds_str = "";
				if(current_loot.gsid~= attr.from_gsid) then
					-- special case: the reward is the from_gsid item, we will not decrease it. 
					adds_str = adds_str..format("%d~%d~%s~%s|", attr.from_gsid, -attr.from_count, "NULL", "NULL");
				end

				pres = format("%d~%d|", attr.from_gsid, attr.from_count);
				pres = (pres or "")..format("%d~%d|", attr.count_gsid, copies);

				local bBoardCast,bBoardCastLocal;
				if(current_loot.gsid) then
					adds_str = adds_str..format("%d~%d~%s~%s|", current_loot.gsid, current_loot.count or 1, "NULL", "NULL");
					
					if(current_loot.gsid == attr.final_reward_gsid) then
						adds_str = adds_str..format("%d~%d~%s~%s|", attr.count_gsid, -copies, "NULL", "NULL");
						if(attr.broadcast_gsid == attr.final_reward_gsid) then
							bBoardCast = true;
						end
					else
						if(not attr.no_increase) then
							adds_str = adds_str..format("%d~%d~%s~%s|", attr.count_gsid, 1, "NULL", "NULL");
						end
					end

					if(attr.local_bbs_gsid and attr.local_bbs_gsid[current_loot.gsid]) then
						bBoardCastLocal = true;
					end
				end

				PowerItemManager.ChangeItem(nid, adds_str, nil, function(msg)
					if(msg.issuccess) then
						---- TODO: update the gear with new serverdata
						LOG.std(nil, "debug", "PowerExtendedCost", "PowerExtendedCost.advanced_lottery %d with exid:%s succeed with %s", nid, ex_template.attr.id or "", adds_str);
						if(bBoardCast or bBoardCastLocal) then
							-- broadcast msg
							local user_info = PowerItemManager.GetUserAndDragonInfoInMemory(nid)
							local user_name;
							if(user_info and user_info.user) then
								user_name = user_info.user.nickname;
								if(attr.form_item_open) then
									Map3DSystem.GSL.system:SendChat(nil, format("/lotteryFormItem %s %d %d %d %s", tostring(nid), attr.from_gsid , current_loot.gsid, 1, user_name or ""), not bBoardCastLocal);
								else
									Map3DSystem.GSL.system:SendChat(nil, format("/lottery %s %d %d %s", tostring(nid), current_loot.gsid, 1, user_name or ""), not bBoardCastLocal);
								end
							end
						end
					else
						LOG.std(nil, "debug", "PowerExtendedCost", "PowerExtendedCost.advanced_lottery %d with exid:%s callback function got error msg:%s", nid, ex_template.attr.id or "", commonlib.serialize_compact(msg));
					end
					if(callbackFunc) then
						callbackFunc(msg);
					end
					-- some handler
				end, true, pres, true); -- greedy mode
			end
			break;
		end
	end
end

--[[
 type="select_one": 从指定的一组GSID中选择1个。 
  from: 一组GSID， 只能有一个。 
  first_cost: 用户首次选择时，需要消耗的物品和个数。 空代表免费。 例如(984,50)
  change_cost：当用户已经有了一个from中的物品， 需要更换到另外一个时，需要消耗的物品和个数。空代表免费.例如(984,50)

@param params: {gsid}
]]
function PowerExtendedCost.select_one(nid, ex_template, params, callbackFunc)
	local attr = ex_template.attr;

	if(not params.gsid) then
		return;
	end
	local new_gsid = tonumber(params.gsid);
	if(not new_gsid) then
		return;
	end
	local adds_str = "";
	local pres = "";
	local owned_gsids = {};
	local has_item;
	local _, gsid

	local is_in_from;
	for _, gsid in ipairs(attr.from) do
		if(gsid == new_gsid) then
			is_in_from = true;
		end
		local bHas, _, _, copies = PowerItemManager.IfOwnGSItem(nid, gsid);
		if(bHas) then
			copies = copies or 1
			owned_gsids[gsid] = copies;
			adds_str = adds_str..format("%d~%d~%s~%s|", gsid, -copies, "NULL", "NULL");
			pres = pres..format("%d~%d|", gsid, copies);
			has_item = true;
			
		end
	end

	if(not is_in_from) then
		LOG.std(nil, "warn", "PowerExtendedCost", "PowerExtendedCost.select_one %d with exid:%s cheating detected", nid, ex_template.attr.id or "");
		return;
	end

	if(has_item) then
		if(owned_gsids[new_gsid]) then
			-- already has it, return immediately
			if(callbackFunc) then
				callbackFunc({issuccess=true});
			end
			return;
		else
			if(attr.change_cost_gsid) then
				adds_str = adds_str..format("%d~%d~%s~%s|", attr.change_cost_gsid, -attr.change_cost_count, "NULL", "NULL");
				pres = pres..format("%d~%d|", attr.change_cost_gsid, attr.change_cost_count);
			end
		end
	else
		if(attr.first_cost_gsid) then
			adds_str = adds_str..format("%d~%d~%s~%s|", attr.first_cost_gsid, -attr.first_cost_count, "NULL", "NULL");
			pres = pres..format("%d~%d|", attr.first_cost_gsid, attr.first_cost_count);
		end
	end

	adds_str = adds_str..format("%d~%d~%s~%s|", new_gsid, 1, "NULL", "NULL");
	
	PowerItemManager.ChangeItem(nid, adds_str, nil, function(msg)
		if(msg.issuccess) then
			LOG.std(nil, "debug", "PowerExtendedCost", "PowerExtendedCost.select_one %d with exid:%s succeed with %s", nid, ex_template.attr.id or "", adds_str);
		else
			LOG.std(nil, "debug", "PowerExtendedCost", "PowerExtendedCost.select_one %d with exid:%s callback function got error msg:%s", nid, ex_template.attr.id or "", commonlib.serialize_compact(msg));
		end
		if(callbackFunc) then
			callbackFunc(msg);
		end
		-- some handler
	end, true, pres, true); -- greedy mode
end

--[[根据用户的信仰经验等级(gsid=50359)和物品的经验等级(stat=70)， 来增加用户的信仰经验。
当等级一样时增加stat(71)的信仰经验
当等级相差N级时增加stat(71)的信仰经验*(1-30%*N), where N =  math.floor(math.abs(item_level*3 - (cur_level or 1)) / 3)
]]
function PowerExtendedCost.dragon_belief(nid, ex_template, params, callbackFunc)
	if(not params.gsid) then
		return;
	end
	local gsid = tonumber(params.gsid);
	if(not gsid) then
		return;
	end
	local exp_gsid = if_else(System.options.version == "kids", 50359, 50389);
	local bHas, _, _, copies = PowerItemManager.IfOwnGSItem(nid, exp_gsid);

	local _, total_level, cur_level = Card.GetStatsFromDragonTotemProfessionAndExp(if_else(System.options.version == "kids", 50351, 50381), exp_gsid, copies or 0);

	local gsItem = PowerItemManager.GetGlobalStoreItemInMemory(gsid)
	if(gsItem) then
		local item_level = gsItem.template.stats[70]
		local item_exp = gsItem.template.stats[71]
		
		if(item_level and item_exp) then
			local diff = math.floor(math.abs(item_level*3 - (cur_level or 1)) / 3);
			local diff_percent = (1-0.3*diff);
			if(diff_percent > 0) then
				item_exp = math.floor(item_exp * diff_percent);

				local adds_str = format("%d~%d~%s~%s|", gsid, -1, "NULL", "NULL");
				adds_str = adds_str..format("%d~%d~%s~%s|", exp_gsid, item_exp, "NULL", "NULL");
				local pres = format("%d~%d|", gsid, 1);

				PowerItemManager.ChangeItem(nid, adds_str, nil, function(msg)
					if(msg.issuccess) then
						LOG.std(nil, "debug", "PowerExtendedCost", "PowerExtendedCost.dragon_belief %d with exid:%s succeed with %s", nid, ex_template.attr.id or "", adds_str);
					else
						LOG.std(nil, "debug", "PowerExtendedCost", "PowerExtendedCost.dragon_belief %d with exid:%s callback function got error msg:%s", nid, ex_template.attr.id or "", commonlib.serialize_compact(msg));
					end
					if(callbackFunc) then
						callbackFunc(msg);
					end
					-- some handler
				end, false, pres, true); -- non-greedy mode
			end
		end
	end
end

--[[ 根据积分 兑换物品
<extendedcost type="RankingPurchase" id="rank_medal_10_1v1" win_gsid="20046" lose_gsid="20047" min_score="100" from_gsid="" from_gsid_count="" to_gsid="20057" to_gsid_count="1"></extendedcost>

System.GSL_client:SendRealtimeMessage("sPowerAPI", {name="PowerExtendedCost", params={exid="rank_medal_10_1v1",}});
]]
function PowerExtendedCost.RankingPurchase(nid, ex_template, params, callbackFunc)
	local attr = ex_template.attr;
	if(not attr.win_gsid or not attr.min_score) then
		return;
	end
	
	local _, _, _, win_count = PowerItemManager.IfOwnGSItem(nid, attr.win_gsid);
	if(win_count) then
		local _, _, _, lose_count = PowerItemManager.IfOwnGSItem(nid, attr.lose_gsid);
		
		local ranking_score = 1000 + win_count - (lose_count or 0);
		if(ranking_score >= attr.min_score) then
			
			local adds_str = format("%d~%d~%s~%s|", attr.to_gsid, attr.to_gsid_count, "NULL", "NULL");

			local pres = "";
			if(attr.from_gsid) then
				adds_str = adds_str..format("%d~%d~%s~%s|", attr.from_gsid, -attr.from_gsid_count, "NULL", "NULL");
				pres = format("%d~%d|", attr.from_gsid, attr.from_gsid_count);
			end

			PowerItemManager.ChangeItem(nid, adds_str, nil, function(msg)
					if(msg.issuccess) then
						LOG.std(nil, "debug", "PowerExtendedCost", "PowerExtendedCost.RankingPurchase %d with exid:%s succeed with %s", nid, ex_template.attr.id or "", adds_str);
					else
						LOG.std(nil, "debug", "PowerExtendedCost", "PowerExtendedCost.RankingPurchase %d with exid:%s callback function got error msg:%s", nid, ex_template.attr.id or "", commonlib.serialize_compact(msg));
					end
					if(callbackFunc) then
						callbackFunc(msg);
					end
					-- some handler
				end, false, pres, true); -- non-greedy mode
			return;
		end
	end
	
	if(callbackFunc) then
		-- not enough ranking score. 
		callbackFunc({issuccess=false, errorcode=493});
	end
end

--[[ 根据战斗力 兑换物品
<extendedcost type="RankingPurchase" id="rank_medal_399_1v1" rank_gearscore="399" from="" to_gsid="20057" to_gsid_count="1"></extendedcost>

System.GSL_client:SendRealtimeMessage("sPowerAPI", {name="PowerExtendedCost", params={exid="rank_medal_10_1v1",}});
]]
function PowerExtendedCost.RankingPurchaseAccordingGS(nid, ex_template, params, callbackFunc)
	local attr = ex_template.attr;
	
	local _, _, _, player_gs = PowerItemManager.IfOwnGSItem(nid, 965);
	if(player_gs) then
		if(attr.min_gs and player_gs < attr.min_gs) then
			return;
		end

		local adds_str = format("%d~%d~%s~%s|", attr.to_gsid, attr.to_gsid_count, "NULL", "NULL");

		local pres = "";

		PowerItemManager.ChangeItem(nid, adds_str, nil, function(msg)
				if(msg.issuccess) then
					LOG.std(nil, "debug", "PowerExtendedCost", "PowerExtendedCost.RankingPurchaseAccordingGS %d with exid:%s succeed with %s", nid, ex_template.attr.id or "", adds_str);
				else
					LOG.std(nil, "debug", "PowerExtendedCost", "PowerExtendedCost.RankingPurchaseAccordingGS %d with exid:%s callback function got error msg:%s", nid, ex_template.attr.id or "", commonlib.serialize_compact(msg));
				end
				if(callbackFunc) then
					callbackFunc(msg);
				end
				-- some handler
			end, false, pres, true); -- non-greedy mode
		return;

	end
	
	if(callbackFunc) then
		-- not enough gearscore. 
		callbackFunc({issuccess=false, errorcode=493});
	end
end

--[[将GameServer内存中的物品全部兑换为GSID物品. 
  我们可以根据玩家的在线时长，或其他GameServer逻辑，来让用户在离开gateway前， 兑换一些真实物品。 例如采集星星， 田园种植，挂机等都可以用此兑换。 
  GameServer只需根据玩家的行为和在线时长向内存中写入数据即可。 非常适合结算类的物品奖励。 
  @param pres: 前提条件， 例如必须VIP或拥有某些物品才可以兑换。 
  @param from_memory_object: 内存对象的名字. 每个用户登录gateway后， 会有一个自己的内存区，并且会清掉同线程中之前的内存区
    @param gsid, gsid_count: 每个内存兑换， 可以兑换什么物品， 以及多少物品。默认为1个。 
  @param max_count： 兑换上限。 

  <extendedcost type="MemoryExchange" id="time_get_stars" pres="" from_memory_object="mc_stars" gsid="17213" gsid_count="1" max_count="100"></extendedcost>
]]
function PowerExtendedCost.MemoryExchange(nid, ex_template, params, callbackFunc)
end

--[[全服共享掉落。 一般我们会将一个MaxCount==1的稀有掉落或兑换物作为前提条件和From.然后执行一个TryGetSharedLoot
无论是否成功, 前置条件的物品都会被清除. 
  @param from_gsid: 前提条件物品
  @param from_gsid_count: 前提条件物品数量 默认为1
  @param loot_name: shared_loot 名称. 请参考config/Aries/Others/SharedLoot.kids|teen.xml
  <extendedcost type="SharedLoot" id="get_XXXX" from_gsid="984" from_gsid_count="123" loot_name="XXXX"></extendedcost>
]]
function PowerExtendedCost.SharedLoot(nid, ex_template, params, callbackFunc)
	local attr = ex_template.attr;
	if(not attr.from_gsid or not attr.loot_name) then
		return;
	end

	local adds_str = format("%d~%d~%s~%s|", attr.from_gsid, -attr.from_gsid_count, "NULL", "NULL");
	local pres = format("%d~%d|", attr.from_gsid, attr.from_gsid_count);

	PowerItemManager.ChangeItem(nid, adds_str, nil, function(msg)
		if(msg.issuccess) then
			LOG.std(nil, "debug", "PowerExtendedCost", "PowerExtendedCost.SharedLoot %d with exid:%s succeed with %s", nid, ex_template.attr.id or "", adds_str);
			Map3DSystem.GSL.system:TryGetSharedLoot(nid, attr.loot_name);
		else
			LOG.std(nil, "debug", "PowerExtendedCost", "PowerExtendedCost.SharedLoot %d with exid:%s callback function got error msg:%s", nid, ex_template.attr.id or "", commonlib.serialize_compact(msg));
		end
		if(callbackFunc) then
			callbackFunc(msg);
		end
		-- some handler
	end, false, pres, true); -- non-greedy mode
end

--[[ 和84兑换类似，不过前提条件和兑换项很多

]]

function PowerExtendedCost.NormalExtendCost(nid, ex_template, params, callbackFunc)
	local attr = ex_template.attr;

	local bHas, _, _, copies = PowerItemManager.IfOwnGSItem(nid, attr.from_gsid);
	copies = copies or 0;

	if(copies < attr.from_gsid_count) then
		if(callbackFunc) then
			callbackFunc({issuccess=false});
		end
	end
	local pre_copies;
	bHas, _, _, pre_copies = PowerItemManager.IfOwnGSItem(nid, attr.pre_gsid);
	pre_copies = pre_copies or 0;



	local count = #ex_template;
	--echo(ex_template);
	for i = 1, count do
		local transfer = ex_template[i];
		--echo("6666666666");
		--echo(transfer);
		local pre_ok = true;
		--echo(transfer.attr.pre)
		--echo(pre_copies);
		if(transfer.attr.pre) then
			local min_count = transfer.attr.pre.min;
			local max_count = transfer.attr.pre.max;
			if( pre_copies < min_count or pre_copies > max_count) then
				pre_ok = false;
				--echo("XXXXXXXXX");
			end
		end
		--echo("22222");
		--echo(pre_ok);
		local loot;
		if(pre_ok) then
			local curRate = math.random(1,1000);
			--echo("22222");
			--echo(curRate);
			local totolRate = 0;
			for i = 1,#transfer.loots do
				if(curRate <= transfer.loots[i].rate) then
					loot = {get = transfer.loots[i].get,lose = transfer.loots[i].lose};
					break;
				end
				curRate = curRate - transfer.loots[i].rate;
				--transfer.loots[i].rate
			end
			--echo("11111");
			--echo(loot);
			if(loot) then
				local adds_str = "";
				adds_str = adds_str..format("%d~%d~%s~%s|", attr.from_gsid, -attr.from_gsid_count, "NULL", "NULL");

				for i = 1,#loot.get do
					adds_str = adds_str..format("%d~%d~%s~%s|", loot.get[i].gsid, loot.get[i].count, "NULL", "NULL");
				end

				for i = 1,#loot.lose do
					adds_str = adds_str..format("%d~%d~%s~%s|", loot.lose[i].gsid, -loot.lose[i].count, "NULL", "NULL");
				end
				local pres;
				pres = (pres or "")..format("%d~%d|", ex_template.attr.from_gsid, ex_template.attr.from_gsid_count);
				PowerItemManager.ChangeItem(nid, adds_str, nil, function(msg)
					if(msg.issuccess) then
						---- TODO: update the gear with new serverdata
						--LOG.std(nil, "debug", "PowerExtendedCost", "PowerExtendedCost.advanced_lottery %d with exid:%s succeed with %s", nid, ex_template.attr.id or "", adds_str);
						--if(bBoardCast or bBoardCastLocal) then
							---- broadcast msg
							--local user_info = PowerItemManager.GetUserAndDragonInfoInMemory(nid)
							--local user_name;
							--if(user_info and user_info.user) then
								--user_name = user_info.user.nickname;
								--Map3DSystem.GSL.system:SendChat(nil, format("/lottery %s %d %d %s", tostring(nid), current_loot.gsid, 1, user_name or ""), not bBoardCastLocal);
							--end
						--end
					else
						LOG.std(nil, "debug", "PowerExtendedCost", "PowerExtendedCost.advanced_lottery %d with exid:%s callback function got error msg:%s", nid, ex_template.attr.id or "", commonlib.serialize_compact(msg));
					end
					if(callbackFunc) then
						callbackFunc(msg);
					end
					-- some handler
				end, true, pres, true); -- greedy mode
				break;
			end
		end
	end
end

function PowerExtendedCost.FromLotToOneExtendCost(nid, ex_template, params, callbackFunc)
	local attr = ex_template.attr;

	local adds_str = "";
	for i = 1,#attr.from_gsid do
		local gsid = attr.from_gsid[i];
		local bHas = PowerItemManager.IfOwnGSItem(nid, gsid);
		if(not bHas) then
			--echo(gsid);
			if(callbackFunc) then
				callbackFunc({issuccess=false});
			end
			return;
		end
		adds_str = adds_str..format("%d~%d~%s~%s|", gsid, -1, "NULL", "NULL");
	end

	adds_str = adds_str..format("%d~%d~%s~%s|", attr.to_gsid, 1, "NULL", "NULL");
	local pres = "";
	PowerItemManager.ChangeItem(nid, adds_str, nil, function(msg)
		if(msg.issuccess) then
			---- TODO: update the gear with new serverdata
			--LOG.std(nil, "debug", "PowerExtendedCost", "PowerExtendedCost.advanced_lottery %d with exid:%s succeed with %s", nid, ex_template.attr.id or "", adds_str);
		else
			LOG.std(nil, "debug", "PowerExtendedCost", "PowerExtendedCost.advanced_lottery %d with exid:%s callback function got error msg:%s", nid, ex_template.attr.id or "", commonlib.serialize_compact(msg));
		end
		if(callbackFunc) then
			callbackFunc(msg);
		end
		-- some handler
	end, true, pres, true); -- greedy mode
end

function PowerExtendedCost.OneOfMulPreCanGet(nid, ex_template, params, callbackFunc)
	local attr = ex_template.attr;
	local meetPre = false;
	if(attr.pre_gsids and #attr.pre_gsids >= 1) then
		local i;
		for i = 1,#attr.pre_gsids do
			local gsid = attr.pre_gsids[i];
			--meetPre = PowerItemManager.IfOwnGSItem(nid, gsid);
			if(PowerItemManager.IfOwnGSItem(nid, gsid)) then
				meetPre = true;
				break;
			end
		end 
	else
		return;
	end
	if(not meetPre) then
		if(callbackFunc) then
			callbackFunc({issuccess=false});
		end
		return;
	end
	local adds_str = format("%d~%d~%s~%s|", attr.to_gsid, 1, "NULL", "NULL");
	local pres = "";
	PowerItemManager.ChangeItem(nid, adds_str, nil, function(msg)
		if(msg.issuccess) then
			---- TODO: update the gear with new serverdata
			--LOG.std(nil, "debug", "PowerExtendedCost", "PowerExtendedCost.advanced_lottery %d with exid:%s succeed with %s", nid, ex_template.attr.id or "", adds_str);
		else
			LOG.std(nil, "debug", "PowerExtendedCost", "PowerExtendedCost.advanced_lottery %d with exid:%s callback function got error msg:%s", nid, ex_template.attr.id or "", commonlib.serialize_compact(msg));
		end
		if(callbackFunc) then
			callbackFunc(msg);
		end
		-- some handler
	end, true, pres, true); -- greedy mode
end

function PowerExtendedCost.CombatPetAdvanced(nid, ex_template, params, callbackFunc)
	local attr = ex_template.attr;
	local from_pet_gsid = attr.from_pet_gsid;
	local bHas, from_pet_guid = PowerItemManager.IfOwnGSItem(nid, from_pet_gsid);

	local adds_str = "";
	if(bHas) then
		local item = PowerItemManager.GetItemByGUID(nid, from_pet_guid);
		if(item and item.GetServerData) then
			local params = item:GetServerData();
			if(params and params.exp) then
				if(params.exp < attr.need_pet_exp) then
					LOG.std(nil, "debug", "PowerExtendedCost", "PowerExtendedCost.CombatPetAdvanced %d with exid:%s false,bacause pet(gsid:%d) isn't enough exp", nid, ex_template.attr.id or "", from_pet_gsid);
					return;
				else
					adds_str = adds_str..format("%d~%d~%s~%s|", from_pet_gsid, -1, "NULL", "NULL");
				end
			end
		end
	else
		LOG.std(nil, "debug", "PowerExtendedCost", "PowerExtendedCost.CombatPetAdvanced %d with exid:%s false,bacause has not pet %d", nid, ex_template.attr.id or "", from_pet_gsid);
		return;
	end

	local from_others = attr.from_others;
	for i = 1,#from_others do
		local item = from_others[i];
		local gsid,number = item.gsid,item.number;
		local bHas, _, _, copies = PowerItemManager.IfOwnGSItem(nid, gsid);
		if(bHas and copies >= number) then
			adds_str = adds_str..format("%d~%d~%s~%s|", gsid, -number, "NULL", "NULL");
		else
			LOG.std(nil, "debug", "PowerExtendedCost", "PowerExtendedCost.CombatPetAdvanced %d with exid:%s false,bacause isn't enough material:%d", nid, ex_template.attr.id or "", gsid);
			return;
		end
	end
	
	local to_pet_gsid = attr.to_pet_gsid;
	local bHas = PowerItemManager.IfOwnGSItem(nid, to_pet_gsid);
	if(bHas) then
		LOG.std(nil, "debug", "PowerExtendedCost", "PowerExtendedCost.CombatPetAdvanced %d with exid:%s false,bacause has been pet %d", nid, ex_template.attr.id or "", to_pet_gsid);
		return;
	else
		adds_str = adds_str..format("%d~%d~%s~%s|", to_pet_gsid, 1, "NULL", "NULL");
	end

	local pres = "";
	PowerItemManager.ChangeItem(nid, adds_str, nil, function(msg)
		if(msg.issuccess) then
			---- TODO: update the gear with new serverdata
			--LOG.std(nil, "debug", "PowerExtendedCost", "PowerExtendedCost.advanced_lottery %d with exid:%s succeed with %s", nid, ex_template.attr.id or "", adds_str);
		else
			LOG.std(nil, "debug", "PowerExtendedCost", "PowerExtendedCost.CombatPetAdvanced %d with exid:%s callback function got error msg:%s", nid, ex_template.attr.id or "", commonlib.serialize_compact(msg));
		end
		if(callbackFunc) then
			callbackFunc(msg);
		end
		-- some handler
	end, false, pres, true); -- greedy mode
end