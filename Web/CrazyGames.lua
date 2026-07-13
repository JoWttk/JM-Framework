local CrazyGames = {}
local js = require("libs.js")
local json = require("libs.json")

function CrazyGames.init(callback)
    js.newPromiseRequest(
        js.stringFunc([[
            (async () => {
                try {
                    await window.CrazyGames.SDK.init();
                    _$_("ok");
                } catch(e) {
                    _$_("error:" + (e && e.message ? e.message : e));
                }
            })();
        ]]),
        function(result)
            if result == "ok" then
                print("CrazyGames Init done")
                if callback then callback(true) end
            else
                print("CrazyGames Init error:", result)
                if callback then callback(false) end
            end
        end,
        function(errId)
            print("CrazyGames Init timeout/error, request id:", errId)
            if callback then callback(false) end
        end
    )
end

function CrazyGames.loading(state)
    if type(state) ~= "string" then return end
    js.callJS("window.CrazyGames.SDK.game.loading" .. state .. "();")
end

function CrazyGames.gameplay(state)
    if type(state) ~= "string" then return end
    js.callJS("window.CrazyGames.SDK.game.gameplay" .. state .. "();")
end

function CrazyGames.data_add(key, value)
    local payload = json.encode(value)
    local safeKey = js.escapeJSString(key)

    js.callJS(js.stringFunc([[
        window.CrazyGames.SDK.data.setItem("%s", JSON.stringify(%s));
    ]], safeKey, payload))
end

function CrazyGames.data_remove(key)
    local safeKey = js.escapeJSString(key)
    js.callJS(js.stringFunc([[
        window.CrazyGames.SDK.data.removeItem("%s");
    ]], safeKey))
end

function CrazyGames.data_clear()
    js.callJS("window.CrazyGames.SDK.data.clear();")
end

function CrazyGames.data_get(key, callback)
    local safeKey = js.escapeJSString(key)
    js.newRequest(
        js.stringFunc([[
            var v = window.CrazyGames.SDK.data.getItem("%s");
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
            print("CrazyGames.data_get error, request id:", errId)
            if callback then callback(nil) end
        end
    )
end

function CrazyGames.getUser(callback)
    js.newPromiseRequest(
        js.stringFunc([[
            (async () => {
                try {
                    const user = await window.CrazyGames.SDK.user.getUser();
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
                print("CrazyGames.getUser error:", result)
                if callback then callback(nil) end
            end
        end,
        function(errId)
            print("CrazyGames.getUser error, request id:", errId)
            if callback then callback(nil) end
        end
    )
end

function CrazyGames.hasAdblock(callback)
    js.newPromiseRequest(
        js.stringFunc([[
            (async () => {
                try {
                    const result = await window.CrazyGames.SDK.ad.hasAdblock();
                    _$_(result ? "true" : "false");
                } catch(e) {
                    _$_("error:" + (e && e.message ? e.message : e));
                }
            })();
        ]]),
        function(result)
            if callback then callback(result == "true") end
        end,
        function(errId)
            print("CrazyGames.hasAdblock error, request id:", errId)
            if callback then callback(false) end
        end
    )
end

function CrazyGames.ad(adType, onFinished, onError)
    js.newPromiseRequest(
        js.stringFunc([[
            (async () => {
                try {
                    await new Promise((resolve, reject) => {
                        const callbacks = {
                            adStarted: () => console.log("Start ad"),
                            adFinished: () => { console.log("End ad"); resolve(); },
                            adError: (e) => { console.log("Error ad", e); reject(e); },
                        };
                        window.CrazyGames.SDK.ad.requestAd("%s", callbacks);
                    });
                    _$_("done");
                } catch(e) {
                    _$_("error:" + (e && e.message ? e.message : e));
                }
            })();
        ]], adType),
        function(result)
            if result == "done" then
                if onFinished then onFinished() end
            else
                print("CrazyGames.ad error:", result)
                if onError then onError(result) end
            end
        end,
        function(errId)
            print("CrazyGames.ad error, request id:", errId)
            if onError then onError(errId) end
        end
    )
end

return CrazyGames