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

-- All wands are given the Skill type fire
local wandSkill = const.Skills.Fire

local crit = {
    [wefChance] = 20,
    [wefMultiplier] = 2,
    [wefMastery] = const.Master,
    [wefGameStatusText] = {
        [statusText] = "critical",
        [textPosition] = textPositionPre,
    } 
}

local greaterCleave = {
    [wefChance] = 1,
    [wefMastery] = const.Master,
    [wefMultiplier] = 1,
    [wefGameStatusText] = {
        [statusText] = "cleaves",
        [textPosition] = textPositionPre,
    } 
}

local instantKill = {
    [wefChance] = 0.5,
    [wefMastery] = const.Master,
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
    [wefMastery] = const.Master,
    [wefChance] = 100,
    [wefScale] = scaleWithLowHP,
    [wefGameStatusText] = {
        [statusText] = "angrily hits",
        [textPosition] = textPositionPre,
    } 
}

local trueDamage = {
    [wefMastery] = const.Master,
    [wefChance] = 100,
    [wefExtraReqs] = {
        [reqsOtherHand] = {
            [const.Skills.Shield] = true,
            ["Unarmed"] = true   
        }
    },
    [wefGameStatusText] = {
    } 
}

local extraDmgMonsterLowHp = {
    -- monster hp between (inclusive) 0-50%
    [wefLowerThreshold] = 0,
    [wefHigherThreshold] = 0.5,
    [wefMultiplier] = 5,
    [wefMastery] = const.Master,
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
    [wefMastery] = const.Master,
    [wefMultiplier] = 2,                    
    [wefChance] = 100,
    [wefGameStatusText] = {
        [statusText] = "brutalize",
        [textPosition] = textPositionPre,
    } 
}

