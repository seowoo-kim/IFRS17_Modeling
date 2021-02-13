```sql

SET TIMING ON;

SELECT * FROM CF_SIMU.GOC_BY_CSM_GN_UNT_INF;
SELECT * FROM CF_SIMU.CSM_DP_RATE_INF;

COMMIT;
ROLLBACK;

--0�̾����� 1�� ������. ���(������ �����ν��̳�)�� ���� ���� ������� �����Ʈ���� ���� ���ö�, �и�� ���ڿ� ���� ���� ���� 1�̵�.
--��ô� ������ ���� ���°�� ������� ���� NULL�� �����Ե�. NULL�� 0���� �����ϰ� CSM_DP_RATE �� ���Ҷ� ���ڿ� 0���� ������� ����ص� 0�� �Ǳ⶧���� 0�� 1���� ���� 1�ε����� ������.

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
                    A.IFRS_WRK_SECD, A.PROG_YYMM, A.PF_SECD, A.SAME_GRP_TYP_COD, A.GOC_TYP_COD, MONTHS_BETWEEN(TO_DATE(A.PROG_YYMM||'01'), TO_DATE('201903'||'01')) AS PROG_IDX    --���б⸻ �Է� �ʿ���
                    , SUM(CASE WHEN (A.MVMT_SECD = '1000' AND A.PROG_YYMM = A.IFRS_ACTS_YYMM) OR (A.MVMT_SECD <> '1000' AND ADD_MONTHS(TO_DATE(A.IFRS_ACTS_YYMM||'01'), 1) = TO_DATE(A.PROG_YYMM||'01')) THEN A.GN_UNT_VL END) AS UNT_VL
                    , SUM(CASE WHEN A.MVMT_SECD = '1090' AND A.IFRS_ACTS_YYMM ='201904' AND A.IFRS_ACTS_YYMM = A.PROG_YYMM THEN A.GN_UNT_CVAL END) AS GN_UNT_CVAL       --�̷����� ����� ȸ������ �����Ʈ �Է�
                    , MAX(CASE WHEN A.MVMT_SECD = '1090' AND A.IFRS_ACTS_YYMM ='201904' THEN A.INIT_RCGNT_DCRT END) AS INIT_RCGNT_DCRT                                  --�̷����� ����� ȸ������ �����Ʈ �Է�
              FROM CF_SIMU.GOC_BY_CSM_GN_UNT_INF A 
              WHERE (A.IFRS_ACTS_YYMM, A.MVMT_SECD) IN (('201904', '1000'), ('201904','1090'), ('201903','9999')) AND A.IFRS_WRK_SECD ='E' AND A.PROG_YYMM <= '201904'   --���⼭ �̷������������ �� �����̿�, ��ȸ���� �����ν� �׸��� �������� CSM�󰢴�� ������� MVMT Ư���ʿ�
              GROUP BY A.IFRS_WRK_SECD, A.PROG_YYMM, A.PF_SECD, A.SAME_GRP_TYP_COD, A.GOC_TYP_COD 
              ) A 
          ) A
      GROUP BY A.IFRS_WRK_SECD, A.PF_SECD, A.SAME_GRP_TYP_COD, A.GOC_TYP_COD 
      ) A
;

COMMIT;

```