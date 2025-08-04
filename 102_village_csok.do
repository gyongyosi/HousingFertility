

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


use ${temp}/tstar_01, clear

merge m:1 ksh4 using `csok', nogen keep(1 3) keepusing(village_csok)

replace village_csok = 0 if village_csok == .

save ${temp}/tstar_02, replace



