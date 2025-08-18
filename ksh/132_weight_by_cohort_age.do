


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

collapse (mean) weight below2500, by(cohort age)
drop if cohort == .

ren weight weight_
ren below2500 below2500_

reshape wide weight below , i(age) j(cohort)


#d ;
	line weight_1970 weight_1971 weight_1972 weight_1973 weight_1974  age ,
		lcolor($color1 $color2 $color3 $color4 $color5)
		lpattern(solid _ - solid _)
		graphregion(color(white))
		legend(order(1 "Cohort: 1970" 2 "1971" 3 "1972" 4 "1973" 5 "1973"))
		xtitle("Age")
		ytitle("Average weight of newborns by cohort")
		;
#d cr


#d ;
	line weight_1975 weight_1976 weight_1977 weight_1978 weight_1979  age ,
		lcolor($color1 $color2 $color3 $color4 $color5)
		lpattern(solid _ - solid _)
		graphregion(color(white))
		legend(order(1 "Cohort: 1975" 2 "1976" 3 "1977" 4 "1978" 5 "1979"))
		xtitle("Age")
		ytitle("Average weight of newborns by cohort")
		;
#d cr



