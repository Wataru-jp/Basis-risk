***
* Climate index insurance project
* Purpose: yield and rainfall
* Date: 2021 May 30
***
cap global dropbox "D:/Dropbox" //Ken
global data "$dropbox\zambia_miura\w_insurance\Project_indexinsurance\data" 
global paper "$dropbox\zambia_miura\w_insurance\Project_indexinsurance\paper\AEJ" 
global presen "$dropbox\zambia_miura\w_insurance\Project_indexinsurance\presen\tex" 

global data "/Users/kodam1/Dropbox/Project_indexinsurance/data"
global paper "/Users/kodam1/Dropbox/Project_indexinsurance/paper/manuscript"
global presen "/Users/kodam1/Dropbox/Project_indexinsurance/presen/tex"

cd $data

**************************
**** Yiled and rainfall **
**************************
*** Prep ***
// Maize yield data from Crop Forecast Survey
import delimited "rawdata/cfs/yield_1975_2010.csv", varnames(1) clear 
// different units of maize production
gen prdctn_exp = prdctn_expctd*90/1000 if source == "sheet1" | source == "sheet2"
replace prdctn_exp = prdctn_expctd ///
	if source == "sheet3" | source == "sheet4" | source == "sheet5"
// drop inconsistent data
drop if source == "sheet1" & year==1996
// summarizing category
tab year district
collapse (sum) area_planted area_harvested prdctn_exp sales_expctd basal top, by(district year)
tab  year district

label var year "survey year"
label var district "district"
label var area_planted "area planted (ha)"
label var area_harvested "area to be harvested (ha)"
label var prdctn_exp "expected production ((MT)"
label var sales_expctd "expected sales (MT)"
label var basal "quantity of basal fertilizer used (MT)"
label var top "quantity of top fertilizer used (MT)"
      
gen choma = district == "Choma" 
label var choma "dummy taking 1 if choma"
tab year
gen trend = year - 1975
label var trend "linear trend (1975=0)"
gen yield = prdctn_exp/area_planted 
label var yield "Maize yield (MT/ha)"
tempfile temp_yield
save `temp_yield', replace

// Rainfall data: Choma
import delimited "rawdata/rainfall/Choma_1949-2012.csv", varnames(1) clear 
rename ay year

merge m:1 year using $data/statadata/choma2.dta
drop _merge
egen rain = rowtotal(nov dec jan feb mar apr) // annual (11-4)
egen rain_fl = rowtotal(jan feb) // flowering season
egen rain_pl = rowtotal(nov dec) // planting season
keep rain rain_fl rain_pl year nov dec jan feb
rename nov rain11
rename dec rain12
rename jan rain1
rename feb rain2
tempfile choma
save `choma', replace

// Rainfall data: Malima
import excel $data/rawdata/rainfall/Malima/rainfall＿BuleyaMalima.xlsx, ///
	 sheet("Malima_rainfall") firstrow clear
rename rainfall_irrigation rain 
keep year month rain
replace year = year - 1 if month <= 10
replace rain = 0 if rain == . & (month == 5 | month == 6 | month == 7)
replace rain = 0 if rain == . & (month == 8 | month == 9 | month == 10)
reshape wide rain, i(year) j(month)
egen mrain = rowtotal(rain11 rain12 rain1 rain2 rain3 rain4) // annual (11-4)
egen mrain_fl = rowtotal(rain1 rain2) // flowering season
egen mrain_pl = rowtotal(rain11 rain12) // planting season
drop if year == 2013| year== 1971
keep year mrain mrain_fl mrain_pl rain11 rain12 rain1 rain2
tempfile malima
save `malima', replace

// merge 
use `temp_yield', clear 
merge m:1 year using `choma'
drop _merge
merge m:1 year using `malima'
drop _merge
stop 
	
	
***** Figure 1 *****
twoway line ///
	yield year if year >= 1975 & choma==1 , ///
		graphregion(color(white)) bgcolor(white) xlabel(1975(5)2010) color(gs0) ///
		lpattern(solid) yaxis(1) xt(Crop year) yt(Maize yield (ton/ha), axis(1)) ///
	|| line yield year if year >= 1975 & choma==0, ///
		xlabel(1975(5)2010) color(gs0) lpattern(shortdash) yaxis(1) xt(Crop year) ///
		yt(Maize yield (tonnes/ha), axis(1)) ///
	|| line rain year if year >= 1975 & year < 2011 & choma == 1, ///
		xlabel(1975(5)2010) color(ltblue) lpattern(solid) yaxis(2) xt(Crop year) ///
		yt(Rainfall amounts (mm), axis(2)) ///
	|| line mrain year if year >= 1975 & year < 2011 & choma == 0, ///
		xlabel(1975(5)2010) color(ltblue) lpattern(shortdash) yaxis(2) xt(Crop year) ///
		yt(Rainfall amounts (mm), axis(2)) ///
		legend(order(1 "Yield (Choma)" 3 "Rainfall (Choma)" 2 "Yield (Sinazongwe)" 4 "Rainfall (Malima)")  cols(4) pos(6))
