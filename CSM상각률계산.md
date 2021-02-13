```sql

SET TIMING ON;

SELECT * FROM CF_SIMU.GOC_BY_CSM_GN_UNT_INF;
SELECT * FROM CF_SIMU.CSM_DP_RATE_INF;

COMMIT;
ROLLBACK;

--0이었지만 1로 변경함. 기시(보유나 최초인식이나)에 값이 없고 당월현가 무브먼트에만 값이 들어올때, 분모와 분자에 같은 값이 들어가서 1이됨.
--기시는 있지만 예상에 없는경우 당월현가 값에 NULL이 들어오게됨. NULL을 0으로 변경하고 CSM_DP_RATE 값 구할때 분자에 0들어가면 어떤식으로 계산해도 0이 되기때문에 0을 1에서 빼면 1로들어가도록 변경함.

--SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', NULL, 'OUTLINE'));
--EXPLAIN PLAN FOR

INSERT /*+ ENABLE_PARALLEL_DML APPEND PARALLEL(Z 10) PQ_DISTRIBUTE(Z NONE) NO_GATHER_OPTIMIZER_STATISTICS */ INTO CF_SIMU.CSM_DP_RATE_INF Z
  SELECT /*+FULL(A) PARALLEL(A 10) */
      A.MAX_PROG_YYMM               AS IFRS_ACTS_YYMM
      , A.IFRS_WRK_SECD             AS IFRS_WRK_SECD
      , A.PF_SECD                   AS PF_SECD
      , A.SAME_GRP_TYP_COD          AS SAME_GRP_TYP_COD
      , A.GOC_TYP_COD               AS GOC_TYP_COD
      , A.MAX_PROG_YYMM             AS PROG_YYMM
      , '0'                         AS TMP_PK
      , 1 - NVL(DECODE(A.UNT_CVAL / DECODE((((A.UNT_VL_3) * (1 + A.RATE_3) + A.UNT_VL_2) * (1+ A.RATE_2) + A.UNT_VL_1) * (1 + A.RATE_1) + A.UNT_CVAL, 0, NULL, 
        (((A.UNT_VL_3) * (1 + A.RATE_3) + A.UNT_VL_2) * (1+ A.RATE_2) + A.UNT_VL_1) * (1 + A.RATE_1) + A.UNT_CVAL), 0, 1, 
        A.UNT_CVAL / DECODE((((A.UNT_VL_3) * (1 + A.RATE_3) + A.UNT_VL_2) * (1+ A.RATE_2) + A.UNT_VL_1) * (1 + A.RATE_1) + A.UNT_CVAL, 0, NULL, 
        (((A.UNT_VL_3) * (1 + A.RATE_3) + A.UNT_VL_2) * (1+ A.RATE_2) + A.UNT_VL_1) * (1 + A.RATE_1) + A.UNT_CVAL)), 0)
                                  AS CSM_DP_RATE                                  
  FROM
      (SELECT /*+FULL(A) PARALLEL(A 10) */
            A.IFRS_WRK_SECD, A.PF_SECD, A.SAME_GRP_TYP_COD, A.GOC_TYP_COD, MAX(A.PROG_YYMM) AS MAX_PROG_YYMM
            , NVL(SUM(A.GN_UNT_CVAL), 0) AS UNT_CVAL
            , NVL(SUM(A.UNT_VL_1), 0)    AS UNT_VL_1
            , NVL(SUM(A.UNT_VL_2), 0)    AS UNT_VL_2
            , NVL(SUM(A.UNT_VL_3), 0)    AS UNT_VL_3
            , CASE WHEN MAX(A.PROG_IDX) >= 3 THEN NVL(MAX(A.RATE_1), 0) ELSE 0 END      AS RATE_1
            , CASE WHEN MAX(A.PROG_IDX) >= 2 THEN NVL(MAX(A.RATE_2), 0) ELSE 0 END      AS RATE_2
            , CASE WHEN MAX(A.PROG_IDX) >= 1 THEN NVL(MAX(A.RATE_3), 0) ELSE 0 END      AS RATE_3
      FROM
          (SELECT /*+FULL(A) PARALLEL(A 10) */ 
                A.*
                , CASE WHEN A.PROG_IDX = 3 THEN A.UNT_VL END                AS UNT_VL_1
                , CASE WHEN A.PROG_IDX = 2 THEN A.UNT_VL END                AS UNT_VL_2
                , CASE WHEN A.PROG_IDX = 1 THEN A.UNT_VL END                AS UNT_VL_3
                , A.INIT_RCGNT_DCRT                                         AS RATE_1
                , A.INIT_RCGNT_DCRT                                         AS RATE_2
                , A.INIT_RCGNT_DCRT                                         AS RATE_3
          FROM
              (SELECT /*+FULL(A) PARALLEL(A 10) */ 
                    A.IFRS_WRK_SECD, A.PROG_YYMM, A.PF_SECD, A.SAME_GRP_TYP_COD, A.GOC_TYP_COD, MONTHS_BETWEEN(TO_DATE(A.PROG_YYMM||'01'), TO_DATE('201903'||'01')) AS PROG_IDX    --전분기말 입력 필요함
                    , SUM(CASE WHEN (A.MVMT_SECD = '1000' AND A.PROG_YYMM = A.IFRS_ACTS_YYMM) OR (A.MVMT_SECD <> '1000' AND ADD_MONTHS(TO_DATE(A.IFRS_ACTS_YYMM||'01'), 1) = TO_DATE(A.PROG_YYMM||'01')) THEN A.GN_UNT_VL END) AS UNT_VL
                    , SUM(CASE WHEN A.MVMT_SECD = '1090' AND A.IFRS_ACTS_YYMM ='201904' AND A.IFRS_ACTS_YYMM = A.PROG_YYMM THEN A.GN_UNT_CVAL END) AS GN_UNT_CVAL       --미래현가 사용할 회계년월과 무브먼트 입력
                    , MAX(CASE WHEN A.MVMT_SECD = '1090' AND A.IFRS_ACTS_YYMM ='201904' THEN A.INIT_RCGNT_DCRT END) AS INIT_RCGNT_DCRT                                  --미래현가 사용할 회계년월과 무브먼트 입력
              FROM CF_SIMU.GOC_BY_CSM_GN_UNT_INF A 
              WHERE (A.IFRS_ACTS_YYMM, A.MVMT_SECD) IN (('201904', '1000'), ('201904','1090'), ('201903','9999')) AND A.IFRS_WRK_SECD ='E' AND A.PROG_YYMM <= '201904'   --여기서 미래보장단위현가 및 이율이용, 당회계년월 최초인식 그리고 경과년월별 CSM상각대상 보장단위 MVMT 특정필요
              GROUP BY A.IFRS_WRK_SECD, A.PROG_YYMM, A.PF_SECD, A.SAME_GRP_TYP_COD, A.GOC_TYP_COD 
              ) A 
          ) A
      GROUP BY A.IFRS_WRK_SECD, A.PF_SECD, A.SAME_GRP_TYP_COD, A.GOC_TYP_COD 
      ) A
;

COMMIT;

```