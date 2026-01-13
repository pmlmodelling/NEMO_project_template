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
   USE phycst         ! physical constants
   USE sbc_oce        ! surface boundary condition variables
   USE sbcrnf         ! River runoff
   !
   USE in_out_manager ! I/O manager
   USE fldread        ! read input field at current time step
   USE iom            ! I/O module
   USE lib_mpp        ! MPP library

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
   REAL(wp), ALLOCATABLE, DIMENSION(:,:,:) :: ebm_sal, ebm_u, ebm_v ! Ocean side salinity, u and v at estuary mouths

CONTAINS

   INTEGER FUNCTION sbc_rnfebm_alloc()
      !!----------------------------------------------------------------------
      !!                ***  ROUTINE sbc_rnf_alloc  ***
      !!----------------------------------------------------------------------
      ALLOCATE( ebm_sal(jpi,jpj,jpk)         , ebm_u(jpi,jpj,jpk)          ,     &
         &      ebm_v(jpi,jpj,jpk) , STAT=sbc_rnfebm_alloc )
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
      INTEGER  ::   ji, jj    ! dummy loop indices
      INTEGER  ::   z_err = 0 ! dummy integer for error handling
      
      !!----------------------------------------------------------------------
      !
      CALL fld_read ( kt, nn_fsbc, sf_ebm )
     
      ! Initialise ocean side variables
      ebm_sal(:,:,:) = 0._wp
      ebm_u(:,:,:) = 0._wp
      ebm_v(:,:,:) = 0._wp

      ! Fill ocean side variables at estuary mouths
      DO jj = 1, jpj
        DO ji = 1, jpi
           IF ( sf_ebm(jp_msk)%fnow(ji,jj,1) == 1 ) THEN
              ebm_sal(ji,jj,:) = tsn(ji,jj,:,jp_sal) 
              ebm_u(ji,jj,:) = un(ji,jj,:)
              ebm_v(ji,jj,:) = vn(ji,jj,:)
           ENDIF
        ENDDO
      ENDDO

      ! Temporary output 
      CALL iom_put( 'ebm_msk', sf_ebm(jp_msk)%fnow(:,:,1) )
      CALL iom_put( 'ebm_sal', ebm_sal )
      CALL iom_put( 'ebm_u', ebm_v )
      CALL iom_put( 'ebm_v', ebm_u )

      

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
      INTEGER           ::   ierror, inum  ! temporary integer
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
