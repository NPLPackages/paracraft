local CppString = NPL.load("./CppString.lua");
local CppStd = NPL.export();

CppStd.INT_MIN = (-2147483647 - 1);
CppStd.INT_MAX = 2147483647;
CppStd.sqrt = math.sqrt;

function default_compare(a, b)
    if (a < b) then
        return true;
    else
        return false;
    end
end

function CppStd.sort(start_it, end_it, comp)
    comp = comp or default_compare;

    local i = start_it;
    while (i ~= end_it) do
    end 
end

function CppStd.CppString(str)
    return CppString:new():init(str);
end
