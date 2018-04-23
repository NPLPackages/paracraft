--[[
Title: text sprite
Author(s): WangTian
Date: 2011/12/24
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/mcml/pe_aries_textsprite.lua");

---++ aries:textsprite
| fontsize | iamge font size(height) |
| default_fontsize | font size when no image sprite is available for the text |
| color | "255 255 255 255" or "255 255 255",  rgb(a) |
| text | utf8 text |
| tooltip | tooltip |
-------------------------------------------------------
]]
----------------------------------------------------------------------
-- aries:textsprite: handles MCML tag <aries:textsprite>
----------------------------------------------------------------------
NPL.load("(gl)script/ide/TextSprite.lua");

local aries_textsprite = commonlib.gettable("MyCompany.Aries.mcml_controls.aries_textsprite");

aries_textsprite.Images = {["default"] = "Texture/16number.png",
						   ["DragonLevel"] = "Texture/Aries/Common/10numbers_purple_26_32bits.png",
						   ["SpellName"] = "Texture/Aries/Common/SpellName_series_high.png",
						   ["CombatDigits"] = "Texture/Aries/Common/CombatDigits_sprites.png",
						   ["MapRegionName"] = "Texture/Aries/Common/MapRegionName_sprites.png",
						   ["MapRegionLevel"] = "Texture/Aries/Common/MapRegionLevel_sprites.png",
						   };
aries_textsprite.Sprites = {
	["default"] = {
		["1"] = {rect = "0 0 20 31", width = 20, height = 32},
		["2"] = {rect = "32 0 19 31", width = 19, height = 32},
		["3"] = {rect = "64 0 19 31", width = 19, height = 32},
		["4"] = {rect = "96 0 19 31", width = 19, height = 32},
		["5"] = {rect = "0 32 20 31", width = 20, height = 32},
		["6"] = {rect = "32 32 19 32", width = 19, height = 32},
		["7"] = {rect = "64 32 19 31", width = 19, height = 32},
		["8"] = {rect = "96 32 19 31", width = 19, height = 32},
		["9"] = {rect = "0 64 19 31", width = 19, height = 32},
		["0"] = {rect = "32 64 19 31", width = 19, height = 32},
		["A"] = {rect = "64 64 22 31", width = 22, height = 32},
		["B"] = {rect = "96 64 20 31", width = 20, height = 32},
		["C"] = {rect = "0 96 19 31", width = 19, height = 32},
		["D"] = {rect = "32 96 19 31", width = 19, height = 32},
		["E"] = {rect = "64 96 19 31", width = 19, height = 32},
		["F"] = {rect = "96 96 19 31", width = 19, height = 32},
	},
	["DragonLevel"] = {
		["1"] = {rect = "0 0 18 26", width = 15, height = 26},
		["2"] = {rect = "18 0 18 26", width = 16, height = 26},
		["3"] = {rect = "36 0 18 26", width = 16, height = 26},
		["4"] = {rect = "54 0 18 26", width = 17, height = 26},
		["5"] = {rect = "72 0 18 26", width = 16, height = 26},
		["6"] = {rect = "0 26 18 26", width = 16, height = 26},
		["7"] = {rect = "18 26 18 26", width = 16, height = 26},
		["8"] = {rect = "36 26 18 26", width = 17, height = 26},
		["9"] = {rect = "54 26 18 26", width = 17, height = 26},
		["0"] = {rect = "72 26 18 26", width = 16, height = 26},
	},
	["SpellName"] = {
		["火"] = {rect = "0 0 18 26", width = 15, height = 26},
	},
	["MapRegionName"] = {
		["火"] = {rect = "0 0 18 26", width = 15, height = 26},
	},
	["CombatDigits"] = {
		["0"] = {rect = "0 0 29 38", width = 29, height = 38},
		["1"] = {rect = "35 0 20 38", width = 20, height = 38}, -- making 1 thinner
		["2"] = {rect = "60 0 29 38", width = 29, height = 38},
		["3"] = {rect = "90 0 29 38", width = 29, height = 38},
		["4"] = {rect = "120 0 29 38", width = 29, height = 38},
		["5"] = {rect = "0 38 29 38", width = 29, height = 38},
		["6"] = {rect = "30 38 29 38", width = 29, height = 38},
		["7"] = {rect = "60 38 29 38", width = 29, height = 38},
		["8"] = {rect = "90 38 29 38", width = 29, height = 38},
		["9"] = {rect = "120 38 29 38", width = 29, height = 38},
		["-"] = {rect = "150 0 29 38", width = 29, height = 38},
		["+"] = {rect = "150 38 29 38", width = 29, height = 38},
	},
	["MapRegionLevel"] = {
		["0"] = {rect = "0 0 22 24", width = 22, height = 24},
		["1"] = {rect = "23 0 20 24", width = 20, height = 24}, -- making 1 thinner
		["2"] = {rect = "44 0 22 24", width = 22, height = 24},
		["3"] = {rect = "66 0 22 24", width = 22, height = 24},
		["4"] = {rect = "88 0 22 24", width = 22, height = 24},
		["~"] = {rect = "110 0 22 24", width = 22, height = 24},

		["5"] = {rect = "0 24 22 24", width = 22, height = 24},
		["6"] = {rect = "22 24 22 24", width = 22, height = 24},
		["7"] = {rect = "44 24 22 24", width = 22, height = 24},
		["8"] = {rect = "66 24 22 24", width = 22, height = 24},
		["9"] = {rect = "88 24 22 24", width = 22, height = 24},
		["级"] = {rect = "110 24 22 24", width = 22, height = 24},
	},
};

