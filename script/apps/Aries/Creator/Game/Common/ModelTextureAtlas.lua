--[[
Title: Model Texture Atlas
Author(s): LiXizhi
Date: 2021/9/27
Desc: This atlas files will be cleared when world in unloaded. 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/ModelTextureAtlas.lua");
local ModelTextureAtlas = commonlib.gettable("MyCompany.Aries.Game.Common.ModelTextureAtlas");
local filename = ModelTextureAtlas:CreateGetModel("blocktemplates/test.bmax")
ModelTextureAtlas:Refresh(filename)
-------------------------------------------------------
]]
local ModelTextureAtlas = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Common.ModelTextureAtlas"))

function ModelTextureAtlas:ctor()
	NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/TextureAtlas.lua");
	local TextureAtlas = commonlib.gettable("MyCompany.Aries.Game.blocks.TextureAtlas")
	self.modelTextureAtlas = TextureAtlas:new():init("model_texture_atlas", 512, 512, 64);
	LOG.std(nil, "info", "ModelTextureAtlas", "initialized");
	GameLogic:Connect("WorldUnloaded", ModelTextureAtlas, ModelTextureAtlas.Clear, "UniqueConnection");
end

function ModelTextureAtlas:Clear()
	self.modelTextureAtlas:Clear();
end

-- create get model texture path. this will increase the tick by 1. 
-- @param filename: can be relative to world or root directory's bmax or x file. 
-- @param skin: can be nil, or custom character string, like used in a movie block skin.  
-- @return texture file path for the given model filename
function ModelTextureAtlas:CreateGetModel(filename, skin)
	if(filename) then
		local region, isNewlyCreated = self.modelTextureAtlas:AddModel(filename, skin)
		if(region) then
			region:Touch()
			if(isNewlyCreated) then
				-- when a new one is created, we will remove untouched
				self.modelTextureAtlas:RemoveUnTouched();
			end
			return region:GetTexturePath()
		end
	end
end

function ModelTextureAtlas:RemoveModel(filename, skin)
	self.modelTextureAtlas:RemoveModel(filename, skin)
end

--@param filename: if nil, we will refresh all, or we will only refresh the given filename
-- @param skin: can be nil, or custom character string, like used in a movie block skin.  
function ModelTextureAtlas:Refresh(filename, skin)
	local region = self.modelTextureAtlas:GetModelRegion(filename, skin)
	if(region) then
		return region:MakeDirty()
	end
end

ModelTextureAtlas:InitSingleton();

