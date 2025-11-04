# Prompt: Documentation Generation

## Purpose
Generate comprehensive, clear, and useful documentation for Laravel projects including API docs, code comments, README files, and technical specifications.

## When to Use
- Creating API documentation
- Writing README files
- Documenting code and architecture
- Creating user guides
- Generating PHPDoc comments
- Writing technical specifications

---

## Prompt Template

```
Please generate documentation for:

**Type**: [API/Code/README/Architecture/etc.]
**Component**: [What needs documentation]
**Audience**: [Developers/Users/Stakeholders]

**Code/Context**:
[CODE_OR_CONTEXT]

Please include:
1. **Overview**: High-level description
2. **Purpose**: What does it do and why?
3. **Usage**: How to use it with examples
4. **Parameters/Arguments**: What inputs does it accept?
5. **Return values**: What does it return?
6. **Exceptions**: What errors can occur?
7. **Examples**: Real-world usage examples
8. **Notes**: Important considerations
```

---

## Example 1: API Documentation

### Input:
```
Please generate API documentation for:

**Type**: API Endpoint
**Component**: User Registration
**Audience**: Frontend developers

**Code**:
POST /api/v1/register
Content-Type: application/json

Body:
{
    "name": "string",
    "email": "string",
    "password": "string",
    "password_confirmation": "string"
}
```

### Expected Output:

## User Registration API

### Endpoint
```
POST /api/v1/register
```

### Description
Creates a new user account in the system. After successful registration, a welcome email is sent to the user's email address.

### Authentication
No authentication required (public endpoint).

### Request Headers
```
Content-Type: application/json
Accept: application/json
```

### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Full name of the user (max 255 characters) |
| `email` | string | Yes | Valid email address (must be unique) |
| `password` | string | Yes | Password (minimum 8 characters) |
| `password_confirmation` | string | Yes | Must match password field |

### Request Example
```json
{
    "name": "John Doe",
    "email": "john@example.com",
    "password": "SecurePass123!",
    "password_confirmation": "SecurePass123!"
}
```

### Success Response

**Status Code**: `201 Created`

```json
{
    "data": {
        "id": 1,
        "name": "John Doe",
        "email": "john@example.com",
        "email_verified_at": null,
        "created_at": "2025-10-28T10:30:00.000000Z",
        "updated_at": "2025-10-28T10:30:00.000000Z"
    },
    "meta": {
        "message": "Registration successful. Please check your email for verification."
    }
}
```

### Error Responses

#### Validation Error
**Status Code**: `422 Unprocessable Entity`

```json
{
    "message": "The given data was invalid.",
    "errors": {
        "email": [
            "The email has already been taken."
        ],
        "password": [
            "The password must be at least 8 characters."
        ]
    }
}
```

#### Server Error
**Status Code**: `500 Internal Server Error`

```json
{
    "message": "Server error occurred.",
    "error": "Internal server error"
}
```

### Rate Limiting
- **Limit**: 5 requests per minute per IP address
- **Header**: `X-RateLimit-Remaining` indicates remaining requests

### Side Effects
1. User account is created in the database
2. Welcome email is sent asynchronously
3. `UserCreated` event is dispatched
4. Default user settings are initialized

### Code Example (JavaScript/Axios)

```javascript
const axios = require('axios');

async function registerUser() {
    try {
        const response = await axios.post('https://api.example.com/api/v1/register', {
            name: 'John Doe',
            email: 'john@example.com',
            password: 'SecurePass123!',
            password_confirmation: 'SecurePass123!'
        });

        console.log('User registered:', response.data);
        return response.data;
    } catch (error) {
        if (error.response.status === 422) {
            console.error('Validation errors:', error.response.data.errors);
        }
        throw error;
    }
}
```

### Code Example (PHP/Guzzle)

```php
use GuzzleHttp\Client;

$client = new Client(['base_uri' => 'https://api.example.com']);

try {
    $response = $client->post('/api/v1/register', [
        'json' => [
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => 'SecurePass123!',
            'password_confirmation' => 'SecurePass123!',
        ]
    ]);

    $user = json_decode($response->getBody(), true);
    echo "User registered: " . $user['data']['id'];
} catch (\GuzzleHttp\Exception\ClientException $e) {
    $errors = json_decode($e->getResponse()->getBody(), true);
    print_r($errors);
}
```

### Notes
- Password is automatically hashed using bcrypt
- Email verification link is sent to the provided email
- User must verify email before accessing protected resources
- Duplicate email registrations are prevented

---

## Example 2: Class Documentation

### Input:
```
Please generate PHPDoc documentation for:

**Type**: Code Documentation
**Component**: OrderService class
**Audience**: Developers

**Code**:
class OrderService
{
    public function __construct(
        private readonly OrderRepository $orders,
        private readonly InventoryService $inventory,
        private readonly PaymentService $payments
    ) {}

    public function createOrder(User $user, array $items): Order
    {
        // Implementation
    }

    public function cancelOrder(Order $order): bool
    {
        // Implementation
    }
}
```

