/* ============================================================================
   BUCU Identity — Frontend State Machine & NUI Communication
   Steps: (1) Identity Form → (2) Character Creator
   Real-time preview via PostMessage / NUI callbacks to Lua
   ============================================================================ */

'use strict';

// ── State ─────────────────────────────────────────────────────────────────────
const State = {
    isOpen:       false,
    currentStep:  'identity',   // 'identity' | 'creator'
    activeTab:        'face',
    activeView:       'full',
    activeBodyPreset: 'standard',
    slot:             1,
    language:     'en',
    locales:      {},
    identity: {
        firstname:   '',
        lastname:    '',
        dob:         '',
        gender:      'male',
        nationality: 'San Andreas'
    },
    skin: {
        model:        'mp_m_freemode_01',
        headBlend:    { shapeFirst: 0, shapeSecond: 21, skinFirst: 0, skinSecond: 21, shapeMix: 0.5, skinMix: 0.5 },
        faceFeatures: {},
        overlays:     {},
        components:   {},
        props:        {},
        hair:         { style: 0, color: 0, highlight: 0 },
        eyeColor:     2,
        bodyScale:    { x: 1.0, y: 1.0, z: 1.0 },
        bodyBuild:    'standard'
    },
    activeBodyPreset: 'standard',
    // Per-component max drawables (fetched async)
    maxDrawables: {}
};

// ── GTA Heritage Parents ─────────────────────────────────────────────────────
const FATHERS = [
    { id: 0,  name: 'Benjamin' },
    { id: 1,  name: 'Daniel' },
    { id: 2,  name: 'Joshua' },
    { id: 3,  name: 'Noah' },
    { id: 4,  name: 'Andrew' },
    { id: 5,  name: 'Juan' },
    { id: 6,  name: 'Alex' },
    { id: 7,  name: 'Isaac' },
    { id: 8,  name: 'Evan' },
    { id: 9,  name: 'Ethan' },
    { id: 10, name: 'Vincent' },
    { id: 11, name: 'Angel' },
    { id: 12, name: 'Diego' },
    { id: 13, name: 'Adrian' },
    { id: 14, name: 'Gabriel' },
    { id: 15, name: 'Michael' },
    { id: 16, name: 'Santiago' },
    { id: 17, name: 'Kevin' },
    { id: 18, name: 'Louis' },
    { id: 19, name: 'Samuel' },
    { id: 20, name: 'Anthony' },
    { id: 42, name: 'Claude' },
    { id: 43, name: 'Niko' },
    { id: 44, name: 'John' }
];

const MOTHERS = [
    { id: 21, name: 'Hannah' },
    { id: 22, name: 'Audrey' },
    { id: 23, name: 'Jasmine' },
    { id: 24, name: 'Giselle' },
    { id: 25, name: 'Amelia' },
    { id: 26, name: 'Isabella' },
    { id: 27, name: 'Zoe' },
    { id: 28, name: 'Ava' },
    { id: 29, name: 'Camila' },
    { id: 30, name: 'Violet' },
    { id: 31, name: 'Sophia' },
    { id: 32, name: 'Eveline' },
    { id: 33, name: 'Nicole' },
    { id: 34, name: 'Ashley' },
    { id: 35, name: 'Grace' },
    { id: 36, name: 'Brianna' },
    { id: 37, name: 'Natalie' },
    { id: 38, name: 'Olivia' },
    { id: 39, name: 'Elizabeth' },
    { id: 40, name: 'Charlotte' },
    { id: 41, name: 'Emma' },
    { id: 45, name: 'Misty' }
];

// ── GTA Hair & Makeup Colors ─────────────────────────────────────────────────
const HAIR_COLORS = [
    '#1a0a00','#2e1503','#3d1f07','#4a2b0c','#5c3511','#7a4a1a','#9e6428',
    '#c8883c','#e0ac6e','#f0cc9c','#f8e8c8','#fff5e8','#f5d08c','#e8b84b',
    '#d49020','#b87010','#8c4800','#5c2400','#3c1400','#200800','#100400',
    '#e8d0d0','#d4a8a8','#c07878','#a84848','#8c2828','#701414','#4c0808',
    '#d0e8d0','#a8c8a8','#78a878','#488448','#286028','#104010','#082808',
    '#d0d4e8','#a8accc','#7880b0','#485494','#283878','#102060','#081040',
    '#e8d0e8','#cca8cc','#b078b0','#904894','#702878','#501460','#300840',
    '#e8e0c0','#ccc8a0','#b0b080','#909460','#707040','#505020','#303010',
    '#c8c8c8','#a0a0a0','#787878','#585858','#383838','#1c1c1c','#080808','#ffffff'
];

const LIPSTICK_COLORS = [
    '#9e0b0f','#b81424','#d62035','#c43b58','#d9526f','#e87890','#f299ab',
    '#9c1c4e','#b8235f','#780d35','#540824','#661028','#851e3e','#ab2952',
    '#c43763','#db517d','#bf2233','#87111e','#630812','#47040b','#b04343',
    '#c75b5b','#de7a7a','#6b2238','#4a1324','#360918','#7a1b4d','#9c2a68'
];

const BLUSH_COLORS = [
    '#d64f5d','#e86d79','#f08d96','#f7abb2','#c73847','#ab2634','#8c1b26',
    '#e07053','#eb876e','#f2a28d','#b84d33','#9e3b22','#802b16','#c74a6c'
];

const SKIN_PRESETS = [
    { name: 'Pale / Sangat Terang',  hex: '#f6dbd1', skinFirst: 0,  skinSecond: 21 },
    { name: 'Fair / Terang',         hex: '#eecdbb', skinFirst: 1,  skinSecond: 22 },
    { name: 'Peach / Kuning Gading', hex: '#e2be9e', skinFirst: 2,  skinSecond: 23 },
    { name: 'Olive / Langsat',       hex: '#d2aa82', skinFirst: 4,  skinSecond: 24 },
    { name: 'Tan / Sawo Matang',     hex: '#b5845c', skinFirst: 5,  skinSecond: 25 },
    { name: 'Caramel / Eksotis',     hex: '#96633d', skinFirst: 17, skinSecond: 37 },
    { name: 'Bronze / Cokelat',      hex: '#744626', skinFirst: 12, skinSecond: 34 },
    { name: 'Dark / Gelap',          hex: '#472917', skinFirst: 19, skinSecond: 38 },
];

const BODY_BUILD_PRESETS = [
    {
        id: 'skinny',
        name: 'Kurus / Ramping',
        icon: '🏃',
        desc: 'Postur ramping, leher & pinggang ramping',
        scaleX: 0.88,
        scaleY: 0.88,
        scaleZ: 1.00,
        component3: 5,
        headBlend: { shapeFirst: 0, shapeSecond: 6, shapeMix: 0.85, skinFirst: 0, skinSecond: 6, skinMix: 0.5 },
        morphs: { 19: -0.90, 10: -0.80, 13: -0.50, 17: -0.90 }
    },
    {
        id: 'standard',
        name: 'Standar / Normal',
        icon: '🚶',
        desc: 'Proporsional seimbang default',
        scaleX: 1.00,
        scaleY: 1.00,
        scaleZ: 1.00,
        component3: 0,
        headBlend: { shapeFirst: 0, shapeSecond: 21, shapeMix: 0.50, skinFirst: 0, skinSecond: 21, skinMix: 0.5 },
        morphs: { 19: 0.00, 10: 0.00, 13: 0.00, 17: 0.00 }
    },
    {
        id: 'muscular',
        name: 'Berotot / Atletis',
        icon: '💪',
        desc: 'Pundak lebar bidang, dada tegap V-taper atletis',
        scaleX: 1.15,
        scaleY: 1.10,
        scaleZ: 1.00,
        component3: 15,
        headBlend: { shapeFirst: 44, shapeSecond: 20, shapeMix: 0.85, skinFirst: 44, skinSecond: 20, skinMix: 0.5 },
        morphs: { 19: 0.75, 10: -0.40, 8: 0.40, 13: 0.65, 14: 0.35, 15: 0.20, 16: 0.25, 17: -0.90 }
    },
    {
        id: 'heavy',
        name: 'Berisi / Gemuk',
        icon: '🏋️',
        desc: 'Postur sangat gemuk, perut & leher tebal berisi',
        scaleX: 1.25,
        scaleY: 1.28,
        scaleZ: 1.00,
        component3: 4,
        headBlend: { shapeFirst: 10, shapeSecond: 16, shapeMix: 0.90, skinFirst: 10, skinSecond: 16, skinMix: 0.5 },
        morphs: { 19: 1.00, 10: 1.00, 13: 0.90, 14: 0.70, 17: 1.00, 18: 0.70, 12: 0.40 }
    }
];

