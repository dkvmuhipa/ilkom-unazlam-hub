# Supabase account creation

The admin account form calls the `admin-create-student` Edge Function. The
function checks the caller against an active `ADMIN` row in `public.students`,
creates a student profile, invites the student's email, then links the Auth user
to the profile. It assigns the new account the `MAHASISWA` role; the client
cannot choose a privileged role.

The function is deployed to the `ilkomunazlam` project at:
`https://boffbpvyqhajfiqzyztx.supabase.co/functions/v1/admin-create-student`.

## Deploy

The client must never use the legacy permissive policies from older SQL copies.
The checked-in `supabase_schema.sql` and security migration now require an active
student profile linked to Supabase Auth, scope attendance and assignment progress
to that student, and reserve class writes for the appropriate officers. For a
new project, run `supabase_schema.sql` in the SQL Editor. For an existing project,
run `supabase_migrations/20261008_secure_access.sql` in the SQL Editor. That
migration targets the existing production schema, where assignment IDs are UUIDs.
Then run `supabase_migrations/20261008_assignment_grading.sql` to enable student
file submissions, submission status, grades, feedback, private Storage access,
and class-grader RLS rules. The bucket accepts supported documents, images, or
ZIP files up to 20 MB.
Then run `supabase_migrations/20261009_student_course_grades.sql` to enable the
official course transcript and restrict grade changes to administrators. This
migration targets the existing production schema, where course IDs are UUIDs.
Do not combine these with an older copy of the schema that creates
`USING (true)` policies.

From the repository root, with the Supabase CLI installed and authenticated:

```powershell
supabase login
supabase link --project-ref boffbpvyqhajfiqzyztx
supabase functions deploy admin-create-student --project-ref boffbpvyqhajfiqzyztx
supabase functions deploy student-login --project-ref boffbpvyqhajfiqzyztx
```

The `student-login` function accepts an active student's NIM and password,
looks up the linked Auth email on the server, then returns only the refresh
token needed by the Flutter client. Email login remains available, and password
reset continues to use the student's registered email. This function has
`verify_jwt = false` so signed-out users can reach it; it validates the project's
public API key and never returns the mapped email. Deploy it before enabling NIM
login for users.

## Password recovery email

The app verifies reset links with Supabase's one-time `token_hash`, which avoids
requiring the original browser's PKCE verifier. In **Authentication → Email
Templates → Reset Password**, keep the existing message and replace its reset
link with:

```html
<p><a href="{{ .RedirectTo }}?token_hash={{ .TokenHash }}&amp;type=recovery">Atur ulang kata sandi</a></p>
```

The app passes its current origin as `redirectTo`; add that origin (for local
development, `http://localhost:5141`) to **Authentication → URL Configuration →
Redirect URLs**. Save the template, then request a new reset email. Old links
that contain `?code=` cannot be reused after changing the template.

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
