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
    server_name series.watchflixad.com;

    root /var/www/series.watchflixad.com;
    index index.html;

    listen 443 ssl; # managed by Certbot
    ssl_certificate /etc/letsencrypt/live/series.watchflixad.com/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/series.watchflixad.com/privkey.pem; # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot

    set $allowed_cors_domain "https://watchflixad.com";
    include /etc/nginx/snippets/proxy-series-common.conf;

}
server {
    if ($host = series.watchflixad.com) {
        return 301 https://$host$request_uri;
    } # managed by Certbot


    listen 80;
    server_name series.watchflixad.com;
    return 404; # managed by Certbot


}
