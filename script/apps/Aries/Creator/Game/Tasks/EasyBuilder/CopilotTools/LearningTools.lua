--[[
Title: LearningTools
Author(s): copilot
Date: 2026/03/18
Desc: Learning session tools — decoupled from BackgroundAgent.
Registers tools for interactive learning (tests, flashcards, TTS).
Code execution tools have been moved to CodeTools.lua.

Categories: "learning_test", "audio"

Services used (via ServiceProvider injection):
  - "learning_ui"    : LaunchLearningTool(toolName, params, callback)
  - "tts"            : ClearQueue(), SpeakText(text, voice, waitForComplete, callback)

Usage:
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/CopilotTools/LearningTools.lua");
    local LearningTools = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.CopilotTools.LearningTools");
    local tools = LearningTools:new();
    tools:RegisterTools(registry);
]]

local LearningTools = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.CopilotTools.LearningTools"));

function LearningTools:ctor()
end

--[[
    Register all learning tools on a ToolRegistry.
    @param registry: ToolRegistry instance
]]
function LearningTools:RegisterTools(registry)
    if not registry then return; end

    -- Tool: Multiple choice test
    registry:RegisterTool("test_multiple_choice", {
        description = "Present a multiple choice question to test the learner's knowledge. Returns when user selects an answer.",
        parameters = {
            type = "object",
            properties = {
                question = {
                    type = "string",
                    description = "The question text to display",
                },
                options = {
                    type = "array",
                    items = {type = "string"},
                    description = "Array of answer options (2-4 choices)",
                },
                correctIndex = {
                    type = "number",
                    description = "Zero-based index of the correct answer",
                },
                hint = {
                    type = "string",
                    description = "Optional hint to show if user gets it wrong",
                },
                subject = {
                    type = "string",
                    description = "The subject/item being tested (e.g., the word being learned)",
                },
            },
            required = {"question", "options", "correctIndex"},
        },
    }, function(params, callback, services)
        if not params.question or params.question == "" then
            callback({success = false, llm_result = "Error: 'question' parameter is required for test_multiple_choice."});
            return;
        end
        if not params.options or type(params.options) ~= "table" or #params.options < 2 then
            callback({success = false, llm_result = "Error: 'options' must be an array with at least 2 choices."});
            return;
        end
        if not params.correctIndex or type(params.correctIndex) ~= "number" then
            callback({success = false, llm_result = "Error: 'correctIndex' (number) is required for test_multiple_choice."});
            return;
        end
        local learningUI = services and services:Get("learning_ui");
        if not learningUI then
            callback({success = false, llm_result = "Learning UI service unavailable"});
            return;
        end
        learningUI:LaunchLearningTool("test_multiple_choice", params, callback);
    end, "learning_test");

    -- Tool: Word speaking test (pronunciation)
    registry:RegisterTool("test_words_speaking", {
        description = "Test the learner's pronunciation by having them speak a word. Shows the word and optional phonetic, plays audio, then listens for speech.",
        parameters = {
            type = "object",
            properties = {
                word = {
                    type = "string",
                    description = "The word to speak",
                },
                phonetic = {
                    type = "string",
                    description = "Phonetic transcription (IPA or simple)",
                },
                audioUrl = {
                    type = "string",
                    description = "URL to pronunciation audio file",
                },
                maxAttempts = {
                    type = "number",
                    description = "Maximum attempts allowed (default: 3)",
                },
                showHint = {
                    type = "boolean",
                    description = "Whether to show phonetic hint",
                },
            },
            required = {"word"},
        },
    }, function(params, callback, services)
        if not params.word or params.word == "" then
            callback({success = false, llm_result = "Error: 'word' parameter is required for test_words_speaking."});
            return;
        end
        local learningUI = services and services:Get("learning_ui");
        if not learningUI then
            callback({success = false, llm_result = "Learning UI service unavailable"});
            return;
        end
        learningUI:LaunchLearningTool("test_words_speaking", params, callback);
    end, "learning_test");

    -- Tool: Word spelling test
    registry:RegisterTool("test_words_spelling", {
        description = "Test the learner's spelling by having them type a word. Can show hints like letter count or first letter.",
        parameters = {
            type = "object",
            properties = {
                word = {
                    type = "string",
                    description = "The correct spelling of the word",
                },
                hint = {
                    type = "string",
                    description = "Hint or definition to help identify the word",
                },
                showLetterCount = {
                    type = "boolean",
                    description = "Show number of letters as hint",
                },
                showFirstLetter = {
                    type = "boolean",
                    description = "Show first letter as hint",
                },
                audioUrl = {
                    type = "string",
                    description = "URL to pronunciation audio to play",
                },
                maxAttempts = {
                    type = "number",
                    description = "Maximum attempts allowed (default: 3)",
                },
                imageUrl = {
                    type = "string",
                    description = "Optional image hint URL",
                },
            },
            required = {"word"},
        },
    }, function(params, callback, services)
        if not params.word or params.word == "" then
            callback({success = false, llm_result = "Error: 'word' parameter is required for test_words_spelling."});
            return;
        end
        local learningUI = services and services:Get("learning_ui");
        if not learningUI then
            callback({success = false, llm_result = "Learning UI service unavailable"});
            return;
        end
        learningUI:LaunchLearningTool("test_words_spelling", params, callback);
    end, "learning_test");

    -- Tool: Show learning content (flashcard-style)
    registry:RegisterTool("show_learning_content", {
        description = "Display learning content like a flashcard with word, translation, image, and pronunciation.",
        parameters = {
            type = "object",
            properties = {
                word = {
                    type = "string",
                    description = "The word or phrase to learn",
                },
                translation = {
                    type = "string",
                    description = "Translation in learner's primary language",
                },
                phonetic = {
                    type = "string",
                    description = "Phonetic transcription",
                },
                imageUrl = {
                    type = "string",
                    description = "Illustration image URL",
                },
                audioUrl = {
                    type = "string",
                    description = "Pronunciation audio URL",
                },
                exampleSentence = {
                    type = "string",
                    description = "Example sentence using the word",
                },
                duration = {
                    type = "number",
                    description = "How long to display (seconds, default: 5)",
                },
            },
            required = {"word"},
        },
    }, function(params, callback, services)
        if not params.word or params.word == "" then
            callback({success = false, llm_result = "Error: 'word' parameter is required for show_learning_content."});
            return;
        end
        -- Don't call OnItemTaught here — wait until OnLearningToolResult confirms
        -- the user actually saw the content (gift box clicked / UI completed).
        local learningUI = services and services:Get("learning_ui");
        if not learningUI then
            callback({success = false, llm_result = "Learning UI service unavailable"});
            return;
        end
        learningUI:LaunchLearningTool("show_learning_content", params, callback);
    end, "learning_test");

    -- Note: run_npl_codeblock_code and run_npl_code have been moved to CodeTools.lua

    -- Tool: Text-to-Speech (TTS)
    registry:RegisterTool("speak_text", {
        description = "Speak text aloud using TTS (text-to-speech). Use this to talk to the learner, read words, give instructions, or provide feedback.",
        parameters = {
            type = "object",
            properties = {
                text = {
                    type = "string",
                    description = "The text to speak aloud",
                },
                voice = {
                    type = "number",
                    description = "Voice narrator ID. 20008=Child female (晓双), 20011=Adult female (晓晓), 20009=Adult male (云希). Default: 20008 for child-friendly voice.",
                },
                waitForComplete = {
                    type = "boolean",
                    description = "Whether to wait for speech to complete before returning (default: true)",
                },
            },
            required = {"text"},
        },
    }, function(params, callback, services)
        local tts = services and services:Get("tts");
        if not tts then
            callback({success = false, llm_result = "TTS service unavailable"});
            return;
        end
        tts:ClearQueue();

        -- Delay 1 second to ensure TTS engine is fully stopped, then speak
        commonlib.TimerManager.SetTimeout(function()
            tts:SpeakText(params.text, params.voice, params.waitForComplete, callback);
        end, 1000);
    end, "audio");
end
