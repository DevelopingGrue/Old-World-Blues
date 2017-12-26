


/datum/power/changeling/recursive_enhancement
	name = "Recursive Enhancement"
	desc = "We cause our abilities to have increased or additional effects."
	helptext = "To check the effects for each ability, check the blue text underneath the ability in the evolution menu."
//	ability_icon_state = "ling_recursive_enhancement"
	genomecost = 3
	verbpath = /mob/proc/changeling_recursive_enhancement

//Increases macimum chemical storage
/mob/proc/changeling_recursive_enhancement()
	set category = "Changeling"
	set name = "Recursive Enhancement"
	set desc = "Empowers our abilities."
	var/datum/changeling/changeling = changeling_power(0,0,100,UNCONSCIOUS)
	if(!changeling)
		return 0
	if(src.mind.changeling.recursive_enhancement)
		to_chat(src, "<span class='warning'>We will no longer empower our abilities.</span>")
		src.mind.changeling.recursive_enhancement = 0
		return 0
		to_chat(src, "<span class='notice'>We empower ourselves. Our abilities will now be extra potent.</span>")
	src.mind.changeling.recursive_enhancement = 1
//	feedback_add_details("changeling_powers","RE")
	return 1


/datum/power/changeling/electric_lockpick
	name = "Electric Lockpick"
	desc = "We discreetly evolve a finger to be able to send a small electric charge.  \
	We can open most electrical locks, but it will be obvious when we do so."
	helptext = "Use the ability, then touch something that utilizes an electrical locking system, to open it.  Each use costs 10 chemicals."
//	ability_icon_state = "ling_electric_lockpick"
	genomecost = 6
	verbpath = /mob/proc/changeling_electric_lockpick

//Emag-lite
/mob/proc/changeling_electric_lockpick()
	set category = "Changeling"
	set name = "Electric Lockpick (5 + 10/use)"
	set desc = "Bruteforces open most electrical locking systems, at 10 chemicals per use."

	var/datum/changeling/changeling = changeling_power(5,0,100,CONSCIOUS)

	var/obj/held_item = get_active_hand()

	if(!changeling)
		return 0

	if(held_item == null)
		if(changeling_generic_weapon(/obj/item/weapon/finger_lockpick,0,5))  //Chemical cost is handled in the equip proc.
			return 1
		return 0

/obj/item/weapon/finger_lockpick
	name = "finger lockpick"
	desc = "This finger appears to be an organic datajack."
	icon = 'icons/obj/weapons.dmi'
	icon_state = "electric_hand"

/obj/item/weapon/finger_lockpick/New()
	if(ismob(loc))
		loc << "<span class='notice'>We shape our finger to fit inside electronics, and are ready to force them open.</span>"

/obj/item/weapon/finger_lockpick/dropped(mob/user)
	to_chat(user, "<span class='notice'>We discreetly shape our finger back to a less suspicious form.</span>")
	spawn(1)
		if(src)
			qdel(src)

/obj/item/weapon/finger_lockpick/afterattack(var/atom/target, var/mob/living/user, proximity)
	if(!target)
		return
	if(!proximity)
		return
	if(!user.mind.changeling)
		return

	var/datum/changeling/ling_datum = user.mind.changeling

	if(ling_datum.chem_charges < 10)
		to_chat(user, "<span class='warning'>We require more chemicals to do that.</span>")
		return

	//Airlocks require an ugly block of code, but we don't want to just call emag_act(), since we don't want to break airlocks forever.
	if(istype(target,/obj/machinery/door))
		var/obj/machinery/door/door = target
		to_chat(user, "<span class='notice'>We send an electrical pulse up our finger, and into \the [target], attempting to open it.</span>")

		if(door.density && door.operable())
			door.do_animate("spark")
			sleep(6)
			//More typechecks, because windoors can't be locked.  Fun.
			if(istype(target,/obj/machinery/door/airlock))
				var/obj/machinery/door/airlock/airlock = target

				if(airlock.locked) //Check if we're bolted.
					airlock.unlock()
					to_chat(user, "<span class='notice'>We've unlocked \the [airlock].  Another pulse is requried to open it.</span>")
				else	//We're not bolted, so open the door already.
					airlock.open()
					to_chat(user, "<span class='notice'>We've opened \the [airlock].</span>")
			else
				door.open() //If we're a windoor, open the windoor.
				to_chat(user, "<span class='notice'>We've opened \the [door].</span>")
		else //Probably broken or no power.
			to_chat(user, "<span class='warning'>The door does not respond to the pulse.</span>")
		door.add_fingerprint(user)
		log_and_message_admins("finger-lockpicked \an [door].")
		ling_datum.chem_charges -= 10
		return 1

	else if(istype(target,/obj/)) //This should catch everything else we might miss, without a million typechecks.
		var/obj/O = target
		to_chat(user, "<span class='notice'>We send an electrical pulse up our finger, and into \the [O].</span>")
		O.add_fingerprint(user)
		O.emag_act(1,user,src)
		log_and_message_admins("finger-lockpicked \an [O].")
		ling_datum.chem_charges -= 10

		return 1
	return 0



