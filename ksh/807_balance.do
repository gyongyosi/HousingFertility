use "${temp}/census_002_trim_updated", clear
******************************************************************************
keep if ty==2018
local thisYear = 2018
******************************************************************************

count
drop if CSOK_5000==.
count


#d ;
	twoway 
		(histogram ty_mother_birth if CSOK_5000==1, start(1969) disc color("$color1")) 
		(histogram ty_mother_birth if CSOK_5000==0, start(1969) disc fcolor(none) lcolor(black) ), 
		xtitle("Women's year of birth")
		legend(order(1 "Treated" 2 "Control"))
		;


#d cr
graph export "${output}/hist_ty_mother_birth_`thisYear'.pdf", as(pdf) replace



#d ;
	twoway 
		(histogram kids_by_2018 if CSOK_5000==1, start(0) disc color("$color1") ) 
		(histogram kids_by_2018 if CSOK_5000==0, start(0) disc fcolor(none) lcolor(black) ),
		xtitle("Number of kids")
		legend(order(1 "Treated" 2 "Control"))
		;
		
#d cr
graph export "${output}/hist_kids_by_2018_`thisYear'.pdf", as(pdf) replace


#d ;
	twoway 
		(histogram marriedBy2019 if CSOK_5000==1, disc color("$color1") ) 
		(histogram marriedBy2019 if CSOK_5000==0, disc fcolor(none) lcolor(black) ),
		xtitle("Married by 2019")
		legend(order(1 "Treated" 2 "Control"))
		;
		
#d cr
graph export "${output}/hist_marriedBy2019_`thisYear'.pdf", as(pdf) replace


#d ;
	twoway 
	(histogram hungarian if CSOK_5000==1, disc color("$color1") ) 
	(histogram hungarian if CSOK_5000==0, disc fcolor(none) lcolor(black) ),
		xtitle("Hungarian nationality")
		legend(order(1 "Treated" 2 "Control"))
		;
			

#d cr
graph export "${output}/hist_hungarian_`thisYear'.pdf", as(pdf) replace


#d ;
	twoway 
		(histogram U_2018 if CSOK_5000==1, start(0) width(0.01) color("$color1") ) 
		(histogram U_2018 if CSOK_5000==0, start(0) width(0.01)  fcolor(none) lcolor(black) ),
		xtitle("Unemployment")
		legend(order(1 "Treated" 2 "Control"))
		;
	
#d cr
graph export "${output}/hist_U_2018_`thisYear'.pdf", as(pdf) replace


#d ;
	twoway 
		(histogram I_2018 if CSOK_5000==1, start(-50) width(50) color("$color1") ) 
		(histogram I_2018 if CSOK_5000==0, start(-50) width(50) fcolor(none) lcolor(black) ),
		xtitle("Income")
		legend(order(1 "Treated" 2 "Control"))
		;
			
#d cr
graph export "${output}/hist_I_2018_`thisYear'.pdf", as(pdf) replace


#d ;
	twoway 
		(histogram eduCatg if CSOK_5000==1, disc color("$color1") ) 
		(histogram eduCatg if CSOK_5000==0, disc fcolor(none) lcolor(black) ),
		xtitle("Education")
		legend(order(1 "Treated" 2 "Control"))
		;
#d cr
graph export "${output}/hist_eduCatg_`thisYear'.pdf", as(pdf) replace


#d ;
	twoway 
		(histogram relC if CSOK_5000==1, disc color("$color1") ) 
		(histogram relC if CSOK_5000==0, disc fcolor(none) lcolor(black) ) ,
		xtitle("Religion")
		legend(order(1 "Treated" 2 "Control"))
		;

#d cr
graph export "${output}/hist_relC_`thisYear'.pdf", as(pdf) replace


#d ;
	twoway 
		(histogram lcstip if CSOK_5000==1, disc color("$color1") ) 
		(histogram lcstip if CSOK_5000==0, disc  fcolor(none) lcolor(black) ),
		xtitle("Family type")
		legend(order(1 "Treated" 2 "Control"))
		;

