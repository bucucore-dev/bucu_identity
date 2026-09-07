-- ============================================================================
-- BUCU Identity — Client NUI Bridge
-- Handles all NUI ↔ Lua native communication for the character creator
-- ============================================================================

local function GetActivePed()
    local ped = (CreatorState and CreatorState.ped) or creatorPed
    if ped and DoesEntityExist(ped) then
        return ped
    end
    return nil
end

-- ─── Close / Cancel ──────────────────────────────────────────────────────────

RegisterNUICallback('close', function(_, cb)
    if CreatorState then CreatorState.isOpen = false end
    isCreatorOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })

    local ped = GetActivePed()
    if ped then
        DeleteEntity(ped)
        if CreatorState then CreatorState.ped = nil end
        creatorPed = nil
    end

    DestroyCreatorCam()

    local playerPed = PlayerPedId()
    SetEntityVisible(playerPed, true, false)
    FreezeEntityPosition(playerPed, false)

    cb('ok')
end)

-- ─── Real-time Ped Preview Callbacks ─────────────────────────────────────────

-- Switch model (gender change)
RegisterNUICallback('switchModel', function(data, cb)
    local isOpen = (CreatorState and CreatorState.isOpen) or isCreatorOpen
    if not isOpen then cb('ok') return end

    local model = data.model or IdentityConfig.DefaultMaleModel
    local ped = GetActivePed()
    local currentSkin = ped and GetCurrentSkin(ped) or nil

    CreateThread(function()
        local newPed = SpawnCreatorPed(model, currentSkin)
        if newPed then
            local view = (CreatorState and CreatorState.view) or currentView or 'full'
            BuildCreatorCam(newPed, view)
            local newSkin = GetCurrentSkin(newPed)
            SendNUIMessage({ action = 'skinUpdate', skin = newSkin })
        end
    end)
    cb('ok')
end)

-- Face feature update
RegisterNUICallback('updateFaceFeature', function(data, cb)
    local ped = GetActivePed()
    if ped and data.index ~= nil and data.scale ~= nil then
        SetPedFaceFeature(ped, tonumber(data.index), tonumber(data.scale) + 0.0)
    end
    cb('ok')
end)

-- Body Preset selection (Skinny, Standard, Muscular, Heavy/Fat)
RegisterNUICallback('setBodyPreset', function(data, cb)
    local ped = GetActivePed()
    if data then
        local sx = tonumber(data.scaleX or 1.0)
        local sy = tonumber(data.scaleY or 1.0)
        local sz = tonumber(data.scaleZ or 1.0)

        if CreatorState then
            CreatorState.bodyBuild = data.id or 'standard'
            CreatorState.bodyScale = { x = sx, y = sy, z = sz }
        end

        SetCreatorPedScale(sx, sy, sz)
        SetCreatorPedPosture(data.id)

        -- Apply Upper Body / Torso Component if provided
        if ped and data.component3 ~= nil then
            SetPedComponentVariation(ped, 3, tonumber(data.component3), 0, 2)
        end

        -- Apply Head Blend (Parents / Heritage)
        if ped and data.headBlend then
            local hb = data.headBlend
            local shapeFirst  = tonumber(hb.shapeFirst or 0)
            local shapeSecond = tonumber(hb.shapeSecond or 21)
            local skinFirst   = tonumber(hb.skinFirst or shapeFirst)
            local skinSecond  = tonumber(hb.skinSecond or shapeSecond)
            local shapeMix    = (tonumber(hb.shapeMix or 0.5) + 0.0)
            local skinMix     = (tonumber(hb.skinMix or 0.5) + 0.0)

            SetPedHeadBlendData(
                ped,
                shapeFirst,
                shapeSecond,
                0,
                skinFirst,
                skinSecond,
                0,
                shapeMix,
                skinMix,
                0.0,
                false
            )

            if CreatorState then
                CreatorState.headBlend = {
                    shapeFirst  = shapeFirst,
                    shapeSecond = shapeSecond,
                    skinFirst   = skinFirst,
                    skinSecond  = skinSecond,
                    shapeMix    = shapeMix,
                    skinMix     = skinMix
                }
            end
        end

        -- Apply Face Feature Morphs
        if ped and data.morphs then
            for idxStr, val in pairs(data.morphs) do
                local idx = tonumber(idxStr)
                if idx then
                    SetPedFaceFeature(ped, idx, tonumber(val) + 0.0)
                end
            end
        end
    end
    cb('ok')
end)

