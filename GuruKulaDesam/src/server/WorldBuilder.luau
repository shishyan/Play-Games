--!strict
--[[
	WorldBuilder.luau
	Guru Kula Desam — Image-Driven WGT-Style Realistic Bharatavarsha Builder
	- Projects the satellite relief map of India onto the continent terrain
	- Builds walkable National Highways tiled with real Indian highway asphalt textures
	- Builds organic hills with climbable stone steps (Padigal) tiled with real granite step textures
	- Uses real 8K temple photographs (Exterior & Walk-in Garbhagriha Sanctum) at all 18 Kshetrams
	- Builds the 12 Regional Virtual Gurukulam Schools (Grades 1 to 12) with Banyan tree backdrops
]]

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local TempleConfig = require(Shared:WaitForChild("TempleConfig"))

local WorldBuilder = {}

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
	-- Both SurfaceGui ImageLabel (crisp, self-illuminated) and Decal fallback
	local decal = Instance.new("Decal")
	decal.Face = face
	decal.Texture = imageId
	decal.Parent = part

	local sgui = Instance.new("SurfaceGui")
	sgui.Face = face
	sgui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sgui.PixelsPerStud = 32
	sgui.LightInfluence = lightInfluence or 0.2
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

local function applyTiledTexture(part: BasePart, face: Enum.NormalId, imageId: string, uTile: number, vTile: number, transparency: number?)
	local tex = Instance.new("Texture")
	tex.Face = face
	tex.Texture = imageId
	tex.StudsPerTileU = uTile
	tex.StudsPerTileV = vTile
	tex.Transparency = transparency or 0
	tex.Parent = part
end

function WorldBuilder.setupLighting()
	Lighting.ClockTime = 8.2 -- Golden morning temple dawn across India
	Lighting.GeographicLatitude = 15
	Lighting.Brightness = 2.6
	Lighting.Ambient = Color3.fromRGB(115, 110, 105)
	Lighting.OutdoorAmbient = Color3.fromRGB(165, 155, 140)
	Lighting.ColorShift_Top = Color3.fromRGB(255, 235, 200)

	for _, child in ipairs(Lighting:GetChildren()) do
		if child:IsA("PostEffect") or child:IsA("Atmosphere") or child:IsA("Sky") then
			child:Destroy()
		end
	end

	local atmo = Instance.new("Atmosphere")
	atmo.Density = 0.24
	atmo.Offset = 0.15
	atmo.Color = Color3.fromRGB(220, 235, 255)
	atmo.Decay = Color3.fromRGB(255, 215, 175)
	atmo.Glare = 0.15
	atmo.Haze = 1.2
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
-- 1. SATELLITE IMAGE-DRIVEN CONTINENT OF INDIA & SRI LANKA
-- ============================================================================
function WorldBuilder.buildContinent(root: Folder)
	local mapFolder = Instance.new("Folder")
	mapFolder.Name = "BharatavarshaMap"
	mapFolder.Parent = root

	-- Deep Indian Ocean Surrounding Base
	makePart({
		Name = "IndianOceanFloor",
		Size = Vector3.new(1600, 4, 1800),
		Position = Vector3.new(0, -3.2, 0),
		Color = Color3.fromRGB(18, 82, 118),
		Material = Enum.Material.Glass,
		Transparency = 0.15,
		Parent = mapFolder,
	})

	-- Main Image-Driven Satellite Continent Canvas of India (640 x 960 studs)
	local continentCanvas = makePart({
		Name = "IndiaSatelliteContinent",
		Size = Vector3.new(TempleConfig.MapBounds.WorldWidth, 4, TempleConfig.MapBounds.WorldLength),
		Position = Vector3.new(0, 0, 0),
		Color = Color3.fromRGB(92, 132, 76),
		Material = Enum.Material.SmoothPlastic,
		Parent = mapFolder,
	})

	-- Project the high-resolution India Satellite Relief Map directly onto the top face!
	local mapDecal = Instance.new("Decal")
	mapDecal.Name = "SatelliteReliefDecal"
	mapDecal.Face = Enum.NormalId.Top
	mapDecal.Texture = TempleConfig.VisualAssets.IndiaReliefMap
	mapDecal.Parent = continentCanvas

	local mapGui = Instance.new("SurfaceGui")
	mapGui.Name = "SatelliteReliefSurfaceGui"
	mapGui.Face = Enum.NormalId.Top
	mapGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	mapGui.PixelsPerStud = 16
	mapGui.LightInfluence = 0.35
	mapGui.Brightness = 1.05
	mapGui.Parent = continentCanvas

	local mapImg = Instance.new("ImageLabel")
	mapImg.Size = UDim2.fromScale(1, 1)
	mapImg.BackgroundTransparency = 1
	mapImg.Image = TempleConfig.VisualAssets.IndiaReliefMap
	mapImg.ScaleType = Enum.ScaleType.Stretch
	mapImg.Parent = mapGui

	-- Majestic Himalayan Snow Wall backdrop along the northern frontier (Z = -480)
	local himalayaBackdrop = makePart({
		Name = "HimalayanPanoramaWall",
		Size = Vector3.new(640, 140, 8),
		Position = Vector3.new(0, 70, -482),
		Color = Color3.fromRGB(225, 238, 255),
		Material = Enum.Material.SmoothPlastic,
		Parent = mapFolder,
	})
	applyPhotoPanel(himalayaBackdrop, Enum.NormalId.South, TempleConfig.VisualAssets.HimalayaKedarnath, 0.15)
