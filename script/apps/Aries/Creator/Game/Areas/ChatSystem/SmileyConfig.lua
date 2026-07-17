--[[
Title: smiley config
Author(s): pbb
Date: 2024/10/13
Desc:  
Use Lib:
-------------------------------------------------------
local SmileyConfig = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/SmileyConfig.lua");
]]

local smileys_people = {
  {
    n = "grinning",
    u = "1f600",
    cn = "露齿而笑的脸",
    idx = 1,
  },
  {
    n = "grin",
    u = "1f601",
    cn = "露齿而笑的眼睛",
    idx = 2,
  },
  {
    n = "joy",
    u = "1f602",
    cn = "喜极而泣的脸",
    idx = 3,
  },
  {
    n = "rolling_on_the_floor_laughing",
    u = "1f923",
    cn = "笑得在地上打滚",
    idx = 4,
  },
  {
    n = "smiley",
    u = "1f603",
    cn = "张嘴微笑的脸",
    idx = 5,
  },
  {
    n = "smile",
    u = "1f604",
    cn = "张嘴微笑并眯眼的脸",
    idx = 6,
  },
  {
    n = "sweat_smile",
    u = "1f605",
    cn = "张嘴微笑并冒冷汗的脸",
    idx = 7,
  },
  {
    n = "satisfied",
    u = "1f606",
    cn = "张嘴微笑并闭眼的脸",
    idx = 8,
  },
  {
    n = "wink",
    u = "1f609",
    cn = "眨眼的脸",
    idx = 9,
  },
  {
    n = "blush",
    u = "1f60a",
    cn = "微笑并害羞的脸",
    idx = 10,
  },
  {
    n = "yum",
    u = "1f60b",
    cn = "品尝美食的脸",
    idx = 11,
  },
  {
    n = "sunglasses",
    u = "1f60e",
    cn = "戴着太阳镜的微笑脸",
    idx = 12,
  },
  {
    n = "heart_eyes",
    u = "1f60d",
    cn = "心形眼睛的微笑脸",
    idx = 13,
  },
  {
    n = "kissing_heart",
    u = "1f618",
    cn = "送吻的脸",
    idx = 14,
  },
  {
    n = "kissing",
    u = "1f617",
    cn = "亲吻的脸",
    idx = 15,
  },
  {
    n = "kissing_smiling_eyes",
    u = "1f619",
    cn = "微笑的亲吻脸",
    idx = 16,
  },
  {
    n = "kissing_closed_eyes",
    u = "1f61a",
    cn = "闭眼亲吻的脸",
    idx = 17,
  },
  {
    n = "relaxed",
    u = "263a-fe0f",
    cn = "白色微笑脸",
    idx = 18,
  },
  {
    n = "slightly_smiling_face",
    u = "1f642",
    cn = "微微一笑的脸",
    idx = 19,
  },
  {
    n = "hugging_face",
    u = "1f917",
    cn = "拥抱的脸",
    idx = 20,
  },
  {
    n = "star-struck",
    u = "1f929",
    cn = "星星眼的露齿而笑的脸",
    idx = 21,
  },
  {
    n = "thinking_face",
    u = "1f914",
    cn = "思考的脸",
    idx = 22,
  },
  {
    n = "face_with_one_eyebrow_raised",
    u = "1f928",
    cn = "挑眉的脸",
    idx = 23,
  },
  {
    n = "neutral_face",
    u = "1f610",
    cn = "中立的脸",
    idx = 24,
  },
  {
    n = "expressionless",
    u = "1f611",
    cn = "无表情的脸",
    idx = 25,
  },
  {
    n = "no_mouth",
    u = "1f636",
    cn = "没有嘴的脸",
    idx = 26,
  },
  {
    n = "face_with_rolling_eyes",
    u = "1f644",
    cn = "翻白眼的脸",
    idx = 27,
  },
  {
    n = "smirk",
    u = "1f60f",
    cn = "得意的脸",
    idx = 28,
  },
  {
    n = "persevere",
    u = "1f623",
    cn = "坚持的脸",
    idx = 29,
  },
  {
    n = "disappointed_relieved",
    u = "1f625",
    cn = "失望但松了一口气的脸",
    idx = 30,
  },
  {
    n = "open_mouth",
    u = "1f62e",
    cn = "张嘴的脸",
    idx = 31,
  },
  {
    n = "zipper_mouth_face",
    u = "1f910",
    cn = "拉链嘴的脸",
    idx = 32,
  },
  {
    n = "hushed",
    u = "1f62f",
    cn = "安静的脸",
    idx = 33,
  },
  {
    n = "sleepy",
    u = "1f62a",
    cn = "困倦的脸",
    idx = 34,
  },
  {
    n = "tired_face",
    u = "1f62b",
    cn = "疲惫的脸",
    idx = 35,
  },
  {
    n = "sleeping",
    u = "1f634",
    cn = "睡觉的脸",
    idx = 36,
  },
  {
    n = "relieved",
    u = "1f60c",
    cn = "松了一口气的脸",
    idx = 37,
  },
  {
    n = "stuck_out_tongue",
    u = "1f61b",
    cn = "吐舌头的脸",
    idx = 38,
  },
  {
    n = "stuck_out_tongue_winking_eye",
    u = "1f61c",
    cn = "吐舌头并眨眼的脸",
    idx = 39,
  },
  {
    n = "stuck_out_tongue_closed_eyes",
    u = "1f61d",
    cn = "吐舌头并闭眼的脸",
    idx = 40,
  },
  {
    n = "drooling_face",
    u = "1f924",
    cn = "流口水的脸",
    idx = 41,
  },
  {
    n = "unamused",
    u = "1f612",
    cn = "不满的脸",
    idx = 42,
  },
  {
    n = "sweat",
    u = "1f613",
    cn = "冷汗的脸",
    idx = 43,
  },
  {
    n = "pensive",
    u = "1f614",
    cn = "沉思的脸",
    idx = 44,
  },
  {
    n = "confused",
    u = "1f615",
    cn = "困惑的脸",
    idx = 45,
  },
  {
    n = "upside_down_face",
    u = "1f643",
    cn = "倒立的脸",
    idx = 46,
  },
  {
    n = "money_mouth_face",
    u = "1f911",
    cn = "钱眼的脸",
    idx = 47,
  },
  {
    n = "astonished",
    u = "1f632",
    cn = "惊讶的脸",
    idx = 48,
  },
  {
    n = "white_frowning_face",
    u = "2639-fe0f",
    cn = "白色皱眉脸",
    idx = 49,
  },
  {
    n = "slightly_frowning_face",
    u = "1f641",
    cn = "微微皱眉的脸",
    idx = 50,
  },
  {
    n = "confounded",
    u = "1f616",
    cn = "困惑的脸",
    idx = 51,
  },
  {
    n = "disappointed",
    u = "1f61e",
    cn = "失望的脸",
    idx = 52,
  },
  {
    n = "worried",
    u = "1f61f",
    cn = "担忧的脸",
    idx = 53,
  },
  {
    n = "triumph",
    u = "1f624",
    cn = "胜利的脸",
    idx = 54,
  },
  {
    n = "cry",
    u = "1f622",
    cn = "哭泣的脸",
    idx = 55,
  },
  {
    n = "sob",
    u = "1f62d",
    cn = "大声哭泣的脸",
    idx = 56,
  },
  {
    n = "frowning",
    u = "1f626",
    cn = "皱眉并张嘴的脸",
    idx = 57,
  },
  {
    n = "anguished",
    u = "1f627",
    cn = "痛苦的脸",
    idx = 58,
  },
  {
    n = "fearful",
    u = "1f628",
    cn = "害怕的脸",
    idx = 59,
  },
  {
    n = "weary",
    u = "1f629",
    cn = "疲惫的脸",
    idx = 60,
  },
  {
    n = "exploding_head",
    u = "1f92f",
    cn = "头爆炸的震惊脸",
    idx = 61,
  },
  {
    n = "grimacing",
    u = "1f62c",
    cn = "扭曲的脸",
    idx = 62,
  },
  {
    n = "cold_sweat",
    u = "1f630",
    cn = "张嘴并冒冷汗的脸",
    idx = 63,
  },
  {
    n = "scream",
    u = "1f631",
    cn = "恐惧尖叫的脸",
    idx = 64,
  },
  {
    n = "flushed",
    u = "1f633",
    cn = "脸红的脸",
    idx = 65,
  },
  {
    n = "zany_face",
    u = "1f92a",
    cn = "一大一小眼睛的露齿而笑的脸",
    idx = 66,
  },
  {
    n = "dizzy_face",
    u = "1f635",
    cn = "头晕的脸",
    idx = 67,
  },
  {
    n = "rage",
    u = "1f621",
    cn = "撅嘴的脸",
    idx = 68,
  },
  {
    n = "angry",
    u = "1f620",
    cn = "愤怒的脸",
    idx = 69,
  },
  {
    n = "face_with_symbols_on_mouth",
    u = "1f92c",
    cn = "嘴巴被符号遮住的严肃脸",
    idx = 70,
  },
  {
    n = "mask",
    u = "1f637",
    cn = "戴口罩的脸",
    idx = 71,
  },
  {
    n = "face_with_thermometer",
    u = "1f912",
    cn = "拿着温度计的脸",
    idx = 72,
  },
  {
    n = "face_with_head_bandage",
    u = "1f915",
    cn = "头上包着绷带的脸",
    idx = 73,
  },
  {
    n = "nauseated_face",
    u = "1f922",
    cn = "恶心的脸",
    idx = 74,
  },
  {
    n = "face_vomiting",
    u = "1f92e",
    cn = "张嘴呕吐的脸",
    idx = 75,
  },
  {
    n = "sneezing_face",
    u = "1f927",
    cn = "打喷嚏的脸",
    idx = 76,
  },
  {
    n = "innocent",
    u = "1f607",
    cn = "带光环的微笑脸",
    idx = 77,
  },
  {
    n = "face_with_cowboy_hat",
    u = "1f920",
    cn = "戴牛仔帽的脸",
    idx = 78,
  },
  {
    n = "clown_face",
    u = "1f921",
    cn = "小丑脸",
    idx = 79,
  },
  {
    n = "lying_face",
    u = "1f925",
    cn = "撒谎的脸",
    idx = 80,
  },
  {
    n = "shushing_face",
    u = "1f92b",
    cn = "用手指捂住嘴的脸",
    idx = 81,
  },
  {
    n = "face_with_hand_over_mouth",
    u = "1f92d",
    cn = "微笑并用手捂嘴的脸",
    idx = 82,
  },
  {
    n = "face_with_monocle",
    u = "1f9d0",
    cn = "戴单片眼镜的脸",
    idx = 83,
  },
  {
    n = "nerd_face",
    u = "1f913",
    cn = "书呆子脸",
    idx = 84,
  },
  {
    n = "smiling_imp",
    u = "1f608",
    cn = "带角的微笑脸",
    idx = 85,
  },
  {
    n = "imp",
    u = "1f47f",
    cn = "小恶魔",
    idx = 86,
  },
  {
    n = "ogre",
    u = "1f479",
    cn = "鬼怪",
    idx = 87,
  },
  {
    n = "goblin",
    u = "1f47a",
    cn = "妖怪",
    idx = 88,
  },
  {
    n = "skull",
    u = "1f480",
    cn = "骷髅",
    idx = 89,
  },
  {
    n = "skull_and_crossbones",
    u = "2620-fe0f",
    cn = "骷髅与交叉骨",
    idx = 90,
  },
  {
    n = "ghost",
    u = "1f47b",
    cn = "鬼魂",
    idx = 91,
  },
  {
    n = "alien",
    u = "1f47d",
    cn = "外星人",
    idx = 92,
  },
  {
    n = "alien monster",
    u = "1f47e",
    cn = "外星怪物",
    idx = 93,
  },
  {
    n = "robot_face",
    u = "1f916",
    cn = "机器人脸",
    idx = 94,
  },
  {
    n = "shit",
    u = "1f4a9",
    cn = "一堆屎",
    idx = 95,
  }
}

