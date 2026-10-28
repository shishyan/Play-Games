--!strict
-- GurukulaDefs.luau
-- Complete curriculum, 7 Ashram Books, Academic & Spiritual Ladder (Pre-School -> Grade 1-12 -> B.A./M.A./Ph.D. -> Dungeon -> Kingdom),
-- and 14-Lokas + Earth Cosmology sourced from GuruKulaDesam.com (guru.shishyan.in).

export type AshramBookDef = {
	id: string,
	number: number,
	tamilName: string,
	translit: string,
	englishName: string,
	virtueFocus: string,
	summary: string,
	color: Color3,
}

export type GradeStageDef = {
	id: string,
	order: number,
	code: string,
	title: string,
	sanskritTitle: string,
	paruvam: string,
	zoneName: string,
	minTotalLevels: number,
	booksUnlocked: { string },
	kuralRefs: { string },
	summary: string,
	status: "playable" | "avenue_gate",
}

export type LokaRealmDef = {
	id: string,
	order: number, -- +7..+1 upper, 0 earth, -1..-7 lower
	division: "Upper" | "Earth" | "Lower",
	sanskritName: string,
	englishName: string,
	inhabitants: string,
	summary: string,
	ringColor: Color3,
}

export type Grade1LessonDef = {
	id: string,
	title: string,
	subtitle: string,
	kuralChapter: string,
	coupletTamil: string,
	coupletMeaning: string,
	virtuePractice: string,
}

local GurukulaDefs = {}

GurukulaDefs.Motto = {
	tamil = "இல்லற தர்மமே நிர்வாணம்",
	english = "Living Dharma is Nirvana",
	pillars = {
		{ id = "duty", name = "Duty (கடமை / Kadamai)", desc = "Fulfill your daily Pancha Maha Yajnas to Rishis, Ancestors, Devas, Fellow Beings, and Nature." },
		{ id = "discipline", name = "Discipline (கட்டுப்பாடு / Kattuppaadu)", desc = "Master mind, speech, and body through rhythmic Sadhana and truthful action." },
		{ id = "dignity", name = "Dignity (கண்ணியம் / Kanniyam)", desc = "Honor the divine spark (Atman) within every living creature through strict Ahimsa (Non-Killing)." },
	},
}

-- The 7 Sacred Books of the Gurukula Ashram (GuruKulaDesam.com)
GurukulaDefs.AshramBooks = {
	{
		id = "narcheyal",
		number = 1,
		tamilName = "நற்செயல்",
		translit = "Narcheyal",
		englishName = "Good Deeds & Daily Sadhana",
		virtueFocus = "Righteous Action (Karma Yoga & Pancha Maha Yajna)",
		summary = "Daily dawn routines, lighting the 18 Agal Vilakku lamps, tending the Tulasi grove, and selfless Seva.",
		color = Color3.fromRGB(235, 195, 95),
	},
	{
		id = "narpanbu",
		number = 2,
		tamilName = "நற்பண்பு",
		translit = "Narpanbu",
		englishName = "Noble Character & Virtues",
		virtueFocus = "Humility, Gratitude, & Self-Control (Adakkam)",
		summary = "Cultivating noble conduct, hospitality (Virunthombal), and gentleness toward all beings.",
		color = Color3.fromRGB(130, 215, 145),
	},
	{
		id = "nanneri",
		number = 3,
		tamilName = "நன்னெறி",
		translit = "Nanneri",
		englishName = "Righteous Path & Moral Code",
		virtueFocus = "Ahimsa (Kollaamai) & Truthfulness (Vaimai)",
		summary = "Thirukkural moral law: never taking a life, speaking truth that heals, and walking the path of Aram.",
		color = Color3.fromRGB(115, 195, 245),
	},
	{
		id = "nallaram",
		number = 4,
		tamilName = "நல்லறம்",
		translit = "Nallaram",
		englishName = "Sacred Household & Social Dharma",
		virtueFocus = "Illara Dharmam & Jivakarunyam (Compassion)",
		summary = "Living Dharma in the world—supporting family, community, cattle, and ecological balance.",
		color = Color3.fromRGB(240, 165, 110),
	},
	{
		id = "narthunai",
		number = 5,
		tamilName = "நற்துணை",
		translit = "Narthunai",
		englishName = "Noble Fellowship (Satsanga)",
		virtueFocus = "Periyaraith Thunai Koduthal (Walking with the Wise)",
		summary = "Stories of the 63 Nayanmars, Acharyas, and choosing noble companions on the spiritual journey.",
		color = Color3.fromRGB(195, 150, 240),
	},
	{
		id = "narchol",
		number = 6,
		tamilName = "நற்சொல்",
		translit = "Narchol",
		englishName = "Sacred Speech & Mantra",
		virtueFocus = "Iniyavai Kooral (Sweet Speech) & Thirumurai Chanting",
		summary = "Mastering Devaram, Thiruvasagam, Thiruppugazh, and Sanskrit/Tamil mantra vibration.",
		color = Color3.fromRGB(245, 215, 130),
	},
	{
		id = "narchinthanai",
		number = 7,
		tamilName = "நற்சிந்தனை",
		translit = "Narchinthanai",
		englishName = "Pure Inquiry & Vedanta-Siddhanta",
		virtueFocus = "Atma Vichara & Pati-Pasu-Pasam Wisdom",
		summary = "Deep contemplation on Upanishads, Sivagnana Bodham, and awakening troubled spirits through wisdom.",
		color = Color3.fromRGB(160, 235, 225),
	},
} :: { AshramBookDef }

