# Prompt: Deployment Checklist

## Purpose
Generate comprehensive pre-deployment checklists and configuration guides for deploying Laravel applications to production environments safely and efficiently.

## When to Use
- Before first production deployment
- Major version releases
- Infrastructure changes
- Post-incident improvements
- Regular deployment audits

---

## Prompt Template

```
I need a deployment checklist for:

**Application**: [App name/type]
**Environment**: [Shared hosting/VPS/Cloud/Container]
**Stack**: [Web server, PHP version, database]
**Special Requirements**:
- [Redis, queues, cron jobs, etc.]
- [Third-party integrations]
- [Scaling requirements]

Please provide:
1. **Pre-deployment checklist**: What to verify before deploying
2. **Configuration changes**: Environment-specific settings
3. **Deployment steps**: Step-by-step deployment process
4. **Post-deployment verification**: How to verify successful deployment
5. **Rollback plan**: How to revert if issues occur
6. **Monitoring setup**: What to monitor
```

---

## Example: Laravel Application Deployment

### Input:
```
I need a deployment checklist for:

**Application**: E-commerce Laravel app
**Environment**: AWS (EC2 + RDS + S3 + Redis)
**Stack**: Nginx, PHP 8.2, MySQL 8.0, Redis
**Special Requirements**:
- Queue workers for order processing
- Scheduled tasks for reports
- Image uploads to S3
- Payment integration (Stripe)
- Email sending (SendGrid)
```

### Expected Output:

## 🚀 Production Deployment Checklist

---

## Phase 1: Pre-Deployment Preparation

### ✅ 1. Code Quality Checks

```bash
# Run tests
php artisan test --parallel

# Static analysis
./vendor/bin/phpstan analyse

# Code style
./vendor/bin/pint --test

# Security audit
composer audit
```

**Checklist:**
- [ ] All tests passing (100% critical tests)
- [ ] Code coverage > 80%
- [ ] No PHPStan errors
- [ ] No security vulnerabilities in dependencies
- [ ] Code style compliant

---

### ✅ 2. Environment Configuration

**`.env.production` Template:**
```env
# Application
APP_NAME="E-Commerce App"
APP_ENV=production
APP_KEY=  # Generate: php artisan key:generate --show
APP_DEBUG=false
APP_URL=https://www.example.com

# Database
DB_CONNECTION=mysql
DB_HOST=your-rds-endpoint.amazonaws.com
DB_PORT=3306
DB_DATABASE=ecommerce_prod
DB_USERNAME=prod_user
DB_PASSWORD=strong_random_password

# Cache & Session
CACHE_DRIVER=redis
SESSION_DRIVER=redis
QUEUE_CONNECTION=redis

# Redis
REDIS_HOST=your-elasticache-endpoint.amazonaws.com
REDIS_PASSWORD=null
REDIS_PORT=6379

# Mail
MAIL_MAILER=smtp
MAIL_HOST=smtp.sendgrid.net
MAIL_PORT=587
MAIL_USERNAME=apikey
MAIL_PASSWORD=your_sendgrid_api_key
MAIL_ENCRYPTION=tls
MAIL_FROM_ADDRESS=noreply@example.com
MAIL_FROM_NAME="${APP_NAME}"

# AWS S3
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
AWS_DEFAULT_REGION=us-east-1
AWS_BUCKET=your-bucket-name
AWS_USE_PATH_STYLE_ENDPOINT=false
FILESYSTEM_DISK=s3

# Stripe
STRIPE_KEY=pk_live_xxxxx
STRIPE_SECRET=sk_live_xxxxx
STRIPE_WEBHOOK_SECRET=whsec_xxxxx

# Logging
LOG_CHANNEL=stack
LOG_LEVEL=warning
LOG_SLACK_WEBHOOK_URL=your_slack_webhook

# Performance
OCTANE_SERVER=swoole  # or roadrunner
```

**Checklist:**
- [ ] All environment variables configured
- [ ] APP_DEBUG=false
- [ ] APP_ENV=production
- [ ] Strong APP_KEY generated
- [ ] Database credentials correct
- [ ] Redis connection tested
- [ ] S3 bucket configured and accessible
- [ ] Email sending tested
- [ ] Payment gateway in live mode
- [ ] All API keys are production keys
- [ ] Logging configured

