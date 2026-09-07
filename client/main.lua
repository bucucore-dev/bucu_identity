-- ============================================================================
-- BUCU Identity — Client Main
-- Manages: Creator camera, ped setup, skin apply / extract natives
-- ============================================================================

CreatorState = {
    cam          = nil,
    ped          = nil,
    isOpen       = false,
    view         = 'full',
    slot         = 1,
    spawnHeading = 330.0,
    bodyScale    = { x = 1.0, y = 1.0, z = 1.0 },
    bodyBuild    = 'standard',
}

-- Backward-compat aliases
creatorCam    = nil
creatorPed    = nil
isCreatorOpen = false
currentView   = 'full'
targetSlot    = 1

-- ─── Physical Scaling Engine (SetEntityMatrix Non-Uniform Deformation) ───────

local isCreatorScaleLoopRunning = false
local isPlayerScaleLoopRunning  = false
local ActivePlayerScale         = nil
local ActivePlayerBuild         = 'standard'

local function norm(vec)
    local mag = math.sqrt(vec.x ^ 2 + vec.y ^ 2 + vec.z ^ 2)
    if mag == 0 then return vec end
    return vector3(vec.x / mag, vec.y / mag, vec.z / mag)
end

function SetCreatorPedScale(scaleX, scaleY, scaleZ)
    if not CreatorState.bodyScale then
        CreatorState.bodyScale = { x = 1.0, y = 1.0, z = 1.0 }
    end
    CreatorState.bodyScale.x = tonumber(scaleX or CreatorState.bodyScale.x or 1.0)
    CreatorState.bodyScale.y = tonumber(scaleY or CreatorState.bodyScale.y or 1.0)
    CreatorState.bodyScale.z = tonumber(scaleZ or CreatorState.bodyScale.z or 1.0)

    local ped = (CreatorState and CreatorState.ped) or creatorPed
    if ped and DoesEntityExist(ped) then
        local scale   = CreatorState.bodyScale
        local basePos = CreatorState.baseCoords
        if not basePos then
            CreatorState.baseCoords = GetEntityCoords(ped)
            basePos = CreatorState.baseCoords
        end

        -- Height adjustment compensation:
        -- When scale.z == 1.0, targetZ is EXACTLY basePos.z (zero vertical displacement).
        -- When scale.z ~= 1.0, adjusts pelvis height proportionally to ground root bone (~0.95m)
        local targetZ = basePos.z + ((scale.z - 1.0) * 0.95)

        local forward, right, upVector, _ = GetEntityMatrix(ped)
        local forwardNorm = norm(forward) * scale.y
        local rightNorm   = norm(right)   * scale.x
        local upNorm      = norm(upVector)* scale.z

        SetEntityMatrix(ped,
            forwardNorm.x, forwardNorm.y, forwardNorm.z,
            rightNorm.x, rightNorm.y, rightNorm.z,
            upNorm.x, upNorm.y, upNorm.z,
            basePos.x, basePos.y, targetZ
        )
    end
end