-- Complete Academic & Spiritual Ladder on Earth (Bhumi)
GurukulaDefs.AcademicLadder = {
	{
		id = "preschool",
		order = 0,
		code = "Pre-School",
		title = "Mazhalai Balavihar",
		sanskritTitle = "Aksharabhyasam Shishu",
		paruvam = "Mazhalai Paruvam (Early Childhood)",
		zoneName = "Balavihar Lotus Sanctuary",
		minTotalLevels = 0,
		booksUnlocked = { "narcheyal" },
		kuralRefs = { "Ch. 1 Kadavul Vazhthu (Praise of the Divine)" },
		summary = "Trace sacred letters in golden sand (Aksharabhyasam), bow to the Guru, and learn joyful kindness to all creatures.",
		status = "playable",
	},
	{
		id = "grade_1",
		order = 1,
		code = "Grade 1",
		title = "Prathama Kaksha (Tharam 1)",
		sanskritTitle = "Prathama Vidyarthi",
		paruvam = "Bala Paruvam (Foundation)",
		zoneName = "Prathama Kaksha Pathshala & Rain Vedi",
		minTotalLevels = 6,
		booksUnlocked = { "narcheyal", "nanneri" },
		kuralRefs = {
			"Ch. 1 Kadavul Vazhthu",
			"Ch. 2 Vaan Sirappu (Blessing of Rain)",
			"Ch. 4 Aran Valiyuruthal (Power of Virtue)",
			"Ch. 8 Anbudaimai (Living with Love)",
			"Ch. 33 Kollaamai (Strict Non-Killing / Ahimsa)",
		},
		summary = "Master the 3 Ds (Duty, Discipline, Dignity), read the Olai Chuvadi palm-leaf manuscripts, tend the Rain Yajna, and pacify agitated spirits without ever killing.",
		status = "playable",
	},
	{
		id = "grade_2",
		order = 2,
		code = "Grade 2",
		title = "Dvitiya Kaksha (Tharam 2)",
		sanskritTitle = "Vinaya Vidyarthi",
		paruvam = "Bala Paruvam",
		zoneName = "Iniyavai Kooral Grove (Sweet Speech Terrace)",
		minTotalLevels = 8,
		booksUnlocked = { "narcheyal", "narpanbu", "nanneri" },
		kuralRefs = { "Ch. 10 Iniyavai Kooral", "Ch. 11 Seynnandri Arithal (Gratitude)" },
		summary = "Cultivate sweet, healing speech and gratitude toward parents, teachers, cows, and rivers.",
		status = "avenue_gate",
	},
	{
		id = "grade_3",
		order = 3,
		code = "Grade 3",
		title = "Tritiya Kaksha (Tharam 3)",
		sanskritTitle = "Samyama Vidyarthi",
		paruvam = "Bala Paruvam",
		zoneName = "Adakkam Mandapa (Self-Control Cloister)",
		minTotalLevels = 10,
		booksUnlocked = { "narcheyal", "narpanbu", "nanneri" },
		kuralRefs = { "Ch. 13 Adakkam Udaimai", "Ch. 14 Ozhukkam Udaimai" },
		summary = "Guard mind, tongue, and senses like a tortoise drawing in its limbs; practice steady daily discipline.",
		status = "avenue_gate",
	},
	{
		id = "grade_4",
		order = 4,
		code = "Grade 4",
		title = "Chaturtha Kaksha (Tharam 4)",
		sanskritTitle = "Kshama Vidyarthi",
		paruvam = "Bala Paruvam",
		zoneName = "Poraiyudaimai Garden (Forgiveness Sanctuary)",
		minTotalLevels = 12,
		booksUnlocked = { "narcheyal", "narpanbu", "nanneri", "nallaram" },
		kuralRefs = { "Ch. 16 Poraiyudaimai (Patience)", "Ch. 25 Aruludaimai (Compassion)" },
		summary = "Bear insults as Earth bears those who dig her; awaken compassion (Arul) as the child of Love (Anbu).",
		status = "avenue_gate",
	},
	{
		id = "grade_5",
		order = 5,
		code = "Grade 5",
		title = "Panchama Kaksha (Tharam 5)",
		sanskritTitle = "Jivakarunya Sadhaka",
		paruvam = "Ilam Paruvam (Middle Gurukula)",
		zoneName = "Vallalar Annadhana Sala (Sanctuary of Sacred Sharing)",
		minTotalLevels = 14,
		booksUnlocked = { "narcheyal", "narpanbu", "nanneri", "nallaram", "narthunai" },
		kuralRefs = { "Ch. 23 ஈகை (Eegai / Generosity)", "Ch. 26 புலால் மறுத்தல் (Refusing Flesh)" },
		summary = "Enter Ilam Paruvam: practice Vallalar's Jivakarunyam, feed the hungry, and uphold pure Sattvic nourishment.",
		status = "avenue_gate",
	},
	{
		id = "grade_6",
		order = 6,
		code = "Grade 6",
		title = "Shashtha Kaksha (Tharam 6)",
		sanskritTitle = "Satya Vrata Sadhaka",
		paruvam = "Ilam Paruvam",
		zoneName = "Vaimai Stambha (Hall of Unbroken Truth)",
		minTotalLevels = 16,
		booksUnlocked = { "narcheyal", "narpanbu", "nanneri", "nallaram", "narthunai" },
		kuralRefs = { "Ch. 30 Vaimai (Truthfulness)", "Ch. 31 Vegulaamai (Restraining Anger)" },
		summary = "Speak only words free from the slightest harm; extinguish wrath toward both friend and stranger.",
		status = "avenue_gate",
	},
	{
		id = "grade_7",
		order = 7,
		code = "Grade 7",
		title = "Saptama Kaksha (Tharam 7)",
		sanskritTitle = "Nayanmar Bhakta",
		paruvam = "Ilam Paruvam",
		zoneName = "Periya Puranam Cloister (63 Nayanmars Courtyard)",
		minTotalLevels = 18,
		booksUnlocked = { "narcheyal", "narpanbu", "nanneri", "nallaram", "narthunai" },
		kuralRefs = { "Ch. 40 Kalvi (Sacred Learning)", "Ch. 42 Kelvi (Listening to the Wise)" },
		summary = "Walk with the 63 Nayanmar saints; unite devotion (Bhakti) with tireless service to temple and village.",
		status = "avenue_gate",
	},
	{
		id = "grade_8",
		order = 8,
		code = "Grade 8",
		title = "Ashtama Kaksha (Tharam 8)",
		sanskritTitle = "Chatur-Veda Sadhaka",
		paruvam = "Ilam Paruvam",
		zoneName = "Purushartha Mandapa (Four Aims Pavilion)",
		minTotalLevels = 20,
		booksUnlocked = { "narcheyal", "narpanbu", "nanneri", "nallaram", "narthunai" },
		kuralRefs = { "Ch. 43 Arivudaimai (True Wisdom)", "Ch. 45 Periyaraith Thunai Koduthal" },
		summary = "Harmonize Dharma (Aram), Artha (Porul), Kama (Inbam), and Moksha (Veedu) in balanced daily life.",
		status = "avenue_gate",
	},
	{
		id = "grade_9",
		order = 9,
		code = "Grade 9",
		title = "Navama Kaksha (Tharam 9)",
		sanskritTitle = "Agama Adhyeta",
		paruvam = "Uyarnilai Paruvam (High School)",
		zoneName = "28 Saiva Agamas Gopuram",
		minTotalLevels = 23,
		booksUnlocked = { "narcheyal", "narpanbu", "nanneri", "nallaram", "narthunai", "narchol" },
		kuralRefs = { "Ch. 60 Ukkam Udaimai (Unwavering Energy)", "Ch. 62 Aalvinai Udaimai" },
		summary = "Unlock the 6th Ashram Book (Narchol); study Charya, Kriya, Yoga, and Jnana across the 28 Saiva Agamas.",
		status = "avenue_gate",
	},
	{
		id = "grade_10",
		order = 10,
		code = "Grade 10",
		title = "Dashama Kaksha (Tharam 10)",
		sanskritTitle = "Shad-Darshana Scholar",
		paruvam = "Uyarnilai Paruvam",
		zoneName = "Pati-Pasu-Pasam Sabha",
		minTotalLevels = 26,
		booksUnlocked = { "narcheyal", "narpanbu", "nanneri", "nallaram", "narthunai", "narchol" },
		kuralRefs = { "Ch. 36 Meyyunardhal (Realizing Ultimate Truth)" },
		summary = "Compare the 6 Classical Darshanas and realize the bond of Pati (Divine), Pasu (Soul), and Pasam (Bondage).",
		status = "avenue_gate",
	},
	{
		id = "grade_11",
		order = 11,
		code = "Grade 11",
		title = "Ekadasha Kaksha (Tharam 11)",
		sanskritTitle = "Upanishad Mimamsaka",
		paruvam = "Melnilai Paruvam (Higher Secondary)",
		zoneName = "Katha Upanishad & Gita Pavilion",
		minTotalLevels = 29,
		booksUnlocked = { "narcheyal", "narpanbu", "nanneri", "nallaram", "narthunai", "narchol", "narchinthanai" },
		kuralRefs = { "Ch. 35 Thuravu (Inner Detachment amidst Duty)" },
		summary = "Unlock the 7th Ashram Book (Narchinthanai); choose Shreyas (the Good) over Preyas (fleeting pleasure).",
		status = "avenue_gate",
	},
	{
		id = "grade_12",
		order = 12,
		code = "Grade 12",
		title = "Dwadasha Kaksha (Tharam 12)",
		sanskritTitle = "Sivagnana Bodham Graduate",
		paruvam = "Melnilai Paruvam",
		zoneName = "Jivanmukti Convocation Mandapa",
		minTotalLevels = 32,
		booksUnlocked = { "narcheyal", "narpanbu", "nanneri", "nallaram", "narthunai", "narchol", "narchinthanai" },
		kuralRefs = { "Ch. 98 Perumai (Spiritual Greatness)", "Ch. 99 Saandraanmai (Sublime Nobility)" },
		summary = "Complete School Gurukula with the 12 Sutras of Meykandar's Sivagnana Bodham and embody Saandraanmai.",
		status = "avenue_gate",
	},
	{
		id = "ba_snataka",
		order = 13,
		code = "B.A.",
		title = "Snataka / Shastri (B.A. in Dharmic Sciences)",
		sanskritTitle = "Dharma-Shastri Snataka",
		paruvam = "Vedanta Vidyapeeth (Collegiate)",
		zoneName = "Vedanta Vidyapeeth — Snataka Mahavidyalaya",
		minTotalLevels = 36,
		booksUnlocked = { "narcheyal", "narpanbu", "nanneri", "nallaram", "narthunai", "narchol", "narchinthanai" },
		kuralRefs = { "Arathuppaal & Porutpaal Synthesis" },
		summary = "Bachelor of Dharmic Life: integrate Vedic hymns, Tamil Thirumurai, ecological stewardship, and sacred arts.",
		status = "avenue_gate",
	},
	{
		id = "ma_acharya",
		order = 14,
		code = "M.A.",
		title = "Acharya (M.A. in Siddhanta & Yoga)",
		sanskritTitle = "Dharma-Acharya",
		paruvam = "Vedanta Vidyapeeth (Post-Graduate)",
		zoneName = "Vedanta Vidyapeeth — Acharya Peetham",
		minTotalLevels = 40,
		booksUnlocked = { "narcheyal", "narpanbu", "nanneri", "nallaram", "narthunai", "narchol", "narchinthanai" },
		kuralRefs = { "Complete 1330 Thirukkural Mastery" },
		summary = "Master of Dharmic Life: guide younger students, lead Yajnas, and harmonize warring subtle forces through Ahimsa.",
		status = "avenue_gate",
	},
	{
		id = "phd_vidyavaridhi",
		order = 15,
		code = "Ph.D.",
		title = "Vidyavaridhi (Ph.D. Doctorate of Wisdom)",
		sanskritTitle = "Brahma-Vidyavaridhi",
		paruvam = "Vedanta Vidyapeeth (Doctoral Research)",
		zoneName = "Vedanta Vidyapeeth — Rishi Samshodhana Vihara",
		minTotalLevels = 45,
		booksUnlocked = { "narcheyal", "narpanbu", "nanneri", "nallaram", "narthunai", "narchol", "narchinthanai" },
		kuralRefs = { "Prasthana Trayi & Panniru Thirumurai Synthesis" },
		summary = "Doctorate of Dharmic Life: original realization bridging ancient Rishi wisdom with cosmic harmony across realms.",
		status = "avenue_gate",
	},
	{
		id = "dungeon_antaryuddha",
		order = 16,
		code = "Dungeon",
		title = "Antar-Yuddha (Sanctum of the Six Inner Shadows)",
		sanskritTitle = "Arishadvarga-Jit",
		paruvam = "Inner Trial (Adhyatmika Kurukshetra)",
		zoneName = "Antar-Yuddha Sanctum (Subterranean Lotus Cavern)",
		minTotalLevels = 50,
		booksUnlocked = { "narcheyal", "narpanbu", "nanneri", "nallaram", "narthunai", "narchol", "narchinthanai" },
		kuralRefs = { "Ch. 37 Avavandaruthal (Conquering Craving)" },
		summary = "Face and pacify the 6 inner passions (Kama, Krodha, Lobha, Moha, Mada, Matsarya) in pure Ahimsa meditation.",
		status = "avenue_gate",
	},
	{
		id = "kingdom_dharmarajya",
		order = 17,
		code = "Kingdom",
		title = "Dharma Rajya (Rajarishi Sovereign of Aram)",
		sanskritTitle = "Chakravarti Rajarishi",
		paruvam = "Sovereign Stewardship (Sengonmai)",
		zoneName = "Dharma Rajya Simhasana (Golden Citadel of Bhumi)",
		minTotalLevels = 55,
		booksUnlocked = { "narcheyal", "narpanbu", "nanneri", "nallaram", "narthunai", "narchol", "narchinthanai" },
		kuralRefs = { "Ch. 39 Iraimaatchi (Royal Excellence)", "Ch. 55 Sengonmai (Righteous Scepter)" },
		summary = "Sovereign Steward of Earth: uphold universal welfare where no creature fears harm and Earth's Dharma shields all 14 realms.",
		status = "avenue_gate",
	},
} :: { GradeStageDef }

