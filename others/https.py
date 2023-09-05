#!/usr/bin/env python3

from http.server import HTTPServer,SimpleHTTPRequestHandler
import ssl
import sys

if __name__ == '__main__':
    port = 444
    if len(sys.argv) == 2:
        if sys.argv[1] in ['-h', '/?', '--help']:
            print('Usage: webs.py [<port>]')
            exit(0)
        try:
            port = int(sys.argv[1])
        except Exception as e:
            print(e)
            print('Usage: webs.py [<port>]')
            exit(0)

    server_address = ('0.0.0.0', port)
    httpd = HTTPServer(server_address, SimpleHTTPRequestHandler)
    sslctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    sslctx.check_hostname = False
    sslctx.load_cert_chain(certfile='/root/.config/ssl/cert.pem', keyfile='/root/.config/ssl/key.pem')
    httpd.socket = sslctx.wrap_socket(httpd.socket, server_side=True)

    print("Runing https web on %s:%d"%server_address)
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        exit(0)