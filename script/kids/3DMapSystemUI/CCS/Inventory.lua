--[[
Title: Character Customization System inventory UI for 3D Map System
Author(s): WangTian
Date: 2007/10/29
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemUI/CCS/Inventory.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/kids/3DMapSystemUI/CCS/DB.lua");
local DB = Map3DSystem.UI.CCS.DB

NPL.load("(gl)script/kids/3DMapSystemUI/CCS/InventorySlot.lua");
local InventorySlot = Map3DSystem.UI.CCS.InventorySlot

local Inventory = commonlib.gettable("Map3DSystem.UI.CCS.Inventory");

-- create, init and display the head inventory UI control
--@param parent: ParaUIObject which is the parent container
function Inventory.Show(parent)
	local _this,_parent;
	
	_this = ParaUI.GetUIObject("CCS_UI_Inventory_Head_container");
	
	if(_this:IsValid() == true) then
		ParaUI.Destroy("CCS_UI_Inventory_Head_container");
	end
	
	-- CCS_UI_Inventory_Head_container
	_this = ParaUI.CreateUIObject("container", "CCS_UI_Inventory_Head_container", "_fi", 0, 0, 0, 0);
	_this.background = "";
	if(parent == nil) then
		_this:AttachToRoot();
	else
		parent:AddChild(_this);
	end
	
	_parent = _this;
	
	
	_this = ParaUI.CreateUIObject("container", "CCS_Head_IconMatrix_Container", "_fi", 0, 47, 0, 0);
	_this.background = "";
	_parent:AddChild(_this);



	_this = ParaUI.CreateUIObject("button", "btnPageLeft", "_lt", 0, 20, 32, 32);
	--_this.text = "<-";
	_this.animstyle = 11;
	_this.tooltip = "向左翻页";
	_this.onclick = ";Map3DSystem.UI.CCS.Inventory.PageLeft();";
	_this.background = "Texture/kidui/CCS/btn_CCS_CF_Page_Left.png";
	_parent:AddChild(_this);
	
	_this = ParaUI.CreateUIObject("button", "btnPageRight", "_lt", 0, 100, 32, 32);
	--_this.text = "->";
	_this.animstyle = 11;
	_this.tooltip = "向右翻页";
	_this.onclick = ";Map3DSystem.UI.CCS.Inventory.PageRight();";
	_this.background = "Texture/kidui/CCS/btn_CCS_CF_Page_Right.png";
	_parent:AddChild(_this);

	_this = ParaUI.CreateUIObject("text", "labelPage", "_lt", 0, 70, 40, 16);
	_this.text = "0/0";
	_parent:AddChild(_this);
	
	
	_this = ParaUI.CreateUIObject("button", "btnUnmount", "_rt", -25, 100, 32, 32);
	--_this.text = "Unmount";
	_this.animstyle = 11;
	_this.tooltip = "脱掉装备";
	_this.background = "Texture/kidui/CCS/btn_BCS_Reset.png";
	_this.onclick = ";Map3DSystem.UI.CCS.Inventory.OnClickUnmountCurrentCharacterSlot();";
	_parent:AddChild(_this);
	
	-- get the Inventory items according to the current inventory slot
	local slotInventory = InventorySlot.GetInventorySlot();
	Inventory.Items = DB.GetItemIdListBySlotType(InventorySlot.Component);
	
	local nCount = table.getn(Inventory.Items);
	
	Inventory.TotalIcons = nCount;
	Inventory.iconsPerPage = 8;
	
	Inventory.totalPage = math.ceil(nCount / Inventory.iconsPerPage);
	
	if(nCount == 0) then
		Inventory.totalPage = 1;
	end
	
	-- flip to the first page
	Inventory.currentPage = 1;
	Inventory.PageLeft();
	
end -- function Inventory.Show(parent)


-- destroy the control
function Inventory.OnDestroy()
	ParaUI.Destroy("CCS_UI_Inventory_Head_container");
end

-- Page Left
function Inventory.PageLeft()
	
	if(Inventory.currentPage > 0) then
	
		Inventory.currentPage = Inventory.currentPage - 1;
		Inventory.RefreshMatrix3D();
	end
end

-- Page Right
function Inventory.PageRight()
	
	if(Inventory.currentPage < (Inventory.totalPage - 1) ) then
		
		Inventory.currentPage = Inventory.currentPage + 1;
		Inventory.RefreshMatrix3D();
	end
end

function Inventory.DrawCCSItemCellHandler(_parent, cell)
	-- simply attach a drawing board on the position
	local scene = cell.GridView3D:GetMiniSceneGraph();
	--scene:RemoveObject(obj);
	
	if(cell ~= nil) then
		local _this = ParaUI.CreateUIObject("button", cell.text, "_fi", 2, 2, 2, 2);
		_this.background = "";
		_this.onclick = ";Map3DSystem.UI.CCS.Inventory.OnClickIconMatrix("..cell.column..", "..cell.row..");";
		_this.onmouseenter = ";Map3DSystem.UI.CCS.Inventory.OnEnterIconMatrix(\""..cell.GridView3D.name.."\", "..cell.column..", "..cell.row..");";
		_this.onmouseleave = ";Map3DSystem.UI.CCS.Inventory.OnLeaveIconMatrix(\""..cell.GridView3D.name.."\", "..cell.column..", "..cell.row..");";
		--_this.tooltip = cell.tooltip;
		_parent:AddChild(_this);
	end
	
	local model, skin;
	model = cell.model;
	skin = cell.skin;
	
	local _asset = ParaAsset.LoadStaticMesh("", model);
	local obj = ParaScene.CreateMeshPhysicsObject(cell.column.."-"..cell.row, _asset, 1,1,1, false, "1,0,0,0,1,0,0,0,1,0,0,0");
	if(obj:IsValid()) then
		obj:SetFacing(1.57);
		obj:GetAttributeObject():SetField("progress", 1);
		
		local aabb = {};
		_asset:GetBoundingBox(aabb);
		local dx = math.abs(aabb.max_x - aabb.min_x);
		local dy = math.abs(aabb.max_y - aabb.min_y);
		local dz = math.abs(aabb.max_z - aabb.min_z);
		
		local max = math.max(dx, dy);
		max = math.max(max, dz);
		obj:SetScale(6.4/max);
		
		local offsetX = -(aabb.max_x + aabb.min_x) * 5;
		local offsetY = -(aabb.max_y + aabb.min_y) * 5;
		
		obj:SetPosition(cell.logicalX + offsetX, cell.logicalY + offsetY, 0);
		--obj:SetPosition(3.2, -6.4, 0);
		local att = obj:GetAttributeObject();
		att:SetField("render_tech", 9);
		
		scene:AddChild(obj);
		
		--local _Head = "character/v3/Item/TextureComponents/TorsoLowerTexture/MomoMale05_he_TL_U.DDS"
		
		--local _texName;
		--
		--if(cell.type == DB.CS_HEAD) then
			--_texName = "character/v3/Item/ObjectComponents/Head/"..skin;
		--elseif(cell.type == DB.CS_SHOULDER) then
			--_texName = "character/v3/Item/ObjectComponents/Shoulder/"..skin;
		--elseif(cell.type == DB.CS_HAND_RIGHT
			--or cell.type == DB.CS_HAND_LEFT) then
			--_texName = "character/v3/Item/ObjectComponents/Weapon/"..skin;
		--elseif(cell.type == DB.CS_CAPE) then
			---- TODO: unisex unirace cape model
			--_texName = "character/v3/Item/ObjectComponents/Cape/"..skin;
		--end
		--
		--local _texture = ParaAsset.LoadTexture("", _texName, 1);
		--obj:SetReplaceableTexture(0, _texture);
		
		if(InventorySlot.Component == DB.CS_BOOTS) then
			local _texture = ParaAsset.LoadTexture("", skin, 1);
			obj:SetReplaceableTexture(2, _texture);
		elseif(InventorySlot.Component == DB.CS_GLOVES) then
			local _texture = ParaAsset.LoadTexture("", skin, 1);
			obj:SetReplaceableTexture(2, _texture);
		elseif(InventorySlot.Component == DB.CS_PANTS) then
			local _texture = ParaAsset.LoadTexture("", cell.skinLU, 1);
			obj:SetReplaceableTexture(1, _texture);
			local _texture = ParaAsset.LoadTexture("", cell.skinLL, 1);
			obj:SetReplaceableTexture(2, _texture);
		elseif(InventorySlot.Component == DB.CS_SHIRT) then
			if(cell.geoSet == 2 or cell.geoSet == 5) then
				local _texture = ParaAsset.LoadTexture("", cell.skinTU, 1);
				obj:SetReplaceableTexture(1, _texture);
				local _texture = ParaAsset.LoadTexture("", cell.skinTL, 1);
				obj:SetReplaceableTexture(2, _texture);
				local _texture = ParaAsset.LoadTexture("", cell.skinAU, 1);
				obj:SetReplaceableTexture(3, _texture);
				local _texture = ParaAsset.LoadTexture("", cell.skinAL, 1);
				obj:SetReplaceableTexture(4, _texture);
			elseif(cell.geoSet == 0 or cell.geoSet == 1 or cell.geoSet == 4) then
				if(cell.skinTU ~= nil) then
					local _texture = ParaAsset.LoadTexture("", cell.skinTU, 1);
					obj:SetReplaceableTexture(1, _texture);
				end
				if(cell.skinAU ~= nil) then
					local _texture = ParaAsset.LoadTexture("", cell.skinAU, 1);
					obj:SetReplaceableTexture(2, _texture);
				end
				if(cell.skinAL ~= nil) then
					local _texture = ParaAsset.LoadTexture("", cell.skinAL, 1);
					obj:SetReplaceableTexture(3, _texture);
				end
			elseif(cell.geoSet == 3) then
				local _texture = ParaAsset.LoadTexture("", cell.skinTU, 1);
				obj:SetReplaceableTexture(1, _texture);
				local _texture = ParaAsset.LoadTexture("", cell.skinAU, 1);
				obj:SetReplaceableTexture(2, _texture);
			end
		end
	end
end

-- Page Left
function Inventory.RefreshMatrix3D()

	local _this,_parent;
	
	local _thisCont = ParaUI.GetUIObject("CCS_UI_Inventory_Head_container");
	
	-- update the page label
	_this = _thisCont:GetChild("labelPage");
	_this.text = (Inventory.currentPage + 1).."/"..Inventory.totalPage;
	
	if(_thisCont:IsValid()) then
		local ctl = CommonCtrl.GetControl("Inventory3DIconMatrix");
		local _currentStartNum;
		_currentStartNum = (Inventory.currentPage) * (Inventory.iconsPerPage);
		
		if(ctl ~= nil) then
			--ctl:Destroy();
			CommonCtrl.DeleteControl(ctl.name);
		end
		
		NPL.load("(gl)script/ide/GridView3D.lua");
		local ctl = CommonCtrl.GridView3D:new{
			name = "Inventory3DIconMatrix",
			container_bg = "Texture/3DMapSystem/CCS/InventorySlots.png",
			alignment = "_lt",
			left = 32, top = 10,
			width = 256,
			height = 128,
			cellWidth = 64,
			cellHeight = 64,
			parent = _thisCont,
			columns = 4,
			rows = 2,
			
			renderTargetSize = 512,
			
			DrawCellHandler = Inventory.DrawCCSItemCellHandler,
			};
		
		local CCSdbfile = "Database/characters.db";
		
		local db = sqlite3.open(DB.dbfile);
		local row;
		
		if(InventorySlot.Component == DB.CS_HEAD
			or InventorySlot.Component == DB.CS_SHOULDER 
			or InventorySlot.Component == DB.CS_HAND_RIGHT 
			or InventorySlot.Component == DB.CS_HAND_LEFT 
			or InventorySlot.Component == DB.CS_CAPE) then
			
			local i;
			for i = 1, table.getn(Inventory.Items) do
				
				if((_currentStartNum + i) <= Inventory.TotalIcons) then
					
					local index = Inventory.Items[_currentStartNum + i];
					local model, skin;
					for row in db:rows(string.format("select Model, Skin from ItemDisplayDB where ItemDisplayID = %d", index)) do
						model = row.Model;
						skin = row.Skin;
					end
					
					if(string.find(string.lower(model), ".x") == nil) then
						model = model..".x";
					end
					--local _assetName = "model/common/ccs_unisex/shirt06_TU1_TL2_AU3_AL4.x";
					
					if(InventorySlot.Component == DB.CS_HEAD) then
						model = "character/v3/Item/ObjectComponents/Head/"..model;
					elseif(InventorySlot.Component == DB.CS_SHOULDER) then
						model = "character/v3/Item/ObjectComponents/Shoulder/"..model;
					elseif(InventorySlot.Component == DB.CS_HAND_RIGHT
						or InventorySlot.Component == DB.CS_HAND_LEFT) then
						model = "character/v3/Item/ObjectComponents/Weapon/"..model;
					elseif(InventorySlot.Component == DB.CS_CAPE) then
						-- TODO: unisex unirace cape model
						model = "character/v3/Item/ObjectComponents/Cape/"..model;
					end
					
					local row = math.ceil(i/4);
					local column = i - (row - 1) * 4;
					
					local cell = CommonCtrl.GridCell3D:new{
						GridView = nil,
						name = row.."-"..column,
						text = row.."-"..column,
						column = column,
						row = row,
						-- CCS item specified info
						type = InventorySlot.Component,
						model = model,
						skin = skin,
						};
					ctl:InsertCell(cell, "Right");
					
				end -- if((_currentStartNum + i) < Inventory.TotalIcons) then
				
			end -- for i = 1, table.getn(Inventory.Items) do
			
		elseif(InventorySlot.Component == DB.CS_PANTS) then
			
			local i;
			for i = 1, 8 do
				
				if((_currentStartNum + i) <= Inventory.TotalIcons) then
					
					local index = Inventory.Items[_currentStartNum + i];
					
					local texLU; -- leg upper
					local texLL; -- leg lower
					local geoSet;
					local modelName;
					
					for row in db:rows(string.format("select GeosetB, TexLegUpper, TexLegLower from ItemDisplayDB where ItemDisplayID = %d", index)) do
						texLU = row.TexLegUpper or "";
						texLL = row.TexLegLower or "";
						geoSet = tonumber(row.GeosetB);
						if(texLU ~= "" and string.find(texLU, ".dds") == nil and string.find(texLU, ".DDS") == nil) then
							texLU = texLU..".dds";
						end
						if(texLL ~= "" and string.find(texLL, ".dds") == nil and string.find(texLL, ".DDS") == nil) then
							texLL = texLL..".dds";
						end
						if(texLU ~= "") then
							texLU = "character/v3/Item/TextureComponents/LegUpperTexture/"..texLU;
						else
							--texLU = "texture/skill_bro.png";
						end
						if(texLL ~= "") then
							texLL = "character/v3/Item/TextureComponents/LegLowerTexture/"..texLL;
						else
							--texLL = "texture/skill_bro.png";
						end
						if(geoSet == 0 or geoSet == 1) then
							modelName = "model/common/ccs_unisex/pants02_LU1_LL2.x";
						elseif(geoSet == 2) then
							modelName = "model/common/ccs_unisex/pants03_LU1_LL2.x";
						elseif(geoSet == 3) then
							modelName = "model/common/ccs_unisex/pants04_LU1_LL2.x";
						elseif(geoSet == 4) then
							modelName = "model/common/ccs_unisex/pants05_LU1_LL2.x";
						elseif(geoSet == 5) then
							modelName = "model/common/ccs_unisex/pants06_LU1_LL2.x";
						end
					end
					
					local row = math.ceil(i/4);
					local column = i - (row - 1) * 4;
					
					local cell = CommonCtrl.GridCell3D:new{
						GridView = nil,
						name = row.."-"..column,
						text = row.."-"..column,
						column = column,
						row = row,
						-- CCS item specified info
						type = InventorySlot.Component,
						model = modelName,
						skinLU = texLU,
						skinLL = texLL,
						tooltip = texLU,
						};
					ctl:InsertCell(cell, "Right");
					
				end -- if((_currentStartNum + i) < Inventory.TotalIcons) then
				
			end -- for i = 1, table.getn(Inventory.Items) do
			
		elseif(InventorySlot.Component == DB.CS_SHIRT) then
			
			--local i;
			--for i = _currentStartNum + 1, _currentStartNum + Inventory.iconsPerPage do
				--
				----if((_currentStartNum + i) < Inventory.TotalIcons) then
				----if((_currentStartNum < i) and ((_currentStartNum + Inventory.iconsPerPage) >= i)) then
				--if( i < Inventory.TotalIcons) then
			
			local i;
			for i = 1, 8 do
				
				if((_currentStartNum + i) <= Inventory.TotalIcons) then
					
					local index = Inventory.Items[_currentStartNum + i];
					
					local texTU; -- Chest Upper;
					local texTL; -- Chest Lower;
					local texAU; -- Arm Upper;
					local texAL; -- Arm Lower;
					local geoSet;
					local modelName;
					
					for row in db:rows(string.format("select GeosetA, TexChestUpper, TexChestLower, TexArmUpper, TexArmLower from ItemDisplayDB where ItemDisplayID = %d", index)) do
						texTU = row.TexChestUpper;
						texTL = row.TexChestLower;
						texAU = row.TexArmUpper;
						texAL = row.TexArmLower;
						geoSet = tonumber(row.GeosetA);
						if(texTU ~= nil and string.find(texTU, ".dds") == nil and string.find(texTU, ".DDS") == nil) then
							texTU = texTU..".dds";
						end
						if(texTL ~= nil and string.find(texTL, ".dds") == nil and string.find(texTL, ".DDS") == nil) then
							texTL = texTL..".dds";
						end
						if(texAU ~= nil and string.find(texAU, ".dds") == nil and string.find(texAU, ".DDS") == nil) then
							texAU = texAU..".dds";
						end
						if(texAL ~= nil and string.find(texAL, ".dds") == nil and string.find(texAL, ".DDS") == nil) then
							texAL = texAL..".dds";
						end
						
						if(texTU ~= nil) then
							texTU = "character/v3/Item/TextureComponents/TorsoUpperTexture/"..texTU;
						else
							--texTU = "texture/skill_bro.png";
						end
						if(texTL ~= nil) then
							texTL = "character/v3/Item/TextureComponents/TorsoLowerTexture/"..texTL;
						else
							--texTL = "texture/skill_bro.png";
						end
						if(texAU ~= nil) then
							texAU = "character/v3/Item/TextureComponents/ArmUpperTexture/"..texAU;
						else
							--texAU = "texture/skill_bro.png";
						end
						if(texAL ~= nil) then
							texAL = "character/v3/Item/TextureComponents/ArmLowerTexture/"..texAL;
						else
							--texAL = "texture/skill_bro.png";
						end
						
						if(geoSet == 0 or geoSet == 1) then
							modelName = "model/common/ccs_unisex/shirt02_TU1_AU2_AL3.x";
						elseif(geoSet == 2) then
							modelName = "model/common/ccs_unisex/shirt03_TU1_TL2_AU3_AL4.x";
						elseif(geoSet == 3) then
							modelName = "model/common/ccs_unisex/shirt04_TU1_AU2.x";
						elseif(geoSet == 4) then
							modelName = "model/common/ccs_unisex/shirt05_TU1_AU2_AL3.x";
						elseif(geoSet == 5) then
							modelName = "model/common/ccs_unisex/shirt06_TU1_TL2_AU3_AL4.x";
						end
					end
					
					local row = math.ceil(i/4);
					local column = i - (row - 1) * 4;
					
					local cell = CommonCtrl.GridCell3D:new{
						GridView = nil,
						name = row.."-"..column,
						text = row.."-"..column,
						column = column,
						row = row,
						-- CCS item specified info
						type = InventorySlot.Component,
						model = modelName,
						skinTU = texTU,
						skinTL = texTL,
						skinAU = texAU,
						skinAL = texAL,
						geoSet = geoSet,
						tooltip = texTU,
						};
					ctl:InsertCell(cell, "Right");
					
				end -- if((_currentStartNum + i) < Inventory.TotalIcons) then
				
			end -- for i = 1, table.getn(Inventory.Items) do
			
		elseif(InventorySlot.Component == DB.CS_BOOTS
			or InventorySlot.Component == DB.CS_GLOVES) then
			
			local i;
			for i = 1, table.getn(Inventory.Items) do
				
				if((_currentStartNum + i) <= Inventory.TotalIcons) then
					
					local index = Inventory.Items[_currentStartNum + i];
					
					local texName; -- for both hands and feet
					local modelName; -- for both hands and feet
					
					if(InventorySlot.Component == DB.CS_BOOTS) then
						for row in db:rows(string.format("select TexFeet from ItemDisplayDB where ItemDisplayID = %d", index)) do
							texName = row.TexFeet;
							if(string.find(texName, ".dds") == nil and string.find(texName, ".DDS") == nil) then
								texName = texName..".dds";
							end
							texName = "character/v3/Item/TextureComponents/FootTexture/"..texName;
							modelName = "model/common/ccs_unisex/boots02_FTr2.x";
						end
					elseif(InventorySlot.Component == DB.CS_GLOVES) then
						for row in db:rows(string.format("select TexHands from ItemDisplayDB where ItemDisplayID = %d", index)) do
							texName = row.TexHands;
							if(string.find(texName, ".dds") == nil and string.find(texName, ".DDS") == nil) then
								texName = texName..".dds";
							end
							texName = "character/v3/Item/TextureComponents/HandTexture/"..texName;
							modelName = "model/common/ccs_unisex/hand02_Hr2.x";
						end
					end
					
					local row = math.ceil(i/4);
					local column = i - (row - 1) * 4;
					
					local cell = CommonCtrl.GridCell3D:new{
						GridView = nil,
						name = row.."-"..column,
						text = row.."-"..column,
						column = column,
						row = row,
						-- CCS item specified info
						type = InventorySlot.Component,
						model = modelName,
						skin = texName,
						tooltip = texName,
						};
					ctl:InsertCell(cell, "Right");
					
				end -- if((_currentStartNum + i) < Inventory.TotalIcons) then
				
			end -- for i = 1, table.getn(Inventory.Items) do
			
		end -- if(InventorySlot.Component == DB.CS_XXXXX) then
		
		db:close();
		
		ctl:Show();
		
	end -- if(_this:IsValid()) then
	
end -- function Inventory.PageLeft()

function Inventory.GetCharacterSlotInfo(obj_params)

	local obj = ObjEditor.GetObjectByParams(obj_params);
	local playerChar;
	
	-- get player character
	if(obj ~= nil and obj:IsValid() == true) then
		if(obj:IsCharacter() == true) then
			playerChar = obj:ToCharacter();
		end
	end
	if( playerChar ~= nil and playerChar:IsCustomModel() == true ) then
		
		local characterslot_info = {};
		-- get the character according to ccs table(inventory part)
		characterslot_info.itemHead = playerChar:GetCharacterSlotItemID(0);
		characterslot_info.itemNeck = playerChar:GetCharacterSlotItemID(1);
		characterslot_info.itemShoulder = playerChar:GetCharacterSlotItemID(2);
		characterslot_info.itemBoots = playerChar:GetCharacterSlotItemID(3);
		characterslot_info.itemBelt = playerChar:GetCharacterSlotItemID(4);
		characterslot_info.itemShirt = playerChar:GetCharacterSlotItemID(5);
		characterslot_info.itemPants = playerChar:GetCharacterSlotItemID(6);
		characterslot_info.itemChest = playerChar:GetCharacterSlotItemID(7);
		characterslot_info.itemBracers = playerChar:GetCharacterSlotItemID(8);
		characterslot_info.itemGloves = playerChar:GetCharacterSlotItemID(9);
		characterslot_info.itemHandRight = playerChar:GetCharacterSlotItemID(10);
		characterslot_info.itemHandLeft = playerChar:GetCharacterSlotItemID(11);
		characterslot_info.itemCape = playerChar:GetCharacterSlotItemID(12);
		characterslot_info.itemTabard = playerChar:GetCharacterSlotItemID(13);
		
		return characterslot_info;
	else
		log("error: attempt to get a non character ccs information or non custom character.\n");
	end
end

-- get the character slot information string from the obj_param
-- @param obj_param: object parameter(table) or ParaObject object
-- @return: the character slot info string if CCS character
--		or nil if no character slot information is found
function Inventory.GetCharacterSlotInfoString(obj_params)

	local obj;
	local playerChar;
	
	if(type(obj_params) == "table") then
		obj = ObjEditor.GetObjectByParams(obj_params);
	elseif(type(obj_params) == "userdata") then
		obj = obj_params;
	else
		log("error: obj_params not table or userdata value.\n");
		return;
	end
	
	-- get player character
	if(obj ~= nil and obj:IsValid() == true) then
		if(obj:IsCharacter() == true) then
			playerChar = obj:ToCharacter();
		end
	end
	if( playerChar ~= nil and playerChar:IsCustomModel() == true ) then
		
		local sInfo = "";
		-- get the character according to ccs table(inventory part)
		
		sInfo = sInfo..playerChar:GetCharacterSlotItemID(0).."#";
		sInfo = sInfo..playerChar:GetCharacterSlotItemID(1).."#";
		sInfo = sInfo..playerChar:GetCharacterSlotItemID(2).."#";
		sInfo = sInfo..playerChar:GetCharacterSlotItemID(3).."#";
		sInfo = sInfo..playerChar:GetCharacterSlotItemID(4).."#";
		sInfo = sInfo..playerChar:GetCharacterSlotItemID(5).."#";
		sInfo = sInfo..playerChar:GetCharacterSlotItemID(6).."#";
		sInfo = sInfo..playerChar:GetCharacterSlotItemID(7).."#";
		sInfo = sInfo..playerChar:GetCharacterSlotItemID(8).."#";
		sInfo = sInfo..playerChar:GetCharacterSlotItemID(9).."#";
		sInfo = sInfo..playerChar:GetCharacterSlotItemID(10).."#";
		sInfo = sInfo..playerChar:GetCharacterSlotItemID(11).."#";
		sInfo = sInfo..playerChar:GetCharacterSlotItemID(12).."#";
		sInfo = sInfo..playerChar:GetCharacterSlotItemID(13).."#";
		sInfo = sInfo..playerChar:GetCharacterSlotItemID(14).."#";
		sInfo = sInfo..playerChar:GetCharacterSlotItemID(15).."#";
		sInfo = sInfo..playerChar:GetCharacterSlotItemID(16).."#";
		sInfo = sInfo..playerChar:GetCharacterSlotItemID(17).."#";
		sInfo = sInfo..playerChar:GetCharacterSlotItemID(18).."#";
		sInfo = sInfo..playerChar:GetCharacterSlotItemID(19).."#";
		sInfo = sInfo..playerChar:GetCharacterSlotItemID(20).."#";
		sInfo = sInfo..playerChar:GetCharacterSlotItemID(21).."#";
		sInfo = sInfo..playerChar:GetCharacterSlotItemID(22).."#";
		sInfo = sInfo..playerChar:GetCharacterSlotItemID(23).."#";
		sInfo = sInfo..playerChar:GetCharacterSlotItemID(24).."#";
		sInfo = sInfo..playerChar:GetCharacterSlotItemID(25).."#";
		sInfo = sInfo..playerChar:GetCharacterSlotItemID(26).."#";
		sInfo = sInfo..playerChar:GetCharacterSlotItemID(27).."#";
		sInfo = sInfo..playerChar:GetCharacterSlotItemID(28).."#";
		sInfo = sInfo..playerChar:GetCharacterSlotItemID(29).."#";
		
		return sInfo;
	else
		--log("error: attempt to get a non character ccs information or non custom character.\n");
		return nil;
	end
end

function Inventory.SetCharacterSlot(player, slot, itemID)
	if(player == nil or player:IsValid() == false) then
		return;
	end
	if(player:IsCharacter() == false) then
		return;
	end
	
	local playerChar = player:ToCharacter();
	
	if(playerChar ~= nil and playerChar:IsCustomModel() == true) then
		playerChar:SetCharacterSlot(slot, itemID);
		
		-- if boots slot, check the character BootHeightDB to raise the character for high heel boot
		if(slot == Map3DSystem.UI.CCS.DB.CS_BOOTS) then
			if(Inventory.BootHeightDB == nil) then
				Inventory.BootHeightDB = {};
				-- load the BootHeightDB data
				
				local databaseFile = "Database/characters.db";
				local result = {};
				local i = 1;
				local db = sqlite3.open(databaseFile);
				
				local db_ItemDatabase = {};
				local maxItemID = 1;
				for row in db:rows("SELECT ID, Race, Gender, BootType, BootHeight FROM BootHeightsDB") do
					local ID = tonumber(row.ID);
					Inventory.BootHeightDB[ID] = {
						Race = tonumber(row.Race),
						Gender = tonumber(row.Gender),
						BootType = tonumber(row.BootType),
						BootHeight = tonumber(row.BootHeight),
					};
				end
				db:close();
			end
			
			player:GetAttributeObject():SetField("BootHeight", 0);
			
			local assetName = player:GetPrimaryAsset():GetKeyName();
			if(string.find(string.lower(assetName), "human/female/humanfemale.x")) then
				local count;
				-- TODO: lxz for andy: use index table instead of brutal force search.
				local k, v;
				for k, v in ipairs(Map3DSystem.UI.CCS.DB.AuraInventoryID[6]) do
					if(itemID == v) then
						count = k;
						break;
					end
				end
				
				if(count~=nil) then
					bootType = Map3DSystem.UI.CCS.DB.AuraInventoryPreview[6][count].GeoSetA + 1;
					
					local k, v;
					for k, v in ipairs(Inventory.BootHeightDB) do
						if(v.BootType == bootType) then
							local height = v.BootHeight/1000;
							player:GetAttributeObject():SetField("BootHeight", height);
							break;
						end
					end
				end
			end
		end
	end
end

function Inventory.ApplyCharacterSlotInfoString(obj_params, sInfo)

	local obj;
	local playerChar;
	
	if(type(obj_params) == "table") then
		obj = ObjEditor.GetObjectByParams(obj_params);
	elseif(type(obj_params) == "userdata") then
		obj = obj_params;
	else
		log("error: obj_params not table or userdata value.\n");
		return;
	end
	
	-- get player character
	if(obj ~= nil and obj:IsValid() == true) then
		if(obj:IsCharacter() == true) then
			playerChar = obj:ToCharacter();
		end
	end
	if( playerChar ~= nil and playerChar:IsCustomModel() == true ) then
		
		local slot = 0;
		local itemID;
		for itemID in string.gfind(sInfo, "([^#]+)") do
			--playerChar:SetCharacterSlot(slot, tonumber(itemID));
			Inventory.SetCharacterSlot(obj, slot, tonumber(itemID));
			slot = slot + 1;
		end
	else
		--log("error: attempt to set a non character ccs information or non custom character.\n");
	end
end

function Inventory.SetCharacterSlotInfo(obj_params, characterslot_info)
	
	local obj = ObjEditor.GetObjectByParams(obj_params);
	local playerChar;
	
	-- get player character
	if(obj ~= nil and obj:IsValid() == true) then
		if(obj:IsCharacter() == true) then
			playerChar = obj:ToCharacter();
		end
	end
	
	local logStr = "";
	if(playerChar ~= nil) then
		-- set the character according to ccs table(inventory part)
		if(characterslot_info.itemHead ~= nil) then
			playerChar:SetCharacterSlot(0, characterslot_info.itemHead);
			logStr = logStr.."Mount Head:"..characterslot_info.itemHead.."\n";
		end
		if(characterslot_info.itemNeck ~= nil) then
			playerChar:SetCharacterSlot(1, characterslot_info.itemNeck);
			logStr = logStr.."Mount Neck:"..characterslot_info.itemNeck.."\n";
		end
		if(characterslot_info.itemShoulder ~= nil) then
			playerChar:SetCharacterSlot(2, characterslot_info.itemShoulder);
			logStr = logStr.."Mount Shoulder:"..characterslot_info.itemShoulder.."\n";
		end
		if(characterslot_info.itemBoots ~= nil) then
			playerChar:SetCharacterSlot(3, characterslot_info.itemBoots);
			logStr = logStr.."Mount Boots:"..characterslot_info.itemBoots.."\n";
		end
		if(characterslot_info.itemBelt ~= nil) then
			playerChar:SetCharacterSlot(4, characterslot_info.itemBelt);
			logStr = logStr.."Mount Belt:"..characterslot_info.itemBelt.."\n";
		end
		if(characterslot_info.itemShirt ~= nil) then
			playerChar:SetCharacterSlot(5, characterslot_info.itemShirt);
			logStr = logStr.."Mount Shirt:"..characterslot_info.itemShirt.."\n";
		end
		if(characterslot_info.itemPants ~= nil) then
			playerChar:SetCharacterSlot(6, characterslot_info.itemPants);
			logStr = logStr.."Mount Pants:"..characterslot_info.itemPants.."\n";
		end
		if(characterslot_info.itemChest ~= nil) then
			playerChar:SetCharacterSlot(7, characterslot_info.itemChest);
			logStr = logStr.."Mount Chest:"..characterslot_info.itemChest.."\n";
		end
		if(characterslot_info.itemBracers ~= nil) then
			playerChar:SetCharacterSlot(8, characterslot_info.itemBracers);
			logStr = logStr.."Mount Bracers:"..characterslot_info.itemBracers.."\n";
		end
		if(characterslot_info.itemGloves ~= nil) then
			playerChar:SetCharacterSlot(9, characterslot_info.itemGloves);
			logStr = logStr.."Mount Gloves:"..characterslot_info.itemGloves.."\n";
		end
		if(characterslot_info.itemHandRight ~= nil) then
			playerChar:SetCharacterSlot(10, characterslot_info.itemHandRight);
			logStr = logStr.."Mount HadnRight:"..characterslot_info.itemHandRight.."\n";
		end
		if(characterslot_info.itemHandLeft ~= nil) then
			playerChar:SetCharacterSlot(11, characterslot_info.itemHandLeft);
			logStr = logStr.."Mount HandLeft:"..characterslot_info.itemHandLeft.."\n";
		end
		if(characterslot_info.itemCape ~= nil) then
			playerChar:SetCharacterSlot(12, characterslot_info.itemCape);
			logStr = logStr.."Mount Cape:"..characterslot_info.itemCape.."\n";
		end
		if(characterslot_info.itemTabard ~= nil) then
			playerChar:SetCharacterSlot(13, characterslot_info.itemTabard);
			logStr = logStr.."Mount Tabard:"..characterslot_info.itemTabard.."\n";
		end
		
		-- log the change information when the item editor is on
		local _editor = ParaUI.GetUIObject("Map3DSystem_ItemEditor");
		if(_editor:IsValid() == true and _editor.visible == true) then
			log(logStr);
		end
		
		-- TODO: play animation according to ccs change
	else
		log("error: attempt to set a non character ccs information.\n");
	end
end

-- change the CCS character slot info of the current seleceted character
function Inventory.OnChangeCharacterSlot(obj_params, nComponent, index)
	local obj = ObjEditor.GetObjectByParams(obj_params);
	local playerChar;
	
	-- get player character
	if(obj ~= nil and obj:IsValid() == true) then
		if(obj:IsCharacter() == true) then
			playerChar = obj:ToCharacter();
		end
	end
	
	if(playerChar ~= nil) then
		-- record the ccs table(inventory part)
		local _ccsTable = {};
		
		if(nComponent == 0) then _ccsTable.itemHead = index; end
		if(nComponent == 1) then _ccsTable.itemNeck = index; end
		if(nComponent == 2) then _ccsTable.itemShoulder = index; end
		if(nComponent == 3) then _ccsTable.itemBoots = index; end
		if(nComponent == 4) then _ccsTable.itemBelt = index; end
		if(nComponent == 5) then _ccsTable.itemShirt = index; end
		if(nComponent == 6) then _ccsTable.itemPants = index; end
		if(nComponent == 7) then _ccsTable.itemChest = index; end
		if(nComponent == 8) then _ccsTable.itemBracers = index; end
		if(nComponent == 9) then _ccsTable.itemGloves = index; end
		if(nComponent == 10) then _ccsTable.itemHandRight = index; end
		if(nComponent == 11) then _ccsTable.itemHandLeft = index; end
		if(nComponent == 12) then _ccsTable.itemCape = index; end
		if(nComponent == 13) then _ccsTable.itemTabard = index; end
		
		-- send object modify message
		Map3DSystem.SendMessage_obj({
				type = Map3DSystem.msg.OBJ_ModifyObject, 
				obj_params = obj_params,
				characterslot_info = _ccsTable,
				});
	else
		log("error: attempt to set a non character ccs information.\n");
	end
end

function Inventory.OnEnterIconMatrix(gridViewName, x, y)
	local ctl = CommonCtrl.GetControl(gridViewName);
	if(ctl ~= nil) then
		local scene = ctl:GetMiniSceneGraph();
		local obj = scene:GetObject(x.."-"..y);
		if(obj:IsValid() == true) then
			local att = obj:GetAttributeObject();
			att:SetField("render_tech", 10);
		end
	end
end		

function Inventory.OnLeaveIconMatrix(gridViewName, x, y)
	local ctl = CommonCtrl.GetControl(gridViewName);
	if(ctl ~= nil) then
		local scene = ctl:GetMiniSceneGraph();
		local obj = scene:GetObject(x.."-"..y);
		if(obj:IsValid() == true) then
			local att = obj:GetAttributeObject();
			att:SetField("render_tech", 9);
		end
	end
end

-- icon matrix onclick function: mount the item to character slot
function Inventory.OnClickIconMatrix(x, y)
	x = x - 1;
	y = y - 1;
	local page = Inventory.currentPage;
	local iconNum = page * (Inventory.iconsPerPage) + x + (y * 4);
	--Inventory.OnClickSetInventorySlotItem(iconNum);

	local index = Inventory.Items[iconNum+1];
	Inventory.OnChangeCharacterSlot(
			Map3DSystem.obj.GetObjectParams("selection"), 
			InventorySlot.Component, 
			index);
			
	-- TODO: play sound for item mounting
	
	-- play animation according to CCS InventorySlot.Component
	if(InventorySlot.Component == DB.CS_SHIRT) then
		Map3DSystem.Animation.SendMeMessage({
				type = Map3DSystem.msg.ANIMATION_Character,
				obj_params = nil, --  <player>
				animationName = "CCSUpper",
				});
	elseif(InventorySlot.Component == DB.CS_SHOULDER) then
		Map3DSystem.Animation.SendMeMessage({
				type = Map3DSystem.msg.ANIMATION_Character,
				obj_params = nil, --  <player>
				animationName = "CCSShoulder",
				});
	elseif(InventorySlot.Component == DB.CS_GLOVES) then
		Map3DSystem.Animation.SendMeMessage({
				type = Map3DSystem.msg.ANIMATION_Character,
				obj_params = nil, --  <player>
				animationName = "CCSGlove",
				});
	elseif(InventorySlot.Component == DB.CS_PANTS) then
		Map3DSystem.Animation.SendMeMessage({
				type = Map3DSystem.msg.ANIMATION_Character,
				obj_params = nil, --  <player>
				animationName = "CCSPant",
				});
	elseif(InventorySlot.Component == DB.CS_BOOTS) then
		Map3DSystem.Animation.SendMeMessage({
				type = Map3DSystem.msg.ANIMATION_Character,
				obj_params = nil, --  <player>
				animationName = "CCSBoot",
				});
	elseif(InventorySlot.Component == DB.CS_HAND_LEFT) then
		Map3DSystem.Animation.SendMeMessage({
				type = Map3DSystem.msg.ANIMATION_Character,
				obj_params = nil, --  <player>
				animationName = "LeftChangeSword",
				});
	elseif(InventorySlot.Component == DB.CS_HAND_RIGHT) then
		Map3DSystem.Animation.SendMeMessage({
				type = Map3DSystem.msg.ANIMATION_Character,
				obj_params = nil, --  <player>
				animationName = "RightChangeSword",
				});
	elseif(InventorySlot.Component == DB.CS_HEAD
		or InventorySlot.Component == DB.CS_CAPE) then
		Map3DSystem.Animation.SendMeMessage({
				type = Map3DSystem.msg.ANIMATION_Character,
				obj_params = nil, --  <player>
				animationName = "CCSHead",
				});
	end
	
end

-- unmount the item according to current character slot on the current seleceted character
function Inventory.OnClickUnmountCurrentCharacterSlot()
	
	Inventory.OnChangeCharacterSlot(
			Map3DSystem.obj.GetObjectParams("selection"), 
			InventorySlot.Component, 
			0);
	
	-- TODO: general implementation
	-- mount the default shirt or pant for human female and male
	local player = ParaScene.GetPlayer();
	local assetName = player:GetPrimaryAsset():GetKeyName();
	
	if(string.find(assetName, "HumanFemale.x") ~= nil) then
		if(InventorySlot.Component == DB.CS_SHIRT) then
			Inventory.OnChangeCharacterSlot(
					Map3DSystem.obj.GetObjectParams("selection"), 
					InventorySlot.Component, 
					10);
		elseif(InventorySlot.Component == DB.CS_PANTS) then
			Inventory.OnChangeCharacterSlot(
					Map3DSystem.obj.GetObjectParams("selection"), 
					InventorySlot.Component, 
					12);
		end
	end
	
	if(string.find(assetName, "HumanMale.x") ~= nil) then
		if(InventorySlot.Component == DB.CS_SHIRT) then
			Inventory.OnChangeCharacterSlot(
					Map3DSystem.obj.GetObjectParams("selection"), 
					InventorySlot.Component, 
					11);
		elseif(InventorySlot.Component == DB.CS_PANTS) then
			Inventory.OnChangeCharacterSlot(
					Map3DSystem.obj.GetObjectParams("selection"), 
					InventorySlot.Component, 
					13);
		end
	end
	-- TODO: play sound for item unmounting
end
