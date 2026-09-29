 program multiple_particle_and_obstacle
 use mtmod
 implicit real*8(a-h,o-z)
 implicit integer*4(i-n)
 integer::vicsek_interaction,curvature_interaction
 double precision,dimension(1:10000)::x_particle,y_particle,x_av,y_av,ex,ey
 integer,dimension(0:501,0:501,0:1000)::grid
 
 ifile=1000

 pi=3.141592

 gauss_limit=3.0d0
 grid=0
 kcount=0
 
 number_of_cells=200
 vicsek_interaction=1
 curvature_interaction=1

 iens=1
 itime=200
 igap=1000
 lsize=20   !system size
 
 n_cell_max=10
 ngrid=lsize/2
 igrid_size=2
 
 
 v0=0.1
 s=1.0 !sigma
 range=1.414213*s
 max_range=s
 e=1.0 !epsilon
 
 D=0.0001 !translational diffusivity
 Dr=0.0001 !rotational diffusivity
 gamma=1.0 !frictional coefficient
 dt=0.001
 dt2=dt**0.5
 D2=(2*D)**0.5
 Dr2=(2*Dr)**0.5
 
 theta_curv=pi/2
 curvature_strength=0.1   !Vary from 0 to 1
 vicsek_strength=0.1      !Vary from 0 to 1


 do i=1,number_of_cells
 read(ifile,*)x_particle(i),y_particle(i),ex(i),ey(i)
 end do
 close (ifile)
 
 
 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
 !!!!!!!!!! Initial gridding of space and distributing particles !!!!!!!!!!!!!
 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
 
 do i=1,number_of_cells
 index_x=floor(x_particle(i))/igrid_size + 1
 index_y=floor(y_particle(i))/igrid_size + 1
 grid(index_x,index_y,0)= grid(index_x,index_y,0) + 1
 grid(index_x,index_y,grid(index_x,index_y,0))=i
 end do


!!!!!!!!!!!! assigning periodic boundary values for particles !!!!!!!!!!!!!!!!
 do i=1,ngrid
 
 grid (0,i,0)=grid(ngrid,i,0)
 grid(ngrid+1,i,0)=grid(1,i,0)
 grid(i,0,0)=grid(i,ngrid,0)
 grid(i,ngrid+1,0)=grid(i,1,0)
 
 do j=1,grid(0,i,0)
 grid(0,i,j)=grid(ngrid,i,j)
 end do
 
 do j=1,grid(ngrid+1,i,0)
 grid(ngrid+1,i,j)=grid(1,i,j)
 end do
 
 do j=1,grid(i,0,0)
 grid(i,0,j)=grid(i,ngrid,j)
 end do

 do j=1,grid(i,ngrid+1,0) 
 grid(i,ngrid+1,j)=grid(i,1,j)
 end do
 
 end do


!!!!!!!!! at the corners !!!!!!!!!!!!!!!!!!!!!!
 grid(0,0,0)=grid(ngrid,ngrid,0)
 grid(ngrid+1,0,0)=grid(1,ngrid,0)
 grid(ngrid+1,ngrid+1,0)=grid(1,1,0)
 grid(0,ngrid+1,0)=grid(ngrid,1,0) 

 do j=1,grid(0,0,0)
 grid(0,0,j)=grid(ngrid,ngrid,j)
 end do

 do j=1,grid(ngrid+1,0,0) 
 grid(ngrid+1,0,j)=grid(1,ngrid,j)
 end do

 do j=1,grid(ngrid+1,ngrid+1,0)  
 grid(ngrid+1,ngrid+1,j)=grid(1,1,j)
 end do

 do j=1,grid(0,ngrid+1,0)  
 grid(0,ngrid+1,j)=grid(ngrid,1,j) 
 end do
 
!!!!!!!!!!! end periodic boundary !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!! End of Initial gridding !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!



 do k3=1,iens

 do k2=1,itime 

 do k1=1,igap
 
 do k0=1,number_of_cells

 !generating gaussian random numbers to be used later
500 xx=grnd()
 xy=grnd()
 gauss1=(-2*log(xx))**0.5*cos(2*pi*xy)
 gauss2=(-2*log(xx))**0.5*sin(2*pi*xy)
 if((abs(gauss1)>gauss_limit).or.(abs(gauss2)>gauss_limit))then
 go to 500
 end if 
