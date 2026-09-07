-- ============================================================================
-- BUCU Identity — Configuration
-- Character Creator, Camera Positions & Creator Settings
-- ============================================================================

IdentityConfig = IdentityConfig or {}

IdentityConfig.Language = (Config and Config.Language) or 'en'

-- Preset Lokasi Character Creator (Menyesuaikan dengan BUCU City)
IdentityConfig.ActiveLocation = (MulticharConfig and MulticharConfig.ActiveLocation) or 'airport_tarmac'

IdentityConfig.Locations = {
    ['airport_tarmac'] = {
        isIndoor     = false,
        interior     = nil,
        pedCoords    = vector4(-1037.71, -2737.77, 20.17, 330.0),
        hiddenCoords = vector4(-1037.71, -2737.77, -50.0, 330.0),
    },
    ['del_perro_coast'] = {
        isIndoor     = false,
        interior     = nil,
        pedCoords    = vector4(-1686.0, -1072.0, 13.0, 50.0),
        hiddenCoords = vector4(-1686.0, -1072.0, -50.0, 50.0),
    },
    ['casino_terrace'] = {
        isIndoor     = false,
        interior     = nil,
        pedCoords    = vector4(964.5, 58.2, 112.5, 328.0),
        hiddenCoords = vector4(964.5, 58.2, 50.0, 328.0),
    },
    ['penthouse_skyline'] = {
        isIndoor     = true,
        interior     = vector3(-774.0, 342.0, 196.0),
        pedCoords    = vector4(-774.2, 342.5, 196.68, 180.0),
        hiddenCoords = vector4(-774.2, 342.5, 150.0, 180.0),
    },
    ['classic_office'] = {
        isIndoor     = true,
        interior     = vector3(-1004.36, -477.9, 51.63),
        pedCoords    = vector4(-1006.98, -477.98, 50.03, 208.42),
        hiddenCoords = vector4(-1006.98, -477.98, -100.0, 208.42),
    }
}

local activeLoc = IdentityConfig.Locations[IdentityConfig.ActiveLocation] or IdentityConfig.Locations['airport_tarmac']
IdentityConfig.CreatorInterior = activeLoc.interior
IdentityConfig.PedCoords       = activeLoc.pedCoords
IdentityConfig.HiddenCoords    = activeLoc.hiddenCoords


-- Konfigurasi Kamera Creator (per view)
-- dist   : Jarak kamera di depan karakter (meter)
-- camZ   : Ketinggian relatif kamera terhadap root ped (meter)
-- targetZ: Ketinggian relatif target pandang kamera (meter)
-- fov    : Sudut lebar lensa kamera
IdentityConfig.Cameras = {
    full  = { dist = 3.40, camZ = 0.15,  targetZ = -0.10, fov = 52.0, offset = vector3(0.0, 3.40, 0.15) },
    head  = { dist = 0.85, camZ = 0.65,  targetZ = 0.65,  fov = 32.0, offset = vector3(0.0, 0.85, 0.65) },
    torso = { dist = 1.45, camZ = 0.25,  targetZ = 0.20,  fov = 38.0, offset = vector3(0.0, 1.45, 0.25) },
    legs  = { dist = 2.05, camZ = -0.10, targetZ = -0.68, fov = 48.0, offset = vector3(0.0, 2.05, -0.10) },
}

-- Studio Lighting (lampu studio depan & atas agar karakter terang benderang)
IdentityConfig.StudioLight = {
    enabled   = true,
    keyLight  = { r = 255, g = 245, b = 235, range = 4.0, intensity = 2.8, dist = 1.8, height = 0.7 },
    fillLight = { r = 210, g = 225, b = 255, range = 3.5, intensity = 1.2, dist = 0.0, height = 2.2 }
}

-- Waktu transisi kamera (ms)
IdentityConfig.CamTransitionTime = 600

-- Default model GTA V Freemode
IdentityConfig.DefaultMaleModel   = 'mp_m_freemode_01'
IdentityConfig.DefaultFemaleModel = 'mp_f_freemode_01'

-- Starter Pack untuk Karakter Baru
IdentityConfig.StarterPack = {
    Cash = 1000,
    Bank = 5000,
    Items = {
        { name = 'id_card',      count = 1 },
        { name = 'phone',        count = 1 },
        { name = 'bread',        count = 2 },
        { name = 'water_bottle', count = 2 },
    }
}

-- Idle animation di creator
IdentityConfig.IdleAnimDict = 'amb@world_human_stand_impatient@male@no_sign@idle_a'
IdentityConfig.IdleAnimName = 'idle_a'

-- Batasan usia karakter (tahun)
IdentityConfig.MinAge = 18
IdentityConfig.MaxAge = 90

-- Harga creator (0 = gratis, hanya saat masuk pertama kali)
IdentityConfig.CreatorPrice = 0

-- Fungsi translasi lokal
function _U(key, ...)
    local lang = IdentityConfig.Language or 'en'
    local dict = (Locales and Locales[lang]) or (Locales and Locales['en']) or {}
    local str = dict[key] or key
    if select('#', ...) > 0 then
        return string.format(str, ...)
    end
    return str
end
