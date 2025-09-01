

/*------------------------------------------------------------------------------
	set path
------------------------------------------------------------------------------*/



global LB x:\INPUT_KSH\Elveszuletes\
global census x:\INPUT_KSH\Nepszamlalas\2022\
global internal_migration x:\INPUT_KSH\Belfoldi_vandorlas\
global demography "x:\INPUT_MTA\KÖZÖS\Demografia\"
global abortion "x:\INPUT_KSH\Terhessegmegszakitas\"

global tstar x:\INPUT_MTA\KÖZÖS\Tstar\Tstar\


global map x:\INPUT_MTA\KÖZÖS\térkép fájlok\Shape
global maptile_geolist ${code}/ado_personal/maptile_geographies
global csok "x:\PROJECTS\Project37_A magyarországi családpolitikák fertilitásra gyakorolt hatásának vizsgálata\GYGY\data\village_csok\"



/*------------------------------------------------------------------------------
	color codes
------------------------------------------------------------------------------*/

global color1 "100 100 100"



/*------------------------------------------------------------------------------
	controls
------------------------------------------------------------------------------*/


global x1_post "i.ty_mother_birth##i.POST i.eduCatg##i.POST i.lcstip##i.POST i.hungarian##i.POST i.marriedBy2019##i.POST"
global x2_post "c.U_2018##i.POST c.I_2018##i.POST"
global x3_post "i.rkod2018##i.POST"
global x4_post "i.mkod2018##i.POST"
global x5_post "i.jaras175##i.POST"

global x1_ty "i.ty_mother_birth##i.ty  i.eduCatg##i.ty  i.lcstip##i.ty  i.hungarian##i.ty i.marriedBy2019##i.ty"
global x2_ty "c.U_2018##i.ty c.I_2018##i.ty"
global x3_ty "i.rkod2018##i.ty"
global x4_ty "i.mkod2018##i.ty"
global x5_ty "i.jaras175##i.ty"
