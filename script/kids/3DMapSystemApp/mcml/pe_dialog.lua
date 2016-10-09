--[[
Title: all controls for NPC dialog
Author(s): WangTian
Date: 2009/6/20
Change history: 
		2009/7/24: prepareaction is added to provide asynchronous call before answer take place
Desc: 

---++ pe:dialog

Place a dialog box on the screen and contains different states to render the inner content according to different states.
Only one dialog will be displayed at a time, so if the another dialog is shown, former dialog box is closed.
 
Attributes:

| Required | Name | Type | Description |
| required | NPC_id | int | id of the NPC |
| required | width | int | width in pixel |
| required | height | int | height in pixel |
| optional | position | string | can be "middle", "scene", "bottom" default to middle |
| required | entryaction | function | function that called before state entry entryaction(from, to) |
| required | exitaction | function | function that called after state exit exitaction(from, to) |


---+++ Examples

<verbatim>

<pe:dialog NPC_id = "10" width = "480" height = "480">
	<pe:state id = "0" entryaction="" exitaction="">
		<pe:answer autoexec = "true">
			<pe:answer-if condition = "hasGSItem(10106)" target_state = "1"/>
			<pe:answer-if condition = "not hasGSItem(10106) and (equipGSItem(21001) or equipGSItem(21002) or equipGSItem(21003))" target_state = "2"/>
			<pe:answer-if condition = "not hasGSItem(10106) and not equipGSItem(21001) and not equipGSItem(21002) and not equipGSItem(21003))" target_state = "3"/>
			<pe:answer-if condition = "not hasGSItem(10106) and (hasGSItem(21001) or hasGSItem(21002) or hasGSItem(21003)) and not equipGSItem(21001) and not equipGSItem(21002) and not equipGSItem(21003))" target_state = "4"/>
			<pe:answer-if condition = "not hasGSItem(10106) and (equipGSItem(21001) or equipGSItem(21002) or equipGSItem(21003))" target_state = "5"/>
			<pe:answer-if condition = "" target_state = ""/>
		</pe:answer>
	</pe:state>
	<pe:state id = "1">
		Has already own the pet
		<pe:answer>
			<pe:answer-if condition = "true" target_state = "-1"/>
		</pe:answer>
	</pe:state>
	<pe:state id = "2">
		Can i have the acinus?
		<pe:answer value = "yes">
			<pe:answer-if condition = "equipGSItem(21001)" target_state = "5"/>
			<pe:answer-if condition = "not equipGSItem(21001)" target_state = "6"/>
		</pe:answer>
		<pe:answer value = "no">
			<pe:answer-if condition = "true" target_state = "-1"/>
		</pe:answer>
	</pe:state>
	<pe:state id = "3">
		Can you find me a acinus in the dark forest?
		<pe:answer>
			<pe:answer-if condition = "true" target_state = "-1"/>
		</pe:answer>
	</pe:state>
	<pe:state id = "4">
		I can taste the smell of acinus on you. Can you feed me with it?
		<pe:answer>
			<pe:answer-if condition = "true" target_state = "-1"/>
		</pe:answer>
	</pe:state>
	<pe:state id = "5">
		I'm a cute husky, do you want to adopt me?
		<pe:answer value="yes">
			<pe:answer-if condition = "true" target_state = "7"/>
		</pe:answer>
		<pe:answer value="no">
			<pe:answer-if condition = "true" target_state = "-1"/>
		</pe:answer>
	</pe:state>
	<pe:state id = "6">
		I hate the smell of the red acinus!
		<pe:answer>
			<pe:answer-if condition = "true" target_state = "-1"/>
		</pe:answer>
	</pe:state>
	<pe:state id = "7">
		<pe:answer autoexec = "true">
			<pe:answer-if condition = "true" target_state = "-1"/>
		</pe:answer>
	</pe:state>
</pe:dialog>

</verbatim>

---++ pe:state

Each pe:state represents a display content of the parent pe:dialog. It can have several pe:answers as the transitions between states
pe:dialog is inited with state = 0, and ends with state = -1.

Attributes:

| Required | Name | Type | Description |
| required | id | int | state id |

---++ pe:answer

Attributes:

| Required | Name | Type | Description |
| required | id | int | state id |
| optional | autoexec | bool | if the answer is automatically executed when enter state, default to false |
| optional | prepareaction | function | this is a special function that provides asynchronous call prepareaction(answervalue, continue)\
			"answervalue: is the value of the pe:answer "continue" is a function that should be called after any asynchronous call\
			NOTE that prepareaction GUARANTEE the continue function is called\
			all related sibling pe:answer are all disabled in case of additional state switching\
			NOTE: Please DONOT refresh the page with prepareaction, previous ui will be replaced by the latter one, if it's an async call|

Each pe:answer is a button on the dialog canvas. Each answer will check the conditions of the user and transit to another state

---++ pe:answer-condition

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_dialog.lua");
-------------------------------------------------------
]]
if(not Map3DSystem.mcml_controls) then Map3DSystem.mcml_controls = {}; end

