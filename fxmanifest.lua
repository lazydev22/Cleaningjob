fx_version "adamant"
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
game "rdr3"

lua54 'yes'
author "dsml"
description "A repeatable cleaning job for vorpcore framework"

shared_scripts {
    'config.lua'
}
client_scripts {
    'client/uiprompt.lua',
    'client/client.lua'
}
server_scripts {
    'server/server.lua'
}
files {
    'ui/index.html',
    'ui/bundle/*',
    'ui/assets/*',
    'ui/assets/fonts/*'
}
ui_page 'ui/index.html'

-- dsml_security is a hard dependency -- the shared rate-limit/validation/suspicious-logging
-- toolkit server/server.lua's GetJob/CleanSpot/FinishJob callbacks call into. Fail CLOSED on
-- missing security infra, not fail open.
dependencies {
    'dsml_progressbar',
    'vorp_animations',
    'dsml_security',
}

version '1.0'
