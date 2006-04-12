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
!!$ CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
!!$ C                                                                      C
!!$ C  References:                                                         C
!!$ C          [1] Duff, I., Marrone, M., Radicati, G., and Vittoli, C.    C
!!$ C              Level 3 basic linear algebra subprograms for sparse     C
!!$ C              matrices: a user level interface                        C
!!$ C              ACM Trans. Math. Softw., 23(3), 379-401, 1997.          C
!!$ C                                                                      C
!!$ C                                                                      C
!!$ C         [2]  S. Filippone, M. Colajanni                              C
!!$ C              PSBLAS: A library for parallel linear algebra           C
!!$ C              computation on sparse matrices                          C
!!$ C              ACM Trans. on Math. Softw., 26(4), 527-550, Dec. 2000.  C
!!$ C                                                                      C
!!$ C         [3] M. Arioli, I. Duff, M. Ruiz                              C
!!$ C             Stopping criteria for iterative solvers                  C
!!$ C             SIAM J. Matrix Anal. Appl., Vol. 13, pp. 138-144, 1992   C
!!$ C                                                                      C
!!$ C                                                                      C
!!$ C         [4] R. Barrett et al                                         C
!!$ C             Templates for the solution of linear systems             C
!!$ C             SIAM, 1993                                          
!!$ C                                                                      C
!!$ C                                                                      C
!!$ CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
! File:  psb_zcgs.f90
!
! Subroutine: psb_zcgs
!
! Parameters:
!    a       -  type(<psb_zspmat_type>).     The sparse matrix containing A.
!    prec    -  type(<psb_prec_type>).       The data structure containing the preconditioner.
!    b       -  real,dimension(:).           The right hand side.
!    x       -  real,dimension(:).           The vector of unknowns.
!    eps     -  real.                        The error tolerance.
!    desc_a  -  type(<psb_desc_type>).       The communication descriptor.
!    info    -  integer.                     Eventually returns an error code.
!    itmax   -  integer(optional).           The maximum number of iterations.
!    iter    -  integer(optional).           The number of iterations performed.
!    err     -  real(optional).              The error on return.
!    itrace  -  integer(optional).           The unit to write messages onto.
!    istop   -  integer(optional).           The stopping criterium.
!
Subroutine psb_zcgs(a,prec,b,x,eps,desc_a,info,&
     &itmax,iter,err,itrace,istop)
  use psb_serial_mod
  use psb_descriptor_type
  use psb_prec_type
  use psb_psblas_mod
  use psb_tools_mod
  use psb_const_mod
  use psb_prec_mod
  use psb_error_mod
  implicit none

!!$  parameters 
  Type(psb_zspmat_type), Intent(in)  :: a
  Type(psb_desc_type), Intent(in)    :: desc_a 
  Type(psb_zprec_type), Intent(in)   :: prec 
  Complex(Kind(1.d0)), Intent(in)       :: b(:)
  Complex(Kind(1.d0)), Intent(inout)    :: x(:)
  Real(Kind(1.d0)), Intent(in)       :: eps
  integer, intent(out)               :: info
  Integer, Optional, Intent(in)      :: itmax, itrace,istop
  Integer, Optional, Intent(out)     :: iter
  Real(Kind(1.d0)), Optional, Intent(out) :: err
