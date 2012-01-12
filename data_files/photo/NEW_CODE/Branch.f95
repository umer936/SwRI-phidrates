Subroutine Branch(iEnd)
!
! This subroutine aportions cross sections for each photodissociation, photoionization, and 
! photodissociative ionization branch.
!
common /A/ Nam, Num, Kat, iFlg, Thrsh, nSets
logical Limit
integer, parameter :: LimA = 50000, LimB = 2000
integer :: i, iEnd, IOS1, iT, j, m, n1, n2, n3, nB, nDum, nS, nSets
integer, dimension(16) :: Num, iFlg, Kat
character (len = 3) :: Aster, Ast3
character (len = 8) :: LastN
character (len = 8), dimension(2)  :: Mother, IPROD
character (len = 8), dimension(10) :: Text
character (len = 8), dimension(16) :: Nam
character (len = 24) :: FMT1
character (len = 39) :: FMT2
real (kind = 8) :: Ang1, AngL, Angsti, Angst1, AngstL, AngstB1, AngstBL, Dum, ttemp
real (kind = 8), dimension(16) :: Thrsh
real (kind = 8), dimension(LimA + 1) :: Angsts
real (kind = 8), dimension(LimA) :: Sigma, BrPr, Tot
real (kind = 8), dimension(LimA) :: AngstB, Br
real (kind = 8), dimension(LimA, 16) :: TabBrP, TabSig
FMT1 = "((a14, 2x, 00 (1x, a8)))"
FMT2 = "((0pf7.1, 1x, 1pe8.2, 00 (1x, 1pe8.2)))"
!
! Initialize Subroutine.
!
Ast3 = "***"
Limit = .False.
m = 0
do i = 1, 16
  iFlg(i) = 0
end do
do i = 1, LimA
  Tot(i) = 0.
  do j = 1, 16
    TabBrP(i, j) = 0.
    TabSig(i, j) = 0.
  end do
end do
!
! Read mother molecule information.
!
read(unit = 1, fmt = "(i10, 2f10.2, 2(1x, a8), 2i3)", iostat = IOS1) nS, &
  Angst1, AngstL, (Mother(i), i = 1, 2), Num(1), Kat(1)    ! Unit 1 is HREC
if(IOS1 < 0) then
  write(unit = *, fmt = *) "End of HRec file:", IOS1
  iEnd = 1
  return
else if(IOS1 > 0) then
  write(unit = *, fmt = *) "HRec input error:", IOS1
  stop
else
end if
if(Num(1) /= 0) then
  Nam(1) = Mother(2)
else
end if
Thrsh(1) = AngstL
!
! Read references for mother molecule.
!
  write(unit = 2, fmt = "(a43, a8, 2x, a8)") "0          References for Cross Section of ", &
  (Mother(i), i = 1, 2)
do
  read(unit = 1, fmt = "(10 a8)") (Text(i), i=1, 10)
  write(unit = 2, fmt = "(10 a8)") (Text(i), i=1, 10)
  if(Text(1) == Text(2) .or. Text(2) == "        ") then
    exit
  else
  endif
end do
!
! Read wavelengths and cross sections for the mother molecule.
!
read(unit = 1, fmt = "(0pf10.2, 1pe10.2)") (Angsts(i), Sigma(i), i = 1, nS)
!
! Read the number of branching sets that follow.
!
read(unit = 1, fmt = "(i3)") nSets
Nam(nSets + 2) = Mother(1)
Num(nSets + 2) = 0
Kat(nSets + 2) = 0
iFlg(nSets + 2) = 1
!
! If there are no branching sets, i.e., nSets = 0, skip to 130.
!
if(nSets /= 0) then     ! This goes to end of "if"
  iT = nSets + 1
!
! Write the total number of branches (nSets + 1).
!
  write(unit = 4, fmt = "(i3)") it     ! Temporary file for wavelengths & cross sections.
!
! Read information for a branching set.
!
  do
    read(unit = 1, fmt = "(i10, 2 f10.2, 2 (1x, a8), 2 i3)") nB, AngstB1, &
         AngstBL, (iProd(i), i = 1, 2), Num(m + 1), Kat(m + 1)
    Thrsh(m + 1) = AngstBL
    m = m + 1
    Nam(m) = IProd(2)
    write(unit = 2, fmt = "(a43, a8, 2x, a8)") "0          References for Cross Section of ", &
         (iProd(i), i = 1, 2)
    do
      read(unit = 1, fmt = "(10 a8)") (Text(i), i = 1, 10)  ! Read references for a branching set.
      write(unit = 2, fmt = "(10 a8)") (Text(i), i = 1, 10)
      if(Text(1) == Text(2) .or. Text(2) == "        ") then
        exit
      else
      end if
    end do  
!
! Set Ang1 = Max(Angst1, AngstB1) and AngL = Min(AngstL, AngstBL).
!
    Ang1 = Angst1
    AngL = AngstL
    if(AngstB1 > Ang1) then
      Ang1 = AngstB1
    else
    end if
    if(AngstBL < AngL) then
      AngL = AngstBL
    else
    end if
