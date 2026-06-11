local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local Camera = workspace.CurrentCamera

local PlayerESP = {}
PlayerESP.__index = PlayerESP
PlayerESP.Version = "1.0.0"

function PlayerESP.new(Config: {any})
	local self = setmetatable({}, PlayerESP)

	self.Enabled = false

	self.Box = Config and Config.Box or false
	self.HealthBar = Config and Config.HealthBar or false
	self.Tracer = Config and Config.Tracer or false
	self.Skeleton = Config and Config.Skeleton or false
	self.Name = Config and Config.Name or false
	self.Arrows = Config and Config.Arrows or false
	self.Chams = Config and Config.Chams or false
	self.ChamsFill = Config and Config.ChamsFill or false
	self.Rainbow = Config and Config.Rainbow or false
	self.TracerOrigin = Config and Config.TracerOrigin or "Character"
	self.DefaultColor = Config and Config.DefaultColor or Color3.fromRGB(255, 255, 255)
	self.ChamsColor = Config and Config.ChamsColor or Color3.fromRGB(255, 255, 255)
	self.ChamsOutline = Config and Config.ChamsOutline or Color3.fromRGB(255, 255, 255)
	self.MaxDistance = Config and Config.MaxDistance or 300
	
	self.Boxes = {}
	self.HealthBars = {}
	self.Tracers = {}
	self.Skeletons = {}
	self.Names = {}
	self.Arrows = {}
	self.Chams = {}

	self.TargetColors = {}
	self.ActiveTargets = {}
	self.Connections = {}

	return self
end

function PlayerESP:CreateDrawing(Type: string, Properties: {any})
	local drawing = Drawing.new(Type)
	
	for property, value in next, Properties do
		drawing[property] = value
	end
	
	return drawing
end

function PlayerESP:GetRainbow()
	local current_time = tick() * 0.5
	local hue = (current_time * 0.35) % 1

	local saturation = 0.9
	local value = 0.9

	return Color3.fromHSV(hue, saturation, value)
end

function PlayerESP:DrawBone(Target: Player, Index: number, Part1: BasePart, Part2: BasePart, Color: Color3)
	if not Part1 or not Part2 then return end

	local point_a_position, a_on_screen = Camera:WorldToViewportPoint(Part1.Position)
	local point_b_position, b_on_screen = Camera:WorldToViewportPoint(Part2.Position)

	self.Skeletons[Target] = self.Skeletons[Target] or {}
	self.Skeletons[Target][Index] = self.Skeletons[Target][Index] or self:CreateDrawing("Line", {
		Thickness = 1.5,
		Color = Color,
		Transparency = 1
	})

	local line = self.Skeletons[Target][Index]
	line.From = Vector2.new(point_a_position.X, point_a_position.Y)
	line.To = Vector2.new(point_b_position.X, point_b_position.Y)
	line.Visible = a_on_screen or b_on_screen
	line.Color = Color
end

function PlayerESP:Cleanup(Target: Player)
	for _, esp_table in next, {self.Boxes, self.HealthBars, self.Tracers, self.Names, self.Arrows} do
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

	if self.Skeletons[Target] then
		for _, line in next, self.Skeletons[Target] do
			line:Remove()
		end
		
		self.Skeletons[Target] = nil
	end

	if self.Chams[Target] then
		self.Chams[Target]:Destroy()
		self.Chams[Target] = nil
	end
end

function PlayerESP:RemoveESP()
	local objects = {self.Tracers, self.Boxes, self.Names, self.HealthBars, self.Arrows}
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

	for _, skeleton in next, self.Skeletons do
		for _, line in next, skeleton do
			line.Visible = false
		end
	end

	for _, cham in next, self.Chams do
		cham:Destroy()
	end

	self.Tracers = {}
	self.Boxes = {}
	self.Names = {}
	self.HealthBars = {}
	self.Skeletons = {}
	self.Arrows = {}
	self.Chams = {}
end

function PlayerESP:DrawBox(Target: Player, ScreenPosition: Vector2, BoxWidth: number, BoxHeight: number, Color: Color3)
	if not self.Box then
		if self.Boxes[Target] then
			self.Boxes[Target].Visible = false
		end
		
		return
	end

	local box = self.Boxes[Target] or self:CreateDrawing("Square", {
		Color = Color,
		Thickness = 1.5,
		Filled = false,
		Transparency = 1
	})
	
	self.Boxes[Target] = box

	box.Size = Vector2.new(BoxWidth, BoxHeight)
	box.Position = Vector2.new(ScreenPosition.X - BoxWidth / 2, ScreenPosition.Y - BoxHeight / 2)
	box.Color = Color
	box.Visible = true
