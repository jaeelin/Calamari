--[[
    JOIN CALAMARI.XXX > discord.com/invite/jWXrcr74a9
]]

getgenv().Core = {}

local Core = getgenv().Core

Core.Version = "1.0.1"
Core.Loaded = true

Core.Services = {}
Core.Features = {}
Core.Connections = {}
Core.Keybinds = {}
Core.Hooks = {}

local Services = Core.Services

Services.Players = game:GetService("Players")
Services.RunService = game:GetService("RunService")
Services.ReplicatedStorage = game:GetService("ReplicatedStorage")
Services.UserInputService = game:GetService("UserInputService")
Services.VirtualInputManager = game:GetService("VirtualInputManager")
Services.TeleportService = game:GetService("TeleportService")

local LocalPlayer = Services.Players.LocalPlayer

local Camera = workspace.CurrentCamera

local PlayerESPLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/jaeelin/Ascendent-ESP/refs/heads/main/PlayerESP.lua"))()
local Calamari = loadstring(game:HttpGet("https://raw.githubusercontent.com/jaeelin/Improved-Scripts/refs/heads/main/Calamari.lua"))()

--[[ FEATURE SETUP ]]--

Core.Features.KillAll = {
	Enabled = false
}

Core.Features.KnifeAura = {
	Enabled = false,
	Range = 300,
	WallCheck = false,
	Priority = "Character"
}

Core.Features.AimAssist = {
	Enabled = false,
	TargetPart = "Head",
	Strength = 0.5,
	Smoothness = 0.5,
	Range = 500,
	WallCheck = true,
	TeamCheck = true,
	Priority = "Camera"
}

Core.Features.SilentAim = {
	Enabled = false,
	Range = 300,
	WallCheck = true,
	Priority = "Camera",
	Hook = nil
}

Core.Features.Flight = {
	Enabled = false,
	VerticalSpeed = 50,
	HorizontalSpeed = 50
}

Core.Features.Walkspeed = {
	Enabled = false,
	Speed = 20
}

Core.Features.FOV = {
	Enabled = false,
	Value = 70
}

Core.Features.Gravity = {
	Enabled = false,
	Value = 196.2
}

Core.Features.JumpPower = {
	Enabled = false,
	Power = 50
}

Core.Features.Phase = {
	Enabled = false,
	OriginalCollision = {}
}

Core.Features.LongJump = {
	Enabled = false,
	Height = 50,
	Boost = 50
}

Core.Features.WallClimb = {
	Enabled = false,
	Speed = 50
}

Core.Features.SpinBot = {
	Enabled = false,
	Speed = 50
}

Core.Features.BunnyHop = {
	Enabled = false,
	Speed = 50
}

Core.Features.PlayerESP = {
	ESPInstance = nil,
	Enabled = false,
	TeamCheck = false,
	Box = false,
	Tracer = false,
	Skeleton = false,
	Arrow = false,
	Name = false,
	Rainbow = false,
	DefaultColor = Color3.fromRGB(255, 255, 255),
	MaxDistance = 1000
}

Core.Features.RainbowHUD = {
	Enabled = false
}

Core.Features.GunCustomizer = {
	Enabled = false,
	Rainbow = false,
	Material = "Plastic",
	Transparency = 0,
	Appearances = {},
	OriginalProperties = {},
	Model = nil,
	LastModel = nil
}

Core.Features.KnifeCustomizer = {
	Enabled = false,
	Rainbow = false,
	Material = "Plastic",
	Transparency = 0,
	Appearances = {},
	OriginalProperties = {},
	Model = nil,
	LastModel = nil
}

Core.Config = {
	Selected = nil,
	NameInput = ""
}

Core.Variables = {
	Remotes = Services.ReplicatedStorage:WaitForChild("Remotes"),
}

--[[ TABLES ]]--

local Materials = {}

for _, material in next, Enum.Material:GetEnumItems() do
	table.insert(Materials, material.Name)
end

--[[ UTILITIES ]]--

function Core:GetCharacter(Player: Player)
	Player = Player or LocalPlayer

	local character = Player.Character
	if not character then return end

	local root = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if not root or not humanoid then return end

	return character, humanoid, root
end

function Core:GetClosest(Values: any)
	local closest_target = nil
	local shortest = math.huge

	local character = LocalPlayer.Character
	if not character then return end

	local humanoid_root_part = character.FindFirstChild(character, "HumanoidRootPart")
	if not humanoid_root_part then return end

	for _, target in next, Services.Players.GetPlayers(Services.Players) do
		if target == LocalPlayer then continue end
		
		if Values.TeamCheck and (target.Team == LocalPlayer.Team) then continue end

		local target_character = target.Character
		if not target_character then continue end

		local target_humanoid_root_part = target_character.FindFirstChild(target_character, "HumanoidRootPart")
		if not target_humanoid_root_part then continue end

		local target_humanoid = target_character.FindFirstChild(target_character, "Humanoid")
		if not target_humanoid then continue end

		if target_humanoid.Health <= 0 then continue end

		local world_distance = (humanoid_root_part.Position - target_humanoid_root_part.Position).Magnitude
		if world_distance > Values.Range then
			continue
		end

		if Values.WallCheck then
			local raycast_parameters = RaycastParams.new()
			raycast_parameters.FilterDescendantsInstances = {character}
			raycast_parameters.FilterType = Enum.RaycastFilterType.Exclude

			local direction = target_humanoid_root_part.Position - humanoid_root_part.Position
			local raycast_result = workspace.Raycast(workspace, humanoid_root_part.Position, direction, raycast_parameters)

			if raycast_result and raycast_result.Instance and not raycast_result.Instance.IsDescendantOf(raycast_result.Instance, target_character) then
				continue
			end
		end

		local distance
		if Values.Priority == "Camera" then
			local screen_position, on_screen = Camera.WorldToViewportPoint(Camera, target_humanoid_root_part.Position)
			if not on_screen then
				continue
			end

			distance = (Vector2.new(screen_position.X, screen_position.Y) - Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)).Magnitude
		elseif Values.Priority == "Mouse" then
			local screen_position, on_screen = Camera.WorldToViewportPoint(Camera, target_humanoid_root_part.Position)
			if not on_screen then continue end

			local mouse = LocalPlayer.GetMouse(LocalPlayer)
			local mouse_position = Vector2.new(mouse.X, mouse.Y)

			distance = (Vector2.new(screen_position.X, screen_position.Y) - mouse_position).Magnitude
		else
			distance = world_distance
		end

		if distance < shortest then
			shortest = distance
			closest_target = target
		end
	end

	return closest_target
end

function Core:GetParts(Player: Player)
	local character = Player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local humanoid_root_part = character:FindFirstChild("HumanoidRootPart")
	if not humanoid_root_part then return end

	return character, humanoid, humanoid_root_part
end

function Core:RefreshConfigs(dropdown)
	dropdown:ClearOptions()
	dropdown:InsertOptions(Calamari:RefreshConfigList() or {})
end

local function GetHumanoid()
	local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

	return character:WaitForChild("Humanoid")
end

