local LogId = "mmtestLog"
local Log = Log


local onHitMonster = 1
local onHitPlayer = 2
-- weapon effect. Al of these needs unique numbers
local weBlock = 1   -- implemented   -- melee only
local weCrit = 2  -- implemented
local weInstantKill = 3   -- implemented 
local weTrueDamage = 4    -- implemented
local weGreaterCleave = 5 -- implemented   -- melee only
local weExtraDamageOnMonsterCondition = 6 -- implemented
local weExtraDamageWhenMonsterHPThreshold = 7 -- implemented
local weExtraDamageWhenPlayerHPThreshold = 8 -- implemented
local weApplyMonsterBuff = 9 -- implemented
local weAmbush = 10 -- implemented
local weApplyMonsterBuffOnAllInMeleeRange = 11    -- implemented  -- melee only
local weExtraDamageWhenPlayerCondition = 12 -- not implemented
-- weapon effect field. all of these needs unique numbers
local wefMultiplier = 1
local wefChance = 2
local wefDuration = 3
local wefAIState = 4
local wefLowerThreshold = 5
local wefHigherThreshold = 6
local wefPower = 7
local wefExtraReqs = 8
local wefMastery = 9 --minimum required mastery

-- all of these needs unique numbers
local reqsMasteriesOr = 1
-- local reqsOtherHand = 2
-- local reqsMainHand = 2
-- local reqsMissile = 4


local crit = {
    [wefChance] = 1,
    [wefMultiplier] = 2,
    [wefMastery] = const.GM
}

local greaterCleave = {
    [wefChance] = 1,
    [wefMastery] = const.GM,
    [wefMultiplier] = 1
}

local instantKill = {
    [wefChance] = 0.5,
    [wefMastery] = const.GM
}

local extraDmgPlayerLowHp = {
    -- player hp between (inclusive) 0-50%
    [wefLowerThreshold] = 0,
    [wefHigherThreshold] = 0.5,
    [wefMultiplier] = 1,
    [wefMastery] = const.GM,
    [wefChance] = 100
}

local trueDamage = {
    [wefMastery] = const.GM,
    [wefChance] = 100,
    [wefExtraReqs] = {
        reqsOtherHand = {
            [const.Skills.Shield] = true,
            [const.Skills.Unarmed] = true   
        }
    }
}

local extraDmgMonsterLowHp = {
    -- monster hp between (inclusive) 0-50%
    [wefLowerThreshold] = 0,
    [wefHigherThreshold] = 0.5,
    [wefMultiplier] = 1,
    [wefMastery] = const.GM,
    [wefChance] = 100
}

local extraDmgWhenMonsterIsStunnedOrParalyzed = {
    [wefAIState] = {
        [const.AIState.Paralyzed] = true,
        [const.AIState.Stunned] = true
    },
    [wefMastery] = const.GM,
    [wefMultiplier] = 2,                    
    [wefChance] = 100
}

local applyStunToAllMonstersInMelee = {
    [wefChance] = 1,
    [wefMastery] = const.GM,
    [wefDuration] = 2, -- * const.Minute  (Minute / 2 == second)s
    -- https://grayface.github.io/mm/ext/ref/#const.MonsterBuff
    [wefPower] = 5
}

local block = { -- works on both weapon and shield
    -- chance * skill + Game.GetStatisticEffect(pl:GetLuck())
    [wefChance] = 1,
    -- damageFactor of 0 completely negates all damage, 
    [wefMultiplier] = 0,
    [wefMastery] = const.GM
}

local defaultAmbushMultiplier = 1

local ambush = {
    [wefMultiplier] = defaultAmbushMultiplier
}

local allOnHitMonsterEffects = {
    [weAmbush] = ambush,
    [weCrit] = crit,
    [weGreaterCleave] = greaterCleave,
    [weInstantKill] = instantKill,
    [weExtraDamageWhenPlayerHPThreshold] = extraDmgPlayerLowHp,
    [weTrueDamage] = trueDamage,
    [weExtraDamageOnMonsterCondition] = extraDmgWhenMonsterIsStunnedOrParalyzed,
    [weApplyMonsterBuffOnAllInMeleeRange] = applyStunToAllMonstersInMelee,
    [weExtraDamageWhenMonsterHPThreshold] = extraDmgMonsterLowHp
}

local allOnHitPlayerEffects = {
    [weBlock] = block,
    [weGreaterCleave] = greaterCleave, -- cleave should not be on shield
    [weApplyMonsterBuffOnAllInMeleeRange] = applyStunToAllMonstersInMelee,
}

