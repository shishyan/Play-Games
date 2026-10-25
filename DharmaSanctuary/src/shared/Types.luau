--[[
    Types.luau
    ----------
    All exported Luau types for Dirgantara.
    Every service, controller, and shared module imports types from here.
    No `any` allowed in type signatures anywhere in the codebase.
]]

local Types = {}

-- ─── Economy & Progression ───────────────────────────────────────────────────

export type WingDef = {
	level: number,
	name: string,
	cahayaHatiCost: number,
	chargeSegments: number,
	canCarry: boolean,
	canEnterSkysPeak: boolean,
}

export type EquippedLoadout = {
	cape: string?,
	mask: string?,
	hair: string?,
	outfit: string?,
	wingSkin: string?,
	instrument: string?,
	emoteSlots: { string },
	trail: string?,
	aura: string?,
	prop: string?,
}

-- ─── Daily Task System ────────────────────────────────────────────────────────

export type DailyTask = {
	id: string,
	difficulty: "Easy" | "Medium" | "Hard",
	target: number,
	progress: number,
	completed: boolean,
}

export type DailyTaskState = {
	date: string,
	tasks: { DailyTask },
	completedIndices: { number },
	milestoneRewardsClaimed: { number },
}

export type WeeklyState = {
	weekNumber: number,
	fullClearDays: number,
	rewardClaimed: boolean,
}

export type MonthlyState = {
	month: string,
	weeklyMilestonesMet: number,
	rewardClaimed: boolean,
}

-- ─── Task Definitions (static pool) ──────────────────────────────────────────

export type TaskDef = {
	id: string,
	difficulty: "Easy" | "Medium" | "Hard",
	descriptionKey: string,
	target: number,
	trackingEvent: string,
	paramFilter: (({ [string]: any }) -> boolean)?,
}

export type TaskReward = {
	cahaya: number?,
	cahayaHati: number?,
	koinMusim: number?,
	itemId: string?,
	fragmentItemId: string?,
}

-- ─── Spirits ─────────────────────────────────────────────────────────────────

export type SpiritReward = {
	cahaya: number,
	cahayaHati: number,
	itemId: string?,
	wingLevelBonus: number,
}

export type SpiritDef = {
	id: string,
	realmId: string,
	spiritType: "Ancestor" | "Season" | "Daily",
	position: Vector3,
	fragmentCount: number,
	fragmentPositions: { Vector3 },
	reward: SpiritReward,
	nameKey: string,
	vignettePath: string,
	seasonId: string?,
}

-- ─── Cosmetics ───────────────────────────────────────────────────────────────

export type CosmeticDef = {
	id: string,
	nameKey: string,
	category: "Cape" | "Mask" | "Hair" | "Outfit" | "WingSkin" | "Instrument"
		| "Emote" | "Trail" | "Aura" | "Prop",
	rarity: "Biasa" | "Langka" | "Epik" | "Legendaris",
	assetId: number,
	syncAnimationId: number?,
	sourceType: "Task" | "Spirit" | "Season" | "Robux" | "Event",
	seasonId: string?,
	robuxProductId: number?,
	giftable: boolean,
}

-- ─── Seasons ─────────────────────────────────────────────────────────────────

export type KoinMusimItem = {
	itemId: string,
	price: number,
}

export type SeasonQuest = {
	id: string,
	step: number,
	descriptionKey: string,
	completionEvent: string,
	target: number,
	reward: TaskReward,
}

export type SeasonDef = {
	id: string,
	nameKey: string,
	startTimestamp: number,
	endTimestamp: number,
	realmExtensionId: string,
	spirits: { string },
	questChain: { SeasonQuest },
	koinMusimShop: { KoinMusimItem },
	musimPassProductId: number,
	musimPassPlusProductId: number,
}

-- ─── Realms ───────────────────────────────────────────────────────────────────

export type RealmDef = {
	id: string,
	placeId: number,
	nameKey: string,
	minWingLevel: number,
	kegelapanZoneCount: number,
	hasSeasonalExtension: boolean,
}

-- ─── Player Data (full schema) ────────────────────────────────────────────────

export type PlayerData = {
	-- Meta
	schemaVersion: number,
	createdAt: number,
	lastLogin: number,

	-- Economy
	cahaya: number,
	cahayaHati: number,
	koinMusim: number,
	bintangHati: number,

	-- Progression
	wingLevel: number,
	awanXP: number,
	skysPeakCycles: number,
	lastRealmId: string,   -- most recent realm successfully entered; used by Sky's Peak return

	-- Daily
	dailyCahayaCollected: number,
	dailyResetTimestamp: number,
	loginStreak: number,
	lastStreakDate: string,
	graceDaysRemaining: number,
	dailySpiritsTouched: { string },

	-- Tasks
	taskState: DailyTaskState,

	-- Weekly / Monthly
	weeklyState: WeeklyState,
	monthlyState: MonthlyState,

	-- Spirits
	freedSpiritIds: { [string]: boolean },
	galeriRohOrder: { string },

	-- Ikatan
	ikatanList: { string },
	ikatanGiftsGivenToday: number,

	-- Cosmetics
	ownedItems: { [string]: boolean },
	fragmentInventory: { [string]: number },
	equippedItems: EquippedLoadout,
	openedChests: { [string]: boolean },

	-- Season
	activeSeasonId: string,
	seasonPassOwned: boolean,
	seasonPassPlusOwned: boolean,
	freedSeasonSpiritIds: { [string]: boolean },
	seasonQuestProgress: { [string]: number },
	dailyChestBonusUsedToday: boolean,

	-- Monetization
	starterPackClaimed: boolean,
	uiScale: number,

	-- Internal flags
	dataLoadFailed: boolean?,
}

-- ─── Naga Gelap AI ────────────────────────────────────────────────────────────

export type NagaState = "PATROL" | "CHASE" | "EXTINGUISH_PLAYER"

export type NagaAgent = {
	id: string,
	zoneId: string,
	model: Model,
	state: NagaState,
	targetUserId: number?,
	zoneBounds: Region3,
}

-- ─── Chest Reward ─────────────────────────────────────────────────────────────

export type ChestRewardEntry = {
	weight: number,
	type: "cahaya" | "koinMusim" | "cosmeticFragment",
	amount: number?,
	rarity: ("Biasa" | "Langka" | "Epik")?,
}

return Types