function SetCreatorPedPosture(presetId)
    local ped = (CreatorState and CreatorState.ped) or creatorPed
    if not ped or not DoesEntityExist(ped) then return end

    local modelHash = GetEntityModel(ped)
    local isMale = modelHash == GetHashKey('mp_m_freemode_01')
    local clipset = 'move_m@generic'
    local animDict = 'amb@world_human_stand_impatient@male@no_sign@idle_a'
    local animName = 'idle_a'

    if presetId == 'heavy' then
        clipset  = isMale and 'move_m@fat@a' or 'move_f@fat@a'
        animDict = 'amb@world_human_hang_out_street@male_b@idle_a'
        animName = 'idle_a'
    elseif presetId == 'muscular' then
        clipset  = isMale and 'move_m@muscle@a' or 'move_f@muscle@a'
        animDict = 'amb@world_human_muscle_flex@arms_at_side@idle_a'
        animName = 'idle_a'
    elseif presetId == 'skinny' then
        clipset  = isMale and 'move_m@casual@d' or 'move_f@casual@d'
        animDict = 'amb@world_human_stand_impatient@male@no_sign@idle_a'
        animName = 'idle_a'
    else
        clipset  = 'move_m@generic'
        animDict = 'amb@world_human_stand_impatient@male@no_sign@idle_a'
        animName = 'idle_a'
    end

    -- 1. Apply movement clipset for walking/locomotion
    RequestAnimSet(clipset)
    local t = 0
    while not HasAnimSetLoaded(clipset) and t < 400 do
        Wait(20); t = t + 20
    end
    if HasAnimSetLoaded(clipset) then
        SetPedMovementClipset(ped, clipset, 0.25)
    end

    -- 2. Play distinct idle pose matching the build
    RequestAnimDict(animDict)
    local t2 = 0
    while not HasAnimDictLoaded(animDict) and t2 < 500 do
        Wait(20); t2 = t2 + 20
    end
    if HasAnimDictLoaded(animDict) then
        ClearPedTasks(ped)
        TaskPlayAnim(ped, animDict, animName, 8.0, -8.0, -1, 49, 0, false, false, false)
    else
        local fallbackDict = 'amb@world_human_stand_impatient@male@no_sign@idle_a'
        RequestAnimDict(fallbackDict)
        if HasAnimDictLoaded(fallbackDict) then
            ClearPedTasks(ped)
            TaskPlayAnim(ped, fallbackDict, 'idle_a', 8.0, -8.0, -1, 49, 0, false, false, false)
        end
    end
end

function StartCreatorScalingLoop()
    if isCreatorScaleLoopRunning then return end
    isCreatorScaleLoopRunning = true

    CreateThread(function()
        while (CreatorState and CreatorState.isOpen) or isCreatorOpen do
            local ped = (CreatorState and CreatorState.ped) or creatorPed
            if ped and DoesEntityExist(ped) then
                local scale = (CreatorState and CreatorState.bodyScale) or { x = 1.0, y = 1.0, z = 1.0 }
                if scale.x ~= 1.0 or scale.y ~= 1.0 or scale.z ~= 1.0 then
                    local basePos = CreatorState and CreatorState.baseCoords
                    if basePos then
                        local targetZ = basePos.z + ((scale.z - 1.0) * 0.95)

                        local forward, right, upVector, _ = GetEntityMatrix(ped)
                        local forwardNorm = norm(forward) * scale.y
                        local rightNorm   = norm(right)   * scale.x
                        local upNorm      = norm(upVector)* scale.z

                        SetEntityMatrix(ped,
                            forwardNorm.x, forwardNorm.y, forwardNorm.z,
                            rightNorm.x, rightNorm.y, rightNorm.z,
                            upNorm.x, upNorm.y, upNorm.z,
                            basePos.x, basePos.y, targetZ
                        )
                    end
                end
            end
            Wait(0)
        end
        isCreatorScaleLoopRunning = false
    end)
end

function ApplyPlayerScale(ped, scale)
    if not scale then return end
    local sx = tonumber(scale.x or 1.0)
    local sy = tonumber(scale.y or 1.0)
    local sz = tonumber(scale.z or 1.0)

    if ped and CreatorState and ped == CreatorState.ped then
        SetCreatorPedScale(sx, sy, sz)
        return
    end

    ActivePlayerScale = { x = sx, y = sy, z = sz }

    if not isPlayerScaleLoopRunning then
        isPlayerScaleLoopRunning = true
        CreateThread(function()
            while isPlayerScaleLoopRunning do
                local playerPed = PlayerPedId()
                if DoesEntityExist(playerPed) and not IsPedInAnyVehicle(playerPed, false) and not IsEntityDead(playerPed) then
                    local curScale = ActivePlayerScale
                    if curScale and (curScale.x ~= 1.0 or curScale.y ~= 1.0 or curScale.z ~= 1.0) then
                        local forward, right, upVector, position = GetEntityMatrix(playerPed)
                        local forwardNorm = norm(forward) * curScale.y
                        local rightNorm   = norm(right)   * curScale.x
                        local upNorm      = norm(upVector)* curScale.z

                        -- Maintain grounded position cleanly without cumulative drift
                        SetEntityMatrix(playerPed,
                            forwardNorm.x, forwardNorm.y, forwardNorm.z,
                            rightNorm.x, rightNorm.y, rightNorm.z,
                            upNorm.x, upNorm.y, upNorm.z,
                            position.x, position.y, position.z
                        )
                    end
                end
                Wait(0)
            end
        end)
    end
