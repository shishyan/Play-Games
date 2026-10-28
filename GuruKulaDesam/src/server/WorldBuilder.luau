--!strict
--[[
	WorldBuilder.luau
	Guru Kula Desam — Subcontinent & Street-Level Temple Town World Architect
	- True Subcontinent Scale (16,000 x 24,000 studs built from an 8x12 grid of 2000x2000 satellite tiles)
	- Segmented Inter-City National Highways (chunks <= 1800 studs so Roblox never clamps Part.Size)
	- 20 Full Street-Level Temple Towns (680 x 680 studs each):
	    * 4 Concentric Mada Veedhi Car Streets around the Central Temple Compound
	    * South Mada Veedhi: Sannathi Bazaar, 6 Agraharam Heritage Houses, Welcome Arch & Archana Stall
	    * East Mada Veedhi: Virtual Gurukulam Banyan School Pavilion, Olai Chuvadi Desk & Annadanam/Go-Shala
	    * West Mada Veedhi: 90x90 Sacred Pushkarini Temple Tank, Padithurai Steps & Neerazhi Mandapam
	    * Outer Transit Ring: Railway Station with Express Train on tracks, Highway Bus/Car Stand & Airport Helipad
	    * North Side: Multi-Tiered Natural Mountain, Foothill Pada Mandapam Arch, Long Climbable Padigal Steps,
	      Mid-Climb Siddhar Mandapam, Summit Climb Pad & Walk-In Hilltop Garbhagriha Sanctum
]]

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local TempleConfig = require(Shared:WaitForChild("TempleConfig"))

local WorldBuilder = {}

local ALL_BOX_FACES = {
	Enum.NormalId.Top,
	Enum.NormalId.Bottom,
	Enum.NormalId.Front,
	Enum.NormalId.Back,
	Enum.NormalId.Left,
	Enum.NormalId.Right,
}

local SIDE_AND_TOP_FACES = {
	Enum.NormalId.Front,
	Enum.NormalId.Back,
	Enum.NormalId.Left,
	Enum.NormalId.Right,
	Enum.NormalId.Top,
}

local function makePart(props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		if k ~= "Parent" then
			(p :: any)[k] = v
		end
	end
	p.Parent = props.Parent
	return p
end

local function applyPhotoPanel(part: BasePart, face: Enum.NormalId, imageId: string, lightInfluence: number?)
	local decal = Instance.new("Decal")
	decal.Face = face
	decal.Texture = imageId
	decal.Parent = part

	local sgui = Instance.new("SurfaceGui")
	sgui.Face = face
	sgui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sgui.PixelsPerStud = 32
	sgui.LightInfluence = lightInfluence or 0.18
	sgui.Brightness = 1.15
	sgui.AlwaysOnTop = false
	sgui.Parent = part

	local img = Instance.new("ImageLabel")
	img.Size = UDim2.fromScale(1, 1)
	img.BackgroundTransparency = 1
	img.Image = imageId
	img.ScaleType = Enum.ScaleType.Stretch
	img.Parent = sgui
end

local function applyTiledTexture(
	part: BasePart,
	face: Enum.NormalId,
	imageId: string,
	uTile: number,
	vTile: number,
	transparency: number?
)
	local tex = Instance.new("Texture")
	tex.Face = face
	tex.Texture = imageId
	tex.StudsPerTileU = uTile
	tex.StudsPerTileV = vTile
	tex.Transparency = transparency or 0
	tex.Parent = part
end

local function createBanner(
	parentPart: BasePart,
	titleText: string,
	subText: string,
	borderColor: Color3,
	offsetY: number,
	maxDist: number,
	sizeX: number?,
	sizeY: number?
)
	local bbg = Instance.new("BillboardGui")
	bbg.Size = UDim2.fromOffset(sizeX or 280, sizeY or 72)
	bbg.StudsOffset = Vector3.new(0, offsetY, 0)
	bbg.AlwaysOnTop = false
	bbg.MaxDistance = maxDist
	bbg.Parent = parentPart

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Color3.fromRGB(22, 18, 14)
	frame.BackgroundTransparency = 0.12
	frame.Parent = bbg
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

	local stroke = Instance.new("UIStroke")
	stroke.Color = borderColor
	stroke.Thickness = 2
	stroke.Parent = frame

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -12, 0.56, 0)
	title.Position = UDim2.fromOffset(6, 2)
	title.BackgroundTransparency = 1
	title.TextColor3 = borderColor
	title.Font = Enum.Font.GothamBold
	title.TextScaled = true
	title.Text = titleText
	title.Parent = frame

	local sub = Instance.new("TextLabel")
	sub.Size = UDim2.new(1, -12, 0.40, 0)
	sub.Position = UDim2.new(0, 6, 0.56, 0)
	sub.BackgroundTransparency = 1
	sub.TextColor3 = Color3.fromRGB(242, 235, 215)
	sub.Font = Enum.Font.GothamMedium
	sub.TextScaled = true
	sub.Text = subText
	sub.Parent = frame
end

function WorldBuilder.setupLighting()
	Lighting.ClockTime = 8.2 -- Golden morning temple dawn across Bharatavarsha
	Lighting.GeographicLatitude = 15
	Lighting.Brightness = 2.6
	Lighting.Ambient = Color3.fromRGB(118, 112, 105)
	Lighting.OutdoorAmbient = Color3.fromRGB(168, 158, 142)
	Lighting.ColorShift_Top = Color3.fromRGB(255, 235, 200)

	for _, child in ipairs(Lighting:GetChildren()) do
		if child:IsA("PostEffect") or child:IsA("Atmosphere") or child:IsA("Sky") then
			child:Destroy()
		end
	end

	local atmo = Instance.new("Atmosphere")
	atmo.Density = 0.22
	atmo.Offset = 0.15
	atmo.Color = Color3.fromRGB(220, 235, 255)
	atmo.Decay = Color3.fromRGB(255, 215, 175)
	atmo.Glare = 0.15
	atmo.Haze = 1.1
	atmo.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.35
	bloom.Size = 22
	bloom.Threshold = 1.1
	bloom.Parent = Lighting

	local cc = Instance.new("ColorCorrectionEffect")
	cc.Brightness = 0.03
	cc.Contrast = 0.10
	cc.Saturation = 0.18
	cc.TintColor = Color3.fromRGB(255, 248, 238)
	cc.Parent = Lighting

	local rays = Instance.new("SunRaysEffect")
	rays.Intensity = 0.12
	rays.Spread = 0.65
	rays.Parent = Lighting
end