local weaponEffects = {
    [const.Skills.Staff] = {
        -- Accessed by using struct.ItemsTxtItem.EquipStat so needs to subtract 1 from const.ItemType value
        [const.ItemType.Weapon2H - 1] = {
            [onHitMonster] = {
                [weAmbush] = ambush,
                [weExtraDamageOnMonsterCondition] = {
                    [wefAIState] = {
                        [const.AIState.Paralyzed] = true,
                        [const.AIState.Stunned] = true,
                        [const.AIState.Flee] = true,
                        [wefMastery] = const.GM
                    },
                    [wefMultiplier] = 1,
                    [wefChance] = 100
                },
                [weExtraDamageWhenMonsterHPThreshold] = {
                    -- monster hp between (inclusive) 0-50%
                    [wefLowerThreshold] = 0,
                    [wefHigherThreshold] = 0.5,
                    [wefMultiplier] = 1,
                    [wefMastery] = const.GM,
                    [wefChance] = 100,
                    [wefExtraReqs] = {
                        [reqsMasteriesOr] = {
                            -- Makes this weapon effect only available to Monks 
                            [const.Skills.Unarmed] = const.GM,
                        }
                    }
                },
            },
            [onHitPlayer] = {
                
            }
        }
    },
    [const.Skills.Sword] = {
        [const.ItemType.Weapon - 1] = {
            [onHitMonster] =  {
                [weAmbush] = ambush,
            },
            [onHitPlayer] = {
                [weBlock] = block,
            }
        },
        [const.ItemType.Weapon2H - 1] = {
            [onHitMonster] = {
                [weAmbush] = ambush,
                [weInstantKill] = instantKill
            },
            [onHitPlayer] = {
                [weBlock] = block,
            }
        }
    },
    [const.Skills.Dagger] = {
        [const.ItemType.Weapon - 1] = {
            [onHitMonster] = {
                [weAmbush] = ambush,
                [weCrit] = crit,
            },
            [onHitPlayer] = {
                
            }
        }
    },
    [const.Skills.Axe] = {
        [const.ItemType.Weapon - 1] = {
            [onHitMonster] = {
                [weAmbush] = ambush,
                [weGreaterCleave] = greaterCleave,
            },
            [onHitPlayer] = {
                
            }
        },
        [const.ItemType.Weapon2H - 1] = {
            [onHitMonster] = {
                [weAmbush] = ambush,
                [weGreaterCleave] = greaterCleave             
            },
            [onHitPlayer] = {
                [weGreaterCleave] = greaterCleave           
            }
        }
    },
    [const.Skills.Spear] = {
        [const.ItemType.Weapon - 1] = {
            [onHitMonster] = {
                [weAmbush] = ambush,
                [weExtraDamageWhenPlayerHPThreshold] = extraDmgPlayerLowHp,
                [weTrueDamage] = trueDamage
            },
            [onHitPlayer] = {
                
            }
        }
    },
    [const.Skills.Bow] = { 
        [const.ItemType.Missile - 1] = {
            [onHitMonster] = {
                [weAmbush] = ambush
            },
            [onHitPlayer] = {
                -- not recommended
            }
        }
    },
    [const.Skills.Mace] = {
        [const.ItemType.Weapon - 1] = {
            [onHitMonster] = {
                [weAmbush] = ambush,
                [weExtraDamageOnMonsterCondition] = extraDmgWhenMonsterIsStunnedOrParalyzed
            },
            [onHitPlayer] = {
                
            }
        }
    },
    [const.Skills.Shield] = {
        [const.ItemType.Shield - 1] = {
            [onHitMonster] = {
                
            },
            [onHitPlayer] = {
                [weApplyMonsterBuffOnAllInMeleeRange] = applyStunToAllMonstersInMelee
            }
        }
    },
    [const.Skills.Unarmed] = {
        -- unarmed has no weapon type
        [onHitMonster] = {
            [weAmbush] = ambush,
            [weExtraDamageWhenMonsterHPThreshold] = extraDmgMonsterLowHp
        },
        [onHitPlayer] = {
        }
    },
    [const.Skills.Blaster] = { 
    -- Blasters are not implemented
        [const.ItemType.Weapon - 1] = {
            [onHitMonster] = {
                [weAmbush] = ambush,
                -- [weApplyMonsterBuff] = {
                --     [wefChance] = 100,
                --     [wefMastery] = const.Expert,
                --     [wefDuration] = 2, -- * const.Minute  (Minute / 2 == second)s
                --     -- https://grayface.github.io/mm/ext/ref/#const.MonsterBuff
                --     [wefPower] = 5
                -- },
            },
            [onHitPlayer] = {
                -- not recommended
            }
        },
    },
}

function events.ItemAdditionalDamage(t)
    -- local wskill, wmastery = SplitSkill(t.Player.Skills[const.Skills.Armsmaster])
    -- t.Player.Skills[const.Skills.Armsmaster] = JoinSkill(math.max(wskill, 10), math.max(wmastery, const.GM))
    local itemSkill = Game.ItemsTxt[t.Item.Number].Skill
    local isMelee = itemSkill ~= const.Skills.Bow 

    local damage = 0
    damage = damage + tryToPerformAmbush(t, onHitMonster, isMelee)

    tryToPerformGreaterCleave(t, onHitMonster, isMelee)
    tryToPerformApplyMonsterBuffOnAllInMeleeRange(t, onHitMonster, isMelee)
    tryToPerformApplyMonsterBuff(t.Player, t.Monster, onHitMonster, isMelee)

    damage = damage + tryToPerformCrit(t, onHitMonster, isMelee)

    damage = damage + tryToPerformExtraDamageOnMonsterCondition(t, onHitMonster, isMelee)
    damage = damage + tryToPerformExtraDamageWhenMonsterHPThreshold(t, onHitMonster, isMelee)
    damage = damage + tryToPerformExtraDamageWhenPlayerHPThreshold(t, onHitMonster, isMelee)

    t.Result = damage
