--[[
Title: Paralife Buildin API for Live models
Author(s): LiXizhi
Date: 2022/3/30
Desc: please note, functions maybe called when the last one has not finished, please safe-guard this by code. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/API/ParaLifeAPI_clickable.lua");
------------------------------------------------------------
]]
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local API = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.API");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/MovieManager.lua");
local MovieManager = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieManager");
NPL.load("(gl)script/ide/System/Util/ImageProc/Image.lua");
local Image = commonlib.gettable("System.Util.ImageProc.Image")
local env_imp = commonlib.gettable("MyCompany.Aries.Game.Code.env_imp");

-- let camera look at (teleport to) the given player 
function API.LookAt(msg)
	local entity = GameLogic.EntityManager.GetEntity(msg.name)
    if(entity) then
		local x, y, z = entity:GetPosition()
		local player = GameLogic.EntityManager.GetPlayer()
		if(player) then
			player:SetPosition(x, y, z)
		end
	end
end

-- open toggle model: "xxxopen.bmax", "xxx.bmax"
function API.ToggleOpen(msg)
	local entity = GameLogic.EntityManager.GetEntity(msg.name)
    if(entity) then
        local filename = entity:GetModelFile()
        if(filename:match("open")) then
            filename = filename:gsub("open", "")
            entity:SetModelFile(filename)
        else
            filename = filename:gsub("(%.%w+)$", "open%1")
            entity:SetModelFile(filename)
        end
    end
end
-- open model: "xxxopen.bmax"
function API.Open(msg)
    local entity = GameLogic.EntityManager.GetEntity(msg.name)
    if(entity) then
        local filename = entity:GetModelFile()
        if(not filename:match("open")) then
            filename = filename:gsub("(%.%w+)$", "open%1")
            entity:SetModelFile(filename)
        end
    end
end

-- close model: "xxx.bmax"
function API.Close(msg)
    local entity = GameLogic.EntityManager.GetEntity(msg.name)
    if(entity) then
        local filename = entity:GetModelFile()
        if(filename:match("open")) then
            filename = filename:gsub("open", "")
            entity:SetModelFile(filename)
        end
    end
end

-- toggle animation between 0 and GetTagField("anim")
function API.ToggleAnim(msg)
	local entity = GameLogic.EntityManager.GetEntity(msg.name)
    if(entity) then
        if(entity:GetCurrentAnimId() == 0) then
			local anim = tonumber(entity:GetTagField("anim") or 70)
            entity:SetAnimation(anim)
        else
            entity:SetAnimation(0)
        end
    end   
end

-- push/pull model out by GetTagField("length") or 1 meter
function API.PushPull(msg)
	local entity = GameLogic.EntityManager.GetEntity(msg.name)
    if(entity and not entity.isMoving_) then
		entity.isMoving_ = true;
        local facing = entity:GetFacing()
        local dirX, dirZ = math.cos(facing), -math.sin(facing);
        if(entity.tag == "open") then
            dirX, dirZ = -dirX, -dirZ;
            entity.tag = "close"
        else
            entity.tag = "open"
        end
        local x, y, z =  entity:GetPosition()
		local length = tonumber(entity:GetTagField("length") or 1)
        for i= 0, length, 0.1 do
            entity:SetPosition(x+dirX*i, y, z+dirZ*i)
            wait(0.01)
        end
		entity.isMoving_ = nil;
    end
end

-- push model out by GetTagField("length") or 1 meter
function API.Push(msg)
    local entity = GameLogic.EntityManager.GetEntity(msg.name)
    if(entity and not entity.isMoving_ and entity.tag ~= "open") then
        entity.isMoving_ = true;
        local facing = entity:GetFacing()
        local dirX, dirZ = math.cos(facing), -math.sin(facing);
        local x, y, z =  entity:GetPosition()
        local length = tonumber(entity:GetTagField("length") or 1)
        local delta = length > 0 and 0.1 or -0.1;
        for i= 0, length, delta do
            entity:SetPosition(x+dirX*i, y, z+dirZ*i)
            wait(0.01)
        end
        entity.tag = "open"
        entity.isMoving_ = nil;
    end
end

