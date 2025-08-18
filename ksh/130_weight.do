
/*------------------------------------------------------------------------------
	average weight
------------------------------------------------------------------------------*/


use ${temp}/live_birth_001, clear



collapse (mean) suly below2500, by(ty)



#d ;
	line suly ty,
		lcolor($color1 )
		lpattern(solid )
		graphregion(color(white))
		xtitle("")
		ytitle("Average weight of newborns")
		;
#d cr


#d ;
	line below2500 ty,
		lcolor($color1 )
		lpattern(solid )
		graphregion(color(white))
		xtitle("")
		ytitle("Share of newborns below 2500g")
		;
#d cr

