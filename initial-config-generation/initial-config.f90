 program multiple_particle_and_obstacle
 use mtmod
 implicit real*8(a-h,o-z)
 implicit integer*4(i-n)
 integer::random_position,random_direction
 double precision,dimension(1:10000)::x_particle,y_particle,x_av,y_av,ex,ey
 integer,dimension(0:501,0:501,0:1000)::grid
 
 ifile=1000

 pi=3.141592

 gauss_limit=3.0d0
 grid=0
 kcount=0
 
 number_of_cells=1000
 
 random_position=1
 random_direction=1

 lsize=46   !system size
 
 s=1.0 !sigma
 range=1.414213*s
 max_range=s


 if (random_position==1) then 
 
 !initialising particle position and direction randomly
 do i=1,number_of_cells
400 x5=grnd()*lsize
    y5=grnd()*lsize
    if((x5>=lsize).or.(y5>=lsize)) then
    go to 400
    end if
    
 do j=1,i-1 

 separation=(x5-x_particle(j))*(x5-x_particle(j)) + (y5-y_particle(j))*(y5-y_particle(j))

 if (separation < max_range*max_range) then
 go to 400
 end if

 end do
 
 x_particle(i)=x5
 y_particle(i)=y5
 
 end do
 
 else
 
 yy=1.0
 xx=1.0
 ly=lsize
 do i=1,number_of_cells
500 if(i<=ly) then
 x_particle(i)=xx
 y_particle(i)=yy
 xx=xx+1
 else
 yy=yy+1.0
 ly=ly+lsize
 xx=1.0
 go to 500
 end if
 end do
 
 end if
 
 
 if (random_direction==1) then
! Initializing the direction of each particle randomly 

 do i=1,number_of_cells
 
 x6=grnd() - 0.5
 y6=grnd() - 0.5
 xmag=(x6*x6+y6*y6)**0.5

 ex(i)=x6/xmag
 ey(i)=y6/xmag
 
 end do

 else
 
 do i=1,number_of_cells
 
 x6=1.0
 y6=0.0
 xmag=(x6*x6+y6*y6)**0.5

 ex(i)=x6/xmag
 ey(i)=y6/xmag 
 
 end do
 
 end if
 
 
!Record initial conditions
 do i=1,number_of_cells
 write(ifile,*)x_particle(i),y_particle(i),ex(i),ey(i)
 end do
 close(ifile) 
!END
 

 end program