local spellname_mapping_original = {
	{"寒", "冰", "魔", "光", "霜", "破", "陨", "落", "狂", "舞", "万", "象", "春", "噬", "草", "召"},
	{"石", "剑", "凛", "空", "陷", "阱", "盾", "结", "唤", "机", "勃", "发", "治", "疗", "术", "使"},
	{"界", "守", "护", "专", "注", "地", "钻", "魄", "怒", "庇", "圣", "净", "化", "精", "希", "望"},
	{"漫", "天", "极", "力", "场", "棱", "镜", "神", "礼", "死", "亡", "暗", "咒", "血", "幽", "突"},
	{"偷", "之", "手", "眩", "晕", "坚", "固", "壁", "袭", "回", "返", "照", "墓", "黑", "诅", "场"},
	{"垒", "海", "狮", "吸", "收", "雹", "来", "袭", "绝", "毒", "巫", "蝠", "王", "魂", "群", "羁"},
	{"敌", "封", "符", "生", "命", "灵", "弧", "静", "绊", "祭", "献", "杀", "星", "契", "约", "烈"},
	{"水", "体", "木", "刺", "不", "息", "林", "莽", "火", "焰", "爆", "凤", "焚", "轮", "换", "日"},
	{"链", "握", "吼", "狼", "咆", "哮", "烟", "雾", "捉", "成", "功", "准", "翼", "翔", "飓", "僵"}, 
	{"转", "冲", "击", "掷", "熔", "岩", "炸", "弹", "尸", "复", "仇", "戒", "律", "墙", "长", "霹"},
	{"急", "速", "点", "燃", "风", "暴", "疾", "电", "雳", "血", "嗜", "铁", "壳", "物", "兵", "虾"},
	{"金", "遁", "夜", "雷", "云", "厉", "运", "和", "叉", "猴", "动", "锁", "攻", "咕", "噜", "大"},
	{"逐", "蛇", "女", "惊", "裂", "隙", "限", "熊", "法", "兽", "土", "猿", "猛", "苍", "蝇", "穿"},
	{"旋", "鸟", "逆", "失", "败", "伤", "阵", "凝", "鬃", "连", "环", "闪", "章", "鱼", "凰", "涅"},
	{"气", "炫", "卡", "彩", "[",  "]", "对", "抗", "磐", "威", "能", "兔", "活", "猫", "帽", "子"},
	{"灼", "炎", "瘟", "强", "愈", "合", "超", "捕", "戏", "法", "柱", "恶", "军", "抑", "制", "迅"},
	{"后", "狱", "形", "态", "影", "斗", "篷", "赐", "福", "替", "身", "阳", "耀", "叹", "遗", "忘"},
	{"附", "虚", "弱", "控", "制", "自", "由", "反", "高", "级", "识", "病", "感", "染", "君", "霆"},
	{"钧", "众", "连", "环", "奥", "鳄", "战", "锤", "元", "素", "双", "龙", "猿", "猛", "柱", "屏"},
	{"蔽", "测", "试", "嘲", "讽", "威", "慑", "姿", "态", "诛", "箭", "雨", "量", "梦", "幸", "泡"},
	{"毛", "蛙", "幻", "避", "文", "衡", "刃", "盗", "平", "漠", "鸭", "胃", "吃", "二", "蟠", "枯"},
	{"密", "领", "贪", "雪", "嚎", "蚁", "梨", "飞", "财", "迷", "世", "小", "山", "招", "到", "喵"},
	{"爪", "抱", "邪", "人", "怪", "沙", "赤", "巨", "蝙", "首", "蛛", "鹰", "花", "白", "蝴", "荒"},
	{"八", "蝎", "母", "蝶", "牙", "食", "萌", "士", "鼠", "蟹", "黎", "明", "彗", "轨", "道", "能"},
	{"严", "炮", "械", "上", "魇", "主", "老", "古", "钢", "牛", "械", "傀", "儡"},
};


