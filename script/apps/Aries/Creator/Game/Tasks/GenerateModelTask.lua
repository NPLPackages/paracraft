--[[
Title: Generate a model or character task
Author(s): LiPeng
Date: 2015/2/11
Desc: Generate a single model/character according to the selected blocks.
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/GenerateModelTask.lua");
local task = MyCompany.Aries.Game.Tasks.GenerateModel:new({obj_params})
task:Run();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/UndoManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Assets/AssetsCommon.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SelectBlocksTask.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/block_types.lua");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local UndoManager = commonlib.gettable("MyCompany.Aries.Game.UndoManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local QuickSelectBar = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.QuickSelectBar");

local GenerateModel = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.GenerateModel"));

local default_data = {
	-- "xof" show file is model file
	["check"] = "xof",
	-- such as 0303, 0302, default as "0303"
	["fileversion"] = "0303",
	-- "txt","bin" or "bzip", default as "txt"
	["textformat"] = "txt",
	-- float size: "0032" or "0064", default as "0032"
	["floatsize"] = "0032",
	-- model id
	["headid"] = "112,97,114,97",
	-- model version
	["headversion"] = "1,0,0,0",
	-- model type
	["type"] = "1",
	-- model be animated
	["beanimated"] = "0";
	-- the default diffuse
	["diffuse"] = "0.588000;0.588000;0.588000;1.000000;";
	-- the default specular exponent
	["specularexponent"] = "0.0";
	-- the default specular
	["specular"] = "0.900000;0.900000;0.900000;";
	-- the default emissive
	["emissive"] = "1.000000;0.000000;0.000000;";
}

local blocksInfo = {};
local material_struct = {};
local material_map = {}
local vertice_struct = {};
local vertice_map = {}
local face_struct = {};
local face_map = {};
local origin_vertice = nil;

local msg_t = {};

-- the will generate mode file;
local file;

function GenerateModel:ctor(o)
	local select_task = MyCompany.Aries.Game.Tasks.SelectBlocks.GetCurrentInstance();
	if(select_task) then
		local cur_selection = select_task:GetSelectedBlocks();
		if(cur_selection and next(cur_selection)) then
			self.blocks = cur_selection
		end
	end
	--self.filename = o.filename;
end

local function getBlockTexture(id)
	local block_template = block_types.get(id);
	--echo("block_template.texture");
	--echo(block_template.texture);
	return {filename = block_template.texture};
end

local function getVerticeIndex()
	return #vertice_map + 1;
end

local function getFaceIndex()
	return #face_map + 1;
end

local square_face_info = {
	[1] = { 
		tag = "x+", normal = {x = 1, y = 0, z = 0},public_vertices = {{x = 0.5, y = 0.5, z = 0.5}, {x = 0.5, y = -0.5, z = -0.5}}, triangle_vertices = {{x = 0.5,y = 0.5, z = -0.5 } ,{x = 0.5,y = -0.5, z = 0.5}}
	},
	[2] = { 
		tag = "x-", normal = {x = -1, y = 0, z = 0},public_vertices = {{x = -0.5, y = 0.5, z = 0.5}, {x = -0.5, y = -0.5, z = -0.5}}, triangle_vertices = {{x = -0.5,y = 0.5, z = -0.5 } ,{x = -0.5,y = -0.5, z = 0.5}}
	},
	[3] = { 
		tag = "y+", normal = {x = 0, y = 1, z = 0},public_vertices = {{x = 0.5, y = 0.5, z = 0.5}, {x = -0.5, y = 0.5, z = -0.5}}, triangle_vertices = {{x = -0.5,y = 0.5, z = 0.5 } ,{x = 0.5,y = 0.5, z = -0.5}}
	},
	[4] = { 
		tag = "y-", normal = {x = 0, y = -1, z = 0},public_vertices = {{x = 0.5, y = -0.5, z = 0.5}, {x = -0.5, y = -0.5, z = -0.5}}, triangle_vertices = {{x = -0.5,y = -0.5, z = 0.5 } ,{x = 0.5,y = -0.5, z = -0.5}}
	},
	[5] = { 
		tag = "z+", normal = {x = 0, y = 0, z = 1},public_vertices = {{x = 0.5, y = 0.5, z = 0.5}, {x = -0.5, y = -0.5, z = 0.5}}, triangle_vertices = {{x = 0.5,y = -0.5, z = 0.5}, {x = -0.5,y = 0.5, z = 0.5 }}
	},
	[6] = { 
		tag = "z-", normal = {x = 0, y = 0, z = -1},public_vertices = {{x = 0.5, y = 0.5, z = -0.5}, {x = -0.5, y = -0.5, z = -0.5}}, triangle_vertices = {{x = 0.5,y = -0.5, z = -0.5}, {x = -0.5,y = 0.5, z = -0.5 }}
	},
}

local msg = "";
-- vertice_struct
-- face_struct
function GenerateModel:ProcessBlocks()
	if(self.blocks) then
		echo("process begin")
		local vertices_num, faces_num, normals_num, uv_num = 0, 0, 0, 0;
		--local last_percent, cur_percent = 0, 0;
		
		local blocks_num = self.blocks_num;
		--_guihelper.MessageBox(string.format("开始格式化方块信息"));
		--local msg = "开始格式化方块信息"
		--table.insert(msg_t,msg);
		if(not self.hasGetModelInfo) then
			_guihelper.MessageBox(msg);
			for i = self.hasGetModelInfoBlocksNumber,blocks_num do
				
			
				local block = self.blocks[i];
				-- one block processing
				local info = {
					faces = {},
				};
				block.info = info;
				local x  = block[1];
				local y  = block[2];
				local z  = block[3];
				if(not self.origin_vertice) then
					self.origin_vertice = {
						x = x,
						y = y,
						z = z,
					}
				end
				x = x - self.origin_vertice.x;
				y = y - self.origin_vertice.y;
				z = z - self.origin_vertice.z;
				info.x = x;
				info.y = y;
				info.z = z;
				local material_id = block[4];
				info.material_id = material_id;

				local tag = string.format("%d|%d|%d",x,y,z);
				block["tag"] = tag;
				blocksInfo[tag] = info;
				for j = 1,6 do
					-- one square face processing
					--local texture = getBlockTexture(id);
					local public_vertices_offset = square_face_info[j]["public_vertices"];
					local triangle_vertices_offset = square_face_info[j]["triangle_vertices"];
					local normal = square_face_info[j]["normal"];
					local face_tag = square_face_info[j]["tag"];
					info.faces[face_tag] = {};
					for k = 1,2 do
						local tri_face = {};
						--tri_face.material_id = material_id;
						tri_face.tag = face_tag;
						--face_map[#face_map + 1] = tri_face;
						info.faces[face_tag][k] = tri_face
						--info.faces[(j-1)*2 + k] = tri_face;
						-- one triangle face processing
						local uv = if_else(k == 1,{u = 1, v = 0},{u = 0, v = 1});
						local vertices = {};
						tri_face.vertices = vertices;

						for m = 1,3 do
							-- one vertice processing
							local pos_x, pox_y, pox_z, uv_u, uv_v;
							if(m == 3) then
								pos_x = x + triangle_vertices_offset[k].x;
								pos_y = y + triangle_vertices_offset[k].y;
								pos_z = z + triangle_vertices_offset[k].z;
								uv_u  = if_else(k == 1,0,1);
								uv_v  = if_else(k == 1,0,1);
							else
								pos_x = x + public_vertices_offset[m].x;
								pos_y = y + public_vertices_offset[m].y;
								pos_z = z + public_vertices_offset[m].z;
								uv_u  = if_else(m == 1,0,1);
								uv_v  = if_else(m == 1,1,0);
							end

							if(not self.maxextent) then
								self.maxextent = {
									x = pos_x,
									y = pos_y,
									z = pos_z,
								};
							else
								if(self.maxextent.x < pos_x) then
									self.maxextent.x = pos_x;
								end
								if(self.maxextent.y < pos_y) then
									self.maxextent.y = pos_y;
								end
								if(self.maxextent.z < pos_z) then
									self.maxextent.z = pos_z;
								end
							end

							if(not self.minextent) then
								self.minextent = {
									x = pos_x,
									y = pos_y,
									z = pos_z,
								};
							else
								if(self.minextent.x > pos_x) then
									self.minextent.x = pos_x;
								end
								if(self.minextent.y > pos_y) then
									self.minextent.y = pos_y;
								end
								if(self.minextent.z > pos_z) then
									self.minextent.z = pos_z;
								end
							end

							--local pos_x = 
							local vertice = {
								pos = {x = pos_x, y = pos_y, z = pos_z},
								normal = normal,
								uv  = {u = uv_u, v = uv_v},
								--id = id,
							};
							vertices[#vertices + 1] = vertice;
						end
					end
				end
				self.cur_percent = math.floor(i*100/blocks_num);
				if(self.cur_percent > self.last_percent) then
					self.last_percent = self.cur_percent;
					--_guihelper.MessageBox(string.format("格式化方块信息，当前进度%%%d",cur_percent));
					msg = string.format("格式化方块信息，当前进度%d%%",self.cur_percent)
					self.hasGetModelInfoBlocksNumber = i + 1;
					if(self.cur_percent == 100) then
						self.last_percent, self.cur_percent = 0, 0;
						self.hasGetModelInfo = true;
					end
					break;
					--table.insert(msg_t,msg);
				end
			end
			echo("process blocks")
		elseif(not self.hasGetNeighbourInfo) then
			for i = self.hasGetNeighbourInfoBlocksNumber,blocks_num do
			--for block_tag, block_info in pairs(blocksInfo) do
				local block = self.blocks[i];
				local block_tag, block_info = block["tag"], block["info"];
				local x, y, z = block_info.x, block_info.y, block_info.z;
				--local neighbour = {};
				local neighbour_number = 0;
				block_info.show_faces = {["x+"] = true, ["x-"] = true, ["y+"] = true, ["y-"] = true, ["z+"] = true, ["z-"] = true,};
				block_info.show = true;
				local x_positive = string.format("%d|%d|%d",x+1,y,z);
				local x_negative = string.format("%d|%d|%d",x-1,y,z);
				local y_negative = string.format("%d|%d|%d",x,y+1,z);
				local y_negative = string.format("%d|%d|%d",x,y-1,z);
				local z_negative = string.format("%d|%d|%d",x,y,z+1);
				local z_negative = string.format("%d|%d|%d",x,y,z-1);
				if(blocksInfo[x_positive]) then
					block_info.show_faces["x+"] = false;
					neighbour_number = neighbour_number + 1;
				end
				if(blocksInfo[x_negative]) then
					block_info.show_faces["x-"] = false;
					neighbour_number = neighbour_number + 1;
				end
				if(blocksInfo[y_positive]) then
					block_info.show_faces["y+"] = false;
					neighbour_number = neighbour_number + 1;
				end
				if(blocksInfo[y_negative]) then
					block_info.show_faces["y-"] = false;
					neighbour_number = neighbour_number + 1;
				end
				if(blocksInfo[z_positive]) then
					block_info.show_faces["z+"] = false;
					neighbour_number = neighbour_number + 1;
				end
				if(blocksInfo[z_negative]) then
					block_info.show_faces["z-"] = false;
					neighbour_number = neighbour_number + 1;
				end
				if(neighbour_number == 6) then
					block_info.show = false;
				end
				self.cur_percent = math.floor(i*100/blocks_num);
				if(self.cur_percent > self.last_percent) then
					self.last_percent = self.cur_percent;
					--_guihelper.MessageBox(string.format("格式化方块信息，当前进度%%%d",cur_percent));
					msg = string.format("计算方块相邻信息，当前进度%d%%",self.cur_percent)
					self.hasGetNeighbourInfoBlocksNumber = i + 1;
					if(self.cur_percent == 100) then
						self.last_percent, self.cur_percent = 0, 0;
						self.hasGetNeighbourInfo = true;
					end
					break;
					--table.insert(msg_t,msg);
				end
			end
		elseif(not self.hasGetVerticesAndFaces) then
			for i = self.hasGetVerticesAndFacesBlocksNumber,blocks_num do
			--for block_tag, block_info in pairs(blocksInfo) do
				local block = self.blocks[i];
				local block_tag, block_info = block["tag"], block["info"];
				if(block_info.show) then

					local texture_index;
					local material_id = block_info.material_id;

					local texture = getBlockTexture(material_id);
					if(not material_struct[material_id]) then
						texture_index = #material_map + 1;
						material_struct[material_id] = texture_index;
						--v1.index = index;
						material_map[texture_index] = texture;
					else
						texture_index = material_struct[material_id];
					end

					local face_tag, tage_value;
					for face_tag, tage_value in pairs(block_info.show_faces) do
						if(tage_value) then
							for j = 1,2 do
								local tri_face = block_info.faces[face_tag][j];
								face_map[#face_map + 1] = tri_face;
								--local vertices = tri_face.vertices;
								for m = 1,3 do
									local vertice = tri_face.vertices[m];
									local vertice_str = string.format("%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d", vertice.pos.x, vertice.pos.y, vertice.pos.z, vertice.normal.x, vertice.normal.y, vertice.normal.z, vertice.uv.u, vertice.uv.v, material_id, block_info.x, block_info.y, block_info.z);
									if(not vertice_struct[vertice_str]) then
										local index = #vertice_map + 1;
										vertice_struct[vertice_str] = index;
										vertice.index = index;
										vertice_map[index] = vertice;
									else
										vertice.index = vertice_struct[vertice_str];
									end
								end
								tri_face.texture_inedex = texture_index;
							end
						end
					end
				end
				self.cur_percent = math.floor(i*100/blocks_num);
				if(self.cur_percent > self.last_percent) then
					self.last_percent = self.cur_percent;
					--_guihelper.MessageBox(string.format("格式化方块信息，当前进度%%%d",cur_percent));
					msg = string.format("统计方块包含顶点和三角面，当前进度%d%%",self.cur_percent)
					self.hasGetVerticesAndFacesBlocksNumber = i + 1;
					if(self.cur_percent == 100) then
						self.last_percent, self.cur_percent = 0, 0;
						self.hasGetVerticesAndFaces = true;
					end
					break;
					--table.insert(msg_t,msg);
				end
			end
		elseif(not self.hasProcessVerticesInfo) then
			self.vertices_number = #vertice_map;
			self.normals_number = self.vertices_number;
			self.uvs_number = self.vertices_number;
			for i = self.hasProcessVerticesNumber,self.vertices_number do
				local vertice = vertice_map[i];
				local vertice_info = string.format("%f;%f;%f;", vertice.pos.x, vertice.pos.y, vertice.pos.z);
				table.insert(self.vertices_info,vertice_info);
				local normal_info = string.format("%f;%f;%f;", vertice.normal.x, vertice.normal.y, vertice.normal.z);
				table.insert(self.normals_info,normal_info);
				local uv_info = string.format("%f;%f;", vertice.uv.u, vertice.uv.v);
				table.insert(self.uvs_info,uv_info);

				self.cur_percent = math.floor(i*100/self.vertices_number);
				if(self.cur_percent > self.last_percent) then
					self.last_percent = self.cur_percent;
					--_guihelper.MessageBox(string.format("格式化方块信息，当前进度%%%d",cur_percent));
					msg = string.format("格式化顶点、法线、UV信息，当前进度%d%%",self.cur_percent)
					self.hasProcessVerticesNumber = i + 1;
					if(self.cur_percent == 100) then
						self.last_percent, self.cur_percent = 0, 0;
						self.hasProcessVerticesInfo = true;
					end
					break;
					--table.insert(msg_t,msg);
				end
			end
		elseif(not self.hasProcessFacesInfo) then
			self.faces_number = #face_map;
			for i = self.hasProcessFacesNumber,self.faces_number do
				local face = face_map[i];
				local vertice = face.vertices;
				local face_info;
				if(face.tag == "x+" or face.tag == "y+" or face.tag == "z+") then
					if(i%2 == 1) then
						face_info = string.format("%d;%d,%d,%d;", 3, vertice[1]["index"] - 1, vertice[2]["index"] - 1, vertice[3]["index"] - 1);
					else
						face_info = string.format("%d;%d,%d,%d;", 3, vertice[2]["index"] - 1, vertice[1]["index"] - 1, vertice[3]["index"] - 1);
					end
				else
					if(i%2 == 1) then
						face_info = string.format("%d;%d,%d,%d;", 3, vertice[2]["index"] - 1, vertice[1]["index"] - 1, vertice[3]["index"] - 1);
					else
						face_info = string.format("%d;%d,%d,%d;", 3, vertice[1]["index"] - 1, vertice[2]["index"] - 1, vertice[3]["index"] - 1);
					end
				end
				table.insert(self.faces_info,face_info);
				table.insert(self.material_queue_of_faces,face.texture_inedex - 1);

				self.cur_percent = math.floor(i*100/self.faces_number);
				if(self.cur_percent > self.last_percent) then
					self.last_percent = self.cur_percent;
					--_guihelper.MessageBox(string.format("格式化方块信息，当前进度%%%d",cur_percent));
					msg = string.format("格式化顶点、法线、UV信息，当前进度%d%%",self.cur_percent)
					self.hasProcessFacesNumber = i + 1;
					if(self.cur_percent == 100) then
						self.last_percent, self.cur_percent = 0, 0;
						self.hasProcessFacesInfo = true;
					end
					break;
					--table.insert(msg_t,msg);
				end
			end
		else
			self.materials_number = #material_map;
			self.hasProcessAllInfo = true;	
		end
		
		_guihelper.MessageBox(msg);
		self.timer:Change(30);
		----_guihelper.MessageBox("计算方块相邻信息");
		----local block_tag, block_info;
		--
		--
		--echo("process neighbour")
		----_guihelper.MessageBox("统计方块包含顶点和三角面");
--
		--
		--echo("process faces")
		----_guihelper.MessageBox("格式化顶点、法线、UV信息");
		--
		--
		--
		--echo("generate vertice strings")
		----_guihelper.MessageBox("格式化三角面、材质信息");
		--
		----self.face_info = "";
		--
--
		--
		--echo("generate face strings")
		--
		----return blocksInfo;
	end	
end

local function outputProcessPercent()
	local msg = msg_t[#msg_t];
	_guihelper.MessageBox(msg);
end

local function resetStructAndMap()
	blocksInfo = {};
	material_struct = {};
	material_map = {}
	vertice_struct = {};
	vertice_map = {}
	face_struct = {};
	face_map = {};
end

function GenerateModel:init()
	self.blocks_num = #self.blocks;
	self.origin_vertice = nil;
	self.vertices_number = 0;
	self.vertices_info = {};
	self.faces_number = 0;
	self.faces_info = {};
	self.normals_number = 0;
	self.normals_info = {};
	self.materials_number = 0;
	self.uvs_number = 0;
	self.uvs_info = {};
	self.minextent = nil;
	self.maxextent = nil;
	self.material_queue_of_faces = {};
	self.materials = {};

	self.last_percent = 0;
	self.cur_percent = 0;
	self.hasGetModelInfo = false;
	self.hasGetModelInfoBlocksNumber = 1;
	self.hasGetNeighbourInfo = false;
	self.hasGetNeighbourInfoBlocksNumber = 1;
	self.hasGetVerticesAndFaces = false;
	self.hasGetVerticesAndFacesBlocksNumber = 1;
	self.hasProcessVerticesInfo = false;
	self.hasProcessVerticesNumber = 1;
	self.hasProcessFacesInfo = false;
	self.hasProcessFacesNumber = 1;
	self.hasProcessAllInfo = false;
	resetStructAndMap();
end

function GenerateModel:Run()
	local function _run()
		self:init();
		self.timer = commonlib.Timer:new({callbackFunc = function(timer)
			if(not self.hasProcessAllInfo) then
				self:ProcessBlocks();
			else
				local filename = self.filename or "model/default.x";
				file = ParaIO.open(filename, "w");
				if(file:IsValid()) then
					_guihelper.MessageBox("输出模型信息到对应文件中"); 
					--self.timer:Change(0,1000);
					self:WriteFileHeader()
					self:WriteModelHeader()
					self:WriteMesh();
					file:close();
					_guihelper.MessageBox(string.format([[模型信息处理完成，保存在文件"%s"中,你现在可以查看了]],filename));
				else
					_guihelper.MessageBox(string.find("模型文件:%s 创建失败",filename));
				end		
			end
			
		end});
		self.timer:Change(30);
	end

	_guihelper.MessageBox(string.format("当前选中%d个方块,是否确定生成模型？",#(self.blocks)), function(res)
		if(res and res == _guihelper.DialogResult.No) then
			return;
		elseif(res and res == _guihelper.DialogResult.Yes) then
			_run();
		end
	end, _guihelper.MessageBoxButtons.YesNo);
end

function GenerateModel:WriteFileHeader()
	local words = ""
	-- the file check;
	words = words..(self.check or default_data.check);
	words = words.." ";
	-- the version, such as 0303
	words = words..(self.fileversion or default_data.fileversion);
	-- the text format, default as "txt"
	words = words.."txt".." ";
	-- the float size, "32" or "64";
	words = words.."0032";
	file:WriteString(words);
end

function GenerateModel:WriteModelHeader()
	-- the comment for "ParaEngine X file" info
	local words = "\r\n";
	words = words.."// Exported by ParaEngine X file exporter V0.2";
	-- the sign of the model header
	words = words.."\r\n";
	words = words.."ParaXHeader header"
	words = words.."{";
	-- the model id;
	words = words.."\r\n";
	words = words..default_data.headid;
	words = words..";";
	-- the model version
	words = words.."\r\n";
	words = words..default_data.headversion;
	words = words..";";
	-- the model type
	words = words.."\r\n";
	words = words..default_data.type;
	words = words..";";
	-- the model be animated
	words = words.."\r\n";
	words = words..default_data.beanimated;
	words = words..";";
	-- the model  minextent
	words = words.."\r\n";
	words = words..string.format("%f;%f;%f;", self.minextent.x, self.minextent.y, self.minextent.z);
	words = words..";";
	-- the model  maxextent
	words = words.."\r\n";
	words = words..string.format("%f;%f;%f;", self.maxextent.x, self.maxextent.y, self.maxextent.z);
	words = words..";";
	-- i don't know the "3" meaning
	words = words.."\r\n";
	words = words.."3";
	words = words..";";
	-- the model head end
	words = words.."\r\n";
	words = words.."}";
	file:WriteString(words);
end

function GenerateModel:WriteMesh()
	-- the mesh begin sig
	local words = "\r\n";
	words = words.."Mesh mesh_object"
	words = words.."{"
	file:WriteString(words);

	-- write vertices info
	self:WriteVerticesInfo()

	-- write faces info
	self:WriteFacesInfo()
	
	-- write MeshNormals info
	self:WriteMeshNormalsInfo();
	-- write MeshMaterialList info
	self:WriteMeshMaterialListInfo();
	-- write MeshTextureCoords info
	self:WriteMeshTextureCoordsInfo();

	-- the mesh end sig
	words = "\r\n";
	words = words.."}"
	words = words.."// mesh"
	file:WriteString(words);
end

function GenerateModel:WriteVerticesInfo()
	local words = "\r\n";
	words = words..tostring(self.vertices_number);
	words = words..";";
	words = words.." // "..tostring(self.vertices_number).." vertices";
	-- the vertice info
	words = words.."\r\n";
	file:WriteString(words);

	for i = 1,#self.vertices_info do
		local line_str = self.vertices_info[i];
		if(i == self.vertices_number) then
			line_str = line_str..";"
		else
			line_str = line_str..",".."\r\n";
			--self.vertice_info = self.vertice_info.."\r\n";
		end
		file:WriteString(line_str);
	end
end

function GenerateModel:WriteFacesInfo()
	-- the face number;
	local words = "\r\n";
	words = words..tostring(self.faces_number);
	words = words..";";
	words = words.." // "..tostring(self.faces_number).." faces";
	words = words.."\r\n";
	file:WriteString(words);

	for i = 1,#self.faces_info do
		local line_str = self.faces_info[i];
		if(i == self.faces_number) then
			line_str = line_str..";"
		else
			line_str = line_str..",".."\r\n";
			--self.vertice_info = self.vertice_info.."\r\n";
		end
		file:WriteString(line_str);
	end
end

function GenerateModel:WriteNormalsInfo()
	-- the normal number;
	local words = "\r\n"
	words = words..tostring(self.normals_number);
	words = words..";";
	words = words.." // "..tostring(self.normals_number).." normals";
	words = words.."\r\n";
	file:WriteString(words);

	for i = 1,#self.normals_info do
		local line_str = self.normals_info[i];
		if(i == self.normals_number) then
			line_str = line_str..";"
		else
			line_str = line_str..",".."\r\n";
			--self.vertice_info = self.vertice_info.."\r\n";
		end
		file:WriteString(line_str);
	end
end

function GenerateModel:WriteMeshNormalsInfo()
	-- the mesh normal begin sig
	local words = "\r\n";
	words = words.."MeshNormals"
	words = words.."{"
	file:WriteString(words);
	
	-- write normals info
	self:WriteNormalsInfo();

	-- write faces info
	self:WriteFacesInfo();

	words = "\r\n";
	words = words.."}"
	file:WriteString(words);
end

function GenerateModel:WriteFacesMaterialMap()
	local words = "\r\n";
	file:WriteString(words);

	for i = 1,#self.material_queue_of_faces do
		local material_index = tostring(self.material_queue_of_faces[i]);
		if(i == self.faces_number) then
			material_index = material_index..";;"
		else
			material_index = material_index..",";
			--self.vertice_info = self.vertice_info.."\r\n";
		end
		file:WriteString(material_index);
	end
end

function GenerateModel:WriteMeshMaterialListInfo()
	-- the mesh normal begin sig
	local words = "\r\n";
	words = words.."MeshMaterialList"
	words = words.."{"
	
	-- the unique material number;
	words = words.."\r\n";
	words = words..tostring(self.materials_number);
	words = words..";";
	words = words.." // ".." Number of unique materials";
	-- the face number;
	words = words.."\r\n";
	words = words..tostring(self.faces_number);
	words = words..";";
	words = words.." // ".." Number of faces";
	file:WriteString(words);

	-- write FacesMaterialMap
	self:WriteFacesMaterialMap()

	-- write the materials info
	self:WriteMaterials();

	-- the mesh normal end sig
	words = "\r\n";
	words = words.."}".."//".."materials"
	file:WriteString(words);
end

function GenerateModel:WriteMaterials()
	local words = "\r\n";
	file:WriteString(words);
	for i = 1,self.materials_number do
		local material = material_map[i];
		-- the material begin sig
		words = "\r\n";
		words = words.."Material"
		words = words.."{"
		-- the diffuse of the material
		words = words.."\r\n";
		words = words..(material.diffuse or default_data.diffuse);
		words = words..";";
		-- the specularexponent of the material
		words = words.."\r\n";
		words = words..(material.specularexponent or default_data.specularexponent);
		words = words..";";
		-- the specular of the material
		words = words.."\r\n";
		words = words..(material.specular or default_data.specular);
		words = words..";";
		-- the emissive of the material
		words = words.."\r\n";
		words = words..(material.emissive or default_data.emissive);
		words = words..";";
		-- the material texture filename begin sig
		words = words.."\r\n";
		words = words.."TextureFilename"
		words = words.."{"
		-- the material texture filename
		words = words.."\"";
		words = words..material.filename;
		words = words.."\"";
		words = words..";";
		-- the material texture filename end sig
		words = words.."}"
		-- the material end sig
		words = words.."\r\n";
		words = words.."}"
		file:WriteString(words);
	end
	--return words;
end

function GenerateModel:WriteMeshTextureCoordsInfo()
	-- the mesh normal begin sig
	local words = "\r\n";
	words = words.."MeshTextureCoords"
	words = words.."{";
	-- the UV number, this is equal vertices number;
	words = words.."\r\n";
	words = words..tostring(self.uvs_number);
	words = words..";";
	words = words.." // "..tostring(self.uvs_number).." UV";
	file:WriteString(words);
	words = "\r\n";
	file:WriteString(words);

	for i = 1,#self.uvs_info do
		local line_str = self.uvs_info[i];
		if(i == self.uvs_number) then
			line_str = line_str..";"
		else
			line_str = line_str..",".."\r\n";
			--self.vertice_info = self.vertice_info.."\r\n";
		end
		file:WriteString(line_str);
	end

	-- the mesh normal end sig
	words = "\r\n";
	words = words.."}"
	words = words.."// UV"
	file:WriteString(words);
end