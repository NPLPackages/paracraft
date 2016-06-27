--[[
Title: rebranding or white label
Author(s): LiXizhi
Date: 2015/12/9
Desc: It will read rebranding.txt in current directory to get name, value pairs
which may change the branding of the game. 
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/Rebranding.lua");
local Rebranding = commonlib.gettable("MyCompany.Aries.Creator.Game.Rebranding");
Rebranding:GetValue("company")
-------------------------------------------------------
]]
local Rebranding = commonlib.gettable("MyCompany.Aries.Creator.Game.Rebranding");

function Rebranding:Init()
	if(not self.isInited) then
		self.isInited = true;
		self:Load();
	end
end

-- @param filename: if nil default to "rebranding.txt"
function Rebranding:Load(filename)
	filename = filename or "rebranding.txt";
	local file = ParaIO.open(filename, "r")
	if(file:IsValid()) then
		LOG.std(nil, "info", "Rebranding", "loaded from file %s", filename);
		local line = file:readline();
		while(line) do
			-- extract all non-English text in quatations
			local name, value = line:match("([%w_]+)%s*=%s*(.+)\r?\n?$");
			if(name) then
				self[name] = value;
				-- echo({name, value})
			end
			line = file:readline();
		end
		file:close();
	end
end

function Rebranding:GetValue(name)
	self:Init();
	return self[name];
end