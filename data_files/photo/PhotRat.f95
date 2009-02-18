Program PhotRat
!
! This Code is a Synthesis of the Codes Branch, Fotrat, Convert, and EIoniz.
!
use PhotRatM
implicit none
integer, parameter :: iFirst = 0, nSum = 0
integer :: iEnd

iEnd = 0
open(unit = 1, file = "HRec", status = "old")
open(unit = 2, file = "BrnOut")
open(unit = 4, status = "replace")
open(unit = 3, file = "RatOut")
!
! RatOut = Binned rate coefficient per Angstrom.
!
open(unit = 9, file = "EIoniz")
open(unit = 10, file = "PhFlux.dat", status = "old")
open(unit = 15, file = "FotOut")
!
! FotOut = Binned cross section.
!
open(unit = 16, status = "replace")
open(unit = 19, file = "EEOut")
open(unit = 20, file = "Summary")
!
! EEOut = Binned excess energy per Angstrom.
!
do
  call Branch(iEnd)
  if(iEnd /= 1) then
    rewind(unit = 4)
    call FotRat(iFirst)
    rewind(unit = 16)
    call Convert(nSum)
    rewind(unit = 4)
    rewind(unit = 16)
  else
    exit
  end if
!close(unit = 2)
!close(unit = 3)
!close(unit = 9)
!close(unit = 15)
!close(unit = 19)
end do
stop
end Program PhotRat


