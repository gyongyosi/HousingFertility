
use "${census}/szemely", clear

keep if neme == 2


gen tm_mother_birth = ym(szev, ho)
format tm_mother_birth %tm

gen td_mother_birth = mdy(ho, nap, szev)
format td_mother_birth %td

gen ty_mother_birth = yofd(dofm(tm_mother_birth))
keep if inrange(ty_mother_birth, 1970, 1983)


gen ksh4_bpker = int(terul/10)
gen ksh4 = ksh4_bpker

foreach Y in 956 317 1806 546 1339 1658 2974 2540 2958 1070 1421 2469 2429 1633 1131 820 211 2928 401 602 1318 1021 3413 {
	replace ksh4 = 1357 if ksh4_bpker == `Y'
}


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

forval i = 1(1)10 {
	format tm_child_`i' %tm
}


keep szemazon tm_mother_birth  tm* td* ksh4* ty* irelo irelsz lcstip hazev



preserve

	clear
	set obs 3000
	gen ty = _n if inrange(_n, 1983, 2022)
	drop if ty == .	
	
	tempfile timeframe
	save `timeframe'


restore

cross using `timeframe'

gen mother_age_ty = (ty - ty_mother_birth) 


forval i = 1(1)10 {
	gen ty_child_`i' = yofd(dofm(tm_child_`i'))
}

