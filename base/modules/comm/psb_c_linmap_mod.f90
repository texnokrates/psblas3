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
!
!
! package: psb_c_linmap_mod
!    Defines data types and interfaces for mapping between vectors belonging
!    to different spaces.
!
module psb_c_linmap_mod

  use psb_const_mod
  use psb_c_mat_mod
  use psb_desc_mod
  use psb_base_linmap_mod


  type, extends(psb_base_linmap_type) ::  psb_clinmap_type 
    type(psb_cspmat_type) :: map_X2Y, map_Y2X
  contains
    procedure, pass(map) :: sizeof   => c_map_sizeof
    procedure, pass(map) :: is_asb   => c_is_asb
    procedure, pass(map) :: free     => c_free
    procedure, pass(map) :: clone    => c_clone
    procedure, pass(map) :: cnv      => psb_c_map_cscnv
  end type psb_clinmap_type


  interface psb_map_X2Y
    subroutine psb_c_map_X2Y(alpha,x,beta,y,map,info,work)
      import :: psb_ipk_, psb_spk_, psb_clinmap_type
      implicit none 
      type(psb_clinmap_type), intent(in) :: map
      complex(psb_spk_), intent(in)     :: alpha,beta
      complex(psb_spk_), intent(inout)  :: x(:)
      complex(psb_spk_), intent(out)    :: y(:)
      integer(psb_ipk_), intent(out)           :: info 
      complex(psb_spk_), optional       :: work(:)
    end subroutine psb_c_map_X2Y
    subroutine psb_c_map_X2Y_vect(alpha,x,beta,y,map,info,work,vtx,vty)
      use psb_c_vect_mod, only : psb_c_vect_type
      import :: psb_ipk_, psb_spk_, psb_clinmap_type
      implicit none 
      type(psb_clinmap_type), intent(in) :: map
      complex(psb_spk_), intent(in)     :: alpha,beta
      type(psb_c_vect_type), intent(inout)  :: x,y
      integer(psb_ipk_), intent(out)           :: info 
      complex(psb_spk_), optional       :: work(:)
      type(psb_c_vect_type), optional, target, intent(inout)  :: vtx,vty
    end subroutine psb_c_map_X2Y_vect
  end interface

  interface psb_map_Y2X
    subroutine psb_c_map_Y2X(alpha,x,beta,y,map,info,work)
      import :: psb_ipk_, psb_spk_, psb_clinmap_type
      implicit none 
      type(psb_clinmap_type), intent(in) :: map
      complex(psb_spk_), intent(in)     :: alpha,beta
      complex(psb_spk_), intent(inout)  :: x(:)
      complex(psb_spk_), intent(out)    :: y(:)
      integer(psb_ipk_), intent(out)           :: info 
      complex(psb_spk_), optional       :: work(:)
    end subroutine psb_c_map_Y2X
    subroutine psb_c_map_Y2X_vect(alpha,x,beta,y,map,info,work,vtx,vty)
      use psb_c_vect_mod, only : psb_c_vect_type
      import :: psb_ipk_, psb_spk_, psb_clinmap_type
      implicit none 
      type(psb_clinmap_type), intent(in) :: map
      complex(psb_spk_), intent(in)     :: alpha,beta
      type(psb_c_vect_type), intent(inout)  :: x,y
      integer(psb_ipk_), intent(out)           :: info 
      complex(psb_spk_), optional       :: work(:)
      type(psb_c_vect_type), optional, target, intent(inout)  :: vtx,vty
    end subroutine psb_c_map_Y2X_vect
  end interface


  interface psb_map_cscnv
    module procedure psb_c_map_cscnv
  end interface

  interface psb_linmap_sub
    module procedure psb_c_linmap_sub
  end interface

  interface psb_move_alloc
    module procedure  psb_clinmap_transfer
  end interface

  interface psb_linmap
    function psb_c_linmap(map_kind,desc_X, desc_Y, map_X2Y, map_Y2X,iaggr,naggr)
      use psb_c_mat_mod, only : psb_cspmat_type
      import :: psb_ipk_, psb_clinmap_type, psb_desc_type, psb_lpk_
      implicit none 
      type(psb_clinmap_type)                  :: psb_c_linmap    
      type(psb_desc_type), target             :: desc_X, desc_Y
      type(psb_cspmat_type), intent(inout)    :: map_X2Y, map_Y2X
      integer(psb_ipk_), intent(in)           :: map_kind
      integer(psb_lpk_), intent(in), optional :: iaggr(:), naggr(:)
    end function psb_c_linmap
  end interface

  private :: c_map_sizeof, c_is_asb, c_free