end

-- ─── Skin Utilities ──────────────────────────────────────────────────────────

--- Extract the current skin data from a ped
function GetCurrentSkin(ped)
    ped = ped or PlayerPedId()
    local modelHash = GetEntityModel(ped)
    local model = modelHash == GetHashKey('mp_f_freemode_01') and 'mp_f_freemode_01' or 'mp_m_freemode_01'

    local skin = {
        model        = model,
        headBlend    = (CreatorState and CreatorState.headBlend) or {
            shapeFirst  = 0,
            shapeSecond = 21,
            skinFirst   = 0,
            skinSecond  = 21,
            shapeMix    = 0.5,
            skinMix     = 0.5
        },
        faceFeatures = {},
        overlays     = {},
        components   = {},
        props        = {},
        hair         = {
            style     = GetPedDrawableVariation(ped, 2),
            color     = GetPedHairColor(ped),
            highlight = GetPedHairHighlightColor(ped)
        }
    }

    -- 20 Face Feature morphs (-1.0 to 1.0)
    for i = 0, 19 do
        skin.faceFeatures[i] = GetPedFaceFeature(ped, i)
    end

    -- 13 Overlay (beard, blemishes, aging, etc.)
    for i = 0, 12 do
        local hasOverlay, overlayValue, colourType, firstColour, secondColour, overlayOpacity = GetPedHeadOverlayData(ped, i)
        skin.overlays[i] = {
            index   = overlayValue,
            opacity = overlayOpacity,
            color1  = firstColour,
            color2  = secondColour
        }
    end

    -- 12 Component variations (torso, legs, shoes, etc.)
    for i = 0, 11 do
        skin.components[i] = {
            drawable = GetPedDrawableVariation(ped, i),
            texture  = GetPedTextureVariation(ped, i)
        }
    end

    -- Props (hat=0, glasses=1, earrings=2, watch=6, bracelet=7)
    local propSlots = { 0, 1, 2, 6, 7 }
    for _, propId in ipairs(propSlots) do
        skin.props[propId] = {
            drawable = GetPedPropIndex(ped, propId),
            texture  = GetPedPropTextureIndex(ped, propId)
        }
    end

    -- Eye color
    skin.eyeColor = GetPedEyeColor(ped)

    -- Body build & scaling
    skin.bodyScale = (CreatorState and CreatorState.bodyScale) or ActivePlayerScale or { x = 1.0, y = 1.0, z = 1.0 }
    skin.bodyBuild = (CreatorState and CreatorState.bodyBuild) or ActivePlayerBuild or 'standard'

    return skin
end

