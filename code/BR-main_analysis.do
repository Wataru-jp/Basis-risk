***
* Climate index insurance project
* Purpose: main regressions 
* Date: 2021 June 9
* Update: 2023 March 30
***

cd "/Users/kodam1/Documents/GitHub/Basis-risk"

**************************
**** read data 
**************************
use "https://github.com/Wataru-jp/Basis-risk/raw/main/data/index_insurance.dta", clear
//use data/index_insurance.dta, clear

**************************
**** descriptive 
**************************
* Table
for num 2011/2013: eststo des_statX: qui estpost su Insurance agri9 agri10 loss /// 
	risk_extreme risk_severe risk_intermediate ///
	risk_moderate risk_slight risk_neutral winnings if year == X
* output	 
esttab des_stat2011 des_stat2012 des_stat2013 /// 
	using table/descriptive-all.tex, ///
	label cells("mean(pattern(1 1 1 1) fmt(3) label(Mean)) sd(par label(Std.Dev.))") ///cells("mean sd")
	nogap nonotes nonumber nomtitles ///
	mgroups("2011/12" "2012/13" "2013/14", pattern(1 1 1) ///
	span prefix(\multicolumn{@span}{c}{) suffix(}) /// 
	erepeat(\cmidrule(lr){@span})) replace
estimates drop des_stat2011 des_stat2012 des_stat2013

// Text (Descriptive statistics: cover rate)
*2011
qui su Insurance if year==2011
di %4.2f r(mean)
di  %4.2f 25/835*100*r(mean) //8.10%
*2012
qui su Insurance if year==2012
di %4.2f r(mean)
di  %4.2f 15/835*100*r(mean) //4.70%
*2013
qui su Insurance if year==2013
di %4.2f r(mean)
di  %4.2f 15/835*100*r(mean) //4.04%


**************************
**** descriptive: BR
**************************
// histogram
twoway hist p if site == 1 & year == 2012, freq width(0.015) color(gs8) lcolor(black) ///
	graphregion(color(white)) xlabel(0(0.05)0.25) ylabel(0(2)8) ///
	ytitle("") xtitle("") ///
	|| hist p if site == 2 & year == 2012, freq width(0.015) color(gs13) lcolor(gs7) ///
	|| hist p if site == 3 & year == 2012, freq width(0.015) color(none) lcolor(gs10) ///
	legend(order(1 "Site A" 2 "Site B" 3 "Site C") cols(3)) ///
	title("Plot-level drought") name(g1, replace)
twoway hist r if site == 1 & year == 2011, freq width(0.008) color(gs8) lcolor(black) ///
	graphregion(color(white)) xlabel(0(0.05)0.15) ylabel(0(2)8) ///
	ytitle("") xtitle("") ///
	|| hist r if site == 2 & year == 2011, freq width(0.008) color(gs13) lcolor(gs7) ///
	|| hist r if site == 3 & year == 2011, freq width(0.008) color(none) lcolor(gs10) ///
	legend(order(1 "Site A" 2 "Site B" 3 "Site C") cols(3)) ///
	title("Spatial basis risk 2011/12") name(g2, replace)
twoway hist r if site == 1 & year == 2012, freq width(0.008) ///
	graphregion(color(white)) xlabel(0(0.05)0.15) ylabel(0(2)8) color(gs8) lcolor(black) ///
	ytitle("") xtitle("") ///
	|| hist r if site == 2 & year == 2012, freq width(0.008) color(gs13) lcolor(gs7) ///
	|| hist r if site == 3 & year == 2012, freq width(0.008) color(none) lcolor(gs10) ///
	legend(order(1 "Site A" 2 "Site B" 3 "Site C") cols(3)) ///
	title("Spatial basis risk 2012/13") name(g3, replace)
