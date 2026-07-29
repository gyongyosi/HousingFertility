/**
cls
capture log close
do "${code}/401_census.do"
do "${code}/805_matching_census_LB.do"
do "${code}/900_firstRegs.do"
* do "${code}/900_firstRegs_hetero.do"
* do "${code}/900_firstRegs.do"
**/


/*==============================================================================
	RURAL CSOK -- DiD
==============================================================================*/


/*------------------------------------------------------------------------------
	balance table
------------------------------------------------------------------------------*/

use "${temp}/census_002_trim_updated", clear

keep if ty == 2018
keep if inrange(mother_age, 15, 49)


local VARS "mother_age edu_1 edu_2 edu_3 edu_4"


foreach BW in 0000 /* 2000 3000 4000 */ 5000  {

	
	eststo clear
	eststo TREATED : estpost summarize  `VARS' if CSOK_`BW' == 1 & ty == 2018, d
	eststo CONTROL : estpost summarize  `VARS' if CSOK_`BW' == 0 & ty == 2018, d
	eststo diff : estpost ttest `VARS' if ty == 2018, by(CSOK_`BW') unequal
	
	#d ;
	esttab * using "${output}/balance_RCSOK_`BW'.rtf", 
		replace
		label
		cells("	mean(pattern(1 1 0) fmt(2)) b(star pattern(0 0  1) fmt(2))" 
			"sd(pattern(1 1  0) fmt(2)) t(pattern(0 0  1) fmt(2))" )
		star(+ 0.1 * 0.05 ** 0.01)
		mtitle("Eligible" "Non-eligible" "Difference}" )
		booktabs nonumbers
		
		;
	#d cr

	
}


/*------------------------------------------------------------------------------
	balance figure
------------------------------------------------------------------------------*/


use "${temp}/census_002_trim_updated", clear

keep if inrange(mother_age, 15, 49)
keep if ty == 2018


foreach BW in 0000 /*2000 3000 4000 */ 5000 {

	#d ;
		twoway 
			(hist mother_age if CSOK_`BW' == 1 , 
				color("$color1") discrete)
			(hist mother_age if CSOK_`BW' == 0 , 
				fcolor(none) lcolor(black) discrete),
			
				xtitle("")
				legend(order(1 "Treated" 2 "Control"))
				graphregion(color(white))
			;
		
	#d cr
	graph export  "${output}/hist_mother_age_by_CSOK`BW'.pdf", as(pdf) replace
	
	
	#d ;
		twoway 
			(hist eduCatg if CSOK_`BW' == 1 , 
				color("$color1") discrete)
			(hist eduCatg if CSOK_`BW' == 0 , 
				fcolor(none) lcolor(black) discrete),
			
				xtitle("")
				legend(order(1 "Treated" 2 "Control"))
				graphregion(color(white))
			;
		
	#d cr
	graph export  "${output}/hist_edu_by_CSOK`BW'.pdf", as(pdf) replace
}



/*------------------------------------------------------------------------------
	diff-in-diff regressions
------------------------------------------------------------------------------*/


/*
* !!!! this works !!!!
reghdfe N_children i.CSOK_0##ib2019.ty if inrange(ty, 2014, .) & CSOK_5 != . , absorb(ksh4 ty i.ty_mother##i.ty i.relC##i.ty i.marriedBy2019##i.ty i.eduC##i.ty i.rkod##i.ty) vce(robust)

reghdfe N_children i.CSOK_0##ib2019.ty if inrange(ty, 2014, .) & CSOK_5 != ., absorb(szemazon ty i.ty_mother##i.ty i.relC##i.ty i.marriedBy2019##i.ty i.eduC##i.ty i.rkod##i.ty) vce(robust)
* !!!!
*/

use "${temp}/census_002_trim_updated", clear

keep if inrange(mother_age, 15, 49)