-- pull model in by GetTagField("length") or 1 meter
function API.Pull(msg)
    local entity = GameLogic.EntityManager.GetEntity(msg.name)
    if(entity and not entity.isMoving_ and entity.tag == "open") then
        entity.isMoving_ = true;
        local facing = entity:GetFacing()
        local dirX, dirZ = -math.cos(facing), math.sin(facing);
        local x, y, z =  entity:GetPosition()
        local length = tonumber(entity:GetTagField("length") or 1)
        local delta = length > 0 and 0.1 or -0.1;
        for i= 0, length, delta do
            entity:SetPosition(x+dirX*i, y, z+dirZ*i)
            wait(0.01)
        end
        entity.tag = "close"
        entity.isMoving_ = nil;
    end
end

-- Lift/Drop model by GetTagField("length") or 1 meter
function API.LiftDrop(msg)
    local entity = GameLogic.EntityManager.GetEntity(msg.name)
    if(entity and not entity.isMoving_) then
        entity.isMoving_ = true;
        local facing = entity:GetFacing()
        local x, y, z =  entity:GetPosition()
        local dir = 1;
        if(entity.tag == "open") then
            dir = -1;
            entity.tag = "close"
        else
            entity.tag = "open"
        end
        local length = tonumber(entity:GetTagField("length") or 1)
        local delta = length > 0 and 0.1 or -0.1;
        
        for i= 0, length, delta do
            entity:SetPosition(x, y + i*dir, z)
            wait(0.01)
        end
        entity.isMoving_ = nil;
    end
end

-- Lift model up by GetTagField("length") or 1 meter
function API.Lift(msg)
    local entity = GameLogic.EntityManager.GetEntity(msg.name)
    if(entity and not entity.isMoving_ and entity.tag ~= "open") then
        entity.isMoving_ = true;
        local x, y, z = entity:GetPosition()
        local length = tonumber(entity:GetTagField("length") or 1)
        local delta = length > 0 and 0.1 or -0.1;
        for i = 0, length, delta do
            entity:SetPosition(x, y + i, z)
            wait(0.01)
        end
        entity.tag = "open"
        entity.isMoving_ = nil;
   end
end

local function playMovie(name, x, y, z)
    if MovieManager:GetInited() == nil then --if not in world or is entering world something logic is not Init,so return
        return
    end
    local channel = MovieManager:CreateGetMovieChannel(name);
    if (channel) then
        local movieEntity = GameLogic.EntityManager.GetBlockEntity(math.floor(x), math.floor(y),
            math.floor(z))
        channel:SetStartBlockPosition(math.floor(x), math.floor(y), math.floor(z));

        local movieClip = movieEntity:GetMovieClip()
        if (movieClip) then
            local toTime = movieClip:GetLength();
            if channel.timer then
                channel:Stop()
                channel.timer:Change()
                channel.timer = nil
            end
            channel.timer = commonlib.Timer:new({
                callbackFunc = function(timer)
                    channel.timer:Change()
                    channel.timer = nil
                    channel:Stop()
                end
            })
            channel.timer:Change(toTime, nil)
        end
        channel:Play(0, -1)
    end
end

-- Drop model down by GetTagField("length") or 1 meter
function API.Drop(msg)
    local entity = GameLogic.EntityManager.GetEntity(msg.name)
    if(entity and not entity.isMoving_ and entity.tag == "open") then
        entity.isMoving_ = true;
        local x, y, z = entity:GetPosition()
        local length = tonumber(entity:GetTagField("length") or 1)
        local delta = length > 0 and 0.1 or -0.1;
        for i = 0, length, delta do
            entity:SetPosition(x, y - i, z)
            wait(0.01)
       end
        entity.tag = "close"
        entity.isMoving_ = nil;
   end
end

function API.PlayMovieEnd()
    if (API.movieChannelName) then
        if MovieManager:GetInited() == nil then --if not in world or is entering world something logic is not Init,so return
            return
        end
        local channel = MovieManager:CreateGetMovieChannel(API.movieChannelName);
        if channel then
            channel:Disconnect("finished", API, API.PlayMovieEnd);
            channel:Stop()
        end
    end
