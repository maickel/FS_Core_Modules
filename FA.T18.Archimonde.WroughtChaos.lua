local FS = LibStub("AceAddon-3.0"):GetAddon("FS")
if not FS then return end

local Hud = FS:GetModule("Hud")
Hud:Enable()

-------------------------------------------------------------------------------
-- Utils
-------------------------------------------------------------------------------

function pack(...)
  return { ... }, select("#", ...)
end

-------------------------------------------------------------------------------
-- Database
-------------------------------------------------------------------------------

default = {
  overrun = 100, 
  width = 256,
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

local f = CreateFrame("Frame", nil);
f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
f:RegisterEvent("ENCOUNTER_START");
f:RegisterEvent("ENCOUNTER_END");
f:SetScript("OnEvent", function(self, event, ...)
  self[event](self, ...)
end)

local ENCOUNTER_ID = nil
local RAYS = {}

function f:ENCOUNTER_START (encounterID, encounterName, difficultyID, raidSize)
  ENCOUNTER_ID = encounterID
end

function f:ENCOUNTER_END (encounterID, encounterName, difficultyID, raidSize, endStatus)
  ENCOUNTER_ID = nil
end

function f:COMBAT_LOG_EVENT_UNFILTERED (_, event, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, _, _, spellName, ...)
  if spellName == "Focused Chaos" and ENCOUNTER_ID == 1799 then 
    RAYS = RAYS or {}
    if event == "SPELL_CAST_START" then
      Hud:RefreshRaidPoints()
      Hud:Show(true)

    elseif event == "SPELL_AURA_APPLIED" then
      local playerName, _ = UnitName("player")
      local pt = Hud:CreateShadowPoint(destName)

      -- Query Database
      local width = config.width.get()
      local overrun = config.overrun.get()
      local selfColor = pack(config.selfColor.get())
      local inColor = pack(config.inColor.get())
      local outColor = pack(config.outColor.get())
 
      function pt:Position()
          local vx, vy = Hud:Vector(sourceName, destName, overrun)
          local x, y = self.ref:Position()
          return x + vx, y + vy
      end
      local line = Hud:DrawLine(sourceName, pt, width)
      
      function line:OnUpdate()
          if sourceName == playerName or destName == playerName then
              self:SetColor(unpack(selfColor))
          elseif self:UnitDistance("player", true) < 2.0 then
              self:SetColor(unpack(inColor))
          else
              self:SetColor(unpack(outColor))
          end
      end
      RAYS[destGUID] = {["line"]=line}
    elseif event == "SPELL_AURA_REMOVED" then
      local ray = RAYS[destGUID]
      if ray then
        for _,v in pairs(ray) do
          v:Remove ()
        end
        RAYS[destGUID] = nil
        if not next(RAYS) then
          Hud:Hide()
        end
      end
    end
  end
end

function reload()
  load("main.lua", true)
end