local SmileyConfig = NPL.export()

SmileyConfig.smileys_config = nil
SmileyConfig.smiley_symbol = nil
SmileyConfig.smiley_idxs = nil

function SmileyConfig.InitConfig()
    if not SmileyConfig.smileys_config then
        SmileyConfig.smileys_config = {}
        SmileyConfig.smiley_symbol = {}
		SmileyConfig.smiley_idxs = {}
        for _, smiley in ipairs(smileys_people) do
            SmileyConfig.smileys_config[smiley.n] = smiley.u
            SmileyConfig.smiley_symbol[smiley.u] = {cn = smiley.cn, n = smiley.n}
			SmileyConfig.smiley_idxs[smiley.idx] = {cn = smiley.cn, n = smiley.n ,u = smiley.u}
        end
    end
end

function SmileyConfig.GetSmileyIconByCode(code,isFullPath)
    if not code or code == "" then
        return
    end
	local idx = tonumber(code)
	if idx and SmileyConfig.smiley_idxs[idx] then
		code = SmileyConfig.smiley_idxs[idx].u
	end
    local smileyDir = "Texture/Aries/Creator/keepwork/smiley/"
    if isFullPath then
        smileyDir = ParaIO.GetWritablePath()..smileyDir
    end
    local icon = smileyDir..code..".png"
    return icon

