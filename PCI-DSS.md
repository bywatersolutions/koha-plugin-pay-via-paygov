# PCI DSS scoping statement — Pay Via PayGov

This document describes what data the **Pay Via PayGov** Koha plugin sends to PayGov, what PayGov
sends back, and what Koha retains.

It is a factual description of the plugin's behaviour at the commit named in section 8 (the v2.1.0
release). It is not a certification, and it does not determine any library's PCI DSS obligations —
a library that accepts card payments is a merchant and has obligations regardless of what Koha
does. What this document establishes is whether Koha itself sits inside the cardholder data
environment.

---

## 1. Summary

| Assertion | Determination |
|---|---|
| Does this plugin **accept** cardholder data (PAN, CVV/CVC/CID, expiry date, track or chip data, PIN)? | **No** |
| Does this plugin **transmit** cardholder data to any system? | **No** |
| Does this plugin **store** cardholder data? | **No** |
| Does this plugin store any **card-derived** data (card brand, truncated PAN, authorisation code)? | **No** |
| Does the patron ever enter card details into a page served by Koha? | **No** |
| Does any Koha-served page frame, embed, script, or otherwise affect the processor's card-entry page? | **No** |

**Determination: Koha is outside the cardholder data environment.**

A patron who chooses to pay library fees online leaves the Koha catalogue entirely and is sent to a
payment page hosted and operated by PayGov. Card details are typed into that page, travel to
PayGov, and never reach Koha or ByWater Solutions' servers. When the payment completes, PayGov
returns the patron to Koha with the result, and Koha marks the selected fees as paid.

### One term that looks like card data and is not