twoway hist r if site == 1 & year == 2013, freq width(0.008) color(gs8) lcolor(black) ///
	graphregion(color(white)) xlabel(0(0.05)0.15) ylabel(0(2)8) ///
	ytitle("") xtitle("") ///
	|| hist r if site == 2 & year == 2013, freq width(0.008) color(gs13) lcolor(gs7) ///
	|| hist r if site == 3 & year == 2013, freq width(0.008) color(none) lcolor(gs10) ///
	legend(order(1 "Site A" 2 "Site B" 3 "Site C") cols(3)) ///
	title("Spatial basis risk 2013/14") name(g4, replace)
grc1leg g1 g2 g3 g4 
graph export figure/prob-drought.eps, as(eps) name("Graph") replace // eps format

// descriptive: BR
forvalue i = 1/3 {
	gen p`i' = p
	gen r`i' = r
	replace p`i' = . if site != `i'
	replace r`i' = . if site != `i'
}
label var p "\$p^d$: drought induced crop loss"
label var r "\$r^s$: spatial basis risk"
label var p1 "~~Site A (16 households)"
label var p2 "~~Site B (16 households)"
label var p3 "~~Site C (16 households)"
label var r1 "~~Site A (16 households)"
label var r2 "~~Site B (16 households)"
label var r3 "~~Site C (16 households)"
* output	 
for num 2011/2013: eststo prob_statX: qui estpost su p p1 p2 p3 r r1 r2 r3 if year == X
esttab prob_stat2011 prob_stat2012 prob_stat2013 /// 
	using table/probability-stat.tex, ///
	label cells("mean(pattern(1 1 1 1) fmt(3) label(Mean)) sd(par label(Std.Dev.))") ///cells("mean sd")
	nogap nonotes nonumber nomtitles ///
	mgroups("2011/12" "2012/13" "2013/14", pattern(1 1 1) ///
	span prefix(\multicolumn{@span}{c}{) suffix(}) /// 
	erepeat(\cmidrule(lr){@span})) replace

	
**************************
**** OLS
**************************
// prep for regresison
* prep: label 
label var loss "\$l$" 
label var p "\$p^d$"
label var r "\$r^s$"
foreach var of varlist sex educ age {
	gen `var'1 = 0
	replace `var'1 = `var' if year==2011
	bysort hhid: egen `var'2 = sum(`var'1)
	replace `var' = `var'2
	drop `var'1 `var'2
	}  

est clear
eststo model1: reg Insurance x1 x2 year2012 year2013, cl(hhid)
estadd local socio "No", replace
eststo model2: reg Insurance p r loss year2012 year2013, cl(hhid)
estadd local socio "No", replace
eststo model3: reg Insurance x1 x2 p r loss year2012 year2013, cl(hhid)
estadd local socio "No", replace
eststo model4: reg Insurance x1 x2 risk_severe2 risk_intermediate ///
	 risk_slight risk_neutral winnings2 year2012 year2013 sex educ age, cl(hhid)
estadd local socio "Yes", replace
eststo model5: reg Insurance p r loss risk_severe2 risk_intermediate ///
	 risk_slight risk_neutral winnings2 year2012 year2013 sex educ age, cl(hhid)
estadd local socio "Yes", replace
eststo model6: reg Insurance x1 x2 p r loss risk_severe2 risk_intermediate ///
	 risk_slight risk_neutral winnings2 year2012 year2013 sex educ age, cl(hhid)
estadd local socio "Yes", replace
//test _b[x1] = -_b[x2]
//estadd local coef `r(F)', replace

* output	 
esttab model1 model2 model3 model4 model5 model6 ///
	using table/OLS.tex, ///
	se label nogap nonotes nomtitles b(%4.3f) nostar ///
	s(socio r2 N, fmt(%9.3f %9.3f %9.0g) ///
	labels("HH characteristics" "R squared" "Observations")) ///
	keep(x1 x2 r p loss risk_severe2 risk_intermediate risk_slight risk_neutral ///
	winnings2 year2012 year2013 _cons) ///
	order(x2 x1 r p loss risk_severe2 risk_intermediate risk_slight risk_neutral winnings2) replace


