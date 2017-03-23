!   
!                Parallel Sparse BLAS  version 3.4
!      (C) Copyright 2006, 2010, 2015
!                         Salvatore Filippone    University of Rome Tor Vergata
!                         Alfredo Buttari        CNRS-IRIT, Toulouse
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

subroutine psb_c_coo_get_diag(a,d,info) 
  use psb_c_base_mat_mod, psb_protect_name => psb_c_coo_get_diag
  use psb_error_mod
  use psb_const_mod
  implicit none 
  class(psb_c_coo_sparse_mat), intent(in) :: a
  complex(psb_spk_), intent(out)     :: d(:)
  integer(psb_ipk_), intent(out)            :: info

  integer(psb_ipk_) :: err_act,mnm, i, j
  integer(psb_ipk_) :: ierr(5)
  character(len=20)  :: name='get_diag'
  logical, parameter :: debug=.false.

  info  = psb_success_
  call psb_erractionsave(err_act)
  if (a%is_dev())   call a%sync()

  mnm = min(a%get_nrows(),a%get_ncols())
  if (size(d) < mnm) then 
    info=psb_err_input_asize_invalid_i_
    ierr(1) = 2; ierr(2) = size(d); 
    call psb_errpush(info,name,i_err=ierr)
    goto 9999
  end if

  if (a%is_unit()) then 
    d(1:mnm) = cone 
  else
    d(1:mnm) = czero
    do i=1,a%get_nzeros()
      j=a%ia(i)
      if ((j == a%ja(i)) .and.(j <= mnm ) .and.(j>0)) then 
        d(j) = a%val(i)
      endif
    enddo
  end if
  call psb_erractionrestore(err_act)
  return

9999 call psb_error_handler(err_act)

  return

end subroutine psb_c_coo_get_diag


subroutine psb_c_coo_scal(d,a,info,side) 
  use psb_c_base_mat_mod, psb_protect_name => psb_c_coo_scal
  use psb_error_mod
  use psb_const_mod
  use psb_string_mod
  implicit none 
  class(psb_c_coo_sparse_mat), intent(inout) :: a
  complex(psb_spk_), intent(in)      :: d(:)
  integer(psb_ipk_), intent(out)            :: info
  character, intent(in), optional :: side

  integer(psb_ipk_) :: err_act,mnm, i, j, m
  integer(psb_ipk_) :: ierr(5)
  character(len=20)  :: name='scal'
  character :: side_
  logical   :: left 
  logical, parameter :: debug=.false.

  info  = psb_success_
  call psb_erractionsave(err_act)
  if (a%is_dev())   call a%sync()

  if (a%is_unit()) then 
    call a%make_nonunit()
  end if

  side_ = 'L'
  if (present(side)) then 
    side_ = psb_toupper(side)
  end if

  left = (side_ == 'L')
  
  if (left) then 
    m = a%get_nrows()
    if (size(d) < m) then 
      info=psb_err_input_asize_invalid_i_
      ierr(1) = 2; ierr(2) = size(d); 
      call psb_errpush(info,name,i_err=ierr)
      goto 9999
    end if
    
    do i=1,a%get_nzeros()
      j        = a%ia(i)
      a%val(i) = a%val(i) * d(j)
    enddo
  else
    m = a%get_ncols()
    if (size(d) < m) then 
      info=psb_err_input_asize_invalid_i_
      ierr(1) = 2; ierr(2) = size(d); 
      call psb_errpush(info,name,i_err=ierr)
      goto 9999
    end if
    
    do i=1,a%get_nzeros()
      j        = a%ja(i)
      a%val(i) = a%val(i) * d(j)
    enddo
  end if
  call a%set_host()

  call psb_erractionrestore(err_act)
  return

9999 call psb_error_handler(err_act)

  return

end subroutine psb_c_coo_scal


subroutine psb_c_coo_scals(d,a,info) 
  use psb_c_base_mat_mod, psb_protect_name => psb_c_coo_scals
  use psb_error_mod
  use psb_const_mod
  implicit none 
  class(psb_c_coo_sparse_mat), intent(inout) :: a
  complex(psb_spk_), intent(in)      :: d
  integer(psb_ipk_), intent(out)            :: info

  integer(psb_ipk_) :: err_act,mnm, i, j, m
  integer(psb_ipk_) :: ierr(5)
  character(len=20)  :: name='scal'
  logical, parameter :: debug=.false.

  info  = psb_success_
  call psb_erractionsave(err_act)
  if (a%is_dev())   call a%sync()

  if (a%is_unit()) then 
    call a%make_nonunit()
  end if

  do i=1,a%get_nzeros()
    a%val(i) = a%val(i) * d
  enddo
  call a%set_host()

  call psb_erractionrestore(err_act)
  return

9999 call psb_error_handler(err_act)

  return

end subroutine psb_c_coo_scals


subroutine  psb_c_coo_reallocate_nz(nz,a) 
  use psb_c_base_mat_mod, psb_protect_name => psb_c_coo_reallocate_nz
  use psb_error_mod
  use psb_realloc_mod
  implicit none 
  integer(psb_ipk_), intent(in) :: nz
  class(psb_c_coo_sparse_mat), intent(inout) :: a
  integer(psb_ipk_) :: err_act, info, nz_
  integer(psb_ipk_) :: ierr(5)
  character(len=20)  :: name='c_coo_reallocate_nz'
  logical, parameter :: debug=.false.

  call psb_erractionsave(err_act)

  nz_ = max(nz,ione)
  call psb_realloc(nz_,a%ia,a%ja,a%val,info)

  if (info /= psb_success_) then 
    call psb_errpush(psb_err_alloc_dealloc_,name)
    goto 9999
  end if

  call psb_erractionrestore(err_act)
  return

9999 call psb_error_handler(err_act)

  return

end subroutine psb_c_coo_reallocate_nz

subroutine psb_c_coo_mold(a,b,info) 
  use psb_c_base_mat_mod, psb_protect_name => psb_c_coo_mold
  use psb_error_mod
  implicit none 
  class(psb_c_coo_sparse_mat), intent(in)                  :: a
  class(psb_c_base_sparse_mat), intent(inout), allocatable :: b
  integer(psb_ipk_), intent(out)                    :: info
  integer(psb_ipk_) :: err_act
  integer(psb_ipk_) :: ierr(5)
  character(len=20)  :: name='coo_mold'
  logical, parameter :: debug=.false.

  call psb_get_erraction(err_act)
  
  info = 0 
  if (allocated(b)) then 
    call b%free()
    deallocate(b,stat=info)
  end if
  if (info == 0) allocate(psb_c_coo_sparse_mat :: b, stat=info)

  if (info /= 0) then 
    info = psb_err_alloc_dealloc_ 
    call psb_errpush(info, name)
    goto 9999
  end if
  return

9999 call psb_error_handler(err_act)

  return

end subroutine psb_c_coo_mold

subroutine psb_c_coo_reinit(a,clear)
  use psb_c_base_mat_mod, psb_protect_name => psb_c_coo_reinit
  use psb_error_mod
  implicit none 

  class(psb_c_coo_sparse_mat), intent(inout) :: a   
  logical, intent(in), optional :: clear

  integer(psb_ipk_) :: err_act, info
  integer(psb_ipk_) :: ierr(5)
  character(len=20)  :: name='reinit'
  logical  :: clear_
  logical, parameter :: debug=.false.

  call psb_erractionsave(err_act)
  info = psb_success_


  if (present(clear)) then 
    clear_ = clear
  else
    clear_ = .true.
  end if

  if (a%is_dev())   call a%sync()
  if (a%is_bld() .or. a%is_upd()) then 
    ! do nothing
    return
  else if (a%is_asb()) then 
    if (clear_) a%val(:) = czero
    call a%set_host()
    call a%set_upd()
  else
    info = psb_err_invalid_mat_state_
    call psb_errpush(info,name)
    goto 9999
  end if

  call psb_erractionrestore(err_act)
  return

9999 call psb_error_handler(err_act)

  return

end subroutine psb_c_coo_reinit



subroutine  psb_c_coo_trim(a)
  use psb_c_base_mat_mod, psb_protect_name => psb_c_coo_trim
  use psb_realloc_mod
  use psb_error_mod
  implicit none 
  class(psb_c_coo_sparse_mat), intent(inout) :: a
  integer(psb_ipk_) :: err_act, info, nz
  integer(psb_ipk_) :: ierr(5)
  character(len=20)  :: name='trim'
  logical, parameter :: debug=.false.

  call psb_erractionsave(err_act)
  info = psb_success_
  if (a%is_dev())   call a%sync()
  nz  = a%get_nzeros()
  if (info == psb_success_) call psb_realloc(nz,a%ia,info)
  if (info == psb_success_) call psb_realloc(nz,a%ja,info)
  if (info == psb_success_) call psb_realloc(nz,a%val,info)

  if (info /= psb_success_) goto 9999 
  call psb_erractionrestore(err_act)
  return

9999 call psb_error_handler(err_act)

  return

end subroutine psb_c_coo_trim

subroutine  psb_c_coo_clean_zeros(a, info)
  use psb_error_mod
  use psb_c_base_mat_mod, psb_protect_name => psb_c_coo_clean_zeros
  implicit none 
  class(psb_c_coo_sparse_mat), intent(inout) :: a
  integer(psb_ipk_) :: info
  !
  integer(psb_ipk_) :: i,j,k, nzin

  info = 0 
  nzin = a%get_nzeros()
  j = 0
  do i=1, nzin
    if (a%val(i) /= czero) then
      j = j + 1
      a%val(j) = a%val(i)
      a%ia(j)  = a%ia(i)
      a%ja(j)  = a%ja(i)
    end if
  end do
  call a%set_nzeros(j) 
  call a%trim()
end subroutine psb_c_coo_clean_zeros



subroutine  psb_c_coo_allocate_mnnz(m,n,a,nz) 
  use psb_c_base_mat_mod, psb_protect_name => psb_c_coo_allocate_mnnz
  use psb_error_mod
  use psb_realloc_mod
  implicit none 
  integer(psb_ipk_), intent(in) :: m,n
  class(psb_c_coo_sparse_mat), intent(inout) :: a
  integer(psb_ipk_), intent(in), optional :: nz
  integer(psb_ipk_) :: err_act, info, nz_
  integer(psb_ipk_) :: ierr(5)
  character(len=20)  :: name='allocate_mnz'
  logical, parameter :: debug=.false.

  call psb_erractionsave(err_act)
  info = psb_success_
  if (m < 0) then 
    info = psb_err_iarg_neg_
    ierr(1) = ione; ierr(2) = izero; 
    call psb_errpush(info,name,i_err=ierr)
    goto 9999
  endif
  if (n < 0) then 
    info = psb_err_iarg_neg_
    ierr(1) = 2; ierr(2) = izero; 
    call psb_errpush(info,name,i_err=ierr)
    goto 9999
  endif
  if (present(nz)) then 
    nz_ = max(nz,ione)
  else
    nz_ = max(7*m,7*n,ione)
  end if
  if (nz_ < 0) then 
    info = psb_err_iarg_neg_
    ierr(1) = 3; ierr(2) = izero; 
    call psb_errpush(info,name,i_err=ierr)
    goto 9999
  endif
  if (info == psb_success_) call psb_realloc(nz_,a%ia,info)
  if (info == psb_success_) call psb_realloc(nz_,a%ja,info)
  if (info == psb_success_) call psb_realloc(nz_,a%val,info)
  if (info == psb_success_) then 
    call a%set_nrows(m)
    call a%set_ncols(n)
    call a%set_nzeros(izero)
    call a%set_bld()
    call a%set_triangle(.false.)
    call a%set_unit(.false.)
    call a%set_dupl(psb_dupl_def_)
    ! An empty matrix is sorted!
    call a%set_sorted(.true.)
    call a%set_host()
  end if
  if (info /= psb_success_) goto 9999 
  call psb_erractionrestore(err_act)
  return

9999 call psb_error_handler(err_act)

  return

end subroutine psb_c_coo_allocate_mnnz



subroutine psb_c_coo_print(iout,a,iv,head,ivr,ivc)
  use psb_c_base_mat_mod, psb_protect_name => psb_c_coo_print
  use psb_string_mod
  implicit none 

  integer(psb_ipk_), intent(in)               :: iout
  class(psb_c_coo_sparse_mat), intent(in) :: a   
  integer(psb_ipk_), intent(in), optional     :: iv(:)
  character(len=*), optional        :: head
  integer(psb_ipk_), intent(in), optional     :: ivr(:), ivc(:)

  integer(psb_ipk_) :: err_act
  integer(psb_ipk_) :: ierr(5)
  character(len=20)  :: name='c_coo_print'
  logical, parameter :: debug=.false.

  character(len=*), parameter  :: datatype='complex'
  character(len=80)                 :: frmtv 
  integer(psb_ipk_) :: i,j, nmx, ni, nr, nc, nz

  write(iout,'(a)') '%%MatrixMarket matrix coordinate complex general'
  if (present(head)) write(iout,'(a,a)') '% ',head 
  write(iout,'(a)') '%'    
  write(iout,'(a,a)') '% COO'

  if (a%is_dev())   call a%sync()

  nr = a%get_nrows()
  nc = a%get_ncols()
  nz = a%get_nzeros()
  nmx = max(nr,nc,1)
  if (present(iv))  nmx = max(nmx,maxval(abs(iv)))
  if (present(ivr)) nmx = max(nmx,maxval(abs(ivr)))
  if (present(ivc)) nmx = max(nmx,maxval(abs(ivc)))
  ni  = floor(log10(1.0*nmx)) + 1

  if (datatype=='real') then 
    write(frmtv,'(a,i3.3,a,i3.3,a)') '(2(i',ni,',1x),es26.18,1x,2(i',ni,',1x))'
  else 
    write(frmtv,'(a,i3.3,a,i3.3,a)') '(2(i',ni,',1x),2(es26.18,1x),2(i',ni,',1x))'
  end if
  write(iout,*) nr, nc, nz 
  if(present(iv)) then 
    do j=1,a%get_nzeros()
      write(iout,frmtv) iv(a%ia(j)),iv(a%ja(j)),a%val(j)
    enddo
  else      
    if (present(ivr).and..not.present(ivc)) then 
      do j=1,a%get_nzeros()
        write(iout,frmtv) ivr(a%ia(j)),a%ja(j),a%val(j)
      enddo
    else if (present(ivr).and.present(ivc)) then 
      do j=1,a%get_nzeros()
        write(iout,frmtv) ivr(a%ia(j)),ivc(a%ja(j)),a%val(j)
      enddo
    else if (.not.present(ivr).and.present(ivc)) then 
      do j=1,a%get_nzeros()
        write(iout,frmtv) a%ia(j),ivc(a%ja(j)),a%val(j)
      enddo
    else if (.not.present(ivr).and..not.present(ivc)) then 
      do j=1,a%get_nzeros()
        write(iout,frmtv) a%ia(j),a%ja(j),a%val(j)
      enddo
    endif
  endif

