<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");
header("Access-Control-Allow-Methods: GET, PUT, POST");
header("Access-Control-Allow-Headers: Content-Type");

include("../config/db_connect.php");

$method = $_SERVER['REQUEST_METHOD'];
$response = array();

// Get action from query string
$action = isset($_GET['action']) ? $_GET['action'] : '';

if ($method === 'GET') {
    $user_id = isset($_GET['user_id']) ? intval($_GET['user_id']) : 0;
    $user_type = isset($_GET['user_type']) ? $_GET['user_type'] : '';
    
    if (!$user_id || !$user_type) {
        echo json_encode(["success" => 0, "message" => "Missing parameters"]);
        exit;
    }
    
    if ($action === 'stats') {
        // Get notification stats
        $sql = "SELECT 
                    COUNT(*) as total,
                    SUM(CASE WHEN is_read = 0 THEN 1 ELSE 0 END) as unread
                FROM notifications 
                WHERE user_id = ? AND user_type = ?";
        $stmt = $pdo->prepare($sql);
        $stmt->execute([$user_id, $user_type]);
        $stats = $stmt->fetch(PDO::FETCH_ASSOC);
        
        // Get counts by type
        $sql = "SELECT type, COUNT(*) as count 
                FROM notifications 
                WHERE user_id = ? AND user_type = ? 
                GROUP BY type";
        $stmt = $pdo->prepare($sql);
        $stmt->execute([$user_id, $user_type]);
        $byType = [];
        while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
            $byType[$row['type']] = $row['count'];
        }
        
        $response["success"] = 1;
        $response["stats"] = [
            "total" => intval($stats['total']),
            "unread" => intval($stats['unread']),
            "by_type" => $byType
        ];
        echo json_encode($response);
        exit;
    }
    
    // Get all notifications
    $sql = "SELECT * FROM notifications 
            WHERE user_id = ? AND user_type = ? 
            ORDER BY created_at DESC";
    $stmt = $pdo->prepare($sql);
    $stmt->execute([$user_id, $user_type]);
    $notifications = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Get stats
    $sql = "SELECT 
                COUNT(*) as total,
                SUM(CASE WHEN is_read = 0 THEN 1 ELSE 0 END) as unread
            FROM notifications 
            WHERE user_id = ? AND user_type = ?";
    $stmt = $pdo->prepare($sql);
    $stmt->execute([$user_id, $user_type]);
    $stats = $stmt->fetch(PDO::FETCH_ASSOC);
    
    $response["success"] = 1;
    $response["data"] = $notifications;
    $response["stats"] = [
        "total" => intval($stats['total']),
        "unread" => intval($stats['unread'])
    ];
    echo json_encode($response);
    
} elseif ($method === 'PUT') {
    // Mark notification(s) as read
    $input = json_decode(file_get_contents('php://input'), true);
    
    if ($action === 'mark_all') {
        // Mark all as read
        $user_id = isset($input['user_id']) ? intval($input['user_id']) : 0;
        $user_type = isset($input['user_type']) ? $input['user_type'] : '';
        
        $sql = "UPDATE notifications 
                SET is_read = 1 
                WHERE user_id = ? AND user_type = ? AND is_read = 0";
        $stmt = $pdo->prepare($sql);
        $stmt->execute([$user_id, $user_type]);
        
        $response["success"] = 1;
        $response["message"] = "All notifications marked as read";
        echo json_encode($response);
        exit;
    }
    
    // Mark single notification as read
    $id = isset($input['id']) ? intval($input['id']) : 0;
    $is_read = isset($input['is_read']) ? intval($input['is_read']) : 1;
    
    $sql = "UPDATE notifications SET is_read = ? WHERE id = ?";
    $stmt = $pdo->prepare($sql);
    $stmt->execute([$is_read, $id]);
    
    $response["success"] = 1;
    $response["message"] = "Notification updated";
    echo json_encode($response);
    
} elseif ($method === 'POST') {
    // Create notification (can be called from other services)
    $input = json_decode(file_get_contents('php://input'), true);
    
    $user_id = isset($input['user_id']) ? intval($input['user_id']) : 0;
    $user_type = isset($input['user_type']) ? $input['user_type'] : '';
    $title = isset($input['title']) ? $input['title'] : '';
    $message = isset($input['message']) ? $input['message'] : '';
    $type = isset($input['type']) ? $input['type'] : 'info';
    
    $sql = "INSERT INTO notifications (user_id, user_type, title, message, type, is_read, created_at) 
            VALUES (?, ?, ?, ?, ?, 0, NOW())";
    $stmt = $pdo->prepare($sql);
    $stmt->execute([$user_id, $user_type, $title, $message, $type]);
    
    $response["success"] = 1;
    $response["message"] = "Notification created";
    $response["id"] = $pdo->lastInsertId();
    echo json_encode($response);
}

?>