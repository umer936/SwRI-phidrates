      Subroutine Convert(BSUM)
      integer, parameter :: LimA = 50000, LimB = 2000, LimF = 1000
      integer :: BSum, i, iCat, idiff, iFlag, inc, ind2, ind3, IOS16, 
     1  iPrnt, j, k, m2, m3, m4, maxBin, maxN, maxp3, n1, n2, nSets, 
     2  nSum, Numb, nF
      integer, dimension(16) :: Num, iFlg, Kat
      real (kind = 8) :: AvGen, ETot, EnElec, Flx, Rate, Thresh, 
     1  TRate, Wave1, Wave2, WaveL, XSect
      real (kind = 8), parameter :: AngeV = 12398.5     ! 12398.5 A = 1 eV
      real (kind = 8), dimension(16) :: Thrsh, TotRat, TotEEn
      real (kind = 8), dimension(9999) :: data
      real (kind = 8), dimension(LimA, 16) :: ExEn
      real (kind = 8), dimension(LimF) :: Flux
      real (kind = 8), dimension(LimF + 1) :: AngstF
      character*8 Name, Name1, Name2, Nam(16), NamCrs(16), NamPr
      character (len = 8) :: RadField
      character (len = 24) :: FMT3, FMT5 !, FMT6
      character (len = 38) :: FMT4
      COMMON /A/ Nam, Num, Kat, iFlg, Thrsh, nSets
      common /C/ AngstF, Flux, nF
      open(unit =  4, status = "replace")        ! Temporary file for wavelengths and cross sections.
      open(unit =  9, file = "EIoniz")           ! Binned rates and excess energies.
      open(unit = 16, status = "replace")        ! Temporary file.
      open(unit = 19, file = "EEOut")            ! Binned excess energy per Angstrom.
      open(unit = 20, file = "Summary")          ! Summary of rate coefficients and excess energies.

      FMT3 = "((a14, 2x, 00 (1x, a8)))"
      FMT4 = "((0pf7.1, 1x,    8x, 00 (1x, 1pe8.2)))"
      FMT5 = "((a16, 00 (1x, 1pe8.2)))"
!
      rewind(unit = 4)
      read(unit = 4, fmt = "(i3)") nSets         ! Scratch file for wavelengths & cross sections.
      ind3 = 0
      maxBin = 0
      iPrnt = 0
      k = 0
      do j = 1, 16
        NamCrs(j) = "        "
        TotRat(j) = 0.0
        TotEEn(j) = 0.0
        do i = 1, LimA
          ExEn(i, j) = 0.0
        end do
      end do
   10 continue
      iPrnt = iPrnt + 1
      k = k + 1
      read(unit = 16, fmt = "(i6)", iostat = IOS16) maxN
      if(IOS16 > 0) then
        write(unit = *, fmt = *) "Error unit = 16"
        stop
      else
        if(IOS16 < 0) then
          return
        end if
      end if
      if(maxN < 0) then
        return
      else
      end if
      if(maxN > 9999) then
        write(unit = *, fmt = *) "Stop (maxN > 9999)"
        stop
      else
      end if  
      maxBin = max(maxN, maxBin)
      Name = Nam(k)
      Numb = Num(k)
      iCat = Kat(k)
      iFlag = iFlg(k)
      Thresh = Thrsh(k)
      if (iFlag == 0) then
        nSum = nSum + maxN + 3
      else
      end if
      read(unit = 16, fmt = "(10x, 5e10.3, a8, 2x, a8)") (data(i), 
     1  i = 1, 5), Name1, Name2
      read(unit = 16, fmt = "(10x, 5e10.3)") (data(i), i = 6, maxN)
      if(iFlag == 1) then
      else
