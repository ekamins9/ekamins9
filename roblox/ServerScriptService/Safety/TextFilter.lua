--[[ TEXT FILTER — Roblox's own filter (TextService), for anything a person typed that someone
     else will read. Roblox requires it ("all incoming text that originates from another user
     must first use text filtering before your game displays it"), and a game without it can
     be taken down. The players' chat is Roblox's TextChatService, filtered already. These
     are the game's own texts:
       • a custom server's name (Hub ▸ HubServer: the server list, the scoreboard);
       • staff's words (Admin ▸ AdminServer: an announcement, a kick, ban or shutdown reason,
         a title given to a player).

       TextFilter.broadcast(text, fromUserId) -> text for everyone, or nil if it couldn't be
                                                 checked (then don't show it)
       TextFilter.forUser(text, fromUserId, toUserId) -> text for that one reader, or nil

     Both yield (the filter is a web call). A failed check means "don't show it": never fall
     back to the raw text. ]]

local TextService = game:GetService("TextService")

local TextFilter = {}

local function result(text, fromUserId)
	local ok, res = pcall(TextService.FilterStringAsync, TextService, text, fromUserId, Enum.TextFilterContext.PublicChat)
	return ok and res or nil
end

function TextFilter.broadcast(text, fromUserId)
	text = tostring(text or "")
	if text:match("^%s*$") then return "" end
	local r = result(text, fromUserId)
	if not r then return nil end
	local ok, out = pcall(r.GetNonChatStringForBroadcastAsync, r)
	return ok and out or nil
end

function TextFilter.forUser(text, fromUserId, toUserId)
	text = tostring(text or "")
	if text:match("^%s*$") then return "" end
	local r = result(text, fromUserId)
	if not r then return nil end
	local ok, out = pcall(r.GetNonChatStringForUserAsync, r, toUserId)
	return ok and out or nil
end

return TextFilter
