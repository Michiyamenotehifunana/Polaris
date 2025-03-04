//Food items that are eaten normally and don't leave anything behind.
/obj/item/weapon/reagent_containers/food/snacks
	name = "snack"
	desc = "yummy"
	icon = 'icons/obj/food.dmi'
	icon_state = null
	var/bitesize = 1
	var/bitecount = 0
	var/trash = null
	var/slice_path
	var/slices_num
	var/dried_type = null
	var/dry = 0
	var/survivalfood = FALSE
	var/nutriment_amt = 0
	var/list/nutriment_desc = list("food" = 1)
	center_of_mass = list("x"=16, "y"=16)
	w_class = ITEMSIZE_SMALL
	force = 0

/obj/item/weapon/reagent_containers/food/snacks/Initialize()
	. = ..()
	if(nutriment_amt)
		reagents.add_reagent("nutriment",nutriment_amt,nutriment_desc)

/obj/item/weapon/reagent_containers/food/snacks/Initialize()
	. = ..()
	if(nutriment_amt)
		reagents.add_reagent("nutriment", nutriment_amt)

	//Placeholder for effect that trigger on eating that aren't tied to reagents.
/obj/item/weapon/reagent_containers/food/snacks/proc/On_Consume(var/mob/M)
	if(!usr)
		usr = M
	if(!reagents.total_volume)
		M.visible_message("<span class='notice'>[M] finishes eating \the [src].</span>","<span class='notice'>You finish eating \the [src].</span>")
		usr.drop_from_inventory(src)	//so icons update :[

		if(trash)
			if(ispath(trash,/obj/item))
				var/obj/item/TrashItem = new trash(usr)
				usr.put_in_hands(TrashItem)
			else if(istype(trash,/obj/item))
				usr.put_in_hands(trash)
		qdel(src)
	return

/obj/item/weapon/reagent_containers/food/snacks/attack_self(mob/user as mob)
	return

/obj/item/weapon/reagent_containers/food/snacks/attack(mob/M as mob, mob/user as mob, def_zone)
	if(reagents && !reagents.total_volume)
		to_chat(user, "<span class='danger'>None of [src] left!</span>")
		user.drop_from_inventory(src)
		qdel(src)
		return 0

	if(istype(M, /mob/living/carbon))
		//TODO: replace with standard_feed_mob() call.

		var/fullness = M.nutrition + (M.reagents.get_reagent_amount("nutriment") * 25)
		if(M == user)								//If you're eating it yourself
			if(istype(M,/mob/living/carbon/human))
				var/mob/living/carbon/human/H = M
				if(!H.check_has_mouth())
					to_chat(user, "Where do you intend to put \the [src]? You don't have a mouth!")
					return
				var/obj/item/blocked = null
				if(survivalfood)
					blocked = H.check_mouth_coverage_survival()
				else
					blocked = H.check_mouth_coverage()
				if(blocked)
					to_chat(user, "<span class='warning'>\The [blocked] is in the way!</span>")
					return

			user.setClickCooldown(user.get_attack_speed(src)) //puts a limit on how fast people can eat/drink things
			if (fullness <= 50)
				to_chat(M, "<span class='danger'>You hungrily chew out a piece of [src] and gobble it!</span>")
			if (fullness > 50 && fullness <= 150)
				to_chat(M, "<span class='notice'>You hungrily begin to eat [src].</span>")
			if (fullness > 150 && fullness <= 350)
				to_chat(M, "<span class='notice'>You take a bite of [src].</span>")
			if (fullness > 350 && fullness <= 550)
				to_chat(M, "<span class='notice'>You unwillingly chew a bit of [src].</span>")
			if (fullness > (550 * (1 + M.overeatduration / 2000)))	// The more you eat - the more you can eat
				to_chat(M, "<span class='danger'>You cannot force any more of [src] to go down your throat.</span>")
				return 0

		else if(user.a_intent == I_HURT)
			return ..()

		else
			if(istype(M,/mob/living/carbon/human))
				var/mob/living/carbon/human/H = M
				if(!H.check_has_mouth())
					to_chat(user, "Where do you intend to put \the [src]? \The [H] doesn't have a mouth!")
					return
				var/obj/item/blocked = null
				var/unconcious = FALSE
				blocked = H.check_mouth_coverage()
				if(survivalfood)
					blocked = H.check_mouth_coverage_survival()
					if(H.stat && H.check_mouth_coverage())
						unconcious = TRUE
						blocked = H.check_mouth_coverage()

				if(unconcious)
					to_chat(user, "<span class='warning'>You can't feed [H] through \the [blocked] while they are unconcious!</span>")
					return

				if(blocked)
					to_chat(user, "<span class='warning'>\The [blocked] is in the way!</span>")
					return

				if (fullness <= (550 * (1 + M.overeatduration / 1000)))
					user.visible_message("<span class='danger'>[user] attempts to feed [M] [src].</span>")
				else
					user.visible_message("<span class='danger'>[user] cannot force anymore of [src] down [M]'s throat.</span>")
					return 0

				user.setClickCooldown(user.get_attack_speed(src))
				if(!do_mob(user, M)) return

				//Do we really care about this
				add_attack_logs(user,M,"Fed with [src.name] containing [reagentlist(src)]", admin_notify = FALSE)

				user.visible_message("<span class='danger'>[user] feeds [M] [src].</span>")

			else
				to_chat(user, "This creature does not seem to have a mouth!")
				return

		if(reagents)								//Handle ingestion of the reagent.
			playsound(M.loc,'sound/items/eatfood.ogg', rand(10,50), 1)
			if(reagents.total_volume)
				if(reagents.total_volume > bitesize)
					reagents.trans_to_mob(M, bitesize, CHEM_INGEST)
				else
					reagents.trans_to_mob(M, reagents.total_volume, CHEM_INGEST)
				bitecount++
				On_Consume(M)
			return 1

	return 0

/obj/item/weapon/reagent_containers/food/snacks/examine(mob/user)
	if(!..(user, 1))
		return
	if (bitecount==0)
		return
	else if (bitecount==1)
		to_chat(user, "<font color='blue'>\The [src] was bitten by someone!</font>")
	else if (bitecount<=3)
		to_chat(user, "<font color='blue'>\The [src] was bitten [bitecount] times!</font>")
	else
		to_chat(user, "<font color='blue'>\The [src] was bitten multiple times!</font>")

/obj/item/weapon/reagent_containers/food/snacks/attackby(obj/item/weapon/W as obj, mob/user as mob)
	if(istype(W,/obj/item/weapon/storage))
		..() // -> item/attackby()
		return

	// Eating with forks
	if(istype(W,/obj/item/weapon/material/kitchen/utensil))
		var/obj/item/weapon/material/kitchen/utensil/U = W
		if(U.scoop_food)
			if(!U.reagents)
				U.create_reagents(5)

			if (U.reagents.total_volume > 0)
				to_chat(user, "<font color='red'>You already have something on your [U].</font>")
				return

			user.visible_message( \
				"[user] scoops up some [src] with \the [U]!", \
				"<font color='blue'>You scoop up some [src] with \the [U]!</font>" \
			)

			src.bitecount++
			U.overlays.Cut()
			U.loaded = "[src]"
			var/image/I = new(U.icon, "loadedfood")
			I.color = src.filling_color
			U.overlays += I

			reagents.trans_to_obj(U, min(reagents.total_volume,5))

			if (reagents.total_volume <= 0)
				qdel(src)
			return

	if (is_sliceable())
		//these are used to allow hiding edge items in food that is not on a table/tray
		var/can_slice_here = isturf(src.loc) && ((locate(/obj/structure/table) in src.loc) || (locate(/obj/machinery/optable) in src.loc) || (locate(/obj/item/weapon/tray) in src.loc))
		var/hide_item = !has_edge(W) || !can_slice_here

		if (hide_item)
			if (W.w_class >= src.w_class || is_robot_module(W))
				return

			to_chat(user, "<span class='warning'>You slip \the [W] inside \the [src].</span>")
			user.drop_from_inventory(W, src)
			add_fingerprint(user)
			contents += W
			return

		if (has_edge(W))
			if (!can_slice_here)
				to_chat(user, "<span class='warning'>You cannot slice \the [src] here! You need a table or at least a tray to do it.</span>")
				return

			var/slices_lost = 0
			if (W.w_class > 3)
				user.visible_message("<span class='notice'>\The [user] crudely slices \the [src] with [W]!</span>", "<span class='notice'>You crudely slice \the [src] with your [W]!</span>")
				slices_lost = rand(1,min(1,round(slices_num/2)))
			else
				user.visible_message("<span class='notice'>\The [user] slices \the [src]!</span>", "<span class='notice'>You slice \the [src]!</span>")

			var/reagents_per_slice = reagents.total_volume/slices_num
			for(var/i=1 to (slices_num-slices_lost))
				var/obj/slice = new slice_path (src.loc)
				reagents.trans_to_obj(slice, reagents_per_slice)
			qdel(src)
			return

/obj/item/weapon/reagent_containers/food/snacks/proc/is_sliceable()
	return (slices_num && slice_path && slices_num > 0)

/obj/item/weapon/reagent_containers/food/snacks/Destroy()
	if(contents)
		for(var/atom/movable/something in contents)
			something.dropInto(loc)
	. = ..()

////////////////////////////////////////////////////////////////////////////////
/// FOOD END
////////////////////////////////////////////////////////////////////////////////
/obj/item/weapon/reagent_containers/food/snacks/attack_generic(var/mob/living/user)
	if(!isanimal(user) && !isalien(user))
		return
	user.visible_message("<b>[user]</b> nibbles away at \the [src].","You nibble away at \the [src].")
	bitecount++
	if(reagents)
		reagents.trans_to_mob(user, bitesize, CHEM_INGEST)
	spawn(5)
		if(!src && !user.client)
			user.custom_emote(1,"[pick("burps", "cries for more", "burps twice", "looks at the area where the food was")]")
			qdel(src)
	On_Consume(user)

//////////////////////////////////////////////////
////////////////////////////////////////////Snacks
//////////////////////////////////////////////////
//Items in the "Snacks" subcategory are food items that people actually eat. The key points are that they are created
//	already filled with reagents and are destroyed when empty. Additionally, they make a "munching" noise when eaten.

//Notes by Darem: Food in the "snacks" subtype can hold a maximum of 50 units Generally speaking, you don't want to go over 40
//	total for the item because you want to leave space for extra condiments. If you want effect besides healing, add a reagent for
//	it. Try to stick to existing reagents when possible (so if you want a stronger healing effect, just use Tricordrazine). On use
//	effect (such as the old officer eating a donut code) requires a unique reagent (unless you can figure out a better way).

//The nutriment reagent and bitesize variable replace the old heal_amt and amount variables. Each unit of nutriment is equal to
//	2 of the old heal_amt variable. Bitesize is the rate at which the reagents are consumed. So if you have 6 nutriment and a
//	bitesize of 2, then it'll take 3 bites to eat. Unlike the old system, the contained reagents are evenly spread among all
//	the bites. No more contained reagents = no more bites.

//Here is an example of the new formatting for anyone who wants to add more food items.
///obj/item/weapon/reagent_containers/food/snacks/xenoburger			//Identification path for the object.
//	name = "Xenoburger"													//Name that displays in the UI.
//	desc = "Smells caustic. Tastes like heresy."						//Duh
//	icon_state = "xburger"												//Refers to an icon in food.dmi
//	New()																//Don't mess with this.
//		..()															//Same here.
//		reagents.add_reagent("xenomicrobes", 10)						//This is what is in the food item. you may copy/paste
//		reagents.add_reagent("nutriment", 2)							//	this line of code for all the contents.
//		bitesize = 3													//This is the amount each bite consumes.




/obj/item/weapon/reagent_containers/food/snacks/aesirsalad
	name = "Aesir salad"
	desc = "Probably too incredible for mortal men to fully enjoy."
	icon_state = "aesirsalad"
	trash = /obj/item/trash/snack_bowl
	filling_color = "#468C00"
	center_of_mass = list("x"=17, "y"=11)
	nutriment_amt = 8
	nutriment_desc = list("apples" = 3,"salad" = 5)

/obj/item/weapon/reagent_containers/food/snacks/aesirsalad/Initialize()
	. = ..()
	reagents.add_reagent("doctorsdelight", 8)
	reagents.add_reagent("tricordrazine", 8)
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/candy
	name = "candy"
	desc = "Nougat, love it or hate it."
	icon_state = "candy"
	trash = /obj/item/trash/candy
	filling_color = "#7D5F46"
	center_of_mass = list("x"=15, "y"=15)
	nutriment_amt = 1
	nutriment_desc = list("candy" = 1)

/obj/item/weapon/reagent_containers/food/snacks/candy/Initialize()
	. = ..()
	reagents.add_reagent("sugar", 3)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/candy/proteinbar
	name = "protein bar"
	desc = "SwoleMAX brand protein bars, guaranteed to get you feeling perfectly overconfident."
	icon_state = "proteinbar"
	trash = /obj/item/trash/candy/proteinbar
	nutriment_amt = 9
	nutriment_desc = list("candy" = 1, "protein" = 8)

/obj/item/weapon/reagent_containers/food/snacks/candy/proteinbar/Initialize()
	. = ..()
	reagents.add_reagent("protein", 4)
	reagents.add_reagent("sugar", 4)
	bitesize = 6

/obj/item/weapon/reagent_containers/food/snacks/candy/donor
	name = "Donor Candy"
	desc = "A little treat for blood donors."
	trash = /obj/item/trash/candy
	nutriment_amt = 9
	nutriment_desc = list("candy" = 10)

/obj/item/weapon/reagent_containers/food/snacks/candy/donor/Initialize()
	. = ..()
	reagents.add_reagent("sugar", 3)
	bitesize = 5

/obj/item/weapon/reagent_containers/food/snacks/candy_corn
	name = "candy corn"
	desc = "It's a handful of candy corn. Cannot be stored in a detective's hat, alas."
	icon_state = "candy_corn"
	filling_color = "#FFFCB0"
	center_of_mass = list("x"=14, "y"=10)
	nutriment_amt = 4
	nutriment_desc = list("candy corn" = 4)

/obj/item/weapon/reagent_containers/food/snacks/candy_corn/Initialize()
	..()
	reagents.add_reagent("sugar", 2)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/chips
	name = "chips"
	desc = "Commander Riker's What-The-Crisps"
	icon_state = "chips"
	trash = /obj/item/trash/chips
	filling_color = "#E8C31E"
	center_of_mass = list("x"=15, "y"=15)
	nutriment_amt = 3
	nutriment_desc = list("salt" = 1, "chips" = 2)

/obj/item/weapon/reagent_containers/food/snacks/chips/Initialize()
	. = ..()
	bitesize = 1

/obj/item/weapon/reagent_containers/food/snacks/cookie
	name = "cookie"
	desc = "COOKIE!!!"
	icon_state = "COOKIE!!!"
	filling_color = "#DBC94F"
	center_of_mass = list("x"=17, "y"=18)
	nutriment_amt = 5
	nutriment_desc = list("sweetness" = 3, "cookie" = 2)

/obj/item/weapon/reagent_containers/food/snacks/cookie/Initialize()
	. = ..()
	bitesize = 1

/obj/item/weapon/reagent_containers/food/snacks/chocolatebar
	name = "Chocolate Bar"
	desc = "Such sweet, fattening food."
	icon_state = "chocolatebar"
	filling_color = "#7D5F46"
	center_of_mass = list("x"=15, "y"=15)
	nutriment_amt = 2
	nutriment_desc = list("chocolate" = 5)

/obj/item/weapon/reagent_containers/food/snacks/chocolatebar/Initialize()
	. = ..()
	reagents.add_reagent("sugar", 2)
	reagents.add_reagent("coco", 2)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/chocolatepiece
	name = "chocolate piece"
	desc = "A luscious milk chocolate piece filled with gooey caramel."
	icon_state =  "chocolatepiece"
	filling_color = "#7D5F46"
	center_of_mass = list("x"=15, "y"=15)
	nutriment_amt = 1
	nutriment_desc = list("chocolate" = 3, "caramel" = 2, "lusciousness" = 1)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/chocolatepiece/white
	name = "white chocolate piece"
	desc = "A creamy white chocolate piece drizzled in milk chocolate."
	icon_state = "chocolatepiece_white"
	filling_color = "#E2DAD3"
	nutriment_desc = list("white chocolate" = 3, "creaminess" = 1)

/obj/item/weapon/reagent_containers/food/snacks/chocolatepiece/truffle
	name = "chocolate truffle"
	desc = "A bite-sized milk chocolate truffle that could buy anyone's love."
	icon_state = "chocolatepiece_truffle"
	nutriment_desc = list("chocolate" = 3, "undying devotion" = 3)

/obj/item/weapon/reagent_containers/food/snacks/chocolateegg
	name = "Chocolate Egg"
	desc = "Such sweet, fattening food."
	icon_state = "chocolateegg"
	filling_color = "#7D5F46"
	center_of_mass = list("x"=16, "y"=13)
	nutriment_amt = 3
	nutriment_desc = list("chocolate" = 5)

/obj/item/weapon/reagent_containers/food/snacks/chocolateegg/Initialize()
	. = ..()
	reagents.add_reagent("sugar", 2)
	reagents.add_reagent("coco", 2)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/donut
	name = "donut"
	desc = "Goes great with Robust Coffee."
	icon_state = "donut1"
	filling_color = "#D9C386"
	var/overlay_state = "box-donut1"
	center_of_mass = list("x"=13, "y"=16)
	nutriment_desc = list("sweetness", "donut")

/obj/item/weapon/reagent_containers/food/snacks/donut/normal
	name = "donut"
	desc = "Goes great with Robust Coffee."
	icon_state = "donut1"
	nutriment_amt = 3

/obj/item/weapon/reagent_containers/food/snacks/donut/normal/Initialize()
	. = ..()
	reagents.add_reagent("nutriment", 3)
	reagents.add_reagent("sprinkles", 1)
	src.bitesize = 3
	if(prob(30))
		src.icon_state = "donut2"
		src.overlay_state = "box-donut2"
		src.name = "frosted donut"
		reagents.add_reagent("sprinkles", 2)
		center_of_mass = list("x"=19, "y"=16)

/obj/item/weapon/reagent_containers/food/snacks/donut/chaos
	name = "Chaos Donut"
	desc = "Like life, it never quite tastes the same."
	icon_state = "donut1"
	filling_color = "#ED11E6"
	nutriment_amt = 2

/obj/item/weapon/reagent_containers/food/snacks/donut/chaos/Initialize()
	. = ..()
	reagents.add_reagent("sprinkles", 1)
	bitesize = 10
	var/chaosselect = pick(1,2,3,4,5,6,7,8,9,10)
	switch(chaosselect)
		if(1)
			reagents.add_reagent("nutriment", 3)
		if(2)
			reagents.add_reagent("capsaicin", 3)
		if(3)
			reagents.add_reagent("frostoil", 3)
		if(4)
			reagents.add_reagent("sprinkles", 3)
		if(5)
			reagents.add_reagent("phoron", 3)
		if(6)
			reagents.add_reagent("coco", 3)
		if(7)
			reagents.add_reagent("slimejelly", 3)
		if(8)
			reagents.add_reagent("banana", 3)
		if(9)
			reagents.add_reagent("berryjuice", 3)
		if(10)
			reagents.add_reagent("tricordrazine", 3)
	if(prob(30))
		src.icon_state = "donut2"
		src.overlay_state = "box-donut2"
		src.name = "Frosted Chaos Donut"
		reagents.add_reagent("sprinkles", 2)

