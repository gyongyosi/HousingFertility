


use "${temp}/demography_1970_2023_women", clear

collapse (sum) population, by(ty age)

gen cohort = ty - age

ren age mother_age
keep population cohort mother_age

tempfile N_women
save `N_women'



use "${temp}/LB_001", clear

gen birth_ = 1

keep if inrange(mother_age, 15, 49)


collapse(sum) birth_ , by(mother_age birth_mother_ty)



gen cohort = birth_mother_ty
merge m:1 cohort mother_age using `N_women', nogen keep(1 3)
drop cohort
ren population pop_
reshape wide birth_ pop_, i(mother_age) j(birth_mother_ty)




sort mother_age

gen one = 1

forval i = 1970(1)2005 {
	bysort one : gen c_birth_`i' = sum(birth_`i')
	bysort one : gen C_birth_`i' = sum(birth_`i') / pop_`i'
	
	gen Birth_`i' = birth_`i' / pop_`i'
}


gen d_C_1976_1975 = C_birth_1976 - C_birth_1975
gen d_C_1975_1974 = C_birth_1975 - C_birth_1974
gen d_C_1974_1973 = C_birth_1974 - C_birth_1973

aaa




line c_birth_1978 c_birth_1979 c_birth_1980 c_birth_1981 c_birth_1982 c_birth_1983 mother_age
line c_birth_1970 c_birth_1971 c_birth_1972 c_birth_1973 c_birth_1974 c_birth_1975 mother_age

line  c_birth_1974 c_birth_1975 c_birth_1976 mother_age

line C_birth_1984 C_birth_1985 C_birth_1986 C_birth_1987 C_birth_1988 C_birth_1989 mother_age
line C_birth_1978 C_birth_1979 C_birth_1980 C_birth_1981 C_birth_1982 C_birth_1983 mother_age
line C_birth_1970 C_birth_1971 C_birth_1972 C_birth_1973 C_birth_1974 C_birth_1975 C_birth_1976 mother_age

line C_birth_1973 C_birth_1974 C_birth_1975 C_birth_1976 mother_age
line d_C* mother_age, xline(40)

line Birth_1984 Birth_1985 Birth_1986 Birth_1987 Birth_1988 Birth_1989 mother_age
line Birth_1978 Birth_1979 Birth_1980 Birth_1981 Birth_1982 Birth_1983 mother_age
line Birth_1970 Birth_1971 Birth_1972 Birth_1973 Birth_1974 Birth_1975 Birth_1976 mother_age


line C_birth_1974 C_birth_1975 C_birth_1976 C_birth_1977 C_birth_1978  mother_age

	
line birth_1974 birth_1975 birth_1976 birth_1977 birth_1978 mother_age
	
line birth_1978 birth_1979 birth_1980 birth_1981 birth_1982 birth_1983 mother_age


* 2019
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
line Birth_1989* mother_age, xline(31)


* 2015
line Birth_1974* mother_age, xline(39)
line Birth_1975* mother_age, xline(40)
line Birth_1976* mother_age, xline(39)

