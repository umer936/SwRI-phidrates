      Subroutine FotRat(iFirst)
!
! This subroutine computes photo rate coefficients in s^(-1)
!
      integer, parameter :: nSA = 162, LimA = 50000, LimB = 2000, 
     1  LimF = 1000
      integer :: i, ij, i1, iL, iFirst, IOS4, iPrnt, j, jL, jLm1, k, 
     1  Last, m2, m3, m4, maxN, maxPr, minPr, n, n1, nL, nPlot, nS, 
     2  nSets, nF
      real (kind = 4) :: SA
      real (kind = 8) :: aLast, Angst1, AngstL, x1, x2, T
      real (kind = 8), dimension(16) :: Rate
      real (kind = 8), dimension(nSA) :: FlxRat         ! Flux ratio of 
!                                                         active/quiet Sun
      real (kind = 8), dimension(nSA*2) :: FlxRatPl
      real (kind = 8), dimension(LimA) :: Sigma
      real (kind = 8), dimension(LimA + 1) :: Angsts, AngPl, Sigpl
      real (kind = 8), dimension(LimA + 2) :: Angx, XSct
      real (kind = 8), dimension(LimF) :: Flux
      real (kind = 8), dimension(LimF + 1) :: AngstF
      real (kind = 8), dimension(LimB) :: XSecPu, X, XTotPu, FlxPlt
      real (kind = 8), dimension(LimB + 1) :: XSctPl, RatePl, AngPlt, 
     1  PhotFlx
      real (kind = 8), dimension(LimA, 16) :: XSctn, RateC
      character (len = 3) :: BB, IS, RadField, Sol
      character (len = 8) :: NamPr
      character (len = 8), dimension(2) :: Name
      character (len = 8), dimension(16)  :: NamCrs
      character (len = 24) :: FMT1, FMT3
      character (len = 45) :: FMT2
      common Name, RadField, idxaxs, idyaxs
      common /C/ AngstF, Flux, nF
      open(unit =  3, file = "RatOut")               ! Binned rate coefficients per Angstrom.
!      open(unit =  4, status = "replace")            ! Temporary file for wavelengths and cross sections.
      open(unit = 15, file = "FotOut")               ! Binned Cross Sections.
!      open(unit = 16, status = "replace")            ! Temporary file.
!
      FMT1 = "((a14, 2x, 00 (1x, a8)))"
      FMT2 = "((0pf7.1, 1x,    8x , 00 (1x, 1pe9.2e3)))"
      FMT3 = "((a16, 00 (1x, 1pe8.2)))"
      do i = 1, LimB
        xTotPu(i) = 0.0
        do j = 1, 16
          XSctn(i, j) = 0.0
          RateC(i, j) = 0.0
        end do
      end do
!
! Read temporary file for wavelengths and cross sections.
!
      read(unit = 4, fmt = "(i3)") nSets
      minpr = 10000
      maxpr = 0
      iprnt = 0
      do i = 1, 16
        Rate(i) = 0.0
        NamCrs(i) = "        "
      end do
!
! Depending on the type of flux, read file with flux data.     
!

!      idyaxs = 2
!      idxaxs = 1
!      if(iFirst .eq. 0) call pltxsct(j, angplt, flxplt)
!      idxaxs = 0
!
!      if(iFirst .eq. 0) call pltxsct(j, angplt, flxplt)
!      idyaxs=3
!      if(iFirst .eq. 0) call pltxsct(j, angplt, flxratpl)
      iFirst = 1
   50 nampr = name(1)
      Last = 1
      do i = 1, LimB
        x(i) = 0.0
        XSecPu(i) = 0.0
      end do
      do i = 1, 3000
        Sigma(i) = 0.0
      end do
      do i = 1, 3001
        Angsts(i) = 0.0
        AngPl(i) = 0.0
        SigPl(i) = 0.0
      end do
      do i = 1, limB + 1
        XSctPl(i) = 0.0
        RatePl(i) = 0.0
      end do
!
! Read temporary file for wavelengths and cross sections.
!
      read(unit = 4, fmt = "(i10, 2f10.2, a8, 2x, a8)", iostat = IOS4) 
     1  nS, Angst1, AngstL, (Name(i), i = 1, 2)
      if (IOS4 > 0) then
        write (unit = *, fmt = *) "Error unit 4 in subroutine RateCoeff"
        stop
      else
        if(IOS4 < 0) then
          go to 300
        else
        end if
      end if
      iPrnt = iPrnt + 1
      Namcrs(iPrnt) = Name(2)
      if(nS < 0) then
        return
      else
      end if
