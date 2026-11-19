<!-- Kingdom Goods | Detailed daily implementation roadmap | v1.0 | 2026-11-16 -->
# Kingdom Goods — Detailed Daily Implementation Roadmap

**Project:** Christian three-tier full-stack e-commerce.  
**Stack:** React/TypeScript + Nginx → one modular Go/Fiber backend → RDS MySQL.  
**Domain:** kingdomgoods.store, purchased through Hostinger.  
**Primary region:** us-west-2. CloudFront viewer certificates are the us-east-1 exception.  
**Plan basis:** Kingdom Goods architecture v1.2 and Four-Week Implementation Roadmap v1.0.  
**Execution status:** Planned. This document does not claim that tasks have been completed.

## How to use this plan

This is a **28-calendar-day plan**, with **20 primary build days and eight buffer/review days**. Calendar Day 8 is the first build day of Week 2; it corresponds to implementation Day 6 in the earlier overview. Numbering below always means calendar day.

Use relative days so the plan can start on the chosen kickoff date. Allow approximately 7–9 focused hours per primary build day, or 35–45 hours per week. Review/buffer days are not extra mandatory feature days; use them for failed gates, provider delays and rest. If primary work consistently exceeds that allowance, remove expansion work or move the release date rather than skipping correctness checks.

**Four-week deliverable:** an evidence-backed, production-configured **sandbox release candidate** with isolated dev/prod environments, safe checkout, repeatable delivery, operational visibility and recovery. Live commercial payments, shipping and tax operations are separate launch work.

**Working defaults to confirm on Day 1:** Cognito customer identity; Stripe hosted sandbox checkout; separate dev/prod AWS accounts and clusters; small dev footprint; production three-AZ application placement and RDS Multi-AZ. Budget, notification destination and instance sizes remain decisions, not assumed approvals to spend without a limit.

**Daily workflow:** prerequisite check → implement in the listed order → meaningful validation → PR/commit → short implementation summary → evidence and next dependency. Use Git Bash in VS Code on Windows for execution commands. Add header comments to authored configuration/code files and explain commands with comments. Never include credentials, unredacted tokens or customer data in evidence.

**Definition of done for a primary build day:** the listed behavior works, required checks pass, changes are versioned and the next day can proceed without guessing. A list of Running pods alone is not application validation.

## Schedule at a glance

| Week | Primary build days | Buffer/review days | Weekly result |
|---|---|---|---|
| 1 | 1–5 | 6–7 | Secure infrastructure and working platform access |
| 2 | 8–12 | 13–14 | Branded dev storefront over HTTPS with secure identity and persistent carts |
| 3 | 15–19 | 20–21 | Correct sandbox checkout, durable events, cache, scaling and observability |
| 4 | 22–26 | 27–28 | Isolated production configuration, validated release, recovery evidence and handoff |

## Week 1 — Repository, bootstrap, identity, networking and EKS

### Day 1 — Establish the project and local baseline

**Goal:** understand what works before changing branding or provisioning AWS infrastructure.  
**Prerequisites:** access to the starter repository, GitHub account, Docker and the chosen local development tools.

**Implementation order**

1. Create the Kingdom Goods working repository from the reviewed ShopVerse starter. Preserve upstream attribution and record the starting commit.
2. Inventory frontend, backend, schema, Helm, Terraform and workflow files. Create a defect backlog covering product authorization, JWT defaults, monetary arithmetic, checkout races, migrations and release weaknesses.
3. Run the unchanged application locally using Docker Compose. Exercise registration/login, products, carts and the existing order path with disposable data.
4. Record environment/version requirements; select compatible pinned versions rather than copying the starter's version labels blindly.
5. Confirm AWS account boundaries, budget ceiling, Cognito/Stripe choices, notification destination, domain naming and workload/recovery targets. Record decision owners and blockers.
6. Establish PR protections where supported, a basic lint/test workflow, project directories and the evidence convention.

**Deliverables:** repository baseline; `docs/decisions/`; `docs/validation/day-01.md`; initial issue list; version matrix. Paths are proposed and may follow the existing repository.

**Validation / done:** another local startup reproduces browse/cart behavior; secrets are excluded from Git; baseline defects are documented; account/budget/provider decisions needed for provisioning are resolved or explicitly block their dependent tasks.

### Day 2 — Bootstrap Terraform, identities, audit and DNS

**Goal:** establish trusted access and start DNS/certificate lead time early.  
**Prerequisites:** Day 1 account/budget decisions and Hostinger domain access.

**Implementation order**

