--[[
Title: Cpp main functions
Author(s): LiXizhi
Date: 2023/8/2
Desc: Display and more
use the lib:
-------------------------------------------------------
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Core/Color.lua");
local Color = commonlib.gettable("System.Core.Color");

NPL.export({

{
	type = "cpp.main", 
	message0 = L"main函数",
	message1 = L"%1",
	arg1 = {
		{
			name = "input",
			type = "input_statement",
			text = "",
		},
	},
	category = "common", 
	helpUrl = "", 
	canRun = false,
	funcName = "cpp.main",
	previousStatement = true,
	nextStatement = true,
	func_description = 'int main(){\\n%s}',
	ToNPL = function(self)
		local input = self:getFieldAsString('input')
		return string.format('int main(){\n%s}\n', input);
	end,
	ToCpp = function(self)
		local input = self:getFieldAsString('input')
		local block_indent = self:GetIndent();
		return string.format('int main(){\n%s\n}\n', input);
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
	},

});