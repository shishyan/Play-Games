--[[
    Assets.luau
    -----------
    Single source of truth for ALL asset IDs and ReplicatedStorage model paths.

    Rules:
      - Every asset reference in the codebase must come from this file.
      - Never hardcode an rbxassetid:// or model path string anywhere else.
      - Placeholder value is 0 (numbers) or "" (strings) — grep for 0 to find unset assets.
      - Sound IDs: assign to Sound.SoundId as  "rbxassetid://" .. Assets.SFX.OrbCollect
      - Image IDs: assign to ImageLabel.Image as "rbxassetid://" .. Assets.Icons.Cahaya
      - Animation IDs: assign to Animation.AnimationId as "rbxassetid://" .. Assets.Animations.EmoteWave
      - Model paths: ReplicatedStorage paths relative to ReplicatedStorage root.
]]

local Assets = {}

-- ─────────────────────────────────────────────
-- ICONS & UI IMAGES
-- Usage: ImageLabel.Image = "rbxassetid://" .. Assets.Icons.KEY
-- ─────────────────────────────────────────────
Assets.Icons = {
    -- Currency
    Cahaya          = 0,   -- Cahaya orb icon (HUD counter)
    CahayaHati      = 0,   -- Cahaya Hati / heart-light icon
    KoinMusim       = 0,   -- Seasonal coin icon
    BintangHati     = 0,   -- Gifting star icon

    -- Wing charge bar
    SegmentFull     = 0,   -- Single filled charge segment
    SegmentEmpty    = 0,   -- Single empty charge segment
    SegmentFlash    = 0,   -- Segment flash on boost use

    -- HUD general
    Compass         = 0,   -- Compass rose base
    CompassNeedle   = 0,   -- Rotating needle overlay
    AltitudeBar     = 0,   -- Sky's Peak altitude bar background
    FABBackground   = 0,   -- Mobile FAB button background

    -- Social Pulse
    PartnerOnline   = 0,   -- Green glow ring for online partner
    PartnerOffline  = 0,   -- Dimmed ring for offline partner
    PartnerNearby   = 0,   -- Pulsing ring when partner ≤40 studs

    -- Daily Task panel
    TaskEasy        = 0,   -- Easy difficulty badge icon
    TaskMedium      = 0,   -- Medium difficulty badge icon
    TaskHard        = 0,   -- Hard difficulty badge icon
    TaskComplete    = 0,   -- Checkmark overlay on completed task
    MilestoneChest  = 0,   -- Daily chest icon (tier 5 reward)
    StreakFlame     = 0,   -- Login streak flame icon

    -- Rarity tier badges
    RarityBiasa     = 0,   -- Common (white) rarity border
    RarityLangka    = 0,   -- Rare (blue) rarity border
    RarityEpik      = 0,   -- Epic (purple) rarity border
    RarityLegendaris = 0,  -- Legendary (gold) rarity border

    -- Inventory / Cosmetic categories
    CatCape         = 0,   -- Cape tab icon
    CatMask         = 0,   -- Mask tab icon
    CatHair         = 0,   -- Hair tab icon
    CatOutfit       = 0,   -- Outfit tab icon
    CatWingSkin     = 0,   -- Wing Skin tab icon
    CatInstrument   = 0,   -- Instrument tab icon
    CatEmote        = 0,   -- Emote tab icon
    CatTrail        = 0,   -- Trail tab icon
    CatAura         = 0,   -- Aura tab icon
    CatProp         = 0,   -- Prop tab icon

    -- Ikatan panel
    IkatanOffer     = 0,   -- Offer hand icon
    IkatanAccept    = 0,   -- Accept bond icon
    IkatanDecline   = 0,   -- Decline icon
    IkatanGift      = 0,   -- Gift icon
    IkatanTeleport  = 0,   -- Teleport-to-partner icon

    -- Season panel
    SeasonPass      = 0,   -- Musim Pass badge
    SeasonPassPlus  = 0,   -- Musim Pass+ badge
    QuestStep       = 0,   -- Inactive quest step dot
    QuestStepDone   = 0,   -- Completed quest step dot

    -- Notifications / Toast
    ToastInfo       = 0,   -- Info toast icon (blue)
    ToastSuccess    = 0,   -- Success toast icon (gold)
    ToastWarning    = 0,   -- Warning toast icon (orange)

    -- Spirit / Galeri Roh
    SpiritAncestor  = 0,   -- Ancestor Spirit silhouette icon
    SpiritSeason    = 0,   -- Season Spirit icon
    SpiritDaily     = 0,   -- Daily Spirit icon

    -- Emote wheel
    EmoteSlotEmpty  = 0,   -- Empty emote slot placeholder

    -- Instrument UI
    NoteButton      = 0,   -- Generic note button background
    StrumButton     = 0,   -- Strum button (Siter/Angklung)
    SustainButton   = 0,   -- Hold button (Terompet)
    ShakeIndicator  = 0,   -- Gyro shake visual cue (Angklung)

    -- Misc
    SettingsGear    = 0,   -- Settings menu icon
    CloseButton     = 0,   -- Panel close X button
    LockIcon        = 0,   -- Locked realm / gated content
}

