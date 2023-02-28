--[[
Title: ItemMaterial
Author(s): wxa
Date: 2014/1/20
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemMaterial.lua");
local ItemMaterial = commonlib.gettable("MyCompany.Aries.Game.Items.ItemMaterial");
local item_ = ItemMaterial:new({icon,});
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/math/vector.lua");
NPL.load("(gl)script/ide/System/Core/Color.lua");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local Color = commonlib.gettable("System.Core.Color");
local Player = commonlib.gettable("MyCompany.Aries.Player");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local ItemMaterial = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Items.ItemToolBase"), commonlib.gettable("MyCompany.Aries.Game.Items.ItemMaterial"));

block_types.RegisterItemClass("ItemMaterial", ItemMaterial);

-- @param template: icon
-- @param radius: the half radius of the object. 
function ItemMaterial:ctor()
	self.m_bIsOwnerDrawIcon = true;
end

function ItemMaterial:OnSelect(itemStack)
    ItemMaterial._super.OnSelect(self, itemStack);
end

function ItemMaterial:CreateTask(itemStack)
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BlockMaterial/BlockMaterialTask.lua");
	local BlockMaterialTask = commonlib.gettable("MyCompany.Aries.Game.Tasks.BlockMaterialTask");
	local task = BlockMaterialTask:new();
	task:SetItemInHand(itemStack)
    return task;
end

function ItemMaterial:GetTextureDiskFilePath(filename)
    if (not filename or filename == "") then return "" end 
	local filepath = Files.GetFilePath(commonlib.Encoding.Utf8ToDefault(filename));
    return filepath == "" and filename or filepath;
end


function ItemMaterial:Vector4ToColor(v)
    v = v or {};
    return Color.RGBAfloat_TO_ColorStr(v[1] or 1.0, v[2] or 1.0, v[3] or 1.0, v[4] or 1.0);
end

function ItemMaterial:ColorToVector4(color, defaultValue)
    local r, g, b, a = Color.ColorStr_TO_RGBAfloat(color or defaultValue or "#ffffffff");
    return {r, g, b, a or 1.0};
end

function ItemMaterial:Color4ToColor3(color)
    local size = string.len("#ffffffff")
    color = color or "#ffffffff";
    return string.len(color) == size and (string.sub(color , 1, size - 2)) or color;
end

function ItemMaterial:Color3ToColor4(color, alpha)
    if (type(alpha) == "number") then
        alpha = alpha > 255 and 255 or alpha;
        alpha = alpha < 0 and 0 or alpha;
        alpha = string.format("%02X", alpha);
    end
    local size = string.len("#ffffff")
    color = color or "#ffffff"
    return string.len(color) == size and (color .. (alpha or "ff")) or color;
end

function ItemMaterial:SetMaterialIdToItemStack(itemStack, matId)
	if(itemStack and matId) then
		itemStack:SetDataField("materialId", matId);

		local material = ParaAsset.GetBlockMaterial(matId);
		local attr = material:GetAttributeObject();
		if (attr:IsValid()) then 
			itemStack:SetDataField("name", attr:GetField("MaterialName"));
			itemStack:SetDataField("color", self:Color4ToColor3(self:Vector4ToColor(attr:GetField("BaseColor"))));
			itemStack:SetDataField("diffuseTex", attr:GetField("Diffuse"));
		end
	end
end

-- virtual: draw icon with given size at current position (0,0)
-- @param width, height: size of the icon
-- @param itemStack: this may be nil. or itemStack instance. 
function ItemMaterial:DrawIcon(painter, width, height, itemStack)
	if(itemStack) then
		local matId = itemStack:GetDataField("materialId") or -1;
		local matColor = itemStack:GetDataField("color") or "#000000";
		local diffuseTex = itemStack:GetDataField("diffuseTex")
		if(itemStack._tmpDiffuseTex ~= diffuseTex) then
			itemStack._tmpDiffuseTex = diffuseTex;
			itemStack._tmpDiffuseTexDiskPath = self:GetTextureDiskFilePath(diffuseTex)
		end
		diffuseTex = self:GetTextureDiskFilePath(itemStack._tmpDiffuseTexDiskPath or diffuseTex);
		if(matId > 0) then
			painter:SetPen(Color.ChangeOpacity(matColor));
			if(diffuseTex and diffuseTex~="") then
				painter:DrawRectTexture(0, 0, width, height, diffuseTex);
			else
				painter:DrawRect(0,0,width, height);
			end
			painter:SetPen("#ffffff");	
			painter:DrawRectTexture(5, 5, width-10, height-10, self:GetIcon());

			-- draw material Id at the corner: no clipping, right aligned, single line
			painter:SetPen("#000000");	
			painter:DrawText(0, height-15+1, width, 15, tostring(matId), 0x122);
			painter:SetPen("#ffffff");	
			painter:DrawText(0, height-15, width-1, 15, tostring(matId), 0x122);

		elseif(matId == 0) then
			painter:SetPen(Color.ChangeOpacity("#cccccc"));
			painter:DrawRect(0,0,width, height);
			painter:SetPen("#ffffff");	
			painter:DrawRectTexture(0, 0, width, height, self:GetIcon());
			painter:DrawText(0, height-15, width-1, 15, "Air", 0x122);
		elseif(matId == -1) then
			painter:SetPen(Color.ChangeOpacity("#000000"));
			painter:DrawRect(0,0,width, height);
			painter:SetPen("#ffffff");	
			painter:DrawRectTexture(0, 0, width, height, self:GetIcon());
			painter:DrawText(0, height-15, width-1, 15, "X", 0x122);
		end
	else
		ItemMaterial._super.DrawIcon(self, painter, width, height, itemStack)
	end
end

-- called whenever this item is clicked on the user interface when it is holding in hand of a given player (current player). 
-- by default, if there is selected blocks, we will replace selection with current block in hand. 
function ItemMaterial:OnClickInHand(itemStack, entityPlayer)
	if(GameLogic.GameMode:IsEditor() and entityPlayer == EntityManager.GetPlayer()) then
		if(self:GetTask()) then
			self:GetTask():PaintSelection();
		end
	end
end
