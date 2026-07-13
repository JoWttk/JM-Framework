local NPC = {}
NPC.__index = NPC

NPC.list = {}
NPC.interactionDist = 40

local Window = require("engine.Interface.window")
local Dialogue = require("engine.DialogTypes.Dialogue")
local Input  = require("engine.Input")
local Player = require("entities.Player")
local Components = require("engine.EntitySystem.Components")

function NPC:new(name, x, y, overrides)
    local npc = {
        name     = name or "NPC",
        x        = x or 0,
        y        = y or 0,
        width    = 32,
        height   = 32,
        scale    = 1,
        flip     = false,
        sprite   = nil,
        anim     = nil,
        onInteract = nil,
        dialogues   = nil,
        interactable = true,
        disableAfterInteract = false,
        interactionDist = NPC.interactionDist,
        _promptShown = false,
    }

    Window.config({
        offsetX = 15,
        offsetY = -50,
        maxWidth = 300
    })

    function npc:setInteractable(bool)
        npc.interactable = bool

        if not bool then
            npc._promptShown = false
            if Window.isActive() and not Dialogue.isActive() then
                Window.close()
            end
        end
    end

    if overrides then
        if overrides.width  then npc.width  = overrides.width  end
        if overrides.height then npc.height = overrides.height end
        if overrides.scale  then npc.scale  = overrides.scale  end
        if overrides.flip   then npc.flip   = overrides.flip   end
        if overrides.sprite then npc.sprite = overrides.sprite end
        if overrides.onInteract then npc.onInteract = overrides.onInteract end
        if overrides.dialogues   then npc.dialogues   = overrides.dialogues   end
        if overrides.interactionDist then npc.interactionDist = overrides.interactionDist end
        if overrides.interactable ~= nil then npc.interactable = overrides.interactable end
        if overrides.disableAfterInteract ~= nil then npc.disableAfterInteract = overrides.disableAfterInteract end

        if overrides.animations and npc.sprite then
            local firstAnimName = next(overrides.animations)
            npc.anim = {
                animations = overrides.animations,
                current    = overrides.animations["idle"] and "idle" or firstAnimName,
                frame      = 1,
                timer      = 0,
            }
        end
    end

    setmetatable(npc, self)
    table.insert(NPC.list, npc)
    return npc
end

function NPC:isPlayerNearby()
    local entity = Player.getEntity()
    if not entity then return false end

    local pos = Components.Position[entity]
    local col = Components.Collider[entity]
    if not pos or not col then return false end

    local playerCX = pos.x + col.w / 2
    local playerCY = pos.y + col.h / 2

    local npcCX = self.x + self.width  / 2
    local npcCY = self.y + self.height / 2

    local dx = playerCX - npcCX
    local dy = playerCY - npcCY
    local dist = math.sqrt(dx * dx + dy * dy)

    return dist <= self.interactionDist
end

function NPC:_promptText()
    if CurrentLanguage == "pt" then
        return "Pressione {SPACE} para interagir"
    end

    return "Press {SPACE} to Interact"
end

function NPC:_showPrompt()
    if self._promptShown then return end
    self._promptShown = true
    Window.show(self:_promptText())
end

function NPC:_interact()
    if not self.interactable then
        return
    end

    Window.close()
    InteracteWithNpc:fire(self)
    self._promptShown = false

    if self.dialogues and #self.dialogues > 0 then
        Dialogue.showSequence(self.dialogues, {
            onComplete = function()
                if self.onInteract then
                    self.onInteract(self)
                end
            end
        })
        return
    end

    if self.onInteract then
        self.onInteract(self)
    end
end

function NPC:update(dt)
    if self.anim then
        local a   = self.anim
        local cur = a.animations[a.current]
        if cur and #cur.frames > 1 then
            a.timer = a.timer + dt
            if a.timer >= (cur.speed or 0.15) then
                a.timer = 0
                a.frame = a.frame + 1
                if a.frame > #cur.frames then
                    a.frame = 1
                end
            end
        end
    end
end

function NPC:draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.push()
    love.graphics.translate(self.x, self.y)

    local scaleX = (self.flip and -1 or 1) * self.scale
    local scaleY = self.scale
    local drawX  = self.flip and (self.width) or 0

    if self.sprite then
        if self.anim then
            local cur   = self.anim.animations[self.anim.current]
            local frame = cur and cur.frames[self.anim.frame]
            if frame then
                love.graphics.draw(self.sprite, frame, drawX, 0, 0, scaleX, scaleY)
            else
                love.graphics.draw(self.sprite, drawX, 0, 0, scaleX, scaleY)
            end
        else
            love.graphics.draw(self.sprite, drawX, 0, 0, scaleX, scaleY)
        end
    else
        love.graphics.setColor(0.3, 0.6, 1)
        love.graphics.rectangle("fill", 0, 0, self.width, self.height)
        love.graphics.setColor(0, 0, 0)
        local eyeX = self.flip and (self.width * 0.25) or (self.width * 0.75)
        love.graphics.ellipse("fill", eyeX, self.height * 0.3, 3, 4)
    end

    love.graphics.pop()
    love.graphics.setColor(1, 1, 1)
end

function NPC.updateAll(dt)
    local nearAny = false
    local nearNPC = nil

    for _, npc in ipairs(NPC.list) do
        npc:update(dt)
        if npc.interactable and npc:isPlayerNearby() then
            nearAny = true
            nearNPC = npc
        end
    end

    if nearAny and nearNPC then
        if not Window.isActive() and not Dialogue.isActive() then
            nearNPC:_showPrompt()
        end

        if Input.wasPressed("space") and not Dialogue.isActive() then
            nearNPC:_interact()
        end
    else
        for _, npc in ipairs(NPC.list) do
            npc._promptShown = false
        end

        if Window.isActive() and not Dialogue.isActive() then
            Window.close()
        end
    end
end

function NPC.drawAll()
    for _, npc in ipairs(NPC.list) do
        npc:draw()
    end
end

function NPC.clear()
    NPC.list = {}
end

function NPC.remove(npc)
    for i, n in ipairs(NPC.list) do
        if n == npc then
            table.remove(NPC.list, i)
            break
        end
    end
end

return NPC