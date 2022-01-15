--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-01-11 13:31:34
]]

local MovieClipCompare = commonlib.gettable("LessonBox.MovieClipCompare")
local types = {"slot","timelength","timeline","text","time","cmd","child_movie_block","backmusic","lookat_x","lookat_y","lookat_z","eye_liftup","eye_rot_y","eye_roll","parent","eye_dist",
	"actor_ani","actor_pos","actor_scale","actor_head","actor_speed","actor_model","actor_opcatiity","actor_parent","actor_name","actor_bone",}
function MovieClipCompare.CompareMovie(entitySrc,entityDst,compareType)
    local self = MovieClipCompare
    if not entitySrc or not entityDst then
		return false
	end
    if compareType == "timelength" then
        return self.CompareTimeLength(entitySrc,entityDst)
    end
    for i=1, entitySrc.inventory:GetSlotCount() do
		local itemStack = entitySrc.inventory:GetItem(i);
		local itemStack2 = entityDst.inventory:GetItem(i)
		if(itemStack and itemStack.count > 0 and itemStack.serverdata) and (itemStack2 and itemStack2.count > 0 and itemStack2.serverdata) then
            if compareType == "slot" then
                return self.CompareSlot(itemStack,itemStack2)
            end
            local timeseries1 = itemStack.serverdata.timeseries
			local timeseries2 = itemStack2.serverdata.timeseries
            if not timeseries1 and not timeseries2 then
            else
                if compareType == "timeline" then
                    return self.CompareTimes(timeseries1,timeseries2,itemStack)
                end
                if compareType == "text" then
                    return self.CompareText(timeseries1,timeseries2,itemStack)
                end
                if compareType == "time" then
                    return self.CompareTime(timeseries1,timeseries2,itemStack)
                end
                if compareType == "cmd" then
                    return self.CompareCmd(timeseries1,timeseries2,itemStack)
                end
                if compareType == "child_movie_block" then
                    return self.CompareMovieBlock(timeseries1,timeseries2,itemStack)
                end
                if compareType == "backmusic" then
                    return self.CompareMusic(timeseries1,timeseries2,itemStack)
                end
                if compareType == "lookat_x" or compareType == "lookat_y" or compareType == "lookat_z" then
                    return self.ComparePosition(timeseries1,timeseries2,itemStack,compareType)
                end
                if compareType == "eye_liftup" or compareType == "eye_rot_y" or compareType == "eye_roll" then
                    return self.CompareRotation(timeseries1,timeseries2,itemStack,compareType)
                end
                if compareType == "eye_dist" then
                    return self.CompareMovieDist(timeseries1,timeseries2,itemStack)
                end
                if compareType == "parent" then
                    return self.CompareParent(timeseries1,timeseries2,itemStack) 
                end
                if compareType == "actor_ani" then
                    return self.CompareActorAni(timeseries1,timeseries2,itemStack) 
                end
                if compareType == "actor_pos" then
                    return self.CompareActorPosition(timeseries1,timeseries2,itemStack)
                end
                if compareType == "actor_scale" then
                    return self.CompareActorScale(timeseries1,timeseries2,itemStack)
                end
                if compareType == "actor_facing" then
                    return self.CompareActorFacing(timeseries1,timeseries2,itemStack)
                end
                if compareType == "actor_rotate" then
                    return self.CompareActorRotation(timeseries1,timeseries2,itemStack)
                end
                if compareType == "actor_head" then
                    return self.CompareActorHead(timeseries1,timeseries2,itemStack) 
                end
                if compareType == "actor_speed" then
                    return self.CompareActorSpeed(timeseries1,timeseries2,itemStack) 
                end
                if compareType == "actor_model" then
                    return self.CompareActorModel(timeseries1,timeseries2,itemStack) 
                end
                if compareType == "actor_skin" then
                    return self.CompareActorSkin(timeseries1,timeseries2,itemStack) 
                end
                if compareType == "actor_opcatity" then
                    return self.CompareActorOpcatity(timeseries1,timeseries2,itemStack)
                end
                if compareType == "actor_name" then
                    return self.CompareActorName(timeseries1,timeseries2,itemStack) 
                end
                if compareType == "actor_parent" then
                    return self.CompareActorParent(timeseries1,timeseries2,itemStack) 
                end
            end
		else
			if not itemStack and not itemStack2 then
			else
				return false
			end
		end
	end
    return true
end

