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
module psi_collective_mod
  use psi_penv_mod
  use psi_m_collective_mod
  use psi_e_collective_mod
  use psi_s_collective_mod
  use psi_d_collective_mod
  use psi_c_collective_mod
  use psi_z_collective_mod

  interface psb_bcast
    module procedure  psb_hbcasts, psb_hbcastv,&
         & psb_hbcasts_ec, psb_hbcastv_ec,&
         & psb_lbcasts, psb_lbcastv, &
         & psb_lbcasts_ec, psb_lbcastv_ec 
  end interface psb_bcast

  
#if defined(SHORT_INTEGERS)
  interface psb_sum
    module procedure psb_i2sums, psb_i2sumv, psb_i2summ, &
         & psb_i2sums_ec, psb_i2sumv_ec, psb_i2summ_ec
  end interface psb_sum
#endif

contains

  
  subroutine psb_hbcasts(ictxt,dat,root,length)
#ifdef MPI_MOD
    use mpi
#endif
    implicit none 
#ifdef MPI_H
    include 'mpif.h'
#endif
    integer(psb_mpk_), intent(in)             :: ictxt
    character(len=*), intent(inout) :: dat
    integer(psb_mpk_), intent(in), optional   :: root,length

    integer(psb_mpk_) :: iam, np, root_,length_,info

#if !defined(SERIAL_MPI)
    if (present(root)) then
      root_ = root
    else
      root_ = psb_root_
    endif
    if (present(length)) then
      length_ = length
    else
      length_ = len(dat)
    endif

    call psb_info(ictxt,iam,np)

    call mpi_bcast(dat,length_,MPI_CHARACTER,root_,ictxt,info)
#endif    

  end subroutine psb_hbcasts

  subroutine psb_hbcastv(ictxt,dat,root)
#ifdef MPI_MOD
    use mpi
#endif
    implicit none 
#ifdef MPI_H
    include 'mpif.h'
#endif
    integer(psb_mpk_), intent(in)             :: ictxt
    character(len=*), intent(inout) :: dat(:)
    integer(psb_mpk_), intent(in), optional   :: root

    integer(psb_mpk_) :: iam, np, root_,length_,info, size_

#if !defined(SERIAL_MPI)
    if (present(root)) then
      root_ = root
    else
      root_ =  psb_root_
    endif
    length_ = len(dat)
    size_   = size(dat) 

    call psb_info(ictxt,iam,np)

    call mpi_bcast(dat,length_*size_,MPI_CHARACTER,root_,ictxt,info)
#endif    

  end subroutine psb_hbcastv

  subroutine psb_hbcasts_ec(ictxt,dat,root)
    implicit none 
    integer(psb_epk_), intent(in)              :: ictxt
    character(len=*), intent(inout)  :: dat
    integer(psb_epk_), intent(in), optional    :: root
    integer(psb_mpk_) :: ictxt_, root_

    ictxt_ = ictxt
    if (present(root)) then 
      root_ = root
      call psb_bcast(ictxt_,dat,root_)
    else
      call psb_bcast(ictxt_,dat)
    end if
  end subroutine psb_hbcasts_ec

  subroutine psb_hbcastv_ec(ictxt,dat,root)
    implicit none 
    integer(psb_epk_), intent(in)              :: ictxt
    character(len=*), intent(inout)  :: dat(:)
    integer(psb_epk_), intent(in), optional    :: root
    integer(psb_mpk_) :: ictxt_, root_

    ictxt_ = ictxt
    if (present(root)) then 
      root_ = root
      call psb_bcast(ictxt_,dat,root_)
    else
      call psb_bcast(ictxt_,dat)
    end if
  end subroutine psb_hbcastv_ec


  
  subroutine psb_lbcasts(ictxt,dat,root)
#ifdef MPI_MOD
    use mpi
#endif
    implicit none 
#ifdef MPI_H
    include 'mpif.h'
#endif
    integer(psb_mpk_), intent(in)             :: ictxt
    logical, intent(inout)          :: dat
    integer(psb_mpk_), intent(in), optional   :: root

    integer(psb_mpk_) :: iam, np, root_,info