/obj/item/weapon/reagent_containers/food/snacks/donut/jelly
	name = "Jelly Donut"
	desc = "You jelly?"
	icon_state = "jdonut1"
	filling_color = "#ED1169"
	center_of_mass = list("x"=16, "y"=11)
	nutriment_amt = 3

/obj/item/weapon/reagent_containers/food/snacks/donut/jelly/Initialize()
	. = ..()
	reagents.add_reagent("sprinkles", 1)
	reagents.add_reagent("berryjuice", 5)
	bitesize = 5
	if(prob(30))
		src.icon_state = "jdonut2"
		src.overlay_state = "box-donut2"
		src.name = "Frosted Jelly Donut"
		reagents.add_reagent("sprinkles", 2)

/obj/item/weapon/reagent_containers/food/snacks/donut/slimejelly
	name = "Jelly Donut"
	desc = "You jelly?"
	icon_state = "jdonut1"
	filling_color = "#ED1169"
	center_of_mass = list("x"=16, "y"=11)
	nutriment_amt = 3

/obj/item/weapon/reagent_containers/food/snacks/donut/slimejelly/Initialize()
	. = ..()
	reagents.add_reagent("sprinkles", 1)
	reagents.add_reagent("slimejelly", 5)
	bitesize = 5
	if(prob(30))
		src.icon_state = "jdonut2"
		src.overlay_state = "box-donut2"
		src.name = "Frosted Jelly Donut"
		reagents.add_reagent("sprinkles", 2)

/obj/item/weapon/reagent_containers/food/snacks/donut/cherryjelly
	name = "Jelly Donut"
	desc = "You jelly?"
	icon_state = "jdonut1"
	filling_color = "#ED1169"
	center_of_mass = list("x"=16, "y"=11)
	nutriment_amt = 3

/obj/item/weapon/reagent_containers/food/snacks/donut/cherryjelly/Initialize()
	. = ..()
	reagents.add_reagent("sprinkles", 1)
	reagents.add_reagent("cherryjelly", 5)
	bitesize = 5
	if(prob(30))
		src.icon_state = "jdonut2"
		src.overlay_state = "box-donut2"
		src.name = "Frosted Jelly Donut"
		reagents.add_reagent("sprinkles", 2)

/obj/item/weapon/reagent_containers/food/snacks/egg
	name = "egg"
	desc = "An egg!"
	icon_state = "egg"
	filling_color = "#FDFFD1"
	volume = 10
	center_of_mass = list("x"=16, "y"=13)

/obj/item/weapon/reagent_containers/food/snacks/egg/Initialize()
	. = ..()
	reagents.add_reagent("egg", 3)

/obj/item/weapon/reagent_containers/food/snacks/egg/afterattack(obj/O as obj, mob/user as mob, proximity)
	if(istype(O,/obj/machinery/microwave))
		return ..()
	if(!(proximity && O.is_open_container()))
		return
	user << "You crack \the [src] into \the [O]."
	reagents.trans_to(O, reagents.total_volume)
	user.drop_from_inventory(src)
	qdel(src)

/obj/item/weapon/reagent_containers/food/snacks/egg/throw_impact(atom/hit_atom)
	..()
	new/obj/effect/decal/cleanable/egg_smudge(src.loc)
	src.reagents.splash(hit_atom, reagents.total_volume)
	src.visible_message("<font color='red'>[src.name] has been squashed.</font>","<font color='red'>You hear a smack.</font>")
	qdel(src)

/obj/item/weapon/reagent_containers/food/snacks/egg/attackby(obj/item/weapon/W as obj, mob/user as mob)
	if(istype( W, /obj/item/weapon/pen/crayon ))
		var/obj/item/weapon/pen/crayon/C = W
		var/clr = C.colourName

		if(!(clr in list("blue","green","mime","orange","purple","rainbow","red","yellow")))
			usr << "<font color='blue'>The egg refuses to take on this color!</font>"
			return

		usr << "<font color='blue'>You color \the [src] [clr]</font>"
		icon_state = "egg-[clr]"
	else
		..()

/obj/item/weapon/reagent_containers/food/snacks/egg/blue
	icon_state = "egg-blue"

/obj/item/weapon/reagent_containers/food/snacks/egg/green
	icon_state = "egg-green"

/obj/item/weapon/reagent_containers/food/snacks/egg/mime
	icon_state = "egg-mime"

/obj/item/weapon/reagent_containers/food/snacks/egg/orange
	icon_state = "egg-orange"

/obj/item/weapon/reagent_containers/food/snacks/egg/purple
	icon_state = "egg-purple"

/obj/item/weapon/reagent_containers/food/snacks/egg/rainbow
	icon_state = "egg-rainbow"

/obj/item/weapon/reagent_containers/food/snacks/egg/red
	icon_state = "egg-red"

/obj/item/weapon/reagent_containers/food/snacks/egg/yellow
	icon_state = "egg-yellow"

/obj/item/weapon/reagent_containers/food/snacks/friedegg
	name = "Fried egg"
	desc = "A fried egg, with a touch of salt and pepper."
	icon_state = "friedegg"
	filling_color = "#FFDF78"
	center_of_mass = list("x"=16, "y"=14)

/obj/item/weapon/reagent_containers/food/snacks/friedegg/Initialize()
	. = ..()
	reagents.add_reagent("protein", 3)
	reagents.add_reagent("sodiumchloride", 1)
	reagents.add_reagent("blackpepper", 1)
	bitesize = 1

/obj/item/weapon/reagent_containers/food/snacks/boiledegg
	name = "Boiled egg"
	desc = "A hard boiled egg."
	icon_state = "egg"
	filling_color = "#FFFFFF"

/obj/item/weapon/reagent_containers/food/snacks/boiledegg/Initialize()
	. = ..()
	reagents.add_reagent("protein", 2)

/obj/item/weapon/reagent_containers/food/snacks/organ
	name = "organ"
	desc = "It's good for you."
	icon = 'icons/obj/surgery.dmi'
	icon_state = "appendix"
	filling_color = "#E00D34"
	center_of_mass = list("x"=16, "y"=16)

/obj/item/weapon/reagent_containers/food/snacks/organ/Initialize()
	. = ..()
	reagents.add_reagent("protein", rand(3,5))
	reagents.add_reagent("toxin", rand(1,3))
	src.bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/tofu
	name = "Tofu"
	icon_state = "tofu"
	desc = "We all love tofu."
	filling_color = "#FFFEE0"
	center_of_mass = list("x"=17, "y"=10)
	nutriment_amt = 3
	nutriment_desc = list("tofu" = 3, "goeyness" = 3)

/obj/item/weapon/reagent_containers/food/snacks/tofu/Initialize()
	. = ..()
	src.bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/tofurkey
	name = "Tofurkey"
	desc = "A fake turkey made from tofu."
	icon_state = "tofurkey"
	filling_color = "#FFFEE0"
	center_of_mass = list("x"=16, "y"=8)
	nutriment_amt = 12
	nutriment_desc = list("turkey" = 3, "tofu" = 5, "goeyness" = 4)

/obj/item/weapon/reagent_containers/food/snacks/tofurkey/Initialize()
	. = ..()
	reagents.add_reagent("stoxin", 3)
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/stuffing
	name = "Stuffing"
	desc = "Moist, peppery breadcrumbs for filling the body cavities of dead birds. Dig in!"
	icon_state = "stuffing"
	filling_color = "#C9AC83"
	center_of_mass = list("x"=16, "y"=10)
	nutriment_amt = 3
	nutriment_desc = list("dryness" = 2, "bread" = 2)

/obj/item/weapon/reagent_containers/food/snacks/stuffing/Initialize()
	. = ..()
	bitesize = 1

/obj/item/weapon/reagent_containers/food/snacks/carpmeat
	name = "fillet"
	desc = "A fillet of carp meat"
	icon_state = "fishfillet"
	filling_color = "#FFDEFE"
	center_of_mass = list("x"=17, "y"=13)

	var/toxin_type = "carpotoxin"
	var/toxin_amount = 3

/obj/item/weapon/reagent_containers/food/snacks/carpmeat/Initialize()
	. = ..()
	reagents.add_reagent("protein", 3)
	reagents.add_reagent(toxin_type, toxin_amount)
	src.bitesize = 6

/obj/item/weapon/reagent_containers/food/snacks/carpmeat/sif
	desc = "A fillet of sivian fish meat."
	filling_color = "#2c2cff"
	color = "#2c2cff"
	toxin_type = "neurotoxic_protein"
	toxin_amount = 2

/obj/item/weapon/reagent_containers/food/snacks/carpmeat/sif/murkfish
	toxin_type = "murk_protein"

/obj/item/weapon/reagent_containers/food/snacks/carpmeat/fish
	desc = "A fillet of fish meat."
	toxin_type = "neurotoxic_protein"
	toxin_amount = 1

/obj/item/weapon/reagent_containers/food/snacks/fishfingers
	name = "Fish Fingers"
	desc = "A finger of fish."
	icon_state = "fishfingers"
	filling_color = "#FFDEFE"
	center_of_mass = list("x"=16, "y"=13)

/obj/item/weapon/reagent_containers/food/snacks/fishfingers/Initialize()
	. = ..()
	reagents.add_reagent("protein", 4)
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/zestfish
	name = "Zesty Fish"
	desc = "Lightly seasoned fish fillets."
	icon_state = "zestfish"
	filling_color = "#FFDEFE"
	center_of_mass = list("x"=16, "y"=13)

/obj/item/weapon/reagent_containers/food/snacks/zestfish/Initialize()
	. = ..()
	reagents.add_reagent("protein", 4)
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/hugemushroomslice
	name = "huge mushroom slice"
	desc = "A slice from a huge mushroom."
	icon_state = "hugemushroomslice"
	filling_color = "#E0D7C5"
	center_of_mass = list("x"=17, "y"=16)
	nutriment_amt = 3
	nutriment_desc = list("raw" = 2, "mushroom" = 2)

/obj/item/weapon/reagent_containers/food/snacks/hugemushroomslice/Initialize()
	. = ..()
	reagents.add_reagent("psilocybin", 3)
	src.bitesize = 6

/obj/item/weapon/reagent_containers/food/snacks/tomatomeat
	name = "tomato slice"
	desc = "A slice from a huge tomato"
	icon_state = "tomatomeat"
	filling_color = "#DB0000"
	center_of_mass = list("x"=17, "y"=16)
	nutriment_amt = 3
	nutriment_desc = list("raw" = 2, "tomato" = 3)

/obj/item/weapon/reagent_containers/food/snacks/tomatomeat/Initialize()
	. = ..()
	src.bitesize = 6

/obj/item/weapon/reagent_containers/food/snacks/bearmeat
	name = "bear meat"
	desc = "A very manly slab of meat."
	icon_state = "bearmeat"
	filling_color = "#DB0000"
	center_of_mass = list("x"=16, "y"=10)

/obj/item/weapon/reagent_containers/food/snacks/bearmeat/Initialize()
	. = ..()
	reagents.add_reagent("protein", 12)
	reagents.add_reagent("hyperzine", 5)
	src.bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/xenomeat
	name = "xenomeat"
	desc = "A slab of green meat. Smells like acid."
	icon_state = "xenomeat"
	filling_color = "#43DE18"
	center_of_mass = list("x"=16, "y"=10)

/obj/item/weapon/reagent_containers/food/snacks/xenomeat/Initialize()
	. = ..()
	reagents.add_reagent("protein", 6)
	reagents.add_reagent("pacid",6)
	src.bitesize = 6

/obj/item/weapon/reagent_containers/food/snacks/xenomeat/spidermeat // Substitute for recipes requiring xeno meat.
	name = "spider meat"
	desc = "A slab of green meat."
	icon_state = "xenomeat"
	filling_color = "#43DE18"
	center_of_mass = list("x"=16, "y"=10)

/obj/item/weapon/reagent_containers/food/snacks/xenomeat/spidermeat/Initialize()
	. = ..()
	reagents.add_reagent("spidertoxin",6)
	reagents.remove_reagent("pacid",6)
	src.bitesize = 6

/obj/item/weapon/reagent_containers/food/snacks/meatball
	name = "meatball"
	desc = "A great meal all round."
	icon_state = "meatball"
	filling_color = "#DB0000"
	center_of_mass = list("x"=16, "y"=16)

/obj/item/weapon/reagent_containers/food/snacks/meatball/Initialize()
	. = ..()
	reagents.add_reagent("protein", 3)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/sausage
	name = "Sausage"
	desc = "A piece of mixed, long meat."
	icon_state = "sausage"
	filling_color = "#DB0000"
	center_of_mass = list("x"=16, "y"=16)

/obj/item/weapon/reagent_containers/food/snacks/sausage/Initialize()
	. = ..()
	reagents.add_reagent("protein", 6)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/donkpocket
	name = "Donk-pocket"
	desc = "The food of choice for the seasoned traitor."
	icon_state = "donkpocket"
	filling_color = "#DEDEAB"
	center_of_mass = list("x"=16, "y"=10)
	var/warm
	var/list/heated_reagents

/obj/item/weapon/reagent_containers/food/snacks/donkpocket/Initialize()
	. = ..()
	reagents.add_reagent("nutriment", 2)
	reagents.add_reagent("protein", 2)

	warm = 0
	heated_reagents = list("tricordrazine" = 5)

/obj/item/weapon/reagent_containers/food/snacks/donkpocket/proc/heat()
	warm = 1
	for(var/reagent in heated_reagents)
		reagents.add_reagent(reagent, heated_reagents[reagent])
	bitesize = 6
	name = "Warm " + name
	cooltime()

/obj/item/weapon/reagent_containers/food/snacks/donkpocket/proc/cooltime()
	if (src.warm)
		spawn(4200)
			src.warm = 0
			for(var/reagent in heated_reagents)
				src.reagents.del_reagent(reagent)
			src.name = initial(name)
	return

/obj/item/weapon/reagent_containers/food/snacks/donkpocket/sinpocket
	name = "\improper Sin-pocket"
	desc = "The food of choice for the veteran. Do <B>NOT</B> overconsume."
	filling_color = "#6D6D00"
	heated_reagents = list("doctorsdelight" = 5, "hyperzine" = 0.75, "synaptizine" = 0.25)
	var/has_been_heated = 0

/obj/item/weapon/reagent_containers/food/snacks/donkpocket/sinpocket/attack_self(mob/user)
	if(has_been_heated)
		user << "<span class='notice'>The heating chemicals have already been spent.</span>"
		return
	has_been_heated = 1
	user.visible_message("<span class='notice'>[user] crushes \the [src] package.</span>", "You crush \the [src] package and feel a comfortable heat build up.")
	spawn(200)
		user << "You think \the [src] is ready to eat about now."
		heat()

/obj/item/weapon/reagent_containers/food/snacks/brainburger
	name = "brainburger"
	desc = "A strange looking burger. It looks almost sentient."
	icon_state = "brainburger"
	filling_color = "#F2B6EA"
	center_of_mass = list("x"=15, "y"=11)

/obj/item/weapon/reagent_containers/food/snacks/brainburger/Initialize()
	. = ..()
	reagents.add_reagent("protein", 6)
	reagents.add_reagent("alkysine", 6)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/ghostburger
	name = "Ghost Burger"
	desc = "Spooky! It doesn't look very filling."
	icon_state = "ghostburger"
	filling_color = "#FFF2FF"
	center_of_mass = list("x"=16, "y"=11)
	nutriment_desc = list("buns" = 3, "spookiness" = 3)
	nutriment_amt = 2

/obj/item/weapon/reagent_containers/food/snacks/ghostburger/Initialize()
	. = ..()
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/human
	var/hname = ""
	var/job = null
	filling_color = "#D63C3C"

/obj/item/weapon/reagent_containers/food/snacks/human/burger
	name = "-burger"
	desc = "A bloody burger."
	icon_state = "hburger"
	center_of_mass = list("x"=16, "y"=11)

/obj/item/weapon/reagent_containers/food/snacks/human/burger/Initialize()
	. = ..()
	reagents.add_reagent("protein", 6)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/cheeseburger
	name = "cheeseburger"
	desc = "The cheese adds a good flavor."
	icon_state = "cheeseburger"
	center_of_mass = list("x"=16, "y"=11)
	nutriment_amt = 2
	nutriment_desc = list("cheese" = 2, "bun" = 2)

/obj/item/weapon/reagent_containers/food/snacks/cheeseburger/Initialize()
	. = ..()
	reagents.add_reagent("protein", 2)

/obj/item/weapon/reagent_containers/food/snacks/monkeyburger
	name = "burger"
	desc = "The cornerstone of every nutritious breakfast."
	icon_state = "hburger"
	filling_color = "#D63C3C"
	center_of_mass = list("x"=16, "y"=11)
	nutriment_amt = 3
	nutriment_desc = list("bun" = 2)

/obj/item/weapon/reagent_containers/food/snacks/monkeyburger/Initialize()
	. = ..()
	reagents.add_reagent("protein", 3)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/fishburger
	name = "Fillet -o- Carp Sandwich"
	desc = "Almost like a carp is yelling somewhere... Give me back that fillet -o- carp, give me that carp."
	icon_state = "fishburger"
	filling_color = "#FFDEFE"
	center_of_mass = list("x"=16, "y"=10)

/obj/item/weapon/reagent_containers/food/snacks/fishburger/Initialize()
	. = ..()
	reagents.add_reagent("protein", 6)
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/tofuburger
	name = "Tofu Burger"
	desc = "What.. is that meat?"
	icon_state = "tofuburger"
	filling_color = "#FFFEE0"
	center_of_mass = list("x"=16, "y"=10)
	nutriment_amt = 6
	nutriment_desc = list("bun" = 2, "pseudo-soy meat" = 3)

/obj/item/weapon/reagent_containers/food/snacks/tofuburger/Initialize()
	. = ..()
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/roburger
	name = "roburger"
	desc = "The lettuce is the only organic component. Beep."
	icon_state = "roburger"
	filling_color = "#CCCCCC"
	center_of_mass = list("x"=16, "y"=11)
	nutriment_amt = 2
	nutriment_desc = list("bun" = 2, "metal" = 3)

/obj/item/weapon/reagent_containers/food/snacks/roburger/Initialize()
	. = ..()
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/roburgerbig
	name = "roburger"
	desc = "This massive patty looks like poison. Beep."
	icon_state = "roburger"
	filling_color = "#CCCCCC"
	volume = 100
	center_of_mass = list("x"=16, "y"=11)

/obj/item/weapon/reagent_containers/food/snacks/roburgerbig/Initialize()
	. = ..()
	bitesize = 0.1

/obj/item/weapon/reagent_containers/food/snacks/xenoburger
	name = "xenoburger"
	desc = "Smells caustic. Tastes like heresy."
	icon_state = "xburger"
	filling_color = "#43DE18"
	center_of_mass = list("x"=16, "y"=11)

