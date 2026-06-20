# Mix App Supabase FCM Trigger Events Plan
## Which App Events Should Trigger Which Notifications

---

# Core Trigger Events

## 1. User Creates Ride
Recipients:
- user
- assigned admin

Payload ideas:
- user: Ride request created
- admin: New ride assigned

---

## 2. User Places Order
Recipients:
- user
- assigned admin

Payload ideas:
- user: Order placed successfully
- admin: New order assigned

---

## 3. Delivery Ride Created Automatically
Recipients:
- user
- assigned admin

Payload ideas:
- user: Delivery request created
- admin: New delivery assigned

---

## 4. Ride Status Updated
Recipient:
- user

Examples:
- on_the_way
- ride_in_progress
- completed
- cancelled

---

## 5. Delivery Status Updated
Recipient:
- user

Examples:
- on_the_way
- delivery_in_progress
- completed
- cancelled

---

## 6. Order Status Updated
Recipient:
- user

Examples:
- pending
- processing
- delivered

---

## 7. Escalation Created
Recipient:
- super admin

Payload:
- escalated ride/order requires attention

---

## 8. Manual Reassignment
Recipient:
- newly assigned admin

Payload:
- request reassigned to you

---

## 9. Promo Broadcast
Recipients:
- topic subscribers
- users
- admins depending on message type

---

# Suggested Target Screens

- `ride_detail`
- `order_detail`
- `admin_rides`
- `admin_orders`
- `admin_escalation_dashboard`
- `main_shell`

---

# End of Trigger Events Plan
