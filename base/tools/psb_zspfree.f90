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
! File: psb_zspfree.f90
!
! Subroutine: psb_zspfree
!    Frees a sparse matrix structure.
! 
! Arguments: 
!    a        - type(psb_zspmat_type).          The sparse matrix to be freed.      
!    desc_a   - type(psb_desc_type).            The communication descriptor.
!    info     - integer.                          return code.
!
subroutine psb_zspfree(a, desc_a,info)
  use psb_base_mod, psb_protect_name => psb_zspfree
  implicit none

  !....parameters...
  type(psb_desc_type), intent(in)      :: desc_a
  type(psb_zspmat_type), intent(inout) :: a
  integer(psb_ipk_), intent(out)        :: info
  !...locals....
  integer(psb_ipk_) :: ictxt, err_act
  character(len=20)   :: name

  info=psb_success_
  name = 'psb_zspfree'
  call psb_erractionsave(err_act)
  if (psb_errstatus_fatal()) then
    info = psb_err_internal_error_ ;    goto 9999
  end if

  if (.not.psb_is_ok_desc(desc_a)) then
    info = psb_err_forgot_spall_
    call psb_errpush(info,name)
    return
  else
    ictxt = desc_a%get_context()
  end if

  !...deallocate a....
  call a%free()

  call psb_erractionrestore(err_act)
  return

9999 call psb_error_handler(ictxt,err_act)

  return

end subroutine psb_zspfree



