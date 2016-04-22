local Hud           = FS.Hud
local Encounters    = FS.Encounters

local mod = Encounters:RegisterEncounter("Archimonde", 1799)

function mod:OnEngage ( id , name , difficulty , size )
  local spells = {
    FocusedChaos    = 185014,
    ShackledTorment = 184964,
    MarkLegion      = 187050,
    Doomfire        = 183586,
    Shadowfel       = 183634,
  }
  for k, v in pairs(spells) do
    mod:CombatLog("SPELL_AURA_APPLIED", k, v)
    mod:CombatLog("SPELL_AURA_REMOVED", "Removed", v)
  end

end

function mod:FocusedChaos ( _, _, args )
  local own = false
  if args.sourceName and args.destName then
    own = UnitIsUnit("player", args.destName) or UnitIsUnit("player", args.sourceName)
  end
  local key = args.destGUID .. args.spellId
  Hud:RemovePoint(key)

  local pt = Hud:CreateShadowPoint(destGUID, key)

  function pt:Position()
      local vx, vy = Hud:Vector(args.sourceGUID, args.destGUID, db.overrun)
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

function mod:ShackledTorment ( _, _, args )

end

function mod:MarkLegion ( _, _, args )

end

function mod:Doomfire ( _, _, args )

end

function mod:Shadowfel ( _, _, args )

end

function mod:Removed ( _, _, args )
  local key = args.destGUID .. args.spellId
  Hud:RemovePoint(key)
end
