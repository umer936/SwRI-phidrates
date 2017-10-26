Subroutine BBRad(T)
!implicit none
! This program calculates the number of photons emitted per unit area per unit time per unit 
! wavelength for a blackbody (BB).  From this it calculates the number of photons in each wavelength 
! bin per unit area.  NBB_lambda = 2*pi*c/[lambda**4*[e**[h*c/[(k*lambda*T)] - 1].
! Then it calculates the BB rate coefficients.  BBGrid is based on solar flux grid, except one grid 
! point is inserted where the BB function is near its maximum for various temperatures.  A few 
! additional grid points have been added at long wavelengths.
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
integer, parameter :: LimA = 50000, LimB = 2000, LimF = 1000, nmax = 300, GrPtLim = 400
integer :: i, j, nF, iGrPt, nGrPts, Deltan
real (kind = 8), parameter :: e = 2.71828183, k_B = 1.3806505d-23, & 
  h = 6.6260755d-34, c = 2.99792458d+08, pi = 3.141592653589793d+00 
real (kind = 8) :: Angstc, T, c1, c2, NBB1, NBB2, RFmax, X
real (kind = 8), dimension(LimB + 1) :: XSctPl, RatePl, AngPlt !, PhotFlx
real (kind = 8), dimension(LimA + 1) :: Angsts, AngPl, Sigpl
real (kind = 8), dimension(LimF) :: Flux
real (kind = 8), dimension(LimF + 1) :: AngstF
real (kind = 8), dimension(GrPtLim) :: BBGrid
character (len = 3) :: BB, IS, RadField, Sol
character (len = 8), dimension(2) :: Name
character (len = 8) :: NamPr
common Name, RadField
common /d/ AngstF, Flux, nF

open(unit = 3, file = "Output", status = "unknown")   ! RatOut = Binned rate coefficient per Angstrom.
open(unit = 7, file = "BBGrid.dat", status = "old")   ! Solar grid plus a few additional wavelength points.
open(unit = 12, file = "BBFlux.dat", status = "unknown") ! BB photon flux in wavelength bin.

nGrPts = 337
if(nGrPts > GrPtLim) then
  write(unit = *, fmt = *) " *** Increase GrPtLim. ***"
else
end if
c1 = 2*pi*c   ! 1.8836516e+09 m/s
c2 = h*c/k_B  ! 1.4387765e-02 Kelvin m
! wavelength at which spectral exitance is a maximum:  Angstc = 2.8978e-03/T [m].
read(unit = 7, fmt = "(f10.2)") (BBGrid(i), i = 1, nGrPts) ! Basic wavelength grid for BB wavelength 
                                                           ! grid
close(unit = 7)
iGrPt = 1
NBB1 = 0.0 ! Number of photons emitted per unit area per unit wavelength at lower wavelength 
           ! of first bin.
nF = 1
AngstF(nF) = BBGrid(iGrPt)             ! Lower wavelength of a bin
! PhotFlx(nF + 1) = BBGrid(iGrPt + 1)  ! Upper wavelength of a bin
AngstF(nF + 1) = BBGrid(iGrPt + 1)     ! Upper wavelength of a bin
do
  if(c2/(AngstF(nF + 1)*1.d-10*T) < 700.) then  ! Avoid overflow of the exponent.
    NBB2 = c1*1.d-04/((AngstF(nF + 1)*1.d-10)**(4.d+00)*(dexp(c2/(AngstF(nF + 1)*1.d-10*T)) - 1.d+00))
    Flux(nF) = (NBB1 + NBB2)*(AngstF(nF + 1) - AngstF(nF))*1.d-10/2.
  else
    Flux(nF) = 0.0
  end if
  write(unit = 12, fmt = "(f10.2, 1pe10.2)") AngstF(nF), Flux(nF)  ! Blackbody photon flux
  iGrpt = iGrPt + 1
  nF = nF + 1
  AngstF(nF + 1) = BBGrid(iGrPt + 1)
  if(iGrPt == nGrPts) then
    write(unit = 12, fmt = "(f10.2)") AngstF(nF)      ! Wavelength of last bin in Angstrom.
    exit
  else
    NBB1 = NBB2
  end if
end do
if(iFirst == 0) then
  write(unit = 20, fmt = "(a43, f11.2, a3)") "The radiation field is from a blackbody at T =", T, "K."
else
end if
close(unit = 12)
return
end Subroutine BBRad
