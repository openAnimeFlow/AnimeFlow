import 'dart:io';

const fixtureDirectory = 'test/core/network/flow/fixtures';

SecurityContext trustedTestContext() => SecurityContext(withTrustedRoots: false)
  ..setTrustedCertificates('$fixtureDirectory/server-cert.pem');

Future<HttpServer> testTlsServer() => HttpServer.bindSecure(
    InternetAddress.loopbackIPv4,
    0,
    SecurityContext()
      ..useCertificateChain('$fixtureDirectory/server-cert.pem')
      ..usePrivateKey('$fixtureDirectory/server-key.pem'));
