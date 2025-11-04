# Code Review Checklist - Danh Sách Kiểm Tra Review Code

> Hướng dẫn chi tiết để review code hiệu quả và đảm bảo chất lượng
>
> **Mục đích**: Chuẩn hóa quy trình review code, phát hiện bugs sớm, cải thiện chất lượng code

---

## 📋 Mục Lục
- [Pre-Review Checklist](#pre-review-checklist)
- [Code Quality](#code-quality)
- [Architecture & Design](#architecture--design)
- [Security](#security)
- [Performance](#performance)
- [Testing](#testing)
- [Documentation](#documentation)
- [Common Code Smells](#common-code-smells)
- [Review Etiquette](#review-etiquette)

---

## 🔍 PRE-REVIEW CHECKLIST

### ✅ Trước khi submit code để review

**Author (Người viết code) phải đảm bảo:**

- [ ] **Code đã compile/build thành công**
  ```bash
  # Run build
  npm run build     # Node.js
  mvn clean install # Java
  dotnet build      # .NET
  ```

- [ ] **All tests pass**
  ```bash
  npm test          # Run all tests
  npm run test:coverage  # Check coverage
  ```

- [ ] **No linting errors**
  ```bash
  npm run lint      # ESLint
  pylint **/*.py    # Python
  ```

- [ ] **Code đã format theo convention**
  ```bash
  npm run format    # Prettier
  black .           # Python Black
  ```

- [ ] **Self-review code của chính mình**
  - Đọc lại mọi dòng code đã thay đổi
  - Xóa debug code, console.log, commented code
  - Kiểm tra có hard-coded values không cần thiết

- [ ] **Commit messages rõ ràng**
  ```bash
  # ❌ BAD
  git commit -m "fix bug"

  # ✅ GOOD - Conventional Commits
  git commit -m "fix(api): handle null pointer in user service"
  git commit -m "feat(auth): add JWT token refresh mechanism"
  ```

- [ ] **Pull Request description đầy đủ**
  ```markdown
  ## What
  Implement user authentication with JWT

  ## Why
  Current basic auth is not secure for production

  ## How
  - Added JWT token generation
  - Implemented refresh token mechanism
  - Added middleware for token validation

  ## Testing
  - Added unit tests for token generation
  - Added integration tests for auth flow

  ## Screenshots (if UI changes)
  [Attach screenshots]

  ## Related Issues
  Closes #123
  ```

- [ ] **Branch updated với latest main/develop**
  ```bash
  git fetch origin
  git rebase origin/main
  ```

- [ ] **No merge conflicts**

- [ ] **Scope reasonable** (không quá lớn)
  - Lý tưởng: < 400 lines changed
  - Tối đa: < 1000 lines changed
  - Nếu lớn hơn: chia thành nhiều PRs

---

## 💻 CODE QUALITY

### 1️⃣ Naming & Readability

- [ ] **Tên biến/hàm/class có ý nghĩa rõ ràng**
  ```javascript
  // ❌ BAD
  const d = new Date();
  function calc(a, b) { return a * b * 0.2; }

  // ✅ GOOD
  const currentDate = new Date();
  function calculateTaxAmount(price, quantity) {
      const TAX_RATE = 0.2;
      return price * quantity * TAX_RATE;
  }
  ```

- [ ] **Không dùng magic numbers**
  ```python
  # ❌ BAD
  if user.age > 18:
      allow_access()

  # ✅ GOOD
  LEGAL_AGE = 18
  if user.age > LEGAL_AGE:
      allow_access()
  ```

- [ ] **Functions nhỏ gọn, làm một việc**
  ```typescript
  // ❌ BAD - Function làm quá nhiều việc
  function processUserData(user: User) {
      validateUser(user);
      saveToDatabase(user);
      sendEmail(user);
      updateCache(user);
      logActivity(user);
  }

  // ✅ GOOD - Tách riêng
  function registerUser(user: User) {
      validateUser(user);
      saveUserToDatabase(user);
  }

  function notifyUserRegistration(user: User) {
      sendWelcomeEmail(user);
      logRegistrationActivity(user);
  }
  ```

- [ ] **Consistent naming convention**
  ```java
  // ✅ GOOD
  class UserService { }           // PascalCase for classes
  private String userName;        // camelCase for variables
  private static final int MAX_RETRIES = 3;  // UPPER_CASE for constants
  public void getUserById() { }   // camelCase for methods
  ```

### 2️⃣ Code Structure

- [ ] **Proper code organization**
  ```
  ✅ GOOD structure:
  src/
    ├── controllers/    # Request handlers
    ├── services/       # Business logic
    ├── repositories/   # Data access
    ├── models/         # Data models
    ├── utils/          # Utilities
    └── config/         # Configuration
  ```

- [ ] **Single Responsibility Principle**
  ```javascript
  // ❌ BAD
  class User {
      saveToDatabase() { }
      sendEmail() { }
      generatePDF() { }
      uploadToS3() { }
  }

  // ✅ GOOD
  class User { /* User data only */ }
  class UserRepository { saveToDatabase() { } }
  class EmailService { send() { } }
  class PDFGenerator { generate() { } }
  class StorageService { upload() { } }
  ```

- [ ] **DRY - Don't Repeat Yourself**
  ```python
  # ❌ BAD - Code duplication
  def calculate_order_total_for_vip(items):
      total = sum(item.price * item.quantity for item in items)
      tax = total * 0.1
      discount = total * 0.2
      return total + tax - discount

  def calculate_order_total_for_regular(items):
      total = sum(item.price * item.quantity for item in items)
      tax = total * 0.1
      discount = total * 0.05
      return total + tax - discount

  # ✅ GOOD - Extract common logic
  def calculate_order_total(items, discount_rate):
      subtotal = sum(item.price * item.quantity for item in items)
      tax = subtotal * 0.1
      discount = subtotal * discount_rate
      return subtotal + tax - discount

  def calculate_vip_order_total(items):
      return calculate_order_total(items, discount_rate=0.2)

  def calculate_regular_order_total(items):
      return calculate_order_total(items, discount_rate=0.05)
  ```

### 3️⃣ Error Handling

- [ ] **Proper error handling, không bỏ trống catch blocks**
  ```javascript
  // ❌ BAD
  try {
      await processPayment(order);
  } catch (error) {
      // Empty catch
  }

  // ✅ GOOD
  try {
      await processPayment(order);
  } catch (error) {
      logger.error('Payment processing failed', {
          orderId: order.id,
          error: error.message,
          stack: error.stack
      });
      throw new PaymentError('Failed to process payment', error);
  }
  ```

- [ ] **Validation đầu vào**
  ```typescript
  // ✅ GOOD
  function createUser(userData: UserData) {
      // Validate required fields
      if (!userData.email || !userData.password) {
          throw new ValidationError('Email and password are required');
      }

      // Validate email format
      if (!isValidEmail(userData.email)) {
          throw new ValidationError('Invalid email format');
      }

      // Validate password strength
      if (userData.password.length < 8) {
          throw new ValidationError('Password must be at least 8 characters');
      }

      // Process...
  }
  ```

- [ ] **Meaningful error messages**
  ```python
  # ❌ BAD
  raise Exception("Error")

  # ✅ GOOD
  raise UserNotFoundException(
      f"User with id {user_id} not found in database",
      user_id=user_id,
      timestamp=datetime.now()
  )
  ```

### 4️⃣ Comments & Documentation

- [ ] **Code tự giải thích, ít comments hơn**
  ```javascript
  // ❌ BAD - Unnecessary comment
  // Increment i by 1
  i++;

  // Loop through users
  for (let user of users) {
      // Process user
      processUser(user);
  }

  // ✅ GOOD - Self-explanatory code
  for (let activeUser of getActiveUsers()) {
      sendNotification(activeUser);
  }
  ```

- [ ] **Comments giải thích "WHY", không phải "WHAT"**
  ```java
  // ❌ BAD - Explains what (obvious)
  // Set user name to John
  user.setName("John");

  // ✅ GOOD - Explains why (useful)
  // Using exponential backoff to avoid overwhelming the external API
  // which has rate limiting of 100 requests per minute
  int delay = calculateExponentialBackoff(retryCount);
  Thread.sleep(delay);
  ```

- [ ] **TODO comments có owner và date**
  ```javascript
  // ❌ BAD
  // TODO: fix this

  // ✅ GOOD
  // TODO(@johndoe, 2025-11-01): Implement caching mechanism to improve
  // query performance. Current response time is 2s, target is < 500ms.
  // Related ticket: JIRA-123
  ```

- [ ] **No commented-out code**
  ```python
  # ❌ BAD - Delete instead of commenting
  # def old_implementation():
  #     # 50 lines of old code
  #     pass

  # ✅ GOOD - Use Git history if need to reference
  def new_implementation():
      # New code
      pass
  ```

---

## 🏗️ ARCHITECTURE & DESIGN

### 1️⃣ Design Patterns

- [ ] **Sử dụng design patterns phù hợp**
  ```typescript
  // ✅ GOOD - Strategy Pattern
  interface PaymentStrategy {
      pay(amount: number): Promise<void>;
  }

  class CreditCardPayment implements PaymentStrategy {
      async pay(amount: number) { /* implementation */ }
  }

  class PayPalPayment implements PaymentStrategy {
      async pay(amount: number) { /* implementation */ }
  }

  class PaymentProcessor {
      constructor(private strategy: PaymentStrategy) {}

      async processPayment(amount: number) {
          await this.strategy.pay(amount);
      }
  }
  ```

- [ ] **Dependency Injection**
  ```javascript
  // ❌ BAD - Hard dependency
  class UserService {
      constructor() {
          this.repository = new UserRepository();  // Tightly coupled
      }
  }

  // ✅ GOOD - Dependency Injection
  class UserService {
      constructor(repository) {
          this.repository = repository;  // Loose coupling
      }
  }

  // Usage
  const repository = new UserRepository();
  const service = new UserService(repository);
  ```

- [ ] **Interface segregation**
  ```java
  // ❌ BAD - Fat interface
  interface Worker {
      void work();
      void eat();
      void sleep();
  }

  // ✅ GOOD - Segregated interfaces
  interface Workable {
      void work();
  }

  interface Eatable {
      void eat();
  }

  interface Sleepable {
      void sleep();
  }
  ```

### 2️⃣ Coupling & Cohesion

- [ ] **Loose coupling giữa các modules**
  ```python
  # ❌ BAD - Tight coupling
  class OrderService:
      def create_order(self, order):
          # Direct dependency on specific implementations
          email_sender = GmailSender()
          email_sender.send(order.customer.email)

  # ✅ GOOD - Loose coupling
  class OrderService:
      def __init__(self, email_service):
          self.email_service = email_service

      def create_order(self, order):
          self.email_service.send_order_confirmation(order)
  ```

- [ ] **High cohesion trong modules**
  ```javascript
  // ✅ GOOD - High cohesion: All methods work with user data
  class UserProfile {
      constructor(user) { this.user = user; }

      getFullName() { return `${this.user.firstName} ${this.user.lastName}`; }
      getAge() { return calculateAge(this.user.birthDate); }
      isAdult() { return this.getAge() >= 18; }
  }
  ```

### 3️⃣ SOLID Principles

- [ ] **Single Responsibility**
  ```typescript
  // ❌ BAD - Multiple responsibilities
  class User {
      saveToDatabase() { }
      sendEmail() { }
      generateReport() { }
  }

  // ✅ GOOD - Single responsibility
  class User { /* Data only */ }
  class UserRepository { save() { } }
  class EmailService { send() { } }
  class ReportGenerator { generate() { } }
  ```

- [ ] **Open/Closed Principle**
  ```javascript
  // ✅ GOOD - Open for extension, closed for modification
  class Shape {
      area() { throw new Error('Must implement'); }
  }

  class Circle extends Shape {
      constructor(radius) { super(); this.radius = radius; }
      area() { return Math.PI * this.radius ** 2; }
  }

  class Rectangle extends Shape {
      constructor(width, height) {
          super();
          this.width = width;
          this.height = height;
      }
      area() { return this.width * this.height; }
  }
  ```

---

## 🔐 SECURITY

### 1️⃣ Input Validation & Sanitization

- [ ] **Validate all user inputs**
  ```javascript
  // ✅ GOOD
  function createUser(req, res) {
      const { email, password, age } = req.body;

      // Validate email
      if (!validator.isEmail(email)) {
          return res.status(400).json({ error: 'Invalid email format' });
      }

      // Validate password strength
      if (!validator.isStrongPassword(password)) {
          return res.status(400).json({ error: 'Weak password' });
      }

      // Validate age
      if (!Number.isInteger(age) || age < 0 || age > 150) {
          return res.status(400).json({ error: 'Invalid age' });
      }

      // Sanitize inputs
      const sanitizedEmail = validator.normalizeEmail(email);

      // Process...
  }
  ```

- [ ] **Prevent SQL Injection**
  ```python
  # ❌ BAD - SQL Injection vulnerability
  def get_user(user_id):
      query = f"SELECT * FROM users WHERE id = {user_id}"
      return db.execute(query)

  # ✅ GOOD - Parameterized query
  def get_user(user_id):
      query = "SELECT * FROM users WHERE id = ?"
      return db.execute(query, [user_id])

  # ✅ GOOD - ORM
  def get_user(user_id):
      return User.query.filter_by(id=user_id).first()
  ```

- [ ] **Prevent XSS attacks**
  ```javascript
  // ❌ BAD - XSS vulnerability
  element.innerHTML = userInput;

  // ✅ GOOD - Sanitize HTML
  import DOMPurify from 'dompurify';
  element.innerHTML = DOMPurify.sanitize(userInput);

  // ✅ BETTER - Use textContent for plain text
  element.textContent = userInput;
  ```

### 2️⃣ Authentication & Authorization

- [ ] **Không hardcode credentials**
  ```javascript
  // ❌ BAD
  const API_KEY = 'sk-1234567890abcdef';
  const DB_PASSWORD = 'password123';

  // ✅ GOOD - Use environment variables
  const API_KEY = process.env.API_KEY;
  const DB_PASSWORD = process.env.DB_PASSWORD;
  ```

- [ ] **Password security**
  ```python
  # ❌ BAD - Plain text password
  user.password = request.form['password']

  # ✅ GOOD - Hash password
  import bcrypt

  password_hash = bcrypt.hashpw(
      request.form['password'].encode('utf-8'),
      bcrypt.gensalt()
  )
  user.password_hash = password_hash
  ```

- [ ] **Proper authorization checks**
  ```typescript
  // ✅ GOOD
  async function deleteUser(userId: string, requestingUser: User) {
      // Check if user is authenticated
      if (!requestingUser) {
          throw new UnauthorizedError('Authentication required');
      }

      // Check if user has permission
      if (!requestingUser.isAdmin() && requestingUser.id !== userId) {
          throw new ForbiddenError('Insufficient permissions');
      }

      // Proceed with deletion
      await userRepository.delete(userId);
  }
  ```

### 3️⃣ Data Protection

- [ ] **Không log sensitive data**
  ```javascript
  // ❌ BAD
  console.log('User login:', {
      email: user.email,
      password: user.password,  // Never log passwords!
      creditCard: user.creditCard
  });

  // ✅ GOOD
  logger.info('User login', {
      userId: user.id,
      email: maskEmail(user.email)  // user@example.com -> u***@example.com
  });
  ```

- [ ] **HTTPS only cho sensitive data**
  ```javascript
  // ✅ GOOD
  app.use((req, res, next) => {
      if (!req.secure && process.env.NODE_ENV === 'production') {
          return res.redirect('https://' + req.headers.host + req.url);
      }
      next();
  });
  ```

---

## ⚡ PERFORMANCE

### 1️⃣ Algorithm Efficiency

- [ ] **Kiểm tra time complexity**
  ```javascript
  // ❌ BAD - O(n²)
  function findDuplicates(arr) {
      const duplicates = [];
      for (let i = 0; i < arr.length; i++) {
          for (let j = i + 1; j < arr.length; j++) {
              if (arr[i] === arr[j]) {
                  duplicates.push(arr[i]);
              }
          }
      }
      return duplicates;
  }

  // ✅ GOOD - O(n)
  function findDuplicates(arr) {
      const seen = new Set();
      const duplicates = new Set();

      for (const item of arr) {
          if (seen.has(item)) {
              duplicates.add(item);
          }
          seen.add(item);
      }

      return Array.from(duplicates);
  }
  ```

- [ ] **Tránh nested loops không cần thiết**
  ```python
  # ❌ BAD - O(n * m)
  def find_common_elements(list1, list2):
      common = []
      for item1 in list1:
          for item2 in list2:
              if item1 == item2:
                  common.append(item1)
      return common

  # ✅ GOOD - O(n + m)
  def find_common_elements(list1, list2):
      return list(set(list1) & set(list2))
  ```

### 2️⃣ Database Queries

- [ ] **Tránh N+1 query problem**
  ```javascript
  // ❌ BAD - N+1 queries
  const users = await User.findAll();
  for (const user of users) {
      user.posts = await Post.findAll({ where: { userId: user.id } });
  }

  // ✅ GOOD - Single query with join
  const users = await User.findAll({
      include: [{ model: Post }]
  });
  ```

- [ ] **Use pagination cho large datasets**
  ```python
  # ✅ GOOD
  def get_users(page=1, page_size=20):
      offset = (page - 1) * page_size
      users = User.query.limit(page_size).offset(offset).all()
      total = User.query.count()

      return {
          'users': users,
          'page': page,
          'page_size': page_size,
          'total': total,
          'total_pages': (total + page_size - 1) // page_size
      }
  ```

- [ ] **Proper indexing**
  ```sql
  -- ✅ GOOD - Add index for frequently queried columns
  CREATE INDEX idx_users_email ON users(email);
  CREATE INDEX idx_orders_user_id ON orders(user_id);
  CREATE INDEX idx_products_category_id ON products(category_id);
  ```

### 3️⃣ Caching

- [ ] **Cache expensive operations**
  ```typescript
  // ✅ GOOD - Cache với TTL
  import NodeCache from 'node-cache';
  const cache = new NodeCache({ stdTTL: 600 }); // 10 minutes

  async function getProductDetails(productId: string) {
      // Check cache first
      const cached = cache.get(productId);
      if (cached) {
          return cached;
      }

      // Fetch from database
      const product = await db.products.findById(productId);

      // Store in cache
      cache.set(productId, product);

      return product;
  }
  ```

### 4️⃣ Memory Management

- [ ] **Tránh memory leaks**
  ```javascript
  // ❌ BAD - Memory leak
  let cache = {};
  function addToCache(key, value) {
      cache[key] = value;  // Never cleaned up!
  }

  // ✅ GOOD - Use Map with size limit
  class LRUCache {
      constructor(maxSize = 100) {
          this.cache = new Map();
          this.maxSize = maxSize;
      }

      set(key, value) {
          if (this.cache.size >= this.maxSize) {
              const firstKey = this.cache.keys().next().value;
              this.cache.delete(firstKey);
          }
          this.cache.set(key, value);
      }
  }
  ```

---

## 🧪 TESTING

### 1️⃣ Test Coverage

- [ ] **Unit tests cho business logic**
  ```javascript
  // ✅ GOOD
  describe('calculateDiscount', () => {
      it('should apply 10% discount for regular users', () => {
          const result = calculateDiscount(100, 'regular');
          expect(result).toBe(90);
      });

      it('should apply 20% discount for VIP users', () => {
          const result = calculateDiscount(100, 'vip');
          expect(result).toBe(80);
      });

      it('should throw error for invalid user type', () => {
          expect(() => calculateDiscount(100, 'invalid'))
              .toThrow('Invalid user type');
      });
  });
  ```

- [ ] **Test edge cases**
  ```python
  def test_divide():
      # Normal case
      assert divide(10, 2) == 5

      # Edge cases
      assert divide(0, 5) == 0
      assert divide(10, 1) == 10

      # Error cases
      with pytest.raises(ZeroDivisionError):
          divide(10, 0)

      # Negative numbers
      assert divide(-10, 2) == -5
      assert divide(10, -2) == -5
  ```

### 2️⃣ Test Quality

- [ ] **Tests có thể đọc được**
  ```typescript
  // ✅ GOOD - Given-When-Then pattern
  it('should send welcome email when user registers', async () => {
      // Given
      const userData = {
          email: 'test@example.com',
          name: 'Test User'
      };
      const emailService = mock<EmailService>();

      // When
      await registerUser(userData, emailService);

      // Then
      expect(emailService.sendWelcomeEmail)
          .toHaveBeenCalledWith(userData.email, userData.name);
  });
  ```

- [ ] **Không test implementation details**
  ```javascript
  // ❌ BAD - Testing internal implementation
  it('should call processPayment internally', () => {
      const spy = jest.spyOn(service, 'processPayment');
      service.checkout(order);
      expect(spy).toHaveBeenCalled();
  });

  // ✅ GOOD - Test behavior
  it('should mark order as paid after successful checkout', async () => {
      const order = await service.checkout(orderData);
      expect(order.status).toBe('paid');
  });
  ```

### 3️⃣ Test Maintenance

- [ ] **Tests độc lập với nhau**
  ```python
  # ✅ GOOD - Each test is independent
  def test_create_user():
      user = User.create(name="John")
      assert user.name == "John"

  def test_update_user():
      user = User.create(name="John")  # Create fresh user
      user.update(name="Jane")
      assert user.name == "Jane"
  ```

- [ ] **Use test fixtures/factories**
  ```javascript
  // ✅ GOOD - Reusable test data
  function createTestUser(overrides = {}) {
      return {
          id: '123',
          email: 'test@example.com',
          name: 'Test User',
          age: 25,
          ...overrides
      };
  }

  it('should validate adult user', () => {
      const user = createTestUser({ age: 20 });
      expect(isAdult(user)).toBe(true);
  });
  ```

---

## 📚 DOCUMENTATION

- [ ] **README cập nhật**
  - Setup instructions
  - Environment variables
  - How to run
  - How to test

- [ ] **API documentation**
  ```javascript
  /**
   * Create a new user account
   *
   * @param {Object} userData - User registration data
   * @param {string} userData.email - User email address
   * @param {string} userData.password - User password (min 8 chars)
   * @param {string} userData.name - User full name
   * @returns {Promise<User>} Created user object
   * @throws {ValidationError} If validation fails
   * @throws {DuplicateEmailError} If email already exists
   *
   * @example
   * const user = await createUser({
   *   email: 'john@example.com',
   *   password: 'SecurePass123',
   *   name: 'John Doe'
   * });
   */
  async function createUser(userData) {
      // Implementation
  }
  ```

- [ ] **Complex logic có comments**
  ```python
  def calculate_shipping_cost(weight, distance, express=False):
      """
      Calculate shipping cost based on package weight and distance.

      Formula: base_rate * weight * distance_factor * speed_multiplier

      Args:
          weight (float): Package weight in kg
          distance (int): Distance in km
          express (bool): Whether express shipping is requested

      Returns:
          float: Shipping cost in USD

      Example:
          >>> calculate_shipping_cost(2.5, 100)
          15.75
          >>> calculate_shipping_cost(2.5, 100, express=True)
          31.50
      """
      # Implementation
  ```

---

## 🚨 COMMON CODE SMELLS

### ❌ Cần refactor nếu thấy:

1. **Long Method** (hàm > 20 dòng)
2. **Large Class** (class > 200 dòng)
3. **Long Parameter List** (> 3 parameters)
4. **Duplicated Code**
5. **Dead Code** (code không được sử dụng)
6. **Speculative Generality** (code "phòng hờ" cho tương lai)
7. **Feature Envy** (method sử dụng quá nhiều data từ class khác)
8. **Data Clumps** (nhóm data luôn xuất hiện cùng nhau)
9. **Primitive Obsession** (dùng primitives thay vì objects)
10. **Switch Statements** (có thể thay bằng polymorphism)

### Ví dụ refactoring:

```javascript
// ❌ CODE SMELL: Long Parameter List
function createOrder(userId, productId, quantity, price,
                     shippingAddress, billingAddress,
                     paymentMethod, couponCode) {
    // ...
}

// ✅ REFACTORED: Parameter Object
function createOrder(orderData) {
    const {
        userId, productId, quantity, price,
        shippingAddress, billingAddress,
        paymentMethod, couponCode
    } = orderData;
    // ...
}
```

---

## 🤝 REVIEW ETIQUETTE

### ✅ Cho Reviewer:

- **Be kind and respectful**
  ```
  ❌ "This code is terrible"
  ✅ "Consider refactoring this method to improve readability"
  ```

- **Explain WHY, not just WHAT**
  ```
  ❌ "Change this"
  ✅ "This could cause a memory leak because the event listener
      is never removed. Consider adding cleanup in useEffect."
  ```

- **Suggest, don't command**
  ```
  ❌ "You must use async/await here"
  ✅ "What do you think about using async/await here?
      It would make the error handling clearer."
  ```

- **Distinguish between must-fix và nice-to-have**
  ```
  🔴 BLOCKER: This SQL injection vulnerability must be fixed
  🟡 SUGGESTION: Consider extracting this to a separate function
  💡 NIT: Minor typo in variable name
  ```

- **Praise good code**
  ```
  ✅ "Nice use of the Strategy pattern here!"
  ✅ "Great test coverage on edge cases!"
  ```

### ✅ Cho Author:

- **Không defensive**
  ```
  ❌ "You don't understand the context"
  ✅ "Thanks for the feedback. Let me explain the context..."
  ```

- **Ask for clarification**
  ```
  ✅ "Could you elaborate on why this approach is better?"
  ✅ "I'm not sure I understand the concern. Could you provide an example?"
  ```

- **Be open to learning**
  ```
  ✅ "I didn't know about that pattern. Thanks for teaching me!"
  ✅ "Good catch! I'll fix that."
  ```

---

## 📊 REVIEW CHECKLIST SUMMARY

### 🔴 MUST FIX (Blocker)

- [ ] Security vulnerabilities
- [ ] Data loss risks
- [ ] Breaking changes without migration
- [ ] Performance issues (N+1 queries, memory leaks)
- [ ] Test failures
- [ ] Build/compilation errors

### 🟡 SHOULD FIX (Important)

- [ ] Code quality issues
- [ ] Missing error handling
- [ ] Poor naming
- [ ] Missing tests
- [ ] Incomplete documentation
- [ ] Code duplication

### 💡 NICE TO HAVE (Suggestion)

- [ ] Minor refactoring
- [ ] Code style improvements
- [ ] Additional test cases
- [ ] Performance optimizations

---

## 🎯 REVIEW TIMELINE

- **Small PR (< 200 lines)**: Review trong 2-4 giờ
- **Medium PR (200-500 lines)**: Review trong 1 ngày
- **Large PR (> 500 lines)**: Chia nhỏ hoặc review trong 2-3 ngày

---

## 📖 REFERENCES

- [Google Engineering Practices - Code Review](https://google.github.io/eng-practices/review/)
- [Conventional Comments](https://conventionalcomments.org/)
- [Code Review Best Practices](https://www.michaelagreiler.com/code-review-best-practices/)

---

*Document Version: 1.0*
*Last Updated: 2025-11-01*
