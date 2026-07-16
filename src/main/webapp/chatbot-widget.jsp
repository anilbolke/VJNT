<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
<%--
    GATEE Portal Assistant - floating chatbot widget
    Include on any page AFTER login with:  <jsp:include page="chatbot-widget.jsp" />
    Renders nothing when no user is in session. Talks to /chatbot (ChatbotServlet).
    All ids/classes are prefixed with "gchat-" to avoid clashing with page styles.
--%>
<%
    User gchatUser = (User) session.getAttribute("user");
    if (gchatUser != null) {
%>
<style>
    #gchat-fab {
        position: fixed;
        bottom: 24px;
        right: 24px;
        width: 62px;
        height: 62px;
        border-radius: 50%;
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        border: none;
        cursor: pointer;
        box-shadow: 0 4px 16px rgba(102, 126, 234, 0.5);
        z-index: 99998;
        display: flex;
        align-items: center;
        justify-content: center;
        transition: transform 0.2s;
        padding: 0;
    }
    #gchat-fab:hover { transform: scale(1.08); }
    #gchat-fab img {
        width: 42px;
        height: 42px;
        border-radius: 50%;
        background: #fff;
        object-fit: contain;
        padding: 3px;
    }
    #gchat-fab .gchat-fab-badge {
        position: absolute;
        top: -2px;
        right: -2px;
        background: #48bb78;
        width: 14px;
        height: 14px;
        border-radius: 50%;
        border: 2px solid #fff;
    }

    #gchat-panel {
        position: fixed;
        bottom: 98px;
        right: 24px;
        width: 360px;
        max-width: calc(100vw - 32px);
        height: 520px;
        max-height: calc(100vh - 130px);
        background: #fff;
        border-radius: 16px;
        box-shadow: 0 10px 40px rgba(0,0,0,0.25);
        z-index: 99999;
        display: none;
        flex-direction: column;
        overflow: hidden;
        font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    }
    #gchat-panel.gchat-open { display: flex; }

    .gchat-header {
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        color: #fff;
        padding: 14px 16px;
        display: flex;
        align-items: center;
        gap: 12px;
    }
    .gchat-header img {
        width: 40px;
        height: 40px;
        border-radius: 50%;
        background: #fff;
        object-fit: contain;
        padding: 3px;
        flex-shrink: 0;
    }
    .gchat-header-title { flex: 1; min-width: 0; }
    .gchat-header-title h4 { margin: 0; font-size: 15px; font-weight: 600; }
    .gchat-header-title span { font-size: 11px; opacity: 0.85; display: block; }
    .gchat-close {
        background: rgba(255,255,255,0.2);
        border: none;
        color: #fff;
        width: 28px;
        height: 28px;
        border-radius: 50%;
        cursor: pointer;
        font-size: 16px;
        line-height: 1;
    }
    .gchat-close:hover { background: rgba(255,255,255,0.35); }

    #gchat-messages {
        flex: 1;
        overflow-y: auto;
        padding: 14px;
        background: #f5f6fa;
        display: flex;
        flex-direction: column;
        gap: 10px;
    }
    .gchat-msg {
        max-width: 85%;
        padding: 10px 13px;
        border-radius: 14px;
        font-size: 13.5px;
        line-height: 1.45;
        white-space: pre-wrap;
        word-wrap: break-word;
    }
    .gchat-msg.gchat-bot {
        background: #fff;
        color: #2d3748;
        align-self: flex-start;
        border-bottom-left-radius: 4px;
        box-shadow: 0 1px 3px rgba(0,0,0,0.08);
    }
    .gchat-msg.gchat-user {
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        color: #fff;
        align-self: flex-end;
        border-bottom-right-radius: 4px;
    }
    .gchat-links {
        display: flex;
        flex-direction: column;
        gap: 6px;
        align-self: flex-start;
        max-width: 85%;
    }
    .gchat-links a {
        display: inline-block;
        background: #fff;
        color: #667eea;
        border: 1.5px solid #667eea;
        border-radius: 20px;
        padding: 7px 14px;
        font-size: 12.5px;
        font-weight: 600;
        text-decoration: none;
        transition: all 0.2s;
    }
    .gchat-links a:hover { background: #667eea; color: #fff; }

    #gchat-suggestions {
        display: flex;
        gap: 6px;
        padding: 8px 12px;
        overflow-x: auto;
        background: #f5f6fa;
        border-top: 1px solid #e2e8f0;
        flex-shrink: 0;
    }
    #gchat-suggestions button {
        flex-shrink: 0;
        background: #edf2ff;
        color: #4c51bf;
        border: 1px solid #c3dafe;
        border-radius: 16px;
        padding: 6px 12px;
        font-size: 12px;
        cursor: pointer;
        white-space: nowrap;
    }
    #gchat-suggestions button:hover { background: #c3dafe; }

    .gchat-input-row {
        display: flex;
        gap: 8px;
        padding: 10px 12px;
        background: #fff;
        border-top: 1px solid #e2e8f0;
    }
    #gchat-input {
        flex: 1;
        border: 1.5px solid #e2e8f0;
        border-radius: 22px;
        padding: 9px 15px;
        font-size: 13.5px;
        outline: none;
        font-family: inherit;
    }
    #gchat-input:focus { border-color: #667eea; }
    #gchat-send {
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        color: #fff;
        border: none;
        width: 40px;
        height: 40px;
        border-radius: 50%;
        cursor: pointer;
        font-size: 16px;
        flex-shrink: 0;
    }
    #gchat-send:hover { opacity: 0.9; }

    .gchat-typing {
        align-self: flex-start;
        background: #fff;
        border-radius: 14px;
        padding: 12px 16px;
        box-shadow: 0 1px 3px rgba(0,0,0,0.08);
        display: flex;
        gap: 4px;
    }
    .gchat-typing span {
        width: 7px;
        height: 7px;
        background: #a0aec0;
        border-radius: 50%;
        animation: gchatBounce 1.2s infinite;
    }
    .gchat-typing span:nth-child(2) { animation-delay: 0.15s; }
    .gchat-typing span:nth-child(3) { animation-delay: 0.3s; }
    @keyframes gchatBounce {
        0%, 60%, 100% { transform: translateY(0); }
        30% { transform: translateY(-5px); }
    }

    @media (max-width: 480px) {
        #gchat-panel { right: 16px; bottom: 90px; width: calc(100vw - 32px); }
        #gchat-fab { right: 16px; bottom: 16px; }
    }