/obj/item/weapon/reagent_containers/food/snacks/xenoburger/Initialize()
	. = ..()
	reagents.add_reagent("protein", 8)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/clownburger
	name = "Clown Burger"
	desc = "This tastes funny..."
	icon_state = "clownburger"
	filling_color = "#FF00FF"
	center_of_mass = list("x"=17, "y"=12)
	nutriment_amt = 6
	nutriment_desc = list("bun" = 2, "clown shoe" = 3)

/obj/item/weapon/reagent_containers/food/snacks/clownburger/Initialize()
	. = ..()
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/mimeburger
	name = "Mime Burger"
	desc = "Its taste defies language."
	icon_state = "mimeburger"
	filling_color = "#FFFFFF"
	center_of_mass = list("x"=16, "y"=11)
	nutriment_amt = 6
	nutriment_desc = list("bun" = 2, "face paint" = 3)

/obj/item/weapon/reagent_containers/food/snacks/mimeburger/Initialize()
	. = ..()
	reagents.add_reagent("nutriment", 6)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/omelette
	name = "Omelette Du Fromage"
	desc = "That's all you can say!"
	icon_state = "omelette"
	trash = /obj/item/trash/plate
	filling_color = "#FFF9A8"
	center_of_mass = list("x"=16, "y"=13)

/obj/item/weapon/reagent_containers/food/snacks/omelette/Initialize()
	. = ..()
	reagents.add_reagent("protein", 8)
	bitesize = 1

/obj/item/weapon/reagent_containers/food/snacks/muffin
	name = "Muffin"
	desc = "A delicious and spongy little cake"
	icon_state = "muffin"
	filling_color = "#E0CF9B"
	center_of_mass = list("x"=17, "y"=4)
	nutriment_amt = 6
	nutriment_desc = list("sweetness" = 3, "muffin" = 3)

/obj/item/weapon/reagent_containers/food/snacks/muffin/Initialize()
	. = ..()
	reagents.add_reagent("nutriment", 6)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/pie
	name = "Banana Cream Pie"
	desc = "Just like back home, on clown planet! HONK!"
	icon_state = "pie"
	trash = /obj/item/trash/plate
	filling_color = "#FBFFB8"
	center_of_mass = list("x"=16, "y"=13)
	nutriment_amt = 4
	nutriment_desc = list("pie" = 3, "cream" = 2)

/obj/item/weapon/reagent_containers/food/snacks/pie/Initialize()
	. = ..()
	reagents.add_reagent("banana",5)
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/pie/throw_impact(atom/hit_atom)
	..()
	new/obj/effect/decal/cleanable/pie_smudge(src.loc)
	src.visible_message("<span class='danger'>\The [src.name] splats.</span>","<span class='danger'>You hear a splat.</span>")
	qdel(src)

/obj/item/weapon/reagent_containers/food/snacks/berryclafoutis
	name = "Berry Clafoutis"
	desc = "No black birds, this is a good sign."
	icon_state = "berryclafoutis"
	trash = /obj/item/trash/plate
	center_of_mass = list("x"=16, "y"=13)
	nutriment_amt = 4
	nutriment_desc = list("sweetness" = 2, "pie" = 3)

/obj/item/weapon/reagent_containers/food/snacks/berryclafoutis/Initialize()
	. = ..()
	reagents.add_reagent("berryjuice", 5)
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/waffles
	name = "waffles"
	desc = "Mmm, waffles"
	icon_state = "waffles"
	trash = /obj/item/trash/waffles
	filling_color = "#E6DEB5"
	center_of_mass = list("x"=15, "y"=11)
	nutriment_amt = 8
	nutriment_desc = list("waffle" = 8)

/obj/item/weapon/reagent_containers/food/snacks/waffles/Initialize()
	. = ..()
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/eggplantparm
	name = "Eggplant Parmigiana"
	desc = "The only good recipe for eggplant."
	icon_state = "eggplantparm"
	trash = /obj/item/trash/plate
	filling_color = "#4D2F5E"
	center_of_mass = list("x"=16, "y"=11)
	nutriment_amt = 6
	nutriment_desc = list("cheese" = 3, "eggplant" = 3)

/obj/item/weapon/reagent_containers/food/snacks/eggplantparm/Initialize()
	. = ..()
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/soylentgreen
	name = "Soylent Green"
	desc = "Not made of people. Honest." //Totally people.
	icon_state = "soylent_green"
	trash = /obj/item/trash/waffles
	filling_color = "#B8E6B5"
	center_of_mass = list("x"=15, "y"=11)

/obj/item/weapon/reagent_containers/food/snacks/soylentgreen/Initialize()
	. = ..()
	reagents.add_reagent("protein", 10)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/soylenviridians
	name = "Soylen Virdians"
	desc = "Not made of people. Honest." //Actually honest for once.
	icon_state = "soylent_yellow"
	trash = /obj/item/trash/waffles
	filling_color = "#E6FA61"
	center_of_mass = list("x"=15, "y"=11)
	nutriment_amt = 10
	nutriment_desc = list("some sort of protein" = 10)  //seasoned VERY well.

/obj/item/weapon/reagent_containers/food/snacks/soylenviridians/Initialize()
	. = ..()
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/meatpie
	name = "Meat-pie"
	icon_state = "meatpie"
	desc = "An old barber recipe, very delicious!"
	trash = /obj/item/trash/plate
	filling_color = "#948051"
	center_of_mass = list("x"=16, "y"=13)

/obj/item/weapon/reagent_containers/food/snacks/meatpie/Initialize()
	. = ..()
	reagents.add_reagent("protein", 10)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/tofupie
	name = "Tofu-pie"
	icon_state = "meatpie"
	desc = "A delicious tofu pie."
	trash = /obj/item/trash/plate
	filling_color = "#FFFEE0"
	center_of_mass = list("x"=16, "y"=13)
	nutriment_amt = 10
	nutriment_desc = list("tofu" = 2, "pie" = 8)

/obj/item/weapon/reagent_containers/food/snacks/tofupie/Initialize()
	. = ..()
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/amanita_pie
	name = "amanita pie"
	desc = "Sweet and tasty poison pie."
	icon_state = "amanita_pie"
	filling_color = "#FFCCCC"
	center_of_mass = list("x"=17, "y"=9)
	nutriment_amt = 5
	nutriment_desc = list("sweetness" = 3, "mushroom" = 3, "pie" = 2)

/obj/item/weapon/reagent_containers/food/snacks/amanita_pie/Initialize()
	..()
	reagents.add_reagent("amatoxin", 3)
	reagents.add_reagent("psilocybin", 1)
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/plump_pie
	name = "plump pie"
	desc = "I bet you love stuff made out of plump helmets!"
	icon_state = "plump_pie"
	filling_color = "#B8279B"
	center_of_mass = list("x"=17, "y"=9)
	nutriment_amt = 8
	nutriment_desc = list("heartiness" = 2, "mushroom" = 3, "pie" = 3)

/obj/item/weapon/reagent_containers/food/snacks/plump_pie/Initialize()
	..()
	if(prob(10))
		name = "exceptional plump pie"
		desc = "Microwave is taken by a fey mood! It has cooked an exceptional plump pie!"
		reagents.add_reagent("nutriment", 8)
		reagents.add_reagent("tricordrazine", 5)
		bitesize = 2
	else
		bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/xemeatpie
	name = "Xeno-pie"
	icon_state = "xenomeatpie"
	desc = "A delicious meatpie. Probably heretical."
	trash = /obj/item/trash/plate
	filling_color = "#43DE18"
	center_of_mass = list("x"=16, "y"=13)

/obj/item/weapon/reagent_containers/food/snacks/xemeatpie/Initialize()
	. = ..()
	reagents.add_reagent("protein", 10)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/wingfangchu
	name = "Wing Fang Chu"
	desc = "A savory dish of alien wing wang in soy."
	icon_state = "wingfangchu"
	trash = /obj/item/trash/snack_bowl
	filling_color = "#43DE18"
	center_of_mass = list("x"=17, "y"=9)

/obj/item/weapon/reagent_containers/food/snacks/wingfangchu/Initialize()
	. = ..()
	reagents.add_reagent("protein", 6)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/human/kabob
	name = "-kabob"
	icon_state = "kabob"
	desc = "A human meat, on a stick."
	trash = /obj/item/stack/rods
	filling_color = "#A85340"
	center_of_mass = list("x"=17, "y"=15)

/obj/item/weapon/reagent_containers/food/snacks/human/kabob/Initialize()
	. = ..()
	reagents.add_reagent("protein", 8)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/monkeykabob
	name = "Meat-kabob"
	icon_state = "kabob"
	desc = "Delicious meat, on a stick."
	trash = /obj/item/stack/rods
	filling_color = "#A85340"
	center_of_mass = list("x"=17, "y"=15)

/obj/item/weapon/reagent_containers/food/snacks/monkeykabob/Initialize()
	. = ..()
	reagents.add_reagent("protein", 8)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/tofukabob
	name = "Tofu-kabob"
	icon_state = "kabob"
	desc = "Vegan meat, on a stick."
	trash = /obj/item/stack/rods
	filling_color = "#FFFEE0"

	center_of_mass = list("x"=17, "y"=15)
	nutriment_amt = 8
	nutriment_desc = list("tofu" = 3, "metal" = 1)

/obj/item/weapon/reagent_containers/food/snacks/tofukabob/Initialize()
	. = ..()
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/cubancarp
	name = "Cuban Carp"
	desc = "A sandwich that burns your tongue and then leaves it numb!"
	icon_state = "cubancarp"
	trash = /obj/item/trash/plate
	filling_color = "#E9ADFF"
	center_of_mass = list("x"=12, "y"=5)
	nutriment_amt = 3
	nutriment_desc = list("toasted bread" = 3)

/obj/item/weapon/reagent_containers/food/snacks/cubancarp/Initialize()
	. = ..()
	reagents.add_reagent("protein", 3)
	reagents.add_reagent("capsaicin", 3)
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/popcorn
	name = "Popcorn"
	desc = "Now let's find some cinema."
	icon_state = "popcorn"
	trash = /obj/item/trash/popcorn
	var/unpopped = 0
	filling_color = "#FFFAD4"
	center_of_mass = list("x"=16, "y"=8)
	nutriment_amt = 2
	nutriment_desc = list("popcorn" = 3)


/obj/item/weapon/reagent_containers/food/snacks/popcorn/Initialize()
	. = ..()
	unpopped = rand(1,10)
	bitesize = 0.1 //this snack is supposed to be eating during looooong time. And this it not dinner food! --rastaf0

/obj/item/weapon/reagent_containers/food/snacks/popcorn/On_Consume()
	if(prob(unpopped))	//lol ...what's the point?
		usr << "<font color='red'>You bite down on an un-popped kernel!</font>"
		unpopped = max(0, unpopped-1)
	..()

/obj/item/weapon/reagent_containers/food/snacks/sosjerky
	name = "Scaredy's Private Reserve Beef Jerky"
	icon_state = "sosjerky"
	desc = "Beef jerky made from the finest space cows."
	trash = /obj/item/trash/sosjerky
	filling_color = "#631212"
	center_of_mass = list("x"=15, "y"=9)

/obj/item/weapon/reagent_containers/food/snacks/sosjerky/Initialize()
		..()
		reagents.add_reagent("protein", 4)
		bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/no_raisin
	name = "4no Raisins"
	icon_state = "4no_raisins"
	desc = "Best raisins in the universe. Not sure why."
	trash = /obj/item/trash/raisins
	filling_color = "#343834"
	center_of_mass = list("x"=15, "y"=4)
	nutriment_amt = 6
	nutriment_desc = list("dried raisins" = 6)

/obj/item/weapon/reagent_containers/food/snacks/no_raisin/Initialize()
	..()
	reagents.add_reagent("nutriment", 6)

/obj/item/weapon/reagent_containers/food/snacks/spacetwinkie
	name = "Space Twinkie"
	icon_state = "space_twinkie"
	desc = "Guaranteed to survive longer then you will."
	filling_color = "#FFE591"
	center_of_mass = list("x"=15, "y"=11)

/obj/item/weapon/reagent_containers/food/snacks/spacetwinkie/Initialize()
	. = ..()
	reagents.add_reagent("sugar", 4)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/cheesiehonkers
	name = "Cheesie Honkers"
	icon_state = "cheesie_honkers"
	desc = "Bite sized cheesie snacks that will honk all over your mouth"
	trash = /obj/item/trash/cheesie
	filling_color = "#FFA305"
	center_of_mass = list("x"=15, "y"=9)
	nutriment_amt = 4
	nutriment_desc = list("cheese" = 5, "chips" = 2)

/obj/item/weapon/reagent_containers/food/snacks/cheesiehonkers/Initialize()
	. = ..()
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/syndicake
	name = "Syndi-Cakes"
	icon_state = "syndi_cakes"
	desc = "An extremely moist snack cake that tastes just as good after being nuked."
	filling_color = "#FF5D05"
	center_of_mass = list("x"=16, "y"=10)
	trash = /obj/item/trash/syndi_cakes
	nutriment_amt = 4
	nutriment_desc = list("sweetness" = 3, "cake" = 1)

/obj/item/weapon/reagent_containers/food/snacks/syndicake/Initialize()
	. = ..()
	reagents.add_reagent("doctorsdelight", 5)
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/loadedbakedpotato
	name = "Loaded Baked Potato"
	desc = "Totally baked."
	icon_state = "loadedbakedpotato"
	filling_color = "#9C7A68"
	center_of_mass = list("x"=16, "y"=10)
	nutriment_amt = 3
	nutriment_desc = list("baked potato" = 3)

/obj/item/weapon/reagent_containers/food/snacks/loadedbakedpotato/Initialize()
	. = ..()
	reagents.add_reagent("protein", 3)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/fries
	name = "Space Fries"
	desc = "AKA: French Fries, Freedom Fries, etc."
	icon_state = "fries"
	trash = /obj/item/trash/plate
	filling_color = "#EDDD00"
	center_of_mass = list("x"=16, "y"=11)
	nutriment_amt = 4
	nutriment_desc = list("fresh fries" = 4)

/obj/item/weapon/reagent_containers/food/snacks/fries/Initialize()
	. = ..()
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/mashedpotato
	name = "Mashed Potato"
	desc = "Pillowy mounds of mashed potato."
	icon_state = "mashedpotato"
	trash = /obj/item/trash/plate
	filling_color = "#EDDD00"
	center_of_mass = list("x"=16, "y"=11)
	nutriment_amt = 4
	nutriment_desc = list("fluffy mashed potatoes" = 4)

/obj/item/weapon/reagent_containers/food/snacks/mashedpotato/Initialize()
	. = ..()
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/bangersandmash
	name = "Bangers and Mash"
	desc = "An English treat."
	icon_state = "bangersandmash"
	trash = /obj/item/trash/plate
	filling_color = "#EDDD00"
	center_of_mass = list("x"=16, "y"=11)
	nutriment_amt = 4
	nutriment_desc = list("fluffy potato" = 3, "sausage" = 2)

/obj/item/weapon/reagent_containers/food/snacks/bangersandmash/Initialize()
	. = ..()
	reagents.add_reagent("protein", 3)
	bitesize = 4

/obj/item/weapon/reagent_containers/food/snacks/cheesymash
	name = "Cheesy Mashed Potato"
	desc = "The only thing that could make mash better."
	icon_state = "cheesymash"
	trash = /obj/item/trash/plate
	filling_color = "#EDDD00"
	center_of_mass = list("x"=16, "y"=11)
	nutriment_amt = 4
	nutriment_desc = list("cheesy potato" = 4)

/obj/item/weapon/reagent_containers/food/snacks/cheesymash/Initialize()
	. = ..()
	reagents.add_reagent("protein", 3)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/blackpudding
	name = "Black Pudding"
	desc = "This doesn't seem like a pudding at all."
	icon_state = "blackpudding"
	filling_color = "#FF0000"
	center_of_mass = list("x"=16, "y"=7)

/obj/item/weapon/reagent_containers/food/snacks/blackpudding/Initialize()
	. = ..()
	reagents.add_reagent("protein", 2)
	reagents.add_reagent("blood", 5)
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/soydope
	name = "Soy Dope"
	desc = "Dope from a soy."
	icon_state = "soydope"
	trash = /obj/item/trash/plate
	filling_color = "#C4BF76"
	center_of_mass = list("x"=16, "y"=10)
	nutriment_amt = 2
	nutriment_desc = list("slime" = 2, "soy" = 2)

/obj/item/weapon/reagent_containers/food/snacks/soydope/Initialize()
	. = ..()
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/spagetti
	name = "Spaghetti"
	desc = "A bundle of raw spaghetti."
	icon_state = "spagetti"
	filling_color = "#EDDD00"
	center_of_mass = list("x"=16, "y"=16)
	nutriment_amt = 1
	nutriment_desc = list("noodles" = 2)

/obj/item/weapon/reagent_containers/food/snacks/spagetti/Initialize()
	. = ..()
	bitesize = 1

/obj/item/weapon/reagent_containers/food/snacks/cheesyfries
	name = "Cheesy Fries"
	desc = "Fries. Covered in cheese. Duh."
	icon_state = "cheesyfries"
	trash = /obj/item/trash/plate
	filling_color = "#EDDD00"
	center_of_mass = list("x"=16, "y"=11)
	nutriment_amt = 4
	nutriment_desc = list("fresh fries" = 3, "cheese" = 3)

/obj/item/weapon/reagent_containers/food/snacks/cheesyfries/Initialize()
	. = ..()
	reagents.add_reagent("protein", 2)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/fortunecookie
	name = "Fortune cookie"
	desc = "A true prophecy in each cookie!"
	icon_state = "fortune_cookie"
	filling_color = "#E8E79E"
	center_of_mass = list("x"=15, "y"=14)
	nutriment_amt = 3
	nutriment_desc = list("fortune cookie" = 2)

/obj/item/weapon/reagent_containers/food/snacks/fortunecookie/Initialize()
	. = ..()
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/badrecipe
	name = "Burned mess"
	desc = "Someone should be demoted from chef for this."
	icon_state = "badrecipe"
	filling_color = "#211F02"
	center_of_mass = list("x"=16, "y"=12)

/obj/item/weapon/reagent_containers/food/snacks/badrecipe/Initialize()
	. = ..()
	reagents.add_reagent("toxin", 1)
	reagents.add_reagent("carbon", 3)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/meatsteak
	name = "Meat steak"
	desc = "A piece of hot spicy meat."
	icon_state = "meatstake"
	trash = /obj/item/trash/plate
	filling_color = "#7A3D11"
	center_of_mass = list("x"=16, "y"=13)

/obj/item/weapon/reagent_containers/food/snacks/meatsteak/Initialize()
	. = ..()
	reagents.add_reagent("protein", 4)
	reagents.add_reagent("sodiumchloride", 1)
	reagents.add_reagent("blackpepper", 1)
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/spacylibertyduff
	name = "Spacy Liberty Duff"
	desc = "Jello gelatin, from Alfred Hubbard's cookbook"
	icon_state = "spacylibertyduff"
	trash = /obj/item/trash/snack_bowl
	filling_color = "#42B873"
	center_of_mass = list("x"=16, "y"=8)
	nutriment_amt = 6
	nutriment_desc = list("mushroom" = 6)