function Core.Features.AimAssist:GetTargetPart(Character: Model)
	local part = Core.Features.AimAssist.TargetPart
	
	if part == "Random" then
		local limbs = {
			"Head",
			"Torso",
			"Left Arm",
			"Right Arm",
			"Left Leg",
			"Right Leg"
		}

		part = limbs[math.random(1, #limbs)]
	end
	
	local part = Character:FindFirstChild(part)
	
	if not part then
		part = Character:FindFirstChild("HumanoidRootPart")
	end

	return part
end

local function StripAppearances(self, Model: Model)
	for _, object in next, Model:GetDescendants() do
		if object:IsA("SurfaceAppearance") then
			table.insert(self.Appearances, {
				instance = object,
				parent = object.Parent
			})
			object.Parent = nil
		end

		if object:IsA("BasePart") then
			self.OriginalProperties[object] = {
				Transparency = object.Transparency,
				Material = object.Material,
				Color = object.Color
			}
		end
	end
end

local function RestoreAppearances(self)
	for _, data in next, self.Appearances do
		if data.instance and data.parent then
			data.instance.Parent = data.parent
		end
	end

	for part, properties in next, self.OriginalProperties do
		if part and part.Parent then
			part.Transparency = properties.Transparency
			part.Material = properties.Material
			part.Color = properties.Color
		end
	end
end

function Core.Features.GunCustomizer:StripAppearances(Model: Model)
	StripAppearances(self, Model)
end

function Core.Features.GunCustomizer:RestoreAppearances()
	RestoreAppearances(self)
end

function Core.Features.KnifeCustomizer:StripAppearances(Model: Model)
	StripAppearances(self, Model)
end

function Core.Features.KnifeCustomizer:RestoreAppearances()
	RestoreAppearances(self)
end

--[[ FEATURES ]]--

local folder_name = "Calamari/9561553764"

local window = Calamari:Window({
	Title = "Calamari",
	Subtitle = "Premium Script – v" .. Core.Version,
	Size = Services.UserInputService.TouchEnabled and UDim2.fromOffset(600, 400) or UDim2.fromOffset(800, 600),
	DragStyle = 1,
	ShowUserInfo = true,
	Keybind = Enum.KeyCode.RightAlt,
	AcrylicBlur = true,
})

Calamari:SetFolder(folder_name)

local main_group = window:TabGroup()

local tabs = {
	Main = main_group:Tab({Name = "Main", Image = "rbxassetid://4034483344"}),
	Mobility = main_group:Tab({Name = "Mobility", Image = "rbxassetid://7992557358"}),
	Render = main_group:Tab({Name = "Render", Image = "rbxassetid://6523858394"}),
	Settings = main_group:Tab({Name = "Settings", Image = "rbxassetid://132848201849699"}),
}

local sections = {
	main_left = tabs.Main:Section({ Side = "Left" }),
	main_left_bottom = tabs.Main:Section({ Side = "Left" }),
	main_right = tabs.Main:Section({ Side = "Right" }),
	main_right_bottom= tabs.Main:Section({ Side = "Right" }),
	mobility_left = tabs.Mobility:Section({ Side = "Left" }),
	mobility_right = tabs.Mobility:Section({ Side = "Right" }),
	mobility_right2 = tabs.Mobility:Section({ Side = "Right" }),
	mobility_right3 = tabs.Mobility:Section({ Side = "Right" }),
	mobility_right4 = tabs.Mobility:Section({ Side = "Right" }),
	mobility_right5 = tabs.Mobility:Section({ Side = "Right" }),
	render_left = tabs.Render:Section({ Side = "Left" }),
	render_left_bottom = tabs.Render:Section({ Side = "Left" }),
	render_right = tabs.Render:Section({ Side = "Right" }),
	render_right_bottom = tabs.Render:Section({ Side = "Right" }),
	settings_left = tabs.Settings:Section({ Side = "Left" }),
	settings_right = tabs.Settings:Section({ Side = "Right" })
}

tabs.Main:Select()

local global_settings = {
	UIBlurToggle = window:GlobalSetting({
		Name = "UI Blur",
		Default = window:GetAcrylicBlurState(),
		Callback = function(bool)
			window:SetAcrylicBlurState(bool)
			window:Notify({
				Title = window.Settings.Title,
				Description = (bool and "Enabled" or "Disabled") .. " UI Blur",
				Lifetime = 5
			})
		end,
	}),

	NotificationToggler = window:GlobalSetting({
		Name = "Notifications",
		Default = window:GetNotificationsState(),
		Callback = function(bool)
			window:SetNotificationsState(bool)
			window:Notify({
				Title = window.Settings.Title,
				Description = (bool and "Enabled" or "Disabled") .. " Notifications",
				Lifetime = 5
			})
		end,
	}),

	ShowUserInfo = window:GlobalSetting({
		Name = "Show User Info",
		Default = window:GetUserInfoState(),
		Callback = function(bool)
			window:SetUserInfoState(bool)
			window:Notify({
				Title = window.Settings.Title,
				Description = (bool and "Showing" or "Redacted") .. " User Info",
				Lifetime = 5
			})
		end,
	})
}

--[[ COMBAT ]]--

KillAll = sections.main_left:Toggle({
	Name = "Kill All",
	Default = Core.Features.KillAll.Enabled,
	Callback = function(state)
		Core.Features.KillAll.Enabled = state

		if state then
			Core.Connections.KillAll = Services.RunService.PreRender:Connect(function(delta)
				local shoot_replicate = Core.Variables.Remotes:WaitForChild("ShootReplicate")
				if not shoot_replicate then return end
				
				local report_hit = Core.Variables.Remotes:WaitForChild("ReportHit")
				if not report_hit then return end

				local match_id = LocalPlayer:GetAttribute("MatchId")
				if not match_id then return end

				if not LocalPlayer:GetAttribute("Alive") then return end

				for _, enemy in next, Services.Players:GetPlayers() do
					if enemy ~= LocalPlayer 
						and enemy.TeamColor ~= LocalPlayer.TeamColor
						and enemy:GetAttribute("MatchId") == match_id
						and enemy:GetAttribute("Alive") then
						
						local enemy_character = enemy.Character
						if not enemy_character then continue end
						
						local torso = enemy_character:FindFirstChild("Torso")
						if not torso then continue end
						
						local pivot = enemy_character:GetPivot().Position

						shoot_replicate:FireServer({
							hitPos = pivot,
							to = pivot,
							hitInstance = torso,
							id = 4,
							hitNormal = Vector3.new(0.0474, 0, -0.9988),
							effects = { Frost = 0, Ricochet = 0, Barrage = 0 },
							isCharacterHit = true,
							kind = "bullet",
							mode = "single",
							ownerUserId = LocalPlayer.UserId,
							isADS = false
						})

						report_hit:FireServer({
							hitPos = pivot,
							to = pivot,
							origin = pivot,
							vel = Vector3.new(-369.498, -26.926, -192.132),
							headshot = true,
							targetUserId = enemy.UserId,
							hitPart = torso,
							at = tick(),
							throwId = 18,
							kind = "throw",
							ownerUserId = LocalPlayer.UserId,
							targetModel = enemy_character
						})
					end
				end

			end)
		else
			if Core.Connections.KillAll then
				Core.Connections.KillAll:Disconnect()
				Core.Connections.KillAll = nil
			end
		end
	end,
}, "KillAll")

Core.Keybinds.KillAllKeybind = sections.main_left:Keybind({
	Name = "Kill All Keybind",
	Blacklist = false,
	onBindHeld = function(held)
		if held then
			Core.Features.KillAll.Enabled = not Core.Features.KillAll.Enabled
			KillAll:UpdateState(Core.Features.KillAll.Enabled)
		end
	end,
}, "KillAllKeybind")

KnifeAura = sections.main_left_bottom:Toggle({
	Name = "Knife Aura",
	Default = Core.Features.KnifeAura.Enabled,
	Callback = function(state)
		Core.Features.KnifeAura.Enabled = state

		if state then
			Core.Connections.KnifeAura = Services.RunService.PreRender:Connect(function(delta)
				local report_hit = Core.Variables.Remotes:FindFirstChild("ReportHit")
				if not report_hit then return end
				
				local closest = Core:GetClosest({
					Range = Core.Features.KnifeAura.Range,
					WallCheck = Core.Features.KnifeAura.WallCheck,
					Priority = Core.Features.KnifeAura.Priority,
					TeamCheck = true
				})
				
				if not closest then return end
				
				local character = closest.Character
				if not character then return end
				
				local root = character:FindFirstChild("HumanoidRootPart")
				if not root then return end
				
				local fake_position = root.Position + root.CFrame.LookVector * 5 + Vector3.new(math.random() *0.2, 0, math.random() *0.2)
				local fake_cframe = CFrame.lookAt(fake_position, root.Position)

				local look_vector = fake_cframe.LookVector

				local arguments = {
					{
						at = workspace:GetServerTimeNow(),
						targetUserId = 0,
						backstab = true,
						kind = "melee",
						targetModel = character,
						direction = look_vector
					}
				}
				
				report_hit:FireServer(unpack(arguments))
			end)
		else
			if Core.Connections.KnifeAura then
				Core.Connections.KnifeAura:Disconnect()
				Core.Connections.KnifeAura = nil
			end
		end
	end,
}, "KnifeAura")

sections.main_left_bottom:Slider({
	Name = "Knife Aura Range",
	Default = Core.Features.KnifeAura.Range,
	Minimum = 1,
	Maximum = 500,
	DisplayMethod = "Value",
	Precision = 1,
	Callback = function(value)
		Core.Features.KnifeAura.Range = value
	end
}, "KnifeAuraRange")

sections.main_left_bottom:Toggle({
	Name = "Knife Aura Wall Check",
	Default = Core.Features.KnifeAura.WallCheck,
	Callback = function(value)
		Core.Features.KnifeAura.WallCheck = value
	end
}, "KnifeAuraWallCheck")

sections.main_left_bottom:Dropdown({
	Name = "Knife Aura Priority",
	Options = {"Camera", "Mouse", "Character"},
	Default = 1,
	Callback = function(value)
		Core.Features.KnifeAura.Priority = value
	end
}, "KnifeAuraPriority")

Core.Keybinds.KnifeAuraKeybind = sections.main_left_bottom:Keybind({
	Name = "Knife Aura Keybind",
	Blacklist = false,
	onBindHeld = function(held)
		if held then
			Core.Features.KnifeAura.Enabled = not Core.Features.KnifeAura.Enabled
			KnifeAura:UpdateState(Core.Features.KnifeAura.Enabled)
		end
	end,
}, "KnifeAuraKeybind")

AimAssist = sections.main_right_bottom:Toggle({
	Name = "Aim Assist",
	Default = Core.Features.AimAssist.Enabled,
	Callback = function(state)
		Core.Features.AimAssist.Enabled = state

		if state then
			Core.Connections.AimAssist = Services.RunService.PreRender:Connect(function(delta)
				local closest = Core:GetClosest({
					Range = Core.Features.AimAssist.Range,
					WallCheck = Core.Features.AimAssist.WallCheck,
					Priority = Core.Features.AimAssist.Priority,
					TeamCheck = Core.Features.AimAssist.TeamCheck
				})

				if not closest then return end

				local character = closest.Character
				if not character then return end

				local part = Core.Features.AimAssist:GetTargetPart(character)
				if not part then return end
				
				local screen_position, on_screen = Camera:WorldToViewportPoint(part.Position)
				if not on_screen then return end
				
				local screen_position, on_screen = Camera:WorldToViewportPoint(part.Position)
				if not on_screen then return end

				local strength = Core.Features.AimAssist.Strength
				local smoothness = Core.Features.AimAssist.Smoothness
				
				local dx = (screen_position.X - Camera.ViewportSize.X / 2)
				local dy = (screen_position.Y - Camera.ViewportSize.Y / 2)
				
				dx = math.clamp(dx, -25, 25)
				dy = math.clamp(dy, -25, 25)
				
				dx = dx * smoothness * strength
				dy = dy * smoothness * strength

				mousemoverel(dx, dy)
			end)
		else
			if Core.Connections.AimAssist then
				Core.Connections.AimAssist:Disconnect()
				Core.Connections.AimAssist = nil
			end
		end
	end,
}, "AimAssist")

sections.main_right_bottom:Dropdown({
	Name = "Aim Assist Target Part",
	Options = {"Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg", "Random"},
	Default = 1,
	Callback = function(value)
		Core.Features.AimAssist.TargetPart = value
	end
}, "AimAssistTargetPart")

sections.main_right_bottom:Slider({
	Name = "Aim Assist Strength",
	Default = Core.Features.AimAssist.Strength,
	Minimum = 0,
	Maximum = 1,
	DisplayMethod = "Value",
	Precision = 1,
	Callback = function(value)
		Core.Features.AimAssist.Strength = value
	end
}, "AimAssistStrength")

sections.main_right_bottom:Slider({
	Name = "Aim Assist Smoothness",
	Default = Core.Features.AimAssist.Smoothness,
	Minimum = 0,
	Maximum = 1,
	DisplayMethod = "Value",
	Precision = 1,
	Callback = function(value)
		Core.Features.AimAssist.Smoothness = value
	end
}, "AimAssistSmoothness")

sections.main_right_bottom:Toggle({
	Name = "Aim Assist Wall Check",
	Default = Core.Features.AimAssist.WallCheck,
	Callback = function(value)
		Core.Features.AimAssist.WallCheck = value
	end
}, "AimAssistWallCheck")

sections.main_right_bottom:Toggle({
	Name = "Aim Assist Team Check",
	Default = Core.Features.AimAssist.TeamCheck,
	Callback = function(value)
		Core.Features.AimAssist.TeamCheck = value
	end
}, "AimAssistTeamCheck")

Core.Keybinds.KnifeAuraKeybind = sections.main_right_bottom:Keybind({
	Name = "Aim Assist Keybind",
	Blacklist = false,
	onBindHeld = function(held)
		if held then
			Core.Features.AimAssist.Enabled = not Core.Features.AimAssist.Enabled
			AimAssist:UpdateState(Core.Features.AimAssist.Enabled)
		end
	end,
}, "AimAssistKeybind")

SilentAim = sections.main_right:Toggle({
	Name = "Silent Aim",
	Default = Core.Features.SilentAim.Enabled,
	Callback = function(state)
		Core.Features.SilentAim.Enabled = state
	end
}, "SilentAim")

local Hook; Hook = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
	local arguments = {...}
	local method = getnamecallmethod()

	if not Core.Features.SilentAim.Enabled then
		return Hook(self, ...)
	end

	if not checkcaller() and method == "FireServer" and (self.Name == "ShootReplicate" or self.Name == "ReportHit") then
		local closest = Core:GetClosest({
			Range = Core.Features.SilentAim.Range,
			WallCheck = Core.Features.SilentAim.WallCheck,
			Priority = Core.Features.SilentAim.Priority,
			TeamCheck = true
		})

		if closest then
			local character = closest.Character
			if character then
				local torso = character.FindFirstChild(character, "Torso")
				if torso then
					if self.Name == "ShootReplicate" then
						arguments[1].hitPos = torso.Position
						arguments[1].to = torso.Position
						arguments[1].hitInstance = torso
						arguments[1].isCharacterHit = true
					else
						arguments[1].hitPos = torso.Position
						arguments[1].to = torso.Position
						arguments[1].origin = torso.Position
						arguments[1].hitPart = torso
						arguments[1].headshot = true
						arugments[1].targetModel = character
					end
				end
			end
		end

		return Hook(self, unpack(arguments))
	end

	return Hook(self, ...)
end))

