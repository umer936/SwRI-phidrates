      Subroutine PltXSct(na,angpl,sigpl)
      character*8 NAME(2)
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
      go to 30
      go to 30
   30 continue
      do 40 i=1,na
   40 continue
      smax=-1
      do 50 j=1,na
      if (sigpl(j).lt.ymin) go to 50
      sminp=ymax-sigpl(j)
      sminm=sigpl(j)-ymin
      if (sminp*sminm.lt.smax) go to 50
      if (ndxx(j).gt.890) go to 50
      smax=sminp*sminm
   50 continue
      if (smax.lt.-1.d50) go to 60
   60 continue
      return
      end