-- ============================================================================
-- 1. TRUE SUBCONTINENT SCALE SATELLITE CONTINENT (16,000 x 24,000 STUDS)
-- Built as an 8 x 12 grid of 2000 x 2000 stud plates (since Roblox caps Part.Size at 2048)
-- ============================================================================
function WorldBuilder.buildContinent(root: Folder)
	local mapFolder = Instance.new("Folder")
	mapFolder.Name = "BharatavarshaMap"
	mapFolder.Parent = root

	local cols = 8
	local rows = 12
	local tileW = TempleConfig.MapBounds.WorldWidth / cols  -- 2000 studs
	local tileL = TempleConfig.MapBounds.WorldLength / rows -- 2000 studs
	local startX = -TempleConfig.MapBounds.WorldWidth * 0.5
	local startZ = -TempleConfig.MapBounds.WorldLength * 0.5

	-- Surrounding Indian Ocean Ring (Arabian Sea, Bay of Bengal & Indian Ocean)
	local oceanFolder = Instance.new("Folder")
	oceanFolder.Name = "IndianOceanTiles"
	oceanFolder.Parent = mapFolder

	for r = 0, rows + 1 do
		for c = 0, cols + 1 do
			if r == 0 or r == rows + 1 or c == 0 or c == cols + 1 then
				local ox = startX + (c - 0.5) * tileW
				local oz = startZ + (r - 0.5) * tileL
				makePart({
					Name = string.format("OceanTile_%d_%d", c, r),
					Size = Vector3.new(tileW, 3, tileL),
					Position = Vector3.new(ox, -2.5, oz),
					Color = Color3.fromRGB(18, 86, 125),
					Material = Enum.Material.Glass,
					Transparency = 0.12,
					Parent = oceanFolder,
				})
			end
		end
	end

	-- 8 x 12 Seamless Satellite Continent Grid of India & Sri Lanka (16,000 x 24,000 studs)
	local continentFolder = Instance.new("Folder")
	continentFolder.Name = "IndiaSatelliteGrid"
	continentFolder.Parent = mapFolder

	local texResolution = 1024
	local rectW = texResolution / cols
	local rectH = texResolution / rows

	for r = 1, rows do
		for c = 1, cols do
			local cx = startX + (c - 0.5) * tileW
			local cz = startZ + (r - 0.5) * tileL

			local tile = makePart({
				Name = string.format("IndiaContinentTile_%d_%d", c, r),
				Size = Vector3.new(tileW, 4, tileL),
				Position = Vector3.new(cx, 0, cz),
				Color = Color3.fromRGB(92, 128, 76),
				Material = Enum.Material.SmoothPlastic,
				Parent = continentFolder,
			})

			local sgui = Instance.new("SurfaceGui")
			sgui.Name = "SatelliteTileGui"
			sgui.Face = Enum.NormalId.Top
			sgui.CanvasSize = Vector2.new(512, 512)
			sgui.LightInfluence = 0.30
			sgui.Brightness = 1.08
			sgui.Parent = tile

			local img = Instance.new("ImageLabel")
			img.Size = UDim2.fromScale(1, 1)
			img.BackgroundTransparency = 1
			img.Image = TempleConfig.VisualAssets.IndiaReliefMap
			img.ImageRectOffset = Vector2.new((c - 1) * rectW, (r - 1) * rectH)
			img.ImageRectSize = Vector2.new(rectW, rectH)
			img.ScaleType = Enum.ScaleType.Stretch
			img.Parent = sgui
		end
	end

	-- Segmented Northern Himalayan Panorama Wall (8 segments of 2000 studs each along Z = -12000)
	local himalayaFolder = Instance.new("Folder")
	himalayaFolder.Name = "HimalayanFrontierWall"
	himalayaFolder.Parent = mapFolder

	for c = 1, cols do
		local hx = startX + (c - 0.5) * tileW
		local wallSeg = makePart({
			Name = "HimalayaPanorama_" .. tostring(c),
			Size = Vector3.new(tileW, 320, 16),
			Position = Vector3.new(hx, 160, startZ - 8),
			Color = Color3.fromRGB(225, 238, 255),
			Material = Enum.Material.SmoothPlastic,
			Parent = himalayaFolder,
		})
		applyPhotoPanel(wallSeg, Enum.NormalId.Back, TempleConfig.VisualAssets.HimalayaKedarnath, 0.15)
		applyPhotoPanel(wallSeg, Enum.NormalId.Front, TempleConfig.VisualAssets.HimalayaKedarnath, 0.15)
	end
end

-- ============================================================================
-- 2. INTER-CITY NATIONAL HIGHWAYS & SEA BRIDGES (CHUNKED <= 1800 STUDS)
-- ============================================================================
function WorldBuilder.buildHighways(root: Folder)
	local roadFolder = Instance.new("Folder")
	roadFolder.Name = "NationalHighways"
	roadFolder.Parent = root

	local maxChunkLen = 1800

	for idx, route in ipairs(TempleConfig.PilgrimageRoutes) do
		local tFrom = TempleConfig.getTempleById(route.From)
		local tTo = TempleConfig.getTempleById(route.To)
		if tFrom and tTo then
			local p1 = TempleConfig.latLonToWorld(tFrom.Lat, tFrom.Lon, 2.15)
			local p2 = TempleConfig.latLonToWorld(tTo.Lat, tTo.Lon, 2.15)
			local delta = p2 - p1
			local totalDist = Vector3.new(delta.X, 0, delta.Z).Magnitude
			local dir = (p2 - p1).Unit
			local numChunks = math.max(1, math.ceil(totalDist / maxChunkLen))
			local chunkLen = totalDist / numChunks

			for c = 1, numChunks do
				local segStart = p1 + dir * ((c - 1) * chunkLen)
				local segEnd = p1 + dir * (c * chunkLen)
				local segMid = (segStart + segEnd) * 0.5

				local roadSeg = makePart({
					Name = string.format("Highway_%d_%s_to_%s_Seg%d", idx, route.From, route.To, c),
					Size = Vector3.new(24, 0.45, chunkLen + 2),
					CFrame = CFrame.lookAt(segMid, Vector3.new(segEnd.X, segMid.Y, segEnd.Z)),
					Color = if route.Type == "SeaBridge"
						then Color3.fromRGB(185, 175, 155)
						else Color3.fromRGB(62, 62, 68),
					Material = Enum.Material.Asphalt,
					CanCollide = true,
					Parent = roadFolder,
				})

				applyTiledTexture(
					roadSeg,
					Enum.NormalId.Top,
					TempleConfig.VisualAssets.HighwayRoadTex,
					24,
					48,
					0.02
				)
			end

			-- Highway Milestone (Maiyakkal) at route midpoint and quarter points
			for _, frac in ipairs({ 0.25, 0.5, 0.75 }) do
				local mPos = p1:Lerp(p2, frac)
				local milestone = makePart({
					Name = string.format("Milestone_%d_%d", idx, math.floor(frac * 100)),
					Size = Vector3.new(3.2, 6.0, 1.8),
					Position = mPos + Vector3.new(15, 3.0, 0),
					Color = Color3.fromRGB(245, 240, 225),
					Material = Enum.Material.Limestone,
					Parent = roadFolder,
				})
				makePart({
					Name = "MilestoneCap",
					Size = Vector3.new(3.4, 1.6, 2.0),
					Position = milestone.Position + Vector3.new(0, 3.6, 0),
					Color = Color3.fromRGB(245, 195, 45),
					Material = Enum.Material.SmoothPlastic,
					Parent = roadFolder,
				})
				createBanner(
					milestone,
					"🛣️ " .. route.Name,
					tFrom.TownName .. " ↔ " .. tTo.TownName,
					Color3.fromRGB(255, 225, 110),
					6.5,
					260,
					240,
					56
				)
			end
		end
	end
end

