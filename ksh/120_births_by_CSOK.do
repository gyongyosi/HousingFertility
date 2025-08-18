
/*------------------------------------------------------------------------------
	number of births by CSOK status
------------------------------------------------------------------------------*/

use ${temp}/live_birth_001, clear


gen cohort = yofd(mother_birth_date)
gen cohort_tm = mofd(mother_birth_date)
format cohort_tm %tm

gen tm_baby_birth_date = mofd(baby_birth_date)
gen ty_baby_birth_date = yofd(baby_birth_date)
format tm_baby_birth_date %tm

gen ty = yofd(baby_birth_date)

gen age_tm = tm_baby_birth_date - cohort_tm
gen age = ty_baby_birth_date - cohort
keep if inrange(age, 15, 49)

gen births_ = 1

collapse (sum) births, by(cohort age village_csok)
drop if cohort == .



reshape wide births_, i(age cohort) j(village_csok)


sort cohort age

forval i = 0(1)1 {
	gen f_`i' = births_`i' /// should get settlement level cohort sizes!!!
	bys cohort (age): gen f_cumulative_`i'_ = sum(f_`i')
}


reshape wide f_cumulative_* , i(age) j(cohort)


forval i = 1970(1)1984 {
	#d ;
		line f_cumulative_0_`i' f_cumulative_1_`i' age,
			lcolor($color1 $color2 $color3 $color4 $color5)
			lpattern(solid _ - solid _)
			graphregion(color(white))
			legend(order(1 "Village CSOK ineligible" 2 "Village CSOK eligible"))
			xtitle("Age")
			ytitle("Cumulative number of births (Cohort `i')")
			;
	#d cr
}





/*------------------------------------------------------------------------------
	number of births by CSOK status
	around the cutoff
------------------------------------------------------------------------------*/

use ${temp}/live_birth_001, clear

keep if inrange(de01_2018, 2000, 8000)

gen cohort = yofd(mother_birth_date)
gen cohort_tm = mofd(mother_birth_date)
format cohort_tm %tm

gen tm_baby_birth_date = mofd(baby_birth_date)
gen ty_baby_birth_date = yofd(baby_birth_date)
format tm_baby_birth_date %tm

gen ty = yofd(baby_birth_date)

gen age_tm = tm_baby_birth_date - cohort_tm
gen age = ty_baby_birth_date - cohort
keep if inrange(age, 15, 49)

gen births_ = 1

collapse (sum) births, by(cohort age village_csok)
drop if cohort == .



reshape wide births_, i(age cohort) j(village_csok)


sort cohort age

forval i = 0(1)1 {
	gen f_`i' = births_`i' /// should get settlement level cohort sizes!!!
	bys cohort (age): gen f_cumulative_`i'_ = sum(f_`i')
}


reshape wide f_cumulative_* , i(age) j(cohort)


forval i = 1970(1)1984 {
	#d ;
		line f_cumulative_0_`i' f_cumulative_1_`i' age,
			lcolor($color1 $color2 $color3 $color4 $color5)
			lpattern(solid _ - solid _)
			graphregion(color(white))
			legend(order(1 "Village CSOK ineligible" 2 "Village CSOK eligible"))
			xtitle("Age")
			ytitle("Cumulative number of births (Cohort `i')")
			;
	#d cr
}

