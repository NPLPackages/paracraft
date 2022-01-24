NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SelectBlocksTask.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityMovieClip.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/MovieClipController.lua");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local EntityMovieClip =  commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityMovieClip")
local SelectBlocks = commonlib.gettable("MyCompany.Aries.Game.Tasks.SelectBlocks");
local MovieClipCompare = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/World2In1/MovieClipCompare.lua");

local MovieClipController = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieClipController");
local LessonBoxCompare = NPL.export()

function LessonBoxCompare.GetFilePath(filename)
	local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
	if (filename == "") then
		templatename = "default";
	end
	if(filename:match("^~")) then
		filename = ParaIO.GetWritablePath().."temp"..filename:sub(2, -1)
	end
	if(not filename:match("%.xml$") and not filename:match("%.bmax$")) then
		filename = filename .. ".blocks.xml";
	end
	local fullpath;
	if(commonlib.Files.IsAbsolutePath(filename)) then
		fullpath = filename;
	else
		fullpath = Files.GetWorldFilePath(filename) or (not filename:match("[/\\]") and Files.GetWorldFilePath("blocktemplates/"..filename));
	end
	
	if(not fullpath and ParaIO.DoesFileExist(filename, true)) then
		fullpath = filename;
	end
	return fullpath
end

function LessonBoxCompare.GetBlocksByFile(filename)
	local xmlRoot = ParaXML.LuaXML_ParseFile(filename or "");
	if(not xmlRoot) then
		xmlRoot = ParaXML.LuaXML_ParseFile(commonlib.Encoding.Utf8ToDefault(filename));
	end
	local blocksConfig = {}
	if(xmlRoot) then
		local template_node = commonlib.XPath.selectNode(xmlRoot, "/pe:blocktemplate");
		blocksConfig.player_pos = template_node.attr.player_pos;
		blocksConfig.pivot = template_node.attr.pivot;
		blocksConfig.name = template_node.attr.name;
		local node = commonlib.XPath.selectNode(xmlRoot, "/pe:blocktemplate/pe:blocks");
		if(node and node[1]) then
			local blocks = NPL.LoadTableFromString(node[1]) or {};
			-- echo(blocks,true)
			local offset_x, offset_y, offset_z = 0,0,0;
			if(offset_x or offset_y or offset_z) then
				offset_x = offset_x or 0;
				offset_y = offset_y or 0;
				offset_z = offset_z or 0;
				for i=1, #(blocks) do
					local block = blocks[i];
					block[1] = block[1] + offset_x;
					block[2] = block[2] + offset_y;
					block[3] = block[3] + offset_z;
				end
			end

			blocksConfig.blocks = blocks;
		end
	else
		LOG.std(nil, "error", "LessonBoxCompare", "can not open file %s", filename or "");
	end
	return blocksConfig
end

--[[
local LessonBoxCompare = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/World2In1/LessonBoxCompare.lua");
if LessonBoxCompare then
    GameLogic.RunCommand("/loadtemplate 19298,5,19370 2222")
    local needBuild = LessonBoxCompare.CompareTemplate("2222","111")
    echo(needBuild,true)
    local blocks = needBuild.blocks
    local startX,startY,startZ =19298,5,19370
    for i=1,#blocks do
        local block = blocks[i]
        local x,y,z = startX+block[1],startY+block[2],startZ+block[3]
        ParaTerrain.SelectBlock(x,y,z, true, 6)
    end
end]]

function LessonBoxCompare.FindBlockByAnother(block)
	if not block or not block[1] then
		return 
	end

end

