

--보험 상품의 ci담보(각종 13대 암, 두번째 암발생률 등)의 위험률을 기초자료(소스테이블 1,2)를 이용하여 생성하기 위한 작업.

SELECT * FROM MIG.FND_RKRT_INF WHERE LAST_HIS_YN ='1' AND DEL_YN ='0';
--RISK_RATE   --SOURCE2, 사용대상만 최신여부와 사용불가여부 두개의 flag로 구분되는 테이블
SELECT * FROM CF_SIMU.IFRS_CI_BFRT_CRT_LST WHERE CLO_YYMM ='201812' AND LAST_HIS_YN ='1' AND DEL_YN ='0';
--Gen_CI_Rate   --SOURCE1
SELECT * FROM CF_SIMU.CI_BFRT_INF;
--CI_Ben_Rate    TARGET
--RISK RATE TABLE에 CLO_YYMM(마감년월)이 없음. 주의해야함. 신회계적용부터 결산단계에 기생성 담보율의 로그를 가지고 있어야 통계정보차이나 가정차를 반영할 수 있으므로 파티셔닝건의필요.=> 마감년월 파티셔닝 추가함.


--각CI 담보코드 별로 계층 확인하기
--CI담보율은 일반 위험률만의 조합이 아니라 기생성 CI담보를 재참조하는 재귀정보임. 그리고 그 특유의 정보관리어려움(계산식 매우 복잡, 기간계정보 오류 잦음, 계리사용자 착오 등)으로 정합성 관리 반드시 할것
--특히 CI 담보율의 소스테이블들은 앱에서의 호출과 사용자 입력 최적화를 위해 정규화와 데이터정합성 확인을 위한 테이블구조가 아님. 별도의 데이터정합성 쿼리 작성할것.
--하나의 담보코드(output대상)가 여러개의 위험률코드1~13번(RKRT_1_ID~RKRT_13_ID) 컬럼에 있는 값을 참조하는데(참조값이 언제나 13개 컬럼모두채워져있지 않으므로 주의), 이때 각 위험률코드가 이미 기생성되어 있는 담보코드(output대상)를 재참조하여 재귀적 관계가 있음.
--아무것도 참조하지 않고 담보코드가 아닌 기초데이터만을 사용하는 대상은 LV1, 그리고 참조하는 위험률코드중 가장 높은LV + 1이 해당 담보코드의 LV(계층)이 됨.
--ex) 담보코드가 참조하는 위험률코드의 레벨들이1,3, 혹은 담보코드가아닌 소스데이터들(편의상lv0)이라면 이때 가장 높은 참조 계층이 3이라면 해당 담보코드는 LV4가 됨.

--아래 쿼리로 사용자가 의도한대로 각 계층별 담보코드가 맞게 입력되어있는지 확인.
SELECT MAX(LENGTH(PATH) - LENGTH(REPLACE(PATH, '/'))) AS LV, IFRS_CLM_ID
FROM 
    (SELECT SYS_CONNECT_BY_PATH(IFRS_CLM_ID, '/') AS PATH, IFRS_CLM_ID, RKRT_ID 
    FROM 
        (SELECT /*+FULL(A) PARALLEL(A 16) */ IFRS_CLM_ID, RKRT_ID
        FROM 
            (SELECT * FROM CF_SIMU.IFRS_CI_BFRT_CRT_LST WHERE CLO_YYMM ='201812' AND LAST_HIS_YN ='1' AND DEL_YN ='0') A
            UNPIVOT(RKRT_ID FOR ID_NUM IN(RKRT_1_ID,RKRT_2_ID,RKRT_3_ID,RKRT_4_ID,RKRT_5_ID,RKRT_6_ID,RKRT_7_ID,RKRT_8_ID,RKRT_9_ID,RKRT_10_ID,RKRT_11_ID,RKRT_12_ID,RKRT_13_ID))
        )
    CONNECT BY NOCYCLE PRIOR IFRS_CLM_ID = RKRT_ID 
    ) A 
GROUP BY IFRS_CLM_ID ORDER BY 1,2;





