
/*------------------------------------------------------------------------------
	plot births by cohort
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

gen f0 = births 
gen f1 = births / N_women

sort cohort age
forval i = 0(1)1 {
	bys cohort (age): gen f`i'_cumulative_ = sum(f`i')
}


reshape wide f* , i(age) j(cohort)





#d ;
	line f0_cumulative_1970 f0_cumulative_1971 f0_cumulative_1972 f0_cumulative_1973 f0_cumulative_1974 age ,
		lcolor($color1 $color2 $color3 $color4 $color5)
		lpattern(solid _ - solid _)
		graphregion(color(white))
		legend(order(1 "Cohort: 1970" 2 "1971" 3 "1972" 4 "1973" 5 "1973"))
		xtitle("Age")
		ytitle("Cumulative number of kids by cohort")
		;
#d cr




#d ;
	line f0_cumulative_1975 f0_cumulative_1976 f0_cumulative_1977 f0_cumulative_1978 f0_cumulative_1979 age ,
		lcolor($color1 $color2 $color3 $color4 $color5)
		lpattern(solid _ - solid _)
		graphregion(color(white))
		legend(order(1 "Cohort: 1975" 2 "1976" 3 "1977" 4 "1978" 5 "1979"))
		xtitle("Age")
		ytitle("Cumulative number of kids by cohort")
		;
#d cr



#d ;
	line f0_cumulative_1980 f0_cumulative_1981 f0_cumulative_1982 f0_cumulative_1983 f0_cumulative_1984 age ,
		lcolor($color1 $color2 $color3 $color4 $color5)
		lpattern(solid _ - solid _)
		graphregion(color(white))
		legend(order(1 "Cohort: 1980" 2 "1981" 3 "1982" 4 "1983" 5 "1984"))
		xtitle("Age")
		ytitle("Cumulative number of kids by cohort")
		;
#d cr




#d ;
	line f1_cumulative_1970 f1_cumulative_1971 f1_cumulative_1972 f1_cumulative_1973 f1_cumulative_1974 age ,
		lcolor($color1 $color2 $color3 $color4 $color5)
		lpattern(solid _ - solid _)
		graphregion(color(white))
		legend(order(1 "Cohort: 1970" 2 "1971" 3 "1972" 4 "1973" 5 "1973"))
		xtitle("Age")
		ytitle("Cumulative average number of kids by cohort")
		;
#d cr


#d ;
	line f1_cumulative_1975 f1_cumulative_1976 f1_cumulative_1977 f1_cumulative_1978 f1_cumulative_1979 age ,
		lcolor($color1 $color2 $color3 $color4 $color5)
		lpattern(solid _ - solid _)
		graphregion(color(white))
		legend(order(1 "Cohort: 1975" 2 "1976" 3 "1977" 4 "1978" 5 "1979"))
		xtitle("Age")
		ytitle("Cumulative average number of kids by cohort")
		;
#d cr



#d ;
	line f1_cumulative_1980 f1_cumulative_1981 f1_cumulative_1982 f1_cumulative_1983 f1_cumulative_1984 age ,
		lcolor($color1 $color2 $color3 $color4 $color5)
		lpattern(solid _ - solid _)
		graphregion(color(white))
		legend(order(1 "Cohort: 1980" 2 "1981" 3 "1982" 4 "1983" 5 "1984"))
		xtitle("Age")
		ytitle("Cumulative average number of kids by cohort")
		;
#d cr




/*------------------------------------------------------------------------------
	
------------------------------------------------------------------------------*/

