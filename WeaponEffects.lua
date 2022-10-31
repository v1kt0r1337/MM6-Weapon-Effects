local LogId = "mmtestLog"
local Log = Log

local onHitMonster = 1
local onHitPlayer = 2
-- weapon effect. Al of these needs unique numbers
local weBlock = 1   -- implemented
local weCrit = 2  -- implemented
local weInstantKill = 3   -- implemented 
local weTrueDamage = 4    -- implemented
local weGreaterCleave = 5 -- implemented 
local weExtraDamageOnMonsterCondition = 6 -- implemented
local weExtraDamageWhenMonsterHPThreshold = 7 -- implemented
local weExtraDamageWhenPlayerHPThreshold = 8 -- implemented
local weApplyMonsterBuff = 9 -- implemented
local weAmbush = 10 -- implemented
local weApplyMonsterBuffOnAllInMeleeRange = 11    -- implemented
local weExtraDamageWhenPlayerCondition = 12 -- not implemented
-- weapon effect field. all of these needs unique numbers
local wefMultiplier = 1
local wefChance = 2
local wefDuration = 3
local wefAIState = 4
local wefLowerThreshold = 5
local wefHigherThreshold = 6
local wefPower = 7
local wefScale = 8
local wefGameStatusText = 9
local wefExtraReqs = 10
local wefMastery = 11 --minimum required mastery

local scaleWithLowHP = 1
local scaleWithHighHP = 2

local statusText = 1
local textPosition = 2
local textPositionPre = 3
local textPositionPost = 4

-- all of these needs unique numbers
local reqsMasteriesOr = 1
local reqsOtherHand = 2
-- local reqsMainHand = 2
-- local reqsMissile = 4

local crit = {
    [wefChance] = 1,
    [wefMultiplier] = 2,
    [wefMastery] = const.GM,
    [wefGameStatusText] = {
        [statusText] = "critical",
        [textPosition] = textPositionPre,
    } 
}

local greaterCleave = {
    [wefChance] = 1,
    [wefMastery] = const.GM,
    [wefMultiplier] = 1,
    [wefGameStatusText] = {
        [statusText] = "cleaves",
        [textPosition] = textPositionPost,
    } 
}

local instantKill = {
    [wefChance] = 0.5,
    [wefMastery] = const.GM,
    [wefGameStatusText] = {
        [statusText] = "executes",
        [textPosition] = textPositionPre,
    } 
}

local extraDmgPlayerLowHp = {
    -- player hp between (inclusive) 0-50%
    [wefLowerThreshold] = 0,
    [wefHigherThreshold] = 0.75,
    [wefMultiplier] = 2,
    [wefMastery] = const.GM,
    [wefChance] = 100,
    [wefScale] = scaleWithLowHP,
    [wefGameStatusText] = {
        [statusText] = "angrily hits",
        [textPosition] = textPositionPre,
    } 
}

local trueDamage = {
    [wefMastery] = const.GM,
    [wefChance] = 100,
    [wefExtraReqs] = {
        [reqsOtherHand] = {
            [const.Skills.Shield] = true,
            [const.Skills.Unarmed] = true   
        }
    },
    [wefGameStatusText] = {
        [statusText] = "true",
        [textPosition] = textPositionPre,
    } 
}

local extraDmgMonsterLowHp = {
    -- monster hp between (inclusive) 0-50%
    [wefLowerThreshold] = 0,
    [wefHigherThreshold] = 0.5,
    [wefMultiplier] = 1,
    [wefMastery] = const.GM,
    [wefChance] = 100,
    [wefGameStatusText] = {
        [statusText] = "punish",
        [textPosition] = textPositionPre,
    } 
}

local extraDmgWhenMonsterIsStunnedOrParalyzed = {
    [wefAIState] = {
        [const.AIState.Paralyzed] = true,
        [const.AIState.Stunned] = true
    },
    [wefMastery] = const.GM,
    [wefMultiplier] = 2,                    
    [wefChance] = 100,
    [wefGameStatusText] = {
        [statusText] = "brutalize",
        [textPosition] = textPositionPre,
    } 
}

local applyParalyzeToAllMonstersInMelee = {
    [wefChance] = 1,
    [wefMastery] = const.GM,
    [wefDuration] = 2, -- * const.Minute  (Minute / 2 == second)s
    -- https://grayface.github.io/mm/ext/ref/#const.MonsterBuff
    [wefPower] = 6,
    [wefGameStatusText] = { 
        [statusText] = "slams shield in a wide circle",
        [textPosition] = textPositionPre,
    } 
}

local block = { -- works on both weapon and shield
    -- chance * skill + Game.GetStatisticEffect(pl:GetLuck())
    [wefChance] = 1,
    -- damageFactor of 0 completely negates all damage, 
    [wefMultiplier] = 0,
    [wefMastery] = const.GM,
    [wefGameStatusText] = {
        [statusText] = "parries",
        [textPosition] = textPositionPre,
    } 
}

local defaultAmbushMultiplier = 1

local ambush = {
    [wefMultiplier] = defaultAmbushMultiplier,
    [wefGameStatusText] = {
        [statusText] = "ambush",
        [textPosition] = textPositionPre,
    } 
}

