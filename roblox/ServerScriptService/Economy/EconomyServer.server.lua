--[[ ECONOMY SERVER — Robux Developer Products (Crown bundles). Make the
     products on the Creator Dashboard (Monetization ▸ Developer Products)
     named exactly like Catalog ▸ Economy ▸ products' `product` ("100 Crowns",
     "550 Crowns", …): at start this looks them up by name and fills the ids,
     so nothing needs pasting (an explicit `id` still wins). ProcessReceipt
     credits the profile, saves, and only then tells Roblox the purchase is
     granted; a replayed receipt pays nothing twice. ]]
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local Economy = require(script.Parent:WaitForChild("Economy"))
local Catalog = require(game:GetService("ReplicatedStorage"):WaitForChild("Catalog"))

-- fill product ids from the universe's Developer Products, by name
task.spawn(function()
	local byName = {}
	local ok, err = pcall(function()
		local pages = MarketplaceService:GetDeveloperProductsAsync()
		while true do
			for _, p in ipairs(pages:GetCurrentPage()) do byName[string.lower(p.Name or "")] = p end
			if pages.IsFinished then break end
			pages:AdvanceToNextPageAsync()
		end
	end)
	if not ok then warn("[Economy] could not list Developer Products:", err); return end
	local found = 0
	for _, prod in ipairs(Catalog.ECONOMY.products) do
		local entry = byName[string.lower(prod.product or (tostring(prod.crowns) .. " Crowns"))]
		if entry then
			if (prod.id or 0) == 0 then prod.id = entry.ProductId end
			found += 1
			-- the dashboard is the truth for the price and the bundle art
			prod.robux = entry.PriceInRobux or prod.robux
			prod.icon = entry.IconImageAssetId
		end
	end
	print(string.format("[Economy] %d / %d Crown bundles linked to Developer Products", found, #Catalog.ECONOMY.products))
end)

MarketplaceService.ProcessReceipt = function(info)
	local plr = Players:GetPlayerByUserId(info.PlayerId)
	if not plr then return Enum.ProductPurchaseDecision.NotProcessedYet end
	local ok = Economy.grantProduct(plr, info.ProductId, info.PurchaseId)
	return ok and Enum.ProductPurchaseDecision.PurchaseGranted or Enum.ProductPurchaseDecision.NotProcessedYet
end
