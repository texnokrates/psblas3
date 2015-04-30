!!$ 
!!$              Parallel Sparse BLAS  version 3.4
!!$    (C) Copyright 2006, 2010, 2015
!!$                       Salvatore Filippone    University of Rome Tor Vergata
!!$                       Alfredo Buttari        CNRS-IRIT, Toulouse
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
!
!  The insertion sort routines 
!  References:
!  D. Knuth
!  The Art of Computer Programming, vol. 3
!  Addison-Wesley
!  
!  Aho, Hopcroft, Ullman
!  Data Structures and Algorithms
!  Addison-Wesley
!
subroutine psb_sisort(x,ix,dir,flag)
  use psb_s_sort_mod, psb_protect_name => psb_sisort
  use psb_error_mod
  implicit none 
  real(psb_spk_), intent(inout)  :: x(:) 
  integer(psb_ipk_), optional, intent(in)    :: dir, flag
  integer(psb_ipk_), optional, intent(inout) :: ix(:)

  integer(psb_ipk_) :: dir_, flag_, n, err_act, i

  integer(psb_ipk_)  :: ierr(5)
  character(len=20)  :: name

  name='psb_sisort'
  call psb_erractionsave(err_act)

  if (present(flag)) then 
    flag_ = flag
  else 
    flag_ = psb_sort_ovw_idx_
  end if
  select case(flag_) 
  case( psb_sort_ovw_idx_, psb_sort_keep_idx_)
    ! OK keep going
  case default
    ierr(1) = 4; ierr(2) = flag_; 
    call psb_errpush(psb_err_input_value_invalid_i_,name,i_err=ierr)
    goto 9999
  end select

  if (present(dir)) then 
    dir_ = dir
  else
    dir_= psb_sort_up_
  end if

  n = size(x)

  if (present(ix)) then
    if (size(ix) < n) then 
      ierr(1) = 2; ierr(2) = size(ix); 
      call psb_errpush(psb_err_input_asize_invalid_i_,name,i_err=ierr)
      goto 9999
    end if
    if (flag_==psb_sort_ovw_idx_) then
      do i=1,n
        ix(i) = i
      end do
    end if

    select case(dir_) 
    case (psb_sort_up_)
      call psi_sisrx_up(n,x,ix)
    case (psb_sort_down_)
      call psi_sisrx_dw(n,x,ix)
    case (psb_asort_up_)
        call psi_saisrx_up(n,x,ix)
    case (psb_asort_down_)
        call psi_saisrx_dw(n,x,ix)
    case default
      ierr(1) = 3; ierr(2) = dir_; 
      call psb_errpush(psb_err_input_value_invalid_i_,name,i_err=ierr)
      goto 9999
    end select
  else 
    select case(dir_) 
    case (psb_sort_up_)
      call psi_sisr_up(n,x)
    case (psb_sort_down_)
      call psi_sisr_dw(n,x)
    case (psb_asort_up_)
        call psi_saisr_up(n,x)
    case (psb_asort_down_)
        call psi_saisr_dw(n,x)
    case default
      ierr(1) = 3; ierr(2) = dir_; 
      call psb_errpush(psb_err_input_value_invalid_i_,name,i_err=ierr)
      goto 9999
    end select

  end if

  return

9999 call psb_error_handler(err_act)

  return
end subroutine psb_sisort

subroutine psi_sisrx_up(n,x,ix)
  use psb_s_sort_mod, psb_protect_name => psi_sisrx_up
  use psb_error_mod
  implicit none 
  real(psb_spk_), intent(inout)  :: x(:) 
  integer(psb_ipk_), intent(inout) :: ix(:)
  integer(psb_ipk_), intent(in)   :: n
  integer(psb_ipk_) :: i,j,ix
  real(psb_spk_) :: xx

  do j=n-1,1,-1
    if (x(j+1) < x(j)) then
      xx = x(j)
      ix = idx(j) 
      i=j+1
      do 
        x(i-1)    = x(i)
        idx(i-1) = idx(i)
        i = i+1
        if (i>n) exit          
        if (x(i) >= xx) exit
      end do
      x(i-1)    = xx
      idx(i-1) = ix
    endif
  enddo
end subroutine psi_sisrx_up

subroutine psi_sisrx_dw(n,x,ix)
  use psb_s_sort_mod, psb_protect_name => psi_sisrx_dw
  use psb_error_mod
  implicit none 
  real(psb_spk_), intent(inout)  :: x(:) 
  integer(psb_ipk_), intent(inout) :: ix(:)
  integer(psb_ipk_), intent(in)   :: n
  integer(psb_ipk_) :: i,j,ix
  real(psb_spk_) :: xx

  do j=n-1,1,-1
    if (x(j+1) > x(j)) then
      xx = x(j)
      ix = idx(j) 
      i=j+1
      do 
        x(i-1)    = x(i)
        idx(i-1) = idx(i)
        i = i+1
        if (i>n) exit          
        if (x(i) <= xx) exit
      end do
      x(i-1)    = xx
      idx(i-1) = ix
    endif
  enddo
