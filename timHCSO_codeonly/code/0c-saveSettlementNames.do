clear
cls
* locals
local homePath "\\apporto.com\dfs\NTHW\Users\tas2998_nthw\Desktop\Hungary" 
* log
log close _all
log using "`homePath'\log\saveSettlementNames.log", replace  

* load sheet from data dictionary with list of settlement codes and names
import excel "`homePath'\data\raw\settlementNames.xlsx", firstrow
destring CODE, replace
rename CODE terul
rename NAME name
* save it for a merge
save "`homePath'\data\mid\settlementNamesTrim.dta", replace