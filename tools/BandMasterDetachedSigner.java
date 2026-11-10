/* Original environment only. No key generation/export, APK access or networking. */
import java.nio.file.*;
import java.security.*;
import java.security.cert.Certificate;
import java.util.Arrays;
import java.util.HexFormat;

class BandMasterDetachedSigner {
    static final String CERT = "83c797fe8db043b49ebdc705a3ca7a0326db19d0b9bf613c8cb1db1ea0c3cbf2";
    static void require(boolean ok, String message) {
        if (!ok) throw new IllegalArgumentException(message);
    }
    public static void main(String[] args) {
        try {
            require(args.length == 5, "Use detached_sign_request.py; requires original keystore/alias and public message/certificate/output");
            Path store = Path.of(args[0]), message = Path.of(args[2]);
            Path certificate = Path.of(args[3]), output = Path.of(args[4]);
            require(Files.size(certificate) < 16384 && Files.size(message) <= 16384,
                    "Unexpected public request size");
            byte[] expected = Files.readAllBytes(certificate), data = Files.readAllBytes(message);
            String digest = HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(expected));
            require(CERT.equals(digest), "Original public certificate pin differs");
            require(Files.isRegularFile(store), "Original keystore missing; do not create a replacement");
            require(!Files.exists(output), "Signature output already exists");
            String storeEnv = System.getenv("BM_STORE_PASSWORD"), keyEnv = System.getenv("BM_KEY_PASSWORD");
            require(storeEnv != null && !storeEnv.isEmpty() && keyEnv != null && !keyEnv.isEmpty(),
                    "Secure original-environment password bindings missing");
            char[] storePass = storeEnv.toCharArray(), keyPass = keyEnv.toCharArray();
            try {
                KeyStore ks = KeyStore.getInstance(store.toFile(), storePass);
                Certificate cert = ks.getCertificate(args[1]);
                require(cert != null && Arrays.equals(cert.getEncoded(), expected),
                        "Keystore alias is not the original Playtest certificate");
                require(ks.isKeyEntry(args[1]), "Original alias has no private-key entry");
                Key key = ks.getKey(args[1], keyPass);
                require(key instanceof PrivateKey && "RSA".equals(key.getAlgorithm()),
                        "Original RSA private key required");
                Signature signer = Signature.getInstance("SHA256withRSA");
                signer.initSign((PrivateKey)key); signer.update(data);
                byte[] signature = signer.sign();
                Signature verifier = Signature.getInstance("SHA256withRSA");
                verifier.initVerify(cert); verifier.update(data);
                require(verifier.verify(signature), "Original-key self-verification failed");
                Files.write(output, signature, StandardOpenOption.CREATE_NEW);
            } finally {
                Arrays.fill(storePass, '\0'); Arrays.fill(keyPass, '\0');
            }
        } catch (Exception error) {
            System.err.println("STOP: " + error.getClass().getSimpleName() + ": " + error.getMessage());
            System.exit(1);
        }
    }
}
