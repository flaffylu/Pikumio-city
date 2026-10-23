--[[
	PIKUMIO CITY  ·  Autos fahren
	-----------------------------
	Wohin damit (wichtig, sonst fährt nichts):
	  Explorer → StarterPlayer → StarterPlayerScripts
	  → Rechtsklick → "LocalScript einfügen"
	  → den Inhalt durch dieses Skript ersetzen
	  → oben auf Play drücken.

	Warum ein LocalScript? Sobald du dich in ein Auto setzt, steuert dein eigener
	Rechner die Fahrphysik. Ein Skript auf dem Server würde dagegen ankämpfen und
	das Auto würde ruckeln.

	Steuern:  W Gas · S Bremse und rückwärts · A/D lenken · Leertaste aussteigen.
	Einsteigen: zum Auto laufen und den Sitz antippen.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local TEMPO = 85          -- Höchstgeschwindigkeit vorwärts (Studs pro Sekunde)
local RUECKWAERTS = 35    -- rückwärts langsamer
local LENKUNG = 2.0       -- wie schnell sich das Auto dreht
local ZUG = 3.0           -- wie schnell es auf Touren kommt
local BREMSE = 2.2        -- wie schnell es ausrollt

local spieler = Players.LocalPlayer
local tempo = 0

RunService.Heartbeat:Connect(function(dt)
	local figur = spieler.Character
	local mensch = figur and figur:FindFirstChildOfClass("Humanoid")
	local sitz = mensch and mensch.SeatPart

	if not (sitz and sitz:IsA("VehicleSeat") and sitz.Name == "Fahrersitz") then
		tempo = 0
		return
	end

	local wurzel = sitz.AssemblyRootPart
	if not wurzel then
		return
	end

	-- Gas geben oder ausrollen
	local gas = sitz.Throttle
	if math.abs(gas) > 0.05 then
		local ziel = gas * ((gas >= 0) and TEMPO or RUECKWAERTS)
		tempo = tempo + (ziel - tempo) * math.min(1, dt * ZUG)
	else
		tempo = tempo * (1 - math.min(1, dt * BREMSE))
	end

	-- vorwärts schieben, Fallen nach unten nicht stören
	local blick = sitz.CFrame.LookVector
	local alt = wurzel.AssemblyLinearVelocity
	wurzel.AssemblyLinearVelocity = Vector3.new(blick.X * tempo, alt.Y, blick.Z * tempo)

	-- Lenken wirkt nur, wenn das Auto rollt; rückwärts andersherum
	local wirkung = math.min(1, math.abs(tempo) / 16)
	local richtung = (tempo < -0.5) and -1 or 1
	wurzel.AssemblyAngularVelocity = Vector3.new(0, -sitz.Steer * LENKUNG * wirkung * richtung, 0)
end)