1. Bootstrap Terraform state storage with S3 versioning, KMS encryption, restricted policies and native state locking using a compatible Terraform version.
2. Configure operator access through IAM Identity Center or the documented existing SSO arrangement. Separate administrative, read-only and workload roles.
3. Create GitHub OIDC trust scoped to the adopted repository/environment; separate infrastructure and artifact-publishing permissions.
4. Enable baseline CloudTrail audit capture; configure cost tags and budget alerts. Start Config/GuardDuty/Security Hub definitions, completed on Day 5.
5. Inventory existing domain records. Create the Route 53 hosted zone, reproduce records that must survive, and set Hostinger nameservers to the returned delegation values. Check parent DS/DNSSEC compatibility before changing delegation.
6. Request DNS-validated ACM certificates: CloudFront coverage in us-east-1; dev/prod ALB origin coverage in us-west-2. Prefer explicit hostnames and record renewal ownership.

**Deliverables:** `terraform/bootstrap/`; identity/OIDC configuration; DNS/certificate configuration; state-access and domain records inventory.

**Validation / done:** allowed identities can access their intended state; an unauthorized identity cannot; concurrent Terraform operations contend on the same state lock; public DNS delegation is verified or propagation is tracked; certificate validation records are correct; no AWS access keys are stored in GitHub for this workflow.

### Day 3 — Build the VPC and private administration path

**Goal:** provide the network boundaries required by EKS, RDS and operators.  
**Prerequisites:** working Terraform backend and identities.

**Implementation order**

1. Define a non-conflicting CIDR plan and three-AZ subnet layout for public ingress/egress, private applications and private data.
2. Create VPC, IGW, routes, subnet tags, security groups and VPC Flow Logs through Terraform.
3. Implement per-AZ production NAT configuration and the documented dev cost variant. Add S3 gateway and selected interface endpoints based on actual access needs and cost.
4. Define explicit ALB-to-app, app-to-DB/cache and controller/service endpoint access. Keep database and worker ingress private.
5. Implement the selected operator access path, such as Client VPN or an SSM-managed administration host without public SSH.
6. Document how Terraform/Helm runners reach private Kubernetes APIs. Do not depend on an in-cluster runner to bootstrap its own cluster; establish the bootstrap runner/access path first.

**Deliverables:** VPC module, environment inputs, route/security-group matrix and private access runbook.

**Validation / done:** intended private connectivity and outbound dependencies work; data subnet routes and firewall rules match the design; no public MySQL access exists; dev/prod network/state inputs are separate.

### Day 4 — Provision the dev EKS baseline

**Goal:** run a reachable, private-worker Kubernetes platform.  
**Prerequisites:** Day 3 networking and operator/runner access.

**Implementation order**

1. Provision the dev EKS cluster with the selected supported Kubernetes version, private API access and control-plane logging.
2. Create a managed system node group in private subnets and establish workload/system scheduling conventions.
3. Configure EKS access entries, least-privilege Kubernetes RBAC and break-glass recovery documentation.
4. Install compatible VPC CNI, CoreDNS, kube-proxy and Pod Identity Agent add-ons. Restrict workload access to node credentials as appropriate.
5. Configure controller workload roles through supported Pod Identity integrations; use a documented alternative only where integration compatibility requires it.
6. Add EBS CSI and encrypted storage configuration where platform volumes require it. Run a disposable workload to check DNS, networking, image pull and storage as applicable.

**Deliverables:** EKS module; access definitions; add-on configuration; baseline validation record.

**Validation / done:** nodes/add-ons are healthy; private API access works from the selected path; unprivileged identities cannot administer the cluster; workload DNS/image pulls succeed; any required PVC binds and the test data is cleaned up.

### Day 5 — Install controllers and establish platform ownership

**Goal:** prepare infrastructure services for application delivery.  
**Prerequisites:** healthy EKS and correct workload IAM roles.

**Implementation order**

1. Create ECR repositories with immutable image handling, scan/lifecycle policies and narrowly scoped publishing access.
2. Install AWS Load Balancer Controller and test target/ALB reconciliation with a disposable service.
3. Install External Secrets and validate a test Secrets Manager value synchronizes without exposing it in output.
4. Install metrics-server and confirm resource metrics are available.
5. Bootstrap Argo CD with scoped repository access, projects and namespaces. Record which platform resources Terraform owns and which Argo CD will own.
6. Complete planned GuardDuty, Config and Security Hub baselines with scoped recording, retention and cost settings. Inspect actual health/findings; do not treat enablement as full compliance.

**Deliverables:** platform configuration, ECR resources, secret-access test, GitOps bootstrap and governance baseline.

**Validation / done:** each controller is ready and performs its intended function; GitOps credentials are protected; no resource has competing Terraform/Argo ownership; a Terraform re-plan has no unexplained changes.

