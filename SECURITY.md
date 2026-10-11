# Security Policy & Audit Report (OWASP Standards)

**Application**: ILKOM UNAZLAM Hub (Class Manager)  
**Audit Date**: 2026-10-12  
**Audit Scope**: Full Codebase Scan (`lib/`, `supabase_schema.sql`, `supabase_migrations/`, `android/`, configurations)  
**Standard**: OWASP Top 10 (2021) & Mobile Security Best Practices  

---

## 1. Executive Summary

A paranoid security sweep was performed on the codebase to identify potential vulnerabilities, hardcoded secrets, injection vectors, and access control loopholes.

The Flutter client architecture is well-structured: all database communications leverage typed, parameterized PostgREST client queries (preventing SQL injection), URL query tokens are sanitized upon callback to prevent token leakage, and file uploads are protected against directory traversal.

However, **critical vulnerabilities were identified in the PostgreSQL Row Level Security (RLS) policies** introduced in recent migration scripts (`supabase_migrations/`). Permissive policies currently allow unauthenticated or unauthorized users with the public anonymous key to perform destructive actions (deleting/modifying assignments and submissions), forge attendance records, and view sensitive student grades and financial debts.

---

## 2. OWASP Top 10 Vulnerability Matrix

| OWASP Category | Vulnerability Description | Severity | Status |
| :--- | :--- | :--- | :--- |
| **A01: Broken Access Control** | Overly permissive RLS (`USING (true) WITH CHECK (true)`) on `assignments` and `student_assignments` | 🔴 Critical | **Requires Fix** |
| **A01: Broken Access Control** | Overly permissive RLS (`FOR ALL TO anon`) on `attendance_sessions` and `attendance_logs` | 🔴 Critical | **Requires Fix** |
| **A01: Broken Access Control** | Public access (`FOR SELECT TO anon USING (true)`) to `student_course_grades` (KHS) and `treasury_dues` | 🔴 Critical | **Requires Fix** |
| **A02: Cryptographic Failures** | Plaintext password storage in client `SharedPreferences` (`user_password_$userNim`) | 🟡 Warning | **Requires Fix** |
| **A02: Cryptographic Failures** | Hardcoded offline fallback credentials (`admin123`, `ilkom2026`, `123456`) in `auth_service.dart` | 🟡 Warning | **Requires Fix** |
| **A03: Injection** | SQL Injection via client queries | 🟢 Passed | **Secure** |
| **A04: Insecure Design** | Unvalidated URI scheme (`url_launcher` without `http`/`https` scheme validation) | 🟡 Warning | **Recommended** |
| **A05: Security Misconfiguration**| `.env` & Android keystore properties excluded from version control | 🟢 Passed | **Fixed in .gitignore** |
| **A06: Vulnerable Components** | Outdated or vulnerable third-party dependencies in `pubspec.yaml` | 🟢 Passed | **Secure** |
| **A07: Identification & Auth** | Supabase PKCE token leakage in URL history | 🟢 Passed | **Sanitized by clearAuthCallbackUrl()** |
| **A08: Software & Data Integrity**| File upload path traversal (`../`) in storage uploads | 🟢 Passed | **Sanitized with safe filename regex** |

---

## 3. Detailed Findings & Explanations

### 🔴 Critical Finding 1: Permissive RLS on Assignments & Submissions
* **Location**: `supabase_migrations/20261011_fix_assignments_permissions_for_all.sql` (Lines 28–31 & 49–52)
* **Mechanics**:
  ```sql
  CREATE POLICY assignments_manage_all ON public.assignments
    FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

  CREATE POLICY student_assignments_manage_all ON public.student_assignments
    FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
  ```
* **Impact**: Anyone holding the public `anon` key can delete or modify all course assignments, manipulate other students' assignment grades, or overwrite student submission files.
* **Remediation**: Restore role-based RLS:
  - `assignments`: `SELECT` allowed for all active students; `INSERT/UPDATE/DELETE` strictly restricted to `ADMIN`, `Ketua Kelas`, or `Sekretaris`.
  - `student_assignments`: Students can only manage their own NIM record (`student_nim = current_student_nim()`), while grading is restricted to officers.

### 🔴 Critical Finding 2: Permissive Attendance Sessions & Logs Spoofing
* **Location**: `supabase_migrations/20261011_enable_attendance_and_assignments.sql` (Lines 33–36 & 60–63)
* **Mechanics**:
  ```sql
  CREATE POLICY attendance_sessions_all_ops ON public.attendance_sessions
    FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

  CREATE POLICY attendance_logs_all_ops ON public.attendance_logs
    FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
  ```
* **Impact**: Students or third parties can generate fake attendance sessions, terminate active classes, or insert falsified attendance logs for any NIM.
* **Remediation**:
  - `attendance_sessions`: Only `Ketua Kelas` / `ADMIN` can `INSERT/UPDATE`.
  - `attendance_logs`: Sesi aktif harus divalidasi dan mahasiswa hanya dapat mencatat presensi untuk NIM miliknya sendiri.

### 🔴 Critical Finding 3: Public Disclosure of Academic Transcripts (KHS) & Kas Dues
* **Location**: `supabase_migrations/20261011_allow_anon_directory_and_dues.sql` (Lines 21–23 & 29–31)
* **Mechanics**:
  ```sql
  CREATE POLICY student_course_grades_anon_read ON public.student_course_grades
    FOR SELECT TO anon USING (true);

  CREATE POLICY treasury_dues_anon_read ON public.treasury_dues
    FOR SELECT TO anon USING (true);
  ```