--- Apply a complete skin table to a ped
function ApplySkinData(ped, skin)
    if not skin then return end
    ped = ped or PlayerPedId()

    -- Head Blend (Parents / Heritage)
    if skin.headBlend then
        local hb = skin.headBlend
        SetPedHeadBlendData(
            ped,
            tonumber(hb.shapeFirst or 0),
            tonumber(hb.shapeSecond or 21),
            0,
            tonumber(hb.skinFirst or hb.shapeFirst or 0),
            tonumber(hb.skinSecond or hb.shapeSecond or 21),
            0,
            (tonumber(hb.shapeMix or 0.5) + 0.0),
            (tonumber(hb.skinMix or 0.5) + 0.0),
            0.0,
            false
        )
    end

    -- Face Features
    if skin.faceFeatures then
        for i, val in pairs(skin.faceFeatures) do
            SetPedFaceFeature(ped, tonumber(i), tonumber(val) + 0.0)
        end
    end

    -- Hair
    if skin.hair then
        SetPedComponentVariation(ped, 2, skin.hair.style or 0, 0, 2)
        SetPedHairColor(ped, skin.hair.color or 0, skin.hair.highlight or 0)
    end

    -- Overlays (beard, blemishes, aging, eyebrows, makeup, lipstick, etc.)
    if skin.overlays then
        for i, ov in pairs(skin.overlays) do
            local idx = tonumber(i)
            local val = tonumber(ov.index or 255)
            local op  = tonumber(ov.opacity or 1.0) + 0.0
            if val == -1 then
                val = 255
                op = 0.0
            end
            SetPedHeadOverlay(ped, idx, val, op)
            if ov.color1 then
                local colorType = 1
                if idx == 4 or idx == 5 or idx == 8 then colorType = 2 end
                SetPedHeadOverlayColor(ped, idx, colorType, tonumber(ov.color1), tonumber(ov.color2 or ov.color1))
            end
        end
    end

    -- Components
    if skin.components then
        for i, comp in pairs(skin.components) do
            SetPedComponentVariation(ped, tonumber(i), comp.drawable or 0, comp.texture or 0, 2)
        end
    end

    -- Props
    if skin.props then
        for i, prop in pairs(skin.props) do
            local propId = tonumber(i)
            if prop.drawable == nil or prop.drawable == -1 then
                ClearPedProp(ped, propId)
            else
                SetPedPropIndex(ped, propId, prop.drawable, prop.texture or 0, true)
            end
        end
    end

    -- Eye color
    if skin.eyeColor ~= nil then
        SetPedEyeColor(ped, tonumber(skin.eyeColor))
    end

    -- Body Scaling & Build
    if skin.bodyScale then
        ApplyPlayerScale(ped, skin.bodyScale)
    end
    if skin.bodyBuild then
        if CreatorState and ped == CreatorState.ped then
            CreatorState.bodyBuild = skin.bodyBuild
        else
            ActivePlayerBuild = skin.bodyBuild
        end
    end
end

-- ─── Model Loader ────────────────────────────────────────────────────────────

function RequestAndLoadModel(model)
    local hash = type(model) == 'number' and model or GetHashKey(model)
    if not IsModelInCdimage(hash) then return false end
    RequestModel(hash)
    local timeout = 0
    while not HasModelLoaded(hash) and timeout < 5000 do
        Wait(10)
        timeout = timeout + 10
    end
    return HasModelLoaded(hash)
end

-- ─── Creator Studio Lighting ──────────────────────────────────────────────────

local isLightingActive = false

function StartCreatorLighting()
    if isLightingActive then return end
    isLightingActive = true
    CreateThread(function()
        while CreatorState.isOpen and isLightingActive do
            Wait(0)
            local ped = CreatorState.ped
            if ped and DoesEntityExist(ped) and (not IdentityConfig.StudioLight or IdentityConfig.StudioLight.enabled ~= false) then
                local pCoords = GetEntityCoords(ped)
                local rad = math.rad(CreatorState.spawnHeading or 330.0)
                -- Forward direction from ped facing towards camera
                local forward = vector3(-math.sin(rad), math.cos(rad), 0.0)

                local kl = (IdentityConfig.StudioLight and IdentityConfig.StudioLight.keyLight) or {}
                local fl = (IdentityConfig.StudioLight and IdentityConfig.StudioLight.fillLight) or {}

                -- 1. Frontal Key Light: Warm studio illumination directly on face & clothes
                local kDist   = kl.dist or 1.8
                local kHeight = kl.height or 0.7
                local kPos    = pCoords + (forward * kDist) + vector3(0.0, 0.0, kHeight)
                DrawLightWithRange(
                    kPos.x, kPos.y, kPos.z,
                    kl.r or 255, kl.g or 245, kl.b or 235,
                    kl.range or 4.0, kl.intensity or 2.8
                )

                -- 2. Ambient Fill Light: Cool overhead light highlighting hair & shoulders
                local fHeight = fl.height or 2.2
                local fPos    = pCoords + vector3(0.0, 0.0, fHeight)
                DrawLightWithRange(
                    fPos.x, fPos.y, fPos.z,
                    fl.r or 210, fl.g or 225, fl.b or 255,
                    fl.range or 3.5, fl.intensity or 1.2
                )
            end
        end
        isLightingActive = false
    end)