end

function events.CalcDamageToMonster(t)
    -- if a player is not the source then no extra damage is done 
    if t.Player == nil then
        return
    end

    -- Ensure we don't do extra damage to monsters immune to physical damage, probably not wise even with blaster
    if t.Monster.PhysResistance == 200 then
        return
    end

    local itemMain =  t.Player.ItemMainHand ~= 0 and Game.ItemsTxt[t.Player.Items[t.Player.ItemMainHand].Number] or nil

    local playerUsesBlaster = itemMain ~= nil and itemMain.Skill == const.Skills.Blaster
    -- Weapon Effects should only trigger on Phys damage or blaster attacks
    if t.DamageKind ~= const.Damage.Phys and t.DamageKind ~= 12 then 
        return
    elseif t.DamageKind == 12 and playerUsesBlaster ~= true then 

        return
    end

    local damage = 0
    local isMelee = isMonsterInMeleeRange(Map.Monsters[t.MonsterIndex])

    -- This is needed to be able to proc skills with unarmed attacks or blasters
    if (isMelee and t.Player.ItemMainHand == 0) or playerUsesBlaster then
        local dmgReductionFactor = t.Result / t.Damage
        damage = damage + tryToPerformAmbush(t, onHitMonster, isMelee) * dmgReductionFactor
        tryToPerformGreaterCleave(t, onHitMonster, isMelee) 
        tryToPerformApplyMonsterBuffOnAllInMeleeRange(t, onHitMonster, isMelee)
        tryToPerformApplyMonsterBuff(t.Player, t.Monster, onHitMonster, isMelee)
        damage = damage + tryToPerformCrit(t, onHitMonster, isMelee) * dmgReductionFactor
        damage = damage + tryToPerformExtraDamageOnMonsterCondition(t, onHitMonster, isMelee) * dmgReductionFactor
        damage = damage + tryToPerformExtraDamageWhenMonsterHPThreshold(t, onHitMonster, isMelee) * dmgReductionFactor
        damage = damage + tryToPerformExtraDamageWhenPlayerHPThreshold(t, onHitMonster, isMelee) * dmgReductionFactor
    end

    damage = damage + tryToPerformInstantKill(t, onHitMonster, isMelee)

    -- if true damage then use t.Damage instead of t.Result
    if tryToPerformTrueDamage(t, onHitMonster, isMelee) then
        damage = damage + t.Damage
    else 
        damage = damage + t.Result
    end 

    t.Result = damage
end

function events.CalcDamageToPlayer(t) 
    local attacker = WhoHitPlayer()
    if attacker.MonsterIndex == nil then
        -- if a monster was not the souce then we do not want to proc effects
        return
    end

    -- monster can be used to perform revengeful single target attacks.
    local monster = Map.Monsters[attacker.MonsterIndex]
    -- Greater cleaver counter attack
    tryToPerformGreaterCleave(t, onHitPlayer, nil)
    tryToPerformApplyMonsterBuff(t.Player, monster, onHitPlayer, nil)
    tryToPerformApplyMonsterBuffOnAllInMeleeRange(t, onHitPlayer, nil)

    local damageFactor = tryToPerformBlock(t, onHitPlayer)
    -- damageFactor 1 is full damage, damageFactor 0 is no damage, 0.5 is half damage
    t.Result = t.Result * damageFactor
    
end

function tryToPerformTrueDamage(t, onHitEventType, isMelee)
    local availability = getWeaponsEffectAvailability(t.Player, onHitEventType, weTrueDamage, isMelee)
    local weapons = getPlayerWeapons(t.Player)
    for weaponSlot, available in pairs(availability) do
        if available then
            -- try to perform true damage
            local activeSkill = weapons[weaponSlot] ~= nil and weapons[weaponSlot].Skill or const.Skills.Unarmed
            local wEffect = getWeaponEffect(onHitEventType, weTrueDamage, weapons[weaponSlot], activeSkill)
            local chance = wEffect[wefChance]
            local skill, mastery = SplitSkill(t.Player.Skills[activeSkill])
            if calcIfWeaponEffectProcs(skill, chance, t.Player) then
                return true
            end
        end
    end
    return false
end