function MovieClipCompare.CompareSlot(itemStack,itemStack2)
	local compare_data = {}
	compare_data.compare_type = "movie_slot"
	--判断是否每个格子放的物品是一样的
	if itemStack.id ~= itemStack2.id then
        compare_data.my_id = itemStack.id
        compare_data.compare_id = itemStack2.id
        return false,compare_data
    end
    return true,compare_data
end

function MovieClipCompare.CompareTimeLength(entitySrc,entityDst)
	--电影方块的时间不一样
	local compare_data = {}
	compare_data.compare_type = "movie_length"
	if(entitySrc.length ~= entityDst.length)then
		compare_data.my_length = entitySrc.length
		compare_data.compare_length = entityDst.length
		return false,compare_data
	end
	return true,compare_data
end

function MovieClipCompare.CompareTimes(timeseries1,timeseries2,itemStack)
    local compare_data = {}
	compare_data.compare_type = "movie_timeline"
	local keyConfig = {
		[10061] = {"lookat_x","lookat_y","lookat_z","eye_dist","eye_liftup","eye_roll","eye_rot_y","parent"},
		[10062] = {"blockinhand","HeadUpdownAngle","HeadTurningAngle","y","x","z","assetfile","skin","speedscale","facing","roll","block","pitch","anim","scaling","gravity","parent"},
		[10063] = {"music","movieblock","cmd","tip","time","blocks","text"}
	}
	if (not timeseries1 and timeseries2) or (timeseries1 and not timeseries2)  then
        return false,compare_data				
    end
    local config = keyConfig[itemStack.id]
    if config then
        for k,v in pairs(config) do
            if (timeseries1[v] and not timeseries2[v]) or (not timeseries1[v] and timeseries2[v]) then
                return false,compare_data
            end
            if (timeseries1[v] and  timeseries2[v])then
                local times1 = timeseries1[v].times
                local times2 = timeseries2[v].times
                if #times1 ~= #times2 then
                    compare_data.compare_key = v
                    compare_data.my_times = times1
                    compare_data.compare_times = times2
                    return false,compare_data --关键帧数量不一样
                else
                    local num = #times1
                    for i=1,num do
                        local nDeNum = math.abs(times1[i] - times2[i])
                        if (nDeNum >= 200) then --关键帧大小相差200ms以上
                            compare_data.compare_key = v
                            compare_data.my_times = times1
                            compare_data.compare_times = times2
                            compare_data.time_dis = nDeNum
                            compare_data.compare_idx = i
                            return false,compare_data
                        end

                    end				
                end
            end			
        end
    end
	return true,compare_data
end

function MovieClipCompare.CompareText(timeseries1,timeseries2,itemStack)
	local compare_data = {}
	compare_data.compare_type = "movie_text"
	if (timeseries1 and not timeseries2) or (not timeseries1 and timeseries2)  then
        return false,compare_data				
    end
    if itemStack.id == 10063 then
        if (timeseries1.text and not timeseries2.text) or (not timeseries1.text and timeseries2.text) then
            return false,compare_data
        end	
        if (timeseries1.text and timeseries2.text) then
            local myCnf = timeseries1.text.data
            local otherCnf = timeseries2.text.data
            for i=1,#myCnf do
                if myCnf[i].text ~= otherCnf[i].text or myCnf[i].textbg ~= otherCnf[i].textbg
                or myCnf[i].bgcolor ~= otherCnf[i].bgcolor or myCnf[i].textanim ~= otherCnf[i].textanim
                or myCnf[i].fontcolor ~= otherCnf[i].fontcolor or myCnf[i].fontsize ~= otherCnf[i].fontsize
                or myCnf[i].textpos ~= otherCnf[i].textpos then
                    compare_data.my_textCnf = myCnf[i]
                    compare_data.compare_textCnf = otherCnf[i]
                    compare_data.compare_idx = i
                    return false,compare_data
                end
            end
        end
    end	
	return true,compare_data
end

function MovieClipCompare.CompareTime(timeseries1,timeseries2,itemStack) --一天中的时间段
	local compare_data = {}
	compare_data.compare_type = "movie_time"
	if (timeseries1 and not timeseries2) or (not timeseries1 and timeseries2)  then
        return false,compare_data				
    end
    if itemStack.id == 10063 then
        if (timeseries1.time and not timeseries2.time) or (not timeseries1.time and timeseries2.time) then
            return false,compare_data
        end					
        if (timeseries1.time and timeseries2.time) then
            local myCnf = timeseries1.time.data
            local otherCnf = timeseries2.time.data
            local num = #myCnf
            for i=1,num do
                local fDis = myCnf[i] - otherCnf[i]
                if math.abs(fDis) > 0.1 then
                    compare_data.worldtime_dis = fDis
                    compare_data.compare_idx = i
                    return false,compare_data
                end
            end
        end				
    end	
	return true,compare_data
