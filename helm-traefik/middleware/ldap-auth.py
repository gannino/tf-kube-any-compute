#!/usr/bin/env python3
import os
import base64
import hmac
import hashlib
import time
import secrets
import re
from flask import Flask, request, jsonify, make_response, redirect
from werkzeug.middleware.proxy_fix import ProxyFix
from ldap3 import Server, Connection, ALL, Tls
import ssl

app = Flask(__name__)
app.secret_key = os.getenv('SECRET_KEY', base64.b64encode(os.urandom(32)).decode())

# Trust proxy headers for SSL termination
app.wsgi_app = ProxyFix(app.wsgi_app, x_for=1, x_proto=1, x_host=1, x_prefix=1)

# Rate limiting
login_attempts = {}
MAX_ATTEMPTS = 5
BLOCK_TIME = 300  # 5 minutes

# LDAP Configuration
LDAP_URL = os.getenv('LDAP_URL', 'ldap://ldap.jumpcloud.com')
LDAP_BASE_DN = os.getenv('LDAP_BASE_DN', '')
LDAP_BIND_DN = os.getenv('LDAP_BIND_DN', '')
LDAP_BIND_PASSWORD = os.getenv('LDAP_BIND_PASSWORD', '')
LDAP_ATTRIBUTE = os.getenv('LDAP_ATTRIBUTE', 'uid')
LDAP_PORT = int(os.getenv('LDAP_PORT', '636' if LDAP_URL.startswith('ldaps') else '389'))
LDAP_SEARCH_FILTER = os.getenv('LDAP_SEARCH_FILTER', '')
LDAP_USE_TLS = LDAP_URL.startswith('ldaps')
AUTH_DOMAIN = os.getenv('AUTH_DOMAIN', 'auth.prod.k3s.annino.cloud')

def create_signed_token(username):
    timestamp = str(int(time.time()))
    data = f"{username}:{timestamp}"
    signature = hmac.new(app.secret_key.encode(), data.encode(), hashlib.sha256).hexdigest()
    return base64.b64encode(f"{data}:{signature}".encode()).decode()

def verify_signed_token(token, max_age=28800):
    try:
        decoded = base64.b64decode(token).decode()
        username, timestamp, signature = decoded.rsplit(':', 2)
        data = f"{username}:{timestamp}"
        expected_sig = hmac.new(app.secret_key.encode(), data.encode(), hashlib.sha256).hexdigest()
        if not hmac.compare_digest(signature, expected_sig):
            return None
        if int(time.time()) - int(timestamp) > max_age:
            return None
        return username
    except:
        return None

def check_rate_limit(ip):
    now = time.time()
    if ip in login_attempts:
        attempts, last_attempt = login_attempts[ip]
        if now - last_attempt < BLOCK_TIME and attempts >= MAX_ATTEMPTS:
            return False
        if now - last_attempt > BLOCK_TIME:
            login_attempts[ip] = (0, now)
    return True

def record_attempt(ip, success):
    now = time.time()
    if ip not in login_attempts:
        login_attempts[ip] = (0, now)
    attempts, _ = login_attempts[ip]
    if success:
        login_attempts[ip] = (0, now)
    else:
        login_attempts[ip] = (attempts + 1, now)

def sanitize_username(username):
    if not username or len(username) > 64:
        return None
    if not re.match(r'^[a-zA-Z0-9._@-]+$', username):
        return None
    return username.strip()

LOGIN_HTML = '''<!DOCTYPE html>
<html>
<head>
    <title>Login</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body {{ font-family: Arial, sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; }}
        .login-container {{ background: white; padding: 2rem; border-radius: 10px; box-shadow: 0 10px 25px rgba(0,0,0,0.2); width: 100%; max-width: 400px; }}
        h2 {{ text-align: center; color: #333; margin-bottom: 1.5rem; }}
        .form-group {{ margin-bottom: 1rem; }}
        label {{ display: block; margin-bottom: 0.5rem; color: #555; font-weight: 500; }}
        input {{ width: 100%; padding: 0.75rem; border: 1px solid #ddd; border-radius: 5px; font-size: 1rem; box-sizing: border-box; }}
        input:focus {{ outline: none; border-color: #667eea; }}
        button {{ width: 100%; padding: 0.75rem; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; border: none; border-radius: 5px; font-size: 1rem; font-weight: 600; cursor: pointer; margin-top: 1rem; }}
        button:hover {{ opacity: 0.9; }}
        .error {{ background: #fee; border: 1px solid #fcc; color: #c33; padding: 0.75rem; border-radius: 5px; margin-bottom: 1rem; text-align: center; }}
    </style>
</head>
<body>
    <div class="login-container">
        <h2>🔐 LDAP Sign In</h2>
        <p style="text-align: center; color: #666; margin-bottom: 0.5rem; font-size: 0.9rem;">{host}</p>
        <p style="text-align: center; color: #999; margin-bottom: 1rem; font-size: 0.8rem;">LDAP: {ldap_server}</p>
        {error}
        <form method="POST" action="https://{auth_domain}/auth">
            <input type="hidden" name="redirect" value="{redirect}">
            <div class="form-group">
                <label for="username">Username</label>
                <input type="text" id="username" name="username" required autofocus>
            </div>
            <div class="form-group">
                <label for="password">Password</label>
                <input type="password" id="password" name="password" required>
            </div>
            <button type="submit">Login</button>
        </form>
    </div>
</body>
</html>'''