end subroutine psb_c_coo_print




function  psb_c_coo_get_nz_row(idx,a) result(res)
  use psb_const_mod
  use psb_sort_mod
  use psb_c_base_mat_mod, psb_protect_name => psb_c_coo_get_nz_row    
  implicit none

  class(psb_c_coo_sparse_mat), intent(in) :: a
  integer(psb_ipk_), intent(in)                  :: idx
  integer(psb_ipk_) :: res
  integer(psb_ipk_) :: nzin_, nza,ip,jp,i,k

  if (a%is_dev())   call a%sync()
  res = 0 
  nza = a%get_nzeros()
  if (a%is_by_rows()) then 
    ! In this case we can do a binary search. 
    ip = psb_ibsrch(idx,nza,a%ia)
    if (ip /= -1) return
    jp = ip 
    do 
      if (ip < 2) exit
      if (a%ia(ip-1) == idx) then  
        ip = ip -1 
      else 
        exit
      end if
    end do
    do 
      if (jp == nza) exit
      if (a%ia(jp+1) == idx) then  
        jp = jp + 1
      else 
        exit
      end if
    end do

    res = jp - ip +1 

  else

    res = 0

    do i=1, nza
      if (a%ia(i) == idx) then 
        res = res + 1 
      end if
    end do

  end if

end function psb_c_coo_get_nz_row

subroutine psb_c_coo_cssm(alpha,a,x,beta,y,info,trans) 
  use psb_const_mod
  use psb_error_mod
  use psb_string_mod
  use psb_c_base_mat_mod, psb_protect_name => psb_c_coo_cssm
  implicit none 
  class(psb_c_coo_sparse_mat), intent(in) :: a
  complex(psb_spk_), intent(in)          :: alpha, beta, x(:,:)
  complex(psb_spk_), intent(inout)       :: y(:,:)
  integer(psb_ipk_), intent(out)                :: info
  character, optional, intent(in)     :: trans

  character :: trans_
  integer(psb_ipk_) :: i,j,k,m,n, nnz, ir, jc, nc
  complex(psb_spk_) :: acc
  complex(psb_spk_), allocatable :: tmp(:,:)
  logical   :: tra, ctra
  integer(psb_ipk_) :: err_act
  integer(psb_ipk_) :: ierr(5)
  character(len=20)  :: name='c_base_csmm'
  logical, parameter :: debug=.false.

  info = psb_success_
  call psb_erractionsave(err_act)

  if (.not.a%is_asb()) then 
    info = psb_err_invalid_mat_state_
    call psb_errpush(info,name)
    goto 9999
  endif
  if (a%is_dev())   call a%sync()

  if (.not. (a%is_triangle())) then 
    info = psb_err_invalid_mat_state_
    call psb_errpush(info,name)
    goto 9999
  end if

  if (present(trans)) then
    trans_ = trans
  else
    trans_ = 'N'
  end if
  tra  = (psb_toupper(trans_) == 'T')
  ctra = (psb_toupper(trans_) == 'C')
  m   = a%get_nrows()
  if (size(x,1) < m) then
    info = psb_err_input_asize_small_i_
    ierr(1) = 3; ierr(2) = m; 
    call psb_errpush(info,name,i_err=ierr)
    goto 9999
  end if
  if (size(y,1) < m) then
    info = psb_err_input_asize_small_i_
    ierr(1) = 5; ierr(2) = m; 
    call psb_errpush(info,name,i_err=ierr)
    goto 9999
  end if

  nc  = min(size(x,2) , size(y,2)) 
  nnz = a%get_nzeros()

  if (alpha == czero) then
    if (beta == czero) then
      do i = 1, m
        y(i,1:nc) = czero
      enddo
    else
      do  i = 1, m
        y(i,1:nc) = beta*y(i,1:nc)
      end do
    endif
    return
  end if

  if (beta == czero) then 
    call inner_coosm(tra,ctra,a%is_lower(),a%is_unit(),a%is_by_rows(),&
         & m,nc,nnz,a%ia,a%ja,a%val,&
         & x,size(x,1,kind=psb_ipk_),y,size(y,1,kind=psb_ipk_),info)
    do  i = 1, m
      y(i,1:nc) = alpha*y(i,1:nc)
    end do
  else 
    allocate(tmp(m,nc), stat=info) 
    if(info /= psb_success_) then
      info=psb_err_from_subroutine_
      call psb_errpush(info,name,a_err='allocate')
      goto 9999
    end if

    call inner_coosm(tra,ctra,a%is_lower(),a%is_unit(),a%is_by_rows(),&
         & m,nc,nnz,a%ia,a%ja,a%val,&
         & x,size(x,1,kind=psb_ipk_),tmp,size(tmp,1,kind=psb_ipk_),info)
    do  i = 1, m
      y(i,1:nc) = alpha*tmp(i,1:nc) + beta*y(i,1:nc)
    end do
  end if

  if(info /= psb_success_) then
    info=psb_err_from_subroutine_
    call psb_errpush(info,name,a_err='inner_coosm')
    goto 9999
  end if

  call psb_erractionrestore(err_act)
  return


9999 call psb_error_handler(err_act)

  return


contains 

  subroutine inner_coosm(tra,ctra,lower,unit,sorted,nr,nc,nz,&
       & ia,ja,val,x,ldx,y,ldy,info) 
    implicit none 
    logical, intent(in)                 :: tra,ctra,lower,unit,sorted
    integer(psb_ipk_), intent(in)                 :: nr,nc,nz,ldx,ldy,ia(*),ja(*)
    complex(psb_spk_), intent(in)          :: val(*), x(ldx,*)
    complex(psb_spk_), intent(out)         :: y(ldy,*)
    integer(psb_ipk_), intent(out)                :: info

    integer(psb_ipk_) :: i,j,k,m, ir, jc
    complex(psb_spk_), allocatable  :: acc(:)

    info = psb_success_
    allocate(acc(nc), stat=info)
    if(info /= psb_success_) then
      info=psb_err_from_subroutine_
      return
    end if


    if (.not.sorted) then 
      info = psb_err_invalid_mat_state_
      return
    end if

    nnz = nz


    if ((.not.tra).and.(.not.ctra)) then 

      if (lower) then 
        if (unit) then 
          j = 1
          do i=1, nr
            acc(1:nc) = czero
            do 
              if (j > nnz) exit
              if (ia(j) > i) exit
              acc(1:nc) = acc(1:nc) + val(j)*y(ja(j),1:nc)
              j   = j + 1
            end do
            y(i,1:nc) = x(i,1:nc) - acc(1:nc)
          end do
        else if (.not.unit) then 
          j = 1
          do i=1, nr
            acc(1:nc) = czero
            do 
              if (j > nnz) exit
              if (ia(j) > i) exit
              if (ja(j) == i) then 
                y(i,1:nc) = (x(i,1:nc) - acc(1:nc))/val(j)
                j = j + 1
                exit
              end if
              acc(1:nc) = acc(1:nc) + val(j)*y(ja(j),1:nc)
              j   = j + 1
            end do
          end do
        end if

      else if (.not.lower) then 
        if (unit) then 
          j = nnz
          do i=nr, 1, -1 
            acc(1:nc) = czero 
            do 
              if (j < 1) exit
              if (ia(j) < i) exit
              acc(1:nc) = acc(1:nc) + val(j)*x(ja(j),1:nc)
              j   = j - 1
            end do
            y(i,1:nc) = x(i,1:nc) - acc(1:nc)
          end do

        else if (.not.unit) then 

          j = nnz
          do i=nr, 1, -1 
            acc(1:nc) = czero 
            do 
              if (j < 1) exit
              if (ia(j) < i) exit
              if (ja(j) == i) then 
                y(i,1:nc) = (x(i,1:nc) - acc(1:nc))/val(j)
                j = j - 1
                exit
              end if
              acc(1:nc) = acc(1:nc) + val(j)*y(ja(j),1:nc)
              j   = j - 1
            end do
          end do
        end if

      end if

    else if (tra) then 

      do i=1, nr
        y(i,1:nc) = x(i,1:nc)
      end do

      if (lower) then 
        if (unit) then 
          j = nnz
          do i=nr, 1, -1
            acc(1:nc) = y(i,1:nc) 
            do
              if (j < 1) exit
              if (ia(j) < i) exit
              jc    = ja(j)
              y(jc,1:nc) = y(jc,1:nc) - val(j)*acc(1:nc) 
              j     = j - 1 
            end do
          end do
        else if (.not.unit) then 
          j = nnz
          do i=nr, 1, -1
            if (ja(j) == i) then 
              y(i,1:nc) = y(i,1:nc) /val(j)
              j    = j - 1
            end if
            acc(1:nc)  = y(i,1:nc) 
            do 
              if (j < 1) exit
              if (ia(j) < i) exit
              jc    = ja(j)
              y(jc,1:nc) = y(jc,1:nc) - val(j)*acc(1:nc) 
              j     = j - 1
            end do
          end do

        else if (.not.lower) then 
          if (unit) then 
            j = 1
            do i=1, nr
              acc(1:nc) = y(i,1:nc)
              do 
                if (j > nnz) exit
                if (ia(j) > i) exit
                jc    = ja(j)
                y(jc,1:nc) = y(jc,1:nc) - val(j)*acc(1:nc) 
                j   = j + 1
              end do
            end do
          else if (.not.unit) then 
            j = 1
            do i=1, nr
              if (ja(j) == i) then 
                y(i,1:nc) = y(i,1:nc) /val(j)
                j    = j + 1
              end if
              acc(1:nc) = y(i,1:nc)
              do 
                if (j > nnz) exit
                if (ia(j) > i) exit
                jc    = ja(j)
                y(jc,1:nc) = y(jc,1:nc) - val(j)*acc(1:nc) 
                j   = j + 1
              end do
            end do
          end if
        end if
      end if

    else if (ctra) then 

      do i=1, nr
        y(i,1:nc) = x(i,1:nc)
      end do

      if (lower) then 
        if (unit) then 
          j = nnz
          do i=nr, 1, -1
            acc(1:nc) = y(i,1:nc) 
            do
              if (j < 1) exit
              if (ia(j) < i) exit
              jc    = ja(j)
              y(jc,1:nc) = y(jc,1:nc) - conjg(val(j))*acc(1:nc) 
              j     = j - 1 
            end do
          end do
        else if (.not.unit) then 
          j = nnz
          do i=nr, 1, -1
            if (ja(j) == i) then 
              y(i,1:nc) = y(i,1:nc) / conjg(val(j))
              j    = j - 1
            end if
            acc(1:nc)  = y(i,1:nc) 
            do 
              if (j < 1) exit
              if (ia(j) < i) exit
              jc    = ja(j)
              y(jc,1:nc) = y(jc,1:nc) - conjg(val(j))*acc(1:nc) 
              j     = j - 1
            end do
          end do

        else if (.not.lower) then 
          if (unit) then 
            j = 1
            do i=1, nr
              acc(1:nc) = y(i,1:nc)
              do 
                if (j > nnz) exit
                if (ia(j) > i) exit
                jc    = ja(j)
                y(jc,1:nc) = y(jc,1:nc) - conjg(val(j))*acc(1:nc) 
                j   = j + 1
              end do
            end do
          else if (.not.unit) then 
            j = 1
            do i=1, nr
              if (ja(j) == i) then 
                y(i,1:nc) = y(i,1:nc) / conjg(val(j))
                j    = j + 1
              end if
              acc(1:nc) = y(i,1:nc)
              do 
                if (j > nnz) exit
                if (ia(j) > i) exit
                jc    = ja(j)
                y(jc,1:nc) = y(jc,1:nc) - conjg(val(j))*acc(1:nc) 
                j   = j + 1
              end do
            end do
          end if
        end if
      end if

    end if
  end subroutine inner_coosm

end subroutine psb_c_coo_cssm



subroutine psb_c_coo_cssv(alpha,a,x,beta,y,info,trans) 
  use psb_const_mod
  use psb_error_mod
  use psb_string_mod
  use psb_c_base_mat_mod, psb_protect_name => psb_c_coo_cssv
  implicit none 
  class(psb_c_coo_sparse_mat), intent(in) :: a
  complex(psb_spk_), intent(in)          :: alpha, beta, x(:)
  complex(psb_spk_), intent(inout)       :: y(:)
  integer(psb_ipk_), intent(out)                :: info
  character, optional, intent(in)     :: trans

  character :: trans_
  integer(psb_ipk_) :: i,j,k,m,n, nnz, ir, jc
  complex(psb_spk_) :: acc
  complex(psb_spk_), allocatable :: tmp(:)
  logical   :: tra, ctra
  integer(psb_ipk_) :: err_act
  integer(psb_ipk_) :: ierr(5)
  character(len=20)  :: name='c_coo_cssv_impl'
  logical, parameter :: debug=.false.

  info = psb_success_
  call psb_erractionsave(err_act)

  if (present(trans)) then
    trans_ = trans
  else
    trans_ = 'N'
  end if
  if (.not.a%is_asb()) then 
    info = psb_err_invalid_mat_state_
    call psb_errpush(info,name)
    goto 9999
  endif
  if (a%is_dev())   call a%sync()

  tra  = (psb_toupper(trans_) == 'T')
  ctra = (psb_toupper(trans_) == 'C')
  m = a%get_nrows()
  if (size(x,1) < m) then
    info = psb_err_input_asize_small_i_
    ierr(1) = 3; ierr(2) = m; 
    call psb_errpush(info,name,i_err=ierr)
    goto 9999
  end if
  if (size(y,1) < m) then
    info = psb_err_input_asize_small_i_
    ierr(1) = 5; ierr(2) = m; 
    call psb_errpush(info,name,i_err=ierr)
    goto 9999
  end if
  if (.not. (a%is_triangle())) then 
    info = psb_err_invalid_mat_state_
    call psb_errpush(info,name)
    goto 9999
  end if


  if (alpha == czero) then
    if (beta == czero) then
      do i = 1, m
        y(i) = czero
      enddo
    else
      do  i = 1, m
        y(i) = beta*y(i)
      end do
    endif
    return
  end if

  if (beta == czero) then 
    call inner_coosv(tra,ctra,a%is_lower(),a%is_unit(),a%is_by_rows(),&
         & a%get_nrows(),a%get_nzeros(),a%ia,a%ja,a%val,&
         & x,y,info)
    if (info /= psb_success_) then 
      call psb_errpush(info,name)
      goto 9999
    end if
    do  i = 1, m
      y(i) = alpha*y(i)
    end do
  else 
    allocate(tmp(m), stat=info) 
    if (info /= psb_success_) then 
      info=psb_err_from_subroutine_
      call psb_errpush(info,name,a_err='allocate')
      goto 9999
    end if

    call inner_coosv(tra,ctra,a%is_lower(),a%is_unit(),a%is_by_rows(),&
         & a%get_nrows(),a%get_nzeros(),a%ia,a%ja,a%val,&
         & x,tmp,info)
    if (info /= psb_success_) then 
      call psb_errpush(info,name)
      goto 9999
    end if
    do  i = 1, m
      y(i) = alpha*tmp(i) + beta*y(i)
    end do
  end if

  call psb_erractionrestore(err_act)
  return

