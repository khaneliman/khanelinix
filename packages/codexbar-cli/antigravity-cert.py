import hashlib
import re
import ssl
import subprocess
import sys
from pathlib import Path


def localhost_fingerprint(binary, openssl):
    fingerprints = set()
    for pem in re.findall(
        rb"-----BEGIN CERTIFICATE-----\s+[A-Za-z0-9+/=\r\n]+-----END CERTIFICATE-----",
        Path(binary).read_bytes(),
    ):
        result = subprocess.run(
            [openssl, "x509", "-noout", "-checkip", "127.0.0.1"],
            input=pem,
            capture_output=True,
            check=False,
        )
        if result.returncode == 0:
            fingerprints.add(
                hashlib.sha256(ssl.PEM_cert_to_DER_cert(pem.decode())).digest()
            )
    if len(fingerprints) != 1:
        raise ValueError(
            "expected exactly one bundled Antigravity loopback certificate"
        )
    return fingerprints.pop()


if __name__ == "__main__":
    fingerprint = localhost_fingerprint(*sys.argv[1:])
    print("static const unsigned char antigravity_fingerprint[32] = {")
    print(", ".join(f"0x{byte:02x}" for byte in fingerprint))
    print("};")