// ── Tab Definitions ───────────────────────────────────────────────────────────
const TABS = {
    face: {
        groups: [
            {
                title: 'Parents Heritage (Silsilah Ayah & Ibu)',
                items: [
                    { type: 'parent', label: 'Father (Ayah)', key: 'hb_father', gender: 'male' },
                    { type: 'parent', label: 'Mother (Ibu)',  key: 'hb_mother', gender: 'female' },
                    { type: 'slider', label: 'Face Resemblance (Mirip Ayah ⟷ Ibu)', key: 'hb_shapeMix', min: 0, max: 1, step: 0.05, nui: 'updateHeadBlend', arg: 'shapeMix' },
                    { type: 'slider', label: 'Skin Tone Resemblance (Kulit Ayah ⟷ Ibu)', key: 'hb_skinMix', min: 0, max: 1, step: 0.05, nui: 'updateHeadBlend', arg: 'skinMix' },
                ]
            },
            {
                title: 'Nose Shape (Bentuk Hidung)',
                items: [
                    { type: 'slider', label: 'Nose Width',       key: 'ff', index: 0, min: -1, max: 1, step: 0.05 },
                    { type: 'slider', label: 'Nose Peak Height', key: 'ff', index: 1, min: -1, max: 1, step: 0.05 },
                    { type: 'slider', label: 'Nose Length',      key: 'ff', index: 2, min: -1, max: 1, step: 0.05 },
                    { type: 'slider', label: 'Nose Bone Height', key: 'ff', index: 3, min: -1, max: 1, step: 0.05 },
                    { type: 'slider', label: 'Nose Lowered',     key: 'ff', index: 4, min: -1, max: 1, step: 0.05 },
                    { type: 'slider', label: 'Nose Bone Twist',  key: 'ff', index: 5, min: -1, max: 1, step: 0.05 },
                ]
            },
            {
                title: 'Eyes & Brows (Mata & Alis)',
                items: [
                    { type: 'slider', label: 'Eyebrow Height',   key: 'ff', index: 6,  min: -1, max: 1, step: 0.05 },
                    { type: 'slider', label: 'Eyebrow Forward',  key: 'ff', index: 7,  min: -1, max: 1, step: 0.05 },
                    { type: 'slider', label: 'Eye Opening',      key: 'ff', index: 11, min: -1, max: 1, step: 0.05 },
                ]
            },
            {
                title: 'Cheeks & Jaw (Pipi & Rahang)',
                items: [
                    { type: 'slider', label: 'Cheekbone Height', key: 'ff', index: 8,  min: -1, max: 1, step: 0.05 },
                    { type: 'slider', label: 'Cheek Width',      key: 'ff', index: 9,  min: -1, max: 1, step: 0.05 },
                    { type: 'slider', label: 'Cheek Size',       key: 'ff', index: 10, min: -1, max: 1, step: 0.05 },
                    { type: 'slider', label: 'Jaw Width',        key: 'ff', index: 13, min: -1, max: 1, step: 0.05 },
                    { type: 'slider', label: 'Jaw Back',         key: 'ff', index: 14, min: -1, max: 1, step: 0.05 },
                ]
            },
            {
                title: 'Chin & Neck (Dagu & Leher)',
                items: [
                    { type: 'slider', label: 'Lip Thickness',    key: 'ff', index: 12, min: -1, max: 1, step: 0.05 },
                    { type: 'slider', label: 'Chin Height',      key: 'ff', index: 15, min: -1, max: 1, step: 0.05 },
                    { type: 'slider', label: 'Chin Length',      key: 'ff', index: 16, min: -1, max: 1, step: 0.05 },
                    { type: 'slider', label: 'Chin Width',       key: 'ff', index: 17, min: -1, max: 1, step: 0.05 },
                    { type: 'slider', label: 'Chin Dimple',      key: 'ff', index: 18, min: -1, max: 1, step: 0.05 },
                    { type: 'slider', label: 'Neck Thickness',   key: 'ff', index: 19, min: -1, max: 1, step: 0.05 },
                ]
            },
            {
                title: 'Eye Color (Warna Mata)',
                items: [
                    { type: 'eyecolor', label: 'Eye Color', key: 'eyeColor' }
                ]
            }
        ]
    },
    hair: {
        groups: [
            {
                title: 'Head Hair',
                items: [
                    { type: 'spinner', label: 'Hair Style', key: 'hair_style', component: 2, nui: 'updateHair', arg: 'hairId' },
                    { type: 'colors',  label: 'Hair Color', key: 'hair_color', palette: HAIR_COLORS, nui: 'updateHair', arg: 'colorId' },
                    { type: 'colors',  label: 'Highlight',  key: 'hair_highlight', palette: HAIR_COLORS, nui: 'updateHair', arg: 'highlightId' },
                ]
            },
            {
                title: 'Facial Hair',
                items: [
                    { type: 'spinner', label: 'Beard Style',  key: 'ov1_index',   overlay: 1, nui: 'updateOverlay' },
                    { type: 'slider',  label: 'Beard Opacity', key: 'ov1_opacity', overlay: 1, min: 0, max: 1, step: 0.05, nui: 'updateOverlay', arg: 'opacity' },
                    { type: 'colors',  label: 'Beard Color',  key: 'ov1_color',   overlay: 1, palette: HAIR_COLORS, nui: 'updateOverlay', arg: 'color1' },
                ]
            },
            {
                title: 'Eyebrows',
                items: [
                    { type: 'spinner', label: 'Eyebrow Style', key: 'ov2_index',   overlay: 2, nui: 'updateOverlay' },
                    { type: 'slider',  label: 'Opacity',       key: 'ov2_opacity', overlay: 2, min: 0, max: 1, step: 0.05, nui: 'updateOverlay', arg: 'opacity' },
                    { type: 'colors',  label: 'Color',         key: 'ov2_color',   overlay: 2, palette: HAIR_COLORS, nui: 'updateOverlay', arg: 'color1' },
                ]
            },
            {
                title: 'Chest Hair',
                items: [
                    { type: 'spinner', label: 'Chest Hair Style', key: 'ov10_index',   overlay: 10, nui: 'updateOverlay' },
                    { type: 'slider',  label: 'Chest Opacity',    key: 'ov10_opacity', overlay: 10, min: 0, max: 1, step: 0.05, nui: 'updateOverlay', arg: 'opacity' },
                    { type: 'colors',  label: 'Chest Color',      key: 'ov10_color',   overlay: 10, palette: HAIR_COLORS, nui: 'updateOverlay', arg: 'color1' },
                ]
            }
        ]
    },
    body: {
        groups: [
            {
                title: 'Physical Build & Posture (Bentuk & Postur Tubuh)',
                items: [
                    { type: 'body_preset', label: 'Preset Postur Tubuh' },
                    { type: 'body_scale_slider', label: 'Body Width / Shoulders (Lebar Pundak & Tubuh)', axis: 'x', min: 0.75, max: 1.50, step: 0.01 },
                    { type: 'body_scale_slider', label: 'Body Depth / Chest & Belly (Ketebalan Dada & Perut)', axis: 'y', min: 0.75, max: 1.50, step: 0.01 },
                    { type: 'body_scale_slider', label: 'Body Height (Tinggi Badan)', axis: 'z', min: 0.85, max: 1.15, step: 0.01 },
                    { type: 'spinner', label: 'Upper Body Physique (Postur Lengan & Dada)', key: 'comp3_draw', component: 3, nui: 'updateComponent', arg: 'drawableId' },
                    { type: 'slider',  label: 'Neck & Shoulder Width (Ketebalan Leher & Pundak)', key: 'ff', index: 19, min: -1, max: 1, step: 0.05 },
                    { type: 'slider',  label: 'Cheek Fullness (Kepenuhan Pipi)', key: 'ff', index: 10, min: -1, max: 1, step: 0.05 },
                    { type: 'slider',  label: 'Jaw Fullness (Lebar & Volume Rahang)', key: 'ff', index: 13, min: -1, max: 1, step: 0.05 },
                    { type: 'slider',  label: 'Chin Mass / Double Chin (Dagu Berisi)', key: 'ff', index: 17, min: -1, max: 1, step: 0.05 },
                    { type: 'spinner', label: 'Chest Hair Style (Bulu Dada)', key: 'ov10_index', overlay: 10, nui: 'updateOverlay' },
                    { type: 'slider',  label: 'Chest Hair Density (Ketebalan)', key: 'ov10_opacity', overlay: 10, min: 0, max: 1, step: 0.05, nui: 'updateOverlay', arg: 'opacity' },
                    { type: 'colors',  label: 'Chest Hair Color (Warna Bulu Dada)', key: 'ov10_color', overlay: 10, palette: HAIR_COLORS, nui: 'updateOverlay', arg: 'color1' },
                ]
            },
            {
                title: 'Skin Tone & Genetics (Warna & Silsilah Kulit)',
                items: [
                    { type: 'skintone_preset', label: 'Skin Tone Palette (Warna Dasar Kulit)', key: 'skin_preset' },
                    { type: 'slider',  label: 'Skin Tone Blend (Perpaduan Kulit Ayah ⟷ Ibu)', key: 'hb_skinMix', min: 0, max: 1, step: 0.05, nui: 'updateHeadBlend', arg: 'skinMix' },
                ]
            },
            {
                title: 'Body Scars & Marks (Bekas Luka & Noda Badan)',
                items: [
                    { type: 'spinner', label: 'Body Blemishes (Bekas Luka Badan)', key: 'ov11_index', overlay: 11, nui: 'updateOverlay' },
                    { type: 'slider',  label: 'Blemishes Opacity (Kepekatan Luka)', key: 'ov11_opacity', overlay: 11, min: 0, max: 1, step: 0.05, nui: 'updateOverlay', arg: 'opacity' },
                    { type: 'spinner', label: 'Additional Scars (Noda Tubuh Tambahan)', key: 'ov12_index', overlay: 12, nui: 'updateOverlay' },
                    { type: 'slider',  label: 'Scars Opacity (Kepekatan Noda)', key: 'ov12_opacity', overlay: 12, min: 0, max: 1, step: 0.05, nui: 'updateOverlay', arg: 'opacity' },
                ]
            },
            {
                title: 'Skin Aging & Condition (Kondisi Kulit & Penuaan)',
                items: [
                    { type: 'spinner', label: 'Aging & Wrinkles (Kerutan & Usia)', key: 'ov3_index', overlay: 3, nui: 'updateOverlay' },
                    { type: 'slider',  label: 'Aging Intensity (Tingkat Kerutan)', key: 'ov3_opacity', overlay: 3, min: 0, max: 1, step: 0.05, nui: 'updateOverlay', arg: 'opacity' },
                    { type: 'spinner', label: 'Skin Complexion (Tekstur Kulit)', key: 'ov6_index', overlay: 6, nui: 'updateOverlay' },
                    { type: 'slider',  label: 'Complexion Opacity (Kejelasan Tekstur)', key: 'ov6_opacity', overlay: 6, min: 0, max: 1, step: 0.05, nui: 'updateOverlay', arg: 'opacity' },
                    { type: 'spinner', label: 'Sun Damage (Efek Sinar Matahari)', key: 'ov7_index', overlay: 7, nui: 'updateOverlay' },
                    { type: 'slider',  label: 'Damage Opacity (Kepekatan Efek Matahari)', key: 'ov7_opacity', overlay: 7, min: 0, max: 1, step: 0.05, nui: 'updateOverlay', arg: 'opacity' },
                    { type: 'spinner', label: 'Moles & Freckles (Tahi Lalat & Bintik Kulit)', key: 'ov9_index', overlay: 9, nui: 'updateOverlay' },
                    { type: 'slider',  label: 'Freckles Opacity (Kepekatan Bintik)', key: 'ov9_opacity', overlay: 9, min: 0, max: 1, step: 0.05, nui: 'updateOverlay', arg: 'opacity' },
                    { type: 'spinner', label: 'Facial Blemishes (Jerawat & Noda)', key: 'ov0_index', overlay: 0, nui: 'updateOverlay' },
                    { type: 'slider',  label: 'Blemishes Opacity (Kepekatan Jerawat)', key: 'ov0_opacity', overlay: 0, min: 0, max: 1, step: 0.05, nui: 'updateOverlay', arg: 'opacity' },
                ]
            }
        ]
    },
    clothing: {
        groups: [
            {
                title: 'Upper Body (Pakaian Bagian Atas)',
                items: [
                    { type: 'clothing_item', label: 'Tops / Baju Luar', key: 'comp11', component: 11 },
                    { type: 'clothing_item', label: 'Undershirt / Kaos Dalam', key: 'comp8', component: 8 },
                    { type: 'clothing_item', label: 'Body Armor / Rompi', key: 'comp9', component: 9 },
                    { type: 'clothing_item', label: 'Decals / Emblem & Badge', key: 'comp10', component: 10 },
                ]
            },
            {
                title: 'Lower Body (Pakaian Bagian Bawah)',
                items: [
                    { type: 'clothing_item', label: 'Pants',    key: 'comp4l',  component: 4 },
                    { type: 'clothing_item', label: 'Shoes / Sepatu & Sandal', key: 'comp6', component: 6 },
                ]
            },
            {
                title: 'Outerwear & Bags (Aksesoris Tambahan)',
                items: [
                    { type: 'clothing_item', label: 'Neckwear & Chains / Kalung & Dasi', key: 'comp7', component: 7 },
                    { type: 'clothing_item', label: 'Bags & Parachutes / Tas Punggung', key: 'comp5', component: 5 },
                ]
            }
        ]
    },
    accessories: {
        groups: [
            {
                title: 'Head Props (Aksesoris Kepala)',
                items: [
                    { type: 'prop_item', label: 'Hat / Topi & Helm', key: 'prop0', prop: 0 },
                    { type: 'prop_item', label: 'Glasses / Kacamata', key: 'prop1', prop: 1 },
                    { type: 'prop_item', label: 'Ear Wear / Anting', key: 'prop2', prop: 2 },
                ]
            },
            {
                title: 'Wrist Props (Aksesoris Tangan)',
                items: [
                    { type: 'prop_item', label: 'Watch / Jam Tangan', key: 'prop6', prop: 6 },
                    { type: 'prop_item', label: 'Bracelet / Gelang', key: 'prop7', prop: 7 },
                ]
            },
            {
                title: 'Cosmetics & Makeup',
                items: [
                    { type: 'spinner', label: 'Makeup Style',    key: 'ov4_index',   overlay: 4, nui: 'updateOverlay' },
                    { type: 'slider',  label: 'Makeup Opacity',  key: 'ov4_opacity', overlay: 4, min: 0, max: 1, step: 0.05, nui: 'updateOverlay', arg: 'opacity' },
                    { type: 'spinner', label: 'Blush Style',     key: 'ov5_index',   overlay: 5, nui: 'updateOverlay' },
                    { type: 'slider',  label: 'Blush Opacity',   key: 'ov5_opacity', overlay: 5, min: 0, max: 1, step: 0.05, nui: 'updateOverlay', arg: 'opacity' },
                    { type: 'colors',  label: 'Blush Color',     key: 'ov5_color',   overlay: 5, palette: BLUSH_COLORS, nui: 'updateOverlay', arg: 'color1' },
                    { type: 'spinner', label: 'Lipstick Style',   key: 'ov8_index',   overlay: 8, nui: 'updateOverlay' },
                    { type: 'slider',  label: 'Lipstick Opacity', key: 'ov8_opacity', overlay: 8, min: 0, max: 1, step: 0.05, nui: 'updateOverlay', arg: 'opacity' },
                    { type: 'colors',  label: 'Lipstick Color',   key: 'ov8_color',   overlay: 8, palette: LIPSTICK_COLORS, nui: 'updateOverlay', arg: 'color1' },
                ]
            },
            {
                title: 'Body Details',
                items: [
                    { type: 'spinner', label: 'Chest Hair Style', key: 'ov10_index',   overlay: 10, nui: 'updateOverlay' },
                    { type: 'slider',  label: 'Chest Opacity',    key: 'ov10_opacity', overlay: 10, min: 0, max: 1, step: 0.05, nui: 'updateOverlay', arg: 'opacity' },
                    { type: 'colors',  label: 'Chest Color',      key: 'ov10_color',   overlay: 10, palette: HAIR_COLORS, nui: 'updateOverlay', arg: 'color1' },
                    { type: 'spinner', label: 'Body Blemishes',   key: 'ov11_index',   overlay: 11, nui: 'updateOverlay' },
                    { type: 'slider',  label: 'Blemishes Opacity', key: 'ov11_opacity', overlay: 11, min: 0, max: 1, step: 0.05, nui: 'updateOverlay', arg: 'opacity' },
                ]
            }
        ]
    }
};