function tryToPerformInstantKill(t, onHitEventType, isMelee) 
    local damage = 0
    local availability = getWeaponsEffectAvailability(t.Player, onHitEventType,weInstantKill, isMelee)
    local weapons = getPlayerWeapons(t.Player)

    for weaponSlot, available in pairs(availability) do
        if available then
            -- try to perform the kill
            local activeSkill = weapons[weaponSlot] ~= nil and weapons[weaponSlot].Skill or const.Skills.Unarmed
            local wEffect = getWeaponEffect(onHitEventType, weInstantKill, weapons[weaponSlot], activeSkill)
            local chance = wEffect[wefChance]

            local skill, mastery = SplitSkill(t.Player.Skills[activeSkill])
            if calcIfWeaponEffectProcs(skill, chance, t.Player) then
                -- could return t.Monster.HP, but the potential for double proc dmg is cooler!
                damage = damage + t.Monster.HP
            end
        end
    end 
    return damage
end

function tryToPerformGreaterCleave(t, onHitEventType, isMelee) 
    local availability = getWeaponsEffectAvailability(t.Player, onHitEventType, weGreaterCleave, isMelee)
    local weapons = getPlayerWeapons(t.Player)
    for weaponSlot, available in pairs(availability) do

        if available then
            local activeSkill = weapons[weaponSlot] ~= nil and weapons[weaponSlot].Skill or const.Skills.Unarmed
            local wEffect = getWeaponEffect(onHitEventType, weGreaterCleave, weapons[weaponSlot], activeSkill)
            local chance = wEffect[wefChance]
            local multiplier = wEffect[wefMultiplier]
            local skill, mastery = SplitSkill(t.Player.Skills[activeSkill])
            if calcIfWeaponEffectProcs(skill, chance, t.Player) then
                greaterCleave(weapons[weaponSlot], t.MonsterIndex, multiplier, t.Player)
            end
        end
    end 
end

function tryToPerformApplyMonsterBuffOnAllInMeleeRange(t, onHitEventType, isMelee)
    local availability = getWeaponsEffectAvailability(t.Player, onHitEventType, weApplyMonsterBuffOnAllInMeleeRange, isMelee)
    local weapons = getPlayerWeapons(t.Player)
    for weaponSlot, available in pairs(availability) do
        if available then
            local activeSkill = weapons[weaponSlot] ~= nil and weapons[weaponSlot].Skill or const.Skills.Unarmed
            local wEffect = getWeaponEffect(onHitEventType, weApplyMonsterBuffOnAllInMeleeRange, weapons[weaponSlot], activeSkill)
            local chance = wEffect[wefChance]
            local skill, mastery = SplitSkill(t.Player.Skills[activeSkill])
            if calcIfWeaponEffectProcs(skill, chance, t.Player) then
                local duration = wEffect[wefDuration]
                local power = wEffect[wefPower]
                applyMonsterBuffOnAllInMeleeRange(duration, power)
            end
        end
    end 
end


function tryToPerformApplyMonsterBuff(player, monster, onHitEventType, isMelee)
    local availability = getWeaponsEffectAvailability(player, onHitEventType, weApplyMonsterBuff, isMelee)
    local weapons = getPlayerWeapons(player)
    for weaponSlot, available in pairs(availability) do
        if available then
            local activeSkill = weapons[weaponSlot] ~= nil and weapons[weaponSlot].Skill or const.Skills.Unarmed
            local wEffect = getWeaponEffect(onHitEventType, weApplyMonsterBuff, weapons[weaponSlot], activeSkill)
            local chance = wEffect[wefChance]
            local skill, mastery = SplitSkill(player.Skills[activeSkill])
            if calcIfWeaponEffectProcs(skill, chance, player) then
                local duration = wEffect[wefDuration]
                local power = wEffect[wefPower]
                applyMonsterBuff(monster, duration, power)
            end
        end
    end 
end

-- returns damage factor, if 1 then damage is unchanged, if 0 then all damage is blocked, if 0.5 50% of the dmg is blocked. result = damage * damageFactor
function tryToPerformBlock(t, onHitEventType) 
    local availability = getWeaponsEffectAvailability(t.Player, onHitEventType, weBlock )
    local weapons = getPlayerWeapons(t.Player)
    for weaponSlot, available in pairs(availability) do
        if available then
            local activeSkill = weapons[weaponSlot] ~= nil and weapons[weaponSlot].Skill or const.Skills.Unarmed
            local wEffect = getWeaponEffect(onHitEventType, weBlock, weapons[weaponSlot], activeSkill)
            local chance = wEffect[wefChance]
            local skill, mastery = SplitSkill(t.Player.Skills[activeSkill])
            if calcIfWeaponEffectProcs(skill, chance, t.Player) then
                return wEffect[wefMultiplier]
            end
        end
    end 
    return 1
end

