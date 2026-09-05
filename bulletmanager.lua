local BulletManager = {}

--Due to having to potentially manage 100s of bullets, parallel arrays will be utilised
--This reduces the load on memory and helps the program run better on lower-end devices
--(Alongside being good practise for redundant objects like these)
--My goal as of now is to get the simple "white" bullets working.

BulletManager.bullets = {--Storage for all the parallel arrays. Bullets exist as the culmination of an index across all these arrays.
    x = {},
    y = {},
    velocity_x = {},
    velocity_y = {},
    width = {},
    height = {},
    accel_x = {},
    accel_y = {},
    quadrantID = {},
    isactive = {},
    custombulletpositions = false --If your pattern updates bullet positions itself, set this to true in via your pattern.
}

--Initialise the BulletManager with a spritesheet, an array of texturepacker hash data, and an array of bullet patterns
function BulletManager:load(spritesheet, spritequadrants, bulletpatterns)
    self.spritesheet = love.graphics.newImage(spritesheet)

    self.spritequadrants = {}

    local quadrantarray
    local quadrantjson = io.open(spritequadrants, "r")
    if quadrantjson then
        local tempquadrantarr = quadrantjson:read("*a")
        quadrantarray = json.decode(tempquadrantarr)
    end

    local sheetwidth, sheetheight = quadrantarray.meta.size.w, quadrantarray.meta.size.h

    for key, table in pairs(quadrantarray.frames) do
        local localquad = table.frame
        self.spritequadrants[key] = love.graphics.newQuad(localquad.x, localquad.y, localquad.w, localquad.h, sheetwidth, sheetheight)
    end

    self.bulletpatterns = bulletpatterns

    self.currentbulletpattern = 1 --Failsafe
end

--Set the index for the bullet pattern to be used in the next update cycle. Ideally call right before or right after the "BULLETS" state.
function BulletManager:setPattern(n)
    self.currentbulletpattern = n
end

--Update bullet related information via the bullet pattern function at the current index.
function BulletManager:applyPattern(dt)
    self.bulletpatterns[self.currentbulletpattern](self, dt)
end

function BulletManager:draw(current_state)
    if current_state ~= "BULLETS" then return end
    for i = #self.bullets.isactive, 1, -1 do
        love.graphics.draw(self.spritesheet, self.spritequadrants[self.bullets.quadrantID[i]], self.bullets.x[i], self.bullets.y[i])
    end
end

function BulletManager:update(dt, current_state)
    if current_state ~= "BULLETS" then

        --Check for leftover data.
        if #self.bullets.isactive ~= 0 then
            self.bullets = {
                    x = {},
                    y = {},
                    velocity_x = {},
                    velocity_y = {},
                    width = {},
                    height = {},
                    accel_x = {},
                    accel_y = {},
                    quadrantID = {},
                    isactive = {},
                    custombulletpositions = false
                }
        end

        return

    end

        self:applyPattern(dt)

        if not self.bullets.custombulletpositions then
        for i = #self.bullets.isactive, 1, -1 do

            if self.bullets.isactive[i] then

                self.bullets.velocity_x[i] = self.bullets.velocity_x[i] + (self.bullets.accel_x[i] * dt)
                self.bullets.velocity_y[i] = self.bullets.velocity_y[i] + (self.bullets.accel_y[i] * dt)

                self.bullets.x[i] = self.bullets.x[i] + (self.bullets.velocity_x[i] * dt)
                self.bullets.y[i] = self.bullets.y[i] + (self.bullets.velocity_y[i] * dt)

            end

        end

        --TODO: Add collision and damage logic.

    end

end

return BulletManager