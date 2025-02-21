# ![image (6) (1) (1) (1)](https://github.com/user-attachments/assets/a9a0d8be-b9dd-4642-92f2-fcb69893cd49) ToTheMoon (투더문)

## 📚 기술 스택
![Swift](https://img.shields.io/badge/Swift-5.0-FA7343?style=flat&logo=swift&logoColor=white)
![Xcode](https://img.shields.io/badge/Xcode-16.1-147EFB?style=flat&logo=xcode&logoColor=white)
![SPM](https://img.shields.io/badge/SPM-DE5C43?style=flat&logo=swift&logoColor=white)
![GitHub](https://img.shields.io/badge/GitHub-181717?style=flat&logo=github&logoColor=white)
![RxSwift](https://img.shields.io/badge/RxSwift-B7178C?style=flat&logo=reactivex&logoColor=white)
![SnapKit](https://img.shields.io/badge/SnapKit-1793D1?style=flat&logoColor=white)
![CoreData](https://img.shields.io/badge/CoreData-4A86CF?style=flat&logoColor=white)
![DGCharts](https://img.shields.io/badge/DGCharts-FF5733?style=flat&logo=chartjs&logoColor=white)

| 카테고리             | 기술 및 도구 |
|----------------------|------------|
| **언어**             | Swift 5 |
| **IDE**             | Xcode 16.1 |
| **의존성 관리**      | SPM (Swift Package Manager) |
| **형상 관리**        | GitHub, Git |
| **아키텍처**        | MVVM, Layered MVVM |
| **디자인 패턴**      | Singleton, Dependency Injection (DI), Service, UseCase, Input-Output |
| **UI 프레임워크**    | UIKit |
| **비동기 처리**      | RxSwift |
| **레이아웃 구성**    | SnapKit |
| **내부 저장소**      | UserDefaults, CoreData |
| **API**            | UpbitOpenAPI, BithumbOpenAPI, CoinoneOpenAPI, KorbitOpenAPI, CoingeckoOpenAPI |
| **네트워킹**        | URLSession, RESTful API, StarScream, WebSocket |
| **차트 및 그래프**   | DGCharts |

---
## 👥 팀원 소개

| 이름 | 역할 | 담당 업무 | GitHub |
|------|------|----------------------------|--------|
| 황석범 | 리더 | 프로젝트 초기 세팅, 앱 배포, API 활용, 기획, 관심목록 화면, 검색 화면, NetworkManager | [@황석범](https://github.com/HwangSeokBeom) |
| 강민성 | 부리더 | API 활용, 기획, 상세 페이지 화면, CoreDataManager | [@강민성](https://github.com/kangminseoung) |
| 서지민 | 팀원 | 디자인, 코인 시세 화면, UI/UX 개선, 기획 | [@서지민](https://github.com/JIMIN-iOSDev) |
| 서현욱 | 팀원 | 디자인, 로고 및 아이콘 제작, 앱 설정 화면, 기획 | [@서현욱](https://github.com/hyunwook-seo) |


---
## ⏰ 프로젝트 기간
- **Start Date**: 2025/01/16
- **End Date**: 2025/02/26

---
## 🖼️ 프리뷰
<table>
  <tr>
    <td><img src="https://github.com/user-attachments/assets/22435079-7c6f-4398-95db-463185fbbc49" width="150"></td>
    <td><img src="https://github.com/user-attachments/assets/ff3a7474-21ae-40de-8856-0ed1675414bc" width="150"></td>
    <td><img src="https://github.com/user-attachments/assets/b5936c98-cd9d-4f98-9d7c-f5d2a7924c95" width="150"></td>
    <td><img src="https://github.com/user-attachments/assets/0ad4a6a3-d22f-41b5-b448-5eecf4126cd4" width="150"></td>
  </tr>
</table>


---
## 🏷 메인 기능
**ToTheMoon**은 각 거래소의 실시간 암호화폐 시세와 정보를 한눈에 볼 수 있는 스마트한 코인 정보 앱입니다.

- 각 거래소의 실시간 코인 시세, 차트 및 정보 확인 기능
- 관심 코인 즐겨찾기 등록으로 관심목록에서 한눈에 확인 기능
- 실시간 업데이트되는 차트로 시장 흐름 즉시 파악 기능
- 검색 기능을 통해 특정 거래소나 코인 빠르게 찾기 기능

---

## ✨ 고려 사항

### 🔑 주요 기능  
- **실시간 업데이트**: 각 거래소 RESTFulAPI와 WebSocket을 활용한 실시간 시장 데이터 조회  
- **사용자 경험**: 부드러운 애니메이션 및 직관적인 내비게이션 제공
- **캔들 데이터 시각화**: 각 거래소의 캔들 데이터를 캔트스틱 차트형태로 시각화해서 보여주기 위해 DGCharts 라이브러리 선택 

### 🎨 UI/UX 개선 사항
- 라이트모드 / 다크 모드 지원  
- 사용자 맞춤 테마 및 레이아웃 제공  
- 다양한 iPhone 모델에 대응하는 반응형 디자인 적용  

---
## 📦 설치 방법
[앱스토어 출시](https://apps.apple.com/kr/app/%ED%88%AC%EB%8D%94%EB%AC%B8/id6741462457)

Clone this repository:
```bash
git clone https://github.com/your-repo/ToTheMoon.git