function tryToPerformCrit(t, onHitEventType, isMelee) 
    local availability = getWeaponsEffectAvailability(t.Player, onHitEventType, weCrit, isMelee)
    local weapons = getPlayerWeapons(t.Player)
    
    local damage = 0
    for weaponSlot, available in pairs(availability) do
        if available then
            local activeSkill = weapons[weaponSlot] ~= nil and weapons[weaponSlot].Skill or const.Skills.Unarmed
            local wEffect = getWeaponEffect(onHitEventType, weCrit, weapons[weaponSlot], activeSkill)
            local chance = wEffect[wefChance]
            local skill, mastery = SplitSkill(t.Player.Skills[activeSkill])
            if calcIfWeaponEffectProcs(skill, chance, t.Player) then
                damage = damage + calcCritDmg(weapons[weaponSlot], wEffect[wefMultiplier], t.Player)           
            end
        end
    end 
    return damage
end

function tryToPerformExtraDamageOnMonsterCondition(t, onHitEventType, isMelee) 
    local availability = getWeaponsEffectAvailability(t.Player, onHitEventType,weExtraDamageOnMonsterCondition, isMelee)
    local weapons = getPlayerWeapons(t.Player)
    
    local damage = 0
    for weaponSlot, available in pairs(availability) do
        if available then
            local activeSkill = weapons[weaponSlot] ~= nil and weapons[weaponSlot].Skill or const.Skills.Unarmed
            local wEffect = getWeaponEffect(onHitEventType, weExtraDamageOnMonsterCondition, weapons[weaponSlot], activeSkill)
            local AIState = wEffect[wefAIState]
            if AIState[t.Monster.AIState] then 
                local skill, mastery = SplitSkill(t.Player.Skills[activeSkill])
                local chance = wEffect[wefChance]
                if calcIfWeaponEffectProcs(skill, chance, t.Player) then
                    local multiplier = wEffect[wefMultiplier]
                    local extraDmg = calcWeaponDmg( weapons[weaponSlot], t.Player) * multiplier      
                    damage = damage + extraDmg
                end
            end
        end
    end 
    return damage
end

function tryToPerformExtraDamageWhenMonsterHPThreshold(t, onHitEventType, isMelee) 
    local availability = getWeaponsEffectAvailability(t.Player, onHitEventType,weExtraDamageWhenMonsterHPThreshold, isMelee)
    local weapons = getPlayerWeapons(t.Player)
    
    local damage = 0
    for weaponSlot, available in pairs(availability) do
        if available then
            local activeSkill = weapons[weaponSlot] ~= nil and weapons[weaponSlot].Skill or const.Skills.Unarmed
            local wEffect = getWeaponEffect(onHitEventType, weExtraDamageWhenMonsterHPThreshold, weapons[weaponSlot], activeSkill)

            local skill, mastery = SplitSkill(t.Player.Skills[activeSkill])
            local chance = wEffect[wefChance]
            if calcIfWeaponEffectProcs(skill, chance, t.Player) then
                local lowerThreshold = wEffect[wefLowerThreshold]
                local higherThreshold = wEffect[wefHigherThreshold]
                local multiplier = wEffect[wefMultiplier]
                damage = damage + extraDmgWhenMonsterHPIsInThreshold(t.Player, t.Monster, weapons[weaponSlot], lowerThreshold, higherThreshold, multiplier) 
            end
        end
    end 
    return damage
end

function tryToPerformExtraDamageWhenPlayerHPThreshold(t, onHitEventType, isMelee) 
    local availability = getWeaponsEffectAvailability(t.Player, onHitEventType,weExtraDamageWhenPlayerHPThreshold, isMelee)
    local weapons = getPlayerWeapons(t.Player)
    
    local damage = 0
    for weaponSlot, available in pairs(availability) do
        if available then
            local activeSkill = weapons[weaponSlot] ~= nil and weapons[weaponSlot].Skill or const.Skills.Unarmed
            local wEffect = getWeaponEffect(onHitEventType, weExtraDamageWhenPlayerHPThreshold, weapons[weaponSlot], activeSkill)

            local skill, mastery = SplitSkill(t.Player.Skills[activeSkill])
            local chance = wEffect[wefChance]
            if calcIfWeaponEffectProcs(skill, chance, t.Player) then
                local lowerThreshold = wEffect[wefLowerThreshold]
                local higherThreshold = wEffect[wefHigherThreshold]
                local multiplier = wEffect[wefMultiplier]
                damage = damage + extraDmgWhenPlayerHPInThreshold(t.Player, t.Monster, weapons[weaponSlot], lowerThreshold, higherThreshold, multiplier)
            end
        end
    end 
    return damage
end

function tryToPerformAmbush(t, onHitEventType, isMelee) 
    local damage = 0
    -- https://grayface.github.io/mm/ext/ref/#const.AIState
    -- 9 fidget, 0 standing, 1 active, 10 interacting (friendly standing infront of party)
    if t.Monster.HP == t.Monster.FullHP and (t.Monster.AIState == 9 or t.Monster.AIState == 0 or t.Monster.AIState == 1 or t.Monster.AIState == 10) then
        local availability = getWeaponsEffectAvailability(t.Player, onHitEventType, weAmbush, isMelee)
        local weapons = getPlayerWeapons(t.Player)
        
        for weaponSlot, available in pairs(availability) do
            if available then
                local activeSkill = weapons[weaponSlot] ~= nil and weapons[weaponSlot].Skill or const.Skills.Unarmed
                local wEffect = getWeaponEffect(onHitEventType, weAmbush, weapons[weaponSlot], activeSkill)
                local multiplier = wEffect[wefMultiplier]
                local ambushDmg = calcWeaponDmg(weapons[weaponSlot], t.Player) * multiplier
                damage = damage + ambushDmg
            end
        end 
    end

    return damage
