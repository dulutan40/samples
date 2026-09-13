# Publishing the privacy policy (HTTPS URL)

App Store Connect and Google Play require a **public HTTPS URL** for your privacy policy.

## Option A — Same host as the Flutter web build (recommended)

1. Replace `YOUR_DOMAIN` and `privacy@YOUR_DOMAIN` in [`docs/PRIVACY_POLICY.md`](PRIVACY_POLICY.md) and [`web/privacy.html`](../web/privacy.html) with your real domain and contact email.
2. Align [`web/index.html`](../web/index.html) canonical / Open Graph URLs with that domain.
3. Build and deploy web per [`docs/RELEASE.md`](RELEASE.md) (Firebase Hosting). The policy is served at **`https://<your-domain>/privacy.html`** (static file next to the Flutter web output).
4. Paste that URL into **App Store Connect → App Privacy** and **Play Console → Policy** (and anywhere else the stores ask).

## Option B — GitHub Pages / other static host

Export [`docs/PRIVACY_POLICY.md`](PRIVACY_POLICY.md) to HTML (or paste into a CMS), host at a stable path, and use that URL in the consoles.

## Store questionnaires

Use the same factual statements for **Apple App Privacy / Nutrition Labels** and **Google Play Data safety** — see [`docs/DATA_SAFETY_AND_APP_PRIVACY.md`](DATA_SAFETY_AND_APP_PRIVACY.md).
