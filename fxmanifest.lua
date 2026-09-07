fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'bucu_identity'
author 'BUCU SuperApp Team'
description 'Premium Character Creator — Face Morphing, Clothing & Identity Registration for BucuCore (QBCore/ESX/QBox/Standalone compatible)'
version '1.0.0'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/css/style.css',
    'html/js/app.js'
}

shared_scripts {
    '@bucu_shared/shared/constants.lua',
    '@bucu_shared/shared/config.lua',
    '@bucu_shared/shared/helpers.lua',
    'locales/en.lua',
    'locales/id.lua',
    'config.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

client_scripts {
    'client/main.lua',
    'client/nui.lua'
}

client_exports {
    'OpenCreator',
    'ApplySkinData',
    'GetCurrentSkin'
}

server_exports {
    'GetSkin',
    'SaveSkin'
}
