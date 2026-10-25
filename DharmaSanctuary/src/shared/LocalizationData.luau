--!strict
--[[
    LocalizationData.luau
    ─────────────────────
    Single source of truth for all game localization entries (T-107, T-112).

    Key convention (FR-LOC-01): CATEGORY_SUBCATEGORY_KEY
    Languages: en (primary, authored), id (Indonesian, authored),
               ja / ar / zh-cn (auto-translated stubs — flagged [REVIEW]).

    Usage
    ──────
    LocalizationData.getEntries() → { LocalizationEntry }
    Pass result to LocalizationTable:SetEntries() on server init.
]]

local LocalizationData = {}

-- ─── Entry type ───────────────────────────────────────────────────────────────

type Values = { [string]: string }
type Entry  = { Key: string, Source: string, Values: Values }

-- ─── Helpers ──────────────────────────────────────────────────────────────────

local function entry(key: string, en: string, id: string, ja: string, ar: string, zhCn: string): Entry
	return {
		Key    = key,
		Source = en,
		Values = {
			["en"]    = en,
			["id"]    = id,
			["ja"]    = ja,      -- [REVIEW] auto-translated
			["ar"]    = ar,      -- [REVIEW] auto-translated
			["zh-cn"] = zhCn,    -- [REVIEW] auto-translated
		},
	}
end

-- ─── Expression Bubble Phrases (T-112) — GDD §16.9 ───────────────────────────
-- 20 preset phrases; all 5 Tier-1 languages authored / reviewed.

local EXPRESSION_ENTRIES: { Entry } = {
	-- Social greetings
	entry("EXPR_HELLO",        "Hello!",         "Halo!",            "こんにちは！",     "مرحباً!",        "你好！"),
	entry("EXPR_FOLLOW_ME",    "Follow me!",     "Ikuti aku!",       "ついてきて！",     "تعال معي!",      "跟我来！"),
	entry("EXPR_THANK_YOU",    "Thank you!",     "Terima kasih!",    "ありがとう！",     "شكراً!",         "谢谢！"),
	entry("EXPR_HELP_ME",      "Help me!",       "Tolong aku!",      "助けて！",         "ساعدني!",        "帮帮我！"),
	entry("EXPR_WAIT_HERE",    "Wait here!",     "Tunggu di sini!",  "ここで待って！",   "انتظر هنا!",     "在这等！"),
	entry("EXPR_GOOD_JOB",     "Good job!",      "Bagus!",           "よくやった！",     "أحسنت!",         "干得好！"),
	entry("EXPR_LETS_FLY",     "Let's fly!",     "Ayo terbang!",     "飛ぼう！",         "لنطر!",          "一起飞！"),
	entry("EXPR_SO_PRETTY",    "So pretty!",     "Cantik sekali!",   "きれい！",         "جميل!",          "好美！"),
	-- Directions
	entry("EXPR_GO_LEFT",      "Go left!",       "Ke kiri!",         "左へ！",           "يساراً!",        "向左！"),
	entry("EXPR_GO_RIGHT",     "Go right!",      "Ke kanan!",        "右へ！",           "يميناً!",        "向右！"),
	entry("EXPR_GO_UP",        "Go up!",         "Ke atas!",         "上へ！",           "إلى الأعلى!",    "向上！"),
	entry("EXPR_GO_DOWN",      "Go down!",       "Ke bawah!",        "إلى الأسفل!",     "下へ！",         "向下！"),
	-- Social (carry / cooperation)
	entry("EXPR_COME_HERE",    "Come here!",     "Sini!",            "ここへ来て！",     "تعال هنا!",      "过来！"),
	entry("EXPR_LOOK_HERE",    "Look here!",     "Lihat sini!",      "見て！",           "انظر هنا!",      "看这里！"),
	entry("EXPR_ILL_CARRY_YOU","I'll carry you!","Aku yang bawa!",   "連れて行くよ！",   "سأحملك!",        "我带你！"),
	entry("EXPR_CARRY_ME",     "Carry me!",      "Bawa aku!",        "連れて行って！",   "احملني!",        "带我去！"),
	-- Reactions
	entry("EXPR_WOW",          "Wow!",           "Wah!",             "わあ！",           "واو!",           "哇！"),
	entry("EXPR_AMAZING",      "Amazing!",       "Luar biasa!",      "すごい！",         "مذهل!",          "太棒了！"),
	entry("EXPR_OOPS",         "Oops!",          "Aduh!",            "あっ！",           "أوه!",           "哎呀！"),
	entry("EXPR_SORRY",        "Sorry!",         "Maaf!",            "ごめん！",         "آسف!",           "对不起！"),
}

