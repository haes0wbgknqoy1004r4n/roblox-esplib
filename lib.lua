-- hi

-- services
local runService = game:GetService("RunService");
local players = game:GetService("Players");
local workspace = game:GetService("Workspace");
local TweenService = game:GetService("TweenService")

-- variables
local localPlayer = players.LocalPlayer;
local camera = workspace.CurrentCamera;
local viewportSize = camera.ViewportSize;

-- locals
local floor = math.floor;
local round = math.round;
local sin = math.sin;
local cos = math.cos;
local clear = table.clear;
local unpack = table.unpack;
local find = table.find;
local create = table.create;
local fromMatrix = CFrame.fromMatrix;

-- methods
local wtvp = camera.WorldToViewportPoint;
local isA = workspace.IsA;
local getPivot = workspace.GetPivot;
local findFirstChild = workspace.FindFirstChild;
local findFirstChildOfClass = workspace.FindFirstChildOfClass;
local getChildren = workspace.GetChildren;
local toOrientation = CFrame.identity.ToOrientation;
local pointToObjectSpace = CFrame.identity.PointToObjectSpace;
local lerpColor = Color3.new().Lerp;
local min2 = Vector2.zero.Min;
local max2 = Vector2.zero.Max;
local lerp2 = Vector2.zero.Lerp;
local min3 = Vector3.zero.Min;
local max3 = Vector3.zero.Max;

-- constants
local HEALTH_BAR_OFFSET = Vector2.new(5, 0);
local HEALTH_TEXT_OFFSET = Vector2.new(3, 0);
local HEALTH_BAR_OUTLINE_OFFSET = Vector2.new(0, 1);
local NAME_OFFSET = Vector2.new(0, 2);
local DISTANCE_OFFSET = Vector2.new(0, 2);
local VERTICES = {
	Vector3.new(-1, -1, -1),
	Vector3.new(-1, 1, -1),
	Vector3.new(-1, 1, 1),
	Vector3.new(-1, -1, 1),
	Vector3.new(1, -1, -1),
	Vector3.new(1, 1, -1),
	Vector3.new(1, 1, 1),
	Vector3.new(1, -1, 1)
};

-- functions
local function isBodyPart(name)
	return name == "Head" or name:find("Torso") or name:find("Leg") or name:find("Arm");
end

local function getBoundingBox(parts)
	local min, max;
	for i = 1, #parts do
		local part = parts[i];
		local cframe, size = part.CFrame, part.Size;

		min = min3(min or cframe.Position, (cframe - size*0.5).Position);
		max = max3(max or cframe.Position, (cframe + size*0.5).Position);
	end

	local center = (min + max)*0.5;
	local front = Vector3.new(center.X, center.Y, max.Z);
	return CFrame.new(center, front), max - min;
end

local function worldToScreen(world)
	local screen, inBounds = wtvp(camera, world);
	return Vector2.new(screen.X, screen.Y), inBounds, screen.Z;
end

