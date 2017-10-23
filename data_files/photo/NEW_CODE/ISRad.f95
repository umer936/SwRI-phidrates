Subroutine ISRad
implicit none
! This program uses the number of photons emitted at a given wavelength per unit area per unit time per unit 
! wavelength for the standard interstellar radiation field (ISRF) as specified by Draine 
! (Astrophys. J. Suppl. 36, 595, 1978) and van Dishoeck and !Black (Astrophys. J. 258, 533, 1982) 
! to calculate the number of IS photons in each wavelength bin per unit area per unit time. 
! lambda (Angstrom) = 12398.5 / E (eV). 
! Draine (1978): 
! Flux [photons/(cm^2 s A)] = 4*pi* [1658000*E - 215200*E^2 + 6919*E^3]/12398.5 
! Since Delta E = 12398.5*(Delta lambda)/lamda^2, 
! Flux [photons/(cm^2 s A)] = [3.203 - 5154*lambda^{-1} + 2055000*lambda^{-2}]*10^15/lambda^3,  (lambda < 2000 A). 
! The van Dishoeck and Black (1982) extension of the flux: 
! Flux [photons/(cm^2 s A)] = 732.26*lambda^{0.7),  (lambda > 2000 A),
!   since 3670.*(0.1)**(0.7) = 732.26.
! The ISGrid (wavelength) is based on the solar flux grid, except a few additional grid points have been added at long wavelengths.
! 
! lambda is the photon wavelength in Angstrom (1 A = 1.E-10 m). 

integer, parameter :: LimA = 50000, LimB = 2000, LimF = 1000, nmax = 300, GrPtLim = 400
integer :: i, j, nF, iGrPt, nGrPts, Deltan, iFirst
real (kind = 8) :: NIS1, NIS2
real (kind = 8), dimension(LimF) :: Flux
real (kind = 8), dimension(LimF + 1) :: AngstF
real (kind = 8), dimension(GrPtLim) :: ISGrid
character (len = 3) :: BB, IS, RadField, Sol
character (len = 8), dimension(2) :: Name
character (len = 8) :: NamPr
common Name, RadField
common /C/ AngstF, Flux, nF

write(unit = *, fmt = *) "Subroutine ISRad"
open(unit = 3, file = "Output", status = "unknown")   ! RatOut = Binned rate coefficient per Angstrom.
open(unit = 7, file = "BBGrid.dat", status = "old")   ! Solar grid plus a few additional wavelength points.
open(unit = 12, file = "ISFlux.dat", status = "unknown") ! IS photon flux in wavelength bin.

nGrPts = 337
if(nGrPts > GrPtLim) then
  write(unit = *, fmt = *) " *** Increase GrPtLim. ***"
else
end if

read(unit = 7, fmt = "(f10.2)") (ISGrid(i), i = 1, nGrPts) ! Basic wavelength grid for IS wavelength 
                                                           ! grid
close(unit = 7)
iGrPt = 1
NIS1 = 0.0 ! Number of photons emitted per unit area per unit wavelength at lower wavelength 
           ! of first bin.
nF = 1
AngstF(nF) = ISGrid(iGrPt)             ! Lower wavelength of a bin
! PhotFlx(nF + 1) = ISGrid(iGrPt + 1)  ! Upper wavelength of a bin
AngstF(nF + 1) = ISGrid(iGrPt + 1)     ! Upper wavelength of a bin
do
  if(AngstF(nF + 1) < 911.) then
    NIS2 = 0.0
  else
    if(AngstF(nF + 1) < 2000.) then
      NIS2 = (3.2028 - 5154.2/AngstF(nF + 1) + 2054600./(AngstF(nF + 1))**2)*1.d15/(AngstF(nF + 1))**3 
    else
      if(AngstF(nF + 1) == 2000.) then
        NIS2 = ((3.2028 - 5154.2/AngstF(nF + 1) + 2054600./(AngstF(nF + 1))**2)*1.d15/(AngstF(nF + 1))**3 & 
          + 732.26*(AngstF(nF + 1))**(0.7))/2.
      else
        NIS2 = 732.26*(AngstF(nF + 1))**(0.7)  ! AngstF(nF + 1) > 2000 A.
      end if
    end if
  end if
  Flux(nF) = (NIS1 + NIS2)*(AngstF(nF + 1) - AngstF(nF))/2.
  write(unit = 12, fmt = "(f10.2, 1pe10.2)") AngstF(nF), Flux(nF)  ! Interstellar photon flux
  iGrpt = iGrPt + 1
  nF = nF + 1
  AngstF(nF + 1) = ISGrid(iGrPt + 1)
  if(iGrPt == nGrPts) then
    write(unit = 12, fmt = "(f10.2)") AngstF(nF)      ! Wavelength of last bin in Angstrom.
    exit
  else
    NIS1 = NIS2
  end if
end do
if(iFirst == 0) then
  write(unit = 20, fmt = "(a36)") "The radiation field is interstellar."
else
end if
close(unit = 12)
return
end Subroutine ISRad