-- ─────────────────────────────────────────────
-- TEXTURES (Decals, SurfaceAppearance, Skybox)
-- Usage: Decal.Texture = "rbxassetid://" .. Assets.Textures.KEY
-- ─────────────────────────────────────────────
Assets.Textures = {
    -- Skybox faces (6 sides per realm)
    SkyboxIsle = {
        Ft = 0, Bk = 0, Up = 0, Dn = 0, Rt = 0, Lt = 0,
    },
    SkyboxForest = {
        Ft = 0, Bk = 0, Up = 0, Dn = 0, Rt = 0, Lt = 0,
    },
    SkyboxWasteland = {
        Ft = 0, Bk = 0, Up = 0, Dn = 0, Rt = 0, Lt = 0,
    },
    SkyboxSkysPeak = {
        Ft = 0, Bk = 0, Up = 0, Dn = 0, Rt = 0, Lt = 0,
    },

    -- Voxel block surface palettes (used in SurfaceAppearance)
    BlockAtlas       = 0,  -- Main block texture atlas (all block types)
    BlockAtlasNormal = 0,  -- Normal map for block atlas

    -- Cahaya orb glow texture
    OrbGlow          = 0,  -- Billboard glow sprite on Cahaya orbs

    -- Kegelapan fog overlay
    FogOverlay       = 0,  -- Transparent fog texture for Kegelapan zones

    -- Wing trail texture
    TrailDefault     = 0,  -- Default wing trail texture (before cosmetic applied)
}

-- ─────────────────────────────────────────────
-- VFX — PARTICLE EMITTER TEMPLATES
-- These are model paths under ReplicatedStorage.Assets.VFX
-- Usage: local vfx = ReplicatedStorage.Assets.VFX[Assets.VFX.KEY]:Clone()
-- ─────────────────────────────────────────────
Assets.VFX = {
    -- Cahaya / Light
    OrbCollect      = "OrbCollect",       -- Burst on Cahaya orb collection
    OrbIdle         = "OrbIdle",          -- Ambient sparkle on floating orb
    Extinguished    = "Extinguished",     -- Puff of smoke when player extinguished
    Revived         = "Revived",          -- Warm burst on player revive
    CahayaGift      = "CahayaGift",       -- Particle trail during gift animation

    -- Flight
    BoostBurst      = "BoostBurst",       -- Wing burst on each boost
    GlideTrail      = "GlideTrail",       -- Thin trail during glide
    CarryLink       = "CarryLink",        -- Tether effect between carrier and carried

    -- Ikatan
    IkatanForm      = "IkatanForm",       -- Mutual glow burst when bond formed
    IkatanTeleport  = "IkatanTeleport",   -- Dissolve effect on Ikatan teleport

    -- Kegelapan
    KegelapanFog    = "KegelapanFog",     -- Dense fog particle inside darkness zones
    DimToggle       = "DimToggle",        -- Flicker effect when player dims own light
    NagaAppear      = "NagaAppear",       -- Spawn cloud for Naga Gelap
    NagaCatch       = "NagaCatch",        -- Impact burst when Naga catches player

    -- Spirits
    SpiritFragment  = "SpiritFragment",   -- Ambient particle on uncollected fragment
    SpiritFree      = "SpiritFree",       -- Liberation burst when spirit freed
    DailySpiritGlow = "DailySpiritGlow",  -- Idle glow on daily spirit
    CompanionFloat  = "CompanionFloat",   -- Companion spirit floating particle

    -- Instruments / Harmoni
    HarmoniAura     = "HarmoniAura",      -- Ring aura around players in Harmoni
    NoteFloat       = "NoteFloat",        -- Musical note particle on instrument play

    -- Cosmetics (applied to character)
    AuraDefault     = "AuraDefault",      -- Default standing aura (none equipped)
    TrailWingDefault = "TrailWingDefault",-- Default wing trail particles

    -- Sky's Peak
    SkysPeakAscend  = "SkysPeakAscend",  -- Upward streaks during ascent
    SkysPeakSacrifice = "SkysPeakSacrifice", -- Full-screen burst during sacrifice
    WingBadgeUnlock = "WingBadgeUnlock", -- Badge cosmetic unlock celebration

    -- Season / Events
    SeasonLaunch    = "SeasonLaunch",     -- Confetti-style burst on season start
    EventFirework   = "EventFirework",    -- Firework burst for mid-season event
}

