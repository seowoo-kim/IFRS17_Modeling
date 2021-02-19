
```sql

--### 업무요건
--RA(위험조정금액, Risk Adjustment)는 각각의 상계단위 별로(회사에서 정책으로 정한 포트폴리오 단위와 회계단위) 그룹핑을 여러 키단위로 반복하여야 적정한 금액이 산출됨
--결산기준테이블 IFRS_CF_PLYNO_BY_INF에 들어갈 RA금액을 계산하는 과정에서 이전 결산에서 산출한 상계과정에서의 배분비율을 담는 WHCOM_RA_SHAR_RTO_INF정보도 같이 생성하게됨
--별도로 산출하게 될시, 결산테이블에 필요할 수백컬럼을 사용하지 않더라도 몇천만~1억조금 넘는 데이터를 반복스캔하고 여러기준 grouping해야하는 부하가 있음.
--따라서 multi insert방식으로 산출한 값에서 필요한 인스턴스의 값만을 플래그로(RA_IDX) WHCOM_RA_SHAR_RTO_INF에 입력하고,
--모든(WHEN 1 = 1조건) 결산과정정보는 그대로 IFRS_CF_PLYNO_BY_INF에 입력함.


SET TIMING ON;

--쿼리 수행 전 실행계획을 확인하기 위한 실행계획 생성과, plan table SELECT
--SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', NULL, 'OUTLINE'));
--EXPLAIN PLAN FOR



INSERT  /*+ ENABLE_PARALLEL_DML APPEND_VALUES PARALLEL(IFRS_CF_PLYNO_BY_INF 16) PARALLEL(WHCOM_RA_SHAR_RTO_INF 16) */ ALL
  WHEN RA_IDX = 1 THEN
    INTO CF_SIMU.WHCOM_RA_SHAR_RTO_INF VALUES(IFRS_ACTS_YYMM, IFRS_WRK_SECD, MVMT_SECD, 'P', PROG_YYMM, APPT_DCRT_SECD, '0', RA_RATIO)  
  WHEN 1 = 1 THEN
    INTO CF_SIMU.IFRS_CF_PLYNO_BY_INF VALUES(
    IFRS_ACTS_YYMM
    , VALU_YYMM
    , PLYNO
    , MPRD_PRDCD
    , IFRS_WRK_SECD
    , MVMT_SECD
    , PROG_YYMM
    , INIT_RCGNT_TYP_COD
    , APPT_DCRT_SECD
    , SAME_GRP_TYP_COD
    , TMP_PK
    , LFDE_MMRP_COD
    , PF_SECD
    , VALU_MDL_NAM
    , INIT_RCGNT_DTM
    , ELMN_DTM
    , BEL_BAS_PREM
    , BEL_AD_PYPRM_VL
    , BEL_INS_CPNT_DTH_PIABA
    , BEL_INS_CPNT_DISA_PIABA
    , BEL_INS_CPNT_DIAG_PIABA
    , BEL_INS_CPNT_SUROP_PIABA
    , BEL_INS_CPNT_HSPZ_PIABA
    , BEL_INS_CPNT_PLOS_PIABA
    , BEL_INS_CPNT_OTR_PIABA
    , BEL_INS_CPNT_ANTY_DFR_AMT
    , BEL_INS_CPNT_PYEX_PREM_VL
    , BEL_INS_CPNT_ACCT_SRDR_RF
    , BEL_INS_CPNT_POHD_DIVD_AMT
    , BEL_IVST_CPNT_EXPI_RF
    , BEL_IVST_CPNT_SRDR_RF
    , BEL_IVST_CPNT_ANTY_DFR_AMT
    , BEL_IVST_CPNT_SRVL_DFR_AMT
    , BEL_IVST_CPNT_MW_WDRW_AMT
    , BEL_IVST_CPNT_ACCT_SRDR_RF
    , BEL_IVST_CPNT_OTR_AMT
    , BEL_DFMT_INCTLN_NW_AMT
    , BEL_DFMT_INCTLN_PRPT_ADMN_EXPN
    , BEL_DPS_INCTLN_RFDAMT
    , BEL_DPS_INCTLN_INTAMT
    , BEL_DIR_NBZEXP_INS_COMS
    , BEL_DIR_NBZEXP_INS_OTR_COMS
    , BEL_DIR_NBZEXP_OTR_COMS
    , BEL_SERV_EXPN_DIR_MTEXP
    , BEL_TAX_PBIMP_DIR_MTEXP
    , BEL_EDUT_DIR_MTEXP
    , BEL_DPST_PREM_DIR_MTEXP
    , BEL_COLEXP_DIR_MTEXP
    , BEL_OTR_DIR_MTEXP
    , BEL_DIR_LOSDMG_INVT_EXPN
    , BEL_PRPT_ADMN_EXPN
    , BEL_IMF_EXPN
    , INS_CPNT_DVP_BEL_AMT
    , IVST_CPNT_DVP_BEL_AMT
    , RA_EXPN
    , INS_CPNT_TVOG_AMT
    , IVST_CPNT_TVOG_AMT
    , CF_BAS_PREM
    , CF_AD_PYPRM_VL
    , CF_INS_CPNT_DTH_PIABA
    , CF_INS_CPNT_DISA_PIABA
    , CF_INS_CPNT_DIAG_PIABA
    , CF_INS_CPNT_SUROP_PIABA
    , CF_INS_CPNT_HSPZ_PIABA
    , CF_INS_CPNT_PLOS_PIABA
    , CF_INS_CPNT_OTR_PIABA
    , CF_INS_CPNT_ANTY_DFR_AMT
    , CF_INS_CPNT_PYEX_PREM_VL
    , CF_INS_CPNT_ACCT_SRDR_RF
    , CF_INS_CPNT_POHD_DIVD_AMT
    , CF_IVST_CPNT_EXPI_RF
    , CF_IVST_CPNT_SRDR_RF
    , CF_IVST_CPNT_ANTY_DFR_AMT
    , CF_IVST_CPNT_SRVL_DFR_AMT
    , CF_IVST_CPNT_MW_WDRW_AMT
    , CF_IVST_CPNT_ACCT_SRDR_RF
    , CF_IVST_CPNT_OTR_AMT
    , CF_DFMT_INCTLN_NW_AMT
    , CF_DFMT_INCTLN_PRPT_ADMN_EXPN
    , CF_DPS_INCTLN_RFDAMT
    , CF_DPS_INCTLN_INTAMT
    , CF_DIR_NBZEXP_INS_COMS
    , CF_DIR_NBZEXP_INS_OTR_COMS
    , CF_DIR_NBZEXP_OTR_COMS
    , CF_SERV_EXPN_DIR_MTEXP
    , CF_TAX_PBIMP_DIR_MTEXP
    , CF_EDUT_DIR_MTEXP
    , CF_DPST_PREM_DIR_MTEXP
    , CF_COLEXP_DIR_MTEXP
    , CF_OTR_DIR_MTEXP
    , CF_DIR_LOSDMG_INVT_EXPN
    , CF_PRPT_ADMN_EXPN
    , CF_IMF_EXPN
    , BEL_INTAMT
    , RA_INTAMT
    , TVOG_INTAMT
    , GOC_TYP_COD
    , PBEL_BAS_PREM
    , PBEL_AD_PYPRM_VL
    , PBEL_INS_CPNT_DTH_PIABA
    , PBEL_INS_CPNT_DISA_PIABA
    , PBEL_INS_CPNT_DIAG_PIABA
    , PBEL_INS_CPNT_SUROP_PIABA
    , PBEL_INS_CPNT_HSPZ_PIABA
    , PBEL_INS_CPNT_PLOS_PIABA
    , PBEL_INS_CPNT_OTR_PIABA
    , PBEL_INS_CPNT_ANTY_DFR_AMT
    , PBEL_INS_CPNT_PYEX_PREM_VL
    , PBEL_INS_CPNT_ACCT_SRDR_RF
    , PBEL_INS_CPNT_POHD_DIVD_AMT
    , PBEL_IVST_CPNT_EXPI_RF
    , PBEL_IVST_CPNT_SRDR_RF
    , PBEL_IVST_CPNT_ANTY_DFR_AMT
    , PBEL_IVST_CPNT_SRVL_DFR_AMT
    , PBEL_IVST_CPNT_MW_WDRW_AMT
    , PBEL_IVST_CPNT_ACCT_SRDR_RF
    , PBEL_IVST_CPNT_OTR_AMT
    , PBEL_DFMT_INCTLN_NW_AMT
    , PBEL_DFMT_INCTLN_PRPT_ADMN_EXPN
    , PBEL_DPS_INCTLN_RFDAMT
    , PBEL_DPS_INCTLN_INTAMT
    , PBEL_DIR_NBZEXP_INS_COMS
    , PBEL_DIR_NBZEXP_INS_OTR_COMS
    , PBEL_DIR_NBZEXP_OTR_COMS
    , PBEL_SERV_EXPN_DIR_MTEXP
    , PBEL_TAX_PBIMP_DIR_MTEXP
    , PBEL_EDUT_DIR_MTEXP
    , PBEL_DPST_PREM_DIR_MTEXP
    , PBEL_COLEXP_DIR_MTEXP
    , PBEL_OTR_DIR_MTEXP
    , PBEL_DIR_LOSDMG_INVT_EXPN
    , PBEL_PRPT_ADMN_EXPN
    , PBEL_IMF_EXPN
    , PCF_BAS_PREM
    , PCF_AD_PYPRM_VL
    , PCF_INS_CPNT_DTH_PIABA
    , PCF_INS_CPNT_DISA_PIABA
    , PCF_INS_CPNT_DIAG_PIABA
    , PCF_INS_CPNT_SUROP_PIABA
    , PCF_INS_CPNT_HSPZ_PIABA
    , PCF_INS_CPNT_PLOS_PIABA
    , PCF_INS_CPNT_OTR_PIABA
    , PCF_INS_CPNT_ANTY_DFR_AMT
    , PCF_INS_CPNT_PYEX_PREM_VL
    , PCF_INS_CPNT_ACCT_SRDR_RF
    , PCF_INS_CPNT_POHD_DIVD_AMT
    , PCF_IVST_CPNT_EXPI_RF
    , PCF_IVST_CPNT_SRDR_RF
    , PCF_IVST_CPNT_ANTY_DFR_AMT
    , PCF_IVST_CPNT_SRVL_DFR_AMT
    , PCF_IVST_CPNT_MW_WDRW_AMT
    , PCF_IVST_CPNT_ACCT_SRDR_RF
    , PCF_IVST_CPNT_OTR_AMT
    , PCF_DFMT_INCTLN_NW_AMT
    , PCF_DFMT_INCTLN_PRPT_ADMN_EXPN
    , PCF_DPS_INCTLN_RFDAMT
    , PCF_DPS_INCTLN_INTAMT
    , PCF_DIR_NBZEXP_INS_COMS
    , PCF_DIR_NBZEXP_INS_OTR_COMS
    , PCF_DIR_NBZEXP_OTR_COMS
    , PCF_SERV_EXPN_DIR_MTEXP
    , PCF_TAX_PBIMP_DIR_MTEXP
    , PCF_EDUT_DIR_MTEXP
    , PCF_DPST_PREM_DIR_MTEXP
    , PCF_COLEXP_DIR_MTEXP
    , PCF_OTR_DIR_MTEXP
    , PCF_DIR_LOSDMG_INVT_EXPN
    , PCF_PRPT_ADMN_EXPN
    , PCF_IMF_EXPN)
    
  SELECT /*+PARALLEL(A 16) */
       A.IFRS_ACTS_YYMM                                     AS IFRS_ACTS_YYMM           
       , A.VALU_YYMM                                        AS VALU_YYMM                 
       , A.PLYNO                                            AS PLYNO                    
       , A.MPRD_PRDCD                                       AS MPRD_PRDCD          
       , A.IFRS_WRK_SECD                                    AS IFRS_WRK_SECD         
       , A.MVMT_SECD                                        AS MVMT_SECD               
       , A.PROG_YYMM                                        AS PROG_YYMM           
       , A.INIT_RCGNT_TYP_COD                               AS INIT_RCGNT_TYP_COD     
       , A.APPT_DCRT_SECD                                   AS APPT_DCRT_SECD             
       , A.SAME_GRP_TYP_COD                                 AS SAME_GRP_TYP_COD           
       , A.TMP_PK                                           AS TMP_PK               
       , A.LFDE_MMRP_COD                                    AS LFDE_MMRP_COD            
       , A.PF_SECD                                          AS PF_SECD                   
       , A.VALU_MDL_NAM                                     AS VALU_MDL_NAM              
       , A.INIT_RCGNT_DTM                                   AS INIT_RCGNT_DTM           
       , A.ELMN_DTM                                         AS ELMN_DTM                    
       , A.SBEL_BAS_PREM                                    AS BEL_BAS_PREM                 
       , A.SBEL_AD_PYPRM_VL                                 AS BEL_AD_PYPRM_VL           
       , A.SBEL_INS_CPNT_DTH_PIABA                          AS BEL_INS_CPNT_DTH_PIABA      
       , A.SBEL_INS_CPNT_DISA_PIABA                         AS BEL_INS_CPNT_DISA_PIABA    
       , A.SBEL_INS_CPNT_DIAG_PIABA                         AS BEL_INS_CPNT_DIAG_PIABA       
       , A.SBEL_INS_CPNT_SUROP_PIABA                        AS BEL_INS_CPNT_SUROP_PIABA    
       , A.SBEL_INS_CPNT_HSPZ_PIABA                         AS BEL_INS_CPNT_HSPZ_PIABA   
       , A.SBEL_INS_CPNT_PLOS_PIABA                         AS BEL_INS_CPNT_PLOS_PIABA     
       , A.SBEL_INS_CPNT_OTR_PIABA                          AS BEL_INS_CPNT_OTR_PIABA    
       , A.SBEL_INS_CPNT_ANTY_DFR_AMT                       AS BEL_INS_CPNT_ANTY_DFR_AMT  
       , A.SBEL_INS_CPNT_PYEX_PREM_VL                       AS BEL_INS_CPNT_PYEX_PREM_VL   
       , A.SBEL_INS_CPNT_ACCT_SRDR_RF                       AS BEL_INS_CPNT_ACCT_SRDR_RF    
       , A.SBEL_INS_CPNT_POHD_DIVD_AMT                      AS BEL_INS_CPNT_POHD_DIVD_AMT  
       , A.SBEL_IVST_CPNT_EXPI_RF                           AS BEL_IVST_CPNT_EXPI_RF     
       , A.SBEL_IVST_CPNT_SRDR_RF                           AS BEL_IVST_CPNT_SRDR_RF     
       , A.SBEL_IVST_CPNT_ANTY_DFR_AMT                      AS BEL_IVST_CPNT_ANTY_DFR_AMT   
       , A.SBEL_IVST_CPNT_SRVL_DFR_AMT                      AS BEL_IVST_CPNT_SRVL_DFR_AMT  
       , A.SBEL_IVST_CPNT_MW_WDRW_AMT                       AS BEL_IVST_CPNT_MW_WDRW_AMT   
       , A.SBEL_IVST_CPNT_ACCT_SRDR_RF                      AS BEL_IVST_CPNT_ACCT_SRDR_RF   
       , A.SBEL_IVST_CPNT_OTR_AMT                           AS BEL_IVST_CPNT_OTR_AMT     
       , A.SBEL_DFMT_INCTLN_NW_AMT                          AS BEL_DFMT_INCTLN_NW_AMT  
       , A.SBEL_DFMT_INCTLN_PRPT_ADMN_EXPN                  AS BEL_DFMT_INCTLN_PRPT_ADMN_EXPN   
       , A.SBEL_DPS_INCTLN_RFDAMT                           AS BEL_DPS_INCTLN_RFDAMT   
       , A.SBEL_DPS_INCTLN_INTAMT                           AS BEL_DPS_INCTLN_INTAMT  
       , A.SBEL_DIR_NBZEXP_INS_COMS                         AS BEL_DIR_NBZEXP_INS_COMS   
       , A.SBEL_DIR_NBZEXP_INS_OTR_COMS                     AS BEL_DIR_NBZEXP_INS_OTR_COMS
       , A.SBEL_DIR_NBZEXP_OTR_COMS                         AS BEL_DIR_NBZEXP_OTR_COMS       
       , A.SBEL_SERV_EXPN_DIR_MTEXP                         AS BEL_SERV_EXPN_DIR_MTEXP  
       , A.SBEL_TAX_PBIMP_DIR_MTEXP                         AS BEL_TAX_PBIMP_DIR_MTEXP  
       , A.SBEL_EDUT_DIR_MTEXP                              AS BEL_EDUT_DIR_MTEXP         
       , A.SBEL_DPST_PREM_DIR_MTEXP                         AS BEL_DPST_PREM_DIR_MTEXP    
       , A.SBEL_COLEXP_DIR_MTEXP                            AS BEL_COLEXP_DIR_MTEXP    
       , A.SBEL_OTR_DIR_MTEXP                               AS BEL_OTR_DIR_MTEXP       
       , A.SBEL_DIR_LOSDMG_INVT_EXPN                        AS BEL_DIR_LOSDMG_INVT_EXPN   
       , A.SBEL_PRPT_ADMN_EXPN                              AS BEL_PRPT_ADMN_EXPN      
       , A.SBEL_IMF_EXPN                                    AS BEL_IMF_EXPN                 
       , A.SINS_CPNT_DVP_BEL_AMT                            AS INS_CPNT_DVP_BEL_AMT         
       , A.SIVST_CPNT_DVP_BEL_AMT                           AS IVST_CPNT_DVP_BEL_AMT                  
       , A.RA_VAL                                           AS RA_EXPN                    
       , A.SINS_CPNT_TVOG_AMT                               AS INS_CPNT_TVOG_AMT          
       , A.SIVST_CPNT_TVOG_AMT                              AS IVST_CPNT_TVOG_AMT         
       , A.SCF_BAS_PREM                                     AS CF_BAS_PREM              
       , A.SCF_AD_PYPRM_VL                                  AS CF_AD_PYPRM_VL           
       , A.SCF_INS_CPNT_DTH_PIABA                           AS CF_INS_CPNT_DTH_PIABA       
       , A.SCF_INS_CPNT_DISA_PIABA                          AS CF_INS_CPNT_DISA_PIABA      
       , A.SCF_INS_CPNT_DIAG_PIABA                          AS CF_INS_CPNT_DIAG_PIABA     
       , A.SCF_INS_CPNT_SUROP_PIABA                         AS CF_INS_CPNT_SUROP_PIABA    
       , A.SCF_INS_CPNT_HSPZ_PIABA                          AS CF_INS_CPNT_HSPZ_PIABA       
       , A.SCF_INS_CPNT_PLOS_PIABA                          AS CF_INS_CPNT_PLOS_PIABA   
       , A.SCF_INS_CPNT_OTR_PIABA                           AS CF_INS_CPNT_OTR_PIABA       
       , A.SCF_INS_CPNT_ANTY_DFR_AMT                        AS CF_INS_CPNT_ANTY_DFR_AMT  
       , A.SCF_INS_CPNT_PYEX_PREM_VL                        AS CF_INS_CPNT_PYEX_PREM_VL   
       , A.SCF_INS_CPNT_ACCT_SRDR_RF                        AS CF_INS_CPNT_ACCT_SRDR_RF   
       , A.SCF_INS_CPNT_POHD_DIVD_AMT                       AS CF_INS_CPNT_POHD_DIVD_AMT    
       , A.SCF_IVST_CPNT_EXPI_RF                            AS CF_IVST_CPNT_EXPI_RF        
       , A.SCF_IVST_CPNT_SRDR_RF                            AS CF_IVST_CPNT_SRDR_RF        
       , A.SCF_IVST_CPNT_ANTY_DFR_AMT                       AS CF_IVST_CPNT_ANTY_DFR_AMT   
       , A.SCF_IVST_CPNT_SRVL_DFR_AMT                       AS CF_IVST_CPNT_SRVL_DFR_AMT  
       , A.SCF_IVST_CPNT_MW_WDRW_AMT                        AS CF_IVST_CPNT_MW_WDRW_AMT   
       , A.SCF_IVST_CPNT_ACCT_SRDR_RF                       AS CF_IVST_CPNT_ACCT_SRDR_RF     
       , A.SCF_IVST_CPNT_OTR_AMT                            AS CF_IVST_CPNT_OTR_AMT         
       , A.SCF_DFMT_INCTLN_NW_AMT                           AS CF_DFMT_INCTLN_NW_AMT       
       , A.SCF_DFMT_INCTLN_PRPT_ADMN_EXPN                   AS CF_DFMT_INCTLN_PRPT_ADMN_EXPN 
       , A.SCF_DPS_INCTLN_RFDAMT                            AS CF_DPS_INCTLN_RFDAMT        
       , A.SCF_DPS_INCTLN_INTAMT                            AS CF_DPS_INCTLN_INTAMT        
       , A.SCF_DIR_NBZEXP_INS_COMS                          AS CF_DIR_NBZEXP_INS_COMS      
       , A.SCF_DIR_NBZEXP_INS_OTR_COMS                      AS CF_DIR_NBZEXP_INS_OTR_COMS  
       , A.SCF_DIR_NBZEXP_OTR_COMS                          AS CF_DIR_NBZEXP_OTR_COMS       
       , A.SCF_SERV_EXPN_DIR_MTEXP                          AS CF_SERV_EXPN_DIR_MTEXP      
       , A.SCF_TAX_PBIMP_DIR_MTEXP                          AS CF_TAX_PBIMP_DIR_MTEXP      
       , A.SCF_EDUT_DIR_MTEXP                               AS CF_EDUT_DIR_MTEXP       
       , A.SCF_DPST_PREM_DIR_MTEXP                          AS CF_DPST_PREM_DIR_MTEXP   
       , A.SCF_COLEXP_DIR_MTEXP                             AS CF_COLEXP_DIR_MTEXP    
       , A.SCF_OTR_DIR_MTEXP                                AS CF_OTR_DIR_MTEXP          
       , A.SCF_DIR_LOSDMG_INVT_EXPN                         AS CF_DIR_LOSDMG_INVT_EXPN    
       , A.SCF_PRPT_ADMN_EXPN                               AS CF_PRPT_ADMN_EXPN           
       , A.SCF_IMF_EXPN                                     AS CF_IMF_EXPN                  
       , A.BEL_INTAMT                                       AS BEL_INTAMT                  
       , A.RA_INTAMT                                        AS RA_INTAMT                  
       , A.TVOG_INTAMT                                      AS TVOG_INTAMT          
       , A.GOC_TYP_COD_FIN                                  AS GOC_TYP_COD                         
       , A.SPBEL_BAS_PREM						                        AS PBEL_BAS_PREM
       , A.SPBEL_AD_PYPRM_VL                                AS PBEL_AD_PYPRM_VL
       , A.SPBEL_INS_CPNT_DTH_PIABA                         AS PBEL_INS_CPNT_DTH_PIABA
       , A.SPBEL_INS_CPNT_DISA_PIABA                        AS PBEL_INS_CPNT_DISA_PIABA
       , A.SPBEL_INS_CPNT_DIAG_PIABA                        AS PBEL_INS_CPNT_DIAG_PIABA
       , A.SPBEL_INS_CPNT_SUROP_PIABA                       AS PBEL_INS_CPNT_SUROP_PIABA
       , A.SPBEL_INS_CPNT_HSPZ_PIABA                        AS PBEL_INS_CPNT_HSPZ_PIABA
       , A.SPBEL_INS_CPNT_PLOS_PIABA                        AS PBEL_INS_CPNT_PLOS_PIABA
       , A.SPBEL_INS_CPNT_OTR_PIABA                         AS PBEL_INS_CPNT_OTR_PIABA
       , A.SPBEL_INS_CPNT_ANTY_DFR_AMT                      AS PBEL_INS_CPNT_ANTY_DFR_AMT
       , A.SPBEL_INS_CPNT_PYEX_PREM_VL                      AS PBEL_INS_CPNT_PYEX_PREM_VL
       , A.SPBEL_INS_CPNT_ACCT_SRDR_RF                      AS PBEL_INS_CPNT_ACCT_SRDR_RF
       , A.SPBEL_INS_CPNT_POHD_DIVD_AMT                     AS PBEL_INS_CPNT_POHD_DIVD_AMT
       , A.SPBEL_IVST_CPNT_EXPI_RF                          AS PBEL_IVST_CPNT_EXPI_RF
       , A.SPBEL_IVST_CPNT_SRDR_RF                          AS PBEL_IVST_CPNT_SRDR_RF
       , A.SPBEL_IVST_CPNT_ANTY_DFR_AMT                     AS PBEL_IVST_CPNT_ANTY_DFR_AMT
       , A.SPBEL_IVST_CPNT_SRVL_DFR_AMT                     AS PBEL_IVST_CPNT_SRVL_DFR_AMT
       , A.SPBEL_IVST_CPNT_MW_WDRW_AMT                      AS PBEL_IVST_CPNT_MW_WDRW_AMT
       , A.SPBEL_IVST_CPNT_ACCT_SRDR_RF                     AS PBEL_IVST_CPNT_ACCT_SRDR_RF
       , A.SPBEL_IVST_CPNT_OTR_AMT                          AS PBEL_IVST_CPNT_OTR_AMT
       , A.SPBEL_DFMT_INCTLN_NW_AMT                         AS PBEL_DFMT_INCTLN_NW_AMT
       , A.SPBEL_DFMT_INCTLN_PRPT_ADMN_EXPN                 AS PBEL_DFMT_INCTLN_PRPT_ADMN_EXPN
       , A.SPBEL_DPS_INCTLN_RFDAMT                          AS PBEL_DPS_INCTLN_RFDAMT
       , A.SPBEL_DPS_INCTLN_INTAMT                          AS PBEL_DPS_INCTLN_INTAMT
       , A.SPBEL_DIR_NBZEXP_INS_COMS                        AS PBEL_DIR_NBZEXP_INS_COMS
       , A.SPBEL_DIR_NBZEXP_INS_OTR_COMS                    AS PBEL_DIR_NBZEXP_INS_OTR_COMS
       , A.SPBEL_DIR_NBZEXP_OTR_COMS                        AS PBEL_DIR_NBZEXP_OTR_COMS
       , A.SPBEL_SERV_EXPN_DIR_MTEXP                        AS PBEL_SERV_EXPN_DIR_MTEXP
       , A.SPBEL_TAX_PBIMP_DIR_MTEXP                        AS PBEL_TAX_PBIMP_DIR_MTEXP
       , A.SPBEL_EDUT_DIR_MTEXP                             AS PBEL_EDUT_DIR_MTEXP
       , A.SPBEL_DPST_PREM_DIR_MTEXP                        AS PBEL_DPST_PREM_DIR_MTEXP
       , A.SPBEL_COLEXP_DIR_MTEXP                           AS PBEL_COLEXP_DIR_MTEXP
       , A.SPBEL_OTR_DIR_MTEXP                              AS PBEL_OTR_DIR_MTEXP
       , A.SPBEL_DIR_LOSDMG_INVT_EXPN                       AS PBEL_DIR_LOSDMG_INVT_EXPN
       , A.SPBEL_PRPT_ADMN_EXPN                             AS PBEL_PRPT_ADMN_EXPN
       , A.SPBEL_IMF_EXPN                                   AS PBEL_IMF_EXPN
       , A.SPCF_BAS_PREM						  			AS PCF_BAS_PREM
       , A.SPCF_AD_PYPRM_VL					  			    AS PCF_AD_PYPRM_VL
       , A.SPCF_INS_CPNT_DTH_PIABA              			AS PCF_INS_CPNT_DTH_PIABA
       , A.SPCF_INS_CPNT_DISA_PIABA             			AS PCF_INS_CPNT_DISA_PIABA
       , A.SPCF_INS_CPNT_DIAG_PIABA             			AS PCF_INS_CPNT_DIAG_PIABA
       , A.SPCF_INS_CPNT_SUROP_PIABA            			AS PCF_INS_CPNT_SUROP_PIABA
       , A.SPCF_INS_CPNT_HSPZ_PIABA             			AS PCF_INS_CPNT_HSPZ_PIABA
       , A.SPCF_INS_CPNT_PLOS_PIABA             			AS PCF_INS_CPNT_PLOS_PIABA
       , A.SPCF_INS_CPNT_OTR_PIABA              			AS PCF_INS_CPNT_OTR_PIABA
       , A.SPCF_INS_CPNT_ANTY_DFR_AMT           			AS PCF_INS_CPNT_ANTY_DFR_AMT
       , A.SPCF_INS_CPNT_PYEX_PREM_VL           			AS PCF_INS_CPNT_PYEX_PREM_VL
       , A.SPCF_INS_CPNT_ACCT_SRDR_RF           			AS PCF_INS_CPNT_ACCT_SRDR_RF
       , A.SPCF_INS_CPNT_POHD_DIVD_AMT          			AS PCF_INS_CPNT_POHD_DIVD_AMT
       , A.SPCF_IVST_CPNT_EXPI_RF               			AS PCF_IVST_CPNT_EXPI_RF
       , A.SPCF_IVST_CPNT_SRDR_RF               			AS PCF_IVST_CPNT_SRDR_RF
       , A.SPCF_IVST_CPNT_ANTY_DFR_AMT          			AS PCF_IVST_CPNT_ANTY_DFR_AMT
       , A.SPCF_IVST_CPNT_SRVL_DFR_AMT          			AS PCF_IVST_CPNT_SRVL_DFR_AMT
       , A.SPCF_IVST_CPNT_MW_WDRW_AMT           			AS PCF_IVST_CPNT_MW_WDRW_AMT
       , A.SPCF_IVST_CPNT_ACCT_SRDR_RF          			AS PCF_IVST_CPNT_ACCT_SRDR_RF
       , A.SPCF_IVST_CPNT_OTR_AMT               			AS PCF_IVST_CPNT_OTR_AMT
       , A.SPCF_DFMT_INCTLN_NW_AMT              			AS PCF_DFMT_INCTLN_NW_AMT
       , A.SPCF_DFMT_INCTLN_PRPT_ADMN_EXPN      			AS PCF_DFMT_INCTLN_PRPT_ADMN_EXPN
       , A.SPCF_DPS_INCTLN_RFDAMT               			AS PCF_DPS_INCTLN_RFDAMT
       , A.SPCF_DPS_INCTLN_INTAMT               			AS PCF_DPS_INCTLN_INTAMT
       , A.SPCF_DIR_NBZEXP_INS_COMS             			AS PCF_DIR_NBZEXP_INS_COMS
       , A.SPCF_DIR_NBZEXP_INS_OTR_COMS         			AS PCF_DIR_NBZEXP_INS_OTR_COMS
       , A.SPCF_DIR_NBZEXP_OTR_COMS             			AS PCF_DIR_NBZEXP_OTR_COMS
       , A.SPCF_SERV_EXPN_DIR_MTEXP             			AS PCF_SERV_EXPN_DIR_MTEXP
       , A.SPCF_TAX_PBIMP_DIR_MTEXP             			AS PCF_TAX_PBIMP_DIR_MTEXP
       , A.SPCF_EDUT_DIR_MTEXP                  			AS PCF_EDUT_DIR_MTEXP
       , A.SPCF_DPST_PREM_DIR_MTEXP             			AS PCF_DPST_PREM_DIR_MTEXP
       , A.SPCF_COLEXP_DIR_MTEXP                			AS PCF_COLEXP_DIR_MTEXP
       , A.SPCF_OTR_DIR_MTEXP                   			AS PCF_OTR_DIR_MTEXP
       , A.SPCF_DIR_LOSDMG_INVT_EXPN            			AS PCF_DIR_LOSDMG_INVT_EXPN
       , A.SPCF_PRPT_ADMN_EXPN                 			    AS PCF_PRPT_ADMN_EXPN
       , A.SPCF_IMF_EXPN                        			AS PCF_IMF_EXPN       
       , A.RA_RATIO                                         AS RA_RATIO
       , A.RA_IDX                                           AS RA_IDX
  FROM
      (SELECT /*+PARALLEL(A 16) SWAP_JOIN_INPUTS(B) PQ_DISTRIBUTE(B NONE BROADCAST) */
           A.*
           , A.BEL_INTAMT_BF * NVL(B.MAX_DC_RATE_VAL,0)         AS BEL_INTAMT
           , A.RA_INTAMT_BF * NVL(B.MAX_DC_RATE_VAL,0)          AS RA_INTAMT
           , A.TVOG_INTAMT_BF * NVL(B.MAX_DC_RATE_VAL,0)        AS TVOG_INTAMT
      FROM  --아래 Select-list의 lag window function은 경과년월별 sorting하여 직전시점의 부채로부터 발생한 당기이자부담분을 계산하기 위함
          (SELECT /*+PARALLEL(A 16) */
               A.*
               , CASE WHEN A.MVMT_SECD ='1010' AND A.APPT_DCRT_SECD ='1' THEN NVL(LAG(A.SINTE_ADINT_TGT_BEL_AMT, 1)                  OVER (PARTITION BY A.IFRS_ACTS_YYMM, A.PLYNO, A.IFRS_WRK_SECD, A.MVMT_SECD, A.INIT_RCGNT_TYP_COD, A.APPT_DCRT_SECD ORDER BY A.PROG_YYMM ASC), 0) ELSE 0 END 
                                                        AS BEL_INTAMT_BF
               , CASE WHEN A.MVMT_SECD ='1010' AND A.APPT_DCRT_SECD ='1' THEN NVL(LAG(A.RA_VAL, 1)                                   OVER (PARTITION BY A.IFRS_ACTS_YYMM, A.PLYNO, A.IFRS_WRK_SECD, A.MVMT_SECD, A.INIT_RCGNT_TYP_COD, A.APPT_DCRT_SECD ORDER BY A.PROG_YYMM ASC), 0) ELSE 0 END 
                                                        AS RA_INTAMT_BF 
               , CASE WHEN A.MVMT_SECD ='1010' AND A.APPT_DCRT_SECD ='1' THEN NVL(LAG(A.SINTE_ADINT_TGT_PBEL_AMT - A.SINTE_ADINT_TGT_BEL_AMT, 1) OVER (PARTITION BY A.IFRS_ACTS_YYMM, A.PLYNO, A.IFRS_WRK_SECD, A.MVMT_SECD, A.INIT_RCGNT_TYP_COD, A.APPT_DCRT_SECD ORDER BY A.PROG_YYMM ASC), 0) ELSE 0 END 
                                                        AS TVOG_INTAMT_BF
               , CASE WHEN A.MVMT_SECD ='1000' THEN TO_CHAR(MAX(A.GOC_TYP_COD_CALC) OVER(PARTITION BY A.IFRS_ACTS_YYMM, A.PLYNO, A.IFRS_WRK_SECD, A.MVMT_SECD, A.INIT_RCGNT_TYP_COD, A.APPT_DCRT_SECD))||A.TERM_SECD
                      ELSE A.GOC_TYP_COD  
                      END                               AS GOC_TYP_COD_FIN       
          FROM
              (SELECT /*+USE_HASH(A B) PARALLEL(A 16) PARALLEL(B 16) OPT_PARAM('_OPTIMIZER_ADAPTIVE_PLANS' 'FALSE') 
                        SWAP_JOIN_INPUTS(B) LEADING(B A) NO_PX_JOIN_FILTER PQ_DISTRIBUTE(B NONE BROADCAST)*/
                   A.IFRS_ACTS_YYMM                         AS IFRS_ACTS_YYMM                                            
                   , A.VALU_YYMM                            AS VALU_YYMM                                                       
                   , A.PLYNO                                AS PLYNO                              
                   , A.MPRD_PRDCD                           AS MPRD_PRDCD                                      
                   , A.IFRS_WRK_SECD                        AS IFRS_WRK_SECD                                                   
                   , A.MVMT_SECD                            AS MVMT_SECD                                        
                   , A.PROG_YYMM                            AS PROG_YYMM                                                        
                   , A.INIT_RCGNT_TYP_COD                   AS INIT_RCGNT_TYP_COD                       
                   , A.APPT_DCRT_SECD                       AS APPT_DCRT_SECD                  
                   , A.TMP_PK                               AS TMP_PK                                   
                   , A.LFDE_MMRP_COD                        AS LFDE_MMRP_COD                     
                   , A.PF_SECD                              AS PF_SECD                           
                   , A.SAME_GRP_TYP_COD                     AS SAME_GRP_TYP_COD                 
                   , A.GOC_TYP_COD                          AS GOC_TYP_COD                       
                   , A.VALU_MDL_NAM                         AS VALU_MDL_NAM                                     
                   , A.MIN_INIT_RCGNT_DTM                   AS INIT_RCGNT_DTM                   
                   , A.MAX_ELMN_DTM                         AS ELMN_DTM                                        
                   , A.SBEL_BAS_PREM                        AS SBEL_BAS_PREM                      
                   , A.SBEL_AD_PYPRM_VL                     AS SBEL_AD_PYPRM_VL                 
                   , A.SBEL_INS_CPNT_DTH_PIABA              AS SBEL_INS_CPNT_DTH_PIABA          
                   , A.SBEL_INS_CPNT_DISA_PIABA             AS SBEL_INS_CPNT_DISA_PIABA         
                   , A.SBEL_INS_CPNT_DIAG_PIABA             AS SBEL_INS_CPNT_DIAG_PIABA         
                   , A.SBEL_INS_CPNT_SUROP_PIABA            AS SBEL_INS_CPNT_SUROP_PIABA        
                   , A.SBEL_INS_CPNT_HSPZ_PIABA             AS SBEL_INS_CPNT_HSPZ_PIABA         
                   , A.SBEL_INS_CPNT_PLOS_PIABA             AS SBEL_INS_CPNT_PLOS_PIABA         
                   , A.SBEL_INS_CPNT_OTR_PIABA              AS SBEL_INS_CPNT_OTR_PIABA          
                   , A.SBEL_INS_CPNT_ANTY_DFR_AMT           AS SBEL_INS_CPNT_ANTY_DFR_AMT       
                   , A.SBEL_INS_CPNT_PYEX_PREM_VL           AS SBEL_INS_CPNT_PYEX_PREM_VL       
                   , A.SBEL_INS_CPNT_ACCT_SRDR_RF           AS SBEL_INS_CPNT_ACCT_SRDR_RF       
                   , A.SBEL_INS_CPNT_POHD_DIVD_AMT          AS SBEL_INS_CPNT_POHD_DIVD_AMT      
                   , A.SBEL_IVST_CPNT_EXPI_RF               AS SBEL_IVST_CPNT_EXPI_RF           
                   , A.SBEL_IVST_CPNT_SRDR_RF               AS SBEL_IVST_CPNT_SRDR_RF           
                   , A.SBEL_IVST_CPNT_ANTY_DFR_AMT          AS SBEL_IVST_CPNT_ANTY_DFR_AMT      
                   , A.SBEL_IVST_CPNT_SRVL_DFR_AMT          AS SBEL_IVST_CPNT_SRVL_DFR_AMT      
                   , A.SBEL_IVST_CPNT_MW_WDRW_AMT           AS SBEL_IVST_CPNT_MW_WDRW_AMT       
                   , A.SBEL_IVST_CPNT_ACCT_SRDR_RF          AS SBEL_IVST_CPNT_ACCT_SRDR_RF      
                   , A.SBEL_IVST_CPNT_OTR_AMT               AS SBEL_IVST_CPNT_OTR_AMT           
                   , A.SBEL_DFMT_INCTLN_NW_AMT              AS SBEL_DFMT_INCTLN_NW_AMT          
                   , A.SBEL_DFMT_INCTLN_PRPT_ADMN_EXPN      AS SBEL_DFMT_INCTLN_PRPT_ADMN_EXPN       
                   , A.SBEL_DPS_INCTLN_RFDAMT               AS SBEL_DPS_INCTLN_RFDAMT           
                   , A.SBEL_DPS_INCTLN_INTAMT               AS SBEL_DPS_INCTLN_INTAMT           
                   , A.SBEL_DIR_NBZEXP_INS_COMS             AS SBEL_DIR_NBZEXP_INS_COMS         
                   , A.SBEL_DIR_NBZEXP_INS_OTR_COMS         AS SBEL_DIR_NBZEXP_INS_OTR_COMS     
                   , A.SBEL_DIR_NBZEXP_OTR_COMS             AS SBEL_DIR_NBZEXP_OTR_COMS         
                   , A.SBEL_SERV_EXPN_DIR_MTEXP             AS SBEL_SERV_EXPN_DIR_MTEXP         
                   , A.SBEL_TAX_PBIMP_DIR_MTEXP             AS SBEL_TAX_PBIMP_DIR_MTEXP         
                   , A.SBEL_EDUT_DIR_MTEXP                  AS SBEL_EDUT_DIR_MTEXP              
                   , A.SBEL_DPST_PREM_DIR_MTEXP             AS SBEL_DPST_PREM_DIR_MTEXP         
                   , A.SBEL_COLEXP_DIR_MTEXP                AS SBEL_COLEXP_DIR_MTEXP            
                   , A.SBEL_OTR_DIR_MTEXP                   AS SBEL_OTR_DIR_MTEXP               
                   , A.SBEL_DIR_LOSDMG_INVT_EXPN            AS SBEL_DIR_LOSDMG_INVT_EXPN        
                   , A.SBEL_PRPT_ADMN_EXPN                  AS SBEL_PRPT_ADMN_EXPN              
                   , A.SBEL_IMF_EXPN                        AS SBEL_IMF_EXPN                  										   
                   , A.SINS_CPNT_DVP_BEL_AMT                AS SINS_CPNT_DVP_BEL_AMT                  
                   , A.SIVST_CPNT_DVP_BEL_AMT               AS SIVST_CPNT_DVP_BEL_AMT                
                   , A.SINTE_ADINT_TGT_BEL_AMT              AS SINTE_ADINT_TGT_BEL_AMT                                
                   , A.SINS_CPNT_STCST_BEL_AMT  - A.SINS_CPNT_DVP_BEL_AMT                   AS SINS_CPNT_TVOG_AMT                           
                   , A.SIVST_CPNT_STCST_BEL_AMT - A.SIVST_CPNT_DVP_BEL_AMT                  AS SIVST_CPNT_TVOG_AMT 
                   , A.SINTE_ADINT_TGT_PBEL_AMT             AS SINTE_ADINT_TGT_PBEL_AMT
                   , A.SCF_BAS_PREM                         AS SCF_BAS_PREM                     
                   , A.SCF_AD_PYPRM_VL                      AS SCF_AD_PYPRM_VL                  
                   , A.SCF_INS_CPNT_DTH_PIABA               AS SCF_INS_CPNT_DTH_PIABA           
                   , A.SCF_INS_CPNT_DISA_PIABA              AS SCF_INS_CPNT_DISA_PIABA          
                   , A.SCF_INS_CPNT_DIAG_PIABA              AS SCF_INS_CPNT_DIAG_PIABA          
                   , A.SCF_INS_CPNT_SUROP_PIABA             AS SCF_INS_CPNT_SUROP_PIABA         
                   , A.SCF_INS_CPNT_HSPZ_PIABA              AS SCF_INS_CPNT_HSPZ_PIABA          
                   , A.SCF_INS_CPNT_PLOS_PIABA              AS SCF_INS_CPNT_PLOS_PIABA          
                   , A.SCF_INS_CPNT_OTR_PIABA               AS SCF_INS_CPNT_OTR_PIABA           
                   , A.SCF_INS_CPNT_ANTY_DFR_AMT            AS SCF_INS_CPNT_ANTY_DFR_AMT        
                   , A.SCF_INS_CPNT_PYEX_PREM_VL            AS SCF_INS_CPNT_PYEX_PREM_VL        
                   , A.SCF_INS_CPNT_ACCT_SRDR_RF            AS SCF_INS_CPNT_ACCT_SRDR_RF        
                   , A.SCF_INS_CPNT_POHD_DIVD_AMT           AS SCF_INS_CPNT_POHD_DIVD_AMT       
                   , A.SCF_IVST_CPNT_EXPI_RF                AS SCF_IVST_CPNT_EXPI_RF            
                   , A.SCF_IVST_CPNT_SRDR_RF                AS SCF_IVST_CPNT_SRDR_RF            
                   , A.SCF_IVST_CPNT_ANTY_DFR_AMT           AS SCF_IVST_CPNT_ANTY_DFR_AMT       
                   , A.SCF_IVST_CPNT_SRVL_DFR_AMT           AS SCF_IVST_CPNT_SRVL_DFR_AMT       
                   , A.SCF_IVST_CPNT_MW_WDRW_AMT            AS SCF_IVST_CPNT_MW_WDRW_AMT        
                   , A.SCF_IVST_CPNT_ACCT_SRDR_RF           AS SCF_IVST_CPNT_ACCT_SRDR_RF       
                   , A.SCF_IVST_CPNT_OTR_AMT                AS SCF_IVST_CPNT_OTR_AMT            
                   , A.SCF_DFMT_INCTLN_NW_AMT               AS SCF_DFMT_INCTLN_NW_AMT           
                   , A.SCF_DFMT_INCTLN_PRPT_ADMN_EXPN       AS SCF_DFMT_INCTLN_PRPT_ADMN_EXPN   
                   , A.SCF_DPS_INCTLN_RFDAMT                AS SCF_DPS_INCTLN_RFDAMT            
                   , A.SCF_DPS_INCTLN_INTAMT                AS SCF_DPS_INCTLN_INTAMT            
                   , A.SCF_DIR_NBZEXP_INS_COMS              AS SCF_DIR_NBZEXP_INS_COMS          
                   , A.SCF_DIR_NBZEXP_INS_OTR_COMS          AS SCF_DIR_NBZEXP_INS_OTR_COMS      
                   , A.SCF_DIR_NBZEXP_OTR_COMS              AS SCF_DIR_NBZEXP_OTR_COMS          
                   , A.SCF_SERV_EXPN_DIR_MTEXP              AS SCF_SERV_EXPN_DIR_MTEXP          
                   , A.SCF_TAX_PBIMP_DIR_MTEXP              AS SCF_TAX_PBIMP_DIR_MTEXP          
                   , A.SCF_EDUT_DIR_MTEXP                   AS SCF_EDUT_DIR_MTEXP               
                   , A.SCF_DPST_PREM_DIR_MTEXP              AS SCF_DPST_PREM_DIR_MTEXP          
                   , A.SCF_COLEXP_DIR_MTEXP                 AS SCF_COLEXP_DIR_MTEXP             
                   , A.SCF_OTR_DIR_MTEXP                    AS SCF_OTR_DIR_MTEXP                
                   , A.SCF_DIR_LOSDMG_INVT_EXPN             AS SCF_DIR_LOSDMG_INVT_EXPN         
                   , A.SCF_PRPT_ADMN_EXPN                   AS SCF_PRPT_ADMN_EXPN              
                   , A.SCF_IMF_EXPN                         AS SCF_IMF_EXPN                     
                   , A.SPBEL_BAS_PREM						AS SPBEL_BAS_PREM
                   , A.SPBEL_AD_PYPRM_VL                    AS SPBEL_AD_PYPRM_VL
                   , A.SPBEL_INS_CPNT_DTH_PIABA             AS SPBEL_INS_CPNT_DTH_PIABA
                   , A.SPBEL_INS_CPNT_DISA_PIABA            AS SPBEL_INS_CPNT_DISA_PIABA
                   , A.SPBEL_INS_CPNT_DIAG_PIABA            AS SPBEL_INS_CPNT_DIAG_PIABA
                   , A.SPBEL_INS_CPNT_SUROP_PIABA           AS SPBEL_INS_CPNT_SUROP_PIABA
                   , A.SPBEL_INS_CPNT_HSPZ_PIABA            AS SPBEL_INS_CPNT_HSPZ_PIABA
                   , A.SPBEL_INS_CPNT_PLOS_PIABA            AS SPBEL_INS_CPNT_PLOS_PIABA
                   , A.SPBEL_INS_CPNT_OTR_PIABA             AS SPBEL_INS_CPNT_OTR_PIABA
                   , A.SPBEL_INS_CPNT_ANTY_DFR_AMT          AS SPBEL_INS_CPNT_ANTY_DFR_AMT
                   , A.SPBEL_INS_CPNT_PYEX_PREM_VL          AS SPBEL_INS_CPNT_PYEX_PREM_VL
                   , A.SPBEL_INS_CPNT_ACCT_SRDR_RF          AS SPBEL_INS_CPNT_ACCT_SRDR_RF
                   , A.SPBEL_INS_CPNT_POHD_DIVD_AMT         AS SPBEL_INS_CPNT_POHD_DIVD_AMT
                   , A.SPBEL_IVST_CPNT_EXPI_RF              AS SPBEL_IVST_CPNT_EXPI_RF
                   , A.SPBEL_IVST_CPNT_SRDR_RF              AS SPBEL_IVST_CPNT_SRDR_RF
                   , A.SPBEL_IVST_CPNT_ANTY_DFR_AMT         AS SPBEL_IVST_CPNT_ANTY_DFR_AMT
                   , A.SPBEL_IVST_CPNT_SRVL_DFR_AMT         AS SPBEL_IVST_CPNT_SRVL_DFR_AMT
                   , A.SPBEL_IVST_CPNT_MW_WDRW_AMT          AS SPBEL_IVST_CPNT_MW_WDRW_AMT
                   , A.SPBEL_IVST_CPNT_ACCT_SRDR_RF         AS SPBEL_IVST_CPNT_ACCT_SRDR_RF
                   , A.SPBEL_IVST_CPNT_OTR_AMT              AS SPBEL_IVST_CPNT_OTR_AMT
                   , A.SPBEL_DFMT_INCTLN_NW_AMT             AS SPBEL_DFMT_INCTLN_NW_AMT
                   , A.SPBEL_DFMT_INCTLN_PRPT_ADMN_EXPN     AS SPBEL_DFMT_INCTLN_PRPT_ADMN_EXPN
                   , A.SPBEL_DPS_INCTLN_RFDAMT              AS SPBEL_DPS_INCTLN_RFDAMT
                   , A.SPBEL_DPS_INCTLN_INTAMT              AS SPBEL_DPS_INCTLN_INTAMT
                   , A.SPBEL_DIR_NBZEXP_INS_COMS            AS SPBEL_DIR_NBZEXP_INS_COMS
                   , A.SPBEL_DIR_NBZEXP_INS_OTR_COMS        AS SPBEL_DIR_NBZEXP_INS_OTR_COMS
                   , A.SPBEL_DIR_NBZEXP_OTR_COMS            AS SPBEL_DIR_NBZEXP_OTR_COMS
                   , A.SPBEL_SERV_EXPN_DIR_MTEXP            AS SPBEL_SERV_EXPN_DIR_MTEXP
                   , A.SPBEL_TAX_PBIMP_DIR_MTEXP            AS SPBEL_TAX_PBIMP_DIR_MTEXP
                   , A.SPBEL_EDUT_DIR_MTEXP                 AS SPBEL_EDUT_DIR_MTEXP
                   , A.SPBEL_DPST_PREM_DIR_MTEXP            AS SPBEL_DPST_PREM_DIR_MTEXP
                   , A.SPBEL_COLEXP_DIR_MTEXP               AS SPBEL_COLEXP_DIR_MTEXP
                   , A.SPBEL_OTR_DIR_MTEXP                  AS SPBEL_OTR_DIR_MTEXP
                   , A.SPBEL_DIR_LOSDMG_INVT_EXPN           AS SPBEL_DIR_LOSDMG_INVT_EXPN
                   , A.SPBEL_PRPT_ADMN_EXPN                 AS SPBEL_PRPT_ADMN_EXPN
                   , A.SPBEL_IMF_EXPN                       AS SPBEL_IMF_EXPN
                   , A.SPCF_BAS_PREM						AS SPCF_BAS_PREM
                   , A.SPCF_AD_PYPRM_VL					    AS SPCF_AD_PYPRM_VL
                   , A.SPCF_INS_CPNT_DTH_PIABA              AS SPCF_INS_CPNT_DTH_PIABA
                   , A.SPCF_INS_CPNT_DISA_PIABA             AS SPCF_INS_CPNT_DISA_PIABA
                   , A.SPCF_INS_CPNT_DIAG_PIABA             AS SPCF_INS_CPNT_DIAG_PIABA
                   , A.SPCF_INS_CPNT_SUROP_PIABA            AS SPCF_INS_CPNT_SUROP_PIABA
                   , A.SPCF_INS_CPNT_HSPZ_PIABA             AS SPCF_INS_CPNT_HSPZ_PIABA
                   , A.SPCF_INS_CPNT_PLOS_PIABA             AS SPCF_INS_CPNT_PLOS_PIABA
                   , A.SPCF_INS_CPNT_OTR_PIABA              AS SPCF_INS_CPNT_OTR_PIABA
                   , A.SPCF_INS_CPNT_ANTY_DFR_AMT           AS SPCF_INS_CPNT_ANTY_DFR_AMT
                   , A.SPCF_INS_CPNT_PYEX_PREM_VL           AS SPCF_INS_CPNT_PYEX_PREM_VL
                   , A.SPCF_INS_CPNT_ACCT_SRDR_RF           AS SPCF_INS_CPNT_ACCT_SRDR_RF
                   , A.SPCF_INS_CPNT_POHD_DIVD_AMT          AS SPCF_INS_CPNT_POHD_DIVD_AMT
                   , A.SPCF_IVST_CPNT_EXPI_RF               AS SPCF_IVST_CPNT_EXPI_RF
                   , A.SPCF_IVST_CPNT_SRDR_RF               AS SPCF_IVST_CPNT_SRDR_RF
                   , A.SPCF_IVST_CPNT_ANTY_DFR_AMT          AS SPCF_IVST_CPNT_ANTY_DFR_AMT
                   , A.SPCF_IVST_CPNT_SRVL_DFR_AMT          AS SPCF_IVST_CPNT_SRVL_DFR_AMT
                   , A.SPCF_IVST_CPNT_MW_WDRW_AMT           AS SPCF_IVST_CPNT_MW_WDRW_AMT
                   , A.SPCF_IVST_CPNT_ACCT_SRDR_RF          AS SPCF_IVST_CPNT_ACCT_SRDR_RF
                   , A.SPCF_IVST_CPNT_OTR_AMT               AS SPCF_IVST_CPNT_OTR_AMT
                   , A.SPCF_DFMT_INCTLN_NW_AMT              AS SPCF_DFMT_INCTLN_NW_AMT
                   , A.SPCF_DFMT_INCTLN_PRPT_ADMN_EXPN      AS SPCF_DFMT_INCTLN_PRPT_ADMN_EXPN
                   , A.SPCF_DPS_INCTLN_RFDAMT               AS SPCF_DPS_INCTLN_RFDAMT
                   , A.SPCF_DPS_INCTLN_INTAMT               AS SPCF_DPS_INCTLN_INTAMT
                   , A.SPCF_DIR_NBZEXP_INS_COMS             AS SPCF_DIR_NBZEXP_INS_COMS
                   , A.SPCF_DIR_NBZEXP_INS_OTR_COMS         AS SPCF_DIR_NBZEXP_INS_OTR_COMS
                   , A.SPCF_DIR_NBZEXP_OTR_COMS             AS SPCF_DIR_NBZEXP_OTR_COMS
                   , A.SPCF_SERV_EXPN_DIR_MTEXP             AS SPCF_SERV_EXPN_DIR_MTEXP
                   , A.SPCF_TAX_PBIMP_DIR_MTEXP             AS SPCF_TAX_PBIMP_DIR_MTEXP
                   , A.SPCF_EDUT_DIR_MTEXP                  AS SPCF_EDUT_DIR_MTEXP
                   , A.SPCF_DPST_PREM_DIR_MTEXP             AS SPCF_DPST_PREM_DIR_MTEXP
                   , A.SPCF_COLEXP_DIR_MTEXP                AS SPCF_COLEXP_DIR_MTEXP
                   , A.SPCF_OTR_DIR_MTEXP                   AS SPCF_OTR_DIR_MTEXP
                   , A.SPCF_DIR_LOSDMG_INVT_EXPN            AS SPCF_DIR_LOSDMG_INVT_EXPN
                   , A.SPCF_PRPT_ADMN_EXPN                  AS SPCF_PRPT_ADMN_EXPN
                   , A.SPCF_IMF_EXPN                        AS SPCF_IMF_EXPN
                   , ROW_NUMBER() OVER (PARTITION BY A.IFRS_ACTS_YYMM, A.VALU_YYMM, A.IFRS_WRK_SECD, A.MVMT_SECD, A.PROG_YYMM, A.APPT_DCRT_SECD ORDER BY A.IFRS_ACTS_YYMM, A.VALU_YYMM, A.IFRS_WRK_SECD, A.MVMT_SECD, A.PROG_YYMM, A.APPT_DCRT_SECD) 
                                                            AS RA_IDX
                   , NVL((A.R14 + A.R15	+ A.R1617 + A.R1819 + A.R20) * (CASE WHEN A.MVMT_SECD ='1000' THEN B.RA_SHAR_RTO 
                                                                             ELSE B.TOT_POL_RA_SUM / DECODE(SUM(A.R14 + A.R15	+ A.R1617 + A.R1819 + A.R20) OVER(PARTITION BY A.IFRS_ACTS_YYMM, A.VALU_YYMM, A.IFRS_WRK_SECD, A.MVMT_SECD, A.PROG_YYMM, A.APPT_DCRT_SECD), 0, NULL,
                                                                                                            SUM(A.R14 + A.R15	+ A.R1617 + A.R1819 + A.R20) OVER(PARTITION BY A.IFRS_ACTS_YYMM, A.VALU_YYMM, A.IFRS_WRK_SECD, A.MVMT_SECD, A.PROG_YYMM, A.APPT_DCRT_SECD)) END), 0) 
                                                            AS RA_VAL       
                   , NVL(B.TOT_POL_RA_SUM / DECODE(SUM(A.R14 + A.R15	+ A.R1617 + A.R1819 + A.R20) OVER(PARTITION BY A.IFRS_ACTS_YYMM, A.VALU_YYMM, A.IFRS_WRK_SECD, A.MVMT_SECD, A.PROG_YYMM, A.APPT_DCRT_SECD), 0, NULL,
                                                   SUM(A.R14 + A.R15	+ A.R1617 + A.R1819 + A.R20) OVER(PARTITION BY A.IFRS_ACTS_YYMM, A.VALU_YYMM, A.IFRS_WRK_SECD, A.MVMT_SECD, A.PROG_YYMM, A.APPT_DCRT_SECD)), 0)  
                                                            AS RA_RATIO                                                                
                   , CASE WHEN A.MVMT_SECD = '1000' AND A.PROG_YYMM = TO_CHAR(ADD_MONTHS(A.MIN_INIT_RCGNT_DTM, -1), 'YYYYMM')
                          THEN CASE WHEN ((A.R14 + A.R15	+ A.R1617 + A.R1819 + A.R20) * B.RA_SHAR_RTO) * 2 < -(A.SINS_CPNT_STCST_BEL_AMT + A.SIVST_CPNT_STCST_BEL_AMT) THEN '1'
                                    ELSE CASE WHEN ((A.R14 + A.R15	+ A.R1617 + A.R1819 + A.R20) * B.RA_SHAR_RTO) * 1 < -(A.SINS_CPNT_STCST_BEL_AMT + A.SIVST_CPNT_STCST_BEL_AMT) THEN '2'
                                              ELSE '3' 
                                              END
                                    END                               
                          END                               AS GOC_TYP_COD_CALC                               
                   , A.TERM_SECD                            AS TERM_SECD
              FROM 
                  (SELECT /*+PARALLEL(A 16) */  
                        A.*
                        , CASE WHEN 120 < MONTHS_BETWEEN(A.MAX_ELMN_DTM, CASE WHEN A.MVMT_SECD ='9999' THEN LAST_DAY(TO_DATE(A.IFRS_ACTS_YYMM||'01')) ELSE A.MIN_INIT_RCGNT_DTM END) THEN 'L' ELSE 'S' END AS TERM_SECD
                        , NVL(CASE WHEN A.M14 - A.M00 < 0 THEN 0 ELSE A.M14 - A.M00 END, 0)                         AS R14 
                        , NVL(CASE WHEN A.M15 - A.M00 < 0 THEN 0 ELSE A.M15 - A.M00 END, 0)                         AS R15
                        , NVL((CASE WHEN A.M16 - A.M00 < 0 THEN 0 ELSE A.M16 - A.M00 END), 0) + NVL((CASE WHEN A.M17 - A.M00 < 0 THEN 0 ELSE A.M17 - A.M00 END), 0) 
                                                                                                                    AS R1617
                        , GREATEST(NVL(CASE WHEN A.M18 - A.M00 < A.M19 - A.M00 THEN A.M19 - A.M00 ELSE A.M18 - A.M00 END, 0), 0) AS R1819
                        , NVL(CASE WHEN A.M20 - A.M00 < 0 THEN 0 ELSE A.M20 - A.M00 END, 0)                         AS R20
                  FROM 
                      (SELECT /*+FULL(A) PARALLEL(A 16) */ 
                            A.IFRS_ACTS_YYMM
                            , A.VALU_YYMM
                            , A.PLYNO
                            , A.MPRD_PRDCD
                            , A.IFRS_WRK_SECD
                            , A.MVMT_SECD
                            , A.PROG_YYMM
                            , A.INIT_RCGNT_TYP_COD
                            , A.APPT_DCRT_SECD
                            , '0'									                                                      AS TMP_PK
                            , A.LFDE_MMRP_COD
                            , A.PF_SECD
                            , A.SAME_GRP_TYP_COD
                            , A.GOC_TYP_COD
                            , A.VALU_MDL_NAM           
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.BEL_BAS_PREM END)                                    AS SBEL_BAS_PREM                  
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.BEL_AD_PYPRM_VL END)                                 AS SBEL_AD_PYPRM_VL               
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.BEL_INS_CPNT_DTH_PIABA END)                          AS SBEL_INS_CPNT_DTH_PIABA        
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.BEL_INS_CPNT_DISA_PIABA END)                         AS SBEL_INS_CPNT_DISA_PIABA       
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.BEL_INS_CPNT_DIAG_PIABA END)                         AS SBEL_INS_CPNT_DIAG_PIABA       
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.BEL_INS_CPNT_SUROP_PIABA END)                        AS SBEL_INS_CPNT_SUROP_PIABA      
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.BEL_INS_CPNT_HSPZ_PIABA END)                         AS SBEL_INS_CPNT_HSPZ_PIABA       
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.BEL_INS_CPNT_PLOS_PIABA END)                         AS SBEL_INS_CPNT_PLOS_PIABA       
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.BEL_INS_CPNT_OTR_PIABA END)                          AS SBEL_INS_CPNT_OTR_PIABA        
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.BEL_INS_CPNT_ANTY_DFR_AMT END)                       AS SBEL_INS_CPNT_ANTY_DFR_AMT     
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.BEL_INS_CPNT_PYEX_PREM_VL END)                       AS SBEL_INS_CPNT_PYEX_PREM_VL     
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.BEL_INS_CPNT_ACCT_SRDR_RF END)                       AS SBEL_INS_CPNT_ACCT_SRDR_RF     
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.BEL_INS_CPNT_POHD_DIVD_AMT END)                      AS SBEL_INS_CPNT_POHD_DIVD_AMT    
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.BEL_IVST_CPNT_EXPI_RF END)                           AS SBEL_IVST_CPNT_EXPI_RF         
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.BEL_IVST_CPNT_SRDR_RF END)                           AS SBEL_IVST_CPNT_SRDR_RF         
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.BEL_IVST_CPNT_ANTY_DFR_AMT END)                      AS SBEL_IVST_CPNT_ANTY_DFR_AMT    
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.BEL_IVST_CPNT_SRVL_DFR_AMT END)                      AS SBEL_IVST_CPNT_SRVL_DFR_AMT    
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.BEL_IVST_CPNT_MW_WDRW_AMT END)                       AS SBEL_IVST_CPNT_MW_WDRW_AMT     
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.BEL_IVST_CPNT_ACCT_SRDR_RF END)                      AS SBEL_IVST_CPNT_ACCT_SRDR_RF    
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.BEL_IVST_CPNT_OTR_AMT END)                           AS SBEL_IVST_CPNT_OTR_AMT         
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.BEL_DFMT_INCTLN_NW_AMT END)                          AS SBEL_DFMT_INCTLN_NW_AMT        
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.BEL_DFMT_INCTLN_PRPT_ADMN_EXPN END)                  AS SBEL_DFMT_INCTLN_PRPT_ADMN_EXPN     
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.BEL_DPS_INCTLN_RFDAMT END)                           AS SBEL_DPS_INCTLN_RFDAMT         
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.BEL_DPS_INCTLN_INTAMT END)                           AS SBEL_DPS_INCTLN_INTAMT         
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.BEL_DIR_NBZEXP_INS_COMS END)                         AS SBEL_DIR_NBZEXP_INS_COMS     
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.BEL_DIR_NBZEXP_INS_OTR_COMS END)                     AS SBEL_DIR_NBZEXP_INS_OTR_COMS 
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.BEL_DIR_NBZEXP_OTR_COMS END)                         AS SBEL_DIR_NBZEXP_OTR_COMS     
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.BEL_SERV_EXPN_DIR_MTEXP END)                         AS SBEL_SERV_EXPN_DIR_MTEXP     
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.BEL_TAX_PBIMP_DIR_MTEXP END)                         AS SBEL_TAX_PBIMP_DIR_MTEXP     
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.BEL_EDUT_DIR_MTEXP END)                              AS SBEL_EDUT_DIR_MTEXP          
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.BEL_DPST_PREM_DIR_MTEXP END)                         AS SBEL_DPST_PREM_DIR_MTEXP     
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.BEL_COLEXP_DIR_MTEXP END)                            AS SBEL_COLEXP_DIR_MTEXP        
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.BEL_OTR_DIR_MTEXP END)                               AS SBEL_OTR_DIR_MTEXP           
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.BEL_DIR_LOSDMG_INVT_EXPN END)                        AS SBEL_DIR_LOSDMG_INVT_EXPN    
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.BEL_PRPT_ADMN_EXPN END)                              AS SBEL_PRPT_ADMN_EXPN          
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.BEL_IMF_EXPN END)                                    AS SBEL_IMF_EXPN                
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.INS_CPNT_DVP_BEL_AMT END)                            AS SINS_CPNT_DVP_BEL_AMT 
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.IVST_CPNT_DVP_BEL_AMT END)                           AS SIVST_CPNT_DVP_BEL_AMT 
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.INTE_ADINT_TGT_BEL_AMT END)                          AS SINTE_ADINT_TGT_BEL_AMT 
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.INTE_ADINT_TGT_BEL_AMT END)                          AS BEL_INTAMT0
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.INS_CPNT_STCST_BEL_AMT END)                          AS SINS_CPNT_STCST_BEL_AMT 
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.IVST_CPNT_STCST_BEL_AMT END)                         AS SIVST_CPNT_STCST_BEL_AMT 
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.INTE_ADINT_TGT_PBEL_AMT END)                         AS SINTE_ADINT_TGT_PBEL_AMT 
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.CF_BAS_PREM END)                                     AS SCF_BAS_PREM                    
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.CF_AD_PYPRM_VL END)                                  AS SCF_AD_PYPRM_VL                 
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.CF_INS_CPNT_DTH_PIABA END)                           AS SCF_INS_CPNT_DTH_PIABA          
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.CF_INS_CPNT_DISA_PIABA END)                          AS SCF_INS_CPNT_DISA_PIABA         
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.CF_INS_CPNT_DIAG_PIABA END)                          AS SCF_INS_CPNT_DIAG_PIABA         
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.CF_INS_CPNT_SUROP_PIABA END)                         AS SCF_INS_CPNT_SUROP_PIABA        
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.CF_INS_CPNT_HSPZ_PIABA END)                          AS SCF_INS_CPNT_HSPZ_PIABA         
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.CF_INS_CPNT_PLOS_PIABA END)                          AS SCF_INS_CPNT_PLOS_PIABA         
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.CF_INS_CPNT_OTR_PIABA END)                           AS SCF_INS_CPNT_OTR_PIABA          
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.CF_INS_CPNT_ANTY_DFR_AMT END)                        AS SCF_INS_CPNT_ANTY_DFR_AMT       
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.CF_INS_CPNT_PYEX_PREM_VL END)                        AS SCF_INS_CPNT_PYEX_PREM_VL       
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.CF_INS_CPNT_ACCT_SRDR_RF END)                        AS SCF_INS_CPNT_ACCT_SRDR_RF       
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.CF_INS_CPNT_POHD_DIVD_AMT END)                       AS SCF_INS_CPNT_POHD_DIVD_AMT      
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.CF_IVST_CPNT_EXPI_RF END)                            AS SCF_IVST_CPNT_EXPI_RF           
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.CF_IVST_CPNT_SRDR_RF END)                            AS SCF_IVST_CPNT_SRDR_RF           
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.CF_IVST_CPNT_ANTY_DFR_AMT END)                       AS SCF_IVST_CPNT_ANTY_DFR_AMT      
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.CF_IVST_CPNT_SRVL_DFR_AMT END)                       AS SCF_IVST_CPNT_SRVL_DFR_AMT      
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.CF_IVST_CPNT_MW_WDRW_AMT END)                        AS SCF_IVST_CPNT_MW_WDRW_AMT       
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.CF_IVST_CPNT_ACCT_SRDR_RF END)                       AS SCF_IVST_CPNT_ACCT_SRDR_RF      
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.CF_IVST_CPNT_OTR_AMT END)                            AS SCF_IVST_CPNT_OTR_AMT           
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.CF_DFMT_INCTLN_NW_AMT END)                           AS SCF_DFMT_INCTLN_NW_AMT          
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.CF_DFMT_INCTLN_PRPT_ADMN_EXPN END)                   AS SCF_DFMT_INCTLN_PRPT_ADMN_EXPN  
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.CF_DPS_INCTLN_RFDAMT END)                            AS SCF_DPS_INCTLN_RFDAMT           
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.CF_DPS_INCTLN_INTAMT END)                            AS SCF_DPS_INCTLN_INTAMT           
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.CF_DIR_NBZEXP_INS_COMS END)                          AS SCF_DIR_NBZEXP_INS_COMS         
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.CF_DIR_NBZEXP_INS_OTR_COMS END)                      AS SCF_DIR_NBZEXP_INS_OTR_COMS     
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.CF_DIR_NBZEXP_OTR_COMS END)                          AS SCF_DIR_NBZEXP_OTR_COMS         
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.CF_SERV_EXPN_DIR_MTEXP END)                          AS SCF_SERV_EXPN_DIR_MTEXP         
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.CF_TAX_PBIMP_DIR_MTEXP END)                          AS SCF_TAX_PBIMP_DIR_MTEXP         
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.CF_EDUT_DIR_MTEXP END)                               AS SCF_EDUT_DIR_MTEXP              
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.CF_DPST_PREM_DIR_MTEXP END)                          AS SCF_DPST_PREM_DIR_MTEXP         
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.CF_COLEXP_DIR_MTEXP END)                             AS SCF_COLEXP_DIR_MTEXP            
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.CF_OTR_DIR_MTEXP END)                                AS SCF_OTR_DIR_MTEXP               
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.CF_DIR_LOSDMG_INVT_EXPN END)                         AS SCF_DIR_LOSDMG_INVT_EXPN        
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.CF_PRPT_ADMN_EXPN END)                               AS SCF_PRPT_ADMN_EXPN             
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.CF_IMF_EXPN END)                                     AS SCF_IMF_EXPN                    
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PBEL_BAS_PREM END)				                      AS SPBEL_BAS_PREM
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PBEL_AD_PYPRM_VL END)                                AS SPBEL_AD_PYPRM_VL
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PBEL_INS_CPNT_DTH_PIABA END)                         AS SPBEL_INS_CPNT_DTH_PIABA
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PBEL_INS_CPNT_DISA_PIABA END)                        AS SPBEL_INS_CPNT_DISA_PIABA
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PBEL_INS_CPNT_DIAG_PIABA END)                        AS SPBEL_INS_CPNT_DIAG_PIABA
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PBEL_INS_CPNT_SUROP_PIABA END)                       AS SPBEL_INS_CPNT_SUROP_PIABA
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PBEL_INS_CPNT_HSPZ_PIABA END)                        AS SPBEL_INS_CPNT_HSPZ_PIABA
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PBEL_INS_CPNT_PLOS_PIABA END)                        AS SPBEL_INS_CPNT_PLOS_PIABA
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PBEL_INS_CPNT_OTR_PIABA END)                         AS SPBEL_INS_CPNT_OTR_PIABA
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PBEL_INS_CPNT_ANTY_DFR_AMT END)                      AS SPBEL_INS_CPNT_ANTY_DFR_AMT
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PBEL_INS_CPNT_PYEX_PREM_VL END)                      AS SPBEL_INS_CPNT_PYEX_PREM_VL
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PBEL_INS_CPNT_ACCT_SRDR_RF END)                      AS SPBEL_INS_CPNT_ACCT_SRDR_RF
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PBEL_INS_CPNT_POHD_DIVD_AMT END)                     AS SPBEL_INS_CPNT_POHD_DIVD_AMT
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PBEL_IVST_CPNT_EXPI_RF END)                          AS SPBEL_IVST_CPNT_EXPI_RF
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PBEL_IVST_CPNT_SRDR_RF END)                          AS SPBEL_IVST_CPNT_SRDR_RF
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PBEL_IVST_CPNT_ANTY_DFR_AMT END)                     AS SPBEL_IVST_CPNT_ANTY_DFR_AMT
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PBEL_IVST_CPNT_SRVL_DFR_AMT END)                     AS SPBEL_IVST_CPNT_SRVL_DFR_AMT
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PBEL_IVST_CPNT_MW_WDRW_AMT END)                      AS SPBEL_IVST_CPNT_MW_WDRW_AMT
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PBEL_IVST_CPNT_ACCT_SRDR_RF END)                     AS SPBEL_IVST_CPNT_ACCT_SRDR_RF
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PBEL_IVST_CPNT_OTR_AMT END)                          AS SPBEL_IVST_CPNT_OTR_AMT
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PBEL_DFMT_INCTLN_NW_AMT END)                         AS SPBEL_DFMT_INCTLN_NW_AMT
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PBEL_DFMT_INCTLN_PRPT_ADMN_EXPN END)                 AS SPBEL_DFMT_INCTLN_PRPT_ADMN_EXPN
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PBEL_DPS_INCTLN_RFDAMT END)                          AS SPBEL_DPS_INCTLN_RFDAMT
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PBEL_DPS_INCTLN_INTAMT END)                          AS SPBEL_DPS_INCTLN_INTAMT
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PBEL_DIR_NBZEXP_INS_COMS END)                        AS SPBEL_DIR_NBZEXP_INS_COMS
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PBEL_DIR_NBZEXP_INS_OTR_COMS END)                    AS SPBEL_DIR_NBZEXP_INS_OTR_COMS
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PBEL_DIR_NBZEXP_OTR_COMS END)                        AS SPBEL_DIR_NBZEXP_OTR_COMS
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PBEL_SERV_EXPN_DIR_MTEXP END)                        AS SPBEL_SERV_EXPN_DIR_MTEXP
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PBEL_TAX_PBIMP_DIR_MTEXP END)                        AS SPBEL_TAX_PBIMP_DIR_MTEXP
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PBEL_EDUT_DIR_MTEXP END)                             AS SPBEL_EDUT_DIR_MTEXP
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PBEL_DPST_PREM_DIR_MTEXP END)                        AS SPBEL_DPST_PREM_DIR_MTEXP
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PBEL_COLEXP_DIR_MTEXP END)                           AS SPBEL_COLEXP_DIR_MTEXP
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PBEL_OTR_DIR_MTEXP END)                              AS SPBEL_OTR_DIR_MTEXP
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PBEL_DIR_LOSDMG_INVT_EXPN END)                       AS SPBEL_DIR_LOSDMG_INVT_EXPN
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PBEL_PRPT_ADMN_EXPN END)                             AS SPBEL_PRPT_ADMN_EXPN
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PBEL_IMF_EXPN END)                                   AS SPBEL_IMF_EXPN
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PCF_BAS_PREM END)					                  AS SPCF_BAS_PREM
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PCF_AD_PYPRM_VL END)				                  AS SPCF_AD_PYPRM_VL
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PCF_INS_CPNT_DTH_PIABA END)                          AS SPCF_INS_CPNT_DTH_PIABA
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PCF_INS_CPNT_DISA_PIABA END)                         AS SPCF_INS_CPNT_DISA_PIABA
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PCF_INS_CPNT_DIAG_PIABA END)                         AS SPCF_INS_CPNT_DIAG_PIABA
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PCF_INS_CPNT_SUROP_PIABA END)                        AS SPCF_INS_CPNT_SUROP_PIABA
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PCF_INS_CPNT_HSPZ_PIABA END)                         AS SPCF_INS_CPNT_HSPZ_PIABA
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PCF_INS_CPNT_PLOS_PIABA END)                         AS SPCF_INS_CPNT_PLOS_PIABA
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PCF_INS_CPNT_OTR_PIABA END)                          AS SPCF_INS_CPNT_OTR_PIABA
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PCF_INS_CPNT_ANTY_DFR_AMT END)                       AS SPCF_INS_CPNT_ANTY_DFR_AMT
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PCF_INS_CPNT_PYEX_PREM_VL END)                       AS SPCF_INS_CPNT_PYEX_PREM_VL
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PCF_INS_CPNT_ACCT_SRDR_RF END)                       AS SPCF_INS_CPNT_ACCT_SRDR_RF
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PCF_INS_CPNT_POHD_DIVD_AMT END)                      AS SPCF_INS_CPNT_POHD_DIVD_AMT
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PCF_IVST_CPNT_EXPI_RF END)                           AS SPCF_IVST_CPNT_EXPI_RF
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PCF_IVST_CPNT_SRDR_RF END)                           AS SPCF_IVST_CPNT_SRDR_RF
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PCF_IVST_CPNT_ANTY_DFR_AMT END)                      AS SPCF_IVST_CPNT_ANTY_DFR_AMT
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PCF_IVST_CPNT_SRVL_DFR_AMT END)                      AS SPCF_IVST_CPNT_SRVL_DFR_AMT
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PCF_IVST_CPNT_MW_WDRW_AMT END)                       AS SPCF_IVST_CPNT_MW_WDRW_AMT
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PCF_IVST_CPNT_ACCT_SRDR_RF END)                      AS SPCF_IVST_CPNT_ACCT_SRDR_RF
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PCF_IVST_CPNT_OTR_AMT END)                           AS SPCF_IVST_CPNT_OTR_AMT
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PCF_DFMT_INCTLN_NW_AMT END)                          AS SPCF_DFMT_INCTLN_NW_AMT
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PCF_DFMT_INCTLN_PRPT_ADMN_EXPN END)                  AS SPCF_DFMT_INCTLN_PRPT_ADMN_EXPN
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PCF_DPS_INCTLN_RFDAMT END)                           AS SPCF_DPS_INCTLN_RFDAMT
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PCF_DPS_INCTLN_INTAMT END)                           AS SPCF_DPS_INCTLN_INTAMT
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PCF_DIR_NBZEXP_INS_COMS END)                         AS SPCF_DIR_NBZEXP_INS_COMS
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PCF_DIR_NBZEXP_INS_OTR_COMS END)                     AS SPCF_DIR_NBZEXP_INS_OTR_COMS
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PCF_DIR_NBZEXP_OTR_COMS END)                         AS SPCF_DIR_NBZEXP_OTR_COMS
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PCF_SERV_EXPN_DIR_MTEXP END)                         AS SPCF_SERV_EXPN_DIR_MTEXP
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PCF_TAX_PBIMP_DIR_MTEXP END)                         AS SPCF_TAX_PBIMP_DIR_MTEXP
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PCF_EDUT_DIR_MTEXP END)                              AS SPCF_EDUT_DIR_MTEXP
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PCF_DPST_PREM_DIR_MTEXP END)                         AS SPCF_DPST_PREM_DIR_MTEXP
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PCF_COLEXP_DIR_MTEXP END)                            AS SPCF_COLEXP_DIR_MTEXP
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PCF_OTR_DIR_MTEXP END)                               AS SPCF_OTR_DIR_MTEXP
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PCF_DIR_LOSDMG_INVT_EXPN END)                        AS SPCF_DIR_LOSDMG_INVT_EXPN
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PCF_PRPT_ADMN_EXPN END)                              AS SPCF_PRPT_ADMN_EXPN
                            , SUM(CASE WHEN A.SHCK_SECD = '0' THEN A.PCF_IMF_EXPN END)                                    AS SPCF_IMF_EXPN                      
                            , MIN(CASE WHEN A.SHCK_SECD = '0' THEN A.INIT_RCGNT_DTM END) 				                  AS MIN_INIT_RCGNT_DTM
                            , MAX(CASE WHEN A.SHCK_SECD = '0' THEN A.ELMN_DTM END)       				                  AS MAX_ELMN_DTM
                            , SUM(CASE WHEN A.SHCK_SECD = '14' THEN A.INS_CPNT_DVP_BEL_AMT + A.IVST_CPNT_DVP_BEL_AMT END) AS M14
                            , SUM(CASE WHEN A.SHCK_SECD = '15' THEN A.INS_CPNT_DVP_BEL_AMT + A.IVST_CPNT_DVP_BEL_AMT END) AS M15  
                            , SUM(CASE WHEN A.SHCK_SECD = '16' THEN A.INS_CPNT_DVP_BEL_AMT + A.IVST_CPNT_DVP_BEL_AMT END) AS M16 
                            , SUM(CASE WHEN A.SHCK_SECD = '17' THEN A.INS_CPNT_DVP_BEL_AMT + A.IVST_CPNT_DVP_BEL_AMT END) AS M17 
                            , SUM(CASE WHEN A.SHCK_SECD = '18' THEN A.INS_CPNT_DVP_BEL_AMT + A.IVST_CPNT_DVP_BEL_AMT END) AS M18 
                            , SUM(CASE WHEN A.SHCK_SECD = '19' THEN A.INS_CPNT_DVP_BEL_AMT + A.IVST_CPNT_DVP_BEL_AMT END) AS M19 
                            , SUM(CASE WHEN A.SHCK_SECD = '20' THEN A.INS_CPNT_DVP_BEL_AMT + A.IVST_CPNT_DVP_BEL_AMT END) AS M20  
                            , SUM(CASE WHEN A.SHCK_SECD = '0'  THEN A.INS_CPNT_DVP_BEL_AMT + A.IVST_CPNT_DVP_BEL_AMT END) AS M00  
                      FROM CF_SIMU.IFRS_CF_BYPDT_INF  A                                                             --1차산출값 테이블 작성 
                      WHERE A.IFRS_ACTS_YYMM ='201811' AND A.IFRS_WRK_SECD ='E' AND A.MVMT_SECD ='1010'             --취합할 조건을 작성. MVMT, 회계년월, 작업구분 등
                      GROUP BY A.IFRS_ACTS_YYMM, A.VALU_YYMM, A.PLYNO, A.MPRD_PRDCD, A.IFRS_WRK_SECD, A.MVMT_SECD
                            , A.PROG_YYMM, A.INIT_RCGNT_TYP_COD, A.APPT_DCRT_SECD, A.LFDE_MMRP_COD, A.PF_SECD
                            , A.SAME_GRP_TYP_COD, A.GOC_TYP_COD, A.VALU_MDL_NAM     
                      ) A                                
                  ) A 
              ,     --아래 인라인뷰 B는 전사수준의 리스크 요인별 상계를 위한 부분임. (각각의 위험요소별 리스크금액 - 기준금액)+ 을 위험금액으로 하여, 상관계수를 반영함
                  (SELECT /*+PARALLEL(A 16) */
                      A.IFRS_ACTS_YYMM, A.VALU_YYMM, A.IFRS_WRK_SECD, A.MVMT_SECD, A.PROG_YYMM, A.APPT_DCRT_SECD  
                      , DECODE(SQRT(A.TR14*A.TR14       + A.TR14*A.TR15*-0.25	  + A.TR14*A.TR1617*0.25 + 0	                   + A.TR14*A.TR20*0.25   + 	     
                                   A.TR14*A.TR15*-0.25  + A.TR15*A.TR15	        + 0	                   + A.TR15*A.TR1819*0.25  + A.TR15*A.TR20*0.25   +
                                   A.TR14*A.TR1617*0.25 + 0	                    + A.TR1617*A.TR1617	   + 0                     + A.TR1617*A.TR20*0.5  +
                                   0	                  + A.TR15*A.TR1819*0.25	+ 0	                   + A.TR1819*A.TR1819	   + A.TR1819*A.TR20*0.5  +
                                   A.TR14*A.TR20*0.25   + A.TR15*A.TR20*0.25	  + A.TR1617*A.TR20*0.5  + A.TR1819*A.TR20*0.5   + A.TR20*A.TR20        	
                                   ), 0 , NULL
                      , SQRT(A.TR14*A.TR14	     + A.TR14*A.TR15*-0.25	+ A.TR14*A.TR1617*0.25 + 0	                   + A.TR14*A.TR20*0.25   + 	     
                            A.TR14*A.TR15*-0.25  + A.TR15*A.TR15	      + 0	                   + A.TR15*A.TR1819*0.25  + A.TR15*A.TR20*0.25   +
                            A.TR14*A.TR1617*0.25 + 0	                  + A.TR1617*A.TR1617	   + 0                     + A.TR1617*A.TR20*0.5  +
                            0	                   + A.TR15*A.TR1819*0.25	+ 0	                   + A.TR1819*A.TR1819	   + A.TR1819*A.TR20*0.5  +
                            A.TR14*A.TR20*0.25   + A.TR15*A.TR20*0.25	  + A.TR1617*A.TR20*0.5  + A.TR1819*A.TR20*0.5   + A.TR20*A.TR20        	
                            ))                        AS TOT_POL_RA_SUM	
                      , CASE WHEN A.MVMT_SECD ='1000' THEN 
                        (SELECT TO_NUMBER(DECODE(C.RA_SHAR_RTO, 0, NULL, C.RA_SHAR_RTO)) FROM CF_SIMU.WHCOM_RA_SHAR_RTO_INF C
                        WHERE C.IFRS_ACTS_YYMM = 
                        (CASE WHEN SUBSTR(A.IFRS_ACTS_YYMM, 5, 2) IN ('01', '02', '03')  THEN (SUBSTR(A.IFRS_ACTS_YYMM, 1, 4) - 1)||'12'
                              WHEN SUBSTR(A.IFRS_ACTS_YYMM, 5, 2) IN ('04', '05', '06')  THEN SUBSTR(A.IFRS_ACTS_YYMM, 1, 4)||'03'
                              WHEN SUBSTR(A.IFRS_ACTS_YYMM, 5, 2) IN ('07', '08', '09')  THEN SUBSTR(A.IFRS_ACTS_YYMM, 1, 4)||'06'
                              WHEN SUBSTR(A.IFRS_ACTS_YYMM, 5, 2) IN ('10', '11', '12')  THEN SUBSTR(A.IFRS_ACTS_YYMM, 1, 4)||'09' END
                        )
                        AND C.IFRS_WRK_SECD = A.IFRS_WRK_SECD AND C.MVMT_SECD IN ('9999','1130') AND C.RN_RSUR_SECD ='P' AND C.APPT_DCRT_SECD ='1' AND C.PROG_YYMM = C.IFRS_ACTS_YYMM
                        ) END AS RA_SHAR_RTO     --스칼라서브쿼리 캐싱효과를 위한 부분    
                  FROM
                      (SELECT /*+PARALLEL(A 16) */
                            A.IFRS_ACTS_YYMM, A.VALU_YYMM, A.IFRS_WRK_SECD, A.MVMT_SECD, A.PROG_YYMM, A.APPT_DCRT_SECD           
                            , SUM(A.PR14)     AS TR14
                            , SUM(A.PR15)     AS TR15
                            , SUM(A.PR1617)   AS TR1617
                            , GREATEST(SUM(A.PR18), SUM(A.PR19)) AS TR1819
                            , SUM(A.PR20)     AS TR20
                      FROM     
                          (SELECT /*+PARALLEL(A 16) */
                                A.IFRS_ACTS_YYMM, A.VALU_YYMM, A.IFRS_WRK_SECD, A.MVMT_SECD, A.PROG_YYMM, A.APPT_DCRT_SECD, A.PF_SECD 
                                , NVL(CASE WHEN A.T14 - A.T0 < 0 THEN 0 ELSE A.T14 - A.T0 END, 0)                           AS PR14
                                , NVL(CASE WHEN A.T15 - A.T0 < 0 THEN 0 ELSE A.T15 - A.T0 END, 0)                           AS PR15
                                , NVL((CASE WHEN A.T16 - A.T0 < 0 THEN 0 ELSE A.T16 - A.T0 END), 0) + NVL((CASE WHEN A.T17 - A.T0 < 0 THEN 0 ELSE A.T17 - A.T0 END), 0) 
                                                                                                                            AS PR1617
                                , NVL(CASE WHEN A.T18 - A.T0 < 0 THEN 0 ELSE A.T18 - A.T0 END, 0)                           AS PR18
                                , NVL(CASE WHEN A.T19 - A.T0 < 0 THEN 0 ELSE A.T19 - A.T0 END, 0)                           AS PR19
                                , NVL(CASE WHEN A.T20 - A.T0 < 0 THEN 0 ELSE A.T20 - A.T0 END, 0)                           AS PR20          
                          FROM
                              (SELECT /*+FULL(A) PARALLEL(A 16) */ 
                                    A.IFRS_ACTS_YYMM, A.VALU_YYMM, A.IFRS_WRK_SECD, A.MVMT_SECD, A.PROG_YYMM, A.APPT_DCRT_SECD, A.PF_SECD                              
                                    , SUM(CASE WHEN A.SHCK_SECD = '14' THEN A.INS_CPNT_DVP_BEL_AMT + A.IVST_CPNT_DVP_BEL_AMT END) AS T14  
                                    , SUM(CASE WHEN A.SHCK_SECD = '15' THEN A.INS_CPNT_DVP_BEL_AMT + A.IVST_CPNT_DVP_BEL_AMT END) AS T15 
                                    , SUM(CASE WHEN A.SHCK_SECD = '16' THEN A.INS_CPNT_DVP_BEL_AMT + A.IVST_CPNT_DVP_BEL_AMT END) AS T16  
                                    , SUM(CASE WHEN A.SHCK_SECD = '17' THEN A.INS_CPNT_DVP_BEL_AMT + A.IVST_CPNT_DVP_BEL_AMT END) AS T17  
                                    , SUM(CASE WHEN A.SHCK_SECD = '18' THEN A.INS_CPNT_DVP_BEL_AMT + A.IVST_CPNT_DVP_BEL_AMT END) AS T18 
                                    , SUM(CASE WHEN A.SHCK_SECD = '19' THEN A.INS_CPNT_DVP_BEL_AMT + A.IVST_CPNT_DVP_BEL_AMT END) AS T19 
                                    , SUM(CASE WHEN A.SHCK_SECD = '20' THEN A.INS_CPNT_DVP_BEL_AMT + A.IVST_CPNT_DVP_BEL_AMT END) AS T20  
                                    , SUM(CASE WHEN A.SHCK_SECD = '0'  THEN A.INS_CPNT_DVP_BEL_AMT + A.IVST_CPNT_DVP_BEL_AMT END) AS T0   
                              FROM CF_SIMU.IFRS_CF_BYPDT_INF  A     --1차산출값 테이블 작성 
                              WHERE A.IFRS_ACTS_YYMM ='201811' AND A.IFRS_WRK_SECD ='E' AND A.MVMT_SECD ='1010'               --취합할 조건을 작성. MVMT, 회계년월, 작업구분 등
                              GROUP BY A.IFRS_ACTS_YYMM, A.VALU_YYMM, A.IFRS_WRK_SECD, A.MVMT_SECD, A.PROG_YYMM, A.APPT_DCRT_SECD, A.PF_SECD         
                              ) A
                          ) A
                      GROUP BY A.IFRS_ACTS_YYMM, A.VALU_YYMM, A.IFRS_WRK_SECD, A.MVMT_SECD, A.PROG_YYMM, A.APPT_DCRT_SECD
                      ) A
                  ) B 
              WHERE 1 = 1 
              AND A.IFRS_ACTS_YYMM     = B.IFRS_ACTS_YYMM                 
              AND A.VALU_YYMM          = B.VALU_YYMM                                                    
              AND A.IFRS_WRK_SECD      = B.IFRS_WRK_SECD     
              AND A.MVMT_SECD          = B.MVMT_SECD        
              AND A.PROG_YYMM          = B.PROG_YYMM         
              AND A.APPT_DCRT_SECD     = B.APPT_DCRT_SECD   
              ) A
          ) A
      ,     --아래 인라인뷰 B는 cohort와 결산단위별로 사용해야할 EIR(effective interest rate)을 보험계약 포트폴리오 단위로 조인하기 위해서 준비하는 과정임
          (SELECT /*+FULL(A) PARALLEL(A 16)*/
                A.FISCAL_YEAR || A.FISCAL_MONTH    AS IFRS_ACTS_YYMM 
                , A.PF_NO                          AS PF_SECD
                , SUBSTR(A.GOC_NO, 1, 2)           AS GOC_TYP_COD	            
                , SUBSTR(A.GOC_NO, 4, 7)           AS SAME_GRP_TYP_COD
                , A.CF_TYPE_GRP       	           AS VALU_MDL_NAM         
                , MAX(A.DC_RATE_VAL)               AS MAX_DC_RATE_VAL
          FROM E17I.DC_RATE_RC A 
          WHERE 1 = 1
          AND A.RC_LBT_TYPE = 'BEL' 
          AND A.FISCAL_YEAR ='2018' AND A.FISCAL_MONTH ='11'            --취합할 조건을 작성.회계년과 월을 나눠서 입력함
          AND ((SUBSTR(A.PF_NO,1,2) <> '99' AND SUBSTR(A.PF_NO, LENGTH(A.PF_NO), 1) = '1' AND A.DC_RATE_TYPE ='LE') 
          OR (SUBSTR(A.PF_NO,1,2) <> '99' AND SUBSTR(A.PF_NO, LENGTH(A.PF_NO), 1) <> '1' AND A.DC_RATE_TYPE ='CE') 
          OR (SUBSTR(A.PF_NO,1,2) = '99' AND A.DC_RATE_TYPE ='CE'))
          GROUP BY A.FISCAL_YEAR || A.FISCAL_MONTH, A.PF_NO,  SUBSTR(A.GOC_NO, 1, 2),  SUBSTR(A.GOC_NO, 4, 7), A.CF_TYPE_GRP
          ) B
      WHERE 1 = 1
      AND A.IFRS_ACTS_YYMM      = B.IFRS_ACTS_YYMM   (+)
      AND A.GOC_TYP_COD_FIN     = B.GOC_TYP_COD      (+)
      AND A.SAME_GRP_TYP_COD    = B.SAME_GRP_TYP_COD (+)
      AND A.PF_SECD             = B.PF_SECD          (+)
      ) A
;


COMMIT;




```
