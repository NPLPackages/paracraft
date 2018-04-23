 --[[
Title: Deprecated: UI Animation for 3D Map system
Author(s): WangTian
Date: 2007/9/24
Desc: UI Animation functions
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemUI/Animation/Animation.lua");
Map3DSystem.UI.Animation.Init();

Deprecated file. use UIAnimManager.lua instead
------------------------------------------------------------
]]
NPL.load("(gl)script/kids/3DMapSystem_Data.lua");
NPL.load("(gl)script/ide/UIAnim/UIAnimManager.lua");


local UI_timer;
function Map3DSystem.UI.Animation.Init()
	NPL.load("(gl)script/ide/timer.lua");
	UI_timer = UI_timer or commonlib.Timer:new({callbackFunc = Map3DSystem.UI.Animation.DoAnimation});
	UI_timer:Change(0, 30);
end

function Map3DSystem.UI.Animation.InterpolateLinear(range, v1, v2)
	return  (v1 * (1.0 - range) + v2 * range);
end

function Map3DSystem.UI.Animation.InterpolateHermite(range, v1, v2, inVal, outVal)

	local h1 = 2.0*range*range*range - 3.0*range*range + 1.0;
	local h2 = -2.0*range*range*range + 3.0*range*range;
	local h3 = range*range*range - 2.0*range*range + range;
	local h4 = range*range*range - range*range;
	
	return (v1*h1 + v2*h2 + inVal*h3 + outVal*h4);
end

function Map3DSystem.UI.Animation.ApplyStyle(obj, parent, styleName)

	local _parent = ParaUI.GetUIObject(parent);
	local _this = _parent:GetChild(obj);
	--local _thisX, _thisY, _thisWidth, _thisHeight = _this:GetAbsPosition();
	
	local _thisX = _this.x;
	local _thisY = _this.y;
	local _thisWidth = _this.width;
	local _thisHeight = _this.height;
	
	_thisX = _thisX + _thisWidth/2;
	_thisY = _thisY + _thisHeight/2;
	
	Map3DSystem.UI.Animation.LastState[obj.."#"..parent] = {
		enabled = false,
		visible = false,
		x = _thisX,
		y = _thisY,
		width = 0,
		height = 0,
		style = styleName, -- TODO: check this
		};
	
	Map3DSystem.UI.Animation.DoChange(obj, parent);
end

function Map3DSystem.UI.Animation.ChangeStyle(obj, parent, style)
end