end

function MovieClipCompare.CompareCmd(timeseries1,timeseries2,itemStack) 
	local compare_data = {}
	compare_data.compare_type = "movie_cmd"
	if (timeseries1 and not timeseries2) or (not timeseries1 and timeseries2)  then
        return false,compare_data				
    end
    if itemStack.id == 10063 then
        if (timeseries1.cmd and not timeseries2.cmd) or (not timeseries1.cmd and timeseries2.cmd) then
            return false,compare_data				
        end	
        if timeseries1.cmd and timeseries2.cmd then
            local myCnf = timeseries1.cmd.data
            local otherCnf = timeseries2.cmd.data
            local num = #myCnf
            for i=1,num do
                if myCnf[i] ~= otherCnf[i] then
                    compare_data.my_cmd = myCnf[i]
                    compare_data.compare_cmd = otherCnf[i]
                    compare_data.compare_idx = i
                    return false,compare_data
                end							
            end			
        end				
    end	
	return true,compare_data
end

function MovieClipCompare.CompareMovieBlock(timeseries1,timeseries2,itemStack) 
	local compare_data = {}
	compare_data.compare_type = "movie_block"
	if (timeseries1 and not timeseries2) or (not timeseries1 and timeseries2)  then
        return false,compare_data				
    end
    if itemStack.id == 10063 then
        if (timeseries1.movieblock and not timeseries2.movieblock) or (not timeseries1.movieblock and timeseries2.movieblock) then
            return false,compare_data
        end	
        if (timeseries1.movieblock and timeseries2.movieblock) then
            local myCnf = timeseries1.movieblock.data
            local otherCnf = timeseries2.movieblock.data
            local num = #myCnf
            for i=1,num do
                if 	myCnf[i][1] ~= otherCnf[i][1] or myCnf[i][2] ~= otherCnf[i][2]	 or myCnf[i][3] ~= otherCnf[i][3]	then
                    compare_data.my_block = myCnf[i]
                    compare_data.compare_block = otherCnf[i]
                    compare_data.compare_idx = i	
                    return false,compare_data
                end
            end
        end					
    end	
	return true,compare_data
end

function MovieClipCompare.CompareMusic(timeseries1,timeseries2,itemStack) 
	local compare_data = {}
	compare_data.compare_type = "movie_music"
    if (timeseries1 and not timeseries2) or (not timeseries1 and timeseries2)  then
        return false,compare_data				
    end
	if itemStack.id == 10063 then
        if (timeseries1.music and not timeseries2.music) or (not timeseries1.music and timeseries2.music) then
            return false,compare_data
        end	
        if (timeseries1.music and timeseries2.music) then
            local myCnf = timeseries1.music.data
            local otherCnf = timeseries2.music.data
            local num = #myCnf
            for i=1,num do
                if myCnf[i] ~= otherCnf[i] then
                    compare_data.my_music = myCnf[i]
                    compare_data.compare_music = otherCnf[i]
                    compare_data.compare_idx = i
                    return false,compare_data
                end							
            end
        end	
        
    end	
	return true,compare_data
end

function MovieClipCompare.ComparePosition(timeseries1,timeseries2,itemStack,key) 
    local compare_data = {}
    compare_data.compare_type = "movie_position"
	if (timeseries1 and not timeseries2) or (not timeseries1 and timeseries2)  then
        return false,compare_data				
    end
    if itemStack.id == 10061 then
        if (timeseries1[key] and not timeseries2[key]) or (not timeseries1[key] and timeseries2[key]) then
            return false,compare_data
        end	
        if (timeseries1[key] and timeseries2[key]) then
            local myCnf = timeseries1[key].data
            local otherCnf = timeseries2[key].data
            local num = #myCnf
            for i=1,num do
                local nDis = myCnf[i] - otherCnf[i]
                if math.abs(nDis) > 3 then
                    compare_data.compare_key = key
                    compare_data.compare_idx = i
                    compare_data.compare_dis = nDis
                    compare_data.my_pos = MovieClipCompare.GetCurPosition(timeseries1,i)
                    compare_data.compare_pos = MovieClipCompare.GetCurPosition(timeseries2,i)
                    return false,compare_data
                end						
            end
        end	
    end	
	return true,compare_data
