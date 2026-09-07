-- ============================================================================
-- BUCU Identity — English Locales
-- ============================================================================

Locales = Locales or {}
Locales['en'] = {
    -- General
    ['title_app']           = 'BUCU IDENTITY',
    ['subtitle_app']        = 'Citizen Registration System',

    -- Step 1: Identity Form
    ['step1_title']         = 'Identity Registration',
    ['step1_subtitle']      = 'Fill in your official civil registry details',
    ['field_firstname']     = 'First Name',
    ['field_lastname']      = 'Last Name',
    ['field_dob']           = 'Date of Birth',
    ['field_gender']        = 'Gender',
    ['field_nationality']   = 'Nationality',
    ['gender_male']         = 'Male',
    ['gender_female']       = 'Female',
    ['btn_next']            = 'Next: Create Character',
    ['btn_cancel']          = 'Cancel',
    ['placeholder_first']   = 'Arthur',
    ['placeholder_last']    = 'Morgan',
    ['placeholder_nation']  = 'San Andreas',

    -- Step 2: Character Creator
    ['step2_title']         = 'Character Creator',
    ['step2_subtitle']      = 'Design your unique identity',
    ['tab_face']            = 'Face',
    ['tab_hair']            = 'Hair',
    ['tab_body']            = 'Body',
    ['tab_clothing']        = 'Clothing',
    ['tab_accessories']     = 'Accessories',
    ['btn_prev']            = 'Back',
    ['btn_finish']          = 'Finalize & Spawn',
    ['rotate_left']         = 'Rotate Left',
    ['rotate_right']        = 'Rotate Right',
    ['view_full']           = 'Full Body',
    ['view_head']           = 'Head',
    ['view_torso']          = 'Torso',
    ['view_legs']           = 'Legs',

    -- Face tabs
    ['face_shape']          = 'Face Shape',
    ['nose_width']          = 'Nose Width',
    ['nose_peak_height']    = 'Nose Peak Height',
    ['nose_peak_length']    = 'Nose Peak Length',
    ['nose_bone_height']    = 'Nose Bone Height',
    ['nose_peak_lowered']   = 'Nose Peak Lowered',
    ['nose_bone_twist']     = 'Nose Bone Twist',
    ['eyebrow_height']      = 'Eyebrow Height',
    ['eyebrow_forward']     = 'Eyebrow Forward',
    ['cheek_bone_high']     = 'Cheekbone Height',
    ['cheek_sideways']      = 'Cheek Width',
    ['cheek_width']         = 'Cheek Size',
    ['eye_opening']         = 'Eye Opening',
    ['lip_thickness']       = 'Lip Thickness',
    ['jaw_bone_width']      = 'Jaw Width',
    ['jaw_bone_back']       = 'Jaw Back',
    ['chin_height']         = 'Chin Height',
    ['chin_length']         = 'Chin Length',
    ['chin_width']          = 'Chin Width',
    ['chin_hole']           = 'Chin Dimple',
    ['neck_thickness']      = 'Neck Thickness',
    ['skin_tone']           = 'Skin Tone',
    ['eye_color']           = 'Eye Color',

    -- Hair
    ['hair_style']          = 'Hair Style',
    ['hair_color']          = 'Hair Color',
    ['hair_highlight']      = 'Highlight Color',
    ['beard_style']         = 'Beard Style',
    ['beard_color']         = 'Beard Color',
    ['eyebrow_style']       = 'Eyebrow Style',
    ['eyebrow_color']       = 'Eyebrow Color',

    -- Body
    ['body_build']          = 'Build (Fat/Thin)',
    ['body_muscle']         = 'Muscle',
    ['blemishes']           = 'Blemishes',
    ['aging']               = 'Aging',
    ['complexion']          = 'Complexion',
    ['sun_damage']          = 'Sun Damage',
    ['freckles']            = 'Freckles',

    -- Clothing
    ['top_style']           = 'Tops',
    ['pants_style']         = 'Pants',
    ['shoes_style']         = 'Shoes',
    ['undershirt']          = 'Undershirt',
    ['accessories']         = 'Accessories',
    ['bag']                 = 'Bags',
    ['armor']               = 'Armor',
    ['hat']                 = 'Hat',
    ['glasses']             = 'Glasses',
    ['watch']               = 'Watch',
    ['bracelet']            = 'Bracelet',

    -- Errors
    ['err_invalid_name']    = 'Name must be 2-25 letters only.',
    ['err_invalid_dob']     = 'Invalid date of birth. Age must be 18-90.',
    ['err_slot_occupied']   = 'This character slot is already taken.',
    ['err_server']          = 'Server error. Please try again.',

    -- Success
    ['notif_char_created']  = 'Character created successfully! Welcome to San Andreas.',
}
