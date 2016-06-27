--[[
Title: The dock page
Author(s): LiXizhi
Date: 2012/12/28
Desc:  
There dock has 2 mode: one for editor and one for creator
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/QuickSelectBar.lua");
local QuickSelectBar = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.QuickSelectBar");
QuickSelectBar.ShowPage(true)
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Effects/ObtainItemEffect.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/TouchButton.lua");
local TouchButton = commonlib.gettable("MyCompany.Aries.Game.Common.TouchButton");
local ObtainItemEffect = commonlib.gettable("MyCompany.Aries.Game.Effects.ObtainItemEffect");
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local Desktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local QuickSelectBar = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.QuickSelectBar");

-- this should be the same as the items per line. 
QuickSelectBar.static_view_len = 9;
QuickSelectBar.static_view_page_index = 1;
QuickSelectBar.custombtn_nodes = {
	{},{},{},{},{},{},{},{},{},
};
QuickSelectBar.maxHp = 8;
QuickSelectBar.lastHp = 8;
QuickSelectBar.curHp = 8;

QuickSelectBar.maxHunger = 8;
QuickSelectBar.lastHunger = 8;
QuickSelectBar.curHunger = 8;

QuickSelectBar.maxExp = 100;
QuickSelectBar.curExp = 0;

QuickSelectBar.progress_bar_width = 358; 
local custombtn_game_nodes = {}
local custombtn_editor_nodes = {}

-- whether the data is modified. 
QuickSelectBar.IsModified = false;
local page;

local max_item_count = 32;

-- called when block texture changes. 
function QuickSelectBar.OnBlockTexturePackChanged(self, event)
	QuickSelectBar.Refresh();
end

function QuickSelectBar.OnInit()
	page = document:GetPageCtrl();
	if(System.options.IsMobilePlatform) then
		QuickSelectBar.custombtn_nodes = {
			{},{},{},{},{},
		};
	end
	GameLogic.events:AddEventListener("OnHandToolIndexChanged", QuickSelectBar.OnHandToolIndexChanged, QuickSelectBar, "QuickSelectBar");
	GameLogic.events:AddEventListener("SetBlockInRightHand", QuickSelectBar.OnSetBlockInRightHand, QuickSelectBar, "QuickSelectBar");
	GameLogic.events:AddEventListener("block_texture_pack_changed", QuickSelectBar.OnBlockTexturePackChanged, QuickSelectBar, "QuickSelectBar");
	GameLogic.events:AddEventListener("game_mode_change", QuickSelectBar.OnGameModeChanged, QuickSelectBar, "QuickSelectBar");
	GameLogic.events:AddEventListener("OnHintSelectBlock", QuickSelectBar.OnHintSelectBlock, QuickSelectBar, "QuickSelectBar");
	GameLogic.events:AddEventListener("OnPlayerReplaced", QuickSelectBar.OnPlayerReplaced, QuickSelectBar, "QuickSelectBar");
end

------------------------
-- input hooked event handler
------------------------
function QuickSelectBar:OnGameModeChanged(event)
	if(page) then
		if(page:IsVisible()) then 
			if(not GameLogic.GameMode:IsEditor()) then
				QuickSelectBar.ShowPage(false);
				return;
			end
		else
			if(GameLogic.GameMode:IsEditor()) then
				QuickSelectBar.ShowPage(true);
				return;
			end
		end
	end
	QuickSelectBar.Refresh();
end

local last_hind_time;
local last_block_index;
local count_down = 6;
function QuickSelectBar:OnHintSelectBlock(event)
	if(page) then
		last_block_index = event.index or 1;
		
		count_down = 6;

		QuickSelectBar.hint_timer = QuickSelectBar.hint_timer or commonlib.Timer:new({callbackFunc = function(timer)
			count_down = count_down - 1;
			if(GameLogic.GetPlayerController():GetHandToolIndex() == last_block_index or count_down<0) then
				timer:Change();
			else
				QuickSelectBar:AnimateBlockHint(last_block_index);
			end
		end})
		
		if(not QuickSelectBar.hint_timer:IsEnabled()) then
			QuickSelectBar.hint_timer:Change(0, 600);
		end
	end
end

function QuickSelectBar:OnPlayerReplaced()
	if(page) then
		page:Refresh(0.1);
	end
end

function QuickSelectBar:AnimateBlockHint(index)
	if(page) then
		local ctl = page:FindControl("handtool_highlight_bg");
		if(ctl) then
			if(System.options.IsMobilePlatform) then
				local x, y = ctl:GetAbsPosition();
				x = x + ((index or 1)-GameLogic.GetPlayerController():GetHandToolIndex())*76;
				local m_x, m_y = ParaUI.GetMousePosition();
				--ObtainItemEffect:new({background="Texture/Aries/Creator/Theme/GameCommonIcon_32bits.png;464 43 18 18", duration=800, color="#ffffffff", width=18,height=18, 
					--from_2d={x=m_x, y=m_y}, to_2d={x=x+12, y=y+8}}):Play();e

				ObtainItemEffect:new({background="Texture/Aries/Creator/Mobile/blocks_UI_32bits.png#308 1 34 34:12 12 12 12", duration=500, color="#ffffffff", width=76,height=76,
					from_2d={x=x, y=y}, to_2d={x=x, y=y}, fadeIn=200, fadeOut=200}):Play();

				--ObtainItemEffect:new({background="Texture/Aries/Creator/Theme/GameCommonIcon_32bits.png;141 137 30 34", duration=500, color="#ffffffff", width=30,height=34,background-color="#ffffff80", 
					--from_2d={x=x+5, y=y-80}, to_2d={x=x+5, y=y-10}, fadeIn=100, fadeOut=100}):Play();
			else
				local x, y = ctl:GetAbsPosition();
				x = x + ((index or 1)-GameLogic.GetPlayerController():GetHandToolIndex())*41;
				local m_x, m_y = ParaUI.GetMousePosition();
				--ObtainItemEffect:new({background="Texture/Aries/Creator/Theme/GameCommonIcon_32bits.png;464 43 18 18", duration=800, color="#ffffffff", width=18,height=18, 
					--from_2d={x=m_x, y=m_y}, to_2d={x=x+12, y=y+8}}):Play();

				ObtainItemEffect:new({background="Texture/Aries/Creator/Theme/GameCommonIcon_32bits.png;74 45 40 40:12 12 12 12", duration=500, color="#ffffffff", width=42,height=42, 
					from_2d={x=x, y=y}, to_2d={x=x, y=y}, fadeIn=200, fadeOut=200}):Play();

				ObtainItemEffect:new({background="Texture/Aries/Creator/Theme/GameCommonIcon_32bits.png;141 137 30 34", duration=500, color="#ffffffff", width=30,height=34, 
					from_2d={x=x+5, y=y-80}, to_2d={x=x+5, y=y-10}, fadeIn=100, fadeOut=100}):Play();
			end
		end
	end
end

function QuickSelectBar:OnSetBlockInRightHand(event)
	if(page and event.block_id ~= self.last_block_id) then
		local ctl = page:FindControl("handtool_tooltip");
		if(ctl) then
			local block_id = GameLogic.GetPlayerController():GetBlockInRightHand();
			if(block_id and block_id>0) then
				if(System.options.IsMobilePlatform) then
					ctl.x = (GameLogic.GetPlayerController():GetHandToolIndex()-1)*76;
				else
					ctl.x = (GameLogic.GetPlayerController():GetHandToolIndex()-1)*41;
				end
				ctl.visible = true;
			
				local item = ItemClient.GetItem(block_id);
				if(item and item.name) then
					GameLogic:UserAction(format("take %s", item.name));
				end

				local text;
				if(item) then
					text = item:GetDisplayName() or tostring(block_id);
				else
					text = tostring(block_id);
				end
				if(System.options.IsMobilePlatform) then
					ctl.width =  _guihelper.GetTextWidth(text)*1.7+5;
				else
					ctl.width = _guihelper.GetTextWidth(text)*1.2+5;
				end
				

				ctl.text = text;
				if(not QuickSelectBar.tooltip_timer) then
					QuickSelectBar.tooltip_timer = commonlib.Timer:new({callbackFunc = function(timer)
						local ctl = page:FindControl("handtool_tooltip");
						if(ctl) then
							ctl.visible = false;
						end
					end})
				end
				QuickSelectBar.tooltip_timer:Change(4000,nil);
			else
				ctl.visible = false;
				if(QuickSelectBar.tooltip_timer) then
					QuickSelectBar.tooltip_timer:Change();
				end
			end
		end
	end
end

function QuickSelectBar:OnHandToolIndexChanged(event)
	if(page) then
		local ctl = page:FindControl("handtool_highlight_bg");
		if(ctl) then
			if(System.options.IsMobilePlatform) then
				ctl.x = (GameLogic.GetPlayerController():GetHandToolIndex()-1)*77 + 1;
			else
				ctl.x = (GameLogic.GetPlayerController():GetHandToolIndex()-1)*41;
			end
			
		end
	end
end

function QuickSelectBar.ShowPage(bShow)
	if(GameLogic.GameMode:IsMovieMode() and bShow) then
		return;
	end

	local url;
	local width,height;
	if(System.options.IsMobilePlatform) then
		width = 400;
		height = 78;
		url = "script/apps/Aries/Creator/Game/Areas/QuickSelectBar.mobile.html"; 
	else
		width = 412;
		height = 96;
		url = "script/apps/Aries/Creator/Game/Areas/QuickSelectBar.html";
	end

	System.App.Commands.Call("File.MCMLWindowFrame", {
			--url = "script/apps/Aries/Creator/Game/Areas/QuickSelectBar.html", 
			url = url,
			name = "QuickSelectBar.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = false,
			bShow = bShow,
			zorder = -5,
			click_through = true, 
			directPosition = true,
				align = "_ctb",
				x = 0,
				y = 0,
				width = width,
				height = height,
		});
end

function QuickSelectBar.Refresh(nDelayTime)
	if(page) then
		page:Refresh(nDelayTime or 0.01);
	end
end

-- @param key_index: 1-9
function QuickSelectBar.OnSelectByKeyIndex(key_index)
	if(key_index and key_index>=1 and key_index<=QuickSelectBar.static_view_len) then
		local index  = (QuickSelectBar.static_view_page_index-1)*QuickSelectBar.static_view_len + key_index;
		GameLogic.GetPlayerController():SetHandToolIndex(key_index);
	end
end

-- bind the current progress bar to a given progress interface. 
-- the IProgress must have GetMaxValue() and GetValue() and GetEvents() method. 
function QuickSelectBar.BindProgressBar(IProgress)
	if(QuickSelectBar.IProgress) then
		QuickSelectBar.IProgress:GetEvents():RemoveEventListener("OnChange", QuickSelectBar.OnProgressChanged, QuickSelectBar);
	end
	QuickSelectBar.IProgress = IProgress;
	if(IProgress) then
		if(page) then
			page:FindControl("progress_wnd").visible = true;
		end
		QuickSelectBar.IProgress:GetEvents():AddEventListener("OnChange", QuickSelectBar.OnProgressChanged, QuickSelectBar, "QuickSelectBar");
		QuickSelectBar:OnProgressChanged();
	else
		if(page) then
			page:FindControl("progress_wnd").visible = false;
		end
	end
end

function QuickSelectBar:OnProgressChanged()
	local IProgress = QuickSelectBar.IProgress;
	if(IProgress and page) then
		self.maxExp = IProgress:GetMaxValue();
		self.curExp = IProgress:GetValue();
		QuickSelectBar.UpdateExpUI();
	end
end

function QuickSelectBar.OnClickAccelerateProgress()
	if(QuickSelectBar.IProgress) then
		QuickSelectBar.IProgress:GetEvents():DispatchEvent({type = "OnClickAccelerateProgress" , });
	end
end

function QuickSelectBar.UpdateExpUI()
	local self = QuickSelectBar;
	local cur_value = self.curExp;
	local max_value = self.maxExp;
	cur_value = math.min(cur_value,max_value);
	local _bar = ParaUI.GetUIObject("mc_exp_bar");
	if(_bar:IsValid() == true) then
		local width = self.progress_bar_width;
		width = math.ceil( (cur_value / max_value) * width );
		width = math.max(8,width);
		_bar.width = width;
		_bar.tooltip = format("%d/%d", cur_value, max_value);
	end	
end

function QuickSelectBar.GetExpUICursorPos()
	local self = QuickSelectBar;
	local _bar = ParaUI.GetUIObject("mc_exp_bar");
	if(_bar:IsValid() == true) then
		local width = self.progress_bar_width;
		local cur_value = self.curExp;
		local max_value = self.maxExp;
		width = math.ceil( (cur_value / max_value) * width );
		width = math.max(8,width);
		local x, y  = _bar:GetAbsPosition();
		return x + width, y;
	end	
end

QuickSelectBar.InventoryPageBeShow = false;

function QuickSelectBar.SwitchInventoryPage()
	QuickSelectBar.InventoryPageBeShow = not QuickSelectBar.InventoryPageBeShow;
	QuickSelectBar.ShowInventoryPage(QuickSelectBar.InventoryPageBeShow);
end

function QuickSelectBar.ShowInventoryPage(beShow)
	if(GameLogic.GameMode:IsUseCreatorBag()) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/BuilderFramePage.lua");
		local BuilderFramePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.BuilderFramePage");
		BuilderFramePage.ShowMobilePage(beShow);
	else
		NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/InventoryPage.lua");
		local InventoryPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.InventoryPage");
		InventoryPage.ShowPage(beShow);
	end
    NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/TouchController.lua");
    local TouchController = commonlib.gettable("MyCompany.Aries.Game.GUI.TouchController");
    TouchController.ShowPage(not beShow);
	NPL.load("(gl)script/mobile/paracraft/Areas/SystemMenuPage.lua");
	local SystemMenuPage = commonlib.gettable("ParaCraft.Mobile.Desktop.SystemMenuPage");
	SystemMenuPage.ShowPage(not beShow);
end

function QuickSelectBar.OnTouchItem(mcmlNode, touch)
	if(not QuickSelectBar.touch_button_item) then
		QuickSelectBar.touch_button_item = TouchButton:new({
			OnTouchClick = function(self)
				-- tap to click on the node. 
				local mcmlNode = self.mcmlNode;
				GameLogic.GetPlayerController():SetHandToolIndex(mcmlNode.slot.slotIndex);
				-- try pick selection if any
				NPL.load("(gl)script/apps/Aries/Creator/Game/Tools/TouchSelection.lua");
				local TouchSelection = commonlib.gettable("MyCompany.Aries.Game.Tools.TouchSelection");
				TouchSelection:TryPickSelection();
			end,
			OnTouchUp = function(self)
				local mcmlNode = self.mcmlNode;
				local dx, dy = self:GetOffsetFromStartLocation();
				if(dy < -40) then
					-- guesture: slide upward to delete the item in slot
					if(mcmlNode.destInventory and mcmlNode.contView) then
						mcmlNode.contView:ShiftClickSlot(mcmlNode.slot_index, nil, mcmlNode.destInventory);
					elseif(mcmlNode.slot) then
						-- shift click to remove all.
						mcmlNode.slot:RemoveItem(nil);
					end
				end
			end,
		})
	end
	QuickSelectBar.touch_button_item.mcmlNode = mcmlNode;
	QuickSelectBar.touch_button_item:OnTouchEvent(touch);
end

-- user clicks the inventory button. 
function QuickSelectBar.OnClickInventory()
	GameLogic.ToggleDesktop("builder");
end