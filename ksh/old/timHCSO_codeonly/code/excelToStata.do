clear
cls
* locals
local homePath "\\apporto.com\dfs\NTHW\Users\tas2998_nthw\Desktop\Hungary"

import excel using "`homePath'\data\raw\Census2022_personal_sample.xlsx", firstrow clear
rename *, lower
save "`homePath'\data\raw\personal_2022_10% sample.dta", replace 