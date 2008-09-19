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
!
! package: psb_hash_mod
! 
!   This module implements a very simple minded hash table.
!   The hash is based on the idea of open addressing with double hashing;
!   the primary hash function h1(K) is simply the remainder modulo 2^N, while
!   the secondary hash function is 1 if H1(k) == 0, otherwise IOR((2^N-H1(k)),1)
!   (See Knuth: TAOCP, Vol. 3, sec. 6.4)
!   These hash functions are not very smart; however they are very simple and fast.
!   The intended usage of this hash table is to store indices of halo points, which
!   are supposed to be few compared to the internal indices
!   (which are stored elsewhere), so in this context they are acceptable.
!
!
!
module psb_hash_mod
  use psb_const_mod
  
  !
  ! For us a hash is a Nx2 table.
  ! Note: we are assuming that the keys are positive numbers.
  ! Allocatable scalars would be a nice solution...
  !
  type psb_hash_type
    integer :: nbits, hsize, hmask, nk
    integer, allocatable :: table(:,:)
    integer(psb_long_int_k_) :: nsrch, nacc
  end type psb_hash_type


  integer, parameter  :: HashDuplicate = 123, HashOK=0, HashOutOfMemory=-512,&
       & HashFreeEntry = -1, HashNotFound = -256

  interface psb_hash_init
    module procedure psb_hash_init_v, psb_hash_init_n
  end interface
  interface psb_sizeof
    module procedure psb_sizeof_hash_type
  end interface