!!$   local data
  Complex(Kind(1.d0)), Pointer  :: aux(:),wwrk(:,:)
  Complex(Kind(1.d0)), Pointer  :: ww(:), q(:),&
       & r(:), p(:), v(:), s(:), t(:), z(:), f(:), rt(:),qt(:),uv(:)
  Integer, Pointer           :: iperm(:), ipnull(:), ipsave(:)
  Real(Kind(1.d0)) ::rerr
  Integer       ::litmax, liter, naux, m, mglob, it, itrac,int_err(5),&
       & nprows,npcols,me,mecol, n_row, n_col,istop_, err_act
  Character     ::diagl, diagu
  Logical, Parameter :: exchange=.True., noexchange=.False.  
  Integer, Parameter :: irmax = 8
  Integer            :: itx, i, isvch, ich, icontxt
  Logical            :: do_renum_left
  Logical, Parameter :: debug = .false.
  Real(Kind(1.d0)) :: rni, xni, bni, ani,bn2
  complex(Kind(1.d0)) :: alpha, beta, rho, rho_old, sigma, omega, tau 
  character(len=20)             :: name,ch_err

  info = 0
  name = 'psb_zcgs'
  call psb_erractionsave(err_act)

  If (debug) Write(*,*) 'entering psb_zcgs'
  icontxt = desc_a%matrix_data(psb_ctxt_)
  Call blacs_gridinfo(icontxt,nprows,npcols,me,mecol)
  If (debug) Write(*,*) 'psb_zcgs: from gridinfo',nprows,npcols,me

  mglob = desc_a%matrix_data(psb_m_)
  n_row = desc_a%matrix_data(psb_n_row_)
  n_col  = desc_a%matrix_data(psb_n_col_)

  If (Present(istop)) Then 
    istop_ = istop 
  Else
    istop_ = 1
  Endif
!
!  istop_ = 1:  normwise backward error, infinity norm 
!  istop_ = 2:  ||r||/||b||   norm 2 
!
!!$
!!$  If ((prec%prec < 0).Or.(prec%prec > 6) ) Then
!!$     Write(0,*) 'f90_cgstab: invalid iprec',prec%prec
!!$     If (Present(ierr)) ierr=-1
!!$     Return
!!$  Endif
  
  if ((istop_ < 1 ).or.(istop_ > 2 ) ) then
    write(0,*) 'psb_cgs: invalid istop',istop_ 
    info=5001
    int_err=istop_
    err=info
    call psb_errpush(info,name,i_err=int_err)
    goto 9999
  endif

  naux=4*n_col 
  Allocate(aux(naux),stat=info)

  Call psb_geall(mglob,11,wwrk,desc_a,info)
  Call psb_geasb(wwrk,desc_a,info)  
  if (info.ne.0) Then 
     info=4011 
     call psb_errpush(info,name)
     goto 9999
  End If

  q  => wwrk(:,1)
  qt => wwrk(:,2)
  r  => wwrk(:,3)
  rt => wwrk(:,4)
  p  => wwrk(:,5)
  v  => wwrk(:,6)
  uv => wwrk(:,7)
  z  => wwrk(:,8)
  f  => wwrk(:,9)
  s  => wwrk(:,10)
  ww => wwrk(:,11)


  If (Present(itmax)) Then 
    litmax = itmax
  Else
    litmax = 1000
  Endif

  If (Present(itrace)) Then
     itrac = itrace
  Else
     itrac = -1
  End If

  ! ensure global coherence for convergence checks.
  Call blacs_get(icontxt,16,isvch)
  ich = 1 
  Call blacs_set(icontxt,16,ich)
  
  diagl  = 'u'
  diagu  = 'u'
  itx   = 0

  if (istop_ == 1) then 
    ani = psb_spnrmi(a,desc_a,info)
    bni = psb_geamax(b,desc_a,info)
  else if (istop_ == 2) then 
    bn2 = psb_genrm2(b,desc_a,info)
  endif
  if(info/=0)then
     info=4011
     call psb_errpush(info,name)
     goto 9999
  end if

  restart: Do 