if(System.options.locale == "zhTW") then
	spellname_mapping_original = {
		{"寒", "冰", "魔", "光", "霜", "破", "隕", "落", "狂", "舞", "萬", "象", "春", "噬", "草", "召"},
		{"石", "劍", "凜", "空", "陷", "阱", "盾", "結", "喚", "機", "勃", "發", "治", "療", "術", "使"},
		{"界", "守", "護", "專", "注", "地", "鑽", "魄", "怒", "庇", "聖", "淨", "化", "精", "希", "望"},
		{"漫", "天", "極", "力", "場", "棱", "鏡", "神", "禮", "死", "亡", "暗", "咒", "血", "幽", "突"},
		{"偷", "之", "手", "眩", "暈", "堅", "固", "壁", "襲", "回", "返", "照", "墓", "黑", "詛", "場"},
		{"壘", "海", "獅", "吸", "收", "雹", "來", "襲", "絕", "毒", "巫", "蝠", "王", "魂", "群", "羁"},
		{"敵", "封", "符", "生", "命", "靈", "弧", "靜", "絆", "祭", "獻", "殺", "星", "契", "約", "烈"},
		{"水", "體", "木", "刺", "不", "息", "林", "莽", "火", "焰", "爆", "鳳", "焚", "輪", "換", "日"},
		{"鏈", "握", "吼", "狼", "咆", "哮", "煙", "霧", "捉", "成", "功", "准", "翼", "翔", "飓", "僵"}, 
		{"轉", "衝", "擊", "擲", "熔", "岩", "炸", "彈", "屍", "複", "仇", "戒", "律", "牆", "長", "霹"},
		{"急", "速", "點", "燃", "風", "暴", "疾", "電", "雳", "血", "嗜", "鐵", "殼", "物", "兵", "蝦"},
		{"金", "遁", "夜", "雷", "雲", "厲", "運", "和", "叉", "猴", "動", "鎖", "攻", "咕", "魯", "大"},
		{"逐", "蛇", "女", "驚", "裂", "隙", "限", "熊", "法", "獸", "土", "猿", "猛", "蒼", "蠅", "穿"},
		{"旋", "鳥", "逆", "失", "敗", "傷", "陣", "凝", "鬃", "連", "環", "閃", "章", "魚", "凰", "涅"},
		{"氣", "炫", "卡", "彩", "[",  "]", "對", "抗", "磐", "威", "能", "兔", "活", "貓", "帽", "子"},
		{"灼", "炎", "瘟", "強", "愈", "合", "超", "捕", "戲", "法", "柱", "惡", "軍", "抑", "制", "迅"},
		{"後", "獄", "形", "態", "影", "鬥", "篷", "賜", "福", "替", "身", "陽", "耀", "歎", "遺", "忘"},
		{"附", "虛", "弱", "控", "制", "自", "由", "反", "高", "級", "識", "病", "感", "染", "君", "霆"},
		{"鈞", "衆", "連", "環", "奧", "鳄", "戰", "錘", "元", "素", "雙", "龍", "猿", "猛", "柱", "屏"},
		{"蔽", "測", "試", "嘲", "諷", "威", "懾", "姿", "態", "誅", "箭", "雨", "量", "夢", "幸", "泡"},
		{"毛", "蛙", "幻", "避", "文", "衡", "刃", "盜", "平", "漠", "鴨", "胃", "吃", "二", "蟠", "枯"},
		{"密", "領", "貪", "雪", "嚎", "蟻", "梨", "飛", "財", "迷", "世", "小", "山", "招", "到", "喵"},
		{"爪", "抱", "邪", "人", "怪", "沙", "赤", "巨", "蝙", "首", "蛛", "鷹", "花", "白", "蝴", "荒"},
		{"八", "蠍", "母", "蝶", "牙", "食", "萌", "士", "鼠", "蟹", "黎", "明", "彗", "軌", "道", "能"},
		{"嚴", "炮", "械", "上", "魘", "主", "老", "古", "鋼", "牛", "械", "傀", "儡"},
	};
