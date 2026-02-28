# Backend: Block Non-Drivers Before OTP (Driver App)

## Goal

Admins and other non-drivers must **never** reach the OTP screen. They should be blocked at login, before an OTP is sent.

## Options for Backend

### Option 1: Reject non-drivers at login (recommended)

**Before sending OTP**, when the request includes `client: "driver_app"`:

1. Validate credentials and look up `user_type`.
2. If `user_type` is NOT `driver` (e.g. `admin`, `parent`, `school_admin`):
   - Return an error immediately. **Do NOT send OTP.**
   - Example: `403` or `200` with `{ "success": false, "message": "Only drivers can access the application. Contact your admin for further assistance." }`
3. If `user_type` is `driver`: send OTP and return `{ "success": true, "otp_id": ..., ... }`.

```python
# In login view, BEFORE OTP send:
if request.data.get('client') == 'driver_app':
    if getattr(user, 'user_type', None) != 'driver':
        return Response({
            'success': False,
            'message': 'Only drivers can access the application. Contact your admin for further assistance.',
            'error': {...}
        }, status=403)
# ... send OTP for drivers only ...
```

### Option 2: Include user_type in login response

If the backend still sends OTP to all users, add `user_type` to the success response so the app can block before navigating to OTP:

```json
{
  "success": true,
  "otp_id": 596,
  "user_type": "driver",
  "delivery_methods": { ... }
}
```

- For drivers: `user_type: "driver"` → app allows OTP screen.
- For non-drivers: `user_type: "admin"` (etc.) → app blocks and shows the message.

## App Behavior

- When login returns **error** (Option 1): app stays on login screen, shows error. Admin never reaches OTP.
- When login returns **success** with `user_type` (Option 2): app blocks non-drivers before OTP screen.
- Fallback: if backend does neither, non-drivers reach OTP and are blocked after verification (from profile).
