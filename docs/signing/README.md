# Original-key detached APK signing

This workflow removes the need to transfer the large unsigned APK or private key
to the other environment. **It does not give a new chat access to the original key.**
No original signing key is configured in the current cloud environment. Actual
signing must run in the original build environment, as instructed by the owner.
If that environment/key is unavailable, report that blocker; do not generate a key,
change the application ID, export the key or call an unsigned APK installable.

The helpers use Python 3 with the existing `cryptography` dependency and Java 17+
(JDK source-file launch). No new game/runtime dependency or background service.
`tools/detached_apk_v2.py` already prepares/assembles APK-v2 blocks and requires
official Android `apksigner`, `zipalign`, app/version and unchanged-payload checks.

## Frozen V23 public handoff

`BandMaster-V23-APK-v2-signing-request.json` is an **exact 9,080-byte copy** of the
existing request, also at Dropbox `/BandMaster/BandMaster-V23-APK-v2-signing-request.json`.
It contains only public certificate/signed data and package-audit metadata, no private key or music.
`v23-policy.json` is the existing public APK/source policy. **Do not edit either.**

| Binding | Exact value |
| --- | --- |
| Request file SHA-256 | `7ebd68fbbc5baaac8aa50afcb3fc884733a686394de36f96df04ccab95be6741` |
| Request ID | `93f51ed3b0d1cd0df531c10b2ffc00bb556a75147f452f9a54b87abafebf3c8b` |
| Signed-data SHA-256 | `f866f500cc0f38abda3454b34f6fe73f19309e0eca4a04dabcf430342f0ead49` |
| Original certificate SHA-256 | `83c797fe8db043b49ebdc705a3ca7a0326db19d0b9bf613c8cb1db1ea0c3cbf2` |
| Unsigned APK SHA-256 | `d7e882153afbf47632d230aa3c6a750905b6866d0c9581d1aeeae5d5f6d08aca` |
| Unsigned APK bytes | `438298804` |
| Packaged game source | `dba007e3022d9d1a39365aab78b127d6a1d79f84` |
| Version | `23` / `0.153.0-playtest-bandnight` |
| App / minimum SDK | `com.bandmaster.ownerplaytest.s40` / `24` |

No V23 signature has been returned. Owner deferred that review for more audio.
The newer crowd source is **not** in V23. Do not reuse this request for a future build;
make a new audited request and version greater than 23 after the batch is ready.

## Public validation — any environment, no private key

From the repository root:

```sh
python3 tools/detached_sign_request.py check \
  --request docs/signing/BandMaster-V23-APK-v2-signing-request.json \
  --request-sha256 7ebd68fbbc5baaac8aa50afcb3fc884733a686394de36f96df04ccab95be6741
```

The checker enforces the separately reviewed exact file hash, canonical request ID,
app/source/SDK fields, original certificate/SPKI, RSA/SHA-256/PKCS#1 v1.5 algorithm,
exact reconstructed signed-data bytes and clear retained package-audit flags.
**It cannot independently audit an APK that is not present.** Review the package/source
audit before signing. Never calculate a hash from an unknown request and blindly approve it.

## Produce the small signature — original environment only

Once the owner wants the **specific audited package** signed, the original signing
environment checks out this branch and runs the same public check. It supplies its
existing keystore path/alias and `BM_STORE_PASSWORD` / `BM_KEY_PASSWORD` through its
secure environment settings. Do not put passwords or keystore contents in chat/Git.
For frozen V23 only, the command is:

```sh
python3 tools/detached_sign_request.py sign \
  --request docs/signing/BandMaster-V23-APK-v2-signing-request.json \
  --request-sha256 7ebd68fbbc5baaac8aa50afcb3fc884733a686394de36f96df04ccab95be6741 \
  --keystore /original/environment/existing-playtest.jks \
  --alias ORIGINAL_EXISTING_ALIAS \
  --output /tmp/BandMaster-V23-signature-response.json
```

The keystore path and alias above are placeholders, not known locations. The original
environment locates its own existing key; the cloud chat must not request its transfer.
Python validates public data, then Java loads that existing keystore locally, checks
its exact public certificate **before retrieving the key**, and signs only the decoded
signed-data bytes with `SHA256withRSA`. Both Java and Python verify the signature.
There is no key generation/export, no APK access and no network call in this helper.
Return only the small response JSON. Outputs are exclusive-create, never overwritten.

Do not sign the JSON, digest text, content digest, or a length-prefixed message.
Do not pre-hash and then call `SHA256withRSA` (double hashing). The helper does the
correct single hash internally. Response fields are request ID, signed-data hash,
original certificate hash and base64 signature, plus schema version.

## Assemble and verify — environment retaining the exact unsigned APK

The following **only** assembles the frozen V23 payload after its matching response arrives:

```sh
python3 tools/detached_apk_v2.py assemble \
  --policy docs/signing/v23-policy.json \
  --request docs/signing/BandMaster-V23-APK-v2-signing-request.json \
  --response /path/to/BandMaster-V23-signature-response.json \
  --apk /workspace/bandmaster-next32/BandMaster-Playtest-v23-UNSIGNED.apk \
  --v16 /workspace/main-app-check/BandMaster-Playtest-v16-arm64.apk \
  --sdk /workspace/tools/android-sdk/build-tools/35.0.0 \
  --output /workspace/bandmaster-next32/BandMaster-Playtest-v23-arm64.apk
```

Paths may need adjustment in a new executor, **never the pinned bytes**. Assembly
revalidates the request against the actual APK and original V16 public certificate,
verifies the detached signature, constructs the block, then requires official
`apksigner verify --verbose --print-certs`, original certificate, app/version/minSDK,
16 KiB alignment and byte-identical ZIP payload. A failed check leaves a held candidate,
not a promoted APK. Stop and investigate; never bypass a failed gate or rebuild under
the same old request. Physical update/save/audio testing remains a separate step.

For later builds, `detached_apk_v2.py prepare/assemble` require an explicitly audited
`--policy`; its unconfigured defaults are historical V17. Preparation must bind the
actual new source/branch, APK, audits and compiled verification; inspect those fields
and publish a new public request/hash before the original environment signs it.
Neither an old V22 signature nor the frozen V23 request authorizes newer source.

## Repeatable public tests

```sh
python3 tests/detached_sign_request_test.py
```

This uses a **real previously returned original-key V22 signature** as a public
known-answer fixture, rejects tampering/cross-build reuse and compiles/runs the Java
missing-key refusal path. Fixtures are public request/signature data, not keys.
Positive signing with the original keystore has **not** been run here.

Where retained APKs and SDK tools exist:

```sh
python3 tests/detached_apk_v2_test.py \
  --policy docs/signing/v23-policy.json \
  --request docs/signing/BandMaster-V23-APK-v2-signing-request.json \
  --apk /workspace/bandmaster-next32/BandMaster-Playtest-v23-UNSIGNED.apk \
  --v16 /workspace/main-app-check/BandMaster-Playtest-v16-arm64.apk \
  --sdk /workspace/tools/android-sdk/build-tools/35.0.0
```

Both suites run without generating keys or producing an APK. The existing detached
assembler has previously completed real V17–V22 original-key handoffs. This handover
adds a reusable original-environment signer and portable, exact public V23 inputs;
it does not claim an actual V23 signature or successful new private-key operation.
