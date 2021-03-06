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
! File:  psb_zscatter.f90
!
! Subroutine: psb_zscatterm
!   This subroutine scatters a global matrix locally owned by one process
!   into pieces that are local to alle the processes.
!
! Arguments:
!   globx     -  complex,dimension(:,:).       The global matrix to scatter.
!   locx      -  complex,dimension(:,:).       The local piece of the distributed matrix.
!   desc_a    -  type(psb_desc_type).        The communication descriptor.
!   info      -  integer.                      Error code.
!   iroot     -  integer(optional).            The process that owns the global matrix. 
!                                              If -1 all the processes have a copy. 
!                                              Default -1
subroutine  psb_zscatterm(globx, locx, desc_a, info, root)

  use psb_base_mod, psb_protect_name => psb_zscatterm
#ifdef MPI_MOD
  use mpi
#endif
  implicit none
#ifdef MPI_H
  include 'mpif.h'
#endif

  complex(psb_dpk_), intent(out), allocatable  :: locx(:,:)
  complex(psb_dpk_), intent(in)     :: globx(:,:)
  type(psb_desc_type), intent(in)  :: desc_a
  integer(psb_ipk_), intent(out)             :: info
  integer(psb_ipk_), intent(in), optional    :: root


  ! locals
  integer(psb_mpk_) :: ictxt, np, me, iroot, icomm, myrank, rootrank, iam, nlr
  integer(psb_ipk_) :: ierr(5), err_act, nrow,&
       & ilocx, jlocx, lda_locx, lda_globx, lock, globk, k, maxk, &
       & col,pos
  integer(psb_lpk_) :: m, n, i, j, idx, iglobx, jglobx
  complex(psb_dpk_),allocatable  :: scatterv(:)
  integer(psb_mpk_), allocatable           :: displ(:), all_dim(:)
  integer(psb_lpk_), allocatable           :: l_t_g_all(:), ltg(:)
  character(len=20)        :: name, ch_err

  name='psb_scatterm'
  info=psb_success_
  call psb_erractionsave(err_act)
  if (psb_errstatus_fatal()) then
    info = psb_err_internal_error_ ;    goto 9999
  end if

  ictxt=desc_a%get_context()

  ! check on blacs grid 
  call psb_info(ictxt, iam, np)
  if (np == -1) then
    info = psb_err_context_error_
    call psb_errpush(info,name)
    goto 9999
  endif

  if (present(root)) then
    iroot = root
    if((iroot < -1).or.(iroot >= np)) then
      info=psb_err_input_value_invalid_i_
      ierr(1)=5; ierr(2)=iroot
      call psb_errpush(info,name,i_err=ierr)
      goto 9999
    end if
  else
    iroot = psb_root_
  end if

  iglobx = 1
  jglobx = 1
  lda_globx = size(globx,1)

  m = desc_a%get_global_rows()
  n = desc_a%get_global_cols()
  call psb_get_mpicomm(ictxt,icomm)
  call psb_get_rank(myrank,ictxt,me)

  if  (iroot==-1) then
    lda_globx = size(globx, 1)
    k = size(globx,2)
  else 
    if (iam==iroot) then  
      k = size(globx,2)
      lda_globx = size(globx, 1)
    end if
  end if
      
  m = desc_a%get_global_rows()
  n = desc_a%get_global_cols()


  !  there should be a global check on k here!!!
  if ((iroot==-1).or.(iam==iroot)) &
       & call psb_chkglobvect(m,n,lda_globx,iglobx,jglobx,desc_a,info)
  if(info /= psb_success_) then
    info=psb_err_from_subroutine_
    ch_err='psb_chk(glob)vect'
    call psb_errpush(info,name,a_err=ch_err)
    goto 9999
  end if
  
  nrow=desc_a%get_local_rows()
  ! root has to gather size information
  allocate(displ(np),all_dim(np),ltg(nrow),stat=info)
  if(info /= psb_success_) then
    info=psb_err_from_subroutine_
    ch_err='Allocate'
    call psb_errpush(info,name,a_err=ch_err)
    goto 9999
  end if
  do i=1, nrow
    ltg(i) = i
  end do
  call psb_loc_to_glob(ltg(1:nrow),desc_a,info) 

  call psb_geall(locx,desc_a,info,n=k)
  
  if ((iroot == -1).or.(np == 1)) then
    ! extract my chunk
    do j=1,k
      do i=1, nrow
        locx(i,j)=globx(ltg(i),j)
      end do
    end do
  else
    
    call psb_get_rank(rootrank,ictxt,iroot)
    !
    ! This is potentially unsafe when IPK=8
    ! But then, IPK=8 is highly experimental anyway.
    !
    nlr = nrow
    call mpi_gather(nlr,1,psb_mpi_mpk_,all_dim,&
         & 1,psb_mpi_mpk_,rootrank,icomm,info)

    if (iam == iroot) then
      displ(1)=0
      do i=2,np
        displ(i)=displ(i-1)+all_dim(i-1)
      end do

      ! root has to gather loc_glob from each process
      allocate(l_t_g_all(sum(all_dim)),scatterv(sum(all_dim)),stat=info)
    else
      !
      ! This is to keep debugging compilers from being upset by 
      ! calling an external MPI function with an unallocated array;
      ! the Fortran side would complain even if the MPI side does
      ! not use the unallocated stuff. 
      ! 
      allocate(l_t_g_all(1),scatterv(1),stat=info)
    end if
    if(info /= psb_success_) then
      info=psb_err_from_subroutine_
      ch_err='Allocate'
      call psb_errpush(info,name,a_err=ch_err)
      goto 9999
    end if

    call mpi_gatherv(ltg,nlr,&
         & psb_mpi_lpk_,l_t_g_all,all_dim,&
         & displ,psb_mpi_lpk_,rootrank,icomm,info)

    do col=1, k
      ! prepare vector to scatter
      if(iam == iroot) then
        do i=1,np
          pos=displ(i)
          do j=1, all_dim(i)
            idx=l_t_g_all(pos+j)
            scatterv(pos+j)=globx(idx,col)
          end do
        end do
      end if

      ! scatter 
      call mpi_scatterv(scatterv,all_dim,displ,&
           & psb_mpi_c_dpk_,locx(1,col),nrow,&
           & psb_mpi_c_dpk_,rootrank,icomm,info)

    end do

    deallocate(l_t_g_all, scatterv,stat=info)
    if(info /= psb_success_) then
      info=psb_err_from_subroutine_
      ch_err='deallocate'
      call psb_errpush(info,name,a_err=ch_err)
      goto 9999
    end if

  end if
  deallocate(all_dim, displ, ltg,stat=info)
  if(info /= psb_success_) then
    info=psb_err_from_subroutine_
    ch_err='deallocate'
    call psb_errpush(info,name,a_err=ch_err)
    goto 9999
  end if

  call psb_erractionrestore(err_act)
  return  

