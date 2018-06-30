module psb_dprec_cbind_mod

  use iso_c_binding
  use psb_prec_mod, only : psb_dprec_type
  use psb_objhandle_mod
  use psb_base_string_cbind_mod

  type, bind(c) :: psb_c_dprec
    type(c_ptr) :: item = c_null_ptr
  end type psb_c_dprec
  
  
contains 


  function  psb_c_dprecinit(ph,ptype) bind(c) result(res)
    use psb_base_mod
    use psb_prec_mod
    use psb_base_string_cbind_mod
    implicit none 
    integer(psb_c_ipk)          :: res
    type(psb_c_dprec) :: ph
    character(c_char)       :: ptype(*)
    type(psb_dprec_type), pointer :: precp
    integer(psb_c_ipk)              :: info
    character(len=80)       :: fptype

    res = -1
    if (c_associated(ph%item)) then 
      return 
    end if

    allocate(precp,stat=info)
    if (info /= 0) return
    ph%item = c_loc(precp)

    call stringc2f(ptype,fptype)
    
    call psb_precinit(precp,fptype,info) 
    
    res = min(0,info)
    return
  end function psb_c_dprecinit
    


  function  psb_c_dprecbld(ah,cdh,ph) bind(c) result(res)
    use psb_base_mod
    use psb_prec_mod
    use psb_objhandle_mod
    use psb_base_string_cbind_mod
    implicit none 
    
    integer(psb_c_ipk) :: res
    type(psb_c_dspmat) :: ah
    type(psb_c_dprec) :: ph
    type(psb_c_descriptor) :: cdh

    type(psb_desc_type), pointer :: descp
    type(psb_dspmat_type), pointer :: ap
    type(psb_dprec_type), pointer :: precp
    integer(psb_c_ipk)              :: info

    res = -1
!!$    write(*,*) 'Entry:   ', psb_c_cd_get_local_rows(cdh)
    if (c_associated(cdh%item)) then 
      call c_f_pointer(cdh%item,descp)
    else
      return 
    end if
    if (c_associated(ah%item)) then 
      call c_f_pointer(ah%item,ap)
    else
      return 
    end if
    if (c_associated(ph%item)) then 
      call c_f_pointer(ph%item,precp)
    else
      return 
    end if

    call psb_precbld(ap,descp, precp, info)

    res = min(info,0)
    
  end function psb_c_dprecbld


  function  psb_c_dprecfree(ph) bind(c) result(res)
    use psb_base_mod
    use psb_prec_mod
    use psb_objhandle_mod
    use psb_base_string_cbind_mod
    implicit none 
    
    integer(psb_c_ipk) :: res
    type(psb_c_dprec) :: ph
    type(psb_dprec_type), pointer :: precp
    integer(psb_c_ipk)              :: info

    res = -1
    if (c_associated(ph%item)) then 
      call c_f_pointer(ph%item,precp)
    else
      return 
    end if
    
    call psb_precfree(precp, info)

    res = min(info,0)
    
  end function psb_c_dprecfree


end module psb_dprec_cbind_mod