-- ─── HUD strings ──────────────────────────────────────────────────────────────

local HUD_ENTRIES: { Entry } = {
	entry("HUD_COMPASS_N",     "N",  "U",  "北",  "ش",  "北"),
	entry("HUD_COMPASS_NE",    "NE", "TL", "北東","شش", "东北"),
	entry("HUD_COMPASS_E",     "E",  "T",  "東",  "ش",  "东"),
	entry("HUD_COMPASS_SE",    "SE", "TG", "南東","جش", "东南"),
	entry("HUD_COMPASS_S",     "S",  "S",  "南",  "ج",  "南"),
	entry("HUD_COMPASS_SW",    "SW", "BD", "南西","جغ", "西南"),
	entry("HUD_COMPASS_W",     "W",  "B",  "西",  "غ",  "西"),
	entry("HUD_COMPASS_NW",    "NW", "BL", "北西","شغ", "西北"),
	entry("HUD_ALTITUDE_FMT",  "↑ {y} m", "↑ {y} m", "↑ {y} m", "↑ {y} م", "↑ {y} 米"),
}

-- ─── Panel title strings ───────────────────────────────────────────────────────

local PANEL_ENTRIES: { Entry } = {
	entry("PANEL_DAILY_TITLE",    "DAILY TASKS",  "TUGAS HARIAN",   "デイリーミッション", "المهام اليومية",    "每日任务"),
	entry("PANEL_WEEKLY_TAB",     "Weekly",       "Mingguan",       "ウィークリー",         "أسبوعي",            "每周"),
	entry("PANEL_DAILY_TAB",      "Daily",        "Harian",         "デイリー",             "يومي",              "每日"),
	entry("PANEL_MONTHLY_TAB",    "Monthly",      "Bulanan",        "マンスリー",           "شهري",              "每月"),
	entry("PANEL_EMOTE_TITLE",    "EMOTE",        "EMOTE",          "エモート",             "إيموت",             "表情"),
	entry("PANEL_INVENTORY_TITLE","INVENTORY",    "INVENTORI",      "インベントリ",         "المخزون",           "物品栏"),
	entry("PANEL_IKATAN_TITLE",   "Ikatan",       "Ikatan",         "絆",                   "الرابطة",           "纽带"),
	entry("PANEL_SEASON_TITLE",   "Season",       "Musim",          "シーズン",             "الموسم",            "赛季"),
	entry("PANEL_GALERI_ROH",     "Spirit Gallery","Galeri Roh",    "精霊ギャラリー",       "معرض الأرواح",      "灵魂画廊"),
}

-- ─── Ikatan panel ─────────────────────────────────────────────────────────────

local IKATAN_ENTRIES: { Entry } = {
	entry("IKATAN_EMPTY",          "No Ikatan yet.",    "Belum ada Ikatan.",        "まだ絆なし。",          "لا يوجد رابطة بعد.",    "还没有纽带。"),
	entry("IKATAN_BTN_TELEPORT",   "Fly To",            "Terbang",                  "飛んで行く",            "اطر إليه",              "飞过去"),
	entry("IKATAN_BTN_GIFT",       "Gift",              "Hadiah",                   "ギフト",                "هدية",                  "礼物"),
	entry("IKATAN_BTN_REMOVE",     "Remove",            "Hapus",                    "削除",                  "إزالة",                 "移除"),
	entry("IKATAN_BTN_OFFER",      "Offer Ikatan",      "Tawarkan Ikatan",          "絆を結ぶ",              "عرض الرابطة",           "提议纽带"),
	entry("IKATAN_BTN_ACCEPT",     "Accept",            "Terima",                   "受け入れる",            "قبول",                  "接受"),
	entry("IKATAN_BTN_DECLINE",    "Decline",           "Tolak",                    "断る",                  "رفض",                   "拒绝"),
	entry("IKATAN_OFFER_FROM",     "Offer from: {name}","Tawaran dari: {name}",     "絆の申し込み: {name}",  "عرض من: {name}",        "来自 {name} 的提议"),
	entry("IKATAN_NEARBY",         "Nearby: {name}",    "Dekat kamu: {name}",       "近くにいる: {name}",    "بالقرب منك: {name}",    "附近：{name}"),
	entry("IKATAN_COOLDOWN_FMT",   "{time}",            "{time}",                   "{time}",                "{time}",                "{time}"),
}

