--[[
Title: keepwork.ai
Author(s): big
Date: 2023.7.7
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/keepwork.ai.lua");
]]

local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");


--http://yapi.kp-para.cn/project/32/interface/api/7015
HttpWrapper.Create("keepwork.ai.chat", "%MAIN%/core/v0/gpt/chat", "POST", "auto")

-- http://yapi.kp-para.cn/project/151/interface/api/7179
HttpWrapper.Create("keepwork.ai.audio2Text", "%MAIN%/ts-storage/audio2Text", "POSTFIELDS", "auto")

-- http://yapi.kp-para.cn/project/151/interface/api/7181
HttpWrapper.Create("keepwork.ai.audioEncode2Text", "%MAIN%/ts-storage/audioEncode2Text", "POST", "auto")

-- AI Chat History APIs (aligned with JS AIChat ChatSession)
HttpWrapper.Create("keepwork.ai.aiChatHistoryUpsert", "%MAIN%/core/v0/gpt/aiChatHistory/upsert", "POST", "auto")
HttpWrapper.Create("keepwork.ai.aiChatHistoryUpdate", "%MAIN%/core/v0/gpt/aiChatHistory/:id", "PUT", "auto")
HttpWrapper.Create("keepwork.ai.aiChatHistoryGet", "%MAIN%/core/v0/gpt/aiChatHistory", "GET", "auto")