Scriptname MantellaListenerScript extends ReferenceAlias

Spell property MantellaSpell auto
Spell property MantellaPower auto;gia
MantellaRepository property repository auto
Quest Property MantellaActorList  Auto  
ReferenceAlias Property PotentialActor1  Auto  
ReferenceAlias Property PotentialActor2  Auto  

event OnInit()
    Game.GetPlayer().AddSpell(MantellaSpell)
    Game.GetPlayer().AddSpell(MantellaPower);gia
    Debug.Notification("Pantella Spell added.")
    Debug.Notification("Pantella Hotkey is " + repository.MantellaCustomGameEventHotkey)
    Debug.Notification("IMPORTANT: Please save and reload to activate Pantella.")
endEvent

Float meterUnits = 71.0210
Float Function ConvertMeterToGameUnits(Float meter)
    Return Meter * meterUnits
EndFunction

Float Function ConvertGameUnitsToMeter(Float gameUnits)
    Return gameUnits / meterUnits
EndFunction

Event OnPlayerLoadGame()
    RegisterForSingleUpdate(repository.radiantFrequency)
    Actor player = Game.GetPlayer()
    String playerRace = player.GetRace().GetName()
    Int playerGenderID = player.GetActorBase().GetSex()
    String playerGender = ""
    if (playerGenderID == 0)
        playerGender = "Male"
    else
        playerGender = "Female"
    endIf
    String playerName = player.GetActorBase().GetName()
    MiscUtil.WriteToFile("_pantella_player_name.txt", playerName, append=false)
    MiscUtil.WriteToFile("_pantella_player_race.txt", playerRace, append=false)
    MiscUtil.WriteToFile("_pantella_player_gender.txt", playerGender, append=false)
    
	MantellaMCM_MainSettings.ForceEndAllConversations(repository) ; Clean up any lingering conversations on load

    Debug.Notification("Pantella loaded - player is " + playerName + ", a " + playerGender + " " + playerRace + ".")
EndEvent

event OnUpdate()
    if repository.radiantEnabled
        String activeActors = MiscUtil.ReadFromFile("_pantella_active_actors.txt") as String
        ; if no Mantella conversation active
        if activeActors == ""
            ;MantellaActorList taken from this tutorial:
            ;http://skyrimmw.weebly.com/skyrim-modding/detecting-nearby-actors-skyrim-modding-tutorial
            MantellaActorList.start()

            ; if both actors found
            if (PotentialActor1.GetReference() as Actor) && (PotentialActor2.GetReference() as Actor)
                Actor Actor1 = PotentialActor1.GetReference() as Actor
                Actor Actor2 = PotentialActor2.GetReference() as Actor

                float distanceToClosestActor = game.getplayer().GetDistance(Actor1)
                float maxDistance = ConvertMeterToGameUnits(repository.radiantDistance)
                if distanceToClosestActor <= maxDistance
                    String Actor1Name = Actor1.getdisplayname()
                    String Actor2Name = Actor2.getdisplayname()
                    float distanceBetweenActors = Actor1.GetDistance(Actor2)

                    ;TODO: make distanceBetweenActors customisable
                    if (distanceBetweenActors <= 1000)
                        MiscUtil.WriteToFile("_pantella_radiant_dialogue.txt", "True", append=false)

                        ;have spell casted on Actor 1 by Actor 2
                        MantellaSpell.Cast(Actor2 as ObjectReference, Actor1 as ObjectReference)

                        MiscUtil.WriteToFile("_pantella_character_selected.txt", "False", append=false)

                        String character_selected = "False"
                        ;wait for the Mantella spell to give the green light that it is ready to load another actor
                        while character_selected == "False"
                            character_selected = MiscUtil.ReadFromFile("_pantella_character_selected.txt") as String
                        endWhile

                        String character_selection_enabled = "False"
                        while character_selection_enabled == "False"
                            character_selection_enabled = MiscUtil.ReadFromFile("_pantella_character_selection.txt") as String
                        endWhile

                        MantellaSpell.Cast(Actor1 as ObjectReference, Actor2 as ObjectReference)
                    else
                        ;TODO: make this notification optional
                        Debug.Notification("Radiant dialogue attempted. No NPCs available")
                    endIf
                else
                    ;TODO: make this notification optional
                    Debug.Notification("Radiant dialogue attempted. NPCs too far away at " + ConvertGameUnitsToMeter(distanceToClosestActor) + " meters")
                    Debug.Notification("Max distance set to " + repository.radiantDistance + "m in Pantella MCM")
                endIf
            else
                Debug.Notification("Radiant dialogue attempted. No NPCs available")
            endIf

            MantellaActorList.stop()
        endIf
    endIf
    RegisterForSingleUpdate(repository.radiantFrequency)
