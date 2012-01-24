Subroutine SolRad(SA)
!
! This subroutine calculates the solar photon flux for the activity level of the Sun.
!
integer, parameter :: LimB = 2000, LimF = 1000, nSA = 162
integer :: iFirst = 0
real (kind = 4) :: SA
real (kind = 8), dimension(LimB) :: FlxPlt
real (kind = 8), dimension(LimB + 1) :: AngPlt, PhotFlx
real (kind = 8), dimension(LimF) :: Flux
real (kind = 8), dimension(LimF + 1) :: AngstF
real (kind = 8), dimension(nSA) :: FlxRatio      ! Flux ratio of active/quiet Sun.
character (len = 3) :: BB, IS, RadField, Sol
common Name, RadField
common /C/ AngstF, Flux, nF
!
nF = 324
do i = 1, LimF
  Flux(i) = 0.0
end do
if(iFirst == 0) then
!  open(unit =  4, status = "replace")            ! Scratch file for wavelengths and cross sections.
  open(unit = 10, file = "PhFlux.dat", status = "old") ! Solar photon flux for quiet Sun.
  open(unit = 20, file = "Summary")              ! Summary of rate coefficients and excess energies.
  read(unit = 10, fmt = "(f8.0, 2x, e8.2)") (PhotFlx(i), PhotFlx(i + 1), i = 1, 2*nF, 2)
  read(unit = 10, fmt = "(f8.0)") PhotFlx(2*nF + 1)
  write(unit = *, fmt = *) " nSA=", nSA
  read(unit = 10, fmt = "(10f5.2)") (FlxRatio(i), i = 1, nSA - 2)
  read(unit = 10, fmt = "(2f5.2)") (FlxRatio(i), i = nSA - 1, nSA)
  close(unit = 10)
else
end if
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
  if(i <= nSA) then
    Flux(i) = Flux(i) + SA*(FlxRatio(i) - 1.)*Flux(i)
  else
  end if
end do
AngstF(nF + 1) = PhotFlx(2*nF + 1)
!do i = 1, LimB
!  xTotPu(i) = 0.
!  do j= 1, 16
!    XSctn(i, j) = 0.
!    RateC(i, j) = 0.
!  end do
!end do
!read(unit = 4, fmt = "(i3)") nSets     ! Temporary file for wavelengths & cross sections.
!minPr = 10000
!maxPr = 0
!iPrnt = 0
!do i = 1, 16
!  Rate(i) = 0.
!  NamCrs(i) = "        "
!end do
if(iFirst == 0) then
  write(unit = 20, fmt = "(a69)") "The radiation field is that of the Sun at 1 AU heliocentric distance."
  write(unit = 20, fmt = "(a20 , f5.2, a1)") "The solar activity =", SA, "."
  write(unit = 20, fmt = "(a74/1x)") "(The quiet Sun has solar activity 0.00, the active Sun has solar activity 1.00)"
else
end if
return
end Subroutine SolRad