* OLS _ exclusing site A
est clear
eststo model1: reg Insurance x1 x2 year2012 year2013 if site!=1, cl(hhid)
estadd local socio "No", replace
eststo model2: reg Insurance x1 x2 p r loss year2012 year2013 if site!=1, cl(hhid)
estadd local socio "No", replace
eststo model3: reg Insurance x1 x2 risk_severe2 risk_intermediate ///
	 risk_slight risk_neutral winnings2 year2012 year2013 if site!=1, cl(hhid)
estadd local socio "No", replace
eststo model4: reg Insurance x1 x2 p r loss risk_severe2 risk_intermediate ///
	 risk_slight risk_neutral winnings2 year2012 year2013 if site!=1, cl(hhid)
estadd local socio "No", replace
eststo model5: reg Insurance x1 x2 risk_severe2 risk_intermediate ///
	 risk_slight risk_neutral winnings2 year2012 year2013 sex educ age if site!=1, cl(hhid)
estadd local socio "Yes", replace
eststo model6: reg Insurance x1 x2 p r loss risk_severe2 risk_intermediate ///
	 risk_slight risk_neutral winnings2 year2012 year2013 sex educ age if site!=1, cl(hhid)
estadd local socio "Yes", replace



**************************
**** FE
**************************
est clear
eststo model1: areg Insurance x2 year2012 year2013, absorb(hhid) cl(hhid)
estadd local RA "No", replace
eststo model2: areg Insurance x2 r year2012 year2013, absorb(hhid) cl(hhid)
estadd local RA "No", replace
eststo model3: areg Insurance x2 year2012 year2013 risk_severe2 risk_intermediate ///
	 risk_slight risk_neutral winnings2, absorb(hhid) cl(hhid)
estadd local RA "Yes", replace
eststo model4: areg Insurance x2 r year2012 year2013 risk_severe2 risk_intermediate ///
	 risk_slight risk_neutral winnings2, absorb(hhid) cl(hhid)
estadd local RA "Yes", replace
eststo model5: areg Insurance r year2012 year2013, absorb(hhid) cl(hhid)
estadd local RA "No", replace

* output	 
//global paper "/Users/kodam1/Dropbox/Project_indexinsurance/paper/memo/results"
esttab model1 model2 model5 model3 model4  ///
	using table/FE.tex, ///
	se label nogap nonotes nomtitles b(%4.3f) nostar ///
	s(RA r2 N, fmt(%9.3f %9.3f %9.0g) ///
	labels("Risk aversion class" "R squared" "Observations")) ///
	keep(x2 r winnings2 year2012 year2013 _cons) order(x2 r winnings2) replace
estimates drop model1 model2 model3 model4 model5

