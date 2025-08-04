


use ${live_births}/live_births, clear

keep if inrange(ty, 2000, .)


#d ;
	line live_birth_all ty , 
		graphregion(color(white))
		xtitle("")
		xline(2015)
		;
#d cr
graph export ${output}/fig_aggregate_live_birth_all.pdf, as(pdf) replace




#d ;
	line sh1 ty , 
		graphregion(color(white))
		xtitle("")
		xline(2015)
		;
#d cr
graph export ${output}/fig_aggregate_sh1_per_1000females.pdf, as(pdf) replace



#d ;
	line sh2 ty , 
		graphregion(color(white))
		xtitle("")
		xline(2015)
		;
#d cr
graph export ${output}/fig_aggregate_sh2_inwedlock_per_1000married.pdf, as(pdf) replace


#d ;
	line sh3 ty , 
		graphregion(color(white))
		xtitle("")
		xline(2015)
		;
#d cr
graph export ${output}/fig_aggregate_sh3_outofwedlock_per_1000unmarried.pdf, as(pdf) replace



#d ;
	line average_age_first average_age ty , 
		graphregion(color(white))
		xtitle("")
		ytitle("Average age of females at childbirth")
		xline(2015)
		legend(order(1 "First child" 2 "All children"))
		lpattern(solid _)
		lcolor("$color1" "$color2")
		;
#d cr
graph export ${output}/fig_aggregate_average_age.pdf, as(pdf) replace




#d ;
	line sh4 ty , 
		graphregion(color(white))
		xtitle("")
		xline(2015)
		;
#d cr
graph export ${output}/fig_aggregate_sh4_extramarital.pdf, as(pdf) replace





#d ;
	line sh5 ty , 
		graphregion(color(white))
		xtitle("")
		xline(2015)
		;
#d cr
graph export ${output}/fig_aggregate_sh5_blow2500.pdf, as(pdf) replace



