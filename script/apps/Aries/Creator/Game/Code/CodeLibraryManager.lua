--[[
Title: Code Library Manager
Author(s): LiXizhi
Date: 2022/5/2
Desc: manage code library. 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeLibraryManager.lua");
local CodeLibraryManager = commonlib.gettable("MyCompany.Aries.Game.Code.CodeLibraryManager");
local library = GameLogic.GetCodeGlobal():GetLibraryManager():CreateGetCodeLibrary("war")
library:AddReference(codeblock)
library:Start()
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeLibrary.lua");
local CodeLibrary = commonlib.gettable("MyCompany.Aries.Game.Code.CodeLibrary");

local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local CodeLibraryManager = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Code.CodeLibraryManager"));

function CodeLibraryManager:ctor()
	self.libraries = {};
end

function CodeLibraryManager:GetCodeLibrary(libName)
	return self.libraries[libName];
end

function CodeLibraryManager:CreateGetCodeLibrary(libName)
	local library = self:GetCodeLibrary(libName)
	if(not library) then
		library = CodeLibrary:new():Init(libName)
		if(not library:IsEmpty()) then
			self.libraries[libName] = library
		end
	end
	return library;
end
