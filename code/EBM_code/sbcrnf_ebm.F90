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

   INTEGER , PARAMETER ::  jpfld = 8            ! Number of EBM parameters
   INTEGER , PARAMETER ::  jp_msk = 1           ! index of msk parameter
   INTEGER , PARAMETER ::  jp_W = 2           ! index of W parameter
   INTEGER , PARAMETER ::  jp_H = 3           ! index of H parameter
   INTEGER , PARAMETER ::  jp_uH = 4           ! index of uH parameter
   INTEGER, PARAMETER :: jp_angle = 5
   INTEGER, PARAMETER :: jp_a0 = 6
   INTEGER, PARAMETER :: jp_a1 = 7
   INTEGER, PARAMETER :: jp_WM_flag = 8
   TYPE(FLD), ALLOCATABLE, DIMENSION(:) ::   sf_ebm       ! structure: EBM data
   TYPE(FLD_N), DIMENSION(jpfld) ::   sn_ebm         ! array of namelist information on files to be read

   CHARACTER(len=100)         ::   cn_dir            !: Root directory for location of ebm files
   TYPE(FLD_N)                ::   sn_ebm_msk            !: information about the mask for EBM locations to be read
   TYPE(FLD_N)                ::   sn_ebm_W          !: information about the EBM estuary widths to be read
   TYPE(FLD_N)                ::   sn_ebm_H          !: information about the EBM estuary heights to be read
   TYPE(FLD_N)                ::   sn_ebm_uH          !: information about the EBM estuary upper layer heights to be read
   TYPE(FLD_N) :: sn_ebm_angle
   TYPE(FLD_N) :: sn_ebm_a0
   TYPE(FLD_N) :: sn_ebm_a1
   TYPE(FLD_N) :: sn_ebm_WM_flag

   REAL(wp), ALLOCATABLE, DIMENSION(:,:) :: ebm_H_ocean, ebm_H_chan, ebm_L_chan, ebm_W_mouth, ebm_V_est
   REAL(wp), ALLOCATABLE, DIMENSION(:,:) :: ebm_u_tide, ebm_L_tide, ebm_Q_river, ebm_S_ocean, ebm_T_ocean, ebm_a0, ebm_a1
   REAL(wp), ALLOCATABLE, DIMENSION(:,:) :: ebm_angle
   INTEGER , ALLOCATABLE, DIMENSION(:,:) :: ebm_wide_mouth, ebm_river_mask

   REAL(wp), ALLOCATABLE, DIMENSION(:,:) :: ebm_Q_UM, ebm_Q_LM, ebm_S_UM, ebm_const, ebm_rho_UM, ebm_S_diff

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
           & ebm_T_ocean(jpi,jpj), ebm_a0(jpi,jpj), ebm_a1(jpi,jpj), ebm_angle(jpi,jpj), &
           & ebm_wide_mouth(jpi,jpj), ebm_river_mask(jpi,jpj), &
           & ebm_Q_UM(jpi,jpj), ebm_Q_LM(jpi,jpj), ebm_S_UM(jpi,jpj), ebm_const(jpi,jpj), ebm_rho_UM(jpi,jpj), ebm_S_diff(jpi,jpj), &
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
      INTEGER :: ji, jj, jk
      INTEGER :: k_chan, k_bot
      REAL(wp) :: wsum, ssum, tsum, hsum
      real(wp) :: theta_deg, theta_rad
      real(wp) :: dirx, diry
      real(wp) :: uT, vT, opp_comp
      real(wp) :: dz_use, remaining_h
      real(wp) :: opp_int, thick_sum
      real(wp) :: depth_total, h_middle
      real(wp), parameter :: deg2rad = acos(-1.0_wp) / 180.0_wp

      !!----------------------------------------------------------------------
      !

      ! Initialise ocean side variables

      ebm_L_chan(:,:)  = 0._wp
      ebm_W_mouth(:,:) = sf_ebm(jp_W )%fnow(:,:,1)
      ebm_H_ocean(:,:) = sf_ebm(jp_H )%fnow(:,:,1)
      ebm_H_chan(:,:)  = sf_ebm(jp_uH)%fnow(:,:,1)
      ebm_angle(:,:)   = sf_ebm(jp_angle)%fnow(:,:,1)
      ebm_a0(:,:)      = sf_ebm(jp_a0)%fnow(:,:,1)
      ebm_a1(:,:)      = sf_ebm(jp_a1)%fnow(:,:,1)
      ebm_S_diff(:,:) = 0._wp

      ebm_V_est(:,:)   = ebm_L_chan(:,:) * ebm_W_mouth(:,:) * ebm_H_ocean(:,:)

      DO jj = 1, jpj
         DO ji = 1, jpi

            ! Skip expensive vertical averaging where EBM is inactive
            IF ( sf_ebm(jp_msk)%fnow(ji,jj,1) < 0.5_wp ) THEN
               ebm_S_ocean(ji,jj) = 0._wp
               ebm_T_ocean(ji,jj) = 0._wp
               CYCLE
            END IF
            k_bot = mbkt(ji,jj)
            IF ( k_bot < 1 ) THEN
               ebm_S_ocean(ji,jj) = 0._wp
               ebm_T_ocean(ji,jj) = 0._wp
               CYCLE
            END IF

            ! Find first T-level deeper than ebm_H_chan; if none, fall back to bottom level
            k_chan = k_bot
            DO jk = 1, k_bot
               IF ( gdept_0(ji,jj,jk) >= ebm_H_chan(ji,jj) ) THEN
                  k_chan = jk
                  EXIT
               END IF
            END DO

            wsum = 0._wp
            ssum = 0._wp
            tsum = 0._wp

            DO jk = k_chan, k_bot
               IF ( tmask(ji,jj,jk) == 1._wp ) THEN
                  wsum = wsum + e3t_n(ji,jj,jk)
                  ssum = ssum + tsn(ji,jj,jk,jp_sal) * e3t_n(ji,jj,jk)
                  tsum = tsum + tsn(ji,jj,jk,jp_tem) * e3t_n(ji,jj,jk)
               END IF
            END DO

            IF ( wsum > 0._wp ) THEN
               ebm_S_ocean(ji,jj) = ssum / wsum
               ebm_T_ocean(ji,jj) = tsum / wsum
            ELSE
               ebm_S_ocean(ji,jj) = tsn(ji,jj,k_bot,jp_sal)
               ebm_T_ocean(ji,jj) = tsn(ji,jj,k_bot,jp_tem)
            END IF

            ! Set depth to spread the river input over based on EBM parameters
            hsum = 0._wp
            DO jk = 1, k_chan
                hsum = hsum + e3t_n(ji,jj,jk)
            END DO
            nk_rnf(ji,jj) = k_chan
            h_rnf(ji,jj) = hsum
         END DO
      END DO

      ! Approximate tidal velocity amplitude from instantaneous near-surface currents
      !ebm_u_tide(:,:)  = SQRT( un(:,:,1)**2 + vn(:,:,1)**2 )
      ebm_u_tide(:,:) = 0._wp

      DO jj = 2, jpj-1
         DO ji = 2, jpi-1

            IF ( sf_ebm(jp_msk)%fnow(ji,jj,1) < 0.5_wp ) CYCLE
 
            k_bot = mbkt(ji,jj)
            IF ( k_bot < 1 ) CYCLE

            IF ( ebm_H_chan(ji,jj) <= 0._wp ) CYCLE

            theta_rad = ebm_angle(ji,jj) * deg2rad
            dirx      = COS(theta_rad)
            diry      = SIN(theta_rad)

            ! Local total wet-column thickness from the model
            depth_total = 0._wp
            DO jk = 1, k_bot
               IF ( tmask(ji,jj,jk) == 1._wp ) THEN
                  depth_total = depth_total + e3t_n(ji,jj,jk)
               END IF
            END DO

            ! Scale the param-file h/H ratio onto the local model depth
            h_middle = depth_total * ebm_H_chan(ji,jj) / ebm_H_ocean(ji,jj)

            opp_int     = 0._wp
            thick_sum   = 0._wp
            remaining_h = h_middle

            ! Integrate upward from the bottom over the lower h_middle thickness
            DO jk = k_bot, 1, -1

               IF ( remaining_h <= 0._wp ) EXIT
               IF ( tmask(ji,jj,jk) /= 1._wp ) CYCLE

               ! Amount of this level included in the bottom-h_middle interval
               dz_use = MIN( e3t_n(ji,jj,jk), remaining_h )

               ! T-point velocity from neighbouring U and V values at this level
               uT = 0.5_wp * ( un(ji  ,jj,jk) + un(ji-1,jj,jk) )
               vT = 0.5_wp * ( vn(ji,jj  ,jk) + vn(ji,jj-1,jk) )

               ! Component opposite to the prescribed estuary direction
               opp_comp = MAX( 0._wp, -(uT * dirx + vT * diry) )

               ! Thickness-integrated opposite component over the bottom-h_middle layer
               opp_int   = opp_int   + opp_comp * dz_use
               thick_sum = thick_sum + dz_use

               remaining_h = remaining_h - dz_use

            END DO

            IF ( thick_sum > 0._wp ) THEN
               ebm_u_tide(ji,jj) = opp_int / thick_sum
            ELSE
               ebm_u_tide(ji,jj) = 0._wp
            END IF

         END DO
      END DO
      ebm_L_tide(:,:)  = 0._wp

      ! Convert runoff to discharge (m3/s). Guard against negative/outflow values.
      ebm_Q_river(:,:) = MAX( 0._wp, rnf(:,:) * e1t(:,:) * e2t(:,:) / 1000.0 )

      ebm_wide_mouth(:,:) = NINT( sf_ebm(jp_WM_flag)%fnow(:,:,1) )

      ! Authoritative mask: only compute where the external mask is active and runoff is positive
      !ebm_river_mask(:,:) = ( sf_ebm(jp_msk)%fnow(:,:,1) == 1._wp ) .AND. ( ebm_Q_river(:,:) > 0._wp )
      ebm_river_mask(:,:) = sf_ebm(jp_msk)%fnow(:,:,1)


      CALL ebm%load_estuary( ebm_H_ocean, ebm_H_chan, ebm_L_chan, ebm_W_mouth, ebm_V_est, &
         &                 ebm_u_tide, ebm_L_tide, ebm_Q_river, ebm_S_ocean, ebm_T_ocean, ebm_a0, ebm_a1, &
         &                 ebm_wide_mouth, ebm_river_mask )

      CALL ebm%evaluate_box_model( Q_UM_out=ebm_Q_UM, Q_LM_out=ebm_Q_LM, S_UM_out=ebm_S_UM, &
         &                        const_out=ebm_const, rho_UM_out=ebm_rho_UM )


      ! Convert EBM outflow into discharge load
      ebm_Q_UM = 1000.0 * ebm_Q_UM(:,:) / (e1t(:,:) * e2t(:,:))
      ebm_Q_LM = 1000.0 * ebm_Q_LM(:,:) / (e1t(:,:) * e2t(:,:))


      DO jj = 1, jpj
          DO ji = 1, jpi

            ! Prefer a mouth/river mask if available
            IF ( ebm_river_mask(ji,jj) == 1 ) THEN
              ebm_S_diff(ji,jj) = ebm_S_ocean(ji,jj) - ebm_S_UM(ji,jj)
            END IF

          END DO
      END DO

      ! Diagnostics (optional, if configured in IOM)
      CALL iom_put( 'ebm_msk',    sf_ebm(jp_msk)%fnow(:,:,1) )

      CALL iom_put( 'ebm_Q_R',   ebm_Q_river    )
      CALL iom_put( 'ebm_S_diff',   ebm_S_diff    )
      CALL iom_put( 'ebm_Q_UM',   ebm_Q_UM    )
      CALL iom_put( 'ebm_Q_LM',   ebm_Q_LM    )
      CALL iom_put( 'ebm_S_UM',   ebm_S_UM    )
      CALL iom_put( 'ebm_S_LM',   ebm_S_ocean )
      CALL iom_put( 'ebm_const',  ebm_const   )
      CALL iom_put( 'ebm_rho_UM', ebm_rho_UM  )

      ! Update runoff and salinity
      rnf(:,:) = ebm_Q_UM(:,:)
      rnf_inflow(:,:) = -1*ebm_Q_LM(:,:)
      rnf_tsc(:,:,jp_sal) = ebm_S_UM(:,:) * rnf(:,:) / 1000.0

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
      NAMELIST/namsbc_rnfebm/ cn_dir, &
            & sn_ebm_msk, sn_ebm_W, sn_ebm_H, sn_ebm_uH, sn_ebm_angle, &
            & sn_ebm_a0, sn_ebm_a1, sn_ebm_WM_flag

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
      sn_ebm(jp_W) = sn_ebm_W
      sn_ebm(jp_H) = sn_ebm_H
      sn_ebm(jp_uH) = sn_ebm_uH
      sn_ebm(jp_angle) = sn_ebm_angle
      sn_ebm(jp_a0) = sn_ebm_a0
      sn_ebm(jp_a1) = sn_ebm_a1
      sn_ebm(jp_WM_flag) = sn_ebm_WM_flag

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

      CALL fld_read ( nit000, nn_fsbc, sf_ebm )

      IF( .NOT. ll_ebm_ready ) THEN
         CALL ebm%init()
         ll_ebm_ready = .TRUE.
      ENDIF


   END SUBROUTINE sbc_rnfebm_init

   !!======================================================================
END MODULE sbcrnf_ebm

