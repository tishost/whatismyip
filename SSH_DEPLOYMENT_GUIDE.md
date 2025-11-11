# SSH Terminal Deployment Guide

## ✅ Implementation Complete

SSH Terminal feature has been successfully implemented with **hybrid approach** (API-first with option for direct mode later).

---

## 📦 What's Been Added

### 1. **Dependencies**
- ✅ `flutter_secure_storage` - For secure credential storage
- ✅ Using existing `dio` package for API calls
- ✅ Direct SSH will be added later via platform channels

### 2. **Code Files Created/Modified**

**New Files:**
- `lib/core/services/ssh_service.dart` - SSH connection service with hybrid approach
- `lib/presentation/screens/tools/ssh_screen.dart` - SSH terminal UI

**Modified Files:**
- `pubspec.yaml` - Added flutter_secure_storage
- `lib/data/models/tool_result.dart` - Added SSH to ToolType enum
- `lib/core/router/app_router.dart` - Added SSH route
- `lib/presentation/screens/tools_screen.dart` - Added SSH navigation

---

## 🔧 Backend API Endpoints Required

The SSH feature uses **digdns.io API** endpoints. You need to implement these on your backend:

### 1. **Connect Endpoint**
```
POST https://digdns.io/api/node/v1/ssh/connect
Content-Type: application/json

Request Body:
{
  "host": "example.com",
  "port": 22,
  "username": "root",
  "password": "password123",
  "privateKey": null  // Optional, for key-based auth
}

Response:
{
  "success": true,
  "data": {
    "sessionId": "unique-session-id-12345"
  }
}
```

### 2. **Execute Command Endpoint**
```
POST https://digdns.io/api/node/v1/ssh/execute
Content-Type: application/json

Request Body:
{
  "sessionId": "unique-session-id-12345",
  "command": "ls -la"
}

Response:
{
  "success": true,
  "data": {
    "output": "total 24\ndrwxr-xr-x...",
    "exitCode": 0,
    "error": null
  }
}
```

### 3. **Disconnect Endpoint**
```
POST https://digdns.io/api/node/v1/ssh/disconnect
Content-Type: application/json

Request Body:
{
  "sessionId": "unique-session-id-12345"
}

Response:
{
  "success": true,
  "message": "Disconnected"
}
```

---

## 🚀 Deployment Steps

### Step 1: Install Dependencies
```bash
flutter pub get
```

### Step 2: Backend API Implementation

You need to implement the SSH API endpoints on your digdns.io backend server. 

**Recommended Backend Stack:**
- Node.js with `ssh2` package
- Express.js for API routes
- Session management for SSH connections
- Rate limiting for security

**Example Node.js Implementation:**
```javascript
const express = require('express');
const { Client } = require('ssh2');
const router = express.Router();

const sshSessions = new Map(); // Store active SSH sessions

// Connect
router.post('/ssh/connect', async (req, res) => {
  const { host, port, username, password, privateKey } = req.body;
  
  const conn = new Client();
  const sessionId = generateSessionId();
  
  conn.on('ready', () => {
    sshSessions.set(sessionId, conn);
    res.json({
      success: true,
      data: { sessionId }
    });
  });
  
  conn.on('error', (err) => {
    res.json({
      success: false,
      error: err.message
    });
  });
  
  conn.connect({
    host,
    port: port || 22,
    username,
    password: password || undefined,
    privateKey: privateKey || undefined,
  });
});

// Execute
router.post('/ssh/execute', async (req, res) => {
  const { sessionId, command } = req.body;
  const conn = sshSessions.get(sessionId);
  
  if (!conn) {
    return res.json({
      success: false,
      error: 'Session not found'
    });
  }
  
  conn.exec(command, (err, stream) => {
    if (err) {
      return res.json({
        success: false,
        error: err.message
      });
    }
    
    let output = '';
    stream.on('close', (code) => {
      res.json({
        success: true,
        data: {
          output,
          exitCode: code
        }
      });
    });
    
    stream.on('data', (data) => {
      output += data.toString();
    });
    
    stream.stderr.on('data', (data) => {
      output += data.toString();
    });
  });
});

// Disconnect
router.post('/ssh/disconnect', (req, res) => {
  const { sessionId } = req.body;
  const conn = sshSessions.get(sessionId);
  
  if (conn) {
    conn.end();
    sshSessions.delete(sessionId);
  }
  
  res.json({ success: true });
});
```

### Step 3: Test the App

```bash
# Run on device/emulator
flutter run

# Or build APK
flutter build apk --debug
```

### Step 4: Build Release

```bash
# Build release APK
flutter build apk --release

# Or build App Bundle for Play Store
flutter build appbundle --release
```

---

## 🔐 Security Considerations

### Backend Security:
1. **Rate Limiting** - Limit SSH connection attempts per IP
2. **Session Timeout** - Auto-disconnect idle sessions after 5-10 minutes
3. **Input Validation** - Validate all inputs (host, port, command)
4. **Command Whitelist** (Optional) - Restrict dangerous commands
5. **HTTPS Only** - All API calls must use HTTPS
6. **Authentication** - Consider adding API key authentication

### App Security:
1. **Credential Storage** - Using `flutter_secure_storage` for passwords
2. **No Logging** - Never log passwords or sensitive data
3. **Certificate Validation** - Validate SSL certificates
4. **Timeout** - Connection timeout after 30 seconds

---

## 📱 Testing Checklist

- [ ] SSH connection via API mode
- [ ] Command execution
- [ ] Multiple commands in sequence
- [ ] Disconnect functionality
- [ ] Error handling (invalid host, wrong password, etc.)
- [ ] Connection status indicator
- [ ] Terminal output display
- [ ] Clear terminal button
- [ ] Back button navigation
- [ ] App lifecycle (pause/resume with active connection)

---

## 🐛 Known Limitations

1. **Direct SSH Mode** - Not yet implemented (requires platform channels)
2. **SSH Key Authentication** - Currently only password auth via API
3. **Interactive Commands** - Commands requiring user input may not work
4. **File Transfer** - SFTP not yet implemented
5. **Port Forwarding** - Not yet implemented

---

## 🔄 Future Enhancements

### v1.1.1 (Next Update)
- [ ] SSH key file picker
- [ ] Connection history
- [ ] Multiple sessions
- [ ] Command history (arrow keys navigation)

### v1.2.0 (Future)
- [ ] Direct SSH mode (platform channels)
- [ ] SFTP file transfer
- [ ] Port forwarding
- [ ] Terminal customization (colors, fonts)
- [ ] Session export/import

---

## 📝 Notes

- The app currently uses **API mode only** for SSH connections
- Direct SSH mode will require native platform implementation
- All SSH operations go through digdns.io API for security
- Backend must handle SSH session management properly
- Consider implementing connection pooling on backend

---

## 🆘 Troubleshooting

### Connection Fails
- Check backend API is running
- Verify API endpoints are correct
- Check network connectivity
- Verify credentials are correct

### Commands Not Executing
- Check session ID is valid
- Verify backend session management
- Check command syntax

### App Crashes
- Check logs: `flutter logs`
- Verify all dependencies installed
- Check Android permissions

---

**Last Updated:** 2025-01-XX
**Status:** ✅ Implementation Complete - Backend API Required
**Next Step:** Implement backend SSH API endpoints on digdns.io