### Day 6 — Infrastructure buffer and defect closure

**Goal:** remove foundation blockers without expanding scope.

**Tasks in priority order:** resolve DNS/certificate delays; repair private access, IAM or add-on failures; repeat failed Day 2–5 checks; remove disposable ALB/PVC/test resources; inspect costs. If the gate already passes, use this day for rest or documentation.

**Output / done:** blocker list is empty or explicitly prevents Week 2; certificates required for public dev exposure have a clear path to issuance; infrastructure evidence is reproducible.

### Day 7 — Week 1 review and checkpoint

**Goal:** confirm the platform can support the application securely.

**Review:** state recovery/locking; DNS and issued certificates; private access; negative RBAC/IAM checks; controller behavior; audit visibility; budget notification receipt. Tag or record the foundation checkpoint and summarize decisions, costs and residual risks.

**Week 1 gate:** no unresolved identity/network/controller blocker. Do not advance dependent work on the assumption that a resource will eventually become healthy.

## Week 2 — RDS, identity, storefront, CI/GitOps and public dev edge

### Day 8 — Move data to RDS and introduce controlled migrations

**Goal:** make MySQL a managed, private transactional service.  
**Prerequisites:** Week 1 gate; schema design includes the identity model selected on Day 1.

**Implementation order**

1. Provision dev RDS MySQL in private DB subnets with TLS, KMS, backup retention and connection limits; define the production Multi-AZ variant in shared modules now.
2. Create separate runtime and migration database permissions; distribute credentials through Secrets Manager/External Secrets.
3. Add versioned migrations for customers/identity subjects, products/variants, carts, stock, reservations, orders/items, provider references, idempotency, processed events and outbox records.
4. Define exact money representation, indexes/uniqueness and state constraints. Seed only controlled demo data; separate seeds from every application startup.
5. Remove production auto-migration/automatic seeding from application replica startup. Add a migration job with explicit release ordering and failure handling.
6. Add bounded connection pools, database timeouts, structured request logs and distinct liveness/readiness behavior.

**Deliverables:** RDS and secret configuration; `backend/migrations/`; migration job template; database access/runbook.

**Validation / done:** an empty DB migrates reproducibly; runtime credentials cannot perform migration-only actions; TLS connections succeed; failed migrations prevent release; DB unavailability changes readiness while liveness does not create an avoidable restart loop.

### Day 9 — Implement identity, administrator permissions and ownership

**Goal:** secure the application before making it public.  
**Prerequisites:** migrated customer schema; confirmed identity provider.

**Implementation order**

1. Provision Cognito user pool/app client and approved callback/logout URLs for local/dev and future prod; use authorization code + PKCE for the browser client.
2. Implement the chosen session/token handling, expiry and sign-out behavior. Remove development JWT fallback secrets and do not trust an unverified browser user object.
3. Validate access-token signing keys, algorithm, issuer, token use, expiry, intended client and scopes/resource audience where configured. Map the verified subject to an internal customer ID.
4. Enforce administrator authorization for product writes and customer ownership on cart/order access. Never accept the request body's user ID as authority.
5. Bound input quantities/lengths, paginate lists and sanitize error responses. Configure rate-limit strategy and secure browser headers.
6. Add negative tests for anonymous writes, ordinary-user admin actions, cross-customer requests, malformed/expired/wrong-pool tokens and missing required configuration.

**Deliverables:** identity IaC, auth middleware, authorization policy, customer mapping, frontend auth integration and negative-test suite.

**Validation / done:** intended users can sign in; all negative tests deny access; product creation actually requires admin authority; user A cannot read/change user B's data; missing identity configuration fails safely. [R1]

### Day 10 — Build the Kingdom Goods shopping experience

**Goal:** replace generic demo branding with the agreed Christian store.  
**Prerequisites:** working authenticated API and product model.

**Implementation order**

1. Apply Kingdom Goods branding, navigation, responsive layout and consistent product presentation.
2. Introduce TypeScript in touched frontend modules while preserving a reproducible build; do not add a Next.js migration to this sprint.
3. Create at least three demo products in each of the seven collections: Bibles, devotionals, prayer journals, apparel, jewelry, gifts and home décor.
4. Implement product/variant details, search/filter basics, availability display, cart quantity changes and customer order views. Keep price/stock authority in the API.
5. Place owned/licensed/demo product assets in private S3; define CDN-compatible asset paths. Add empty/error/loading/out-of-stock states.
6. Validate mobile layout and basic keyboard navigation. Keep checkout clearly staged until the payment path exists.

**Deliverables:** branded React frontend, typed API models, controlled catalog seed and asset manifest.

