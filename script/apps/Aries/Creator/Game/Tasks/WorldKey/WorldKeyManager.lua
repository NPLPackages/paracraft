--[[
Title: WorldKeyManager
Author(s): yangguiyi
Date: 2021/4/28
Desc:  
Use Lib:
-------------------------------------------------------
local WorldKeyManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/WorldKey/WorldKeyManager.lua")
--]]
local KeepworkServiceProject = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/Project.lua")
local WorldKeyManager = NPL.export();

function WorldKeyManager.GenerateActivationCodes(count, private_key, projectId, filename, folder_path, succee_cb)
    count = count or 5
    projectId = tonumber(projectId)
    
    private_key = WorldKeyManager.GetCurrentSearchKey(private_key)


    local key_list = ""
    for i = 1, count do
        local key = WorldKeyManager.EncodeKeys(private_key, projectId, mathlib.bit.band(math.random(10, 9999) + os.time(), 0xff))
        key_list = key_list .. key .. "\n"
    end

    local filename = filename .. ".txt"
    filename = commonlib.Encoding.Utf8ToDefault(filename)
    local file_path = string.format("%s/%s", folder_path, filename)
	ParaIO.CreateDirectory(file_path)
	local file = ParaIO.open(file_path, "w");

	if(file) then
		file:write(key_list, #key_list);
		file:close();
	end
    -- local path = string.gsub(folder_path, "/", "\\")
    if succee_cb then
        succee_cb(string.gsub(file_path, "/", "\\"))
    end
    
end

function WorldKeyManager.EncodeKeys(nKey1, nKey2, nKey3)
    nKey2 = mathlib.bit.band(0xffffff, nKey2)
    nKey3 = mathlib.bit.band(0xff, nKey3)
    -- print("cccccccccccc", mathlib.bit.band(0xffffff, 100), mathlib.bit.band(math.random(1, 1000), 0xff))
    local part1 = WorldKeyManager.SYMETRIC_ENCODE_32_BY_8(nKey1, nKey3)
    local part2 = mathlib.bit.lshift(WorldKeyManager.SYMETRIC_ENCODE_32_BY_8(nKey2, nKey3), 8)
    part2 = part2 + nKey3
    local num_a = mathlib.bit.rshift(part1, 16)
    local num_b = mathlib.bit.band(part1, 0xffff)
    local num_c = mathlib.bit.rshift(part2, 16)
    local num_d = mathlib.bit.band(part2, 0xffff)

    return string.format("%sx-%sx-%sx-%sx", num_a, num_b, num_c, num_d)
end

function WorldKeyManager.DecodeKeys(sActivationCode)
    local parts = commonlib.split(sActivationCode,"x-");
    if #parts ~= 4 then
        return "", ""
    end
    if string.find(sActivationCode, "xx") then
        return "", ""
    end
	local nKey3 = mathlib.bit.band(0xff, parts[4])
	local nKey1 = mathlib.bit.lshift(parts[1], 16)+parts[2];
	nKey1 = WorldKeyManager.SYMETRIC_ENCODE_32_BY_8(nKey1, nKey3);
	local nKey2 = mathlib.bit.lshift(parts[3], 8)+mathlib.bit.rshift(parts[4], 8);
	nKey2 = mathlib.bit.band(WorldKeyManager.SYMETRIC_ENCODE_32_BY_8(nKey2, nKey3), 0x00ffffff);

    return nKey1, nKey2
end

function WorldKeyManager.SYMETRIC_ENCODE_32_BY_8(a, k)
    
    local encode_a = mathlib.bit.band(mathlib.bit.bxor(a, (mathlib.bit.lshift(k, 24))), 0xff000000)
    local encode_b = mathlib.bit.band(mathlib.bit.bxor(a, (mathlib.bit.lshift(k, 16))), 0x00ff0000)
    local encode_c = mathlib.bit.band(mathlib.bit.bxor(a, (mathlib.bit.lshift(k, 8))), 0x0000ff00)
    local encode_d = mathlib.bit.band(mathlib.bit.bxor(a, k), 0x000000ff)


    -- local encode_b = mathlib.bit.band((a^(mathlib.bit.lshift(k, 16))), 0x00ff0000)
    -- local encode_c = mathlib.bit.band((a^(mathlib.bit.lshift(k, 8)))), 0x0000ff00)
    -- local encode_d = mathlib.bit.band((a^(mathlib.bit.lshift(k)))), 0x000000ff)
    return  encode_a + encode_b + encode_c + encode_d