--가장 최하계층과 그 위의 계층부터 조인대상이 달라지므로(계층1은 재귀적이지 않으나 계층2부터는 계층1결과값을 스스로 참조해야하므로 LV2부터는 재귀관계있음) 쿼리를 두가지로 구분하여 가지고 있어야함. 그리고 2이상의 상위계층 루프를 앱단에서 작성하도록 함.
--이전 작업방식이 어플리케이션에서 사용하는 SQLITE의 특유기능을 사용하였으나 ORACLE에서 지원 불가, 따라서 XML QUERY이용함.
--계산식을 담고 있는 RKRT_CALFM_RMK(컬럼 값 예시: Q1+Q2/2-(1-Q3*Q4)) 컬럼내는 Q1(1번위험률)~ Q13(13번위험률)을이용한 계산식을 표현하고 있으므로 xml표현식으로 각각의 맵핑된 값을 넣어서 계산값을 반환받아 INSERT해야함.
--각 위험률 특유의(여러암발생률의 최대연령, 통계가있는 연령이 다름) 최대기간이 있으나 다른 위험률에 값이 있다면 계산을 해야하므로  프로젝션기간 누락없도록 할것.
--정규화되어있지 않아 각각의 CACL_TYP_COD(CI담보산출목적)컬럼 값 Pri, CF, N별로 계산해내야하는 방식과(부담보기간 적용여부 등) 3차원기간적용방식이 다르므로 주의가 필요함.
--카티전곱으로 강제로 기간을 늘려서 위의 계산방식에 맞춰서 값을 생성해주고, 조건에 맞지 않는 레코드는 필터링해서 필요한 값만을 넣는 것이 정합성 유지가 편할 것이라 판단함.

------------------------------------------------------------------------------------------------
--LEVEL 1, 최하계층을 위한 쿼리. 값검증 끝났음. 다만 계층 2~ 이상은 컬럼단위로 잡아와서 작업을 진행해야함.
------------------------------------------------------------------------------------------------

--SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
--EXPLAIN PLAN FOR
```sql
INSERT /*+ENABLE_PARALLEL_DML PARALLEL(Z 16) OPT_PARAM('_OPTIMIZER_GATHER_STATS_ON_LOAD' 'FALSE') */ 
INTO CF_SIMU.CI_BFRT_INF Z       --아래에 입력해야하는 마감년월에 맞춰서 CLO_YYMM 변경해줘야함. 07.21기준
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
        (SELECT /*+FULL(A) PARALLEL(A 16) FULL(B) PARALLEL(B 16) USE_HASH(A B) USE_HASH(B A) SWAP_JOIN_INPUTS(B) PQ_DISTRIBUTE(A HASH HASH) NO_PX_JOIN_FILTER(A) USE_CONCAT*/
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
            FROM CF_SIMU.IFRS_CI_BFRT_CRT_LST A WHERE CLO_YYMM ='201812' AND LAST_HIS_YN ='1' AND DEL_YN ='0'   --입력해야하는 마감년월에 맞춰서 CLO_YYMM 변경해줘야함. 07.21기준
            AND LENGTH(REPLACE(RKRT_1_ID||RKRT_2_ID||RKRT_3_ID||RKRT_4_ID||RKRT_5_ID||RKRT_6_ID||RKRT_7_ID||RKRT_8_ID||RKRT_9_ID||RKRT_10_ID||RKRT_11_ID||RKRT_12_ID||RKRT_13_ID, 'q')) = 
            LENGTH(RKRT_1_ID||RKRT_2_ID||RKRT_3_ID||RKRT_4_ID||RKRT_5_ID||RKRT_6_ID||RKRT_7_ID||RKRT_8_ID||RKRT_9_ID||RKRT_10_ID||RKRT_11_ID||RKRT_12_ID||RKRT_13_ID)
            )B 
            , 
            (SELECT /*+FULL(A) PARALLEL(A 16) FULL(B) PARALLEL(B 16) SWAP_JOIN_INPUTS(B) PQ_DISTRIBUTE(B NONE BROADCAST) MERGE*/ A.RKRT_COD, A.GNDR_APPT_COD, 
                  CASE WHEN B.CACL_TYP_COD ='N' THEN 999 
                       ELSE (A.AGE - (CASE WHEN B.CACL_TYP_COD = 'Pri' THEN B.LV - 2 ELSE FLOOR((B.LV - 5)/12) END)) END AS NTRY_AGE
                  , A.AGE AS AGE
                  , CASE WHEN B.CACL_TYP_COD <> 'CF' THEN 0 ELSE MOD(B.LV -5, 12) + 1 END AS YY_LSTH_PPRD, A.RKRT
                  , B.CACL_TYP_COD 
            FROM MIG.FND_RKRT_INF A, 
                 (SELECT LEVEL AS LV, CASE WHEN LEVEL = 1 THEN 'N' WHEN LEVEL > 1 AND LEVEL < 5 THEN 'Pri' ELSE 'CF' END AS CACL_TYP_COD FROM DUAL CONNECT BY LEVEL < 41) B 
            WHERE A.LAST_HIS_YN ='1' AND A.DEL_YN ='0' AND (A.AGE - (CASE WHEN B.CACL_TYP_COD = 'Pri' THEN B.LV - 2 ELSE FLOOR((B.LV - 5)/12) END)) > = 0 
            ) A
        WHERE A.RKRT_COD IN (B.RKRT_1_ID, B.RKRT_2_ID, B.RKRT_3_ID, B.RKRT_4_ID, B.RKRT_5_ID, B.RKRT_6_ID, B.RKRT_7_ID, B.RKRT_8_ID, B.RKRT_9_ID, B.RKRT_10_ID, B.RKRT_11_ID, B.RKRT_12_ID, B.RKRT_13_ID) 
        AND A.AGE < B.IFRS_CI_BFRT_CRT_LAST_AGE_COD 
        GROUP BY B.IFRS_CLM_ID, B.RKRT_CALFM_RMK, A.GNDR_APPT_COD, A.NTRY_AGE, A.AGE, A.YY_LSTH_PPRD, A.CACL_TYP_COD
        ) A
    ) A
;
COMMIT;
```

------------------------------------------------------------------------------------------------
--LEVEL 2~ 를 위한 쿼리
------------------------------------------------------------------------------------------------
--SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
--EXPLAIN PLAN FOR

