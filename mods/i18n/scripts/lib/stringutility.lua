--[[ This mod was developed to provide easy way of internationalization for mods and also to show devs that we REALLY need built-in 'getGameLanguage()' function.

The following code heavilly relies on the hope that settings.ini, current clientlog and mod helper file are accessible.

The main problem is that if player's Steam language is English, game will not write 'Setting language file' in clientlog, because there is no need to load localization files for English. This can mess up everything, especially if player changes language in menu without restarting the game.

Of course, I can just use 'if "Quit"%_t == "Beenden" then lang = "de" end ..' (simpleMode) and so on for every language. But this means I need to add a new check every time devs add new language, it can break in the future if few languages will have the same translation e.t.c.
Also it's not as fun :) ]]

local s, config = pcall(require, "mods/i18n/config/i18nconfig")
if not s then
    config = { langCode = "auto", logLevel = 1, detectMode = "optimal" } -- default settings
end
config.langCode = config.langCode:lower()
config.detectMode = config.detectMode:lower()

local lang = config.langCode ~= "auto" and config.langCode or nil
local firstRegistered = false
local L10n = {}
local mods = {}

i18n = {}

local function log(lvl, msg, ...)
    if lvl > config.logLevel then return end

    if lvl == 1 then lvl = "[ERROR]"
    elseif lvl == 2 then lvl = "[INFO]"
    else lvl = "[DEBUG]" end

    print(string.format("%s%s: "..msg, "[i18n]", lvl, ...))
end

-- we need to save last language change time to work with language=steam case
local function helperSetData(timestamp, lang, isSteam)
    local f = io.open("i18n.txt", "w+b")
    if f == nil then
        log(1, "can't open i18n.txt")
        return
    end
    f:write(timestamp, "\r\n", lang, "\r\n", isSteam or "0")
    f:close()
end

local function helperGetData()
    local f = io.open("i18n.txt", "r")
    if not f then
        helperSetData(0, "en")
        return {"0", "en", "0"}
    end
    local result = {}
    for line in f:lines() do result[#result+1] = line end
    f:close()    
    return result
end

function i18n.detectLanguage()
    if config.detectMode ~= "simple" then

      local time = os.time()
      local startTime = time - math.floor(appTime()) -- approximate game start time (clientlog had to be created in that time)
      local open = io.open

      -- Try to get language from settings.ini (language=ru)
      local f = open("settings.ini", "rb")
      if f ~= nil then      
          local content = f:read("*a")
          f:close()

          local lang = content:gmatch('language=([%a-]+)')()
          if lang ~= nil then
              if lang ~= "steam" then -- we're lucky, game is not using steam language
                  helperSetData(startTime, lang)
                  log(3, "settings.ini - language is: %s", lang)
                  return lang
              elseif config.detectMode == "full" then -- Try to use clientlog              
                  local lines = helperGetData()
                  if lines ~= nil and #lines > 2 then
                      local prevTime = tonumber(lines[1])
                      local prevLang = lines[2]
                      local isSteam = lines[3]

                      if isSteam == "1" and prevTime > startTime then -- we already detected what language=steam means during this game launch
                          helperSetData(time, prevLang, 1)
                          log(3, "steam language was already detected: %s", prevLang)
                          return prevLang
                      end

                      local logname = os.date("clientlog %Y-%m-%d %H-%M-%S.txt", startTime)
                      f = open(logname, "rb")
                      if f == nil then -- Due to the fact that os.time gives no miliseconds we can try to subtract 1 second to find client log
                          log(3, "try to subtract 1 sec to find clientlog")
                          logname = os.date("clientlog %Y-%m-%d %H-%M-%S.txt", startTime-1)
                          f = open(logname, "rb")
                      end

                      if f ~= nil then
                          local content = f:read("*a")
                          f:close()

                          --[[ Slowest part of entire code, especially if this is first load during game session.
                            If Steam language is English, there will be no 'setting language' in the clientlog and regex will take up to 0.8 second on my PC
                            Thanks to the helper file, this will only happen in the first time.
                          ]]
                          local y, m, d, H, M, S, lang = content:gmatch('.*\n(%d+)-(%d+)-(%d+) (%d+)-(%d+)-(%d+)|[^\n]+Setting language file "data[/\\]localization[/\\]([%a-]+)%.po')()
                          if lang ~= nil then
                              if lang == "deutsch" then lang = "de" end

                              local newTime = os.time{year=y, month=m, day=d, hour=H, minute=M, second=S}
                              if newTime > prevTime then -- found new 'setting language'
                                  helperSetData(time, lang, 1)
                                  log(3, "found 'new' language: %s", lang)
                                  return lang
                              else -- can't find 'new' 'setting language', then language=steam means english
                                  helperSetData(time, "en", 1)
                                  log(3, "can't find 'new' language, assuming it's english")
                                  return "en"
                              end
                          else -- if we can't find 'setting language', language=steam means english
                              helperSetData(time, "en", 1)
                              log(2, "can't find language in clientlog, assuming it's english")
                              return "en"
                          end
                      else log(1, "can't find or open clientlog") end
                  else
                      helperSetData(0, "en")
                      log(1, "can't open i18n.txt")
                  end
              end
          else log(1, "can't find language in settings.ini") end
      else log(1, "can't open settings.ini") end

    end
    -- Try localized string
    local s = GetLocalizedString("Quit")
    local lang
    if s == "Beenden" then lang = "de"
    elseif s == "Выход" then lang = "ru"
    elseif s == "退出游戏" then lang = "zh"
    elseif s == "退出" then lang = "zh-hk"
    else lang = "en" end

    log(3, "Language is '%s' based on localized string '%s'", lang, s)
    return lang
end

function i18n.getLanguage()
    if lang == nil then
        local t
        if config.logLevel > 2 then t = appTime() end
        lang = i18n.detectLanguage()
        if config.logLevel > 2 then
            t = appTime() - t
            log(3, "detected language in %f seconds", t)
        end
    end
    return lang
end

local oldInterp
local function newInterp(s, tab)
    if tab or not L10n[s] then
        return oldInterp(s, tab)
    end
    return L10n[s]
end

local function setNewInterp() -- override % operator only if mod was registered
    oldInterp = getmetatable("").__mod
    getmetatable("").__mod = newInterp
end

function i18n.registerMod(modname) -- ModName -> mods/ModName/localization
    if mods[modname] then return end -- don't register mod twice

    if lang == nil then
        local t
        if config.logLevel > 2 then t = appTime() end
        lang = i18n.detectLanguage()
        if config.logLevel > 2 then
            t = appTime() - t
            log(3, "detected language in %f seconds", t)
        end
    end
    
    mods[modname] = true
    
    local s, r = pcall(require, "mods/"..modname.."/localization/"..lang)
    if not s then
        return false, r
    end
    if not firstRegistered then
        firstRegistered = true
        setNewInterp()
    end
    for k,v in pairs(r) do
        L10n[k] = v
    end
    return true
end