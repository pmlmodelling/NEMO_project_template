MODULE sbcrnf_ebm
   !!======================================================================
   !!                       ***  MODULE  sbcrnf_ebm  ***
   !! Ocean forcing:  estuary box model river runoff
   !!=====================================================================
   !! History :
   !!   NEMO     4.0  ! 2026    (D. Partridge, M. Wathen)
   !!----------------------------------------------------------------------

   !!----------------------------------------------------------------------
   !!   sbc_rnfebm       : monthly runoffs calculated from EBM
   !!   sbc_rnfebm_init  : EBM runoffs initialisation
   !!----------------------------------------------------------------------
   USE oce            ! ocean dynamics and tracers
   USE dom_oce        ! ocean space and time domain
   USE par_kind, ONLY: wp
   USE sbc_oce        ! surface boundary condition variables
   USE sbcrnf         ! River runoff
   !
   USE in_out_manager ! I/O manager
   USE fldread        ! read input field at current time step
   USE iom            ! I/O module
   USE lib_mpp        ! MPP library

   USE estuary_box_physics, ONLY: Estuary_box_model  ! Estuary Box Model physics

   IMPLICIT NONE
   PRIVATE

   PUBLIC   sbc_rnfebm       ! called in sbcmod module
   PUBLIC   sbc_rnfebm_init  ! called in sbcmod module

   INTEGER , PARAMETER ::  jpfld = 5            ! Number of EBM parameters
   INTEGER , PARAMETER ::  jp_msk = 1           ! index of msk parameter
   INTEGER , PARAMETER ::  jp_L = 2           ! index of L parameter
   INTEGER , PARAMETER ::  jp_W = 3           ! index of W parameter
   INTEGER , PARAMETER ::  jp_H = 4           ! index of H parameter
   INTEGER , PARAMETER ::  jp_uH = 5           ! index of uH parameter
   TYPE(FLD), ALLOCATABLE, DIMENSION(:) ::   sf_ebm       ! structure: EBM data
   TYPE(FLD_N), DIMENSION(jpfld) ::   sn_ebm         ! array of namelist information on files to be read

   CHARACTER(len=100)         ::   cn_dir            !: Root directory for location of ebm files
   TYPE(FLD_N)                ::   sn_ebm_msk            !: information about the mask for EBM locations to be read
   TYPE(FLD_N)                ::   sn_ebm_L          !: information about the EBM estuary lengths to be read
   TYPE(FLD_N)                ::   sn_ebm_W          !: information about the EBM estuary widths to be read
   TYPE(FLD_N)                ::   sn_ebm_H          !: information about the EBM estuary heights to be read
   TYPE(FLD_N)                ::   sn_ebm_uH          !: information about the EBM estuary upper layer heights to be read

   REAL(wp), ALLOCATABLE, DIMENSION(:,:) :: ebm_H_ocean, ebm_H_chan, ebm_L_chan, ebm_W_mouth, ebm_V_est
   REAL(wp), ALLOCATABLE, DIMENSION(:,:) :: ebm_u_tide, ebm_L_tide, ebm_Q_river, ebm_S_ocean, ebm_T_ocean, ebm_a0
   LOGICAL , ALLOCATABLE, DIMENSION(:,:) :: ebm_wide_mouth, ebm_river_mask

   REAL(wp), ALLOCATABLE, DIMENSION(:,:) :: ebm_Q_UM, ebm_Q_LM, ebm_S_UM, ebm_const, ebm_rho_UM

   ! Persistent EBM instance used across time steps
   TYPE(Estuary_box_model), SAVE :: ebm
   LOGICAL,                SAVE :: ll_ebm_ready = .FALSE.

