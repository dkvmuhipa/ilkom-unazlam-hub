# Supabase account creation

The admin account form calls the `admin-create-student` Edge Function. The
function checks the caller against an active `ADMIN` row in `public.students`,
creates a student profile, invites the student's email, then links the Auth user
to the profile. It assigns the new account the `MAHASISWA` role; the client
cannot choose a privileged role.

The function is deployed to the `ilkomunazlam` project at:
`https://boffbpvyqhajfiqzyztx.supabase.co/functions/v1/admin-create-student`.

## Deploy

From the repository root, with the Supabase CLI installed and authenticated:

```powershell
supabase login
supabase link --project-ref boffbpvyqhajfiqzyztx
supabase functions deploy admin-create-student --project-ref boffbpvyqhajfiqzyztx
```

The function requires `verify_jwt = true`, configured in `config.toml`. Keep the
project's secret/service role key in Supabase's server environment only. Never
put it in Flutter build variables, source code, or app configuration.

## First administrator

The project currently has no Auth users or student rows, so the account form
cannot be used until the first administrator is provisioned through the trusted
Supabase Dashboard:

1. In **Authentication → Users**, add or invite the first administrator.
2. In **SQL Editor**, replace the placeholders below and run the insert for
   that administrator. It only inserts when the email matches exactly one Auth
   user:

   ```sql
   INSERT INTO public.students
     (id, nim, nama, email, no_wa, peminatan, prodi, semester, kelas,
      role, jabatan, is_aktif, auth_user_id)
   SELECT
     'ADMIN_NIM', 'ADMIN_NIM', 'NAMA_ADMIN', lower('EMAIL_ADMIN'), '', '',
     'Ilmu Komunikasi', 1, 'Ilmu Komunikasi', 'ADMIN', 'Admin', true, u.id
   FROM auth.users AS u
   WHERE lower(u.email) = lower('EMAIL_ADMIN');
   ```

3. Sign in to the app with that administrator account.

Use the actual administrator's name, NIM, and email in the insert; do not use
student demo data. The app then sends invitation emails for new student accounts
through Supabase Auth. Configure the project's email delivery and redirect URL
before using this in production.