9999 call psb_error_handler(ione*ictxt,err_act)

    return

end subroutine psb_zscatterm




!!$ 
!!$              Parallel Sparse BLAS  version 3.5
!!$    (C) Copyright 2006-2018
!!$                       Salvatore Filippone    University of Rome Tor Vergata
!!$                       Alfredo Buttari      
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

! Subroutine: psb_zscatterv
!   This subroutine scatters a global vector locally owned by one process
!   into pieces that are local to alle the processes.
!
! Arguments:
!   globx     -  complex,dimension(:).         The global vector to scatter.
!   locx      -  complex,dimension(:).         The local piece of the ditributed vector.
!   desc_a    -  type(psb_desc_type).        The communication descriptor.
!   info      -  integer.                      Return code
!   iroot     -  integer(optional).            The process that owns the global vector. If -1 all
!                                              the processes have a copy.
!
subroutine  psb_zscatterv(globx, locx, desc_a, info, root)
  use psb_base_mod, psb_protect_name => psb_zscatterv
#ifdef MPI_MOD
  use mpi
#endif
  implicit none
#ifdef MPI_H
  include 'mpif.h'
#endif

  complex(psb_dpk_), intent(out), allocatable   :: locx(:)
  complex(psb_dpk_), intent(in)     :: globx(:)
  type(psb_desc_type), intent(in)  :: desc_a
  integer(psb_ipk_), intent(out)             :: info
  integer(psb_ipk_), intent(in), optional    :: root


  ! locals
  integer(psb_mpk_) :: ictxt, np, iam, iroot, iiroot, icomm, myrank, rootrank, nlr
  integer(psb_ipk_) :: ierr(5), err_act, nrow,&
       & ilocx, jlocx, lda_locx, lda_globx, k, pos, ilx, jlx
  integer(psb_lpk_) :: m, n, i, j, idx, iglobx, jglobx
  complex(psb_dpk_), allocatable  :: scatterv(:)
  integer(psb_mpk_), allocatable            :: displ(:), all_dim(:)
  integer(psb_lpk_), allocatable            :: l_t_g_all(:), ltg(:)
  character(len=20)        :: name, ch_err
  integer(psb_ipk_) :: debug_level, debug_unit

  name='psb_scatterv'
  info=psb_success_
  call psb_erractionsave(err_act)
  if  (psb_errstatus_fatal()) then
    info = psb_err_internal_error_ ;    goto 9999
  end if
  ictxt=desc_a%get_context()
  debug_unit  = psb_get_debug_unit()
  debug_level = psb_get_debug_level()


  ! check on blacs grid 
  call psb_info(ictxt, iam, np)
  if (np == -1) then
    info = psb_err_context_error_
    call psb_errpush(info,name)
    goto 9999
  endif

  if (present(root)) then
     iroot = root
     if((iroot < -1).or.(iroot > np)) then
        info=psb_err_input_value_invalid_i_
        ierr(1) = 5; ierr(2)=iroot
        call psb_errpush(info,name,i_err=ierr)
        goto 9999
     end if
  else
     iroot = psb_root_
  end if
  
  call psb_get_mpicomm(ictxt,icomm)
  call psb_get_rank(myrank,ictxt,iam)

  iglobx = 1
  jglobx = 1
  ilocx = 1
  jlocx = 1
  if ((iroot==-1).or.(iam==iroot))&
       & lda_globx = size(globx, 1)


  m = desc_a%get_global_rows()
  n = desc_a%get_global_cols()

  k = 1
  !  there should be a global check on k here!!!
  if ((iroot==-1).or.(iam==iroot)) &
       & call psb_chkglobvect(m,n,lda_globx,iglobx,jglobx,desc_a,info)

  if(info /= psb_success_) then
     info=psb_err_from_subroutine_
     ch_err='psb_chk(glob)vect'
     call psb_errpush(info,name,a_err=ch_err)
     goto 9999
  end if

  nrow = desc_a%get_local_rows()
  allocate(displ(np),all_dim(np),ltg(nrow),stat=info)
  if(info /= psb_success_) then
    info=psb_err_from_subroutine_
    ch_err='Allocate'
    call psb_errpush(info,name,a_err=ch_err)
    goto 9999
  end if

  do i=1, nrow
    ltg(i) = i
  end do
  call psb_loc_to_glob(ltg(1:nrow),desc_a,info) 
  call psb_geall(locx,desc_a,info)
  
  if ((iroot == -1).or.(np == 1)) then
    ! extract my chunk
    do i=1, nrow
      locx(i)=globx(ltg(i))
    end do
  else
    call psb_get_rank(rootrank,ictxt,iroot)
    !
    ! This is potentially unsafe when IPK=8
    ! But then, IPK=8 is highly experimental anyway.
    !
    nlr = nrow
    call mpi_gather(nlr,1,psb_mpi_mpk_,all_dim,&
         & 1,psb_mpi_mpk_,rootrank,icomm,info)

    if(iam == iroot) then
      displ(1)=0
      do i=2,np
        displ(i)=displ(i-1) + all_dim(i-1)
      end do
      if (debug_level >= psb_debug_inner_) then 
        write(debug_unit,*) iam,' ',trim(name),' displ:',displ(1:np), &
             &' dim',all_dim(1:np), sum(all_dim)
      endif
      
      ! root has to gather loc_glob from each process
      allocate(l_t_g_all(sum(all_dim)),scatterv(sum(all_dim)),stat=info)
      
    else
      !
      ! This is to keep debugging compilers from being upset by 
      ! calling an external MPI function with an unallocated array;
      ! the Fortran side would complain even if the MPI side does
      ! not use the unallocated stuff. 
      ! 
      allocate(l_t_g_all(1),scatterv(1),stat=info)
    end if
    if(info /= psb_success_) then
      info=psb_err_from_subroutine_
      ch_err='Allocate'
      call psb_errpush(info,name,a_err=ch_err)
      goto 9999
    end if

    call mpi_gatherv(ltg,nlr,&
         & psb_mpi_lpk_,l_t_g_all,all_dim,&
         & displ,psb_mpi_lpk_,rootrank,icomm,info)

    ! prepare vector to scatter
    if (iam == iroot) then
      do i=1,np
        pos=displ(i)
        do j=1, all_dim(i)
          idx=l_t_g_all(pos+j)
          scatterv(pos+j)=globx(idx)

        end do
      end do
    end if

    call mpi_scatterv(scatterv,all_dim,displ,&
         & psb_mpi_c_dpk_,locx,nrow,&
         & psb_mpi_c_dpk_,rootrank,icomm,info)

    deallocate(l_t_g_all, scatterv,stat=info)
    if(info /= psb_success_) then
      info=psb_err_from_subroutine_
      ch_err='deallocate'
      call psb_errpush(info,name,a_err=ch_err)
      goto 9999
    end if
  end if

  deallocate(all_dim, displ, ltg,stat=info)
  if(info /= psb_success_) then
    info=psb_err_from_subroutine_
    ch_err='deallocate'
    call psb_errpush(info,name,a_err=ch_err)
    goto 9999
  end if

  call psb_erractionrestore(err_act)
  return  

9999 call psb_error_handler(ione*ictxt,err_act)

    return

end subroutine psb_zscatterv

