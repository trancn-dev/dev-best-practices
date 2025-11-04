# Rule: Refactoring Guide

## Intent
Enforce systematic code improvement practices through refactoring techniques while maintaining functionality and tests.

## Scope
Applies to all code refactoring activities including restructuring, simplification, and design improvements.

---

## 1. When to Refactor

### Refactor When You See:

- ✅ **Code Smells** (duplicated code, long functions, large classes)
- ✅ **Before adding new features** (prepare codebase)
- ✅ **After fixing bugs** (clean up while context is fresh)
- ✅ **During code review** (as suggested improvements)
- ❌ **Not as a separate project** (integrate with feature work)

### Code Smells Checklist

- [ ] **Long Method** (> 20 lines)
- [ ] **Large Class** (> 500 lines)
- [ ] **Long Parameter List** (> 3 parameters)
- [ ] **Duplicated Code**
- [ ] **Complex Conditionals**
- [ ] **Deep Nesting** (> 3 levels)
- [ ] **Magic Numbers**
- [ ] **Primitive Obsession**
- [ ] **Feature Envy** (method uses another class more than its own)

---

## 2. Extract Method

```javascript
// ❌ BAD - Long method
function processOrder(order) {
    // Validate order (10 lines)
    if (!order.items || order.items.length === 0) {
        throw new Error('Order must have items');
    }
    // ... more validation

    // Calculate total (15 lines)
    let subtotal = 0;
    for (const item of order.items) {
        subtotal += item.price * item.quantity;
    }
    // ... more calculation

    // Send email (20 lines)
    const emailBody = `Order confirmed...`;
    // ... email logic
}

// ✅ GOOD - Extracted methods
function processOrder(order) {
    validateOrder(order);
    const total = calculateTotal(order);
    sendConfirmationEmail(order, total);
}

function validateOrder(order) {
    if (!order.items || order.items.length === 0) {
        throw new Error('Order must have items');
    }
    // ... validation
}

function calculateTotal(order) {
    const subtotal = order.items.reduce((sum, item) =>
        sum + item.price * item.quantity, 0
    );
    return subtotal * (1 + TAX_RATE);
}

function sendConfirmationEmail(order, total) {
    // ... email logic
}
```

---

## 3. Introduce Parameter Object

```javascript
// ❌ BAD - Too many parameters
function createUser(name, email, age, address, phone, role, department) {
    // ...
}

// ✅ GOOD - Parameter object
function createUser(userData) {
    const { name, email, age, address, phone, role, department } = userData;
    // ...
}

createUser({
    name: 'John',
    email: 'john@example.com',
    age: 30,
    address: '123 Main St',
    phone: '555-1234',
    role: 'admin',
    department: 'IT'
});
```

---

## 4. Replace Conditional with Polymorphism

```javascript
// ❌ BAD - Complex conditionals
function calculateShipping(order) {
    if (order.type === 'express') {
        return order.total * 0.2;
    } else if (order.type === 'standard') {
        return order.total * 0.1;
    } else if (order.type === 'economy') {
        return order.total * 0.05;
    }
}

// ✅ GOOD - Polymorphism
class ShippingStrategy {
    calculate(total) {
        throw new Error('Must implement calculate');
    }
}

class ExpressShipping extends ShippingStrategy {
    calculate(total) {
        return total * 0.2;
    }
}

class StandardShipping extends ShippingStrategy {
    calculate(total) {
        return total * 0.1;
    }
}

const shippingStrategies = {
    express: new ExpressShipping(),
    standard: new StandardShipping()
};

function calculateShipping(order) {
    return shippingStrategies[order.type].calculate(order.total);
}
```

---

## 5. Simplify Conditionals

### Replace Nested Conditionals with Guard Clauses

```javascript
// ❌ BAD - Deep nesting
function processPayment(order) {
    if (order) {
        if (order.isPaid) {
            if (order.amount > 0) {
                if (order.user) {
                    // Process payment
                    return true;
                }
            }
        }
    }
    return false;
}

// ✅ GOOD - Guard clauses
function processPayment(order) {
    if (!order) return false;
    if (!order.isPaid) return false;
    if (order.amount <= 0) return false;
    if (!order.user) return false;

    // Process payment
    return true;
}
```

