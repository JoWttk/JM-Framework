local Enemy = {}
Enemy.__index = Enemy

local Text     = require("engine.Interface.text")
local Signal   = require("engine.Utils.signal")
local Platform = require("engine.EntitySystem.Platform")

Enemy.list   = {}
Enemy.onDied = Signal.new()

-- ============================================================
-- TIPOS DISPONÍVEIS:
--   "walker"   - patrulha básica, dano leve
--   "stomper"  - patrulha, morre se player pular em cima (Mario)
--   "tank"     - patrulha lenta, muito HP, dano pesado (NÃO é stompable)
--   "shooter"  - patrulha, para e atira quando player entra no range
--   "dasher"   - patrulha, faz dash quando player se aproxima
--
-- Todos os tipos (exceto o tank) são stompable (morrem instantaneamente se o player pular em cima).
--
-- SPAWN:
--   Enemy:new("walker", x, y)
--   Enemy:new("walker", x, y, { patrolDist = 200 })
--   Enemy:new("walker", x, y, { sprite = love.graphics.newImage(...) })
--   Enemy:new("walker", x, y, {
--       sprite = img,
--       animations = {
--           walk = { frames = { q1, q2 }, speed = 0.15 },
--           idle = { frames = { q0 },    speed = 0.4  },
--       }
--   })
--
-- SIGNAL:
--   Enemy.onDied:connect(function(enemy)
--       print("morreu:", enemy.name, "em", enemy.x, enemy.y)
--   end)
-- AI

local KNOCKBACK_HIT_SPEED  = 260  
local KNOCKBACK_AOE_RADIUS = 90  
local KNOCKBACK_AOE_SPEED  = 200  
local KB_FRICTION          = 700

local GRAVITY = 1200 
local VOID_Y  = 1500

local LEDGE_CHECK_AHEAD = 6 
local LEDGE_CHECK_DEPTH = 6