!
! Read temporary file for wavelengths and cross sections.
!
      read(unit = 4, fmt = "(0pf10.2, 1pe10.2)")
     1  (Angsts(i), Sigma(i), i=1, nS)
      do i=1, nS
        if(Sigma(i) <= 1.e-30) then
          SigPl(i) = -30.
        else
          SigPl(i) = dlog10(Sigma(i))
        end if
      end do
      if(Angst1 - AngstL >= -1.e-6) GO TO 370  ! Changed 1.e-6 to -1.e-6
      if(Angst1 < AngstF(1)) GO TO 370
      if(AngstL > AngstF(nF)) GO TO 370
      Rate(iPrnt) = 0.0
      n1 = 0
      nL = 0
      do i = 1, nF
        if(AngstF(i) - Angst1 <= 1.e-6) then
          n1 = i
        else
        end if
        if(AngstF(i) < AngstL) then
          nL = i
        else
        end if
      end do
      if(n1 < minpr) then
        minpr = n1
      else
      end if
      if(nL > maxpr) then
        maxpr = nL
      else
      end if
      if(nL <= n1) GO TO 370
!
! Interpolate cross sections.
!
      i1 = 1
      j = 1
      n = n1 + 1
      iL = nS
      Angx(1) = Angst1
      XSct(1) = Sigma(1) - (Sigma(2) - Sigma(1))*(Angsts(1) - Angst1)/
     1  (Angsts(2) - Angsts(1))
      if(XSct(1) < 1.e-30) then
        XSct(1) = 1.e-30
      else
      end if
      do i = i1, iL
        do
          j = j + 1
          if(Angsts(i) - AngstF(n) < -1.e-6) then
            Angx(j) = Angsts(i)
            XSct(j) = Sigma(i)
            exit
          else if(abs(Angsts(i) - AngstF(n)) <= 1.e-6) then
            Angx(j) = Angsts(i)
            XSct(j) = Sigma(i)
            n = n + 1
            exit
          else
            Angx(j) = AngstF(n)
            XSct(j) = XSct(j - 1) + (Sigma(i) - XSct(j - 1))*
     1        (AngstF(n) - Angx(j - 1))/(Angsts(i) - Angx(j - 1))
            n = n + 1
          end if
        end do
      end do
      if(n <= nL) then
        do i = n, nL
          j = j + 1
          Angx(j) = AngstF(i)
          XSct(j) = Sigma(nS - 1) + (Sigma(nS) - Sigma(nS - 1))*
     1      (AngstF(i) - Angsts(nS - 1))/(Angsts(nS) - Angsts(nS - 1))
          if(XSct(j) < 1.e-30) then
            XSct(j) = 1.e-30
          else
          end if
        end do
      end if
      jL = j + 1
      Angx(jL) = AngstL
      XSct(jL) = Sigma(nS - 1) + (Sigma(nS) - Sigma(nS - 1))*
     1  (AngstL - Angsts(nS - 1))/(Angsts(nS) - Angsts(nS - 1))
      if(XSct(jL) < 1.e-30) then
        XSct(jL) = 1.e-30
      else
      end if
      jLm1 = jL - 1
      n = n1
      maxN = n1 - 1
!      write(unit = *, fmt = *) " maxN=", maxN
      x(n) = 0.0
      x1 = 0.5*XSct(1)
