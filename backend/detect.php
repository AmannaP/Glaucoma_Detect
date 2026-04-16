<?php
header('Content-Type: application/json');

// Mock Glaucoma Detection API
// Hosted at: http://169.239.251.102:280/~chika.amanna/glaucoma_backend/detect.php

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (isset($_FILES['image'])) {
        $file = $_FILES['image'];
        $uploadDir = 'uploads/';
        
        if (!is_dir($uploadDir)) {
            mkdir($uploadDir, 0777, true);
        }

        $fileName = time() . '_' . basename($file['name']);
        $targetFile = $uploadDir . $fileName;

        if (move_uploaded_file($file['tmp_name'], $targetFile)) {
            // Simulated ML Analysis
            $riskScore = rand(10, 95) / 100;
            $hasGlaucoma = $riskScore > 0.6;
            $types = ["Open-angle", "Angle-closure", "Normal-tension"];
            $type = $hasGlaucoma ? $types[array_rand($types)] : "None";

            echo json_encode([
                "status" => "success",
                "message" => "Image analyzed successfully",
                "prediction" => $hasGlaucoma ? "Glaucoma Detected" : "Healthy Eye",
                "risk_score" => $riskScore,
                "glaucoma_type" => $type,
                "timestamp" => date('Y-m-d H:i:s')
            ]);
        } else {
            echo json_encode(["status" => "error", "message" => "Failed to move uploaded file."]);
        }
    } else {
        echo json_encode(["status" => "error", "message" => "No image file uploaded."]);
    }
} else {
    echo json_encode(["status" => "error", "message" => "Invalid request method. Use POST."]);
}
?>