function Enemy:new(enemyType, x, y, overrides, onDie)
    local templates = {
        walker = {
            name        = "Walker",
            health      = 20,  -- 2 ataques para matar
            damage      = 10,
            speed       = 70,
            width       = 32,
            height      = 32,
            color       = {1, 0.3, 0.3},
            patrolDist  = 120,
            stompable   = true,
            stompHeight = 16,
            healthBarColor   = {1, 0.35, 0.35},
            healthBarBgColor = {0.35, 0.1, 0.1},
            noGravity = false
        },
        stomper = {
            name        = "Stomper",
            health      = 20,  -- 2 ataques para matar
            damage      = 20,
            speed       = 80,
            width       = 32,
            height      = 32,
            color       = {0.9, 0.6, 0.1},
            patrolDist  = 100,
            stompable   = true,
            stompHeight = 16,
            healthBarColor   = {1, 0.65, 0.1},
            healthBarBgColor = {0.35, 0.22, 0.03},
            noGravity = false,
        },
        tank = {
            name        = "Tank",
            health      = 50,  -- 5 ataques para matar
            damage      = 25,
            speed       = 28,
            width       = 48,
            height      = 48,
            color       = {0.4, 0.4, 0.9},
            patrolDist  = 80,
            knockbackResist = true,
            stompable   = false,
            healthBarColor   = {0.35, 0.55, 1},
            healthBarBgColor = {0.08, 0.12, 0.3},
            tankAttackRange    = 120,
            tankChargeSpeed    = 300,
            tankChargeDuration = 0.3,
            tankChargeTimer    = 0,
            tankCharging       = false,
            tankChargeDir      = 0,
            tankCooldown       = 2.0,
            tankCooldownTimer  = 0,
            noGravity = false,
        },
        shooter = {
            name             = "Shooter",
            health           = 30,  -- 3 ataques para matar
            damage           = 8,
            speed            = 45,
            width            = 32,
            height           = 32,
            color            = {0.8, 0.2, 0.8},
            patrolDist       = 150,
            shootCooldown    = 2.5,
            shootTimer       = 2.5, 
            projectileDamage = 35,
            projectileSpeed  = 200,
            shootRange       = 250,
            isShooting       = false,
            stompable        = false,
            stompHeight      = 16,
            healthBarColor   = {0.9, 0.3, 0.9},
            healthBarBgColor = {0.3, 0.08, 0.3},
            onAttackEnd = nil,
            noGravity = false,
        },
        dasher = {
            name         = "Dasher",
            health       = 40,  -- 4 ataques para matar
            damage       = 18,
            speed        = 50,
            dashSpeed    = 420,
            width        = 32,
            height       = 32,
            color        = {0.2, 0.9, 0.7},
            patrolDist   = 130,
            dashRange    = 180,
            dashCooldown = 3,
            dashTimer    = 0,
            dashing      = false,
            dashDuration = 0.25,
            dashTimeLeft = 0,
            dashDirX     = 0,
            stompable    = true,
            stompHeight  = 16,
            noGravity    = true,
            healthBarColor   = {0.25, 1, 0.8},
            healthBarBgColor = {0.05, 0.3, 0.25},
        },
    }

    local t = templates[enemyType]
    assert(t, "Unknown enemy type: " .. tostring(enemyType))

    local enemy = {}
    for k, v in pairs(t) do enemy[k] = v end

    if overrides then
        for k, v in pairs(overrides) do
            if k ~= "animations" then
                enemy[k] = v
            end
        end
    end

    enemy.type        = enemyType
    enemy.x           = x
    enemy.y           = y
    enemy.maxHealth   = enemy.health
    enemy.projectiles = {}

    enemy.patrolOrigin = x
    enemy.patrolDir    = 1
    enemy.flip         = false

    enemy.sprite = overrides and overrides.sprite or nil
    enemy.anim   = nil

    if overrides and overrides.animations and overrides.sprite then
        enemy.anim = {
            animations = overrides.animations,
            current    = next(overrides.animations),
            frame      = 1,
            timer      = 0,
        }
    end

    enemy.state         = "alive"
    enemy.deathMode      = nil
    enemy.deathTimer     = 0
    enemy.deathDuration  = 0
    enemy.deathVX        = 0
    enemy.deathVY        = 0
    enemy.deathRotation  = 0

    enemy.hitFlashTimer  = 0
    enemy.HIT_FLASH_DURATION = 0.12

    enemy.kbVX = 0

    enemy.vy       = 0
    enemy.grounded = false

    enemy.bobTimer = 0
    enemy.bobOffset = 0
    enemy.bobSquash = 1

    enemy.spriteScale = 1
    enemy.baseWidth   = enemy.width
    enemy.baseHeight  = enemy.height
    enemy.onDie = onDie or nil

    function enemy:setSpriteScale(scale)
        scale = scale or 1

        local oldWidth  = enemy.width
        local oldHeight = enemy.height

        local newWidth  = enemy.baseWidth  * scale
        local newHeight = enemy.baseHeight * scale

        enemy.x = enemy.x + (oldWidth  - newWidth)  / 2
        enemy.y = enemy.y + (oldHeight - newHeight)

        enemy.patrolOrigin = enemy.patrolOrigin + (oldWidth - newWidth) / 2

        enemy.width  = newWidth
        enemy.height = newHeight
        enemy.spriteScale = scale

        return enemy
    end

    setmetatable(enemy, self)
    table.insert(Enemy.list, enemy)
    return enemy
end

function Enemy:takeDamage(amount)
    if not self:isAlive() then return end
    if self._damagedThisFrame then return end 
    self._damagedThisFrame = true
    
    self.health = math.max(self.health - amount, 0)

    self.hitFlashTimer = self.HIT_FLASH_DURATION

    if self.health <= 0 then
        self:startDeath()
    end
end

function Enemy:isAlive()
    return self.state == "alive"
end

function Enemy:startDeath()
    if self.state ~= "alive" then return end

    love.audio.play(SOUNDS["hit"])

    if self.onDie then
        self.onDie()
    end

    self.state        = "dying"
    self.deathTimer    = 0
    self.deathDuration = 0.15
end

function Enemy:_updateDeath(dt)
    self.deathTimer = self.deathTimer + dt
    if self.deathTimer >= self.deathDuration then
        self.state = "dead"
        Enemy.onDied:fire(self)
    end
end

function Enemy:_applyKnockback(dt)
    if self.kbVX == 0 then return end

    self.x = self.x + self.kbVX * dt

    local decay = KB_FRICTION * dt
    if self.kbVX > 0 then
        self.kbVX = math.max(0, self.kbVX - decay)
    elseif self.kbVX < 0 then
        self.kbVX = math.min(0, self.kbVX + decay)
    end