local applyParalyzeToAllMonstersInMelee = {
    [wefChance] = 1,
    [wefMastery] = const.Master,
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
    [wefMastery] = const.Master,
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
                [weExtraDamageWhenMonsterHPThreshold] = extraDmgMonsterLowHp,
                -- [weExtraDamageOnMonsterCondition] = extraDmgWhenMonsterIsStunnedOrParalyzed,
            },
            [onHitPlayer] = {
            }
        }
    },
    [const.Skills.Sword] = {
        [const.ItemType.Weapon - 1] = {
            [onHitMonster] =  {
            },
            [onHitPlayer] = {
                [weBlock] = block,
            }
        },
        [const.ItemType.Weapon2H - 1] = {
            [onHitMonster] = {
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
                [weCrit] = crit,
            },
            [onHitPlayer] = {
                
            }
        }
    },
    [const.Skills.Axe] = {
        [const.ItemType.Weapon - 1] = {
            [onHitMonster] = {
                [weGreaterCleave] = greaterCleave,
            },
            [onHitPlayer] = {
                
            }
        },
        [const.ItemType.Weapon2H - 1] = {
            [onHitMonster] = {
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
    [wandSkill] = {
        [const.ItemType.Wand - 1] = {
            [onHitMonster] = {
            },
            [onHitPlayer] = {
            }
        }
    }
}

function events.LoadMap()
    -- for i in Game.ItemsTxt do
    --     if Game.ItemsTxt[i].Name == "Blaster" then
    --         evt.Add("Inventory",i)
    --     end
    -- end
    -- print(dump(const))
end

-- each index represent the damage done by a party member
local partyDamageTracker = {
    {
        damage = 0
     },
    {
        damage = 0
    },
    { 
        damage = 0
    },
    { 
        damage = 0
    }
}

function showDamage() 
    print("Player damage done")
    for i, player in ipairs(partyDamageTracker) do
        print(player.damage)
    end
end


local defaultAttackEventTrackerMeta = {
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

local defaultAttackEventTracker = {
    -- if gameTime has changed overwrite all data
    -- if gameTime is the same, and its the same attacker and attacked then we sum up all the effects and dmg 
    gameTime = -1,
    -- the current round indexes and type. Indexes has to be in string or we will get big trouble...
    attackerIndex = "-1",
    attackedIndex = "-1",
    attackedType = "", -- "monsterAttacked" | "playerAttacked"
    playerAttacked = {
        -- ["attackerIndex"] = {
        --     meta = defaultAttackEventTrackerMeta,
        --     targets = {
        --         ["attackedIndex"] = {
        --              damage = 0,
        --              source = "melee" | "bow" | "blaster" | "other" -- other is typically spells, wand or scrolls
        --         }
        --     }
        -- }
    },
    monsterAttacked = {
        -- ["attackerIndex"] = {
        --     meta = defaultAttackEventTrackerMeta,
        --     targets = {
        --         ["attackedIndex"] = {
        --              damage = 0,
        --              source = "melee" | "bow" | "blaster" | "other" -- other is typically spells, wand or scrolls
        --         }
        --     }
        -- }
    },
}

local attackEventTracker = DeepCopy(defaultAttackEventTracker)

function ShowStatusTextOnHitMonster(playerIndex, monsterIndex) 
    local player = Party.Players[playerIndex]
    local monster = Map.Monsters[monsterIndex]
    local statusText = player.Name
    local attackerIndex = attackEventTracker.attackerIndex
    local attackedIndex = attackEventTracker.attackedIndex
    local attackEventContent = attackEventTracker.monsterAttacked[attackerIndex]
    local attackEventMeta = attackEventContent.meta
    local statusText = player.Name
    local textPositionPre = attackEventMeta.textPositionPre
    local textPositionPost = attackEventMeta.textPositionPost
    local damageSource =  attackEventContent.targets[attackedIndex].source
    local damage = attackEventContent.targets[attackedIndex].damage

    local hasCleaved = false
    if textPositionPre ~= nil then
        for wEffectId, effectStatus in pairs(textPositionPre) do
            statusText = statusText .. " " .. effectStatus.text
            
            if wEffectId == weGreaterCleave then
                hasCleaved = true
                local cleaveDamage = attackEventMeta.cleaveDamage + damage
                local kills = monster.HP <= damage and attackEventMeta.kills + 1 or attackEventMeta.kill
                statusText = statusText .. " for " .. cleaveDamage .. " dmg"
                if attackEventMeta.kills > 0 then
                    statusText = statusText .. " killing " .. kills .. "!"
                end
            end
        end
    end

    if next(textPositionPre) == nil and next(textPositionPost) == nil then
        local isRanged = damageSource == "blaster" or damageSource == "bow"
        local hitText = monster.HP < 1 and "hits" or isRanged == true and "shoots" or "hits"
        statusText = statusText .. " " .. hitText
    end

    if hasCleaved == false then
        local monsterName = monster.Name or Game.MonstersTxt[monster.Id].Name or ""
        if  monster.HP < 1 then
            statusText = statusText .. " for " .. tostring(damage) .. " dmg killing " .. monsterName
        else 
            statusText = statusText .. " " .. monsterName .. " for " .. tostring(damage) .. " dmg" 
        end

        local isFirstPostPosition = true
        if textPositionPost ~= nil then
            for wEffectId, effectStatus in pairs(textPositionPost) do
                if isFirstPostPosition then
                    statusText = statusText .. " and"
                    isFirstPostPosition = false
                end
                statusText = statusText .. " " .. effectStatus.text
            end
        end
    end

    Game.ShowStatusText(statusText)
end

function ShowStatusTextOnHitPlayer(playerIndex, monsterIndex) 
    local attackerIndex = attackEventTracker.attackerIndex
    local attackEventContent = attackEventTracker.playerAttacked[attackerIndex]
    local attackEventMeta = attackEventContent.meta

    if next(attackEventMeta.textPositionPre) == nil and next(attackEventMeta.textPositionPost) == nil then
        return
    end
    local player = Party.Players[playerIndex]

    local statusText = player.Name
    local textPositionPre = attackEventMeta.textPositionPre
    if textPositionPre ~= nil then
        local hasPreText = false
        for wEffectId, effectStatus in pairs(textPositionPre) do
            hasPreText = true
            statusText = statusText .. " " .. effectStatus.text

            if wEffectId == weBlock then
                statusText = statusText .. " " .. -attackEventMeta.blockedDamage .. " dmg!"
            end

            if wEffectId == weGreaterCleave then
                statusText = statusText .. " for " .. attackEventMeta.cleaveDamage .. " dmg"
                if attackEventMeta.kills > 0 then
                    statusText = statusText .. " killing " .. attackEventMeta.kills .. "!"
                end
            end
            if effectStatus.power == const.MonsterBuff.Paralyze then
                if attackEventMeta.paralyze > 0 then
                    statusText = statusText .. " paralyzing " .. attackEventMeta.paralyze .. "!"
                else 
                    statusText = statusText .. " hitting only air!"
                end
            end
        end
    end

    local textPositionPost = attackEventMeta.textPositionPost
    if textPositionPost ~= nil then
        local isFirstPostPosition = true
        for wEffectId, effectStatus in pairs(textPositionPost) do
            if isFirstPostPosition and hasPreText then
                statusText = statusText .. " and "
                isFirstPostPosition = false
            end
            statusText = statusText .. " " .. effectStatus.text
            if wEffectId == weGreaterCleave then
                statusText = statusText .. " for " .. attackEventMeta.cleaveDamage .. "dmg"
                if attackEventMeta.kills > 0 then
                    statusText = statusText .. " killing " .. attackEventMeta.kills .. "!"
                end
            end
            if effectStatus.power == const.MonsterBuff.Paralyze then
                if attackEventMeta.paralyze > 0 then
                    statusText = statusText .. " paralyzing " .. attackEventMeta.paralyze .. "!"
                else 
                    statusText = statusText .. " hitting only air!"
                end
            end
        end
    end
    Game.ShowStatusText(statusText)
end

function GetPlayerEquipedWeaponSkills(player) 
    local weapons = GetPlayerWeapons(player)
    local mainSkill = weapons.main ~= nil and weapons.main.Skill or nil
    local extraSkill = weapons.extra ~= nil and weapons.extra.Skill or nil
    local missileSkill = weapons.missile ~= nil and weapons.missile.Skill or nil
    return {
        main = mainSkill,
        extra = extraSkill,
        missle = missileSkill
    } 
end 

-- attackedType is either "playerAttacked" or "monsterAttacked"
function HandleInitiateAttackEventTracker(attackerIndex, attackedIndex, attackedType)
    if attackEventTracker.gameTime ~= Game.Time then
        attackEventTracker = DeepCopy(defaultAttackEventTracker)
        attackEventTracker.gameTime = Game.Time
    end 
    attackEventTracker.attackerIndex = tostring(attackerIndex)
    attackEventTracker.attackedIndex = tostring(attackedIndex)
    attackEventTracker.attackedType = attackedType

    if attackEventTracker[attackedType][attackEventTracker.attackerIndex] == nil then
        attackEventTracker[attackedType][attackEventTracker.attackerIndex] = {
            meta = DeepCopy(defaultAttackEventTrackerMeta),
            targets = {
            }
        }
    end
    if attackEventTracker[attackedType][attackEventTracker.attackerIndex].targets[attackEventTracker.attackedIndex] == nil then
        attackEventTracker[attackedType][attackEventTracker.attackerIndex].targets[attackEventTracker.attackedIndex] = {
            damage = 0,
        }
        if attackedType == "monsterAttacked" then
            SetSourceOnMonsterAttackedEvent()
        end
    end

end

function events.PlayerAttacked(t) 
    if t.Attacker.Monster then
        HandleInitiateAttackEventTracker(t.Attacker.MonsterIndex, t.PlayerSlot, "playerAttacked")
    end
end

function events.MonsterAttacked(t) 
    if t.Attacker.Player then
        HandleInitiateAttackEventTracker(t.Attacker.PlayerSlot , t.MonsterIndex, "monsterAttacked")
    end
end

function events.CalcDamageToMonster(t)
    if t.Player == nil then
        local hitter = WhoHitMonster()
        t.Player = hitter["Player"]
        t.PlayerIndex = hitter['PlayerIndex']
    end
    if t.Player == nil then
        return
    end
    source = GetSourceOnMonsterAttackedEvent()
    -- ensure we don't trigger weapon effects on spells like Shrapmetal
    if source == "other" then
        AddDamageToAttackEvent(t.Result)
        return
    end

    -- Ensure we don't do extra damage to monsters immune to physical damage, probably not wise even with blaster
    if t.Monster.PhysResistance == 200 then
        -- add none physical dmg to total dmg done
        AddDamageToAttackEvent(t.Result)
        return
    end

    local mainHand = t.Player.ItemMainHand ~= 0 and Game.ItemsTxt[t.Player.Items[t.Player.ItemMainHand].Number] or nil

    local playerUsesBlaster = const.Damage.Energy == t.DamageKind and mainHand ~= nil and mainHand.Skill == const.Skills.Blaster

    if t.DamageKind == const.Damage.Phys or playerUsesBlaster then
        t.Result = TryToPerformOffensiveEffects(t)
    end
    AddDamageToAttackEvent(t.Result)
end

function GetSourceOnMonsterAttackedEvent()
    local attackerIndex = attackEventTracker.attackerIndex
    local attackedIndex = attackEventTracker.attackedIndex
    local source = attackEventTracker.monsterAttacked[attackerIndex].targets[attackedIndex].source
    return source
end

-- this should only be called on the first damage source of an attack
-- the subsequential damages from an enchanted weapon will not have the same bodyLocation 
-- differentiating between them is not interesting in our context
function SetSourceOnMonsterAttackedEvent() 
    local source = "other"
    local hitter = WhoHitMonster()
    if hitter.Player ~= nil then
        -- hit by ranged attack
        if hitter.Object ~= nil then
            local bodyLocation = hitter.Object.Item.BodyLocation
            if bodyLocation == 0 then
                -- typically spells and wand and probably scrolls
                source = "other"
            elseif bodyLocation == 2 then
                source = "blaster"
            elseif bodyLocation == 3 then
                source = "bow"
            end
        else 
            source = "melee"
        end
    end

    local attackerIndex = attackEventTracker.attackerIndex
    local attackedIndex = attackEventTracker.attackedIndex
    attackEventTracker.monsterAttacked[attackerIndex].targets[attackedIndex].source = source
end

function events.AfterMonsterAttacked(t) 
    if t.Attacker.Player ~= nil then
        local attackerIndex = attackEventTracker.attackerIndex
        local attackedIndex = attackEventTracker.attackedIndex
        local damage = attackEventTracker.monsterAttacked[attackerIndex].targets[attackedIndex].damage
        if damage ~= nil and damage > 0 then
            -- Object.BodyLocation 2 == blaster, 3 == bow, spells and wand == 0
            if t.Attacker.Object ~= nil and t.Attacker.Object.Item ~= nil and t.Attacker.Object.Item.BodyLocation ~= 0 then
                ShowStatusTextOnHitMonster(t.Attacker.PlayerSlot, t.MonsterIndex)
            end
            -- is melee attack
            if t.Attacker.Object == nil then
                ShowStatusTextOnHitMonster(t.Attacker.PlayerSlot, t.MonsterIndex)
            end
        end
    end
end

function events.CalcDamageToPlayer(t) 
    local attacker = WhoHitPlayer()
    -- attacker is nil when party is hurt by water or fall damage
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
        if (skill ~= nil) then
            TryToPerformGreaterCleave(t, onHitPlayer, skill)
            TryToPerformApplyMonsterBuff(t.Player, monster, onHitPlayer, skill)
            TryToPerformApplyMonsterBuffOnAllInMeleeRange(t, onHitPlayer, skill)
            -- damageFactors stacks if two procs reduce damage with a factor of 0.5 the result will be 0.25
            damageFactor = damageFactor * TryToPerformBlock(t, onHitPlayer, skill)
        end
    end

    local attackerIndex = attackEventTracker.attackerIndex

    attackEventTracker.playerAttacked[attackerIndex].meta.blockedDamage = attackEventTracker.playerAttacked[attackerIndex].meta.blockedDamage - (t.Result * damageFactor) - t.Result
    -- damageFactor 1 is full damage, damageFactor 0 is no damage, 0.5 is half damage
    t.Result = t.Result * damageFactor
    ShowStatusTextOnHitPlayer(t.PlayerIndex, attacker.MonsterIndex)
end

-- returns the damage done by offensive effects
function TryToPerformOffensiveEffects(t) 
    local damage = 0
    local activeSkills = GetActiveSkills(t)
    local dmgReductionFactor = t.Result / t.Damage
    local hasSuccessfullyPeformedTrueDmg = false

    for index, activeSkill in pairs(activeSkills) do 
        --- do dmg that should be affected by dmg reduction
        damage = damage + TryToPerformAmbush(t, onHitMonster, activeSkill)
        TryToPerformGreaterCleave(t, onHitMonster, activeSkill) 
        TryToPerformApplyMonsterBuffOnAllInMeleeRange(t, onHitMonster, activeSkill)
        TryToPerformApplyMonsterBuff(t.Player, t.Monster, onHitMonster, activeSkill)
        damage = damage + TryToPerformCrit(t, onHitMonster, activeSkill)
        damage = damage + TryToPerformExtraDamageOnMonsterCondition(t, onHitMonster, activeSkill)
        damage = damage + TryToPerformExtraDamageWhenMonsterHPThreshold(t, onHitMonster, activeSkill)
        damage = damage + TryToPerformExtraDamageWhenPlayerHPThreshold(t, onHitMonster, activeSkill)
        -- nan checks on both
        if damage == damage and dmgReductionFactor == dmgReductionFactor then
            damage = damage * dmgReductionFactor
        end
        damage = damage + TryToPerformInstantKill(t, onHitMonster, activeSkill)
        if TryToPerformTrueDamage(t, onHitMonster, activeSkill) then
            hasSuccessfullyPeformedTrueDmg = true;
        end 
    end
    if hasSuccessfullyPeformedTrueDmg then
        damage = damage + t.Damage
    else 
        damage = damage + t.Result
    end
    return math.floor(damage)
end

function GetActiveSkills(t) 

    source = GetSourceOnMonsterAttackedEvent()

    local mainHand = t.Player.ItemMainHand ~= 0 and Game.ItemsTxt[t.Player.Items[t.Player.ItemMainHand].Number] or nil
    local itemExtra = t.Player.ItemExtraHand ~= 0 and Game.ItemsTxt[t.Player.Items[t.Player.ItemExtraHand].Number] or nil
    local activeSkills = {}
    -- if player is in melee, both hands are relevant regardless of blaster 
    if source == "melee" then
        if mainHand ~= nil then
            table.insert(activeSkills, mainHand.Skill)
        end
        if itemExtra ~= nil then
            table.insert(activeSkills, itemExtra.Skill)
        end
    else
    -- player is not in melee, check if active is blaster or bow
        if source == "blaster" then
            table.insert(activeSkills, mainHand.Skill)
        else 
            table.insert(activeSkills, const.Skills.Bow)
        end

    end
    return activeSkills
end

function AddDamageToAttackEvent(damage) 
    local attackedType = attackEventTracker.attackedType
    local attackerIndex = attackEventTracker.attackerIndex
    local attackedIndex = attackEventTracker.attackedIndex
    attackEventTracker[attackedType][attackerIndex].targets[attackedIndex].damage = attackEventTracker[attackedType][attackerIndex].targets[attackedIndex].damage + damage
    -- for the party damage tracker 
    if attackedType == 'monsterAttacked' then
        partyDamageTracker[tonumber(attackerIndex) + 1].damage = partyDamageTracker[tonumber(attackerIndex) + 1].damage + damage
    else 
        partyDamageTracker[tonumber(attackedIndex) + 1].damage = partyDamageTracker[tonumber(attackedIndex) + 1].damage + damage
    end
end

function TryToPerformTrueDamage(t, onHitEventType, activeSkill)
    local availability = GetWeaponsEffectAvailability(t.Player, onHitEventType, weTrueDamage, activeSkill)
    local available = availability.available
    if available then
        local weapons = GetPlayerWeapons(t.Player)
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
    local available = availability.available
    if available then
        local weapons = GetPlayerWeapons(t.Player)
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
    local available = availability.available
    if available then
        local weapons = GetPlayerWeapons(t.Player)
        local activeSlot = availability.activeSlot
        local wEffect = GetWeaponEffect(onHitEventType, weGreaterCleave, weapons[activeSlot], activeSkill)
        local chance = wEffect[wefChance]
        local multiplier = wEffect[wefMultiplier]
        local skill, mastery = SplitSkill(t.Player.Skills[activeSkill])
        if CalcIfWeaponEffectProcs(skill, chance, t.Player) then
            GreaterCleave(weapons[activeSlot], t.MonsterIndex, multiplier, t.Player)
            local attackerIndex = attackEventTracker.attackerIndex
            local attackedType = attackEventTracker.attackedType
            if attackEventTracker[attackedType][attackerIndex].meta.cleaveDamage > 0 then
                AddStatusText({wEffect = wEffect, wEffectId = weGreaterCleave})
            end
        end
    end
end

function TryToPerformApplyMonsterBuffOnAllInMeleeRange(t, onHitEventType, activeSkill)
    local availability = GetWeaponsEffectAvailability(t.Player, onHitEventType, weApplyMonsterBuffOnAllInMeleeRange, activeSkill)
    local available = availability.available
    if available then
        local weapons = GetPlayerWeapons(t.Player)
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
    local available = availability.available
    if available then
        local weapons = GetPlayerWeapons(player)
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
    local available = availability.available
    if available then
        local weapons = GetPlayerWeapons(t.Player)
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
    local damage = 0
    local available = availability.available
    if available then
        local weapons = GetPlayerWeapons(t.Player)
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
    local damage = 0
    local available = availability.available
    if available then
        local weapons = GetPlayerWeapons(t.Player)
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
    -- 9 fidget, 0 standing, 1 active, 10 interacting (friendly standing infront of party).  -- HostileType ~= 0
    if t.Monster.HP == t.Monster.FullHP and 
        (t.Monster.AIState == const.AIState.Fidget or t.Monster.AIState == const.AIState.Active or 
        t.Monster.AIState == const.AIState.Interact or isMonsterAtItsOriginalPosition(t.Monster)) then
        local availability = GetWeaponsEffectAvailability(t.Player, onHitEventType, weAmbush, activeSkill)
        local weapons = GetPlayerWeapons(t.Player)
        local available = availability.available
        
        if available then
            local activeSlot = availability.activeSlot
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

function isMonsterAtItsOriginalPosition(monster)
    return monster.X == monster.StartX and monster.Y == monster.StartY and monster.Z == monster.StartZ
end

function AddStatusText(t)
    local wEffect = t.wEffect
    local wEffectId = t.wEffectId
    local power = t.power
    local attackerIndex = attackEventTracker.attackerIndex
    local attackedType = attackEventTracker.attackedType

    if next(wEffect[wefGameStatusText]) then
        if wEffect[wefGameStatusText][textPosition] == textPositionPost then
            attackEventTracker[attackedType][attackerIndex].meta.textPositionPost[wEffectId] = {
                text = wEffect[wefGameStatusText][statusText],
                power = power,
            }
        else 
            attackEventTracker[attackedType][attackerIndex].meta.textPositionPre[wEffectId] = {
                text = wEffect[wefGameStatusText][statusText],
                power = power,
            }
        end
    end
end

function GetWeaponsEffectAvailability(player, onHitEventType, weaponEffectId, activeSkill) 
    if activeSkill == nil then
        return {available = false, activeSlot = nil};
    end
    local weapons = GetPlayerWeapons(player)
    local mainSkill = weapons.main ~= nil and weapons.main.Skill or nil
    local extraSkill = weapons.extra ~= nil and weapons.extra.Skill or nil
    local missileSkill = weapons.missile ~= nil and weapons.missile.Skill or nil

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
            if extraReqs[reqsOtherHand][otherSkills.otherHand or "Unarmed"] ~= true then
                return false
            end
        end
    end
    -- all tests passed
    return true
end

function GetWeaponEffect(onHitEventType, weaponEffectId, weapon, skill)
    if (skill ~= nil and weapon ~= nil) then
        return weaponEffects[weapon.Skill][weapon.EquipStat][onHitEventType][weaponEffectId]
    else 
        return nil
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
        local weaponDmg = CalcWeaponDmg(weaponTxt, player)
        print(weaponDmg)
        damage = weaponDmg * multiplier
        print(damage)
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
            if monster.HP > 0 and monster.PhysResistance < 200 and monster.HostileType ~= 0 then
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
            local attackerIndex = attackEventTracker.attackerIndex
            local attackedType = attackEventTracker.attackedType
            attackEventTracker[attackedType][attackerIndex].meta.paralyze = attackEventTracker[attackedType][attackerIndex].meta.paralyze + 1
        elseif power == 4 then
            monster.AIState = const.AIState.Flee
        end

    end
end

---  this function seems to crash the game, try calling it directly
function WeaponDamageToMonsterOutsideAttackEvent(monster, monsterIndex, weaponTxt, multiplier, player) 
    local dmg = CalcWeaponDmg(weaponTxt, player) * multiplier
    local attackerIndex = attackEventTracker.attackerIndex
    local attackedType = attackEventTracker.attackedType
    -- Avoids Getting exp for monsters already killed
    if monster.HP > 0 and monster.HP <= dmg then
        AddKillExp(monster.Experience)
        evt.PlaySound(monster.SoundDie, monster.X, monster.Y)
        monster.AIState = const.AIState.Dying
        local killer = {
            ["Type"] = 4,
            ["Player"] = player,
        }
        -- Existing in merge, but won't throw errors if used in game without this event.
        events.cocall("MonsterKilled", monster, monsterIndex, nil, killer)
        attackEventTracker[attackedType][attackerIndex].meta.kills =  attackEventTracker[attackedType][attackerIndex].meta.kills + 1
    else
        evt.PlaySound(monster.SoundGetHit, monster.X, monster.Y)
    end
    attackEventTracker[attackedType][attackerIndex].meta.cleaveDamage = attackEventTracker[attackedType][attackerIndex].meta.cleaveDamage + dmg
    
    -- for the party damage tracker 
    if attackedType == 'monsterAttacked' then
        partyDamageTracker[tonumber(attackerIndex) + 1].damage = partyDamageTracker[tonumber(attackerIndex) + 1].damage + dmg
    else 
        local attackedIndex = attackEventTracker.attackedIndex
        partyDamageTracker[tonumber(attackedIndex) + 1].damage = partyDamageTracker[tonumber(attackedIndex) + 1].damage + dmg
    end

    monster.HP = monster.HP - dmg
end

function CalcIfWeaponEffectProcs(skill, chance, player) 
    math.randomseed(os.time())
    -- First draft was: skill * chance + Game.GetStatisticEffect(player:GetLuck()) 
    -- however this made it impossible to create effects with a guaranteed low chance off success
    if chance < 1 then
        local result = math.random(99) < (skill + Game.GetStatisticEffect(player:GetLuck()) * chance)
        return result
    else 
        return math.random(99) < (skill * chance + Game.GetStatisticEffect(player:GetLuck()))
    end
end

-- multiplier can be a decimal or whole number 
function CalcCritDmg(itemTxt, multiplier, player) 
    return math.floor(CalcWeaponDmg(itemTxt, player) * multiplier)
end

function CalcUnarmedDmg(player) 
    local strengthMod = Game.GetStatisticEffect(player:GetMight())
    return strengthMod
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
    mem.call(mmv(0x421520, 0x42694B, 0x424D5B),2, exp)
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
