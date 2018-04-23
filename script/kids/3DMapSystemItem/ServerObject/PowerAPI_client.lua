--[[
Title: 
Author(s):  WangTian
Date: 2010/9/2
Desc: power api server object client class
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemItem/ServerObject/PowerAPI_client.lua");
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/GoldRankingList/ranking_server.lua");
local RankingServer = commonlib.gettable("MyCompany.Aries.GoldRankingList.RankingServer");

local ItemManager = commonlib.gettable("Map3DSystem.Item.ItemManager");
local type = type;
-------------------------------------
-- a special client NPC on behalf of a server agent, it just shows what is received.
-------------------------------------
local PowerAPI_client = {};

Map3DSystem.GSL.client.config:RegisterNPCTemplate("aries_powerapi", PowerAPI_client)

function PowerAPI_client.CreateInstance(self)
	self.OnNetReceive = PowerAPI_client.OnNetReceive;
	-- uncomment to overwrite default AddRealtimeMessage implementation, such as adding a message compression layer.
	-- self.AddRealtimeMessage = MyEchoNPC_server.AddRealtimeMessage;
	
	-- TODO: add your proviate per instance data here
	self.private_data = {some_per_instance_data_here};
end

-- whenever an instance of this server agent calls AddRealtimeMessage() on the server side(from_nid), the client will receive it via this event callback. 
-- if msg is nil, it means that client has received a normal update of this agent from server and some data fields of the agent have been updated. 
function PowerAPI_client:OnNetReceive(client, msgs)
	if(client and msgs) then
		local _, msg;
		for _, msg in ipairs(msgs) do
			if(type(msg) == "string") then
				local name, return_msg = string.match(msg, "^%[Aries%]%[PowerAPI%]([%w]+):(.+)$");
				if(name == "ForceUpdateUserBags") then
					local bags = return_msg;
					if(bags) then
						-- inform the client to update bags
						local bag;
						for bag in string.gmatch(bags, "[^,]+") do
							bag = tonumber(bag);
							if(bag and bag >= 0) then
								-- update bag
								log("info: force update user bag:"..tostring(bag).."\n")
								ItemManager.GetItemsInBag(bag, "update_server_inform_bags"..bag, function(msg)
									--if(System.options.version == "teen") then
										-- for teen version update the pe:slot and pe:shortcut in the shortcut bar
										Map3DSystem.mcml_controls.GetClassByTagName("pe:slot").RefreshContainingPageCtrls();
									--end
								end, "access plus 0 day");
							elseif(bag == -1) then
								-- update user and dragon info
								log("info: force update user and dragon info\n")
								System.App.profiles.ProfileManager.GetUserInfo(nil, "update_server_inform_userinfo_update", function()end, "access plus 0 day");
								MyCompany.Aries.Pet.GetRemoteValue(nil, function() end, "access plus 0 day");
							end
						end
					end
				elseif(name == "MountGemReply") then
					if(return_msg) then
						return_msg = commonlib.LoadTableFromString(return_msg);
						if(return_msg) then
							ItemManager.MountGemInSocket_callback_from_powerapi(return_msg.seq, return_msg);
						end
					end
				elseif(name == "UnEquipGemReply") then
					if(return_msg) then
						return_msg = commonlib.LoadTableFromString(return_msg);
						if(return_msg) then
							local ItemManager = System.Item.ItemManager;
							ItemManager.UnEquipGemFromSocket_callback_from_powerapi(return_msg.seq, return_msg);
						end
					end
				elseif(name == "MountGemReply2") then
					if(return_msg) then
						return_msg = commonlib.LoadTableFromString(return_msg);
						if(return_msg) then
							local ItemManager = System.Item.ItemManager;
							ItemManager.MountGemInSocket2_callback_from_powerapi(return_msg.seq, return_msg);
						end
					end
				elseif(name == "UnEquipGemReply2") then
					if(return_msg) then
						return_msg = commonlib.LoadTableFromString(return_msg);
						if(return_msg) then
							local ItemManager = System.Item.ItemManager;
							ItemManager.UnEquipGemFromSocket2_callback_from_powerapi(return_msg.seq, return_msg);
						end
					end
				elseif(name == "DestroyCardToMagicDirtReply") then
					if(return_msg) then
						return_msg = commonlib.LoadTableFromString(return_msg);
						if(return_msg) then
							local ItemManager = System.Item.ItemManager;
							ItemManager.DestroyCardToMagicDirt_callback_from_powerapi(return_msg.seq, return_msg);
						end
					end
				elseif(name == "DirectlyOpenCardPackReply") then
					if(return_msg) then
						return_msg = commonlib.LoadTableFromString(return_msg);
						if(return_msg) then
							local ItemManager = System.Item.ItemManager;
							ItemManager.DirectlyOpenCardPack_callback_from_powerapi(return_msg.seq, return_msg);
						end
					end
				elseif(name == "DirectlyOpenGiftPackReply") then
					if(return_msg) then
						return_msg = commonlib.LoadTableFromString(return_msg);
						if(return_msg) then
							local ItemManager = System.Item.ItemManager;
							ItemManager.DirectlyOpenGiftPack_callback_from_powerapi(return_msg.seq, return_msg);
						end
					end
				elseif(name == "MountGemReply") then
					if(return_msg) then
						return_msg = commonlib.LoadTableFromString(return_msg);
						if(return_msg) then
							ItemManager.MountGemInSocket_callback_from_powerapi(return_msg.seq, return_msg);
						end
					end
				elseif(name == "LastPills") then
					if(return_msg) then
						local Dock = commonlib.gettable("MyCompany.Aries.Desktop.Dock");
						Dock.OnLastPillsNotification(return_msg);
					end
				elseif(name == "FullHPAfterPvPTickerCost" and System.options.version ~= "kids") then
					if(return_msg) then
						NPL.load("(gl)script/ide/TooltipHelper.lua");
						local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
						BroadcastHelper.PushLabel({id="pvp_ticket_cost_tip", label = "入场券已消耗！", max_duration=10000, color = "255 0 0", scaling=1.1, bold=true, shadow=true,});
						--MyCompany.Aries.Combat.MsgHandler.HealByWisp(1, true);
					end
				elseif(name == "FullHPAfterPvPCountCost") then
					if(return_msg) then
						NPL.load("(gl)script/ide/TooltipHelper.lua");
						local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
						BroadcastHelper.PushLabel({id="pvp_ticket_cost_tip", label = "今天红蘑菇场次已消耗！", max_duration=10000, color = "255 0 0", scaling=1.1, bold=true, shadow=true,});
						--MyCompany.Aries.Combat.MsgHandler.HealByWisp(1, true);
					end
				elseif(name == "DoGemTranslation") then
					if(return_msg) then
						return_msg = commonlib.LoadTableFromString(return_msg);
						if(return_msg) then
							NPL.load("(gl)script/apps/Aries/ApparelTranslation/GemTranslationPage.lua");
							local GemTranslationPage = commonlib.gettable("MyCompany.Aries.ApparelTranslation.GemTranslationPage");
							GemTranslationPage.DoGemTranslation_Handle(return_msg);
						end
					end
				elseif(name == "DoGemTranslationKids") then
					if(return_msg) then
						return_msg = commonlib.LoadTableFromString(return_msg);
						--[[
						local return_msg = {
								issuccess = true,
								from_gsid = from_gsid,
								to_gsid = to_gsid,
							};
						--]]
						LOG.std(nil, "info", "DoGemTranslationKids", return_msg);
						if(return_msg) then
							NPL.load("(gl)script/apps/Aries/NPCs/ShoppingZone/Avatar_item_upgrade.lua");
							local Avatar_item_upgrade = commonlib.gettable("MyCompany.Aries.NPCs.ShoppingZone.Avatar_item_upgrade");
							Avatar_item_upgrade.OnHandleUpgradeCallback(return_msg);
						end
					end
				elseif(name == "CombatpetUpdateExp") then
					if(return_msg) then
						return_msg = commonlib.LoadTableFromString(return_msg);
						if(return_msg) then
							NPL.load("(gl)script/apps/Aries/Service/CommonClientService.lua");
							local CommonClientService = commonlib.gettable("MyCompany.Aries.Service.CommonClientService");
							if(CommonClientService.IsTeenVersion())then
								NPL.load("(gl)script/apps/Aries/CombatPet/CombatFollowPetPane.lua");
								local CombatFollowPetPane = commonlib.gettable("MyCompany.Aries.CombatPet.CombatFollowPetPane");
								CombatFollowPetPane.UpdateExp(return_msg.add_exp);
							else
								NPL.load("(gl)script/apps/Aries/CombatPet/CombatPetPane.lua");
								local CombatPetPane = commonlib.gettable("MyCompany.Aries.CombatPet.CombatPetPane");
								CombatPetPane.UpdateExp(return_msg.pet_gsid,return_msg.exp,return_msg.add_exp);
							end
							
						end
					end
				end
			elseif(type(msg) == "table") then
				if(msg.type == "reply") then
					if(msg.name == "SetItemAddonLevel") then
						if(msg.msg and msg.msg.issuccess) then
							LOG.std(nil, "info", "PowerItemManager", "PowerItemManager.SetItemAddonLevel succeed: %s", commonlib.serialize_compact(msg));
							if(msg.input_msg) then
								local item = ItemManager.GetItemByGUID(msg.input_msg.guid);
								if(item) then
									ItemManager.UpdateBagItems(msg.msg.ups);
									MyCompany.Aries.event:DispatchEvent({type = "custom_goal_client"},79016);

									NPL.load("(gl)script/ide/TooltipHelper.lua");
									local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
									local gsItem = ItemManager.GetGlobalStoreItemInMemory(item.gsid);
									local item_name = "装备";
									if(gsItem and gsItem.template) then
										item_name = gsItem.template.name;
									end
									local words = format("强化成功, 你的[%s]升到了%d级", item_name, msg.input_msg.addlel)
									BroadcastHelper.PushLabel({id="addonlevel", label = words, max_duration=10000, color = "0 255 0", scaling=1.1, bold=true, shadow=true,});

									local ChatChannel = commonlib.gettable("MyCompany.Aries.ChatSystem.ChatChannel");
									ChatChannel.AppendChat({ChannelIndex=ChatChannel.EnumChannels.System, is_direct_mcml=true, words=words});

									NPL.load("(gl)script/apps/Aries/NPCs/ShoppingZone/Avatar_equip_upgrade.lua");
									local Avatar_equip_upgrade = commonlib.gettable("MyCompany.Aries.NPCs.ShoppingZone.Avatar_equip_upgrade");
									Avatar_equip_upgrade.UpgradeHandle();
								end
							end
						else
							LOG.std(nil, "info", "PowerAPIClient", "PowerItemManager.SetItemAddonLevel failed: %s", commonlib.serialize_compact(msg));
							_guihelper.MessageBox("强化失败了")
						end
					elseif(msg.name == "SignItem") then
						if(msg.msg and msg.msg.issuccess) then
							LOG.std(nil, "info", "PowerAPIClient", "PowerItemManager.SignItem succeed: %s", commonlib.serialize_compact(msg));
							if(msg.input_msg) then
								local item = ItemManager.GetItemByGUID(msg.input_msg.guid);
								if(item) then
									ItemManager.UpdateBagItems(msg.msg.ups, msg.msg.adds);
									_guihelper.MessageBox("恭喜！签名成功")
									NPL.load("(gl)script/apps/Aries/Items/sign_item_page.lua");
									local sign_item_page = commonlib.gettable("MyCompany.Aries.Items.sign_item_page");
									sign_item_page.ClosePage();
								end
							end
						else
							LOG.std(nil, "info", "PowerAPIClient", "PowerItemManager.SignItem failed: %s", commonlib.serialize_compact(msg));
							_guihelper.MessageBox("签名失败了")
						end
					elseif(msg.name == "SubmitScore") then
						local msg_data = msg.msg;
						LOG.std(nil, "info", "PowerAPIClient.SubmitScore.result", msg);
						local GoldRankingListMain = commonlib.gettable("MyCompany.Aries.GoldRankingList.GoldRankingListMain");
						if(GoldRankingListMain.OnSubmitScoreCallback) then
							GoldRankingListMain.OnSubmitScoreCallback(msg);
						end
					elseif(msg.name == "PowerExtendedCost") then
						local msg_data = msg.msg;
						local items_to_add;
						LOG.std(nil, "info", "PowerAPIClient.PowerExtendedCost.result", msg);
						if(msg_data and msg_data.issuccess) then
							items_to_add = ItemManager.UpdateBagItems(msg_data.ups or msg_data.updates, msg_data.adds);
						end
						if(msg.input_msg and msg.input_msg.exid)then
							if(msg.input_msg.exid == "change_religion")then
								NPL.load("(gl)script/apps/Aries/Desktop/CombatCharacterFrame/TotemPage.lua");
								local TotemPage = commonlib.gettable("MyCompany.Aries.Desktop.TotemPage");
								TotemPage.PowerExtendedCost_Handle(msg);
							elseif(msg.input_msg.exid == "change_skill")then
								NPL.load("(gl)script/apps/Aries/Desktop/CombatCharacterFrame/MinorSkillPage.lua");
								local MinorSkillPage = commonlib.gettable("MyCompany.Aries.Desktop.MinorSkillPage");
								MinorSkillPage.PowerExtendedCost_Handle(msg);
							elseif(string.find(msg.input_msg.exid,"Identify"))then
								NPL.load("(gl)script/apps/Aries/Desktop/CombatCharacterFrame/ItemCheckPage.lua");
								local ItemCheckPage = commonlib.gettable("MyCompany.Aries.Desktop.ItemCheckPage");
								ItemCheckPage.PowerExtendedCost_Handle(msg);
							elseif(string.find(msg.input_msg.exid,"lottery"))then
								NPL.load("(gl)script/apps/Aries/Desktop/CombatCharacterFrame/ItemLuckyPage.lua");
								local ItemLuckyPage = commonlib.gettable("MyCompany.Aries.Desktop.ItemLuckyPage");
								ItemLuckyPage.LootHandle(items_to_add);
							elseif(msg.input_msg.exid == "add_dragon_belief")then
								--使用魂印
								NPL.load("(gl)script/apps/Aries/Desktop/CombatCharacterFrame/CombatCharMainFramePage.lua");
								local CombatCharacterFrame = commonlib.gettable("MyCompany.Aries.Desktop.CombatCharacterFrame");
								CombatCharacterFrame.RefreshPage();
							elseif(string.find(msg.input_msg.exid,"FateCard")) then
								NPL.load("(gl)script/apps/Aries/Desktop/Functions/FateCard.lua");
								local FateCard = commonlib.gettable("MyCompany.Aries.Desktop.FateCard");
								FateCard.MsgHandle(msg);
							end	
						end
					end
				end
			end
		end
	elseif(msgs == nil) then
		-- normal update
	end
	
	-- self:AddRealTimeMessage(self.id, msg);
	
	-- one can send real time message to self.id on the server side. 
	-- self:GetValue();
end