end

function MovieClipCompare.GetCurPosition(timeseries,index)
    local x = timeseries.lookat_x.data[index]
    local y = timeseries.lookat_y.data[index]
    local z = timeseries.lookat_z.data[index]
    return {x,y,z}
end

function MovieClipCompare.GetRotation(timeseries,index)
    local roll,pitch,yaw  --eye_roll,eye_liftup,eye_rot_y
    roll = timeseries.eye_roll.data[index]
    pitch = timeseries.eye_liftup.data[index]
    yaw = timeseries.eye_rot_y.data[index]
    return {roll,pitch,yaw}
end

function MovieClipCompare.CompareRotation(timeseries1,timeseries2,itemStack,key)
    local compare_data = {}
    compare_data.compare_type = "compare_rotation"
	if (timeseries1 and not timeseries2) or (not timeseries1 and timeseries2)  then
        return false,compare_data				
    end
    if itemStack.id == 10061 then
        if (timeseries1[key] and not timeseries2[key]) or (not timeseries1[key] and timeseries2[key]) then
            return false,compare_data
        end	
        if (timeseries1[key] and timeseries2[key]) then
            local myCnf = timeseries1[key].data
            local otherCnf = timeseries2[key].data
            local num = #myCnf
                for i=1,num do
                    local fDis = myCnf[i] - otherCnf[i]
                    if (math.abs(fDis) > 0.3)  then
                        compare_data.compare_key = key
                        compare_data.compare_idx = i
                        compare_data.compare_dis = fDis
                        compare_data.my_rotate = MovieClipCompare.GetRotation(timeseries1,i)
                        compare_data.compare_rotate = MovieClipCompare.GetRotation(timeseries2,i)
                        return false,compare_data
                    end						
                end
        end
    end	
	return true
end

function MovieClipCompare.CompareMovieDist(timeseries1,timeseries2,itemStack)
    local compare_data = {}
	compare_data.compare_type = "movie_eyedist"
	if (timeseries1 and not timeseries2) or (not timeseries1 and timeseries2)  then
        return false,compare_data				
    end
    if itemStack.id == 10061 then
        if (timeseries1.eye_dist and not timeseries2.eye_dist) or (not timeseries1.eye_dist and timeseries2.eye_dist) then
            return false,compare_data				
        end	
        if timeseries1.eye_dist and timeseries2.eye_dist then
            local myCnf = timeseries1.eye_dist.data
            local otherCnf = timeseries2.eye_dist.data
            local num = #myCnf
            for i=1,num do
                local fDis = myCnf[i] - otherCnf[i]
                if math.abs( fDis ) > 0.5 then
                    compare_data.my_eye_dist = myCnf[i]
                    compare_data.compare_eye_dist = otherCnf[i]
                    compare_data.compare_dis = fDis
                    compare_data.compare_idx = i
                    return false,compare_data
                end							
            end			
        end				
    end	
	return true,compare_data
end

function MovieClipCompare.CompareParent(timeseries1,timeseries2,itemStack) 
    local compare_data = {}
	compare_data.compare_type = "movie_parent"
	if (timeseries1 and not timeseries2) or (not timeseries1 and timeseries2)  then
        return false,compare_data				
    end
    if itemStack.id == 10061 then
        if (timeseries1.parent and not timeseries2.parent) or (not timeseries1.parent and timeseries2.parent) then
            return false,compare_data
        end	
        if (timeseries1.parent and timeseries2.parent) then
            local myCnf = timeseries1.parent.data
            local otherCnf = timeseries2.parent.data
            local num = #myCnf
            local isSame = true
            for i=1,num do
                compare_data.compare_idx = i
                if myCnf[i].target ~= otherCnf[i].target then
                    isSame = false
                    compare_data.compare_key = "target"
                end
                if isSame and  (math.abs(myCnf[i].rot[1]*180/math.pi - otherCnf[i].rot[1]*180/math.pi) > 35 
                    or math.abs(myCnf[i].rot[2]*180/math.pi - otherCnf[i].rot[2]*180/math.pi) > 35  
                    or math.abs(myCnf[i].rot[3]*180/math.pi - otherCnf[i].rot[3]*180/math.pi) > 35) then
                        compare_data.compare_key = "rot"
                        isSame = false
                end
                if isSame and  (math.abs(myCnf[i].pos[1] - otherCnf[i].pos[1]) > 3 
                    or math.abs(myCnf[i].pos[2] - otherCnf[i].pos[2]) > 3  
                    or math.abs(myCnf[i].pos[3] - otherCnf[i].pos[3]) > 3) then
                        compare_data.compare_key = "pos"
                        isSame = false
                end
                if not isSame then
                    compare_data.my_target = myCnf[i].target
                    compare_data.compare_target = myCnf[i].target
                    compare_data.my_rot = myCnf[i].rot
                    compare_data.compare_rot = myCnf[i].rot
                    compare_data.my_pos = myCnf[i].pos
                    compare_data.compare_pos = myCnf[i].pos
                    return false,compare_data
                end
            end
        end				
    end
	return true,compare_data