-- ============================================================================
-- 3. HELPER: BUILD TEMPLE SANCTUARY (EXTERIOR GOPURAM & WALK-IN GARBHAGRIHA)
-- Placed both in the Town Center Complex AND atop the Mountain Summit!
-- ============================================================================
local function buildSanctuaryShrine(
	parentFolder: Folder,
	temple: TempleConfig.TempleEntry,
	centerPos: Vector3,
	labelPrefix: string,
	showSkyBeacon: boolean
)
	local sanctumY = centerPos.Y

	-- Sacred Temple Courtyard Platform (Prakaram)
	local courtyard = makePart({
		Name = labelPrefix .. "_SanctuaryCourtyard",
		Size = Vector3.new(84, 1.4, 84),
		Position = Vector3.new(centerPos.X, sanctumY + 0.7, centerPos.Z),
		Color = Color3.fromRGB(215, 205, 188),
		Material = Enum.Material.Cobblestone,
		Parent = parentFolder,
	})
	applyTiledTexture(courtyard, Enum.NormalId.Top, TempleConfig.VisualAssets.TempleStepsTex, 24, 24, 0.2)

	-- Compound Prakaram Perimeter Walls (East, West & North walls with Chola Red/White stripes)
	for _, sideX in ipairs({ -41, 41 }) do
		makePart({
			Name = labelPrefix .. "_PrakaramWallSide",
			Size = Vector3.new(2.2, 11, 84),
			Position = Vector3.new(centerPos.X + sideX, sanctumY + 6.5, centerPos.Z),
			Color = Color3.fromRGB(235, 222, 205),
			Material = Enum.Material.Limestone,
			Parent = parentFolder,
		})
	end

	-- Southern Raja Gopuram Entrance Gateway Arch (at +Z edge of courtyard)
	for _, pillarX in ipairs({ -11, 11 }) do
		makePart({
			Name = labelPrefix .. "_GopuramBasePillar",
			Size = Vector3.new(7, 16, 7),
			Position = Vector3.new(centerPos.X + pillarX, sanctumY + 9, centerPos.Z + 38),
			Color = Color3.fromRGB(210, 185, 145),
			Material = Enum.Material.Sandstone,
			Parent = parentFolder,
		})
	end
	for tier = 1, 5 do
		local w = 30 - tier * 3.2
		local d = 10 - tier * 1.0
		local ty = sanctumY + 17 + (tier - 0.5) * 4.2
		makePart({
			Name = labelPrefix .. "_GopuramTier_" .. tostring(tier),
			Size = Vector3.new(w, 4.0, d),
			Position = Vector3.new(centerPos.X, ty, centerPos.Z + 38),
			Color = if tier % 2 == 1 then temple.PrimaryColor else Color3.fromRGB(240, 220, 175),
			Material = Enum.Material.Sandstone,
			Parent = parentFolder,
		})
	end

	-- Sacred Dwajasthambam (Golden Temple Flagstaff) & Bali Peetham in front of Sanctum
	makePart({
		Name = labelPrefix .. "_DwajasthambamBase",
		Size = Vector3.new(4.2, 3.2, 4.2),
		Position = Vector3.new(centerPos.X, sanctumY + 2.6, centerPos.Z + 20),
		Color = Color3.fromRGB(195, 180, 155),
		Material = Enum.Material.Granite,
		Parent = parentFolder,
	})
	makePart({
		Name = labelPrefix .. "_DwajasthambamPole",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(26, 1.4, 1.4),
		CFrame = CFrame.new(centerPos.X, sanctumY + 16, centerPos.Z + 20) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(255, 205, 55),
		Material = Enum.Material.Foil,
		Parent = parentFolder,
	})

	-- Photorealistic Temple Exterior Panorama Billboard Wall (at North side of courtyard)
	local exteriorWall = makePart({
		Name = labelPrefix .. "_PhotorealisticTempleExterior",
		Size = Vector3.new(54, 32, 2.5),
		Position = Vector3.new(centerPos.X, sanctumY + 17.2, centerPos.Z - 26),
		Color = Color3.fromRGB(245, 235, 215),
		Material = Enum.Material.SmoothPlastic,
		Parent = parentFolder,
	})
	applyPhotoPanel(exteriorWall, Enum.NormalId.Back, temple.ExteriorImageId, 0.12)
	applyPhotoPanel(exteriorWall, Enum.NormalId.Front, temple.ExteriorImageId, 0.12)

	makePart({
		Name = labelPrefix .. "_GopuramGoldenCrown",
		Size = Vector3.new(56, 3.2, 3.6),
		Position = Vector3.new(centerPos.X, sanctumY + 34.5, centerPos.Z - 26),
		Color = temple.PrimaryColor,
		Material = Enum.Material.Foil,
		Parent = parentFolder,
	})

	-- Walk-In Photorealistic Garbhagriha (Inner Sanctum Darshan Shrine)
	local garbhagrihaBackdrop = makePart({
		Name = labelPrefix .. "_GarbhagrihaSanctumImage",
		Size = Vector3.new(24, 18, 1.6),
		Position = Vector3.new(centerPos.X, sanctumY + 10.2, centerPos.Z - 8),
		Color = Color3.fromRGB(255, 235, 190),
		Material = Enum.Material.SmoothPlastic,
		Parent = parentFolder,
	})
	-- Back is +Z (facing the player walking North into the sanctum), Front is -Z
	applyPhotoPanel(garbhagrihaBackdrop, Enum.NormalId.Back, temple.SanctumImageId, 0.05)
	applyPhotoPanel(garbhagrihaBackdrop, Enum.NormalId.Front, temple.SanctumImageId, 0.05)

	for _, sx in ipairs({ -13, 13 }) do
		makePart({
			Name = labelPrefix .. "_SanctumPillar",
			Size = Vector3.new(2.8, 18.5, 10),
			Position = Vector3.new(centerPos.X + sx, sanctumY + 10.4, centerPos.Z - 4),
			Color = Color3.fromRGB(165, 152, 135),
			Material = Enum.Material.Granite,
			Parent = parentFolder,
		})
	end
	makePart({
		Name = labelPrefix .. "_SanctumRoofMandapam",
		Size = Vector3.new(30, 2.4, 14),
		Position = Vector3.new(centerPos.X, sanctumY + 20.4, centerPos.Z - 4),
		Color = Color3.fromRGB(215, 175, 85),
		Material = Enum.Material.Sandstone,
		Parent = parentFolder,
	})

	-- Warm Garbhagriha Aarti Lamp & Darshan ProximityPrompt
	local sanctumLightPart = makePart({
		Name = labelPrefix .. "_GarbhagrihaAartiLamp",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(2.2, 2.2, 2.2),
		Position = Vector3.new(centerPos.X, sanctumY + 4.8, centerPos.Z + 2),
		Color = Color3.fromRGB(255, 195, 65),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = parentFolder,
	})
	local sLight = Instance.new("PointLight")
	sLight.Color = Color3.fromRGB(255, 200, 95)
	sLight.Brightness = 2.6
	sLight.Range = 34
	sLight.Parent = sanctumLightPart

	local darshanPrompt = Instance.new("ProximityPrompt")
	darshanPrompt.Name = "DarshanPrompt"
	darshanPrompt.ObjectText = temple.Name .. " (" .. temple.DeityTitle .. ")"
	darshanPrompt.ActionText = "🙏 Perform Darshan & Receive Boon (+" .. tostring(temple.KarmaReward) .. " Karma)"
	darshanPrompt.HoldDuration = 0.25
	darshanPrompt.MaxActivationDistance = 28
	darshanPrompt.RequiresLineOfSight = false
	darshanPrompt:SetAttribute("TempleId", temple.Id)
	darshanPrompt.Parent = sanctumLightPart

	if showSkyBeacon then
		local beacon = Instance.new("BillboardGui")
		beacon.Name = "TempleSkyBeacon"
		beacon.Size = UDim2.fromOffset(320, 86)
		beacon.StudsOffset = Vector3.new(0, 24, 0)
		beacon.AlwaysOnTop = true
		beacon.MaxDistance = 1200
		beacon.Parent = exteriorWall

		local bFrame = Instance.new("Frame")
		bFrame.Size = UDim2.fromScale(1, 1)
		bFrame.BackgroundColor3 = Color3.fromRGB(20, 16, 12)
		bFrame.BackgroundTransparency = 0.14
		bFrame.Parent = beacon
		Instance.new("UICorner", bFrame).CornerRadius = UDim.new(0, 10)

		local bStroke = Instance.new("UIStroke")
		bStroke.Color = temple.PrimaryColor
		bStroke.Thickness = 2
		bStroke.Parent = bFrame

		local bTitle = Instance.new("TextLabel")
		bTitle.Size = UDim2.new(1, -12, 0.56, 0)
		bTitle.Position = UDim2.fromOffset(6, 2)
		bTitle.BackgroundTransparency = 1
		bTitle.TextColor3 = temple.PrimaryColor
		bTitle.Font = Enum.Font.GothamBold
		bTitle.TextScaled = true
		bTitle.Text = (if temple.Deity == "Murugan" then "🦚 " else "🔱 ") .. temple.Name
		bTitle.Parent = bFrame

		local bSub = Instance.new("TextLabel")
		bSub.Size = UDim2.new(1, -12, 0.40, 0)
		bSub.Position = UDim2.new(0, 6, 0.56, 0)
		bSub.BackgroundTransparency = 1
		bSub.TextColor3 = Color3.fromRGB(240, 232, 210)
		bSub.Font = Enum.Font.GothamMedium
		bSub.TextScaled = true
		bSub.Text = "✨ Boon: " .. temple.WishSolved .. " (Grade " .. tostring(temple.GradeRegion) .. ")"
		bSub.Parent = bFrame
	end
