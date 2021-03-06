# IFRS17_Modeling

## CI담보율_Batch_query.md 파일 상세

### 테이블 구조

- 모든 소스와 결과 테이블들은 마감년월(CLO_YYMM)컬럼으로 파티셔닝하여 관리한다.(년월 시점별 partitioning으로 I/O 부담 최소화)
- 소스1과 소스2는 변경이 잦기 때문에 작업시에는 사용 대상만을 특정하기 위한 최신여부와 사용불가여부 두개의 flag 컬럼과 조건을 둔다.(LAST_HIS_YN ='1' AND DEL_YN ='0')
- 소스2 IFRS_CI_BFRT_CRT_LST 테이블에는 대상담보(IFRS_CLM_ID)를 구성하는 최대 13개의 기초위험률코드와 담보코드를 입력할 수 있는 컬럼들(RKRT_1_ID, ... RKRT_13_ID)이 존재한다. 담보율과 기초위험률은 코드로 관리하며 IFRS_CLM_ID, RKRT_COD 컬럼명으로 각각 받는다.
- 소스2 IFRS_CI_BFRT_CRT_LST 테이블의 위험률산출식비고(RKRT_CALFM_RMK)컬럼은 **'계산식'**을 담고 있다. **위험률1ID(RKRT_1_ID) ~ 위험률13ID(RKRT_13_ID) 각각을 Q1~Q13으로 하여 표현**한다. 계산에 모든 컬럼을 사용할 필요는 없으며, 계산식에 사용된 컬럼이라도(Q#으로) 해당 컬럼에 코드값이 없는 경우에는 그 컬럼 부분 표현만 무시하도록 처리한다. 
계산식의 예 : (Q1+Q2/2-(1-Q3*Q4)) * (1- Q7)
- 소스2 IFRS_CI_BFRT_CRT_LST 테이블의 IFRSCI급부율생성최종나이코드(IFRS_CI_BFRT_CRT_LAST_AGE_COD)컬럼은 레코드 생성 결과를 제약한다. 예로 최종나이코드값이 80세라면, 재료 담보코드와 위험률코드의 연산조인 결과가 102세까지 산출된다고 하더라도 80세까지만의 레코드를 결과 테이블에 입력해야한다.
- 결과입력 CI_BFRT_INF 테이블의 계산유형코드(CACL_TYP_COD)는 세가지 담보산출목적(**Pri**, **CF**, **N**)에 따라 계산방식을 구분한다. 보험사는 **위험관리**를 위해 약정한 보험금을 100% 지급하지 않고, 담보 별로(치아 90일, 암 1년 등) **부지급이나 일부지급 기간을 설정**하고 있다. 예를 들어서 34세가입 1년경과 35세 지급 담보율과, 35세 가입 직후 35세 담보율은 부담보로 인한 괴리가 발생한다.
    - N(통계산출목적)은 부담보 없이 100% 전부지급으로 담보율 계산.
    - 통계 집계와 산출은 '연'단위이므로, 부지급이나 일부지급 기간이 월단위인 경우 **연**단위로 변환(ex 1- 부지급달수/12)하여 계산한 것이 Pri(프라이싱목적).
    - 모델의 예상현금흐름 산출단위는 '월'이므로 담보연율을 **월할**하여(ex 1-(1-연위험률) ^ (1/12), 단 상수사력가정시) 계산한 것이 CF(현금흐름산출목적)이다. 예상현금흐름 프로젝션은 개별 계약이 몇 세에 가입하여 얼마나 경과한 것인지를 통계적으로 유의미하게 고려해야 한다.
- 성별(GNDR_APPT_COD), 가입연령(NTRY_AGE), 년미만경과기간(YY_LSTH_PPRD)은 각 목적에 따라 시점 별로 사용할 위험률값(RKRT_VL)의 '키'이다.

### CI담보 데이터의 계층형 데이터 설계

- **레벨 1**은 기초통계 위험률만을 조합해 계산한 담보로 가장 기본 계층 데이터이다.
- 담보의 계층레벨 계산은 **"참조하는 기생성 담보 중 가장 높은 레벨 + 1"**로 한다. 기초위험률의 레벨은 0 이므로 레벨1 담보를 설명할 수 있다.  레벨2 담보는 레벨1 담보들과 기초위험률들간의 조합으로 생성한 담보이다. 또 다른 예로 2와 3레벨을 참조하는 담보는 4레벨이다.
- 담보는 레벨 1부터 순차적으로 **같은 레벨끼리 묶어서 계산해야**한다. 예로 레벨3 담보율을 계산하기 위해서는 결과 테이블(CI_BFRT_INF)에 레벨2 담보의 결과물이 반드시 존재해야 한다. 없다면 outer 조인의 결과로 null이 붙고, 존재하는 더 하위레벨 담보나 레벨0의 기초통계정보만 조인에 성공하여서 왜곡된 값의 INSERT 가능성이 있다.
- **가능하다면** 재료로 되는 위험률들의 **최대 통계산출 기간까지** 담보율을 산출한다. 그러나 약관이나 통계집계상의 제약으로 유의미한 연령이 특정된다면 다른 불필요한 연령 레코드를 산출하지 않는 것을 원칙으로 한다. 이는 보험계약이 지급사유가 존재하는 경우에만 유지되며, 상위계층으로 **불필요한 인스턴스까지 재참조 되면서 발생하는 통계기간의 왜곡을 막기 위함**이다. 특정 연령의 발생률이 없다는 것은 "확률적으로 정의되지 않는다"는 것으로, '지급사유가 없음'을 의미하고 보험계약의 개시불가나 소멸로 무의미한 통계 추정 프로젝션을 종료한다는 것과 동일한 의미로 간주한다.

### 계층형 query 구조

- 기본 계층인 레벨1 담보생성에는 결과테이블의 참조가 필요 없지만, 레벨2 이상의 담보생성에는 필요하므로 필요테이블에 따라 **쿼리를 두가지로** 구분하여 작성한다.
- 선행해야하는 계층레벨 별로 작업이 분리되어 있으므로, 최대계층까지 **한단계씩 순차진행**하는 **루프구조**로 구성한다. 루프를 위해 최대계층은 사전에 조회하여 들고 있어야 한다.
- IFRS_CI_BFRT_CRT_LST 테이블은 어플리케이션 이용과 사용자 편의상 13개의 재료 코드를 컬럼으로 늘여 놓은 **비정규형 테이블**이다. 그러나 계층관계를 파악하기 위해서는 UNPIVOT으로 "담보-구성1", "담보-구성2", ... "담보-구성13"처럼 행으로 내려 각각의 관계를 1:1로 대응시켜야한다. 예로 담보B의 "구성2"가 레벨1담보 A라면, B는 A가 전제되어야 계산 가능하므로 부모(A)-자식(B) 관계가 성립한다. 동시에 담보B의 "구성5"가 레벨3담보 C라면 담보 B는 또한 C가 전제되어야 계산 가능하므로 부모(C)-자식(B) 관계가 성립한다. 이처럼 **하나의 CI담보코드**가 다양한 레벨의 여러 부모를 가질 수 있다.
- 행으로 내린 각각의 13컬럼 모두 계층구조를 파악해야 하기 때문에, Oracle 계층형 쿼리에서 **START WITH 구문이 존재하지 않는다(모든 레코드가 계층분석 시작 지점)**. 담보코드의 재료 "구성1" ~ "구성13"간의 관계는 알 수 없으므로, 목적 담보와 "구성1" ~ "13" 각각의 관계를 모두 파악해야한다(앞선 UNPIVOT과정). 구성1보다 구성13에 높은 레벨의 담보를 입력하는 것이 아니라, 단지 계산식에 대입한 Q1~Q13에 대응하는 컬럼일 뿐이다.
- **카티전곱**으로 강제로 산출 기간을 늘려 위의 계산방식에 따라 값을 생성한다. 단 생성 가능한 최대 레코드 집합에서 참조할 모든 구성 위험률의 조인이 실패하거나 산출최대연령에 걸리는 등의 조건에 맞지 않는 레코드는 필터링하는 방식으로 정합성을 유지한다. 산출목적(N, Pri, CF)도 **카티전곱으로** '동일한 재료를 이용한 연산'을 목적에 따라 계산법만 바꾸어 반복 연산할 수 있도록 표식을 해둔다. **각 행의 의미는 담보율이 실제로 연산되는 시점에 판단**한다.
- 일반적인 sql은 작성시점에 구조가 이미 명확히 정의되어 있어야 하는 정형화 질의이므로, PL/SQL, Dynamic query가 아니라면 동적구조를 지원하지 않는다. 하지만 일반 sql이 아닌 **'xml query'**를 이용한다면 최소한 Select-List의 구조는 유연하게 대처할 수 있다. 다양한 재료 값들을 조인하여 string으로 만들고 xml 일반표현의 해석으로 INSERT 직전에 연산하면, 다양한 계산식과 컬럼변경에 따라 sql의 '구조'적인 변경을 고려할 필요가 없다.

### query 사용 시 주의할 점

- xml query는 Oracle 병렬 수행때 runtime error가 발생한다면 대체로 병렬자체가 문제라는 듯한 메세지를 띄운다. 그러나 **실제로는 데이터의 오류**(zero devide, null처리, 의미없는 문자의 삽입으로 인한 일반표현식해석불가로 xml오류 등)**이므로 병렬 그 자체의 문제가 아니다**. query 전체로는 디버그가 어렵기때문에, 인라인뷰 단위로 떼어내어 디버깅을 진행함이 현명하다.
