!   
!                Parallel Sparse BLAS  version 3.5
!      (C) Copyright 2006-2018
!        Salvatore Filippone    
!        Alfredo Buttari      
!   
!    Redistribution and use in source and binary forms, with or without
!    modification, are permitted provided that the following conditions
!    are met:
!      1. Redistributions of source code must retain the above copyright
!         notice, this list of conditions and the following disclaimer.
!      2. Redistributions in binary form must reproduce the above copyright
!         notice, this list of conditions, and the following disclaimer in the
!         documentation and/or other materials provided with the distribution.
!      3. The name of the PSBLAS group or the names of its contributors may
!         not be used to endorse or promote products derived from this
!         software without specific written permission.
!   
!    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
!    ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
!    TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
!    PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE PSBLAS GROUP OR ITS CONTRIBUTORS
!    BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
!    CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
!    SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
!    INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
!    CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
!    ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
!    POSSIBILITY OF SUCH DAMAGE.
!   
!    
! File:  psb_dnumbmm.f90 
! Subroutine: 
! Arguments:
!
!
! Note: This subroutine performs the numerical product of two sparse matrices.
!       It is modeled after the SMMP package by R. Bank and C. Douglas, but is 
!       rewritten in Fortran 95/2003 making use of our sparse matrix facilities.
!
!
subroutine psb_dnumbmm(a,b,c)
  use psb_base_mod, psb_protect_name => psb_dnumbmm
  implicit none 

  type(psb_dspmat_type), intent(in) :: a,b
  type(psb_dspmat_type), intent(inout)  :: c
  integer(psb_ipk_) :: info
  integer(psb_ipk_) :: err_act
  character(len=*), parameter ::  name='psb_numbmm'

  call psb_erractionsave(err_act)
  info = psb_success_

  if ((a%is_null()) .or.(b%is_null()).or.(c%is_null())) then
    info = psb_err_invalid_mat_state_
    call psb_errpush(info,name)
    goto 9999
  endif

  select type(aa=>c%a)
  type is (psb_d_csr_sparse_mat)
    call psb_numbmm(a%a,b%a,aa)
  class default
    info = psb_err_invalid_mat_state_
    call psb_errpush(info,name)
    goto 9999
  end select

  call c%set_asb()

  call psb_erractionrestore(err_act)
  return

9999 call psb_error_handler(err_act)

  return

end subroutine psb_dnumbmm

subroutine psb_dbase_numbmm(a,b,c)
  use psb_mat_mod
  use psb_string_mod
  use psb_serial_mod, psb_protect_name => psb_dbase_numbmm
  implicit none 

  class(psb_d_base_sparse_mat), intent(in) :: a,b
  type(psb_d_csr_sparse_mat), intent(inout)  :: c
  integer(psb_ipk_), allocatable  :: itemp(:)
  integer(psb_ipk_) :: nze, ma,na,mb,nb  
  character(len=20)     :: name
  real(psb_dpk_), allocatable :: temp(:)
  integer(psb_ipk_) :: info
  integer(psb_ipk_) :: err_act
  name='psb_numbmm'
  call psb_erractionsave(err_act)
  info = psb_success_


  ma = a%get_nrows()
  na = a%get_ncols()
  mb = b%get_nrows()
  nb = b%get_ncols()


  if ( mb /= na ) then 
    write(psb_err_unit,*) 'Mismatch in SYMBMM: ',ma,na,mb,nb
  endif
  allocate(temp(max(ma,na,mb,nb)),stat=info)    
  if (info /= psb_success_) then 
    info = psb_err_alloc_dealloc_ 
    call psb_Errpush(info,name)
    goto 9999
  endif

  !
  ! Note: we still have to test about possible performance hits. 
  !
  !
  call psb_ensure_size(ione*size(c%ja),c%val,info)
  select type(a)
  type is (psb_d_csr_sparse_mat) 
    select type(b)
    type is (psb_d_csr_sparse_mat) 
      call csr_numbmm(a,b,c,temp,info)
    class default
      call gen_numbmm(a,b,c,temp,info)
    end select
  class default
    call gen_numbmm(a,b,c,temp,info)
  end select
  
  if (info /= psb_success_) then 
    call psb_errpush(info,name)
    goto 9999
  end if

  call c%set_asb()
  deallocate(temp) 

  call psb_erractionrestore(err_act)
  return

9999 call psb_error_handler(err_act)

  return

