--[[
    author:{pbb}
    time:2022-07-11 17:58:40
    uselib:
        NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BuildReplay/RecordCode.lua");
        local RecordCode = commonlib.gettable("MyCompany.Aries.Game.Tasks.RecordCode");
        local num = RecordCode:GenerateCode()
        RecordCode:SetMacroSpeed(6)
        if num > 0 then
            local playTime = 5
            local totaltime = self:GetTotalPlayTime()
            print("totaltime===========",totaltime)
            RecordCode:StartPlay(playTime,function()
                GameLogic.AddBBS(nil,"结束了")
            end)
        end
]]
NPL.load("(gl)script/ide/System/Core/ToolBase.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlockWindow.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/block_engine.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local CodeBlockWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockWindow");
local RecordCode = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"),commonlib.gettable("MyCompany.Aries.Game.Tasks.RecordCode"))
local block_speed = 1
local code_speed = 20
function RecordCode:OnInit()
    self.record_data = {}
    self.current_entity = nil
    self.code_key = "world_edit_code"
    self:RegisterEvent()
    self.total_play_time = 0
    self.finish_call_back = nil
    self.macro_speed = 1
    self.code_edit_line = 0
end

function RecordCode:SetMacroSpeed(speed)
    if speed and speed > 0 then
        self.macro_speed = speed
    end
end

function RecordCode:RegisterEvent()
    GameLogic.GetFilters():add_filter("CodeBlockEditorOpened",function(codeBlockWindow, entity,codeEntity)
        self:OnSetCodeEntity(codeEntity)
    end)
end

function RecordCode:RegisterCodeWindowEvent(bRegister)
    if bRegister then
        GameLogic.GetEvents():AddEventListener("CodeBlockWindowShow",RecordCode.ShowCodeBlockWindow,RecordCode,"RecordCode");
        GameLogic.GetCodeGlobal():RegisterTextEvent("macroFinished", function()
            GameLogic.Macros.SetShowTrigger(true)
            self:PlayCodeMacro(self.finish_call_back)
        end)
        return 
    end
    GameLogic.GetEvents():RemoveEventListener("CodeBlockWindowShow",RecordCode.ShowCodeBlockWindow,RecordCode)
    GameLogic.GetCodeGlobal():UnregisterTextEvent("macroFinished", function()
        GameLogic.Macros.SetShowTrigger(true)
        self:PlayCodeMacro(self.finish_call_back)
    end)
end

function RecordCode:GetTempPath()
    return ParaIO.GetWritablePath().."temp/"
end

function RecordCode:GetWorldPath()
    return GameLogic.GetWorldDirectory()
end

function RecordCode:IsReadOnlyWorld()
    return GameLogic.IsReadOnly()
end

local xmlSavePath = "user_code_data.xml"
function RecordCode:OnWorldLoaded()
    self:RegisterCodeWindowEvent(true)
    self.record_data = {}
    self.code_edit_line = 0
    self.current_entity = nil
    if not self:IsReadOnlyWorld() then --清除tag.xml中的code数据，移到xml文件中
        local isBuild,writeLineNum = self:BuildXmlFileFromTag()
        if isBuild then
            WorldCommon.SetWorldTag(self.code_key,"")
            WorldCommon.SetWorldTag("editCodeLine",writeLineNum or 0)
            WorldCommon.SaveWorldTag()
        end
    end
    self:MoveXmlInfoFile()
    self:MoveCodeInfoFile()
    self:LoadWorldCodeData()
end

function RecordCode:BuildXmlFileFromTag() --兼容原先的tag数据
    local codeStr = WorldCommon.GetWorldTag(self.code_key)
    if codeStr and codeStr ~= "" then
        local record_data = NPL.LoadTableFromString(codeStr)
        local filename = GameLogic.GetWorldDirectory().."stats/"..xmlSavePath
        local root = {name='user_code_map', attr={file_version="0.1"} }
        local temp = {}
        local writeLineNum = 0
        for k,v in pairs(record_data) do
            local pos = v.pos
            local bx,by,bz = unpack(pos)
            local newKey = (bx or 0) * 100000000 +  (by or 0) * 1000000 + (bz or 0)
            if not temp[newKey] and (v.writeLineNum and v.writeLineNum > 0) then
                root[#root+1] = {
                    name = "value",
                    attr = {id = newKey,pos = commonlib.serialize_compact(pos),IsEdit = v.IsEdit or false,editTime = v.editTime or 0,writeLineNum = v.writeLineNum or 0}
                }
                writeLineNum = writeLineNum + (v.writeLineNum and v.writeLineNum or 0)
                temp[newKey] = true
            end
        end
        local xml_data = commonlib.Lua2XmlString(root, true, true) or "";
        local writer = ParaIO.CreateZip(filename, "");
        if (writer:IsValid()) then
            writer:ZipAddData("data", xml_data);
            writer:close();
        end
        return true,writeLineNum;
    end