!
!.....Begin EIONIZ.....
!
        write(unit = 9, fmt = *) "Begin EIoniz"
        write(unit = 9, fmt = "(1x, 2i5, 11x, a8, 12x, a8)") Numb, iCat,
     1    Name1, Name2                           ! Unit 9 is EIoniz.
        write(unit = 9, fmt = "(a49, a18)") 
     1    "0   Wavelength Range X-Section    Flux      Rate ", 
     2    "    E Excess   Sum"
        NamPr = Name1
        NamCrs(iPrnt) = Name2
        if(nSets <= 0) then
          nSets = 1
        else
        end if
        m2 = nSets
        m3 = 1
        m4 = nSets
        if(iPrnt == 1) then
          write(unit = 19, fmt = "(i2, 49x, a8)") nSets, NamPr! Unit 19 is EEOut.
          write(unit = 20, fmt = "(a8)") NamPr                ! Unit 20 is Summary.
        else
        end if
        if(m2 < 10) then
          FMT3(13:13) = CHAR(m2 + 48)
          FMT3(12:12) = CHAR(48)
          FMT4(23:23) = CHAR(M2 + 48)
          FMT4(22:22) = CHAR(48)
          FMT5(9:9) = CHAR(M2 + 48)
          FMT5(8:8) = CHAR(48)
        else
          FMT3(13:13) = CHAR(M2 + 38)
          FMT3(12:12) = CHAR(M2/10 + 48)
          FMT4(23:23) = CHAR(M2 + 38)
          FMT4(22:22) = CHAR(M2/10 + 48)
          FMT5(9:9) = CHAR(M2 + 38)
          FMT5(8:8) = CHAR(M2/10 + 48)
        end if
        TRate = 0.0
        ETot = 0.0
        do i = 1, maxN
          Wave1 = AngstF(i)
          Wave2 = AngstF(i + 1)
          XSect = Data(i)
          Flx = Flux(i)
          Rate = XSect*Flx
      ! if (wave1.eq.0.) wave1=0.1
          if(Wave1 < 1.0E-06) then
            Wave1 = 0.1
          else if(Wave1 > Thresh) then
            Wave1 = Thresh
          else
          end if
          if(Wave2 > Thresh) then
            Wave2 = Thresh
          else
          end if
          WaveL = 2.0*Wave1*Wave2/(Wave1 + Wave2)
          EnElec = AngeV/WaveL - AngeV/Thresh
          TRate = TRate + Rate
          ExEn(i, iPrnt) = EnElec*Rate
          ETot = ETot + EnElec*Rate
          write(unit = 9, fmt = "(1x, 2f10.2, 1p3e10.3, 
     1    0pf10.2, 1pe10.3)") Wave1, Wave2, XSect, Flx, Rate, EnElec, 
     2    ETot
        end do
          AvgEn = ETot/TRate
        write(unit = 9, fmt = "(a1, 48X, a13, 1pe10.3)") "0", 
     1    "Total Rate = ", TRate
        write(unit = 9, fmt = "(45X, a17, f6.3)") "Average Energy = ", 
     1    AvgEn
          TotRat(iPrnt) = TRate
          TotEEn(iPrnt) = AvgEn
        do i = 1, maxN
          ExEn(i, iPrnt) = ExEn(i, iPrnt)/TRate
          if(ExEn(i, iPrnt) < 0.0) then
            ExEn(i, iPrnt) = 0.0
          end if
        end do
        do j = 1, nSets
          if(ExEn(maxN, j) < 0) then
            ExEn(maxN, j) = 0.0
          else
          end if
        end do
        if(iPrnt == nSets) then
          write(unit = 19, fmt = FMT3) " Lambda       ", 
     1      (NamCrs(j), j = m3, m4)
          write(unit = 19, fmt = FMT4) (AngstF(i), 
     1      (ExEn(i, j), j = 1, nSets), i = 1, maxBin)
          write(unit = 19, fmt = "(0PF7.1)") AngstF(maxBin + 1)
          write(unit = 19, fmt = FMT5) " Rate Coeffs. = ", (TotRat(j), 
     1      j = 1, nSets)
          write(unit = 20, fmt = FMT5) " Rate Coeffs. = ", (TotRat(j), 
     1      j = 1, nSets)                        ! Summary file.
          write(unit = 19, fmt = FMT5) " Av. Excess E = ", (TotEEn(j), 
     1      j = 1, nSets)
          write(unit = 20, fmt = FMT5) " Av. Excess E = ", (TotEEn(j), 
     1      j = 1, nSets)                        ! Summary file.
        else
        end if
!
!.....End EIoniz
!
      end if
      maxp3 = maxN + 3
      n2 = 0
      inc = 5
      ind2 = 117
      if(ind2 > maxp3) then
        ind2 = maxp3
      else
      end if
      ind3 = ind2 - 3
   50 continue
      n1 = n2 + 1
      n2 = n1 + inc
      if(n2 .lt. ind3) go to 50
      n2 = ind3
      iDiff = n2 - n1
      if(iDiff .eq. 0) go to 60
      if(n2 .eq. maxN) go to 10
      go to 80
   60 continue
   80 continue
      ind2 = ind2 + 114
      if(ind2 > maxp3) then
        ind2 = maxp3
      else
      end if
      ind3 = ind2 - 3
      go to 50
   90 continue
      return
      end Subroutine Convert
