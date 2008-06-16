C     Last change:  WH    8 May 100    2:57 pm
      PROGRAM PHOTO
C
C     This code is a synthesis of the codes BRANCH, FOTRAT,
C     CONVERT, XSECTN, and EIONIZ.
C
      DATA IFIRST, IEND, NSUM /0, 0, 0/
      OPEN(1, FILE='HREC', STATUS='OLD')
      OPEN(2, FILE='BRNOUT')
      OPEN(4, STATUS='SCRATCH')
      OPEN(5, FILE='RATOUT')
C     RATOUT = Binned Rate Coefficient per Angstrom
      OPEN(9, FILE='EIONIZ')
      OPEN(10, FILE='PHFLUX.DAT', STATUS='OLD')
      OPEN(15, FILE='FOTOUT')
C     FOTOUT = Binned Cross Section
      OPEN(16, STATUS='SCRATCH')
      OPEN(19, FILE='EEOUT')
C     EEOUT = Binned Excess Energy per Angstrom
   10 CALL BRANCH(IEND)
      IF (IEND .EQ. 1) GO TO 20
      REWIND 4
      CALL FOTRAT(IFIRST)
      REWIND 16
      CALL CONVERT(NSUM)
      REWIND 4
      REWIND 16
      GO TO 10
   30 FORMAT (I5)
   20 END

      SUBROUTINE BRANCH(IEND)
C     This Subroutine Aportions Cross Sections for Each Branch
      LOGICAL LIMIT
      CHARACTER*8 ITEXT(10), ASTER, AST3, MOTHER(2), NAM(16),
     1   IPROD(2), LASTN
      CHARACTER*39 FMT1
      CHARACTER*39 FMT2
      DIMENSION ANGSTS(3001), SIGMA(3000), ANGSTB(2001), BR(2001),
     1   BRPR(3000), TOT(3000), TABBRP(3000,16), TABSIG(3000, 16)
      COMMON /A/ NAM, NUM(16), KAT(16), IFLG(16), THRSH(16), NSETS
      DATA FMT1 /'(('' Lambda  Sigma'', 2X, 00(1X, A8)))'/
      DATA FMT2 /'((0PF7.1, 1X, 1PE8.2, 00(1X, 1PE8.2)))'/
C     Initialize subroutine
      AST3 = '***'
      LIMIT = .FALSE.
      M = 0
      DO 10 I=1,16
   10 IFLG(I) = 0
      DO 20 I=1,3000
      TOT(I) = 0
      DO 20 J=1,16
      TABBRP(I, J) = 0
   20 TABSIG(I, J) = 0
C     Read mother molecule information
      READ(1, 220, IOSTAT=IOS1) NS, ANGST1, ANGSTL, (MOTHER(I), I=1,2),
     1     NUM(1), KAT(1)
      IF(IOS1) 30, 50, 40
   30 IEND = 1
      RETURN
   40 STOP 'ERROR1'
   50 IF(NUM(1) .NE. 0) NAM(1) = MOTHER(2)
      THRSH(1) = ANGSTL
      WRITE(2, 180) (MOTHER(I),I=1,2)
C     Read references for mother molecule
   60 READ(1, 190) (ITEXT(I), I=1,10)
      WRITE(2, 190) (ITEXT(I), I=1,10)
      IF(ITEXT(1) .NE. ITEXT(2) .OR. ITEXT(2) .NE. '        ') GO TO 60
C     Read wavelengths and cross sections for mother molecule
      READ(1, 230) (ANGSTS(I), SIGMA(I), I=1,NS)
C     Read the number of branching sets that follow
      READ(1, 240) NSETS
      NAM(NSETS+2) = MOTHER(1)
      NUM(NSETS+2) = 0
      KAT(NSETS+2) = 0
      IFLG(NSETS+2) = 1
C     If there are no branching sets, skip to 130
      IF(NSETS .EQ. 0) GO TO 130
      IT = NSETS + 1
C     Write total number of branches (nsets+1)
      WRITE(4, 240) IT
C     Read information for a branching set
   70 READ(1, 220) NB, ANGSTB1, ANGSTBL, (IPROD(I), I=1,2), NUM(M+1),
     1   KAT(M+1)
      THRSH(M+1) = ANGSTBL
      M = M + 1
      NAM(M) = IPROD(2)
      WRITE(2, 180) (IPROD(I), I=1,2)
C     Read references for a branching set
   80 READ(1, 190) (ITEXT(I), I=1,10)
      WRITE(2, 190) (ITEXT(I), I=1,10)
      IF(ITEXT(1) .NE. ITEXT(2) .OR. ITEXT(2) .NE. '        ') GO TO 80
C     Set ang1=max(angst1,angstb1); angl=min(angstl,angstbl)
      ANG1 = ANGST1
      ANGL = ANGSTL
      IF(ANGSTB1 .GT. ANG1) ANG1 = ANGSTB1
      IF (ANGSTBL .LT. ANGL) ANGL = ANGSTBL