// Eye color hex for display
const EYE_COLORS = [
    '#5b8c5a','#4e7db0','#6b4c8c','#a66a3a','#2e2e2e','#c7a060','#2e5c3a',
    '#3a4e8c','#7a3a3a','#4a4a4a','#8c7a2e','#5c8c7a','#3a6e8c','#5a4e6a','#6a3a2e','#8c8c8c',
    '#d4af37','#1a4a2a','#2a3a8c','#7a2e5c','#3a5c2a','#8c3a2e','#2e8c7a','#5c5c2a','#4a2e5c',
    '#8c5a2a'
];

// ── NUI Bridge ────────────────────────────────────────────────────────────────
function nuiPost(eventName, data) {
    return fetch(`https://bucu_identity/${eventName}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data || {})
    }).then(r => r.json()).catch(() => ({}));
}

// ── Debounce utility ──────────────────────────────────────────────────────────
function debounce(fn, delay) {
    let timer;
    return function(...args) {
        clearTimeout(timer);
        timer = setTimeout(() => fn.apply(this, args), delay);
    };
}

// ── Localization ──────────────────────────────────────────────────────────────
function t(key) {
    return State.locales[key] || key;
}

// ── App Visibility ─────────────────────────────────────────────────────────────
function showApp() {
    document.getElementById('identity-app').classList.remove('hidden');
}
function hideApp() {
    document.getElementById('identity-app').classList.add('hidden');
}
function showStep(step) {
    const root = document.getElementById('identity-app');
    document.querySelectorAll('.step-panel').forEach(p => {
        p.classList.add('hidden');
        p.classList.remove('active');
    });
    const panel = document.getElementById(`step-${step}`);
    if (panel) {
        panel.classList.remove('hidden');
        panel.classList.add('active');
    }
    State.currentStep = step;
    if (step === 'creator') {
        root.classList.add('creator-mode');
    } else {
        root.classList.remove('creator-mode');
    }
}

// ── STEP 1: Identity Form Logic ───────────────────────────────────────────────
function initStep1() {
    const form       = document.getElementById('identity-form');
    const btnCancel  = document.getElementById('btn-s1-cancel');
    const errBox     = document.getElementById('s1-error');

    // Gender click
    document.querySelectorAll('.gender-option').forEach(opt => {
        opt.addEventListener('click', () => {
            document.querySelectorAll('.gender-option').forEach(o => o.classList.remove('selected'));
            opt.classList.add('selected');
            State.identity.gender = opt.querySelector('input').value;
        });
    });

    btnCancel.addEventListener('click', () => {
        nuiPost('close');
        hideApp();
    });

    form.addEventListener('submit', (e) => {
        e.preventDefault();
        errBox.classList.add('hidden');

        const firstname   = document.getElementById('inp-firstname').value.trim();
        const lastname    = document.getElementById('inp-lastname').value.trim();
        const dob         = document.getElementById('inp-dob').value;
        const nationality = document.getElementById('inp-nationality').value.trim();
        const gender      = State.identity.gender;

        // Validation
        if (!firstname || firstname.length < 2 || !/^[a-zA-Z\s\-]+$/.test(firstname) ||
            !lastname  || lastname.length < 2  || !/^[a-zA-Z\s\-]+$/.test(lastname)) {
            errBox.textContent = t('err_invalid_name');
            errBox.classList.remove('hidden');
            return;
        }

        State.identity = { firstname, lastname, dob, nationality, gender };

        // Switch model if female
        const model = gender === 'female' ? 'mp_f_freemode_01' : 'mp_m_freemode_01';
        State.skin.model = model;
        nuiPost('switchModel', { model });

        // Advance to creator
        showStep('creator');
        setCameraView(State.activeTab === 'face' || State.activeTab === 'hair' ? 'head' : 'full');
        renderOptionsPanel(State.activeTab);
        updateCharInfoStrip();
    });
}

// ── STEP 2: Character Creator Logic ──────────────────────────────────────────

function updateCharInfoStrip() {
    const strip = document.getElementById('creator-char-info');
    const id    = State.identity;
    strip.innerHTML = `<strong>${id.firstname} ${id.lastname}</strong> &nbsp;·&nbsp; ${id.dob} &nbsp;·&nbsp; ${id.gender === 'female' ? '♀' : '♂'}`;
}

// Helper to switch active camera view and notify Lua
function setCameraView(viewName) {
    State.activeView = viewName;
    document.querySelectorAll('.cam-btn').forEach(b => {
        b.classList.toggle('active', b.dataset.view === viewName);
    });
    nuiPost('setCamera', { view: viewName });
}

// Tab switching with smart camera auto-framing
function initTabNav() {
    document.querySelectorAll('.tab-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            State.activeTab = btn.dataset.tab;

            // Auto-frame camera based on category for optimal visibility
            if (State.activeTab === 'face' || State.activeTab === 'hair') {
                setCameraView('head');
            } else if (State.activeTab === 'body') {
                setCameraView('torso');
            } else if (State.activeTab === 'clothing') {
                setCameraView('full');
            }

            renderOptionsPanel(State.activeTab);
        });
    });
}

// Camera view buttons (Full, Head, Torso, Legs)
function initCamControls() {
    document.querySelectorAll('.cam-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            setCameraView(btn.dataset.view);
        });
    });
}

// Rotate and Zoom controls
function initRotateControls() {
    const btnLeft  = document.getElementById('btn-rotate-left');
    const btnReset = document.getElementById('btn-rotate-reset');
    const btnRight = document.getElementById('btn-rotate-right');

    if (btnLeft) {
        btnLeft.addEventListener('click', () => {
            nuiPost('rotatePed', { angle: -25 });
        });
    }
    if (btnReset) {
        btnReset.addEventListener('click', () => {
            nuiPost('rotatePed', { angle: 0, reset: true });
        });
    }
    if (btnRight) {
        btnRight.addEventListener('click', () => {
            nuiPost('rotatePed', { angle: 25 });
        });
    }

    // Intuitive mouse drag to rotate + mouse wheel to zoom on center preview area
    const preview = document.querySelector('.creator-preview');
    if (preview) {
        let isDragging = false;
        let lastX = 0;

        preview.addEventListener('mousedown', (e) => {
            isDragging = true;
            lastX = e.clientX;
        });

        window.addEventListener('mousemove', (e) => {
            if (!isDragging || State.currentStep !== 'creator') return;
            const deltaX = e.clientX - lastX;
            if (Math.abs(deltaX) >= 2) {
                nuiPost('rotatePed', { angle: deltaX * -0.65 });
                lastX = e.clientX;
            }
        });

        window.addEventListener('mouseup', () => {
            isDragging = false;
        });

        // Mouse wheel smoothly zooms camera in/out
        preview.addEventListener('wheel', (e) => {
            if (State.currentStep !== 'creator') return;
            e.preventDefault();
            nuiPost('zoomCam', { delta: e.deltaY > 0 ? 3.0 : -3.0 });
        }, { passive: false });
    }
}

// Back button
function initCreatorBack() {
    document.getElementById('btn-creator-back').addEventListener('click', () => {
        showStep('identity');
    });
}

// Finish & Save
function initCreatorFinish() {
    document.getElementById('btn-creator-finish').addEventListener('click', () => {
        nuiPost('saveCharacter', {
            identity: State.identity,
            slot:     State.slot
        });
    });
}

// ── Options Panel Renderer ────────────────────────────────────────────────────
function renderOptionsPanel(tabKey) {
    const panel = document.getElementById('creator-options-panel');
    const tabDef = TABS[tabKey];
    if (!tabDef) { panel.innerHTML = ''; return; }

    panel.innerHTML = '';
    panel.classList.add('fade-enter');
    setTimeout(() => panel.classList.remove('fade-enter'), 400);

    tabDef.groups.forEach(group => {
        const groupEl = document.createElement('div');
        groupEl.className = 'option-group';

        const titleEl = document.createElement('div');
        titleEl.className = 'option-group-title';
        titleEl.textContent = group.title;
        groupEl.appendChild(titleEl);

        group.items.forEach(item => {
            groupEl.appendChild(buildOptionItem(item));
        });

        panel.appendChild(groupEl);
    });
}

function buildOptionItem(item) {
    switch (item.type) {
        case 'parent':            return buildParentSelector(item);
        case 'slider':            return buildSlider(item);
        case 'spinner':           return buildSpinner(item);
        case 'clothing_item':     return buildClothingItem(item);
        case 'prop_item':         return buildPropItem(item);
        case 'colors':            return buildColorPalette(item);
        case 'eyecolor':          return buildEyeColorPicker(item);
        case 'skintone_preset':   return buildSkinTonePreset(item);
        case 'body_preset':       return buildBodyPresetSelector(item);
        case 'body_scale_slider': return buildBodyScaleSlider(item);
        default:                  return document.createElement('div');
    }
}

// Parent (Heritage) Selector
function buildParentSelector(item) {
    const wrap = document.createElement('div');
    wrap.className = 'spinner-row parent-row';

    const list = item.gender === 'male' ? FATHERS : MOTHERS;
    const currentId = (State.skin.headBlend && (item.gender === 'male' ? State.skin.headBlend.shapeFirst : State.skin.headBlend.shapeSecond)) ?? (item.gender === 'male' ? 0 : 21);

    let currentIndex = list.findIndex(p => p.id === currentId);
    if (currentIndex < 0) currentIndex = 0;

    wrap.innerHTML = `
        <label>${item.label}</label>
        <div class="spinner parent-spinner">
            <button type="button" class="spinner-btn spinner-btn-dec">−</button>
            <span class="spinner-val parent-name">${list[currentIndex].name}</span>
            <button type="button" class="spinner-btn spinner-btn-inc">+</button>
        </div>
    `;

    const nameEl = wrap.querySelector('.parent-name');
    const decBtn = wrap.querySelector('.spinner-btn-dec');
    const incBtn = wrap.querySelector('.spinner-btn-inc');

    const update = (newIdx) => {
        if (newIdx < 0) newIdx = list.length - 1;
        if (newIdx >= list.length) newIdx = 0;
        currentIndex = newIdx;
        const parent = list[currentIndex];
        nameEl.textContent = parent.name;

        if (!State.skin.headBlend) {
            State.skin.headBlend = { shapeFirst: 0, shapeSecond: 21, skinFirst: 0, skinSecond: 21, shapeMix: 0.5, skinMix: 0.5 };
        }

        if (item.gender === 'male') {
            State.skin.headBlend.shapeFirst = parent.id;
            State.skin.headBlend.skinFirst  = parent.id;
        } else {
            State.skin.headBlend.shapeSecond = parent.id;
            State.skin.headBlend.skinSecond  = parent.id;
        }

        nuiPost('updateHeadBlend', {
            shapeFirst:  State.skin.headBlend.shapeFirst,
            shapeSecond: State.skin.headBlend.shapeSecond,
            skinFirst:   State.skin.headBlend.skinFirst,
            skinSecond:  State.skin.headBlend.skinSecond,
            shapeMix:    State.skin.headBlend.shapeMix,
            skinMix:     State.skin.headBlend.skinMix
        });
    };

    decBtn.addEventListener('click', () => update(currentIndex - 1));
    incBtn.addEventListener('click', () => update(currentIndex + 1));
    return wrap;
}

// Slider
function buildSlider(item) {
    const wrap    = document.createElement('div');
    wrap.className = 'option-row';

    const curVal = getStateVal(item) ?? 0;

    wrap.innerHTML = `
        <div class="option-row-label">
            <span>${item.label}</span>
            <span class="val">${Number(curVal).toFixed(2)}</span>
        </div>
        <input type="range"
            min="${item.min ?? 0}"
            max="${item.max ?? 1}"
            step="${item.step ?? 0.05}"
            value="${curVal}">
    `;

    const input = wrap.querySelector('input');
    const valEl = wrap.querySelector('.val');

    const handler = debounce((val) => {
        valEl.textContent = Number(val).toFixed(2);
        if (item.nui === 'updateHeadBlend') {
            if (!State.skin.headBlend) {
                State.skin.headBlend = { shapeFirst: 0, shapeSecond: 21, skinFirst: 0, skinSecond: 21, shapeMix: 0.5, skinMix: 0.5 };
            }
            const fVal = parseFloat(val);
            if (item.arg === 'shapeMix') State.skin.headBlend.shapeMix = fVal;
            if (item.arg === 'skinMix')  State.skin.headBlend.skinMix = fVal;
            nuiPost('updateHeadBlend', {
                shapeFirst:  State.skin.headBlend.shapeFirst,
                shapeSecond: State.skin.headBlend.shapeSecond,
                skinFirst:   State.skin.headBlend.skinFirst,
                skinSecond:  State.skin.headBlend.skinSecond,
                shapeMix:    State.skin.headBlend.shapeMix,
                skinMix:     State.skin.headBlend.skinMix
            });
        } else if (item.key === 'ff') {
            State.skin.faceFeatures[item.index] = parseFloat(val);
            nuiPost('updateFaceFeature', { index: item.index, scale: parseFloat(val) });
        } else if (item.overlay !== undefined) {
            if (!State.skin.overlays[item.overlay]) State.skin.overlays[item.overlay] = { index: 0, opacity: 1.0, color1: 0, color2: 0 };
            if (item.arg === 'opacity') {
                const opVal = parseFloat(val);
                State.skin.overlays[item.overlay].opacity = opVal;
                nuiPost('updateOverlay', {
                    index: item.overlay,
                    value: State.skin.overlays[item.overlay].index ?? 0,
                    opacity: opVal,
                    color1: State.skin.overlays[item.overlay].color1 ?? 0,
                    color2: State.skin.overlays[item.overlay].color2 ?? 0
                });
            } else {
                const intVal = Math.round(val);
                State.skin.overlays[item.overlay].index = intVal;
                let op = State.skin.overlays[item.overlay].opacity;
                if (intVal >= 0 && intVal !== 255) {
                    if (op === undefined || op === null || op <= 0.0) {
                        op = 1.0;
                        State.skin.overlays[item.overlay].opacity = 1.0;
                    }
                }
                nuiPost('updateOverlay', {
                    index: item.overlay,
                    value: intVal,
                    opacity: op,
                    color1: State.skin.overlays[item.overlay].color1 ?? 0,
                    color2: State.skin.overlays[item.overlay].color2 ?? 0
                });
            }
        } else if (item.component !== undefined) {
            const intVal = Math.round(val);
            if (!State.skin.components[item.component]) State.skin.components[item.component] = { drawable: 0, texture: 0 };
            State.skin.components[item.component].drawable = intVal;
            nuiPost('updateComponent', { componentId: item.component, drawableId: intVal, textureId: 0 });
        }
    }, 40);

    input.addEventListener('input', (e) => handler(e.target.value));
    return wrap;
}

// Number Spinner
function buildSpinner(item) {
    const wrap = document.createElement('div');
    wrap.className = 'spinner-row';

    const curVal = getStateVal(item) || 0;

    wrap.innerHTML = `
        <label>${item.label}</label>
        <div class="spinner">
            <button type="button" class="spinner-btn spinner-btn-dec">−</button>
            <span class="spinner-val">${curVal}</span>
            <button type="button" class="spinner-btn spinner-btn-inc">+</button>
            <span class="spinner-tex">/ ?</span>
        </div>
    `;

    const valEl  = wrap.querySelector('.spinner-val');
    const texEl  = wrap.querySelector('.spinner-tex');
    const decBtn = wrap.querySelector('.spinner-btn-dec');
    const incBtn = wrap.querySelector('.spinner-btn-inc');

    // Fetch max from Lua
    let maxVal = 99;
    const payload = {};
    if (item.component !== undefined)     { payload.type = 'component'; payload.id = item.component; }
    else if (item.prop !== undefined)    { payload.type = 'prop';      payload.id = item.prop; }
    else if (item.overlay !== undefined) { payload.type = 'overlay';   payload.id = item.overlay; }

    nuiPost('getMaxDrawable', payload).then(res => {
        maxVal = (res && res.max != null) ? res.max : 99;
        texEl.textContent = `/ ${maxVal}`;
    });

    let curNum = curVal;

    const update = (newVal) => {
        const minVal = (item.prop !== undefined || item.overlay !== undefined) ? -1 : 0;
        curNum = Math.max(minVal, Math.min(newVal, maxVal));
        valEl.textContent = curNum === -1 ? 'Off' : curNum;

        // Prioritize updateHair if nui is 'updateHair'
        if (item.nui === 'updateHair') {
            if (!State.skin.hair) State.skin.hair = { style: 0, color: 0, highlight: 0 };
            State.skin.hair.style = curNum;
            if (State.skin.components) {
                if (!State.skin.components[2]) State.skin.components[2] = { drawable: 0, texture: 0 };
                State.skin.components[2].drawable = curNum;
            }
            nuiPost('updateHair', {
                hairId: curNum,
                colorId: State.skin.hair.color || 0,
                highlightId: State.skin.hair.highlight || 0
            });
        } else if (item.component !== undefined) {
            if (!State.skin.components[item.component]) State.skin.components[item.component] = { drawable: 0, texture: 0 };
            State.skin.components[item.component].drawable = curNum;
            nuiPost('updateComponent', { componentId: item.component, drawableId: curNum, textureId: 0 });
        } else if (item.prop !== undefined) {
            if (!State.skin.props[item.prop]) State.skin.props[item.prop] = { drawable: -1, texture: 0 };
            State.skin.props[item.prop].drawable = curNum;
            nuiPost('updateProp', { propId: item.prop, drawableId: curNum, textureId: 0 });
        } else if (item.overlay !== undefined) {
            if (!State.skin.overlays[item.overlay]) {
                State.skin.overlays[item.overlay] = { index: 0, opacity: 1.0, color1: 0, color2: 0 };
            }
            State.skin.overlays[item.overlay].index = curNum;
            let op = State.skin.overlays[item.overlay].opacity;
            if (curNum >= 0 && curNum !== 255) {
                if (op === undefined || op === null || op <= 0.0) {
                    op = 1.0;
                    State.skin.overlays[item.overlay].opacity = 1.0;
                }
            } else {
                op = 0.0;
                State.skin.overlays[item.overlay].opacity = 0.0;
            }
            const color1 = State.skin.overlays[item.overlay].color1 ?? 0;
            const color2 = State.skin.overlays[item.overlay].color2 ?? color1;
            nuiPost('updateOverlay', {
                index: item.overlay,
                value: curNum,
                opacity: op,
                color1: color1,
                color2: color2
            });
        }
    };

    decBtn.addEventListener('click', () => update(curNum - 1));
    incBtn.addEventListener('click', () => update(curNum + 1));
    return wrap;
}

// ── Dual Clothing Item (Model + Color/Texture Variant) ────────────────────────
function buildClothingItem(item) {
    const wrap = document.createElement('div');
    wrap.className = 'clothing-card';

    if (!State.skin.components) State.skin.components = {};
    if (!State.skin.components[item.component]) {
        State.skin.components[item.component] = { drawable: 0, texture: 0 };
    }
    let curDraw = State.skin.components[item.component].drawable || 0;
    let curTex  = State.skin.components[item.component].texture  || 0;

    wrap.innerHTML = `
        <div class="clothing-card-header">
            <span class="clothing-card-title">${item.label}</span>
            <span class="clothing-card-badge">Model #${curDraw} · Warna #${curTex}</span>
        </div>
        <div class="clothing-controls-grid">
            <div class="clothing-control-item">
                <span class="clothing-control-label">Pilihan Model</span>
                <div class="spinner">
                    <button type="button" class="spinner-btn btn-draw-dec">−</button>
                    <span class="spinner-val val-draw">${curDraw}</span>
                    <button type="button" class="spinner-btn btn-draw-inc">+</button>
                    <span class="spinner-tex max-draw">/ ?</span>
                </div>
            </div>
            <div class="clothing-control-item">
                <span class="clothing-control-label">Warna / Motif</span>
                <div class="spinner">
                    <button type="button" class="spinner-btn btn-tex-dec">−</button>
                    <span class="spinner-val val-tex">${curTex}</span>
                    <button type="button" class="spinner-btn btn-tex-inc">+</button>
                    <span class="spinner-tex max-tex">/ ?</span>
                </div>
            </div>
        </div>
    `;

    const badgeEl  = wrap.querySelector('.clothing-card-badge');
    const valDraw  = wrap.querySelector('.val-draw');
    const maxDrawEl= wrap.querySelector('.max-draw');
    const valTex   = wrap.querySelector('.val-tex');
    const maxTexEl = wrap.querySelector('.max-tex');

    const btnDrawDec = wrap.querySelector('.btn-draw-dec');
    const btnDrawInc = wrap.querySelector('.btn-draw-inc');
    const btnTexDec  = wrap.querySelector('.btn-tex-dec');
    const btnTexInc  = wrap.querySelector('.btn-tex-inc');

    let maxDraw = 99;
    let maxTex  = 0;

    const updateBadge = () => {
        badgeEl.textContent = `Model #${curDraw} · Warna #${curTex}`;
    };

    const queryMaxTextures = (drawable) => {
        nuiPost('getMaxDrawable', {
            type: 'texture',
            componentId: item.component,
            drawableId: drawable
        }).then(res => {
            maxTex = (res && res.max != null) ? res.max : 0;
            maxTexEl.textContent = `/ ${maxTex}`;
            if (curTex > maxTex) {
                curTex = 0;
                valTex.textContent = curTex;
                updateBadge();
                State.skin.components[item.component].texture = curTex;
                nuiPost('updateComponent', {
                    componentId: item.component,
                    drawableId: curDraw,
                    textureId: curTex
                });
            }
        });
    };

    // Query initial max drawables and textures
    nuiPost('getMaxDrawable', { type: 'component', id: item.component }).then(res => {
        maxDraw = (res && res.max != null) ? res.max : 99;
        maxDrawEl.textContent = `/ ${maxDraw}`;
    });
    queryMaxTextures(curDraw);

    const updateDrawable = (newDraw) => {
        curDraw = Math.max(0, Math.min(newDraw, maxDraw));
        valDraw.textContent = curDraw;
        curTex = 0;
        valTex.textContent = curTex;
        updateBadge();

        State.skin.components[item.component].drawable = curDraw;
        State.skin.components[item.component].texture  = curTex;

        nuiPost('updateComponent', {
            componentId: item.component,
            drawableId: curDraw,
            textureId: curTex
        });
        queryMaxTextures(curDraw);
    };

    const updateTexture = (newTex) => {
        curTex = Math.max(0, Math.min(newTex, maxTex));
        valTex.textContent = curTex;
        updateBadge();

        State.skin.components[item.component].texture = curTex;

        nuiPost('updateComponent', {
            componentId: item.component,
            drawableId: curDraw,
            textureId: curTex
        });
    };

    btnDrawDec.addEventListener('click', () => updateDrawable(curDraw - 1));
    btnDrawInc.addEventListener('click', () => updateDrawable(curDraw + 1));
    btnTexDec.addEventListener('click',  () => updateTexture(curTex - 1));
    btnTexInc.addEventListener('click',  () => updateTexture(curTex + 1));

    return wrap;
}