end

function Enemy:_applyGravity(dt)
    if self.noGravity then
        self.vy = 0
        self.grounded = true
        return
    end

    self.vy = self.vy + GRAVITY * dt
    self.y  = self.y + self.vy * dt

    self.grounded = false

    for _, platform in ipairs(Platform.list) do
        if platform.canCollide then
            local overlapX = self.x < platform.x + platform.w and self.x + self.width  > platform.x
            local overlapY = self.y < platform.y + platform.h and self.y + self.height > platform.y

            if overlapX and overlapY then
                if self.vy > 0 then
                    self.y = platform.y - self.height
                    self.vy = 0
                    self.grounded = true
                elseif self.vy < 0 then
                    self.y = platform.y + platform.h
                    self.vy = 0
                end
            end
        end
    end

    if self.y > VOID_Y then
        self:_fallIntoVoid()
    end
end

function Enemy:_fallIntoVoid()
    if self.state == "dead" then return end
    self:startDeath()
end

function Enemy:_groundAheadX(dirX)
    if dirX == 0 then return true end

    local checkX = dirX > 0
        and (self.x + self.width + LEDGE_CHECK_AHEAD)
        or  (self.x - LEDGE_CHECK_AHEAD)
    local checkY = self.y + self.height + LEDGE_CHECK_DEPTH

    for _, platform in ipairs(Platform.list) do
        if platform.canCollide then
            if checkX >= platform.x and checkX <= platform.x + platform.w
            and checkY >= platform.y and checkY <= platform.y + platform.h then
                return true
            end
        end
    end

    return false
end

function Enemy:update(dt, player)
    self._damagedThisFrame = false 
    
    if self.hitFlashTimer > 0 then
        self.hitFlashTimer = math.max(0, self.hitFlashTimer - dt)
    end

    if self.state == "dead" then return end

    self:_applyKnockback(dt)
    self:_applyGravity(dt)

    if self.state == "dying" then
        self:_updateDeath(dt)
        return
    end

    self:_updateBob(dt)

    local dx   = player.x - self.x
    local dy   = player.y - self.y
    local dist = math.sqrt(dx * dx + dy * dy)

    if self.type == "walker" or self.type == "stomper" then
        self:_patrol(dt)
    elseif self.type == "tank" then
        self.tankCooldownTimer = self.tankCooldownTimer + dt

        if self.tankCharging then
            -- Executa a carga
            self.tankChargeTimer = self.tankChargeTimer + dt
            self.x = self.x + self.tankChargeDir * self.tankChargeSpeed * dt
            self.flip = self.tankChargeDir < 0

            if self.tankChargeTimer >= self.tankChargeDuration then
                self.tankCharging = false
                self.tankChargeTimer = 0
                self.tankCooldownTimer = 0
            end
        else
            -- Verifica se o jogador está no alcance e o cooldown está pronto
            if dist <= self.tankAttackRange and self.tankCooldownTimer >= self.tankCooldown then
                -- Inicia a carga
                self.tankCharging = true
                self.tankChargeTimer = 0
                self.tankChargeDir = (dx ~= 0) and (dx / math.abs(dx)) or 0
                self.tankCooldownTimer = 0
            else
                self:_patrol(dt)
            end
        end
    elseif self.type == "shooter" then
        if dist <= self.shootRange then
            if not self.attacking then
                self.attacking = true
                
                self.onAttackEnd = function(enemy)
                    enemy:_shoot(player)
                    enemy.attacking = false
                end
                
                self:_setAnim("attack")
            end
        else
            self.attacking = false
            self:_patrol(dt)
        end
        
        self:_updateProjectiles(dt, player)
    elseif self.type == "dasher" then
        self.dashTimer = self.dashTimer + dt

        if self.dashing then
            if self.noGravity and not self:_groundAheadX(self.dashDirX) then
                self.dashing      = false
                self.dashTimeLeft = 0
            else
                self.dashTimeLeft = self.dashTimeLeft - dt
                self.x = self.x + self.dashDirX * self.dashSpeed * dt
                self.flip = self.dashDirX < 0

                if self.dashTimeLeft <= 0 then
                    self.dashing = false
                end

                self:_setAnim("dash")
            end
        else
            if dist <= self.dashRange and self.dashTimer >= self.dashCooldown then
                self.dashTimer    = 0
                self.dashing      = true
                self.dashTimeLeft = self.dashDuration
                self.dashDirX     = (dx ~= 0) and (dx / math.abs(dx)) or 0
            else
                self:_patrol(dt)
            end
        end
    end

    self:_updateAnim(dt)
