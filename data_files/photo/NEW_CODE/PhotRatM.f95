Module PhotRatM
implicit none
public :: BlackB, Branch, FotRat, Convert
contains
!
Subroutine BlackB
!
! This program calculates the number of photons emitted per unit area per unit time per unit 
! wavelength for a blackbody (BB).  From this it calculates the number of photons in each wavelength 
! bin per unit area.  NBB_lambda = 2*pi*c/[lambda**4*[e**[h*c/[(k*lambda*T)] - 1].
! Then it calculates the BB rate coefficients.  BBGrid is based on solar flux grid, except one grid 
! point is inserted where the BB function is near its maximum for various temperatures.  A few 
! addditionalg rid points have been added at long wavelengths.
! 
! Physical constants:
! Avogadro constant N_0 = 6.0221415d+23 atoms/(g-mol)
! Boltzmann constant k_B = 1.3806505d-23 J/K
! Planck constant h = 6.6260755d-34 J s 
! speed of light c = 2.99792458d+08 m/s
!
! Mathematical constants:
! e = 2.718281828459045d+00
! pi = 3.141592653589793d+00
!
! lambda is the photon wavelength in Angstrom (1 A = 1.E-10 m). 
! T is the blackbody temperature in K.
!
integer, parameter :: LimA = 50000, LimB = 2000, nmax = 300, GrPtLim = 400
integer :: i, j, nF, iGrPt, nGrPts, Deltan
real (kind = 8), parameter :: e = 2.71828183, k_B = 1.3806505d-23, & 
  h = 6.6260755d-34, c = 2.99792458d+08, pi = 3.141592653589793d+00 
real (kind = 8) :: Angstc, T, c1, c2, NBB1, NBB2, RFmax
real (kind = 8), dimension(LimB + 1) :: XSctPl, RatePl, AngPlt, PhotFlx
real (kind = 8), dimension(LimA + 1) :: Angsts, AngPl, Sigpl
real (kind = 8), dimension(GrPtLim) :: BBGrid
character (len = 8), dimension(2) :: Name
character (len = 8) :: NamPr, RadField
common Name, nF, RadField, T

open(unit = 3, file = "Output", status = "unknown")   !! RatOut = Binned rate coefficient per Angstrom.
open(unit = 7, file = "BaseGrid.dat", status = "old") ! Solar grid plus a few additional wavelength points.
open(unit = 12, file = "BBFlux.dat", status = "unknown") ! BB photon flux in wavelength bin.

nGrPts = 337
if(nGrPts > GrPtLim) then
  write(unit = *, fmt = *) " *** Increase GrPtLim. ***"
else
end if
do
  write(unit = *, fmt = *) "Enter blackbody temperature {f7.0) in K; T minimum = 50. K."
  read(unit = *, fmt = "(f7.0)") T
  if(T >= 50.) then
    write(unit = *, fmt = "(a4, f9.0, a2)") " T =", T, " K"
    exit
  else
    write(unit = *, fmt = *) "Entered T =", T, "K, but should be larger than 50. K"
  end if
end do

c1 = 2*pi*c   ! 1.8836516e+09 m/s
c2 = h*c/k_B  ! 1.4387765e-02/T m
! wavelength at which spectral exitance is a maximum:  Angstc = 2.8978e-03/T [m].
read(unit = 7, fmt = "(f10.2)") (BBGrid(i), i = 1, nGrPts) ! Basic wavelength grid for BB wavelength 
                                                           ! grid.
close(unit = 7)
iGrPt = 1
NBB1 = 0.  ! Number of photons emitted per unit area per unit wavelength at lower wavelength 
           ! of first bin.
nF = 2
!PhotFlx(nF - 1) = 0.
PhotFlx(nF - 1) = BBGrid(iGrPt)      ! Lower wavelength of a bin
PhotFlx(nF + 1) = BBGrid(iGrPt + 1)  ! Upper wavelength of a bin
do
  if(c2/(PhotFlx(nF + 1)*1.d-10*T) < 700.) then  ! Avoid overflow of the exponent.
!    write(unit = *, fmt = *) " iGrPt =", iGrPt, " BBGrid =", BBGrid(iGrPt), " nF =", nF, " PhotFlx(nF + 1) =", PhotFlx(nF + 1)
!    write(unit = *, fmt = *) " numer =", c1*(PhotFlx(nF + 1)*1.d-10)**(-5.d+00), &
!      " denom =", dexp(c2/(PhotFlx(nF + 1)*1.d-10)*T) - 1.d+00
    NBB2 = c1*1.d-04/((PhotFlx(nF + 1)*1.d-10)**(4.d+00)*(dexp(c2/(PhotFlx(nF + 1)*1.d-10*T)) - 1.d+00))
!   Number of photons per cm^2 and per Angstrom at a wavelength grid point.
!   The factor 1.d-10 converts the wavwlength from m to Angstrom (A).    
!   The factor 1.d-04 converts the area from m^2 to cm^2.    
!    PF2 = NBB2*PhotFlx(nF + 1)*1.d-10/(c*h)
!   Number of photons per cm^2 in bin = width of wavelength bin * average number of photons at lower 
!   and upper wavelength of bin.
    PhotFlx(nF) = (NBB1 + NBB2)*(PhotFlx(nF + 1) - PhotFlx(nF - 1))*1.d-10/2.
!    if(nF == 456) then
!    end if
    write(unit = 12, fmt = "(f10.2, 1pe10.2)") PhotFlx(nF - 1), PhotFlx(nF) ! BBFlux.dat
  else
    write(unit = 12, fmt = "(f10.2, 1pe10.2)") PhotFlx(nF - 1), 0.0
  end if
  iGrpt = iGrPt + 1
  nF = nF + 2
  PhotFlx(nF + 1) = BBGrid(iGrPt + 1)
  if(iGrPt == nGrPts) then
    write(unit = 12, fmt = "(f10.2)") PhotFlx(nF - 1) ! Wavelength of last bin in Angstrom.
    nF = nF/2 - 1
    exit
  else
    NBB1 = NBB2
  end if
end do
! ***
close(unit = 12)
! ***
return
end Subroutine BlackB

! *****************************************************************************

Subroutine Branch(iEnd)
!
! This subroutine apportions cross sections for each branch.
!
logical Limit
integer, parameter :: LimA = 50000, LimB = 2000
integer :: i, iEnd, IOS1, iT, j, m, n1, n2, n3, nB, nDum, nS, nSets
integer, dimension(16) :: Num, iFlg, Kat
character (len = 3) :: Aster, Ast3
character (len = 8) :: LastN
character (len = 8), dimension(2)  :: Mother, IPROD
character (len = 8), dimension(10) :: Text
character (len = 8), dimension(16) :: Nam
character (len = 24) :: FMT1
character (len = 39) :: FMT2
real (kind = 8) :: Ang1, AngL, Angsti, Angst1, AngstL, AngstB1, AngstBL, Dum, ttemp
real (kind = 8), dimension(16) :: Thrsh
real (kind = 8), dimension(LimA + 1) :: Angsts
real (kind = 8), dimension(LimA) :: Sigma, BrPr, Tot
real (kind = 8), dimension(LimA) :: AngstB, Br
real (kind = 8), dimension(LimA, 16) :: TabBrP, TabSig
FMT1 = "((a14, 2x, 00 (1x, a8)))"
FMT2 = "((0pf7.1, 1x, 1pe8.2, 00 (1x, 1pe8.2)))"
!common /A/ Nam, Num, Kat, iFlg, Thrsh, nSets
!
! Initialize Subroutine.
!
Ast3 = "***"
Limit = .False.
m = 0
do i = 1, 16
  iFlg(i) = 0
end do
do i = 1, LimA
!  Tot(i) = 0
  Tot(i) = 0.
  do j = 1, 16
!    TabBrP(i, j) = 0
    TabBrP(i, j) = 0.
!    TabSig(i, j) = 0
    TabSig(i, j) = 0.
  end do
end do
!
! Read mother molecule information.
!
read(unit = 1, fmt = "(i10, 2f10.2, 2(1x, a8), 2i3)", iostat = IOS1) nS, &
  Angst1, AngstL, (Mother(i), i = 1, 2), Num(1), Kat(1)    ! Unit 1 is HREC
if(IOS1 < 0) then
  write(unit = *, fmt = *) "End of HRec file:", IOS1
  iEnd = 1
  return
else if(IOS1 > 0) then
  write(unit = *, fmt = *) "HRec input error:", IOS1
  stop
else
end if
if(Num(1) /= 0) then
  Nam(1) = Mother(2)
else
end if
Thrsh(1) = AngstL
write(unit = 2, fmt = "(a43, a8, 2x, a8)") "0          References for Cross Section of ", &
  (Mother(i), i = 1, 2)
do
  read(unit = 1, fmt = "(10 a8)") (Text(i), i=1, 10)  ! Read references for mother molecule.
  write(unit = 2, fmt = "(10 a8)") (Text(i), i=1, 10)
  if(Text(1) == Text(2) .or. Text(2) == "        ") then
    exit
  else
  endif
end do
!
! Read wavelengths and cross sections for the mother molecule.
!
read(unit = 1, fmt = "(0pf10.2, 1pe10.2)") (Angsts(i), Sigma(i), i = 1, nS)
!
! Read the number of branching sets that follow.
!
read(unit = 1, fmt = "(i3)") nSets
Nam(nSets + 2) = Mother(1)
Num(nSets + 2) = 0
Kat(nSets + 2) = 0
iFlg(nSets + 2) = 1
!
! If there are no branching sets, i.e., nSets = 0, skip to 130.
!
if(nSets /= 0) then     ! This goes to end of "if"
  it = nSets + 1
!
! Write the total number of branches (nSets + 1).
!
  write(unit = 4, fmt = "(i3)") it     ! Temporary file for wavelengths & cross sections.
!
! Read information for a branching set.
!
  do
    read(unit = 1, fmt = "(i10, 2 f10.2, 2 (1x, a8), 2 i3)") nB, AngstB1, &
         AngstBL, (iProd(i), i = 1, 2), Num(m + 1), Kat(m + 1)
    Thrsh(m + 1) = AngstBL
    m = m + 1
    Nam(m) = IProd(2)
    write(unit = 2, fmt = "(a43, a8, 2x, a8)") "0          References for Cross Section of ", &
         (iProd(i), i = 1, 2)
    do
      read(unit = 1, fmt = "(10 a8)") (Text(i), i = 1, 10)  ! Read references for a branching set.
      write(unit = 2, fmt = "(10 a8)") (Text(i), i = 1, 10)
      if(Text(1) == Text(2) .or. Text(2) == "        ") then
        exit
      else
      end if
    end do  
!
! Set Ang1 = Max(Angst1, AngstB1) and AngL = Min(AngstL, AngstBL).
!
    Ang1 = Angst1
    AngL = AngstL
    if(AngstB1 > Ang1) then
      Ang1 = AngstB1
    else
    end if
    if(AngstBL < AngL) then
      AngL = AngstBL
    else
    end if
!
! Read pairs of wavelengths and sigmas for branching set.
!
    read(unit = 1, fmt = "(0pf10.2, 1pe10.2)") (AngstB(i), Br(i), i = 1, nB)
    j = 1
!
! For each wavelength of the mother species calculate a new cross section (Sigma) for each branch.
!
    do i = 1, nS
      Angsti = Angsts(i)
      do
        if(Angsti > AngstB(j + 1) .and. .not. Limit) then  ! This goes to end of "if" 
        else
          if(Angsti == AngstB(j + 1)) then
            BrPr(i) = Br(j + 1)
          end if
          if(Angsti /= AngstB(j + 1)) then
            BrPr(i) = Br(J) + (Br(j + 1) - Br(j))*((Angsti - AngstB(j)) &
              /(AngstB(j + 1) - AngstB(j)))
          end if
          if(Limit) then
            BrPr(I) = 0.
          end if
          Tot(i) = Tot(i) + BrPr(i)
          TabSig(i, m) = BrPr(i)*Sigma(i)
          TabBrP(i, m) = BrPr(i)
          exit
!
! Find the smallest wavelength of the branching set that is greater than the 
! wavelength of the mother species.
!
        end if
        j = j + 1
!
! Check if the limit has been reached.
!
        if(j + 1 >= nB .and. Angsti > AngstB(nB)) then
          Limit = .True.
        end if
      end do
    end do
! Write temporary file for wavelengths & cross sections.
    write(unit = 4, fmt = "(i10, 2 f10.2, a8, 2 x, a8)") nS, Ang1, AngL, Mother(1), IProd(2)
    write(unit = 4, fmt = "(0pf10.2, 1pe10.2)") (Angsts(i), TabSig(i, m), i = 1, nS)
!
! If there are more branching sets, then loop back and do it again.
!
    if(m == nSets) then
      exit
    else
    end if
  end do
  nSets = nSets + 1
  read(unit = 1, fmt = "(i10, 2 f10.2, 2 (1x, a8), 2 i3)") nDum, Dum, &
       Thrsh(nSets), iProd(1), LastN, Num(nSets), Kat(nSets)
  Nam(nSets) = LastN
!
! nSets + 1 is the total number of branches.  Calculcate the final branch here.
!
  do i = 1, ns
    ttemp = 1. - Tot(i)
    if(ttemp < 0.) then
      write(unit = *, fmt = *) Mother(1), ", ttemp < 0.: ", ttemp, " around wavelength: ", Angsts(i)
      TabBrP(i, nSets) = 0.
      ttemp = 0.0
    else
      TabBrP(i, nSets) = ttemp
    end if
    TabSig(i, nSets) = TabBrP(i, nSets)*Sigma(i)
  end do
! Write temporary file for wavelengths & cross sections.
  write(unit = 4, fmt = "(i10, 2 f10.2, a8, 2x, a8)") ns, Angst1, AngstL, Mother(1), LastN
  write(unit = 4, fmt = "(0pf10.2, 1pe10.2)") (Angsts(i), TabSig(i, nSets), i=1, ns)
!
! If there are no Branching Sets, the Mother Molecule is the Only "Branch."
!
else
! Write temporary file for wavelengths & cross sections.
  write(unit = 4, fmt = "(i3)") nSets
  write(unit = 4, fmt = "(i10, 2 f10.2, a8, 2x, a8)") nS, Angst1, AngstL, (Mother(i), i = 1, 2)
  write(unit = 4, fmt = "(0pf10.2, 1pe10.2)") (Angsts(i), Sigma(i), i = 1, nS)
end if
do
  read(unit = 1, fmt = "(a3)") Aster
  if(Aster == Ast3) then
    exit
  else
  end if
end do
  n1 = nSets
  n2 = 1
  n3 = nSets
  if(n1 < 10) then
    FMT1(13:13) = CHAR(n1 + 48)
    FMT1(12:12) = CHAR(48)
    FMT2(24:24) = CHAR(n1 + 48)
    FMT2(23:23) = CHAR(48)
  else
    FMT1(13:13) = CHAR(n1 + 38)
    FMT1(12:12) = CHAR(n1/10 + 48)
    FMT2(24:24) = CHAR(n1 + 38)
    FMT2(23:23) = CHAR(n1/10 + 48)
  end if
  write(unit = 2, fmt = "(a21, (2 (1x, a8)), 4x, i2, a9)") &
    "0 Branching ratio for", (Mother(j), j = 1, 2), nSets, " branches"
  if(nSets > 0) then
    write(unit = 2, fmt = FMT1) " Lambda  Total", (Nam(i), i = n2, n3)
    write(unit = 2, fmt = FMT2) (Angsts(i), Sigma(i), (TabSig(i, j), j = n2, n3),&
      i = 1, ns)
  else
    write(unit = 2, fmt = "(a8, 2x, a8)") "  Lambda", Mother(2)
    write(unit = 2, fmt = "(0pf8.2, 1x, 1pe9.2)") (Angsts(i), &
      Sigma(i), i = 1, nS)
  end if
return
end Subroutine Branch

! *****************************************************************************

Subroutine FotRat(iFirst)
!
! This subroutine computes photo rate coefficients in s^(-1)
!
integer, parameter :: nAS = 162, LimA = 50000, LimB = 2000, LimF = 1000! !, nF = 324
integer :: i, ij, i1, iL, idxAxs, idyAxs, iFirst, IOS4, iPrnt, j, jL, jLm1, k, last, &
           m2, m3, m4, maxN, maxPr, minPr, n, n1, nL, nPlot, nS, nSets, nF
real (kind = 8) :: aLast, Angst1, AngstL, SA, x1, x2
real (kind = 8) :: T
real (kind = 8), dimension(16) :: Rate
real (kind = 8), dimension(nAS) :: FlxRat         ! Flux ratio of active/quiet Sun
real (kind = 8), dimension(nAS*2) :: FlxRatPl
real (kind = 8), dimension(LimA) :: Sigma
real (kind = 8), dimension(LimA + 1) :: Angsts, AngPl, Sigpl
real (kind = 8), dimension(LimA + 2) :: Angx, XSct
real (kind = 8), dimension(LimF) :: Flux
real (kind = 8), dimension(LimF + 1) :: AngstF
real (kind = 8), dimension(LimB) :: XSecPu, X, XTotPu, FlxPlt
real (kind = 8), dimension(LimB + 1) :: XSctPl, RatePl, AngPlt, PhotFlx
real (kind = 8), dimension(LimA, 16) :: XSctn, RateC
character (len = 2) :: BBT
character (len = 8) :: NamPr, RadField
character (len = 8), dimension(2) :: Name
character (len = 8), dimension(16)  :: NamCrs
character (len = 24) :: FMT1, FMT3
character (len = 39) :: FMT2
common /B/ PhotFlx, flxrat, SA, Flux
common Name, nF, RadField, T, BBT
FMT1 = "((a14, 2x, 00 (1x, a8)))"
FMT2 = "((0pf7.1, 1x,    8x , 00 (1x, 1pe8.2)))"
FMT3 = "((a16, 00 (1x, 1pe8.2)))"
open(unit = 12, file = "BBFlux.dat", status = "old")
BBT = "  "
if(iFirst == 0) then
  if(RadField == "Sol") then
    nF = 324
    do
      write(unit = *, fmt = *) "Enter Solar Activity:  (f4.2), Quiet Sun = 0.00 < SA < & 
        &Active Sun = 1.00 / SA = "
      read(unit = *, fmt = "(f4.2)") SA ! Read solar activity
      if(SA >= 0.0) then
        exit
      else
      end if
    end do
! Unit 10 is solar radiation flux.
    read(unit = 10, fmt = "(f8.0, 2x, e8.2)") (PhotFlx(i), PhotFlx(i + 1), i = 1, 2*nF, 2)
    read(unit = 10, fmt = "(f8.0)") PhotFlx(2*nF + 1)
    read(unit = 10, fmt = "(10f5.2)") (FlxRat(i), i = 1, nAS - 2)
    read(unit = 10, fmt = "(2f5.2)") (FlxRat(i), i = nAS - 1, nAS)
    close (unit = 10)
  else
    read(unit = 12, fmt = "(f10.2, 1pe10.2)") (PhotFlx(i), PhotFlx(i + 1), i = 1, 2*nF, 2)
    read(unit = 12, fmt = "(f10.2)") PhotFlx(2*nF + 1) ! BB photon flux in wavelength bin.
  end if
end if
do i = 1, LimF
  Flux(i) = 0.
end do
do i = 1, LimB
  xTotPu(i) = 0.
  do j= 1, 16
    XSctn(i, j) = 0.
    RateC(i, j) = 0.
  end do
end do
read(unit = 4, fmt = "(i3)") nSets     ! Temporary file for wavelengths & cross sections.
minPr = 10000
maxPr = 0
iPrnt = 0
do i = 1, 16
  Rate(i) = 0.
  NamCrs(i) = "        "
end do
if(iFirst == 0) then
  if(RadField == "Sol") then
    write(unit = 20, fmt = "(a69)") "The radiation field is that of the Sun at 1 AU heliocentric distance."
    write(unit = 20, fmt = "(a20 , f5.2, a1)") "The solar activity =", SA, "."
    write(unit = 20, fmt = "(a74/1x)") "(The quiet Sun has solar activity 0, the active Sun has solar activity 1.)"
    write(unit = *, fmt = *) "SA =", SA
  else if(RadField == "BB") then
    write(unit = 20, fmt = "(a43, f11.2, a3)") "The radiation field is a blackbody with T =", T, "K."
  else if(RadField == "IS") then
    write(unit = 20, fmt = "(a36)") "The radiation field is interstellar."
  end if
else
end if
! **********************************
if(RadField == "Sol") then
  do i = 1, nF
    j = 2*i
    AngstF(i) = PhotFlx(j - 1)
    if(j /= 2) then
      AngPlt(j - 1) = dlog10(PhotFlx(j - 1))
    else
      AngPlt(1) = 0.
    end if
    AngPlt(j) = dlog10(PhotFlx(j + 1))
    FlxPlt(j - 1) = dlog10(PhotFlx(j)/(PhotFlx(j + 1) - PhotFlx(j - 1)))
    FlxPlt(j) = FlxPlt(j - 1)
    Flux(i) = PhotFlx(j)
    if(i <= nAS) then
      Flux(i) = Flux(i) + SA*(FlxRat(i) - 1.)*Flux(i)
    else
    end if
  end do
else if(RadField == "BB") then
  do i = 1, nF
    j = 2*i
    AngstF(i) = PhotFlx(j - 1)
    if(j /= 2) then
      if(PhotFlx(j - 1) < 1.e-30) then
        AngPlt(j - 1) = -30.
      else
        AngPlt(j - 1) = dlog10(PhotFlx(j - 1))
      end if
    else
      AngPlt(1) = 0.
    end if
    AngPlt(j) = dlog10(PhotFlx(j + 1))
    if(PhotFlx(j) < 1.e-30) then
      FlxPlt(j - 1) = -30.
    else
      FlxPlt(j - 1) = dlog10(PhotFlx(j)/(PhotFlx(j + 1) - PhotFlx(j - 1)))
    end if
    FlxPlt(j) = FlxPlt(j - 1)
    Flux(i) = PhotFlx(j)
  end do 
end if
AngstF(nF + 1) = PhotFlx(2*nF + 1)
do j = 2, nF, 2
  AngPlt(j - 1) = PhotFlx(j - 1)
  AngPlt(j) = PhotFlx(j + 1)
end do
do i = 2, nF, 2
  FlxRatPl(j - 1) = FlxRat(i)
  FlxRatPl(j) = FlxRat(i)
end do
iFirst = 1
50 NamPr = Name(1)
last = 1
do i = 1, LimB
  x(i) = 0.
  XSecPu(i) = 0.
end do
do i = 1, LimA
  sigma(i) = 0.
end do
do i = 1, LimA + 1
  Angsts(i) = 0.
  AngPl(i) = 0.
  SigPl(i) = 0.
end do
do i = 1, LimB + 1
  XSctPl(i) = 0.
  RatePl(i) = 0.
end do
! Read temporary file for wavelengths & cross sections.
read(unit = 4, fmt = "(i10, 2 f10.2, a8, 2x, a8)", iostat = IOS4) nS, Angst1, AngstL, (Name(i), i = 1, 2)
if(IOS4 > 0) then
  write(unit = *, fmt = *) "Error unit 4"
  stop
else
  if(IOS4 < 0) then
    go to 300
  else
  end if
end if
iPrnt = iPrnt + 1
NamCrs(iPrnt) = Name(2)
if(ns < 0) then
  return
else
end if
! Read temporary file for wavelengths & cross sections.
read(unit = 4, fmt = "(0pf10.2, 1pe10.2)") (Angsts(i), Sigma(i), i=1, nS)
do i = 1, nS
  if(Sigma(i) <= 1.e-30) then
    SigPl(i) = -30.
  else
    SigPl(i) = dlog10(Sigma(i))
  end if
end do
      if(Angst1 - AngstL >= 1.e-6) GO TO 370
      if(Angst1 < AngstF(1)) GO TO 370
      if(AngstL > AngstF(nF + 1)) GO TO 370
      Rate(iprnt) = 0.
      n1 = 0
      nL = 0
do i = 1, nF
  if(AngstF(i) - Angst1 <= 1.e-6) then
    n1 = i
  end if
  if(AngstF(i) < AngstL) then
    nL = i
  end if
end do
if(nL == 1) then
  BBT = "Lo"
  write(unit = 20, fmt = "(a8, a3, a9/ a15, f7.0, a46)") Name(1), "-->", Name(2), "The flux at&
    & T =", T, " K is too low to calculate a rate coefficient."
  write(unit = *, fmt = "(a5, a9, a3, a9, a25, f7.0, a46)") " For ", Name(1), "-->", Name(2), "the blackbody flux at&
    & T =", T, " K is too low to calculate a rate coefficient."
  return
else
end if
if(n1 < minpr) then
  minpr = n1
end if
if(nL > maxpr) then
  maxpr = nL
end if
if(nL <= n1) GO TO 370
!
! Interpolate cross sections
!
j = 1
n = n1 + 1
iL = nS
i1 = 1
Angx(1) = Angst1
XSct(1) = Sigma(1) - (Sigma(2) - Sigma(1))*(Angsts(1) - Angst1)/(Angsts(2) - Angsts(1))
if(XSct(1) < 1.e-30) then
  XSct(1) = 1.e-30
else
end if
if(abs(Angsts(1) - Angst1) < 1.e-6 ) then
  i1 = 2
else
end if
if(abs(Angsts(nS) - AngstL) < 1.e-6) then
  iL = ns - 1
else
end if
do i = i1, iL
  do
    j = j + 1
    if(Angsts(i) - AngstF(n) < -1.e-6) then
      Angx(j) = Angsts(i)
      XSct(j) = Sigma(i)
      exit
    else if(abs(Angsts(i) - AngstF(n)) <= 1.e-6) then
      Angx(j) = Angsts(i)
      XSct(j) = Sigma(i)
      n = n + 1
      exit
    else
      Angx(j) = AngstF(n)
      XSct(j) = XSct(j - 1) + (Sigma(i) - XSct(j - 1))*(AngstF(n) - Angx(j - 1))&
                /(Angsts(i) - Angx(j - 1))
      n = n + 1
    end if
  end do
end do
if(n <= nL) then
  do i = n, nL
    j = j + 1
    Angx(j) = AngstF(i)
    XSct(j) = Sigma(nS - 1) + (Sigma(nS) - Sigma(nS - 1))*(AngstF(i) - Angsts(nS - 1))&
              /(Angsts(nS) - Angsts(nS - 1))
    if(XSct(j) < 1.e-30) then
      XSct(j) = 1.e-30
    end if
  end do
end if
jL = j + 1
Angx(jL) = AngstL
XSct(jL) = Sigma(nS - 1) + (Sigma(nS) - sigma(nS - 1))*(AngstL - Angsts(nS - 1))&
           /(Angsts(nS) - Angsts(nS - 1))
if(XSct(jL) <= 1.e-30) then         ! This was <= 0.  ALSO REMOVE THIS IF LOOP?
  XSct(jL) = 1.e-30
end if
jLm1 = jL - 1
n = n1
maxN = n1 - 1
x(n) = 0.0
x1 = 0.5*XSct(1)
do j = 1, jLm1               !jLm1 Should be about 298
  x2 = 0.5*XSct(j + 1)
  x(n) = x(n) + (x1 + x2)*(Angx(j + 1) - Angx(j))
  x1 = x2
  if(j == jLm1) then
    XSctn(n, iPrnt) = x(n)/(AngstF(n + 1) - AngstF(n))
    RateC(n, iPrnt) = XSctn(n, iPrnt)*Flux(n)
    XSecPu(n) = XSctn(n, iPrnt)
    if(XSecPu(n) > 1.e-30) then
      Last = 0
    else
      Last = Last + 1
    end if
    Rate(iPrnt) = Rate(iPrnt) + XSctn(n, iPrnt)*Flux(n)
  else
    if(Angx(j + 1) >= AngstF(n + 1)) then
      XSctn(n, iPrnt) = x(n)/(AngstF(n + 1) - AngstF(n))
      RateC(n, iPrnt) = XSctn(n, iPrnt)*Flux(n)
      XSecPu(n) = XSctn(n, iPrnt)
      if(XSecPu(n) > 1.e-30) then
        Last = 0
      else
        Last = Last + 1
      end if
      Rate(iPrnt) = Rate(iPrnt) + XSctn(n, iPrnt)*Flux(n)
      n = n + 1
      x(n) = 0.
    else
      cycle  
    end if
  end if
end do
maxN = n - Last    ! maxN is the subscript of the last non-zero cross section.
i = 1
do n = n1, nL
  AngPl(i) = AngstF(n)
  AngPl(i + 1) = AngstF(n + 1)
  if(XSctn(n, iprnt) > 1.e-30 .and. XSctn(n, iPrnt)*Flux(n) > 1.e-30) then
    XSctPl(i) = dlog10(XSctn(n, iPrnt))
    RatePl(i) = dlog10(XSctn(n, iPrnt)*Flux(n)/(AngPl(i+1) - AngPl(i)))
  else
    XSctPl(i) = -30.
    RatePl(i) = -30.
  end if
  XSctPl(i + 1) = XSctPl(i)
  RatePl(i + 1) = RatePl(i)
  i = i + 2
end do
nPlot = i - 1
idyAxs = 1
idyAxs = 0
write(unit = 16, fmt = "(i6)") maxN
do i = 1, maxN, 5
  ij = i + 4
  write(unit = 16, fmt = "(f7.0, 3x, 1p5e10.3, a8, 2x, a8)") AngstF(i), (XSecPu(j), j = i, ij), (Name(k), k = 1, 2)
end do
if(nSets - iPrnt) 300, 300, 50
300 CONTINUE
NamPr = Name(1)
if(nSets <= 0) then
  nSets = 1
end if
m2 = nSets
m3 = 1
m4 = nSets
if(nSets > 8) then
  m2 = 8
  m4 = 8
else
end if
write(unit = 15, fmt = "(i2, 49x, a8)") nSets, NamPr      ! unit 15 is FotOut.
write(unit = 3, fmt = "(i2, 49x, a8)") nSets, NamPr       ! unit 3 is RatOut.
  if(m2 < 10) then
    FMT1(13:13) = CHAR(m2 + 48)
    FMT1(12:12) = CHAR(48)
    FMT2(24:24) = CHAR(m2 + 48)
    FMT2(23:23) = CHAR(48)
    FMT3(9:9) = CHAR(m2 + 48)
    FMT3(8:8) = CHAR(48)
  else
    FMT1(13:13) = CHAR(m2 + 38)
    FMT1(12:12) = CHAR(m2/10 + 48)
    FMT2(24:24) = CHAR(m2 + 38)
    FMT2(23:23) = CHAR(m2/10 + 48)
    FMT3(9:9) = CHAR(m2 + 38)
    FMT3(8:8) = CHAR(m2/10 + 48)
  end if
  write(unit = 15, fmt = FMT1) " Lambda       ", (NamCrs(j), j = m3, m4)
  write(unit = 3, fmt = FMT1) " Lambda       ", (NamCrs(j), j = m3, m4)
  write(unit = 15, fmt = FMT2) (AngstF(i), &
       (XSctn(i, j), j = m3, m4), i = minPr, maxPr)
  write(unit = 3, fmt = FMT2) (AngstF(i), &
       (XSctn(i, j), j = m3, m4), i = minPr, maxPr)
  write(unit = 15, fmt = "(0pf7.1)") AngstF(maxPr + 1)
  write(unit = 3, fmt = "(0pf7.1)") AngstF(maxPr + 1)
  write(unit = 3, fmt = FMT3) " Rate Coeffs. = ", (Rate(j), j = m3, m4)
aLast = 0.
do i = 1, nF
  do j = 1, 16
    XTotPu(i) = XTotPu(i) + XSctn(i, j)
    XSctn(i, j) = 0.
  end do
  if(XTotPu(i) == 0.) then
    if(aLast < 1.e-20) then
      maxN = i - 1
    end if
  else
      aLast = XTotPu(i)
  end if
end do
write(unit = 16, fmt = "(i6)") maxN
do i = 1, maxN, 5
  ij = i + 4
  write(unit = 16, fmt = "(f7.0, 3x, 1p5e10.3, 10x, a8)") AngstF(i), (XTotPu(j), j = i, ij), NamPr
end do
do i = 1, 16
  Rate(i) = 0.
  NamCrs(i) = "        "
end do
do i = 1, nF
!do i = 1, nAS*2
  XTotPu(i) = 0.
end do
minpr = 10000
maxpr = 0
iprnt = 1
return
  370 CONTINUE
write(unit = 15, fmt = "(1x, 2(a8, 2x), 1x, a12/a12, 9x, a13,&
  & f10.2, a18, f10.2/22x, a5, i5/a31, f10.2, a11, f10.2/ 22x, a5, i5,&
  & a7, i5, a7, i5)") &
  (Name(i), i=1,2), "input error", "Flux values: ", "AngstF(1) = ", &
  AngstF(1), ", AngstF(nF + 1) = ", AngstF(nF + 1), "nF = ", nF, &
  "Cross section values: Angst1 = ", Angst1, ", AngstL = ", AngstL, &
  "ns = ", ns, ", n1 = ", n1, ", nL = ", nL
GO TO 50
return
end Subroutine Fotrat
!
! *****************************************************************************
!
Subroutine Convert(BSum)            ! BSum = nSum, but BSum is not used
! integer, parameter :: nAS = 162, nF = 324, LimA = 50000, LimB = 2000, LimF = 1000
integer, parameter :: nAS = 162, LimA = 50000, LimB = 2000, LimF = 1000
integer :: BSum, i, iCat, idiff, iFlag, inc, ind2, ind3, IOS16, iPrnt, j, k, &
           m2, m3, m4, maxBin, maxN, maxp3, n1, n2, nSets, nSum, Numb, nF
integer, dimension(16) :: Num, iFlg, Kat
real (kind = 8) :: AvGen, ETot, EnElec, Flx, Rate, SA, Thresh, TRate, Wave1, Wave2, WAveL, XSect
real (kind = 8), parameter :: AngeV = 12398.5     ! 12398.5 A = 1 eV
real (kind = 8), dimension(16) :: Thrsh, TotRat, TotEEn
real (kind = 8), dimension(nAS) :: FlxRat         ! Flux ratio of active/quiet Sun
real (kind = 8), dimension(LimB + 1) :: PhotFlx
real (kind = 8), dimension(9999) :: data
real (kind = 8), dimension(LimA, 16) :: ExEn
real (kind = 8), dimension(LimF) :: Flux
character (len = 24) :: FMT3, FMT5 !, FMT6
character (len = 38) :: FMT4
character*8 Name, Name1, Name2, Nam(16), NamCrs(16), NamPr
common /A/ Nam, Num, Kat, iFlg, Thrsh, nSets
common /B/ PhotFlx, FlxRat, SA, Flux
! *******
character (len = 8) :: RadField ! NamPr, RadField
! integer :: ! i, j, nF, idxaxs, iGrPt, nGrPts, Deltan
common Name, nF, RadField !, T, BBT
! *******
FMT3 = "((a14, 2x, 00 (1x, a8)))"
FMT4 = "((0pf7.1, 1x,    8x, 00 (1x, 1pe8.2)))"
FMT5 = "((a16, 00 (1x, 1pe8.2)))"
rewind(unit = 4)
read(unit = 4, fmt = "(i3)") nSets     ! Temporary file for wavelengths & cross sections.
ind3 = 0
maxBin = 0
iPrnt = 0
k = 0
do j = 1, 16
  NamCrs(j) = "        "
  TotRat(j) = 0.
  TotEEn(j) = 0.
  do i = 1, LimA
    ExEn(i, j) = 0.
  end do
end do
   10 CONTINUE
iPrnt = iPrnt + 1
k = k + 1
read(unit = 16, fmt = "(i6)", iostat = IOS16) maxN
if(IOS16 > 0) then
  write(unit = *, fmt = *) "Error unit = 16"
  stop
else
  if(IOS16 < 0) then
    return
  end if
end if
if(maxN < 0) then
  return
else
end if
if(maxN > 9999) then
  write(unit = *, fmt = *) "Stop (maxN > 9999)"
  stop
else
end if  
maxBin = max(maxN, maxBin)
Name = Nam(k)
Numb = Num(k)
iCat = Kat(k)
iFlag = iFlg(k)
Thresh = Thrsh(k)
if(iFlag == 0) then
  nSum = nSum + maxN + 3
else
end if
read(unit = 16, fmt = "(10x, 5e10.3, a8, 2x, a8)") (data(i), i = 1, 5), Name1, Name2
 read(unit = 16, fmt = "(10x, 5e10.3)") (data(i), i = 6, maxN)
if(iFlag == 1) then
else
!
! Begin EIoniz.
!
! *****
write(unit = 9, fmt = *) "Begin EIoniz"
  write(unit = 9, fmt = "(1x, 2 i5, 11x, a8, 12x, a8)") Numb, iCat, Name1, Name2    ! Unit 9 is EIoniz.
  write(unit = 9, fmt = "(a49, a18)") "0   Wavelength Range  X-Section   Flux      Rate ", "    E Excess   Sum"
  NamPr = Name1
  NamCrs(iprnt) = Name2
  if(nSets <= 0) then
    nSets = 1
  else
  end if
  m2 = nSets
  m3 = 1
  m4 = nSets
  if(iPrnt == 1) then
    write(unit = 19, fmt = "(i2, 49x, a8)") nSets, NamPr   ! Unit 19 is EEOut.
    write(unit = 20, fmt = "(a8)") NamPr                   ! Unit 20 is Summary.
  else
  end if
  if(m2 < 10) then
    FMT3(13:13) = CHAR(m2 + 48)
    FMT3(12:12) = CHAR(48)
    FMT4(23:23) = CHAR(M2 + 48)
    FMT4(22:22) = CHAR(48)
    FMT5(9:9) = CHAR(M2 + 48)
    FMT5(8:8) = CHAR(48)
  else
    FMT3(13:13) = CHAR(M2 + 38)
    FMT3(12:12) = CHAR(M2/10 + 48)
    FMT4(23:23) = CHAR(M2 + 38)
    FMT4(22:22) = CHAR(M2/10 + 48)
    FMT5(9:9) = CHAR(M2 + 38)
    FMT5(8:8) = CHAR(M2/10 + 48)
  end if
    TRate = 0.
    ETot = 0.
    do i = 1, maxN
      Wave1 = PhotFlx(2*i - 1)
      Wave2 = PhotFlx(2*i + 1)
      XSect = Data(i)
      Flx = Flux(i)
      Rate = XSect*Flx
      if(Wave1 < 1.0E-06) then         ! NEW 2/27/11 in place of: if(Wave1 == 0.) then
        Wave1 = 0.1
      else if(Wave1 > Thresh) then     ! NEW 2/27/11
        Wave1 = Thresh                 ! NEW 2/27/11
      else
      end if
      if(Wave2 > Thresh) then          ! NEW 2/27/11
        Wave2 = Thresh                 ! NEW 2/27/11
      else                             ! NEW 2/27/11
      end if                           ! NEW 2/27/11
      WaveL = 2.*Wave1*Wave2/(Wave1 + Wave2)
      EnElec = AngeV/WaveL - AngeV/Thresh
      TRate = TRate + Rate
      ExEn(i, iprnt) = EnElec*RATE
      ETot = ETot + EnElec*Rate
! *************
      write(unit = 9, fmt = "(1h , 2 f10.2, 1p3e10.3, 0pf10.2, 1pe10.3)") &
            Wave1, Wave2, XSect, Flx, Rate, EnElec, ETot
! *************
    end do
    AvgEn = ETot/TRate
    write(unit = 9, fmt = "(a1, 48X, a13, 1pe10.3)") "0", "Total Rate = ", TRate
    write(unit = 9, fmt = "(45X, a17, f6.3)") "Average Energy = ", AvgEn
    TotRat(iPrnt) = TRate
    TotEEn(iPrnt) = AvgEn
    do i = 1, maxN
      ExEn(i, iPrnt) = ExEn(i, iPrnt)/TRate
      if(ExEn(i, iPrnt) < 0.) then
        ExEn(i, iPrnt) = 0.
      end if
    end do
    do j = 1, nSets
      if(ExEn(maxN, j) < 0) then
        ExEn(maxN, j) = 0.
      else
      end if
    end do
    if(iPrnt == nSets) then
      write(unit = 19, fmt = FMT3) " Lambda       ", (NamCrs(j), j = m3, m4)
      write(unit = 19, fmt = FMT4) (PhotFlx(2*i - 1), &
           (ExEn(i, j), j = 1, nSets), i = 1, maxBin)
      write(unit = 19, fmt = "(0PF7.1)") PhotFlx(2*maxBin + 1)
      write(unit = 19, fmt = FMT5) " Rate Coeffs. = ", (TotRat(j), j = 1, nSets)
      write(unit = 20, fmt = FMT5) " Rate Coeffs. = ", (TotRat(j), j = 1, nSets)    ! Summary file.
      write(unit = 19, fmt = FMT5) " Av. Excess E = ", (TotEEn(j), j = 1, nSets)
      write(unit = 20, fmt = FMT5) " Av. Excess E = ", (TotEEn(j), j = 1, nSets)    ! Summary file.
    else
    end if
!
! End EIoniz
!
end if
maxp3 = maxN + 3
n2 = 0
inc = 5
ind2 = 117
  if(ind2 > maxp3) then
    ind2 = maxp3
  else
  end if
  ind3 = ind2 - 3
   50 CONTINUE
  n1 = n2 + 1
  n2 = n1 + inc
  IF (n2 .lt. ind3) GO TO 50
    n2 = ind3
    iDiff = n2 - n1
    if(iDiff == 0) then
    else
    end if
    if(n2 /= maxN) then
    else
    end if  
      if (n2 .eq. maxN) GO TO 10
      GO TO 80
   80 CONTINUE
    ind2 = ind2 + 114
    if(ind2 > maxp3) then
      ind2 = maxp3
    end if
    ind3 = ind2 - 3
      GO TO 50
return
end Subroutine Convert

end Module PhotRatM