-- ─────────────────────────────────────────────
-- SFX — SOUND EFFECTS
-- Usage: Sound.SoundId = "rbxassetid://" .. Assets.SFX.KEY
-- ─────────────────────────────────────────────
Assets.SFX = {
    -- Cahaya / World
    OrbCollect      = 0,   -- Soft chime on orb pickup
    OrbCollectCap   = 0,   -- Muted chime when daily cap reached
    OrbRespawn      = 0,   -- Subtle pop when orb respawns
    Extinguished    = 0,   -- Low whoosh + silence on extinguish
    Revived         = 0,   -- Warm bell on revive

    -- Flight
    BoostFlap       = 0,   -- Wing flap on each boost (L1–2)
    BoostWhoosh     = 0,   -- Stronger whoosh on boost (L3–5)
    GlideWind       = 0,   -- Looping wind during glide (volume ~ speed)
    CarryGrab       = 0,   -- Grab click when carry weld attaches
    CarryBail       = 0,   -- Release swoosh when carry ends

    -- Kegelapan
    KegelapanEnter  = 0,   -- Ominous tone on zone entry
    KegelapanExit   = 0,   -- Relief swell on zone exit
    DrainTick       = 0,   -- Subtle drain sound each Cahaya lost in zone
    DimToggleOn     = 0,   -- Dampened click when player dims
    DimToggleOff    = 0,   -- Soft swell when player un-dims
    NagaGrowl       = 0,   -- Naga Gelap ambient growl (looping, spatialized)
    NagaChase       = 0,   -- Intensified growl during chase
    NagaCatch       = 0,   -- Impact hit sound on catch

    -- Spirits
    FragmentCollect = 0,   -- Gentle ping on fragment collection
    SpiritFree      = 0,   -- Melodic swell on spirit liberation
    DailySpiritTouch = 0,  -- Soft warmth tone on daily spirit touch

    -- Ikatan
    IkatanOffer     = 0,   -- Soft pulse when offer sent
    IkatanFormed    = 0,   -- Two-tone chime when bond forms
    IkatanTeleport  = 0,   -- Whoosh + arrival chime

    -- Cosmetics
    EquipSuccess    = 0,   -- Light click when cosmetic equipped

    -- Sky's Peak
    SkysPeakWind    = 0,   -- Looping storm wind during ascent
    SkysPeakSummit  = 0,   -- Triumphant tone on reaching summit
    SkysPeakSacrifice = 0, -- Deep resonant pulse during sacrifice animation

    -- UI
    UIOpen          = 0,   -- Panel open whoosh
    UIClose         = 0,   -- Panel close click
    UIConfirm       = 0,   -- Confirm / accept button sound
    UIDecline       = 0,   -- Decline / cancel button sound
    UITabSwitch     = 0,   -- Tab switch tick
    MilestoneUnlock = 0,   -- Milestone reward claimed fanfare
    StreakMilestone = 0,   -- Login streak milestone hit

    -- Notifications
    ToastInfo       = 0,   -- Info toast pop
    ToastSuccess    = 0,   -- Success toast chime
    ToastWarning    = 0,   -- Warning toast thud
}