end

function getWeaponsEffectAvailability(player, onHitEventType, weaponEffectId, isMelee) 
    local weapons = getPlayerWeapons(player)

    local mainSkill = weapons.main ~= nil and weapons.main.Skill or const.Skills.Unarmed
    local extraSkill = weapons.extra ~= nil and weapons.extra.Skill or const.Skills.Unarmed
    local availableMainHand = isWeaponEffectAvailableOnWeapon(player, onHitEventType, weaponEffectId, weapons.main, mainSkill, extraSkill)
    local availableExtraHand = isWeaponEffectAvailableOnWeapon(player, onHitEventType, weaponEffectId, weapons.extra, extraSkill, mainSkill)
    local missileSkill = weapons.missile ~= nil and weapons.missile.Skill or const.Skills.Unarmed
    local availableMissile = isWeaponEffectAvailableOnWeapon(player, onHitEventType, weaponEffectId, weapons.missile, missileSkill, nil)

    -- -- -- Blasters are not implemented
    --  Blasters will only get benefit of shields.
    if mainSkill == const.Skills.Blaster and extraSkill == const.Skills.Shield then
        return {
            ["main"] = availableMainHand,
            ["extra"] = availableExtraHand
        }
    elseif mainSkill == const.Skills.Blaster then
        return {
            ["main"] = availableMainHand,
        }
    elseif isMelee then
        return {
            ["main"] = availableMainHand,
            ["extra"] = availableExtraHand
        }
    elseif isMelee == false then
        return {
            ["missile"] = availableMissile
        }
    else -- its an onHitPlayer event and all weapons can potentially have an effect
        return {
            ["main"] = availableMainHand,
            ["extra"] = availableExtraHand,
            ["missile"] = availableMissile
        } 
    end
end

function isWeaponEffectAvailableOnWeapon(player, onHitEventType, weaponEffectId, activeWeapon, activeSkill, otherSkill) 
    local effect = getWeaponEffect(onHitEventType, weaponEffectId, activeWeapon, activeSkill)
    if effect == nil then
        return false
    end
    local skill, mastery = SplitSkill(player.Skills[activeSkill])
    -- skill mastery is required and player fails the test
    if effect[wefMastery] ~= nil and effect[wefMastery] > mastery then 
        return  false
    end
    local extraReqs = effect[wefExtraReqs]
    if extraReqs ~= nil then 
        if extraReqs[reqsMasteriesOr] ~= nil then
            -- Loop through all MasteriesOr, if one of them passes set doPlayerMeetOneReq = true
            local doPlayerMeetOneReq = false
            for reqSkill, reqMastery in pairs(extraReqs[reqsMasteriesOr]) do
                local pSkill, pMastery = SplitSkill(player.Skills[reqSkill])
                if reqMastery <= pMastery then
                    doPlayerMeetOneReq = true;
                    break
                end
            end
            if doPlayerMeetOneReq == false then
                return false
            end
        end
        if extraReqs[reqsOtherHand] ~= nil and otherSkill ~= nil then
            -- players other hand needs to employ a certain skill to be able to use the weapon effect 
            if extraReqs[reqsOtherHand][otherSkill] == false then
                return false
            end
        end
    end
    -- all tests passed
    return true
end

-- cant use Weapon.Skill because if Unarmed then weapon is nil 
function getWeaponEffect(onHitEventType, weaponEffectId, weapon, skill)

    -- Deeper table nesting when skill is not Unarmed
    if (skill ~= const.Skills.Unarmed and skill ~= nil) then
        return weaponEffects[skill][weapon.EquipStat][onHitEventType][weaponEffectId]
    elseif (skill == const.Skills.Unarmed) then
        return weaponEffects[skill][onHitEventType][weaponEffectId]
    end
end

function getPlayerWeapons(player)
    local mainHand = player.ItemMainHand  
    local extraHand = player.ItemExtraHand 
    local missileHand = player.ItemBow
    local mainWeapon = mainHand ~= 0 and player.Items[mainHand].Number
    local extraWeapon = extraHand ~= 0 and player.Items[extraHand].Number
    local missileWeapon = missileHand ~= 0 and player.Items[missileHand].Number
    local mainWeaponTxt = mainHand ~= 0 and Game.ItemsTxt[mainWeapon] or nil
    local extraWeaponTxt = extraHand ~= 0 and Game.ItemsTxt[extraWeapon] or nil
    local missileWeaponTxt = missileHand ~= 0 and Game.ItemsTxt[missileWeapon] or nil

    return {
        ["main"] = mainWeaponTxt,
        ["extra"] = extraWeaponTxt,
        ["missile"] = missileWeaponTxt
    }