#d cr
graph export "${output}/hist_lcstip_`thisYear'.pdf", as(pdf) replace






*******************************************************************************
// CTS: ty_mother_birth kids_by_2018 marriedBy2019 hungarian U_2018 I_2018

tab eduCatg, gen(eduCatg_)
tab relC, gen(relC_)
tab lcstip, gen(lcstip_)


local thisYear = 2018
local VARS_TO_COMPARE "ty_mother_birth kids_by_2018 marriedBy2019 hungarian eduCatg_1 eduCatg_2 eduCatg_3 eduCatg_4 relC_1 relC_2 relC_3 relC_4 relC_5 lcstip_1 lcstip_2 lcstip_3 lcstip_4 lcstip_5 lcstip_6 lcstip_7 lcstip_8 lcstip_9 lcstip_10 lcstip_11 lcstip_12 lcstip_13 U_2018 I_2018 "


eststo clear
eststo TREATED: estpost sum `VARS_TO_COMPARE' if CSOK_5000 == 1, d
eststo CONTROL: estpost sum `VARS_TO_COMPARE' if CSOK_5000 == 0, d
eststo diff : estpost ttest `VARS_TO_COMPARE', by(CSOK_5000) unequal
eststo diff_welch : estpost ttest `VARS_TO_COMPARE', by(CSOK_5000) welch

esttab TREATED CONTROL diff using "${output}/tableStan_`thisYear'.rtf", wide cells("mean(pattern(1 1 0) fmt(2)) b(pattern(0 0 1) fmt(2)) sd(pattern(1 1 0) fmt(2)) t(pattern(0 0 1) fmt(2)) ") replace

esttab TREATED CONTROL diff_welch using "${output}/tableNorm_`thisYear'.rtf", wide cells("mean(pattern(1 1 0) fmt(2)) b(pattern(0 0 1) fmt(2)) sd(pattern(1 1 0) fmt(2)) t(pattern(0 0 1) fmt(2)) ") replace



foreach X in `VARS_TO_COMPARE' {
	egen mean_`X' = mean(`X'), by(CSOK_5000)
	egen std_`X' = sd(`X'), by(CSOK_5000)
	egen N_`X' = count(`X'), by(CSOK_5000)

}

collapse (mean) N_* mean_* std_*, by(CSOK_5000)
reshape long N_ mean_ std_, i(CSOK_5000) j(var) string
drop if var=="children" 
drop if var=="childrenNEW"
reshape wide N_ mean_ std_, i(var) j(CSOK_5000)

gen N = N_1 + N_0
gen beta = mean_1 - mean_0
gen var_0 = (std_0)^2 
gen var_1 = (std_1)^2 

gen tStan = beta / sqrt((var_1 / N_1) + (var_0 / N_0))
gen tNorm = beta / sqrt(var_1 + var_0)

* export
export delimited using "${output}/tableCts_`thisYear'.csv", replace delim(";")



**********************************************************************************
// CAT: kids_by_2018 marriedBy2019 eduCatg hungarian relC lcstip rkod2018

use "${temp}/census_002_trim_updated", clear
******************************************************************************
keep if ty==2018
local thisYear = 2018
******************************************************************************

count
drop if CSOK_5000==.
count 

estpost tab kids_by_2018 CSOK_5000, chi2
esttab using "${output}/table_Kids_`thisYear'.rtf", replace

estpost tab eduCatg CSOK_5000, chi2
esttab using "${output}/table_Educ_`thisYear'.rtf", replace

estpost tab relC CSOK_5000, chi2
esttab using "${output}/table_Relg_`thisYear'.rtf", replace

estpost tab lcstip CSOK_5000, chi2
esttab using "${output}/table_Fam_`thisYear'.rtf", replace

estpost tab rkod2018 CSOK_5000, chi2
esttab using "${output}/table_Regn_`thisYear'.rtf", replace