9999 call psb_error_handler(err_act)

  return

contains 

  subroutine inner_coosv(tra,ctra,lower,unit,sorted,nr,nz,&
       & ia,ja,val,x,y,info) 
    implicit none 
    logical, intent(in)                 :: tra,ctra,lower,unit,sorted
    integer(psb_ipk_), intent(in)                 :: nr,nz,ia(*),ja(*)
    complex(psb_spk_), intent(in)          :: val(*), x(*)
    complex(psb_spk_), intent(out)         :: y(*)
    integer(psb_ipk_), intent(out)                :: info

    integer(psb_ipk_) :: i,j,k,m, ir, jc, nnz
    complex(psb_spk_) :: acc

    info = psb_success_
    if (.not.sorted) then 
      info = psb_err_invalid_mat_state_
      return
    end if

    nnz = nz

    if ((.not.tra).and.(.not.ctra)) then 

      if (lower) then 
        if (unit) then 
          j = 1
          do i=1, nr
            acc = czero
            do 
              if (j > nnz) exit
              if (ia(j) > i) exit
              acc = acc + val(j)*y(ja(j))
              j   = j + 1
            end do
            y(i) = x(i) - acc
          end do
        else if (.not.unit) then 
          j = 1
          do i=1, nr
            acc = czero
            do 
              if (j > nnz) exit
              if (ia(j) > i) exit
              if (ja(j) == i) then 
                y(i) = (x(i) - acc)/val(j)
                j = j + 1
                exit
              end if
              acc = acc + val(j)*y(ja(j))
              j   = j + 1
            end do
          end do
        end if

      else if (.not.lower) then 
        if (unit) then 
          j = nnz
          do i=nr, 1, -1 
            acc = czero 
            do 
              if (j < 1) exit
              if (ia(j) < i) exit
              acc = acc + val(j)*y(ja(j))
              j   = j - 1
            end do
            y(i) = x(i) - acc
          end do

        else if (.not.unit) then 

          j = nnz
          do i=nr, 1, -1 
            acc = czero 
            do 
              if (j < 1) exit
              if (ia(j) < i) exit
              if (ja(j) == i) then 
                y(i) = (x(i) - acc)/val(j)
                j = j - 1
                exit
              end if
              acc = acc + val(j)*y(ja(j))
              j   = j - 1
            end do
          end do
        end if

      end if

    else if (tra) then 

      do i=1, nr
        y(i) = x(i)
      end do

      if (lower) then 
        if (unit) then 
          j = nnz
          do i=nr, 1, -1
            acc = y(i) 
            do
              if (j < 1) exit
              if (ia(j) < i) exit
              jc    = ja(j)
              y(jc) = y(jc) - val(j)*acc 
              j     = j - 1 
            end do
          end do
        else if (.not.unit) then 
          j = nnz
          do i=nr, 1, -1
            if (ja(j) == i) then 
              y(i) = y(i) /val(j)
              j    = j - 1
            end if
            acc  = y(i) 
            do 
              if (j < 1) exit
              if (ia(j) < i) exit
              jc    = ja(j)
              y(jc) = y(jc) - val(j)*acc 
              j     = j - 1
            end do
          end do

        else if (.not.lower) then 
          if (unit) then 
            j = 1
            do i=1, nr
              acc = y(i)
              do 
                if (j > nnz) exit
                if (ia(j) > i) exit
                jc    = ja(j)
                y(jc) = y(jc) - val(j)*acc 
                j   = j + 1
              end do
            end do
          else if (.not.unit) then 
            j = 1
            do i=1, nr
              if (ja(j) == i) then 
                y(i) = y(i) /val(j)
                j    = j + 1
              end if
              acc = y(i)
              do 
                if (j > nnz) exit
                if (ia(j) > i) exit
                jc    = ja(j)
                y(jc) = y(jc) - val(j)*acc 
                j   = j + 1
              end do
            end do
          end if
        end if
      end if

    else if (ctra) then 

      do i=1, nr
        y(i) = x(i)
      end do

      if (lower) then 
        if (unit) then 
          j = nnz
          do i=nr, 1, -1
            acc = y(i) 
            do
              if (j < 1) exit
              if (ia(j) < i) exit
              jc    = ja(j)
              y(jc) = y(jc) - conjg(val(j))*acc 
              j     = j - 1 
            end do
          end do
        else if (.not.unit) then 
          j = nnz
          do i=nr, 1, -1
            if (ja(j) == i) then 
              y(i) = y(i) /conjg(val(j))
              j    = j - 1
            end if
            acc  = y(i) 
            do 
              if (j < 1) exit
              if (ia(j) < i) exit
              jc    = ja(j)
              y(jc) = y(jc) - conjg(val(j))*acc 
              j     = j - 1
            end do
          end do

        else if (.not.lower) then 
          if (unit) then 
            j = 1
            do i=1, nr
              acc = y(i)
              do 
                if (j > nnz) exit
                if (ia(j) > i) exit
                jc    = ja(j)
                y(jc) = y(jc) - conjg(val(j))*acc 
                j   = j + 1
              end do
            end do
          else if (.not.unit) then 
            j = 1
            do i=1, nr
              if (ja(j) == i) then 
                y(i) = y(i) /conjg(val(j))
                j    = j + 1
              end if
              acc = y(i)
              do 
                if (j > nnz) exit
                if (ia(j) > i) exit
                jc    = ja(j)
                y(jc) = y(jc) - conjg(val(j))*acc 
                j   = j + 1
              end do
            end do
          end if
        end if
      end if
    end if

  end subroutine inner_coosv


end subroutine psb_c_coo_cssv

subroutine psb_c_coo_csmv(alpha,a,x,beta,y,info,trans) 
  use psb_const_mod
  use psb_error_mod
  use psb_string_mod
  use psb_c_base_mat_mod, psb_protect_name => psb_c_coo_csmv
  implicit none 

  class(psb_c_coo_sparse_mat), intent(in) :: a
  complex(psb_spk_), intent(in)          :: alpha, beta, x(:)
  complex(psb_spk_), intent(inout)       :: y(:)
  integer(psb_ipk_), intent(out)                :: info
  character, optional, intent(in)     :: trans

  character :: trans_
  integer(psb_ipk_) :: i,j,k,m,n, nnz, ir, jc
  complex(psb_spk_) :: acc
  logical   :: tra, ctra
  integer(psb_ipk_) :: err_act
  integer(psb_ipk_) :: ierr(5)
  character(len=20)  :: name='c_coo_csmv_impl'
  logical, parameter :: debug=.false.

  info = psb_success_
  call psb_erractionsave(err_act)

  if (.not.a%is_asb()) then 
    info = psb_err_invalid_mat_state_
    call psb_errpush(info,name)
    goto 9999
  endif

  if (a%is_dev())   call a%sync()

  if (present(trans)) then
    trans_ = trans
  else
    trans_ = 'N'
  end if

  tra  = (psb_toupper(trans_) == 'T')
  ctra = (psb_toupper(trans_) == 'C')


  if (tra.or.ctra) then 
    m = a%get_ncols()
    n = a%get_nrows()
  else
    n = a%get_ncols()
    m = a%get_nrows()
  end if
  if (size(x,1) < n) then
    info = psb_err_input_asize_small_i_
    ierr(1) = 3; ierr(2) = n; 
    call psb_errpush(info,name,i_err=ierr)
    goto 9999
  end if
  if (size(y,1) < m) then
    info = psb_err_input_asize_small_i_
    ierr(1) = 5; ierr(2) = m; 
    call psb_errpush(info,name,i_err=ierr)
    goto 9999
  end if
  nnz = a%get_nzeros()

  if (alpha == czero) then
    if (beta == czero) then
      do i = 1, m
        y(i) = czero
      enddo
    else
      do  i = 1, m
        y(i) = beta*y(i)
      end do
    endif
    return
  else 
    if (a%is_unit()) then 
      if (beta == czero) then
        do i = 1, min(m,n)
          y(i) = alpha*x(i)
        enddo
        do i = min(m,n)+1, m
          y(i) = czero
        enddo
      else
        do  i = 1, min(m,n) 
          y(i) = beta*y(i) + alpha*x(i)
        end do
        do i = min(m,n)+1, m
          y(i) = beta*y(i)
        enddo
      endif
    else
      if (beta == czero) then
        do i = 1, m
          y(i) = czero
        enddo
      else
        do  i = 1, m
          y(i) = beta*y(i)
        end do
      endif

    endif

  end if

  if ((.not.tra).and.(.not.ctra)) then 
    i    = 1
    j    = i
    if (nnz > 0) then 
      ir   = a%ia(1) 
      acc  = czero
      do 
        if (i>nnz) then 
          y(ir) = y(ir) + alpha * acc
          exit
        endif
        if (a%ia(i) /= ir) then 
          y(ir) = y(ir) + alpha * acc
          ir    = a%ia(i) 
          acc   = czero
        endif
        acc     = acc + a%val(i) * x(a%ja(i))
        i       = i + 1               
      enddo
    end if

  else if (tra) then 

    if (alpha == cone) then
      i    = 1
      do i=1,nnz
        ir = a%ja(i)
        jc = a%ia(i)
        y(ir) = y(ir) +  a%val(i)*x(jc)
      enddo

    else if (alpha == -cone) then

      do i=1,nnz
        ir = a%ja(i)
        jc = a%ia(i)
        y(ir) = y(ir) - a%val(i)*x(jc)
      enddo

    else                    

      do i=1,nnz
        ir = a%ja(i)
        jc = a%ia(i)
        y(ir) = y(ir) + alpha*a%val(i)*x(jc)
      enddo

    end if                  !.....end testing on alpha

  else if (ctra) then 

    if (alpha == cone) then
      i    = 1
      do i=1,nnz
        ir = a%ja(i)
        jc = a%ia(i)
        y(ir) = y(ir) +  conjg(a%val(i))*x(jc)
      enddo

    else if (alpha == -cone) then

      do i=1,nnz
        ir = a%ja(i)
        jc = a%ia(i)
        y(ir) = y(ir) - conjg(a%val(i))*x(jc)
      enddo

    else                    

      do i=1,nnz
        ir = a%ja(i)
        jc = a%ia(i)
        y(ir) = y(ir) + alpha*conjg(a%val(i))*x(jc)
      enddo

    end if                  !.....end testing on alpha

  endif

  call psb_erractionrestore(err_act)
  return

9999 call psb_error_handler(err_act)

  return

end subroutine psb_c_coo_csmv


subroutine psb_c_coo_csmm(alpha,a,x,beta,y,info,trans) 
  use psb_const_mod
  use psb_error_mod
  use psb_string_mod
  use psb_c_base_mat_mod, psb_protect_name => psb_c_coo_csmm
  implicit none 
  class(psb_c_coo_sparse_mat), intent(in) :: a
  complex(psb_spk_), intent(in)          :: alpha, beta, x(:,:)
  complex(psb_spk_), intent(inout)       :: y(:,:)
  integer(psb_ipk_), intent(out)                :: info
  character, optional, intent(in)     :: trans

  character :: trans_
  integer(psb_ipk_) :: i,j,k,m,n, nnz, ir, jc, nc
  complex(psb_spk_), allocatable  :: acc(:)
  logical   :: tra, ctra
  integer(psb_ipk_) :: err_act
  integer(psb_ipk_) :: ierr(5)
  character(len=20)  :: name='c_coo_csmm_impl'
  logical, parameter :: debug=.false.

  info = psb_success_
  call psb_erractionsave(err_act)


  if (.not.a%is_asb()) then 
    info = psb_err_invalid_mat_state_
    call psb_errpush(info,name)
    goto 9999
  endif

  if (a%is_dev())   call a%sync()

  if (present(trans)) then
    trans_ = trans
  else
    trans_ = 'N'
  end if


  tra  = (psb_toupper(trans_) == 'T')
  ctra = (psb_toupper(trans_) == 'C')


  if (tra.or.ctra) then 
    m = a%get_ncols()
    n = a%get_nrows()
  else
    n = a%get_ncols()
    m = a%get_nrows()
  end if
  if (size(x,1) < n) then
    info = psb_err_input_asize_small_i_
    ierr(1) = 3; ierr(2) = n; 
    call psb_errpush(info,name,i_err=ierr)
    goto 9999
  end if
  if (size(y,1) < m) then
    info = psb_err_input_asize_small_i_
    ierr(1) = 5; ierr(2) = m; 
    call psb_errpush(info,name,i_err=ierr)
    goto 9999
  end if

  nnz = a%get_nzeros()

  nc = min(size(x,2), size(y,2))
  allocate(acc(nc),stat=info)
  if(info /= psb_success_) then
    info=psb_err_from_subroutine_
    call psb_errpush(info,name,a_err='allocate')
    goto 9999
  end if


  if (alpha == czero) then
    if (beta == czero) then
      do i = 1, m
        y(i,1:nc) = czero
      enddo
    else
      do  i = 1, m
        y(i,1:nc) = beta*y(i,1:nc)
      end do
    endif
    return
  else 
    if (a%is_unit()) then 
      if (beta == czero) then
        do i = 1, min(m,n)
          y(i,1:nc) = alpha*x(i,1:nc)
        enddo
        do i = min(m,n)+1, m
          y(i,1:nc) = czero
        enddo
      else
        do  i = 1, min(m,n) 
          y(i,1:nc) = beta*y(i,1:nc) + alpha*x(i,1:nc)
        end do
        do i = min(m,n)+1, m
          y(i,1:nc) = beta*y(i,1:nc)
        enddo
      endif
    else
      if (beta == czero) then
        do i = 1, m
          y(i,1:nc) = czero
        enddo
      else
        do  i = 1, m
          y(i,1:nc) = beta*y(i,1:nc)
        end do
      endif

    endif

  end if

  if (.not.tra) then 
    i    = 1
    j    = i
    if (nnz > 0) then 
      ir   = a%ia(1) 
      acc  = czero
      do 
        if (i>nnz) then 
          y(ir,1:nc) = y(ir,1:nc) + alpha * acc
          exit
        endif
        if (a%ia(i) /= ir) then 
          y(ir,1:nc) = y(ir,1:nc) + alpha * acc
          ir    = a%ia(i) 
          acc   = czero
        endif
        acc     = acc + a%val(i) * x(a%ja(i),1:nc)
        i       = i + 1               
      enddo
    end if

  else if (tra) then 

    if (alpha == cone) then
      i    = 1
      do i=1,nnz
        ir = a%ja(i)
        jc = a%ia(i)
        y(ir,1:nc) = y(ir,1:nc) +  a%val(i)*x(jc,1:nc)
      enddo

    else if (alpha == -cone) then

      do i=1,nnz
        ir = a%ja(i)
        jc = a%ia(i)
        y(ir,1:nc) = y(ir,1:nc) - a%val(i)*x(jc,1:nc)
      enddo

    else                    

      do i=1,nnz
        ir = a%ja(i)
        jc = a%ia(i)
        y(ir,1:nc) = y(ir,1:nc) + alpha*a%val(i)*x(jc,1:nc)
      enddo

    end if                  !.....end testing on alpha

  else if (ctra) then 

    if (alpha == cone) then
      i    = 1
      do i=1,nnz
        ir = a%ja(i)
        jc = a%ia(i)
        y(ir,1:nc) = y(ir,1:nc) +  conjg(a%val(i))*x(jc,1:nc)
      enddo

    else if (alpha == -cone) then

      do i=1,nnz
        ir = a%ja(i)
        jc = a%ia(i)
        y(ir,1:nc) = y(ir,1:nc) - conjg(a%val(i))*x(jc,1:nc)
      enddo

    else                    

      do i=1,nnz
        ir = a%ja(i)
        jc = a%ia(i)
        y(ir,1:nc) = y(ir,1:nc) + alpha*conjg(a%val(i))*x(jc,1:nc)
      enddo

    end if                  !.....end testing on alpha

  endif

  call psb_erractionrestore(err_act)
  return

