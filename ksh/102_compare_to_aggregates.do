

/*------------------------------------------------------------------------------
	create aggregate figures and compare to aggregate KSH statistics
------------------------------------------------------------------------------*/

use ${live_birth_aggr}/live_births, clear


use ${temp}/live_birth_001, clear

gen one = 1
gen boy = 1 if nem == 1
gen girl = 1 if nem == 2
gen below_2500 = (suly < 2500)


collapse (sum) one boy girl (mean) below_2500 nokor, by(ty)

merge 1:1 ty using ${live_birth_aggr}/live_births, nogen keep(1 3)

#d ;
	twoway line one live_birth_all ty, 
		legend(order(1 "Number of births (LB)" 2 "Number of births (Aggregate)"))
		lcolor($color1 $color2)
		lpattern(solid _)
		graphregion(color(white))
		;
#d cr
graph export ${output}/fig_comparing_LB_aggregate_number_of_births.pdf, as(pdf) replace



#d ;
	twoway line boy live_birth_boy ty ty, 
		legend(order(1 "Number of boys (LB)" 2 "Number of boys (Aggregate)"))
		lcolor($color1 $color2)
		lpattern(solid _)
		graphregion(color(white))
		;
#d cr
graph export ${output}/fig_comparing_LB_aggregate_number_of_boys.pdf, as(pdf) replace


#d ;
	twoway line girl live_birth_girl ty ty, 
		legend(order(1 "Number of girls (LB)" 2 "Number of girls (Aggregate)"))
		lcolor($color1 $color2)
		lpattern(solid _)
		graphregion(color(white))
		;
#d cr
graph export ${output}/fig_comparing_LB_aggregate_number_of_girls.pdf, as(pdf) replace


#d ;
	twoway line below_2500 sh5_below_2500 ty ty, 
		legend(order(1 "Share below 2500g (LB)" 2 "Share below 2500g (Aggregate)"))
		lcolor($color1 $color2)
		lpattern(solid _)
		graphregion(color(white))
		;
#d cr
graph export ${output}/fig_comparing_LB_aggregate_below2500.pdf, as(pdf) replace



#d ;
	twoway line nokor average_age ty ty, 
		legend(order(1 "Average age of mother (LB)" 2 "Average age of mother (Aggregate)"))
		lcolor($color1 $color2)
		lpattern(solid _)
		graphregion(color(white))
		;
#d cr
graph export ${output}/fig_comparing_LB_aggregate_average_age_mother.pdf, as(pdf) replace


