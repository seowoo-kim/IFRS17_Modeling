보험계리현업팀에서 동일한 테이블 회계결산기준별로 파티셔닝됨 에대한 분석이나 데이터 검증용 쿼리의     (   )          
수행시간이 천차만별로 차이남     .
유의미한 차이가 있는 쿼리들은 아니었기에 가이드라인 제공하기 위해 오라클 기준 파라미터세팅과 병                 18c    
렬관련 힌트 테스트진행     .
모두 병렬수행을하는 집계기준이고 현 세팅상 세션별 병렬도 여유도 충분한 상태에서 큰 차이가 없어     ,  db                 
야 정상으로 보임     .
############################################################ 1 시도
가장 자주쓰는 부터 병렬유도방식 확인해봄    group by     . 
하나의 보험회계년월에 수행해야하는 회계단계무브먼트별로 비교를 해보는 경우가 많음               .
대다수가 사용하고 있는 쿼리는 아래처럼 파티션기반 병렬처리를 수행함               .
문제는 회계결산단계별로 데이터 양이 극단적으로 불균형하게 차이나고 필요 경과기간 상이 결산단계별             (     ,   
적용 가정 상이 특정 무브먼트 대상계약 상이하여 레코드 수 차이 남     ,                )
일부 결산단계만 수행할 경우 두세개의 파티션만을 이용하여 분석하기도 하므로 병렬도가 높은것이 도움                      
이 전혀 되지 않음       .
=>       . 블록기반으로 유도하는것이 여러모로 현명함
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
EXPLAIN PLAN FOR
SELECT /*+FULL(A) PARALLEL(A 16)*/ MVMT_SECD FROM CF_SIMU.IFRS_CF_BYPDT_INF A 
WHERE IFRS_ACTS_YYMM ='201812' GROUP BY MVMT_SECD;
Plan hash value: 1684526887
-------------------------------------------------------------------------------------------------------------------------------------------------
| Id  | Operation                      | Name              | Rows  | Bytes | Cost (%CPU)| Time     | Pstart| Pstop |    TQ  |IN-OUT| PQ Distrib |
-------------------------------------------------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT               |                   |     1 |    15 |    2   (0)| 00:00:01 |       |       |        |      |            |
|   1 |  PX COORDINATOR                |                   |       |       |           |          |       |       |        |      |            |
|   2 |   PX SEND QC (RANDOM)          | :TQ10000          |     1 |    15 |    2   (0)| 00:00:01 |       |       |  Q1,00 | P->S | QC (RAND)  |
|   3 |    PX PARTITION LIST ALL       |                   |     1 |    15 |    2   (0)| 00:00:01 |     1 |    33 |  Q1,00 | PCWC |            |
|   4 |     HASH GROUP BY              |                   |     1 |    15 |    2   (0)| 00:00:01 |       |       |  Q1,00 | PCWP |            |
|   5 |      PX PARTITION RANGE SINGLE |                   |     1 |    15 |    2   (0)| 00:00:01 |    13 |    13 |  Q1,00 | PCWC |            |
|*  6 |       TABLE ACCESS STORAGE FULL| IFRS_CF_BYPDT_INF |     1 |    15 |    2   (0)| 00:00:01 |   397 |   429 |  Q1,00 | PCWP |            |
-------------------------------------------------------------------------------------------------------------------------------------------------
Predicate Information (identified by operation id):
---------------------------------------------------
   6 - storage("IFRS_ACTS_YYMM"='201812')
       filter("IFRS_ACTS_YYMM"='201812')
Note
-----
   - Degree of Parallelism is 16 because of table property