9999 call psb_error_handler(err_act)

  return

end subroutine psb_c_coo_csmm

function psb_c_coo_maxval(a) result(res)
  use psb_error_mod
  use psb_c_base_mat_mod, psb_protect_name => psb_c_coo_maxval
  implicit none 
  class(psb_c_coo_sparse_mat), intent(in) :: a
  real(psb_spk_)         :: res

  integer(psb_ipk_) :: i,j,k,m,n, nnz, ir, jc, nc, info
  integer(psb_ipk_) :: ierr(5)
  character(len=20)  :: name='c_coo_maxval'
  logical, parameter :: debug=.false.

  if (a%is_dev())   call a%sync()

  if (a%is_unit()) then 
    res = sone
  else
    res = szero
  end if
  nnz = a%get_nzeros()
  if (allocated(a%val)) then 
    nnz = min(nnz,size(a%val))
    res = maxval(abs(a%val(1:nnz)))
  end if

end function psb_c_coo_maxval

function psb_c_coo_csnmi(a) result(res)
  use psb_error_mod
  use psb_c_base_mat_mod, psb_protect_name => psb_c_coo_csnmi
  implicit none 
  class(psb_c_coo_sparse_mat), intent(in) :: a
  real(psb_spk_)         :: res

  integer(psb_ipk_) :: i,j,k,m,n, nnz, ir, jc, nc, info
  real(psb_spk_) :: acc
  real(psb_spk_), allocatable :: vt(:)
  logical            :: tra, is_unit
  integer(psb_ipk_)  :: err_act
  integer(psb_ipk_)  :: ierr(5)
  character(len=20)  :: name='c_coo_csnmi'
  logical, parameter :: debug=.false.

  if (a%is_dev())   call a%sync()

  res = szero
  nnz = a%get_nzeros()
  is_unit = a%is_unit()
  if (a%is_by_rows()) then 
    i   = 1
    j   = i
    res = szero 
    do while (i<=nnz) 
      do while ((a%ia(j) == a%ia(i)).and. (j <= nnz))
        j = j+1
      enddo
      if (is_unit) then 
        acc = sone
      else
        acc = szero
      end if
      do k=i, j-1
        acc = acc + abs(a%val(k))
      end do
      res = max(res,acc)
      i = j
    end do
  else
    m = a%get_nrows()
    allocate(vt(m),stat=info)
    if (info /= 0) return
    if (is_unit) then 
      vt = sone
    else
      vt = szero
    end if
    do j=1, nnz
      i = a%ia(j)
      vt(i) = vt(i) + abs(a%val(j))
    end do
    res = maxval(vt(1:m))
    deallocate(vt,stat=info)
  end if
    
end function psb_c_coo_csnmi


function psb_c_coo_csnm1(a) result(res)
  use psb_error_mod
  use psb_const_mod
  use psb_c_base_mat_mod, psb_protect_name => psb_c_coo_csnm1

  implicit none 
  class(psb_c_coo_sparse_mat), intent(in) :: a
  real(psb_spk_)         :: res

  integer(psb_ipk_) :: i,j,k,m,n, nnz, ir, jc, nc, info
  real(psb_spk_) :: acc
  real(psb_spk_), allocatable :: vt(:)
  logical   :: tra
  integer(psb_ipk_) :: err_act
  integer(psb_ipk_) :: ierr(5)
  character(len=20)  :: name='c_coo_csnm1'
  logical, parameter :: debug=.false.

  if (a%is_dev())   call a%sync()

  res = szero
  nnz = a%get_nzeros()
  n   = a%get_ncols()
  allocate(vt(n),stat=info)
  if (info /= 0) return
  if (a%is_unit()) then 
    vt = sone
  else
    vt = szero
  end if
  do j=1, nnz
    i = a%ja(j)
    vt(i) = vt(i) + abs(a%val(j))
  end do
  res = maxval(vt(1:n))
  deallocate(vt,stat=info)

  return

end function psb_c_coo_csnm1

subroutine psb_c_coo_rowsum(d,a) 
  use psb_error_mod
  use psb_const_mod
  use psb_c_base_mat_mod, psb_protect_name => psb_c_coo_rowsum
  class(psb_c_coo_sparse_mat), intent(in) :: a
  complex(psb_spk_), intent(out)             :: d(:)

  integer(psb_ipk_) :: i,j,k,m,n, nnz, ir, jc, nc
  complex(psb_spk_) :: acc
  complex(psb_spk_), allocatable :: vt(:)
  logical   :: tra
  integer(psb_ipk_) :: err_act, info
  integer(psb_ipk_) :: ierr(5)
  character(len=20)  :: name='rowsum'
  logical, parameter :: debug=.false.

  call psb_erractionsave(err_act)
  if (a%is_dev())   call a%sync()

  m = a%get_nrows()
  if (size(d) < m) then 
    info=psb_err_input_asize_small_i_
    ierr(1) = 1; ierr(2) = size(d); ierr(3) = m
    call psb_errpush(info,name,i_err=ierr)
    goto 9999
  end if

  if (a%is_unit()) then 
    d = cone
  else
    d = czero
  end if
  nnz = a%get_nzeros()
  do j=1, nnz
    i    = a%ia(j)
    d(i) = d(i) + a%val(j)
  end do


  return
  call psb_erractionrestore(err_act)
  return  

9999 call psb_error_handler(err_act)

  return

end subroutine psb_c_coo_rowsum

subroutine psb_c_coo_arwsum(d,a) 
  use psb_error_mod
  use psb_const_mod
  use psb_c_base_mat_mod, psb_protect_name => psb_c_coo_arwsum
  class(psb_c_coo_sparse_mat), intent(in) :: a
  real(psb_spk_), intent(out)              :: d(:)

  integer(psb_ipk_) :: i,j,k,m,n, nnz, ir, jc, nc
  real(psb_spk_) :: acc
  real(psb_spk_), allocatable :: vt(:)
  logical   :: tra
  integer(psb_ipk_) :: err_act, info
  integer(psb_ipk_) :: ierr(5)
  character(len=20)  :: name='rowsum'
  logical, parameter :: debug=.false.

  call psb_erractionsave(err_act)
  if (a%is_dev())   call a%sync()

  m = a%get_nrows()
  if (size(d) < m) then 
    info=psb_err_input_asize_small_i_
    ierr(1) = 1; ierr(2) = size(d); ierr(3) = m
    call psb_errpush(info,name,i_err=ierr)
    goto 9999
  end if

  if (a%is_unit()) then 
    d = sone
  else
    d = szero
  end if
  nnz = a%get_nzeros()
  do j=1, nnz
    i    = a%ia(j)
    d(i) = d(i) + abs(a%val(j))
  end do

  return
  call psb_erractionrestore(err_act)
  return  

9999 call psb_error_handler(err_act)

  return

end subroutine psb_c_coo_arwsum

subroutine psb_c_coo_colsum(d,a) 
  use psb_error_mod
  use psb_const_mod
  use psb_c_base_mat_mod, psb_protect_name => psb_c_coo_colsum
  class(psb_c_coo_sparse_mat), intent(in) :: a
  complex(psb_spk_), intent(out)              :: d(:)

  integer(psb_ipk_) :: i,j,k,m,n, nnz, ir, jc, nc
  complex(psb_spk_) :: acc
  complex(psb_spk_), allocatable :: vt(:)
  logical   :: tra
  integer(psb_ipk_) :: err_act, info
  integer(psb_ipk_) :: ierr(5)
  character(len=20)  :: name='colsum'
  logical, parameter :: debug=.false.

  call psb_erractionsave(err_act)
  if (a%is_dev())   call a%sync()

  n = a%get_ncols()
  if (size(d) < n) then 
    info=psb_err_input_asize_small_i_
    ierr(1) = 1; ierr(2) = size(d);  ierr(3) = n
    call psb_errpush(info,name,i_err=ierr)
    goto 9999
  end if

  if (a%is_unit()) then 
    d = cone
  else
    d = czero
  end if

  nnz = a%get_nzeros()
  do j=1, nnz
    k    = a%ja(j)
    d(k) = d(k) + a%val(j)
  end do

  return
  call psb_erractionrestore(err_act)
  return  

9999 call psb_error_handler(err_act)

  return

end subroutine psb_c_coo_colsum

subroutine psb_c_coo_aclsum(d,a) 
  use psb_error_mod
  use psb_const_mod
  use psb_c_base_mat_mod, psb_protect_name => psb_c_coo_aclsum
  class(psb_c_coo_sparse_mat), intent(in) :: a
  real(psb_spk_), intent(out)              :: d(:)

  integer(psb_ipk_) :: i,j,k,m,n, nnz, ir, jc, nc
  real(psb_spk_) :: acc
  real(psb_spk_), allocatable :: vt(:)
  logical   :: tra
  integer(psb_ipk_) :: err_act, info
  integer(psb_ipk_) :: ierr(5)
  character(len=20)  :: name='aclsum'
  logical, parameter :: debug=.false.

  call psb_erractionsave(err_act)
  if (a%is_dev())   call a%sync()

  n = a%get_ncols()
  if (size(d) < n) then 
    info=psb_err_input_asize_small_i_
    ierr(1) = 1; ierr(2) = size(d); ierr(3) = n
    call psb_errpush(info,name,i_err=ierr)
    goto 9999
  end if

  if (a%is_unit()) then 
    d = sone
  else
    d = szero
  end if

  nnz = a%get_nzeros()
  do j=1, nnz
    k    = a%ja(j)
    d(k) = d(k) + abs(a%val(j))
  end do
  
  return
  call psb_erractionrestore(err_act)
  return  

9999 call psb_error_handler(err_act)

  return

end subroutine psb_c_coo_aclsum



! == ==================================
!
!
!
! Data management
!
!
!
!
!
! == ==================================



subroutine psb_c_coo_csgetptn(imin,imax,a,nz,ia,ja,info,&
     & jmin,jmax,iren,append,nzin,rscale,cscale)
  ! Output is always in  COO format 
  use psb_error_mod
  use psb_const_mod
  use psb_error_mod
  use psb_c_base_mat_mod, psb_protect_name => psb_c_coo_csgetptn
  implicit none

  class(psb_c_coo_sparse_mat), intent(in)       :: a
  integer(psb_ipk_), intent(in)                 :: imin,imax
  integer(psb_ipk_), intent(out)                :: nz
  integer(psb_ipk_), allocatable, intent(inout) :: ia(:), ja(:)
  integer(psb_ipk_),intent(out)                 :: info
  logical, intent(in), optional                 :: append
  integer(psb_ipk_), intent(in), optional       :: iren(:)
  integer(psb_ipk_), intent(in), optional       :: jmin,jmax, nzin
  logical, intent(in), optional                 :: rscale,cscale

  logical :: append_, rscale_, cscale_ 
  integer(psb_ipk_) :: nzin_, jmin_, jmax_, err_act, i
  integer(psb_ipk_) :: ierr(5)
  character(len=20)  :: name='csget'
  logical, parameter :: debug=.false.

  call psb_erractionsave(err_act)
  if (a%is_dev())   call a%sync()
  info = psb_success_
  nz = 0

  if (present(jmin)) then
    jmin_ = jmin
  else
    jmin_ = 1
  endif
  if (present(jmax)) then
    jmax_ = jmax
  else
    jmax_ = a%get_ncols()
  endif

  if ((imax<imin).or.(jmax_<jmin_)) return

  if (present(append)) then
    append_=append
  else
    append_=.false.
  endif
  if ((append_).and.(present(nzin))) then 
    nzin_ = nzin
  else
    nzin_ = 0
  endif
  if (present(rscale)) then 
    rscale_ = rscale
  else
    rscale_ = .false.
  endif
  if (present(cscale)) then 
    cscale_ = cscale
  else
    cscale_ = .false.
  endif
  if ((rscale_.or.cscale_).and.(present(iren))) then 
    info = psb_err_many_optional_arg_
    call psb_errpush(info,name,a_err='iren (rscale.or.cscale)')
    goto 9999
  end if

  call coo_getptn(imin,imax,jmin_,jmax_,a,nz,ia,ja,nzin_,append_,info,&
       & iren)

  if (rscale_) then 
    do i=nzin_+1, nzin_+nz
      ia(i) = ia(i) - imin + 1
    end do
  end if
  if (cscale_) then 
    do i=nzin_+1, nzin_+nz
      ja(i) = ja(i) - jmin_ + 1
    end do
  end if

  if (info /= psb_success_) goto 9999

  call psb_erractionrestore(err_act)
  return

9999 call psb_error_handler(err_act)

  return