end
-- turn model GetTagField("angle") or 130 around axis GetTagField("axis") or "y"
function API.Door(msg)
    local entity = GameLogic.EntityManager.GetEntity(msg.name)
    if(entity and not entity.isMoving_) then
        entity.isMoving_ = true;
        local axis = entity:GetTagField("axis") or "y";

        local fromAngle = 0;
        if(axis == "x") then
            fromAngle = entity:GetPitch()
        elseif(axis == "z") then
            fromAngle = entity:GetRoll()
        else
            fromAngle = entity:GetFacing()
        end

        local dir = 1;
        if(entity.tag == "open") then
            entity.tag = "close"
            dir = -1;
        else
            entity.tag = "open"
        end
        if (entity.tag == "open") then
            local movie = entity:GetTagField("movie");
            if (movie ~= nil and movie ~= "") then
                local x, y, z, cmd_text_remain = movie:match(
                    "^([~%-%d]%-?[%d%.]*)[%s,]+([~%-%d]%-?[%d%.]*)[%s,]+([~%-%d]%-?[%d%.]*)%s*(.*)$");
                if x and y and z then
                    --����
                    local name = string.format("movie_%s_%s_%s", x, y, z)
                    playMovie(name, x, y, z)
                else
                    --����
                    local entities = GameLogic.EntityManager.FindEntities({ category = "searchable", });
                    if (entities) then
                        local bFind = false
                        for i, _entity in ipairs(entities) do
                            local name = tostring(_entity:GetDisplayName() or "");
                            if (name ~= "" and name == movie) then
                                local bx, by, bz = _entity:GetBlockPos()
                                playMovie(name, bx, by, bz)
                                bFind = true
                                break
                            end
                        end
                        if not bFind then
                            -- ���ҵ�Ӱ�ļ�������
                            local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
                            local filename = movie;

                            -- �����ļ���չ��
                            local fileExt = filename:match("%.(%w+)$");
                            if (fileExt ~= "xml") then
                                filename = filename .. ".blocks.xml";
                            end
                            if (filename:match("^~")) then
                                filename = ParaIO.GetWritablePath() .. "temp/" .. filename:sub(2, -1)
                            end

                            local fullpath;
                            if (commonlib.Files.IsAbsolutePath(filename)) then
                                fullpath = filename;
                            else
                                fullpath = Files.GetWorldFilePath(filename) or
                                    (not filename:match("[/\\]") and Files.GetWorldFilePath("blocktemplates/" .. filename)) or
                                    Files.WorldPathToFullPath(commonlib.Encoding.Utf8ToDefault(filename));
                            end

                            -- ����ҵ��ļ������ŵ�Ӱ
                            if fullpath and ParaIO.DoesFileExist(fullpath, true) then
                                if MovieManager:GetInited() == nil then --if not in world or is entering world something logic is not Init,so return
                                    return
                                end
                                MovieManager:Reset()
                                local movie_name = "default"
                                local channel = MovieManager:CreateGetMovieChannel(movie_name);
                                API.movieChannelName = movie_name;
                                local bx, by, bz = entity:GetBlockPos();
                                channel:CreateFromTemplateFile(fullpath, bx, by, bz);
                                channel:Stop()
                                channel:Play(0, -1);
                                channel:Connect("finished", API, API.PlayMovieEnd);
                            end
                        end
                    end
                end
            end
        end
        local angle = tonumber(entity:GetTagField("angle") or 130)
        local axis = entity:GetTagField("axis") or "y";
        local deltaAngle = angle > 0 and 10 or -10
        for i = 0, angle, deltaAngle do
            if (axis == "x") then
                entity:SetPitch(fromAngle + dir * i / 180 * math.pi)
            elseif (axis == "z") then
                entity:SetRoll(fromAngle + dir * i / 180 * math.pi)
            else
                entity:SetFacing(fromAngle + dir * i / 180 * math.pi)
            end
            wait(0.01)
        end
        entity.isMoving_ = nil;
    end
end

