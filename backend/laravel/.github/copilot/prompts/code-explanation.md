# Prompt: Code Explanation

## Purpose
Generate comprehensive explanations of code functionality, architecture, and implementation details for Laravel projects.

## When to Use
- Understanding complex code sections
- Onboarding new team members
- Documenting legacy code
- Code review and knowledge sharing
- Learning Laravel patterns and best practices

---

## Prompt Template

```
Please explain the following code:

[CODE_BLOCK]

Include:
1. **Purpose**: What does this code do?
2. **How it works**: Step-by-step explanation
3. **Dependencies**: What does it rely on?
4. **Design patterns**: What patterns are used?
5. **Laravel conventions**: How does it follow Laravel best practices?
6. **Potential improvements**: Suggestions for optimization or refactoring
7. **Related components**: What other parts of the system interact with this?
```

---

## Example Usage

### Input:
```
Please explain the following code:

class CreateOrderAction
{
    public function __construct(
        private readonly OrderRepository $orders,
        private readonly InventoryService $inventory,
        private readonly PaymentService $payments
    ) {}

    public function execute(User $user, array $items): Order
    {
        return DB::transaction(function () use ($user, $items) {
            $this->inventory->checkAvailability($items);

            $order = $this->orders->create([
                'user_id' => $user->id,
                'total' => $this->calculateTotal($items),
                'status' => OrderStatus::Pending,
            ]);

            foreach ($items as $item) {
                $order->items()->create($item);
            }

            $this->inventory->reserve($items);

            event(new OrderCreated($order));

            return $order;
        });
    }
}
```

### Expected Output:

**Purpose:**
This `CreateOrderAction` class implements the Action pattern to handle order creation in an e-commerce system.

**How it works:**
1. Constructor injection receives three dependencies: OrderRepository, InventoryService, and PaymentService
2. The `execute()` method accepts a User and array of items
3. Wraps the entire process in a database transaction for data integrity
4. Checks inventory availability before proceeding
5. Creates the order record with pending status
6. Creates order item records in a loop
7. Reserves inventory for the items
8. Dispatches an OrderCreated event for other parts of the system
9. Returns the created order

**Dependencies:**
- `OrderRepository`: Handles database operations for orders
- `InventoryService`: Manages product inventory
- `PaymentService`: Processes payments (injected but not used in this method)
- `DB` facade: Provides database transaction support
- `OrderCreated` event: Notifies listeners about new orders
- `OrderStatus` enum: Defines order status constants

**Design patterns:**
- **Action Pattern**: Encapsulates single business operation
- **Repository Pattern**: Abstracts database access
- **Service Pattern**: Handles business logic in services
- **Dependency Injection**: Constructor injection for loose coupling
- **Event-Driven**: Uses Laravel events for decoupled notifications

**Laravel conventions:**
- ✅ Uses constructor property promotion (PHP 8.0+)
- ✅ Type hints for all parameters and return types
- ✅ Follows single responsibility principle
- ✅ Uses Eloquent relationships (`$order->items()`)
- ✅ Uses database transactions for data integrity
- ✅ Dispatches events for side effects

**Potential improvements:**
1. Add error handling for inventory check failure
2. Move `calculateTotal()` to a separate calculator service
3. Add logging for debugging and audit trail
4. Consider using a job queue for event processing
5. Add validation for items array structure
6. Consider adding payment processing in this action or separate it

**Related components:**
- `Order` model with `items()` relationship
- `OrderRepository` for data persistence
- `InventoryService` for stock management
- `OrderCreated` event and its listeners
- `OrderStatus` enum for status definitions
- Database migrations for orders and order_items tables

---

## Variations

### For Beginners
```
Explain this code as if I'm new to Laravel. Break down each part and explain why it's needed.
```

### For Specific Aspect
```
Explain the security implications of this code and any potential vulnerabilities.
```

### For Performance
```
Explain the performance characteristics of this code. Are there any bottlenecks or optimization opportunities?
```

### For Testing
```
Explain how to test this code. What test cases should be covered?
```

---

## Best Practices

1. **Provide context**: Include surrounding code if needed
2. **Specify focus**: Mention specific aspects you want explained
3. **Ask follow-ups**: Request clarification on unclear parts
4. **Request examples**: Ask for usage examples if needed
5. **Compare approaches**: Ask about alternative implementations

---

## Related Prompts

- `refactoring-suggestions.md` - Get refactoring ideas
- `code-review.md` - Comprehensive code review
- `testing-strategy.md` - How to test the code
- `documentation-generation.md` - Generate documentation
