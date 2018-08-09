local status, config = pcall(require, "mods/i18n/config/i18n")
if not status then
    config = { logLevel = 1, secondaryLanguages = { "en" } } -- default
    log(logLevel.Error, "Can't load config file (mods/i18n/config/i18n.lua)")
end

local logLevel = { Error = 1, Warn = 2, Info = 3, Debug = 4 }
local logLevelLabel = { "ERROR", "WARN", "INFO", "DEBUG" }
local function log(level, msg, ...)
    if level > config.logLevel then return end
    print(string.format("[%s][i18n]: "..msg, logLevelLabel[level], ...))
end

i18n = {}

local L10n = {} -- table that contains all loaded translations
local localizedMods = {} -- array of mods that use i18n, where each key is modname
local languages = config.secondaryLanguages -- use first lang code in 'secondaryLanguages' for server
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
function i18n.registerMod(modname) -- ModName -> mods/ModName/localization
    if not status then
        return 1
    end
    log(logLevel.Debug, "Trying to load translation for mod '%s'", modname)
    if localizedMods[modname] then -- don't register mod twice
        return 2
    end
    localizedMods[modname] = true
    -- try to load translation files
    local s, translation
    for i = 1, #languages do
        s, translation = pcall(require, "mods/"..modname.."/localization/"..languages[i])
        if not s then -- now 'translation' contains the reason why file wasn't loaded
            log(logLevel.Info, "Can't load localization files for mod '%s' - %s", modname, translation)
        else
            break
        end
    end
    if not s then
        return 3, translation
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