// ── Dual Prop Item (Model + Color/Texture Variant) ────────────────────────────
function buildPropItem(item) {
    const wrap = document.createElement('div');
    wrap.className = 'clothing-card';

    if (!State.skin.props) State.skin.props = {};
    if (!State.skin.props[item.prop]) {
        State.skin.props[item.prop] = { drawable: -1, texture: 0 };
    }
    let curDraw = State.skin.props[item.prop].drawable !== undefined ? State.skin.props[item.prop].drawable : -1;
    let curTex  = State.skin.props[item.prop].texture  || 0;

    wrap.innerHTML = `
        <div class="clothing-card-header">
            <span class="clothing-card-title">${item.label}</span>
            <span class="clothing-card-badge">${curDraw === -1 ? 'Off / Dilepas' : `Model #${curDraw} · Warna #${curTex}`}</span>
        </div>
        <div class="clothing-controls-grid">
            <div class="clothing-control-item">
                <span class="clothing-control-label">Pilihan Model</span>
                <div class="spinner">
                    <button type="button" class="spinner-btn btn-draw-dec">−</button>
                    <span class="spinner-val val-draw">${curDraw === -1 ? 'Off' : curDraw}</span>
                    <button type="button" class="spinner-btn btn-draw-inc">+</button>
                    <span class="spinner-tex max-draw">/ ?</span>
                </div>
            </div>
            <div class="clothing-control-item">
                <span class="clothing-control-label">Warna / Motif</span>
                <div class="spinner">
                    <button type="button" class="spinner-btn btn-tex-dec">−</button>
                    <span class="spinner-val val-tex">${curTex}</span>
                    <button type="button" class="spinner-btn btn-tex-inc">+</button>
                    <span class="spinner-tex max-tex">/ ?</span>
                </div>
            </div>
        </div>
    `;

    const badgeEl  = wrap.querySelector('.clothing-card-badge');
    const valDraw  = wrap.querySelector('.val-draw');
    const maxDrawEl= wrap.querySelector('.max-draw');
    const valTex   = wrap.querySelector('.val-tex');
    const maxTexEl = wrap.querySelector('.max-tex');

    const btnDrawDec = wrap.querySelector('.btn-draw-dec');
    const btnDrawInc = wrap.querySelector('.btn-draw-inc');
    const btnTexDec  = wrap.querySelector('.btn-tex-dec');
    const btnTexInc  = wrap.querySelector('.btn-tex-inc');

    let maxDraw = 99;
    let maxTex  = 0;

    const updateBadge = () => {
        badgeEl.textContent = curDraw === -1 ? 'Off / Dilepas' : `Model #${curDraw} · Warna #${curTex}`;
    };

    const queryMaxPropTextures = (drawable) => {
        if (drawable < 0) {
            maxTex = 0;
            maxTexEl.textContent = '/ 0';
            return;
        }
        nuiPost('getMaxDrawable', {
            type: 'prop_texture',
            propId: item.prop,
            drawableId: drawable
        }).then(res => {
            maxTex = (res && res.max != null) ? res.max : 0;
            maxTexEl.textContent = `/ ${maxTex}`;
            if (curTex > maxTex) {
                curTex = 0;
                valTex.textContent = curTex;
                updateBadge();
                State.skin.props[item.prop].texture = curTex;
                nuiPost('updateProp', {
                    propId: item.prop,
                    drawableId: curDraw,
                    textureId: curTex
                });
            }
        });
    };

    nuiPost('getMaxDrawable', { type: 'prop', id: item.prop }).then(res => {
        maxDraw = (res && res.max != null) ? res.max : 99;
        maxDrawEl.textContent = `/ ${maxDraw}`;
    });
    queryMaxPropTextures(curDraw);

    const updateDrawable = (newDraw) => {
        curDraw = Math.max(-1, Math.min(newDraw, maxDraw));
        valDraw.textContent = curDraw === -1 ? 'Off' : curDraw;
        curTex = 0;
        valTex.textContent = curTex;
        updateBadge();

        State.skin.props[item.prop].drawable = curDraw;
        State.skin.props[item.prop].texture  = curTex;

        nuiPost('updateProp', {
            propId: item.prop,
            drawableId: curDraw,
            textureId: curTex
        });
        queryMaxPropTextures(curDraw);
    };

    const updateTexture = (newTex) => {
        if (curDraw < 0) return;
        curTex = Math.max(0, Math.min(newTex, maxTex));
        valTex.textContent = curTex;
        updateBadge();

        State.skin.props[item.prop].texture = curTex;

        nuiPost('updateProp', {
            propId: item.prop,
            drawableId: curDraw,
            textureId: curTex
        });
    };

    btnDrawDec.addEventListener('click', () => updateDrawable(curDraw - 1));
    btnDrawInc.addEventListener('click', () => updateDrawable(curDraw + 1));
    btnTexDec.addEventListener('click',  () => updateTexture(curTex - 1));
    btnTexInc.addEventListener('click',  () => updateTexture(curTex + 1));

    return wrap;
}

