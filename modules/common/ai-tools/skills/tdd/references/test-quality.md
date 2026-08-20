# Test Quality Guidelines

High quality tests verify observable behavior through public interfaces. They do
not couple to internal implementation details.

## Good Tests

Good tests read like specifications. They exercise behavior that callers care
about and survive internal refactoring.

Key characteristics:

- Test observable behavior through public APIs.
- Use independent literal values for assertions.
- Survive internal implementation refactoring.
- Fail with clear diagnostics when behavior changes.
- Focus on one logical behavior per test.

```typescript
// Good: Tests observable behavior through public API
test("user can checkout with valid cart", async () => {
  const cart = createCart();
  cart.add(product);
  const result = await checkout(cart, paymentMethod);
  expect(result.status).toBe("confirmed");
});
```

```python
# Good: Verifies behavior with known expected literal
def test_calculate_total_applies_discount():
    items = [LineItem(price=100, quantity=2)]
    total = calculate_total(items, discount_percent=10)
    assert total == 180
```

## Anti-Patterns

### 1. Implementation Coupling

Tests that verify private methods, inspect internal fields, or assert on call
order break during refactoring.

Red flags:

- Mocking internal helper classes or functions.
- Asserting on internal call counts or call order.
- Querying private database tables directly instead of calling the API.
- Test names that describe how the code works instead of what behavior happens.

```typescript
// Bad: Coupled to internal implementation
test("checkout calls paymentService.process", async () => {
  const mockPayment = jest.mock(paymentService);
  await checkout(cart, payment);
  expect(mockPayment.process).toHaveBeenCalledWith(cart.total);
});
```

### 2. Tautological Tests

A tautological test recomputes expected results using the same formula as the
production code. Such tests pass by construction and cannot detect formula
defects.

Expected values must originate from independent sources of truth: fixed
literals, worked examples, or design specifications.

```python
# Bad: Expected value recomputes implementation formula
def test_bad_sum():
    numbers = [10, 20, 30]
    expected = sum(numbers)
    assert calculate_sum(numbers) == expected

# Good: Expected value is a known independent literal
def test_good_sum():
    numbers = [10, 20, 30]
    assert calculate_sum(numbers) == 60
```

### 3. Horizontal Slicing

Writing all test cases before writing any implementation creates imagined
interfaces. It locks in unverified design assumptions.

Use vertical slicing instead:

- Write one failing test for one minimal behavior slice.
- Write minimal code to make that test pass.
- Repeat the cycle for subsequent behavior slices.
