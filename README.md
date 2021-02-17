# IFRS17_Queryscript

IFRS17 전사시스템 구축과정에서 담당업무 간단 복기, 테스트 내용 백업을 위해 구성함. 
보험업 전반에 적용해 볼 수 있도록 일반적인 내용으로 작성하였으며, 개인적으로 테스트하며 탐구한 내용이므로 특정 보험사의 메타와 데이터모델링과는 상이함. 
간편하고 편의성을 위해 비정규형으로 많이 작성하였으므로 상황에 맞게 정규화하고 통합하여 정교화할 것. 
 
## 신회계제도 IFRS17 작업 요건, 개요
 
### IFRS17 재무, 통계 정보 산출의 복잡성
 
### 
 
 

## IFRS17 데이터 정합성 프로세스
 
앞서 언급한 IFRS17 신제도와 감독규정에 따라 이전보다 데이터 산출요건이 세분화되고 정교한 모델링이 필요하여, 데이터 산출과정과 정합성 관리도 복잡해졌음. 
하나의 재무사이클을 위한 일련의 업무흐름(DW->마트별전사정보수집->예측모델->계리결산->재무결산 과정을 모든 결산단계에 따라 수십차례 반복)에서 각 업무분야의 데이터 통합과 흐름에서 논리적, 수치적 정합성을 더욱 강조하게되어 일련의 IFRS17 정합성 프로세스를 필요로하게 됨. 
위험의 최소화를 위해 내부검증을 위한 프로세스를 새로운 전사시스템 구축에 맞게 검증프로세스 항목은 아래 예시 참고. 
 
- 각 부서 오너십의 데이터가 각기 목적에 맞게 생성되어 필요한 곳에 쓰인것이 맞는지 데이터 처리검증 
- 적용 계리 및 경제 가정의 변경 여부, 시스템과 추정모델 파라미터 변경 여부 확인과 모니터링 
- 모델의 산출값의 재무제표의 항목별 회계적 금액 일치 여부와 평가시점별 기준금액 역산이 일치하는지 검증 
- 적용 계리 및 경제 가정의 변경 여부, 시스템과 추정모델 파라미터 변경 여부 확인과 모니터링 
- 이상 산출값에 대한 기준점을 마련하여 모니터링하고, 이를 추적하여 파악할 수 있는 검증 
- 의미론적으로는 동일하나, 산출방식과 기준, 사용 데이터가 상이한 방법들을 이용하여 프로세스 역검증 
- 내부검증의 변경 사항에 대한 승인과 절차, 그리고 로그를 유지할 수 있도록 하는 프로세스 마련 
- 업무흐름속에서 트랜젝션 단위를 조정하여 savepoint 마련, 정합성 오염을 최소화하여 필요 시점별 롤백이 가능하도록 프로세스 구성 
 
 
## 쿼리 파일별 개요
 
### CI_Batch.md
CI담보 지급률 배치작업 쿼리에 대한 내용으로 "CI_Batch_README.md" 파일 참고. 
보다 자세하게 스키마와 담보데이터의 계층형모델링 고안 내용은 아래의 notion link 참고. 
https://www.notion.so/6fd73b778abf42e19aae394e56c71ba9
 
### IFRS17_Accounting_n_Audit
IFRS17기준 모델 산출결과 movement별 결산 base 처리를 위한 쿼리 테스트.  
회계산출항목과 통계구분에 따른 항목이 세분화되어 컬럼 개수가 많으므로 상관계수처리와 포트폴리오 단위 그룹핑부분만 참고할 것. 
 
### Meta_Script.md
오라클18c기준 테이블, 인덱스, comment, 권한 등의 추출을 위한 내용으로 "Meta_Script_README.md" 파일 참고. 
 
### ReIns_Optimization.md
재보험평균출재율 산출업무에 존재하는 여러집계기준과 속성, 그리고 각기의 처리방식의 '통합'을 시도한 내용으로 "ReIns_Optimization_README.md" 파일 참고. 
보다 자세하게 스키마와 업무목적에 대한 내용은 아래의 notion link참고. 
https://www.notion.so/OLAP-e280b8d084dc48cab4670ffedc0cae77 
 
### VFA_
VFA(Variable Fee Aproach for direct participating contracts)판단 방법에 대한 개요와 집계 엔터티 통합후 테스트 쿼리. 
 
### Sensitivity
서버에 엑셀 import한 데이터를 이용하기 위한 신계약 물량 민감도 업무목적을 위한 테스트 쿼리. 
 
### Sensitivity
서버에 엑셀 import한 데이터를 이용하기 위한 재보험 손익률 민감도 업무목적을 위한 테스트 쿼리. 약식 정합성 확인과정 포함. 
 
 
## 보험사 데이터 표준화, 메타정보 관리
개인적인 작업기준과 생각을 정리함. 아래의 notion link 참고. 
https://www.notion.so/57ce832b3f174c608be3a29ac93ebf21 
 
 
## 관계형데이터 모델링에 대해서
고민을 위해 참고한 "관계형 데이터 모델링 노트" 요약. 아래의 notion link 참고. 
https://www.notion.so/be10152a52a44de090c3cd88a951b91d 
 
 
## SQLite 사용에 대해서
application 이용과 로컬 데이터관리를 위한 서버리스 DB 고민. 아래의 notion link 참고. 
https://www.notion.so/SQLite-d32608beda5144da9d4953e9d3d8d447 
 
 
