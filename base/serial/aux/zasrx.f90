!!$ 
!!$              Parallel Sparse BLAS  v2.0
!!$    (C) Copyright 2006 Salvatore Filippone    University of Rome Tor Vergata
!!$                       Alfredo Buttari        University of Rome Tor Vergata
!!$ 
!!$  Redistribution and use in source and binary forms, with or without
!!$  modification, are permitted provided that the following conditions
!!$  are met:
!!$    1. Redistributions of source code must retain the above copyright
!!$       notice, this list of conditions and the following disclaimer.
!!$    2. Redistributions in binary form must reproduce the above copyright
!!$       notice, this list of conditions, and the following disclaimer in the
!!$       documentation and/or other materials provided with the distribution.
!!$    3. The name of the PSBLAS group or the names of its contributors may
!!$       not be used to endorse or promote products derived from this
!!$       software without specific written permission.
!!$ 
!!$  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
!!$  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
!!$  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
!!$  PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE PSBLAS GROUP OR ITS CONTRIBUTORS
!!$  BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
!!$  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
!!$  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
!!$  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
!!$  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
!!$  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
!!$  POSSIBILITY OF SUCH DAMAGE.
!!$ 
!!$  
subroutine zasrx(n,x,indx,dir,flag)
  use psb_serial_mod
  use zacmp_mod
  implicit none
  !
  !  Quicksort with indices into original positions.
  !  Adapted from a number of sources, including Don Knuth's TAOCP.
  !
  !     .. Scalar Arguments ..
  integer, intent(in) :: n, dir, flag
  complex(kind(1.d0)) ::  x(n)
  integer ::  indx(n)
  !     ..
  !     .. Local Scalars ..
  complex(kind(1.d0)) :: xx, piv, xk, xt
  integer i, j, ii, ilx, iux, istp, lpiv
  integer ixt, n1, n2

  integer, parameter :: maxstack=64,nparms=3,ithrs=16
  integer            :: istack(nparms,maxstack)
  !     ..

  select case(flag)
  case(psb_sort_ovw_idx_)
    do i=1, n
      indx(i) = i
    enddo
  case(psb_sort_keep_idx_)
    ! do nothing
  case default
    write(0,*) 'Error in isrx: invalid flag',flag
  end select
  !

  !
  !     small inputs will only get through insertion sort. 
  !
  select case(dir) 

  case(psb_alsort_up_)

    if (n > ithrs) then          
      !
      !     Init stack pointer
      !
      istp = 1
      istack(1,istp) = 1
      istack(2,istp) = n

      do 
        if (istp <= 0) exit
        ilx  = istack(1,istp)
        iux  = istack(2,istp)
        istp = istp - 1
        !$$$            write(0,*) 'Debug 1: ',ilx,iux
        !
        !       Choose a pivot with median-of-three heuristics, leave it 
        !       in the LPIV location
        !            
        i = ilx
        j = iux 
        lpiv = (i+j)/2
        piv  = x(lpiv)
        if (piv < x(i)) then
          xt        = x(i)
          ixt        = indx(i)
          x(i)       = x(lpiv)
          indx(i)    = indx(lpiv)
          x(lpiv)    = xt
          indx(lpiv) = ixt
          piv        = x(lpiv)
        endif
        if (piv > x(j)) then
          xt        = x(j)
          ixt        = indx(j)
          x(j)       = x(lpiv)
          indx(j)    = indx(lpiv)
          x(lpiv)    = xt
          indx(lpiv) = ixt
          piv        = x(lpiv)
        endif
        if (piv < x(i)) then
          xt        = x(i)
          ixt        = indx(i)
          x(i)       = x(lpiv)
          indx(i)    = indx(lpiv)
          x(lpiv)    = xt
          indx(lpiv) = ixt
          piv        = x(lpiv)
        endif
        !
        !     now piv is correct;  place it into first location
        xt        = x(i)
        ixt        = indx(i)
        x(i)       = x(lpiv)
        indx(i)    = indx(lpiv)
        x(lpiv)    = xt
        indx(lpiv) = ixt
        piv        = x(lpiv)

        i = ilx - 1 
        j = iux + 1 

        outer_up: do
          in_up1: do
            i = i + 1
            xk = x(i)
            if (xk >= piv) exit in_up1
          end do in_up1
          !
          !     Ensure finite termination for next loop
          !
          xt  = xk
          x(i) = piv
          in_up2:do 
            j = j - 1
            xk = x(j)
            if (xk <= piv) exit in_up2
          end do in_up2
          x(i) = xt  

          if (j > i) then
            xt     = x(i)
            ixt     = indx(i)
            x(i)    = x(j)
            indx(i) = indx(j)
            x(j)    = xt 
            indx(j) = ixt  
          else
            exit outer_up
          end if
        end do outer_up
        if (i == ilx) then 
          if (x(i) /= piv) then
            write(0,*) 'Should never ever get here????!!!!'
            stop
          endif
          i = i + 1 
        endif

        n1 = (i-1)-ilx+1
        n2 = iux-(i)+1
        if (n1 > n2) then
          if (n1 > ithrs) then 
            istp = istp + 1
            istack(1,istp) = ilx
            istack(2,istp) = i-1
          else
            call izasrx_up(n1,x(ilx:i-1),indx(ilx:i-1))
          endif
          if (n2 > ithrs) then
            istp = istp + 1
            istack(1,istp) = i
            istack(2,istp) = iux
          else
            call izasrx_up(n2,x(i:iux),indx(i:iux))
          endif
        else
          if (n2 > ithrs) then
            istp = istp + 1
            istack(1,istp) = i
            istack(2,istp) = iux
          else
            call izasrx_up(n2,x(i:iux),indx(i:iux))
          endif
          if (n1 > ithrs) then 
            istp = istp + 1
            istack(1,istp) = ilx
            istack(2,istp) = i-1
          else
            call izasrx_up(n1,x(ilx:i-1),indx(ilx:i-1))
          endif
        endif
      enddo
    else
      call izasrx_up(n,x,indx)
    endif

  case(psb_alsort_down_) 



    if (n > ithrs) then          
      !
      !     Init stack pointer
      !
      istp = 1
      istack(1,istp) = 1
      istack(2,istp) = n

      do 
        if (istp <= 0) exit
        ilx  = istack(1,istp)
        iux  = istack(2,istp)
        istp = istp - 1
        !$$$            write(0,*) 'Debug 1: ',ilx,iux
        !
        !       Choose a pivot with median-of-three heuristics, leave it 
        !       in the LPIV location
        !            
        i = ilx
        j = iux 
        lpiv = (i+j)/2
        piv  = x(lpiv)
        if (piv > x(i)) then
          xt        = x(i)
          ixt        = indx(i)
          x(i)       = x(lpiv)
          indx(i)    = indx(lpiv)
          x(lpiv)    = xt
          indx(lpiv) = ixt
          piv        = x(lpiv)
        endif
        if (piv < x(j)) then
          xt        = x(j)
          ixt        = indx(j)
          x(j)       = x(lpiv)
          indx(j)    = indx(lpiv)
          x(lpiv)    = xt
          indx(lpiv) = ixt
          piv        = x(lpiv)
        endif
        if (piv > x(i)) then
          xt        = x(i)
          ixt        = indx(i)
          x(i)       = x(lpiv)
          indx(i)    = indx(lpiv)
          x(lpiv)    = xt
          indx(lpiv) = ixt
          piv        = x(lpiv)
        endif
        !
        !     now piv is correct;  place it into first location
        xt        = x(i)
        ixt        = indx(i)
        x(i)       = x(lpiv)
        indx(i)    = indx(lpiv)
        x(lpiv)    = xt
        indx(lpiv) = ixt
        piv        = x(lpiv)

        i = ilx - 1 
        j = iux + 1 

        outer_dw: do
          in_dw1: do
            i = i + 1
            xk = x(i)
            if (xk <= piv) exit in_dw1
          end do in_dw1
          !
          !     Ensure finite termination for next loop
          !
          xt  = xk
          x(i) = piv
          in_dw2:do 
            j = j - 1
            xk = x(j)
            if (xk >= piv) exit in_dw2
          end do in_dw2
          x(i) = xt  

          if (j > i) then
            xt     = x(i)
            ixt     = indx(i)
            x(i)    = x(j)
            indx(i) = indx(j)
            x(j)    = xt  
            indx(j) = ixt  
          else
            exit outer_dw
          end if
        end do outer_dw
        if (i == ilx) then 
          if (x(i) /= piv) then
            write(0,*) 'Should never ever get here????!!!!'
            stop
          endif
          i = i + 1 
        endif

        n1 = (i-1)-ilx+1
        n2 = iux-(i)+1
        if (n1 > n2) then
          if (n1 > ithrs) then 
            istp = istp + 1
            istack(1,istp) = ilx
            istack(2,istp) = i-1
          else
            call izasrx_dw(n1,x(ilx:i-1),indx(ilx:i-1))
          endif
          if (n2 > ithrs) then
            istp = istp + 1
            istack(1,istp) = i
            istack(2,istp) = iux
          else
            call izasrx_dw(n2,x(i:iux),indx(i:iux))
          endif
        else
          if (n2 > ithrs) then
            istp = istp + 1
            istack(1,istp) = i
            istack(2,istp) = iux
          else
            call izasrx_dw(n2,x(i:iux),indx(i:iux))
          endif
          if (n1 > ithrs) then 
            istp = istp + 1
            istack(1,istp) = ilx
            istack(2,istp) = i-1
          else
            call izasrx_dw(n1,x(ilx:i-1),indx(ilx:i-1))
          endif
        endif
      enddo
    else
      call izasrx_dw(n,x,indx)
    endif

  case default
    write(0,*) 'isrx error  dir ',dir
  end select


  return

