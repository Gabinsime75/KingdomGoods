<!-- KingdomGoods | Initial starter defect backlog -->
# Starter Defect Backlog

Source reviewed: ShopVerse commit
c1b1ea73e305d26a8e702eda04f8019c5c6b0628.

All items below are OPEN. Successful local shopping tests do
not demonstrate that these production requirements are met.

| ID | Finding | Required outcome | Target |
|---|---|---|---|
| KG-001 | Product creation requires login but lacks an admin role check | Only authorized administrators can manage products; verify denied access | Day 9 |
| KG-002 | JWT configuration includes a fallback signing secret and long token lifetime | Remove fallback secrets and implement the chosen identity/token controls | Day 9 |
| KG-003 | Prices and totals use floating-point arithmetic | Use integer minor units or exact decimals with explicit currency and rounding | Day 15 |
| KG-004 | Checkout lacks inventory reservations and duplicate-request protection | Prevent overselling and duplicate orders under concurrent requests | Day 15 |
| KG-005 | Checkout reads cart state outside its transaction and ignores commit errors | Define transactional boundaries and handle failures explicitly | Day 15 |
| KG-006 | Starter orders are confirmed without payment-provider verification | Use explicit order/payment states and verified, idempotent Stripe sandbox webhooks | Day 16 |
| KG-007 | Database migration and seeding run during application startup | Use controlled, versioned migrations and explicit development seed commands | Day 8 |
| KG-008 | Health endpoint always reports healthy | Separate liveness from readiness and test dependency failures | Days 8–12 |
| KG-009 | Frontend build reported 19 dependency vulnerabilities | Triage advisories, upgrade dependencies and validate compatibility | Days 1–12 |
| KG-010 | Starter delivery uses permanent AWS keys and rebuilds after scanning | Use GitHub OIDC and promote the same tested, scanned image digest | Days 2 and 11 |
| KG-011 | Starter infrastructure exposes the EKS API broadly and grants broad controller permissions | Implement the selected private access path and scoped workload permissions | Days 3–5 |
| KG-012 | Local Compose publishes frontend, API and MySQL on all host interfaces | Restrict published local ports to loopback; keep cloud data services private | Day 1 |
| KG-013 | No automated test suite was found in the reviewed starter | Establish CI checks and add behavioral tests as features are hardened | Day 1 onward |
| KG-014 | No upstream LICENSE file was found | Clarify upstream reuse permissions before distributing a derived release | Before release |

## Scope

- This is a practice project using sandbox payments and dummy data.
- Branding and the storefront redesign remain on Day 10.
- Upstream workflow and infrastructure findings guide our replacements;
  those files were not imported into KingdomGoods.
- Close items only when implementation and validation evidence exist.
