--[[
Title: Enter Game 
Author(s): LiXizhi
Date: 2013/2/16
Desc:  The very first page shown to the user. It asks the user to create or load or download a game from game market. 
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/GameMarket/AddFlowerToWorks.lua");
local AddFlowerToWorks = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.AddFlowerToWorks");
AddFlowerToWorks.ShowPage(true)
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/main.lua");
NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local Desktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop");
local ItemManager = commonlib.gettable("Map3DSystem.Item.ItemManager");

local AddFlowerToWorks = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.AddFlowerToWorks");

if(System.options.version == "teen") then
	AddFlowerToWorks.FlowerItemBag = 12;
	AddFlowerToWorks.FlowerItemGsid = 17344;
	AddFlowerToWorks.GetFlowerExid = 30908;
	AddFlowerToWorks.MinGetFlowerLevel = 40;
else
	AddFlowerToWorks.FlowerItemBag = 10062;
	AddFlowerToWorks.FlowerItemGsid = 20056;
	AddFlowerToWorks.GetFlowerExid = 1888;
	AddFlowerToWorks.MinGetFlowerLevel = 50;
end
-- this is a read-only bag to receive flowers
AddFlowerToWorks.DonatedFlowerBag = 50201;


local page;
function AddFlowerToWorks.OnInit()
	page = document:GetPageCtrl();
end

function AddFlowerToWorks.GetMyFlowerCount()
	local bOwn, guid, bag, copies = ItemManager.IfOwnGSItem(AddFlowerToWorks.FlowerItemGsid)
	if(bOwn) then
		return copies;
	else
		return 0;
	end
end

function AddFlowerToWorks.ShowPage(bShow)
	local width, height = 350, 70;

	local x,y,width_, height_ = _guihelper.GetLastUIObjectPos();

	
	AddFlowerToWorks.DoAutoPurchase();
	

	System.App.Commands.Call("File.MCMLWindowFrame", {
			url = "script/apps/Aries/Creator/Game/GameMarket/AddFlowerToWorks.html", 
			name = "AddFlowerToWorks.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			bShow = bShow,
			enable_esc_key = true,
			directPosition = true,
				align = "_rt",
				x = -width-5,
				y = y+height_+3,
				width = width,
				height = height,
		});
end

-- do auto purchase if not yet. 
function AddFlowerToWorks.DoAutoPurchase()
	NPL.load("(gl)script/apps/Aries/Player/main.lua");
	local Player = commonlib.gettable("MyCompany.Aries.Player");

	if(Player.GetLevel() < AddFlowerToWorks.MinGetFlowerLevel) then
		return;
	end

	local gsItem = ItemManager.GetGlobalStoreItemInMemory(AddFlowerToWorks.FlowerItemGsid);
	if(gsItem and not AddFlowerToWorks.is_purchased) then
		local maxdailycount = gsItem.maxdailycount;
		local gsObtain = ItemManager.GetGSObtainCntInTimeSpanInMemory(AddFlowerToWorks.FlowerItemGsid);
		if(gsObtain and gsObtain.inday < maxdailycount) then
			if( (gsItem.template.maxcount-maxdailycount) >= AddFlowerToWorks.GetMyFlowerCount()) then
				-- Do purchase
				AddFlowerToWorks.is_purchased = true;
				ItemManager.ExtendedCost( AddFlowerToWorks.GetFlowerExid, nil, nil, function(msg)
					if(msg and msg.issuccess == true)then
						if(page) then
							page:Refresh();
						end
					end
				end,function(msg)end);
			end
		end
	end
end

-- donate flower to bag. 
function AddFlowerToWorks.OnDonateFlower(count)
	local my_flower_count = AddFlowerToWorks.GetMyFlowerCount();
	local to_nid = WorldCommon.GetWorldTag("nid");

	if(tostring(to_nid) == tostring(System.User.nid)) then
		_guihelper.MessageBox("不能给自己投鲜花");
		return;
	elseif(to_nid and to_nid~="" and my_flower_count >= count) then
		paraworld.inventory.DonateToBag({
				gsid = AddFlowerToWorks.FlowerItemGsid, 
				cnt = count, 
				tonid = tonumber(to_nid),
				tobag = AddFlowerToWorks.DonatedFlowerBag,
			}, "SendFlower", function(msg)

			if(msg) then
				if(msg.errorcode and msg.errorcode~=0) then
					LOG.std(nil, "warn", "DoDonateMyItems", "failed to DonateToBag: %s", to_nid);
				elseif(msg.errorcode==0) then
					-- successfully submitted score 
					
					if(AddFlowerToWorks.parent_page) then
						if(AddFlowerToWorks.opc_item) then
							AddFlowerToWorks.opc_item.copies = (AddFlowerToWorks.opc_item.copies or 0) + count;
						end
						AddFlowerToWorks.FlowerCount = (AddFlowerToWorks.FlowerCount or 0) + count;
						AddFlowerToWorks.parent_page:Refresh(0.01);
					end
				end
			end
		end)
	end 
end