end

function RecordCode:OnBeforeWorldSave()
    self:SetWorldCodeData()
    self:MergeROWCD()
end

---user_code_data.xml中加载代码数据,世界本地的
function RecordCode:LoadWorldCodeData()
    self.code_edit_line = WorldCommon.GetWorldTag("editCodeLine") or 0
    self.record_data = {}
    local isHaveOldData = false
    local codeStr = WorldCommon.GetWorldTag(self.code_key)
    if codeStr and codeStr ~= "" then
        local temp = {}
        local record_data = NPL.LoadTableFromString(codeStr)
        for k,v in pairs(record_data) do
            local bx,by,bz = unpack(v.pos)
            local newKey = (bx or 0) * 100000000 +  (by or 0) * 1000000 + (bz or 0)
            if (not temp[newKey] and v.writeLineNum and v.writeLineNum > 0) then
                self.record_data[newKey] = v
                temp[newKey] = true
                isHaveOldData = true
            end
        end
    end
    if isHaveOldData then
        return 
    end
    local filename1 = GameLogic.GetWorldDirectory().."stats/"..xmlSavePath
    local filename = GameLogic.GetWorldDirectory()..xmlSavePath
    if not self:LoadCodeDataFormXmlFile(filename1) then
        self:LoadCodeDataFormXmlFile(filename)
    end
end

function RecordCode:MoveXmlInfoFile()
    if self:IsReadOnlyWorld() then
        return 
    end
    local filename1 = GameLogic.GetWorldDirectory().."stats/"..xmlSavePath
    local filename = GameLogic.GetWorldDirectory()..xmlSavePath
    local stats_folder = GameLogic.GetWorldDirectory().."stats/"
    if not ParaIO.DoesFileExist(stats_folder) then
        ParaIO.CreateDirectory(stats_folder)
    end
    
    if not ParaIO.DoesFileExist(filename1) and ParaIO.DoesFileExist(filename) then
        ParaIO.MoveFile(filename,filename1)
    end
end

function RecordCode:LoadCodeDataFormXmlFile(filename)
    local xmlRoot = ParaXML.LuaXML_ParseFile(filename)
    if(xmlRoot) then
        local arr = commonlib.XPath.selectNodes(xmlRoot, "/user_code_map");
        if arr and arr[1] then
            local list = arr[1]
            for k,v in ipairs(list) do
                local obj = v.attr
                self.record_data[obj.id] = {}
                self.record_data[obj.id].pos = NPL.LoadTableFromString(obj.pos)
                self.record_data[obj.id].IsEdit = (obj.IsEdit == "true" or obj.IsEdit == true)
                self.record_data[obj.id].editTime = tonumber(obj.editTime) or 0
                self.record_data[obj.id].writeLineNum = tonumber(obj.writeLineNum) or 0
            end
        end
        return true
    end
end

function RecordCode:SetWorldCodeData()
    if self:IsReadOnlyWorld() then
        return
    end
    local tagCodeData,editCodeLineNum = self:GetTagCodeData()
    -- local codeStr = commonlib.serialize_compact(tagCodeData)
    -- WorldCommon.SetWorldTag(self.code_key,codeStr) --代码存入xml文件中
    WorldCommon.SetWorldTag("editCodeLine",self.code_edit_line)
    WorldCommon.SaveWorldTag()
    if math.abs(editCodeLineNum) > 0 then
        local filename = GameLogic.GetWorldDirectory().."stats/"..xmlSavePath
        local root = {name='user_code_map', attr={file_version="0.1"} }
        for k,v in pairs(tagCodeData) do
            local pos = v.pos
            local bx,by,bz = unpack(pos)
            local newKey = (bx or 0) * 100000000 +  (by or 0) * 1000000 + (bz or 0)
            if (v.writeLineNum and v.writeLineNum > 0) then
                root[#root+1] = {
                    name = "value",
                    attr = {id = newKey,pos = commonlib.serialize_compact(pos),IsEdit = v.IsEdit or false,editTime = v.editTime or 0, writeLineNum = v.writeLineNum or 0}
                }
            end
        end
        local xml_data = commonlib.Lua2XmlString(root, true, true) or "";
        local writer = ParaIO.CreateZip(filename, "");
        if (writer:IsValid()) then
            writer:ZipAddData("data", xml_data);
            writer:close();
        end
    end
