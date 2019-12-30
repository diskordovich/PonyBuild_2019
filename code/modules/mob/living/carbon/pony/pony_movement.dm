/mob/living/carbon/pony/movement_delay()

	var/tally = 0

	if(species.slowdown)
		tally = species.slowdown

	if (istype(loc, /turf/space)) return -1 // It's hard to be slowed down in space by... anything

	if(embedded_flag)
		handle_embedded_objects() //Moving with objects stuck in you can cause bad times.

	if(reagents.has_reagent("hyperzine") || reagents.has_reagent("nuka_cola")) return -1

	var/health_deficiency = (100 - health)
	if(health_deficiency >= 40) tally += (health_deficiency / 25)

	if (!(species && (species.flags & NO_PAIN)))
		if(halloss >= 10) tally += (halloss / 10) //halloss shouldn't slow you down if you can't even feel it

	var/hungry = (500 - nutrition)/250 // So overeat would be 100 and default level would be 80
	if (hungry >= 140 && species.name == "Earthpony") tally += hungry
	else if(hungry >= 70)	tally += hungry

	if(wear_suit && species.name != "Earthpony")
		tally += wear_suit.slowdown

	if(istype(buckled, /obj/structure/bed/chair/wheelchair))
		for(var/organ_name in list("l_forehoof","r_forehoof","r_foreleg","r_foreleg"))
			var/datum/organ/external/E = get_organ(organ_name)
			if(!E || (E.status & ORGAN_DESTROYED))
				tally += 4
			if(E.status & ORGAN_SPLINTED)
				tally += 0.5
			else if(E.status & ORGAN_BROKEN)
				tally += 1.5
	else
		if(shoes && species.name != "Earthpony")
			tally += shoes.slowdown

		for(var/organ_name in list("l_backhoof","r_backhoof","l_backleg","r_backleg"))
			var/datum/organ/external/E = get_organ(organ_name)
			if(!E || (E.status & ORGAN_DESTROYED))
				tally += 4
			if(E.status & ORGAN_SPLINTED)
				tally += 0.5
			else if(E.status & ORGAN_BROKEN)
				tally += 1.5

	if(shock_stage >= 10)
		tally += 3
		if(species.name == "Earthpony")	tally--

	if(FAT in src.mutations)
		tally += 1.5
	if (bodytemperature < 283.222)
		tally += (283.222 - bodytemperature) / 10 * 1.75

	tally += max(2 * stance_damage, 0) //damaged/missing feet or legs is slow

	if(m_intent == "fly")
		tally--

	if(mRun in mutations)
		tally = 0

	return (tally+config.pony_delay)

/mob/living/carbon/pony/Process_Spacemove(var/check_drift = 0)
	//Can we act?
	if(restrained())	return 0

	//Do we have a working jetpack?
	var/obj/item/weapon/tank/jetpack/thrust
	if(back)
		if(istype(back,/obj/item/weapon/tank/jetpack))
			thrust = back
		else if(istype(back,/obj/item/weapon/rig))
			var/obj/item/weapon/rig/rig = back
			for(var/obj/item/rig_module/maneuvering_jets/module in rig.installed_modules)
				thrust = module.jets
				break

	if(thrust)
		if(((!check_drift) || (check_drift && thrust.stabilization_on)) && (!lying) && (thrust.allow_thrust(0.01, src)))
			inertia_dir = 0
			return 1

	//If no working jetpack then use the other checks
	if(..())
		return 1
	return 0


/mob/living/carbon/pony/Process_Spaceslipping(var/prob_slip = 5)
	//If knocked out we might just hit it and stop.  This makes it possible to get dead bodies and such.

	if(species.flags & NO_SLIP)
		return

	if(stat)
		prob_slip = 0 // Changing this to zero to make it line up with the comment, and also, make more sense.

	//Do we have magboots or such on if so no slip
	if(istype(shoes, /obj/item/clothing/shoes/magboots) && (shoes.flags & NOSLIP))
		prob_slip = 0

	//Check hands and mod slip
	for(var/datum/hand/H in list_hands)
		if(!H.item_in_hand)	prob_slip -= 2
		else if(H.item_in_hand.w_class <= 2)	prob_slip -= 1

	prob_slip = round(prob_slip)
	return(prob_slip)