# MAD_Excersise #3 – OOP Domain Modeling for Mobile Apps

## Block 1 – Core OOP Concepts in a Mobile Context

This exercise focuses on applying fundamental object-oriented programming concepts—classes, objects, encapsulation, inheritance, and polymorphism—to a realistic mobile application domain. In modern mobile development (Kotlin/Java on Android, Swift on iOS), OOP is used to model domain entities (users, orders, rides) and organize business logic, while frameworks provide lifecycle and UI layers.

Key concepts to emphasize:
- Classes and objects: classes define the blueprint (attributes + methods); objects are concrete instances representing real-world entities in your app.
- Encapsulation: grouping data and related behavior inside classes and exposing only what is necessary through public APIs while hiding internal details.
- Inheritance: extracting common attributes and behaviors into base classes to reduce duplication and express "is-a" relationships.
- Polymorphism: treating related objects uniformly through interfaces or base classes and allowing different concrete implementations to override behavior.

Understanding these concepts in a mobile context helps you design code that is easier to maintain, test, and extend as app features grow.

---

## Block 2 – Task 1: Identifying Entities and Designing Classes

In this task, you choose a domain (e.g., ride-hailing, e-commerce, social media, fitness tracking, banking) and identify 4–5 core entities. Each entity should map to a class with attributes capturing its state and methods capturing its behavior.

Recommended steps:
- Start from user scenarios: what tasks users perform (ordering a ride, placing an order, posting a photo, recording a workout).
- Derive entities from nouns in those scenarios (User, Driver, Ride, Payment, Product, Order, Account, Transaction).
- For each class, define 3–5 fields with realistic data types and 2–4 methods that correspond to domain actions.

Example (Ride-Hailing):
- `Ride`: attributes like `rideId`, `passenger`, `driver`, `pickupLocation`, `dropoffLocation`, `status`, `fare`; methods like `calculateFare()`, `updateStatus()`, `cancelRide()`.
- `User`: attributes like `userId`, `name`, `phone`, `paymentMethods`; methods like `requestRide()`, `rateDriver()`.

Documenting this in a table or simple UML-style diagram clarifies the relationships and keeps the design consistent.

---

## Block 3 – Task 2: Encapsulation and Access Control

Encapsulation is about protecting the internal state of objects and exposing a clean, safe interface. In mobile apps, poor encapsulation leads to fragile code where many components directly modify internal fields, making bugs hard to track.

Key practices:
- Make fields private by default, exposing them via getters/setters or computed properties when necessary.
- Use methods to enforce invariants (e.g., only `addItemToCart()` modifies the cart’s list of items, ensuring totals are updated consistently).
- Avoid exposing mutable collections directly; instead, return read-only views or copies.

In your exercise, you should:
- Identify which fields must not be modified freely (e.g., `balance` in a `BankAccount`).
- Design methods that encapsulate changes (e.g., `deposit(amount)`, `withdraw(amount)` with validation).
- Explain how this prevents inconsistent state and bugs.

---

## Block 4 – Task 3: Inheritance and Hierarchies

This task requires designing inheritance hierarchies for your domain. A common pattern in mobile apps is to identify a base class for entities that share attributes and behaviors.

Examples:
- `User` as base class with subclasses `Customer` and `Driver`.
- `Account` as base class with subclasses `SavingsAccount` and `CheckingAccount`.
- `Post` as base class with subclasses `ImagePost`, `VideoPost`, `TextPost`.

Good patterns for inheritance:
- Use it when an "is-a" relationship is clearly true in the domain and shared behavior is non-trivial.
- Avoid deep or artificial hierarchies—prefer composition when entities just "have" other objects.

In your documentation, explain why you chose inheritance over duplication and what common functionality lives in the base class (e.g., `calculateRewardPoints()` in all account types).

---

## Block 5 – Task 4: Polymorphism and Interfaces

Polymorphism lets you treat different concrete types uniformly through a common interface or base class. In mobile apps, this is often used for payment methods, notification channels, or UI items in lists.

Examples:
- `PaymentMethod` interface with implementations `CreditCard`, `PayPal`, `ApplePay`, `GooglePay`, each overriding `authorize()` or `charge()`.
- `NotificationChannel` interface implemented by `EmailNotification`, `PushNotification`, `SMSNotification`.
- `FeedItem` base class or interface with subclasses for different content types.

In your implementation, you might:
- Define an interface or abstract base class that declares shared methods.
- Implement multiple concrete classes with different behavior.
- Use polymorphism where client code operates on the interface type instead of specific implementations.

Describe how this design makes adding new types easier (e.g., a new payment provider) without changing existing logic, which is key for evolving mobile apps.

---

## Block 6 – Task 5: Code Quality and Best Practices

The final part of the exercise emphasizes writing clean, maintainable code. Important practices in mobile OOP design include:
- Clear naming: classes and methods should reflect domain concepts, not implementation details.
- Single Responsibility Principle: each class should have one primary reason to change.
- Separation of concerns: avoid mixing UI code with domain logic; use patterns like MVVM/MVC/MVP.
- Testability: encapsulated, well-structured domain classes are easier to unit test.

A short reflection on how your design would scale—new features, new entity types, more complex rules—will demonstrate understanding beyond syntax.