// Economic impact
areg Insurance x2 year2012 year2013, absorb(hhid) cl(hhid)
di %4.3f -_b[x2]*0.01*1.113 // increase in unit purchase
*** 2011/12 ***
su r if year==2011
di 0.01/r(sd)
su Insurance if year==2011
di %4.3f (-_b[x2]*0.01*1.113)/r(mean)*100
di %4.2f (25/835)*r(mean)*100 // actual cover rate
di %4.2f (25/835)*-_b[x2]*0.05*1.113*100 // pp increase in cover rate (5p.p.)
di %4.2f (25/835)*(r(mean)-_b[x2]*0.05*1.113)*100 // cover rate after 5 pp decrease
di %4.2f (r(mean)-_b[x2]*0.05*1.113)/r(mean)*100-100 // increase %
* 2012/13
su r if year==2012
di 0.01/r(sd)
su Insurance if year==2012
di %4.2f r(mean)
di %4.2f (-_b[x2]*0.01*1.113)/r(mean)*100
di %4.2f (15/835)*r(mean)*100 // actual cover rate
di %4.2f (15/835)*-_b[x2]*0.05*1.113*100 // pp increase in cover rate (5p.p.)
di %4.2f (15/835)*(r(mean)-_b[x2]*0.05*1.113)*100 // cover rate after 5 pp decrease
di %4.2f (r(mean)-_b[x2]*0.05*1.113)/r(mean)*100-100 // increase % 
* 2012/13 (Footnote 18 if low product basis risk)
di %4.2f [(15/835)*-_b[x2]*0.05*1.113*100]*4/3 // pp increase in cover rate
di %4.2f [(r(mean)-_b[x2]*0.05*1.113)/r(mean)*100-100] *4/3 // increase % 
* 2013/14
su r if year==2013
di 0.01/r(sd)
su Insurance if year==2013
di %4.2f r(mean)
di %4.2f (-_b[x2]*0.01*1.113)/r(mean)*100
di %4.2f (15/835)*r(mean)*100 // actual cover rate
di %4.2f (15/835)*-_b[x2]*0.05*1.113*100 // pp increase in cover rate (5p.p.)
di %4.2f (15/835)*(r(mean)-_b[x2]*0.05*1.113)*100 // cover rate after 5 pp decrease
di %4.2f (r(mean)-_b[x2]*0.05*1.113)/r(mean)*100-100 // increase % 
* 2013/14 (Footnote 18 if low product basis risk)
di %4.2f [(15/835)*-_b[x2]*0.05*1.113*100]*4/3 // pp increase in cover rate
di %4.2f [(r(mean)-_b[x2]*0.05*1.113)/r(mean)*100-100] *4/3 // increase % 

**************************
**** FE: Bootstrap
**************************
eststo model1: areg Insurance x2 year2012 year2013, absorb(hhid) vce(bootstrap, reps(1000) seed(123)) nodots
estadd local RA "No", replace
eststo model2: areg Insurance x2 r year2012 year2013, absorb(hhid) vce(bootstrap, reps(1000) seed(123)) nodots
estadd local RA "No", replace
eststo model3: areg Insurance x2 year2012 year2013 risk_severe2 risk_intermediate ///
	 risk_slight risk_neutral winnings2, absorb(hhid) vce(bootstrap, reps(1000) seed(123)) nodots
estadd local RA "Yes", replace
eststo model4: areg Insurance x2 r year2012 year2013 risk_severe2 risk_intermediate ///
	 risk_slight risk_neutral winnings2, absorb(hhid) vce(bootstrap, reps(1000) seed(123)) nodots
estadd local RA "Yes", replace
eststo model5: areg Insurance r year2012 year2013 risk_severe2 risk_intermediate ///
	 risk_slight risk_neutral winnings2, absorb(hhid) vce(bootstrap, reps(1000) seed(123)) nodots
estadd local RA "No", replace

// Table
esttab model1 model2 model5 model3 model4  ///
	using table/FE_bs.tex, ///
	se label nogap nonotes nomtitles b(%4.3f) nostar ///
	s(RA r2 N, fmt(%9.3f %9.3f %9.0g) ///
	labels("Risk aversion class" "R squared" "Observations")) ///
	keep(x2 r winnings2 year2012 year2013 _cons) order(x2 r winnings2) replace

	
**************************
**** Optimal index 
**************************
// histogram: BR of optimal index
twoway hist r_opt if site == 1 & year == 2011, freq width(0.007) color(gs8) lcolor(black) ///
	graphregion(color(white)) xlabel(0(0.05)0.15) ylabel(0(2)8) ///
	ytitle("") xtitle("") ///
	|| hist r_opt if site == 2 & year == 2011, freq width(0.007) color(gs13) lcolor(gs7) ///
	|| hist r_opt if site == 3 & year == 2011, freq width(0.007) color(none) lcolor(gs10) ///
	legend(order(1 "Site A" 2 "Site B" 3 "Site C") cols(3)) ///
	title("Spatial basis risk, optimal index") name(g1, replace)
