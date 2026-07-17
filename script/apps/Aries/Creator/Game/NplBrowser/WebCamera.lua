--[[
Title: Web camera
Author(s): LiXizhi
Date: 2024.2.4
Desc: This is a singleton class that provides web camera functionality based on webview and NPLJS.
texture filename is "_textureDynamicDefault", use it as an ordinary texture file to render dynamic video texture.
------------------------------------------------------------
local WebCamera = NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/WebCamera.lua");
WebCamera:Open(128, 128)
WebCamera:OpenVideo("https://api.keepwork.com/ts-storage/siteFiles/30113/raw#WhatIsParacraft.mp4", 512, 360)
WebCamera:Close()
echo(WebCamera:GetTextureFilename()); -- "_textureDynamicDefault"
WebCamera:FlipLeftRight(true);
WebCamera:FlipVertically(false);

WebCamera:FetchCameraData()
echo(WebCamera:GetImageData())
WebCamera:SaveToFile("temp/camera.jpg")

WebCamera:SetReceiveCameraDataInterval(1000);  // 1000ms 取数据频率  存在多个相机时, 每个相机频率为此值的N(相机数量)倍
local camera_id_1 = WebCamera:OpenCamera(128, 128);
local camera_id_2 = WebCamera:OpenCamera(128, 128);
WebCamera:SetReceiveCameraDataCallback(function(msg)
    -- todo
end, camera_id_1)
WebCamera:SetReceiveCameraDataCallback(function(msg)
    -- todo
end, camera_id_2)
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Scene/Assets/ImageFile.lua");
local ImageFile = commonlib.gettable("System.Scene.Assets.ImageFile");
local WebCamera = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

-- WebCamera.textureFilename = "_textureDynamicDefault";
WebCamera.defaultCameraId = "0"
function WebCamera:ctor()
    self:Reset();
end

function WebCamera:Destroy()
    self:Reset();
end

function WebCamera:SetAutoCloseWebView(auto_close)
    self.m_auto_close_webview = auto_close;
end

function WebCamera:SetReceiveCameraDataInterval(interval, camera_id)
    self:GetCamera(camera_id).m_interval = interval;
end

-- create get video texture
function WebCamera:GetVideoTexture(camera_id)
    local camera = self:GetCamera(camera_id);
    if (camera.m_video_texture) then return camera.m_video_texture end
    NPL.load("(gl)script/ide/System/Scene/Assets/DynamicTexture.lua");
    local DynamicTexture = commonlib.gettable("System.Scene.Assets.DynamicTexture");
    camera.m_video_texture = DynamicTexture:new():Init("_texture_" .. camera.m_camera_id);
    camera.m_video_texture:SetKey(camera.m_camera_id);
    camera.m_video_texture:EnableActiveRendering(false);
    System.Core.Scene:MakeAutoDestory(self);
    return camera.m_video_texture;
end

function WebCamera:Reset()
    for _, camera in pairs(self.m_cameras or {}) do
        if (camera.m_video_texture) then
            camera.m_video_texture:EnableActiveRendering(false);
            camera.m_video_texture = nil;
        end
    end
    self.isOpen = false;
    self.isWebviewShown = false;
    self.m_auto_close_webview = true;
    self.m_cameras = {};
    self.m_cameras_size = 0;
end

function WebCamera:GetCamera(camera_id)
    camera_id = camera_id or WebCamera.defaultCameraId;
    if (not self.m_cameras[camera_id]) then
        self.m_cameras[camera_id] = { 
            m_camera_id = camera_id,
            m_interval = 50,
            m_has_camera_event = true;
            m_flip_horizontal = false,
            m_flip_vertical = false,
            m_image_format = "png",
            m_pause_receive_data = false,
        };
        self.m_cameras_size = self.m_cameras_size + 1;
    end
    return self.m_cameras[camera_id];
end

function WebCamera:Close()
    GameLogic.RunCommand("/capture none")
    self:Reset();
end

function WebCamera:IsOpen()
    return self.isOpen;
end

-- @param width, height: default to 512, 360
function WebCamera:OpenVideo(mp4_url, width, height)
    return self:Open(width or 512, height or 360, mp4_url)
end

-- @param width, height: default to 128,128
function WebCamera:OpenCamera(width, height, bFlipLeftRight, x, y, camera_id, device_id, camera_url)
    return self:Open(width, height, nil, bFlipLeftRight, x, y, camera_id, device_id, camera_url);
end

function WebCamera:SetDebug(bDebug)
    self.isDebug = bDebug;
end

function WebCamera:OpenByOptions(options)
    return self:Open(options.width, options.height, options.mp4_url, options.bFlipLeftRight, options.x, options.y, options.camera_id, options.device_id, options.camera_url, options)
end

-- @param width, height: default to 128,128
-- @param mp4_url: if nil, it will open camera, it can also be any url based video file. 
function WebCamera:Open(width, height, mp4_url, bFlipLeftRight, x, y, camera_id, device_id, camera_url, options) 
    options = options or {};

    -- 如果为视屏直接先关闭
    if (mp4_url) then self:Close() end

    width = width or 128
    height = height or 128
    device_id = tostring(device_id or 0);
    camera_id = camera_id or WebCamera.defaultCameraId;
    if (self.m_cameras[camera_id]) then return camera_id end

    local camera = self:GetCamera(camera_id);
    camera.m_flip_horizontal = bFlipLeftRight;
    camera.m_device_id = device_id;

    local video_texture = self:GetVideoTexture(camera_id);
    video_texture:Disconnect();
    video_texture:Connect("OnRender", self, self.OnRender, "UniqueConnection");

    local NPLJS = NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NPLJS.lua");
    NPLJS:Connect("OnReceiveCameraData", self, self.OnReceiveCameraData, "UniqueConnection");
    NPLJS:Connect("OnStartWebPage", self, self.StartRendering, "UniqueConnection");
    NPLJS:Connect("OnStartCamera", self, self.StartRendering, "UniqueConnection");
    
    if (not self.isOpen) then
        GameLogic.RunCommand("/capture none")
        self.isWebviewShown = true;
        self.isOpen = true;
    end

    if(type(mp4_url) == "string") then
        GameLogic.RunCommand(format("/capture webpage -scale 1 -width %d -height %d -url %s -camera_id %s %s", width, height, mp4_url, camera_id, self.isDebug and "-debug" or ""))
    else
        local cmd_str = format("/capture video -scale 1 -x %d -y %d -width %d -height %d -camera_id %s -device_id %s", x or 0, y or 0, width, height, camera_id, device_id);
        if (camera_url) then cmd_str = cmd_str .. " -camera_url " .. camera_url end
        if (type(options) == "table" and options.url) then cmd_str = cmd_str .. " -url " .. options.url end
        if (self.isDebug or options.debug) then cmd_str = cmd_str .. " -debug" end
        if (options.isolated) then cmd_str = cmd_str .. " -isolated" end
        GameLogic.RunCommand(cmd_str);
    end

    return camera_id;
end

function WebCamera:OnRender(camera_id, device_id)
    if (not self.isOpen) then return end
    local camera = self:GetCamera(camera_id);
    camera.m_device_id = device_id or camera.m_device_id;
    self:FetchCameraData(camera.m_camera_id, camera.m_interval);
end

function WebCamera:SetReceiveCameraDataCallback(callback, camera_id)
    self:GetCamera(camera_id).m_callback = callback;
end

function WebCamera:SetReceiveCameraDataInterval(interval, camera_id)
    self:GetCamera(camera_id).m_interval = interval;
end

function WebCamera:OnReceiveCameraData(msg)
    if (type(msg) ~= "table") then return end

    local camera_id = msg.camera_id;
    local camera = self:GetCamera(camera_id);
    camera.m_has_camera_event = true;
    camera.m_camera_data = msg;
	if(msg.width and msg.data and msg.width ~= 0 and msg.height ~= 0) then
        local data = msg.data;
        local width = msg.width;
        local height = msg.height;
        
        if(self.isOpen) then
            if(type(data) == "string" and camera.m_need_update_texture) then
                camera.m_need_update_texture = false;
 
                local fromX, toX = 0, width -1;
                local fromY, toY = 0, height - 1;

                if(camera.m_flip_horizontal) then
                    fromX, toX = toX, fromX
                end

                if(camera.m_flip_vertical) then
                    fromY, toY = toY, fromY
                end

                self:GetVideoTexture(camera_id):LoadImageFromString(data, fromX, fromY, toX, toY)
                
                if(self.isWebviewShown and self.m_auto_close_webview) then
                    -- when we can receive data, we can now hide the webview. 
                    -- otherwise the user may be requesting permission to use camera. 
                    self.isWebviewShown = false;
                    GameLogic.RunCommand("/capture hide")
                end
            end
        end

        if (camera.m_callback) then camera.m_callback(msg) end
    end
end

function WebCamera:HideWebview()
    GameLogic.RunCommand("/capture hide")
end

function WebCamera:StopRendering(camera_id)
    self:GetCamera(camera_id).m_rendering = false;
    self:GetVideoTexture(camera_id):EnableActiveRendering(false);
end

function WebCamera:StartRendering(camera_id)
    local camera = self:GetCamera(camera_id);
    if (camera.m_rendering) then return end
    camera.m_rendering = true;
    camera.m_last_fetch_time = commonlib.TimerManager.GetCurrentTime();
    self:GetVideoTexture(camera_id):EnableActiveRendering(true);
end

-- return width, height
function WebCamera:GetSize(camera_id)
    local video_texture = self:GetVideoTexture(camera_id);
    return video_texture.width, video_texture.height
end

-- fetch camera data. it may take a while to receive the data.
-- when data is received, one can call GetImageData to retrive the camera data.
-- @param camera_id: the camera id. default to 0
-- @param minIntervalMS: minimum interval in milliseconds between two fetches. default to 100 if camera_id is not specified
-- @return sinceFetchTimeMS: the time since last fetch in milliseconds.
function WebCamera:FetchCameraData(camera_id, minIntervalMS)
    local camera = self:GetCamera(camera_id);
    minIntervalMS = minIntervalMS or camera.m_interval or 100; 
    local current_time = commonlib.TimerManager.GetCurrentTime();
    local sinceFetchTimeMS = current_time - (camera.m_last_fetch_time or 0)
    if(not camera.m_pause_receive_data and camera.m_has_camera_event and sinceFetchTimeMS > minIntervalMS) then
	    camera.m_last_fetch_time = current_time;
        camera.m_has_camera_event = false;
        camera.m_need_update_texture = true;
        GameLogic.RunCommand(string.format("/capture videoimage -format %s -camera_id %s", camera.m_image_format, camera.m_camera_id));
	end
    return sinceFetchTimeMS;
end

-- get current camera texture data in the given format. 
-- it will automatically call FetchCameraData(). if the image is not ready this function may return false on the second parameter
-- this is slow, do it sparingly if video size is big. 
-- @param width, height: sample at the given width and height. if nil, they will be same as the texture size.
-- @param colorMode: "rgb" or "DWORD" or "grey", default to "rgb". if "grey", value normalized to [0,1]
-- @return img, sinceFetchTimeMS:  img is nil or img table of {width, height, data = {r,g,b,r,g,b,...}}, sinceFetchTimeMS is the time since last fetch in milliseconds.
function WebCamera:GetImageData(width, height, colorMode, camera_id)
    local sinceFetchTimeMS = self:FetchCameraData(camera_id);
    local img = self:GetVideoTexture(camera_id):GetImageData(width, height, colorMode);
    return img, sinceFetchTimeMS;
end

function WebCamera:GetImageRGBData(callback, camera_id)
    local video_texture = self:GetVideoTexture(camera_id);
    if (video_texture) then
        local file = ImageFile.open(video_texture:GetTextureFilename())
        if(file:IsValid()) then
            return file:GetImageRGBData(callback);
        end
    end
    callback();
end

function WebCamera:FlipLeftRight(isFlipLeftRight, camera_id)
    self:GetCamera(camera_id).m_flip_horizontal = isFlipLeftRight;
end
    
function WebCamera:FlipVertically(isFlipVertical, camera_id)
    self:GetCamera(camera_id).m_flip_vertical = isFlipVertical;
end

function WebCamera:GetTextureFilename(camera_id)
	return self:GetVideoTexture(camera_id):GetTextureFilename();
end

-- save to disk file, jpg and png supported. 
function WebCamera:SaveToFile(filename, camera_id)
    self:GetVideoTexture(camera_id):SaveToFile(filename)
end

function WebCamera:GetCameraData(camera_id)
    return self:GetCamera(camera_id).m_camera_data;
end

function WebCamera:SmartCar(options, camera_id)
    local NPLJS = NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NPLJS.lua");

    options = options or {};
    options.camera_id = camera_id or self.camera_id;
    NPLJS:SmartCar(options);
end

WebCamera:InitSingleton();

