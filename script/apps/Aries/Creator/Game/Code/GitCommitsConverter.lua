--[[
Title: GitCommitsConverter
Author(s): leio
Date: 2019/12/12
Desc: this is a log converter for translating git commits to markdown format 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/GitCommitsConverter.lua");
local GitCommitsConverter = commonlib.gettable("MyCompany.Aries.Game.Code.GitCommitsConverter");
local c = GitCommitsConverter:new();
c:Export("test/nplcad.txt","test/nplcad.md")
-------------------------------------------------------
]]

local GitCommitsConverter = commonlib.inherit(nil,commonlib.gettable("MyCompany.Aries.Game.Code.GitCommitsConverter"));

function GitCommitsConverter:ctor()
end

function GitCommitsConverter:Export(input_filename,output_filename)
    if(not input_filename)then
        return
    end

    local content = self:ReadFileContent(input_filename) or "";
    local begin_commit_token = false;
    local token;
    local result = {};
    for line in string.gfind(content,"[^\r\n]+") do
        local commit_id = string.match(line,"commit%s-(%w+)%c-");
        if(commit_id and (#commit_id) == 40)then
            token = {
                commit_id = commit_id,
                content = "";
            }
            table.insert(result,token);
        end
        if(token and token.commit_id)then
            if(string.match(line,"Author:%s-(.+)%c-"))then
                token.author = string.match(line,"Author:%s-(.+)%c-");
            elseif(string.match(line,"Date:%s-(.+)%c-"))then
                token.date = string.match(line,"Date:%s-(.+)%c-");
            else
                if(not commit_id)then
                    token.content = token.content .. line;
                end
            end
        end
    end
    self:WriteMD(output_filename,result);
end
function GitCommitsConverter:ReadFileContent(filename)
    local file = ParaIO.open(filename,"r");
    if(file:IsValid()) then
        local txt = file:GetText();
        file:close();
        return txt;
    end
end
-- change date to simple format
-- "Wed Jul 13 17:09:48 2016 +0800" -> 2016-7-13
function GitCommitsConverter:GetSimpleDate(date)
    local week,month,day,time,year,zone = string.match(date,"%s-(.+)%s+(.+)%s+(.+)%s+(.+)%s+(.+)%s+(.+)%s-");
    if(year and month and day)then
        month = self:GetMontyNumber(month);
        return string.format("%s-%s-%s",year,tostring(month),day);
    else 
        return date;
    end
end
function GitCommitsConverter:WriteMD(filename,result)
    if(not result)then
        return
    end
    local file = ParaIO.open(filename,"w");
    local s = "";
    for k,v in ipairs(result) do
        local date = v.date;
        date = self:GetSimpleDate(date)
        local content = v.content;
        if(s == "")then
            s = string.format("#### %s\r\n%s",date,content);
        else
            s = string.format("%s\n#### %s\r\n%s",s, date,content);
        end
    end

    if(file:IsValid()) then
		file:WriteString(s);
		file:close();
	end
    
end
function GitCommitsConverter:GetMontyNumber(m)
    m = string.lower(m)
    local list = {
        ["january"] = 1,
        ["february"] = 2,
        ["march"] = 3,
        ["april"] = 4,
        ["may"] = 5,
        ["june"] = 6,
        ["july"] = 7,
        ["august"] = 8,
        ["september"] = 9,
        ["october"] = 10,
        ["november"] = 11,
        ["december"] = 12,
    }
    for k,v in pairs(list) do
        if(string.find(k,m))then
            return v;
        end
    end
end