end

function MovieClipCompare.CompareActorAni(timeseries1,timeseries2,itemStack) 
	local compare_data = {}
	compare_data.compare_type = "movie_actor_anim"
	if (timeseries1 and not timeseries2) or (not timeseries1 and timeseries2)  then
        return false,compare_data				
    end
    if itemStack.id == 10062 then
        if (timeseries1.anim and not timeseries2.anim) or (not timeseries1.anim and timeseries2.anim) then
            return false,compare_data
        end	
        if (timeseries1.anim and timeseries2.anim) then
            local myCnf = timeseries1.anim.data
            local otherCnf = timeseries2.anim.data
            local num = #myCnf
            for i=1,num do
                if myCnf[i] ~= otherCnf[i] then
                    compare_data.my_anim = myCnf[i]
                    compare_data.compare_anim = otherCnf[i]
                    compare_data.compare_idx = i
                    return false,compare_data
                end							
            end	
        end				
    end	
	return true,compare_data
end

function MovieClipCompare.CompareActorPosition(timeseries1,timeseries2,itemStack) 
	local compare_data = {}
	compare_data.compare_type = "movie_actor_pos"
	if (timeseries1 and not timeseries2) or (not timeseries1 and timeseries2)  then
        return false,compare_data				
    end

    local getPos = function (timeseries,index)
        local x = timeseries.x.data[index]
        local y = timeseries.y.data[index]
        local z = timeseries.z.data[index]
        return {x,y,z}
    end

    local keys = {"x","y","z"}
    if itemStack.id == 10062 then
        for k,v in pairs(keys) do
            if (timeseries1[v] and not timeseries2[v]) or (not timeseries1[v] and timeseries2[v]) then
                return false,compare_data
            end	
            if (timeseries1[v] and timeseries2[v]) then
                local myCnf = timeseries1[v].data
                local otherCnf = timeseries2[v].data
                local num = #myCnf
                for i=1,num do
                    local fDis = myCnf[i] - otherCnf[i]
                    if math.abs(fDis) > 3 then
                        compare_data.compare_key = "actor_"..v
                        compare_data.compare_dis = fDis
                        compare_data.compare_idx = i
                        compare_data.my_pos = getPos(timeseries1,i)
                        compare_data.compare_pos = getPos(timeseries2,i)
                        return false,compare_data
                    end							
                end	
            end	
        end							
    end	
	return true,compare_data
end

function MovieClipCompare.CompareActorScale(timeseries1,timeseries2,itemStack) 
    local compare_data = {}
	compare_data.compare_type = "movie_actor_scale"
	if (timeseries1 and not timeseries2) or (not timeseries1 and timeseries2)  then
        return false,compare_data				
    end
	if itemStack.id == 10062 then
        if (timeseries1.scaling and not timeseries2.scaling) or (not timeseries1.scaling and timeseries2.scaling) then
            return false,compare_data
        end	
        if (timeseries1.scaling and timeseries2.scaling) then
            local myCnf = timeseries1.scaling.data
            local otherCnf = timeseries2.scaling.data
            local num = #myCnf
            for i=1,num do
                local fDis = myCnf[i] - otherCnf[i]
                if math.abs(fDis) > 0.5 then
                    compare_data.compare_idx = i
                    compare_data.compare_dis = fDis
                    compare_data.my_scale = myCnf[i]
                    compare_data.compare_scale = otherCnf[i]
                    return false,compare_data
                end							
            end	
        end								
    end	
	return true,compare_data
end

