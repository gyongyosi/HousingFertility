
/*------------------------------------------------------------------------------
	aggregate HUN TFR
------------------------------------------------------------------------------*/


clear
import delimited ${tfr_worldbank}/API_SP.DYN.TFRT.IN_DS2_en_csv_v2_230.csv, rowrange(3) varnames(3)

forval i = 5(1)70 {
	local j = `i' + 1955
	ren v`i' y_`j'
}

ren lastupdateddate country_name
ren v2 country_code
ren v3 indicator_name
ren v4 indicator_code

drop in 1

reshape long y_, i(country* indicator*) j(ty)
ren y_ TFR

#d ;
	line TFR ty if country_name == "Hungary" & inrange(ty, 2000, .),
		graphregion(color(white))
		xtitle("")
		ytitle("Total fertility rate")
		lcolor("$color1")
		xline(2015 2019)
		;
	
#d cr
graph export ${output}/TFR_Hungary.pdf, as(pdf) replace








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



