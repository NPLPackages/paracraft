--[[
Title: ItemBlockModel
Author(s): LiXizhi
Date: 2015/5/5
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemBlockModel.lua");
local ItemBlockModel = commonlib.gettable("MyCompany.Aries.Game.Items.ItemBlockModel");
local item = ItemBlockModel:new({icon,});
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemToolBase.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local ItemStack = commonlib.gettable("MyCompany.Aries.Game.Items.ItemStack");

local ItemBlockModel = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Items.ItemToolBase"), commonlib.gettable("MyCompany.Aries.Game.Items.ItemBlockModel"));

block_types.RegisterItemClass("ItemBlockModel", ItemBlockModel);

local default_inhand_offset = {0.15, 0.3, 0}

-- @param template: icon
-- @param radius: the half radius of the object. 
function ItemBlockModel:ctor()
	self:SetOwnerDrawIcon(true);
end

-- we will use C++ polygon-level physics engine for real physics. 
function ItemBlockModel:HasRealPhysics()
	local block_template = self:GetBlock();
	if(block_template) then
		return not block_template.obstruction;
	end
end

-- item offset when hold in hand. 
-- @return nil or {x,y,z}
function ItemBlockModel:GetItemModelInHandOffset()
	return self.inhandOffset or default_inhand_offset;
end

-- whether filename is a block template file. 
function ItemBlockModel:IsBlockTemplate(filename)
	return filename and filename:match("%.blocks%.xml$") and true;
end

-- load the model as block templates into the world.
-- @param filename: if nil, the current file is used. 
function ItemBlockModel:UnpackIntoWorld(itemStack, filename)
	if(not filename) then
		local local_filename = itemStack:GetDataField("tooltip");
		filename = local_filename;
	end
	if(filename) then
		filename = Files.FindFile(commonlib.Encoding.Utf8ToDefault(filename));
	end
	if(filename) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/BlockTemplatePage.lua");
		local BlockTemplatePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.BlockTemplatePage");
		BlockTemplatePage.CreateFromTemplate(filename);
	end
end

-- virtual function: try to get block entity data from itemStack. 
-- in most cases, this return nil
-- @return nil or an xml table
function ItemBlockModel:GetBlockEntityData(itemStack)
	local local_filename = itemStack:GetDataField("tooltip");
	if(local_filename and local_filename ~= "") then
		local xml_data = {attr = {filename = local_filename} };
		return xml_data
	end
end

function ItemBlockModel:TryCreate(itemStack, entityPlayer, x,y,z, side, data, side_region)
	local local_filename = itemStack:GetDataField("tooltip");
	local filename = local_filename;
	if(filename) then
		filename = Files.FindFile(commonlib.Encoding.Utf8ToDefault(filename));
		if(filename) then
			filename = commonlib.Encoding.DefaultToUtf8(filename);
		end
	end
	if(not filename) then
		self:OpenChangeFileDialog(itemStack);
		return;
	end

	if(self:IsBlockTemplate(filename)) then
		self:UnpackIntoWorld(itemStack, filename);
		return;
	end

	if (itemStack and itemStack.count == 0) then
		return;
	elseif (entityPlayer and not entityPlayer:CanPlayerEdit(x,y,z, data, itemStack)) then
		return;
	elseif (self:CanPlaceOnSide(x,y,z,side, data, side_region, entityPlayer, itemStack)) then
		local x_, y_, z_ = BlockEngine:GetBlockIndexBySide(x,y,z,BlockEngine:GetOppositeSide(side));
		local last_block_id = BlockEngine:GetBlockId(x_, y_, z_);
		local block_id = self.block_id;

		local block_template = block_types.get(block_id);
		if(block_template) then
			data = data or block_template:GetMetaDataFromEnv(x, y, z, side, side_region);
			
			local xml_data = {attr = {filename = local_filename} };
			if(BlockEngine:SetBlock(x, y, z, block_id, data, 3, xml_data)) then
				block_template:play_create_sound();

				block_template:OnBlockPlacedBy(x,y,z, entityPlayer);
				if(itemStack) then
					itemStack.count = itemStack.count - 1;
				end
			end
			return true;
		end
	end
end

function ItemBlockModel:PickItemFromPosition(x,y,z)
	local entity = self:GetBlock():GetBlockEntity(x,y,z);
	if(entity) then
		if(entity.GetModelFile) then
			local filename = entity:GetModelFile();
			if(filename) then
				local itemStack = ItemStack:new():Init(self.id, 1);
				-- transfer filename from entity to item stack. 
				itemStack:SetTooltip(filename);
				return itemStack;
			end
		end
	end
end

-- return true if items are the same. 
-- @param left, right: type of ItemStack or nil. 
function ItemBlockModel:CompareItems(left, right)
	if(ItemBlockModel._super.CompareItems(self, left, right)) then
		if(left and right and left:GetTooltip() == right:GetTooltip()) then
			return true;
		end
	end
end

function ItemBlockModel:OpenChangeFileDialog(itemStack)
	if(itemStack) then
		local local_filename = itemStack:GetDataField("tooltip");
		local_filename = commonlib.Encoding.Utf8ToDefault(local_filename)
		NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/OpenAssetFileDialog.lua");
		local OpenAssetFileDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.OpenAssetFileDialog");
		OpenAssetFileDialog.ShowPage(L"请输入bmax, x或fbx文件的相对路径, <br/>你也可以随时将外部文件拖入窗口中", function(result)
			if(result and result~="" and result~=local_filename) then
				result = commonlib.Encoding.DefaultToUtf8(result)
				self:SetModelFileName(itemStack, result);
			end
		end, local_filename, L"选择模型文件", "model", nil, function(filename)
			self:UnpackIntoWorld(itemStack, filename);
		end)
	end
end

-- called whenever this item is clicked on the user interface when it is holding in hand of a given player (current player). 
function ItemBlockModel:OnClickInHand(itemStack, entityPlayer)
	-- if there is selected blocks, we will replace selection with current block in hand. 
	if(GameLogic.GameMode:IsEditor() and entityPlayer == EntityManager.GetPlayer()) then
		self:SelectModelFile(itemStack);
	end
end

function ItemBlockModel:SelectModelFile(itemStack)
	local selected_blocks = Game.SelectionManager:GetSelectedBlocks();
	if(selected_blocks and itemStack) then
		-- Save template:
		local last_filename = itemStack:GetDataField("tooltip");
		NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/OpenFileDialog.lua");
		local OpenFileDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.OpenFileDialog");
		OpenFileDialog.ShowPage(L"将当前选择的方块保存为bmax文件. 请输入文件名:<br/> 例如: test", function(result)
			if(result and result~="") then
				result = commonlib.Encoding.DefaultToUtf8(result)
				local filename = result;
				local bSucceed, filename = GameLogic.RunCommand("/savemodel "..filename);
				if(filename) then
					self:SetModelFileName(itemStack, filename);
				end
			end
		end, last_filename, L"选择模型文件", "model");
	else
		self:OpenChangeFileDialog(itemStack);
	end
end

-- virtual function: when selected in right hand
function ItemBlockModel:OnSelect(itemStack)
	ItemBlockModel._super.OnSelect(self, itemStack);
	GameLogic.SetStatus(L"Ctrl+左键选择方块与骨骼, 左键点击物品图标保存模型");
end

function ItemBlockModel:OnDeSelect()
	ItemBlockModel._super.OnDeSelect(self);
	GameLogic.SetStatus(nil);
end


function ItemBlockModel:GetModelFileName(itemStack)
	return itemStack and itemStack:GetDataField("tooltip");
end

function ItemBlockModel:SetModelFileName(itemStack, filename)
	if(itemStack) then
		itemStack:SetDataField("tooltip", filename);
		local task = self:GetTask();
		if(task) then
			task:SetItemInHand(itemStack);
			task:RefreshPage();
		end
	end
end

-- virtual: draw icon with given size at current position (0,0)
-- @param width, height: size of the icon
-- @param itemStack: this may be nil. or itemStack instance. 
function ItemBlockModel:DrawIcon(painter, width, height, itemStack)
	ItemBlockModel._super.DrawIcon(self, painter, width, height, itemStack);
	local filename = self:GetModelFileName(itemStack);
	if(filename and filename~="") then
		filename = filename:match("[^/]+$"):gsub("%..*$", "");
		filename = filename:sub(1, 6);
		painter:SetPen("#33333380");
		painter:DrawRect(0,0, width, 14);
		painter:SetPen("#ffffff");
		painter:DrawText(1,0, filename);
	end
end

-- virtual function: 
function ItemBlockModel:CreateTask(itemStack)
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EditModel/EditModelTask.lua");
	local EditModelTask = commonlib.gettable("MyCompany.Aries.Game.Tasks.EditModelTask");
	EditModelTask:SetItemInHand(itemStack)
	return EditModelTask:new();
end