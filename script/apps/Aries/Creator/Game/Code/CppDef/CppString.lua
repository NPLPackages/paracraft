NPL.load("(gl)script/ide/commonlib.lua");

local CppIterator = NPL.load("./CppIterator.lua");
local CppString = NPL.export();

local CppStringIterator = commonlib.inherit(CppIterator);

CppStringIterator.__add = function(self, offset)
    return CppStringIterator:new():init(self.m_cpp_string, self.m_index + offset);
end

CppStringIterator.__eq = function(self, other)
    return self.m_cpp_string == other.m_cpp_string and self.m_index == other.m_index;
end

function CppStringIterator:ctor()
    self.m_cpp_string = nil;
    self.m_index = 0;
end

function CppStringIterator:init(cpp_string, index)
    self.m_cpp_string = cpp_string;
    self.m_index = index or 0;
end

function CppStringIterator:get()
    return self.m_cpp_string:at(self.m_index);
end

function CppStringIterator:set(value)
    self.m_cpp_string.m_lua_string[self.m_index + 1] = value;
end

function CppString:new(lua_string)
    return setmetatable({}, {__index = CppString});
end

function CppString:init(lua_string)
    self.m_lua_string = lua_string or "";
end

function CppString:size()
    return #(self.m_lua_string);
end

function CppString:length()
    return self:size();
end

function CppString:at(index)
    return self.m_lua_string:sub(index + 1, index + 1);
end

function CppString:begin()
    return CppStringIterator:new():init(self);
end

function CppString:end()
    return CppStringIterator:new():init(self, self:size());
end
