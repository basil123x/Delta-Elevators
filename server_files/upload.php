<?
header('Content-Type: application/json');
include("xtras/config.php");
// تحقق من وجود الملف
if (!isset($_FILES['file'])) {
    echo json_encode(['success' => false, 'message' => 'No file uploaded']);
    exit;
}

$file = $_FILES['file'];
$id = $_POST['id'] ?? '';
$booking_id = $_POST['booking_id'] ?? '';

// مجلد الرفع
$uploadDir = 'uploads/contracts/';
if (!is_dir($uploadDir)) {
    mkdir($uploadDir, 0777, true);
}

// تحقق من نوع الملف
$allowedTypes = ['application/pdf'];
if (!in_array($file['type'], $allowedTypes)) {
    echo json_encode(['success' => false, 'message' => 'Only PDF files allowed']);
    exit;
}

// اسم الملف الجديد
$fileName = 'contract_' . $id . '.pdf';
$targetPath = $uploadDir . $fileName;

// انقل الملف
if (move_uploaded_file($file['tmp_name'], $targetPath)) {
    // احفظ في قاعدة البيانات (اختياري)
    $conx->query("UPDATE bookings SET contract_id = '$id',stt='1' WHERE id='$booking_id' ");
    
    echo json_encode([
        'success' => true,
        'message' => 'File uploaded successfully',
        'file_path' => $targetPath,
        'file_name' => $fileName
    ]);
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Failed to upload file'
    ]);
}
?>