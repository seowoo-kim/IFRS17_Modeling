SET TIMING ON;

--���� ��ǰ�� ci�㺸(���� 13�� ��, �ι�° �Ϲ߻��� ��)�� ������� �����ڷ�(�ҽ����̺� 1,2)�� �̿��Ͽ� �����ϱ� ���� �۾�.

SELECT * FROM MIG.FND_RKRT_INF WHERE LAST_HIS_YN ='1' AND DEL_YN ='0';
--RISK_RATE   --SOURCE2, ����� �ֽſ��ο� ���Ұ����� �ΰ��� flag�� ���еǴ� ���̺�
SELECT * FROM CF_SIMU.IFRS_CI_BFRT_CRT_LST WHERE CLO_YYMM ='201812' AND LAST_HIS_YN ='1' AND DEL_YN ='0';
--Gen_CI_Rate   --SOURCE1
SELECT * FROM CF_SIMU.CI_BFRT_INF;
--CI_Ben_Rate    TARGET
--RISK RATE TABLE�� CLO_YYMM(�������)�� ����. �����ؾ���. ��ȸ��������� ���ܰ迡 ����� �㺸���� �α׸� ������ �־�� ����������̳� �������� �ݿ��� �� �����Ƿ� ��Ƽ�Ŵװ����ʿ�.=> ������� ��Ƽ�Ŵ� �߰���.


--��CI �㺸�ڵ� ���� ���� Ȯ���ϱ�
--CI�㺸���� �Ϲ� ��������� ������ �ƴ϶� ����� CI�㺸�� �������ϴ� ���������. �׸��� �� Ư���� �������������(���� �ſ� ����, �Ⱓ������ ���� ����, �踮����� ���� ��)���� ���ռ� ���� �ݵ�� �Ұ�
--Ư�� CI �㺸���� �ҽ����̺���� �ۿ����� ȣ��� ����� �Է� ����ȭ�� ���� ����ȭ�� ���������ռ� Ȯ���� ���� ���̺����� �ƴ�. ������ ���������ռ� ���� �ۼ��Ұ�.
--�ϳ��� �㺸�ڵ�(output���)�� �������� ������ڵ�1~13��(RKRT_1_ID~RKRT_13_ID) �÷��� �ִ� ���� �����ϴµ�(�������� ������ 13�� �÷����ä�������� �����Ƿ� ����), �̶� �� ������ڵ尡 �̹� ������Ǿ� �ִ� �㺸�ڵ�(output���)�� �������Ͽ� ����� ���谡 ����.
--�ƹ��͵� �������� �ʰ� �㺸�ڵ尡 �ƴ� ���ʵ����͸��� ����ϴ� ����� LV1, �׸��� �����ϴ� ������ڵ��� ���� ����LV + 1�� �ش� �㺸�ڵ��� LV(����)�� ��.
--ex) �㺸�ڵ尡 �����ϴ� ������ڵ��� ��������1,3, Ȥ�� �㺸�ڵ尡�ƴ� �ҽ������͵�(���ǻ�lv0)�̶�� �̶� ���� ���� ���� ������ 3�̶�� �ش� �㺸�ڵ�� LV4�� ��.

--�Ʒ� ������ ����ڰ� �ǵ��Ѵ�� �� ������ �㺸�ڵ尡 �°� �ԷµǾ��ִ��� Ȯ��.
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





--���� ���ϰ����� �� ���� �������� ���δ���� �޶����Ƿ�(����1�� ��������� ������ ����2���ʹ� ����1������� ������ �����ؾ��ϹǷ� LV2���ʹ� ��Ͱ�������) ������ �ΰ����� �����Ͽ� ������ �־����. �׸��� 2�̻��� �������� ������ �۴ܿ��� �ۼ��ϵ��� ��.
--���� �۾������ ���ø����̼ǿ��� ����ϴ� SQLITE�� Ư������� ����Ͽ����� ORACLE���� ���� �Ұ�, ���� XML QUERY�̿���.
--������ ��� �ִ� RKRT_CALFM_RMK(�÷� �� ����: Q1+Q2/2-(1-Q3*Q4)) �÷����� Q1(1�������)~ Q13(13�������)���̿��� ������ ǥ���ϰ� �����Ƿ� xmlǥ�������� ������ ���ε� ���� �־ ��갪�� ��ȯ�޾� INSERT�ؾ���.
--�� ����� Ư����(�����Ϲ߻����� �ִ뿬��, ��谡�ִ� ������ �ٸ�) �ִ�Ⱓ�� ������ �ٸ� ������� ���� �ִٸ� ����� �ؾ��ϹǷ�  �������ǱⰣ ���������� �Ұ�.
--����ȭ�Ǿ����� �ʾ� ������ CACL_TYP_COD(CI�㺸�������)�÷� �� Pri, CF, N���� ����س����ϴ� ��İ�(�δ㺸�Ⱓ ���뿩�� ��) 3�����Ⱓ�������� �ٸ��Ƿ� ���ǰ� �ʿ���.
--īƼ�������� ������ �Ⱓ�� �÷��� ���� ����Ŀ� ���缭 ���� �������ְ�, ���ǿ� ���� �ʴ� ���ڵ�� ���͸��ؼ� �ʿ��� ������ �ִ� ���� ���ռ� ������ ���� ���̶� �Ǵ���.