twoway hist dr if site == 1 & year == 2011, freq width(0.003) color(gs8) lcolor(black) ///
	graphregion(color(white)) xlabel(0(0.02)0.07) ylabel(0(2)10) ///
	ytitle("") xtitle("") ///
	|| hist dr if site == 2 & year == 2011, freq width(0.003) color(gs13) lcolor(gs7) ///
	|| hist dr if site == 3 & year == 2011, freq width(0.003) color(none) lcolor(gs10) ///
	legend(order(1 "Site A" 2 "Site B" 3 "Site C") cols(3)) ///
	title("Deductible spatial basis risk 2011/12") name(g2, replace)
twoway hist dr if site == 1 & year == 2012, freq width(0.003) ///
	graphregion(color(white)) xlabel(0(0.02)0.07) ylabel(0(2)10) color(gs8) lcolor(black) ///
	ytitle("") xtitle("") ///
	|| hist dr if site == 2 & year == 2012, freq width(0.003) color(gs13) lcolor(gs7) ///
	|| hist dr if site == 3 & year == 2012, freq width(0.003) color(none) lcolor(gs10) ///
	legend(order(1 "Site A" 2 "Site B" 3 "Site C") cols(3)) ///
	title("Deductible spatial basis risk 2012/13") name(g3, replace)
twoway hist dr if site == 1 & year == 2013, freq width(0.003) color(gs8) lcolor(black) ///
	graphregion(color(white)) xlabel(0(0.02)0.07) ylabel(0(2)10) ///
	ytitle("") xtitle("") ///
	|| hist dr if site == 2 & year == 2013, freq width(0.003) color(gs13) lcolor(gs7) ///
	|| hist dr if site == 3 & year == 2013, freq width(0.003) color(none) lcolor(gs10) ///
	legend(order(1 "Site A" 2 "Site B" 3 "Site C") cols(3)) ///
	title("Deductible spatial basis risk 2013/14") name(g4, replace)
grc1leg g1 g2 g3 g4 
graph export figure/basis-risk-opt.eps, as(eps) name("Graph") replace // eps format

// text: descriptive
su r_opt
su dr if year == 2011
su dr if year == 2012
su dr if year == 2013

// Back-of-the-envelope-calculation
areg Insurance x2 year2012 year2013, absorb(hhid) cl(hhid)
gen before = Insurance
gen after = Insurance - e(b)[1,1]*dr2*loss
gen change = (after - before)/ before* 100

gen before_cr = Insurance*25/835*100
replace before_cr = Insurance*15/835*100 if year2011 == 0
gen after_cr = after*25/835*100
replace before_cr = after*15/835*100 if year2011 == 0
gen change_cr = (after_cr - before_cr)/ before_cr* 100

label var before "Units of insurance takeup (\#)"
label var after "Expected units, optimal index (\#)"
label var change "Expected increase in units (\%)"
label var before_cr "Cover rate (\%)"
label var after_cr "Expected cover rate, optimal index (\%)"
label var change_cr "Expected increase in cover rate (\%)"

// Table
for num 2011/2013: eststo des_statX: qui estpost ///
	su before after before_cr after_cr if year == X
esttab des_stat2011 des_stat2012 des_stat2013 /// 
	using table/envelope-calculation.tex, ///
	label cells("mean(pattern(1 1 1 1) fmt(3) label(Mean)) sd(par label(Std.Dev.))") ///
	nogap nonotes nonumber nomtitles ///
	mgroups("2011/12" "2012/13" "2013/14", pattern(1 1 1) ///
	span prefix(\multicolumn{@span}{c}{) suffix(}) /// 
	erepeat(\cmidrule(lr){@span})) replace
estimates drop des_stat2011 des_stat2012 des_stat2013
