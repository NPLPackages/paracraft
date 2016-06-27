--[[
Title: Game Market Place
Author(s): LiXizhi
Date: 2013/7/14
Desc:  the game portal page. 
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/GameMarket/GameShopPage.lua");
local GameShopPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.GameShopPage");
GameShopPage.ShowPage(true)
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/main.lua");
local Desktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop");
local GameShopPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.GameShopPage");
local ItemManager = commonlib.gettable("Map3DSystem.Item.ItemManager");

local pkg_install_path = "worlds/DesignHouse/";

function GameShopPage.OnInit()
end

function GameShopPage.IsSecretKeyPressed()
	if(ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LCONTROL) and ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LSHIFT)) then
		return true;
	end
end

function GameShopPage.ShowPage(bShow)
	local width, height = 512, 480;
	System.App.Commands.Call("File.MCMLWindowFrame", {
			url = "script/apps/Aries/Creator/Game/GameMarket/GameShopPage.html", 
			name = "GameShopPage.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			bShow = bShow,
			directPosition = true,
				align = "_ct",
				x = -width/2,
				y = -height/2,
				width = width,
				height = height,
		});
end


function GameShopPage.OnOpenPkgFile(filename)
	local file_name = filename:match("[^/\\]*$");
	local dest_path = pkg_install_path..file_name;

	_guihelper.MessageBox(format("确定要安装创意空间文件:%s?", commonlib.Encoding.DefaultToUtf8(filename)), function()
		local function CopyFile_()
			if(ParaIO.CopyFile(filename, dest_path, true)) then
				_guihelper.MessageBox(format("世界[%s]安装成功！您可以从创意空间中加载这个世界了", file_name));
			else
				_guihelper.MessageBox(format("无法复制文件到%s", dest_path));
			end
		end
		if(ParaIO.DoesFileExist(dest_path, true)) then
			_guihelper.MessageBox(format("世界[%s]已经安装过， 是否覆盖之前的世界?", file_name), function()
				CopyFile_();
			end);
		else
			CopyFile_();
		end
	end);
end


-- force enter block world edition, only set to true when visit_url is not empty when loading the world.
GameShopPage.ForceEnterBlockWorld = nil;
-- VIP item 
GameShopPage.vip_item_gsid = 17394;
-- VIP trial item: valid for 7 days
-- GameShopPage.vip_trial_item_gsid = 17394;

-- whether the user has the right to do something
function GameShopPage.HaveRight(name)
	if(name == "entergame" or name=="cmd_create" or name=="savegame" or name=="minimap") then
		if(System.options.version == "teen" and (MyCompany.Aries.Player.GetLevel() >= 40)) then
			-- only for player whose level is bigger than 40. 
			return true;
		end
		if(GameShopPage.ForceEnterBlockWorld and name == "entergame") then
			return true;
		end

		if(not System.User.nid or System.User.nid == 0 or System.options.mc)  then
			-- offline mode
			return true;
		end
		local bHas = ItemManager.IfOwnGSItem(GameShopPage.vip_item_gsid);
		if(not bHas and GameShopPage.vip_trial_item_gsid) then
			bHas = ItemManager.IfOwnGSItem(GameShopPage.vip_trial_item_gsid);
		end
		return bHas;
	end
end

-- whether the user has the right to do something, if not it will display the proper error message to the user
function GameShopPage.CheckRight(name)
	local bHasRight = GameShopPage.HaveRight(name)
	if(not bHasRight) then
		_guihelper.MessageBox("你不是创意空间会员, 不能使用这个功能. 是否要立即成为会员?", function(res)
			if(res and res == _guihelper.DialogResult.Yes) then
				-- pressed YES
				local command = System.App.Commands.GetCommand("Profile.Aries.PurchaseItemWnd");
				if(command) then
					command:Call({gsid = GameShopPage.vip_item_gsid});
				end
			end
		end, _guihelper.MessageBoxButtons.YesNo);
	end
	return bHasRight;
end