------------------------------------------------------------------------------------------------
--LEVEL 1, ���ϰ����� ���� ����. ������ ������. �ٸ� ���� 2~ �̻��� �÷������� ��ƿͼ� �۾��� �����ؾ���.
------------------------------------------------------------------------------------------------

--SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
--EXPLAIN PLAN FOR

INSERT /*+ENABLE_PARALLEL_DML PARALLEL(Z 16) OPT_PARAM('_OPTIMIZER_GATHER_STATS_ON_LOAD' 'FALSE') */ 
INTO CF_SIMU.CI_BFRT_INF Z       --�Ʒ��� �Է��ؾ��ϴ� ��������� ���缭 CLO_YYMM �����������. 07.21����
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
            FROM CF_SIMU.IFRS_CI_BFRT_CRT_LST A WHERE CLO_YYMM ='201812' AND LAST_HIS_YN ='1' AND DEL_YN ='0'   --�Է��ؾ��ϴ� ��������� ���缭 CLO_YYMM �����������. 07.21����
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


------------------------------------------------------------------------------------------------
--LEVEL 2~ �� ���� ����
------------------------------------------------------------------------------------------------
--SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
--EXPLAIN PLAN FOR

INSERT /*+ENABLE_PARALLEL_DML PARALLEL(Z 16) OPT_PARAM('_OPTIMIZER_GATHER_STATS_ON_LOAD' 'FALSE') */ 
INTO CF_SIMU.CI_BFRT_INF Z      --�Ʒ��� �Է��ؾ��ϴ� ��������� ���缭 CLO_YYMM �����������. 07.21����
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
                                (SELECT * FROM CF_SIMU.IFRS_CI_BFRT_CRT_LST WHERE CLO_YYMM ='201812' AND LAST_HIS_YN ='1' AND DEL_YN ='0') A    --�Է��ؾ��ϴ� ��������� ���缭 CLO_YYMM �����������. 07.21����
                                UNPIVOT(RKRT_ID FOR ID_NUM IN(RKRT_1_ID,RKRT_2_ID,RKRT_3_ID,RKRT_4_ID,RKRT_5_ID,RKRT_6_ID,RKRT_7_ID,RKRT_8_ID,RKRT_9_ID,RKRT_10_ID,RKRT_11_ID,RKRT_12_ID,RKRT_13_ID))
                            )
                        CONNECT BY NOCYCLE PRIOR IFRS_CLM_ID = RKRT_ID) WHERE LV =2) B	--����� ������ ���� LV �����������. ��������.
                WHERE A.CLO_YYMM ='201812' AND A.LAST_HIS_YN ='1' AND A.DEL_YN ='0' AND A.IFRS_CLM_ID = B.IFRS_CLM_ID   --�Է��ؾ��ϴ� ��������� ���缭 CLO_YYMM �����������. 07.21����
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
                            (SELECT * FROM CF_SIMU.IFRS_CI_BFRT_CRT_LST WHERE CLO_YYMM ='201812' AND LAST_HIS_YN ='1' AND DEL_YN ='0') A    --�Է��ؾ��ϴ� ��������� ���缭 CLO_YYMM �����������. 07.21����
                            UNPIVOT(RKRT_ID FOR ID_NUM IN(RKRT_1_ID,RKRT_2_ID,RKRT_3_ID,RKRT_4_ID,RKRT_5_ID,RKRT_6_ID,RKRT_7_ID,RKRT_8_ID,RKRT_9_ID,RKRT_10_ID,RKRT_11_ID,RKRT_12_ID,RKRT_13_ID))
                        )
                    CONNECT BY NOCYCLE PRIOR IFRS_CLM_ID = RKRT_ID) WHERE LV =2) B	--�����Է��ؾ���, ����� 2, �̰��� �ִ�������� �������Ѿ���
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
                WHERE A.MIG_CLO_YYMM ='201812' AND A.LAST_HIS_YN ='1' AND A.DEL_YN ='0' AND (A.AGE - (CASE WHEN B.CACL_TYP_COD = 'Pri' THEN B.LV - 2 ELSE FLOOR((B.LV - 5)/12) END)) > = 0  --�Է��ؾ��ϴ� ��������� ���缭 CLO_YYMM �����������. 07.21����
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


