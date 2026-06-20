# Mix App Super Admin Analytics Documentation
## Sales, Movement, State, Area, and Admin Performance Intelligence

---

# Purpose

This document explains the super admin analytics layer added to the Mix app.

The goal is to give super admin visibility into:
- sales
- order activity
- ride activity
- delivery activity
- escalations
- reassignments
- admin performance
- state performance
- area performance
- time-based performance windows

This is important because the app is no longer a simple local app.
It is becoming a multi-admin, multi-area, Nigeria-wide operational platform.

---

# What the Analytics Dashboard Shows

## Top Summary Metrics
The dashboard currently shows:
- Total Sales
- Delivered Orders
- All Orders
- Total Admins
- Total Rides
- Total Deliveries
- Escalations
- Reassignments

---

# Time Range Filtering

A major improvement now included is time-range filtering.

Super admin can now switch analytics to view:

- Today
- Last 7 Days
- Last 30 Days
- All Time

This is very important because national operations are not only about totals.
They are about trend and recency.

Examples of use:
- how much did Surulere make today?
- how many deliveries happened this week in Lagos?
- which admin handled the most orders in the last 30 days?
- how many escalations happened today?

---

# Sales Intelligence

## Sales by Admin
This shows how much delivered order value has been handled by each admin.

This helps answer:
- which admin is generating the most fulfilled value?
- which operational region is performing better?

## Sales by State
This groups delivered order revenue by assigned admin state.

This helps answer:
- which states are performing best?

## Sales by Area
This groups delivered order revenue by assigned admin area.

This helps answer:
- which Lagos areas, Abuja areas, etc. are strongest?

---

# Movement Intelligence

## Orders by Admin
Shows how many total orders are associated with each admin.

## Rides by Admin
Shows how many transport rides each admin handled.

## Deliveries by Admin
Shows how many delivery rides each admin handled.

These metrics help measure actual operational load.

---

# Reassignment Intelligence

## Manual Reassignments by Admin
This shows reassignment count grouped by the final assigned admin.

This helps answer:
- which admins are taking over problem requests?
- where is the system relying more on manual overrides?

---

# Why This Matters

The app now supports:
- location-based admin assignment
- area/state matching
- workload balancing
- super admin escalation fallback
- manual reassignment
- super admin escalation dashboard
- notification flow for assignments/escalations

That means super admin needs visibility across all of this.

Without analytics:
- super admin cannot easily understand operational performance
- region strengths and weaknesses stay hidden
- overload and imbalance are harder to detect

---

# Current Data Sources

The analytics dashboard currently uses:
- orders collection
- rides collection
- admins collection

It reads existing fields such as:
- assignedAdminName
- assignedAdminState
- assignedAdminArea
- assignmentMethod
- escalatedToSuperAdmin
- status
- totalAmount
- createdAt

---

# Important Current Interpretation Rules

## Total Sales
Calculated only from delivered orders.

## Sales by Admin/State/Area
Calculated from delivered orders only.

## Orders by Admin
Counts all filtered orders linked to an admin.

## Rides by Admin
Counts filtered movement records of type `ride`.

## Deliveries by Admin
Counts filtered movement records of type `delivery`.

## Reassignments
Counts filtered records marked with assignment method `manual_reassignment`.

---

# Time Range Logic

## Today
Shows only records created from the start of the current day.

## Last 7 Days
Shows records from the last 7 days.

## Last 30 Days
Shows records from the last 30 days.

## All Time
Shows everything.

This allows super admin to compare:
- short-term pulse
- weekly trends
- monthly performance
- total historical performance

---

# Why This Is Useful for Your Use Case

You specifically wanted things like:
- how many sales admin in Surulere made
- how many sales admin in Central Lagos made
- movement by admin/state/area

This dashboard is the first serious version of that.

And now because time filtering exists, it can answer not only:
- total ever

but also:
- today
- this week
- this month

---

# Future Improvements Recommended

The current dashboard is already useful, but future improvements can make it much stronger.

Recommended next upgrades:
1. charts over time
2. custom date range picker
3. state filter dropdown
4. admin filter dropdown
5. average order value by admin
6. cancellation rate by admin
7. completion rate by admin
8. escalation rate by state/area
9. active load trend
10. fulfilled delivery fee totals separate from order totals
11. daily/weekly comparison cards
12. top-performing areas trend chart

---

# Long-Term Vision

As Mix grows, this analytics dashboard can become the central national operations intelligence screen.

That means super admin could later use it to answer:
- which state needs more admins?
- which area has too many escalations?
- which admins are overloaded?
- which areas are generating the most sales?
- where should marketing spend be focused?
- where should delivery expansion happen next?
- which zones need more local operational coverage?
- which admin teams are underperforming this week?

---

# Final Summary

The super admin analytics dashboard is the first real intelligence dashboard in Mix.

It transforms the project from:
- just operational management

into:
- measurable operational strategy

And with time filtering, it becomes much more practical for real business decisions.

This is one of the most important steps for scaling the app nationally.

