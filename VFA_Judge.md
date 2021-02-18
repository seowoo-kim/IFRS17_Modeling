```sql

SET TIMING ON;

--###데이터 확인
SELECT * FROM CF_SIMU.VFA_APPT_REQS_LST WHERE IFRS_ACTS_YYMM ='201904' AND IFRS_WRK_SECD ='E' AND ROWNUM < 100; --변동수수료법적용요건내역, 소스테이블
SELECT * FROM CF_SIMU.VFA_JUDG_RTO_LST WHERE IFRS_ACTS_YYMM ='201904' AND IFRS_WRK_SECD ='E' AND ROWNUM < 100;  --변동수수료법판단비율내역, 결과테이블

-- DELETE FROM CF_SIMU.VFA_JUDG_RTO_LST;    --특정 건들만 필요에 따라 빠르게 작업후 확인하는 작업이 반복 될 것이므로, TRUNCATE말고 DELETE 주로 할것
-- COMMIT;


--###업무요건

--회계모형 중 변동수수료 접근법(이하 VFA)은 보험계약의 형태에 따라 금융상품(투자요소)요소와 계약자의 직접 참가 특성이 있는 경우에 사용한다.
--이러한 회계처리는 대체로 변액이나 금리 연동형 상품군에 적용된다.
--직접 참가 특성이 있는지를 판단하기위해 기초항목(연계된 자산 등)의 공정가치나 이와 연계된 보험금지급금과, 기초항목과 무관한 지급금을 비교하여 시나리오를 선정하는 프로세스가 필요하다.
--얼마나 관련되어 있는지는 각각의 경제가정 시나리오(금리, etf 등)의 변화에 따른 변동성이 설명해주기에 표준편차를 구한다.

--0번 시나리오는 BASE 시나리오로 여타의 1~1000번 시나리오와 사용 목적과 데이터 산출 기준이 다름. 
--보험상품에는 확정형과 비확정형(펀드변액행, 금리연동형) 상품군으로 크게 두가지로 구분 할 수 있고, 확정형 상품은 기본시나리오만 사용하며 비확정형 상품은 모든 시나리오(BASE + 1~1000)를 사용함.

--VFA_APPT_REQS_LST 테이블이 몇천만건의 데이터로 꽤 크지만 그럼에도 두번의 FULL SCAN을 하도록 선택하였음. 각각의 full scan 목적은 아래의 해당 INLINE VIEW의 주석으로 표기함.
--하나의 계약(증권번호)이지만 여러 종류의 보험상품이 묶여서 팔리기 때문에 계약내에서 각각을 분리하여 영향을 분리해 판단해야 함.
--게다가 보험 계약 단위의 특성상 직접참가 특성을 가진 상품은 하나의 계약 내에 하나만 존재할 수 있으므로,
--극단적으로 수십개의 상품으로 묶였지만 하나만, 혹은 하나도 직접참가 특성이 없을수도 있음. 반면 직접 참가특성을 가진 상품만이 존재할 수도 있음. OUTER JOIN의 이유.

--집계기준과 속성이 상이하지만, 엔터티 통합 시도했음. 


--쿼리 수행 전 실행계획을 확인하기 위한 실행계획 생성과, plan table SELECT
--SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', NULL, 'OUTLINE'));
--EXPLAIN PLAN FOR



INSERT /*+ENABLE_PARALLEL_DML PARALLEL(Z 16) PQ_DISTRIBUTE(Z NONE) NO_GATHER_OPTIMIZER_STATISTICS */ 
INTO CF_SIMU.VFA_JUDG_RTO_LST Z
SELECT /*+PARALLEL(A 16) */ 
      A.IFRS_ACTS_YYMM
    , A.PLYNO
    , A.MPRD_PRDCD
    , A.IFRS_WRK_SECD
    , A.MAX_SCN_NUM
    , '0'          AS TMP_PK        --테스트 작업에서는 의미없는 속성이므로 '0'으로 고정함
    , A.FV_STD_DVAT
    , A.INS_DFR_AMT_STD_DVAT
    , LEAST(A.VFA_JUDG_RTO, 99999)
FROM
    (SELECT /*+PARALLEL(A 16) PARALLEL(B 16) SWAP_JOIN_INPUTS(B) PQ_DISTRIBUTE(B HASH HASH) OPT_PARAM('_OPTIMIZER_ADAPTIVE_PLANS' 'FALSE')*/
          A.IFRS_ACTS_YYMM
        , A.PLYNO
        , A.MPRD_PRDCD
        , A.IFRS_WRK_SECD
        , 0             AS MAX_SCN_NUM      --테스트 작업에서는 시나리오 판별요건을 무시하기로 함. 대략 0~1000의 1001개 시나리오 중 선택하는것이었으나 BASE인 0으로 고정함.
        , NVL(STDDEV_POP(CASE WHEN A.SCNR_NUM <> 0  --변동성을 살펴볼때는 BASE 시나리오를 제외해야 하므로 표준편차 계산시에 SCNR_NUM <> 0 조건이 들어감.
                              THEN A.FND_ITM_FV + NVL(B.FND_ITM_FV, 0) 
                              END)
             , 0)       AS FV_STD_DVAT
        , NVL(STDDEV_POP(CASE WHEN A.SCNR_NUM <> 0 
                              THEN A.FND_ITM_RLP_INS_DFR_AMT + A.FND_ITM_NO_RLP_INS_DFR_AMT + NVL(B.FND_ITM_RLP_INS_DFR_AMT, 0) + NVL(B.FND_ITM_NO_RLP_INS_DFR_AMT, 0) 
                              END)
             , 0)       AS INS_DFR_AMT_STD_DVAT
        , NVL(SUM(CASE WHEN A.SCNR_NUM <> 0 
                       THEN (A.FND_ITM_RLP_INS_DFR_AMT + NVL(B.FND_ITM_RLP_INS_DFR_AMT, 0)) 
                       END) 
             / DECODE(SUM(CASE WHEN A.SCNR_NUM <> 0 
                               THEN A.FND_ITM_RLP_INS_DFR_AMT + A.FND_ITM_NO_RLP_INS_DFR_AMT + NVL(B.FND_ITM_RLP_INS_DFR_AMT, 0) + NVL(B.FND_ITM_NO_RLP_INS_DFR_AMT, 0) 
                               END)
                     , 0, NULL
                     , SUM(CASE WHEN A.SCNR_NUM <> 0 
                                THEN A.FND_ITM_RLP_INS_DFR_AMT + A.FND_ITM_NO_RLP_INS_DFR_AMT + NVL(B.FND_ITM_RLP_INS_DFR_AMT, 0) + NVL(B.FND_ITM_NO_RLP_INS_DFR_AMT, 0) 
                                END)
                     )
             , 0)       AS AVG_ADJ_RTO
        , NVL(NVL(SUM(CASE WHEN A.SCNR_NUM <> 0 
                           THEN (A.FND_ITM_RLP_INS_DFR_AMT + NVL(B.FND_ITM_RLP_INS_DFR_AMT, 0)) 
                           END) 
                 / DECODE(SUM(CASE WHEN A.SCNR_NUM <> 0 
                                   THEN A.FND_ITM_RLP_INS_DFR_AMT + A.FND_ITM_NO_RLP_INS_DFR_AMT + NVL(B.FND_ITM_RLP_INS_DFR_AMT, 0) + NVL(B.FND_ITM_NO_RLP_INS_DFR_AMT, 0) 
                                   END)
                         , 0, NULL
                         , SUM(CASE WHEN A.SCNR_NUM <> 0 
                                    THEN A.FND_ITM_RLP_INS_DFR_AMT + A.FND_ITM_NO_RLP_INS_DFR_AMT + NVL(B.FND_ITM_RLP_INS_DFR_AMT, 0) + NVL(B.FND_ITM_NO_RLP_INS_DFR_AMT, 0) 
                                    END)
                         )
                 , 0) 
             * NVL(STDDEV_POP(CASE WHEN A.SCNR_NUM <> 0 
                                   THEN A.FND_ITM_RLP_INS_DFR_AMT + A.FND_ITM_NO_RLP_INS_DFR_AMT + NVL(B.FND_ITM_RLP_INS_DFR_AMT, 0) + NVL(B.FND_ITM_NO_RLP_INS_DFR_AMT, 0) 
                                   END)
                  / DECODE(STDDEV_POP(CASE WHEN A.SCNR_NUM <> 0 
                                           THEN A.FND_ITM_FV + NVL(B.FND_ITM_FV, 0) 
                                           END)
                          , 0, NULL
                          , STDDEV_POP(CASE WHEN A.SCNR_NUM <> 0 
                                            THEN A.FND_ITM_FV + NVL(B.FND_ITM_FV, 0) 
                                            END)
                          )
                  , 1)
             , 99999)   AS VFA_JUDG_RTO
    FROM
        (SELECT /*+FULL(A) PARALLEL(A 16) */ 
              IFRS_ACTS_YYMM
            , PLYNO
            , MPRD_PRDCD
            , IFRS_WRK_SECD
            , SCNR_NUM
            , SUM(FND_ITM_FV)                 AS FND_ITM_FV
            , SUM(FND_ITM_RLP_INS_DFR_AMT)    AS FND_ITM_RLP_INS_DFR_AMT
            , SUM(FND_ITM_NO_RLP_INS_DFR_AMT) AS FND_ITM_NO_RLP_INS_DFR_AMT
        FROM CF_SIMU.VFA_APPT_REQS_LST A 
        WHERE IFRS_ACTS_YYMM ='201904' AND IFRS_WRK_SECD ='E'
        GROUP BY IFRS_ACTS_YYMM, PLYNO, MPRD_PRDCD, IFRS_WRK_SECD, SCNR_NUM
        ) A,
        (SELECT /*+PARALLEL(A 16) */
              IFRS_ACTS_YYMM
            , PLYNO
            , MPRD_PRDCD
            , IFRS_WRK_SECD
            , SUM(FND_ITM_FV)                 AS FND_ITM_FV
            , SUM(FND_ITM_RLP_INS_DFR_AMT)    AS FND_ITM_RLP_INS_DFR_AMT
            , SUM(FND_ITM_NO_RLP_INS_DFR_AMT) AS FND_ITM_NO_RLP_INS_DFR_AMT
        FROM
            (SELECT /*+FULL(A) PARALLEL(A 16) */ 
                  IFRS_ACTS_YYMM
                , PLYNO
                , MPRD_PRDCD
                , IFRS_WRK_SECD
                , PRDCD
                , SUM(CASE WHEN SCNR_NUM = 0 THEN FND_ITM_FV END)                 AS FND_ITM_FV
                , SUM(CASE WHEN SCNR_NUM = 0 THEN FND_ITM_RLP_INS_DFR_AMT END)    AS FND_ITM_RLP_INS_DFR_AMT
                , SUM(CASE WHEN SCNR_NUM = 0 THEN FND_ITM_NO_RLP_INS_DFR_AMT END) AS FND_ITM_NO_RLP_INS_DFR_AMT
            FROM CF_SIMU.VFA_APPT_REQS_LST A 
            WHERE IFRS_ACTS_YYMM ='201904' AND IFRS_WRK_SECD ='E'
            GROUP BY IFRS_ACTS_YYMM, PLYNO, MPRD_PRDCD, IFRS_WRK_SECD, PRDCD    --MPRD_PRDCD는 주계약상품으로 계약단위당 한가지만 존재하지만, 여러상품 PRDCD가 존재할 수 있음.
            HAVING COUNT(SCNR_NUM) = 1      
            ) A
        GROUP BY IFRS_ACTS_YYMM, PLYNO, MPRD_PRDCD, IFRS_WRK_SECD   --시나리오 효과를 골라서 하나의 계약단위로 통합함.
        ) B
    WHERE A.IFRS_ACTS_YYMM = B.IFRS_ACTS_YYMM (+) 
    AND A.PLYNO = B.PLYNO                     (+)
    AND A.MPRD_PRDCD = B.MPRD_PRDCD           (+)
    AND A.IFRS_WRK_SECD = B.IFRS_WRK_SECD     (+)
    GROUP BY A.IFRS_ACTS_YYMM, A.PLYNO, A.MPRD_PRDCD, A.IFRS_WRK_SECD
    ) A
;

COMMIT;


```