local allOnHitMonsterEffects = {
    [weAmbush] = ambush,
    [weCrit] = crit,
    [weGreaterCleave] = greaterCleave,
    [weInstantKill] = instantKill,
    [weExtraDamageWhenPlayerHPThreshold] = extraDmgPlayerLowHp,
    [weTrueDamage] = trueDamage,
    [weExtraDamageOnMonsterCondition] = extraDmgWhenMonsterIsStunnedOrParalyzed,
    [weApplyMonsterBuffOnAllInMeleeRange] = applyParalyzeToAllMonstersInMelee,
    [weExtraDamageWhenMonsterHPThreshold] = extraDmgMonsterLowHp
}

local allOnHitPlayerEffects = {
    [weBlock] = block,
    [weGreaterCleave] = greaterCleave, -- cleave should not be on shield
    [weApplyMonsterBuffOnAllInMeleeRange] = applyParalyzeToAllMonstersInMelee,
}

local function MergeTables(...)
    local result = {}
    for _, t in ipairs{...} do
        for k, v in pairs(t) do
            result[k] = v
        end
        local mt = getmetatable(t)
        if mt then
            setmetatable(result, mt)
        end
        end
    return result
end

local function DeepCopy(object)
    local lookup_table = {}
    local function Copy(object) 
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for key, value in pairs(object) do
            new_table[Copy(key)] = Copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return Copy(object)
end

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
                    },
                    [wefMastery] = const.GM,
                    [wefMultiplier] = 1,
                    [wefChance] = 100,
                    [wefGameStatusText] = {
                        [statusText] = "brutalize",
                        [textPosition] = textPositionPre,
                    } 
                },
                [weExtraDamageWhenMonsterHPThreshold] = MergeTables(extraDmgMonsterLowHp, 
                    {[wefExtraReqs] = {
                        [reqsMasteriesOr] = {
                            -- Makes this weapon effect only available to Monks 
                            [const.Skills.Unarmed] = const.GM,
                        }
                     }}
                )
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
                [weGreaterCleave] = MergeTables(greaterCleave, {
                    [wefChance] = 0.8,
                    [wefGameStatusText] = {
                        [statusText] = "revenge cleaves",
                        [textPosition] = textPositionPre,
                    }
                })           
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
                [weApplyMonsterBuffOnAllInMeleeRange] = applyParalyzeToAllMonstersInMelee
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
            }
        },
    },
}

-- Effects triggered in ItemAdditionalDamage will be shown to player in CalcDamageToMonster
function events.ItemAdditionalDamage(t)
    -- local wskill, wmastery = SplitSkill(t.Player.Skills[const.Skills.Air])
    -- t.Player.Skills[const.Skills.Air] = JoinSkill(math.max(wskill, 20), math.max(wmastery, const.GM))
    local activeSkill = Game.ItemsTxt[t.Item.Number].Skill
    local damage = 0
    damage = damage + TryToPerformAmbush(t, onHitMonster, activeSkill)
    TryToPerformGreaterCleave(t, onHitMonster, activeSkill)
    TryToPerformApplyMonsterBuffOnAllInMeleeRange(t, onHitMonster, activeSkill)
    TryToPerformApplyMonsterBuff(t.Player, t.Monster, onHitMonster, activeSkill)

    damage = damage + TryToPerformCrit(t, onHitMonster, activeSkill)

    damage = damage + TryToPerformExtraDamageOnMonsterCondition(t, onHitMonster, activeSkill)
    damage = damage + TryToPerformExtraDamageWhenMonsterHPThreshold(t, onHitMonster, activeSkill)
    damage = damage + TryToPerformExtraDamageWhenPlayerHPThreshold(t, onHitMonster, activeSkill)
    t.Result = damage
end

local defaultEventTracker = {
    totalCalcDamageToMonsters = 0,
    currentCalcDamageToMonster = 0,
    damageDone = 0,
    cleaveDamage = 0,
    kills = 0,
    paralyze = 0,
    blockedDamage = 0,
    textPositionPre = {
        -- [weEffect] = {
        --  text = "",
        --  power (optional) = 6
        -- }
    },
    textPositionPost = {
        -- [weEffect] = {
        --  text = "",
        --  power (optional) = 6
        -- }
    }
}

local eventTracker = DeepCopy(defaultEventTracker)

function InitiateNewAttackEventRound(player, isMelee) 
    eventTracker.totalCalcDamageToMonsters = GetTotalCalcDamageToMonsters(player, isMelee)
end 

function GetTotalCalcDamageToMonsters(player, isMelee) 
    local weapons = GetPlayerWeapons(player)
    mainSkill = weapons.main ~= nil and weapons.main.Skill or const.Skills.Unarmed
    if isMelee == false and mainSkill ~= const.Skills.Blaster then
        return 2
    end
    
    if mainSkill == const.Skills.Blaster then
        return 1
    end

    if mainSkill == const.Skills.Unarmed and weapons.extra == nil then
        -- if Unarmed and hammerhands then two CalcDamageToMonster will get triggered
        if player.SpellBuffs[6].ExpireTime > Game.Time then
            return 2
        else
            return 1
        end
    end

    local extraSkill = weapons.extra ~= nil and weapons.extra.Skill or const.Skills.Unarmed
    if extraSkill == const.Skills.Unarmed then
        return 2
    end
    return 3
end

