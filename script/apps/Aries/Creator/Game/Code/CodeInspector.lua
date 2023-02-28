--[[
Title: Code inspector
Author(s): LiXizhi
Date: 2022/4/18
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeInspector.lua");
local CodeInspector = commonlib.gettable("MyCompany.Aries.Game.Code.CodeInspector");
echo(CodeInspector:GetFunctionDefinition(echo))
-------------------------------------------------------
]]

local CodeInspector = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Code.CodeInspector"));

function CodeInspector:ctor()
end

-- static function£º slow to call, only call when needed. 
-- @param func: any function to inspect
-- @return {params = {paramName1, paramName2, ...}, comment = "--line1\n--line2", linedefined=number, source="src_filename"}
function CodeInspector:GetFunctionDefinition(func)
	if(type(func) == "table") then
		if(func.ctor) then
			func = func.ctor;
		elseif(func.OnInit) then
			func = func.OnInit;
		elseif(func.FrameMove) then
			func = func.FrameMove;
		elseif(func.OneTimeInit) then
			func = func.OneTimeInit;
		else
			return
		end
	end
	if(type(func) ~= "function") then
		return
	end

	local info = debug.getinfo(func, "S")
	if(info and info.source and info.linedefined) then
		local filename = info.source;
		if(not ParaIO.DoesFileExist(filename, true)) then
			local binFilename = filename:gsub("%.lua$", "%.o")
			if(binFilename ~= filename) then
				filename = "bin/"..binFilename;
				if(not ParaIO.DoesFileExist(filename, true)) then
					filename = nil;
				end
			else
				filename = nil;
			end
		end
		if(filename) then
			local file = ParaIO.open(filename, "r")
			if(file:IsValid()) then
				local text = file:GetText(0, -1)
				file:close();

				local lines = {};
				for line in text:gmatch("([^\r\n]*)\r?\n?") do
					lines[#lines + 1] = line;
				end
				if(info.linedefined <= #lines) then
					local linedefined = lines[info.linedefined]
					local params = {};
					local paramsText = linedefined:match("%(.*%)")
					if(paramsText) then
						for paramName in paramsText:gmatch("%w+") do
							params[#params+1] = paramName;
						end
					end
					local commentText;
					for i = info.linedefined-1, 1, -1 do
						local line = lines[i]
						local comment = line:match("%s*(%-%-.*)");
						if(comment) then
							if(commentText) then
								commentText = (comment.."\n")..commentText
							else
								commentText = comment;	
							end
						else
							break;
						end
					end
					return {params = params, comment = commentText, source = filename, linedefined = info.linedefined};
				end
			end
		end
	end
end