contains

  subroutine coo_getptn(imin,imax,jmin,jmax,a,nz,ia,ja,nzin,append,info,&
       & iren)

    use psb_const_mod
    use psb_error_mod
    use psb_realloc_mod
    use psb_sort_mod
    implicit none

    class(psb_c_coo_sparse_mat), intent(in)    :: a
    integer(psb_ipk_) :: imin,imax,jmin,jmax
    integer(psb_ipk_), intent(inout)               :: nz
    integer(psb_ipk_), allocatable, intent(inout)  :: ia(:), ja(:)
    integer(psb_ipk_), intent(in)                  :: nzin
    logical, intent(in)                  :: append
    integer(psb_ipk_) :: info
    integer(psb_ipk_), optional                    :: iren(:)
    integer(psb_ipk_) :: nzin_, nza, idx,ip,jp,i,k, nzt, irw, lrw,nrd
    integer(psb_ipk_) :: debug_level, debug_unit
    character(len=20) :: name='coo_getptn'

    debug_unit  = psb_get_debug_unit()
    debug_level = psb_get_debug_level()

    nza = a%get_nzeros()
    irw = imin
    lrw = imax
    if (irw<0) then 
      info = psb_err_pivot_too_small_
      return
    end if

    if (append) then 
      nzin_ = nzin
    else
      nzin_ = 0
    endif

    if (a%is_by_rows()) then 
      ! In this case we can do a binary search. 
      if (debug_level >= psb_debug_serial_)&
           & write(debug_unit,*) trim(name), ': srtdcoo '
      do
        ip = psb_ibsrch(irw,nza,a%ia)
        if (ip /= -1) exit
        irw = irw + 1
        if (irw > imax) then
          write(debug_unit,*)  trim(name),&
               & 'Warning : did not find any rows. Is this an error? ',&
               & irw,lrw,imin
          exit
        end if
      end do

      if (ip /= -1) then 
        ! expand [ip,jp] to contain all row entries.
        do 
          if (ip < 2) exit
          if (a%ia(ip-1) == irw) then  
            ip = ip -1 
          else 
            exit
          end if
        end do

      end if

      do
        jp = psb_ibsrch(lrw,nza,a%ia)
        if (jp /= -1) exit
        lrw = lrw - 1
        if (irw > lrw) then
          write(debug_unit,*) trim(name),&
               & 'Warning : did not find any rows. Is this an error?'
          exit
        end if
      end do

      if (jp /= -1) then 
        ! expand [ip,jp] to contain all row entries.
        do 
          if (jp == nza) exit
          if (a%ia(jp+1) == lrw) then  
            jp = jp + 1
          else 
            exit
          end if
        end do
      end if
      if (debug_level >= psb_debug_serial_) &
           & write(debug_unit,*)  trim(name),': ip jp',ip,jp,nza
      if ((ip /= -1) .and.(jp /= -1)) then 
        ! Now do the copy.
        nzt = jp - ip +1 
        nz = 0 

        call psb_ensure_size(nzin_+nzt,ia,info)
        if (info == psb_success_) call psb_ensure_size(nzin_+nzt,ja,info)
        if (info /= psb_success_) return

        if (present(iren)) then 
          do i=ip,jp
            if ((jmin <= a%ja(i)).and.(a%ja(i)<=jmax)) then 
              nzin_ = nzin_ + 1
              nz    = nz + 1
              ia(nzin_)  = iren(a%ia(i))
              ja(nzin_)  = iren(a%ja(i))
            end if
          enddo
        else
          do i=ip,jp
            if ((jmin <= a%ja(i)).and.(a%ja(i)<=jmax)) then 
              nzin_ = nzin_ + 1
              nz    = nz + 1
              ia(nzin_)  = a%ia(i)
              ja(nzin_)  = a%ja(i)
            end if
          enddo
        end if
      else 
        nz = 0 
      end if

    else
      if (debug_level >= psb_debug_serial_) &
           & write(debug_unit,*)  trim(name),': unsorted '

      nrd = max(a%get_nrows(),1)
      nzt = ((nza+nrd-1)/nrd)*(lrw-irw+1)
      call psb_ensure_size(nzin_+nzt,ia,info)
      if (info == psb_success_) call psb_ensure_size(nzin_+nzt,ja,info)
      if (info /= psb_success_) return

      if (present(iren)) then 
        k = 0 
        do i=1, a%get_nzeros()
          if ((a%ia(i)>=irw).and.(a%ia(i)<=lrw).and.&
               & (jmin <= a%ja(i)).and.(a%ja(i)<=jmax)) then 
            k = k + 1 
            if (k > nzt) then
              nzt = k + nzt
              call psb_ensure_size(nzin_+nzt,ia,info)
              if (info == psb_success_) call psb_ensure_size(nzin_+nzt,ja,info)
              if (info /= psb_success_) return
            end if
            ia(nzin_+k)  = iren(a%ia(i))
            ja(nzin_+k)  = iren(a%ja(i))
          endif
        enddo
      else
        k = 0 
        do i=1,a%get_nzeros()
          if ((a%ia(i)>=irw).and.(a%ia(i)<=lrw).and.&
               & (jmin <= a%ja(i)).and.(a%ja(i)<=jmax)) then 
            k = k + 1 
            if (k > nzt) then
              nzt = k + nzt
              call psb_ensure_size(nzin_+nzt,ia,info)
              if (info == psb_success_) call psb_ensure_size(nzin_+nzt,ja,info)
              if (info /= psb_success_) return

            end if
            ia(nzin_+k)  = (a%ia(i))
            ja(nzin_+k)  = (a%ja(i))
          endif
        enddo
        nzin_=nzin_+k
      end if
      nz = k 
    end if

  end subroutine coo_getptn

end subroutine psb_c_coo_csgetptn


!
! NZ is the number of non-zeros on output. 
! The output is guaranteed to be sorted
! 
subroutine psb_c_coo_csgetrow(imin,imax,a,nz,ia,ja,val,info,&
     & jmin,jmax,iren,append,nzin,rscale,cscale)
  ! Output is always in  COO format 
  use psb_error_mod
  use psb_const_mod
  use psb_error_mod
  use psb_c_base_mat_mod, psb_protect_name => psb_c_coo_csgetrow
  implicit none

  class(psb_c_coo_sparse_mat), intent(in) :: a
  integer(psb_ipk_), intent(in)                  :: imin,imax
  integer(psb_ipk_), intent(out)                 :: nz
  integer(psb_ipk_), allocatable, intent(inout)  :: ia(:), ja(:)
  complex(psb_spk_), allocatable,  intent(inout)    :: val(:)
  integer(psb_ipk_),intent(out)                  :: info
  logical, intent(in), optional        :: append
  integer(psb_ipk_), intent(in), optional        :: iren(:)
  integer(psb_ipk_), intent(in), optional        :: jmin,jmax, nzin
  logical, intent(in), optional        :: rscale,cscale

  logical :: append_, rscale_, cscale_ 
  integer(psb_ipk_) :: nzin_, jmin_, jmax_, err_act, i
  integer(psb_ipk_) :: ierr(5)
  character(len=20)  :: name='csget'
  logical, parameter :: debug=.false.

  call psb_erractionsave(err_act)
  if (a%is_dev())   call a%sync()
  info = psb_success_
  nz = 0
  if (present(jmin)) then
    jmin_ = jmin
  else
    jmin_ = 1
  endif
  if (present(jmax)) then
    jmax_ = jmax
  else
    jmax_ = a%get_ncols()
  endif

  if ((imax<imin).or.(jmax_<jmin_))  return

  if (present(append)) then
    append_=append
  else
    append_=.false.
  endif
  if ((append_).and.(present(nzin))) then 
    nzin_ = nzin
  else
    nzin_ = 0
  endif
  if (present(rscale)) then 
    rscale_ = rscale
  else
    rscale_ = .false.
  endif
  if (present(cscale)) then 
    cscale_ = cscale
  else
    cscale_ = .false.
  endif
  if ((rscale_.or.cscale_).and.(present(iren))) then 
    info = psb_err_many_optional_arg_
    call psb_errpush(info,name,a_err='iren (rscale.or.cscale)')
    goto 9999
  end if

  call coo_getrow(imin,imax,jmin_,jmax_,a,nz,ia,ja,val,nzin_,append_,info,&
       & iren)

  if (rscale_) then 
    do i=nzin_+1, nzin_+nz
      ia(i) = ia(i) - imin + 1
    end do
  end if
  if (cscale_) then 
    do i=nzin_+1, nzin_+nz
      ja(i) = ja(i) - jmin_ + 1
    end do
  end if

  if (info /= psb_success_) goto 9999

  call psb_erractionrestore(err_act)
  return

9999 call psb_error_handler(err_act)

  return

contains

  subroutine coo_getrow(imin,imax,jmin,jmax,a,nz,ia,ja,val,nzin,append,info,&
       & iren)

    use psb_const_mod
    use psb_error_mod
    use psb_realloc_mod
    use psb_sort_mod
    use psb_ip_reord_mod
    implicit none

    class(psb_c_coo_sparse_mat), intent(in)    :: a
    integer(psb_ipk_) :: imin,imax,jmin,jmax
    integer(psb_ipk_), intent(inout)               :: nz
    integer(psb_ipk_), allocatable, intent(inout)  :: ia(:), ja(:)
    complex(psb_spk_), allocatable,  intent(inout)    :: val(:)
    integer(psb_ipk_), intent(in)                  :: nzin
    logical, intent(in)                            :: append
    integer(psb_ipk_) :: info
    integer(psb_ipk_), optional                    :: iren(:)
    integer(psb_ipk_) :: nzin_, nza, idx,ip,jp,i,k, nzt, irw, lrw, nra, nca, nrd
    integer(psb_ipk_) :: debug_level, debug_unit
    character(len=20) :: name='coo_getrow'

    debug_unit  = psb_get_debug_unit()
    debug_level = psb_get_debug_level()

    nra = a%get_nrows()
    nca = a%get_ncols()
    nza = a%get_nzeros()
    irw = imin
    lrw = imax
    if (irw<0) then 
      info = psb_err_pivot_too_small_
      return
    end if

    if (append) then 
      nzin_ = nzin
    else
      nzin_ = 0
    endif

    if (a%is_by_rows()) then 
      ! In this case we can do a binary search. 
      if (debug_level >= psb_debug_serial_)&
           & write(debug_unit,*) trim(name), ': srtdcoo '
      do
        ip = psb_ibsrch(irw,nza,a%ia)
        if (ip /= -1) exit
        irw = irw + 1
        if (irw > imax) then
          write(debug_unit,*)  trim(name),&
               & 'Warning : did not find any rows. Is this an error? ',&
               & irw,lrw,imin
          exit
        end if
      end do

      if (ip /= -1) then 
        ! expand [ip,jp] to contain all row entries.
        do 
          if (ip < 2) exit
          if (a%ia(ip-1) == irw) then  
            ip = ip -1 
          else 
            exit
          end if
        end do

      end if

      do
        jp = psb_ibsrch(lrw,nza,a%ia)
        if (jp /= -1) exit
        lrw = lrw - 1
        if (irw > lrw) then
          write(debug_unit,*) trim(name),&
               & 'Warning : did not find any rows. Is this an error?'
          exit
        end if
      end do

      if (jp /= -1) then 
        ! expand [ip,jp] to contain all row entries.
        do 
          if (jp == nza) exit
          if (a%ia(jp+1) == lrw) then  
            jp = jp + 1
          else 
            exit
          end if
        end do
      end if
      if (debug_level >= psb_debug_serial_) &
           & write(debug_unit,*)  trim(name),': ip jp',ip,jp,nza
      if ((ip /= -1) .and.(jp /= -1)) then 
        ! Now do the copy.
        nzt = jp - ip +1 
        nz = 0 

        call psb_ensure_size(nzin_+nzt,ia,info)
        if (info == psb_success_) call psb_ensure_size(nzin_+nzt,ja,info)
        if (info == psb_success_) call psb_ensure_size(nzin_+nzt,val,info)
        if (info /= psb_success_) return

        if (present(iren)) then 
          do i=ip,jp
            if ((jmin <= a%ja(i)).and.(a%ja(i)<=jmax)) then 
              nz    = nz + 1
              val(nzin_+nz) = a%val(i)
              ia(nzin_+nz)  = iren(a%ia(i))
              ja(nzin_+nz)  = iren(a%ja(i))
            end if
          enddo
          call psb_c_fix_coo_inner(nra,nca,nzin_+nz,psb_dupl_add_,ia,ja,val,nz,info)
          nz = nz - nzin_        
        else
          do i=ip,jp
            if ((jmin <= a%ja(i)).and.(a%ja(i)<=jmax)) then 
              nz    = nz + 1
              val(nzin_+nz) = a%val(i)
              ia(nzin_+nz)  = a%ia(i)
              ja(nzin_+nz)  = a%ja(i)
            end if
          enddo
        end if
      else
        nz = 0 
      end if

    else
      if (debug_level >= psb_debug_serial_) &
           & write(debug_unit,*)  trim(name),': unsorted '

      nrd = max(a%get_nrows(),1)
      nzt = ((nza+nrd-1)/nrd)*(lrw-irw+1)
      call psb_ensure_size(nzin_+nzt,ia,info)
      if (info == psb_success_) call psb_ensure_size(nzin_+nzt,ja,info)
      if (info == psb_success_) call psb_ensure_size(nzin_+nzt,val,info)
      if (info /= psb_success_) return

      if (present(iren)) then 
        k = 0 
        do i=1, a%get_nzeros()
          if ((a%ia(i)>=irw).and.(a%ia(i)<=lrw).and.&
               & (jmin <= a%ja(i)).and.(a%ja(i)<=jmax)) then 
            k = k + 1 
            if (k > nzt) then
              nzt = k + nzt
              call psb_ensure_size(nzin_+nzt,ia,info)
              if (info == psb_success_) call psb_ensure_size(nzin_+nzt,ja,info)
              if (info == psb_success_) call psb_ensure_size(nzin_+nzt,val,info)
              if (info /= psb_success_) return
            end if
            val(nzin_+k) = a%val(i)
            ia(nzin_+k)  = iren(a%ia(i))
            ja(nzin_+k)  = iren(a%ja(i))
          endif
        enddo
      else
        k = 0 
        do i=1,a%get_nzeros()
          if ((a%ia(i)>=irw).and.(a%ia(i)<=lrw).and.&
               & (jmin <= a%ja(i)).and.(a%ja(i)<=jmax)) then 
            k = k + 1 
            if (k > nzt) then
              nzt = k + nzt
              call psb_ensure_size(nzin_+nzt,ia,info)
              if (info == psb_success_) call psb_ensure_size(nzin_+nzt,ja,info)
              if (info == psb_success_) call psb_ensure_size(nzin_+nzt,val,info)
              if (info /= psb_success_) return

            end if
            val(nzin_+k) = a%val(i)
            ia(nzin_+k)  = (a%ia(i))
            ja(nzin_+k)  = (a%ja(i))
          endif
        enddo
      end if
      call psb_c_fix_coo_inner(nra,nca,nzin_+k,psb_dupl_add_,ia,ja,val,nz,info)
      nz = nz - nzin_
    end if

  end subroutine coo_getrow

