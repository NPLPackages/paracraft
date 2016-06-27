--[[
Title: beautify command text
Author(s): LiXizhi
Date: 2016/2/19
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Text/beautify.lua");
local beautify = commonlib.gettable("MyCompany.Aries.Game.Common.Text.beautify");
text = beautify:beautify_cmd("	hello world");
echo(text);
-------------------------------------------------------
]]
local beautify = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Common.Text.beautify"));

local syntax_map_cmd = {
	{"<", [[&lt;]]},
	{">", [[&gt;]]},
	{"\"", [[&quot;]]},
	{"'", [[&apos;]]},
	{"^(%s*)(/*function.*)$", [[%1&fts;%2&fte;]]},
	{"^(%s*)(/*%w+)(.*)$", [[%1&fts;%2&fte;%3]]},
	{"(%s+)(/%w+)(.*)$", [[%1&fts;%2&fte;%3]]},
	{"\t", [[&nbsp;&nbsp;&nbsp;]]},
	{"^ ", [[&nbsp;]]},
	{" ", [[&#32;]]},
	{"&fts;", [[<span style="color:#0000CC">]]},
	{"&fte;", [[</span>]]},
	{"(%-%-.*)$", [[<span style="color:#00AA00">%1</span>]]},
}

-- beautify text to html 
-- @param text: 
function beautify:beautify_cmd(text)
	if(not text or text == "") then
		return text;
	end
	for i,v in ipairs(syntax_map_cmd) do
		text = string.gsub(text, v[1], v[2]);
	end
	return text;
end

