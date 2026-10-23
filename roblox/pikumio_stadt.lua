--[[
	PIKUMIO CITY  ·  Stadtaufbau für Roblox
	---------------------------------------
	So benutzt du das Skript:
	  1. Roblox Studio öffnen, ein neues Baseplate-Spiel anlegen.
	  2. Oben auf "Ansicht" (View) → "Befehlsleiste" (Command Bar) einschalten.
	  3. Dieses ganze Skript hineinkopieren und Enter drücken.
	  4. Die Stadt entsteht sofort. Mit Strg+S speichern.

	Klappt das Einfügen nicht, geht es auch so:
	  In Studio links bei "Explorer" auf ServerScriptService rechtsklicken →
	  "Script einfügen", den Inhalt ersetzen, dann oben auf "Play" drücken.

	Das Skript kann man beliebig oft laufen lassen: Es räumt seine alte Stadt
	vorher weg und baut neu.
]]

local Lighting = game:GetService("Lighting")
local Terrain = workspace.Terrain

-- ========== Einstellungen ==========
local BLOCK = 160        -- Abstand der Straßenmitten (Studs)
local ROAD = 44          -- Straßenbreite
local WALK = 10          -- Breite des Gehwegs
local GRID = 2           -- Straßen in jede Richtung ab der Mitte (ergibt 5x5 Kreuzungen)
local EDGE = BLOCK * GRID + BLOCK / 2

-- ========== Farben ==========
local C = {
	gras = Color3.fromRGB(92, 148, 76),
	asphalt = Color3.fromRGB(58, 58, 64),
	gehweg = Color3.fromRGB(176, 172, 164),
	linie = Color3.fromRGB(240, 238, 230),
	fenster = Color3.fromRGB(255, 214, 120),
	glas = Color3.fromRGB(150, 200, 230),
	stamm = Color3.fromRGB(104, 72, 48),
	laub = Color3.fromRGB(70, 136, 64),
	wasser = Color3.fromRGB(42, 96, 128),
	metall = Color3.fromRGB(120, 124, 132),
	gelb = Color3.fromRGB(230, 180, 40),
	rot = Color3.fromRGB(198, 62, 54),
}

local HAUSFARBEN = {
	Color3.fromRGB(196, 110, 92),
	Color3.fromRGB(150, 128, 164),
	Color3.fromRGB(120, 140, 170),
	Color3.fromRGB(206, 176, 128),
	Color3.fromRGB(104, 118, 128),
	Color3.fromRGB(176, 92, 96),
	Color3.fromRGB(132, 160, 140),
}

-- ========== Grundgerüst ==========
local alt = workspace:FindFirstChild("PikumioCity")
if alt then
	alt:Destroy()
end

local stadt = Instance.new("Folder")
stadt.Name = "PikumioCity"
stadt.Parent = workspace

local function ordner(name)
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = stadt
	return f
end

local F_BODEN = ordner("Boden")
local F_STRASSEN = ordner("Strassen")
local F_HAEUSER = ordner("Haeuser")
local F_DEKO = ordner("Deko")
local F_PARK = ordner("Park")
local F_HAFEN = ordner("Hafen")

-- Baut einen Quader. Alles ist verankert, damit nichts wegrollt.
local function block(eltern, name, groesse, pos, farbe, material, drehung)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = groesse
	p.Color = farbe
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if drehung then
		p.CFrame = CFrame.new(pos) * CFrame.Angles(0, math.rad(drehung), 0)
	else
		p.CFrame = CFrame.new(pos)
	end
	p.Parent = eltern
	return p
end

local function keil(eltern, name, groesse, pos, farbe, drehung)
	local p = Instance.new("WedgePart")
	p.Name = name
	p.Anchored = true
	p.Size = groesse
	p.Color = farbe
	p.Material = Enum.Material.Slate
	p.CFrame = CFrame.new(pos) * CFrame.Angles(0, math.rad(drehung or 0), 0)
	p.Parent = eltern
	return p
end

local function zylinder(eltern, name, durchmesser, hoehe, pos, farbe, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = Enum.PartType.Cylinder
	p.Anchored = true
	p.Size = Vector3.new(hoehe, durchmesser, durchmesser)
	p.Color = farbe
	p.Material = material or Enum.Material.SmoothPlastic
	p.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90))
	p.Parent = eltern
	return p
