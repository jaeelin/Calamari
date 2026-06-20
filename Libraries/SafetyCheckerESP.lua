local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local Camera = workspace.CurrentCamera

local SafetyESP = {}
SafetyESP.__index = SafetyESP
SafetyESP.Version = "1.0.1"

function SafetyESP.new(Config: {any})
	local self = setmetatable({}, SafetyESP)

	self.Debug = Config and Config.Debug or false
	
	self.FlagDictionary = Config and Config.FlagDictionary or {}
	
	self.TargetData = {}
	
	self.Enabled = false
	self.Box = Config and Config.Box or false
	self.Name = Config and Config.Name or false
	self.Status = Config and Config.Status or false
	self.DefaultColor = Config and Config.DefaultColor or Color3.fromRGB(255, 255, 255)
	self.MaxDistance = Config and Config.MaxDistance or 300

	self.BoxDrawings = {}
	self.NameDrawings = {}
	self.StatusDrawings = {}

	self.TargetColors = {}
	self.ActiveTargets = {}
	self.Connections = {}

	return self
end

function SafetyESP:CreateDrawing(Type: string, Properties: {any})
	local drawing = Drawing.new(Type)

	for property, value in next, Properties do
		drawing[property] = value
	end

	return drawing
end

function SafetyESP:Cleanup(Target: Player)
	for _, esp_table in next, {self.BoxDrawings, self.NameDrawings, self.StatusDrawings} do
		local object = esp_table[Target]

		if object then
			if type(object) == "table" then
				for _, obj in next, object do obj:Remove() end
			else
				object:Remove()
			end

			esp_table[Target] = nil
		end
	end
end

function SafetyESP:RemoveESP()
	local objects = {self.BoxDrawings, self.NameDrawings, self.StatusDrawings}

	for _, table in next, objects do
		for _, object in next, table do
			if type(object) == "table" then
				for _, sub_object in next, object do
					sub_object.Visible = false
				end
			elseif object then
				object.Visible = false
			end
		end
	end

	self.BoxDrawings = {}
	self.NameDrawings = {}
	self.StatusDrawings = {}
end

function SafetyESP:DrawBox(Target: Player, ScreenPosition: Vector2, BoxWidth: number, BoxHeight: number, Color: Color3)
	if not self.Box then
		if self.BoxDrawings[Target] then
			self.BoxDrawings[Target].Visible = false
		end

		return
	end

	local box = self.BoxDrawings[Target] or self:CreateDrawing("Square", {
		Color = Color,
		Thickness = 1.5,
		Filled = false,
		Transparency = 1
	})

	self.BoxDrawings[Target] = box

	box.Size = Vector2.new(BoxWidth, BoxHeight)
	box.Position = Vector2.new(ScreenPosition.X - BoxWidth / 2, ScreenPosition.Y - BoxHeight / 2)
	box.Color = Color
	box.Visible = true
end

function SafetyESP:DrawName(Target: Player, ScreenPosition: Vector2, BoxHeight: number, Distance: number, Color: Color3)
	if not self.Name then
		if self.NameDrawings[Target] then
			self.NameDrawings[Target].Visible = false
		end

		return
	end

	local name_text = self.NameDrawings[Target] or self:CreateDrawing("Text", {
		Text = Target.Name,
		Color = Color,
		Font = 2,
		Size = 14,
		Center = true,
		Outline = true
	})

	self.NameDrawings[Target] = name_text

	name_text.Text = Target.Name .. " [" .. Distance .. "m]"
	name_text.Position = Vector2.new(ScreenPosition.X, ScreenPosition.Y - BoxHeight / 2 - 15)
	name_text.Color = Color
	name_text.Visible = true
end

function SafetyESP:DrawStatus(Target: Player, ScreenPosition: Vector2, BoxHeight: number, Data: any, Color: Color3)
	if not self.Status or not Data or not Data.flagType then
		if self.StatusDrawings[Target] then
			self.StatusDrawings[Target].Visible = false
		end

		return
	end

	local status_text = self.StatusDrawings[Target] or self:CreateDrawing("Text", {
		Color = Color,
		Font = 2,
		Size = 12,
		Center = true,
		Outline = true
	})

	self.StatusDrawings[Target] = status_text

	local flag_name = self.FlagDictionary[Data.flagType] or "Unknown"
	local confidence = math.floor((Data.confidence or 0) * 100)
	status_text.Text = flag_name .. " (" .. confidence .. "%)"

	status_text.Position = Vector2.new(ScreenPosition.X, ScreenPosition.Y - BoxHeight / 2 - 32)
	status_text.Color = Color
	status_text.Visible = true
