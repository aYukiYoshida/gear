      
      character infile*30,outfile*30
      character buf*30,b1*7, b2*1
      infile="201012221158.pha"
      outfile="test.qdp"
      b2="!"
*
 100  continue
      write(6,'("Key in input and output file names")')
      read(5,*, end= 9999)infile, outfile
*      write(6,'("Key in output file name")')
*      read(5,*)outfile

*
      open(unit=1,file=infile,status="old")
      open(unit=2,file=outfile,status="new")

      write(2,200)
 200  format(1h ,"lab x channel"/
     &       1h ,"lab y counts"/
     &       1h ,"f ro"/
     &       1h ,"cs 1.5"/
     &       1h ,"lw 3")
      ich=0
      iflag=0
 1001 do 1000 i1=1,10000
         read(1,'(A10)',end=999)buf
*         write(6,*)buf
         read(buf,'(A7)')b1
*         write(6,*)b1
         if(iflag.eq.1)goto 1200
         if(b1.ne."<<DATA>")then
            write(2,'(A1,A30)')b2,buf
            go to 1000
         else
            write(2,'(A1,A30)')b2,buf
            iflag=1
            goto 1000
         endif
 1200    continue
         if(b1.eq."<<END>>")then
            iflag=0
            goto 1000
         endif
         read(buf,*)num
         ich=ich+1
         write(2,'(i4,1x,i10)')ich,num
 1000 continue
 999  continue
      close(1)
      close(2)
      goto 100
 9999 continue
      stop
      end
