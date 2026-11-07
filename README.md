# mach-posix-threads

std's thread backend over `pthread_create`, for loader-hosted linux processes.

A shared library, a dynamic executable or anything that links a C library on
linux is loader-hosted. Thread-locals and C runtime state exist there only on
threads the host creates, so `std.sync.thread.spawn` returns `unsupported` until
a backend is installed. std names no libc symbol, so the backend is this package.
This is the only code in the family that names `pthread_create`.

## Use

Depend on the package and import its module once, anywhere the build reaches.
That puts the backend in the link, and `[link.c]` cascades to the program. It
names the shared C library, found by the link on the system's search path, so a
build needs no C compiler. The program's linux targets state `env = "gnu"`,
which names the loader.

```mach
use posix_threads.backend;
```

A static executable never consults the backend, and darwin and windows have
their own system threads, so the module is empty there. `Config.stack_commit` is
refused as `unsupported`. Exactly one backend belongs in a link. Keep secrets
away from this seam: it is a `#[weak]` call, and constant-time code is not yet
refused for passing one through it. Replacement is link time only, so a shared
library that carries std and spawns has this package in its own link. No other
image can supply it, and `LD_PRELOAD` does not.

`demo/hosted` runs the backend end to end: `demo/hosted/run.sh path/to/mach`.

## Build

```sh
mach dep pull .
mach build .
mach test . --timeout 5m
```

## Workflow

`dev` is the default branch. Work branches from it as `feat/<issue>` or
`fix/<issue>` and merges back through a pull request. `main` only takes release
merges from `dev`. A `hotfix/<issue>` branches from `main` and merges into both.

Both branches require a pull request and a passing `gate` check. Neither can be
deleted or force-pushed, and pull requests merge with a merge commit. Repository
admins can bypass these rules to cut a release. Once a `v*` tag is pushed, only
an admin can move or delete it.

Commits follow [Conventional Commits](https://www.conventionalcommits.org), with
the issue number as the scope: `fix(#12): reject a negative length`.

Issues are labeled on independent axes:

| axis | labels |
| --- | --- |
| semver magnitude | `patch`, `minor`, `major` |
| kind of work | `feature`, `fix`, `removal`, `chore`, `performance` |
| where, omitted for core code | `testing`, `tooling`, `doc` |
| severity and state | `critical`, `blocked`, `parked`, `security` |
| discussion | `discussion` |

## CI

`.github/workflows/ci.yml` runs on pull requests, on Linux. It checks formatting,
builds every target and runs the unit tests of the host target, where a test
thread goes through the backend. Nothing runs under emulation.

To test on other hosts before merging, such as a darwin-specific change, dispatch
it on the branch: `gh workflow run CI --ref <branch> -f runners='["macos-15"]'`.
A project whose primary host is not Linux changes the default runner list in the
`test` job's matrix.

CI checks that the project builds and its unit tests pass. Integration, load or
demo suites are not CI jobs. Run them locally.

`gate` is the check the branch rules require. It fails if any job it needs
failed or was cancelled.

The compiler is `MACH_REF`, a mach commit, in `ci.yml` until a 7.x release
exists. `cd.yml` still names `MACH_VERSION`, an exact release, and moves to one
then. Change either together with the `mach` range in `mach.toml`.

## Releases

1. Set `version` in `mach.toml` and merge that into `dev`.
2. Merge `dev` into `main`.
3. Tag `main` and push the tag: `git tag vX.Y.Z && git push origin vX.Y.Z`.

`.github/workflows/cd.yml` checks that the tag matches the manifest version,
runs CI in the release profile on every host the project ships to (the
`runners` list in `cd.yml`, trimmed to the targets it declares), cross-builds
every artifact for every target in release, and publishes a GitHub release. Each artifact is packaged per target
(`.zip` for Windows, `.tar.gz` elsewhere) with `SHA256SUMS`. Names and paths come
from `mach build --plan`, so a new target or artifact needs no workflow change.
The notes are the version's `CHANGELOG.md` section, or generated from merged pull
requests when there is none. A tag with a prerelease part, such as `v1.0.0-rc.1`,
is published as a prerelease.

## License

MIT. See [LICENSE](LICENSE).
