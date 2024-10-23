#!/bin/sh
LOG_LEVEL="${LOG_LEVEL:-info}"
DNS="${DNS:-local}"

REMOTE_ADDRESS="${REMOTE_ADDRESS:-}"
REMOTE_PORT="${REMOTE_PORT:-443}"

ID="${ID:-}"
FLOW="${FLOW:-xtls-rprx-vision}"

SERVER_NAME="${SERVER_NAME:-}"
FINGER_PRINT="${FINGER_PRINT:-chrome}"

PUBLIC_KEY="${PUBLIC_KEY:-}"
SHORT_ID="${SHORT_ID:-}"

config_file() {
  cat > /singbox.json << EOF
{
  "log": {
    "level": "${LOG_LEVEL}",
    "timestamp": false
  },
  "dns": {
    "servers": [
      {
        "tag": "dns-direct",
        "address": "${DNS}",
        "detour": "direct"
      }
    ]
  },
  "inbounds": [
    {
      "type": "tun",
      "tag": "tun-in",
      "interface_name": "tun0",
      "address": ["198.18.0.1/24"],
      "mtu": 1500,
      "auto_route": true,
      "strict_route": true,
      "stack": "gvisor",
      "sniff": false,
      "route_exclude_address": ["192.168.0.0/16", "172.16.0.0/12", "10.0.0.0/8"]
    }
  ],
  "outbounds": [
    {
      "type": "vless",
      "tag": "vless-out",
      "server": "${REMOTE_ADDRESS}",
      "server_port": ${REMOTE_PORT},
      "uuid": "${ID}",
      "flow": "${FLOW}",
      "tls": {
        "enabled": true,
        "server_name": "${SERVER_NAME}",
        "utls": {
          "enabled": true,
          "fingerprint": "${FINGER_PRINT}"
        },
        "reality": {
          "enabled": true,
          "public_key": "${PUBLIC_KEY}",
          "short_id": "${SHORT_ID}"
        }
      },
      "packet_encoding": "xudp"
    },
    {
      "type": "dns",
      "tag": "dns-out"
    },
    {
      "type": "direct",
      "tag": "direct"
    }
  ],
  "route": {
    "auto_detect_interface": true,
    "rules": [
      {
        "inbound": "tun-in",
        "outbound": "vless-out"
      },
      {
        "port": 53,
        "outbound": "dns-out"
      }
    ]
  }
}
EOF
}

run() {
  config_file
  /bin/sing-box check -c /singbox.json --disable-color
  /bin/sing-box run -c /singbox.json --disable-color
}

run || exit 1
