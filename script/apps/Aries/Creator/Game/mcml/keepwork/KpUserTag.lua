--[[
Title: icon tag for user
Author(s): leio
Date: 2020/8/10
Desc:  
Use Lib:
-------------------------------------------------------
local KpUserTag = NPL.load("(gl)script/apps/Aries/Creator/Game/mcml/keepwork/KpUserTag.lua");
--]]
local KpUserTag = NPL.export();

function KpUserTag.Is_crown(user_info)
    return user_info.vip == 1;
end
function KpUserTag.Is_student(user_info)
    return user_info.student == 1;
end
function KpUserTag.Is_teacher(user_info)
    return user_info.tLevel == 1;
end

function KpUserTag.GetMcml(user_info)
    if(not user_info)then
        return
    end
    local s = "";
    local crown_tag = "";
    local s_tag = "";
    local t_tag = "";
    if(KpUserTag.Is_crown(user_info))then
        crown_tag =  [[
        <div style="float:left" >
            <img tooltip="<%=L('Paracraft 会员')%>" style="width:18px;height:18px;background:url(Texture/Aries/Creator/keepwork/UserInfo/crown_32bits.png#0 0 18 18)"/>
        </div>
        ]]
    end
    if(KpUserTag.Is_student(user_info))then
        s_tag =  [[
        <div style="float:left;margin-left:2px;">
            <img tooltip="<%=L('合作机构vip学员')%>" style="width:18px;height:18px;background:url(Texture/Aries/Creator/keepwork/UserInfo/V_32bits.png#0 0 18 18)"/>
        </div>
        ]]
    end
    if(KpUserTag.Is_teacher(user_info))then
        t_tag =  [[
        <div style="float:left;margin-left:2px;">
            <img tooltip="<%=L('合作机构vip教师')%>" style="width:18px;height:18px;background:url(Texture/Aries/Creator/keepwork/UserInfo/blue_v_32bits.png#0 0 18 18)"/>
        </div>
        ]]
        s_tag = "";
    end
    s = string.format("%s%s%s",crown_tag,s_tag,t_tag);
    return s;
end