----------------------------------------------------------------------
-- pe:dialog: handles MCML tag <pe:dialog>
----------------------------------------------------------------------
local pe_dialog = commonlib.gettable("Map3DSystem.mcml_controls.pe_dialog");
function pe_dialog.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	if(mcmlNode:GetAttribute("display") == "none") then return end

	local myLayout,css;
	local padding_left, padding_top, padding_bottom, padding_right;
	local margin_left, margin_top, margin_bottom, margin_right;
	local availWidth, availHeight;
	local maxWidth, maxHeight;
	local bUseSpace; 
	local instName;

	-- if there is a dialog and TargetArea is visible, disable TargetArea to avoid 2 portraits displayed. Added by Spring: 2010.9.2
	local _targetArea = ParaUI.GetUIObject("TargetArea");
	if(_targetArea:IsValid() == true) then
		if(_targetArea.visible == true) then
			_targetArea.visible = false;
		end		
	end
	-- dialog template is added by LiXizhi: 2010.8.28
	local dialog_template = mcmlNode:GetChild("pe:template");
	if(dialog_template) then
		mcmlNode.dialog_template = dialog_template;
	else
		-- clone and merge new style if the node has css style property
		css = mcmlNode:GetStyle(Map3DSystem.mcml_controls.pe_html.css["pe:dialog"]) or {};
		if(style) then
			-- pass through some css styles from parent. 
			css.color = css.color or style.color;
			css["font-family"] = css["font-family"] or style["font-family"];
			css["font-size"] = css["font-size"] or style["font-size"];
			css["font-weight"] = css["font-weight"] or style["font-weight"];
			css["text-shadow"] = css["text-shadow"] or style["text-shadow"];
		end
		padding_left, padding_top, padding_bottom, padding_right = 
			(css["padding-left"] or css["padding"] or 0),(css["padding-top"] or css["padding"] or 0),
			(css["padding-bottom"] or css["padding"] or 0),(css["padding-right"] or css["padding"] or 0);
		margin_left, margin_top, margin_bottom, margin_right = 
			(css["margin-left"] or css["margin"] or 0),(css["margin-top"] or css["margin"] or 0),
			(css["margin-bottom"] or css["margin"] or 0),(css["margin-right"] or css["margin"] or 0);	
	
		availWidth, availHeight = parentLayout:GetPreferredSize();
		maxWidth, maxHeight = parentLayout:GetMaxSize();
		if(css["max-width"]) then
			local max_width = css["max-width"];
			if(max_width) then
				if(maxWidth>max_width) then
					local left, top, right, bottom = parentLayout:GetAvailableRect();
					-- align at center. 
					if(mcmlNode:GetAttribute("align")=="center") then
						left = left + (maxWidth - max_width)/2
					elseif(mcmlNode:GetAttribute("align")=="right") then
						left = right - max_width;
					end	
					right = left + max_width
					parentLayout:reset(left, top, right, bottom);
				end
			end
		end
	
		width, height = mcmlNode:GetAttribute("width"), mcmlNode:GetAttribute("height");
		if(width) then
			css.width = tonumber(string.match(width, "%d+"));
			if(css.width and string.match(width, "%%$")) then
				css.width=math.floor((maxWidth-margin_left-margin_right)*css.width/100);
				if(availWidth<(css.width+margin_left+margin_right)) then
					css.width=availWidth-margin_left-margin_right;
				end
				if(css.width<=0) then
					css.width = nil;
				end
			end	
		end
		if(height) then
			css.height = tonumber(string.match(height, "%d+"));
			if(css.height and string.match(height, "%%$")) then
				css.height=math.floor((maxHeight-margin_top-margin_bottom)*css.height/100);
				if(availHeight<(css.height+margin_top+margin_bottom)) then
					css.height=availHeight-margin_top-margin_bottom;
				end
				if(css.height<=0) then
					css.height = nil;
				end
			end	
		end
	
		-- whether this control takes up space
		if(css.float) then
			if(css.width) then
				if(availWidth<(css.width+margin_left+margin_right)) then
					parentLayout:NewLine();
				end
			end	
		else
			parentLayout:NewLine();
		end
		myLayout = parentLayout:clone();
		myLayout:SetUsedSize(0,0);
	
		if(css.position == "absolute") then
			-- absolute positioning in parent
			myLayout:SetPos(css.left, css.top);
		elseif(css.position == "relative") then
			-- relative positioning in next render position. 
			myLayout:OffsetPos(css.left, css.top);
		else
			myLayout:OffsetPos(css.left, css.top);
			bUseSpace = true;	
		end
	
		left,top = myLayout:GetAvailablePos();
		myLayout:SetPos(left,top);
		width,height = myLayout:GetSize();
	
		if(css.width) then
			myLayout:IncWidth(left+margin_left+margin_right+css.width-width)
		end
	
		if(css.height) then
			myLayout:IncHeight(top+margin_top+margin_bottom+css.height-height)
		end	
	
		-- for inner control preferred size
		myLayout:OffsetPos(margin_left+padding_left, margin_top+padding_top);
		myLayout:IncWidth(-margin_right-padding_right)
		myLayout:IncHeight(-margin_bottom-padding_bottom)	
	
		if(css.headimage) then
			local headimagewidth = css.headimagewidth or 16;
			myLayout:OffsetPos(headimagewidth+3, nil);
		
			-- reference image is 20 pixel
			local _this=ParaUI.CreateUIObject("button","b","_lt", left+margin_left, top+margin_top+(20-headimagewidth)/2, headimagewidth, headimagewidth);
			_this.background = css.headimage;
			_guihelper.SetUIColor(_this, "255 255 255");
			_parent:AddChild(_this);
		end
		
		if(not css.background or css.background=="") then
			if(mcmlNode:GetAttribute("name") or mcmlNode:GetAttribute("id")) then
				-- this is solely for giving a global name to inner text control so that it can be animated
				instName = mcmlNode:GetInstanceName(rootName);
			end	
		end
	end

	local entryaction = mcmlNode:GetAttributeWithCode("entryaction");
	if(entryaction) then
		local pageCtrl = mcmlNode:GetPageCtrl();
		if(not pageCtrl) then return end
		mcmlNode.entryaction = function(from_state_id, to_state_id)
			if(type(entryaction) == "string") then
				return pageCtrl:CallMethod(entryaction, "entryaction", from_state_id, to_state_id)
			elseif(type(entryaction) == "function") then
				entryaction(from_state_id, to_state_id)
			end
		end
	end
	local exitaction = mcmlNode:GetAttributeWithCode("exitaction");
	if(exitaction) then
		local pageCtrl = mcmlNode:GetPageCtrl();
		if(not pageCtrl) then return end
		mcmlNode.exitaction = function(from_state_id, to_state_id)
			if(type(exitaction) == "string") then
				return pageCtrl:CallMethod(exitaction, "exitaction", from_state_id, to_state_id)
			elseif(type(exitaction) == "function") then
				exitaction(from_state_id, to_state_id)
			end
		end
	end
	
	local state_id = mcmlNode:GetNumber("state_id");
	if(state_id == nil) then
		state_id = 0;
		state_id = pe_dialog.SetState(mcmlNode, 0, false);
		if(state_id~=0) then
			return;
		end
	end
	
	local childnode;
	
	for childnode in mcmlNode:next() do
		if(type(childnode)~="table" or (childnode.name == "pe:state" and childnode:GetNumber("id") ~= state_id)) then
			-- skip rendering the state
		else
			if(dialog_template) then
				-- assign the current pe:state node as the source_node field of the pe:holderplace whose source attribute is "pe:state"
				if(childnode.name == "pe:state") then
					local placeholderNode = dialog_template:SearchChildByAttribute("source", "{pe:state}");
					if(placeholderNode) then
						placeholderNode.source_node = childnode;
						childnode.use_template = true;
					end
				end
			else
				-- render rest of the mcml nodes
				local left, top, width, height = myLayout:GetPreferredRect();
				Map3DSystem.mcml_controls.create(rootName, childnode, bindingContext, _parent, left, top, width, height, 
					{instName = instName, color = css.color, 
					["font-family"] = css["font-family"],  ["font-size"]=css["font-size"], ["font-weight"] = css["font-weight"], 
					["text-align"] = css["text-align"], ["text-shadow"] = css["text-shadow"]
				}, myLayout);
			end
		end
	end
	if(not dialog_template) then
		local left, top = parentLayout:GetAvailablePos();
		local width, height = myLayout:GetUsedSize()
		width = width + padding_right + margin_right
		height = height + padding_bottom + margin_bottom
		if(css.width) then
			width = left + css.width + margin_left+margin_right;
		end	
		if(css.height) then
			height = top + css.height + margin_top+margin_bottom;
		end
	
		if(bUseSpace) then
			parentLayout:AddObject(width-left, height-top);
			if(not css.float) then
				parentLayout:NewLine();
			end	
		end
		if(css.background and css.background~="") then
			local instName;
			if(mcmlNode:GetAttribute("name") or mcmlNode:GetAttribute("id")) then
				-- this is solely for giving a global name to background image control so that it can be animated
				-- background image control is mutually exclusive with inner text control. hence if there is a background, inner text becomes anonymous
				instName = mcmlNode:GetInstanceName(rootName);
			end	

			local _this=ParaUI.CreateUIObject("button",instName or "b","_lt", left+margin_left, top+margin_top, width-left-margin_left-margin_right, height-top-margin_top-margin_bottom);
			_this.background = css.background;
			_this.enabled = false;
			if(css["background-color"]) then
				_guihelper.SetUIColor(_this, css["background-color"]);
			else
				_guihelper.SetUIColor(_this, "255 255 255 255");
			end	
			if(css["background-rotation"]) then
				_this.rotation = tonumber(css["background-rotation"])
			end
			_parent:AddChild(_this);
			_this:BringToBack();
		end	
	
		---- call onload(mcmlNode) function if any. 
		--local entryactionFunc = mcmlNode:GetString("entryaction");
		--local exitactionFunc = mcmlNode:GetString("exitaction");
	
		--if(onloadFunc and onloadFunc~="") then
			--Map3DSystem.mcml_controls.pe_script.BeginCode(mcmlNode);
			--local pFunc = commonlib.getfield(onloadFunc);
			--if(type(pFunc) == "function") then
				--pFunc(mcmlNode);
			--else
				--log(string.format("warning: %s node's onload call back: %s is not a valid function.\n", mcmlNode.name, onloadFunc))	
			--end
			--Map3DSystem.mcml_controls.pe_script.EndCode(rootName, mcmlNode, bindingContext, _parent, left, top, width, height,style, parentLayout);
		--end
	end

	if(dialog_template) then
		-- we will use template for dialog display
		Map3DSystem.mcml_controls.pe_template.create(rootName, dialog_template, bindingContext, _parent, left, top, width, height, style, parentLayout)
	end