end

function StopCreatorLighting()
    isLightingActive = false
end

-- ─── Creator Camera ──────────────────────────────────────────────────────────

function BuildCreatorCam(ped, viewName)
    ped = ped or CreatorState.ped
    if not ped or not DoesEntityExist(ped) then return end

    viewName = viewName or CreatorState.view or 'full'
    CreatorState.view = viewName
    currentView = viewName

    local cfg = IdentityConfig.Cameras[viewName] or IdentityConfig.Cameras['full']
    local coords = GetEntityCoords(ped)
    local rad = math.rad(CreatorState.spawnHeading or 330.0)

    -- Vector pointing forward in front of the character
    local forward = vector3(-math.sin(rad), math.cos(rad), 0.0)

    local dist    = cfg.dist or (cfg.offset and math.abs(cfg.offset.y)) or 2.4
    local camZ    = cfg.camZ or (cfg.offset and cfg.offset.z) or 0.15
    local targetZ = cfg.targetZ or (cfg.offset and (cfg.offset.z * 0.5)) or 0.05

    -- Camera placed in front of ped looking directly at the front of the body
    local camPos    = coords + (forward * dist) + vector3(0.0, 0.0, camZ)
    local targetPos = coords + vector3(0.0, 0.0, targetZ)

    if not (CreatorState.cam and DoesCamExist(CreatorState.cam)) then
        CreatorState.cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
        SetCamCoord(CreatorState.cam, camPos.x, camPos.y, camPos.z)
        PointCamAtCoord(CreatorState.cam, targetPos.x, targetPos.y, targetPos.z)
        SetCamFov(CreatorState.cam, cfg.fov or 46.0)
        SetCamActive(CreatorState.cam, true)
        RenderScriptCams(true, true, 500, true, true)
        creatorCam = CreatorState.cam
    else
        local newCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
        SetCamCoord(newCam, camPos.x, camPos.y, camPos.z)
        PointCamAtCoord(newCam, targetPos.x, targetPos.y, targetPos.z)
        SetCamFov(newCam, cfg.fov or 46.0)
        SetCamActiveWithInterp(newCam, CreatorState.cam, IdentityConfig.CamTransitionTime or 600, 1, 1)

        local oldCam = CreatorState.cam
        CreatorState.cam = newCam
        creatorCam = newCam

        CreateThread(function()
            Wait((IdentityConfig.CamTransitionTime or 600) + 50)
            if oldCam and DoesCamExist(oldCam) then
                DestroyCam(oldCam, false)
            end
        end)
    end
end

function DestroyCreatorCam()
    StopCreatorLighting()
    if CreatorState.cam and DoesCamExist(CreatorState.cam) then
        RenderScriptCams(false, true, 500, true, true)
        SetCamActive(CreatorState.cam, false)
        DestroyCam(CreatorState.cam, false)
        CreatorState.cam = nil
        creatorCam = nil
    end
end

-- ─── Creator Ped ─────────────────────────────────────────────────────────────

