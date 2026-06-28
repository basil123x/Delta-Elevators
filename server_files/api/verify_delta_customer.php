<?php
include("../xtras/config.php");

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
header('Content-Type: application/json; charset=utf-8');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

// Accept the phone from a form POST or a JSON body.
$input = json_decode(file_get_contents('php://input'), true);
$phone = $_POST['phone'] ?? ($input['phone'] ?? '');
$phone = trim((string)$phone);

if ($phone === '') {
    echo json_encode(['success' => false, 'message' => 'أدخل رقم الهاتف']);
    exit;
}

/**
 * Match cust_app.a2 whether the DB stores "12345678", "97412345678",
 * "+97412345678", etc. (mirrors the matching used elsewhere in the app).
 */
function deltaPhoneWhere($conx, $rawPhone)
{
    $digits = preg_replace('/\D/', '', (string)$rawPhone);
    $last8 = strlen($digits) >= 8 ? substr($digits, -8) : $digits;
    $variants = array_unique(array_filter([
        trim((string)$rawPhone),
        $digits,
        $last8,
        '974' . $last8,
        '+974' . $last8,
        '00974' . $last8,
    ], function ($v) {
        return $v !== '' && $v !== null;
    }));
    $parts = [];
    foreach ($variants as $v) {
        $e = mysqli_real_escape_string($conx, $v);
        $parts[] = "a2 = '$e'";
    }
    if (empty($parts)) {
        return '(1=0)';
    }
    return '(' . implode(' OR ', $parts) . ')';
}

// 1. Find the customer (a2 = mobile, a3 = uid).
$phoneWhere = deltaPhoneWhere($conx, $phone);
$sql = "SELECT id, a2, a3 FROM cust_app WHERE $phoneWhere LIMIT 1";
$result = $conx->query($sql);

if (!$result || $result->num_rows === 0) {
    echo json_encode([
        'success' => false,
        'message' => 'رقم الهاتف غير مسجل كعميل دلتا'
    ]);
    exit;
}

$customer = $result->fetch_assoc();
$uid = $customer['a3'];
$uidEsc = mysqli_real_escape_string($conx, $uid);

// 2. Make sure this customer has an active booking/contract.
$sql2 = "SELECT id, contract_id, addressId FROM bookings
         WHERE uid = '$uidEsc'
         AND stx = 1
         LIMIT 1";
$result2 = $conx->query($sql2);

if (!$result2 || $result2->num_rows === 0) {
    echo json_encode([
        'success' => false,
        'message' => 'لا يوجد عقد مسجل لهذا الرقم'
    ]);
    exit;
}

$booking = $result2->fetch_assoc();

echo json_encode([
    'success' => true,
    'uid' => $uid,
    'contract_id' => $booking['contract_id'],
    'address_id' => $booking['addressId'],
    'phone' => $customer['a2']
]);