-- Open door by rotating around axis
function API.DoorOpen(msg)
    local entity = GameLogic.EntityManager.GetEntity(msg.name)
    if(entity and not entity.isMoving_ and entity.tag ~= "open") then
        entity.isMoving_ = true;
        local axis = entity:GetTagField("axis") or "y";
        
        local fromAngle = 0;
        if(axis == "x") then
            fromAngle = entity:GetPitch()
        elseif(axis == "z") then
            fromAngle = entity:GetRoll()
        else
            fromAngle = entity:GetFacing()
        end
        
        local angle = tonumber(entity:GetTagField("angle") or 130)
        local deltaAngle = angle > 0 and 10 or -10
        for i = 0, angle, deltaAngle do
            if(axis == "x") then
                entity:SetPitch(fromAngle + i /180*math.pi)
            elseif(axis == "z") then
                entity:SetRoll(fromAngle + i /180*math.pi)
            else
                entity:SetFacing(fromAngle + i /180*math.pi)
            end
            wait(0.01)
        end
        entity.tag = "open"
        entity.isMoving_ = nil;
    end
end

-- Close door by rotating around axis
function API.DoorClose(msg)
    local entity = GameLogic.EntityManager.GetEntity(msg.name)
    if(entity and not entity.isMoving_ and entity.tag == "open") then
        entity.isMoving_ = true;
        local axis = entity:GetTagField("axis") or "y";
        
        local fromAngle = 0;
        if(axis == "x") then
            fromAngle = entity:GetPitch()
        elseif(axis == "z") then
            fromAngle = entity:GetRoll()
        else
            fromAngle = entity:GetFacing()
        end
        
        local angle = tonumber(entity:GetTagField("angle") or 130)
        local deltaAngle = angle > 0 and 10 or -10
        for i = 0, angle, deltaAngle do
            if(axis == "x") then
                entity:SetPitch(fromAngle - i /180*math.pi)
            elseif(axis == "z") then
                entity:SetRoll(fromAngle - i /180*math.pi)
            else
                entity:SetFacing(fromAngle - i /180*math.pi)
            end
            wait(0.01)
        end
        entity.tag = "close"
        entity.isMoving_ = nil;
    end
end

function API.ClickLight(msg)
    local entity = GameLogic.EntityManager.GetEntity(msg.name)
    if(entity) then
        local bx, by, bz = entity:GetBlockPos()
        local id = getBlock(bx, by, bz)
        local lightblockId = 270 -- invisible light block 
        local effectName = entity.name .. "_effect"
        local entity_effect = GameLogic.EntityManager.GetEntity(effectName)

        if (entity.tag == "on") then
            entity.tag = nil
            if (entity_effect) then
                entity_effect:Destroy()
            end
            if (id == lightblockId) then
                setBlock(bx, by, bz, 0)
            end
        else
            if (not id or id == 0 or id == lightblockId) then
                entity.tag = "on"
                setBlock(bx, by, bz, lightblockId)
                local useEffect = tostring(entity:GetTagField("useEffect")) or ""
                if (useEffect ~= "") then
                    if (entity_effect == nil) then
                        entity_effect = GameLogic.EntityManager.EntityLiveModel:Create({ bx, by, bz });
                        entity_effect:SetModelFile(useEffect);
                        entity_effect:Attach();
                    end
                    entity_effect:SetBlockPos(bx, by, bz)
                    entity_effect:SetName(effectName)
                    entity_effect:SetPersistent(false)
                end
            end
        end
    end
end

-- Turn light on
function API.LightOn(msg)
    local entity = GameLogic.EntityManager.GetEntity(msg.name)
    if(entity and entity.tag ~= "on") then
        local bx, by, bz = entity:GetBlockPos()
        local id = getBlock(bx, by, bz)
        local lightblockId = 270 -- invisible light block
        if(not id or id == 0 or id == lightblockId) then
            entity.tag = "on"
            setBlock(bx, by, bz, lightblockId)
        end
    end
end