**Validation / done:** all seven categories render; products/cart match the API; refresh/relogin preserves server-side carts; invalid quantities cannot bypass backend rules; build and meaningful UI checks pass.

### Day 11 — Complete immutable CI and GitOps delivery

**Goal:** release traceable artifacts without manual cluster edits.  
**Prerequisites:** application builds and tests; ECR/Argo foundation.

**Implementation order**

1. Expand PR checks to Go/frontend tests, dependency/secret scanning, Terraform checks and Helm rendering/validation.
2. Build each application image once, scan that artifact and publish its immutable digest to ECR. Produce an SBOM and record provenance; evaluate findings under the documented policy.
3. Package/version Helm charts; externalize configuration, resource sizing, probes and service accounts without embedding secret values.
4. Define dev GitOps desired state using the tested frontend/backend digests and chart version.
5. Configure Argo CD sync health and migration sequencing. Retain prior working configuration and use compatible schema changes.
6. Test a successful release, a deliberately failing application release in dev and a Git-based application rollback. Infrastructure apply remains a separate workflow.

**Deliverables:** CI workflows, chart updates, dev GitOps configuration, release manifest containing commit/digests/chart/schema version.

**Validation / done:** EKS runs the exact scanned images; failed required checks block release; no long-lived AWS workflow keys; an application rollback recovers service without pretending to undo destructive schema changes.

### Day 12 — Launch the dev storefront through the secure edge

**Goal:** expose the functioning store at dev.kingdomgoods.store.  
**Prerequisites:** issued certificates, GitOps deployment and working login/cart.

**Implementation order**

1. Configure HTTPS ALB listeners and paths for frontend and /api; keep application services internal.
2. Configure CloudFront origin names/TLS so ALB certificate validation and forwarded host behavior are consistent.
3. Attach WAF with observed managed/rate rules; configure private S3 OAC access for assets/media.
4. Create separate cache behaviors for assets, suitable public catalog content and uncached authenticated/transactional endpoints. Forward required auth headers, cookies and query strings.
5. Restrict origin bypass using appropriate CloudFront origin-facing source controls plus a validated custom origin header. Do not expose public worker NodePorts.
6. Publish dev DNS; verify Cognito redirects, same-origin API calls, browser headers, direct-origin rejection and cross-user cache isolation. Reserve an uncached webhook path for Week 3.

**Deliverables:** edge/DNS IaC, cache/origin policy, working HTTPS dev URL and edge validation report.

**Validation / done:** external browser sign-in → browse → cart works over HTTPS; direct origin and anonymous S3 access fail as intended; one customer's private response is never served to another; WAF permits legitimate flows.

### Day 13 — Dev integration buffer

**Goal:** fix end-to-end integration defects before checkout implementation.

**Tasks in priority order:** resolve TLS/redirect/cookie/header problems; validate migrations on a fresh disposable dev database; repeat negative auth/cache tests; repair CI/reconciliation drift; clean test artifacts and inspect costs. Do not spend this day adding unrelated storefront features.

**Output / done:** repeatable dev deployment and stable customer sign-in/cart path; no security blocker waiting for Week 3.

### Day 14 — Week 2 review and checkpoint

**Goal:** prove the secure dev storefront is ready for transactional checkout.

**Review:** sign in as two users; browse all collections; update carts; replace a backend pod and verify persistence; deny cross-user/admin access; inspect the release manifest and GitOps health; review logs without secrets; confirm MySQL/private-origin boundaries.

**Week 2 gate:** dev HTTPS, identity, durable cart, migrations and immutable release/rollback are proven. Save the dev-storefront checkpoint and a short demonstration.

## Week 3 — Checkout correctness, payments, events, cache and reliability

### Day 15 — Implement transactional checkout and inventory reservations

**Goal:** prevent overselling and duplicate logical orders.  
**Prerequisites:** Week 2 gate; indexed inventory/order/idempotency schema.

**Implementation order**

1. Define order and reservation states and allowed transitions. Set reservation expiry and the payment/expiry conflict policy.
2. Compute prices/totals server-side using exact money representation; reject unsupported variants and invalid quantities.
3. Scope a unique idempotency key to the customer and operation; return the same logical result for matching retries and reject conflicting payload reuse.
4. Use row locks or conditional atomic inventory updates in a documented transaction strategy. Include consistent cart reads and protect concurrent cart changes.
5. Create pending order/items, reservations and the initial outbox record atomically. Handle begin, write and commit failures explicitly.
6. Implement safe release of expired unpaid reservations. Prepare automated contention, retry and transaction-failure tests before attaching a payment provider.

