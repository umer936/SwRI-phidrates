$(FC) = gfortran

photo : Branch.o BBRad.o Convert.o  InitializeF.o  ISRad.o  PltXsctn.o  RateCoeff.o  SolRad.o
	gfortran -o photo.exe Branch.o BBRad.o InitializeF.o Convert.o ISRad.o  PltXsctn.o  RateCoeff.o  SolRad.o

%.o %.mod: %.f95
	gfortran -M . -g -c -o $@ $< 

clean:
	rm -f *.o *.mod BBFlux.dat fort.* Summary replace RatOut Output EIoniz BrnOut EEOut FotOut