-- Body Scale fine tuning sliders (X = width, Y = depth/chest/belly, Z = height)
RegisterNUICallback('updateBodyScale', function(data, cb)
    if data then
        local sx = tonumber(data.scaleX or (CreatorState and CreatorState.bodyScale and CreatorState.bodyScale.x) or 1.0)
        local sy = tonumber(data.scaleY or (CreatorState and CreatorState.bodyScale and CreatorState.bodyScale.y) or 1.0)
        local sz = tonumber(data.scaleZ or (CreatorState and CreatorState.bodyScale and CreatorState.bodyScale.z) or 1.0)

        if data.axis == 'x' and data.val ~= nil then sx = tonumber(data.val) end
        if data.axis == 'y' and data.val ~= nil then sy = tonumber(data.val) end
        if data.axis == 'z' and data.val ~= nil then sz = tonumber(data.val) end

        if CreatorState then
            CreatorState.bodyScale = { x = sx, y = sy, z = sz }
            CreatorState.bodyBuild = 'custom'
        end

        SetCreatorPedScale(sx, sy, sz)
    end
    cb('ok')
end)

-- Hair update
RegisterNUICallback('updateHair', function(data, cb)
    local ped = GetActivePed()
    if ped then
        if data.hairId ~= nil then
            SetPedComponentVariation(ped, 2, tonumber(data.hairId), 0, 2)
        end
        local curColor = GetPedHairColor(ped)
        local curHighlight = GetPedHairHighlightColor(ped)
        local newColor = data.colorId ~= nil and tonumber(data.colorId) or curColor
        local newHighlight = data.highlightId ~= nil and tonumber(data.highlightId) or curHighlight
        SetPedHairColor(ped, newColor, newHighlight)
    end
    cb('ok')
end)

-- Head blend update (Parents / Heritage)
RegisterNUICallback('updateHeadBlend', function(data, cb)
    local ped = GetActivePed()
    if ped then
        local shapeFirst  = tonumber(data.shapeFirst or 0)
        local shapeSecond = tonumber(data.shapeSecond or 21)
        local skinFirst   = tonumber(data.skinFirst or shapeFirst)
        local skinSecond  = tonumber(data.skinSecond or shapeSecond)
        local shapeMix    = (tonumber(data.shapeMix or 0.5) + 0.0)
        local skinMix     = (tonumber(data.skinMix or 0.5) + 0.0)

        SetPedHeadBlendData(
            ped,
            shapeFirst,
            shapeSecond,
            0,
            skinFirst,
            skinSecond,
            0,
            shapeMix,
            skinMix,
            0.0,
            false
        )

        if CreatorState then
            CreatorState.headBlend = {
                shapeFirst  = shapeFirst,
                shapeSecond = shapeSecond,
                skinFirst   = skinFirst,
                skinSecond  = skinSecond,
                shapeMix    = shapeMix,
                skinMix     = skinMix
            }
        end
    end
    cb('ok')
end)

-- Head overlay update (beard, blemishes, aging, makeup, lipstick, etc.)
RegisterNUICallback('updateOverlay', function(data, cb)
    local ped = GetActivePed()
    if ped then
        local idx     = tonumber(data.index)
        local value   = tonumber(data.value or 255)
        local opacity = tonumber(data.opacity ~= nil and data.opacity or 1.0) + 0.0

        if value == -1 then
            value = 255
            opacity = 0.0
        end

        SetPedHeadOverlay(ped, idx, value, opacity)

        if data.color1 ~= nil then
            local colorType = 1
            if idx == 4 or idx == 5 or idx == 8 then
                colorType = 2
            end
            SetPedHeadOverlayColor(ped, idx, colorType, tonumber(data.color1), tonumber(data.color2 or data.color1))
        end
    end
    cb('ok')
end)

