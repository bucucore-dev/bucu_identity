-- ============================================================================
-- BUCU Identity — Server Main
-- Handles: character creation, skin storage, starter pack, multi-framework bridge
-- Supports: BucuCore, QBCore, ESX, QBox, Standalone
-- ============================================================================

-- ─── Framework Detection ────────────────────────────────────────────────────

local Framework = nil
local FrameworkName = 'standalone'

CreateThread(function()
    -- Detect active framework
    if GetResourceState('qb-core') == 'started' then
        Framework = exports['qb-core']:GetCoreObject()
        FrameworkName = 'qbcore'
        print('^2[bucu_identity]^7 Framework detected: ^3QBCore^7')
    elseif GetResourceState('qbx_core') == 'started' then
        Framework = exports.qbx_core
        FrameworkName = 'qbox'
        print('^2[bucu_identity]^7 Framework detected: ^3QBox^7')
    elseif GetResourceState('es_extended') == 'started' then
        Framework = exports['es_extended']:getSharedObject()
        FrameworkName = 'esx'
        print('^2[bucu_identity]^7 Framework detected: ^3ESX^7')
    elseif GetResourceState('bucu_core') == 'started' then
        FrameworkName = 'bucu'
        print('^2[bucu_identity]^7 Framework detected: ^3BucuCore^7')
    else
        print('^3[bucu_identity]^7 No framework detected. Running in Standalone mode.')
    end
end)

-- ─── Helpers ────────────────────────────────────────────────────────────────

local function GetPlayerLicense(source)
    if GetPlayerIdentifierByType then
        local lic = GetPlayerIdentifierByType(source, 'license')
        if lic and lic ~= '' then
            return (string.sub(lic, 1, 8) == 'license:') and lic or ('license:' .. lic)
        end
        local lic2 = GetPlayerIdentifierByType(source, 'license2')
        if lic2 and lic2 ~= '' then
            return (string.sub(lic2, 1, 9) == 'license2:') and lic2 or ('license2:' .. lic2)
        end
    end

    for i = 0, GetNumPlayerIdentifiers(source) - 1 do
        local id = GetPlayerIdentifier(source, i)
        if id and string.sub(id, 1, 8) == 'license:' then
            return id
        end
    end
    for i = 0, GetNumPlayerIdentifiers(source) - 1 do
        local id = GetPlayerIdentifier(source, i)
        if id and string.sub(id, 1, 9) == 'license2:' then
            return id
        end
    end
    for i = 0, GetNumPlayerIdentifiers(source) - 1 do
        local id = GetPlayerIdentifier(source, i)
        if id and string.sub(id, 1, 6) == 'steam:' then
            return id
        end
    end
    local first = GetPlayerIdentifier(source, 0)
    if first and first ~= '' then return first end
    return 'license:' .. tostring(source)
end

local function IsValidName(name)
    if not name or type(name) ~= 'string' then return false end
    local clean = name:match('^%s*(.-)%s*$')
    if #clean < 2 or #clean > 25 then return false end
    return clean:match('^[%a%s%-]+$') ~= nil
end

local function IsValidDOB(dob)
    if not dob or type(dob) ~= 'string' then return false end
    local y, m, d = dob:match('^(%d%d%d%d)-(%d%d)-(%d%d)$')
    if not y then return false end
    local year, month, day = tonumber(y), tonumber(m), tonumber(d)
    if month < 1 or month > 12 or day < 1 or day > 31 then return false end
    local age = 2026 - year
    return age >= (IdentityConfig.MinAge or 18) and age <= (IdentityConfig.MaxAge or 90)
end

