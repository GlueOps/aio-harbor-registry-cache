#!/usr/bin/env python3
import http.server
import socketserver
import urllib.request
import ssl
import json
import sys

PORT = 1337
HARBOR_HEALTH_URL = "https://host.docker.internal:8443/api/v2.0/health"

class HealthCheckHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        try:
            # Create SSL context that ignores certificate verification
            ssl_context = ssl.create_default_context()
            ssl_context.check_hostname = False
            ssl_context.verify_mode = ssl.CERT_NONE
            
            # Make request to Harbor health endpoint
            req = urllib.request.Request(HARBOR_HEALTH_URL)
            with urllib.request.urlopen(req, context=ssl_context, timeout=12) as response:
                health_data = response.read().decode('utf-8')
                
                # Check if response contains "unhealthy" (case insensitive)
                if "unhealthy" in health_data.lower():
                    self.send_response(503)
                    self.send_header('Content-Type', 'application/json')
                    self.end_headers()
                    self.wfile.write(health_data.encode('utf-8'))
                else:
                    self.send_response(200)
                    self.send_header('Content-Type', 'application/json')
                    self.end_headers()
                    self.wfile.write(health_data.encode('utf-8'))
                    
        except Exception as e:
            # Harbor is unreachable or error occurred
            self.send_response(503)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            error_response = json.dumps({
                "status": "unhealthy",
                "error": str(e),
                "message": "Harbor health check failed"
            })
            self.wfile.write(error_response.encode('utf-8'))
    
    def log_message(self, format, *args):
        # Suppress default logging
        pass

if __name__ == "__main__":
    with socketserver.TCPServer(("", PORT), HealthCheckHandler) as httpd:
        print(f"Health check server running on port {PORT}")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nShutting down health check server")
            sys.exit(0)