end

-- set the dialog node with the target_state
-- @param _dialogNode: dialog mcmlNode
-- @param target_state: target state
-- @param autoRefresh: automatically refresh the pageCtrl, default to true
-- NOTE: if the current state is the same as the target_state, it will return
-- NOTE: page control will be automatically refreshed
-- @return target state, if the state includes an autoexec answer, then it will return the final target state
function pe_dialog.SetState(_dialogNode, target_state, autoRefresh)
	if(_dialogNode) then
		local state_id = _dialogNode:GetNumber("state_id");
		if(state_id == target_state) then
			log("error: set with the same pe_dialog.SetState\n")
			return;
		end
		if(state_id == nil) then
			_dialogNode:SetAttribute("state_id", target_state);
			if(_dialogNode.entryaction) then
				_dialogNode.entryaction(-1, target_state);
			end
		elseif(target_state == -1) then
			_dialogNode:SetAttribute("state_id", target_state);
			if(_dialogNode.exitaction) then
				_dialogNode.exitaction(state_id, -1);
			end
			-- automatically close the page control
			local pageCtrl = _dialogNode:GetPageCtrl();
			pageCtrl:CloseWindow();
			return -1;
		else
			_dialogNode:SetAttribute("state_id", target_state);
			if(_dialogNode.entryaction) then
				_dialogNode.entryaction(state_id, target_state);
			end
			if(_dialogNode.exitaction) then
				_dialogNode.exitaction(state_id, target_state);
			end
		end
		local _stateNode;
		for _stateNode in _dialogNode:next() do
			if(_stateNode.name == "pe:state" and target_state == _stateNode:GetNumber("id")) then
				local _answerNode;
				for _answerNode in _stateNode:next() do
					if(type(_answerNode) ~= "string" and _answerNode.name == "pe:answer" and _answerNode:GetBool("autoexec") == true) then
						function continue()
							local _answerifNode;
							for _answerifNode in _answerNode:next() do
								local _condition = _answerifNode:GetAttributeWithCode("condition");
								if(type(_condition) == "function") then
									_condition = _condition();
								end
								if(_condition == true or _condition == "true") then
									local target_target_state = tonumber(_answerifNode:GetAttribute("target_state"));
									if(target_target_state and target_target_state ~= target_state) then
										-- call transition function if valid
										local transition_func = _answerifNode:GetAttributeWithCode("transition",nil,true);
										if(transition_func) then
											local pageCtrl = _dialogNode:GetPageCtrl();
											if(pageCtrl) then
												if(type(transition_func) == "string") then
													pageCtrl:CallMethod(transition_func, "transition_func", target_state, target_target_state)
												elseif(type(transition_func) == "function") then
													transition_func(target_state, target_target_state)
												end
											end
										end
										-- transit to the target state and automatically refresh the pageCtrl
										target_state = pe_dialog.SetState(_dialogNode, target_target_state, true);
									end
									break;
								end
							end
						end
						local prepareaction = _answerNode:GetAttributeWithCode("prepareaction");
						if(prepareaction and type(prepareaction) == "function") then
							-- disable all inputs
							local _answerNodeNode;
							for _answerNodeNode in _stateNode:next() do
								if(type(_answerNodeNode) ~= "string" and _answerNodeNode.name == "pe:answer") then
									if(_answerNodeNode.uiobject_id) then
										local _btn = ParaUI.GetUIObject(_answerNodeNode.uiobject_id);
										if(_btn and _btn:IsValid() == true) then
											_btn.enabled = false;
										end
									end
									_answerNodeNode:SetAttribute("enabled", false);
								end
							end
							prepareaction(_answerNode:GetAttributeWithCode("value"), continue);
						else
							continue();
						end
						break;
					end
				end
				break;
			end
		end
		if(autoRefresh == true or autoRefresh == nil) then
			-- automatically refresh the dialog page control
			local pageCtrl = _dialogNode:GetPageCtrl();
			pageCtrl:Refresh(0.1);
		end
		return target_state;
	end
