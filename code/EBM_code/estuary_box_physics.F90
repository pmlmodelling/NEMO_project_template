!=============================================================
! estuary_box_physics.F90
!=============================================================
MODULE estuary_box_physics
   USE par_kind,            ONLY: wp
   USE estuary_box_helpers, ONLY: clamp, cbrt_real, cubic_roots, sw_dens0
   IMPLICIT NONE
   PRIVATE

   REAL(wp), PARAMETER :: c68 = 1.00024_wp

   PUBLIC :: Estuary_box_model

   TYPE, PUBLIC :: Estuary_box_model
      ! ---- global parameters ----
      REAL(wp) :: a_0          = 1.2_wp
      REAL(wp) :: a_1          = 0.88_wp
      REAL(wp) :: a_t          = 0.59_wp
      REAL(wp) :: Sc           = 2.2_wp
      REAL(wp) :: tidal_period = 32000._wp
      REAL(wp) :: beta         = 7.7e-4_wp
      REAL(wp) :: g            = 9.81_wp
      REAL(wp) :: S            = 1._wp
      REAL(wp) :: rho_R        = 1000._wp
      REAL(wp) :: rho_LM       = 1025._wp
      REAL(wp) :: S_fw         = 0._wp     ! freshwater salinity fallback

      ! ---- scalar cell state (Python names in comments) ----
      REAL(wp) :: H_ocean = 0._wp   ! Python H
      REAL(wp) :: H_chan  = 0._wp   ! Python h
      REAL(wp) :: L_chan  = 0._wp   ! Python L
      REAL(wp) :: W_mouth = 0._wp   ! Python W
      REAL(wp) :: V_est   = 0._wp   ! Python V
      REAL(wp) :: u_tide  = 0._wp   ! Python u_t
      REAL(wp) :: L_tide  = 0._wp   ! Python L_t
      REAL(wp) :: Q_river = 0._wp   ! Python Q_R
      REAL(wp) :: S_ocean = 0._wp   ! Python S_LM
      REAL(wp) :: T_ocean = 0._wp   ! Python T_LM
      INTEGER  :: wide_mouth = 0._wp

      ! ---- scalar outputs ----
      REAL(wp) :: Q_LM       = 0._wp
      REAL(wp) :: Q_UM       = 0._wp
      REAL(wp) :: rho_UM     = 0._wp
      REAL(wp) :: S_UM       = 0._wp
      REAL(wp) :: const_last = 0._wp

      ! ---- 2-D stored fields ----
      LOGICAL :: has_grid = .FALSE.
      INTEGER :: ni = 0, nj = 0

      REAL(wp), ALLOCATABLE :: H_ocean2(:,:), H_chan2(:,:), L_chan2(:,:), W_mouth2(:,:), V_est2(:,:)
      REAL(wp), ALLOCATABLE :: u_tide2(:,:), L_tide2(:,:)
      REAL(wp), ALLOCATABLE :: a0_2(:,:), S_ocean2(:,:), T_ocean2(:,:), Q_river2(:,:)
      INTEGER, ALLOCATABLE :: wide_mouth2(:,:), river_mask(:,:)

   CONTAINS
      PROCEDURE, PUBLIC :: init
      PROCEDURE, PASS, PUBLIC :: load_estuary      => load_estuary_2d
      PROCEDURE, PASS, PUBLIC :: evaluate_box_model => evaluate_box_model_2d

      PROCEDURE, PUBLIC :: B_UM
      PROCEDURE, PUBLIC :: F_R
      PROCEDURE, PUBLIC :: F_REX
      PROCEDURE, PUBLIC :: dF_R
      PROCEDURE, PUBLIC :: dF_REX
      PROCEDURE, PUBLIC :: est_dens
      PROCEDURE, PUBLIC :: sw_smow
      PROCEDURE, PUBLIC :: in_flux
      PROCEDURE, PUBLIC :: S_eff
   END TYPE Estuary_box_model

