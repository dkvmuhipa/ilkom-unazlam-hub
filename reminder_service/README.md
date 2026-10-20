# ILKOM reminder gateway

Separate Node 22 service. It keeps the existing WAHA NOWEB session and forwards
only the Flutter endpoints it needs. No second WhatsApp login or browser runs here.
The service has no npm dependencies. Run `npm test` and `npm start`.

## Deploy on Railway

Create a separate service from this repository with root directory
`/reminder_service` and its Dockerfile. Attach a persistent volume mounted at
`/data`, with **one replica**. Disable serverless sleeping. Set variables from
`.env.example`; never commit credentials. Keep the WAHA service running separately.
Use the existing WAHA API key as `WAHA_UPSTREAM_API_KEY`. `GATEWAY_API_KEY`
authenticates the Flutter client; `WEBHOOK_SECRET` authenticates incoming events.
Health check: `/health`. Target port: `8080` (or Railway's `PORT`).

Run `supabase_migrations/20261018_reminder_schedule.sql` on the existing database.
Set the server-only Supabase service role key in Railway. The service reads the
schedule RPC every 30 seconds while enabled, including today's/tomorrow's
cancellations and time/room overrides. It does not write to Supabase.
The RPC is callable only by service_role; do not put this key in Flutter.
Without Supabase credentials, manually synced schedules expire after 24 hours.

Configure the existing WAHA session's `config.webhooks` to include:

```json
{
  "url": "https://YOUR-REMINDER-DOMAIN/webhooks/waha",
  "events": ["message"],
  "customHeaders": [{"name": "X-Webhook-Secret", "value": "YOUR-WEBHOOK-SECRET"}]
}
```

Preserve all other existing WAHA session configuration when updating it.
Do not remove other webhooks. Test webhook authentication before enabling.
Only messages from the configured Komti phone for the configured WAHA session
are accepted. Group identities are ignored. LID identities are resolved using
WAHA's authenticated LID-to-phone API; an unresolved LID is ignored, never guessed.
Replies must be `KIRIM <id>` or `BATAL <id>` so simultaneous reminders cannot be
confused. NOWEB's store must be enabled for its LID mapping API.

In Flutter, change the WAHA Base URL to the reminder service's public domain and
set its `GATEWAY_API_KEY`. The same panel continues to manage WAHA and now detects
the `auto-reminder` capability. Save the Komti number and enable the feature.
Sync courses, then use the simulation button: simulations send **only to Komti**.
Confirm a simulation with its ID and verify history before enabling live schedules.

## Delivery and restart behavior

Configuration, schedules, pending jobs, and history persist in an atomically
replaced JSON file. Sending is claimed before network calls. An uncertain result
is never retried automatically, because the recipient may already have received
it; inspect WAHA and history before manual recovery. This provides at-most-once
attempts, not guaranteed exactly-once delivery. Keep one process/replica per volume.
Turning the feature off pauses sends; pending jobs more than 24 hours overdue
expire. A current Supabase cancellation cancels the matching pending job.
Data-file corruption fails startup rather than silently losing deduplication data.
There are no automatic test messages to lecturers and no production credentials
in source or test fixtures.