end subroutine psb_c_coo_csgetrow


subroutine psb_c_coo_csput_a(nz,ia,ja,val,a,imin,imax,jmin,jmax,info,gtl) 
  use psb_error_mod
  use psb_realloc_mod
  use psb_sort_mod
  use psb_c_base_mat_mod, psb_protect_name => psb_c_coo_csput_a
  implicit none 

  class(psb_c_coo_sparse_mat), intent(inout) :: a
  complex(psb_spk_), intent(in)      :: val(:)
  integer(psb_ipk_), intent(in)             :: nz, ia(:), ja(:), imin,imax,jmin,jmax
  integer(psb_ipk_), intent(out)            :: info
  integer(psb_ipk_), intent(in), optional   :: gtl(:)


  integer(psb_ipk_) :: err_act
  integer(psb_ipk_) :: ierr(5)
  character(len=20)  :: name='c_coo_csput_a_impl'
  logical, parameter :: debug=.false.
  integer(psb_ipk_) :: nza, i,j,k, nzl, isza, debug_level, debug_unit

  info = psb_success_
  debug_unit  = psb_get_debug_unit()
  debug_level = psb_get_debug_level()
  call psb_erractionsave(err_act)
  if (a%is_dev())   call a%sync()

  if (nz < 0) then 
    info = psb_err_iarg_neg_
    ierr(1)=1
    call psb_errpush(info,name,i_err=ierr)
    goto 9999
  end if
  if (size(ia) < nz) then 
    info = psb_err_input_asize_invalid_i_
    ierr(1)=2
    call psb_errpush(info,name,i_err=ierr)
    goto 9999
  end if

  if (size(ja) < nz) then 
    info = psb_err_input_asize_invalid_i_
    ierr(1)=3
    call psb_errpush(info,name,i_err=ierr)
    goto 9999
  end if
  if (size(val) < nz) then 
    info = psb_err_input_asize_invalid_i_
    ierr(1)=4
    call psb_errpush(info,name,i_err=ierr)
    goto 9999
  end if

  if (nz == 0) return


  nza  = a%get_nzeros()
  isza = a%get_size()
  if (a%is_bld()) then 
    ! Build phase. Must handle reallocations in a sensible way.
    if (isza < (nza+nz)) then 
      call a%reallocate(max(nza+nz,int(1.5*isza)))
    endif
    isza = a%get_size()
    if (isza < (nza+nz)) then 
      info = psb_err_alloc_dealloc_; call psb_errpush(info,name)
      goto 9999
    end if

    call psb_inner_ins(nz,ia,ja,val,nza,a%ia,a%ja,a%val,isza,&
         & imin,imax,jmin,jmax,info,gtl)
    call a%set_nzeros(nza)
    call a%set_sorted(.false.)


  else  if (a%is_upd()) then 

    if (a%is_dev())   call a%sync()

    call  c_coo_srch_upd(nz,ia,ja,val,a,&
         & imin,imax,jmin,jmax,info,gtl)

    if (info < 0) then 
      info = psb_err_internal_error_
    else if (info > 0) then 
      if (debug_level >= psb_debug_serial_) &
           & write(debug_unit,*) trim(name),&
           & ': Discarded entries not  belonging to us.'                    
      info = psb_success_
    end if
  else 
    ! State is wrong.
    info = psb_err_invalid_mat_state_
  end if
  if (info /= psb_success_) then
    call psb_errpush(info,name)
    goto 9999
  end if
  call a%set_host()

  call psb_erractionrestore(err_act)
  return

9999 call psb_error_handler(err_act)

  return

contains

  subroutine psb_inner_ins(nz,ia,ja,val,nza,ia1,ia2,aspk,maxsz,&
       & imin,imax,jmin,jmax,info,gtl)
    implicit none 

    integer(psb_ipk_), intent(in) :: nz, imin,imax,jmin,jmax,maxsz
    integer(psb_ipk_), intent(in) :: ia(:),ja(:)
    integer(psb_ipk_), intent(inout) :: nza,ia1(:),ia2(:)
    complex(psb_spk_), intent(in) :: val(:)
    complex(psb_spk_), intent(inout) :: aspk(:)
    integer(psb_ipk_), intent(out) :: info
    integer(psb_ipk_), intent(in), optional  :: gtl(:)
    integer(psb_ipk_) :: i,ir,ic,ng

    info = psb_success_
    if (present(gtl)) then 
      ng = size(gtl) 

      do i=1, nz 
        ir = ia(i)
        ic = ja(i) 
        if ((ir >=1).and.(ir<=ng).and.(ic>=1).and.(ic<=ng)) then 
          ir = gtl(ir)
          ic = gtl(ic) 
          if ((ir >=imin).and.(ir<=imax).and.(ic>=jmin).and.(ic<=jmax)) then 
            nza = nza + 1 
            ia1(nza) = ir
            ia2(nza) = ic
            aspk(nza) = val(i)
          end if
        end if
      end do
    else

      do i=1, nz 
        ir = ia(i)
        ic = ja(i) 
        if ((ir >=imin).and.(ir<=imax).and.(ic>=jmin).and.(ic<=jmax)) then 
          nza = nza + 1 
          ia1(nza) = ir
          ia2(nza) = ic
          aspk(nza) = val(i)
        end if
      end do
    end if

  end subroutine psb_inner_ins


  subroutine c_coo_srch_upd(nz,ia,ja,val,a,&
       & imin,imax,jmin,jmax,info,gtl)

    use psb_const_mod
    use psb_realloc_mod
    use psb_string_mod
    implicit none 

    class(psb_c_coo_sparse_mat), intent(inout) :: a
    integer(psb_ipk_), intent(in) :: nz, imin,imax,jmin,jmax
    integer(psb_ipk_), intent(in) :: ia(:),ja(:)
    complex(psb_spk_), intent(in) :: val(:)
    integer(psb_ipk_), intent(out) :: info
    integer(psb_ipk_), intent(in), optional  :: gtl(:)
    integer(psb_ipk_) :: i,ir,ic, ilr, ilc, ip, &
         & i1,i2,nc,nnz,dupl,ng, nr
    integer(psb_ipk_) :: debug_level, debug_unit
    character(len=20)    :: name='c_coo_srch_upd'

    info = psb_success_
    debug_unit  = psb_get_debug_unit()
    debug_level = psb_get_debug_level()

    dupl = a%get_dupl()

    if (.not.a%is_sorted()) then 
      info = -4
      return
    end if

    ilr = -1 
    ilc = -1 
    nnz = a%get_nzeros()
    nr = a%get_nrows()
    nc = a%get_ncols()


    if (present(gtl)) then
      ng = size(gtl)

      select case(dupl)
      case(psb_dupl_ovwrt_,psb_dupl_err_)
        ! Overwrite.
        ! Cannot test for error, should have been caught earlier.
        do i=1, nz
          ir = ia(i)
          ic = ja(i) 
          if ((ir >=1).and.(ir<=ng).and.(ic>=1).and.(ic<=ng)) then 
            ir = gtl(ir)
            if ((ir > 0).and.(ir <= nr)) then 
              ic = gtl(ic) 
              if (ir /= ilr) then 
                i1 = psb_ibsrch(ir,nnz,a%ia)
                i2 = i1
                do 
                  if (i2+1 > nnz) exit
                  if (a%ia(i2+1) /= a%ia(i2)) exit
                  i2 = i2 + 1
                end do
                do 
                  if (i1-1 < 1) exit
                  if (a%ia(i1-1) /= a%ia(i1)) exit
                  i1 = i1 - 1
                end do
                ilr = ir
              else
                i1 = 1
                i2 = 1
              end if
              nc = i2-i1+1
              ip = psb_issrch(ic,nc,a%ja(i1:i2))
              if (ip>0) then 
                a%val(i1+ip-1) = val(i)
              else
                info = max(info,3)
              end if
            else
              info = max(info,2)
            endif
          else
            info = max(info,1)
          end if
        end do
      case(psb_dupl_add_)
        ! Add
        do i=1, nz
          ir = ia(i)
          ic = ja(i) 
          if ((ir >=1).and.(ir<=ng).and.(ic>=1).and.(ic<=ng)) then 
            ir = gtl(ir)
            ic = gtl(ic) 
            if ((ir > 0).and.(ir <= nr)) then 

              if (ir /= ilr) then 
                i1 = psb_ibsrch(ir,nnz,a%ia)
                i2 = i1
                do 
                  if (i2+1 > nnz) exit
                  if (a%ia(i2+1) /= a%ia(i2)) exit
                  i2 = i2 + 1
                end do
                do 
                  if (i1-1 < 1) exit
                  if (a%ia(i1-1) /= a%ia(i1)) exit
                  i1 = i1 - 1
                end do
                ilr = ir
              else
                i1 = 1
                i2 = 1
              end if
              nc = i2-i1+1
              ip = psb_issrch(ic,nc,a%ja(i1:i2))
              if (ip>0) then 
                a%val(i1+ip-1) = a%val(i1+ip-1) + val(i)
              else
                info = max(info,3)
              end if
            else
              info = max(info,2)
            end if
          else
            info = max(info,1)
          end if
        end do

      case default
        info = -3
        if (debug_level >= psb_debug_serial_) &
             & write(debug_unit,*) trim(name),&
             & ': Duplicate handling: ',dupl
      end select

    else

      select case(dupl)
      case(psb_dupl_ovwrt_,psb_dupl_err_)
        ! Overwrite.
        ! Cannot test for error, should have been caught earlier.
        do i=1, nz
          ir = ia(i)
          ic = ja(i) 
          if ((ir > 0).and.(ir <= nr)) then 

            if (ir /= ilr) then 
              i1 = psb_ibsrch(ir,nnz,a%ia)
              i2 = i1
              do 
                if (i2+1 > nnz) exit
                if (a%ia(i2+1) /= a%ia(i2)) exit
                i2 = i2 + 1
              end do
              do 
                if (i1-1 < 1) exit
                if (a%ia(i1-1) /= a%ia(i1)) exit
                i1 = i1 - 1
              end do
              ilr = ir
            else
              i1 = 1
              i2 = 1
            end if
            nc = i2-i1+1
            ip = psb_issrch(ic,nc,a%ja(i1:i2))
            if (ip>0) then 
              a%val(i1+ip-1) = val(i)
            else
              info = max(info,3)
            end if
          else
            info = max(info,2)
          end if
        end do

      case(psb_dupl_add_)
        ! Add
        do i=1, nz
          ir = ia(i)
          ic = ja(i) 
          if ((ir > 0).and.(ir <= nr)) then 

            if (ir /= ilr) then 
              i1 = psb_ibsrch(ir,nnz,a%ia)
              i2 = i1
              do 
                if (i2+1 > nnz) exit
                if (a%ia(i2+1) /= a%ia(i2)) exit
                i2 = i2 + 1
              end do
              do 
                if (i1-1 < 1) exit
                if (a%ia(i1-1) /= a%ia(i1)) exit
                i1 = i1 - 1
              end do
              ilr = ir
            else
              i1 = 1
              i2 = 1
            end if
            nc = i2-i1+1
            ip = psb_issrch(ic,nc,a%ja(i1:i2))
            if (ip>0) then 
              a%val(i1+ip-1) = a%val(i1+ip-1) + val(i)
            else
              info = max(info,3)
            end if
          else
            info = max(info,2)
          end if
        end do

      case default
        info = -3
        if (debug_level >= psb_debug_serial_) &
             & write(debug_unit,*) trim(name),&
             & ': Duplicate handling: ',dupl
      end select

    end if

  end subroutine c_coo_srch_upd

end subroutine psb_c_coo_csput_a


subroutine psb_c_cp_coo_to_coo(a,b,info) 
  use psb_error_mod
  use psb_c_base_mat_mod, psb_protect_name => psb_c_cp_coo_to_coo
  implicit none 
  class(psb_c_coo_sparse_mat), intent(in) :: a
  class(psb_c_coo_sparse_mat), intent(inout) :: b
  integer(psb_ipk_), intent(out)            :: info

  integer(psb_ipk_) :: err_act, nz
  integer(psb_ipk_) :: ierr(5)
  character(len=20)  :: name='to_coo'
  logical, parameter :: debug=.false.


  call psb_erractionsave(err_act)
  info = psb_success_
  if (a%is_dev())   call a%sync()

  b%psb_c_base_sparse_mat = a%psb_c_base_sparse_mat
  call b%set_sort_status(a%get_sort_status())
  nz = a%get_nzeros()
  call b%set_nzeros(nz)
  call b%reallocate(nz)

  b%ia(1:nz)  = a%ia(1:nz)
  b%ja(1:nz)  = a%ja(1:nz)
  b%val(1:nz) = a%val(1:nz)

  call b%set_host()

  if (.not.b%is_by_rows()) call b%fix(info)

  if (info /= psb_success_) goto 9999

  call psb_erractionrestore(err_act)
  return

9999 call psb_error_handler(err_act)

  return

end subroutine psb_c_cp_coo_to_coo

subroutine psb_c_cp_coo_from_coo(a,b,info) 
  use psb_error_mod
  use psb_c_base_mat_mod, psb_protect_name => psb_c_cp_coo_from_coo
  implicit none 
  class(psb_c_coo_sparse_mat), intent(inout) :: a
  class(psb_c_coo_sparse_mat), intent(in)    :: b
  integer(psb_ipk_), intent(out)            :: info

  integer(psb_ipk_) :: err_act
  integer(psb_ipk_) :: ierr(5)
  character(len=20)  :: name='from_coo'
  logical, parameter :: debug=.false.
  integer(psb_ipk_) :: m,n,nz


  call psb_erractionsave(err_act)
  info = psb_success_
  if (b%is_dev())   call b%sync()
  a%psb_c_base_sparse_mat = b%psb_c_base_sparse_mat
  call a%set_sort_status(b%get_sort_status())
  nz = b%get_nzeros()
  call a%set_nzeros(nz)
  call a%reallocate(nz)

  a%ia(1:nz)  = b%ia(1:nz)
  a%ja(1:nz)  = b%ja(1:nz)
  a%val(1:nz) = b%val(1:nz)

  call a%set_host()

  if (.not.a%is_by_rows()) call a%fix(info)

  if (info /= psb_success_) goto 9999

  call psb_erractionrestore(err_act)
  return

9999 continue
  call psb_errpush(info,name)

  call psb_error_handler(err_act)

  return

end subroutine psb_c_cp_coo_from_coo