---

### ✅ 3. Database Preparation

```bash
# Backup current database
php artisan backup:run --only-db

# Test migrations on staging
php artisan migrate --pretend

# Run migrations
php artisan migrate --force

# Verify data integrity
php artisan db:show
php artisan db:table users
```

**Checklist:**
- [ ] Database backup created
- [ ] Migrations tested on staging
- [ ] Rollback plan prepared
- [ ] Seeders ready (if needed)
- [ ] Indexes optimized
- [ ] Foreign keys verified

---

### ✅ 4. Security Hardening

```bash
# Update dependencies
composer update --no-dev --optimize-autoloader

# Check for vulnerabilities
composer audit

# Generate secure keys
php artisan key:generate
```

**Security Checklist:**
- [ ] All dependencies updated
- [ ] No known vulnerabilities
- [ ] HTTPS enforced
- [ ] CORS configured properly
- [ ] Rate limiting enabled
- [ ] CSRF protection enabled
- [ ] SQL injection prevention verified
- [ ] XSS protection verified
- [ ] File upload validation in place
- [ ] Sensitive data encrypted
- [ ] API tokens secured
- [ ] Database credentials rotated

---

## Phase 2: Deployment Process

### ✅ Step 1: Server Setup

```bash
# SSH into server
ssh ubuntu@your-server-ip

# Update system
sudo apt update && sudo apt upgrade -y

# Install required packages
sudo apt install -y nginx php8.2-fpm php8.2-mysql php8.2-redis \
    php8.2-mbstring php8.2-xml php8.2-curl php8.2-zip \
    php8.2-gd php8.2-bcmath redis-server supervisor

# Install Composer
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer

# Configure PHP
sudo nano /etc/php/8.2/fpm/php.ini
```

**PHP Configuration:**
```ini
memory_limit = 512M
upload_max_filesize = 50M
post_max_size = 50M
max_execution_time = 300
opcache.enable = 1
opcache.memory_consumption = 256
opcache.interned_strings_buffer = 16
opcache.max_accelerated_files = 10000
opcache.validate_timestamps = 0
```

---

### ✅ Step 2: Application Deployment

```bash
# Clone repository
cd /var/www
sudo git clone https://github.com/your-repo/ecommerce.git
cd ecommerce

# Checkout production branch
sudo git checkout production

# Install dependencies
sudo composer install --no-dev --optimize-autoloader

# Set permissions
sudo chown -R www-data:www-data /var/www/ecommerce
sudo chmod -R 755 /var/www/ecommerce
sudo chmod -R 775 /var/www/ecommerce/storage
sudo chmod -R 775 /var/www/ecommerce/bootstrap/cache

# Setup environment
sudo cp .env.production .env
sudo php artisan key:generate

# Optimize
sudo php artisan config:cache
sudo php artisan route:cache
sudo php artisan view:cache
sudo php artisan event:cache

# Run migrations
sudo php artisan migrate --force

# Create storage link
sudo php artisan storage:link
```

---

### ✅ Step 3: Nginx Configuration

```nginx
# /etc/nginx/sites-available/ecommerce
server {
    listen 80;
    listen [::]:80;
    server_name www.example.com example.com;

    # Redirect HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name www.example.com example.com;
    root /var/www/ecommerce/public;

    index index.php;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # Gzip compression
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

    charset utf-8;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }

    # Cache static assets
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

```bash
# Enable site
sudo ln -s /etc/nginx/sites-available/ecommerce /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

---

### ✅ Step 4: Queue Worker Configuration

```ini
# /etc/supervisor/conf.d/laravel-worker.conf
[program:laravel-worker]
process_name=%(program_name)s_%(process_num)02d
command=php /var/www/ecommerce/artisan queue:work redis --sleep=3 --tries=3 --max-time=3600
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
user=www-data
numprocs=4
redirect_stderr=true
stdout_logfile=/var/www/ecommerce/storage/logs/worker.log
stopwaitsecs=3600
```

