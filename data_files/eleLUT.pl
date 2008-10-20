#!/opt/local/bin/perl -w

$eleLUT {'H'} = "H";
$eleLUT {'H-'} = "H<sup>-</sup>";
$eleLUT {'He'} = "He";
$eleLUT {'He+'} = "He<sup>+</sup>";
$eleLUT {'Li'} = "Li";
$eleLUT {'Li+'} = "Li<sup>+</sup>";
$eleLUT {'Be'} = "Be";
$eleLUT {'Be+'} = "Be<sup>+</sup>";
$eleLUT {'B'} = "B";
$eleLUT {'B+'} = "B<sup>+</sup>";
$eleLUT {'C'} = "C(<sup>3</sup>P)";
$eleLUT {'C(^1D)'} = "C(<sup>1</sup>D)";
$eleLUT {'C(^1S)'} = "C(<sup>1</sup>S)";
$eleLUT {'C+'} = "C<sup>+</sup>";
$eleLUT {'N'} = "N";
$eleLUT {'N+'} = "N<sup>+</sup>";
$eleLUT {'O'} = "O(<sup>3</sup>P)";
$eleLUT {'O(^1D)'} = "O(<sup>1</sup>D)";
$eleLUT {'O(^1S)'} = "O(<sup>1</sup>S)";
$eleLUT {'O+'} = "O<sup>+</sup>";
$eleLUT {'F'} = "F";
$eleLUT {'F+'} = "F<sup>+</sup>";
$eleLUT {'Ne'} = "Ne";
$eleLUT {'Ne+'} = "Ne<sup>+</sup>";
$eleLUT {'Nae'} = "Na (exp.)";
$eleLUT {'Nat'} = "Na (theor.)";
$eleLUT {'Na+'} = "Na<sup>+</sup>";
$eleLUT {'Mg'} = "Mg";
$eleLUT {'Mg+'} = "Mg<sup>+</sup>";
$eleLUT {'Al'} = "Al";
$eleLUT {'Al+'} = "Al<sup>+</sup>";
$eleLUT {'Si'} = "Si";
$eleLUT {'Si+'} = "Si<sup>+</sup>";
$eleLUT {'P'} = "P";
$eleLUT {'P+'} = "P<sup>+</sup>";
$eleLUT {'S'} = "S(<sup>3</sup>P)";
$eleLUT {'S(^1D)'} = "S(<sup>1</sup>D)";
$eleLUT {'S(^1S)'} = "S(<sup>1</sup>S)";
$eleLUT {'S+'} = "S<sup>+</sup>";
$eleLUT {'Cl'} = "Cl";
$eleLUT {'Cl+'} = "Cl<sup>+</sup>";
$eleLUT {'Ar'} = "Ar";
$eleLUT {'Ar+'} = "Ar<sup>+</sup>";
$eleLUT {'K'} = "K";
$eleLUT {'K+'} = "K<sup>+</sup>";
$eleLUT {'Ca'} = "Ca";
$eleLUT {'Ca+'} = "Ca<sup>+</sup>";
$eleLUT {'Sc'} = "Sc";
$eleLUT {'Sc+'} = "Sc<sup>+</sup>";
$eleLUT {'Ti'} = "Ti";
$eleLUT {'Ti+'} = "Ti<sup>+</sup>";
$eleLUT {'V'} = "V";
$eleLUT {'V+'} = "V<sup>+</sup>";
$eleLUT {'Cr'} = "Cr";
$eleLUT {'Cr+'} = "Cr<sup>+</sup>";
$eleLUT {'Mn'} = "Mn";
$eleLUT {'Mn+'} = "Mn<sup>+</sup>";
$eleLUT {'Fe'} = "Fe";
$eleLUT {'Fe+'} = "Fe<sup>+</sup>";
$eleLUT {'Co'} = "Co";
$eleLUT {'Co+'} = "Co<sup>+</sup>";
$eleLUT {'Ni'} = "Ni";
$eleLUT {'Ni+'} = "Ni<sup>+</sup>";
$eleLUT {'Cu'} = "Cu";
$eleLUT {'Cu+'} = "Cu<sup>+</sup>";
$eleLUT {'Zn'} = "Zn";
$eleLUT {'Zn+'} = "Zn<sup>+</sup>";
$eleLUT {'Xe'} = "Xe";
$eleLUT {'H2'} = "H<sub>2</sub>";
$eleLUT {'CH'} = "CH";
$eleLUT {'OHe'} = "OH (exp.)";
$eleLUT {'OHt'} = "OH (theor.)";
$eleLUT {'HF'} = "HF";
$eleLUT {'CN'} = "CN";
$eleLUT {'C2'} = "C<sub>2</sub>";
$eleLUT {'CO'} = "CO";
$eleLUT {'^3CO'} = "CO(a^3Pi)";
$eleLUT {'N2'} = "N<sub>2</sub>";
$eleLUT {'NO'} = "NO";
$eleLUT {'O2'} = "O(<sub>2</sub>)";
$eleLUT {'HCl'} = "HCl";
$eleLUT {'F2'} = "F<sub>2</sub>";
$eleLUT {'SO'} = "SO";
$eleLUT {'Cl2'} = "Cl<sub>2</sub>";
$eleLUT {'BrO'} = "BrO";
$eleLUT {'NH3'} = "NH<sub>3</sub>";
$eleLUT {'H2O'} = "H<sub>2</sub>O";
$eleLUT {'HCN'} = "HCN";
$eleLUT {'ohdo'} = "OH + O";
$eleLUT {'H2S'} = "H<sub>2</sub>S";
$eleLUT {'CO2'} = "CO<sub>2</sub>";
$eleLUT {'n2do1s'} = "N2(<sup>1</sup>\$)+";
$eleLUT {'n2do1d'} = "N2(<sup>1</sup>\$) + O(<sup>1</sup>D)";
$eleLUT {'NO2'} = "NO(<sub>2</sub>)";
$eleLUT {'O3'} = "O(<sub>3</sub>P)";
$eleLUT {'ohdcl'} = "OH + Cl";
$eleLUT {'OCS'} = "OCS";
$eleLUT {'SO2'} = "SO<sub>2</sub>";
$eleLUT {'cldno'} = "Cl + NO";
$eleLUT {'clodo'} = "ClO + O(<sup>3</sup>P)";
$eleLUT {'clodo1d'} = "ClO + O(<sup>1</sup>D)";
$eleLUT {'clodo'} = "ClO + O";
$eleLUT {'CS2'} = "CS<sub>2</sub>";
$eleLUT {'ohdbr'} = "OH + Br";
$eleLUT {'ohdI'} = "OH + I";
$eleLUT {'Idno'} = "I + NO";
$eleLUT {'nh2dh'} = "H<sub>2</sub>(XB<sub>1</sub>) + H";
$eleLUT {'snhdh2'} = "NH(a<sup>1</sup>^) + H2";
$eleLUT {'nhdhdh'} = "NH(X<sup>3</sup>\$-) + H + H";
$eleLUT {'nh3i'} = "H<sub>3</sub>+";
$eleLUT {'nh2ih'} = "H<sub>2</sub>+ + H";
$eleLUT {'nhih2'} = "NH+ + H2";
$eleLUT {'nih2dh'} = "N+ + H2 + H";
$eleLUT {'hinh2'} = "H+ + H<sub>2</sub>";
$eleLUT {'c2h2i'} = "CH<sub>2</sub>+";
$eleLUT {'c2hih'} = "C2H+ + H";
$eleLUT {'c2dh2'} = "C2 + H2";
$eleLUT {'c2hdh'} = "C2H + H";
$eleLUT {'c2h2**'} = "CH<sub>2</sub>*";
$eleLUT {'hcodh'} = "HCO + H";
$eleLUT {'codh2'} = "CO + H2";
$eleLUT {'codhdh'} = "CO + H + H";
$eleLUT {'h2coi'} = "H2CO+";
$eleLUT {'hcoih'} = "HCO+ + H";
$eleLUT {'coih2'} = "CO+ + H2";
$eleLUT {'ph2dh'} = "H<sub>2</sub> + H";
$eleLUT {'ohdoh'} = "OH + OH";
$eleLUT {'nhdco'} = "NH(c1#) + CO";
$eleLUT {'hdnco'} = "H + NCO(A<sup>2</sup>\$)";
$eleLUT {'ohdno'} = "OH + NO";
$eleLUT {'no2do'} = "O<sub>2</sub> + O";
$eleLUT {'nodo2'} = "NO + O2";
$eleLUT {'cofdf'} = "COF + F";
$eleLUT {'cldno2'} = "Cl + O<sub>2</sub>";
$eleLUT {'cldno2'} = "Cl + O<sub>2</sub>";
$eleLUT {'cofdcl'} = "COF + Cl";
$eleLUT {'clo2do'} = "CO<sub>2</sub> + O";
$eleLUT {'cocldcl'} = "COCl + Cl";
$eleLUT {'sch2dh2'} = "H<sub>2</sub>(�A<sub>1</sub>) + H2";
$eleLUT {'ch3dh'} = "H<sub>3</sub> + H";
$eleLUT {'ch2dhdh'} = "H<sub>2</sub> + H + H";
$eleLUT {'ch4'} = "CH<sub>4</sub>";
$eleLUT {'CH4+'} = "CH<sub>4</sub><sup>+</sup>";
$eleLUT {'CH3+H'} = "CH<sub>3</sub><sup>+</sup> + H";
$eleLUT {'CH2+H2'} = "CH<sub>2</sub><sup>+</sup> + H2";
$eleLUT {'CH+H2/H'} = "CH<sup>+</sup> + H2 + H";
$eleLUT {'H+CH3'} = "H<sup>+</sup> + CH<sub>3</sub>";
$eleLUT {'CH/H2/H'} = "CH + H<sub>2</sub> + H";
$eleLUT {'^1CH2/H2'} = "<sup>1</sup>CH + H<sub>2</sub> + H";
$eleLUT {'co2dh2'} = "O<sub>2</sub> + H2";
$eleLUT {'h2co2i'} = "H2O<sub>2</sub>+";
$eleLUT {'hcoioh'} = "HCO+ + OH";
$eleLUT {'hcodoh'} = "HCO + OH";
$eleLUT {'ch3dcl'} = "H<sub>3</sub> + Cl";
$eleLUT {'cndc2h'} = "CN + C2H";
$eleLUT {'ohdno2'} = "OH + O<sub>2</sub>";
$eleLUT {'chf2dcl'} = "CF<sub>2</sub> + Cl";
$eleLUT {'clonodo'} = "ClONO + O";
$eleLUT {'cldno3'} = "Cl + O<sub>3</sub>";
$eleLUT {'cf2cldcl'} = "F<sub>2</sub>Cl + Cl";
$eleLUT {'cf2d2cl'} = "F<sub>2</sub> + Cl + Cl";
$eleLUT {'cfcl2dcl'} = "CCl<sub>2</sub> + Cl";
$eleLUT {'cfcld2cl'} = "CFCl + Cl + Cl";
$eleLUT {'brodno2'} = "BrO + O<sub>2</sub>";
$eleLUT {'ccl3dcl'} = "Cl<sub>3</sub> + Cl";
$eleLUT {'ccl2d2cl'} = "Cl<sub>2</sub> + Cl + Cl";
$eleLUT {'Iodno2'} = "IO + O<sub>2</sub>";
$eleLUT {'c2h4i'} = "CH<sub>4</sub>+";
$eleLUT {'c2h2ih2'} = "CH<sub>2</sub>+ + H2";
$eleLUT {'c2h3ih'} = "CH<sub>3</sub>+ + H";
$eleLUT {'c2h2d2h'} = "CH<sub>2</sub> + H2";
$eleLUT {'ch3doh'} = "H<sub>3</sub> + OH";
$eleLUT {'ch3ohi'} = "H<sub>3</sub>OH+";
$eleLUT {'ch3oih'} = "H<sub>3</sub>O+ + H";
$eleLUT {'h2coih2'} = "H2CO+ + H2";
$eleLUT {'h2codh2'} = "H2CO + H2";
$eleLUT {'hodno3'} = "OH + O<sub>3</sub>";
$eleLUT {'ho2dno2'} = "O<sub>2</sub> + O<sub>2</sub>";
$eleLUT {'ch4dco'} = "H<sub>4</sub> + CO";
$eleLUT {'ch3dhco'} = "H<sub>3</sub> + HCO";
$eleLUT {'tch3cho'} = "(<sub>3</sub>)H<sub>3</sub>CHO";
$eleLUT {'ch3odoh'} = "H<sub>3</sub>O + OH";
$eleLUT {'2no2do'} = "O<sub>2</sub> + O<sub>2</sub> + O";
$eleLUT {'ch3dch3'} = "H<sub>3</sub> + H<sub>3</sub>";
$eleLUT {'c2h5dh'} = "CH<sub>5</sub> + H";
$eleLUT {'(1)ch2dch4'} = "1H<sub>2</sub> + H<sub>4</sub>";
$eleLUT {'c2h6i'} = "CH<sub>6</sub>+";
$eleLUT {'c2h4dh2'} = "CH<sub>4</sub> + H2";
$eleLUT {'..cl2dcl'} = "H<sub>3</sub>Cl<sub>2</sub> + Cl";
$eleLUT {'..o2dno2'} = "H<sub>3</sub>O2 + O<sub>2</sub>";
$eleLUT {'ch3odno3'} = "H<sub>3</sub>O + O<sub>3</sub>";
$eleLUT {'mssdm'} = "H<sub>3</sub>SS + H<sub>3</sub>";
$eleLUT {'2(ch3s)'} = "H<sub>3</sub>S + H<sub>3</sub>S";
$eleLUT {'mco3dno2'} = "H<sub>3</sub>O<sub>3</sub> + O<sub>2</sub>";
$eleLUT {'mco2dno3'} = "H<sub>3</sub>O<sub>2</sub> + O<sub>3</sub>";

sub ConvertCanonicalBranchName {
    local ($branch) = $_ [0];
    return $eleLUT {$branch};
}
