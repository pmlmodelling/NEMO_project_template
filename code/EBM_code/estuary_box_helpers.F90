!=============================================================
! estuary_box_helpers.F90
!
! Numerical helpers used by estuary_box_physics:
!   - clamp()        : bound a value into [lo, hi]
!   - cbrt_real()    : real cube-root (sign preserving)
!   - cubic_roots()  : roots of a cubic polynomial (complex)
!   - sw_dens0()     : UNESCO 1980 density at atmospheric pressure
!
! NEMO integration:
!   - uses par_kind::wp for consistent real kind.
!=============================================================
MODULE estuary_box_helpers
   USE par_kind, ONLY: wp
   IMPLICIT NONE
   PRIVATE

   PUBLIC :: clamp
   PUBLIC :: cbrt_real
   PUBLIC :: cubic_roots
   PUBLIC :: sw_dens0

   REAL(wp), PARAMETER :: c68 = 1.00024_wp

CONTAINS

   PURE REAL(wp) FUNCTION clamp(x, lo, hi) RESULT(y)
      REAL(wp), INTENT(IN) :: x, lo, hi
      y = MIN(MAX(x, lo), hi)
   END FUNCTION clamp

   PURE REAL(wp) FUNCTION cbrt_real(x) RESULT(y)
      REAL(wp), INTENT(IN) :: x
      IF (x >= 0._wp) THEN
         y = ABS(x)**(1._wp/3._wp)
      ELSE
         y = -ABS(x)**(1._wp/3._wp)
      END IF
   END FUNCTION cbrt_real

   PURE COMPLEX(wp) FUNCTION cbrt_complex(z) RESULT(w)
      COMPLEX(wp), INTENT(IN) :: z
      REAL(wp) :: r, theta
      r     = ABS(z)
      theta = ATAN2(AIMAG(z), REAL(z, wp))
      w = CMPLX( r**(1._wp/3._wp) * COS(theta/3._wp), &
                 r**(1._wp/3._wp) * SIN(theta/3._wp), wp )
   END FUNCTION cbrt_complex

   !-----------------------------------------------------------------
   ! cubic_roots
   ! Solve: a3*x^3 + a2*x^2 + a1*x + a0 = 0
   ! coeff(1:4) = [a3, a2, a1, a0]
   !
   ! Returns 3 (possibly complex) roots via Cardano.
   ! NOTE: In normal EBM use, a3 = lambda3 = -H, so it is never ~0 for H>0.
   !-----------------------------------------------------------------

   SUBROUTINE cubic_roots(coeff, roots)
      ! Solve a3*x^3 + a2*x^2 + a1*x + a0 = 0 (real coefficients).
      REAL(wp),    INTENT(IN)  :: coeff(4)
      COMPLEX(wp), INTENT(OUT) :: roots(3)

      REAL(wp) :: a3, a2, a1, a0
      REAL(wp) :: b, c, d, p, q
      REAL(wp) :: disc, sqrt_disc, eps
      REAL(wp) :: third, shift
      REAL(wp) :: u, v
      REAL(wp) :: pi_val, phi, t, denom, cosphi

      a3 = coeff(1); a2 = coeff(2); a1 = coeff(3); a0 = coeff(4)
      roots = CMPLX(0._wp, 0._wp, wp)

      IF (ABS(a3) <= TINY(1._wp)) RETURN

      third  = 1._wp/3._wp
      pi_val = ACOS(-1._wp)

      ! Normalize: x^3 + b*x^2 + c*x + d = 0
      b = a2 / a3
      c = a1 / a3
      d = a0 / a3
      shift = b*third

      ! Depressed cubic: x = y - b/3  ->  y^3 + p*y + q = 0
      p = c - b*b*third
      q = (2._wp*b*b*b)/27._wp - (b*c)*third + d

      disc = (q*q)/4._wp + (p*p*p)/27._wp
      eps  = 128._wp*EPSILON(1._wp) * (ABS((q*q)/4._wp) + ABS((p*p*p)/27._wp) + 1._wp)

      IF (disc > eps) THEN
         ! One real root + complex pair
         sqrt_disc = SQRT(disc)
         u = cbrt_real(-q/2._wp + sqrt_disc)
         v = cbrt_real(-q/2._wp - sqrt_disc)

         roots(1) = CMPLX( (u+v) - shift, 0._wp, wp )
         roots(2) = CMPLX( -(u+v)/2._wp - shift,  (SQRT(3._wp)/2._wp)*(u-v), wp )
         roots(3) = CMPLX( -(u+v)/2._wp - shift, -(SQRT(3._wp)/2._wp)*(u-v), wp )

      ELSEIF (disc < -eps) THEN
         ! Three real roots (trigonometric form)
         IF (p >= 0._wp) THEN
            u = cbrt_real(-q/2._wp)
            roots(1) = CMPLX( 2._wp*u - shift, 0._wp, wp )
            roots(2) = CMPLX( -u - shift,      0._wp, wp )
            roots(3) = CMPLX( -u - shift,      0._wp, wp )
         ELSE
            t = 2._wp * SQRT( -p / 3._wp )
            denom = 2._wp * SQRT( MAX(0._wp, -(p*p*p)/27._wp) )

            IF (denom <= TINY(1._wp)) THEN
               u = cbrt_real(-q)
               roots(1) = CMPLX( u - shift, 0._wp, wp )
               roots(2) = CMPLX( u - shift, 0._wp, wp )
               roots(3) = CMPLX( u - shift, 0._wp, wp )
            ELSE
               cosphi = clamp( (-q) / denom, -1._wp, 1._wp )
               phi = ACOS(cosphi)

               roots(1) = CMPLX( t*COS(  phi/3._wp )                - shift, 0._wp, wp )
               roots(2) = CMPLX( t*COS( (phi+2._wp*pi_val)/3._wp )  - shift, 0._wp, wp )
               roots(3) = CMPLX( t*COS( (phi+4._wp*pi_val)/3._wp )  - shift, 0._wp, wp )
            END IF
         END IF

      ELSE
         ! disc ~ 0: repeated root(s)
         u = cbrt_real(-q/2._wp)
         roots(1) = CMPLX( 2._wp*u - shift, 0._wp, wp )
         roots(2) = CMPLX( -u - shift,      0._wp, wp )
         roots(3) = CMPLX( -u - shift,      0._wp, wp )
      END IF
   END SUBROUTINE cubic_roots

   !-----------------------------------------------------------------
   ! sw_dens0
   !
   ! Seawater density at atmospheric pressure, UNESCO 1980 polynomial.
   ! Inputs:
   !   t : temperature [degC]
   !   s : salinity [PSU]
   ! Output:
   !   density [kg/m^3]
   !-----------------------------------------------------------------
   PURE REAL(wp) FUNCTION sw_dens0(t, s) RESULT(dens)
      REAL(wp), INTENT(IN) :: t, s

      REAL(wp) :: t68
      REAL(wp) :: a0,a1,a2,a3,a4,a5
      REAL(wp) :: b0,b1,b2,b3,b4
      REAL(wp) :: c0,c1,c2
      REAL(wp) :: d0
      REAL(wp) :: rho_w

      b0 = 8.24493e-1_wp
      b1 = -4.0899e-3_wp
      b2 = 7.6438e-5_wp
      b3 = -8.2467e-7_wp
      b4 = 5.3875e-9_wp

      c0 = -5.72466e-3_wp
      c1 = 1.0227e-4_wp
      c2 = -1.6546e-6_wp

      d0 = 4.8314e-4_wp

      a0 = 999.842594_wp
      a1 = 6.793952e-2_wp
      a2 = -9.095290e-3_wp
      a3 = 1.001685e-4_wp
      a4 = -1.120083e-6_wp
      a5 = 6.536332e-9_wp

      t68 = t * c68

      dens = s * (b0 + b1*t68 + b2*t68**2 + b3*t68**3 + b4*t68**4) &
           + s**1.5_wp * (c0 + c1*t68 + c2*t68**2) &
           + d0 * s**2

      rho_w = a0 + a1*t68 + a2*t68**2 + a3*t68**3 + a4*t68**4 + a5*t68**5
      dens  = dens + rho_w
   END FUNCTION sw_dens0

END MODULE estuary_box_helpers