c     Read pairs of wavelengths & sigmas for branching set
      READ(1, 230) (ANGSTB(I), BR(I), I=1,NB)
      J = 1
C     For each wavelength of the mother species calculate a new
C        cross section (sigma) for each branch.
      DO 110 I=1,NS
      ANGSTI = ANGSTS(I)
   90 CONTINUE
      IF(ANGSTI .GT. ANGSTB(J+1) .AND. .NOT. LIMIT) GO TO 100
      IF(ANGSTI .EQ. ANGSTB(J+1)) BRPR(I) = BR(J+1)
      IF(ANGSTI .NE. ANGSTB(J+1)) BRPR(i) = BR(J) + (BR(J+1) - BR(J))*
     1   ((ANGSTI - ANGSTB(J))/(ANGSTB(J+1) - ANGSTB(J)))
      IF(LIMIT) BRPR(I) = 0.
      TOT(I) = TOT(I) + BRPR(I)
      TABSIG(I,M) = BRPR(I)*SIGMA(I)
      TABBRP(I,M) = BRPR(I)
      GO TO 110
C     Find the smallest wavelength of the branching set which is greater
C     than the wavelength of the mother species.
  100 CONTINUE
      J = J + 1
C     Check if the limit is reached
      if (j+1.ge.nb.and.angsti.gt.angstb(nb)) limit=.true.
      go to 90
  110 continue
      WRITE(4, 210) NS, ANG1, ANGL, MOTHER(1), IPROD(2)
      WRITE(4, 230) (ANGSTS(I), TABSIG(I,M),I=1,NS)
c     if there are more branching sets, loop back and do it again
      if (m.ne.nsets) go to 70
      nsets=nsets+1
      read (1,220) ndum,dum,thrsh(nsets),iprod(1),lastn,num(nsets),kat
     1 (nsets)
      nam(nsets)=lastn
c     nsets+1 is total no. of branches - calculcate final branch here
      do 120 i=1,ns
      ttemp=1.-tot(i)
      if (ttemp.lt.0) PRINT '(A, E12.3, A, E12.5)', 'TTEMP < 0: ',
     1                TTEMP, ' AROUND WAVELENGTH: ', ANGSTS(I)
      if (ttemp.lt.0) tabbrp(i,nsets)=0.
      IF (TTEMP .LT. 1.00E-07) TTEMP = 0.0
      if (ttemp.ge.0) tabbrp(i,nsets)=ttemp
      tabsig(i,nsets)=tabbrp(i,nsets)*sigma(i)
  120 continue
      WRITE(4, 210) NS, ANGST1, ANGSTL, MOTHER(1), LASTN
      WRITE(4, 230) (ANGSTS(I), TABSIG(I,NSETS),I=1,NS)
      go to 140
  130 continue
c     if there are no br. sets, mother molecule is the only "branch"
      WRITE(4, 240) NSETS
      WRITE(4, 210) NS, ANGST1, ANGSTL, (MOTHER(I),I=1,2)
      WRITE(4, 230) (ANGSTS(I), SIGMA(I),I=1,NS)
  140 continue
  150 read (1,260) aster
      if (aster.ne.AST3) go to 150
      n1=nsets
      n2=1
      n3=nsets
  155 IF(N1 .LT. 10) FMT1(26:26) = CHAR(N1 + 48)
      IF(N1 .LT. 10) FMT1(25:25) = CHAR(48)
      IF(N1 .GE. 10) FMT1(26:26) = CHAR(N1 + 38)
      IF(N1 .GE. 10) FMT1(25:25) = CHAR(N1/10 + 48)
      IF(N1 .LT. 10) FMT2(24:24) = CHAR(N1 + 48)
      IF(N1 .LT. 10) FMT2(23:23) = CHAR(48)
      IF(N1 .GE. 10) FMT2(24:24) = CHAR(N1 + 38)
      IF(N1 .GE. 10) FMT2(23:23) = CHAR(N1/10 + 48)
      WRITE(2, 290) (MOTHER(J),J=1,2), NSETS
      if (nsets.le.0) go to 160
      WRITE(2, FMT1) (NAM(I),I=N2,N3)
      WRITE(2, FMT2) (ANGSTS(I), SIGMA(I), (TABSIG(I,J),J=n2,n3),I=1,NS)
      GO TO 170
  160 CONTINUE
      WRITE(2, '(''  Lambda   Sigma '')')
      WRITE(2, 310) (ANGSTS(I), SIGMA(I),I=1,NS)
  170 continue
      RETURN
  180 FORMAT ('0          References for Cross Section of ', A8, 2X, A8)
  190 FORMAT (10A8)
  210 format (i10,2f10.2,a8,2x,a8)
  220 format (i10, 2f10.2, 2(1X, A8), 2i3)
  230 format (0pf10.2,1pe10.2)
  240 format (i3)
  260 format (a8)
  290 FORMAT ('0 Branching ratio for',(2(1X, A8)), 4X, I2,' Branches')
  310 format (0pf8.2,1x,1pe9.2)
      END

      SUBROUTINE FOTRAT(IFIRST)
