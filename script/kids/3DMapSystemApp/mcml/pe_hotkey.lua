--[[
Title: Hot key 
Author(s): LiXizhi
Date: 2013/1/16
Desc: we can define a hot key hook function so that when the parent container of the tag node is visible, the key defined can trigger a given function. 
use the lib:

---++ pe:hotkey
Attributes:
| Name|  Description |
| hotkey	|  the virtual key name such as "DIK_A, DIK_F1, DIK_SPACE" |
| combokey	|   |
| onclick	| function(dik_key)  end | 

---+++ Examples
<verbatim>
    <pe:hotkey name="2" hotkey="DIK_X" onclick="echo"/>
</verbatim>

-------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_hotkey.lua");
local hotkey_manager = commonlib.gettable("Map3DSystem.mcml_controls.hotkey_manager");

hotkey_manager.register_key(hotkey, mcml_node, uiobject_id)
hotkey_manager.register_key(hotkey, function() end, uiobject_id)

-- the game key handler should call this function to enable 
hotkey_manager.handle_key_event(virtual_key)
-------------------------------------------------------
]]
local hotkey_manager = commonlib.gettable("Map3DSystem.mcml_controls.hotkey_manager");

local key_map = {};

function hotkey_manager.Hook()
end

function hotkey_manager.Unhook()
end

function hotkey_manager.handle_key_event(virtual_key)
	local dik_key = VirtualKeyToScaneCodeStr[virtual_key];
	local mcml_node = hotkey_manager.find_key(dik_key)
	if(mcml_node) then
		if(mcml_node.hotkey_func) then
			return mcml_node.hotkey_func(dik_key);
		else
			local onclick = mcml_node:GetAttributeWithCode("onclick");
			if(onclick) then
				return Map3DSystem.mcml_controls.OnPageEvent(mcml_node, onclick, dik_key);
			end
		end
	end
end

-- return the key mcmlNode
function hotkey_manager.find_key(key)
	local mcml_node = key_map[key];
	if(mcml_node and mcml_node.uiobject_id) then
		local parent_ = ParaUI.GetUIObject(mcml_node.uiobject_id);
		if(parent_ and parent_:IsValid()) then
			if(parent_:GetAttributeObject():GetField("VisibleRecursive", false)) then
				return mcml_node;
			end
		else
			mcml_node[key] = nil;
		end
	end
end

-- only used by pe_goalpointer
-- @param mcml_node: mcml_node. this may also be a function. 
function hotkey_manager.register_key(hotkey, mcml_node, uiobject_id)
	if(type(mcml_node) == "function" and uiobject_id) then
		mcml_node = {hotkey_func = mcml_node, uiobject_id = uiobject_id}
	end
	if(type(mcml_node) == "table") then
		key_map[hotkey] = mcml_node;
	end
end

---------------------------
-- pe:hotkey
---------------------------
local pe_hotkey = commonlib.gettable("Map3DSystem.mcml_controls.pe_hotkey");

function pe_hotkey.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local hotkey = mcmlNode:GetAttributeWithCode("hotkey", nil, true);
	local combokey = mcmlNode:GetAttributeWithCode("combokey", nil, true);

	mcmlNode.uiobject_id = _parent.id;

	local onclick = mcmlNode:GetAttributeWithCode("onclick");
	if(hotkey and onclick) then
		hotkey_manager.register_key(hotkey, mcmlNode);
	end
end