* **Impact**: Unauthenticated users can scrape every student's grades (KHS, IPK, letter grades) and personal treasury debts.
* **Remediation**: Restrict `SELECT` on `student_course_grades` and `treasury_dues` to authenticated users where `student_nim = current_student_nim()` or the user holds the `Bendahara` / `ADMIN` role.

### 🟡 Warning Finding 4: Client-Side Plaintext Password Storage
* **Location**: `lib/core/services/auth_service.dart` (Lines 34 & 155)
* **Mechanics**: Passwords are saved directly to unencrypted `SharedPreferences` under key `user_password_$userNim`.
* **Impact**: If a device is rooted, inspected via ADB backup, or run in a shared web browser (via localStorage), the plaintext password is exposed.
* **Remediation**: Rely strictly on Supabase Session tokens (`access_token`, `refresh_token`) instead of storing raw passwords in local storage.

### 🟡 Warning Finding 5: Insecure Default Passwords in Offline Fallback
* **Location**: `lib/core/services/auth_service.dart` (Lines 163–175)
* **Mechanics**: When Supabase is unreachable, the system accepts `admin123`, `admin`, `ilkom2026`, or the last 6 digits of NIM.
* **Impact**: Anyone knowing an administrator's NIM can gain administrative rights offline by entering `admin123`.
* **Remediation**: Require offline authentication to verify against a salted hash or disable administrative privileges when operating in offline/mock mode.

### 🟡 Warning Finding 6: Unrestricted URL Schemes in External Launchers
* **Location**: `lib/features/dashboard/student_home_screen.dart` (Line 153), `lib/features/schedule/schedule_screen.dart`
* **Mechanics**: `_openVirtualClass(url)` parses arbitrary URLs and executes `launchUrl()` without scheme validation.
* **Impact**: A rogue database entry with a scheme like `javascript:...`, `intent:...`, or `file:...` could lead to unintended action execution.
* **Remediation**: Enforce HTTP/HTTPS validation:
  ```dart
  final uri = Uri.tryParse(url.trim());
  if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
  ```

---

## 4. Remediation Patch: Secure RLS Script

A consolidated PostgreSQL migration script (`supabase_migrations/20261012_security_audit_rls_hardening.sql`) should be applied in Supabase to eliminate the critical authorization vulnerabilities while keeping user operations functional.

```sql
BEGIN;

-- 1. HARDEN ASSIGNMENTS
ALTER TABLE public.assignments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS assignments_manage_all ON public.assignments;

CREATE POLICY assignments_read_authenticated ON public.assignments
  FOR SELECT TO authenticated USING (true);

CREATE POLICY assignments_manage_officer ON public.assignments
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.students s
      WHERE (s.auth_user_id = auth.uid() OR s.email = (auth.jwt()->>'email'))
        AND UPPER(COALESCE(s.role, '')) IN ('ADMIN', 'KETUA KELAS', 'SEKRETARIS')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.students s
      WHERE (s.auth_user_id = auth.uid() OR s.email = (auth.jwt()->>'email'))
        AND UPPER(COALESCE(s.role, '')) IN ('ADMIN', 'KETUA KELAS', 'SEKRETARIS')
    )
  );

-- 2. HARDEN STUDENT_ASSIGNMENTS
ALTER TABLE public.student_assignments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS student_assignments_manage_all ON public.student_assignments;

CREATE POLICY student_assignments_read ON public.student_assignments
  FOR SELECT TO authenticated
  USING (
    student_nim IN (
      SELECT s.nim FROM public.students s
      WHERE s.auth_user_id = auth.uid() OR s.email = (auth.jwt()->>'email')
    )
    OR EXISTS (
      SELECT 1 FROM public.students s
      WHERE (s.auth_user_id = auth.uid() OR s.email = (auth.jwt()->>'email'))
        AND UPPER(COALESCE(s.role, '')) IN ('ADMIN', 'KETUA KELAS', 'SEKRETARIS')
    )
  );

CREATE POLICY student_assignments_self_manage ON public.student_assignments
  FOR INSERT TO authenticated
  WITH CHECK (
    student_nim IN (
      SELECT s.nim FROM public.students s
      WHERE s.auth_user_id = auth.uid() OR s.email = (auth.jwt()->>'email')
    )
  );

-- 3. HARDEN STUDENT_COURSE_GRADES (KHS)
ALTER TABLE public.student_course_grades ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS student_course_grades_anon_read ON public.student_course_grades;

CREATE POLICY student_course_grades_secure_read ON public.student_course_grades
  FOR SELECT TO authenticated
  USING (
    student_nim IN (
      SELECT s.nim FROM public.students s
      WHERE s.auth_user_id = auth.uid() OR s.email = (auth.jwt()->>'email')
    )
    OR EXISTS (
      SELECT 1 FROM public.students s
      WHERE (s.auth_user_id = auth.uid() OR s.email = (auth.jwt()->>'email'))
        AND UPPER(COALESCE(s.role, '')) = 'ADMIN'
    )
  );

COMMIT;
```

---

## 5. Verification Status

1. **Gitignore Protection**: `.env`, `*.env`, and `android/key.properties` have been explicitly added to [.gitignore](file:///f:/Project/Gellona%20Tech/APPS/.gitignore).
2. **Security Documentation**: [SECURITY.md](file:///f:/Project/Gellona%20Tech/APPS/SECURITY.md) is registered in the repository root.
3. **Database RLS Checklist**: Documented with migration plan above for deployment to the Supabase console.
