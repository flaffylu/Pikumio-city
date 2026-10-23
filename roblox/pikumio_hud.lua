--[[
	PIKUMIO CITY  ·  Anzeige und Autofahren
	---------------------------------------
	Wohin damit:
	  Explorer → StarterPlayer → StarterPlayerScripts → Rechtsklick
	  → "LocalScript einfügen" → Inhalt durch dieses Skript ersetzen.

	(Ersetzt das alte "pikumio_auto.lua" – das Fahren steckt hier mit drin.)

	Steuern:  W Gas · S Bremse und rückwärts · A/D lenken · Leertaste aussteigen.
	Gegner besiegst du, indem du von oben auf sie springst.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local spieler = Players.LocalPlayer
local anzeige = spieler:WaitForChild("PlayerGui")

-- ========== Anzeige ==========
local gui = Instance.new("ScreenGui")
gui.Name = "PikumioHud"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = anzeige

local function label(groesse, pos, text, schrift, farbe, rechts)
	local l = Instance.new("TextLabel")
	l.Size = groesse
	l.Position = pos
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextSize = schrift
	l.Font = Enum.Font.GothamBold
	l.TextColor3 = farbe or Color3.fromRGB(255, 246, 234)
	l.TextXAlignment = rechts and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left
	l.TextStrokeTransparency = 0.4
	l.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	l.Parent = gui
	return l
end

local muenzText = label(UDim2.new(0, 320, 0, 44), UDim2.new(0, 18, 0, 14), "0 Münzen", 30, Color3.fromRGB(255, 200, 58))
local aufgabeText = label(UDim2.new(0, 460, 0, 28), UDim2.new(0, 18, 0, 58), "", 20)
local hinweisText = label(UDim2.new(0, 560, 0, 26), UDim2.new(0, 18, 0, 86), "", 18, Color3.fromRGB(180, 230, 255))
local tempoText = label(UDim2.new(0, 220, 0, 40), UDim2.new(1, -236, 0, 14), "", 28, Color3.fromRGB(255, 246, 234), true)

local function verbinde()
	local stats = spieler:WaitForChild("leaderstats", 20)
	if stats then
		local m = stats:WaitForChild("Münzen", 20)
		if m then
			local function zeige()
				muenzText.Text = m.Value .. (m.Value == 1 and " Münze" or " Münzen")
			end
			zeige()
			m.Changed:Connect(zeige)
		end
	end
	local a = spieler:WaitForChild("Aufgabe", 20)
	if a then
		local function zeige()
			aufgabeText.Text = "Aufgabe: " .. a.Value
		end
		zeige()
		a.Changed:Connect(zeige)
	end
	local h = spieler:WaitForChild("Hinweis", 20)
	if h then
		local function zeige()
			hinweisText.Text = h.Value
			task.delay(6, function()
				if hinweisText.Text == h.Value then
					hinweisText.Text = ""
				end
			end)
		end
		zeige()
		h.Changed:Connect(zeige)
	end
end
task.spawn(verbinde)

-- ========== Autofahren ==========
local TEMPO = 85
local RUECKWAERTS = 35
local LENKUNG = 2.0
local ZUG = 3.0
local BREMSE = 2.2

local tempo = 0

RunService.Heartbeat:Connect(function(dt)
	local figur = spieler.Character
	local mensch = figur and figur:FindFirstChildOfClass("Humanoid")
	local sitz = mensch and mensch.SeatPart

	if not (sitz and sitz:IsA("VehicleSeat") and sitz.Name == "Fahrersitz") then
		tempo = 0
		if tempoText.Text ~= "" then
			tempoText.Text = ""
		end
		return
	end

	local wurzel = sitz.AssemblyRootPart
	if not wurzel then
		return
	end

	local gas = sitz.Throttle
	if math.abs(gas) > 0.05 then
		local ziel = gas * ((gas >= 0) and TEMPO or RUECKWAERTS)
		tempo = tempo + (ziel - tempo) * math.min(1, dt * ZUG)
	else
		tempo = tempo * (1 - math.min(1, dt * BREMSE))
	end

	local blick = sitz.CFrame.LookVector
	local alt = wurzel.AssemblyLinearVelocity
	-- Bordsteine schleuderten das Auto hoch: beim Fahren darf es nicht nach oben schnellen.
	-- Fallen (negative Werte) bleibt erlaubt, damit es Hügel und Abhänge noch kann.
	local hoch = alt.Y
	if math.abs(tempo) > 3 and hoch > 2 then
		hoch = 2
	end
	wurzel.AssemblyLinearVelocity = Vector3.new(blick.X * tempo, hoch, blick.Z * tempo)

	local wirkung = math.min(1, math.abs(tempo) / 16)
	local richtung = (tempo < -0.5) and -1 or 1
	wurzel.AssemblyAngularVelocity = Vector3.new(0, -sitz.Steer * LENKUNG * wirkung * richtung, 0)

	tempoText.Text = math.floor(math.abs(tempo) * 0.6) .. " km/h"
end)
