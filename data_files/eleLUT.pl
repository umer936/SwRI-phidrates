#!/opt/local/bin/perl -w

$eleLUT {'H-'} = "H<sup>-</sup>";
$eleLUT {'Hi'} = "H<sup>+</sup> + e";
$eleLUT {'H'} = "H";
$eleLUT {'Hpi'} = "H<sup>+</sup> + e";
$eleLUT {'he'} = "He";
$eleLUT {'hei'} = "He<sup>+</sup> + e";
$eleLUT {'c3p'} = "C(<sup>3</sup>P)";
$eleLUT {'ci'} = "C<sup>+</sup> + e";
$eleLUT {'c1d'} = "C(<sup>1</sup>D)";
$eleLUT {'c1di'} = "C<sup>+</sup> + e";
$eleLUT {'c1s'} = "C(<sup>1</sup>S)";
$eleLUT {'c1si'} = "C<sup>+</sup> + e";
$eleLUT {'n'} = "N";
$eleLUT {'ni'} = "N<sup>+</sup> + e";
$eleLUT {'o3p'} = "O(<sup>3</sup>P)";
$eleLUT {'oi'} = "O<sup>+</sup> + e";
$eleLUT {'o1d'} = "O(<sup>1</sup>D)";
$eleLUT {'o1di'} = "O<sup>+</sup> + e";
$eleLUT {'o1s'} = "O(<sup>1</sup>S)";
$eleLUT {'o1si'} = "O<sup>+</sup> + e";
$eleLUT {'f'} = "F";
$eleLUT {'fi'} = "F<sup>+</sup> + e";
$eleLUT {'na'} = "Na";
$eleLUT {'nai'} = "Na<sup>+</sup> + e";
$eleLUT {'nai'} = "Na<sup>+</sup> + e";
$eleLUT {'s3p'} = "S(<sup>3</sup>P)";
$eleLUT {'s3pi'} = "S<sup>+</sup> + e";
$eleLUT {'s1d'} = "S(<sup>1</sup>D)";
$eleLUT {'s1di'} = "S<sup>+</sup> + e";
$eleLUT {'s1s'} = "S(<sup>1</sup>S)";
$eleLUT {'s1si'} = "S<sup>+</sup> + e";
$eleLUT {'cl'} = "Cl";
$eleLUT {'cli'} = "Cl<sup>+</sup> + e";
$eleLUT {'k'} = "K";
$eleLUT {'ki'} = "K<sup>+</sup> + e";
$eleLUT {'h2'} = "H<sub>2</sub>";
$eleLUT {'h1dh2'} = "H(1s) + H(2s,2p)";
$eleLUT {'hdh'} = "H(1s) + H(1s)";
$eleLUT {'h2i'} = "H<sub>2</sub><sup>+</sup> + e";
$eleLUT {'hih'} = "H<sup>+</sup> + H + e";
$eleLUT {'ch'} = "CH";
$eleLUT {'chi'} = "CH<sup>+</sup> + e";
$eleLUT {'c1sdh'} = "C(<sup>1</sup>S) + H";
$eleLUT {'c1ddh'} = "C(<sup>1</sup>D) + H";
$eleLUT {'cdh'} = "C(<sup>3</sup>P) + H";
$eleLUT {'oh'} = "OH";
$eleLUT {'o3pdh'} = "O(<sup>3</sup>P) + H";
$eleLUT {'o1sdh'} = "O(<sup>1</sup>S) + H";
$eleLUT {'ohi'} = "OH<sup>+</sup> + e";
$eleLUT {'o1ddh'} = "O(<sup>1</sup>D) + H";
$eleLUT {'o3pdh'} = "O(<sup>3</sup>P) + H";
$eleLUT {'o1sdh'} = "O(<sup>1</sup>S) + H";
$eleLUT {'ohi'} = "OH<sup>+</sup> + e";
$eleLUT {'o1ddh'} = "O(<sup>1</sup>D) + H";
$eleLUT {'hf'} = "HF";
$eleLUT {'hfi'} = "HF<sup>+</sup> + e";
$eleLUT {'hif'} = "H<sup>+</sup> + F + e";
$eleLUT {'hdf'} = "H + F";
$eleLUT {'fih'} = "F<sup>+</sup> + H + e";
$eleLUT {'cn'} = "CN";
$eleLUT {'cdn'} = "C + N";
$eleLUT {'c2'} = "C<sub>2</sub>";
$eleLUT {'c1ddc1d'} = "C(<sup>1</sup>D) + C(<sup>1</sup>D)";
$eleLUT {'c2i'} = "C<sub>2</sub><sup>+</sup> + e";
$eleLUT {'co'} = "CO(X<sub>1</sub>\$<sup>+</sup>)";
$eleLUT {'coi'} = "CO<sup>+</sup> + e";
$eleLUT {'cio'} = "C<sup>+</sup> + O + e";
$eleLUT {'oic'} = "O<sup>+</sup> + C + e";
$eleLUT {'cdo'} = "C + O";
$eleLUT {'c1ddo1d'} = "C(<sup>1</sup>D) + O(<sup>1</sup>D)";
$eleLUT {'tco'} = "CO(a<sup>3</sup>#)";
$eleLUT {'tcoi'} = "CO<sup>+</sup> + e";
$eleLUT {'tcio'} = "C<sup>+</sup> + O + e";
$eleLUT {'toic'} = "O<sup>+</sup> + C + e";
$eleLUT {'tcdo'} = "C + O";
$eleLUT {'n2'} = "N<sub>2</sub>";
$eleLUT {'ndn'} = "N + N";
$eleLUT {'nin'} = "N<sup>+</sup> + N + e";
$eleLUT {'n2i'} = "N<sub>2</sub><sup>+</sup> + e";
$eleLUT {'no'} = "NO";
$eleLUT {'noi'} = "NO<sup>+</sup> + e";
$eleLUT {'oin'} = "O<sup>+</sup> + N + e";
$eleLUT {'nio'} = "N<sup>+</sup> + O + e";
$eleLUT {'ndo'} = "N + O";
$eleLUT {'o2'} = "O<sub>2</sub>";
$eleLUT {'odo'} = "O(<sup>3</sup>P) + O(<sup>3</sup>P)";
$eleLUT {'odo1d'} = "O(<sup>3</sup>P) + O(<sup>1</sup>D)";
$eleLUT {'oio'} = "O<sup>+</sup> + O + e";
$eleLUT {'o1sdo1s'} = "O(<sup>1</sup>S) + O(<sup>1</sup>S)";
$eleLUT {'o2i'} = "O<sub>2</sub><sup>+</sup> + e";
$eleLUT {'hcl'} = "HCl";
$eleLUT {'hdcl'} = "H + Cl";
$eleLUT {'f2'} = "F<sub>2</sub>";
$eleLUT {'fdf'} = "F + F";
$eleLUT {'so'} = "SO";
$eleLUT {'sdo'} = "S + O";
$eleLUT {'soi'} = "SO<sup>+</sup> + e";
$eleLUT {'cl2'} = "Cl<sub>2</sub>";
$eleLUT {'cldcl'} = "Cl + Cl";
$eleLUT {'bro'} = "BrO";
$eleLUT {'brdo'} = "Br + O(<sup>3</sup>P)";
$eleLUT {'brdo1d'} = "Br + O(<sup>1</sup>D)";
$eleLUT {'nh2'} = "NH<sub>2</sub>";
$eleLUT {'nhdh'} = "NH + H";
$eleLUT {'h2o'} = "H<sub>2</sub>O";
$eleLUT {'hdoh'} = "H + OH";
$eleLUT {'h2do1d'} = "H<sub>2</sub> + O(<sup>1</sup>D)";
$eleLUT {'odhdh'} = "O + H + H";
$eleLUT {'ohih'} = "OH<sup>+</sup> + H + e";
$eleLUT {'oih2'} = "O<sup>+</sup> + H<sub>2</sub> + e";
$eleLUT {'hioh'} = "H<sup>+</sup> + OH + e";
$eleLUT {'h2oi'} = "H<sub>2</sub>O<sup>+</sup> + e";
$eleLUT {'hcn'} = "HCN";
$eleLUT {'hdcn(*)'} = "H + CN(A<sup>2</sup>#<sub>1</sub>)";
$eleLUT {'hcni'} = "HCN<sup>+</sup> + e";
$eleLUT {'ho2'} = "HO<sub>2</sub>";
$eleLUT {'ohdo'} = "OH + O";
$eleLUT {'h2s'} = "H<sub>2</sub>S";
$eleLUT {'hsdh'} = "HS + H";
$eleLUT {'h2si'} = "H<sub>2</sub>S<sup>+</sup> + e";
$eleLUT {'sih2'} = "S<sup>+</sup> + H<sub>2</sub> + e";
$eleLUT {'h2s'} = "H<sub>2</sub>S";
$eleLUT {'hsih'} = "HS<sup>+</sup> + H + e";
$eleLUT {'co2'} = "CO<sub>2</sub>";
$eleLUT {'codo1d'} = "CO(X<sup>1</sup>\$<sup>+</sup>) + O(<sup>1</sup>D)";
$eleLUT {'co2'} = "CO<sub>2</sub>";
$eleLUT {'co2i'} = "CO<sub>2</sub><sup>+</sup> + e";
$eleLUT {'coio'} = "CO<sup>+</sup> + O + e";
$eleLUT {'oico'} = "O<sup>+</sup> + CO + e";
$eleLUT {'cio2'} = "C<sup>+</sup> + O<sub>2</sub> + e";
$eleLUT {'codo'} = "CO(X<sup>1</sup>\$<sup>+</sup>) + O(<sup>3</sup>P)";
$eleLUT {'cotdo'} = "CO(a<sup>3</sup>#) + O(<sup>3</sup>P)";
$eleLUT {'n2o'} = "N<sub>2</sub>O";
$eleLUT {'n2do1s'} = "N<sub>2</sub>(<sup>1</sup>\$)<sup>+</sup>";
$eleLUT {'n2do1d'} = "N<sub>2</sub>(<sup>1</sup>\$) + O(<sup>1</sup>D)";
$eleLUT {'no2'} = "NO<sub>2</sub>";
$eleLUT {'no2i'} = "NO<sub>2</sub><sup>+</sup> + e";
$eleLUT {'nodod'} = "NO(X<sup>2</sup>#) + O(<sup>1</sup>D)";
$eleLUT {'nodo'} = "NO(X<sup>2</sup>#) + O(<sup>3</sup>P)";
$eleLUT {'o3'} = "O<sub>3</sub>";
$eleLUT {'odo2'} = "O(<sup>3</sup>P) + O<sub>2</sub>(<sup>3</sup>\$<sub>g</sub><sup>-</sup>)";
$eleLUT {'o1ddo2d'} = "O(<sup>1</sup>D) + O<sub>2</sub>(a<sup>1</sup>^<sub>g</sub>)";
$eleLUT {'hocl'} = "HOCl";
$eleLUT {'ohdcl'} = "OH + Cl";
$eleLUT {'ocs'} = "OCS";
$eleLUT {'ciso'} = "C<sup>+</sup> + SO + e";
$eleLUT {'oics'} = "O<sup>+</sup> + CS + e";
$eleLUT {'cois'} = "CO<sup>+</sup> + S + e";
$eleLUT {'sico'} = "S<sup>+</sup> + CO + e";
$eleLUT {'csio'} = "CS<sup>+</sup> + O + e";
$eleLUT {'cosi'} = "OCS<sup>+</sup> + e";
$eleLUT {'cods1s'} = "CO + S(<sup>1</sup>S)";
$eleLUT {'csdo'} = "CS + O(<sup>3</sup>P)";
$eleLUT {'cods1d'} = "CO + S(<sup>1</sup>D)";
$eleLUT {'csdo1d'} = "CS + O(<sup>1</sup>D)";
$eleLUT {'cods'} = "CO + S(<sup>3</sup>P)";
$eleLUT {'so2'} = "SO<sub>2</sub>";
$eleLUT {'sodo'} = "SO + O";
$eleLUT {'sdo2'} = "S + O<sub>2</sub>";
$eleLUT {'so2band'} = "SO<sub>2</sub>*";
$eleLUT {'so2i'} = "SO<sub>2</sub><sup>+</sup> + e";
$eleLUT {'clno'} = "ClNO";
$eleLUT {'cldno'} = "Cl + NO";
$eleLUT {'oclo'} = "OClO";
$eleLUT {'clodo'} = "ClO + O(<sup>3</sup>P)";
$eleLUT {'clodo1d'} = "ClO + O(<sup>1</sup>D)";
$eleLUT {'cloo'} = "ClOO";
$eleLUT {'clodo'} = "ClO + O";
$eleLUT {'cs2'} = "CS<sub>2</sub>";
$eleLUT {'cis2'} = "C<sup>+</sup> + S<sub>2</sub> + e";
$eleLUT {'sics'} = "S<sup>+</sup> + CS + e";
$eleLUT {'csis'} = "CS<sup>+</sup> + S + e";
$eleLUT {'s2ic'} = "S<sub>2</sub><sup>+</sup> + C + e";
$eleLUT {'cs2i'} = "CS<sub>2</sub><sup>+</sup> + e";
$eleLUT {'csds'} = "CS(X<sup>1</sup>\$<sup>+</sup>) + S(<sup>3</sup>P)";
$eleLUT {'csds1d'} = "CS(X<sup>1</sup>\$<sup>+</sup>) + S(<sup>1</sup>D)";
$eleLUT {'tcsds'} = "CS(a<sup>3</sup>#) + S(<sup>3</sup>P)";
$eleLUT {'a1scds'} = "CS(A<sup>1</sup>#) + S(<sup>3</sup>P)";
$eleLUT {'hobr'} = "HOBr";
$eleLUT {'ohdbr'} = "OH + Br";
$eleLUT {'hoi'} = "HOI";
$eleLUT {'ohdi'} = "OH + I";
$eleLUT {'ino'} = "INO";
$eleLUT {'idno'} = "I + NO";
$eleLUT {'nh3'} = "NH<sub>3</sub>";
$eleLUT {'nh2dh'} = "NH<sub>2</sub>(X<sup>2</sup>B<sub>1</sub>) + H";
$eleLUT {'snhdh2'} = "NH(a<sup>1</sup>^) + H<sub>2</sub>";
$eleLUT {'nhdhdh'} = "NH(X<sup>3</sup>\$<sup>-</sup>) + H + H";
$eleLUT {'nh3i'} = "NH<sub>3</sub><sup>+</sup> + e";
$eleLUT {'nh2ih'} = "NH<sub>2</sub><sup>+</sup> + H + e";
$eleLUT {'nhih2'} = "NH<sup>+</sup> + H<sub>2</sub> + e";
$eleLUT {'nih2dh'} = "N<sup>+</sup> + H<sub>2</sub> + H";
$eleLUT {'hinh2'} = "H<sup>+</sup> + NH<sub>2</sub> + e";
$eleLUT {'c2h2'} = "C<sub>2</sub>H<sub>2</sub>";
$eleLUT {'c2h2i'} = "C<sub>2</sub>H<sub>2</sub><sup>+</sup> + e";
$eleLUT {'c2hih'} = "C<sub>2</sub>H<sup>+</sup> + H + e";
$eleLUT {'c2dh2'} = "C<sub>2</sub> + H<sub>2</sub>";
$eleLUT {'c2hdh'} = "C<sub>2</sub>H + H";
$eleLUT {'c2h2**'} = "C<sub>2</sub>H<sub>2</sub>*";
$eleLUT {'h2co'} = "H<sub>2</sub>CO";
$eleLUT {'h2co'} = "H<sub>2</sub>CO";
$eleLUT {'hcodh'} = "HCO + H";
$eleLUT {'codh2'} = "CO + H<sub>2</sub>";
$eleLUT {'codhdh'} = "CO + H + H";
$eleLUT {'h2coi'} = "H<sub>2</sub>CO<sup>+</sup> + e";
$eleLUT {'hcoih'} = "HCO<sup>+</sup> + H + e";
$eleLUT {'coih2'} = "CO<sup>+</sup> + H<sub>2</sub> + e";
$eleLUT {'ph3'} = "PH<sub>3</sub>";
$eleLUT {'ph2dh'} = "PH<sub>2</sub> + H";
$eleLUT {'h2o2'} = "H<sub>2</sub>O<sub>2</sub>";
$eleLUT {'ohdoh'} = "OH + OH";
$eleLUT {'hnco'} = "HNCO";
$eleLUT {'nhdco'} = "NH(c<sup>1</sup>#) + CO";
$eleLUT {'hdnco'} = "H + NCO(A<sup>2</sup>\$)";
$eleLUT {'hono'} = "HONO";
$eleLUT {'ohdno'} = "OH + NO";
$eleLUT {'no3'} = "NO<sub>3</sub>";
$eleLUT {'no2do'} = "NO<sub>2</sub> + O";
$eleLUT {'nodo2'} = "NO + O<sub>2</sub>";
$eleLUT {'cof2'} = "COF<sub>2</sub>";
$eleLUT {'cofdf'} = "COF + F";
$eleLUT {'clno2'} = "ClNO<sub>2</sub>";
$eleLUT {'cldno2'} = "Cl + NO<sub>2</sub>";
$eleLUT {'clono'} = "ClONO";
$eleLUT {'cldno2'} = "Cl + NO<sub>2</sub>";
$eleLUT {'cofcl'} = "COFCl";
$eleLUT {'cofdcl'} = "COF + Cl";
$eleLUT {'clo3'} = "ClO<sub>3</sub>";
$eleLUT {'clo2do'} = "ClO<sub>2</sub> + O";
$eleLUT {'cocl2'} = "COCl<sub>2</sub>";
$eleLUT {'cocldcl'} = "COCl + Cl";
$eleLUT {'ch4'} = "CH<sub>4</sub>";
$eleLUT {'ch4'} = "CH<sub>4</sub>";
$eleLUT {'sch2dh2'} = "CH<sub>2</sub>(�<sup>1</sup>A<sub>1</sub>) + H<sub>2</sub>";
$eleLUT {'ch4'} = "CH<sub>4</sub>";
$eleLUT {'ch3dh'} = "CH<sub>3</sub> + H";
$eleLUT {'ch4'} = "CH<sub>4</sub>";
$eleLUT {'ch2dhdh'} = "CH<sub>2</sub> + H + H";
$eleLUT {'ch4'} = "CH<sub>4</sub>";
$eleLUT {'ch4i'} = "CH<sub>4</sub><sup>+</sup> + e";
$eleLUT {'ch4'} = "CH<sub>4</sub>";
$eleLUT {'ch3ih'} = "CH<sub>3</sub><sup>+</sup> + H + e";
$eleLUT {'ch4'} = "CH<sub>4</sub>";
$eleLUT {'ch2ih2'} = "CH<sub>2</sub><sup>+</sup> + H<sub>2</sub> + e";
$eleLUT {'ch4'} = "CH<sub>4</sub>";
$eleLUT {'chih2dh'} = "CH<sup>+</sup> + H<sub>2</sub> + H + e";
$eleLUT {'ch4'} = "CH<sub>4</sub>";
$eleLUT {'hich3'} = "H<sup>+</sup> + CH<sub>3</sub> + e";
$eleLUT {'ch4'} = "CH<sub>4</sub>";
$eleLUT {'chdh2dh'} = "CH + H<sub>2</sub> + H";
$eleLUT {'h2co2'} = "HCOOH";
$eleLUT {'h2co2'} = "HCOOH";
$eleLUT {'co2dh2'} = "CO<sub>2</sub> + H<sub>2</sub>";
$eleLUT {'h2co2'} = "HCOOH";
$eleLUT {'h2co2i'} = "H<sub>2</sub>CO<sub>2</sub><sup>+</sup> + e";
$eleLUT {'h2co2'} = "HCOOH";
$eleLUT {'hcoioh'} = "HCO<sup>+</sup> + OH + e";
$eleLUT {'h2co2'} = "HCOOH";
$eleLUT {'hcodoh'} = "HCO + OH";
$eleLUT {'ch3cl'} = "CH<sub>3</sub>Cl";
$eleLUT {'ch3dcl'} = "CH<sub>3</sub> + Cl";
$eleLUT {'hc3n'} = "HC<sub>3</sub>N";
$eleLUT {'cndc2h'} = "CN + C<sub>2</sub>H";
$eleLUT {'hno3'} = "HNO<sub>3</sub>";
$eleLUT {'ohdno2'} = "OH + NO<sub>2</sub>";
$eleLUT {'chf2cl'} = "CHF<sub>2</sub>Cl";
$eleLUT {'chf2dcl'} = "CHF<sub>2</sub> + Cl";
$eleLUT {'clono2'} = "ClONO<sub>2</sub>";
$eleLUT {'clono2'} = "ClONO<sub>2</sub>";
$eleLUT {'clonodo'} = "ClONO + O";
$eleLUT {'clono2'} = "ClONO<sub>2</sub>";
$eleLUT {'cldno3'} = "Cl + NO<sub>3</sub>";
$eleLUT {'cf2cl2'} = "CF<sub>2</sub>Cl<sub>2</sub>";
$eleLUT {'cf2cl2'} = "CF<sub>2</sub>Cl<sub>2</sub>";
$eleLUT {'cf2cldcl'} = "CF<sub>2</sub>Cl + Cl";
$eleLUT {'cf2cl2'} = "CF<sub>2</sub>Cl<sub>2</sub>";
$eleLUT {'cf2d2cl'} = "CF<sub>2</sub> + Cl + Cl";
$eleLUT {'cfcl3'} = "CFCl<sub>3</sub>";
$eleLUT {'cfcl3'} = "CFCl<sub>3</sub>";
$eleLUT {'cfcl2dcl'} = "CFCl<sub>2</sub> + Cl";
$eleLUT {'cfcl3'} = "CFCl<sub>3</sub>";
$eleLUT {'cfcld2cl'} = "CFCl + Cl + Cl";
$eleLUT {'brono2'} = "BrONO<sub>2</sub>";
$eleLUT {'brodno2'} = "BrO + NO<sub>2</sub>";
$eleLUT {'ccl4'} = "CCl<sub>4</sub>";
$eleLUT {'ccl4'} = "CCl<sub>4</sub>";
$eleLUT {'ccl3dcl'} = "CCl<sub>3</sub> + Cl";
$eleLUT {'ccl4'} = "CCl<sub>4</sub>";
$eleLUT {'ccl2d2cl'} = "CCl<sub>2</sub> + Cl + Cl";
$eleLUT {'iono2'} = "IONO<sub>2</sub>";
$eleLUT {'iodno2'} = "IO + NO<sub>2</sub>";
$eleLUT {'c2h4'} = "C<sub>2</sub>H<sub>4</sub>";
$eleLUT {'c2h4'} = "C<sub>2</sub>H<sub>4</sub>";
$eleLUT {'c2h4i'} = "C<sub>2</sub>H<sub>4</sub><sup>+</sup> + e";
$eleLUT {'c2h4'} = "C<sub>2</sub>H<sub>4</sub>";
$eleLUT {'c2h2ih2'} = "C<sub>2</sub>H<sub>2</sub><sup>+</sup> + H<sub>2</sub> + e";
$eleLUT {'c2h4'} = "C<sub>2</sub>H<sub>4</sub>";
$eleLUT {'c2h3ih'} = "C<sub>2</sub>H<sub>3</sub><sup>+</sup> + H + e";
$eleLUT {'c2h4'} = "C<sub>2</sub>H<sub>4</sub>";
$eleLUT {'c2h2d2h'} = "C<sub>2</sub>H<sub>2</sub> + H + H";
$eleLUT {'c2h2dh2'} = "C<sub>2</sub>H<sub>2</sub> + H<sub>2</sub>";
$eleLUT {'ch3oh'} = "CH<sub>3</sub>OH";
$eleLUT {'ch3oh'} = "CH<sub>3</sub>OH";
$eleLUT {'ch3doh'} = "CH<sub>3</sub> + OH";
$eleLUT {'ch3oh'} = "CH<sub>3</sub>OH";
$eleLUT {'ch3ohi'} = "CH<sub>3</sub>OH<sup>+</sup> + e";
$eleLUT {'ch3oh'} = "CH<sub>3</sub>OH";
$eleLUT {'ch3oih'} = "CH<sub>3</sub>O<sup>+</sup> + H + e";
$eleLUT {'ch3oh'} = "CH<sub>3</sub>OH";
$eleLUT {'h2coih2'} = "H<sub>2</sub>CO<sup>+</sup> + H<sub>2</sub> + e";
$eleLUT {'ch3oh'} = "CH<sub>3</sub>OH";
$eleLUT {'h2codh2'} = "H<sub>2</sub>CO + H<sub>2</sub>";
$eleLUT {'ho2no2'} = "HO<sub>2</sub>NO<sub>2</sub>";
$eleLUT {'ho2no2'} = "HO<sub>2</sub>NO<sub>2</sub>";
$eleLUT {'hodno3'} = "OH + NO<sub>3</sub>";
$eleLUT {'ho2no2'} = "HO<sub>2</sub>NO<sub>2</sub>";
$eleLUT {'ho2dno2'} = "HO<sub>2</sub> + NO<sub>2</sub>";
$eleLUT {'ch3cho'} = "CH<sub>3</sub>CHO";
$eleLUT {'ch3cho'} = "CH<sub>3</sub>CHO";
$eleLUT {'ch4dco'} = "CH<sub>4</sub> + CO";
$eleLUT {'ch3cho'} = "CH<sub>3</sub>CHO";
$eleLUT {'ch3dhco'} = "CH<sub>3</sub> + HCO";
$eleLUT {'ch3cho'} = "CH<sub>3</sub>CHO";
$eleLUT {'tch3cho'} = "<sup>3</sup>CH<sub>3</sub>CHO";
$eleLUT {'ch3ooh'} = "CH<sub>3</sub>CHO";
$eleLUT {'ch3odoh'} = "CH<sub>3</sub>O + OH";
$eleLUT {'n2o5'} = "N<sub>2</sub>O<sub>5</sub>";
$eleLUT {'2no2do'} = "NO<sub>2</sub> + NO<sub>2</sub> + O";
$eleLUT {'c2h6'} = "C<sub>2</sub>H<sub>6</sub>";
$eleLUT {'c2h6'} = "C<sub>2</sub>H<sub>6</sub>";
$eleLUT {'ch3dch3'} = "CH<sub>3</sub> + CH<sub>3</sub>";
$eleLUT {'c2h6'} = "C<sub>2</sub>H<sub>6</sub>";
$eleLUT {'c2h5dh'} = "C<sub>2</sub>H<sub>5</sub> + H";
$eleLUT {'c2h6'} = "C<sub>2</sub>H<sub>6</sub>";
$eleLUT {'1ch2dch4'} = "<sup>1</sup>CH<sub>2</sub> + CH<sub>4</sub>";
$eleLUT {'c2h6'} = "C<sub>2</sub>H<sub>6</sub>";
$eleLUT {'c2h6i'} = "C<sub>2</sub>H<sub>6</sub><sup>+</sup> + e";
$eleLUT {'c2h6'} = "C<sub>2</sub>H<sub>6</sub>";
$eleLUT {'c2h4dh2'} = "C<sub>2</sub>H<sub>4</sub> + H<sub>2</sub>";
$eleLUT {'ch3ccl3'} = "CH<sub>3</sub>CCl<sub>3</sub>";
$eleLUT {'..cl2dcl'} = "CH<sub>3</sub>CCl<sub>2</sub> + Cl";
$eleLUT {'ch3o2no2'} = "CH<sub>3</sub>O<sub>2</sub>NO<sub>2</sub>";
$eleLUT {'ch3o2no2'} = "CH<sub>3</sub>O<sub>2</sub>NO<sub>2</sub>";
$eleLUT {'..o2dno2'} = "CH<sub>3</sub>O<sub>2</sub> + NO<sub>2</sub>";
$eleLUT {'ch3o2no2'} = "CH<sub>3</sub>O<sub>2</sub>NO<sub>2</sub>";
$eleLUT {'ch3odno3'} = "CH<sub>3</sub>O + NO<sub>3</sub>";
$eleLUT {'ch3ssch3'} = "CH<sub>3</sub>SSCH<sub>3</sub>";
$eleLUT {'ch3ssch3'} = "CH<sub>3</sub>SSCH<sub>3</sub>";
$eleLUT {'mssdm'} = "CH<sub>3</sub>SS + CH<sub>3</sub>";
$eleLUT {'ch3ssch3'} = "CH<sub>3</sub>SSCH<sub>3</sub>";
$eleLUT {'2(ch3s)'} = "CH<sub>3</sub>S + CH<sub>3</sub>S";
$eleLUT {'ch3cno5'} = "CH<sub>3</sub>CO<sub>3</sub>NO<sub>2</sub>";
$eleLUT {'ch3cno5'} = "CH<sub>3</sub>CO<sub>3</sub>NO<sub>2</sub>";
$eleLUT {'mco3dno2'} = "CH<sub>3</sub>CO<sub>3</sub> + NO<sub>2</sub>";
$eleLUT {'ch3cno5'} = "CH<sub>3</sub>CO<sub>3</sub>NO<sub>2</sub>";
$eleLUT {'mco2dno3'} = "CH<sub>3</sub>CO<sub>2</sub> + NO<sub>3</sub>";

sub ConvertCanonicalBranchName {

    local ($branch) = $_ [0];

    return $eleLUT {$branch};
}