end

local function drawSpriteWithFlash(sprite, frame, drawX, scaleX, scaleY, flashing, flashAmt)
    love.graphics.setColor(1, 1, 1, 1)
    if frame then
        love.graphics.draw(sprite, frame, drawX, 0, 0, scaleX, scaleY)
    else
        love.graphics.draw(sprite, drawX, 0, 0, scaleX, scaleY)
    end

    if flashing then
        love.graphics.setBlendMode("add")
        love.graphics.setColor(1, 1, 1, flashAmt * 0.85)
        if frame then
            love.graphics.draw(sprite, frame, drawX, 0, 0, scaleX, scaleY)
        else
            love.graphics.draw(sprite, drawX, 0, 0, scaleX, scaleY)
        end
        love.graphics.setBlendMode("alpha")
        love.graphics.setColor(1, 1, 1, 1)
    end
end

function Enemy:_drawBody()
    local flashing = self.hitFlashTimer > 0
    local flashAmt = flashing and (self.hitFlashTimer / self.HIT_FLASH_DURATION) or 0

    local scale  = self.spriteScale or 1
    local scaleX = (self.flip and -1 or 1) * scale
    local scaleY = scale
    local drawX  = self.flip and self.width or 0

    if self.sprite then
        local frame = nil
        if self.anim then
            local cur = self.anim.animations[self.anim.current]
            frame = cur and cur.frames and cur.frames[self.anim.frame]
        end

        drawSpriteWithFlash(self.sprite, frame, drawX, scaleX, scaleY, flashing, flashAmt)
    else
        local r, g, b = self.color[1], self.color[2], self.color[3]
        if flashing then
            r = r + (1 - r) * flashAmt
            g = g + (1 - g) * flashAmt
            b = b + (1 - b) * flashAmt
        end

        love.graphics.setColor(r, g, b)
        love.graphics.rectangle("fill", 0, 0, self.width, self.height)

        love.graphics.setColor(0, 0, 0)
        local eyeX = self.flip
            and (self.width * 0.25 - 3)
            or  (self.width * 0.75 - 3)
        love.graphics.ellipse("fill", eyeX, self.height * 0.3, 4, 5)

        if self.type == "dasher" and self.dashing then
            love.graphics.setColor(1, 1, 0, 0.45)
            love.graphics.rectangle("fill", 0, 0, self.width, self.height)
        end

        if self.type == "shooter" and self.isShooting then
            love.graphics.setColor(1, 0.3, 1, 0.35)
            love.graphics.rectangle("fill", 0, 0, self.width, self.height)
        end
    end
end

function Enemy:_drawDying()
    local scaleY = 0.15
    local cx     = self.x + self.width / 2
    local by     = self.y + self.height

    love.graphics.push()
    love.graphics.translate(cx, by)
    love.graphics.scale(1, scaleY)
    love.graphics.translate(-self.width / 2, -self.height)
    love.graphics.setColor(1, 1, 1, 1)
    self:_drawBody()
    love.graphics.pop()
    love.graphics.setColor(1, 1, 1, 1)
end

function Enemy:_drawHealthBar()
    local barX, barY = self.x, self.y - 10
    local barW, barH = self.width, 5
    local hpRatio = self.health / self.maxHealth

    local bgColor = self.healthBarBgColor or {0.15, 0.15, 0.15}
    love.graphics.setColor(bgColor[1], bgColor[2], bgColor[3])
    love.graphics.rectangle("fill", barX, barY, barW, barH)

    if self.healthBarColor then
        love.graphics.setColor(self.healthBarColor[1], self.healthBarColor[2], self.healthBarColor[3])
    else
        love.graphics.setColor(0.1 + 0.9 * (1 - hpRatio), 0.9 * hpRatio, 0.05)
    end
    love.graphics.rectangle("fill", barX, barY, barW * hpRatio, barH)

    love.graphics.setColor(1, 1, 1, 1)
end