graph export $paper/manuscript/figure/yield-rain.eps, as(eps) name("Graph") replace
graph export $paper/figure/yield-rain.jpg, as(jpg) name("Graph") quality(100) replace
twoway line ///
	yield year if choma==1 , ///
		graphregion(color(white)) bgcolor(white) xlabel(1975(5)2010) color(gs0) ///
		lpattern(solid) yaxis(1) xt(Crop year) yt(Maize yield (tonnes/ha), axis(1)) ///
	|| line yield year if choma==0, ///
		xlabel(1975(5)2010) color(gs0) lpattern(longdash) yaxis(1) xt(Crop year) ///
		yt(Maize yield (tonnes/ha), axis(1)) ///
	|| line rain_fl year if year >= 1975 & year < 2011 & choma == 1, ///
		xlabel(1975(5)2010) color(ltblue) lpattern(solid) yaxis(2) xt(Crop year) ///
		yt(Rainfall amounts (mm), axis(2)) ///
	|| line mrain_fl year if year >= 1975 & year < 2011 & choma == 0, ///
		xlabel(1975(5)2010) color(ltblue) lpattern(shortdash) yaxis(2) xt(Crop year) ///
		yt(Rainfall amounts (mm), axis(2)) ///
		legend(order(1 "Yield (Choma)" 2 "Yield (Sinazongwe)" 3 "Rainfall (Choma)" 4 "Rainfall (Malima)") cols(4) pos(6))
graph export $paper/figure/yield-rain2.eps, as(eps) name("Graph") replace
graph export $paper/figure/yield-rain2.jpg, as(jpg) name("Graph") quality(100) replace

*** Regression: yield and rainfall ***
// prep
gen drought = (rain_fl <= 280)
gen mdrought = (mrain_fl <= 280)
gen flood = (rain12 >= 300 & rain12 != .)
gen mflood = (rain12 >= 300 & rain12 != .)

// prep2
keep year district yield rain mrain rain_fl mrain_fl rain_pl mrain_pl drought mdrought  flood mflood
rename rain rain1
rename mrain rain2
rename rain_fl rain_fl1
rename rain_pl rain_pl1
rename mrain_fl rain_fl2
rename mrain_pl rain_pl2
rename drought drought1
rename flood flood1
rename mdrought drought2
rename mflood flood2
reshape long rain rain_fl rain_pl drought flood, i(year district) j(rain_station)

// prep 3
gen drought_1st = (rain <= 600)
gen flood_1st = (rain >= 1000 & rain != .)
gen drought_2nd = (rain_fl <= 280)
gen flood_2nd = flood
gen drought_3rd = (rain_pl <= 214)
gen flood_3rd = (rain_pl >= 800&rain_pl != .)

replace rain = rain/100
replace rain_fl = rain_fl/100
replace rain_pl = rain_pl/100
gen rain_sq = rain^2
gen rain_fl_sq = rain_fl^2
gen rain_pl_sq = rain_pl^2
gen choma = district == "Choma"
gen trend = year - 1975
label var rain "~~Rainy season (100mm)"
label var rain_sq "~~Rainy season, squared."
label var rain_fl "~~Flowering season (100mm)"
label var rain_fl_sq "~~Flowering season, squared."
label var rain_pl "~~Planting season (100mm)"
label var rain_pl_sq "~~Planting season, squared."
label var drought "~~\quotes{Drought}"
label var flood "~~\quotes{Flood}"
label var choma "Choma district"
label var trend "Linear time trend"

label var drought_1st "~~\quotes{Drought} in 11/12 contract"
label var flood_1st "~~\quotes{Flood} in 11/12 contract"
label var drought_2nd "~~\quotes{Drought} in 12/13 contract"
label var flood_2nd "~~\quotes{Flood} in 12/13 contract"
label var drought_3rd "~~\quotes{Drought} in 13/14 contract"
label var flood_3rd "~~\quotes{Flood} in 13/14 contract"

// Regression for choma
est clear
eststo: reg yield rain rain_sq choma trend if rain_station == 1, r
eststo: reg yield rain_fl rain_pl choma trend if rain_station == 1, r
eststo: reg yield rain_fl rain_fl_sq rain_pl rain_pl_sq choma trend if rain_station == 1, r
eststo: reg yield drought_1st flood_1st choma trend if rain_station == 1, r
eststo: reg yield drought_2nd flood_2nd choma trend if rain_station == 1, r
***** Table 3 _choma*****
esttab using $paper/table/yield-rain.tex, ///
	se label nogap nonotes nomtitles b(%4.3f) nostar ///
	order(rain rain_sq rain_fl rain_fl_sq rain_pl rain_pl_sq drought_1st flood_1st drought_2nd flood_2nd choma trend) refcat(rain "Rainfall", nolabel) ///
	s(r2 N, fmt(%9.3f %9.0g) labels("R-squared" "Observations")) replace
	

