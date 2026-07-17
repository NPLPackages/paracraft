--[[
Title: WebTools
Author(s): copilot
Date: 2026/04/02
Desc: Web fetching tools — fetches webpage content and extracts text for AI consumption.
Uses System.os.GetUrl for HTTP requests and simple HTML→text conversion.
Registered tool:
  - fetch_webpage: Fetch one or more URLs, strip HTML tags, and return text content
    with optional query-focused snippet extraction.

Category: "web"

Usage:
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/CopilotTools/WebTools.lua");
    local WebTools = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.CopilotTools.WebTools");
    local tools = WebTools:new();
    tools:RegisterTools(registry);
    -- Direct use:
    tools:FetchWebpage("https://example.com", "some query", function(result) echo(result) end);
]]

local WebTools = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.CopilotTools.WebTools"));

-- Maximum content length per URL (characters)
WebTools.MAX_CONTENT_LENGTH = 6000;

-- HTTP request timeout (milliseconds)
WebTools.TIMEOUT_MS = 15000;

function WebTools:ctor()
end

--[[
    Register all web tools on a ToolRegistry.
    @param registry: ToolRegistry instance
]]
function WebTools:RegisterTools(registry)
    if not registry then return; end

    local self_ = self;
    registry:RegisterTool("fetch_webpage", {
        description = "Fetch the main content from one or more web pages. "
            .. "Returns extracted text content suitable for AI analysis. "
            .. "Use this when you need to look up information from a URL.",
        parameters = {
            type = "object",
            properties = {
                urls = {
                    type = "array",
                    items = { type = "string" },
                    description = "An array of URLs to fetch content from.",
                },
                query = {
                    type = "string",
                    description = "The query to search for in the web page's content. "
                        .. "Used to extract the most relevant snippet from long pages.",
                },
            },
            required = {"urls", "query"},
        },
    }, function(params, callback, services)
        self_:ExecuteFetchWebpage(params, callback);
    end, "web");
end

--------------------------------------------------------------------------------
-- Execution Methods
--------------------------------------------------------------------------------

--[[
    Execute fetch_webpage tool: fetch one or more URLs and return text content.
    @param params: table - {urls: string[], query: string}
    @param callback: function(result) - Called with {success, llm_result}
]]
function WebTools:ExecuteFetchWebpage(params, callback)
    local urls = params.urls;
    local query = params.query;

    if not urls or type(urls) ~= "table" or #urls == 0 then
        callback({ success = false, llm_result = "Failed: urls is required and must be a non-empty array" });
        return;
    end
    if not query or type(query) ~= "string" or query == "" then
        callback({ success = false, llm_result = "Failed: query is required" });
        return;
    end

    local results = {};
    local pending = #urls;
    local maxLen = self.MAX_CONTENT_LENGTH or 6000;

    for i, url in ipairs(urls) do
        self:FetchWebpage(url, query, function(result)
            results[i] = result;
            pending = pending - 1;
            if pending <= 0 then
                -- All fetches complete, format output
                local parts = {};
                for _, r in ipairs(results) do
                    if r then
                        if r.error then
                            table.insert(parts, string.format("URL: %s\nError: %s", r.url or "?", r.error));
                        else
                            local header = string.format("URL: %s", r.url or "?");
                            if r.title and r.title ~= "" then
                                header = header .. string.format("\nTitle: %s", r.title);
                            end
                            table.insert(parts, header .. "\n" .. (r.content or ""));
                        end
                    end
                end
                callback({
                    success = true,
                    llm_result = table.concat(parts, "\n\n---\n\n"),
                });
            end
        end);
    end
end

--[[
    Fetch a single webpage and extract text content.
    @param url: string - URL to fetch
    @param query: string - Query for snippet extraction
    @param callback: function(result) - {url, title, content, error}
]]
function WebTools:FetchWebpage(url, query, callback)
    if not url or url == "" then
        callback({ url = url, error = "Empty URL" });
        return;
    end

    local maxLen = self.MAX_CONTENT_LENGTH or 6000;

    System.os.GetUrl({
        url = url,
        headers = {
            Accept = "text/html,application/xhtml+xml,application/xml;q=0.9,text/plain;q=0.8,*/*;q=0.5",
        },
    }, function(err, msg, data)
        if err ~= 200 then
            callback({ url = url, error = string.format("HTTP %s: %s", tostring(err), tostring(msg and msg.statusCode or "")) });
            return;
        end
        if not data or data == "" then
            callback({ url = url, error = "Empty response" });
            return;
        end

        -- Check if raw content should be returned (markdown, json)
        if WebTools.ShouldReturnRaw(url, data) then
            local content = data;
            if #content > maxLen then
                content = content:sub(1, maxLen);
            end
            callback({ url = url, title = "", content = content });
            return;
        end

        -- Parse HTML
        local title = WebTools.ExtractTitle(data);
        local text = WebTools.HtmlToText(data);

        -- Try query-focused snippet
        local snippet = WebTools.BuildQuerySnippet(text, query, math.min(maxLen, 1800));
        local sourceContent = (snippet and snippet ~= "") and snippet or text;

        -- Truncate to maxLen
        if #sourceContent > maxLen then
            sourceContent = sourceContent:sub(1, maxLen);
        end

        callback({ url = url, title = title, content = sourceContent });
    end);
end

