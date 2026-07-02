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
    server_name movies.wflx.st;

    root /var/www/movies.wflx.st;
    index index.html;

    listen 443 ssl; # managed by Certbot
    ssl_certificate /etc/letsencrypt/live/movies.wflx.st/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/movies.wflx.st/privkey.pem; # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot


    set $allowed_cors_domain "https://wflx.st";
    include /etc/nginx/snippets/streaming-common.conf;

}
server {
    if ($host = movies.wflx.st) {
        return 301 https://$host$request_uri;
    } # managed by Certbot


    listen 80;
    server_name movies.wflx.st;
    return 404; # managed by Certbot


}
