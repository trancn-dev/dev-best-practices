# Refactoring Guide - Hướng Dẫn Tái Cấu Trúc Code

> Hướng dẫn chi tiết về khi nào, tại sao và làm thế nào để refactor code hiệu quả
>
> **Mục đích**: Cải thiện chất lượng code, dễ maintain, giảm technical debt

---

## 📋 Mục Lục
- [What is Refactoring](#what-is-refactoring)
- [When to Refactor](#when-to-refactor)
- [Code Smells](#code-smells)
- [Refactoring Techniques](#refactoring-techniques)
- [Safe Refactoring Steps](#safe-refactoring-steps)
- [Refactoring Patterns](#refactoring-patterns)
- [Tools & Automation](#tools--automation)

---

## 🎯 WHAT IS REFACTORING

> **Refactoring**: Cải thiện cấu trúc bên trong của code mà KHÔNG thay đổi hành vi bên ngoài

### Key Principles

```
✅ REFACTORING IS:
- Improving code structure
- Making code easier to understand
- Reducing complexity
- Eliminating duplication
- Preparing for new features

❌ REFACTORING IS NOT:
- Adding new features
- Fixing bugs (that's bug fixing)
- Changing behavior
- Rewriting from scratch
```

---

## ⏰ WHEN TO REFACTOR

### 🔄 Rule of Three

```
1st time: Just do it
2nd time: Wince at duplication, but do it anyway
3rd time: REFACTOR!
```

### ✅ Good Times to Refactor

```javascript
// 1. Before adding a new feature
// Refactor to make the change easier
function calculatePrice(product) {
    // Complex, hard to extend
    return product.basePrice * 1.2 + 5;
}

// Refactor first
function calculatePrice(product) {
    const subtotal = product.basePrice;
    const tax = calculateTax(subtotal);
    const shipping = calculateShipping(product);
    return subtotal + tax + shipping;
}

// Now easy to add discount feature
function calculatePrice(product, discount = 0) {
    const subtotal = product.basePrice;
    const tax = calculateTax(subtotal);
    const shipping = calculateShipping(product);
    const discountAmount = subtotal * discount;
    return subtotal + tax + shipping - discountAmount;
}
```

```python
# 2. During code review
# Reviewer: "This function is hard to understand"
# ✅ Refactor immediately

# Before
def process(data):
    result = []
    for item in data:
        if item['status'] == 'active' and item['age'] > 18:
            result.append({'name': item['name'], 'email': item['email']})
    return result

# After refactoring
def process(data):
    active_adults = filter_active_adults(data)
    return extract_contact_info(active_adults)

def filter_active_adults(data):
    return [item for item in data
            if item['status'] == 'active' and item['age'] > 18]

def extract_contact_info(users):
    return [{'name': u['name'], 'email': u['email']} for u in users]
```

```typescript
// 3. When you understand the problem better
// Initial implementation (naive)
function findDuplicates(arr: number[]): number[] {
    const duplicates = [];
    for (let i = 0; i < arr.length; i++) {
        for (let j = i + 1; j < arr.length; j++) {
            if (arr[i] === arr[j] && !duplicates.includes(arr[i])) {
                duplicates.push(arr[i]);
            }
        }
    }
    return duplicates;
}

// Refactored (better understanding)
function findDuplicates(arr: number[]): number[] {
    const seen = new Set<number>();
    const duplicates = new Set<number>();

    for (const num of arr) {
        if (seen.has(num)) {
            duplicates.add(num);
        }
        seen.add(num);
    }

    return Array.from(duplicates);
}
```

### ❌ Bad Times to Refactor

```
❌ When you're close to a deadline
❌ When you don't have tests
❌ When code is about to be deleted
❌ Just because you don't like the style
❌ When you don't understand what the code does
```

---

## 👃 CODE SMELLS

### 1️⃣ Long Method

```javascript
// ❌ BAD - 50+ lines method
function processOrder(order) {
    // Validate order
    if (!order.items || order.items.length === 0) {
        throw new Error('No items');
    }

    // Calculate totals
    let subtotal = 0;
    for (const item of order.items) {
        subtotal += item.price * item.quantity;
    }

    // Apply discounts
    let discount = 0;
    if (order.customer.isVIP) {
        discount = subtotal * 0.2;
    }

    // Calculate tax
    const tax = (subtotal - discount) * 0.1;

    // Calculate shipping
    let shipping = 0;
    if (subtotal < 50) {
        shipping = 10;
    }

    // Create invoice
    // ... 30 more lines
}

// ✅ GOOD - Extract methods
function processOrder(order) {
    validateOrder(order);
    const subtotal = calculateSubtotal(order);
    const discount = calculateDiscount(order, subtotal);
    const tax = calculateTax(subtotal, discount);
    const shipping = calculateShipping(subtotal);
    return createInvoice(order, subtotal, discount, tax, shipping);
}
```

### 2️⃣ Large Class

```python
# ❌ BAD - God class
class User:
    def __init__(self):
        pass

    def save_to_database(self):
        pass

    def send_email(self):
        pass

    def generate_report(self):
        pass

    def process_payment(self):
        pass

    def upload_to_s3(self):
        pass

    # ... 20 more methods

# ✅ GOOD - Single Responsibility
class User:
    def __init__(self, name, email):
        self.name = name
        self.email = email

class UserRepository:
    def save(self, user):
        pass

class EmailService:
    def send_welcome_email(self, user):
        pass

class ReportGenerator:
    def generate_user_report(self, user):
        pass

class PaymentProcessor:
    def process(self, user, amount):
        pass
```

### 3️⃣ Long Parameter List

```typescript
// ❌ BAD - Too many parameters
function createUser(
    name: string,
    email: string,
    age: number,
    address: string,
    city: string,
    country: string,
    phone: string,
    role: string
) {
    // ...
}

// ✅ GOOD - Parameter object
interface UserData {
    name: string;
    email: string;
    age: number;
    address: Address;
    contact: ContactInfo;
    role: string;
}

interface Address {
    street: string;
    city: string;
    country: string;
}

interface ContactInfo {
    phone: string;
    email: string;
}

function createUser(userData: UserData) {
    // ...
}
```

### 4️⃣ Duplicated Code

```java
// ❌ BAD - Duplication
public void sendEmailToUsers() {
    List<User> users = userRepository.findAll();
    for (User user : users) {
        String subject = "Newsletter";
        String body = "Dear " + user.getName() + "...";
        emailService.send(user.getEmail(), subject, body);
    }
}

public void sendEmailToAdmins() {
    List<User> admins = userRepository.findAdmins();
    for (User admin : admins) {
        String subject = "Admin Alert";
        String body = "Dear " + admin.getName() + "...";
        emailService.send(admin.getEmail(), subject, body);
    }
}

// ✅ GOOD - Extract common code
public void sendEmailToUsers() {
    List<User> users = userRepository.findAll();
    sendBulkEmail(users, "Newsletter", this::createNewsletterBody);
}

public void sendEmailToAdmins() {
    List<User> admins = userRepository.findAdmins();
    sendBulkEmail(admins, "Admin Alert", this::createAdminAlertBody);
}

private void sendBulkEmail(
    List<User> recipients,
    String subject,
    Function<User, String> bodyGenerator
) {
    for (User user : recipients) {
        String body = bodyGenerator.apply(user);
        emailService.send(user.getEmail(), subject, body);
    }
}
```

### 5️⃣ Data Clumps

```javascript
// ❌ BAD - Data always appears together
function createInvoice(customerName, customerEmail, customerPhone) {
    // ...
}

function sendReceipt(customerName, customerEmail, customerPhone) {
    // ...
}

// ✅ GOOD - Extract object
class Customer {
    constructor(name, email, phone) {
        this.name = name;
        this.email = email;
        this.phone = phone;
    }
}

function createInvoice(customer) {
    // ...
}

function sendReceipt(customer) {
    // ...
}
```

### 6️⃣ Primitive Obsession

```python
# ❌ BAD - Using primitives everywhere
def transfer_money(from_account_number, to_account_number, amount_cents):
    if amount_cents <= 0:
        raise ValueError("Invalid amount")
    # ...

# ✅ GOOD - Create value objects
class Money:
    def __init__(self, amount_cents):
        if amount_cents <= 0:
            raise ValueError("Amount must be positive")
        self.amount_cents = amount_cents

    def __add__(self, other):
        return Money(self.amount_cents + other.amount_cents)

class Account:
    def __init__(self, account_number):
        self.account_number = account_number
        self.balance = Money(0)

def transfer_money(from_account: Account, to_account: Account, amount: Money):
    # Type safety and validation built-in
    pass
```

### 7️⃣ Switch Statements

```typescript
// ❌ BAD - Switch statement
function calculatePrice(product: Product): number {
    switch (product.type) {
        case 'book':
            return product.basePrice * 0.9;
        case 'electronics':
            return product.basePrice * 1.1;
        case 'clothing':
            return product.basePrice;
        default:
            throw new Error('Unknown type');
    }
}

// ✅ GOOD - Polymorphism
interface Product {
    calculatePrice(): number;
}

class Book implements Product {
    constructor(private basePrice: number) {}

    calculatePrice(): number {
        return this.basePrice * 0.9;
    }
}

class Electronics implements Product {
    constructor(private basePrice: number) {}

    calculatePrice(): number {
        return this.basePrice * 1.1;
    }
}

class Clothing implements Product {
    constructor(private basePrice: number) {}

    calculatePrice(): number {
        return this.basePrice;
    }
}
```

---

## 🔧 REFACTORING TECHNIQUES

### Extract Method

```javascript
// ❌ Before
function printOwing(invoice) {
    console.log("***********************");
    console.log("**** Customer Owes ****");
    console.log("***********************");

    let outstanding = 0;
    for (const order of invoice.orders) {
        outstanding += order.amount;
    }

    console.log(`name: ${invoice.customer}`);
    console.log(`amount: ${outstanding}`);
}

// ✅ After - Extract methods
function printOwing(invoice) {
    printBanner();
    const outstanding = calculateOutstanding(invoice);
    printDetails(invoice, outstanding);
}

function printBanner() {
    console.log("***********************");
    console.log("**** Customer Owes ****");
    console.log("***********************");
}

function calculateOutstanding(invoice) {
    return invoice.orders.reduce((sum, order) => sum + order.amount, 0);
}

function printDetails(invoice, outstanding) {
    console.log(`name: ${invoice.customer}`);
    console.log(`amount: ${outstanding}`);
}
```

### Inline Method

```python
# ❌ Before - Unnecessary method
def get_rating(driver):
    return more_than_five_late_deliveries(driver) ? 2 : 1

def more_than_five_late_deliveries(driver):
    return driver.late_deliveries > 5

# ✅ After - Inline trivial method
def get_rating(driver):
    return 2 if driver.late_deliveries > 5 else 1
```

### Extract Variable

```java
// ❌ Before
if ((platform.toUpperCase().indexOf("MAC") > -1) &&
    (browser.toUpperCase().indexOf("IE") > -1) &&
    wasInitialized() && resize > 0) {
    // do something
}

// ✅ After
boolean isMacOS = platform.toUpperCase().indexOf("MAC") > -1;
boolean isIE = browser.toUpperCase().indexOf("IE") > -1;
boolean wasResized = resize > 0;

if (isMacOS && isIE && wasInitialized() && wasResized) {
    // do something
}
```

### Rename Variable/Method

```typescript
// ❌ Before - Unclear names
function calc(d: number): number {
    return d * 24 * 60 * 60 * 1000;
}

// ✅ After - Clear names
function convertDaysToMilliseconds(days: number): number {
    const HOURS_PER_DAY = 24;
    const MINUTES_PER_HOUR = 60;
    const SECONDS_PER_MINUTE = 60;
    const MILLISECONDS_PER_SECOND = 1000;

    return days * HOURS_PER_DAY * MINUTES_PER_HOUR *
           SECONDS_PER_MINUTE * MILLISECONDS_PER_SECOND;
}
```

### Replace Temp with Query

```javascript
// ❌ Before
function calculateTotal(order) {
    const basePrice = order.quantity * order.itemPrice;
    const discountFactor = basePrice > 1000 ? 0.95 : 0.98;
    return basePrice * discountFactor;
}

// ✅ After
function calculateTotal(order) {
    return basePrice(order) * discountFactor(order);
}

function basePrice(order) {
    return order.quantity * order.itemPrice;
}

function discountFactor(order) {
    return basePrice(order) > 1000 ? 0.95 : 0.98;
}
```

### Introduce Parameter Object

```python
# ❌ Before
def create_report(start_date, end_date, user_id, department):
    pass

def calculate_metrics(start_date, end_date, user_id, department):
    pass

# ✅ After
class ReportCriteria:
    def __init__(self, start_date, end_date, user_id, department):
        self.start_date = start_date
        self.end_date = end_date
        self.user_id = user_id
        self.department = department

def create_report(criteria: ReportCriteria):
    pass

def calculate_metrics(criteria: ReportCriteria):
    pass
```

### Replace Conditional with Polymorphism

```typescript
// ❌ Before
class Bird {
    constructor(public type: string, public numberOfCoconuts: number) {}

    getSpeed(): number {
        switch (this.type) {
            case 'European':
                return 35;
            case 'African':
                return 40 - 2 * this.numberOfCoconuts;
            case 'Norwegian':
                return this.isNailed ? 0 : 10;
            default:
                throw new Error('Unknown bird');
        }
    }
}

// ✅ After
abstract class Bird {
    abstract getSpeed(): number;
}

class EuropeanBird extends Bird {
    getSpeed(): number {
        return 35;
    }
}

class AfricanBird extends Bird {
    constructor(private numberOfCoconuts: number) {
        super();
    }

    getSpeed(): number {
        return 40 - 2 * this.numberOfCoconuts;
    }
}

class NorwegianBird extends Bird {
    constructor(private isNailed: boolean) {
        super();
    }

    getSpeed(): number {
        return this.isNailed ? 0 : 10;
    }
}
```

---

## 🛡️ SAFE REFACTORING STEPS

### The Refactoring Workflow

```
1. ✅ Ensure you have good test coverage
2. 🔧 Make one small refactoring
3. 🧪 Run all tests
4. ✅ Tests pass? Commit and continue
5. ❌ Tests fail? Undo and try again
6. 🔄 Repeat
```

### Example: Safe Refactoring Process

```javascript
// Step 1: Original code with tests
function calculateOrderTotal(order) {
    let total = 0;
    for (const item of order.items) {
        total += item.price * item.quantity;
    }
    if (order.customer.isPremium) {
        total = total * 0.9;
    }
    total = total * 1.1; // Add tax
    return total;
}

// Test
test('calculateOrderTotal for regular customer', () => {
    const order = {
        items: [{ price: 10, quantity: 2 }],
        customer: { isPremium: false }
    };
    expect(calculateOrderTotal(order)).toBe(22); // 20 * 1.1
});

// Step 2: Extract subtotal calculation
function calculateOrderTotal(order) {
    const subtotal = calculateSubtotal(order);
    let total = subtotal;
    if (order.customer.isPremium) {
        total = total * 0.9;
    }
    total = total * 1.1;
    return total;
}

function calculateSubtotal(order) {
    let total = 0;
    for (const item of order.items) {
        total += item.price * item.quantity;
    }
    return total;
}

// Run tests ✅

// Step 3: Extract discount calculation
function calculateOrderTotal(order) {
    const subtotal = calculateSubtotal(order);
    const discount = calculateDiscount(subtotal, order.customer);
    const total = (subtotal - discount) * 1.1;
    return total;
}

function calculateDiscount(subtotal, customer) {
    return customer.isPremium ? subtotal * 0.1 : 0;
}

// Run tests ✅

// Step 4: Extract tax calculation
function calculateOrderTotal(order) {
    const subtotal = calculateSubtotal(order);
    const discount = calculateDiscount(subtotal, order.customer);
    const tax = calculateTax(subtotal - discount);
    return subtotal - discount + tax;
}

function calculateTax(amount) {
    const TAX_RATE = 0.1;
    return amount * TAX_RATE;
}

// Run tests ✅
```

---

## 🎨 REFACTORING PATTERNS

### Pattern 1: Replace Magic Numbers with Constants

```java
// ❌ Before
public double calculateMonthlyPayment(double principal, int years) {
    double rate = 0.05; // What is this?
    int months = years * 12;
    return principal * rate / 12 * Math.pow(1 + rate/12, months);
}

// ✅ After
public class LoanCalculator {
    private static final double ANNUAL_INTEREST_RATE = 0.05;
    private static final int MONTHS_PER_YEAR = 12;

    public double calculateMonthlyPayment(double principal, int years) {
        double monthlyRate = ANNUAL_INTEREST_RATE / MONTHS_PER_YEAR;
        int totalMonths = years * MONTHS_PER_YEAR;
        return principal * monthlyRate * Math.pow(1 + monthlyRate, totalMonths);
    }
}
```

### Pattern 2: Replace Type Code with Class

```python
# ❌ Before
EMPLOYEE_TYPE_ENGINEER = 0
EMPLOYEE_TYPE_SALESMAN = 1
EMPLOYEE_TYPE_MANAGER = 2

class Employee:
    def __init__(self, name, type):
        self.name = name
        self.type = type

    def get_salary(self):
        if self.type == EMPLOYEE_TYPE_ENGINEER:
            return 5000
        elif self.type == EMPLOYEE_TYPE_SALESMAN:
            return 3000
        elif self.type == EMPLOYEE_TYPE_MANAGER:
            return 7000

# ✅ After
class Employee:
    def __init__(self, name):
        self.name = name

    def get_salary(self):
        raise NotImplementedError

class Engineer(Employee):
    def get_salary(self):
        return 5000

class Salesman(Employee):
    def get_salary(self):
        return 3000

class Manager(Employee):
    def get_salary(self):
        return 7000
```

### Pattern 3: Decompose Conditional

```javascript
// ❌ Before
if (date.before(SUMMER_START) || date.after(SUMMER_END)) {
    charge = quantity * winterRate + winterServiceCharge;
} else {
    charge = quantity * summerRate;
}

// ✅ After
charge = isWinter(date) ? winterCharge(quantity) : summerCharge(quantity);

function isWinter(date) {
    return date.before(SUMMER_START) || date.after(SUMMER_END);
}

function winterCharge(quantity) {
    return quantity * winterRate + winterServiceCharge;
}

function summerCharge(quantity) {
    return quantity * summerRate;
}
```

---

## 🛠️ TOOLS & AUTOMATION

### IDE Refactoring Tools

```typescript
// Most IDEs support:
// - Rename (F2)
// - Extract Method (Ctrl+Alt+M)
// - Extract Variable (Ctrl+Alt+V)
// - Inline (Ctrl+Alt+N)
// - Move (F6)
// - Change Signature (Ctrl+F6)

// Example: VS Code with TypeScript
class UserService {
    // Select code and use "Extract Method" refactoring
    processUser(user: User) {
        // Selected: validation logic
        if (!user.email || !user.name) {
            throw new Error('Invalid user');
        }
        // Auto-extracted to:
        // this.validateUser(user);
    }
}
```

### Automated Refactoring Tools

```bash
# JavaScript/TypeScript
npm install -g jscodeshift

# Python
pip install rope  # Refactoring library
pip install bowler  # AST-based refactoring

# Java
# Use IntelliJ IDEA built-in refactoring
# Or Eclipse with automated refactoring tools
```

---

## 📝 REFACTORING CHECKLIST

### Before Refactoring

- [ ] Code has good test coverage
- [ ] All tests are passing
- [ ] You understand what the code does
- [ ] You have a clear goal for refactoring
- [ ] You have time to do it properly
- [ ] Code is under version control

### During Refactoring

- [ ] Make small, incremental changes
- [ ] Run tests after each change
- [ ] Commit frequently
- [ ] Use IDE refactoring tools when possible
- [ ] Keep the code working at all times
- [ ] Don't add features while refactoring

### After Refactoring

- [ ] All tests still pass
- [ ] Code is more readable
- [ ] Code is easier to modify
- [ ] No duplication
- [ ] Good naming throughout
- [ ] Update documentation if needed

---

## 🎯 BEST PRACTICES

### ✅ DO

- ✅ Refactor in small steps
- ✅ Run tests frequently
- ✅ Commit after each successful refactoring
- ✅ Use meaningful names
- ✅ Extract methods to make code readable
- ✅ Remove duplication
- ✅ Simplify complex conditionals
- ✅ Apply SOLID principles

### ❌ DON'T

- ❌ Refactor without tests
- ❌ Make big changes at once
- ❌ Refactor and add features together
- ❌ Refactor without understanding the code
- ❌ Refactor just before deployment
- ❌ Over-engineer solutions

---

## 📚 REFERENCES

- **Refactoring** - Martin Fowler
- **Clean Code** - Robert C. Martin
- **Working Effectively with Legacy Code** - Michael Feathers
- [Refactoring Guru](https://refactoring.guru/)
- [SourceMaking - Refactoring](https://sourcemaking.com/refactoring)

---

*Document Version: 1.0*
*Last Updated: 2025-11-01*
