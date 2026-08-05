# Release Workflow

This document describes how to publish a new version of Loopweek to both
distribution channels:

- **Google Play Store** → `.aab`, signed with your **Play upload key**, built & uploaded **manually**.
- **GitHub Releases** → `.apk`, signed with a **dedicated GitHub-release key**, built & published **automatically** by CI when you push a tag.

> **Two separate signing keys (important):** Loopweek uses **Google Play App
> Signing**. That means Google holds the *app signing key* and re-signs the APK
> it distributes via Play. You sign the AAB you upload with your *upload key*.
> Because of this, an APK you build locally can **never** have the same
> signature as the Play Store build — so the GitHub APK and the Play Store app
> are **mutually exclusive**: a user can have one or the other installed, not
> both at the same time (same package name, different signatures → "App not
> installed"). This is expected and normal for open-source Android apps.
>
> To keep things clean and safe, the GitHub APK is signed with a **separate,
> dedicated "GitHub-release" keystore** — never your Play upload key. Your Play
> upload key never touches GitHub's servers.

## Prerequisites (one-time setup)

### A) Play Store — local upload key

1. Have your Play **upload** keystore (`.jks`) on your machine.
2. Create `android/key.properties` **in the `android/` folder** (next to
   `build.gradle.kts`). It is gitignored and must never be committed.
   Use `android/key.properties.example` as a template:

   ```properties
   storeFile=/absolute/path/to/your/play-upload-key.jks
   storePassword=your-store-password
   keyAlias=your-key-alias
   keyPassword=your-key-password
   ```

   `storeFile` may be an absolute path, or a path relative to `android/app/`
   (where `build.gradle.kts` reads it). When present, the `release` build type
   signs automatically with these credentials (used for the local AAB build).

### B) GitHub Releases — dedicated key as repository secrets

1. Generate a **new, dedicated** keystore just for GitHub releases (do **not**
   reuse your Play upload key):

   ```bash
   keytool -genkeypair -v \
     -keystore loopweek-github.jks \
     -alias github -keyalg RSA -keysize 2048 -validity 10000 \
     -storepass STOREPW -keypass KEYPW
   ```

   **Back this file up somewhere safe.** All future GitHub releases must be
   signed with the same key, or users won't be able to update in place.

2. Base64-encode it (for storing as a secret):

   ```bash
   base64 -i loopweek-github.jks | pbcopy    # macOS (copies to clipboard)
   # or:  base64 -w 0 loopweek-github.jks    # Linux
   ```

3. In GitHub: **Settings → Secrets and variables → Actions → New repository
   secret**, and add these four:

   | Secret name | Value |
   |-------------|-------|
   | `RELEASE_KEYSTORE_BASE64` | the base64 output from step 2 |
   | `RELEASE_STORE_PASSWORD` | the `storepass` you set |
   | `RELEASE_KEY_ALIAS` | `github` (or whatever alias you chose) |
   | `RELEASE_KEY_PASSWORD` | the `keypass` you set |

   GitHub encrypts secrets at rest; they are only decrypted during the CI run
   and are masked in logs.

> Until these secrets are added, the automated release workflow will fail to
> sign. Add them once and you're set for every future release.

## 1. Prepare the release (every release)

1. Make sure `master` is up to date and CI is green.
2. Bump the version in `pubspec.yaml`:
   - `version: 1.0.0+1` — the part **before** `+` is `versionName` (human-readable,
     e.g. `1.2.0`), the part **after** `+` is `versionCode` (must always
     increase; never reuse a number).
   - Example: `version: 1.0.0+1` → `version: 1.2.0+2`
3. Commit the bump and open a PR (branch protection requires it). Once CI is
   green, **Squash and merge** it to `master`, then pull locally:
   `git checkout master && git pull`.

## 2. Publish the GitHub Release (automatic)

This part is fully automated by `.github/workflows/release.yml`.

```bash
git tag v1.2.0
git push origin v1.2.0
```

Pushing the tag triggers CI to: build a signed release APK → create a GitHub
Release for that tag → attach `Loopweek-v1.2.0.apk` → auto-generate release
notes from the PRs/commits since the previous tag.

That's it. The APK appears in the **Releases** section on GitHub, and users can
download and install it (they must allow "Install unknown apps" for their
browser/file manager — standard sideloading).

> Watch the run under the **Actions** tab. If it fails, the most likely cause
> is a missing/incorrect release secret — re-check the four secrets above.

## 3. Publish to the Play Store (manual)

Google Play requires **Android App Bundles (.aab)**, built and signed with your
**upload key** locally.

```bash
flutter build appbundle --release
```

The signed AAB lands at
`build/app/outputs/bundle/release/app-release.aab`.

Then upload it:

1. Go to https://play.google.com/console → your app → **Production** (or
   internal testing first) → **Create new release**.
2. Upload `app-release.aab`.
3. Add release notes, then **Review release** → **Start rollout**.

> Keep your **upload keystore** safe. If you lose it, you must contact Play
> Console support to reset it. (This is separate from the GitHub-release key.)

## Quick reference (every release)

```bash
# 1. After merging the version-bump PR to master:
git checkout master && git pull

# 2. Tag & push → triggers the AUTOMATIC GitHub Release (APK attached)
git tag v1.2.0
git push origin v1.2.0

# 3. Manually build & upload the AAB to the Play Store
flutter build appbundle --release
#    then upload build/app/outputs/bundle/release/app-release.aab in Play Console
```

## Which artifact goes where?

| Target      | Format | How it's produced | Signing key | Automatable |
|-------------|--------|-------------------|-------------|-------------|
| Play Store  | `.aab` | local `flutter build appbundle`, manual upload | Play **upload key** (Google re-signs) | Manual upload |
| GitHub      | `.apk` | CI on tag push (`release.yml`) | dedicated **GitHub-release key** (repo secret) | ✅ Automatic |
| Debug (dev) | `.apk` | local `flutter build apk --debug` | debug key | — |