// Color Palette
function buildColorPalette(item) {
    const wrap = document.createElement('div');
    wrap.className = 'option-row';

    const curColor = getStateVal(item) || 0;

    wrap.innerHTML = `<div class="option-row-label"><span>${item.label}</span></div>
                      <div class="color-palette"></div>`;

    const palette = wrap.querySelector('.color-palette');
    const colors  = item.palette || HAIR_COLORS;

    colors.forEach((hex, i) => {
        const swatch = document.createElement('div');
        swatch.className = 'color-swatch' + (i === curColor ? ' active' : '');
        swatch.style.background = hex;
        swatch.dataset.index = i;
        swatch.title = `Color ${i}`;

        swatch.addEventListener('click', () => {
            palette.querySelectorAll('.color-swatch').forEach(s => s.classList.remove('active'));
            swatch.classList.add('active');
            const colorIdx = parseInt(swatch.dataset.index);

            if (item.nui === 'updateHair') {
                if (!State.skin.hair) State.skin.hair = { style: 0, color: 0, highlight: 0 };
                if (item.arg === 'colorId') {
                    State.skin.hair.color = colorIdx;
                    nuiPost('updateHair', {
                        hairId: State.skin.hair.style || 0,
                        colorId: colorIdx,
                        highlightId: State.skin.hair.highlight || 0
                    });
                } else if (item.arg === 'highlightId') {
                    State.skin.hair.highlight = colorIdx;
                    nuiPost('updateHair', {
                        hairId: State.skin.hair.style || 0,
                        colorId: State.skin.hair.color || 0,
                        highlightId: colorIdx
                    });
                }
            } else if (item.nui === 'updateOverlay' && item.overlay !== undefined) {
                if (!State.skin.overlays[item.overlay]) State.skin.overlays[item.overlay] = { index: 0, opacity: 1.0 };
                State.skin.overlays[item.overlay].color1 = colorIdx;
                State.skin.overlays[item.overlay].color2 = colorIdx;
                nuiPost('updateOverlay', {
                    index: item.overlay,
                    value: State.skin.overlays[item.overlay].index || 0,
                    opacity: State.skin.overlays[item.overlay].opacity ?? 1.0,
                    color1: colorIdx,
                    color2: colorIdx
                });
            }
        });
        palette.appendChild(swatch);
    });

    return wrap;
}

