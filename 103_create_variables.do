
use  ${temp}/tstar_02, clear


foreach X of varlist de3* de55 {
	replace `X' = 0 if `X' == .
}

gen ln_de01 = ln(de01)
gen ln_de55 = ln(de55)
gen women_childbearing_age = de30 + de31 + de32 + de33 + de34 + de35
gen women_15_19 = de30 + de31 + de32 
gen women_20_29 = de33 
gen women_30_39 = de34 
gen women_40_49 = de35 


gen fertility = de55 / women_childbearing_age
gen U_rate = mn01 / de09
gen income = tx02 / tx01
gen ln_income = ln(income)
gen migration_gap = (de62 - de63) / de01
gen ln_hp = ln(total_price)
gen transaction_per_pop = total_transaction / de01

foreach YEAR in 2003 2015 2018 {
	gen tmp_de01_`YEAR' = de01 if ty == `YEAR'
	egen de01_`YEAR' = mean(tmp_de01_`YEAR'), by(ksh4)
	drop tmp_de01_`YEAR'
}

gen pop_change = de01_2018 - de01_2003
gen pop_change_percent = (de01_2018 - de01_2003) / de01_2003


gen POST = (ty > 2018)

save ${temp}/tstar_03, replace









/*
use ${temp}/tstar_03, clear



#d ;
	binscatter village_csok ln_de01 if ty == 2019 , nq(50)
		xtitle("Log population, 2019")
		ytitle("Share of eligible")
		;
#d cr

#d ;
	binscatter village_csok de01 if ty == 2019 , nq(50)
		xtitle("Log population, 2019")
		ytitle("Share of eligible")
		;
#d cr


#d ;
	binscatter village_csok SH_t_1 if ty == 2019 , nq(50)
		xtitle("Share of primary school, 2011")
		ytitle("Share of eligible")
		;
#d cr

#d ;
	binscatter village_csok SH_t_4 if ty == 2019 , nq(50)
		xtitle("Share of college, 2011")
		ytitle("Share of eligible")
		;
#d cr


#d ;
	binscatter village_csok ln_income  if ty == 2019 , nq(50)
		xtitle("Log income per capita, 2019")
		ytitle("Share of eligible")
		;
#d cr



#d ;
	binscatter ln_income SH_t_4 if ty == 2019 , nq(50)
		xtitle("Share of college, 2011")
		ytitle("Share of eligible")
		;
#d cr

#d ;
	binscatter village_csok migration_gap  if ty == 2019 , nq(50)
		xtitle("Share of college, 2011")
		ytitle("Share of eligible")
		;
#d cr






#d ;
	binscatter village_csok sh_homeownership_b if ty == 2019 , nq(50)
		xtitle("Homeownership, 2011")
		ytitle("Share of eligible")
		;
#d cr

maptile sh_homeownership_b if ty == 2019 , geo(ksh4)


#d ;
	binscatter village_csok sh_room_1 if ty == 2019 , nq(50)
		xtitle("Share of houses with 1 room, 2011")
		ytitle("Share of eligible")
		;
#d cr

maptile sh_room_1 if ty == 2019 , geo(ksh4)


#d ;
	binscatter village_csok sh_room_2 if ty == 2019 , nq(50)
		xtitle("Share of houses with 2 rooms, 2011")
		ytitle("Share of eligible")
		;
#d cr








* fertility migration_gap 
foreach OUTCOME in migration_gap {
	cap drop TIME b se hi lo 
	reghdfe `OUTCOME' i.village##ib2015.ty if inrange(ty, 2005, .)  [pw = de01], absorb(ksh4 ty)
	gen TIME = _n if inrange(_n, 2000, 2023)

	gen b = .
	gen se = .
	forval i = 2005(1)2023 {
		replace b = _b[1.village_csok#`i'.ty] if TIME == `i'
		replace se = _se[1.village_csok#`i'.ty] if TIME == `i'
	}

	gen hi = b + 1.96 * se
	gen lo = b - 1.96 * se


	#d ;
		twoway (rcap hi lo TIME if inrange(TIME, 2005, 2023))
			(connected b TIME if inrange(TIME, 2005, 2023))
			;
	#d cr

}


* fertility migration_gap 
foreach OUTCOME in migration_gap {
	cap drop TIME b se hi lo 
	reghdfe `OUTCOME' i.village##ib2015.ty if inrange(ty, 2007, .) & inrange(de01_2015, ., 5000) [pw = de01], absorb(ksh4 ty)
	gen TIME = _n if inrange(_n, 2000, 2023)

	gen b = .
	gen se = .
	forval i = 2007(1)2023 {
		replace b = _b[1.village_csok#`i'.ty] if TIME == `i'
		replace se = _se[1.village_csok#`i'.ty] if TIME == `i'
	}

	gen hi = b + 1.96 * se
	gen lo = b - 1.96 * se


	#d ;
		twoway (rcap hi lo TIME if inrange(TIME, 2007, 2023))
			(connected b TIME if inrange(TIME, 2007, 2023))
			;
	#d cr

}



* de55 de58 de59 de67
foreach OUTCOME in  de67 {
	cap drop TIME b se hi lo 
	ppmlhdfe `OUTCOME' i.village##ib2015.ty if inrange(ty, 2007, .)  [pw = de01], absorb(ksh4 ty)
	gen TIME = _n if inrange(_n, 2000, 2023)

	gen b = .
	gen se = .
	forval i = 2007(1)2023 {
		replace b = _b[1.village_csok#`i'.ty] if TIME == `i'
		replace se = _se[1.village_csok#`i'.ty] if TIME == `i'
	}

	gen hi = b + 1.96 * se
	gen lo = b - 1.96 * se


	#d ;
		twoway (rcap hi lo TIME if inrange(TIME, 2007, 2023))
			(connected b TIME if inrange(TIME, 2007, 2023))
			;
	#d cr

}















