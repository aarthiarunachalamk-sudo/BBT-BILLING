# Admin and staff flow review

Reviewed 10 September 2026. This is a source and automated-test review, not a live-device or production acceptance test. Application code was not changed.

## Flow map

| Area | Connected flow |
| --- | --- |
| Entry and authentication | Splash → workspace selection → role-checked login → dashboard; staff session restoration and token refresh; password change requires current password. |
| Admin operations | Users and activation → categories/brands/suppliers/products → purchase approval and receipt → inventory → billing → invoices/payments → reports, audit, settings. |
| Staff operations | Login → catalogue/search/scanning → cart → discount request if needed → admin decision → payment → checkout → invoice/PDF; inventory roles also have transfers, counts, expiry and product tools. |
| Checkout | Server reloads prices, checks stock, validates discount approval and payment total, verifies Razorpay signature when applicable, then creates invoice/payment records and deducts inventory in a transaction. |
| Shared visibility | Staff changes are read by admin collections, dashboards, user summaries and audit records. Data refresh is request based. |
| Returns | Return request → approval → stock restored. Refund amount is recorded, but the approval action does not execute a payment-provider refund. |
| WhatsApp | Admin creates a queued message record. No delivery worker/provider integration was found in the repository. |

## Findings, in priority order

### High: administrative decisions are available to ordinary authenticated users

`backend/billing/views.py:1573`, `:1681`, `:1724` inherit the default authenticated-only permission. Payment verification/rejection, purchase decisions/receipt, and return decisions have no additional role check. Category, brand and supplier CRUD likewise use this default. A staff token can call these routes directly regardless of which screens are visible.

`RolePermission` flags are stored and editable but are not consulted by the API permission classes (`views.py:102`, `:111`, `:1670`). Disabling billing or inventory in the roles screen therefore does not revoke endpoint access. Establish and enforce an action-by-role matrix and test denied requests for each role.

### High: verified payments remain editable and deletable

`backend/billing/views.py:1573` is a full ModelViewSet; `serializers.py:491` leaves amount, invoice and method writable. A PATCH of a verified payment can change its amount or invoice, and DELETE can remove it. These inherited operations do not reconcile invoice status or inventory. Make posted payment records immutable and use explicit correction/reversal operations.

### High: successful checkout can be presented as failure and submitted twice

`lib/frontend/screens/user/user_state.dart:388` saves the invoice, then fetches invoice history before clearing the cart and navigating. If that GET fails, the operation reports failure with the cart retained, despite the sale being committed. Admin checkout similarly waits for several refreshes before returning the invoice (`admin_state.dart:744`). The backend checkout has no general request idempotency key. Commit the successful UI state immediately, refresh separately, and make retrying a checkout safe.

### High: returns can restore more stock than was sold

`backend/billing/serializers.py:563` checks each return line against the original invoice quantity, without counting earlier returns or duplicate lines. Repeated requests can each return the full sold quantity; approval adds inventory each time (`views.py:1735`). Validate aggregate returned quantities under a lock. Validation also occurs after creating the return header, without an enclosing transaction, so invalid requests can leave partial records.

### High for multiple branches: new branch stock can copy another branch's quantity

`backend/billing/inventory/services/stock_service.py:26` initializes missing branch rows from product-level legacy stock. `_sync_legacy` then overwrites those product fields with the last updated branch's values. Accessing a previously unused branch can consequently initialize it with another branch's stock. Restrict legacy backfill to its intended branch and initialize new branches explicitly.

### Medium: staff collections stop at the first 20 records

`lib/frontend/screens/user/user_api.dart:111` returns only `results` and ignores `next`; backend pagination defaults to 20 (`backend/config/settings.py`). Products, stock, categories, invoices and discount history can silently be incomplete. Local searching cannot find omitted products. The admin API already follows pagination. Add equivalent staff pagination or server-backed paged screens.

### Medium: admin sessions expire without refresh

`lib/frontend/screens/admin/admin_api.dart:154` retains only the access token and has no refresh implementation. Backend access tokens last one hour. An admin working beyond that window receives authentication failures; the staff client already has a refresh path.

### Medium: newly created admin-role users can lose access to admin modules

User creation accepts `role=admin` but does not set Django `is_staff` (`backend/billing/serializers.py:84`). Login/UI checks admit admin and manager roles, while settings, permissions and audit endpoints require `IsAdminUser`, which checks `is_staff` (`views.py:1670`, `:1759`, `:1769`). Align the role model and endpoint rules; a seeded superuser does not exercise this case.

### Medium: invoice sharing ends at queue creation

`backend/billing/views.py:1659` only saves a WhatsApp message and audit entry; `lib/frontend/screens/admin/admin_state.dart:983` calls this endpoint. A queued record alone does not deliver an invoice. Complete provider delivery/status handling or clearly label the feature as queue-only.

## Validation

- Django: all 39 existing tests passed; system checks found no issues. Tests ran against an isolated test database with DATABASE_URL cleared.
- Existing backend coverage includes login/password change/logout audit, account deactivation, staff product and stock changes reflected in admin, checkout total validation and atomic stock deduction, discount approval, and mocked Razorpay order/signature checks.
- Flutter: all 48 existing tests passed using the installed Flutter tool snapshot with `test --no-pub`.
- Dart analysis of `lib` and `test`: 22 findings (15 warnings, 7 informational; no code errors). Mostly unused declarations/style issues, plus two unawaited returns inside try blocks. The analyzer also reported a sandbox-denied telemetry timestamp write on exit.
- Live Razorpay settlement, WhatsApp delivery, Cloudinary uploads, camera scanning, printing/PDF sharing on devices, production PostgreSQL concurrency and browser/mobile end-to-end behavior were not exercised.

## Recommended acceptance coverage

Add regression cases for role-denied actions, payment immutability, more than 20 staff records, checkout success followed by refresh failure/retry, cumulative returns, two-branch inventory isolation, newly created admin accounts and token expiry. Then exercise the complete admin/cashier/inventory workflows on target devices against a staging backend, including real provider sandbox callbacks and failed-network recovery.
