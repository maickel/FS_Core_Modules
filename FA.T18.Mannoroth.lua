local Hud           = FS.Hud
local Encounters    = FS.Encounters
local LSM           = LibStub:GetLibrary("LibSharedMedia-3.0")

-------------------------------------------------------------------------------
-- SETTINGS
-------------------------------------------------------------------------------

local SETTINGS = {
  selfColor       = {0, 0.78, 1.0, 0.5},
  inColor         = {0.9, 0, 0.1, 0.5},
  outColor        = {0, 0.8, 0.1, 0.5},
  defaultColor    = {1, 1, 1, 0.5},
  font            = LSM:Fetch("font", "PT Sans Narrow"),
  font_outline    = "OUTLINE",
  font_size       = 14
}

-------------------------------------------------------------------------------
-- GLOBALS
-------------------------------------------------------------------------------
local MARKER_DOOM   = {
  melee   = 8,
  healer  = 3,
  ranged  = 1 
}

local WRATH      = {}

local TEXT_ARGS     = {
  font    = SETTINGS.font, 
  size    = SETTINGS.font_size, 
  outline = SETTINGS.font_outline,
  offset  = {0,15}
}
-------------------------------------------------------------------------------
-- MODULE
-------------------------------------------------------------------------------

local mod = Encounters:RegisterEncounter("Mannoroth", 1795)

local OPTIONS = mod:Options(_P) {
  MarkOfDoom        = mod:opt { 181099 },
  Gaze              = mod:opt { 181597 },
  EmpoweredGaze     = mod:opt { 182006 },
  DoomSpike         = mod:opt { 189717 },
  Wrath             = mod:opt { 186362 }
}

function mod:OnEngage ( id , name , difficulty , size )
  for k, v in pairs(OPTIONS) do
    if OPTIONS[k] then
      mod:CombatLog("SPELL_AURA_APPLIED", k, v)
      mod:CombatLog("SPELL_AURA_REMOVED", "Removed", v)
    end
  end
  -- DRY ...
  if OPTIONS["Wrath"] then
    mod:CombatLog("SPELL_AURA_REMOVED_DOSE", "WrathDose", 183586)
  end
end

function mod:Wrath ( _, _, args )
  local key = args.destGUID .. args.spellId
  Hud:RemovePoint(key)
  local root = Hud:CreateSnapshotPoint (args.destGUID, key)
  local aera = Hud:DrawArea(root, 10)
  aera:SetColor(0.7, 0.0, 1.0, 0.5) -- Purple
  local color = FS:GetClassColor(args.destName)
  WRATH[key] = Hud:DrawText(root, "|c" .. color .. args.destName .. " [" .. 40 .. "]", TEXT_ARGS)
end

function mod:WrathDose ( _, _, args )
  local key = args.destGUID .. args.spellId
  local color = FS:GetClassColor(args.destName)
  local text = "|c" .. color .. args.destName .. " [" .. args.amount .. "]"
  WRATH[key]:SetText (text)
end

function mod:DoomSpike ( _, _, args )
  local key = args.destGUID .. args.spellId
  Hud:RemovePoint(key)
  local root = Hud:CreateSnapshotPoint (args.destGUID, key)
  local aera = Hud:DrawArea(root, 30)
  function aera:OnUpdate()
      if self:UnitIsInside("player") then
          self:SetColor(unpack(SETTINGS.inColor))
      else
          self:SetColor(unpack(SETTINGS.outColor))
      end
  end
end

local function Gaze (args)
  local key = args.destGUID .. args.spellId
  Hud:RemovePoint(key)
  local pt = Hud:CreateShadowPoint(args.destGUID, key)
  local timer = Hud:DrawTimer(pt, 8, 4)
  local color = FS:GetClassColor(args.destName)
  local text = Hud:DrawText(pt, "|c" .. color .. args.destName , TEXT_ARGS)
end

function mod:Gaze ( _, _, args )
  Gaze (args)
end

function mod:EmpoweredGaze ( _, _, args )
  Gaze (args)
end

function mod:MarkOfDoom ( _, _, args )
  local key = args.destGUID .. args.spellId
  Hud:RemovePoint(key)
  local pt = Hud:CreateShadowPoint(args.destGUID, key)
  local timer = Hud:DrawTimer(pt, 20, 15)
  local role = self:Role(args.destName)
  local idx = MARKER_DOOM[role]
  timer:SetMarkerColor(idx, 0.5)
  local color = FS:GetClassColor(args.destName)
  local text = Hud:DrawText(pt, "|c" .. color .. args.destName , TEXT_ARGS)
end

function mod:Removed ( _, _, args )
  local key = args.destGUID .. args.spellId
  Hud:RemovePoint(key)
end
