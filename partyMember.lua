--The project now supports multiple party members!

PartyMember = Object:extend()

function PartyMember:new(name, xpos, ypos, animations, defaultquadrant, defaultanim, animationSpecialLoops, spritesheetarray, spritesheetpng, size, maxhp, ATK, DEF)

    self.name = name
    self.xpos = xpos
    self.ypos = ypos
    self.animations = animations
    self.defaultanim = defaultanim
    self.size = size
    self.maxhp = maxhp
    self.hp = maxhp
    self.ATK = ATK
    self.DEF = DEF
    self.animationSpecialLoops = animationSpecialLoops

    self.currentanimation = defaultanim
    self.currentframe = nil
    self.currentframecount = 1

    self.spritesheetpng = spritesheetpng
    self.quadrants = {}

    local sheetwidth, sheetheight = spritesheetarray.meta.size.w, spritesheetarray.meta.size.h

    for i = 0,#self.animations do --Load every frame of every animation, index them by numbers

        self.quadrants[i] = {}

        for j = 1, animations[i][2] do
            local filename = animations[i][1]..j..".png"
            local quaddata = spritesheetarray.frames[filename]
            self.quadrants[i][j] = love.graphics.newQuad(quaddata.frame.x, quaddata.frame.y, quaddata.frame.w, quaddata.frame.h, sheetwidth, sheetheight)
        end

    end

    local defaultfilename = defaultquadrant
    local defaultquaddata = spritesheetarray.frames[defaultfilename]

    self.defaultquadrant = love.graphics.newQuad(defaultquaddata.frame.x, defaultquaddata.frame.y, defaultquaddata.frame.w, defaultquaddata.frame.h, sheetwidth, sheetheight)

    self.isdefending = false

    self.animationsfromstate = { --When a string is passed into set_animation(), these are checked to convert into a numerical value
        ["ATTACKUI"] = 6,
        ["ACTUI"] = 7,
        ["ITEMUI"] = 0,
        ["SPAREUI"] = 8,
        ["DEFEND"] = 5,
        ["ATTACK"] = 1,

    }

    for k, v in pairs(self.animationSpecialLoops) do
        print (self.name.." special loop "..k.." : "..v)
    end

    self.hpup = nil --The variable that is used to display the HP Increase of a party member (i.e. the green number next to their head)

end

function PartyMember:draw()

    if self.quadrants[self.currentanimation] and self.currentquadrant then

        love.graphics.draw(self.spritesheetpng, self.currentquadrant, self.xpos + self.animations[self.currentanimation][5], self.ypos + self.animations[self.currentanimation][6], 0, self.size, self.size)

    else

        --If a frame somehow doesn't exist, this is displayed.
         love.graphics.draw(self.spritesheetpng, self.defaultquadrant, self.xpos, self.ypos, 0, self.size, self.size)

    end

    if self.hpup then

        love.graphics.setColor(0,1,0,1)
        love.graphics.setFont(Battlefont)
        love.graphics.print(self.hpup, self.xpos + 90, self.ypos - 30) -- Draw offsetted hp increase amount above and to the right of member's head
        love.graphics.setColor(1,1,1,1)

    end

end

function PartyMember:set_animation(animation)
    if type(animation) == "number" then
        self.currentanimation = animation
    else
        self.currentanimation = self.animationsfromstate[animation]

        if self.currentanimation == nil then
            self.currentanimation = self.defaultanim
        end

    end
        self.currentframecount = 1
end

function PartyMember:attack(local_enemy, mult)

    love.audio.play(SND_ATTACK)
    print(self.name.." attacked "..local_enemy.name)

    local selectedEnemyIndex

    for i = 1, #enemies do
        if enemies[i] == local_enemy then
            selectedEnemyIndex = i
            break
        end
    end

    if selectedEnemyIndex == nil or local_enemy.hp <= 0 then
        local_enemy = nil
        for i = 1, #enemies do
            print(enemies[i].name.." hp is "..enemies[i].hp)
            if enemies[i].hp > 0 then
                local_enemy = enemies[i]
                selectedEnemyIndex = i
                break
            end
        end
    end

    if local_enemy then
        print(self.name.." attacked enemy "..selectedEnemyIndex)
        local_enemy:hurt(self.ATK*mult)
        self.currentanimation = 1
        self.currentframecount = 1
    else
        print("No enemies left :)")
        current_state = "BATTLEOVER"
    end
end

function PartyMember:update(dt)
    if current_state == "BATTLEUI" and self.isdefending then
        self.isdefending = false
        self:set_animation(0)
    end
    AnimateQuadrants(self, dt, self.animationSpecialLoops)
end

function PartyMember:act(local_enemy, actname, ui)
    print(self.name.." acted together with "..local_enemy.name)
    print("Current act: "..actname)
    self:set_animation(2)
    local_enemy.mercyup = local_enemy.mercytable[actname]
    local_enemy:act(actname, ui) --Lets local_enemy handle the act
end

function PartyMember:spare(local_enemy)
    local_enemy:spared()
end

function PartyMember:hpUp(hp)
    self.hpup = hp
    self.hp = self.hp + hp
    if self.hp > self.maxhp then
        self.hp = self.maxhp
        self.hpup = "MAX"
    end
end