import http.server
import importlib.util
import re
import ssl
import subprocess
import sys
import tempfile
import threading
from pathlib import Path


class Handler(http.server.BaseHTTPRequestHandler):
    def log_message(self, *_args):
        pass

    def do_GET(self):
        self.respond()

    def do_POST(self):
        self.respond()

    def respond(self):
        expected = self.rfile.read(int(self.headers.get("Content-Length", 0))).decode()
        token = self.headers.get("X-Codeium-Csrf-Token")
        if token and (
            not self.headers.get("Host", "").startswith("127.0.0.1:")
            or not self.path.startswith(
                "/exa.language_server_pb.LanguageServerService/"
            )
        ):
            self.send_response(400)
            body = b"wrong-origin"
        elif self.path == "/redirect-to-api":
            self.send_response(302)
            self.send_header(
                "Location",
                f"https://127.0.0.1:{self.server.server_port}/exa.language_server_pb.LanguageServerService/GetUserStatus",
            )
            body = b"redirect"
        elif self.path.endswith(("/Redirect", "/redirect")):
            self.send_response(302)
            self.send_header(
                "Location", f"https://localhost:{self.server.server_port}/other"
            )
            body = b"redirect"
        elif (
            self.path.endswith("/PreservedHeaders")
            and self.headers.get("X-Fixture") != "preserved"
        ):
            self.send_response(400)
            body = b"lost-header"
        elif token is not None and token != expected:
            self.send_response(400)
            body = b"wrong-token"
        else:
            self.send_response(200)
            body = b"token" if token else b"no-token"
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


helper, agy, openssl, harness = sys.argv[1:]
spec = importlib.util.spec_from_file_location("antigravity_cert", helper)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

with tempfile.TemporaryDirectory(dir=".") as directory:
    scratch = Path(directory)
    pinned = scratch / "pinned.pem"
    for pem in re.findall(
        rb"-----BEGIN CERTIFICATE-----\s+[A-Za-z0-9+/=\r\n]+-----END CERTIFICATE-----",
        Path(agy).read_bytes(),
    ):
        result = subprocess.run(
            [openssl, "x509", "-noout", "-checkip", "127.0.0.1"],
            input=pem,
            capture_output=True,
            check=False,
        )
        if result.returncode == 0:
            pinned.write_bytes(pem)
            break
    foreign = scratch / "foreign.pem"
    subprocess.run(
        [
            openssl,
            "req",
            "-x509",
            "-newkey",
            "rsa:2048",
            "-noenc",
            "-subj",
            "/CN=localhost",
            "-addext",
            "subjectAltName=IP:127.0.0.1,DNS:localhost",
            "-days",
            "1",
            "-keyout",
            str(scratch / "key.pem"),
            "-out",
            str(foreign),
        ],
        check=True,
        capture_output=True,
    )
    assert module.localhost_fingerprint(agy, openssl) == module.localhost_fingerprint(
        pinned, openssl
    )
    for data in (
        b"no certificates",
        pinned.read_bytes() + b"\n" + foreign.read_bytes(),
    ):
        fixture = scratch / "invalid"
        fixture.write_bytes(data)
        try:
            module.localhost_fingerprint(fixture, openssl)
        except ValueError:
            pass
        else:
            raise AssertionError("missing or ambiguous certificates must fail closed")
    context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    context.load_cert_chain(foreign, scratch / "key.pem")
    server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), Handler)
    server.socket = context.wrap_socket(server.socket, server_side=True)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    try:
        subprocess.run(
            [harness, agy, str(pinned), str(foreign), str(server.server_port)],
            check=True,
        )
    finally:
        server.shutdown()
        server.server_close()
        thread.join()
