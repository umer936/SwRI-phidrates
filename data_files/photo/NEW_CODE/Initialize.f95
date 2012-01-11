Program PhotoRates
!
! This computer program is intended to calclate rate coefficients for photodissociation, 
! photoionization, and photodissociative ionization.  When adding photoexciatation cross 
! sections it could also be used to calculate rate coefficients for that ptocess.
! This code also calculates the excess energies of the photo products. 
! Subroutines called:  Branch, FotRat, Convert, (PltXsctn,?) and EIoniz (as part of Convert).
!
use PhotRatM
integer, parameter :: iFirst = 0, LimA = 50000, LimB = 2000, LimF = 1000, nSum = 0
integer :: iEnd, IOS1, nB, nS
real (kind = 8), dimension(LimF) :: Flux
real (kind = 8), dimension(LimF + 1) :: AngstF
real (kind = 8) :: T
character (len = 3) :: BB, IS, RadField, Sol
character (len = 8) :: NamPr
open(unit =  1, file = "HREC", status = "old")   ! Input data (HRec):  Species name, wavelengths, 
!                                                  cross sections, branching ratios, etc.
open(unit =  2, file = "BRNOUT")                 ! Wavelengths and cross sections for branches.
open(unit =  3, file = "RATOUT")                 ! Binned rate coefficient per Angstrom.
open(unit =  4, status = "replace")              ! Temporary file for wavelengths and cross sections.
open(unit =  9, file = "EIONIZ")                 ! Binned rates and excess energies.
open(unit = 10, file = "PHFLUX.DAT", status = "old") ! Solar flux for quiet Sun.
open(unit = 15, file = "FOTOUT")                 ! Binned Cross Section.
open(unit = 16, status = "replace")              ! Temporary file.
open(unit = 19, file = "EEOUT")                  ! Binned excess energy per Angstrom.
open(unit = 20, file = "Summary")                ! Summary of rate coefficients and excess energies.
!
! After selecting the type of molecular species (monatomic ion, monatomic neutral, diatomic, triatomic, 
! tetratomic, pentatomic, or suprapentatomic molecule), select the ion, atom or molecule of interest 
! from these lists by reading the appropriate HRec file and calulate the cross sections for the various 
! branches (ionization, dissociation, and dissociative ionization) in subroutine Branch.
!
iEnd = 0
call Branch(iEnd)
do i = 1, LimF
  Flux(i) = 0.0
end do
do
  write(unit = *, fmt = *) "Enter radiation field:  Sol for solar, BB for blackbody, IS for interstellar"
  read(unit = *, fmt = "(a3)") RadField
  write(unit = *, fmt = *) "RadField = ", RadField
!
! Calculate spectral photon flux at 1 AU heliocentric distance for solar activity = SA.
!
  if(RadField == "Sol") then  
    write(unit = *, fmt = *) "Enter solar activity (f4.2).  Quiet Sun = 0.00 <= SA <= active Sun = 1.00."
    read(unit = *, fmt = "(f4.2)") SA
    write(unit = *, fmt = "(a14, f4.2)") " Entered SA = ", SA
    call SolRad(SA)
    exit
  else 
    if(RadField == "BB") then  ! Calculate blackbody photon field for temperature T (K).
      do
        write(unit = *, fmt = *) "Enter temperature T (f8.0) for blackbody radiation in K."
        write(unit = *, fmt = *) "Minimum T = 50.0 K; recommended maximum T = 1,000,000. K"
        read(unit = *, fmt = "(f8.0)") T
        if(T >= 50.) then
          write(unit = *, fmt = "(a13, f8.0)") " Entered T = ", T
          exit
        else
          write(unit = *, fmt = *) "Entered T =", T, "K, but should be between minimum of 50 K"
          write(unit = *, fmt = *) "and recommended maximum of 1,000,000. K"
        end if
      end do  
      call BBRad(T)
      exit
    else
      if(RadField == "IS") then  ! Calculate interstellar spectral photon flux. 
        call ISRad
        exit
      else
        write(unit = *, fmt = *) "Error:  Unspecified radiation field."
      end if
    end if
  end if
end do
!
! After the cross sections of the various photoprocesses have been determined, select the desired 
! rediation field:  
! (1) solar rdiation, "Sol", at 1 AU heliocentric distance (including the solar activity, 
!     SA = 0.00 for the quiet Sun, SA = 1.00 for the active Sun, or any value of SA between 
!     these limits); 
! (2) blackbody radiation, "BB", (including the blackbody temperature, T, for any value between 
!     T = 50 K and 1,000,000 K);
! (3) interstellar radiation field, "IS" (not yet implemented).
!
! Next, the computer program will calculate the appropriate rate coefficients and the excess 
! energies of the photo products.
!
do
  if(iEnd /= 1) then
    rewind(unit = 4)         ! Temporary file for wavelengths and cross sections.
    call FotRat(iFirst)
    rewind(unit = 16)        ! Temporary file.
    call Convert(nSum)
! ***
    write(unit = *, fmt = *) " after Convert:  iEnd=", iEnd
    stop
! ***
    rewind(unit = 4)         ! Scratch file for wavelengths and cross sections.
    rewind(unit = 16)        ! Scratch file.
  else
    exit
  end if
end do
stop
end Program PhotoRates