### Expected Output:

```php
<?php

namespace App\Services;

use App\Models\Order;
use App\Models\User;
use App\Repositories\OrderRepository;
use App\Services\InventoryService;
use App\Services\PaymentService;
use App\Exceptions\InsufficientInventoryException;
use App\Exceptions\PaymentFailedException;
use Illuminate\Support\Facades\DB;

/**
 * Service for managing order operations.
 *
 * This service handles the complete order lifecycle including creation,
 * payment processing, inventory management, and order cancellation.
 * All operations are wrapped in database transactions for data consistency.
 *
 * @package App\Services
 */
class OrderService
{
    /**
     * Create a new OrderService instance.
     *
     * @param  OrderRepository  $orders  Repository for order data access
     * @param  InventoryService  $inventory  Service for inventory management
     * @param  PaymentService  $payments  Service for payment processing
     */
    public function __construct(
        private readonly OrderRepository $orders,
        private readonly InventoryService $inventory,
        private readonly PaymentService $payments
    ) {}

    /**
     * Create a new order for the specified user.
     *
     * This method performs the following operations:
     * 1. Validates inventory availability for all items
     * 2. Creates the order record with pending status
     * 3. Reserves inventory for the order
     * 4. Dispatches OrderCreated event for side effects
     *
     * All operations are executed within a database transaction.
     * If any step fails, the entire process is rolled back.
     *
     * @param  User  $user  The user placing the order
     * @param  array  $items  Array of items with structure:
     *     [
     *         ['product_id' => 1, 'quantity' => 2, 'price' => 99.99],
     *         ['product_id' => 2, 'quantity' => 1, 'price' => 49.99],
     *     ]
     * @return Order  The newly created order instance
     *
     * @throws InsufficientInventoryException  If any item is out of stock
     * @throws \InvalidArgumentException  If items array is empty or invalid
     * @throws \Exception  If database transaction fails
     *
     * @example
     * ```php
     * $items = [
     *     ['product_id' => 1, 'quantity' => 2, 'price' => 99.99],
     *     ['product_id' => 2, 'quantity' => 1, 'price' => 49.99],
     * ];
     *
     * $order = $orderService->createOrder($user, $items);
     * echo "Order #{$order->id} created successfully";
     * ```
     */
    public function createOrder(User $user, array $items): Order
    {
        // Implementation
    }

    /**
     * Cancel an existing order.
     *
     * This method performs the following operations:
     * 1. Verifies order can be cancelled (not shipped/delivered)
     * 2. Processes refund if payment was completed
     * 3. Releases reserved inventory back to stock
     * 4. Updates order status to cancelled
     * 5. Dispatches OrderCancelled event
     *
     * All operations are executed within a database transaction.
     *
     * @param  Order  $order  The order to cancel
     * @return bool  True if cancellation was successful
     *
     * @throws \InvalidArgumentException  If order cannot be cancelled (wrong status)
     * @throws PaymentFailedException  If refund processing fails
     * @throws \Exception  If database transaction fails
     *
     * @example
     * ```php
     * if ($orderService->cancelOrder($order)) {
     *     echo "Order cancelled and refunded successfully";
     * }
     * ```
     */
    public function cancelOrder(Order $order): bool
    {
        // Implementation
    }
}
```

---

## Example 3: README Documentation

### Input:
```
Please generate README documentation for:

**Type**: Project README
**Component**: Laravel API Project
**Audience**: New developers

Include: Setup instructions, features, tech stack, API endpoints overview
```

### Expected Output:

```markdown
# E-Commerce API

A robust Laravel-based REST API for e-commerce operations including user management, product catalog, order processing, and payment integration.

## 🚀 Features

- **User Management**: Registration, authentication, profile management
- **Product Catalog**: Product listing, search, filtering, categories
- **Order Processing**: Cart management, checkout, order tracking
- **Payment Integration**: Stripe payment processing
- **Admin Panel**: Product and order management
- **Email Notifications**: Order confirmations, shipping updates
- **Real-time Updates**: WebSocket support for live notifications

## 📋 Requirements

- PHP >= 8.2
- Composer
- MySQL >= 8.0 or PostgreSQL >= 13
- Redis (for caching and queues)
- Node.js >= 18.x (for asset compilation)

## 🛠 Tech Stack

- **Framework**: Laravel 11.x
- **Database**: MySQL/PostgreSQL
- **Cache**: Redis
- **Queue**: Redis
- **Authentication**: Laravel Sanctum
- **Testing**: PHPUnit/Pest
- **Code Quality**: PHPStan, PHP CS Fixer

## 📦 Installation

### 1. Clone the repository

```bash
git clone https://github.com/your-username/ecommerce-api.git
cd ecommerce-api
```

### 2. Install dependencies

```bash
composer install
npm install
```

### 3. Environment setup

```bash
cp .env.example .env
php artisan key:generate
```

Edit `.env` and configure your database and other services:

```env
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=ecommerce
DB_USERNAME=root
DB_PASSWORD=

