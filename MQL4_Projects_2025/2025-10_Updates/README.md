# MQL4/MQL5 Projects - 2025년 10월 이후 업데이트

2025년 10월 1일 이후 업데이트된 MQL4/MQL5 오픈소스 프로젝트 모음

## 다운로드 날짜
2025년 11월 8일

## 프로젝트 목록

### 1. Swing-Trend-EA-Pro-MT5
- **저장소**: https://github.com/tomgachter/Swing-Trend-EA-Pro-MT5-
- **설명**: MetaTrader 5용 간단한 트렌드 추종 EA
- **마지막 업데이트**: 2025-11-07
- **라이선스**: MIT
- **언어**: MQL5

**특징**:
- 트렌드 추종 전략
- 스윙 트레이딩에 최적화
- MT5 전용

### 2. shed-ea
- **저장소**: https://github.com/stelioszlat/shed-ea
- **설명**: Adaptive ATR Channel 인디케이터를 통합한 Expert Advisor
- **마지막 업데이트**: 2025-11-07
- **언어**: MQL5

**특징**:
- ATR 기반 채널 전략
- 적응형 변동성 대응
- 고급 리스크 관리

### 3. Three-Line-Break
- **저장소**: https://github.com/marbotek/Three-Line-Break
- **설명**: MetaTrader 4/5용 커스터마이징 가능한 3라인 브레이크 차트 인디케이터
- **마지막 업데이트**: 2025-11-07
- **Stars**: ⭐ 2
- **라이선스**: GPL-3.0
- **언어**: MQL4, MQL5

**특징**:
- 독특한 가격 움직임 시각화
- MT4/MT5 모두 지원
- 커스터마이징 가능 (색상, 두께, 알림)
- 멀티 타임프레임 지원
- 명확한 트렌드 전환 신호

**파일**:
- `ThreeLineBreak.mq4` - MT4 버전
- `ThreeLineBreak.mq5` - MT5 버전
- 예제 차트 이미지 포함

### 4. MetaTrader-Indicators
- **저장소**: https://github.com/opita04/MetaTrader-Indicators
- **설명**: MetaTrader 4 (MQL4) 및 MetaTrader 5 (MQL5) 인디케이터와 Expert Advisors 모음
- **마지막 업데이트**: 2025-11-07
- **언어**: MQL4, MQL5

**포함된 주요 인디케이터**:
- 3LS (mtf + alerts) - 멀티 타임프레임 지원
- 2 MA Trend - 이동평균 트렌드
- Currency Strength Histogram - 통화 강도 히스토그램
- Currency Strength Zones - 통화 강도 존
- BO Dashboard - 바이너리 옵션 대시보드
- Pattern123 - 123 패턴 감지

**포함된 EA**:
- Currency Strength Dashboard EA
- Currency Strength Trader EA

**MQL5 인디케이터**:
- 4TF HA (하이켄 아시)
- smLazyTMA HuskyBands v2.1

### 5. MyWork
- **저장소**: https://github.com/soko8/MyWork
- **설명**: 개발자의 모든 MQL4 작업물 모음
- **마지막 업데이트**: 2025-11-06
- **Stars**: ⭐ 3
- **언어**: MQL4

**특징**:
- 다양한 커스텀 인디케이터
- 실전 트레이딩 EA 모음
- 개발자의 실무 경험 반영

### 6. Equity-Line
- **저장소**: https://github.com/Abhishek-97735/Equity-Line
- **설명**: MT4/MT5/cTrader용 Equity Line 인디케이터 - 예상 자본과 플로팅 손익을 계산하고 시각화
- **마지막 업데이트**: 2025-11-07
- **언어**: MQL4, MQL5, C# (cTrader)

**특징**:
- 실시간 자본 추적
- 플로팅 손익 시각화
- MT4, MT5, cTrader 모두 지원
- 리스크 관리에 유용

**파일**:
- `EquityLine.mq4` - MT4 버전
- `EquityLine.mq5` - MT5 버전
- `EquityLine.cs` - cTrader 버전
- 예제 차트 이미지 포함 (EURUSD)

## 설치 방법

### MetaTrader 4
```bash
# 인디케이터
cp *.mq4 "$MT4_PATH/MQL4/Indicators/"

# Expert Advisors
cp *EA*.mq4 "$MT4_PATH/MQL4/Experts/"

# MetaEditor에서 컴파일 후 사용
```

### MetaTrader 5
```bash
# 인디케이터
cp *.mq5 "$MT5_PATH/MQL5/Indicators/"

# Expert Advisors
cp *EA*.mq5 "$MT5_PATH/MQL5/Experts/"

# MetaEditor에서 컴파일 후 사용
```

## 사용 시 주의사항

1. **백테스팅 필수**: 모든 EA는 실계좌 사용 전 충분한 백테스팅 필요
2. **리스크 관리**: 적절한 로트 사이즈와 손절 설정
3. **라이선스 확인**: 각 프로젝트의 라이선스 준수
4. **업데이트 확인**: 주기적으로 원본 저장소에서 최신 버전 확인

## 관련 링크

- [MQL4 GitHub Topics](https://github.com/topics/mql4)
- [MQL5 GitHub Topics](https://github.com/topics/mql5)
- [MetaTrader Platform](https://www.metatrader5.com)

## 검색 정보

- **검색 날짜**: 2025-11-08
- **검색 조건**: `language:mql4 OR language:mql5 pushed:>2025-10-01`
- **총 검색 결과**:
  - MQL5: 349개 리포지토리
  - MQL4: 112개 리포지토리

## 라이선스

각 프로젝트는 개별 라이선스를 따릅니다. 사용 전 각 프로젝트의 LICENSE 파일을 확인하세요.