INSERT /*+ENABLE_PARALLEL_DML PARALLEL(Z 16) OPT_PARAM('_OPTIMIZER_GATHER_STATS_ON_LOAD' 'FALSE') */ 
INTO CF_SIMU.CI_BFRT_INF Z      --아래에 입력해야하는 마감년월에 맞춰서 CLO_YYMM 변경해줘야함. 07.21기준
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
            (SELECT /*+FULL(A) PARALLEL(A 16) FULL(B) PARALLEL(B 16) USE_HASH(A B) USE_HASH(B A) SWAP_JOIN_INPUTS(B) PQ_DISTRIBUTE(A HASH HASH) NO_PX_JOIN_FILTER(A) USE_CONCAT*/
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
                                (SELECT * FROM CF_SIMU.IFRS_CI_BFRT_CRT_LST WHERE CLO_YYMM ='201812' AND LAST_HIS_YN ='1' AND DEL_YN ='0') A    --입력해야하는 마감년월에 맞춰서 CLO_YYMM 변경해줘야함. 07.21기준
                                UNPIVOT(RKRT_ID FOR ID_NUM IN(RKRT_1_ID,RKRT_2_ID,RKRT_3_ID,RKRT_4_ID,RKRT_5_ID,RKRT_6_ID,RKRT_7_ID,RKRT_8_ID,RKRT_9_ID,RKRT_10_ID,RKRT_11_ID,RKRT_12_ID,RKRT_13_ID))
                            )
                        CONNECT BY NOCYCLE PRIOR IFRS_CLM_ID = RKRT_ID) WHERE LV =2) B	--계산할 계층에 맞춰 LV 변경해줘야함. 루프진행.
                WHERE A.CLO_YYMM ='201812' AND A.LAST_HIS_YN ='1' AND A.DEL_YN ='0' AND A.IFRS_CLM_ID = B.IFRS_CLM_ID   --입력해야하는 마감년월에 맞춰서 CLO_YYMM 변경해줘야함. 07.21기준
                )B 
                , (SELECT /*+FULL(A) PARALLEL(A 16) */ * FROM CF_SIMU.CI_BFRT_INF A) A
            WHERE A.IFRS_CLM_ID IN (B.RKRT_1_ID, B.RKRT_2_ID, B.RKRT_3_ID, B.RKRT_4_ID, B.RKRT_5_ID, B.RKRT_6_ID, B.RKRT_7_ID, B.RKRT_8_ID, B.RKRT_9_ID, RKRT_10_ID, RKRT_11_ID, RKRT_12_ID, RKRT_13_ID)
            GROUP BY B.IFRS_CLM_ID, B.RKRT_CALFM_RMK, A.GNDR_APPT_COD, A.AGE, A.NTRY_AGE, A.YY_LSTH_PPRD, A.CACL_TYP_COD
            
            UNION ALL
            
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
                            (SELECT * FROM CF_SIMU.IFRS_CI_BFRT_CRT_LST WHERE CLO_YYMM ='201812' AND LAST_HIS_YN ='1' AND DEL_YN ='0') A    --입력해야하는 마감년월에 맞춰서 CLO_YYMM 변경해줘야함. 07.21기준
                            UNPIVOT(RKRT_ID FOR ID_NUM IN(RKRT_1_ID,RKRT_2_ID,RKRT_3_ID,RKRT_4_ID,RKRT_5_ID,RKRT_6_ID,RKRT_7_ID,RKRT_8_ID,RKRT_9_ID,RKRT_10_ID,RKRT_11_ID,RKRT_12_ID,RKRT_13_ID))
                        )
                    CONNECT BY NOCYCLE PRIOR IFRS_CLM_ID = RKRT_ID) WHERE LV =2) B	--계층입력해야함, 현재는 2, 이것을 최대계층까지 루프시켜야함
                WHERE A.CLO_YYMM ='201812' AND A.LAST_HIS_YN ='1' AND A.DEL_YN ='0' AND A.IFRS_CLM_ID = B.IFRS_CLM_ID
                )B 
                , 
                (SELECT /*+FULL(A) PARALLEL(A 16) FULL(B) PARALLEL(B 16) SWAP_JOIN_INPUTS(B) PQ_DISTRIBUTE(B NONE BROADCAST) MERGE*/ A.RKRT_COD, A.GNDR_APPT_COD, 
                      CASE WHEN B.CACL_TYP_COD ='N' THEN 999 
                           ELSE (A.AGE - (CASE WHEN B.CACL_TYP_COD = 'Pri' THEN B.LV - 2 ELSE FLOOR((B.LV - 5)/12) END)) END AS NTRY_AGE
                      , A.AGE AS AGE
                      , CASE WHEN B.CACL_TYP_COD <> 'CF' THEN 0 ELSE MOD(B.LV -5, 12) + 1 END AS YY_LSTH_PPRD, A.RKRT
                      , B.CACL_TYP_COD 
                FROM MIG.FND_RKRT_INF A, 
                     (SELECT LEVEL AS LV, CASE WHEN LEVEL = 1 THEN 'N' WHEN LEVEL > 1 AND LEVEL < 5 THEN 'Pri' ELSE 'CF' END AS CACL_TYP_COD FROM DUAL CONNECT BY LEVEL < 41) B 
                WHERE A.MIG_CLO_YYMM ='201812' AND A.LAST_HIS_YN ='1' AND A.DEL_YN ='0' AND (A.AGE - (CASE WHEN B.CACL_TYP_COD = 'Pri' THEN B.LV - 2 ELSE FLOOR((B.LV - 5)/12) END)) > = 0  --입력해야하는 마감년월에 맞춰서 CLO_YYMM 변경해줘야함. 07.21기준
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