contains

  
  function hashval(key) result(val)
    integer, intent(in)  :: key
    integer, parameter :: ival=5381, mask=2147483647
    integer :: key_, val, i

    key_ = key
    val  = ival 
    do i=1, 4
      val  = val * 33 + iand(key_,255)
      key_ = ishft(key_,-8)
    end do
    
    val = val + ishft(val,-5)
    val = iand(val,mask)
    
  end function hashval

  
  function psb_Sizeof_hash_type(hash) result(val)
    type(psb_hash_type), pointer :: hash
    integer(psb_long_int_k_) :: val
    val = 0
    if (associated(hash)) then 
      val = val + psb_sizeof_int * size(hash%table)
    end if
  end function psb_Sizeof_hash_type

  
  function psb_hash_avg_acc(hash)
    type(psb_hash_type), intent(in) :: hash
    real(psb_dpk_) :: psb_hash_avg_acc
    
    psb_hash_avg_acc = dble(hash%nacc)/dble(hash%nsrch)
  end function psb_hash_avg_acc

  subroutine HashTransfer(hashin,hashout,info)
    use psb_realloc_mod
    type(psb_hash_type) :: hashin
    type(psb_hash_type) :: hashout
    integer, intent(out)  :: info 

    info = HashOk
    hashout%nbits = hashin%nbits
    hashout%hsize = hashin%hsize
    hashout%hmask = hashin%hmask
    hashout%nk    = hashin%nk
    hashout%nsrch = hashin%nsrch
    hashout%nacc  = hashin%nacc
    call psb_transfer(hashin%table, hashout%table,info)

  end subroutine HashTransfer

  subroutine HashCopy(hashin,hashout,info)
    use psb_realloc_mod
    type(psb_hash_type) :: hashin
    type(psb_hash_type) :: hashout
    integer, intent(out)  :: info 

    info = HashOk
    hashout%nbits = hashin%nbits
    hashout%hsize = hashin%hsize
    hashout%hmask = hashin%hmask
    hashout%nk    = hashin%nk
    hashout%nsrch = hashin%nsrch
    hashout%nacc  = hashin%nacc
    call psb_safe_ab_cpy(hashin%table, hashout%table,info)

  end subroutine HashCopy

  subroutine CloneHashTable(hashin,hashout,info)
    type(psb_hash_type), pointer :: hashin
    type(psb_hash_type), pointer :: hashout
    integer, intent(out)  :: info 
    
    if (associated(hashout)) then 
      deallocate(hashout,stat=info)
      !if (info /= 0) return
    end if
    if (associated(hashin)) then
      allocate(hashout,stat=info)
      if (info /= 0) return
      call HashCopy(hashin,hashout,info)
    end if

  end subroutine CloneHashTable

  subroutine psb_hash_init_V(v,hash,info)
    integer, intent(in)     :: v(:)
    type(psb_hash_type), intent(out) :: hash
    integer, intent(out)    :: info 

    integer :: i,j,k,hsize,nbits, nv

    info  = 0
    nv    = size(v)
    call psb_hash_init(nv,hash,info) 
    if (info /= 0) return
    do i=1,nv 
      call psb_hash_searchinskey(v(i),j,i,hash,info) 
      if ((j /= i).or.(info /= HashOK)) then 
        write(0,*) 'Error from hash_ins',i,v(i),j,info
        info = HashNotFound
        return
      end if
    end do
  end subroutine psb_hash_init_V

  subroutine psb_hash_init_n(nv,hash,info)
    integer, intent(in)     :: nv
    type(psb_hash_type), intent(out) :: hash
    integer, intent(out)    :: info 

    integer :: i,j,k,hsize,nbits

    info  = 0
    nbits = 12
    hsize = 2**nbits
    !
    ! Figure out the smallest power of 2 bigger than NV
    !
    do 
      if (hsize < 0) then 
        write(0,*) 'Error: hash size overflow ',hsize,nbits
        info = -2 
        return
      end if
      if (hsize > nv) exit
      nbits = nbits + 1
      hsize = hsize * 2 
    end do

    hash%nbits = nbits
    hash%hsize = hsize
    hash%hmask = hsize-1
    hash%nsrch = 0
    hash%nacc  = 0 
    allocate(hash%table(0:hsize-1,2),stat=info) 
    if (info /= 0) then
      write(0,*) 'Error: memory allocation failure  ',hsize
      info = HashOutOfMemory
      return
    end if
    hash%table = HashFreeEntry
    hash%nk    = 0
  end subroutine psb_hash_init_n


  subroutine psb_hash_realloc(hash,info)
    type(psb_hash_type), intent(inout) :: hash
    integer, intent(out)   :: info 
    type(psb_hash_type)    :: nhash
    integer :: nk, key, val, nextval,i

    info = HashOk
    
    call psb_hash_init((hash%hsize+1),nhash,info)
    
    if (info /= HashOk) then 
      info = HashOutOfMemory
      return
    endif
    do i=0, hash%hsize-1
      key     = hash%table(i,1)
      nextval = hash%table(i,2)
      if (key /= HashFreeEntry) then 
        call psb_hash_searchinskey(key,val,nextval,nhash,info)        
        if (info /= 0) then 
          info = HashOutOfMemory
          return
        end if
      end if
    end do
    call HashTransfer(nhash,hash,info)
  end subroutine psb_hash_realloc
    
  recursive subroutine psb_hash_searchinskey(key,val,nextval,hash,info)
    integer, intent(in)   :: key,nextval
    type(psb_hash_type)   :: hash
    integer, intent(out)  :: val, info 

    integer :: i,j,k,hsize,hmask, hk, hd

    info  = HashOK
    hsize = hash%hsize
    hmask = hash%hmask

    hk = iand(hashval(key),hmask)
    if (hk == 0) then 
      hd = 1
    else 
      hd = hsize - hk 
      hd = ior(hd,1)
    end if

    hash%nsrch = hash%nsrch + 1
    do 
      hash%nacc = hash%nacc + 1
      if (hash%table(hk,1) == key) then 
        val  = hash%table(hk,2)
        info = HashDuplicate
        return
      end if
      if (hash%table(hk,1) == HashFreeEntry) then 
        if (hash%nk == hash%hsize -1) then
          !
          ! Note: because of the way we allocate things at CDALL
          ! time this is really unlikely; if we get here, we
          ! have at least as many halo indices as internals, which
          ! means we're already in trouble. But we try to keep going. 
          !
          call psb_hash_realloc(hash,info) 
          if (info /=  HashOk) then             
            info = HashOutOfMemory
            return
          else
            call psb_hash_searchinskey(key,val,nextval,hash,info)
            return
          end if
        else
          hash%nk = hash%nk + 1 
          hash%table(hk,1) = key
          hash%table(hk,2) = nextval
          val              = nextval
          return
        end if
      end if
      hk = hk - hd 
      if (hk < 0) hk = hk + hsize
    end do
  end subroutine psb_hash_searchinskey

  subroutine psb_hash_searchkey(key,val,hash,info)
    integer, intent(in)   :: key
    type(psb_hash_type)   :: hash
    integer, intent(out)  :: val, info 

    integer :: i,j,k,hsize,hmask, hk, hd

    info  = HashOK
    hsize = hash%hsize
    hmask = hash%hmask
    hk = iand(hashval(key),hmask)
    if (hk == 0) then 
      hd = 1
    else 
      hd = hsize - hk 
      hd = ior(hd,1)
    end if
    
    hash%nsrch = hash%nsrch + 1
    do 
      hash%nacc = hash%nacc + 1
      if (hash%table(hk,1) == key) then 
        val  = hash%table(hk,2)
        return
      end if
      if (hash%table(hk,1) == HashFreeEntry) then 
        val  = HashFreeEntry
!!$        info = HashNotFound
        return
      end if
      hk = hk - hd 
      if (hk < 0) hk = hk + hsize
    end do
  end subroutine psb_hash_searchkey

end module psb_hash_mod