end

function SafetyESP:Update(Target: Player)
	local character = Target.Character
	if not character or not character.Parent then self:Cleanup(Target) return end

	local humanoid_root_part = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildWhichIsA("Humanoid")

	if not humanoid_root_part or not humanoid or humanoid.Health <= 0 then self:Cleanup(Target) return end

	local color = self.TargetColors[Target] or self.DefaultColor
	if self.Rainbow then color = self:GetRainbow() end

	local head_position, head_on_screen = Camera:WorldToViewportPoint(humanoid_root_part.Position + Vector3.new(0, 3, 0))
	local foot_position, foot_on_screen = Camera:WorldToViewportPoint(humanoid_root_part.Position - Vector3.new(0, 3, 0))

	local box_height = foot_position.Y - head_position.Y
	local box_width = box_height / 1.5
	local box_center = Vector2.new((head_position.X + foot_position.X) / 2, (head_position.Y + foot_position.Y) / 2)

	local distance = 0

	local local_humanoid_root_pat = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if local_humanoid_root_pat then distance = math.floor((local_humanoid_root_pat.Position - humanoid_root_part.Position).Magnitude) end

	if self.MaxDistance > 0 and distance > self.MaxDistance then self:Cleanup(Target) return end

	if not (head_on_screen or foot_on_screen) then
		self:Cleanup(Target)
		return
	end

	self:DrawBox(Target, box_center, box_width, box_height, color)
	self:DrawName(Target, box_center, box_height, distance, color)

	local data = self.TargetData and self.TargetData[Target.UserId] or nil
	self:DrawStatus(Target, box_center, box_height, data, color)
end

function SafetyESP:Setup(Target: Player)
	if Target == LocalPlayer then return end

	self.ActiveTargets[Target] = true

	if not self.RenderConnection then
		self.RenderConnection = RunService.RenderStepped:Connect(function()
			if not self.Enabled then return end

			for active_target in next, self.ActiveTargets do
				self:Update(active_target)
			end
		end)

		table.insert(self.Connections, self.RenderConnection)
	end
end

function SafetyESP:SetColor(Target: Player, Color: Color3)
	self.TargetColors[Target] = Color
end

function SafetyESP:Destroy(Target: Player)
	if not Target then
		for target in next, self.ActiveTargets do
			self:Cleanup(target)
		end

		self.ActiveTargets = {}

		return
	end

	local function CleanupPlayer(Player: Player)
		if typeof(Player) == "Instance" and Player:IsA("Player") then
			self.ActiveTargets[Player] = nil
			self:Cleanup(Player)
		end
	end

	if typeof(Target) == "Instance" and Target:IsA("Player") then
		CleanupPlayer(Target)
	elseif type(Target) == "table" then
		for _, player_instance in next, Target do
			CleanupPlayer(player_instance)
		end
	end
end

function SafetyESP:Add(Target: Player)
	if not Target then return end

	if typeof(Target) ~= "Instance" or not Target:IsA("Player") then return end

	if not self.ActiveTargets[Target] then
		self:Setup(Target)
	end
end

function SafetyESP:Enable()
	self.Enabled = true

	for _, target in next, Players:GetPlayers() do
		self:Setup(target)
	end

	table.insert(self.Connections, Players.PlayerAdded:Connect(function(target)
		self:Setup(target)
	end))

	table.insert(self.Connections, Players.PlayerRemoving:Connect(function(target)
		self.ActiveTargets[target] = nil
		self:Cleanup(target)
	end))
end

function SafetyESP:Disable()
	self.Enabled = false

	if self.ActiveTargets then
		for target in next, self.ActiveTargets do
			self:Cleanup(target)
		end
	end

	self:RemoveESP()

	for _, connection in next, self.Connections do
		connection:Disconnect()
	end

	self.Connections = {}
end

return SafetyESP