Core.Features.SilentAim.Hook = Hook

sections.main_right:Slider({
	Name = "Silent Aim Range",
	Default = Core.Features.SilentAim.Range,
	Minimum = 1,
	Maximum = 500,
	DisplayMethod = "Value",
	Precision = 1,
	Callback = function(value)
		Core.Features.SilentAim.Range = value
	end
}, "SilentAimRange")

sections.main_right:Toggle({
	Name = "Silent Aim Wall Check",
	Default = Core.Features.SilentAim.WallCheck,
	Callback = function(value)
		Core.Features.SilentAim.WallCheck = value
	end
}, "SilentAimWallCheck")

sections.main_right:Dropdown({
	Name = "Silent Aim Priority",
	Options = {"Camera", "Mouse", "Character"},
	Default = 1,
	Callback = function(value)
		Core.Features.SilentAim.Priority = value
	end
}, "SilentAimPriority")

Core.Keybinds.SilentAim = sections.main_right:Keybind({
	Name = "Silent Aim Keybind",
	Blacklist = false,
	onBindHeld = function(held)
		if held then
			Core.Features.SilentAim.Enabled = not Core.Features.SilentAim.Enabled
			SilentAim:UpdateState(Core.Features.SilentAim.Enabled)
		end
	end
}, "SilentAimKeybind")

