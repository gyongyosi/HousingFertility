


/*------------------------------------------------------------------------------
	average weight by CSOK status
------------------------------------------------------------------------------*/

use ${temp}/live_birth_001, clear



collapse (sum) suly below2500, by(ty village_csok)

ren suly suly_
ren below2500 below2500_


reshape wide suly below, i(ty) j(village_csok)


#d ;
	line suly_1 suly_0 age,
		lcolor($color1 $color2 )
		lpattern(solid _ )
		graphregion(color(white))
		legend(order(1 "Village CSOK eligible" 2 "Village CSOK ineligible"))
		xtitle("")
		ytitle("Average weight of newborns")
		;
#d cr

#d ;
	line below2500_1 below2500_0 age,
		lcolor($color1 $color2 )
		lpattern(solid _ )
		graphregion(color(white))
		legend(order(1 "Village CSOK eligible" 2 "Village CSOK ineligible"))
		xtitle("")
		ytitle("Share of newborns below 2500g")
		;
#d cr




/*------------------------------------------------------------------------------
	average weight by CSOK status
		around the cutoff
------------------------------------------------------------------------------*/

use ${temp}/live_birth_001, clear

keep if inrange(de01_2018, 2000, 8000)

collapse (sum) suly below2500 thet, by(ty village_csok)

ren suly suly_
ren below2500 below2500_
ren thet thet_


reshape wide suly below thet, i(ty) j(village_csok)


#d ;
	line suly_1 suly_0 age,
		lcolor($color1 $color2 )
		lpattern(solid _ )
		graphregion(color(white))
		legend(order(1 "Village CSOK eligible" 2 "Village CSOK ineligible"))
		xtitle("")
		ytitle("Average weight of newborns")
		;
#d cr

#d ;
	line below2500_1 below2500_0 age,
		lcolor($color1 $color2 )
		lpattern(solid _ )
		graphregion(color(white))
		legend(order(1 "Village CSOK eligible" 2 "Village CSOK ineligible"))
		xtitle("")
		ytitle("Share of newborns below 2500g")
		;
#d cr


#d ;
	line thet_1 thet_0 age,
		lcolor($color1 $color2 )
		lpattern(solid _ )
		graphregion(color(white))
		legend(order(1 "Village CSOK eligible" 2 "Village CSOK ineligible"))
		xtitle("")
		ytitle("Length of pregnancy")
		;
#d cr
