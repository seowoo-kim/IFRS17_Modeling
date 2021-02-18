# IFRS17_Queryscript
<br/>

IFRS17 전사시스템 구축과정에서 계리 주제영역 담당업무 간단 복기, 테스트 내용 백업을 위해 구성함.  
보험업 전반에 적용해 볼 수 있도록 일반적인 내용으로 작성하였으며,<br/> 
***개인적으로 테스트하며 탐구한 내용이므로 실제 보험사의 메타와 데이터모델링과는 상이함.***  
빠른 복기와 편의성을 위해 비정규형으로 많이 작성하였으므로, 상황에 맞게 모델링을 다시하거나 정규화하고 통합하여 정교화할 것.  
<br/> 
  
## 신 회계제도 IFRS17 개요
<br/>

### IFRS17 데이터 산출과 관리의 복잡성 원인 분석
1. 보험사업의 수익 인식 방식이 기존의 보험료나 투자수입금 유입이 아닌, 다양한 기초 정보에 근거하여 계산 하도록 변경됨. <br/>   시중의 금융변수 정보와 기업 고유데이터, 통계를 잘 쌓고 정제해서 합리적인 추정으로 미래의 보험서비스 제공에 따른 수익 인식을 해야 하므로 추정과 데이터가 중요해짐.<br/>
2. 회계단계가 세분화되고 통계적 추정이 많아지면서, 변동성 설명을 위한 재무정보와 가정의 분석단위가 나뉘어 데이터가 많아짐.<br/>
3. 미래의 현금흐름을 최선추정할 때 다양한 가정과 복잡한 예측모델 및 수식을 사용하면서 전문적인 데이터를 올바르게 사용해야 함.<br/>   (경제가정, 지급률, 계약자행동, 시나리오 확률가중평균, 보험서비스와 관련된 모든 부문 현금흐름 추정 등)<br/>
4. 통계와 가정의 전제하에 회계처리가 이루어지므로, 회계정책에 대한 통제와 변경사항을 엄격하게 관리해야 함. <br/>
5. 대량의 데이터와 가정(계약자정보, 경제가정, 계리가정, 사업비가정, 운영정책가정 등)이 얽혀 여러 단계로 계산되기에, 작은 오류로도 잘못된 전사 회계결과 산출이 이루어 질 수 있음.<br/>
<br/>

### IFRS17 데이터 정합성 프로세스
IFRS17신제도와 감독규정에 따라 이전보다 데이터 산출요건이 세분화되고 정교한 모델링이 필요하여,
<br/> 데이터 산출과정과 정합성 관리도 복잡해졌음.  
하나의 재무사이클은 "DW->마트별 전사정보수집->예측모델->계리결산->재무결산"의 흐름을 수십차례 반복하여 완성됨.  
사이클을 구성하는 각 업무분야 데이터 흐름의 논리적, 수치적 정합성을 더욱 강조하게되어 일련의 IFRS17 정합성 프로세스를 필요로 함.  
위험의 최소화를 위해 내부검증을 위한 프로세스를 새로운 전사시스템 구축에 맞게 준비함. 
아래는 그 예시.  
<br/>

- 각 모델 오너십의 데이터가 각기 목적에 맞게 생성되어 필요한 곳에 쓰였는지 데이터 처리 검증  
- 적용 계리 및 경제 가정의 변경 여부, 시스템과 추정모델 파라미터 변경 여부 모니터링  
- 모델 산출값의 재무제표 항목별 회계적 금액 일치 여부와, 평가시점별 역산한 기준금액이 일치하는지 검증  
- 이상 산출값에 대한 기준점을 마련하여 모니터링하고, 이를 추적하여 파악할 수 있는 방안을 마련  
- 의미론적으로는 동일하나, 산출방식과 기준, 사용 데이터가 상이한 방법들을 이용하여 프로세스 재검증  
- 내부검증의 변경 사항에 대한 승인과 절차, 그리고 로그를 유지할 수 있도록 하는 프로세스 마련  
- 업무흐름 속에서 트랜젝션 단위를 조정하여 savepoint 마련, 정합성 오염을 최소화하여 필요 시점별 롤백이 가능하도록 프로세스 구성  
<br/>
 