--[[ MOBILITY ]]--

Flight = sections.mobility_left:Toggle({
	Name = "Flight",
	Default = Core.Features.Flight.Enabled,
	Callback = function(state)
		Core.Features.Flight.Enabled = state

		if state then
			Core.Connections.Flight = Services.RunService.PreRender:Connect(function(delta)
				local character, humanoid, humanoid_root_part = Core:GetParts(LocalPlayer)
				if not character or not humanoid or not humanoid_root_part then return end

				local move_direction = Vector3.zero

				if Services.UserInputService:IsKeyDown(Enum.KeyCode.W) and not Services.UserInputService:GetFocusedTextBox() then
					move_direction += Vector3.new(0, 0, 1)
				end
				if Services.UserInputService:IsKeyDown(Enum.KeyCode.S) and not Services.UserInputService:GetFocusedTextBox() then
					move_direction += Vector3.new(0, 0, -1)
				end
				if Services.UserInputService:IsKeyDown(Enum.KeyCode.A) and not Services.UserInputService:GetFocusedTextBox() then
					move_direction += Vector3.new(-1, 0, 0)
				end
				if Services.UserInputService:IsKeyDown(Enum.KeyCode.D) and not Services.UserInputService:GetFocusedTextBox() then
					move_direction += Vector3.new(1, 0, 0)
				end

				local vertical = 0
				if (Services.UserInputService:IsKeyDown(Enum.KeyCode.E) or Services.UserInputService:IsKeyDown(Enum.KeyCode.Space))
					and not Services.UserInputService:GetFocusedTextBox() then
					vertical = Core.Features.Flight.VerticalSpeed
				end
				if Services.UserInputService:IsKeyDown(Enum.KeyCode.Q) and not Services.UserInputService:GetFocusedTextBox() then
					vertical = -Core.Features.Flight.VerticalSpeed
				end

				if move_direction.Magnitude > 0 then
					move_direction = move_direction.Unit * Core.Features.Flight.HorizontalSpeed
				end

				local forward = Camera.CFrame.LookVector
				local right = Camera.CFrame.RightVector

				local final_move = (forward * move_direction.Z) + (right * move_direction.X) + (Vector3.yAxis * vertical)

				humanoid_root_part.CFrame += final_move * delta

				local velocity = humanoid_root_part.Velocity
				humanoid_root_part.Velocity = Vector3.new(velocity.X, 0.5, velocity.Z)
			end)
		else
			if Core.Connections.Flight then
				Core.Connections.Flight:Disconnect()
				Core.Connections.Flight = nil
			end
		end
	end,
}, "Flight")

sections.mobility_left:Slider({
	Name = "Horizontal Speed",
	Default = Core.Features.Flight.HorizontalSpeed,
	Minimum = 0,
	Maximum = 500,
	DisplayMethod = "Value",
	Precision = 1,
	Callback = function(v) Core.Features.Flight.HorizontalSpeed = v end,
}, "FlightHorizontalSpeed")

sections.mobility_left:Slider({
	Name = "Vertical Speed",
	Default = Core.Features.Flight.VerticalSpeed,
	Minimum = 0,
	Maximum = 500,
	DisplayMethod = "Value",
	Precision = 1,
	Callback = function(v) Core.Features.Flight.VerticalSpeed = v end,
}, "FlightVerticalSpeed")

Core.Keybinds.Flight = sections.mobility_left:Keybind({
	Name = "Flight Keybind",
	Blacklist = false,
	onBindHeld = function(held)
		if held then
			Core.Features.Flight.Enabled = not Core.Features.Flight.Enabled
			Flight:UpdateState(Core.Features.Flight.Enabled)
		end
	end,
}, "FlightKeybind")

Walkspeed = sections.mobility_left:Toggle({
	Name = "Walkspeed",
	Default = Core.Features.Walkspeed.Enabled,
	Callback = function(enabled)
		Core.Features.Walkspeed.Enabled = enabled

		if enabled then
			Core.Connections.Walkspeed = Services.RunService.PreRender:Connect(function()
				local character, humanoid, humanoid_root_part = Core:GetParts(LocalPlayer)
				if not character or not humanoid or not humanoid_root_part then return end

				humanoid.WalkSpeed = Core.Features.Walkspeed.Speed
			end)
		else
			if Core.Connections.Walkspeed then
				Core.Connections.Walkspeed:Disconnect()
				Core.Connections.Walkspeed = nil
			end

			local character, humanoid, humanoid_root_part = Core:GetParts(LocalPlayer)
			if not character or not humanoid or not humanoid_root_part then return end

			humanoid.WalkSpeed = 16
		end
	end,
}, "Walkspeed")

sections.mobility_left:Slider({
	Name = "Speed",
	Default = Core.Features.Walkspeed.Speed,
	Minimum = 0,
	Maximum = 200,
	DisplayMethod = "Value",
	Precision = 1,
	Callback = function(value)
		Core.Features.Walkspeed.Speed = value
	end,
}, "WalkspeedSlider")

