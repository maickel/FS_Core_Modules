local Hud           = FS.Hud
local Encounters    = FS.Encounters
local LSM           = LibStub:GetLibrary("LibSharedMedia-3.0")

print("|cff64b4ffArchimonde Module : |cff999999Loaded")
-------------------------------------------------------------------------------
-- SETTINGS
-------------------------------------------------------------------------------

local SETTINGS = {
  shackled_width  = 128,
  overrun         = 100, 
  ray_width       = 128,
  selfColor       = {0, 0.78, 1.0, 0.5},
  inColor         = {0.9, 0, 0.1, 0.5},
  outColor        = {0, 0.8, 0.1, 0.5},
  defaultColor    = {1, 1, 1, 0.5},
  font            = LSM:Fetch("font", "PT Sans Narrow"),
  font_outline    = "OUTLINE",
  font_size       = 14
}

-------------------------------------------------------------------------------
-- UTILS
-------------------------------------------------------------------------------

local function IsPlayer (args)
  local own = false
  if args.sourceName and args.destName then
    own = UnitIsUnit("player", args.destName) or UnitIsUnit("player", args.sourceName)
  end
  return own
end

-------------------------------------------------------------------------------
-- GLOBALS
-------------------------------------------------------------------------------

local MARK_TIMERS = {
  [5]   = 1,
  [7]   = 2, 
  [9]   = 3, 
  [11]  = 4
}

local DOOMFIRES      = {}

local TEXT_ARGS     = {
  font    = SETTINGS.font, 
  size    = SETTINGS.font_size, 
  outline = SETTINGS.font_outline,
  offset  = {0,15}
}
-------------------------------------------------------------------------------
-- MODULE
-------------------------------------------------------------------------------

local mod = Encounters:RegisterEncounter("Archimonde", 1799)

local SPELLS = {
  FocusedChaos    = 185014 ,
  ShackledTorment = 184964 ,
  MarkLegion      = 187050 ,
  Doomfire        = 183586 ,
  Shadowfel       = 183634 
}
local OPTIONS = mod:Options(_P) {

  FocusedChaos    = mod:opt { 185014 },
  ShackledTorment = mod:opt { 184964 },
  MarkLegion      = mod:opt { 187050 },
  Doomfire        = mod:opt { 183586 },
  Shadowfel       = mod:opt { 183634 }
}

function mod:OnEngage ( id , name , difficulty , size )
  for k, v in pairs(OPTIONS) do
    if OPTIONS[k] then
      mod:CombatLog("SPELL_AURA_APPLIED", k, SPELLS[k])
      mod:CombatLog("SPELL_AURA_REMOVED", "Removed", SPELLS[k])
    end
  end
  -- DRY ...
  if OPTIONS["Doomfire"] then
    mod:CombatLog("SPELL_AURA_APPLIED_DOSE", "DoomfireDose", 183586)
  end
end

function mod:FocusedChaos ( _, _, args )
  local own = IsPlayer (args)
  Hud:RemovePoint(args.destKey)
  local pt = Hud:CreateShadowPoint(args.destGUID, args.destKey)
  local sourceGUID  = args.sourceGUID
  local destGUID    = args.destGUID
  function pt:Position()
    local vx, vy = Hud:Vector(sourceGUID, destGUID, SETTINGS.overrun)
    local x, y = self.ref:Position()
    return x + vx, y + vy
  end
  local line = Hud:DrawLine(args.sourceGUID, pt, SETTINGS.ray_width)
  
  function line:OnUpdate()
    if own then
      self:SetColor(unpack(SETTINGS.selfColor))
    elseif self:UnitDistance("player") < 2 then
      self:SetColor(unpack(SETTINGS.inColor))
    else
      self:SetColor(unpack(SETTINGS.outColor))
    end
  end
end

function mod:ShackledTorment ( _, _, args )
  local own = IsPlayer (args)
  Hud:RemovePoint(args.destKey)
  local root = Hud:CreateSnapshotPoint (args.destGUID, args.destKey)
  local aera = Hud:DrawArea(root, 25)
  function aera:OnUpdate()
    if own then
      self:SetColor(unpack(SETTINGS.selfColor))
    elseif self:UnitIsInside("player") then
      self:SetColor(unpack(SETTINGS.inColor))
    else
      self:SetColor(unpack(SETTINGS.outColor))
    end
  end
  local line = Hud:DrawLine(root, args.destGUID, SETTINGS.shackled_width)
  line:SetColor (unpack(SETTINGS.defaultColor))
  root:SetColor (unpack(SETTINGS.defaultColor))
end

function mod:MarkLegion ( _, _, args )
  Hud:RemovePoint(args.destKey)
  local duration = select(6, UnitDebuff(args.destName, args.spellName))
  local idx = MARK_TIMERS[duration]
  
  local pt = Hud:CreateShadowPoint(args.destGUID, args.destKey)
  local timer = Hud:DrawTimer(pt, 10, duration)
  
  if idx then
    timer:SetMarkerColor(idx, 0.5)
  else
    timer:SetColor(unpack(SETTINGS.defaultColor))
  end
  
  local color = FS:GetClassColor(args.destName)
  local text = Hud:DrawText(pt, "|c" .. color .. args.destName, TEXT_ARGS) 
end

function mod:Doomfire ( _, _, args )
  Hud:RemovePoint(args.destKey)
  local pt = Hud:CreateShadowPoint(args.destGUID, args.destKey)
  local color = FS:GetClassColor(args.destName)
  local text = Hud:DrawText(pt, "|c" .. color .. args.destName, TEXT_ARGS)
  local timer = Hud:DrawTimer(pt, 10, 12)
  timer:SetColor(unpack(SETTINGS.defaultColor))
  DOOMFIRES[args.destKey] = timer
end

function mod:DoomfireDose ( _, _, args )
  if DOOMFIRES[args.destKey] then 
    DOOMFIRES[args.destKey]:Reset(12)
  end
end

function mod:Shadowfel ( _, _, args )
  Hud:RemovePoint(args.destKey)
  local pt = Hud:CreateShadowPoint(args.destGUID, args.destKey)
  local aera = Hud:DrawArea(pt, 8)
  aera:SetColor(unpack(SETTINGS.defaultColor))
  local color = FS:GetClassColor(args.destName)
  local text = Hud:DrawText(pt, "|c" .. color .. args.destName, TEXT_ARGS)
end

function mod:Removed ( _, _, args )
  Hud:RemovePoint(args.destKey)
end