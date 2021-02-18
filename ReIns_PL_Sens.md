```sql

SET TIMING ON;


--###데이터 확인

--INPUT
SELECT * FROM CF_SIMU.BZ_PL_RSUR_CED_INF WHERE ROWNUM < 100;              
--사업계획재보험출재정보, 소스 1
SELECT * FROM CF_SIMU.BZ_PL_EXP_PFMC_INF WHERE ROWNUM < 100;              
--사업계획예상실적정보, 소스2

--OUTPUT
SELECT * FROM CF_SIMU.CED_CVT_COD_BY_RSUR_BZ_PL_RTO_INF WHERE IFRS_ACTS_YYMM ='201812' ORDER BY 1,2,3 AND ROWNUM < 100;    
--출재협약코드별재보험사업계획비율정보


--###업무요건
--신계약물량 민감도 "NB_Sens.md"와 업무요건이 유사함. 다만 원수보험사의 계약자 대상의 물량만이 아니라, 원수보험사의 재보험자 대상의 출재 물량에 관한 내용을 포함함.
--재보험 예상실적 테이블은 분석 집계 기준 동일한 cohort, 채널의 상품군이 첫 판매 시점 이후 향후 경과함에 따라 기간별로 얼마만큼 물량이 들어올지에 대한 시나리오 내용이다.
--사업계획재보험출재정보 테이블은 분석 대상이 되는 cohort의 기본 현금흐름정보를 담고 있다.
--두 테이블을 조인하면서 base 현금흐름을 경과시점별로 들어올 물량의 민감도를 곱해서 누적합산하되, 평가시점으로부터 2년치만 사용하도록 고정함.
--검증case 반드시 살펴서 사용자 수기 시나리오를 받는 것에 대한 정합성유지를 할것.


--쿼리 수행 전 실행계획을 확인하기 위한 실행계획 생성과, plan table SELECT
--SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', NULL, 'OUTLINE'));
--EXPLAIN PLAN FOR


--##INSERT

INSERT /*+ENABLE_PARALLEL_DML PARALLEL(Z 16)*/ 
INTO CF_SIMU.CED_CVT_COD_BY_RSUR_BZ_PL_RTO_INF Z 
SELECT /*+PARALLEL(A 16) PARALLEL(B 16) SWAP_JOIN_INPUTS(A) ORDERED PQ_DISTRIBUTE(A HASH HASH)*/ 
      B.IFRS_ACTS_YYMM
    , B.CED_CVT_COD AS RSUR_TRT_PK
    , A.APPT_YYMM
    , NVL(SUM(B.CED_RKPREM * A.COL_VL / DECODE(B.GSPRE_GROUP, 0, NULL, B.GSPRE_GROUP)) 
             / DECODE(SUM(B.CED_RKPREM), 0, NULL, SUM(B.CED_RKPREM))
         , 0) AS WRBZ_BZ_PL_RTO
FROM
    (SELECT /*+PARALLEL(A 16)*/ 
          COL_CHN_DTLCD
        , PRD_GRP_ALFA
        , PYCYC_COD
        , TO_CHAR(ADD_MONTHS(TO_DATE(CLO_YYMM||'01'), PROG_IDX), 'YYYYMM') AS APPT_YYMM
        , COL_VL 
    FROM
        (SELECT /*+PARALLEL(A 16)*/ 
              CLO_YYMM
            , COL_CHN_DTLCD
            , PRD_GRP_ALFA
            , PYCYC_COD
            , CAST(REPLACE(REPLACE(PROG_YYMM, 'COLM_'), '_VL') AS INTEGER) AS PROG_IDX
            , COL_VL 
        FROM
            (SELECT /*+FULL(A) PARALLEL(A 16)*/ * 
            FROM CF_SIMU.BZ_PL_EXP_PFMC_INF A 
            WHERE CLO_YYMM = '201812' AND SCNR_NUM =0 AND LAST_HIS_YN ='1' AND DEL_YN ='0'  --사용하려는 민감도 데이터의 마감년월 201812을 입력 받음.
            ) A
        UNPIVOT(COL_VL FOR PROG_YYMM IN(COLM_1_VL, COLM_2_VL, COLM_3_VL, COLM_4_VL, COLM_5_VL, COLM_6_VL, COLM_7_VL, COLM_8_VL, COLM_9_VL, COLM_10_VL 
                                    , COLM_11_VL, COLM_12_VL, COLM_13_VL, COLM_14_VL, COLM_15_VL, COLM_16_VL, COLM_17_VL, COLM_18_VL, COLM_19_VL, COLM_20_VL 
                                    , COLM_21_VL, COLM_22_VL, COLM_23_VL, COLM_24_VL, COLM_25_VL, COLM_26_VL, COLM_27_VL, COLM_28_VL, COLM_29_VL, COLM_30_VL 
                                    , COLM_31_VL, COLM_32_VL, COLM_33_VL, COLM_34_VL, COLM_35_VL, COLM_36_VL, COLM_37_VL, COLM_38_VL, COLM_39_VL, COLM_40_VL 
                                    , COLM_41_VL, COLM_42_VL, COLM_43_VL, COLM_44_VL, COLM_45_VL, COLM_46_VL, COLM_47_VL, COLM_48_VL, COLM_49_VL, COLM_50_VL 
                                    , COLM_51_VL, COLM_52_VL, COLM_53_VL, COLM_54_VL, COLM_55_VL, COLM_56_VL, COLM_57_VL, COLM_58_VL, COLM_59_VL, COLM_60_VL
                                    , COLM_61_VL, COLM_62_VL, COLM_63_VL, COLM_64_VL, COLM_65_VL, COLM_66_VL, COLM_67_VL, COLM_68_VL, COLM_69_VL, COLM_70_VL
                                    , COLM_71_VL, COLM_72_VL, COLM_73_VL, COLM_74_VL, COLM_75_VL, COLM_76_VL, COLM_77_VL, COLM_78_VL, COLM_79_VL, COLM_80_VL
                                    , COLM_81_VL, COLM_82_VL, COLM_83_VL, COLM_84_VL, COLM_85_VL, COLM_86_VL, COLM_87_VL, COLM_88_VL, COLM_89_VL, COLM_90_VL
                                    , COLM_91_VL, COLM_92_VL, COLM_93_VL, COLM_94_VL, COLM_95_VL, COLM_96_VL, COLM_97_VL, COLM_98_VL, COLM_99_VL, COLM_100_VL
                                    , COLM_101_VL, COLM_102_VL, COLM_103_VL, COLM_104_VL, COLM_105_VL, COLM_106_VL, COLM_107_VL, COLM_108_VL, COLM_109_VL, COLM_110_VL
                                    , COLM_111_VL, COLM_112_VL, COLM_113_VL, COLM_114_VL, COLM_115_VL, COLM_116_VL, COLM_117_VL, COLM_118_VL, COLM_119_VL, COLM_120_VL))
        ) A
    WHERE ADD_MONTHS(TO_DATE(CLO_YYMM||'01'), PROG_IDX) > TO_DATE('201812'||'01') 
        AND ADD_MONTHS(TO_DATE(CLO_YYMM||'01'), PROG_IDX) < ADD_MONTHS(TO_DATE('201812'||'01'), 24 + 1)
        --조건절의 '201812'가 데이터의 마감년월이자 사용자가 지정하는 기준시점이 됨. 기준시점의 첫달부터 총 24개월동안 산출함. 24 + 1 부분의 수정으로 손익률계산 단위기간(현 24개월)도 수정 가능함.
    ) A,   
    (SELECT /*+PARALLEL(A 16)*/ 
          IFRS_ACTS_YYMM
        , COL_CHN_DTLCD
        , PRD_GRP_ALFA
        , PYCYC_COD
        , CED_CVT_COD
        , CED_RKPREM
        , MAX(GSPRE) OVER(PARTITION BY COL_CHN_DTLCD, PRD_GRP_ALFA, PYCYC_COD) AS GSPRE_GROUP
    FROM
        (SELECT /*+FULL(A) PARALLEL(A 16)*/ 
              IFRS_ACTS_YYMM
            , COL_CHN_DTLCD
            , PRD_GRP_ALFA
            , PYCYC_COD
            , CED_CVT_COD
            , SUM(CASE WHEN CED_CVT_COD = 'BASE' THEN GSPRE END) AS GSPRE   --재보험의 출재협약이 기본인 경우에만 영업보험료(GSPRE)와 출재위험보험료(CED_RKPREM)을 기준으로 손익률을 계산함.
            , SUM(CASE WHEN CED_CVT_COD <> 'BASE' THEN CED_RKPREM END) AS CED_RKPREM 
        FROM CF_SIMU.BZ_PL_RSUR_CED_INF A WHERE IFRS_ACTS_YYMM = '201812' AND IFRS_WRK_SECD ='E' --사용하려는 현금흐름데이터의 마감년월을 입력받음. 민감도정보와 동일한 마감년월일 필요없음.
        GROUP BY IFRS_ACTS_YYMM, COL_CHN_DTLCD, PRD_GRP_ALFA, PYCYC_COD, CED_CVT_COD) A
    ) B --위의 A 부분의 INLINE VIEW에 같이 적용해주는 것으로 함. 
WHERE B.CED_CVT_COD <> 'BASE' 
    AND A.COL_CHN_DTLCD = B.COL_CHN_DTLCD 
    AND A.PRD_GRP_ALFA = B.PRD_GRP_ALFA 
    AND A.PYCYC_COD = B.PYCYC_COD
GROUP BY B.IFRS_ACTS_YYMM, B.CED_CVT_COD, A.APPT_YYMM

;

--ROLLBACK;
COMMIT;



--##DEBUG, 데이터정합성 확인과정
--테스트환경에서는 데이터가 많지 않아 별도의 힌트작성이나 병렬유도 없이 작성함.
--cf테이블의 산출키와 사용자가 입력한 민감도의 키단위가 매칭되는지 확인하고, 인조pk로 정합성을 관리하도록 하였으나 이외의 중첩인스턴스나 중복데이터 있는지 확인하기 위함임.


--###검증CASE 1
--인조PK와는 별개로 중복값 있는지 확인함. 어플리케이션 내의 LOOP OUT 조건임.
SELECT 
      COL_CHN_DTLCD
    , PRD_GRP_ALFA
    , PYCYC_COD 
FROM CF_SIMU.BZ_PL_EXP_PFMC_INF 
WHERE CLO_YYMM = '201908' AND SCNR_NUM =1 AND LAST_HIS_YN ='1' AND DEL_YN ='0' 
GROUP BY COL_CHN_DTLCD, PRD_GRP_ALFA, PYCYC_COD 
HAVING COUNT(*) > 1;


--###검증CASE 2
--조인실패 CHECK, BZ_PL_EXP_PFMC_INF 기준으로 계약자정보 INFORCE에서 받는 모델 값의 차이를 확인함.
SELECT 
      COL_CHN_DTLCD
    , PRD_GRP_ALFA
    , PYCYC_COD 
FROM 
    (SELECT 
          A.COL_CHN_DTLCD
        , A.PRD_GRP_ALFA
        , A.PYCYC_COD
        , B.COL_CHN_DTLCD AS NULL_CHK
    FROM
        (SELECT 
              COL_CHN_DTLCD
            , PRD_GRP_ALFA
            , PYCYC_COD 
        FROM CF_SIMU.BZ_PL_EXP_PFMC_INF 
        WHERE CLO_YYMM = '201908' AND SCNR_NUM =1 AND LAST_HIS_YN ='1' AND DEL_YN ='0'
        ) A,
        (SELECT DISTINCT 
              COL_CHN_DTLCD
            , PRD_GRP_ALFA
            , PYCYC_COD 
        FROM CF_SIMU.BZ_PL_RSUR_CED_INF 
        WHERE IFRS_ACTS_YYMM ='202001' AND IFRS_WRK_SECD ='E'
        ) B 
    WHERE A.COL_CHN_DTLCD = B.COL_CHN_DTLCD (+)
        AND A.PRD_GRP_ALFA = B.PRD_GRP_ALFA (+)
        AND A.PYCYC_COD = B.PYCYC_COD (+))
WHERE NULL_CHK IS NULL 
ORDER BY 1,2,3;


--###검증CASE 3
--조인실패 CHECK, BZ_PL_RSUR_CED_INF 기준으로 민감도 값이 없는지 확인함.
SELECT
      COL_CHN_DTLCD
    , PRD_GRP_ALFA
    , PYCYC_COD 
FROM 
    (SELECT 
          B.COL_CHN_DTLCD
        , B.PRD_GRP_ALFA
        , B.PYCYC_COD
        , A.COL_CHN_DTLCD AS NULL_CHK
    FROM
        (SELECT 
              COL_CHN_DTLCD
            , PRD_GRP_ALFA
            , PYCYC_COD 
        FROM CF_SIMU.BZ_PL_EXP_PFMC_INF 
        WHERE CLO_YYMM = '201908' AND SCNR_NUM =1 AND LAST_HIS_YN ='1' AND DEL_YN ='0'
        ) A,
        (SELECT DISTINCT 
              COL_CHN_DTLCD
            , PRD_GRP_ALFA
            , PYCYC_COD 
        FROM CF_SIMU.BZ_PL_RSUR_CED_INF 
        WHERE IFRS_ACTS_YYMM ='202001' AND IFRS_WRK_SECD ='E'
        ) B 
    WHERE B.COL_CHN_DTLCD = A.COL_CHN_DTLCD (+)
        AND B.PRD_GRP_ALFA = A.PRD_GRP_ALFA (+)
        AND B.PYCYC_COD = A.PYCYC_COD (+))
WHERE NULL_CHK IS NULL 
ORDER BY 1,2,3;



```


