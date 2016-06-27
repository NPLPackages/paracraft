--[[
Title: Environment Frame Page
Author(s): LiXizhi
Date: 2013/10/15
Desc: 
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/EnvFramePage.lua");
local EnvFramePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.EnvFramePage");
EnvFramePage.ShowPage(true)
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/BlockTemplatePage.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua");

local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local BlockTemplatePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.BlockTemplatePage");
local Desktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");

local EnvFramePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.EnvFramePage");

local page;

EnvFramePage.category_index = 1;
EnvFramePage.Current_Item_DS = {};
-- this is a value between [100-255]
local block_light_scale = 180;

EnvFramePage.category_ds_old = {
    {text=L"画面效果", name="graphics"},
    {text=L"地形", name="terrain"},
}

EnvFramePage.category_ds_new = {
    {text=L"环境", name="environment"},
    {text=L"游戏", name="gameparma"},
	{text=L"其他", name="others"},
}
EnvFramePage.shader_ds = {
	{value="1", text=L"关闭"},
	{value="2", text=L"开启"},
	{value="3", text=L"HDR"},
	{value="4", text=L"Dof/HDR"},
}

EnvFramePage.category_ds = nil;
EnvFramePage.uiversion = nil;
EnvFramePage.colorpicker_name = nil;

function EnvFramePage.OnInit(uiversion)
	EnvFramePage.OneTimeInit();
	page = document:GetPageCtrl();

	EnvFramePage.uiversion = uiversion;
	EnvFramePage.category_ds = nil;
	if(uiversion == 0) then
		EnvFramePage.category_ds = EnvFramePage.category_ds_old;
		EnvFramePage.colorpicker_name = "BlockColorpicker";
		block_light_scale = 180;
	elseif(uiversion == 1) then
		EnvFramePage.category_ds = EnvFramePage.category_ds_new;
		EnvFramePage.colorpicker_name = "NewBlockColorpicker";
		block_light_scale = 172;
	end
	EnvFramePage.OnChangeCategory(nil, false);

	local nRenderMethod = ParaTerrain.GetBlockAttributeObject():GetField("BlockRenderMethod", 1);
	for i, item in ipairs(EnvFramePage.shader_ds) do
		if(i == nRenderMethod) then
			item.selected = true;
		else
			item.selected = nil;
		end
	end
	
	page:SetValue("comboShader",  tostring(math.min(math.max(1, nRenderMethod), 4)) );
	--page:SetValue("checkboxShadow", ParaTerrain.GetBlockAttributeObject():GetField("UseSunlightShadowMap", false) == true);
	--page:SetValue("checkboxReflection", ParaTerrain.GetBlockAttributeObject():GetField("UseWaterReflection", false) == true);

	page:SetValue("checkboxUIScaling", GameLogic.options.EnableAutoUIScaling);
	page:SetValue("checkboxViewBobbing", GameLogic.options.ViewBobbing);
	page:SetValue("checkboxLockMouseWheel", GameLogic.options.lock_mouse_wheel);
	page:SetValue("eye_bightness", GameLogic.options:GetEyeBrightness());
	page:SetValue("superRenderDist", GameLogic.options:GetSuperRenderDist());

	local render_dist = ParaTerrain.GetBlockAttributeObject():GetField("RenderDist", 100);
	if(render_dist < 30) then
		render_dist = 30
	elseif(render_dist > 200) then
		render_dist = 200;
	end
	page:SetValue("renderDist", render_dist);
	
	local color = ParaTerrain.GetBlockAttributeObject():GetField("BlockLightColor", GameLogic.options.BlockLightColor);
	page:SetNodeValue(EnvFramePage.colorpicker_name, string.format("%d %d %d", color[1]*block_light_scale, color[2]*block_light_scale, color[3]*block_light_scale));
end

function EnvFramePage.OneTimeInit()
	if(EnvFramePage.is_inited) then
		return;
	end
	EnvFramePage.is_inited = true;
end

-- clicked a block
function EnvFramePage.OnClickBlock(block_id)
end

-- @param bRefreshPage: false to stop refreshing the page
function EnvFramePage.OnChangeCategory(index, bRefreshPage)
    EnvFramePage.category_index = index or EnvFramePage.category_index;
	
	local category = EnvFramePage.category_ds[EnvFramePage.category_index];
	if(category) then
		-- EnvFramePage.Current_Item_DS = ItemClient.GetBlockDS(category.name);
	end
    
	if(bRefreshPage~=false and page) then
		page:Refresh(0.01);
	end
end

function EnvFramePage.OnBlockColorChanged(r,g,b)
	if(r and g and b) then
		r = r/block_light_scale;
		g = g/block_light_scale;
		b = b/block_light_scale;
		ParaTerrain.GetBlockAttributeObject():SetField("BlockLightColor", {r,g,b});
	end
end

-- from night to noo by sliderbar
function EnvFramePage.OnTimeSliderChanged(value)
	if (value) then
		local time=(value/1000-0.5)*2;
		time = tostring(time);
		CommandManager:RunCommand("time", time);
	end	
end

local RGBTable = {
	["red"]        = {red_v = 255,green_v = 21, blue_v = 0,  },
	["yellow"]     = {red_v = 255,green_v = 182,blue_v = 0,  },
	["green"]      = {red_v = 107,green_v = 255,blue_v = 0,  },
	["light_blue"] = {red_v = 0,  green_v = 204,blue_v = 255,},
	["dark_blue"]  = {red_v = 0,  green_v = 30, blue_v = 255,},
	["purple"]	   = {red_v = 182,green_v = 0,  blue_v = 255,},
	["white"]	   = {red_v = 255,green_v = 255,blue_v = 255,},
	["black"]	   = {red_v = 0,  green_v = 0,  blue_v = 0,  },
}

function EnvFramePage.SetLightColor(color_name)
	local rgb_item = RGBTable[color_name];
	if(rgb_item) then
		local red_value = rgb_item.red_v;
		local green_value = rgb_item.green_v;	
		local blue_value = rgb_item.blue_v;	
		page:SetUIValue(EnvFramePage.colorpicker_name, string.format("%d %d %d", red_value, green_value, blue_value));		
		--page:Refresh(0.1);
		EnvFramePage.OnBlockColorChanged(red_value, green_value, blue_value);
	end
end


EnvFramePage.category_game = {
	[1] = {
		{left_text="摄影机摇摆", quest_mark = false, right_type="button",onclick="GameLogic.OnToggleViewBobbing"},
		{left_text="UI自动放缩", quest_mark = false, right_type="button",onclick="GameLogic.OnToggleUIScaling"},
		{left_text="锁定鼠标滚轮",quest_mark = false, right_type="button",onclick="GameLogic.OnToggleLockMouseWheel"},	
		{left_text="可视距离", quest_mark = false, right_type="slider"},
	},
	[2] = {
		{left_text="鼠标左键",quest_mark = false,right_type="text",right_value="消除方块",},
		{left_text="鼠标右键",quest_mark = false,right_type="text",right_value="放置方块"},
		{left_text="鼠标中键",quest_mark = false,right_type="text",right_value="选择方块"},	
		{left_text="W",quest_mark = false,right_type="text",right_value="向前"},	
		{left_text="A",quest_mark = false,right_type="text",right_value="向左"},	
		{left_text="S",quest_mark = false,right_type="text",right_value="后退"},	
		{left_text="D",quest_mark = false,right_type="text",right_value="向右"},	
		{left_text="Space",quest_mark = false,right_type="text",right_value="跳跃"},	
		{left_text="Ctrl + X",quest_mark = false,right_type="text",right_value="撤销上步操作"},	
	}
}

EnvFramePage.category_others = {	
	[1]={
		{left_text="背景音乐", quest_mark = false, right_type="button",},
		{left_text="游戏音效", quest_mark = false, right_type="button",},
		{left_text="图像品质", quest_mark = false, right_type="button",},
		{left_text="视觉摇晃", quest_mark = false, right_type="button",},
		{left_text="视觉摇晃", quest_mark = false, right_type="button",},
	}
    
}