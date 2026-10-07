<?php
include("../xtras/config.php");

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
header('Content-Type: application/json; charset=utf-8');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

$input = json_decode(file_get_contents('php://input'), true);
$phone = $_POST['phone'] ?? ($input['phone'] ?? '');
$phone = trim((string)$phone);

if ($phone === '') {
    echo json_encode(['success' => false, 'message' => 'أدخل رقم الهاتف']);
    exit;
}

/**
 * Build OR conditions for a phone column against common Qatar formats.
 */
function deltaPhoneWhere($conx, $column, $rawPhone)
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
        $parts[] = "$column = '$e'";
    }
    if (empty($parts)) {
        return '(1=0)';
    }
    return '(' . implode(' OR ', $parts) . ')';
}

// 1) Must exist in ERP customers (customers.a2 = phone).
$custPhoneWhere = deltaPhoneWhere($conx, 'a2', $phone);
$sqlCust = "SELECT id, a1, a2, a3 FROM customers WHERE $custPhoneWhere LIMIT 1";
$resCust = $conx->query($sqlCust);

if (!$resCust || $resCust->num_rows === 0) {
    echo json_encode([
        'success' => false,
        'message' => 'رقم الهاتف غير مسجل كعميل دلتا في العقود',
    ]);
    exit;
}

$erpCustomer = $resCust->fetch_assoc();
$customerName = trim((string)($erpCustomer['a1'] ?? ''));
$nameEsc = mysqli_real_escape_string($conx, $customerName);

// 2) Physical ERP contracts only.
// App-created maintenance rows are type=5 with a30 = app uid — never use those here.
// System/physical contracts come from ERP (type 1 elevator, or type 5 with empty a30).
$contractId = '';
$contract = null;
$contractType = '';

if ($customerName !== '') {
    // Exact name match first (no loose LIKE), prefer non-app rows.
    $sqlContract = "SELECT id, type, a3, a30 FROM contracts
                    WHERE TRIM(a3) = '$nameEsc'
                      AND NOT (IFNULL(type,'') = '5' AND TRIM(IFNULL(a30,'')) != '')
                    ORDER BY
                      CASE WHEN IFNULL(type,'') = '5' THEN 1 ELSE 0 END ASC,
                      id DESC
                    LIMIT 1";
    $resContract = $conx->query($sqlContract);
    if ($resContract && ($contract = $resContract->fetch_assoc())) {
        $contractId = (string)$contract['id'];
        $contractType = (string)($contract['type'] ?? '');
    }
}

if ($contractId === '') {
    echo json_encode([
        'success' => false,
        'message' => 'لا يوجد عقد فيزيائي مسجل لهذا الرقم في السيستم. يمكنك المتابعة كعميل جديد.',
    ]);
    exit;
}

// App uid + address (optional helpers for the maintenance request screen).
$appPhoneWhere = deltaPhoneWhere($conx, 'a2', $phone);
$appUid = '';
$resApp = $conx->query("SELECT a3 FROM cust_app WHERE $appPhoneWhere LIMIT 1");
if ($resApp && ($appRow = $resApp->fetch_assoc())) {
    $appUid = (string)$appRow['a3'];
}

$uid = $appUid;
$addressId = '';
if ($uid !== '') {
    $uidEsc = mysqli_real_escape_string($conx, $uid);
    $resAddr = $conx->query(
        "SELECT id FROM addresses WHERE uid = '$uidEsc' ORDER BY id DESC LIMIT 1"
    );
    if ($resAddr && ($addr = $resAddr->fetch_assoc())) {
        $addressId = (string)$addr['id'];
    }
}

echo json_encode([
    'success' => true,
    'status' => 'verified',
    'uid' => $uid,
    'contract_id' => $contractId,
    'contract_type' => $contractType,
    'address_id' => $addressId,
    'phone' => $erpCustomer['a2'],
    'customer_name' => $customerName,
    'source' => 'erp_physical',
]);
