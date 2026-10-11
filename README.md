# extremo-external-proto

**Open gRPC / Protocol Buffer specification for the Extremo external partner API.**

This repository is the source of truth for the **public, externally-published** surface of the Extremo booking platform — the API that third-party partners and integrations call. It is published as an open spec under **Apache-2.0**.

> Status: **early / v1 in progress.**

## Why a separate repo

The Extremo internal protos live in a private monorepo. The external API is deliberately carved out here because:

1. **Anti-corruption boundary.** This module has **no dependency on internal proto modules**, so internal types cannot be imported from these files — `buf build` fails on an unknown import. Internal database shapes (foreign keys, soft-delete flags, audit timestamps, nested internal relations) can never leak into the public contract. The boundary is a CI-enforced invariant, not a convention.
2. **Open spec.** Partners can read the entire contract from one public repo, and Extremo ships the reference implementation (the "open core" / open-protocol playbook).
3. **Independent stability.** `buf breaking` on this repo checks the external API's v1 compatibility (report-only until v1 is released).

The external surface is **authenticated** (per-tenant API key + scopes) and distinct from the internal anonymous `public/` booking-page services.

## Scopes

Each API key is granted a subset of these scopes; every RPC checks the scope it needs.

| Scope | Grants |
|-------|--------|
| `service.read` | Read the tenant's service catalog |
| `tenant.read` | Read the tenant's public profile |
| `availability.read` | Read computed booking availability |
| `book.read` | Read the tenant's bookings |
| `book_event.read` | Read the booking change feed |
| `book.create` | **Create** a booking for a consumer (`CreateBooking`) |
| `book.update` | **Mutate** a booking (`UpdateBooking` / `CancelBooking`) |
| `book.moderate` | **Decide** on a booking as the shop (`AcceptBooking` / `RejectBooking` / `NoShowBooking`) |
| `consumer.read` | Read the tenant's consumers |
| `consumer.write` | Register, update and deactivate the tenant's consumers |
| `service.create` | **Create** a service (`CreateService`) |
| `service.update` | **Change** services and their images (`UpdateService` / `ReorderServices` / the service image RPCs) |
| `tenant.update` | **Change** the shop's settings, profile, address, theme and images |
| `role.read` | List the staff members who can take shifts (`ListStaff`) |
| `attendance.read` | Read staff shifts and their breaks (`ListAttendances`) |
| `attendance.create` | **Create** a shift (`CreateAttendance`) |
| `attendance.update` | **Change** a shift's time, title and breaks |
| `attendance.reassign` | **Move** a shift to another staff member (with `attendance.update`) |
| `attendance.delete` | **Delete** a shift (`DeleteAttendance`) |
| `tenant_design.read` | Read the shop's booking page design |
| `tenant_design.update` | Edit a draft of the shop's booking page design |
| `tenant_design.moderate` | Publish, unpublish and roll back the shop's booking page design |

Booking **writes** (`book.create` / `book.update`) let a partner create, reschedule, and cancel bookings on a consumer's behalf: register the consumer through `ConsumerService` first, then `CreateBooking` takes its `consumer_id`, validates the slot against the tenant's schedule (capacity, staff, business hours, and 30 minutes' notice), and returns the booking. A slot rejection carries a `google.rpc.ErrorInfo` whose `reason` is a `BookingConflictReason` name. Supply an `idempotency_key` to make retries safe, and echo a booking's `updated_at` as `expected_updated_at` on `UpdateBooking` for optimistic concurrency (a mismatch returns `ABORTED`). Consumer contact details are never echoed back in a `Booking` — PII stays server-side.

The shop management RPCs (`ServiceService` writes, `TenantService` writes, `StaffService`, `AttendanceService`) do what the admin UI does. An update changes only the fields set in the request: a field left unset keeps its value, and a field set to `false`, `0` or `""` takes that value. They return these codes:

| Situation | Code |
|-----------|------|
| An id that does not exist, belongs to another tenant, or belongs to another parent (an image of another service, a break of another shift) | `NOT_FOUND` |
| A missing or invalid value (an empty name, an end before its start, a shift outside business hours, a file that is not an image) | `INVALID_ARGUMENT` |
| An `UpdateAttendance` setting `staff_id` while another request moved the same shift to another staff member | `ABORTED` |
| A missing scope | `PERMISSION_DENIED` |
| A missing or invalid API key | `UNAUTHENTICATED` |
| Too many requests | `RESOURCE_EXHAUSTED` |

Give a consumer-facing system a key **without** `book.moderate` and without the shop management scopes (`service.create` / `service.update` / `tenant.update` / `role.read` / the `attendance.*` scopes): accepting, rejecting and recording no-shows are the shop's decisions, as is managing the menu, the staff shifts and the shop's settings. A key cannot tell one consumer from another, so the partner's own server must check that the signed-in consumer owns a booking before it reads, changes or cancels it.

## Layout

```
extremo/
├── msg/external/v1/        # Public DTOs (Service, Booking, TenantProfile, AvailabilitySlot, Staff, Attendance, enums)
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

(A Buf Schema Registry module — `buf.build/threecorp/extremo-external` — and Ruby / Python SDKs are planned.)

## License

[Apache-2.0](./LICENSE).
