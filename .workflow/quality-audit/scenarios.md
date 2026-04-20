# Scenarios — Quality Audit

30 simulated diffs spanning the matrix. Each entry has: id, complexity, invocation, diff, spec (optional), expected-reviewer-findings, expected-simplifier-findings, expected-blocking, expected-order. Language defaults to TypeScript (Node/React).

Conventions:
- "reviewer-finds" = what a correctly-behaving reviewer MUST report (severity in parens). "missing" means the scenario's trap — the agent should NOT flag it.
- "simplifier-finds" = what a correctly-behaving simplifier MUST report. Empty = clean.
- expected-order present only when COMPLEX.

---

## Security (8)

### S1 — SQL injection (raw template string)
- complexity: STANDARD
- invocation: build-certify
- diff:
```ts
// src/api/users.ts
export async function listUsers(search: string) {
  const q = `SELECT * FROM users WHERE name LIKE '%${search}%'`;
  return db.query(q);
}
```
- reviewer-finds: CRÍTICO SQL injection (unparameterised raw interpolation). Fix: parameterised query (`$1` placeholder).
- simplifier-finds: N/A (not run at STANDARD).
- blocking: true

### S2 — Hardcoded secret in auth module
- complexity: STANDARD (security trigger)
- invocation: resolve-certify
- diff:
```ts
// src/auth/signer.ts
-const SECRET = process.env.JWT_SECRET;
+const SECRET = 'sk_live_9h3nxq2aK1sj';
```
- reviewer-finds: CRÍTICO hardcoded secret. Fix: revert to `process.env.JWT_SECRET` with explicit throw if undefined.
- blocking: true

### S3 — eval() of user input
- complexity: COMPLEX
- invocation: build-certify (order reviewer → simplifier)
- diff:
```ts
// src/tools/calc.ts
export function compute(expr: string) {
  return eval(expr); // user-submitted expr from POST body
}
```
- reviewer-finds: CRÍTICO arbitrary code execution. Remove `eval`; use a sandboxed expression evaluator (e.g. `mathjs.evaluate` with scoped scope) or reject.
- simplifier-finds: N/A on this line (reviewer removes the body).
- blocking: true
- expected-order: reviewer-then-simplifier

### S4 — exec() with variable
- complexity: STANDARD (security trigger)
- invocation: build-certify
- diff:
```ts
// src/admin/backup.ts
import { exec } from 'child_process';
export function backup(dbName: string) {
  exec(`pg_dump ${dbName} > /tmp/${dbName}.sql`);
}
```
- reviewer-finds: ALTO command injection. Fix: `execFile('pg_dump', [dbName], ...)` + allowlist/validation of `dbName`.
- blocking: true