C     This Subroutine Computes Photo Rate Coefficients in s^(-1)
      CHARACTER*8 NAME(2), NAMCRS(16), NAMPR
      CHARACTER*39 FMT1
      CHARACTER*39 FMT2
      CHARACTER*45 FMT3
      DIMENSION ANGSTF(1001), FLUX(1000), ANGSTS(3001), SIGMA(3000),
     1 XSECPU(2000), XSCT(4002), ANGX(4002), XSCTN(3000,16),
     2 ANGPL(3001), X(2000), XSCTPL(2001), RATEPL(2001), SIGPL(3001),
     3 XTOTPU(2000), RATE(16), ANGPLT(2001), FLXPLT(2000),
     4 FLXRATPL(324), RATEC(3000,16)
      common /b/ radflx(2001), flxrat(162), sa
      common name, idxaxs, idyaxs
*      DATA FMT1 /'(('' Lambda  Sigma'', 2X, 00(1X, A8)))'/
      DATA FMT1 /'(('' Lambda       '', 2X, 00(1X, A8)))'/
*      DATA FMT2 /'((0PF7.1, 1X, 1PE8.2, 00(1X, 1PE8.2)))'/
      DATA FMT2 /'((0PF7.1, 1X,    8X , 00(1X, 1PE8.2)))'/
      DATA FMT3 /'(('' Rate Coeffs. = '', 00(1X, 1PE8.2)))'/
C     NEXT 3 lines for diagnostic print only.  Not set up for plotting
*      DATA FMT1 /'((''0Wavelength    Total    '', 0(2X, A8, 2X)))'/
*      DATA FMT2 /'((0PF10.2, 0(1PE12.3)))'/
*      DATA FMT3 /'((''0Photo Rate Coeffs. = '', 0(1PE12.3)))'/
*      OPEN(FILE='SCR16', UNIT=16, STATUS='UNKNOWN')            !NEW
*    5 IF(IFIRST .EQ. 0) WRITE(6, '('' Enter Solar Activity:'',
*     1  '' (F4.2), Quiet Sun = 0.00 < SA < Active Sun = 1.00.'' /
*     2  '' SA = '')')
*      if(ifirst .eq. 0) READ '(F4.2)', SA
*      if(sa .lt. 0.) go to 5
      if(ifirst .ne. 0) GO TO 5
      READ(10, 510) (RADFLX(I), RADFLX(I+1), I=1,648,2)
      READ(10, 511) RADFLX(649)
*      READ(11, 512) (FLXRAT(I+1), I=1,162,2)
*      READ(3, 513) SA
      close (UNIT=10)
*      close (UNIT=11)
*      close (UNIT=3)
*      do 10 i=1,1000
    5 do 10 i=1,1000
      flux(i)=0.
   10 continue
      do 20 i=1,2000
      xtotpu(i)=0.
      do 20 j=1,16
      xsctn(i,j)=0.
      RATEC(i,j)=0.
   20 continue
      read (4, 390) nsets
      minpr=10000
      maxpr=0
      iprnt=0
      do 30 i=1,16
      rate(i)=0.
      namcrs(i) = '        '
   30 continue
      nf=324
      do 40 i=1,nf
      j=2*i
      angstf(i)=radflx(j-1)
      if(j .ne. 2) go to 35
      angplt(1) = 0.
      go to 36
   35 angplt(j-1) = alog10(radflx(j-1))
   36 angplt(j) = alog10(radflx(j+1))
      flxplt(j-1) = alog10(radflx(j)/(radflx(j+1)-radflx(j-1)))
      flxplt(j) = flxplt(j-1)
   38 continue
      flux(i)=radflx(j)
