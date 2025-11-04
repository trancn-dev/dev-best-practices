# Clean Code Rules - Quy Tắc Code Sạch

> Tài liệu tham khảo từ cuốn "Clean Code" của Robert C. Martin
>
> Mục đích: Hướng dẫn viết code rõ ràng, dễ đọc, dễ bảo trì

---

## 📋 Mục Lục
- [Quy Tắc Đặt Tên](#quy-tắc-đặt-tên)
- [Quy Tắc Về Hàm (Functions)](#quy-tắc-về-hàm-functions)
- [Quy Tắc Về Comments](#quy-tắc-về-comments)
- [Quy Tắc Formatting](#quy-tắc-formatting)
- [Quy Tắc Về Objects và Data Structures](#quy-tắc-về-objects-và-data-structures)
- [Xử Lý Lỗi (Error Handling)](#xử-lý-lỗi-error-handling)
- [Quy Tắc Về Unit Tests](#quy-tắc-về-unit-tests)
- [Quy Tắc Về Classes](#quy-tắc-về-classes)

---

## 🏷️ Quy Tắc Đặt Tên

### ✅ PHẢI LÀM

1. **Sử dụng tên có ý nghĩa và dễ hiểu**
   ```javascript
   // ❌ BAD
   let d; // elapsed time in days

   // ✅ GOOD
   let elapsedTimeInDays;
   let daysSinceCreation;
   ```

2. **Tên phải thể hiện mục đích rõ ràng**
   ```python
   # ❌ BAD
   def get_data():
       pass

   # ✅ GOOD
   def getUserProfileFromDatabase():
       pass
   ```

3. **Tránh thông tin sai lệch**
   ```javascript
   // ❌ BAD - accountList không phải List mà là Object
   let accountList = {};

   // ✅ GOOD
   let accountMap = {};
   let accounts = {};
   ```

4. **Tạo sự khác biệt rõ ràng**
   ```java
   // ❌ BAD - Khó phân biệt
   getActiveAccount();
   getActiveAccounts();
   getActiveAccountInfo();

   // ✅ GOOD
   getActiveAccount();
   getAllActiveAccounts();
   getActiveAccountDetails();
   ```

5. **Sử dụng tên có thể phát âm được**
   ```typescript
   // ❌ BAD
   const genymdhms = new Date();

   // ✅ GOOD
   const generationTimestamp = new Date();
   ```

6. **Sử dụng tên có thể tìm kiếm được**
   ```javascript
   // ❌ BAD
   setTimeout(blastOff, 86400000);

   // ✅ GOOD
   const MILLISECONDS_PER_DAY = 86400000;
   setTimeout(blastOff, MILLISECONDS_PER_DAY);
   ```

### 🚫 KHÔNG NÊN LÀM

- ❌ Không dùng ký tự đơn (trừ biến đếm trong vòng lặp ngắn)
- ❌ Không dùng mã hóa kiểu Hungarian notation
- ❌ Không dùng prefix cho member variables (m_)
- ❌ Không dùng tên quá chung chung: `data`, `info`, `item`

---

## 🔧 Quy Tắc Về Hàm (Functions)

### ✅ NGUYÊN TẮC CHÍNH

1. **Hàm phải nhỏ gọn**
   - Lý tưởng: 4-5 dòng
   - Tối đa: 20 dòng
   ```javascript
   // ❌ BAD - Hàm quá dài
   function processUserData(user) {
       // 100 dòng code ở đây...
   }

   // ✅ GOOD - Tách thành nhiều hàm nhỏ
   function processUserData(user) {
       validateUser(user);
       const normalizedData = normalizeUserData(user);
       saveToDatabase(normalizedData);
   }
   ```

2. **Mỗi hàm chỉ làm MỘT việc**
   ```python
   # ❌ BAD
   def save_and_send_email(user):
       save_user(user)
       send_email(user.email)

   # ✅ GOOD
   def save_user(user):
       # save logic

   def send_welcome_email(user):
       # email logic
   ```

3. **Một mức độ trừu tượng cho mỗi hàm**
   ```javascript
   // ❌ BAD - Trộn lẫn các mức độ trừu tượng
   function renderPage() {
       const html = "<div>...</div>";  // Low level
       authenticateUser();              // High level
       db.query("SELECT * FROM...");    // Medium level
   }

   // ✅ GOOD
   function renderPage() {
       authenticateUser();
       const content = getPageContent();
       displayContent(content);
   }
   ```

4. **Số lượng tham số**
   - Lý tưởng: 0 tham số
   - Tốt: 1-2 tham số
   - Tránh: 3+ tham số
   ```typescript
   // ❌ BAD
   function createUser(name: string, age: number, email: string,
                      address: string, phone: string) {
   }

   // ✅ GOOD
   interface UserData {
       name: string;
       age: number;
       email: string;
       address: string;
       phone: string;
   }

   function createUser(userData: UserData) {
   }
   ```

5. **Tránh flag arguments**
   ```javascript
   // ❌ BAD
   function book(isPremium) {
       if (isPremium) {
           bookPremium();
       } else {
           bookRegular();
       }
   }

   // ✅ GOOD
   function bookPremium() { }
   function bookRegular() { }
   ```

6. **Không có side effects**
   ```python
   # ❌ BAD
   def check_password(username, password):
       if valid_password(username, password):
           Session.initialize()  # Side effect!
           return True
       return False

   # ✅ GOOD
   def check_password(username, password):
       return valid_password(username, password)

   def login(username, password):
       if check_password(username, password):
           Session.initialize()
           return True
       return False
   ```

7. **Command Query Separation**
   ```javascript
   // ❌ BAD - Vừa query vừa command
   function set(attribute, value) {
       if (attributeExists(attribute)) {
           setAttribute(attribute, value);
           return true;
       }
       return false;
   }

   // ✅ GOOD - Tách riêng
   function attributeExists(attribute) { }
   function setAttribute(attribute, value) { }
   ```

### 🎯 CẤU TRÚC HÀM TỐT

```javascript
// ✅ GOOD EXAMPLE
function calculateMonthlyPayment(loanAmount, interestRate, loanTermYears) {
    validateInputs(loanAmount, interestRate, loanTermYears);

    const monthlyRate = convertToMonthlyRate(interestRate);
    const numberOfPayments = calculateNumberOfPayments(loanTermYears);

    return computePayment(loanAmount, monthlyRate, numberOfPayments);
}
```

---

## 💬 Quy Tắc Về Comments

### ✅ COMMENTS TỐT

1. **Legal Comments** (bắt buộc)
   ```javascript
   // Copyright (C) 2025 Company Name
   // Licensed under MIT
   ```

2. **Giải thích ý định**
   ```python
   # We are using binary search here because the dataset
   # can contain millions of records and needs O(log n) performance
   def find_user(user_id):
       return binary_search(users, user_id)
   ```

3. **Làm rõ code phức tạp**
   ```javascript
   // Format: "YYYY-MM-DD HH:mm:ss"
   const timestamp = date.toISOString().slice(0, 19).replace('T', ' ');
   ```

4. **Cảnh báo về hậu quả**
   ```java
   // WARNING: This test takes 10 minutes to run
   @Test
   public void testWithRealDatabase() {
   }
   ```

5. **TODO comments**
   ```typescript
   // TODO: Implement caching mechanism to improve performance
   function fetchUserData(userId: string) {
   }
   ```

### 🚫 COMMENTS XẤU

1. **Comments thừa**
   ```javascript
   // ❌ BAD
   // Increment i by 1
   i++;

   // ❌ BAD
   // Default constructor
   constructor() {
   }
   ```

2. **Comments sai lệch (misleading)**
   ```python
   # ❌ BAD - Comment nói một đằng, code làm một nẻo
   # Return the user's full name
   def get_user():
       return user.email  # Actually returns email!
   ```

3. **Comments dư thừa**
   ```java
   // ❌ BAD
   /**
    * Gets the name
    * @return the name
    */
   public String getName() {
       return name;
   }
   ```

4. **Commented-out code**
   ```javascript
   // ❌ BAD - Xóa đi thay vì comment!
   // function oldImplementation() {
   //     // 50 lines of old code...
   // }

   function newImplementation() {
   }
   ```

### 💡 NGUYÊN TẮC VÀNG

> **Code tốt là tài liệu tốt nhất. Khi bạn cần viết comment, hãy tự hỏi: "Làm sao để code tự giải thích được?"**

---

## 📐 Quy Tắc Formatting

### ✅ NGUYÊN TẮC

1. **Vertical Formatting**
   - File nên ngắn (200-500 dòng lý tưởng)
   - Concepts liên quan gần nhau
   ```javascript
   // ✅ GOOD - Nhóm các khái niệm liên quan
   const userName = getUserName();
   const userEmail = getUserEmail();
   const userAge = getUserAge();

   // Dòng trống để tách khái niệm khác
   const productName = getProductName();
   const productPrice = getProductPrice();
   ```

2. **Vertical Distance**
   - Variables: khai báo gần nơi sử dụng
   - Functions: caller trên, callee dưới
   ```python
   # ✅ GOOD
   def process_order():
       order = get_order()        # Dùng ngay
       validate_order(order)      # Caller

   def validate_order(order):     # Callee ở dưới
       pass
   ```

3. **Horizontal Formatting**
   - Giới hạn 80-120 ký tự mỗi dòng
   - Sử dụng khoảng trắng hợp lý
   ```javascript
   // ✅ GOOD
   const result = (a + b) * (c - d);

   function calculateTotal(price, quantity, discount) {
       return price * quantity - discount;
   }
   ```

4. **Indentation**
   - Sử dụng nhất quán (2 hoặc 4 spaces)
   - Không phá vỡ indentation
   ```typescript
   // ✅ GOOD
   class User {
       constructor(name: string) {
           this.name = name;
       }

       getName(): string {
           return this.name;
       }
   }
   ```

### 📏 TEAM RULES

> Team phải thống nhất một style guide và tuân theo nghiêm ngặt. Sử dụng tools như:
> - ESLint, Prettier (JavaScript/TypeScript)
> - Black, pylint (Python)
> - RuboCop (Ruby)
> - Google Java Format (Java)

---

## 🗂️ Quy Tắc Về Objects và Data Structures

### ✅ NGUYÊN TẮC

1. **Data Abstraction**
   ```javascript
   // ❌ BAD - Concrete implementation exposed
   class Point {
       public x;
       public y;
   }

   // ✅ GOOD - Abstract interface
   class Point {
       getX() { }
       getY() { }
       setCartesian(x, y) { }
   }
   ```

2. **Law of Demeter**
   > Một module không nên biết về internal details của objects nó thao tác

   ```python
   # ❌ BAD - Train wreck
   output_dir = ctxt.getOptions().getScratchDir().getAbsolutePath()

   # ✅ GOOD
   output_dir = ctxt.getScratchDirectoryPath()
   ```

3. **Data Transfer Objects (DTOs)**
   ```typescript
   // ✅ GOOD - DTO cho API response
   interface UserDTO {
       id: string;
       name: string;
       email: string;
   }

   class User {
       constructor(
           private id: string,
           private name: string,
           private email: string,
           private passwordHash: string  // Không expose trong DTO
       ) {}

       toDTO(): UserDTO {
           return {
               id: this.id,
               name: this.name,
               email: this.email
           };
       }
   }
   ```

---

## ⚠️ Xử Lý Lỗi (Error Handling)

### ✅ NGUYÊN TẮC

1. **Sử dụng Exceptions thay vì Error Codes**
   ```java
   // ❌ BAD
   public int deleteUser(User user) {
       if (userExists(user)) {
           delete(user);
           return 0;
       }
       return -1;  // Error code
   }

   // ✅ GOOD
   public void deleteUser(User user) throws UserNotFoundException {
       if (!userExists(user)) {
           throw new UserNotFoundException(user.id);
       }
       delete(user);
   }
   ```

2. **Viết Try-Catch-Finally trước**
   ```python
   # ✅ GOOD
   def load_config(filename):
       try:
           with open(filename) as f:
               return json.load(f)
       except FileNotFoundError:
           logger.error(f"Config file not found: {filename}")
           return default_config()
       except json.JSONDecodeError:
           logger.error(f"Invalid JSON in config: {filename}")
           return default_config()
   ```

3. **Cung cấp context với exceptions**
   ```javascript
   // ✅ GOOD
   class PaymentError extends Error {
       constructor(message, amount, userId) {
           super(message);
           this.amount = amount;
           this.userId = userId;
           this.timestamp = new Date();
       }
   }

   throw new PaymentError(
       'Payment failed',
       amount,
       user.id
   );
   ```

4. **Không return null**
   ```typescript
   // ❌ BAD
   function getUsers(): User[] | null {
       if (noUsers) return null;
       return users;
   }

   // ✅ GOOD
   function getUsers(): User[] {
       if (noUsers) return [];
       return users;
   }
   ```

5. **Không pass null**
   ```java
   // ❌ BAD
   public void calculate(Integer a, Integer b) {
       int result = a + b;  // NullPointerException nếu a hoặc b null
   }

   // ✅ GOOD
   public void calculate(int a, int b) {
       // Hoặc validate
   }

   public void calculate(Integer a, Integer b) {
       if (a == null || b == null) {
           throw new IllegalArgumentException("Parameters cannot be null");
       }
       int result = a + b;
   }
   ```

---

## 🧪 Quy Tắc Về Unit Tests

### ✅ THREE LAWS OF TDD

1. **First Law**: Không viết production code cho đến khi có failing unit test
2. **Second Law**: Chỉ viết đủ unit test để fail (không compile cũng là fail)
3. **Third Law**: Chỉ viết đủ production code để pass test hiện tại

### ✅ CLEAN TESTS - F.I.R.S.T

1. **Fast** - Tests phải chạy nhanh
2. **Independent** - Tests không phụ thuộc lẫn nhau
3. **Repeatable** - Tests chạy được ở mọi môi trường
4. **Self-Validating** - Tests có kết quả boolean rõ ràng
5. **Timely** - Tests viết trước hoặc cùng lúc với production code

### ✅ NGUYÊN TẮC

1. **One Assert Per Test** (lý tưởng)
   ```javascript
   // ✅ GOOD
   test('should return user name', () => {
       const user = new User('John');
       expect(user.getName()).toBe('John');
   });

   test('should return user email', () => {
       const user = new User('John', 'john@example.com');
       expect(user.getEmail()).toBe('john@example.com');
   });
   ```

2. **Sử dụng Given-When-Then**
   ```python
   def test_user_registration():
       # Given
       username = "testuser"
       email = "test@example.com"

       # When
       user = register_user(username, email)

       # Then
       assert user.username == username
       assert user.email == email
       assert user.is_active == True
   ```

3. **Test Clean Code**
   ```typescript
   // ✅ GOOD - Test code cũng phải clean
   describe('UserService', () => {
       let userService: UserService;
       let mockRepository: MockRepository;

       beforeEach(() => {
           mockRepository = createMockRepository();
           userService = new UserService(mockRepository);
       });

       it('should create user with valid data', async () => {
           const userData = createValidUserData();

           const result = await userService.createUser(userData);

           expect(result).toBeDefined();
           expect(mockRepository.save).toHaveBeenCalledWith(userData);
       });
   });
   ```

---

## 🏛️ Quy Tắc Về Classes

### ✅ NGUYÊN TẮC

1. **Organization**
   ```java
   // ✅ GOOD - Thứ tự trong class
   public class User {
       // 1. Constants
       private static final int MAX_NAME_LENGTH = 100;

       // 2. Static variables
       private static int userCount = 0;

       // 3. Instance variables
       private String name;
       private String email;

       // 4. Constructors
       public User(String name, String email) {
           this.name = name;
           this.email = email;
       }

       // 5. Public methods
       public String getName() {
           return name;
       }

       // 6. Private methods
       private void validateName(String name) {
           // validation logic
       }
   }
   ```

2. **Classes Should Be Small**
   - Đo bằng số lượng responsibilities
   - Single Responsibility Principle (SRP)
   ```javascript
   // ❌ BAD - Too many responsibilities
   class User {
       saveToDatabase() { }
       sendEmail() { }
       generateReport() { }
       validateData() { }
   }

   // ✅ GOOD - Single responsibility
   class User {
       constructor(name, email) { }
       getName() { }
       getEmail() { }
   }

   class UserRepository {
       save(user) { }
   }

   class EmailService {
       send(user) { }
   }
   ```

3. **Cohesion**
   - Methods nên sử dụng nhiều instance variables
   - High cohesion = good
   ```python
   # ✅ GOOD - High cohesion
   class Stack:
       def __init__(self):
           self.elements = []  # Used by all methods

       def push(self, element):
           self.elements.append(element)

       def pop(self):
           return self.elements.pop()

       def size(self):
           return len(self.elements)
   ```

4. **Open-Closed Principle**
   > Open for extension, closed for modification

   ```typescript
   // ✅ GOOD
   interface Shape {
       area(): number;
   }

   class Circle implements Shape {
       constructor(private radius: number) {}

       area(): number {
           return Math.PI * this.radius ** 2;
       }
   }

   class Rectangle implements Shape {
       constructor(private width: number, private height: number) {}

       area(): number {
           return this.width * this.height;
       }
   }

   // Thêm shape mới không cần sửa code cũ
   class Triangle implements Shape {
       constructor(private base: number, private height: number) {}

       area(): number {
           return 0.5 * this.base * this.height;
       }
   }
   ```

---

## 🎯 Nguyên Tắc SOLID

### 1. **S**ingle Responsibility Principle
Một class chỉ nên có một lý do để thay đổi

### 2. **O**pen-Closed Principle
Open for extension, closed for modification

### 3. **L**iskov Substitution Principle
Subclass phải thay thế được base class

### 4. **I**nterface Segregation Principle
Không ép client implement interface không dùng đến

### 5. **D**ependency Inversion Principle
Phụ thuộc vào abstractions, không phụ thuộc vào concrete classes

---

## ✨ TÓM TẮT - CHECKLIST HÀNG NGÀY

### 📝 Khi Viết Code Mới

- [ ] Tên biến/hàm/class có ý nghĩa rõ ràng?
- [ ] Hàm có làm ĐÚNG MỘT việc không?
- [ ] Hàm có quá 20 dòng không?
- [ ] Số tham số có ≤ 3 không?
- [ ] Code có tự giải thích được không?
- [ ] Có thể xóa bớt comments không?

### 🔍 Khi Review Code

- [ ] Code có dễ đọc không?
- [ ] Có test coverage đầy đủ không?
- [ ] Error handling có đúng không?
- [ ] Có code duplication không?
- [ ] Có vi phạm SOLID không?

### 🧹 Khi Refactor

- [ ] Tests đã pass chưa?
- [ ] Code đơn giản hơn chưa?
- [ ] Tên có cải thiện không?
- [ ] Functions có nhỏ hơn không?
- [ ] Duplications đã loại bỏ chưa?

---

## 📚 Tài Liệu Tham Khảo

- **Clean Code** - Robert C. Martin (Uncle Bob)
- **The Pragmatic Programmer** - Andrew Hunt & David Thomas
- **Refactoring** - Martin Fowler
- **Design Patterns** - Gang of Four

---

## 🤖 Hướng Dẫn Cho AI Copilot

Khi đọc file này, AI Copilot cần:

1. **Áp dụng tất cả quy tắc** khi generate code
2. **Ưu tiên**: Naming → Functions → Error Handling
3. **Luôn hỏi** nếu không chắc về context
4. **Suggest refactoring** khi thấy code vi phạm
5. **Giải thích lý do** khi đề xuất thay đổi

### Ví Dụ Response Từ AI:

```
"Tôi thấy hàm này có 5 tham số, vi phạm Clean Code rule về số lượng tham số.
Tôi đề xuất group chúng vào một object. Bạn có muốn tôi refactor không?"
```

---

*Document version: 1.0*
*Last updated: 2025-10-31*
