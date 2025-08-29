


use ${tstar}/de, clear
keep if ev == 2018
ren tazon ksh4
keep ksh4 de01
tempfile population
save `population'





use "${temp}/demography_1970_2023_women", clear


merge m:1 ksh4 using `population', nogen keep(1 3)

gen CSOK = .
replace CSOK = 1 if inrange(de01, 3000, 4999)
replace CSOK = 0 if inrange(de01, 5000, 7000)

drop if CSOK == .

collapse (sum) population, by(ty age CSOK)

gen cohort = ty - age

ren age mother_age
ren population women_
keep women cohort mother_age CSOK

tempfile N_women
save `N_women'







use "${temp}/LB_001", clear

gen birth_ = 1

keep if inrange(mother_age, 15, 49)


ren ksh4_mother ksh4
merge m:1 ksh4 using `population', nogen keep(1 3) 

gen CSOK = .
replace CSOK = 1 if inrange(de01, 3000, 4999)
replace CSOK = 0 if inrange(de01, 5000, 7000)

drop if CSOK == .


collapse(sum) birth_ , by(CSOK mother_age birth_mother_ty)

gen cohort = birth_mother_ty
merge m:1 CSOK cohort mother_age using `N_women', nogen keep(1 3)
drop cohort
reshape wide birth_ women_, i(mother_age CSOK) j(birth_mother_ty)
ren birth* birth*_
ren women* women*_
reshape wide birth_* women*, i(mother_age) j(CSOK)





sort mother_age

gen one = 1

forval i = 1970(1)2005 {
	forval CSOK = 0(1)1 {
		bysort one : gen c_birth_`i'_`CSOK' = birth_`i'_`CSOK' / women_`i'_`CSOK'
		bysort one : gen C_birth_`i'_`CSOK' = sum(c_birth_`i'_`CSOK') 
		
		gen Birth_`i'_`CSOK' = birth_`i'_`CSOK' / women_`i'_`CSOK'

		
	}
}



aaa




line C_birth_1976* mother_age, xline(43)
line C_birth_1977* mother_age, xline(42)
line C_birth_1978* mother_age, xline(41)
line C_birth_1979* mother_age, xline(40)
line C_birth_1980* mother_age, xline(39)

line C_birth_1981* mother_age, xline(38)
line C_birth_1982* mother_age, xline(37)
line C_birth_1983* mother_age, xline(36)
line C_birth_1984* mother_age, xline(35)
line C_birth_1985* mother_age, xline(34)
line C_birth_1986* mother_age, xline(33)
line C_birth_1987* mother_age, xline(32)
line C_birth_1988* mother_age, xline(31)


line Birth_1976* mother_age, xline(43)
line Birth_1977* mother_age, xline(42)
line Birth_1978* mother_age, xline(41)
line Birth_1979* mother_age, xline(40)
line Birth_1980* mother_age, xline(39)

line Birth_1981* mother_age, xline(38)
line Birth_1982* mother_age, xline(37)
line Birth_1983* mother_age, xline(36)
line Birth_1984* mother_age, xline(35)
line Birth_1985* mother_age, xline(34)
line Birth_1986* mother_age, xline(33)
line Birth_1987* mother_age, xline(32)
line Birth_1988* mother_age, xline(31)





line C_birth_1984 C_birth_1985 C_birth_1986 C_birth_1987 C_birth_1988 C_birth_1989 mother_age
line C_birth_1978 C_birth_1979 C_birth_1980 C_birth_1981 C_birth_1982 C_birth_1983 mother_age
line C_birth_1970 C_birth_1971 C_birth_1972 C_birth_1973 C_birth_1974 C_birth_1975 C_birth_1976 mother_age