--------------------------------------------------------------------------------
-- HTML Parsing Helpers (static methods, no DOM available in NPL)
--------------------------------------------------------------------------------

--[[
    Check if the URL or content indicates raw format (markdown, JSON) that
    should be returned without HTML stripping.
    @param url: string
    @param content: string
    @return boolean
]]
function WebTools.ShouldReturnRaw(url, content)
    if not url then return false; end
    local lower = url:lower();
    if lower:match("%.md$") or lower:match("%.md%?") then return true; end
    if lower:match("%.json$") or lower:match("%.json%?") then return true; end
    -- Check if content doesn't look like HTML
    if content and not content:match("<html") and not content:match("<body") and not content:match("<!DOCTYPE") then
        -- Heuristic: if first non-whitespace is { or [, likely JSON
        local trimmed = content:match("^%s*(.-)");
        if trimmed and (trimmed:sub(1, 1) == "{" or trimmed:sub(1, 1) == "[") then
            return true;
        end
    end
    return false;
end

--[[
    Extract the <title> content from HTML.
    @param html: string
    @return string
]]
function WebTools.ExtractTitle(html)
    if not html then return ""; end
    local title = html:match("<title[^>]*>(.-)</title>");
    if title then
        return WebTools.NormalizeText(title);
    end
    return "";
end

--[[
    Convert HTML to plain text by stripping tags and normalizing whitespace.
    Removes script, style, noscript, svg, nav, header, footer blocks first.
    @param html: string
    @return string
]]
function WebTools.HtmlToText(html)
    if not html then return ""; end

    -- Remove blocks that are not useful for content extraction
    local text = html;
    -- Remove script, style, noscript, svg, nav, header, footer, form, aside
    for _, tag in ipairs({"script", "style", "noscript", "svg", "nav", "header", "footer", "form", "aside"}) do
        text = text:gsub("<" .. tag .. "[^>]*>.-</" .. tag .. ">", " ");
    end

    -- Try to extract main content area (article, main, [role="main"])
    local mainContent = text:match("<main[^>]*>(.-)</main>")
        or text:match("<article[^>]*>(.-)</article>")
        or text:match('<div[^>]*role%s*=%s*"main"[^>]*>(.-)</div>');

    if mainContent and #mainContent > 100 then
        text = mainContent;
    end

    -- Replace block-level tags with newlines for readability
    text = text:gsub("<br[^>]*>", "\n");
    text = text:gsub("</p>", "\n");
    text = text:gsub("</div>", "\n");
    text = text:gsub("</li>", "\n");
    text = text:gsub("</h[1-6]>", "\n");
    text = text:gsub("</tr>", "\n");

    -- Strip all remaining tags
    text = text:gsub("<[^>]+>", " ");

    -- Decode common HTML entities
    text = WebTools.DecodeEntities(text);

    return WebTools.NormalizeText(text);
end

--[[
    Decode common HTML entities.
    @param text: string
    @return string
]]
function WebTools.DecodeEntities(text)
    if not text then return ""; end
    local entities = {
        ["&amp;"] = "&",
        ["&lt;"] = "<",
        ["&gt;"] = ">",
        ["&quot;"] = '"',
        ["&apos;"] = "'",
        ["&#39;"] = "'",
        ["&nbsp;"] = " ",
        ["&#160;"] = " ",
    };
    for entity, char in pairs(entities) do
        text = text:gsub(entity, char);
    end
    -- Decode numeric entities &#NNN;
    text = text:gsub("&#(%d+);", function(n)
        local num = tonumber(n);
        if num and num < 128 then
            return string.char(num);
        end
        return "";
    end);
    return text;
end

--[[
    Normalize whitespace: collapse multiple spaces/newlines, trim.
    @param text: string
    @return string
]]
function WebTools.NormalizeText(text)
    if not text then return ""; end
    -- Collapse multiple whitespace into single space
    text = text:gsub("[ \t]+", " ");
    -- Collapse multiple newlines into double newline
    text = text:gsub("\n[ \t]*\n", "\n\n");
    text = text:gsub("\n\n\n+", "\n\n");
    -- Trim leading/trailing whitespace
    text = text:match("^%s*(.-)%s*$") or "";
    return text;
end

--[[
    Build a query-focused snippet by finding the best matching region.
    @param content: string - Full text content
    @param query: string - Search query
    @param maxLength: number - Maximum snippet length (default 1800)
    @return string - Extracted snippet, or "" if no match
]]
function WebTools.BuildQuerySnippet(content, query, maxLength)
    maxLength = maxLength or 1800;
    if not content or content == "" then return ""; end
    if not query or query == "" then return ""; end

    local lowerContent = content:lower();

    -- Split query into terms
    local terms = {};
    for term in query:lower():gmatch("%S+") do
        if not terms[term] then
            table.insert(terms, term);
            terms[term] = true;
        end
    end

    -- Find the earliest match position
    local matchIndex = nil;
    for _, term in ipairs(terms) do
        local pos = lowerContent:find(term, 1, true);
        if pos and (not matchIndex or pos < matchIndex) then
            matchIndex = pos;
        end
    end

    if not matchIndex then
        return "";
    end

    -- Extract a window around the match
    local halfWindow = math.floor(maxLength / 2);
    local startPos = math.max(1, matchIndex - halfWindow);
    local endPos = math.min(#content, startPos + maxLength);
    return content:sub(startPos, endPos);
end