############################################################ 2 시도
아래의 힌트 적용시에도 안타깝지만 실행계획 동일함 동일 일부 회계년월만으로           (hash value  ).     range 
partition         구성된 다른 테스트용 결산테이블에서는
블록기반 병렬유도 되었지만 에서 유도가 매끄럽지 않아보임 다른 내재힌트나      COMPOSITE PARTITION       .     
파라미터도 신경써야하나   ?
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
EXPLAIN PLAN FOR
SELECT /*+ OPT_PARAM('_PX_PARTITION_SCAN_ENABLED' 'FALSE') FULL(A) PARALLEL(A 
16)*/ MVMT_SECD FROM CF_SIMU.IFRS_CF_BYPDT_INF A WHERE IFRS_ACTS_YYMM ='201812' 
GROUP BY MVMT_SECD;
Plan hash value: 1684526887
-------------------------------------------------------------------------------------------------------------------------------------------------
| Id  | Operation                      | Name              | Rows  | Bytes | Cost (%CPU)| Time     | Pstart| Pstop |    TQ  |IN-OUT| PQ Distrib |
-------------------------------------------------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT               |                   |     1 |    15 |    2   (0)| 00:00:01 |       |       |        |      |            |
|   1 |  PX COORDINATOR                |                   |       |       |           |          |       |       |        |      |            |
|   2 |   PX SEND QC (RANDOM)          | :TQ10000          |     1 |    15 |    2   (0)| 00:00:01 |       |       |  Q1,00 | P->S | QC (RAND)  |
|   3 |    PX PARTITION LIST ALL       |                   |     1 |    15 |    2   (0)| 00:00:01 |     1 |    33 |  Q1,00 | PCWC |            |
|   4 |     HASH GROUP BY              |                   |     1 |    15 |    2   (0)| 00:00:01 |       |       |  Q1,00 | PCWP |            |
|   5 |      PX PARTITION RANGE SINGLE |                   |     1 |    15 |    2   (0)| 00:00:01 |    13 |    13 |  Q1,00 | PCWC |            |
|*  6 |       TABLE ACCESS STORAGE FULL| IFRS_CF_BYPDT_INF |     1 |    15 |    2   (0)| 00:00:01 |   397 |   429 |  Q1,00 | PCWP |            |
-------------------------------------------------------------------------------------------------------------------------------------------------
Predicate Information (identified by operation id):
---------------------------------------------------
   6 - storage("IFRS_ACTS_YYMM"='201812')
       filter("IFRS_ACTS_YYMM"='201812')
Note
-----
   - Degree of Parallelism is 16 because of table property


############################################################ 3 시도
파티션프루닝 없이 해서 확인해봄 파티션 일부를 특정하지조차 않고 그럼에도    FULL SCAN   .        .   partition
기반 그래뉼로 넘어감     .
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
EXPLAIN PLAN FOR
SELECT /*+FULL(A) PARALLEL(A 16) */* FROM CF_SIMU.IFRS_CF_BYPDT_INF A;
Plan hash value: 306559591
-----------------------------------------------------------------------------------------------------------------------------------------------
| Id  | Operation                    | Name              | Rows  | Bytes | Cost (%CPU)| Time     | Pstart| Pstop |    TQ  |IN-OUT| PQ Distrib |
-----------------------------------------------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT             |                   |  1190M|   965G|  2878K  (1)| 00:01:53 |       |       |        |      |            |
|   1 |  PX COORDINATOR              |                   |       |       |            |          |       |       |        |      |            |
|   2 |   PX SEND QC (RANDOM)        | :TQ10000          |  1190M|   965G|  2878K  (1)| 00:01:53 |       |       |  Q1,00 | P->S | QC (RAND)  |
|   3 |    PX PARTITION LIST ALL     |                   |  1190M|   965G|  2878K  (1)| 00:01:53 |     1 |  LAST |  Q1,00 | PCWC |            |
|   4 |     TABLE ACCESS STORAGE FULL| IFRS_CF_BYPDT_INF |  1190M|   965G|  2878K  (1)| 00:01:53 |     1 |  1618 |  Q1,00 | PCWP |            |
-----------------------------------------------------------------------------------------------------------------------------------------------
Note
-----
   - Degree of Parallelism is 16 because of table property