/obj/item/weapon/reagent_containers/food/snacks/spacylibertyduff/Initialize()
	. = ..()
	reagents.add_reagent("psilocybin", 6)
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/amanitajelly
	name = "Amanita Jelly"
	desc = "Looks curiously toxic"
	icon_state = "amanitajelly"
	trash = /obj/item/trash/snack_bowl
	filling_color = "#ED0758"
	center_of_mass = list("x"=16, "y"=5)
	nutriment_amt = 6
	nutriment_desc = list("jelly" = 3, "mushroom" = 3)

/obj/item/weapon/reagent_containers/food/snacks/amanitajelly/Initialize()
	. = ..()
	reagents.add_reagent("amatoxin", 6)
	reagents.add_reagent("psilocybin", 3)
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/poppypretzel
	name = "Poppy pretzel"
	desc = "It's all twisted up!"
	icon_state = "poppypretzel"
	bitesize = 2
	filling_color = "#916E36"
	center_of_mass = list("x"=16, "y"=10)
	nutriment_amt = 5
	nutriment_desc = list("poppy seeds" = 2, "pretzel" = 3)

/obj/item/weapon/reagent_containers/food/snacks/poppypretzel/Initialize()
	. = ..()
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/meatballsoup
	name = "Meatball soup"
	desc = "You've got balls kid, BALLS!"
	icon_state = "meatballsoup"
	trash = /obj/item/trash/snack_bowl
	filling_color = "#785210"
	center_of_mass = list("x"=16, "y"=8)

/obj/item/weapon/reagent_containers/food/snacks/meatballsoup/Initialize()
	. = ..()
	reagents.add_reagent("protein", 8)
	reagents.add_reagent("water", 5)
	bitesize = 5

/obj/item/weapon/reagent_containers/food/snacks/slimesoup
	name = "slime soup"
	desc = "If no water is available, you may substitute tears."
	icon_state = "slimesoup" //nonexistant?
	filling_color = "#C4DBA0"

/obj/item/weapon/reagent_containers/food/snacks/slimesoup/Initialize()
	. = ..()
	reagents.add_reagent("slimejelly", 5)
	reagents.add_reagent("water", 10)
	bitesize = 5

/obj/item/weapon/reagent_containers/food/snacks/bloodsoup
	name = "Tomato soup"
	desc = "Smells like copper."
	icon_state = "tomatosoup"
	filling_color = "#FF0000"
	center_of_mass = list("x"=16, "y"=7)

/obj/item/weapon/reagent_containers/food/snacks/bloodsoup/Initialize()
	. = ..()
	reagents.add_reagent("protein", 2)
	reagents.add_reagent("blood", 10)
	reagents.add_reagent("water", 5)
	bitesize = 5

/obj/item/weapon/reagent_containers/food/snacks/clownstears
	name = "Clown's Tears"
	desc = "Not very funny."
	icon_state = "clownstears"
	filling_color = "#C4FBFF"
	center_of_mass = list("x"=16, "y"=7)
	nutriment_amt = 4
	nutriment_desc = list("salt" = 1, "the worst joke" = 3)

/obj/item/weapon/reagent_containers/food/snacks/clownstears/Initialize()
	. = ..()
	reagents.add_reagent("banana", 5)
	reagents.add_reagent("water", 10)
	bitesize = 5

/obj/item/weapon/reagent_containers/food/snacks/vegetablesoup
	name = "Vegetable soup"
	desc = "A true vegan meal" //TODO
	icon_state = "vegetablesoup"
	trash = /obj/item/trash/snack_bowl
	filling_color = "#AFC4B5"
	center_of_mass = list("x"=16, "y"=8)
	nutriment_amt = 8
	nutriment_desc = list("carot" = 2, "corn" = 2, "eggplant" = 2, "potato" = 2)

/obj/item/weapon/reagent_containers/food/snacks/vegetablesoup/Initialize()
	. = ..()
	reagents.add_reagent("water", 5)
	bitesize = 5

/obj/item/weapon/reagent_containers/food/snacks/nettlesoup
	name = "Nettle soup"
	desc = "To think, the botanist would've beat you to death with one of these."
	icon_state = "nettlesoup"
	trash = /obj/item/trash/snack_bowl
	filling_color = "#AFC4B5"
	center_of_mass = list("x"=16, "y"=7)
	nutriment_amt = 8
	nutriment_desc = list("salad" = 4, "egg" = 2, "potato" = 2)

/obj/item/weapon/reagent_containers/food/snacks/nettlesoup/Initialize()
	. = ..()
	reagents.add_reagent("water", 5)
	reagents.add_reagent("tricordrazine", 5)
	bitesize = 5

/obj/item/weapon/reagent_containers/food/snacks/mysterysoup
	name = "Mystery soup"
	desc = "The mystery is, why aren't you eating it?"
	icon_state = "mysterysoup"
	trash = /obj/item/trash/snack_bowl
	filling_color = "#F082FF"
	center_of_mass = list("x"=16, "y"=6)
	nutriment_amt = 1
	nutriment_desc = list("backwash" = 1)

/obj/item/weapon/reagent_containers/food/snacks/mysterysoup/Initialize()
	. = ..()
	var/mysteryselect = pick(1,2,3,4,5,6,7,8,9,10)
	switch(mysteryselect)
		if(1)
			reagents.add_reagent("nutriment", 6)
			reagents.add_reagent("capsaicin", 3)
			reagents.add_reagent("tomatojuice", 2)
		if(2)
			reagents.add_reagent("nutriment", 6)
			reagents.add_reagent("frostoil", 3)
			reagents.add_reagent("tomatojuice", 2)
		if(3)
			reagents.add_reagent("nutriment", 5)
			reagents.add_reagent("water", 5)
			reagents.add_reagent("tricordrazine", 5)
		if(4)
			reagents.add_reagent("nutriment", 5)
			reagents.add_reagent("water", 10)
		if(5)
			reagents.add_reagent("nutriment", 2)
			reagents.add_reagent("banana", 10)
		if(6)
			reagents.add_reagent("nutriment", 6)
			reagents.add_reagent("blood", 10)
		if(7)
			reagents.add_reagent("slimejelly", 10)
			reagents.add_reagent("water", 10)
		if(8)
			reagents.add_reagent("carbon", 10)
			reagents.add_reagent("toxin", 10)
		if(9)
			reagents.add_reagent("nutriment", 5)
			reagents.add_reagent("tomatojuice", 10)
		if(10)
			reagents.add_reagent("nutriment", 6)
			reagents.add_reagent("tomatojuice", 5)
			reagents.add_reagent("imidazoline", 5)
	bitesize = 5

/obj/item/weapon/reagent_containers/food/snacks/wishsoup
	name = "Wish Soup"
	desc = "I wish this was soup."
	icon_state = "wishsoup"
	trash = /obj/item/trash/snack_bowl
	filling_color = "#D1F4FF"
	center_of_mass = list("x"=16, "y"=11)

/obj/item/weapon/reagent_containers/food/snacks/wishsoup/Initialize()
	. = ..()
	reagents.add_reagent("water", 10)
	bitesize = 5
	if(prob(25))
		src.desc = "A wish come true!"
		reagents.add_reagent("nutriment", 8, list("something good" = 8))

/obj/item/weapon/reagent_containers/food/snacks/hotchili
	name = "Hot Chili"
	desc = "A five alarm Texan Chili!"
	icon_state = "hotchili"
	trash = /obj/item/trash/snack_bowl
	filling_color = "#FF3C00"
	center_of_mass = list("x"=15, "y"=9)
	nutriment_amt = 3
	nutriment_desc = list("chilli peppers" = 3)

/obj/item/weapon/reagent_containers/food/snacks/hotchili/Initialize()
	. = ..()
	reagents.add_reagent("protein", 3)
	reagents.add_reagent("capsaicin", 3)
	reagents.add_reagent("tomatojuice", 2)
	bitesize = 5

/obj/item/weapon/reagent_containers/food/snacks/coldchili
	name = "Cold Chili"
	desc = "This slush is barely a liquid!"
	icon_state = "coldchili"
	filling_color = "#2B00FF"
	center_of_mass = list("x"=15, "y"=9)
	trash = /obj/item/trash/snack_bowl
	nutriment_amt = 3
	nutriment_desc = list("ice peppers" = 3)

/obj/item/weapon/reagent_containers/food/snacks/coldchili/Initialize()
	. = ..()
	reagents.add_reagent("protein", 3)
	reagents.add_reagent("frostoil", 3)
	reagents.add_reagent("tomatojuice", 2)
	bitesize = 5

/obj/item/weapon/reagent_containers/food/snacks/monkeycube
	name = "monkey cube"
	desc = "Just add water!"
	flags = OPENCONTAINER
	icon_state = "monkeycube"
	bitesize = 12
	filling_color = "#ADAC7F"
	center_of_mass = list("x"=16, "y"=14)

	var/wrapped = 0
	var/monkey_type = "Monkey"

/obj/item/weapon/reagent_containers/food/snacks/monkeycube/Initialize()
	. = ..()
	reagents.add_reagent("protein", 10)

/obj/item/weapon/reagent_containers/food/snacks/monkeycube/attack_self(mob/user as mob)
	if(wrapped)
		Unwrap(user)

/obj/item/weapon/reagent_containers/food/snacks/monkeycube/proc/Expand()
	src.visible_message("<span class='notice'>\The [src] expands!</span>")
	var/mob/living/carbon/human/H = new(get_turf(src))
	H.set_species(monkey_type)
	H.real_name = H.species.get_random_name()
	H.name = H.real_name
	if(ismob(loc))
		var/mob/M = loc
		M.unEquip(src)
	qdel(src)
	return 1

/obj/item/weapon/reagent_containers/food/snacks/monkeycube/proc/Unwrap(mob/user as mob)
	icon_state = "monkeycube"
	desc = "Just add water!"
	to_chat(user, "You unwrap the cube.")
	wrapped = 0
	flags |= OPENCONTAINER
	return

/obj/item/weapon/reagent_containers/food/snacks/monkeycube/On_Consume(var/mob/M)
	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		H.visible_message("<span class='warning'>A screeching creature bursts out of [M]'s chest!</span>")
		var/obj/item/organ/external/organ = H.get_organ(BP_TORSO)
		organ.take_damage(50, 0, 0, "Animal escaping the ribcage")
	Expand()

/obj/item/weapon/reagent_containers/food/snacks/monkeycube/on_reagent_change()
	if(reagents.has_reagent("water"))
		Expand()

/obj/item/weapon/reagent_containers/food/snacks/monkeycube/wrapped
	desc = "Still wrapped in some paper."
	icon_state = "monkeycubewrap"
	flags = 0
	wrapped = 1

/obj/item/weapon/reagent_containers/food/snacks/monkeycube/farwacube
	name = "farwa cube"
	monkey_type = "Farwa"

/obj/item/weapon/reagent_containers/food/snacks/monkeycube/wrapped/farwacube
	name = "farwa cube"
	monkey_type = "Farwa"

/obj/item/weapon/reagent_containers/food/snacks/monkeycube/stokcube
	name = "stok cube"
	monkey_type = "Stok"

/obj/item/weapon/reagent_containers/food/snacks/monkeycube/wrapped/stokcube
	name = "stok cube"
	monkey_type = "Stok"

/obj/item/weapon/reagent_containers/food/snacks/monkeycube/neaeracube
	name = "neaera cube"
	monkey_type = "Neaera"

/obj/item/weapon/reagent_containers/food/snacks/monkeycube/wrapped/neaeracube
	name = "neaera cube"
	monkey_type = "Neaera"

/obj/item/weapon/reagent_containers/food/snacks/spellburger
	name = "Spell Burger"
	desc = "This is absolutely Ei Nath."
	icon_state = "spellburger"
	filling_color = "#D505FF"
	nutriment_amt = 6
	nutriment_desc = list("magic" = 3, "buns" = 3)

/obj/item/weapon/reagent_containers/food/snacks/spellburger/Initialize()
	. = ..()
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/bigbiteburger
	name = "Big Bite Burger"
	desc = "Forget the Big Mac. THIS is the future!"
	icon_state = "bigbiteburger"
	filling_color = "#E3D681"
	center_of_mass = list("x"=16, "y"=11)
	nutriment_amt = 4
	nutriment_desc = list("buns" = 4)

/obj/item/weapon/reagent_containers/food/snacks/bigbiteburger/Initialize()
	. = ..()
	reagents.add_reagent("protein", 10)
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/enchiladas
	name = "Enchiladas"
	desc = "Viva La Mexico!"
	icon_state = "enchiladas"
	trash = /obj/item/trash/tray
	filling_color = "#A36A1F"
	center_of_mass = list("x"=16, "y"=13)
	nutriment_amt = 2
	nutriment_desc = list("tortilla" = 3, "corn" = 3)

/obj/item/weapon/reagent_containers/food/snacks/enchiladas/Initialize()
	. = ..()
	reagents.add_reagent("protein", 6)
	reagents.add_reagent("capsaicin", 6)
	bitesize = 4

/obj/item/weapon/reagent_containers/food/snacks/monkeysdelight
	name = "monkey's Delight"
	desc = "Eeee Eee!"
	icon_state = "monkeysdelight"
	trash = /obj/item/trash/tray
	filling_color = "#5C3C11"
	center_of_mass = list("x"=16, "y"=13)

/obj/item/weapon/reagent_containers/food/snacks/monkeysdelight/Initialize()
	. = ..()
	reagents.add_reagent("protein", 10)
	reagents.add_reagent("banana", 5)
	reagents.add_reagent("blackpepper", 1)
	reagents.add_reagent("sodiumchloride", 1)
	bitesize = 6

/obj/item/weapon/reagent_containers/food/snacks/baguette
	name = "Baguette"
	desc = "Bon appetit!"
	icon_state = "baguette"
	filling_color = "#E3D796"
	center_of_mass = list("x"=18, "y"=12)
	nutriment_amt = 6
	nutriment_desc = list("french bread" = 6)

/obj/item/weapon/reagent_containers/food/snacks/baguette/Initialize()
	. = ..()
	reagents.add_reagent("blackpepper", 1)
	reagents.add_reagent("sodiumchloride", 1)
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/fishandchips
	name = "Fish and Chips"
	desc = "I do say so myself chap."
	icon_state = "fishandchips"
	filling_color = "#E3D796"
	center_of_mass = list("x"=16, "y"=16)
	nutriment_amt = 3
	nutriment_desc = list("salt" = 1, "chips" = 3)

/obj/item/weapon/reagent_containers/food/snacks/fishandchips/Initialize()
	. = ..()
	reagents.add_reagent("protein", 3)
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/sandwich
	name = "Sandwich"
	desc = "A grand creation of meat, cheese, bread, and several leaves of lettuce! Arthur Dent would be proud."
	icon_state = "sandwich"
	trash = /obj/item/trash/plate
	filling_color = "#D9BE29"
	center_of_mass = list("x"=16, "y"=4)
	nutriment_amt = 3
	nutriment_desc = list("bread" = 3, "cheese" = 3)

/obj/item/weapon/reagent_containers/food/snacks/sandwich/Initialize()
	. = ..()
	reagents.add_reagent("protein", 3)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/toastedsandwich
	name = "Toasted Sandwich"
	desc = "Now if you only had a pepper bar."
	icon_state = "toastedsandwich"
	trash = /obj/item/trash/plate
	filling_color = "#D9BE29"
	center_of_mass = list("x"=16, "y"=4)
	nutriment_amt = 3
	nutriment_desc = list("toasted bread" = 3, "cheese" = 3)

/obj/item/weapon/reagent_containers/food/snacks/toastedsandwich/Initialize()
	. = ..()
	reagents.add_reagent("protein", 3)
	reagents.add_reagent("carbon", 2)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/grilledcheese
	name = "Grilled Cheese Sandwich"
	desc = "Goes great with Tomato soup!"
	icon_state = "toastedsandwich"
	trash = /obj/item/trash/plate
	filling_color = "#D9BE29"
	nutriment_amt = 3
	nutriment_desc = list("toasted bread" = 3, "cheese" = 3)

/obj/item/weapon/reagent_containers/food/snacks/grilledcheese/Initialize()
	. = ..()
	reagents.add_reagent("protein", 4)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/tomatosoup
	name = "Tomato Soup"
	desc = "Drinking this feels like being a vampire! A tomato vampire..."
	icon_state = "tomatosoup"
	trash = /obj/item/trash/snack_bowl
	filling_color = "#D92929"
	center_of_mass = list("x"=16, "y"=7)
	nutriment_amt = 5
	nutriment_desc = list("soup" = 5)

/obj/item/weapon/reagent_containers/food/snacks/tomatosoup/Initialize()
	. = ..()
	reagents.add_reagent("tomatojuice", 10)
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/onionsoup
	name = "Onion Soup"
	desc = "A soup with layers."
	icon_state = "onionsoup"
	trash = /obj/item/trash/snack_bowl
	filling_color = "#E0C367"
	center_of_mass = list("x"=16, "y"=7)
	nutriment_amt = 5
	nutriment_desc = list("onion" = 2, "soup" = 2)

/obj/item/weapon/reagent_containers/food/snacks/onionsoup/Initialize()
	. = ..()
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/onionrings
	name = "Onion Rings"
	desc = "Crispy rings."
	icon_state = "onionrings"
	trash = /obj/item/trash/plate
	filling_color = "#E0C367"
	center_of_mass = list("x"=16, "y"=7)
	nutriment_amt = 5
	nutriment_desc = list("onion" = 2)

/obj/item/weapon/reagent_containers/food/snacks/onionrings/Initialize()
	. = ..()
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/rofflewaffles
	name = "Roffle Waffles"
	desc = "Waffles from Roffle. Co."
	icon_state = "rofflewaffles"
	trash = /obj/item/trash/waffles
	filling_color = "#FF00F7"
	center_of_mass = list("x"=15, "y"=11)
	nutriment_amt = 8
	nutriment_desc = list("waffle" = 7, "sweetness" = 1)

/obj/item/weapon/reagent_containers/food/snacks/rofflewaffles/Initialize()
	. = ..()
	reagents.add_reagent("psilocybin", 8)
	bitesize = 4

/obj/item/weapon/reagent_containers/food/snacks/stew
	name = "Stew"
	desc = "A nice and warm stew. Healthy and strong."
	icon_state = "stew"
	filling_color = "#9E673A"
	center_of_mass = list("x"=16, "y"=5)
	nutriment_amt = 6
	nutriment_desc = list("tomato" = 2, "potato" = 2, "carrot" = 2, "eggplant" = 2, "mushroom" = 2)

/obj/item/weapon/reagent_containers/food/snacks/stew/Initialize()
	. = ..()
	reagents.add_reagent("protein", 4)
	reagents.add_reagent("tomatojuice", 5)
	reagents.add_reagent("imidazoline", 5)
	reagents.add_reagent("water", 5)
	bitesize = 10

/obj/item/weapon/reagent_containers/food/snacks/jelliedtoast
	name = "Jellied Toast"
	desc = "A slice of bread covered with delicious jam."
	icon_state = "jellytoast"
	trash = /obj/item/trash/plate
	filling_color = "#B572AB"
	center_of_mass = list("x"=16, "y"=8)
	nutriment_amt = 1
	nutriment_desc = list("toasted bread" = 2)

