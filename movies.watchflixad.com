# Step 2: Extract base path per type
map $uri $secure_base_path {
    # Everything up to and including /hls/
    ~^(?P<base>.+/hls/)     $base;

    # Everything up to and including /original.mp4
    ~^(?P<base>.+/original\.mp4)    $base;

    # Fallback — use full URI
    default     $uri;
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

    # Reverse proxy for MP4/m3u8/ts streaming
    location ~* \.(mp4|m3u8|ts)$ {
        

        # ── Secure Link (staging only) ────────────────────────────────────────────
        secure_link $arg_token,$arg_e;

        set $secretKey "a9f3c7d1e8b5f2k4m6n8p1q3r5s7t9v2";
        secure_link_md5 "$secure_link_expires$secure_base_path $arg_upid $secretKey";
    
        if ($secure_link = "") {
            return 403;
        }

        if ($secure_link = "0") {
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