```bash
# Start supervisor
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start laravel-worker:*
```

---

### ✅ Step 5: Scheduled Tasks (Cron)

```bash
# Edit crontab
sudo crontab -e -u www-data

# Add Laravel scheduler
* * * * * cd /var/www/ecommerce && php artisan schedule:run >> /dev/null 2>&1
```

---

### ✅ Step 6: SSL Certificate

```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx

# Obtain certificate
sudo certbot --nginx -d example.com -d www.example.com

# Test auto-renewal
sudo certbot renew --dry-run
```

---

## Phase 3: Post-Deployment Verification

### ✅ Application Health Checks

```bash
# Check application is running
curl -I https://www.example.com

# Check API endpoints
curl https://www.example.com/api/health

# Check database connection
php artisan tinker
>>> DB::connection()->getPdo();

# Check Redis connection
php artisan tinker
>>> Cache::put('test', 'value', 60);
>>> Cache::get('test');

# Check queue workers
sudo supervisorctl status

# Check cron jobs
sudo grep CRON /var/log/syslog

# Check logs
tail -f storage/logs/laravel.log
```

**Verification Checklist:**
- [ ] Website loads correctly
- [ ] HTTPS is working
- [ ] Database queries working
- [ ] Redis connection working
- [ ] Queue workers running
- [ ] Cron jobs executing
- [ ] Email sending works
- [ ] File uploads to S3 work
- [ ] Payment processing works
- [ ] No errors in logs

---

### ✅ Performance Verification

```bash
# Test response time
curl -o /dev/null -s -w 'Total: %{time_total}s\n' https://www.example.com

# Check OPcache status
php -r "print_r(opcache_get_status());"

# Monitor Redis
redis-cli info stats
```

**Performance Checklist:**
- [ ] Page load time < 2 seconds
- [ ] API response time < 500ms
- [ ] OPcache hit rate > 95%
- [ ] Redis memory usage acceptable
- [ ] Database query time acceptable

---

## Phase 4: Monitoring & Alerts

### ✅ Setup Monitoring

```php
// config/logging.php
'channels' => [
    'slack' => [
        'driver' => 'slack',
        'url' => env('LOG_SLACK_WEBHOOK_URL'),
        'username' => 'Laravel Log',
        'emoji' => ':boom:',
        'level' => 'critical',
    ],
],
```

**Monitoring Checklist:**
- [ ] Error logging configured
- [ ] Slack alerts for critical errors
- [ ] Uptime monitoring (e.g., UptimeRobot)
- [ ] Performance monitoring (e.g., New Relic)
- [ ] Server monitoring (CPU, RAM, Disk)
- [ ] Database monitoring
- [ ] Queue monitoring
- [ ] SSL certificate expiry alerts

---

## Phase 5: Rollback Plan

### ✅ If Deployment Fails

```bash
# Rollback database
php artisan migrate:rollback --step=1

# Restore previous code
git checkout previous-stable-tag
composer install --no-dev
php artisan config:cache
php artisan route:cache

# Restore database backup
mysql -u username -p database_name < backup.sql

# Restart services
sudo supervisorctl restart laravel-worker:*
sudo systemctl reload php8.2-fpm
sudo systemctl reload nginx
```

**Rollback Checklist:**
- [ ] Database backup available
- [ ] Previous code version tagged
- [ ] Rollback procedure tested
- [ ] Downtime window communicated

---

## 📋 Final Pre-Launch Checklist

### Critical
- [ ] All tests passing
- [ ] Database backed up
- [ ] Environment variables configured
- [ ] HTTPS working
- [ ] Security hardening complete

### High Priority
- [ ] Queue workers running
- [ ] Cron jobs configured
- [ ] Monitoring setup
- [ ] Error logging configured
- [ ] Performance optimized

### Important
- [ ] SSL certificate installed
- [ ] Rollback plan ready
- [ ] Documentation updated
- [ ] Team notified

---

## Related Prompts

- `security-audit.md` - Pre-deployment security check
- `performance-optimization.md` - Optimize before deployment
- `testing-strategy.md` - Verify all tests pass