!
! Compute cross section per Angstrom for each bin.
!
      do j = 1, jLm1
        x2 = 0.5*XSct(j + 1)
        x(n) = x(n) + (x1 + x2)*(Angx(j + 1 ) - Angx(j))
        x1 = x2
        if(j == jLm1) then
          XSctn(n, iPrnt) = x(n)/(AngstF(n + 1) - AngstF(n))
          XSecPu(n) = XSctn(n, iPrnt)
          if(XSecPu(n) <= 1.d-30) then
            Last = Last + 1
            if(XSctn(n, iPrnt) < 0.0) then
              XSctn(n, iPrnt) = 0.0
            else
              if(XSctn(n, iPrnt) < 1.d-30) then
                XSctn(n, iPrnt) = 1.d-35
              else
              end if
            end if
          else
          end if
          RateC(n, iPrnt) = XSctn(n, iPrnt)*Flux(n)
        else
          if(Angx(j + 1) >= AngstF(n + 1)) then             ! This and the following 9 lines were not in Phidrats
            XSctn(n, iPrnt) = x(n)/(AngstF(n + 1) - AngstF(n))
            RateC(n, iPrnt) = XSctn(n, iPrnt)*Flux(n)
            XSecPu(n) = XSctn(n, iPrnt)
            if(XSecPu(n) > 1.e-30) then
              Last = 0
            else
              Last = Last + 1
            end if
            Rate(iPrnt) = Rate(iPrnt) + XSctn(n, iPrnt)*Flux(n)
            n = n + 1
            x(n) = 0.0
          else
            cycle  
         end if
        end if
      end do
      maxN = n - Last   ! maxN is the subscript of last non-zero cross section.
      i = 1
      do n = n1, nL
        AngPl(i) = AngstF(n)
        AngPl(i + 1) = AngstF(n + 1)
        if(XSctn(n, iprnt) > 1.e-30 .and. XSctn(n, iPrnt)*Flux(n) > 
     1      1.e-30) then
          XSctPl(i) = dlog10(XSctn(n, iPrnt))
          RatePl(i) = dlog10(XSctn(n, iPrnt)*Flux(n)/(AngPl(i+1) - 
     1      AngPl(i)))
        else
          XSctPl(i) = -30.
          RatePl(i) = -30.
        end if
        XSctPl(i + 1) = XSctPl(i)
        RatePl(i + 1) = RatePl(i)
        i = i + 2
      end do
      nPlot = i - 1
      idyaxs = 1
      call PltXSct(nS, Angsts, SigPl)
      call PltXSct(nPlot, AngPl, XSctPl)
      idyaxs = 0
      call PltXSct(nPlot, AngPl, RatePl)
      write(unit = 16, fmt = "(i6)") maxN
      do i = 1, maxN, 5
        ij = i + 4
        write(unit = 16, fmt = "(f7.0, 3x, 1p5e10.3, a8, 2x, a8)") 
     1    AngstF(i), (XSecPu(j), j = i, ij), (Name(k), k = 1, 2)
      end do
      if (nSets > iPrnt) then
        go to 50
      else
      end if
  300 continue
      Nampr = Name(1)
      if(nSets <= 0) then
        nSets = 1
      else
      end if
      m2 = nSets
      m3 = 1
      m4 = nSets
      write(unit = 15, fmt = "(i2, 49x, a8)") nSets, NamPr ! unit 15 is FotOut
      write(unit = 3, fmt = "(i2, 49x, a8)") nSets, NamPr  ! unit 3 is RatOut.
      if(m2 < 10) then
        FMT1(13:13) = CHAR(m2 + 48)
        FMT1(12:12) = CHAR(48)
        FMT2(24:24) = CHAR(m2 + 48)
        FMT2(23:23) = CHAR(48)
        FMT3(9:9) = CHAR(m2 + 48)
        FMT3(8:8) = CHAR(48)
      else
        FMT1(13:13) = CHAR(m2 + 38)
        FMT1(12:12) = CHAR(m2/10 + 48)
        FMT2(24:24) = CHAR(m2 + 38)
        FMT2(23:23) = CHAR(m2/10 + 48)
        FMT3(9:9) = CHAR(m2 + 38)
        FMT3(8:8) = CHAR(m2/10 + 48)
      end if
      write(unit = 15, fmt = FMT1) " Lambda       ", (NamCrs(j), 
     1  j = m3, m4)                    ! FOTOUT:  Binned Cross Section.
      write(unit = 3, fmt = FMT1) " Lambda       ", (NamCrs(j), 
     1  j = m3, m4)                    ! RATOUT:  Binned rate coefficient per Angstrom.
      write(unit = 15, fmt = FMT2) (AngstF(i), 
     1  (XSctn(i, j), j = m3, m4), i = minPr, maxPr)
      write(unit = 3, fmt = FMT2) (AngstF(i), 
     1  (RateC(i, j), j = m3, m4), i = minPr, maxPr)
      write(unit = 15, fmt = "(0pf7.1)") AngstF(maxPr + 1)
      write(unit = 3, fmt = "(0pf7.1)") AngstF(maxPr + 1)
      do j = m3, m4
        if(Rate(j) < 1.0d-99) then
          Rate(j) = 0.0
        else
        end if
      end do
      write(unit = 3, fmt = FMT3) " Rate Coeffs. = ", (Rate(j), 
     1  j = m3, m4)
      aLast = 0.0
      do i = 1, nF
        do j = 1, 16
          XTotPu(i) = XTotPu(i) + XSctn(i, j)
          XSctn(i, j) = 0.0
        end do
        if(XTotPu(i) == 0.0) then
          if(aLast < 1.e-40) then
            maxN = i - 1
          else
          end if
        else
          aLast = XTotPu(i)
        end if
      end do
      write(unit = 16, fmt = "(i6)") maxN
!      write(unit = *, fmt = "(i6)") maxN
      do i = 1, maxN, 5
        ij = i + 4
        write(unit = 16, fmt = "(f7.0, 3x, 1p5e10.3, 10x, a8)") 
     1    AngstF(i), (XTotPu(j), j = i, ij), NamPr
!        write(unit = *, fmt = "(f7.0, 3x, 1p5e10.3, a8, 2x, a8)") 
!     1    AngstF(i), (XSecPu(j), j = i, ij), (Name(k), k = 1, 2)
      end do
      do i = 1, 16
        Rate(i) = 0.0
        NamCrs(i) = "        "
      end do
      do i = 1, nF
        XTotPu(i) = 0.0
      end do
      minpr = 10000
      maxpr = 0
      iprnt = 1
      return
  370 continue
      write(unit = 15, fmt = "(1x, 2(a8, 2x), 1x, a12/a12, 9x, a13,
     1  f10.2, a18, f10.2/22x, a5, i5/a31, f10.2, a11, f10.2/ 22x, a5, 
     2  i5, a7, i5, a7, i5)") 
     3  (Name(i), i=1,2), "input error", "Flux values: ", 
     4  "AngstF(1) = ", AngstF(1), ", AngstF(nF + 1) = ", 
     5  AngstF(nF + 1), "nF = ", nF, "Cross section values: Angst1 = ", 
     6  Angst1, ", AngstL = ", AngstL, "nS = ", nS, ", n1 = ", n1, ", 
     7  nL = ", nL
      go to 50
      return
      end Subroutine FotRat