## SQL 파일 별 개요
<br/>
IFRS17 전사시스템 구축 프로젝트에서 계리 주제영역을 담당하며 맡은 프로세스 일부 테스트 파일.  
<br/>

### Benefit_Batch.md
일반(비계층형, 비CI/GI)담보 지급률 배치작업 테스트 쿼리. ***아래의 "CI_Batch.md"의 상세인 notion link에서 담보데이터에 대한 내용 참고.***  
<br/>

### CI_Batch.md
CI(계층형)담보 지급률 배치작업 쿼리에 대한 내용으로 "CI_Batch_README.md" 파일 참고.  
보다 자세하게 스키마와 담보데이터의 계층형모델링 고안 내용은 아래의 notion link 참고.  
https://www.notion.so/6fd73b778abf42e19aae394e56c71ba9  
<br/>

### CSM_Calc.md  
CSM상각률 계산 내용으로 결산단계(무브먼트)별로 상이한 집계와 처리를 하는 모델을 통합해보고 확인한 테스트 쿼리.    
<br/>

### IFRS17_Accounting_n_Audit.md
IFRS17기준 모델 산출결과 movement별 결산 base 처리를 위한 쿼리 테스트.   
회계산출항목과 통계구분에 따른 항목이 세분화되어 컬럼 개수가 많으므로 상관계수처리와 포트폴리오 단위 그룹핑부분만 참고할 것.  
<br/>

### Meta_Script.md
오라클18c기준 테이블, 인덱스, comment, 권한 등의 추출을 위한 내용으로 "Meta_Script_README.md" 파일 참고.  
<br/>

### ReIns_Optimization.md
재보험평균출재율 산출업무에 존재하는 여러집계기준과 속성, 그리고 각기의 처리방식의 '통합'을 시도한 내용으로 "ReIns_Optimization_README.md" 파일 참고.  
보다 자세하게 스키마와 업무목적에 대한 내용은 아래의 notion link참고.  
https://www.notion.so/OLAP-e280b8d084dc48cab4670ffedc0cae77  
<br/>

### VFA_Judge.md
VFA(Variable Fee Aproach for direct participating contracts)판단 방법에 대한 개요와 집계 엔터티 통합 후 테스트 쿼리.  
<br/>

[https://github.com/seowoo-kim/IFRS17_Queryscript/blob/main/NB_Sens.md](###NB_Sens.md)
신계약 물량 민감도 업무목적을 위한 테스트 쿼리. 서버에 엑셀 import한 데이터를 이용하기 위한 형태.  
<br/>

### ReIns_PL_Sens.md
재보험 손익률 민감도 업무목적을 위한 테스트 쿼리. 약식 정합성 확인과정 포함. 서버에 엑셀 import한 데이터를 이용하기 위한 형태.  
<br/>
<br/>
  
## 보험사 데이터 표준화, 메타정보 관리
개인적인 작업기준과 생각을 정리함. 아래의 notion link 참고.  
https://www.notion.so/57ce832b3f174c608be3a29ac93ebf21  
<br/>

## 관계형데이터 모델링에 대해서
고민을 위해 참고한 "관계형 데이터 모델링 노트" 요약. 아래의 notion link 참고.  
https://www.notion.so/be10152a52a44de090c3cd88a951b91d  
<br/>
 
## SQLite 사용에 대해서
application 이용과 로컬 데이터관리를 위한 서버리스 DB 고민. 아래의 notion link 참고.  
https://www.notion.so/SQLite-d32608beda5144da9d4953e9d3d8d447  
<br/>
 
