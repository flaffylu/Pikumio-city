--[[
	PIKUMIO CITY  ·  Weltaufbau für Roblox   (Version 2 – große Welt mit Autos)
	---------------------------------------------------------------------------
	So benutzt du das Skript:
	  1. Roblox Studio öffnen, Baseplate-Spiel.
	  2. Ansicht → Befehlsleiste einschalten.
	  3. Dieses ganze Skript hineinkopieren, Enter drücken. Dauert ein paar Sekunden.
	  4. Mit Strg+S speichern.

	Damit die Autos fahren, brauchst du noch das zweite Skript:
	  Explorer → StarterPlayer → StarterPlayerScripts → Rechtsklick →
	  "LocalScript einfügen", Inhalt durch "pikumio_auto.lua" ersetzen.

	Das Skript kann beliebig oft laufen – es räumt die alte Welt vorher weg.
]]

local Lighting = game:GetService("Lighting")
local Terrain = workspace.Terrain

-- ========== Maße der Welt ==========
local BLOCK = 160          -- Abstand der Straßenmitten
local ROAD = 44            -- Straßenbreite
local WALK = 10            -- Gehwegbreite
local GRID = 4             -- Straßen je Richtung ab der Mitte  -> 9x9 Kreuzungen
local EDGE = BLOCK * GRID + BLOCK / 2       -- Rand der Stadt (720)
local LAND = EDGE + 700                     -- Rand des Umlands

-- ========== Farben ==========
local C = {
	gras = Color3.fromRGB(92, 148, 76),
	wiese = Color3.fromRGB(110, 164, 84),
	asphalt = Color3.fromRGB(58, 58, 64),
	gehweg = Color3.fromRGB(176, 172, 164),
	linie = Color3.fromRGB(240, 238, 230),
	fenster = Color3.fromRGB(255, 214, 120),
	glas = Color3.fromRGB(150, 200, 230),
	stamm = Color3.fromRGB(104, 72, 48),
	laub = Color3.fromRGB(70, 136, 64),
	tanne = Color3.fromRGB(46, 104, 62),
	metall = Color3.fromRGB(120, 124, 132),
	gelb = Color3.fromRGB(230, 180, 40),
	rot = Color3.fromRGB(198, 62, 54),
	sand = Color3.fromRGB(226, 206, 150),
	fels = Color3.fromRGB(128, 124, 120),
	schnee = Color3.fromRGB(242, 244, 250),
}