</style>

<button id="gchat-fab" title="GATEE Assistant - Chat with us" onclick="gchatToggle()">
    <img src="<%= request.getContextPath() %>/Document/GATEE LOGO.png?v=2" alt="GATEE Assistant">
    <span class="gchat-fab-badge"></span>
</button>

<div id="gchat-panel">
    <div class="gchat-header">
        <img src="<%= request.getContextPath() %>/Document/GATEE LOGO.png?v=2" alt="GATEE Logo">
        <div class="gchat-header-title">
            <h4>GATEE Assistant</h4>
            <span>GATEE सहाय्यक • Online</span>
        </div>
        <button class="gchat-close" onclick="gchatToggle()" title="Close">&times;</button>
    </div>
    <div id="gchat-messages"></div>
    <div id="gchat-suggestions"></div>
    <div class="gchat-input-row">
        <input type="text" id="gchat-input" placeholder="Type your question..."
               onkeydown="if(event.key==='Enter'){gchatSend();}" maxlength="500">
        <button id="gchat-send" onclick="gchatSend()" title="Send">&#10148;</button>
    </div>
</div>

<script>
(function() {
    window.gchatCtx = '<%= request.getContextPath() %>';
    window.gchatStarted = false;
})();

function gchatToggle() {
    var panel = document.getElementById('gchat-panel');
    var open = panel.classList.toggle('gchat-open');
    if (open && !window.gchatStarted) {
        window.gchatStarted = true;
        gchatShowTyping();
        fetch(window.gchatCtx + '/chatbot')
            .then(function(r) { return r.json(); })
            .then(gchatRenderBot)
            .catch(gchatRenderError);
    }
    if (open) {
        setTimeout(function() { document.getElementById('gchat-input').focus(); }, 100);
    }
}

function gchatSend(text) {
    var input = document.getElementById('gchat-input');
    var msg = (text !== undefined) ? text : input.value.trim();
    if (!msg) return;
    input.value = '';

    gchatAddMsg(msg, 'gchat-user');
    gchatShowTyping();

    var params = new URLSearchParams();
    params.append('message', msg);

    fetch(window.gchatCtx + '/chatbot', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: params.toString()
    })
    .then(function(r) {
        if (r.status === 401) { window.location.href = window.gchatCtx + '/login'; return null; }
        return r.json();
    })
    .then(function(data) { if (data) gchatRenderBot(data); })
    .catch(gchatRenderError);
}

function gchatRenderBot(data) {
    gchatHideTyping();
    gchatAddMsg(data.reply, 'gchat-bot');

    if (data.links && data.links.length > 0) {
        var box = document.createElement('div');
        box.className = 'gchat-links';
        data.links.forEach(function(l) {
            var a = document.createElement('a');
            a.href = l.url;
            a.textContent = l.label;
            box.appendChild(a);
        });
        document.getElementById('gchat-messages').appendChild(box);
    }

    if (data.suggestions) {
        var sug = document.getElementById('gchat-suggestions');
        sug.innerHTML = '';
        data.suggestions.forEach(function(s) {
            var b = document.createElement('button');
            b.type = 'button';
            b.textContent = s;
            b.onclick = function() { gchatSend(s); };
            sug.appendChild(b);
        });
    }
    gchatScroll();
}

function gchatRenderError() {
    gchatHideTyping();
    gchatAddMsg('Sorry, I could not connect to the server. Please check your connection and try again.', 'gchat-bot');
    gchatScroll();
}

function gchatAddMsg(text, cls) {
    var div = document.createElement('div');
    div.className = 'gchat-msg ' + cls;
    div.textContent = text;
    document.getElementById('gchat-messages').appendChild(div);
    gchatScroll();
}

function gchatShowTyping() {
    gchatHideTyping();
    var t = document.createElement('div');
    t.className = 'gchat-typing';
    t.id = 'gchat-typing';
    t.innerHTML = '<span></span><span></span><span></span>';
    document.getElementById('gchat-messages').appendChild(t);
    gchatScroll();
}

function gchatHideTyping() {
    var t = document.getElementById('gchat-typing');
    if (t) t.remove();
}

function gchatScroll() {
    var m = document.getElementById('gchat-messages');
    m.scrollTop = m.scrollHeight;
}
</script>
<% } %>
