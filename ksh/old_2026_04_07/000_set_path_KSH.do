

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
global hp "X:\PROJECTS\Project37_A magyarországi családpolitikák fertilitásra gyakorolt hatásának vizsgálata\GYGY\data\hp\"



global agglomeration "x:\INPUT_MTA\KÖZÖS\"

/*------------------------------------------------------------------------------
	color scheme
------------------------------------------------------------------------------*/

global color1      "17 112 170"
global color2       "252 125 11"
global color3       "163 172 185"
global color4       "87 96 108"
global color5       "95 162 206"
global color6       "200 82 0"
global color7       "123 132 143"
global color8       "163 204 233"
global color9       "255 188 121"
global color10       "200 208 217"

/*------------------------------------------------------------------------------
	controls
------------------------------------------------------------------------------*/


global x1_post "i.ty_mother_birth##i.POST i.eduCatg##i.POST i.lcstip##i.POST i.hungarian##i.POST i.marriedBy2019##i.POST"
global x2_post "c.U_2018##i.POST c.I_2018##i.POST i.agglo##i.POST"
global x3_post "i.rkod2018##i.POST"
global x4_post "i.mkod2018##i.POST"
global x5_post "i.jaras175##i.POST"

global x1_ty "i.ty_mother_birth##i.ty  i.eduCatg##i.ty  i.lcstip##i.ty  i.hungarian##i.ty i.marriedBy2019##i.ty"
global x2_ty "c.U_2018##i.ty c.I_2018##i.ty"
global x3_ty "i.rkod2018##i.ty"
global x4_ty "i.mkod2018##i.ty"
global x5_ty "i.jaras175##i.ty"