############################################################ 4 시도
처음으로 이 로 변경됨 블록기반 병렬 작업임  PX PARTITION  PX BLOCK ITERATOR   .      .
현재 보험회계결산 테이블은 회계년월별로 레인지파티셔닝 되어있고 각각의 메인 파티션에 결       (YYYYMM)    ,       
산무브먼트별 자리 코드 가짓수 현재 로 리스트 서브파티셔닝 되어있음 (4   ,     33)       .
결과적으로 분석대상 테이블은 하나의 회계년월 메인파티션 당 서브파티션 개로 구성되어있는 콤포짓         ( )    33      
파티셔닝 구성임   .
위 실행계획과 다른 것을 생각해보면 메인파티션이 특정이 되어 있느냐 안되느냐 일부만 특정되어서         ,          ,     
서브파티션을 얼마만큼 읽느냐가 관계있는것으로 보임         .
파티션단위로 세그먼트가 구분되기 때문에 조건으로 세그먼트 자체가 하나로 특정되지 않는 환경       , WHERE             
에서라면, 
OPT_PARAM('_PX_PARTITION_SCAN_ENABLED', 'FALSE')      . <=   힌트가 적용되는것을 확인함 혹시 세
그먼트 개수에 따라 힌트가 영향을 받을수도 있어보이므로 확인필요함              
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
EXPLAIN PLAN FOR
SELECT /*+ OPT_PARAM('_PX_PARTITION_SCAN_ENABLED', 'FALSE') FULL(A) PARALLEL(A 
16) */* FROM CF_SIMU.IFRS_CF_BYPDT_INF A;
Plan hash value: 2884436594
-----------------------------------------------------------------------------------------------------------------------------------------------
| Id  | Operation                    | Name              | Rows  | Bytes | Cost (%CPU)| Time     | Pstart| Pstop |    TQ  |IN-OUT| PQ Distrib |
-----------------------------------------------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT             |                   |  1190M|   965G|  2878K  (1)| 00:01:53 |       |       |        |      |            |
|   1 |  PX COORDINATOR              |                   |       |       |            |          |       |       |        |      |            |
|   2 |   PX SEND QC (RANDOM)        | :TQ10000          |  1190M|   965G|  2878K  (1)| 00:01:53 |       |       |  Q1,00 | P->S | QC (RAND)  |
|   3 |    PX BLOCK ITERATOR         |                   |  1190M|   965G|  2878K  (1)| 00:01:53 |     1 |  LAST |  Q1,00 | PCWC |            |
|   4 |     TABLE ACCESS STORAGE FULL| IFRS_CF_BYPDT_INF |  1190M|   965G|  2878K  (1)| 00:01:53 |     1 |  1618 |  Q1,00 | PCWP |            |
-----------------------------------------------------------------------------------------------------------------------------------------------
Note
-----
   - Degree of Parallelism is 16 because of table property
############################################################ 5 시도
메인파티션 하나의 회계년월 만 특정해준 경우 오히려 해당 메인파티션의 세그먼트들 전체를 읽는식으로 (   )                  
옵티마이저가 판단하여   , 
파티션기반 병렬파라미터조정 힌트 없이도 처음부터 블록기반 그래뉼로 작동함               .
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
EXPLAIN PLAN FOR
SELECT /*+FULL(A) PARALLEL(A 16) */* FROM CF_SIMU.IFRS_CF_BYPDT_INF A WHERE 
IFRS_ACTS_YYMM ='201812';
Plan hash value: 2884436594
-----------------------------------------------------------------------------------------------------------------------------------------------
| Id  | Operation                    | Name              | Rows  | Bytes | Cost (%CPU)| Time    | Pstart| Pstop |    TQ  |IN-OUT| PQ Distrib |
-----------------------------------------------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT             |                   |     1 |  2119 |     2  (0)| 00:00:01 |       |       |        |      |            |
|   1 |  PX COORDINATOR              |                   |       |       |           |          |       |       |        |      |            |
|   2 |   PX SEND QC (RANDOM)        | :TQ10000          |     1 |  2119 |     2  (0)| 00:00:01 |       |       |  Q1,00 | P->S | QC (RAND)  |
|   3 |    PX BLOCK ITERATOR         |                   |     1 |  2119 |     2  (0)| 00:00:01 |     1 |    33 |  Q1,00 | PCWC |            |
|*  4 |     TABLE ACCESS STORAGE FULL| IFRS_CF_BYPDT_INF |     1 |  2119 |     2  (0)| 00:00:01 |   397 |   429 |  Q1,00 | PCWP |            |
-----------------------------------------------------------------------------------------------------------------------------------------------
Predicate Information (identified by operation id):
---------------------------------------------------
   4 - storage("IFRS_ACTS_YYMM"='201812')
       filter("IFRS_ACTS_YYMM"='201812')
