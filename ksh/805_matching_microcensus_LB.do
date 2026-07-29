** adding in births from LB ****************************************************

* load unbalanced census panel from 401 file
use "${temp}/microcensus_002_unbal", clear
* merge with match file
merge m:1 szemazon using "${temp}/microcensus_matches_all"

* drop the match file entries that did not find match in census (only 13)
drop if _merge==2
* save the census entries that do NOT match to LB and therefore won't be updated
preserve
	keep if _merge==1
	drop _merge
	save "${temp}/microcensusNoMomID", replace
restore

* save the census entries that do match to LB
keep if _merge==3
drop _merge
* merge with info on kids births from LB
merge m:1 momID using "${temp}/lb_forMerge", update
* drop the LB panel file entries that did not find match in census
drop if _merge==2
drop _merge
* save census entries that did match to LB
save "${temp}/microcensusYesMomID", replace
********************************************************************************
* load census entries that did match to LB
use "${temp}/microcensusYesMomID", clear

* test whether LB and census line up on first-parity births
gen testing1 = tm_child_1==tm_child_LB_1
tab testing1, m
* these should be the same bc all non-equalities come from post-Oct 2022
count if testing1==0
count if (testing1==0 & tm_child_1==.)
* no possible additions before Oct 2022 because I dropped them in LB
tab tm_child_LB_1 if testing1==0

* test whether LB and census line up on second-parity births
gen testing2 = tm_child_2==tm_child_LB_2
tab testing2, m
count if testing2==0
count if (testing2==0 & tm_child_2==.)
* there are now some possible additions before Oct 2022
tab tm_child_LB_2 if testing2==0

* test whether LB and census line up on second-parity births
gen testing3 = tm_child_3==tm_child_LB_3
tab testing3, m
count if testing3==0
count if (testing3==0 & tm_child_3==.)
* there are now some possible additions before Oct 2022
tab tm_child_LB_3 if testing3==0
* breakdown
tab tm_child_LB_3 if (testing3==0 & tm_child_3==.)
tab tm_child_LB_3 if (testing3==0 & tm_child_3!=.)

* extract birth years from Live Birth panel
gen ty_child_LB_1 = year(dofm(tm_child_LB_1))
gen ty_child_LB_2 = year(dofm(tm_child_LB_2))
gen ty_child_LB_3 = year(dofm(tm_child_LB_3))
gen ty_child_LB_4 = year(dofm(tm_child_LB_4))
gen ty_child_LB_5 = year(dofm(tm_child_LB_5))
gen ty_child_LB_6 = year(dofm(tm_child_LB_6))
gen ty_child_LB_7 = year(dofm(tm_child_LB_7))
gen ty_child_LB_8 = year(dofm(tm_child_LB_8))
gen ty_child_LB_9 = year(dofm(tm_child_LB_9))
gen ty_child_LB_10 = year(dofm(tm_child_LB_10))
* update here: fill in if missing census and not missing LB!
replace ty_child_1 = ty_child_LB_1 if (ty_child_LB_1!=. & ty_child_1==. & tm_child_LB_1 >= ym(2016,10))
replace ty_child_2 = ty_child_LB_2 if (ty_child_LB_2!=. & ty_child_2==. & tm_child_LB_2 >= ym(2016,10))
replace ty_child_3 = ty_child_LB_3 if (ty_child_LB_3!=. & ty_child_3==. & tm_child_LB_3 >= ym(2016,10))
replace ty_child_4 = ty_child_LB_4 if (ty_child_LB_4!=. & ty_child_4==. & tm_child_LB_4 >= ym(2016,10))
replace ty_child_5 = ty_child_LB_5 if (ty_child_LB_5!=. & ty_child_5==. & tm_child_LB_5 >= ym(2016,10))
replace ty_child_6 = ty_child_LB_6 if (ty_child_LB_6!=. & ty_child_6==. & tm_child_LB_6 >= ym(2016,10))
replace ty_child_7 = ty_child_LB_7 if (ty_child_LB_7!=. & ty_child_7==. & tm_child_LB_7 >= ym(2016,10))
replace ty_child_8 = ty_child_LB_8 if (ty_child_LB_8!=. & ty_child_8==. & tm_child_LB_8 >= ym(2016,10))
replace ty_child_9 = ty_child_LB_9 if (ty_child_LB_9!=. & ty_child_9==. & tm_child_LB_9 >= ym(2016,10))
replace ty_child_10 = ty_child_LB_10 if (ty_child_LB_10!=. & ty_child_10==. & tm_child_LB_10 >= ym(2016,10))
* re-combine with census entries that do NOT match to LB and were not updated
append using "${temp}/microcensusNoMomID"
* save all census entries
save "${temp}/microcensusAllMomID", replace
********************************************************************************
use "${temp}/microcensusAllMomID", clear

* RECOMPUTE regression outcomes: flow and stock of children
gen N_childrenNEW = 0
sort szemazon ty 
forval i = 1(1)10 {
	replace N_childrenNEW = N_childrenNEW + 1 if ty_child_`i' == ty
}
* fix strangely high tuplets
replace N_childrenNEW=1 if N_childrenNEW > 4 
bysort szemazon (ty): gen C_childrenNEW = sum(N_childrenNEW)
tab N_childrenNEW
tab C_childrenNEW

* adjust variables for heterogeneity regressions
replace kidsBy2013 = 3 if kidsBy2013 > 3

replace cohort5 = . if cohort5==1961 // not enough obs
replace cohort5 = . if cohort5==1966
replace cohort5 = 3 if cohort5==1971
replace cohort5 = 4 if cohort5==1976
replace cohort5 = 5 if cohort5==1981
replace cohort5 = 6 if cohort5==1986
replace cohort5 = 7 if cohort5==1991
replace cohort5 = 8 if cohort5==1996
replace cohort5 = 9 if cohort5==2001
replace cohort5 = . if cohort5==2006

rename ln_income_2012 ln_income_2012_cts 
rename U_2012 U_2012_cts 
rename hsShare_2012 hsShare_2012_cts 
rename Q_ln_income_2012 Q_ln_income_2012_cts
rename Q_U_2012 Q_U_2012_cts
rename Q_hsShare_2012 Q_hsShare_2012_cts 
rename P_ln_income_2012 P_ln_income_2012_cts
rename P_U_2012 P_U_2012_cts
rename P_hsShare_2012 P_hsShare_2012_cts 

* drop obs for speed
count
keep if inrange(ty,2008,2018)
keep szemazon ty C_childrenNEW C_children N_childrenNEW N_children CSOK_* Q_CSOK_* P_CSOK_* ///
	ty_mother_birth cohort5 marriedBy2013 kidsBy2013 lcstip eduCatg ethCatg /* relCatg */ ///
	U_2012* Q_U_2012* P_U_2012* ln_income_2012* Q_ln_income_2012* P_ln_income_2012* ///
	hsShare_2012* P_hsShare_2012* Q_hsShare_2012*  P_de01 P_de01_2012 P_SH_t_1 P_SH_t_2 P_SH_t_3 P_SH_t_4 ///
	ksh4 Q_ksh4 P_ksh4 jaras175 Q_jaras175 P_jaras175 ///  
	mover*
compress
count
* save this for regressions
save "${temp}/microcensus_002_unbal_filled", replace