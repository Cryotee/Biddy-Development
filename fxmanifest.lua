fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Cryotee'
description 'FiveM Hooker Script'
version '1.1'

escrow_ignore {
    'config.lua',
    'Readme.md',
    'install/items.lua',
    'install/setup.sql'
}

shared_scripts {
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

dependencies {
    'qb-core',
    'oxmysql'
}

dependency '/assetpacks'
