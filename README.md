# GlaucomaDetect

**GlaucomaDetect** is a cross-platform mobile application built with Flutter for early detection of eye defects, particularly glaucoma. The app allows users to capture images of their eyes using their mobile device camera, which are then analyzed using a pretrained AI model to provide a preliminary glaucoma risk assessment, mitigation recommendations, and an option to consult an ophthalmologist.

## Core Features
The application maintains a secure history of user eye scans and allows users to share their screening records with ophthalmologists. Users can schedule consultations, receive prescriptions, and communicate with doctors through real-time in-app messaging. The system will also support in-app voice or video consultations, allowing patients and ophthalmologists to interact without leaving the application.

Push notifications will alert users about new messages, appointments, and follow-ups. With user permission, GPS functionality will help recommend nearby clinics or pharmacies for prescription fulfillment. Ophthalmologists will be able to complete structured prescription forms, automatically generate them as PDF documents, and share them with patients while maintaining consultation records.

## Local Resources Featured
The app fulfills course requirements by implementing the following local device resources:
1. **Camera:** For capturing eye images for AI screening.
2. **GPS/Geolocation:** For clinic and pharmacy recommendations based on the user's current location.
3. **Push Notifications:** For alerts regarding messages, appointment reminders, and follow-ups.
4. **Local Storage:** For the history of user eye scans, session management, and prescription storage.
5. **In-app Messaging and Calls:** For real-time patient and doctor interactions and remote consultations.

## Architecture & Logic (Simulated for Coursework)
*Note: Due to the scope of the project, certain backend AI and real-time network features are simulated using hardcoded logic.*
- **AI Assessment:** The result (positive/negative) is simulated based on the uploaded image. A negative result suggests a check-up in 3-6 months. A positive result prompts booking a consultation.
- **Pharmacies/Clinics:** Recommendations use real GPS data to calculate distances to a predefined, hardcoded list of pharmacies.
- **Backend:** A lightweight PHP/MySQL backend (`auth.php`, `appointments.php`, `detect.php`) handles user roles (patient/doctor), mock AI detection, and data persistence.
