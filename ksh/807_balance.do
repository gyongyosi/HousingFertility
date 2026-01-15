use "${temp}/census_002_trim_updated", clear
******************************************************************************
keep if ty==2018
local thisYear = 2018
******************************************************************************

count
drop if CSOK_5000==.
count

twoway ((histogram ty_mother_birth if CSOK_5000==1, start(1969) width(1) color(red%30) legend(off)) (histogram ty_mother_birth if CSOK_5000==0, start(1969) width(1) color(green%30) legend(off)))
graph export "${output}/hist_ty_mother_birth_`thisYear'.pdf", as(pdf) replace

twoway ((histogram kids_by_2018 if CSOK_5000==1, start(0) width(1) color(red%30) legend(off)) (histogram kids_by_2018 if CSOK_5000==0, start(0) width(1) color(green%30) legend(off)))
graph export "${output}/hist_kids_by_2018_`thisYear'.pdf", as(pdf) replace

twoway ((histogram marriedBy2019 if CSOK_5000==1, color(red%30) legend(off)) (histogram marriedBy2019 if CSOK_5000==0, color(green%30) legend(off)))
graph export "${output}/hist_marriedBy2019_`thisYear'.pdf", as(pdf) replace

twoway ((histogram hungarian if CSOK_5000==1, color(red%30) legend(off)) (histogram hungarian if CSOK_5000==0, color(green%30) legend(off)))
graph export "${output}/hist_hungarian_`thisYear'.pdf", as(pdf) replace

twoway ((histogram U_2018 if CSOK_5000==1, start(0) width(0.01) color(red%30) legend(off)) (histogram U_2018 if CSOK_5000==0, start(0) width(0.01) color(green%30) legend(off)))
graph export "${output}/hist_U_2018_`thisYear'.pdf", as(pdf) replace

twoway ((histogram I_2018 if CSOK_5000==1, start(-50) width(50) color(red%30) legend(off)) (histogram I_2018 if CSOK_5000==0, start(-50) width(50) color(green%30) legend(off)))
graph export "${output}/hist_I_2018_`thisYear'.pdf", as(pdf) replace

twoway ((histogram eduCatg if CSOK_5000==1, color(red%30) legend(off)) (histogram eduCatg if CSOK_5000==0, color(green%30) legend(off)))
graph export "${output}/hist_eduCatg_`thisYear'.pdf", as(pdf) replace

twoway ((histogram relC if CSOK_5000==1, color(red%30) legend(off)) (histogram relC if CSOK_5000==0, color(green%30) legend(off))) 
graph export "${output}/hist_relC_`thisYear'.pdf", as(pdf) replace

twoway ((histogram lcstip if CSOK_5000==1, color(red%30) legend(off)) (histogram lcstip if CSOK_5000==0, color(green%30) legend(off))) 
graph export "${output}/hist_lcstip_`thisYear'.pdf", as(pdf) replace

twoway ((histogram rkod2018 if CSOK_5000==1, color(red%30) legend(off)) (histogram rkod2018 if CSOK_5000==0, color(green%30) legend(off))) 
graph export "${output}/hist_rkod2018_`thisYear'.pdf", as(pdf) replace



*******************************************************************************
// CTS: ty_mother_birth kids_by_2018 marriedBy2019 hungarian U_2018 I_2018
estpost ttest ty_mother_birth kids_by_2018 marriedBy2019 hungarian U_2018 I_2018, by(CSOK_5000) unequal
esttab using "${output}/tableStan_`thisYear'.rtf", wide cells("b count se t df_t p_l p p_u mu_1 N_1 mu_2 N_2") replace
estpost ttest ty_mother_birth kids_by_2018 marriedBy2019 hungarian U_2018 I_2018, by(CSOK_5000) welch
esttab using "${output}/tableNorm_`thisYear'.rtf", wide cells("b count se t df_t p_l p p_u mu_1 N_1 mu_2 N_2") replace

foreach X in ty_mother_birth kids_by_2018 marriedBy2019 hungarian U_2018 I_2018 {
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
export delimited using "${output}/tableCts_`thisYear'.csv", replace


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