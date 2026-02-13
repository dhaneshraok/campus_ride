# Campus Ride Enterprise Roadmap

## P0 Security and Integrity
- Enforce driver single-active-ride in backend writes (Cloud Functions transaction gate).
- Add role-aware App Check and abuse throttling for offer/message/report endpoints.
- Add stricter Firestore field validation for ride state transitions and immutable fields.

## P1 Reliability and Operations
- Add staged environments: `dev`, `staging`, `prod` Firebase projects.
- Add CI gates: `flutter analyze`, tests, rules compile, functions lint/check.
- Add crash and performance monitoring (Crashlytics + traces + alerting).

## P1 Product Data Contracts
- Keep notification/message/ride event types centralized and versioned.
- Add migration scripts for historical notification type normalization.
- Add analytics taxonomy for core lifecycle metrics.

## P2 UX Improvements
- Add per-thread unread indicators in Inbox.
- Add undo window for chat deletion (soft-delete first, hard-delete async).
- Add inbox filters (`Unread`, `Active rides`, `Offers`) and search by user/destination.

## P2 Functional Enhancements
- Driver availability toggle with schedule windows.
- SLA-driven ride matching (distance, ETA, reliability score).
- Dispute flow for cancellations/no-shows with moderation queue.

## P3 Enterprise Admin
- Admin dashboard for reports, bans, appeals, and audit logs.
- Policy engine for campus-specific rules (hours, geofence, role constraints).
- Scheduled data retention and PII cleanup policies.