elseif(System.options.locale == "thTH") then
	spellname_mapping_original = {{}};
elseif(System.options.locale == "jaJP") then
	spellname_mapping_original = {{}};
elseif(System.options.locale == "enUS") then
	spellname_mapping_original = {{}};
end

local i, j;
for i = 1, 32 do
	for j = 1, 16 do
		if(spellname_mapping_original[i] and spellname_mapping_original[i][j]) then
			aries_textsprite.Sprites["SpellName"][spellname_mapping_original[i][j]] = {
				rect = (j * 32 - 32).." "..(i * 32 - 32).." 32 32", 
				width = 32, 
				height = 32, 
			};
		end
	end
end

local mapregionname_mapping_original = {
	{"黎", "明", "岗", "哨", "渔", "港", "彩", "虹", "像", "迷", "阵", "清", "泉", "绿", "入", "窟"},
	{"密", "林", "贫", "瘠", "之", "地", "火", "焰", "落", "日", "神", "殿", "口", "狱", "海", "女"},
	{"山", "洞", "都", "码", "头", "乱", "草", "沼", "泪", "亡", "者", "森", "暗", "影", "坎", "德"},
	{"泽", "鸟", "洲", "泰", "坦", "的", "遗", "迹", "拉", "废", "墟", "萨", "满", "祭", "坛", "封"},
	{"沸", "腾", "湖", "焚", "香", "丛", "林", "神", "印", "心", "试", "炼", "塔", "梦", "魇", "异"},
	{"木", "空", "间", "浮", "冰", "台", "海", "雪", "界", "英", "雄", "谷", "红", "蘑", "菇", "角"},
	{"原", "梦", "幻", "岛", "寒", "狼", "莲", "峰", "斗", "场", "副", "本", "P", "V", "[", "]"},
	{"大", "熊", "巢", "穴", "风", "暴", "眼", "石"},
};

local i, j;
for i = 1, 16 do
	for j = 1, 16 do
		if(mapregionname_mapping_original[i] and mapregionname_mapping_original[i][j]) then
			aries_textsprite.Sprites["MapRegionName"][mapregionname_mapping_original[i][j]] = {
				rect = (j * 32 - 32).." "..(i * 32 - 32).." 32 32", 
				width = 32, 
				height = 32, 
			};
		end
	end
end

-- aries_textsprite is just a wrapper of TextSprite
function aries_textsprite.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local spritestyle = mcmlNode:GetAttributeWithCode("spritestyle") or "default";
	local color = mcmlNode:GetAttributeWithCode("color") or "255 255 255 255";
	local fontsize = mcmlNode:GetNumber("fontsize") or 32;
	local text = mcmlNode:GetAttributeWithCode("text");
	
	if(not text) then
		log("error: nil text got in aries_textsprite.create\n");
		return;
	end
	
	local left, top, width, height = parentLayout:GetPreferredRect();
	
	-- TODO: each time we will rebuilt child nodes however, we can also reuse previously created ones. 
	mcmlNode:ClearAllChildren();
	
	local ctl = CommonCtrl.TextSprite:new{
		name = "mcml_text_sprite",
		alignment = "_lt",
		left = left,
		top = top,
		width = 2000,
		height = fontsize,
		parent = _parent,
		text = text,
		color = color,
		fontsize = fontsize,
		default_fontsize = mcmlNode:GetNumber("default_fontsize"),
		tooltip = mcmlNode:GetAttributeWithCode("tooltip"),
		image = aries_textsprite.Images[spritestyle],
		sprites = aries_textsprite.Sprites[spritestyle],
	};
	ctl:Show(true);
	mcmlNode.control = ctl;
	
	parentLayout:AddObject(ctl:GetUsedWidth(), fontsize);
end

-- get the UI value on the node
function aries_textsprite.GetUIValue(mcmlNode, pageInstName)
	local editBox = mcmlNode:GetControl(pageInstName);
	if(editBox) then
		if(type(editBox)=="table" and type(editBox.GetText) == "function") then
			return editBox:GetText();
		end	
	end
end

-- set the UI value on the node
function aries_textsprite.SetUIValue(mcmlNode, pageInstName, value)
	local editBox = mcmlNode:GetControl(pageInstName);
	if(editBox) then
		if(type(value) == "number") then
			value = tostring(value);
		elseif(type(value) == "table") then
			return
		end 
		if(type(editBox.SetText) == "function") then
			editBox:SetText(value);
		end	
	end
end