contains

  function c_map_sizeof(map) result(val)
    implicit none 
    class(psb_clinmap_type), intent(in) :: map
    integer(psb_epk_) :: val

    val = map%psb_base_linmap_type%sizeof()
    val = val + map%map_X2Y%sizeof()
    val = val + map%map_Y2X%sizeof()

  end function c_map_sizeof


  function c_is_asb(map) result(val)
    implicit none 
    class(psb_clinmap_type), intent(in) :: map
    logical  :: val

    val = map%psb_base_linmap_type%is_asb() .and. &
         & map%map_X2Y%is_asb() .and.map%map_Y2X%is_asb() 
    
  end function c_is_asb


  subroutine psb_c_map_cscnv(map,info,type,mold,imold)    
    implicit none
    class(psb_clinmap_type), intent(inout)  :: map
    integer(psb_ipk_), intent(out)                   :: info
    character(len=*), intent(in), optional :: type
    class(psb_c_base_sparse_mat), intent(in), optional :: mold
    class(psb_i_base_vect_type), intent(in), optional  :: imold

    if (map%map_X2Y%is_asb())&
         & call map%map_X2Y%cscnv(info,type=type,mold=mold)
    if (info == psb_success_ .and.map%map_Y2X%is_asb())&
         & call map%map_Y2X%cscnv(info,type=type,mold=mold)
    if (present(imold)) then 
      call map%desc_X%cnv(mold=imold)
      call map%desc_Y%cnv(mold=imold)
    end if

  end subroutine psb_c_map_cscnv

  subroutine psb_c_linmap_sub(out_map,map_kind,desc_X, desc_Y,&
       & map_X2Y, map_Y2X,iaggr,naggr)
    implicit none 
    type(psb_clinmap_type), intent(out)     :: out_map    
    type(psb_desc_type), target             :: desc_X, desc_Y
    type(psb_cspmat_type), intent(inout)    :: map_X2Y, map_Y2X
    integer(psb_ipk_), intent(in)           :: map_kind
    integer(psb_lpk_), intent(in), optional :: iaggr(:), naggr(:)
    out_map = psb_linmap(map_kind,desc_X,desc_Y,map_X2Y,map_Y2X,iaggr,naggr)
  end subroutine psb_c_linmap_sub

  subroutine  psb_clinmap_transfer(mapin,mapout,info)
    use psb_realloc_mod
    implicit none 
    type(psb_clinmap_type) :: mapin,mapout
    integer(psb_ipk_), intent(out)      :: info 
    
    call psb_move_alloc(mapin%psb_base_linmap_type, &
         & mapout%psb_base_linmap_type,info)
    call psb_move_alloc(mapin%map_X2Y,mapout%map_X2Y,info)
    call psb_move_alloc(mapin%map_Y2X,mapout%map_Y2X,info)

  end subroutine psb_clinmap_transfer

  subroutine  c_free(map,info)
    implicit none 
    class(psb_clinmap_type) :: map
    integer(psb_ipk_), intent(out)      :: info 
    
    call map%psb_base_linmap_type%free(info)
    
    call map%map_X2Y%free()
    call map%map_Y2X%free()

  end subroutine c_free
  

  subroutine  c_clone(map,mapout,info)
    use psb_error_mod
    implicit none 
    class(psb_clinmap_type), intent(inout) :: map
    class(psb_base_linmap_type), intent(inout) :: mapout
    integer(psb_ipk_)     :: info 
    
    integer(psb_ipk_) :: err_act
    character(len=20)  :: name='clone'

    info = 0
    select type(mout => mapout)
    class is (psb_clinmap_type)
      call mout%free(info)
      ! Base clone!    
      if (info == 0) call &
           & map%psb_base_linmap_type%clone(mout%psb_base_linmap_type,info)
      if (info == 0) call map%map_X2Y%clone(mout%map_X2Y,info)
      if (info == 0) call map%map_Y2X%clone(mout%map_Y2X,info)
    class default
      info = psb_err_invalid_dynamic_type_
      info = psb_err_missing_override_method_
      call psb_errpush(info,name,m_err=(/2/))
      call psb_erractionsave(err_act)

      call psb_error_handler(err_act)
    end select

      
  end subroutine c_clone
  

end module psb_c_linmap_mod

