

use "${census}/szemely", clear

keep if neme == 2


gen tm_mother_birth = ym(szev, ho)
format tm_mother_birth %tm

gen td_mother_birth = mdy(ho, nap, szev)
format td_mother_birth %td

gen ty_mother_birth = yofd(dofm(tm_mother_birth))
keep if inrange(ty_mother_birth, 1973, 1977)


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

gen mother_age_tm = (ty - ty_mother_birth) 


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

compress
save "${temp}/census_101", replace

aaa



use "${temp}/census_101", clear



foreach X in 2014 2019 2022 {
	gen tmp_C_children_`X' = C_children if ty == `X'
	egen C_children_`X' = mean(tmp_C_children_`X' ), by(szemazon)
	drop tmp_C_children_`X'
}

gen d_C_children = C_children_2019 - C_children_2014
 

binscatter d_C_children td_mother_birth if ty == 2022, xline(5478) nq(50)
binscatter d_C_children td_mother_birth if ty == 2022, xline(5478) nq(100)

 
binscatter d_C_children tm_mother_birth if ty == 2022, xline(191)
binscatter d_C_children tm_mother_birth if ty == 2022, rd(191.5)

binscatter C_children_2014 tm_mother_birth if ty == 2022, rd(191.5)






