module wrf_params_mod
    public  update_pint, preserve_restart_date, cold_start
    logical update_pint            !  if true, then this is nmm run with pint variable, so update pint
                                   !    (where pint is non-hydrostatic 3-d pressure variable)
    logical preserve_restart_date  !  if true, then do not update date information on restart file
    logical cold_start             !  if true, then restart file is from GFS
  contains
    subroutine init(update,restart_date,coldstart)      
       update_pint = update
       preserve_restart_date = restart_date
       cold_start = coldstart
    end subroutine init
end module wrf_params_mod
