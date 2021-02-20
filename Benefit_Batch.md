
### IFRS_BFRT_CRT_LST

|순번|속성명|속성영문명|PK|PT|SP|데이터타입|Null여부|Default|설명|
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
|1|마감년월|CLO_YYMM|1|1||CHAR(6)|N||마감년월|
|2|기준IFRS청구ID|STD_IFRS_CLM_ID|4|||VARCHAR2(500)|N||기준IFRS청구ID|
|3|기준사고급부코드|STD_ACCT_PYMT_COD||||VARCHAR2(10)|Y||기준사고급부코드|
|4|기준위험율산출식비고|STD_RKRT_CALFM_RMK||||VARCHAR2(100)|Y||기준위험율산출식비고|
|5|기준위험율1ID|STD_RKRT_1_ID||||VARCHAR2(100)|Y||기준위험율1ID|
|6|기준위험율2ID|STD_RKRT_2_ID||||VARCHAR2(100)|Y||기준위험율2ID|
|7|기준위험율3ID|STD_RKRT_3_ID||||VARCHAR2(100)|Y||기준위험율3ID|
|8|기준위험율4ID|STD_RKRT_4_ID||||VARCHAR2(100)|Y||기준위험율4ID|
|9|기준위험율5ID|STD_RKRT_5_ID||||VARCHAR2(100)|Y||기준위험율5ID|
|10|기준위험율6ID|STD_RKRT_6_ID||||VARCHAR2(100)|Y||기준위험율6ID|
|11|기준위험율7ID|STD_RKRT_7_ID||||VARCHAR2(100)|Y||기준위험율7ID|
|12|기준위험율8ID|STD_RKRT_8_ID||||VARCHAR2(100)|Y||기준위험율8ID|
|13|기준위험율9ID|STD_RKRT_9_ID||||VARCHAR2(100)|Y||기준위험율9ID|
|14|온레벨IFRS청구ID|ONLVL_IFRS_CLM_ID||||VARCHAR2(500)|Y||온레벨IFRS청구ID|
|15|온레벨사고급부코드|ONLVL_ACCT_PYMT_COD||||VARCHAR2(10)|Y||온레벨사고급부코드|
|16|온레벨위험율산출식비고|ONLVL_RKRT_CALFM_RMK||||VARCHAR2(100)|Y||온레벨위험율산출식비고|
|17|온레벨위험율1ID|ONLVL_RKRT_1_ID||||VARCHAR2(100)|Y||온레벨위험율1ID|
|18|온레벨위험율2ID|ONLVL_RKRT_2_ID||||VARCHAR2(100)|Y||온레벨위험율2ID|
|19|온레벨위험율3ID|ONLVL_RKRT_3_ID||||VARCHAR2(100)|Y||온레벨위험율3ID|
|20|온레벨위험율4ID|ONLVL_RKRT_4_ID||||VARCHAR2(100)|Y||온레벨위험율4ID|
|21|온레벨위험율5ID|ONLVL_RKRT_5_ID||||VARCHAR2(100)|Y||온레벨위험율5ID|
|22|온레벨위험율6ID|ONLVL_RKRT_6_ID||||VARCHAR2(100)|Y||온레벨위험율6ID|
|23|온레벨위험율7ID|ONLVL_RKRT_7_ID||||VARCHAR2(100)|Y||온레벨위험율7ID|
|24|온레벨위험율8ID|ONLVL_RKRT_8_ID||||VARCHAR2(100)|Y||온레벨위험율8ID|
|25|온레벨위험율9ID|ONLVL_RKRT_9_ID||||VARCHAR2(100)|Y||온레벨위험율9ID|
|26|최종이력여부|LAST_HIS_YN|2|||CHAR(1)|N||최종이력여부|
|27|삭제여부|DEL_YN|3|||CHAR(1)|N||삭제여부|

### FND_RKRT_INF

|순번|속성명|속성영문명|PK|PT|SP|데이터타입|Null여부|Default|설명|
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
|1|MIG마감연월|MIG_CLO_YYMM|1|1||CHAR(6)|N||MIG마감연월|
|2|위험율코드|RKRT_COD|4|||VARCHAR2(20)|N||위험율코드|
|3|성별적용코드|GNDR_APPT_COD|5|||VARCHAR2(10)|N||성별적용코드|
|4|나이|AGE|6|||"NUMBER(3, 0)"|N||나이|
|5|위험율|RKRT||||"NUMBER(18, 9)"|N||위험율|
|6|최종이력여부|LAST_HIS_YN|2|||CHAR(1)|N||최종이력여부|
|7|삭제여부|DEL_YN|3|||CHAR(1)|N||삭제여부|

