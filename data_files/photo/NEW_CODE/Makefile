FC = gfortran
FFLAGS = -g

photo : Branch.o BBRad.o Convert.o  InitializeF.o  ISRad.o PltXsctn.o RateCoeff.o  SolRad.o
	gfortran -o photo.exe InitializeF.o Branch.o BBRad.o Convert.o ISRad.o PltXsctn.o RateCoeff.o SolRad.o

%.o %.mod: %.f95
	gfortran -g -c -o $@ $< 

clean:
	rm -f *.o *.mod BBFlux.dat fort.* Summary replace RatOut Output EIoniz BrnOut EEOut FotOut