---

## 6. Extract Class

```javascript
// ❌ BAD - God class
class User {
    constructor(name, email) {
        this.name = name;
        this.email = email;
    }

    // User methods
    updateProfile() { }
    changePassword() { }

    // Order methods (should be separate class)
    createOrder() { }
    cancelOrder() { }

    // Payment methods (should be separate class)
    processPayment() { }
    refundPayment() { }
}

// ✅ GOOD - Separate classes
class User {
    constructor(name, email) {
        this.name = name;
        this.email = email;
    }

    updateProfile() { }
    changePassword() { }
}

class Order {
    constructor(userId) {
        this.userId = userId;
    }

    create() { }
    cancel() { }
}

class Payment {
    constructor(orderId) {
        this.orderId = orderId;
    }

    process() { }
    refund() { }
}
```

---

## 7. Replace Magic Numbers

```javascript
// ❌ BAD - Magic numbers
function calculateDiscount(price) {
    if (price > 1000) {
        return price * 0.2;
    } else if (price > 500) {
        return price * 0.1;
    }
    return 0;
}

// ✅ GOOD - Named constants
const PREMIUM_THRESHOLD = 1000;
const STANDARD_THRESHOLD = 500;
const PREMIUM_DISCOUNT = 0.2;
const STANDARD_DISCOUNT = 0.1;

function calculateDiscount(price) {
    if (price > PREMIUM_THRESHOLD) {
        return price * PREMIUM_DISCOUNT;
    } else if (price > STANDARD_THRESHOLD) {
        return price * STANDARD_DISCOUNT;
    }
    return 0;
}
```

---

## 8. Refactoring Process

### Safe Refactoring Steps

1. **Write Tests First** (if not exist)
2. **Make Small Changes** (one refactoring at a time)
3. **Run Tests** (after each change)
4. **Commit Frequently** (working state)
5. **Review Changes** (before merging)

```bash
# ✅ GOOD - Refactoring workflow
git checkout -b refactor/extract-user-service

# 1. Ensure tests pass
npm test

# 2. Make small refactoring
git commit -m "refactor: extract validateUser function"

# 3. Run tests again
npm test

# 4. Continue refactoring
git commit -m "refactor: extract calculateTotal function"

# 5. Final test
npm test

# 6. Create PR
git push origin refactor/extract-user-service
```

---

## 9. Copilot Instructions

When suggesting refactoring, Copilot **MUST**:

1. **IDENTIFY** code smells
2. **SUGGEST** specific refactoring technique
3. **PROVIDE** before/after code
4. **EXPLAIN** benefits
5. **RECOMMEND** test coverage
6. **BREAK** into small steps

### Response Pattern

```markdown
🔧 **Refactoring Suggestion**

**Code Smell:** Long Method (45 lines)

**Current Code:**
\`\`\`javascript
function processOrder(order) {
    // 45 lines of mixed concerns
}
\`\`\`

**Suggested Refactoring:** Extract Method

**Refactored Code:**
\`\`\`javascript
function processOrder(order) {
    validateOrder(order);
    const total = calculateTotal(order);
    sendConfirmationEmail(order, total);
}
\`\`\`

**Benefits:**
- Improved readability
- Better testability
- Single Responsibility

**Steps:**
1. Extract validateOrder()
2. Extract calculateTotal()
3. Extract sendConfirmationEmail()
4. Run tests after each extraction
```

---

## 10. Checklist

### Before Refactoring
- [ ] Tests exist and pass
- [ ] Understand current behavior
- [ ] Create feature branch
- [ ] Plan small incremental changes

### During Refactoring
- [ ] One refactoring at a time
- [ ] Run tests after each change
- [ ] Commit working states
- [ ] No functional changes mixed with refactoring

### After Refactoring
- [ ] All tests pass
- [ ] Code review completed
- [ ] Documentation updated
- [ ] No performance regression

---

## References

- Refactoring - Martin Fowler
- Clean Code - Robert C. Martin
- Refactoring Guru (refactoring.guru)

**Remember:** Refactoring is not rewriting. It's improving code structure while preserving behavior.