CONTAINS

   INTEGER FUNCTION sbc_rnfebm_alloc()
      !!----------------------------------------------------------------------
      !!                ***  ROUTINE sbc_rnf_alloc  ***
      !!----------------------------------------------------------------------
      ALLOCATE( &
         & ebm_H_ocean(jpi,jpj), ebm_H_chan(jpi,jpj), ebm_L_chan(jpi,jpj), ebm_W_mouth(jpi,jpj), ebm_V_est(jpi,jpj), &
         & ebm_u_tide(jpi,jpj), ebm_L_tide(jpi,jpj), ebm_Q_river(jpi,jpj), ebm_S_ocean(jpi,jpj), &
         & ebm_T_ocean(jpi,jpj), ebm_a0(jpi,jpj), &
         & ebm_wide_mouth(jpi,jpj), ebm_river_mask(jpi,jpj), &
         & ebm_Q_UM(jpi,jpj), ebm_Q_LM(jpi,jpj), ebm_S_UM(jpi,jpj), ebm_const(jpi,jpj), ebm_rho_UM(jpi,jpj), &
         & STAT=sbc_rnfebm_alloc )
         !
      CALL mpp_sum ( 'sbcrnf_ebm', sbc_rnfebm_alloc )
      IF( sbc_rnfebm_alloc > 0 )   CALL ctl_warn('sbc_rnfebm_alloc: allocation of arrays failed')
   END FUNCTION sbc_rnfebm_alloc



   SUBROUTINE sbc_rnfebm( kt )
      !!----------------------------------------------------------------------
      !!                  ***  ROUTINE sbc_rnfebm  ***
      !!
      !! ** Purpose :   Update river runoff using estuary box model
      !!
      !! ** Method  :   Take river runoff values and use EBM from XXXX
      !!
      !! ** Action  :   runoff/salinity updated fields at time-step kt
      !!----------------------------------------------------------------------
      INTEGER, INTENT(in) ::   kt          ! ocean time step
      !

      !!----------------------------------------------------------------------
      !
      CALL fld_read ( kt, nn_fsbc, sf_ebm )

      ! Initialise ocean side variables

      ebm_L_chan(:,:)  = sf_ebm(jp_L )%fnow(:,:,1)
      ebm_W_mouth(:,:) = sf_ebm(jp_W )%fnow(:,:,1)
      ebm_H_ocean(:,:) = sf_ebm(jp_H )%fnow(:,:,1)
      ebm_H_chan(:,:)  = sf_ebm(jp_uH)%fnow(:,:,1)

      ebm_V_est(:,:)   = ebm_L_chan(:,:) * ebm_W_mouth(:,:) * ebm_H_ocean(:,:)

      ! Ocean-side T/S at the mouth: use deepest model level as a pragmatic default
      ebm_S_ocean(:,:) = tsn(:,:,jpk,jp_sal)
      ebm_T_ocean(:,:) = tsn(:,:,jpk,jp_tem)

      ! Approximate tidal velocity amplitude from instantaneous near-surface currents
      ebm_u_tide(:,:)  = SQRT( un(:,:,1)**2 + vn(:,:,1)**2 )
      ebm_L_tide(:,:)  = 0._wp

      ! Convert runoff to discharge (m3/s). Guard against negative/outflow values.
      ebm_Q_river(:,:) = MAX( 0._wp, rnf(:,:) * e1t(:,:) * e2t(:,:) )

      ! Empirical a0 field: set to 0 to trigger model-default a_0 inside EBM
      ebm_a0(:,:) = 0._wp

      ! Wide-mouth flag currently disabled
      ebm_wide_mouth(:,:) = .FALSE.

      ! Authoritative mask: only compute where the external mask is active and runoff is positive
      ebm_river_mask(:,:) = ( sf_ebm(jp_msk)%fnow(:,:,1) == 1._wp ) .AND. ( ebm_Q_river(:,:) > 0._wp )

      IF( .NOT. ll_ebm_ready ) THEN
         CALL ebm%init()
         ll_ebm_ready = .TRUE.
      ENDIF

      CALL ebm%load_estuary( ebm_H_ocean, ebm_H_chan, ebm_L_chan, ebm_W_mouth, ebm_V_est, &
         &                 ebm_u_tide, ebm_L_tide, ebm_Q_river, ebm_S_ocean, ebm_T_ocean, ebm_a0, &
         &                 ebm_wide_mouth, ebm_river_mask )

      CALL ebm%evaluate_box_model( Q_UM_out=ebm_Q_UM, Q_LM_out=ebm_Q_LM, S_UM_out=ebm_S_UM, &
         &                        const_out=ebm_const, rho_UM_out=ebm_rho_UM )

      ! Diagnostics (optional, if configured in IOM)
      CALL iom_put( 'ebm_msk',    sf_ebm(jp_msk)%fnow(:,:,1) )
      CALL iom_put( 'ebm_Q_UM',   ebm_Q_UM   )
      CALL iom_put( 'ebm_Q_LM',   ebm_Q_LM   )
      CALL iom_put( 'ebm_S_UM',   ebm_S_UM   )
      CALL iom_put( 'ebm_const',  ebm_const  )
      CALL iom_put( 'ebm_rho_UM', ebm_rho_UM )

   END SUBROUTINE sbc_rnfebm

   SUBROUTINE sbc_rnfebm_init
      !!----------------------------------------------------------------------
      !!                  ***  ROUTINE sbc_rnfebm_init  ***
      !!
      !! ** Purpose :   Initialisation of the EBMs if (ln_rnfebm=T)
      !!
      !! ** Method  : - read the runoff namsbc_rnfebm namelist
      !!
      !! ** Action  : - read parameters
      !!----------------------------------------------------------------------
      INTEGER           ::   jp    ! dummy loop indices
      INTEGER           ::   ierror  ! temporary integer
      INTEGER           ::   ios           ! Local integer output status for namelist read

      !!
      NAMELIST/namsbc_rnfebm/ cn_dir,  &
         &                 sn_ebm_msk, sn_ebm_L, sn_ebm_W, sn_ebm_H, sn_ebm_uH

      !!----------------------------------------------------------------------
      !
      !                                         !==  allocate runoff arrays
      IF( sbc_rnfebm_alloc() /= 0 )   CALL ctl_stop( 'STOP', 'sbc_rnfebm_alloc : unable to allocate arrays' )
      !
      !                                   ! ============
      !                                   !   Namelist
      !                                   ! ============
      !
      REWIND( numnam_ref )
      READ  ( numnam_ref, namsbc_rnfebm, IOSTAT = ios, ERR = 901)
