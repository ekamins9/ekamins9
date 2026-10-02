--[[ ECONOMY SERVER — Robux Developer Products (Crown bundles). Paste product
     ids into Catalog ▸ Economy ▸ products. ProcessReceipt credits the profile,
     saves, and only then tells Roblox the purchase is granted; a replayed
     receipt pays nothing twice. ]]
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local Economy = require(script.Parent:WaitForChild("Economy"))

MarketplaceService.ProcessReceipt = function(info)
	local plr = Players:GetPlayerByUserId(info.PlayerId)
	if not plr then return Enum.ProductPurchaseDecision.NotProcessedYet end
	local ok = Economy.grantProduct(plr, info.ProductId, info.PurchaseId)
	return ok and Enum.ProductPurchaseDecision.PurchaseGranted or Enum.ProductPurchaseDecision.NotProcessedYet
end
