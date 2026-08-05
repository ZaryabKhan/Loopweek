# 🚀 Release Cheatsheet

Quick, copy-paste reference for publishing a new version to **both** the Play Store and GitHub.

> Current version: `1.0.0+1`. The next release uses `1.2.0+2` in the examples below — just swap in your own numbers.

---

## ⏱️ The whole flow at a glance

1. **Bump the version** → PR → merge (because `master` is protected).
2. **Play Store** → build AAB locally → upload to Play Console. *(manual, ~5 min)*
3. **GitHub** → push a tag → CI auto-builds the APK & publishes the release. *(one command)*

That's it. The Play side is manual; the GitHub side is automatic.

---

## ✅ Before you start

- You're on `master`, working tree clean, and CI is green on GitHub.
- `android/key.properties` exists (points to your **Play upload key**) — needed only for the Play AAB step.
- The 4 GitHub release secrets are already set (they're permanent; you don't touch them again).

```bash
git checkout master && git pull
```

---

## Step 1 — Bump the version

In `pubspec.yaml`, change the `version:` line:

```yaml
version: 1.2.0+2      # was 1.0.0+1
```

- The part **before** `+` is `versionName` (human-readable, e.g. `1.2.0`).
- The part **after** `+` is `versionCode` — **always +1, never reuse a number**.

Commit it on a branch and open a PR (required — `master` is protected):

```bash
git checkout -b chore/bump-version-1.2.0
git add pubspec.yaml
git commit -m "Bump version to 1.2.0"
git push -u origin chore/bump-version-1.2.0
```

On GitHub: open a PR → wait for the **"Build & Test"** check to go green 🟢 → **Squash and merge**.

Then pull the merged master:

```bash
git checkout master
git pull
```

---

## Step 2 — Play Store (manual, AAB)

Build the signed **AAB** with your Play upload key:

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

Upload it:

1. Go to **Play Console** → your app → **Production** → **Create new release**
2. Upload `app-release.aab`
3. Add release notes → **Review release** → **Start rollout**

> Google Play App Signing is on, so Google re-signs the final APK with its own key. You only ever upload an AAB signed with your **upload key**.

---

## Step 3 — GitHub (automatic, APK)

One command — push a tag matching the version:

```bash
git tag v1.2.0
git push origin v1.2.0
```

That's it. CI now automatically:
- Builds a signed release APK (with the **GitHub-release key**)
- Creates a GitHub Release named `v1.2.0`
- Attaches `Loopweek-v1.2.0.apk`
- Auto-generates release notes from the PRs/commits since the last tag

Watch it live: **GitHub repo → Actions tab → "Release" workflow**. When it finishes, the APK appears in the **Releases** section, ready for users to install.

---

## 📋 Copy-paste the whole thing

```bash
# 0. Start clean
git checkout master && git pull

# 1. Bump version (edit version: in pubspec.yaml first)
git checkout -b chore/bump-version-1.2.0
git add pubspec.yaml
git commit -m "Bump version to 1.2.0"
git push -u origin chore/bump-version-1.2.0
#    → open PR on GitHub, wait for green CI, Squash & merge, then:
git checkout master && git pull

# 2. Play Store — build & upload AAB
flutter build appbundle --release
#    → upload build/app/outputs/bundle/release/app-release.aab in Play Console

# 3. GitHub — push tag → automatic APK release
git tag v1.2.0
git push origin v1.2.0
#    → watch the "Release" workflow in the Actions tab
```

---

## 🧠 Things to remember

| Thing | Why |
|-------|-----|
| `versionCode` (after `+`) must **always increase** (never reuse a number) | Play Store rejects uploads with a lower/equal code |
| Tag must match the version (`v1.2.0` for `1.2.0`) | The tag becomes the GitHub Release name & APK filename |
| GitHub APK and Play Store app **can't coexist** on one device | Different signatures (Play App Signing). Users pick one source. Normal for open-source apps. |
| Keep `loopweek-github.jks` backed up safely | All GitHub releases must use the same key, or users can't update in place |
| Keep your **Play upload key** backed up safely | Lose it → must contact Play Console support to reset |
| The GitHub release secrets are permanent | You set them once; never edit them unless you regenerate the GitHub key |

---

## 🆘 If something goes wrong

- **GitHub release didn't appear** → check the **Actions** tab; the "Release" workflow failed. Most common cause: a secret name typo or a wrong password. Re-check the 4 secrets.
- **`flutter build appbundle` produces an unsigned / `app-release-unsigned.aab`** → `android/key.properties` is missing or has a wrong path. Recreate it from `android/key.properties.example`.
- **Play Console rejects the upload** → `versionCode` wasn't increased, or you uploaded an APK instead of an AAB.
- **CI build fails on the APK** → same signing-config issue as above, but in CI the keystore comes from secrets, so check `RELEASE_KEYSTORE_BASE64` decodes correctly.

---

## 📜 Where to find more detail

The full, in-depth explanation (two-keystore setup, Play App Signing notes, secret creation) is in [RELEASE.md](RELEASE.md). This cheatsheet is the fast version.