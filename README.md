# Claude Code v2 고급 매뉴얼 📚

Claude Code v2를 활용한 개발 생산성 향상을 위한 종합 가이드입니다.

## 📖 매뉴얼 구성

이 레포지토리는 총 5권의 상세한 매뉴얼로 구성되어 있으며, 각 권당 50쪽 분량의 전문적인 내용을 담고 있습니다.

### 제1권: 소개, 설치 및 기본 개념
**파일**: `ccmanual1.docx` (48KB)

- Claude Code 소개 및 주요 특징
- 시스템 요구사항 (하드웨어, 소프트웨어, 네트워크)
- 설치 가이드 (Windows, macOS, Linux)
- 기본 개념 및 용어 정리
- 사용자 인터페이스 이해
- 첫 번째 프로젝트 시작하기
- 실습 예제 및 FAQ

### 제2권: GitHub 기본 통합
**파일**: `ccmanual2.docx` (53KB)

- Git 및 GitHub 기본 개념
- **저장소 클론하기** (HTTPS, SSH, GitHub CLI 등 모든 방법)
- Git 설치 및 초기 설정
- 기본 워크플로 (add, commit, push, pull, fetch)
- **커밋 메시지 작성 가이드 및 컨벤션**
- 브랜치 기초 및 관리
- 원격 저장소 동기화
- 충돌 해결 방법
- 실습 예제

### 제3권: GitHub 고급 명령어 및 협업
**파일**: `ccmanual3.docx` (46KB)

- 고급 브랜치 전략 (Git Flow, GitHub Flow, GitLab Flow)
- Rebase vs Merge 상세 비교
- Cherry-pick, Stash 활용법
- Pull Request 작성 및 관리
- 코드 리뷰 프로세스
- GitHub Actions를 활용한 CI/CD
- Git Hooks 활용
- Submodules와 Subtrees
- 팀 협업 워크플로 최적화

### 제4권: MCP 연결 및 설정
**파일**: `ccmanual4.docx` (45KB)

- **MCP (Model Context Protocol) 완전 가이드**
- MCP 아키텍처 및 작동 원리
- **MCP 서버 설치 방법**
  - Filesystem 서버
  - Database 서버 (PostgreSQL, MySQL)
  - GitHub 서버
  - Slack 서버
- **Claude Code와 MCP 연결 설정**
  - settings.json 설정 파일 작성
  - 환경 변수 관리
  - 보안 설정
- 각 MCP 서버 활용 실전 예제
- **커스텀 MCP 서버 개발**
  - Python 예제
  - Node.js/TypeScript 예제
- 디버깅 및 로깅
- 성능 최적화
- 트러블슈팅 가이드

### 제5권: 고급 기능 및 트러블슈팅
**파일**: `ccmanual5.docx` (48KB)

- 고급 프롬프트 엔지니어링
  - Few-Shot Learning
  - Chain-of-Thought Prompting
  - SMART 원칙
- 워크플로 자동화
- 커스텀 명령 작성
- 성능 최적화 기법
- 보안 모범 사례
- 대규모 프로젝트 관리
- 팀 설정 및 정책
- 플러그인 개발 가이드
- API 활용
- 종합 트러블슈팅 가이드
- FAQ

## 🎯 주요 특징

- ✅ **각 권당 50쪽 분량**의 상세한 내용
- ✅ **실용적인 코드 예제** 다수 포함
- ✅ **표, 리스트, 코드 블록** 활용한 전문적인 구성
- ✅ **단계별 실습 가이드**로 쉬운 학습
- ✅ **GitHub 명령어 완벽 정리** (clone, commit, push, pull, branch, merge, rebase 등)
- ✅ **MCP 연결 방법 상세 설명** (설정 파일, 환경 변수, 보안)
- ✅ **한국어로 작성**된 전문 문서

## 🚀 사용 대상

- Claude Code를 처음 시작하는 개발자
- GitHub 통합 기능을 활용하고 싶은 개발자
- MCP 서버를 연결하여 기능을 확장하고 싶은 고급 사용자
- 팀 협업 환경에서 Claude Code를 도입하려는 조직
- 개발 생산성을 극대화하고 싶은 모든 개발자

## 📥 다운로드

각 매뉴얼 파일을 다운로드하여 사용하세요:

1. [제1권: 소개, 설치 및 기본 개념](ccmanual1.docx)
2. [제2권: GitHub 기본 통합](ccmanual2.docx)
3. [제3권: GitHub 고급 명령어 및 협업](ccmanual3.docx)
4. [제4권: MCP 연결 및 설정](ccmanual4.docx)
5. [제5권: 고급 기능 및 트러블슈팅](ccmanual5.docx)

## 💡 활용 팁

1. **순서대로 학습**: 제1권부터 순서대로 읽으면 체계적으로 학습할 수 있습니다.
2. **필요한 부분만**: 각 권은 독립적으로 구성되어 필요한 부분만 참고할 수 있습니다.
3. **실습 위주**: 예제 코드를 직접 따라하면서 학습하세요.
4. **북마크 활용**: 자주 참고하는 부분은 북마크하여 빠르게 접근하세요.

## 📝 목차 미리보기

### 주요 Git/GitHub 명령어 (제2-3권)
```bash
# 저장소 클론
git clone <url>
git clone --depth 1 <url>

# 기본 워크플로
git add .
git commit -m "message"
git push origin main
git pull origin main

# 브랜치 관리
git branch <name>
git checkout -b <name>
git merge <branch>
git rebase <branch>

# GitHub CLI
gh repo create
gh pr create
gh pr merge
```

### MCP 연결 예제 (제4권)
```json
{
  "claude.mcpServers": {
    "filesystem": {
      "command": "mcp-server-filesystem",
      "args": ["/path/to/directory"]
    },
    "github": {
      "command": "mcp-server-github",
      "args": ["--token", "${env:GITHUB_TOKEN}"]
    }
  }
}
```

## 🛠️ 기술 스택

- **문서 형식**: Microsoft Word (.docx)
- **작성 도구**: Python + python-docx
- **버전 관리**: Git + GitHub
- **스타일**: 전문적인 기술 문서 포맷

## 📄 라이선스

본 매뉴얼은 교육 및 학습 목적으로 자유롭게 사용할 수 있습니다.

## 🤝 기여

오타나 개선사항을 발견하시면 Issue나 Pull Request를 통해 알려주세요!

## 📞 문의

- GitHub Issues: [이슈 등록하기](https://github.com/phamcucvinh/ccmanual/issues)
- 작성일: 2025년 1월
- 버전: 2.0

---

**⭐ 도움이 되셨다면 Star를 눌러주세요!**

Made with ❤️ for Claude Code developers