function Map3DSystem.UI.Animation.DoAnimation()
	UIAnimManager.DoAnimation();
	
	if(Map3DSystem.UI.Animation.Pool) then
		local k, v;
		for k, v in pairs(Map3DSystem.UI.Animation.Pool) do
			
			local continueAnimation = false;
			local sharpSign = string.find(k, "#");
			local obj = string.sub(k, 0, sharpSign-1);
			local parent = string.sub(k, sharpSign+1);
			
			local _parent = ParaUI.GetUIObject(parent);
			local _this = _parent:GetChild(obj);
	
			if(v["visibleAlpha"]) then
				local _tex = _this:GetTexture("background");
				if(v["visibleAlpha"].Index == 8) then
					-- reach end of animation
					_tex.transparency = v["visibleAlpha"][v["visibleAlpha"].Index];
					v["visibleAlpha"].Index = -1;
				elseif(v["visibleAlpha"].Index ~= -1) then
					-- still to go
					_tex.transparency = v["visibleAlpha"][v["visibleAlpha"].Index];
					continueAnimation = true;
					v["visibleAlpha"].Index = v["visibleAlpha"].Index + 1;
				end
				
			end
			
			if(v["enableAlpha"]) then
				local _tex = _this:GetTexture("background");
				if(v["enableAlpha"].Index == 8) then
					-- reach end of animation
					_tex.transparency = v["enableAlpha"][v["enableAlpha"].Index];
				else
					-- still to go
					_tex.transparency = v["enableAlpha"][v["enableAlpha"].Index];
					continueAnimation = true;
					v["enableAlpha"].Index = v["enableAlpha"].Index + 1;
				end
			end
			
			if(v["x"]) then
				if(v["x"].Index == 8) then
					-- reach end of animation
					_this.x = v["x"][v["x"].Index];
				else
					-- still to go
					_this.x = v["x"][v["x"].Index];
					continueAnimation = true;
					v["x"].Index = v["x"].Index + 1;
				end
			end
			
			if(v["y"]) then
				if(v["y"].Index == 8) then
					-- reach end of animation
					_this.y = v["y"][v["y"].Index];
				else
					-- still to go
					_this.y = v["y"][v["y"].Index];
					continueAnimation = true;
					v["y"].Index = v["y"].Index + 1;
				end
			end
			
			if(v["width"]) then
				if(v["width"].Index == 8) then
					-- reach end of animation
					_this.width = v["width"][v["width"].Index];
				else
					-- still to go
					_this.width = v["width"][v["width"].Index];
					continueAnimation = true;
					v["width"].Index = v["width"].Index + 1;
				end
			end
			
			if(v["height"]) then
				if(v["height"].Index == 8) then
					-- reach end of animation
					_this.height = v["height"][v["height"].Index];
				else
					-- still to go
					_this.height = v["height"][v["height"].Index];
					continueAnimation = true;
					v["height"].Index = v["height"].Index + 1;
				end
			end
			
				--if(_this.visible == true) then
					--log("visible: ".."true ");
				--elseif(_this.visible == false) then
					--log("visible: ".."false ");
				--end
				--
				--if(_this.visible == true) then
					--log("enabled: ".."true ");
				--elseif(_this.visible == false) then
					--log("enabled: ".."false ");
				--end
				--
				--log("x: ".._this.x);
				--log(" y: ".._this.y);
				--log(" width: ".._this.width);
				--log(" height: ".._this.height.."\r\n");
				
			if(continueAnimation == false) then
				Map3DSystem.UI.Animation.DirectApply = true;
				_this.enabled = v["endState"].enabled;
				_this.visible = v["endState"].visible;
				_this.x = v["endState"].x;
				_this.y = v["endState"].y;
				_this.width = v["endState"].width;
				_this.height = v["endState"].height;
				Map3DSystem.UI.Animation.DirectApply = false;
				
	
				Map3DSystem.UI.Animation.LastState[obj.."#"..parent] = {
					enabled = v["endState"].enabled,
					visible = v["endState"].visible,
					x = v["endState"].x + v["endState"].width/2,
					y = v["endState"].y + v["endState"].height/2,
					width = v["endState"].width,
					height = v["endState"].height,
					};
				
				v = nil;
			end
			
		end
	end
end

