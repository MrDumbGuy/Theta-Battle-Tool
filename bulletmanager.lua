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
    self.spritesheet = spritesheet --Preloaded spritesheet via love.graphics.newImage(filename)
    self.spritequadrants = spritequadrants --An array of loaded texturepacker hash data (as standard for this project, thru rxi's JSON library)
    self.bulletpatterns = bulletpatterns --An array of patterns of bullet movement, indexed via numbers 1 through #bulletpatterns. All must return the BulletManager.bullets table.
    self.currentbulletpattern = 1
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
        love.graphics.draw(self.spritesheet, self.bullets.quadrantID[i], self.bullets.x[i], self.bullets.y[i])
    end
end

function BulletManager:update(dt, current_state)
    if current_state ~= "BULLETS" then return end

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

    end

end

return BulletManager