-- The 14 Non-Human Realms (7 Upper Lokas + 7 Lower Talas) + Earth (Bhumi)
GurukulaDefs.FourteenLokas = {
	-- 7 Upper Lokas (Vyahritis)
	{
		id = "satya_loka",
		order = 7,
		division = "Upper",
		sanskritName = "Satya-Loka (Brahmaloka)",
		englishName = "7th Upper Realm of Pure Truth",
		inhabitants = "Prajapatis, Sanatkumaras, & Liberated Siddhas",
		summary = "Highest of the 7 upper non-human realms; radiant lotus plane of unconditioned Satya beyond rebirth.",
		ringColor = Color3.fromRGB(255, 250, 215),
	},
	{
		id = "tapar_loka",
		order = 6,
		division = "Upper",
		sanskritName = "Tapar-Loka (Tapoloka)",
		englishName = "6th Upper Realm of Luminous Tapas",
		inhabitants = "Vairaja Rishis & Ascetic Devas",
		summary = "Plane of inextinguishable spiritual austerity whose golden vibrations nourish cosmic order.",
		ringColor = Color3.fromRGB(255, 230, 155),
	},
	{
		id = "janar_loka",
		order = 5,
		division = "Upper",
		sanskritName = "Janar-Loka (Janaloka)",
		englishName = "5th Upper Realm of Divine Wisdom-Born",
		inhabitants = "Mind-Born Putra-Rishis & Pure Vidyadharas",
		summary = "Celestial sanctuary of pure creative intelligence and unclouded Vedic resonance.",
		ringColor = Color3.fromRGB(215, 240, 255),
	},
	{
		id = "mahar_loka",
		order = 4,
		division = "Upper",
		sanskritName = "Mahar-Loka",
		englishName = "4th Upper Realm of Great Seers",
		inhabitants = "Saptarishis, Bhrigu, & Cosmic Guardians",
		summary = "Bridge between mortal cycles and eternal planes where the Seven Great Seers watch over Dharma.",
		ringColor = Color3.fromRGB(165, 225, 255),
	},
	{
		id = "svar_loka",
		order = 3,
		division = "Upper",
		sanskritName = "Svar-Loka (Svargaloka)",
		englishName = "3rd Upper Realm of Celestial Light",
		inhabitants = "Adityas, Vasus, Rudras, Ashvins, & Gandharvas",
		summary = "Shining firmament of the Devas powered by sacred Yajnas and righteous deeds performed on Earth.",
		ringColor = Color3.fromRGB(250, 210, 120),
	},
	{
		id = "bhuvar_loka",
		order = 2,
		division = "Upper",
		sanskritName = "Bhuvar-Loka (Antariksha)",
		englishName = "2nd Upper Realm of Vital Atmosphere",
		inhabitants = "Siddhas, Charanas, Maruts, & Pitris",
		summary = "Subtle atmospheric plane of Prana winds, rain-bearing clouds, and ancestral blessings.",
		ringColor = Color3.fromRGB(150, 235, 200),
	},
	{
		id = "bhur_upari",
		order = 1,
		division = "Upper",
		sanskritName = "Bhur-Upari (Etheric Crown of Bhumi)",
		englishName = "1st Upper Canopy of Sacred Mountains",
		inhabitants = "Yakshas, Kinnaras, & Mountain Devas",
		summary = "The etheric Himalayan canopy just above human sight where celestial musicians chant at dawn.",
		ringColor = Color3.fromRGB(175, 240, 160),
	},
	-- Center: Earth (Human Realm)
	{
		id = "bhumi_earth",
		order = 0,
		division = "Earth",
		sanskritName = "Bhumi (Prithvi — Karma-Bhumi)",
		englishName = "Earth — The Human Gurukula of Dharmic Life",
		inhabitants = "Human Star-Seed Students, Acharyas, Cows, & Sacred Flora",
		summary = "The only realm where souls enroll in the Virtual School of Dharmic Life (Pre-School to Kingdom) and consciously choose Dharma.",
		ringColor = Color3.fromRGB(115, 210, 130),
	},
	-- 7 Lower Realms (Bila-Svarga / Patalas)
	{
		id = "atala",
		order = -1,
		division = "Lower",
		sanskritName = "Atala",
		englishName = "1st Lower Realm of White Crystal",
		inhabitants = "Bala-Danavas & Subterranean Mystics",
		summary = "First of the 7 non-human subterranean realms; a glittering realm of illusion that tests detachment.",
		ringColor = Color3.fromRGB(215, 195, 235),
	},
	{
		id = "vitala",
		order = -2,
		division = "Lower",
		sanskritName = "Vitala",
		englishName = "2nd Lower Realm of Hataka Gold",
		inhabitants = "Hatakeshvara Bhuta-Ganas & Gold-Swarm Spirits",
		summary = "Cavernous realm watered by the Hataki river where raw elemental power is tempered by Shiva's stillness.",
		ringColor = Color3.fromRGB(225, 180, 115),
	},
	{
		id = "sutala",
		order = -3,
		division = "Lower",
		sanskritName = "Sutala",
		englishName = "3rd Lower Realm of Righteous Bali",
		inhabitants = "Emperor Mahabali & Devoted Daityas",
		summary = "Subterranean kingdom of Mahabali, proving that even in the lower realms, surrender to Dharma brings grace.",
		ringColor = Color3.fromRGB(145, 200, 185),
	},
	{
		id = "talatala",
		order = -4,
		division = "Lower",
		sanskritName = "Talatala",
		englishName = "4th Lower Realm of Maya's Architecture",
		inhabitants = "Mayasura & Master Geomantic Builders",
		summary = "Jewel-lit cities of the architect Mayasura; when pride surges here, rifts occasionally touch Earth.",
		ringColor = Color3.fromRGB(150, 165, 235),
	},
	{
		id = "mahatala",
		order = -5,
		division = "Lower",
		sanskritName = "Mahatala",
		englishName = "5th Lower Realm of Many-Hooded Serpents",
		inhabitants = "Krodhavasha Nagas (Kuhaka, Takshaka, Sushena)",
		summary = "Vast subterranean lakes of ancient serpent clans whose restless energy is calmed by Shanti Mantras.",
		ringColor = Color3.fromRGB(125, 195, 155),
	},
	{
		id = "rasatala",
		order = -6,
		division = "Lower",
		sanskritName = "Rasatala",
		englishName = "6th Lower Realm of Primordial Caverns",
		inhabitants = "Panis, Nivatakavachas, & Kalakeyas",
		summary = "Deep tectonic vaults where fierce non-human clans dwell; future realm-collision wars originate here when Dharma wanes.",
		ringColor = Color3.fromRGB(215, 125, 115),
	},
	{
		id = "patala",
		order = -7,
		division = "Lower",
		sanskritName = "Patala (Naga-Loka)",
		englishName = "7th Lower Realm of Radiant Gems",
		inhabitants = "Vasuki & Jewel-Crowned Naga Sovereigns",
		summary = "Deepest of the 7 lower realms, illuminated by the crest-jewels of Vasuki and resting above Ananta Shesha.",
		ringColor = Color3.fromRGB(185, 130, 240),
	},
} :: { LokaRealmDef }