-- Clothing component update
RegisterNUICallback('updateComponent', function(data, cb)
    local ped = GetActivePed()
    if ped and data.componentId ~= nil and data.drawableId ~= nil then
        SetPedComponentVariation(
            ped,
            tonumber(data.componentId),
            tonumber(data.drawableId),
            tonumber(data.textureId or 0),
            2
        )
    end
    cb('ok')
end)

-- Prop update (hat, glasses, watch, bracelet)
RegisterNUICallback('updateProp', function(data, cb)
    local ped = GetActivePed()
    if ped and data.propId ~= nil then
        local propId = tonumber(data.propId)
        local drawId = tonumber(data.drawableId or -1)
        if drawId == -1 then
            ClearPedProp(ped, propId)
        else
            SetPedPropIndex(ped, propId, drawId, tonumber(data.textureId or 0), true)
        end
    end
    cb('ok')
end)

-- Eye color update
RegisterNUICallback('updateEyeColor', function(data, cb)
    local ped = GetActivePed()
    if ped and data.colorId ~= nil then
        SetPedEyeColor(ped, tonumber(data.colorId))
    end
    cb('ok')
end)

-- ─── Camera Controls ─────────────────────────────────────────────────────────

RegisterNUICallback('setCamera', function(data, cb)
    local ped = GetActivePed()
    if ped then
        local view = data.view or 'full'
        if CreatorState then CreatorState.view = view end
        currentView = view
        BuildCreatorCam(ped, view)
    end
    cb('ok')
end)

RegisterNUICallback('rotatePed', function(data, cb)
    local ped = GetActivePed()
    if ped then
        if data.reset then
            local spawnH = (CreatorState and CreatorState.spawnHeading) or 330.0
            SetEntityHeading(ped, spawnH)
        else
            local heading = GetEntityHeading(ped)
            local delta   = tonumber(data.angle) or 0
            SetEntityHeading(ped, (heading + delta) % 360.0)
        end
        if CreatorState and CreatorState.bodyScale then
            SetCreatorPedScale(CreatorState.bodyScale.x, CreatorState.bodyScale.y, CreatorState.bodyScale.z)
        end
    end
    cb('ok')
end)

RegisterNUICallback('zoomCam', function(data, cb)
    if CreatorState and CreatorState.cam and DoesCamExist(CreatorState.cam) then
        local curFov = GetCamFov(CreatorState.cam)
        local delta  = tonumber(data.delta) or 0
        local newFov = math.max(18.0, math.min(65.0, curFov + delta))
        SetCamFov(CreatorState.cam, newFov)
    end
    cb('ok')
end)

-- ─── Get Max Drawables (for spinner limits) ───────────────────────────────────

RegisterNUICallback('getMaxDrawable', function(data, cb)
    local max = 0
    local ped = GetActivePed()
    if ped then
        if data.type == 'component' then
            max = GetNumberOfPedDrawableVariations(ped, tonumber(data.id)) - 1
        elseif data.type == 'prop' then
            max = GetNumberOfPedPropDrawableVariations(ped, tonumber(data.id)) - 1
        elseif data.type == 'texture' then
            max = GetNumberOfPedTextureVariations(ped, tonumber(data.componentId), tonumber(data.drawableId)) - 1
        elseif data.type == 'prop_texture' then
            max = GetNumberOfPedPropTextureVariations(ped, tonumber(data.propId), tonumber(data.drawableId)) - 1
        elseif data.type == 'overlay' then
            max = GetPedHeadOverlayNum(tonumber(data.id)) - 1
        end
    end
    cb({ max = math.max(0, max) })
end)

-- ─── Save Character ──────────────────────────────────────────────────────────