def verify_ldap(username, password):
    print(f"[INFO] LDAP auth attempt for user: {username[:3]}***")
    if not password or len(password) > 128:
        print(f"[WARN] Invalid password length")
        return False
    try:
        tls_config = None
        if LDAP_USE_TLS:
            tls_config = Tls(validate=ssl.CERT_REQUIRED)
        server = Server(LDAP_URL, port=LDAP_PORT, use_ssl=LDAP_USE_TLS, tls=tls_config, get_info=ALL)
        print(f"[DEBUG] LDAP server created (TLS: {LDAP_USE_TLS})")

        if LDAP_SEARCH_FILTER:
            escaped_username = username.replace('\\', '\\\\').replace('*', '\\*').replace('(', '\\(').replace(')', '\\)')
            search_filter = LDAP_SEARCH_FILTER.replace('{username}', escaped_username)
            print(f"[DEBUG] Using search filter (sanitized)")
            if LDAP_BIND_DN and LDAP_BIND_PASSWORD:
                print(f"[DEBUG] Binding with service account: {LDAP_BIND_DN}")
                conn = Connection(server, LDAP_BIND_DN, LDAP_BIND_PASSWORD, auto_bind=True)
                print(f"[DEBUG] Service account bind successful")
                conn.search(LDAP_BASE_DN, search_filter, attributes=['dn'])
                print(f"[DEBUG] Search returned {len(conn.entries)} entries")
                if conn.entries:
                    user_dn = str(conn.entries[0].entry_dn)
                    print(f"[DEBUG] Found user DN: {user_dn}")
                    conn.unbind()
                    print(f"[DEBUG] Attempting user bind with found DN")
                    conn = Connection(server, user_dn, password, auto_bind=True)
                else:
                    print(f"[DEBUG] No user found with search filter")
                    return False
            else:
                print(f"[DEBUG] Anonymous bind for search")
                conn = Connection(server, auto_bind=True)
                conn.search(LDAP_BASE_DN, search_filter, attributes=['dn'])
                print(f"[DEBUG] Search returned {len(conn.entries)} entries")
                if conn.entries:
                    user_dn = str(conn.entries[0].entry_dn)
                    print(f"[DEBUG] Found user DN: {user_dn}")
                    conn.unbind()
                    print(f"[DEBUG] Attempting user bind with found DN")
                    conn = Connection(server, user_dn, password, auto_bind=True)
                else:
                    print(f"[DEBUG] No user found with search filter")
                    return False
        else:
            user_dn = f"{LDAP_ATTRIBUTE}={username},{LDAP_BASE_DN}"
            print(f"[DEBUG] Direct bind with DN: {user_dn}")
            conn = Connection(server, user_dn, password, auto_bind=True)

        if conn.bind():
            print(f"[INFO] Auth successful for: {username[:3]}***")
            conn.unbind()
            return True
        print(f"[WARN] Auth failed for: {username[:3]}***")
        return False
    except Exception as e:
        print(f"[ERROR] LDAP Error: {str(e)[:100]}")
        return False