-- Grade 1 (Prathama Kaksha / Tharam 1) Interactive Curriculum Lessons
GurukulaDefs.Grade1Lessons = {
	{
		id = "g1_kural_1",
		title = "Lesson 1: Kadavul Vazhthu (Praise of the Divine)",
		subtitle = "Thirukkural Chapter 1 — Kural 1",
		kuralChapter = "Adhikaram 1: Kadavul Vazhthu",
		coupletTamil = "அகர முதல எழுத்தெல்லாம் ஆதி பகவன் முதற்றே உலகு.",
		coupletMeaning = "As the letter 'A' (अ / அ) is the first of all letters, so the Eternal Divine is the first and foundation of the universe.",
		virtuePractice = "Begin every study and deed with gratitude to the Source; see the same light in every student and creature.",
	},
	{
		id = "g1_kural_2",
		title = "Lesson 2: Vaan Sirappu (The Blessing of Rain)",
		subtitle = "Thirukkural Chapter 2 — Kural 11",
		kuralChapter = "Adhikaram 2: Vaan Sirappu",
		coupletTamil = "வான்நின்று உலகம் வழங்கி வருதலால் தான்அமிழ்தம் என்றுணரற் பாற்று.",
		coupletMeaning = "Because rain sustains the world without fail, rain itself should be revered as Nectar (Amrita).",
		virtuePractice = "Keep rivers pure, draw water with reverence, and offer sacred herbs at the Rain Yajna Vedi.",
	},
	{
		id = "g1_kural_4",
		title = "Lesson 3: Aran Valiyuruthal (The Power of Virtue)",
		subtitle = "Thirukkural Chapter 4 — Kural 34",
		kuralChapter = "Adhikaram 4: Aran Valiyuruthal",
		coupletTamil = "மனத்துக்கண் மாசிலன் ஆதல் அனைத்தறன் ஆகுல நீர பிற.",
		coupletMeaning = "To be spotless and pure in mind is the whole of Dharma (Aram); all else is mere outward show.",
		virtuePractice = "Practice the 3 Ds of GuruKulaDesam: Duty (Kadamai), Discipline (Kattuppaadu), and Dignity (Kanniyam).",
	},
	{
		id = "g1_kural_8",
		title = "Lesson 4: Anbudaimai (Living with Love)",
		subtitle = "Thirukkural Chapter 8 — Kural 80",
		kuralChapter = "Adhikaram 8: Anbudaimai",
		coupletTamil = "அன்பின் வழியது உயிர்நிலை அஃதிலார்க்கு என்புதோல் போர்த்த உடம்பு.",
		coupletMeaning = "That body alone truly lives which moves on the path of Love; without love, it is merely bones covered with skin.",
		virtuePractice = "Share Sattvic food (Annadhana), greet elders and peers with warmth, and protect the sanctuary's cows and deer.",
	},
	{
		id = "g1_kural_33",
		title = "Lesson 5: Kollaamai (Strict Non-Killing / Ahimsa)",
		subtitle = "Thirukkural Chapter 33 — Kural 321 & 322",
		kuralChapter = "Adhikaram 33: Kollaamai",
		coupletTamil = "அறவினை யாதெனில் கொல்லாமை கோறல் பிறவினை எல்லாம் தரும்.",
		coupletMeaning = "What is the highest work of Virtue? Never killing any living being; for killing brings every other evil in its wake.",
		virtuePractice = "In this Gurukula, we NEVER kill. Even when restless spirits appear, calm their agitation with Prana implements or [V] Shanti Mantra so they awaken in golden peace (Prabodha).",
	},
} :: { Grade1LessonDef }

