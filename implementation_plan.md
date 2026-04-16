# Implementation Plan - Glaucoma Detect Redesign & PHP Backend

This plan outlines the steps to introduce a PHP backend for image processing, redesign the application's home experience to look professional, and implement a flexible image acquisition system (embedded camera and file picker).

## User Review Required

> [!IMPORTANT]
> **PHP Environment**: The backend will be hosted at `http://169.239.251.102:280/~chika.amanna/`. I will ensure all API calls point to this specific endpoint.
> **Home Screen Aesthetic**: I will move the app from a dark-only theme to a professional Blue/White aesthetic as shown in your reference image.
> **Packages**: I will add `image_picker` for file uploads and `table_calendar` for the appointment scheduling feature.

## Proposed Changes

Location: `http://169.239.251.102:280/~chika.amanna/glaucoma_backend/`

#### [NEW] [detect.php](file:///C:/Users/HP/Mobile_App/glaucoma_detect/backend/detect.php)
- Handle image uploads and return diagnostic results. Hosted at `.../glaucoma_backend/detect.php`.

#### [NEW] [appointments.php](file:///C:/Users/HP/Mobile_App/glaucoma_detect/backend/appointments.php)
- Handle booking sessions. Hosted at `.../glaucoma_backend/appointments.php`.

---

### Flutter UI & Navigation Redesign

#### [NEW] [home_dashboard.dart](file:///C:/Users/HP/Mobile_App/glaucoma_detect/lib/screens/home_dashboard.dart)
- **High-Fidelity Dashboard** (Mockup-matched):
  - User header with profile image and notification badges.
  - Custom Search bar with filter icon.
  - "Medical Checks!" featured banner with quick "Check Now" access.
  - "Doctor Specialty" horizontally scrollable/grid categories (Ophthalmology, etc.).
  - "Top Doctors" vertical list with category filters.

#### [NEW] [doctor_detail.dart](file:///C:/Users/HP/Mobile_App/glaucoma_detect/lib/screens/doctor_detail.dart)
- Detailed view of a doctor with bio and specialty.
- **Appointment Booking**: Integrated calendar widget for selecting consultation dates/times.

#### [NEW] [scan_detail.dart](file:///C:/Users/HP/Mobile_App/glaucoma_detect/lib/screens/scan_detail.dart)
- A dedicated page to view full details of a past scan, accessible from the History tab.

#### [MODIFY] [scan_history.dart](file:///C:/Users/HP/Mobile_App/glaucoma_detect/lib/screens/scan_history.dart)
- Enable tapping on history items to open `ScanDetailScreen`.

#### [MODIFY] [recommendations.dart](file:///C:/Users/HP/Mobile_App/glaucoma_detect/lib/screens/recommendations.dart)
- Fix text overflow in doctor cards.
- Link doctor cards to the new `DoctorDetailScreen`.

#### [MODIFY] [pubspec.yaml](file:///C:/Users/HP/Mobile_App/glaucoma_detect/pubspec.yaml)
- Add `image_picker` and `table_calendar`.

---

## Logic Explanation: Image Capturing & Detection

1. **Capturing (Flutter Client)**:
   - **Live Camera**: Uses the `camera` package to provide a real-time viewfinder. The user clicks a trigger which executes `takePicture()`.
   - **File Picker**: Uses `image_picker` to let the user select a high-resolution photo from their phone's storage.
2. **Transmission (Networking)**:
   - The selected image is processed into a `MultipartFile`.
   - A `POST` request is sent to `http://your-server/backend/detect.php`.
3. **Detection (PHP Backend)**:
   - The server validates that a valid image was uploaded.
   - The image is passed to a diagnostic function (placeholder for ML model).
   - The script calculates a `risk_score` based on visual parameters (simulated for now).
4. **Response & Display**:
   - PHP returns a JSON object (e.g., `{"status": "success", "prediction": "Glaucoma Detected", "risk": 0.85}`).
   - Flutter parses this JSON and displays a detailed diagnostic report to the user.

## Open Questions

- What is the URL/address of the PHP server where you plan to host the backend files? (e.g., `http://192.168.1.5/glaucoma_backend/` or a local domain).
- Do you have a specific "Home Screen" reference or layout you prefer (e.g., Apple Health style, minimalist medical dashboard)?

## Verification Plan

### Automated Tests
- Build and run the app to ensure no compilation errors after adding `image_picker`.
- Check that the `backend/` folder and files are correctly created in the project root.

### Manual Verification
- Verify the new Dashboard layout appears professional on launch.
- Test the "Pick from Gallery" functionality.
- Verify that the app attempts to connect to the PHP backend (I will use a placeholder URL that you can configure).