600 xx=grnd()
 xy=grnd()
 gauss3=(-2*log(xx))**0.5*cos(2*pi*xy)
 gauss4=(-2*log(xx))**0.5*sin(2*pi*xy)
 if((abs(gauss3)>gauss_limit).or.(abs(gauss4)>gauss_limit))then
 go to 600
 end if 
 !end gaussian number generation
 

 !!!!!!!!!!!! calculate total force on the particle due to all the other particles !!!!!!!!!!!!!!!!!!!!!!
 
 ftx=0.0d0
 fty=0.0d0
 
 avg_ex=0.0d0
 avg_ey=0.0d0
 
 index_x_old=floor(x_particle(k0))/igrid_size + 1
 index_y_old=floor(y_particle(k0))/igrid_size + 1  
 

 do i=-1,1
 do j=-1,1

 do jj=1,grid(index_x_old+i,index_y_old+j,0)

 i_particle=grid(index_x_old+i,index_y_old+j,jj)   !Particle index
 
  if (i_particle.ne.k0) then
 
 
 x_position=x_particle(i_particle)         !x position of the particle
 y_position=y_particle(i_particle)         !y position of the particle

 if((index_x_old+i)==0) then
 x_position=x_position - lsize  
 else if((index_x_old+i)==(ngrid+1)) then
 x_position=x_position  + lsize  
 end if 

 if((index_y_old+j)==0) then
 y_position=y_position - lsize  
 else if((index_y_old+j)==(ngrid+1)) then
 y_position=y_position  + lsize  
 end if          

 separation=(x_particle(k0)-x_position)*(x_particle(k0)-x_position) + (y_particle(k0)-y_position)*(y_particle(k0)-y_position)

 if (separation < range*range) then  !Only repulsion
 call calculate_force(x_particle(k0),y_particle(k0),x_position,y_position,s,e,fx,fy)
 ftx=ftx+fx
 fty=fty+fy

 avg_ex=avg_ex+ex(k0)
 avg_ey=avg_ey+ey(k0) 

 end if
 
 end if
 
 end do
 
 end do
 end do
 

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!! Translational motion of the particle !!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
 
 dx1=v0*ex(k0)*dt
 dx2=(ftx/gamma)*dt
 dx3=gauss1*D2*dt2
 dy1=v0*ey(k0)*dt
 dy2=(fty/gamma)*dt
 dy3=gauss2*D2*dt2

 dx=dx1 + dx2 + dx3
 dy=dy1 + dy2 + dy3
 
 x_particle(k0)=x_particle(k0)+dx
 y_particle(k0)=y_particle(k0)+dy 
 
!!!!!periodic boundary condition !!!!!!!!!!!!

 if(x_particle(k0)>lsize) then
 x_particle(k0)=x_particle(k0)-lsize
 end if

 if(x_particle(k0)<0.0d0) then
 x_particle(k0)=x_particle(k0)+lsize
 end if

 if(y_particle(k0)>lsize) then
 y_particle(k0)=y_particle(k0)-lsize
 end if

 if(y_particle(k0)<0.0d0) then
 y_particle(k0)=y_particle(k0)+lsize
 end if
 
!!!!! END Periodic Boundary Condition !!!!!!! 
 
 
 index_x=floor(x_particle(k0))/igrid_size + 1
 index_y=floor(y_particle(k0))/igrid_size + 1 
 
 
 if ((index_x_old.ne.index_x).or.(index_y_old.ne.index_y)) then
 
 
 index_particle=0
 do i3=1,grid(index_x_old,index_y_old,0)
 if (grid(index_x_old,index_y_old,i3) == k0) then
 index_particle=i3
 end if
 end do 

!!!!!!!!!revoming the record of particle from old index !!!!!!!!!!

 grid(index_x_old,index_y_old,index_particle)= grid(index_x_old,index_y_old,grid(index_x_old,index_y_old,0)) 
 grid(index_x_old,index_y_old,grid(index_x_old,index_y_old,0))=0
 
 grid(index_x_old,index_y_old,0)= grid(index_x_old,index_y_old,0) - 1  
 
 
 !!!!!!!!!adding the record of particle in new index !!!!!!!!!!
 
 grid(index_x,index_y,0)= grid(index_x,index_y,0) + 1 
 grid(index_x,index_y,grid(index_x,index_y,0))=k0
 
 end if

