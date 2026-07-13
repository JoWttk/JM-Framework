local gcl = {}

require("GLOBALS")
local ffi = require("ffi")

ffi.cdef[[
    typedef struct SDL_Locale {
        const char *language;
        const char *country;
    } SDL_Locale;
    SDL_Locale *SDL_GetPreferredLocales(void);
    void SDL_free(void *mem);
]]

local function setLang(lang)
    local Settings = require("scenes.Settings")
    local change = require("translation.change")

    Settings.Language = lang
    ChangeLanguage:fire(lang)
end

function gcl.get()
    local sdl = ffi.os == "Windows" and ffi.load("SDL2") or ffi.C

    local locales = sdl.SDL_GetPreferredLocales()
    if locales ~= nil and locales[0].language ~= nil then
        local lang = ffi.string(locales[0].language)
        sdl.SDL_free(locales)

        setLang(lang)

        return lang
    end

    setLang("en")
    return "en"
end

return gcl