REDIS_HOST=127.0.0.1
REDIS_PORT=6379

MAIL_MAILER=smtp
MAIL_HOST=mailhog
MAIL_PORT=1025

STRIPE_KEY=your_stripe_key
STRIPE_SECRET=your_stripe_secret
```

### 4. Database setup

```bash
php artisan migrate
php artisan db:seed
```

### 5. Start development server

```bash
# Start Laravel server
php artisan serve

# Start queue worker (in another terminal)
php artisan queue:work

# Compile assets (in another terminal)
npm run dev
```

The API will be available at `http://localhost:8000`

## 🧪 Testing

Run tests with PHPUnit:

```bash
# Run all tests
php artisan test

# Run with coverage
php artisan test --coverage

# Run specific test
php artisan test --filter=UserRegistrationTest
```

## 📚 API Documentation

### Authentication

#### Register
```http
POST /api/v1/register
```

#### Login
```http
POST /api/v1/login
```

#### Logout
```http
POST /api/v1/logout
```

### Products

#### List Products
```http
GET /api/v1/products
```

#### Get Product
```http
GET /api/v1/products/{id}
```

### Orders

#### Create Order
```http
POST /api/v1/orders
```

#### Get Orders
```http
GET /api/v1/orders
```

Full API documentation available at `/api/documentation` when running locally.

## 🔧 Development

### Code Style

This project follows PSR-12 coding standards.

```bash
# Check code style
./vendor/bin/pint --test

# Fix code style
./vendor/bin/pint
```

### Static Analysis

```bash
# Run PHPStan
./vendor/bin/phpstan analyse
```

### Pre-commit Checks

```bash
# Run all checks
composer check
```

## 📁 Project Structure

```
app/
├── Actions/          # Single-purpose action classes
├── Http/
│   ├── Controllers/  # API controllers
│   ├── Requests/     # Form request validation
│   └── Resources/    # API resource transformers
├── Models/           # Eloquent models
├── Repositories/     # Data access layer
└── Services/         # Business logic services

tests/
├── Feature/          # Integration tests
└── Unit/             # Unit tests
```

## 🚀 Deployment

### Production Checklist

- [ ] Set `APP_ENV=production`
- [ ] Set `APP_DEBUG=false`
- [ ] Configure proper database credentials
- [ ] Set up Redis for cache and queues
- [ ] Configure email service (SendGrid, SES, etc.)
- [ ] Set up Stripe production keys
- [ ] Run migrations: `php artisan migrate --force`
- [ ] Cache configurations: `php artisan config:cache`
- [ ] Cache routes: `php artisan route:cache`
- [ ] Install dependencies: `composer install --no-dev --optimize-autoloader`
- [ ] Set up queue workers (Supervisor)
- [ ] Set up SSL certificate
- [ ] Configure CORS properly

## 📝 License

This project is licensed under the MIT License.

## 👥 Contributors

- John Doe - Initial work
- Jane Smith - Feature development

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📞 Support

For support, email support@example.com or join our Slack channel.
```

---

## Templates

### PHPDoc Method Template
```php
/**
 * Brief description of what the method does.
 *
 * Detailed explanation of the method's purpose, behavior,
 * and any important implementation details.
 *
 * @param  Type  $paramName  Description of parameter
 * @param  Type  $optional  Optional parameter description (default: value)
 * @return Type  Description of return value
 *
 * @throws ExceptionType  When this exception is thrown
 * @throws AnotherException  When this exception is thrown
 *
 * @example
 * ```php
 * $result = $object->method($param);
 * echo $result;
 * ```
 */
```

### Class PHPDoc Template
```php
/**
 * Brief description of the class.
 *
 * Detailed explanation of the class purpose, responsibilities,
 * and usage patterns.
 *
 * @package App\Services
 * @author Your Name <your.email@example.com>
 */
```

---

## Variations

### For Architecture Documentation
```
Document the architecture of this Laravel application including:
- System design
- Component interactions
- Data flow
- Technology stack
- Deployment architecture
```

### For User Guide
```
Create a user guide for [FEATURE] explaining:
- How to use it
- Step-by-step instructions
- Screenshots/examples
- Common issues and solutions
```

### For API Collection
```
Generate Postman/Insomnia collection documentation for all API endpoints in this controller.
```

---

## Related Prompts

- `code-explanation.md` - Understand before documenting
- `refactoring-suggestions.md` - Improve before documenting
- `testing-strategy.md` - Document testing approach
