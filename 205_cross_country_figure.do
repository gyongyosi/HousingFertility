// Cross-country scatter: affordability change vs TFR change, 2010–2019
// Data: cross_country_affordability.csv
// Output: cross_country_affordability_tfr.pdf

global DB   "/home/gyozo/Dropbox"
global root "${DB}/_babavaro"
global cc_data "${root}/data/cross_country"
global fig     "${root}/output"

// Colors
local c1  "17 112 170"    // countries – blue
local c2  "252 125 11"    // Hungary – orange
local c4  "87 96 108"     // OLS line – dark grey

// Load data
import delimited "${cc_data}/cross_country_affordability.csv", ///
    stringcols(1 2) clear


#delimit ;

twoway
    (scatter dtfr dpti,
        msymbol(none)
        mlabel(iso3) mlabpos(0) mlabsize(vsmall) mlabcolor("`c1'"))
    (lfit dtfr dpti,
        lcolor("`c4'") lpattern(dash) lwidth(thin))
    ,
    xline(0, lcolor(gs14) lwidth(thin))
    yline(0, lcolor(gs14) lwidth(thin))
    ylabel(-0.6(0.2)0.4, format(%3.1f) labsize(small))
    xlabel(-80(20)40, labsize(small))
    xtitle("Change in price-to-income ratio, 2010-2019", size(small))
    ytitle("Change in TFR, 2010-2019", size(small))
    legend(off)
    graphregion(color(white)) plotregion(color(white))
    ;

#delimit cr

graph export "${fig}/cross_country_affordability_tfr.pdf", as(pdf) replace
