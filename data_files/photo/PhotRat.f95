Program PhotRat
!
! This Code is a Synthesis of the Codes Branch, Fotrat, Convert, and EIoniz.
!
use PhotRatM
implicit none
integer, parameter :: iFirst = 0, nSum = 0
integer :: iEnd, nF
integer :: i, ij, i1, iL, idxAxs, idyAxs
real (kind = 8) :: T
character (len = 8) :: RadField
character (len = 3) :: Sol
character (len = 2) :: BB, IS, BBT
character (len = 8), dimension(2) :: Name
common Name, idxaxs, idyaxs, nF, RadField, T, BBT
! HREC:  Input data:  Species name, wavelengths, cross sections, branching ratios, etc.
open(unit = 1, file = "HRec", status = "old") 
open(unit = 2, file = "BrnOut")        ! Wavelengths & cross sections for various branches.
open(unit = 3, file = "RatOut")        ! RatOut = Binned rate coefficient per Angstrom.
open(unit = 4, status = "replace")     ! Temporary file for wavelengths & cross sections.
open(unit = 9, file = "EIoniz")        ! Binned rates & excess energies.
!
iEnd = 0
do
  write(unit = *, fmt = *) "Enter radiation field:  Sol for solar, BB for blackbody, IS for interstellar"
  read(unit = *, fmt = "(a3)") RadField
  write(unit = *, fmt = *) "RadField = ", Radfield
  if(RadField == "Sol") then
    open(unit = 10, file = "PhFlux.dat", status = "old") ! PhFlux.dat is solar flux.
    exit
  else if(RadField == "BB") then
    call BlackB ! Calclate blackbody flux at temperature T.
    exit
  else if(RadField == "IS") then
    open(unit = 14, file = "ISFlux.dat")  !, status ="old")  ! ISFlux.dat is interstellar flux.
    exit
  else 
    write(unit = *, fmt = *) "Error:  Unspecified radiation field."
  end if
end do
open(unit = 15, file = "FotOut")       ! FotOut = Binned cross section.
open(unit = 16, status = "replace")    ! Temporary file.
open(unit = 19, file = "EEOut")        ! EEOut = Binned excess energy per Angstrom.
open(unit = 20, file = "Summary")      ! Summary of rate coefficients & excess energies.
do
  call Branch(iEnd)
  if(iEnd /= 1) then
    rewind(unit = 4)         ! Temporary file for wavelengths & cross sections.
    call FotRat(iFirst)
    if(BBT == "Lo") then
      BBT = "  "
    else
      rewind(unit = 16)      ! Temporary file.
      call Convert(nSum)
    end if
    rewind(unit = 4)         ! Temporary file for wavelengths & cross sections.
    rewind(unit = 16)        ! Temporary file.
  else
    exit
  end if
! close(unit = 2)
! close(unit = 3)
! close(unit = 9)
! close(unit = 15)
! close(unit = 19)
end do
close(unit = 20)
stop
end Program PhotRat


