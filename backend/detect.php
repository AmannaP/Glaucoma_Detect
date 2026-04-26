<?php
header('Content-Type: application/json');

// Mock Glaucoma Detection API
// Hosted at: http://169.239.251.102:280/~chika.amanna/glaucoma_backend/detect.php

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (isset($_FILES['image'])) {
        $file = $_FILES['image'];
        
        // Check for PHP upload errors
        if ($file['error'] !== UPLOAD_ERR_OK) {
            $errorMessages = [
                UPLOAD_ERR_INI_SIZE => 'The uploaded file exceeds the upload_max_filesize directive in php.ini.',
                UPLOAD_ERR_FORM_SIZE => 'The uploaded file exceeds the MAX_FILE_SIZE directive that was specified in the HTML form.',
                UPLOAD_ERR_PARTIAL => 'The uploaded file was only partially uploaded.',
                UPLOAD_ERR_NO_FILE => 'No file was uploaded.',
                UPLOAD_ERR_NO_TMP_DIR => 'Missing a temporary folder.',
                UPLOAD_ERR_CANT_WRITE => 'Failed to write file to disk.',
                UPLOAD_ERR_EXTENSION => 'A PHP extension stopped the file upload.',
            ];
            $msg = isset($errorMessages[$file['error']]) ? $errorMessages[$file['error']] : 'Unknown upload error.';
            echo json_encode(["status" => "error", "message" => "Upload Error: $msg"]);
            exit;
        }

        $uploadDir = 'uploads/';
        
        if (!is_dir($uploadDir)) {
            if (!mkdir($uploadDir, 0777, true)) {
                echo json_encode(["status" => "error", "message" => "Failed to create upload directory: $uploadDir. Check permissions."]);
                exit;
            }
        }

        $fileName = time() . '_' . basename($file['name']);
        $targetFile = $uploadDir . $fileName;

        if (move_uploaded_file($file['tmp_name'], $targetFile)) {
            // Simulated ML Analysis
            $riskScore = rand(10, 95) / 100;
            $hasGlaucoma = $riskScore > 0.6;
            $types = ["Open-angle", "Angle-closure", "Normal-tension"];
            $type = $hasGlaucoma ? $types[array_rand($types)] : "None";

            // Mock Image Verification (Smart Scanning)
            // In a real app, this would use a computer vision model to verify it's an eye.
            // For simulation, we check if the file is extremely small or has a specific pattern.
            $image_size = $_FILES['image']['size'];
            if ($image_size < 1024) { // Simulated check for invalid/placeholder images
                echo json_encode([
                    "status" => "error",
                    "message" => "Invalid Image: The AI could not detect a human eye in this picture. Please retake the photo in a well-lit area."
                ]);
                exit;
            }

            // AI Simulation logic
            $prediction_options = ["Glaucoma Detected", "Healthy Eye"];

            echo json_encode([
                "status" => "success",
                "message" => "Image analyzed successfully",
                "prediction" => $hasGlaucoma ? "Glaucoma Detected" : "Healthy Eye",
                "risk_score" => $riskScore,
                "glaucoma_type" => $type,
                "timestamp" => date('Y-m-d H:i:s')
            ]);
        } else {
            $isWritable = is_writable($uploadDir) ? 'Yes' : 'No';
            $exists = file_exists($file['tmp_name']) ? 'Yes' : 'No';
            echo json_encode([
                "status" => "error", 
                "message" => "Failed to move uploaded file. Directory writable: $isWritable. Temp file exists: $exists."
            ]);
        }
    } else {
        echo json_encode(["status" => "error", "message" => "No image file uploaded."]);
    }
} else {
    echo json_encode(["status" => "error", "message" => "Invalid request method. Use POST."]);
}
?>
