local PlayerBases = {}

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")

local StarInfoModule = require(script.Parent.Parent.StarSystem.Magnets.StarInfoModule)
local DataStoreHandler = require(script.Parent.DataStoreHandler)


function PlayerBases.PlayerBaseLoad(Player)
	local Profile = DataStoreHandler.Profiles[Player]
	if not Profile then
		repeat Profile = DataStoreHandler.Profiles[Player] task.wait() until Profile
	end
	
	local PlayerID = Player.UserId
	
	local LoadedPlots = workspace:WaitForChild("EmptyPlots")
	local PlayerPlots = workspace:WaitForChild("Plots")
	local StoredBase1 = ServerStorage:WaitForChild("Bases"):WaitForChild("Plot")
	
	local Plots = CollectionService:GetTagged("Plots")

	local AssignedPlot
	
	-- find an empty plot, then assign it
	
	for _, plot in ipairs(Plots) do
		if not plot:FindFirstChildOfClass("ObjectValue") then
			AssignedPlot = plot
			
			break
		end
	end
	
	AssignedPlot.Parent = PlayerPlots
	
	if not AssignedPlot then
		warn("Player has no base, join a different server")
		return
	end
	
	local EmptyPlot = AssignedPlot:GetChildren()[1]
	
	local BaseSpawn = EmptyPlot.PrimaryPart.CFrame
	
	local EmptyBase = AssignedPlot:GetDescendants()
	for _, base in ipairs(EmptyBase) do
		base:Destroy()
	end
	
	-- get player's base level and spawn base (base levels not added yet)
	local BaseLevel = Profile.Data.BaseLevel
	local PlayerBase
	
	if BaseLevel == 1 then
		PlayerBase = StoredBase1:Clone()
	end
		
	PlayerBase.Parent = AssignedPlot
	PlayerBase.Name = tostring(PlayerID)
	
	if PlayerBase.PrimaryPart then
		PlayerBase:PivotTo(BaseSpawn)
	end
	
	
	if Player.Character then
		LoadPlayerMagnets(Player, PlayerBase, Profile)
		LoadPlayerInventory(Player, Profile)
	else
		Player.CharacterAdded:Once(function()
			LoadPlayerMagnets(Player, PlayerBase, Profile)
			LoadPlayerInventory(Player, Profile)
		end)
	end
	
	
	
	-- Spawn the player
	
	local SpawnLocation = PlayerBase:WaitForChild("Main"):WaitForChild("SpawnLocation")
	local Character = Player.Character
	
	if Player.Character then
		local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
		local Humanoid = Character:WaitForChild("Humanoid")

		Humanoid.WalkSpeed = 30


		HumanoidRootPart.CFrame = SpawnLocation.CFrame + Vector3.new(0, 3, 0)
		
		Player.CharacterAdded:Connect(function(Character)
			Humanoid.WalkSpeed = 30
			
			HumanoidRootPart.CFrame = SpawnLocation.CFrame + Vector3.new(0, 3, 0)
		end)
		
	else
		
		Player.CharacterAdded:Connect(function(Character)
			local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
			local Humanoid = Character:WaitForChild("Humanoid")
			
			Humanoid.WalkSpeed = 30
			
			HumanoidRootPart.CFrame = SpawnLocation.CFrame + Vector3.new(0, 3, 0)
		end)
		
	end
	
	-- Set up the "Base" tp button
	
	local PlayerGUI = Player:WaitForChild("PlayerGui")
	local MainGUI = PlayerGUI:WaitForChild("MainGUI")
	local TPButtonFolder = MainGUI:WaitForChild("TeleportButtons")
	local BaseTPButton = TPButtonFolder:WaitForChild("Base")
	local BaseVector3 = BaseTPButton:WaitForChild("Position")
	
	BaseVector3.Value = SpawnLocation.Position + Vector3.new(0, 3, 0)
	
	
	-- Set up the sign
	
	local Sign = PlayerBase:WaitForChild("Sign"):WaitForChild("Sign")
	local SignGUI = Sign:WaitForChild("PlayerSignGUI")
	local SignText = SignGUI:WaitForChild("PlayerUsername")
	local SignImage = SignGUI:WaitForChild("PlayerImage")

	SignText.Text = `{Players:GetNameFromUserIdAsync(PlayerID)}'s Base`

	local GotImage, Thumbnail = pcall(function()
		return Players:GetUserThumbnailAsync(PlayerID, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
	end)

	if GotImage then
		SignImage.Image = Thumbnail
	end

	SignImage.ImageTransparency = 0
	
	
	AssignedPlot.Name = tostring(PlayerID)

	local OwnerTag = Instance.new("ObjectValue")
	OwnerTag.Name = "Owner"
	OwnerTag.Value = Player
	OwnerTag.Parent = AssignedPlot
end


function PlayerBases.PlayerBaseUnload(Player)
	local PlayerID = Player.UserId

	local EmptyPlots = workspace:WaitForChild("EmptyPlots")
	local PlayerPlots = workspace:WaitForChild("Plots")
	local StoredBase1 = ServerStorage:WaitForChild("Bases"):WaitForChild("Plot")
	local StoredEmptyBase = ServerStorage:WaitForChild("Bases"):WaitForChild("EmptyPlot")
	
	for _, base in ipairs(PlayerPlots:GetChildren()) do
		if base.Name == tostring(PlayerID) then
			local EmptyPlot = Instance.new("Folder")
			EmptyPlot.Name = "EmptyPlot"
			EmptyPlot.Parent = EmptyPlots
			
			local EmptyBase = StoredEmptyBase:Clone()
			EmptyBase.Name = "EmptyPlot"
			EmptyBase.Parent = EmptyPlot
			
			if EmptyBase.PrimaryPart and base:GetChildren()[1] and base:GetChildren()[1].PrimaryPart then
				EmptyBase:PivotTo(base:GetChildren()[1].PrimaryPart.CFrame)
			else
				print("didnt work")
			end
			
			base:Destroy()
		end
	end
end

function LoadPlayerInventory(Player, Profile)
	local Stars = ServerStorage:WaitForChild("Stars")
	local Backpack = Player.Backpack
	
	for i, Item in pairs(Profile.Data.Inventory) do
		for _, StarTemplate in ipairs(Stars:GetDescendants()) do
			if StarTemplate:IsA("Tool") and StarTemplate.Name == Item.ItemName then
				local Star = StarTemplate:Clone()
				local Handle = Star:WaitForChild("Handle")

				Handle:SetAttribute("Sellable", Item.Sellable)
				Handle:SetAttribute("UniqueID", Item.UniqueID)
				Handle:SetAttribute("Owner", Item.Owner)
				
				Star.Parent = Backpack
			end
		end
	end
	
	print(`Loaded {Player.DisplayName}'s inventory!`)
end

function LoadPlayerMagnets(Player, PlayerBase, Profile)
	local Stars = ServerStorage:WaitForChild("Stars")
	local StarMagnets = PlayerBase:WaitForChild("StarMagnets")
	
	for i, SavedStar in pairs(Profile.Data.StarsInMagnet) do
		for _, StarTemplate in ipairs(Stars:GetDescendants()) do
			if StarTemplate:IsA("Tool") and StarTemplate.Name == SavedStar.StarName then
				local Magnet = SavedStar.MagnetParent
				
				local Star = StarTemplate:Clone()
				local Handle = Star:WaitForChild("Handle")
				local Glass = StarMagnets:WaitForChild(Magnet).Glass
				local TakeOutPrompt = Glass:WaitForChild("TakeOutPrompt")
				local PutInPrompt = Glass:WaitForChild("PutInPrompt")
				
				Handle:SetAttribute("Sellable", SavedStar.Sellable)
				Handle:SetAttribute("UniqueID", SavedStar.UniqueID)
				Handle:SetAttribute("Owner", SavedStar.Owner)
				
								
				Handle.Anchored = true
				Handle.CFrame = Glass.CFrame
				Handle.Parent = Glass
				Star:Destroy()
				
				Glass:WaitForChild("HasStar").Value = true
				PutInPrompt.Enabled = false
				TakeOutPrompt.Enabled = true
				
				StarInfoModule.StarfallInitialize(Player)
			end
		end
	end
	
	print(`Loaded {Player.DisplayName}'s magnets!`)
end



function PlayerBases.GetPlayerBase(PlayerID)
	local LoadedPlots = workspace:WaitForChild("Plots")
	
	for _, base in ipairs(LoadedPlots:GetChildren()) do
		if base.Name == tostring(PlayerID) then
			return base
		end
	end
end

return PlayerBases