#if !defined(SERIAL_MPI)
    if (present(root)) then
      root_ = root
    else
      root_ = psb_root_
    endif

    call psb_info(ictxt,iam,np)
    call mpi_bcast(dat,1,MPI_LOGICAL,root_,ictxt,info)
#endif    

  end subroutine psb_lbcasts


  subroutine psb_lbcastv(ictxt,dat,root)
#ifdef MPI_MOD
    use mpi
#endif
    implicit none 
#ifdef MPI_H
    include 'mpif.h'
#endif
    integer(psb_mpk_), intent(in)             :: ictxt
    logical, intent(inout)          :: dat(:)
    integer(psb_mpk_), intent(in), optional   :: root

    integer(psb_mpk_) :: iam, np, root_,info

#if !defined(SERIAL_MPI)
    if (present(root)) then
      root_ = root
    else
      root_ = psb_root_
    endif

    call psb_info(ictxt,iam,np)
    call mpi_bcast(dat,size(dat),MPI_LOGICAL,root_,ictxt,info)
#endif    

  end subroutine psb_lbcastv


  subroutine psb_lbcasts_ec(ictxt,dat,root)
    implicit none 
    integer(psb_epk_), intent(in)              :: ictxt
    logical, intent(inout)  :: dat
    integer(psb_epk_), intent(in), optional    :: root
    integer(psb_mpk_) :: ictxt_, root_

    ictxt_ = ictxt
    if (present(root)) then 
      root_ = root
      call psb_bcast(ictxt_,dat,root_)
    else
      call psb_bcast(ictxt_,dat)
    end if
  end subroutine psb_lbcasts_ec

  subroutine psb_lbcastv_ec(ictxt,dat,root)
    implicit none 
    integer(psb_epk_), intent(in)              :: ictxt
    logical, intent(inout)  :: dat(:)
    integer(psb_epk_), intent(in), optional    :: root
    integer(psb_mpk_) :: ictxt_, root_

    ictxt_ = ictxt
    if (present(root)) then 
      root_ = root
      call psb_bcast(ictxt_,dat,root_)
    else
      call psb_bcast(ictxt_,dat)
    end if
  end subroutine psb_lbcastv_ec


  
#if defined(SHORT_INTEGERS)
  subroutine psb_i2sums(ictxt,dat,root)

#ifdef MPI_MOD
    use mpi
#endif
    implicit none 
#ifdef MPI_H
    include 'mpif.h'
#endif
    integer(psb_mpk_), intent(in)              :: ictxt
    integer(psb_i2pk_), intent(inout)  :: dat
    integer(psb_mpk_), intent(in), optional    :: root
    integer(psb_mpk_) :: root_
    integer(psb_i2pk_) :: dat_
    integer(psb_mpk_) :: iam, np, info
    integer(psb_ipk_) :: iinfo

#if !defined(SERIAL_MPI)

    call psb_info(ictxt,iam,np)

    if (present(root)) then 
      root_ = root
    else
      root_ = -1
    endif
    if (root_ == -1) then 
      call mpi_allreduce(dat,dat_,1,psb_mpi_i2pk_,mpi_sum,ictxt,info)
      dat = dat_
    else
      call mpi_reduce(dat,dat_,1,psb_mpi_i2pk_,mpi_sum,root_,ictxt,info)
      if (iam == root_) dat = dat_
    endif

#endif    
  end subroutine psb_i2sums

  subroutine psb_i2sumv(ictxt,dat,root)
    use psb_realloc_mod
#ifdef MPI_MOD
    use mpi
#endif
    implicit none 
#ifdef MPI_H
    include 'mpif.h'
#endif
    integer(psb_mpk_), intent(in)              :: ictxt
    integer(psb_i2pk_), intent(inout)  :: dat(:)
    integer(psb_mpk_), intent(in), optional    :: root
    integer(psb_mpk_) :: root_
    integer(psb_i2pk_), allocatable :: dat_(:)
    integer(psb_mpk_) :: iam, np,  info
    integer(psb_ipk_) :: iinfo

