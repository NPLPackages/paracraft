--[[
Title: item reading
Author(s): WangTian
Date: 2009/8/17
Desc: reading material
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemItem/Item_Reading.lua");
------------------------------------------------------------
]]

local Item_Reading = {};
commonlib.setfield("Map3DSystem.Item.Item_Reading", Item_Reading)

---------------------------------
-- functions
---------------------------------

function Item_Reading:new(o)
	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self
	return o
end

-- When item is clicked through pe:slot
function Item_Reading:OnClick(mouse_button)
	local ItemManager = Map3DSystem.Item.ItemManager;
	if(mouse_button == "left") then
		-- open the MCML page
		local gsid = self.gsid;
		local gsItem = ItemManager.GetGlobalStoreItemInMemory(gsid)
		if(gsItem) then
			local url = gsItem.descfile;
			if(url) then
				--获取要下载的文件列表
				NPL.load("(gl)script/apps/Aries/Books/BookPreloadAssets.lua");
				local download_list = MyCompany.Aries.Books.BookPreloadAssets.GetAssetList(url);
				function showpage()
					System.App.Commands.Call("File.MCMLWindowFrame", {
						url = url, 
						name = "Aries.ViewItemReading", 
						app_key = MyCompany.Aries.app.app_key, 
						isShowTitleBar = false,
						allowDrag = false,
						enable_esc_key = true,
						DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
						style = CommonCtrl.WindowFrame.ContainerStyle,
						zorder = 2,
						directPosition = true,
							align = "_ct",
							x = -848/2,
							y = -600/2,
							width = 848,
							height = 620,
					});
				end
				if(download_list)then
					NPL.load("(gl)script/kids/3DMapSystemUI/MiniGames/PreLoaderDialog.lua");
					commonlib.echo("=============before Aries.ViewItemReading");
					Map3DSystem.App.MiniGames.PreLoaderDialog.StartDownload({
							download_list = download_list,
							txt = {"正在打开图书，请稍等......"},
							custom_percent = 0.2,
							},
						function(msg)
								commonlib.echo("=============after Aries.ViewItemReading");
								commonlib.echo(msg);
								if(msg and msg.state == "finished")then
									showpage();
								end
						end);
				else
					showpage()
				end
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