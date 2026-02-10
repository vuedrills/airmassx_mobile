# Mobile App Feature Parity Plan (Revised)

**Goal:** Ensure the Flutter mobile app has feature parity with the Next.js web app.

**Last Updated:** December 23, 2024

---

## ✅ Completed Items

### 1. Offers Not Appearing - FIXED ✅
**Root Cause:** Docker container was running old code without the `/tasks/:id/offers` route.
**Solution:** Rebuilt Docker container with `docker-compose down && docker-compose up -d --build`

### 2. Equipment Post Request - IMPLEMENTED ✅
Created a new 4-step equipment request wizard at `lib/screens/equipment/post_equipment_request_screen.dart`:

- **Step 1: Machine Specs**
  - Equipment type dropdown (20+ equipment categories)
  - Capacity/size picker (based on equipment type)
  - Job description

- **Step 2: Location**
  - Location text input
  - Map for pin selection

- **Step 3: Timing & Budget**
  - Hire duration type (hourly/daily/weekly/monthly)
  - Estimated hours/duration
  - Operator preference (required/preferred/dry hire)
  - Date selection (flexible or specific)
  - Budget input
  - Fuel included toggle

- **Step 4: Review**
  - Summary of all fields
  - Submit button

### 3. Equipment Constants - ADDED ✅
Created `lib/constants/equipment.dart` with:
- Equipment categories list
- Hire duration type enum
- Operator preference enum
- Equipment capacity model and presets

### 4. CreateTask State/Events/Bloc - UPDATED ✅
Added equipment-specific fields:
- `taskType` ('service' or 'equipment')
- `hireDurationType`
- `estimatedHours` / `estimatedDuration`
- `operatorPreference`
- `fuelIncluded`
- `requiredCapacityId`

---

## 🔄 In Progress

### WebSocket Reconnection Loop ⚠️
**Status:** Known issue - WebSocket connects/disconnects in a loop
**Impact:** Real-time updates may not work properly
**Next Steps:** Investigate WebSocket implementation in RealtimeService

---

## ⏳ Remaining Items

### Tasker Onboarding Wizard ❌ NOT STARTED
**Web App Has:**
- Step 1: Basic Information (name, phone, bio)
- Step 2: Identity Verification (ID upload, selfie)
- Step 3: Professions Selection
- Step 4: Portfolio Upload
- Step 5: Qualifications/Certificates
- Step 6: Availability Schedule

**Mobile Needs:**
- [ ] Multi-step wizard navigation
- [ ] File upload component (camera/gallery)
- [ ] Profession selector
- [ ] Weekly availability grid
- [ ] Certificate upload
- [ ] API integration with `/tasker/profile` and `/tasker/upload-metadata`

### Review System ❌ NOT STARTED
**Web App Has:**
- Multi-rating (communication, time, professionalism)
- Comment text
- Reply to reviews
- Force review after task completion

**Mobile Needs:**
- [ ] Create review screen/modal
- [ ] Star rating component (3 categories)
- [ ] Reviews list on profile
- [ ] Reply to review

### Task Completion Flow ❌ NOT STARTED
**Web App Has:**
- Complete task button (for taskers)
- Review modal trigger (for posters)
- Invoice display
- Escrow status

**Mobile Needs:**
- [ ] Complete task action for taskers
- [ ] Review prompt for posters
- [ ] Invoice/escrow display

### Profile Enhancements 🟡 PARTIAL
**Missing:**
- [ ] Tasker verification badge
- [ ] Portfolio gallery section
- [ ] Qualifications display
- [ ] Availability schedule display
- [ ] Reviews breakdown by category

### Notifications Enhancement 🟡 PARTIAL
**Missing:**
- [ ] Mark All as Read
- [ ] Notification grouping
- [ ] Rich notification display

---

## Files Created/Modified

### New Files Created
| File | Description |
|------|-------------|
| `lib/constants/equipment.dart` | Equipment categories, enums, capacity presets |
| `lib/screens/equipment/post_equipment_request_screen.dart` | 4-step equipment request wizard |

### Files Modified
| File | Changes |
|------|---------|
| `lib/bloc/create_task/create_task_state.dart` | Added equipment fields |
| `lib/bloc/create_task/create_task_event.dart` | Added equipment events |
| `lib/bloc/create_task/create_task_bloc.dart` | Added equipment handlers |
| `lib/screens/equipment/browse_equipment_screen.dart` | FAB navigates to new screen |
| `lib/services/api_service.dart` | Added debug logging for offers |

---

## API Endpoints Status

### Working ✅
- `GET /tasks/:id/offers` - NOW WORKING (after Docker rebuild)
- `POST /tasks` - Now includes equipment fields
- All auth, task, conversation, notification endpoints

### Need to Implement ❌
- `GET /equipment-capacities` - For dynamic capacity lists
- `GET /inventory` - For user's equipment inventory
- `POST /inventory` - Create inventory item
- `POST /tasker/profile` - Update tasker profile
- `POST /reviews` - Create review
- `POST /tasks/:id/complete` - Complete task

---

## Next Priority

1. **Fix WebSocket Loop** - Investigate and fix the reconnection issue
2. **Tasker Onboarding** - Multi-step wizard for becoming a tasker
3. **Review System** - Rating modal and review display
4. **Task Completion** - Complete/review flow after task is done
