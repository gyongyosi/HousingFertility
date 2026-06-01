

dis "`c(username)'"

if "`c(username)'" == "gyozo" {

	global DB "/home/gyozo/Dropbox"
	global root ${DB}/_babavaro
	global code /home/gyozo/GitHub/HousingFertility/ksh

	sysdir set PERSONAL /home/gyozo/ado/personal/
	sysdir set PLUS "/home/gyozo/ado/plus/"
}


do ${code}/001_set_path





/*------------------------------------------------------------------------------
	run the code
------------------------------------------------------------------------------*/

/*
do ${code}/101_merge
do ${code}/102_village_csok
do ${code}/103_create_variables