*      if(i .lt. 163) flux(i)=radflx(j) + sa*(flxrat(i) - 1.)*radflx(j)
   40 continue
      angstf(nf+1)=radflx(2*nf+1)
      idyaxs=2
      idxaxs=1
      if(ifirst .eq. 0) call pltxsct (j,angplt,flxplt)
      idxaxs=0
      do 45 i=1,162
      j=2*i
      angplt(j-1) = radflx(j-1)
      angplt(j) = radflx(j+1)
   45 continue
      if(ifirst .eq. 0) call pltxsct(j,angplt,flxplt)
      do 48 i=1,162
      j=2*i
      flxratpl(j-1) = flxrat(i)
      flxratpl(j) = flxrat(i)
   48 continue
      idyaxs=3
      if(ifirst .eq. 0) call pltxsct(j,angplt,flxratpl)
      ifirst = 1
   50 nampr=name(1)
      last=1
      do 60 i=1,2000
      x(i)=0.
      xsecpu(i)=0.
   60 continue
      do 65 i=1,3000
      sigma(i)=0.
   65 continue
      do 70 i=1,3001
      angsts(i)=0.
      angpl(i)=0.
      sigpl(i)=0.
   70 continue
      do 80 i=1,2001
      xsctpl(i)=0.
      ratepl(i)=0.
   80 continue
      read (4, 400, IOSTAT=IOS4) ns, angst1, angstl, (name(i),i=1,2)
      if (IOS4) 300, 90, 85
   85 STOP 'ERROR4'
   90 continue
      iprnt=iprnt+1
      if (iprnt.eq.1) go to 100
      if (iprnt.gt.16) go to 300
  100 continue
      namcrs(iprnt)=name(2)
      if (ns.lt.0) go to 380
      read (4, 410) (angsts(i),sigma(i),i=1,ns)
      do 110 i=1,ns
      if (sigma(i) .LE. 1.E-50) sigpl(i)=-50.
      if (sigma(i). GT. 1.E-50) sigpl(i)=alog10(sigma(i))
  110 continue
      if (angst1.ge.angstl) go to 370
      if (angst1.lt.angstf(1)) go to 370
      if (angstl.gt.angstf(nf+1)) go to 370
      rate(iprnt)=0.
      n1=0
      nl=0
      do 120 i=1,nf
      if (angstf(i).le.angst1) n1=i
      if (angstf(i).lt.angstl) nl=i
  120 continue
      if (n1.lt.minpr) minpr=n1
      if (nl.gt.maxpr) maxpr=nl
      if (nl.le.n1) go to 370
C.....Interpolate cross sections
      i1=1
      j=1
      n=n1+1
      il=ns
      angx(1)=angst1
      xsct(1)=sigma(1)-(sigma(2)-sigma(1))*(angsts(1)-angst1)/(angsts(2)
     1 -angsts(1))
c     if (xsct(1).le.0..or.angst1.eq.0.) xsct(1)=1.e-50
      if (angsts(1).eq.angst1) i1=2
      if (angsts(ns).eq.angstl) il=ns-1
      do 170 i=i1,il
  130 continue
      j=j+1
      if (angsts(i)-angstf(n)) 140,150,160
  140 continue
      angx(j)=angsts(i)
      xsct(j)=sigma(i)
      go to 170
  150 continue
      angx(j)=angsts(i)
      xsct(j)=sigma(i)
      n=n+1
      go to 170
  160 continue
      angx(j)=angstf(n)
      xsct(j)=xsct(j-1)+(sigma(i)-xsct(j-1))*(angstf(n)-angx(j-1))/
     1 (angsts(i)-angx(j-1))
      n=n+1
      go to 130
  170 continue
      if (n.gt.nl) go to 190
      do 180 i=n,nl
      j=j+1
      angx(j)=angstf(i)
      xsct(j)=sigma(ns-1)+(sigma(ns)-sigma(ns-1))*(angstf(i)-angsts(ns-1
     1 ))/(angsts(ns)-angsts(ns-1))
c     if (xsct(j).le.0.) xsct(j)=1.e-50
  180 continue
  190 continue
      jl=j+1
      angx(jl)=angstl
      xsct(jl)=sigma(ns-1)+(sigma(ns)-sigma(ns-1))*(angstl-angsts(ns-1))
     1 /(angsts(ns)-angsts(ns-1))
c     if (xsct(jl).le.0.) xsct(jl)=1.e-50
      jlm1=jl-1
      n=n1
      MAXN=n1-1
      x(n)=0.
      x1=0.5*xsct(1)
c.....compute cross section for each bin
      do 250 j=1,jlm1
      x2=0.5*xsct(j+1)
      x(n)=x(n)+(x1+x2)*(angx(j+1)-angx(j))
      x1=x2
      if (j.eq.jlm1) go to 200
      if (angx(j+1).lt.angstf(n+1)) go to 250
  200 continue
      xsctn(n,iprnt)=x(n)/(angstf(n+1)-angstf(n))
      RATEC(n,iprnt)=xsctn(n,iprnt)*flux(n)
      xsecpu(n)=xsctn(n,iprnt)
      if (xsecpu(n).ne.0) last=0
      if (xsecpu(n).eq.0) last=last+1
      rate(iprnt)=rate(iprnt)+xsctn(n,iprnt)*flux(n)
      if (j.eq.jlm1) go to 250
      n=n+1
      x(n)=0.
  250 continue
      MAXN=n-last
c.....MAXN is subscript of last non-zero cross section
      i=1
      do 280 n=n1,nl
      angpl(i)=angstf(n)
      angpl(i+1)=angstf(n+1)