function SpawnCreatorPed(model, skin)
    local cfg   = IdentityConfig.PedCoords
    local hash  = type(model) == 'number' and model or GetHashKey(model)

    if not RequestAndLoadModel(hash) then
        print('^1[bucu_identity]^7 Failed to load model: ' .. tostring(model))
        return nil
    end

    -- Delete existing preview ped
    if CreatorState.ped and DoesEntityExist(CreatorState.ped) then
        DeleteEntity(CreatorState.ped)
        CreatorState.ped = nil
        creatorPed = nil
    end

    local ped = CreatePed(4, hash, cfg.x, cfg.y, cfg.z - 0.98, cfg.w, false, true)
    PlaceObjectOnGroundProperly(ped)
    CreatorState.baseCoords = GetEntityCoords(ped)
    SetEntityHeading(ped, cfg.w)
    CreatorState.spawnHeading = cfg.w

    SetPedCanPlayAmbientAnims(ped, true)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)

    -- Play idle animation
    local dict = IdentityConfig.IdleAnimDict or 'amb@world_human_stand_impatient@male@no_sign@idle_a'
    local anim = IdentityConfig.IdleAnimName or 'idle_a'
    RequestAnimDict(dict)
    local t = 0
    while not HasAnimDictLoaded(dict) and t < 3000 do
        Wait(50); t = t + 50
    end
    if HasAnimDictLoaded(dict) then
        TaskPlayAnim(ped, dict, anim, 8.0, -8.0, -1, 49, 0, false, false, false)
    end

    -- Apply existing skin if provided
    if skin then
        Wait(100)
        ApplySkinData(ped, skin)
        if skin.headBlend then
            CreatorState.headBlend = skin.headBlend
        end
        if skin.bodyScale then
            CreatorState.bodyScale = skin.bodyScale
        end
        if skin.bodyBuild then
            CreatorState.bodyBuild = skin.bodyBuild
        end
    else
        CreatorState.headBlend = { shapeFirst = 0, shapeSecond = 21, skinFirst = 0, skinSecond = 21, shapeMix = 0.5, skinMix = 0.5 }
        CreatorState.bodyScale = { x = 1.0, y = 1.0, z = 1.0 }
        CreatorState.bodyBuild = 'standard'
        SetPedHeadBlendData(ped, 0, 21, 0, 0, 21, 0, 0.5, 0.5, 0.0, false)

        -- Clean starter apparel for character creation preview
        local isMale = hash == GetHashKey('mp_m_freemode_01')
        if isMale then
            SetPedComponentVariation(ped, 3, 15, 0, 2)  -- Athletic torso
            SetPedComponentVariation(ped, 4, 61, 0, 2)  -- Athletic pants
            SetPedComponentVariation(ped, 6, 34, 0, 2)  -- Sneakers
            SetPedComponentVariation(ped, 8, 15, 0, 2)  -- Undershirt
            SetPedComponentVariation(ped, 11, 15, 0, 2) -- Torso preview
        else
            SetPedComponentVariation(ped, 3, 15, 0, 2)  -- Female athletic torso
            SetPedComponentVariation(ped, 4, 15, 0, 2)  -- Shorts
            SetPedComponentVariation(ped, 6, 35, 0, 2)  -- Sneakers
            SetPedComponentVariation(ped, 8, 14, 0, 2)  -- Sport top
            SetPedComponentVariation(ped, 11, 15, 0, 2) -- Fit preview top
        end
    end

    StartCreatorScalingLoop()

    SetModelAsNoLongerNeeded(hash)
    CreatorState.ped = ped
    creatorPed = ped
    return ped
end

-- ─── Open Creator ────────────────────────────────────────────────────────────

