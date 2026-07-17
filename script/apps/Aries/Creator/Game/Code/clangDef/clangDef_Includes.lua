--[[
Title: Block Pen
Author(s): LiXizhi
Date: 2020/2/16
Desc: 
use the lib:
-------------------------------------------------------
-------------------------------------------------------
]]
NPL.export({
-- Operators
{
	type = "include_stdio", 
	message0 = L"引用头文件%1",
	arg0 = {
		{
			name = "filename",
			type = "input_value",
            shadow = { type = "text", value = "stdio.h",},
			text = "stdio.h", 
		},
	},
	category = "CommandIncludes", 
	helpUrl = "", 
	canRun = false,
	funcName = "include",
	previousStatement = true,
	nextStatement = true,
	func_description = '#include %s',
	ToNPL = function(self)
		return string.format('#include <%s>\n', self:getFieldAsString('filename'));
	end,
	examples = {{desc = "", canRun = true, code = [[
#include <stdio.h>
int main() {
	printf("hello world");
	return 0;
}
]]}},
},


{
	type = "main_function", 
	message0 = L"主函数",
	message1 = L"%1",
	arg1 = {
		{
			name = "input",
			type = "input_statement",
		},
	},
	category = "CommandIncludes", 
	helpUrl = "", 
	canRun = false,
	funcName = "main", 
	previousStatement = true,
	nextStatement = true,
	func_description = 'int main(){\\n%s\\n}',
	ToNPL = function(self)
		return string.format('int main(){\n    %s\n}\n', self:getFieldAsString('input'));
	end,
	examples = {{desc = "", canRun = true, code = [[
#include <stdio.h>
int main() {
	printf("hello world");
	return 0;
}
]]}},
},

});