end

-- ============================================================================
-- 4. HELPER: MASSIVE NATURAL MOUNTAIN & LONG CLIMBABLE STONE STEPS (PADIGAL)
-- Ascends from the Northern Foothill Arch (Z = -165) up to Summit (Z = -310, Y = Altitude)
-- ============================================================================
local function buildNaturalMountainAndHillSteps(templeFolder: Folder, temple: TempleConfig.TempleEntry, townPos: Vector3)
	local hillFolder = Instance.new("Folder")
	hillFolder.Name = "SacredHillAndPadigal"
	hillFolder.Parent = templeFolder

	local alt = math.max(28, temple.Altitude)
	local hillCenter = townPos + Vector3.new(0, 0, -350)
	local hillTex = if temple.Lat > 27
		then TempleConfig.VisualAssets.HimalayaKedarnath
		else TempleConfig.VisualAssets.WesternGhatsHill
	local hillColor = if temple.Lat > 27
		then Color3.fromRGB(210, 225, 240)
		else Color3.fromRGB(102, 124, 84)

	-- 5-Tiered Natural Mountain Mass with WedgePart slopes on all 4 sides
	local tiers = 5
	for tier = 1, tiers do
		local frac = (tier - 1) / tiers
		local tierY0 = 2.2 + (alt - 2.2) * frac
		local tierH = (alt - 2.2) / tiers
		local radius = 115 * (1 - frac * 0.52)

		local tierCore = makePart({
			Name = "MountainTier_" .. tostring(tier),
			Size = Vector3.new(radius * 2, tierH, radius * 2),
			Position = Vector3.new(hillCenter.X, tierY0 + tierH * 0.5, hillCenter.Z),
			Color = hillColor,
			Material = if temple.Lat > 27 then Enum.Material.Glacier else Enum.Material.Rock,
			Parent = hillFolder,
		})
		for _, face in ipairs(SIDE_AND_TOP_FACES) do
			applyTiledTexture(tierCore, face, hillTex, 36, 36, 0.08)
		end

		local skirtSpecs = {
			{ offset = Vector3.new(0, 0, radius + 14), rotY = 0, sx = radius * 1.85, sz = 28 },
			{ offset = Vector3.new(0, 0, -(radius + 14)), rotY = 180, sx = radius * 1.85, sz = 28 },
			{ offset = Vector3.new(radius + 14, 0, 0), rotY = 90, sx = radius * 1.85, sz = 28 },
			{ offset = Vector3.new(-(radius + 14), 0, 0), rotY = -90, sx = radius * 1.85, sz = 28 },
		}
		for sIdx, sk in ipairs(skirtSpecs) do
			local wedge = Instance.new("WedgePart")
			wedge.Name = string.format("MountainSlope_%d_%d", tier, sIdx)
			wedge.Anchored = true
			wedge.Size = Vector3.new(sk.sx, tierH, sk.sz)
			wedge.CFrame = CFrame.new(
				hillCenter.X + sk.offset.X,
				tierY0 + tierH * 0.5,
				hillCenter.Z + sk.offset.Z
			) * CFrame.Angles(0, math.rad(sk.rotY), 0)
			wedge.Color = hillColor
			wedge.Material = if temple.Lat > 27 then Enum.Material.Snow else Enum.Material.LeafyGrass
			wedge.Parent = hillFolder
			applyTiledTexture(wedge, Enum.NormalId.Front, hillTex, 32, 32, 0.1)
			applyTiledTexture(wedge, Enum.NormalId.Back, hillTex, 32, 32, 0.1)
		end
	end

	-- Long Climbable Stone Staircase (Padigal) from Foothill Arch (Z = -165) to Summit (Z = -305)
	local startZ = townPos.Z - 165
	local endZ = townPos.Z - 305
	local totalRun = startZ - endZ -- 140 studs of horizontal run
	local totalRise = alt - 2.4
	local numSteps = 72
	local runPerStep = totalRun / numSteps

	-- Foothill Pada Mandapam Welcome Archway at bottom of the hill steps (Z = -162)
	local archBase = Vector3.new(townPos.X, 2.4, startZ + 4)
	for _, px in ipairs({ -9, 9 }) do
		makePart({
			Name = "FoothillArchPillar",
			Size = Vector3.new(3.2, 16, 3.2),
			Position = archBase + Vector3.new(px, 8, 0),
			Color = Color3.fromRGB(220, 200, 170),
			Material = Enum.Material.Limestone,
			Parent = hillFolder,
		})
	end
	local archHeader = makePart({
		Name = "FoothillArchHeader",
		Size = Vector3.new(24, 4.2, 4.0),
		Position = archBase + Vector3.new(0, 17.5, 0),
		Color = temple.PrimaryColor,
		Material = Enum.Material.SmoothPlastic,
		Parent = hillFolder,
	})
	createBanner(
		archHeader,
		"🪜 " .. temple.HillStepsLabel,
		"Ascend " .. tostring(temple.RealStepCount) .. " Sacred Steps for +65 Good Karma & Summit Darshan!",
		temple.PrimaryColor,
		5.5,
		320,
		310,
		72
	)

	-- 72 Wide Granite Padigal Steps with Deepa Stambham Oil Lamps & Mid-Climb Siddhar Mandapam
	for s = 1, numSteps do
		local frac = s / numSteps
		local stepY = 2.4 + totalRise * frac
		local stepZ = startZ - (s - 0.5) * runPerStep

		local stepPart = makePart({
			Name = "PadigalStep_" .. tostring(s),
			Size = Vector3.new(16, 1.5, runPerStep + 0.35),
			Position = Vector3.new(townPos.X, stepY - 0.6, stepZ),
			Color = Color3.fromRGB(188, 180, 170),
			Material = Enum.Material.Granite,
			CanCollide = false, -- Smooth collision ramp handles effortless climbing
			Parent = hillFolder,
		})
		applyTiledTexture(stepPart, Enum.NormalId.Top, TempleConfig.VisualAssets.TempleStepsTex, 16, 6, 0)
		applyTiledTexture(stepPart, Enum.NormalId.Back, TempleConfig.VisualAssets.TempleStepsTex, 16, 4, 0)

		-- Deepa Stambham Oil Lamps every 9 steps
		if s % 9 == 1 or s == numSteps then
			for _, sideX in ipairs({ -9.2, 9.2 }) do
				makePart({
					Name = "StepLampPillar",
					Size = Vector3.new(1.4, 5.0, 1.4),
					Position = Vector3.new(townPos.X + sideX, stepY + 2.5, stepZ),
					Color = Color3.fromRGB(215, 180, 95),
					Material = Enum.Material.Cobblestone,
					Parent = hillFolder,
				})
				local flame = makePart({
					Name = "DeepamFlame",
					Shape = Enum.PartType.Ball,
					Size = Vector3.new(1.3, 1.7, 1.3),
					Position = Vector3.new(townPos.X + sideX, stepY + 5.4, stepZ),
					Color = Color3.fromRGB(255, 190, 55),
					Material = Enum.Material.Neon,
					CanCollide = false,
					Parent = hillFolder,
				})
				local pl = Instance.new("PointLight")
				pl.Color = Color3.fromRGB(255, 195, 90)
				pl.Brightness = 1.5
				pl.Range = 18
				pl.Parent = flame
			end
		end

		-- Mid-Climb Idumban / Siddhar Rest Mandapam halfway up the hill!
		if s == 36 then
			local midRoof = makePart({
				Name = "MidClimbSiddharMandapam",
				Size = Vector3.new(22, 2.0, 14),
				Position = Vector3.new(townPos.X, stepY + 12, stepZ),
				Color = Color3.fromRGB(215, 165, 85),
				Material = Enum.Material.Sandstone,
				Parent = hillFolder,
			})
			for _, px in ipairs({ -9.5, 9.5 }) do
				makePart({
					Name = "MidMandapamPillar",
					Size = Vector3.new(1.8, 12, 1.8),
					Position = Vector3.new(townPos.X + px, stepY + 6, stepZ),
					Color = Color3.fromRGB(185, 175, 160),
					Material = Enum.Material.Granite,
					Parent = hillFolder,
				})
			end
			createBanner(
				midRoof,
				"🕉️ Mid-Climb Siddhar Mandapam",
				"Halfway up " .. temple.Name .. " (" .. tostring(math.floor(temple.RealStepCount * 0.5)) .. " Steps)",
				Color3.fromRGB(255, 215, 110),
				4.0,
				180,
				240,
				54
			)
		end
	end

	-- Invisible Smooth Walkable Staircase Collision Ramp
	local pBottom = Vector3.new(townPos.X, 2.4, startZ)
	local pTop = Vector3.new(townPos.X, alt, endZ)
	local rampLen = (pTop - pBottom).Magnitude
	local rampMid = (pBottom + pTop) * 0.5
	makePart({
		Name = "SmoothWalkableStepsRamp",
		Size = Vector3.new(16.5, 0.8, rampLen),
		CFrame = CFrame.lookAt(rampMid, pTop),
		Transparency = 1,
		CanCollide = true,
		Parent = hillFolder,
	})

	-- Summit Climb Completion Pad (Awards +60/+65 Good Karma when touched!)
	local summitPad = makePart({
		Name = "SummitClimbCompletePad",
		Size = Vector3.new(18, 1.0, 8),
		Position = Vector3.new(townPos.X, alt + 0.3, endZ - 3),
		Color = Color3.fromRGB(255, 215, 75),
		Material = Enum.Material.Neon,
		Transparency = 0.45,
		CanCollide = true,
		Parent = hillFolder,
	})
	summitPad:SetAttribute("TempleId", temple.Id)
	summitPad:SetAttribute("IsHillSummitPad", true)

	-- Hilltop Sanctuary Shrine & Walk-In Garbhagriha atop the Mountain!
	buildSanctuaryShrine(
		hillFolder,
		temple,
		Vector3.new(townPos.X, alt, hillCenter.Z),
		"Summit",
		true
	)
