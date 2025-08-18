

/*------------------------------------------------------------------------------
	create aggregate figures
------------------------------------------------------------------------------*/

use ${temp}/internal_migration_01, clear

gen moving_ = 1

collapse (sum) moving , by(ty jel)

reshape wide moving_, i(ty) j(jel)


#d ;
	twoway line moving_* ty, 
		graphregion(color(white))
		legend(order(1 "Across settlements" 2 "Across districts (Budapest)" 3 "Within settlement"))
		xtitle("")
		ytitle("Number of moves")
		;
#d cr




use ${temp}/internal_migration_01, clear

keep if jel == 1
keep if nem == 2

gen moving_ = 1
gen age_cat = .
replace age_cat = 1 if inrange(szulev, . , 14)
replace age_cat = 1 if inrange(szulev, 15 , 49)
replace age_cat = 1 if inrange(szulev, 50 , .)

collapse (sum) moving, by(age_cat ty )

reshape wide moving_, i(ty) j(age_cat)


#d ;
	twoway line moving_* ty, 
		graphregion(color(white))
		legend(order(1 "Age 0-14" 2 "Age 15-49" 3 "Age 50+"))
		xtitle("")
		ytitle("Number of moves (women only)")
		;
#d cr


use ${temp}/internal_migration_01, clear

keep if jel == 1 | jel == 2
keep if nem == 2

gen moving_ = 1

gen moving_type = .
replace moving_type = 1 if in_village_csok == 0 & out_village_csok == 0
replace moving_type = 2 if in_village_csok == 0 & out_village_csok == 1
replace moving_type = 3 if in_village_csok == 1 & out_village_csok == 0
replace moving_type = 4 if in_village_csok == 1 & out_village_csok == 1

lab def moving_type_csok 1 "non-CSOK to non-CSOK" 2 "CSOK to non_CSOK" 3 "non-CSOK to CSOK" 4 "CSOK to CSOK"
lab val moving_type moving_type_csok 


collapse (sum) moving, by(moving_type ty )

reshape wide moving_, i(ty) j(moving_type)


#d ;
	twoway line moving_* ty, 
		graphregion(color(white))
		legend(order(1 "non-CSOK to non-CSOK" 2 "CSOK to non_CSOK" 3 "non-CSOK to CSOK" 4 "CSOK to CSOK"))
		xtitle("")
		lcolor($color1 $color2 $color3 $color4 $color5)
		lpattern(solid _ - solid _)
		ytitle("Number of moves (women only)")
		;
#d cr

