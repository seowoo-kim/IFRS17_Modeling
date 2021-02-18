```sql

SET TIMING ON;

--###데이터 확인

--INPUT 1.현금흐름테이블(CF), 2.민감도-SENSTIVITY(PARTITIONED ONE, FINAL ONE)
SELECT * FROM CF_SIMU.OUTPUT_T14 WHERE ROWNUM < 100;    --소스1 : 그룹별사업계획현금흐름산출내역, MIG_CLO_YYMM, SYSPART컬럼 묶어서 LIST PARTITIONING함.
SELECT * FROM CF_SIMU.WRBZ_BZ_PL_SENSTVT_USER_BY_INF;   --소스2-PARTITIONED ONE: 신계약사업계획민감도유저별정보, A~K SYSTEM PARTITIONED 차후 사번등의 유저별 파티션 지정을 예정함.
SELECT * FROM CF_SIMU.WRBZ_BZ_PL_SENSTVT_INF;           --소스2-FINAL ONE: 신계약사업계획민감도정보, 유저별테스트 이후 최종 제출용으로 남길 자료로 축적함.

--OUTPUT
SELECT * FROM CF_SIMU.OUTPUT_T14_RST;                   --그룹별사업계획현금흐름산출내역결과


--###업무요건
--민감도정보 테이블은 분석 집계 기준 동일한 cohort, 채널의 상품군이 첫 판매 시점 이후 향후 경과함에 따라 기간별로 얼마만큼 물량이 들어올지에 대한 내용이다.
--현금흐름산출내역 테이블은 분석 대상이 되는 cohort의 기본 현금흐름정보를 담고 있다.
--두 테이블을 조인하면서 base 현금흐름을 경과시점별로 들어올 물량의 민감도를 곱해서 기간을 미루면서 누적합산하여
--해당 집단의 소멸기간까지 전체 현금흐름을 구하는 것이 목표이다.


--업무 목적에 따라서 소스2의 사용자별 sample partitioned나 filnal 정보를 사용함.
--USER TABLE INSERT 예시, WRBZ_BZ_PL_SENSTVT_USER_BY_INF 와 WRBZ_BZ_PL_SENSTVT_INF의 레이아웃은 동일하므로 유저별로 정보를 받아와서 수정하여 민감도 테스트해보는 방식으로 수행함.
INSERT INTO CF_SIMU.WRBZ_BZ_PL_SENSTVT_USER_BY_INF PARTITION(A) 
SELECT * 
FROM CF_SIMU.WRBZ_BZ_PL_SENSTVT_INF 
WHERE SCNR_NUM =2
;
-- COMMIT;


--###주의해야할 점
--SYSTEM_PARTITION을 이용한 함수처리와 카티전 조인 이후의 INSERT에서, 당 시스템파티션에 데이터가 없다면 0 ROW INSERTED가 아니라 ORA-000600 ERROR로 비정상종료되므로 주의.
--반드시 사용하는 소스테이블에서 해당 파티션의 데이터가 존재하는지 확인할것, 어플리케이션 내부에는 확인후 경고문구 띄우도록 처리함.



--쿼리 수행 전 실행계획을 확인하기 위한 실행계획 생성과, plan table SELECT
--SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', NULL, 'OUTLINE'));
--EXPLAIN PLAN FOR



--아래는 최종 민감도정보를 이용하여 작성하였음. WRBZ_BZ_PL_SENSTVT_INF를 WRBZ_BZ_PL_SENSTVT_USER_BY_INF PARTITION(##)로만 변경해도 동일한 작동 함.

INSERT /*+ENABLE_PARALLEL_DML APPEND PARALLEL(Z 16) PQ_DISTRIBUTE(Z NONE)*/ 
INTO CF_SIMU.OUTPUT_T14_RST Z
SELECT /*+PARALLEL(A 16)*/ 
      MIG_CLO_YYMM, SYS_PART
    , INFLOW_IDX
    , OPEXP_SHAR_CHN_SECD
    , CHN_DTLCD
    , PRD_GRP_ALFA
    , PYCYC_COD
    , SCNR_NUM
    , FLOOR(PROJ_YM_JOIN / 12)                      AS PROJ_Y
    , PROJ_YM_JOIN                                  AS PROJ_YM
    , SUM(CF_PREM_INC)                              AS CF_PREM_INC
    , SUM(CF_NET_IMF_INC)                           AS CF_NET_IMF_INC
    , SUM(CF_GMXB_NET_INC)                          AS CF_GMXB_NET_INC
    , SUM(CF_INVEST_INC)                            AS CF_INVEST_INC
    , SUM(CF_EV_CLAIM)                              AS CF_EV_CLAIM
    , SUM(CF_SURR_BEN)                              AS CF_SURR_BEN
    , SUM(CF_MAT_BEN)                               AS CF_MAT_BEN
    , SUM(CF_CLAIM_ANTY)                            AS CF_CLAIM_ANTY
    , SUM(CF_PARTWITH)                              AS CF_PARTWITH
    , SUM(CF_LIV_BEN)                               AS CF_LIV_BEN
    , SUM(CF_TRANS_TO_SA)                           AS CF_TRANS_TO_SA
    , SUM(CF_COMMISSION)                            AS CF_COMMISSION
    , SUM(CF_ACQ_TOT)                               AS CF_ACQ_TOT
    , SUM(CF_MNT_TOT)                               AS CF_MNT_TOT
    , SUM(CF_COLL_EXP)                              AS CF_COLL_EXP
    , SUM(CF_OTH_EXP)                               AS CF_OTH_EXP
    , SUM(CF_RES_INC)                               AS CF_RES_INC
    , SUM(CF_DAC_INC)                               AS CF_DAC_INC
    , SUM(CF_RESERVE)                               AS CF_RESERVE
    , SUM(CF_SA)                                    AS CF_SA
    , SUM(CF_SURR_RESERVE)                          AS CF_SURR_RESERVE
    , SUM(CF_UNEARN_RESERVE)                        AS CF_UNEARN_RESERVE
    , SUM(CF_GMDB_RES)                              AS CF_GMDB_RES
    , SUM(CF_GMAB_RES)                              AS CF_GMAB_RES
    , SUM(CF_DAC)                                   AS CF_DAC
    , SUM(CF_POLICY_UNALPHA_IF)                     AS CF_POLICY_UNALPHA_IF
    , SUM(CF_REP_COLL_ALPHA_IF)                     AS CF_REP_COLL_ALPHA_IF
    , SUM(CF_SOP_COLL_ALPHA_IF)                     AS CF_SOP_COLL_ALPHA_IF
    , SUM(CF_SOP_COLL_BETA_IF)                      AS CF_SOP_COLL_BETA_IF
    , SUM(CF_SOP_COLL_GAMMA_IF)                     AS CF_SOP_COLL_GAMMA_IF
    , SUM(CF_SOP_SAV_PREM_IF)                       AS CF_SOP_SAV_PREM_IF
    , SUM(CF_SOP_RISK_PREM_IF)                      AS CF_SOP_RISK_PREM_IF
    , SUM(CF_SOP_RISK_PREM_LWL_ADD_IF)              AS CF_SOP_RISK_PREM_LWL_ADD_IF
    , SUM(CF_ACQ_EXP)                               AS CF_ACQ_EXP
    , SUM(CF_ACQ_ND_EXP)                            AS CF_ACQ_ND_EXP
    , SUM(CF_MNT_P_EXP)                             AS CF_MNT_P_EXP
    , SUM(CF_MNT_NP_EXP)                            AS CF_MNT_NP_EXP
    , SUM(CF_CLAIM_TOT)                             AS CF_CLAIM_TOT
    , SUM(CF_RES_AT_DTH)                            AS CF_RES_AT_DTH
    , SUM(CF_RES_AT_SURR)                           AS CF_RES_AT_SURR
    , SUM(CF_IMF_INCOME)                            AS CF_IMF_INCOME
    , SUM(CF_IMF_OUTGO)                             AS CF_IMF_OUTGO
    , SUM(CF_GMXB_INC)                              AS CF_GMXB_INC
    , SUM(CF_CLAIM_GMDB)                            AS CF_CLAIM_GMDB
    , SUM(CF_CLAIM_GMAB)                            AS CF_CLAIM_GMAB
    , SUM(CF_RBC_RBC_CRED)                          AS CF_RBC_RBC_CRED
    , SUM(CF_RBC_RBC_MARKET)                        AS CF_RBC_RBC_MARKET
    , SUM(CF_RBC_RBC_INS)                           AS CF_RBC_RBC_INS
    , SUM(CF_RBC_RBC_ALM)                           AS CF_RBC_RBC_ALM
    , SUM(CF_RBC_RBC_OPER)                          AS CF_RBC_RBC_OPER
    , SUM(CF_RBC_RBC_RISK_PREM_1YR)                 AS CF_RBC_RBC_RISK_PREM_1YR
    , SUM(CF_RBC_INS_DEATH)                         AS CF_RBC_INS_DEATH
    , SUM(CF_RBC_INS_DIS)                           AS CF_RBC_INS_DIS
    , SUM(CF_RBC_INS_HOSP)                          AS CF_RBC_INS_HOSP
    , SUM(CF_RBC_INS_SURGDIAG)                      AS CF_RBC_INS_SURGDIAG
    , SUM(CF_RBC_INS_MEDEXP)                        AS CF_RBC_INS_MEDEXP
    , SUM(CF_RBC_INS_ETC)                           AS CF_RBC_INS_ETC
    , SUM(CF_RBC_RBC_GMDB_AMT)                      AS CF_RBC_RBC_GMDB_AMT
    , SUM(CF_RBC_RBC_GMAB_AMT)                      AS CF_RBC_RBC_GMAB_AMT
    , SUM(CF_RBC_MARKET_OTH)                        AS CF_RBC_MARKET_OTH
    , SUM(CF_RBC_LIAB_AMT)                          AS CF_RBC_LIAB_AMT
    , SUM(CF_RBC_ASSET_AMT)                         AS CF_RBC_ASSET_AMT
    , SUM(CF_RBC_ALM_MIN_AMT)                       AS CF_RBC_ALM_MIN_AMT
    , SUM(GSPRE_NON_SINGLE)                         AS GSPRE_NON_SINGLE
    , SUM(GSPRE_SINGLE)                             AS GSPRE_SINGLE
    , SUM(POLICYCOUNT)                              AS POLICYCOUNT
    , SUM(RIDERCOUNT)                               AS RIDERCOUNT
    , SUM(CF_DAC_AT_SURR)                           AS CF_DAC_AT_SURR
    , SUM(CF_SA_INP)                                AS CF_SA_INP
    , SUM(CF_TRANS_AT_ANTY_OPEN)                    AS CF_TRANS_AT_ANTY_OPEN
    , SUM(NEG_SPREAD)                               AS NEG_SPREAD
    , SUM(CF_PREM_INC_1STYR)                        AS CF_PREM_INC_1STYR
    , SUM(CF_COMMISSION_1STYR)                      AS CF_COMMISSION_1STYR
    , SUM(NO_SURRS)                                 AS NO_SURRS
    , SUM(NO_DTHS)                                  AS NO_DTHS
    , SUM(NO_PAYS)                                  AS NO_PAYS
    , SUM(CF_SURRS_EXPOSURE)                        AS CF_SURRS_EXPOSURE
    , SUM(CF_SURRS_PREM)                            AS CF_SURRS_PREM
    , SUM(CF_SURRS_PREM_EXPOSURE)                   AS CF_SURRS_PREM_EXPOSURE
    , SUM(CF_SOP_INTEREST_IF)                       AS CF_SOP_INTEREST_IF
    , SUM(CF_FUND_AT_DTH)                           AS CF_FUND_AT_DTH
    , SUM(CF_FUND_AT_SURR)                          AS CF_FUND_AT_SURR
    , SUM(CF_PRE_TAX_PROFIT)                        AS CF_PRE_TAX_PROFIT
    , SUM(COMM_PREVCOMM)                            AS COMM_PREVCOMM
    , SUM(RBC_RP_TOT)                               AS RBC_RP_TOT
    , SUM(I_CALC)                                   AS I_CALC
    , SUM(INTEREST_MARGIN)                          AS INTEREST_MARGIN
    , SUM(MORT_MARGIN)                              AS MORT_MARGIN
    , SUM(EXPENSE_MARGIN)                           AS EXPENSE_MARGIN
    , SUM(CF_WAIVER_COST)                           AS CF_WAIVER_COST
FROM
    (SELECT /*+PARALLEL(A 16) PARALLEL(B 16) ORDERED SWAP_JOIN_INPUTS(A) PQ_DISTRIBUTE(A HASH HASH)*/ 
          B.MIG_CLO_YYMM
        , B.SYS_PART
        , B.INFLOW_IDX
        , B.OPEXP_SHAR_CHN_SECD
        , B.CHN_DTLCD
        , B.PRD_GRP_ALFA
        , B.PYCYC_COD
        , B.SCNR_NUM
        , B.PROJ_YM
        , B.MAX_PROJ_YM
        , B.PROJ_YM + A.PROJ_YM - 1                         AS PROJ_YM_JOIN
        , B.CF_PREM_INC * NVL(A.COL_VL, 0)                  AS CF_PREM_INC
        , B.CF_NET_IMF_INC * NVL(A.COL_VL, 0)               AS CF_NET_IMF_INC
        , B.CF_GMXB_NET_INC * NVL(A.COL_VL, 0)              AS CF_GMXB_NET_INC
        , B.CF_INVEST_INC * NVL(A.COL_VL, 0)                AS CF_INVEST_INC
        , B.CF_EV_CLAIM * NVL(A.COL_VL, 0)                  AS CF_EV_CLAIM
        , B.CF_SURR_BEN * NVL(A.COL_VL, 0)                  AS CF_SURR_BEN
        , B.CF_MAT_BEN * NVL(A.COL_VL, 0)                   AS CF_MAT_BEN
        , B.CF_CLAIM_ANTY * NVL(A.COL_VL, 0)                AS CF_CLAIM_ANTY
        , B.CF_PARTWITH * NVL(A.COL_VL, 0)                  AS CF_PARTWITH
        , B.CF_LIV_BEN * NVL(A.COL_VL, 0)                   AS CF_LIV_BEN
        , B.CF_TRANS_TO_SA * NVL(A.COL_VL, 0)               AS CF_TRANS_TO_SA
        , B.CF_COMMISSION * NVL(A.COL_VL, 0)                AS CF_COMMISSION
        , B.CF_ACQ_TOT * NVL(A.COL_VL, 0)                   AS CF_ACQ_TOT
        , B.CF_MNT_TOT * NVL(A.COL_VL, 0)                   AS CF_MNT_TOT
        , B.CF_COLL_EXP * NVL(A.COL_VL, 0)                  AS CF_COLL_EXP
        , B.CF_OTH_EXP * NVL(A.COL_VL, 0)                   AS CF_OTH_EXP
        , B.CF_RES_INC * NVL(A.COL_VL, 0)                   AS CF_RES_INC
        , B.CF_DAC_INC * NVL(A.COL_VL, 0)                   AS CF_DAC_INC
        , B.CF_RESERVE * NVL(A.COL_VL, 0)                   AS CF_RESERVE
        , B.CF_SA * NVL(A.COL_VL, 0)                        AS CF_SA
        , B.CF_SURR_RESERVE * NVL(A.COL_VL, 0)              AS CF_SURR_RESERVE
        , B.CF_UNEARN_RESERVE * NVL(A.COL_VL, 0)            AS CF_UNEARN_RESERVE
        , B.CF_GMDB_RES * NVL(A.COL_VL, 0)                  AS CF_GMDB_RES
        , B.CF_GMAB_RES * NVL(A.COL_VL, 0)                  AS CF_GMAB_RES
        , B.CF_DAC * NVL(A.COL_VL, 0)                       AS CF_DAC
        , B.CF_POLICY_UNALPHA_IF * NVL(A.COL_VL, 0)         AS CF_POLICY_UNALPHA_IF
        , B.CF_REP_COLL_ALPHA_IF * NVL(A.COL_VL, 0)         AS CF_REP_COLL_ALPHA_IF
        , B.CF_SOP_COLL_ALPHA_IF * NVL(A.COL_VL, 0)         AS CF_SOP_COLL_ALPHA_IF
        , B.CF_SOP_COLL_BETA_IF * NVL(A.COL_VL, 0)          AS CF_SOP_COLL_BETA_IF
        , B.CF_SOP_COLL_GAMMA_IF * NVL(A.COL_VL, 0)         AS CF_SOP_COLL_GAMMA_IF
        , B.CF_SOP_SAV_PREM_IF * NVL(A.COL_VL, 0)           AS CF_SOP_SAV_PREM_IF
        , B.CF_SOP_RISK_PREM_IF * NVL(A.COL_VL, 0)          AS CF_SOP_RISK_PREM_IF
        , B.CF_SOP_RISK_PREM_LWL_ADD_IF * NVL(A.COL_VL, 0)  AS CF_SOP_RISK_PREM_LWL_ADD_IF
        , B.CF_ACQ_EXP * NVL(A.COL_VL, 0)                   AS CF_ACQ_EXP
        , B.CF_ACQ_ND_EXP * NVL(A.COL_VL, 0)                AS CF_ACQ_ND_EXP
        , B.CF_MNT_P_EXP * NVL(A.COL_VL, 0)                 AS CF_MNT_P_EXP
        , B.CF_MNT_NP_EXP * NVL(A.COL_VL, 0)                AS CF_MNT_NP_EXP
        , B.CF_CLAIM_TOT * NVL(A.COL_VL, 0)                 AS CF_CLAIM_TOT
        , B.CF_RES_AT_DTH * NVL(A.COL_VL, 0)                AS CF_RES_AT_DTH
        , B.CF_RES_AT_SURR * NVL(A.COL_VL, 0)               AS CF_RES_AT_SURR
        , B.CF_IMF_INCOME * NVL(A.COL_VL, 0)                AS CF_IMF_INCOME
        , B.CF_IMF_OUTGO * NVL(A.COL_VL, 0)                 AS CF_IMF_OUTGO
        , B.CF_GMXB_INC * NVL(A.COL_VL, 0)                  AS CF_GMXB_INC
        , B.CF_CLAIM_GMDB * NVL(A.COL_VL, 0)                AS CF_CLAIM_GMDB
        , B.CF_CLAIM_GMAB * NVL(A.COL_VL, 0)                AS CF_CLAIM_GMAB
        , B.CF_RBC_RBC_CRED * NVL(A.COL_VL, 0)              AS CF_RBC_RBC_CRED
        , B.CF_RBC_RBC_MARKET * NVL(A.COL_VL, 0)            AS CF_RBC_RBC_MARKET
        , B.CF_RBC_RBC_INS * NVL(A.COL_VL, 0)               AS CF_RBC_RBC_INS
        , B.CF_RBC_RBC_ALM * NVL(A.COL_VL, 0)               AS CF_RBC_RBC_ALM
        , B.CF_RBC_RBC_OPER * NVL(A.COL_VL, 0)              AS CF_RBC_RBC_OPER
        , B.CF_RBC_RBC_RISK_PREM_1YR * NVL(A.COL_VL, 0)     AS CF_RBC_RBC_RISK_PREM_1YR
        , B.CF_RBC_INS_DEATH * NVL(A.COL_VL, 0)             AS CF_RBC_INS_DEATH
        , B.CF_RBC_INS_DIS * NVL(A.COL_VL, 0)               AS CF_RBC_INS_DIS
        , B.CF_RBC_INS_HOSP * NVL(A.COL_VL, 0)              AS CF_RBC_INS_HOSP
        , B.CF_RBC_INS_SURGDIAG * NVL(A.COL_VL, 0)          AS CF_RBC_INS_SURGDIAG
        , B.CF_RBC_INS_MEDEXP * NVL(A.COL_VL, 0)            AS CF_RBC_INS_MEDEXP
        , B.CF_RBC_INS_ETC * NVL(A.COL_VL, 0)               AS CF_RBC_INS_ETC
        , B.CF_RBC_RBC_GMDB_AMT * NVL(A.COL_VL, 0)          AS CF_RBC_RBC_GMDB_AMT
        , B.CF_RBC_RBC_GMAB_AMT * NVL(A.COL_VL, 0)          AS CF_RBC_RBC_GMAB_AMT
        , B.CF_RBC_MARKET_OTH * NVL(A.COL_VL, 0)            AS CF_RBC_MARKET_OTH
        , B.CF_RBC_LIAB_AMT * NVL(A.COL_VL, 0)              AS CF_RBC_LIAB_AMT
        , B.CF_RBC_ASSET_AMT * NVL(A.COL_VL, 0)             AS CF_RBC_ASSET_AMT
        , B.CF_RBC_ALM_MIN_AMT * NVL(A.COL_VL, 0)           AS CF_RBC_ALM_MIN_AMT
        , B.GSPRE_NON_SINGLE * NVL(A.COL_VL, 0)             AS GSPRE_NON_SINGLE
        , B.GSPRE_SINGLE * NVL(A.COL_VL, 0)                 AS GSPRE_SINGLE
        , B.POLICYCOUNT * NVL(A.COL_VL, 0)                  AS POLICYCOUNT
        , B.RIDERCOUNT * NVL(A.COL_VL, 0)                   AS RIDERCOUNT
        , B.CF_DAC_AT_SURR * NVL(A.COL_VL, 0)               AS CF_DAC_AT_SURR
        , B.CF_SA_INP * NVL(A.COL_VL, 0)                    AS CF_SA_INP
        , B.CF_TRANS_AT_ANTY_OPEN * NVL(A.COL_VL, 0)        AS CF_TRANS_AT_ANTY_OPEN
        , B.NEG_SPREAD * NVL(A.COL_VL, 0)                   AS NEG_SPREAD
        , B.CF_PREM_INC_1STYR * NVL(A.COL_VL, 0)            AS CF_PREM_INC_1STYR
        , B.CF_COMMISSION_1STYR * NVL(A.COL_VL, 0)          AS CF_COMMISSION_1STYR
        , B.NO_SURRS * NVL(A.COL_VL, 0)                     AS NO_SURRS
        , B.NO_DTHS * NVL(A.COL_VL, 0)                      AS NO_DTHS
        , B.NO_PAYS * NVL(A.COL_VL, 0)                      AS NO_PAYS
        , B.CF_SURRS_EXPOSURE * NVL(A.COL_VL, 0)            AS CF_SURRS_EXPOSURE
        , B.CF_SURRS_PREM * NVL(A.COL_VL, 0)                AS CF_SURRS_PREM
        , B.CF_SURRS_PREM_EXPOSURE * NVL(A.COL_VL, 0)       AS CF_SURRS_PREM_EXPOSURE
        , B.CF_SOP_INTEREST_IF * NVL(A.COL_VL, 0)           AS CF_SOP_INTEREST_IF
        , B.CF_FUND_AT_DTH * NVL(A.COL_VL, 0)               AS CF_FUND_AT_DTH
        , B.CF_FUND_AT_SURR * NVL(A.COL_VL, 0)              AS CF_FUND_AT_SURR
        , B.CF_PRE_TAX_PROFIT * NVL(A.COL_VL, 0)            AS CF_PRE_TAX_PROFIT
        , B.COMM_PREVCOMM * NVL(A.COL_VL, 0)                AS COMM_PREVCOMM
        , B.RBC_RP_TOT * NVL(A.COL_VL, 0)                   AS RBC_RP_TOT
        , B.I_CALC * NVL(A.COL_VL, 0)                       AS I_CALC
        , B.INTEREST_MARGIN * NVL(A.COL_VL, 0)              AS INTEREST_MARGIN
        , B.MORT_MARGIN * NVL(A.COL_VL, 0)                  AS MORT_MARGIN
        , B.EXPENSE_MARGIN * NVL(A.COL_VL, 0)               AS EXPENSE_MARGIN
        , B.CF_WAIVER_COST * NVL(A.COL_VL, 0)               AS CF_WAIVER_COST
    FROM    
        (SELECT /*+PARALLEL(A 16) */ * 
        FROM
           (SELECT /*+PARALLEL(A 16) */ 
                  OPEXP_SHAR_CHN_SECD
                , ADJ_CHN_DTLCD
                , PRD_GRP_ALFA
                , PYCYC_COD
                , CAST(REPLACE(REPLACE(PROG_YYMM, '_VL'), 'COLM_') AS INTEGER) AS PROJ_YM   --컬럼명에 경과기간이 내포되어 있음. 비정규형이지만 현업의 엑셀 IMPORT하는 작업 편의를 고려함.
                , CASE WHEN CAST(REPLACE(REPLACE(PROG_YYMM, '_VL'), 'COLM_') AS INTEGER) > 60   --사업계획이 5년단위로만 의미가 있으므로 60개월 초과는 0으로 처리함.
                       THEN 0 
                       ELSE COL_VL 
                       END                                                     AS COL_VL 
            FROM
                (SELECT /*+FULL(A) PARALLEL(A 16) */ * 
                FROM CF_SIMU.WRBZ_BZ_PL_SENSTVT_INF A 
                WHERE SCNR_NUM = 2 AND LAST_HIS_YN ='1' AND DEL_YN ='0'
                ) A 
                --원하는 시나리오를 조건으로 변경하면 됨. SCNR_NUM = ##, 컬럼명 COLM_##_VL 에서 ##은 경과기간을 의미함.
            UNPIVOT(COL_VL FOR PROG_YYMM IN(COLM_1_VL, COLM_2_VL, COLM_3_VL, COLM_4_VL, COLM_5_VL, COLM_6_VL, COLM_7_VL, COLM_8_VL, COLM_9_VL, COLM_10_VL 
                                        , COLM_11_VL, COLM_12_VL, COLM_13_VL, COLM_14_VL, COLM_15_VL, COLM_16_VL, COLM_17_VL, COLM_18_VL, COLM_19_VL, COLM_20_VL 
                                        , COLM_21_VL, COLM_22_VL, COLM_23_VL, COLM_24_VL, COLM_25_VL, COLM_26_VL, COLM_27_VL, COLM_28_VL, COLM_29_VL, COLM_30_VL 
                                        , COLM_31_VL, COLM_32_VL, COLM_33_VL, COLM_34_VL, COLM_35_VL, COLM_36_VL, COLM_37_VL, COLM_38_VL, COLM_39_VL, COLM_40_VL 
                                        , COLM_41_VL, COLM_42_VL, COLM_43_VL, COLM_44_VL, COLM_45_VL, COLM_46_VL, COLM_47_VL, COLM_48_VL, COLM_49_VL, COLM_50_VL 
                                        , COLM_51_VL, COLM_52_VL, COLM_53_VL, COLM_54_VL, COLM_55_VL, COLM_56_VL, COLM_57_VL, COLM_58_VL, COLM_59_VL, COLM_60_VL))
            WHERE COL_VL <> 0   --UNPIVOT함수에 의해 자동으로 NULL값을 포함하는 경과기간은 제외되어 부하가 줄음. 0의 입력은 해당 경과시점의 민감도가 0, 즉 계약유입이 없음을 의미함.
            ) A
        WHERE COL_VL <> 0   --계약유입이 없다고 가정한 0 이외의 60 초과시점의 민감도 가정도 통상의 요건상 의미없기 때문에 제외함.
        ) A, --INLINE VIEW A는 민감도 정보 조인을 위한 준비

        (SELECT /*+FULL(A) PARALLEL(A 16) */
              MIG_CLO_YYMM
            , SYS_PART
            , INFLOW_IDX
            , OPEXP_SHAR_CHN_SECD
            , CHN_DTLCD
            , PRD_GRP_ALFA
            , PYCYC_COD
            , SCNR_NUM
            , CAST(PROJ_YM AS INTEGER)              AS PROJ_YM
            , MAX(CAST(PROJ_YM AS INTEGER)) OVER(PARTITION BY MIG_CLO_YYMM, SYS_PART, INFLOW_IDX, OPEXP_SHAR_CHN_SECD, CHN_DTLCD, PRD_GRP_ALFA, PYCYC_COD) AS MAX_PROJ_YM
            , SUM(CF_PREM_INC)                      AS CF_PREM_INC
            , SUM(CF_NET_IMF_INC)                   AS CF_NET_IMF_INC
            , SUM(CF_GMXB_NET_INC)                  AS CF_GMXB_NET_INC
            , SUM(CF_INVEST_INC)                    AS CF_INVEST_INC
            , SUM(CF_EV_CLAIM)                      AS CF_EV_CLAIM
            , SUM(CF_SURR_BEN)                      AS CF_SURR_BEN
            , SUM(CF_MAT_BEN)                       AS CF_MAT_BEN
            , SUM(CF_CLAIM_ANTY)                    AS CF_CLAIM_ANTY
            , SUM(CF_PARTWITH)                      AS CF_PARTWITH
            , SUM(CF_LIV_BEN)                       AS CF_LIV_BEN
            , SUM(CF_TRANS_TO_SA)                   AS CF_TRANS_TO_SA
            , SUM(CF_COMMISSION)                    AS CF_COMMISSION
            , SUM(CF_ACQ_TOT)                       AS CF_ACQ_TOT
            , SUM(CF_MNT_TOT)                       AS CF_MNT_TOT
            , SUM(CF_COLL_EXP)                      AS CF_COLL_EXP
            , SUM(CF_OTH_EXP)                       AS CF_OTH_EXP
            , SUM(CF_RES_INC)                       AS CF_RES_INC
            , SUM(CF_DAC_INC)                       AS CF_DAC_INC
            , SUM(CF_RESERVE)                       AS CF_RESERVE
            , SUM(CF_SA)                            AS CF_SA
            , SUM(CF_SURR_RESERVE)                  AS CF_SURR_RESERVE
            , SUM(CF_UNEARN_RESERVE)                AS CF_UNEARN_RESERVE
            , SUM(CF_GMDB_RES)                      AS CF_GMDB_RES
            , SUM(CF_GMAB_RES)                      AS CF_GMAB_RES
            , SUM(CF_DAC)                           AS CF_DAC
            , SUM(CF_POLICY_UNALPHA_IF)             AS CF_POLICY_UNALPHA_IF
            , SUM(CF_REP_COLL_ALPHA_IF)             AS CF_REP_COLL_ALPHA_IF
            , SUM(CF_SOP_COLL_ALPHA_IF)             AS CF_SOP_COLL_ALPHA_IF
            , SUM(CF_SOP_COLL_BETA_IF)              AS CF_SOP_COLL_BETA_IF
            , SUM(CF_SOP_COLL_GAMMA_IF)             AS CF_SOP_COLL_GAMMA_IF
            , SUM(CF_SOP_SAV_PREM_IF)               AS CF_SOP_SAV_PREM_IF
            , SUM(CF_SOP_RISK_PREM_IF)              AS CF_SOP_RISK_PREM_IF
            , SUM(CF_SOP_RISK_PREM_LWL_ADD_IF)      AS CF_SOP_RISK_PREM_LWL_ADD_IF
            , SUM(CF_ACQ_EXP)                       AS CF_ACQ_EXP
            , SUM(CF_ACQ_ND_EXP)                    AS CF_ACQ_ND_EXP
            , SUM(CF_MNT_P_EXP)                     AS CF_MNT_P_EXP
            , SUM(CF_MNT_NP_EXP)                    AS CF_MNT_NP_EXP
            , SUM(CF_CLAIM_TOT)                     AS CF_CLAIM_TOT
            , SUM(CF_RES_AT_DTH)                    AS CF_RES_AT_DTH
            , SUM(CF_RES_AT_SURR)                   AS CF_RES_AT_SURR
            , SUM(CF_IMF_INCOME)                    AS CF_IMF_INCOME
            , SUM(CF_IMF_OUTGO)                     AS CF_IMF_OUTGO
            , SUM(CF_GMXB_INC)                      AS CF_GMXB_INC
            , SUM(CF_CLAIM_GMDB)                    AS CF_CLAIM_GMDB
            , SUM(CF_CLAIM_GMAB)                    AS CF_CLAIM_GMAB
            , SUM(CF_RBC_RBC_CRED)                  AS CF_RBC_RBC_CRED
            , SUM(CF_RBC_RBC_MARKET)                AS CF_RBC_RBC_MARKET
            , SUM(CF_RBC_RBC_INS)                   AS CF_RBC_RBC_INS
            , SUM(CF_RBC_RBC_ALM)                   AS CF_RBC_RBC_ALM
            , SUM(CF_RBC_RBC_OPER)                  AS CF_RBC_RBC_OPER
            , SUM(CF_RBC_RBC_RISK_PREM_1YR)         AS CF_RBC_RBC_RISK_PREM_1YR
            , SUM(CF_RBC_INS_DEATH)                 AS CF_RBC_INS_DEATH
            , SUM(CF_RBC_INS_DIS)                   AS CF_RBC_INS_DIS
            , SUM(CF_RBC_INS_HOSP)                  AS CF_RBC_INS_HOSP
            , SUM(CF_RBC_INS_SURGDIAG)              AS CF_RBC_INS_SURGDIAG
            , SUM(CF_RBC_INS_MEDEXP)                AS CF_RBC_INS_MEDEXP
            , SUM(CF_RBC_INS_ETC)                   AS CF_RBC_INS_ETC
            , SUM(CF_RBC_RBC_GMDB_AMT)              AS CF_RBC_RBC_GMDB_AMT
            , SUM(CF_RBC_RBC_GMAB_AMT)              AS CF_RBC_RBC_GMAB_AMT
            , SUM(CF_RBC_MARKET_OTH)                AS CF_RBC_MARKET_OTH
            , SUM(CF_RBC_LIAB_AMT)                  AS CF_RBC_LIAB_AMT
            , SUM(CF_RBC_ASSET_AMT)                 AS CF_RBC_ASSET_AMT
            , SUM(CF_RBC_ALM_MIN_AMT)               AS CF_RBC_ALM_MIN_AMT
            , SUM(GSPRE_NON_SINGLE)                 AS GSPRE_NON_SINGLE
            , SUM(GSPRE_SINGLE)                     AS GSPRE_SINGLE
            , SUM(POLICYCOUNT)                      AS POLICYCOUNT
            , SUM(RIDERCOUNT)                       AS RIDERCOUNT
            , SUM(CF_DAC_AT_SURR)                   AS CF_DAC_AT_SURR
            , SUM(CF_SA_INP)                        AS CF_SA_INP
            , SUM(CF_TRANS_AT_ANTY_OPEN)            AS CF_TRANS_AT_ANTY_OPEN
            , SUM(NEG_SPREAD)                       AS NEG_SPREAD
            , SUM(CF_PREM_INC_1STYR)                AS CF_PREM_INC_1STYR
            , SUM(CF_COMMISSION_1STYR)              AS CF_COMMISSION_1STYR
            , SUM(NO_SURRS)                         AS NO_SURRS
            , SUM(NO_DTHS)                          AS NO_DTHS
            , SUM(NO_PAYS)                          AS NO_PAYS
            , SUM(CF_SURRS_EXPOSURE)                AS CF_SURRS_EXPOSURE
            , SUM(CF_SURRS_PREM)                    AS CF_SURRS_PREM
            , SUM(CF_SURRS_PREM_EXPOSURE)           AS CF_SURRS_PREM_EXPOSURE
            , SUM(CF_SOP_INTEREST_IF)               AS CF_SOP_INTEREST_IF
            , SUM(CF_FUND_AT_DTH)                   AS CF_FUND_AT_DTH
            , SUM(CF_FUND_AT_SURR)                  AS CF_FUND_AT_SURR
            , SUM(CF_PRE_TAX_PROFIT)                AS CF_PRE_TAX_PROFIT
            , SUM(COMM_PREVCOMM)                    AS COMM_PREVCOMM
            , SUM(RBC_RP_TOT)                       AS RBC_RP_TOT
            , SUM(I_CALC)                           AS I_CALC
            , SUM(INTEREST_MARGIN)                  AS INTEREST_MARGIN
            , SUM(MORT_MARGIN)                      AS MORT_MARGIN
            , SUM(EXPENSE_MARGIN)                   AS EXPENSE_MARGIN
            , SUM(CF_WAIVER_COST)                   AS CF_WAIVER_COST 
        FROM CF_SIMU.OUTPUT_T14 A 
        WHERE MIG_CLO_YYMM = '201812' AND SYS_PART ='A02' AND INFLOW_IDX ='1' AND SCNR_NUM = 1 AND PROJ_YM <> 0   --경과시점 0은 평가시점 그자체이므로 물량민감도와 무관하기에 제외함.
        GROUP BY MIG_CLO_YYMM, SYS_PART, INFLOW_IDX, OPEXP_SHAR_CHN_SECD, CHN_DTLCD, PRD_GRP_ALFA, PYCYC_COD, SCNR_NUM, PROJ_YM
        ) B --INLINE VIEW B는 필요한 현금흐름을 최소집계기준단위(테스트에서는 사업비배분채널OPEXP_SHAR_CHN_SECD, 관리채널CHN_DTLCD, 상품그룹단위PRD_GRP_ALFA, 납입주기PYCYC_COD)로 GROUPING
    WHERE A.OPEXP_SHAR_CHN_SECD = B.OPEXP_SHAR_CHN_SECD
        AND A.ADJ_CHN_DTLCD = B.CHN_DTLCD
        AND A.PRD_GRP_ALFA = B.PRD_GRP_ALFA
        AND A.PYCYC_COD = B.PYCYC_COD
    ) A
WHERE PROJ_YM_JOIN < = MAX_PROJ_YM
GROUP BY MIG_CLO_YYMM, SYS_PART, INFLOW_IDX, OPEXP_SHAR_CHN_SECD, CHN_DTLCD, PRD_GRP_ALFA, PYCYC_COD, SCNR_NUM, PROJ_YM_JOIN
;

COMMIT;


```