end

-- ============================================================================
-- 5. FULL STREET-LEVEL TEMPLE TOWNS (680 x 680 STUDS PER TEMPLE TOWN)
-- ============================================================================
local function buildTempleTown(templesFolder: Folder, temple: TempleConfig.TempleEntry)
	local tFolder = Instance.new("Folder")
	tFolder.Name = temple.Id
	tFolder.Parent = templesFolder

	local townPos = TempleConfig.latLonToWorld(temple.Lat, temple.Lon, 2.2)
	local townSize = TempleConfig.MapBounds.TownSize -- 680 studs

	-- 5A. 680 x 680 Town Street-Level Ground Canvas
	local townCanvas = makePart({
		Name = "TownStreetCanvas",
		Size = Vector3.new(townSize, 0.6, townSize),
		Position = Vector3.new(townPos.X, 2.1, townPos.Z),
		Color = Color3.fromRGB(165, 152, 132),
		Material = Enum.Material.Concrete,
		Parent = tFolder,
	})
	local townMapAsset = if temple.Lat < 22
		then TempleConfig.VisualAssets.SouthTownStreetMap
		else TempleConfig.VisualAssets.NorthTownStreetMap
	applyPhotoPanel(townCanvas, Enum.NormalId.Top, townMapAsset, 0.45)

	-- 5B. Central Town Temple Complex & Walk-In Garbhagriha (at town center Z = 0)
	buildSanctuaryShrine(
		tFolder,
		temple,
		Vector3.new(townPos.X, 2.4, townPos.Z),
		"TownCenter",
		false
	)

	-- 5C. 4 Concentric Walkable Car Streets (Mada Veedhis) around the Temple Compound (Radius = 150 studs)
	local streetFolder = Instance.new("Folder")
	streetFolder.Name = "MadaVeedhiStreets"
	streetFolder.Parent = tFolder

	local r = 150
	local streetW = 26
	local streetLen = r * 2 + streetW

	local madaStreets = {
		{ name = "SouthMadaVeedhi", pos = Vector3.new(0, 0.35, r), size = Vector3.new(streetLen, 0.3, streetW), u = streetLen, v = streetW },
		{ name = "NorthMadaVeedhi", pos = Vector3.new(0, 0.35, -r), size = Vector3.new(streetLen, 0.3, streetW), u = streetLen, v = streetW },
		{ name = "EastMadaVeedhi", pos = Vector3.new(r, 0.35, 0), size = Vector3.new(streetW, 0.3, streetLen), u = streetW, v = streetLen },
		{ name = "WestMadaVeedhi", pos = Vector3.new(-r, 0.35, 0), size = Vector3.new(streetW, 0.3, streetLen), u = streetW, v = streetLen },
		-- Sannathi Entry Avenue connecting South Mada Veedhi to Temple Gopuram & Outer Railway Ring
		{ name = "SannathiMainAvenue", pos = Vector3.new(0, 0.36, 150), size = Vector3.new(28, 0.3, 210), u = 28, v = 120 },
		-- Foothill Approach Avenue connecting Central Temple to Northern Foothill Steps
		{ name = "FoothillApproachAvenue", pos = Vector3.new(0, 0.36, -105), size = Vector3.new(24, 0.3, 120), u = 24, v = 80 },
	}

	for _, st in ipairs(madaStreets) do
		local stPart = makePart({
			Name = st.name,
			Size = st.size,
			Position = townPos + st.pos,
			Color = Color3.fromRGB(58, 58, 64),
			Material = Enum.Material.Asphalt,
			Parent = streetFolder,
		})
		applyTiledTexture(stPart, Enum.NormalId.Top, TempleConfig.VisualAssets.HighwayRoadTex, 26, 26, 0.04)
	end

	-- 5D. SOUTH MADA VEEDHI (+Z = +150): Main Bazaar, 6 Agraharam Houses, Welcome Arch & Archana Stall
	local bazaarFolder = Instance.new("Folder")
	bazaarFolder.Name = "SouthMadaVeedhiBazaar"
	bazaarFolder.Parent = tFolder

	local houseColors = {
		Color3.fromRGB(235, 185, 95),
		Color3.fromRGB(225, 115, 85),
		Color3.fromRGB(115, 195, 225),
		Color3.fromRGB(240, 215, 145),
		Color3.fromRGB(165, 215, 140),
		Color3.fromRGB(235, 150, 175),
	}
	local houseOffsetsX = { -115, -75, -38, 38, 75, 115 }
	for i, hx in ipairs(houseOffsetsX) do
		local hBase = townPos + Vector3.new(hx, 0, 182)
		-- Agraharam House Body
		makePart({
			Name = "AgraharamHouse_" .. tostring(i),
			Size = Vector3.new(24, 12, 20),
			Position = hBase + Vector3.new(0, 6.2, 0),
			Color = houseColors[i],
			Material = Enum.Material.SmoothPlastic,
			Parent = bazaarFolder,
		})
		-- Traditional Terracotta Tiled Pitched Roof
		makePart({
			Name = "TerracottaRoof_" .. tostring(i),
			Size = Vector3.new(26, 3.2, 22),
			Position = hBase + Vector3.new(0, 13.6, 0),
			Color = Color3.fromRGB(175, 72, 42),
			Material = Enum.Material.Cobblestone,
			Parent = bazaarFolder,
		})
		-- Front Thinnai Verandah & Wooden Columns
		makePart({
			Name = "ThinnaiPorch_" .. tostring(i),
			Size = Vector3.new(24, 1.4, 5),
			Position = hBase + Vector3.new(0, 1.0, -12),
			Color = Color3.fromRGB(215, 200, 180),
			Material = Enum.Material.Limestone,
			Parent = bazaarFolder,
		})
	end

	-- Town Welcome Torana Archway on South Sannathi Street (Z = +205)
	local welcomeArch = makePart({
		Name = "TownWelcomeToranaArch",
		Size = Vector3.new(34, 4.5, 4.0),
		Position = townPos + Vector3.new(0, 18.5, 205),
		Color = temple.PrimaryColor,
		Material = Enum.Material.SmoothPlastic,
		Parent = bazaarFolder,
	})
	for _, px in ipairs({ -14, 14 }) do
		makePart({
			Name = "TownWelcomePillar",
			Size = Vector3.new(3.5, 17, 3.5),
			Position = townPos + Vector3.new(px, 8.8, 205),
			Color = Color3.fromRGB(225, 205, 175),
			Material = Enum.Material.Limestone,
			Parent = bazaarFolder,
		})
	end
	createBanner(
		welcomeArch,
		"🏛️ Welcome to " .. temple.TownName,
		temple.StreetLayoutSummary,
		temple.PrimaryColor,
		5.5,
		420,
		320,
		70
	)

	-- Interactive Flower, Coconut & Vibhuti Archana Bazaar Stall (Z = +128, X = -28)
	local archanaStall = makePart({
		Name = "ArchanaBazaarStall",
		Size = Vector3.new(14, 3.8, 8),
		Position = townPos + Vector3.new(-28, 2.2, 128),
		Color = Color3.fromRGB(215, 130, 55),
		Material = Enum.Material.WoodPlanks,
		Parent = bazaarFolder,
	})
	makePart({
		Name = "ArchanaCanopy",
		Size = Vector3.new(16, 1.2, 10),
		Position = townPos + Vector3.new(-28, 10.5, 128),
		Color = Color3.fromRGB(245, 185, 45),
		Material = Enum.Material.Fabric,
		Parent = bazaarFolder,
	})
	createBanner(
		archanaStall,
		"🌸 Pooja Archana Flower & Coconut Stall",
		"Offer Sacred Jasmine, Lotus & Coconut (+25 Good Karma)",
		Color3.fromRGB(255, 205, 85),
		10.5,
		220,
		250,
		58
	)

	local archanaPrompt = Instance.new("ProximityPrompt")
	archanaPrompt.Name = "ArchanaPrompt"
	archanaPrompt.ObjectText = temple.TownName .. " Flower Bazaar"
	archanaPrompt.ActionText = "🌸 Offer Flower & Coconut Archana (+25 Good Karma)"
	archanaPrompt.HoldDuration = 0.25
	archanaPrompt.MaxActivationDistance = 22
	archanaPrompt.RequiresLineOfSight = false
	archanaPrompt:SetAttribute("TempleId", temple.Id)
	archanaPrompt:SetAttribute("DeedKey", "ArchanaOffering")
	archanaPrompt.Parent = archanaStall

	-- 5E. EAST MADA VEEDHI (+X = +150): Virtual Gurukulam School Pavilion & Annadanam / Go-Shala
	local eastFolder = Instance.new("Folder")
	eastFolder.Name = "EastMadaVeedhiGurukulam"
	eastFolder.Parent = tFolder

	local gradeInfo = TempleConfig.getGradeByNumber(temple.GradeRegion) or TempleConfig.GurukulaGrades[1]
	local schoolPos = townPos + Vector3.new(192, 0.6, -24)

	makePart({
		Name = "TownGurukulamPlinth",
		Size = Vector3.new(42, 1.4, 36),
		Position = schoolPos,
		Color = Color3.fromRGB(195, 165, 120),
		Material = Enum.Material.WoodPlanks,
		Parent = eastFolder,
	})

	local banyanWall = makePart({
		Name = "TownGurukulamBanyanBackdrop",
		Size = Vector3.new(36, 20, 1.8),
		Position = schoolPos + Vector3.new(0, 10.5, -14),
		Color = Color3.fromRGB(235, 225, 200),
		Material = Enum.Material.SmoothPlastic,
		Parent = eastFolder,
	})
	applyPhotoPanel(banyanWall, Enum.NormalId.Front, TempleConfig.VisualAssets.GurukulamBanyan, 0.1)
	applyPhotoPanel(banyanWall, Enum.NormalId.Back, TempleConfig.VisualAssets.GurukulamBanyan, 0.1)

	local studyDesk = makePart({
		Name = "OlaiChuvadiStudyDesk",
		Size = Vector3.new(9, 3.4, 5),
		Position = schoolPos + Vector3.new(0, 2.4, 2),
		Color = Color3.fromRGB(145, 95, 50),
		Material = Enum.Material.Wood,
		Parent = eastFolder,
	})

	local lessonPrompt = Instance.new("ProximityPrompt")
	lessonPrompt.Name = "GurukulaLessonPrompt"
	lessonPrompt.ObjectText = gradeInfo.SchoolTitle
	lessonPrompt.ActionText = "📖 Study Thirukkural & Virtue (+" .. tostring(gradeInfo.KarmaReward) .. " Good Karma)"
	lessonPrompt.HoldDuration = 0.25
	lessonPrompt.MaxActivationDistance = 24
	lessonPrompt.RequiresLineOfSight = false
	lessonPrompt:SetAttribute("GradeNumber", gradeInfo.Grade)
	lessonPrompt.Parent = studyDesk

	createBanner(
		banyanWall,
		"🎓 " .. gradeInfo.SchoolTitle,
		gradeInfo.CoreBook .. " • +" .. tostring(gradeInfo.KarmaReward) .. " Karma",
		Color3.fromRGB(145, 245, 160),
		13.5,
		380,
		280,
		66
	)

	-- Annadanam Chattram & Go-Shala Cow Sanctuary on East Mada Veedhi (+X = +192, Z = +45)
	local annadanamHall = makePart({
		Name = "AnnadanamChattramHall",
		Size = Vector3.new(32, 10, 24),
		Position = townPos + Vector3.new(192, 5.2, 48),
		Color = Color3.fromRGB(240, 220, 185),
		Material = Enum.Material.Limestone,
		Parent = eastFolder,
	})
	createBanner(
		annadanamHall,
		"🍚 Annadanam Chattram & Go-Shala Sanctuary",
		"Feed Pilgrims & Temple Cows (+40 Good Karma)",
		Color3.fromRGB(255, 215, 115),
		8.0,
		260,
		260,
		60
	)

	local annadanamPrompt = Instance.new("ProximityPrompt")
	annadanamPrompt.Name = "AnnadanamPrompt"
	annadanamPrompt.ObjectText = temple.TownName .. " Annadanam & Go-Shala"
	annadanamPrompt.ActionText = "🍚 Perform Annadanam & Go-Seva (+40 Good Karma)"
	annadanamPrompt.HoldDuration = 0.25
	annadanamPrompt.MaxActivationDistance = 24
	annadanamPrompt.RequiresLineOfSight = false
	annadanamPrompt:SetAttribute("TempleId", temple.Id)
	annadanamPrompt:SetAttribute("DeedKey", "AnnadanamSeva")
	annadanamPrompt.Parent = annadanamHall

	-- 5F. WEST MADA VEEDHI (-X = -150): Sacred Pushkarini Temple Tank (90x90 studs) & Neerazhi Mandapam
	local tankFolder = Instance.new("Folder")
	tankFolder.Name = "SacredPushkariniTank"
	tankFolder.Parent = tFolder

	local tankCenter = townPos + Vector3.new(-215, 0, 0)
	-- Stepped Granite Padithurai Walls around the 90x90 Tank
	for step = 1, 3 do
		local sz = 96 - step * 6
		makePart({
			Name = "PushkariniPadithurai_" .. tostring(step),
			Size = Vector3.new(sz, 1.0, sz),
			Position = tankCenter + Vector3.new(0, 2.0 - step * 0.4, 0),
			Color = Color3.fromRGB(190, 182, 170),
			Material = Enum.Material.Granite,
			Parent = tankFolder,
		})
	end

	-- Turquoise Sacred Theertham Water Surface
	local tankWater = makePart({
		Name = "PushkariniSacredWater",
		Size = Vector3.new(76, 1.2, 76),
		Position = tankCenter + Vector3.new(0, 1.2, 0),
		Color = Color3.fromRGB(32, 165, 195),
		Material = Enum.Material.Glass,
		Transparency = 0.18,
		Parent = tankFolder,
	})

	-- Central Neerazhi Mandapam Pavilion in the middle of the Pushkarini Tank
	makePart({
		Name = "NeerazhiMandapamPlinth",
		Size = Vector3.new(18, 4.5, 18),
		Position = tankCenter + Vector3.new(0, 3.5, 0),
		Color = Color3.fromRGB(225, 215, 195),
		Material = Enum.Material.Limestone,
		Parent = tankFolder,
	})
	for _, px in ipairs({ -6.5, 6.5 }) do
		for _, pz in ipairs({ -6.5, 6.5 }) do
			makePart({
				Name = "NeerazhiPillar",
				Size = Vector3.new(1.8, 10, 1.8),
				Position = tankCenter + Vector3.new(px, 10.5, pz),
				Color = Color3.fromRGB(205, 195, 175),
				Material = Enum.Material.Granite,
				Parent = tankFolder,
			})
		end
	end
	local neerazhiCap = makePart({
		Name = "NeerazhiGopuramCap",
		Size = Vector3.new(20, 4.5, 20),
		Position = tankCenter + Vector3.new(0, 17.5, 0),
		Color = temple.PrimaryColor,
		Material = Enum.Material.Sandstone,
		Parent = tankFolder,
	})
	createBanner(
		neerazhiCap,
		"🌊 Sacred Pushkarini Theertham & Neerazhi Mandapam",
		"Take Punya Snanam Holy Dip (+30 Good Karma)",
		Color3.fromRGB(95, 225, 255),
		6.0,
		320,
		280,
		62
	)

	-- Interactive Bathing Ghat Stone Platform on East edge of Tank (facing West Mada Veedhi)
	local ghatPlatform = makePart({
		Name = "PushkariniGhatStepPlatform",
		Size = Vector3.new(12, 2.2, 22),
		Position = tankCenter + Vector3.new(44, 1.6, 0),
		Color = Color3.fromRGB(205, 195, 180),
		Material = Enum.Material.Granite,
		Parent = tankFolder,
	})

	local pushkariniPrompt = Instance.new("ProximityPrompt")
	pushkariniPrompt.Name = "PushkariniPrompt"
	pushkariniPrompt.ObjectText = temple.Name .. " Sacred Pushkarini"
	pushkariniPrompt.ActionText = "🌊 Perform Punya Snanam Sacred Bath (+30 Good Karma)"
	pushkariniPrompt.HoldDuration = 0.25
	pushkariniPrompt.MaxActivationDistance = 26
	pushkariniPrompt.RequiresLineOfSight = false
	pushkariniPrompt:SetAttribute("TempleId", temple.Id)
	pushkariniPrompt:SetAttribute("DeedKey", "PushkariniSnanam")
	pushkariniPrompt.Parent = ghatPlatform
	local _ = tankWater

	-- 5G. OUTER TRANSIT RING (+Z = +265): Railway Station with Vande Bharat Train, Highway Stand & Airport
	local transitFolder = Instance.new("Folder")
	transitFolder.Name = "TownTransitHubs"
	transitFolder.Parent = tFolder

	-- Railway Station Platform & Express Train on South-West Outer Ring (X = -120, Z = +265)
	local railPos = townPos + Vector3.new(-120, 0, 265)
	local railPlatform = makePart({
		Name = "RailwayStationPlatform",
		Size = Vector3.new(96, 2.6, 20),
		Position = railPos + Vector3.new(0, 1.5, 0),
		Color = Color3.fromRGB(185, 180, 172),
		Material = Enum.Material.Concrete,
		Parent = transitFolder,
	})
	local railCanopy = makePart({
		Name = "RailwayStationCanopy",
		Size = Vector3.new(68, 1.8, 16),
		Position = railPos + Vector3.new(0, 13.5, 0),
		Color = Color3.fromRGB(45, 95, 175),
		Material = Enum.Material.Metal,
		Parent = transitFolder,
	})
	createBanner(
		railCanopy,
		"🚆 " .. temple.RailwayStationName,
		"Vande Bharat Express Inter-City Rail Corridor",
		Color3.fromRGB(95, 195, 255),
		5.5,
		360,
		280,
		60
	)
	-- Express Train Coach parked beside the platform
	makePart({
		Name = "VandeBharatExpressCoach",
		Size = Vector3.new(78, 8.5, 10.5),
		Position = railPos + Vector3.new(0, 5.2, 16),
		Color = Color3.fromRGB(240, 245, 255),
		Material = Enum.Material.SmoothPlastic,
		Parent = transitFolder,
	})
	makePart({
		Name = "VandeBharatBlueStripe",
		Size = Vector3.new(78.4, 2.2, 10.8),
		Position = railPos + Vector3.new(0, 6.0, 16),
		Color = Color3.fromRGB(35, 115, 225),
		Material = Enum.Material.SmoothPlastic,
		Parent = transitFolder,
	})
	local _ = railPlatform

	-- National Highway Car & Pilgrim Bus Terminus (X = +95, Z = +265)
	local busStand = makePart({
		Name = "HighwayCarAndBusStand",
		Size = Vector3.new(64, 1.8, 28),
		Position = townPos + Vector3.new(95, 1.2, 265),
		Color = Color3.fromRGB(85, 85, 92),
		Material = Enum.Material.Asphalt,
		Parent = transitFolder,
	})
	createBanner(
		busStand,
		"🚗 " .. temple.RoadHighwayName,
		"National Highway Car & Pilgrim Bus Terminus",
		Color3.fromRGB(255, 205, 75),
		9.5,
		320,
		270,
		58
	)

	-- Regional Airport / Pushpaka Helipad on East Edge (X = +265, Z = +145)
	local helipad = makePart({
		Name = "AirportHelipad",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1.6, 52, 52),
		CFrame = CFrame.new(townPos + Vector3.new(265, 1.2, 145)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(70, 75, 85),
		Material = Enum.Material.Concrete,
		Parent = transitFolder,
	})
	createBanner(
		helipad,
		"✈️ " .. temple.AirportName,
		"All-India Pushpaka Flight & Helicopter Pad",
		Color3.fromRGB(255, 230, 125),
		10.5,
		360,
		270,
		58
	)

	-- 5H. NORTH SIDE (-Z = -165 to -440): Multi-Tiered Natural Mountain & Climbable Padigal Steps!
	buildNaturalMountainAndHillSteps(tFolder, temple, townPos)