function Map3DSystem.UI.Animation.DoChange(obj, parent, isDragable)
	log("Trigger\r\n");
				if(Map3DSystem.UI.Animation.LastState[obj.."#"..parent].enabled == true) then
					log("visible: ".."true ");
				elseif(Map3DSystem.UI.Animation.LastState[obj.."#"..parent].enabled == false) then
					log("visible: ".."false ");
				end
				
				if(Map3DSystem.UI.Animation.LastState[obj.."#"..parent].visible == true) then
					log("enabled: ".."true ");
				elseif(Map3DSystem.UI.Animation.LastState[obj.."#"..parent].visible == false) then
					log("enabled: ".."false ");
				end
				
				log("x: "..Map3DSystem.UI.Animation.LastState[obj.."#"..parent].x);
				log(" y: "..Map3DSystem.UI.Animation.LastState[obj.."#"..parent].y);
				log(" width: "..Map3DSystem.UI.Animation.LastState[obj.."#"..parent].width);
				log(" height: "..Map3DSystem.UI.Animation.LastState[obj.."#"..parent].height.."\r\n");

	
	if(Map3DSystem.UI.Animation.DirectApply == true) then
		return;
	end
	
	local _parent = ParaUI.GetUIObject(parent);
	local _this = _parent:GetChild(obj);
	
	local _thisEnabled = _this.enabled;
	local _thisVisible = _this.visible;
	--local _thisX, _thisY, _thisWidth, _thisHeight = _this:GetAbsPosition();
	local _thisX = _this.x;
	local _thisY = _this.y;
	local _thisWidth = _this.width;
	local _thisHeight = _this.height;
	
	Map3DSystem.UI.Animation.DirectApply = true;
	--_this.enabled = Map3DSystem.UI.Animation.LastState[obj.."#"..parent].enabled;
	--_this.visible = Map3DSystem.UI.Animation.LastState[obj.."#"..parent].visible;
	_this.visible = true;
	_this.enabled = true;
	_this.x = Map3DSystem.UI.Animation.LastState[obj.."#"..parent].x;
	_this.y = Map3DSystem.UI.Animation.LastState[obj.."#"..parent].y;
	_this.width = Map3DSystem.UI.Animation.LastState[obj.."#"..parent].width;
	_this.height = Map3DSystem.UI.Animation.LastState[obj.."#"..parent].height;
	Map3DSystem.UI.Animation.DirectApply = false;
	
	local styleName = Map3DSystem.UI.Animation.LastState[obj.."#"..parent].style;
	local style = Map3DSystem.UI.Animation.Style[styleName];
				
	
	if(Map3DSystem.UI.Animation.LastState[obj.."#"..parent].visible == false and _thisVisible == true) then
		-- visible false --> true
		-- register new pool object
		if(not Map3DSystem.UI.Animation.Pool[obj.."#"..parent]) then
			Map3DSystem.UI.Animation.Pool[obj.."#"..parent] = {};
		end
		
		if(Map3DSystem.UI.Animation.Pool[obj.."#"..parent]["visibleAlpha"]) then
			-- TODO: the object is animating
		else
			
			Map3DSystem.UI.Animation.Pool[obj.."#"..parent]["visibleAlpha"] = {
				Index = 1,
				style["VisibleFadeIn"][1],
				style["VisibleFadeIn"][2],
				style["VisibleFadeIn"][3],
				style["VisibleFadeIn"][4],
				style["VisibleFadeIn"][5],
				style["VisibleFadeIn"][6],
				style["VisibleFadeIn"][7],
				style["VisibleFadeIn"][8],
				};
		end
	elseif(Map3DSystem.UI.Animation.LastState[obj.."#"..parent].visible == true and _thisVisible == false) then
		-- visible true --> false
		if(not Map3DSystem.UI.Animation.Pool[obj.."#"..parent]) then
			Map3DSystem.UI.Animation.Pool[obj.."#"..parent] = {};
		end
		if(Map3DSystem.UI.Animation.Pool[obj.."#"..parent]["visibleAlpha"]) then
			-- TODO: the object is animating
		else
			-- register new pool object
			
			Map3DSystem.UI.Animation.Pool[obj.."#"..parent]["visibleAlpha"] = {
				Index = 1,
				style["VisibleFadeOut"][1],
				style["VisibleFadeOut"][2],
				style["VisibleFadeOut"][3],
				style["VisibleFadeOut"][4],
				style["VisibleFadeOut"][5],
				style["VisibleFadeOut"][6],
				style["VisibleFadeOut"][7],
				style["VisibleFadeOut"][8],
				};
		end
	else
		-- visible no change
		if(Map3DSystem.UI.Animation.LastState[obj.."#"..parent].enabled == false and _thisEnabled == true) then
			-- enable false --> true
			if(not Map3DSystem.UI.Animation.Pool[obj.."#"..parent]) then
				Map3DSystem.UI.Animation.Pool[obj.."#"..parent] = {};
			end
			if(Map3DSystem.UI.Animation.Pool[obj.."#"..parent]["enableAlpha"]) then
				-- TODO: the object is animating
			else
				-- register new pool object

				
				Map3DSystem.UI.Animation.Pool[obj.."#"..parent]["enableAlpha"] = {
					Index = 1,
					style["EnableFadeIn"][1],
					style["EnableFadeIn"][2],
					style["EnableFadeIn"][3],
					style["EnableFadeIn"][4],
					style["EnableFadeIn"][5],
					style["EnableFadeIn"][6],
					style["EnableFadeIn"][7],
					style["EnableFadeIn"][8],
					};
			end
		elseif(Map3DSystem.UI.Animation.LastState[obj.."#"..parent].enabled == true and _thisEnabled == false) then
			-- enable true --> false
			if(not Map3DSystem.UI.Animation.Pool[obj.."#"..parent]) then
				Map3DSystem.UI.Animation.Pool[obj.."#"..parent] = {};
			end
				
			if(Map3DSystem.UI.Animation.Pool[obj.."#"..parent]["enableAlpha"]) then
				-- TODO: the object is animating
			else
				-- register new pool object
	
				Map3DSystem.UI.Animation.Pool[obj.."#"..parent]["enableAlpha"] = {
					Index = 1,
					style["EnableFadeOut"][1],
					style["EnableFadeOut"][2],
					style["EnableFadeOut"][3],
					style["EnableFadeOut"][4],
					style["EnableFadeOut"][5],
					style["EnableFadeOut"][6],
					style["EnableFadeOut"][7],
					style["EnableFadeOut"][8],
					};
			end
		end
	end
	
	
	if(Map3DSystem.UI.Animation.LastState[obj.."#"..parent].x ~= _thisX) then
		-- move X
		if(not Map3DSystem.UI.Animation.Pool[obj.."#"..parent]) then
			Map3DSystem.UI.Animation.Pool[obj.."#"..parent] = {};
		end
			
		local multiplierX = (_thisX - Map3DSystem.UI.Animation.LastState[obj.."#"..parent].x)/16;
		
		if(Map3DSystem.UI.Animation.Pool[obj.."#"..parent]["x"]) then
			-- TODO: the object is animating
		else
			-- register new pool object
			
			Map3DSystem.UI.Animation.Pool[obj.."#"..parent]["x"] = {
				Index = 1,
				Map3DSystem.UI.Animation.LastState[obj.."#"..parent].x + style["Move"][1] * multiplierX,
				Map3DSystem.UI.Animation.LastState[obj.."#"..parent].x + style["Move"][2] * multiplierX,
				Map3DSystem.UI.Animation.LastState[obj.."#"..parent].x + style["Move"][3] * multiplierX,
				Map3DSystem.UI.Animation.LastState[obj.."#"..parent].x + style["Move"][4] * multiplierX,
				Map3DSystem.UI.Animation.LastState[obj.."#"..parent].x + style["Move"][5] * multiplierX,
				Map3DSystem.UI.Animation.LastState[obj.."#"..parent].x + style["Move"][6] * multiplierX,
				Map3DSystem.UI.Animation.LastState[obj.."#"..parent].x + style["Move"][7] * multiplierX,
				Map3DSystem.UI.Animation.LastState[obj.."#"..parent].x + style["Move"][8] * multiplierX,
				};
		end
	end
	
	if(Map3DSystem.UI.Animation.LastState[obj.."#"..parent].y ~= _thisY) then
		-- move Y
		if(not Map3DSystem.UI.Animation.Pool[obj.."#"..parent]) then
			Map3DSystem.UI.Animation.Pool[obj.."#"..parent] = {};
		end
		
		local multiplierY = (_thisY - Map3DSystem.UI.Animation.LastState[obj.."#"..parent].y)/16;
		
		if(Map3DSystem.UI.Animation.Pool[obj.."#"..parent]["y"]) then
			-- TODO: the object is animating
		else
			-- register new pool object
			if(not Map3DSystem.UI.Animation.Pool[obj.."#"..parent]) then
				Map3DSystem.UI.Animation.Pool[obj.."#"..parent] = {};
			end
			
			Map3DSystem.UI.Animation.Pool[obj.."#"..parent]["y"] = {
				Index = 1,
				Map3DSystem.UI.Animation.LastState[obj.."#"..parent].y + style["Move"][1] * multiplierY,
				Map3DSystem.UI.Animation.LastState[obj.."#"..parent].y + style["Move"][2] * multiplierY,
				Map3DSystem.UI.Animation.LastState[obj.."#"..parent].y + style["Move"][3] * multiplierY,
				Map3DSystem.UI.Animation.LastState[obj.."#"..parent].y + style["Move"][4] * multiplierY,
				Map3DSystem.UI.Animation.LastState[obj.."#"..parent].y + style["Move"][5] * multiplierY,
				Map3DSystem.UI.Animation.LastState[obj.."#"..parent].y + style["Move"][6] * multiplierY,
				Map3DSystem.UI.Animation.LastState[obj.."#"..parent].y + style["Move"][7] * multiplierY,
				Map3DSystem.UI.Animation.LastState[obj.."#"..parent].y + style["Move"][8] * multiplierY,
				};
		end
	end
	
	if(isDragable ~= true) then
		if(Map3DSystem.UI.Animation.LastState[obj.."#"..parent].width ~= _thisWidth) then
			-- resize width
			if(not Map3DSystem.UI.Animation.Pool[obj.."#"..parent]) then
				Map3DSystem.UI.Animation.Pool[obj.."#"..parent] = {};
			end
			local multiplierWidth = (_thisWidth - Map3DSystem.UI.Animation.LastState[obj.."#"..parent].width)/16;
			
			if(Map3DSystem.UI.Animation.Pool[obj.."#"..parent]["width"]) then
				-- TODO: the object is animating
			else
				-- register new pool object

				
				Map3DSystem.UI.Animation.Pool[obj.."#"..parent]["width"] = {
					Index = 1,
					Map3DSystem.UI.Animation.LastState[obj.."#"..parent].width + style["Resize"][1] * multiplierWidth,
					Map3DSystem.UI.Animation.LastState[obj.."#"..parent].width + style["Resize"][2] * multiplierWidth,
					Map3DSystem.UI.Animation.LastState[obj.."#"..parent].width + style["Resize"][3] * multiplierWidth,
					Map3DSystem.UI.Animation.LastState[obj.."#"..parent].width + style["Resize"][4] * multiplierWidth,
					Map3DSystem.UI.Animation.LastState[obj.."#"..parent].width + style["Resize"][5] * multiplierWidth,
					Map3DSystem.UI.Animation.LastState[obj.."#"..parent].width + style["Resize"][6] * multiplierWidth,
					Map3DSystem.UI.Animation.LastState[obj.."#"..parent].width + style["Resize"][7] * multiplierWidth,
					Map3DSystem.UI.Animation.LastState[obj.."#"..parent].width + style["Resize"][8] * multiplierWidth,
					};
			end
		end
		
		if(Map3DSystem.UI.Animation.LastState[obj.."#"..parent].height ~= _thisHeight) then
			-- resize height
			if(not Map3DSystem.UI.Animation.Pool[obj.."#"..parent]) then
				Map3DSystem.UI.Animation.Pool[obj.."#"..parent] = {};
			end
			local multiplierHeight = (_thisHeight - Map3DSystem.UI.Animation.LastState[obj.."#"..parent].height)/16;
			
			if(Map3DSystem.UI.Animation.Pool[obj.."#"..parent]["height"]) then
				-- TODO: the object is animating
			else
				-- register new pool object

				
				Map3DSystem.UI.Animation.Pool[obj.."#"..parent]["height"] = {
					Index = 1,
					Map3DSystem.UI.Animation.LastState[obj.."#"..parent].height + style["Resize"][1] * multiplierHeight,
					Map3DSystem.UI.Animation.LastState[obj.."#"..parent].height + style["Resize"][2] * multiplierHeight,
					Map3DSystem.UI.Animation.LastState[obj.."#"..parent].height + style["Resize"][3] * multiplierHeight,
					Map3DSystem.UI.Animation.LastState[obj.."#"..parent].height + style["Resize"][4] * multiplierHeight,
					Map3DSystem.UI.Animation.LastState[obj.."#"..parent].height + style["Resize"][5] * multiplierHeight,
					Map3DSystem.UI.Animation.LastState[obj.."#"..parent].height + style["Resize"][6] * multiplierHeight,
					Map3DSystem.UI.Animation.LastState[obj.."#"..parent].height + style["Resize"][7] * multiplierHeight,
					Map3DSystem.UI.Animation.LastState[obj.."#"..parent].height + style["Resize"][8] * multiplierHeight,
					};
			end
		end
	end
	
	if(Map3DSystem.UI.Animation.Pool[obj.."#"..parent]) then
		Map3DSystem.UI.Animation.Pool[obj.."#"..parent]["endState"] = {
			enabled = _thisEnabled,
			visible = _thisVisible,
			x = _thisX;
			y = _thisY;
			width = _thisWidth;
			height = _thisHeight;
			};
	end

end