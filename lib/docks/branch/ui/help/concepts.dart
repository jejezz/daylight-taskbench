import 'package:daylight_taskbench/l10n/app_localizations.dart';

/// 개념 도움말 카드 (PLAN.md 3.13). v0.1.0은 동기화와 Pull 방식에 필요한
/// 카드로 시작했고, v0.2.0에서 병합(squash)과 태그 카드를 더했다.
enum Concept {
  fetchVsPull,
  upstream,
  fastForward,
  mergeCommit,
  rebase,
  squash,
  annotatedTag,
  stash,
  detachedHead,
  forceWithLease,
  revert,
  cherryPick,
  reset,
  reflog,
  commitGraph,
}

/// 커밋 그래프 한 장면. 커밋은 왼쪽(오래됨) → 오른쪽(최신), 줄(lane)은 위에서 아래.
class GraphScene {
  const GraphScene({required this.caption, required this.commits, required this.edges, this.labels = const []});

  final String caption;
  final List<GraphCommit> commits;

  /// (부모 id, 자식 id)
  final List<(String, String)> edges;
  final List<GraphLabel> labels;
}

class GraphCommit {
  const GraphCommit(this.id, this.column, this.lane, {this.highlight = false, this.ghost = false});

  final String id;
  final int column;
  final int lane;

  /// 이번 동작으로 새로 생긴 커밋.
  final bool highlight;

  /// 아직 내 컴퓨터에 없는 커밋 (원격에만 있음).
  final bool ghost;
}

class GraphLabel {
  const GraphLabel(this.text, this.commit, {this.highlight = false, this.remote = false});

  final String text;
  final String commit;

  /// 이번 동작으로 옮겨진 이름표.
  final bool highlight;
  final bool remote;
}

class ConceptLink {
  const ConceptLink(this.title, this.url);

  final String title;
  final String url;
}

/// 카드 한 장의 내용 (카드 구성: 낱말 뜻 → git에서는 → 왜·언제 → 그림 → 링크).
class ConceptCard {
  const ConceptCard({
    required this.title,
    required this.word,
    required this.inGit,
    required this.why,
    required this.scenes,
    required this.links,
  });

  final String title;
  final String word;
  final String inGit;
  final String why;
  final List<GraphScene> scenes;
  final List<ConceptLink> links;
}

const _a = GraphCommit('A', 0, 0);
const _b = GraphCommit('B', 1, 0);

