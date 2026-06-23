# http {} block
map $http_origin $sl_token {
    "~staging\.watchflixad\.com"  $arg_token;
    default          "";
}

map $http_origin $sl_expiry {
    "~staging\.watchflixad\.com"  $arg_e;
    default          "";
}

# Override $secure_link result for non-staging hosts — force it to "1" (valid)
map $http_origin $force_secure_link {
    "~staging\.watchflixad\.com"  "";   # empty = don't force, use real $secure_link value
    default          "1";  # force valid for all other hosts
}


server {
    server_name movies.watchflixad.com;

    root /var/www/movies.watchflixad.com;
    index index.html;

    listen 443 ssl; # managed by Certbot
    ssl_certificate /etc/letsencrypt/live/movies.watchflixad.com/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/movies.watchflixad.com/privkey.pem; # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot


    location /debug-time {
        return 200 "nginx_time=$time_local unix=$msec\n";
    }

    # Reverse proxy for MP4/m3u8/ts streaming
    location ~* \.(mp4|m3u8|ts)$ {
        

        # ── Secure Link (staging only) ────────────────────────────────────────────
        set $folder_token_path "";   # explicit default

        if ($uri ~* "^(/.+/original)") {
          set $folder_token_path $1;
        }

        if ($folder_token_path = "") {
            # skip token validation or return 403
            # return 403;
        }

        secure_link $sl_token,$sl_expiry;

        set $secretKey "a9f3c7d1e8b5f2k4m6n8p1q3r5s7t9v2";

        secure_link_md5 "$secure_link_expires$folder_token_path $secretKey";

        # For non-staging, $force_secure_link = "1" so these ifs are never triggered
        set $effective_secure_link $secure_link;

        # add_header X-Debug-FORCE-Link $force_secure_link always;
        # add_header X-Debug-http-rogina-Link $http_origin always;
        # add_header X-Debug-http-secure-md5-Link "$secure_link_expires$uri $secretKey" always;
        # add_header X-Debug-http-secure-sl_expiry "$sl_expiry" always;
        # add_header X-Now $msec always;
        # add_header X-Debug-http-secure-secure_link_expires "$secure_link_expires" always;
        # add_header X-Debug-Uri $uri always;
        # add_header X-Debug-http-secure-secure_link "$secure_link" always;
        # add_header X-Debug-http-secure-effective_secure_link "$effective_secure_link" always;


        if ($force_secure_link = "1") {
            set $effective_secure_link "1";
        }

        if ($effective_secure_link = "") {
            return 403;
        }

        if ($effective_secure_link = "0") {
            return 410;
        }
        # ── End Secure Link ───────────────────────────────────────────────────────


        # proxy_pass https://83.149.92.247;        
        # resolver 8.8.8.8 ipv6=off;
        # set $upstream "shieldedstar.com";
        # proxy_pass https://$upstream;


        # proxy_set_header Host shieldedstar.com;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_http_version 1.1;
        proxy_set_header Connection "";

        proxy_set_header Range $http_range;
        proxy_set_header If-Range $http_if_range;

        proxy_buffering off;
        proxy_request_buffering off;


        # proxy_ssl_server_name on;
        # proxy_ssl_verify off;

        # Remove any existing CORS headers from upstream
        proxy_hide_header Access-Control-Allow-Origin;
        proxy_hide_header Access-Control-Allow-Methods;
        proxy_hide_header Access-Control-Allow-Headers;


        set $cors "";
        if ($http_origin ~* "^https?://([a-z0-9-]+\.)?watchflixad\.com$") {
          set $cors $http_origin;
        }

        # add_header Access-Control-Allow-Origin "https://watchflixad.com" always;
       
        add_header 'Access-Control-Allow-Origin' $cors always;
        # add_header Access-Control-Allow-Origin $cors always;
        add_header Access-Control-Allow-Methods "GET, OPTIONS" always;
        add_header Access-Control-Allow-Headers "*" always;


        proxy_pass https://83.149.92.247;

        # CORS headers
        # add_header Access-Control-Allow-Origin *;
        # add_header Access-Control-Allow-Methods "GET, OPTIONS";
        # add_header Access-Control-Allow-Headers "*";
    }

}
server {
    if ($host = movies.watchflixad.com) {
        return 301 https://$host$request_uri;
    } # managed by Certbot


    listen 80;
    server_name movies.watchflixad.com;
    return 404; # managed by Certbot


}
