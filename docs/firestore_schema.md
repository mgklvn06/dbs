# Firestore Schema (Role Based)

This project uses three primary collections. All writes are admin-only in `firestore.rules`.

## users/{uid}
- uid: string
- email: string
- displayName: string
- photoUrl: string? (also stored as avatarUrl for backward compatibility)
- role: "user" | "doctor" | "admin"
- status: "active" | "suspended"
- createdAt: timestamp
- lastLoginAt: timestamp
- updatedAt: timestamp

## doctors/{doctorId}
- userId: string
- name: string
- specialty: string
- bio: string?
- email: string?
- photoUrl: string?
- isActive: bool
- createdAt: timestamp
- updatedAt: timestamp

## appointments/{appointmentId}
- userId: string
- doctorId: string
- appointmentTime: timestamp
- slotId: string? (optional)
- status: "pending" | "confirmed" | "completed" | "cancelled" (app also accepts accepted/rejected)
- createdAt: timestamp
- updatedAt: timestamp

## availability/{doctorId}/slots/{slotId}
- startTime: timestamp
- endTime: timestamp
- isBooked: bool
- bookedBy: string? (uid)
- bookedAt: timestamp?

## roles/{roleName}
- description: string
- permissions: array<string>

## Indexes
- appointments by doctorId + dateTime
- appointments by userId + dateTime
