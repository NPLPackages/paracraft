--[[
Title: ItemSnipper
Author(s): LiXizhi
Date: 2013/7/14
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemSnipper.lua");
local ItemSnipper = commonlib.gettable("MyCompany.Aries.Game.Items.ItemSnipper");
local item_ = ItemSnipper:new({icon,});
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/math/vector.lua");
local vector3d = commonlib.gettable("mathlib.vector3d");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
local CameraController = commonlib.gettable("MyCompany.Aries.Game.CameraController")
local SelectionManager = commonlib.gettable("MyCompany.Aries.Game.SelectionManager");

local ItemSnipper = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Items.Item"), commonlib.gettable("MyCompany.Aries.Game.Items.ItemSnipper"));
block_types.RegisterItemClass("ItemSnipper", ItemSnipper);

-- ItemSnipper.CreateAtPlayerFeet = true;
-- if true, when item is collected, it automatically replace the tool in hand. 
ItemSnipper.auto_equip = true;

ItemSnipper.damage = 10;

ItemSnipper.can_pick = false;

ItemSnipper.shoot_range = 200;

-- make the entity auto rotate
ItemSnipper.auto_rotate = true;

-- @param template: icon
-- @param radius: the half radius of the object. 
function ItemSnipper:ctor()
	
end

function ItemSnipper:mousePressEvent(event)
	if(event.mouse_button == "left") then
		self:FireMissile();
	elseif(event.mouse_button == "right") then
		self:ToggleSnipperMode();
	end
	event:accept();
end

function ItemSnipper:mouseMoveEvent(event)
	GameLogic.GetSceneContext():CheckMousePick();
end

function ItemSnipper:mouseReleaseEvent(event)
end

function ItemSnipper:keyPressEvent(event)
	local dik_key = event.keyname;

	if(GameLogic.GetSceneContext():HandleGlobalKey(event)) then
	elseif(GameLogic.GetSceneContext():handlePlayerKeyEvent(event)) then
	end	
	event:accept();
end

-- fire a missile
function ItemSnipper:FireMissile()
	
	
	--local fromX, fromY, fromZ = vFromPos[1], vFromPos[2], vFromPos[3];
	
	local fromX, fromY, fromZ = EntityManager.GetPlayer():GetPosition();
	fromY = fromY + 1;
	local vFromPos = vector3d:new({fromX, fromY, fromZ});

	local att = ParaCamera.GetAttributeObject();
	local lookatPos = vector3d:new(att:GetField("Lookat position", {1, 1, 1}));
	local vEyePos = vector3d:new(att:GetField("Eye position", {1, 1, 1}));
	
	local vDirection = lookatPos - vEyePos;
	vDirection:normalize();

	local toX, toY, toZ;
	local block_id;
	
	local result = SelectionManager:MousePickBlock(true, true, true, self.shoot_range);
	if(result)  then
		if(result.obj) then
			-- tricky code: 
			local x, y, z = result.obj:GetPosition();
			local lookatPos = vector3d:new({x, y+1, z});
			local dist_to_obj = (lookatPos - vEyePos):length();
			
			local vTarget = vEyePos + (vDirection * dist_to_obj);
			toX, toY, toZ = vTarget[1], vTarget[2], vTarget[3];
		elseif(result.x) then
			toX, toY, toZ = result.x, result.y, result.z;
		end
	end
	if(not toX) then
		local vTarget = vFromPos + (vDirection * 80);
		toX, toY, toZ = vTarget[1], vTarget[2], vTarget[3];
	end

	if(toX) then
		local asset = ParaAsset.LoadParaX("", "character/v5/06quest/Cartridge/Cartridge01.x");
		ParaScene.FireMissile(asset, 50, fromX, fromY, fromZ, toX, toY, toZ);

		if(result) then
			if(result.block_id) then
				-- hit block ignore it
				if(result.blockX and  result.block_id>0 and result.block_id<200) then
					-- create some block pieces at hit point. 
					local block_template = block_types.get(result.block_id);
					block_template:CreateBlockPieces(result.blockX, result.blockY, result.blockZ, 1, nil, toX, toY, toZ);
				end
			elseif(result.obj) then	
				-- hit entity try to check if entity is a monster
				local main_texture = result.obj:GetPrimaryAsset():GetDefaultReplaceableTexture(0);
				local filename = main_texture:GetKeyName();
				if ( filename == "" ) then
					filename  = nil;
				end
				-- create some block pieces at hit point. 
				local block_template = block_types.get(55);
				block_template:CreateBlockPieces(result.blockX, result.blockY, result.blockZ, 1, filename, toX, toY, toZ);

				-- invoke callback
				if(result.entity) then
					result.entity:OnHit(self.damage, fromX, fromY, fromZ);
				end
			end
		end

		-- making the player shake when fire
		local old_x, old_y, old_z = EntityManager.GetPlayer():GetPosition();
		local vOffset = vDirection*0.2;
		local offset_y = vOffset[2] + math.random(50,150)/1000;
		vOffset = vector3d:new({0,1,0}) * vDirection * (math.random(50,150)/1000);
		local offset_x, offset_z  = vOffset[1], vOffset[3];
		
		if(EntityManager.GetPlayer():IsOnGround()) then
			UIAnimManager.PlayCustomAnimation(300, function(elapsedTime)
					local dX, dY, dZ;
					if(elapsedTime < 50) then
						local t = (elapsedTime/50);
						dX = offset_x * t;
						dY = offset_y * t;
						dZ = offset_z * t;
					else
						local t = (1 - (elapsedTime-50)/250);
						dX = offset_x * t;
						dY = offset_y * t;
						dZ = offset_z * t;
					end
					EntityManager.GetPlayer():SetPosition(old_x+dX, old_y+dY, old_z+dZ);
				end);
		end
	end
end


-- factory class to create an instance of the entity 
function ItemSnipper:OnUse()
end

local normal_fov = 60/180*3.1415926;
local snipper_fov = 10/180*3.1415926;
local speed_fov = 200/180*3.1415926;

function ItemSnipper:AnimateFieldOfView(target_fov)
	CameraController.AnimateFieldOfView(target_fov);
end

function ItemSnipper:ToggleSnipperMode(is_snipper_mode)
	if(is_snipper_mode == nil) then
		self.is_snipper_mode = not self.is_snipper_mode;
	else
		self.is_snipper_mode = is_snipper_mode;
	end
	
	local _parent = ParaUI.GetUIObject("Snipper_canvas");
	if(not _parent:IsValid())then
		local _, _, width_screen, height_screen = ParaUI.GetUIObject("root"):GetAbsPosition();
		local margin = math.floor((width_screen - height_screen)/2)+1;

		_parent = ParaUI.CreateUIObject("container", "Snipper_canvas", "_fi", 0, 0, 0, 0);
		_parent.background = "";
		_parent.enabled = false;
		_parent.zorder = -1;
		_parent:AttachToRoot();

		local _this = ParaUI.CreateUIObject("button", "c", "_fi", margin, 0, margin, 0);
		_this.background = "Texture/Aries/Creator/Snipper/SnipperCamera.png";
		_this.enabled = false;
		_guihelper.SetUIColor(_this, "#ffffffcc");
		_parent:AddChild(_this);

		local _this = ParaUI.CreateUIObject("button", "c", "_ml", 0, 0, margin, 0);
		_this.background = "Texture/Aries/Creator/Snipper/SnipperCamera.png;0 0 256 5";
		_this.enabled = false;
		_guihelper.SetUIColor(_this, "#ffffffcc");
		_parent:AddChild(_this);

		local _this = ParaUI.CreateUIObject("button", "c", "_mr", 0, 0, margin, 0);
		_this.background = "Texture/Aries/Creator/Snipper/SnipperCamera.png;0 0 256 5";
		_this.enabled = false;
		_guihelper.SetUIColor(_this, "#ffffffcc");
		_parent:AddChild(_this);
	end


	local att = ParaCamera.GetAttributeObject();
	if(self.is_snipper_mode) then
		self:AnimateFieldOfView(snipper_fov);
		--att:SetField("MoveScaler", 5);
		att:SetField("RotationScaler", 0.001);
		--att:SetField("TotalDragTime", 5)
		--att:SetField("SmoothFramesNum", 8)
		_parent.visible = true;
	else
		self:AnimateFieldOfView(normal_fov);
		att:SetField("RotationScaler", 0.004);
		_parent.visible = false;
	end
end

-- virtual function: when selected in right hand
function ItemSnipper:OnSelect()
	GameLogic.ToggleCamera(true);
	self:ToggleSnipperMode(false);
	GameLogic.AddBBS("Snipper", L"射击模式：鼠标滚轮切换物品，Q键丢弃", 3000000, "0 255 0");
end

-- virtual function: when deselected in right hand
function ItemSnipper:OnDeSelect()
	self:ToggleSnipperMode(false);
	GameLogic.ToggleCamera(false);
	GameLogic.AddBBS("Snipper", nil);
end


function ItemSnipper:OnObtain()
end

function ItemSnipper:OnClick()
	GameLogic.SetBlockInRightHand(self.id);
end
