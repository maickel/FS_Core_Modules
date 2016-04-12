local Hud = FS.Hud
-------------------------------------------------------------------------------
-- Database
-------------------------------------------------------------------------------

local default = {
  shackled_enabled = true,
  shackled_width = 128,
  chaos_enabled = true,
  overrun = 100, 
  ray_width = 128,
  mark_enabled = true,
  shadowfel_enabled = true,
  doomfire_enabled = true,
  selfColor = {0, 0.78, 1.0, 0.5},
  inColor = {0.9, 0, 0.1, 0.5},
  outColor = {0, 0.8, 0.1, 0.5},
  defaultColor = {1, 1, 1, 0.5}
}

for k,v in pairs(default) do
  if db[k] == nil then 
    db[k] = v
  end
end

config = {
  shackled={
    type = "group",
    name = "Shackled Torment",
    args = {
      enable = {
        order = 1,
        type = "toggle",
        name = "Enable",
        width = "full",
        get = function() return db.shackled_enabled end,
        set = function(_, v) db.shackled_enabled = v end
      },
      width = {
        order = 2,
        type = "range",
        name = "Width",
        desc = "Change shackled line width.",
        min = 64,
        max = 512,
        step = 64,
        get = function() return db.shackled_width end,
        set = function(_, v) db.shackled_width = v end
      }
    }
  },
  mark={
    type = "group",
    name = "Mark of the Legion",
    args = {
      enable = {
        order = 1,
        type = "toggle",
        name = "Enable",
        width = "full",
        get = function() return db.mark_enabled end,
        set = function(_, v) db.mark_enabled = v end
      }
    }
  },
  doomfire={
    type = "group",
    name = "Doomfire",
    args = {
      enable = {
        order = 1,
        type = "toggle",
        name = "Enable",
        width = "full",
        get = function() return db.doomfire_enabled end,
        set = function(_, v) db.doomfire_enabled = v end
      }
    }
  },
  shadowfel={
    type = "group",
    name = "Shadowfel Burst",
    args = {
      enable = {
        order = 1,
        type = "toggle",
        name = "Enable",
        width = "full",
        get = function() return db.shadowfel_enabled end,
        set = function(_, v) db.shadowfel_enabled = v end
      }
    }
  },
  chaos={
    type = "group",
    name = "Focused Chaos",
    args = {
      enable = {
        order = 1,
        type = "toggle",
        name = "Enable",
        width = "full",
        get = function() return db.chaos_enabled end,
        set = function(_, v) db.chaos_enabled = v end
      },
      overrun = {
        order = 2,
        type = "range",
        name = "Overrun",
        desc = "Change ray length.",
        min = 10,
        max = 150,
        step = 10,
        get = function() return db.overrun end,
        set = function(_, v) db.overrun = v end
      },
      width = {
        order = 3,
        type = "range",
        name = "Width",
        desc = "Change ray width.",
        min = 64,
        max = 512,
        step = 64,
        get = function() return db.ray_width end,
        set = function(_, v) db.ray_width = v end
      },
    }
  },
  colors = {
    type = "group",
    name = "Colors",
    args = {
      selfColor = {
        order = 1,
        type = 'color',
        name = "Self Color",
        hasAlpha = true,
        get = function() return unpack(db.selfColor) end,
        set = function(_, ...)
          db.selfColor = ...
        end
      },
      inColor = {
        order = 2,
        type = 'color',
        name = "Inside Color",
        hasAlpha = true,
        get = function() return unpack(db.inColor) end,
        set = function(_, ...)
          db.inColor = ...
        end
      },
      outColor = {
        order = 3,
        type = 'color',
        name = "Outside Color",
        hasAlpha = true,
        get = function() return unpack(db.outColor) end,
        set = function(_, ...)
          db.outColor = ...
        end
      },
      defaultColor = {
        order = 4,
        type = 'color',
        name = "Default Color",
        hasAlpha = true,
        get = function() return unpack(db.defaultColor) end,
        set = function(_, ...)
          db.outColor = ...
        end
      }
    }
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

-- 1 - Star
-- 2 - Circle
-- 3 - Diamond
-- 4 - Triangle
-- 5 - Moon
-- 6 - Square
-- 7 - Cross
-- 8 - Skull

local MARK_TIMERS = {
  [5]=1,
  [7]=2, 
  [9]=3, 
  [11]=4
}
local RAID_TARGET_COLORS = {
  {1.0, 1.0, 0.0, 0.5}, 
  {1.0, 0.5, 0.0, 0.5}, 
  {0.7, 0.0, 1.0, 0.5}, 
  {0.0, 0.7, 0.0, 0.5}, 
  {0.5, 0.6, 0.7, 0.5},
  {0.0, 0.6, 1.0, 0.5},
  {1.0, 0.2, 0.1, 0.5},
  {0.9, 0.9, 0.9, 0.5}
}

local ENCOUNTER_ID = nil
local DOOMFIRE = {}

function f:ENCOUNTER_START (encounterID, encounterName, difficultyID, raidSize)
  ENCOUNTER_ID = encounterID
  self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
end

function f:ENCOUNTER_END (encounterID, encounterName, difficultyID, raidSize, endStatus)
  ENCOUNTER_ID = nil
  self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED") 
end

function f:COMBAT_LOG_EVENT_UNFILTERED (_, event, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, _, spell, spellName, ...)
  if ENCOUNTER_ID == 1799 then
    local key = nil
    local own = false
    if sourceName and destName then
      own = UnitIsUnit("player", destName) or UnitIsUnit("player", sourceName)
    end

    if spell == 185014 and db.chaos_enabled then 
      key = sourceGUID .. "_chaos_ray"
      if event == "SPELL_AURA_APPLIED" then
        Hud:RemovePoint(key)
        local pt = Hud:CreateShadowPoint(destGUID, key)

        function pt:Position()
            local vx, vy = Hud:Vector(sourceGUID, destGUID, db.overrun)
            local x, y = self.ref:Position()
            return x + vx, y + vy
        end
        local line = Hud:DrawLine(sourceGUID, pt, db.ray_width)
        
        function line:OnUpdate()
            if own then
                self:SetColor(unpack(db.selfColor))
            elseif self:UnitDistance("player") < 2 then
                self:SetColor(unpack(db.inColor))
            else
                self:SetColor(unpack(db.outColor))
            end
        end
      end
    elseif spell == 184964 and db.shackled_enabled then
      key = destGUID .. "_shackled"
      if event == "SPELL_AURA_APPLIED" then
        Hud:RemovePoint(key)
        local x, y = UnitPosition(destName)
        local root = Hud:CreateStaticPoint(x, y, key)
        local aera = Hud:DrawArea(root, 25)
        function aera:OnUpdate()
            if own then
                self:SetColor(unpack(db.selfColor))
            elseif self:UnitIsInside("player") then
                self:SetColor(unpack(db.inColor))
            else
                self:SetColor(unpack(db.outColor))
            end
        end
        local line = Hud:DrawLine(root, destGUID, db.shackled_width)
        line:SetColor (unpack(db.defaultColor))
        root:SetColor (unpack(db.defaultColor))
      end
    elseif spell == 187050 and db.mark_enabled then
      key = destGUID .. "_mark"
      if event == "SPELL_AURA_APPLIED" then
        Hud:RemovePoint(key)
        local duration = select(6, UnitDebuff(destName, spellName))
        local idx = MARK_TIMERS[duration]

        local pt = Hud:CreateShadowPoint(destGUID, key)
        local timer = Hud:DrawTimer(pt, 10, duration)
        if idx then
          timer:SetColor(unpack(RAID_TARGET_COLORS[idx]))
        else
          timer:SetColor(unpack(db.defaultColor))
        end
      end
    elseif spell == 183586 and db.doomfire_enabled then
      key = destGUID .. "_doomfire"
      if event == "SPELL_AURA_APPLIED" then
        Hud:RemovePoint(key)
        local pt = Hud:CreateShadowPoint(destGUID, key)
        local timer = Hud:DrawTimer(pt, 10, 12)
        timer:SetColor(unpack(db.defaultColor))
        DOOMFIRE[key] = timer
      elseif event == "SPELL_AURA_APPLIED_DOSE" then
        DOOMFIRE[key]:Reset(12)
      end
    elseif spell == 183634 and db.shadowfel_enabled then
      key = destGUID .. "_shadowfel"
      if event == "SPELL_AURA_APPLIED" then
        Hud:RemovePoint(key)
        local pt = Hud:CreateShadowPoint(destGUID, key)
        local aera = Hud:DrawArea(pt, 8)
        aera:SetColor(unpack(db.defaultColor))
      end
    end
    if event == "SPELL_AURA_REMOVED" and key then
        Hud:RemovePoint(key)
    end
  end
end

function reload()
  load("main.lua", true)
end