end subroutine psi_sisrx_dw


subroutine psi_sisr_up(n,x)
  use psb_s_sort_mod, psb_protect_name => psi_sisr_up
  use psb_error_mod
  implicit none 
  real(psb_spk_), intent(inout)  :: x(:) 
  integer(psb_ipk_), intent(in)   :: n
  integer(psb_ipk_) :: i,j
  real(psb_spk_) :: xx
  
  do j=n-1,1,-1
    if (x(j+1) < x(j)) then
      xx = x(j)
      i=j+1
      do 
        x(i-1) = x(i)
        i = i+1
        if (i>n) exit          
        if (x(i) >= xx) exit
      end do
      x(i-1) = xx
    endif
  enddo
end subroutine psi_sisr_up

subroutine psi_sisr_dw(n,x)
  use psb_s_sort_mod, psb_protect_name => psi_sisr_dw
  use psb_error_mod
  implicit none 
  real(psb_spk_), intent(inout)  :: x(:) 
  integer(psb_ipk_), intent(in)   :: n
  integer(psb_ipk_) :: i,j
  real(psb_spk_) :: xx
  
  do j=n-1,1,-1
    if (x(j+1) > x(j)) then
      xx = x(j)
      i=j+1
      do 
        x(i-1) = x(i)
        i = i+1
        if (i>n) exit          
        if (x(i) <= xx) exit
      end do
      x(i-1) = xx
    endif
  enddo
end subroutine psi_sisr_dw

subroutine psi_saisrx_up(n,x,ix)
  use psb_s_sort_mod, psb_protect_name => psi_saisrx_up
  use psb_error_mod
  implicit none 
  real(psb_spk_), intent(inout)  :: x(:) 
  integer(psb_ipk_), intent(inout) :: ix(:)
  integer(psb_ipk_), intent(in)   :: n
  integer(psb_ipk_) :: i,j,ix
  real(psb_spk_) :: xx

  do j=n-1,1,-1
    if (abs(x(j+1)) < abs(x(j))) then
      xx = x(j)
      ix = idx(j) 
      i=j+1
      do 
        x(i-1)    = x(i)
        idx(i-1) = idx(i)
        i = i+1
        if (i>n) exit          
        if (abs(x(i)) >= abs(xx)) exit
      end do
      x(i-1)    = xx
      idx(i-1) = ix
    endif
  enddo
end subroutine psi_saisrx_up

subroutine psi_saisrx_dw(n,x,ix)
  use psb_s_sort_mod, psb_protect_name => psi_saisrx_dw
  use psb_error_mod
  implicit none 
  real(psb_spk_), intent(inout)  :: x(:) 
  integer(psb_ipk_), intent(inout) :: ix(:)
  integer(psb_ipk_), intent(in)   :: n
  integer(psb_ipk_) :: i,j,ix
  real(psb_spk_) :: xx

  do j=n-1,1,-1
    if (abs(x(j+1)) > abs(x(j))) then
      xx = x(j)
      ix = idx(j) 
      i=j+1
      do 
        x(i-1)    = x(i)
        idx(i-1) = idx(i)
        i = i+1
        if (i>n) exit          
        if (abs(x(i)) <= abs(xx)) exit
      end do
      x(i-1)    = xx
      idx(i-1) = ix
    endif
  enddo
end subroutine psi_saisrx_dw

subroutine psi_saisr_up(n,x)
  use psb_s_sort_mod, psb_protect_name => psi_saisr_up
  use psb_error_mod
  implicit none 
  real(psb_spk_), intent(inout)  :: x(:) 
  integer(psb_ipk_), intent(in)   :: n
  integer(psb_ipk_) :: i,j
  real(psb_spk_) :: xx
  
  do j=n-1,1,-1
    if (abs(x(j+1)) < abs(x(j))) then
      xx = x(j)
      i=j+1
      do 
        x(i-1) = x(i)
        i = i+1
        if (i>n) exit          
        if (abs(x(i)) >= abs(xx)) exit
      end do
      x(i-1) = xx
    endif
  enddo
end subroutine psi_saisr_up

subroutine psi_saisr_dw(n,x)
  use psb_s_sort_mod, psb_protect_name => psi_saisr_dw
  use psb_error_mod
  implicit none 
  real(psb_spk_), intent(inout)  :: x(:) 
  integer(psb_ipk_), intent(in)   :: n
  integer(psb_ipk_) :: i,j
  real(psb_spk_) :: xx
  
  do j=n-1,1,-1
    if (abs(x(j+1)) > abs(x(j))) then
      xx = x(j)
      i=j+1
      do 
        x(i-1) = x(i)
        i = i+1
        if (i>n) exit          
        if (abs(x(i)) <= abs(xx)) exit
      end do
      x(i-1) = xx
    endif
  enddo
end subroutine psi_saisr_dw