function MovieClipCompare.CompareActorFacing(timeseries1,timeseries2,itemStack) 
    local compare_data = {}
	compare_data.compare_type = "movie_actor_facing"
	if (timeseries1 and not timeseries2) or (not timeseries1 and timeseries2)  then
        return false,compare_data				
    end
	if itemStack.id == 10062 then
        if (timeseries1.facing and not timeseries2.facing) or (not timeseries1.facing and timeseries2.facing) then
            return false,compare_data
        end	
        if (timeseries1.facing and timeseries2.facing) then
            local myCnf = timeseries1.facing.data
            local otherCnf = timeseries2.facing.data
            local num = #myCnf
            for i=1,num do
                local fDis = myCnf[i] - otherCnf[i] 
                if math.abs(fDis) * 180 /math.pi > 35 then
                    compare_data.compare_idx = i
                    compare_data.compare_dis = math.abs(fDis)* 180 /math.pi
                    compare_data.my_facing = myCnf[i]
                    compare_data.compare_facing = otherCnf[i]
                    return false,compare_data
                end							
            end	
        end								
    end	
	return true,compare_data
end

--yaw :: facing  roll:25 yaw pitch
function MovieClipCompare.CompareActorRotation(timeseries1,timeseries2,itemStack) 
	local compare_data = {}
	compare_data.compare_type = "movie_actor_rotate"
	if (timeseries1 and not timeseries2) or (not timeseries1 and timeseries2)  then
        return false,compare_data				
    end

    local getRotate = function (timeseries,index)
        local facing = timeseries.facing.data[index]
        local roll = timeseries.roll.data[index]
        local pitch = timeseries.pitch.data[index]
        return {facing,roll,pitch}
    end

    local keys = {"facing","roll","pitch"}
    if itemStack.id == 10062 then
        for k,v in pairs(keys) do
            if (timeseries1[v] and not timeseries2[v]) or (not timeseries1[v] and timeseries2[v]) then
                return false,compare_data
            end	
            if (timeseries1[v] and timeseries2[v]) then
                local myCnf = timeseries1[v].data
                local otherCnf = timeseries2[v].data
                local num = #myCnf
                for i=1,num do
                    local fDis = myCnf[i] - otherCnf[i]
                    if math.abs(fDis)*180/math.pi > 3 then
                        compare_data.compare_key = "actor_"..v
                        compare_data.compare_dis = fDis*180/math.pi
                        compare_data.compare_idx = i
                        compare_data.my_rotate = getRotate(timeseries1,i)
                        compare_data.compare_rotate = getRotate(timeseries2,i)
                        return false,compare_data
                    end							
                end	
            end	
        end							
    end	
	return true,compare_data
end

function MovieClipCompare.CompareActorHead(timeseries1,timeseries2,itemStack) 
	local compare_data = {}
	compare_data.compare_type = "movie_actor_head"
	if (timeseries1 and not timeseries2) or (not timeseries1 and timeseries2)  then
        return false,compare_data				
    end
    local keys = {"HeadUpdownAngle","HeadTurningAngle"}
    if itemStack.id == 10062 then
        for k,v in pairs(keys) do
            if (timeseries1[v] and not timeseries2[v]) or (not timeseries1[v] and timeseries2[v]) then
                return false,compare_data
            end	
            if (timeseries1[v] and timeseries2[v]) then
                local myCnf = timeseries1[v].data
                local otherCnf = timeseries2[v].data
                local num = #myCnf
                for i=1,num do
                    local rotDis = myCnf[i] - otherCnf[i]
                    rotDis = rotDis*180/math.pi
                    if math.abs(rotDis) > 35 then
                        compare_data.compare_dis = rotDis
                        compare_data.compare_idx = i
                        compare_data.compare_key = v
                        compare_data.my_rot = myCnf[i]
                        compare_data.compare_rot = otherCnf[i]
                        return false,compare_data
                    end							
                end	
            end	
        end							
    end	
	return true,compare_data
end


function MovieClipCompare.CompareActorSpeed(timeseries1,timeseries2,itemStack) 
	local compare_data = {}
	compare_data.compare_type = "movie_actor_speed"
	if (timeseries1 and not timeseries2) or (not timeseries1 and timeseries2)  then
        return false,compare_data				
    end
    if itemStack.id == 10062 then
        if (timeseries1.speedscale and not timeseries2.speedscale) or (not timeseries1.speedscale and timeseries2.speedscale) then
            return false,compare_data
        end	
        if (timeseries1.speedscale and timeseries2.speedscale) then
            local myCnf = timeseries1.speedscale.data
            local otherCnf = timeseries2.speedscale.data
            local num = #myCnf
            for i=1,num do
                if myCnf[i] ~= otherCnf[i] then
                    compare_data.my_speed = myCnf[i]
                    compare_data.compare_speed = otherCnf[i]
                    compare_data.compare_idx = i
                    return false,compare_data
                end							
            end
        end								
    end		
	return true,compare_data
