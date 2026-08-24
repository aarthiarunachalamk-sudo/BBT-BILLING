# Supermarket Billing App — Manual Testing Audit

Date: 22 August 2026  
Overall result: **PARTIALLY PASS**

## Navigation remediation audit — 22 August 2026

This pass inspected every Flutter `onTap`, `onPressed`, navigation bar, route transition, dialog action, and clickable list/card in both active modules. The application uses centralized state-driven navigation (`AdminState.go/setNav` and `UserState.go/setNav`), so no second router or duplicate legacy screen was introduced.

| Navigation flow | Result | Evidence |
|---|---|---|
| Portal → Admin/User choice | PASS | Both choices push only the active `SupermarketAdminApp` / `SupermarketUserApp` modules |
| Admin login → Dashboard | PASS | Login changes the centralized screen to Dashboard; `PopScope` prevents returning to login while authenticated |
| Admin bottom Dashboard/Users/Billing/Reports/Settings | PASS | Settings mapping corrected from Audit/Logout to Reports & Store Settings; state switching does not stack routes |
| Admin dashboard sales/profit | PASS | Opens Payment & Sales Report |
| Admin dashboard Low/Expiring/Out of Stock | PASS | Opens Inventory Alerts with the requested filter selected |
| Admin dashboard Total Bills | PASS | Opens the existing invoice-control module, now implemented as searchable All Bills |
| Admin All Bills → selected invoice | PASS | Invoice ID-backed row opens its itemized detail dialog |
| Admin Users → selected user | PASS | Passes backend user ID to `openUserDetails`; back returns to User Management |
| Admin Add User → refresh | PASS | Successful API creation reloads the user collection before closing |
| Admin Products → selected product | PASS | Product ID-backed row opens edit workflow; filter icon opens filter sheet |
| Admin Add Product → refresh | PASS | Successful creation updates centralized products before returning |
| Admin logout | PASS | Confirmation, guarded request, local session clear, and portal callback are wired |
| Staff login → Verification → Dashboard | PASS | State transition occurs only after successful authentication |
| Staff bottom Dashboard/Inventory/Billing/Reports/Profile | PASS | Uses state switching; no Admin destination is referenced |
| Staff logical back navigation | PASS | Added previous-screen tracking; Payment returns to Billing and Profile subflows return logically without loops |
| Staff dashboard quick actions | PASS | Current Stock, Shelf Stock, Quantity Review, and Expiry route to their existing screens |
| Inventory category → filtered products | PASS | Passes category database ID to current-stock API query |
| Billing → Payment → Invoice | PASS | Cart remains in state; invoice transition occurs only after checkout succeeds |
| Quantity Update/Confirm/Report Difference | PASS | All three actions now use confirmation/input and the stock-review API |
| Expiry Remove/Clearance/Return/Dispose | PASS | Each action confirms, calls its batch endpoint by ID, and refreshes batch data |
| Shelf Move Stock | PASS | Quantity dialog calls the stock-transfer endpoint and refreshes shelf stock |
| Shelf Discount/Return/Clearance | BLOCKED | No corresponding staff-authorized shelf-product API exists; UI explicitly reports manager-only availability |
| Invoice PDF/WhatsApp/Print | BLOCKED | Dedicated staff PDF, platform share, and print services/endpoints do not exist in this project |
| Physical device click-through | BLOCKED | Flutter CLI/device tooling still stalls without producing a usable target; results above are code-path and backend verification, not claimed physical taps |

## Environment evidence

- `python backend/manage.py check`: PASS.
- Applied pending additive migrations `billing.0007` and `billing.0008`: PASS.
- `python backend/manage.py test billing.tests --noinput`: **17/17 PASS**.
- Isolated critical Staff/Admin integration scenario: PASS.
- Django deployment check: five warnings (HSTS, SSL redirect, secure session cookie, secure CSRF cookie, and DEBUG).
- Flutter CLI (`flutter devices`, `flutter analyze`, and earlier formatter attempts): BLOCKED because the local Flutter process stalls without producing output.
- Android/emulator gesture, screenshot, keyboard, responsive-layout, and visual-reference checks: BLOCKED because no usable target could be established.

## Summary

| Result | Count |
|---|---:|
| Total test groups | 66 |
| Passed | 10 |
| Failed | 20 |
| Blocked / not manually executable | 36 |

Severity summary:

| Severity | Open findings |
|---|---:|
| Critical | 3 |
| High | 7 |
| Medium | 8 |
| Low | 2 |

## Detailed evidence matrix

