# Share Sahalat with clients (web demo)

The app uses **hash URLs** (`#/splash`, `#/nav-steps`), so it works on any static file host without special rewrite rules.

## Option A — Stable link (recommended): Netlify / Cloudflare Pages

1. Open PowerShell in this folder (`sahalat` project root, where `pubspec.yaml` is).
2. Run:

   ```powershell
   .\scripts\publish-for-clients.ps1 -Mode StaticHost
   ```

3. Upload the **`build\web`** folder (entire folder contents) to:
   - **Netlify Drop:** [https://app.netlify.com/drop](https://app.netlify.com/drop)  
   - **Cloudflare Pages:** dashboard → *Workers & Pages* → *Create* → *Upload assets*

4. Share the site URL with clients, e.g.  
   `https://your-site.netlify.app/#/splash`

Each upload can produce a new random subdomain unless you connect a custom domain in that host’s settings.

## Option B — Quick temporary link: Cloudflare Quick Tunnel + XAMPP

Good for a same-day demo; the URL changes every time you restart the tunnel (unless you configure a named tunnel in Cloudflare).

1. Build and copy into XAMPP:

   ```powershell
   .\scripts\publish-for-clients.ps1 -Mode Xampp
   ```

2. Start **Apache** in XAMPP. Check: [http://127.0.0.1/sahalat/#/splash](http://127.0.0.1/sahalat/#/splash)

3. Install [cloudflared](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/), then run:

   ```bash
   cloudflared tunnel --url http://127.0.0.1:80
   ```

4. Copy the printed `https://….trycloudflare.com` URL and add the path, for example:  
   `https://random-name.trycloudflare.com/sahalat/#/splash`

## Flutter / paths

- **Static host:** build uses `--base-href /` (site at domain root).
- **XAMPP:** build uses `--base-href /sahalat/` to match `http://localhost/sahalat/`.

If your Flutter SDK is not on `PATH`, install it or edit `publish-for-clients.ps1` and set the path to `flutter.bat`.
