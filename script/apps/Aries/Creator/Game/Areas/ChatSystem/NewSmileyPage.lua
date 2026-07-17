--[[
Title: NewSmileyPage
Author(s): pbb
Date: 2024/11/3
Desc:  
Use Lib:
-------------------------------------------------------
	--表情包
	local NewSmileyPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/NewSmileyPage.lua");
	NewSmileyPage.ShowPage()
--]]

NPL.load("(gl)script/apps/Aries/BBSChat/ChatSystem/ChatChannel.lua");
local ChatChannel = commonlib.gettable("MyCompany.Aries.ChatSystem.ChatChannel");
NPL.load("(gl)script/apps/Aries/BBSChat/ChatSystem/ChatEdit.lua");
local ChatEdit = commonlib.gettable("MyCompany.Aries.ChatSystem.ChatEdit");
local SmileyConfig = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/SmileyConfig.lua");
local NewSmileyPage = NPL.export()

NewSmileyPage.smile_data = SmileyConfig.GetSmileyData()
NewSmileyPage.isFromChatPage = false;
function NewSmileyPage.DS_Func_Items(index)
	local self = NewSmileyPage;
	if(not self.smile_data)then return 0 end
	if(index == nil) then
		return #(self.smile_data);
	else
		return self.smile_data[index];
	end
end
function NewSmileyPage.OnInit()
	local self = NewSmileyPage;
	self.page = document:GetPageCtrl();
end

function NewSmileyPage.ClosePage()
	if(NewSmileyPage.page)then
		NewSmileyPage.page:CloseWindow();
		NewSmileyPage.page = nil;
	end
end

function NewSmileyPage.ShowPage(isFromChatPage)
    local self = NewSmileyPage;
	self.isFromChatPage = isFromChatPage;
	if self.page then
		self.ClosePage()
		return
	end
	if not self.isFromChatPage then
		self.last_caret = ChatEdit.GetCurCaretPosition();
	else
		local ChatChannelPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/ChatChannelPage.lua");
		self.last_caret = ChatChannelPage.GetCurCaretPosition();
	end

    local x,y,width, height = _guihelper.GetLastUIObjectPos();
	if(not x) then
		return
	end
	x = x+width/2-15;
	if(x<0) then
		x = 0;
	end

    local params = {
		url = "script/apps/Aries/Creator/Game/Areas/ChatSystem/NewSmileyPage.html", 
		name = "NewSmileyPage.ShowPage", 
		app_key=MyCompany.Aries.app.app_key, 
		isShowTitleBar = false,
		DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
		style = CommonCtrl.WindowFrame.ContainerStyle,
		zorder = 12,
		enable_esc_key = true,
		isTopLevel = false,
		allowDrag = false,
		directPosition = true,
			align = "_lt",
			x = x,
			y = y-200,
			width = 280,
			height = 192,
	};

	System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function NewSmileyPage.SendSmiley(index)
	if(not index)then return end
	local self = NewSmileyPage;
	local node = self.smile_data[index] or {};
    local index = node.idx
    if(not index)then return end
    local symbol = "#"..index.."#"
	if not self.isFromChatPage then
		ChatEdit.InsertSymbol(symbol,self.last_caret);
	else
		local ChatChannelPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/ChatChannelPage.lua");
		ChatChannelPage.InsertSymbol(symbol,self.last_caret);
	end
	--直接发送
	--ChatChannel.SendMessage( ChatChannel.EnumChannels.NearBy, nil, nil, symbol );
end

function NewSmileyPage.DoClick(index)
	NewSmileyPage.SendSmiley(index)
	if(NewSmileyPage.page)then
		NewSmileyPage.page:CloseWindow();
	end
end

function NewSmileyPage.HasSymbol(s)
	if(not s)then return end
	local isHaveSymbol,_ = SmileyConfig.FindSmileyCode(s)
	return isHaveSymbol
end

function NewSmileyPage.ShowAnimatePage()
	local self = NewSmileyPage;
	self.isFromChatPage = nil;
	if self.page then
		self.ClosePage()
		return
	end
	if not NewSmileyPage.animations then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/PlayerAssetFile.lua");
		local PlayerAssetFile = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerAssetFile")
		NewSmileyPage.animations = PlayerAssetFile:GetAllAnimations()
	end
	local x,y,width, height = _guihelper.GetLastUIObjectPos();
	if(not x) then
		return
	end
	x = x+width/2-15;
	if(x<0) then
		x = 0;
	end

    local params = {
		url = "script/apps/Aries/Creator/Game/Areas/ChatSystem/NewAnimatePage.html", 
		name = "NewAnimatePage.ShowPage", 
		app_key=MyCompany.Aries.app.app_key, 
		isShowTitleBar = false,
		DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
		style = CommonCtrl.WindowFrame.ContainerStyle,
		zorder = 12,
		enable_esc_key = true,
		isTopLevel = false,
		allowDrag = false,
		directPosition = true,
			align = "_lt",
			x = x,
			y = y-200,
			width = 280,
			height = 192,
	};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function NewSmileyPage.DS_Func_Anims(index)
	if index == nil then
		return #NewSmileyPage.animations
	else
		return NewSmileyPage.animations[index]
	end
end

function NewSmileyPage.OnClickAnim(index)
	if not NewSmileyPage.animations or index == nil then
		return
	end
	local anim = NewSmileyPage.animations[index]
	if not anim then
		return
	end
	local animId = anim.id or ""
	GameLogic.RunCommand(string.format("/anim %s", animId))
end