esttab using "$dropbox\zambia_miura\w_insurance\Project_indexinsurance\presen\table\table3-yield-rain.tex", ///
	se label nogap nonotes nomtitles b(%4.3f) star(* 0.10 ** 0.05 *** 0.01) ///
	keep(rain rain_sq rain_fl rain_fl_sq rain_pl rain_pl_sq drought_1st flood_1st drought_2nd flood_2nd) ///
	order(rain rain_sq rain_fl rain_fl_sq rain_pl rain_pl_sq drought_1st flood_1st drought_2nd flood_2nd) ///
	refcat(rain "Rainfall", nolabel) nocons ///
	s(r2 N, fmt(%9.3f %9.0g) labels("R-squared" "Observations")) replace

// Regression for Malima
est clear
eststo: reg yield rain rain_sq choma trend if rain_station == 2, r
eststo: reg yield rain_fl rain_pl choma trend if rain_station == 2, r
eststo: reg yield rain_fl rain_fl_sq rain_pl rain_pl_sq choma trend if rain_station == 2, r
eststo: reg yield drought_3rd flood_3rd choma trend if rain_station == 2, r

***** Table 3 _malima*****
esttab using $paper/table/yield-rain_malima.tex, ///
	se label nogap nonotes nomtitles b(%4.3f) nostar ///
refcat(rain "Rainfall", nolabel) order(rain rain_sq rain_fl rain_fl_sq rain_pl rain_pl_sq drought_3rd flood_3rd choma trend) ///
	s(r2 N, fmt(%9.3f %9.0g) labels("R-squared" "Observations")) replace
	
esttab using "$dropbox\zambia_miura\w_insurance\Project_indexinsurance\presen\table\table3-yield-rain_malima.tex", ///
	se label nogap nonotes nomtitles b(%4.3f) star(* 0.10 ** 0.05 *** 0.01) ///
	keep(rain rain_sq rain_fl rain_fl_sq rain_pl rain_pl_sq drought_3rd flood_3rd) ///
	order(rain rain_sq rain_fl rain_fl_sq rain_pl rain_pl_sq drought_3rd flood_3rd) ///
	refcat(rain "Rainfall", nolabel) nocons  ///
	s(r2 N, fmt(%9.3f %9.0g) labels("R-squared" "Observations")) replace	
// Regression_both
est clear
eststo reg1: reg yield rain rain_sq choma trend if rain_station == 1, r
eststo reg2: reg yield rain_fl rain_fl_sq rain_pl rain_pl_sq choma trend if rain_station == 1, r
eststo reg3: reg yield drought flood choma trend if rain_station == 1, r
eststo reg4: reg yield rain rain_sq choma trend if rain_station == 2, r
eststo reg5: reg yield rain_fl rain_fl_sq rain_pl rain_pl_sq choma trend if rain_station == 2, r
eststo reg6: reg yield drought flood choma trend if rain_station == 2, r
***** Table 3 *****
esttab reg1 reg2 reg3 reg4 reg5 reg6 using $paper/table/table3-yield-rain_both.tex, ///
	se label nogap nonotes nomtitles b(%4.3f) star(* 0.10 ** 0.05 *** 0.01) ///
	order(rain rain_sq rain_fl rain_fl_sq rain_pl rain_pl_sq drought flood choma trend) ///
	s(r2 N, fmt(%9.3f %9.0g) labels("R-squared" "Observations")) replace

***** Original (Figure 1)
twoway line yield year if choma==1 , ///
	graphregion(color(white)) bgcolor(white) xlabel(1975(5)2010) color(gs0) ///
	lpattern(solid) yaxis(1) xt(Crop year) yt(Maize yield (ton/ha), axis(1)) ///
	|| line yield year if choma==0, ///
	xlabel(1975(5)2010) color(gs0) lpattern(longdash) yaxis(1) xt(Crop year) ///
	yt(Maize yield (ton/ha), axis(1)) ///
	|| line rain year if year >= 1975 & year < 2011 & choma == 1, ///
	xlabel(1975(5)2010) color(eltblue) lpattern(shortdash) yaxis(2) xt(Crop year) ///
	yt(Rainfall amounts (mm), axis(2)) ///
	legend(order(1 "Choma" 2 "Sinazongwe" 3 "Rainfall") cols(3))
*** Descriptive regression: yield and rainfall ***
** prep
replace rain = rain/100
replace mrain = mrain/100
gen rain_sq = rain^2
gen mrain_sq = mrain^2
//replace dec = dec/100
gen dec_sq = dec^2
gen flowering = (jan + feb)/100
gen flowering_sq = flowering^2
gen planting = (nov + dec)/100
gen planting_sq = germinating^2
gen drought = (flowering <= 2.8)
gen flood = (dec >= 300)
label var rain "Annual rainfall (100 mm)"
label var rain_sq "Annual rainfall (100 mm), sq."
label var dec "December (100 mm)"
label var dec_sq "December (100 mm), sq."
label var flowering "Flowering season (100 mm)"
label var flowering_sq "Flowering season (100 mm), sq."
label var germinating "Planting season (100 mm)"
label var germinating_sq "Planting season (100 mm), sq."
label var drought "Flood"
label var flood "Drought"
label var choma "Choma district"
label var trend "Linear time trend (1975 = 0)"
