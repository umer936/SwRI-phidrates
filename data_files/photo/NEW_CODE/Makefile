$(FC) = gfortran

photo : PhotRatM.o BBRad.o Convert.o  Initialize.o  ISRad.o  PltXsctn.o  RateCoeff.o  SolRad.o
	gfortran -o photo.exe PhotRatM.o BBRad.o Convert.o  Initialize.o  ISRad.o  PltXsctn.o  RateCoeff.o  SolRad.o

%.o %.mod: %.f95
	gfortran -M . -c -o $@ $< 

clean:
	rm *.o *.mod