| Test ID | Module / scenario | Expected result | Actual result / evidence | Status | Severity |
|---:|---|---|---|---|---|
| 7 | Staff → Admin product sync | One shared product and stock | Isolated API scenario created `INT-JUICE-001`; Admin API returned the same row and total 60 | PASS | — |
| 10 | Shelf transfer | 45 store, 15 shelf, total 60 | Transactional endpoint produced exactly 45/15/60 and recorded movement/audit | PASS | — |
| 21 | Stock after billing | Both roles see 56 | Shared `Item` changed from 58 to 56; both roles query the same endpoint/table | PASS | — |
| 22 | Negative stock prevention | Reject oversell without writes | Existing checkout tests and row-locked validation pass | PASS | — |
| 32 | Admin creates Staff | Staff can authenticate | Admin created EMP200 and employee-ID JWT login succeeded | PASS | — |
| 33 | Deactivation | Login rejected | Deactivated EMP200 login returned HTTP 401 | PASS | — |
| 34 | Admin user summary | Real daily totals | Summary returned one bill and UPI 231.00 for EMP200 | PASS | — |
| 36 | Admin → Staff price sync | Staff reads ₹110 | Admin PATCH updated shared Item; Staff GET returned 110.00 | PASS | — |
| 37 | Historical price | Old invoice retains price | `InvoiceItem.unit_price` is persisted as a checkout snapshot | PASS | — |
| 44 | Admin payment aggregation | Totals derive from Payment | Dashboard and user summary aggregated verified UPI payment 231.00 | PASS | — |
| 2 | OTP login | No unsupported OTP control is shown | OTP login control removed; password login remains the supported path | PASS | — |
| 5 | Category filtering | Selected category filters products | Category tap opens all current stock and does not pass category ID | FAIL | Medium |
| 9 | Staff stock update | Editable store quantity | Staff UI has no direct stock-adjustment control | FAIL | High |
| 11 | Shelf aging actions | Four working mutations | Apply Discount, Return Supplier, and Clearance remain disabled/placeholders | FAIL | High |
| 12 / 41 | Quantity review approval | Record discrepancy, then Admin confirms | Backend immediately changes inventory during Staff review; no separate Admin confirmation state | FAIL | Critical |
| 13 / 42 | Expiry actions | Actions update batch and stock | Staff action buttons are still notification placeholders; status actions do not consistently change stock | FAIL | High |
| 15 | Cart controls | Remove and clear cart | Quantity removal works; no Clear Cart control | FAIL | Low |
| 16 | Billing calculations | Discount/GST controls and matching totals | GST is shown; Staff UI has no discount input even though backend supports bill-level discount | FAIL | High |
| 24 | User report | Own totals and custom dates | Custom range is absent; endpoint currently aggregates all verified payments for authenticated Staff | FAIL | Critical |
| 25 | Invoice details | Products, payment method, totals | User invoice screen omits item lines and payment breakdown | FAIL | High |
| 26 | PDF | Generate/open real PDF | Button only displays an informational snackbar | FAIL | Medium |
| 27 | WhatsApp | Share actual invoice | Button only displays an informational snackbar | FAIL | Medium |
| 28 | User bill history | Own paginated/searchable history | Profile opens a single invoice-oriented screen; no history search/date UI | FAIL | Medium |
| 38 | Historical GST | Old invoice retains GST rate | `InvoiceItem` stores unit price but not per-line GST percentage snapshot | FAIL | Critical |
| 40 | Admin shelf actions | Mutations visible to Staff | Existing Admin inventory presentation does not expose/test every requested action | FAIL | Medium |
| 45 | All bills | Dedicated searchable transaction history | Invoices exist in state/API, but the required complete All Bills interaction is not independently verified/presented | FAIL | Medium |
| 48 | Settings | No dead settings items | Some requested settings capabilities are not backed by dedicated working forms/endpoints | FAIL | Medium |
| 56 | JWT refresh | Refresh, then logout on failure | Staff API stores only access token and has no automatic refresh/401 retry | FAIL | High |
| 57 | Rapid Pay/Save | No duplicates | UI loading helps, but checkout has no idempotency key against repeated completed requests | FAIL | High |
| 65 | Admin API security | Staff receives 403 for Admin aggregations | User management/audit are protected, but shared dashboard/payment summary expose store-wide aggregation to any authenticated role | FAIL | Critical |
| Remaining 36 groups | Device/UI/error/large-data/manual interactions | Verified on real target | No operable Flutter target; cannot honestly mark as passed | BLOCKED | — |

## Critical integration scenario

The following was executed in an isolated Django test database and passed:

1. Admin created active Inventory Staff `EMP200`.
2. EMP200 authenticated using employee ID.
3. EMP200 created `Integration Test Juice`, opening stock 50 store + 10 shelf, GST 5%, and batch `TESTB001`.
4. Admin retrieved the same product with total stock 60.
5. EMP200 moved five units to shelf; values became 45 store + 15 shelf = 60.
6. EMP200 recorded physical quantity 58.
7. Admin changed price from ₹100 to ₹110; Staff retrieved ₹110.
8. EMP200 sold quantity two using UPI; backend recalculated total ₹231 including GST.
9. Stock became 56; Admin dashboard, user summary, payment, invoice, and audit records updated.
10. EMP200 logout was audited.
11. Admin deactivated EMP200; subsequent login returned 401.

## Fixed during this audit

- Applied pending migrations 0007 and 0008.
- Added a permanent isolated regression test for the critical cross-role scenario.
- Verified employee-ID authentication, atomic product/batch/opening-stock creation, shelf transfer, price synchronization, atomic checkout, report aggregation, audit visibility, logout tracking, and deactivation.

## Final verification

The backend portion of the requested final flow passes in an isolated database. The complete application cannot be declared fully manually tested because device UI execution is blocked and the failed items above are genuine missing behaviors, especially two-stage quantity approval, historical GST snapshots, Staff report scoping, refresh-token handling, PDF/WhatsApp, and Admin aggregation permissions.