end

function MovieClipCompare.CompareActorModel(timeseries1,timeseries2,itemStack) 
	local compare_data = {}
	compare_data.compare_type = "movie_actor_model"
	if (timeseries1 and not timeseries2) or (not timeseries1 and timeseries2)  then
        return false,compare_data				
    end
    if itemStack.id == 10062 then
        if (timeseries1.assetfile and not timeseries2.assetfile) or (not timeseries1.assetfile and timeseries2.assetfile) then
            return false,compare_data
        end	
        if (timeseries1.assetfile and timeseries2.assetfile) then
            local myCnf = timeseries1.assetfile.data
            local otherCnf = timeseries2.assetfile.data
            local num = #myCnf
            for i=1,num do
                if myCnf[i] ~= otherCnf[i] then
                    compare_data.my_assetfile = myCnf[i]
                    compare_data.compare_assetfile = otherCnf[i]
                    compare_data.compare_idx = i
                    return false,compare_data
                end							
            end	
        end								
    end
	return true,compare_data
end

function MovieClipCompare.CompareActorSkin(timeseries1,timeseries2,itemStack) 
	local compare_data = {}
	compare_data.compare_type = "movie_actor_skin"
	if (timeseries1 and not timeseries2) or (not timeseries1 and timeseries2)  then
        return false,compare_data				
    end
    if itemStack.id == 10062 then
        if (timeseries1.skin and not timeseries2.skin) or (not timeseries1.skin and timeseries2.skin) then
            return false,compare_data
        end	
        if (timeseries1.skin and timeseries2.skin) then
            local myCnf = timeseries1.skin.data
            local otherCnf = timeseries2.skin.data
            local num = #myCnf
            for i=1,num do
                if myCnf[i] ~= otherCnf[i] then
                    compare_data.my_skin = myCnf[i]
                    compare_data.compare_skin = otherCnf[i]
                    compare_data.compare_idx = i
                    return false,compare_data
                end							
            end	
        end								
    end
	return true,compare_data
end

function MovieClipCompare.CompareActorOpcatity(timeseries1,timeseries2,itemStack) 
	local compare_data = {}
	compare_data.compare_type = "movie_actor_opcatity"
	if (timeseries1 and not timeseries2) or (not timeseries1 and timeseries2)  then
        return false,compare_data				
    end
    if itemStack.id == 10062 then
        if (timeseries1.opacity and not timeseries2.opacity) or (not timeseries1.opacity and timeseries2.opacity) then
            return false,compare_data
        end	
        if (timeseries1.opacity and timeseries2.opacity) then
            local myCnf = timeseries1.opacity.data
            local otherCnf = timeseries2.opacity.data
            local num = #myCnf
            for i=1,num do
                if myCnf[i] ~= otherCnf[i] then
                    compare_data.my_opcatity = myCnf[i]
                    compare_data.compare_opcatity =otherCnf[i] 
                    compare_data.compare_idx = i
                    return false,compare_data
                end
            end	
        end								
    end
	return true
end

function MovieClipCompare.CompareActorName(timeseries1,timeseries2,itemStack) 
	local compare_data = {}
	compare_data.compare_type = "movie_actor_name"
	if (timeseries1 and not timeseries2) or (not timeseries1 and timeseries2)  then
        return false,compare_data				
    end
    if itemStack.id == 10062 then
        if (timeseries1.name and not timeseries2.name) or (not timeseries1.name and timeseries2.name) then
            return false,compare_data
        end	
        if (timeseries1.name and timeseries2.name) then
            local myCnf = timeseries1.name.data
            local otherCnf = timeseries2.name.data
            local num = #myCnf
            for i=1,num do
                if myCnf[i] ~= otherCnf[i] then
                    compare_data.my_name = myCnf[i]
                    compare_data.compare_name =otherCnf[i] 
                    compare_data.compare_idx = i
                    return false,compare_data
                end							
            end	
        end								
    end	
	return true,compare_data
end