gen N_children = 0
sort szemazon ty 
forval i = 1(1)10 {
	replace N_children = N_children + 1 if ty_child_`i' == ty
}
bysort szemazon : gen C_children = sum(N_children)

drop tm_child* ty_child*


* EDUCATION
gen eduCatg = 0
* no secondary school
replace eduCatg = 1 if inlist(irelsz,0,1)
* secondary-vocational
replace eduCatg = 2 if inlist(irelsz,2,3,4)
* secondary-general + some non-degree tertiary
replace eduCatg = 3 if inlist(irelsz,5,6,7)
* college, university, or grad degree
replace eduCatg = 4 if inlist(irelsz,8,9,10)

compress
save "${temp}/census_201", replace

aaa





use "${temp}/census_201", clear



foreach X in 2016 2019 2021 2022 {
	gen tmp_C_children_`X' = C_children if ty == `X'
	egen C_children_`X' = mean(tmp_C_children_`X' ), by(szemazon)
	drop tmp_C_children_`X'
}

gen d_C_children = C_children_2022 - C_children_2019
gen d_C_children_place = C_children_2019 - C_children_2016
 
 
tab eduCatg, gen(edu_)

 * keep one x-section
*keep if ty == 2022
 
 
* searching for the cutoff
binscatter d_C_children tm_mother_birth if ty == 2019, rd(235.5) ylabel(0 0.05 0.1 0.15 0.2 0.25) nq(50)
graph export "${output}/RDD_mother_birth_change_in_kids.pdf", as(pdf) replace



binscatter d_C_children_place tm_mother_birth if ty == 2016, rd(199.5)  ylabel(0 0.05 0.1 0.15 0.2 0.25) nq(50)
graph export "${output}/RDD_mother_birth_change_in_kids_placebo.pdf", as(pdf) replace

reg d_C_children ib37.mother_age_tm if ty == 2019
reg d_C_children_place ib37.mother_age_tm if ty == 2016
 
 
 binscatter d_C_children mother_age_tm if ty == 2019, nq(50)
 binscatter d_C_children tm_mother_birth if ty == 2019 , discrete xline(235.5 251.5)
 binscatter d_C_children_place tm_mother_birth if ty == 2016 , discrete xline(199.5 )

binscatter d_C_children tm_mother_birth if ty == 2019 & inrange(tm_mother, 220, 250) , discrete rd(235.5 )

 binscatter edu_4 tm_mother_birth if ty == 2019 & inrange(tm_mother, 210, 255) , discrete rd(235.5 )
 binscatter edu_1 tm_mother_birth if ty == 2019 & inrange(tm_mother, 210, 255) , discrete rd(235.5 )


rdrobust d_C_children tm_mother_birth if ty == 2019, c(235.5) all h(15) b(25)
rdrobust d_C_children tm_mother_birth if ty == 2019, c(235.5) all h(8) b(16)
rdrobust d_C_children tm_mother_birth if ty == 2019, c(235.5) all h(15) b(25) covs(edu_*)


rdrobust C_children_2019 tm_mother_birth if ty == 2019, c(235.5) all h(15) b(25)
 
 
* placebo 
rdrobust d_C_children tm_mother_birth if ty == 2019, c(247.5) all h(15) b(25)
rdrobust d_C_children tm_mother_birth if ty == 2019, c(223.5) all h(15) b(25)


rdrobust d_C_children_place tm_mother_birth if ty == 2016, c(199.5) all h(15) b(25)
 
 
 
* day level birth date
 
 binscatter d_C_children td_mother_birth if ty == 2019 & inrange(tm_mother, 210, 255), rd(7182.5) discrete
 binscatter d_C_children td_mother_birth if ty == 2019 & inrange(tm_mother, 210, 255), rd(7182.5) nq(100)

 binscatter d_C_children td_mother_birth if ty == 2019 & inrange(tm_mother, 210, 255), rd(7182.5) nq(100)

 rdrobust d_C_children td_mother_birth if ty == 2019, c(7182.5) all

 
 * diff-in-diff
 gen TREATED = (tm_mother_birth > 235.5)
 gen POST = (ty > 2019)
 reghdfe N_children i.TREATED##i.POST if inrange(tm_mother, 220, 240) & inrange(ty, 2014, .) , absorb(szemazon ty i.eduCatg##i.POST)
 
  reghdfe N_children i.TREATED##ib2019.ty mother_age_ty if inrange(tm_mother, 220, 240) & inrange(ty, 2014, .) , absorb(szemazon ty i.eduCatg##i.ty)

  
  


use "${temp}/census_201", clear


/*
foreach X in 2016 2019 2021 2022 {
	gen tmp_C_children_`X' = C_children if ty == `X'
	egen C_children_`X' = mean(tmp_C_children_`X' ), by(szemazon)
	drop tmp_C_children_`X'
}

gen d_C_children = C_children_2022 - C_children_2019
gen d_C_children_place = C_children_2019 - C_children_2016
 
 
*tab eduCatg, gen(edu_)
*/  
  
collapse (mean) C_children N_chi, by( tm_mother_birth mother_age_ty)
ren C_children C_
ren N_chi N_
reshape wide C_ N_ , i(mother_age_ty) j(tm_mother)
  
  
line C_234 C_235 C_236 C_237 mothe
line N_235 N_236 N_237 N_238 N_239 mothe
line N_235 N_236 mothe
line C_235 C_236 mothe, xline(39)
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
binscatter d_C_children td_mother_birth if ty == 2022, xline(5478) nq(50)
binscatter d_C_children td_mother_birth if ty == 2022, xline(5478) nq(100)

 
binscatter d_C_children tm_mother_birth if ty == 2022, xline(239)
binscatter d_C_children tm_mother_birth if ty == 2022, rd(251.5)

binscatter C_children_2014 tm_mother_birth if ty == 2022, rd(191.5)


rdrobust d_C_children tm_mother_birth if ty == 2022, c(251.5) all
rdrobust d_C_children td_mother_birth if ty == 2022, c(7182.5) all
rdrobust C_children_2018 td_mother_birth if ty == 2022, c(7182.5) all
rdrobust C_children_2019 td_mother_birth if ty == 2022, c(7182.5) all


rdrobust C_children_2019 td_mother_birth if ty == 2022, c(6817.5) all
rdrobust d_C_children_place td_mother_birth if ty == 2022, c(6817.5) all

rdrobust d_C_children_place2 td_mother_birth if ty == 2022, c(6452.5) all