contains 

  subroutine csr_numbmm(a,b,c,temp,info)
    type(psb_d_csr_sparse_mat), intent(in)  :: a,b
    type(psb_d_csr_sparse_mat), intent(inout) :: c
    real(psb_dpk_)                          :: temp(:)
    integer(psb_ipk_), intent(out)                    :: info
    integer(psb_ipk_) :: nze, ma,na,mb,nb

    info = psb_success_
    ma = a%get_nrows()
    na = a%get_ncols()
    mb = b%get_nrows()
    nb = b%get_ncols()
    
    call dnumbmm(ma,na,nb,a%irp,a%ja,izero,a%val,&
         & b%irp,b%ja,izero,b%val,&
         & c%irp,c%ja,izero,c%val,temp)

    
  end subroutine csr_numbmm

  subroutine gen_numbmm(a,b,c,temp,info)
    class(psb_d_base_sparse_mat), intent(in)  :: a,b
    type(psb_d_csr_sparse_mat), intent(inout) :: c
    integer(psb_ipk_) :: info
    real(psb_dpk_)      :: temp(:)
    integer(psb_ipk_), allocatable  :: iarw(:), iacl(:),ibrw(:),ibcl(:)
    real(psb_dpk_), allocatable :: aval(:),bval(:)
    integer(psb_ipk_) :: maxlmn,i,j,m,n,k,l,nazr,nbzr,jj,minlm,minmn,minln
    real(psb_dpk_)      :: ajj

    n = a%get_nrows()
    m = a%get_ncols() 
    l = b%get_ncols()
    maxlmn = max(l,m,n)
    allocate(iarw(maxlmn),iacl(maxlmn),ibrw(maxlmn),ibcl(maxlmn),&
         & aval(maxlmn),bval(maxlmn), stat=info)
    if (info /= psb_success_) then
      info = psb_err_alloc_dealloc_
      return
    endif

    do i = 1,maxlmn
      temp(i) = dzero
    end do
    minlm = min(l,m)
    minln = min(l,n)
    minmn = min(m,n)
    do  i = 1,n

      call a%csget(i,i,nazr,iarw,iacl,aval,info)
      do jj=1, nazr
        j=iacl(jj)
        ajj = aval(jj)
        if ((j<1).or.(j>m)) then 
          write(psb_err_unit,*) ' NUMBMM: Problem with A ',i,jj,j,m
            info = 1
            return
          
        endif
        call b%csget(j,j,nbzr,ibrw,ibcl,bval,info)
        do k=1,nbzr
          if ((ibcl(k)<1).or.(ibcl(k)>maxlmn)) then 
            write(psb_err_unit,*) 'Problem in NUMBM 1:',j,k,ibcl(k),maxlmn
            info = psb_err_pivot_too_small_
            return
          else
            temp(ibcl(k)) = temp(ibcl(k)) + ajj * bval(k)
          endif
        enddo
      end do
      do  j = c%irp(i),c%irp(i+1)-1
        if((c%ja(j)<1).or. (c%ja(j) > maxlmn))  then 
          write(psb_err_unit,*) ' NUMBMM: output problem',i,j,c%ja(j),maxlmn
            info = psb_err_invalid_ovr_num_
            return
        else
          c%val(j) = temp(c%ja(j))
          temp(c%ja(j)) = dzero
        endif
      end do
    end do

    
  end subroutine gen_numbmm

end subroutine psb_dbase_numbmm



subroutine psb_ldnumbmm(a,b,c)
  use psb_base_mod, psb_protect_name => psb_ldnumbmm
  implicit none 

  type(psb_ldspmat_type), intent(in) :: a,b
  type(psb_ldspmat_type), intent(inout)  :: c
  integer(psb_ipk_) :: info
  integer(psb_ipk_) :: err_act
  character(len=*), parameter ::  name='psb_numbmm'

  call psb_erractionsave(err_act)
  info = psb_success_

  if ((a%is_null()) .or.(b%is_null()).or.(c%is_null())) then
    info = psb_err_invalid_mat_state_
    call psb_errpush(info,name)
    goto 9999
  endif

  select type(aa=>c%a)
  type is (psb_ld_csr_sparse_mat)
    call psb_numbmm(a%a,b%a,aa)
  class default
    info = psb_err_invalid_mat_state_
    call psb_errpush(info,name)
    goto 9999
  end select

  call c%set_asb()

  call psb_erractionrestore(err_act)
  return

9999 call psb_error_handler(err_act)

  return

end subroutine psb_ldnumbmm

