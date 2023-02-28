	--[[
Title: BlockMaterialTask Command
Author(s): LiXizhi
Date: 2022/11/20
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BlockMaterial/BlockMaterialTask.lua");
local BlockMaterialTask = commonlib.gettable("MyCompany.Aries.Game.Tasks.BlockMaterialTask");
local task = BlockMaterialTask:new();
task:Run();
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Core/Color.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/UndoManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BlockMaterial/CreateBlockMaterialTask.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SelectBlocksTask.lua");
local SelectBlocks = commonlib.gettable("MyCompany.Aries.Game.Tasks.SelectBlocks");
local UndoManager = commonlib.gettable("MyCompany.Aries.Game.UndoManager");
local Color = commonlib.gettable("System.Core.Color");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BlockMaterialEditor = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BlockMaterial/BlockMaterialEditor.lua");

local BlockMaterialTask = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.BlockMaterialTask"));

BlockMaterialTask:Property({"maxFloodRadius", 10});
BlockMaterialTask:Signal("colorPicked", function(color) end)

local PageSize = 18;
local cur_instance;

-- default materials and their IDs, we will always show 16 by default. 
-- @param uv: {width, height, offsetX, offsetY}, in block coordinates. Default value is {1,1,0,0}.
--  e.g. If width,height is 2, 2, then all textures will be tiled as 2*2 blocks. Floating point values are supported, like 1.25. 
--   offsetX, offsetY, can be an offset value, so that we can position the texture anywhere in the scene with floating point precision. 
--   However, UV rotation is not supported at the monent. 
-- @param color: base diffuse color
-- @param diffuseTex: diffuse texture, if empty, we will display as pure color. 
-- @param [internal value]metallic: internal value, default to 0. if this is bigger than 0.1, we will render with a normal map. 
-- @param specular: default to 0.  1 is fully reflective. 
-- @param normalTex: normal map, which share the same UV with the diffuse texture. If normal texture has alpha channel, then 
-- the alpha channel is used as roughness map. i.e. alpha==1 means no specular lighting, alpha==0 means fully reflective. 
-- the per-pixel roughness will be multipled by (1-specular)
local mDefaultMaterialList = {
	{id=1,  color="#ffffff", name="default1", uv = {2, 2, 0, 0}, diffuseTex="Texture/blocks/brick.png", EmissiveColor=nil},
	{id=2,  color="#aa0000", name="default2", diffuseTex=nil, EmissiveColor=nil, },
	{id=3,  color="#ff0000", name="default3", diffuseTex=nil, EmissiveColor=nil, },
	{id=4,  color="#ff5500", name="default4", diffuseTex=nil, EmissiveColor=nil, },
	{id=5,  color="#ffff00", name="default5", diffuseTex=nil, EmissiveColor=nil, },
	{id=6,  color="#00aa55", name="default6", diffuseTex=nil, EmissiveColor=nil, },
	{id=7,  color="#00aaff", name="default7", diffuseTex=nil, EmissiveColor=nil, },
	{id=8,  color="#aa55aa", name="default8", diffuseTex="Texture/blocks/brick.png", EmissiveColor=nil, },
	{id=9,  color="#aaaaaa", name="default9", uv = {6, 1, 0, 0}, diffuseTex="Texture/tileset/blocks/test_six.dds", EmissiveColor=nil, },
	{id=10, color="#aa5555", name="default10", diffuseTex=nil, EmissiveColor=nil, },
	{id=11, color="#ffaaff", name="default11", diffuseTex="Texture/blocks/clay.png", EmissiveColor=nil, },
	{id=12, color="#ffaa00", name="default12", diffuseTex=nil, EmissiveColor=nil, },
	{id=13, color="#ffffaa", name="default13", diffuseTex="Texture/blocks/1.png", metallic=0.5, normalTex="Texture/blocks/1_n.png", EmissiveColor=nil, },
	{id=14, color="#aaff00", name="default14", diffuseTex=nil, EmissiveColor=nil, },
	{id=15, color="#aaffff", name="default15", diffuseTex=nil, EmissiveColor=nil, },
	{id=16, color="#55aaaa", name="default16", diffuseTex=nil, EmissiveColor=nil, },
	{id=17, color="#aaffff", name="default15", diffuseTex=nil, EmissiveColor=nil, },
	{id=18, color="#55aaaa", name="default16", diffuseTex=nil, EmissiveColor=nil, },
}
local mMaterialList = nil;
local mMaterialMap = nil;

function BlockMaterialTask:ctor()
	BlockMaterialTask.LoadMaterials();
end

local page
function BlockMaterialTask.OnInit()
	page = document:GetPageCtrl();
end

function BlockMaterialTask:Run()
	self.finished = false;
	cur_instance = self;
	self:LoadSceneContext();
	self:GetSceneContext():setMouseTracking(true);
	self:GetSceneContext():setCaptureMouse(true);
	self:ShowPage();
end


function BlockMaterialTask:SetItemInHand(itemStack)
	self.itemInHand = itemStack;
end

function BlockMaterialTask:OnExit()
	BlockMaterialTask._super.OnExit(self);
	self:SetFinished();
	self:UnloadSceneContext();
	self:Destroy();
	cur_instance = nil;
	page = nil;
end

function BlockMaterialTask.GetInstance()
	return cur_instance;
end

function BlockMaterialTask.LoadMaterials(reload)
	if (mMaterialMap and not reload) then return end 
    -- print("=====================BlockMaterialTask.LoadMaterials======================");
	mMaterialList = {}
	mMaterialMap = {}
	for i = 1, #mDefaultMaterialList do
		local material = mDefaultMaterialList[i];
		mMaterialMap[material.id] = {
			ID = material.id,
			BaseColor = material.color,
			EmissiveColor = material.emissiveColor or "#00000000",
			MaterialName = material.name,
			Diffuse = material.diffuseTex,
			Normal = material.normalTex,
			Metallic = material.metallic,
			Specular = material.specular or 0.5,
			Roughness = material.roughness,
			MaterialUV = BlockMaterialEditor:Vector4ToString(material.uv),
		}
	end
	BlockMaterialEditor:LoadMaterials(mMaterialMap, reload);
	BlockMaterialTask.RefreshMaterials();
end

function BlockMaterialTask.RefreshMaterials(curMaterialID)
	BlockMaterialTask.LoadMaterials();
	local curID = curMaterialID or BlockMaterialTask.GetMaterialId();
	if (curID < 1) then curID = BlockMaterialEditor:GetCurrentMaterialID() end 
	local materials = BlockMaterialEditor:GetMaterialMap();
	local iStart = math.floor((curID - 1) / PageSize) * PageSize;
	for i = 1, PageSize do
		local ID = iStart + i;
		local material = materials[ID];
		if (material) then
			mMaterialList[i] = mMaterialList[i] or {id = ID};
			mMaterialList[i].id = material.ID;
			mMaterialList[i].name = material.MaterialName;
			mMaterialList[i].color = material.BaseColor;
			mMaterialList[i].emissiveColor = material.EmissiveColor;
			mMaterialList[i].diffuseTex = material.Diffuse ~= "" and material.Diffuse or nil;
			mMaterialList[i].normalTex = material.Normal ~= "" and material.Normal or nil;
			mMaterialList[i].metallic = material.Metallic;
			mMaterialList[i].specular = material.Specular;
			mMaterialList[i].roughness = material.Roughness;
			mMaterialList[i].uv = BlockMaterialEditor:StringToVector4(material.MaterialUV);
			mMaterialList[i].diffuseTexPath = material.DiffuseFullPath ~= "" and material.DiffuseFullPath or nil;
			mMaterialList[i].normalTexPath = material.NormalFullPath ~= "" and material.NormalFullPath or nil;
			mMaterialMap[mMaterialList[i].id] = mMaterialList[i];
			-- print ("=========", curID, ID, material.ID, material.MaterialName, material.BaseColor, material.Diffuse)
		else
			mMaterialList[i] = nil;
		end
	end
	BlockMaterialTask.Refresh();
end

function BlockMaterialTask.GetMaterials()
	return mMaterialList;
end

function BlockMaterialTask.GetPageInfo()
	local nTotalCount = #(BlockMaterialEditor:GetMaterialList());
	local nPageCount = math.ceil(nTotalCount / PageSize);
	local nID = BlockMaterialTask.GetMaterialId();
	nID = nID < 1 and BlockMaterialEditor:GetCurrentMaterialID() or nID;
	local nCurPage = math.ceil(nID / PageSize);
	return string.format("%d/%d", nCurPage, nPageCount);
end

function BlockMaterialTask:ShowPage()
	NPL.load("(gl)script/ide/System/Scene/Viewports/ViewportManager.lua");
	local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");
	local viewport = ViewportManager:GetSceneViewport();
	local parent = viewport:GetUIObject(true)
	local window = self:CreateGetToolWindow();

	window:Show({
		name="BlockMaterialTask", 
		url="script/apps/Aries/Creator/Game/Tasks/BlockMaterial/BlockMaterialTask.html",
		alignment="_ctb", left=0, top= -55, width = 350, height = 64, parent = parent,
	});
end

function BlockMaterialTask.GetMaterialId()
	local self = BlockMaterialTask.GetInstance();
	if(self and self.itemInHand) then
		return self.itemInHand:GetDataField("materialId") or 0;
	end
	return 0;
end

function BlockMaterialTask:GetCurrentMaterial()
	if(self and self.itemInHand) then
		local matId = self.itemInHand:GetDataField("materialId") or 0;
		return mMaterialMap[matId];
	end
end

function BlockMaterialTask.OnClickAddMaterial()
	BlockMaterialEditor:ShowMaterialListPage(function()
		BlockMaterialTask.RefreshMaterials();
	end)
end

function BlockMaterialTask.OnClickEditMaterial()
	local matId = BlockMaterialTask.GetMaterialId()
	BlockMaterialEditor:Show(matId, function()
		BlockMaterialTask.RefreshMaterials();
	end);
end

function BlockMaterialTask:UpdateManipulators()
	self:DeleteManipulators();
	self.paintMaterialManip = nil;
	-- TODO: we may support advanced painting UI with manipulator in future
end

function BlockMaterialTask:Redo()
end

function BlockMaterialTask:Undo()
end

function BlockMaterialTask:handleLeftClickScene(event, result)
	local result = result or Game.SelectionManager:MousePickBlock(true, false, false);
	if(not event:IsCtrlKeysPressed()) then
		-- left click to remove material from block's surface
		if(result.blockX and result.side) then
			local task = MyCompany.Aries.Game.Tasks.CreateBlockMaterialTask:new({blockX = result.blockX,blockY = result.blockY, blockZ = result.blockZ, 
				materialId = -1, side = result.side, nohistory=false})
			task:Run();
		end
		event:accept();
	elseif(event.alt_pressed) then
		-- alt key to pick
		local last_material_id = BlockEngine:GetBlockExternalMaterial(result.blockX,result.blockY,result.blockZ, result.side);
		if(last_material_id and last_material_id > 0) then
			self:SelectMaterialById(last_material_id)
			event:accept();
		end
	elseif(event.ctrl_pressed) then
		-- Ctrl + left click to select block
		if(result.block_id) then
			local task = SelectBlocks:new({blockX = result.blockX,blockY = result.blockY, blockZ = result.blockZ})
			task:Run();
			task:Connect("selectionCanceled", function()
				if(cur_instance) then
					cur_instance:LoadSceneContext();
				end
			end)
			task:Connect("sceneRightClicked", self, self.OnRightClickOnSelection)
			if(event.shift_pressed) then
				task:RefreshImediately();
				-- Ctrl + shift + left click to select all connected blocks
				task.SelectAll(true);
			end
			event:accept();
		end
	elseif(event.shift_pressed) then
		local result = result or Game.SelectionManager:MousePickBlock(true, false, false);
		if(result.blockX and result.side) then
			self:BatchApplyCoplanarMaterials(result.blockX, result.blockY, result.blockZ, result.side, -1);
		end
		event:accept();
	end
end

function BlockMaterialTask:BatchApplyCoplanarMaterials(blockX, blockY, blockZ, side, materialId)
	if(blockX and side and materialId) then
		local blockBlockId = BlockEngine:GetBlockId(blockX, blockY, blockZ)
		local centerMaterialId = BlockEngine:GetBlockExternalMaterial(blockX, blockY, blockZ, side);
		local blocks = {};
		local blockMap = {};
		local function TryAddBlock(x, y, z)
			local blockTemplate = BlockEngine:GetBlock(x,y,z)
			if(blockTemplate and blockTemplate.cubeMode and blockTemplate.id == blockBlockId) then
				local dx, dy, dz = Direction.GetOffsetBySide(side)
				local blockTemplate = BlockEngine:GetBlock(x + dx, y + dy, z + dz)
				if(not blockTemplate) then
					local last_material_id = BlockEngine:GetBlockExternalMaterial(x, y, z, side);
					if(last_material_id == materialId or last_material_id == centerMaterialId) then
						blocks[#blocks+1] = {x,y,z, side, materialId}
						return true
					end
				end
			end
		end

		-- recursive function to run like water flooding nearby blocks. 
		local function Flood_(x, y, z, radius)
			local index = BlockEngine:GetSparseIndex(x, y, z)
			local bFloodNearbyBlocks;
			local lastRadius = blockMap[index]
			if(lastRadius and lastRadius >= 0  and lastRadius < radius) then
				bFloodNearbyBlocks = true
			end

			if(not lastRadius) then
				if(TryAddBlock(x, y, z)) then
					bFloodNearbyBlocks = true;
				else
					blockMap[index] = -1;
				end
			end
			
			if(bFloodNearbyBlocks) then
				blockMap[index] = radius;
				local nextRadius = radius - 1;
				if(nextRadius >= 0) then
					if(side == 0 or side == 1) then
						Flood_(x, y+1, z, nextRadius)
						Flood_(x, y-1, z, nextRadius)
						Flood_(x, y, z+1, nextRadius)
						Flood_(x, y, z-1, nextRadius)
					elseif(side == 2 or side == 3) then
						Flood_(x, y+1, z, nextRadius)
						Flood_(x, y-1, z, nextRadius)
						Flood_(x+1, y, z, nextRadius)
						Flood_(x-1, y, z, nextRadius)
					else -- if(side == 4 or side == 5) then
						Flood_(x, y, z+1, nextRadius)
						Flood_(x, y, z-1, nextRadius)
						Flood_(x+1, y, z, nextRadius)
						Flood_(x-1, y, z, nextRadius)
					end
				end
			end
		end

		Flood_(blockX, blockY, blockZ, self.maxFloodRadius);
		
		if(#blocks > 0) then
			local task = MyCompany.Aries.Game.Tasks.CreateBlockMaterialTask:new({blocks = blocks,
					materialId = materialId, nohistory=false})
			task:Run();
		end
	end
end


function BlockMaterialTask:mousePressEvent(event)
end

function BlockMaterialTask:mouseReleaseEvent(event)
	if(event:isClick()) then
		if(not event:IsCtrlKeysPressed()) then
			-- right click to paint material, left click to clear entity's material
			local mat = self:GetCurrentMaterial();
			local materialId = mat and mat.id or -1;
			if(event:button() == "left") then
				materialId = -1
			end
			local result = Game.SelectionManager:MousePickBlock(true, true, true);
			local entity = result.entity;
			if(not entity and result.blockX and result.block_id) then
				entity = GameLogic.EntityManager.GetBlockEntity(result.blockX, result.blockY, result.blockZ)
			end
			if(entity) then
				-- currently only bmax model support material id, in future all models should support it. 
				local filename = entity:GetModelFile()
				if(filename and filename:match("%.bmax$")) then
					entity:SetMaterialId(materialId)
				end
				event:accept();
			end
		end
		if(not event:isAccepted()) then
			local result = self:GetSceneContext():CheckMousePick();
			if(event.mouse_button == "left") then
				self:handleLeftClickScene(event, result)
			elseif(event.mouse_button == "right") then
				self:handleRightClickScene(event, result);
			end
		end
	end
end

function BlockMaterialTask:handleRightClickScene(event, result)
	local mat = self:GetCurrentMaterial();
	local materialId = mat and mat.id or -1;
	if(not event:IsCtrlKeysPressed()) then
		-- right click to paint material on block's surface
		local result = result or Game.SelectionManager:MousePickBlock(true, false, false);
		if(result.blockX and result.side and result.block_id) then
			local task = MyCompany.Aries.Game.Tasks.CreateBlockMaterialTask:new({blockX = result.blockX,blockY = result.blockY, blockZ = result.blockZ, 
				materialId = materialId, side = result.side, nohistory=false})
			task:Run();
		end
		event:accept();

	elseif(event.shift_pressed) then
		local result = result or Game.SelectionManager:MousePickBlock(true, false, false);
		if(result.blockX and result.side) then
			self:BatchApplyCoplanarMaterials(result.blockX, result.blockY, result.blockZ, result.side, materialId);
		end
		event:accept();
	end
end

function BlockMaterialTask:mouseMoveEvent(event)
	self:GetSceneContext():mouseMoveEvent(event);
end

function BlockMaterialTask:mouseWheelEvent(event)
	self:GetSceneContext():mouseWheelEvent(event);
end

function BlockMaterialTask:keyPressEvent(event)
	local dik_key = event.keyname;
	if(dik_key == "DIK_Z")then
		UndoManager.Undo();
	elseif(dik_key == "DIK_Y")then
		UndoManager.Redo();
	end
	self:GetSceneContext():keyPressEvent(event);
end

function BlockMaterialTask:SelectMaterialById(matId)
	BlockMaterialEditor:SetCurrentMaterialID(matId);
	if(self.itemInHand) then
		local mat = mMaterialMap[matId] or {};
		self.itemInHand:SetDataField("materialId", matId);
		self.itemInHand:SetDataField("name", mat.name);
		self.itemInHand:SetDataField("uv", mat.uv);
		self.itemInHand:SetDataField("color", mat.color);
		self.itemInHand:SetDataField("diffuseTex", mat.diffuseTex);
		self.itemInHand:SetDataField("metallic", mat.metallic);
		self.itemInHand:SetDataField("specular", mat.specular);
		self.itemInHand:SetDataField("roughness", mat.roughness);
		self.itemInHand:SetDataField("normalTex", mat.normalTex);
		self.itemInHand:SetDataField("emissiveColor", mat.emissiveColor);
	end
	if(page) then
		page:Refresh(0.01)
	end
end

function BlockMaterialTask.OnClickMaterial(name)
	local matId = tonumber(name) or -1
	-- 相同取消选择
	if(BlockMaterialTask.GetMaterialId() == matId) then matId = -1 end
	BlockMaterialTask.SetCurrentMaterialId(matId)
end

function BlockMaterialTask.GetPageId(materialId)
	local material = mMaterialMap[materialId or 1];
	materialId = material and material.id or 1;
	return math.floor((materialId - 1) / PageSize);
end

function BlockMaterialTask.SetCurrentMaterialId(matId)
	local self = BlockMaterialTask.GetInstance()
	local curMaterialId = BlockMaterialEditor:GetCurrentMaterialID();
	matId = matId or BlockMaterialTask.GetMaterialId();

	if (matId == 0 or not self) then return end 
	if (matId ~=-1 and BlockMaterialTask.GetPageId(matId) ~= BlockMaterialTask.GetPageId(curMaterialId)) then
		BlockMaterialTask.RefreshMaterials(matId);
	end
	self:SelectMaterialById(matId);
end

function BlockMaterialTask.Refresh()
	local instance = BlockMaterialTask.GetInstance();
	if (instance and instance.window and page) then 
		page:Refresh(0.01)
	end
	BlockMaterialTask.SetCurrentMaterialId(BlockMaterialTask.GetMaterialId())
end

-- usually called when user click the icon when some blocks are selected in the scene. 
function BlockMaterialTask:PaintSelection()
	local selected_blocks = GameLogic.SelectionManager:GetSelectedBlocks();
	if(selected_blocks) then
		-- TODO: 
	end
end

-- called when some blocks are selected, and user right click on the scene
function BlockMaterialTask:OnRightClickOnSelection(event)
	local curSelectTask = SelectBlocks.GetCurrentInstance()
	local selected_blocks = GameLogic.SelectionManager:GetSelectedBlocks();
	if(selected_blocks and curSelectTask) then
		local result = Game.SelectionManager:MousePickBlock(true, false, false);
		if(result.blockX and result.side) then
			if(curSelectTask:IsBlockSelected(result.blockX, result.blockY, result.blockZ)) then
				local mat = self:GetCurrentMaterial();
				local blocks = {};
				local side = result.side;
				local materialId = mat and mat.id or -1;
				local bx, by, bz = result.blockX, result.blockY, result.blockZ
				if(side == 0 or side == 1) then
					for _, b in pairs(selected_blocks) do
						if(bx == b[1]) then
							blocks[#blocks + 1] = {b[1], b[2], b[3], side, materialId}
						end
					end
				elseif(side == 2 or side == 3) then
					for _, b in pairs(selected_blocks) do
						if(bz == b[3]) then
							blocks[#blocks + 1] = {b[1], b[2], b[3], side, materialId}
						end
					end
				else -- if(side == 4 or side == 5) then
					for _, b in pairs(selected_blocks) do
						if(by == b[2]) then
							blocks[#blocks + 1] = {b[1], b[2], b[3], side, materialId}
						end
					end
				end
				local task = MyCompany.Aries.Game.Tasks.CreateBlockMaterialTask:new({blocks = blocks, nohistory=false})
				task:Run();

				event:accept();
			else
				self:handleRightClickScene(event, result)	
			end
			return true;
		end
	end
end