end

function PlayerESP:DrawHealthBar(Target: Player, ScreenPosition: Vector2, BoxWidth: number, BoxHeight: number)
	if not self.HealthBar then
		if self.HealthBars and self.HealthBars[Target] then
			self.HealthBars[Target].Visible = false
		end
		
		return
	end

	local bar = self.HealthBars[Target] or self:CreateDrawing("Square", {
		Color = Color3.fromRGB(150, 255, 150),
		Thickness = 1,
		Filled = true,
		Transparency = 1
	})
	
	self.HealthBars[Target] = bar

	local humanoid = Target.Character and Target.Character:FindFirstChild("Humanoid")
	if not humanoid or humanoid.Health <= 0 then bar.Visible = false return end

	local health_percent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
	local health_color
	
	if health_percent <= 0.5 then
		health_color = Color3.fromRGB(255, 150, 150):Lerp(Color3.fromRGB(255, 220, 150), health_percent * 2)
	else
		health_color = Color3.fromRGB(255, 220, 150):Lerp(Color3.fromRGB(150, 255, 150), (health_percent - 0.5) * 2)
	end

	local bar_x = ScreenPosition.X + (BoxWidth / 2) + 2
	local bar_y = ScreenPosition.Y - BoxHeight / 2 + (BoxHeight * (1 - health_percent))

	bar.Size = Vector2.new(3, BoxHeight * health_percent)
	bar.Position = Vector2.new(bar_x, bar_y)
	bar.Color = health_color
	bar.Visible = true
end

function PlayerESP:DrawTracer(Target: Player, ScreenPosition: Vector2, Color: Color3)
	if not self.Tracer then
		if self.Tracers[Target] then
			self.Tracers[Target].Visible = false
		end
		
		return
	end

	local tracer = self.Tracers[Target] or self:CreateDrawing("Line", {
		Color = Color,
		Thickness = 1.5
	})
	
	self.Tracers[Target] = tracer

	local viewport_size = Camera.ViewportSize
	local camera_screen_position = 
		Vector2.new(viewport_size.X / 2, 
		(self.TracerOrigin == "Top" and 0) or (self.TracerOrigin == "Bottom" and viewport_size.Y) or viewport_size.Y / 2)

	tracer.From = camera_screen_position
	tracer.To = Vector2.new(ScreenPosition.X, ScreenPosition.Y)
	tracer.Color = Color
	tracer.Visible = true
end

function PlayerESP:DrawName(Target: Player, ScreenPosition: Vector2, BoxHeight: number, Distance: number, Color: Color3)
	if not self.Name then
		if self.Names[Target] then
			self.Names[Target].Visible = false
		end
		
		return
	end

	local name_text = self.Names[Target] or self:CreateDrawing("Text", {
		Text = Target.Name,
		Color = Color,
		Font = 2,
		Size = 14,
		Center = true,
		Outline = true
	})
	
	self.Names[Target] = name_text

	name_text.Text = Target.Name .. " [" .. Distance .. "m]"
	name_text.Position = Vector2.new(ScreenPosition.X, ScreenPosition.Y - BoxHeight / 2 - 15)
	name_text.Color = Color
	name_text.Visible = true
end

function PlayerESP:DrawSkeleton(Target: Player, Character: Model, Color: Color3)
	if not self.Skeleton then
		for _, skeleton in next, self.Skeletons do
			for _, line in next, skeleton do line.Visible = false end
		end
		
		return
	end

	local function GetPart(part)
		local object = Character:FindFirstChild(part)
		return (object and object:IsA("BasePart")) and object or nil
	end

	local torso = GetPart("Torso") or GetPart("UpperTorso")
	local lower_torso = GetPart("LowerTorso")
	local root = torso or lower_torso

	local parts = {
		Head = GetPart("Head"),
		Torso = torso,
		LowerTorso = lower_torso,
		LeftUpperArm = GetPart("Left Arm") or GetPart("LeftUpperArm"),
		RightUpperArm = GetPart("Right Arm") or GetPart("RightUpperArm"),
		LeftLowerArm = GetPart("LeftLowerArm"),
		RightLowerArm = GetPart("RightLowerArm"),
		LeftUpperLeg = GetPart("Left Leg") or GetPart("LeftUpperLeg"),
		RightUpperLeg = GetPart("Right Leg") or GetPart("RightUpperLeg"),
		LeftLowerLeg = GetPart("LeftLowerLeg"),
		RightLowerLeg = GetPart("RightLowerLeg")
	}

	local function DrawLimb(Start, Mid, End, Index)
		if Mid then
			self:DrawBone(Target, Index, Mid, Mid, Color)
			
			if End then
				self:DrawBone(Target, Index + 1, Mid, End, Color)
			end
		end
	end

	self:DrawBone(Target, 1, parts.Head, root, Color)
	
	DrawLimb(root, parts.LeftUpperArm, parts.LeftLowerArm, 2)
	DrawLimb(root, parts.RightUpperArm, parts.RightLowerArm, 4)
	DrawLimb(root, parts.LeftUpperLeg, parts.LeftLowerLeg, 6)
	DrawLimb(root, parts.RightUpperLeg, parts.RightLowerLeg, 8)

	for _, line in next, self.Skeletons[Target] or {} do
		line.Color = Color
	end