end

function WorldBuilder.buildTemples(root: Folder)
	local templesFolder = Instance.new("Folder")
	templesFolder.Name = "DivyaKshetrams"
	templesFolder.Parent = root

	for _, temple in ipairs(TempleConfig.Temples) do
		buildTempleTown(templesFolder, temple)
	end
end

-- ============================================================================
-- 6. STANDALONE REGIONAL VIRTUAL GURUKULAM HEADQUARTERS (GRADES 1 TO 12)
-- ============================================================================
function WorldBuilder.buildGurukulaSchools(root: Folder)
	local schoolFolder = Instance.new("Folder")
	schoolFolder.Name = "VirtualGurukulamSchools"
	schoolFolder.Parent = root

	for _, gradeInfo in ipairs(TempleConfig.GurukulaGrades) do
		local gFolder = Instance.new("Folder")
		gFolder.Name = "Grade_" .. tostring(gradeInfo.Grade)
		gFolder.Parent = schoolFolder

		-- Placed on East Mada Veedhi of the headquarters region
		local pos = TempleConfig.latLonToWorld(gradeInfo.Lat, gradeInfo.Lon, 2.5) + Vector3.new(192, 0.5, 115)

		makePart({
			Name = "GurukulamPlatform",
			Size = Vector3.new(36, 1.4, 30),
			Position = pos,
			Color = Color3.fromRGB(195, 165, 120),
			Material = Enum.Material.WoodPlanks,
			Parent = gFolder,
		})

		local banyanScreen = makePart({
			Name = "GurukulamBanyanBackdrop",
			Size = Vector3.new(32, 18, 1.6),
			Position = pos + Vector3.new(0, 9.5, -11),
			Color = Color3.fromRGB(235, 225, 200),
			Material = Enum.Material.SmoothPlastic,
			Parent = gFolder,
		})
		applyPhotoPanel(banyanScreen, Enum.NormalId.Back, TempleConfig.VisualAssets.GurukulamBanyan, 0.1)
		applyPhotoPanel(banyanScreen, Enum.NormalId.Front, TempleConfig.VisualAssets.GurukulamBanyan, 0.1)

		local studyDesk = makePart({
			Name = "GurukulamStudyDesk",
			Size = Vector3.new(8, 3.4, 4.5),
			Position = pos + Vector3.new(0, 2.4, 0),
			Color = Color3.fromRGB(145, 95, 50),
			Material = Enum.Material.Wood,
			Parent = gFolder,
		})

		local lessonPrompt = Instance.new("ProximityPrompt")
		lessonPrompt.Name = "GurukulaLessonPrompt"
		lessonPrompt.ObjectText = gradeInfo.SchoolTitle
		lessonPrompt.ActionText = "📖 Study Thirukkural & Virtue (+" .. tostring(gradeInfo.KarmaReward) .. " Good Karma)"
		lessonPrompt.HoldDuration = 0.25
		lessonPrompt.MaxActivationDistance = 24
		lessonPrompt.RequiresLineOfSight = false
		lessonPrompt:SetAttribute("GradeNumber", gradeInfo.Grade)
		lessonPrompt.Parent = studyDesk

		createBanner(
			banyanScreen,
			"🎓 " .. gradeInfo.SchoolTitle,
			gradeInfo.CoreBook .. " • +" .. tostring(gradeInfo.KarmaReward) .. " Karma",
			Color3.fromRGB(130, 235, 145),
			12.5,
			460,
			280,
			66
		)
	end