Note
-----
   - Degree of Parallelism is 16 because of table property
그래서 힌트를 준것과 안준것이 동일한 실행계획으로 구성됨  opt_param           .
**************************************************************************
**************************************************************************
작용기제 유추함   .
우선 로 적용되는 기준이 파티션의 개수가 슬레이브의 배로 잡혀있는것으로 추측  PARTITION GRANULE            2    
됨.
현재 회계결산에서 정의한 결산무브먼트에 따라 서브파티션은 하나의 파티션당 개로 구성되어 있음                33     .
그런데 병렬도 까지는 로 시작하는 반면 병렬도 부터는    16  PARTITION RANGE SINGLE      ,   17  PX_BLOCK 
ITERATOR       , 로 시작하는 것으로 보아
PARTITION                      . 병렬의 기준이 슬레이브수의 두배이상으로 파티션 개수가 많은때라는 것을 알 수 있음
따라서 메인파티션으로 등치조건 을 준 경우에는 서브파티션개수만으로 확인하기 때문에     (=)           ,
서브파티션 개수가 개인것을 알고 있으므로 조정해야하는 것으로 추측함    33           .
OPT_PARAM('_PX_PARTITION_SCAN_THRESHOLD' '')      , 힌트는 사용을 주의해야하는데
왜냐하면 파티션병렬을 포기하고 블록기반 병렬을 선택하는 것이 아니라              
병렬수행자체를 취소하고 실행계획상에서 컬럼 자체가 사라지고 테이블 액세스도 아니고 인덱스 엑세   (  TQ               
스를 보임   )
병렬이 아닌 인덱스 이용 수행으로 처음부터 파싱할수도 있음               .
옵티마이저 판단으로 파티션기반 최적화스캔하는 것을 포기할 수 없어서 블록기준 병렬스캔을 가지 않고                        
아예 병렬자체를 안해버리는 참사가 벌어진다         .
결산데이터 구조상 파티션그래뉼이 항상 비효율적이므로 블록그래뉼기반으로 유도한게 목표 다른 힌트나               .   
방식을 찾는것이 현명해보임 아래후술     . 
************************************************************************** 1 방안
사실 나 조정이 고객사 입장에서는 일반사용자들에게 가이드라인을 세우기 힘들 수  hint  parameter    dba            
있음. 
차라리 항상 모든 서브파티션인 무브먼트들을 분석하지는 않으니 필요없는 결산단계 몇개는 제외하는             ,       
특정조건으로 조건 해서 저절로 유도하는것은 어떨지 어차피 대부분의 그룹핑진행은  not in  filtering        ?     
많아봐야 개대로 보임  20   .
혹은 병렬도를 수정하는 것은 어떨지 기존보다 더 많이 잡아서 서브파티션개수 보다 많아지면 유도         ?           1/2    
됨
메인파티션을 특정했으므로 서브파티션 개에서 개빼면 개 그리고 는 개이므로 블록      33  2  31 ,   16 DOP *2  32  
기반으로 유도됨

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
EXPLAIN PLAN FOR
SELECT /*+FULL(A) PARALLEL(A 16)*/ 
MVMT_SECD, COUNT(*) FROM CF_SIMU.IFRS_CF_BYPDT_INF A WHERE IFRS_ACTS_YYMM 
='201812' AND MVMT_SECD NOT IN ('1000', '1130') GROUP BY MVMT_SECD;
Plan hash value: 1633003598
---------------------------------------------------------------------------------------------------------------------------------------------------
| Id  | Operation                        | Name              | Rows  | Bytes | Cost (%CPU)| Time    | Pstart| Pstop |    TQ  |IN-OUT| PQ Distrib |
---------------------------------------------------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                 |                   |     1 |    15 |    2   (0)| 00:00:01 |       |       |        |      |            |
|   1 |  PX COORDINATOR                  |                   |       |       |           |          |       |       |        |      |            |
|   2 |   PX SEND QC (RANDOM)            | :TQ10001          |     1 |    15 |    2   (0)| 00:00:01 |       |       |  Q1,01 | P->S | QC (RAND)  |
|   3 |    HASH GROUP BY                 |                   |     1 |    15 |    2   (0)| 00:00:01 |       |       |  Q1,01 | PCWP |            |
|   4 |     PX RECEIVE                   |                   |     1 |    15 |    2   (0)| 00:00:01 |       |       |  Q1,01 | PCWP |            |
|   5 |      PX SEND HASH                | :TQ10000          |     1 |    15 |    2   (0)| 00:00:01 |       |       |  Q1,00 | P->P | HASH       |
|   6 |       HASH GROUP BY              |                   |     1 |    15 |    2   (0)| 00:00:01 |       |       |  Q1,00 | PCWP |            |
|   7 |        PX BLOCK ITERATOR         |                   |     1 |    15 |    2   (0)| 00:00:01 |   KEY |   KEY |  Q1,00 | PCWC |            |
|*  8 |         TABLE ACCESS STORAGE FULL| IFRS_CF_BYPDT_INF |     1 |    15 |    2   (0)| 00:00:01 |   397 |   429 |  Q1,00 | PCWP |            |
---------------------------------------------------------------------------------------------------------------------------------------------------
Predicate Information (identified by operation id):
---------------------------------------------------
   8 - storage("IFRS_ACTS_YYMM"='201812')
       filter("IFRS_ACTS_YYMM"='201812')