function ShowStatusTextOnHitMonster(player, monster) 
    -- vanilla text
    -- Player.Name hits MonsterName for x damage
    -- Player.Name stuns MonsterName
    -- Player.Name inflicts x points killing MonsterName
    local function DisplayStatusText() 
        local statusText = player.Name
        local textPositionPre = eventTracker.textPositionPre
        if textPositionPre ~= nil then
            for wEffectId, effectStatus in pairs(textPositionPre) do
                statusText = statusText .. " " .. effectStatus.text
            end
        end
        local damage = eventTracker.damageDone
        local monsterName = monster.Name or Game.MonstersTxt[monster.Id].Name or ""
        if  monster.HP - damage < 1 then
            statusText = statusText .. " for " .. tostring(damage) .. " dmg killing " .. monsterName
        else 
            statusText = statusText .. " " .. monsterName .. " for " .. tostring(damage) .. " dmg" 
        end
        local isFirstPostPosition = true
        local textPositionPost = eventTracker.textPositionPost
        if textPositionPost ~= nil then
            for wEffectId, effectStatus in pairs(textPositionPost) do
                if isFirstPostPosition then
                    statusText = statusText .. " and"
                    isFirstPostPosition = false
                end
                statusText = statusText .. " " .. effectStatus.text
                if wEffectId == weGreaterCleave then
                    statusText = statusText .. " for " .. eventTracker.cleaveDamage .. " dmg"
                    if eventTracker.kills > 0 then
                        statusText = statusText .. " killing " .. eventTracker.kills .. "!"
                    end
                end
            end
        end
        Game.ShowStatusText(statusText)
        eventTracker = DeepCopy(defaultEventTracker)
        RemoveTimer(DisplayStatusText)
    end
    if next(eventTracker.textPositionPre) ~= nil or next(eventTracker.textPositionPost) ~= nil then
        Timer(DisplayStatusText, nil, Game.Time)
    else 
        eventTracker = DeepCopy(defaultEventTracker)
    end
end

function GetPlayerEquipedWeaponSkills(player) 
    local weapons = GetPlayerWeapons(player)
    local mainSkill = weapons.main ~= nil and weapons.main.Skill or const.Skills.Unarmed
    local extraSkill = weapons.extra ~= nil and weapons.extra.Skill or const.Skills.Unarmed 
    local missileSkill = weapons.missile ~= nil and weapons.missile.Skill or nil
    return {
        main = mainSkill,
        extra = extraSkill,
        missle = missileSkill
    } 
end 

function ShowStatusTextOnHitPlayer(player) 
    -- think this needs to be declared localy or we will Get problems with it repeating again and again.
    local function DisplayStatusText() 
        local statusText = player.Name
        local textPositionPre = eventTracker.textPositionPre
        if textPositionPre ~= nil then
            local hasPreText = false
            for wEffectId, effectStatus in pairs(textPositionPre) do
                hasPreText = true
                statusText = statusText .. " " .. effectStatus.text

                if wEffectId == weBlock then
                    statusText = statusText .. " " .. -eventTracker.blockedDamage .. " dmg!"
                end

                if wEffectId == weGreaterCleave then
                    statusText = statusText .. " for " .. eventTracker.cleaveDamage .. " dmg"
                    if eventTracker.kills > 0 then
                        statusText = statusText .. " killing " .. eventTracker.kills .. "!"
                    end
                end
                if effectStatus.power == const.MonsterBuff.Paralyze then
                    if eventTracker.paralyze > 0 then
                        statusText = statusText .. " paralyzing " .. eventTracker.paralyze .. "!"
                    else 
                        statusText = statusText .. " hitting only air!"
                    end
                end
            end
        end

        local textPositionPost = eventTracker.textPositionPost
        if textPositionPost ~= nil then
            local isFirstPostPosition = true
            for wEffectId, effectStatus in pairs(textPositionPost) do
                if isFirstPostPosition and hasPreText then
                    statusText = statusText .. " and "
                    isFirstPostPosition = false
                end
                statusText = statusText .. " " .. effectStatus.text
                if wEffectId == weGreaterCleave then
                    statusText = statusText .. " for " .. eventTracker.cleaveDamage .. "dmg"
                    if eventTracker.kills > 0 then
                        statusText = statusText .. " killing " .. eventTracker.kills .. "!"
                    end
                end
                if effectStatus.power == const.MonsterBuff.Paralyze then
                    if eventTracker.paralyze > 0 then
                        statusText = statusText .. " paralyzing " .. eventTracker.paralyze .. "!"
                    else 
                        statusText = statusText .. " hitting only air!"
                    end
                end
            end
        end
        Game.ShowStatusText(statusText)
        eventTracker = DeepCopy(defaultEventTracker)
        RemoveTimer(DisplayStatusText)
    end
    if next(eventTracker.textPositionPre) ~= nil or next(eventTracker.textPositionPost) ~= nil then
        Timer(DisplayStatusText, nil, Game.Time)
    else 
        eventTracker = DeepCopy(defaultEventTracker)
    end
end

