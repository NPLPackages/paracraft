--[[
Title: Translation gettext parser
Author(s): LiXizhi
Date: 2014/11/21
Desc: reading po and mo translation file. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/TranslationGettext.lua");
local TranslationGettext = commonlib.gettable("MyCompany.Aries.Game.Common.TranslationGettext")
echo(TranslationGettext.AddMoFile("config/Aries/creator/language/paracraft_enUS.mo", nil));
echo(TranslationGettext.AddPoFile("config/Aries/creator/language/paracraft_enUS.po", nil));
-------------------------------------------------------
]]
local TranslationGettext = commonlib.gettable("MyCompany.Aries.Game.Common.TranslationGettext")

function TranslationGettext.AddMoFile(filepath)
end

-- add all translations in a mo translation file to the current locale
-- mo file is the compiled version of po file. 
-- parsing code reference: http://lua-users.org/lists/lua-l/2010-04/msg00005.html
-- @param output: to which locale object to add the text entry
-- @return output
function TranslationGettext.AddMoFile(filepath, output)
	output = output or {};
	local file = ParaIO.open(filepath, "r");
	if(not file:IsValid()) then
		return output;
	end
	local mo_data = file:GetText(0, -1);
	file:close();

	--------------------------------
    -- precache some functions
    --------------------------------
    local byte=string.byte
    local sub=string.sub

    --------------------------------
    -- check format
    --------------------------------
    local peek_long --localize
    local magic=sub(mo_data,1,4)
    -- intel magic 0xde120495
    if magic=="\222\018\004\149" then
        peek_long=function(offs)
            local a,b,c,d=byte(mo_data,offs+1,offs+4)
            return ((d*256+c)*256+b)*256+a
        end
    -- motorola magic = 0x950412de
    elseif magic=="\149\004\018\222" then
        peek_long=function(offs)
            local a,b,c,d=byte(mo_data,offs+1,offs+4)
            return ((a*256+b)*256+c)*256+d
        end
    else
		LOG.std(nil, "warn", "TranslationGettext", "invalid mo translation file: %s", filepath);
        return output;
    end

    --------------------------------
    -- version
    --------------------------------
    local V=peek_long(4)
    if V~=0 then
		LOG.std(nil, "warn", "TranslationGettext", "supported version in mo translation file: %s ", filepath);
        return output;
    end

    ------------------------------
    -- get number of offsets of table
    ------------------------------
    local N,O,T=peek_long(8),peek_long(12),peek_long(16)
    ------------------------------
    -- traverse and get strings
    ------------------------------
    for nstr=1,N do
        local ol,oo=peek_long(O),peek_long(O+4) O=O+8
        local tl,to=peek_long(T),peek_long(T+4) T=T+8
		if(ol>1 and tl>1) then
			output[sub(mo_data,oo+1,oo+ol)]=sub(mo_data,to+1,to+tl)
		end
    end
	LOG.std(nil, "info", "TranslationGettext", "load mo file %s with %d entries", filepath, N);
	return output;
end


-- add all translations in a po translation file to the current locale
-- @param output: to which locale object to add the text entry
-- @return output
function TranslationGettext.AddPoFile(filepath, output)
	output = output or {};
	local file = ParaIO.open(filepath, "r");
	if(file:IsValid()) then
		
		local LoadObjectFromString = NPL.LoadObjectFromString;
		local type = type;
		local count = 0;
		
		local msgid = "";
		local msgstr = nil;
		local line = file:readline();
		while(line) do
			if(line[1] ~= '#') then
				local msg_type, text = line:match("^msg(%S+)%s+(\".*\")$");
				if(msg_type == "id") then
					msgid = LoadObjectFromString(text);
				elseif(msg_type == "str") then
					msgstr = LoadObjectFromString(text);

					-- add entry: 
					if(msgid and msgid~="" and msgstr~="") then
						output[msgid] = msgstr;
						count = count + 1;
					end
				else
					-- TODO: support multiline text
				end
			end
			line = file:readline();
		end
		LOG.std(nil, "info", "TranslationGettext", "load po file %s with %d entries", filepath, count);
		file:close();
	else
		LOG.std(nil, "warn", "TranslationGettext", "language file %s can not be found", filepath);
	end
	return output;
end
