--[[

    date:2023.6.6
    use:
        local GenerateVideoQueue = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BuildReplay/GenerateVideoQueue.lua");
        GenerateVideoQueue:Init()
        GenerateVideoQueue:StartPlay(video_queue)
]]

local GenerateVideoQueue = NPL.export()
local self = GenerateVideoQueue
function GenerateVideoQueue:Init()
    if self.InitValue then
        return
    end
    GameLogic.GetFilters():remove_filter("apps.aries.creator.game.login.swf_loading_bar.close_page",  GenerateVideoQueue.OnSwfLoadingCloesed);
    GameLogic.GetFilters():add_filter("apps.aries.creator.game.login.swf_loading_bar.close_page",  GenerateVideoQueue.OnSwfLoadingCloesed);
    self.video_projectIds = {}
    self.generate_index = 1
    self.is_world_loaded = false
    self.is_swfpage_cloesed = false
    self.InitValue = true
end

function GenerateVideoQueue:StartPlay(video_queue)
    if not self.InitValue then
        self:Init()
    end
    if video_queue and video_queue ~= "" then
        self.generate_index = 1
        self.video_projectIds = commonlib.split(video_queue,",")
    end
    echo(self.video_projectIds,true)
    print("self.generate_index========",self.generate_index)
    if type(self.video_projectIds) == "table" and #self.video_projectIds > 0 then
        self.is_in_generating = true
        self.is_world_loaded = false
        self.is_swfpage_cloesed = false
        if self.generate_index <= #self.video_projectIds then
            local projectId =  self.video_projectIds[self.generate_index]
            if projectId and tonumber(projectId) > 0 then
                GameLogic.RunCommand(string.format("/loadworld -s -auto %d",tonumber(projectId)))
            end
            self.generate_index = self.generate_index + 1
        else
            GameLogic.AddBBS(nil,"录制视频结束~~~~")
            self.is_in_generating = false
            self.video_projectIds = {}
            self.generate_index = 1
            self.is_world_loaded = false
            self.is_swfpage_cloesed = false
            self.InitValue = true
        end
    end
end

function GenerateVideoQueue:OnWorldLoaded()
    self.is_world_loaded = true
    if (self.is_world_loaded and self.is_swfpage_cloesed) then
        self:StartRecord()
    end
end

function GenerateVideoQueue:OnWorldUnloaded()
    if self.ReplayManager then
        self.ReplayManager:debug_off_script()
    end
end

function GenerateVideoQueue.OnSwfLoadingCloesed()
    self.is_swfpage_cloesed = true
    if (self.is_world_loaded and self.is_swfpage_cloesed) then
        self:StartRecord()
    end
end

function GenerateVideoQueue:StartRecord()
    if not self.is_in_generating then
        return
    end
    GameLogic.AddBBS(nil,"开始练习----------")
    if not self.ReplayManager then
        NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BuildReplay/ReplayManager.lua");
        self.ReplayManager = commonlib.gettable("MyCompany.Aries.Game.Tasks.BuildReplay.ReplayManager");
    end
    self.ReplayManager.StopAllCodeBlocks()
    self.ReplayManager:debug_on_script()

    self.ReplayManager:Play({
		speed = 1
	},function(result)
        self:StartPlay()
    end,(self.generate_index - 1),true)
end