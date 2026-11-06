program calculate_speed
    implicit none
    
    integer :: i, fnum, ix, iy
    integer, parameter :: num_particles = 1000
    integer, parameter :: start_file = 1000
    integer, parameter :: end_file = 1200
    integer, parameter :: grid_boxes = 10
    
    real*8 :: lsize, box_size
    real*8 :: x, y, ex, ey, vx, vy, v_mag
    
    real*8, dimension(grid_boxes, grid_boxes) :: sum_v
    integer, dimension(grid_boxes, grid_boxes) :: count_p
    
    character(len=20) :: filename

    lsize = 46.0d0
    box_size = lsize / dble(grid_boxes)

    open(unit=20, file='grid_velocity.dat', status='replace')
    write(20, *) 'Frame, Box_X_Index, Box_Y_Index, Avg_Velocity'

    open(unit=21, file='particle_tracking.dat', status='replace')
    write(21, *) 'Frame, Particle_ID, X, Y, V_i'

    do fnum = start_file, end_file
        write(filename, '(A5,I4)') 'fort.', fnum
        open(unit=10, file=filename, status='old', action='read', err=100)

        sum_v = 0.0d0
        count_p = 0

        do i = 1, num_particles
            read(10, *) x, y, ex, ey, vx, vy, v_mag

            write(21, *) fnum, i, x, y, v_mag

            ix = floor(x / box_size) + 1
            iy = floor(y / box_size) + 1

            if (ix > grid_boxes) ix = grid_boxes
            if (iy > grid_boxes) iy = grid_boxes
            if (ix < 1) ix = 1
            if (iy < 1) iy = 1

            sum_v(ix, iy) = sum_v(ix, iy) + v_mag
            count_p(ix, iy) = count_p(ix, iy) + 1
        end do
        close(10)

        do ix = 1, grid_boxes
            do iy = 1, grid_boxes
                if (count_p(ix, iy) > 0) then
                    write(20, *) fnum, ix, iy, (sum_v(ix, iy) / dble(count_p(ix, iy)))
                else
                    write(20, *) fnum, ix, iy, 0.0d0
                end if
            end do
        end do
        
        goto 200
        
100     continue 
200     continue
    end do

    close(20)
    close(21)

end program calculate_speed