function Enemy:draw()
    if self.state == "dead" then return end

    if self.state == "dying" then
        self:_drawDying()
        return
    end

    love.graphics.setColor(1, 1, 1)
    love.graphics.push()
    love.graphics.translate(self.x, self.y + self.bobOffset)
    love.graphics.push()
    love.graphics.translate(self.width / 2, self.height)
    love.graphics.scale(1, self.bobSquash)
    love.graphics.translate(-self.width / 2, -self.height)
    self:_drawBody()
    love.graphics.pop()
    love.graphics.pop()
    love.graphics.setColor(1, 1, 1, 1)

    if self.type == "shooter" then
        for _, p in ipairs(self.projectiles) do
            if p.sprite then
                love.graphics.setColor(1, 1, 1, 1)
                local imgW = p.sprite:getWidth()
                local imgH = p.sprite:getHeight()
                love.graphics.draw(p.sprite, p.x, p.y, p.rotation, 1, 1, imgW / 2, imgH / 2)
            else
                love.graphics.setColor(1, 0.4, 1)
                love.graphics.circle("fill", p.x, p.y, 5)
                love.graphics.setColor(1, 1, 1, 1)
            end
        end
    end

    self:_drawHealthBar()
end

function Enemy.checkStomp(enemy, player)
    if not enemy.stompable then return false end
    if not enemy:isAlive() then return false end

    local playerBottom = player.y + player.height
    local enemyMid      = enemy.y + enemy.height * 0.5

    local hOverlap =
        player.x < enemy.x + enemy.width and
        player.x + player.width > enemy.x

    local falling       = player.vy and player.vy > 0
    local cameFromAbove = playerBottom <= enemyMid + 8

    return hOverlap and falling and cameFromAbove
end

function Enemy:isTouching(player)
    if not self:isAlive() then return false end
    return
        self.x < player.x + player.width and
        self.x + self.width > player.x   and
        self.y < player.y + player.height and
        self.y + self.height > player.y
end

function Enemy.registerPlayerAttack(Player)
    Player.onAttackHit:connect(function(hx, hy, hw, hh)
        local hitCenterX = hx + hw / 2
        local hitCenterY = hy + hh / 2

        for _, e in ipairs(Enemy.list) do
            if e:isAlive() then
                local overlap =
                    hx < e.x + e.width and
                    hx + hw > e.x and
                    hy < e.y + e.height and
                    hy + hh > e.y

                if overlap then
                    local dmg = (Player.stats and Player.stats.Attack or 1) * 10
                    e:takeDamage(dmg)

                    if not e.knockbackResist then
                        local dir = (e.x + e.width / 2 < hitCenterX) and -1 or 1
                        e.kbVX = dir * KNOCKBACK_HIT_SPEED
                    end
                else
                    local ecx = e.x + e.width / 2
                    local ecy = e.y + e.height / 2
                    local ddx = ecx - hitCenterX
                    local ddy = ecy - hitCenterY
                    local d   = math.sqrt(ddx * ddx + ddy * ddy)

                    if d <= KNOCKBACK_AOE_RADIUS and not e.knockbackResist then
                        local dir     = (ddx < 0) and -1 or 1
                        local falloff = 1 - (d / KNOCKBACK_AOE_RADIUS)
                        e.kbVX = dir * KNOCKBACK_AOE_SPEED * falloff
                    end
                end
            end
        end
    end)
end

function Enemy.updateAll(dt, player)
    for _, e in ipairs(Enemy.list) do
        e:update(dt, player)
 
        if e:isAlive() and e:isTouching(player) then
            if e.stompable and Enemy.checkStomp(e, player) then
                e:startDeath()
                if player.bounceJump then player:bounceJump() end
            else
                if e.type == "tank" and e.tankCharging then
                    if player.takeDamage then
                        player:takeDamage(e.damage * 2)
                        if player.takeKnockback then
                            local dir = (e.x + e.width/2 < player.x + player.width/2) and 1 or -1
                            player:takeKnockback(dir * 400)
                        end
                    end
                else
                    -- Todos os outros dão dano normal
                    if player.takeDamage then
                        player:takeDamage(e.damage)
                    end
                end
            end
        end
    end

    for i = #Enemy.list, 1, -1 do
        if Enemy.list[i].state == "dead" then
            table.remove(Enemy.list, i)
        end
    end
end

function Enemy.drawAll()
    for _, e in ipairs(Enemy.list) do
        e:draw()
    end
end