// Eye Color Picker (26 preset + display)
function buildEyeColorPicker(item) {
    const wrap = document.createElement('div');
    wrap.className = 'option-row';

    const cur = State.skin.eyeColor || 0;
    wrap.innerHTML = `<div class="option-row-label"><span>${item.label}</span></div>
                      <div class="color-palette"></div>`;

    const palette = wrap.querySelector('.color-palette');
    EYE_COLORS.forEach((hex, i) => {
        const swatch = document.createElement('div');
        swatch.className = 'color-swatch' + (i === cur ? ' active' : '');
        swatch.style.background = hex;
        swatch.dataset.index = i;
        swatch.title = `Eye Color ${i}`;

        swatch.addEventListener('click', () => {
            palette.querySelectorAll('.color-swatch').forEach(s => s.classList.remove('active'));
            swatch.classList.add('active');
            State.skin.eyeColor = i;
            nuiPost('updateEyeColor', { colorId: i });
        });
        palette.appendChild(swatch);
    });
    return wrap;
}

// Skin Tone Preset Selector (Genetic Tone Palette)
function buildSkinTonePreset(item) {
    const wrap = document.createElement('div');
    wrap.className = 'option-row';

    wrap.innerHTML = `<div class="option-row-label"><span>${item.label}</span></div>
                      <div class="color-palette skin-palette"></div>`;

    const palette = wrap.querySelector('.color-palette');
    const curFirst = (State.skin.headBlend && State.skin.headBlend.skinFirst !== undefined) ? State.skin.headBlend.skinFirst : 0;

    SKIN_PRESETS.forEach((preset, i) => {
        const swatch = document.createElement('div');
        swatch.className = 'color-swatch' + (preset.skinFirst === curFirst ? ' active' : '');
        swatch.style.background = preset.hex;
        swatch.dataset.index = i;
        swatch.title = preset.name;

        swatch.addEventListener('click', () => {
            palette.querySelectorAll('.color-swatch').forEach(s => s.classList.remove('active'));
            swatch.classList.add('active');

            if (!State.skin.headBlend) {
                State.skin.headBlend = { shapeFirst: 0, shapeSecond: 21, skinFirst: 0, skinSecond: 21, shapeMix: 0.5, skinMix: 0.5 };
            }
            State.skin.headBlend.skinFirst  = preset.skinFirst;
            State.skin.headBlend.skinSecond = preset.skinSecond;

            nuiPost('updateHeadBlend', {
                shapeFirst:  State.skin.headBlend.shapeFirst,
                shapeSecond: State.skin.headBlend.shapeSecond,
                skinFirst:   preset.skinFirst,
                skinSecond:  preset.skinSecond,
                shapeMix:    State.skin.headBlend.shapeMix,
                skinMix:     State.skin.headBlend.skinMix
            });
        });

        palette.appendChild(swatch);
    });

    return wrap;
}