contains

  subroutine izasrx_up(n,x,indx)
    use zacmp_mod
    implicit none
    integer :: n
    complex(kind(1.d0)) :: x(n)
    integer :: indx(n)
    integer :: i,j,ix
    complex(kind(1.d0)) :: xx

    do j=n-1,1,-1
      if (x(j+1) < x(j)) then
        xx = x(j)
        ix = indx(j) 
        i=j+1
        do 
          x(i-1)    = x(i)
          indx(i-1) = indx(i)
          i = i+1
          if (i>n) exit          
          if (x(i) >= xx) exit
        end do
        x(i-1)    = xx
        indx(i-1) = ix
      endif
    enddo
  end subroutine izasrx_up

  subroutine izasrx_dw(n,x,indx)
    use zacmp_mod
    implicit none
    integer :: n
    complex(kind(1.d0)) :: x(n)
    integer :: indx(n)
    integer :: i,j,ix
    complex(kind(1.d0)) :: xx

    do j=n-1,1,-1
      if (x(j+1) > x(j)) then
        xx = x(j)
        ix = indx(j) 
        i=j+1
        do 
          x(i-1)    = x(i)
          indx(i-1) = indx(i)
          i = i+1
          if (i>n) exit          
          if (x(i) <= xx) exit
        end do
        x(i-1)    = xx
        indx(i-1) = ix
      endif
    enddo
  end subroutine izasrx_dw

end subroutine zasrx