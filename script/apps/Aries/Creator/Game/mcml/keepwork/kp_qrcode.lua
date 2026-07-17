NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/QREncode.lua");
local QREncode = commonlib.gettable("MyCompany.Aries.Game.Movie.QREncode");
local kp_qrcode = commonlib.gettable("MyCompany.Aries.Game.mcml.kp_qrcode");

function kp_qrcode.render_callback(mcmlNode, rootName, bindingContext, _parent, left, top, right, bottom, myLayout, css)
    kp_qrcode.create_default(rootName, mcmlNode, bindingContext, _parent, left, top, right, bottom, myLayout, css);
    return true, true, true;
end

function kp_qrcode.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
    return mcmlNode:DrawDisplayBlock(rootName, bindingContext, _parent, left, top, width, height, parentLayout, style, kp_qrcode.render_callback);
end

function kp_qrcode.create_default(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, parentLayout,css)
    local uiname = mcmlNode:GetAttributeWithCode("uiname", nil, true)
    
    local value = mcmlNode:GetAttributeWithCode("value", "", true)


    local min_width = 20
    local min_height = 20
    local w = mcmlNode:GetNumber("width") or (width-left);
    if css.width then
        w = css.width
    end
    local color = css.color or "#000000ff"
    local default_height = mcmlNode:GetNumber("height")
    local h = default_height or (height-top);
    if css.height then
        h = css.height
    end

    h = math.max(h, min_height)
    w = math.max(w, min_width)

    local qrcode_container_name = uiname or "qrcode_container"
    local qrcode_container = ParaUI.GetUIObject("qrcode_container_name")
    if qrcode_container:IsValid() then
        ParaUI.DestroyUIObject(qrcode_container)
    end

    local ret,qrcode_value = QREncode.qrcode(value) 
    qrcode_value = qrcode_value or {}

    local size = ret == true and #qrcode_value or 1
    local qrcode_width = w
    local qrcode_height = h
    local block_size = qrcode_width / size
    
    local _this = ParaUI.CreateUIObject("container", qrcode_container_name, "_lt", left, top, w, h);
	_this.background = css.background or "";
	_parent:AddChild(_this);
    mcmlNode:SetObjId(_this.id);
    _this:SetField("OwnerDraw", true); -- enable owner draw paint event
    _this:SetField("SelfPaint", true);
    _this:SetScript("ondraw", function()
        for i = 1, #(qrcode_value) do
            for j = 1, #(qrcode_value[i]) do
                local code = qrcode_value[i][j];
                if (code < 0) then
                    ParaPainter.SetPen(color);
                    ParaPainter.DrawRect((i-1) * block_size, (j-1) * block_size, block_size, block_size);
                end
            end
        end
    end);
end