-- ─── Inventory panel ──────────────────────────────────────────────────────────

local INVENTORY_ENTRIES: { Entry } = {
	entry("INVENTORY_EQUIPPED",       "Equipped:",          "Terpasang:",          "装備中:",             "المجهز:",              "已装备:"),
	entry("INVENTORY_EMOTE_SLOTS",    "Equipped Slots",     "Slot Terpasang",      "装備スロット",        "الفتحات المجهزة",      "已装备的格位"),
	entry("INVENTORY_BTN_UNEQUIP",    "Unequip",            "Lepas",               "外す",                "إزالة التجهيز",        "卸下"),
	entry("INVENTORY_BTN_EQUIP",      "Equip",              "Pasang",              "装備",                "تجهيز",               "装备"),
	entry("INVENTORY_EMPTY",          "No items owned.",    "Belum ada item.",     "アイテムなし。",      "لا توجد عناصر.",       "没有物品。"),
	entry("INVENTORY_CAT_CAPE",       "Cape",               "Jubah",               "マント",              "العباءة",              "披风"),
	entry("INVENTORY_CAT_MASK",       "Mask",               "Topeng",              "マスク",              "القناع",               "面具"),
	entry("INVENTORY_CAT_HAIR",       "Hair",               "Rambut",              "ヘア",                "الشعر",                "发型"),
	entry("INVENTORY_CAT_OUTFIT",     "Outfit",             "Pakaian",             "衣装",                "الزي",                 "服装"),
	entry("INVENTORY_CAT_WINGSKIN",   "Wing Skin",          "Kulit Sayap",         "ウィングスキン",      "جلد الجناح",           "翅膀皮肤"),
	entry("INVENTORY_CAT_INSTRUMENT", "Instrument",         "Alat Musik",          "楽器",                "الآلة الموسيقية",      "乐器"),
	entry("INVENTORY_CAT_EMOTE",      "Emote",              "Emote",               "エモート",            "الإيموت",              "表情"),
	entry("INVENTORY_CAT_TRAIL",      "Trail",              "Jejak",               "トレイル",            "الأثر",                "尾迹"),
	entry("INVENTORY_CAT_AURA",       "Aura",               "Aura",                "オーラ",              "الهالة",               "光环"),
	entry("INVENTORY_CAT_PROP",       "Prop",               "Aksesori",            "プロップ",            "الدعامة",              "道具"),
}

-- ─── Season panel ─────────────────────────────────────────────────────────────

local SEASON_ENTRIES: { Entry } = {
	entry("SEASON_NO_ACTIVE",       "No active season.",          "Tidak ada musim aktif saat ini.", "アクティブなシーズンはありません。", "لا يوجد موسم نشط.",         "暂无进行中的赛季。"),
	entry("SEASON_ENDS_IN",         "Ends in: {time}",            "Berakhir dalam: {time}",          "終了まで: {time}",                  "ينتهي في: {time}",           "距结束：{time}"),
	entry("SEASON_KOIN_BALANCE",    "✦ {amount} Koin",            "✦ {amount} Koin",                 "✦ {amount} コイン",                 "✦ {amount} عملة",            "✦ {amount} 硬币"),
	entry("SEASON_BTN_BUY_PASS",    "Get Pass",                   "Beli Pass",                       "パスを購入",                        "اشتر التصريح",               "购买通行证"),
	entry("SEASON_PASS_OWNED",      "✦ Season Pass",              "✦ Musim Pass",                    "✦ シーズンパス",                    "✦ تصريح الموسم",             "✦ 赛季通行证"),
	entry("SEASON_QUEST_SECTION",   "Quest Chain",                "Rantai Misi",                     "クエストチェーン",                  "سلسلة المهام",               "任务链"),
	entry("SEASON_SHOP_SECTION",    "Koin Shop",                  "Toko Koin Musim",                 "コインショップ",                    "متجر العملات",               "硬币商店"),
	entry("SEASON_NO_QUEST",        "No quest chain.",            "Tidak ada misi rantai.",           "クエストなし。",                    "لا توجد سلسلة مهام.",        "没有任务链。"),
	entry("SEASON_SHOP_EMPTY",      "Shop is empty.",             "Toko kosong.",                    "ショップは空です。",                 "المتجر فارغ.",               "商店为空。"),
	entry("SEASON_BTN_BUY",         "Buy",                        "Beli",                            "購入",                              "اشتر",                       "购买"),
}

