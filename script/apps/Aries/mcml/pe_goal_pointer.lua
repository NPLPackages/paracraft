--[[
Title: goal pointer
Author(s): LiXizhi
Date: 2013/1/10
Desc: 
the goal pointer works as follows:
1. the game system can set the current global goal with some optional paramters. Each goal has a type. 
2. Each goal intance has a current stack level, which start from 1. 
3. There are many places in the user interface that may show the goal UI pointer according to the following rule
	3.1 there is no already shown pointers that has a higher stacklevel then the current goal's current stack level.
	3.2 any finish function may trigger a goal indicator which is one stack level higher than current. 
	3.3 Once a goal is completed (the goal is finished and there is no UI pointer associated with the goal.), all ui pointers are cleared. 
	3.4 there is only one instance of goal pointer in the game. 

---++ Goal DataSource Definition
<!-- UI提示类任务追踪
@param type: 任务目标类型.  config/Quests_[teen]/custom_goal_list.xml 中创建对任务类型的实例。 实例可以有几个参数。
@param finish 字段代表一类目标字段. 有一个Timer， 从后向前找第一个可见的但没有完成finish对象，并高亮这个对象。 
@param custom_goal_client: Boolean 完成时会调用任务系统的custom_goal_client，提交Server端完成Client端任务
@param finish_last: Boolean 需要完成上一部才能执行本步骤， 如果finish字段为close, 则默认finish_last是true
  如果finish代表的UI不在同一个层次上， finish_last一般无需配置。用发参考type="change_card_deck"
@param finish_once: we will only show once when finished. 
-->
<goals>
	<goal type="lottery" priority="-1">
		<step finish="open_mijiuhulu" param1="npc_shop_id"/>
		<step finish="open_lottery"/>
		<step finish="close"/>
	</goal>
</goals>
---++ supported "finish" UI key
"open_auctionhouse": auction house
"open_mijiuhulu": mijiu hulu 
"open_ranking": ranking window

---++ pe:goalpointer
There is zero cost to create pe:goalpointer. it does not create any timer or any UI object. it simply register a region position to goal_manager. 
And use its immediate parent container to decide whether the goalpointer ui object is visible. 

<verbatim>
	<pe:goalpointer listen="open_carddeck" style="position:relative;width:32px;height:32px;"></pe:goalpointer>
	<pe:goalpointer listen="open_npc_shop" match_current_goal="true" param_name1="npc_id" param_value1="123456" style="position:relative;width:32px;height:32px;margin:10px;"></pe:goalpointer>
</verbatim>
| *name* | *desc* |
| match_current_goal | if true, we will match the current. |

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/mcml/pe_goal_pointer.lua");
local goal_manager = commonlib.gettable("MyCompany.Aries.mcml_controls.goal_manager");
goal_manager.SetCurrentGoal("buyitem", {gsid="1912", npc_shop_id="36203", npc_id="36203"});
goal_manager.SetCurrentGoal("buy_any", {npc_shop_id="36203", npc_id="36203"});
goal_manager.SetCurrentGoal("feedpet");
goal_manager.SetCurrentGoal("feedpet_gem");

goal_manager.SetCurrentGoal("addonlevel", {level="1"});
goal_manager.SetCurrentGoal("mount_gem");

goal_manager.SetCurrentGoal("lottery");
goal_manager.SetCurrentGoal("change_card_deck");

-- call this function to preload a world
goal_manager.SetCurrentGoal("world_preloader", {worldname_or_path = "FlamingPhoenixIsland"});

goal_manager.finish("open_lottery");

goal_manager.SetDefaultGoal("currentquest")
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/timer.lua");
local WorldManager = commonlib.gettable("MyCompany.Aries.WorldManager");
local goal_manager = commonlib.gettable("MyCompany.Aries.mcml_controls.goal_manager");

-- mapping from goal type name to goal definition. 
local goal_map = {};
-- the current goal object. 
local cur_goal;
-- register pointers
local pointers = {};

-- parent container of the globally unique pointer name. 
local pointer_ui_name = "pe_goalpointer_cont"
local pointer_cursor_ui_name = "pe_goalpointer_cursor_cont"

-- loading all goals from a config file. 
function goal_manager.Init()
	-- loading from file. 
	if(goal_manager.is_inited) then
		return;
	end
	goal_manager.is_inited = true;

	local filename = if_else(System.options.version=="kids", "config/Aries/Quests/goal_pointer.kids.xml", "config/Aries/Quests_Teen/goal_pointer.teen.xml"); 
	if(not filename) then
		return;
	end
	local xmlRoot = ParaXML.LuaXML_ParseFile(filename);
	if(xmlRoot) then
		goal_manager.has_content = true;
		local node;
		for node in commonlib.XPath.eachNode(xmlRoot, "/goals/goal") do
			if(node.attr and node.attr.type) then
				local goal = {
					name = node.attr.type,
					param1 = node.attr.param1,
					param2 = node.attr.param2,
					onload = node.attr.onload,
				};
				goal_map[goal.name] = goal;
				goal.listen_map = {};
				local subnode;
				local next_stacklevel = 1;
				for subnode in commonlib.XPath.eachNode(node, "/step") do
					local step = subnode.attr;
					if(step.finish) then
						next_stacklevel = tonumber(step.stacklevel) or next_stacklevel;
						step.stacklevel = next_stacklevel;
						step.custom_goal_client = step.custom_goal_client == "true";
						step.finish_last = (step.finish_last == "true");
						step.finish_once = (step.finish_once == "true");
						next_stacklevel = next_stacklevel + 1;
						goal[#goal+1] = step;
						goal.listen_map[step.finish] = step;
					end
				end
			end
		end
		LOG.std(nil, "info", "goal_manager", "loading file: %s", filename);
	end

	goal_manager.SetActive(true);
end

-- call this to temporarily make the goal manager active or not. 
-- @param bEnabled: true or nil to enable  it. 
-- @param time_interval: can be nil which defaults to 300ms. 
function goal_manager.SetActive(bEnabled, time_interval)
	if(goal_manager.has_content) then
		if(bEnabled~=false) then
			goal_manager.mytimer = goal_manager.mytimer or commonlib.Timer:new({callbackFunc = function(timer)
				goal_manager.OnFrameMove(timer);
			end})
			time_interval = time_interval or 300;

			goal_manager.mytimer:Change(0, time_interval);
		else
			if(goal_manager.mytimer) then
				goal_manager.mytimer:Change();
			end
			goal_manager.hide_pointer();
		end
	end
end

-- get goal definition by name
function goal_manager.GetGoal(type_name)
	if(type_name) then
		return goal_map[type_name];
	end
end

-- cur_goal table is returned. cur_goal.params contains additional params from the quest system if any. 
function goal_manager.GetCurrentGoal()
	return cur_goal;
end

-- check if the current goal's params contains a parameter name whose value is value. 
function goal_manager.match_param(name, test_value)
	if(cur_goal and cur_goal.params and cur_goal.params[name] == tostring(test_value)) then
		return true;
	end
end

-- this is the default goal (usually never finished) such as asking the user to click the next goal. 
function goal_manager.SetDefaultGoal(type_name)
	
	if(not cur_goal or cur_goal.name == goal_manager.default_goal_name) then
		-- if there is no current goal or current goal is the last default goal, track the default goal.
		goal_manager.default_goal_name = type_name;
		if(type_name) then
			goal_manager.SetCurrentGoal(goal_manager.default_goal_name, nil, true);
		end
	else
		goal_manager.default_goal_name = type_name;
	end
end

-- set the current goal name
-- @param type_name: 
-- @param params: nil or table of name, value pairs. This is usually the attr of goalpointer tag in custom goal file. 
--  and params.id is a special id which if exists will fire the 
--  MyCompany.Aries.event:DispatchEvent({type = "custom_goal_client"}, params.id); once any step in the goal is finished. 
-- @param force_refresh: force refreshing the quest target. 
function goal_manager.SetCurrentGoal(type_name, params, force_refresh)
	goal_manager.Init();
	local goal = goal_manager.GetGoal(type_name)
	if(goal) then
		local is_same_goal;
		if(cur_goal) then
			if(cur_goal == goal or (cur_goal.id and cur_goal.id == goal.id)) then
				-- two goals are the same or id is the same, ignore it. 
				is_same_goal = true;
			else
				-- TODO: shall we cancel the last goal or not?
			end
		end
		cur_goal = goal;

		if(not commonlib.compare(cur_goal.params, params)) then
			is_same_goal = false;
		end
		-- reset stack level to front;
		if(not is_same_goal or force_refresh) then
			cur_goal.stack_level = 1;
			cur_goal.last_finish = nil;
			cur_goal.params = params;
		end
		
		if(cur_goal.onload) then
			local onload_func = commonlib.getfield(cur_goal.onload);
			if(type(onload_func) == "function") then
				onload_func(cur_goal, params);
			end
		end

		if(params and params.npc_id) then
			-- open the NPC
			local npc_id = tonumber(params.npc_id);
			if(npc_id)then
				WorldManager:GotoNPC(npc_id,function()
					local TargetArea = commonlib.gettable("MyCompany.Aries.Desktop.TargetArea");
					TargetArea.TalkToNPC(npc_id, nil, false);
				end)
			end
		end

		-- activate the goal
		goal_manager.SetActive();

		-- always set to current mouse position. 
		local x, y = goal_manager.GetMousePosition();
		local _parent = ParaUI.GetUIObject(pointer_cursor_ui_name);
		if(not _parent:IsValid()) then
			_parent.translationx, _parent.translationy = goal_manager.GetMousePosition();
			_parent:ApplyAnim();
		end
	end
end

-- this will fix a bug for platform without mouse position. 
function goal_manager.GetMousePosition()
	local x, y = ParaUI.GetMousePosition();
	if(x < 0 ) then
		x = 0;
	end
	if(y < 0 ) then
		y = 0;
	end
	return x,y;
end

-- check if a given named pointer is visible, if so, show it and return true;
function goal_manager.CheckShowPointer(name)
	local mcml_node, parent_ = goal_manager.find_pointer(name);
	if(mcml_node and mcml_node.point_region) then
		local parent_left, parent_top = parent_:GetAbsPosition();
		local left, top, right, bottom = mcml_node.point_region.left, mcml_node.point_region.top, mcml_node.point_region.right, mcml_node.point_region.bottom;
		goal_manager.show_pointer(left+parent_left, top+parent_top, right-left, bottom-top, step, mcml_node);
		return true;
	end
end

-- called every 0.3 second to check if there is a goal.
function goal_manager.OnFrameMove(timer)
	if(cur_goal) then
		local step;
		local stack_level;

		local has_pointer = false;
		-- find the first visible UI 

		local i;
		for i = #cur_goal, 1, -1 do
			local step = cur_goal[i];

			if(cur_goal.last_finish == step.finish) then
				if(i == (#cur_goal-1) and cur_goal[#cur_goal].finish == "close") then
					if(goal_manager.CheckShowPointer("close")) then
						has_pointer = true;
					else
						goal_manager.finish_current_goal()
					end
				end
				break;
			elseif(step.finish ~= "close") then
				if(not step.finish_last or (i>1 and cur_goal[i-1].finish == cur_goal.last_finish)) then
					if(goal_manager.CheckShowPointer(step.finish)) then
						has_pointer = true;
						break;
					end
				end
			end
		end
		if(not has_pointer) then
			goal_manager.hide_pointer();
		end
	else
		goal_manager.SetActive(false)
	end
end

-- do next goal 
function goal_manager.finish_current_goal()
	cur_goal = nil;
	if(goal_manager.default_goal_name)then
		goal_manager.SetCurrentGoal(goal_manager.default_goal_name, nil, true)
	end
end


function goal_manager.show_pointer(left, top, width, height, step, mcml_node)
	-- update the region indicator
	local _parent = ParaUI.GetUIObject(pointer_ui_name);
	if(not _parent:IsValid()) then
		_parent = ParaUI.CreateUIObject("container", pointer_ui_name, "_lt", 0, 0, 64, 64);
		_parent.background = "Texture/Aries/Common/ThemeTeen/animated/btn_anim_32bits_fps10_a012.png";
		_parent.enabled = false;
		_guihelper.SetUIColor(_parent, "#ffffffff");
		_parent:AttachToRoot();
	end

	if(_parent.width~= width or _parent.height~=height) then
		_parent.width = width;
		_parent.height = height;
	end

	_parent.translationx = left;
	_parent.translationy = top;
	_parent.zorder = mcml_node.zorder or 1000;
	_parent.visible = true;

	-- update the cursor indicator
	local _parent = ParaUI.GetUIObject(pointer_cursor_ui_name);
	if(not _parent:IsValid()) then
		local width, height = 82, 32;
		_parent = ParaUI.CreateUIObject("container", pointer_cursor_ui_name, "_lt", 0, 0, width, height);
		_parent.background = "";
		_parent.enabled = false;
		_parent:AttachToRoot();

		NPL.load("(gl)script/kids/3DMapSystemApp/mcml/PageCtrl.lua");
		goal_manager.cursor_my_page = goal_manager.cursor_my_page or Map3DSystem.mcml.PageCtrl:new({url="script/kids/3DMapSystemApp/mcml/test/MyPageControl_UI.html"});

		local mcmlStr;
		if(System.options.version == "teen") then
			mcmlStr = [[<div name="quest_tip_goalpointer" direction="2" style="float:left;position:relative;margin-left:-10px;margin-top:-65px;width:300px;height:32px;" >
				<div style="position:relative;margin-left:15px;margin-top:29px;width:32px;height:32px;background:url(Texture/Aries/Common/ThemeKid/tip/text_tip_arrow_down_32bits.png)" />
				<div style="height:32px;background:url(Texture/Aries/Common/ThemeKid/tip/text_tip_bg_32bits.png:7 7 7 7)">
					<div style="margin-top:4px;margin-left:5px;line-height:20px;text-align:left;font-size:13px;font-weight:bold;text-shadow:true;shadow-quality:8;shadow-color:#60ffffff">点击这里</div>
				</div>
			</div>]];
		else
			mcmlStr = [[<div name="quest_tip_goalpointer" direction="2" style="float:left;position:relative;margin-left:-40px;margin-top:-65px;width:300px;height:32px;" >
				<div style="position:relative;margin-left:45px;margin-top:29px;width:32px;height:32px;background:url(Texture/Aries/Common/ThemeKid/tip/text_tip_arrow_down_32bits.png)" />
				<div style="height:32px;background:url(Texture/Aries/Common/ThemeKid/tip/text_tip_bg_32bits.png:7 7 7 7)">
					<div style="margin-top:4px;margin-left:5px;line-height:20px;font-size:13px;font-weight:bold;text-shadow:true;shadow-quality:8;shadow-color:#60ffffff">点击这里</div>
				</div>
			</div>]];
		end

		local xmlRoot = ParaXML.LuaXML_ParseString(mcmlStr);
		if(type(xmlRoot)=="table" and table.getn(xmlRoot)>0) then
			local xmlRoot = Map3DSystem.mcml.buildclass(xmlRoot);
							
			local myLayout = Map3DSystem.mcml_controls.layout:new();
			myLayout:reset(0, 0, width, height);
			Map3DSystem.mcml_controls.create("pe_goalpointer_cursor_page", xmlRoot, nil, _parent, 0, 0, width, height,nil, myLayout);
		end

		_parent.translationx, _parent.translationy = goal_manager.GetMousePosition();
		_parent:ApplyAnim();
	end
	_parent.zorder = mcml_node.zorder or 1000;
	_parent.visible = true;

	goal_manager.dest_x, goal_manager.dest_y = left, top;

	if(_parent.translationx ~= left or _parent.translationy ~= top) then
		goal_manager.cursor_timer = goal_manager.cursor_timer or commonlib.Timer:new({callbackFunc = function(timer)
			local _parent = ParaUI.GetUIObject(pointer_cursor_ui_name);
			if(goal_manager.dest_x and _parent:IsValid() and _parent.visible) then
				local cur_pt_x, cur_pt_y = _parent.translationx, _parent.translationy;
				local speed = 1; -- pixel per ms 
				if(cur_pt_x ~= goal_manager.dest_x or  cur_pt_y ~= goal_manager.dest_y) then
					local delta = timer:GetDelta();
					local step = (speed*delta);
					if(step >= math.abs(goal_manager.dest_x-cur_pt_x) ) then
						_parent.translationx = goal_manager.dest_x;
					else
						_parent.translationx = step * if_else(cur_pt_x>goal_manager.dest_x, -1, 1)+cur_pt_x;
					end
					if(step >= math.abs(goal_manager.dest_y-cur_pt_y) ) then
						_parent.translationy = goal_manager.dest_y;
					else
						_parent.translationy = step * if_else(cur_pt_y>goal_manager.dest_y, -1, 1)+cur_pt_y;
					end
					_parent:ApplyAnim();
				else
					timer:Change();	
				end
			else
				timer:Change();
			end
		end})
		goal_manager.cursor_timer:Change(30,30);
	end
end

function goal_manager.hide_pointer()
	local _parent = ParaUI.GetUIObject(pointer_ui_name);
	if(_parent:IsValid()) then
		_parent.visible = false;
	end

	local _parent = ParaUI.GetUIObject(pointer_cursor_ui_name);
	if(_parent:IsValid()) then
		_parent.visible = false;
	end
end

-- return the pointer mcmlNode and the parent_ ui object. 
function goal_manager.find_pointer(name)
	local pointer = pointers[name];
	if(pointer and pointer.uiobject_id) then
		local parent_ = ParaUI.GetUIObject(pointer.uiobject_id);
		if(parent_ and parent_:IsValid()) then
			if(parent_:GetAttributeObject():GetField("VisibleRecursive", false)) then
				return pointer, parent_;
			end
		else
			pointers[name] = nil;
		end
	end
end

-- only used by pe_goalpointer
function goal_manager.register_pointer(name, mcml_node)
	pointers[name] = mcml_node;
end

-- finish a given step name
-- it will automatically fire the "custom_goal_client" event if the step has custom_goal_client set to true
function goal_manager.finish(name)
	if(cur_goal) then
		-- find the first visible UI 
		local quest_template_id;
		if(cur_goal.params and cur_goal.params.id) then
			quest_template_id = cur_goal.params.id;
		end
		local i;
		for i = #cur_goal, 1, -1 do
			local step = cur_goal[i];
			if(step.finish == name) then
				cur_goal.last_finish = name;
				if(quest_template_id and step.custom_goal_client) then
					MyCompany.Aries.event:DispatchEvent({type = "custom_goal_client"}, quest_template_id);
				end
			end
		end
	end
end

-----------------------------------
-- pe:goalpointer control
-----------------------------------
local pe_goalpointer = commonlib.gettable("MyCompany.Aries.mcml_controls.pe_goalpointer");

function pe_goalpointer.render_callback(mcmlNode, rootName, bindingContext, _parent, left, top, width, height, myLayout, css)
	-- listen for a given target. 
	local listen = mcmlNode:GetAttributeWithCode("listen", nil, true);

	-- for inner nodes
	-- mcmlNode:DrawChildBlocks_Callback(rootName, bindingContext, _parent, left, top, width, height, myLayout, css)
	mcmlNode.uiobject_id = _parent.id;
	mcmlNode.point_region = {left=left, top=top, right=width, bottom=height};
	mcmlNode.zorder = mcmlNode:GetNumber("zorder");

	local can_register = true;

	local i;
	for i = 1, 3 do 
		local param_name = mcmlNode:GetAttributeWithCode("param_name"..tostring(i), nil, true);
		if(param_name) then
			local param_value = mcmlNode:GetAttributeWithCode("param_value"..tostring(i), nil, true);
			if(param_value) then
				if(cur_goal and cur_goal.params and cur_goal.params[param_name] == tostring(param_value)) then
					-- only register if all parameters matches the current goal's parameter.
				else
					can_register = false;
				end
			end
		else
			break;
		end
	end
	
	if(can_register and listen and listen~="") then
		goal_manager.register_pointer(listen, mcmlNode);
	end

	return true, true, true; -- ignore_onclick, ignore_background, ignore_tooltip;
end

function pe_goalpointer.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	return mcmlNode:DrawDisplayBlock(rootName, bindingContext, _parent, left, top, width, height, parentLayout, style, pe_goalpointer.render_callback);
end

