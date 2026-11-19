<!-- Kingdom Goods | Four-week implementation roadmap | v1.0 | Created 2026-11-16 -->
# Kingdom Goods — Four-Week Implementation Roadmap

**Domain:** kingdomgoods.store — purchased through Hostinger, confirmed by owner.  
**Primary AWS region:** us-west-2 (Oregon).  
**Architecture:** React / TypeScript → one modular Go/Fiber backend → RDS MySQL.  
**Source:** ShopVerse starter; architecture diagram v1.2, including checkout and operations detail pages.  
**Status:** Implementation plan. Domain purchase is confirmed; deployment and operational controls are not yet verified.

## 1. Outcome and planning assumptions

Deliver a production-oriented release candidate with an isolated dev environment, a production-configured environment, reproducible infrastructure, GitOps delivery, a branded storefront, secure customer access, correct sandbox checkout, operational visibility, and tested recovery. Keep the three-tier design: background workers share the Go codebase; they do not imply a microservice rewrite.

The plan contains **20 focused implementation days across four weeks**, with remaining days available for rest, catch-up, DNS/provider delays and defects. A reasonable planning allowance is **35–45 focused hours per week** for one engineer using the existing application. This is an estimate, not a completion guarantee. If availability is lower, move optional work out; do not remove authorization, checkout correctness or recovery gates.

The four-week release uses **Stripe sandbox payments and simulated fulfillment**. It is not automatic authorization to accept real payments or ship real orders. A large-customer-capacity claim requires measured evidence beyond the initial load targets.

### Planning choices to resolve on Day 1

| Decision | Working baseline | Required resolution |
|---|---|---|
| Customer identity | Cognito, authorization code + PKCE | Confirm service choice and session/token design before implementation |
| Payments | Stripe hosted checkout, sandbox only | Confirm account access and sandbox credentials; no live keys |
| Environments | Separate dev/prod AWS accounts, clusters, state and data | Confirm account availability and budget; document any weaker isolation as an exception |
| Budget | Smaller dev footprint; production topology sized explicitly | Set an actual monthly ceiling, initial estimates and budget alarm destinations before provisioning |
| Production availability | Three-AZ application placement, RDS Multi-AZ | Confirm affordable initial node and database sizes |
| Scope | Core commerce + cache + messaging + observability | OpenSearch and conditional integrations follow the four-week core |
| Notification destination | Owner-selected email or incident endpoint | Verify receipt of a test alarm during implementation |

**Scheduling rule:** complete each weekly gate before promoting the next release. A failed gate becomes the next work item; a date does not substitute for a passing check.

## 2. Four-week overview

| Week | Implementation focus | Demonstrable outcome | Exit gate |
|---|---|---|---|
| **1 — Foundation** | Repository, bootstrap, identity, DNS, network, EKS, platform access | Reproducible private-node EKS platform; delegated DNS and issued certificates; core controllers healthy | Trusted operator access works, unauthorized access is denied, baseline infrastructure is reconciled |
| **2 — Secure dev storefront** | RDS, secrets, migrations, customer identity, branding, CI/GitOps, edge | HTTPS dev storefront can sign in, browse products and manage a persistent cart | Auth and ownership tests pass; deployment comes from Git; origin access and private data boundaries are verified |
| **3 — Correct commerce** | Checkout, reservations, payment webhooks, outbox/SQS, cache, scaling and telemetry | Sandbox purchase flows to a durable order, asynchronous processing and observable outcomes | No duplicate processing or overselling in contention tests; queue retry/replay and autoscaling are demonstrated |
| **4 — Release validation** | Isolated production configuration, artifact promotion, load/failure/restore tests, documentation | Tested release candidate at kingdomgoods.store, with recovery and operations evidence | Release checklist passes and measured limitations are documented |

## 3. Week 1 — Bootstrap, identity, DNS, networking and EKS

**Goal:** establish a secure, repeatable platform before placing customer data or public applications on it.

