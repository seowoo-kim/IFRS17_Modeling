
CSM_DP_RATE_INF

|순번|속성명|속성영문명|PK|PT|SP|데이터타입|Null여부|Default|설명|
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
|1|IFRS회계년월|IFRS_ACTS_YYMM|1|1||CHAR(6)|N||IFRS회계년월|
|2|IFRS작업구분코드|IFRS_WRK_SECD|2|||VARCHAR2(1)|N||IFRS작업구분코드|
|3|포트폴리오구분코드|PF_SECD|3|||VARCHAR2(5)|N||포트폴리오구분코드|
|4|동일그룹유형코드|SAME_GRP_TYP_COD|4|||VARCHAR2(10)|N||동일그룹유형코드|
|5|계약집합유형코드|GOC_TYP_COD|5|||VARCHAR2(10)|N||계약집합유형코드|
|6|경과년월|PROG_YYMM|6|||CHAR(6)|N||경과년월|
|7|임시고유번호|TMP_PK|7|||VARCHAR2(22)|N||임시고유번호|
|8|계약서비스차익상각율|CSM_DP_RATE||||"NUMBER(38, 19)"|Y|0|계약서비스차익상각율|

GOC_BY_CSM_GN_UNT_INF

|순번|속성명|속성영문명|PK|PT|SP|데이터타입|Null여부|Default|설명|
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
|1|IFRS회계년월|IFRS_ACTS_YYMM||1||CHAR(6)|N||IFRS회계년월|
|2|코어번호|CORENO||||VARCHAR2(10)|N||코어번호|
|3|IFRS작업구분코드|IFRS_WRK_SECD||||VARCHAR2(1)|N||IFRS작업구분코드|
|4|움직임구분코드|MVMT_SECD|||1|VARCHAR2(10)|N||움직임구분코드|
|5|포트폴리오구분코드|PF_SECD||||VARCHAR2(5)|N||포트폴리오구분코드|
|6|동일그룹유형코드|SAME_GRP_TYP_COD||||VARCHAR2(10)|N||동일그룹유형코드|
|7|계약집합유형코드|GOC_TYP_COD||||VARCHAR2(10)|N||계약집합유형코드|
|8|경과년월|PROG_YYMM||||CHAR(6)|N||경과년월|
|9|임시고유번호|TMP_PK||||VARCHAR2(22)|N||임시고유번호|
|10|상품코드|PRDCD||||VARCHAR2(10)|N||상품코드|
|11|보장단위값|GN_UNT_VL||||"NUMBER(38, 19)"|Y||보장단위값|
|12|보장단위현가|GN_UNT_CVAL||||"NUMBER(38, 19)"|Y||보장단위현가|
|13|최초인식할인율|INIT_RCGNT_DCRT||||"NUMBER(38, 19)"|Y||최초인식할인율|