Core.Keybinds.Walkspeed = sections.mobility_left:Keybind({
	Name = "Walkspeed Keybind",
	Blacklist = false,
	onBindHeld = function(held)
		if held then
			Core.Features.Walkspeed.Enabled = not Core.Features.Walkspeed.Enabled
			Walkspeed:UpdateState(Core.Features.Walkspeed.Enabled)
		end
	end,
}, "WalkspeedKeybind")

JumpPower = sections.mobility_left:Toggle({
	Name = "Jump Power",
	Default = Core.Features.JumpPower.Enabled,
	Callback = function(enabled)
		Core.Features.JumpPower.Enabled = enabled

		if enabled then
			Core.Connections.JumpPower = Services.RunService.PreRender:Connect(function()
				local character, humanoid = Core:GetParts(LocalPlayer)
				if not humanoid then return end

				if humanoid.UseJumpPower then
					humanoid.JumpPower = Core.Features.JumpPower.Power
				else
					humanoid.JumpHeight = Core.Features.JumpPower.Power
				end
			end)
		else
			if Core.Connections.JumpPower then
				Core.Connections.JumpPower:Disconnect()
				Core.Connections.JumpPower = nil
			end

			local character, humanoid = Core:GetParts(LocalPlayer)
			if not humanoid then return end

			if humanoid.UseJumpPower then
				humanoid.JumpPower = 50
			else
				humanoid.JumpHeight = 7.2
			end
		end
	end,
}, "JumpPower")

sections.mobility_left:Slider({
	Name = "Power",
	Default = Core.Features.JumpPower.Power,
	Minimum = 0,
	Maximum = 300,
	DisplayMethod = "Value",
	Precision = 1,
	Callback = function(value)
		Core.Features.JumpPower.Power = value
	end,
}, "JumpPowerSlider")

Core.Keybinds.JumpPower = sections.mobility_left:Keybind({
	Name = "Jump Power Keybind",
	Blacklist = false,
	onBindHeld = function(held)
		if held then
			Core.Features.JumpPower.Enabled = not Core.Features.JumpPower.Enabled
			JumpPower:UpdateState(Core.Features.JumpPower.Enabled)
		end
	end,
}, "JumpPowerKeybind")

FOV = sections.mobility_left:Toggle({
	Name = "Field of View",
	Default = Core.Features.FOV.Enabled,
	Callback = function(enabled)
		Core.Features.FOV.Enabled = enabled

		if enabled then
			Core.Connections.FOV = Services.RunService.PreRender:Connect(function()
				Camera.FieldOfView = Core.Features.FOV.Value
			end)
		else
			if Core.Connections.FOV then
				Core.Connections.FOV:Disconnect()
				Core.Connections.FOV = nil
			end

			Camera.FieldOfView = 70
		end
	end,
}, "FOV")

sections.mobility_left:Slider({
	Name = "FOV",
	Default = Core.Features.FOV.Value,
	Minimum = 0,
	Maximum = 120,
	DisplayMethod = "Value",
	Precision = 1,
	Callback = function(value)
		Core.Features.FOV.Value = value
	end,
}, "FOVSlider")

Core.Keybinds.FOV = sections.mobility_left:Keybind({
	Name = "FOV Keybind",
	Blacklist = false,
	onBindHeld = function(held)
		if held then
			Core.Features.FOV.Enabled = not Core.Features.FOV.Enabled
			FOV:UpdateState(Core.Features.FOV.Enabled)
		end
	end,
}, "FOVKeybind")

Gravity = sections.mobility_left:Toggle({
	Name = "Gravity",
	Default = Core.Features.Gravity.Enabled,
	Callback = function(enabled)
		Core.Features.Gravity.Enabled = enabled

		if enabled then
			Core.Connections.Gravity = Services.RunService.PreRender:Connect(function()
				workspace.Gravity = Core.Features.Gravity.Value
			end)
		else
			if Core.Connections.Gravity then
				Core.Connections.Gravity:Disconnect()
				Core.Connections.Gravity = nil
			end

			workspace.Gravity = 196.2
		end
	end,
}, "Gravity")

sections.mobility_left:Slider({
	Name = "Gravity",
	Default = Core.Features.Gravity.Value,
	Minimum = 0,
	Maximum = 300,
	DisplayMethod = "Value",
	Precision = 1,
	Callback = function(v)
		Core.Features.Gravity.Value = v
	end,
}, "GravitySlider")

Core.Keybinds.Gravity = sections.mobility_left:Keybind({
	Name = "Gravity Keybind",
	Blacklist = false,
	onBindHeld = function(held)
		if held then
			Core.Features.Gravity.Enabled = not Core.Features.Gravity.Enabled
			Gravity:UpdateState(Core.Features.Gravity.Enabled)
		end
	end,
}, "GravityKeybind")

Phase = sections.mobility_right:Toggle({
	Name = "Phase",
	Default = Core.Features.Phase.Enabled,
	Callback = function(enabled)
		Core.Features.Phase.Enabled = enabled

		if enabled then
			Core.Features.Phase.OriginalCollision = {}

			Core.Connections.Phase = Services.RunService.PreRender:Connect(function()
				local character = LocalPlayer.Character
				if not character then return end

				for _, part in next, character:GetDescendants() do
					if part:IsA("BasePart") and Core.Features.Phase.OriginalCollision[part] == nil then
						Core.Features.Phase.OriginalCollision[part] = part.CanCollide
					end
				end

				for part in next, Core.Features.Phase.OriginalCollision do
					if part and part.Parent then
						part.CanCollide = false
					end
				end
			end)
		else
			for part, canCollide in next, Core.Features.Phase.OriginalCollision do
				if part and part.Parent then
					part.CanCollide = canCollide
				end
			end

			Core.Features.Phase.OriginalCollision = {}

			if Core.Connections.Phase then
				Core.Connections.Phase:Disconnect()
				Core.Connections.Phase = nil
			end
		end
	end,
}, "Phase")

Core.Keybinds.Phase = sections.mobility_right:Keybind({
	Name = "Phase Keybind",
	Blacklist = false,
	onBindHeld = function(held)
		if held then
			Core.Features.Phase.Enabled = not Core.Features.Phase.Enabled
			Phase:UpdateState(Core.Features.Phase.Enabled)
		end
	end,
}, "PhaseKeybind")

LongJump = sections.mobility_right2:Toggle({
	Name = "Long Jump",
	Default = Core.Features.LongJump.Enabled,
	Callback = function(enabled)
		Core.Features.LongJump.Enabled = enabled

		if enabled then
			local can_boost = true

			Core.Connections.LongJump = Services.RunService.PreRender:Connect(function()
				local character, humanoid, root = Core:GetParts(LocalPlayer)
				if not character or not humanoid or not root then return end

				if humanoid:GetState() == Enum.HumanoidStateType.Jumping and can_boost then
					local direction = root.CFrame.LookVector * Core.Features.LongJump.Boost
					root.Velocity += Vector3.new(direction.X, Core.Features.LongJump.Height, direction.Z)
					can_boost = false
				elseif humanoid:GetState() ~= Enum.HumanoidStateType.Jumping then
					can_boost = true
				end
			end)
		else
			if Core.Connections.LongJump then
				Core.Connections.LongJump:Disconnect()
				Core.Connections.LongJump = nil
			end
		end
	end,
}, "LongJump")

