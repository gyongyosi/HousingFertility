
use ${temp}/live_birth_001, clear

tab ossz1



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

collapse (sum) births, by(cohort age ossz1)
drop if cohort == .


replace ossz1 = 3 if ossz1 >3

reshape wide births_, i(age cohort) j(ossz1)


sort cohort age

forval i = 1(1)3 {
	gen f_`i' = births_`i'
	bys cohort (age): gen f_cumulative_`i'_ = sum(f_`i')
}


reshape wide f_cumulative_* , i(age) j(cohort)


forval i = 1970(1)1984 {
	#d ;
		line f_cumulative_1_`i' f_cumulative_2_`i' f_cumulative_3_`i'   age,
			lcolor($color1 $color2 $color3 $color4 $color5)
			lpattern(solid _ - solid _)
			graphregion(color(white))
			legend(order( 1 "First child" 2 "Second" 3 "3+"))
			xtitle("Age")
			ytitle("Cumulative number of births (Cohort `i')")
			;
	#d cr
}


