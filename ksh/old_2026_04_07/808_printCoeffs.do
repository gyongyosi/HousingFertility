cls

use "${temp}/census_002_trim_updated", clear

* collapse by settlement
collapse (firstnm) U_2018 I_2018, by(ksh4)
* generate bins of 5
xtile U_2018_bin5 = U_2018, nq(5)
xtile I_2018_bin5 = I_2018, nq(5)
* generate bins of 2
xtile U_2018_bin2 = U_2018, nq(2)
xtile I_2018_bin2 = I_2018, nq(2)
* save
save "${temp}/binnedTSTAR", replace
* restore
use "${temp}/census_002_trim_updated", clear
drop _merge
* bring back into main data
merge m:1 ksh4 using  "${temp}/binnedTSTAR"

eststo clear
eststo q_1 : reghdfe N_childrenNEW i.CSOK_5000##ib2019.ty i.ty_mother_birth##i.ty i.kids_by_2018##i.ty i.eduCatg##i.ty i.marriedBy2019##i.ty if inrange(ty, 2014, 2024), absorb(i.szemazon) vce("cluster ksh4")
esttab using "${output}/tab9coeffs.rtf", replace

******************************************************************************

eststo clear
eststo q_1 : reghdfe N_childrenNEW i.CSOK_5000##ib2019.ty i.ty_mother_birth##i.ty i.kids_by_2018##i.ty i.eduCatg##i.ty i.rkod2018##i.ty i.marriedBy2019##i.ty i.lcstip##i.ty i.hungarian##i.ty i.relC##i.ty if inrange(ty, 2014, 2024), absorb(i.szemazon) vce("cluster ksh4")
esttab using "${output}/tab17coeffs.rtf", replace

******************************************************************************

eststo clear
eststo q_1 : reghdfe N_childrenNEW i.CSOK_5000##ib2019.ty i.ty_mother_birth##i.ty i.kids_by_2018##i.ty i.eduCatg##i.ty i.rkod2018##i.ty i.marriedBy2019##i.ty i.lcstip##i.ty i.hungarian##i.ty i.relC##i.ty i.I_2018_bin5##i.ty i.U_2018_bin5##i.ty if inrange(ty, 2014, 2024), absorb(i.szemazon) vce("cluster ksh4")
esttab using "${output}/tab29coeffs.rtf", 