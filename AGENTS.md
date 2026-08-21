# PROJECT CONTEXT: RICE UNIVERSITY URL SHORTENER & QR STUDIO

## 1. SPECS & ENV
- **Type**: Web-only app (Flutter Web, Dart) + Firebase (Auth, Firestore, Cloud Functions, Hosting).
- **Domains**: Production `link.thejambers.com`, future migration target `rice.edu`.
- **Target Platform**: Modern web browsers (Desktop/Tablet/Mobile responsive).
- **Versions**: Always install & resolve latest stable versions of packages/frameworks. Keep GitHub Actions versions as configured (e.g., `actions/checkout@v6`).

## 2. AUTHENTICATION
- **Provider**: Firebase Google Auth.
- **Rule**: Strict restriction to `@rice.edu` emails. Non-Rice accounts rejected with feedback. No external Rice OIT setup required.

## 3. LINK SHORTENING & REDIRECTION
- **Shortcode**: Default 5-char alphanumeric (case-insensitive base36/base62 lowercase-normalized).
- **Custom Alias**: URL-safe strings (alphanumeric + hyphens). Check collisions & reserved paths (`app`, `api`, `login`, `static`, `r`, `dashboard`).
- **Expiration**: Optional timestamp.
- **Fallback**: Default `https://rice.edu` (user customizable).
- **Redirection**: Firebase Cloud Function (`/:code`) handles instant HTTP 301 (active) / 302 (expired -> fallback). Dashboard hosted at `/` or `/app`.

## 4. QR CODE ENGINE
- **Module Shapes**: 3 styles (`square`, `rounded`, `dots`).
- **Colors**:
  - Presets:
    - Foreground: Rice Blue (`#00205B`), Rice Gray (`#7C7E7F`), Dark Blue (`#00143D`), Light Blue (`#4B729F`), Laurel Gold (`#C19B4C`), Black (`#000000`).
    - Background (Light Brand Tones): White (`#FFFFFF`), Off-White (`#F7F7F7`), Light Gray (`#E0E2E6`), Light Blue Gray (`#ADC7DC`), Accent Light Blue (`#CFEEFC`), Transparent (`#00000000`).
  - Custom Color Picker (Hex/RGB). Default: Rice Blue foreground, White background.
- **Center Logos**: Official Rice marks with quiet zone cutout:
  1. `shield` (Rice University Crest / Shield - Academic)
  2. `owl` (Rice Owl - Spirit/Athletics)
  3. `old_english_r` (Old English R)
  4. `none`
  - Default: First option (`shield`).
- **Exports**: Web client-side Canvas/SVG rasterizer for PNG (512px, 1024px, 2048px) and scalable SVG.

## 5. UI/UX & DESIGN SYSTEM (RICE.EDU INSPIRED)
- **Aesthetic**: Institutional elegance of `rice.edu`.
- **Typography**:
  - Headings/Display: `Cormorant Garamond` (Google Font alternate for Copernicus).
  - Body/UI: `Lato` (Google Font alternate for Mallory).
- **Layout**: Top Rice Blue banner with logo/wordmark, user profile menu, crisp card surfaces, high-contrast accessible elements.
- **Dashboard Features**: Full CRUD (Create, Edit destination/fallback/expiration/QR, Toggle Active/Inactive, Delete), Search/Filter, Quick Copy, QR Download modal.

## 6. CODE ARCHITECTURE & QUALITY STANDARDS
- **SRP & DRY**: Every file <150-200 lines. Single dedicated responsibility.
- **Directory Structure**:
  - `lib/core/` (constants, theme, utils, web downloads)
  - `lib/data/` (models, services: auth, firestore, qr export)
  - `lib/presentation/` (state controllers, widgets: common, qr, links, views: auth, dashboard, 404)
  - `functions/` (Cloud Functions redirect handler)
  - `web/` (index.html, manifest, assets)
- **Routing**: Flutter Web HTML5 path URL strategy (no `#` hash routing).

## 7. DATA SCHEMAS (FIRESTORE)
```json
// Collection: links/{linkId}
{
  "id": "string",
  "userId": "string",
  "userEmail": "string",
  "shortCode": "string (lowercase)",
  "destinationUrl": "string",
  "fallbackUrl": "string (default: https://rice.edu)",
  "expiresAt": "Timestamp | null",
  "isActive": true,
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp",
  "qrConfig": {
    "fgColorHex": "#00205B",
    "bgColorHex": "#FFFFFF",
    "style": "square | rounded | dots",
    "logoType": "shield | owl | old_english_r | none"
  }
}
```