local function calculateCorners(cframe, size)
	local corners = create(#VERTICES);
	for i = 1, #VERTICES do
		corners[i] = worldToScreen((cframe + size*0.5*VERTICES[i]).Position);
	end

	local min = min2(viewportSize, unpack(corners));
	local max = max2(Vector2.zero, unpack(corners));
	return {
		corners = corners,
		topLeft = Vector2.new(floor(min.X), floor(min.Y)),
		topRight = Vector2.new(floor(max.X), floor(min.Y)),
		bottomLeft = Vector2.new(floor(min.X), floor(max.Y)),
		bottomRight = Vector2.new(floor(max.X), floor(max.Y))
	};
end

local function rotateVector(vector, radians)
	-- https://stackoverflow.com/questions/28112315/how-do-i-rotate-a-vector
	local x, y = vector.X, vector.Y;
	local c, s = cos(radians), sin(radians);
	return Vector2.new(x*c - y*s, x*s + y*c);
end

local function parseColor(self, color, isOutline)
	if color == "Team Color" or (self.interface.sharedSettings.useTeamColor and not isOutline) then
		return self.interface.getTeamColor(self.player) or Color3.new(1,1,1);
	end
	return color;
end

-----------------------------------------------------------------------------------------------

local maincont

if runService:IsStudio() then
	maincont = script.Parent
	-- Instance.new("ScreenGui", localPlayer.PlayerGui)
else
	maincont = Instance.new("ScreenGui", gethui and gethui() or game:GetService("CoreGui"))
end

local esplib = {
	container = Instance.new("Folder", maincont),
	chamscontainer = Instance.new("Folder", maincont),
	chamsmodels = Instance.new("Folder", workspace),
	settings = {
		friendly = {
			enabled = true,
			boxEnabled = true,
			boxColor = Color3.fromRGB(255, 0, 0),
			healthbarEnabled = true,
			healthbarfill = Color3.fromRGB(0, 255, 0),
			nameEnabled = true,
			frndWidget = true,
			distanceWidget = false,
			visibleChamsEnabled = true,
			visibleChamsFill = {Color3.fromRGB(0, 255, 0), 0.5},
			visibleChamsOutline = {Color3.fromRGB(0, 0, 0), 0.7},
			unvisibleChamsEnabled = true,
			unvisibleChamsFill = {Color3.fromRGB(255, 0, 0), 0.5},
			unvisibleChamsOutline = {Color3.fromRGB(0, 0, 0), 0.7},
		},
		enemies = {
			enabled = true,
			boxEnabled = true,
			boxColor = Color3.fromRGB(255, 0, 0),
			healthbarEnabled = true,
			healthbarfill = Color3.fromRGB(0, 255, 0),
			nameEnabled = true,
			frndWidget = true,
			distanceWidget = false,
			visibleChamsEnabled = true,
			visibleChamsFill = {Color3.fromRGB(0, 255, 0), 0.5},
			visibleChamsOutline = {Color3.fromRGB(0, 0, 0), 0.7},
			unvisibleChamsEnabled = true,
			unvisibleChamsFill = {Color3.fromRGB(255, 0, 0), 0.5},
			unvisibleChamsOutline = {Color3.fromRGB(0, 0, 0), 0.7},
		},
	}
}

maincont.Name = 'yesplib'

esplib.chamsmodels.Name = "chams_models"
esplib.container.Name = 'container'
esplib.chamscontainer.Name = 'chams'

local playerframe

if runService:IsStudio() then
	playerframe = script.Parent:WaitForChild("player")
	script.Parent:WaitForChild("player").Visible = false
else
	playerframe = game:GetObjects("rbxassetid://100962588120445")[1]
end

-----------------

function esplib.isFriendly(player)
	return player.Team and player.Team == localPlayer.Team;
end

function esplib.isFrnd(player)
	return false
end

function esplib.getCharacter(player)
	return player.Character;
end

function esplib.getHealth(player)
	local character = player and esplib.getCharacter(player);
	local humanoid = character and findFirstChildOfClass(character, "Humanoid");

	if humanoid then
		return math.floor(tonumber(humanoid.Health) or 0), humanoid.MaxHealth;
	end

	return 100, 100;
end

-----------------

local chamsconnections = {}

function esplib.new(player)
	assert(player)
	local character = player.Character
	assert(character, 'no character!!!')
	
	local main = playerframe:Clone()
	main.Parent = esplib.container
	main.Name = player.Name
	main.AnchorPoint = Vector2.new(0, 0)
	
	local chamsfolder = Instance.new("Folder")
	chamsfolder.Parent = esplib.chamscontainer
	chamsfolder.Name = player.Name
	
	local visiblechams = Instance.new('Highlight')
	visiblechams.Parent = chamsfolder
	visiblechams.Name = 'chams'
	visiblechams.DepthMode = Enum.HighlightDepthMode.Occluded
	visiblechams.Adornee = character
	
	local normalchamsmodel = Instance.new('Model')
	normalchamsmodel.Parent = esplib.chamsmodels
	normalchamsmodel.Name = player.Name
	
	local normalchams = Instance.new('Highlight')
	normalchams.Parent = normalchamsmodel
	normalchams.Name = 'chams'
	normalchams.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	normalchams.Adornee = normalchamsmodel
	
	
	
	chamsconnections[player.Name] = {}
	
	for _, part in ipairs(character:GetChildren()) do
		if character:FindFirstChild("Head") then
			local clone = part:Clone()
			local head = character:WaitForChild("Head")
			
			for _, v in ipairs(clone:GetChildren()) do
				if not v:IsA("SpecialMesh") then
					v:Destroy()
				else
					v.TextureId = ""
				end
			end
			
			pcall(function()
				clone.CanCollide = false
				clone.Size = clone.Size * 0.9
				clone.Parent = normalchamsmodel
			end)
			
			local connection = runService.RenderStepped:Connect(function()
				if head:IsDescendantOf(workspace) then
					pcall(function()
						clone.CFrame = part.CFrame
						clone.Size = part.Size
					end)
				else
					normalchamsmodel:Destroy()
					return
				end
			end)
			
			table.insert(chamsconnections[player.Name], connection)
		end
	end
end

function esplib.getMain(player)
	assert(player)
	return esplib.container:FindFirstChild(player.Name)
end

function esplib.remove(player)
	assert(player)

	local main = esplib.getMain(player)
	if main ~= nil then main:Destroy() end

	local chamsfolder = esplib.chamscontainer:FindFirstChild(player.Name)
	if chamsfolder ~= nil then chamsfolder:Destroy() end
	
	local pl_chamsconnections = chamsconnections[player.Name]
	if pl_chamsconnections then
		for _, connection in pairs(pl_chamsconnections) do
			if connection.Connected then
				connection:Disconnect()
			end
			
			connection = nil
		end
	end
	
	chamsconnections[player.Name] = nil
end

function esplib.update()
	if not esplib.settings.friendly.enabled and not esplib.settings.enemies.enabled then
		for _,player in ipairs(players:GetChildren()) do
			local main = esplib.getMain(player)
			if not main then continue end

			main.Visible = false
		end

		return
	end
	
	for _, player in ipairs(players:GetChildren()) do
		local friendly = esplib.isFriendly(player)
		local group = friendly and "friendly" or "enemies"
		
		local espsetts = esplib.settings[group]
		
		local main = esplib.getMain(player)
		if not main then continue end

		main.Visible = espsetts.enabled
		if not espsetts.enabled then continue end
		
		local character = esplib.getCharacter(player)
		if not character then main.Visible = false continue end
		
		local head = character:FindFirstChild('Head')
		if not head then main.Visible = false continue end

		local exist = pcall(function() return head.Position end)
		if not exist then main.Visible = false continue end
		
		local _, onScreen, depth = worldToScreen(head.Position);
		
		if not onScreen then
			main.Visible = false
			continue
		end
		
		local cache = {}
		local children = getChildren(character);

		for i = 1, #children do
			local part = children[i];
			if isA(part, "BasePart") and isBodyPart(part.Name) then
				cache[#cache + 1] = part;
			end
		end

		local corners = calculateCorners(getBoundingBox(cache));
		local position = UDim2.new(0, corners.topLeft.X, 0, corners.topLeft.Y)
		local size =  UDim2.new(0, corners.bottomRight.X - corners.topLeft.X, 0, corners.bottomRight.Y - corners.topLeft.Y)
		
		main.Position = position
		main.Size = size
		
		local boxColor = main:FindFirstChild('box') and main:FindFirstChild('box'):FindFirstChild('UIStroke')
		if boxColor then
			boxColor.Color = espsetts.boxColor
			boxColor.Enabled = espsetts.boxEnabled
		end
		
		local boxStroke = main:FindFirstChild('stroke') and main:FindFirstChild('stroke'):FindFirstChild("UIStroke")
		if boxStroke then
			boxStroke.Enabled = espsetts.boxEnabled
		end
		
		local top = main:FindFirstChild('top')
		local right = main:FindFirstChild('right')
		local bottom = main:FindFirstChild('bottom')
		
		if top then
			local username = top:FindFirstChild("username")
			
			if username then
				username.Visible = espsetts.nameEnabled
				
				for _, label in pairs(username:GetChildren()) do
					label.Text = player.DisplayName
				end
			end
		end
		
		if right then
			local frnd = right:FindFirstChild("frnd")
			
			if frnd then
				frnd.Visible = espsetts.frndWidget and esplib.isFrnd(player)
			end
		end
		
		if bottom then
			local distance = bottom:FindFirstChild("distance")

			if distance then
				distance.Visible = espsetts.distanceWidget
			end
		end
		
		local healthbar = main:FindFirstChild('healthbar')
		
		if healthbar then
			healthbar.Visible = espsetts.healthbarEnabled
			
			local health, maxHealth = esplib.getHealth(player)
			local fill = healthbar:FindFirstChild('fill')
			
			if fill then
				TweenService:Create(fill, TweenInfo.new(0.3, Enum.EasingStyle.Quad), { Size = UDim2.new(1, 0, health/maxHealth, 0) }):Play()
				
				local stroke1, stroke2 = fill:FindFirstChild('UIStroke'), fill:FindFirstChild("stroke"):FindFirstChild('UIStroke')
				
				stroke1.Color = espsetts.healthbarfill
				stroke2.Color = espsetts.healthbarfill
				
				fill.BackgroundColor3 = espsetts.healthbarfill
				
				local labels = { fill:FindFirstChild('original'), fill:FindFirstChild("2"), fill:FindFirstChild("3") }
				
				for _, label in pairs(labels) do
					label.Text = health
				end
			end
		end
		
		local visiblechams = esplib.chamscontainer:FindFirstChild(player.Name) and esplib.chamscontainer:FindFirstChild(player.Name):FindFirstChild("chams")
		local unvisiblechams = esplib.chamsmodels:FindFirstChild(player.Name) and esplib.chamsmodels:FindFirstChild(player.Name):FindFirstChild("chams")
		
		if visiblechams then
			visiblechams.Enabled = espsetts.visibleChamsEnabled
			visiblechams.FillColor = espsetts.visibleChamsFill[1]
			visiblechams.FillTransparency = espsetts.visibleChamsFill[2]
			visiblechams.OutlineColor = espsetts.visibleChamsOutline[1]
			visiblechams.OutlineTransparency = espsetts.visibleChamsOutline[2]
		end
		
		if unvisiblechams then
			unvisiblechams.Enabled = espsetts.unvisibleChamsEnabled
			unvisiblechams.FillColor = espsetts.unvisibleChamsFill[1]
			unvisiblechams.FillTransparency = espsetts.unvisibleChamsFill[2]
			unvisiblechams.OutlineColor = espsetts.unvisibleChamsOutline[1]
			unvisiblechams.OutlineTransparency = espsetts.unvisibleChamsOutline[2]
		end
	end
end

function connectplayer(player)
	player.CharacterAdded:Connect(function(character)
		esplib.new(player)

		local humanoid = character:WaitForChild("Humanoid")

		humanoid.Died:Connect(function()
			esplib.remove(player)
		end)
	end)
end

function esplib:Init()
	players.PlayerAdded:Connect(function(player)
		connectplayer(player)
	end);
	
	players.PlayerRemoving:Connect(esplib.remove);

	for _, player in pairs(players:GetChildren()) do
		connectplayer(player)
		
		if player.Character ~= nil then
			esplib.new(player)
		end
	end

	runService.RenderStepped:Connect(esplib.update)

	playerframe.Visible = false
end

-------------------------------

esplib:Init()

return esplib
