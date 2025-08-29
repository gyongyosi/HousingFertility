
/*------------------------------------------------------------------------------
	create aggregate figures
------------------------------------------------------------------------------*/

use "${temp}/internal_migration_02", clear

gen moving_ = 1

collapse (sum) moving , by(ty jel)

reshape wide moving_, i(ty) j(jel)


#d ;
	twoway line moving_* ty if inrange(ty, 2008, .), 
		graphregion(color(white))
		legend(order(1 "Across settlements" 2 "Across districts (Budapest)" 3 "Within settlement"))
		xtitle("")
		ytitle("Number of moves")
		lpattern(solid _ - )
		xline(2015.5 2019.5)
		
		;
#d cr
graph export "${temp}/migration_by_type.pdf", as(pdf) replace




use "${temp}/internal_migration_02", clear

keep if jel == 1
keep if nem == 2

gen moving_ = 1
gen age_cat = .
replace age_cat = 1 if inrange(korev, . , 14)
replace age_cat = 2 if inrange(korev, 15 , 49)
replace age_cat = 3 if inrange(korev, 50 , .)

collapse (sum) moving, by(age_cat ty )

reshape wide moving_, i(ty) j(age_cat)


#d ;
	twoway line moving_* ty, 
		graphregion(color(white))
		legend(order(1 "Age 0-14" 2 "Age 15-49" 3 "Age 50+"))
		xtitle("")
		ytitle("Number of moves (women only)")
		lpattern(solid _ - )
		xline(2015.5 2019.5)
		;
#d cr




use "${temp}/internal_migration_02", clear

keep if jel == 1
keep if nem == 2

gen moving_ = 1
gen age_cat = .
forval i = 15(5)45 {
	local j = `i' + 4
	replace age_cat = `i' if inrange(korev, `i', `j')
}

drop if age_cat == .

collapse (sum) moving, by(age_cat ty )

reshape wide moving_, i(ty) j(age_cat)


#d ;
	twoway line moving_* ty, 
		graphregion(color(white))
		
		xtitle("")
		ytitle("Number of moves (women only)")
		lpattern(solid _ - )
		xline(2015.5 2019.5)
		;
#d cr






use "${temp}/internal_migration_02", clear

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


collapse (sum) moving_, by(moving_type ty )

reshape wide moving_, i(ty) j(moving_type)


#d ;
	twoway line moving_* ty, 
		graphregion(color(white))
		legend(order(1 "non-CSOK to non-CSOK" 2 "CSOK to non_CSOK" 3 "non-CSOK to CSOK" 4 "CSOK to CSOK"))
		xtitle("")
		lcolor($color1 $color2 $color3 $color4 $color5)
		lpattern(solid _ - solid _)
		ytitle("Number of moves (women only)")
		xline(2019.5)
		;
#d cr


#d ;
	twoway line moving_2 moving_3 moving_4  ty, 
		graphregion(color(white))
		legend(order(1 "CSOK to non_CSOK" 2 "non-CSOK to CSOK" 3 "CSOK to CSOK"))
		xtitle("")
		lcolor($color1 $color2 $color3 $color4 $color5)
		lpattern(solid _ - solid _)
		ytitle("Number of moves (women only)")
		xline(2019.5)
		;
#d cr