/obj/item/weapon/reagent_containers/food/snacks/jelliedtoast/Initialize()
	. = ..()
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/jelliedtoast/cherry/Initialize()
	. = ..()
	reagents.add_reagent("cherryjelly", 5)

/obj/item/weapon/reagent_containers/food/snacks/jelliedtoast/slime/Initialize()
	. = ..()
	reagents.add_reagent("slimejelly", 5)

/obj/item/weapon/reagent_containers/food/snacks/jellyburger
	name = "Jelly Burger"
	desc = "Culinary delight..?"
	icon_state = "jellyburger"
	filling_color = "#B572AB"
	center_of_mass = list("x"=16, "y"=11)
	nutriment_amt = 5
	nutriment_desc = list("buns" = 5)

/obj/item/weapon/reagent_containers/food/snacks/jellyburger/Initialize()
	. = ..()
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/jellyburger/slime/Initialize()
	. = ..()
	reagents.add_reagent("slimejelly", 5)

/obj/item/weapon/reagent_containers/food/snacks/jellyburger/cherry/Initialize()
	. = ..()
	reagents.add_reagent("cherryjelly", 5)

/obj/item/weapon/reagent_containers/food/snacks/milosoup
	name = "Milosoup"
	desc = "The universes best soup! Yum!!!"
	icon_state = "milosoup"
	trash = /obj/item/trash/snack_bowl
	center_of_mass = list("x"=16, "y"=7)
	nutriment_amt = 8
	nutriment_desc = list("soy" = 8)

/obj/item/weapon/reagent_containers/food/snacks/milosoup/Initialize()
	. = ..()
	reagents.add_reagent("water", 5)
	bitesize = 4

/obj/item/weapon/reagent_containers/food/snacks/stewedsoymeat
	name = "Stewed Soy Meat"
	desc = "Even non-vegetarians will LOVE this!"
	icon_state = "stewedsoymeat"
	trash = /obj/item/trash/plate
	center_of_mass = list("x"=16, "y"=10)
	nutriment_amt = 8
	nutriment_desc = list("soy" = 4, "tomato" = 4)

/obj/item/weapon/reagent_containers/food/snacks/stewedsoymeat/Initialize()
	. = ..()
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/boiledspagetti
	name = "Boiled Spaghetti"
	desc = "A plain dish of noodles, this sucks."
	icon_state = "spagettiboiled"
	trash = /obj/item/trash/plate
	filling_color = "#FCEE81"
	center_of_mass = list("x"=16, "y"=10)
	nutriment_amt = 2
	nutriment_desc = list("noodles" = 2)

/obj/item/weapon/reagent_containers/food/snacks/boiledspagetti/Initialize()
	. = ..()
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/boiledrice
	name = "Boiled Rice"
	desc = "A boring dish of boring rice."
	icon_state = "boiledrice"
	trash = /obj/item/trash/snack_bowl
	filling_color = "#FFFBDB"
	center_of_mass = list("x"=17, "y"=11)
	nutriment_amt = 2
	nutriment_desc = list("rice" = 2)

/obj/item/weapon/reagent_containers/food/snacks/boiledrice/Initialize()
	. = ..()
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/ricepudding
	name = "Rice Pudding"
	desc = "Where's the jam?"
	icon_state = "rpudding"
	trash = /obj/item/trash/snack_bowl
	filling_color = "#FFFBDB"
	center_of_mass = list("x"=17, "y"=11)
	nutriment_amt = 4
	nutriment_desc = list("rice" = 2)

/obj/item/weapon/reagent_containers/food/snacks/ricepudding/Initialize()
	. = ..()
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/kudzudonburi
	name = "Zhan-Kudzu Overtaker"
	desc = "Seasoned Kudzu and fish donburi."
	icon_state = "kudzudonburi"
	trash = /obj/item/trash/snack_bowl
	filling_color = "#FFFBDB"
	center_of_mass = list("x"=17, "y"=11)
	nutriment_amt = 16
	nutriment_desc = list("rice" = 2, "gauze" = 4, "fish" = 10)

/obj/item/weapon/reagent_containers/food/snacks/kudzudonburi/Initialize()
	. = ..()
	reagents.add_reagent("protein", 4)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/pastatomato
	name = "Spaghetti"
	desc = "Spaghetti and crushed tomatoes. Just like your abusive father used to make!"
	icon_state = "pastatomato"
	trash = /obj/item/trash/plate
	filling_color = "#DE4545"
	center_of_mass = list("x"=16, "y"=10)
	nutriment_amt = 6
	nutriment_desc = list("tomato" = 3, "noodles" = 3)

/obj/item/weapon/reagent_containers/food/snacks/pastatomato/Initialize()
	. = ..()
	reagents.add_reagent("tomatojuice", 10)
	bitesize = 4

/obj/item/weapon/reagent_containers/food/snacks/meatballspagetti
	name = "Spaghetti & Meatballs"
	desc = "Now thats a nic'e meatball!"
	icon_state = "meatballspagetti"
	trash = /obj/item/trash/plate
	filling_color = "#DE4545"
	center_of_mass = list("x"=16, "y"=10)
	nutriment_amt = 4
	nutriment_desc = list("noodles" = 4)

/obj/item/weapon/reagent_containers/food/snacks/meatballspagetti/Initialize()
	. = ..()
	reagents.add_reagent("protein", 4)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/spesslaw
	name = "Spesslaw"
	desc = "A lawyers favourite"
	icon_state = "spesslaw"
	filling_color = "#DE4545"
	center_of_mass = list("x"=16, "y"=10)
	nutriment_amt = 4
	nutriment_desc = list("noodles" = 4)

/obj/item/weapon/reagent_containers/food/snacks/spesslaw/Initialize()
	. = ..()
	reagents.add_reagent("protein", 4)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/carrotfries
	name = "Carrot Fries"
	desc = "Tasty fries from fresh Carrots."
	icon_state = "carrotfries"
	trash = /obj/item/trash/plate
	filling_color = "#FAA005"
	center_of_mass = list("x"=16, "y"=11)
	nutriment_amt = 3
	nutriment_desc = list("carrot" = 3, "salt" = 1)

/obj/item/weapon/reagent_containers/food/snacks/carrotfries/Initialize()
	. = ..()
	reagents.add_reagent("imidazoline", 3)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/superbiteburger
	name = "Super Bite Burger"
	desc = "This is a mountain of a burger. FOOD!"
	icon_state = "superbiteburger"
	filling_color = "#CCA26A"
	center_of_mass = list("x"=16, "y"=3)
	nutriment_amt = 25
	nutriment_desc = list("buns" = 25)

/obj/item/weapon/reagent_containers/food/snacks/superbiteburger/Initialize()
	. = ..()
	reagents.add_reagent("protein", 25)
	bitesize = 10

/obj/item/weapon/reagent_containers/food/snacks/candiedapple
	name = "Candied Apple"
	desc = "An apple coated in sugary sweetness."
	icon_state = "candiedapple"
	filling_color = "#F21873"
	center_of_mass = list("x"=15, "y"=13)
	nutriment_amt = 3
	nutriment_desc = list("apple" = 3, "caramel" = 3, "sweetness" = 2)

/obj/item/weapon/reagent_containers/food/snacks/candiedapple/Initialize()
	. = ..()
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/applepie
	name = "Apple Pie"
	desc = "A pie containing sweet sweet love... or apple."
	icon_state = "applepie"
	filling_color = "#E0EDC5"
	center_of_mass = list("x"=16, "y"=13)
	nutriment_amt = 4
	nutriment_desc = list("sweetness" = 2, "apple" = 2, "pie" = 2)

/obj/item/weapon/reagent_containers/food/snacks/applepie/Initialize()
	. = ..()
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/cherrypie
	name = "Cherry Pie"
	desc = "Taste so good, make a grown man cry."
	icon_state = "cherrypie"
	filling_color = "#FF525A"
	center_of_mass = list("x"=16, "y"=11)
	nutriment_amt = 4
	nutriment_desc = list("sweetness" = 2, "cherry" = 2, "pie" = 2)

/obj/item/weapon/reagent_containers/food/snacks/cherrypie/Initialize()
	. = ..()
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/twobread
	name = "Two Bread"
	desc = "It is very bitter and winy."
	icon_state = "twobread"
	filling_color = "#DBCC9A"
	center_of_mass = list("x"=15, "y"=12)
	nutriment_amt = 2
	nutriment_desc = list("sourness" = 2, "bread" = 2)

/obj/item/weapon/reagent_containers/food/snacks/twobread/Initialize()
	. = ..()
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/jellysandwich
	name = "Jelly Sandwich"
	desc = "You wish you had some peanut butter to go with this..."
	icon_state = "jellysandwich"
	trash = /obj/item/trash/plate
	filling_color = "#9E3A78"
	center_of_mass = list("x"=16, "y"=8)
	nutriment_amt = 2
	nutriment_desc = list("bread" = 2)

/obj/item/weapon/reagent_containers/food/snacks/jellysandwich/Initialize()
	. = ..()
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/jellysandwich/slime/Initialize()
	. = ..()
	reagents.add_reagent("slimejelly", 5)

/obj/item/weapon/reagent_containers/food/snacks/jellysandwich/cherry/Initialize()
	. = ..()
	reagents.add_reagent("cherryjelly", 5)

/obj/item/weapon/reagent_containers/food/snacks/jellysandwich/peanutbutter
	desc = "You wish you had some peanut butter to go with this... Oh wait!"
	icon_state = "pbandj"

/obj/item/weapon/reagent_containers/food/snacks/jellysandwich/peanutbutter/Initialize()
	. = ..()
	reagents.add_reagent("peanutbutter", 5)

/obj/item/weapon/reagent_containers/food/snacks/boiledslimecore
	name = "Boiled slime Core"
	desc = "A boiled red thing."
	icon_state = "boiledslimecore" //nonexistant?

/obj/item/weapon/reagent_containers/food/snacks/boiledslimecore/Initialize()
	. = ..()
	reagents.add_reagent("slimejelly", 5)
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/mint
	name = "mint"
	desc = "it is only wafer thin."
	icon_state = "mint"
	filling_color = "#F2F2F2"
	center_of_mass = list("x"=16, "y"=14)

/obj/item/weapon/reagent_containers/food/snacks/mint/Initialize()
	. = ..()
	reagents.add_reagent("mint", 1)
	bitesize = 1

/obj/item/weapon/reagent_containers/food/snacks/mushroomsoup
	name = "chantrelle soup"
	desc = "A delicious and hearty mushroom soup."
	icon_state = "mushroomsoup"
	trash = /obj/item/trash/snack_bowl
	filling_color = "#E386BF"
	center_of_mass = list("x"=17, "y"=10)
	nutriment_amt = 8
	nutriment_desc = list("mushroom" = 8, "milk" = 2)

/obj/item/weapon/reagent_containers/food/snacks/mushroomsoup/Initialize()
	. = ..()
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/plumphelmetbiscuit
	name = "plump helmet biscuit"
	desc = "This is a finely-prepared plump helmet biscuit. The ingredients are exceptionally minced plump helmet, and well-minced dwarven wheat flour."
	icon_state = "phelmbiscuit"
	filling_color = "#CFB4C4"
	center_of_mass = list("x"=16, "y"=13)
	nutriment_amt = 5
	nutriment_desc = list("mushroom" = 4)

/obj/item/weapon/reagent_containers/food/snacks/plumphelmetbiscuit/Initialize()
	. = ..()
	if(prob(10))
		name = "exceptional plump helmet biscuit"
		desc = "Microwave is taken by a fey mood! It has cooked an exceptional plump helmet biscuit!"
		reagents.add_reagent("nutriment", 8)
		bitesize = 2
	else
		reagents.add_reagent("nutriment", 5)
		bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/chawanmushi
	name = "chawanmushi"
	desc = "A legendary egg custard that makes friends out of enemies. Probably too hot for a cat to eat."
	icon_state = "chawanmushi"
	trash = /obj/item/trash/snack_bowl
	filling_color = "#F0F2E4"
	center_of_mass = list("x"=17, "y"=10)

/obj/item/weapon/reagent_containers/food/snacks/chawanmushi/Initialize()
	. = ..()
	reagents.add_reagent("protein", 5)
	bitesize = 1

/obj/item/weapon/reagent_containers/food/snacks/beetsoup
	name = "beet soup"
	desc = "Wait, how do you spell it again..?"
	icon_state = "beetsoup"
	trash = /obj/item/trash/snack_bowl
	filling_color = "#FAC9FF"
	center_of_mass = list("x"=15, "y"=8)
	nutriment_amt = 8
	nutriment_desc = list("tomato" = 4, "beet" = 4)

/obj/item/weapon/reagent_containers/food/snacks/beetsoup/Initialize()
	. = ..()
	name = pick(list("borsch","bortsch","borstch","borsh","borshch","borscht"))
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/tossedsalad
	name = "tossed salad"
	desc = "A proper salad, basic and simple, with little bits of carrot, tomato and apple intermingled. Vegan!"
	icon_state = "herbsalad"
	trash = /obj/item/trash/snack_bowl
	filling_color = "#76B87F"
	center_of_mass = list("x"=17, "y"=11)
	nutriment_amt = 8
	nutriment_desc = list("salad" = 2, "tomato" = 2, "carrot" = 2, "apple" = 2)

/obj/item/weapon/reagent_containers/food/snacks/tossedsalad/Initialize()
	. = ..()
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/validsalad
	name = "valid salad"
	desc = "It's just a salad of questionable 'herbs' with meatballs and fried potato slices. Nothing suspicious about it."
	icon_state = "validsalad"
	trash = /obj/item/trash/snack_bowl
	filling_color = "#76B87F"
	center_of_mass = list("x"=17, "y"=11)
	nutriment_amt = 6
	nutriment_desc = list("100% real salad")

/obj/item/weapon/reagent_containers/food/snacks/validsalad/Initialize()
	. = ..()
	reagents.add_reagent("protein", 2)
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/appletart
	name = "golden apple streusel tart"
	desc = "A tasty dessert that won't make it through a metal detector."
	icon_state = "gappletart"
	trash = /obj/item/trash/plate
	filling_color = "#FFFF00"
	center_of_mass = list("x"=16, "y"=18)
	nutriment_amt = 8
	nutriment_desc = list("apple" = 8)

/obj/item/weapon/reagent_containers/food/snacks/appletart/Initialize()
	. = ..()
	reagents.add_reagent("gold", 5)
	bitesize = 3

/////////////////////////////////////////////////Sliceable////////////////////////////////////////
// All the food items that can be sliced into smaller bits like Meatbread and Cheesewheels

// sliceable is just an organization type path, it doesn't have any additional code or variables tied to it.

/obj/item/weapon/reagent_containers/food/snacks/sliceable
	w_class = ITEMSIZE_NORMAL //Whole pizzas and cakes shouldn't fit in a pocket, you can slice them if you want to do that.

/**
 *  A food item slice
 *
 *  This path contains some extra code for spawning slices pre-filled with
 *  reagents.
 */
/obj/item/weapon/reagent_containers/food/snacks/slice
	name = "slice of... something"
	var/whole_path  // path for the item from which this slice comes
	var/filled = FALSE  // should the slice spawn with any reagents

/**
 *  Spawn a new slice of food
 *
 *  If the slice's filled is TRUE, this will also fill the slice with the
 *  appropriate amount of reagents. Note that this is done by spawning a new
 *  whole item, transferring the reagents and deleting the whole item, which may
 *  have performance implications.
 */
/obj/item/weapon/reagent_containers/food/snacks/slice/Initialize()
	. = ..()
	if(filled)
		var/obj/item/weapon/reagent_containers/food/snacks/whole = new whole_path()
		if(whole && whole.slices_num)
			var/reagent_amount = whole.reagents.total_volume/whole.slices_num
			whole.reagents.trans_to_obj(src, reagent_amount)

		qdel(whole)

/obj/item/weapon/reagent_containers/food/snacks/sliceable/meatbread
	name = "meatbread loaf"
	desc = "The culinary base of every self-respecting eloquent gentleman."
	icon_state = "meatbread"
	slice_path = /obj/item/weapon/reagent_containers/food/snacks/slice/meatbread
	slices_num = 5
	filling_color = "#FF7575"
	center_of_mass = list("x"=19, "y"=9)
	nutriment_desc = list("bread" = 10)
	nutriment_amt = 10

/obj/item/weapon/reagent_containers/food/snacks/sliceable/meatbread/Initialize()
	. = ..()
	reagents.add_reagent("protein", 20)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/slice/meatbread
	name = "meatbread slice"
	desc = "A slice of delicious meatbread."
	icon_state = "meatbreadslice"
	trash = /obj/item/trash/plate
	filling_color = "#FF7575"
	bitesize = 2
	center_of_mass = list("x"=16, "y"=16)
	whole_path = /obj/item/weapon/reagent_containers/food/snacks/sliceable/meatbread

/obj/item/weapon/reagent_containers/food/snacks/slice/meatbread/filled
	filled = TRUE

/obj/item/weapon/reagent_containers/food/snacks/sliceable/xenomeatbread
	name = "xenomeatbread loaf"
	desc = "The culinary base of every self-respecting eloquent gentleman. Extra Heretical."
	icon_state = "xenomeatbread"
	slice_path = /obj/item/weapon/reagent_containers/food/snacks/slice/xenomeatbread
	slices_num = 5
	filling_color = "#8AFF75"
	center_of_mass = list("x"=16, "y"=9)
	nutriment_desc = list("bread" = 10)
	nutriment_amt = 10

/obj/item/weapon/reagent_containers/food/snacks/sliceable/xenomeatbread/Initialize()
	. = ..()
	reagents.add_reagent("protein", 20)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/slice/xenomeatbread
	name = "xenomeatbread slice"
	desc = "A slice of delicious meatbread. Extra Heretical."
	icon_state = "xenobreadslice"
	trash = /obj/item/trash/plate
	filling_color = "#8AFF75"
	bitesize = 2
	center_of_mass = list("x"=16, "y"=13)
	whole_path = /obj/item/weapon/reagent_containers/food/snacks/sliceable/xenomeatbread


/obj/item/weapon/reagent_containers/food/snacks/slice/xenomeatbread/filled
	filled = TRUE

/obj/item/weapon/reagent_containers/food/snacks/sliceable/bananabread
	name = "Banana-nut bread"
	desc = "A heavenly and filling treat."
	icon_state = "bananabread"
	slice_path = /obj/item/weapon/reagent_containers/food/snacks/slice/bananabread
	slices_num = 5
	filling_color = "#EDE5AD"
	center_of_mass = list("x"=16, "y"=9)
	nutriment_desc = list("bread" = 10)
	nutriment_amt = 10

/obj/item/weapon/reagent_containers/food/snacks/sliceable/bananabread/Initialize()
	. = ..()
	reagents.add_reagent("banana", 20)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/slice/bananabread
	name = "Banana-nut bread slice"
	desc = "A slice of delicious banana bread."
	icon_state = "bananabreadslice"
	trash = /obj/item/trash/plate
	filling_color = "#EDE5AD"
	bitesize = 2
	center_of_mass = list("x"=16, "y"=8)
	whole_path = /obj/item/weapon/reagent_containers/food/snacks/sliceable/bananabread

/obj/item/weapon/reagent_containers/food/snacks/slice/bananabread/filled
	filled = TRUE

