!!$ 
!!$              Parallel Sparse BLAS  version 3.0
!!$    (C) Copyright 2006, 2007, 2008, 2009, 2010, 2012
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
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!	Module to   define PREC_DATA,           !!
!!      structure for preconditioning.          !!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
module psb_z_base_prec_mod

  ! Reduces size of .mod file.
  use psb_base_mod, only : psb_dpk_, psb_ipk_, psb_long_int_k_,&
       & psb_desc_type, psb_sizeof, psb_free, psb_cdfree, psb_errpush, psb_act_abort_,&
       & psb_sizeof_int, psb_sizeof_long_int, psb_sizeof_sp, psb_sizeof_dp, &
       & psb_erractionsave, psb_erractionrestore, psb_error, psb_get_errstatus, psb_success_,&
       & psb_z_base_sparse_mat, psb_zspmat_type, psb_z_csr_sparse_mat,& 
       & psb_z_base_vect_type, psb_z_vect_type

  use psb_prec_const_mod

  type, abstract :: psb_z_base_prec_type
    integer(psb_ipk_) :: ictxt
  contains
    procedure, pass(prec) :: set_ctxt   => psb_z_base_set_ctxt
    procedure, pass(prec) :: get_ctxt   => psb_z_base_get_ctxt
    procedure, pass(prec) :: get_nzeros => psb_z_base_get_nzeros
    procedure, pass(prec) :: precseti   => psb_z_base_precseti
    procedure, pass(prec) :: precsetr   => psb_z_base_precsetr
    procedure, pass(prec) :: precsetc   => psb_z_base_precsetc
    generic, public       :: precset    => precseti, precsetr, precsetc
    procedure(psb_z_base_apply_vect), pass(prec), deferred :: z_apply_v  
    procedure(psb_z_base_apply), pass(prec), deferred :: z_apply    
    generic, public       :: apply     => z_apply, z_apply_v
    procedure(psb_z_base_precbld), pass(prec), deferred :: precbld    
    procedure(psb_z_base_sizeof), pass(prec), deferred :: sizeof     
    procedure(psb_z_base_precinit), pass(prec), deferred :: precinit   
    procedure(psb_z_base_precfree), pass(prec), deferred :: free   
    procedure(psb_z_base_precdescr), pass(prec), deferred :: precdescr  
    procedure(psb_z_base_precdump), pass(prec), deferred :: dump       
    procedure(psb_z_base_precclone), pass(prec), deferred :: clone       
  end type psb_z_base_prec_type

  private :: psb_z_base_set_ctxt, psb_z_base_get_ctxt, &
       & psb_z_base_get_nzeros

  abstract interface 
    subroutine psb_z_base_apply_vect(alpha,prec,x,beta,y,desc_data,info,trans,work)
      import psb_ipk_, psb_dpk_, psb_desc_type, psb_z_vect_type, &
           & psb_z_base_vect_type, psb_zspmat_type, psb_z_base_prec_type,&
           & psb_z_base_sparse_mat
      implicit none 
      type(psb_desc_type),intent(in)        :: desc_data
      class(psb_z_base_prec_type), intent(inout)  :: prec
      complex(psb_dpk_),intent(in)          :: alpha, beta
      type(psb_z_vect_type),intent(inout)   :: x
      type(psb_z_vect_type),intent(inout)   :: y
      integer(psb_ipk_), intent(out)                  :: info
      character(len=1), optional            :: trans
      complex(psb_dpk_),intent(inout), optional, target :: work(:)

    end subroutine psb_z_base_apply_vect
  end interface

  abstract interface 
    subroutine psb_z_base_apply(alpha,prec,x,beta,y,desc_data,info,trans,work)
      import psb_ipk_, psb_dpk_, psb_desc_type, psb_z_vect_type, &
           & psb_z_base_vect_type, psb_zspmat_type, psb_z_base_prec_type,&
           & psb_z_base_sparse_mat
      implicit none 
      type(psb_desc_type),intent(in)       :: desc_data
      class(psb_z_base_prec_type), intent(in)  :: prec
      complex(psb_dpk_),intent(in)         :: alpha, beta
      complex(psb_dpk_),intent(inout)      :: x(:)
      complex(psb_dpk_),intent(inout)      :: y(:)
      integer(psb_ipk_), intent(out)                 :: info
      character(len=1), optional           :: trans
      complex(psb_dpk_),intent(inout), optional, target :: work(:)

    end subroutine psb_z_base_apply
  end interface


  abstract interface 
    subroutine psb_z_base_precinit(prec,info)
      import psb_ipk_, psb_dpk_, psb_desc_type, psb_z_vect_type, &
           & psb_z_base_vect_type, psb_zspmat_type, psb_z_base_prec_type,&
           & psb_z_base_sparse_mat
      Implicit None

      class(psb_z_base_prec_type),intent(inout) :: prec
      integer(psb_ipk_), intent(out)                     :: info

    end subroutine psb_z_base_precinit
  end interface


  abstract interface 
    subroutine psb_z_base_precbld(a,desc_a,prec,info,upd,amold,afmt,vmold)
      import psb_ipk_, psb_dpk_, psb_desc_type, psb_z_vect_type, &
           & psb_z_base_vect_type, psb_zspmat_type, psb_z_base_prec_type,&
           & psb_z_base_sparse_mat
      Implicit None

      type(psb_zspmat_type), intent(in), target :: a
      type(psb_desc_type), intent(in), target   :: desc_a
      class(psb_z_base_prec_type),intent(inout) :: prec
      integer(psb_ipk_), intent(out)                      :: info
      character, intent(in), optional           :: upd
      character(len=*), intent(in), optional    :: afmt
      class(psb_z_base_sparse_mat), intent(in), optional :: amold
      class(psb_z_base_vect_type), intent(in), optional  :: vmold

    end subroutine psb_z_base_precbld
  end interface


  abstract interface 
    subroutine psb_z_base_precfree(prec,info)
      import psb_ipk_, psb_dpk_, psb_desc_type, psb_z_vect_type, &
           & psb_z_base_vect_type, psb_zspmat_type, psb_z_base_prec_type,&
           & psb_z_base_sparse_mat
      Implicit None

      class(psb_z_base_prec_type), intent(inout) :: prec
      integer(psb_ipk_), intent(out)                :: info

    end subroutine psb_z_base_precfree
  end interface


  abstract interface 
    subroutine psb_z_base_precdescr(prec,iout)
      import psb_ipk_, psb_dpk_, psb_desc_type, psb_z_vect_type, &
           & psb_z_base_vect_type, psb_zspmat_type, psb_z_base_prec_type,&
           & psb_z_base_sparse_mat
      Implicit None

      class(psb_z_base_prec_type), intent(in) :: prec
      integer(psb_ipk_), intent(in), optional    :: iout

    end subroutine psb_z_base_precdescr
  end interface

  abstract interface   
    subroutine psb_z_base_precdump(prec,info,prefix,head)
      import psb_ipk_, psb_dpk_, psb_desc_type, psb_z_vect_type, &
           & psb_z_base_vect_type, psb_zspmat_type, psb_z_base_prec_type,&
           & psb_z_base_sparse_mat
      implicit none 
      class(psb_z_base_prec_type), intent(in) :: prec
      integer(psb_ipk_), intent(out)             :: info
      character(len=*), intent(in), optional :: prefix,head

    end subroutine psb_z_base_precdump
  end interface
 
  abstract interface   
    subroutine psb_z_base_precclone(prec,precout,info)
      import psb_ipk_, psb_dpk_, psb_desc_type, psb_z_vect_type, &
           & psb_z_base_vect_type, psb_zspmat_type, psb_z_base_prec_type,&
           & psb_z_base_sparse_mat
      implicit none 
      class(psb_z_base_prec_type), intent(inout)              :: prec
      class(psb_z_base_prec_type), allocatable, intent(inout) :: precout
      integer(psb_ipk_), intent(out)               :: info
    end subroutine psb_z_base_precclone
  end interface