function MovieClipCompare.CompareActorParent(timeseries1,timeseries2,itemStack) 
	local compare_data = {}
	compare_data.compare_type = "movie_actor_parent"
	if (timeseries1 and not timeseries2) or (not timeseries1 and timeseries2)  then
        return false,compare_data				
    end
    if itemStack.id == 10062 then
        if (timeseries1.parent and not timeseries2.parent) or (not timeseries1.parent and timeseries2.parent) then
            return false,compare_data
        end	
        if (timeseries1.parent and timeseries2.parent) then
            local myCnf = timeseries1.parent.data
            local otherCnf = timeseries2.parent.data
            if #myCnf ~= #otherCnf then
                return false
            else
                local num = #myCnf
                local isSame = true
                local isSame = true
                for i=1,num do
                    compare_data.compare_idx = i
                    if myCnf[i].target ~= otherCnf[i].target then
                        isSame = false
                        compare_data.compare_key = "target"
                    end
                    if isSame and  (math.abs(myCnf[i].rot[1]*180/math.pi - otherCnf[i].rot[1]*180/math.pi) > 35 
                        or math.abs(myCnf[i].rot[2]*180/math.pi - otherCnf[i].rot[2]*180/math.pi) > 35  
                        or math.abs(myCnf[i].rot[3]*180/math.pi - otherCnf[i].rot[3]*180/math.pi) > 35) then
                            compare_data.compare_key = "rot"
                            isSame = false
                    end
                    if isSame and  (math.abs(myCnf[i].pos[1] - otherCnf[i].pos[1]) > 3 
                        or math.abs(myCnf[i].pos[2] - otherCnf[i].pos[2]) > 3  
                        or math.abs(myCnf[i].pos[3] - otherCnf[i].pos[3]) > 3) then
                            compare_data.compare_key = "pos"
                            isSame = false
                    end
                    if not isSame then
                        compare_data.my_target = myCnf[i].target
                        compare_data.compare_target = myCnf[i].target
                        compare_data.my_rot = myCnf[i].rot
                        compare_data.compare_rot = myCnf[i].rot
                        compare_data.my_pos = myCnf[i].pos
                        compare_data.compare_pos = myCnf[i].pos
                        return false,compare_data
                    end
                end
            end
        end								
    end	
	return true,compare_data
end

--这个暂时不用，课程还没有涉及到
function MovieClipCompare.CompareActorBones(entitySrc,entityDst) 
	if not entitySrc or not entityDst then
		return false
	end
	for i=1, entitySrc.inventory:GetSlotCount() do
		local itemStack = entitySrc.inventory:GetItem(i);
		local itemStack2 = entityDst.inventory:GetItem(i)
		if(itemStack and itemStack.count > 0 and itemStack.serverdata) and (itemStack2 and itemStack2.count > 0 and itemStack2.serverdata) then
			local timeseries1 = itemStack.serverdata.timeseries
			local timeseries2 = itemStack2.serverdata.timeseries
			if not timeseries1 or not timeseries2  then
				return false				
			end
			if itemStack.id == 10062 then
				if (timeseries1.bones and not timeseries2.bones) or (not timeseries1.bones and timeseries2.bones) then
					return false
				end	
				if (timeseries1.bones and timeseries2.bones) then
					local myCnf = timeseries1.bones
					local otherCnf = timeseries2.bones
					local keys = {}
					for k,v in pairs(myCnf) do
						if not otherCnf[k] then
							return false						
						end
						keys[#keys] = k
					end
					local num = #keys
					for i=1,num do
						local curKey = keys[i]
						local myBoneDts = myCnf[curKey].data
						local otherBoneDts = otherCnf[curKey].data
						if string.find(curKey,"rot") then
							NPL.load("(gl)script/ide/math/Quaternion.lua");
							local Quaternion = commonlib.gettable("mathlib.Quaternion");
							local temp1,temp2,temp3 = Quaternion:new(myBoneDts):ToEulerAngles()
							myBoneDts = {temp1,temp2,temp3 }
							temp1,temp2,temp3 = Quaternion:new(otherBoneDts):ToEulerAngles()
							otherBoneDts = {temp1,temp2,temp3}
							local dataNum = #myBoneDts
							for dataIndex = 1,dataNum do 
								local rotDis = myBoneDts[dataIndex] - otherBoneDts[dataIndex]
								rotDis = rotDis * 180 /math.pi
								if rotDis > 35 or rotDis < -35 then
									return false
								end
							end
						end
					end
				end				
			end		
		end
	end
	return true
end
