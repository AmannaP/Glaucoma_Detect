<?php
header('Content-Type: application/json');

// Mock Appointment Booking API
// Hosted at: http://169.239.251.102:280/~chika.amanna/glaucoma_backend/appointments.php

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents('php://input'), true);

    if (isset($data['doctor_id'], $data['date'], $data['time'])) {
        // Here we would normally save to a database
        echo json_encode([
            "status" => "success",
            "message" => "Appointment booked successfully",
            "appointment_id" => uniqid(),
            "details" => $data
        ]);
    } else {
        echo json_encode(["status" => "error", "message" => "Missing required fields (doctor_id, date, time)."]);
    }
} else {
    echo json_encode(["status" => "error", "message" => "Invalid request method. Use POST."]);
}
?>
