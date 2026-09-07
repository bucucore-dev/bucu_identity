-- ============================================================================
-- BUCU Identity — Bahasa Indonesia Locales
-- ============================================================================

Locales = Locales or {}
Locales['id'] = {
    -- Umum
    ['title_app']           = 'BUCU IDENTITY',
    ['subtitle_app']        = 'Sistem Registrasi Kependudukan',

    -- Step 1: Form Identitas
    ['step1_title']         = 'Registrasi Identitas',
    ['step1_subtitle']      = 'Isi data kependudukan resmi Anda dengan benar',
    ['field_firstname']     = 'Nama Depan',
    ['field_lastname']      = 'Nama Belakang',
    ['field_dob']           = 'Tanggal Lahir',
    ['field_gender']        = 'Jenis Kelamin',
    ['field_nationality']   = 'Kewarganegaraan',
    ['gender_male']         = 'Laki-laki',
    ['gender_female']       = 'Perempuan',
    ['btn_next']            = 'Lanjut: Buat Karakter',
    ['btn_cancel']          = 'Batal',
    ['placeholder_first']   = 'Budi',
    ['placeholder_last']    = 'Santoso',
    ['placeholder_nation']  = 'San Andreas',

    -- Step 2: Character Creator
    ['step2_title']         = 'Pembuat Karakter',
    ['step2_subtitle']      = 'Rancang identitas unik Anda',
    ['tab_face']            = 'Wajah',
    ['tab_hair']            = 'Rambut',
    ['tab_body']            = 'Tubuh',
    ['tab_clothing']        = 'Pakaian',
    ['tab_accessories']     = 'Aksesori',
    ['btn_prev']            = 'Kembali',
    ['btn_finish']          = 'Selesai & Masuk',
    ['rotate_left']         = 'Putar Kiri',
    ['rotate_right']        = 'Putar Kanan',
    ['view_full']           = 'Seluruh Tubuh',
    ['view_head']           = 'Kepala',
    ['view_torso']          = 'Badan',
    ['view_legs']           = 'Kaki',

    -- Wajah
    ['face_shape']          = 'Bentuk Wajah',
    ['nose_width']          = 'Lebar Hidung',
    ['nose_peak_height']    = 'Tinggi Ujung Hidung',
    ['nose_peak_length']    = 'Panjang Hidung',
    ['nose_bone_height']    = 'Tinggi Batang Hidung',
    ['nose_peak_lowered']   = 'Hidung Turun',
    ['nose_bone_twist']     = 'Lekukan Hidung',
    ['eyebrow_height']      = 'Tinggi Alis',
    ['eyebrow_forward']     = 'Alis ke Depan',
    ['cheek_bone_high']     = 'Tinggi Tulang Pipi',
    ['cheek_sideways']      = 'Lebar Pipi',
    ['cheek_width']         = 'Ukuran Pipi',
    ['eye_opening']         = 'Bukaan Mata',
    ['lip_thickness']       = 'Ketebalan Bibir',
    ['jaw_bone_width']      = 'Lebar Rahang',
    ['jaw_bone_back']       = 'Rahang ke Belakang',
    ['chin_height']         = 'Tinggi Dagu',
    ['chin_length']         = 'Panjang Dagu',
    ['chin_width']          = 'Lebar Dagu',
    ['chin_hole']           = 'Lesung Dagu',
    ['neck_thickness']      = 'Ketebalan Leher',
    ['skin_tone']           = 'Warna Kulit',
    ['eye_color']           = 'Warna Mata',

    -- Rambut
    ['hair_style']          = 'Gaya Rambut',
    ['hair_color']          = 'Warna Rambut',
    ['hair_highlight']      = 'Warna Sorotan',
    ['beard_style']         = 'Gaya Janggut',
    ['beard_color']         = 'Warna Janggut',
    ['eyebrow_style']       = 'Gaya Alis',
    ['eyebrow_color']       = 'Warna Alis',

    -- Tubuh
    ['body_build']          = 'Postur (Gemuk/Kurus)',
    ['body_muscle']         = 'Otot',
    ['blemishes']           = 'Noda Kulit',
    ['aging']               = 'Penuaan',
    ['complexion']          = 'Warna Kulit',
    ['sun_damage']          = 'Bekas Sinar Matahari',
    ['freckles']            = 'Bintik-bintik',

    -- Pakaian
    ['top_style']           = 'Atasan',
    ['pants_style']         = 'Celana',
    ['shoes_style']         = 'Sepatu',
    ['undershirt']          = 'Kaus Dalam',
    ['accessories']         = 'Aksesori',
    ['bag']                 = 'Tas',
    ['armor']               = 'Rompi',
    ['hat']                 = 'Topi',
    ['glasses']             = 'Kacamata',
    ['watch']               = 'Jam Tangan',
    ['bracelet']            = 'Gelang',

    -- Error
    ['err_invalid_name']    = 'Nama harus 2-25 huruf alfabet saja.',
    ['err_invalid_dob']     = 'Tanggal lahir tidak valid. Usia harus 18-90 tahun.',
    ['err_slot_occupied']   = 'Slot karakter ini sudah terisi.',
    ['err_server']          = 'Terjadi kesalahan server. Coba lagi.',

    -- Sukses
    ['notif_char_created']  = 'Karakter berhasil dibuat! Selamat datang di San Andreas.',
}