```sql

SET TIMING ON;

--###데이터 확인

--INPUT
SELECT * FROM CF_SIMU.GOC_BY_CSM_GN_UNT_INF WHERE IFRS_ACTS_YYMM = '201904' AND IFRS_WRK_SECD ='E' AND ROWNUM < 100;   
--상품별계약서비스차익보장단위정보, 소스

--OUTPUT
SELECT * FROM CF_SIMU.CSM_DP_RATE_INF WHERE IFRS_ACTS_YYMM = '201904' AND IFRS_WRK_SECD ='E' AND ROWNUM < 100;         
--계약서비스차익상각율정보, 타겟 테이블


--###업무요건

--IFRS17은 분기내 누적결산이 기본이며, 따라서 계약집단을 인식하기 시작한 첫 마감년월분기를 cohort단위로 구분하여 관리함. 
--분기 누적이라 함은 한 분기 내에서 현재 경과한 마감년월의 실현된 가정과 통계를 기준으로, 직전분기 말부터 다시 예측분을 재평가하는 것을 의미함.
--ex ) 2018_4Q 2018년 11월 말 결산시, 2018년 4분기 내 이전 2018 10월 말 결산했던 부분을 realese하여 없던 일로하면서 11월 말 기준으로 재결산하고, 여기에 11월 말 분을 추가함.


--IFRS17에서 보험업은 당기의 보험료나 투자수입을 수익으로 인식하지 못하며, 각 경과시점별로 유입될 것이라고 예측되는 현금흐름의 현재가치의 '실현분'을 수익으로 계산해야함.
--따라서 WHERE clause에 분기 누적결산으로 과거 결산분을 읽기 위한 (A.IFRS_ACTS_YYMM, A.MVMT_SECD)의 multi-in 조건과,
--과거시점에서 예측했던 현재의 마감년월까지의 실현된 경과년월 PROG_YYMM <= IFRS_ACTS_YYMM 분을 인지하도록 모델링을 구성함.


--결산단위가 분기이므로 최대 3개월치의 값을 인지할 수 있으며, 쿼리 내 "PROG_IDX" 를 flag로 하여 각각의 마감년월에 사용해야할 평가시점의 경과년월 이외의 값들을 Null로 만들어서 처리함.
--결산단계(MVMT_SECD)는 직전분기말, 분기내 첫달, 둘째달, 마지막달까지 총 4가지에 대해서 요건정의되는 대로 어플리케이션에서 입력받아 사용하도록 구성 함. 


--쿼리의 목표는 CSM상각률(CSM_DP_RATE)을 구하는데에 있으며, 이 계산식은 1 - 분자/분모로 다음과 같다.
--분자 : 평가시점의잔여장래현금흐름현가 
--분모 : (((분기내첫달실현분 * (1+부리이율) + 분기내두번째달실현분) * (1+부리이율) + 분기내마지막달실현분) * (1+부리이율)) + 평가시점의잔여장래현금흐름현가
--"분자/분모" 식을 해석해본다면 평가시점부터 앞으로 보험서비스를 수행하면서 유입될 현금흐름의 현재가치의 잔여비율로, 이를 1에서 빼면서 실현비율로 바꿔서 상각률을 구하는 것이다.


--쿼리 수행 전 실행계획을 확인하기 위한 실행계획 생성과, plan table SELECT
--SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', NULL, 'OUTLINE'));
--EXPLAIN PLAN FOR



INSERT /*+ ENABLE_PARALLEL_DML APPEND PARALLEL(Z 10) PQ_DISTRIBUTE(Z NONE) NO_GATHER_OPTIMIZER_STATISTICS */ 
INTO CF_SIMU.CSM_DP_RATE_INF Z
SELECT /*+FULL(A) PARALLEL(A 10) */
        A.MAX_PROG_YYMM             AS IFRS_ACTS_YYMM
      , A.IFRS_WRK_SECD             AS IFRS_WRK_SECD
      , A.PF_SECD                   AS PF_SECD
      , A.SAME_GRP_TYP_COD          AS SAME_GRP_TYP_COD
      , A.GOC_TYP_COD               AS GOC_TYP_COD
      , A.MAX_PROG_YYMM             AS PROG_YYMM
      , '0'                         AS TMP_PK
      , 1 - NVL(DECODE(A.UNT_CVAL / DECODE((((A.UNT_VL_3) * (1 + A.RATE_3) + A.UNT_VL_2) * (1+ A.RATE_2) + A.UNT_VL_1) * (1 + A.RATE_1) + A.UNT_CVAL
                                          , 0, NULL
                                          , (((A.UNT_VL_3) * (1 + A.RATE_3) + A.UNT_VL_2) * (1+ A.RATE_2) + A.UNT_VL_1) * (1 + A.RATE_1) + A.UNT_CVAL)
                       , 0, 1
                       , A.UNT_CVAL / DECODE((((A.UNT_VL_3) * (1 + A.RATE_3) + A.UNT_VL_2) * (1+ A.RATE_2) + A.UNT_VL_1) * (1 + A.RATE_1) + A.UNT_CVAL
                                            , 0, NULL, 
                                            (((A.UNT_VL_3) * (1 + A.RATE_3) + A.UNT_VL_2) * (1+ A.RATE_2) + A.UNT_VL_1) * (1 + A.RATE_1) + A.UNT_CVAL)
                       )
               , 0)                 AS CSM_DP_RATE        --앞선 주석의 CSM 상각률 산출 식 해석 참고                          
  FROM
      (SELECT /*+FULL(A) PARALLEL(A 10) */
              A.IFRS_WRK_SECD
            , A.PF_SECD
            , A.SAME_GRP_TYP_COD
            , A.GOC_TYP_COD
            , MAX(A.PROG_YYMM)                                                      AS MAX_PROG_YYMM
            , NVL(SUM(A.GN_UNT_CVAL), 0)                                            AS UNT_CVAL
            , NVL(SUM(A.UNT_VL_1), 0)                                               AS UNT_VL_1
            , NVL(SUM(A.UNT_VL_2), 0)                                               AS UNT_VL_2
            , NVL(SUM(A.UNT_VL_3), 0)                                               AS UNT_VL_3
            , CASE WHEN MAX(A.PROG_IDX) >= 3 THEN NVL(MAX(A.RATE_1), 0) ELSE 0 END  AS RATE_1
            , CASE WHEN MAX(A.PROG_IDX) >= 2 THEN NVL(MAX(A.RATE_2), 0) ELSE 0 END  AS RATE_2
            , CASE WHEN MAX(A.PROG_IDX) >= 1 THEN NVL(MAX(A.RATE_3), 0) ELSE 0 END  AS RATE_3
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
                    A.IFRS_WRK_SECD
                  , A.PROG_YYMM
                  , A.PF_SECD
                  , A.SAME_GRP_TYP_COD
                  , A.GOC_TYP_COD
                  , MONTHS_BETWEEN(TO_DATE(A.PROG_YYMM||'01')
                                  , TO_DATE('201903'||'01'))  AS PROG_IDX     --'201903' 자리에 전분기말 입력 필요함. 전분기말로부터 얼마나 경과했는지 PROG_IDX로 판별하도록 만듬.
                  , SUM(CASE WHEN (A.MVMT_SECD = '1000' AND A.PROG_YYMM = A.IFRS_ACTS_YYMM) 
                                    OR (A.MVMT_SECD <> '1000' AND ADD_MONTHS(TO_DATE(A.IFRS_ACTS_YYMM||'01'), 1) = TO_DATE(A.PROG_YYMM||'01')) 
                             THEN A.GN_UNT_VL 
                             END)                             AS UNT_VL
                  , SUM(CASE WHEN A.MVMT_SECD = '1090' AND A.IFRS_ACTS_YYMM ='201904' AND A.IFRS_ACTS_YYMM = A.PROG_YYMM 
                             THEN A.GN_UNT_CVAL 
                             END)                             AS GN_UNT_CVAL      --미래현가 사용할 회계년월과 무브먼트 입력
                  , MAX(CASE WHEN A.MVMT_SECD = '1090' AND A.IFRS_ACTS_YYMM ='201904' 
                             THEN A.INIT_RCGNT_DCRT 
                             END)                             AS INIT_RCGNT_DCRT  --미래현가 사용할 회계년월과 무브먼트 입력
              FROM CF_SIMU.GOC_BY_CSM_GN_UNT_INF A 
              WHERE (A.IFRS_ACTS_YYMM, A.MVMT_SECD) IN (('201904', '1000'), ('201904','1090'), ('201903','9999')) --테스트의 마감년월을 2019년 04월로 직전분기말 201903부터 값을 찾음.
                  AND A.IFRS_WRK_SECD ='E' AND A.PROG_YYMM <= '201904'   --여기서 미래보장단위현가 및 이율이용, 당회계년월 최초인식 그리고 경과년월별 CSM상각대상 보장단위 MVMT 특정필요
              GROUP BY A.IFRS_WRK_SECD, A.PROG_YYMM, A.PF_SECD, A.SAME_GRP_TYP_COD, A.GOC_TYP_COD 
              ) A 
          ) A
      GROUP BY A.IFRS_WRK_SECD, A.PF_SECD, A.SAME_GRP_TYP_COD, A.GOC_TYP_COD 
      ) A
;

COMMIT;

```