function LessonBoxCompare.GetDiffBlocksAndType(blockSrc,blockDest)
	if not blockSrc or not blockDest then
		return 
	end
	local needBuild = {}
	needBuild.movies = {}
	needBuild.codes = {}
	local numSrc = #blockSrc
	local numDest = #blockDest
	for i = 1,numSrc do
		local block1 = blockSrc[i]
		for j = 1,numDest do
			local block2 = blockDest[j]
			if block1[1] == block2[1] and block1[2] == block2[2] and block1[3] == block2[3] then --位置相同
				if block1[4] == block2[4] or (block1[4] == 75 and block2[4] == 76) or (block1[4] == 76 and block2[4] == 75) then --方块类型相同
					if block1[5] == block2[5] or (block1[4] == 250 and block2[4] == 250) then
						block1.have = true
						block2.have = true
					end	
					if block1[4] == block_types.names.MovieClip then
						needBuild.movies[#needBuild.movies + 1] = {block1,block2}
					end
					if block1[4] == block_types.names.CodeBlock then
						needBuild.codes[#needBuild.codes + 1] = {block1,block2}
					end				
				end
			end
		end
	end

	--处理剩下的方块
	local tempSrcBlocks = {}
	local tempDestBlocks = {}
	for i=1,numDest do
		if not blockDest[i].have then
			tempDestBlocks[#tempDestBlocks + 1] = blockDest[i]
		end
	end
	for i=1,numSrc do
		if not blockSrc[i].have then
			tempSrcBlocks[#tempSrcBlocks + 1] = blockSrc[i]
		end
	end

	--去掉blockid相同的方块，这个只需要处理一遍
	for i = 1,#tempSrcBlocks do
		local block1 = tempSrcBlocks[i]
		for j = 1,#tempDestBlocks do
			local block2 = tempDestBlocks[j]
			if block1[1] == block2[1] and block1[2] == block2[2] and block1[3] == block2[3] then --位置相同
				if not (block1[4] == block2[4] or (block1[4] == 75 and block2[4] == 76) or (block1[4] == 76 and block2[4] == 75)) then --方块类型相同
					block2.have = true	
					block1[4] = block2[4]
				else
					if block1[5] ~= block2[5] then
						block2.have = true
						block1[5] = block2[5]
					end
				end
			end
		end
	end

	--合并不一样的方块数据
	local tempBlocks = {}
	for i=1,#tempDestBlocks do
		if not tempDestBlocks[i].have then
			tempBlocks[#tempBlocks + 1] = tempDestBlocks[i]
		end
	end
	for i=1,#tempSrcBlocks do
		if not tempSrcBlocks[i].have then
			tempBlocks[#tempBlocks + 1] = tempSrcBlocks[i]
		end
	end
	--判断处理的类型
	needBuild.blocks = tempBlocks
	if numSrc < numDest then --添加方块
		needBuild.nAddType = 1
	end
	if numSrc > numDest then --删除方块
		needBuild.nAddType = 2
	end
	if numSrc == numDest then	--方块数目一致
		needBuild.nAddType = 3
		-- tempBlocks = {}
		-- for i=1,numSrc do
		-- 	if not blockSrc[i].have then
		-- 		tempBlocks[#tempBlocks + 1] = blockSrc[i]
		-- 	end
		-- end
	end
	return needBuild
end

function LessonBoxCompare.CompareTemplate(filenameSrc,filenameDest,isfullpath)
	local blockConfigSrc,blockConfigDest
	if isfullpath then
		blockConfigSrc = LessonBoxCompare.GetBlocksByFile(filenameSrc)
		blockConfigDest = LessonBoxCompare.GetBlocksByFile(filenameDest)
	else
		blockConfigSrc = LessonBoxCompare.GetBlocksByFile(LessonBoxCompare.GetFilePath(filenameSrc))
		blockConfigDest = LessonBoxCompare.GetBlocksByFile(LessonBoxCompare.GetFilePath(filenameDest))
	end
	local needBuild = LessonBoxCompare.GetDiffBlocksAndType(blockConfigSrc.blocks,blockConfigDest.blocks)
	if needBuild then
		return needBuild
	end
end

function LessonBoxCompare.GetRegionData(regionSrc,regionDest,callback)
	if not regionSrc or not regionDest then
		return 
	end
	local pos = regionSrc.pos
	local size = regionSrc.size 
	local pivotConfig = {}
	local cmdStr = string.format("/select %d %d %d (%d %d %d)", pos[1], pos[2], pos[3], size[1], size[2], size[3])
	GameLogic.RunCommand(cmdStr)
	local blocksSrc,blocksDest
	local select_task = SelectBlocks.GetCurrentInstance();
	local createpos = nil
	if select_task then
		local pivot_x, pivot_y, pivot_z = select_task:GetSelectionPivot();
		pivotConfig.createpos = {pivot_x, pivot_y, pivot_z}
        blocksSrc = select_task:GetCopyOfBlocks({pivot_x, pivot_y, pivot_z});
		GameLogic.RunCommand("/select -clear")
	end
	

	
	commonlib.TimerManager.SetTimeout(function()  
		pos = regionDest.pos
		size = regionDest.size 
		cmdStr = string.format("/select %d %d %d (%d %d %d)", pos[1], pos[2], pos[3], size[1], size[2], size[3])
		GameLogic.RunCommand(cmdStr)
		select_task = SelectBlocks.GetCurrentInstance();
		if select_task then
			local pivot_x, pivot_y, pivot_z = select_task:GetSelectionPivot();
			pivotConfig.srcPivot = {pivot_x, pivot_y, pivot_z}
			blocksDest = select_task:GetCopyOfBlocks({pivot_x, pivot_y, pivot_z}); 
		end
		GameLogic.RunCommand("/select -clear")
		if callback then
			callback(blocksSrc,blocksDest,pivotConfig)
		end
	end, 100);
end

--[[
local LessonBoxCompare = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/World2In1/LessonBoxCompare.lua");
if LessonBoxCompare then
    local regionsrc = {pos={19312,5,19371},size={10,8,13}}
    local regiondest = {pos={19312,5,19354},size={10,8,13}}
    LessonBoxCompare.CompareTwoAreas(regionsrc,regiondest,function(needbuild)
        echo(needbuild,true)
    end)
end]]
--不适用于很大的区块比较，大区块比较尽量先存成template文件，再进行比较
function LessonBoxCompare.CompareTwoAreas(regionSrc,regionDest,callback)
	LessonBoxCompare.GetRegionData(regionSrc,regionDest,function(blockSrc,blockDest,pivotConfig)
		if blockSrc and blockDest then
			local needBuild = LessonBoxCompare.GetDiffBlocksAndType(blockSrc,blockDest)
			if callback then
				callback(needBuild,pivotConfig)
			end
		end
	end)
end

function LessonBoxCompare.CompareAreaWithTemplate(regionSrc,strDest,callback)
	local pos = regionSrc.pos
	local size = regionSrc.size 
	local pivotConfig = {}
	local cmdStr = string.format("/select %d %d %d (%d %d %d)", pos[1], pos[2], pos[3], size[1], size[2], size[3])
	GameLogic.RunCommand(cmdStr)
	local blocksSrc,blocksDest
	local select_task = SelectBlocks.GetCurrentInstance();
	local createpos = nil
	if select_task then
		local pivot_x, pivot_y, pivot_z = select_task:GetSelectionPivot();
		pivotConfig.createpos = {pivot_x, pivot_y, pivot_z}
        blocksSrc = select_task:GetCopyOfBlocks({pivot_x, pivot_y, pivot_z});
		GameLogic.RunCommand("/select -clear")
	end
	local blocksConfig = LessonBoxCompare.GetBlocksByFile(LessonBoxCompare.GetFilePath(strDest))
	blocksDest = blocksConfig.blocks
	if blocksSrc and blocksDest then
		local needBuild = LessonBoxCompare.GetDiffBlocksAndType(blocksSrc,blocksDest)
		if callback then
			-- echo(needBuild,true)
			callback(needBuild,pivotConfig)
		end
	end
end

_G.MOVIE_COMPARE_TYPE = {
    ENTITY_NULL = -1,
    ENTITY_SLOT = 1,
    ENTITY_TIME_LENGTH = 2,
    ENTITY_TIME_LINE = 3,
    ENTITY_TEXT = 4,
    ENTITY_TIME = 5,
    ENTITY_CMD = 6,
    ENTITY_CHILD_MOVIE = 7,
    ENTITY_MUSIC = 8,
    ENTITY_POSITION = 9,
    ENTITY_ROTATE = 10,
    ENTITY_PARENT = 11,
    ENTITY_ACTOR_ANI = 12,
    ENTITY_ACTOR_BONE = 13,
    ENTITY_ACTOR_POS = 14,
    ENTITY_ACTOR_SCALE = 15,
    ENTITY_ACTOR_HEAD = 16,
    ENTITY_ACTOR_SPEED = 17,
    ENTITY_ACTOR_MODEL = 18,
    ENTITY_ACTOR_OPCATITY = 19,
    ENTITY_ACTOR_PARENT = 20,
    ENTITY_ACTOR_NAME = 21,
}

function LessonBoxCompare.CompareMovie(entitySrc,entityDest,compareType)
	local diff_num, compare_date = 0
    if entitySrc and entityDest then
        if compareType == "slot" then
            diff_num, compare_date = entitySrc:CompareSlot(entityDest)
        end
        if compareType == "timelength" then
            diff_num, compare_date = entitySrc:CompareTimeLength(entityDest)
        end
		-- 关键帧比较
        if compareType == "timeline" then
            diff_num, compare_date = entitySrc:CompareTimes(entityDest)
        end
        if compareType == "text" then
            diff_num, compare_date = entitySrc:CompareText(entityDest)
        end
        if compareType == "time" then
            diff_num, compare_date = entitySrc:CompareTime(entityDest)
        end
        if compareType == "cmd" then
            diff_num, compare_date = entitySrc:CompareCmd(entityDest)
        end
        if compareType == "child_movie_block" then
            diff_num, compare_date = entitySrc:CompareMovieBlock(entityDest)
        end
        if compareType == "backmusic" then
            diff_num, compare_date = entitySrc:CompareMusic(entityDest)
        end
        if compareType == "lookat" then
            diff_num, compare_date = entitySrc:ComparePosition(entityDest)
        end
        if compareType == "rotation" then
            diff_num, compare_date = entitySrc:CompareRotation(entityDest)
        end
        if compareType == "parent" then
            diff_num, compare_date = entitySrc:CompareParent(entityDest)
        end
        if compareType == "actor_ani" then
            diff_num, compare_date = entitySrc:CompareActorAni(entityDest)
        end
        if compareType == "actor_bone" then
            diff_num, compare_date = entitySrc:CompareActorBones(entityDest)
        end
        if compareType == "actor_pos" then
            diff_num, compare_date = entitySrc:CompareActorPosition(entityDest)
        end
		if compareType == "actor_turn" then
            diff_num, compare_date = entitySrc:CompareActorRotation(entityDest, true)
        end
        if compareType == "actor_rotation" then
            diff_num, compare_date = entitySrc:CompareActorRotation(entityDest)
        end
        if compareType == "actor_scale" then
            diff_num, compare_date = entitySrc:CompareActorScale(entityDest)
        end
        if compareType == "actor_head" then
            diff_num, compare_date = entitySrc:CompareActorHead(entityDest)
        end
        if compareType == "actor_speed" then
            diff_num, compare_date = entitySrc:CompareActorSpeed(entityDest)
        end
        if compareType == "actor_model" then
            diff_num, compare_date = entitySrc:CompareActorModel(entityDest)
        end
        if compareType == "actor_opcatiity" then
            diff_num, compare_date = entitySrc:CompareActorOpcatity(entityDest)
        end
        if compareType == "actor_parent" then
            diff_num, compare_date = entitySrc:CompareActorParent(entityDest)
        end
        if compareType == "actor_name" then
            diff_num, compare_date = entitySrc:CompareActorName(entityDest)
        end
        if compareType == "weather" then
            diff_num, compare_date = entitySrc:CompareWeather(entityDest)
        end
        if compareType == "actor_skin" then
            diff_num, compare_date = entitySrc:CompareActorSkin(entityDest)
        end
    end
    return diff_num, compare_date
end

function LessonBoxCompare.CompareMovieClip(entitySrc,entityDest)
	local types = {"slot","timelength","timeline","text","time","cmd","child_movie_block","backmusic","lookat","rotation","parent",
	"actor_ani","actor_bone","actor_pos","actor_scale","actor_head","actor_speed","actor_model","actor_opcatiity","actor_parent","actor_name"}
	for i=1,#types do
		local curType = types[i]
		local bSame,rType = LessonBoxCompare.CompareMovie(entitySrc,entityDest,curType)
		if not bSame then
			return bSame,rType
		end
	end
end

_G.CODE_COMPARE_TYPE = {
	ENTITY_NULL = -1,
    ENTITY_BLOKLY_DIFF = 1,        ---不同的代码类型（原始，google图块，npl图块）
    ENTITY_SAME = 2,                ---相同代码
    ENTITY_DIFF_NPLCODE = 3,        ---原始代码
    ENTITY_DIFF_NPLBLOCKLYCODE = 4, ---wxa blockly代码图块
    ENTITY_DIFF_BLOCKLYCODE = 5,    ---google代码图块
}
function LessonBoxCompare.CompareCode(entitySrc,entityDest)
    if not (entitySrc and entityDest) then
        return false,CODE_COMPARE_TYPE.ENTITY_NULL
    end
    local strSrcCode = ""
    local strDestCode = ""
    local isBlocklyEditMode = entityDest.isBlocklyEditMode
    if entitySrc.isBlocklyEditMode == entityDest.isBlocklyEditMode then
        if entityDest.isBlocklyEditMode == true then
            if entityDest.isUseNplBlockly == entitySrc.isUseNplBlockly then
                if entityDest.isUseNplBlockly == true then --使用nplblockly图块
                    strSrcCode = string.gsub(entitySrc.npl_blockly_nplcode,"\n","")
                    strDestCode = string.gsub(entityDest.npl_blockly_nplcode,"\n","")
                    if strSrcCode == strDestCode then
                        return true,CODE_COMPARE_TYPE.ENTITY_SAME
                    else
                        return false,CODE_COMPARE_TYPE.ENTITY_DIFF_NPLBLOCKLYCODE
                    end
                else
                    strSrcCode = string.gsub(entitySrc.blockly_nplcode,"\n","")
                    strDestCode = string.gsub(entityDest.blockly_nplcode,"\n","")
                    if strSrcCode == strDestCode then
                        return true,CODE_COMPARE_TYPE.ENTITY_SAME
                    else
                        return false,CODE_COMPARE_TYPE.ENTITY_DIFF_BLOCKLYCODE
                    end
                end
            end
        else
            strSrcCode = string.gsub(entitySrc.nplcode,"\r\n","")
            strDestCode = string.gsub(entityDest.nplcode,"\r\n","")
            if strSrcCode == strDestCode then
                return true,CODE_COMPARE_TYPE.ENTITY_SAME
            else
                return false,CODE_COMPARE_TYPE.ENTITY_DIFF_NPLCODE
            end
        end
    end
    return false,CODE_COMPARE_TYPE.ENTITY_BLOKLY_DIFF
end

local MoviceCompareType = {
	"slot", 				-- 电影方块元素数量 演员 or 摄像机 or 命令序列
	"timelength", 			-- 电影时长
	"timeline",				-- 关键帧数量
	"text",					-- 电影使用的文本
	"time",					-- 时间
	"cmd",					-- 命令
	"child_movie_block",
	"backmusic",
	"lookat",
	"rotation",
	"parent",
	"eye_dist",
	"actor_ani",
	"actor_pos",
	"actor_turn",
	"actor_rotation",
	"actor_scale",
	"actor_head",
	"actor_speed",
	"actor_model",
	"actor_opcatiity",
	"actor_parent",
	"actor_name",
	"actor_bone",
	"actor_skin",
	"weather",
}

local CompareNameToMovieName = {
	-- 摄影机
	["ActorCamera"] = {
		["text"] = {"text"},
		["time"] = {"time"},
		-- ["weather{"] = ""},
		-- ["blocks{"] = ""},
		["cmd"] = {"cmd"},
		-- ["movieblock{"] = ""},
		["music"] = {"backmusic"},
		["pos"] = {"lookat_x","lookat_y","lookat_z"},
		["rot"] = {"eye_liftup","eye_rot_y","eye_roll"},
		["scaling"] = {"eye_dist"},
		["is_fps"] = {""},
		-- ["parent"] = {""},
		["static"] = {""},
		special_tab = {
			["eye_liftup"] = "rot",
			["eye_rot_y"] = "rot",
			["eye_roll"] = "rot",
			["lookat_x"] = "pos",
			["lookat_y"] = "pos",
			["lookat_z"] = "pos",
			["eye_dist"] = "scaling",
		}
	},
	-- 角色
	["ActorNPC"] = {
		["anim"] = {"actor_ani"},
		["bones"] = {"actor_bone"},
		["pos"] = {"actor_pos"},
		["facing"] = {"actor_turn"},
		["rot"] = {"actor_rotation"},
		["scaling"] = {"actor_scale"},
		["head"] = {"actor_head"},
		["speedscale"] = {"actor_speed"},
		-- ["gravity"] = {""},
		["assetfile"] = {"actor_model"},
		["skin"] = {"actor_skin"},
		["opacity"] = {"actor_opcatiity"},
		["parent"] = {"actor_parent"},
		special_tab = {
			["x"] = "pos",
			["y"] = "pos",
			["z"] = "pos",
		}
		-- ["blockinhand"] = {""},
		-- ["blocks"] = {""},
		-- ["parent"] = {""},
		-- ["cam_dist"] = {""},
		-- ["static"] = {""},
	},
	-- 命令
	["ActorCommands"] = {
		["text"] = {""},
		["time"] = {"time"},
		["weather"] = {"weather"},
		["blocks"] = {""},
		["cmd"] = {""},
		["movieblock"] = {""},
		["music"] = {""},
	},


}

function LessonBoxCompare.CompareMovieAll(entitySrc,entityDest, compare_list)
	local result_list = {}

	compare_list = compare_list or MoviceCompareType
	for key, v in pairs(compare_list) do
		local diff_num, result = LessonBoxCompare.CompareMovie(entitySrc,entityDest,v)
		if diff_num > 0 then
			result_list[v] = result
		end
	end
	
	return result_list
end

function LessonBoxCompare.GetMoviceCompareType()
	return MoviceCompareType
end

-- 用于电影方块左下角菜单的颜色背景显示
function LessonBoxCompare.CheckNeedCreateMoviceMenuCompareBg(compare_data, name, class_name)
	if LessonBoxCompare.CheckKeyDiff(compare_data, name, class_name) then
		return true
	end

	if LessonBoxCompare.CheckTimeLineNums(compare_data, name, class_name) then
		return true
	end

	return false
end

-- 比较关键帧是否有差异
function LessonBoxCompare.CheckKeyDiff(compare_data, name, class_name)
	local compare_config = CompareNameToMovieName[class_name]

	local function check_result(check_name)
		if compare_config and compare_config[check_name] then
			local compare_name_list = compare_config[check_name]
			for key, v in pairs(compare_name_list) do
				if compare_data[v] then
					return true
				end
			end
		end

		return false
	end

	-- facing 先检查rot 三轴旋转与转身特殊处理 显示转身的时候 如果有三轴旋转 只提示三轴旋转
	if name == "facing" and check_result("rot") then
		return false
	end

	if check_result(name) then
		return true
	end

	return false
end

-- 检测关键帧数量
function LessonBoxCompare.CheckTimeLineNums(compare_data, name, class_name)
	local compare_config = CompareNameToMovieName[class_name]
	-- 这块目前是处理timeline的
	local cur_select_slot = MovieClipController.GetCurSelectSlotIndex()
	for k, v in pairs(compare_data) do
		local slot_data = v[cur_select_slot]
		if type(slot_data) == "table" then
			if name == "rot" and (slot_data["pitch"] or slot_data["roll"]) then
				return true
			end
			
			if  slot_data and slot_data[name] then
				-- facing 跟 roll特殊处理 有三轴旋转优先三轴旋转提示
				if name == "facing" and (slot_data["pitch"] or slot_data["roll"]) then
					return false
				end
	
				return true
			end

			if compare_config.special_tab then
				local special_tab = compare_config.special_tab
				for k2, v2 in pairs(slot_data) do
					if special_tab[k2] == name then
						return true
					end
				end
			end

		end
	end

	return false
end

function LessonBoxCompare.GetMovieMenuName(pro_name)
	for k2, compare_config in pairs(CompareNameToMovieName) do
		if compare_config.special_tab and compare_config.special_tab[pro_name] then
			return compare_config.special_tab[pro_name]
		end
	end

	return pro_name
end
--[[
local LessonBoxCompare = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/World2In1/LessonBoxCompare.lua");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local entity1 = EntityManager.GetBlockEntity(18668,14,19441)
local entity2 = EntityManager.GetBlockEntity(18668,14,19446)
local entity3 = EntityManager.GetBlockEntity(18665,14,19441)
local entity4 = EntityManager.GetBlockEntity(18665,14,19446)

local isSame,type = LessonBoxCompare.CompareCode(entity1,entity3)
local isSame2,type2 = LessonBoxCompare.CompareCode(entity1,entity2)
echo({isSame,type})
echo({isSame2,type2})
]]