end

local function kugel(eltern, name, durchmesser, pos, farbe)
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = Enum.PartType.Ball
	p.Anchored = true
	p.Size = Vector3.new(durchmesser, durchmesser, durchmesser)
	p.Color = farbe
	p.Material = Enum.Material.Grass
	p.CFrame = CFrame.new(pos)
	p.Parent = eltern
	return p
end

-- Schild mit Text an einer Hauswand
local function schild(eltern, text, pos, breite, drehung, farbe)
	local tafel = block(eltern, "Schild", Vector3.new(breite, 6, 0.6), pos, farbe or Color3.fromRGB(28, 22, 36), Enum.Material.SmoothPlastic, drehung)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.CanvasSize = Vector2.new(breite * 20, 120)
	gui.Parent = tafel
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.fromRGB(255, 214, 120)
	label.Parent = gui
	return tafel
end

-- ========== Boden ==========
local WIESE_Z0, WIESE_Z1 = -EDGE - 200, (GRID - 0.5) * BLOCK + 70
block(F_BODEN, "Wiese", Vector3.new(EDGE * 2 + 400, 4, WIESE_Z1 - WIESE_Z0),
	Vector3.new(0, -2, (WIESE_Z0 + WIESE_Z1) / 2), C.gras, Enum.Material.Grass)

-- ========== Straßen und Gehwege ==========
local function strasse(mitte, waagerecht)
	local laenge = EDGE * 2 + 120
	local groesse, pos
	if waagerecht then
		groesse = Vector3.new(laenge, 1, ROAD)
		pos = Vector3.new(0, 0.5, mitte)
	else
		groesse = Vector3.new(ROAD, 1, laenge)
		pos = Vector3.new(mitte, 0.5, 0)
	end
	block(F_STRASSEN, "Strasse", groesse, pos, C.asphalt, Enum.Material.Asphalt)

	-- Mittelstreifen
	local schritt = 24
	local n = math.floor(laenge / schritt)
	for i = 0, n do
		local t = -laenge / 2 + i * schritt + schritt / 2
		local lp
		if waagerecht then
			lp = Vector3.new(t, 1.05, mitte)
		else
			lp = Vector3.new(mitte, 1.05, t)
		end
		local ls
		if waagerecht then
			ls = Vector3.new(10, 0.1, 1.2)
		else
			ls = Vector3.new(1.2, 0.1, 10)
		end
		block(F_STRASSEN, "Linie", ls, lp, C.linie, Enum.Material.SmoothPlastic)
	end

	-- Gehwege links und rechts
	for _, s in ipairs({ -1, 1 }) do
		local gp, gs
		if waagerecht then
			gs = Vector3.new(laenge, 1.6, WALK)
			gp = Vector3.new(0, 0.8, mitte + s * (ROAD / 2 + WALK / 2))
		else
			gs = Vector3.new(WALK, 1.6, laenge)
			gp = Vector3.new(mitte + s * (ROAD / 2 + WALK / 2), 0.8, 0)
		end
		block(F_STRASSEN, "Gehweg", gs, gp, C.gehweg, Enum.Material.Concrete)
	end
end

for i = -GRID, GRID do
	strasse(i * BLOCK, true)
	strasse(i * BLOCK, false)
end

-- ========== Häuser ==========
local function fensterreihe(eltern, haus, breite, tiefe, hoehe, pos)
	local reihen = math.min(6, math.max(1, math.floor(hoehe / 16)))
	local spalten = math.min(4, math.max(1, math.floor(breite / 12)))
	for r = 1, reihen do
		for s = 1, spalten do
			local y = pos.Y - hoehe / 2 + r * (hoehe / (reihen + 1))
			local x = pos.X - breite / 2 + s * (breite / (spalten + 1))
			local hell = (math.random() < 0.65)
			local farbe = hell and C.fenster or C.glas
			block(eltern, "Fenster", Vector3.new(breite / (spalten + 2), hoehe / (reihen + 3), 0.4),
				Vector3.new(x, y, pos.Z + tiefe / 2 + 0.1), farbe, Enum.Material.Neon)
			block(eltern, "Fenster", Vector3.new(breite / (spalten + 2), hoehe / (reihen + 3), 0.4),
				Vector3.new(x, y, pos.Z - tiefe / 2 - 0.1), farbe, Enum.Material.Neon)
		end
	end
