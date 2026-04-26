<?php
require_once 'db_config.php';
header('Content-Type: application/json');

$action = isset($_GET['action']) ? $_GET['action'] : '';

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    if ($action === 'fetch') {
        try {
            $stmt = $conn->prepare("SELECT * FROM pharmacies");
            $stmt->execute();
            $pharmacies = $stmt->fetchAll(PDO::FETCH_ASSOC);
            echo json_encode(["status" => "success", "pharmacies" => $pharmacies]);
        } catch (PDOException $e) {
            echo json_encode(["status" => "error", "message" => $e->getMessage()]);
        }
    } elseif ($action === 'populate') {
        // Create 50 mock pharmacies around Ashesi/Ghana (5.76, -0.22)
        try {
            $conn->exec("DELETE FROM pharmacies"); // Clear existing
            $stmt = $conn->prepare("INSERT INTO pharmacies (name, address, rating, lat, lng) VALUES (?, ?, ?, ?, ?)");
            
            $names = ["City", "Health", "Community", "Life", "Med", "Pulse", "Care", "Direct", "Plus", "Hill"];
            $suffixes = ["Pharmacy", "Drug Mart", "Medi-Store", "Chemists", "Healthcare"];
            
            for ($i = 1; $i <= 50; $i++) {
                $name = $names[array_rand($names)] . " " . $suffixes[array_rand($suffixes)] . " #" . $i;
                $address = "Street " . $i . ", Ghana Region";
                $rating = 3.5 + (rand(0, 15) / 10);
                // Spread them around Ashesi (5.76, -0.22)
                $lat = 5.7600 + (rand(-1000, 1000) / 10000); 
                $lng = -0.2200 + (rand(-1000, 1000) / 10000);
                
                $stmt->execute([$name, $address, $rating, $lat, $lng]);
            }
            echo json_encode(["status" => "success", "message" => "50 pharmacies populated successfully"]);
        } catch (PDOException $e) {
            echo json_encode(["status" => "error", "message" => $e->getMessage()]);
        }
    }
} else {
    echo json_encode(["status" => "error", "message" => "Invalid method"]);
}
?>
