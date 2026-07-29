/*------------------------------------------------------------------------------
	create mother panel
------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------
	dataset 1: women-year-level panel
------------------------------------------------------------------------------*/

local mother_born_lower = 1955
local mother_born_upper = 2004

clear
set obs 3000
gen ty = _n if inrange(_n, 1970, 2018)
drop if ty == .	
tempfile timeframe
save `timeframe'

use "${microcensus}/szemely_2016_MTA", clear

egen szemazon = group(azon szsor)

count 
destring neme, replace
keep if neme == 2
count 

* generate woman-level birthday vars
gen td_mother_birth = mdy(ho,nap,szev)
format td_mother_birth %td
gen tm_mother_birth = ym(szev, ho)
format tm_mother_birth %tm
gen ty_mother_birth = yofd(dofm(tm_mother_birth))
* keep women born within target time range
keep if inrange(ty_mother_birth, `mother_born_lower', `mother_born_upper')
count 

* monthly version of child birth dates
gen tm_child_1 = ym(elszev, elszho)
gen tm_child_2 = ym(maszev, maszho)
gen tm_child_3 = ym(haszev, haszho)
gen tm_child_4 = ym(neszev, neszho)
gen tm_child_5 = ym(otszev, otszho)
forval i = 6(1)15 {
		gen tm_child_`i' = ym(SZEV`i', HO`i')
}

* format monthly version
forval i = 1(1)15 {
	format tm_child_`i' %tm
}
* yearly version of child birth dates
gen ty_child_1 = elszev
gen ty_child_2 = maszev
gen ty_child_3 = haszev
gen ty_child_4 = neszev
gen ty_child_5 = otszev
forval i = 6(1)15 {
	gen ty_child_`i' = SZEV`i'
}

* keep relevant vars 
keep szemazon td* tm* ty*
* combine woman-level with year-level to create panel
cross using `timeframe'

* regression outcomes: flow and stock of children
gen N_children = 0
sort szemazon ty 
forval i = 1(1)15 {
	replace N_children = N_children + 1 if ty_child_`i' == ty
}
* fix strangely high tuplets
replace N_children=1 if N_children > 4 
* generate cumulative variable
bysort szemazon : gen C_children = sum(N_children)
tab N_children
tab C_children
* save 
compress
save "${temp}/microcensus_001", replace




/*------------------------------------------------------------------------------
	dataset 2: women-level (time-invariant) characteristics
------------------------------------------------------------------------------*/

use "${microcensus}/szemely_2016_MTA", clear

egen szemazon = group(azon szsor)

ren LAKEV_X lakev_x
destring lakev_x, replace
replace lakev_x = 1 if lakev_x == .

ren szev ty_mother_birth
* keep variables of interest, including moving variables
keep szemazon irelo irelsz lcstip hazev cspot enemzv mnemzv /* vallasv */ gakt jc terul lakev_x lakev lakho eterul ty_mother_birth

** create time-invariant controls: age, education, ethnicity, religion