**Deliverables:** checkout module, state machine, reservation worker logic, migration adjustments and concurrency tests.

**Validation / done:** 20 test buyers competing for five units cannot reserve/sell more than five; inventory never goes negative; a repeated key yields one logical order; transaction failure leaves no partial order or incorrect cart deletion.

### Day 16 — Integrate Stripe sandbox and reconcile payment events

**Goal:** make payment confirmation reliable despite retries and network failures.  
**Prerequisites:** correct reservation/order behavior and Stripe sandbox access.

**Implementation order**

1. Create hosted Checkout sessions after the DB transaction commits, using stable provider idempotency. Store the provider/session reference.
2. Send only server-calculated product/price/quantity information. Start with an explicit set of supported payment methods and sandbox-only credentials.
3. Expose the uncached webhook route through CloudFront/ALB and verify signatures against the raw body. Apply WAF exceptions narrowly if legitimate webhooks require them.
4. Verify payment identity, expected amount/currency, actual payment status and allowed order state. Persist provider event deduplication and order changes transactionally.
5. Reconcile provider API timeout, duplicate/out-of-order events, webhook delay and payment-versus-expiry races. Define late-payment handling rather than silently losing funds or overselling.
6. Treat redirects as customer navigation; only verified payment processing establishes the paid state. Keep raw card data outside the application.

**Deliverables:** payment adapter, webhook handler, sandbox configuration, reconciliation logic and event test fixtures.

**Validation / done:** success, decline, duplicate webhook, invalid signature, API timeout and late-event tests pass; paid/fulfilled transitions occur once; an unpaid session or mere success-page visit cannot create a paid order. [R3]

### Day 17 — Implement outbox, SQS, workers and notifications

**Goal:** keep downstream work durable without holding checkout open.  
**Prerequisites:** order/payment events and outbox transaction design.

**Implementation order**

1. Provision SQS and DLQ configuration with encryption, access policy, visibility timeout, retry thresholds and retention.
2. Implement an outbox relay that selects committed events safely, publishes them and records publication; handle multiple relay replicas and crash/retry windows.
3. Implement worker processes from the same Go codebase with durable event deduplication and acknowledgment only after the required durable work completes.
4. Add simulated fulfillment and customer notification processing. Use SES sandbox/verified recipients or a captured test sink while provider access is pending.
5. Add queue depth/age/DLQ telemetry, controlled replay tooling and event correlation IDs. Account for ordering/version checks where order matters.
6. Kill/restart the relay and worker at selected failure points; inject a poisoned event and verify it reaches the DLQ and can be recovered deliberately.

**Deliverables:** queue IaC, relay/consumer entrypoints, event schema, notification integration and retry/replay runbook.

**Validation / done:** a committed order is eventually processed after a temporary failure; rolled-back transactions publish no event; duplicates cause no duplicate fulfillment; DLQ/replay tests pass. For external notifications, state any provider-level duplicate-delivery limitation rather than claiming distributed exactly-once delivery. [R4]

### Day 18 — Add cache and complete telemetry

**Goal:** improve catalog performance while making failures diagnosable.  
**Prerequisites:** working checkout/events; basic logs/readiness from Week 2.

**Implementation order**

1. Provision dev ElastiCache/Valkey privately and add bounded, timeout-aware cache-aside reads for suitable public catalog data.
2. Define cache keys, TTL, invalidation and fallback; keep authoritative inventory and checkout transactions in MySQL.
3. Deploy resource-bounded OpenTelemetry collectors, Prometheus and Grafana; integrate CloudWatch logs and AWS metrics with retention limits.
4. Instrument request/checkout latency, errors, DB pools/locks, reservations, outbox lag, queue age, consumer failures and cache hit/miss behavior.
5. Add node/pod, CoreDNS and available kube-proxy monitoring. Enable available EKS control-plane telemetry without implying direct etcd administration.
6. Create dashboards and trace/log correlation for a successful checkout and an injected failure; remove sensitive fields from logs and labels.

**Deliverables:** cache adapter and IaC, monitoring charts/configuration, instrumentation, dashboards and telemetry retention settings.

**Validation / done:** cache miss/hit/invalidation work; cache outage falls back within bounds without corrupting orders; one request/order can be traced through API and worker evidence; dashboards show the failure's actual dependency.

### Day 19 — Validate scaling, disruption controls and alert delivery

**Goal:** make scaling and incident signals demonstrable.  
**Prerequisites:** telemetry and workload resource baselines.

**Implementation order**

