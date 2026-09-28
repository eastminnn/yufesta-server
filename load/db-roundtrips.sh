#!/usr/bin/env bash
# 요청 한 건이 DB를 몇 번 왕복하는지 센다. 로컬 전용(compose의 MySQL general log를 잠깐 켠다).
# 응답 시간만 봐서는 "DB를 몇 번 다녀왔는지"가 보이지 않는다. 캐시가 맞았는데도 트랜잭션 제어문이 나가던 것,
# 로그인 요청마다 회원을 다시 읽던 것 모두 이 방법으로 찾았다(README 2026-09-28).
#
#   ./load/db-roundtrips.sh /api/v1/match/summary                       # 비로그인
#
#   # 로그인. 비밀은 앱 컨테이너가 실제로 쓰는 값을 그대로 가져온다(.env를 직접 자르면 따옴표·개행이 섞일 수 있다)
#   export JWT_SECRET=$(docker compose exec -T app printenv JWT_SECRET)
#   export ACCESS_TOKEN=$(./load/token.sh 2025)      # 2025 = 로컬 회원 ID(seed.sql이 만든 합성 회원)
#   ./load/db-roundtrips.sh /api/v1/match/summary
#
# 먼저 한 번 불러 캐시를 채운 뒤 COUNT건을 연달아 보내고 건당 평균을 낸다.
# 회차 스케줄러가 10초마다 도는데, 그 한 번이 "transaction control 5 + select match_rounds 1"로 잡힌다.
# 건당 값이 아니라 합계 6~9건이 보이면 그것이다. 값이 튀면 한 번 더 돌린다.
set -euo pipefail

REQUEST_PATH="${1:?경로가 필요하다 (예: /api/v1/match/summary)}"
COUNT="${2:-20}"
BASE_URL="${BASE_URL:-http://localhost:8080}"
DB_PASSWORD="${MYSQL_ROOT_PASSWORD:-yufesta}"

mysql_exec() {
  docker compose exec -T mysql mysql --default-character-set=utf8mb4 -uroot "-p${DB_PASSWORD}" yufesta -e "$1" 2>/dev/null
}

call() {
  if [ -n "${ACCESS_TOKEN:-}" ]; then
    curl -s -o /dev/null -w '%{http_code}\n' -H "Cookie: access_token=${ACCESS_TOKEN}" "${BASE_URL}${REQUEST_PATH}"
  else
    curl -s -o /dev/null -w '%{http_code}\n' "${BASE_URL}${REQUEST_PATH}"
  fi
}

# 끝나면(실패해도) 로그를 반드시 끈다. 켜 둔 채로 두면 모든 쿼리가 테이블에 쌓인다
trap 'mysql_exec "SET GLOBAL general_log = '"'"'OFF'"'"';"' EXIT

# 토큰이 받아들여지지 않으면 서버는 조용히 비로그인으로 처리하고 요약은 그래도 200을 준다.
# 그대로 재면 비로그인 수치를 로그인 수치로 착각하게 되므로 먼저 확인하고 멈춘다
if [ -n "${ACCESS_TOKEN:-}" ]; then
  LOGIN_STATUS="$(curl -s -o /dev/null -w '%{http_code}' -H "Cookie: access_token=${ACCESS_TOKEN}" "${BASE_URL}/api/v1/auth/me")"
  if [ "$LOGIN_STATUS" != "200" ]; then
    echo "ACCESS_TOKEN이 받아들여지지 않았다(/api/v1/auth/me -> ${LOGIN_STATUS})." >&2
    echo "서명 비밀이 이 서버의 것과 같은지, 회원 ID가 이 DB에 있는지, 만료(2시간)되지 않았는지 확인할 것" >&2
    exit 1
  fi
fi

echo "캐시 채우기: $(call)"
mysql_exec "SET GLOBAL log_output = 'TABLE'; SET GLOBAL general_log = 'ON'; TRUNCATE mysql.general_log;"
STATUSES="$(for _ in $(seq 1 "$COUNT"); do call; done | sort | uniq -c | tr '\n' ' ')"
sleep 0.3
mysql_exec "SET GLOBAL general_log = 'OFF';"

echo "요청 ${COUNT}건 (${ACCESS_TOKEN:+로그인}${ACCESS_TOKEN:-비로그인}) 응답 코드: ${STATUSES}" | sed 's/(로그인[^)]*)/(로그인)/'
mysql_exec "
SELECT kind AS 'statement', n AS total, ROUND(n / ${COUNT}, 1) AS per_request FROM (
  SELECT CASE
           WHEN q LIKE 'set %' OR q IN ('commit', 'rollback') THEN 'transaction control'
           WHEN q LIKE 'select%' THEN CONCAT('select ', SUBSTRING_INDEX(SUBSTRING_INDEX(q, ' from ', -1), ' ', 1))
           ELSE LEFT(q, 40)
         END AS kind, COUNT(*) AS n
  FROM (SELECT LOWER(CONVERT(argument USING utf8mb4)) AS q FROM mysql.general_log WHERE command_type = 'Query') t
  WHERE q NOT LIKE '%general_log%' AND q NOT LIKE '%version_comment%'
  GROUP BY kind
  UNION ALL
  SELECT '== TOTAL ==', COUNT(*)
  FROM (SELECT CONVERT(argument USING utf8mb4) AS q FROM mysql.general_log WHERE command_type = 'Query') t
  WHERE q NOT LIKE '%general_log%' AND q NOT LIKE '%version_comment%'
) s ORDER BY (kind = '== TOTAL ==') DESC, n DESC;"