end

-- ============================================================================
-- 2. WALKABLE IMAGE-TEXTURED NATIONAL HIGHWAYS & PILGRIMAGE ROADS
-- ============================================================================
function WorldBuilder.buildHighways(root: Folder)
	local roadFolder = Instance.new("Folder")
	roadFolder.Name = "NationalHighways"
	roadFolder.Parent = root

	for idx, route in ipairs(TempleConfig.PilgrimageRoutes) do
		local tFrom = TempleConfig.getTempleById(route.From)
		local tTo = TempleConfig.getTempleById(route.To)
		if tFrom and tTo then
			local p1 = TempleConfig.latLonToWorld(tFrom.Lat, tFrom.Lon, 2.12)
			local p2 = TempleConfig.latLonToWorld(tTo.Lat, tTo.Lon, 2.12)
			local delta = p2 - p1
			local dist = Vector3.new(delta.X, 0, delta.Z).Magnitude
			local mid = (p1 + p2) * 0.5

			-- 14-stud wide walkable road segment flush with the continent surface
			local roadSeg = makePart({
				Name = "Highway_" .. idx .. "_" .. route.From .. "_to_" .. route.To,
				Size = Vector3.new(14, 0.35, dist),
				CFrame = CFrame.lookAt(mid, Vector3.new(p2.X, mid.Y, p2.Z)),
				Color = if route.Type == "SeaBridge" then Color3.fromRGB(185, 175, 155) else Color3.fromRGB(68, 68, 72),
				Material = Enum.Material.Asphalt,
				CanCollide = true,
				Parent = roadFolder,
			})

			-- Tile the real Indian National Highway photographic texture along the road!
			applyTiledTexture(
				roadSeg,
				Enum.NormalId.Top,
				TempleConfig.VisualAssets.HighwayRoadTex,
				14,
				28,
				0.02
			)

			-- Highway Milestone (Maiyakkal) at the midpoint of each National Highway
			local milestone = makePart({
				Name = "Milestone_" .. idx,
				Size = Vector3.new(2.2, 4.2, 1.2),
				Position = mid + Vector3.new(8.5, 2.1, 0),
				Color = Color3.fromRGB(245, 240, 225),
				Material = Enum.Material.Limestone,
				Parent = roadFolder,
			})
			makePart({
				Name = "MilestoneCap",
				Size = Vector3.new(2.3, 1.1, 1.3),
				Position = milestone.Position + Vector3.new(0, 2.4, 0),
				Color = Color3.fromRGB(245, 195, 45),
				Material = Enum.Material.SmoothPlastic,
				Parent = roadFolder,
			})

			local bbg = Instance.new("BillboardGui")
			bbg.Size = UDim2.fromOffset(180, 42)
			bbg.StudsOffset = Vector3.new(0, 4.5, 0)
			bbg.MaxDistance = 95
			bbg.Parent = milestone

			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.fromScale(1, 1)
			lbl.BackgroundColor3 = Color3.fromRGB(25, 35, 25)
			lbl.BackgroundTransparency = 0.2
			lbl.TextColor3 = Color3.fromRGB(255, 230, 130)
			lbl.Font = Enum.Font.GothamBold
			lbl.TextScaled = true
			lbl.Text = "🛣️ " .. route.Name
			lbl.Parent = bbg
			Instance.new("UICorner", lbl).CornerRadius = UDim.new(0, 6)
		end
	end