### BFRT_INF

|순번|속성명|속성영문명|PK|PT|SP|데이터타입|Null여부|Default|설명|
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
|1|마감연월|CLO_YYMM|1|1||CHAR(6)|N||마감연월|
|2|IFRS청구ID|IFRS_CLM_ID|2|||VARCHAR2(500)|N||IFRS청구ID|
|3|성별적용코드|GNDR_APPT_COD|3|||VARCHAR2(10)|N||성별적용코드|
|4|나이|AGE|4|||"NUMBER(3, 0)"|N||나이|
|5|위험율값|RKRT_VL||||"NUMBER(38, 19)"|Y||위험율값|

```sql

SET TIMING ON;

--###데이터 확인

--INPUT
SELECT * FROM CF_SIMU.IFRS_BFRT_CRT_LST WHERE CLO_YYMM ='201812' AND LAST_HIS_YN ='1' AND DEL_YN ='0' AND ROWNUM < 100;
--IFRS급부율생성내역, 소스 1
SELECT * FROM MIG.FND_RKRT_INF WHERE LAST_HIS_YN ='1' AND DEL_YN ='0' AND ROWNUM < 100;
--기초위험율정보, 소스 2

--OUTPUT
SELECT * FROM CF_SIMU.BFRT_INF WHERE ROWNUM < 100;
--급부율정보, 타겟

--###참고사항
--비계층형 정보인것만 감안하면 CI담보 Batch 작업쿼리와 사용하는 스키마나 조인과정이 유사함. 
--unpivot부분, xml query부분은 CI_Batch_README.md나 notion link 확인바람.


--###업무요건

--한 담보코드의 재료는 일반기초통계(기초통계량 STD1~9)와 온레벨기초통계(가정으로 조정한 통계량 ONLVL1~9) 모두 이용해 계산하여, 각각 기본담보코드 온레벨담보코드 두개의 키로 생성된다.
--이는 담보코드가 처음 생성될때의 가정과 논리로 묶은 기초통계로 구성되고, 이후 경과실적을 보면서 온레벨하여 새로운 계산식과 재료로 변경하여 새로운 코드로도 구성되는 업무프로세스 때문이다.
--즉 하나의 (STD_IFRS_CLM_ID키를 기준으로)인스턴스로부터 두개의 담보코드(STD_IFRS_CLM_ID, ONLVL_IFRS_CLM_ID)가 생성 되며, 예정과 실제의반영분 비교를 위해 두 ID 모두 필요하다.

--주의해야할 점 
--1. 온레벨한 담보코드와 기본담보코드가 동일한 경우가 있다. 아직 온레벨할 정도로 경과가 되지않거나 필요성이 없는 경우에 해당함.
--2. 다른 인스턴스의 온레벨 담보코드가 또 다른 기본담보코드와 일치하는 경우가 있다. 처음엔 다른 담보로 분류하였지만, 경험치에 따라 다른 유사담보와 통합 관리하게 되는 경우이다.
--따라서 중복없이 유일하게 계산해야 데이터 정합성을 유지할 수 있으며, 사용자 오류나 기간계정보오류로 틀린 경우를 찾아내기 위한 검증case를 마련하게 되었다.


--쿼리 수행 전 실행계획을 확인하기 위한 실행계획 생성과, plan table SELECT
--SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
--EXPLAIN PLAN FOR



INSERT /*+ENABLE_PARALLEL_DML PARALLEL(Z 16) OPT_PARAM('_OPTIMIZER_GATHER_STATS_ON_LOAD' 'FALSE') PQ_DISTRIBUTE(Z NONE)*/ 
INTO CF_SIMU.BFRT_INF Z         --아래 CLO_YYMM을 어플리케이션에서 입력받아 CLO_YYMM 변경해줘야함.
SELECT /*+PARALLEL(A 16)*/ 
      '201812' AS CLO_YYMM
    , A.IFRS_CLM_ID
    , A.GNDR_APPT_COD
    , A.AGE
    , CASE WHEN ROUND_OPT = '1'     --라운딩 룰 옵션
           THEN ROUND(XMLQUERY(STD_RKRT_CALFM_RMK RETURNING CONTENT).GETNUMBERVAL(), 6) --XMLQUERY() 는 string을 해석하는 부분.
           ELSE XMLQUERY(STD_RKRT_CALFM_RMK RETURNING CONTENT).GETNUMBERVAL() 
           END AS RKRT_VL 
FROM 
    (SELECT /*+PARALLEL(A 16)*/
          A.IFRS_CLM_ID
        , REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(STD_RKRT_CALFM_RMK
            , 'q1', Q1), 'q2', Q2), 'q3', Q3), 'q4', Q4), 'q5', Q5), 'q6', Q6), 'q7', Q7), 'q8', Q8), 'q9', Q9), '/', ' div ')
            , 'Round', 'fn:round-half-to-even'), 'x', '*'), 'q', 1) AS STD_RKRT_CALFM_RMK
        , A.GNDR_APPT_COD
        , A.AGE
        , A.ROUND_OPT
    FROM 
        (SELECT /*+PARALLEL(A 16) PARALLEL(B 16) USE_HASH(A B) USE_HASH(B A) 
            SWAP_JOIN_INPUTS(B) PQ_DISTRIBUTE(A HASH HASH) NO_PX_JOIN_FILTER(A) USE_CONCAT*/
              B.STD_IFRS_CLM_ID AS IFRS_CLM_ID
            , B.STD_RKRT_CALFM_RMK
            , A.GNDR_APPT_COD
            , A.AGE
            , NVL(MAX(CASE WHEN A.RKRT_COD = B.STD_RKRT_1_ID THEN RKRT END), 0) AS Q1
            , NVL(MAX(CASE WHEN A.RKRT_COD = B.STD_RKRT_2_ID THEN RKRT END), 0) AS Q2
            , NVL(MAX(CASE WHEN A.RKRT_COD = B.STD_RKRT_3_ID THEN RKRT END), 0) AS Q3
            , NVL(MAX(CASE WHEN A.RKRT_COD = B.STD_RKRT_4_ID THEN RKRT END), 0) AS Q4
            , NVL(MAX(CASE WHEN A.RKRT_COD = B.STD_RKRT_5_ID THEN RKRT END), 0) AS Q5
            , NVL(MAX(CASE WHEN A.RKRT_COD = B.STD_RKRT_6_ID THEN RKRT END), 0) AS Q6
            , NVL(MAX(CASE WHEN A.RKRT_COD = B.STD_RKRT_7_ID THEN RKRT END), 0) AS Q7
            , NVL(MAX(CASE WHEN A.RKRT_COD = B.STD_RKRT_8_ID THEN RKRT END), 0) AS Q8
            , NVL(MAX(CASE WHEN A.RKRT_COD = B.STD_RKRT_9_ID THEN RKRT END), 0) AS Q9
            , MAX(CASE WHEN A.RKRT_COD IN ('28Z167B2220', '28Z167B2221', '28Z167B2222') THEN '1' ELSE '0' END) AS ROUND_OPT --특수케이스 하드코딩으로 임시처리해봄.
        FROM 
            (SELECT /*+PARALLEL(B 16) NO_MERGE*/ 
                  STD_IFRS_CLM_ID
                , STD_RKRT_CALFM_RMK    --계산식이 담기는 컬럼. ex q1 - q2 /2 + q3 * q4
                , STD_RKRT_1_ID
                , STD_RKRT_2_ID
                , STD_RKRT_3_ID
                , STD_RKRT_4_ID
                , STD_RKRT_5_ID
                , STD_RKRT_6_ID
                , STD_RKRT_7_ID
                , STD_RKRT_8_ID
                , STD_RKRT_9_ID
            FROM 
                (SELECT /*+FULL(A) PARALLEL(A 16) */ 
                      STD_IFRS_CLM_ID
                    , STD_ACCT_PYMT_COD
                    , STD_RKRT_CALFM_RMK
                    , STD_RKRT_1_ID
                    , STD_RKRT_2_ID
                    , STD_RKRT_3_ID
                    , STD_RKRT_4_ID
                    , STD_RKRT_5_ID
                    , STD_RKRT_6_ID
                    , STD_RKRT_7_ID
                    , STD_RKRT_8_ID
                    , STD_RKRT_9_ID 
                FROM CF_SIMU.IFRS_BFRT_CRT_LST A 
                WHERE CLO_YYMM ='201812' AND LAST_HIS_YN ='1' AND DEL_YN ='0'

                UNION
--UNION을 사용함에도 동일키에 대한 중복건(예를 들어 동일담보코드에 계산법이 여러개라던가, 혹은 위험률코드가 다르다던가)이 있다면, 결과테이블의 PK중복에러가 나면서 데이터 INSERT 자체가 불가능함.
--만약 에러가 난다면 아래의 검증case 1~3을 참고하여 계산법 중복확인, 위험률코드 중복확인 쿼리수행해서 확인할것. 
--실제 어플리케이션단에서는 검증case 1,2를 먼저수행하고 현 sql 수행하여 insert후 마지막으로 검증case 3의 insert를 하여 모델런을 위한 준비를 마치도록 구상함.

                SELECT /*+FULL(A) PARALLEL(A 16) */ 
                      ONLVL_IFRS_CLM_ID AS STD_IFRS_CLM_ID
                    , ONLVL_ACCT_PYMT_COD AS STD_ACCT_PYMT_COD
                    , ONLVL_RKRT_CALFM_RMK AS STD_RKRT_CALFM_RMK
                    , ONLVL_RKRT_1_ID AS STD_RKRT_1_ID
                    , ONLVL_RKRT_2_ID AS STD_RKRT_2_ID
                    , ONLVL_RKRT_3_ID AS STD_RKRT_3_ID
                    , ONLVL_RKRT_4_ID AS STD_RKRT_4_ID
                    , ONLVL_RKRT_5_ID AS STD_RKRT_5_ID
                    , ONLVL_RKRT_6_ID AS STD_RKRT_6_ID
                    , ONLVL_RKRT_7_ID AS STD_RKRT_7_ID
                    , ONLVL_RKRT_8_ID AS STD_RKRT_8_ID
                    , ONLVL_RKRT_9_ID AS STD_RKRT_9_ID 
                FROM CF_SIMU.IFRS_BFRT_CRT_LST A 
                WHERE CLO_YYMM ='201812' AND LAST_HIS_YN ='1' AND DEL_YN ='0'
                )B 
            )B
            , MIG.FND_RKRT_INF A
        WHERE A.MIG_CLO_YYMM ='201812' AND A.LAST_HIS_YN ='1' AND A.DEL_YN ='0' 
            AND A.RKRT_COD IN (B.STD_RKRT_1_ID, B.STD_RKRT_2_ID, B.STD_RKRT_3_ID, B.STD_RKRT_4_ID, B.STD_RKRT_5_ID
                                , B.STD_RKRT_6_ID, B.STD_RKRT_7_ID, B.STD_RKRT_8_ID, B.STD_RKRT_9_ID) 
        GROUP BY B.STD_IFRS_CLM_ID, B.STD_RKRT_CALFM_RMK, A.GNDR_APPT_COD, A.AGE
        ) A 
    ) A
;

COMMIT;



--##DEBUG, 데이터정합성 확인과정

--###검증CASE 1
--동일한 담보(CLM_ID)이지만 계산법(CALFM_RMK)이 상이하게 입력된 경우가 있는지 확인함.
SELECT /*+PARALLEL(A 16) */ 
    CLM_ID
FROM 
    (SELECT /*+PARALLEL(A 16) */ 
          CLM_ID
        , CALFM_RMK 
    FROM 
        (SELECT /*+PARALLEL(A 16) */ 
              CLM_NUM
            , CLM_ID
            , CASE WHEN CLM_NUM ='STD_IFRS_CLM_ID' 
                   THEN STD_RKRT_CALFM_RMK 
                   WHEN CLM_NUM ='ONLVL_IFRS_CLM_ID' 
                   THEN ONLVL_RKRT_CALFM_RMK 
                   END AS CALFM_RMK  
        FROM 
            (SELECT /*+FULL(A) PARALLEL(A 16) */ 
                  CLM_NUM
                , CLM_ID
                , STD_RKRT_CALFM_RMK
                , ONLVL_RKRT_CALFM_RMK
            FROM 
                (SELECT * 
                FROM CF_SIMU.IFRS_BFRT_CRT_LST 
                WHERE CLO_YYMM ='201812' AND LAST_HIS_YN ='1' AND DEL_YN ='0'
                ) A
            UNPIVOT(CLM_ID FOR CLM_NUM IN (STD_IFRS_CLM_ID, ONLVL_IFRS_CLM_ID)) 
            ) A 
        ) A 
    GROUP BY CLM_ID, CALFM_RMK
    ) A 
GROUP BY CLM_ID HAVING COUNT (*) > 1 
; 


--###검증CASE 2
--동일한 담보(CLM_ID)이지만 위험률코드(STD_IFRS_CLM_ID)가 상이하게 입력된 경우가 있는지 확인함.
SELECT /*+PARALLEL(A 16)*/ STD_IFRS_CLM_ID 
FROM
    (SELECT /*+FULL(A) PARALLEL(A 16) */ 
          STD_IFRS_CLM_ID
        , (STD_RKRT_1_ID||STD_RKRT_2_ID||STD_RKRT_3_ID||STD_RKRT_4_ID||STD_RKRT_5_ID||STD_RKRT_6_ID||STD_RKRT_7_ID||STD_RKRT_8_ID||STD_RKRT_9_ID) AS CHK
    FROM CF_SIMU.IFRS_BFRT_CRT_LST A 
    WHERE CLO_YYMM ='201812' AND LAST_HIS_YN ='1' AND DEL_YN ='0'

    UNION

    SELECT /*+FULL(A) PARALLEL(A 16) */ 
          ONLVL_IFRS_CLM_ID AS STD_IFRS_CLM_ID
        , (ONLVL_RKRT_1_ID||ONLVL_RKRT_2_ID||ONLVL_RKRT_3_ID||ONLVL_RKRT_4_ID||ONLVL_RKRT_5_ID||ONLVL_RKRT_6_ID||ONLVL_RKRT_7_ID||ONLVL_RKRT_8_ID||ONLVL_RKRT_9_ID) AS CHK
    FROM CF_SIMU.IFRS_BFRT_CRT_LST A 
    WHERE CLO_YYMM ='201812' AND LAST_HIS_YN ='1' AND DEL_YN ='0'
    )
GROUP BY STD_IFRS_CLM_ID HAVING COUNT(*) > 1;


--###검증CASE 3- 1
--담보(CLM_ID)의 재료 위험률코드(STD_IFRS_CLM_ID)로 입력되어 있지만, 기초통계 테이블에는 소스가 존재하지 않는 경우를 확인함.
SELECT RKRT_COD 
FROM 
    (SELECT /*+PARALLEL(B 16) PARALLEL(A 16) */ 
          A.RKRT_COD
        , B.RKRT_COD AS NULL_CHK 
    FROM
        (SELECT DISTINCT 
            RKRT_ID AS RKRT_COD
        FROM
            (SELECT /*+FULL(A) PARALLEL(A 16) */ 
                  RKRT_ID
                , ID_NUM
            FROM 
                (SELECT * 
                FROM CF_SIMU.IFRS_BFRT_CRT_LST 
                WHERE CLO_YYMM ='201812' AND LAST_HIS_YN ='1' AND DEL_YN ='0'
                ) A
            UNPIVOT(RKRT_ID FOR ID_NUM IN(STD_RKRT_1_ID, STD_RKRT_2_ID, STD_RKRT_3_ID, STD_RKRT_4_ID, STD_RKRT_5_ID, STD_RKRT_6_ID, STD_RKRT_7_ID, STD_RKRT_8_ID
                                        , STD_RKRT_9_ID, ONLVL_RKRT_1_ID, ONLVL_RKRT_2_ID, ONLVL_RKRT_3_ID, ONLVL_RKRT_4_ID, ONLVL_RKRT_5_ID
                                        , ONLVL_RKRT_6_ID, ONLVL_RKRT_7_ID, ONLVL_RKRT_8_ID, ONLVL_RKRT_9_ID))
            )
        ) A, 
        (SELECT /*+FULL(A) PARALLEL(A 16)*/ DISTINCT 
            RKRT_COD AS RKRT_COD 
        FROM MIG.FND_RKRT_INF A 
        WHERE LAST_HIS_YN ='1' AND DEL_YN ='0'
        ) B
    WHERE A.RKRT_COD = B.RKRT_COD (+)
    ) 
WHERE NULL_CHK IS NULL;


--###검증CASE 3- 2
--3-1의 누락위험률 사용하는 담보코드 내 위험률코드가 전부 누락된 것이 아니라 일부만 누락된 경우라면, 누락 위험률은 0으로 넣고 다른 위험률들과 계산해서 넣음.
--모든 정보가 마련되지 않아 왜곡된 정보이긴 하나, 의도적으로 누락된 경우나 왜곡되어도 모델에서 색적시 탐색은 되어야 에러가 나지 않고 돌 수 있음.
--의도치 않았지만 모델 결산 런목적만을 위한 경우에는 차후 예정실제 차이에 반영하면서 차액 잡아서 조정함.
SELECT DISTINCT STD_IFRS_CLM_ID 
FROM 
    (SELECT /*+PARALLEL(B 16) PARALLEL(A 16) */ 
          A.STD_IFRS_CLM_ID
        , B.RKRT_COD AS NULL_CHK 
    FROM
        (SELECT /*+PARALLEL(A 16) */  DISTINCT 
              A.CLM_ID AS STD_IFRS_CLM_ID
            , A.RKRT_ID AS RKRT_COD
        FROM
            (SELECT /*+FULL(A) PARALLEL(A 16) */ 
                  CLM_ID
                , CLM_NUM
                , RKRT_ID
                , ID_NUM
            FROM
                (SELECT /*+FULL(A) PARALLEL(A 16) */ 
                      STD_IFRS_CLM_ID
                    , ONLVL_IFRS_CLM_ID
                    , RKRT_ID, ID_NUM
                FROM 
                    (SELECT * 
                    FROM CF_SIMU.IFRS_BFRT_CRT_LST 
                    WHERE CLO_YYMM ='201812' AND LAST_HIS_YN ='1' AND DEL_YN ='0'
                    ) A
                UNPIVOT(RKRT_ID FOR ID_NUM IN(STD_RKRT_1_ID, STD_RKRT_2_ID, STD_RKRT_3_ID, STD_RKRT_4_ID, STD_RKRT_5_ID, STD_RKRT_6_ID, STD_RKRT_7_ID, STD_RKRT_8_ID
                                            , STD_RKRT_9_ID, ONLVL_RKRT_1_ID, ONLVL_RKRT_2_ID, ONLVL_RKRT_3_ID, ONLVL_RKRT_4_ID, ONLVL_RKRT_5_ID, ONLVL_RKRT_6_ID
                                            , ONLVL_RKRT_7_ID, ONLVL_RKRT_8_ID, ONLVL_RKRT_9_ID)) A
                ) A
            UNPIVOT(CLM_ID FOR CLM_NUM IN (STD_IFRS_CLM_ID, ONLVL_IFRS_CLM_ID))
            ) A
        ) A, 
        (SELECT /*+FULL(A) PARALLEL(A 16)*/ DISTINCT 
            RKRT_COD AS RKRT_COD 
        FROM MIG.FND_RKRT_INF A 
        WHERE LAST_HIS_YN ='1' AND DEL_YN ='0'
        ) B
    WHERE A.RKRT_COD = B.RKRT_COD (+)
    )
WHERE NULL_CHK IS NULL;


--###검증CASE 3- 3
--3-2의 누락위험률을 사용한 담보코드를 모두 넣으면 중복문제가 생김. 모든 기초정보가 없어 모든조인이 실패한 담보코드만 넣어야하기에, TARGET TABLE과 조인후 NULL CHK를 진행함.
--넣는 위험률은 projection은 하지 않지만(계약유지 조건을 충족시키지못함, 보험담보지급사유가 없음 = 발생률 0), 예측모델 런때 데이터 유무에는 걸리지 않도록 0으로 고정함.
SELECT * FROM BFRT_INF WHERE ROWNUM < 100;


--쿼리 수행 전 실행계획을 확인하기 위한 실행계획 생성과, plan table SELECT
--SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', NULL, 'OUTLINE'));
--EXPLAIN PLAN FOR


INSERT /*+ENABLE_PARALLEL_DML APPEND PARALLEL(Z 16) PQ_DISTRIBUTE(Z NONE)*/
INTO CF_SIMU.BFRT_INF Z
SELECT 
      '201812' AS CLO_YYMM  --아래 CLO_YYMM을 어플리케이션에서 입력받아 CLO_YYMM 변경해줘야함.
    , A.STD_IFRS_CLM_ID
    , B.GNDR_APPT_COD
    , B.AGE
    , 0 AS RKRT_VL          --발생률 0 으로 고정하는 부분. 다만 필요한 키를 기준으로 인스턴스는 생성되어야 함.               
FROM
    (SELECT /*+PARALLEL(A 16) */ 
        STD_IFRS_CLM_ID
    FROM
        (SELECT /*+PARALLEL(A 16) PARALLEL(B 16) ORDERED USE_HASH(A B)*/ 
              A.STD_IFRS_CLM_ID
            , B.IFRS_CLM_ID
        FROM
            (SELECT DISTINCT 
                STD_IFRS_CLM_ID 
            FROM 
                (SELECT /*+PARALLEL(B 16) PARALLEL(A 16) */ 
                      A.STD_IFRS_CLM_ID
                    , B.RKRT_COD AS NULL_CHK 
                FROM
                    (SELECT /*+PARALLEL(A 16) */  DISTINCT 
                          A.CLM_ID AS STD_IFRS_CLM_ID
                        , A.RKRT_ID AS RKRT_COD
                    FROM
                        (SELECT /*+PARALLEL(A 16) */ 
                            CLM_ID
                            , CLM_NUM
                            , RKRT_ID
                            , ID_NUM
                        FROM
                            (SELECT /*+FULL(A) PARALLEL(A 16) */ 
                                  STD_IFRS_CLM_ID
                                , ONLVL_IFRS_CLM_ID
                                , RKRT_ID, ID_NUM
                            FROM 
                                (SELECT * 
                                FROM CF_SIMU.IFRS_BFRT_CRT_LST 
                                WHERE CLO_YYMM ='201812' AND LAST_HIS_YN ='1' AND DEL_YN ='0'
                                ) A
                            UNPIVOT(RKRT_ID FOR ID_NUM IN(STD_RKRT_1_ID, STD_RKRT_2_ID, STD_RKRT_3_ID, STD_RKRT_4_ID, STD_RKRT_5_ID, STD_RKRT_6_ID, STD_RKRT_7_ID, STD_RKRT_8_ID
                                                        , STD_RKRT_9_ID, ONLVL_RKRT_1_ID, ONLVL_RKRT_2_ID, ONLVL_RKRT_3_ID, ONLVL_RKRT_4_ID, ONLVL_RKRT_5_ID, ONLVL_RKRT_6_ID
                                                        , ONLVL_RKRT_7_ID, ONLVL_RKRT_8_ID, ONLVL_RKRT_9_ID))
                            ) A
                        UNPIVOT(CLM_ID FOR CLM_NUM IN (STD_IFRS_CLM_ID, ONLVL_IFRS_CLM_ID))
                        ) A
                    ) A, 
                    (SELECT /*+FULL(A) PARALLEL(A 16)*/ DISTINCT 
                        RKRT_COD AS RKRT_COD 
                    FROM MIG.FND_RKRT_INF A 
                    WHERE LAST_HIS_YN ='1' AND DEL_YN ='0'
                    ) B
                WHERE A.RKRT_COD = B.RKRT_COD (+)
                )
            WHERE NULL_CHK IS NULL
            ) A, 
            (SELECT /*+FULL(A) PARALLEL(A 16) */ DISTINCT 
                IFRS_CLM_ID 
            FROM CF_SIMU.BFRT_INF A
            ) B
        WHERE A.STD_IFRS_CLM_ID = B.IFRS_CLM_ID (+)
        ) A
    WHERE IFRS_CLM_ID IS NULL
    ) A, 
    (SELECT 
          FLOOR((LEVEL - 1 ) / 120) + 1 AS GNDR_APPT_COD
        , MOD((LEVEL - 1 ), 120) + 1 AS AGE 
    FROM DUAL 
    CONNECT BY LEVEL < 241
    ) B
;
COMMIT;



```
