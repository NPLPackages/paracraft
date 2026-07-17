--[[
    author:{pbb}
    time:2023-02-28 15:03:30
    function:智能批改作业相关
    uselib:
        NPL.load("(gl)script/apps/Aries/Creator/Game/Tutorial/Assessment.lua")
        local Assessment = commonlib.gettable("MyCompany.Aries.Creator.Game.Tutorial.Assessment")

        GameLogic.Assessment:GetUserData("")
]]

NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityManager.lua");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
NPL.load("(gl)script/ide/System/Core/ToolBase.lua")
local Assessment = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"),commonlib.gettable("MyCompany.Aries.Creator.Game.Tutorial.Assessment"))

function Assessment:ctor()
    
end

function Assessment:OnWorldLoaded()
    
end

function Assessment:OnWorldUnLoaded()
    
end

function Assessment:Init()
    self.reviews = {}
    self.score = {}
    self.all_entities = nil
    self.check_options = nil
end

function Assessment:GetAllData()
    if self.mall_data then
       return
    end
	keepwork.mall.menus.get({
		platform =  1,
	},function(err, msg, data)
		if err == 200 and data then
			local menuData={}
			local num = data and #data or 0
			if num > 0 then
				for i=1,num do
					local temp = data[i]
                    if temp then
                        if temp.children and #(temp.children) > 0 then
                            for i,v in ipairs(temp.children) do
                                if string.find(v.name,"全部") then
                                    menuData[#menuData + 1] = {id = v.id,name = v.name,parent_name = temp.name}
                                    break
                                end
                            end
                        else
                            menuData[#menuData + 1] = {id = temp.id,name = temp.name,parent_name = ""}
                        end
                    end
				end
				local mallData = {}
				local good_index = 1
				local menu_num = #menuData
				function funcGet(index)
					if not index or not menuData[index] or not menuData then
						return
					end
					local id = menuData[index].id
					keepwork.mall.goods.get({
						classifyId = id,
						platform = 1,
						["x-per-page"] = 10000,
						["x-page"] = 1,
					},function(err, msg, data)
						if err == 200 and data and data.count and tonumber(data.count) > 0 then
							local temp = {}
							temp.id = id
							temp.name = menuData[index].parent_name ~= "" and menuData[index].parent_name or menuData[index].name
							temp.data = {}
							for i,good in ipairs(data.rows) do
								temp.data[#temp.data + 1] = {id = good.id,name = good.name,description = good.description,type = good.modelType}
							end
							mallData[#mallData + 1] = temp
						end
						good_index = good_index + 1
						if good_index <= #menuData then
							funcGet(good_index)
						else
							self.mall_data = mallData
						end
					end)
				end
				funcGet(good_index)
			end
		end
	end)
end

-----------------------------
--------输入-----------------
-----------------------------

--获得用户的操作体量， 目前客户端已经记录的数据，可以提供访问接口。 field为空代表totalWorkScore， 否则为下面的某个值。
function Assessment:GetUserData(strField)
    NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
    local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon");
    local field = strField or "totalWorkScore"
    return WorldCommon.GetWorldTag(field) or 0;
end

--判断所有用户编辑过的代码方块中， 是否包含某段代码。 支持regular expression 例如 HasUserCode("ggs%s+connect")
function Assessment:HasUserCode(strCode)
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BuildReplay/RecordCode.lua");
    local RecordCode = commonlib.gettable("MyCompany.Aries.Game.Tasks.RecordCode");
    local num = RecordCode:GenerateCode()
    if num <= 0 then
        --添加世界所有代码方块的判断
        return self:SearchFileInWorld(strCode)
    end
    local codeData = RecordCode:GetCodeData()
    for i=1,num do
        local pos = codeData[i] and codeData[i].pos or {}
        if pos and pos[1] then
            local bx, by, bz = pos[1],pos[2],pos[3]
            local entity = EntityManager.GetBlockEntity(bx, by, bz)
            if entity and entity:isa(EntityManager.EntityCode) then
                local code = entity:GetCommand()
                local bFound, filename, filenames = mathlib.StringUtil.FindTextInLine(code, strCode)
                if bFound then
                    return bFound ,filename
                end
            end
        end
    end
    return false
end

function Assessment:GetAllEntities()
    if not self.all_entities then
        self.all_entities = EntityManager.FindEntities({category="all", })
    end
    return self.all_entities
end

--获得bmax文件的数量。 当bIncludeStore为true时，代表统计从商城中下载的模型, 否则只统计用户自己创建的。
function Assessment:GetBMaxFileCount(bIncludeStore)
    local worldpath = ParaWorld.GetWorldDirectory()
    local files = commonlib.Files.Find({},worldpath, 5,5000,"*.bmax")

    local filesTotal = #files
    local storeNum = 0
    for key, value in ipairs(files) do
        if value.filename:find("onlinestore/") then
            storeNum = storeNum + 1
        end
    end
    return bIncludeStore and filesTotal or filesTotal - storeNum
end

-- --获得普通活动模型
function Assessment:GetLiveModelCount(bIncludeLiveModel)
    local entities = self:GetAllEntities()
    -- echo(entities)
end

--是否有某个文件，例如bmax文件， filename支持regular expression, 例如 HasFile("cat%.bmax"),  HasFile("jpg")
function Assessment:HasUserFile(filename)
    local worldpath = ParaWorld.GetWorldDirectory()
    local files = commonlib.Files.Find({},worldpath, 5,5000,"*.*")
    for key, value in ipairs(files) do
        if value.filename:find(filename) then
            return true
        end
    end
    return false
end

--获得场景中某个物品的数量。 例如： 拉杆、代码方块、电影方块的数量。 可以判断， 用户是否在代码方块周围放置拉杆等。 data为nil不匹配data field。
--[[
    "CodeBlock":代码方块 219
    "Lever":拉杆 190
    "MovieClip"：电影方块 228
    "Command_Block":命令方块 212
]]
local objConfig = {
    EntityCode = {blockId=219,blockName="CodeBlock"},
    EntityMovieClip = {blockId=228,blockName="MovieClip"},
    EntityCommandBlock = {blockId=212,blockName="Command_Block"},
}

local findFunc = function(blockId)
    for k,v in pairs(objConfig) do
        if (blockId and (blockId == v.blockId or blockId == v.blockName)) then
            return true
        end
    end
end

local getBlockIdByItemId = function(typeNameOrItemId)
    if typeNameOrItemId == "Lever" or typeNameOrItemId == "lever" or typeNameOrItemId == 190 then
        return 190
    end
    return tonumber(typeNameOrItemId)
end

function Assessment:GetObjectCountByType(typeNameOrItemId,data)
    if not typeNameOrItemId then
        return 0
    end
    NPL.load("(gl)script/apps/Aries/Creator/Game/block_engine.lua");
    local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
    local num = 0
    local rendist =  math.floor(GameLogic.options:GetRenderDist() or 0)
    if not findFunc(typeNameOrItemId) then
        local blockId1 = getBlockIdByItemId(typeNameOrItemId)
        if blockId1 and blockId1 > 0 then
            local player = GameLogic.GetPlayer()
            if player then
                local px,py,pz =player:GetBlockPos()
                local minx,maxx = math.max(px-rendist,0),px+rendist
                local miny,maxy = math.max(py-rendist,0),py+rendist
                local minz,maxz = math.max(pz-rendist,0),pz+rendist
                for x=minx,maxx do
                    for y=miny,maxy do
                        for z=minz,maxz do
                            local blockId ,blockData = BlockEngine:GetBlockIdAndData(x, y, z)
                            if data and data == blockData and blockId == blockId1 then
                                num = num + 1
                            elseif blockId == blockId1 then
                                num = num + 1
                            end
                        end
                    end
                end
            end
            return num
        end
        return 0
    end
    for k,v in pairs(objConfig) do
        if (type(typeNameOrItemId) == "string" and typeNameOrItemId == v.blockName) or (type(typeNameOrItemId) == "number" and typeNameOrItemId == v.blockId) then
            local blockType = k
            local entities = EntityManager.FindEntities({category="b", type=k});
            num = entities and #entities or 0
            return num
        end
    end
end

--是否ggs启动了
function Assessment:IsGGSEnabled()
    NPL.load("Mod/GeneralGameServerMod/App/Client/AppGeneralGameClient.lua");
    local AppGeneralGameClient = commonlib.gettable("Mod.GeneralGameServerMod.App.Client.AppGeneralGameClient");
   return AppGeneralGameClient:IsLogin()
end

--是否任何代码方块有编译错误。 一般只有文本编程需要这样。
function Assessment:HasCompileError()
    local entities = EntityManager.FindEntities({category="b", type="EntityCode"});
    if(entities and #entities>0) then
        local count = 0
        for _, entity in ipairs(entities) do
            if(not entity:IsCodeLoaded()) then
                if(not entity:Compile()) then
                    count = count + 1
                end
            end
        end
        return count > 0
    end
    return false
end

--当前代码运行结果输出的日志窗口中是否有某个value, 支持regular expression.  一般只有文本编程需要这样。
function Assessment:HasLogOutput(strValue)
    if not strValue or strValue == "" then
        return false
    end
    -- NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlockWindow.lua");
    -- local CodeBlockWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockWindow");
    -- local consoleText = CodeBlockWindow.GetConsoleText()
    -- print("consoleText===========",consoleText,type(consoleText))
    -- echo(consoleText)
    NPL.load("(gl)script/apps/Aries/BBSChat/ChatSystem/ChatChannel.lua");
    local ChatChannel = commonlib.gettable("MyCompany.Aries.ChatSystem.ChatChannel");
    local channels = {1,2,3,4,5,6,7,8,9,11,12,13,14}
    local chatdata = ChatChannel.GetChat(channels);
    
    if (chatdata) then
        for i,v in ipairs(chatdata) do
            if v and v.words and v.words:find(strValue) then
                return true
            end
        end
    end
    return false
end

--获取项目ID， 如果空，表示没有分享。 
function Assessment:GetProjectId()
    return GameLogic.options:GetProjectId()
end


--判断世界是否使用了某个文件
function Assessment:SearchFileInWorld(filetext)
    if not filetext or filetext == "" then
        return false
    end
    local results = {};
	local function AddEntity_(entity, filename)
		local item = entity:GetItemClass()
		local nCount = #results;
		if(item and nCount < 2000) then
			nCount = nCount + 1;
			results[nCount] = entity;
			return true;
		end
	end
    local entities = EntityManager.FindEntities({category="all", }) or {};
	local homeEntity = GameLogic.GetHomeEntity()
	if(homeEntity) then
		entities[#entities+1] = homeEntity;
	end
	for _, entity in ipairs(entities) do
		if(entity.FindFile) then
			local bFound, filename, filenames = entity:FindFile(filetext)
			if(bFound) then
				if(filenames) then
					local bFailed;
					for _, filename_ in ipairs(filenames) do
						if(not AddEntity_(entity, filename_)) then
							bFailed = true;
							break;
						end
					end
					if(bFailed) then
						break;
					end
				elseif(not AddEntity_(entity, filename)) then
					break;
				end
			end
		end
	end
    if next(results) then
        return true
    end
    return false
end

--判断模型是否有某个属性
function Assessment:IsHaveAttribute(name)
    local entities = EntityManager.FindEntities({category="all", }) or {};
    for _,entity in pairs(entities) do
        if entity and entity[name] then
            return entity[name] == true
        end
    end
    return false
end

--用户是否使用某个类型的文件（主要是）
function Assessment:CheckUsedFile(category)
    NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/PlayerAssetFile.lua");
    local PlayerAssetFile = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerAssetFile")

    NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/OpenAssetFileDialog.lua");
    local OpenAssetFileDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.OpenAssetFileDialog");

    local isFindInAsset,isFindInmall = false,false
    local categoryData = {}
    local categoryData1 = {}
    for i,v in ipairs(OpenAssetFileDialog.categories) do
        if v.name:find(category) or v.text:find(category) then
            isFindInAsset = true
            categoryData = PlayerAssetFile:GetCategoryItems(v.name)
            break
        end
    end

    if (self.mall_data) then
        for i,v in pairs(self.mall_data) do
            if v.name and v.name:find(category) then
                isFindInmall = true
                categoryData1 = v.data
                break
            end
        end
    end
    local entities = EntityManager.FindEntities({category="all", }) or {};
    for _, entity in ipairs(entities) do
        local modelFile  = string.lower((entity and entity.GetModelFile) and entity:GetModelFile() or "")
        if isFindInAsset then
            for i,v in ipairs(categoryData) do
                if modelFile:find(string.lower(v.name)) then
                    return true
                end
            end
        end
        if isFindInmall then
            for i,v in ipairs(categoryData1) do
                if modelFile:find(string.lower(v.name)) or modelFile:find(string.lower(v.description)) then
                    return true
                end
            end
        end
    end
	return false
end

--添加分数判定条件,S A B C D
function Assessment:AddCheckOptions(optionName)
    if not self.check_options then
        self.check_options = {}
    end
    self.check_options[#self.check_options + 1] = {optionName = optionName,isFinished = false}
end

--完成某个判定条件
function Assessment:FinishCheckOptions(optionName)
    if self.check_options then
        for k,v in pairs(self.check_options) do
            if optionName and v.optionName == optionName then
                v.isFinished = true
                break
            end
        end
    end
end

--是否完成
function Assessment:IsFinishOption(optionName)
    if self.check_options then
        for k,v in pairs(self.check_options) do
            if optionName and v.optionName == optionName then
                return v.isFinished 
            end
        end
    end
    return false
end

function Assessment:GetWorkMark()
    if self.check_options then
        local count = 0
        local finishOptions = {}
        for k,v in pairs(self.check_options) do
            if v and v.isFinished then
                count = count + 1
                finishOptions[#finishOptions + 1] = {v.optionName}
            end
        end
        return count,self.reviews,finishOptions,self.knowledge
    end
end

--[[ {text=L"建造", name="static"   },
    {text=L"电影", name="movie"   },
    {text=L"代码", name="character"},
    {text=L"背包", name="playerbag"   },
    {text=L"机关", name="gear"	   },
    {text=L"装饰", name="deco"     },
	{text=L"工具", name="tool"	   },
	{text=L"模板", name="template" },]]
--搜索分类目录下的方块数量
function Assessment:SearchBlockNumByCategory(category)
    if not category or category == "" then
        return 999999
    end
    NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua");
    local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
    NPL.load("(gl)script/apps/Aries/Creator/Game/block_engine.lua");
    local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
    local ds_src = ItemClient.GetBlockDS(category);
    if ds_src and #ds_src > 0 then
        local num = 0
        local block_map = {}
        for index, item in ipairs(ds_src) do 
            if(item.block_id) then
                block_map[item.block_id] = true
            end
        end
        local rendist =  math.floor(GameLogic.options:GetRenderDist() or 0)
        local player = GameLogic.GetPlayer()
        if player then
            local px,py,pz =player:GetBlockPos()
            local minx,maxx = math.max(px-rendist,0),px+rendist
            local miny,maxy = math.max(py-rendist,0),py+rendist
            local minz,maxz = math.max(pz-rendist,0),pz+rendist
            for x=minx,maxx do
                for y=miny,maxy do
                    for z=minz,maxz do
                        local blockId ,blockData = BlockEngine:GetBlockIdAndData(x, y, z)
                        if blockId and blockId > 0 and block_map[blockId] then
                            num = num + 1
                        end
                    end
                end
            end
        end
        return num
    end
    return  0
end
-----------------------------
--------输出-----------------
-----------------------------

--[[增加一行Review， 注意这里会自动随机同类的话。order代表优先级，相同优先级按照添加次序排序。 否则从小到大排序。 默认为0.
type可以是warn警告, error错误, advice建议, good点赞： 展示在UI上会颜色区分。 ]]
function Assessment:AddReview(type,line,order)
    if not self.reviews then
        self.reviews = {}
    end
    self.reviews[#self.reviews + 1] = {type = type,line = line,order=(order or 0)}
end

function Assessment:SortReview()
    if self.reviews and #self.reviews > 0 then
        table.sort( self.reviews,function(a,b)
            return a.order < b.order
        end)
    end
end

function Assessment:GenerateReviewsToLine()
    self:SortReview()

end

--清空缓存中所有review
function Assessment:ClearReview()
    if self.reviews and #self.reviews > 0 then
        self.reviews = {}
    end
end

--增加某个方面的分数，策划给出某些维度
function Assessment:AddScore(name, value)
    if not self.score then
        self.score = {}
    end
    self.score[name] = value
end

--截图到裁剪版
function Assessment:TakeScreenshotToClipboard()
    
end

--获得全部review
function Assessment:GetReview()
    return self.reviews
end

--获得全部Score
function Assessment:GetScore()
    return self.score
end

--添加知识点
function Assessment:AddKnowledges(strKnowledge)
    self.knowledge = strKnowledge
end

--向后台发送review,score等数据，并回调。
function Assessment:Submit(callbackFunc)
    if callbackFunc then
        callbackFunc()
    end
    if true then
        local RedSummerCampPPtPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampPPtPage.lua");
        local count,reviews,options = self:GetWorkMark()
        local assessmentData = {}
        assessmentData.finishCount = count or 0
        assessmentData.options = options or {}
        assessmentData.reviews = reviews or {}
        if reviews then
            for k,v in pairs(reviews) do
                if v.line and v.line ~= "" then
                    assessmentData.line = v.line
                    break
                end 
            end
        end
        RedSummerCampPPtPage.SetAssessmentData(assessmentData)
        return
    end
    local AssessmentQueue = NPL.load("(gl)script/apps/Aries/Creator/Game/Tutorial/AssessmentQueue.lua")
    AssessmentQueue.FinishCurAssessment()
end

-- 初始化成单列模式
Assessment:InitSingleton();

