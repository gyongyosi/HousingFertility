
/*------------------------------------------------------------------------------
	plot fertility by cohort
------------------------------------------------------------------------------*/

use ${aggr_demo}/aggregate_demography, clear
drop men
keep if inrange(age, 15, 49)
gen cohort = ty - age
ren women N_women
tempfile cohortsize
save `cohortsize'



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

gen births = 1

collapse (sum) births, by(cohort age)
drop if cohort == .

merge m:1 cohort age using `cohortsize', nogen keep(1 3)

gen f = births / N_women
sort cohort age
bys cohort (age): gen f_cumulative_ = sum(f)

reshape wide f_cumulative_ , i(age) j(cohort)





#d ;
	line f_cumulative_1970 f_cumulative_1971 f_cumulative_1972 f_cumulative_1973 f_cumulative_1974 age ,
		lcolor($color1 $color2 $color3 $color4 $color5)
		lpattern(solid _ - solid _)
		graphregion(color(white))
		legend(order(1 "Cohort: 1970" 2 "1971" 3 "1972" 4 "1973" 5 "1973"))
		xtitle("Age")
		ytitle("Cumulative average number of kids per women")
		;
#d cr