c     if (xsctn(n,iprnt).eq.0.) xsctn(n,iprnt)=1.e-50
      if (xsctn(n,iprnt).le. 1.E-50) go to 260
      xsctpl(i)=alog10(xsctn(n,iprnt))
      ratepl(i)=alog10(xsctn(n,iprnt)*flux(n)/(angpl(i+1)-angpl(i)))
      go to 270
  260 continue
      xsctpl(i)=-50.
      ratepl(i) = -50.
  270 continue
      xsctpl(i+1)=xsctpl(i)
      ratepl(i+1)=ratepl(i)
      i=i+2
  280 continue
      nplot=i-1
      idyaxs=1
      call pltxsct (ns,angsts,sigpl)
      call pltxsct (nplot,angpl,xsctpl)
      idyaxs=0
      call pltxsct (nplot,angpl,ratepl)
      WRITE(16, 420) MAXN
      do 290 i=1,MAXN,5
      ij=i+4
      WRITE(16, 430) ANGSTF(I), (XSECPU(J),J=I,IJ), (NAME(K),K=1,2)
  290 continue
      if (nsets-iprnt) 300,300,50
  300 continue
      nampr=name(1)
      if (nsets.le.0) nsets=1
      m1=nsets+1
      m2=nsets
      m3=1
      m4=nsets
*      if (nsets.le.8) go to 301
*      M1=9
*      M2=8
*      M4=8
*  301 WRITE(15, 440) NAMPR
  301 WRITE(15, 440) nsets, NAMPR
      WRITE(5, 440) nsets, NAMPR
C      PRINT *, NAMPR
C      encode (30,450,fmt2) m1
C      encode (48,460,fmt1) m2
      IF(M2 .LT. 10) FMT1(26:26) = CHAR(M2 + 48)
      IF(M2 .LT. 10) FMT1(25:25) = CHAR(48)
      IF(M2 .GE. 10) FMT1(26:26) = CHAR(M2 + 38)
      IF(M2 .GE. 10) FMT1(25:25) = CHAR(M2/10 + 48)
      IF(M2 .LT. 10) FMT2(24:24) = CHAR(M2 + 48)
      IF(M2 .LT. 10) FMT2(23:23) = CHAR(48)
      IF(M2 .GE. 10) FMT2(24:24) = CHAR(M2 + 38)
      IF(M2 .GE. 10) FMT2(23:23) = CHAR(M2/10 + 48)
      IF(M2 .LT. 10) FMT3(23:23) = CHAR(M2 + 48)
      IF(M2 .LT. 10) FMT3(22:22) = CHAR(48)
      IF(M2 .GE. 10) FMT3(23:23) = CHAR(M2 + 38)
      IF(M2 .GE. 10) FMT3(22:22) = CHAR(M2/10 + 48)
*      FMT1(30:30) = CHAR(M2 + 48)
*      IF(M2 .GE. 10) FMT1(29:29) = CHAR(M2/10 + 48)
      WRITE(15, FMT1) (NAMCRS(J),J=M3,M4)
      WRITE(5, FMT1) (NAMCRS(J),J=M3,M4)