RegisterNUICallback('saveCharacter', function(data, cb)
    local isOpen = (CreatorState and CreatorState.isOpen) or isCreatorOpen
    if not isOpen then cb('ok') return end

    local ped = GetActivePed()
    local finalSkin = ped and GetCurrentSkin(ped) or nil
    local slot = (CreatorState and CreatorState.slot) or targetSlot or 1

    local payload = {
        slot     = slot,
        identity = data.identity,
        skin     = finalSkin
    }

    TriggerServerEvent('bucu:identity:server:saveCharacter', payload)

    if CreatorState then CreatorState.isOpen = false end
    isCreatorOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })

    if ped then
        DeleteEntity(ped)
        if CreatorState then CreatorState.ped = nil end
        creatorPed = nil
    end

    DestroyCreatorCam()
    cb('ok')
end)

-- ─── Model Loader Helper ──────────────────────────────────────────────────────

local function EnsureModelLoaded(model)
    local hash = type(model) == 'number' and model or GetHashKey(model)
    if not IsModelInCdimage(hash) then return false end
    RequestModel(hash)
    local timeout = 0
    while not HasModelLoaded(hash) and timeout < 3500 do
        Wait(20)
        timeout = timeout + 20
    end
    return HasModelLoaded(hash)
end

-- ─── Character Created → Transform player model, apply skin & spawn at Airport ─

RegisterNetEvent('bucu:identity:client:onCharCreated', function(charData)
    local success, err = pcall(function()
        DoScreenFadeOut(400)
        local fadeTimeout = 0
        while not IsScreenFadedOut() and fadeTimeout < 1500 do
            Wait(50)
            fadeTimeout = fadeTimeout + 50
        end

        -- 1. Transform PlayerPedId() from Michael into the customized freemode character model
        local gender = (charData and charData.gender) or 'male'
        local fallbackModel = (gender == 'female') and 'mp_f_freemode_01' or 'mp_m_freemode_01'
        local model = (charData and charData.model) or fallbackModel
        local hash  = type(model) == 'number' and model or GetHashKey(model)

        if EnsureModelLoaded(hash) then
            SetPlayerModel(PlayerId(), hash)
            SetModelAsNoLongerNeeded(hash)
        end

        local ped = PlayerPedId()
        SetPedDefaultComponentVariation(ped)

        -- 2. Apply all customized skin data (head blend, morphs, clothing with textures, scale)
        if charData and charData.skin then
            ApplySkinData(ped, charData.skin)
        elseif CreatorState and CreatorState.skinData then
            ApplySkinData(ped, CreatorState.skinData)
        end

        -- 3. Set citizen state bag
        if charData and charData.citizenid then
            LocalPlayer.state:set('citizenid', charData.citizenid, true)
        end

        -- 4. Teleport directly to Airport arrival gate (Kedatangan Bucu City)
        local airportCoords = vector4(-1037.6, -2737.8, 20.1, 330.0)
        RequestCollisionAtCoord(airportCoords.x, airportCoords.y, airportCoords.z)
        SetEntityCoordsNoOffset(ped, airportCoords.x, airportCoords.y, airportCoords.z, false, false, false)
        SetEntityHeading(ped, airportCoords.w)
        SetEntityVisible(ped, true, false)
        FreezeEntityPosition(ped, false)

        -- Wait briefly for collision
        local colTimeout = 0
        while not HasCollisionLoadedAroundEntity(ped) and colTimeout < 1500 do
            Wait(50)
            colTimeout = colTimeout + 50
        end

        TriggerEvent('bucu:client:onPlayerSpawned', airportCoords)
        TriggerEvent('bucu:player:clientLoaded', charData)

        local fullName = (charData.firstname or 'Citizen') .. ' ' .. (charData.lastname or '')
        TriggerEvent('bucu:notify:show', {
            type  = 'success',
            title = 'Selamat Datang di Kota Bucu',
            text  = 'Selamat datang, ' .. fullName .. '! Anda telah tiba di Bandara Internasional LSIA.'
        })
    end)

    if not success then
        print('^1[bucu_identity] Error during onCharCreated: ' .. tostring(err) .. '^7')
    end

    -- ALWAYS ensure screen fades in and player is unfreezed
    Wait(200)
    DoScreenFadeIn(800)
    FreezeEntityPosition(PlayerPedId(), false)
end)