// Body Build Preset Selector (Skinny, Standard, Muscular, Heavy)
function buildBodyPresetSelector(item) {
    const wrap = document.createElement('div');
    wrap.className = 'body-presets';

    BODY_BUILD_PRESETS.forEach(preset => {
        const card = document.createElement('div');
        const isActive = (State.activeBodyPreset === preset.id) || (!State.activeBodyPreset && preset.id === 'standard');
        card.className = 'body-preset-card' + (isActive ? ' active' : '');

        card.innerHTML = `
            <span class="body-preset-icon">${preset.icon}</span>
            <span class="body-preset-name">${preset.name}</span>
            <span class="body-preset-desc">${preset.desc}</span>
        `;

        card.addEventListener('click', () => {
            wrap.querySelectorAll('.body-preset-card').forEach(c => c.classList.remove('active'));
            card.classList.add('active');
            State.activeBodyPreset = preset.id;
            State.skin.bodyBuild = preset.id;

            if (!State.skin.bodyScale) {
                State.skin.bodyScale = { x: 1.0, y: 1.0, z: 1.0 };
            }
            State.skin.bodyScale.x = preset.scaleX;
            State.skin.bodyScale.y = preset.scaleY;
            State.skin.bodyScale.z = preset.scaleZ;

            // Apply upper body torso component if defined
            if (preset.component3 !== undefined) {
                if (!State.skin.components) State.skin.components = {};
                if (!State.skin.components[3]) State.skin.components[3] = { drawable: 0, texture: 0 };
                State.skin.components[3].drawable = preset.component3;
            }

            // Apply heritage head blend if defined
            if (preset.headBlend) {
                if (!State.skin.headBlend) State.skin.headBlend = {};
                State.skin.headBlend = Object.assign({}, State.skin.headBlend, preset.headBlend);
            }

            // Apply all preset morphs to State.skin.faceFeatures
            if (!State.skin.faceFeatures) State.skin.faceFeatures = {};
            Object.entries(preset.morphs).forEach(([idxStr, val]) => {
                const idx = parseInt(idxStr, 10);
                State.skin.faceFeatures[idx] = val;
            });

            // Post setBodyPreset NUI event with scale, morphs, headBlend, and component3
            nuiPost('setBodyPreset', {
                id: preset.id,
                scaleX: preset.scaleX,
                scaleY: preset.scaleY,
                scaleZ: preset.scaleZ,
                morphs: preset.morphs,
                headBlend: preset.headBlend,
                component3: preset.component3
            });

            // Re-render current options panel so sliders reflect the new preset values
            renderOptionsPanel(State.activeTab);
        });

        wrap.appendChild(card);
    });

    return wrap;
}

