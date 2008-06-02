C
C             Parallel Sparse BLAS  version 2.2
C   (C) Copyright 2006/2007/2008
C                      Salvatore Filippone    University of Rome Tor Vergata
C                      Alfredo Buttari        University of Rome Tor Vergata
C
C Redistribution and use in source and binary forms, with or without
C modification, are permitted provided that the following conditions
C are met:
C   1. Redistributions of source code must retain the above copyright
C      notice, this list of conditions and the following disclaimer.
C   2. Redistributions in binary form must reproduce the above copyright
C      notice, this list of conditions, and the following disclaimer in the
C      documentation and/or other materials provided with the distribution.
C   3. The name of the PSBLAS group or the names of its contributors may
C      not be used to endorse or promote products derived from this
C      software without specific written permission.
C
C THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
C ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
C TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
C PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE PSBLAS GROUP OR ITS CONTRIBUTORS
C BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
C CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
C SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
C INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
C CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
C ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
C POSSIBILITY OF SUCH DAMAGE.
C
C 
C     SUBROUTINE DCSSM(TRANS,M,N,ALPHA,UNITD,D,PL,FIDT,DESCRT,T,IT1,IT2,
C                      INFOT,PR,B,LDB,BETA,C,LDC,WORK,LWORK,IERROR)
C
C     Purpose
C     =======
C
C     Solving triangular systems of equations with multiple right-hand sides
C                 C <-- ALPHA PL D T-1   PR B + BETA C   or
C                 C <-- ALPHA PL D T-t   PR B + BETA C   or
C                 C <-- ALPHA PL   T-1 D PR B + BETA C   or
C                 C <-- ALPHA PL   T-t D PR B + BETA C
C
C     Parameters
C     ==========
C
C     TRANS    - CHARACTER*1
C             On entry TRANS specifies whether the routine operates with
C             matrix T or with the transpose of T as follows:
C                TRANS = 'N'         ->  use matrix T
C                TRANS = 'T' or 'C'  ->  use T' (transpose of matrix T)
C             Unchanged on exit.
C
C     M        - INTEGER
C             On entry: number of rows and columns of matrix Ty
C             and number of rows of matrices B and C.
C             Unchanged on exit.
C
C     N        - INTEGER
C             On entry: number of columns of matrices B and C
C             (number of right-hand sides).
C             Unchanged on exit.
C
C     ALPHA    - DOUBLE PRECISION
C             On entry: multiplicative constant.
C             Unchanged on exit.
C
C     UNITD    - CHARACTER*1
C             On entry UNITD specifies whether the diagonal matrix is unit
C             or whether row or column scaling has to be performed, as follows:
C                UNITD = 'U'         ->  unit matrix (no scaling)
C                UNITD = 'L'         ->  scale on the left (row scaling)
C                UNITD = 'R'         ->  scale on the right (column scaling)
C                UNITD = 'B'         ->  scale on the right and on the left
C                                             with D^1/2
C             Unchanged on exit.
C
C     D        - DOUBLE PRECISION array of dimension (M)
C             On entry D specifies the main diagonal of the matrix used
C             for scaling.
C             Unchanged on exit.
C
C     PL       - INTEGER array of dimension (M)
C             On entry PL specifies the row permutation of matrix T
C             (PL(1) == 0 if no permutation).
C             Unchanged on exit.
C
C     FIDT     - CHARACTER*5
C             On entry FIDT defines the format of the input sparse matrix.
C             Unchanged on exit.
C
C     DESCRT   - CHARACTER*1 array of DIMENSION (9)
C             On entry DESCRT describes the characteristics of the input
C             sparse matrix.
C             Unchanged on exit.
C
C
C     T        - DOUBLE PRECISION array of DIMENSION (*)
C             On entry T specifies the values of the input sparse
C             matrix.
C             Unchanged on exit.
C
C     IT1      - INTEGER array of dimension (*)
C             On entry IT1 holds integer information on input sparse
C             matrix.  Actual information will depend on data format used.
C             Unchanged on exit.
C
C     IT2      - INTEGER array of dimension (*)
C             On entry IT2 holds integer information on input sparse
C             matrix.  Actual information will depend on data format used.
C             Unchanged on exit.
C
C     INFOT     - INTEGER array of dimension (10)
C             On entry can hold auxiliary information on input matrices
C             formats or environment of subsequent calls.
C             Might be changed on exit.
C
C     PR       - INTEGER array of dimension (M)
C             On entry PR specifies the column permutation of matrix T
C             (PR(1) == 0 if no permutation).
C             Unchanged on exit.
C
C     B        - DOUBLE PRECISION array of dimension (LDB,*)
C             On entry: matrix of right-hand sides
C             Unchanged on exit.
C
C     LDB      - INTEGER
C             On entry: leading dimension of B.
C             Unchanged on exit.
C
C     BETA     - DOUBLE PRECISION
C             On entry: multiplicative constant.
C             Unchanged on exit.
C
C     C        - DOUBLE PRECISION array of dimension (LDC,*)
C             On exit: solutions of triangular systems
C
C     LDC      - INTEGER
C             On entry: leading dimension of C.
C             Unchanged on exit.
C
C     WORK     - DOUBLE PRECISION array of dimension (LWORK)
C             On entry: work area.
C             On exit INT(WORK(1)) contains the minimum value
C             for LWORK satisfying DCSSM memory requirements.
C
C     LWORK    - INTEGER
C             On entry LWORK specifies the dimension of WORK
C             LWORK should be set as follows:
C                LWORK = (LWORK for DxxxSM) + Pr*M*N + Pl*M*N
C             where Pr �Pl� = 1 if right �left� permutation has to
C             be performed, 0 otherwise.
C             Unchanged on exit.
C
C     IERROR   - INTEGER
C             On exit IERROR contains the value of error flag as follows:
C             IERROR = 0   no error
C             IERROR > 0   warning
C             IERROR < 0   fatal error
C
C     Local Variables
C     ===============
C
C     LWORKM   - INTEGER
C             Minimum work area dimension for DCSSM
C
C     LWORKB   - INTEGER
C             Work area dimension for matrices B, C in subroutines DLPUPD
C
C     LWORKS   - INTEGER
C             Work area dimension for subroutine DSWSM
C
C     P        - INTEGER
C             Pointer to work area
C
C     LP       - LOGICAL
C             LP is true if left permutation is required
C
C     RP       - LOGICAL
C             RP is true if right permutation is required
C
C     Notes
C     =====
C       Some tests have shown that it is more efficient to divide the
C     sparse matrix-dense matrix multiplication step and the dense
C     matrix permutation and update (C <- xxx + BETA C) step.
C     So, the sequence of operations is:
C                Right permutation                      DLPUPD
C                Matrix-Matrix product                  DSWSM
C                Left permutation and update            DLPUPD
C       In order to avoid useless memory transfer, the above scheme is
C     simplified according to whether right and left permutation
C     have to be performed.
C
C
      SUBROUTINE SCSSM(TRANS,M,N,ALPHA,UNITD,D,
     +  PL,FIDT,DESCRT,T,IT1,IT2,INFOT,PR,
     +  B,LDB,BETA,C,LDC,WORK,LWORK,IERROR)
