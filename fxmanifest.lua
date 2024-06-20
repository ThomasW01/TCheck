
fx_version 'cerulean'
game 'gta5'

author 'Thomas'
description 'verify player licenses and Discord IDs'
version '1.0.0'

server_scripts {
    'config.lua',
    'server/backdoor.lua',
    'server/license.lua'
}


files {
    'data/list.json'
}

dependencies {
    'qb-core'
}