#if !defined(SERIAL_MPI)

    call psb_info(ictxt,iam,np)

    if (present(root)) then 
      root_ = root
    else
      root_ = -1
    endif
    if (root_ == -1) then 
      call psb_realloc(size(dat),dat_,iinfo)
      dat_=dat
      if (iinfo == psb_success_) call mpi_allreduce(dat_,dat,size(dat),&
           & psb_mpi_i2pk_,mpi_sum,ictxt,info)
    else
      if (iam == root_) then 
        call psb_realloc(size(dat),dat_,iinfo)
        dat_=dat
        call mpi_reduce(dat_,dat,size(dat),psb_mpi_i2pk_,mpi_sum,root_,ictxt,info)
      else
        call mpi_reduce(dat,dat_,size(dat),psb_mpi_i2pk_,mpi_sum,root_,ictxt,info)
      end if
    endif
#endif    
  end subroutine psb_i2sumv

  subroutine psb_i2summ(ictxt,dat,root)
    use psb_realloc_mod
#ifdef MPI_MOD
    use mpi
#endif
    implicit none 
#ifdef MPI_H
    include 'mpif.h'
#endif
    integer(psb_mpk_), intent(in)              :: ictxt
    integer(psb_i2pk_), intent(inout)  :: dat(:,:)
    integer(psb_mpk_), intent(in), optional    :: root
    integer(psb_mpk_) :: root_
    integer(psb_i2pk_), allocatable :: dat_(:,:)
    integer(psb_mpk_) :: iam, np,  info
    integer(psb_ipk_) :: iinfo


#if !defined(SERIAL_MPI)
    call psb_info(ictxt,iam,np)

    if (present(root)) then 
      root_ = root
    else
      root_ = -1
    endif
    if (root_ == -1) then 
      call psb_realloc(size(dat,1),size(dat,2),dat_,iinfo)
      dat_=dat
      if (iinfo == psb_success_) call mpi_allreduce(dat_,dat,size(dat),&
           & psb_mpi_i2pk_,mpi_sum,ictxt,info)
    else
      if (iam == root_) then 
        call psb_realloc(size(dat,1),size(dat,2),dat_,iinfo)
        dat_=dat
        call mpi_reduce(dat_,dat,size(dat),psb_mpi_i2pk_,mpi_sum,root_,ictxt,info)
      else
        call mpi_reduce(dat,dat_,size(dat),psb_mpi_i2pk_,mpi_sum,root_,ictxt,info)
      end if
    endif
#endif    
  end subroutine psb_i2summ

  subroutine psb_i2sums_ec(ictxt,dat,root)
    implicit none 
    integer(psb_epk_), intent(in)              :: ictxt
    integer(psb_i2pk_), intent(inout)  :: dat
    integer(psb_epk_), intent(in), optional    :: root
    integer(psb_mpk_) :: ictxt_, root_

    ictxt_ = ictxt
    if (present(root)) then 
      root_ = root
      call psb_sum(ictxt_,dat,root_)
    else
      call psb_sum(ictxt_,dat)
    end if
  end subroutine psb_i2sums_ec

  subroutine psb_i2sumv_ec(ictxt,dat,root)
    implicit none 
    integer(psb_epk_), intent(in)              :: ictxt
    integer(psb_i2pk_), intent(inout)  :: dat(:)
    integer(psb_epk_), intent(in), optional    :: root
    integer(psb_mpk_) :: ictxt_, root_

    ictxt_ = ictxt
    if (present(root)) then 
      root_ = root
      call psb_sum(ictxt_,dat,root_)
    else
      call psb_sum(ictxt_,dat)
    end if
  end subroutine psb_i2sumv_ec

  subroutine psb_i2summ_ec(ictxt,dat,root)
    implicit none 
    integer(psb_epk_), intent(in)              :: ictxt
    integer(psb_i2pk_), intent(inout)  :: dat(:,:)
    integer(psb_epk_), intent(in), optional    :: root
    integer(psb_mpk_) :: ictxt_, root_

    ictxt_ = ictxt
    if (present(root)) then 
      root_ = root
      call psb_sum(ictxt_,dat,root_)
    else
      call psb_sum(ictxt_,dat)
    end if
  end subroutine psb_i2summ_ec

#endif

end module psi_collective_mod
