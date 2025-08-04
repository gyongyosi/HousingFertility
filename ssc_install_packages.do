
ssc install estout
ssc install reghdfe
ssc install ppmlhdfe
ssc install binscatter

net install rdrobust, from(https://raw.githubusercontent.com/rdpackages/rdrobust/master/stata) replace
net install rddensity, from(https://raw.githubusercontent.com/rdpackages/rddensity/master/stata) replace
net install lpdensity, from(https://raw.githubusercontent.com/nppackages/lpdensity/master/stata) replace


ssc install maptile
ssc install shp2dta
ssc install spmap

ssc install winsor2
ssc install ivreg2
ssc install ivreghdfe
ssc install did_imputation
ssc install ftools
ssc install gtools
ssc install lpdensity, replace
ssc install mergepoly

