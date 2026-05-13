# 진행 상태

## 파트별 현황

| 파트 | 상태 | 비고 |
|---|---|---|
| 데이터 | 설계 완료 (구현 대기) | architecture.md 초안 / 카탈로그 SSOT 정정 완료 / 워크트리 미생성 |
| 서버 | 해당 없음 | 잔액 산출은 BQ 측 (server-side 변경 불필요) |
| 클라이언트 | 해당 없음 | 대시보드 소비만 |

## 결정 로그

| 날짜 | 결정 | 이유 |
|---|---|---|
| 2026-05-13 | 원천 SSOT = `server_rdb.heart_log[_detail]` 확정. `analytics_164027297.server_rdb_heart_log[_detail]` 사용 금지 | BQ 실측 결과 옛 위치는 컬럼 6종 누락 + 1일 stale ([ISS-017](../../common-data-airflow/docs/hellobot-data/catalog/issues.md)) |
| 2026-05-13 | 백필 전략 = 1안 풀 recompute | dry-run 10.16 GB / $0.05 — 매우 저렴, 정합성 ★★★ |
| 2026-05-13 | 환불·만료 처리 = D 시점 기준 자연 반영 (정책 별도 컬럼 없음) | 서버 `getUsableHeart` 와 의미 동등 |
| 2026-05-13 | SQL alias 컨벤션: `det` / `chg` / `target_d` | DECLARE 변수와 case-insensitive 충돌 회피 |

## 갭·이슈

- [ISS-017](../../common-data-airflow/docs/hellobot-data/catalog/issues.md) — 옛 위치 stale + prior art 마이그레이션 (본 프로젝트 산출 후 별도 과업)
- [external-tasks B-1](../../common-data-airflow/docs/hellobot-data/catalog/external-tasks.md) — 옛 위치 적재 출처 식별

## 다음 액션

1. 워크트리 생성 → 구현 (유형 B 전환)
2. 백필 스크립트 → 1년치 적재
3. 일배치 통합 → Looker 대시보드