local HAUSFARBEN = {
	Color3.fromRGB(196, 110, 92), Color3.fromRGB(150, 128, 164),
	Color3.fromRGB(120, 140, 170), Color3.fromRGB(206, 176, 128),
	Color3.fromRGB(104, 118, 128), Color3.fromRGB(176, 92, 96),
	Color3.fromRGB(132, 160, 140), Color3.fromRGB(188, 152, 112),
}
local AUTOFARBEN = {
	Color3.fromRGB(198, 52, 46), Color3.fromRGB(42, 96, 170),
	Color3.fromRGB(238, 196, 52), Color3.fromRGB(60, 150, 96),
	Color3.fromRGB(236, 240, 244), Color3.fromRGB(40, 42, 50),
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
local F_LAND = ordner("Umland")
local F_AUTOS = ordner("Autos")

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

local function keil(eltern, name, groesse, pos, farbe, drehung, material)
	local p = Instance.new("WedgePart")
	p.Name = name
	p.Anchored = true
	p.Size = groesse
	p.Color = farbe
	p.Material = material or Enum.Material.Slate
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

local function kugel(eltern, name, durchmesser, pos, farbe, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = Enum.PartType.Ball
	p.Anchored = true
	p.Size = Vector3.new(durchmesser, durchmesser, durchmesser)
	p.Color = farbe
	p.Material = material or Enum.Material.Grass
	p.CFrame = CFrame.new(pos)
	p.Parent = eltern
	return p
end

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

local function baum(eltern, x, z, groesse, tanne)
	groesse = groesse or 1
	zylinder(eltern, "Stamm", 3 * groesse, 12 * groesse, Vector3.new(x, 7 * groesse, z), C.stamm, Enum.Material.Wood)
	if tanne then
		for i = 1, 3 do
			local d = (16 - i * 3.5) * groesse
			kugel(eltern, "Krone", d, Vector3.new(x, (13 + i * 4) * groesse, z), C.tanne, Enum.Material.Grass)
		end
	else
		kugel(eltern, "Krone", (16 + math.random() * 6) * groesse, Vector3.new(x, 18 * groesse, z), C.laub)
	end
end

-- ========== Boden ==========
local WIESE_Z1 = (GRID - 0.5) * BLOCK + 70
block(F_BODEN, "Wiese", Vector3.new(LAND * 2, 4, (WIESE_Z1 + LAND)),
	Vector3.new(0, -2, (WIESE_Z1 - LAND) / 2), C.gras, Enum.Material.Grass)

-- ========== Straßen ==========
local function strasse(mitte, waagerecht)
	local laenge = EDGE * 2 + 160
	local groesse, pos
	if waagerecht then
		groesse = Vector3.new(laenge, 1, ROAD)
		pos = Vector3.new(0, 0.5, mitte)
	else
		groesse = Vector3.new(ROAD, 1, laenge)
		pos = Vector3.new(mitte, 0.5, 0)
	end
	block(F_STRASSEN, "Strasse", groesse, pos, C.asphalt, Enum.Material.Asphalt)

	local schritt = 48
	for i = 0, math.floor(laenge / schritt) do
		local t = -laenge / 2 + i * schritt + schritt / 2
		local lp, ls
		if waagerecht then
			lp = Vector3.new(t, 1.05, mitte)
			ls = Vector3.new(16, 0.1, 1.2)
		else
			lp = Vector3.new(mitte, 1.05, t)
			ls = Vector3.new(1.2, 0.1, 16)
		end
		block(F_STRASSEN, "Linie", ls, lp, C.linie, Enum.Material.SmoothPlastic)
	end

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

-- Landstraße nach Süden ins Umland
block(F_STRASSEN, "Landstrasse", Vector3.new(ROAD, 1, 700), Vector3.new(0, 0.5, -EDGE - 350), C.asphalt, Enum.Material.Asphalt)

-- ========== Häuser ==========
local function fenster(eltern, breite, tiefe, hoehe, pos, dicht)
	local reihen = math.min(dicht and 7 or 4, math.max(1, math.floor(hoehe / 18)))
	local spalten = math.min(4, math.max(1, math.floor(breite / 14)))
	for r = 1, reihen do
		for s = 1, spalten do
			local y = pos.Y - hoehe / 2 + r * (hoehe / (reihen + 1))
			local x = pos.X - breite / 2 + s * (breite / (spalten + 1))
			local farbe = (math.random() < 0.6) and C.fenster or C.glas
			local gr = Vector3.new(breite / (spalten + 2), hoehe / (reihen + 3), 0.4)
			block(eltern, "Fenster", gr, Vector3.new(x, y, pos.Z + tiefe / 2 + 0.1), farbe, Enum.Material.Neon)
			block(eltern, "Fenster", gr, Vector3.new(x, y, pos.Z - tiefe / 2 - 0.1), farbe, Enum.Material.Neon)
		end
	end
end

local function hochhaus(x, z, breite, tiefe, hoehe, farbe)
	local m = Instance.new("Model")
	m.Name = "Haus"
	m.Parent = F_HAEUSER
	local mitte = Vector3.new(x, hoehe / 2 + 1.6, z)
	block(m, "Wand", Vector3.new(breite, hoehe, tiefe), mitte, farbe, Enum.Material.Brick)
	block(m, "Dach", Vector3.new(breite + 2, 2, tiefe + 2), Vector3.new(x, hoehe + 2.6, z), Color3.fromRGB(62, 56, 66), Enum.Material.Concrete)
	fenster(m, breite, tiefe, hoehe, mitte, hoehe > 90)
	return m
end

local function kleinhaus(x, z, breite, tiefe, farbe)
	local m = Instance.new("Model")
	m.Name = "Haus"
	m.Parent = F_HAEUSER
	local hoehe = 18
	local mitte = Vector3.new(x, hoehe / 2 + 1.6, z)
	block(m, "Wand", Vector3.new(breite, hoehe, tiefe), mitte, farbe, Enum.Material.WoodPlanks)
	-- Satteldach aus zwei Keilen
	for _, s in ipairs({ -1, 1 }) do
		keil(m, "Dach", Vector3.new(tiefe + 2, 9, breite / 2 + 1),
			Vector3.new(x + s * (breite / 4 + 0.25), hoehe + 6.1, z), C.rot, s > 0 and 90 or 270)
	end
	block(m, "Tuer", Vector3.new(5, 9, 0.8), Vector3.new(x, 6.1, z + tiefe / 2 + 0.2), Color3.fromRGB(110, 70, 44), Enum.Material.Wood)
	fenster(m, breite, tiefe, hoehe, mitte, false)
	-- Gartenzaun
	for _, s in ipairs({ -1, 1 }) do
		block(m, "Zaun", Vector3.new(breite + 20, 4, 0.8), Vector3.new(x, 3.6, z + s * (tiefe / 2 + 11)), C.gehweg, Enum.Material.Wood)
	end
	return m
end

local LAEDEN = {
	"BÄCKEREI", "FRISEUR", "MARKT", "KINO", "WERKSTATT", "SPIELZEUG", "EISDIELE", "BLUMEN",
	"KLEIDER", "BUCHLADEN", "PIZZA", "APOTHEKE", "SCHULE", "POLIZEI", "KLINIK", "BANK",
}
local ladenNr = 1

local function baufeld(cx, cz, ring)
	local innen = BLOCK - ROAD - WALK * 2
	block(F_HAEUSER, "Platz", Vector3.new(innen, 1.6, innen), Vector3.new(cx, 0.8, cz),
		Color3.fromRGB(158, 154, 148), Enum.Material.Concrete)
	local frei = innen - 14
	local anzahl = (ring >= 3) and 2 or math.random(2, 3)
	local breite = frei / anzahl - 8
	for i = 1, anzahl do
		local x = cx - frei / 2 + (i - 0.5) * (frei / anzahl)
		local tiefe = math.random(30, 48)
		local farbe = HAUSFARBEN[math.random(1, #HAUSFARBEN)]
		if ring >= 3 then
			kleinhaus(x, cz, breite, tiefe, farbe)       -- Vorstadt: kleine Häuser
		else
			local hoehe
			if ring == 0 then
				hoehe = math.random(90, 200)             -- Zentrum: Hochhäuser
			elseif ring == 1 then
				hoehe = math.random(50, 120)
			else
				hoehe = math.random(26, 70)
			end
			hochhaus(x, cz, breite, tiefe, hoehe, farbe)
			if i == 1 and ladenNr <= #LAEDEN and math.random() < 0.5 then
				schild(F_HAEUSER, LAEDEN[ladenNr], Vector3.new(x, 14, cz + tiefe / 2 + 0.6), breite - 4, 0)
				ladenNr = ladenNr + 1
			end
		end
	end
end

for gx = -GRID, GRID - 1 do
	for gz = -GRID, GRID - 1 do
		local cx = gx * BLOCK + BLOCK / 2
		local cz = gz * BLOCK + BLOCK / 2
		local ring = math.max(math.abs(gx), math.abs(gz + 1))
		local istPark = (gx == 0 and gz == 0)
		local istHafen = (gz == GRID - 1)
		local istBasis = (gx == -1 and gz == -1)
		if not istPark and not istHafen and not istBasis then
			baufeld(cx, cz, ring)
		end
	end
end

-- ========== Park ==========
do
	local cx, cz = BLOCK / 2, BLOCK / 2
	local w = BLOCK - ROAD - WALK * 2
	block(F_PARK, "Parkwiese", Vector3.new(w, 1.8, w), Vector3.new(cx, 0.9, cz), Color3.fromRGB(104, 164, 82), Enum.Material.Grass)
	block(F_PARK, "Weg", Vector3.new(w, 0.2, 10), Vector3.new(cx, 1.85, cz), Color3.fromRGB(196, 176, 140), Enum.Material.Sand)
	block(F_PARK, "Weg", Vector3.new(10, 0.2, w), Vector3.new(cx, 1.85, cz), Color3.fromRGB(196, 176, 140), Enum.Material.Sand)
	zylinder(F_PARK, "Brunnenrand", 28, 3, Vector3.new(cx, 3.2, cz), C.gehweg, Enum.Material.Marble)
	zylinder(F_PARK, "Wasser", 25, 3.2, Vector3.new(cx, 3.6, cz), Color3.fromRGB(60, 140, 180), Enum.Material.Water)
	zylinder(F_PARK, "Saeule", 4, 9, Vector3.new(cx, 7.5, cz), C.gehweg, Enum.Material.Marble)
	kugel(F_PARK, "Wasserkugel", 8, Vector3.new(cx, 13, cz), Color3.fromRGB(150, 210, 235))
	for i = 1, 16 do
		local a = (i / 16) * math.pi * 2
		local r = 36 + math.random() * 16
		baum(F_PARK, cx + math.cos(a) * r, cz + math.sin(a) * r, 1, false)
	end
	for _, s in ipairs({ -1, 1 }) do
		block(F_PARK, "Bank", Vector3.new(12, 1, 4), Vector3.new(cx + s * 22, 4, cz + 18), C.stamm, Enum.Material.Wood)
		block(F_PARK, "Lehne", Vector3.new(12, 5, 1), Vector3.new(cx + s * 22, 6, cz + 20), C.stamm, Enum.Material.Wood)
	end
end

-- ========== Hafen ==========
do
	local z = (GRID - 0.5) * BLOCK + 10
	local breite = EDGE * 2
	block(F_HAFEN, "Kai", Vector3.new(breite, 6, 60), Vector3.new(0, 3, z + 40), C.gehweg, Enum.Material.Concrete)
	local mitte = CFrame.new(0, -10, z + 220)
	local gr = Vector3.new(LAND * 2, 40, 400)
	Terrain:FillBlock(mitte, gr, Enum.Material.Air)
	Terrain:FillBlock(CFrame.new(0, -10, z + 220), Vector3.new(LAND * 2, 20, 400), Enum.Material.Water)

	local cfarben = {
		Color3.fromRGB(196, 72, 60), Color3.fromRGB(60, 120, 180),
		Color3.fromRGB(220, 160, 50), Color3.fromRGB(70, 150, 110),
	}
	for i = 1, 40 do
		local x = -breite / 2 + 40 + math.random() * (breite - 80)
		for s = 1, math.random(1, 3) do
			block(F_HAFEN, "Container", Vector3.new(24, 10, 10),
				Vector3.new(x, 6 + (s - 0.5) * 10, z + 20 + math.random() * 30),
				cfarben[math.random(1, #cfarben)], Enum.Material.CorrodedMetal, math.random(0, 1) * 90)
		end
	end
	for _, kx in ipairs({ -320, -80, 180, 420 }) do
		local k = Instance.new("Model")
		k.Name = "Kran"
		k.Parent = F_HAFEN
		for _, s in ipairs({ -1, 1 }) do
			block(k, "Bein", Vector3.new(4, 60, 4), Vector3.new(kx + s * 14, 36, z + 40), C.gelb, Enum.Material.Metal)
		end
		block(k, "Traeger", Vector3.new(36, 5, 6), Vector3.new(kx, 68, z + 40), C.gelb, Enum.Material.Metal)
		block(k, "Ausleger", Vector3.new(6, 4, 100), Vector3.new(kx, 70, z + 85), C.gelb, Enum.Material.Metal)
		block(k, "Kabine", Vector3.new(8, 7, 8), Vector3.new(kx, 62, z + 52), C.metall, Enum.Material.Metal)
	end
	-- Strand westlich vom Hafen
	block(F_HAFEN, "Strand", Vector3.new(500, 2, 150), Vector3.new(-EDGE - 260, 1, z + 30), C.sand, Enum.Material.Sand)
	for i = 1, 10 do
		baum(F_HAFEN, -EDGE - 500 + math.random() * 480, z - 10 + math.random() * 60, 0.9, false)
	end
end

-- ========== Umland: Wald, See, Bauernhof, Berg ==========
do
	-- Wald im Südwesten
	for i = 1, 120 do
		local x = -LAND + 120 + math.random() * 560
		local z = -EDGE - 80 - math.random() * 560
		baum(F_LAND, x, z, 0.9 + math.random() * 0.5, math.random() < 0.6)
	end

	-- See im Süden
	local seeC = CFrame.new(140, -8, -EDGE - 420)
	Terrain:FillBlock(seeC, Vector3.new(420, 30, 320), Enum.Material.Air)
	Terrain:FillBlock(CFrame.new(140, -8, -EDGE - 420), Vector3.new(420, 16, 320), Enum.Material.Water)
	block(F_LAND, "Steg", Vector3.new(10, 2, 70), Vector3.new(140, 2, -EDGE - 250), C.stamm, Enum.Material.WoodPlanks)

	-- Bauernhof im Südosten
	local fx, fz = LAND - 420, -EDGE - 300
	block(F_LAND, "Hofplatz", Vector3.new(240, 1.6, 200), Vector3.new(fx, 0.8, fz), Color3.fromRGB(176, 156, 120), Enum.Material.Ground)
	local scheune = Instance.new("Model")
	scheune.Name = "Scheune"
	scheune.Parent = F_LAND
	block(scheune, "Wand", Vector3.new(70, 26, 44), Vector3.new(fx, 14.6, fz), C.rot, Enum.Material.WoodPlanks)
	for _, s in ipairs({ -1, 1 }) do
		keil(scheune, "Dach", Vector3.new(46, 14, 36), Vector3.new(fx + s * 17.5, 34.6, fz), Color3.fromRGB(80, 70, 66), s > 0 and 90 or 270)
	end
	schild(F_LAND, "BAUERNHOF", Vector3.new(fx, 24, fz + 22.4), 40, 0)
	for i = 1, 6 do
		block(F_LAND, "Feld", Vector3.new(90, 1.2, 26), Vector3.new(fx + 190, 1.4, fz - 90 + i * 30),
			(i % 2 == 0) and Color3.fromRGB(190, 170, 70) or Color3.fromRGB(120, 150, 70), Enum.Material.Grass)
	end

	-- Berg im Nordwesten
	local bx, bz = -LAND + 260, EDGE + 320
	for i = 1, 7 do
		local d = 420 - i * 52
		zylinder(F_LAND, "Fels", d, 46, Vector3.new(bx, i * 40 - 10, bz), C.fels, Enum.Material.Rock)
	end
	kugel(F_LAND, "Gipfel", 120, Vector3.new(bx, 290, bz), C.schnee, Enum.Material.Snow)
end

-- ========== Laternen und Ampeln ==========
do
	for i = -GRID, GRID do
		if i % 2 == 0 then
			local n = 0
			for t = -EDGE, EDGE, 100 do
				for _, s in ipairs({ -1, 1 }) do
					local px = i * BLOCK + s * (ROAD / 2 + WALK - 2)
					zylinder(F_DEKO, "Mast", 1.4, 22, Vector3.new(px, 12, t), C.metall, Enum.Material.Metal)
					local lampe = block(F_DEKO, "Lampe", Vector3.new(5, 1.4, 3), Vector3.new(px - s * 2, 23, t), C.fenster, Enum.Material.Neon)
					n = n + 1
					if n % 3 == 0 then
						local licht = Instance.new("PointLight")
						licht.Range = 42
						licht.Brightness = 1.6
						licht.Color = Color3.fromRGB(255, 220, 150)
						licht.Parent = lampe
					end
				end
			end
		end
	end

	for i = -GRID, GRID, 2 do
		for j = -GRID, GRID, 2 do
			local x = i * BLOCK + ROAD / 2 + WALK - 3
			local z = j * BLOCK + ROAD / 2 + WALK - 3
			zylinder(F_DEKO, "Ampelmast", 1.2, 20, Vector3.new(x, 11, z), Color3.fromRGB(40, 44, 50), Enum.Material.Metal)
			block(F_DEKO, "Ampel", Vector3.new(3, 8, 3), Vector3.new(x, 22, z), Color3.fromRGB(32, 34, 40), Enum.Material.SmoothPlastic)
			block(F_DEKO, "Rot", Vector3.new(1.6, 1.6, 0.4), Vector3.new(x, 24.4, z + 1.6), Color3.fromRGB(230, 60, 50), Enum.Material.Neon)
			block(F_DEKO, "Gelb", Vector3.new(1.6, 1.6, 0.4), Vector3.new(x, 22, z + 1.6), Color3.fromRGB(240, 200, 60), Enum.Material.Neon)
			block(F_DEKO, "Gruen", Vector3.new(1.6, 1.6, 0.4), Vector3.new(x, 19.6, z + 1.6), Color3.fromRGB(70, 220, 110), Enum.Material.Neon)
		end
	end
end

-- ========== Basis mit Startpunkt ==========
do
	local bx, bz = -BLOCK / 2 - BLOCK, -BLOCK / 2 - BLOCK
	local m = Instance.new("Model")
	m.Name = "Basis"
	m.Parent = stadt
	block(m, "Hof", Vector3.new(90, 1.6, 90), Vector3.new(bx, 0.8, bz), Color3.fromRGB(150, 146, 140), Enum.Material.Concrete)
	block(m, "Haus", Vector3.new(44, 28, 32), Vector3.new(bx, 15.6, bz), Color3.fromRGB(214, 178, 128), Enum.Material.WoodPlanks)
	for _, s in ipairs({ -1, 1 }) do
		keil(m, "Dach", Vector3.new(34, 12, 24), Vector3.new(bx + s * 11, 35.6, bz), C.rot, s > 0 and 90 or 270)
	end
	block(m, "Tuer", Vector3.new(8, 14, 1), Vector3.new(bx, 8.6, bz + 16.2), Color3.fromRGB(110, 70, 44), Enum.Material.Wood)
	schild(m, "PIKUMIO", Vector3.new(bx, 27, bz + 16.4), 26, 0, Color3.fromRGB(40, 28, 56))

	local startpunkt = Instance.new("SpawnLocation")
	startpunkt.Name = "Start"
	startpunkt.Anchored = true
	startpunkt.Size = Vector3.new(14, 1, 14)
	startpunkt.CFrame = CFrame.new(bx, 2.2, bz + 30)
	startpunkt.Color = Color3.fromRGB(255, 200, 58)
	startpunkt.Material = Enum.Material.Neon
	startpunkt.TopSurface = Enum.SurfaceType.Smooth
	startpunkt.Parent = m
end

-- ========== Autos ==========
-- Aufbau: Karosserie ohne Kollision, vier Räder mit Kollision, alles fest verschweißt.
-- Gefahren wird über das zweite Skript (pikumio_auto.lua) in ServerScriptService.
local function auto(x, z, drehung, farbe)
	local m = Instance.new("Model")
	m.Name = "Auto"
	m.Parent = F_AUTOS

	local function teil(name, groesse, versatz, f, material, kollision)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = groesse
		p.Color = f
		p.Material = material or Enum.Material.SmoothPlastic
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.CanCollide = kollision and true or false
		p.Anchored = false
		p.CFrame = CFrame.new(x, 0, z) * CFrame.Angles(0, math.rad(drehung), 0) * CFrame.new(versatz)
		p.Parent = m
		return p
	end

	local karo = teil("Karosserie", Vector3.new(9, 3.4, 18), Vector3.new(0, 4.2, 0), farbe, Enum.Material.SmoothPlastic, false)
	m.PrimaryPart = karo
	teil("Dach", Vector3.new(8.4, 3, 8), Vector3.new(0, 7.2, -1), farbe, Enum.Material.SmoothPlastic, false)
	teil("Scheibe", Vector3.new(8.6, 2.4, 0.4), Vector3.new(0, 7.2, 3), Color3.fromRGB(150, 200, 230), Enum.Material.Glass, false)
	for _, s in ipairs({ -1, 1 }) do
		teil("Licht", Vector3.new(2, 1.2, 0.4), Vector3.new(s * 2.8, 4.4, 9.1), Color3.fromRGB(255, 240, 190), Enum.Material.Neon, false)
		teil("Ruecklicht", Vector3.new(2, 1.2, 0.4), Vector3.new(s * 2.8, 4.4, -9.1), Color3.fromRGB(230, 60, 50), Enum.Material.Neon, false)
	end

	local raeder = {}
	for _, dz in ipairs({ 5.6, -5.6 }) do
		for _, dx in ipairs({ -4.6, 4.6 }) do
			local rad = Instance.new("Part")
			rad.Name = "Rad"
			rad.Shape = Enum.PartType.Cylinder
			rad.Size = Vector3.new(2.2, 5, 5)
			rad.Color = Color3.fromRGB(30, 30, 34)
			rad.Material = Enum.Material.SmoothPlastic
			rad.CanCollide = true
			rad.Anchored = false
			rad.CustomPhysicalProperties = PhysicalProperties.new(1.2, 0.35, 0.1, 1, 1)
			rad.CFrame = CFrame.new(x, 0, z) * CFrame.Angles(0, math.rad(drehung), 0)
				* CFrame.new(dx, 3.5, dz) * CFrame.Angles(0, 0, math.rad(90))
			rad.Parent = m
			table.insert(raeder, rad)
		end
	end

	local sitz = Instance.new("VehicleSeat")
	sitz.Name = "Fahrersitz"
	sitz.Size = Vector3.new(5, 1, 5)
	sitz.Color = Color3.fromRGB(40, 40, 46)
	sitz.Material = Enum.Material.Fabric
	sitz.Anchored = false
	sitz.CanCollide = false
	sitz.MaxSpeed = 90
	sitz.Torque = 20
	sitz.TurnSpeed = 6
	sitz.CFrame = CFrame.new(x, 0, z) * CFrame.Angles(0, math.rad(drehung), 0) * CFrame.new(0, 6.2, -1)
	sitz.Parent = m

	-- alles fest mit der Karosserie verbinden
	for _, p in ipairs(m:GetChildren()) do
		if p ~= karo and p:IsA("BasePart") then
			local w = Instance.new("WeldConstraint")
			w.Part0 = karo
			w.Part1 = p
			w.Parent = karo
		end
	end
	return m
end

do
	local plaetze = {
		{ -BLOCK / 2 - BLOCK, -BLOCK / 2 - BLOCK + 46, 0 },
		{ BLOCK + 24, -BLOCK * 2 + 10, 0 },
		{ -BLOCK * 2 + 24, BLOCK + 40, 0 },
		{ BLOCK * 2 + 24, BLOCK * 2 - 30, 0 },
		{ 24, -BLOCK * 3 + 20, 0 },
		{ -BLOCK * 3 + 24, -20, 0 },
		{ BLOCK * 3 + 24, -BLOCK + 30, 0 },
		{ -24, BLOCK * 3 - 40, 180 },
	}
	for i, p in ipairs(plaetze) do
		auto(p[1], p[2], p[3], AUTOFARBEN[((i - 1) % #AUTOFARBEN) + 1])
	end
end

-- ========== Licht und Himmel ==========
Lighting.ClockTime = 15
Lighting.Brightness = 2.6
Lighting.GlobalShadows = true
Lighting.EnvironmentDiffuseScale = 0.45
Lighting.EnvironmentSpecularScale = 0.35
Lighting.OutdoorAmbient = Color3.fromRGB(120, 124, 150)
Lighting.FogEnd = 3000

local alteAtmo = Lighting:FindFirstChildOfClass("Atmosphere")
if alteAtmo then
	alteAtmo:Destroy()
end
local atmo = Instance.new("Atmosphere")
atmo.Density = 0.3
atmo.Haze = 1.6
atmo.Glare = 0.2
atmo.Color = Color3.fromRGB(205, 215, 235)
atmo.Decay = Color3.fromRGB(120, 130, 160)
atmo.Parent = Lighting

print("Pikumio City steht! Teile: " .. #stadt:GetDescendants() .. "  ·  Stadt: " .. (EDGE * 2) .. " Studs breit")