subroutine psb_ldbase_numbmm(a,b,c)
  use psb_mat_mod
  use psb_string_mod
  use psb_serial_mod, psb_protect_name => psb_ldbase_numbmm
  implicit none 

  class(psb_ld_base_sparse_mat), intent(in) :: a,b
  type(psb_ld_csr_sparse_mat), intent(inout)  :: c
  integer(psb_ipk_), allocatable  :: itemp(:)
  integer(psb_lpk_) :: nze, ma,na,mb,nb  
  character(len=20)     :: name
  real(psb_dpk_), allocatable :: temp(:)
  integer(psb_ipk_) :: info
  integer(psb_ipk_) :: err_act
  name='psb_numbmm'
  call psb_erractionsave(err_act)
  info = psb_success_


  ma = a%get_nrows()
  na = a%get_ncols()
  mb = b%get_nrows()
  nb = b%get_ncols()


  if ( mb /= na ) then 
    write(psb_err_unit,*) 'Mismatch in SYMBMM: ',ma,na,mb,nb
  endif
  allocate(temp(max(ma,na,mb,nb)),stat=info)    
  if (info /= psb_success_) then 
    info = psb_err_alloc_dealloc_ 
    call psb_Errpush(info,name)
    goto 9999
  endif

  !
  ! Note: we still have to test about possible performance hits. 
  !
  !
  call psb_ensure_size(ione*size(c%ja),c%val,info)
  select type(a)
  type is (psb_ld_csr_sparse_mat) 
    select type(b)
    type is (psb_ld_csr_sparse_mat) 
      call csr_numbmm(a,b,c,temp,info)
    class default
      call gen_numbmm(a,b,c,temp,info)
    end select
  class default
    call gen_numbmm(a,b,c,temp,info)
  end select
  
  if (info /= psb_success_) then 
    call psb_errpush(info,name)
    goto 9999
  end if

  call c%set_asb()
  deallocate(temp) 

  call psb_erractionrestore(err_act)
  return

9999 call psb_error_handler(err_act)

  return

contains 

  subroutine csr_numbmm(a,b,c,temp,info)
    type(psb_ld_csr_sparse_mat), intent(in)  :: a,b
    type(psb_ld_csr_sparse_mat), intent(inout) :: c
    real(psb_dpk_)                          :: temp(:)
    integer(psb_ipk_), intent(out)                    :: info
    integer(psb_lpk_) :: nze, ma,na,mb,nb

    info = psb_success_
    ma = a%get_nrows()
    na = a%get_ncols()
    mb = b%get_nrows()
    nb = b%get_ncols()
    
    call ldnumbmm(ma,na,nb,a%irp,a%ja,lzero,a%val,&
         & b%irp,b%ja,lzero,b%val,&
         & c%irp,c%ja,lzero,c%val,temp)

    
  end subroutine csr_numbmm

  subroutine gen_numbmm(a,b,c,temp,info)
    class(psb_ld_base_sparse_mat), intent(in)  :: a,b
    type(psb_ld_csr_sparse_mat), intent(inout) :: c
    integer(psb_ipk_) :: info
    real(psb_dpk_)      :: temp(:)
    integer(psb_lpk_), allocatable  :: iarw(:), iacl(:),ibrw(:),ibcl(:)
    real(psb_dpk_), allocatable :: aval(:),bval(:)
    integer(psb_lpk_) :: maxlmn,i,j,m,n,k,l,nazr,nbzr,jj,minlm,minmn,minln
    real(psb_dpk_)      :: ajj

    n = a%get_nrows()
    m = a%get_ncols() 
    l = b%get_ncols()
    maxlmn = max(l,m,n)
    allocate(iarw(maxlmn),iacl(maxlmn),ibrw(maxlmn),ibcl(maxlmn),&
         & aval(maxlmn),bval(maxlmn), stat=info)
    if (info /= psb_success_) then
      info = psb_err_alloc_dealloc_
      return
    endif

    do i = 1,maxlmn
      temp(i) = dzero
    end do
    minlm = min(l,m)
    minln = min(l,n)
    minmn = min(m,n)
    do  i = 1,n

      call a%csget(i,i,nazr,iarw,iacl,aval,info)
      do jj=1, nazr
        j=iacl(jj)
        ajj = aval(jj)
        if ((j<1).or.(j>m)) then 
          write(psb_err_unit,*) ' NUMBMM: Problem with A ',i,jj,j,m
            info = 1
            return
          
        endif
        call b%csget(j,j,nbzr,ibrw,ibcl,bval,info)
        do k=1,nbzr
          if ((ibcl(k)<1).or.(ibcl(k)>maxlmn)) then 
            write(psb_err_unit,*) 'Problem in NUMBM 1:',j,k,ibcl(k),maxlmn
            info = psb_err_pivot_too_small_
            return
          else
            temp(ibcl(k)) = temp(ibcl(k)) + ajj * bval(k)
          endif
        enddo
      end do
      do  j = c%irp(i),c%irp(i+1)-1
        if((c%ja(j)<1).or. (c%ja(j) > maxlmn))  then 
          write(psb_err_unit,*) ' NUMBMM: output problem',i,j,c%ja(j),maxlmn
            info = psb_err_invalid_ovr_num_
            return
        else
          c%val(j) = temp(c%ja(j))
          temp(c%ja(j)) = dzero
        endif
      end do
    end do

    
  end subroutine gen_numbmm

end subroutine psb_ldbase_numbmm
