# Day 2 — AWS foundation and validation

## Verified results

| Area | Evidence |
|---|---|
| Dev Terraform backend | Created a versioned, KMS-encrypted S3 bucket with Block Public Access and HTTPS enforcement. Migrated the local state to S3, read all six resources from the remote state, and ran a plan that showed no changes. |
| Management Terraform backend | Created a separate versioned, KMS-encrypted S3 backend. The DNS and ACM stack initialized against it and imported four existing resources with zero additions, changes, or destroys. |
| GitHub OIDC | A workflow on `main` assumed `kingdomgoods-dev-github-terraform` and verified the AWS identity. [Smoke test run](https://github.com/Gabinsime75/KingdomGoods/actions/runs/45723742405) |
| Terraform CI permissions | Applied a policy scoped to `dev/network/terraform.tfstate`, its `.tflock` object, and use of the matching KMS key through S3. |
| Dev CloudTrail | The multi-Region management-event trail reported `IsLogging: true` and successful delivery to its private S3 bucket on November 26, 2026, with no delivery error. |
| Budget | Created a recurring $300 monthly cost budget in the management account for dev and prod combined. Budget alert delivery has not been verified. |
| Public DNS | Verified that Hostinger delegates `kingdomgoods.store` to the Route 53 zone in the management account. Terraform adopted the zone and the two existing viewer certificate validation CNAMEs. |
| TLS certificates | The prod CloudFront viewer certificate is issued in `us-east-1` for `kingdomgoods.store` and `www.kingdomgoods.store`. Terraform provisioned and validated the prod and dev ALB origin certificates in `us-west-2` for `origin.kingdomgoods.store` and `dev-origin.kingdomgoods.store`, respectively. |

## Cost impact

The Terraform state backends, CloudTrail log storage, and public hosted zone add ongoing AWS costs. The monthly budget tracks combined spending across the selected dev and prod accounts.

## Open items

- Native S3 state locking is configured. Concurrent lock contention was not verified.
- Exercise the CI role against the dev network backend when the network stack is in place.
- Carry forward cost allocation tagging and the AWS Config, GuardDuty, and Security Hub baseline.

## Next dependency

Day 3 starts with the dev VPC CIDR and subnet layout. The network stack will use `dev/network/terraform.tfstate` in the dev S3 backend.