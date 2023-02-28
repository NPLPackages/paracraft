--[[
    --写日志到指定文件
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BuildReplay/FileLogUtil.lua");
    local FileLogUtil = commonlib.gettable("MyCompany.Aries.Game.Tasks.BuildReplay.FileLogUtil");

    local logUtil = FileLogUtil:new({filename = "log_video_queue.txt"})
    logUtil.output_video_log(nil,"info","VideoRenderQueue","debug info string...")
]]


local string_gsub = string.gsub;
local string_sub = string.sub;
local string_format = string.format;
local ParaGlobal_timeGetTime = ParaGlobal.timeGetTime

local nLastTime = 0;
local nLastDateTime = 0;
local date_str = ParaGlobal.GetDateFormat("yyyy-MM-dd");
local time_str = ParaGlobal.GetTimeFormat(nil);

local function GetLogTimeString()
	local nCurTime = ParaGlobal_timeGetTime();
	-- fixed time wrapping
	if((nCurTime - nLastTime) > 1000 or nCurTime < nLastTime) then
		nLastTime = nCurTime;
		if((nCurTime - nLastDateTime)>3600000 or nCurTime < nLastDateTime) then
			date_str = ParaGlobal.GetDateFormat("yyyy-MM-dd");
		end
		time_str = ParaGlobal.GetTimeFormat(nil);
	end
	return date_str, time_str, nCurTime
end

local FileLogUtil = commonlib.inherit(nil,commonlib.gettable("MyCompany.Aries.Game.Tasks.BuildReplay.FileLogUtil"))

function FileLogUtil:ctor()
    self:initWithFilename(self.filename)
end

function FileLogUtil:initWithFilename(filename)
    self.filename = filename or "log_video_queue.txt"
end

function FileLogUtil:_std_log_long(thread_or_word,level,module_name,str)
	local date_str, time_str, nCurTime = GetLogTimeString();
	
	str = string_format("%s %s %s|%s|%s|%s|", date_str, time_str, nCurTime, thread_or_word or npl_thread_name,level or "",module_name or "")..str.."\n"

    if self._logFileObj==nil then
        self._logFileObj = ParaIO.open(self.filename,"a+")
    else
        self._logFileObj = ParaIO.open(self.filename,"a+")
    end
    self._logFileObj:WriteString(str)
    self._logFileObj:close()
    print(str)
end

function FileLogUtil:output_video_log(thread_or_word,level,module_name,input, ...)
    if(type(input) == "string") then
        local args = {...};
        if(#args == 0) then
            self:_std_log_long(thread_or_word,level,module_name,input)
        else
            local ok, result = pcall(string_format, input, ...);
            if ok then
                self:_std_log_long(thread_or_word,level,module_name,string_format(input, ...));
            else
                self:_std_log_long(thread_or_word,level,module_name, string.format("<runtime error> in output_video_log. input:%q with %s \n reason:%s \n callstack:%s", input, commonlib.serialize_compact({...}), tostring(result), commonlib.debugstack(2)));
            end
        end	
    elseif(type(input) == "table") then	
        self:_std_log_long(thread_or_word,level,module_name,commonlib.serialize_compact(input));
    else
        self:_std_log_long(thread_or_word,level,module_name,tostring(input));
    end
end

function FileLogUtil:clear()
    if self.filename and ParaIO.DoesFileExist(self.filename) then
        ParaIO.DeleteFile(self.filename)
    end
end

return FileLogUtil