/datum/power/changeling/visible_camouflage
	name = "Camouflage"
	desc = "We rapidly shape the color of our skin and secrete easily reversible dye on our clothes, to blend in with our surroundings.  \
	We are undetectable, so long as we move slowly.(Toggle)"
	helptext = "Running, and performing most acts will reveal us.  Our chemical regeneration is halted while we are hidden."
	enhancedtext = "Can run while hidden."
//	ability_icon_state = "ling_camoflage"
	genomecost = 5
	verbpath = /mob/proc/changeling_visible_camouflage

//Hide us from anyone who would do us harm.
/mob/proc/changeling_visible_camouflage()
	set category = "Changeling"
	set name = "Visible Camouflage (10)"
	set desc = "Turns yourself almost invisible, as long as you move slowly."


	if(istype(src,/mob/living/carbon/human))
		var/mob/living/carbon/human/H = src

		if(H.mind.changeling.cloaked)
			H.mind.changeling.cloaked = 0
			return 1

		//We delay the check, so that people can uncloak without needing 10 chemicals to do so.
		var/datum/changeling/changeling = changeling_power(10,0,100,CONSCIOUS)

		if(!changeling)
			return 0
		changeling.chem_charges -= 10
		var/old_regen_rate = H.mind.changeling.chem_recharge_rate

		H << "<span class='notice'>We vanish from sight, and will remain hidden, so long as we move carefully.</span>"
		H.mind.changeling.cloaked = 1
		H.mind.changeling.chem_recharge_rate = 0
		animate(src,alpha = 255, alpha = 10, time = 10)

		var/must_walk = TRUE
		if(src.mind.changeling.recursive_enhancement)
			must_walk = FALSE
			src << "<span class='notice'>We may move at our normal speed while hidden.</span>"

		if(must_walk)
			H.set_m_intent("walk")

		var/remain_cloaked = TRUE
		while(remain_cloaked) //This loop will keep going until the player uncloaks.
			sleep(1 SECOND) // Sleep at the start so that if something invalidates a cloak, it will drop immediately after the check and not in one second.

			if(H.m_intent != "walk" && must_walk) // Moving too fast uncloaks you.
				remain_cloaked = 0
			if(!H.mind.changeling.cloaked)
				remain_cloaked = 0
			if(H.stat) // Dead or unconscious lings can't stay cloaked.
				remain_cloaked = 0
			if(H.stat||H.paralysis||H.stunned) // Stunned lings also can't stay cloaked.
				remain_cloaked = 0

			if(mind.changeling.chem_recharge_rate != 0) //Without this, there is an exploit that can be done, if one buys engorged chem sacks while cloaked.
				old_regen_rate += mind.changeling.chem_recharge_rate //Unfortunately, it has to occupy this part of the proc.  This fixes it while at the same time
				mind.changeling.chem_recharge_rate = 0 //making sure nobody loses out on their bonus regeneration after they're done hiding.



		H.invisibility = initial(invisibility)
		visible_message("<span class='warning'>[src] suddenly fades in, seemingly from nowhere!</span>",
		"<span class='notice'>We revert our camouflage, revealing ourselves.</span>")
		H.set_m_intent("run")
		H.mind.changeling.cloaked = 0
		H.mind.changeling.chem_recharge_rate = old_regen_rate

		animate(src,alpha = 10, alpha = 255, time = 10)