@app.route('/auth', methods=['GET', 'POST'])
def auth():
    try:
        if request.method == 'POST':
            client_ip = request.headers.get('X-Real-Ip', request.remote_addr)

            if not check_rate_limit(client_ip):
                print(f"[WARN] Rate limit exceeded for IP: {client_ip}")
                return LOGIN_HTML.format(error='<div class="error">Too many attempts. Try again later.</div>', redirect='/'), 429

            username = sanitize_username(request.form.get('username', ''))
            password = request.form.get('password', '')
            redirect_url = request.form.get('redirect', '/')

            if not username or not password:
                record_attempt(client_ip, False)
                host = request.headers.get('X-Forwarded-Host', request.headers.get('Host', ''))
                ldap_server = LDAP_URL.replace('ldap://', '').replace('ldaps://', '')
                return LOGIN_HTML.format(error='<div class="error">Username and password required</div>', redirect=redirect_url, auth_domain=AUTH_DOMAIN, host=host, ldap_server=ldap_server), 400

            if not redirect_url.startswith('/'):
                redirect_url = '/'

            if verify_ldap(username, password):
                record_attempt(client_ip, True)
                auth_token = create_signed_token(username)
                # Get original host from Referer header (where the form was shown)
                referer = request.headers.get('Referer', '')
                if referer and '://' in referer:
                    original_host = referer.split('://')[1].split('/')[0]
                else:
                    original_host = request.headers.get('X-Forwarded-Host', request.headers.get('Host', '')).replace('auth.', '')
                try:
                    response = make_response(redirect(f'https://{original_host}{redirect_url}'))
                    # Extract parent domain (e.g., prod.k3s.annino.cloud from traefik.prod.k3s.annino.cloud)
                    domain_parts = original_host.split('.')
                    if len(domain_parts) > 2:
                        parent_domain = '.'.join(domain_parts[-3:])  # Get last 3 parts
                    else:
                        parent_domain = original_host
                    response.set_cookie('auth_token', auth_token, max_age=28800, httponly=True, secure=True, samesite='Lax', domain=f'.{parent_domain}')
                    print(f"[DEBUG] Cookie set for domain: .{parent_domain}, redirect to: https://{original_host}{redirect_url}")
                    return response
                except Exception as e:
                    print(f"[ERROR] Failed to set cookie/redirect: {e}")
                    host = request.headers.get('X-Forwarded-Host', request.headers.get('Host', ''))
                    ldap_server = LDAP_URL.replace('ldap://', '').replace('ldaps://', '')
                    return LOGIN_HTML.format(error='<div class="error">Login successful but redirect failed</div>', redirect=redirect_url, auth_domain=AUTH_DOMAIN, host=host, ldap_server=ldap_server), 500
            else:
                record_attempt(client_ip, False)
                time.sleep(1)
                host = request.headers.get('X-Forwarded-Host', request.headers.get('Host', ''))
                ldap_server = LDAP_URL.replace('ldap://', '').replace('ldaps://', '')
                return LOGIN_HTML.format(error='<div class="error">Invalid credentials</div>', redirect=redirect_url, auth_domain=AUTH_DOMAIN, host=host, ldap_server=ldap_server), 401

        auth_cookie = request.cookies.get('auth_token')
        if auth_cookie:
            print(f"[DEBUG] Checking cookie: {auth_cookie[:20]}...")
            username = verify_signed_token(auth_cookie)
            if username:
                print(f"[INFO] Valid session for: {username[:3]}***")
                response = make_response('', 200)
                response.headers['X-Forwarded-User'] = username
                return response
            print(f"[WARN] Invalid/expired token - cookie present but verification failed")
        else:
            print(f"[DEBUG] No auth cookie found in request")

        # Get the original URL - X-Forwarded-Uri contains /auth, we want the original page
        redirect_url = request.headers.get('X-Forwarded-Uri', '/')
        # If redirect is /auth, use root instead (user accessed auth directly)
        if redirect_url == '/auth':
            redirect_url = '/'
        # Get the host being accessed
        host = request.headers.get('X-Forwarded-Host', request.headers.get('Host', ''))
        ldap_server = LDAP_URL.replace('ldap://', '').replace('ldaps://', '')
        response = make_response(LOGIN_HTML.format(error='', redirect=redirect_url, auth_domain=AUTH_DOMAIN, host=host, ldap_server=ldap_server), 401)
        response.headers['Content-Security-Policy'] = "default-src 'self'; script-src 'unsafe-inline'; style-src 'unsafe-inline'"
        response.headers['X-Content-Type-Options'] = 'nosniff'
        response.headers['X-Frame-Options'] = 'DENY'
        return response
    except Exception as e:
        print(f"[ERROR] Unhandled error in auth: {e}")
        import traceback
        print(f"[ERROR] {traceback.format_exc()}")
        return 'Internal Server Error', 500

@app.route('/health')
def health():
    return jsonify({'status': 'healthy'})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, debug=False)

# For Gunicorn
if __name__ != '__main__':
    import logging
    logging.basicConfig(level=logging.INFO)