-- ─── Daily task panel ─────────────────────────────────────────────────────────

local DAILY_TASK_ENTRIES: { Entry } = {
	entry("DAILY_TASK_DONE",             "Done",                     "Selesai",               "完了",            "تم",              "完成"),
	entry("DAILY_STREAK_LABEL",          "Streak: {days} days",      "Streak: {days} hari",   "連続: {days} 日", "سلسلة: {days} أيام", "连续: {days} 天"),
	entry("DAILY_MILESTONE_CLAIM",       "Claim",                    "Ambil",                 "受け取る",        "احصل عليه",       "领取"),
	entry("DAILY_MILESTONE_CLAIMED",     "Claimed",                  "Sudah diambil",         "受取済",          "تم الحصول عليه",  "已领取"),
	entry("DAILY_WEEKLY_CLEARS",         "Full Clears: {count}/7",   "Bersih: {count}/7",     "フルクリア: {count}/7", "إتمام: {count}/7", "全清: {count}/7"),
	entry("DAILY_MONTHLY_MILESTONES",    "Milestones: {count}/4",    "Milestone: {count}/4",  "マイルストーン: {count}/4", "معالم: {count}/4", "里程碑: {count}/4"),
	-- Task description keys (format strings with named params)
	entry("TASK_COLLECT_CAHAYA",         "Collect {count} Cahaya",   "Kumpulkan {count} Cahaya",     "キャハヤを{count}個集める",   "اجمع {count} كاهايا",     "收集 {count} 个光源"),
	entry("TASK_FREE_SPIRITS",           "Free {count} spirit(s)",   "Bebaskan {count} roh",         "精霊{count}体を解放",         "أطلق {count} روح",        "释放 {count} 灵魂"),
	entry("TASK_GIFT_CAHAYA",            "Gift Cahaya to {count} player(s)", "Hadiahi Cahaya ke {count} pemain", "キャハヤを{count}人に贈る", "أهدِ كاهايا لـ {count} لاعب", "赠予 {count} 名玩家光源"),
	entry("TASK_BOOST_TIMES",            "Boost {count} time(s)",    "Terbang meningkat {count}x",   "ブースト{count}回",           "قم بالتعزيز {count} مرات", "助推 {count} 次"),
	entry("TASK_COLLECT_FRAGMENTS",      "Collect {count} fragment(s)", "Kumpulkan {count} fragmen", "フラグメント{count}個を集める", "اجمع {count} شظية",      "收集 {count} 个碎片"),
	entry("TASK_PLAY_INSTRUMENT",        "Play instrument {count}s", "Mainkan alat musik {count} dtk", "楽器を{count}秒演奏",      "العب آلة موسيقية {count} ثانية", "演奏乐器 {count} 秒"),
	entry("TASK_REVIVE_PLAYERS",         "Revive {count} player(s)", "Hidupkan kembali {count} pemain", "プレイヤー{count}人を復活",  "أنعش {count} لاعب",      "复活 {count} 名玩家"),
}

-- ─── Galeri Roh panel ─────────────────────────────────────────────────────────

local GALERI_ROH_ENTRIES: { Entry } = {
	entry("GALERI_ROH_FREED_BADGE",  "FREED",         "BEBAS",          "解放済",          "تم التحرير",      "已解放"),
	entry("GALERI_ROH_LOCKED",       "Locked",        "Terkunci",       "ロック中",        "مقفل",            "已锁定"),
	entry("GALERI_ROH_TAP_HINT",     "Tap to read",   "Ketuk untuk baca","タップして読む", "اضغط للقراءة",    "点击阅读"),
}