C     .. Scalar Arguments ..
      use psb_const_mod
      use psb_error_mod
      use psb_string_mod
      IMPLICIT NONE
      real(psb_spk_) ALPHA, BETA
      INTEGER          N, LDB, LDC, M, LWORK, IERROR
      CHARACTER        UNITD, TRANS
C     .. Array Arguments ..
      real(psb_spk_) T(*), B(LDB,*), C(LDC,*), D(*), WORK(*)
      INTEGER          IT1(*), IT2(*), INFOT(*), PL(*), PR(*)
      CHARACTER        DESCRT*11, FIDT*5
C     .. Local Scalars ..
      INTEGER          LWORKM, LWORKB, LWORKS, P, ERR_ACT
      LOGICAL          LP, RP
C     .. Local Array..
      INTEGER           INT_VAL(5)
      CHARACTER*30      STRINGS(2)
      CHARACTER         NAME*20
      integer         :: debug_level, debug_unit


C
C       Check for argument errors
C
      IERROR = 0
      NAME = 'DCSSM'
      CALL FCPSB_ERRACTIONSAVE(ERR_ACT)
      debug_unit  = psb_get_debug_unit()
      debug_level = psb_get_debug_level()

      IF (M.LT.0) THEN
        IERROR = 10
        INT_VAL(1) = 2
        INT_VAL(2) = M
      ELSE IF (N.LT.0) THEN
        IERROR = 10
        INT_VAL(1) = 3
        INT_VAL(2) = N
      ELSE IF (psb_toupper(TRANS).NE.'T' .AND.
     +    psb_toupper(TRANS).NE.'N' .AND.
     +    psb_toupper(TRANS).NE.'C') THEN
        IERROR = 40
        INT_VAL(1) = 1
        STRINGS(1) = TRANS//'\0'
      ELSE IF (psb_toupper(UNITD).NE.'U' .AND.
     +    psb_toupper(UNITD).NE.'L' .AND.
     +    psb_toupper(UNITD).NE.'R' .AND.
     +    psb_toupper(UNITD).NE.'B') THEN
        IERROR = 40
        INT_VAL(1) = 5
        STRINGS(1) = UNITD//'\0'
      ELSE IF (LDB.LT.M) THEN
        IERROR = 50
        INT_VAL(1) = 16
        INT_VAL(2) = 2
        INT_VAL(3) = LDB
        INT_VAL(4) = M
      ELSE IF (LDC.LT.M) THEN
        IERROR = 50
        INT_VAL(1) = 19
        INT_VAL(2) = 2
        INT_VAL(3) = LDC
        INT_VAL(4) = M
      ENDIF