* AGE
* categorical by cohort
gen cohort5 = .
forval i = 1951(5)2016 {
	local j = `i' + 4
	replace cohort5 = `i' if inrange(ty_mother_birth, `i', `j')
}
* binary version
gen young = .
replace young = 1 if inrange(ty_mother_birth, 1989, .)
replace young = 0 if inrange(ty_mother_birth, ., 1988)

* EDUCATION
destring irelsz, replace
gen eduCatg = 0
* no secondary school
replace eduCatg = 1 if inlist(irelsz,0,1)
* secondary-vocational
replace eduCatg = 2 if inlist(irelsz,2,3,4)
* secondary-general + some non-degree tertiary
replace eduCatg = 3 if inlist(irelsz,5,6,7)
* college, university, or grad degree
replace eduCatg = 4 if inlist(irelsz,8,9,10)
** create binary version
gen eduHigh = inlist(irelsz,5,6,7,8,9,10)
* create non-categorical version
tab eduCatg, gen(edu_)

* ETHNICITY: binary variable for Hungarian ethnicities
destring enemzv, replace
destring mnemzv, replace
gen hungarian = (enemzv>=100 & enemzv<200)
gen roma = (inrange(enemzv, 300, 399) | inrange(mnemzv, 300, 399))
* base case (=0) is other
gen ethCatg = 0
* 1 is hungarian
replace ethCatg = 1 if hungarian==1
* 2 is roma, counting those with Hungarian as first and Roma as second as second
replace ethCatg = 2 if roma==1

* RELIGION
* base case (=0) is no response + others not listed here
/*
gen relCatg = 0 
* Catholic
replace relCatg = 1 if inlist(vallasv,100,111,200,300,311,400,410,420,440,480,510,530)
* Calvinist
replace relCatg = 2 if inlist(vallasv,1100,1101,1110,1111,1181)
* Lutheran
replace relCatg = 3 if inlist(vallasv,1200,1210,1211,1220)
* None
replace relCatg = 4 if inlist(vallasv,0,50,51)
** create binary version
gen relXn = inlist(relCatg,1,2,3)
*/

compress
save "${temp}/microcensus_mother_characteristics", replace









/*------------------------------------------------------------------------------
	dataset 3: 2014 settlement-level T-STAR vars into tempfile tstar --> 2022 loc ksh4_bpker
------------------------------------------------------------------------------*/

local tVarsToKeep ksh4_bpker jaras175 mkod2018 rkod2018 CSOK_* SH_t_1 SH_t_2 SH_t_3 SH_t_4 de01 de01_2012 de01_2018  emp_sh_0 emp_sh_1 emp_sh_2 emp_sh_3 emp_sh_4 emp_sh_5 emp_sh_6 emp_sh_7 emp_sh_8 emp_sh_9 subsidy_1_2016_2023 subsidy_2_2016_2023 subsidy_4_2016_2023 subsidy_3_2019_2023 U_2012* ln_income_2012* hsShare_2012* women_15_49*


* load T-STAR data from 100 code file
use "${temp}/tstar_important", clear
* get 2018 snapshot (pre-treatment)
keep if ty == 2014
* vars that we want to attach
keep `tVarsToKeep'
* save into temp file for merging soon
compress
tempfile tstar
save `tstar'

/*------------------------------------------------------------------------------
	dataset 4: 2014 settlement-level T-STAR vars into tempfile qtstar --> time-varying loc Q_ksh4_bpker
------------------------------------------------------------------------------*/

* save 2018 pop in different temp file bc will merge on moving-adjusted settlement
use "${temp}/tstar_important", clear
* get 2018 snapshot (pre-treatment)
keep if ty == 2014
* vars that we want to attach
keep `tVarsToKeep'
* rename these variables with "Q_" prefixes
ren * Q_*
* save into different temp file for merging soon
compress
tempfile qtstar
save `qtstar'

/*------------------------------------------------------------------------------
	dataset 5: 2014 settlement-level T-STAR vars into tempfile ptstar --> 2018 loc P_ksh4_bpker
------------------------------------------------------------------------------*/

* save 2018 pop in different temp file bc will merge on moving-adjusted settlement
use "${temp}/tstar_important", clear
* get 2018 snapshot (pre-treatment)
keep if ty == 2014
* vars that we want to attach
keep `tVarsToKeep'
* rename these variables with "Q_" prefixes
ren * P_*
* save into different temp file for merging soon
compress
tempfile ptstar
save `ptstar'








/*------------------------------------------------------------------------------
	merge all 5 datasets
------------------------------------------------------------------------------*/

* load census panel
use "${temp}/microcensus_001", clear
* merge 1 of 4: merge with woman-level characteristics
merge m:1 szemazon using "${temp}/microcensus_mother_characteristics", nogen keep(1 3)

** create some time-varying variables
* AGE
gen mother_age = ty - ty_mother_birth
* MARITAL STATUS
destring cspot, replace
gen married = (cspot==2 & ty>hazev)
* gen 2019 dummy
gen marriedBy2013 = (cspot==2 & hazev<2013)
* NUM KIDS
gen tmp_kids_by_2013 = C_children if ty == 2012
egen kidsBy2013 = mean(tmp_kids_by_2013), by(szemazon)
drop tmp_kids_by_2013

* account for moving in the settlement id
destring eterul, replace
gen prev_ksh5 = eterul
gen prev_ksh4_bpker = int(prev_ksh5/10)
gen prev_ksh4 = prev_ksh4_bpker
* fix Budapest districts
foreach Y in 956 317 1806 546 1339 1658 2974 2540 2958 1070 1421 2469 2429 1633 1131 820 211 2928 401 602 1318 1021 3413 {
	replace prev_ksh4 = 1357 if prev_ksh4_bpker == `Y'
}
drop prev_ksh5


