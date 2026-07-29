

/*------------------------------------------------------------------------------
	MAIN TABLE -- flow
------------------------------------------------------------------------------*/



use "${temp}/census_002_trim_updated", clear

*keep if inrange(ty, 2019, 2020)
*sample 1

keep if inrange(ty, 2014, 2024)
keep if CSOK_15000 != .

foreach BW in "0000" 5000 15000 {
	gen CSOK_`BW'_POST = CSOK_`BW' * POST
}

gen s_CSOK = subsidy_3 / de01
gen s_CSOK_POST = s_CSOK * POST


foreach BW in  "0000" 5000 15000  {
	eststo clear

	eststo q_0 : reghdfe N_childrenNEW CSOK_`BW'_POST if inrange(ty, 2014, 2024), absorb($x0_f) vce("cluster ksh4")
		estadd local time "Yes"

	eststo q_1 : reghdfe N_childrenNEW CSOK_`BW'_POST if inrange(ty, 2014, 2024), absorb($x0_f $x1_post ) vce("cluster ksh4")
		estadd local time "Yes"
		estadd local mother "Yes"


	eststo q_2 : reghdfe N_childrenNEW CSOK_`BW'_POST if inrange(ty, 2014, 2024), absorb($x0_f $x1_post $x2_post ) vce("cluster ksh4")
		estadd local time "Yes"
		estadd local mother "Yes"
		estadd local muni "Yes"


	eststo q_3 : reghdfe N_childrenNEW CSOK_`BW'_POST if inrange(ty, 2014, 2024), absorb($x0_f $x1_post $x2_post $x3_post) vce("cluster ksh4")
		estadd local time "Yes"
		estadd local mother "Yes"
		estadd local muni "Yes"
		estadd local region_FE "Yes"

	eststo q_4 : reghdfe N_childrenNEW CSOK_`BW'_POST if inrange(ty, 2014, 2024), absorb($x0_f $x1_post $x2_post $x4_post) vce("cluster ksh4")
		estadd local time "Yes"
		estadd local mother "Yes"
		estadd local muni "Yes"
		estadd local county_FE "Yes"

	eststo q_5 : reghdfe N_childrenNEW CSOK_`BW'_POST if inrange(ty, 2014, 2024), absorb($x0_f $x1_post $x2_post $x5_post) vce("cluster ksh4")
		estadd local time "Yes"
		estadd local mother "Yes"
		estadd local muni "Yes"
		estadd local subregion_FE "Yes"



	esttab

	#d ;
	esttab q* 	using "${output}/tab_mainOLS_flow_BW`BW'.rtf",  replace nocons nomtitle
		keep(CSOK_`BW'_POST  ) coeflabel( CSOK_`BW'_POST "Rural CSOK \(\times\) Post")	
		 nonote obslast  star(+ 0.1 * 0.05 ** 0.01) se 
		scalars("time Municipality \& Year FE"
				"mother Mother controls"
				"muni Municipality controls"
				"region_FE Region FE"
				"county_FE County FE"
				"subregion_FE Subregion FE"
				) 
		;
	#d cr
}



foreach BW in  5000 15000  {
	eststo clear

	eststo q_1 : reghdfe N_childrenNEW CSOK_0000_POST if CSOK_`BW' != . & inrange(ty, 2014, 2024), absorb($x0_f ) vce("cluster ksh4")
		estadd local time "Yes"

	eststo q_2 : reghdfe N_childrenNEW  CSOK_0000_POST if CSOK_`BW' != . &  inrange(ty, 2014, 2024), absorb($x0_f $x1_post  ) vce("cluster ksh4")
		estadd local time "Yes"
		estadd local mother "Yes"

	eststo q_3 : reghdfe N_childrenNEW CSOK_0000_POST if CSOK_`BW' != . &  inrange(ty, 2014, 2024), absorb($x0_f $x1_post $x2_post $x3_post ) vce("cluster ksh4")
		estadd local time "Yes"
		estadd local mother "Yes"
		estadd local muni "Yes"
		estadd local county_FE "Yes"
		
	qui : reghdfe CSOK_0000_POST  CSOK_`BW'_POST if inrange(ty, 2014, 2024), absorb($x0_f $x1_post $x2_post $x3_post) vce("cluster ksh4")
		local F_stat = (_b[CSOK_`BW'_POST] / _se[CSOK_`BW'_POST])^2
	
	eststo q_IV_1 : ivreghdfe N_childrenNEW (CSOK_0000_POST = CSOK_`BW'_POST) if inrange(ty, 2014, 2024), absorb($x0_f $x1_post $x2_post $x3_post) vce("cluster ksh4")
		estadd local time "Yes"
		estadd local mother "Yes"
		estadd local muni "Yes"
		estadd local region_FE "Yes"
		estadd scalar Fstat = `F_stat'

		
	qui : reghdfe s_CSOK_POST  CSOK_`BW'_POST if inrange(ty, 2014, 2024), absorb($x0_f $x1_post $x2_post $x3_post) vce("cluster ksh4")
		local F_stat = (_b[CSOK_`BW'_POST] / _se[CSOK_`BW'_POST])^2
	
	eststo q_IV_2 : ivreghdfe N_childrenNEW (s_CSOK_POST = CSOK_`BW'_POST) if inrange(ty, 2014, 2024), absorb($x0_f $x1_post $x2_post $x3_post) vce("cluster ksh4")
		estadd local time "Yes"
		estadd local mother "Yes"
		estadd local muni "Yes"
		estadd local region_FE "Yes"
		estadd scalar Fstat = `F_stat'


	esttab

	#d ;
	esttab q* 	using "${output}/tab_main_flow_BW`BW'.rtf",  replace nocons nomtitle
		keep(CSOK_0000_POST s_CSOK_POST ) coeflabel( CSOK_0000_POST "Rural CSOK \(\times\) Post" s_CSOK_POST "Subsidy")	
		 nonote obslast  star(+ 0.1 * 0.05 ** 0.01) se 
		scalars("time Municipality \& Year FE"
				"mother Mother controls"
				"muni Municipality controls"
				"region_FE Region FE"
				"Fstat F statistics"
				) 
		;
	#d cr
}




/*------------------------------------------------------------------------------
	PRE-TREND flow
------------------------------------------------------------------------------*/

/*
cap log close OC_pretrend_flow
log using "${output}/OC_pretrend_flow", text replace name(OC_pretrend_flow)


local controls_0 "${x0_f}"
local controls_1 "`controls_0'  ${x1_ty}"
local controls_2 "`controls_1'  ${x2_ty}"
local controls_3 "`controls_2'  ${x3_ty}"
local controls_4 "`controls_2'  ${x4_ty}"
local controls_5 "`controls_2'  ${x5_ty}"


use "${temp}/census_002_trim_updated", clear

*keep if inrange(ty, 2018, 2021)
*sample 3

keep if inrange(ty, 2014, 2024)
keep if CSOK_15000 != .


foreach BW in "0000" 5000 15000 { 
	forval CONTROLS = 0(1)5 {

		reghdfe N_childrenNEW i.CSOK_`BW'##ib2019.ty if inrange(ty, 2014, 2024), absorb(`controls_`CONTROLS'') vce("cluster ksh4")

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
		graph export "${output}/pretrend_main_flow_BW`BW'_controls`CONTROLS'.pdf", as(pdf) replace
		drop b se hi lo TIME
		
	}
}

cap log close OC_pretrend_flow
*/