RegisterNetEvent('bucu:identity:client:openCreator', function(data)
    if CreatorState.isOpen then return end
    CreatorState.isOpen = true
    isCreatorOpen       = true
    CreatorState.slot   = (data and data.slot) or 1
    targetSlot          = CreatorState.slot

    -- Ensure daytime and crystal-clear skies for previewing character
    NetworkOverrideClockTime(13, 0, 0)
    SetWeatherTypePersist('EXTRASUNNY')
    SetWeatherTypeNow('EXTRASUNNY')

    -- Load interior if indoor location
    if IdentityConfig.CreatorInterior then
        local interior = GetInteriorAtCoords(
            IdentityConfig.CreatorInterior.x,
            IdentityConfig.CreatorInterior.y,
            IdentityConfig.CreatorInterior.z - 18.9
        )
        LoadInterior(interior)
        local t = 0
        while not IsInteriorReady(interior) and t < 5000 do
            Wait(100); t = t + 100
        end
    end

    -- Hide player ped
    local playerPed = PlayerPedId()
    DoScreenFadeOut(200)
    Wait(300)
    SetEntityCoords(playerPed, IdentityConfig.HiddenCoords.x, IdentityConfig.HiddenCoords.y, IdentityConfig.HiddenCoords.z)
    FreezeEntityPosition(playerPed, true)
    SetEntityVisible(playerPed, false, false)

    -- Determine default model from gender
    local defaultModel = IdentityConfig.DefaultMaleModel

    -- Spawn preview ped facing front
    local ped = SpawnCreatorPed(defaultModel, nil)
    if not ped then
        print('^1[bucu_identity]^7 Failed to spawn creator ped.')
        CreatorState.isOpen = false
        isCreatorOpen       = false
        return
    end

    -- Build camera (facing the ped front)
    CreatorState.view = 'full'
    currentView       = 'full'
    BuildCreatorCam(ped, 'full')

    -- Start studio illumination
    StartCreatorLighting()

    -- Get base skin from spawned ped
    local baseSkin = GetCurrentSkin(ped)

    SetNuiFocus(true, true)
    DoScreenFadeIn(500)

    -- Open NUI
    SendNUIMessage({
        action    = 'open',
        language  = IdentityConfig.Language or 'en',
        locales   = Locales and (Locales[IdentityConfig.Language] or Locales['en']) or {},
        slot      = CreatorState.slot,
        baseSkin  = baseSkin
    })
end)

-- ─── Exports (callable by bucu_multicharacter / other resources) ─────────────

exports('OpenCreator', function(slot)
    TriggerServerEvent('bucu:identity:server:openCreator', slot or 1)
end)

exports('ApplySkinData', ApplySkinData)
exports('GetCurrentSkin', GetCurrentSkin)
exports('ApplyPlayerScale', ApplyPlayerScale)
exports('SetCreatorPedScale', SetCreatorPedScale)
exports('SetCreatorPedPosture', SetCreatorPedPosture)

-- ─── Internal: switch model when gender changes ───────────────────────────────

RegisterNetEvent('bucu:identity:client:switchModel', function(model, currentSkin)
    if not CreatorState.isOpen then return end
    local ped = SpawnCreatorPed(model, currentSkin)
    if ped then
        BuildCreatorCam(ped, CreatorState.view or 'full')
        local newSkin = GetCurrentSkin(ped)
        SendNUIMessage({ action = 'skinUpdate', skin = newSkin })
    end
end)

-- ─── Apply Skin from DB on Player Load ──────────────────────────────────────

AddEventHandler('bucu:client:onPlayerSpawned', function()
    CreateThread(function()
        Wait(600)
        local citizenId = LocalPlayer.state.citizenid

        if not citizenId and exports['bucu_core'] then
            pcall(function()
                local coreObj = exports['bucu_core']:GetCoreObject()
                if coreObj and coreObj.Player then
                    citizenId = coreObj.Player.citizenid
                end
            end)
        end

        if not citizenId and GetResourceState('qb-core') == 'started' then
            pcall(function()
                local QBCore = exports['qb-core']:GetCoreObject()
                local pData  = QBCore.Functions.GetPlayerData()
                citizenId    = pData and pData.citizenid
            end)
        end

        if citizenId then
            TriggerServerEvent('bucu:identity:server:requestSkin', citizenId)
        end
    end)
end)

RegisterNetEvent('bucu:identity:client:applySkin', function(model, skinData)
    CreateThread(function()
        if model then
            local hash = type(model) == 'number' and model or GetHashKey(model)
            if RequestAndLoadModel(hash) then
                SetPlayerModel(PlayerId(), hash)
                SetModelAsNoLongerNeeded(hash)
            end
        end
        local ped = PlayerPedId()
        SetPedDefaultComponentVariation(ped)
        Wait(150)
        ApplySkinData(ped, skinData)
    end)
end)

-- Server side handler for skin request (in server/main.lua we add this event)
-- bucu:identity:server:requestSkin → bucu:identity:client:applySkin

print('^2[bucu_identity]^7 Client loaded successfully.')