Note
-----
   - Degree of Parallelism is 16 because of table property
혹은 개수를 개 이상으로 하여 개 서브파티션 개수보다 많도록 하여 언제나  DOP  17      33            BLOCK ITERATOR
로 유도함
Plan hash value: 4227840072
---------------------------------------------------------------------------------------------------------------------------------------------------
| Id  | Operation                        | Name              | Rows  | Bytes | Cost (%CPU)| Time    | Pstart| Pstop |    TQ  |IN-OUT| PQ Distrib |
---------------------------------------------------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                 |                   |     1 |    15 |    2   (0)| 00:00:01 |       |       |        |      |            |
|   1 |  PX COORDINATOR                  |                   |       |       |           |          |       |       |        |      |            |
|   2 |   PX SEND QC (RANDOM)            | :TQ10001          |     1 |    15 |    2   (0)| 00:00:01 |       |       |  Q1,01 | P->S | QC (RAND)  |
|   3 |    HASH GROUP BY                 |                   |     1 |    15 |    2   (0)| 00:00:01 |       |       |  Q1,01 | PCWP |            |
|   4 |     PX RECEIVE                   |                   |     1 |    15 |    2   (0)| 00:00:01 |       |       |  Q1,01 | PCWP |            |
|   5 |      PX SEND HASH                | :TQ10000          |     1 |    15 |    2   (0)| 00:00:01 |       |       |  Q1,00 | P->P | HASH       |
|   6 |       HASH GROUP BY              |                   |     1 |    15 |    2   (0)| 00:00:01 |       |       |  Q1,00 | PCWP |            |
|   7 |        PX BLOCK ITERATOR         |                   |     1 |    15 |    2   (0)| 00:00:01 |     1 |    33 |  Q1,00 | PCWC |            |
|*  8 |         TABLE ACCESS STORAGE FULL| IFRS_CF_BYPDT_INF |     1 |    15 |    2   (0)| 00:00:01 |   397 |   429 |  Q1,00 | PCWP |            |
---------------------------------------------------------------------------------------------------------------------------------------------------
Predicate Information (identified by operation id):
---------------------------------------------------
   8 - storage("IFRS_ACTS_YYMM"='201812')
       filter("IFRS_ACTS_YYMM"='201812')
Note
-----
   - Degree of Parallelism is 17 because of table property