/obj/item/weapon/reagent_containers/food/snacks/sliceable/tofubread
	name = "Tofubread"
	icon_state = "Like meatbread but for vegetarians. Not guaranteed to give superpowers."
	icon_state = "tofubread"
	slice_path = /obj/item/weapon/reagent_containers/food/snacks/slice/tofubread
	slices_num = 5
	filling_color = "#F7FFE0"
	center_of_mass = list("x"=16, "y"=9)
	nutriment_desc = list("tofu" = 10)
	nutriment_amt = 10

/obj/item/weapon/reagent_containers/food/snacks/sliceable/tofubread/Initialize()
	. = ..()
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/slice/tofubread
	name = "Tofubread slice"
	desc = "A slice of delicious tofubread."
	icon_state = "tofubreadslice"
	trash = /obj/item/trash/plate
	filling_color = "#F7FFE0"
	bitesize = 2
	center_of_mass = list("x"=16, "y"=13)
	whole_path = /obj/item/weapon/reagent_containers/food/snacks/sliceable/tofubread

/obj/item/weapon/reagent_containers/food/snacks/slice/tofubread/filled
	filled = TRUE


/obj/item/weapon/reagent_containers/food/snacks/sliceable/carrotcake
	name = "Carrot Cake"
	desc = "A favorite desert of a certain wascally wabbit. Not a lie."
	icon_state = "carrotcake"
	slice_path = /obj/item/weapon/reagent_containers/food/snacks/slice/carrotcake
	slices_num = 5
	filling_color = "#FFD675"
	center_of_mass = list("x"=16, "y"=10)
	nutriment_desc = list("cake" = 10, "sweetness" = 10, "carrot" = 15)
	nutriment_amt = 25

/obj/item/weapon/reagent_containers/food/snacks/sliceable/carrotcake/Initialize()
	. = ..()
	reagents.add_reagent("imidazoline", 10)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/slice/carrotcake
	name = "Carrot Cake slice"
	desc = "Carrotty slice of Carrot Cake, carrots are good for your eyes! Also not a lie."
	icon_state = "carrotcake_slice"
	trash = /obj/item/trash/plate
	filling_color = "#FFD675"
	bitesize = 2
	center_of_mass = list("x"=16, "y"=14)
	whole_path = /obj/item/weapon/reagent_containers/food/snacks/sliceable/carrotcake

/obj/item/weapon/reagent_containers/food/snacks/slice/carrotcake/filled
	filled = TRUE

/obj/item/weapon/reagent_containers/food/snacks/sliceable/braincake
	name = "Brain Cake"
	desc = "A squishy cake-thing."
	icon_state = "braincake"
	slice_path = /obj/item/weapon/reagent_containers/food/snacks/slice/braincake
	slices_num = 5
	filling_color = "#E6AEDB"
	center_of_mass = list("x"=16, "y"=10)
	nutriment_desc = list("cake" = 10, "sweetness" = 10, "slime" = 15)
	nutriment_amt = 5

/obj/item/weapon/reagent_containers/food/snacks/sliceable/braincake/Initialize()
	. = ..()
	reagents.add_reagent("protein", 25)
	reagents.add_reagent("alkysine", 10)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/slice/braincake
	name = "Brain Cake slice"
	desc = "Lemme tell you something about prions. THEY'RE DELICIOUS."
	icon_state = "braincakeslice"
	trash = /obj/item/trash/plate
	filling_color = "#E6AEDB"
	bitesize = 2
	center_of_mass = list("x"=16, "y"=12)
	whole_path = /obj/item/weapon/reagent_containers/food/snacks/sliceable/braincake

/obj/item/weapon/reagent_containers/food/snacks/slice/braincake/filled
	filled = TRUE

/obj/item/weapon/reagent_containers/food/snacks/sliceable/cheesecake
	name = "Cheese Cake"
	desc = "DANGEROUSLY cheesy."
	icon_state = "cheesecake"
	slice_path = /obj/item/weapon/reagent_containers/food/snacks/slice/cheesecake
	slices_num = 5
	filling_color = "#FAF7AF"
	center_of_mass = list("x"=16, "y"=10)
	nutriment_desc = list("cake" = 10, "cream" = 10, "cheese" = 15)
	nutriment_amt = 10

/obj/item/weapon/reagent_containers/food/snacks/sliceable/cheesecake/Initialize()
	. = ..()
	reagents.add_reagent("protein", 15)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/slice/cheesecake
	name = "Cheese Cake slice"
	desc = "Slice of pure cheestisfaction."
	icon_state = "cheesecake_slice"
	trash = /obj/item/trash/plate
	filling_color = "#FAF7AF"
	bitesize = 2
	center_of_mass = list("x"=16, "y"=14)
	whole_path = /obj/item/weapon/reagent_containers/food/snacks/sliceable/cheesecake

/obj/item/weapon/reagent_containers/food/snacks/slice/cheesecake/filled
	filled = TRUE

/obj/item/weapon/reagent_containers/food/snacks/sliceable/peanutcake
	name = "Peanut Cake"
	desc = "DANGEROUSLY nutty. Sometimes literally."
	icon_state = "peanutcake"
	slice_path = /obj/item/weapon/reagent_containers/food/snacks/slice/peanutcake
	slices_num = 5
	filling_color = "#4F3500"
	center_of_mass = list("x"=16, "y"=10)
	nutriment_desc = list("cake" = 10, "peanuts" = 15)
	nutriment_amt = 10

/obj/item/weapon/reagent_containers/food/snacks/sliceable/peanutcake/Initialize()
	. = ..()
	reagents.add_reagent("protein", 5)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/slice/peanutcake
	name = "Peanut Cake slice"
	desc = "Slice of nutty goodness."
	icon_state = "peanutcake_slice"
	trash = /obj/item/trash/plate
	filling_color = "#4F3500"
	bitesize = 2
	center_of_mass = list("x"=16, "y"=14)
	whole_path = /obj/item/weapon/reagent_containers/food/snacks/sliceable/peanutcake

/obj/item/weapon/reagent_containers/food/snacks/slice/peanutcake/filled
	filled = TRUE

/obj/item/weapon/reagent_containers/food/snacks/sliceable/plaincake
	name = "Vanilla Cake"
	desc = "A plain cake, not a lie."
	icon_state = "plaincake"
	slice_path = /obj/item/weapon/reagent_containers/food/snacks/slice/plaincake
	slices_num = 5
	filling_color = "#F7EDD5"
	center_of_mass = list("x"=16, "y"=10)
	nutriment_desc = list("cake" = 10, "sweetness" = 10, "vanilla" = 15)
	nutriment_amt = 20

/obj/item/weapon/reagent_containers/food/snacks/slice/plaincake
	name = "Vanilla Cake slice"
	desc = "Just a slice of cake, it is enough for everyone."
	icon_state = "plaincake_slice"
	trash = /obj/item/trash/plate
	filling_color = "#F7EDD5"
	bitesize = 2
	center_of_mass = list("x"=16, "y"=14)
	whole_path = /obj/item/weapon/reagent_containers/food/snacks/sliceable/plaincake

/obj/item/weapon/reagent_containers/food/snacks/slice/plaincake/filled
	filled = TRUE

/obj/item/weapon/reagent_containers/food/snacks/sliceable/orangecake
	name = "Orange Cake"
	desc = "A cake with added orange."
	icon_state = "orangecake"
	slice_path = /obj/item/weapon/reagent_containers/food/snacks/slice/orangecake
	slices_num = 5
	filling_color = "#FADA8E"
	center_of_mass = list("x"=16, "y"=10)
	nutriment_desc = list("cake" = 10, "sweetness" = 10, "orange" = 15)
	nutriment_amt = 20

/obj/item/weapon/reagent_containers/food/snacks/slice/orangecake
	name = "Orange Cake slice"
	desc = "Just a slice of cake, it is enough for everyone."
	icon_state = "orangecake_slice"
	trash = /obj/item/trash/plate
	filling_color = "#FADA8E"
	bitesize = 2
	center_of_mass = list("x"=16, "y"=14)
	whole_path = /obj/item/weapon/reagent_containers/food/snacks/sliceable/orangecake

/obj/item/weapon/reagent_containers/food/snacks/slice/orangecake/filled
	filled = TRUE


/obj/item/weapon/reagent_containers/food/snacks/sliceable/limecake
	name = "Lime Cake"
	desc = "A cake with added lime."
	icon_state = "limecake"
	slice_path = /obj/item/weapon/reagent_containers/food/snacks/slice/limecake
	slices_num = 5
	filling_color = "#CBFA8E"
	center_of_mass = list("x"=16, "y"=10)
	nutriment_desc = list("cake" = 10, "sweetness" = 10, "lime" = 15)
	nutriment_amt = 20


/obj/item/weapon/reagent_containers/food/snacks/slice/limecake
	name = "Lime Cake slice"
	desc = "Just a slice of cake, it is enough for everyone."
	icon_state = "limecake_slice"
	trash = /obj/item/trash/plate
	filling_color = "#CBFA8E"
	bitesize = 2
	center_of_mass = list("x"=16, "y"=14)
	whole_path = /obj/item/weapon/reagent_containers/food/snacks/sliceable/limecake

/obj/item/weapon/reagent_containers/food/snacks/slice/limecake/filled
	filled = TRUE

/obj/item/weapon/reagent_containers/food/snacks/sliceable/lemoncake
	name = "Lemon Cake"
	desc = "A cake with added lemon."
	icon_state = "lemoncake"
	slice_path = /obj/item/weapon/reagent_containers/food/snacks/slice/lemoncake
	slices_num = 5
	filling_color = "#FAFA8E"
	center_of_mass = list("x"=16, "y"=10)
	nutriment_desc = list("cake" = 10, "sweetness" = 10, "lemon" = 15)
	nutriment_amt = 20


/obj/item/weapon/reagent_containers/food/snacks/slice/lemoncake
	name = "Lemon Cake slice"
	desc = "Just a slice of cake, it is enough for everyone."
	icon_state = "lemoncake_slice"
	trash = /obj/item/trash/plate
	filling_color = "#FAFA8E"
	bitesize = 2
	center_of_mass = list("x"=16, "y"=14)
	whole_path = /obj/item/weapon/reagent_containers/food/snacks/sliceable/lemoncake

/obj/item/weapon/reagent_containers/food/snacks/slice/lemoncake/filled
	filled = TRUE

/obj/item/weapon/reagent_containers/food/snacks/sliceable/chocolatecake
	name = "Chocolate Cake"
	desc = "A cake with added chocolate."
	icon_state = "chocolatecake"
	slice_path = /obj/item/weapon/reagent_containers/food/snacks/slice/chocolatecake
	slices_num = 5
	filling_color = "#805930"
	center_of_mass = list("x"=16, "y"=10)
	nutriment_desc = list("cake" = 10, "sweetness" = 10, "chocolate" = 15)
	nutriment_amt = 20

/obj/item/weapon/reagent_containers/food/snacks/slice/chocolatecake
	name = "Chocolate Cake slice"
	desc = "Just a slice of cake, it is enough for everyone."
	icon_state = "chocolatecake_slice"
	trash = /obj/item/trash/plate
	filling_color = "#805930"
	bitesize = 2
	center_of_mass = list("x"=16, "y"=14)
	whole_path = /obj/item/weapon/reagent_containers/food/snacks/sliceable/chocolatecake

/obj/item/weapon/reagent_containers/food/snacks/slice/chocolatecake/filled
	filled = TRUE

/obj/item/weapon/reagent_containers/food/snacks/sliceable/cheesewheel
	name = "Cheese wheel"
	desc = "A big wheel of delcious Cheddar."
	icon_state = "cheesewheel"
	slice_path = /obj/item/weapon/reagent_containers/food/snacks/cheesewedge
	slices_num = 5
	filling_color = "#FFF700"
	center_of_mass = list("x"=16, "y"=10)
	nutriment_desc = list("cheese" = 10)
	nutriment_amt = 10

/obj/item/weapon/reagent_containers/food/snacks/sliceable/cheesewheel/Initialize()
	. = ..()
	reagents.add_reagent("protein", 10)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/cheesewedge
	name = "Cheese wedge"
	desc = "A wedge of delicious Cheddar. The cheese wheel it was cut from can't have gone far."
	icon_state = "cheesewedge"
	filling_color = "#FFF700"
	bitesize = 2
	center_of_mass = list("x"=16, "y"=10)

/obj/item/weapon/reagent_containers/food/snacks/sliceable/birthdaycake
	name = "Birthday Cake"
	desc = "Happy Birthday..."
	icon_state = "birthdaycake"
	slice_path = /obj/item/weapon/reagent_containers/food/snacks/slice/birthdaycake
	slices_num = 5
	filling_color = "#FFD6D6"
	center_of_mass = list("x"=16, "y"=10)
	nutriment_desc = list("cake" = 10, "sweetness" = 10)
	nutriment_amt = 20

/obj/item/weapon/reagent_containers/food/snacks/sliceable/birthdaycake/Initialize()
	. = ..()
	reagents.add_reagent("sprinkles", 10)
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/slice/birthdaycake
	name = "Birthday Cake slice"
	desc = "A slice of your birthday."
	icon_state = "birthdaycakeslice"
	trash = /obj/item/trash/plate
	filling_color = "#FFD6D6"
	bitesize = 2
	center_of_mass = list("x"=16, "y"=14)
	whole_path = /obj/item/weapon/reagent_containers/food/snacks/sliceable/birthdaycake

/obj/item/weapon/reagent_containers/food/snacks/slice/birthdaycake/filled
	filled = TRUE

/obj/item/weapon/reagent_containers/food/snacks/sliceable/bread
	name = "Bread"
	icon_state = "Some plain old Earthen bread."
	icon_state = "bread"
	slice_path = /obj/item/weapon/reagent_containers/food/snacks/slice/bread
	slices_num = 5
	filling_color = "#FFE396"
	center_of_mass = list("x"=16, "y"=9)
	nutriment_desc = list("bread" = 6)
	nutriment_amt = 6

/obj/item/weapon/reagent_containers/food/snacks/sliceable/bread/Initialize()
	. = ..()
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/slice/bread
	name = "Bread slice"
	desc = "A slice of home."
	icon_state = "breadslice"
	trash = /obj/item/trash/plate
	filling_color = "#D27332"
	bitesize = 2
	center_of_mass = list("x"=16, "y"=4)
	whole_path = /obj/item/weapon/reagent_containers/food/snacks/sliceable/bread

/obj/item/weapon/reagent_containers/food/snacks/slice/bread/filled
	filled = TRUE


/obj/item/weapon/reagent_containers/food/snacks/sliceable/creamcheesebread
	name = "Cream Cheese Bread"
	desc = "Yum yum yum!"
	icon_state = "creamcheesebread"
	slice_path = /obj/item/weapon/reagent_containers/food/snacks/slice/creamcheesebread
	slices_num = 5
	filling_color = "#FFF896"
	center_of_mass = list("x"=16, "y"=9)
	nutriment_desc = list("bread" = 6, "cream" = 3, "cheese" = 3)
	nutriment_amt = 5

/obj/item/weapon/reagent_containers/food/snacks/sliceable/creamcheesebread/Initialize()
	. = ..()
	reagents.add_reagent("protein", 15)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/slice/creamcheesebread
	name = "Cream Cheese Bread slice"
	desc = "A slice of yum!"
	icon_state = "creamcheesebreadslice"
	trash = /obj/item/trash/plate
	filling_color = "#FFF896"
	bitesize = 2
	center_of_mass = list("x"=16, "y"=14)
	whole_path = /obj/item/weapon/reagent_containers/food/snacks/sliceable/creamcheesebread


/obj/item/weapon/reagent_containers/food/snacks/slice/creamcheesebread/filled
	filled = TRUE


/obj/item/weapon/reagent_containers/food/snacks/watermelonslice
	name = "Watermelon Slice"
	desc = "A slice of watery goodness."
	icon_state = "watermelonslice"
	filling_color = "#FF3867"
	bitesize = 2
	center_of_mass = list("x"=16, "y"=10)

/obj/item/weapon/reagent_containers/food/snacks/sliceable/applecake
	name = "Apple Cake"
	desc = "A cake centred with apples."
	icon_state = "applecake"
	slice_path = /obj/item/weapon/reagent_containers/food/snacks/slice/applecake
	slices_num = 5
	filling_color = "#EBF5B8"
	center_of_mass = list("x"=16, "y"=10)
	nutriment_desc = list("cake" = 10, "sweetness" = 10, "apple" = 15)
	nutriment_amt = 15

/obj/item/weapon/reagent_containers/food/snacks/slice/applecake
	name = "Apple Cake slice"
	desc = "A slice of heavenly cake."
	icon_state = "applecakeslice"
	trash = /obj/item/trash/plate
	filling_color = "#EBF5B8"
	bitesize = 2
	center_of_mass = list("x"=16, "y"=14)
	whole_path = /obj/item/weapon/reagent_containers/food/snacks/sliceable/applecake

/obj/item/weapon/reagent_containers/food/snacks/slice/applecake/filled
	filled = TRUE

/obj/item/weapon/reagent_containers/food/snacks/sliceable/pumpkinpie
	name = "Pumpkin Pie"
	desc = "A delicious treat for the autumn months."
	icon_state = "pumpkinpie"
	slice_path = /obj/item/weapon/reagent_containers/food/snacks/slice/pumpkinpie
	slices_num = 5
	filling_color = "#F5B951"
	center_of_mass = list("x"=16, "y"=10)
	nutriment_desc = list("pie" = 5, "cream" = 5, "pumpkin" = 5)
	nutriment_amt = 15

/obj/item/weapon/reagent_containers/food/snacks/slice/pumpkinpie
	name = "Pumpkin Pie slice"
	desc = "A slice of pumpkin pie, with whipped cream on top. Perfection."
	icon_state = "pumpkinpieslice"
	trash = /obj/item/trash/plate
	filling_color = "#F5B951"
	bitesize = 2
	center_of_mass = list("x"=16, "y"=12)
	whole_path = /obj/item/weapon/reagent_containers/food/snacks/sliceable/pumpkinpie

/obj/item/weapon/reagent_containers/food/snacks/slice/pumpkinpie/filled
	filled = TRUE

/obj/item/weapon/reagent_containers/food/snacks/cracker
	name = "Cracker"
	desc = "It's a salted cracker."
	icon_state = "cracker"
	filling_color = "#F5DEB8"
	center_of_mass = list("x"=16, "y"=6)
	nutriment_desc = list("salt" = 1, "cracker" = 2)
	nutriment_amt = 1



/////////////////////////////////////////////////PIZZA////////////////////////////////////////

/obj/item/weapon/reagent_containers/food/snacks/sliceable/pizza
	slices_num = 6
	filling_color = "#BAA14C"

/obj/item/weapon/reagent_containers/food/snacks/sliceable/pizza/margherita
	name = "Margherita"
	desc = "The golden standard of pizzas."
	icon_state = "pizzamargherita"
	slice_path = /obj/item/weapon/reagent_containers/food/snacks/slice/margherita
	slices_num = 6
	center_of_mass = list("x"=16, "y"=11)
	nutriment_desc = list("pizza crust" = 10, "tomato" = 10, "cheese" = 15)
	nutriment_amt = 35

