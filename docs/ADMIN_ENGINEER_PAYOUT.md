# Engineer IBAN / bank verification (admin)

Engineers submit bank details in the app (**Profile → Bank & IBAN**). Fields on `users/{uid}`:

| Field | Description |
|-------|-------------|
| `payoutBankId` | Bank code (see app `saudi_banks.dart`) |
| `payoutAccountName` | Account holder name |
| `payoutIban` | Normalized IBAN (no spaces) |
| `payoutStatus` | `pending` \| `approved` \| `rejected` (also `none` or unset) |
| `payoutAdminMessage` | Reason shown to engineer if rejected |
| `payoutSubmittedAt` | Server timestamp of last submission |

## Approve or reject (Firebase Console or Admin SDK)

1. Open **Firestore** → `users` → select the engineer document.
2. Set `payoutStatus` to `approved` or `rejected`.
3. If rejected, set `payoutAdminMessage` (string) with the reason.

**Security rules** prevent the mobile app from setting `approved` / `rejected`; only updates that keep the previous status or set `pending` are allowed from the client.