end

-- ============================================================================
-- 7. SPAWN LOCATION ON SOUTH MADA VEEDHI (SANNATHI BAZAAR STREET) OF GRADE 1
-- ============================================================================
function WorldBuilder.buildSpawn(root: Folder)
	local existingSpawn = Workspace:FindFirstChildOfClass("SpawnLocation")
	if existingSpawn then
		existingSpawn:Destroy()
	end

	local startTemple = TempleConfig.getTempleById("thirupparamkunram") or TempleConfig.Temples[1]
	local townCenter = TempleConfig.latLonToWorld(startTemple.Lat, startTemple.Lon, 2.4)
	local spawnPos = townCenter + Vector3.new(0, 0.6, 185)

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "BharatavarshaSpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(22, 1.2, 22)
	-- Face North (-Z) straight down Sannathi Bazaar Street toward the Raja Gopuram, Foothill Arch & Hill Steps!
	spawn.CFrame = CFrame.lookAt(spawnPos, Vector3.new(townCenter.X, spawnPos.Y, townCenter.Z))
	spawn.Color = Color3.fromRGB(245, 200, 85)
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.Parent = root
	applyTiledTexture(spawn, Enum.NormalId.Top, TempleConfig.VisualAssets.TempleStepsTex, 22, 22, 0.15)
	local _ = ALL_BOX_FACES
end

function WorldBuilder.buildAll()
	WorldBuilder.setupLighting()

	local existing = Workspace:FindFirstChild("GuruKulaDesamWorld")
	if existing then
		existing:Destroy()
	end

	local worldRoot = Instance.new("Folder")
	worldRoot.Name = "GuruKulaDesamWorld"
	worldRoot.Parent = Workspace

	WorldBuilder.buildContinent(worldRoot)
	WorldBuilder.buildHighways(worldRoot)
	WorldBuilder.buildTemples(worldRoot)
	WorldBuilder.buildGurukulaSchools(worldRoot)
	WorldBuilder.buildSpawn(worldRoot)
end

return WorldBuilder
