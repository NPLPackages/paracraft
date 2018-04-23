--[[
Title: Server agent template class
Author(s): 
Date: 2009/11/15
Desc: power api server object server class
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemItem/ServerObject/PowerAPI_server.lua");
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/GoldRankingList/ranking_server.lua");
local RankingServer = commonlib.gettable("MyCompany.Aries.GoldRankingList.RankingServer");
NPL.load("(gl)script/apps/GameServer/GSL_config.lua");

local string_find = string.find;
local string_match = string.match;
local table_insert = table.insert;
local math_random = math.random;
local math_floor = math.floor;
local type = type;
local PowerItemManager = commonlib.gettable("Map3DSystem.Item.PowerItemManager");
local PowerExtendedCost = commonlib.gettable("Map3DSystem.Item.PowerExtendedCost");
local gateway = commonlib.gettable("Map3DSystem.GSL.gateway");

-------------------------------------
-- a special server NPC that just echos whatever received. 
-------------------------------------
-- directly keep the server object class and instance
local PowerAPI_server = commonlib.gettable("Map3DSystem.GSL.PowerAPI_server");

Map3DSystem.GSL.config:RegisterNPCTemplate("aries_powerapi", PowerAPI_server)


local server_objects = {};

function PowerAPI_server.CreateInstance(self, revision)
	-- overwrite virtual functions
	self.OnNetReceive = PowerAPI_server.OnNetReceive;
	self.OnFrameMove = PowerAPI_server.OnFrameMove;
	-- uncomment to overwrite default AddRealtimeMessage implementation, such as adding a message compression layer.
	-- self.AddRealtimeMessage = PowerAPI_server.AddRealtimeMessage;
	table.insert(server_objects, self);
end


-- whenever an instance of this server agent has received a real time message from client (from_nid) in gridnode, this function will be called.  
function PowerAPI_server:OnNetReceive(from_nid, gridnode, msg, revision)
	if(from_nid and gridnode and type(msg.name) == "string") then
		local name = msg.name;
		local params = msg.params;
		
		if(name == "ForceUpdateUserAndDragonInfo") then
			log("info: power item server recv client combat exp update\n");
			PowerItemManager.GetUserAndDragonInfo(tonumber(from_nid), function(msg) end, function() end);
		elseif(name == "ForceUpdateFollowPetRelated") then
			log("info: power item server recv client follow pet update\n");
			-- sync user all items
			PowerItemManager.SyncUserItems(tonumber(from_nid), {0,10010,}, function(msg) end, function() end);
		elseif(name == "ForceUpdateBag14") then
			log("info: power item server recv client force bag 14 update\n");
			-- sync user bag 14 items
			PowerItemManager.SyncUserItems(tonumber(from_nid), {14,}, function(msg) end, function() end);
		elseif(name == "ForceUpdateBag12") then
			log("info: power item server recv client force bag 12 update\n");
			-- sync user bag 12 items
			PowerItemManager.SyncUserItems(tonumber(from_nid), {12,}, function(msg) end, function() end);
		elseif(name == "ForceUpdateBag0") then
			log("info: power item server recv client force bag 0 update\n");
			-- sync user bag 0 items
			PowerItemManager.SyncUserItems(tonumber(from_nid), {0,}, function(msg) end, function() end);
		elseif(name == "MountGemInSocket") then
			if(params) then
				PowerItemManager.MountGemInSocket(tonumber(from_nid), params);
			end
		elseif(name == "UnEquipGemFromSocket") then
			if(params) then
				PowerItemManager.UnEquipGemFromSocket(tonumber(from_nid), params);
			end
		elseif(name == "MountGemInSocket2") then
			if(params) then
				PowerItemManager.MountGemInSocket2(tonumber(from_nid), params);
			end
		elseif(name == "UnEquipGemFromSocket2") then
			if(params) then
				PowerItemManager.UnEquipGemFromSocket2(tonumber(from_nid), params);
			end
		elseif(name == "DestroyCardToMagicDirt") then
			if(params) then
				PowerItemManager.DestroyCardToMagicDirt(tonumber(from_nid), params);
			end
		elseif(name == "DirectlyOpenCardPack") then
			if(params) then
				PowerItemManager.DirectlyOpenCardPack(tonumber(from_nid), params);
			end
		elseif(name == "DirectlyOpenGiftPack") then
			if(params) then
				PowerItemManager.DirectlyOpenGiftPack(tonumber(from_nid), params);
			end
		elseif(name == "ItemSetExtendedCost") then
			if(params) then
				PowerItemManager.ItemSetExtendedCost(tonumber(from_nid), params);
			end
		elseif(name == "SetItemAddonLevel") then
			if(params) then
				PowerItemManager.SetItemAddonLevel(tonumber(from_nid), params);
			end
		elseif(name == "DoGemTranslation") then
			if(params) then
				NPL.load("(gl)script/apps/Aries/ApparelTranslation/GemTranslationHelper.lua");
				local GemTranslationHelper = commonlib.gettable("MyCompany.Aries.ApparelTranslation.GemTranslationHelper");
				GemTranslationHelper.DoGemTranslation(tonumber(from_nid),params.from_gsid,params.to_gsid,true)
			end
		elseif(name == "DoGemTranslationKids") then
			if(params) then
				NPL.load("(gl)script/apps/Aries/ApparelTranslation/GemTranslationHelper.lua");
				local GemTranslationHelper = commonlib.gettable("MyCompany.Aries.ApparelTranslation.GemTranslationHelper");
				GemTranslationHelper.DoGemTranslationKids(tonumber(from_nid),params.from_gsid,params.to_gsid,true)
			end
		elseif(name == "SignItem") then
			if(params) then
				PowerItemManager.SignItem(tonumber(from_nid), params);
			end
		elseif(name == "CheckExpire") then
			log("info: check expire item for nid:"..tostring(from_nid).."\n");
			PowerItemManager.CheckExpire(tonumber(from_nid));

		elseif(name == "SubmitScore") then
			if(System.options.version == "kids" and params and params.gsid and tonumber(params.gsid) == 20091) then

			elseif(params and params.rank_name and (params.gsid  or RankingServer.IsSpecialRankingName(params.rank_name) )) then
				-- we only allow gsid type rank to be submitted from client, all other types are rejected. 
				RankingServer.SubmitScore(params.rank_name, from_nid, params.guid or params.gsid, params.score or params.count, function(msg)
					local gridnode = gateway:GetPrimGridNode(tostring(from_nid));
					if(gridnode) then
						local server_object = gridnode:GetServerObject("sPowerAPI");
						if(server_object) then
							server_object:SendRealtimeMessage(tostring(from_nid), {type="reply", name="SubmitScore", input_msg=params, msg=msg});
						end
					end
				end, nil, params.school);
			end
		elseif(name == "PowerExtendedCost") then
			if(params) then
				PowerExtendedCost.ExtendedCost(tonumber(from_nid), params.exid, params, function(msg)
					local gridnode = gateway:GetPrimGridNode(tostring(from_nid));
					if(gridnode) then
						local server_object = gridnode:GetServerObject("sPowerAPI");
						if(server_object) then
							server_object:SendRealtimeMessage(tostring(from_nid), {type="reply", name="PowerExtendedCost", input_msg=params, msg=msg});
						end
					end
				end);
			end
		end
	end
	---- echo real time message to client
	--self:AddRealtimeMessage(msg)
end

-- This function is called by gridnode at normal update interval. One can update persistent data fields in this functions. 
function PowerAPI_server:OnFrameMove(curTime, revision)
	-- update persistent data and let normal update to broadcast to all agents. 
	-- By LiXizhi: no need to call here, this is called periodically in the service module.
	-- PowerAPI_server.CheckInformBags();

	--local old_value = self:GetValue("versioned_data");
	--old_value.nCount = old_value.nCount + 1;
	--self:SetValue("versioned_data", old_value, revision);
end

-- check for update bag and userinfo
function PowerAPI_server.CheckInformBags()
	-- NOTE: we send via every server object
	local inform_update_bags = PowerItemManager.GetInformUpdateBags();
	local nid, bags;
	local count = 0;
	for nid, bags in pairs(inform_update_bags) do
		count = count + 1;
		local bags_need_update_this_nid = "";
		local bag, bNeedUpdate;
		for bag, bNeedUpdate in pairs(bags) do
			if(bNeedUpdate) then
				bags_need_update_this_nid = bags_need_update_this_nid..bag..",";
			end
		end
		if(bags_need_update_this_nid ~= "") then
			local nid_str = tostring(nid);
			local gridnode = gateway:GetPrimGridNode(nid_str);
			if(gridnode) then
				local server_object = gridnode:GetServerObject("sPowerAPI");
				if(server_object) then
					-- tell the user to update bags
					-- update persistent data and let normal update to broadcast to all agents. 
					local msg = bags_need_update_this_nid;
					server_object:SendRealtimeMessage(nid_str, "[Aries][PowerAPI]ForceUpdateUserBags:"..msg);
				end
			end
		end
	end
	if(count>0) then
		PowerItemManager.ClearInformUpdateBags();
	end
end