| Day | Work | Deliverable and verification |
|---|---|---|
| **1 — Baseline and decisions** | Create the Kingdom Goods working repository from the reviewed starter; record upstream commit and preserve attribution. Run the existing app locally with Docker Compose. Capture current behavior and defects. Set dev/prod account boundaries, budget, identity/payment choices, workload targets and a pinned tool/version matrix. Create GitHub environments, protected branches and initial PR checks. | Baseline screenshots and smoke results; decision records; initial backlog; working local React/Go/MySQL path. Customer product creation is identified as an authorization defect, not accepted behavior. |
| **2 — State, access and DNS** | Bootstrap encrypted/versioned S3 Terraform state with locking and scoped access. Establish operator SSO, GitHub OIDC roles, separate infra/publish permissions, budget alerts and audit logging. Create the Route 53 hosted zone; inventory any existing MX/TXT/CAA records before delegation. Update Hostinger nameservers to the returned Route 53 values. Check DNSSEC/DS compatibility. Request DNS-validated certificates early. | Backend locking and state recovery demonstrated; owner can assume intended roles; delegation resolves through public DNS. ACM requests cover chosen dev/prod/origin names. Preserve working mail records. |
| **3 — Network and private connectivity** | Terraform a VPC with public, private application and private data subnets across three AZs; routes, security groups and flow logs. Define per-AZ production NAT and selected VPC endpoints; document any dev cost trade-off. Implement the chosen controlled operator/runner path to private EKS APIs. | Network plan and apply evidence; private administration/runner reachability tested. Public database/worker access is absent. No circular dependency on an in-cluster runner to create the cluster. |
| **4 — EKS baseline** | Provision the dev cluster and managed system node group. Configure EKS access entries/RBAC, control-plane logging, managed add-ons and Pod Identity. Enable EBS CSI only where required by platform storage. Establish image-pull access and the system/workload placement model. | Nodes and add-ons healthy; private API access works from the chosen access path; an unprivileged identity cannot administer the cluster. Pin and document compatible versions. |
| **5 — Controllers and platform gate** | Install AWS Load Balancer Controller, External Secrets, metrics-server and Argo CD through explicitly owned bootstrap/platform configuration. Create ECR image/chart repositories with immutability and lifecycle policies. Set secrets access scopes. Enable planned GuardDuty, Security Hub and Config baselines with cost-aware scope. | Controllers ready; test secret synchronization works without printing values; Argo CD has scoped repository/project access. Terraform baseline has no unexplained changes. Capture the Week 1 validation summary. |

### Week 1 acceptance gate

- [ ] AWS identities, regions and account boundaries match the approved design.
- [ ] Terraform state is encrypted, versioned and locked; no state or credentials are committed to Git.
- [ ] Route 53 delegation resolves; required certificates are issued or a tracked DNS blocker exists that is resolved before Week 2 exposure.
- [ ] EKS workers are private; approved operators/runners have a working private connectivity path.
- [ ] RBAC/Pod Identity and controller health checks pass; audit and budget alert destinations are verified.
- [ ] Bootstrap and workload configuration have one clear owner each; Terraform and Argo CD do not compete for the same resources.

**Certificate placement:** CloudFront viewer certificates use ACM in **us-east-1**. ALB certificates use **us-west-2**. This is a certificate exception, not a second application region. [1]

**Terraform locking:** use native S3 lockfiles (`use_lockfile = true`) with a compatible pinned Terraform version. Do not add a DynamoDB locking table by habit. [2]

## 4. Week 2 — Managed data, secure identity, storefront and dev delivery

**Goal:** make the branded dev store available securely before adding payment complexity.