foreach BW in  5000  /* 0000 2000 3000 4000  */ {
	
	eststo clear
	
	local seType "cluster ksh4_bpker"
	eststo q_1 : reghdfe N_children i.CSOK_`BW'##i.POST if inrange(ty, 2014, .) , absorb(ksh4_bpker ty ) vce(`seType')
		*estadd local FE "Yes"

	eststo q_2 : reghdfe N_children i.CSOK_`BW'##i.POST if inrange(ty, 2014, .) , absorb(ksh4_bpker ty  $x1_post) vce(`seType')
		*estadd local FE "Yes"
		*estadd local controls "Yes"

		
	eststo q_3 : reghdfe N_children i.CSOK_`BW'##i.POST if inrange(ty, 2014, .) , absorb(ksh4_bpker ty  $x1_post $x2_post) vce(`seType')
		*estadd local FE "Yes"
		*estadd local controls "Yes"
		*estadd local settlement "Yes"	
		
	eststo q_4 : reghdfe N_children i.CSOK_`BW'##i.POST if inrange(ty, 2014, .) , absorb(ksh4_bpker ty  $x1_post $x2_post $x3_post) vce(`seType')
		*estadd local FE "Yes"
		*estadd local controls "Yes"
		*estadd local settlement "Yes"	
		*estadd local region "Yes"
			
	eststo q_5 : reghdfe N_children i.CSOK_`BW'##i.POST if inrange(ty, 2014, .) , absorb(ksh4_bpker ty  $x1_post $x2_post $x4_post) vce(`seType')
		*estadd local FE "Yes"
		*estadd local controls "Yes"
		*estadd local settlement "Yes"	
		*estadd local county "Yes"
	
			
	eststo q_6 : reghdfe N_children i.CSOK_`BW'##i.POST if inrange(ty, 2014, .) , absorb(ksh4_bpker ty  $x1_post $x2_post $x5_post) vce(`seType')
		*estadd local FE "Yes"
		*estadd local controls "Yes"
		*estadd local settlement "Yes"	
		*estadd local subregion "Yes"
	
	esttab using "${output}/tab_rural_BW`BW'_cumul.rtf", keep(1.CSOK_`BW'#1.POST_2019) replace

	
}



/*------------------------------------------------------------------------------
	diff-in-diff figure - updated version
------------------------------------------------------------------------------*/

use "${temp}/census_002", clear

keep if inrange(mother_age, 15, 49)

use "${temp}/census_002_trim_updated", clear


foreach BW in 5000  /* 0000 2000 3000 4000 5000 */ {

	*** estimating with flow
	reghdfe N_childrenNEW i.CSOK_`BW'##ib2019.ty if inrange(ty, 2014, 2024), absorb(i.ty_mother_birth##i.ty i.marriedBy2019##i.ty i.kids_by_2018##i.ty i.lcstip##i.ty i.eduCatg##i.ty i.hungarian##i.ty i.relC##i.ty i.szemazon) vce(robust)

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
				ytitle("Estimated coefficient")
				legend(off)
				xline(2019.5)	
			;
	#d cr
	graph export "${output}/pretrend_CSOK_5000_6", as(pdf) replace
	drop b se hi lo TIME

	*** estimating with stock
	reghdfe C_childrenNEW i.CSOK_`BW'##ib2019.ty if inrange(ty, 2014, 2024), absorb(i.ty_mother_birth##i.ty i.marriedBy2019##i.ty i.kids_by_2018##i.ty i.lcstip##i.ty i.eduCatg##i.ty i.hungarian##i.ty i.relC##i.ty i.szemazon) vce(robust)

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
				ytitle("Estimated coefficient")
				legend(off)
				xline(2019.5)
			;
	#d cr
	graph export "${output}/pretrend_CSOK_5000_6_cumul.pdf", as(pdf) replace
	drop b se hi lo TIME
}


/*------------------------------------------------------------------------------
	diff-in-diff figure
------------------------------------------------------------------------------*/

use "${temp}/census_002", clear

keep if inrange(mother_age, 15, 49)

use "${temp}/census_002_trim_updated", clear


foreach BW in 5000  /* 0000 2000 3000 4000 5000 */ {

	*** estimating with settlement FE
	reghdfe N_childrenNEW i.CSOK_`BW'##ib2019.ty if inrange(ty, 2014, 2024), absorb(ksh4 ty $x1_ty  $x2_ty  $x3_ty  i.relC##i.ty ) vce(robust)

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
				xtitle("")
				ytitle("Estimated coefficient")
				legend(off)
				xline(2019.5)	
			;
	#d cr
	graph export "${output}/pretrend_CSOK`BW'_spec1_withLB.pdf", as(pdf) replace
	drop b se hi lo TIME

	*** estimating with mother FE
	reghdfe N_childrenNEW i.CSOK_`BW'##ib2019.ty if inrange(ty, 2014, 2024), absorb(szemazon ty $x1_ty  $x2_ty  $x3_ty  ) vce(robust)

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
				xtitle("")
				ytitle("Estimated coefficient")
				legend(off)
				xline(2019.5)
			;
	#d cr
	graph export "${output}/pretrend_CSOK`BW'_spec2_withLB.pdf", as(pdf) replace
	drop b se hi lo TIME
}





/*------------------------------------------------------------------------------
	heterogeneity
	
	TODO: by cohort5
	
------------------------------------------------------------------------------*/


use "${temp}/census_002", clear

keep if inrange(mother_age, 15, 49)


foreach BW in 5000  /* 0000 2000 3000 4000 5000 */ {

	eststo clear
	eststo q_1 : reghdfe N_children i.CSOK_`BW'##i.POST if inrange(ty, 2014, .) & high_edu == 0, absorb(ksh4 ty  $x1_post) vce(robust)
		estadd local FE "Yes"
		estadd local controls "Yes"

	eststo q_2 : reghdfe N_children i.CSOK_`BW'##i.POST if inrange(ty, 2014, .) & high_edu == 1, absorb(ksh4 ty  $x1_post) vce(robust)
		estadd local FE "Yes"
		estadd local controls "Yes"

		
	eststo q_3 : reghdfe N_children i.CSOK_`BW'##i.POST if inrange(ty, 2014, .) & young == 0, absorb(ksh4 ty  $x1_post) vce(robust)
		estadd local FE "Yes"
		estadd local controls "Yes"

	eststo q_4 : reghdfe N_children i.CSOK_`BW'##i.POST if inrange(ty, 2014, .) & young == 1, absorb(ksh4 ty  $x1_post) vce(robust)
		estadd local FE "Yes"
		estadd local controls "Yes"

	eststo q_5 : reghdfe N_children i.CSOK_`BW'##i.POST if inrange(ty, 2014, .) & kids_by_2018 == 0, absorb(ksh4 ty  $x1_post) vce(robust)
		estadd local FE "Yes"
		estadd local controls "Yes"

	eststo q_6 : reghdfe N_children i.CSOK_`BW'##i.POST if inrange(ty, 2014, .) & kids_by_2018 > 0, absorb(ksh4 ty  $x1_post) vce(robust)
		estadd local FE "Yes"
		estadd local controls "Yes"


		esttab using "${output}/tab_hetero_rural_BW`BW'.rtf", keep(1.CSOK_`BW'#1.POST_2019) replace
	

}

/*==============================================================================
	RURAL CSOK -- RDD
==============================================================================*/



/*------------------------------------------------------------------------------
	prepare data (create a cross section of women)
------------------------------------------------------------------------------*/

use "${temp}/census_002_trim_updated", clear



foreach X in 2016 2017 2018 2019 2020 2021 2022 {
	gen tmp_C_children_`X' = C_children if ty == `X'
	egen C_children_`X' = mean(tmp_C_children_`X' ), by(szemazon)
	drop tmp_C_children_`X'
}


keep if inrange(mother_age, 15, 49)


gen d_C_children = C_children_2022 - C_children_2019
gen d_C_children_placebo = C_children_2019 - C_children_2016

save "${temp}/rdd_RCSOK_census_01", replace



/*------------------------------------------------------------------------------
	RDD -- balance 
------------------------------------------------------------------------------*/

use "${temp}/rdd_RCSOK_census_01", clear



#d ;
	binscatter edu_1 de01 if CSOK_5 != . & ty == 2018, rd(5000) 
		nq(100)
		xtitle("Population")
		ytitle("Share of women with primary school education" "(age 15-49)")
		;
	
#d cr


#d ;
	binscatter edu_2 de01 if  CSOK_5 != . & ty == 2018, rd(5000) 
		nq(100)
		xtitle("Population")
		ytitle("Share of women with vocation school education" "(age 15-49)")
		;
	
#d cr

#d ;
	binscatter edu_3 de01 if  CSOK_5 != . & ty == 2018, rd(5000) 
		nq(100)
		xtitle("Population")
		ytitle("Share of women with high school education" "(age 15-49)")
		;
	
#d cr

#d ;
	binscatter edu_4 de01 if   CSOK_5 != . & ty == 2018, rd(5000) 
		nq(100)
		xtitle("Population")
		ytitle("Share of women with college education" "(age 15-49)")
		;
	
#d cr



#d ;
	binscatter irelo de01 if   CSOK_5 != . & ty == 2018, rd(5000) 
		nq(100)
		xtitle("Population")
		ytitle("Average years of educations" "(age 15-49)")
		;
	
#d cr


#d ;
	binscatter agglo de01 if CSOK_5 != . & ty == 2018, rd(5000) 
		nq(100)
		xtitle("Population")
		ytitle("Share of women living in agglomeration" "(age 15-49)")
		;
	
#d cr


** not in agglomeration
#d ;
	binscatter edu_1 de01 if CSOK_5 != . & ty == 2018 & agglo != 1, rd(5000) 
		nq(100)
		xtitle("Population")
		ytitle("Share of women with primary school education" "(age 15-49)")
		;
	
#d cr




/*------------------------------------------------------------------------------
	RDD -- fertility -- pre-policy 
		all women
		by 5-year cohorts
------------------------------------------------------------------------------*/

use "${temp}/rdd_RCSOK_census_01", clear

#d ;
	binscatter C_children_2019 de01 if CSOK_5 != . & ty == 2019,  rd(5000) 
		nq(100)
		xtitle("Population")
		ytitle("Average number of children by 2019" "(age 15-49)")
		;
	
#d cr
graph export "${output}/RDD_children_by2019_allwomen.pdf", as(pdf) replace


#d ;
	binscatter d_C_children_place de01 if CSOK_5 != . & ty == 2016,  rd(5000) 
		nq(100)
		xtitle("Population")
		ytitle("Change in average number of children between 2016-2019" "(age 15-49)")
		;
	
#d cr
graph export "${output}/RDD_children_change_placebo_allwomen.pdf", as(pdf) replace




forval i = 1965(5)1995 {

	local j = `i' + 4

	#d ;
		binscatter C_children_2019 de01 if cohort == `i' & ty == 2019, rd(5000)
			nq(100)
			xtitle("Population")
			ytitle("Average number of children by 2019" "(women born `i'-`j')")
			;
		
	#d cr	
	graph export "${output}/RDD_children_by2019_cohort`i'.pdf", as(pdf) replace
}



forval i = 1965(5)1995 {

	local j = `i' + 4

	#d ;
		binscatter d_C_children_place de01 if cohort == `i' & ty == 2016, rd(5000)
			nq(100)
			xtitle("Population")
			ytitle("Change in average number of children between 2016-2019" "(women born `i'-`j')")
			;
		
	#d cr	
	graph export "${output}/RDD_children_change_cohort`i'.pdf", as(pdf) replace
}




































gen csok_post = village_csok * POST

foreach i in 2015 2018 2019 2021 2022 {
	gen tmp_C_children_`i' = C_children if ty == `i'
	egen C_children_`i' = mean(tmp_C_children_`i'), by(szemazon)
	drop tmp_C_children_`i'
}

gen d_C_children = C_children_2022 - C_children_2019
gen d_C_children_place = C_children_2019 - C_children_2015
gen d_C_children_place2 = C_children_2019 - C_children_2018



reghdfe d_C_children i.CSOK_2##i.POST if ty == 2022, 
reghdfe d_C_children i.CSOK_2##i.POST if ty == 2022, absorb(eduCatg ty_mother_birth marriedBy2019)


reghdfe d_C_children village_csok if ty == 2022 & CSOK_2 != ., 
reghdfe d_C_children village_csok if ty == 2022 & CSOK_2 != ., absorb(eduCatg ty_mother_birth marriedBy2019)

ivreghdfe d_C_children (village_csok = CSOK_2) if ty == 2022 & CSOK_2 != ., 
ivreghdfe d_C_children (village_csok = CSOK_2) if ty == 2022 & CSOK_2 != ., cluster(ksh4)
ivreghdfe d_C_children (village_csok = CSOK_2) if ty == 2022 & CSOK_2 != ., cluster(ksh4) absorb(eduCatg ty_mother_birth marriedBy2019)


reghdfe d_C_children_place i.CSOK_2##i.POST if ty == 2022,  
reghdfe d_C_children_place i.CSOK_2##i.POST if ty == 2022,  absorb(eduCatg ty_mother_birth)



reghdfe d_C_children_place village_csok if ty == 2022 & CSOK_2 != ., 
reghdfe d_C_children_place village_csok if ty == 2022 & CSOK_2 != ., absorb(eduCatg ty_mother_birth marriedBy2019)


reghdfe d_C_children_place2 village_csok if ty == 2022 & CSOK_2 != ., 
reghdfe d_C_children_place2 village_csok if ty == 2022 & CSOK_2 != ., absorb(eduCatg ty_mother_birth marriedBy2019)


ivreghdfe d_C_children_place (village_csok = CSOK_2) if ty == 2022 & CSOK_2 != ., cluster(ksh4) absorb(eduCatg ty_mother_birth marriedBy2019)







* table
eststo clear
eststo q_1 : reghdfe N_children i.CSOK_2##i.POST if inrange(ty, 2014, .) , absorb(ksh4 ty ) vce(robust)
	estadd local FE "Yes"

eststo q_2 : reghdfe N_children i.CSOK_3##i.POST if inrange(ty, 2014, .) , absorb(ksh4 ty ) vce(robust)
	estadd local FE "Yes"

eststo q_3 : reghdfe N_children i.CSOK_4##i.POST if inrange(ty, 2014, .) , absorb(ksh4 ty ) vce(robust)
	estadd local FE "Yes"

eststo q_4 : reghdfe N_children i.CSOK_5##i.POST if inrange(ty, 2014, .) , absorb(ksh4 ty ) vce(robust)
	estadd local FE "Yes"

esttab, keep(1.CSOK*#1.POST)




* table -- reduced form
eststo clear
eststo q_1 : reghdfe N_children i.CSOK_4##i.POST if inrange(ty, 2014, .) , absorb(ksh4 ty ) vce(robust)
	estadd local FE "Yes"

eststo q_2 : reghdfe N_children i.CSOK_4##i.POST if inrange(ty, 2014, .) , absorb(ksh4 ty  $x1_post) vce(robust)
	estadd local FE "Yes"
	estadd local controls "Yes"

	
eststo q_3 : reghdfe N_children i.CSOK_4##i.POST if inrange(ty, 2014, .) , absorb(ksh4 ty  $x1_post $x2_post) vce(robust)
	estadd local FE "Yes"
	estadd local controls "Yes"
	estadd local settlement "Yes"	
	
eststo q_4 : reghdfe N_children i.CSOK_4##i.POST if inrange(ty, 2014, .) , absorb(ksh4 ty  $x1_post $x2_post $x3_post) vce(robust)
	estadd local FE "Yes"
	estadd local controls "Yes"
	estadd local settlement "Yes"	
	estadd local subregion "Yes"
		
eststo q_5 : reghdfe N_children i.CSOK_4##i.POST if inrange(ty, 2014, .) , absorb(ksh4 ty  $x1_post $x2_post $x4_post) vce(robust)
	estadd local FE "Yes"
	estadd local controls "Yes"
	estadd local settlement "Yes"	
	estadd local subregion "Yes"
	

esttab, keep(1.CSOK*#1.POST)

	
* table -- IV
eststo clear
eststo q_1 : ivreghdfe N_children (csok_post = i.CSOK_4##i.POST) if inrange(ty, 2014, .) , absorb(ksh4 ty ) vce(robust)
	estadd local FE "Yes"

eststo q_2 : ivreghdfe N_children (csok_post = i.CSOK_4##i.POST) if inrange(ty, 2014, .) , absorb(ksh4 ty  $x1_post) vce(robust)
	estadd local FE "Yes"
	estadd local controls "Yes"

	
eststo q_3 : ivreghdfe N_children (csok_post = i.CSOK_4##i.POST) if inrange(ty, 2014, .) , absorb(ksh4 ty  $x1_post $x2_post) vce(robust)
	estadd local FE "Yes"
	estadd local controls "Yes"
	estadd local settlement "Yes"	
	
eststo q_4 :  ivreghdfe N_children (csok_post = i.CSOK_4##i.POST) if inrange(ty, 2014, .) , absorb(ksh4 ty  $x1_post $x2_post $x3_post) vce(robust)
	estadd local FE "Yes"
	estadd local controls "Yes"
	estadd local settlement "Yes"	
	estadd local subregion "Yes"
		
eststo q_5 :  ivreghdfe N_children (csok_post = i.CSOK_4##i.POST) if inrange(ty, 2014, .) , absorb(ksh4 ty  $x1_post $x2_post $x4_post) vce(robust)
	estadd local FE "Yes"
	estadd local controls "Yes"
	estadd local settlement "Yes"	
	estadd local subregion "Yes"
	

esttab, keep(1.CSOK*#1.POST)

	
* table heterogeneity 1 -- reduced form

eststo clear
eststo q_1 : reghdfe N_children i.CSOK_4##i.POST if inrange(ty, 2014, .) & high_edu == 0, absorb(ksh4 ty  $x1_post) vce(robust)
	estadd local FE "Yes"
	estadd local controls "Yes"

eststo q_2 : reghdfe N_children i.CSOK_4##i.POST if inrange(ty, 2014, .) & high_edu == 1, absorb(ksh4 ty  $x1_post) vce(robust)
	estadd local FE "Yes"
	estadd local controls "Yes"

	
eststo q_3 : reghdfe N_children i.CSOK_4##i.POST if inrange(ty, 2014, .) & young == 0, absorb(ksh4 ty  $x1_post) vce(robust)
	estadd local FE "Yes"
	estadd local controls "Yes"

eststo q_4 : reghdfe N_children i.CSOK_4##i.POST if inrange(ty, 2014, .) & young == 1, absorb(ksh4 ty  $x1_post) vce(robust)
	estadd local FE "Yes"
	estadd local controls "Yes"

esttab, keep(1.CSOK*#1.POST)

	
	
	
* table heterogeneity 1 -- IV

eststo clear
eststo q_1 :ivreghdfe N_children (csok_post = i.CSOK_4##i.POST) if inrange(ty, 2014, .) & high_edu == 0, absorb(ksh4 ty  $x1_post) vce(robust)
	estadd local FE "Yes"
	estadd local controls "Yes"

eststo q_2 : ivreghdfe N_children (csok_post = i.CSOK_4##i.POST) if inrange(ty, 2014, .) & high_edu == 1, absorb(ksh4 ty  $x1_post) vce(robust)
	estadd local FE "Yes"
	estadd local controls "Yes"

	
eststo q_3 : ivreghdfe N_children (csok_post = i.CSOK_4##i.POST) if inrange(ty, 2014, .) & young == 0, absorb(ksh4 ty  $x1_post) vce(robust)
	estadd local FE "Yes"
	estadd local controls "Yes"

eststo q_4 : ivreghdfe N_children (csok_post = i.CSOK_4##i.POST) if inrange(ty, 2014, .) & young == 1, absorb(ksh4 ty  $x1_post) vce(robust)
	estadd local FE "Yes"
	estadd local controls "Yes"

esttab, keep(csok_post)

	
	
	
* table heterogeneity 2 -- by regions

eststo clear
forval i = 1(1)7 {
	eststo q_`i' : reghdfe N_children i.CSOK_2##i.POST if inrange(ty, 2014, .) & rkod2018 == `i', absorb(ksh4 ty  $x1_post) vce(robust)
}
esttab, keep(1.CSOK*#1.POST)

	
	

* figure


























/*------------------------------------------------------------------------------
	RDD figures
------------------------------------------------------------------------------*/

use "${temp}/census_002_trim_updated", clear




*rdbwselect d_C_children de01 if ty == 2022, c(5000)
*global H = `e(h_mserd)'
*global B = `e(b_mserd)'
global H = 2500
global B = 5000


keep if CSOK_5000 != .
*keep if ty == 2019





#d ;
	binscatter C_children_2019 de01 if ty == 2019, rd(5000) 
		nq(50)
		xtitle("Population")
		ytitle("Average number of children by 2019" "(women born 1965-2001)")
		;
	
#d cr
graph export "${output}/RDD_children_by2019_allwomen.pdf", as(pdf) replace


#d ;
	binscatter C_children_2018 de01 if ty == 2018,  rd(5000) 
		nq(50)
		xtitle("Population")
		ytitle("Average number of children by 2018" "(women born 1965-2001)")
		;
	
#d cr
graph export "${output}/RDD_children_by2018_allwomen.pdf", as(pdf) replace


#d ;
	binscatter d_C_children de01 if ty == 2019,  rd(5000) 
		nq(50)
		xtitle("Population")
		ytitle("Change in average number of children between 2019-2022" "(women born 1965-2001)")
		;
	
#d cr
graph export "${output}/RDD_children_change_allwomen.pdf", as(pdf) replace

#d ;
	binscatter d_C_children_place de01 if ty == 2016,  rd(5000) 
		nq(50)
		xtitle("Population")
		ytitle("Change in average number of children between 2019-2022" "(women born 1965-2001)")
		;
	
#d cr
graph export "${output}/RDD_children_change_placebo_allwomen.pdf", as(pdf) replace


















forval i = 1965(5)1995 {

	local j = `i' + 4

	#d ;
		binscatter C_children_2018 de01 if cohort == `i' & ty == 2022, rd(5000)
			nq(50)
			xtitle("Population")
			ytitle("Average number of children by 2018" "(women born `i'-`j')")
			;
		
	#d cr	
	graph export "${output}/RDD_children_by2018_cohort`i'.pdf", as(pdf) replace
}


forval i = 1965(5)1995 {

	local j = `i' + 4

	#d ;
		binscatter C_children_2019 de01 if cohort == `i' & ty == 2022, rd(5000)
			nq(50)
			xtitle("Population")
			ytitle("Average number of children by 2019" "(women born `i'-`j')")
			;
		
	#d cr	
	graph export "${output}/RDD_children_by2019_cohort`i'.pdf", as(pdf) replace
}


forval i = 1965(5)1995 {

	local j = `i' + 4

	#d ;
		binscatter C_children_2022 de01 if cohort == `i' & ty == 2022, rd(5000)
			nq(50)
			xtitle("Population")
			ytitle("Average number of children by 2022" "(women born `i'-`j')")
			;
		
	#d cr	
	graph export "${output}/RDD_children_by2022_cohort`i'.pdf", as(pdf) replace
}


forval i = 1965(5)1995 {

	local j = `i' + 4

	#d ;
		binscatter d_C_children de01 if cohort == `i' & ty == 2022, rd(5000)
			nq(50)
			xtitle("Population")
			ytitle("Change in average number of children between 2019 and 2022" "(women born `i'-`j')")
			;
		
	#d cr	
	graph export "${output}/RDD_d_children_cohort`i'.pdf", as(pdf) replace
}




** tables 

* table 1 - average effect on change of number of kids
eststo clear
eststo q_1 : rdrobust d_C_children de01 if ty == 2019, all c(5000) h(2500) b(5000)
eststo q_2 : rdrobust d_C_children de01 if ty == 2019 , all c(5000) h(2500) b(5000) covs(ty_mother_birth eduCatg hungarian)
eststo q_3 : rdrobust d_C_children de01 if ty == 2019 , all c(5000) h(1250) b(2500)  
eststo q_4 : rdrobust d_C_children de01 if ty == 2019 , all c(5000) h(2500) b(5000) fuzzy(CSOK_0000)

esttab, keep(Robust)


* table  - average effect on number of kids in 2019
eststo clear
eststo q_1 : rdrobust C_children_2019 de01 if ty == 2019 , all c(5000) h(2500) b(5000)
eststo q_2 : rdrobust C_children_2019 de01 if ty == 2019 , all c(5000) h(2500) b(5000) covs(ty_mother_birth eduCatg hungarian)
eststo q_3 : rdrobust C_children_2019 de01 if ty == 2019 , all c(5000) h(1250) b(2500)  
eststo q_4 : rdrobust C_children_2019 de01 if ty == 2019 , all c(5000) h(2500) b(5000) fuzzy(CSOK_0000)

esttab, keep(Robust)

* table  - average effect on number of kids in 2022
eststo clear
eststo q_1 : rdrobust C_children_2022 de01 if ty == 2019 , all c(5000) h(2500) b(5000)
eststo q_2 : rdrobust C_children_2022 de01 if ty == 2019 , all c(5000) h(2500) b(5000) covs(ty_mother_birth irelo)
eststo q_3 : rdrobust C_children_2022 de01 if ty == 2019 , all c(5000) h(1250) b(2500) 
eststo q_4 : rdrobust C_children_2022 de01 if ty == 2019 , all c(5000) h(2500) b(5000) fuzzy(CSOK_0000)

esttab, keep(Robust)


* table 2 : by cohort -- average effect on change of number of kids
eststo clear
forval i = 1965(5)1995 {
	eststo q_`i' : rdrobust d_C_children de01 if ty == 2022 & cohort == `i' , all c(5000) h(2500) b(5000)
}
esttab, keep(Robust)


eststo clear
forval i = 1965(5)1995 {
	eststo q_`i' : rdrobust C_children_2019 de01 if ty == 2022 & cohort == `i' ,  c(5000) h(2000) b(4000) all
}
esttab, keep(Robust)


eststo clear
forval i = 1965(5)1995 {
	eststo q_`i' : rdrobust C_children_2022 de01 if ty == 2022 & cohort == `i' , all c(5000) h(2500) b(5000)
}
esttab, keep(Robust)



eststo q_1 : rdrobust ty_mother_birth de01 if ty == 2022 , all c(5000) h(2500) b(5000)


rdrobust d_C_children de01 if ty == 2022 & cohort == 1980, all c(5000) h(2000) b(4000)












/*------------------------------------------------------------------------------
	descriptives by cohort
------------------------------------------------------------------------------*/

use "${temp}/census_001", clear



keep if inrange(mother_age, 15, 49)

collapse (mean) C_children N_children, by(mother_age ty_mother_birth) 

ren C_children C_
ren N_children B_
reshape wide C_ B_, i(mother_age) j(ty_mother_birth)

line C_1980 C_1981 C_1982 C_1983 C_1984 mother_age
line C_1985 C_1986 C_1987 C_1988 C_1989 mother_age


line B_1980 B_1981 B_1982 B_1983 B_1984 mother_age
line B_1985 B_1986 B_1987 B_1988 B_1989 mother_age


line B_1985 B_1986  mother_age



line B_1976* mother_age, xline(43)
line B_1977* mother_age, xline(42)
line B_1978* mother_age, xline(41)
line B_1979* mother_age, xline(40)
line B_1980* mother_age, xline(39)

line B_1981* mother_age, xline(38)
line B_1982* mother_age, xline(37)
line B_1983* mother_age, xline(36)
line B_1984* mother_age, xline(35)
line B_1985* mother_age, xline(34)
line B_1986* mother_age, xline(33)
line B_1987* mother_age, xline(32)
line B_1988* mother_age, xline(31)






/*------------------------------------------------------------------------------
	descriptives by cohort & CSOK
------------------------------------------------------------------------------*/


use ${tstar}/de, clear
keep if ev == 2018
ren tazon ksh4
keep ksh4 de01
tempfile population
save `population'



use "${temp}/census_001", clear

collapse (mean) C_children N_children, by(mother_age ty_mother_birth ksh4) 

merge m:1 ksh4 using `population', nogen keep(1 3)

gen CSOK = .
replace CSOK = 1 if inrange(de01, 2000, 4999)
replace CSOK = 0 if inrange(de01, 5000, 8000)

drop if CSOK == .

collapse (mean) C_children N_children, by(mother_age ty_mother_birth CSOK) 


ren C_children C_
ren N_children B_
reshape wide C_ B_, i(mother_age CSOK) j(ty_mother_birth)
ren C* C*_ 
ren B* B*_

reshape wide C_* B_*, i(mother_age ) j(CSOK)


line B_1976* mother_age, xline(43) lpattern(solid _)
line B_1977* mother_age, xline(42) lpattern(solid _)
line B_1978* mother_age, xline(41) lpattern(solid _)
line B_1979* mother_age, xline(40) lpattern(solid _)
line B_1980* mother_age, xline(39) lpattern(solid _)

line B_1981* mother_age, xline(38) lpattern(solid _)
line B_1982* mother_age, xline(37) lpattern(solid _)
line B_1983* mother_age, xline(36) lpattern(solid _)
line B_1984* mother_age, xline(35) lpattern(solid _)
line B_1985* mother_age, xline(34) lpattern(solid _)
line B_1986* mother_age, xline(33) lpattern(solid _)
line B_1987* mother_age, xline(32) lpattern(solid _)
line B_1988* mother_age, xline(31) lpattern(solid _)
line B_1989* mother_age, xline(30) lpattern(solid _)
line B_1990* mother_age, xline(29) lpattern(solid _)
line B_1991* mother_age, xline(28) lpattern(solid _)
line B_1992* mother_age, xline(27) lpattern(solid _)
line B_1993* mother_age, xline(26) lpattern(solid _)
line B_1994* mother_age, xline(25) lpattern(solid _)
line B_1995* mother_age, xline(24) lpattern(solid _)
line B_1996* mother_age, xline(23) lpattern(solid _)
line B_1997* mother_age, xline(22) lpattern(solid _)
line B_1998* mother_age, xline(21) lpattern(solid _)