1. Set tested requests/limits, startup/readiness/liveness probes, graceful shutdown and dependency timeouts. Add bounded retries with backoff only where safe.
2. Configure HPA, topology spread and PDBs with enough base replicas/capacity for the intended disruption scenario.
3. Add Karpenter with narrowly scoped roles, node class/pool, allowed capacity types and explicit resource/cost limits. Retain stable managed system capacity.
4. Configure Alertmanager/CloudWatch and SNS routes for API errors/latency, DB pressure, outbox/queue lag and DLQ messages.
5. Generate controlled load and demonstrate pod scale-up plus node provisioning when pending pods require it. Observe scale-down behavior and application health.
6. Perform a safe pod restart or permitted node drain; verify traffic, queue processing and an actual alarm notification. Clean temporary capacity.

**Deliverables:** scaling/disruption manifests, Karpenter configuration, alert rules/routes and scaling/disruption evidence.

**Validation / done:** HPA/Karpenter act for the intended reason, respect bounds and do not evict critical system capacity; customer traffic remains within the tested envelope; a selected failure reaches the chosen alert destination; normal operation recovers.

### Day 20 — Commerce and reliability buffer

**Goal:** close correctness defects before production configuration.

**Tasks in priority order:** fix stock/charge/order-state defects; repeat payment-expiry and duplicate-event tests; recover/replay DLQ scenarios; tune unhealthy probes/limits; verify cache fallback and alert receipt. Visual polish is lower priority than these checks.

**Output / done:** zero unresolved blocking checkout/authorization defects; known nonblocking limits have evidence and owners.

### Day 21 — Week 3 review and release-candidate checkpoint

**Goal:** prove a complete, observable sandbox customer journey.

**Review:** browse → sign in → cart → reserve → hosted sandbox payment → verified paid order → simulated fulfillment/notification. Repeat with failure/retry. Inspect matching database, outbox, queue, trace and log evidence. Re-run the five-units contention test and a duplicate webhook test.

**Week 3 gate:** no overselling or duplicate business transition; retries and replay work; cache, telemetry, scaling and notification routes are demonstrated. Tag the dev release candidate and freeze new features before production rollout.

## Week 4 — Production configuration, promotion, testing and handoff

### Day 22 — Instantiate the isolated production environment

**Goal:** create a production-configured environment using the proven modules.  
**Prerequisites:** Week 3 gate, production account access and agreed cost estimate.

**Implementation order**

1. Reuse the modules/version pins with separate production account, state, identities, data and secrets. Do not share customer/test databases between environments.
2. Provision production network/EKS/control-plane access and controllers using the documented bootstrap/GitOps ownership model.
3. Configure application placement across three AZs with appropriate minimum capacity; use the production NAT/endpoint design.
4. Provision RDS Multi-AZ, TLS, backups/retention, deletion protection and scoped access. Configure any production cache/queues separately.
5. Configure production identity app-client/user-pool boundaries, callback URLs and sandbox payment/notification secrets. Retain the non-live payment mode.
6. Confirm audit/log retention, budgets, tags and private runner/operator access before deploying the candidate.

**Deliverables:** production environment parameters/state, production cost inventory and isolation/access test report.

**Validation / done:** dev identities cannot read production secrets/data or deploy as production; production controllers are healthy; backup/retention/Multi-AZ configuration is verified; recurring costs and any intentional topology exception are explicit.

### Day 23 — Promote tested artifacts and publish the production domain

**Goal:** release the same candidate through the production delivery path.  
**Prerequisites:** Day 22 readiness and recorded dev artifact digests.

**Implementation order**

1. Create the production configuration PR referencing the same frontend/backend digests and tested chart version. Separate required environment values from artifacts.
2. Apply compatible migrations with an application/schema compatibility check and rollback plan; take the required recovery checkpoint.
3. Let Argo CD reconcile application state. Verify rollout health, readiness and service discovery.
4. Configure production CloudFront/ALB/WAF/origin restrictions and private S3 access with the issued certificates.
5. Publish kingdomgoods.store DNS to the production distribution; configure a canonical www redirect only if adopted.
6. Register the production-hosted sandbox webhook endpoint. Re-test anonymous/admin-negative, ownership, direct-origin and cache-isolation behavior plus a complete sandbox purchase.

**Deliverables:** production release record, working domain, smoke/negative-test evidence and candidate rollback reference.

**Validation / done:** external HTTPS journey works; production runs the same tested images; paid state comes from verified sandbox events; direct origin bypass remains rejected. Clearly identify sandbox/demo operation to avoid inviting real purchases.

### Day 24 — Run realistic load and inventory contention tests

**Goal:** measure capacity and expose bottlenecks without exaggerating scale.  
**Prerequisites:** stable candidate, telemetry and isolated test accounts/data.

**Implementation order**