sections.mobility_right2:Slider({
	Name = "Height",
	Default = Core.Features.LongJump.Height,
	Minimum = 0,
	Maximum = 500,
	DisplayMethod = "Value",
	Precision = 1,
	Callback = function(value)
		Core.Features.LongJump.Height = value
	end,
}, "LongJumpHeight")

sections.mobility_right2:Slider({
	Name = "Boost",
	Default = Core.Features.LongJump.Boost,
	Minimum = 0,
	Maximum = 500,
	DisplayMethod = "Value",
	Precision = 1,
	Callback = function(value)
		Core.Features.LongJump.Boost = value
	end,
}, "LongJumpBoost")

Core.Keybinds.LongJump = sections.mobility_right2:Keybind({
	Name = "Long Jump Keybind",
	Blacklist = false,
	onBindHeld = function(held)
		if held then
			Core.Features.LongJump.Enabled = not Core.Features.LongJump.Enabled
			LongJump:UpdateState(Core.Features.LongJump.Enabled)
		end
	end,
}, "LongJumpKeybind")

WallClimb = sections.mobility_right3:Toggle({
	Name = "Wall Climb",
	Default = Core.Features.WallClimb.Enabled,
	Callback = function(enabled)
		Core.Features.WallClimb.Enabled = enabled

		if enabled then
			Core.Connections.WallClimb = Services.RunService.PreRender:Connect(function()
				local character, humanoid, root = Core:GetParts(LocalPlayer)
				if not character or not root then return end

				local ray_origin = root.Position
				local ray_direction = root.CFrame.LookVector * 2

				local params = RaycastParams.new()
				params.FilterDescendantsInstances = { character }
				params.FilterType = Enum.RaycastFilterType.Exclude

				local hit = workspace:Raycast(ray_origin, ray_direction, params)
				if not hit then return end

				local upperOrigin = ray_origin + Vector3.new(0, 2.5, 0)
				local upperHit = workspace:Raycast(upperOrigin, ray_direction, params)

				if upperHit then
					root.Velocity = Vector3.new(
						root.Velocity.X,
						Core.Features.WallClimb.Speed,
						root.Velocity.Z
					)
				else
					root.CFrame += root.CFrame.LookVector * 1.2
					root.Velocity = Vector3.zero
				end
			end)
		else
			if Core.Connections.WallClimb then
				Core.Connections.WallClimb:Disconnect()
				Core.Connections.WallClimb = nil
			end
		end
	end,
}, "WallClimb")

sections.mobility_right3:Slider({
	Name = "Speed",
	Default = Core.Features.WallClimb.Speed,
	Minimum = 0,
	Maximum = 100,
	DisplayMethod = "Value",
	Precision = 1,
	Callback = function(value)
		Core.Features.WallClimb.Speed = value
	end,
}, "WallClimbSpeed")

Core.Keybinds.WallClimb = sections.mobility_right3:Keybind({
	Name = "Wall Climb Keybind",
	Blacklist = false,
	onBindHeld = function(held)
		if held then
			Core.Features.WallClimb.Enabled = not Core.Features.WallClimb.Enabled
			WallClimb:UpdateState(Core.Features.WallClimb.Enabled)
		end
	end,
}, "WallClimbKeybind")

SpinBot = sections.mobility_right4:Toggle({
	Name = "Spin Bot",
	Default = Core.Features.SpinBot.Enabled,
	Callback = function(enabled)
		Core.Features.SpinBot.Enabled = enabled

		if enabled then
			Core.Connections.SpinBot = Services.RunService.PreRender:Connect(function(delta)
				local character, humanoid, root = Core:GetParts(LocalPlayer)
				if not character or not humanoid or not root then return end

				humanoid.AutoRotate = false

				local rotation = math.rad(Core.Features.SpinBot.Speed) * delta * 60
				root.CFrame *= CFrame.Angles(0, rotation, 0)
			end)
		else
			if Core.Connections.SpinBot then
				Core.Connections.SpinBot:Disconnect()
				Core.Connections.SpinBot = nil
			end

			local character, humanoid = Core:GetParts(LocalPlayer)
			if humanoid then
				humanoid.AutoRotate = true
			end
		end
	end,
}, "SpinBot")

sections.mobility_right4:Slider({
	Name = "Speed",
	Default = Core.Features.SpinBot.Speed,
	Minimum = 0,
	Maximum = 100,
	DisplayMethod = "Value",
	Precision = 1,
	Callback = function(v)
		Core.Features.SpinBot.Speed = v
	end,
}, "SpinBotSpeed")

Core.Keybinds.SpinBot = sections.mobility_right4:Keybind({
	Name = "Spin Bot Keybind",
	Blacklist = false,
	onBindHeld = function(held)
		if held then
			Core.Features.SpinBot.Enabled = not Core.Features.SpinBot.Enabled
			SpinBot:UpdateState(Core.Features.SpinBot.Enabled)
		end
	end,
}, "SpinBotKeybind")

BunnyHop = sections.mobility_right5:Toggle({
	Name = "Bunny Hop",
	Default = Core.Features.BunnyHop.Enabled,
	Callback = function(enabled)
		Core.Features.BunnyHop.Enabled = enabled

		if enabled then
			Core.Connections.BunnyHop = Services.RunService.PreRender:Connect(function(delta)
				local character = LocalPlayer.Character
				if not character then return end

				local humanoid = character:FindFirstChild("Humanoid")
				if not humanoid then return end

				if humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
					humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
				end
			end)
		else
			if Core.Connections.BunnyHop then
				Core.Connections.BunnyHop:Disconnect()
				Core.Connections.BunnyHop = nil
			end
		end
	end,
}, "BunnyHop")

Core.Keybinds.BunnyHop = sections.mobility_right5:Keybind({
	Name = "Bunny Hop Keybind",
	Blacklist = false,
	onBindHeld = function(held)
		if held then
			Core.Features.BunnyHop.Enabled = not Core.Features.BunnyHop.Enabled
			BunnyHop:UpdateState(Core.Features.BunnyHop.Enabled)
		end
	end,
}, "BunnyHopKeybind")

--[[ RENDER ]]--

PlayerESP = sections.render_left:Toggle({
	Name = "Player ESP",
	Default = false,
	Callback = function(enabled)
		Core.Features.PlayerESP.Enabled = enabled

		if enabled then
			Core.Features.PlayerESP.ESPInstance = PlayerESPLib.new({
				Box = Core.Features.PlayerESP.Box,
				Tracer = Core.Features.PlayerESP.Tracer,
				Arrows = Core.Features.PlayerESP.Arrows,
				Skeleton = Core.Features.PlayerESP.Skeleton,
				Name = Core.Features.PlayerESP.Name,
				Rainbow = Core.Features.PlayerESP.Rainbow,
				DefaultColor = Core.Features.PlayerESP.DefaultColor,
				MaxDistance = Core.Features.PlayerESP.MaxDistance
			})

			Core.Features.PlayerESP.ESPInstance:Enable()
		else
			if Core.Features.PlayerESP.ESPInstance then
				Core.Features.PlayerESP.ESPInstance:Disable()
				Core.Features.PlayerESP.ESPInstance = nil
			end
		end
	end,
}, "PlayerESP")

