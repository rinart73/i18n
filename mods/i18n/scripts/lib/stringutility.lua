local status, config = pcall(require, "mods/i18n/config/i18nConfig")
if not status then
    eprint("[ERROR][i18n]: Couldn't load config, using default settings")
    config = { LogLevel = 1, SecondaryLanguages = { "en" } }
end

local LogLevel = { Error = 1, Warn = 2, Info = 3, Debug = 4 }
local logLevelLabel = { "ERROR", "WARN", "INFO", "DEBUG" }
local function log(level, msg, ...)
    if level > config.LogLevel then return end
    if level == LogLevel.Error then
      eprint(string.format("[%s][i18n]: "..msg, logLevelLabel[level], ...))
    else
      print(string.format("[%s][i18n]: "..msg, logLevelLabel[level], ...))
    end
end

i18n = {}

local L10n = {} -- table that contains all loaded translations
local localizedMods = {} -- array of mods that use i18n, where each key is modname
local languages = config.SecondaryLanguages -- use first lang code in 'SecondaryLanguages' for server
if getCurrentLanguage ~= nil then -- use getCurrentLanguage() result as first lang code for client
    local lang = getCurrentLanguage()
    for k, v in ipairs(languages) do
        if v == lang then
            table.remove(languages, k) -- remove duplicate lang code
            break
        end
    end
    table.insert(languages, 1,  lang)
end

local oldInterp -- save old interp
local function newInterp(s, tab)
    if tab or not L10n[s] then
        return oldInterp(s, tab)
    end
    return L10n[s]
end

-- Register mod and load it's localization
function i18n.registerMod(modname, custompath) -- ModName -> mods/ModName/localization
    if not status then
        return 1
    end
    log(LogLevel.Debug, "Trying to load translation for mod '%s'", modname)
    if localizedMods[modname] then -- don't register mod twice
        return 2
    end
    localizedMods[modname] = true
    -- try to load translation files
    local s, translation, path
    for i = 1, #languages do
        path = custompath and custompath..languages[i] or "mods/"..modname.."/localization/"..languages[i]
        s, translation = pcall(require, path)
        if not s then -- now 'translation' contains the reason why file wasn't loaded
            log(LogLevel.Info, "Can't load localization files for mod '%s' - %s", modname, translation)
        else
            break
        end
    end
    if not s then
        -- if there is an actual error
        if not translation or not translation:match("^[^\r\n]+not found:[\r\n]+") then
            return 3, translation
        end
        -- if file wasn't found
        return 4
    end

    for k, v in pairs(translation) do
        L10n[k] = v
    end
    if oldInterp == nil then -- override interp
        oldInterp = getmetatable("").__mod
        getmetatable("").__mod = newInterp
    end
    return 0
end

-- Get list of all mods that tried or succeeded in calling 'i18n.registerMod'
function i18n.getMods()
    local r = {}
    for k,_ in pairs(localizedMods) do
        r[#r+1] = k
    end
    return r
end