function GurukulaDefs.totalSkillLevels(paths: { [string]: any }?): number
	if not paths then
		return 6
	end
	local sum = 0
	local isPurushartha = type(paths.dharma) == "number" or type(paths.artha) == "number" or type(paths.kama) == "number"
	if isPurushartha then
		local pScore = (tonumber(paths.dharma) or 0) + (tonumber(paths.artha) or 0) + (tonumber(paths.kama) or 0) + (tonumber(paths.moksha) or 0)
		-- Map Purushartha score (0..400) smoothly onto the academic ladder (6..60+)
		return 6 + math.floor(pScore * 0.25)
	end
	for _, p in pairs(paths) do
		if type(p) == "table" and type(p.level) == "number" then
			sum += p.level
		elseif type(p) == "number" then
			sum += p
		else
			sum += 1
		end
	end
	return math.max(6, sum)
end

function GurukulaDefs.gradeFor(
	paths: { [string]: any }?,
	legacy: any?
): (GradeStageDef, GradeStageDef?, number)
	local total = GurukulaDefs.totalSkillLevels(paths)
	local rebirthCount = 0
	if type(legacy) == "number" then
		rebirthCount = legacy
	elseif type(legacy) == "table" and type(legacy.rebirths) == "number" then
		rebirthCount = legacy.rebirths
	end
	local effective = total + rebirthCount * 3

	-- Fresh star-seeds at exact starting level (6 total, 0 XP) begin at Grade 1 (with Pre-School & Grade 1 both open)
	local current = GurukulaDefs.AcademicLadder[2] -- Default: Grade 1 (Prathama Kaksha)
	local nextStage: GradeStageDef? = GurukulaDefs.AcademicLadder[3]

	for i, stage in ipairs(GurukulaDefs.AcademicLadder) do
		if effective >= stage.minTotalLevels then
			current = stage
			nextStage = GurukulaDefs.AcademicLadder[i + 1]
		else
			break
		end
	end

	return current, nextStage, effective
end

function GurukulaDefs.findStage(stageId: string): GradeStageDef?
	for _, s in ipairs(GurukulaDefs.AcademicLadder) do
		if s.id == stageId then
			return s
		end
	end
	return nil
end

function GurukulaDefs.findLoka(lokaId: string): LokaRealmDef?
	for _, l in ipairs(GurukulaDefs.FourteenLokas) do
		if l.id == lokaId then
			return l
		end
	end
	return nil
end

return GurukulaDefs