CONTAINS

   !============================================================
   ! init
   !============================================================
   SUBROUTINE init(EBM, a0, a1, a_t, schmidt, tidal_period, beta, g, S, rho_R, rho_LM, S_fw)
      IMPLICIT NONE
      CLASS(Estuary_box_model), INTENT(INOUT) :: EBM
      REAL(wp), INTENT(IN), OPTIONAL :: a0, a1, a_t, schmidt, tidal_period, beta, g, S, rho_R, rho_LM, S_fw

      IF (PRESENT(a0))           EBM%a_0 = a0
      IF (PRESENT(a1))           EBM%a_1 = a1
      IF (PRESENT(a_t))          EBM%a_t = a_t
      IF (PRESENT(schmidt))      EBM%Sc  = schmidt
      IF (PRESENT(tidal_period)) EBM%tidal_period = tidal_period
      IF (PRESENT(beta))         EBM%beta = beta
      IF (PRESENT(g))            EBM%g = g
      IF (PRESENT(S))            EBM%S = S
      IF (PRESENT(rho_R))        EBM%rho_R = rho_R
      IF (PRESENT(rho_LM))       EBM%rho_LM = rho_LM
      IF (PRESENT(S_fw))         EBM%S_fw = S_fw
   END SUBROUTINE init

   !============================================================
   ! load_estuary (2-D) + authoritative river_mask
   !============================================================
   SUBROUTINE load_estuary_2d(EBM, H_ocean_in, H_chan_in, L_chan_in, W_mouth_in, V_est_in, &
                              u_tide_in, L_tide_in, Q_river_in, S_ocean_in, T_ocean_in, a0_in, &
                              wide_mouth_in, river_mask_in)
      IMPLICIT NONE
      ! Inputs are 2-D fields on the same (ni,nj) grid:
      !   H_ocean_in     : ocean-side depth at the mouth (Python: H)
      !   H_chan_in      : mean channel depth (Python: h)
      !   L_chan_in      : channel length (Python: L)
      !   W_mouth_in     : estuary mouth width (Python: W)
      !   V_est_in       : mean estuary volume (Python: V)
      !   u_tide_in      : tidal velocity amplitude (Python: u_t)
      !   L_tide_in      : tidal excursion length (Python: L_t)
      !   Q_river_in     : river discharge (Python: Q_R)
      !   S_ocean_in     : ocean salinity at the mouth (Python: S_ocean / So)
      !   T_ocean_in     : ocean temperature at the mouth (units per EOS)
      !   a0_in          : empirical coefficient scaling tidal exchange terms (Python: a_0)
      !   wide_mouth_in  : regime flag for wide-mouth parameterisation
      !   river_mask_in  : active-cell mask (TRUE = compute / valid cell)
      CLASS(Estuary_box_model), INTENT(INOUT) :: EBM
      REAL(wp), INTENT(IN) :: H_ocean_in(:,:), H_chan_in(:,:), L_chan_in(:,:), W_mouth_in(:,:), V_est_in(:,:)
      REAL(wp), INTENT(IN) :: u_tide_in(:,:),  L_tide_in(:,:), Q_river_in(:,:), S_ocean_in(:,:), T_ocean_in(:,:), a0_in(:,:)
      INTEGER, INTENT(IN) :: wide_mouth_in(:,:), river_mask_in(:,:)

      INTEGER :: ni_loc, nj_loc

      ni_loc = SIZE(H_ocean_in,1)
      nj_loc = SIZE(H_ocean_in,2)

      IF (SIZE(H_chan_in,1)  /= ni_loc .OR. SIZE(H_chan_in,2)  /= nj_loc) STOP 'load_estuary_2d: H_chan_in shape mismatch'
      IF (SIZE(L_chan_in,1)  /= ni_loc .OR. SIZE(L_chan_in,2)  /= nj_loc) STOP 'load_estuary_2d: L_chan_in shape mismatch'
      IF (SIZE(W_mouth_in,1) /= ni_loc .OR. SIZE(W_mouth_in,2) /= nj_loc) STOP 'load_estuary_2d: W_mouth_in shape mismatch'
      IF (SIZE(V_est_in,1)   /= ni_loc .OR. SIZE(V_est_in,2)   /= nj_loc) STOP 'load_estuary_2d: V_est_in shape mismatch'
      IF (SIZE(u_tide_in,1)  /= ni_loc .OR. SIZE(u_tide_in,2)  /= nj_loc) STOP 'load_estuary_2d: u_tide_in shape mismatch'
      IF (SIZE(L_tide_in,1)  /= ni_loc .OR. SIZE(L_tide_in,2)  /= nj_loc) STOP 'load_estuary_2d: L_tide_in shape mismatch'
      IF (SIZE(Q_river_in,1) /= ni_loc .OR. SIZE(Q_river_in,2) /= nj_loc) STOP 'load_estuary_2d: Q_river_in shape mismatch'
      IF (SIZE(S_ocean_in,1) /= ni_loc .OR. SIZE(S_ocean_in,2) /= nj_loc) STOP 'load_estuary_2d: S_ocean_in shape mismatch'
      IF (SIZE(T_ocean_in,1) /= ni_loc .OR. SIZE(T_ocean_in,2) /= nj_loc) STOP 'load_estuary_2d: T_ocean_in shape mismatch'
      IF (SIZE(a0_in,1)      /= ni_loc .OR. SIZE(a0_in,2)      /= nj_loc) STOP 'load_estuary_2d: a0_in shape mismatch'
      IF (SIZE(wide_mouth_in,1) /= ni_loc .OR. SIZE(wide_mouth_in,2) /= nj_loc) STOP 'load_estuary_2d: wide_mouth_in shape mismatch'
      IF (SIZE(river_mask_in,1) /= ni_loc .OR. SIZE(river_mask_in,2) /= nj_loc) STOP 'load_estuary_2d: river_mask_in shape mismatch'

      EBM%ni = ni_loc
      EBM%nj = nj_loc
      EBM%has_grid = .TRUE.

      CALL alloc_or_realloc_r2(EBM%H_ocean2, ni_loc, nj_loc)
      CALL alloc_or_realloc_r2(EBM%H_chan2,  ni_loc, nj_loc)
      CALL alloc_or_realloc_r2(EBM%L_chan2,  ni_loc, nj_loc)
      CALL alloc_or_realloc_r2(EBM%W_mouth2, ni_loc, nj_loc)
      CALL alloc_or_realloc_r2(EBM%V_est2,   ni_loc, nj_loc)
      CALL alloc_or_realloc_r2(EBM%u_tide2,  ni_loc, nj_loc)
      CALL alloc_or_realloc_r2(EBM%L_tide2,  ni_loc, nj_loc)
      CALL alloc_or_realloc_r2(EBM%Q_river2, ni_loc, nj_loc)
      CALL alloc_or_realloc_r2(EBM%S_ocean2, ni_loc, nj_loc)
      CALL alloc_or_realloc_r2(EBM%T_ocean2, ni_loc, nj_loc)
      CALL alloc_or_realloc_r2(EBM%a0_2,     ni_loc, nj_loc)
      CALL alloc_or_realloc_i2(EBM%wide_mouth2, ni_loc, nj_loc)
      CALL alloc_or_realloc_i2(EBM%river_mask,  ni_loc, nj_loc)

      EBM%H_ocean2 = H_ocean_in
      EBM%H_chan2  = H_chan_in
      EBM%L_chan2  = L_chan_in
      EBM%W_mouth2 = W_mouth_in
      EBM%V_est2   = V_est_in
      EBM%u_tide2  = u_tide_in
      EBM%L_tide2  = L_tide_in
      EBM%Q_river2 = Q_river_in
      EBM%S_ocean2 = S_ocean_in
      EBM%T_ocean2 = T_ocean_in
      EBM%a0_2     = a0_in
      EBM%wide_mouth2 = wide_mouth_in

      ! Authoritative river mask
      EBM%river_mask = river_mask_in
   END SUBROUTINE load_estuary_2d

   !============================================================
   ! evaluate_box_model (2-D)
   !============================================================
   SUBROUTINE evaluate_box_model_2d(EBM, daily_tidal_amp, &
                                    Q_UM_out, Q_LM_out, S_UM_out, const_out, rho_UM_out)
      IMPLICIT NONE
      CLASS(Estuary_box_model), INTENT(INOUT) :: EBM
      REAL(wp), INTENT(IN), OPTIONAL :: daily_tidal_amp(:,:)
      REAL(wp), INTENT(OUT) :: Q_UM_out(:,:), Q_LM_out(:,:), S_UM_out(:,:), const_out(:,:)
      REAL(wp), INTENT(OUT), OPTIONAL :: rho_UM_out(:,:)

      INTEGER :: i, j, ni_loc, nj_loc
      REAL(wp) :: H_ocean_cell, H_chan_cell, W_mouth_cell, L_tide_cell, u_tide_cell
      REAL(wp) :: Q_river_cell, S_ocean_cell, a0_cell
      INTEGER  :: wide_cell
      LOGICAL  :: ok
      REAL(wp) :: qlm, qum, rhoum, sum_out, cst, a_t_out
      REAL(wp) :: pi_val

      IF (.NOT. EBM%has_grid) STOP 'evaluate_box_model_2d: call load_estuary_2d first'

      ni_loc = EBM%ni
      nj_loc = EBM%nj

      IF (SIZE(Q_UM_out,1) /= ni_loc .OR. SIZE(Q_UM_out,2) /= nj_loc) STOP 'evaluate_box_model_2d: Q_UM_out shape mismatch'
      IF (SIZE(Q_LM_out,1) /= ni_loc .OR. SIZE(Q_LM_out,2) /= nj_loc) STOP 'evaluate_box_model_2d: Q_LM_out shape mismatch'
      IF (SIZE(S_UM_out,1) /= ni_loc .OR. SIZE(S_UM_out,2) /= nj_loc) STOP 'evaluate_box_model_2d: S_UM_out shape mismatch'
      IF (SIZE(const_out,1) /= ni_loc .OR. SIZE(const_out,2) /= nj_loc) STOP 'evaluate_box_model_2d: const_out shape mismatch'
      IF (PRESENT(rho_UM_out)) THEN
         IF (SIZE(rho_UM_out,1) /= ni_loc .OR. SIZE(rho_UM_out,2) /= nj_loc) STOP 'evaluate_box_model_2d: rho_UM_out shape mismatch'
      END IF

      Q_UM_out  = 0._wp
      Q_LM_out  = 0._wp
      S_UM_out  = 0._wp
      const_out = 0._wp
      IF (PRESENT(rho_UM_out)) rho_UM_out = 0._wp

      pi_val = ACOS(-1._wp)

      DO j = 1, nj_loc
         DO i = 1, ni_loc

            IF (EBM%river_mask(i,j) == 0._wp) CYCLE

            Q_river_cell = EBM%Q_river2(i,j)
            !IF (Q_river_cell == 0._wp) CYCLE
            S_ocean_cell = EBM%S_ocean2(i,j)

            !IF (Q_river_cell == 0._wp) CYCLE


            H_ocean_cell = EBM%H_ocean2(i,j)
            H_chan_cell  = EBM%H_chan2(i,j)
            W_mouth_cell = EBM%W_mouth2(i,j)
            L_tide_cell  = EBM%L_tide2(i,j)
            u_tide_cell  = EBM%u_tide2(i,j)
            a0_cell      = EBM%a0_2(i,j)
            wide_cell    = EBM%wide_mouth2(i,j)

            IF (PRESENT(daily_tidal_amp)) THEN
               IF (H_ocean_cell > 0._wp) u_tide_cell = daily_tidal_amp(i,j) * SQRT(EBM%g / MAX(TINY(1._wp), H_ocean_cell))
            END IF

            IF (L_tide_cell == 0._wp .AND. u_tide_cell /= 0._wp) L_tide_cell = EBM%tidal_period * u_tide_cell / pi_val

            ! Fallback: simple river for this river cell
            Q_UM_out(i,j)  = Q_river_cell
            Q_LM_out(i,j)  = 0._wp
            S_UM_out(i,j)  = EBM%S_fw
            const_out(i,j) = 0._wp
            IF (PRESENT(rho_UM_out)) rho_UM_out(i,j) = EBM%rho_R

            ! Gate: if parameters missing/invalid, keep fallback
            !IF (H_ocean_cell <= 0._wp) CYCLE
            !IF (W_mouth_cell <= 0._wp) CYCLE
            !IF (L_tide_cell <= 0._wp)  CYCLE
            !IF (u_tide_cell == 0._wp)  CYCLE
            !IF (S_ocean_cell == 0._wp) CYCLE
            !IF (H_chan_cell < 0._wp .OR. H_chan_cell >= H_ocean_cell) CYCLE

            IF (a0_cell == 0._wp) a0_cell = EBM%a_0

            CALL compute_one_cell(a0_cell, EBM%a_1, EBM%Sc, EBM%beta, EBM%g, EBM%S, &
                                  EBM%rho_R, EBM%rho_LM, &
                                  H_ocean_cell, H_chan_cell, W_mouth_cell, L_tide_cell, u_tide_cell, &
                                  Q_river_cell, S_ocean_cell, wide_cell, &
                                  qlm, qum, rhoum, sum_out, cst, a_t_out, ok)

            !IF (.NOT. ok) CYCLE

            Q_UM_out(i,j)  = qum
            Q_LM_out(i,j)  = qlm
            S_UM_out(i,j)  = sum_out
            const_out(i,j) = cst
            IF (PRESENT(rho_UM_out)) rho_UM_out(i,j) = rhoum

         END DO
      END DO
   END SUBROUTINE evaluate_box_model_2d

   !============================================================
   ! Diagnostics
   !============================================================
   PURE REAL(wp) FUNCTION B_UM(EBM, const, N_R, N_LM) RESULT(N_UM)
      IMPLICIT NONE
      CLASS(Estuary_box_model), INTENT(IN) :: EBM
      REAL(wp), INTENT(IN) :: const, N_R, N_LM
      N_UM = (N_R*EBM%Q_river + N_LM*(const - EBM%Q_LM)) / (EBM%Q_UM + const)
   END FUNCTION B_UM

   PURE REAL(wp) FUNCTION F_R(EBM, Z, H_upper_in, H_lower_in) RESULT(out)
      IMPLICIT NONE
      CLASS(Estuary_box_model), INTENT(IN) :: EBM
      REAL(wp), INTENT(IN) :: Z
      REAL(wp), INTENT(IN), OPTIONAL :: H_upper_in, H_lower_in
      REAL(wp) :: H_upper, H_lower

      H_upper = EBM%H_ocean - EBM%H_chan
      H_lower = EBM%H_chan
      IF (PRESENT(H_upper_in)) H_upper = H_upper_in
      IF (PRESENT(H_lower_in)) H_lower = H_lower_in

      IF (Z <= -H_upper) THEN
         out = 0._wp
      ELSE
         out = EBM%Q_river * EBM%S * (1._wp + Z/MAX(TINY(1._wp),H_upper))
      END IF
   END FUNCTION F_R

   PURE REAL(wp) FUNCTION F_REX(EBM, Z, H_upper_in, H_lower_in) RESULT(out)
      IMPLICIT NONE
      CLASS(Estuary_box_model), INTENT(IN) :: EBM
      REAL(wp), INTENT(IN) :: Z
      REAL(wp), INTENT(IN), OPTIONAL :: H_upper_in, H_lower_in
      REAL(wp) :: H_upper, H_lower, S_eff_loc, F0

      H_upper = EBM%H_ocean - EBM%H_chan
      H_lower = EBM%H_chan
      IF (PRESENT(H_upper_in)) H_upper = H_upper_in
      IF (PRESENT(H_lower_in)) H_lower = H_lower_in

      S_eff_loc = EBM%S_ocean * EBM%Q_LM / (EBM%Q_LM - EBM%Q_river)
      F0 = -EBM%Q_LM * (EBM%S_ocean - S_eff_loc)

      IF (Z <= -(H_upper + H_lower)) THEN
         out = 0._wp
      ELSEIF (Z <= -H_upper) THEN
         out = -F0 * H_upper * (H_upper + H_lower + Z) / MAX(TINY(1._wp),H_lower)
      ELSEIF (Z <= 0._wp) THEN
         out =  F0 * Z / MAX(TINY(1._wp),H_upper)
      ELSE
         out = 0._wp
      END IF
   END FUNCTION F_REX

   PURE REAL(wp) FUNCTION dF_R(EBM, Z, H_upper_in, H_lower_in) RESULT(out)
      IMPLICIT NONE
      CLASS(Estuary_box_model), INTENT(IN) :: EBM
      REAL(wp), INTENT(IN) :: Z
      REAL(wp), INTENT(IN), OPTIONAL :: H_upper_in, H_lower_in
      REAL(wp) :: H_upper

      H_upper = EBM%H_ocean - EBM%H_chan
      IF (PRESENT(H_upper_in)) H_upper = H_upper_in

      IF (Z <= -H_upper) THEN
         out = 0._wp
      ELSE
         out = EBM%Q_river * EBM%S / MAX(TINY(1._wp),H_upper)
      END IF
   END FUNCTION dF_R

   PURE REAL(wp) FUNCTION dF_REX(EBM, Z, H_upper_in, H_lower_in) RESULT(out)
      IMPLICIT NONE
      CLASS(Estuary_box_model), INTENT(IN) :: EBM
      REAL(wp), INTENT(IN) :: Z
      REAL(wp), INTENT(IN), OPTIONAL :: H_upper_in, H_lower_in
      REAL(wp) :: H_upper, H_lower, S_eff_loc, F0

      H_upper = EBM%H_ocean - EBM%H_chan
      H_lower = EBM%H_chan
      IF (PRESENT(H_upper_in)) H_upper = H_upper_in
      IF (PRESENT(H_lower_in)) H_lower = H_lower_in

      S_eff_loc = EBM%S_ocean * EBM%Q_LM / (EBM%Q_LM - EBM%Q_river)
      F0 = -EBM%Q_LM * (EBM%S_ocean - S_eff_loc)

      IF (Z <= -(H_upper + H_lower)) THEN
         out = 0._wp
      ELSEIF (Z <= -H_upper) THEN
         out = -F0 * H_upper / MAX(TINY(1._wp),H_lower)
      ELSEIF (Z <= 0._wp) THEN
         out = F0 / MAX(TINY(1._wp),H_upper)
      ELSE
         out = 0._wp
      END IF
   END FUNCTION dF_REX

   PURE REAL(wp) FUNCTION est_dens(EBM, t, s) RESULT(dens)
      IMPLICIT NONE
      CLASS(Estuary_box_model), INTENT(IN) :: EBM
      REAL(wp), INTENT(IN) :: t, s
      REAL(wp) :: b0,b1,b2,b3,b4, c0,c1,c2, d0, t68

      b0 = 8.24493e-1_wp
      b1 = -4.0899e-3_wp
      b2 = 7.6438e-5_wp
      b3 = -8.2467e-7_wp
      b4 = 5.3875e-9_wp
      c0 = -5.72466e-3_wp
      c1 = 1.0227e-4_wp
      c2 = -1.6546e-6_wp
      d0 = 4.8314e-4_wp

      t68  = t * c68
      dens = s*(b0 + b1*t68 + b2*t68**2 + b3*t68**3 + b4*t68**4) &
           + s**1.5_wp*(c0 + c1*t68 + c2*t68**2) + d0*s**2
      dens = dens + EBM%sw_smow(t68)
   END FUNCTION est_dens

   PURE REAL(wp) FUNCTION sw_smow(EBM, t) RESULT(dens)
      IMPLICIT NONE
      CLASS(Estuary_box_model), INTENT(IN) :: EBM
      REAL(wp), INTENT(IN) :: t
      REAL(wp) :: a0,a1,a2,a3,a4,a5, T68w

      a0 = 999.842594_wp
      a1 = 6.793952e-2_wp
      a2 = -9.095290e-3_wp
      a3 = 1.001685e-4_wp
      a4 = -1.120083e-6_wp
      a5 = 6.536332e-9_wp

      T68w = t * c68
      dens = a0 + a1*T68w + a2*T68w**2 + a3*T68w**3 + a4*T68w**4 + a5*T68w**5
   END FUNCTION sw_smow

   SUBROUTINE in_flux(EBM, F_r, F_o, B_river, B_ocean, deltaT)
      IMPLICIT NONE
      CLASS(Estuary_box_model), INTENT(IN) :: EBM
      REAL(wp), INTENT(OUT) :: F_r, F_o
      REAL(wp), INTENT(IN), OPTIONAL :: B_river, B_ocean, deltaT

      REAL(wp) :: Br, Bo, dt, rho_estuary, vol_estuary
      REAL(wp), PARAMETER :: SecDay = 86400._wp

      Br = 0._wp; Bo = 0._wp; dt = 1._wp
      IF (PRESENT(B_river)) Br = B_river
      IF (PRESENT(B_ocean)) Bo = B_ocean
      IF (PRESENT(deltaT))  dt = deltaT

      rho_estuary = sw_dens0(EBM%T_ocean, EBM%S_ocean)
      vol_estuary = EBM%V_est * rho_estuary / 1000._wp

      F_r = Br * EBM%Q_river * dt * SecDay / MAX(TINY(1._wp), vol_estuary)
      F_o = Bo * EBM%Q_LM    * dt * SecDay / MAX(TINY(1._wp), vol_estuary)
   END SUBROUTINE in_flux

   PURE REAL(wp) FUNCTION S_eff(EBM, S_ocean_in) RESULT(res)
      IMPLICIT NONE
      CLASS(Estuary_box_model), INTENT(IN) :: EBM
      REAL(wp), INTENT(IN) :: S_ocean_in
      res = S_ocean_in * EBM%Q_LM / (EBM%Q_LM - EBM%Q_river)
   END FUNCTION S_eff

   !============================================================
   ! PRIVATE: single-cell kernel
   !============================================================
   SUBROUTINE compute_one_cell(a0, a1, Sc, beta, g, S, rho_R, rho_LM, &
                               H_ocean, H_lower, W_mouth, L_tide, u_tide, &
                               Q_river, S_ocean, wide_mouth, &
                               Q_LM, Q_UM, rho_UM, S_UM, const, a_t_out, ok)
      IMPLICIT NONE
      REAL(wp), INTENT(IN)  :: a0, a1, Sc, beta, g, S, rho_R, rho_LM
      REAL(wp), INTENT(IN)  :: H_ocean, H_lower, W_mouth, L_tide, u_tide, Q_river, S_ocean
      INTEGER,  INTENT(IN)  :: wide_mouth
      REAL(wp), INTENT(OUT) :: Q_LM, Q_UM, rho_UM, S_UM, const, a_t_out
      LOGICAL,  INTENT(OUT) :: ok

      REAL(wp) :: pi_val, H_upper
      REAL(wp) :: r_2, r_s, theta, r_cos, r_sin, Fgeom, Rgeom
      REAL(wp) :: a_t_loc, Q_Ut, c, cbrtval, Qmix
      REAL(wp) :: lambda0, lambda1, lambda2, lambda3
      REAL(wp) :: coef(4)
      COMPLEX(wp) :: roots(3)
      REAL(wp) :: qlm_candidate, min_im
      LOGICAL :: have_real
      INTEGER :: k

      ok = .FALSE.
      Q_LM = 0._wp
      Q_UM = 0._wp
      rho_UM = 0._wp
      S_UM = 0._wp
      const = 0._wp
      a_t_out = 0._wp

      IF (H_ocean <= 0._wp) RETURN
      IF (W_mouth <= 0._wp) RETURN
      IF (L_tide  <= 0._wp) RETURN
      IF (u_tide  == 0._wp) RETURN
      IF (Q_river == 0._wp) RETURN
      IF (H_lower < 0._wp .OR. H_lower >= H_ocean) RETURN
      IF (S_ocean < 0._wp) RETURN

      pi_val  = ACOS(-1._wp)
      H_upper = H_ocean - H_lower

      IF (W_mouth > pi_val*L_tide/2._wp) THEN
         r_2 = L_tide
      ELSE
         r_2 = SQRT( MAX(0._wp, 2._wp*W_mouth*L_tide/pi_val) )
      END IF

      r_s = SQRT( MAX(0._wp, L_tide**2 - W_mouth**2 * (L_tide**2 - r_2**2) / &
                       MAX(TINY(1._wp), 4._wp*r_2**2)) )
      IF (r_s <= 0._wp) RETURN

      theta = ASIN( clamp( W_mouth / MAX(TINY(1._wp), 2._wp*r_s), -1._wp, 1._wp ) )
      !theta = ASIN(W_mouth / (2._wp * r_s))

      r_cos = (L_tide - r_2) * COS(pi_val - 2._wp*theta)
      r_sin = (L_tide - r_2) * SIN(pi_val - 2._wp*theta)

      IF (wide_mouth == 1._wp) THEN
         Fgeom = (L_tide*r_2) * ( theta + ATAN( r_sin / MAX(TINY(1._wp), (L_tide + r_2 + r_cos)) ) )
         Rgeom = r_s
      ELSE
         Fgeom = 2._wp * W_mouth * L_tide * theta / pi_val
         Rgeom = SQRT( MAX(0._wp, 2._wp*W_mouth*L_tide/pi_val) )
      END IF

      a_t_loc = 1._wp - ( Fgeom + (W_mouth/2._wp)*Rgeom*COS(theta) ) / &
                        MAX(TINY(1._wp), (W_mouth*L_tide))
      a_t_out = a_t_loc

      Q_Ut = 2._wp * W_mouth * (H_upper - H_lower) * u_tide / pi_val
      c    = SQRT( MAX(0._wp, g * beta * S_ocean * H_ocean) )

      cbrtval = cbrt_real( (W_mouth*H_ocean*c**4) / MAX(TINY(1._wp), (Q_river*Sc**2)) )
      Qmix    = Q_river + a0*a_t_out*Q_Ut

      lambda0 = -0.048_wp * a1 * cbrtval * H_ocean**2 * W_mouth * Qmix * Q_river
      lambda1 =  0.096_wp  * a1 * cbrtval * H_ocean**2 * W_mouth * Q_river &
              -  Q_river * (2._wp*H_ocean - H_lower) * Qmix &
              - (a0*a_t_loc*Q_Ut)**2 * H_ocean / 4._wp
      lambda2 =  2._wp*Q_river * (2._wp*H_ocean - H_lower) + a0*a_t_loc*Q_Ut*H_ocean
      lambda3 = -H_ocean

      coef = (/ lambda3, lambda2, lambda1, lambda0 /)
      CALL cubic_roots(coef, roots)

      have_real = .FALSE.
      qlm_candidate = HUGE(1._wp)

      DO k = 1, 3
         IF (ABS(AIMAG(roots(k))) <= 1.e-10_wp) THEN
            have_real = .TRUE.
            qlm_candidate = MIN(qlm_candidate, REAL(roots(k), wp))
         END IF
      END DO

      IF (.NOT. have_real) THEN
         ! Fallback: take the root with smallest |Im|.
         qlm_candidate = REAL(roots(1), wp)
         min_im = ABS(AIMAG(roots(1)))
         DO k = 2, 3
            IF (ABS(AIMAG(roots(k))) < min_im) THEN
               min_im = ABS(AIMAG(roots(k)))
               qlm_candidate = REAL(roots(k), wp)
            END IF
         END DO
      END IF

      Q_LM = qlm_candidate
      Q_UM = Q_river - Q_LM

      const = (a0 * a_t_loc * Q_Ut) / 2._wp
      IF ( (Q_UM + a0*a1*Q_Ut/2._wp) == 0._wp ) RETURN

      rho_UM = ( rho_R*Q_river - rho_LM*Q_LM + rho_LM * const ) / &
               ( Q_UM + const )


      IF ( (Q_UM + const) == 0._wp ) RETURN

      S_UM = S_ocean * (-Q_LM + const) / (Q_UM + const)

      ok = .TRUE.
   END SUBROUTINE compute_one_cell

   !============================================================
   ! PRIVATE: allocation helpers
   !============================================================
   SUBROUTINE alloc_or_realloc_r2(A, ni_in, nj_in)
      IMPLICIT NONE
      REAL(wp), ALLOCATABLE, INTENT(INOUT) :: A(:,:)
      INTEGER, INTENT(IN) :: ni_in, nj_in
      IF (.NOT. ALLOCATED(A)) THEN
         ALLOCATE(A(ni_in, nj_in))
      ELSEIF (SIZE(A,1) /= ni_in .OR. SIZE(A,2) /= nj_in) THEN
         DEALLOCATE(A)
         ALLOCATE(A(ni_in, nj_in))
      END IF
   END SUBROUTINE alloc_or_realloc_r2

   SUBROUTINE alloc_or_realloc_i2(A, ni_in, nj_in)
      IMPLICIT NONE
      INTEGER, ALLOCATABLE, INTENT(INOUT) :: A(:,:)
      INTEGER, INTENT(IN) :: ni_in, nj_in
      IF (.NOT. ALLOCATED(A)) THEN
         ALLOCATE(A(ni_in, nj_in))
      ELSEIF (SIZE(A,1) /= ni_in .OR. SIZE(A,2) /= nj_in) THEN
         DEALLOCATE(A)
         ALLOCATE(A(ni_in, nj_in))
      END IF
   END SUBROUTINE alloc_or_realloc_i2

END MODULE estuary_box_physics


