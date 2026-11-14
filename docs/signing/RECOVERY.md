# Original Playtest signing — phone-friendly recovery

**No phone download or secret-file import is required.** ESCROW68 verified recovery
using both owner-connected cloud stores in fresh isolated staging. The original
Android signing key was not changed. V26's public signature remains unchanged;
APK assembly and official verification are separate.

## Identity and separate storage

| Item | Verified reference |
| --- | --- |
| App / saves | `com.bandmaster.ownerplaytest.s40` / `BandMasterOwnerPlaytestS40` |
| Original JKS alias | `androiddebugkey` |
| Certificate SHA-256 | `83c797fe8db043b49ebdc705a3ca7a0326db19d0b9bf613c8cb1db1ea0c3cbf2` |
| Encrypted JKS + both passwords | Owner Dropbox `/BandMasterSigningPrivate/BandMaster-original-signing-v1.bmk`, file `id:6rRaLzqs6O4AAAAAAAABOQ`,4380 bytes |
| Backup SHA-256 | `bf41dd9aeae318dce8d7216d48905f4810a0b14edc25af6f6080f066bb30e272` |
| Dropbox content hash | `2293937585dfdab0627082e790a05cfeff10fb067fbd583eb024a952eda54dd6` |
| Separate recovery secret | Google My Drive, `BandMaster-signing-recovery-v1.bin`, file ID `1WvAR59rHtvlZAB54Oh62suVL9fcyPTQv`,32 raw bytes |
| Verified Drive access | `shared=false`, personal My Drive; exactly one permission: owner `chair@lovewelluk.com`. No other reader, group, domain or anyone grant. |

This is **private file escrow, not a managed secret vault**. The Drive file contains
the backup-encryption secret in plaintext, protected by Google/account permissions;
the Dropbox file is AES-256-GCM encrypted. A chat authorised to both connections can
recover the signer. Compromise of both accounts exposes the backup. No public
sharing permission was added. The original JKS and existing passwords are unchanged.

Do not store the secret in Git, messages, inline base64, command arguments or logs.
Only nonsecret file IDs, hashes and access metadata belong in this runbook.

## Future-chat procedure

Requires both owner Dropbox and Google Drive connections, Python3 with the existing
`cryptography` package, Java17+ source-file launch/JDK compiler module, and `keytool`.
No APK transfer, signing service or original chat filesystem is required.

1. Fetch the public helpers/fixtures and a small owner-approved request from
   `feature/playtest-polish-v20`. Require an independently approved request SHA-256.
2. Read Drive metadata for the exact ID above BEFORE fetching. Require personal
   My Drive, binary MIME,32 bytes, `shared=false`, and owner-only permissions above.
   Refuse additional users/groups/domains/anyone, a shortcut or Shared Drive.
3. Use Google Drive `fetch(download_raw_file=True, include_base64=False)` and the
   authenticated `file_uri`/`download_file` flow. **Do not print the result:** it
   contains temporary bearer URLs. Immediately protect materialized files and move
   only the new secret copy into a0700 temporary directory with0600 permissions.
4. Fetch the encrypted Dropbox file through its authenticated connector. Verify
   provider size/content hash when available. Text extraction may add a newline:
   retain any raw-SHA mismatch; accept only authenticated AEAD recovery, never claim
   raw byte equality from extracted text. Do not place the backup itself in Git.
5. Set these nonsecret path variables to the two protected staged files:
   `BM_SIGNING_BACKUP_FILE` and `BM_SIGNING_RECOVERY_KEY_FILE`. These are per-process
   paths, not a claim that managed environment secret bindings were configured.
6. Run the commands below; return only the public response. Remove only the new
   temporary recovered JKS stage. The helper does that on success/failure. Do not
   delete cloud recovery copies or the original keystore.

For this exact V26 request:

```sh
python3 tools/detached_sign_request.py check \
  --request docs/continuous_improvement/evidence/RESTORE66/BandMaster-V26-APK-v2-signing-request.json \
  --request-sha256 42fb4c51238778f681adb86fdff6cd6648b1062c56d4249fbe31faf62c9fcff0

python3 tools/detached_sign_request.py recover-sign \
  --request docs/continuous_improvement/evidence/RESTORE66/BandMaster-V26-APK-v2-signing-request.json \
  --request-sha256 42fb4c51238778f681adb86fdff6cd6648b1062c56d4249fbe31faf62c9fcff0 \
  --output /tmp/BandMaster-V26-signature-response.json
```

The helper authenticates before staging private material, checks the original
certificate, and signs exact decoded bytes with `SHA256withRSA`/PKCS#1v1.5 (one
SHA-256). No replacement key is generated. Private stages are0700/0600; process
memory/immutable strings are not claimed to be cryptographically zeroised.

## Actual proof and limits

- Both remote files were retrieved; Drive's32 bytes privately matched the original.
- Fresh isolated staging used downloaded inputs and newly fetched public helpers,
  without original chat JKS/password/recovery files. Its V26 response matched the
  original public response byte-for-byte; Java and Python verified the signature.
- This is **same-host remote-backed recovery**, not a tested new machine/new chat.
  Managed vault bindings remain optional and unconfigured.
- Previous17 signer +10 backup tests remain applicable;10 simulated unsafe ACL
  cases were refused. No live permissions were changed for negative testing.
- One initial tool result displayed a short-lived transfer URL, advertised expiry
  13:48:18UTC14November2026; no raw secret bytes were printed or Drive sharing
  grant changed. Expiry does not prove the URL was never accessed or copied; no such absence claim is made. Future orchestration must withhold transfer metadata entirely.

[Public response](BandMaster-V26-signature-response.json) SHA-256:
`6e2d6f1f55fe8f62aab0b52ec0acedc28330882e01b10e0cf6ebc4b756c1b4dd`.

## Final assembly — environment retaining the unchanged APK

Unsigned V26:372861236 bytes / SHA-256
`3ba53963494717c1cce448e6a630dc519125df4719fc49acf46f6a94d9e9b39c`.
Set these nonsecret local paths to the audited V26 policy, APK, build-tools and output:

```sh
python3 tools/detached_apk_v2.py assemble \
  --policy "$V26_POLICY" \
  --request docs/continuous_improvement/evidence/RESTORE66/BandMaster-V26-APK-v2-signing-request.json \
  --response docs/signing/BandMaster-V26-signature-response.json \
  --apk "$V26_UNSIGNED_APK" --public-reference \
  --sdk "$ANDROID_BUILD_TOOLS" --output "$V26_SIGNED_APK"
"$ANDROID_BUILD_TOOLS/apksigner" verify --verbose --print-certs "$V26_SIGNED_APK"
"$ANDROID_BUILD_TOOLS/zipalign" -c -P 16 -v 4 "$V26_SIGNED_APK"
```

Require original certificate/app/version26 and unchanged payload/resource checks.
No APK was assembled here. Physical install/save retention/listening remain
unverified. Install an update; never uninstall or clear app data.

To revoke future retrieval, remove its Drive file only after securing another
verified recovery copy. Removal cannot revoke previously retrieved copies; removing
the only durable secret makes the backup unusable.
