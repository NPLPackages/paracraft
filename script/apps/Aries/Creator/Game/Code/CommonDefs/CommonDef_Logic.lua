--[[
Title: CommonDef_Logic
Author(s): leio
Date: 2020/12/14
Desc: 
use the lib:
-------------------------------------------------------
local CommonDef_Logic = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CommonDefs/CommonDef_Logic.lua");
-------------------------------------------------------
]]
NPL.export({

{
	type = "control_if", 
	message0 = L"如果%1那么",
	message1 = L"%1",
	arg0 = {
		{
			name = "expression",
			type = "input_value",
		},
    },
    arg1 = {
		{
			name = "input_true",
			type = "input_statement",
			text = "", 
		},
	},
	category = "Logic", 
	helpUrl = "", 
	canRun = false,
	funcName = "if",
	previousStatement = true,
	nextStatement = true,
	func_description = 'if (%s) then\\n%send',
	func_description_js = 'if (%s) {\\n%s}',
	ToPython = function(self)
		local input = self:getFieldAsString('input_true')
		if input == '' then
			input = 'pass'
		end
		return string.format('if %s:\n    %s\n', self:getFieldAsString('expression'), input);
	end,
	ToNPL = function(self)
		return string.format('if(%s) then\n    %s\nend\n', self:getFieldAsString('expression'), self:getFieldAsString('input_true'));
	end,
	examples = {{desc = "", canRun = true, code = [[

]]}},
},

{
	type = "if_else", 
	message0 = L"如果%1那么",
	message1 = L"%1",
	message2 = L"否则",
	message3 = L"%1",
	arg0 = {
		{
			name = "expression",
			type = "input_value",
		},
    },
    arg1 = {
		{
			name = "input_true",
			type = "input_statement",
			text = "", 
		},
	},
    arg3 = {
		{
			name = "input_else",
			type = "input_statement",
			text = "", 
		},
	},
	category = "Logic", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	func_description = 'if (%s) then\\n%selse\\n%send',
	func_description_js = 'if (%s) {\\n%s} else {\\n%s}',
	ToPython = function(self)
		local input_true = self:getFieldAsString('input_true')
		local input_else = self:getFieldAsString('input_else')
		if input_true == '' then
			input_true = 'pass'
		end
		if input_else == '' then
			input_else = 'pass'
		end
		return string.format('if %s:\n    %s\nelse:\n    %s\n', self:getFieldAsString('expression'), input_true, input_else);
	end,
	ToNPL = function(self)
		return string.format('if(%s) then\n    %s\nelse\n    %s\nend\n', self:getFieldAsString('expression'), self:getFieldAsString('input_true'), self:getFieldAsString('input_else'));
	end,
	examples = {{desc = "", canRun = true, code = [[
while(true) do
    if(distanceTo("mouse-pointer")<3) then
        say("mouse-pointer")
    else
        say("")
    end
    wait(0.01)
end
]]}},
},

})