-- ─────────────────────────────────────────────
-- INSTRUMENTS — NOTE SOUNDS (pentatonic C D E G A)
-- Usage: Sound.SoundId = "rbxassetid://" .. Assets.Instruments.Seruling[noteIndex]
-- noteIndex: 1=C  2=D  3=E  4=G  5=A
-- ─────────────────────────────────────────────
Assets.Instruments = {
    Seruling = { 0, 0, 0, 0, 0 },   -- Flute: C D E G A
    Kendang  = { 0, 0, 0, 0, 0 },   -- Drum: 5 rhythm pads
    Siter    = { 0, 0, 0, 0, 0 },   -- Plucked string: C D E G A
    Terompet = { 0, 0, 0, 0, 0 },   -- Trumpet sustain notes: C D E G A
    Angklung = { 0, 0, 0, 0, 0 },   -- Chime: C D E G A (triggered by shake/key)

    -- Strum / single-shot variants
    SiterStrum    = 0,   -- Siter open strum
    AngklungShake = 0,   -- Angklung single shake sound
    TerompetSustainLoop = 0, -- Looping sustain for Terompet hold
}

-- ─────────────────────────────────────────────
-- BGM — BACKGROUND MUSIC (looping tracks)
-- Usage: Sound.SoundId = "rbxassetid://" .. Assets.BGM.KEY
-- All tracks should seamlessly loop.
-- ─────────────────────────────────────────────
Assets.BGM = {
    -- Ambient states (used by AudioController adaptive score)
    AmbientSolo    = 0,   -- Sparse solo flute — player alone
    AmbientSocial  = 0,   -- Layered harmonic — players nearby
    AmbientKegelapan = 0, -- Atonal drone — inside darkness zone
    AmbientSkysPeak = 0,  -- Full orchestral swell — Sky's Peak ascent

    -- Per-realm ambient base layers (crossfaded by AudioController)
    RealmIsleDawn   = 0,  -- Pulau Fajar: warm, gentle
    RealmGrassland  = 0,  -- Padang Bisikan: airy, open
    RealmForest     = 0,  -- Hutan Gaung: layered, mysterious
    RealmValley     = 0,  -- Lembah Kejayaan: grand, slightly melancholic
    RealmWasteland  = 0,  -- Tanah Tandus: sparse, tense
    RealmVault      = 0,  -- Kubah Pengetahuan: reverberant, ancient

    -- Seasonal themes (played in seasonal realm extension areas)
    SeasonStarfall  = 0,  -- Musim Hujan Bintang theme
    SeasonDawn      = 0,  -- Musim Fajar Abadi theme
    SeasonMist      = 0,  -- Musim Kabut Pelangi theme
    SeasonShadow    = 0,  -- Musim Bayang Langit theme

    -- Event stingers (short, non-looping)
    StingerIkatanForm  = 0,  -- Short fanfare when Ikatan formed
    StingerSpiritFree  = 0,  -- Melodic lift when spirit freed
    StingerCycleComplete = 0, -- Sky's Peak cycle completion fanfare
    StingerStreakMile  = 0,  -- Login streak milestone fanfare
}

-- ─────────────────────────────────────────────
-- ANIMATIONS
-- Usage: Animation.AnimationId = "rbxassetid://" .. Assets.Animations.KEY
-- ─────────────────────────────────────────────
Assets.Animations = {
    -- Flight
    FlightGlide     = 0,  -- Character glide pose
    FlightBoost     = 0,  -- Wing-flap animation on boost
    FlightCarryHold = 0,  -- Carrier hold-arm pose
    FlightCarried   = 0,  -- Carried player dangling pose

    -- Emotes (solo)
    EmoteWave       = 0,
    EmoteBow        = 0,
    EmoteSit        = 0,
    EmoteMeditate   = 0,
    EmotePointSky   = 0,
    EmoteClap       = 0,
    EmoteDance      = 0,
    EmoteNod        = 0,
    EmoteShakeHead  = 0,
    EmotePoint      = 0,  -- Directional point (follows look direction)

    -- Emotes (duo / sync — plays when bonded pair matches emotes)
    EmoteDuoWave    = 0,  -- Synchronized wave
    EmoteDuoBow     = 0,  -- Mutual bow
    EmoteDuoDance   = 0,  -- Partner dance

    -- Instruments
    AnimSeruling    = 0,  -- Hold-flute pose + breath animation
    AnimKendang     = 0,  -- Drum-strike arm animation
    AnimSiter       = 0,  -- Pluck-string hand animation
    AnimTerompet    = 0,  -- Trumpet-raise pose
    AnimAngklung    = 0,  -- Shake/hold chime pose

    -- Spirit interactions
    SpiritReveal    = 0,  -- Player reach-out animation when freeing spirit
    FragmentPickup  = 0,  -- Bend-and-pickup fragment animation

    -- Sky's Peak
    SkysPeakSacrifice = 0, -- Arms-spread sacrifice animation (5 seconds)
    WingBadgeReceive  = 0, -- Look-at-wings cosmetic reveal moment

    -- Companion spirit
    CompanionFloat  = 0,  -- Companion idle hover animation
    CompanionFollow = 0,  -- Companion trailing movement

    -- Ikatan
    IkatanOffer     = 0,  -- Extend-hand offer animation
    IkatanAccept    = 0,  -- Mutual glow embrace animation

    -- Extinguish / Revive
    ExtinguishedIdle = 0, -- Slumped/dim idle when extinguished
    ReviveReceive    = 0, -- Restored-to-light animation
}

