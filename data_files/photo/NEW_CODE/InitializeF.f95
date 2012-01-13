Program InitializeF
!
! *** This version of PhotoRates (PhotoRatesF) uses input from an input file. ***
!
! This computer program is intended to calculate rate coefficients for photodissociation, 
! photoionization, and photodissociative ionization.  When adding photoexcitation cross 
! sections it could also be used to calculate rate coefficients for that process.
! This code also calculates the excess energies of the photo products. 
! Subroutines called:  Branch, FotRat, Convert, (PltXsctn,?) and EIoniz (as part of Convert).
!
integer, parameter :: LimA = 50000, LimB = 2000, LimF = 1000, nSum = 0
integer :: iFirst
integer :: iEnd, IOS1, nB, nS
real (kind = 4) :: SA, DumSA
real (kind = 8), dimension(LimF) :: Flux
real (kind = 8), dimension(LimF + 1) :: AngstF
real (kind = 8) :: T
character (len = 3) :: BB, IS, RadField, Sol, Dummy
character (len = 8) :: NamPr
common Name, RadField
open(unit =  1, file = "Hrec", status = "old")   ! Input data (HRec):  Species name, wavelengths, 
!                                                  cross sections, branching ratios, etc.
open(unit =  2, file = "BrnOut")                 ! Wavelengths and cross sections for branches.
open(unit =  3, file = "RatOut")                 ! Binned rate coefficients per Angstrom.
open(unit =  4, status = "replace")              ! Temporary file for wavelengths and cross sections.
Open(unit =  7, file = "Input")                  ! Input parameters:  Sol, BB, IS, AS, T, etc.
open(unit =  9, file = "EIoniz")                 ! Binned rates and excess energies.
! open(unit = 10, file = "PhFlux.dat", status = "old") ! Solar flux for quiet Sun.
open(unit = 15, file = "FotOut")                 ! Binned Cross Sections.
open(unit = 16, status = "replace")              ! Temporary file.
open(unit = 19, file = "EEOut")                  ! Binned excess energies per Angstrom.
open(unit = 20, file = "Summary")                ! Summary of rate coefficients and average excess energies.
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
read(unit = 7, fmt = "(a3)") RadField
if(RadField == "Sol") then
  read(unit = 7, fmt = "(f4.2)") SA
  call SolRad(SA)
else
  if(RadField == "BB ") then
    read(unit = 7, fmt = "(f4.2)") DumSA
    write(unit = *, fmt = *) " DumSA=", DumSA
    read(unit = 7, fmt = "(f8.0)") T
    call BBRad(T)
  else
    if(RadField == "IS") then  ! Calculate interstellar spectral photon flux. 
      call ISRad
    else
    end if
  end if
end if
!
! Calculate spectral photon flux at 1 AU heliocentric distance for solar activity = SA.
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
    rewind(unit = 4)         ! Scratch file for wavelengths and cross sections.
    rewind(unit = 16)        ! Scratch file.
    exit
  else
    write(unit = *, fmt = *) " iEnd = 1, i.e., end of HRec file."
    exit
  end if
end do
close(unit =  2)
close(unit =  3)
close(unit =  4)
close(unit =  9)
close(unit = 10)
close(unit = 15)
close(unit = 16)
close(unit = 19)
close(unit = 20)
stop
end Program InitializeF


