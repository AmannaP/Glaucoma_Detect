<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST');

require_once 'db_config.php';

$method = $_SERVER['REQUEST_METHOD'];
$action = isset($_GET['action']) ? $_GET['action'] : '';

// Helper function to get user ID by name
function getUserIdByName($conn, $name) {
    $stmt = $conn->prepare("SELECT id FROM users WHERE full_name = ? LIMIT 1");
    $stmt->execute([$name]);
    $result = $stmt->fetch(PDO::FETCH_ASSOC);
    return $result ? $result['id'] : null;
}

if ($method === 'GET' && $action === 'fetch') {
    // Fetch messages between two users
    $user_id = isset($_GET['user_id']) ? intval($_GET['user_id']) : null;
    $other_name = isset($_GET['other_name']) ? $_GET['other_name'] : null;

    if (!$user_id || !$other_name) {
        echo json_encode(["status" => "error", "message" => "Missing user_id or other_name"]);
        exit;
    }

    $other_id = getUserIdByName($conn, $other_name);
    if (!$other_id) {
        echo json_encode(["status" => "success", "messages" => []]); // No chat history if user doesn't exist
        exit;
    }

    try {
        $stmt = $conn->prepare("
            SELECT m.*, 
                   s.full_name as sender_name, 
                   r.full_name as receiver_name 
            FROM messages m
            JOIN users s ON m.sender_id = s.id
            JOIN users r ON m.receiver_id = r.id
            WHERE (m.sender_id = ? AND m.receiver_id = ?) 
               OR (m.sender_id = ? AND m.receiver_id = ?)
            ORDER BY m.created_at ASC
        ");
        $stmt->execute([$user_id, $other_id, $other_id, $user_id]);
        $messages = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        echo json_encode([
            "status" => "success", 
            "messages" => $messages,
            "other_id" => $other_id
        ]);
    } catch (PDOException $e) {
        echo json_encode(["status" => "error", "message" => $e->getMessage()]);
    }

} elseif ($method === 'POST' && $action === 'send') {
    // Send a new message
    $data = json_decode(file_get_contents("php://input"), true);
    
    $sender_id = isset($data['sender_id']) ? intval($data['sender_id']) : null;
    $receiver_name = isset($data['receiver_name']) ? $data['receiver_name'] : null;
    $message = isset($data['message']) ? trim($data['message']) : '';

    if (!$sender_id || !$receiver_name || empty($message)) {
        echo json_encode(["status" => "error", "message" => "Missing required fields"]);
        exit;
    }

    $receiver_id = getUserIdByName($conn, $receiver_name);
    if (!$receiver_id) {
        echo json_encode(["status" => "error", "message" => "Receiver not found"]);
        exit;
    }

    try {
        $stmt = $conn->prepare("INSERT INTO messages (sender_id, receiver_id, message) VALUES (?, ?, ?)");
        $stmt->execute([$sender_id, $receiver_id, $message]);
        
        echo json_encode([
            "status" => "success", 
            "message" => "Message sent successfully",
            "message_id" => $conn->lastInsertId()
        ]);
    } catch (PDOException $e) {
        echo json_encode(["status" => "error", "message" => $e->getMessage()]);
    }

} else {
    echo json_encode(["status" => "error", "message" => "Invalid request method or action"]);
}
?>
