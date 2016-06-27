--[[
Title: The editbox for chatwindow
Author(s): zrf, refactored by LiXizhi
Date: 2011/3/14
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/ChatEdit.lua");
local ChatEdit = commonlib.gettable("MyCompany.Aries.ChatSystem.ChatEdit");
ChatEdit.ShowPage();
-------------------------------------------------------
]]
if(not System.options.mc) then
	NPL.load("(gl)script/apps/Aries/BBSChat/ChatSystem/ChatEdit.lua");
	return
end

NPL.load("(gl)script/apps/Aries/BBSChat/ChatSystem/ChatChannel.lua");
NPL.load("(gl)script/apps/Aries/BBSChat/SentenceHistory.lua");
NPL.load("(gl)script/apps/Aries/SlashCommand/SlashCommand.lua");
NPL.load("(gl)script/apps/Aries/BBSChat/ChatSystem/SmileyPage.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/CommandHelpPage.lua");
local CommandHelpPage = commonlib.gettable("MyCompany.Aries.ChatSystem.CommandHelpPage");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local SmileyPage = commonlib.gettable("MyCompany.Aries.ChatSystem.SmileyPage");
local SlashCommand = commonlib.gettable("MyCompany.Aries.SlashCommand.SlashCommand");
local ChatWindow = commonlib.gettable("MyCompany.Aries.ChatSystem.ChatWindow");
local sentence_history = commonlib.gettable("MyCompany.Aries.BBSChat.sentence_history");
local ChatChannel = commonlib.gettable("MyCompany.Aries.ChatSystem.ChatChannel");
local ChatEdit = commonlib.gettable("MyCompany.Aries.ChatSystem.ChatEdit");


ChatEdit.selected_channel = ChatEdit.selected_channel or 1;

local bg_timer;

-- show the page
-- e.g. ChatEdit.ShowPage(true, "_lb", 0, -147, 450, 30)
function ChatEdit.ShowPage(bForceRefreshPage, alignment, left, top, width, height)
	if(bForceRefreshPage or not ChatEdit.page) then
		ChatEdit.page = Map3DSystem.mcml.PageCtrl:new({
			url="script/apps/Aries/Creator/Game/Areas/ChatSystem/ChatEdit.html", 
			click_through=true});
	end

	if(bForceRefreshPage) then
		ParaUI.Destroy("ChatEditPage");
	end
	
	if(not ChatEdit.redirect_UI_name) then
		local _parent = ParaUI.GetUIObject("ChatEditPage");
		if(not _parent or not _parent:IsValid()) then
			_parent = ParaUI.CreateUIObject("container", "ChatEditPage", alignment or ChatWindow.DefaultUIPos.EditWnd.alignment, left or ChatWindow.DefaultUIPos.EditWnd.left, top or ChatWindow.DefaultUIPos.EditWnd.top, width or ChatWindow.DefaultUIPos.EditWnd.width, height or ChatWindow.DefaultUIPos.EditWnd.height);
			_parent.background = "";
			_parent.visible=false;
			_parent.zorder = -3;
			local _parentwnd = ChatWindow.CreateGetParentWnd();
			if(_parentwnd) then
				_parentwnd:AddChild(_parent);
			else
				_parent:AttachToRoot();
			end
			_parent:GetAttributeObject():SetField("ClickThrough", true);
			ChatEdit.page:Create("ChatEdit.page", _parent, "_fi", 0, 0, 0, 0);

			if(bForceRefreshPage) then
				ChatEdit.page:Refresh(0.01);
			end
			ChatEdit.OnClickChannel(ChatEdit.selected_channel, L"附近");

			ChatEdit.is_fade_out = nil;
		end
		_parent.visible = true;
	end

	ChatEdit.EnableTimer(true);
	ChatEdit.is_shown = true;
end

function ChatEdit.Init()
	ChatEdit.page = document:GetPageCtrl();
end

-- this function is only used in kids version
-- where the ChatEdit function is redirected to another persistent UI at the bottom of the screen. 
-- when UI is redirected. the ChatEdit.Show() function does not take any effect. 
-- @param sUIName: if nil it means the the default UI, otherwise it is the name of the external editbox UI. 
function ChatEdit.RedirectUITarget(sUIName)
	ChatEdit.redirect_UI_name = sUIName;
	if(sUIName) then
		ChatEdit.Hide()
	else
		if(ChatEdit.is_shown) then
			ChatEdit.ShowPage();
		else
			ChatEdit.Hide();
		end
	end
end


