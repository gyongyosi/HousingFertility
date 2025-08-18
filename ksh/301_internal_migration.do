
clear
import delimited ${village_csok}/list_of_village_csok.csv, encoding(UTF-8)

ren v1 telnev_bpker


replace telnev_bpker = subinstr(telnev_bpker, "õ", "ő", .)
replace telnev_bpker = subinstr(telnev_bpker, "Õ", "Ő", .)
replace telnev_bpker = subinstr(telnev_bpker, "û", "ű", .)


merge m:1 telnev_bpker using ${hnk}/hnk_2018,  keep(1  3) keepusing(ksh*)

tab _
drop _

gen village_csok = 1

tempfile csok
save `csok'



use ${internal_migration}/BelfoldiVandorlas_2023_minta_allomany, clear

ren va_* *

lab var jel ""
lab var kshtip ""
lab var esev ""
lab var esho ""
lab var nem ""
lab var csal ""
lab var szulev ""
lab var allp ""
lab var odatel ""
lab var eltel ""
lab var korev ""


gen tm = (esev-1960) * 12 + esho - 1
format tm %tm

gen ty = yofd(dofm(tm))
drop esev esho

ren eltel out_tel
ren odatel in_tel


foreach X of varlist in_tel out_tel {

	local direction = subinstr("`X'", "_tel", "", .)

	ren `X' ksh4_bpker
	merge m:1 ksh4_bpker using `csok', nogen keep(1 3)
	ren ksh4_bpker `X'
	replace village_csok = 0 if village_csok == .
	ren village_csok `direction'_village_csok

}

foreach X of varlist out_tel in_tel {

	local direction = subinstr("`X'", "_tel", "", .)

	
	ren `X' tazon
	ren ty ev
	merge m:1 tazon ev using ${tstar}/de, nogen keep(1 3) keepusing(de01)
	merge m:1 tazon ev using ${tstar}/tx, nogen keep(1 3) keepusing(tx01 tx02 tx03)
	merge m:1 tazon ev using ${tstar}/mn, nogen keep(1 3) keepusing(mn01)
	
	ren tazon `X'
	ren ev ty

		
	foreach Y of varlist de01 tx01 tx02 tx03 mn01 {
		ren `Y' `Y'_`direction'
	}
}


replace jel = 1 if jel == 2
replace jel = 1 if jel == 3



* sanity check: it is weird in the sample data
gen age = ty - szulev
reg age korev
scatter age korev
graph export ${output}/check_internal_migration_age.pdf, as(pdf) replace


save ${temp}/internal_migration_01, replace

aaa