!!!!!!!!!!!! reassigning periodic boundary values for particles !!!!!!!!!!!!!!!!


 if ((index_x_old.ne.index_x).and.(index_y_old.eq.index_y)) then
 
 
 grid(0,index_y,0)=grid(ngrid,i,0) 
 do j=1,grid(0,index_y,0) 
 grid(0,index_y,j)=grid(ngrid,i,j) 
 end do 
 
 grid(ngrid+1,index_y,0)=grid(1,index_y,0) 
 do j=1,grid(ngrid+1,index_y,0)
 grid(ngrid+1,index_y,j)=grid(1,index_y,j)
 end do
 
 
 else if ((index_x_old.eq.index_x).and.(index_y_old.ne.index_y)) then
  
 grid(index_x,0,0)=grid(index_x,ngrid,0)   
 do j=1,grid(index_x,0,0) 
 grid(index_x,0,j)=grid(index_x,ngrid,j) 
 end do 
 
 grid(index_x,ngrid+1,0)=grid(index_x,1,0) 
 do j=1,grid(index_x,ngrid+1,0)
 grid(index_x,ngrid+1,j)=grid(index_x,1,j)
 end do  


 
 else if ((index_x_old.ne.index_x).and.(index_y_old.ne.index_y)) then 
  
 grid(0,0,0)=grid(ngrid,ngrid,0)  
 do j=1,grid(0,0,0)
 grid(0,0,j)=grid(ngrid,ngrid,j)
 end do

 grid(ngrid+1,ngrid+1,0)=grid(1,1,0)
 do j=1,grid(ngrid+1,ngrid+1,0)  
 grid(ngrid+1,ngrid+1,j)=grid(1,1,j)
 end do
 
 grid(ngrid+1,0,0)=grid(1,ngrid,0) 
 do j=1,grid(ngrid+1,0,0) 
 grid(ngrid+1,0,j)=grid(1,ngrid,j)
 end do

 grid(0,ngrid+1,0)=grid(ngrid,1,0) 
 do j=1,grid(0,ngrid+1,0)  
 grid(0,ngrid+1,j)=grid(ngrid,1,j) 
 end do  
 

 end if  
  

!!!!!!!!!!! end periodic boundary !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

! x_av(k0)=x_av(k0) + dx
! y_av(k0)=y_av(k0) + dy


 
!!!!!!!!!!!!!!!!!! End Translational dynamics !!!!!!!!!!!!!!!!!!!!!

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!  Rotational motion of the particle !!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

!!!!!!!!!!!! Initiate curvature interaction !!!!!!!!!!!!!!!!!!!!!!!!!
 
 if (curvature_interaction==1) then
 
 theta_i=atan2(ey(k0),ex(k0))
 !angle=sin(theta_i - theta_curv)
 tau_curv=-curvature_strength*sin(theta_i - theta_curv)
 w=tau_curv/gamma
 
 end if
 
!!!!!!!!!!!! End curvature interaction !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

 w_vicsek=0.0d0
 
!!!!!!!!!!!!! Initiate Vicsek interaction !!!!!!!!!!!!!!!!!!!!!!!!!!!

 if (vicsek_interaction==1) then
 
 theta_vicsek=atan2(avg_ey,avg_ex)

 theta_i=atan2(ey(k0),ex(k0))

 tau_vicsek=-vicsek_strength*sin(theta_i - theta_vicsek)
 w_vicsek=tau_vicsek/gamma

 end if
 
!!!!!!!!!!!!!!!End Vicsek interaction !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


!!!!Updating orientation for curvature and/or vicsek interaction !!!!!

 ex(k0)=ex(k0) - w*ey(k0) - w_vicsek*ey(k0) - (Dr2*gauss3*ey(k0))*dt2
 ey(k0)=ey(k0) + w*ex(k0) + w_vicsek*ex(k0) + (Dr2*gauss3*ex(k0))*dt2
 enorm=(ex(k0)**2+ey(k0)**2)**0.5
 ex(k0)=ex(k0)/enorm
 ey(k0)=ey(k0)/enorm

!!!!!!!!!!!!!!!!! End orientation update !!!!!!!!!!!!!!!!!!!!!!!!!!!!!

 
 end do
 
 
 end do
 
!writing on file 
 
 ifile=ifile+1
 do i=1,number_of_cells
 write(ifile,*)x_particle(i),y_particle(i),ex(i),ey(i)
 end do
 close(ifile)
 
 end do
 
 end do


 end program

 subroutine calculate_force(rx,ry,obs_x,obs_y,s,e,fx,fy)
     double precision rx,ry,obs_x,obs_y,s,e,fr,fx,fy
     x=rx-obs_x
     y=ry-obs_y
     fr=+4*e*((4*s*s*s*s)/((x*x+y*y)*(x*x+y*y)*(x*x+y*y)) - (2*s*s)/((x*x+y*y)*(x*x+y*y)))
     fx=x*fr
     fy=y*fr
     return
 end

