```sql

--###데이터 확인
SELECT * FROM MIG.FND_RKRT_INF WHERE CLO_YYMM = '201812' AND LAST_HIS_YN ='1' AND DEL_YN ='0' AND ROWNUM < 100;
SELECT * FROM CF_SIMU.IFRS_CI_BFRT_CRT_LST WHERE CLO_YYMM ='201812' AND LAST_HIS_YN ='1' AND DEL_YN ='0' AND ROWNUM < 100;
SELECT * FROM CF_SIMU.CI_BFRT_INF WHERE CLO_YYMM = '201812' AND ROWNUM < 100;



--###업무요건
--README, notion 링크 확인



SET TIMING ON;



--###CI담보코드 계층별 목록 생성
--최대 계층을 반환받아야 어플리케이션 내의 루프를 구성할 수 있음. 


SELECT MAX(LENGTH(PATH) - LENGTH(REPLACE(PATH, '/'))) AS LV, IFRS_CLM_ID    --계층은 PATH에 "/"로 구분한 담보코드의 수이므로, 그중 최대값 색적.
FROM 
    (SELECT SYS_CONNECT_BY_PATH(IFRS_CLM_ID, '/') AS PATH, IFRS_CLM_ID, RKRT_ID 	
    --'SYS_CONNECT_BY_PATH'는 재료담보(인라인뷰의 RKRT_ID)가 다른 결과담보(IFRS_CLM_ID)로부터 파생된 관계노드를 따라 "/"로 PATH를 표시함 .
    FROM 
        (SELECT /*+FULL(A) PARALLEL(A 16) */ IFRS_CLM_ID, RKRT_ID
        FROM 
            (SELECT * FROM CF_SIMU.IFRS_CI_BFRT_CRT_LST WHERE CLO_YYMM ='201812' AND LAST_HIS_YN ='1' AND DEL_YN ='0') A --소스테이블 마감년월 입력받아 CLO_YYMM변경.
            UNPIVOT(RKRT_ID FOR ID_NUM IN(RKRT_1_ID,RKRT_2_ID,RKRT_3_ID,RKRT_4_ID,RKRT_5_ID,RKRT_6_ID,RKRT_7_ID,RKRT_8_ID,RKRT_9_ID,RKRT_10_ID,RKRT_11_ID,RKRT_12_ID,RKRT_13_ID))
        )   --UNPIVOT으로 결과와 재료 각각의 관계를 1:1로 만듬
    CONNECT BY NOCYCLE PRIOR IFRS_CLM_ID = RKRT_ID  --계층형 탐색 시작, START WITH 생략으로 모든 레코드 각각에 모두 찾도록 함.
    ) A 
GROUP BY IFRS_CLM_ID ORDER BY 1,2;
--위에서 최대 계층을 확인하여야 어플리케이션에서 루프를 구성할 수 있음. 어플리케이션 로직에는 리스트가 아니라 최대 계층만을 뽑아 FOR 루프 횟수로 둠.
--현재 ci담보코드 레코드수는 약 200~300개로, 쿼리반환까지 수초 걸림.





--이전 작업방식이 어플리케이션에서 사용하는 SQLITE의 특유기능을 사용하였으나 ORACLE에서 지원 불가, 따라서 XML QUERY이용함.
--각 위험률 특유의(여러암발생률의 최대연령, 통계가있는 연령이 다름) 최대기간을 고려하여 계산을 해야하므로  프로젝션기간 누락없도록 할것.
--CACL_TYP_COD(CI담보산출목적)컬럼 값 Pri, CF, N별로 부담보기간(k#) 3차원기간적용방식이 다르므로 주의가 필요함.


------------------------------------------------------------------------------------------------
--###LEVEL 1, 가장 기본계층이 되는 담보코드 산출, 계층형구조가 없음, 결과테이블 참조하지 않음.
------------------------------------------------------------------------------------------------

--SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
--EXPLAIN PLAN FOR

INSERT /*+ENABLE_PARALLEL_DML PARALLEL(Z 16) OPT_PARAM('_OPTIMIZER_GATHER_STATS_ON_LOAD' 'FALSE') */ 
INTO CF_SIMU.CI_BFRT_INF Z       --아래 '201812'는 결과를 사용하려는 마감년월(CLO_YYMM)로 어플리케이션에서 사용자의 입력을 받도록 함, XMLQUERY() 는 string을 해석하는 부분.
SELECT /*+PARALLEL(A 16)*/ '201812' AS CLO_YYMM, A.IFRS_CLM_ID, A.GNDR_APPT_COD, A.AGE, A.NTRY_AGE, A.YY_LSTH_PPRD, A.CACL_TYP_COD, XMLQUERY(RKRT_CALFM_RMK RETURNING CONTENT).GETNUMBERVAL() AS RKRT_VL 
FROM 
    (SELECT /*+PARALLEL(A 16)*/
          A.IFRS_CLM_ID
          , CASE WHEN A.CACL_TYP_COD = 'N' THEN REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(RKRT_CALFM_RMK, 'q13', Q13), 'q12', Q12), 'q11', Q11), 'q10', Q10), 'q9', Q9), 'q8', Q8), 'q7', Q7), 'q6', Q6), 'q5', Q5), 'q4', Q4), 'q3', Q3), 'q2', Q2), 'q1', Q1), '/', ' div '), 'k1|k3|k4|k6', '1') 
                 WHEN A.CACL_TYP_COD = 'Pri' THEN 
                      CASE WHEN A.AGE = A.NTRY_AGE THEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(RKRT_CALFM_RMK, 'q13', Q13), 'q12', Q12), 'q11', Q11), 'q10', Q10), 'q9', Q9), 'q8', Q8), 'q7', Q7), 'q6', Q6), 'q5', Q5), 'q4', Q4), 'q3', Q3), 'q2', Q2), 'q1', Q1), '/', ' div '), 'k1', '0.75'), 'k3', '0.5'), 'k4', '0'), 'k6', '0')         
                           WHEN A.AGE = A.NTRY_AGE + 1 THEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(RKRT_CALFM_RMK, 'q13', Q13), 'q12', Q12), 'q11', Q11), 'q10', Q10), 'q9', Q9), 'q8', Q8), 'q7', Q7), 'q6', Q6), 'q5', Q5), 'q4', Q4), 'q3', Q3), 'q2', Q2), 'q1', Q1), '/', ' div '), 'k1', '1'), 'k3', '1'), 'k4', '0'), 'k6', '0.75')          
                           ELSE REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(RKRT_CALFM_RMK, 'q13', Q13), 'q12', Q12), 'q11', Q11), 'q10', Q10), 'q9', Q9), 'q8', Q8), 'q7', Q7), 'q6', Q6), 'q5', Q5), 'q4', Q4), 'q3', Q3), 'q2', Q2), 'q1', Q1), '/', ' div '), 'k1', '1'), 'k3', '1'), 'k4', '0.75'), 'k6', '1')          
                           END
                 WHEN A.CACL_TYP_COD = 'CF' THEN
                      CASE WHEN A.AGE = A.NTRY_AGE AND A.YY_LSTH_PPRD <= 3 THEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(RKRT_CALFM_RMK, 'q13', Q13), 'q12', Q12), 'q11', Q11), 'q10', Q10), 'q9', Q9), 'q8', Q8), 'q7', Q7), 'q6', Q6), 'q5', Q5), 'q4', Q4), 'q3', Q3), 'q2', Q2), 'q1', Q1), '/', ' div '), 'k1', '0'), 'k3', '0'), 'k4', '0'), 'k6', '0')           
                           WHEN A.AGE = A.NTRY_AGE AND A.YY_LSTH_PPRD > 3 AND A.YY_LSTH_PPRD <= 6 THEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(RKRT_CALFM_RMK, 'q13', Q13), 'q12', Q12), 'q11', Q11), 'q10', Q10), 'q9', Q9), 'q8', Q8), 'q7', Q7), 'q6', Q6), 'q5', Q5), 'q4', Q4), 'q3', Q3), 'q2', Q2), 'q1', Q1), '/', ' div '), 'k1', '1'), 'k3', '0'), 'k4', '0'), 'k6', '0')
                           WHEN A.AGE = A.NTRY_AGE AND A.YY_LSTH_PPRD > 6 THEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(RKRT_CALFM_RMK, 'q13', Q13), 'q12', Q12), 'q11', Q11), 'q10', Q10), 'q9', Q9), 'q8', Q8), 'q7', Q7), 'q6', Q6), 'q5', Q5), 'q4', Q4), 'q3', Q3), 'q2', Q2), 'q1', Q1), '/', ' div '), 'k1', '1'), 'k3', '1'), 'k4', '0'), 'k6', '0')
                           WHEN A.AGE = A.NTRY_AGE + 1 AND A.YY_LSTH_PPRD <= 3 THEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(RKRT_CALFM_RMK, 'q13', Q13), 'q12', Q12), 'q11', Q11), 'q10', Q10), 'q9', Q9), 'q8', Q8), 'q7', Q7), 'q6', Q6), 'q5', Q5), 'q4', Q4), 'q3', Q3), 'q2', Q2), 'q1', Q1), '/', ' div '), 'k1', '1'), 'k3', '1'), 'k4', '0'), 'k6', '0')    
                           WHEN A.AGE = A.NTRY_AGE + 1 AND A.YY_LSTH_PPRD > 3 THEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(RKRT_CALFM_RMK, 'q13', Q13), 'q12', Q12), 'q11', Q11), 'q10', Q10), 'q9', Q9), 'q8', Q8), 'q7', Q7), 'q6', Q6), 'q5', Q5), 'q4', Q4), 'q3', Q3), 'q2', Q2), 'q1', Q1), '/', ' div '), 'k1', '1'), 'k3', '1'), 'k4', '0'), 'k6', '1')
                           WHEN A.AGE = A.NTRY_AGE + 2 AND A.YY_LSTH_PPRD <= 3 THEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(RKRT_CALFM_RMK, 'q13', Q13), 'q12', Q12), 'q11', Q11), 'q10', Q10), 'q9', Q9), 'q8', Q8), 'q7', Q7), 'q6', Q6), 'q5', Q5), 'q4', Q4), 'q3', Q3), 'q2', Q2), 'q1', Q1), '/', ' div '), 'k1', '1'), 'k3', '1'), 'k4', '0'), 'k6', '1')       
                           ELSE REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(RKRT_CALFM_RMK, 'q13', Q13), 'q12', Q12), 'q11', Q11), 'q10', Q10), 'q9', Q9), 'q8', Q8), 'q7', Q7), 'q6', Q6), 'q5', Q5), 'q4', Q4), 'q3', Q3), 'q2', Q2), 'q1', Q1), '/', ' div '), 'k1', '1'), 'k3', '1'), 'k4', '1'), 'k6', '1')
                           END     
            END AS RKRT_CALFM_RMK, A.GNDR_APPT_COD, A.NTRY_AGE, A.AGE, A.YY_LSTH_PPRD, A.CACL_TYP_COD
    FROM 
        (SELECT /*+FULL(A) PARALLEL(A 16) FULL(B) PARALLEL(B 16) USE_HASH(A B) USE_HASH(B A) SWAP_JOIN_INPUTS(B) PQ_DISTRIBUTE(A HASH HASH) NO_PX_JOIN_FILTER(A) USE_CONCAT*/   --use concat으로 각각의 unpivoting한 재료컬럼 13개 별로 반복스캔 조인하도록 유도함.
               B.IFRS_CLM_ID, B.RKRT_CALFM_RMK, A.GNDR_APPT_COD, A.NTRY_AGE, A.AGE, A.YY_LSTH_PPRD, A.CACL_TYP_COD
               , MAX(CASE WHEN A.RKRT_COD = B.RKRT_1_ID AND B.IFRS_CI_BFRT_CRT_LAST_AGE_COD > A.AGE THEN RKRT ELSE 0 END) AS Q1
               , MAX(CASE WHEN A.RKRT_COD = B.RKRT_2_ID AND B.IFRS_CI_BFRT_CRT_LAST_AGE_COD > A.AGE THEN RKRT ELSE 0 END) AS Q2
               , MAX(CASE WHEN A.RKRT_COD = B.RKRT_3_ID AND B.IFRS_CI_BFRT_CRT_LAST_AGE_COD > A.AGE THEN RKRT ELSE 0 END) AS Q3
               , MAX(CASE WHEN A.RKRT_COD = B.RKRT_4_ID AND B.IFRS_CI_BFRT_CRT_LAST_AGE_COD > A.AGE THEN RKRT ELSE 0 END) AS Q4
               , MAX(CASE WHEN A.RKRT_COD = B.RKRT_5_ID AND B.IFRS_CI_BFRT_CRT_LAST_AGE_COD > A.AGE THEN RKRT ELSE 0 END) AS Q5
               , MAX(CASE WHEN A.RKRT_COD = B.RKRT_6_ID AND B.IFRS_CI_BFRT_CRT_LAST_AGE_COD > A.AGE THEN RKRT ELSE 0 END) AS Q6
               , MAX(CASE WHEN A.RKRT_COD = B.RKRT_7_ID AND B.IFRS_CI_BFRT_CRT_LAST_AGE_COD > A.AGE THEN RKRT ELSE 0 END) AS Q7
               , MAX(CASE WHEN A.RKRT_COD = B.RKRT_8_ID AND B.IFRS_CI_BFRT_CRT_LAST_AGE_COD > A.AGE THEN RKRT ELSE 0 END) AS Q8
               , MAX(CASE WHEN A.RKRT_COD = B.RKRT_9_ID AND B.IFRS_CI_BFRT_CRT_LAST_AGE_COD > A.AGE THEN RKRT ELSE 0 END) AS Q9
               , MAX(CASE WHEN A.RKRT_COD = B.RKRT_10_ID AND B.IFRS_CI_BFRT_CRT_LAST_AGE_COD > A.AGE THEN RKRT ELSE 0 END) AS Q10
               , MAX(CASE WHEN A.RKRT_COD = B.RKRT_11_ID AND B.IFRS_CI_BFRT_CRT_LAST_AGE_COD > A.AGE THEN RKRT ELSE 0 END) AS Q11
               , MAX(CASE WHEN A.RKRT_COD = B.RKRT_12_ID AND B.IFRS_CI_BFRT_CRT_LAST_AGE_COD > A.AGE THEN RKRT ELSE 0 END) AS Q12
               , MAX(CASE WHEN A.RKRT_COD = B.RKRT_13_ID AND B.IFRS_CI_BFRT_CRT_LAST_AGE_COD > A.AGE THEN RKRT ELSE 0 END) AS Q13
        FROM 
            (SELECT /*+FULL(A) PARALLEL(A 16) NO_MERGE*/ IFRS_CLM_ID, CAST(CASE WHEN IFRS_CI_BFRT_CRT_LAST_AGE_COD IS NULL THEN '999' ELSE SUBSTR(IFRS_CI_BFRT_CRT_LAST_AGE_COD, 2, LENGTH(IFRS_CI_BFRT_CRT_LAST_AGE_COD)) END AS INTEGER) AS IFRS_CI_BFRT_CRT_LAST_AGE_COD, RKRT_CALFM_RMK
                  , RKRT_1_ID
                  , RKRT_2_ID
                  , RKRT_3_ID
                  , RKRT_4_ID
                  , RKRT_5_ID
                  , RKRT_6_ID
                  , RKRT_7_ID
                  , RKRT_8_ID
                  , RKRT_9_ID 
                  , RKRT_10_ID 
                  , RKRT_11_ID 
                  , RKRT_12_ID 
                  , RKRT_13_ID
            FROM CF_SIMU.IFRS_CI_BFRT_CRT_LST A WHERE CLO_YYMM ='201812' AND LAST_HIS_YN ='1' AND DEL_YN ='0'   --소스테이블의 마감년월에 맞춰서 CLO_YYMM 변경해줘야함.
            AND LENGTH(REPLACE(RKRT_1_ID||RKRT_2_ID||RKRT_3_ID||RKRT_4_ID||RKRT_5_ID||RKRT_6_ID||RKRT_7_ID||RKRT_8_ID||RKRT_9_ID||RKRT_10_ID||RKRT_11_ID||RKRT_12_ID||RKRT_13_ID, 'q')) = 
            LENGTH(RKRT_1_ID||RKRT_2_ID||RKRT_3_ID||RKRT_4_ID||RKRT_5_ID||RKRT_6_ID||RKRT_7_ID||RKRT_8_ID||RKRT_9_ID||RKRT_10_ID||RKRT_11_ID||RKRT_12_ID||RKRT_13_ID)
            )B --인라인뷰 B 내부의 'q'를 포함한행을 제외하는 조건은, 기초통계코드에는 'q'가 포함되지 않지만, lv1이상의 담보는 포함하기때문.
            , 
            (SELECT /*+FULL(A) PARALLEL(A 16) FULL(B) PARALLEL(B 16) SWAP_JOIN_INPUTS(B) PQ_DISTRIBUTE(B NONE BROADCAST) MERGE*/ A.RKRT_COD, A.GNDR_APPT_COD, 
                  CASE WHEN B.CACL_TYP_COD ='N' THEN 999 
                       ELSE (A.AGE - (CASE WHEN B.CACL_TYP_COD = 'Pri' THEN B.LV - 2 ELSE FLOOR((B.LV - 5)/12) END)) END AS NTRY_AGE
                  , A.AGE AS AGE
                  , CASE WHEN B.CACL_TYP_COD <> 'CF' THEN 0 ELSE MOD(B.LV -5, 12) + 1 END AS YY_LSTH_PPRD, A.RKRT
                  , B.CACL_TYP_COD 
            FROM MIG.FND_RKRT_INF A, --아래 inlineview B는 카티전 곱을 생성하기 위한 부분, readme 카티전곱 확인바람.
                 (SELECT LEVEL AS LV, CASE WHEN LEVEL = 1 THEN 'N' WHEN LEVEL > 1 AND LEVEL < 5 THEN 'Pri' ELSE 'CF' END AS CACL_TYP_COD FROM DUAL CONNECT BY LEVEL < 41) B 
            WHERE A.LAST_HIS_YN ='1' AND A.DEL_YN ='0' AND (A.AGE - (CASE WHEN B.CACL_TYP_COD = 'Pri' THEN B.LV - 2 ELSE FLOOR((B.LV - 5)/12) END)) > = 0 
            ) A
        WHERE A.RKRT_COD IN (B.RKRT_1_ID, B.RKRT_2_ID, B.RKRT_3_ID, B.RKRT_4_ID, B.RKRT_5_ID, B.RKRT_6_ID, B.RKRT_7_ID, B.RKRT_8_ID, B.RKRT_9_ID, B.RKRT_10_ID, B.RKRT_11_ID, B.RKRT_12_ID, B.RKRT_13_ID) 
        AND A.AGE < B.IFRS_CI_BFRT_CRT_LAST_AGE_COD     --최대연령코드값을 조건으로 결과행 제약함.
        GROUP BY B.IFRS_CLM_ID, B.RKRT_CALFM_RMK, A.GNDR_APPT_COD, A.NTRY_AGE, A.AGE, A.YY_LSTH_PPRD, A.CACL_TYP_COD
        ) A
    ) A
;
COMMIT;

--40초


------------------------------------------------------------------------------------------------
--###LEVEL 2~, 결과테이블을 참조하는 담보코드 산출, 어플리케이션에서 루프로 구성함.
------------------------------------------------------------------------------------------------

--반드시 계층별로 순차진행하면서 산출 값 왜곡되지 않도록 주의가 필요함.

--SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
--EXPLAIN PLAN FOR

INSERT /*+ENABLE_PARALLEL_DML PARALLEL(Z 16) OPT_PARAM('_OPTIMIZER_GATHER_STATS_ON_LOAD' 'FALSE') */ 
INTO CF_SIMU.CI_BFRT_INF Z      --아래 '201812'는 결과를 사용하려는 마감년월(CLO_YYMM)로 어플리케이션에서 사용자의 입력을 받도록 함, XMLQUERY() 는 string을 해석하는 부분
SELECT /*+PARALLEL(A 16)*/ '201812' AS CLO_YYMM, A.IFRS_CLM_ID, A.GNDR_APPT_COD, A.AGE, A.NTRY_AGE, A.YY_LSTH_PPRD, A.CACL_TYP_COD, XMLQUERY(RKRT_CALFM_RMK RETURNING CONTENT).GETNUMBERVAL() AS RKRT_VL 
FROM 
    (SELECT /*+PARALLEL(A 16)*/
          A.IFRS_CLM_ID
          , CASE WHEN A.CACL_TYP_COD = 'N' THEN REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(RKRT_CALFM_RMK, 'q13', Q13), 'q12', Q12), 'q11', Q11), 'q10', Q10), 'q9', Q9), 'q8', Q8), 'q7', Q7), 'q6', Q6), 'q5', Q5), 'q4', Q4), 'q3', Q3), 'q2', Q2), 'q1', Q1), '/', ' div '), 'k1|k3|k4|k6', '1') 
                 WHEN A.CACL_TYP_COD = 'Pri' THEN 
                      CASE WHEN A.AGE = A.NTRY_AGE THEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(RKRT_CALFM_RMK, 'q13', Q13), 'q12', Q12), 'q11', Q11), 'q10', Q10), 'q9', Q9), 'q8', Q8), 'q7', Q7), 'q6', Q6), 'q5', Q5), 'q4', Q4), 'q3', Q3), 'q2', Q2), 'q1', Q1), '/', ' div '), 'k1', '0.75'), 'k3', '0.5'), 'k4', '0'), 'k6', '0')         
                           WHEN A.AGE = A.NTRY_AGE + 1 THEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(RKRT_CALFM_RMK, 'q13', Q13), 'q12', Q12), 'q11', Q11), 'q10', Q10), 'q9', Q9), 'q8', Q8), 'q7', Q7), 'q6', Q6), 'q5', Q5), 'q4', Q4), 'q3', Q3), 'q2', Q2), 'q1', Q1), '/', ' div '), 'k1', '1'), 'k3', '1'), 'k4', '0'), 'k6', '0.75')          
                           ELSE REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(RKRT_CALFM_RMK, 'q13', Q13), 'q12', Q12), 'q11', Q11), 'q10', Q10), 'q9', Q9), 'q8', Q8), 'q7', Q7), 'q6', Q6), 'q5', Q5), 'q4', Q4), 'q3', Q3), 'q2', Q2), 'q1', Q1), '/', ' div '), 'k1', '1'), 'k3', '1'), 'k4', '0.75'), 'k6', '1')          
                           END
                 WHEN A.CACL_TYP_COD = 'CF' THEN
                      CASE WHEN A.AGE = A.NTRY_AGE AND A.YY_LSTH_PPRD <= 3 THEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(RKRT_CALFM_RMK, 'q13', Q13), 'q12', Q12), 'q11', Q11), 'q10', Q10), 'q9', Q9), 'q8', Q8), 'q7', Q7), 'q6', Q6), 'q5', Q5), 'q4', Q4), 'q3', Q3), 'q2', Q2), 'q1', Q1), '/', ' div '), 'k1', '0'), 'k3', '0'), 'k4', '0'), 'k6', '0')           
                           WHEN A.AGE = A.NTRY_AGE AND A.YY_LSTH_PPRD > 3 AND A.YY_LSTH_PPRD <= 6 THEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(RKRT_CALFM_RMK, 'q13', Q13), 'q12', Q12), 'q11', Q11), 'q10', Q10), 'q9', Q9), 'q8', Q8), 'q7', Q7), 'q6', Q6), 'q5', Q5), 'q4', Q4), 'q3', Q3), 'q2', Q2), 'q1', Q1), '/', ' div '), 'k1', '1'), 'k3', '0'), 'k4', '0'), 'k6', '0')
                           WHEN A.AGE = A.NTRY_AGE AND A.YY_LSTH_PPRD > 6 THEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(RKRT_CALFM_RMK, 'q13', Q13), 'q12', Q12), 'q11', Q11), 'q10', Q10), 'q9', Q9), 'q8', Q8), 'q7', Q7), 'q6', Q6), 'q5', Q5), 'q4', Q4), 'q3', Q3), 'q2', Q2), 'q1', Q1), '/', ' div '), 'k1', '1'), 'k3', '1'), 'k4', '0'), 'k6', '0')
                           WHEN A.AGE = A.NTRY_AGE + 1 AND A.YY_LSTH_PPRD <= 3 THEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(RKRT_CALFM_RMK, 'q13', Q13), 'q12', Q12), 'q11', Q11), 'q10', Q10), 'q9', Q9), 'q8', Q8), 'q7', Q7), 'q6', Q6), 'q5', Q5), 'q4', Q4), 'q3', Q3), 'q2', Q2), 'q1', Q1), '/', ' div '), 'k1', '1'), 'k3', '1'), 'k4', '0'), 'k6', '0')    
                           WHEN A.AGE = A.NTRY_AGE + 1 AND A.YY_LSTH_PPRD > 3 THEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(RKRT_CALFM_RMK, 'q13', Q13), 'q12', Q12), 'q11', Q11), 'q10', Q10), 'q9', Q9), 'q8', Q8), 'q7', Q7), 'q6', Q6), 'q5', Q5), 'q4', Q4), 'q3', Q3), 'q2', Q2), 'q1', Q1), '/', ' div '), 'k1', '1'), 'k3', '1'), 'k4', '0'), 'k6', '1')
                           WHEN A.AGE = A.NTRY_AGE + 2 AND A.YY_LSTH_PPRD <= 3 THEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(RKRT_CALFM_RMK, 'q13', Q13), 'q12', Q12), 'q11', Q11), 'q10', Q10), 'q9', Q9), 'q8', Q8), 'q7', Q7), 'q6', Q6), 'q5', Q5), 'q4', Q4), 'q3', Q3), 'q2', Q2), 'q1', Q1), '/', ' div '), 'k1', '1'), 'k3', '1'), 'k4', '0'), 'k6', '1')       
                           ELSE REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(RKRT_CALFM_RMK, 'q13', Q13), 'q12', Q12), 'q11', Q11), 'q10', Q10), 'q9', Q9), 'q8', Q8), 'q7', Q7), 'q6', Q6), 'q5', Q5), 'q4', Q4), 'q3', Q3), 'q2', Q2), 'q1', Q1), '/', ' div '), 'k1', '1'), 'k3', '1'), 'k4', '1'), 'k6', '1')
                           END     
            END AS RKRT_CALFM_RMK, A.GNDR_APPT_COD, A.NTRY_AGE, A.AGE, A.YY_LSTH_PPRD, A.CACL_TYP_COD
    FROM 
        (SELECT /*+PARALLEL(A 16) */ A.IFRS_CLM_ID, A.RKRT_CALFM_RMK, A.GNDR_APPT_COD, A.NTRY_AGE, A.AGE, A.YY_LSTH_PPRD, A.CACL_TYP_COD
              , NVL(MAX(Q1), 0) AS Q1, NVL(MAX(Q2), 0) AS Q2, NVL(MAX(Q3), 0) AS Q3, NVL(MAX(Q4), 0) AS Q4, NVL(MAX(Q5), 0) AS Q5, NVL(MAX(Q6), 0) AS Q6, NVL(MAX(Q7), 0) AS Q7
              , NVL(MAX(Q8), 0) AS Q8, NVL(MAX(Q9), 0) AS Q9, NVL(MAX(Q10), 0) AS Q10, NVL(MAX(Q11), 0) AS Q11, NVL(MAX(Q12), 0) AS Q12, NVL(MAX(Q13), 0) AS Q13 
        FROM 
            (SELECT /*+FULL(A) PARALLEL(A 16) FULL(B) PARALLEL(B 16) USE_HASH(A B) USE_HASH(B A) SWAP_JOIN_INPUTS(B) PQ_DISTRIBUTE(A HASH HASH) NO_PX_JOIN_FILTER(A) USE_CONCAT*/   --use concat으로 각각의 unpivoting한 재료컬럼 13개 별로 반복스캔 조인하도록 유도
               B.IFRS_CLM_ID, B.RKRT_CALFM_RMK, A.GNDR_APPT_COD, A.AGE, A.NTRY_AGE, A.YY_LSTH_PPRD, A.CACL_TYP_COD
               , MAX(CASE WHEN A.IFRS_CLM_ID = NVL(B.RKRT_1_ID, 0) AND B.IFRS_CI_BFRT_CRT_LAST_AGE_COD > A.AGE THEN A.RKRT_VL END) AS Q1
               , MAX(CASE WHEN A.IFRS_CLM_ID = NVL(B.RKRT_2_ID, 0) AND B.IFRS_CI_BFRT_CRT_LAST_AGE_COD > A.AGE THEN A.RKRT_VL END) AS Q2
               , MAX(CASE WHEN A.IFRS_CLM_ID = NVL(B.RKRT_3_ID, 0) AND B.IFRS_CI_BFRT_CRT_LAST_AGE_COD > A.AGE THEN A.RKRT_VL END) AS Q3
               , MAX(CASE WHEN A.IFRS_CLM_ID = NVL(B.RKRT_4_ID, 0) AND B.IFRS_CI_BFRT_CRT_LAST_AGE_COD > A.AGE THEN A.RKRT_VL END) AS Q4
               , MAX(CASE WHEN A.IFRS_CLM_ID = NVL(B.RKRT_5_ID, 0) AND B.IFRS_CI_BFRT_CRT_LAST_AGE_COD > A.AGE THEN A.RKRT_VL END) AS Q5
               , MAX(CASE WHEN A.IFRS_CLM_ID = NVL(B.RKRT_6_ID, 0) AND B.IFRS_CI_BFRT_CRT_LAST_AGE_COD > A.AGE THEN A.RKRT_VL END) AS Q6
               , MAX(CASE WHEN A.IFRS_CLM_ID = NVL(B.RKRT_7_ID, 0) AND B.IFRS_CI_BFRT_CRT_LAST_AGE_COD > A.AGE THEN A.RKRT_VL END) AS Q7
               , MAX(CASE WHEN A.IFRS_CLM_ID = NVL(B.RKRT_8_ID, 0) AND B.IFRS_CI_BFRT_CRT_LAST_AGE_COD > A.AGE THEN A.RKRT_VL END) AS Q8
               , MAX(CASE WHEN A.IFRS_CLM_ID = NVL(B.RKRT_9_ID, 0) AND B.IFRS_CI_BFRT_CRT_LAST_AGE_COD > A.AGE THEN A.RKRT_VL END) AS Q9
               , MAX(CASE WHEN A.IFRS_CLM_ID = NVL(B.RKRT_10_ID, 0) AND B.IFRS_CI_BFRT_CRT_LAST_AGE_COD > A.AGE THEN A.RKRT_VL END) AS Q10
               , MAX(CASE WHEN A.IFRS_CLM_ID = NVL(B.RKRT_11_ID, 0) AND B.IFRS_CI_BFRT_CRT_LAST_AGE_COD > A.AGE THEN A.RKRT_VL END) AS Q11
               , MAX(CASE WHEN A.IFRS_CLM_ID = NVL(B.RKRT_12_ID, 0) AND B.IFRS_CI_BFRT_CRT_LAST_AGE_COD > A.AGE THEN A.RKRT_VL END) AS Q12
               , MAX(CASE WHEN A.IFRS_CLM_ID = NVL(B.RKRT_13_ID, 0) AND B.IFRS_CI_BFRT_CRT_LAST_AGE_COD > A.AGE THEN A.RKRT_VL END) AS Q13
            FROM 
                (SELECT /*+FULL(A) PARALLEL(A 16) NO_MERGE*/ A.IFRS_CLM_ID, CAST(CASE WHEN A.IFRS_CI_BFRT_CRT_LAST_AGE_COD IS NULL THEN '999' ELSE SUBSTR(A.IFRS_CI_BFRT_CRT_LAST_AGE_COD, 2, LENGTH(A.IFRS_CI_BFRT_CRT_LAST_AGE_COD)) END AS INTEGER) AS IFRS_CI_BFRT_CRT_LAST_AGE_COD, RKRT_CALFM_RMK
                      , RKRT_1_ID
                      , RKRT_2_ID
                      , RKRT_3_ID
                      , RKRT_4_ID
                      , RKRT_5_ID
                      , RKRT_6_ID
                      , RKRT_7_ID
                      , RKRT_8_ID
                      , RKRT_9_ID 
                      , RKRT_10_ID 
                      , RKRT_11_ID 
                      , RKRT_12_ID 
                      , RKRT_13_ID
                FROM CF_SIMU.IFRS_CI_BFRT_CRT_LST A,
                    (SELECT IFRS_CLM_ID FROM (
                        SELECT LEVEL AS LV, IFRS_CLM_ID 
                        FROM 
                            (SELECT /*+FULL(A) PARALLEL(A 16) */ IFRS_CLM_ID, RKRT_ID
                            FROM 
                                (SELECT * FROM CF_SIMU.IFRS_CI_BFRT_CRT_LST WHERE CLO_YYMM ='201812' AND LAST_HIS_YN ='1' AND DEL_YN ='0') A   --소스테이블의 마감년월에 맞춰서 CLO_YYMM 변경해줘야함.
                                UNPIVOT(RKRT_ID FOR ID_NUM IN(RKRT_1_ID,RKRT_2_ID,RKRT_3_ID,RKRT_4_ID,RKRT_5_ID,RKRT_6_ID,RKRT_7_ID,RKRT_8_ID,RKRT_9_ID,RKRT_10_ID,RKRT_11_ID,RKRT_12_ID,RKRT_13_ID))
                            )
                        CONNECT BY NOCYCLE PRIOR IFRS_CLM_ID = RKRT_ID) WHERE LV =2) B	--계산할 계층에 맞춰 LV 변경해줘야함. 순차루프진행하며 해당 루프때의 계층은 앱에서 입력해줌.
                WHERE A.CLO_YYMM ='201812' AND A.LAST_HIS_YN ='1' AND A.DEL_YN ='0' AND A.IFRS_CLM_ID = B.IFRS_CLM_ID   --소스테이블의 마감년월에 맞춰서 CLO_YYMM 변경해줘야함.
                )B 
                , (SELECT /*+FULL(A) PARALLEL(A 16) */ * FROM CF_SIMU.CI_BFRT_INF A) A
            WHERE A.IFRS_CLM_ID IN (B.RKRT_1_ID, B.RKRT_2_ID, B.RKRT_3_ID, B.RKRT_4_ID, B.RKRT_5_ID, B.RKRT_6_ID, B.RKRT_7_ID, B.RKRT_8_ID, B.RKRT_9_ID, RKRT_10_ID, RKRT_11_ID, RKRT_12_ID, RKRT_13_ID)
            GROUP BY B.IFRS_CLM_ID, B.RKRT_CALFM_RMK, A.GNDR_APPT_COD, A.AGE, A.NTRY_AGE, A.YY_LSTH_PPRD, A.CACL_TYP_COD
            
            UNION ALL   --union all의 위로는 구성정보(소스2)와 결과테이블(소스3)에 대한 조인, 아래로는 구성정보(소스2)와 기간계 기초테이블(소스1)에 대한 조인임. 두 결과를 합치면서 group by로 필요한 재료를 모음.
                        --동시에 소스2,소스1,소스3과 조인하지 못하는 이유는 데이터 정합성 때문임. 소스1을 하나도 참조하지 않는 경우도 있기 때문임. 
                        --게다가 단순히 outer join으로 하기에는 카티전곱으로 레코드 수가 너무 늘어나서 부파가 걸리므로, 차라리 두번 각각 독립적으로 조인하고 합치는 편이 부하가 적음.
            
            SELECT /*+FULL(A) PARALLEL(A 16) FULL(B) PARALLEL(B 16) USE_HASH(A B) USE_HASH(B A) SWAP_JOIN_INPUTS(B) PQ_DISTRIBUTE(A HASH HASH) NO_PX_JOIN_FILTER(A) USE_CONCAT*/
                   B.IFRS_CLM_ID, B.RKRT_CALFM_RMK, A.GNDR_APPT_COD, A.AGE, A.NTRY_AGE, A.YY_LSTH_PPRD, A.CACL_TYP_COD
                   , MAX(CASE WHEN A.RKRT_COD = B.RKRT_1_ID AND B.IFRS_CI_BFRT_CRT_LAST_AGE_COD > A.AGE THEN RKRT END) AS Q1
                   , MAX(CASE WHEN A.RKRT_COD = B.RKRT_2_ID AND B.IFRS_CI_BFRT_CRT_LAST_AGE_COD > A.AGE THEN RKRT END) AS Q2
                   , MAX(CASE WHEN A.RKRT_COD = B.RKRT_3_ID AND B.IFRS_CI_BFRT_CRT_LAST_AGE_COD > A.AGE THEN RKRT END) AS Q3
                   , MAX(CASE WHEN A.RKRT_COD = B.RKRT_4_ID AND B.IFRS_CI_BFRT_CRT_LAST_AGE_COD > A.AGE THEN RKRT END) AS Q4
                   , MAX(CASE WHEN A.RKRT_COD = B.RKRT_5_ID AND B.IFRS_CI_BFRT_CRT_LAST_AGE_COD > A.AGE THEN RKRT END) AS Q5
                   , MAX(CASE WHEN A.RKRT_COD = B.RKRT_6_ID AND B.IFRS_CI_BFRT_CRT_LAST_AGE_COD > A.AGE THEN RKRT END) AS Q6
                   , MAX(CASE WHEN A.RKRT_COD = B.RKRT_7_ID AND B.IFRS_CI_BFRT_CRT_LAST_AGE_COD > A.AGE THEN RKRT END) AS Q7
                   , MAX(CASE WHEN A.RKRT_COD = B.RKRT_8_ID AND B.IFRS_CI_BFRT_CRT_LAST_AGE_COD > A.AGE THEN RKRT END) AS Q8
                   , MAX(CASE WHEN A.RKRT_COD = B.RKRT_9_ID AND B.IFRS_CI_BFRT_CRT_LAST_AGE_COD > A.AGE THEN RKRT END) AS Q9
                   , MAX(CASE WHEN A.RKRT_COD = B.RKRT_10_ID AND B.IFRS_CI_BFRT_CRT_LAST_AGE_COD > A.AGE THEN RKRT END) AS Q10
                   , MAX(CASE WHEN A.RKRT_COD = B.RKRT_11_ID AND B.IFRS_CI_BFRT_CRT_LAST_AGE_COD > A.AGE THEN RKRT END) AS Q11
                   , MAX(CASE WHEN A.RKRT_COD = B.RKRT_12_ID AND B.IFRS_CI_BFRT_CRT_LAST_AGE_COD > A.AGE THEN RKRT END) AS Q12
                   , MAX(CASE WHEN A.RKRT_COD = B.RKRT_13_ID AND B.IFRS_CI_BFRT_CRT_LAST_AGE_COD > A.AGE THEN RKRT END) AS Q13
            FROM 
                (SELECT /*+FULL(A) PARALLEL(A 16) NO_MERGE*/ A.IFRS_CLM_ID, CAST(CASE WHEN A.IFRS_CI_BFRT_CRT_LAST_AGE_COD IS NULL THEN '999' ELSE SUBSTR(A.IFRS_CI_BFRT_CRT_LAST_AGE_COD, 2, LENGTH(A.IFRS_CI_BFRT_CRT_LAST_AGE_COD)) END AS INTEGER) AS IFRS_CI_BFRT_CRT_LAST_AGE_COD, RKRT_CALFM_RMK
                      , RKRT_1_ID
                      , RKRT_2_ID
                      , RKRT_3_ID
                      , RKRT_4_ID
                      , RKRT_5_ID
                      , RKRT_6_ID
                      , RKRT_7_ID
                      , RKRT_8_ID
                      , RKRT_9_ID 
                      , RKRT_10_ID 
                      , RKRT_11_ID 
                      , RKRT_12_ID 
                      , RKRT_13_ID
                FROM CF_SIMU.IFRS_CI_BFRT_CRT_LST A, 
                    (SELECT IFRS_CLM_ID FROM (
                    SELECT LEVEL AS LV, IFRS_CLM_ID 
                    FROM 
                        (SELECT /*+FULL(A) PARALLEL(A 16) */ IFRS_CLM_ID, RKRT_ID
                        FROM 
                            (SELECT * FROM CF_SIMU.IFRS_CI_BFRT_CRT_LST WHERE CLO_YYMM ='201812' AND LAST_HIS_YN ='1' AND DEL_YN ='0') A    --소스테이블의 마감년월에 맞춰서 CLO_YYMM 변경해줘야함
                            UNPIVOT(RKRT_ID FOR ID_NUM IN(RKRT_1_ID,RKRT_2_ID,RKRT_3_ID,RKRT_4_ID,RKRT_5_ID,RKRT_6_ID,RKRT_7_ID,RKRT_8_ID,RKRT_9_ID,RKRT_10_ID,RKRT_11_ID,RKRT_12_ID,RKRT_13_ID))
                        )
                    CONNECT BY NOCYCLE PRIOR IFRS_CLM_ID = RKRT_ID) WHERE LV =2) B	--계산할 계층에 맞춰 LV 변경해줘야함. 순차루프진행하며 해당 루프때의 계층은 앱에서 입력해줌.
                WHERE A.CLO_YYMM ='201812' AND A.LAST_HIS_YN ='1' AND A.DEL_YN ='0' AND A.IFRS_CLM_ID = B.IFRS_CLM_ID
                )B 
                , 
                (SELECT /*+FULL(A) PARALLEL(A 16) FULL(B) PARALLEL(B 16) SWAP_JOIN_INPUTS(B) PQ_DISTRIBUTE(B NONE BROADCAST) MERGE*/ A.RKRT_COD, A.GNDR_APPT_COD, 
                      CASE WHEN B.CACL_TYP_COD ='N' THEN 999 
                           ELSE (A.AGE - (CASE WHEN B.CACL_TYP_COD = 'Pri' THEN B.LV - 2 ELSE FLOOR((B.LV - 5)/12) END)) END AS NTRY_AGE
                      , A.AGE AS AGE
                      , CASE WHEN B.CACL_TYP_COD <> 'CF' THEN 0 ELSE MOD(B.LV -5, 12) + 1 END AS YY_LSTH_PPRD, A.RKRT
                      , B.CACL_TYP_COD 
                FROM MIG.FND_RKRT_INF A,    --아래 inlineview B는 카티전 곱을 생성하기 위한 부분, readme 카티전곱 확인바람.
                     (SELECT LEVEL AS LV, CASE WHEN LEVEL = 1 THEN 'N' WHEN LEVEL > 1 AND LEVEL < 5 THEN 'Pri' ELSE 'CF' END AS CACL_TYP_COD FROM DUAL CONNECT BY LEVEL < 41) B 
                WHERE A.MIG_CLO_YYMM ='201812' AND A.LAST_HIS_YN ='1' AND A.DEL_YN ='0' AND (A.AGE - (CASE WHEN B.CACL_TYP_COD = 'Pri' THEN B.LV - 2 ELSE FLOOR((B.LV - 5)/12) END)) > = 0  --소스테이블의 마감년월에 맞춰서 CLO_YYMM 변경해줘야함
                ) A
            WHERE A.RKRT_COD IN (B.RKRT_1_ID, B.RKRT_2_ID, B.RKRT_3_ID, B.RKRT_4_ID, B.RKRT_5_ID, B.RKRT_6_ID, B.RKRT_7_ID, B.RKRT_8_ID, B.RKRT_9_ID, B.RKRT_10_ID, B.RKRT_11_ID, B.RKRT_12_ID, B.RKRT_13_ID) 
            AND A.AGE < B.IFRS_CI_BFRT_CRT_LAST_AGE_COD 
            GROUP BY B.IFRS_CLM_ID, B.RKRT_CALFM_RMK, A.GNDR_APPT_COD, A.NTRY_AGE, A.AGE, A.YY_LSTH_PPRD, A.CACL_TYP_COD
            ) A 
        GROUP BY A.IFRS_CLM_ID, A.RKRT_CALFM_RMK, A.GNDR_APPT_COD, A.AGE, A.NTRY_AGE, A.YY_LSTH_PPRD, A.CACL_TYP_COD
        ) A
    ) A    
;

COMMIT;

--레벨이 높아질수록 레코드수가 줄어듬. 레벨2가 약 50초정도로 현 최대레벨 5까지(2~5) 150초 정도 소요됨


```