end

function extraDmgWhenPlayerHPInThreshold(player, monster, weaponTxt, lowerThreshold, higherThreshold, multiplier) 
    local damage = 0
    local ratioHPLeft = player.HP / player:GetFullHP()
    if ratioHPLeft <= higherThreshold and ratioHPLeft >= lowerThreshold then
        damage = calcWeaponDmg(weaponTxt, player) * multiplier - player.HP / player:GetFullHP() -- HP / FullHP is a hard coded logic where lower hp means better, should fix this
    end
    return damage
end

function extraDmgWhenMonsterHPIsInThreshold(player, monster, weaponTxt, lowerThreshold, higherThreshold, multiplier) 
    local damage = 0
    local ratioHPLeft = monster.HP / monster.FullHP
    if ratioHPLeft <= higherThreshold and ratioHPLeft >= lowerThreshold then
        damage = calcWeaponDmg(weaponTxt, player) * multiplier
    end
    return damage
end

function greaterCleave(weaponTxt, monsterIndex, multiplier, player)
    monsterIndex = monsterIndex or 0
    for i in Map.Monsters do
        -- avoid damaging the same monster an extra time
        if i ~= MonsterIndex then
            local monster = Map.Monsters[i]
            -- Ensure we don"t do damage to monsters immune to physical damage or player attack none hostiles
            if monster.PhysResistance < 200 and monster.Hostile then
                if isMonsterInMeleeRange(monster) then 
                    weaponDamageToMonsterOutsideAttackEvent(monster, i, weaponTxt, multiplier, player)
                end
            
            end
        end
    end
end

function applyMonsterBuffOnAllInMeleeRange(duration, power) 
    for i in Map.Monsters do
        local monster = Map.Monsters[i]
        if isMonsterInMeleeRange(monster) then
            applyMonsterBuff(monster, duration, power)
        end
    end
end

function applyMonsterBuff(monster, duration, power) 
    monster.SpellBuffs[power].ExpireTime = Game.Time + duration * const.Minute -- 1 Minute is 256 is game time, which in real time game play translate to 2 seconds.
end

function weaponDamageToMonsterOutsideAttackEvent(monster, monsterIndex, weaponTxt, multiplier, player) 
    local dmg = calcWeaponDmg(weaponTxt, player) * multiplier
    -- Avoids getting exp for monsters already killed
    if monster.HP > 0 and (monster.HP - dmg) < 1 then
        AddKillExp(monster.Experience)
        evt.PlaySound(monster.SoundDie, monster.X, monster.Y)
        monster.AIState = const.AIState.Dying
        local killer = {
            ["Type"] = 4,
            ["Player"] = player,
        }
        events.cocall("MonsterKilled", monster, monsterIndex, nil, killer)
    else
        evt.PlaySound(monster.SoundGetHit, monster.X, monster.Y)
    end
    monster.HP = monster.HP - dmg
end

function calcIfWeaponEffectProcs(skill, chance, player) 
    math.randomseed(os.time())
    -- First draft was: skill * chance + Game.GetStatisticEffect(player:GetLuck()) 
    -- howeverr this made it impossible to create effects with a guaranteed low chance off success
    if chance < 1 then
        return math.random(99) < (skill + Game.GetStatisticEffect(player:GetLuck()) * chance)
    else 
        return math.random(99) < (skill * chance + Game.GetStatisticEffect(player:GetLuck()))
    end
end

-- multiplier can be a decimal or whole number 
function calcCritDmg(itemTxt, multiplier, player) 
    return math.floor(calcWeaponDmg(itemTxt, player) * multiplier)
end

function calcUnarmedDmg(player) 
    local skill, mastery = SplitSkill(player.Skills[const.Skills.Unarmed])
    local unarmedSkillDmg = mastery == const.Expert and skill or mastery >= const.Master and skill * 2 or 0
    local diceDmg = castDices(3, 1)
    local strengthMod = Game.GetStatisticEffect(player:GetMight())
    return unarmedSkillDmg + diceDmg + strengthMod
end

-- TODO: Rename to calcDmgType, then include a dmgType param that calls a new calcWeaponDmg if dmgType is weaponDmg
function calcWeaponDmg(itemTxt, player)
    -- if attack is an unarmed attack itemTxt is nil
    if (itemTxt ~= nil) then 
        local diceDmg = castDices(itemTxt.Mod1DiceSides, itemTxt.Mod1DiceCount)
        -- Not sure if all of the bonuses are relevant and should be added?
        return diceDmg + itemTxt.Mod2 -- + itemTxt.Bonus + itemTxt.Bonus2 + itemTxt.BonusStrength
    else
        return calcUnarmedDmg(player)
    end
end

function castDices(sides, count) 
    local result = 0;
    local dicesCast = 0;
    math.randomseed(os.time())
    while dicesCast < count do
        result = result + math.random(1, sides)
        dicesCast = dicesCast + 1
    end
    return result