function Enemy.remove(enemy)
    for i, e in ipairs(Enemy.list) do
        if e == enemy then
            table.remove(Enemy.list, i)
            break
        end
    end
end

function Enemy.clear()
    Enemy.list = {}
end

function Enemy:_updateBob(dt)
    if self.state ~= "alive" or (self.anim and self.type ~= "shooter") then
        self.bobOffset = 0
        self.bobSquash = 1
        return
    end

    local bobOffsetMultiplier = 2.5
    local bobFreqMultiplier = 6

    if self.type == "shooter" then
        bobOffsetMultiplier = 1.25 
        bobFreqMultiplier = 6
    end

    local freq = (self.speed / 100) * bobFreqMultiplier 
    self.bobTimer = self.bobTimer + dt * freq

    self.bobOffset = math.sin(self.bobTimer) * bobOffsetMultiplier

    local sinVal = math.sin(self.bobTimer)
    self.bobSquash = 1 + sinVal * 0.06
end

function Enemy:_patrol(dt)
    local dest = self.patrolOrigin + self.patrolDir * self.patrolDist

    if self.patrolDir == 1 and self.x >= dest then
        self.patrolDir = -1
    elseif self.patrolDir == -1 and self.x <= self.patrolOrigin - self.patrolDist then
        self.patrolDir = 1
    end

    if self.noGravity and not self:_groundAheadX(self.patrolDir) then
        self.patrolDir = -self.patrolDir
    end

    self.x    = self.x + self.patrolDir * self.speed * dt
    self.flip = self.patrolDir < 0

    self:_setAnim("walk")
end

function Enemy:_setAnim(name)
    if not self.anim then return end
    if not self.anim.animations[name] then return end
    if self.anim.current == name then return end
    self.anim.current = name
    self.anim.frame   = 1
    self.anim.timer   = 0
end

function Enemy:_updateAnim(dt)
    if not self.anim then return end
    local a   = self.anim
    local cur = a.animations[a.current]
    if not cur then return end

    a.timer = a.timer + dt
    if a.timer >= cur.speed then
        a.timer = 0
        a.frame = a.frame + 1
        if a.frame > #cur.frames then
            a.frame = 1
            
            if a.current == "attack" and self.onAttackEnd then
                self.onAttackEnd(self)
                self.onAttackEnd = nil
            end
            
            if a.current == "attack" then
                a.current = "walk"
            end
        end
    end
end

function Enemy:_shoot(player)
    if not player.x or not player.y then return end

    local dx   = player.x - self.x
    local dy   = player.y - self.y
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist < 1 then return end

    local projX = self.x + self.width / 2
    local projY = self.y + self.height / 2
    local projVX = (dx / dist) * self.projectileSpeed
    local projVY = (dy / dist) * self.projectileSpeed

    if not self.bananaImg then
        self.bananaImg = ENEMIES.shooter.BANANA
    end

    table.insert(self.projectiles, {
        x        = projX,
        y        = projY,
        vx       = projVX,
        vy       = projVY,
        life     = 3,
        rotation = 0,
        vr       = math.rad(1080),
        sprite   = self.bananaImg
    })

    self:_setAnim("attack")
end

function Enemy:_updateProjectiles(dt, player)
    for i = #self.projectiles, 1, -1 do
        local p = self.projectiles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.life = p.life - dt
        
        -- Atualiza o ângulo de rotação da banana
        if p.rotation then
            p.rotation = p.rotation + p.vr * dt
        end

        local hit = false

        if player.takeDamage then
            local px, py = player.x, player.y
            local pw     = player.width  or 16
            local ph     = player.height or 32
            if p.x >= px and p.x <= px + pw and p.y >= py and p.y <= py + ph then
                player:takeDamage(self.projectileDamage)
                table.remove(self.projectiles, i)
                hit = true
            end
        end

        if not hit and p.life <= 0 then
            table.remove(self.projectiles, i)
        end
    end
end

function Enemy.changeAllEnemiesHealth(multiplier)
    for _, e in ipairs(Enemy.list) do
        if e:isAlive() then
            local ratio = e.health / e.maxHealth
            e.maxHealth = e.maxHealth * multiplier
            e.health    = e.maxHealth * ratio
        end
    end
end

Enemy.onDied:connect(function(e)
    -- e : enemy
    _G.getPlayer().addPoints(100, e)
end)

return Enemy