-- ─────────────────────────────────────────────
-- FONTS (font asset IDs for CJK and Arabic)
-- Usage: Font.fromId(Assets.Fonts.CJK)
-- Latin locales use Roblox built-in GothamSsm (no ID needed).
-- ─────────────────────────────────────────────
Assets.Fonts = {
    CJK    = 0,   -- SourceHanSans or equivalent (ja, zh-cn, zh-tw, ko)
    Arabic = 0,   -- NotoSansArabic or equivalent (ar)
}

-- ─────────────────────────────────────────────
-- MODEL PATHS (ReplicatedStorage paths)
-- Usage: ReplicatedStorage:FindFirstChild(Assets.Models.KEY, true)
-- Or compose: ReplicatedStorage.Assets.[category][key]:Clone()
-- All paths relative to ReplicatedStorage root.
-- ─────────────────────────────────────────────
Assets.Models = {
    -- NPC
    NagaGelap       = "Assets/NPCs/NagaGelap",

    -- Cahaya
    CahayaOrb       = "Assets/Props/CahayaOrb",       -- Orb part template
    PetiCahaya      = "Assets/Props/PetiCahaya",       -- Darkness chest

    -- Spirits
    SpiritBase      = "Assets/Spirits/SpiritBase",     -- Base spirit model (re-skinned per spirit)
    SpiritFragment  = "Assets/Spirits/Fragment",       -- Generic fragment part

    -- Wing models (one per level, re-skinned by cosmetics)
    Wing = {
        [1]  = "Assets/Wings/WingL1",
        [2]  = "Assets/Wings/WingL2",
        [3]  = "Assets/Wings/WingL3",
        [4]  = "Assets/Wings/WingL4",
        [5]  = "Assets/Wings/WingL5",
        [6]  = "Assets/Wings/WingL6",
        [7]  = "Assets/Wings/WingL7",
        [8]  = "Assets/Wings/WingL8",
        [9]  = "Assets/Wings/WingL9",
        [10] = "Assets/Wings/WingL10",
    },

    -- Cosmetic items (indexed by item ID from CosmeticDefs)
    -- Convention: "Assets/Cosmetics/{Category}/{ItemId}"
    -- e.g. ReplicatedStorage.Assets.Cosmetics.Cape.STARTER_CAPE
    CosmeticsRoot   = "Assets/Cosmetics",

    -- VFX templates (cloned and positioned by controllers)
    VFXRoot         = "Assets/VFX",
}

-- ─────────────────────────────────────────────
-- SPRITE SHEETS (for UI atlas packing)
-- Image IDs for sprite sheets + rect offsets.
-- Usage: ImageLabel.Image = "rbxassetid://" .. Assets.SpriteSheet.Sheet
--        ImageLabel.ImageRectOffset = Assets.SpriteSheet.Rects.KEY.offset
--        ImageLabel.ImageRectSize   = Assets.SpriteSheet.Rects.KEY.size
-- ─────────────────────────────────────────────
Assets.SpriteSheet = {
    Sheet = 0,  -- Main UI sprite sheet texture ID

    Rects = {
        -- Each entry: { offset = Vector2.new(x, y), size = Vector2.new(w, h) }
        -- Populate after sprite sheet is finalized.
        -- Example:
        -- CahayaIcon = { offset = Vector2.new(0, 0),   size = Vector2.new(64, 64) },
        -- HeartIcon  = { offset = Vector2.new(64, 0),  size = Vector2.new(64, 64) },
    },
}

return Assets
