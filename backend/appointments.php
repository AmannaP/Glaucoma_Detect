<?php
require_once 'db_config.php';
header('Content-Type: application/json');

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'POST') {
    $data = json_decode(file_get_contents('php://input'), true);

    if (isset($data['user_id'], $data['doctor_name'], $data['specialty'], $data['date'], $data['time'])) {
        $user_id = $data['user_id'];
        $doctor_name = $data['doctor_name'];
        $specialty = $data['specialty'];
        $date = $data['date'];
        $time = $data['time'];

        try {
            // Check if user already has an appointment at this time
            $check = $conn->prepare("SELECT id FROM appointments WHERE user_id = ? AND date = ? AND time = ?");
            $check->execute([$user_id, $date, $time]);
            if ($check->fetch()) {
                echo json_encode(["status" => "error", "message" => "You already have an appointment at this time."]);
                exit;
            }

            $stmt = $conn->prepare("INSERT INTO appointments (user_id, doctor_name, specialty, date, time) VALUES (?, ?, ?, ?, ?)");
            $stmt->execute([$user_id, $doctor_name, $specialty, $date, $time]);
            echo json_encode(["status" => "success", "message" => "Appointment booked successfully"]);
        } catch (PDOException $e) {
            echo json_encode(["status" => "error", "message" => $e->getMessage()]);
        }
    } else {
        echo json_encode(["status" => "error", "message" => "Missing required fields"]);
    }
} elseif ($method === 'GET') {
    if (isset($_GET['user_id'])) {
        // Fetch appointments for a specific user
        $user_id = $_GET['user_id'];
        try {
            $stmt = $conn->prepare("SELECT * FROM appointments WHERE user_id = ? ORDER BY date DESC, time DESC");
            $stmt->execute([$user_id]);
            $appointments = $stmt->fetchAll(PDO::FETCH_ASSOC);
            echo json_encode(["status" => "success", "appointments" => $appointments]);
        } catch (PDOException $e) {
            echo json_encode(["status" => "error", "message" => $e->getMessage()]);
        }
    } elseif (isset($_GET['doctor_name'], $_GET['date'])) {
        // Fetch busy slots for a doctor on a specific date
        $doctor_name = $_GET['doctor_name'];
        $date = $_GET['date'];
        try {
            $stmt = $conn->prepare("SELECT time FROM appointments WHERE doctor_name = ? AND date = ?");
            $stmt->execute([$doctor_name, $date]);
            $busy_slots = $stmt->fetchAll(PDO::FETCH_COLUMN);
            echo json_encode(["status" => "success", "busy_slots" => $busy_slots]);
        } catch (PDOException $e) {
            echo json_encode(["status" => "error", "message" => $e->getMessage()]);
        }
    } else {
        echo json_encode(["status" => "error", "message" => "Missing user_id or doctor_name/date"]);
    }
} else {
    echo json_encode(["status" => "error", "message" => "Invalid request method"]);
}
?>