end

function isMonsterInMeleeRange(monster) 
    local deltaX = monster.X - Party.X
    local deltaY = monster.Y - Party.Y
    local deltaZ = monster.Z - Party.Z
    distance = math.sqrt(deltaX * deltaX + deltaY * deltaY + deltaZ * deltaZ);
    return distance < 350
end

local mmver = offsets.MMVersion

local function mmv(...)
	return select(mmver - 5, ...)
end

local function mm78(...)
	return select(mmver - 5, nil, ...)
end

function AddKillExp(exp) 
    mem.call(0x424D5B,2, exp)
end

--- 
-- GrayFace — Today at 6:56 AM
-- @viktor This should solve the problem
-- WhoHitPlayer() would show the monster and MonsterAction. const.MonsterAction = {
--     Attack1 = 0,
--     Attack2 = 1,
--     Spell1 = 2,
--     Spell2 =3,
-- }
if not WhoHitMonster then
    local u4 = mem.u4
	-- WhoHitMonster
	local p = mem.StaticAlloc(12)
	u4[p] = 0
	local hooks = HookManager{
		att = p,      -- attacker ObjRef
		mon = p + 4,  -- monster index
		kind = p + 8, -- mon attack kind
		ret = 4,      -- stack arguments*4
	}
	local push = [[
		mov eax, [esp + %ret%]
		push eax
	]]
	local s = push..[[
		mov [%att%], ecx
		mov [%mon%], edx
		call @std
		mov dword [%att%], 0
		ret %ret%
	@std:
	]]
	local mon = push..[[
		mov [%kind%], eax
	]]..s
	hooks.asmhook(mmv(0x430E50, 0x439463, 0x436E26), s)  -- from party
	if mmver > 6 then
		hooks.asmhook(mm78(0x43B07A, 0x438C6E), s)  -- from event
		hooks.ref.ret = 8
		hooks.asmhook(mm78(0x43B1D3, 0x438DDE), mon)  -- from monster
	end
	
	local function Who(i)
		local t, kind = {}, i%8
		i = (i - kind)/8
		if kind == 2 then
			local obj = Map.Objects[i]
			t.ObjectIndex, t.Object = i, obj
			i = obj.Owner
			kind = i%8
			i = (i - kind)/8
		end
		if kind == 4 then
			t.PlayerIndex, t.Player = i, Party.PlayersArray[i]
		elseif kind == 3 then
			t.MonsterIndex, t.Monster, t.MonsterAction = i, Map.Monsters[i], u4[p + 8]
		end
		return t
	end
	
	-- If a monster is being attacked, returns 't', #TargetMon:structs.MapMonster#, 'TargetMonIndex'
	-- #t.Player:structs.Player# and 't.PlayerIndex' are set if monster is attacked by the party.
	-- #t.Monster:structs.MapMonster#, 't.MonsterIndex' and #t.MonsterAction:const.MonsterAction# fields are set if monster is attacked by another monster.
	-- #t.Object:structs.MapObject# and 't.ObjectIndex' are set if monster is hit by a missile.
	function WhoHitMonster()
		local i = u4[p]
		if i ~= 0 then
			local t, i = Who(i), u4[p + 4]
			return t, Map.Monsters[i], i
		end
	end
	
	-- WhoHitPlayer
	local p = mem.StaticAlloc(12)
	u4[p] = 0
	local hooks = HookManager{
		att = p,      -- attacker ObjRef
		slot = p + 4, -- party slot
		kind = p + 8, -- mon attack kind
		ret = 8,      -- stack arguments*4
	}
	local s = push..[[
		mov [%slot%], eax
	]]..push..[[
		mov [%att%], ecx
		mov [%kind%], edx
		call @std
		mov dword [%att%], 0
		ret %ret%
	@std:
	]]
	hooks.asmhook(mmv(0x431BE0, 0x439FEE, 0x437B06), s)

	-- If party is being attacked, returns 't', 'PlayerSlot'
	-- #t.Monster:structs.MapMonster#, 't.MonsterIndex' and #t.MonsterAction:const.MonsterAction# fields are set if player is attacked by a monster.
	-- #t.Object:structs.MapObject# and 't.ObjectIndex' are set if player is hit by a missile.
	function WhoHitPlayer()
		local i = u4[p]
		if i ~= 0 then
			return Who(i), u4[p + 4]
		end
	end
end

-- function tprint (t, s)
--     for k, v in pairs(t) do
--         local kfmt = '["' .. tostring(k) ..'"]'
--         if type(k) ~= 'string' then
--             kfmt = '[' .. k .. ']'
--         end
--         local vfmt = '"'.. tostring(v) ..'"'
--         if type(v) == 'table' then
--             tprint(v, (s or '')..kfmt)
--         else
--             if type(v) ~= 'string' then
--                 vfmt = tostring(v)
--             end
--             print(type(t)..(s or '')..kfmt..' = '..vfmt)
--         end
--     end
-- end