// Body Scale Slider (manual fine-tuning for X=width, Y=depth/chest/belly, Z=height)
function buildBodyScaleSlider(item) {
    const wrap = document.createElement('div');
    wrap.className = 'option-row';

    if (!State.skin.bodyScale) {
        State.skin.bodyScale = { x: 1.0, y: 1.0, z: 1.0 };
    }
    const curVal = State.skin.bodyScale[item.axis] != null ? State.skin.bodyScale[item.axis] : 1.0;

    wrap.innerHTML = `
        <div class="option-row-label">
            <span>${item.label}</span>
            <span class="val">${Number(curVal).toFixed(2)}</span>
        </div>
        <input type="range"
            min="${item.min ?? 0.75}"
            max="${item.max ?? 1.50}"
            step="${item.step ?? 0.01}"
            value="${curVal}">
    `;

    const input = wrap.querySelector('input');
    const valEl = wrap.querySelector('.val');

    const handler = debounce((val) => {
        valEl.textContent = Number(val).toFixed(2);
        const fVal = parseFloat(val);
        if (!State.skin.bodyScale) {
            State.skin.bodyScale = { x: 1.0, y: 1.0, z: 1.0 };
        }
        State.skin.bodyScale[item.axis] = fVal;
        State.activeBodyPreset = 'custom';
        State.skin.bodyBuild = 'custom';

        // Unset active highlight from preset cards if custom slider changed
        const activeCards = document.querySelectorAll('.body-preset-card.active');
        activeCards.forEach(c => c.classList.remove('active'));

        nuiPost('updateBodyScale', {
            axis: item.axis,
            val: fVal,
            scaleX: State.skin.bodyScale.x,
            scaleY: State.skin.bodyScale.y,
            scaleZ: State.skin.bodyScale.z
        });
    }, 30);

    input.addEventListener('input', (e) => handler(e.target.value));
    return wrap;
}

// ── State Value Helpers ────────────────────────────────────────────────────────
function getStateVal(item) {
    if (item.key === 'ff') return State.skin.faceFeatures[item.index] ?? 0;
    if (item.key === 'eyeColor') return State.skin.eyeColor ?? 0;
    if (item.key === 'hb_shapeMix') return (State.skin.headBlend && State.skin.headBlend.shapeMix) ?? 0.5;
    if (item.key === 'hb_skinMix')  return (State.skin.headBlend && State.skin.headBlend.skinMix) ?? 0.5;
    if (item.key === 'hair_style' || item.key === 'hair.style') return (State.skin.hair && State.skin.hair.style) ?? 0;
    if (item.key === 'hair_color' || item.key === 'hair.color') return (State.skin.hair && State.skin.hair.color) ?? 0;
    if (item.key === 'hair_highlight' || item.key === 'hair.highlight') return (State.skin.hair && State.skin.hair.highlight) ?? 0;
    if (item.overlay !== undefined) {
        const ov = State.skin.overlays[item.overlay] || {};
        if (item.arg === 'opacity') return ov.opacity ?? 1.0;
        if (item.arg === 'color1') return ov.color1 ?? 0;
        return ov.index ?? 0;
    }
    if (item.component !== undefined) return (State.skin.components[item.component] || {}).drawable ?? 0;
    if (item.prop !== undefined) return (State.skin.props[item.prop] || {}).drawable ?? -1;
    return 0;
}

// ── NUI Message Handler (from Lua) ────────────────────────────────────────────
window.addEventListener('message', (event) => {
    const msg = event.data;
    if (!msg || !msg.action) return;

    switch (msg.action) {
        case 'open':
            State.isOpen    = true;
            State.language  = msg.language || 'en';
            State.locales   = msg.locales  || {};
            State.slot      = msg.slot     || 1;
            if (msg.baseSkin) mergeSkin(msg.baseSkin);
            showApp();
            showStep('identity');
            break;

        case 'close':
            hideApp();
            State.isOpen = false;
            break;

        case 'skinUpdate':
            if (msg.skin) mergeSkin(msg.skin);
            break;
    }
});

function mergeSkin(newSkin) {
    if (!newSkin) return;
    State.skin = Object.assign({}, State.skin, newSkin);
    if (newSkin.headBlend) {
        State.skin.headBlend = Object.assign({}, State.skin.headBlend, newSkin.headBlend);
    }
    if (newSkin.bodyScale) {
        State.skin.bodyScale = Object.assign({}, State.skin.bodyScale, newSkin.bodyScale);
    }
    if (newSkin.bodyBuild) {
        State.skin.bodyBuild = newSkin.bodyBuild;
        State.activeBodyPreset = newSkin.bodyBuild;
    }
    // Re-render current tab if creator is open
    if (State.currentStep === 'creator') {
        renderOptionsPanel(State.activeTab);
    }
}

// ── Bootstrap ─────────────────────────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', () => {
    initStep1();
    initTabNav();
    initCamControls();
    initRotateControls();
    initCreatorBack();
    initCreatorFinish();

    // Dev mode: allow testing with Esc key
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') {
            nuiPost('close');
            hideApp();
        }
    });
});