| Day | Work | Deliverable and verification |
|---|---|---|
| **6 — RDS, secrets and schema** | Provision dev RDS MySQL in private data subnets with encryption, TLS and automated backups; define production Multi-AZ configuration. Move DB credentials to Secrets Manager. Add versioned migrations for catalog/variants, carts, inventory, reservations, orders, payment references, idempotency, outbox and processed events. Remove per-pod production auto-migration and demo seeding. Add structured logs and DB readiness checks now. | App connects with least-privilege credentials over TLS. Clean database migrates successfully; an incompatible migration fails the release. Seed data is a controlled dev job. Only application roles/network paths can reach MySQL. |
| **7 — Customer identity and authorization** | Integrate the confirmed identity provider. For Cognito, implement code + PKCE and the chosen token/session handling; validate issuer, signing keys, token use, client/audience binding as appropriate and expiry. Replace the weak JWT fallback. Add administrator authorization, cart/order ownership checks, input bounds and login/API rate controls. | Anonymous and non-admin product writes are denied. User A cannot access or modify user B's cart/orders. Missing secrets fail startup. Login, expiry and sign-out behavior are tested. |
| **8 — Kingdom Goods storefront** | Apply branding; introduce TypeScript incrementally without a Next.js rewrite. Create at least 21 demo products across the seven agreed collections. Support variants where needed, stock-aware purchase controls, search/filter basics, product details, cart and account/order views. Store approved product images in private S3 and reference CDN paths. | Responsive catalog/cart flows work for Bibles, devotionals, prayer journals, apparel, jewelry, gifts and home décor. Error/empty/loading states and a basic keyboard navigation check pass. Inventory is controlled by the backend. |
| **9 — CI, artifacts and GitOps** | Expand PR checks: Go tests, frontend lint/build, integration tests, Terraform/Helm validation, dependency/secret/container scanning. Build an immutable image, scan that exact artifact and publish it to ECR; record SBOM/provenance. Package/version Helm charts. Define dev desired state in Git and let Argo CD reconcile. Run migrations with explicit deployment ordering. | A reviewed commit produces traceable frontend/backend digests and a chart version. EKS runs those digests. A compatible Git revert restores the previous application release. No long-lived AWS keys or raw secrets in workflow logs. |
| **10 — Edge and HTTPS dev launch** | Create ALB routes, CloudFront distribution, WAF, private S3 OAC access, DNS aliases and cache behaviors. Restrict ALB origin access with appropriate CloudFront source controls plus a validated origin header. Route /api consistently. Disable shared caching for login, carts, orders and payment webhook routes. | **https://dev.kingdomgoods.store** supports sign-in, browse and cart persistence. TLS works browser-to-edge and edge-to-ALB. Direct origin bypass is rejected. Cross-user cache isolation and test WAF behavior pass. |

### Week 2 acceptance gate

- [ ] Register/sign in, browse, cart updates and persistence work in dev after pod replacement.
- [ ] Admin authorization and customer resource-ownership tests pass.
- [ ] MySQL is private; pods retrieve secrets without hardcoded defaults; migrations are controlled.
- [ ] Dev is deployed from Git/ECR with recorded immutable digests.
- [ ] HTTPS, origin restriction, private S3 access and authenticated-cache isolation pass.
- [ ] Basic logs, readiness, deployment checks and a usable rollback path are already operational.

**Planned DNS:** `dev.kingdomgoods.store` for dev; `kingdomgoods.store` for production. Add `www` only with a defined canonical redirect. Origin hostnames must match the ALB certificate and CloudFront origin configuration. Hostinger remains the registrar after Route 53 delegation. [3]

## 5. Week 3 — Checkout correctness, reliable events, caching and scaling

**Goal:** complete the commerce path and prove it behaves correctly under retries, concurrency and component failures.

