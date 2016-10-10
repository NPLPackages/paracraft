--[[
Title: UI Template and place holder tags
Author(s): LiXizhi
Date: 2010/8/28
Desc: We use these tags to create UI template within mcml, so that frequently used UI components 
can be written in a template file. Many other mcml files can reference the same template file. 
The most common usage is the NPC dialog page, where data and logics are written in many mcml files, 
which reference just a few UI template file, thus, removing duplicated code and making changing UI layout and theme easier. 

see examples in "script/kids/3DMapSystemApp/mcml/test/test_pe_template[_templ].html"

---++ pe:template
This tag will insert another(template) mcml page in place of the containing mcml page. 
The child nodes of pe:template can be pe:placeholder, which allows us to replace 
elements or their attributes in the including page with those in the containing page. 

In the included template page, the designer should mark replaceable regions using the tag pe:template-block,
each pe:templage-block has a unique id, when should match the same pe:placeholder id in the containing page. 

The page parsing order is like this: 
the parent page parses the page as normal until it matches a pe:template. 
the pe:template then immediately parses the included template page, it will add the pe:mcml tag in the template page
as the last child of pe:template in the parent page. So the template page parsing continues until it meets a 
pe:template-block. pe:template-block will search its parent for the first pe:template and look for 
a child pe:placeholder node with the same id. 

If no matching pe:placeholder is found, the pe:templace-block will be skipped during rendering

If pe:placeholder's source is {this}, it will transfer attributes of the placeholder to all 
child nodes of pe:template-block and continue rendering. 

If pe:placeholder has a source_node field, it will transfer all attributes of pe:template-block 
to the source_node, and use the source_node for rendering. It will also render all child nodes of 
pe:template-block after the source_node is rendered. 

If pe:placeholder do not have a source_node field, the pe:template-block will be skipped from rendering. 

Now the trick thing is how and when source_node field is assigned to the pe:placeholder node. 
This can be a magic of the implementation of other mcml tags that is aware of pe:template. 
For example, pe:dialog will assign the current pe:state node as the source_node on the pe:placeholder whose 
source attribute is "pe:state"; whereas the pe:answer node will assign the itself to the 
source_node of pe:placeholder whose id is the same as the template_id attribute. 

Attributes:

| Required | Name | Type | Description |
| required | filename | string | the template file name, it may contain request params like "abc.html?name=value" |

---+++ Examples
<verbatim>
<pe:mcml>
<script type="text/npl" ></script>
<pe:dialog NPC_id = '0' >
    <pe:template filename="script/kids/3DMapSystemApp/mcml/test/test_pe_template_templ.html">
        <pe:placeholder id="portrait" source="{this}" nid='30132' name='NoName'></pe:placeholder>
        <pe:placeholder id="content" source="{pe:state}"></pe:placeholder>
        <pe:placeholder id="button1"></pe:placeholder>
        <pe:placeholder id="exit"></pe:placeholder>
    </pe:template>
    <pe:state id = "0">
		<pe:answer autoexec = "true">
			<pe:answer-if condition = 'true' target_state = "1"/>
		</pe:answer>
	</pe:state>
    <pe:state id = "1">
        this is state 1
        <pe:answer text="Go to 2" template_id="button1">
			<pe:answer-if condition = 'true' target_state = "2"/>
		</pe:answer>
        <pe:answer text="exit" template_id="exit">
			<pe:answer-if condition = 'true' target_state = "-1"/>
		</pe:answer>
    </pe:state>
    <pe:state id = "2">
        this is state 2
        <pe:answer text="Go to 1" template_id="button1">
			<pe:answer-if condition = 'true' target_state = "1"/>
		</pe:answer>
        <pe:answer text="exit" template_id="exit">
			<pe:answer-if condition = 'true' target_state = "-1"/>
		</pe:answer>
    </pe:state>
</pe:dialog>
</pe:mcml>
</verbatim>

---++ pe:placeholder
A tag used for describing how content of pe:template-block should be replaced by content in the containing page. 

Attributes:
| Required | Name | Type | Description |
| required | id | string| |
| optional | source | string| if this is "{this}", attributes of this node will be transferred to template block child nodes. otherwise it can be a node path in current dom.|

---++ pe:template-block
A tag used for marking a place in the template file to be replaced by pe:placeholder in the containing page.

Attributes:
| Required | Name | Type | Description |
| required | id | string | |

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_template.lua");
-------------------------------------------------------
]]
if(not Map3DSystem.mcml_controls) then Map3DSystem.mcml_controls = {}; end