-- Will return nil on first round of CalcDamageToMonstersEvent if not using Unarmed or Blaster
function GetActiveSkillBasedOnCurrentCalcDamageToMonstersEvent(player, monster, isMelee)
    local itemMain = player.ItemMainHand ~= 0 and Game.ItemsTxt[player.Items[player.ItemMainHand].Number] or nil
    local mainSkill = itemMain ~= nil and itemMain.Skill or const.Skills.Unarmed
    if isMelee ~= true and mainSkill ~= const.Skills.Blaster then
        return const.Skills.Bow
    end

    local itemExtra = player.ItemExtraHand ~= 0 and Game.ItemsTxt[player.Items[player.ItemExtraHand].Number] or nil
    local extraSkill = itemExtra ~= nil and itemExtra.Skill or const.Skills.Unarmed
    if eventTracker.currentCalcDamageToMonster == 1 then
        if mainSkill == const.Skills.Blaster then
            return mainSkill 
        elseif mainSkill == const.Skills.Unarmed and ekstraSkill == const.Skills.Unarmed or extraSkill == const.Skills.Shield then
            return mainSkill
        else return nil
        end 
        
        return mainSkill == const.Skills.Blaster and const.Skills.Blaster or mainSkill == const.Skills.Unarmed 
    elseif eventTracker.currentCalcDamageToMonster == 3 then
        -- check on Unarmed is not valid because it will not trigger 3 times if extra hand is unarmed 
        return extraSkill
    else -- currentCalcDamageToMonster == 2 is usually main hand, but if player has unarmed or blaster in main hand and a dagger or sword in extra hand then it can be extra hand 
        if mainSkill == const.Skills.Blaster or mainSkill == const.Skills.Unarmed then
            return extraSkill
        else  
            return mainSkill
        end
    end
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

    local isMelee = IsMonsterInMeleeRange(t.Monster)
    
    -- When currentCalcDamageToMonster is 0 we differentiate if this is a physical attack or a spell
    if eventTracker.currentCalcDamageToMonster == 0 then
        local playerUsesBlaster = t.Player.ItemMainHand ~= 0 and Game.ItemsTxt[t.Player.Items[t.Player.ItemMainHand].Number].Skill == const.Skills.Blaster or false
        -- Weapon Effects should only trigger on Physical attacks or blaster attacks.
        -- DamageKind 0 seems to be used when its additional item damage
        if t.DamageKind ~= const.Damage.Phys and t.DamageKind ~= 12 then 
            return
        elseif t.DamageKind == 12 and playerUsesBlaster == false then 
            return
        end
        InitiateNewAttackEventRound(t.Player, isMelee)
    end

    eventTracker.currentCalcDamageToMonster = eventTracker.currentCalcDamageToMonster + 1
    -- activeSkill needs to be extracted after InitiateNewAttackEventRound
    local activeSkill = GetActiveSkillBasedOnCurrentCalcDamageToMonstersEvent(t.Player, t.Monster, isMelee)
    
    local damage = 0
    local itemMain = t.Player.ItemMainHand ~= 0 and Game.ItemsTxt[t.Player.Items[t.Player.ItemMainHand].Number] or nil
    local mainSkill = itemMain == nil and const.Skills.Unarmed or itemMain.Skill
    -- This is needed to be able to proc skills with unarmed attacks or blasters
    if (isMelee and t.Player.ItemMainHand == 0 and eventTracker.currentCalcDamageToMonster == 1 ) or activeSkill == const.Skills.Blaster then

        local dmgReductionFactor = t.Result / t.Damage
        damage = damage + TryToPerformAmbush(t, onHitMonster, mainSkill)
        TryToPerformGreaterCleave(t, onHitMonster, mainSkill) 
        TryToPerformApplyMonsterBuffOnAllInMeleeRange(t, onHitMonster, mainSkill)
        TryToPerformApplyMonsterBuff(t.Player, t.Monster, onHitMonster, mainSkill)

        damage = damage + TryToPerformCrit(t, onHitMonster, mainSkill)
        damage = damage + TryToPerformExtraDamageOnMonsterCondition(t, onHitMonster, mainSkill)

        damage = damage + TryToPerformExtraDamageWhenMonsterHPThreshold(t, onHitMonster, mainSkill)

        damage = damage + TryToPerformExtraDamageWhenPlayerHPThreshold(t, onHitMonster, mainSkill)
        -- nan checks on both
        if damage == damage and dmgReductionFactor == dmgReductionFactor then
            damage = damage * dmgReductionFactor
        end
    end

    if activeSkill ~= nil then
        damage = damage + TryToPerformInstantKill(t, onHitMonster, activeSkill)
    end

    -- if true damage then use t.Damage instead of t.Result
    -- if active skill is nil its we will use the mainSkill as we want it to become true damage if main skill has the requirement
    if TryToPerformTrueDamage(t, onHitMonster, activeSkill or mainSkill) then
        damage = damage + t.Damage
    else 
        damage = damage + t.Result
    end 
    
    -- if this is the last CalcDamageToMonster in the attack then it's time to show the status text
    if eventTracker.totalCalcDamageToMonsters == eventTracker.currentCalcDamageToMonster then
        ShowStatusTextOnHitMonster(t.Player, t.Monster)
    end
    t.Result = math.floor(damage)
    eventTracker.damageDone = eventTracker.damageDone + t.Result
end

function events.CalcDamageToPlayer(t) 
    local attacker = WhoHitPlayer()
    if attacker == nil then
        -- if a monster was not the source then we do not want to proc effects
        return 
    end
    if attacker.MonsterIndex == nil then
        -- if a monster was not the source then we do not want to proc effects
        return 
    end

    local monster = Map.Monsters[attacker.MonsterIndex]
    local equipedSkills = GetPlayerEquipedWeaponSkills(t.Player)
    local damageFactor = 1
    for slot, skill in pairs(equipedSkills) do
    -- Greater cleaver counter attack
        TryToPerformGreaterCleave(t, onHitPlayer, skill)
        TryToPerformApplyMonsterBuff(t.Player, monster, onHitPlayer, skill)
        TryToPerformApplyMonsterBuffOnAllInMeleeRange(t, onHitPlayer, skill)
        -- damageFactors stacks if two procs reduce damage with a factor of 0.5 the result will be 0.25
        damageFactor = damageFactor * TryToPerformBlock(t, onHitPlayer, skill)
    end

    eventTracker.blockedDamage = eventTracker.blockedDamage - (t.Result * damageFactor) - t.Result
    -- damageFactor 1 is full damage, damageFactor 0 is no damage, 0.5 is half damage
    t.Result = t.Result * damageFactor
    ShowStatusTextOnHitPlayer(t.Player)
