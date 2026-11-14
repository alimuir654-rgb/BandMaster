# Original Playtest signing and recovery

V26 detached signature is verified. APK assembly and official Android verification
remain with the build environment. No new APK key was generated or rotated.

## Public identity and storage

- Application ID: `com.bandmaster.ownerplaytest.s40`
- Save directory: `BandMasterOwnerPlaytestS40`
- Existing JKS alias: `androiddebugkey`
- Certificate SHA-256: `83c797fe8db043b49ebdc705a3ca7a0326db19d0b9bf613c8cb1db1ea0c3cbf2`
- Owner Dropbox encrypted backup: `/BandMasterSigningPrivate/BandMaster-original-signing-v1.bmk`
- Dropbox file ID: `id:6rRaLzqs6O4AAAAAAAABOQ`; size: 4380 bytes.
- Encrypted-file SHA-256: `bf41dd9aeae318dce8d7216d48905f4810a0b14edc25af6f6080f066bb30e272`
- Dropbox content hash: `2293937585dfdab0627082e790a05cfeff10fb067fbd583eb024a952eda54dd6`

The AES-256-GCM backup contains the original JKS bytes, both existing passwords,
alias and pinned certificate/app identity. A separate 32-byte backup recovery
secret is required; it is **not** a replacement Android signing key. No plaintext
key/password or recovery-secret value is in this repository or chat. No shared
link was created for the backup. The original keystore remains unchanged.

**Durable recovery is not yet complete.** The encrypted backup is in owner Dropbox,
but its recovery secret currently has temporary, owner-only custody at
`/tmp/bandmaster-sign26-private/recovery-key.bin` (0600, parent0700). It is not a
vault or a durable secret binding. Losing that file before secure import makes
this backup unusable. Do not delete the original key or this temporary secret.

**One owner setup action:** import that protected recovery-secret file into the
reusable BandMaster environment's secure secret-file storage and **Publish** the
configuration with `BM_SIGNING_RECOVERY_KEY_FILE` pointing to its mounted path.
Use the environment/secret-manager interface, never chat or Git. The current tools
cannot perform that vault import or publish a secret binding. Do not paste its
value into a message. Securely retain its vault recovery copy as part of that setup.

## Required reusable settings

| Setting | Binding / value |
| --- | --- |
| `BM_SIGNING_RECOVERY_KEY_FILE` | Secure file binding, exactly32 raw bytes, owner-only; proposed mount `/run/secrets/bandmaster-recovery-key.bin`. **Pending owner setup.** |
| `BM_SIGNING_BACKUP_FILE` | Local path to the authenticated encrypted Dropbox file, e.g. `/run/bandmaster/signing-backup.bmk`; ciphertext can be fetched through the owner's Dropbox connection. |
| Runtime | Python3, existing `cryptography`, Java17+ with source-file launch/JDK compiler module, and `keytool`. No Android SDK or APK is needed by the signer. |

Passwords are recovered from the authenticated encrypted payload and supplied only
to the existing Java child process. Direct signing also supports secure bindings
`BM_SIGNING_KEYSTORE_FILE`, `BM_STORE_PASSWORD`, `BM_KEY_PASSWORD` and optional
nonsecret `BM_SIGNING_ALIAS=androiddebugkey`; these are not currently configured.
There is no signing server, background task or fallback key generation.

## Sign a reviewed public request in any configured chat

Obtain the small request and an **independently approved** SHA-256. Never bless an
unknown request by computing its hash and treating that as approval. Future chats
need the published secure binding, not this chat or an APK transfer.

For this exact V26 request, from the repository root:

```sh
python3 tools/detached_sign_request.py check \
  --request docs/continuous_improvement/evidence/RESTORE66/BandMaster-V26-APK-v2-signing-request.json \
  --request-sha256 42fb4c51238778f681adb86fdff6cd6648b1062c56d4249fbe31faf62c9fcff0

python3 tools/detached_sign_request.py recover-sign \
  --request docs/continuous_improvement/evidence/RESTORE66/BandMaster-V26-APK-v2-signing-request.json \
  --request-sha256 42fb4c51238778f681adb86fdff6cd6648b1062c56d4249fbe31faf62c9fcff0 \
  --output /tmp/BandMaster-V26-signature-response.json
```

The recovery command uses the two file settings above, authenticates the backup
before staging secrets, checks the original certificate, then calls the existing
Java `SHA256withRSA` signer on the exact decoded message (PKCS#1v1.5, one SHA-256).
A new0700 directory holds a0600 temporary JKS and is removed on exit/failure.
Python/environment strings are not claimed to be cryptographically zeroised.
Outputs use exclusive creation; do not overwrite or reuse another build's response.
Return only the public signature JSON. The signed APK still does not exist here.

## What was actually tested

- Actual original certificate exported and matched to the pin above.
- Local encrypted-backup recovery matched the original JKS bytes and both passwords.
- Owner Dropbox readback: stored object size/content hash matched. Text extraction
  added a newline (4381 vs4380 bytes), so its raw-SHA comparison is retained as held;
  decoded envelope/ciphertext matched, AES-GCM authentication passed, recovered JKS
  bytes matched, and the recovered certificate matched. No raw-download byte-equality claim.
- **V26 was signed using the recovered Dropbox envelope**, not the original path;
  Java self-verification, Python verification and independent public RSA verification passed.
- 17 existing public signer tests and10 backup tests passed. Backup tests use mock
  QA bytes; they are separate from the actual original-key recovery/signing proof.
- Recovery in another environment using a published durable secret binding has
  **not** been tested. Do that after owner setup; until then signing is not fully chat-independent.

V26 request ID: `f68e8d992998a6c5b685ad48cb8ee16d34148ae0995174fc225348d1e8249f1b`.
Message:884bytes / SHA-256 `db0cc73e146d030f677fd40c9a90017f13b64fb389e2ba7149c2b61e097a5aee`.
[Public response](BandMaster-V26-signature-response.json):256-byte RSA signature;
response-file SHA-256 `6e2d6f1f55fe8f62aab0b52ec0acedc28330882e01b10e0cf6ebc4b756c1b4dd`.

## Final APK assembly — only where the exact unsigned APK is retained

Set the following nonsecret local paths to the audited V26 policy, unchanged APK,
existing Android build-tools directory and new output. The unsigned APK must be
372861236bytes / SHA-256 `3ba53963494717c1cce448e6a630dc519125df4719fc49acf46f6a94d9e9b39c`.

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

Require the original certificate, app/version26, unchanged payload/resource audits
and private delivery before calling the update installable. Physical install,
save retention and listening remain untested. Install as an update; never uninstall
or clear app data. This signer operation did not assemble or officially audit an APK.

To undo only the Dropbox backup creation, remove the named encrypted file/folder
in Dropbox; that does not remove the original keystore. Do not remove the only
recovery secret before durable secure import is verified.