----------------------------------------------------------------------
-- pe:template: handles MCML tag <pe:template>
----------------------------------------------------------------------
local pe_template = commonlib.gettable("Map3DSystem.mcml_controls.pe_template");
function pe_template.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local filename = mcmlNode:GetAttributeWithCode("filename", nil, true);
	if(not filename) then
		return;
	end
	local url = filename;

	local template_root = mcmlNode:GetChild("pe:mcml");
	if(template_root and template_root.url__ ~= url) then
		template_root:Detach();
		template_root = nil;
	end
	-- no need to recreate it if we have created it before
	if(not template_root) then
		-- TODO: find a way to cache frequently used template file to avoid reparsing it. 
		local params = System.localserver.UrlHelper.url_getparams_table(url);
		if(params) then
			-- merge request params if any. 
			local params_parent = mcmlNode:GetPageCtrl():GetRequestParam();
			commonlib.partialcopy(params_parent, params);
		end
		filename = string.gsub(url, "%?.*$", "")

		local xmlRoot = ParaXML.LuaXML_ParseFile(filename);
		if(type(xmlRoot)=="table" and #(xmlRoot)>0) then
			xmlRoot = Map3DSystem.mcml.buildclass(xmlRoot);
			template_root = commonlib.XPath.selectNode(xmlRoot, "//pe:mcml");
			if(template_root) then
				template_root.url__ = url;
				-- add the loaded template file as the last child of pe:template. 
				mcmlNode:AddChild(template_root)
			end
		end
	end
	if(template_root) then
		Map3DSystem.mcml_controls.create(rootName, template_root, bindingContext, _parent, left, top, width, height, nil, parentLayout);
	end
end

----------------------------------------------------------------------
-- pe:template_block: handles MCML tag <pe:template-block>
----------------------------------------------------------------------
local pe_template_block = commonlib.gettable("Map3DSystem.mcml_controls.pe_template_block");
function pe_template_block.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local templateNode = mcmlNode:GetParent("pe:template");
	if(not templateNode) then
		LOG.std("", "warn", "MCML", "template block parent is not found");
		return;
	end
	local id = mcmlNode:GetAttributeWithCode("id");
	local placeholderNode = templateNode:SearchChildByAttribute("id", id);
	if(placeholderNode) then
		local source = placeholderNode:GetAttribute("source");
		
		if(source == "{this}") then
			-- transfer attribute from placeholder to all child nodes of template-block. 
			local childNode;
			for childNode in mcmlNode:next() do
				if(type(childNode) == "table") then
					local name, value;
					for name, value in pairs(placeholderNode.attr) do
						if(name ~= "id" and name~="source") then
							childNode.attr[name] = value;
						end
					end
				end
			end
			Map3DSystem.mcml_controls.pe_simple_styles.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout);
		else
			-- replace the entire node in the template file with the given node in the current file. 
			if(placeholderNode.source_node) then
				-- render using source node
				placeholderNode.source_node.use_template = true;

				-- copy attributes on the template block to the source node. Template attribute will overwrite source attribute. 
				local name, value;
				for name, value in pairs(mcmlNode.attr) do
					if(name ~= "id") then
						placeholderNode.source_node.attr[name] = value;
					end
				end
				-- render using source_node
				Map3DSystem.mcml_controls.create(rootName, placeholderNode.source_node, bindingContext, _parent, left, top, width, height, style, parentLayout);
				-- tricky: clear the source_node, so that it will be rebind the next time page is refreshed. 
				placeholderNode.source_node = nil;

				-- render child nodes if any
				local childnode;
				for childnode in mcmlNode:next() do
					Map3DSystem.mcml_controls.create(rootName, childnode, bindingContext, _parent, left, top, width, height, style, parentLayout);
				end
			else
				-- do not show this template block if the placeholder is not bound to any node in the original file
			end
		end
	end
end

----------------------------------------------------------------------
-- pe:placeholder: handles MCML tag <pe:placeholder>
----------------------------------------------------------------------
local pe_placeholder = commonlib.gettable("Map3DSystem.mcml_controls.pe_placeholder");
function pe_placeholder.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
end
