--[[
Title: Slope Based Block
Author(s): devilwalk@taomee
Date: 2016/6/28
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/BlockSlope.lua");
local block = commonlib.gettable("MyCompany.Aries.Game.blocks.BlockSlope")
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Direction.lua");
NPL.load("(gl)script/ide/math/bit.lua");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local band = mathlib.bit.band;

local block = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.block"), commonlib.gettable("MyCompany.Aries.Game.blocks.BlockSlope"));

-- register
block_types.RegisterBlockClass("BlockSlope", block);

function block:ctor()
	local models = {
		{id_data=0, assetfile="L", facing=0, },
		{id_data=7, assetfile="L", facing=1.57, },
		{id_data=1, assetfile="L", facing=3.14, },
		{id_data=6, assetfile="L", facing=4.71, },

		{id_data=9, assetfile="T", facing=0, },
		{id_data=12, assetfile="T", facing=4.71, },
		{id_data=8, assetfile="T", facing=3.14, },
		{id_data=13, assetfile="T", facing=1.57, },

		{id_data=4, assetfile="/", facing=0, },
		{id_data=3, assetfile="/", facing=4.71, },
		{id_data=5, assetfile="/", facing=3.14, },
		{id_data=2, assetfile="/", facing=1.57, },

		{id_data=14, assetfile="7", facing=0, },
		{id_data=11, assetfile="7", facing=4.71, },
		{id_data=15, assetfile="7", facing=3.14, },
		{id_data=10, assetfile="7", facing=1.57, },

		{id_data=100+0, assetfile="shape_1", facing=0, },
		{id_data=100+1, assetfile="shape_1", facing=1.57, },
		{id_data=100+2, assetfile="shape_1", facing=3.14, },
		{id_data=100+3, assetfile="shape_1", facing=4.71, },

		{id_data=100+4, assetfile="shape_2", facing=0, },
		{id_data=100+5, assetfile="shape_2", facing=4.71, },
		{id_data=100+6, assetfile="shape_2", facing=3.14, },
		{id_data=100+7, assetfile="shape_2", facing=1.57, },

		{id_data=100+8, assetfile="shape_3", facing=0, },
		{id_data=100+16, assetfile="shape_3", facing=4.71, },
		{id_data=100+14, assetfile="shape_3", facing=3.14, },
		{id_data=100+22, assetfile="shape_3", facing=1.57, },

		{id_data=100+9, assetfile="shape_4", facing=0, },
		{id_data=100+17, assetfile="shape_4", facing=4.71, },
		{id_data=100+15, assetfile="shape_4", facing=3.14, },
		{id_data=100+23, assetfile="shape_4", facing=1.57, },

		{id_data=100+10, assetfile="shape_5", facing=0, },
		{id_data=100+18, assetfile="shape_5", facing=4.71, },
		{id_data=100+12, assetfile="shape_5", facing=3.14, },
		{id_data=100+20, assetfile="shape_5", facing=1.57, },

		{id_data=100+11, assetfile="shape_6", facing=0, },
		{id_data=100+19, assetfile="shape_6", facing=4.71, },
		{id_data=100+13, assetfile="shape_6", facing=3.14, },
		{id_data=100+21, assetfile="shape_6", facing=1.57, },

		{id_data=124+0, assetfile="shape_7", facing=0, },
		{id_data=124+1, assetfile="shape_7", facing=1.57, },
		{id_data=124+2, assetfile="shape_7", facing=3.14, },
		{id_data=124+3, assetfile="shape_7", facing=4.71, },

		{id_data=124+4, assetfile="shape_8", facing=0, },
		{id_data=124+5, assetfile="shape_8", facing=1.57, },
		{id_data=124+6, assetfile="shape_8", facing=3.14, },
		{id_data=124+7, assetfile="shape_8", facing=4.71, },
	}
	models.id_model_map = {};
	for i, model in ipairs(models) do
		models.id_model_map[model.id_data] = model
	end
	-- only used by block rotation
	self.models2 = models;
end

function block:Init()
end

local lCubeIndex = 16;
local function _isMatch(blockIndex, blockX, blockY, blockZ)
	local block_pos_x = BlockEngine:GetBlock(blockX + 1, blockY, blockZ);
	local block_neg_x = BlockEngine:GetBlock(blockX-1, blockY, blockZ);
	local block_pos_y = BlockEngine:GetBlock(blockX, blockY + 1, blockZ);
	local block_neg_y = BlockEngine:GetBlock(blockX, blockY-1, blockZ);
	local block_pos_z = BlockEngine:GetBlock(blockX, blockY, blockZ + 1);
	local block_neg_z = BlockEngine:GetBlock(blockX, blockY, blockZ-1);
	local block_index_pos_x = nil;
	local block_index_neg_x = nil;
	local block_index_pos_y = nil;
	local block_index_neg_y = nil;
	local block_index_pos_z = nil;
	local block_index_neg_z = nil;
	if block_pos_x and block_pos_x.modelName == "slope" then
		block_index_pos_x = band(BlockEngine:GetBlockData(blockX + 1, blockY, blockZ), 0xff);
	end
	if block_neg_x and block_neg_x.modelName == "slope" then
		block_index_neg_x = band(BlockEngine:GetBlockData(blockX-1, blockY, blockZ), 0xff);
	end
	if block_pos_y and block_pos_y.modelName == "slope" then
		block_index_pos_y = band(BlockEngine:GetBlockData(blockX, blockY + 1, blockZ), 0xff);
	end
	if block_neg_y and block_neg_y.modelName == "slope" then
		block_index_neg_y = band(BlockEngine:GetBlockData(blockX, blockY-1, blockZ), 0xff);
	end
	if block_pos_z and block_pos_z.modelName == "slope" then
		block_index_pos_z = band(BlockEngine:GetBlockData(blockX, blockY, blockZ + 1), 0xff);
	end
	if block_neg_z and block_neg_z.modelName == "slope" then
		block_index_neg_z = band(BlockEngine:GetBlockData(blockX, blockY, blockZ-1), 0xff);
	end
	if 0==blockIndex then
		if block_index_pos_x
		or block_index_neg_x 
		or block_index_pos_y 
		or(block_index_neg_y and block_index_neg_y~=3)
		or(not block_index_pos_z and not block_index_neg_z and not block_index_neg_y)
		or(block_index_pos_z and block_index_pos_z~=12 and block_index_pos_z~=blockIndex) 
		or(block_index_neg_z and block_index_neg_z~=8 and block_index_neg_z~=blockIndex) then
			return false;
		end
	elseif 1==blockIndex then
		if block_index_neg_x
		or block_index_pos_x 
		or block_index_pos_y 
		or(block_index_neg_y and block_index_neg_y~=2)
		or(not block_index_pos_z and not block_index_neg_z and not block_index_neg_y)
		or(block_index_pos_z and block_index_pos_z~=9 and block_index_pos_z~=blockIndex) 
		or(block_index_neg_z and block_index_neg_z~=13 and block_index_neg_z~=blockIndex) then
			return false;
		end
	elseif 2==blockIndex then
		if block_neg_x~=nil and block_pos_y~=nil and block_index_neg_x==nil and block_index_pos_y==nil and 
			block_pos_x==nil and block_neg_y==nil
		then
			return true
		end

		if block_index_neg_x
		or block_index_pos_x
		or(block_index_pos_y and block_index_pos_y~=1)
		or block_index_neg_y
		or(not block_index_pos_z and not block_index_neg_z and not block_index_pos_y)
		or(block_index_pos_z and block_index_pos_z~=14 and block_index_pos_z~=blockIndex) 
		or(block_index_neg_z and block_index_neg_z~=10 and block_index_neg_z~=blockIndex) then
			return false;
		end
	elseif 3==blockIndex then
		if block_pos_x~=nil and block_pos_y~=nil and block_index_pos_x==nil and block_index_pos_y==nil and 
			block_neg_x==nil and block_neg_y==nil
		then
			return true
		end
		if block_index_pos_x
		or block_index_neg_x
		or(block_index_pos_y and block_index_pos_y~=0)
		or block_index_neg_y
		or(not block_index_pos_z and not block_index_neg_z and not block_index_pos_y)
		or(block_index_pos_z and block_index_pos_z~=11 and block_index_pos_z~=blockIndex) 
		or(block_index_neg_z and block_index_neg_z~=15 and block_index_neg_z~=blockIndex) then
			return false;
		end
	elseif 4==blockIndex then
		if block_index_pos_z
		or block_index_neg_z
		or(block_index_pos_y and block_index_pos_y~=7)
		or block_index_neg_y
		or(not block_index_pos_x and not block_index_neg_x and not block_index_pos_y)
		or(block_index_pos_x and block_index_pos_x~=14 and block_index_pos_x~=blockIndex) 
		or(block_index_neg_x and block_index_neg_x~=11 and block_index_neg_x~=blockIndex) then
			return false;
		end
	elseif 5==blockIndex then
		if block_index_pos_z
		or block_index_neg_z
		or(block_index_pos_y and block_index_pos_y~=6)
		or block_index_neg_y
		or(not block_index_pos_x and not block_index_neg_x and not block_index_pos_y)
		or(block_index_pos_x and block_index_pos_x~=10 and block_index_pos_x~=blockIndex) 
		or(block_index_neg_x and block_index_neg_x~=15 and block_index_neg_x~=blockIndex) then
			return false;
		end
	elseif 6==blockIndex then
		if block_index_pos_z
		or block_index_neg_z 
		or block_index_pos_y 
		or(block_index_neg_y and block_index_neg_y~=5)
		or(not block_index_pos_x and not block_index_neg_x and not block_index_neg_y)
		or(block_index_pos_x and block_index_pos_x~=13 and block_index_pos_x~=blockIndex) 
		or(block_index_neg_x and block_index_neg_x~=8 and block_index_neg_x~=blockIndex) then
			return false;
		end
	elseif 7==blockIndex then
		if block_index_neg_z
		or block_index_pos_z 
		or block_index_pos_y 
		or(block_index_neg_y and block_index_neg_y~=4)
		or(not block_index_pos_x and not block_index_neg_x and not block_index_neg_y)
		or(block_index_pos_x and block_index_pos_x~=9 and block_index_pos_x~=blockIndex) 
		or(block_index_neg_x and block_index_neg_x~=12 and block_index_neg_x~=blockIndex) then
			return false;
		end
	elseif 8==blockIndex then
		if block_index_pos_x~=6 or block_index_pos_z ~=0 then
			return false;
		end
	elseif 9==blockIndex then
		if block_index_neg_x~=7 or block_index_neg_z~=1 then
			return false;
		end
	elseif 10==blockIndex then
		if block_index_neg_x~=5 or block_index_pos_z~=2 then
			return false;
		end
	elseif 11==blockIndex then
		if block_index_pos_x~=4 or block_index_neg_z~=3 then
			return false;
		end
	elseif 12==blockIndex then
		if block_index_pos_x~=7 or block_index_neg_z~=0 then
			return false;
		end
	elseif 13==blockIndex then
		if block_index_neg_x~=6 or block_index_pos_z~=1 then
			return false;
		end
	elseif 14==blockIndex then
		if block_index_neg_x~=4 or block_index_neg_z~=2 then
			return false;
		end
	elseif 15==blockIndex then
		if block_index_pos_x~=5 or block_index_pos_z~=3 then
			return false;
		end
	elseif 16==blockIndex then
		if block_index_pos_x~=6 or block_index_neg_z~=1 then
			return false;
		end
	elseif 17==blockIndex then
		if block_index_pos_x~=5 or block_index_neg_z~=2 then
			return false;
		end
	elseif 18==blockIndex then
		if block_index_neg_x~=6 or block_index_neg_z~=0 then
			return false;
		end
	elseif 19==blockIndex then
		if block_index_neg_x~=5 or block_index_neg_z~=3 then
			return false;
		end
	elseif 20==blockIndex then
		if block_index_neg_x~=7 or block_index_pos_z~=0 then
			return false;
		end
	elseif 21==blockIndex then
		if block_index_neg_x~=4 or block_index_pos_z~=3 then
			return false;
		end
	elseif 22==blockIndex then
		if block_index_pos_x~=7 or block_index_pos_z~=1 then
			return false;
		end
	elseif 23==blockIndex then
		if block_index_pos_x~=4 or block_index_pos_z~=2 then
			return false;
		end
	elseif 24==blockIndex then
		if block_pos_x==nil or block_neg_z==nil or block_index_pos_x~=nil or block_index_neg_z~=nil then
			return false
		end
	elseif 25==blockIndex then
		if block_neg_x==nil or block_neg_z==nil or block_index_neg_x~=nil or block_index_neg_z~=nil then
			return false
		end
	elseif 26==blockIndex then
		if block_neg_x==nil or block_pos_z==nil or block_index_neg_x~=nil or block_index_pos_z~=nil then
			return false
		end
	elseif 27==blockIndex then
		if block_pos_x==nil or block_pos_z==nil or block_index_pos_x~=nil or block_index_pos_z~=nil then
			return false
		end
	elseif 28==blockIndex then
		if block_pos_y==nil or block_neg_z==nil or block_index_pos_y~=nil or block_index_neg_z~=nil then
			return false
		end
	elseif 29==blockIndex then
		if block_pos_y==nil or block_pos_z==nil or block_index_pos_y~=nil or block_index_pos_z~=nil then
			return false
		end
	else
		return false;
	end
	return true;
end


local function isMatch_outCornerModels(blockIndex, blockX, blockY, blockZ)
	local block_pos_x = BlockEngine:GetBlock(blockX + 1, blockY, blockZ);
	local block_neg_x = BlockEngine:GetBlock(blockX-1, blockY, blockZ);
	local block_pos_y = BlockEngine:GetBlock(blockX, blockY + 1, blockZ);
	local block_neg_y = BlockEngine:GetBlock(blockX, blockY-1, blockZ);
	local block_pos_z = BlockEngine:GetBlock(blockX, blockY, blockZ + 1);
	local block_neg_z = BlockEngine:GetBlock(blockX, blockY, blockZ-1);
	local block_index_pos_x = nil;
	local block_index_neg_x = nil;
	local block_index_pos_y = nil;
	local block_index_neg_y = nil;
	local block_index_pos_z = nil;
	local block_index_neg_z = nil;
	if block_pos_x and block_pos_x.modelName == "slope" then
		block_index_pos_x = band(BlockEngine:GetBlockData(blockX + 1, blockY, blockZ), 0xff);
	end
	if block_neg_x and block_neg_x.modelName == "slope" then
		block_index_neg_x = band(BlockEngine:GetBlockData(blockX-1, blockY, blockZ), 0xff);
	end
	if block_pos_y and block_pos_y.modelName == "slope" then
		block_index_pos_y = band(BlockEngine:GetBlockData(blockX, blockY + 1, blockZ), 0xff);
	end
	if block_neg_y and block_neg_y.modelName == "slope" then
		block_index_neg_y = band(BlockEngine:GetBlockData(blockX, blockY-1, blockZ), 0xff);
	end
	if block_pos_z and block_pos_z.modelName == "slope" then
		block_index_pos_z = band(BlockEngine:GetBlockData(blockX, blockY, blockZ + 1), 0xff);
	end
	if block_neg_z and block_neg_z.modelName == "slope" then
		block_index_neg_z = band(BlockEngine:GetBlockData(blockX, blockY, blockZ-1), 0xff);
	end

	--锥形，直角可以指向8个顶点 https://i.bmp.ovh/imgs/2022/08/25/16c1e6198ea3c3c1.png
	if 124==blockIndex then
		if (block_index_neg_x==7 or block_index_neg_x==31) and block_index_neg_y==25 and block_index_neg_z==1 then
			return true;
		end
	elseif 125==blockIndex then
		if (block_index_neg_x==6 or block_index_neg_x==30) and block_index_neg_y==26 and block_index_pos_z==1 then
			return true;
		end
	elseif 126==blockIndex then
		if (block_index_pos_x==6 or block_index_pos_x==30) and block_index_neg_y==27 and block_index_pos_z==0 then
			return true;
		end
	elseif 127==blockIndex then
		if (block_index_pos_x==7 or block_index_pos_x==31) and block_index_neg_y==24 and block_index_neg_z==0 then
			return true;
		end
	elseif 128==blockIndex then
		if (block_index_neg_x==5 or block_index_neg_x==29) and block_index_pos_y==26 and block_index_pos_z==2 then
			return true;
		end
	elseif 129==blockIndex then
		if (block_index_pos_x==5 or block_index_pos_x==29) and block_index_pos_y==27 and block_index_pos_z==3 then
			return true;
		end
	elseif 130==blockIndex then
		if (block_index_pos_x==4 or block_index_pos_x==28) and block_index_pos_y==24 and block_index_neg_z==3 then
			return true;
		end
	elseif 131==blockIndex then
		if (block_index_neg_x==4 or block_index_neg_x==28) and block_index_pos_y==25 and block_index_neg_z==2 then
			return true;
		end
	end


	--锥形，6个方向各有4个翻滚角，共24个(包含上面的mOuterCornerBlockModels) https://i.bmp.ovh/imgs/2022/08/25/42439e0218bc849d.png
	if 100==blockIndex then
		if block_index_neg_z==0 and (block_index_pos_x==7 or block_index_pos_x==31) then
			return true;
		end
	elseif 101==blockIndex then
		if block_index_neg_z==1 and (block_index_neg_x==7 or block_index_pos_x==31) then
			return true;
		end
	elseif 102==blockIndex then
		if block_index_pos_z==1 and (block_index_neg_x==6 or block_index_pos_x==30) then
			return true;
		end
	elseif 103==blockIndex then
		if block_index_pos_z==0 and (block_index_pos_x==6 or block_index_pos_x==30) then
			return true;
		end
	elseif 104==blockIndex then
		if (block_index_neg_x==4 or block_index_neg_x==28) and block_index_neg_z==2 then
			return true;
		end
	elseif 105==blockIndex then
		if (block_index_pos_x==4 or block_index_pos_x==28) and block_index_neg_z==3 then
			return true;
		end
	elseif 106==blockIndex then
		if (block_index_pos_x==5 or block_index_pos_x==29) and block_index_pos_z==3 then
			return true;
		end
	elseif 107==blockIndex then
		if (block_index_neg_x==5 or block_index_neg_x==29) and block_index_pos_z==2 then
			return true;
		end
	elseif 108==blockIndex then
		if block_index_neg_z==1 and block_index_neg_y==25 then
			return true;
		end
	elseif 109==blockIndex then
		if block_index_neg_z==2 and block_index_pos_y==25 then
			return true;
		end
	elseif 110==blockIndex then
		if block_index_pos_z==2 and block_index_pos_y==26 then
			return true;
		end
	elseif 111==blockIndex then
		if block_index_pos_z==1 and block_index_neg_y==26 then
			return true;
		end
	elseif 112==blockIndex then
		if block_index_neg_z==3 and block_index_pos_y==24 then
			return true;
		end
	elseif 113==blockIndex then
		if block_index_neg_z==0 and block_index_neg_y==24 then
			return true;
		end
	elseif 114==blockIndex then
		if block_index_pos_z==0 and block_index_neg_y==27 then
			return true;
		end
	elseif 115==blockIndex then
		if block_index_pos_z==3 and block_index_pos_y==27 then
			return true;
		end
	elseif 116==blockIndex then
		if (block_index_pos_x==7 or block_index_pos_x==31) and block_index_neg_y==24 then
			return true;
		end
	elseif 117==blockIndex then
		if (block_index_pos_x==4 or block_index_pos_x==28) and block_index_pos_y==24 then
			return true;
		end
	elseif 118==blockIndex then
		if (block_index_neg_x==4 or block_index_neg_x==28) and block_index_pos_y==25 then
			return true;
		end
	elseif 119==blockIndex then
		if (block_index_neg_x==7 or block_index_neg_x==31) and block_index_neg_y==25 then
			return true;
		end
	elseif 120==blockIndex then
		if (block_index_pos_x==5 or block_index_pos_x==29) and block_index_pos_y==27 then
			return true;
		end
	elseif 121==blockIndex then
		if (block_index_pos_x==6 or block_index_pos_x==30) and block_index_neg_y==27 then
			return true;
		end
	elseif 122==blockIndex then
		if (block_index_neg_x==6 or block_index_neg_x==30) and block_index_neg_y==26 then
			return true;
		end
	elseif 123==blockIndex then
		if (block_index_neg_x==5 or block_index_neg_x==29) and block_index_pos_y==26 then
			return true;
		end
	end

end

local dir_side_to_data = {
 [0] = {[0] = -24, [1] = -24, [2] = 3, [3] = 0, [4] = -22, [5] = -24},
 [1] = {[0] = -23, [1] = -23, [2] = 2, [3] = 1, [4] = -22, [5] = -23},
 [2] = {[0] = 3, [1] = 2, [2] = -18, [3] = -18, [4] = -19, [5] = -18},
 [3] = {[0] = 0, [1] = 1, [2] = -17, [3] = -17, [4] = -20, [5] = -17},
};

function block:GetMetaDataFromEnv(blockX, blockY, blockZ, side, side_region, camx, camy, camz, lookat_x, lookat_y, lookat_z)
	for i=0,7 do 
		local idx = 124 + i
		if isMatch_outCornerModels(idx,blockX, blockY, blockZ) then
			return idx 
		end
	end

	for i=0,24 do 
		local idx = 100 + i
		if isMatch_outCornerModels(idx,blockX, blockY, blockZ) then
			return idx
		end
	end
	
	local data = nil;
	for i = 0, 31 do
		if _isMatch(i, blockX, blockY, blockZ) then
			data = i;
			break;
		end
	end

	if (not data and side < 4) then
		local dir = Direction.GetDirection3DFromCamera(camx,camy,camz, lookat_x,lookat_y,lookat_z);
		data = 24 + dir_side_to_data[side][dir];
	end

	if not data then
		NPL.load("(gl)script/ide/math/math3d.lua");
		local math3d = commonlib.gettable("mathlib.math3d");
		local dx, dy, dz = math3d.CameraToWorldSpace(0, 0, 1, camx, camy, camz, lookat_x, lookat_y, lookat_z);
		if math.abs(dx)>=math.abs(dz) and dx>=0 and dy<=0 then
			data = 0;
		elseif math.abs(dx)>=math.abs(dz) and dx<=0 and dy<=0 then
			data = 1;
		elseif math.abs(dx)>=math.abs(dz) and dx<=0 and dy>=0 then
			data = 2;
		elseif math.abs(dx)>=math.abs(dz) and dx>=0 and dy>=0 then
			data = 3;
		elseif math.abs(dz)>=math.abs(dx) and dy>=0 and dz<=0 then
			data = 4;
		elseif math.abs(dz)>=math.abs(dx) and dy>=0 and dz>=0 then
			data = 5;
		elseif math.abs(dz)>=math.abs(dx) and dy<=0 and dz>=0 then
			data = 6;
		elseif math.abs(dz)>=math.abs(dx) and dy<=0 and dz<=0 then
			data = 7;
		end
	end
	return data;
end

local minX_data = {[1] = 0.5,[5] = 0.5,[8] = 0.5, }
local maxX_data = {[2] = 0.5,[6] = 0.5,[7] = 0.5, }

local minZ_data = {[3] = 0.5,[5] = 0.5,[6] = 0.5, }
local maxZ_data = {[4] = 0.5,[7] = 0.5,[8] = 0.5, }

-- Adds all intersecting collision boxes representing this block to a list.
-- @param list: in|out array list to hold the output
-- @param aabb: only add if collide with this aabb. 
-- @param entity: 
function block:AddCollisionBoxesToList(x, y, z, aabb, list, entity)
	local data = BlockEngine:GetBlockData(x, y, z);
	data = band(data, 0xff);
	if(data <= 8) then
	    -- lower half
		self:SetBlockBounds(0.0, 0.0, 0.0, 1.0, 0.5, 1.0);
		block._super.AddCollisionBoxesToList(self, x, y, z, aabb, list, entity);
		-- top half
		local minX, minY, minZ = minX_data[data] or 0, 0.5, minZ_data[data] or 0;
		local maxX, maxY, maxZ = maxX_data[data] or 1, 1.0, maxZ_data[data] or 1;
		self:SetBlockBounds(minX, minY, minZ, maxX, maxY, maxZ);
		block._super.AddCollisionBoxesToList(self, x, y, z, aabb, list, entity);
	else
		-- everything else is standard cube
		self:SetBlockBounds(0.0, 0.0, 0.0, 1.0, 1.0, 1.0);
		block._super.AddCollisionBoxesToList(self, x, y, z, aabb, list, entity);
	end
end

-- rotate the block data by the given angle and axis. This is mosted reimplemented in blocks with orientations stored in block data, such as slope, bones, etc. 
-- @param blockData: current block data
-- @param angle: usually 1.57, -1.57, 3.14, -3.14, 0. 
-- @param axis: "x|y|z", if nil, it should default to "y" axis
-- @return the rotated block data. 
function block:RotateBlockData(blockData, angle, axis)
	local highColorData = band(blockData, 0xff00)
	blockData = band(blockData, 0xff);
	return self:RotateBlockDataUsingModelFacing(blockData, angle, axis) + highColorData;
end

-- mirror the block data along the given axis. This is mosted reimplemented in blocks with orientations stored in block data, such as slope, bones, etc. 
-- @param blockData: current block data
-- @param axis: "x|y|z", if nil, it should default to "y" axis
-- @return the mirrored block data. 
function block:MirrorBlockData(blockData, axis)
	local highColorData = band(blockData, 0xff00)
	blockData = band(blockData, 0xff);
	local arr
	if(axis == "x") then
		arr = {
			[1] = 0,
			[9] = 12,
			[8] = 13,
			[2] = 3,
			[14] = 11,
			[15] = 10,


			[100] = 101,
			[102] = 103,
			[104] = 105,
			[106] = 107,

			[108] = 113,
			[109] = 112,
			[110] = 115,
			[111] = 114,

			[116] = 119,
			[117] = 118,
			[120] = 123,
			[121] = 122,

			[124] = 127,
			[125] = 126,
			[128] = 129,
			[130] = 131,
		}
		
	elseif(axis == "z") then
		arr = {
			[7] = 6,
			[9] = 13,
			[8] = 12,
			[11] = 15,
			[14] = 10,
			[4] = 5,

			[100] = 103,
			[101] = 102,
			[104] = 107,
			[105] = 105,

			[108] = 111,
			[109] = 110,
			[112] = 115,
			[113] = 114,

			[116] = 121,
			[117] = 120,
			[118] = 123,
			[119] = 122,

			[124] = 125,
			[126] = 127,
			[128] = 131,
			[130] = 129,
		}
	else -- "y"
		arr = {
			[7] = 4,
			[11] = 12,
			[0] = 3,
			[8] = 15,
			[6] = 5,
			[13] = 10,
			[1] = 2,
			[9] = 14,

			[100] = 105,
			[101] = 104,
			[102] = 107,
			[103] = 106,

			[108] = 109,
			[110] = 111,
			[112] = 113,
			[114] = 115,

			[116] = 117,
			[118] = 119,
			[120] = 121,
			[122] = 123,

			[124] = 131,
			[125] = 128,
			[126] = 129,
			[127] = 130,
		}
		
	end
	for k,v in pairs(arr) do 
		if k==blockData then
			blockData = v 
			break
		elseif v==blockData then
			blockData = k
			break
		end
	end
	return blockData + highColorData;
end

function block:GetModelByBlockData2(blockData)
	if(self.models2 and blockData and self.models2.id_model_map) then
		return self.models2.id_model_map[blockData];
	end
end

-- helper function: can be used by RotateBlockData() to automatically calculate rotated block facing. 
-- please note, it will cache last search result to accelerate subsequent calls.
function block:RotateBlockDataUsingModelFacing(blockData, angle, axis)
	if(not axis or axis == "y") then
		local lastModel = self:GetModelByBlockData2(blockData)
		if(lastModel) then
			local lastFacing = lastModel.facing;
			if(lastFacing) then
				facing = lastFacing + angle;
				if(facing < 0) then
					facing = facing + 6.28;
				end
				facing = (math.floor(facing/1.57+0.5) % 4) * 1.57;

				if(not lastModel.facings) then
					lastModel.facings = {};
					for _, model in ipairs(self.models2) do
						if(model.assetfile == lastModel.assetfile and model.facing and model.transform==lastModel.transform) then
							lastModel.facings[model.facing] = model.id_data;
						end
					end
					if(not lastModel.facings[3.14] and lastModel.facings[0]) then
						lastModel.facings[3.14] = lastModel.facings[0];
					end
					if(not lastModel.facings[4.71] and lastModel.facings[1.57]) then
						lastModel.facings[4.71] = lastModel.facings[1.57];
					end
				end
				blockData = lastModel.facings[facing] or blockData;
			end
		end
	else
		-- TODO: other axis
	end
	return blockData;
end