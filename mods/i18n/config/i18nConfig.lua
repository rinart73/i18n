local config = {}
config.author = "Rinart73"
config.name = "i18n"
config.homepage = "http://www.avorion.net/forum/index.php/topic,4330.msg22873.html"
config.version = {
    major = 1, minor = 1, patch = 0, -- 0.21.4
}
config.version.string = config.version.major..'.'..config.version.minor..'.'..config.version.patch


-- CLIENT SETTINGS --
-- Log only messages that have level equal or lower than specified
-- 0 - nothing, 1 - errors, 2 - warning, 3 - info, 4 - debug
config.LogLevel = 2

-- If mod doesn't have localization for your language, i18n will try to load other localization files in order that is specified in 'secondaryLanguages' parameter
config.SecondaryLanguages = { "en" }


return config