-- ─── General UI ───────────────────────────────────────────────────────────────

local GENERAL_ENTRIES: { Entry } = {
	entry("GENERAL_CLOSE",      "Close",     "Tutup",    "閉じる",  "إغلاق",    "关闭"),
	entry("GENERAL_CONFIRM",    "Confirm",   "Konfirm",  "確認",    "تأكيد",    "确认"),
	entry("GENERAL_CANCEL",     "Cancel",    "Batal",    "キャンセル","إلغاء",  "取消"),
	entry("GENERAL_LOADING",    "Loading…",  "Memuat…",  "読み込み中…","جار التحميل…","加载中…"),
	entry("GENERAL_LEVEL",      "Lv. {n}",  "Lv. {n}", "Lv. {n}", "Lv. {n}", "Lv. {n}"),
	-- Rarity labels
	entry("RARITY_BIASA",       "Common",    "Biasa",    "コモン",  "شائع",     "普通"),
	entry("RARITY_LANGKA",      "Rare",      "Langka",   "レア",    "نادر",     "稀有"),
	entry("RARITY_EPIK",        "Epic",      "Epik",     "エピック","ملحمي",    "史诗"),
	entry("RARITY_LEGENDARIS",  "Legendary", "Legendaris","レジェンド","أسطوري", "传说"),
	-- Toast / notifications
	entry("TOAST_MILESTONE_CLAIMED",  "Milestone reward claimed!", "Hadiah milestone diterima!", "マイルストーン報酬獲得！", "تم استلام مكافأة المعلم!", "已领取里程碑奖励！"),
	entry("TOAST_IKATAN_FORMED",      "Ikatan formed with {name}!", "Ikatan terbentuk dengan {name}!", "絆を結んだ！ {name}", "تشكلت الرابطة مع {name}!", "与 {name} 建立了纽带！"),
	entry("TOAST_SPIRIT_FREED",       "Spirit freed!", "Roh dibebaskan!", "精霊を解放！", "تم تحرير الروح!", "灵魂已释放！"),
	entry("TOAST_FRAGMENT_CRAFTED",   "Item unlocked: {item}!", "Item terbuka: {item}!", "アイテム解放: {item}！", "تم فتح العنصر: {item}!", "物品已解锁：{item}！"),
	entry("TOAST_CAHAYA_CAP",         "Daily Cahaya cap reached.", "Batas harian Cahaya tercapai.", "デイリーキャハヤ上限に達しました。", "تم الوصول إلى الحد اليومي للكاهايا.", "已达到每日光源上限。"),
	entry("TOAST_WING_UPGRADED",      "Wing upgraded to Lv. {n}!", "Sayap naik ke Lv. {n}!", "翼がLv. {n}にアップグレード！", "ترقية الجناح إلى المستوى {n}!", "翅膀升级至 {n} 级！"),
	-- Wing gate denial
	entry("GATE_DENIED",              "Wing level too low for this realm.", "Level sayap terlalu rendah untuk realm ini.", "翼レベルが低すぎます。", "مستوى الجناح منخفض جداً.", "翅膀等级不足。"),
}

-- ─── Assemble all entries ─────────────────────────────────────────────────────

local ALL_ENTRIES: { Entry } = {}

local function append(list: { Entry })
	for _, e in list do
		table.insert(ALL_ENTRIES, e)
	end
end

append(EXPRESSION_ENTRIES)
append(HUD_ENTRIES)
append(PANEL_ENTRIES)
append(IKATAN_ENTRIES)
append(INVENTORY_ENTRIES)
append(SEASON_ENTRIES)
append(DAILY_TASK_ENTRIES)
append(GALERI_ROH_ENTRIES)
append(GENERAL_ENTRIES)

-- Returns all entries ready for LocalizationTable:SetEntries().
function LocalizationData.getEntries(): { Entry }
	return ALL_ENTRIES
end

-- Returns just the expression phrase keys (used by Constants.EXPRESSION_PHRASE_KEYS).
function LocalizationData.getExpressionKeys(): { string }
	local keys: { string } = {}
	for _, e in EXPRESSION_ENTRIES do
		table.insert(keys, e.Key)
	end
	return keys
end

return LocalizationData