contains

  subroutine psb_z_base_precseti(prec,what,val,info)
    Implicit None

    class(psb_z_base_prec_type),intent(inout) :: prec
    integer(psb_ipk_), intent(in)                      :: what 
    integer(psb_ipk_), intent(in)                      :: val 
    integer(psb_ipk_), intent(out)                     :: info
    integer(psb_ipk_) :: err_act, nrow
    character(len=20)  :: name='z_base_precseti'

    !
    ! Base version does nothing.

    info = psb_success_ 

    return

  end subroutine psb_z_base_precseti

  subroutine psb_z_base_precsetr(prec,what,val,info)
    Implicit None

    class(psb_z_base_prec_type),intent(inout) :: prec
    integer(psb_ipk_), intent(in)                      :: what 
    real(psb_dpk_), intent(in)               :: val 
    integer(psb_ipk_), intent(out)                     :: info
    integer(psb_ipk_) :: err_act, nrow
    character(len=20)  :: name='z_base_precsetr'


    !
    ! Base version does nothing.
    !

    info = psb_success_ 

    return

  end subroutine psb_z_base_precsetr

  subroutine psb_z_base_precsetc(prec,what,val,info)
    Implicit None

    class(psb_z_base_prec_type),intent(inout) :: prec
    integer(psb_ipk_), intent(in)                      :: what 
    character(len=*), intent(in)             :: val
    integer(psb_ipk_), intent(out)                     :: info
    integer(psb_ipk_) :: err_act, nrow
    character(len=20)  :: name='z_base_precsetc'


    !
    ! Base version does nothing.
    !

    info = psb_success_ 

    return

  end subroutine psb_z_base_precsetc

  subroutine psb_z_base_set_ctxt(prec,ictxt)
    implicit none 
    class(psb_z_base_prec_type), intent(inout) :: prec
    integer(psb_ipk_), intent(in)  :: ictxt

    prec%ictxt = ictxt

  end subroutine psb_z_base_set_ctxt

  function psb_z_base_sizeof(prec) result(val)
    class(psb_z_base_prec_type), intent(in) :: prec
    integer(psb_long_int_k_) :: val

    val = 0
    return
  end function psb_z_base_sizeof

  function psb_z_base_get_ctxt(prec) result(val)
    class(psb_z_base_prec_type), intent(in) :: prec
    integer(psb_ipk_) :: val

    val = prec%ictxt
    return
  end function psb_z_base_get_ctxt

  function psb_z_base_get_nzeros(prec) result(res)
    class(psb_z_base_prec_type), intent(in) :: prec
    integer(psb_long_int_k_) :: res

    res = 0

  end function psb_z_base_get_nzeros

end module psb_z_base_prec_mod