function API.ClickSuspended(msg)
    local entity = GameLogic.EntityManager.GetEntity(msg.name)
    if (entity) then
        local bx, by, bz = entity:GetBlockPos()
        local entities = GameLogic.EntityManager.GetEntitiesByMinMax(bx, by, bz, bx, by + 2, bz, nil, entity)
        local objs = {}
        if (entities) then
            for _, _entity in ipairs(entities) do
                if entity.name ~= _entity.name then
                    table.insert(objs, _entity)
                end
            end
        end

        if (entity.tag == "on") then
            entity.tag = nil
            -- ��entity.tag == "on"ʱ����objs�е�����entity�½�
            if #objs > 0 then
                for i, _e in ipairs(objs) do
                    _e:FallDown()
                end
            end
        else
            entity.tag = "on"
            -- ��entity.tag ~= "on"ʱ����objs�е�����entityλ������
            if #objs > 0 then
                local aabb = entity:GetInnerObjectAABB()
                local max_x, max_y, max_z = aabb:GetMaxValues()
                local extend_y = aabb:GetExtendY()
                local target_y = max_y + extend_y * 2    -- Ŀ��Yλ�ã��߶�Ϊ max_y + extend_y * 2

                local duration = 0.5                     -- ��ʱ��0.5��
                local step_time = 0.03                  -- ÿ�����ʱ��
                local total_steps = duration / step_time -- �ܲ���
                
                -- Բ�ηֲ�����
                local entity_count = #objs
                local center_x, center_y, center_z = entity:GetPosition()  -- �Դ���ʵ��ΪԲ��
                local radius = 0.5                                           -- �̶��뾶Ϊ1
                
                -- Ϊ����objs�е�entity����Բ�ηֲ���������
                for i, _e in ipairs(objs) do
                    local _x, _y, _z = _e:GetPosition()
                    local start_y = _y
                    
                    -- ����Ŀ��λ��
                    local target_x, target_z
                    
                    if entity_count == 1 then
                        -- ֻ��1��ʵ��ʱ������Բ��λ��
                        target_x = center_x
                        target_z = center_z
                    elseif entity_count == 2 then
                        -- 2��ʵ��ʱ���ֲ���ֱ����
                        target_x = center_x + (i == 1 and -radius or radius)
                        target_z = center_z
                    else
                        -- 3��������ʵ��ʱ���ȷ�Բ��
                        local angle = (i - 1) / entity_count * 2 * math.pi
                        target_x = center_x + radius * math.cos(angle)
                        target_z = center_z + radius * math.sin(angle)
                    end

                    -- Ϊÿ��entity���������Ķ���Э��
                    commonlib.TimerManager.SetTimeout(function()
                        for j = 0, total_steps do
                            local progress = j / total_steps                            -- ���ȱ��� (0��1)
                            local current_x = _x + (target_x - _x) * progress           -- Xλ�ò�ֵ
                            local current_y = start_y + (target_y - start_y) * progress -- Yλ�ò�ֵ
                            local current_z = _z + (target_z - _z) * progress           -- Zλ�ò�ֵ
                            _e:SetPosition(current_x, current_y, current_z)             -- ������λ��
                            env_imp.wait(env_imp, step_time)                            -- �ȴ���һ֡
                        end
                        -- ȷ������λ��׼ȷ
                        _e:SetPosition(target_x, target_y, target_z)
                    end, i * 5) -- ÿ��entity�ӳ�10ms��ʼ�����������Ķ���Ч��
                end
            end
        end
    end
end