sections.render_left:Toggle({
	Name = "Team Check",
	Default = Core.Features.PlayerESP.TeamCheck,
	Callback = function(value)
		Core.Features.PlayerESP.TeamCheck = value

		if value then
			Core.Connections.TeamCheck = Services.RunService.PreRender:Connect(function()
				for _, target in next, Services.Players:GetPlayers() do
					if Core.Features.PlayerESP.ESPInstance then
						if target.Team == LocalPlayer.Team then
							Core.Features.PlayerESP.ESPInstance:Destroy(target)
						else
							Core.Features.PlayerESP.ESPInstance:Add(target)
						end
					end
				end
			end)
		else
			if Core.Connections.TeamCheck then
				Core.Connections.TeamCheck:Disconnect()
				Core.Connections.TeamCheck = nil
			end
			
			if Core.Features.PlayerESP.ESPInstance then
				for _, player in next, Services.Players:GetPlayers() do
					Core.Features.PlayerESP.ESPInstance:Add(player)
				end
			end
		end
	end
}, "PlayerESPTeamCheck")

sections.render_left:Toggle({
	Name = "Box",
	Default = false,
	Callback = function(state)
		Core.Features.PlayerESP.Box = state

		if Core.Features.PlayerESP.ESPInstance then
			Core.Features.PlayerESP.ESPInstance.Box = state
		end
	end,
}, "PlayerESPBox")

sections.render_left:Toggle({
	Name = "Tracer",
	Default = false,
	Callback = function(state)
		Core.Features.PlayerESP.Tracer = state

		if Core.Features.PlayerESP.ESPInstance then
			Core.Features.PlayerESP.ESPInstance.Tracer = state
		end
	end,
}, "PlayerESPTracer")

sections.render_left:Toggle({
	Name = "Skeleton",
	Default = false,
	Callback = function(state)
		Core.Features.PlayerESP.Skeleton = state

		if Core.Features.PlayerESP.ESPInstance then
			Core.Features.PlayerESP.ESPInstance.Skeleton = state
		end
	end,
}, "PlayerESPSkeleton")

sections.render_left:Toggle({
	Name = "Arrows",
	Default = false,
	Callback = function(state)
		Core.Features.PlayerESP.Arrows = state

		if Core.Features.PlayerESP.ESPInstance then
			Core.Features.PlayerESP.ESPInstance.Arrows = state
		end
	end,
}, "PlayerESPArrows")

sections.render_left:Toggle({
	Name = "Name",
	Default = false,
	Callback = function(state)
		Core.Features.PlayerESP.Name = state

		if Core.Features.PlayerESP.ESPInstance then
			Core.Features.PlayerESP.ESPInstance.Name = state
		end
	end,
}, "PlayerESPName")

sections.render_left:Toggle({
	Name = "Rainbow",
	Default = false,
	Callback = function(state)
		Core.Features.PlayerESP.Rainbow = state

		if Core.Features.PlayerESP.ESPInstance then
			Core.Features.PlayerESP.ESPInstance.Rainbow = state
		end
	end,
}, "PlayerESPRainbow")

sections.render_left:Colorpicker({
	Name = "Player ESP Color",
	Default = Core.Features.PlayerESP.DefaultColor,
	Callback = function(color)
		Core.Features.PlayerESP.DefaultColor = color

		if Core.Features.PlayerESP.ESPInstance then
			Core.Features.PlayerESP.ESPInstance.DefaultColor = color

			for _, target_player in next, Services.Players:GetPlayers() do
				if target_player ~= LocalPlayer then
					Core.Features.PlayerESP.ESPInstance:SetColor(target_player, color)
				end
			end
		end
	end,
}, "PlayerESPColor")

Core.Keybinds.PlayerESP = sections.render_left:Keybind({
	Name = "Player ESP Keybind",
	Blacklist = false,
	onBindHeld = function(held)
		if held then
			Core.Features.PlayerESP.Enabled = not Core.Features.PlayerESP.Enabled
			PlayerESP:UpdateState(Core.Features.PlayerESP.Enabled)
		end
	end,
}, "PlayerESPKeybind")

RainbowHUD = sections.render_left_bottom:Toggle({
	Name = "Rainbow HUD",
	Default = false,
	Callback = function(enabled)
		Core.Features.RainbowHUD.Enabled = enabled

		if enabled then

			Core.Connections.RainbowHUD = Services.RunService.PreRender:Connect(function()
				local crosshair_module = require(Services.ReplicatedStorage.Shared.Crosshair)
				if not crosshair_module then return end
				
				local hue = (tick() % 5) / 5
				
				crosshair_module.SetAmmoTint(Color3.fromHSV(hue, 1, 1))
			end)
		else
			if Core.Connections.RainbowHUD then
				Core.Connections.RainbowHUD:Disconnect()
				Core.Connections.RainbowHUD = nil
			end
		end
	end,
}, "RainbowHUD")

Core.Keybinds.RainbowHUD = sections.render_left_bottom:Keybind({
	Name = "Rainbow HUD Keybind",
	Blacklist = false,
	onBindHeld = function(held)
		if held then
			Core.Features.RainbowHUD.Enabled = not Core.Features.RainbowHUD.Enabled
			RainbowHUD:UpdateState(Core.Features.RainbowHUD.Enabled)
		end
	end,
}, "RainbowHUDKeybind")

GunCustomizer = sections.render_right:Toggle({
	Name = "Gun Customizer",
	Default = false,
	Callback = function(enabled)
		Core.Features.GunCustomizer.Enabled = enabled
		
		if enabled then
			local character = LocalPlayer.Character
			if not character then return end
			
			local model = character:FindFirstChild("RevolverRig")
			if not model then return end

			Core.Features.GunCustomizer.Model = model

			Core.Features.GunCustomizer:StripAppearances(model)
			
			Core.Connections.GunCustomizer = Services.RunService.PreRender:Connect(function()
				local character = LocalPlayer.Character
				if not character then return end
				
				local model = character:FindFirstChild("RevolverRig")
				if not model then return end
				
				if model ~= Core.Features.GunCustomizer.LastModel then
					Core.Features.GunCustomizer:RestoreAppearances()
					
					Core.Features.GunCustomizer:StripAppearances(model)
					
					Core.Features.GunCustomizer.LastModel = model
				end
				
				if Core.Features.GunCustomizer.Rainbow then
					local hue = (tick() % 5) / 5

					for _, object in next, model:GetDescendants() do
						if object:IsA("BasePart") then
							if object.Name:find("Root") then continue end

							object.Color = Color3.fromHSV(hue, 1, 1)
							object.Transparency = Core.Features.GunCustomizer.Transparency
							object.Material = Enum.Material[Core.Features.GunCustomizer.Material]
						end
					end
				end
			end)
		else
			if Core.Connections.GunCustomizer then
				Core.Connections.GunCustomizer:Disconnect()
				Core.Connections.GunCustomizer = nil
			end
			
			Core.Features.GunCustomizer:RestoreAppearances()
		end
	end,
}, "GunCustomizer")

sections.render_right:Toggle({
	Name = "Rainbow",
	Default = false,
	Callback = function(state)
		Core.Features.GunCustomizer.Rainbow = state
	end,
}, "GunCustomizerRainbow")