end

function TryToPerformTrueDamage(t, onHitEventType, activeSkill)
    local availability = GetWeaponsEffectAvailability(t.Player, onHitEventType, weTrueDamage, activeSkill)
    local weapons = GetPlayerWeapons(t.Player)
    local available = availability.available
    if available then
        -- try to perform true damage
        local activeSlot = availability.activeSlot
        local wEffect = GetWeaponEffect(onHitEventType, weTrueDamage, weapons[activeSlot], activeSkill)
        local chance = wEffect[wefChance]
        local skill, mastery = SplitSkill(t.Player.Skills[activeSkill])
        if CalcIfWeaponEffectProcs(skill, chance, t.Player) then
            AddStatusText({wEffect = wEffect, wEffectId = weTrueDamage})
            return true
        end
    end
    return false
end

function TryToPerformInstantKill(t, onHitEventType, activeSkill) 
    local damage = 0
    local availability = GetWeaponsEffectAvailability(t.Player, onHitEventType, weInstantKill, activeSkill)
    local weapons = GetPlayerWeapons(t.Player)
    local available = availability.available
    if available then
        -- try to perform the kill
        local activeSlot = availability.activeSlot
        local wEffect = GetWeaponEffect(onHitEventType, weInstantKill, weapons[activeSlot], activeSkill)
        local chance = wEffect[wefChance]

        local skill, mastery = SplitSkill(t.Player.Skills[activeSkill])
        if CalcIfWeaponEffectProcs(skill, chance, t.Player) then
            damage = damage + t.Monster.HP
            AddStatusText({wEffect = wEffect, wEffectId = weInstantKill})
        end
    end
    return damage  
end

function TryToPerformGreaterCleave(t, onHitEventType, activeSkill) 
    local availability = GetWeaponsEffectAvailability(t.Player, onHitEventType, weGreaterCleave, activeSkill)
    local weapons = GetPlayerWeapons(t.Player)
    local available = availability.available

    if available then
        local activeSlot = availability.activeSlot
        local wEffect = GetWeaponEffect(onHitEventType, weGreaterCleave, weapons[activeSlot], activeSkill)
        local chance = wEffect[wefChance]
        local multiplier = wEffect[wefMultiplier]
        local skill, mastery = SplitSkill(t.Player.Skills[activeSkill])
        if CalcIfWeaponEffectProcs(skill, chance, t.Player) then
            GreaterCleave(weapons[activeSlot], t.MonsterIndex, multiplier, t.Player)
            if eventTracker.cleaveDamage > 0 then
                AddStatusText({wEffect = wEffect, wEffectId = weGreaterCleave})
            end
        end
    end
end

function TryToPerformApplyMonsterBuffOnAllInMeleeRange(t, onHitEventType, activeSkill)
    local availability = GetWeaponsEffectAvailability(t.Player, onHitEventType, weApplyMonsterBuffOnAllInMeleeRange, activeSkill)
    local weapons = GetPlayerWeapons(t.Player)
    local available = availability.available

    if available then
        local activeSlot = availability.activeSlot
        local wEffect = GetWeaponEffect(onHitEventType, weApplyMonsterBuffOnAllInMeleeRange, weapons[activeSlot], activeSkill)
        local chance = wEffect[wefChance]
        local skill, mastery = SplitSkill(t.Player.Skills[activeSkill])
        if CalcIfWeaponEffectProcs(skill, chance, t.Player) then
            local duration = wEffect[wefDuration]
            local power = wEffect[wefPower]
            ApplyMonsterBuffOnAllInMeleeRange(duration, power)
            AddStatusText({wEffect = wEffect, wEffectId = weApplyMonsterBuffOnAllInMeleeRange, power = power})
        end
    end
end


function TryToPerformApplyMonsterBuff(player, monster, onHitEventType, activeSkill)
    local availability = GetWeaponsEffectAvailability(player, onHitEventType, weApplyMonsterBuff, activeSkill)
    local weapons = GetPlayerWeapons(player)
    local available = availability.available

    if available then
        local activeSlot = availability.activeSlot
        local wEffect = GetWeaponEffect(onHitEventType, weApplyMonsterBuff, weapons[activeSlot], activeSkill)
        local chance = wEffect[wefChance]
        local skill, mastery = SplitSkill(player.Skills[activeSkill])
        if CalcIfWeaponEffectProcs(skill, chance, player) then
            local duration = wEffect[wefDuration]
            local power = wEffect[wefPower]
            AddStatusText({wEffect = wEffect, wEffectId = weApplyMonsterBuff, power = power})
            ApplyMonsterBuff(monster, duration, power)
        end
    end
end

