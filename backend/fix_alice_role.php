<?php
require_once 'db_config.php';

$email = 'alice.green@glaucoma.com';
$new_role = 'doctor';

try {
    $stmt = $conn->prepare("UPDATE users SET role = ? WHERE email = ?");
    $stmt->execute([$new_role, $email]);
    
    if ($stmt->rowCount() > 0) {
        echo "Successfully updated role for $email to $new_role.";
    } else {
        echo "No user found with email $email or role is already $new_role.";
    }
} catch (PDOException $e) {
    echo "Error: " . $e->getMessage();
}
?>