end

----------------------------------------------------------------------
-- pe:state: handles MCML tag <pe:state>
----------------------------------------------------------------------
local pe_state = commonlib.gettable("Map3DSystem.mcml_controls.pe_state");
function pe_state.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	if(mcmlNode:GetAttribute("display") == "none") then return end
	
	-- clone and merge new style if the node has css style property
	local css = mcmlNode:GetStyle(Map3DSystem.mcml_controls.pe_html.css["pe:dialog"]) or {};
	if(style) then
		-- pass through some css styles from parent. 
		css.color = css.color or style.color;
		css["font-family"] = css["font-family"] or style["font-family"];
		css["font-size"] = css["font-size"] or style["font-size"];
		css["base-font-size"] = css["base-font-size"] or style["base-font-size"];
		css["font-weight"] = css["font-weight"] or style["font-weight"];
		css["text-shadow"] = css["text-shadow"] or style["text-shadow"];
	end
	local padding_left, padding_top, padding_bottom, padding_right = 
		(css["padding-left"] or css["padding"] or 0),(css["padding-top"] or css["padding"] or 0),
		(css["padding-bottom"] or css["padding"] or 0),(css["padding-right"] or css["padding"] or 0);
	local margin_left, margin_top, margin_bottom, margin_right = 
		(css["margin-left"] or css["margin"] or 0),(css["margin-top"] or css["margin"] or 0),
		(css["margin-bottom"] or css["margin"] or 0),(css["margin-right"] or css["margin"] or 0);	
	
	local availWidth, availHeight = parentLayout:GetPreferredSize();
	local maxWidth, maxHeight = parentLayout:GetMaxSize();
	if(css["max-width"]) then
		local max_width = css["max-width"];
		if(max_width) then
			if(maxWidth>max_width) then
				local left, top, right, bottom = parentLayout:GetAvailableRect();
				-- align at center. 
				if(mcmlNode:GetAttribute("align")=="center") then
					left = left + (maxWidth - max_width)/2
				elseif(mcmlNode:GetAttribute("align")=="right") then
					left = right - max_width;
				end	
				right = left + max_width
				parentLayout:reset(left, top, right, bottom);
			end
		end
	end
	
	local width, height = mcmlNode:GetAttribute("width"), mcmlNode:GetAttribute("height");
	if(width) then
		css.width = tonumber(string.match(width, "%d+"));
		if(css.width and string.match(width, "%%$")) then
			css.width=math.floor((maxWidth-margin_left-margin_right)*css.width/100);
			if(availWidth<(css.width+margin_left+margin_right)) then
				css.width=availWidth-margin_left-margin_right;
			end
			if(css.width<=0) then
				css.width = nil;
			end
		end	
	end
	if(height) then
		css.height = tonumber(string.match(height, "%d+"));
		if(css.height and string.match(height, "%%$")) then
			css.height=math.floor((maxHeight-margin_top-margin_bottom)*css.height/100);
			if(availHeight<(css.height+margin_top+margin_bottom)) then
				css.height=availHeight-margin_top-margin_bottom;
			end
			if(css.height<=0) then
				css.height = nil;
			end
		end	
	end
	
	-- whether this control takes up space
	local bUseSpace; 
	if(css.float) then
		if(css.width) then
			if(availWidth<(css.width+margin_left+margin_right)) then
				parentLayout:NewLine();
			end
		end	
	else
		parentLayout:NewLine();
	end
	local myLayout = parentLayout:clone();
	myLayout:SetUsedSize(0,0);
	
	if(css.position == "absolute") then
		-- absolute positioning in parent
		myLayout:SetPos(css.left, css.top);
	elseif(css.position == "relative") then
		-- relative positioning in next render position. 
		myLayout:OffsetPos(css.left, css.top);
	else
		myLayout:OffsetPos(css.left, css.top);
		bUseSpace = true;	
	end
	
	left,top = myLayout:GetAvailablePos();
	myLayout:SetPos(left,top);
	width,height = myLayout:GetSize();
	
	if(css.width) then
		myLayout:IncWidth(left+margin_left+margin_right+css.width-width)
	end
	
	if(css.height) then
		myLayout:IncHeight(top+margin_top+margin_bottom+css.height-height)
	end	
	
	-- for inner control preferred size
	myLayout:OffsetPos(margin_left+padding_left, margin_top+padding_top);
	myLayout:IncWidth(-margin_right-padding_right)
	myLayout:IncHeight(-margin_bottom-padding_bottom)	
	
	if(css.headimage) then
		local headimagewidth = css.headimagewidth or 16;
		myLayout:OffsetPos(headimagewidth+3, nil);
		
		-- reference image is 20 pixel
		local _this=ParaUI.CreateUIObject("button","b","_lt", left+margin_left, top+margin_top+(20-headimagewidth)/2, headimagewidth, headimagewidth);
		_this.background = css.headimage;
		_guihelper.SetUIColor(_this, "255 255 255");
		_parent:AddChild(_this);
	end
	
	local instName;
	if(not css.background or css.background=="") then
		if(mcmlNode:GetAttribute("name") or mcmlNode:GetAttribute("id")) then
			-- this is solely for giving a global name to inner text control so that it can be animated
			instName = mcmlNode:GetInstanceName(rootName);
		end	
	end
	
	local childnode;
	for childnode in mcmlNode:next() do
		local left, top, width, height = myLayout:GetPreferredRect();
		Map3DSystem.mcml_controls.create(rootName, childnode, bindingContext, _parent, left, top, width, height, 
				{instName = instName, color = css.color, 
				["font-family"] = css["font-family"],  ["font-size"]=css["font-size"], ["font-weight"] = css["font-weight"], 
				["text-align"] = css["text-align"], ["text-shadow"] = css["text-shadow"], ["base-font-size"]=css["base-font-size"]
			}, myLayout);
	end
	
	local left, top = parentLayout:GetAvailablePos();
	local width, height = myLayout:GetUsedSize()
	width = width + padding_right + margin_right
	height = height + padding_bottom + margin_bottom
	if(css.width) then
		width = left + css.width + margin_left+margin_right;
	end	
	if(css.height) then
		height = top + css.height + margin_top+margin_bottom;
	end
	
	if(bUseSpace) then
		parentLayout:AddObject(width-left, height-top);
		if(not css.float) then
			parentLayout:NewLine();
		end	
	end
	if(css.background and css.background~="") then
		local instName;
		if(mcmlNode:GetAttribute("name") or mcmlNode:GetAttribute("id")) then
			-- this is solely for giving a global name to background image control so that it can be animated
			-- background image control is mutually exclusive with inner text control. hence if there is a background, inner text becomes anonymous
			instName = mcmlNode:GetInstanceName(rootName);
		end	

		local _this=ParaUI.CreateUIObject("button",instName or "b","_lt", left+margin_left, top+margin_top, width-left-margin_left-margin_right, height-top-margin_top-margin_bottom);
		_this.background = css.background;
		_this.enabled = false;
		if(css["background-color"]) then
			_guihelper.SetUIColor(_this, css["background-color"]);
		else
			_guihelper.SetUIColor(_this, "255 255 255 255");
		end	
		if(css["background-rotation"]) then
			_this.rotation = tonumber(css["background-rotation"])
		end
		_parent:AddChild(_this);
		_this:BringToBack();
	end	