subroutine psb_c_cp_coo_to_fmt(a,b,info) 
  use psb_error_mod
  use psb_c_base_mat_mod, psb_protect_name => psb_c_cp_coo_to_fmt
  implicit none 
  class(psb_c_coo_sparse_mat), intent(in) :: a
  class(psb_c_base_sparse_mat), intent(inout) :: b
  integer(psb_ipk_), intent(out)            :: info

  integer(psb_ipk_) :: err_act
  integer(psb_ipk_) :: ierr(5)
  character(len=20)  :: name='to_coo'
  logical, parameter :: debug=.false.


  call psb_erractionsave(err_act)
  info = psb_success_

  call b%cp_from_coo(a,info)

  if (info /= psb_success_) goto 9999

  call psb_erractionrestore(err_act)
  return

9999 continue
  call psb_errpush(info,name)

  call psb_error_handler(err_act)

  return

end subroutine psb_c_cp_coo_to_fmt

subroutine psb_c_cp_coo_from_fmt(a,b,info) 
  use psb_error_mod
  use psb_c_base_mat_mod, psb_protect_name => psb_c_cp_coo_from_fmt
  implicit none 
  class(psb_c_coo_sparse_mat), intent(inout) :: a
  class(psb_c_base_sparse_mat), intent(in) :: b
  integer(psb_ipk_), intent(out)            :: info

  integer(psb_ipk_) :: err_act
  integer(psb_ipk_) :: ierr(5)
  character(len=20)  :: name='from_coo'
  logical, parameter :: debug=.false.
  integer(psb_ipk_) :: m,n,nz


  call psb_erractionsave(err_act)
  info = psb_success_

  call b%cp_to_coo(a,info)

  if (info /= psb_success_) goto 9999

  call psb_erractionrestore(err_act)
  return

9999 continue
  call psb_errpush(info,name)

  call psb_error_handler(err_act)

  return

end subroutine psb_c_cp_coo_from_fmt


subroutine psb_c_mv_coo_to_coo(a,b,info) 
  use psb_error_mod
  use psb_c_base_mat_mod, psb_protect_name => psb_c_mv_coo_to_coo
  implicit none 
  class(psb_c_coo_sparse_mat), intent(inout) :: a
  class(psb_c_coo_sparse_mat), intent(inout) :: b
  integer(psb_ipk_), intent(out)            :: info

  integer(psb_ipk_) :: err_act
  integer(psb_ipk_) :: ierr(5)
  character(len=20)  :: name='to_coo'
  logical, parameter :: debug=.false.


  call psb_erractionsave(err_act)
  info = psb_success_
  if (a%is_dev())   call a%sync()
  b%psb_c_base_sparse_mat = a%psb_c_base_sparse_mat
  call b%set_sort_status(a%get_sort_status())
  call b%set_nzeros(a%get_nzeros())

  call move_alloc(a%ia, b%ia)
  call move_alloc(a%ja, b%ja)
  call move_alloc(a%val, b%val)
  call b%set_host()
  call a%free()

  if (.not.b%is_by_rows()) call b%fix(info)

  if (info /= psb_success_) goto 9999

  call psb_erractionrestore(err_act)
  return

9999 continue
  call psb_errpush(info,name)

  call psb_error_handler(err_act)

  return

end subroutine psb_c_mv_coo_to_coo

subroutine psb_c_mv_coo_from_coo(a,b,info) 
  use psb_error_mod
  use psb_c_base_mat_mod, psb_protect_name => psb_c_mv_coo_from_coo
  implicit none 
  class(psb_c_coo_sparse_mat), intent(inout) :: a
  class(psb_c_coo_sparse_mat), intent(inout) :: b
  integer(psb_ipk_), intent(out)            :: info

  integer(psb_ipk_) :: err_act
  integer(psb_ipk_) :: ierr(5)
  character(len=20)  :: name='from_coo'
  logical, parameter :: debug=.false.
  integer(psb_ipk_) :: m,n,nz


  call psb_erractionsave(err_act)
  info = psb_success_
  if (b%is_dev())   call b%sync()
  a%psb_c_base_sparse_mat = b%psb_c_base_sparse_mat
  call a%set_sort_status(b%get_sort_status())
  call a%set_nzeros(b%get_nzeros())

  call move_alloc(b%ia , a%ia   )
  call move_alloc(b%ja , a%ja   )
  call move_alloc(b%val, a%val )
  call b%free()
  call a%set_host()

  if (.not.a%is_by_rows()) call a%fix(info)

  if (info /= psb_success_) goto 9999

  call psb_erractionrestore(err_act)
  return

9999 continue
  call psb_errpush(info,name)

  call psb_error_handler(err_act)

  return

end subroutine psb_c_mv_coo_from_coo


subroutine psb_c_mv_coo_to_fmt(a,b,info) 
  use psb_error_mod
  use psb_c_base_mat_mod, psb_protect_name => psb_c_mv_coo_to_fmt
  implicit none 
  class(psb_c_coo_sparse_mat), intent(inout) :: a
  class(psb_c_base_sparse_mat), intent(inout) :: b
  integer(psb_ipk_), intent(out)            :: info

  integer(psb_ipk_) :: err_act
  integer(psb_ipk_) :: ierr(5)
  character(len=20)  :: name='to_coo'
  logical, parameter :: debug=.false.


  call psb_erractionsave(err_act)
  info = psb_success_

  call b%mv_from_coo(a,info)

  if (info /= psb_success_) goto 9999

  call psb_erractionrestore(err_act)
  return

9999 continue
  call psb_errpush(info,name)

  call psb_error_handler(err_act)

  return

end subroutine psb_c_mv_coo_to_fmt

subroutine psb_c_mv_coo_from_fmt(a,b,info) 
  use psb_error_mod
  use psb_c_base_mat_mod, psb_protect_name => psb_c_mv_coo_from_fmt
  implicit none 
  class(psb_c_coo_sparse_mat), intent(inout) :: a
  class(psb_c_base_sparse_mat), intent(inout) :: b
  integer(psb_ipk_), intent(out)            :: info

  integer(psb_ipk_) :: err_act
  integer(psb_ipk_) :: ierr(5)
  character(len=20)  :: name='from_coo'
  logical, parameter :: debug=.false.
  integer(psb_ipk_) :: m,n,nz


  call psb_erractionsave(err_act)
  info = psb_success_

  call b%mv_to_coo(a,info)

  if (info /= psb_success_) goto 9999

  call psb_erractionrestore(err_act)
  return

9999 continue
  call psb_errpush(info,name)

  call psb_error_handler(err_act)

  return

end subroutine psb_c_mv_coo_from_fmt

subroutine psb_c_coo_cp_from(a,b)
  use psb_error_mod
  use psb_c_base_mat_mod, psb_protect_name => psb_c_coo_cp_from
  implicit none 

  class(psb_c_coo_sparse_mat), intent(inout) :: a
  type(psb_c_coo_sparse_mat), intent(in)   :: b


  integer(psb_ipk_) :: err_act, info
  integer(psb_ipk_) :: ierr(5)
  character(len=20)  :: name='cp_from'
  logical, parameter :: debug=.false.

  call psb_erractionsave(err_act)
  info = psb_success_
  call a%cp_from_coo(b,info)
  if (info /= psb_success_) goto 9999

  call psb_erractionrestore(err_act)
  return

9999 continue
  call psb_errpush(info,name)

  call psb_error_handler(err_act)

  return

end subroutine psb_c_coo_cp_from

subroutine psb_c_coo_mv_from(a,b)
  use psb_error_mod
  use psb_c_base_mat_mod, psb_protect_name => psb_c_coo_mv_from
  implicit none 

  class(psb_c_coo_sparse_mat), intent(inout)  :: a
  type(psb_c_coo_sparse_mat), intent(inout) :: b


  integer(psb_ipk_) :: err_act, info
  integer(psb_ipk_) :: ierr(5)
  character(len=20)  :: name='mv_from'
  logical, parameter :: debug=.false.

  call psb_erractionsave(err_act)
  info = psb_success_
  call a%mv_from_coo(b,info)
  if (info /= psb_success_) goto 9999

  call psb_erractionrestore(err_act)
  return

9999 continue
  call psb_errpush(info,name)

  call psb_error_handler(err_act)

  return

end subroutine psb_c_coo_mv_from



subroutine psb_c_fix_coo(a,info,idir) 
  use psb_const_mod
  use psb_error_mod
  use psb_c_base_mat_mod, psb_protect_name => psb_c_fix_coo
  implicit none 

  class(psb_c_coo_sparse_mat), intent(inout) :: a
  integer(psb_ipk_), intent(out)                :: info
  integer(psb_ipk_), intent(in), optional :: idir
  integer(psb_ipk_), allocatable :: iaux(:)
  !locals
  integer(psb_ipk_) :: nza, nzl,iret,idir_, dupl_, nra, nca
  integer(psb_ipk_) :: i,j, irw, icl, err_act
  integer(psb_ipk_) :: debug_level, debug_unit
  integer(psb_ipk_) :: ierr(5)
  character(len=20)    :: name = 'psb_fixcoo'

  info  = psb_success_

  call psb_erractionsave(err_act)
  debug_unit  = psb_get_debug_unit()
  debug_level = psb_get_debug_level()

  if(debug_level >= psb_debug_serial_) &
       & write(debug_unit,*)  trim(name),': start ',&
       & size(a%ia),size(a%ja)
  if (present(idir)) then 
    idir_ = idir
  else
    idir_ = psb_row_major_
  endif
  if (a%is_dev())   call a%sync()
  
  nra = a%get_nrows()
  nca = a%get_ncols()
  nza = a%get_nzeros()
  if (nza >= 2) then 
    dupl_ = a%get_dupl()
    call psb_c_fix_coo_inner(nra,nca,nza,dupl_,a%ia,a%ja,a%val,i,info,idir_)
    if (info /= psb_success_) goto 9999
  else
    i = nza
  end if
  call a%set_sort_status(idir_)
  call a%set_nzeros(i)
  call a%set_asb()
  call a%set_host()

  call psb_erractionrestore(err_act)
  return

9999 call psb_error_handler(err_act)

  return

end subroutine psb_c_fix_coo



