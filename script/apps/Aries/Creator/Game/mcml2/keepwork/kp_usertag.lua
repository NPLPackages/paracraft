--[[
Title: div element
Author(s): chenjinxian
Date: 2020/8/4
Desc: kp:usertag element
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/mcml2/keepwork/kp_usertag.lua");
MyCompany.Aries.Game.mcml2.kp_usertag:RegisterAs("kp:usertag");
------------------------------------------------------------
]]

NPL.load("(gl)script/ide/System/Windows/mcml/PageElement.lua");
NPL.load("(gl)script/ide/System/Windows/Shapes/Rectangle.lua");
NPL.load("(gl)script/ide/System/Windows/Controls/Button.lua");
local Button = commonlib.gettable("System.Windows.Controls.Button");
local Rectangle = commonlib.gettable("System.Windows.Shapes.Rectangle");

local kp_usertag = commonlib.inherit(commonlib.gettable("System.Windows.mcml.PageElement"), commonlib.gettable("MyCompany.Aries.Game.mcml2.kp_usertag"));
kp_usertag:Property({"class_name", "kp:usertag"});

function kp_usertag:ctor()
end

function kp_usertag:LoadComponent(parentElem, parentLayout, style)
	local onclick = self:GetString("onclick");
	if(onclick == "") then
		onclick = nil;
	end

	local _this = self.control;
	if(not _this) then
		if(onclick) then
			_this = Button:new():init(parentElem);
			_this:SetPolygonStyle("none");
			self.isButton = true;
		else
			_this = Rectangle:new():init(parentElem);
		end

		self:SetControl(_this);
	else
		_this:SetParent(parentElem);
	end

	kp_usertag._super.LoadComponent(self, _this, parentLayout, style);
end

function kp_usertag:OnLoadComponentBeforeChild(parentElem, parentLayout, css)
	if(self.isButton) then
		self.buttonName = self:GetAttributeWithCode("name",nil,true);
		parentElem:Connect("clicked", self, self.OnClick, "UniqueConnection");
	end

	if(not css.background and not css.background2 and css["background-color"]~="#ffffff00") then
		if(css["background-color"]) then
			css.background = "Texture/whitedot.png";	
		else
			css["background-color"] = "#ffffff00";
		end
	end

	local _this = self.control;
	if(_this) then
		_this:SetTooltip(self:GetAttributeWithCode("tooltip", nil, true));
		--_this:ApplyCss(css);

		local tag = self:GetAttributeWithCode("tag", nil, true);
		if (tag) then
			local icons = {
				["VT"] = { background = "Texture/Aries/Creator/keepwork/UserInfo/VT_32bits.png;0 0 34 18",  width = 34, height = 18, },  
				["VT_gray"] = { background = "Texture/Aries/Creator/keepwork/UserInfo/VT_gray_32bits.png;0 0 34 18",  width = 34, height = 18, },  

				["T"] = { background = "Texture/Aries/Creator/keepwork/UserInfo/T_32bits.png;0 0 18 18",  width = 18, height = 18, },  
				["T_gray"] = { background = "Texture/Aries/Creator/keepwork/UserInfo/T_gray_32bits.png;0 0 18 18",  width = 18, height = 18, },  

				["V"] = { background = "Texture/Aries/Creator/keepwork/UserInfo/V_32bits.png;0 0 18 18",  width = 18, height = 18, },  
				["V_gray"] = { background = "Texture/Aries/Creator/keepwork/UserInfo/V_gray_32bits.png;0 0 18 18",  width = 18, height = 18, },  
			}

			local key = tag;
			local gray = self:GetAttributeWithCode("gray", nil, true);
			if (gray) then
				key = key.."_gray";
			end
			local icon = icons[key];
			if (icon) then
				_this:resize(icon.width, icon.height);
				_this:SetBackground(icon.background);
			end
		end
	end

	kp_usertag._super.OnLoadComponentBeforeChild(self, parentElem, parentLayout, css)	
end

function kp_usertag:OnBeforeChildLayout(layout)
	if(#self ~= 0) then
		local myLayout = layout:new();
		local css = self:GetStyle();
		local width, height = layout:GetPreferredSize();
		local padding_left, padding_top = css:padding_left(),css:padding_top();
		myLayout:reset(padding_left,padding_top,width+padding_left, height+padding_top);
		self:UpdateChildLayout(myLayout);
		width, height = myLayout:GetUsedSize();
		width = width - padding_left;
		height = height - padding_top;
		layout:AddObject(width, height);
	end
	return true;
end

-- virtual function: 
-- after child node layout is updated
function kp_usertag:OnAfterChildLayout(layout, left, top, right, bottom)
	if(self.control) then
		--self.control:setGeometry(left, top, right-left, bottom-top);
		self.control:setGeometry(left, top, self.control:width(), self.control:height());
	end
end

function kp_usertag:OnClick()
	local bindingContext;
	local onclick = self.onclickscript or self:GetAttributeWithCode("onclick",nil,true);
	if(onclick == "")then
		onclick = nil;
	end
	local result;
	if(onclick) then
		local btnType = self:GetString("type");
		if( btnType=="submit") then
			-- user clicks the normal button. 
			-- the callback function format is function(buttonName, values, bindingContext, self) end
			local values;
			--if(bindingContext) then
				--bindingContext:UpdateControlsToData();
				--values = bindingContext.values
			--end	
			result = self:DoPageEvent(onclick, self.buttonName, self);
		else
			-- user clicks the button, yet without form info
			-- the callback function format is function(buttonName, self) end
			result = self:DoPageEvent(onclick, self.buttonName, self)
		end
	end
	return result;
end