-- returns damage factor, if 1 then damage is unchanged, if 0 then all damage is blocked, if 0.5 50% of the dmg is blocked. result = damage * damageFactor
function TryToPerformBlock(t, onHitEventType, activeSkill) 
    local availability = GetWeaponsEffectAvailability(t.Player, onHitEventType, weBlock, activeSkill )
    local weapons = GetPlayerWeapons(t.Player)
    local available = availability.available

    if available then
        local activeSlot = availability.activeSlot
        local wEffect = GetWeaponEffect(onHitEventType, weBlock, weapons[activeSlot], activeSkill)
        local chance = wEffect[wefChance]
        local skill, mastery = SplitSkill(t.Player.Skills[activeSkill])
        if CalcIfWeaponEffectProcs(skill, chance, t.Player) then
            AddStatusText({wEffect = wEffect, wEffectId = weBlock})
            return wEffect[wefMultiplier]
        end
    end     
    return 1
end

function TryToPerformCrit(t, onHitEventType, activeSkill)
    local availability = GetWeaponsEffectAvailability(t.Player, onHitEventType, weCrit, activeSkill)
    local weapons = GetPlayerWeapons(t.Player)
    local damage = 0
    local available = availability.available
    if available then
        local activeSlot = availability.activeSlot
        local wEffect = GetWeaponEffect(onHitEventType, weCrit, weapons[activeSlot], activeSkill)
        local chance = wEffect[wefChance]
        local skill, mastery = SplitSkill(t.Player.Skills[activeSkill])
        if CalcIfWeaponEffectProcs(skill, chance, t.Player) then
            damage = damage + CalcCritDmg(weapons[activeSlot], wEffect[wefMultiplier], t.Player)           
            AddStatusText({wEffect = wEffect, wEffectId = weCrit})
        end
    end
    return damage
end

function TryToPerformExtraDamageOnMonsterCondition(t, onHitEventType, activeSkill) 
    local availability = GetWeaponsEffectAvailability(t.Player, onHitEventType,weExtraDamageOnMonsterCondition, activeSkill)
    local weapons = GetPlayerWeapons(t.Player)
    local damage = 0
    local available = availability.available

    if available then
        local activeSlot = availability.activeSlot
        local wEffect = GetWeaponEffect(onHitEventType, weExtraDamageOnMonsterCondition, weapons[activeSlot], activeSkill)
        local AIState = wEffect[wefAIState]
         if AIState[t.Monster.AIState] then 
            local skill, mastery = SplitSkill(t.Player.Skills[activeSkill])
            local chance = wEffect[wefChance]
            if CalcIfWeaponEffectProcs(skill, chance, t.Player) then
                local multiplier = wEffect[wefMultiplier]
                local extraDmg = CalcWeaponDmg( weapons[activeSlot], t.Player) * multiplier      
                damage = damage + extraDmg
                AddStatusText({wEffect = wEffect, wEffectId = weExtraDamageOnMonsterCondition})
            end
        end
    end
    return damage
end

function TryToPerformExtraDamageWhenMonsterHPThreshold(t, onHitEventType, activeSkill) 
    local availability = GetWeaponsEffectAvailability(t.Player, onHitEventType,weExtraDamageWhenMonsterHPThreshold, activeSkill)
    local weapons = GetPlayerWeapons(t.Player)
    local damage = 0
    local available = availability.available
    if available then
        local activeSlot = availability.activeSlot
        local wEffect = GetWeaponEffect(onHitEventType, weExtraDamageWhenMonsterHPThreshold, weapons[activeSlot], activeSkill)

        local skill, mastery = SplitSkill(t.Player.Skills[activeSkill])
        local chance = wEffect[wefChance]
        if CalcIfWeaponEffectProcs(skill, chance, t.Player) then
            local lowerThreshold = wEffect[wefLowerThreshold]
            local higherThreshold = wEffect[wefHigherThreshold]
            local multiplier = wEffect[wefMultiplier]
            damage = damage + ExtraDmgWhenMonsterHPIsInThreshold(t.Player, t.Monster, weapons[activeSlot], lowerThreshold, higherThreshold, multiplier) 
            if damage > 0 then
                AddStatusText({wEffect = wEffect, wEffectId = weExtraDamageWhenMonsterHPThreshold})
            end
        end
    end
    return damage
end

function TryToPerformExtraDamageWhenPlayerHPThreshold(t, onHitEventType, activeSkill) 
    local availability = GetWeaponsEffectAvailability(t.Player, onHitEventType,weExtraDamageWhenPlayerHPThreshold, activeSkill)
    local weapons = GetPlayerWeapons(t.Player)
    local damage = 0
    local available = availability.available

    if available then
        local activeSlot = availability.activeSlot
        local wEffect = GetWeaponEffect(onHitEventType, weExtraDamageWhenPlayerHPThreshold, weapons[activeSlot], activeSkill)
        local skill, mastery = SplitSkill(t.Player.Skills[activeSkill])
        local chance = wEffect[wefChance]
        if CalcIfWeaponEffectProcs(skill, chance, t.Player) then
            local lowerThreshold = wEffect[wefLowerThreshold]
            local higherThreshold = wEffect[wefHigherThreshold]
            local scale = wEffect[wefScale]
            local multiplier = wEffect[wefMultiplier]
            damage = damage + ExtraDmgWhenPlayerHPInThreshold(t.Player, t.Monster, weapons[activeSlot], lowerThreshold, higherThreshold, multiplier, scale)
            if damage > 0 then
                AddStatusText({wEffect = wEffect, wEffectId = weExtraDamageWhenPlayerHPThreshold})
            end
        end
    end

    return damage
end

