<?php
require_once 'db_config.php';
header('Content-Type: application/json');

$action = isset($_GET['action']) ? $_GET['action'] : '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents('php://input'), true);

    if ($action === 'signup') {
        if (isset($data['full_name'], $data['email'], $data['password'])) {
            $full_name = $data['full_name'];
            $email = $data['email'];
            $password = password_hash($data['password'], PASSWORD_DEFAULT);
            $role = isset($data['role']) ? $data['role'] : 'patient';
            try {
                $stmt = $conn->prepare("INSERT INTO users (full_name, email, password, role) VALUES (?, ?, ?, ?)");
                $stmt->execute([$full_name, $email, $password, $role]);
                echo json_encode(["status" => "success", "message" => "User registered successfully"]);
            } catch (PDOException $e) {
                if ($e->getCode() == 23000) {
                    echo json_encode(["status" => "error", "message" => "Email already exists"]);
                } else {
                    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
                }
            }
        } else {
            echo json_encode(["status" => "error", "message" => "Missing required fields"]);
        }
    } elseif ($action === 'login') {
        if (isset($data['email'], $data['password'])) {
            $email = $data['email'];
            $password = $data['password'];

            try {
                $stmt = $conn->prepare("SELECT * FROM users WHERE email = ?");
                $stmt->execute([$email]);
                $user = $stmt->fetch(PDO::FETCH_ASSOC);

                if ($user && password_verify($password, $user['password'])) {
                    echo json_encode([
                        "status" => "success",
                        "message" => "Login successful",
                        "user" => [
                            "id" => $user['id'],
                            "full_name" => $user['full_name'],
                            "email" => $user['email'],
                            "role" => isset($user['role']) ? $user['role'] : "patient"
                        ]
                    ]);
                } else {
                    echo json_encode(["status" => "error", "message" => "Invalid email or password"]);
                }
            } catch (PDOException $e) {
                echo json_encode(["status" => "error", "message" => $e->getMessage()]);
            }
        } else {
            echo json_encode(["status" => "error", "message" => "Missing required fields"]);
        }
    } else {
        echo json_encode(["status" => "error", "message" => "Invalid action"]);
    }
} elseif ($_SERVER['REQUEST_METHOD'] === 'GET') {
    if ($action === 'fetch_doctors') {
        try {
            $stmt = $conn->prepare("SELECT id, full_name as name, role as specialty FROM users WHERE role = 'doctor'");
            $stmt->execute();
            $doctors = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            // Add mock distances/ratings since they aren't in the DB yet
            foreach ($doctors as &$doc) {
                $doc['specialty'] = 'Glaucoma Specialist';
                $doc['distance'] = (rand(5, 50) / 10) . " km";
                $doc['rating'] = 4.0 + (rand(0, 10) / 10);
            }
            
            echo json_encode(["status" => "success", "doctors" => $doctors]);
        } catch (PDOException $e) {
            echo json_encode(["status" => "error", "message" => $e->getMessage()]);
        }
    } else {
        echo json_encode(["status" => "error", "message" => "Invalid action or method"]);
    }
} else {
    echo json_encode(["status" => "error", "message" => "Invalid request method"]);
}
?>