1. Prepare load scripts and test identities; keep payment operations in sandbox. Capture target environment size, data set and test settings.
2. Run a short warm-up, then ramp 10 → 50 → 100 concurrent virtual users. Hold the agreed peak for 15 minutes if the cost/error limits allow it.
3. Use approximately 80% catalog, 15% cart and 5% checkout operations; also execute deliberate hot-product contention separately.
4. Measure achieved request rate, p50/p95/p99 latency, unexpected failures, DB connections/locks, cache ratio, outbox/queue age and scaling behavior.
5. Review WAF/rate-limit effects. Distinguish intentional limits and expected sold-out conflicts from unexpected application failures; do not silently disable protection.
6. Tune a demonstrated bottleneck, rerun the affected workload and retain raw before/after results. Clean load generators/test capacity.

**Deliverables:** reproducible load scripts, raw results, graphs, capacity report and performance defect list.

**Validation / done:** proposed API targets are evaluated: <1% unexpected failures, catalog p95 <500 ms, checkout-initiation p95 <1.5 s excluding external provider latency. Report browser/provider timing separately. If targets fail, fix or document an explicit release limitation; concurrency alone is not a capacity claim.

### Day 25 — Prove failover, restore and rollback

**Goal:** demonstrate recovery rather than just configured backups.  
**Prerequisites:** backups/PITR, recovery credentials, runbooks and a safe test window.

**Implementation order**

1. Record an application/data checkpoint and recovery timestamps. Restore RDS to a separate instance; validate key customer/order/inventory data and application connectivity.
2. Restore a prior version of an S3 object and validate controlled access. Verify retained Terraform state/version recovery steps without corrupting active state.
3. Perform a controlled RDS failover and measure application reconnection, error rate and recovery time. Avoid claiming this proves a complete AZ outage scenario.
4. Exercise pod/node interruption within the chosen disruption budget, worker restart, poisoned message handling and controlled DLQ replay.
5. Roll back a compatible application release through Git; verify customer traffic and order state. State clearly which migrations cannot be reversed automatically.
6. Measure actual RTO/RPO against the proposed ≤60-minute / ≤15-minute goals, record gaps, remove restore resources and reconcile test data.

**Deliverables:** restore/failover/rollback reports, measured recovery times, alert timelines and corrected runbooks.

**Validation / done:** a usable database/object is recovered, application rollback works and data invariants hold; the recorded evidence distinguishes configuration from exercised recovery. Do not overwrite production data for a drill.

### Day 26 — Assemble the release evidence and operator handoff

**Goal:** make the implementation understandable and reproducible by another engineer.  
**Prerequisites:** test results and functioning candidate.

**Implementation order**

1. Review security findings, deployment drift, permissions, secrets, encryption, backup status and costs. Fix release blockers before cosmetic work.
2. Update README with the implemented architecture, prerequisites, Git Bash usage, actual deployment workflow and environment URLs.
3. Update draw.io/source diagrams to match deployed resources; label any planned-only service and known environment exception.
4. Finish deployment, rollback, DNS, identity, secret rotation, incident, queue replay and restore runbooks.
5. Assemble weekly summaries, CI/artifact records, load/recovery reports, dashboard/alert evidence and a short demonstration.
6. Prepare the initial release decision with unresolved items, measured capacity, operating costs and the post-four-week backlog.

**Deliverables:** complete documentation/evidence package and a tagged release candidate where gates permit.

**Validation / done:** another operator can follow the documented path without relying on this chat; no unsupported production/scale claim appears in the README; blockers remain explicit rather than hidden by a release tag.

### Day 27 — Final defect buffer and regression

**Goal:** reserve time for findings from load, recovery and handoff.

**Tasks in priority order:** repair correctness/security/recovery blockers; rerun affected checks; verify compatible rollback after fixes; confirm temporary load/restore resources are removed; recheck domain/certificates, alarms and costs. Avoid adding new services.

**Output / done:** final candidate manifest and updated evidence; remaining nonblocking issues are prioritized with owners. If a blocking defect remains, postpone the release decision.

### Day 28 — Final acceptance, demonstration and next increment

**Goal:** close the four-week implementation honestly and provide a usable handoff.

**Final review order**

1. Demonstrate the HTTPS customer journey and admin/customer access boundaries.
2. Show matching Git commit, tested digests, chart/schema version, Argo CD health and environment isolation.
3. Present contention, webhook deduplication, queue replay, scaling, alert delivery, load and recovery results.
4. Confirm monitoring/runbooks/ownership, billable resources and budget controls; state measured limits and residual issues.
5. Record go/no-go for the production-configured sandbox release. If mandatory gates fail, record no-go and the recovery plan instead of declaring success.
6. Prioritize the next increment: OpenSearch, conditional DynamoDB/EventBridge needs, then separately scoped live-commerce operations.