end

function RecordCode:GetTagCodeData()
    local editCodeNum = 0
    local temp = {}
    for k,v in pairs(self.record_data) do
        if v.IsEdit and (v.writeLineNum and v.writeLineNum > 0) then
            temp[k] = {}
            temp[k].pos = v.pos
            temp[k].IsEdit = v.IsEdit
            temp[k].editTime = v.editTime or 0
            if v.endEditTime and v.startEditTime then
                temp[k].editTime = v.endEditTime - v.startEditTime
            end
            temp[k].writeLineNum = v.writeLineNum
            editCodeNum = editCodeNum + v.writeLineNum
        end
    end
    return temp,editCodeNum
end

function RecordCode:OnWorldUnloaded()
    local isReadOnlyWorld = self:IsReadOnlyWorld()
    if isReadOnlyWorld then
        self:RefreshSaveData()
        self:SaveCode()
    end
    self:RegisterCodeWindowEvent()
    self.play_macro_data = nil
    self.play_macro_index = nil
    self.play_macro_max_index = nil
end

--只读模式存文件
function RecordCode:RefreshSaveData()
    local isReadOnlyWorld = self:IsReadOnlyWorld()
    local temp = {}
    if isReadOnlyWorld then
        for k,v in pairs(self.record_data) do
            if v.IsEdit and (v.writeLineNum and v.writeLineNum > 0) then
                temp[k] = v
            end
        end
    end
    self.record_data = temp
end