************************************************************************** 2  방안
--선택
구글링해보니 다른 힌트로 제어할 수 있어보임 내재파라미터 조정을 쿼리에서 수행하지 않아 덜 위험해           .             
보이고 간단해보임   .
NO_USE_PARTITION_WISE_GBY     OPT_PARAM('_PX_PARTITION_SCAN_ENABLED'  를 사용시
'FALSE')           . 라는 파라미터 힌트를 사용하지 않아도 됨
원래는 옵티마이저 파라미터조정시에도 서브파티션 단위에서는 단위 병렬을 시도했지만 그          PARTITION         
이유는 힌트가 내재되어있기 때문임 까지 실행계획옵션 바꿔서  USE_PARTITION_WISE_GBY      . OUTLINE      
확인함.
그래서 이 옵션자체만 꺼도 로 작동할 수 있음 아래의 두 쿼리가 동일한        BLOCK ITERATOR       .         PLAN HASH
VALUE  . 나타냄
SELECT /*+OPT_PARAM('_PX_PARTITION_SCAN_ENABLED' 'FALSE') 
NO_USE_PARTITION_WISE_GBY FULL(A) PARALLEL(A 16)*/ MVMT_SECD FROM 
CF_SIMU.IFRS_CF_BYPDT_INF A WHERE IFRS_ACTS_YYMM ='201812' GROUP BY MVMT_SECD;
SELECT /*+NO_USE_PARTITION_WISE_GBY FULL(A) PARALLEL(A 16)*/ MVMT_SECD FROM 
CF_SIMU.IFRS_CF_BYPDT_INF A WHERE IFRS_ACTS_YYMM ='201812' GROUP BY MVMT_SECD;
Plan hash value: 4227840072
-------------------------------------------------------------------------------------------------------------------------------------------
| Id  | Operation                | Name              | Rows  | Bytes | Cost (%CPU)| Time     | Pstart| Pstop |    TQ  |IN-OUT| PQ Distrib |
-------------------------------------------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT         |                   |     1 |    15 |     2   (0)| 00:00:01 |       |       |        |      |            |
|   1 |  PX COORDINATOR          |                   |       |       |            |          |       |       |        |      |            |
|   2 |   PX SEND QC (RANDOM)    | :TQ10001          |     1 |    15 |     2   (0)| 00:00:01 |       |       |  Q1,01 | P->S | QC (RAND)  |
|   3 |    HASH GROUP BY         |                   |     1 |    15 |     2   (0)| 00:00:01 |       |       |  Q1,01 | PCWP |            |
|   4 |     PX RECEIVE           |                   |     1 |    15 |     2   (0)| 00:00:01 |       |       |  Q1,01 | PCWP |            |
|   5 |      PX SEND HASH        | :TQ10000          |     1 |    15 |     2   (0)| 00:00:01 |       |       |  Q1,00 | P->P | HASH       |
|   6 |       HASH GROUP BY      |                   |     1 |    15 |     2   (0)| 00:00:01 |       |       |  Q1,00 | PCWP |            |
|   7 |        PX BLOCK ITERATOR |                   |     1 |    15 |     2   (0)| 00:00:01 |     1 |    33 |  Q1,00 | PCWC |            |
|*  8 |         TABLE ACCESS FULL| IFRS_CF_BYPDT_INF |     1 |    15 |     2   (0)| 00:00:01 |   397 |   429 |  Q1,00 | PCWP |            |
-------------------------------------------------------------------------------------------------------------------------------------------
Outline Data
-------------
  /*+
      BEGIN_OUTLINE_DATA
      USE_HASH_AGGREGATION(@"SEL$1")
      GBY_PUSHDOWN(@"SEL$1")
      FULL(@"SEL$1" "A"@"SEL$1")
      OUTLINE_LEAF(@"SEL$1")
      ALL_ROWS
      OPT_PARAM('_px_partition_scan_enabled' 'false')
      DB_VERSION('18.1.0')
      OPTIMIZER_FEATURES_ENABLE('18.1.0')
      IGNORE_OPTIM_EMBEDDED_HINTS
      END_OUTLINE_DATA
  */
Predicate Information (identified by operation id):
---------------------------------------------------
   8 - filter("IFRS_ACTS_YYMM"='201812')
