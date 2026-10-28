# campusCRM

Cross-platform (Web and Mobile) management system designed for non-technical owners of small teaching institutes, built with **Flutter**, **Riverpod**, and **Firebase Cloud Firestore** (offline-first).

## Live Demo
- **Web App (GitHub Pages):** [https://ambekaraditya.github.io/campuscrm/](https://ambekaraditya.github.io/campuscrm/)

## Core Features
1. **Home Dashboard (`lib/features/dashboard`)**:
   - "Today's Classes" list view
   - "Action Items" alert banner (overdue payments, new leads)
   - Prominent "Mark Daily Attendance" floating action button with interactive attendance sheet
2. **Inquiries & Lead Management (`lib/features/inquiries`)**:
   - `InquiryCard` displaying Name, Area/City, high-visibility color-coded Status Dropdown (`New`, `Follow-Up`, `Trial Scheduled`, `Joined`, `Not Interested`), and Remarks `TextField`
   - 1-Click action buttons via `url_launcher`: Call (`tel:`), WhatsApp (`https://wa.me/`), Email (`mailto:`), and Google Maps (`https://maps.google.com/?q=`)
3. **Students & Batches (`lib/features/academics`)**:
   - `BatchListView` displaying active cohorts
   - `StudentProfileScreen` with contact info, assigned batch, attendance record, and "Generate Certificate" action
4. **Payments Ledger (`lib/features/payments`)**:
   - "Due This Week" ledger with progress bar for Total Fee vs. Amount Paid
   - "Record Payment" form capturing Student, Amount, Payment Method (`UPI`/`Cash`), and Date
5. **Bookings & Appointments (`lib/features/bookings`)**:
   - Daily time-slot UI and `BookingCard` for 1-on-1 sessions, shared rooms, or models
6. **Materials & Inventory (`lib/features/inventory`)**:
   - Stock item list with automatic red highlight when `Quantity < 5`
   - Checkbox list for assigning "Student Kits"
7. **Admin & Staff Permissions (`lib/features/admin`)**:
   - `StaffListView` and `AddStaffForm` (with 4-digit login PIN)
   - `PermissionsToggleScreen` (`canViewMoney`, `canEditStudents`, `canMarkAttendance`, `canManageInventory`)
   - Real-time `ActivityFeedView` backed by Firestore `activity_logs`
