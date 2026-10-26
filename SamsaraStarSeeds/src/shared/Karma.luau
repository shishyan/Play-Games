--!nonstrict
-- Karma: the net moral balance of your deeds (Rta vs Anrita). Pure functions only.
local Karma = {}

Karma.MIN = -100
Karma.MAX = 100
Karma.DEVA_AT = 30
Karma.ASURA_AT = -30

-- Karma value of deeds. `anrita` is the chaos each deed adds to the world's ledger.
Karma.DEEDS = {
	kill_corrupt = { karma = 0.2, rta = 0.2 },
	pacify = { karma = 2, rta = 2 },
	kill_peaceful = { karma = -5, rta = -6, anrita = 1 },
	cleanse_blight = { karma = 2, rta = 3 },
	plant_grove = { karma = 1.5, rta = 2 },
	donate = { karma = 0.5, rta = 0.5 }, -- plus 1 per 20 gold, see donateKarma
	coerce_merchant = { karma = -4, rta = -2, anrita = 1 },
	hoard_temptation = { karma = -6, rta = -3, anrita = 1 },
	astra_backfire = { karma = -1, rta = -1, anrita = 0 },
}

function Karma.clamp(v: number): number
	return math.clamp(v, Karma.MIN, Karma.MAX)
end

function Karma.path(karma: number): string
	if karma >= Karma.DEVA_AT then
		return "Deva"
	elseif karma <= Karma.ASURA_AT then
		return "Asura"
	end
	return "Madhyama"
end

function Karma.add(karma: number, delta: number): number
	return Karma.clamp(karma + delta)
end

function Karma.donateKarma(gold: number): number
	return 0.5 + gold / 20
end

-- Merchants like the virtuous: 0.75x at +100 karma, 1.25x at -100.
function Karma.priceMult(karma: number): number
	return math.clamp(1 - karma / 400, 0.75, 1.25)
end

-- Celestial access needs both inner work (Dharma) and a good record (Karma).
Karma.SVARGA_DHARMA = 35
Karma.SVARGA_KARMA = 15

function Karma.canEnterSvarga(karma: number, dharma: number): (boolean, string?)
	if dharma < Karma.SVARGA_DHARMA then
		return false, ("The celestial gate answers only to Dharma %d or higher."):format(Karma.SVARGA_DHARMA)
	end
	if karma < Karma.SVARGA_KARMA then
		return false, "Svarga's gate rejects you. Your Karma is too heavy."
	end
	return true, nil
end

return Karma