-- get the editbox input control, so that we can get/set text or alter text color
function ChatEdit.GetInputControl()
	if(ChatEdit.redirect_UI_name) then
		-- redirected ui control
		return ParaUI.GetUIObject(ChatEdit.redirect_UI_name);
	else
		-- default ui control in mcml page
		if(ChatEdit.page) then
			if(System.options.IsMobilePlatform) then
				return ChatEdit.page:FindUIControl("chatedit_words_mobile");
			else
				return ChatEdit.page:FindUIControl("chatedit_words");
			end
			--return ChatEdit.page:FindUIControl("chatedit_words");
		end
	end
end
function ChatEdit.GetCurCaretPosition()
	if(ChatEdit.is_shown) then
		local _editbox = ChatEdit.GetInputControl();
		if(_editbox) then
			local pos = _editbox:GetCaretPosition();
			return pos;
		end
	end
end
--在字符串的第几个位置后插入新的字符串
--返回 str,index(重新计算后插入的位置)
function ChatEdit.InsertStringAt(s,emot_str,index)
	if(not s or not emot_str)then return end
	index = index or 0;
	local len = ParaMisc.GetUnicodeCharNum(s);
	index = math.max(index,0);
	index = math.min(index,len);
	local start_str = ParaMisc.UniSubString(s, 1, index) or "";
	local end_str = ParaMisc.UniSubString(s, index+1, -1) or "";
	local str = start_str..emot_str..end_str;
	return str,index;
end

function ChatEdit.SetText(text)
	if(text and ChatEdit.is_shown) then
		local _editbox = ChatEdit.GetInputControl();
		if(_editbox) then
			_editbox.text = text;
	        _editbox:Focus();
			_editbox:SetCaretPosition(-1);
		end
	end
end

function ChatEdit.GetText()
	local _editbox = ChatEdit.GetInputControl();
	if(_editbox) then
		return _editbox.text;
	end
end

local replace_map;

--插入一个表情符号,类似:$1 $5
-- @param symbol: text like $gsid
-- @param caret_pos: if nil, it is last
-- @param replace_text: we will show this text instead of s. must be unique. 
function ChatEdit.InsertSymbol(s,caret_pos, replace_text)
	if(not s)then return end
	local len = ParaMisc.GetUnicodeCharNum(s);
	if(ChatEdit.is_shown) then
		local _editbox = ChatEdit.GetInputControl();
		if(_editbox) then
			if(replace_text) then
				replace_map = replace_map or {};
				replace_map[replace_text] = s;
			end

			local text = _editbox.text or "";
			if(not caret_pos)then
				caret_pos = ParaMisc.GetUnicodeCharNum(text);
			end
			text,caret_pos = ChatEdit.InsertStringAt(text, replace_text or s,caret_pos)
			_editbox.text = text or "";
	        _editbox:Focus();
			caret_pos = caret_pos + len;
			_editbox:SetCaretPosition(caret_pos);
		end
	end
end

function ChatEdit.Hide()
	local _parent = ParaUI.GetUIObject("ChatEditPage");
	if(_parent and _parent:IsValid()) then
		_parent.visible = false;
		ChatEdit.is_fade_out = true;
	end
	ChatEdit.is_shown = false;
end

-- timer is enabled whenever chat edit window is shown
function ChatEdit.EnableTimer(bEnabled)
	--if(System.options.version == "teen") then
		if(not bg_timer) then
			bg_timer = commonlib.Timer:new({callbackFunc = ChatEdit.OnTimer})
		end
		if(bEnabled) then
			bg_timer:Change(200, 200);
		else
			bg_timer:Change(200, nil);
		end
	--end
end


-- this is a slow timer to highlight the chat area 
-- if the mouse cursor is within the chat area, we will highlight the background. 
-- otherwise we will not show the display background.
function ChatEdit.OnTimer(timer)
	if(ChatWindow.is_shown) then
		if(ChatEdit.HasFocus()) then
			--ChatEdit.FadeIn();
			--ChatWindow.FadeIn();
		else
			--ChatEdit.FadeOut(0.2);
			ChatWindow.FadeOut(0.2);
		end
	end		
end

function ChatEdit.SetComboSelect(select)
	select=tostring(select);
	ChatEdit.page:SetValue("channelselect2",select);
end

function ChatEdit.LostFocus()
	local _editbox = ChatEdit.GetInputControl();
	if(_editbox) then
		_editbox:LostFocus();
	end
	local vscrollbar = ParaUI.GetUIObject("ChatWindow_CreateTreeView_VScrollBar");
	if(vscrollbar:IsValid())then
		vscrollbar.visible = false;
	end
	CommandHelpPage.ClosePage();
	ChatWindow.HideAll();
end

-- send text without writing to history. 
-- @param words: text string
-- @param channel: if nil, it is the current channel.
function ChatEdit.SendTextSilent(words, channel)
	if(ChatChannel.SendMessage( channel or ChatEdit.selected_channel, nil, nil, words )) then
		return true;
	end
end