| Day | Work | Deliverable and verification |
|---|---|---|
| **11 — Transactional checkout and stock** | Use integer minor units or exact decimal arithmetic. Implement server-computed totals, scoped unique idempotency keys, conditional stock updates/locking, reservation expiry and an explicit order state machine. Include cart reads and relevant writes in the consistency strategy. Handle begin/commit errors and concurrent cart changes. | Repeated checkout keys produce one logical order; conflicting key reuse is rejected. Concurrent buyers cannot reserve more units than available. Failed transactions do not clear carts or leave partial orders. |
| **12 — Stripe sandbox and webhook correctness** | Create hosted Checkout sessions after DB commit using provider idempotency. Verify webhook signatures on the raw body; validate payment identity/amount/currency/status. Deduplicate provider event IDs and update payment/order/reservation state transactionally. Implement reconciliation for API timeouts, missing/reordered events and payment-versus-expiry races. | Successful, failed, duplicate, delayed and out-of-order sandbox events pass. Redirects alone do not mark orders paid. No duplicate order fulfillment or raw card storage. Start with explicitly supported payment methods. |
| **13 — Outbox, SQS, workers and notification** | Write outbox rows in the order transaction; implement a retryable relay. Configure SQS, visibility timeout, bounded retries, DLQ, durable consumer deduplication and replay controls. Add simulated fulfillment and SES sandbox/verified-recipient notification or a captured test-notification sink. | Kill/restart the relay after publication and show duplicates have no duplicate business effect. An unavailable downstream dependency causes retry/DLQ, then controlled recovery. Evidence links order ID → outbox event → consumer outcome. |
| **14 — Valkey and complete observability** | Add ElastiCache/Valkey for suitable public catalog reads with TTL, invalidation and DB fallback. Keep inventory/checkout correctness in MySQL. Install/integrate OpenTelemetry, Prometheus, Grafana and CloudWatch collection with retention/resource limits. Export API, checkout, DB, queue and cache metrics. | Cache hit/miss behavior and invalidation are demonstrated; cache loss does not corrupt orders. Dashboards link errors/latency to logs/traces. Include node, CoreDNS and available kube-proxy metrics. |
| **15 — Autoscaling and alert validation** | Configure HPA, resource requests/limits, topology spread, PDBs, graceful termination and timeouts. Add a bounded Karpenter workload pool with separate stable system capacity. Set Prometheus/CloudWatch alarms, Alertmanager/SNS routing and queue-age/DLQ alerts. Exercise scaling and a pod disruption. | HPA increases replicas under controlled load; Karpenter adds needed capacity and respects cost limits. Pods remain serviceable during a permitted disruption. Test alerts reach the chosen destination; no secrets/PII are emitted in telemetry. |

### Week 3 acceptance gate

- [ ] Browse → login → cart → reserve → sandbox payment → paid order → simulated fulfillment completes.
- [ ] Overselling, duplicate checkout, duplicate webhook and reservation/payment race tests pass.
- [ ] Database changes and outbox events commit together; relay/consumer retries are safe.
- [ ] DLQ alarm and controlled replay work; notification success or approved sandbox limitation is recorded.
- [ ] Cache fallback, HPA, node provisioning and a real alert notification are demonstrated.
- [ ] Trace/log/metric evidence exists for a successful and a failed checkout.

Use webhook-driven payment confirmation rather than relying on the customer redirect. [4] The outbox addresses the database/event dual-write gap; duplicates still require idempotent consumers. [5]

## 6. Week 4 — Production configuration, failure testing and release evidence

**Goal:** promote the tested implementation, measure its limits and demonstrate recovery.

| Day | Work | Deliverable and verification |
|---|---|---|
| **16 — Production environment** | Instantiate the isolated production configuration using the same Terraform modules. Apply production Multi-AZ RDS, appropriate application replicas/AZ placement, per-AZ egress, backup retention, deletion protection, encryption, access restrictions and log retention. Separate database, queues, secrets and identity configuration from dev. | Dev cannot read/write production data or deploy as production. Production node/DB capacity and expected recurring costs are documented. Required add-ons/controllers and private runner access work. |
| **17 — Controlled promotion** | Promote the same tested image digests and chart version through a production configuration PR. Run compatible migrations in order. Configure production CloudFront/WAF/DNS and sandbox webhook endpoint. Verify a full customer journey at kingdomgoods.store. | Record release commit, digests, schema version and Argo CD health. Unauthenticated/admin-negative tests and origin/cache checks pass in production configuration. Sandbox checkout remains clearly identified. |
| **18 — Load and contention evidence** | Run realistic mixed traffic, bounded flash-sale traffic and stock contention with isolated test identities/data. Measure API percentiles, errors, DB connections/locks, cache ratio, queue age and scaling. Investigate bottlenecks and tune within the agreed budget. | Publish workload, tool, concurrency, request rate, duration, environment size and raw results. Distinguish expected stock/rate-limit responses from unexpected failures. Never extrapolate a short demo into a millions-of-users claim. |
| **19 — Failure, restore and rollback drills** | Restore RDS to a separate instance and validate data/application reconnect. Restore a versioned S3 object. Test a controlled RDS failover, pod/node interruption where safe, worker restart, poisoned message replay and compatible application rollback. Confirm migration rollback limitations. | Measured RTO/RPO, reconciliation results, alert timelines and restore evidence are recorded. Do not overwrite production data as a test. Separate an actual failover test from a claim of full AZ outage tolerance. |
| **20 — Release gate and portfolio handoff** | Resolve blocking defects; check drift, security findings, access, budgets, retention and runbooks. Update README, final diagrams, deployment/rollback/restore guidance, test reports, operational dashboards and phase summaries. Tag the release candidate and document residual gaps. | A reproducible demo, evidence-backed architecture and explicit go/no-go record. Date alone cannot override missing checkout, authorization, recovery or isolation evidence. |

