# extremo-external-proto

**Open gRPC / Protocol Buffer specification for the Extremo external partner API.**

This repository is the source of truth for the **public, externally-published** surface of the [Extremo](https://github.com/orgs/threecorp/projects/1) booking platform — the API that third-party partners and integrations call. It is published as an open spec under **Apache-2.0**.

> Status: **early / v1 in progress.** The surface is being built out under [`threecorp/extremo-proto#50`](https://github.com/threecorp/extremo-proto/issues/50) and the Phase E epic [`threecorp/extremo-proto#26`](https://github.com/threecorp/extremo-proto/issues/26).

## Why a separate repo

The Extremo internal protos live in a private monorepo. The external API is deliberately carved out here because:

1. **Anti-corruption boundary.** This module has **no dependency on the internal `extremo-proto` module**, so it is impossible to `import "extremo/msg/db/v1/db.proto"` (or any internal type) from these files — `buf build` fails on an unknown import. Internal database shapes (foreign keys, soft-delete flags, audit timestamps, nested internal relations) can never leak into the public contract. The boundary is a CI-enforced invariant, not a convention.
2. **Open spec.** Partners can read the entire contract from one public repo, and Extremo ships the reference implementation (the "open core" / open-protocol playbook).
3. **Independent stability.** `buf breaking` on this repo gates the external API's v1 compatibility.

The external surface is **authenticated** (per-tenant API key + scopes) and distinct from the internal anonymous `public/` booking-page services.

## Layout

```
extremo/
├── msg/external/v1/        # Public DTOs (Service, Booking, TenantProfile, AvailabilitySlot, Staff, enums)
└── api/external/<svc>/v1/  # External services (REST via google.api.http: /api/external/v1/...)
```

Generated SDKs:

```
externalgo/        # Go
externaltsnode/    # TypeScript (ES + TanStack Query)
lib/               # Dart
```

## Generate

Requires `buf` and `go` (provided by the bundled nix flake via direnv):

```bash
direnv allow      # first time
make lint         # buf lint + build
make protocol     # generate Go / TS / Dart
```

## Consume

Go:

```bash
go get github.com/threecorp/extremo-external-proto@latest
```

```go
import extsvc "github.com/threecorp/extremo-external-proto/externalgo/extremo/api/external/services/v1"
```

(A Buf Schema Registry module — `buf.build/threecorp/extremo-external` — and Ruby / Python SDKs are planned for the reference client at [`threecorp/extremo-spec#7`](https://github.com/threecorp/extremo-spec/issues/7).)

## Related

- Strategy: [`threecorp/extremo-spec#6`](https://github.com/threecorp/extremo-spec/issues/6) (Phase E acceleration), [`#5`](https://github.com/threecorp/extremo-spec/issues/5) (OSS carve-out)
- Roadmap: [`extremo-spec/ROADMAP.md` §7](https://github.com/threecorp/extremo-spec/blob/main/ROADMAP.md)

## License

[Apache-2.0](./LICENSE).