subroutine psb_c_fix_coo_inner(nr,nc,nzin,dupl,ia,ja,val,nzout,info,idir) 
  use psb_const_mod
  use psb_error_mod
  use psb_c_base_mat_mod, psb_protect_name => psb_c_fix_coo_inner
  use psb_string_mod
  use psb_ip_reord_mod
  implicit none 

  integer(psb_ipk_), intent(in)           :: nr, nc, nzin, dupl
  integer(psb_ipk_), intent(inout)        :: ia(:), ja(:)
  complex(psb_spk_), intent(inout) :: val(:)
  integer(psb_ipk_), intent(out)          :: nzout, info
  integer(psb_ipk_), intent(in), optional :: idir
  !locals
  integer(psb_ipk_), allocatable :: iaux(:), ias(:),jas(:), ix2(:)
  complex(psb_spk_),  allocatable :: vs(:)
  integer(psb_ipk_) :: nza, nzl,iret,idir_, dupl_
  integer(psb_ipk_) :: i,j, irw, icl, err_act, ip,is, imx, k, ii
  integer(psb_ipk_) :: debug_level, debug_unit
  integer(psb_ipk_) :: ierr(5)
  character(len=20)    :: name = 'psb_fixcoo'
  logical :: srt_inp, use_buffers

  info  = psb_success_

  call psb_erractionsave(err_act)
  debug_unit  = psb_get_debug_unit()
  debug_level = psb_get_debug_level()

  if(debug_level >= psb_debug_serial_) &
       & write(debug_unit,*)  trim(name),': start ',&
       & size(ia),size(ja)
  if (present(idir)) then 
    idir_ = idir
  else
    idir_ = psb_row_major_
  endif


  if (nzin < 2) then 
    call psb_erractionrestore(err_act)
    return
  end if

  dupl_ = dupl



  allocate(iaux(max(nr,nc,nzin)+2),stat=info) 
  if (info /= psb_success_) then 
    info = psb_err_alloc_dealloc_
    call psb_errpush(info,name)
    goto 9999
  end if

  allocate(ias(nzin),jas(nzin),vs(nzin),ix2(max(nr,nc,nzin)+2), stat=info)
  use_buffers = (info == 0)
  
  select case(idir_) 

  case(psb_row_major_) 
    !  Row major order
    if (use_buffers) then 
      if (.not.(  (ia(1) < 1).or.(ia(1)> nr)) ) then 
        iaux(:) = 0
        iaux(ia(1)) = iaux(ia(1)) + 1
        srt_inp = .true. 
        do i=2,nzin
          if (  (ia(i) < 1).or.(ia(i)> nr)) then 
            use_buffers = .false.
            srt_inp     = .false. 
            exit
          end if
          iaux(ia(i)) = iaux(ia(i)) + 1
          srt_inp = srt_inp .and.(ia(i-1)<=ia(i))
        end do
      else
        use_buffers=.false.
      end if
    end if
    ! Check again use_buffers.
    if (use_buffers) then 
      if (srt_inp) then 
        ! If input was already row-major 
        ! we can do it row-by-row here.
        k = 0
        i = 1
        do j=1, nr
          nzl = iaux(j)
          imx = i+nzl-1

          if (nzl > 0) then 
            call psi_i_msort_up(nzl,ja(i:imx),ix2,iret)
            if (iret == 0) &
                 & call psb_ip_reord(nzl,val(i:imx),&
                 & ia(i:imx),ja(i:imx),ix2)

            select case(dupl_)
            case(psb_dupl_ovwrt_)
              k = k + 1
              ia(k)  = ia(i)
              ja(k)  = ja(i) 
              val(k) = val(i) 
              irw = ia(k) 
              icl = ja(k) 
              do
                i = i + 1
                if (i > imx) exit
                if ((ia(i) == irw).and.(ja(i) == icl)) then 
                  val(k) = val(i)
                else
                  k = k+1
                  val(k) = val(i)
                  ia(k)  = ia(i)
                  ja(k)  = ja(i)
                  irw = ia(k) 
                  icl = ja(k) 
                endif
              enddo

            case(psb_dupl_add_)
              k = k + 1
              ia(k)  = ia(i)
              ja(k)  = ja(i) 
              val(k) = val(i) 
              irw = ia(k) 
              icl = ja(k) 
              do
                i = i + 1
                if (i > imx) exit
                if ((ia(i) == irw).and.(ja(i) == icl)) then 
                  val(k) = val(k) + val(i)
                else
                  k = k+1
                  val(k) = val(i)
                  ia(k)  = ia(i)
                  ja(k)  = ja(i)
                  irw = ia(k) 
                  icl = ja(k) 
                endif
              enddo

            case(psb_dupl_err_)
              k = k + 1
              ia(k)  = ia(i)
              ja(k)  = ja(i) 
              val(k) = val(i) 
              irw = ia(k) 
              icl = ja(k) 
              do
                i = i + 1
                if (i > imx) exit
                if ((ia(i) == irw).and.(ja(i) == icl)) then 
                  call psb_errpush(psb_err_duplicate_coo,name)          
                  goto 9999
                else
                  k = k+1
                  val(k) = val(i)
                  ia(k)  = ia(i)
                  ja(k)  = ja(i)
                  irw = ia(k) 
                  icl = ja(k) 
                endif
              enddo
            case default
              write(psb_err_unit,*) 'Error in fix_coo: unsafe dupl',dupl_
              info =-7
              return 
            end select

          endif
          !i = i + nzl
        enddo

      else  if (.not.srt_inp) then 
        ! If input was not already row-major 
        ! we have to sort all

        ip     = iaux(1)
        iaux(1) = 0
        do i=2, nr
          is = iaux(i) 
          iaux(i) = ip
          ip = ip + is
        end do
        iaux(nr+1) = ip

        do i=1,nzin
          irw = ia(i)
          ip = iaux(irw) + 1
          ias(ip) = ia(i)
          jas(ip) = ja(i)
          vs(ip)  = val(i)
          iaux(irw) = ip 
        end do
        k = 0
        i = 1
        do j=1, nr

          nzl = iaux(j)-i+1
          imx = i+nzl-1

          if (nzl > 0) then 
            call psi_i_msort_up(nzl,jas(i:imx),ix2,iret)
            if (iret == 0) &
                 & call psb_ip_reord(nzl,vs(i:imx),&
                 & ias(i:imx),jas(i:imx),ix2)

            select case(dupl_)
            case(psb_dupl_ovwrt_)
              k = k + 1
              ia(k)  = ias(i)
              ja(k)  = jas(i) 
              val(k) = vs(i) 
              irw = ia(k) 
              icl = ja(k) 
              do
                i = i + 1
                if (i > imx) exit
                if ((ias(i) == irw).and.(jas(i) == icl)) then 
                  val(k) = vs(i)
                else
                  k = k+1
                  val(k) = vs(i)
                  ia(k)  = ias(i)
                  ja(k)  = jas(i)
                  irw = ia(k) 
                  icl = ja(k) 
                endif
              enddo

            case(psb_dupl_add_)
              k = k + 1
              ia(k)  = ias(i)
              ja(k)  = jas(i) 
              val(k) = vs(i) 
              irw = ia(k) 
              icl = ja(k) 
              do
                i = i + 1
                if (i > imx) exit
                if ((ias(i) == irw).and.(jas(i) == icl)) then 
                  val(k) = val(k) + vs(i)
                else
                  k = k+1
                  val(k) = vs(i)
                  ia(k)  = ias(i)
                  ja(k)  = jas(i)
                  irw = ia(k) 
                  icl = ja(k) 
                endif
              enddo

            case(psb_dupl_err_)
              k = k + 1
              ia(k)  = ias(i)
              ja(k)  = jas(i) 
              val(k) = vs(i) 
              irw = ia(k) 
              icl = ja(k) 
              do
                i = i + 1
                if (i > imx) exit
                if ((ias(i) == irw).and.(jas(i) == icl)) then 
                  call psb_errpush(psb_err_duplicate_coo,name)          
                  goto 9999
                else
                  k = k+1
                  val(k) = vs(i)
                  ia(k)  = ias(i)
                  ja(k)  = jas(i)
                  irw = ia(k) 
                  icl = ja(k) 
                endif
              enddo
            case default
              write(psb_err_unit,*) 'Error in fix_coo: unsafe dupl',dupl_
              info =-7
              return 
            end select

          endif
        enddo

      end if

      i=k
      
      deallocate(ias,jas,vs,ix2, stat=info)

    else if (.not.use_buffers) then 

      !
      ! If we did not have enough memory for buffers,
      ! let's try in place. 
      ! 
      call psi_i_msort_up(nzin,ia(1:),iaux(1:),iret)
      if (iret == 0) &
           & call psb_ip_reord(nzin,val,ia,ja,iaux)
      i    = 1
      j    = i
      do while (i <= nzin)

        do while ((ia(j) == ia(i)))
          j = j+1
          if (j > nzin) exit
        enddo
        nzl = j - i
        call psi_i_msort_up(nzl,ja(i:),iaux(1:),iret)
        if (iret == 0) &
             & call psb_ip_reord(nzl,val(i:i+nzl-1),&
             & ia(i:i+nzl-1),ja(i:i+nzl-1),iaux)
        i = j
      enddo

      i = 1
      irw = ia(i)
      icl = ja(i)
      j = 1

      select case(dupl_)
      case(psb_dupl_ovwrt_)

        do 
          j = j + 1
          if (j > nzin) exit
          if ((ia(j) == irw).and.(ja(j) == icl)) then 
            val(i) = val(j)
          else
            i = i+1
            val(i) = val(j)
            ia(i) = ia(j)
            ja(i) = ja(j)
            irw = ia(i) 
            icl = ja(i) 
          endif
        enddo

      case(psb_dupl_add_)

        do 
          j = j + 1
          if (j > nzin) exit
          if ((ia(j) == irw).and.(ja(j) == icl)) then 
            val(i) = val(i) + val(j)
          else
            i = i+1
            val(i) = val(j)
            ia(i) = ia(j)
            ja(i) = ja(j)
            irw = ia(i) 
            icl = ja(i) 
          endif
        enddo

      case(psb_dupl_err_)
        do 
          j = j + 1
          if (j > nzin) exit
          if ((ia(j) == irw).and.(ja(j) == icl)) then 
            call psb_errpush(psb_err_duplicate_coo,name)          
            goto 9999
          else
            i = i+1
            val(i) = val(j)
            ia(i) = ia(j)
            ja(i) = ja(j)
            irw = ia(i) 
            icl = ja(i) 
          endif
        enddo
      case default
        write(psb_err_unit,*) 'Error in fix_coo: unsafe dupl',dupl_
        info =-7
      end select
    endif

    if(debug_level >= psb_debug_serial_)&
         & write(debug_unit,*)  trim(name),': end second loop'


  case(psb_col_major_) 

    if (use_buffers) then 
      iaux(:) = 0
      if (.not.(  (ja(1) < 1).or.(ja(1)> nc)) ) then 
        iaux(ja(1)) = iaux(ja(1)) + 1
        srt_inp = .true. 
        do i=2,nzin
          if (  (ja(i) < 1).or.(ja(i)> nc)) then 
            use_buffers = .false.
            srt_inp     = .false.
            exit
          end if
          iaux(ja(i)) = iaux(ja(i)) + 1
          srt_inp = srt_inp .and.(ja(i-1)<=ja(i))
        end do
      else
        use_buffers=.false.
      end if
    end if
    !use_buffers=use_buffers.and.srt_inp
    ! Check again use_buffers.
    if (use_buffers) then 

      if (srt_inp) then 
        ! If input was already col-major 
        ! we can do it col-by-col here.
        k = 0
        i = 1
        do j=1, nc
          nzl = iaux(j)
          imx = i+nzl-1

          if (nzl > 0) then 
            call psi_i_msort_up(nzl,ia(i:imx),ix2,iret)
            if (iret == 0) &
                 & call psb_ip_reord(nzl,val(i:imx),&
                 & ia(i:imx),ja(i:imx),ix2)

            select case(dupl_)
            case(psb_dupl_ovwrt_)
              k = k + 1
              ia(k)  = ia(i)
              ja(k)  = ja(i) 
              val(k) = val(i) 
              irw = ia(k) 
              icl = ja(k) 
              do
                i = i + 1
                if (i > imx) exit
                if ((ia(i) == irw).and.(ja(i) == icl)) then 
                  val(k) = val(i)
                else
                  k = k+1
                  val(k) = val(i)
                  ia(k)  = ia(i)
                  ja(k)  = ja(i)
                  irw = ia(k) 
                  icl = ja(k) 
                endif
              enddo

            case(psb_dupl_add_)
              k = k + 1
              ia(k)  = ia(i)
              ja(k)  = ja(i) 
              val(k) = val(i) 
              irw = ia(k) 
              icl = ja(k) 
              do
                i = i + 1
                if (i > imx) exit
                if ((ia(i) == irw).and.(ja(i) == icl)) then 
                  val(k) = val(k) + val(i)
                else
                  k = k+1
                  val(k) = val(i)
                  ia(k)  = ia(i)
                  ja(k)  = ja(i)
                  irw = ia(k) 
                  icl = ja(k) 
                endif
              enddo

            case(psb_dupl_err_)
              k = k + 1
              ia(k)  = ia(i)
              ja(k)  = ja(i) 
              val(k) = val(i) 
              irw = ia(k) 
              icl = ja(k) 
              do
                i = i + 1
                if (i > imx) exit
                if ((ia(i) == irw).and.(ja(i) == icl)) then 
                  call psb_errpush(psb_err_duplicate_coo,name)          
                  goto 9999
                else
                  k = k+1
                  val(k) = val(i)
                  ia(k)  = ia(i)
                  ja(k)  = ja(i)
                  irw = ia(k) 
                  icl = ja(k) 
                endif
              enddo
            case default
              write(psb_err_unit,*) 'Error in fix_coo: unsafe dupl',dupl_
              info =-7
              return 
            end select

          endif
          !i = i + nzl
        enddo

      else  if (.not.srt_inp) then 
        ! If input was not already col-major 
        ! we have to sort all
        ip     = iaux(1)
        iaux(1) = 0
        do i=2, nc
          is = iaux(i) 
          iaux(i) = ip
          ip = ip + is
        end do
        iaux(nc+1) = ip

        do i=1,nzin
          icl = ja(i)
          ip = iaux(icl) + 1
          ias(ip) = ia(i)
          jas(ip) = ja(i)
          vs(ip)  = val(i)
          iaux(icl) = ip 
        end do
        k = 0
        i = 1
        do j=1, nc
          nzl = iaux(j)-i+1
          imx = i+nzl-1

          if (nzl > 0) then 
            call psi_i_msort_up(nzl,ias(i:imx),ix2,iret)
            if (iret == 0) &
                 & call psb_ip_reord(nzl,vs(i:imx),&
                 & ias(i:imx),jas(i:imx),ix2)
            select case(dupl_)
            case(psb_dupl_ovwrt_)
              k = k + 1
              ia(k)  = ias(i)
              ja(k)  = jas(i) 
              val(k) = vs(i) 
              irw = ia(k) 
              icl = ja(k) 
              do
                i = i + 1
                if (i > imx) exit
                if ((ias(i) == irw).and.(jas(i) == icl)) then 
                  val(k) = vs(i)
                else
                  k = k+1
                  val(k) = vs(i)
                  ia(k)  = ias(i)
                  ja(k)  = jas(i)
                  irw = ia(k) 
                  icl = ja(k) 
                endif
              enddo

            case(psb_dupl_add_)
              k = k + 1
              ia(k)  = ias(i)
              ja(k)  = jas(i) 
              val(k) = vs(i) 
              irw = ia(k) 
              icl = ja(k) 
              do
                i = i + 1
                if (i > imx) exit
                if ((ias(i) == irw).and.(jas(i) == icl)) then 
                  val(k) = val(k) + vs(i)
                else
                  k = k+1
                  val(k) = vs(i)
                  ia(k)  = ias(i)
                  ja(k)  = jas(i)
                  irw = ia(k) 
                  icl = ja(k) 
                endif
              enddo

            case(psb_dupl_err_)
              k = k + 1
              ia(k)  = ias(i)
              ja(k)  = jas(i) 
              val(k) = vs(i) 
              irw = ia(k) 
              icl = ja(k) 
              do
                i = i + 1
                if (i > imx) exit
                if ((ias(i) == irw).and.(jas(i) == icl)) then 
                  call psb_errpush(psb_err_duplicate_coo,name)          
                  goto 9999
                else
                  k = k+1
                  val(k) = vs(i)
                  ia(k)  = ias(i)
                  ja(k)  = jas(i)
                  irw = ia(k) 
                  icl = ja(k) 
                endif
              enddo
            case default
              write(psb_err_unit,*) 'Error in fix_coo: unsafe dupl',dupl_
              info =-7
              return 
            end select

          endif
        enddo

      end if

      i=k
      deallocate(ias,jas,vs,ix2, stat=info)

    else if (.not.use_buffers) then 

      call psi_i_msort_up(nzin,ja(1:),iaux(1:),iret)
      if (iret == 0) &
           & call psb_ip_reord(nzin,val,ia,ja,iaux)
      i    = 1
      j    = i
      do while (i <= nzin)
        do while ((ja(j) == ja(i)))
          j = j+1
          if (j > nzin) exit
        enddo
        nzl = j - i
        call psi_i_msort_up(nzl,ia(i:),iaux(1:),iret)
        if (iret == 0) &
             & call psb_ip_reord(nzl,val(i:i+nzl-1),&
             & ia(i:i+nzl-1),ja(i:i+nzl-1),iaux)
        i = j
      enddo

      i = 1
      irw = ia(i)
      icl = ja(i)
      j = 1


      select case(dupl_)
      case(psb_dupl_ovwrt_)
        do 
          j = j + 1
          if (j > nzin) exit
          if ((ia(j) == irw).and.(ja(j) == icl)) then 
            val(i) = val(j)
          else
            i = i+1
            val(i) = val(j)
            ia(i) = ia(j)
            ja(i) = ja(j)
            irw = ia(i) 
            icl = ja(i) 
          endif
        enddo

      case(psb_dupl_add_)
        do 
          j = j + 1
          if (j > nzin) exit
          if ((ia(j) == irw).and.(ja(j) == icl)) then 
            val(i) = val(i) + val(j)
          else
            i = i+1
            val(i) = val(j)
            ia(i) = ia(j)
            ja(i) = ja(j)
            irw = ia(i) 
            icl = ja(i) 
          endif
        enddo

      case(psb_dupl_err_)
        do 
          j = j + 1
          if (j > nzin) exit
          if ((ia(j) == irw).and.(ja(j) == icl)) then 
            call psb_errpush(psb_err_duplicate_coo,name)
            goto 9999
          else
            i = i+1
            val(i) = val(j)
            ia(i) = ia(j)
            ja(i) = ja(j)
            irw = ia(i) 
            icl = ja(i) 
          endif
        enddo
      case default
        write(psb_err_unit,*) 'Error in fix_coo: unsafe dupl',dupl_
        info =-7
      end select
      if (debug_level >= psb_debug_serial_)&
           & write(debug_unit,*)  trim(name),': end second loop'

    end if

  case default
    write(debug_unit,*) trim(name),': unknown direction ',idir_
    info = psb_err_internal_error_
    call psb_errpush(info,name)
    goto 9999
  end select

  nzout = i 

  deallocate(iaux)

  call psb_erractionrestore(err_act)
  return

9999 call psb_error_handler(err_act)

  return

end subroutine psb_c_fix_coo_inner