end

-- ============================================================================
-- 3. IMAGE-DRIVEN TEMPLE HILLS, CLIMBABLE STONE STEPS (PADIGAL) & SANCTUARIES
-- ============================================================================
local function buildNaturalHillAndClimbableSteps(templeFolder: Folder, temple: TempleConfig.TempleEntry, basePos: Vector3)
	local alt = temple.Altitude
	local hillTex = if temple.Lat > 27 then TempleConfig.VisualAssets.HimalayaKedarnath else TempleConfig.VisualAssets.WesternGhatsHill
	local hillColor = if temple.Lat > 27 then Color3.fromRGB(205, 220, 235) else Color3.fromRGB(108, 125, 88)

	-- Multi-tiered sloped mountain mass (using WedgeParts & terraced slopes so it looks like a natural hill, NOT a block!)
	local tiers = 4
	for tier = 1, tiers do
		local frac = (tier - 1) / tiers
		local nextFrac = tier / tiers
		local tierY0 = 2 + (alt - 2) * frac
		local tierH = (alt - 2) / tiers
		local radius = 34 * (1 - frac * 0.48)

		local tierCore = makePart({
			Name = "HillTier_" .. tier,
			Size = Vector3.new(radius * 2, tierH, radius * 2),
			Position = Vector3.new(basePos.X, tierY0 + tierH * 0.5, basePos.Z),
			Color = hillColor,
			Material = if temple.Lat > 27 then Enum.Material.Glacier else Enum.Material.Rock,
			Parent = templeFolder,
		})
		for _, face in ipairs({ Enum.NormalId.North, Enum.NormalId.South, Enum.NormalId.East, Enum.NormalId.West, Enum.NormalId.Top }) do
			applyTiledTexture(tierCore, face, hillTex, 28, 28, 0.08)
		end

		-- Sloped natural mountain skirts on all 4 sides using WedgeParts
		local skirtOffsets = {
			{ pos = Vector3.new(0, 0, radius + 6), rot = Vector3.new(0, 0, 0), sx = radius * 1.8, sz = 12 },
			{ pos = Vector3.new(0, 0, -(radius + 6)), rot = Vector3.new(0, 180, 0), sx = radius * 1.8, sz = 12 },
			{ pos = Vector3.new(radius + 6, 0, 0), rot = Vector3.new(0, 90, 0), sx = radius * 1.8, sz = 12 },
			{ pos = Vector3.new(-(radius + 6), 0, 0), rot = Vector3.new(0, -90, 0), sx = radius * 1.8, sz = 12 },
		}
		for sIdx, sk in ipairs(skirtOffsets) do
			local wedge = Instance.new("WedgePart")
			wedge.Name = "HillSlope_" .. tier .. "_" .. sIdx
			wedge.Anchored = true
			wedge.Size = Vector3.new(sk.sx, tierH, sk.sz)
			wedge.CFrame = CFrame.new(basePos.X + sk.pos.X, tierY0 + tierH * 0.5, basePos.Z + sk.pos.Z)
				* CFrame.Angles(0, math.rad(sk.rot.Y), 0)
			wedge.Color = hillColor
			wedge.Material = if temple.Lat > 27 then Enum.Material.Snow else Enum.Material.LeafyGrass
			wedge.Parent = templeFolder
			applyTiledTexture(wedge, Enum.NormalId.Front, hillTex, 24, 24, 0.1)
		end
		local _ = nextFrac
	end

	-- CLIMBABLE SACRED STONE STEPS (PADIGAL) leading from the Southern Foothill Arch up to the Summit!
	local totalRise = alt - 2
	local numSteps = math.clamp(math.floor(totalRise / 1.0), 12, 68)
	local runPerStep = 1.65
	local totalRun = numSteps * runPerStep
	local startZ = basePos.Z + 28 + totalRun
	local endZ = basePos.Z + 28

	-- Foothill Pada Mandapam Archway at the bottom of the hill steps
	local archBase = Vector3.new(basePos.X, 2, startZ + 4)
	makePart({
		Name = "FoothillPillarL",
		Size = Vector3.new(2.2, 12, 2.2),
		Position = archBase + Vector3.new(-6.5, 6, 0),
		Color = Color3.fromRGB(215, 195, 165),
		Material = Enum.Material.Limestone,
		Parent = templeFolder,
	})
	makePart({
		Name = "FoothillPillarR",
		Size = Vector3.new(2.2, 12, 2.2),
		Position = archBase + Vector3.new(6.5, 6, 0),
		Color = Color3.fromRGB(215, 195, 165),
		Material = Enum.Material.Limestone,
		Parent = templeFolder,
	})
	local archHeader = makePart({
		Name = "FoothillArchHeader",
		Size = Vector3.new(16, 3.2, 2.8),
		Position = archBase + Vector3.new(0, 13.2, 0),
		Color = temple.PrimaryColor,
		Material = Enum.Material.SmoothPlastic,
		Parent = templeFolder,
	})

	local archGui = Instance.new("BillboardGui")
	archGui.Size = UDim2.fromOffset(260, 64)
	archGui.StudsOffset = Vector3.new(0, 4.2, 0)
	archGui.MaxDistance = 140
	archGui.Parent = archHeader

	local archLabel = Instance.new("TextLabel")
	archLabel.Size = UDim2.fromScale(1, 1)
	archLabel.BackgroundColor3 = Color3.fromRGB(28, 20, 14)
	archLabel.BackgroundTransparency = 0.12
	archLabel.TextColor3 = Color3.fromRGB(255, 225, 120)
	archLabel.Font = Enum.Font.GothamBold
	archLabel.TextScaled = true
	archLabel.Text = "🪜 " .. temple.HillStepsLabel .. "\nWalk Up Steps for +60 Good Karma!"
	archLabel.Parent = archGui
	Instance.new("UICorner", archLabel).CornerRadius = UDim.new(0, 8)

	-- Visual Granite Steps (Padigal) with real uploaded TempleStepsTex (Vibhuti, Turmeric & Kumkum!)
	for s = 1, numSteps do
		local frac = s / numSteps
		local stepY = 2 + totalRise * frac
		local stepZ = startZ - (s - 0.5) * runPerStep
		local stepPart = makePart({
			Name = "PadigalStep_" .. s,
			Size = Vector3.new(12, 1.2, runPerStep + 0.2),
			Position = Vector3.new(basePos.X, stepY - 0.5, stepZ),
			Color = Color3.fromRGB(185, 178, 168),
			Material = Enum.Material.Granite,
			CanCollide = false, -- Smooth collision ramp handles effortless walking
			Parent = templeFolder,
		})
		applyTiledTexture(stepPart, Enum.NormalId.Top, TempleConfig.VisualAssets.TempleStepsTex, 12, 6, 0)
		applyTiledTexture(stepPart, Enum.NormalId.South, TempleConfig.VisualAssets.TempleStepsTex, 12, 4, 0)

		-- Sacred Deepa Stambham Oil Lamps & Stone Balustrades every 8 steps
		if s % 8 == 1 or s == numSteps then
			for _, side in ipairs({ -6.6, 6.6 }) do
				makePart({
					Name = "StepLampPillar",
					Size = Vector3.new(1.1, 4.2, 1.1),
					Position = Vector3.new(basePos.X + side, stepY + 2.1, stepZ),
					Color = Color3.fromRGB(215, 180, 95),
					Material = Enum.Material.Cobblestone,
					Parent = templeFolder,
				})
				local flame = makePart({
					Name = "DeepamFlame",
					Shape = Enum.PartType.Ball,
					Size = Vector3.new(1.1, 1.5, 1.1),
					Position = Vector3.new(basePos.X + side, stepY + 4.5, stepZ),
					Color = Color3.fromRGB(255, 190, 55),
					Material = Enum.Material.Neon,
					CanCollide = false,
					Parent = templeFolder,
				})
				local pl = Instance.new("PointLight")
				pl.Color = Color3.fromRGB(255, 195, 90)
				pl.Brightness = 1.4
				pl.Range = 16
				pl.Parent = flame
			end
		end
	end

	-- Smooth Walkable Staircase Collision Ramp so players walk right up the hill steps smoothly!
	local pBottom = Vector3.new(basePos.X, 2, startZ)
	local pTop = Vector3.new(basePos.X, alt, endZ)
	local rampLen = (pTop - pBottom).Magnitude
	local rampMid = (pBottom + pTop) * 0.5
	makePart({
		Name = "SmoothWalkableStepsRamp",
		Size = Vector3.new(12.5, 0.6, rampLen),
		CFrame = CFrame.lookAt(rampMid, pTop),
		Transparency = 1,
		CanCollide = true,
		Parent = templeFolder,
	})

	-- Summit Step Completion Pad (Awards +60 Good Karma when player climbs the hill steps!)
	local summitPad = makePart({
		Name = "SummitClimbCompletePad",
		Size = Vector3.new(14, 0.8, 6),
		Position = Vector3.new(basePos.X, alt + 0.2, endZ - 2),
		Color = Color3.fromRGB(255, 215, 75),
		Material = Enum.Material.Neon,
		Transparency = 0.55,
		CanCollide = true,
		Parent = templeFolder,
	})
	summitPad:SetAttribute("TempleId", temple.Id)
	summitPad:SetAttribute("IsHillSummitPad", true)