function API.ClickShowImg(msg)
    local entity = GameLogic.EntityManager.GetEntity(msg.name)
    if (entity) then
        local img_url = entity:GetTagField("img_url") or "";

        if (img_url ~= "") then
            local fullpath;

            -- ���������URL��ֱ��ʹ��
            if (img_url:match("^https?://")) then
                fullpath = img_url;
            else
                -- ���ұ���ͼƬ�ļ�
                local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
                local filename = img_url;

                -- �����ļ���չ��
                local fileExt = filename:match("%.(%w+)$");
                if (fileExt ~= "png" and fileExt ~= "jpg" and fileExt ~= "jpeg" and fileExt ~= "gif" and fileExt ~= "bmp") then
                    filename = filename .. ".png";
                end

                if (filename:match("^~")) then
                    filename = ParaIO.GetWritablePath() .. "temp/" .. filename:sub(2, -1)
                end

                if (commonlib.Files.IsAbsolutePath(filename)) then
                    fullpath = filename;
                else
                    fullpath = Files.GetWorldFilePath(filename) or
                        (not filename:match("[/\\]") and Files.GetWorldFilePath("blocktemplates/" .. filename)) or
                        Files.WorldPathToFullPath(commonlib.Encoding.Utf8ToDefault(filename));
                end

                if (not fullpath and ParaIO.DoesFileExist(filename, true)) then
                    fullpath = filename;
                end
            end

            -- ��ʾͼƬ
            if (fullpath) then
                local width, height = tonumber(entity:GetTagField("width")),
                    tonumber(entity:GetTagField("height"))
                -- ����Ƿ�Ϊ����URL
                if fullpath:match("^https?://") then
                else
                    if width == 0 or height == 0 or width == nil or height == nil then
                        -- ���ڱ���ͼƬ�����Ի�ȡʵ�ʳߴ�
                        local img = Image:new()
                        img:LoadFromFile(fullpath)
                        if img.width and img.height and img.width > 0 and img.height > 0 then
                            width = img.width
                            height = img.height
                        else
                            print("Failed to load local image, using default size")
                        end
                    end
                end
                local text =
                    [[<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
                    <html xmlns="http://www.w3.org/1999/xhtml">
                    <head>
                        <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
                        <title></title>
                    </head>
                    <body>
                        <pe:mcml>
                            <script refresh="true" type="text/npl">
                                function onClose()
                                    Page:CloseWindow();
                                end
                            </script>
                            <pe:container alignment="_fi" width="100%" height="100%" style="background-color:#dcdcdc00">
                                <div onclick = "onClose" alignment="_fi" width="100%" height="100%" style="background-color:#dcdcdc00">
                                    <div align = "center" valign = "center" style = "width:]] ..
                    width .. [[px;height:]] .. height .. [[px;background:url(]] .. fullpath .. [[)">
                                    </div>
                                </div>
                            </pe:container>
                        </pe:mcml>
                    </body>
                    </html>]]
                local path = ParaIO.GetWritablePath() .. "temp/showImg.html"
                commonlib.Files.WriteFile(path, text)
                local my_window = System.Windows.Window:new();
                my_window:Show({ url = path, alignment = "_fi", left = 0, top = 0, width = 0, height = 0, zorder = 10, allowDrag = false });
                my_window:SetDesignResolution(1280, 720)
            end
        end
    end
end

-- Turn light off
function API.LightOff(msg)
    local entity = GameLogic.EntityManager.GetEntity(msg.name)
    if(entity and entity.tag == "on") then
        local bx, by, bz = entity:GetBlockPos()
        local id = getBlock(bx, by, bz)
        local lightblockId = 270 -- invisible light block
        if(id == lightblockId) then
            entity.tag = nil
            setBlock(bx, by, bz, 0)
        end
    end
end

-- toggle playing music files in GetTagField("sound")
function API.ToggleMusic(msg)
    local entity = GameLogic.EntityManager.GetEntity(msg.name)
    if(entity) then
        local filename = entity:GetTagField("sound")
        if(filename) then
            if(entity.curMusic_ == filename) then
                filename = nil;
            end
            entity.curMusic_ = filename;
            playMusic(filename)
        end
    end
end

-- play music from GetTagField("sound")
function API.MusicOn(msg)
    local entity = GameLogic.EntityManager.GetEntity(msg.name)
    if(entity and entity.curMusic_ ~= entity:GetTagField("sound")) then
        local filename = entity:GetTagField("sound")
        if(filename) then
            entity.curMusic_ = filename;
            playMusic(filename)
        end
    end
end

-- stop playing music
function API.MusicOff(msg)
    local entity = GameLogic.EntityManager.GetEntity(msg.name)
    if(entity and entity.curMusic_) then
        entity.curMusic_ = nil;
        playMusic(nil)
    end
end

function API.ClickGiftBox(msg)
    msg = commonlib.LoadTableFromString(msg)
    local entity = GameLogic.EntityManager.GetEntity(msg.name)
    if(entity and entity.tag == "hasGift") then
        local x, y, z = entity:GetPosition()
        local mountedEntity = entity:GetMountedEntityAt(1)
        if(mountedEntity) then
            mountedEntity:SetPosition(x, y, z)
            local scale = mountedEntity:GetScaling() * 10
            mountedEntity:SetScaling(scale)
            mountedEntity:SetCanDrag(true)
        end
        entity:Destroy()
    end
end

function API.Flip(msg)
    local entity = GameLogic.EntityManager.GetEntity(msg.name)
    if(entity) then
        local pitch = entity:GetPitch()
        if(pitch == 0) then
            local aabb = entity:GetInnerObjectAABB()
            local dx, dy, dz = aabb:GetExtendValues();
            entity:SetPitch(math.pi)
            entity:SetBootHeight(dy*2)
        else
            entity:SetPitch(0)
            entity:SetBootHeight(0)
        end
    end
end

-- turn facing by GetTagField("angle") or 90
function API.Turn(msg)
    local entity = GameLogic.EntityManager.GetEntity(msg.name)
    if(entity) then
        local facing = entity:GetFacing()
		local angle = tonumber(entity:GetTagField("angle") or 90)
        entity:SetFacing(facing + angle * math.pi / 180);
    end
end

local directions = { {-1, 0}, {1, 0}, {0, 1}, {0, -1}, {-1, -1}, {1, 1}, {1, -1}, {-1, 1} }
-- return dx, dz: if not nil, we have found a new location (prefer block without entities)
local function GetRandomNearbyBlockOfType(bx, by, bz, blockId)
    local count = #directions;
    local i = math.random(1, count)
    local dx1, dz1;
    for _ = 1, count do
        i = (i % count) + 1
        local dx, dz = directions[i][1], directions[i][2]
        if(BlockEngine:GetBlockId(bx+dx, by, bz+dz) == blockId) then
            dx1, dz1 = dx, dz
            local entities = GameLogic.EntityManager.GetEntitiesInBlock(bx+dx, by, bz+dz)
            if(not entities or not next(entities)) then
                break;
            end
        end
    end
    return dx1, dz1
end


-- randomly walk to another block with the same block type in random directions. 
function API.RandomWalkToSameBlockType(msg)
    local entity = GameLogic.EntityManager.GetEntity(msg.name)
    if(entity and not entity.isMoving_) then
        entity.isMoving_ = true;
        -- local walkDistance = tonumber(entity:GetTagField("walkDistance") or 1)
        local x, y, z = entity:GetPosition()
        local bx, by, bz = entity:GetBlockPos()
        local lastBlockId = getBlock(bx, by, bz)
        local dx, dz = GetRandomNearbyBlockOfType(bx, by, bz, lastBlockId)
        if(dx and dz) then
            local newX, newY, newZ = GameLogic.BlockEngine:real(bx+dx, by, bz+dz)
            for i = 0, 1, 0.02 do
                local x1 = newX * i + x * (1 - i);
                local z1 = newZ * i + z * (1 - i);
                entity:SetPosition(x1, y, z1)
                wait(0.01)
            end
        end
        entity.isMoving_ = nil;
    end
end

-- GetTagField("inWaterDepth")
function API.FloatToWaterSurface(msg)
    local entity = GameLogic.EntityManager.GetEntity(msg.name)
    if(entity) then
        local x, y, z = entity:GetPosition()
        local bx, by, bz = entity:GetBlockPos()
        local y1 = by;
        while(true) do
            local blockId = getBlock(bx, y1, bz)
            local blockId2 = getBlock(bx, y1+1, bz)
            if(blockId == 76 and blockId2 == 0) then
                y1 = y1 + 1;
                break;
            elseif(blockId2 == 76) then
                y1 = y1 + 1;
            else
                y1 = nil
                break
            end
        end
        if(y1) then
            local inWaterDepth = tonumber(entity:GetTagField("inWaterDepth") or 0.4);
            local destY = GameLogic.BlockEngine:realY(y1)-0.2-inWaterDepth
            entity:SetPosition(x, destY, z);
            
            -- swing back and forth
            local maxAngle = 15;
            for i=0, math.pi*4, 0.1 do
                maxAngle = maxAngle * 0.98
                angle = math.sin(i) * maxAngle /180 * math.pi
                entity:SetRoll(angle)
                wait(0.01)
            end
            entity:SetRoll(0)
        end
    end
end

-- GetTagField("codeblockName"): if empty, we will use the entity name
function API.OpenCodeblock(msg)
    local entity = GameLogic.EntityManager.GetEntity(msg.name)
    if(entity) then
        local codeblockName = entity:GetTagField("codeblockName")
        entity:OpenCodeEditor(codeblockName)
    end
end

-- Open the editable world UI for save/load operations
function API.OpenEditableWorld(msg)
    local entity = GameLogic.EntityManager.GetEntity(msg.name)
    if(entity) then
        local subtag = entity:GetStaticTag("subtag")
        NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyEditableWorld.lua");
        local EasyEditableWorld = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyEditableWorld");
        local task = EasyEditableWorld:new({operation="subtag", subtag = subtag});
        if(task) then
            task:OpenEditableWorld(subtag,entity);
        end
    end
end

-- Enter the editable world at the current location
function API.EnterEditableWorld(msg)
    local entity = GameLogic.EntityManager.GetEntity(msg.name)
    if(entity) then
        entity:SetAnimFrame(nil)
        local subtag = entity:GetStaticTag("subtag")
        NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyEditableWorld.lua");
        local EasyEditableWorld = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyEditableWorld");
        local task = EasyEditableWorld:new({operation="enter", subtag = subtag});
        task:OnEnterWorldPoint(subtag,entity);
    end
end

-- Leave the editable world and return to the previous world
function API.LeaveEditableWorld(msg)
    local entity = GameLogic.EntityManager.GetEntity(msg.name)
    if(entity) then
        entity:SetAnimFrame(0)
        NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyEditableWorld.lua");
        local EasyEditableWorld = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyEditableWorld");
        local task = EasyEditableWorld:new({operation="leave"});
        task:OnLeaveWorldPoint(subtag,entity);
    end
end

function API.PlayNearbyMovieBlockAsAgent(msg)
    local entity = GameLogic.EntityManager.GetEntity(msg.name)
    if(entity) then
        local movieEntity;
        local movieBlockName = entity:GetTagField("movieBlockName")
        local actorIndex = entity:GetTagField("actorIndex")
        local playRelative = entity:GetTagField("playRelative")
        
        if(not movieBlockName or movieBlockName == "") then
            local bx, by, bz = entity:GetBlockPos()
            local radius = 4;
            local entities = GameLogic.EntityManager.GetEntitiesByMinMax(
                bx - radius, by - radius, bz - radius, 
                bx + radius, by + radius, bz + radius, 
                GameLogic.EntityManager.EntityMovieClip
            )
            if(entities and #entities > 0) then
                movieEntity = entities[1]
                movieBlockName = "nearby_movie_block"
            else
                LOG.std(nil, "warn", "ParaLifeAPI", "No movie block found within %d meters", radius);
            end
        else
            movieEntity = GameLogic.EntityManager.FindFirstEntity(function(entity)
                return entity.displayName == movieBlockName and entity:isa(GameLogic.EntityManager.EntityMovieClip)
            end)
        end
        if(movieEntity) then
            NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/MovieManager.lua");
            local MovieManager = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieManager");
            local channel = MovieManager:CreateGetMovieChannel(movieBlockName);
            channel:CloneFromEntity(movieEntity);
            local player = GameLogic.EntityManager.GetFocus();
            local x, y, z = player:GetPosition();
            channel:SetAutoStopWhenPlayFinish(true)
            if playRelative ~= "false" and playRelative ~= false then
                channel:TransformActorsByFirstActor(x, y, z, player:GetFacing());
            end
            channel:BindActorAgentToEntity(1, player, true);
            channel:Play(0, -1)
        end
    end
end

-- Character interaction: plays an animation and optionally displays text
function API.CharInteract(msg)
    local entity = GameLogic.EntityManager.GetEntity(msg.name)
    if(entity) then
        NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyCharAction.lua");
        local EasyCharAction = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyCharAction");
        EasyCharAction:ShowPage(entity)
    end
end

function API.CookingPot(msg)
    local player = GameLogic.EntityManager.GetFocus() or GameLogic.EntityManager.GetPlayer()
    if player then
        local x, y, z = player:GetPosition()
        local facing = player:GetFacing()
        local dist = 1
        local nx = x + math.cos(facing) * dist
        local nz = z - math.sin(facing) * dist
        local name  = "CookingPot"
        local entity = GameLogic.EntityManager.GetEntity(name)
        if entity == nil then
            entity = GameLogic.EntityManager.EntityLiveModel:Create({x=nx, y=y, z=nz, facing=facing})
            entity:SetModelFile("character/CC/artwar/game/chai.x")
            entity:SetName(name)
            entity:SetPersistent(false)
            entity:SetStaticTag("actionname", entity:GetTagField("actionname") or L"烹饪")
            entity:SetCanDrag(true)
            entity:Attach()
        else
            entity:SetPosition(nx, y, nz)
        end
        entity:SetOnClickEvent("on_click_cooking_pot")
    end
end