### Suggested initial validation targets — confirm on Day 1

These are acceptance proposals, not achieved results or a large-scale capacity guarantee.

| Check | Initial target | Measurement boundary |
|---|---|---|
| Mixed workload | Ramp 10 → 50 → 100 concurrent virtual users; hold peak 15 minutes | Approximately 80% catalog, 15% cart, 5% sandbox checkout; report actual achieved RPS and test data |
| API errors | Under 1% unexpected failures during the accepted steady workload | Report expected stock conflicts and intentional rate limits separately |
| API latency | p95 catalog reads <500 ms; checkout initiation <1.5 s | Server/API measurement; separately report browser latency and external payment-provider latency |
| Stock contention | 20 distinct buyers compete for 5 units | At most 5 units reserved/sold; no negative inventory; unpaid reservations eventually release |
| Duplicate handling | Repeated keys/events and worker restarts | One logical business transition; retries are auditable |
| Recovery | Proposed RTO ≤60 minutes; RPO ≤15 minutes | Measure the actual restore and recoverable timestamp; record gaps rather than asserting success |
| Service objective | Draft 99.9% monthly availability target | Define success and measurement window; short tests cannot prove a month of availability |

### Week 4 acceptance gate

- [ ] Dev passes before production promotion; production uses the same tested artifacts.
- [ ] `kingdomgoods.store` resolves to the intended HTTPS storefront.
- [ ] No unresolved critical authorization, data-integrity, exposed-secret or payment-state defects.
- [ ] Load results and capacity limits are published; key performance targets pass or exceptions are explicit.
- [ ] Database/S3 restoration and application rollback are demonstrated with measured outcomes.
- [ ] Runbooks, dashboards, ownership, alert destinations and cost controls are usable by another operator.
- [ ] Remaining work is listed; production-configured sandbox demonstration is distinguished from live commercial readiness.

## 7. Dependency order and ownership

**Critical path:** decisions/local baseline → state/identity/DNS → VPC/private access → EKS/controllers → RDS/secrets/migrations → auth/storefront → immutable CI/GitOps → HTTPS dev → checkout/payments/outbox → telemetry/scaling → isolated production → load/restore/rollback → release evidence.

Application design/tests can progress locally while infrastructure provisions. DNS validation starts early to avoid holding the dev release. Basic logging starts in Week 2; the full operational stack follows in Week 3. Production configuration is parameterized during foundation work, then instantiated after the dev release is validated.

| Resource or action | Owner |
|---|---|
| VPC, EKS, RDS, edge, IAM, state, queues, buckets | Terraform with reviewed plans and environment-specific state |
| Platform bootstrap before GitOps can run | Explicit Terraform/bootstrap workflow; record handoff where applicable |
| Application releases and assigned platform charts | Argo CD from Git, packaged with Helm |
| Image/chart publication | GitHub Actions with scoped OIDC permissions |
| Image promotion | Reviewed Git configuration change to a tested immutable digest; no competing tag owner |
| Schema changes | Versioned migration job with ordering, compatibility rules and evidence |
| Secret values | Secrets Manager; External Secrets synchronizes narrowly scoped Kubernetes Secrets |
| Domain registration / authoritative records | Hostinger registrar / Terraform-managed Route 53 DNS |

## 8. Scope boundaries and schedule protection

