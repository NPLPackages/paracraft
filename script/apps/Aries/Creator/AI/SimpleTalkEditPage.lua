--[[
Title: SimpleTalkEditPage.html code-behind script
Author(s): LiXizhi
Date: 2010/2/7
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/AI/SimpleTalkEditPage.lua");
local args = {
	text =  {
		"aaaaaaaaaaaaaaaaaaa",
		"aaaaaaaaaaaaaaaaaaa",
		"aaaaaaaaaaaaaaaaaaa",
		"aaaaaaaaaaaaaaaaaaa",
		"aaaaaaaaaaaaaaaaaaa",
	}
}
MyCompany.Aries.Creator.AI.SimpleTalkEditPage.ShowPage(args);
-------------------------------------------------------
]]
local SimpleTalkEditPage = commonlib.gettable("MyCompany.Aries.Creator.AI.SimpleTalkEditPage")

local page;

function SimpleTalkEditPage.OnInit()
	page = document:GetPageCtrl();	
end

function SimpleTalkEditPage.ClosePage()
	page:CloseWindow();
end
--args = { text = { "aaaaaa", "bbbbbbb"}, }
function SimpleTalkEditPage.ShowPage(args)
	System.App.Commands.Call("File.MCMLWindowFrame", {
			url = "script/apps/Aries/Creator/AI/SimpleTalkEditPage.html", 
			name = "SimpleTalkEditPage.ShowPage", 
			app_key=MyCompany.Aries.app.app_key, 
			isShowTitleBar = false,
			DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
			style = CommonCtrl.WindowFrame.ContainerStyle,
			zorder = 3,
			isTopLevel = true,
			allowDrag = false,
			directPosition = true,
				align = "_ct",
				x = -260,
				y = -170,
				width = 520,
				height = 370,
		});
	if(page and args and args.text)then
		local k,v;
		for k,v in ipairs(args.text) do
			page:SetValue("txt_"..k,v);
		end
		SimpleTalkEditPage.ai_data = args.text;
	end
end
function SimpleTalkEditPage.OnCopy(sName)
	commonlib.echo(sName);
	if(not sName)then return end
	local __,__,_,index = string.find(sName,"(.+)_(.+)");
	local txt_name = "txt_"..(index or "");
	local r = page:GetValue(txt_name)
	ParaMisc.CopyTextToClipboard(r);
end
function SimpleTalkEditPage.OnPaste(sName)
	commonlib.echo(sName);
	if(not sName)then return end
	local __,__,_,index = string.find(sName,"(.+)_(.+)");
	local txt_name = "txt_"..(index or "");
	
	local v = ParaMisc.GetTextFromClipboard() or "";
	page:SetValue(txt_name,v)
end
function SimpleTalkEditPage.OnSave()
	if(not page or not SimpleTalkEditPage.ai_data)then return end
	local k;
	for k = 1,5 do
		local txt = page:GetValue("txt_"..tostring(k));
		if(txt)then
			txt = string.gsub(txt,"%s","");
			local name_len = ParaMisc.GetUnicodeCharNum(txt);
			if(name_len > 50)then
				local s = string.format("<div style='margin-left:15px;margin-top:35px;text-align:center'>第%d行文字超过50个了，请重新输入吧。</div>",k);
				_guihelper.MessageBox(s);
				return
			end
		
			SimpleTalkEditPage.ai_data[k] = txt;
		end
	end
	SimpleTalkEditPage.ClosePage();
end