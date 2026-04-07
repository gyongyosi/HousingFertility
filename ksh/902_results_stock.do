
/*
/*------------------------------------------------------------------------------
	MAIN TABLE -- stock
------------------------------------------------------------------------------*/



use "${temp}/census_002_trim_updated", clear

*keep if inrange(ty, 2019, 2020)
*sample 5

keep if inrange(ty, 2014, 2024)
keep if CSOK_15000 != .

foreach BW in "0000" 5000 15000 {
	gen CSOK_`BW'_POST = CSOK_`BW' * POST
}

gen s_CSOK = subsidy_3 / women_15_49_TSTAR
gen s_CSOK_POST = s_CSOK * POST
gen ln_de01_2018 = ln(de01)


foreach BW in  "0000" 5000 15000  {
	eststo clear

	eststo q_0 : reghdfe C_childrenNEW CSOK_`BW'_POST if inrange(ty, 2014, 2024), absorb($x0_s) vce("cluster ksh4")
		estadd local time "Yes"

	eststo q_1 : reghdfe C_childrenNEW CSOK_`BW'_POST if inrange(ty, 2014, 2024), absorb($x0_s $x1_post ) vce("cluster ksh4")
		estadd local time "Yes"
		estadd local mother "Yes"


	eststo q_2 : reghdfe C_childrenNEW CSOK_`BW'_POST if inrange(ty, 2014, 2024), absorb($x0_s $x1_post $x2_post ) vce("cluster ksh4")
		estadd local time "Yes"
		estadd local mother "Yes"
		estadd local muni "Yes"


	eststo q_3 : reghdfe C_childrenNEW CSOK_`BW'_POST if inrange(ty, 2014, 2024), absorb($x0_s $x1_post $x2_post $x3_post) vce("cluster ksh4")
		estadd local time "Yes"
		estadd local mother "Yes"
		estadd local muni "Yes"
		estadd local region_FE "Yes"

	eststo q_4 : reghdfe C_childrenNEW CSOK_`BW'_POST if inrange(ty, 2014, 2024), absorb($x0_s $x1_post $x2_post $x4_post) vce("cluster ksh4")
		estadd local time "Yes"
		estadd local mother "Yes"
		estadd local muni "Yes"
		estadd local county_FE "Yes"

	eststo q_5 : reghdfe C_childrenNEW CSOK_`BW'_POST if inrange(ty, 2014, 2024), absorb($x0_s $x1_post $x2_post $x5_post) vce("cluster ksh4")
		estadd local time "Yes"
		estadd local mother "Yes"
		estadd local muni "Yes"
		estadd local subregion_FE "Yes"



	esttab

	#d ;
	esttab q* 	using "${output}/tab_mainOLS_stock_BW`BW'.rtf",  replace nocons nomtitle
		keep(CSOK_`BW'_POST  ) coeflabel( CSOK_`BW'_POST "Rural CSOK \(\times\) Post")	
		 nonote obslast  star(+ 0.1 * 0.05 ** 0.01) se 
		scalars("time Mother \& Year FE"
				"mother Mother controls"
				"muni Municipality controls"
				"region_FE Region FE"
				"county_FE County FE"
				"subregion_FE Subregion FE"
				) 
		;
	#d cr
}



foreach BW in  5000   15000  {
	
	eststo clear

	eststo q_1 : reghdfe C_childrenNEW CSOK_0000_POST if CSOK_`BW' != . &  inrange(ty, 2014, 2024), absorb($x0_s ) vce("cluster ksh4")
		estadd local time "Yes"

	eststo q_2 : reghdfe C_childrenNEW  CSOK_0000_POST if CSOK_`BW' != . &  inrange(ty, 2014, 2024), absorb($x0_s $x1_post  ) vce("cluster ksh4")
		estadd local time "Yes"
		estadd local mother "Yes"

	eststo q_3 : reghdfe C_childrenNEW CSOK_0000_POST if CSOK_`BW' != . &  inrange(ty, 2014, 2024), absorb($x0_s $x1_post $x2_post $x3_post ) vce("cluster ksh4")
		estadd local time "Yes"
		estadd local mother "Yes"
		estadd local muni "Yes"
		estadd local region_FE "Yes"
		
	qui : reghdfe CSOK_0000_POST  CSOK_`BW'_POST if inrange(ty, 2014, 2024), absorb($x0_s $x1_post $x2_post $x3_post) vce("cluster ksh4")
		local F_stat = (_b[CSOK_`BW'_POST] / _se[CSOK_`BW'_POST])^2
	
	eststo q_IV_1 : ivreghdfe C_childrenNEW (CSOK_0000_POST = CSOK_`BW'_POST) if inrange(ty, 2014, 2024), absorb($x0_s $x1_post $x2_post $x3_post) vce("cluster ksh4")
		estadd local time "Yes"
		estadd local mother "Yes"
		estadd local muni "Yes"
		estadd local region_FE "Yes"
		estadd scalar Fstat = `F_stat'

		
	qui : reghdfe s_CSOK_POST  CSOK_`BW'_POST if inrange(ty, 2014, 2024), absorb($x0_s $x1_post $x2_post $x3_post) vce("cluster ksh4")
		local F_stat = (_b[CSOK_`BW'_POST] / _se[CSOK_`BW'_POST])^2
	
	eststo q_IV_2 : ivreghdfe C_childrenNEW (s_CSOK_POST = CSOK_`BW'_POST) if inrange(ty, 2014, 2024), absorb($x0_s $x1_post $x2_post $x3_post) vce("cluster ksh4")
		estadd local time "Yes"
		estadd local mother "Yes"
		estadd local muni "Yes"
		estadd local region_FE "Yes"
		estadd scalar Fstat = `F_stat'


	esttab

	#d ;
	esttab q* 	using "${output}/tab_main_stock_BW`BW'.rtf",  replace nocons nomtitle
		keep(CSOK_0000_POST s_CSOK_POST ) coeflabel( CSOK_0000_POST "Rural CSOK \(\times\) Post" s_CSOK_POST "Subsidy")	
		 nonote obslast  star(+ 0.1 * 0.05 ** 0.01) se 
		scalars("time Mother \& Year FE"
				"mother Mother controls"
				"muni Municipality controls"
				"region_FE Region FE"
				"Fstat F statistics"
				) 
		;
	#d cr
}


*/

/*------------------------------------------------------------------------------
	PRE-TREND stock
------------------------------------------------------------------------------*/


cap log close OC_pretrend_stock
log using "${output}/OC_pretrend_stock", text replace name(OC_pretrend_stock)

local controls_0 "${x0_s}"
local controls_1 "`controls_0'  ${x1_ty}"
local controls_2 "`controls_1'  ${x2_ty}"
local controls_3 "`controls_2'  ${x3_ty}"
local controls_4 "`controls_3'  ${x4_ty}"
local controls_5 "`controls_4'  ${x5_ty}"
local controls_6 "`controls_4'  ${x6_ty}"
local controls_7 "`controls_4'  ${x7_ty}"


use "${temp}/census_002_trim_updated", clear

*keep if inrange(ty, 2018, 2020)
*sample 3

gen ln_de01_2018 = ln(de01)

keep if inrange(ty, 2014, 2024)
keep if CSOK_15000 != .


foreach BW in /* "0000"  5000 */ 15000 { 
	forval CONTROLS = 0(1)7 {

		reghdfe C_childrenNEW i.CSOK_`BW'##ib2019.ty if inrange(ty, 2014, 2024), absorb(`controls_`CONTROLS'') vce("cluster ksh4")

		gen TIME = _n if inrange(_n, 2014, 2024)
		gen b = .
		gen se = .

		forval i = 2008(1)2024 {
			cap replace b = _b[1.CSOK_`BW'#`i'.ty] if TIME == `i'
			cap replace se = _se[1.CSOK_`BW'#`i'.ty] if TIME == `i'
		}
		gen hi = b + 1.96 * se
		gen lo = b - 1.96 * se

		#d ;
			twoway 
				(connected b TIME, lcolor("$color1") mcolor("$color1"))
				(rcap hi lo TIME, color("$color1")), 
					graphregion(color(white))
					xtitle("Year")
					ytitle("Total Children")
					legend(off)
					xline(2019.5)
					yline(0)
					xlabel(2014(1)2024)
				;
		#d cr
		graph export "${output}/pretrend_main_stock_BW`BW'_controls`CONTROLS'.pdf", as(pdf) replace
		drop b se hi lo TIME
		
	}
}

cap log close OC_pretrend_stock




/*------------------------------------------------------------------------------
	HETEROGENEITY -- STOCK -- by individual characteristics
------------------------------------------------------------------------------*/


use "${temp}/census_002_trim_updated", clear

*keep if inrange(ty, 2019, 2020)
*sample 3

keep if inrange(ty, 2014, 2024)
keep if CSOK_15000 != .

gen CSOK_0000_POST = CSOK_0000 * POST
gen CSOK_5000_POST = CSOK_5000 * POST
gen CSOK_15000_POST = CSOK_15000 * POST

gen ln_de01_2018 = ln(de01)

foreach BW in  /*"0000"*/ 5000 15000  {

	eststo clear

	eststo q_1 : reghdfe C_childrenNEW CSOK_`BW'_POST if inrange(ty, 2014, 2024) & kids_by_2018 == 0, absorb($x0_s $x1_post $x2_post $x3_post) vce("cluster ksh4")

	eststo q_2 : reghdfe C_childrenNEW CSOK_`BW'_POST if inrange(ty, 2014, 2024) & kids_by_2018 != 0, absorb($x0_s $x1_post $x2_post $x3_post) vce("cluster ksh4")

	eststo q_3 : reghdfe C_childrenNEW CSOK_`BW'_POST if inrange(ty, 2014, 2024) & high_edu == 0, absorb($x0_s $x1_post $x2_post $x3_post) vce("cluster ksh4")

	eststo q_4 : reghdfe C_childrenNEW CSOK_`BW'_POST if inrange(ty, 2014, 2024) & high_edu == 1, absorb($x0_s $x1_post $x2_post $x3_post) vce("cluster ksh4")

	eststo q_5 : reghdfe C_childrenNEW CSOK_`BW'_POST if inrange(ty, 2014, 2024) & inrange(ty_mother_birth, ., 1988) , absorb($x0_s $x1_post $x2_post $x3_post) vce("cluster ksh4")

	eststo q_6 : reghdfe C_childrenNEW CSOK_`BW'_POST if inrange(ty, 2014, 2024)  & inrange(ty_mother_birth, 1989, .) , absorb($x0_s $x1_post $x2_post $x3_post) vce("cluster ksh4")

	eststo q_7 : reghdfe C_childrenNEW CSOK_`BW'_POST if inrange(ty, 2014, 2024) & marriedBy2019  == 0 , absorb($x0_s $x1_post $x2_post $x3_post) vce("cluster ksh4")

	eststo q_8 : reghdfe C_childrenNEW CSOK_`BW'_POST if inrange(ty, 2014, 2024)  & marriedBy2019  == 1 , absorb($x0_s $x1_post $x2_post $x3_post) vce("cluster ksh4")


	#d ;
	esttab q* 	using "${output}/tab_hetero_stock_BW`BW'.rtf",  replace nocons nomtitle
		keep(CSOK_`BW'_POST  ) coeflabel( CSOK_`BW'_POST "Rural CSOK \(\times\) Post" )	
		 nonote obslast  star(+ 0.1 * 0.05 ** 0.01) se 
		scalars("time Mother \& Year FE"
				"mother Mother controls"
				"muni Municipality controls"
				"region_FE Region FE"
				) 
		;
	#d cr

	
}





/*------------------------------------------------------------------------------
	HETEROGENEITY -- STOCK -- by mover status
------------------------------------------------------------------------------*/


use "${temp}/census_002_trim_updated", clear

*keep if inrange(ty, 2019, 2020)
*sample 3

keep if inrange(ty, 2014, 2024)
keep if CSOK_15000 != .

gen eterul_ksh4 = floor(eterul / 10)
gen eterul_ksh4_bpker = floor(eterul / 10)

gen MOVE = .
replace MOVE = 0 if lakev_x == 0
replace MOVE = 0 if lakev_x == 1 & lakev < 2019
replace MOVE = 1 if lakev_x == 1 & lakev >= 2019
replace MOVE = 2 if lakev_x == 1 & lakev >= 2019 & ksh4 == eterul_ksh4
replace MOVE = 3 if lakev_x == 1 & lakev >= 2019 & ksh4 != eterul_ksh4 & inrange(eterul_ksh4, 4000, 9999) 

lab def MOVE 0 "did not move" 1 "moved (across muni)" 2 "moved (within muni)" 3 "moved (from abroad)"
lab val MOVE MOVE

gen CSOK_0000_POST = CSOK_0000 * POST
gen CSOK_5000_POST = CSOK_5000 * POST
gen CSOK_15000_POST = CSOK_15000 * POST

cap gen ln_de01_2018 = ln(de01)


foreach BW in /* "0000" */ 15000 5000   {

	eststo clear

	eststo q_1a : reghdfe C_childrenNEW CSOK_`BW'_POST if inrange(ty, 2014, 2024) & MOVE == 0, absorb($x0_s $x1_post $x2_post $x3_post) vce("cluster ksh4")
	
	eststo q_1b : ivreghdfe C_childrenNEW (CSOK_0000_POST = CSOK_`BW'_POST) if inrange(ty, 2014, 2024) & MOVE == 0, absorb($x0_s $x1_post $x2_post $x3_post) vce("cluster ksh4")
	
	

	eststo q_2a : reghdfe C_childrenNEW CSOK_`BW'_POST if inrange(ty, 2014, 2024) & MOVE == 1, absorb($x0_s $x1_post $x2_post $x3_post) vce("cluster ksh4")


	eststo q_2b : ivreghdfe C_childrenNEW (CSOK_0000_POST = CSOK_`BW'_POST)  if inrange(ty, 2014, 2024) & MOVE == 1, absorb($x0_s $x1_post $x2_post $x3_post) vce("cluster ksh4")

	eststo q_3a : reghdfe C_childrenNEW CSOK_`BW'_POST if inrange(ty, 2014, 2024) & MOVE == 2, absorb($x0_s $x1_post $x2_post $x3_post) vce("cluster ksh4")

	eststo q_3b : ivreghdfe C_childrenNEW (CSOK_0000_POST = CSOK_`BW'_POST) if inrange(ty, 2014, 2024) & MOVE == 2, absorb($x0_s $x1_post $x2_post $x3_post) vce("cluster ksh4")

	
	#d ;
	esttab q* 	using "${output}/tab_hetero_move_stock_BW`BW'.rtf",  replace nocons nomtitle
		keep(CSOK_`BW'_POST CSOK_0000_POST ) coeflabel( CSOK_`BW'_POST "Rural CSOK \(\times\) Post" CSOK_0000_POST "Rural CSOK eligibility \(\times\) Post" )	
		 nonote obslast  star(+ 0.1 * 0.05 ** 0.01) se 
		scalars("time Mother \& Year FE"
				"mother Mother controls"
				"muni Municipality controls"
				"region_FE Region FE"
				) 
		;
	#d cr

	
}




cap log close OC_pretrend_stock_MOVE
log using "${output}/OC_pretrend_stock_MOVE", text replace name(OC_pretrend_stock_MOVE)


foreach BW in /* "0000" */  15000 5000 {

	forval MOVE = 0(1)2 {
		
		reghdfe C_childrenNEW i.CSOK_`BW'##ib2019.ty if inrange(ty, 2014, 2024) & MOVE == `MOVE', absorb($x0_s $x1_ty $x2_ty $x3_ty $x4_ty) vce("cluster ksh4")

		gen TIME_`MOVE' = _n if inrange(_n, 2014, 2024)
		gen b_`MOVE' = .
		gen se_`MOVE' = .

		forval i = 2008(1)2024 {
			cap replace b_`MOVE' = _b[1.CSOK_`BW'#`i'.ty] if TIME_`MOVE' == `i'
			cap replace se_`MOVE' = _se[1.CSOK_`BW'#`i'.ty] if TIME_`MOVE' == `i'
		}
		gen hi_`MOVE' = b_`MOVE' + 1.96 * se_`MOVE'
		gen lo_`MOVE' = b_`MOVE' - 1.96 * se_`MOVE'


	}

	replace TIME_1 = TIME_0 + 0.1
	replace TIME_2 = TIME_0 + 0.2


	preserve

		drop if TIME_0 == .

		#d ;
			twoway 
				(connected b_0 TIME_0, lcolor("$color1") mcolor("$color1"))
				(connected b_1 TIME_1, lcolor("$color2") mcolor("$color2"))
				(connected b_2 TIME_2, lcolor("$color3") mcolor("$color3"))
				(rcap hi_0 lo_0 TIME_0, color("$color1")) 
				(rcap hi_1 lo_1 TIME_1, color("$color2")) 
				(rcap hi_2 lo_2 TIME_2, color("$color3")), 		
					graphregion(color(white))
					xtitle("Year")
					ytitle("Annual Birth Probability")
					legend(position(6) order(1 "Non-movers" 2 "Movers (across municipalities)" 3 "Movers (within municipality)"))
					xline(2019.5)
					yline(0)
					xlabel(2014(1)2024)
				;
		#d cr

	restore
		
	graph export "${output}/pretrend_move_stock_BW`BW'.pdf", as(pdf) replace
	drop b_* se_* hi_* lo_* TIME_*

}


cap log close OC_pretrend_stock_MOVE





/*------------------------------------------------------------------------------
	whole sample did
------------------------------------------------------------------------------*/

/*

use "${temp}/census_002_trim_updated", clear

keep if inrange(ty, 2014, 2024)
gen s_CSOK_tot = (subsidy_1 + subsidy_2) / women_15_49
gen s_CSOK_3 =  subsidy_3 / women_15_49

foreach X in s_CSOK_tot s_CSOK_3 {
	gen `X'_POST = `X' * POST
}

gen ln_de01_2018 = ln(de01)

eststo clear



eststo q_0 : reghdfe C_childrenNEW s_CSOK_tot_POST s_CSOK_3_POST if inrange(ty, 2014, 2024), absorb($x0_s) vce("cluster ksh4")
	estadd local time "Yes"

eststo q_1 : reghdfe C_childrenNEW s_CSOK_tot_POST s_CSOK_3_POST if inrange(ty, 2014, 2024), absorb($x0_s $x1_post ) vce("cluster ksh4")
	estadd local time "Yes"
	estadd local mother "Yes"


eststo q_2 : reghdfe C_childrenNEW s_CSOK_tot_POST s_CSOK_3_POST if inrange(ty, 2014, 2024), absorb($x0_s $x1_post $x2_post ) vce("cluster ksh4")
	estadd local time "Yes"
	estadd local mother "Yes"
	estadd local muni "Yes"


eststo q_3 : reghdfe C_childrenNEW s_CSOK_tot_POST s_CSOK_3_POST if inrange(ty, 2014, 2024), absorb($x0_s $x1_post $x2_post $x3_post) vce("cluster ksh4")
	estadd local time "Yes"
	estadd local mother "Yes"
	estadd local muni "Yes"
	estadd local region_FE "Yes"

eststo q_4 : reghdfe C_childrenNEW s_CSOK_tot_POST s_CSOK_3_POST if inrange(ty, 2014, 2024), absorb($x0_s $x1_post $x2_post $x4_post) vce("cluster ksh4")
	estadd local time "Yes"
	estadd local mother "Yes"
	estadd local muni "Yes"
	estadd local county_FE "Yes"

eststo q_5 : reghdfe C_childrenNEW s_CSOK_tot_POST s_CSOK_3_POST if inrange(ty, 2014, 2024), absorb($x0_s $x1_post $x2_post $x5_post) vce("cluster ksh4")
	estadd local time "Yes"
	estadd local mother "Yes"
	estadd local muni "Yes"
	estadd local subregion_FE "Yes"



esttab

#d ;
esttab q* 	using "${output}/tab_mainOLS_stock_fullsample.rtf",  replace nocons nomtitle
	keep(s_CSOK_tot_POST  s_CSOK_3_POST ) coeflabel(s_CSOK_tot_POST "CSOK \(\times\) Post" s_CSOK_3_POST "Rural CSOK \(\times\) Post")	
	 nonote obslast  star(+ 0.1 * 0.05 ** 0.01) se 
	scalars("time Mother \& Year FE"
			"mother Mother controls"
			"muni Municipality controls"
			"region_FE Region FE"
			"county_FE County FE"
			"subregion_FE Subregion FE"
			) 
	;
#d cr

*/



/*------------------------------------------------------------------------------
	whole sample did -- figure
------------------------------------------------------------------------------*/

/*

cap log close OC_pretrend_stock_fullsample
log using "${output}/OC_pretrend_stock_fullsample", text replace name(OC_pretrend_stock_fullsample)

local controls_0 "${x0_s}"
local controls_1 "`controls_0'  ${x1_ty}"
local controls_2 "`controls_1'  ${x2_ty}"
local controls_3 "`controls_2'  ${x3_ty}"
local controls_4 "`controls_3'  ${x4_ty}"
local controls_5 "`controls_4'  ${x5_ty}"
local controls_6 "`controls_4'  ${x6_ty}"
local controls_7 "`controls_4'  ${x7_ty}"



use "${temp}/census_002_trim_updated", clear

*keep if inrange(ty, 2018, 2020)
*sample 1


keep if inrange(ty, 2010, 2024)
gen s_CSOK_tot = (subsidy_1 + subsidy_2) / women_15_49_TSTAR
gen s_CSOK_3 =  subsidy_3 / women_15_49_TSTAR

gen ln_de01_2018 = ln(de01)

forval CONTROLS = 0(1)7 {

	reghdfe C_childrenNEW  c.s_CSOK_tot##ib2019.ty c.s_CSOK_3##ib2019.ty if inrange(ty, 2014, 2024), absorb(`controls_`CONTROLS'') vce("cluster ksh4")

	foreach X in tot 3 {
		
		gen TIME_`X' = _n if inrange(_n, 2010, 2024)
		gen b_`X' = .
		gen se_`X' = .

		forval i = 2008(1)2024 {
			cap replace b_`X' = _b[`i'.ty#c.s_CSOK_`X'] if TIME_`X' == `i'
			cap replace se_`X' = _se[`i'.ty#c.s_CSOK_`X'] if TIME_`X' == `i'
		}
		gen hi_`X' = b_`X' + 1.96 * se_`X'
		gen lo_`X' = b_`X' - 1.96 * se_`X'
	}
	
	replace TIME_3 = TIME_3 + 0.1
	
	#d ;
		twoway 
			(connected b_tot TIME_tot, lcolor("$color1") mcolor("$color1"))
			(connected b_3 TIME_3, lcolor("$color2") mcolor("$color2"))
			(rcap hi_tot lo_tot TIME_tot, color("$color1"))
			(rcap hi_3 lo_3 TIME_3, color("$color2")), 
				graphregion(color(white))
				xtitle("Year")
				ytitle("Total Children")
				legend(order(1 "CSOK" 2 "Rural CSOK"))
				xline(2015.5 2019.5)
				yline(0)
				xlabel(2010(2)2024)
			;
	#d cr
	graph export "${output}/pretrend_main_stock_fullsample_controls`CONTROLS'.pdf", as(pdf) replace
	drop b_3 se_3 hi_3 lo_3 TIME_3 b_tot se_tot hi_tot lo_tot TIME_tot
	
}

cap log close OC_pretrend_stock_fullsample


*/







