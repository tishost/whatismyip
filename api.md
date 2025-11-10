# DigDNS Node.js API Documentation

## Overview

DigDNS Node.js API provides comprehensive network tools and IP information services including:
- IP geolocation with city-level accuracy
- Proxy/VPS/VPN detection
- IP Whois lookup
- Network traceroute
- ISP information

**Base URL:**
- Production: `https://digdns.io/api/node/v1`
- Direct: `http://localhost:3000/api/v1`

**API Version:** 1.0.0

---

## Table of Contents

1. [Health Check](#health-check)
2. [API Status](#api-status)
3. [IP Location API](#ip-location-api)
4. [Traceroute API](#traceroute-api)
5. [IP Whois Lookup API](#ip-whois-lookup-api)
6. [Error Handling](#error-handling)
7. [Access Methods](#access-methods)

---

## Health Check

### Endpoint
```
GET /health
```

**Example:**
```bash
curl https://digdns.io/api/node/health
```

**Response:**
```json
{
  "status": "ok",
  "message": "DigDNS Node.js API is running",
  "timestamp": "2025-11-09T03:16:06.144Z"
}
```

---

## API Status

### Endpoint
```
GET /api/v1/status
```

**Example:**
```bash
curl https://digdns.io/api/node/v1/status
```

**Response:**
```json
{
  "success": true,
  "data": {
    "service": "DigDNS API",
    "version": "1.0.0",
    "uptime": 46.047613052
  }
}
```

---

## IP Location API

### Get Visitor's IP and Location

#### Endpoint
```
GET /api/v1/ip/location
GET /api/v1/ip/location?ip=8.8.8.8
GET /api/v1/ip/location?ip=2001:4860:4860::8888
```

**Note:** Supports both IPv4 and IPv6 addresses. IPv6 location data is limited (country and ISP only) as the LITE database doesn't support full IPv6 geolocation.

**Examples:**
```bash
# Get visitor's IP location (auto-detected)
curl https://digdns.io/api/node/v1/ip/location

# Get specific IP location
curl https://digdns.io/api/node/v1/ip/location?ip=8.8.8.8

# IPv6 location
curl https://digdns.io/api/node/v1/ip/location?ip=2001:4860:4860::8888
```

**Response:**
```json
{
  "success": true,
  "data": {
    "ip": "43.231.20.253",
    "country": "Bangladesh",
    "countryCode": "BD",
    "region": "Dhaka",
    "city": "Dhaka",
    "latitude": 23.710394,
    "longitude": 90.407112,
    "isp": "Radiant Communications Ltd",
    "domain": "",
    "timezone": "+06:00",
    "proxy": {
      "isProxy": true,
      "proxyType": "PUB",
      "isVpn": false,
      "isTor": false,
      "isDataCenter": false,
      "isPublicProxy": true,
      "isWebProxy": false,
      "isSearchEngineRobot": false,
      "isResidentialProxy": false,
      "isVps": false
    },
    "timestamp": "2025-11-09T03:47:02.655Z",
    "source": "local_database"
  }
}
```

**Proxy/VPS Detection Fields:**
- `proxy.isProxy`: Boolean - Whether the IP is a proxy
- `proxy.proxyType`: String - Type of proxy (PUB, VPN, TOR, DCH, etc.)
- `proxy.isVpn`: Boolean - Whether the IP is a VPN
- `proxy.isTor`: Boolean - Whether the IP is a Tor exit node
- `proxy.isDataCenter`: Boolean - Whether the IP is from a datacenter
- `proxy.isVps`: Boolean - Whether the IP is likely a VPS (datacenter IPs)
- `proxy.isPublicProxy`: Boolean - Whether it's a public proxy
- `proxy.isWebProxy`: Boolean - Whether it's a web proxy
- `proxy.isSearchEngineRobot`: Boolean - Whether it's a search engine bot
- `proxy.isResidentialProxy`: Boolean - Whether it's a residential proxy

**Response Fields:**
- `ip`: String - IP address
- `country`: String - Full country name
- `countryCode`: String - ISO 3166-1 alpha-2 country code
- `region`: String - Region/State name
- `city`: String - City name
- `latitude`: Number or null - Latitude coordinate
- `longitude`: Number or null - Longitude coordinate
- `isp`: String - Internet Service Provider name
- `domain`: String - Domain name (if available)
- `timezone`: String - Timezone offset (e.g., "+06:00")
- `proxy`: Object - Proxy/VPS detection data (see above)
- `timestamp`: String - ISO 8601 timestamp
- `source`: String - Data source ("local_database" or "whois_fallback")
- `note`: String - Additional information (for IPv6)

**Error Responses:**

- **400 Bad Request** - Invalid IP format
```json
{
  "success": false,
  "error": "Invalid IP address format"
}
```

- **400 Bad Request** - IP address required
```json
{
  "success": false,
  "error": "IP address is required"
}
```

---

## Traceroute API

### Endpoints

#### 1. GET - Traceroute (URL Parameter)
```
GET /api/v1/traceroute/:target
GET /api/v1/traceroute/:target?maxHops=30&timeout=5
```

**Parameters:**
- `target` (required): IP address or domain name
- `maxHops` (optional): Maximum number of hops (1-255, default: 30)
- `timeout` (optional): Timeout per hop in seconds (default: 5)

**Example:**
```bash
curl https://digdns.io/api/node/v1/traceroute/8.8.8.8?maxHops=10
curl https://digdns.io/api/node/v1/traceroute/google.com?maxHops=5
```

#### 2. POST - Traceroute (Request Body)
```
POST /api/v1/traceroute
```

**Request Body:**
```json
{
  "target": "8.8.8.8",
  "maxHops": 10,
  "timeout": 5
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "target": "8.8.8.8",
    "maxHops": 10,
    "timeout": 5,
    "hops": [
      {
        "hop": 1,
        "ip": "51.81.154.252",
        "hostname": null,
        "times": [0.571, 0.612, 0.648],
        "avgTime": 0.61,
        "status": "success"
      },
      {
        "hop": 2,
        "ip": "10.23.162.64",
        "hostname": null,
        "times": [0.51, 0.425, 0.477],
        "avgTime": 0.47,
        "status": "success"
      }
    ],
    "totalHops": 2,
    "raw": "traceroute output...",
    "timestamp": "2025-11-09T05:31:40.555Z"
  }
}
```

**Hop Object Fields:**
- `hop`: Number - Hop number (1, 2, 3, ...)
- `ip`: String or null - IP address of the hop
- `hostname`: String or null - Hostname if available
- `times`: Array - Array of 3 response times in milliseconds [time1, time2, time3]
- `avgTime`: Number or null - Average response time in milliseconds
- `status`: String - "success" or "timeout"

**Note:** Supports both IPv4 and IPv6 addresses. For IPv6, `traceroute6` is used automatically.

**Error Responses:**

- **400 Bad Request** - Invalid parameters
```json
{
  "success": false,
  "error": "maxHops must be between 1 and 255"
}
```

- **404 Not Found** - Target host not found
```json
{
  "success": false,
  "error": "Target host not found",
  "target": "invalid-domain.example"
}
```

- **500 Internal Server Error** - Traceroute failed
```json
{
  "success": false,
  "error": "Traceroute failed or no response",
  "raw": "traceroute output..."
}
```

---

## IP Whois Lookup API

### Endpoints

#### 1. GET - IP Whois Lookup (URL Parameter)
```
GET /api/v1/whois/ip/:ip
```

**Example:**
```bash
curl https://digdns.io/api/node/v1/whois/ip/8.8.8.8
```

#### 2. POST - IP Whois Lookup (Request Body)
```
POST /api/v1/whois/ip
Content-Type: application/json

{
  "ip": "8.8.8.8"
}
```

**Example:**
```bash
curl -X POST https://digdns.io/api/node/v1/whois/ip \
  -H "Content-Type: application/json" \
  -d '{"ip": "8.8.8.8"}'
```

### Response Format

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "ip": "8.8.8.8",
    "raw": "Raw whois output text...",
    "parsed": {
      "Netrange": "8.8.8.0 - 8.8.8.255",
      "Cidr": "8.8.8.0/24",
      "Netname": "GOGL",
      "Organization": "Google LLC (GOGL)",
      "Country": "US",
      ...
    },
    "timestamp": "2025-11-09T03:16:06.144Z"
  }
}
```

**Error Responses:**

- **400 Bad Request** - Invalid IP format
```json
{
  "success": false,
  "error": "Invalid IP address format"
}
```

- **404 Not Found** - IP not found in whois
```json
{
  "success": false,
  "error": "WHOIS information not found for this IP address"
}
```

- **503 Service Unavailable** - Whois server busy
```json
{
  "success": false,
  "error": "WHOIS server is busy due to too many requests. Please try again in a few minutes."
}
```

### Supported IP Formats

- IPv4: `8.8.8.8`, `192.168.1.1`
- IPv6: `2001:4860:4860::8888`

---

## Error Handling

All API endpoints follow a consistent error response format:

**Standard Error Response:**
```json
{
  "success": false,
  "error": "Error message here",
  "message": "Additional details (development mode only)"
}
```

**Common HTTP Status Codes:**
- `200 OK` - Request successful
- `400 Bad Request` - Invalid parameters or request format
- `404 Not Found` - Resource not found
- `500 Internal Server Error` - Server error
- `503 Service Unavailable` - Service temporarily unavailable

---

## Access Methods

### Via Nginx Proxy (Recommended)

All API endpoints are accessible through the nginx proxy at:
```
https://digdns.io/api/node/v1/{endpoint}
```

**Examples:**
```
https://digdns.io/api/node/v1/ip/location?ip=8.8.8.8
https://digdns.io/api/node/v1/traceroute/8.8.8.8?maxHops=10
https://digdns.io/api/node/v1/whois/ip/8.8.8.8
https://digdns.io/api/node/v1/status
https://digdns.io/api/node/health
```

**Note:** The old format `/api/node/api/v1/` is still supported for backward compatibility, but the recommended format is `/api/node/v1/`.

### Direct Access (Port 3000)

You can also access the API directly on port 3000 (localhost only):
```
http://localhost:3000/api/v1/{endpoint}
```

**Examples:**
```
http://localhost:3000/api/v1/ip/location?ip=8.8.8.8
http://localhost:3000/api/v1/traceroute/8.8.8.8
http://localhost:3000/api/v1/whois/ip/8.8.8.8
http://localhost:3000/api/v1/status
http://localhost:3000/health
```

---

## Rate Limiting

Currently, there are no rate limits enforced. However, please use the API responsibly to ensure optimal performance for all users.

---

## Data Sources

- **IP Geolocation:** IP2Location LITE Database (DB11 - City level)
- **Proxy Detection:** IP2Proxy LITE Database (PX11)
- **ISP Information:** Extracted from Whois data when not available in database
- **IPv6 Support:** Limited - uses Whois fallback for basic information

---

## Support

For issues, questions, or feature requests, please contact the development team.

**Last Updated:** November 9, 2025

