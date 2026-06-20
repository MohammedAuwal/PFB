# Mix App Technical Documentation - Part 5
## Admin Workload Balancing, Capacity Control, and Smarter National Assignment

---

# Table of Contents

1. Purpose of Part 5
2. Why Nearest Admin Alone Is Not Enough
3. The Workload Problem
4. Example of the Problem in Lagos
5. What Workload Balancing Means
6. Balancing Strategy Added
7. New Admin Workload Fields
8. How Assignment Now Works
9. Scoring Logic
10. Capacity Limits
11. Active / Paused Admin Mode
12. Area + State + Radius + Workload Hybrid
13. Why This Is Better Than Distance-Only
14. What Happens When Admin Is Full
15. What Happens When Admin Is Paused
16. What Happens When No Admin Qualifies
17. Operational Benefits
18. Admin UX Implications
19. Future Improvements
20. Final Summary

---

# 1. Purpose of Part 5

Part 4 introduced nearest-admin assignment.

Part 5 improves that system by making it smarter.

The reason is simple:
the nearest admin is not always the best admin if that admin is already overloaded.

This document explains the workload balancing layer added on top of the location-aware assignment system.

---

# 2. Why Nearest Admin Alone Is Not Enough

Suppose there are two admins in the same broad area.

- Admin A is 2 km away
- Admin B is 4 km away

If Admin A already has:
- 15 active deliveries
- 6 active rides
- several unresolved orders

and Admin B has:
- only 2 active requests

then assigning the next user to Admin A just because they are slightly nearer may create a bad experience.

That is why distance alone is not enough.

---

# 3. The Workload Problem

In large operational systems, problems happen when one operator becomes overloaded while others are idle.

This can lead to:
- slower response time
- missed requests
- poor user experience
- uneven admin effort
- local operational burnout

A national app needs balancing logic, not just proximity logic.

---

# 4. Example of the Problem in Lagos

Imagine:
- Lekki Admin has 25 active requests
- Ajah Admin has 4 active requests

A new user in Lekki places an order.

If only location is considered:
- Lekki Admin keeps receiving more and more requests

But if workload is also considered:
- Ajah Admin may receive some nearby requests if they are still reasonable to handle

This makes operations more sustainable.

---

# 5. What Workload Balancing Means

Workload balancing means the system does not only ask:

**“Who is closest?”**

It also asks:

**“Who can still handle this request well?”**

That is a much more mature operational question.

---

# 6. Balancing Strategy Added

The app now supports workload-aware admin assignment.

The system checks:
- area match
- state match
- distance/radius
- admin active status
- admin current active load
- admin maximum allowed active assignments

This is a stronger production-style design.

---

# 7. New Admin Workload Fields

Admins can now have:

- `isActive`
- `maxActiveAssignments`

## `isActive`
If false:
- admin will not receive new assignments

Useful when:
- admin is offline
- admin is on break
- admin is unavailable
- admin is temporarily suspended from operations

## `maxActiveAssignments`
Defines how many active requests an admin should handle before the system stops assigning new ones.

Example:
- 20 active requests max

---

# 8. How Assignment Now Works

When the app tries to assign an admin:

1. Build candidate admins using:
   - area match if available
   - otherwise state match
   - otherwise broad radius fallback

2. Ignore admins who are:
   - not active
   - missing base location
   - outside acceptable rules
   - already above capacity

3. Count each admin’s active assignments

4. Compute an internal score combining:
   - distance
   - load penalty
   - area/state bonus

5. Pick the lowest/best score

This creates smarter assignment.

---

# 9. Scoring Logic

A simple score system is used.

Base idea:
- lower distance is better
- lower load is better
- area match gets bonus
- state match gets bonus

This means the final selected admin is not just the physically closest one, but the one who is likely best positioned to respond.

---

# 10. Capacity Limits

Capacity limits are important because they stop the system from endlessly overloading the same admin.

Example:
- max active assignments = 20

If current admin already has 20 or more active items:
- they can be skipped
- another qualifying admin is considered

This is a practical balancing mechanism.

---

# 11. Active / Paused Admin Mode

Admins can now be marked active or paused for assignment.

This means:
- admin can stay in the system
- but temporarily stop receiving new requests

This is useful for:
- shpfb handover
- temporary absence
- poor network
- high workload pause
- planned operational control

---

# 12. Area + State + Radius + Workload Hybrid

The system is now based on four layers working together:

## Area
Strong local neighborhood match

## State
Broad regional match

## Radius
Geographic fallback

## Workload
Operational balancing

This is much better than any one factor alone.

---

# 13. Why This Is Better Than Distance-Only

Distance-only assignment can cause:
- overload
- local imbalance
- poor customer response

Hybrid assignment gives:
- fairness
- sustainability
- better practical routing of work

---

# 14. What Happens When Admin Is Full

If admin active load >= max active assignments:
- that admin is skipped for new assignment

The system then checks other candidates.

This reduces operational congestion.

---

# 15. What Happens When Admin Is Paused

If `isActive = false`:
- admin is skipped entirely during assignment

This allows flexible staff control.

---

# 16. What Happens When No Admin Qualifies

If no admin passes:
- area/state/radius/load checks

then request may become effectively unassigned.

This is safer than assigning to the wrong admin blindly.

Future enhancement can include:
- fallback national escalation admin
- super admin fallback queue

---

# 17. Operational Benefits

This balancing system improves:

- response fairness
- scalability
- city operations
- national rollout control
- admin workload distribution
- user response time consistency

---

# 18. Admin UX Implications

Admins now have more operational control.

They can define:
- where they operate from
- what areas they cover
- how far they cover
- how much active load they should carry
- whether they are currently active

This turns the admin system into an actual operational layer.

---

# 19. Future Improvements

Recommended later:
1. weighted load by request type
2. shpfb scheduling
3. active hours
4. manual reassignment
5. dashboard load heatmap
6. escalation queue if no admin qualifies
7. historical load analytics

---

# 20. Final Summary

Nearest-admin assignment solved the first scaling problem:
- who is geographically relevant?

Workload balancing solves the next scaling problem:
- who can actually handle more work well?

Together, these two systems make the app much more realistic for national rollout in Nigeria, especially in large and dense places like Lagos.

---

# End of Part 5 Documentation
