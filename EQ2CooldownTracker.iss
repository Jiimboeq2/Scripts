variable string PATH_UI = "${LavishScript.HomeDirectory}/Scripts/${Script.Filename}/UI"
variable EQ2CooldownTracker EQ2CooldownTracker
variable collection:string ClassNames
variable collection:string ClassColours

function main()
{
	if !${ISXEQ2(exists)}
	{
        ui -load -skin EQ2-Green "${PATH_UI}/${Script.Filename}.xml"
		echo "\ayISXEQ2 has not been loaded!  EQ2CooldownTracker can not run without it.  Good Bye!\ax"
		return
	}
	elseif !${ISXEQ2.IsReady}
	{
		echo "\ayISXEQ2 is not yet ready -- you must wait until the authentication and patching sequences have completed before running EQ2CooldownTracker.\ax"
		return
	}
	elseif (${EQ2.Zoning} != 0)
	{
		echo "\ayYou cannot start EQ2CooldownTracker while zoning.  Wait until you have finished zoning, and then try again.\ax"
		return
	}

    EQ2CooldownTracker:Init_UI
    EQ2CooldownTracker:SetClassColours
    EQ2CooldownTracker:Init_Events

    do
	{
	}
	while TRUE
}

objectdef EQ2CooldownTracker
{
    method SetClassColours()
    {
        ClassColours:Set["mystic","9cfe39"]
        ClassColours:Set["warden","9cfe39"]
        ClassColours:Set["templar","9cfe39"]
        ClassColours:Set["inquisitor","9cfe39"]
        ClassColours:Set["fury","9cfe39"]
        ClassColours:Set["defiler","9cfe39"]
        ClassColours:Set["conjuror","37FDFC"]
        ClassColours:Set["necromancer","37FDFC"]
        ClassColours:Set["wizard","37FDFC"]
        ClassColours:Set["warlock","37FDFC"]
        ClassColours:Set["illusionist","37FDFC"]
        ClassColours:Set["coercer","37FDFC"]
        ClassColours:Set["swashbuckler","fefe39"]
        ClassColours:Set["brigand","fefe39"]
        ClassColours:Set["troubador","fefe39"]
        ClassColours:Set["dirge","fefe39"]
        ClassColours:Set["ranger","fefe39"]
        ClassColours:Set["assassin","fefe39"]
        ClassColours:Set["guardian","FF0000"]
        ClassColours:Set["berserker","FF0000"]
        ClassColours:Set["monk","FF0000"]
        ClassColours:Set["bruiser","FF0000"]
        ClassColours:Set["shadowknight","FF0000"]
        ClassColours:Set["paladin","FF0000"]
    }

    member:string GetClassFromName(string ToonName)
    {
        return ${Actor[Query,Name=="${ToonName}" && Race != "NPC"].Class}
    }

    method Init_Events()
    {
        Event[OgreEvent_OnAbilityReadyTimersUpdate]:AttachAtom[This:OgreEvent_OnAbilityReadyTimersUpdate]
        Event[EQ2_onGroupMembershipChange]:AttachAtom[This:ISXEvent_OnGroupOrRaidMembershipChange]
        Event[EQ2_onRaidMembershipChange]:AttachAtom[This:ISXEvent_OnGroupOrRaidMembershipChange]
    }

	method Init_UI()
	{
        ui -reload -skin EQ2-Green "${PATH_UI}/${Script.Filename}.xml"
		ui -reload "${LavishScript.HomeDirectory}/Interface/Skins/EQ2-Green/EQ2-Green.xml"
	}

    method OgreEvent_OnAbilityReadyTimersUpdate(string _Toon, int64 _AbilityID=0, string _AbilityName="", float _TimeUntilReady=0)
    {   
        if (${_TimeUntilReady} > 0)
        {
            variable string _ListItemText

            if !${ClassNames.Get[${_Toon}](exists)}
            {
                ClassNames:Set["${_Toon}","${This.GetClassFromName["${_Toon}"]}"]
            }

            call This.FormatCooldownListItem "${_Toon}" "${_AbilityName}" ${_TimeUntilReady}
            _ListItemText:Set["${Return}"]

            if (${UIElement[EQ2CooldownTracker].FindUsableChild[lstboxCDlist,listbox].ItemByValue["${_Toon}-${_AbilityID}"].ID(exists)})
            {
                ; Item already in the list, just edit the text.
                UIElement[EQ2CooldownTracker].FindUsableChild[lstboxCDlist,listbox].Item[${UIElement[EQ2CooldownTracker].FindUsableChild[lstboxCDlist,listbox].ItemByValue["${_Toon}-${_AbilityID}"].ID}]:SetText["${_ListItemText}"]

                UIElement[EQ2CooldownTracker].FindUsableChild[lstboxCDlist,listbox].Item[${UIElement[EQ2CooldownTracker].FindUsableChild[lstboxCDlist,listbox].ItemByValue["${_Toon}-${_AbilityID}"].ID}]:SetTextColor["FF${ClassColours.Get[${ClassNames.Get[${_Toon}]}]}"]
            }
            else
            {
                ; Item is new, add it.
                UIElement[EQ2CooldownTracker].FindUsableChild[lstboxCDlist,listbox]:AddItem["${_ListItemText}", "${_Toon}-${_AbilityID}"] 
            }
        }
        else
        {
            ; Cooldown is over, remove it from the list
            UIElement[EQ2CooldownTracker].FindUsableChild[lstboxCDlist,listbox]:RemoveItem[${UIElement[EQ2CooldownTracker].FindUsableChild[lstboxCDlist,listbox].ItemByValue["${_Toon}-${_AbilityID}"].ID}]
        }
    }

    method ISXEvent_OnGroupOrRaidMembershipChange(int _OldCount, int _NewCount)
    {
        ; Group or Raid changed, clearing list as it may contain abilities no longer in the group
        UIElement[EQ2CooldownTracker].FindUsableChild[lstboxCDlist,listbox]:ClearItems
    }

    function:string FormatCooldownListItem(string _Toon, string _AbilityName, float _TimeUntilReady)
    {
        variable string _FormattedToonName="${_Toon.Left[10]}"
        variable string _FormattedAbilityName="${_AbilityName.Left[15]}"

        while ${_FormattedToonName.Length} < 10
        {
            _FormattedToonName:Concat[" "]
        }

        while ${_FormattedAbilityName.Length} < 21
        {
            _FormattedAbilityName:Concat[" "]
        }

        return "${_FormattedToonName} ${_FormattedAbilityName} [${_TimeUntilReady.Ceil}s]"
    }
}

function atexit()
{
    ui -unload "${PATH_UI}/${Script.Filename}.xml"

    Event[OgreEvent_OnAbilityReadyTimersUpdate]:DetachAtom[EQ2CooldownTracker:OgreEvent_OnAbilityReadyTimersUpdate]
    Event[EQ2_onGroupMembershipChange]:DetachAtom[EQ2CooldownTracker:ISXEvent_OnGroupOrRaidMembershipChange]
    Event[EQ2_onRaidMembershipChange]:DetachAtom[EQ2CooldownTracker:ISXEvent_OnGroupOrRaidMembershipChange]
}