| Capability | Four-week treatment |
|---|---|
| React, TypeScript, Go/Fiber, RDS MySQL, EKS, Terraform, Helm, GitHub Actions, Argo CD | Core implementation |
| Route 53, CloudFront, ALB, WAF, S3, ACM, IAM/secret controls | Core implementation |
| Cognito, Stripe sandbox, Valkey, SQS/DLQ, observability, scaling | Planned core; identity/provider selection finalized Day 1 |
| SES notifications | Sandbox/verified recipients; test sink acceptable if provider approval is pending |
| OpenSearch | Post-core increment: indexing events → private domain → autocomplete/facets → rebuild/lag tests. Retain basic catalog search in four-week release |
| DynamoDB | Conditional ADR and separate increment only if a measured cart/session access pattern justifies a second authoritative store |
| EventBridge / SNS business-event fan-out | Add when multiple integrations require routing; SNS operational alarms remain core |
| Next.js, service mesh, gRPC microservices, Kafka, multi-region failover, AI remediation | Outside this four-week implementation |
| Live payments, real fulfillment, advanced shipping/tax/refund automation | Separate commercial-launch increment; sandbox release does not imply these are ready |

**If behind:** cut optional search/visual polish and additional integrations first. A reduced dev footprint is acceptable when documented. Do not cut authorization, stock/charge correctness, secret handling, restore evidence or separation of environments. If those fail, defer release and report the blocker.

**Cost controls:** estimate before apply; use budget alarms and service-level tags; cap Karpenter/ASG/HPA capacity; set log retention, ECR lifecycle and S3 lifecycle; remove test load/failover/restore resources after evidence is retained. Stopping nodes alone does not stop charges for EKS control planes, NAT gateways, databases or other managed services. Track the production environment's billable lifetime explicitly.

**EKS monitoring boundary:** AWS manages control-plane etcd. Collect available EKS telemetry/control-plane logs and application symptoms; do not promise direct etcd filesystem access, etcdctl backup/restore or unrestricted managed-etcd metrics. Monitor kube-proxy where exposed; select its supported mode from the actual EKS/version design rather than requiring IPVS without validation. [6]

## 9. Repository and evidence deliverables

Use a documented structure such as `frontend/`, `backend/`, `helm/kingdom-goods/`, `terraform/bootstrap/`, `terraform/modules/`, `terraform/environments/dev/`, `terraform/environments/prod/`, `gitops/`, `tests/`, `.github/workflows/`, and `docs/`. Final paths should follow the adopted repository, not require an unnecessary rewrite.

Every implementation session should produce:

1. A short objective and prerequisite check.
2. Commands for **Git Bash in VS Code on Windows**, with explanatory comments and no mixed PowerShell syntax.
3. Commented configuration/code where explanation helps; file header comments on authored files.
4. A reviewable change plus meaningful validation, not only a resource listing.
5. A brief implementation summary: what changed, evidence, limitations, cost impact and next dependency.

Required closeout artifacts: architecture source/exports; README; account/environment and version records; Terraform plan/apply evidence; CI/release digest records; weekly validation summaries; authorization/checkout tests; load/failover/restore reports; dashboard/alert evidence; deployment, rollback, DNS, credential and incident runbooks; cost inventory; deferred backlog.

**First execution session:** Day 1 — establish the Kingdom Goods repository, run the unchanged starter locally, confirm account/budget/provider choices, and record the baseline before rebranding or provisioning.

## 10. Official implementation references

[1] [CloudFront certificate requirements and region](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/cnames-and-https-requirements.html)  
[2] [Terraform S3 backend, state versioning and native locking](https://developer.hashicorp.com/terraform/language/backend/s3)  
[3] [Hostinger nameserver changes](https://www.hostinger.com/support/1696789-how-to-change-nameservers-at-hostinger/)  
[4] [Stripe Checkout fulfillment and webhook handling](https://docs.stripe.com/checkout/fulfillment)  
[5] [AWS transactional outbox pattern](https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/transactional-outbox.html)  
[6] [Amazon EKS reliability responsibilities](https://docs.aws.amazon.com/eks/latest/best-practices/reliability.html)