destring terul, replace
gen ksh5 = terul
*replace ksh5 = eterul if lakev_x == 1 & ty < lakev // NOT using, see instead the same condiion a few lines below
gen ksh4_bpker = int(ksh5/10)
gen ksh4 = ksh4_bpker
* fix Budapest districts
foreach Y in 956 317 1806 546 1339 1658 2974 2540 2958 1070 1421 2469 2429 1633 1131 820 211 2928 401 602 1318 1021 3413 {
	replace ksh4 = 1357 if ksh4_bpker == `Y'
}
drop ksh5
* merge 2 of 4: merge in T-STAR for 2022 settlement
merge m:1 ksh4_bpker using `tstar', nogen keep(1 3) 


destring lakev_x, replace

* merge 3 of 4: merge in T-STAR for MOVING-ADJUSTED TIME-VARYING settlement
gen Q_ksh4_bpker = ksh4_bpker
* this variable takes previous settlement if move=1 and year<year of move
replace Q_ksh4_bpker = prev_ksh4_bpker if lakev_x == 1 & ty < lakev 
* merge happens here on MOVING-ADJUSTED TIME-VARYING settlement
merge m:1 Q_ksh4_bpker using `qtstar', nogen keep(1 3)  
* combine Budapest districts
gen Q_ksh4 = Q_ksh4_bpker
foreach Y in 956 317 1806 546 1339 1658 2974 2540 2958 1070 1421 2469 2429 1633 1131 820 211 2928 401 602 1318 1021 3413 {
	replace Q_ksh4 = 1357 if Q_ksh4_bpker == `Y'
}

* merge 4 of 4: merge in T-STAR for 2018 settlement
gen P_ksh4_bpker_tmp = Q_ksh4_bpker if ty==2012
* panel is still balanced so no missing vals here
egen P_ksh4_bpker = mode(P_ksh4_bpker_tmp), by(szemazon)
drop P_ksh4_bpker_tmp
* merge happens here on MOVING-ADJUSTED 2018 settlement
merge m:1 P_ksh4_bpker using `ptstar', nogen keep(1 3)
* combine Budapest districts
gen P_ksh4 = P_ksh4_bpker
foreach Y in 956 317 1806 546 1339 1658 2974 2540 2958 1070 1421 2469 2429 1633 1131 820 211 2928 401 602 1318 1021 3413 {
	replace P_ksh4 = 1357 if P_ksh4_bpker == `Y'
}




* did you move in 2013 or after?
gen mover = lakev_x==1 & lakev>=2013 
* if so, what was the year of zour move?
gen mover_year = lakev if mover==1
* did you move within settlement in 2013 or after?
gen mover_sameSett = (lakev_x==1 & lakev>=2013 & ksh4==prev_ksh4)
* did you move across settlement in 2013 or after?
gen mover_newSett = (lakev_x==1 & lakev>=2013 & ksh4!=prev_ksh4)
gen mover_newSett_check = (P_ksh4!=ksh4)
* checks
tab mover
tab mover mover_sameSett
tab mover mover_newSett
tab mover_sameSett mover_newSett
tab mover_newSett mover_newSett_check

* identify moving related to CSOK 5000 cutoff
gen mover_withinITT = (mover & CSOK_all==1 & P_CSOK_all==1)
gen mover_intoITT = (mover & CSOK_all==1 & P_CSOK_all==0)
gen mover_withoutITT = (mover & CSOK_all==0 & P_CSOK_all==0)
gen mover_outofITT = (mover & CSOK_all==0 & P_CSOK_all==1)
* identify moving related to CSOK actual eligibility
gen mover_withinTOT = (mover & CSOK_0000_all==1 & P_CSOK_0000_all==1)
gen mover_intoTOT = (mover & CSOK_0000_all==1 & P_CSOK_0000_all==0)
gen mover_withoutTOT = (mover & CSOK_0000_all==0 & P_CSOK_0000_all==0)
gen mover_outofTOT = (mover & CSOK_0000_all==0 & P_CSOK_0000_all==1)
* CSOK_all==1 //2022 location has 5K or less
* CSOK_all==0 //2022 location more than 5K

* P_CSOK_all==1 //2018 location has 5K or less
* P_CSOK_all==0 //2018 location more than 5K
* P_CSOK_all==. //2018 location NOT in Hungary
drop if P_CSOK_all==. //drop people who moved from other countries 443,830

/*
* settlement level variables
gen U_2018 = mn01_2018 / de01_2018
gen I_2018 = (tx02_2018 - tx03_2018) / tx01_2018
* turn CSOK_0000 variable's entries for non-eligible settlements from . to 0
replace CSOK_0000 = 0 if CSOK_0000 == .
*/
lab var edu_1 "Primary school"
lab var edu_2 "Vocational school"
lab var edu_3 "High school"
lab var edu_4 "College"
lab var mother_age "Age"

*cap drop POST_2013
*gen POST_2013 = (ty >= 2014)

* save "${temp}/census_002", replace
count
keep if inrange(mother_age, 15, 49)
count
save "${temp}/microcensus_002_unbal", replace








