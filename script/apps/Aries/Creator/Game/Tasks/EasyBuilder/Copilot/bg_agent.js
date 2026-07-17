/**
 * bg_agent.js
 * Background Agent Debugger — vanilla JS (no frameworks)
 * Primary communication: WebSocket push (ws://<host>/ajax/raw?file=script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/bg_agent.page&action=handshake)
 * Fallback AJAX: context history (kept for simplicity).
 */
(function () {
    'use strict';

    var BASE    = 'ajax/raw?file=script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/bg_agent.page&action=';
    var WS_FILE = 'script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/bg_agent_ws_server.lua';

    // WebSocket state
    var ws             = null;
    var wsReady        = false;
    var reconnectTimer = null;
    var reconnectDelay = 1000;   // doubles up to 30 s
    var MAX_DELAY      = 30000;
    var destroyed      = false;

    // ── Helpers ──────────────────────────────────────────────

    function $(id) { return document.getElementById(id); }

    function esc(s) {
        if (s == null) return '';
        return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
    }

    function truncate(s, n) {
        if (!s) return '';
        return s.length > n ? s.slice(0, n) + '...' : s;
    }

    function diskImageUrl(path) {
        if (!path) return '';
        return '/wp-content/pages/disk_image.page?filename=' + encodeURIComponent(path.replace(/\\/g, '/'));
    }

    // AJAX helper kept for context-history (not in WS init snapshot)
    function get(action, params) {
        var url = BASE + action;
        if (params) {
            var parts = [];
            for (var k in params) {
                if (params[k] != null) parts.push(encodeURIComponent(k) + '=' + encodeURIComponent(params[k]));
            }
            if (parts.length) url += '&' + parts.join('&');
        }
        return fetch(url).then(function (r) { return r.json(); });
    }

    // ── WebSocket ─────────────────────────────────────────────

    function wsUrl() {
        var proto = location.protocol === 'https:' ? 'wss:' : 'ws:';
        return proto + '//' + location.host + '/ajax/raw?file=script/apps/Aries/Creator/Game/Tasks/EasyBuilder/Copilot/bg_agent.page&action=handshake';
    }

    function wsSend(obj) {
        if (!wsReady || !ws || ws.readyState !== WebSocket.OPEN) {
            console.warn('[bg_agent WS] wsSend skipped (not ready):', obj.action);
            return false;
        }
        obj.filename = obj.filename || WS_FILE;
        //console.log('[bg_agent WS] →', obj.action, obj);
        ws.send(JSON.stringify(obj));
        return true;
    }

    function setWsBadge(state, label) {
        var el = $('wsBadge');
        if (!el) return;
        var cls = {
            connected:    'bg-green/15 text-green',
            disconnected: 'bg-red/15 text-red',
            connecting:   'bg-yellow/15 text-yellow',
        };
        el.className = 'ml-auto px-2 py-0.5 rounded-full text-xs font-semibold ' + (cls[state] || 'bg-surface text-muted');
        el.innerHTML = 'WS: &#x25CF; ' + esc(label);
    }

    function scheduleReconnect() {
        if (destroyed || reconnectTimer) return;
        setWsBadge('disconnected', 'reconnecting in ' + (reconnectDelay / 1000).toFixed(0) + 's');
        reconnectTimer = setTimeout(function () {
            reconnectTimer = null;
            if (!destroyed) connectWS();
        }, reconnectDelay);
        reconnectDelay = Math.min(reconnectDelay * 2, MAX_DELAY);
    }

    function connectWS() {
        setWsBadge('connecting', 'connecting…');
        ws = new WebSocket(wsUrl());

        ws.onopen = function () {
            reconnectDelay = 1000;
            wsReady = true;
            setWsBadge('connected', 'live');
            //console.log('[bg_agent WS] connected, sending refresh…');
            wsSend({action: 'refresh'});
        };

        ws.onmessage = function (e) {
            var data;
            try { data = JSON.parse(e.data); } catch(_) { return; }
            //console.log('[bg_agent WS] ←', data.type, data);
            handleWsMessage(data);
        };

        ws.onclose = function () {
            wsReady = false;
            scheduleReconnect();
        };

        ws.onerror = function () {
            // onclose fires right after onerror
        };
    }

    function handleWsMessage(d) {
        var t = d.type;
        if (t === 'init') {
            if (d.status)   renderStatus(d.status);
            if (d.chat)     renderChat(d.chat);
            if (d.llm)      { _llmEntries = d.llm; renderLLMHistory(_llmEntries); }
            if (d.vision)   renderVision(d.vision);
            if (d.voice)    renderVoice(d.voice);
            if (d.tools)    renderTools(d.tools);
            if (d.copilots) renderCopilots(d.copilots);
            if (d.progress) renderProgress(d.progress);
        } else if (t === 'status') {
            if (d.data) renderStatus(d.data);
        } else if (t === 'chat') {
            if (d.data && d.data.messages) renderChat(d.data.messages);
        } else if (t === 'llm') {
            if (d.data && d.data.entries) { _llmEntries = d.data.entries; renderLLMHistory(_llmEntries); }
        } else if (t === 'vision') {
            if (d.data && d.data.entries) renderVision(d.data.entries);
        } else if (t === 'voice') {
            if (d.data && d.data.entries) renderVoice(d.data.entries);
        } else if (t === 'copilots') {
            if (d.data && d.data.copilots) renderCopilots(d.data.copilots);
        } else if (t === 'tools') {
            if (d.data && d.data.tools) renderTools(d.data.tools);
        } else if (t === 'progress') {
            if (d.data) renderProgress(d.data);
        } else if (t === 'system_prompt') {
            if (d.data) $('promptPre').textContent = d.data.prompt || '(empty)';
        } else if (t === 'last_step') {
            if (d.data) renderLastStep(d.data);
        } else if (t === 'ack') {
            if (d.action === 'save_learning_state' && d.success) alert('Learning state saved.');
            else if (d.action === 'set_system_prompt' && d.success) alert('System prompt updated.');
        } else if (t === 'error') {
            console.warn('[bg_agent WS]', d.msg);

        }
    }

    // ── Tab helpers ──────────────────────────────────────────

    function activateTab(btnClass, panelPrefix, name) {
        document.querySelectorAll('.' + btnClass).forEach(function (b) {
            var isActive = b.getAttribute('data-' + (btnClass === 'ltab' ? 'ltab' : 'rtab')) === name;
            b.classList.toggle('text-blue', isActive);
            b.classList.toggle('border-blue', isActive);
            b.classList.toggle('text-muted', !isActive);
            b.classList.toggle('border-transparent', !isActive);
        });
        document.querySelectorAll('[id^="' + panelPrefix + '"]').forEach(function (p) {
            p.classList.toggle('hidden', p.id !== panelPrefix + name.charAt(0).toUpperCase() + name.slice(1));
        });
    }

    // ── Status row builder ──────────────────────────────────

    function infoRow(label, value) {
        return '<div class="flex justify-between py-1 text-sm"><span class="text-muted">' + esc(label) + '</span><span class="text-txt font-medium">' + esc(value) + '</span></div>';
    }

    // ── State badge ─────────────────────────────────────────

    var stateColors = {
        playing: 'bg-green/15 text-green',
        paused:  'bg-yellow/15 text-yellow',
        stopped: 'bg-red/15 text-red',
    };

    function updateBadge(state) {
        var el = $('stateBadge');
        el.textContent = state || 'unknown';
        el.className = 'px-2 py-0.5 rounded-full text-xs font-semibold uppercase ' + (stateColors[state] || 'bg-surface text-muted');
    }

    // ── Render functions ────────────────────────────────────

    function renderStatus(d) {
        updateBadge(d.playbackState);
        $('llmCount').textContent = 'LLM: ' + (d.llmCount || 0);
        $('chatCount').textContent = 'Chat: ' + (d.chatCount || 0);

        // Sync toolbar toggle buttons
        var db = $('debugBtn');
        if (db) {
            db.textContent = 'Debug: ' + (d.debugEnabled ? 'ON' : 'OFF');
            db.className = db.className.replace(/bg-\S+|text-base|text-txt/g, '').trim();
            if (d.debugEnabled) db.className += ' bg-yellow/20 text-yellow'; else db.className += ' bg-card text-txt';
        }
        var ob = $('obsBtn');
        if (ob) {
            ob.textContent = 'Obs: ' + (d.isObservationMode ? 'ON' : 'OFF');
            ob.className = ob.className.replace(/bg-\S+|text-\S+/g, '').trim();
            if (d.isObservationMode) ob.className += ' bg-mauve/20 text-mauve'; else ob.className += ' bg-card text-txt';
        }
        var asb = $('autoSpeakBtn');
        if (asb) {
            asb.textContent = '\uD83D\uDD0A AutoSpeak: ' + (d.autoSpeakEnabled ? 'ON' : 'OFF');
            asb.className = asb.className.replace(/bg-\S+|text-\S+/g, '').trim();
            if (d.autoSpeakEnabled) asb.className += ' bg-green/20 text-green'; else asb.className += ' bg-card text-txt';
        }
        var vpb = $('visionPassiveBtn');
        if (vpb) {
            var passive = d.sceneVisionPassiveMode === true;
            vpb.textContent = '\uD83D\uDCF7 Vision: ' + (passive ? 'Passive' : 'Active');
            vpb.className = vpb.className.replace(/bg-\S+|text-\S+/g, '').trim();
            if (passive) vpb.className += ' bg-yellow/20 text-yellow'; else vpb.className += ' bg-card text-txt';
        }

        var h = '';
        h += infoRow('State',       d.playbackState || '—');
        h += infoRow('Enabled',     d.isEnabled     ? 'YES' : 'no');
        h += infoRow('Debug',       d.debugEnabled  ? 'ON'  : 'OFF');
        h += infoRow('Observe',     d.isObservationMode ? 'ON' : 'OFF');
        h += infoRow('AutoSpeak',   d.autoSpeakEnabled  ? 'ON' : 'OFF');
        h += infoRow('Vision Mode', d.sceneVisionPassiveMode ? 'Passive' : 'Active');
        h += infoRow('TTS Playing', d.isTTSPlaying ? 'YES' : 'no');
        h += infoRow('Stepping',    d.stepInProgress ? 'YES' : 'no');
        if (d.hasTask) {
            h += infoRow('Task', truncate(d.taskText, 36));
        }
        if (d.learningPercentage != null) {
            h += infoRow('Progress', d.learningPercentage + '%');
            h += '<div class="h-1.5 bg-surface rounded-full overflow-hidden my-1"><div class="h-full bg-green rounded-full transition-all" style="width:' + d.learningPercentage + '%"></div></div>';
        }
        var tts = d.tts || {};
        h += infoRow('TTS Queue', tts.queueLength || 0);
        h += infoRow('Voice Pending', d.voicePending || 0);
        var uiq = d.uiToolQueue || {};
        if (uiq.queueLength) h += infoRow('UITool Queue', uiq.queueLength);
        $('statusPanel').innerHTML = h;

        // sync task textarea if empty
        if (d.taskText && !$('taskInput').value) {
            $('taskInput').value = d.taskText;
        }
    }

    function renderChat(messages) {
        var el = $('chatScroll');
        if (!messages || !messages.length) {
            el.innerHTML = '<div class="text-muted text-center py-5 text-sm">No messages yet. Type below or press Play.</div>';
            $('chatBadge').textContent = '0';
            return;
        }
        $('chatBadge').textContent = messages.length;
        var h = '';
        messages.forEach(function (m) {
            var isUser = m.role === 'user';
            h += '<div class="mb-2 px-3 py-2 rounded-md whitespace-pre-wrap break-words text-sm leading-relaxed '
                + (isUser ? 'bg-blue/10 border-l-[0.15rem] border-blue' : 'bg-green/5 border-l-[0.15rem] border-green') + '">';
            h += '<div class="text-xs font-bold uppercase mb-0.5 ' + (isUser ? 'text-blue' : 'text-green') + '">' + esc(m.role) + '</div>';
            h += '<div>' + esc(m.content) + '</div></div>';
        });
        el.innerHTML = h;
        el.scrollTop = el.scrollHeight;
    }

    function renderLLMHistory(entries) {
        var el = $('llmList');
        $('llmBadge').textContent = entries ? entries.length : 0;
        if (!entries || !entries.length) {
            el.innerHTML = '<div class="text-muted p-2 text-sm">No LLM calls yet</div>';
            return;
        }
        var h = '';
        entries.forEach(function (e, i) {
            h += '<div class="py-1.5 px-2.5 border-b border-border text-sm cursor-pointer hover:bg-surface" onclick="Agent.showLLMDetail(' + i + ')">';
            h += '<span class="text-muted">' + esc(e.timeStr) + '</span> ';
            h += '<span class="' + (e.status === 'ok' ? 'text-green' : 'text-red') + '">' + esc(e.status) + '</span> ';
            h += '<span class="text-yellow">' + esc(e.durationStr) + '</span>';
            if (e.hasImage) h += ' &#x1F4F7;';
            if (e.toolCallCount) h += ' <span class="text-mauve">&#x1F527;' + e.toolCallCount + '</span>';
            h += '<div class="text-txtsec mt-0.5">' + esc(truncate(e.responseShort, 80)) + '</div>';
            h += '</div>';
        });
        el.innerHTML = h;
    }

    function renderTools(tools) {
        var el = $('leftTabTools');
        $('toolsBadge').textContent = tools ? tools.length : 0;
        if (!tools || !tools.length) {
            el.innerHTML = '<div class="text-muted p-2 text-sm">No tools registered</div>';
            return;
        }
        var h = '';
        tools.forEach(function (t) {
            var name = (t['function'] ? t['function'].name : t.name) || '?';
            var desc = (t['function'] ? t['function'].description : t.description) || '';
            h += '<div class="py-1 px-2.5 text-sm text-txtsec border-b border-surface">';
            h += '<span class="text-mauve font-semibold">' + esc(name) + '</span>';
            if (desc) h += ' <span class="text-muted ml-1">- ' + esc(truncate(desc, 55)) + '</span>';
            h += '</div>';
        });
        el.innerHTML = h;
    }

    function renderCopilots(list) {
        var el = $('copilotsList');
        $('copilotsBadge').textContent = list ? list.length : 0;
        if (!list || !list.length) {
            el.innerHTML = '<div class="text-muted p-2 text-sm">No copilots discovered</div>';
            return;
        }
        var h = '';
        list.forEach(function (c) {
            h += '<div class="py-1 px-2 border-b border-surface text-xs">';
            h += '<span class="text-yellow font-semibold">' + esc(c.displayName || c.name) + '</span>';
            h += ' <span class="text-muted ml-1">' + (c.toolCount || 0) + ' tools</span>';
            h += '</div>';
        });
        el.innerHTML = h;
    }

    function renderContext(entries) {
        var el = $('rightTabContext');
        if (!entries || !entries.length) {
            el.innerHTML = '<div class="text-muted p-2 text-sm">No context entries</div>';
            return;
        }
        var h = '';
        entries.forEach(function (c) {
            var imgUrl = (c.imageUrl && c.imageUrl !== '') ? c.imageUrl : (c.imagePath ? diskImageUrl(c.imagePath) : '');
            var imgLabel = (c.imageUrl && c.imageUrl !== '') ? c.imageUrl : (c.imagePath || '');
            var imgAttr = imgUrl ? ' data-img="' + imgUrl + '"' : '';
            var timeStr = c.timestamp ? new Date(c.timestamp * 1000).toLocaleTimeString() : (c.timeStr || '');
            var content = c.content || c.summary || '';
            h += '<div class="py-1.5 px-2 border-b border-surface text-sm"' + imgAttr + '>';
            h += '<span class="text-muted">' + esc(timeStr) + '</span> ';
            h += '<span class="text-yellow">' + esc(c.type) + '</span>';
            if (c.sentToLLM) h += ' <span class="text-green text-xs">&#x2713;LLM</span>';
            if (imgLabel) h += '<div class="text-blue text-xs mt-0.5 break-all">&#x1F4F7; ' + esc(imgLabel) + '</div>';
            h += '<div class="text-txtsec mt-0.5">' + esc(truncate(content, 150)) + '</div>';
            h += '</div>';
        });
        el.innerHTML = h;
    }

    function renderVision(entries) {
        var el = $('visionList');
        if (!el) return;
        $('visionBadge').textContent = entries ? entries.length : 0;
        if (!entries || !entries.length) {
            el.innerHTML = '<div class="text-muted p-2 text-sm">No scene vision entries</div>';
            return;
        }
        var h = '';
        entries.slice().reverse().forEach(function (e) {
            var imgUrl = (e.imageUrl && e.imageUrl !== '') ? e.imageUrl : (e.imagePath ? diskImageUrl(e.imagePath) : '');
            var imgLabel = (e.imageUrl && e.imageUrl !== '') ? e.imageUrl : (e.imagePath || '');
            var imgAttr = imgUrl ? ' data-img="' + imgUrl + '"' : '';
            h += '<div class="py-1.5 px-2 border-b border-surface text-xs"' + imgAttr + '>';
            h += '<div class="text-muted">' + esc(new Date(e.timestamp * 1000).toLocaleTimeString()) + '</div>';
            if (imgLabel) h += '<div class="text-blue text-xs mt-0.5 break-all">&#x1F4F7; ' + esc(imgLabel) + '</div>';
            if (e.description) h += '<div class="text-txtsec mt-0.5 whitespace-pre-wrap">' + esc(truncate(e.description, 120)) + '</div>';
            h += '</div>';
        });
        el.innerHTML = h;
    }

    function renderVoice(entries) {
        var el = $('voiceList');
        if (!el) return;
        $('voiceBadge').textContent = entries ? entries.length : 0;
        if (!entries || !entries.length) {
            el.innerHTML = '<div class="text-muted p-2 text-sm">No voice entries</div>';
            return;
        }
        var h = '';
        entries.slice().reverse().forEach(function (e) {
            h += '<div class="py-1.5 px-2 border-b border-surface text-xs">';
            h += '<span class="text-muted">' + esc(new Date(e.timestamp * 1000).toLocaleTimeString()) + '</span>';
            if (e.confidence != null) h += ' <span class="text-muted">' + Math.round(e.confidence * 100) + '%</span>';
            h += '<div class="text-txt mt-0.5">' + esc(e.transcript || '') + '</div>';
            h += '</div>';
        });
        el.innerHTML = h;
    }

    function renderProgress(d) {
        if (d && d.summary != null) {
            $('progressPre').textContent = d.summary || 'No learning progress data';
        }
    }

    function renderLastStep(d) {
        var el = $('stepPanel');
        if (!el) return;
        var h = '';
        if (!d || (!d.context && !d.result)) {
            el.innerHTML = '<div class="text-muted p-2 text-sm">No step data yet. Run a Step first.</div>';
            return;
        }
        if (d.context) {
            h += '<div class="text-xs font-semibold text-blue mb-0.5">Context</div>';
            h += '<pre class="whitespace-pre-wrap text-txtsec text-xs bg-input rounded p-1.5 mb-2">' + esc(JSON.stringify(d.context, null, 2)) + '</pre>';
        }
        if (d.result) {
            h += '<div class="text-xs font-semibold text-green mb-0.5">Result</div>';
            h += '<pre class="whitespace-pre-wrap text-txtsec text-xs bg-input rounded p-1.5">' + esc(JSON.stringify(d.result, null, 2)) + '</pre>';
        }
        el.innerHTML = h;
    }

    // ── Cached data for modal ───────────────────────────────

    var _llmEntries = [];

    // ── Public API (window.Agent) ───────────────────────────

    var Agent = window.Agent = {};

    // Full refresh: request a new init snapshot from server
    Agent.refreshAll = function () {
        if (wsReady) { wsSend({action: 'refresh'}); }
        // Context history is not in the WS init snapshot — fetch via AJAX
        get('get_context_history', {max: 30}).then(function(d){ renderContext(d.entries); }).catch(function(){});
    };

    // Playback
    Agent.play  = function () { wsSend({action: 'play'}); };
    Agent.pause = function () { wsSend({action: 'pause'}); };
    Agent.stop  = function () { wsSend({action: 'stop'}); };
    Agent.step  = function () { wsSend({action: 'step'}); };

    // Chat
    Agent.sendMessage = function () {
        var input = $('chatInput');
        var text = (input.value || '').trim();
        if (!text) return;
        input.value = '';
        // Optimistic render
        var el = $('chatScroll');
        el.innerHTML += '<div class="mb-2 px-3 py-2 rounded-md whitespace-pre-wrap break-words text-sm leading-relaxed bg-blue/10 border-l-[0.15rem] border-blue">'
            + '<div class="text-xs font-bold uppercase mb-0.5 text-blue">user</div>'
            + '<div>' + esc(text) + '</div></div>';
        el.scrollTop = el.scrollHeight;
        wsSend({action: 'send_message', text: text});
    };

    Agent.clearChat = function () { wsSend({action: 'clear_chat'}); };

    // Debug / Observation / AutoSpeak toggles — read DOM state to avoid round-trip
    Agent.toggleDebug = function () {
        var db = $('debugBtn');
        var next = db && db.textContent.indexOf('ON') !== -1 ? '0' : '1';
        wsSend({action: 'set_debug_enabled', enabled: next});
    };

    Agent.toggleObservationMode = function () {
        var ob = $('obsBtn');
        var next = ob && ob.textContent.indexOf('ON') !== -1 ? '0' : '1';
        wsSend({action: 'set_observation_mode', enabled: next});
    };

    Agent.toggleAutoSpeak = function () {
        var asb = $('autoSpeakBtn');
        var next = asb && asb.textContent.indexOf('ON') !== -1 ? '0' : '1';
        wsSend({action: 'set_auto_speak', enabled: next});
    };

    Agent.toggleVisionPassive = function () {
        var vpb = $('visionPassiveBtn');
        var next = vpb && vpb.textContent.indexOf('Passive') !== -1 ? '0' : '1';
        wsSend({action: 'set_scene_vision_passive', enabled: next});
    };

    Agent.triggerObservation = function () { wsSend({action: 'trigger_observation'}); };
    Agent.clearUIToolQueue   = function () { wsSend({action: 'clear_uitool_queue'}); };

    // Vision & Voice
    Agent.fetchVision       = function () { wsSend({action: 'get_scene_vision_history'}); };
    Agent.fetchVoiceHistory = function () { wsSend({action: 'get_voice_history'}); };
    Agent.fetchLastStep     = function () { wsSend({action: 'get_last_step'}); };

    // Learning state management
    Agent.resetLearningProgress = function () {
        if (!confirm('Reset learning progress?')) return;
        wsSend({action: 'reset_learning_progress'});
    };

    Agent.saveLearningState = function () { wsSend({action: 'save_learning_state'}); };

    Agent.loadLearningState = function () {
        var taskId = prompt('Task ID to load (leave blank for current task):') || '';
        wsSend({action: 'load_learning_state', taskId: taskId});
    };

    Agent.clearLearningState = function () {
        var taskId = prompt('Task ID to clear (leave blank for current task):') || '';
        if (!confirm('Clear learning state for task "' + (taskId || 'current') + '"?')) return;
        wsSend({action: 'clear_learning_state', taskId: taskId});
    };

    // System prompt
    Agent.setSystemPrompt = function () {
        var prompt = ($('promptInput') || {}).value || '';
        if (!prompt.trim()) { alert('Prompt input is empty.'); return; }
        $('promptPre').textContent = prompt; // optimistic
        wsSend({action: 'set_system_prompt', prompt: prompt});
    };

    Agent.invalidateSystemPrompt = function () {
        wsSend({action: 'invalidate_system_prompt'});
        $('promptPre').textContent = 'Cache invalidated. Click Load to fetch fresh prompt.';
    };

    // Update interval (ms) - call from console: Agent.setUpdateInterval(2000)
    Agent.setUpdateInterval = function (ms) { wsSend({action: 'set_update_interval', interval: ms}); };

    // LLM
    Agent.clearLLMHistory = function () { wsSend({action: 'clear_llm_history'}); };

    // Scene vision / voice clear
    Agent.clearSceneVision  = function () { wsSend({action: 'clear_scene_vision'}); };
    Agent.clearVoiceHistory = function () { wsSend({action: 'clear_voice_history'}); };

    Agent.showLLMDetail = function (idx) {
        var e = _llmEntries[idx];
        if (!e) return;
        var h = '';
        h += infoRow('Time', e.timeStr);
        h += infoRow('Status', e.status);
        h += infoRow('Duration', e.durationStr);
        h += infoRow('Tool Calls', e.toolCallCount || 0);
        h += infoRow('Image', e.hasImage ? 'Yes' : 'No');
        h += '<hr class="border-border my-2">';
        h += '<div class="text-sm text-muted mb-1">Response</div>';
        h += '<pre class="whitespace-pre-wrap break-words text-sm text-txtsec">' + esc(e.responseShort || e.response || '(empty)') + '</pre>';
        $('llmModalBody').innerHTML = h;
        $('llmModal').classList.remove('hidden');
    };

    Agent.closeModal = function (evt) {
        if (evt && evt.target !== $('llmModal')) return;
        $('llmModal').classList.add('hidden');
    };

    // Copilots
    Agent.refreshCopilots = function () { wsSend({action: 'refresh_copilots'}); };

    // Task
    Agent.setTask = function () {
        var text = $('taskInput').value || '';
        wsSend({action: 'set_task', text: text});
    };

    // System prompt load
    Agent.loadSystemPrompt = function () { wsSend({action: 'get_system_prompt'}); };

    // Tabs
    Agent.setLeftTab = function (name) { activateTab('ltab', 'leftTab', name); };
    Agent.setRightTab = function (name) {
        activateTab('rtab', 'rightTab', name);
        // Lazy-load context via AJAX (not in WS snapshot)
        if (name === 'context') {
            get('get_context_history', {max: 30}).then(function(d){ renderContext(d.entries); }).catch(function(){});
        } else if (name === 'step') {
            wsSend({action: 'get_last_step'});
        } else if (name === 'progress') {
            wsSend({action: 'get_learning_progress'});
        }
    };

    // ── Init ────────────────────────────────────────────────

    // Enter key in chat input
    $('chatInput').addEventListener('keydown', function (e) {
        if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); Agent.sendMessage(); }
    });

    // Image hover preview
    (function () {
        var preview    = document.getElementById('imgPreview');
        var previewImg = document.getElementById('imgPreviewImg');
        var previewUrl = document.getElementById('imgPreviewUrl');
        if (!preview || !previewImg) return;
        function positionPreview(evt) {
            var x = evt.clientX + 18, y = evt.clientY + 18;
            if (x + 350 > window.innerWidth)  x = evt.clientX - 354;
            if (y + 240 > window.innerHeight) y = evt.clientY - 244;
            preview.style.left = x + 'px';
            preview.style.top  = y + 'px';
        }
        document.addEventListener('mousemove', function (evt) {
            var el = evt.target && evt.target.closest ? evt.target.closest('[data-img]') : null;
            if (!el) { preview.style.display = 'none'; return; }
            var src = el.getAttribute('data-img');
            if (!src) { preview.style.display = 'none'; return; }
            if (previewImg.getAttribute('src') !== src) { previewImg.src = src; }
            if (previewUrl) previewUrl.textContent = src;
            preview.style.display = 'block';
            positionPreview(evt);
        });
        document.addEventListener('mouseleave', function () { preview.style.display = 'none'; });
    })();

    // Default tabs
    Agent.setLeftTab('tools');
    Agent.setRightTab('context');

    // Start WebSocket (auto-reconnects)
    window.addEventListener('beforeunload', function () { destroyed = true; if (ws) ws.close(); });
    connectWS();

    // Hide sidebar if Page host exists
    if (typeof Page !== 'undefined' && Page.ShowSideBar) {
        Page.ShowSideBar(false);
    }
})();