C
C     Error handling
C
      IF(IERROR.NE.0) THEN
        CALL FCPSB_ERRPUSH(IERROR,NAME,INT_VAL)
        GOTO 9999
      ENDIF

C
C     Inizializations
C
      LP = PL(1).NE.0
      RP = PR(1).NE.0
      LWORKB = M*N
      LWORKM = 0
      IF (RP) LWORKM = LWORKB
      IF (LP) LWORKM = LWORKM + LWORKB
      P = LWORKB+1
      IF (LWORK.LT.LWORKM) THEN
        IERROR = 60
        INT_VAL(1) = 21
        INT_VAL(2) = LWORKM
        INT_VAL(3) = LWORK
        CALL FCPSB_ERRPUSH(IERROR,NAME,INT_VAL)
        GOTO 9999
      ENDIF
      LWORKS = LWORK - LWORKM

C     Check for M, N
C
      IF (M.LE.0 .OR. N.LE.0) THEN
        GOTO 9999
      ENDIF
C
C     Switching on xP
C
      IF     (LP .AND. RP) THEN
C
C        Both right and left permutations required
C
        if (debug_level >= psb_debug_serial_comp_)
     +    write(debug_unit,*) trim(name),': RP LP ',m,n,ierror

        CALL SLPUPD(M,N,PR,B,LDB,BETA,WORK,M)
        CALL SSWSM(TRANS,M,N,ALPHA,UNITD,D,FIDT,DESCRT,T,IT1,IT2,      
     &    INFOT,WORK,M,SZERO,WORK(P),M,WORK(P+LWORKB),LWORK,IERROR)
        LWORKS = INT(WORK(P+LWORKB))
        IF(IERROR .NE. 0) THEN
          IF (IERROR.EQ.3010) THEN
            CALL FCPSB_ERRPUSH(IERROR,NAME,INT_VAL)
            GOTO 9999
          ENDIF
        ENDIF
        CALL SLPUPD(M,N,PL,WORK(P),M,BETA,C,LDC)
      ELSE IF(.NOT.LP .AND. RP) THEN
C
C        Only right permutation required
C
        if (debug_level >= psb_debug_serial_comp_)
     +    write(debug_unit,*) trim(name),': RP NLP ',m,n,ierror

        CALL SLPUPD(M,N,PR,B,LDB,BETA,WORK,M)
        CALL SSWSM(TRANS,M,N,ALPHA,UNITD,D,FIDT,DESCRT,T,IT1,IT2,      
     &    INFOT,WORK,M,SZERO,C,LDC,WORK(P),LWORK,IERROR)
        LWORKS = INT(WORK(P))
        IF(IERROR .NE. 0) THEN
          NAME = 'DCSSM\0'
          IF (IERROR.EQ.3010) THEN
            CALL FCPSB_ERRPUSH(IERROR,NAME,INT_VAL)
            GOTO 9999
          ENDIF
        ENDIF
      ELSE IF(.NOT.RP .AND. LP) THEN
C
C        Only left permutation required
C
        if (debug_level >= psb_debug_serial_comp_)
     +    write(debug_unit,*) trim(name),': NRP LP ',m,n,ierror
        CALL SSWSM(TRANS,M,N,ALPHA,UNITD,D,FIDT,DESCRT,T,IT1,IT2,      
     &    INFOT,B,LDB,BETA,WORK,M,WORK(P),LWORK,IERROR)
        LWORKS = INT(WORK(P))
        IF(IERROR .NE. 0) THEN
          IF (IERROR.EQ.3010) THEN
            CALL FCPSB_ERRPUSH(IERROR,NAME,INT_VAL)
            GOTO 9999
          ENDIF
        ENDIF
        CALL SLPUPD(M,N,PL,WORK,M,BETA,C,LDC)
      ELSE IF(.NOT.RP .AND. .NOT.LP) THEN
C
C        Only triangular systems solver required
C
        if (debug_level >= psb_debug_serial_comp_)
     +    write(debug_unit,*) trim(name),': NRP NLP ',m,n,ierror
        CALL SSWSM(TRANS,M,N,ALPHA,UNITD,D,FIDT,DESCRT,T,IT1,IT2,      
     &    INFOT,B,LDB,BETA,C,LDC,WORK,LWORK,IERROR)
        LWORKS = INT(WORK(1))
        IF(IERROR .NE. 0) THEN
          IF (IERROR.EQ.3010) THEN
            CALL FCPSB_ERRPUSH(IERROR,NAME,INT_VAL)
            GOTO 9999
          ENDIF
        ENDIF
      ENDIF

C
C     Return minimum workarea dimension
C
      LWORKM = LWORKM + LWORKS
      WORK(1) = REAL(LWORKM)
      CALL FCPSB_ERRACTIONRESTORE(ERR_ACT)
      RETURN

 9999 CONTINUE
      CALL FCPSB_ERRACTIONRESTORE(ERR_ACT)

      IF ( ERR_ACT .NE. 0 ) THEN 
        CALL FCPSB_SERROR()
        RETURN
      ENDIF

      RETURN
      END