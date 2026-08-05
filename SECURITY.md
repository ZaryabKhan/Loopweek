# Security Policy

## Supported versions

Security fixes are applied to the latest released version of Loopweek.

| Version | Supported |
| ------- | --------- |
| latest  | ✅        |
| older   | ❌        |

## Reporting a vulnerability

We take security seriously. If you discover a vulnerability in Loopweek, **please do not open a public GitHub issue**.

Instead, report it **privately** using one of these options:

1. **GitHub private vulnerability reporting** (preferred): go to the
   [Security tab](https://github.com/ZaryabKhan/loopweek/security/advisories/new)
   and choose **"Report a vulnerability"**.
2. **Email**: contact the maintainer at **appcodecraft@gmail.com** with the subject
   `[Loopweek Security] <short summary>`.

Please include:

- A description of the issue and its potential impact.
- Steps to reproduce (proof of concept).
- The app version and Android version affected.

We will acknowledge your report as soon as possible and work with you on a fix
and coordinated disclosure. Please give us reasonable time to address the issue
before any public disclosure.

## What this project does (and does not) handle

- Loopweek is a **fully client-side** Android app. There is **no backend server** and **no API keys** shipped in the repository.
- The app stores data locally on the device using a Drift (SQLite) database.
- There is **no network code** in the release build — no analytics, no telemetry, no crash reporting that sends data anywhere.
- The **Play Store signing key is private** and is **not** part of this repository, so exposing the source cannot compromise app signing or your other published apps.