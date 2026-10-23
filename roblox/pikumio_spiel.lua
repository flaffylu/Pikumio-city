--[[
	PIKUMIO CITY  ·  Das Spiel
	--------------------------
	Wohin damit:
	  Explorer → Rechtsklick auf ServerScriptService → "Script einfügen"
	  → Inhalt durch dieses Skript ersetzen.

	Es braucht die Welt aus "pikumio_stadt.lua" (Ordner PikumioCity im Workspace).

	Was es macht:
	  · 140 Münzen liegen in der Stadt und kommen nach kurzer Zeit wieder
	  · die Frechdachs-Bande jagt dich – spring von oben drauf, dann ist sie weg
	  · Klaufix klaut Münzen und haut ab; schnappst du ihn, gibt es sie doppelt zurück
	  · Baron Blubberbauch kommt als Boss, sobald jemand 50 Münzen hat
	  · vor der Basis kannst du Haustier, Krone, Turboschuhe und Extraleben kaufen
	  · drei Aufgaben, die nacheinander kommen
	  · Tag und Nacht wechseln von selbst
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local welt = workspace:WaitForChild("PikumioCity")

-- Dieselben Maße wie im Aufbauskript
local BLOCK, ROAD, GRID = 160, 44, 4
local EDGE = BLOCK * GRID + BLOCK / 2

-- ========== Hilfsmittel ==========
local function teil(eltern, name, groesse, cf, farbe, material, kollision)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = kollision and true or false
	p.Size = groesse
	p.Color = farbe
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CFrame = cf
	p.Parent = eltern
	return p
end

local function kugel(eltern, name, d, cf, farbe, material)
	local p = teil(eltern, name, Vector3.new(d, d, d), cf, farbe, material)
	p.Shape = Enum.PartType.Ball
	return p
end

local function textAuf(p, text, farbe)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Top
	gui.CanvasSize = Vector2.new(400, 200)
	gui.Parent = p
	local l = Instance.new("TextLabel")
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextScaled = true
	l.Font = Enum.Font.GothamBold
	l.TextColor3 = farbe or Color3.fromRGB(255, 240, 200)
	l.Parent = gui
	return l
end

local function spielerVon(treffer)
	local figur = treffer and treffer.Parent
	if not figur then
		return nil, nil
	end
	local mensch = figur:FindFirstChildOfClass("Humanoid")
	if not mensch then
		return nil, nil
	end
	return Players:GetPlayerFromCharacter(figur), mensch
end

local function wurzelVon(spieler)
	local figur = spieler.Character
	if not figur then
		return nil
	end
	return figur:FindFirstChild("HumanoidRootPart"), figur:FindFirstChildOfClass("Humanoid")
end

-- ========== Spielstand je Spieler ==========
local daten = {}

local function muenzenAendern(spieler, n)
	local d = daten[spieler]
	if not d then
		return
	end
	d.muenzen.Value = math.max(0, d.muenzen.Value + n)
end

Players.PlayerAdded:Connect(function(spieler)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	stats.Parent = spieler

	local muenzen = Instance.new("IntValue")
	muenzen.Name = "Münzen"
	muenzen.Parent = stats

	local besiegt = Instance.new("IntValue")
	besiegt.Name = "Besiegt"
	besiegt.Parent = stats

	local aufgabe = Instance.new("StringValue")
	aufgabe.Name = "Aufgabe"
	aufgabe.Value = "Sammle 25 Münzen"
	aufgabe.Parent = spieler

	local hinweis = Instance.new("StringValue")
	hinweis.Name = "Hinweis"
	hinweis.Value = "Spring von oben auf die Frechdachse!"
	hinweis.Parent = spieler

	daten[spieler] = { muenzen = muenzen, besiegt = besiegt, aufgabe = aufgabe, hinweis = hinweis, stufe = 1, haustier = nil }
end)

Players.PlayerRemoving:Connect(function(spieler)
	local d = daten[spieler]
	if d and d.haustier then
		d.haustier:Destroy()
	end
	daten[spieler] = nil
end)

-- ========== Münzen ==========
local F_MUENZEN = Instance.new("Folder")
F_MUENZEN.Name = "Muenzen"
F_MUENZEN.Parent = welt

local muenzen = {}

local function muenzeBauen(x, z)
	local p = Instance.new("Part")
	p.Name = "Muenze"
	p.Shape = Enum.PartType.Cylinder
	p.Size = Vector3.new(0.6, 5, 5)
	p.Color = Color3.fromRGB(255, 200, 58)
	p.Material = Enum.Material.Neon
	p.Anchored = true
	p.CanCollide = false
	p.CFrame = CFrame.new(x, 4, z) * CFrame.Angles(0, 0, math.rad(90))
	p.Parent = F_MUENZEN

	local eintrag = { p = p, x = x, z = z, weg = 0 }
	muenzen[#muenzen + 1] = eintrag

	p.Touched:Connect(function(treffer)
		if eintrag.weg > 0 then
			return
		end
		local spieler = spielerVon(treffer)
		if not spieler or not daten[spieler] then
			return
		end
		eintrag.weg = 20            -- kommt nach 20 Sekunden wieder
		p.Transparency = 1
		muenzenAendern(spieler, 1)
	end)
	return eintrag
end

do
	-- Münzen entlang der Straßen verteilen
	for i = -GRID, GRID do
		for j = -GRID, GRID - 1 do
			local z = j * BLOCK + BLOCK / 2
			muenzeBauen(i * BLOCK + 11, z)
			muenzeBauen(i * BLOCK - 11, z + 40)
		end
	end
	-- ein paar im Park und am Hafen
	for i = 1, 12 do
		local a = (i / 12) * math.pi * 2
		muenzeBauen(80 + math.cos(a) * 44, 80 + math.sin(a) * 44)
	end
end

-- ========== Die Frechdachs-Bande ==========
local F_GEGNER = Instance.new("Folder")
F_GEGNER.Name = "Frechdachse"
F_GEGNER.Parent = welt

local ARTEN = {
	klaufix = { name = "Klaufix", leben = 1, tempo = 20, hoehe = 5, farbe = Color3.fromRGB(138, 74, 216), punkte = 3, klaut = true },
	kaktus = { name = "Glupsch-Kaktus", leben = 1, tempo = 12, hoehe = 6, farbe = Color3.fromRGB(58, 168, 74), punkte = 2 },
	kruemel = { name = "Torten-Krümel", leben = 2, tempo = 10, hoehe = 7, farbe = Color3.fromRGB(248, 248, 252), punkte = 4 },
	baron = { name = "Baron Blubberbauch", leben = 8, tempo = 11, hoehe = 9, farbe = Color3.fromRGB(106, 42, 138), punkte = 25, boss = true },
}

local function gegnerModell(art)
	local A = ARTEN[art]
	local m = Instance.new("Model")
	m.Name = A.name
	m.Parent = F_GEGNER

	local koerper
	if art == "klaufix" then
		koerper = kugel(m, "Koerper", 5, CFrame.new(0, 0, 0), A.farbe)
		teil(m, "Muetze", Vector3.new(4, 1.4, 4), CFrame.new(0, 2.8, 0), Color3.fromRGB(214, 62, 54))
		teil(m, "Propeller", Vector3.new(7, 0.3, 0.8), CFrame.new(0, 3.8, 0), Color3.fromRGB(255, 200, 58))
	elseif art == "kaktus" then
		koerper = teil(m, "Koerper", Vector3.new(3.6, 6, 3.6), CFrame.new(0, 0, 0), A.farbe)
		teil(m, "Topf", Vector3.new(4.4, 2.4, 4.4), CFrame.new(0, -3.6, 0), Color3.fromRGB(200, 100, 60))
		for _, s in ipairs({ -1, 1 }) do
			teil(m, "Arm", Vector3.new(1.4, 2.6, 1.4), CFrame.new(s * 2.4, 0.8, 0), A.farbe)
		end
	elseif art == "kruemel" then
		koerper = kugel(m, "Koerper", 7, CFrame.new(0, 0, 0), A.farbe)
		kugel(m, "Kopf", 4, CFrame.new(0, 4.6, 0), Color3.fromRGB(246, 212, 176))
		teil(m, "Kochmuetze", Vector3.new(3.4, 3, 3.4), CFrame.new(0, 7.4, 0), Color3.fromRGB(252, 252, 255))
		kugel(m, "Nase", 1.2, CFrame.new(0, 4.4, 2), Color3.fromRGB(230, 90, 80))
	else
		koerper = kugel(m, "Koerper", 11, CFrame.new(0, 0, 0), A.farbe)
		kugel(m, "Kopf", 5, CFrame.new(0, 7, 0), Color3.fromRGB(246, 212, 176))
		teil(m, "Krone", Vector3.new(4, 1.8, 4), CFrame.new(0, 10.2, 0), Color3.fromRGB(255, 200, 58))
		for _, s in ipairs({ -1, 1 }) do
			kugel(m, "Hand", 2.4, CFrame.new(s * 6.4, 1.6, 0), Color3.fromRGB(252, 252, 255))
		end
	end

	-- Augen
	for _, s in ipairs({ -1, 1 }) do
		local y = (art == "kruemel" or art == "baron") and (art == "baron" and 7.8 or 5.2) or 1.4
		local d = (art == "baron") and 2.8 or 1.6
		kugel(m, "Auge", d, CFrame.new(s * d * 0.6, y, (art == "baron") and 2.2 or 1.8), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic)
		kugel(m, "Pupille", d * 0.45, CFrame.new(s * d * 0.6, y, (art == "baron") and 3.3 or 2.5), Color3.fromRGB(20, 20, 24), Enum.Material.SmoothPlastic)
	end

	koerper.Name = "Koerper"
	m.PrimaryPart = koerper

	local schild = Instance.new("BillboardGui")
	schild.Size = UDim2.new(0, 160, 0, 36)
	schild.StudsOffset = Vector3.new(0, A.hoehe * 0.9, 0)
	schild.AlwaysOnTop = false
	schild.Parent = koerper
	local l = Instance.new("TextLabel")
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundTransparency = 1
	l.Text = A.name
	l.TextScaled = true
	l.Font = Enum.Font.GothamBold
	l.TextColor3 = Color3.fromRGB(255, 220, 160)
	l.Parent = schild

	return m
end

local gegner = {}

local function gegnerSetzen(art, x, z)
	local A = ARTEN[art]
	local m = gegnerModell(art)
	local g = {
		art = art, A = A, m = m, leben = A.leben,
		x = x, z = z, y = A.hoehe / 2 + 1.6,
		ph = math.random() * 6, treffer = 0, beute = 0, flucht = 0,
	}
	m:PivotTo(CFrame.new(x, g.y, z))
	gegner[#gegner + 1] = g
	return g
end

local function gegnerWeg(g, spieler)
	if g.weg then
		return
	end
	g.weg = true
	if spieler and daten[spieler] then
		daten[spieler].besiegt.Value = daten[spieler].besiegt.Value + 1
		muenzenAendern(spieler, g.A.punkte + g.beute * 2)
	end
	g.m:Destroy()
end

local function zufallsOrt()
	local i = math.random(-GRID, GRID)
	local j = math.random(-GRID, GRID - 1)
	return i * BLOCK + math.random(-14, 14), j * BLOCK + BLOCK / 2 + math.random(-50, 50)
end

for i = 1, 14 do
	local arten = { "kaktus", "kaktus", "klaufix", "kruemel" }
	local x, z = zufallsOrt()
	gegnerSetzen(arten[math.random(1, #arten)], x, z)
end

local bossDa = false

-- ========== Kauf-Pads vor der Basis ==========
local basis = welt:FindFirstChild("Basis")
local bx, bz = -BLOCK / 2 - BLOCK, -BLOCK / 2 - BLOCK
if basis and basis.PrimaryPart then
	bx, bz = basis.PrimaryPart.Position.X, basis.PrimaryPart.Position.Z
end

local F_LADEN = Instance.new("Folder")
F_LADEN.Name = "Laden"
F_LADEN.Parent = welt

local function pad(name, text, preis, abstand, farbe, wirkung)
	local p = teil(F_LADEN, name, Vector3.new(16, 1, 16), CFrame.new(bx + abstand, 2.2, bz + 40), farbe, Enum.Material.Neon, false)
	textAuf(p, text .. "\n" .. preis .. " Münzen", Color3.fromRGB(30, 20, 40))
	local wartet = {}
	p.Touched:Connect(function(treffer)
		local spieler = spielerVon(treffer)
		if not spieler or not daten[spieler] or wartet[spieler] then
			return
		end
		wartet[spieler] = true
		task.delay(1.5, function()
			wartet[spieler] = nil
		end)
		local d = daten[spieler]
		if d.muenzen.Value < preis then
			d.hinweis.Value = "Dafür brauchst du " .. preis .. " Münzen."
			return
		end
		if wirkung(spieler, d) then
			muenzenAendern(spieler, -preis)
		end
	end)
	return p
end

-- Haustier Piku
local function pikuBauen(spieler)
	local m = Instance.new("Model")
	m.Name = "Piku"
	m.Parent = welt
	local k = kugel(m, "Koerper", 4, CFrame.new(0, 3, 0), Color3.fromRGB(96, 170, 236))
	kugel(m, "Ohr1", 1.6, CFrame.new(-1.2, 5, 0), Color3.fromRGB(96, 170, 236))
	kugel(m, "Ohr2", 1.6, CFrame.new(1.2, 5, 0), Color3.fromRGB(96, 170, 236))
	kugel(m, "Auge1", 1.1, CFrame.new(-0.9, 3.4, 1.7), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic)
	kugel(m, "Auge2", 1.1, CFrame.new(0.9, 3.4, 1.7), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic)
	m.PrimaryPart = k
	return m
end

pad("PadHaustier", "HAUSTIER PIKU", 30, -40, Color3.fromRGB(96, 170, 236), function(spieler, d)
	if d.haustier then
		d.hinweis.Value = "Piku ist schon bei dir."
		return false
	end
	d.haustier = pikuBauen(spieler)
	d.hinweis.Value = "Piku folgt dir jetzt!"
	return true
end)

pad("PadKrone", "GOLDENE KRONE", 60, -14, Color3.fromRGB(255, 200, 58), function(spieler, d)
	local wurzel, mensch = wurzelVon(spieler)
	if not wurzel then
		return false
	end
	local kopf = spieler.Character:FindFirstChild("Head")
	if not kopf or kopf:FindFirstChild("Krone") then
		return false
	end
	local k = Instance.new("Part")
	k.Name = "Krone"
	k.Size = Vector3.new(2.4, 1.2, 2.4)
	k.Color = Color3.fromRGB(255, 200, 58)
	k.Material = Enum.Material.Neon
	k.CanCollide = false
	k.Massless = true
	k.CFrame = kopf.CFrame * CFrame.new(0, 1.2, 0)
	k.Parent = kopf
	local w = Instance.new("WeldConstraint")
	w.Part0 = kopf
	w.Part1 = k
	w.Parent = k
	d.hinweis.Value = "Schicke Krone!"
	return true
end)

pad("PadSchuhe", "TURBOSCHUHE", 45, 14, Color3.fromRGB(255, 120, 60), function(spieler, d)
	local _, mensch = wurzelVon(spieler)
	if not mensch then
		return false
	end
	if mensch.WalkSpeed >= 32 then
		d.hinweis.Value = "Du bist schon so schnell wie möglich."
		return false
	end
	mensch.WalkSpeed = 32
	d.schnell = true
	d.hinweis.Value = "Turboschuhe an!"
	return true
end)

pad("PadLeben", "EXTRA LEBEN", 80, 42, Color3.fromRGB(80, 220, 120), function(spieler, d)
	local _, mensch = wurzelVon(spieler)
	if not mensch then
		return false
	end
	if mensch.MaxHealth >= 200 then
		d.hinweis.Value = "Mehr Leben geht nicht."
		return false
	end
	mensch.MaxHealth = 200
	mensch.Health = 200
	d.stark = true
	d.hinweis.Value = "Du hast jetzt 200 Leben!"
	return true
end)

-- Beim Nachleben die Käufe wiederherstellen
Players.PlayerAdded:Connect(function(spieler)
	spieler.CharacterAdded:Connect(function(figur)
		local mensch = figur:WaitForChild("Humanoid", 10)
		local d = daten[spieler]
		if mensch and d then
			if d.schnell then
				mensch.WalkSpeed = 32
			end
			if d.stark then
				mensch.MaxHealth = 200
				mensch.Health = 200
			end
		end
	end)
end)

-- ========== Aufgaben ==========
local AUFGABEN = {
	{ text = "Sammle 25 Münzen", fertig = function(d) return d.muenzen.Value >= 25 end, lohn = 20 },
	{ text = "Besiege 5 Frechdachse", fertig = function(d) return d.besiegt.Value >= 5 end, lohn = 30 },
	{ text = "Kauf dir Piku für 30 Münzen", fertig = function(d) return d.haustier ~= nil end, lohn = 40 },
	{ text = "Besiege Baron Blubberbauch", fertig = function(d) return d.bossBesiegt end, lohn = 100 },
	{ text = "Alles geschafft – spiel einfach weiter!", fertig = function() return false end, lohn = 0 },
}

local function aufgabenPruefen()
	for spieler, d in pairs(daten) do
		local a = AUFGABEN[d.stufe]
		if a and a.fertig(d) then
			muenzenAendern(spieler, a.lohn)
			d.stufe = math.min(d.stufe + 1, #AUFGABEN)
			d.aufgabe.Value = AUFGABEN[d.stufe].text
			d.hinweis.Value = "Aufgabe geschafft! +" .. a.lohn .. " Münzen"
		end
	end
end

-- ========== Zug im Umland ==========
local zug
do
	local m = Instance.new("Model")
	m.Name = "PikuExpress"
	m.Parent = welt
	local lok = teil(m, "Lok", Vector3.new(10, 12, 24), CFrame.new(0, 7, 0), Color3.fromRGB(198, 62, 54), Enum.Material.Metal, false)
	teil(m, "Schlot", Vector3.new(3, 5, 3), CFrame.new(0, 15, 8), Color3.fromRGB(50, 50, 58), Enum.Material.Metal, false)
	m.PrimaryPart = lok
	for i = 1, 3 do
		teil(m, "Wagen", Vector3.new(10, 10, 22), CFrame.new(0, 6, -i * 26), Color3.fromRGB(70, 130, 180), Enum.Material.Metal, false)
	end
	zug = { m = m, t = 0 }
	-- Schienen
	for i = -30, 30 do
		teil(welt, "Schwelle", Vector3.new(14, 0.6, 3), CFrame.new(-EDGE - 120, 1, i * 20), Color3.fromRGB(96, 70, 48), Enum.Material.Wood, false)
	end
end

-- ========== Takt ==========
local zeit = 0
local pruefUhr = 0

local function takt(dt)
	zeit = zeit + dt
	pruefUhr = pruefUhr + dt

	-- Münzen drehen und zurückkommen lassen
	for _, e in ipairs(muenzen) do
		if e.weg > 0 then
			e.weg = e.weg - dt
			if e.weg <= 0 then
				e.weg = 0
				e.p.Transparency = 0
			end
		else
			e.p.CFrame = CFrame.new(e.x, 4 + math.sin(zeit * 2 + e.x) * 0.4, e.z)
				* CFrame.Angles(0, zeit * 2, 0) * CFrame.Angles(0, 0, math.rad(90))
		end
	end

	-- Gegner bewegen
	for i = #gegner, 1, -1 do
		local g = gegner[i]
		if g.weg or not g.m.Parent then
			table.remove(gegner, i)
		else
			local zielSpieler, zielWurzel, zielDist = nil, nil, 1e9
			for spieler, _ in pairs(daten) do
				local wurzel = wurzelVon(spieler)
				if wurzel then
					local d = (Vector3.new(g.x, 0, g.z) - Vector3.new(wurzel.Position.X, 0, wurzel.Position.Z)).Magnitude
					if d < zielDist then
						zielDist, zielSpieler, zielWurzel = d, spieler, wurzel
					end
				end
			end

			g.ph = g.ph + dt * (g.art == "kaktus" and 6 or 3)
			local richtung = 0

			if zielWurzel and zielDist < 160 then
				local dx = zielWurzel.Position.X - g.x
				local dz = zielWurzel.Position.Z - g.z
				local laenge = math.max(0.001, math.sqrt(dx * dx + dz * dz))
				local vz = (g.flucht > 0) and -1 or 1
				if g.flucht > 0 then
					g.flucht = g.flucht - dt
				end
				local tempo = g.A.tempo * ((g.flucht > 0) and 1.3 or 1)
				g.x = g.x + dx / laenge * tempo * dt * vz
				g.z = g.z + dz / laenge * tempo * dt * vz
				richtung = math.atan2(dx * vz, dz * vz)

				-- Treffer prüfen
				g.treffer = math.max(0, g.treffer - dt)
				if zielDist < 7 and g.treffer <= 0 then
					local _, mensch = wurzelVon(zielSpieler)
					local obenDrauf = zielWurzel.Position.Y > g.y + g.A.hoehe * 0.2   -- von oben = besiegt
					if obenDrauf then
						g.leben = g.leben - 1
						g.treffer = 0.6
						zielWurzel.AssemblyLinearVelocity = Vector3.new(0, 60, 0)   -- Abprall nach oben
						if g.leben <= 0 then
							if g.A.boss then
								local d = daten[zielSpieler]
								if d then
									d.bossBesiegt = true
								end
								bossDa = false
							end
							gegnerWeg(g, zielSpieler)
						end
					elseif mensch then
						g.treffer = 1.2
						mensch:TakeDamage(g.A.boss and 20 or 10)
						if g.A.klaut and daten[zielSpieler] and daten[zielSpieler].muenzen.Value > 0 then
							local n = math.min(daten[zielSpieler].muenzen.Value, 5)
							muenzenAendern(zielSpieler, -n)
							g.beute = g.beute + n
							g.flucht = 6
							daten[zielSpieler].hinweis.Value = "Klaufix hat dir " .. n .. " Münzen geklaut!"
						end
					end
				end
			else
				richtung = g.ph * 0.2
				g.x = g.x + math.sin(g.ph * 0.3) * dt * 6
			end

			local hub = (g.art == "kaktus") and math.abs(math.sin(g.ph)) * 3 or math.sin(g.ph) * 0.6
			g.m:PivotTo(CFrame.new(g.x, g.y + hub, g.z) * CFrame.Angles(0, richtung, 0))
		end
	end

	-- Zug fahren lassen
	if zug and zug.m.Parent then
		zug.t = zug.t + dt * 40
		local z = ((zug.t % 1200) - 600)
		zug.m:PivotTo(CFrame.new(-EDGE - 120, 7, z))
	end

	-- alle halbe Sekunde: Aufgaben, Nachschub, Boss
	if pruefUhr >= 0.5 then
		pruefUhr = 0
		aufgabenPruefen()

		if #gegner < 14 then
			local arten = { "kaktus", "klaufix", "kruemel" }
			local x, z = zufallsOrt()
			gegnerSetzen(arten[math.random(1, #arten)], x, z)
		end

		if not bossDa then
			for _, d in pairs(daten) do
				if d.muenzen.Value >= 50 and not d.bossBesiegt then
					bossDa = true
					local x, z = zufallsOrt()
					gegnerSetzen("baron", x, z)
					d.hinweis.Value = "Baron Blubberbauch ist in der Stadt!"
					break
				end
			end
		end

		-- Haustier hinterherlaufen lassen
		for spieler, d in pairs(daten) do
			if d.haustier and d.haustier.Parent then
				local wurzel = wurzelVon(spieler)
				if wurzel then
					local ziel = wurzel.CFrame * CFrame.new(-4, -1.5, 5)
					local jetzt = d.haustier:GetPivot()
					d.haustier:PivotTo(jetzt:Lerp(ziel, 0.35))
				end
			end
		end
	end

	-- Tag und Nacht
	Lighting.ClockTime = (Lighting.ClockTime + dt * 0.02) % 24
end

RunService.Heartbeat:Connect(function(dt)
	local ok, fehler = pcall(takt, dt)
	if not ok then
		warn("Pikumio: " .. tostring(fehler))
	end
end)

print("Pikumio-Spiel läuft: " .. #muenzen .. " Münzen, " .. #gegner .. " Frechdachse")