local function GenerateCitizenId()
    if BucuSharedHelpers and BucuSharedHelpers.GenerateCitizenNumber then
        return BucuSharedHelpers.GenerateCitizenNumber()
    end
    -- Fallback generator
    local charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    local id = 'BUCU-'
    for i = 1, 6 do
        local rnd = math.random(1, #charset)
        id = id .. charset:sub(rnd, rnd)
    end
    return id
end

-- ─── Framework: Load Player Session ─────────────────────────────────────────

local function LoadPlayerSession(src, charIdentifier, citizenId, slot)
    if FrameworkName == 'bucu' then
        -- BucuCore native
        if BucuPlayerStorage and BucuPlayerStorage.LoadPlayer then
            BucuPlayerStorage.LoadPlayer(src, charIdentifier)
        end
        TriggerEvent('bucu:player:loaded', src, {
            identifier = charIdentifier,
            citizenid  = citizenId,
            slot       = slot
        })

    elseif FrameworkName == 'qbcore' and Framework then
        -- QBCore: login with citizenid
        Framework.Player.Login(src, citizenId)
        QBCore = Framework
        TriggerClientEvent('QBCore:Client:OnPlayerLoaded', src)

    elseif FrameworkName == 'qbox' then
        -- QBox: use exports
        TriggerEvent('qbx_core:server:playerLoaded', src, citizenId)

    elseif FrameworkName == 'esx' and Framework then
        -- ESX: trigger player load
        TriggerEvent('esx:playerLoaded', src, Framework.GetPlayerFromId(src))

    else
        -- Standalone: trigger bucu events as best effort
        TriggerEvent('bucu:player:loaded', src, {
            identifier = charIdentifier,
            citizenid  = citizenId,
            slot       = slot
        })
    end
end

-- ─── Give Starter Items ──────────────────────────────────────────────────────

local function GiveStarterItems(src, citizenId, charData)
    -- Via bucu_inventory export (preferred)
    if exports and exports['bucu_inventory'] then
        local idCardMeta = {
            name         = charData.firstname .. ' ' .. charData.lastname,
            citizenid    = citizenId,
            date_of_birth= charData.dob,
            gender       = charData.gender,
            issued_date  = os.date('!%Y-%m-%d')
        }
        exports['bucu_inventory']:AddItem(citizenId, 'id_card',      1, 1, idCardMeta, 'pocket')
        exports['bucu_inventory']:AddItem(citizenId, 'phone',        1, 2, nil,        'pocket')
        exports['bucu_inventory']:AddItem(citizenId, 'bread',        2, 3, nil,        'pocket')
        exports['bucu_inventory']:AddItem(citizenId, 'water_bottle', 2, 4, nil,        'pocket')
        return
    end

    -- QBCore fallback
    if FrameworkName == 'qbcore' and Framework then
        local Player = Framework.Functions.GetPlayer(src)
        if Player then
            local starterItems = IdentityConfig.StarterPack.Items or {}
            for _, v in ipairs(starterItems) do
                local info = {}
                if v.name == 'id_card' then
                    info.citizenid    = citizenId
                    info.firstname    = charData.firstname
                    info.lastname     = charData.lastname
                    info.birthdate    = charData.dob
                    info.gender       = charData.gender
                    info.nationality  = charData.nationality
                end
                Player.Functions.AddItem(v.name, v.count, false, info)
            end
        end
    end
end

-- ─── Create Accounts & Job (BucuCore DB) ────────────────────────────────────

local function SetupNewCharacterDB(charId, citizenId)
    if not MySQL or not MySQL.execute then return end

    local cash = (IdentityConfig.StarterPack and IdentityConfig.StarterPack.Cash) or 1000
    local bank = (IdentityConfig.StarterPack and IdentityConfig.StarterPack.Bank) or 5000

    MySQL.execute("INSERT IGNORE INTO bucu_accounts (character_id, account_type, balance) VALUES (?, 'cash', ?)",  { charId, cash })
    MySQL.execute("INSERT IGNORE INTO bucu_accounts (character_id, account_type, balance) VALUES (?, 'bank', ?)",  { charId, bank })
    MySQL.execute("INSERT IGNORE INTO bucu_jobs (character_id, job_name, job_grade, on_duty) VALUES (?, 'unemployed', 0, 1)", { charId })
    MySQL.execute("INSERT IGNORE INTO bucu_player_needs (citizenid, hunger, thirst, stress) VALUES (?, 100.0, 100.0, 0.0)", { citizenId })
end

-- ─── Save Skin Data ──────────────────────────────────────────────────────────

local function SaveSkinToDB(citizenId, skinData)
    if not MySQL or not MySQL.execute then return end

    local skinJson = json and json.encode and json.encode(skinData) or '{}'
    local model    = (skinData and skinData.model) or 'mp_m_freemode_01'

    MySQL.execute([[
        INSERT INTO bucu_player_skins (citizenid, model, skin_data)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE model = VALUES(model), skin_data = VALUES(skin_data)
    ]], { citizenId, model, skinJson })
end

-- ─── Net Events ─────────────────────────────────────────────────────────────

-- Called by bucu_multicharacter when a new character slot is selected
RegisterNetEvent('bucu:identity:server:openCreator', function(slot)
    local src = source
    TriggerClientEvent('bucu:identity:client:openCreator', src, { slot = slot })
end)

-- Main handler: save new character with identity + skin
RegisterNetEvent('bucu:identity:server:saveCharacter', function(payload)
    local src = source

    -- Validate payload
    if not payload or not payload.identity or not payload.skin then
        TriggerClientEvent('bucu:notify:show', src, { type = 'error', text = _U('err_server') })
        return
    end

    local identity = payload.identity
    local skinData = payload.skin
    local slot     = tonumber(payload.slot) or 1

    -- Validate inputs
    if not IsValidName(identity.firstname) or not IsValidName(identity.lastname) then
        TriggerClientEvent('bucu:notify:show', src, { type = 'error', text = _U('err_invalid_name') })
        return
    end
    if not IsValidDOB(identity.dob) then
        TriggerClientEvent('bucu:notify:show', src, { type = 'error', text = _U('err_invalid_dob') })
        return
    end

    local gender       = (identity.gender == 'female') and 'female' or 'male'
    local license      = GetPlayerLicense(src)
    local charId_str   = string.format('%s:%d', license, slot)
    local citizenId    = GenerateCitizenId()
    local nationality  = identity.nationality or 'San Andreas'

    local avatarUrl    = identity.avatar or 'images/default_avatar.png'

    local initialMeta = json and json.encode({
        citizenid    = citizenId,
        nationality  = nationality,
        avatar       = avatarUrl,
        created_at   = os.date('!%Y-%m-%d %H:%M:%SZ')
    }) or '{}'

    -- For non-BucuCore frameworks that use their own DB schema, insert directly
    if FrameworkName == 'qbcore' and Framework then
        -- QBCore: use QBCore.Player.Login with new char data
        local newData = {
            cid      = slot,
            charinfo = {
                firstname   = identity.firstname,
                lastname    = identity.lastname,
                birthdate   = identity.dob,
                gender      = (identity.gender == 'female') and 1 or 0,
                nationality = nationality
            }
        }
        if Framework.Player.Login(src, false, newData) then
            local Player  = Framework.Functions.GetPlayer(src)
            local qbCitId = Player and Player.PlayerData and Player.PlayerData.citizenid or citizenId
            -- Save skin
            SaveSkinToDB(qbCitId, skinData)
            GiveStarterItems(src, qbCitId, identity)
            TriggerClientEvent('bucu:notify:show', src, { type = 'success', text = _U('notif_char_created') })
            TriggerClientEvent('bucu:identity:client:onCharCreated', src, { slot = slot, citizenid = qbCitId })
        end
        return
    end

    -- BucuCore / ESX / QBox / Standalone: use bucu_characters table
    if not MySQL or not MySQL.insert then
        -- No DB, just trigger client
        TriggerClientEvent('bucu:identity:client:onCharCreated', src, {
            slot      = slot,
            citizenid = citizenId,
            firstname = identity.firstname,
            lastname  = identity.lastname,
            gender    = gender,
            model     = skinData.model or (gender == 'female' and 'mp_f_freemode_01' or 'mp_m_freemode_01'),
            skin      = skinData
        })
        return
    end

    -- Clean up any stale records on this slot to prevent collision/failure
    MySQL.execute('DELETE FROM bucu_characters WHERE identifier = ?', { charId_str }, function()
        MySQL.insert([[
            INSERT INTO bucu_characters (identifier, firstname, lastname, date_of_birth, gender, metadata)
            VALUES (?, ?, ?, ?, ?, ?)
        ]], {
            charId_str,
            identity.firstname,
            identity.lastname,
            identity.dob,
            gender,
            initialMeta
        }, function(charId)
            if not charId or charId <= 0 then
                TriggerClientEvent('bucu:notify:show', src, { type = 'error', text = _U('err_slot_occupied') })
                return
            end

            -- Setup DB records (accounts, jobs, needs)
            SetupNewCharacterDB(charId, citizenId)
            -- Save skin to bucu_player_skins
            SaveSkinToDB(citizenId, skinData)
            -- Give starter items to inventory
            GiveStarterItems(src, citizenId, { firstname = identity.firstname, lastname = identity.lastname, dob = identity.dob, gender = gender, nationality = nationality })

            -- Notify client
            TriggerClientEvent('bucu:notify:show', src, { type = 'success', text = _U('notif_char_created') })

            LoadPlayerSession(src, charId_str, citizenId, slot)

            -- Sync state bag to player entity
            Player(src).state:set('citizenid', citizenId, true)
            Player(src).state:set('charIdentifier', charId_str, true)

            TriggerClientEvent('bucu:identity:client:onCharCreated', src, {
                slot      = slot,
                citizenid = citizenId,
                firstname = identity.firstname,
                lastname  = identity.lastname,
                gender    = gender,
                model     = skinData.model or (gender == 'female' and 'mp_f_freemode_01' or 'mp_m_freemode_01'),
                skin      = skinData
            })

            -- Notify multicharacter system
            TriggerEvent('bucu:player:loaded', src, {
                identifier = charId_str,
                citizenid  = citizenId,
                slot       = slot
            })
        end)
    end)
end)

-- ─── Server Exports ──────────────────────────────────────────────────────────

-- Get skin data for a citizenid
exports('GetSkin', function(citizenId)
    if not MySQL or not MySQL.query then return nil end
    local result = MySQL.query.await('SELECT model, skin_data FROM bucu_player_skins WHERE citizenid = ?', { citizenId })
    if result and result[1] then
        local skinData = {}
        pcall(function() skinData = json.decode(result[1].skin_data) end)
        return result[1].model, skinData
    end
    return nil, nil
end)

-- Save skin data
exports('SaveSkin', function(citizenId, skinData)
    SaveSkinToDB(citizenId, skinData)
end)

-- ─── Skin Request (on spawn) ─────────────────────────────────────────────────

RegisterNetEvent('bucu:identity:server:requestSkin', function(citizenId)
    local src = source
    if not MySQL or not MySQL.query then return end

    MySQL.query('SELECT model, skin_data FROM bucu_player_skins WHERE citizenid = ?', { citizenId }, function(result)
        if result and result[1] then
            local skinData = {}
            pcall(function() skinData = json.decode(result[1].skin_data) end)
            TriggerClientEvent('bucu:identity:client:applySkin', src, result[1].model, skinData)
        end
    end)
end)

print('^2[bucu_identity]^7 Server loaded successfully.')