!!$
!!$   r0 = b-ax0
!!$ 
    If (itx.Ge.litmax) Exit restart  
    it = 0      
    Call psb_geaxpby(zone,b,zzero,r,desc_a,info)
    Call psb_spmm(-zone,a,x,zone,r,desc_a,info,work=aux)
    Call psb_geaxpby(zone,r,zzero,rt,desc_a,info)
    if(info/=0)then
       info=4011
       call psb_errpush(info,name)
       goto 9999
    end if
    
    rho = zzero
    If (debug) Write(*,*) 'on entry to amax: b: ',Size(b)

    if (istop_ == 1) then 
      rni = psb_geamax(r,desc_a,info)
      xni = psb_geamax(x,desc_a,info)
      rerr =  rni/(ani*xni+bni)
      if (itrac /= -1) then 
        If (me == 0) Write(itrac,'(a,i4,5(2x,es10.4))') 'cgs: ',&
             & itx,rerr,rni,bni,xni,ani
      endif
    else if (istop_ == 2) then 
      rni = psb_genrm2(r,desc_a,info)
      rerr = rni/bn2
      if (itrac /= -1) then 
        If (me == 0) Write(itrac,'(a,i4,3(2x,es10.4))') 'cgs: ',itx,rerr,rni,bn2
      endif
    endif
    if(info/=0)then
       info=4011
       call psb_errpush(info,name)
       goto 9999
    end if
    
    If (rerr<=eps) Then 
      Exit restart
    End If

    iteration:  Do 
      it   = it + 1
      itx = itx + 1
      If (debug) Write(*,*) 'iteration: ',itx
      rho_old = rho    
      rho = psb_gedot(rt,r,desc_a,info)
      If (rho==zzero) Then
         If (debug) Write(0,*) 'cgs iteration breakdown r',rho
        Exit iteration
      Endif

      If (it==1) Then
        Call psb_geaxpby(zone,r,zzero,uv,desc_a,info)
        Call psb_geaxpby(zone,r,zzero,p,desc_a,info)
      Else
        beta = (rho/rho_old)
        Call psb_geaxpby(zone,r,zzero,uv,desc_a,info)
        Call psb_geaxpby(beta,q,zone,uv,desc_a,info)
        Call psb_geaxpby(zone,q,beta,p,desc_a,info)
        Call psb_geaxpby(zone,uv,beta,p,desc_a,info)

      End If

      Call psb_prc_aply(prec,p,f,desc_a,info,work=aux)

      Call psb_spmm(zone,a,f,zzero,v,desc_a,info,&
           & work=aux)

      sigma = psb_gedot(rt,v,desc_a,info)
      If (sigma==zzero) Then
         If (debug) Write(0,*) 'cgs iteration breakdown s1', sigma
         Exit iteration
      Endif
      
      alpha = rho/sigma

      Call psb_geaxpby(zone,uv,zzero,q,desc_a,info)
      Call psb_geaxpby(-alpha,v,zone,q,desc_a,info)
      Call psb_geaxpby(zone,uv,zzero,s,desc_a,info)
      Call psb_geaxpby(zone,q,zone,s,desc_a,info)
      
      Call psb_prc_aply(prec,s,z,desc_a,info,work=aux)

      Call psb_geaxpby(alpha,z,zone,x,desc_a,info)

      Call psb_spmm(zone,a,z,zzero,qt,desc_a,info,&
           & work=aux)
      
      Call psb_geaxpby(-alpha,qt,zone,r,desc_a,info)
      
     
      if (istop_ == 1) then 
        rni = psb_geamax(r,desc_a,info)
        xni = psb_geamax(x,desc_a,info)
        rerr =  rni/(ani*xni+bni)
        if (itrac /= -1) then 
        If (me == 0) Write(itrac,'(a,i4,5(2x,es10.4))') 'cgs: ',&
             & itx,rerr,rni,bni,xni,ani
        endif

      else  if (istop_ == 2) then 

        rni = psb_genrm2(r,desc_a,info)
        rerr = rni/bn2
        if (itrac /= -1) then 
        If (me == 0) Write(itrac,'(a,i4,3(2x,es10.4))') 'cgs: ',&
             & itx,rerr,rni,bn2
        endif
      endif

      If (rerr<=eps) Then 
        Exit restart
      End If
      If (itx.Ge.litmax) Exit restart
    End Do iteration
  End Do restart

  If (Present(err)) err=rerr
  If (Present(iter)) iter = itx
  If (rerr>eps) Then
    Write(0,*) 'cgs failed to converge to ',eps,&
         & ' in ',itx,' iterations  '
  End If

  Deallocate(aux)
  Call psb_gefree(wwrk,desc_a,info)
  ! restore external global coherence behaviour
  Call blacs_set(icontxt,16,isvch)

  if(info/=0) then
     call psb_errpush(info,name)
     goto 9999
  end if

  call psb_erractionrestore(err_act)
  return

9999 continue
  call psb_erractionrestore(err_act)
  if (err_act.eq.act_abort) then
     call psb_error()
     return
  end if
  return

End Subroutine psb_zcgs


