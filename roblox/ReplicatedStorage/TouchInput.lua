--[[ TOUCH INPUT — the go-between for the on-screen controls on a phone or a
     tablet (StarterPlayerScripts ▸ TouchControls) and the scripts that act on
     input (CombatClient, Movement, CameraRig). A button press here is the same
     action a key bind is everywhere else.

       TouchInput.active()            a touch screen with no keyboard (show the buttons)
       TouchInput.press(action, down, side)   the controls: an action pressed (down)
                                      or let go; side "Left" / "Right" for a swing
       TouchInput.changed             :Connect(fn(action, down, side))
       TouchInput.addLook(dx, dy)     a drag on the screen turns the camera…
       TouchInput.takeLook() -> dx, dy  …CameraRig takes it each frame

     Actions: Swing · Stab · Overhead · Feint · Kick · Block (held) · Dodge ·
     Jump · Sprint (held) · Emote ]]

local UserInputService = game:GetService("UserInputService")

local TouchInput = {}
local ev = Instance.new("BindableEvent")
TouchInput.changed = ev.Event

local lookX, lookY = 0, 0

function TouchInput.active()
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

function TouchInput.press(action, down, side)
	ev:Fire(action, down ~= false, side)
end

function TouchInput.addLook(dx, dy)
	lookX += dx
	lookY += dy
end

function TouchInput.takeLook()
	local x, y = lookX, lookY
	lookX, lookY = 0, 0
	return x, y
end

return TouchInput
