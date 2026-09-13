# Data Safety (Google Play) & App Privacy (Apple) — checklist for Pong

After you complete the forms, publish a matching **privacy policy URL** as described in [`docs/PUBLISHING_PRIVACY.md`](PUBLISHING_PRIVACY.md).

Use this document when filling **Google Play → App content → Data safety** and **App Store Connect → App Privacy**. Align answers with your **actual** production build (especially whether **ads** and **IAP** are enabled).

## Data types commonly applicable

| Data type | Collected? | Purpose | Linked to user? | Shared? |
|-----------|------------|---------|-------------------|---------|
| **User IDs** (Firebase UID, anonymous) | Yes (if Firebase Auth used) | Account / online play / sync | Yes (pseudonymous) | With Google (Firebase) as processor |
| **Gameplay / diagnostics** (scores, room state, crashes if you add Crashlytics) | Yes if stored in Firestore or crash SDK | Gameplay / stability | Often yes | With Google if used |
| **Purchase history** | Yes if IAP used | Entitlements | Yes | With Apple / Google as payment processors |
| **Advertising ID / device advertising** | Only if ads enabled | Ads | Per Google/Apple rules | With ad partners if ads enabled |
| **Approximate location** | Rare for this app unless ad SDK infers | Ads/analytics if enabled | Varies | Varies |

**Encryption in transit:** Yes (HTTPS to Firebase / Google APIs).

## Google Play — Data safety (typical answers)

1. **Does your app collect or share any of the required user data types?**  
   - If only anonymous Firebase UID + game data: answer **Yes** for minimal types, or **No** for types you truly do not touch—be precise.

2. **Data collection**  
   - Declare **Firebase** as the backend; collection is for **app functionality** and **analytics** only if you ship analytics.

3. **Data deletion**  
   - Provide a support contact or in-app flow if you offer deletion.

## Apple — Privacy Nutrition Labels (typical)

- **Contact Info:** Usually **No** (unless you collect email).  
- **Identifiers:** **Yes** if Firebase UID / device IDs used.  
- **Usage data:** **Yes** if analytics or ads.  
- **Diagnostics:** **Yes** if Crashlytics or similar.  

**Tracking:** If you use ads that track across apps/websites, declare per ATT. If no cross-app tracking, answer accordingly.

## Export compliance (Apple)

If the app only uses **standard HTTPS/TLS** for client-server communication and does not implement custom cryptography beyond OS APIs, you typically use Apple’s **standard encryption** declaration. Confirm with your legal counsel for your jurisdiction.

## Source of truth

The shipped behavior is defined in code and Firebase configuration. Update this checklist whenever you add SDKs (analytics, ads, social login, etc.).