end

function SmileyConfig.GetSmileyData()
    local tempSmile = {}
    for _, smileydata in ipairs(smileys_people) do
		local smileycode = smileydata.u
        tempSmile[#tempSmile + 1] = {smileycode = smileycode, idx = smileydata.idx, cn = smileydata.cn, n = smileydata.n,icon = SmileyConfig.GetSmileyIconByCode(smileycode)}
    end
    return tempSmile
end

function SmileyConfig.IsSmiley(code)
    if not code or code == "" then
        return false
    end
	local idx = tonumber(code)
	if idx and SmileyConfig.smiley_idxs[idx] then
		return true
	end
	if SmileyConfig.smiley_symbol[code] then
		return true
	end
	return false
end

function SmileyConfig.FindSmileyCode(text)
    if not text or text == "" then
      return
    end
    local emoji_pattern = "#(%d+)#"
    local isFind = string.find(text, emoji_pattern)
    if isFind then
        local smileyTexts = {}
		local isHaveEmoji = false
        for match in string.gmatch(text, emoji_pattern) do
            if match and match ~= "" and SmileyConfig.IsSmiley(match) then
                smileyTexts[#smileyTexts + 1] = match
				  isHaveEmoji = true
			end
        end
        return isHaveEmoji,smileyTexts
    end
    return isFind,text
end

function SmileyConfig.GenerateBulletHtml(text)
	if not text or text == "" then
		return ""
	end
	local isFind,smileyTexts = SmileyConfig.FindSmileyCode(text)
	local emoji_html = [[<img src="%s" style="width:18px;height:18px;margin-left:2px; margin-top:2px;" />]]
	local all_html = [[<div style="color:#ffffff;font-size:15px;base-font-size:15;font-weight:bold;shadow-quality:8;shadow-color:#8000468e;text-shadow:true">%s</div>]]
	if not isFind then
		return string.format(all_html,text)
	end
	local tempText = ""
	for _, smileyText in ipairs(smileyTexts) do
		local fullText = "#"..smileyText.."#"
		text = string.gsub(text, fullText, string.format(emoji_html,SmileyConfig.GetSmileyIconByCode(smileyText)))
	end
	return string.format(all_html,text)
end

function SmileyConfig.GenerateNormalHtml(text,default_font_size)
	if not text or text == "" then
		return ""
	end
	local isFind,smileyTexts = SmileyConfig.FindSmileyCode(text)
	local emoji_html = [[<img src="%s" style="width:18px;height:18px;margin-left:2px; margin-top:2px;" />]]
	local all_html = [[<div style="font-size:15px;base-font-size:15;">%s</div>]]
    if default_font_size and type(default_font_size) == "number" then
        default_font_size = default_font_size > 0 and default_font_size or 14
        all_html = [[<div style="font-size:]]..default_font_size..[[px;base-font-size:]]..default_font_size..[[px;">%s</div>]]
        emoji_html = [[<img src="%s" style="float:left; width:18px;height:18px;margin-left:2px; margin-top:2px;" />]]
    end
	if not isFind then
		return string.format(all_html,text),isFind
	end
	local tempText = ""
	for _, smileyText in ipairs(smileyTexts) do
		local fullText = "#"..smileyText.."#"
		text = string.gsub(text, fullText, string.format(emoji_html,SmileyConfig.GetSmileyIconByCode(smileyText)))
	end
	return string.format(all_html,text),isFind
end

function SmileyConfig.GenerateChatPageHtml(text,default_font_size)
	if not text or text == "" then
		return ""
	end
	local isFind,smileyTexts = SmileyConfig.FindSmileyCode(text)
	local emoji_html = [[<img src="%s" style="width:18px;height:18px;margin-left:2px; margin-top:2px;" />]]
	local all_html = [[<div style="font-size:15px;base-font-size:15;">%s</div>]]
	if default_font_size and type(default_font_size) == "number" then
		default_font_size = default_font_size > 0 and default_font_size or 14
		all_html = [[<div style="font-size:]]..default_font_size..[[px;base-font-size:]]..default_font_size..[[px;">%s</div>]]
		emoji_html = [[<div style="float:left; width:18px;height:18px;margin-left:2px; margin-top:2px; background:url(%s)" ></div>]]
	end
	if not isFind then
		return string.format(all_html,text),isFind
	end
	local tempText = ""
	for _, smileyText in ipairs(smileyTexts) do
		local fullText = "#"..smileyText.."#"
		text = string.gsub(text, fullText, string.format(emoji_html,SmileyConfig.GetSmileyIconByCode(smileyText)))
	end
	return string.format(all_html,text),isFind
end

function SmileyConfig.CopySmileIcon()
    if not System.options.isInternal then
        return
    end
    local tblSmile = {}
    for smiley, smileycode in pairs(SmileyConfig.smileys_config) do
        tblSmile[#tblSmile + 1] = smileycode
    end

    local srcDir = ParaIO.GetWritablePath().."emoji/"
    local desDir = ParaIO.GetWritablePath().."Texture/Aries/Creator/keepwork/smiley/"    

    local errCodes = {}
    for _, smileCode in ipairs(tblSmile) do
        local srcFile = srcDir..smileCode..".png"
        local desFile = desDir..smileCode..".png"
        print("copy file start:", srcFile, desFile,ParaIO.DoesFileExist(srcFile))
        if ParaIO.DoesFileExist(srcFile) then
            if ParaIO.CopyFile(srcFile, desFile ,true) then
                print("copy file success:", srcFile, desFile)
            else
                errCodes[#errCodes + 1] = smileCode
            end
        else
            errCodes[#errCodes + 1] = smileCode
        end
    end
    if #errCodes > 0 then
        print("copy file fail:", errCodes)
        echo(errCodes)
    end
end


SmileyConfig.InitConfig()