end

----------------------------------------------------------------------
-- pe:answer: handles MCML tag <pe:answer>
----------------------------------------------------------------------
local pe_answer = commonlib.gettable("Map3DSystem.mcml_controls.pe_answer");
-- a mapping from answer name to mcml node instance.
pe_answer.answer_instances = {};

function pe_answer.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local stateNode = mcmlNode:GetParent("pe:state");
	if(not stateNode) then
		return
	end
	if(stateNode.use_template) then	
		if(mcmlNode.use_template) then
			-- render normally
			mcmlNode.use_template = nil;
		else
			-- add this node to template
			local template_id = mcmlNode:GetAttribute("template_id");
			if(template_id) then
				local dialogNode = stateNode:GetParent("pe:dialog");
				if(dialogNode) then
					local dialog_template = dialogNode.dialog_template;
					if(dialog_template) then
						local placeholderNode = dialog_template:SearchChildByAttribute("id", template_id);
						if(placeholderNode) then
							placeholderNode.source_node = mcmlNode;
						else
							-- tricky: we will add a default placeholder node with the matching id if no one is provided. 
							placeholderNode = Map3DSystem.mcml.new(nil, {name="pe:placeholder", attr={id=template_id}});
							dialog_template:AddChild(placeholderNode);
						end
					end
				end
			end
			return;
		end
	end
	mcmlNode.onclickscript = "Map3DSystem.mcml_controls.pe_answer.OnGeneralClick";
	Map3DSystem.mcml_controls.pe_editor_button.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout);