function TryToPerformAmbush(t, onHitEventType, activeSkill)
    local damage = 0
    -- https://grayface.github.io/mm/ext/ref/#const.AIState
    -- had to remove t.Monster.AIState == 0 because 
    -- 9 fidget, 0 standing, 1 active, 10 interacting (friendly standing infront of party). 
    if t.Monster.HP == t.Monster.FullHP and 
        (t.Monster.AIState == const.AIState.Fidget or t.Monster.AIState == const.AIState.Active or 
        -- or t.Monster.AIState == const.AIState.Stand monster enters this state during combat
        t.Monster.AIState == const.AIState.Interact) then
        local availability = GetWeaponsEffectAvailability(t.Player, onHitEventType, weAmbush, activeSkill)
        local weapons = GetPlayerWeapons(t.Player)
        local available = availability.available
        
        if available then
            local activeSlot = availability.activeSlot
            -- local activeSkill = weapons[weaponSlot] ~= nil and weapons[weaponSlot].Skill or const.Skills.Unarmed
            local wEffect = GetWeaponEffect(onHitEventType, weAmbush, weapons[activeSlot], activeSkill)
            local multiplier = wEffect[wefMultiplier]
            local ambushDmg = CalcWeaponDmg(weapons[activeSlot], t.Player) * multiplier
            damage = damage + ambushDmg
            if damage > 0 then 
                AddStatusText({wEffect = wEffect, wEffectId = weAmbush})
            end
        end
    end
    return damage
end

function AddStatusText(t)
    local wEffect = t.wEffect
    local wEffectId = t.wEffectId
    local power = t.power
    
    if wEffect[wefGameStatusText][textPosition] == textPositionPost then
        eventTracker.textPositionPost[wEffectId] = {
            text = wEffect[wefGameStatusText][statusText],
            power = power,
        }
    else 
        eventTracker.textPositionPre[wEffectId] = {
            text = wEffect[wefGameStatusText][statusText],
            power = power,
        }
    end
end


function GetWeaponsEffectAvailability(player, onHitEventType, weaponEffectId, activeSkill) 
    local weapons = GetPlayerWeapons(player)

    local mainSkill = weapons.main ~= nil and weapons.main.Skill or const.Skills.Unarmed
    local extraSkill = weapons.extra ~= nil and weapons.extra.Skill or const.Skills.Unarmed
    local missileSkill = weapons.missile ~= nil and weapons.missile.Skill or const.Skills.Unarmed

    local otherSkills = {}
    local activeSlot
    if activeSkill == mainSkill then
        activeSlot = "main"
        otherSkills.otherHand = extraSkill
        otherSkills.missile = missileSkill
    -- if player is dual wielding same weapon type it will in this context not matter which of the weapons is the actual trigger 
    elseif activeSkill == extraSkill then
        activeSlot = "extra"
        otherSkills.otherHand = mainSkill
        otherSkills.missile = missileSkill   
    else 
        activeSlot = "missile"
        otherSkills.mainHand = mainSkill
        otherSkills.otherHand = extraSkill   
    end

    local available = IsWeaponEffectAvailableOnWeapon(player, onHitEventType, weaponEffectId, weapons[activeSlot], activeSkill, otherSkills)

    return {available = available, activeSlot = activeSlot};
end

function IsWeaponEffectAvailableOnWeapon(player, onHitEventType, weaponEffectId, activeWeapon, activeSkill, otherSkills) 
    local effect = GetWeaponEffect(onHitEventType, weaponEffectId, activeWeapon, activeSkill)
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
        if extraReqs[reqsOtherHand] ~= nil then
            -- players other hand needs to employ a certain skill to be able to use the weapon effect 
            if extraReqs[reqsOtherHand][otherSkills.otherHand] ~= true then
                return false
            end
        end
    end
    -- all tests passed
    return true
end

function GetWeaponEffect(onHitEventType, weaponEffectId, weapon, skill)
    -- Deeper table nesting when skill is not Unarmed
    if (skill ~= const.Skills.Unarmed and skill ~= nil and weapon ~= nil) then
        return weaponEffects[skill][weapon.EquipStat][onHitEventType][weaponEffectId]
    elseif (skill == const.Skills.Unarmed) then
        return weaponEffects[skill][onHitEventType][weaponEffectId]
    end
end

function GetPlayerWeapons(player)
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

function ExtraDmgWhenPlayerHPInThreshold(player, monster, weaponTxt, lowerThreshold, higherThreshold, multiplier, scale) 
    local damage = 0
    local ratioHPLeft = player.HP / player:GetFullHP()

    local effectiveMultiplier = multiplier
    if scale == scaleWithLowHP then
        effectiveMultiplier = multiplier - player.HP / player:GetFullHP()
    elseif scaleWithHighHP then 
        effectiveMultiplier = multiplier + player.HP / player:GetFullHP()
    end

    if ratioHPLeft <= higherThreshold and ratioHPLeft >= lowerThreshold then
        damage = math.floor(CalcWeaponDmg(weaponTxt, player) * effectiveMultiplier)
    end
    return damage
end

function ExtraDmgWhenMonsterHPIsInThreshold(player, monster, weaponTxt, lowerThreshold, higherThreshold, multiplier) 
    local damage = 0
    local ratioHPLeft = monster.HP / monster.FullHP
    if ratioHPLeft <= higherThreshold and ratioHPLeft >= lowerThreshold then
        damage = CalcWeaponDmg(weaponTxt, player) * multiplier
    end
    return damage
end

