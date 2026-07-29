/*------------------------------------------------------------------------------
	improve kids birth date data in census
		idea: 
	although from mothers' data, we only know kid's birth date at month precision
	if the kid still lives in the same family/household, then we should get the day
	as well this approach also allows us to determine the gender of the kids
------------------------------------------------------------------------------*/

use "${census}/szemely", clear

* szev, ho, nap is the personal-level birthdate info
* will be looking for children's birthdays, so label w/ "_child" to prep for merge 
gen tm_child = ym(szev,ho)
format tm_child %tm
gen td_child = mdy(ho,nap,szev)
format td_child %td

* drop non-families 
keep if lcstip != 12
* drop repeats with same birth month at same address (e.g, drops one twin)
duplicates drop cimazon tm_child, force
* keep: person ID, address ID, family ID, birth month, birth day, sex, settlement
* will use address/household ID to merge onto mom-level dataset later
keep szemazon cimazon lcssor tm_child td_child neme terul

* save temporary file
tempfile kids_nontwins
save `kids_nontwins'

*******************************************************************************
use "${census}/szemely", clear
* drop non-families 
keep if lcstip != 12

* keep females
keep if neme == 2
* keep women born in 1965 after to match Live Birth for matching
keep if szev >= 1965

* birth date info of mother
gen td_mother_birth = mdy(ho, nap, szev)
format td_mother_birth %td
gen tm_mother_birth = ym(szev, ho)
format tm_mother_birth %tm
gen ty_mother_birth = yofd(dofm(tm_mother_birth))

* birth months of children
gen tm_child_1 = ym(elszev, elszho)
gen tm_child_2 = ym(maszev, maszho)
gen tm_child_3 = ym(haszev, haszho)
gen tm_child_4 = ym(neszev, neszho)
gen tm_child_5 = ym(otszev, otszho)
gen tm_child_6 = ym(szev6, ho6)
gen tm_child_7 = ym(szev7, ho7)
gen tm_child_8 = ym(szev8, ho8)
gen tm_child_9 = ym(szev9, ho9)
gen tm_child_10 = ym(uszev, uszho)
foreach X of varlist tm_child* {
	format `X' %tm
}

* mothers education as of 2022 census
gen edu_mother = 0
replace edu_mother = 1 if inlist(irelsz,0,1)
replace edu_mother = 2 if inlist(irelsz,2,3,4)
replace edu_mother = 3 if inlist(irelsz,5,6,7)
replace edu_mother = 4 if inlist(irelsz,8,9,10)
* location as of 2022 census
gen loc_mother = floor(terul / 10)
* month of marriage as of 2022 census
* gen tm_marriage = ym(hazev,hazho)
* format tm_marriage %tm
gen y_marriage = hazev
gen m_marriage = hazho
replace y_marriage = 0 if cspot==1 
replace m_marriage = 0 if cspot==1 
* marital status as of 2022 census
* gen marr_mother = cspot

* keep variables: personal ID, address ID, family number, mother birth date info,
* children birth months, mother's education, location, marital status, marriage month
keep szemazon cimazon lcssor td_mother_birth tm_mother_birth ty_mother_birth ///
	tm_child* edu_mother loc_mother y_marriage m_marriage
	
** fill in EXACT day of birth for kids still living with mom
* loop over mom-level vars for kid X's birth month
forval i = 1(1)10 {
	
	* for merge: adjust variable name of mom-level var for kid X's birth month
	ren tm_child_`i' tm_child
	* merge using address/household ID cimazon instead of personal ID szemazon
	* keep 3-matches and 1-master only, drop 2-using only
	merge m:1 cimazon tm_child using `kids_nontwins', nogen keep(1 3)
	
	* the temporary "kids_nontwins" data had these 7 vars...
	* ... szemazon cimazon lcssor tm_child td_child neme terul ...
	* ... but szemazon cimazon lcssor are also contained in the master data...
	* ... so their using version is deleted bc the master data are inviolable...
	* ... so this merge brings in 4 vars: tm_child td_child neme terul...
	* ... I rename them to match birth order here:
	ren tm_child tm_child_`i'
	ren td_child td_child_`i'
	ren neme nem_`i'
	* drop 5th digit of census settlement code to match 4-digit LB version
	* gen terul4 = floor(terul / 10)
	drop terul
	* ren terul4 terul_`i'
}

* for now, drop mom-level address ID (used in above merge) and family no. vars
drop cimazon lcssor 
* save
save "${temp}/census_for_matching_001", replace