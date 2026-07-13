local Poki = {}
require("libs.js")
local json = require("libs.json")

function Poki.init(callback)
    JS.newPromiseRequest(
        JS.stringFunc([[
            (async () => {
                try {
                    await PokiSDK.init();
                    _$_("ok");
                } catch(e) {
                    _$_("error:" + (e && e.message ? e.message : e));
                }
            })();
        ]]),
        function(result)
            if result == "ok" then
                print("Poki SDK initialized")
                if callback then callback(true) end
            else
                print("Poki SDK init error:", result)
                if callback then callback(false) end
            end
        end,
        function(errId)
            print("Poki init timeout/error, request id:", errId)
            if callback then callback(false) end
        end
    )
end

function Poki.setDebug(enabled)
    if enabled then
        JS.callJS("PokiSDK.setDebug(true);")
    end
end

function Poki.loadingFinished()
    JS.callJS("PokiSDK.gameLoadingFinished();")
end

function Poki.gameplayStart()
    JS.callJS("PokiSDK.gameplayStart();")
end

function Poki.gameplayStop()
    JS.callJS("PokiSDK.gameplayStop();")
end

function Poki.saveProgress(key, data)
    local payload = json.encode(data)
    local safeKey = JS.escapeJSString(key)

    JS.newRequest(
        JS.stringFunc([[
            try {
                localStorage.setItem("%s", JSON.stringify(%s));
                return "ok";
            } catch(e) {
                return "error:" + (e && e.message ? e.message : e);
            }
        ]], safeKey, payload),
        function(result)
            if result and result:sub(1, 5) == "error" then
                print("Poki.saveProgress error:", result)
            end
        end,
        function(errId)
            print("Poki.saveProgress error, request id:", errId)
        end
    )
end

function Poki.loadProgress(key, callback)
    local safeKey = JS.escapeJSString(key)
    JS.newRequest(
        JS.stringFunc([[
            var v = localStorage.getItem("%s");
            return v;
        ]], safeKey),
        function(data)
            local decoded = nil
            if data and data ~= "" and data ~= "nil" then
                local ok, result = pcall(json.decode, data)
                decoded = ok and result or data
            end
            if callback then callback(decoded) end
        end,
        function(errId)
            print("Poki.loadProgress error, request id:", errId)
            if callback then callback(nil) end
        end
    )
end

function Poki.data_get(key, callback)
    Poki.loadProgress(key, callback)
end

function Poki.data_remove(key)
    local safeKey = JS.escapeJSString(key)
    JS.callJS(JS.stringFunc([[
        try { localStorage.removeItem("%s"); }
        catch(e) { console.log("Poki.data_remove error", e); }
    ]], safeKey))
end

function Poki.commercialBreak(callback)
    JS.newPromiseRequest(
        JS.stringFunc([[
            PokiSDK.commercialBreak().then(function() {
                _$_("done");
            }).catch(function(e) {
                _$_("error:" + (e && e.message ? e.message : e));
            });
        ]]),
        function(result)
            if callback then callback(result == "done") end
        end,
        function(errId)
            print("Poki.commercialBreak error, request id:", errId)
            if callback then callback(false) end
        end
    )
end

function Poki.rewardedBreak(onSuccess, onError)
    JS.newPromiseRequest(
        JS.stringFunc([[
            PokiSDK.rewardedBreak().then(function(withReward) {
                _$_(withReward ? "watched" : "skipped");
            }).catch(function(e) {
                _$_("error:" + (e && e.message ? e.message : e));
            });
        ]]),
        function(result)
            if result == "watched" then
                if onSuccess then onSuccess(true) end
            elseif result == "skipped" then
                if onSuccess then onSuccess(false) end
            else
                if onError then onError(result) end
            end
        end,
        function(errId)
            if onError then onError("request_failed:" .. tostring(errId)) end
        end
    )
end

function Poki.shareableURL(params, callback)
    params = params or "{}"

    JS.newPromiseRequest(
        JS.stringFunc([[
            PokiSDK.shareableURL(%s).then(function(url) {
                _$_(url);
            }).catch(function(e) {
                _$_("error:" + (e && e.message ? e.message : e));
            });
        ]], params),
        function(result)
            if callback then callback(result) end
        end,
        function(errId)
            print("Poki.shareableURL error, request id:", errId)
            if callback then callback(nil) end
        end
    )
end

function Poki.login(onSuccess, onError)
    JS.newPromiseRequest(
        JS.stringFunc([[
            (async () => {
                try {
                    await PokiSDK.login();
                    _$_("ok");
                } catch(e) {
                    _$_("error:" + (e && e.message ? e.message : e));
                }
            })();
        ]]),
        function(result)
            if result == "ok" then
                if onSuccess then onSuccess() end
            else
                if onError then onError(result) end
            end
        end,
        function(errId)
            if onError then onError("request_failed:" .. tostring(errId)) end
        end
    )
end

function Poki.getUser(callback)
    JS.newPromiseRequest(
        JS.stringFunc([[
            (async () => {
                try {
                    const user = await PokiSDK.getUser();
                    _$_(JSON.stringify(user));
                } catch(e) {
                    _$_("error:" + (e && e.message ? e.message : e));
                }
            })();
        ]]),
        function(result)
            if result and result:sub(1, 5) ~= "error" then
                local ok, decoded = pcall(json.decode, result)
                if callback then callback(ok and decoded or nil) end
            else
                print("Poki.getUser error:", result)
                if callback then callback(nil) end
            end
        end,
        function(errId)
            print("Poki.getUser error, request id:", errId)
            if callback then callback(nil) end
        end
    )
end

function Poki.getToken(callback)
    JS.newPromiseRequest(
        JS.stringFunc([[
            (async () => {
                try {
                    const token = await PokiSDK.getToken();
                    _$_(token || "");
                } catch(e) {
                    _$_("error:" + (e && e.message ? e.message : e));
                }
            })();
        ]]),
        function(result)
            if result and result:sub(1, 5) ~= "error" then
                if callback then callback(result ~= "" and result or nil) end
            else
                print("Poki.getToken error:", result)
                if callback then callback(nil) end
            end
        end,
        function(errId)
            print("Poki.getToken error, request id:", errId)
            if callback then callback(nil) end
        end
    )
end

return Poki