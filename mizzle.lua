-- Every unique enemy class must have its own file. Don't try to make a Froggit as a Mizzle().

require "animate"

Mizzle = Object:extend()

function Mizzle:new(name, x, y, animations, spritesheet, spritesheetarray, defaultanim, size, maxhp)

    self.name = name
    self.x = x
    self.y = y
    self.animations = animations
    self.defaultanim = defaultanim
    self.size = size
    self.maxhp = maxhp
    self.hp = maxhp

    self.type = "MIZZLE" --Not an argument. Define individually for every class.

    self.currentanimation = defaultanim
    self.currentquadrant = nil
    self.currentframecount = 1

    self.spritesheet = spritesheet

    self.quadrants = {}

    local sheetwidth, sheetheight = spritesheetarray.meta.size.w, spritesheetarray.meta.size.h

    for i = 0,#self.animations do

        self.animations[i][5] = self.animations[i][5] * self.size
        self.animations[i][6] = self.animations[i][6] * self.size

        self.quadrants[i] = {}

        for j = 1,animations[i][2] do
            local localquad = spritesheetarray.frames[self.animations[i][1]..j..".png"].frame
            self.quadrants[i][j] = love.graphics.newQuad(localquad.x, localquad.y, localquad.w, localquad.h, sheetwidth, sheetheight)
        end

    end

    self.sparable = false
    self.mercy = 0
    self.mercytable = { --used for the mercyup
        ["* Lullaby"] = 50
    }

    self.sleeping = true

    self.initialx = x

    self.mercied = false

end

function Mizzle:act(actname, ui) --Handle acts passed by a partyMember() based on actname

    if actname == "* Alarm" then
        self.sleeping = false
        self:set_animation(2)

    elseif actname == "* Lullaby" then
        self.sleeping = true
        self.mercy = self.mercy + 50
        if self.mercy >= 100 then
            self.sparable = true
        end
        self:set_animation(0)

        if self.mercy > 100 then
            self.mercy = 100
        end

    else
        
        --Not necessary, but helpful for debugging.
        ui:subtext("* Someone did an act...\n* But it was not defined in the enemy file!\n* Check mizzle.lua")

    end

    if self.sleeping == true then
        print(self.name.." is sleeping!")
    else
        print(self.name.." is awake!")
    end

end

function Mizzle:hurt(n)
    if n > 0 then
        if self.sleeping then
            self.sleeping = false
            self:set_animation(4)
        end
        self.hp = self.hp - n
        print(self.name.." hp is: "..self.hp)
    else
        print(self.name.." was not hurt!")
    end
end

function Mizzle:set_animation(n)
    print(self.name.." animation changed from number "..self.currentanimation.." to number "..n)
    --The mizzle has 2 sets of sprites, so if it's sparable the pink alternative is used.
    --My example code only passes the animations for the non-pink animations
    --Otherwise, you'd get completely different animations!
    self.currentanimation = n

    if self.sparable then
        self.currentanimation = n+1
    end
    
    self.currentframecount = 1

end

function Mizzle:draw()

    if self.currentquadrant then
        love.graphics.draw(self.spritesheet, self.currentquadrant, self.x + self.animations[self.currentanimation][5], self.y + self.animations[self.currentanimation][6], 0, self.size, self.size)

    end

    if self.mercyup then
        love.graphics.setFont(Goldenfont)
        love.graphics.print("+"..self.mercyup.."%", self.initialx-100, self.y, 0, 1.5, 1.5)
    end

    if self.hp <= 0 and self.x <= 1750 then
        love.graphics.draw(LOST, self.initialx-50, self.y-50, 0, 1.2, 1.2)
    end
    if self.mercied and self.x <= 1750 then
        love.graphics.draw(RECRUIT, self.initialx-50, self.y-50, 0, 1.2, 1.2)
    end

end

function Mizzle:remove(enemies)


    local toRemove --index of the enemy to remove from the list
    local lastEnemy = false

    for i = 1, #enemies do
        if enemies[i] == self then
            toRemove = i
            print(i)
            if toRemove == #enemies then lastEnemy = true end --if it's the last enemy the removal is simple.
            print("lastEnemy: "..tostring(lastEnemy))
        end
    end

    table.remove(enemies, toRemove)

    if lastEnemy then --The super easy last enemy removal
        Enemysubarray[#Enemysubarray] = nil
    else --Removes enemy from and rebuilds the enemysubarray array as if the removed enemy never existed.
        local neoEnemysubarray = Enemysubarray
        for i = toRemove, #Enemysubarray-1 do
            neoEnemysubarray[i][1] = Enemysubarray[i+1][1]
        end
        Enemysubarray = neoEnemysubarray
        Enemysubarray[#Enemysubarray] = nil
    end

    --No leftovers (or the dish will cry)
    collectgarbage("collect")

end

function Mizzle:spared()

    self.mercy = self.mercy + 20
    self.mercyup = 20

    if self.mercy >= 100 then
        self.mercied = true
        if self.mercy > 100 then
            self.mercyup = self.mercyup - (self.mercy - 100)
            self.mercy = 100
        else
            self.mercyup = nil --Setting to 0 activates the display logic, so we set it to nil instead.
        end
    else
        self.mercied = false
    end

    print(self.name.." Mercy at: "..self.mercy)

end

function Mizzle:update(dt, localcurrentstate, enemies)

    if localcurrentstate == "BULLETS" then
        if self.mercyup then
            self.mercyup = nil
        end
        
        if self.currentanimation == 4 or self.currentanimation == 5 then
            
            if self.hp > 0 then
                self:set_animation(2)
            end

        end
    end

    if  self.x < 1750 and (self.hp <= 0  or self.mercied) then
        self.x = self.x + 1000*dt
    end

    if self.hp > 0 then
        AnimateQuadrants(self, dt)
    end

    if (self.hp <= 0 or self.mercied) and self.x >= 1750 then
        self:remove(enemies)
    end
end