end

function WorldKeyManager.CharToBase64(byte)
    local n = 0
    if byte >= string.byte('0') and byte <= string.byte('9') then
        n=byte - string.byte('0')
    elseif byte>= string.byte('a') and byte <= string.byte('z') then
        n=10+byte - string.byte('a')
    elseif byte >= string.byte('A') and byte <= string.byte('Z') then
        n=36+byte - string.byte('A')
    elseif byte == string.byte('.') then
        n=63;
    end

    return n
end

function WorldKeyManager.Base64ToChar(num)
    local char = ""
    if num < 10 then
        char = string.char(string.byte('0') + num)
    elseif num < 36 then
        char = string.char(string.byte('a') + num)
    elseif num < 62 then
        char = string.char(string.byte('A') + num)
    else
        char = '.'
    end

    return char
end

function WorldKeyManager.isValidActivationCode(code, world_data)
    

    local params = world_data or {}
    local name = params.username or "" 
    local project_id = params.id
    local extra = params.extra or {}
    local world_encodekey_data = extra.world_encodekey_data or {}
    local invalid_key_list = world_encodekey_data.invalid_key_list or {}
    if invalid_key_list[code] then
        return false
    end

    local part1, part2 = WorldKeyManager.DecodeKeys(code)
    if part2 == project_id and part1 == WorldKeyManager.GetCurrentSearchKey(name) then
        local decode_world_list = GameLogic.GetPlayerController():LoadRemoteData("WorldKeyManager.DecodeWorldList", {});
        decode_world_list[project_id] = 1
        GameLogic.GetPlayerController():SaveRemoteData("WorldKeyManager.DecodeWorldList", decode_world_list)
        return true
    end
   
    return false
end

function WorldKeyManager.GetCurrentSearchKey(serach_key)
    local key_num = 0
    for index = 1, #serach_key do
        key_num = mathlib.bit.lshift(key_num, 6) + WorldKeyManager.CharToBase64(string.byte(serach_key, index))
    end
    
    return key_num
end

function WorldKeyManager.DecodeSearchKey(key_num)
    local str = ""
    while (key_num > 0) do
        local rshift = mathlib.bit.rshift(key_num, 6)
        local byte = key_num - rshift
        -- print("bbbb", key_num , rshift)
        local char = WorldKeyManager.Base64ToChar(byte)

        str = char .. str
        key_num = rshift
    end

    
end

function WorldKeyManager.HasActivate(project_id)
    if GameLogic.IsVip() then
        return true
    end

    local DecodeWorldList = GameLogic.GetPlayerController():LoadRemoteData("WorldKeyManager.DecodeWorldList", {});
    if DecodeWorldList[project_id] then
        return true
    end
end

function WorldKeyManager.OnclickNpc(project_id)
    if project_id == nil then
        return
    end
    
    local KeepworkServiceProject = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/Project.lua")
    KeepworkServiceProject:GetProject(project_id, function(data, err)
        if type(data) == 'table' then
            if data.username == System.User.username then
                NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/WorldKey/WorldKeyEncodePage.lua").Show(project_id);
            else
                local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager")
                CommandManager:RunCommand(string.format('/loadworld -force -s %s', project_id))
            end
        end
    end)
end

function WorldKeyManager.AddInvalidKey(key, world_data, succee_cb)
    if not WorldKeyManager.isValidActivationCode(key, world_data) then
        GameLogic.AddBBS(nil, L"无效激活码，不需要注销", 3000, "255 0 0")
        return
    end

    local params = world_data or {}
    local extra = params.extra or {}
    params.extra = extra

    local world_encodekey_data = params.extra.world_encodekey_data or {}
    extra.world_encodekey_data = world_encodekey_data
    if world_encodekey_data.invalid_key_list == nil then
        world_encodekey_data.invalid_key_list = {}
    end

    if world_encodekey_data.invalid_key_list[key] then
        GameLogic.AddBBS(nil, L"无效激活码，不需要注销", 3000, "255 0 0")
        return
    end
    
    world_encodekey_data.invalid_key_list[key] = 1

    local projectId = world_data.id
    if projectId == nil then
        return
    end

    KeepworkServiceProject:UpdateProject(projectId, params, function(data, err)
        if err == 200 then
            GameLogic.AddBBS(nil, L"注销成功", 3000, "0 255 0")
            if succee_cb then
                succee_cb()
            end
        end
    end)
end