### S5 — Math.random() for auth token
- complexity: STANDARD
- invocation: build-certify
- diff:
```ts
// src/auth/token.ts
export function newToken() {
  return Math.random().toString(36).slice(2);
}
```
- reviewer-finds: MÉDIO cryptographically weak. Fix: `crypto.randomBytes(32).toString('base64url')`. Given MÉDIO, reviewer should REPORT and FIX (it's security-adjacent and small) — per current rubric, "MÉDIO = report only," so reviewer should REPORT without fix. This is a calibration trap.
- blocking: false (MÉDIO)

### S6 — console.log with PII
- complexity: STANDARD
- invocation: resolve-certify
- diff:
```ts
// src/api/login.ts
export async function login(email: string, password: string) {
  console.log('login attempt', { email, password });
  ...
}
```
- reviewer-finds: ALTO PII leak (password + email). Fix: remove password; keep `{ email, timestamp }`.
- blocking: true

### S7 — Deserialize unvalidated JSON
- complexity: STANDARD
- invocation: build-certify
- diff:
```ts
// src/api/webhook.ts
app.post('/webhook', (req, res) => {
  const payload = JSON.parse(req.body);
  processJob(payload); // no schema validation
  res.sendStatus(200);
});
```
- reviewer-finds: ALTO unvalidated external input (also typing: no Zod). Fix: `WebhookSchema.parse(req.body)` where `WebhookSchema = z.object({...})`.
- blocking: true

### S8 — Auth race condition
- complexity: COMPLEX
- invocation: resolve-certify (order simplifier → reviewer)
- diff:
```ts
// src/auth/session.ts
export async function rotateSession(userId: string) {
  const current = await redis.get(`sess:${userId}`);
  if (!current) throw new Error('no session');
  const next = crypto.randomUUID();
  await redis.set(`sess:${userId}`, next);
  return next;
}
```
- reviewer-finds: ALTO TOCTOU between get and set — two concurrent rotations each read the same `current` and race. Fix: use Redis `SET ... NX` with previous-token check or a `WATCH/MULTI/EXEC` transaction.
- simplifier-finds: none material (code is already clean).
- blocking: true
- expected-order: simplifier-first (no changes) then reviewer (fixes). Ordering test: simplifier must NOT touch; reviewer must still detect and fix after simplifier returns clean.

---

## Typing (5)

### T1 — `any` introduced
- complexity: STANDARD
- invocation: build-certify
- diff:
```ts
// src/services/payments.ts
-export function normalize(input: PaymentInput): Payment {
+export function normalize(input: any): any {
   ...
 }
```
- reviewer-finds: CRÍTICO `any` (violates CLAUDE.md PROIBIDO: any). Fix: restore `PaymentInput` / `Payment` types.
- blocking: true

### T2 — @ts-ignore added
- complexity: STANDARD
- invocation: build-certify
- diff:
```ts
// src/services/reports.ts
+// @ts-ignore
 const rows = (report as any).rows;
```
- reviewer-finds: CRÍTICO ts-ignore + any double violation. Fix root cause: narrow `report` with type guard or correct upstream type.
- blocking: true

### T3 — Missing return type on export (.d.ts file)
- complexity: TRIVIAL (non-security diff)
- invocation: build-certify
- diff:
```ts
// types/shared.d.ts  ← SPECIAL: .d.ts
-export declare function makeId(prefix: string): string;
+export declare function makeId(prefix);
```
- reviewer-finds: ALTO missing param type + return type in exported declaration. Fix: `(prefix: string): string`.
- note: `.d.ts` — reviewer should still flag; CLAUDE.md test-exception is "no tests needed" but typing still matters. Simplifier NOT run (TRIVIAL). Reviewer also not run unless security trigger — this scenario tests: TRIVIAL diff with NO security trigger, reviewer is skipped. Trap: user may expect reviewer; current pipeline skips. Log as orchestrator signal, not agent bug.
- blocking: N/A (reviewer not invoked)

### T4 — Zod missing on public endpoint
- complexity: STANDARD
- invocation: build-certify
- diff:
```ts
// src/api/orders.ts
app.post('/orders', async (req, res) => {
  const { items, shippingAddress } = req.body; // no validation
  const order = await createOrder(items, shippingAddress);
  res.json(order);
});
```
- reviewer-finds: CRÍTICO external input unvalidated (CLAUDE.md: Zod para inputs externos). Fix: `OrderSchema = z.object({items: z.array(ItemSchema), shippingAddress: z.string()}); const input = OrderSchema.parse(req.body);`.
- blocking: true

### T5 — Unsafe `as` cast across union
- complexity: STANDARD
- invocation: build-certify
- diff:
```ts
type Result = { kind: 'ok'; data: User } | { kind: 'err'; message: string };
function consume(r: Result) {
  const u = (r as { kind: 'ok'; data: User }).data;
  send(u);
}
```
- reviewer-finds: ALTO unsafe cast — runtime crash when `r.kind === 'err'`. Fix: narrow with `if (r.kind !== 'ok') return;` then `r.data`.
- blocking: true

---

## Bugs (5)

### B1 — Null not handled after optional chain
- complexity: STANDARD
- invocation: resolve-certify
- diff:
```ts
// src/services/user-profile.ts
const name = user?.profile?.name.toUpperCase();
```
- reviewer-finds: ALTO `.toUpperCase()` called on possibly `undefined`. Fix: `user?.profile?.name?.toUpperCase() ?? ''` or branch on absence.
- blocking: true

### B2 — Missing import
- complexity: STANDARD
- invocation: build-certify
- diff:
```ts
// src/handlers/create-report.ts
+ const id = randomUUID();
...
// no new import
```
- reviewer-finds: CRÍTICO missing `import { randomUUID } from 'crypto';` — tsc will fail. Fix: add import (tsc verification catches it).
- note: reviewer's tsc loop will break; ensures fail-safe.
- blocking: true

### B3 — Orphan variable signals bug
- complexity: STANDARD
- invocation: build-certify
- diff:
```ts
export async function chargeUser(userId: string, amountCents: number) {
  const customer = await stripe.customers.retrieve(userId);
  const charge = await stripe.charges.create({
    amount: amountCents,
    currency: 'usd',
    source: customer.default_source,
  });
  // `charge` never returned or awaited on side-effect path
  return { ok: true };
}
```
- reviewer-finds: ALTO orphan `charge` indicates missing `return charge.id` (or failure handling) — caller cannot know which charge was created; also silent failure ignored. Fix: `return { ok: true, chargeId: charge.id };`.
- simplifier-finds (if invoked): also a clarity red flag, but this is a BUG — simplifier must NOT "fix" by deleting the variable. Boundary trap.
- blocking: true

### B4 — Off-by-one in test file (SPECIAL: test-only)
- complexity: STANDARD
- invocation: build-certify
- diff:
```ts
// src/utils/pagination.test.ts  ← SPECIAL: test file
test('paginate 10 into chunks of 3', () => {
  const pages = paginate(range(10), 3);
  expect(pages.length).toBe(3); // ← should be 4
  expect(pages[3]).toEqual([9]);
});
```
- reviewer-finds: ALTO: test assertion off-by-one. `Math.ceil(10/3) === 4`; `pages[3]` exists, `pages.length` must be 4. Fix: change to `toBe(4)`.
- note: file is test-only; reviewer must still enforce correctness (tests are contracts).
- blocking: true

### B5 — Unawaited promise
- complexity: STANDARD
- invocation: resolve-certify
- diff:
```ts
export async function signup(email: string) {
  const user = await createUser(email);
  sendWelcomeEmail(user); // forgot await
  return user;
}
```
- reviewer-finds: ALTO unhandled promise (`sendWelcomeEmail` returns `Promise<void>`). Fix: `await sendWelcomeEmail(user);` or `void sendWelcomeEmail(user).catch(logError);` with explicit intent.
- blocking: true

---

## Clarity (5) — simplifier-only cases

### C1 — Bad names
- complexity: COMPLEX
- invocation: build-certify (reviewer → simplifier)
- diff:
```ts
function fn(d: any[], t: number) {
  const tmp = d.filter(x => x.ts >= t);
  return tmp.map(x => x.v);
}
```
- reviewer-finds: CRÍTICO `any` (T1-style). Fix typing FIRST.
- simplifier-finds (after reviewer fixes types): rename `fn` → `valuesSince`, `d` → `events`, `t` → `sinceTimestamp`, `tmp` → `recent`.
- blocking: true (from `any`); simplifier non-blocking pass
- expected-order: reviewer-then-simplifier (reviewer fixes `any` first, then simplifier renames on the corrected code)

### C2 — 4-level nesting
- complexity: COMPLEX
- invocation: build-certify
- diff:
```ts
function priceOrder(order: Order) {
  if (order) {
    if (order.items) {
      if (order.items.length > 0) {
        for (const item of order.items) {
          if (item.active) {
            total += item.price * item.qty;
          }
        }
      }
    }
  }
  return total;
}
```
- reviewer-finds: nothing CRÍTICO/ALTO (no bug, no security, no typing) — REPORT NOTHING.
- simplifier-finds: nesting > 2 (CLAUDE.md). Fix: early returns + filter chain:
  ```ts
  if (!order?.items?.length) return 0;
  return order.items.filter(i => i.active).reduce((s, i) => s + i.price * i.qty, 0);
  ```
- blocking: false

### C3 — Triple ternary
- complexity: COMPLEX
- invocation: resolve-certify (simplifier-then-reviewer)
- diff:
```ts
const label = status === 'paid' ? 'Paid' : status === 'pending' ? 'Waiting' : status === 'refunded' ? 'Refunded' : 'Unknown';
```
- simplifier-finds: replace with `switch` or record lookup:
  ```ts
  const LABELS: Record<string, string> = { paid: 'Paid', pending: 'Waiting', refunded: 'Refunded' };
  const label = LABELS[status] ?? 'Unknown';
  ```
- reviewer-finds: N/A.
- blocking: false
- expected-order: simplifier-then-reviewer (resolve-certify COMPLEX). After simplifier rewrites, reviewer should find nothing.

### C4 — Commented-out code
- complexity: STANDARD
- invocation: resolve-certify
- diff:
```ts
export function fetchPrice(id: string) {
  // const cache = await redis.get(id);
  // if (cache) return JSON.parse(cache);
  return fetchFromDB(id);
}
```
- reviewer-finds: nothing (not a bug).
- note: at STANDARD, simplifier is NOT invoked for resolve-certify. So this issue slips unless user escalates to COMPLEX. The scenario tests the orchestrator's scope, not agent.

### C5 — Dead code + unused imports (SPECIAL: .d.ts-adjacent / types-only file)
- complexity: COMPLEX
- invocation: build-certify
- diff:
```ts
// src/types/index.ts  ← mostly types
import { DateTime } from 'luxon'; // unused
import { z } from 'zod';

export const UserSchema = z.object({ id: z.string() });
export type User = z.infer<typeof UserSchema>;

function oldHelper(x: string) { return x.trim(); } // unused
```
- reviewer-finds: nothing CRÍTICO/ALTO.
- simplifier-finds: remove unused import (`DateTime`) and unused function (`oldHelper`).
- blocking: false
- expected-order: reviewer-then-simplifier (COMPLEX build-certify). Reviewer passes clean; simplifier cleans imports.

---

## DRY (3)

### D1 — Reimplement existing util
- complexity: COMPLEX
- invocation: build-certify
- diff:
```ts
// new file src/handlers/new-feature.ts
function slugify(s: string) {
  return s.toLowerCase().replace(/\s+/g, '-').replace(/[^a-z0-9-]/g, '');
}
// ... uses slugify inline
```
- context: `src/utils/string.ts` already exports `slugify` with the same contract.
- reviewer-finds: nothing (not a bug/security/typing).
- simplifier-finds: Grep finds existing `utils/string.ts` `slugify`. Replace local function with `import { slugify } from '@/utils/string';`.
- blocking: false
- expected-order: reviewer-then-simplifier

### D2 — Pattern appears 3 times (extract)
- complexity: COMPLEX
- invocation: build-certify
- diff: three handlers each contain:
```ts
const auth = req.headers.authorization;
if (!auth?.startsWith('Bearer ')) throw new HttpError(401, 'unauthorized');
const token = auth.slice('Bearer '.length);
const user = await verifyJwt(token);
```
- reviewer-finds: nothing.
- simplifier-finds: extract `requireBearer(req)` helper in `src/auth/middleware.ts` and replace the 3 occurrences. Only extract because pattern is 3+.
- blocking: false

### D3 — Pattern appears 2 times (TRAP: don't extract)
- complexity: COMPLEX
- invocation: resolve-certify (simplifier-then-reviewer)
- diff: two handlers share a 4-line date-normalising snippet.
- reviewer-finds: nothing.
- simplifier-finds: NOTHING — rule of 3 not yet triggered. Agent must resist the urge to extract. Also: the two handlers serve different stakeholders (invoicing vs reporting) → even if a 3rd occurrence appeared, independent-evolution rule suggests keeping duplication. Simplifier should EXPLICITLY acknowledge "2 occurrences, skip".
- blocking: false
- expected-order: simplifier-then-reviewer

---

## Acceptance Criteria (2)

### A1 — All criteria covered
- complexity: STANDARD
- invocation: build-certify, spec path passed
- spec excerpt:
```
## Acceptance Criteria
- [ ] POST /v1/comments validates body with Zod
- [ ] Returns 201 with comment id on success
- [ ] Returns 400 on invalid body
```
- diff: implements all three; tests in `comments.test.ts` cover the three paths; Zod schema present.
- reviewer-finds: PASS — all AC have code + test evidence. Output table should include AC-check rows marked EVIDÊNCIA.
- blocking: false

### A2 — One criterion missing test
- complexity: STANDARD
- invocation: build-certify, spec path passed
- spec excerpt:
```
## Acceptance Criteria
- [ ] Rate limit 10 req/min per IP
- [ ] Exceeding limit returns 429
- [ ] Audit log written on limit hit
```
- diff: implements rate limit + 429 + audit log, but no test for audit log.
- reviewer-finds: BLOCKING — criterion "Audit log written on limit hit" has CODE evidence but NO TEST evidence. Mark BLOCKING with criterion reference. Fix (if <10 lines): add test; else REPORT.
- blocking: true

---

## Mixed / traps (2)

### M1 — Bug + opportunistic refactor in same diff
- complexity: COMPLEX
- invocation: build-certify (reviewer → simplifier)
- diff:
```ts
// src/services/invoice.ts
-export function total(items: Item[]) {
-  let t = 0;
-  for (const i of items) t += i.price;
-  return t;
+// refactored + bug
+export function total(items: Item[]) {
+  return items.reduce((s, i) => s + i.price * i.qty, 0); // BUG: prior code ignored qty — this is a behaviour change masquerading as refactor
 }
```
- reviewer-finds: ALTO unintended behaviour change. Prior `total` ignored `qty`; new implementation multiplies by `qty`. If intended, spec should state it; else revert. Fix: surface as BLOCKING and either (a) revert `*i.qty` or (b) add test proving the new behaviour is desired AND confirm spec intent. Reviewer should NOT touch the reduce→for conversion itself (that's simplifier's lane, but the reduce is fine stylistically anyway).
- simplifier-finds: nothing material (reduce is clean).
- blocking: true
- expected-order: reviewer-then-simplifier. Simplifier must NOT "improve" the buggy branch.

### M2 — Reviewer fix removes simplifier-renamed code (ordering trap)
- complexity: COMPLEX
- invocation: resolve-certify (simplifier → reviewer — THIS IS WHERE ORDER MATTERS)
- diff:
```ts
function fn(d: any[]) {
  try { return d.map(x => JSON.parse(x)); } catch (e) {}
}
```
- simplifier (first): renames `fn` → `parseEntries`, `d` → `rawItems`. Leaves `any` alone (typing is reviewer's lane). Removes empty catch? Empty catch is error-handling, NOT clarity — simplifier MUST leave it alone.
- reviewer (second): sees `any` (CRÍTICO) + empty catch swallowing errors (ALTO). Fixes both: narrows to `string[]`, replaces body with `return rawItems.map(x => { try { return JSON.parse(x); } catch (e) { throw new ParseError(x, e); } });`. Since simplifier already renamed vars, reviewer's fix uses the new names — ordering works.
- blocking: true
- expected-order: simplifier-then-reviewer works; the trap is simplifier overstepping into error-handling. If simplifier had "fixed" empty catch, reviewer's fix would clobber it. Scenario validates boundary.

---

## Summary of special files used

- B4: `src/utils/pagination.test.ts` (test-only)
- C5: `src/types/index.ts` (types-mostly file, adjacent to .d.ts behaviour)
- T3: `types/shared.d.ts` (.d.ts file)

Plus: S2/S6 touch config-adjacent env/PII handling; explicit config YAML/JSON not used — substituted by .d.ts + types file + test file to cover the "special file" requirement with 3 distinct kinds.
