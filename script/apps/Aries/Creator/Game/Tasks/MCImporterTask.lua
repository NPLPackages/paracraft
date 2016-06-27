--[[
Title: Importing blocks from the minecraft mcr file or world folder
Author(s): LiXizhi
Date: 2013/5/11
Desc: This file works with the MCImporter.dll which is a C++ plugin to import models from minecraft to the game. 
Simple drag *.mca file from file explorer to the game window to export all blocks in region directory. 
If there are too many files in region directory, it may take several minute to export, so one may need to remove unrelated mca files in region folder before export. 
It is also possible to drag "temp/mcimporter.mcr.tmp" to any block world to import exported blocks. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MCImporterTask.lua");
local task = MyCompany.Aries.Game.Tasks.MCImporter:new({folder="E:/Games/Minecraft1.5.2_mod/Minecraft/.minecraft/saves/test1/", min_y=64, bExportOpaque=false})
task:Run();

NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MCImporterTask.lua");
local task = MyCompany.Aries.Game.Tasks.MCImporter:new({offset_bx = nil, offset_by=nil, offset_bz=nil})
task:cmd_create();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TaskManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/UndoManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/block_types.lua");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local UndoManager = commonlib.gettable("MyCompany.Aries.Game.UndoManager");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")

local MCImporter = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.MCImporter"));

-- if true, we will use "MCImporter_d.dll" instead of "MCImporter.dll" for debugging. 
local debug_dll = false;

MCImporter.max_radius = 30;
local temp_blocks_filename = "temp/mcimporter.mcr.tmp";

local callbacks = {};

local block_map = {
	[1] = 56,
[2] = 62,
[3] = 55,
[4] = 58,
[5] = 81,
    [501] = 138,
	[502] = 139,
	[503] = 140,
    [6] = 119,
    [601] = 120,
	[602] = 121,
	[603] = 122,
	[7] = 123,
	[8] = 75, 
	[9] = 75,
[10] = 82,
[11] = 82,
[12] = 51,
	[13] = 12,
	[14] = 18, -- gold
	[15] = 124, -- iron
	[16] = 125,
	[17] = 98,
	[1701] = 126,
	[1702] = 127,
	[1703] = 128,
	[18] = 86, --leaves oak
	[1801] = 91,
    [1802] = 129,
	[1803] = 85,
	         [19] = 174,
	[20] = 95,
	[21] = 130,
	[22] = 131,
[23] = 83,
	[24] = 4,
	         [2401] = 170,
	         [2402] = 171,	
[25] = 83,
[26] = 23,
[27] = 103,
[28] = 103,
[29] = 83,
	[30] = 118, -- cobweb
	[31] = 113,
	[3101] = 113,
	[3102] = 114,
	[32] = 132,
	[33] = 83,
	[34] = 83,
	[35] = 133,
    [3501] = 94,
    [3502] = 25,
	[3503] = 21,
	[3504] = 27,
	[3505] = 93,
	[3506] = 96,
	[3507] = 134,
	[3508] = 135,
	[3509] = 20,
	[3510] = 24,
	[3511] = 19,
	[3512] = 136,
	[3513] = 137,
	[3514] = 23,
	[3515] = 71,
	[37] = 116,
	[38] = 115,
	[39] = 141,
	[40] = 117,
	[41] = 142,
	[42] = 143,
	[43] = 59,
	       [44] = 176,
	       [4401] = 177,
               [4402] = 160,
	       [4403] = 178,
	       [4404] = 179,
	       [4405] = 180,
	       [4406] = 181,
	       [4407] = 182,
[45] = 70,
[46] = 23,
	[47] = 144,
	[48] = 145,
	[49] = 146,
[50] = 100, --torch
[51] = 82, -- fire
[52] = 83,
	[53] = 112,
[54] = 83,
[55] = 83,
	[56] = 147,
	[57] = 148,
[58] = 83,
                    [59] = 164,
[60] = 13,
[61] = 83,
[62] = 83,
[63] = 83,
	[64] = 108, -- trapdoor 
                     [65] = 166,
[66] = 103, -- rail
                     [67] = 175, --cobblestone_stairs
[68] = 83,
[69] = 105, -- lever
	[70] = 83,
[71] = 108,
	[72] = 83,
[73] = 16,
[74] = 16,
[75] = 100,
[76] = 100,
	[77] = 105,
[78] = 5,
    [7801] = 5,
	[7802] = 5,
	[7803] = 5,
	[7804] = 5,
	[7805] = 5,
	[7806] = 5,
[79] = 17,
[80] = 5,
                  [81] = 165,
	[82] = 53,
                 [83] = 161,
	[84] = 83,
[85] = 101, -- fence
	[86] = 149,
	[87] = 150,
	[88] = 151,
[89] = 87, -- glowstone
[90] = 24,
	[91] = 149,
	[92] = 84,
[93] = 83,
	[94] = 83,
[95] = 83,
	[96] = 108,
[97] = 83,
	[98] = 68,
	[9801] = 69,
    [9802] = 66,
	[9803] = 89,
	[99] = 136,
[100] = 23,
[101] = 108,
[102] = 102,
	[103] = 152,
[104] = 93,
[105] = 93,
	              [106] = 162,
[107] = 101,
              [108] = 167,
	      [109] = 168,
	[110] = 153,
	[111] = 93,
	[112] = 154,
[113] = 101,
               [114] = 169,
	[115] = 23,
[116] = 83,
[117] = 83,
[118] = 83,
	[119] = 24,
[120] = 83,
	[121] = 155,
	[122] = 23,
	[123] = 6,
	[124] = 6,
[125] = 81,
                [126] = 160,
                [12601] = 183,
	        [12602] = 184,
	        [12603] = 185,        
	[127] = 149,
[128] = 104, -- stairs
[129] = 2,
[130] = 83,
	[131] = 105,
	[132] = 83,
	[133] = 156,
	          [134] = 172,
	          [135] = 173,
	          [136] = 188,
[137] = 83,
[138] = 83,
	[139] = 111,
[140] = 83,
	[141] = 86,
	[142] = 86,
[143] = 105,
	[144] = 71,
	[145] = 83,
[146] = 83,
	[147] = 142,
	[148] = 143,
[149] = 23,
[150] = 23,
	[151] = 83,
	[152] = 157,
	[153] = 158,
	[154] = 71,
	[155] = 97,
	[15501] = 8,
	[15502] = 159,
              [156] = 187,
[157] = 103, --rails
[158] = 83,
              [170] = 186,
    [171] = 133,
    [17101] = 94,
    [17102] = 25,
    [17103] = 21,
    [17104] = 27,
	[17105] = 93,
	[17106] = 96,
	[17107] = 134,
	[17108] = 135,
	[17109] = 20,
	[17110] = 24,
	[17111] = 19,
	[17112] = 136,
	[17113] = 137,
	[17114] = 23,
	[17115] = 71,
	[172] = 53,
	[173] = 71,
	         
}
-- translate minecraft block id to our block id. 
local function translate_block_id(block_id)
	local id = block_map[block_id];
	if(id) then
		return id;
	else
		if(block_id > 200) then
			-- default to base index
			id = block_map[math.floor(block_id/100)];
			if(id) then
				echo({"info: mc block_id replaced with base part", block_id})
			else
				echo({"warn: unknown mc block id", block_id})
			end
		else
			echo({"warn: unknown mc block id", block_id})
		end
		block_map[block_id] = id or 5;
	end
	return id;
end


function MCImporter:get_dll_name()
	return if_else(self.debug or debug_dll, "MCImporter_d.dll", "MCImporter.dll")
end

function MCImporter:ctor()
	self.step = 1;
	self.history = {};
	block_types.init();

	-- always use mapping in block_types.xml first. 
	local mc_id, id
	for mc_id, id in pairs(block_types.mc_id_map) do
		block_map[mc_id] = id;
	end

	if(self.folder) then
		self:cmd_load(self.folder);
	end
	if(self.filename) then
		self:cmd_create(self.filename);
	end
end

-- @param min_y: default to 0
-- @param max_y: default to 256
-- @param bExportOpaque: default to false. if true, all blocks are exported. if not, blocks whose nearby 6 blocks are all solid are not exported. 
function MCImporter:cmd_load(folder)
	folder = folder or self.folder;
	if(folder) then
		if(NPL.activate(self:get_dll_name(), {cmd = "load", folder = folder, min_y = self.min_y, max_y = self.max_y, bExportOpaque = self.bExportOpaque})~=0) then
			_guihelper.MessageBox(format("error: %s not found!", self:get_dll_name()))
		end
	end
end

-- @param offset_bx, offset_by, offset_bz : default offset position. default to current player position's containing region. 
--  sealevel in minecraft is always on 64. however, in our game, it is 128. so if this is not specified. offset_by is always 64. 
function MCImporter:cmd_create(filename)
	-- disable game logics, such as auto block generation
	BlockEngine:SetGameLogic(nil);
	
	filename = filename or temp_blocks_filename;
	if(filename) then
		local file = ParaIO.open(filename, "r");
		if(file:IsValid()) then
			NPL.load("(gl)script/ide/timer.lua");
			local max_blocks_per_tick = 10000;

			local px, py, pz = ParaScene.GetPlayer():GetPosition();
			local offset_bx, offset_by, offset_bz = BlockEngine:block(px, py, pz);

			offset_bx = self.offset_bx or offset_bx;
			offset_by = self.offset_by or 0; 
			offset_bz = self.offset_bz or offset_bz;

			-- use the current player's containing block
			offset_bx = math.floor(offset_bx / BlockEngine.region_size) * BlockEngine.region_size;
			offset_bz = math.floor(offset_bz / BlockEngine.region_size) * BlockEngine.region_size;

			local offset_center_bx = offset_bx;
			local offset_center_bz = offset_bz;

			local view_pos_x, view_pos_y, view_pos_z = offset_bx, 0, offset_bz; 

			-- ParaTerrain.GetAttributeObject():SetField("RenderTerrain",false);

			ParaTerrain.GetBlockAttributeObject():CallField("SuspendLightUpdate");

			local count = 0;
			local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
				local line;
				local i;
				view_pos_y = 0;
				for i = 1, max_blocks_per_tick do
					line = file:readline();
					if(line) then
						local x, y, z, block_id = line:match("([^,]+),([^,]+),([^,]+),(%d+)");
						if(x == "region") then
							y, z, block_id = tonumber(y), tonumber(z), tonumber(block_id);
							-- this is begining of a new region 
							local cx = offset_center_bx + y * BlockEngine.region_size;
							local cz = offset_center_bz + z * BlockEngine.region_size;
							local cy = 0;
							cx, cy, cz = BlockEngine:real(cx, cy, cz);

							-- local step = BlockEngine.blocksize*8;
							-- for i = 1, 64 do 
							-- 	for j = 1, 64 do 
							-- 		local xx = cx + i * step - 1;
							-- 		local zz = cz + j * step - 1;
							-- 		if(not ParaTerrain.IsHole(xx,zz)) then
							-- 			ParaTerrain.SetHole(xx,zz, true);
							-- 			ParaTerrain.UpdateHoles(xx,zz);
							-- 		end
							-- 	end
							-- end

							-- teleport player to the highest position in the last max_blocks_per_tick blocks. 
							local px, py, pz = BlockEngine:real(cx, cy+1, cz);
							ParaScene.GetPlayer():SetPosition(px, py, pz);
							local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");
							CommandManager:RunCommand("loadregion", format("%d %d %d %d", cx, cy, cz, 256));
							GameLogic.SetStatus(format("importing region: %d %d", y, z));
						else
							x, y, z, block_id = tonumber(x), tonumber(y), tonumber(z), tonumber(block_id);
							if(block_id) then
								block_id = translate_block_id(block_id);
								if(block_id) then
									count = count + 1;
									x = x + offset_bx;
									y = y + offset_by;
									z = z + offset_bz;
									if(y>=0 and y<256) then
										ParaTerrain.SetBlockTemplateByIdx(x, y, z, block_id);
										if(view_pos_y<y) then
											view_pos_x, view_pos_y, view_pos_z = x,y,z;
										end
									end
								end
							end
						end
					else
						break;
					end
				end

				if(view_pos_y > 0) then
					-- teleport player to the highest position in the last max_blocks_per_tick blocks. 
					local px, py, pz = BlockEngine:real(view_pos_x, view_pos_y+1, view_pos_z);
					ParaScene.GetPlayer():SetPosition(px, py, pz);
				end

				if(line == nil) then
					LOG.std(nil, "info", "MCImporter", "create %d blocks from %s", count, filename)
					ParaTerrain.GetBlockAttributeObject():CallField("ResumeLightUpdate");
					file:close();
				else
					timer:Change(30);
				end
			end})
			
			mytimer:Change(100)
		end
	end
end

-- @param x, y:
function MCImporter:RemoveTerrain(x,y)
	ParaTerrain.SetHole(cx, cz, true);
	
end

function MCImporter:Run()
	
end

function MCImporter:FrameMove()
	self.finished = true;
end

function MCImporter:Redo()

end

function MCImporter:Undo()
end

local function activate()
	if(not msg.succeed) then
		return
	end
	local filename = msg.filename;
	if(filename) then
		
		_guihelper.MessageBox(format("已经成功导出 %d个方块到文件 %s. 是否现在添加到场景中， 可能需要一定时间. 您也可以手动将这个文件拖到游戏窗口中来添加.", msg.count or 0, filename), function()
			local task = MCImporter:new({offset_bx = nil, offset_by=nil, offset_bz=nil})
			task.regions = msg.regions;
			task:cmd_create(filename);
		end);
	end
end

NPL.this(activate);