-- Returns the number of effected targets
function GreaterCleave(weaponTxt, monsterIndex, multiplier, player)
    monsterIndex = monsterIndex or 0
    for i in Map.Monsters do
        -- avoid damaging the same monster an extra time
        if i ~= MonsterIndex then
            local monster = Map.Monsters[i]
            -- Ensure we don"t do damage to monsters immune to physical damage or player attack none hostiles
            if monster.PhysResistance < 200 and monster.Hostile then
                if IsMonsterInMeleeRange(monster) then 
                    WeaponDamageToMonsterOutsideAttackEvent(monster, i, weaponTxt, multiplier, player)
                end
            
            end
        end
    end
end

function ApplyMonsterBuffOnAllInMeleeRange(duration, power) 
    for i in Map.Monsters do
        local monster = Map.Monsters[i]
        if IsMonsterInMeleeRange(monster) then
            ApplyMonsterBuff(monster, duration, power)
        end
    end
end

function ApplyMonsterBuff(monster, duration, power) 
    if monster.HP > 0 then
        evt.PlaySound(monster.SoundGetHit, monster.X, monster.Y)
        monster.SpellBuffs[power].ExpireTime = Game.Time + duration * const.Minute -- 1 Minute is 256 is game time, which in real time game play translate to 2 seconds.
        if power == 6 then
            monster.AIState = const.AIState.Paralyzed
            eventTracker.paralyze = eventTracker.paralyze + 1
        elseif power == 4 then
            monster.AIState = const.AIState.Flee
        end

    end
end

function WeaponDamageToMonsterOutsideAttackEvent(monster, monsterIndex, weaponTxt, multiplier, player) 
    local dmg = CalcWeaponDmg(weaponTxt, player) * multiplier

    -- Avoids Getting exp for monsters already killed
    if monster.HP > 0 and (monster.HP - dmg) < 1 then
        AddKillExp(monster.Experience)
        evt.PlaySound(monster.SoundDie, monster.X, monster.Y)
        monster.AIState = const.AIState.Dying
        local killer = {
            ["Type"] = 4,
            ["Player"] = player,
        }
        -- Existing in merge, but won't throw errors if used in game without this event.
        events.cocall("MonsterKilled", monster, monsterIndex, nil, killer)
        eventTracker.kills = eventTracker.kills + 1
    else
        evt.PlaySound(monster.SoundGetHit, monster.X, monster.Y)
    end
    eventTracker.cleaveDamage = eventTracker.cleaveDamage + dmg
    monster.HP = monster.HP - dmg
end

function CalcIfWeaponEffectProcs(skill, chance, player) 
    math.randomseed(os.time())
    -- First draft was: skill * chance + Game.GetStatisticEffect(player:GetLuck()) 
    -- however this made it impossible to create effects with a guaranteed low chance off success
    if chance < 1 then
        return math.random(99) < (skill + Game.GetStatisticEffect(player:GetLuck()) * chance)
    else 
        return math.random(99) < (skill * chance + Game.GetStatisticEffect(player:GetLuck()))
    end
end

-- multiplier can be a decimal or whole number 
function CalcCritDmg(itemTxt, multiplier, player) 
    return math.floor(CalcWeaponDmg(itemTxt, player) * multiplier)
end

function CalcUnarmedDmg(player) 
    local skill, mastery = SplitSkill(player.Skills[const.Skills.Unarmed])
    local unarmedSkillDmg = mastery == const.Expert and skill or mastery >= const.Master and skill * 2 or 0
    local diceDmg = CastDices(3, 1)
    local strengthMod = Game.GetStatisticEffect(player:GetMight())
    return unarmedSkillDmg + diceDmg + strengthMod
end

-- TODO: Rename to CalcDmgType, then include a dmgType param that calls a new CalcWeaponDmg if dmgType is weaponDmg
function CalcWeaponDmg(itemTxt, player)
    -- if attack is an unarmed attack itemTxt is nil
    if (itemTxt ~= nil) then 
        local diceDmg = CastDices(itemTxt.Mod1DiceSides, itemTxt.Mod1DiceCount)
        -- Not sure if all of the bonuses are relevant and should be added?
        return diceDmg + itemTxt.Mod2 -- + itemTxt.Bonus + itemTxt.Bonus2 + itemTxt.BonusStrength
    else
        return CalcUnarmedDmg(player)
    end
end

function CastDices(sides, count) 
    local result = 0;
    local dicesCast = 0;
    math.randomseed(os.time())
    while dicesCast < count do
        result = result + math.random(1, sides)
        dicesCast = dicesCast + 1
    end
    return result
end

function IsMonsterInMeleeRange(monster) 
    local deltaX = monster.X - Party.X
    local deltaY = monster.Y - Party.Y
    local deltaZ = monster.Z - Party.Z
    distance = math.sqrt(deltaX * deltaX + deltaY * deltaY + deltaZ * deltaZ);
    return distance < 350
end

local mmver = offsets.MMVersion

function mmv(...)
	return select(mmver - 5, ...)
end

function mm78(...)
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
	
	function Who(i)
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


function TPrint (t, s)
    for k, v in pairs(t) do
        local kfmt = '["' .. tostring(k) ..'"]'
        if type(k) ~= 'string' then
            kfmt = '[' .. k .. ']'
        end
        local vfmt = '"'.. tostring(v) ..'"'
        if type(v) == 'table' then
            TPrint(v, (s or '')..kfmt)
        else
            if type(v) ~= 'string' then
                vfmt = tostring(v)
            end
            print(type(t)..(s or '')..kfmt..' = '..vfmt)
        end
    end
end