ConceptCard conceptCard(AppLocalizations l10n, Concept concept) {
  final ko = l10n.localeName == 'ko';
  final book = ko ? 'https://git-scm.com/book/ko/v2' : 'https://git-scm.com/book/en/v2';
  final merging = ConceptLink(
    l10n.bdHelpLinkBranchingBasics,
    ko
        ? '$book/Git-%EB%B8%8C%EB%9E%9C%EC%B9%98-%EB%B8%8C%EB%9E%9C%EC%B9%98%EC%99%80-Merge-%EC%9D%98-%EA%B8%B0%EC%B4%88'
        : '$book/Git-Branching-Basic-Branching-and-Merging',
  );
  final remoteBranches = ConceptLink(
    l10n.bdHelpLinkRemoteBranches,
    ko
        ? '$book/Git-%EB%B8%8C%EB%9E%9C%EC%B9%98-%EB%A6%AC%EB%AA%A8%ED%8A%B8-%EB%B8%8C%EB%9E%9C%EC%B9%98'
        : '$book/Git-Branching-Remote-Branches',
  );
  final rebasing = ConceptLink(
    l10n.bdHelpLinkRebasing,
    ko ? '$book/Git-%EB%B8%8C%EB%9E%9C%EC%B9%98-Rebase-%ED%95%98%EA%B8%B0' : '$book/Git-Branching-Rebasing',
  );
  const gitMerge = ConceptLink('git-merge', 'https://git-scm.com/docs/git-merge');
  const gitPush = ConceptLink('git-push --force-with-lease', 'https://git-scm.com/docs/git-push#Documentation/git-push.txt---force-with-leaseltrefnamegt');
  const gitPull = ConceptLink('git-pull', 'https://git-scm.com/docs/git-pull');

  // 갈라진 기록: main은 E를, feature는 C·D를 가졌다.
  const diverged = [_a, _b, GraphCommit('E', 2, 0), GraphCommit('C', 2, 1), GraphCommit('D', 3, 1)];
  const divergedEdges = [('A', 'B'), ('B', 'E'), ('B', 'C'), ('C', 'D')];

  return switch (concept) {
    Concept.fetchVsPull => ConceptCard(
        title: l10n.bdHelpFetchVsPullTitle,
        word: l10n.bdHelpFetchVsPullWord,
        inGit: l10n.bdHelpFetchVsPullInGit,
        why: l10n.bdHelpFetchVsPullWhy,
        scenes: [
          GraphScene(
            caption: l10n.bdHelpCaptionBefore,
            commits: const [_a, _b, GraphCommit('C', 2, 0, ghost: true), GraphCommit('D', 3, 0, ghost: true)],
            edges: const [('A', 'B'), ('B', 'C'), ('C', 'D')],
            labels: const [GraphLabel('main', 'B'), GraphLabel('origin/main', 'B', remote: true)],
          ),
          GraphScene(
            caption: l10n.bdHelpCaptionAfterFetch,
            commits: const [_a, _b, GraphCommit('C', 2, 0, highlight: true), GraphCommit('D', 3, 0, highlight: true)],
            edges: const [('A', 'B'), ('B', 'C'), ('C', 'D')],
            labels: const [GraphLabel('main', 'B'), GraphLabel('origin/main', 'D', remote: true, highlight: true)],
          ),
          GraphScene(
            caption: l10n.bdHelpCaptionAfterPull,
            commits: const [_a, _b, GraphCommit('C', 2, 0), GraphCommit('D', 3, 0)],
            edges: const [('A', 'B'), ('B', 'C'), ('C', 'D')],
            labels: const [GraphLabel('main', 'D', highlight: true), GraphLabel('origin/main', 'D', remote: true)],
          ),
        ],
        links: [remoteBranches, gitPull],
      ),
    Concept.upstream => ConceptCard(
        title: l10n.bdHelpUpstreamTitle,
        word: l10n.bdHelpUpstreamWord,
        inGit: l10n.bdHelpUpstreamInGit,
        why: l10n.bdHelpUpstreamWhy,
        scenes: [
          GraphScene(
            caption: l10n.bdHelpCaptionAheadOne,
            commits: const [_a, _b, GraphCommit('C', 2, 0, highlight: true)],
            edges: const [('A', 'B'), ('B', 'C')],
            labels: const [GraphLabel('feature', 'C', highlight: true), GraphLabel('origin/feature', 'B', remote: true)],
          ),
        ],
        links: [remoteBranches],
      ),
    Concept.fastForward => ConceptCard(
        title: l10n.bdHelpFastForwardTitle,
        word: l10n.bdHelpFastForwardWord,
        inGit: l10n.bdHelpFastForwardInGit,
        why: l10n.bdHelpFastForwardWhy,
        scenes: [
          GraphScene(
            caption: l10n.bdHelpCaptionBefore,
            commits: const [_a, _b, GraphCommit('C', 2, 0), GraphCommit('D', 3, 0)],
            edges: const [('A', 'B'), ('B', 'C'), ('C', 'D')],
            labels: const [GraphLabel('main', 'B'), GraphLabel('feature', 'D')],
          ),
          GraphScene(
            caption: l10n.bdHelpCaptionAfter,
            commits: const [_a, _b, GraphCommit('C', 2, 0), GraphCommit('D', 3, 0)],
            edges: const [('A', 'B'), ('B', 'C'), ('C', 'D')],
            labels: const [GraphLabel('main', 'D', highlight: true), GraphLabel('feature', 'D')],
          ),
        ],
        links: [merging, gitMerge],
      ),
    Concept.mergeCommit => ConceptCard(
        title: l10n.bdHelpMergeCommitTitle,
        word: l10n.bdHelpMergeCommitWord,
        inGit: l10n.bdHelpMergeCommitInGit,
        why: l10n.bdHelpMergeCommitWhy,
        scenes: [
          GraphScene(
            caption: l10n.bdHelpCaptionBefore,
            commits: diverged,
            edges: divergedEdges,
            labels: const [GraphLabel('main', 'E'), GraphLabel('feature', 'D')],
          ),
          GraphScene(
            caption: l10n.bdHelpCaptionAfter,
            commits: const [...diverged, GraphCommit('M', 4, 0, highlight: true)],
            edges: const [...divergedEdges, ('E', 'M'), ('D', 'M')],
            labels: const [GraphLabel('main', 'M', highlight: true), GraphLabel('feature', 'D')],
          ),
        ],
        links: [merging, gitMerge],
      ),
    Concept.rebase => ConceptCard(
        title: l10n.bdHelpRebaseTitle,
        word: l10n.bdHelpRebaseWord,
        inGit: l10n.bdHelpRebaseInGit,
        why: l10n.bdHelpRebaseWhy,
        scenes: [
          GraphScene(
            caption: l10n.bdHelpCaptionBefore,
            commits: diverged,
            edges: divergedEdges,
            labels: const [GraphLabel('main', 'E'), GraphLabel('feature', 'D')],
          ),
          GraphScene(
            caption: l10n.bdHelpCaptionAfter,
            commits: const [
              _a,
              _b,
              GraphCommit('E', 2, 0),
              GraphCommit("C'", 3, 0, highlight: true),
              GraphCommit("D'", 4, 0, highlight: true),
            ],
            edges: const [('A', 'B'), ('B', 'E'), ('E', "C'"), ("C'", "D'")],
            labels: const [GraphLabel('main', 'E'), GraphLabel('feature', "D'", highlight: true)],
          ),
        ],
        links: [rebasing],
      ),
    Concept.squash => ConceptCard(
        title: l10n.bdHelpSquashTitle,
        word: l10n.bdHelpSquashWord,
        inGit: l10n.bdHelpSquashInGit,
        why: l10n.bdHelpSquashWhy,
        scenes: [
          GraphScene(
            caption: l10n.bdHelpCaptionBefore,
            commits: const [_a, _b, GraphCommit('C', 2, 1), GraphCommit('D', 3, 1), GraphCommit('E', 4, 1)],
            edges: const [('A', 'B'), ('B', 'C'), ('C', 'D'), ('D', 'E')],
            labels: const [GraphLabel('main', 'B'), GraphLabel('feature', 'E')],
          ),
          GraphScene(
            caption: l10n.bdHelpCaptionAfterSquash,
            commits: const [
              _a,
              _b,
              GraphCommit('S', 2, 0, highlight: true),
              GraphCommit('C', 2, 1),
              GraphCommit('D', 3, 1),
              GraphCommit('E', 4, 1),
            ],
            edges: const [('A', 'B'), ('B', 'S'), ('B', 'C'), ('C', 'D'), ('D', 'E')],
            labels: const [GraphLabel('main', 'S', highlight: true), GraphLabel('feature', 'E')],
          ),
        ],
        links: [
          ConceptLink(l10n.bdHelpLinkGitHubMergeMethods,
              'https://docs.github.com/${ko ? 'ko' : 'en'}/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/about-merge-methods-on-github'),
          gitMerge,
        ],
      ),
    Concept.annotatedTag => ConceptCard(
        title: l10n.bdHelpTagTitle,
        word: l10n.bdHelpTagWord,
        inGit: l10n.bdHelpTagInGit,
        why: l10n.bdHelpTagWhy,
        scenes: [
          GraphScene(
            caption: l10n.bdHelpCaptionTag,
            commits: const [_a, _b, GraphCommit('C', 2, 0), GraphCommit('D', 3, 0)],
            edges: const [('A', 'B'), ('B', 'C'), ('C', 'D')],
            labels: const [
              GraphLabel('v1.0.0', 'B', highlight: true),
              GraphLabel('v1.1.0', 'D', highlight: true),
              GraphLabel('main', 'D'),
            ],
          ),
        ],
        links: [
          ConceptLink(
            l10n.bdHelpLinkTagging,
            ko ? '$book/Git%EC%9D%98-%EA%B8%B0%EC%B4%88-%ED%83%9C%EA%B7%B8' : '$book/Git-Basics-Tagging',
          ),
        ],
      ),
    Concept.stash => ConceptCard(
        title: l10n.bdHelpStashTitle,
        word: l10n.bdHelpStashWord,
        inGit: l10n.bdHelpStashInGit,
        why: l10n.bdHelpStashWhy,
        scenes: [
          GraphScene(
            caption: l10n.bdHelpCaptionStash,
            commits: const [_a, _b, GraphCommit('W', 2, 1, highlight: true)],
            edges: const [('A', 'B'), ('B', 'W')],
            labels: const [GraphLabel('main', 'B'), GraphLabel('stash@{0}', 'W', highlight: true)],
          ),
        ],
        links: [
          ConceptLink(
            l10n.bdHelpLinkStashing,
            ko ? '$book/Git-%EB%8F%84%EA%B5%AC-Stashing%EA%B3%BC-Cleaning' : '$book/Git-Tools-Stashing-and-Cleaning',
          ),
        ],
      ),
    Concept.detachedHead => ConceptCard(
        title: l10n.bdHelpDetachedTitle,
        word: l10n.bdHelpDetachedWord,
        inGit: l10n.bdHelpDetachedInGit,
        why: l10n.bdHelpDetachedWhy,
        scenes: [
          GraphScene(
            caption: l10n.bdHelpCaptionDetached,
            commits: const [_a, _b, GraphCommit('C', 2, 0), GraphCommit('D', 3, 0)],
            edges: const [('A', 'B'), ('B', 'C'), ('C', 'D')],
            labels: const [
              GraphLabel('HEAD', 'B', highlight: true),
              GraphLabel('v1.0.0', 'B'),
              GraphLabel('main', 'D'),
            ],
          ),
        ],
        links: [
          ConceptLink(
            l10n.bdHelpLinkTagging,
            ko ? '$book/Git%EC%9D%98-%EA%B8%B0%EC%B4%88-%ED%83%9C%EA%B7%B8' : '$book/Git-Basics-Tagging',
          ),
        ],
      ),
    Concept.forceWithLease => ConceptCard(
        title: l10n.bdHelpForceTitle,
        word: l10n.bdHelpForceWord,
        inGit: l10n.bdHelpForceInGit,
        why: l10n.bdHelpForceWhy,
        scenes: [
          GraphScene(
            caption: l10n.bdHelpCaptionBefore,
            commits: const [_a, _b, GraphCommit('C', 2, 0), GraphCommit("C'", 2, 1, highlight: true)],
            edges: const [('A', 'B'), ('B', 'C'), ('B', "C'")],
            labels: const [
              GraphLabel('origin/feature', 'C', remote: true),
              GraphLabel('feature', "C'", highlight: true),
            ],
          ),
          GraphScene(
            caption: l10n.bdHelpCaptionAfter,
            commits: const [_a, _b, GraphCommit("C'", 2, 0, highlight: true)],
            edges: const [('A', 'B'), ('B', "C'")],
            labels: const [
              GraphLabel('origin/feature', "C'", remote: true, highlight: true),
              GraphLabel('feature', "C'"),
            ],
          ),
        ],
        links: [gitPush],
      ),
    Concept.commitGraph => ConceptCard(
        title: l10n.bdHelpCommitGraphTitle,
        word: l10n.bdHelpCommitGraphWord,
        inGit: l10n.bdHelpCommitGraphInGit,
        why: l10n.bdHelpCommitGraphWhy,
        scenes: [
          GraphScene(
            caption: l10n.bdHelpCaptionGraphMerged,
            commits: const [
              _a,
              _b,
              GraphCommit('E', 2, 0),
              GraphCommit('C', 2, 1),
              GraphCommit('D', 3, 1),
              GraphCommit('M', 4, 0, highlight: true),
            ],
            edges: const [('A', 'B'), ('B', 'E'), ('B', 'C'), ('C', 'D'), ('E', 'M'), ('D', 'M')],
            labels: const [GraphLabel('main', 'M', highlight: true), GraphLabel('feature', 'D')],
          ),
        ],
        links: [const ConceptLink('git-log --graph', 'https://git-scm.com/docs/git-log#Documentation/git-log.txt---graph')],
      ),
    Concept.reset => ConceptCard(
        title: l10n.bdHelpResetTitle,
        word: l10n.bdHelpResetWord,
        inGit: l10n.bdHelpResetInGit,
        why: l10n.bdHelpResetWhy,
        scenes: [
          GraphScene(
            caption: l10n.bdHelpCaptionBeforeReset,
            commits: const [_a, _b, GraphCommit('C', 2, 0), GraphCommit('D', 3, 0)],
            edges: const [('A', 'B'), ('B', 'C'), ('C', 'D')],
            labels: const [GraphLabel('main', 'D')],
          ),
          GraphScene(
            caption: l10n.bdHelpCaptionAfterReset,
            commits: const [_a, _b, GraphCommit('C', 2, 0), GraphCommit('D', 3, 0)],
            edges: const [('A', 'B'), ('B', 'C'), ('C', 'D')],
            labels: const [GraphLabel('main', 'B', highlight: true)],
          ),
        ],
        links: [const ConceptLink('git-reset', 'https://git-scm.com/docs/git-reset')],
      ),
    Concept.reflog => ConceptCard(
        title: l10n.bdHelpReflogTitle,
        word: l10n.bdHelpReflogWord,
        inGit: l10n.bdHelpReflogInGit,
        why: l10n.bdHelpReflogWhy,
        scenes: [
          GraphScene(
            caption: l10n.bdHelpCaptionReflog,
            commits: const [_a, _b, GraphCommit('C', 2, 0), GraphCommit('D', 3, 0)],
            edges: const [('A', 'B'), ('B', 'C'), ('C', 'D')],
            labels: const [GraphLabel('HEAD@{0}', 'B', highlight: true), GraphLabel('HEAD@{1}', 'D')],
          ),
        ],
        links: [const ConceptLink('git-reflog', 'https://git-scm.com/docs/git-reflog')],
      ),
    Concept.revert => ConceptCard(
        title: l10n.bdHelpRevertTitle,
        word: l10n.bdHelpRevertWord,
        inGit: l10n.bdHelpRevertInGit,
        why: l10n.bdHelpRevertWhy,
        scenes: [
          GraphScene(
            caption: l10n.bdHelpCaptionAfterRevert,
            commits: const [_a, _b, GraphCommit('C', 2, 0), GraphCommit("C⁻", 3, 0, highlight: true)],
            edges: const [('A', 'B'), ('B', 'C'), ('C', "C⁻")],
            labels: const [GraphLabel('main', "C⁻", highlight: true)],
          ),
        ],
        links: [const ConceptLink('git-revert', 'https://git-scm.com/docs/git-revert')],
      ),
    Concept.cherryPick => ConceptCard(
        title: l10n.bdHelpCherryPickTitle,
        word: l10n.bdHelpCherryPickWord,
        inGit: l10n.bdHelpCherryPickInGit,
        why: l10n.bdHelpCherryPickWhy,
        scenes: [
          GraphScene(
            caption: l10n.bdHelpCaptionBefore,
            commits: const [_a, _b, GraphCommit('E', 2, 0), GraphCommit('C', 2, 1), GraphCommit('D', 3, 1)],
            edges: const [('A', 'B'), ('B', 'E'), ('B', 'C'), ('C', 'D')],
            labels: const [GraphLabel('main', 'E'), GraphLabel('feature', 'D')],
          ),
          GraphScene(
            caption: l10n.bdHelpCaptionAfterCherryPick,
            commits: const [
              _a,
              _b,
              GraphCommit('E', 2, 0),
              GraphCommit("D'", 3, 0, highlight: true),
              GraphCommit('C', 2, 1),
              GraphCommit('D', 3, 1),
            ],
            edges: const [('A', 'B'), ('B', 'E'), ('E', "D'"), ('B', 'C'), ('C', 'D')],
            labels: const [GraphLabel('main', "D'", highlight: true), GraphLabel('feature', 'D')],
          ),
        ],
        links: [const ConceptLink('git-cherry-pick', 'https://git-scm.com/docs/git-cherry-pick')],
      ),
  };
}
