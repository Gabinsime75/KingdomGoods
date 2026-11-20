<!-- KingdomGoods | Day 1 local validation -->
# Day 1 — Local Baseline Validation

## Environment

- Windows with Git Bash and Docker Desktop Linux containers.
- Compose project: kingdomgoods-local.
- Services: React/Nginx frontend, Go/Fiber backend, MySQL 8.0.

## Results

| Check | Result |
|---|---|
| Frontend and backend images build | PASS |
| All three containers start | PASS |
| MySQL container health check | PASS |
| Backend GET /health | PASS |
| Frontend proxy GET /api/products | PASS — 28 seeded products |
| Storefront registration | PASS — operator verified |
| Logout and login | PASS — operator verified |
| Add product to cart | PASS — operator verified |
| Change quantity and refresh for persistence | PASS — operator verified |
| Starter order flow with dummy details | PASS — operator verified |

## Findings

- Alpine build-package installation took approximately 22 minutes.
- Frontend npm installation reported 19 vulnerabilities:
  1 low, 7 moderate and 11 high. Detailed triage remains pending.
- ShopVerse branding remains until Day 10.
- These checks establish local functionality; production readiness,
  payment processing and checkout concurrency are not yet validated.

## Day 1 status

In progress: defect backlog, version requirements and basic CI
checks remain to be completed.