**Done:** a repeatable, documented, tested three-tier sandbox release is available at kingdomgoods.store, or the exact remaining blockers are recorded. Four weeks alone does not establish live commercial readiness or massive-customer capacity.

## Mandatory final acceptance checklist

- [ ] kingdomgoods.store and dev.kingdomgoods.store resolve to their intended HTTPS environments.
- [ ] IaC, accounts/state, application configuration and customer data are separated between dev and prod.
- [ ] CI scanned the exact deployed artifacts; production promotion reused the dev-tested digests.
- [ ] Private workers/data, origin restrictions, secret handling, workload permissions and negative authorization checks pass.
- [ ] All seven collections, sign-in, product/variant selection, persistent cart and order views work.
- [ ] Exact money, stock reservation, idempotency, signed webhooks and payment/expiry reconciliation pass their tests.
- [ ] Durable outbox processing, retry/DLQ/replay and duplicate-safe business outcomes are demonstrated.
- [ ] Cache failure does not corrupt stock/orders or cause uncontrolled database overload.
- [ ] HPA/Karpenter, disruption controls, logs/traces/metrics and a real alert destination work within the tested configuration.
- [ ] Load results, actual capacity boundaries, restore/failover/rollback outcomes and RTO/RPO evidence are retained.
- [ ] README, diagrams, version matrix, runbooks, cost inventory, release manifest and deferred backlog match reality.
- [ ] No blocking authorization, stock/charge integrity, secret exposure or unrecoverable-data defect remains.

## Scope and sequencing rules

**Required in these four weeks:** the three application tiers; secure identity/authorization; Route 53/CloudFront/WAF/ALB/ACM/S3; infrastructure and GitOps delivery; sandbox checkout; RDS; SQS/outbox; Valkey; operational telemetry, access controls and tested recovery.

**After the core release:** OpenSearch indexing/facets/autocomplete. Add DynamoDB only for a justified access pattern, and EventBridge only when event routing needs it. Keep basic catalog search in the release. No service mesh, Kafka, gRPC microservice split, Next.js rewrite, AI remediation or multi-region failover is assumed.

**Separate commercial-launch increment:** live payment configuration, business fulfillment, shipping/tax/refund processes and customer-service operations. A sandbox payment journey does not implement these automatically.

**Budget protection:** finalize spend limits before provisioning; tag resources; cap autoscaling; set log/ECR/S3 retention; clean load/restore resources. Account for EKS control-plane, NAT, RDS, cache and other ongoing managed-service costs even when app pods are idle.

**Managed EKS boundary:** monitor available control-plane signals plus API symptoms, nodes, DNS and exposed kube-proxy telemetry. AWS manages etcd; direct etcd backup/restore and unrestricted etcd internals are not project deliverables. Validate supported networking modes against the actual chosen EKS design rather than forcing IPVS by default.

**When behind schedule:** use the eight buffer/review days, reduce polish and expansion work, and repeat failed checks. Keep authorization, payment/stock correctness, secret handling, isolation and recovery. Record a schedule slip if mandatory gates remain unresolved.

## Evidence convention

Proposed files: `docs/validation/day-XX.md`, `docs/decisions/`, `docs/runbooks/`, `docs/testing/`, `docs/releases/` and the repository's existing architecture location. Each daily record should include objective, prerequisites, changed files/commit, relevant environment, validation command/result, redacted evidence, cost impact, blockers and next step.

Resource ownership stays explicit: Terraform owns AWS infrastructure; Argo CD owns assigned Helm/application releases; GitHub Actions builds/scans/publishes; reviewed Git changes own promotion; versioned migration jobs own schema changes; Secrets Manager owns secret values. Avoid competing tools changing the same desired state.

## References

- [R1: Cognito access-token claims and validation considerations](https://docs.aws.amazon.com/cognito/latest/developerguide/amazon-cognito-user-pools-using-the-access-token.html)
- [R2: EKS Pod Identity and credential isolation](https://docs.aws.amazon.com/eks/latest/userguide/pod-identities.html)
- [R3: Stripe Checkout fulfillment and webhook handling](https://docs.stripe.com/checkout/fulfillment)
- [R4: AWS transactional outbox pattern](https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/transactional-outbox.html)
- [Terraform S3 backend locking/versioning](https://developer.hashicorp.com/terraform/language/backend/s3)
- [CloudFront ACM certificate region](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/cnames-and-https-requirements.html)
- [Hostinger nameserver changes](https://www.hostinger.com/support/1696789-how-to-change-nameservers-at-hostinger/)