function ChatEdit.OnClickSend(name)
	local words = "";
	local _editbox = ChatEdit.GetInputControl();
	if(_editbox) then
		if(not name or name == "send") then
			words = _editbox.text;
		elseif(name == "cancel") then
			words = "";
		end
	end

	if(words == "")then
		ChatEdit.LostFocus();
		if(System.options.IsMobilePlatform) then
			MyCompany.Aries.Creator.Game.Desktop.ShowMobileDesktop(true);
		end
		return;
	end

	if(_editbox) then
		if((#words) > 120) then
			_guihelper.MessageBox(L"你输入的文字太多了");
			return;
		end
		-- internally it will run all GM commands. 
		local original_msg = words;

		local bSendMessage = true;
		if (words:match("^/")) then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandManager.lua");
			local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");
			words, bSendMessage = CommandManager:RunFromConsole(words);
			if(type(words) ~= "string") then
				words = "";
			end
			CommandHelpPage.ClosePage();	
		else
			local player = EntityManager.GetPlayer();
			if(player:SendChatMsg(words)) then
				bSendMessage = false; 
			end
		end

		if(replace_map) then
			local name, value;
			for name, value in pairs(replace_map) do
				name = name:gsub("([%(%)%[%]%%%^%+%-%.%*%?])", "%%%1");
				words = words:gsub(name, value);
			end
			replace_map = nil;
		end

		if(not System.options.mc) then
			words = SmileyPage.RemoveNotOwnedGsid(words);
		end

		if(bSendMessage) then	
			if(words == sentence_history:PeekLastSentence()) then
				--_editbox.text = "不能连续发送相同内容";
				_guihelper.MessageBox(L"不能连续发送相同内容");
			elseif(ChatChannel.SendMessage( ChatEdit.selected_channel, nil, nil, words )) then
				ChatEdit.ResetDefaultChannelText(true);
				sentence_history:PushSentence(words);
				ChatEdit.LostFocus();
				if(System.options.IsMobilePlatform) then
					MyCompany.Aries.Creator.Game.Desktop.ShowMobileDesktop(true);
				end
			end
		else
			ChatEdit.ResetDefaultChannelText(true);
			sentence_history:PushSentence(original_msg);
			ChatEdit.LostFocus();
			if(System.options.IsMobilePlatform) then
				MyCompany.Aries.Creator.Game.Desktop.ShowMobileDesktop(true);
			end
		end
	end
end

function ChatEdit.FadeIn(animSeconds)
	if(ChatEdit.is_fade_out) then
		ChatEdit.is_fade_out = false;
		if(not ChatEdit.redirect_UI_name) then
			local _parent = ParaUI.GetUIObject("ChatEditPage");
			UIAnimManager.ChangeAlpha("Aries.ChatEditPage", _parent, 255, 256/(animSeconds or 0.5))
		end
	end
end

function ChatEdit.FadeOut(animSeconds)
	if(not ChatEdit.is_fade_out) then
		ChatEdit.is_fade_out = true;
		if(not ChatEdit.redirect_UI_name) then
			local _parent = ParaUI.GetUIObject("ChatEditPage");
			UIAnimManager.ChangeAlpha("Aries.ChatEditPage", _parent, if_else(System.options.version == "teen", 0, 0), 256/(animSeconds or 4))
		end
	end
end

-- whether the chat window is now having key focus. 
function ChatEdit.HasFocus()
	if(ChatWindow.is_shown and ChatEdit.page) then
		local _parent = ParaUI.GetUIObject("ChatLogPage");
		if(_parent.visible) then
			local x, y, width, height = _parent:GetAbsPosition();
			local mouseX, mouseY = ParaUI.GetMousePosition();
			if(x<=mouseX and mouseX <= (x+width) and y<=mouseY and mouseY<(y+height+32)) then
				return true;
			end
		end
	end
	if(ChatEdit.is_shown) then
		local _editbox = ChatEdit.GetInputControl();
		if(_editbox) then
			return _editbox.visible and _editbox:GetAttributeObject():GetField("HasKeyFocus", false);
		end
	end
end

-- set focus
function ChatEdit.SetFocus()
	local _editbox = ChatEdit.GetInputControl();
	if(_editbox) then
		_editbox:Focus();
	end
	local vscrollbar = ParaUI.GetUIObject("ChatWindow_CreateTreeView_VScrollBar");
	if(vscrollbar:IsValid())then
		vscrollbar.visible = true;
	end
	ChatEdit.FadeIn(0.2);
	ChatWindow.FadeIn(0.2);
	--ChatWindow.RefreshTreeView();
end

function ChatEdit.OnKeyUp(name, mcmlNode)
	local _editbox = ChatEdit.GetInputControl();
	if(_editbox and _editbox:IsValid()) then
		local sentText = _editbox.text;

		if(string.len(sentText) > 120) then
			_editbox.text = string.sub(sentText, 1, 120);
			_editbox:SetCaretPosition(-1);
		end
		
		local callbacks = {
			[Event_Mapping.EM_KEY_RETURN] = ChatEdit.OnClickSend,
			[Event_Mapping.EM_KEY_NUMPADENTER] = ChatEdit.OnClickSend,
			[Event_Mapping.EM_KEY_UP] = function ()
				local sentence = sentence_history:PreviousSentence()
				if(sentence) then
					_editbox.text = sentence;
					_editbox:SetCaretPosition(-1);
				end
			end,
			[Event_Mapping.EM_KEY_DOWN] = function ()
				local sentence = sentence_history:NextSentence()
				if(sentence) then
					_editbox.text = sentence;
					_editbox:SetCaretPosition(-1);
				end
			end,
		}
		local x,y = _editbox:GetAbsPosition();
		CommandHelpPage.HandlerKeyUp({x = x,y = y,rows = 10,offset_x = -5,offset_y = 9},virtual_key,callbacks,sentText);
		--CommandHelpPage.HandlerKeyUp(virtual_key,callbacks,sentText);


		--if(virtual_key == Event_Mapping.EM_KEY_RETURN or virtual_key == Event_Mapping.EM_KEY_NUMPADENTER) then
			--if(CommandHelpPage.page_be_show) then
				--CommandHelpPage.OnClickKEY_RETURN(ChatEdit.OnClickSend);
			--else
				--ChatEdit.OnClickSend();
			--end
			----ChatEdit.OnClickSend();
		--elseif(virtual_key == Event_Mapping.EM_KEY_UP) then
			--if(CommandHelpPage.page_be_show) then
				--CommandHelpPage.SelectLastCmd();
			--else
				--local sentence = sentence_history:PreviousSentence()
				--if(sentence) then
					--_editbox.text = sentence;
					--_editbox:SetCaretPosition(-1);
				--end
			--end	
		--elseif(virtual_key == Event_Mapping.EM_KEY_DOWN) then	
			--if(CommandHelpPage.page_be_show) then
				--CommandHelpPage.SelectNextCmd();
			--else
				--local sentence = sentence_history:NextSentence()
				--if(sentence) then
					--_editbox.text = sentence;
					--_editbox:SetCaretPosition(-1);
				--end
			--end	
		--else
			--CommandHelpPage.ShowCommandHelpInfo(sentText);	
		---- esc key is not trapped. 
		----elseif(virtual_key == Event_Mapping.EM_KEY_ESCAPE) then	
			----ChatWindow.OnClickWndMinimize();
		--end
	end
end

-- reset the edit box with the default channel text
-- @param bSetFocus: true to set focus
function ChatEdit.ResetDefaultChannelText(bSetFocus)
	local channel = ChatChannel.GetChannel(ChatEdit.selected_channel);
	if(channel) then
		local input = ChatEdit.GetInputControl();
		if(input)then
			input.text = channel.default_channel_text or "";
			if(bSetFocus)then
				input:Focus();
				input:SetCaretPosition(-1);
			end
		end
	end
end

-- set text and scroll to caret position at the end of the text
function ChatEdit.SetEditorText(text)
	local input = ChatEdit.GetInputControl()
	if(input) then
		input.text = tostring(text or "");
		input:SetCaretPosition(-1);
	end
end

function ChatEdit.OnClickChannel(name,channel_name)
	local channel_index = tonumber(name)
	local bIgnoreText = ChatEdit.selected_channel ~= ChatChannel.EnumChannels.Private and channel_index ~= ChatChannel.EnumChannels.Private;
	ChatEdit.SelectChannel(channel_index, bIgnoreText, channel_name)
end

-- @param bIgnoreText: if true, we will ignore default text
function ChatEdit.SelectChannel(index, bIgnoreText, channel_name)
	index = tonumber(index);
	ChatEdit.selected_channel = index;
	ChatEdit.page:SetValue("channelselect2", channel_name or ChatChannel.GetChannelName(index));

	local channel = ChatChannel.GetChannel(ChatEdit.selected_channel);
	if(channel) then
		local input = ChatEdit.GetInputControl();
		if(input)then
			_guihelper.SetFontColor(input, "#"..channel.color);
		end
	end
	if(not bIgnoreText) then
		ChatEdit.ResetDefaultChannelText(true);
	end
end

-- first esc key to clear text, second one to lost focus. 
function ChatEdit.handleEscKey()
	if(ChatEdit.HasFocus()) then
		local text = ChatEdit.GetText();
		if(text and #text>0 and text ~= "/") then
			if(text:match("^/")) then
				ChatEdit.SetText("/");
			else
				ChatEdit.SetText("");
			end
		else
			ChatEdit.LostFocus()
		end
	end
end