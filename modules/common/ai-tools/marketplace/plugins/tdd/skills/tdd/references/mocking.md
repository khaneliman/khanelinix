# Mocking Guidelines

Mock external system boundaries only. Do not mock code that you control.

## Where to Mock

Mock only at external system boundaries:

- Third-party network APIs (payment providers, email services, external
  webhooks).
- System clocks and time-dependent functions.
- Cryptographic or pseudo-random number generators.
- External file systems or remote object storage when real access is
  unavailable.

## What Never to Mock

Never mock:

- Internal modules or helper classes in the same repository.
- Internal domain logic and calculations.
- In-memory data structures.
- Local SQLite or test database instances when cheap local execution exists.

## Design for Mockability

Use architectural patterns that isolate external boundaries cleanly.

### 1. Dependency Injection

Pass external clients as arguments rather than instantiating them inside
functions.

```typescript
// Good: Client is passed as dependency
function processOrder(order: Order, paymentGateway: PaymentGateway) {
  return paymentGateway.charge(order.amount);
}

// Bad: Client is hardcoded internally
function processOrder(order: Order) {
  const paymentGateway = new StripeGateway(process.env.API_KEY);
  return paymentGateway.charge(order.amount);
}
```

### 2. Specific Client Interfaces

Create domain-specific interfaces for external operations rather than generic
untyped clients.

```typescript
// Good: Domain interface has specific mockable methods
interface UserDirectory {
  getUser(id: string): Promise<User>;
  updateUser(id: string, data: UserUpdate): Promise<void>;
}

// Bad: Generic client requires complex conditional mocking
interface GenericClient {
  fetch(endpoint: string, options: RequestInit): Promise<Response>;
}
```

Specific interfaces provide distinct benefits:

- Each mock method returns a specific shape.
- Test setup avoids conditional mock branches.
- Type checking validates test fixtures at compile time.