end

function PlayerESP:DrawArrows(Target: Player, _, Color: Color3)
	if not self.Arrows then
		if self.Arrows[Target] then
			for _, line in next, self.Arrows[Target] do line.Visible = false end
		end
		
		return
	end

	local character = Target.Character
	local humanoid_root_part = character and character:FindFirstChild("HumanoidRootPart")
	
	if not humanoid_root_part then return end

	self.Arrows[Target] = self.Arrows[Target] or {}

	local viewport = Camera.ViewportSize
	local center = Vector2.new(viewport.X / 2, viewport.Y / 2)

	local to_target = humanoid_root_part.Position - Camera.CFrame.Position
	local direction = Vector2.new(to_target:Dot(Camera.CFrame.RightVector), -to_target:Dot(Camera.CFrame.UpVector))
	
	if direction.Magnitude > 0 then direction = direction.Unit end

	local arrow_distance, arrow_size = 50, 10
	local position = center + direction * arrow_distance
	local angle = math.atan2(direction.Y, direction.X)

	local points = {
		position + Vector2.new(math.cos(angle) * arrow_size, math.sin(angle) * arrow_size),
		position + Vector2.new(math.cos(angle + 2.5) * arrow_size, math.sin(angle + 2.5) * arrow_size),
		position + Vector2.new(math.cos(angle - 2.5) * arrow_size, math.sin(angle - 2.5) * arrow_size)
	}

	for i = 1, 3 do
		local line = self.Arrows[Target][i] or self:CreateDrawing("Line", {Color = Color, Thickness = 1.5})
		self.Arrows[Target][i] = line
		line.From = points[i]
		line.To = points[i % 3 + 1]
		line.Color = Color
		line.Visible = true
	end
end

function PlayerESP:DrawChams(Target: Player, Character: Model, FillColor: Color3, OutlineColor: Color3)
	if not self.Chams then
		if self.Chams[Target] then
			self.Chams[Target].Enabled = false
		end
		
		return
	end

	if not Character or not Character.Parent then return end

	local highlight = self.Chams[Target] or Instance.new("Highlight")
	self.Chams[Target] = highlight

	highlight.Parent = Character
	highlight.Adornee = Character
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.FillColor = FillColor or self.ChamsColor
	highlight.OutlineColor = OutlineColor or self.ChamsOutline
	highlight.FillTransparency = self.ChamsFill and 0.4 or 1
	highlight.OutlineTransparency = 0
	highlight.Enabled = true
end

function PlayerESP:Update(Target: Player)
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
		self:DrawArrows(Target, box_center, color)
		return
	else
		if self.Arrows[Target] then
			for _, line in next, self.Arrows[Target] do
				line.Visible = false
			end
		end
	end

	self:DrawBox(Target, box_center, box_width, box_height, color)
	self:DrawHealthBar(Target, box_center, box_width, box_height)
	self:DrawTracer(Target, box_center, color)
	self:DrawName(Target, box_center, box_height, distance, color)
	self:DrawSkeleton(Target, character, color)

	local fill = (self.Rainbow and self:GetRainbow()) or self.ChamsColor
	local outline = (self.Rainbow and self:GetRainbow()) or self.ChamsOutline
	
	self:DrawChams(Target, character, fill, outline)
end

function PlayerESP:Setup(Target: Player)
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

function PlayerESP:SetColor(Target: Player, Color: Color3)
	self.TargetColors[Target] = Color
end

function PlayerESP:Destroy(Target: Players)
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

function PlayerESP:Add(Target: Player)
	if not Target then return end

	if typeof(Target) ~= "Instance" or not Target:IsA("Player") then return end

	if not self.ActiveTargets[Target] then
		self:Setup(Target)
	end
end

function PlayerESP:Enable()
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

function PlayerESP:Disable()
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

return PlayerESP
