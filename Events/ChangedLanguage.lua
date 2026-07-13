local Changed = {}

function Changed.ChangeLanguage(NewLanguage)
    CurrentLanguage = NewLanguage
    CurrentLanguageModule = require("translation/"..CurrentLanguage)
end

return Changed