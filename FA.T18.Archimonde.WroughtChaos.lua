local Hud = FS.Hud
-------------------------------------------------------------------------------
-- Database
-------------------------------------------------------------------------------

local default = {
  overrun = 100, 
  width = 128,
  selfColor = {0, 0.78, 1.0, 0.5},
  inColor = {0.9, 0, 0.1, 0.5},
  outColor = {0, 0.8, 0.1, 0.5}
}

for k,v in pairs(default) do
  if db[k] == nil then 
    db[k] = v
  end
end

config = {
  overrun = {
    order = 1,
    type = "range",
    name = "Overrun",
    min = 10,
    max = 150,
    step = 10,
    get = function() return db.overrun end,
    set = function(_, v) db.overrun = v end
  },
  width = {
    order = 2,
    type = "range",
    name = "Width",
    min = 64,
    max = 512,
    step = 64,
    get = function() return db.width end,
    set = function(_, v) db.width = v end
  },
  selfColor = {
    order = 3,
    type = 'color',
    name = "Self Color",
    hasAlpha = true,
    get = function() return unpack(db.selfColor) end,
    set = function(_, ...)
      db.selfColor = ...
    end
  },
  inColor = {
    order = 4,
    type = 'color',
    name = "Inside Color",
    hasAlpha = true,
    get = function() return unpack(db.inColor) end,
    set = function(_, ...)
      db.inColor = ...
    end
  },
  outColor = {
    order = 5,
    type = 'color',
    name = "Outside Color",
    hasAlpha = true,
    get = function() return unpack(db.outColor) end,
    set = function(_, ...)
      db.outColor = ...
    end
  }
}

-------------------------------------------------------------------------------
-- Events
-------------------------------------------------------------------------------

if f == nil then
  f = CreateFrame("Frame", nil);
  f:RegisterEvent("ENCOUNTER_START");
  f:RegisterEvent("ENCOUNTER_END");
  f:SetScript("OnEvent", function(self, event, ...)
    self[event](self, ...)
  end)
end

local ENCOUNTER_ID = nil

function f:ENCOUNTER_START (encounterID, encounterName, difficultyID, raidSize)
  ENCOUNTER_ID = encounterID
  f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
end

function f:ENCOUNTER_END (encounterID, encounterName, difficultyID, raidSize, endStatus)
  ENCOUNTER_ID = nil
  f:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED") 
end

function f:COMBAT_LOG_EVENT_UNFILTERED (_, event, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, _, spell, spellName, ...)
  if spell == 185014 and ENCOUNTER_ID == 1799 then 
    local key = sourceGUID .. "_chaos_ray"
    local own = UnitIsUnit("player", destName) or UnitIsUnit("player", sourceName)
    if event == "SPELL_AURA_APPLIED" then
      Hud:RemovePoint(key)
      local pt = Hud:CreateShadowPoint(destName, key)

      function pt:Position()
          local vx, vy = Hud:Vector(sourceGUID, destGUID, db.overrun)
          local x, y = self.ref:Position()
          return x + vx, y + vy
      end
      local line = Hud:DrawLine(sourceGUID, pt, db.width)
      
      function line:OnUpdate()
          if own then
              self:SetColor(unpack(db.selfColor))
          elseif self:UnitDistance("player") < 2 then
              self:SetColor(unpack(db.inColor))
          else
              self:SetColor(unpack(db.outColor))
          end
      end
    elseif event == "SPELL_AURA_REMOVED" then
      Hud:RemovePoint(key)
    end
  end
end

function reload()
  load("main.lua", true)
end