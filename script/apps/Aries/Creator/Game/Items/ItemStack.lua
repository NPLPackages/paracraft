--[[
Title: ItemStack
Author(s): LiXizhi
Date: 2013/12/25
Desc: ItemStack is intances of item. Only stackable item can have a count in ItemStack, only unstackable items can have serverdata. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemStack.lua");
local ItemStack = commonlib.gettable("MyCompany.Aries.Game.Items.ItemStack");
local item = ItemStack:new():Init(id, count, serverdata);
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/API/StatList.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Neuron/NeuronAPISandbox.lua");
local NeuronAPISandbox = commonlib.gettable("MyCompany.Aries.Game.Neuron.NeuronAPISandbox");
local NeuronManager = commonlib.gettable("MyCompany.Aries.Game.Neuron.NeuronManager");
local StatList = commonlib.gettable("MyCompany.Aries.Creator.Game.API.StatList");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");

local ItemStack = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Items.ItemStack"));

ItemStack.class_name = "ItemStack";

-- @param template: icon
-- @param icon:
-- @param block_id:
function ItemStack:ctor()
end

-- @param id: the underlying item id. 
-- @param serverdata: this should be xml node table or nil. 
function ItemStack:Init(id, count, serverdata)
	self.id = id;
	self.count = count or 1;
	self.serverdata = serverdata;
	return self;
end

function ItemStack:GetItem()
	return ItemClient.GetItem(self.id);
end

-- get user data 
function ItemStack:GetData()
	if(type(self.serverdata) == "table") then
		return self.serverdata[1];
	else
		return self.serverdata;
	end
end

-- set user data 
function ItemStack:SetData(data)
	if(type(self.serverdata) == "table") then
		self.serverdata[1] = data;
	else
		if(type(data) == "table") then
			self.serverdata = {data};
		else
			self.serverdata = data;
		end
	end
end

function ItemStack:SetPreferredBlockData(data)
	self.blockData = data;
end

function ItemStack:GetPreferredBlockData()
	return self.blockData;
end

-- create or get script scope
function ItemStack:GetScriptScope()
	if(not self._PAGESCRIPT) then
		self._PAGESCRIPT = {
			this = self,
		};
		setmetatable (self._PAGESCRIPT, NeuronAPISandbox.CreateGetSandbox())
	end
	return self._PAGESCRIPT;
end

-- set script and automatically reload if a different file is specified. 
function ItemStack:SetScript(filename)
	if(self.filename ~= filename) then
		if(filename == nil or filename == "") then
			self.filename = nil;
			self.activate_func = nil;
		else
			self.filename = filename;
			if(self.activate_func) then
				self:CheckLoadScript(true);
			end
		end
		self:SetData(filename);
	end
end

-- set the raw code to run
function ItemStack:SetCode(code)
	if(self.code ~= code) then
		if(code == nil or code == "") then
			self.code = nil;
			self.activate_func = nil;
		else
			self.code = code;
			if(self.activate_func) then
				self:CheckLoadScript(true);
			end
		end
		self:SetData(code);
	end
end

-- run the entire script code again with given parameters. 
function ItemStack:RunCode(...)
	self:CheckLoadScript(false, false);

	if(self.activate_func) then
		local ok, errmsg = pcall(self.activate_func, ...);
		if(not ok) then
			LOG.std(nil, "error", "ItemStack", errmsg);
			GameLogic.ShowMsg(errmsg);
		end
	end
end

-- whether has script file or raw code
function ItemStack:HasScript()
	return self.code or self.filename;
end

-- check load script code if any. It will only load on first call. Subsequent calls will be very fast. 
-- usually one do not need to call this function explicitly, unless one wants to preload or reload. 
-- @param bReload: default to nil. 
-- @param bRunOnFirstLoad: true to run on first load. if nil it means true
function ItemStack:CheckLoadScript(bReload, bRunOnFirstLoad)
	if( bReload or self.activate_func == nil) then
		local func;
		if(self.code) then
			local code_func, errormsg = loadstring(self.code, self.filename or "itemStack:code");
			if(not code_func) then
				LOG.std(nil, "error", "ItemStack", "<Runtime error> syntax error while loading code:\n%s\n%s", tostring(errormsg), self.code);
			else
				func = code_func;
			end
		else
			local filename = self:GetData();
			if(not self.filename or self.filename ~= filename) then
				self:SetScript(filename);
			end
			if(self.filename) then
				func = NeuronManager.GetScriptCode(self.filename, bReload);
			end
		end
		self.activate_func = func;
		
		if(func) then
			-- load on first activation call.
			setfenv(func, self:GetScriptScope());
			if(bRunOnFirstLoad~=false) then
				local ok, errmsg = pcall(func);
				if(not ok) then
					LOG.std(nil, "error", "ItemStack", errmsg);
					GameLogic.ShowMsg(errmsg);
				end
			end
		end
		if(not self.code) then
			NeuronManager.RegisterScript(self.filename, self);
		end
	end
	return self.activate_func;
end

-- get script function if any. 
-- @param func_name: some known functions are "main"
-- @return the function or nil is returned. 
function ItemStack:GetScriptFunction(func_name, bReload)
	if(func_name and self:CheckLoadScript(bReload)) then
		local script_scope = self:GetScriptScope();
		return rawget(script_scope, func_name);
	end
end

function ItemStack:GetPosition()
	return self.x, self.y, self.z;
end

-- set block position
function ItemStack:SetPosition(x, y, z)
	self.x, self.y, self.z = x, y, z;
end

-- activate script associated by SetScript() function.  
-- @param entity: the message to be passed to main function. 
function ItemStack:ActivateScript(...)
	local main_func = self:GetScriptFunction("main");
	if(main_func and type(main_func) == "function") then
		local ok, result = pcall(main_func, ...);
		if(ok) then
			return result;
		else
			LOG.std(nil, "error", "ItemStack:script", result);
		end
	end
end

-- called when this function is activated when the entity is activated. 
-- @param entity: the container entity. this is usually a command block or entity. 
-- @param entityPlayer: the triggering entity
-- @return true if the entity should stop activating other items in its bag. 
function ItemStack:OnActivate(entityContainer, entityPlayer)
	local item = self:GetItem();
	if(item) then
		return item:OnActivate(self, entityContainer, entityPlayer);
	end
end

-- called when entity receives a custom event via one of its rule bag items. 
function ItemStack:handleEntityEvent(entity, event)
	local item = self:GetItem();
	if(item) then
		return item:handleEntityEvent(self, entity, event);
	end
end


function ItemStack:LoadFromXMLNode(node)
	local attr = node.attr;
	if(attr) then
		local serverdata = node[1];
		if(serverdata) then
			if(type(serverdata) == "string" and serverdata:match("^{")) then
				-- if failed to load from table, we will keep wrong data as string for recovery manually. 
				-- the string will be serialized as first string node in xml file.
				serverdata = NPL.LoadTableFromString(serverdata) or serverdata;
			end
		end
		return self:Init(tonumber(attr.id), tonumber(attr.count), serverdata);
	end
end

function ItemStack:SaveToXMLNode(node, bSort)
	attr = node.attr;
	if(not attr) then
		attr = {id=self.id, count = self.count, };
		node.attr = attr;
	else
		attr.id = self.id;
		attr.count = self.count;
	end
	if(self.serverdata) then
		if(type(self.serverdata) == "table") then
			local item = ItemClient.GetItem(self.id);
			local sData;
			if(item) then
				sData = item:SerializeServerData(self.serverdata, bSort);
			else
				sData = commonlib.serialize_compact(self.serverdata, bSort);
			end
			node[1] = sData;
		else
			node[1] = self.serverdata;
		end
	end
	return node;
end

-- Remove the count number of items from the stack. Return a new stack object with count size.
-- @param count: if nil, it will be the total count. 
function ItemStack:SplitStack(count)
	count = count or self.count;
    local item_stack = ItemStack:new():Init(self.id, count);

    if (self.serverdata) then
        item_stack.serverdata = commonlib.copy(self.serverdata);
    end
	item_stack.blockData = self.blockData;
    self.count = self.count - count;
    return item_stack;
end

-- returns max allowed size of the item.
function ItemStack:GetMaxStackSize()
	local item = self:GetItem();
	if(item) then
		return item:GetMaxCount();
	end
	return 64;
end

-- if the ItemStack can hold 2 or more units of the item.
function ItemStack:IsStackable()
    return self:GetMaxStackSize() > 1;
end

-- return true if item is same, both id and serverdata mathes
function ItemStack:IsSameItem(itemStack)
	if(self.id == itemStack.id and (self.blockData==itemStack.blockData)) then
		
		if(self.serverdata == itemStack.serverdata) then
			return true;
		elseif(self.serverdata and itemStack.serverdata) then
			-- strict compare 
			return commonlib.compare(self.serverdata, itemStack.serverdata);
		end
	end
end

-- return a copy of self. 
function ItemStack:Copy()
	local o = {
		id = self.id,
		count = self.count,
		blockData = self.blockData, -- preferred block data
	}
	if(self.serverdata) then
		o.serverdata = commonlib.copy(self.serverdata);
	end
	return ItemStack:new(o);
end

-- swapping all content: id, count and data
function ItemStack:Swap(itemStack)
	if(itemStack) then
		self.id, itemStack.id = itemStack.id, self.id;
		self.count, itemStack.count = itemStack.count, self.count;
		self.serverdata, itemStack.serverdata = itemStack.serverdata, self.serverdata;
		self.blockData, itemStack.blockData = itemStack.blockData, self.blockData;
	end
end

-- get icon 
function ItemStack:GetIcon()
	local item = self:GetItem();
	if(item) then
		return item:GetIcon():gsub("#", ";");	
	end
end

-- get block template. 
function ItemStack:GetBlock()
	local item = self:GetItem();
	if(item) then
		return item:GetBlock();	
	end
end

-- get data field 
-- @param fieldname: "tooltip", "durability", etc
function ItemStack:GetDataField(fieldname)
	local item = self:GetItem();
	if(item) then
		if (type(self.serverdata) == "table") then
			return self.serverdata[fieldname];
		end
	end
end

-- set data field to be stored
-- @param fieldname: "tooltip", "durability"
function ItemStack:SetDataField(fieldname, value)
	local item = self:GetItem();
	if(item) then
		if (type(self.serverdata) == "table") then
			self.serverdata[fieldname] = value;
		elseif(value~=nil) then
			self.serverdata = {
				[fieldname] = value;
				[1] = self.serverdata,
			}
		end
	end
end

function ItemStack:GetDataTable()
	return self.serverdata;
end

-- this is the text shown at the right bottom of the icon in pe:slot control. 
-- by default, this is count if bigger than 1, and "" if count is 1
-- if the displayname contains [XXX], text in square brackets will also be displayed. 
function ItemStack:GetIconText()
	local text;
	if(self.count>1) then
		text = tostring(self.count);
	end
	local name = self:GetDisplayName();
	if(name) then
		local icontext = name:match("%[([^%]]+)%]");
		if(icontext) then
			text = icontext..(text or "");
		end
	end
	return text or "";
end

-- get tooltip
function ItemStack:GetTooltip()
	local item = self:GetItem();
	if(item) then
		local tip = self:GetDataField("tooltip")
		if(tip == nil or tip == "") then
			tip = item:GetTooltipFromItemStack(self);
		end
		return tip;
	end
end

function ItemStack:GetDisplayName()
	local item = self:GetItem();
	if(item) then
		local tip = self:GetDataField("tooltip")
		if(tip == nil or tip == "") then
			tip = item:GetDisplayName();
		end
		return tip;
	else
		return "";
	end
end

function ItemStack:SetDisplayName(name)
	self:SetTooltip(name);
end

-- set user defined tooltip. 
function ItemStack:SetTooltip(value)
	self:SetDataField("tooltip", value)
end

-- durablity: do not call this function directly, call :AttemptDamageItem() instead. 
-- only call this function when you are setting an undurable item to become durable via command line, etc. 
function ItemStack:SetDurability(value)
	self:SetDataField("durability", value)
end

-- nil means infinit.
function ItemStack:GetDurability()
	local durablity = self:GetDataField("durability");
	if(not durablity) then
		local item = self:GetItem();
		if(item) then
			durablity = item:GetMaxDamage();
		end
	end
	return durablity;
end

-- true if this itemStack is damageable
function ItemStack:IsItemStackDamageable()
	local item = self:GetItem();
	if(item) then
		return self:GetMaxDamage();
	end
end

-- returns true when a damageable item is damaged
function ItemStack:IsItemDamaged()
    return (self:GetDurability() ~= self:GetMaxDamage());
end

-- Returns the max damage(durabilitt) an item in the stack can take.
function ItemStack:GetMaxDamage()
    local item = self:GetItem();
	if(item) then
		return item:GetMaxDamage() or self:GetDurability();
	end
end

-- Attempts to damage the ItemStack with amount of damage. 
-- Returns true if it takes more damage than GetMaxDamage(). 
-- Returns false otherwise or if the ItemStack can't be damaged
function ItemStack:AttemptDamageItem(amount)
	local durability = self:GetDurability();
    if (durability) then
        if (amount and amount > 0) then
			durability = durability - amount;
			self:SetDurability(durability);
			return durability == 0;
        end
    end
end

-- Damages the item in the ItemStack
function ItemStack:DamageItem(amount, fromEntity)
    if (fromEntity) then
		-- TODO: editor mode not invoking damage? 
        if (self:IsItemStackDamageable()) then
            if (self:AttemptDamageItem(amount)) then
				local isWearingThis;
				if (fromEntity.inventory and fromEntity.inventory.GetItemInRightHand) then
					if(self == fromEntity.inventory:GetItemInRightHand()) then
						isWearingThis = true;
					end
				end
                self.count = self.count - 1;
				if (self.count < 0) then
                    self.count = 0;
                end
                if (self.count == 0) then
                    -- TODO: destroy current equipped item if player is wearing or holding this?
					if(isWearingThis) then
						-- TODO: create break block into pieces animation for block in hand. 
						fromEntity.inventory:NotifyBlockInHandChanged(self.id, 0);
					end
                end
				self:SetDurability(nil);
				if(fromEntity.inventory) then
					fromEntity.inventory:OnInventoryChanged();
				end
            end
        end
    end
end

function ItemStack:CanEditBlocks()
	local item = self:GetItem();
	if(item) then
		return item:CanItemEditBlocks();
	end
end

-- @param side: this is OPPOSITE of the touching side
function ItemStack:TryCreate(entityPlayer, x,y,z, side, data, side_region)
	local item = self:GetItem();
	if(item) then
		local bUsed = item:TryCreate(self, entityPlayer, x,y,z, side, data, side_region);
		if (bUsed) then
			entityPlayer:AddStat(StatList.objectUseStats[self.id], 1);
		end
		return bUsed;
	end
end

 -- Called whenever this item is equipped and the right mouse button is pressed.
-- @return the new item stack to put in the position.
function ItemStack:OnItemRightClick(entityPlayer)
	local item = self:GetItem();
	if(item) then
		return item:OnItemRightClick(self, entityPlayer);
	end
end

