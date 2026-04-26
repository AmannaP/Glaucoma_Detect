<?php
$ch = curl_init('http://169.239.251.102:280/~chika.amanna/Glaucoma_Detect/backend/auth.php?action=login');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode([
    'email' => 'alice.green@glaucoma.com',
    'password' => 'doctor123'
]));
$response = curl_exec($ch);
echo "Response: " . $response . "\n";
?>
