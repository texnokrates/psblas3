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
subroutine psb_dprecseti(p,what,val,info)

  use psb_base_mod
  use psb_prec_mod, psb_protect_name => psb_dprecseti
  implicit none
  type(psb_dprec_type), intent(inout)    :: p
  integer(psb_ipk_) :: what, val 
  integer(psb_ipk_), intent(out)                   :: info
  character(len=20) :: name='precset'

  info = psb_success_
  if (.not.allocated(p%prec)) then 
    info = 1124
    call psb_errpush(info,name,a_err="preconditioner")
    return
!!$    goto 9999
  end if

  call p%prec%precset(what,val,info)

  return

end subroutine psb_dprecseti


subroutine psb_dprecsetr(p,what,val,info)

  use psb_base_mod
  use psb_prec_mod, psb_protect_name => psb_dprecsetr
  implicit none
  type(psb_dprec_type), intent(inout)    :: p
  integer(psb_ipk_) :: what
  real(psb_dpk_)                       :: val 
  integer(psb_ipk_), intent(out)                   :: info
  character(len=20) :: name='precset'

  info = psb_success_
  if (.not.allocated(p%prec)) then 
    info = 1124
    call psb_errpush(info,name,a_err="preconditioner")
    return
!!$    goto 9999
  end if

  call p%prec%precset(what,val,info)

  return

end subroutine psb_dprecsetr