end

function WorldBuilder.buildTemples(root: Folder)
	local templesFolder = Instance.new("Folder")
	templesFolder.Name = "DivyaKshetrams"
	templesFolder.Parent = root

	for _, temple in ipairs(TempleConfig.Temples) do
		local tFolder = Instance.new("Folder")
		tFolder.Name = temple.Id
		tFolder.Parent = templesFolder

		local pos = TempleConfig.latLonToWorld(temple.Lat, temple.Lon, temple.Altitude)

		-- If this is a Hill/Mountain Temple, build the natural sloped mountain & climbable stone Padigal steps!
		if temple.Altitude > 6 then
			buildNaturalHillAndClimbableSteps(tFolder, temple, pos)
		else
			-- Low coastal/river temple plinth with 5-8 sacred stone steps
			local plinth = makePart({
				Name = "TemplePlinth",
				Size = Vector3.new(54, temple.Altitude, 54),
				Position = Vector3.new(pos.X, 2 + temple.Altitude * 0.5, pos.Z),
				Color = Color3.fromRGB(205, 195, 175),
				Material = Enum.Material.Limestone,
				Parent = tFolder,
			})
			applyTiledTexture(plinth, Enum.NormalId.Top, TempleConfig.VisualAssets.TempleStepsTex, 18, 18, 0.1)

			-- Entry steps ramp
			local stepRamp = makePart({
				Name = "PlinthSteps",
				Size = Vector3.new(12, 1.2, 10),
				CFrame = CFrame.lookAt(
					Vector3.new(pos.X, 2 + temple.Altitude * 0.5, pos.Z + 30),
					Vector3.new(pos.X, 2 + temple.Altitude, pos.Z + 26)
				),
				Color = Color3.fromRGB(190, 182, 170),
				Material = Enum.Material.Granite,
				Parent = tFolder,
			})
			applyTiledTexture(stepRamp, Enum.NormalId.Top, TempleConfig.VisualAssets.TempleStepsTex, 12, 5, 0)
		end

		local sanctumY = math.max(2, temple.Altitude)

		-- Sacred Temple Courtyard Platform (Prakaram)
		local courtyard = makePart({
			Name = "SanctuaryCourtyard",
			Size = Vector3.new(48, 1.2, 48),
			Position = Vector3.new(pos.X, sanctumY + 0.6, pos.Z),
			Color = Color3.fromRGB(215, 205, 188),
			Material = Enum.Material.Cobblestone,
			Parent = tFolder,
		})
		applyTiledTexture(courtyard, Enum.NormalId.Top, TempleConfig.VisualAssets.TempleStepsTex, 24, 24, 0.25)

		-- ====================================================================
		-- WGT IMAGE-DRIVEN TEMPLE EXTERIOR PANORAMA BILLBOARD WALL
		-- Shows the real 8K photograph of the temple exterior in the 3D world!
		-- ====================================================================
		local exteriorWall = makePart({
			Name = "PhotorealisticTempleExterior",
			Size = Vector3.new(38, 24, 2.2),
			Position = Vector3.new(pos.X, sanctumY + 13.2, pos.Z - 16),
			Color = Color3.fromRGB(245, 235, 215),
			Material = Enum.Material.SmoothPlastic,
			Parent = tFolder,
		})
		applyPhotoPanel(exteriorWall, Enum.NormalId.South, temple.ExteriorImageId, 0.12)
		applyPhotoPanel(exteriorWall, Enum.NormalId.North, temple.ExteriorImageId, 0.12)

		-- Ornamental Golden Gopuram Crown Frame atop the Exterior Panorama
		makePart({
			Name = "GopuramGoldenCrown",
			Size = Vector3.new(40, 2.6, 3.2),
			Position = Vector3.new(pos.X, sanctumY + 26.2, pos.Z - 16),
			Color = temple.PrimaryColor,
			Material = Enum.Material.Foil,
			Parent = tFolder,
		})

		-- ====================================================================
		-- WALK-IN PHOTOREALISTIC GARBHAGRIHA (INNER SANCTUM DARSHAN SHRINE)
		-- Players walk right inside the sanctum to behold the real Deity Image!
		-- ====================================================================
		local garbhagrihaBackdrop = makePart({
			Name = "GarbhagrihaSanctumImage",
			Size = Vector3.new(18, 14, 1.5),
			Position = Vector3.new(pos.X, sanctumY + 8.2, pos.Z - 4),
			Color = Color3.fromRGB(255, 235, 190),
			Material = Enum.Material.SmoothPlastic,
			Parent = tFolder,
		})
		applyPhotoPanel(garbhagrihaBackdrop, Enum.NormalId.South, temple.SanctumImageId, 0.05)

		-- Sanctum Side Pillars & Canopy Roof framing the Inner Sanctum Image
		for _, sx in ipairs({ -9.8, 9.8 }) do
			makePart({
				Name = "SanctumPillar",
				Size = Vector3.new(2.2, 14.5, 6),
				Position = Vector3.new(pos.X + sx, sanctumY + 8.4, pos.Z - 2),
				Color = Color3.fromRGB(165, 152, 135),
				Material = Enum.Material.Granite,
				Parent = tFolder,
			})
		end
		makePart({
			Name = "SanctumRoofMandapam",
			Size = Vector3.new(22, 2.0, 9),
			Position = Vector3.new(pos.X, sanctumY + 16.2, pos.Z - 2),
			Color = Color3.fromRGB(215, 175, 85),
			Material = Enum.Material.Sandstone,
			Parent = tFolder,
		})

		-- Warm Garbhagriha Oil Lamp Glow
		local sanctumLightPart = makePart({
			Name = "GarbhagrihaAartiLamp",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(1.8, 1.8, 1.8),
			Position = Vector3.new(pos.X, sanctumY + 4.5, pos.Z + 1.5),
			Color = Color3.fromRGB(255, 195, 65),
			Material = Enum.Material.Neon,
			CanCollide = false,
			Parent = tFolder,
		})
		local sLight = Instance.new("PointLight")
		sLight.Color = Color3.fromRGB(255, 200, 95)
		sLight.Brightness = 2.4
		sLight.Range = 28
		sLight.Parent = sanctumLightPart

		-- Interactive Darshan & Boon Prompt inside the Garbhagriha
		local darshanPrompt = Instance.new("ProximityPrompt")
		darshanPrompt.Name = "DarshanPrompt"
		darshanPrompt.ObjectText = temple.Name .. " (" .. temple.DeityTitle .. ")"
		darshanPrompt.ActionText = "🙏 Perform Darshan & Receive Boon (+" .. tostring(temple.KarmaReward) .. " Karma)"
		darshanPrompt.HoldDuration = 0.3
		darshanPrompt.MaxActivationDistance = 24
		darshanPrompt.RequiresLineOfSight = false
		darshanPrompt:SetAttribute("TempleId", temple.Id)
		darshanPrompt.Parent = sanctumLightPart

		-- Floating Sky Beacon Banner for each Divya Kshetram
		local beacon = Instance.new("BillboardGui")
		beacon.Name = "TempleSkyBeacon"
		beacon.Size = UDim2.fromOffset(300, 82)
		beacon.StudsOffset = Vector3.new(0, 18, 0)
		beacon.AlwaysOnTop = true
		beacon.MaxDistance = 650
		beacon.Parent = exteriorWall

		local bFrame = Instance.new("Frame")
		bFrame.Size = UDim2.fromScale(1, 1)
		bFrame.BackgroundColor3 = Color3.fromRGB(20, 16, 12)
		bFrame.BackgroundTransparency = 0.15
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
-- 4. THE 12 VIRTUAL GURUKULAM SCHOOL CAMPUSES (GRADES 1 TO 12)
-- ============================================================================
function WorldBuilder.buildGurukulaSchools(root: Folder)
	local schoolFolder = Instance.new("Folder")
	schoolFolder.Name = "VirtualGurukulamSchools"
	schoolFolder.Parent = root

	for _, gradeInfo in ipairs(TempleConfig.GurukulaGrades) do
		local gFolder = Instance.new("Folder")
		gFolder.Name = "Grade_" .. tostring(gradeInfo.Grade)
		gFolder.Parent = schoolFolder

		-- Offset slightly east of the region center so it sits cleanly beside the regional temples
		local pos = TempleConfig.latLonToWorld(gradeInfo.Lat, gradeInfo.Lon, 2.5) + Vector3.new(34, 0, 18)

		-- Sacred Banyan Gurukulam Plinth
		makePart({
			Name = "GurukulamPlatform",
			Size = Vector3.new(28, 1.2, 24),
			Position = pos,
			Color = Color3.fromRGB(195, 165, 120),
			Material = Enum.Material.WoodPlanks,
			Parent = gFolder,
		})

		-- Photorealistic Banyan Gurukulam Backdrop Wall
		local banyanScreen = makePart({
			Name = "GurukulamBanyanBackdrop",
			Size = Vector3.new(24, 15, 1.5),
			Position = pos + Vector3.new(0, 8.1, -9),
			Color = Color3.fromRGB(235, 225, 200),
			Material = Enum.Material.SmoothPlastic,
			Parent = gFolder,
		})
		applyPhotoPanel(banyanScreen, Enum.NormalId.South, TempleConfig.VisualAssets.GurukulamBanyan, 0.1)
		applyPhotoPanel(banyanScreen, Enum.NormalId.North, TempleConfig.VisualAssets.GurukulamBanyan, 0.1)

		-- Interactive Olai Chuvadi (Palm-Leaf) Study Desk
		local studyDesk = makePart({
			Name = "GurukulamStudyDesk",
			Size = Vector3.new(6, 3.2, 4),
			Position = pos + Vector3.new(0, 2.2, 0),
			Color = Color3.fromRGB(145, 95, 50),
			Material = Enum.Material.Wood,
			Parent = gFolder,
		})

		local lessonPrompt = Instance.new("ProximityPrompt")
		lessonPrompt.Name = "GurukulaLessonPrompt"
		lessonPrompt.ObjectText = gradeInfo.SchoolTitle
		lessonPrompt.ActionText = "📖 Study Thirukkural & Virtue (+" .. tostring(gradeInfo.KarmaReward) .. " Good Karma)"
		lessonPrompt.HoldDuration = 0.25
		lessonPrompt.MaxActivationDistance = 22
		lessonPrompt.RequiresLineOfSight = false
		lessonPrompt:SetAttribute("GradeNumber", gradeInfo.Grade)
		lessonPrompt.Parent = studyDesk

		-- Floating School Grade Banner
		local gGui = Instance.new("BillboardGui")
		gGui.Size = UDim2.fromOffset(260, 66)
		gGui.StudsOffset = Vector3.new(0, 11, 0)
		gGui.AlwaysOnTop = true
		gGui.MaxDistance = 420
		gGui.Parent = banyanScreen

		local gFrame = Instance.new("Frame")
		gFrame.Size = UDim2.fromScale(1, 1)
		gFrame.BackgroundColor3 = Color3.fromRGB(22, 38, 26)
		gFrame.BackgroundTransparency = 0.15
		gFrame.Parent = gGui
		Instance.new("UICorner", gFrame).CornerRadius = UDim.new(0, 8)

		local gStroke = Instance.new("UIStroke")
		gStroke.Color = Color3.fromRGB(130, 235, 145)
		gStroke.Thickness = 2
		gStroke.Parent = gFrame

		local gTitle = Instance.new("TextLabel")
		gTitle.Size = UDim2.new(1, -10, 0.55, 0)
		gTitle.Position = UDim2.fromOffset(5, 2)
		gTitle.BackgroundTransparency = 1
		gTitle.TextColor3 = Color3.fromRGB(155, 255, 165)
		gTitle.Font = Enum.Font.GothamBold
		gTitle.TextScaled = true
		gTitle.Text = "🎓 " .. gradeInfo.SchoolTitle
		gTitle.Parent = gFrame

		local gSub = Instance.new("TextLabel")
		gSub.Size = UDim2.new(1, -10, 0.40, 0)
		gSub.Position = UDim2.new(0, 5, 0.55, 0)
		gSub.BackgroundTransparency = 1
		gSub.TextColor3 = Color3.fromRGB(240, 245, 225)
		gSub.Font = Enum.Font.GothamMedium
		gSub.TextScaled = true
		gSub.Text = gradeInfo.CoreBook .. " • +" .. tostring(gradeInfo.KarmaReward) .. " Karma"
		gSub.Parent = gFrame
	end
end

-- ============================================================================
-- 5. SPAWN LOCATION AT GRADE 1 (MADURAI / THIRUPPARAMKUNRAM FOOTHILLS)
-- ============================================================================
function WorldBuilder.buildSpawn(root: Folder)
	local existingSpawn = Workspace:FindFirstChildOfClass("SpawnLocation")
	if existingSpawn then
		existingSpawn:Destroy()
	end

	local g1 = TempleConfig.GurukulaGrades[1]
	local spawnPos = TempleConfig.latLonToWorld(g1.Lat, g1.Lon, 2.6) + Vector3.new(0, 0, 42)

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "BharatavarshaSpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(18, 1.2, 18)
	spawn.Position = spawnPos
	spawn.Color = Color3.fromRGB(245, 200, 85)
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.Parent = root
	applyTiledTexture(spawn, Enum.NormalId.Top, TempleConfig.VisualAssets.TempleStepsTex, 18, 18, 0.15)
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
