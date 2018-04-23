--[[
Title: HomelandTemplate items
Author(s): WangTian
Date: 2009/12/6
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemItem/Item_HomelandTemplate.lua");
------------------------------------------------------------
]]

local Item_HomelandTemplate = {};
commonlib.setfield("Map3DSystem.Item.Item_HomelandTemplate", Item_HomelandTemplate)

---------------------------------
-- functions
---------------------------------

function Item_HomelandTemplate:new(o)
	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self
	return o
end

-- When item is clicked through pe:slot
function Item_HomelandTemplate:OnClick(mouse_button)
	local ItemManager = Map3DSystem.Item.ItemManager;
	if(mouse_button == "left") then
		-- directly use the item
		self:UseItem(function(msg) end);
		
	elseif(mouse_button == "right") then
		---- destroy the item
		--_guihelper.MessageBox("你确定要销毁 #"..tostring(self.guid).." 物品么？", function(result) 
			--if(_guihelper.DialogResult.Yes == result) then
				--Map3DSystem.Item.ItemManager.DestroyItem(self.guid, 1, function(msg)
					--if(msg) then
						--log("+++++++Destroy item return: #"..tostring(self.guid).." +++++++\n")
						--commonlib.echo(msg);
					--end
				--end);
			--elseif(_guihelper.DialogResult.No == result) then
				---- doing nothing if the user cancel the add as friend
			--end
		--end, _guihelper.MessageBoxButtons.YesNo);
	end
end

-- When item is clicked through pe:slot
function Item_HomelandTemplate:UseItem(callbackFunc)
	-- mount or use the item
	if(self.bag == 0 and self.position) then
		Map3DSystem.Item.ItemManager.UnEquipItem(self.position, function(msg) 
			if(callbackFunc) then
				callbackFunc(msg);
			end
		end);
	else
		Map3DSystem.Item.ItemManager.EquipItem(self.guid, function(msg) 
			if(callbackFunc) then
				callbackFunc(msg);
			end
		end);
	end
end

-- get the homeland path
-- @return:
function Item_HomelandTemplate:GetWorldPath()
	-- typical homeland template descfile:
	-- {worldpath="worlds/MyWorlds/1211_homeland"}
	local gsItem = System.Item.ItemManager.GetGlobalStoreItemInMemory(self.gsid);
	if(gsItem) then
		local desctable = commonlib.LoadTableFromString(gsItem.descfile);
		if(desctable) then
			return desctable.worldpath;
		end
	end
end