end

local function haus(x, z, breite, tiefe, hoehe, farbe)
	local modell = Instance.new("Model")
	modell.Name = "Haus"
	modell.Parent = F_HAEUSER
	local mitte = Vector3.new(x, hoehe / 2 + 1.6, z)
	local koerper = block(modell, "Wand", Vector3.new(breite, hoehe, tiefe), mitte, farbe, Enum.Material.Brick)
	-- Dachkante
	block(modell, "Dach", Vector3.new(breite + 2, 2, tiefe + 2), Vector3.new(x, hoehe + 2.6, z),
		Color3.fromRGB(62, 56, 66), Enum.Material.Concrete)
	fensterreihe(modell, koerper, breite, tiefe, hoehe, mitte)
	return modell
end

-- In jedem Baufeld ein paar Häuser verteilen
local function baufeld(cx, cz, laden)
	local innen = BLOCK - ROAD - WALK * 2
	block(F_HAEUSER, "Platz", Vector3.new(innen, 1.6, innen), Vector3.new(cx, 0.8, cz),
		Color3.fromRGB(158, 154, 148), Enum.Material.Concrete)
	local frei = innen - 14
	local anzahl = math.random(2, 3)
	local breite = frei / anzahl - 6
	for i = 1, anzahl do
		local x = cx - frei / 2 + (i - 0.5) * (frei / anzahl)
		local tiefe = math.random(30, 50)
		local hoehe = math.random(24, 96)
		local farbe = HAUSFARBEN[math.random(1, #HAUSFARBEN)]
		haus(x, cz, breite, tiefe, hoehe, farbe)
		if laden and i == 1 then
			schild(F_HAEUSER, laden, Vector3.new(x, 14, cz + tiefe / 2 + 0.6), breite - 4, 0)
		end
	end
end

local LAEDEN = { "BÄCKEREI", "FRISEUR", "MARKT", "KINO", "WERKSTATT", "SPIELZEUG", "EISDIELE", "BLUMEN" }
local ladenNr = 1
for gx = -GRID, GRID - 1 do
	for gz = -GRID, GRID - 1 do
		local cx = gx * BLOCK + BLOCK / 2
		local cz = gz * BLOCK + BLOCK / 2
		-- Park und Hafen bekommen kein Bauland
		local istPark = (gx == 0 and gz == 0)
		local istHafen = (gz == GRID - 1)
		if not istPark and not istHafen then
			local laden = nil
			if math.random() < 0.45 and ladenNr <= #LAEDEN then
				laden = LAEDEN[ladenNr]
				ladenNr = ladenNr + 1
			end
			baufeld(cx, cz, laden)
		end
	end
end

-- ========== Park in der Mitte ==========
do
	local cx, cz = BLOCK / 2, BLOCK / 2
	local w = BLOCK - ROAD - WALK * 2
	block(F_PARK, "Parkwiese", Vector3.new(w, 1.8, w), Vector3.new(cx, 0.9, cz), Color3.fromRGB(104, 164, 82), Enum.Material.Grass)

	-- Wege über Kreuz
	block(F_PARK, "Weg", Vector3.new(w, 0.2, 10), Vector3.new(cx, 1.85, cz), Color3.fromRGB(196, 176, 140), Enum.Material.Sand)
	block(F_PARK, "Weg", Vector3.new(10, 0.2, w), Vector3.new(cx, 1.85, cz), Color3.fromRGB(196, 176, 140), Enum.Material.Sand)

	-- Springbrunnen
	zylinder(F_PARK, "Brunnenrand", 26, 3, Vector3.new(cx, 3.2, cz), C.gehweg, Enum.Material.Marble)
	zylinder(F_PARK, "Wasser", 23, 3.2, Vector3.new(cx, 3.6, cz), C.wasser, Enum.Material.Water)
	zylinder(F_PARK, "Saeule", 4, 8, Vector3.new(cx, 7, cz), C.gehweg, Enum.Material.Marble)
	kugel(F_PARK, "Wasserkugel", 7, Vector3.new(cx, 12, cz), Color3.fromRGB(150, 210, 235))

	-- Bäume und Bänke
	for i = 1, 14 do
		local a = (i / 14) * math.pi * 2
		local r = 34 + math.random() * 14
		local bx = cx + math.cos(a) * r
		local bz = cz + math.sin(a) * r
		zylinder(F_PARK, "Stamm", 3, 12, Vector3.new(bx, 7.6, bz), C.stamm, Enum.Material.Wood)
		kugel(F_PARK, "Krone", 16 + math.random() * 6, Vector3.new(bx, 18, bz), C.laub)
	end
	for _, s in ipairs({ -1, 1 }) do
		block(F_PARK, "Bank", Vector3.new(12, 1, 4), Vector3.new(cx + s * 20, 4, cz + 16), C.stamm, Enum.Material.Wood)
		block(F_PARK, "Lehne", Vector3.new(12, 5, 1), Vector3.new(cx + s * 20, 6, cz + 18), C.stamm, Enum.Material.Wood)
	end
end

-- ========== Hafen am Rand ==========
do
	local z = (GRID - 0.5) * BLOCK + 10
	local breite = EDGE * 2

	-- Kaimauer
	block(F_HAFEN, "Kai", Vector3.new(breite, 6, 60), Vector3.new(0, 3, z + 40), C.gehweg, Enum.Material.Concrete)

	-- Wasser dahinter (erst altes wegräumen, dann neu füllen)
	local wasserMitte = CFrame.new(0, -10, z + 140)
	local wasserGroesse = Vector3.new(breite + 400, 40, 180)
	Terrain:FillBlock(wasserMitte, wasserGroesse, Enum.Material.Air)
	Terrain:FillBlock(CFrame.new(0, -10, z + 140), Vector3.new(breite + 400, 20, 180), Enum.Material.Water)

	-- Container stapeln
	local cfarben = {
		Color3.fromRGB(196, 72, 60), Color3.fromRGB(60, 120, 180),
		Color3.fromRGB(220, 160, 50), Color3.fromRGB(70, 150, 110),
	}
	for i = 1, 22 do
		local x = -breite / 2 + 30 + math.random() * (breite - 60)
		local stapel = math.random(1, 3)
		for s = 1, stapel do
			block(F_HAFEN, "Container", Vector3.new(24, 10, 10),
				Vector3.new(x, 6 + (s - 0.5) * 10, z + 20 + math.random() * 30),
				cfarben[math.random(1, #cfarben)], Enum.Material.CorrodedMetal, math.random(0, 1) * 90)
		end
	end

	-- Zwei Kräne
	for _, kx in ipairs({ -90, 110 }) do
		local k = Instance.new("Model")
		k.Name = "Kran"
		k.Parent = F_HAFEN
		for _, s in ipairs({ -1, 1 }) do
			block(k, "Bein", Vector3.new(4, 60, 4), Vector3.new(kx + s * 14, 36, z + 40), C.gelb, Enum.Material.Metal)
		end
		block(k, "Traeger", Vector3.new(36, 5, 6), Vector3.new(kx, 68, z + 40), C.gelb, Enum.Material.Metal)
		block(k, "Ausleger", Vector3.new(6, 4, 90), Vector3.new(kx, 70, z + 80), C.gelb, Enum.Material.Metal)
		block(k, "Kabine", Vector3.new(8, 7, 8), Vector3.new(kx, 62, z + 52), C.metall, Enum.Material.Metal)
	end
end

-- ========== Straßenlaternen, Ampeln, Bäume am Weg ==========
do
	for i = -GRID, GRID do
		local n = 0
		for t = -EDGE, EDGE, 80 do
			for _, s in ipairs({ -1, 1 }) do
				local px = i * BLOCK + s * (ROAD / 2 + WALK - 2)
				-- Laternen an den senkrechten Straßen
				zylinder(F_DEKO, "Mast", 1.4, 22, Vector3.new(px, 12, t), C.metall, Enum.Material.Metal)
				local lampe = block(F_DEKO, "Lampe", Vector3.new(5, 1.4, 3), Vector3.new(px - s * 2, 23, t), C.fenster, Enum.Material.Neon)
				n = n + 1
				if n % 3 == 0 then   -- nicht jede Lampe leuchtet, sonst wird es zu langsam
					local licht = Instance.new("PointLight")
					licht.Range = 40
					licht.Brightness = 1.6
					licht.Color = Color3.fromRGB(255, 220, 150)
					licht.Parent = lampe
				end
			end
		end
	end

	-- Ampeln an den Kreuzungen
	for i = -GRID, GRID do
		for j = -GRID, GRID do
			local x = i * BLOCK + ROAD / 2 + WALK - 3
			local z = j * BLOCK + ROAD / 2 + WALK - 3
			zylinder(F_DEKO, "Ampelmast", 1.2, 20, Vector3.new(x, 11, z), Color3.fromRGB(40, 44, 50), Enum.Material.Metal)
			local kasten = block(F_DEKO, "Ampel", Vector3.new(3, 8, 3), Vector3.new(x, 22, z), Color3.fromRGB(32, 34, 40), Enum.Material.SmoothPlastic)
			block(F_DEKO, "Rot", Vector3.new(1.6, 1.6, 0.4), Vector3.new(x, 24.4, z + 1.6), Color3.fromRGB(230, 60, 50), Enum.Material.Neon)
			block(F_DEKO, "Gelb", Vector3.new(1.6, 1.6, 0.4), Vector3.new(x, 22, z + 1.6), Color3.fromRGB(240, 200, 60), Enum.Material.Neon)
			block(F_DEKO, "Gruen", Vector3.new(1.6, 1.6, 0.4), Vector3.new(x, 19.6, z + 1.6), Color3.fromRGB(70, 220, 110), Enum.Material.Neon)
			kasten.Name = "Ampel"
		end
	end
end

-- ========== Deine Basis ==========
do
	local bx, bz = -BLOCK / 2, -BLOCK / 2
	local m = Instance.new("Model")
	m.Name = "Basis"
	m.Parent = stadt

	block(m, "Hof", Vector3.new(70, 1.6, 70), Vector3.new(bx, 0.8, bz), Color3.fromRGB(150, 146, 140), Enum.Material.Concrete)
	block(m, "Haus", Vector3.new(40, 26, 30), Vector3.new(bx, 14.6, bz), Color3.fromRGB(214, 178, 128), Enum.Material.WoodPlanks)
	keil(m, "Dach", Vector3.new(30, 12, 44), Vector3.new(bx, 33.6, bz), C.rot, 90)
	block(m, "Tuer", Vector3.new(8, 14, 1), Vector3.new(bx, 8.6, bz + 15.2), Color3.fromRGB(110, 70, 44), Enum.Material.Wood)
	schild(m, "PIKUMIO", Vector3.new(bx, 26, bz + 15.4), 24, 0, Color3.fromRGB(40, 28, 56))

	local startpunkt = Instance.new("SpawnLocation")
	startpunkt.Name = "Start"
	startpunkt.Anchored = true
	startpunkt.Size = Vector3.new(12, 1, 12)
	startpunkt.CFrame = CFrame.new(bx, 2.2, bz + 26)
	startpunkt.Color = Color3.fromRGB(255, 200, 58)
	startpunkt.Material = Enum.Material.Neon
	startpunkt.TopSurface = Enum.SurfaceType.Smooth
	startpunkt.Parent = m
end

-- ========== Licht und Himmel ==========
Lighting.ClockTime = 15
Lighting.Brightness = 2.6
Lighting.GlobalShadows = true
Lighting.EnvironmentDiffuseScale = 0.45
Lighting.EnvironmentSpecularScale = 0.35
Lighting.OutdoorAmbient = Color3.fromRGB(120, 124, 150)
Lighting.FogEnd = 1400

local alteAtmo = Lighting:FindFirstChildOfClass("Atmosphere")
if alteAtmo then
	alteAtmo:Destroy()
end
local atmo = Instance.new("Atmosphere")
atmo.Density = 0.32
atmo.Haze = 1.4
atmo.Glare = 0.2
atmo.Color = Color3.fromRGB(205, 215, 235)
atmo.Decay = Color3.fromRGB(120, 130, 160)
atmo.Parent = Lighting

print("Pikumio City steht! Teile: " .. #stadt:GetDescendants())
