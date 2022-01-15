--[[
Title: Folder Manager for entities
Author(s): LiXizhi
Date: 2022/1/15
Desc: we can group entities in folders. One entity can be linked to multiple folders
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/FolderManager.lua");
local FolderManager = commonlib.gettable("MyCompany.Aries.Game.GameLogic.FolderManager")
FolderManager:AddEntityToFolder(entity, foldername)
FolderManager:Clear()
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityLiveModel.lua");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local FolderManager = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.GameLogic.FolderManager"));
FolderManager.class_name = "FolderManager";

function FolderManager:ctor()
	self.folders = {};
end

function FolderManager:Clear()
	self.folders = {};
end

function FolderManager:GetFolder(foldername)
	return self.folders[foldername];
end

function FolderManager:CreateGetFolder(foldername)
	local folder = self:GetFolder(foldername)
	if(not folder) then
		folder = commonlib.UnorderedArraySet:new();
		self.folders[foldername] = folder;
	end
	return folder
end

-- @param foldername: such as "name1/name2"
function FolderManager:AddEntityToFolder(entity, foldername)
	if(entity and foldername) then
		local folder = self:CreateGetFolder(foldername)
		if(folder and not folder:contains(entity)) then
			entity:Connect("beforeDestroyed", function()
				folder:removeByValue(entity);
			end);
			folder:add(entity)
			return true;
		end
	end
end

FolderManager:InitSingleton();