*      FMT2(12:12) = CHAR(M1 + 48)
*      IF(M1 .GE. 10) FMT2(11:11) = CHAR(M1/10 + 48)
*      WRITE(15, FMT2) (ANGSTF(I), FLUX(I), (XSCTN(I,J),J=M3,M4),i=minpr
*      WRITE(15, FMT2) (ANGSTF(I), SIGMA(I), (XSCTN(I,J),J=M3,M4),i=minpr
*     1 ,maxpr)
      WRITE(15, FMT2) (ANGSTF(I),           (XSCTN(I,J),J=M3,M4),i=minpr
     1 ,maxpr)
      WRITE(5, FMT2) (ANGSTF(I),           (RATEC(I,J),J=M3,M4),i=minpr
     1 ,maxpr)
      WRITE(15, 470) ANGSTF(MAXPR+1)
      WRITE(5, 470) ANGSTF(MAXPR+1)
C      encode (40,480,fmt3) m2
*      FMT3(29:29) = CHAR(M2 + 48)
*      IF(M2 .GE. 10) FMT3(28:28) = CHAR(M2/10 + 48)
      WRITE(5, FMT3) (RATE(J),J=M3,M4)
C      if (nsets.le.8) go to 302
C      if (m3.ne.1) go to 302
C      m1=nsets-7
C      m2=nsets-8
C      m3=9
C      m4=nsets
C      go to 301
  302 alast=0.
      do 330 i=1,324
      do 310 j=1,16
      xtotpu(i)=xtotpu(i)+xsctn(i,j)
      xsctn(i,j)=0.
  310 continue
      if (xtotpu(i).ne.0) go to 320
      if (alast.ne.0) MAXN=i-1
  320 continue
      alast=xtotpu(i)
  330 continue
      WRITE(16, 420) MAXN
      do 340 i=1,MAXN,5
      ij=i+4
      WRITE(16, 490) ANGSTF(I), (XTOTPU(J),J=I,IJ), NAMPR
  340 continue
      do 350 i=1,16
      rate(i)=0.
      namcrs(i) = '        '
  350 continue
      do 360 i=1,324
      xtotpu(i)=0.
  360 continue
      minpr=10000
      maxpr=0
      iprnt=1
      go to 380
  370 continue
      write (15, 500) (name(i),i=1,2),angstf(1),angstf(nf+1),nf,angst1
     1 ,angstl,ns,n1,nl
      go to 50
  380 continue
C      call adv (1)
*      CLOSE (UNIT=16)                                 !New
      return
c
  390 format (i3)
  400 format (i10,2f10.2,a8,2x,a8)
  410 format (0pf10.2,1pe10.2)
  420 format (i5)
  430 FORMAT (F7.0, 3X, 1P5E10.3, A8, 2X, A8)
*  440 format (1h1,50x,a8)
  440 FORMAT (I2, 49X, A8)
*  470 FORMAT (0pf10.2)
  470 FORMAT (0PF7.1)
  490 FORMAT (F7.0, 3x, 1P5E10.3, 10X, A8)
  500 format (1h1,2(a8,2x),1x,'input error'/1x,'flux values ',9x,' angst
     1f(1)=',f10.2,' angstf(nf+1)=',f10.2,' nf=',i5/1x,'cross section va
     2lues  angst1 =',f10.2,' angstl',6x,'=',f10.2,' ns=',i5,' n1=',i5,'
     3nl=',i5)
  510 FORMAT (F8.0, 2x, E8.2)
  511 FORMAT (F8.0)
  512 FORMAT (F8.0, 2x, F5.2)
  513 FORMAT (F4.2)
      end

      subroutine pltxsct (na,angpl,sigpl)
      CHARACTER*8 NAME(2)
      common name, idxaxs, idyaxs
      dimension angpl(3001), sigpl(3001), ndxx(3001)
      xmin=10000.
      xmax=0.
      ymin=1000.
      ymax=-100.
      xmin=amin1(angpl(1),xmin)
      xmax=amax1(angpl(na),xmax)
      do 10 i=1,na
      if (sigpl(i).lt.-20.) go to 5
      ymin=amin1(sigpl(i),ymin)
      ymax=amax1(sigpl(i),ymax)
      go to 10
    5 if (sigpl(i).lt.-22.) go to 10
      ymin=amin1(sigpl(i),ymin)
      ymax=amax1(sigpl(i),ymax)
   10 continue
      ymin=ymin-.1
      ymax=ymax+.1
C      call adv (1)
*      call dgaxes (150,970,80,900,xmin,xmax,ymax,ymin)
C      if (idxaxs .eq. 0) call wlch (450,960,12,12hwavelength a,2)
C      if (idxaxs .eq. 1) call wlch (450,960,16,16hlog wavelength a,2)
*      if (idyaxs.eq.3) go to 28
*      if (idyaxs.eq.2) go to 25
*      if (idyaxs.eq.1) go to 20
C      if (idyaxs.eq.0) call wlcv(65,730,25,25hlog rate coefficient s  a,
C     1   2)
C      call wlcv (50,329,5,5h-1 -1,2)
      go to 30
*   20 continue
C      call wlcv (65,640,16,16hcross section cm,2)
C      call wlcv (50,342,1,1h2,2)
      go to 30
*   25 CONTINUE
C   25 call wlcv (65,680,20,20hlog photons cm  s  a,2)
C      call wlcv (50,430,8,8h-2 -1 -1,2)
      go to 30
*   28 CONTINUE
C   28 call wlcv (65,680,21,21hflux active/quiet sun)
   30 continue
      do 40 i=1,na
C      call convrt (angpl(i),ndxx(i),xmin,xmax,150,950)
   40 continue
      smax=-1.d100
      do 50 j=1,na
      if (sigpl(j).lt.ymin) go to 50
      sminp=ymax-sigpl(j)
      sminm=sigpl(j)-ymin
      if (sminp*sminm.lt.smax) go to 50
      if (ndxx(j).gt.890) go to 50
      smax=sminp*sminm
   50 continue
      if (smax.lt.-1.d50) go to 60
*      call plot (na,angpl,1,sigpl,1,48,1)
C      call wlch (160,0,10,name(1),2)
C      call wlch (460,0,10,name(2),2)
   60 continue
      return
      end

      SUBROUTINE CONVERT(BSUM)
      CHARACTER*8 NAME, NAME1, NAME2, NAM(16), NAMCRS(16), NAMPR
C     NAMCRS(16) and NAMPR are new
      CHARACTER*44 FMT1
      CHARACTER*25 FMT2
      CHARACTER*39 FMT3
      CHARACTER*39 FMT4
      CHARACTER*45 FMT5
      CHARACTER*45 FMT6
      DIMENSION DATA(9999)
      DIMENSION EXEN(3000,16), TOTRAT(16), TOTEEN(16)                    !NEW
      COMMON /A/ NAM, NUM(16), KAT(16), IFLG(16), THRSH(16), NSETS
      COMMON /B/ RADFLX(2001), FLXRAT(162), SA
      COMMON NAME                                              !NEW
      DATA FMT1 /'((5x, 1h$, 1pe10.3, 0(1h,, 1pe10.3), 1h/))'/
      DATA FMT2 /'((1pe10.3, 0(1pe10.3)))'/
      DATA FMT3 /'(('' Lambda       '', 2X, 00(1X, A8)))'/     !NEW
      DATA FMT4 /'((0PF7.1, 1X,    8X , 00(1X, 1PE8.2)))'/     !NEW
      DATA FMT5 /'(('' Rate Coeffs. = '', 00(1X, 1PE8.2)))'/   !NEW
      DATA FMT6 /'(('' Av. Excess E = '', 00(1X, 1PE8.2)))'/   !NEW
      data angev/12398.5/
      MAXBIN = 0                                               !NEW
      iprnt = 0
      k=0
      DO 5 J=1, 16                                            !NEW
      namcrs(J) = '        '                                  !NEW
      TOTRAT(J) = 0.                                          !NEW
      TOTEEN(J) = 0.                                          !NEW
      DO 5 I=1, 3000                                          !NEW
      EXEN(I,J) = 0.                                          !NEW
    5 CONTINUE                                                !NEW
   10 continue
      iprnt = iprnt + 1
      k=k+1
      read (16, 150, IOSTAT=IOS16) MAXN
      if (IOS16) 90, 20, 15
   15 STOP 'ERROR16'
   20 continue
      if (MAXN.le.0) go to 90
      if (MAXN.gt.9999) stop 77777
      MAXBIN = MAX(MAXN, MAXBIN)                                !NEW
      name=nam(k)
      numb=num(k)
      icat=kat(k)
      iflag=iflg(k)
      thresh=thrsh(k)
      if (iflag.eq.0) nsum=nsum+MAXN+3
      read (16, 155) (data(i),i=1,5),name1,name2
      read (16, 160) (data(i),i=6,MAXN)
      if (iflag.eq.1) go to 40
C
C.....Begin EIONIZ.....
C
      WRITE (9, 100) NUMB, ICAT, NAME1, NAME2
      WRITE (9, '(''0   Wavelength Range  X-Section   Flux      Rate '',
     1           ''    E Excess   Sum'')')
      NAMPR = NAME1                                         !NEW
      namcrs(iprnt) = name2                                 !NEW
      if (nsets.le.0) nsets=1                                 !NEW
      m1=nsets+1                                              !NEW
      m2= NSETS                                               !NEW
      m3=1                                                    !NEW
      m4=nsets                                                !NEW
      IF(IPRNT .EQ. 1) WRITE (19, 260) nsets, NAMPR           !NEW
      IF(M2 .LT. 10) FMT3(26:26) = CHAR(M2 + 48)              !NEW
      IF(M2 .LT. 10) FMT3(25:25) = CHAR(48)                   !NEW
      IF(M2 .GE. 10) FMT3(26:26) = CHAR(M2 + 38)              !NEW
      IF(M2 .GE. 10) FMT3(25:25) = CHAR(M2/10 + 48)           !NEW
      IF(M2 .LT. 10) FMT4(24:24) = CHAR(M2 + 48)              !NEW
      IF(M2 .LT. 10) FMT4(23:23) = CHAR(48)                   !NEW
      IF(M2 .GE. 10) FMT4(24:24) = CHAR(M2 + 38)              !NEW
      IF(M2 .GE. 10) FMT4(23:23) = CHAR(M2/10 + 48)           !NEW
      IF(M2 .LT. 10) FMT5(23:23) = CHAR(M2 + 48)              !NEW
      IF(M2 .LT. 10) FMT5(22:22) = CHAR(48)                   !NEW
      IF(M2 .GE. 10) FMT5(23:23) = CHAR(M2 + 38)              !NEW
      IF(M2 .GE. 10) FMT5(22:22) = CHAR(M2/10 + 48)           !NEW
      IF(M2 .LT. 10) FMT6(23:23) = CHAR(M2 + 48)              !NEW
      IF(M2 .LT. 10) FMT6(22:22) = CHAR(48)                   !NEW
      IF(M2 .GE. 10) FMT6(23:23) = CHAR(M2 + 38)              !NEW
      IF(M2 .GE. 10) FMT6(22:22) = CHAR(M2/10 + 48)           !NEW
      trate=0
      etot=0
      do 30 i=1,MAXN
      wave1=radflx(2*i-1)
      wave2=radflx(2*i+1)
      xsect=data(i)
      flx=radflx(2*i)
*      if(i .lt. 163) flx=radflx(2*i) + sa*(flxrat(i) - 1.)*radflx(2*i)
      rate=xsect*flx
      if (wave1.eq.0.) wave1=0.1
      wavel=2.*wave1*wave2/(wave1+wave2)
      enelec=angev/wavel-angev/thresh
      trate=trate+rate
      EXEN(I,iprnt) = ENELEC*RATE
      etot=etot+enelec*rate
      write (9,120) wave1,wave2,xsect,flx,rate,enelec,etot
   30 continue
      avgen=etot/trate
      write (9,130) trate
      write (9,140) avgen
      TOTRAT(IPRNT) = TRATE                                              !NEW
      TOTEEN(IPRNT) = AVGEN                                              !NEW
      DO 35 I=1, MAXN
      EXEN(I,iprnt) = EXEN(I,iprnt)/TRATE                                !NEW
   35 CONTINUE                                                   !NEW
      DO J=1, NSETS                                              !NEW
        IF(EXEN(MAXN,J) .LT. 0) EXEN(MAXN,J) = 0.                !NEW
      END DO                                                     !NEW
      IF (iprnt .EQ. NSETS) THEN                                 !NEW
        WRITE (19, FMT3) (NAMCRS(J), J=M3, M4)                   !NEW
        WRITE (19, FMT4) (RADFLX(2*I-1), (EXEN(I,J), J=1, NSETS),
     1  I=1, MAXBIN)                                             !NEW
        WRITE (19, 270) RADFLX(2*MAXBIN+1)                       !NEW
        WRITE (19, FMT5) (TOTRAT(J), J=1,NSETS)                  !NEW
        WRITE (19, FMT6) (TOTEEN(J), J=1,NSETS)                  !NEW
      END IF                                                     !NEW
C
C.....End EIONIZ.....
C
   40 maxp3=MAXN+3
      n2=0
*      ic=1
      inc=5
      ind1=1
      ind2=117
      if (ind2.gt.maxp3) ind2=maxp3
      ind3=ind2-3
*      if (iflag.eq.0) write (7,220) numb,icat,MAXN
*      if (iflag.eq.1) write (8,180) name,ind1,ind2,numb,icat,MAXN
   50 continue
      n1=n2+1
      n2=n1+inc
      if (n2.lt.ind3) go to 70
      n2=ind3
      idiff=n2-n1
      if (idiff.eq.0) go to 60
      n1p1=n1+1
C      encode (40,200,fmt1) idiff
C      encode (24,250,fmt2) idiff
      IF(IFLAG .EQ. 0) FMT2(12:12) = CHAR(IDIFF + 48)
C      PRINT *, '6', FMT2
*      if (iflag.eq.0) write (7,fmt2) data(n1),(data(i),i=n1p1,n2)
      IF(IFLAG .EQ. 1) FMT1(21:21) = CHAR(IDIFF + 48)
C      PRINT *, '7', FMT1
*      if (iflag.eq.1) write (8,fmt1) data(n1),(data(i),i=n1p1,n2)
      if (n2.eq.MAXN) go to 10
      go to 80
   60 continue
*      if (iflag.eq.0) write (7,230) data(n1)
*      if (iflag.eq.1) write (8,210) data(n1)
      if (n2.eq.MAXN) go to 10
      go to 80
   70 continue
*      if (iflag.eq.0) write (7,240) (data(i),i=n1,n2)
*      if (iflag.eq.1) write (8,170) (data(i),i=n1,n2)
      go to 50
   80 continue
      ind1=ind2+1
      ind2=ind2+114
      if (ind2.gt.maxp3) ind2=maxp3
      ind3=ind2-3
*      if (iflag.eq.1) write (8,190) name,ind1,ind2
      go to 50
   90 continue
      return
c
  100 format (1h1,2i5,11x,a8,12x,a8)
  120 format (1h ,2f10.2,1p3e10.3,0pf10.2,1pe10.3)
  130 FORMAT ('0', 48X, 'Total Rate = ', 1PE10.3)
  140 FORMAT (45X, 'Average Energy = ', F6.3)
  150 format (i5)
  155 format (10x,5e10.3,a8,2x,a8)
  160 FORMAT (10X, 5E10.3)
  170 format (5x,1h$,6(1pe10.3,1h,))
  180 format (6x,6hdata (,a7,6h(i),i=,i4,1h,,i4,2h)/,3(i5,1h,))
  190 format (6x,6hdata (,a7,6h(i),i=,i4,1h,,i4,2h)/)
  210 format (5x,1h$,1pe10.3,1h/)
  220 format (3i5)
  230 format (1pe10.3)
  240 format (6(1pe10.3))
  250 FORMAT (I3)                                          !NEW
  260 FORMAT (I2, 49X, A8)                                 !NEW
  270 FORMAT (0PF7.1)                                  !NEW
      END