/obj/item/weapon/reagent_containers/food/snacks/sliceable/pizza/margherita/Initialize()
	. = ..()
	reagents.add_reagent("protein", 5)
	reagents.add_reagent("tomatojuice", 6)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/slice/margherita
	name = "Margherita slice"
	desc = "A slice of the classic pizza."
	icon_state = "pizzamargheritaslice"
	filling_color = "#BAA14C"
	bitesize = 2
	center_of_mass = list("x"=16, "y"=13)
	whole_path = /obj/item/weapon/reagent_containers/food/snacks/sliceable/pizza/margherita

/obj/item/weapon/reagent_containers/food/snacks/slice/margherita/filled
	filled = TRUE

/obj/item/weapon/reagent_containers/food/snacks/sliceable/pizza/pineapple
	name = "Hawaiian"
	desc = "The accursed wheel from ancient times."
	icon_state = "pizzamargherita"
	slice_path = /obj/item/weapon/reagent_containers/food/snacks/slice/pineapple
	slices_num = 6
	center_of_mass = list("x"=16, "y"=11)
	nutriment_desc = list("pizza crust" = 5, "tomato" = 5, "cheese" = 5, "pineapple" = 20)
	nutriment_amt = 35

/obj/item/weapon/reagent_containers/food/snacks/sliceable/pizza/pineapple/Initialize()
	. = ..()
	reagents.add_reagent("protein", 5)
	reagents.add_reagent("pineapplejuice", 6)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/slice/pineapple
	name = "Hawaiian slice"
	desc = "A slice of the accursed pizza."
	icon_state = "pizzamargheritaslice"
	filling_color = "#BAA14C"
	bitesize = 2
	center_of_mass = list("x"=16, "y"=13)
	whole_path = /obj/item/weapon/reagent_containers/food/snacks/sliceable/pizza/pineapple

/obj/item/weapon/reagent_containers/food/snacks/slice/pineapple/filled
	filled = TRUE

/obj/item/weapon/reagent_containers/food/snacks/sliceable/pizza/meatpizza
	name = "Meatpizza"
	desc = "A pizza with meat topping."
	icon_state = "meatpizza"
	slice_path = /obj/item/weapon/reagent_containers/food/snacks/slice/meatpizza
	slices_num = 6
	center_of_mass = list("x"=16, "y"=11)
	nutriment_desc = list("pizza crust" = 10, "tomato" = 10, "cheese" = 15)
	nutriment_amt = 10

/obj/item/weapon/reagent_containers/food/snacks/sliceable/pizza/meatpizza/Initialize()
	. = ..()
	reagents.add_reagent("protein", 34)
	reagents.add_reagent("tomatojuice", 6)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/slice/meatpizza
	name = "Meatpizza slice"
	desc = "A slice of a meaty pizza."
	icon_state = "meatpizzaslice"
	filling_color = "#BAA14C"
	bitesize = 2
	center_of_mass = list("x"=16, "y"=13)
	whole_path = /obj/item/weapon/reagent_containers/food/snacks/sliceable/pizza/meatpizza

/obj/item/weapon/reagent_containers/food/snacks/slice/meatpizza/filled
	filled = TRUE

/obj/item/weapon/reagent_containers/food/snacks/sliceable/pizza/mushroompizza
	name = "Mushroompizza"
	desc = "Very special pizza."
	icon_state = "mushroompizza"
	slice_path = /obj/item/weapon/reagent_containers/food/snacks/slice/mushroompizza
	slices_num = 6
	center_of_mass = list("x"=16, "y"=11)
	nutriment_desc = list("pizza crust" = 10, "tomato" = 10, "cheese" = 5, "mushroom" = 10)
	nutriment_amt = 35

/obj/item/weapon/reagent_containers/food/snacks/sliceable/pizza/mushroompizza/Initialize()
	. = ..()
	reagents.add_reagent("protein", 5)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/slice/mushroompizza
	name = "Mushroompizza slice"
	desc = "Maybe it is the last slice of pizza in your life."
	icon_state = "mushroompizzaslice"
	filling_color = "#BAA14C"
	bitesize = 2
	center_of_mass = list("x"=16, "y"=13)
	whole_path = /obj/item/weapon/reagent_containers/food/snacks/sliceable/pizza/mushroompizza

/obj/item/weapon/reagent_containers/food/snacks/slice/mushroompizza/filled
	filled = TRUE

/obj/item/weapon/reagent_containers/food/snacks/sliceable/pizza/vegetablepizza
	name = "Vegetable pizza"
	desc = "No one of Tomato Sapiens were harmed during making this pizza."
	icon_state = "vegetablepizza"
	slice_path = /obj/item/weapon/reagent_containers/food/snacks/slice/vegetablepizza
	slices_num = 6
	center_of_mass = list("x"=16, "y"=11)
	nutriment_desc = list("pizza crust" = 10, "tomato" = 10, "cheese" = 5, "eggplant" = 5, "carrot" = 5, "corn" = 5)
	nutriment_amt = 25

/obj/item/weapon/reagent_containers/food/snacks/sliceable/pizza/vegetablepizza/Initialize()
	. = ..()
	reagents.add_reagent("protein", 5)
	reagents.add_reagent("tomatojuice", 6)
	reagents.add_reagent("imidazoline", 12)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/slice/vegetablepizza
	name = "Vegetable pizza slice"
	desc = "A slice of the most green pizza of all pizzas not containing green ingredients."
	icon_state = "vegetablepizzaslice"
	filling_color = "#BAA14C"
	bitesize = 2
	center_of_mass = list("x"=16, "y"=13)
	whole_path = /obj/item/weapon/reagent_containers/food/snacks/sliceable/pizza/vegetablepizza

/obj/item/weapon/reagent_containers/food/snacks/slice/vegetablepizza/filled
	filled = TRUE

/obj/item/weapon/reagent_containers/food/snacks/sliceable/pizza/oldpizza
	name = "moldy pizza"
	desc = "This pizza might actually be alive.  There's mold all over."
	icon_state = "oldpizza"
	slice_path = /obj/item/weapon/reagent_containers/food/snacks/slice/oldpizza
	slices_num = 6
	center_of_mass = list("x"=16, "y"=11)
	nutriment_desc = list("stale pizza crust" = 10, "moldy tomato" = 10, "moldy cheese" = 5)
	nutriment_amt = 10

/obj/item/weapon/reagent_containers/food/snacks/sliceable/pizza/oldpizza/Initialize()
	. = ..()
	reagents.add_reagent("protein", 5)
	reagents.add_reagent("tomatojuice", 6)
	reagents.add_reagent("mold", 8)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/slice/oldpizza
	name = "moldy pizza slice"
	desc = "This used to be pizza..."
	icon_state = "old_pizza"
	filling_color = "#BAA14C"
	bitesize = 2
	center_of_mass = list("x"=16, "y"=13)
	whole_path = /obj/item/weapon/reagent_containers/food/snacks/sliceable/pizza/oldpizza

/obj/item/pizzabox
	name = "pizza box"
	desc = "A box suited for pizzas."
	icon = 'icons/obj/food.dmi'
	icon_state = "pizzabox1"

	var/open = 0 // Is the box open?
	var/ismessy = 0 // Fancy mess on the lid
	var/obj/item/weapon/reagent_containers/food/snacks/sliceable/pizza/pizza // Content pizza
	var/list/boxes = list() // If the boxes are stacked, they come here
	var/boxtag = ""

/obj/item/pizzabox/update_icon()

	overlays = list()

	// Set appropriate description
	if( open && pizza )
		desc = "A box suited for pizzas. It appears to have a [pizza.name] inside."
	else if( boxes.len > 0 )
		desc = "A pile of boxes suited for pizzas. There appears to be [boxes.len + 1] boxes in the pile."

		var/obj/item/pizzabox/topbox = boxes[boxes.len]
		var/toptag = topbox.boxtag
		if( toptag != "" )
			desc = "[desc] The box on top has a tag, it reads: '[toptag]'."
	else
		desc = "A box suited for pizzas."

		if( boxtag != "" )
			desc = "[desc] The box has a tag, it reads: '[boxtag]'."

	// Icon states and overlays
	if( open )
		if( ismessy )
			icon_state = "pizzabox_messy"
		else
			icon_state = "pizzabox_open"

		if( pizza )
			var/image/pizzaimg = image("food.dmi", icon_state = pizza.icon_state)
			pizzaimg.pixel_y = -3
			overlays += pizzaimg

		return
	else
		// Stupid code because byondcode sucks
		var/doimgtag = 0
		if( boxes.len > 0 )
			var/obj/item/pizzabox/topbox = boxes[boxes.len]
			if( topbox.boxtag != "" )
				doimgtag = 1
		else
			if( boxtag != "" )
				doimgtag = 1

		if( doimgtag )
			var/image/tagimg = image("food.dmi", icon_state = "pizzabox_tag")
			tagimg.pixel_y = boxes.len * 3
			overlays += tagimg

	icon_state = "pizzabox[boxes.len+1]"

/obj/item/pizzabox/attack_hand( mob/user as mob )

	if( open && pizza )
		user.put_in_hands( pizza )

		to_chat(user, "<span class='warning'>You take \the [src.pizza] out of \the [src].</span>")
		src.pizza = null
		update_icon()
		return

	if( boxes.len > 0 )
		if( user.get_inactive_hand() != src )
			..()
			return

		var/obj/item/pizzabox/box = boxes[boxes.len]
		boxes -= box

		user.put_in_hands( box )
		to_chat(user, "<span class='warning'>You remove the topmost [src] from your hand.</span>")
		box.update_icon()
		update_icon()
		return
	..()

/obj/item/pizzabox/attack_self( mob/user as mob )

	if( boxes.len > 0 )
		return

	open = !open

	if( open && pizza )
		ismessy = 1

	update_icon()

/obj/item/pizzabox/attackby( obj/item/I as obj, mob/user as mob )
	if( istype(I, /obj/item/pizzabox/) )
		var/obj/item/pizzabox/box = I

		if( !box.open && !src.open )
			// Make a list of all boxes to be added
			var/list/boxestoadd = list()
			boxestoadd += box
			for(var/obj/item/pizzabox/i in box.boxes)
				boxestoadd += i

			if( (boxes.len+1) + boxestoadd.len <= 5 )
				user.drop_item()

				box.loc = src
				box.boxes = list() // Clear the box boxes so we don't have boxes inside boxes. - Xzibit
				src.boxes.Add( boxestoadd )

				box.update_icon()
				update_icon()

				to_chat(user, "<span class='warning'>You put \the [box] ontop of \the [src]!</span>")
			else
				to_chat(user, "<span class='warning'>The stack is too high!</span>")
		else
			to_chat(user, "<span class='warning'>Close \the [box] first!</span>")

		return

	if( istype(I, /obj/item/weapon/reagent_containers/food/snacks/sliceable/pizza/) ) // Long ass fucking object name

		if( src.open )
			user.drop_item()
			I.loc = src
			src.pizza = I

			update_icon()

			to_chat(user, "<span class='warning'>You put \the [I] in \the [src]!</span>")
		else
			to_chat(user, "<span class='warning'>You try to push \the [I] through the lid but it doesn't work!</span>")
		return

	if( istype(I, /obj/item/weapon/pen/) )

		if( src.open )
			return

		var/t = sanitize(input("Enter what you want to add to the tag:", "Write", null, null) as text, 30)

		var/obj/item/pizzabox/boxtotagto = src
		if( boxes.len > 0 )
			boxtotagto = boxes[boxes.len]

		boxtotagto.boxtag = copytext("[boxtotagto.boxtag][t]", 1, 30)

		update_icon()
		return
	..()

/obj/item/pizzabox/margherita/Initialize()
	pizza = new /obj/item/weapon/reagent_containers/food/snacks/sliceable/pizza/margherita(src)
	boxtag = "Margherita Deluxe"

/obj/item/pizzabox/vegetable/Initialize()
	pizza = new /obj/item/weapon/reagent_containers/food/snacks/sliceable/pizza/vegetablepizza(src)
	boxtag = "Gourmet Vegatable"

/obj/item/pizzabox/mushroom/Initialize()
	pizza = new /obj/item/weapon/reagent_containers/food/snacks/sliceable/pizza/mushroompizza(src)
	boxtag = "Mushroom Special"

/obj/item/pizzabox/meat/Initialize()
	pizza = new /obj/item/weapon/reagent_containers/food/snacks/sliceable/pizza/meatpizza(src)
	boxtag = "Meatlover's Supreme"

/obj/item/pizzabox/old/Initialize()
	pizza = new /obj/item/weapon/reagent_containers/food/snacks/sliceable/pizza/oldpizza(src)
	boxtag = "Deluxe Gourmet"

/obj/item/weapon/reagent_containers/food/snacks/dionaroast
	name = "roast diona"
	desc = "It's like an enormous, leathery carrot. With an eye."
	icon_state = "dionaroast"
	trash = /obj/item/trash/plate
	filling_color = "#75754B"
	center_of_mass = list("x"=16, "y"=7)
	nutriment_amt = 6
	nutriment_desc = list("a chorus of flavor" = 6)

/obj/item/weapon/reagent_containers/food/snacks/dionaroast/Initialize()
	. = ..()
	reagents.add_reagent("radium", 2)
	bitesize = 2

///////////////////////////////////////////
// new old food stuff from bs12
///////////////////////////////////////////
/obj/item/weapon/reagent_containers/food/snacks/dough
	name = "dough"
	desc = "A piece of dough."
	icon = 'icons/obj/food_ingredients.dmi'
	icon_state = "dough"
	bitesize = 2
	center_of_mass = list("x"=16, "y"=13)
	nutriment_amt = 3
	nutriment_desc = list("uncooked dough" = 3)

/obj/item/weapon/reagent_containers/food/snacks/dough/Initialize()
	. = ..()
	reagents.add_reagent("protein", 1)

// Dough + rolling pin = flat dough
/obj/item/weapon/reagent_containers/food/snacks/dough/attackby(obj/item/weapon/W as obj, mob/user as mob)
	if(istype(W,/obj/item/weapon/material/kitchen/rollingpin))
		new /obj/item/weapon/reagent_containers/food/snacks/sliceable/flatdough(src)
		user << "You flatten the dough."
		qdel(src)

// slicable into 3xdoughslices
/obj/item/weapon/reagent_containers/food/snacks/sliceable/flatdough
	name = "flat dough"
	desc = "A flattened dough."
	icon = 'icons/obj/food_ingredients.dmi'
	icon_state = "flat dough"
	slice_path = /obj/item/weapon/reagent_containers/food/snacks/doughslice
	slices_num = 3
	center_of_mass = list("x"=16, "y"=16)

/obj/item/weapon/reagent_containers/food/snacks/sliceable/flatdough/Initialize()
	. = ..()
	reagents.add_reagent("protein", 1)
	reagents.add_reagent("nutriment", 3)

/obj/item/weapon/reagent_containers/food/snacks/doughslice
	name = "dough slice"
	desc = "A building block of an impressive dish."
	icon = 'icons/obj/food_ingredients.dmi'
	icon_state = "doughslice"
	slice_path = /obj/item/weapon/reagent_containers/food/snacks/spagetti
	slices_num = 1
	bitesize = 2
	center_of_mass = list("x"=17, "y"=19)
	nutriment_amt = 1
	nutriment_desc = list("uncooked dough" = 1)

/obj/item/weapon/reagent_containers/food/snacks/doughslice/Initialize()
	. = ..()

/obj/item/weapon/reagent_containers/food/snacks/bun
	name = "bun"
	desc = "A base for any self-respecting burger."
	icon = 'icons/obj/food_ingredients.dmi'
	icon_state = "bun"
	bitesize = 2
	center_of_mass = list("x"=16, "y"=12)
	nutriment_amt = 4
	nutriment_desc = "bun"

/obj/item/weapon/reagent_containers/food/snacks/bun/Initialize()
	. = ..()

/obj/item/weapon/reagent_containers/food/snacks/bun/attackby(obj/item/weapon/W as obj, mob/user as mob)
	// Bun + meatball = burger
	if(istype(W,/obj/item/weapon/reagent_containers/food/snacks/meatball))
		new /obj/item/weapon/reagent_containers/food/snacks/monkeyburger(src)
		user << "You make a burger."
		qdel(W)
		qdel(src)

	// Bun + cutlet = hamburger
	else if(istype(W,/obj/item/weapon/reagent_containers/food/snacks/cutlet))
		new /obj/item/weapon/reagent_containers/food/snacks/monkeyburger(src)
		user << "You make a burger."
		qdel(W)
		qdel(src)

	// Bun + sausage = hotdog
	else if(istype(W,/obj/item/weapon/reagent_containers/food/snacks/sausage))
		new /obj/item/weapon/reagent_containers/food/snacks/hotdog(src)
		user << "You make a hotdog."
		qdel(W)
		qdel(src)

// Burger + cheese wedge = cheeseburger
/obj/item/weapon/reagent_containers/food/snacks/monkeyburger/attackby(obj/item/weapon/reagent_containers/food/snacks/cheesewedge/W as obj, mob/user as mob)
	if(istype(W))// && !istype(src,/obj/item/weapon/reagent_containers/food/snacks/cheesewedge))
		new /obj/item/weapon/reagent_containers/food/snacks/cheeseburger(src)
		user << "You make a cheeseburger."
		qdel(W)
		qdel(src)
		return
	else
		..()

// Human Burger + cheese wedge = cheeseburger
/obj/item/weapon/reagent_containers/food/snacks/human/burger/attackby(obj/item/weapon/reagent_containers/food/snacks/cheesewedge/W as obj, mob/user as mob)
	if(istype(W))
		new /obj/item/weapon/reagent_containers/food/snacks/cheeseburger(src)
		user << "You make a cheeseburger."
		qdel(W)
		qdel(src)
		return
	else
		..()

/obj/item/weapon/reagent_containers/food/snacks/bunbun
	name = "\improper Bun Bun"
	desc = "A small bread monkey fashioned from two burger buns."
	icon_state = "bunbun"
	bitesize = 2
	center_of_mass = list("x"=16, "y"=8)
	nutriment_amt = 8
	nutriment_desc = list("bun" = 8)

/obj/item/weapon/reagent_containers/food/snacks/bunbun/Initialize()
	. = ..()

/obj/item/weapon/reagent_containers/food/snacks/taco
	name = "taco"
	desc = "Take a bite!"
	icon_state = "taco"
	bitesize = 3
	center_of_mass = list("x"=21, "y"=12)
	nutriment_amt = 4
	nutriment_desc = list("cheese" = 2,"taco shell" = 2)

/obj/item/weapon/reagent_containers/food/snacks/taco/Initialize()
	. = ..()
	reagents.add_reagent("protein", 3)

/obj/item/weapon/reagent_containers/food/snacks/rawcutlet
	name = "raw cutlet"
	desc = "A thin piece of raw meat."
	icon = 'icons/obj/food_ingredients.dmi'
	icon_state = "rawcutlet"
	bitesize = 1
	center_of_mass = list("x"=17, "y"=20)

/obj/item/weapon/reagent_containers/food/snacks/rawcutlet/Initialize()
	. = ..()
	reagents.add_reagent("protein", 1)

/obj/item/weapon/reagent_containers/food/snacks/cutlet
	name = "cutlet"
	desc = "A tasty meat slice."
	icon = 'icons/obj/food_ingredients.dmi'
	icon_state = "cutlet"
	bitesize = 2
	center_of_mass = list("x"=17, "y"=20)