901   IF( ios /= 0 )   CALL ctl_nam ( ios , 'namsbc_rnfebm in reference namelist' )

      REWIND( numnam_cfg )
      READ  ( numnam_cfg, namsbc_rnfebm, IOSTAT = ios, ERR = 902 )
902   IF( ios >  0 )   CALL ctl_nam ( ios , 'namsbc_rnfebm in configuration namelist' )
      IF(lwm) WRITE ( numond, namsbc_rnfebm )
      !
      !                                         ! Control print
      !IF(lwp) THEN
      !   WRITE(numout,*)
      !   WRITE(numout,*) 'sbc_rnfebm_init : EBMs '
      !   WRITE(numout,*) '~~~~~~~~~~~~ '
      !   WRITE(numout,*) '   Namelist namsbc_rnfebm'
      !ENDIF

      ! Create array of namelist information for EBM parameters
      sn_ebm(jp_msk) = sn_ebm_msk
      sn_ebm(jp_L) = sn_ebm_L
      sn_ebm(jp_W) = sn_ebm_W
      sn_ebm(jp_H) = sn_ebm_H
      sn_ebm(jp_uH) = sn_ebm_uH

      ! Create structure for EBM parameter data
      ALLOCATE( sf_ebm(jpfld), STAT=ierror )         ! Create sf_rnf structure (runoff inflow)
      IF(lwp) WRITE(numout,*)
      IF(lwp) WRITE(numout,*) '   ==>>>   Read EBM information from file'
      IF( ierror > 0 ) THEN
         CALL ctl_stop( 'sbc_rnfebm_init: unable to allocate sf_ebm structure' )   ;   RETURN
      ENDIF
      CALL fld_fill( sf_ebm, sn_ebm, cn_dir, 'sbc_rnfebm_init','River runoff - EBM parameters','namsbc_rnfebm')
      DO jp = 1, jpfld
              ALLOCATE( sf_ebm(jp)%fnow(jpi,jpj,1)   )
              IF( sn_ebm(jp)%ln_tint ) ALLOCATE( sf_ebm(jp)%fdta(jpi,jpj,1,2) )
      ENDDO

   END SUBROUTINE sbc_rnfebm_init

   !!======================================================================
END MODULE sbcrnf_ebm