!
! Read pairs of wavelengths and sigmas for branching set.
!
    read(unit = 1, fmt = "(0pf10.2, 1pe10.2)") (AngstB(i), Br(i), i = 1, nB)
    j = 1
!
! For each wavelength of the mother species calculate a new cross section (Sigma) for each branch.
!
    do i = 1, nS
      Angsti = Angsts(i)
      do
        if(Angsti > AngstB(j + 1) .and. .not. Limit) then  ! This goes to end of "if" 
        else
          if(Angsti == AngstB(j + 1)) then
            BrPr(i) = Br(j + 1)
          end if
          if(Angsti /= AngstB(j + 1)) then
            BrPr(i) = Br(j) + (Br(j + 1) - Br(j))*((Angsti - AngstB(j)) &
              /(AngstB(j + 1) - AngstB(j)))
          end if
          if(Limit) then
            BrPr(I) = 0.
          end if
          Tot(i) = Tot(i) + BrPr(i)
          TabSig(i, m) = BrPr(i)*Sigma(i)
          TabBrP(i, m) = BrPr(i)
          exit
!
! Find the smallest wavelength of the branching set that is greater than the 
! wavelength of the mother species.
!
        end if
        j = j + 1
!
! Check if the limit has been reached.
!
        if(j + 1 >= nB .and. Angsti > AngstB(nB)) then
          Limit = .True.
        end if
      end do
    end do
!
! Write temporary file for wavelengths and cross sections.
!
    write(unit = 4, fmt = "(i10, 2 f10.2, a8, 2 x, a8)") nS, Ang1, AngL, Mother(1), IProd(2)
    write(unit = 4, fmt = "(0pf10.2, 1pe10.2)") (Angsts(i), TabSig(i, m), i = 1, nS)
!
! If there are more branching sets, then loop back and do it again.
!
    if(m == nSets) then
      exit
    else
    end if
  end do
  nSets = nSets + 1
  read(unit = 1, fmt = "(i10, 2 f10.2, 2 (1x, a8), 2 i3)") nDum, Dum, &
    Thrsh(nSets), iProd(1), LastN, Num(nSets), Kat(nSets)
  Nam(nSets) = LastN
!
! nSets + 1 is the total number of branches.  Calculcate the final branch here.
!
  do i = 1, ns
    ttemp = 1. - Tot(i)
    if(ttemp < 0.) then
      write(unit = *, fmt = *) Mother(1), ", ttemp < 0.: ", ttemp, " around wavelength: ", Angsts(i)
      TabBrP(i, nSets) = 0.0
      ttemp = 0.0
    else
      TabBrP(i, nSets) = ttemp
    end if
    TabSig(i, nSets) = TabBrP(i, nSets)*Sigma(i)
  end do
!
! Write temporary file for wavelengths & cross sections.
!
  write(unit = 4, fmt = "(i10, 2 f10.2, a8, 2x, a8)") ns, Angst1, AngstL, Mother(1), LastN
  write(unit = 4, fmt = "(0pf10.2, 1pe10.2)") (Angsts(i), TabSig(i, nSets), i=1, ns)
!
! If there are no Branching Sets, the Mother Molecule is the Only "Branch."
!
else
!
! Write temporary file for wavelengths & cross sections.
!
  write(unit = 4, fmt = "(i3)") nSets
  write(unit = 4, fmt = "(i10, 2 f10.2, a8, 2x, a8)") nS, Angst1, AngstL, (Mother(i), i = 1, 2)
  write(unit = 4, fmt = "(0pf10.2, 1pe10.2)") (Angsts(i), Sigma(i), i = 1, nS)
end if
do
  read(unit = 1, fmt = "(a3)") Aster
  if(Aster == Ast3) then
    exit
  else
  end if
end do
  n1 = nSets
  n2 = 1
  n3 = nSets
  if(n1 < 10) then
    FMT1(13:13) = CHAR(n1 + 48)
    FMT1(12:12) = CHAR(48)
    FMT2(24:24) = CHAR(n1 + 48)
    FMT2(23:23) = CHAR(48)
  else
    FMT1(13:13) = CHAR(n1 + 38)
    FMT1(12:12) = CHAR(n1/10 + 48)
    FMT2(24:24) = CHAR(n1 + 38)
    FMT2(23:23) = CHAR(n1/10 + 48)
  end if
  write(unit = 2, fmt = "(a21, (2 (1x, a8)), 4x, i2, a9)") &
    "0 Branching ratio for", (Mother(j), j = 1, 2), nSets, " branches"
  if(nSets > 0) then
    write(unit = 2, fmt = FMT1) " Lambda  Total", (Nam(i), i = n2, n3)
    write(unit = 2, fmt = FMT2) (Angsts(i), Sigma(i), (TabSig(i, j), j = n2, n3),&
      i = 1, ns)
  else
    write(unit = 2, fmt = "(a8, 2x, a8)") "  Lambda", Mother(2)
    write(unit = 2, fmt = "(0pf8.2, 1x, 1pe9.2)") (Angsts(i), &
      Sigma(i), i = 1, nS)
  end if
return
end Subroutine Branch