/obj/item/weapon/reagent_containers/food/snacks/cutlet/Initialize()
	. = ..()
	reagents.add_reagent("protein", 2)

/obj/item/weapon/reagent_containers/food/snacks/rawmeatball
	name = "raw meatball"
	desc = "A raw meatball."
	icon = 'icons/obj/food_ingredients.dmi'
	icon_state = "rawmeatball"
	bitesize = 2
	center_of_mass = list("x"=16, "y"=15)

/obj/item/weapon/reagent_containers/food/snacks/rawmeatball/Initialize()
	. = ..()
	reagents.add_reagent("protein", 2)

/obj/item/weapon/reagent_containers/food/snacks/hotdog
	name = "hotdog"
	desc = "Unrelated to dogs, maybe."
	icon_state = "hotdog"
	bitesize = 2
	center_of_mass = list("x"=16, "y"=17)

/obj/item/weapon/reagent_containers/food/snacks/hotdog/Initialize()
	. = ..()
	reagents.add_reagent("protein", 6)

/obj/item/weapon/reagent_containers/food/snacks/hotdog/old
	name = "old hotdog"
	desc = "Covered in mold.  You're not gonna eat that, are you?"

/obj/item/weapon/reagent_containers/food/snacks/hotdog/old/Initialize()
	. = ..()
	reagents.add_reagent("mold", 6)

/obj/item/weapon/reagent_containers/food/snacks/flatbread
	name = "flatbread"
	desc = "Bland but filling."
	icon = 'icons/obj/food_ingredients.dmi'
	icon_state = "flatbread"
	bitesize = 2
	center_of_mass = list("x"=16, "y"=16)
	nutriment_amt = 3
	nutriment_desc = list("bread" = 3)

/obj/item/weapon/reagent_containers/food/snacks/flatbread/Initialize()
	. = ..()

// potato + knife = raw sticks
/obj/item/weapon/reagent_containers/food/snacks/grown/attackby(obj/item/weapon/W, mob/user)
	if(seed && seed.kitchen_tag && seed.kitchen_tag == "potato" && istype(W,/obj/item/weapon/material/knife))
		new /obj/item/weapon/reagent_containers/food/snacks/rawsticks(get_turf(src))
		to_chat(user, "<span class='notice'>You cut the potato.</span>")
		qdel(src)
	else if(seed && seed.kitchen_tag && seed.kitchen_tag == "sunflower" && istype(W,/obj/item/weapon/material/knife))
		new /obj/item/weapon/reagent_containers/food/snacks/rawsunflower(get_turf(src))
		to_chat(user, "<span class='notice'>You remove the seeds from the flower, slightly damaging them.</span>")
		qdel(src)
	else
		..()

/obj/item/weapon/reagent_containers/food/snacks/rawsticks
	name = "raw potato sticks"
	desc = "Raw fries, not very tasty."
	icon = 'icons/obj/food_ingredients.dmi'
	icon_state = "rawsticks"
	bitesize = 2
	center_of_mass = list("x"=16, "y"=12)
	nutriment_amt = 3
	nutriment_desc = list("raw potato" = 3)

/obj/item/weapon/reagent_containers/food/snacks/rawsticks/Initialize()
	. = ..()

/obj/item/weapon/reagent_containers/food/snacks/rawsunflower
	name = "sunflower seeds"
	desc = "Raw sunflower seeds, alright. They look too damaged to plant."
	icon = 'icons/obj/food_ingredients.dmi'
	icon_state = "sunflowerseed"
	bitesize = 1
	center_of_mass = list("x"=17, "y"=18)
	nutriment_amt = 1
	nutriment_desc = list("starch" = 3)

/obj/item/weapon/reagent_containers/food/snacks/rawsunflower/Initialize()
	. = ..()

/obj/item/weapon/reagent_containers/food/snacks/roastedsunflower
	name = "sunflower seeds"
	desc = "Sunflower seeds!"
	icon = 'icons/obj/food.dmi'
	icon_state = "sunflowerseed"
	bitesize = 1
	center_of_mass = list("x"=15, "y"=17)
	nutriment_amt = 2
	nutriment_desc = list("salt" = 3)

/obj/item/weapon/reagent_containers/food/snacks/roastedpeanuts
	name = "peanuts"
	desc = "Stopped being the planetary airline food of Earth in 2120."
	icon = 'icons/obj/food.dmi'
	icon_state = "roastnuts"
	bitesize = 1
	center_of_mass = list("x"=15, "y"=17)
	nutriment_amt = 2
	nutriment_desc = list("salt" = 3)

/obj/item/weapon/reagent_containers/food/snacks/liquidfood
	name = "\improper LiquidFood Ration"
	desc = "A prepackaged grey slurry of all the essential nutrients for a spacefarer on the go. Should this be crunchy?"
	icon_state = "liquidfood"
	trash = /obj/item/trash/liquidfood
	filling_color = "#A8A8A8"
	survivalfood = TRUE
	center_of_mass = list("x"=16, "y"=15)
	nutriment_amt = 20
	nutriment_desc = list("chalk" = 6)

/obj/item/weapon/reagent_containers/food/snacks/liquidfood/Initialize()
	. = ..()
	reagents.add_reagent("iron", 3)
	bitesize = 4

/obj/item/weapon/reagent_containers/food/snacks/tastybread
	name = "bread tube"
	desc = "Bread in a tube. Chewy...and surprisingly tasty."
	icon_state = "tastybread"
	trash = /obj/item/trash/tastybread
	filling_color = "#A66829"
	center_of_mass = list("x"=17, "y"=16)
	nutriment_amt = 6
	nutriment_desc = list("bread" = 2, "sweetness" = 3)

/obj/item/weapon/reagent_containers/food/snacks/tastybread/Initialize()
	. = ..()
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/skrellsnacks
	name = "\improper SkrellSnax"
	desc = "Cured fungus shipped all the way from Qerr'balak, almost like jerky! Almost."
	icon_state = "skrellsnacks"
	filling_color = "#A66829"
	center_of_mass = list("x"=15, "y"=12)
	nutriment_amt = 10
	nutriment_desc = list("mushroom" = 5, "salt" = 5)

/obj/item/weapon/reagent_containers/food/snacks/skrellsnacks/Initialize()
	. = ..()
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/unajerky
	name = "Moghes Imported Sissalik Jerky"
	icon_state = "unathitinred"
	desc = "An incredibly well made jerky, shipped in all the way from Moghes."
	trash = /obj/item/trash/unajerky
	filling_color = "#631212"
	center_of_mass = list("x"=15, "y"=9)

/obj/item/weapon/reagent_containers/food/snacks/unajerky/Initialize()
		..()
		reagents.add_reagent("protein", 8)
		reagents.add_reagent("capsaicin", 2)
		bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/croissant
	name = "croissant"
	desc = "True French cuisine."
	filling_color = "#E3D796"
	icon_state = "croissant"
	nutriment_amt = 6
	nutriment_desc = list("french bread" = 6)

/obj/item/weapon/reagent_containers/food/snacks/croissant/Initialize()
	. = ..()
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/meatbun
	name = "meat bun"
	desc = "Chinese street food, in neither China nor a street."
	filling_color = "#DEDEAB"
	icon_state = "meatbun"
	nutriment_amt = 4

/obj/item/weapon/reagent_containers/food/snacks/meatbun/Initialize()
	. = ..()
	bitesize = 2
	reagents.add_reagent("protein", 4)

/obj/item/weapon/reagent_containers/food/snacks/sashimi
	name = "carp sashimi"
	desc = "Expertly prepared. Hopefully toxin got removed though."
	filling_color = "#FFDEFE"
	icon_state = "sashimi"
	nutriment_amt = 6

/obj/item/weapon/reagent_containers/food/snacks/sashimi/Initialize()
	. = ..()
	reagents.add_reagent("protein", 2)
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/benedict
	name = "eggs benedict"
	desc = "Hey, there's only one egg in this!"
	filling_color = "#FFDF78"
	icon_state = "benedict"
	nutriment_amt = 4

/obj/item/weapon/reagent_containers/food/snacks/benedict/Initialize()
	. = ..()
	reagents.add_reagent("protein", 2)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/beans
	name = "baked beans"
	desc = "Musical fruit in a slightly less musical container."
	filling_color = "#FC6F28"
	icon_state = "beans"
	nutriment_amt = 4
	nutriment_desc = list("beans" = 4)

/obj/item/weapon/reagent_containers/food/snacks/beans/Initialize()
	. = ..()
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/sugarcookie
	name = "sugar cookie"
	desc = "Just like your little sister used to make."
	filling_color = "#DBC94F"
	icon_state = "sugarcookie"
	nutriment_amt = 5
	nutriment_desc = list("sweetness" = 4, "cookie" = 1)

/obj/item/weapon/reagent_containers/food/snacks/sugarcookie/Initialize()
	. = ..()
	bitesize = 1

/obj/item/weapon/reagent_containers/food/snacks/berrymuffin
	name = "berry muffin"
	desc = "A delicious and spongy little cake, with berries."
	icon_state = "berrymuffin"
	filling_color = "#E0CF9B"
	center_of_mass = list("x"=17, "y"=4)
	nutriment_amt = 6
	nutriment_desc = list("sweetness" = 2, "muffin" = 2, "berries" = 2)

/obj/item/weapon/reagent_containers/food/snacks/berrymuffin/Initialize()
	. = ..()
	reagents.add_reagent("nutriment", 6)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/ghostmuffin
	name = "booberry muffin"
	desc = "My stomach is a graveyard! No living being can quench my bloodthirst!"
	icon_state = "berrymuffin"
	filling_color = "#799ACE"
	center_of_mass = list("x"=17, "y"=4)
	nutriment_amt = 6
	nutriment_desc = list("spookiness" = 4, "muffin" = 1, "berries" = 1)

/obj/item/weapon/reagent_containers/food/snacks/ghostmuffin/Initialize()
	. = ..()
	reagents.add_reagent("nutriment", 6)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/eggroll
	name = "egg roll"
	desc = "Free with orders over 10 thalers."
	icon_state = "eggroll"
	filling_color = "#799ACE"
	center_of_mass = list("x"=17, "y"=4)
	nutriment_amt = 4
	nutriment_desc = list("egg" = 4)

/obj/item/weapon/reagent_containers/food/snacks/eggroll/Initialize()
	. = ..()
	reagents.add_reagent("nutriment", 6)
	reagents.add_reagent("protein", 2)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/devilledegg
	name = "devilled eggs"
	desc = "Spicy homestyle favorite."
	icon_state = "devilledegg"
	filling_color = "#799ACE"
	center_of_mass = list("x"=17, "y"=16)
	nutriment_amt = 8
	nutriment_desc = list("egg" = 4, "chili" = 4)

/obj/item/weapon/reagent_containers/food/snacks/devilledegg/Initialize()
	. = ..()
	reagents.add_reagent("nutriment", 6)
	reagents.add_reagent("capsaicin", 2)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/fruitsalad
	name = "fruit salad"
	desc = "Your standard fruit salad."
	icon_state = "fruitsalad"
	filling_color = "#FF3867"
	nutriment_amt = 10
	nutriment_desc = list("fruit" = 10)

/obj/item/weapon/reagent_containers/food/snacks/fruitsalad/Initialize()
	. = ..()
	reagents.add_reagent("nutriment", 10)
	bitesize = 4

/obj/item/weapon/reagent_containers/food/snacks/flowerchildsalad
	name = "flowerchild salad"
	desc = "A fragrant salad."
	icon_state = "flowerchildsalad"
	filling_color = "#FF3867"
	nutriment_amt = 10
	nutriment_desc = list("bittersweet" = 10)

/obj/item/weapon/reagent_containers/food/snacks/flowerchildsalad/Initialize()
	. = ..()
	reagents.add_reagent("nutriment", 10)
	bitesize = 4

/obj/item/weapon/reagent_containers/food/snacks/rosesalad
	name = "flowerchild salad"
	desc = "A fragrant salad."
	icon_state = "rosesalad"
	filling_color = "#FF3867"
	nutriment_amt = 5
	nutriment_desc = list("bittersweet" = 10, "iron" = 5)

/obj/item/weapon/reagent_containers/food/snacks/rosesalad/Initialize()
	. = ..()
	reagents.add_reagent("nutriment", 10)
	reagents.add_reagent("stoxin", 2)
	bitesize = 4

/obj/item/weapon/reagent_containers/food/snacks/eggbowl
	name = "egg bowl"
	desc = "A bowl of fried rice with egg mixed in."
	icon_state = "eggbowl"
	trash = /obj/item/trash/snack_bowl
	filling_color = "#FFFBDB"
	nutriment_amt = 6
	nutriment_desc = list("rice" = 2, "egg" = 4)

/obj/item/weapon/reagent_containers/food/snacks/eggbowl/Initialize()
	. = ..()
	reagents.add_reagent("nutriment", 6)
	reagents.add_reagent("protein", 4)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/porkbowl
	name = "pork bowl"
	desc = "A bowl of fried rice with cuts of meat."
	icon_state = "porkbowl"
	trash = /obj/item/trash/snack_bowl
	filling_color = "#FFFBDB"
	nutriment_amt = 6
	nutriment_desc = list("rice" = 2, "meat" = 4)

/obj/item/weapon/reagent_containers/food/snacks/porkbowl/Initialize()
	. = ..()
	reagents.add_reagent("nutriment", 6)
	reagents.add_reagent("protein", 4)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/tortilla
	name = "tortilla"
	desc = "The base for all your burritos."
	icon_state = "tortilla"
	nutriment_amt = 1
	nutriment_desc = list("bread" = 1)

/obj/item/weapon/reagent_containers/food/snacks/tortilla/Initialize()
	. = ..()
	reagents.add_reagent("nutriment", 2)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/meatburrito
	name = "carne asada burrito"
	desc = "The best burrito for meat lovers."
	icon_state = "carneburrito"
	nutriment_amt = 6
	nutriment_desc = list("tortilla" = 3, "meat" = 3)

/obj/item/weapon/reagent_containers/food/snacks/meatburrito/Initialize()
	. = ..()
	reagents.add_reagent("protein", 6)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/cheeseburrito
	name = "Cheese burrito"
	desc = "It's a burrito filled with cheese."
	icon_state = "cheeseburrito"
	nutriment_amt = 6
	nutriment_desc = list("tortilla" = 3, "cheese" = 3)

/obj/item/weapon/reagent_containers/food/snacks/cheeseburrito/Initialize()
	. = ..()
	reagents.add_reagent("nutriment", 6)
	reagents.add_reagent("protein", 2)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/fuegoburrito
	name = "fuego phoron burrito"
	desc = "A super spicy burrito."
	icon_state = "fuegoburrito"
	nutriment_amt = 6
	nutriment_desc = list("chili peppers" = 5, "tortilla" = 1)

/obj/item/weapon/reagent_containers/food/snacks/fuegoburrito/Initialize()
	. = ..()
	reagents.add_reagent("nutriment", 6)
	reagents.add_reagent("capsaicin", 4)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/nachos
	name = "nachos"
	desc = "Chips from Old Mexico."
	icon_state = "nachos"
	nutriment_amt = 2
	nutriment_desc = list("salt" = 1)

/obj/item/weapon/reagent_containers/food/snacks/nachos/Initialize()
	. = ..()
	reagents.add_reagent("nutriment", 1)
	bitesize = 1

/obj/item/weapon/reagent_containers/food/snacks/cheesenachos
	name = "cheesy nachos"
	desc = "The delicious combination of nachos and melting cheese."
	icon_state = "cheesenachos"
	nutriment_amt = 5
	nutriment_desc = list("salt" = 2, "cheese" = 3)

/obj/item/weapon/reagent_containers/food/snacks/cheesenachos/Initialize()
	. = ..()
	reagents.add_reagent("nutriment", 5)
	reagents.add_reagent("protein", 2)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/cubannachos
	name = "cuban nachos"
	desc = "That's some dangerously spicy nachos."
	icon_state = "cubannachos"
	nutriment_amt = 6
	nutriment_desc = list("salt" = 1, "cheese" = 2, "chili peppers" = 3)

/obj/item/weapon/reagent_containers/food/snacks/cubannachos/Initialize()
	. = ..()
	reagents.add_reagent("nutriment", 5)
	reagents.add_reagent("capsaicin", 4)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/curryrice
	name = "curry rice"
	desc = "That's some dangerously spicy rice."
	icon_state = "curryrice"
	nutriment_amt = 6
	nutriment_desc = list("salt" = 1, "rice" = 2, "chili peppers" = 3)

/obj/item/weapon/reagent_containers/food/snacks/curryrice/Initialize()
	. = ..()
	reagents.add_reagent("nutriment", 5)
	reagents.add_reagent("capsaicin", 4)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/piginblanket
	name = "pig in a blanket"
	desc = "A sausage embedded in soft, fluffy pastry. Free this pig from its blanket prison by eating it."
	icon_state = "piginblanket"
	nutriment_amt = 6
	nutriment_desc = list("meat" = 3, "pastry" = 3)

/obj/item/weapon/reagent_containers/food/snacks/piginblanket/Initialize()
	. = ..()
	reagents.add_reagent("nutriment", 6)
	reagents.add_reagent("protein", 4)
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/piginblanket
	name = "pig in a blanket"
	desc = "A sausage embedded in soft, fluffy pastry. Free this pig from its blanket prison by eating it."
	icon_state = "piginblanket"
	nutriment_amt = 6
	nutriment_desc = list("meat" = 3, "pastry" = 3)

/obj/item/weapon/reagent_containers/food/snacks/piginblanket/Initialize()
	. = ..()
	reagents.add_reagent("nutriment", 6)
	reagents.add_reagent("protein", 4)
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/wormsickly
	name = "sickly worm"
	desc = "A worm, it doesn't look particularily healthy, but it will still serve as good fishing bait."
	icon_state = "worm_sickly"
	nutriment_amt = 1
	nutriment_desc = list("bugflesh" = 1)
	w_class = ITEMSIZE_TINY

/obj/item/weapon/reagent_containers/food/snacks/wormsickly/Initialize()
	. = ..()
	reagents.add_reagent("fishbait", 10)
	bitesize = 5

/obj/item/weapon/reagent_containers/food/snacks/worm
	name = "strange worm"
	desc = "A peculiar worm, freshly plucked from the earth."
	icon_state = "worm"
	nutriment_amt = 1
	nutriment_desc = list("bugflesh" = 1)
	w_class = ITEMSIZE_TINY

/obj/item/weapon/reagent_containers/food/snacks/worm/Initialize()
	. = ..()
	reagents.add_reagent("fishbait", 20)
	bitesize = 5

/obj/item/weapon/reagent_containers/food/snacks/wormdeluxe
	name = "deluxe worm"
	desc = "A fancy worm, genetically engineered to appeal to fish."
	icon_state = "worm_deluxe"
	nutriment_amt = 5
	nutriment_desc = list("bugflesh" = 1)
	w_class = ITEMSIZE_TINY

/obj/item/weapon/reagent_containers/food/snacks/wormdeluxe/Initialize()
	. = ..()
	reagents.add_reagent("fishbait", 40)
	bitesize = 5