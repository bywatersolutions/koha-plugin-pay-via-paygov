# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.1.0] - 2026-08-19

### Security

- The PayGov API password is now encrypted at rest with `Koha::Encryption` (AES-256-CBC) instead of
  being stored in cleartext in Koha's `plugin_data` table. Existing passwords are migrated
  automatically on upgrade.
- The configuration form now submits via `POST` with a CSRF token, so a newly entered password no
  longer appears in staff browser URLs, browser history, or the web server access log.
- The configuration page no longer renders the stored password back into the form. The field is a
  password input and is left blank; leave it blank to keep the existing password.

### Fixed

- **Saving the configuration no longer erases the Settle Code and API URL.** The form had no fields
  for them, so every save overwrote both settings with nothing. Both fields are now on the form.

### Added

- `upgrade()`, which encrypts any credential still held in cleartext. It is idempotent, and never
  throws — an instance with no encryption key keeps working on its existing cleartext password
  rather than dropping out of Koha's plugin list.
- `t/db_dependent/PayViaPayGov.t`, covering the migration, its idempotency, the cleartext fallback,
  and the fail-closed paths.
- CI now runs `prove` recursively with the plugin directory on the include path, so tests under
  `t/db_dependent/` are actually collected.

### Notes

- PayGov's integration requires the API password as a field in the browser-submitted payment form,
  so it still appears in the OPAC page source at payment time. That is the vendor's documented
  design, and encrypting the stored copy does not change it.
- Encryption needs an `encryption_key` in `koha-conf.xml`; Koha does not generate one. Without it
  the plugin behaves as before and the configuration page shows a warning.
- Encryption requires Koha 22.05 or newer. On older versions the plugin runs unchanged.
