

/*------------------------------------------------------------------------------
	prepares settlement-year-age level demography data
------------------------------------------------------------------------------*/


use "${demography}/Nepesseg_Kutatoszoba_1970-2020_-_jan1", clear

append using "${demography}/Nepesseg_Kutatoszoba_2021_-_jan1"
append using "${demography}/Nepesseg_Kutatoszoba_2022_-_jan1"
append using "${demography}/Nepesseg_Kutatoszoba_2023_-_jan1"

replace esev = 2023 if esev == 2024


ren esev ty 
ren nep_jan1 population
ren korev age
ren nem gender
ren ter ksh4_bpker

replace age = "90" if age =="90+"
destring age, replace

gen ksh4 = ksh4_bpker

foreach Y in 956 317 1806 546 1339 1658 2974 2540 2958 1070 1421 2469 2429 1633 1131 820 211 2928 401 602 1318 1021 3413 {
	replace ksh4 = 1357 if ksh4_bpker == `Y'
}

save "${temp}/demography_1970_2023", replace




use "${temp}/demography_1970_2023", clear

keep if inrange(age, 15, 49)
keep if gender == 2

save "${temp}/demography_1970_2023_women", replace