**Koha's `cardnumber` is a library card barcode, not a payment card number.** This plugin sends
it to PayGov as the [`F-5495` form field](https://github.com/bywatersolutions/koha-plugin-pay-via-paygov/blob/f70ed61f6f6188cd02ba7fc5192b6e77d2358db5/Koha/Plugin/Com/ByWaterSolutions/PayViaPayGov/opac_online_payment_begin.tt#L89) — it is the number printed on the plastic
library card, used by PayGov as a customer reference. It is not a PAN and not cardholder data.

---

## 2. How a payment works

1. The patron selects fees in the OPAC. [`opac_online_payment_begin`](https://github.com/bywatersolutions/koha-plugin-pay-via-paygov/blob/f70ed61f6f6188cd02ba7fc5192b6e77d2358db5/Koha/Plugin/Com/ByWaterSolutions/PayViaPayGov.pm#L65) records a
   [one-time token](https://github.com/bywatersolutions/koha-plugin-pay-via-paygov/blob/f70ed61f6f6188cd02ba7fc5192b6e77d2358db5/Koha/Plugin/Com/ByWaterSolutions/PayViaPayGov.pm#L87) and renders a form.
2. **Patron's browser** [POSTs that form directly to the configured PayGov URL](https://github.com/bywatersolutions/koha-plugin-pay-via-paygov/blob/f70ed61f6f6188cd02ba7fc5192b6e77d2358db5/Koha/Plugin/Com/ByWaterSolutions/PayViaPayGov/opac_online_payment_begin.tt#L85), and the
   patron enters card details on PayGov's page. Koha is not involved and receives nothing from
   that step.
3. **PayGov** returns the patron to `opac-account-pay-return.pl`
   ([`SuccessURL`](https://github.com/bywatersolutions/koha-plugin-pay-via-paygov/blob/f70ed61f6f6188cd02ba7fc5192b6e77d2358db5/Koha/Plugin/Com/ByWaterSolutions/PayViaPayGov/opac_online_payment_begin.tt#L95)), which runs [`opac_online_payment_end`](https://github.com/bywatersolutions/koha-plugin-pay-via-paygov/blob/f70ed61f6f6188cd02ba7fc5192b6e77d2358db5/Koha/Plugin/Com/ByWaterSolutions/PayViaPayGov.pm#L112): the token is
   validated and the payment [credited](https://github.com/bywatersolutions/koha-plugin-pay-via-paygov/blob/f70ed61f6f6188cd02ba7fc5192b6e77d2358db5/Koha/Plugin/Com/ByWaterSolutions/PayViaPayGov.pm#L167).

There is no server-to-server leg. The plugin has no API routes, and its stored `PayGovApiUrl` is
never used to make a request.

## 3. Data sent to the payment processor

All fields are in the [browser-submitted form](https://github.com/bywatersolutions/koha-plugin-pay-via-paygov/blob/f70ed61f6f6188cd02ba7fc5192b6e77d2358db5/Koha/Plugin/Com/ByWaterSolutions/PayViaPayGov/opac_online_payment_begin.tt#L85):

| Field | Contents | Code |
|---|---|---|
| `Address1` / `City` / `State` / `ZipCode` | patron address | [`:86`](https://github.com/bywatersolutions/koha-plugin-pay-via-paygov/blob/f70ed61f6f6188cd02ba7fc5192b6e77d2358db5/Koha/Plugin/Com/ByWaterSolutions/PayViaPayGov/opac_online_payment_begin.tt#L86), [`:87`](https://github.com/bywatersolutions/koha-plugin-pay-via-paygov/blob/f70ed61f6f6188cd02ba7fc5192b6e77d2358db5/Koha/Plugin/Com/ByWaterSolutions/PayViaPayGov/opac_online_payment_begin.tt#L87), [`:94`](https://github.com/bywatersolutions/koha-plugin-pay-via-paygov/blob/f70ed61f6f6188cd02ba7fc5192b6e77d2358db5/Koha/Plugin/Com/ByWaterSolutions/PayViaPayGov/opac_online_payment_begin.tt#L94), [`:97`](https://github.com/bywatersolutions/koha-plugin-pay-via-paygov/blob/f70ed61f6f6188cd02ba7fc5192b6e77d2358db5/Koha/Plugin/Com/ByWaterSolutions/PayViaPayGov/opac_online_payment_begin.tt#L97) |
| `F-5494` | patron "surname, firstname" | [`:88`](https://github.com/bywatersolutions/koha-plugin-pay-via-paygov/blob/f70ed61f6f6188cd02ba7fc5192b6e77d2358db5/Koha/Plugin/Com/ByWaterSolutions/PayViaPayGov/opac_online_payment_begin.tt#L88) |
| `F-5495` | patron **library card barcode** (see above) | [`:89`](https://github.com/bywatersolutions/koha-plugin-pay-via-paygov/blob/f70ed61f6f6188cd02ba7fc5192b6e77d2358db5/Koha/Plugin/Com/ByWaterSolutions/PayViaPayGov/opac_online_payment_begin.tt#L89) |
| `FirstName` / `LastName` / `Phone` / `email` | patron identity | [`:90-92`](https://github.com/bywatersolutions/koha-plugin-pay-via-paygov/blob/f70ed61f6f6188cd02ba7fc5192b6e77d2358db5/Koha/Plugin/Com/ByWaterSolutions/PayViaPayGov/opac_online_payment_begin.tt#L90-L92), [`:98`](https://github.com/bywatersolutions/koha-plugin-pay-via-paygov/blob/f70ed61f6f6188cd02ba7fc5192b6e77d2358db5/Koha/Plugin/Com/ByWaterSolutions/PayViaPayGov/opac_online_payment_begin.tt#L98) |
| `SettleCode` / `Ttid` | merchant configuration | [`:93`](https://github.com/bywatersolutions/koha-plugin-pay-via-paygov/blob/f70ed61f6f6188cd02ba7fc5192b6e77d2358db5/Koha/Plugin/Com/ByWaterSolutions/PayViaPayGov/opac_online_payment_begin.tt#L93), [`:96`](https://github.com/bywatersolutions/koha-plugin-pay-via-paygov/blob/f70ed61f6f6188cd02ba7fc5192b6e77d2358db5/Koha/Plugin/Com/ByWaterSolutions/PayViaPayGov/opac_online_payment_begin.tt#L96) |
| `SuccessURL` | the return URL | [`:95`](https://github.com/bywatersolutions/koha-plugin-pay-via-paygov/blob/f70ed61f6f6188cd02ba7fc5192b6e77d2358db5/Koha/Plugin/Com/ByWaterSolutions/PayViaPayGov/opac_online_payment_begin.tt#L95) |
| `user_id` | borrowernumber | [`:99`](https://github.com/bywatersolutions/koha-plugin-pay-via-paygov/blob/f70ed61f6f6188cd02ba7fc5192b6e77d2358db5/Koha/Plugin/Com/ByWaterSolutions/PayViaPayGov/opac_online_payment_begin.tt#L99) |
| `ApiPassword` | **the PayGov API password** — see §7 | [`:101`](https://github.com/bywatersolutions/koha-plugin-pay-via-paygov/blob/f70ed61f6f6188cd02ba7fc5192b6e77d2358db5/Koha/Plugin/Com/ByWaterSolutions/PayViaPayGov/opac_online_payment_begin.tt#L101) |
| `OrderToken` | JSON of token, borrowernumber, accountline ids | [`:110`](https://github.com/bywatersolutions/koha-plugin-pay-via-paygov/blob/f70ed61f6f6188cd02ba7fc5192b6e77d2358db5/Koha/Plugin/Com/ByWaterSolutions/PayViaPayGov/opac_online_payment_begin.tt#L110) |
| `paymentAmount` | summed amount | [`:116`](https://github.com/bywatersolutions/koha-plugin-pay-via-paygov/blob/f70ed61f6f6188cd02ba7fc5192b6e77d2358db5/Koha/Plugin/Com/ByWaterSolutions/PayViaPayGov/opac_online_payment_begin.tt#L116) |

**Cardholder data in this table: none.** No PAN, CVV, expiry, track or PIN field is constructed
anywhere in this plugin. No itemised fee descriptions are transmitted.

## 4. Data received from the payment processor

**Transport:** the patron's return request to the OPAC; parameters read from
[`$cgi->Vars`](https://github.com/bywatersolutions/koha-plugin-pay-via-paygov/blob/f70ed61f6f6188cd02ba7fc5192b6e77d2358db5/Koha/Plugin/Com/ByWaterSolutions/PayViaPayGov.pm#L125).
**Authentication of this channel:** the patron's authenticated OPAC session, plus the one-time
token round-tripped inside `OrderToken`.

| Field | Read | Persisted? |
|---|---|---|
| [`Amount`](https://github.com/bywatersolutions/koha-plugin-pay-via-paygov/blob/f70ed61f6f6188cd02ba7fc5192b6e77d2358db5/Koha/Plugin/Com/ByWaterSolutions/PayViaPayGov.pm#L125) | yes — becomes the credited amount | `accountlines.amount` |
| [`authcode`](https://github.com/bywatersolutions/koha-plugin-pay-via-paygov/blob/f70ed61f6f6188cd02ba7fc5192b6e77d2358db5/Koha/Plugin/Com/ByWaterSolutions/PayViaPayGov.pm#L128) | yes — string-compared to `SUCCESS` | no |
| [`OrderId`](https://github.com/bywatersolutions/koha-plugin-pay-via-paygov/blob/f70ed61f6f6188cd02ba7fc5192b6e77d2358db5/Koha/Plugin/Com/ByWaterSolutions/PayViaPayGov.pm#L129) | yes | **hashed** — `sha256` of it goes into the note ([`:145`](https://github.com/bywatersolutions/koha-plugin-pay-via-paygov/blob/f70ed61f6f6188cd02ba7fc5192b6e77d2358db5/Koha/Plugin/Com/ByWaterSolutions/PayViaPayGov.pm#L145)) |
| [`TransId`](https://github.com/bywatersolutions/koha-plugin-pay-via-paygov/blob/f70ed61f6f6188cd02ba7fc5192b6e77d2358db5/Koha/Plugin/Com/ByWaterSolutions/PayViaPayGov.pm#L130) | yes — displayed on error only | no |
| [`OrderToken`](https://github.com/bywatersolutions/koha-plugin-pay-via-paygov/blob/f70ed61f6f6188cd02ba7fc5192b6e77d2358db5/Koha/Plugin/Com/ByWaterSolutions/PayViaPayGov.pm#L132) | yes — token, borrowernumber, accountlines | token row deleted on success |

**Cardholder data in this channel: none** — no masked PAN, brand, expiry, or card token appears in
what PayGov returns or in what the plugin reads.

## 5. What Koha stores, and for how long

| Store | Contents | Retention |
|---|---|---|
| [`paygov_plugin_tokens`](https://github.com/bywatersolutions/koha-plugin-pay-via-paygov/blob/f70ed61f6f6188cd02ba7fc5192b6e77d2358db5/Koha/Plugin/Com/ByWaterSolutions/PayViaPayGov.pm#L409) | one-time token, created_on, borrowernumber | Deleted on success. As of v2.2.0, a nightly job removes tokens older than seven days, and `install()`/`upgrade()` actually create the table — see §7. |
| `accountlines` | amount; note `PayGov (<sha256 of OrderId>)` ([`:145`](https://github.com/bywatersolutions/koha-plugin-pay-via-paygov/blob/f70ed61f6f6188cd02ba7fc5192b6e77d2358db5/Koha/Plugin/Com/ByWaterSolutions/PayViaPayGov.pm#L145), [`:170`](https://github.com/bywatersolutions/koha-plugin-pay-via-paygov/blob/f70ed61f6f6188cd02ba7fc5192b6e77d2358db5/Koha/Plugin/Com/ByWaterSolutions/PayViaPayGov.pm#L170)) | Per the library's Koha retention settings |
| `plugin_data` | configuration; the API password **encrypted** (AES-256-CBC via `Koha::Encryption`, [`koha-enc-v1:` prefix](https://github.com/bywatersolutions/koha-plugin-pay-via-paygov/blob/f70ed61f6f6188cd02ba7fc5192b6e77d2358db5/Koha/Plugin/Com/ByWaterSolutions/PayViaPayGov.pm#L39), since v2.1.0) | Until changed |

**Logs: this plugin writes nothing to the log** — no `warn`, no logger, in any payment path.

**Credentials:** the API password is encrypted by [`_set_secret`](https://github.com/bywatersolutions/koha-plugin-pay-via-paygov/blob/f70ed61f6f6188cd02ba7fc5192b6e77d2358db5/Koha/Plugin/Com/ByWaterSolutions/PayViaPayGov.pm#L343) and decrypted by
[`_get_secret`](https://github.com/bywatersolutions/koha-plugin-pay-via-paygov/blob/f70ed61f6f6188cd02ba7fc5192b6e77d2358db5/Koha/Plugin/Com/ByWaterSolutions/PayViaPayGov.pm#L305); cleartext values from earlier versions are
[migrated on upgrade](https://github.com/bywatersolutions/koha-plugin-pay-via-paygov/blob/f70ed61f6f6188cd02ba7fc5192b6e77d2358db5/Koha/Plugin/Com/ByWaterSolutions/PayViaPayGov.pm#L370). Where no `encryption_key` exists in `koha-conf.xml` the plugin
keeps working on the cleartext value and says so on the configuration page. The configuration form
posts with a CSRF token and never renders the stored password.

## 6. Patron personal data (outside PCI scope)

Name, address, phone, email, library barcode and borrowernumber go to PayGov in the payment form.
Fee descriptions do **not** — only the summed amount. Once transmitted, PayGov's handling is
governed by their privacy policy and the library's agreement with them.

## 7. Known limitations

| Item | Bearing on this document | Status |
|---|---|---|
| **The API password appears in the OPAC page source at payment time** ([`:101`](https://github.com/bywatersolutions/koha-plugin-pay-via-paygov/blob/f70ed61f6f6188cd02ba7fc5192b6e77d2358db5/Koha/Plugin/Com/ByWaterSolutions/PayViaPayGov/opac_online_payment_begin.tt#L101)) — any patron can read it from the payment form. PayGov's POST API documentation requires `apipassword` as a browser-form field, so this is the vendor's documented integration, not a plugin defect. Encrypting the stored copy (v2.1.0) does not change it. | Credential exposure, not cardholder data. | Open — constrained by the vendor's design; PayGov's undocumented "secure post" variant is the potential path out |
| [`install()`](https://github.com/bywatersolutions/koha-plugin-pay-via-paygov/blob/f70ed61f6f6188cd02ba7fc5192b6e77d2358db5/Koha/Plugin/Com/ByWaterSolutions/PayViaPayGov.pm#L405) builds the `CREATE TABLE` for `paygov_plugin_tokens` and **never executes it** — the token INSERT dies unless the table was created by hand. | Whether payments work at all on a fresh install; no card data involved. | **Remediated in v2.2.0** — `install()` executes the statement and `upgrade()` creates the table for existing installs |
| The return leg trusts the browser-supplied [`Amount`](https://github.com/bywatersolutions/koha-plugin-pay-via-paygov/blob/f70ed61f6f6188cd02ba7fc5192b6e77d2358db5/Koha/Plugin/Com/ByWaterSolutions/PayViaPayGov.pm#L125) and [`authcode`](https://github.com/bywatersolutions/koha-plugin-pay-via-paygov/blob/f70ed61f6f6188cd02ba7fc5192b6e77d2358db5/Koha/Plugin/Com/ByWaterSolutions/PayViaPayGov.pm#L128); there is no signature and no server-to-server verification. | Payment-record integrity, not card data. | Open |
| If PayGov delivers the return as a POST, Koha's CSRF middleware rejects it before this plugin runs ([Koha bug 41197](https://bugs.koha-community.org/bugzilla3/show_bug.cgi?id=41197), Passed QA). Whether PayGov uses GET or POST for `SuccessURL` is not determinable from this code. | Whether the return leg works; no card data involved. | Open question |
| The API password was stored in cleartext in `plugin_data`. | Credential exposure. | **Remediated in v2.1.0** — encrypted at rest, migrated on upgrade |
| The configuration form submitted by GET and rendered the stored password into the page; saving also erased the Settle Code and API URL, whose fields were missing. | Credential exposure / configuration integrity. | **Remediated in v2.1.0** |

## 8. What was reviewed

Reviewed at commit [`f70ed61f6f6188cd02ba7fc5192b6e77d2358db5`](https://github.com/bywatersolutions/koha-plugin-pay-via-paygov/commit/f70ed61f6f6188cd02ba7fc5192b6e77d2358db5) (the v2.1.0 release) on 2026-08-19:
[`PayViaPayGov.pm`](https://github.com/bywatersolutions/koha-plugin-pay-via-paygov/blob/f70ed61f6f6188cd02ba7fc5192b6e77d2358db5/Koha/Plugin/Com/ByWaterSolutions/PayViaPayGov.pm), [`opac_online_payment_begin.tt`](https://github.com/bywatersolutions/koha-plugin-pay-via-paygov/blob/f70ed61f6f6188cd02ba7fc5192b6e77d2358db5/Koha/Plugin/Com/ByWaterSolutions/PayViaPayGov/opac_online_payment_begin.tt), the end template, and the
configuration template.

| Date | Version | Commit | Reviewer | Change |
|---|---|---|---|---|
| 2026-08-19 | v2.1.0 | `f70ed61` | Kyle M Hall | Initial review |
