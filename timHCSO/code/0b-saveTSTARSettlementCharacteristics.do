clear
cls
* locals
local homePath "X:\Kimeno\kutato29\Output1\Working_files"    
* log
log close _all
log using "`homePath'\log\wrangleTSTAR.log", replace  

* load T-STAR data
use "`homePath'\data\raw\data_for_KSH.dta", replace

* rename variables
rename ksh4 terul
rename ty date 

* generate categories based on 2019 population level (pop19) 
gen pop19 = b03 if date==2019
egen pop19_2 = max(pop19), by(terul)
drop pop19
rename pop19_2 pop19
* generate cutoff variable (small19)
gen small19 = (pop19 <= 5000)
* normalize 2019 population level to cutoff (pop19Norm)
gen pop19Norm = (pop19 - 5000) / 1000

** save settlement-level dummies for 1) village CSOK, and 2) type 
collapse (mean) settlement_type village_csok pop19 small19 pop19Norm, by(terul)
save "`homePath'\data\mid\settlementDummies.dta", replace