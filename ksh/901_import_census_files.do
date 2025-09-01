
/*------------------------------------------------------------------------------
	import census files from excel (only necessary on Dropbox)
------------------------------------------------------------------------------*/


clear
import excel using ${census}/Nepszamlalas2022_szemely_teszt.xlsx, first

foreach X of varlist * {
	local new_varname =  strlower("`X'")
	ren `X' `new_varname'
}


foreach X of varlist * {
	destring `X', replace
}


* missing variables

foreach YEAR in elszev maszev haszev neszev otszev szev6 szev7 szev8 szev9 uszev {
	gen `YEAR' = int(runiform(1990,2020))

}

foreach MONTH in elszho maszho haszho neszho otszho   ho6 ho7 ho8 ho9 uszho {
	gen `MONTH' = int(runiform(1,13))
}


save ${census}/szemely, replace