function RecordCode:RefreshPlayData()
    local projectId = GameLogic.options:GetProjectId() --本地世界不能分享
    if projectId and tonumber(projectId) > 0 then 
        self.play_macro_data = {}
        for k,v in pairs(self.record_data) do
            if v.IsEdit and (v.writeLineNum and v.writeLineNum > 0) then
                self.play_macro_data[#self.play_macro_data + 1] = v
            end
        end
        return true
    end
end

function RecordCode:GetCodeChars(codeStr)
    local getCodes = function (code)
        if not code or code == "" then
            return
        end
        local len = ParaMisc.GetUnicodeCharNum(tostring(code));
        local chars = {}; 
        local i;
        for i = 1, len do
            local c = ParaMisc.UniSubString(tostring(code), i, i);
            chars[#chars+1] = c;
        end
        return chars
    end

    local lines = {}
    local lineNum = 0
    for line in string.gmatch(codeStr, "([^\r\n]*)\r?\n?") do
        if line and line ~= "" then
            lines[#lines + 1] = line
            lineNum = lineNum + 1
        end
    end

    local codeChars = {}
    if lineNum > 0 then
        for i=1,lineNum do
            local curLine = lines[i]
            local temp = getCodes(curLine)
            if temp then
                codeChars[#codeChars + 1] = temp
            end
        end
    end
    local str = ""
    if #codeChars > 0 then
        GameLogic.Macros:BeginRecord()
        GameLogic.Macros:AddMacro("WindowTextControlClick", "CodeBlockWindow.code", "left", 195,33,1,0)
        for i=1,#codeChars do
            local lineChars = codeChars[i]
            local charNum = #lineChars
            local startIndex = 0
            local spaceNum = 0
            for m=1,charNum do
                if lineChars[m] == " " then
                    spaceNum = spaceNum + 1
                    startIndex = startIndex + 1
                else
                    break                
                end
            end
            local tabNum = math.floor(spaceNum/4)
            local otherNum = spaceNum - tabNum *4
            if startIndex == 0 then
                startIndex = 1
            else
                startIndex = startIndex + 1
            end
            codeChars[i].startIndex = startIndex
            codeChars[i].tabNum = tabNum
            codeChars[i].otherNum = otherNum
            if i > 1  then
                local tabNum = codeChars[i].tabNum - codeChars[i - 1].tabNum
                local oSpaceNum = codeChars[i].otherNum - codeChars[i - 1].otherNum
                if tabNum ~= 0 then
                    local strKey = tabNum > 0 and "DIK_TAB" or "shift+DIK_TAB"
                    self:AddKeyTrigger(strKey)
                    GameLogic.Macros:AddMacro("WindowKeyPress", "CodeBlockWindow.code", strKey)
                end

                if oSpaceNum ~= 0 then
                    local strKey = oSpaceNum > 0 and "DIK_SPACE" or "DIK_BACKSPACE"
                    self:AddKeyTrigger(strKey)
                    GameLogic.Macros:AddMacro("WindowKeyPress", "CodeBlockWindow.code", strKey)
                end
            end
            for j=startIndex ,charNum do
                if string.len(lineChars[j]) ~= ParaMisc.GetUnicodeCharNum(lineChars[j]) then
                    GameLogic.Macros:AddMacro("WindowInputMethod", "CodeBlockWindow.code", lineChars[j])
                else
                    local keyCode = GameLogic.Macros.TextToKeyName(lineChars[j]);
                    self:AddKeyTrigger(keyCode)
                    GameLogic.Macros:AddMacro("WindowInputMethod", "CodeBlockWindow.code", lineChars[j])
                    GameLogic.Macros:AddMacro("WindowKeyPress", "CodeBlockWindow.code", keyCode)
                end
            end 
            
            self:AddKeyTrigger("DIK_RETURN")
            GameLogic.Macros:AddMacro("WindowKeyPress", "CodeBlockWindow.code", "DIK_RETURN")
        end
    end
    local macros = GameLogic.Macros:EndRecord(true)
    local num = 0
    for str in string.gmatch(macros, "Trigger") do
        num = num + 1
    end
    local single_macro_time = self:GetAutoPlayTime()
    self.total_play_time = self.total_play_time + single_macro_time * num 
    return macros
end

local curTriggerNum = 0

function RecordCode:AddKeyTrigger(strKey)
    if strKey and strKey ~= "" then
        curTriggerNum = curTriggerNum + 1
        if curTriggerNum >= self.macro_speed then
            curTriggerNum = 0
            GameLogic.Macros:AddMacro("WindowKeyPressTrigger", "CodeBlockWindow.code", strKey)
        end
    end
end

function RecordCode:GetNplBlocklyMacro(npl_blockly_xml_code,callfunc)
    if not npl_blockly_xml_code or npl_blockly_xml_code == "" then
        return 
    end
    self:CloseNplPage()
    local Page = NPL.load("script/ide/System/UI/Page.lua");
    local width, height, margin_right, bottom, top, sceneMarginBottom = CodeBlockWindow:CalculateMargins()
    myNplBlocklyEditorPage = Page.Show({
        Language = "npl",
        xmltext = npl_blockly_xml_code,
    }, { 
        url = "script/apps/Aries/Creator/Game/Tasks/BuildReplay/NplBlockly.html",
        alignment="_rt",
        x = -2560, y = 45 + top,
		height = height - 45 - 54,
        width = width,
        isAutoScale = false,
        windowName = "UICodeBlockWindow",
        minRootScreenWidth = 0,
		minRootScreenHeight = 0,
        zorder = 100,
    });

    local G = myNplBlocklyEditorPage:GetG();
    if G and type(G.GetMacroCode) == "function" then
        local code = G.GetMacroCode()
        code= code .. "Broadcast(\"macroFinished\")"
        local single_macro_time = self:GetAutoPlayTime(true)
        local num= 0
        for str in string.gmatch(code, "Trigger") do
            num = num + 1
        end
        self.total_play_time = self.total_play_time + single_macro_time * num 
        return code
    end
end

function RecordCode:GetAutoPlayTime(isBlockly)
    local speed = isBlockly == true and block_speed or code_speed
    local defaultInterval = 200;
    defaultInterval = math.max(math.floor(defaultInterval /speed  + 0.5), 10)
    return defaultInterval
end

function RecordCode:CloseNplPage()
    if myNplBlocklyEditorPage then
        myNplBlocklyEditorPage:CloseWindow();
        myNplBlocklyEditorPage = nil;
    end
end

function RecordCode:GetCodePos()
    return 19197,253,19244
end

function RecordCode:PlayMacro(str,isBlockly)
    if not str or str == "" or self.isStopPlay then
        return 
    end
    local bx, by, bz = self:GetCodePos()
    BlockEngine:SetBlockToAir(bx, by, bz)
    local isSuc = BlockEngine:SetBlock(bx, by, bz,219)
    if isSuc then
        self:CloseNplPage()
        local codeEntity = EntityManager.GetBlockEntity(bx, by, bz)
        if codeEntity then
            local speed = code_speed
            if isBlockly then
                speed = block_speed
                codeEntity:SetUseNplBlockly(true)
            end
            codeEntity:OpenEditor("entity", codeEntity)
            if isBlockly then 
                CodeBlockWindow:ChangeCodeMode("blockMode")
            end
            CodeBlockWindow.SetFontSize(18)
            GameLogic.Macros.SetPlayOrigin(19200,5,19200)
            GameLogic.Macros.SetShowTrigger(false)
            GameLogic.Macros.SetAutoPlay(true);
            GameLogic.Macros.SetHelpLevel(0);
            GameLogic.Macros.SetPlaySpeed(speed);
            GameLogic.Macros:Play(str);
            NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/MacroPlayer.lua");
            local MacroPlayer = commonlib.gettable("MyCompany.Aries.Game.Tasks.MacroPlayer");
            MacroPlayer.ShowController(false);
        end
    end
end

function RecordCode:IsOpenSourceCode(entity) --是否使用的是原先的网页版本的图块
    -- return entity and entity:IsUseNplBlockly()
    if not entity then
        return false
    end
    return not entity:IsUseNplBlockly()
end

function RecordCode:StartEditCode(entity)
    if self:IsOpenSourceCode(entity) then
        return 
    end
    local entityId = entity.entityId
    local bx,by,bz = entity:GetBlockPos()
    local macroX,macroY,macroZ = self:GetCodePos()
    if macroX == bx and macroY == by and macroZ == bz then
        return 
    end
    
    local posKey =  (bx or 0) * 100000000 +  (by or 0) * 1000000 + (bz or 0);
    local record_key = posKey

    if not self.record_data[record_key] then
        self.record_data[record_key] = {}
    end
    -- self.record_data[record_key].entity = entity
    local codeStr = self:GetCodeStringByEntity(entity)
    self.record_data[record_key].codeStr = codeStr
    local lineNum = self:GetCodeLineNum(codeStr)
    -- print("start lineNum===========",lineNum,codeStr)
    -- self.record_data[record_key].blockly_xml_code = entity:GetBlocklyXMLCode()
    self.record_data[record_key].npl_blockly_xml_code = entity:GetNPLBlocklyXMLCode()
    self.record_data[record_key].startEditTime = os.time()
    self.record_data[record_key].pos = {bx,by,bz}
    self.record_data[record_key].startLineNum = lineNum
    -- echo(self.record_data,true)
end

function RecordCode:EndEditCode(entity)
    if self:IsOpenSourceCode(entity) then
        return 
    end
    local entityId = entity.entityId
    local bx,by,bz = entity:GetBlockPos()
    local macroX,macroY,macroZ = self:GetCodePos()
    if macroX == bx and macroY == by and macroZ == bz then
        return 
    end
    local posKey =  (bx or 0) * 100000000 +  (by or 0) * 1000000 + (bz or 0);
    local record_key = posKey
    if self.record_data[record_key] then
        local newCodeStr = self:GetCodeStringByEntity(entity)
        if newCodeStr ~= self.record_data[record_key].codeStr then
            self.record_data[record_key].IsEdit = true
        end
        local lineNum = self:GetCodeLineNum(newCodeStr)
        -- print("end lineNum===========",lineNum,posKey)
        self.record_data[record_key].codeStr = newCodeStr
        self.record_data[record_key].blockly_xml_code = entity:GetBlocklyXMLCode()
        self.record_data[record_key].npl_blockly_xml_code = entity:GetNPLBlocklyXMLCode()
        self.record_data[record_key].endEditTime = os.time()
        self.record_data[record_key].endLineNum = lineNum
        local writeLineNum = lineNum - self.record_data[record_key].startLineNum
        self.record_data[record_key].writeLineNum = writeLineNum
        self.code_edit_line = self.code_edit_line + math.abs(writeLineNum)
    end
    entity:SetLastEditTime(os.time())
end

function RecordCode:OnSetCodeEntity(entity) --打开代码方块
    if not entity then
        return
    end
    if self.current_entity == nil then
        self:StartEditCode(entity)
        self.current_entity = entity
        return 
    end


    local preEntity = self.current_entity
    if self.current_entity ~= entity then
        self.current_entity = entity
        self:EndEditCode(preEntity)
        self:StartEditCode(self.current_entity)
    end
end

function RecordCode:ShowCodeBlockWindow(event)
    local entity = CodeBlockWindow.GetCodeEntity()
    -- echo(event,true)
    -- print("RecordCode:CodeBlockWindowShow================")
    if event  then
        -- print("entity data==========",entity,self.current_entity)
        local bShow = event.bShow
        if not bShow and entity then
            if self.current_entity == entity then
                self.current_entity = nil
            end
            self:EndEditCode(entity)
        end
    end
end

function RecordCode:GetCodeLineNum(codeStr)
    if not codeStr or codeStr == "" then
        return 0
    end
    local num = 0
    for line in string.gmatch(codeStr, "([^\r\n]*)\r?\n?") do
        if line and line ~= "" then
            num = num  + 1
        end
    end
    return num
end

function RecordCode:GetCodeStringByEntity(entity)
    if not entity then
        return ""
    end
    if self:IsSupportNplBlockly(entity) then
        return entity:GetNPLBlocklyNPLCode()
    end
    return entity:GetCommand()
end

function RecordCode:IsSupportNplBlockly(entity)
    local configFile = entity:GetLanguageConfigFile()
    local language = entity and entity:GetCodeLanguageType();
	return language ~= "python" and (configFile and configFile ~= "microbit") and entity and type(entity.IsBlocklyEditMode) and type(entity.IsUseNplBlockly) == "function" and entity:IsBlocklyEditMode() and entity:IsUseNplBlockly();
end

function RecordCode:CheckHaveData()
    if not self.record_data then
        return 
    end
    local isHave = false
    -- echo(self.record_data)
    -- print("check================")
    for k,v in pairs(self.record_data) do
        if v.IsEdit then
            local npl_blockly_xml_code = v.npl_blockly_xml_code
            local codeStr = v.codeStr
            if (npl_blockly_xml_code and npl_blockly_xml_code ~= "") then
                isHave = true
                break
            end
            if (codeStr and codeStr ~= "") then
                isHave = true
                break
            end
        end
    end
    return isHave
end

function RecordCode:SaveCode()
    if (not self:CheckHaveData()) then
        return
    end
    -- print("dddddddddddddddddddddddd")
    -- echo(self.record_data)
    local temp = {}
    for k,v in pairs(self.record_data) do
        local npl_blockly_xml_code = v.npl_blockly_xml_code
        local codeStr = v.codeStr
        if v.IsEdit then
            if (npl_blockly_xml_code and npl_blockly_xml_code ~= "") then
                temp[k] = v
            end
            if (codeStr and codeStr ~= "") then
                temp[k] = v
            end
        end
    end
    self:SaveCode1(temp)
end

function RecordCode:LoadCodeFromTempFile()
    local codeInfo = {}
    local path = self:GetCodeFilePath()
    if not ParaIO.DoesFileExist(path) then
       return codeInfo
    end
    local strContent = self:OpenFile(path)
    if strContent then
        local data = commonlib.LoadTableFromString(strContent)
        if not data then
            ParaIO.DeleteFile(path)
            return codeInfo
        end
        codeInfo = data
    end
    return codeInfo
end

--private function
function RecordCode:SaveCode1(saveData)
    local path = self:GetCodeFilePath()
    local file_size = ParaIO.GetFileSize(path) or 0;
    file_size = math.floor(file_size/1024 + 0.5)
    if not saveData or file_size >= 500 then
        return 
    end
    local curData = self:LoadCodeFromTempFile() or {}
    for k,v in pairs(saveData) do
        if curData[k] ~= nil and ((curData[k].codeStr ~=v.codeStr and v.codeStr ~= "") or (curData[k].npl_blockly_xml_code ~=v.npl_blockly_xml_code and v.npl_blockly_xml_code ~= "") )  then
            local key = ParaGlobal.GenerateUniqueID()
            curData[key] = v
        else
            curData[k] = v
        end
    end
    local saveStr = commonlib.serialize_compact(curData)
    if saveStr ~= "" then
        local path = self:GetCodeFilePath()
        if not ParaIO.DoesFileExist(path) then
            ParaIO.CreateDirectory(path)
        end
        local file = ParaIO.open(path, "w")
        if(file:IsValid()) then
            file:WriteString(saveStr);
            file:close();
        end
    end
end

function RecordCode:GetCodeFilePath()
    return self:GetTempPath().."replay/codeblock.txt"
end

function RecordCode:OpenFile(fileName)
    local file = ParaIO.open(fileName, "r");
    local strContent
    if(file and file:IsValid()) then
        strContent = file:GetText(0,-1)
        file:close();
    end
    return strContent
end

function RecordCode:LoadCodeInfoFromFile()
    local stats_folder = GameLogic.GetWorldDirectory().."stats/codeblock.txt"
    local path = GameLogic.GetWorldDirectory().."codeblock.txt"
    local strContent = self:OpenFile(stats_folder)
    if not strContent then
        strContent = self:OpenFile(path)
    end
    if strContent and strContent ~= "" then
        return commonlib.LoadTableFromString(strContent)
    end
end

function RecordCode:MoveCodeInfoFile()
    if self:IsReadOnlyWorld() then
        return 
    end
    local stats_folder = GameLogic.GetWorldDirectory().."stats/"
    local stats_folder_file = GameLogic.GetWorldDirectory().."stats/codeblock.txt"
    local path = GameLogic.GetWorldDirectory().."codeblock.txt"

    if not ParaIO.DoesFileExist(stats_folder) then
        ParaIO.CreateDirectory(stats_folder)
    end
    
    if not ParaIO.DoesFileExist(stats_folder_file) and ParaIO.DoesFileExist(path) then
        ParaIO.MoveFile(path,stats_folder_file)
    end
end

function RecordCode:LoadCodeFromCodeBlock(x,y,z)
    local codeEntity = EntityManager.GetBlockEntity(x,y,z)
    if codeEntity then
        local npl_blockly_xmlcode = codeEntity.npl_blockly_xmlcode
        if npl_blockly_xmlcode and npl_blockly_xmlcode ~= "" then
            return npl_blockly_xmlcode,true
        end
        return codeEntity:GetCommand(),false
    end
end

function RecordCode:GenerateCode()
    local codeInfo = self:LoadCodeInfoFromFile() --保存在文本中的代码
    local codeData = {}
    if self:RefreshPlayData() then
        codeData = self.play_macro_data
    end
    -- echo(codeInfo)
    -- print("zzzzzzzzzzzzzzzzzzzz")
    if codeInfo and type(codeInfo) == "table" then
        for k,v in pairs(codeInfo) do
            if not self.record_data[k] then --如果当前存在同一个key的数据，用当前最新的
                codeData[#codeData + 1] = v
            end
        end
    end

    if codeData and #codeData > 0 then
        self.play_macro_data = codeData
        self.play_macro_max_index = #codeData
    end
    return #codeData
end

function RecordCode:GetCodeData()
    return self.play_macro_data
end

function RecordCode:StartPlay(playtime,finish_callback)
    self.finish_call_back = finish_callback
    if not self.play_macro_data or #self.play_macro_data <= 0 then
        -- GameLogic.AddBBS(nil,"没有代码数据")
        if finish_callback then
            finish_callback()
        end
        return 
    end
    self:StopPlay()
    self.isStopPlay = false
    self.play_macro_index = 1
    self:PlayCodeMacro(finish_callback)
    if playtime and playtime > 0 then
        local time = playtime * 1000
        self.play_macro_timer = self.play_macro_timer or commonlib.Timer:new({callbackFunc = function(timer)
            if finish_callback then
                finish_callback()
            end
            self:StopPlay()
        end})
        self.play_macro_timer:Change(time);
    end
end

function RecordCode:StopPlay()
    if GameLogic.Macros:IsPlaying() then
        GameLogic.Macros:Stop()
    end
    self.isStopPlay = true
    CodeBlockWindow.Close()
    local bx, by, bz = self:GetCodePos()
    BlockEngine:SetBlockToAir(bx, by, bz)
    if self.play_macro_timer then
        self.play_macro_timer:Change()
        self.play_macro_timer = nil
    end
end

function RecordCode:PlayCodeMacro(finish_callback)
    if not self.play_macro_max_index then
        return 
    end
    if self.play_macro_index > self.play_macro_max_index then
        -- GameLogic.AddBBS(nil,"代码方块播放结束了")
        if finish_callback then
            finish_callback()
        end
        self:StopPlay()
        return 
    end
    local curMacroDt = self.play_macro_data[self.play_macro_index]
    self.play_macro_index = self.play_macro_index + 1
    if curMacroDt then
        local npl_blockly_xml_code = curMacroDt.npl_blockly_xml_code
        local codeStr = curMacroDt.codeStr
        local x,y,z = unpack(curMacroDt.pos)
        local code,isblockly = self:LoadCodeFromCodeBlock(x,y,z)
        if (not npl_blockly_xml_code or npl_blockly_xml_code == "") and isblockly then
            npl_blockly_xml_code = code
        end
        if (not codeStr or codeStr == "") and not isblockly then
            codeStr = code
        end
        if curMacroDt.macros and curMacroDt.macros ~= "" then
            commonlib.TimerManager.SetTimeout(function() 
                local isblockly = (npl_blockly_xml_code and npl_blockly_xml_code ~="") and 1 or 0
                self:PlayMacro(curMacroDt.macros,isblockly == 1)
            end, 200)
            return
        end

        if npl_blockly_xml_code and npl_blockly_xml_code ~="" then
            local data = self:GetNplBlocklyMacro(npl_blockly_xml_code)
            commonlib.TimerManager.SetTimeout(function() 
                self:PlayMacro(data,true)
            end, 200)
            return
        end
        if codeStr and codeStr ~= ""  then
            local macros = self:GetCodeChars(codeStr)
            commonlib.TimerManager.SetTimeout(function()
                self:PlayMacro(macros)
            end, 200)
            return
        end

        --移动了代码方块，就直接播放下一个数据
        self:PlayCodeMacro(finish_callback)
    end
end

function RecordCode:GetTotalPlayTime()
    self.total_play_time = 0
    for k,v in pairs(self.play_macro_data) do
        local npl_blockly_xml_code = v.npl_blockly_xml_code
        local codeStr = v.codeStr
        local x,y,z = unpack(v.pos)
        local code,isblockly = self:LoadCodeFromCodeBlock(x,y,z)
        if isblockly then
            if (not npl_blockly_xml_code or npl_blockly_xml_code == "") then
                npl_blockly_xml_code = code
            end
            if npl_blockly_xml_code and npl_blockly_xml_code ~="" then
                local data = self:GetNplBlocklyMacro(npl_blockly_xml_code)
                v.macros = data
            end
        else
            if (not codeStr or codeStr == "") then
                codeStr = code
            end
            if codeStr and codeStr ~= ""  then
                local macros = self:GetCodeChars(codeStr)
                v.macros = macros
            end
        end
    end
    return self.total_play_time
end

function RecordCode:MergeROWCD() --合并只读世界数据
    if self:IsReadOnlyWorld() then
        return 
    end
    local path = self:GetCodeFilePath() 
    local stats_folder = GameLogic.GetWorldDirectory().."stats/"
    local dest_path = stats_folder.."codeblock.txt"
    if ParaIO.DoesFileExist(path) then
        if not ParaIO.DoesFileExist(dest_path) then
            ParaIO.CreateDirectory(dest_path)
        end
        local file = ParaIO.open(path, "r");
        local strContent
        if(file:IsValid()) then
            strContent = file:GetText(0,-1)
            file:close();
        end
        if strContent and strContent ~= "" then
            local newCodeInfo = commonlib.LoadTableFromString(strContent)
            if newCodeInfo then
                local curCodeInfo = self:LoadCodeInfoFromFile() or {}
                for k,v in pairs(newCodeInfo) do
                    if not curCodeInfo[k] then
                        curCodeInfo[k] = v
                    elseif (curCodeInfo[k].codeStr ~=v.codeStr and v.codeStr ~= "") or (curCodeInfo[k].npl_blockly_xml_code ~=v.npl_blockly_xml_code and v.npl_blockly_xml_code ~= "") then
                        local key = ParaGlobal.GenerateUniqueID()
                        curCodeInfo[key] = v
                    end
                end
                local writeStr = commonlib.serialize_compact(curCodeInfo)
                file = ParaIO.open(dest_path, "w+");
                if file and file:IsValid() then
                    file:WriteString(writeStr);
                    file:close()
                    ParaIO.DeleteFile(path)
                end
            else
                ParaIO.DeleteFile(path)
            end
        end
    end
end

RecordCode:InitSingleton()






