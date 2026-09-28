package com.yufesta.domain.match.service;

import com.yufesta.domain.match.dto.response.LastResultResponse;
import com.yufesta.domain.match.dto.response.MatchSummaryCommonResponse;
import com.yufesta.domain.match.dto.response.MySummaryResponse;
import com.yufesta.domain.match.entity.MatchRound;
import com.yufesta.domain.match.enums.MatchResultStatus;
import com.yufesta.domain.match.repository.ApplicationRepository;
import com.yufesta.domain.match.repository.MyApplicationState;
import java.util.Map;
import java.util.Objects;
import java.util.function.Function;
import java.util.stream.Collectors;
import java.util.stream.Stream;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 홈 요약의 DB 조회 부분. 캐시를 확인한 뒤에만 불리도록 {@link MatchSummaryService}와 빈을 나눴다.
 *
 * <p>한 클래스에 두면 캐시 확인까지 트랜잭션 안에 들어간다. 읽기 전용 트랜잭션은 SELECT를 하나도 보내지 않아도
 * 시작·종료만으로 풀에서 커넥션을 빌리고 제어문 5개({@code SET SESSION TRANSACTION READ ONLY},
 * {@code SET autocommit=0}, {@code COMMIT}, {@code SET autocommit=1}, {@code SET SESSION TRANSACTION READ WRITE})를
 * DB로 보낸다(2026-09-28 로컬 MySQL general log로 확인). 캐시가 맞은 요청이 그 비용을 내지 않게
 * 트랜잭션 경계를 이 클래스의 public 메서드로 옮겼다.
 */
@Service
@Transactional(readOnly = true)
public class MatchSummaryQueryService {

    private final MatchRoundService matchRoundService;
    private final ApplicationRepository applicationRepository;

    public MatchSummaryQueryService(MatchRoundService matchRoundService, ApplicationRepository applicationRepository) {
        this.matchRoundService = matchRoundService;
        this.applicationRepository = applicationRepository;
    }

    /**
     * 모든 사용자에게 같은 부분(현재·다음·최근 발표 회차, 신청자 수)을 DB에서 읽는다. 캐시의 원본 계산이다.
     * @throws CustomException MATCH_ROUND_NOT_FOUND
     */
    public MatchSummaryCommonResponse loadCommon() {
        MatchRound current = matchRoundService.getCurrentRound();
        MatchRound next = matchRoundService.findNextRound(current).orElse(null);
        MatchRound published = matchRoundService.findLatestPublishedRound().orElse(null);
        long applicantCount = applicationRepository.countByRound_IdAndCanceledAtIsNull(current.getId());
        return MatchSummaryCommonResponse.of(current, next, published, applicantCount);
    }

    /**
     * 로그인 사용자의 상태를 읽는다. 사용자마다 달라 캐시하지 않는 대신 쿼리 하나로 끝낸다.
     * <p>어느 회차를 볼지는 공통부에서 받는다. 회차는 모두에게 같은 값이라 요청마다 다시 읽을 이유가 없다.
     * 결과(lastResult)는 발표된 회차에서만 나온다(FR-MT-04). 공통부의 publishedRound가 published_at이 있는 회차다.
     * @param common 요약 공통부(캐시에서 온 값일 수 있다)
     */
    public MySummaryResponse loadMy(Long userId, MatchSummaryCommonResponse common) {
        // 회차가 전부 발표되면 현재 회차와 최근 발표 회차가 같은 회차다
        var roundIds = Stream.of(common.currentRoundId(), common.publishedRoundId())
                .filter(Objects::nonNull)
                .distinct()
                .toList();
        Map<Long, MyApplicationState> stateByRound = applicationRepository.findMyStates(userId, roundIds).stream()
                .collect(Collectors.toMap(MyApplicationState::roundId, Function.identity()));

        boolean applied = stateByRound.containsKey(common.currentRoundId());
        MyApplicationState publishedState = stateByRound.get(common.publishedRoundId());
        LastResultResponse lastResult = publishedState == null
                ? null
                : LastResultResponse.of(common.publishedRoundSeq(), resultStatus(publishedState));
        return MySummaryResponse.of(applied, lastResult);
    }

    private static MatchResultStatus resultStatus(MyApplicationState state) {
        return state.matched() ? MatchResultStatus.MATCHED : MatchResultStatus.UNMATCHED;
    }
}