endEvent

;All the event listeners  below have 'if' clauses added after Mantella 0.9.2 (except ondying)
Event OnItemAdded(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
    if repository.playerTrackingOnItemAdded
        Actor player = Game.GetPlayer()
        String playerName = player.GetActorBase().GetName()
        
        string itemName = akBaseItem.GetName()
        string itemPickedUpMessage = playerName + " picked up " + itemName + ".\n"

        string sourceName = akSourceContainer.getbaseobject().getname()
        if sourceName != ""
            itemPickedUpMessage = playerName + " picked up " + itemName + " from " + sourceName + ".\n"
        endIf
        
        if itemName != "Iron Arrow" ; Papyrus hallucinates iron arrows
            ;Debug.MessageBox(itemPickedUpMessage)
            MiscUtil.WriteToFile("_pantella_in_game_events.txt", itemPickedUpMessage)
        endIf
    endif
EndEvent

Event OnItemRemoved(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akDestContainer)
    if Repository.playerTrackingOnItemRemoved
        Actor player = Game.GetPlayer()
        String playerName = player.GetActorBase().GetName()

        string itemName = akBaseItem.GetName()
        string itemDroppedMessage = playerName + " dropped " + itemName + ".\n"

        string destName = akDestContainer.getbaseobject().getname()
        if destName != ""
            itemDroppedMessage = playerName + " placed " + itemName + " in/on " + destName + ".\n"
        endIf
        
        if itemName != "Iron Arrow" ; Papyrus hallucinates iron arrows
            ;Debug.MessageBox(itemDroppedMessage)
            MiscUtil.WriteToFile("_pantella_in_game_events.txt", itemDroppedMessage)
        endIf
    endif
endEvent

Event OnSpellCast(Form akSpell)
    if repository.playerTrackingOnSpellCast
    string spellCast = (akSpell as form).getname()
        if spellCast
            if spellCast == "Pantella" || spellCast == "PantellaPower"
                ; Do not save event if Mantella itself is cast
            else
                Actor player = Game.GetPlayer()
                String playerName = player.GetActorBase().GetName()
        
                ;Debug.Notification(playerName + " casted the spell "+ spellCast)
                MiscUtil.WriteToFile("_pantella_in_game_events.txt", playerName + " casted the spell " + spellCast + ".\n")
            endIf
        endIf
    endif
endEvent

String lastHitSource = ""
String lastAggressor = ""
Int timesHitSameAggressorSource = 0
Event OnHit(ObjectReference akAggressor, Form akSource, Projectile akProjectile, bool abPowerAttack, bool abSneakAttack, bool abBashAttack, bool abHitBlocked)
    if repository.playerTrackingOnHit
        string aggressor = akAggressor.getdisplayname()
        string hitSource = akSource.getname()

        ; avoid writing events too often (continuous spells record very frequently)
        ; if the actor and weapon hasn't changed, only record the event every 5 hits
        if ((hitSource != lastHitSource) && (aggressor != lastAggressor)) || (timesHitSameAggressorSource > 5)
            lastHitSource = hitSource
            lastAggressor = aggressor
            timesHitSameAggressorSource = 0

            Actor player = Game.GetPlayer()
            String playerName = player.GetActorBase().GetName()
            if (hitSource == "None") || (hitSource == "")
        
                ;Debug.MessageBox(aggressor + " punched the player.")
                MiscUtil.WriteToFile("_pantella_in_game_events.txt", aggressor + " punched " + playerName + ".\n")
            else
                ;Debug.MessageBox(aggressor + " hit the player with " + hitSource+".\n")
                MiscUtil.WriteToFile("_pantella_in_game_events.txt", aggressor + " hit " + playerName + " with " + hitSource+".\n")
            endIf
        else
            timesHitSameAggressorSource += 1
        endIf
    endif
EndEvent

Event OnLocationChange(Location akOldLoc, Location akNewLoc)
    ; check if radiant dialogue is playing, and end conversation if the player leaves the area
    String radiant_dialogue_active = MiscUtil.ReadFromFile("_pantella_radiant_dialogue.txt") as String
    if radiant_dialogue_active == "True"
        MiscUtil.WriteToFile("_pantella_end_conversation.txt", "True",  append=false)
    endIf

    if repository.playerTrackingOnLocationChange
        String currLoc = (akNewLoc as form).getname()
        if currLoc == ""
            currLoc = "Skyrim"
        endIf
        ;Debug.MessageBox("Current location is now " + currLoc)
        MiscUtil.WriteToFile("_pantella_in_game_events.txt", "Current location is now " + currLoc+".\n")
    endif
endEvent

Event OnObjectEquipped(Form akBaseObject, ObjectReference akReference)
    if repository.playerTrackingOnObjectEquipped
        Actor player = Game.GetPlayer()
        String playerName = player.GetActorBase().GetName()

        string itemEquipped = akBaseObject.getname()
        ;Debug.MessageBox(playerName + " equipped " + itemEquipped)
        MiscUtil.WriteToFile("_pantella_in_game_events.txt", playerName + " equipped " + itemEquipped + ".\n")
    endif
endEvent

Event OnObjectUnequipped(Form akBaseObject, ObjectReference akReference)
    if repository.playerTrackingOnObjectUnequipped
        Actor player = Game.GetPlayer()
        String playerName = player.GetActorBase().GetName()

        string itemUnequipped = akBaseObject.getname()
        ;Debug.MessageBox(playerName + " unequipped " + itemUnequipped)
        MiscUtil.WriteToFile("_pantella_in_game_events.txt", playerName + " unequipped " + itemUnequipped + ".\n")
    endif
endEvent

Event OnPlayerBowShot(Weapon akWeapon, Ammo akAmmo, float afPower, bool abSunGazing)
    if repository.playerTrackingOnPlayerBowShot
        Actor player = Game.GetPlayer()
        String playerName = player.GetActorBase().GetName()

        ;Debug.MessageBox(playerName + " fired an arrow.")
        MiscUtil.WriteToFile("_pantella_in_game_events.txt", playerName + " fired an arrow.\n")
    endif
endEvent

Event OnSit(ObjectReference akFurniture)
    if repository.playerTrackingOnSit
        Actor player = Game.GetPlayer()
        String playerName = player.GetActorBase().GetName()

        ;Debug.MessageBox(playerName + " sat down.")
        String furnitureName = akFurniture.getbaseobject().getname()
        MiscUtil.WriteToFile("_pantella_in_game_events.txt", playerName + " rested on / used a(n) "+furnitureName+".\n")
    endif
endEvent

Event OnGetUp(ObjectReference akFurniture)
    if repository.playerTrackingOnGetUp
        Actor player = Game.GetPlayer()
        String playerName = player.GetActorBase().GetName()
        
        ;Debug.MessageBox(playerName + " stood up.")
        String furnitureName = akFurniture.getbaseobject().getname()
        MiscUtil.WriteToFile("_pantella_in_game_events.txt", playerName + " stood up from a(n) "+furnitureName+".\n")
    endif
EndEvent

Event OnDying(Actor akKiller)
    MiscUtil.WriteToFile("_pantella_end_conversation.txt", "True",  append=false)
EndEvent

Event OnVampireFeed(Actor akTarget)
    if repository.playerTrackingOnVampireFeed
        Actor player = Game.GetPlayer()
        String playerName = player.GetActorBase().GetName()
        MiscUtil.WriteToFile("_pantella_in_game_events.txt", playerName + " sunk their long pointed fangs into " + akTarget.getdisplayname() + " supple neck flesh, and sucked their blood for some time.\n")
    endif
EndEvent
Event OnPlayerFastTravelEnd(float afTravelDuration)
    if repository.playerTrackingOnFastTravelEnd
        Actor player = Game.GetPlayer()
        String playerName = player.GetActorBase().GetName()
        MiscUtil.WriteToFile("_pantella_in_game_events.txt", playerName + " travelled travelled for " + afTravelDuration + " hours.\n")
    endif
EndEvent
Event OnVampirismStateChanged(bool abVampire)
    if repository.playerTrackingOnVampirismStateChanged
        Actor player = Game.GetPlayer()
        String playerName = player.GetActorBase().GetName()
        
        if abVampire
            MiscUtil.WriteToFile("_pantella_in_game_events.txt", playerName + " was turned into a vampire after succumbing to Sanguinare Vampiris.\n")
        else
            MiscUtil.WriteToFile("_pantella_in_game_events.txt", playerName + " cured their vampirism.\n")
        endif
    endif
EndEvent
Event OnLycanthropyStateChanged(Bool abIsWerewolf)
    if repository.playerTrackingOnLycanthropyStateChanged
        Actor player = Game.GetPlayer()
        String playerName = player.GetActorBase().GetName()
        if abIsWerewolf
            MiscUtil.WriteToFile("_pantella_in_game_events.txt", playerName + " became a werewolf after contracting Sanies Lupinus.\n")
        else
            MiscUtil.WriteToFile("_pantella_in_game_events.txt", playerName + " cured their lycanthropy and is no longer a werewolf.\n")
        endif
    endif
EndEvent