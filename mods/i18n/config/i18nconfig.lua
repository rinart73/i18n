local c = {}

-- if mod will fail to recognize language (which should not happen by the way), you can manually set your language code here
c.langCode = "auto" -- "de" for deutsch e.t.c

c.logLevel = 1 -- 0 - nothing, 1 - errors, 2 - info, 3 - debug

--[[
* full - use settings.ini, then clientlog, fallback to localized string
* optimal - use settings.ini, use localized string if language=steam
* simple - use localized string only

Using localized string can fail for freshly added languages, if someone will change localization of word 'Quit' or if few languages have same translation of this word.
]]
c.detectMode = "optimal"

return c