sections.render_right:Dropdown({
	Name = "Material",
	Options = Materials,
	Default = 1,
	Callback = function(value)
		Core.Features.GunCustomizer.Material = value
	end
}, "GunCustomizerMaterial")

sections.render_right:Slider({
	Name = "Transparency",
	Default = Core.Features.GunCustomizer.Transparency,
	Minimum = 0,
	Maximum = 1,
	DisplayMethod = "Value",
	Precision = 1,
	Callback = function(v)
		Core.Features.GunCustomizer.Transparency = v
	end,
}, "GunCustomizerTransparency")

Core.Keybinds.GunCustomizer = sections.render_right:Keybind({
	Name = "Gun Customizer Keybind",
	Blacklist = false,
	onBindHeld = function(held)
		if held then
			Core.Features.GunCustomizer.Enabled = not Core.Features.GunCustomizer.Enabled
			GunCustomizer:UpdateState(Core.Features.GunCustomizer.Enabled)
		end
	end,
}, "GunCustomizerKeybind")

KnifeCustomizer = sections.render_right_bottom:Toggle({
	Name = "Knife Customizer",
	Default = false,
	Callback = function(enabled)
		Core.Features.KnifeCustomizer.Enabled = enabled

		if enabled then
			local character = LocalPlayer.Character
			if not character then return end

			local model = character:FindFirstChild("KnifeRig")
			if not model then return end

			Core.Features.KnifeCustomizer.Model = model

			Core.Features.KnifeCustomizer:StripAppearances(model)

			Core.Connections.KnifeCustomizer = Services.RunService.PreRender:Connect(function()
				local character = LocalPlayer.Character
				if not character then return end

				local model = character:FindFirstChild("KnifeRig")
				if not model then return end

				if model ~= Core.Features.KnifeCustomizer.LastModel then
					Core.Features.KnifeCustomizer:RestoreAppearances()

					Core.Features.KnifeCustomizer:StripAppearances(model)

					Core.Features.KnifeCustomizer.LastModel = model
				end

				if Core.Features.KnifeCustomizer.Rainbow then
					local hue = (tick() % 5) / 5

					for _, object in next, model:GetDescendants() do
						if object:IsA("BasePart") then
							if object.Name:find("Bounding") then continue end

							object.Color = Color3.fromHSV(hue, 1, 1)
							object.Transparency = Core.Features.KnifeCustomizer.Transparency
							object.Material = Enum.Material[Core.Features.KnifeCustomizer.Material]
						end
					end
				end
			end)
		else
			if Core.Connections.KnifeCustomizer then
				Core.Connections.KnifeCustomizer:Disconnect()
				Core.Connections.KnifeCustomizer = nil
			end

			Core.Features.KnifeCustomizer:RestoreAppearances()
		end
	end,
}, "KnifeCustomizer")

sections.render_right_bottom:Toggle({
	Name = "Rainbow",
	Default = false,
	Callback = function(state)
		Core.Features.KnifeCustomizer.Rainbow = state
	end,
}, "KnifeCustomizerRainbow")

sections.render_right_bottom:Dropdown({
	Name = "Material",
	Options = Materials,
	Default = 1,
	Callback = function(value)
		Core.Features.KnifeCustomizer.Material = value
	end
}, "KnifeCustomizerMaterial")

sections.render_right_bottom:Slider({
	Name = "Transparency",
	Default = Core.Features.KnifeCustomizer.Transparency,
	Minimum = 0,
	Maximum = 1,
	DisplayMethod = "Value",
	Precision = 1,
	Callback = function(v)
		Core.Features.KnifeCustomizer.Transparency = v
	end,
}, "KnifeCustomizerTransparency")

Core.Keybinds.KnifeCustomizer = sections.render_right_bottom:Keybind({
	Name = "Knife Customizer Keybind",
	Blacklist = false,
	onBindHeld = function(held)
		if held then
			Core.Features.KnifeCustomizer.Enabled = not Core.Features.KnifeCustomizer.Enabled
			GunCustomizer:UpdateState(Core.Features.KnifeCustomizer.Enabled)
		end
	end,
}, "KnifeCustomizerKeybind")

--[[ CONFIG ]]--

ConfigDropdown = sections.settings_left:Dropdown({
	Name = "Configs",
	Callback = function(selected)
		Core.Config.Selected = selected
	end,
}, "ConfigDropdown")

Core:RefreshConfigs(ConfigDropdown)

sections.settings_left:Input({
	Name = "Config Name",
	Placeholder = "Enter name",
	Callback = function(text)
		Core.Config.NameInput = text
	end,
}, "ConfigNameInput")

sections.settings_left:Button({
	Name = "Save Config",
	Callback = function()
		if Core.Config.NameInput == "" then
			window:Notify({
				Title = "Config",
				Description = "Config name cannot be empty",
				Lifetime = 3
			})
			return
		end

		Calamari:SaveConfig(Core.Config.NameInput)
		Core:RefreshConfigs(ConfigDropdown)

		window:Notify({
			Title = "Config",
			Description = "Saved config: " .. Core.Config.NameInput,
			Lifetime = 3
		})
	end
})

sections.settings_left:Button({
	Name = "Load Config",
	Callback = function()
		if not Core.Config.Selected then return end

		Calamari:LoadConfig(Core.Config.Selected)
		Core:RefreshConfigs(ConfigDropdown)

		window:Notify({
			Title = "Config",
			Description = "Loaded config: " .. Core.Config.Selected,
			Lifetime = 3
		})
	end
})

sections.settings_left:Button({
	Name = "Delete Config",
	Callback = function()
		if not Core.Config.Selected then return end

		local path = folder_name .. "/settings/" .. Core.Config.Selected .. ".json"
		if isfile(path) then
			delfile(path)
		end

		Core.Config.Selected = nil
		Core:RefreshConfigs(ConfigDropdown)

		window:Notify({
			Title = "Config",
			Description = "Config deleted",
			Lifetime = 3
		})
	end
})

ThemeDropdown = sections.settings_right:Dropdown({
	Name = "Theme",
	Options = window:GetThemes(),
	Default = window:GetTheme(),
	Callback = function(Value)
		if not Value then return end

		window:SetTheme(Value)
		window:Notify({
			Title = window.Settings.Title,
			Description = "Theme changed to " .. Value,
			Lifetime = 3
		})
	end,
}, "ThemeDropdown")

window:Dialog({
	Title = "Discord Server",
	Description = "Would you like to join our discord server? We offer premium scripts!",
	Buttons = {
		{
			Name = "Join",
			Callback = function()
				setclipboard("https://discord.com/invite/jWXrcr74a9")
			end,
		},
		{
			Name = "Decline"
		}
	}
})

window.onUnloaded(function()
	if Core.Features.PlayerESP.ESPInstance then
		Core.Features.PlayerESP.ESPInstance:Disable()
		Core.Features.PlayerESP.ESPInstance = nil
	end
	
	if Core.Features.SilentAim.Hook then
		hookmetamethod(game, "__namecall", Core.Features.SilentAim.Hook)
		Core.Features.SilentAim.Hook = nil
	end

	Core.Keybinds = {}

	for _, connection in next, Core.Connections do
		if connection and connection.Disconnect then
			connection:Disconnect()
		end
	end

	Core.Connections = {}
end)