end

-- user clicks the button yet without form info
-- the callback function format is function(buttonName, mcmlNode) end
function pe_answer.OnGeneralClick(buttonName, mcmlNode)
	if(not mcmlNode) then
		return 
	end
	
	-- check for answer conditions one by one
	local _dialogNode = mcmlNode:GetParent("pe:dialog");
	local _stateNode = mcmlNode:GetParent("pe:state");
	local state_id;
	if(_dialogNode) then
		state_id = _dialogNode:GetAttribute("state_id");
			
		local function continue()		
			local childnode;
			for childnode in mcmlNode:next() do
				if(childnode.name == "pe:answer-if") then
					local _condition = childnode:GetAttributeWithCode("condition",nil,true);
					if(type(_condition) == "function") then
						_condition = _condition();
					end
					if(_condition == true or _condition == "true") then
						local target_state = tonumber(childnode:GetAttribute("target_state"));
						if(target_state and target_state ~= state_id) then
							-- call transition function if valid
							local transition_func = childnode:GetAttributeWithCode("transition",nil,true);
							if(transition_func) then
								local pageCtrl = childnode:GetPageCtrl();
								if(pageCtrl) then
									if(type(transition_func) == "string") then
										pageCtrl:CallMethod(transition_func, "transition_func", state_id, target_state)
									elseif(type(transition_func) == "function") then
										transition_func(state_id, target_state)
									end
								end
							end	
							-- transit to the target state and automatically refresh the pageCtrl
							pe_dialog.SetState(_dialogNode, target_state, true);
							return;
						end
					end
				end
			end
		end
		local prepareaction = mcmlNode:GetAttributeWithCode("prepareaction");
		if(prepareaction and type(prepareaction) == "function") then
			-- disable all inputs
			local _answerNodeNode;
			for _answerNodeNode in _stateNode:next() do
				if(type(_answerNodeNode) ~= "string" and _answerNodeNode.name == "pe:answer") then
					if(_answerNodeNode.uiobject_id) then
						local _btn = ParaUI.GetUIObject(_answerNodeNode.uiobject_id);
						if(_btn and _btn:IsValid() == true) then
							_btn.enabled = false;
						end
					end
					_answerNodeNode:SetAttribute("enabled", false);
				end
			end
			prepareaction(mcmlNode:GetAttributeWithCode("value"), continue);
		else
			continue();
		end
	end
		
	local _dialogNode = mcmlNode:GetParent("pe:dialog");
	local _stateNode = mcmlNode:GetParent("pe:state");
		
	local state_id = _dialogNode:GetAttribute("state_id");
		
	--pe_answer.GetEntryAction(mcmlNode);
	--pe_answer.GetExitAction(mcmlNode);
	--Map3DSystem.mcml_controls.OnPageEvent(mcmlNode, callback, buttonName, mcmlNode);
end

---- get the entryaction callback function
--function pe_answer.GetEntryAction(mcmlNode)
	--if(mcmlNode) then
	--end
--end
--
---- get the exitaction callback function
--function pe_answer.GetExitAction(mcmlNode)
	--if(mcmlNode) then
	--end
--end

----------------------------------------------------------------------
-- pe:answer-if: handles MCML tag <pe:answer-if>
----------------------------------------------------------------------
local pe_answer_if = commonlib.gettable("Map3DSystem.mcml_controls.pe_answer_if");
function pe_answer_if.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
end