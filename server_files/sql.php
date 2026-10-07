<?
ini_set('display_errors', 0);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);
include("xtras/config.php");
include("../erp2026/xtras/UploadS3.php");
// Set CORS headers
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
header('Content-Type: application/json; charset=utf-8');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    exit(0);
}

// Get request data (JSON body preferred; fall back to form POST)
$rawBody = file_get_contents('php://input');
$input = json_decode($rawBody, true);
if (!is_array($input)) {
    $input = [];
}
if (!empty($_POST)) {
    $input = array_merge($input, $_POST);
}

$action = isset($input['action']) ? $input['action'] : '';

function sanitize($data) {
    global $conx;
    if ($data === null) {
        $data = '';
    }
    return mysqli_real_escape_string($conx, trim((string)$data));
}

/** Last 8 digits for Qatar local numbers (handles +974 / 974 / spaces). */
function custAppPhoneCanonical8($raw) {
    $d = preg_replace('/\D/', '', (string)$raw);
    if (strlen($d) >= 8) {
        return substr($d, -8);
    }
    return $d;
}

/**
 * Match cust_app.a2 whether DB stores "12345678", "97412345678", "+97412345678", etc.
 */
function buildCustAppPhoneWhere($conx, $rawPhone) {
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

function sendResponse($success, $message, $data = null, $userType = null) {
    $response = [
        'success' => $success,
        'message' => $message
    ];
    if ($data !== null) {
        $response['data'] = $data;
    }
    if ($userType !== null) {
        $response['user_type'] = $userType;
    }
    echo json_encode($response, JSON_UNESCAPED_UNICODE);
    exit;
}

switch ($action) {
    case 'login':
        handleLogin($input);
        break;
    case 'register':
        handleRegister($input);
        break;
    case 'checkUser':
        checkUser($input);
        break;
    case 'checkPhone':
        checkPhoneExists($input);
        break;
    case 'profile':
        getUserProfile($input);
        break;
    case 'updateProfile':
        updateProfile($input);
        break;
    case 'updateName':
        updateNameOnly($input);
        break;
    case 'groups':
        getGroups($input);
        break;
    case 'items':
        getItems($input);
        break;
    
    case 'oneItemDetails':
        getOneItemDetails($input);
        break;
    case 'addOneItem':
        addOneItem($input);
        break;
    case 'addNewAddress':
        addNewAddress($input);
        break;
    case 'getAddresses':
        getAddresses($input);
        break;
    case 'getOneAddress':
        getOneAddress($input);
        break;
    case 'updateOneAddress':
        updateOneAddress($input);
        break;
    case 'deleteAddress':
        deleteAddress($input);
        break;
    case 'getOrders':
        getOrders($input);
        break;
    case 'deleteMyOrders':
        deleteMyOrders($input);
        break;
    case 'addMyBookings':
        addMyBookings($input);
        break;
    case 'getMyBookings':
        getMyBookings($input);
        break;
    case 'dashboard':
        getDashboard($input);
        break;
    case 'getMyBookingOne':
        getMyBookingOne($input);
        break;
    case 'getMyBookingDet':
        getMyBookingDet($input);
        break;
    case 'addContract':
        addContract($input);
        break;
    case 'addMaintenanceContract':
        addMaintenanceContract($input);
        break;
    case 'getContract':
        getContract($input);
        break;
    case 'UploadSignature':
        UploadSignature($input);
        break;
    case 'UploadPdf':
        UploadPdf($input);
        break;
    case 'saveMaintenanceContract':
        saveMaintenanceContract($input);
        break;
    case 'getMyMaintenanceContracts':
        getMyMaintenanceContracts($input);
        break;
    case 'getMaintenanceContractPdf':
        getMaintenanceContractPdf($input);
        break;
    case 'getLabelsLifts':
        getLabelsLifts($input);
        break;
    case 'getLiftsDet':
        getLiftsDet($input);
        break;
    case 'addComplaint':
        addComplaint($input);
        break;
    case 'deleteAccount':
        deleteAccount($input);
        break;
    case 'addMaintenRequest':
        addMaintenRequest($input);
        break;
    case 'uploadImagesMain':
        uploadImagesMain($input);
        break;
    case 'getMaintenances':
        getMaintenances($input);
        break;
    case 'updateMaintenanceStatus':
        updateMaintenanceStatus($input);
        break;
    case 'getHrTechnicians':
        getHrTechnicians($input);
        break;
    case 'assignMaintenanceTech':
        assignMaintenanceTech($input);
        break;
    case 'getTechnicianWorkZone':
        getTechnicianWorkZone($input);
        break;
    case 'search':
        searchItems($input);
        break;
    case 'searchAdmin':
        searchAdmin($input);
        break;
    case 'promos':
        getPromos($input);
        break;
    case 'getPlayerIds':
        getPlayerIds($input);
        break;
    case 'getNotify':
        getNotify($input);
        break;
    case 'delNotify':
        delNotify($input);
        break;
    case 'getUpdates':
        getUpdates($input);
        break;
    case 'getPresignedUrlS3':
        getPresignedUrlS3($input);
        break;
    case 'getPresignedPdfUrl':
        getPresignedPdfUrl($input);
        break;
    case 'SavePdfKey':
        SavePdfKey($input);
        break;
    case 'updateMaintenanceContract':
        updateMaintenanceContract($input);
        break;
    case 'getPresignedMaintenanceImageUrl':
        getPresignedMaintenanceImageUrl($input);
        break;
    case 'getPresignedProfilePhotoUrl':
        getPresignedProfilePhotoUrl($input);
        break;
    case 'updateProfilePhoto':
        updateProfilePhoto($input);
        break;
    case 'getMaintenanceImages':
        getMaintenanceImages($input);
        break;
    case 'getProcessingImages':
        getProcessingImages($input);
        break;
    case 'getPresignedProcessingImageUrl':
        getPresignedProcessingImageUrl($input);
        break;
    case 'deleteProcessingImage':
        deleteProcessingImage($input);
        break;
    case 'notifyProcessingMedia':
        notifyProcessingMedia($input);
        break;
    case 'updateCounterRequest':
        updateCounterRequest($input);
        break;
    case 'getRejectionReason':
        getRejectionReason($input);
        break;
    case 'getChatMessages':
        getChatMessages($input);
        break;
    case 'sendClientChatMsg':
        sendClientChatMsg($input);
        break;
    case 'sendTypingIndicator':
        sendTypingIndicator($input);
        break;
    case 'checkTyping':
        checkTyping($input);
        break;
    case 'updateQuotationStx':
        updateQuotationStx($input);
        break;
    case 'approveContract':
        approveContract($input);
        break;
    case 'updateEnterClient':
        updateEnterClient($input);
        break;
    case 'getEnterClient':
        getEnterClient($input);
        break;
    case 'getCurrentContractMaint':
        getCurrentContractMaint($input);
        break;
    case 'getComplaints':
        getComplaints($input);
        break;
    case 'getMaintenanceDetails':
        getMaintenanceDetails($input);
        break;
    case 'getDeliveryStatus':
        getDeliveryStatus($input);
        break;
    case 'saveDeliveryContract':
        saveDeliveryContract($input);
        break;
    case 'getSupervisorContact':
        getSupervisorContact($input);
        break;
    case 'updateBookingStage':
        updateBookingStage($input);
        break;
    case 'addMaintenanceBooking':
        addMaintenanceBooking($input);
        break;
    case 'checkMaintenanceStatus':
        checkMaintenanceStatus($input);
        break;
    case 'updateBookingAddress':
        updateBookingAddress($input);
        break;
    default:
        sendResponse(false, 'Invalid action');
}

/**
 * LOGIN HANDLER
 */
function handleLogin($input) {
    global $conx;
    
    if (!isset($input['phone'])) {
        sendResponse(false, 'Phone and password are required');
    }
    
    $phoneRaw = trim($input['phone']);
    $playerId = sanitize($input['playerId']);
    $phone8 = custAppPhoneCanonical8($phoneRaw);
    if (!preg_match('/^[0-9]{8}$/', $phone8)) {
        sendResponse(false, 'رقم الهاتف يجب أن يكون 8 أرقام');
    }

    $phoneWhere = buildCustAppPhoneWhere($conx, $phoneRaw);
    $userQuery = "SELECT id, a1, a2, a3, a4, a5, a6 FROM cust_app WHERE $phoneWhere LIMIT 1";
    $userResult = mysqli_query($conx, $userQuery);
    
    // ✅ الإصلاح: التحقق من النتيجة
    if ($userResult && mysqli_num_rows($userResult) > 0) {
        $user = mysqli_fetch_assoc($userResult);
        $idx = (int)$user['id'];
        $conx->query("UPDATE cust_app SET a7 = '$playerId' WHERE id = '$idx'");
        $loginData = [
            'a3' => (int)$user['a3'],
            'a4' => (int)$user['a4'],
        ];
        sendResponse(true, 'تم تسجيل الدخول بنجاح', $loginData);
    } else {
        sendResponse(false, 'رقم الهاتف أو كلمة المرور غير صحيحة');
    }
}

/**
 * REGISTER HANDLER
 */
function handleRegister($input) {
    global $conx;
    
    // ✅ التحقق من وجود البيانات
    if (!isset($input['name']) || !isset($input['phone'])) {
        sendResponse(false, 'جميع الحقول مطلوبة');
    }
    
    $name = sanitize($input['name']);
    $phoneRaw = trim($input['phone']);
    $phoneNorm = sanitize(custAppPhoneCanonical8($phoneRaw));
    $created_at = sanitize($input['created_at']);
    $uid = sanitize($input['uid']);
    $oid = sanitize($input['oid']);
    $playerId = sanitize($input['playerId']);
    


    
    $phoneWhere = buildCustAppPhoneWhere($conx, $phoneRaw);
    $userQuery = "SELECT * FROM cust_app WHERE $phoneWhere LIMIT 1";
    $userResult = $conx->query($userQuery);

    if ($userResult && mysqli_num_rows($userResult) > 0) {
        $existing = mysqli_fetch_assoc($userResult);
        $a1 = isset($existing['a1']) ? trim((string)$existing['a1']) : '';
        $hasName = ($a1 !== '' && strcasecmp($a1, 'null') !== 0);
        if ($hasName) {
            sendResponse(false, 'المستخدم موجود بالفعل');
        }
        $delQuery = "DELETE FROM cust_app WHERE $phoneWhere";
        if (!mysqli_query($conx, $delQuery)) {
            sendResponse(false, 'حدث خطأ أثناء التسجيل');
        }
    }

    $insertQuery = "INSERT INTO cust_app (a1, a2, a3, a4, a5, a7,  stx) VALUES ('$name', '$phoneNorm', '$uid', '$oid', '$created_at', '$playerId', '1')";
    if (mysqli_query($conx, $insertQuery)) {
        sendResponse(true, 'تم التسجيل بنجاح');
    } else {
        sendResponse(false, 'حدث خطأ أثناء التسجيل');
    }
}

/**
 * checkUser
 */
function checkUser($input) {
    global $conx;

    $phoneRaw = trim($input['phone']);
    $phoneWhere = buildCustAppPhoneWhere($conx, $phoneRaw);
    $userQuery = "SELECT * FROM cust_app WHERE $phoneWhere LIMIT 1";
    $userResult = $conx->query($userQuery);
    
    if ($userResult && mysqli_num_rows($userResult) > 0) {
        sendResponse(true, 'المستخدم مسجل');
    } else {
        sendResponse(false, 'المستخدم غير مسجل');
    }
}

/**
 * checkPhone — JSON { "exists": bool }. Table cust_app, column a2 (TRIM match).
 */
function checkPhoneExists($input) {
    global $conx;
    $phone = isset($input['phone']) ? trim($input['phone']) : '';

    header('Content-Type: application/json; charset=utf-8');
    if ($phone === '') {
        echo json_encode(array('exists' => false), JSON_UNESCAPED_UNICODE);
        exit;
    }

    $stmt = $conx->prepare('SELECT id FROM cust_app WHERE TRIM(a2) = ? LIMIT 1');
    if (!$stmt) {
        echo json_encode(array('exists' => false), JSON_UNESCAPED_UNICODE);
        exit;
    }
    $stmt->bind_param('s', $phone);
    $stmt->execute();
    $res = $stmt->get_result();
    $exists = ($res && mysqli_num_rows($res) > 0);
    $stmt->close();

    echo json_encode(array('exists' => (bool)$exists), JSON_UNESCAPED_UNICODE);
    exit;
}



/**
 * get Profile User
 */
function getUserProfile($input) {
    global $conx;
    $uid = sanitize($input['uid']);
    
    if (isset($input['playId'])) {
        $play = sanitize($input['playId']);;
        $conx->query("UPDATE cust_app SET a7 = '$play' WHERE a3 = '$uid'");
    }
    
    $userQuery = "SELECT a1, a2, a3, a4, a5, a6 FROM cust_app WHERE a3 = '$uid'";
    $userResult = $conx->query($userQuery);
    $user = mysqli_fetch_assoc($userResult);
    sendResponse(true, 'تم جلب بيانات المستخدم',$user);
}

// 81ab86ec-6dab-45f5-bc66-5cb611ee7445
// ed20d40a-23ed-45c4-bb88-6f30fd1937a5

/**
 * get Items Groups
 */
function getGroups($input) {
    global $conx;
    $grparr = array();
    $grpQuery = "SELECT a2 FROM items WHERE a2 != 'null' GROUP BY a2";
    $grpResult = $conx->query($grpQuery);
    while($rows=mysqli_fetch_assoc($grpResult)) {$grparr[] = $rows;}
    sendResponse(true, '', $grparr);
}

/**
 * get Items
 */
function getItems($input) {
    global $conx;
    $grp = '';
    $notId = "";
    if (isset($input['grp'])) {
        $grp = sanitize($input['grp']);
    }
    if (isset($input['notId'])) {
        $notId = sanitize($input['notId']);
    }
    $grpql = "";
    $notql = "";
    if ($grp != '') {
        $grpql = "AND items.a2 = '$grp'";
    }
    if ($notId != '') {
        $notql = "AND items.id != '$notId'";
    }
    $itmarr = array();
    $itmxQuery = "SELECT items.id ,   items.a1 , items.a2 , items.a3 , lifts.a1 AS a1x , lifts.a2 AS a2x , lifts.a3 AS a3x , lifts.a4 , lifts.a5 , lifts.a6 , lifts.a7 , lifts.a8 , lifts.a9 , lifts.a10 , lifts.a11 , lifts.a12 , lifts.a13 , lifts.a14 , lifts.a15 , lifts.a16 FROM items LEFT JOIN lifts ON items.a4 = lifts.id WHERE items.a1 != 'null' $grpql $notql";
    $itmxResult = $conx->query($itmxQuery);
    while($rows=mysqli_fetch_assoc($itmxResult)) {$itmarr[] = $rows;}
    sendResponse(true, '',$itmarr);
}

/**
 * get One Item Details
 */
function getOneItemDetails($input) {
    global $conx;
    $itmid = sanitize($input['itmid']);
    $itmarr = array();
    $itmxQuery = "SELECT items.id , lifts.id AS liftid, items.a1 , items.a2 , items.a3 , lifts.a1 AS a1x , lifts.a2 AS a2x , lifts.a3 AS a3x , lifts.a4 , lifts.a5 , lifts.a6 , lifts.a7 , lifts.a8 , lifts.a9 , lifts.a10 , lifts.a11 , lifts.a12 , lifts.a13 , lifts.a14 , lifts.a15 , lifts.a16 FROM items LEFT JOIN lifts ON items.a4 = lifts.id WHERE items.id = '$itmid'";
    $itmxResult = $conx->query($itmxQuery);
    while($rows=mysqli_fetch_assoc($itmxResult)) {$itmarr[] = $rows;}
    sendResponse(true, '',$itmarr);
}

/**
 * add One Item
 */
function addOneItem($input) {
    global $conx;
    $itmid = sanitize($input['itmid']);
    $uid = sanitize($input['uid']);
    $oid = sanitize($input['oid']);
    
    $orderQuery = "SELECT * FROM orders WHERE itmid = '$itmid' AND uid = '$uid' AND stx = '0'";
    $orderResult = $conx->query($orderQuery);
    
    if ($orderResult && mysqli_num_rows($orderResult) > 0) {
        sendResponse(false, 'هذا الطلب موجود بالفعل');
    } else {
        $insertQuery = "INSERT INTO orders (itmid, uid, oid) VALUES ('$itmid', '$uid', '$oid')";
        $conx->query($insertQuery);
        sendResponse(true, 'تم إضافة هذا الطلب');
    }
}

/**
 * add New Address
 */
function addNewAddress($input) {
    global $conx;
    $city = sanitize($input['city']);
    $zone = sanitize($input['zone']);
    $street = sanitize($input['street']);
    $building = sanitize($input['building']);
    $latitude = sanitize($input['latitude']);
    $longitude = sanitize($input['longitude']);
    $uid = sanitize($input['uid']);
    
    $insertQuery = "INSERT INTO addresses VALUES (NULL, '$city', '$zone', '$street', '$building', '$latitude', '$longitude', '$uid')";
    $conx->query($insertQuery);
    sendResponse(true, 'تم إضافة هذا العنوان');
}

/**
 * get Addresses
 */
function getAddresses($input) {
    global $conx;
    $uid = sanitize($input['uid']);
    $addarr = array();
    $addxQuery = "SELECT * FROM addresses WHERE uid = '$uid' ";
    $addxResult = $conx->query($addxQuery);
    while($rows=mysqli_fetch_assoc($addxResult)) {$addarr[] = $rows;}
    sendResponse(true, '',$addarr);
}

/**
 * get One Address
 */
function getOneAddress($input) {
    global $conx;
    $id = sanitize($input['id']);
    $addarr = array();
    $addxQuery = "SELECT * FROM addresses WHERE id = '$id' ";
    $addxResult = $conx->query($addxQuery);
    while($rows=mysqli_fetch_assoc($addxResult)) {$addarr[] = $rows;}
    sendResponse(true, '',$addarr);
}

/**
 * update One Address
 */
function updateOneAddress($input) {
    global $conx;
    $uid = sanitize($input['uid']);
    $zone = sanitize($input['zone']);
    $street = sanitize($input['street']);
    $building = sanitize($input['building']);
    $latitude = sanitize($input['latitude']);
    $longitude = sanitize($input['longitude']);
    $conx->query("UPDATE addresses SET zone = '$zone', street = '$street', building = '$building', latitude = '$latitude', longitude = '$longitude' WHERE id = '$uid'");
    sendResponse(true, 'تم تحديث العنوان بنجاح');
}

/**
 * delete Address
 */
function deleteAddress($input) {
    global $conx;
    $id = sanitize($input['id']);
    $uid = sanitize($input['uid']);
    $conx->query("DELETE FROM addresses WHERE id = '$id' AND uid = '$uid'");
    echo json_encode([
        'status' => 'success',
        'success' => true,
        'message' => 'تم حذف العنوان بنجاح',
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

/**
 * get My Orders
 */
function getOrders($input) {
    global $conx;
    $uid = sanitize($input['uid']);
    $ordarr = array();
    $ordxQuery = "SELECT orders.id AS oid , items.id , items.a1 , items.a2 , items.a3 FROM orders LEFT JOIN items ON orders.itmid = items.id WHERE orders.uid = '$uid' AND orders.stx = '0'";
    $ordxResult = $conx->query($ordxQuery);
    while($rows=mysqli_fetch_assoc($ordxResult)) {$ordarr[] = $rows;}
    sendResponse(true, '',$ordarr);
}

/**
 * delete My Orders
 */
function deleteMyOrders($input) {
    global $conx;
    $id = sanitize($input['id']);
    $conx->query("DELETE FROM orders WHERE id = '$id'");
    sendResponse(true, 'تم حذف الطلب بنجاح');
}

/**
 * add My Bookings
 */
function addMyBookings($input) {
    global $conx;
    $addId = sanitize($input['addId']);
    $uid = sanitize($input['uid']);
    $oid = sanitize($input['oid']);
    $date = date('Y-m-d');
    $time = date('h:i A');
    $conx->query("UPDATE orders SET stx = '1' WHERE uid = '$uid'");
    $conx->query("INSERT INTO bookings (addressId, uid, orderId, date, time, stx) VALUES('$addId', '$uid', '$oid', '$date', '$time', '0')");
    sendResponse(true, 'تم حجز الطلب بنجاح');
}

/**
 * App "عميل جديد" maintenance onboarding booking.
 * ERP قائمة صيانة filters: bookings.enter LIKE '%صيانة%'
 */
function addMaintenanceBooking($input) {
    global $conx;
    $uid = sanitize($input['uid'] ?? '');
    $oid = sanitize($input['oid'] ?? '');
    $addId = sanitize($input['addId'] ?? '0');
    if ($uid === '') {
        sendResponse(false, 'uid required');
    }
    if ($oid === '') {
        $oid = (string)(1000 + mt_rand(0, 8999));
    }
    if ($addId === '') {
        $addId = '0';
    }

    // Reuse an open maintenance booking for this user (avoid duplicates).
    $existing = $conx->query(
        "SELECT id, addressId, stx, stt, contract_ready, contract_id
         FROM bookings
         WHERE uid = '$uid'
           AND enter LIKE '%صيانة%'
           AND (stx = '0' OR (stx = '1' AND IFNULL(stt,0) = '0'))
         ORDER BY id DESC
         LIMIT 1"
    )->fetch_assoc();
    if ($existing) {
        echo json_encode([
            'success' => true,
            'message' => 'موجود',
            'bookingId' => (string)$existing['id'],
            'addressId' => (string)($existing['addressId'] ?? ''),
            'stx' => (string)($existing['stx'] ?? '0'),
            'contract_ready' => (string)($existing['contract_ready'] ?? '0'),
        ]);
        exit;
    }

    $date = date('Y-m-d');
    $time = date('h:i A');
    $enter = 'صيانة';
    $conx->query(
        "INSERT INTO bookings
         (addressId, uid, orderId, date, time, stx, stt, stl, stb, enter, contract_ready)
         VALUES
         ('$addId', '$uid', '$oid', '$date', '$time', '0', '0', '0', '0', '$enter', 0)"
    );
    $bookingId = (string)mysqli_insert_id($conx);
    echo json_encode([
        'success' => true,
        'message' => 'تم إنشاء طلب الصيانة',
        'bookingId' => $bookingId,
        'addressId' => $addId,
    ]);
    exit;
}

/**
 * Status for new-client maintenance onboarding resume.
 * none | pending_address | pending_approval | pending_prepare | pending_contract | completed
 */
function checkMaintenanceStatus($input) {
    global $conx;
    $uid = sanitize($input['uid'] ?? '');
    if ($uid === '') {
        sendResponse(false, 'uid required');
    }

    $hasContract = $conx->query(
        "SELECT id FROM contracts
         WHERE a30 = '$uid' AND (type = '5' OR type = '4')
         LIMIT 1"
    )->fetch_assoc();

    $book = $conx->query(
        "SELECT id, addressId, stx, stt, contract_ready, contract_id
         FROM bookings
         WHERE uid = '$uid' AND enter LIKE '%صيانة%'
         ORDER BY id DESC
         LIMIT 1"
    )->fetch_assoc();

    if (!$book) {
        $status = $hasContract ? 'completed' : 'none';
        echo json_encode([
            'success' => true,
            'status' => $status,
            'bookingId' => '',
            'addressId' => '',
        ]);
        exit;
    }

    $bookingId = (string)$book['id'];
    $addressId = trim((string)($book['addressId'] ?? ''));
    $stx = (string)($book['stx'] ?? '0');
    $stt = (string)($book['stt'] ?? '0');
    $ready = (string)($book['contract_ready'] ?? '0');
    $cid = trim((string)($book['contract_id'] ?? ''));

    if ($addressId === '' || $addressId === '0') {
        $status = 'pending_address';
    } elseif ($stx === '0') {
        $status = 'pending_approval';
    } elseif ($ready === '1' || $ready === 'true') {
        // Contract sent to app for review/sign
        $status = ($stt === '1' || $cid !== '') ? 'completed' : 'pending_contract';
    } elseif ($stt === '1' || ($cid !== '' && $hasContract)) {
        $status = 'completed';
    } else {
        // ERP approved, company preparing / editing contract
        $status = 'pending_prepare';
    }

    echo json_encode([
        'success' => true,
        'status' => $status,
        'bookingId' => $bookingId,
        'addressId' => $addressId,
        'stx' => $stx,
        'stt' => $stt,
        'contract_ready' => $ready,
        'contract_id' => $cid,
    ]);
    exit;
}

function updateBookingAddress($input) {
    global $conx;
    $bookingId = sanitize($input['bookingId'] ?? '');
    $addressId = sanitize($input['addressId'] ?? '');
    if ($bookingId === '' || $addressId === '' || $addressId === '0') {
        sendResponse(false, 'bookingId and addressId required');
    }
    // Ensure maintenance marker so ERP صيانة tab can see it.
    $conx->query(
        "UPDATE bookings
         SET addressId = '$addressId',
             enter = IF(enter LIKE '%صيانة%', enter, 'صيانة')
         WHERE id = '$bookingId'"
    );
    echo json_encode([
        'success' => true,
        'message' => 'تم تحديث العنوان',
        'bookingId' => $bookingId,
        'addressId' => $addressId,
    ]);
    exit;
}

/**
 * get My Bookings
 */
function getMyBookings($input) {
    global $conx;
    $uid = sanitize($input['uid']);
    $stx = "";
    if (isset($input['indexChanged']))
    {
        $indexChanged = sanitize($input['indexChanged']);
        switch ($indexChanged) {
            case '1':
                $stx = "AND bookings.stl IN ('1', '2', '3', '4', '5', '6', '7', '8') ";
                break;
            case '2':
                $stx = "AND bookings.stl = '9'";
                break;
            default:
                $stx = "";
                break;
        }
    }

    $bookarr = array();
    if (isAppManagerUid($uid)) {
        $bookxQuery = "SELECT bookings.*, addresses.city , addresses.zone , addresses.street , addresses.building , addresses.latitude , addresses.longitude , bookings.uid , bookings.orderId , cust_app.a1 AS client_name
                       FROM bookings
                       LEFT JOIN addresses ON addresses.id = bookings.addressId
                       LEFT JOIN cust_app ON bookings.uid = cust_app.a3
                       WHERE 1=1 $stx
                       ORDER BY bookings.id DESC";
    } else {
        $bookxQuery = "SELECT bookings.*, addresses.city , addresses.zone , addresses.street , addresses.building , addresses.latitude , addresses.longitude , bookings.uid , bookings.orderId FROM addresses RIGHT JOIN bookings ON addresses.id = bookings.addressId WHERE bookings.uid = '$uid' $stx ORDER BY bookings.id DESC";
    }
    $bookxResult = $conx->query($bookxQuery);
    while($rows=mysqli_fetch_assoc($bookxResult)) {$bookarr[] = $rows;}
    sendResponse(true, '',$bookarr);
}

/**
 * Home dashboard: active / completed bookings + last booking.
 * App manager = cust_app.a29=1 OR matching ERP users.a29=1 (by phone).
 * Managers see the latest booking across all customers.
 */
function getDashboard($input) {
    global $conx;
    $uidRaw = isset($input['uid']) ? trim((string)$input['uid']) : '';
    if ($uidRaw === '') {
        sendResponse(true, '', array(
            'active_orders' => 0,
            'completed_orders' => 0,
            'last_order_date' => '',
            'last_order_id' => '',
            'last_order_stl' => '',
            'last_order_stb' => '',
            'last_order_stt' => '',
            'last_order_customer' => '',
            'is_app_manager' => 0,
        ));
        return;
    }
    $uid = sanitize($uidRaw);

    $active = 0;
    $completed = 0;
    $lastDate = '';
    $lastId = '';
    $lastStl = '';
    $lastStb = '';
    $lastStt = '';
    $lastCustomer = '';
    $isAppManager = 0;
    $phoneRaw = '';

    $qRole = "SELECT a2, a29 FROM cust_app WHERE a3 = '$uid' LIMIT 1";
    $resRole = $conx->query($qRole);
    if ($resRole && ($rowRole = mysqli_fetch_assoc($resRole))) {
        $phoneRaw = isset($rowRole['a2']) ? (string)$rowRole['a2'] : '';
        if ((string)$rowRole['a29'] === '1') {
            $isAppManager = 1;
        }
    }

    // ERP «أدمن الموبايل» lives on users.a29 (matched by phone)
    if ($isAppManager !== 1 && $phoneRaw !== '') {
        $phoneCanon = custAppPhoneCanonical8($phoneRaw);
        if ($phoneCanon !== '') {
            $phoneEsc = sanitize($phoneCanon);
            $qErp = "SELECT a29 FROM users
                     WHERE REPLACE(REPLACE(REPLACE(TRIM(a5), '+', ''), ' ', ''), '-', '') LIKE '%$phoneEsc'
                     LIMIT 1";
            $resErp = $conx->query($qErp);
            if ($resErp && ($rowErp = mysqli_fetch_assoc($resErp)) && (string)$rowErp['a29'] === '1') {
                $isAppManager = 1;
            }
        }
    }

    if ($isAppManager === 1) {
        $qActive = "SELECT COUNT(*) AS c FROM bookings WHERE stl IN ('1','2','3','4','5','6','7','8')";
        $qDone = "SELECT COUNT(*) AS c FROM bookings WHERE stl = '9'";
    } else {
        $qActive = "SELECT COUNT(*) AS c FROM bookings WHERE uid = '$uid' AND stl IN ('1','2','3','4','5','6','7','8')";
        $qDone = "SELECT COUNT(*) AS c FROM bookings WHERE uid = '$uid' AND stl = '9'";
    }
    $resA = $conx->query($qActive);
    if ($resA && ($rowA = mysqli_fetch_assoc($resA))) {
        $active = (int)$rowA['c'];
    }

    $resD = $conx->query($qDone);
    if ($resD && ($rowD = mysqli_fetch_assoc($resD))) {
        $completed = (int)$rowD['c'];
    }

    if ($isAppManager === 1) {
        $qLast = "SELECT bookings.id, bookings.`date`, bookings.stl, bookings.stb, bookings.stt, cust_app.a1 AS customer_name
                  FROM bookings
                  LEFT JOIN cust_app ON bookings.uid = cust_app.a3
                  ORDER BY bookings.id DESC
                  LIMIT 1";
    } else {
        $qLast = "SELECT bookings.id, bookings.`date`, bookings.stl, bookings.stb, bookings.stt, cust_app.a1 AS customer_name
                  FROM bookings
                  LEFT JOIN cust_app ON bookings.uid = cust_app.a3
                  WHERE bookings.uid = '$uid'
                  ORDER BY bookings.id DESC
                  LIMIT 1";
    }
    $resL = $conx->query($qLast);
    if ($resL && ($rowL = mysqli_fetch_assoc($resL))) {
        $lastId = (string)$rowL['id'];
        $lastDate = $rowL['date'] !== null ? (string)$rowL['date'] : '';
        $lastStl = isset($rowL['stl']) ? (string)$rowL['stl'] : '';
        $lastStb = isset($rowL['stb']) ? (string)$rowL['stb'] : '';
        $lastStt = isset($rowL['stt']) ? (string)$rowL['stt'] : '';
        $lastCustomer = isset($rowL['customer_name']) ? (string)$rowL['customer_name'] : '';
    }

    sendResponse(true, '', array(
        'active_orders' => $active,
        'completed_orders' => $completed,
        'last_order_date' => $lastDate,
        'last_order_id' => $lastId,
        'last_order_stl' => $lastStl,
        'last_order_stb' => $lastStb,
        'last_order_stt' => $lastStt,
        'last_order_customer' => $lastCustomer,
        'is_app_manager' => $isAppManager,
    ));
}

/**
 * get My Booking
 */
function getMyBookingOne($input) {
    global $conx;
    $bookid = sanitize($input['bookid']);
    $bookarr = array();
    $bookxQuery = "SELECT id, stx, stt, stl, stb, floors, persons, orderId, contract_id, contract_ready FROM bookings WHERE id = '$bookid'";
    $bookxResult = $conx->query($bookxQuery);
    while($rows=mysqli_fetch_assoc($bookxResult)) {$bookarr[] = $rows;}
    sendResponse(true, '',$bookarr);
}

/**
 * get My Booking
 */
function getMyBookingDet($input) {
    global $conx;
    $bookId = sanitize($input['bookId']);
    $bookarr = array();
    $bookxQuery = "SELECT bookings.id , bookings.stt , bookings.stl , bookings.stb , bookings.contract_ready , bookings.enter , bookings.floors , bookings.persons , bookings.orderId , bookings.date , addresses.city , addresses.zone , addresses.street , addresses.building , addresses.latitude , addresses.longitude , cust_app.a1 , cust_app.a2 , addresses.uid , bookings.contract_id , contracts.a15 , contracts.a16 , contracts.a17 , contracts.a18 FROM bookings LEFT JOIN addresses ON bookings.addressId = addresses.id LEFT JOIN cust_app ON bookings.uid = cust_app.a3 LEFT JOIN contracts ON bookings.contract_id = contracts.id WHERE bookings.id = '$bookId'";
    $bookxResult = $conx->query($bookxQuery);
    while($rows=mysqli_fetch_assoc($bookxResult)) {
        $bid = (string)($rows['id'] ?? $bookId);
        $enter = (string)($rows['enter'] ?? '');
        $ktype = (strpos($enter, 'صيانة') !== false) ? '4' : '1';
        $rows['contract_pdf_url'] =
            'https://daltalifts.com/app2026/PDF_Final/index.php?ktype=' . $ktype . '&batchId=' . rawurlencode($bid);
        $bookarr[] = $rows;
    }
    sendResponse(true, '',$bookarr);
}

/**
 * addContract
 */
function addContract($input) {
    global $conx;
    $type = sanitize($input['type']);
    $a2 = sanitize($input['a2']);
    $a3 = sanitize($input['a3']);
    $sqlx = "INSERT INTO contracts(type, a2, a3, clx) VALUES('$type', '$a2', '$a3', '1')";
    $conx->query($sqlx);
    $id = $conx->insert_id;
    sendResponse(true, '',["id" => $id]);
}

/**
 * addMaintenanceContract
 */
function addMaintenanceContract($input) {
    global $conx;
    $type = sanitize($input['type']);
    $a2 = sanitize($input['a2']);
    $a3 = sanitize($input['a3']);
    $a19 = sanitize($input['a19']);
    $a20 = sanitize($input['a20']);
    $a30 = sanitize($input['a30']);
    $sqlx = "INSERT INTO contracts(type, a2, a3, a19, a20, a30, clx) VALUES('$type', '$a2', '$a3', '$a19','$a20', '$a30','1')";
    $conx->query($sqlx);
    $id = $conx->insert_id;
    sendResponse(true, '',["id" => $id]);
}

/**
 * Upload Signature
 */
function UploadSignature($input) {
    global $conx;
    $contractId = sanitize($input['contractId'] ?? '');
    $bookingId = sanitize($input['bookingId'] ?? ($input['bookId'] ?? ''));
    if ($contractId === '' && $bookingId !== '') {
        $contractId = $bookingId;
    }

    // لو جاي s3Key يعني الرفع على S3 — لازم نربط الحجز بالتوقيع
    if (!empty($input['s3Key'])) {
        $s3Key = sanitize($input['s3Key']);
        if ($contractId === '' && preg_match('/signature_([0-9A-Za-z_-]+)\.png/i', $s3Key, $m)) {
            $contractId = $m[1];
        }
        if ($bookingId !== '' && $contractId !== '') {
            $conx->query("UPDATE bookings SET stt = '1', contract_id = '$contractId' WHERE id = '$bookingId'");
        }
        // لو التوقيع اترفَع على مسار قديم فاضي، انسخه للمسار الصحيح
        try {
            if (class_exists('S3Storage') && $contractId !== '') {
                $s3 = S3Storage::getInstance();
                $canonical = "Mobile_App/signatures/Maintenance_Contracts_New/signature_{$contractId}.png";
                if ($s3Key !== $canonical && $s3->exists($s3Key) && !$s3->exists($canonical)) {
                    $tmp = sys_get_temp_dir() . "/sign_fix_{$contractId}.png";
                    $url = $s3->presignedUrl($s3Key, 300);
                    $bytes = @file_get_contents($url);
                    if ($bytes && strlen($bytes) > 100) {
                        file_put_contents($tmp, $bytes);
                        $s3->upload($tmp, $canonical, 'public-read');
                        @unlink($tmp);
                        $s3Key = $canonical;
                    }
                }
            }
        } catch (Throwable $e) {
            // non-fatal
        }
        echo json_encode([
            'success' => true,
            'message' => 'تم حفظ التوقيع',
            'contractId' => $contractId,
            's3Key' => $s3Key,
        ]);
        exit;
    }

    // الكود القديم — لو جاي base64 (fallback)
    $signature = $input['signature'] ?? '';
    $signature = preg_replace('/\s+/', '', (string)$signature);
    $signature = preg_replace('#^data:image/\w+;base64,#', '', $signature);
    if ($contractId === '' || $signature === '') {
        echo json_encode(['success' => false, 'message' => 'بيانات غير كاملة']);
        exit;
    }
    $upload_dir = __DIR__ . '/../erp2026/assets/signatures/';
    if (!file_exists($upload_dir)) mkdir($upload_dir, 0777, true);
    $filename = 'signature_' . $contractId . '.png';
    $filepath = $upload_dir . $filename;
    $image_data = base64_decode($signature);
    if ($image_data && file_put_contents($filepath, $image_data)) {
        if ($bookingId !== '') {
            $conx->query("UPDATE bookings SET stt = '1', contract_id = '$contractId' WHERE id = '$bookingId'");
        }
        try {
            if (class_exists('S3Storage')) {
                $s3 = S3Storage::getInstance();
                $s3->upload($filepath, "Mobile_App/signatures/Maintenance_Contracts_New/{$filename}", 'public-read');
            }
        } catch (Throwable $e) {
        }
        echo json_encode(['success' => true, 'message' => 'تم حفظ التوقيع بنجاح', 'contractId' => $contractId]);
    } else {
        echo json_encode(['success' => false, 'message' => 'فشل في حفظ الصورة']);
    }
}

/**
 * Link signed maintenance contract to booking + mark app contract owner.
 */
function saveMaintenanceContract($input) {
    global $conx;
    $bookingId = sanitize($input['bookingId'] ?? ($input['bookId'] ?? ''));
    $contractId = sanitize($input['contractId'] ?? '');
    $uid = sanitize($input['uid'] ?? ($input['userId'] ?? ''));
    if ($bookingId === '' || $contractId === '') {
        echo json_encode(['success' => false, 'message' => 'bookingId and contractId required']);
        exit;
    }

    $conx->query(
        "UPDATE bookings
         SET contract_id = '$contractId', stt = '1',
             enter = IF(enter LIKE '%صيانة%', enter, 'صيانة')
         WHERE id = '$bookingId'"
    );

    // Fill customer name/phone/address + bind app uid (a30) for resume/completed checks.
    $book = $conx->query(
        "SELECT b.uid, c.a1 AS name, c.a2 AS phone,
                CONCAT(IFNULL(a.city,''),' - ',IFNULL(a.zone,''),' - ',IFNULL(a.building,'')) AS addr
         FROM bookings b
         LEFT JOIN cust_app c ON c.a3 = b.uid
         LEFT JOIN addresses a ON a.id = b.addressId
         WHERE b.id = '$bookingId'
         LIMIT 1"
    )->fetch_assoc();

    if ($book) {
        if ($uid === '') {
            $uid = sanitize($book['uid'] ?? '');
        }
        $name = sanitize($book['name'] ?? '');
        $addr = sanitize($book['addr'] ?? '');
        $startDate = date('Y-m-d');
        $endDate = date('Y-m-d', strtotime('+1 year'));
        $conx->query(
            "UPDATE contracts
             SET a3 = IF(TRIM(IFNULL(a3,''))='', '$name', a3),
                 a11 = IF(TRIM(IFNULL(a11,''))='', '$addr', a11),
                 a30 = IF(TRIM(IFNULL(a30,''))='', '$uid', a30),
                 a19 = IF(TRIM(IFNULL(a19,''))='', '$startDate', a19),
                 a20 = IF(TRIM(IFNULL(a20,''))='', '$endDate', a20),
                 a2 = IF(TRIM(IFNULL(a2,''))='', '$startDate', a2),
                 stx = '1'
             WHERE id = '$contractId'"
        );
    }

    echo json_encode([
        'success' => true,
        'message' => 'تم ربط عقد الصيانة',
        'bookingId' => $bookingId,
        'contractId' => $contractId,
    ]);
    exit;
}

/**
 * App user's maintenance contracts (settings screen).
 * Returns dates + expiry status for UI coloring.
 */
function getMyMaintenanceContracts($input) {
    global $conx;
    $uid = sanitize($input['uid'] ?? ($input['userId'] ?? ''));
    if ($uid === '') {
        sendResponse(false, 'uid required');
    }

    $rows = [];
    $q = $conx->query(
        "SELECT id, type, a2, a3, a11, a19, a20, a30, stx
         FROM contracts
         WHERE a30 = '$uid' AND (type = '4' OR type = '5')
         ORDER BY id DESC"
    );
    $today = strtotime(date('Y-m-d'));
    $canCreateNew = true;
    $activeCount = 0;

    while ($r = mysqli_fetch_assoc($q)) {
        $start = trim((string)($r['a19'] ?? ''));
        $end = trim((string)($r['a20'] ?? ''));
        $created = trim((string)($r['a2'] ?? ''));
        if ($start === '' && $created !== '') {
            $start = $created;
        }
        if ($end === '' && $start !== '') {
            $ts = strtotime($start);
            if ($ts) {
                $end = date('Y-m-d', strtotime('+1 year', $ts));
            }
        }

        $endTs = $end !== '' ? strtotime($end) : false;
        $status = 'active';
        $daysLeft = null;
        if ($endTs) {
            $daysLeft = (int)floor(($endTs - $today) / 86400);
            if ($daysLeft < 0) {
                $status = 'expired';
            } elseif ($daysLeft <= 30) {
                $status = 'expiring_soon';
                $canCreateNew = false;
                $activeCount++;
            } else {
                $status = 'active';
                $canCreateNew = false;
                $activeCount++;
            }
        } else {
            // No end date → treat as active (block new until set/expired)
            $status = 'active';
            $canCreateNew = false;
            $activeCount++;
        }

        $bookingId = '';
        $cidEsc = mysqli_real_escape_string($conx, (string)$r['id']);
        $bRow = $conx->query(
            "SELECT id FROM bookings
             WHERE contract_id = '$cidEsc'
             ORDER BY id DESC LIMIT 1"
        )->fetch_assoc();
        if ($bRow) {
            $bookingId = (string)$bRow['id'];
        }

        $rows[] = [
            'id' => (string)$r['id'],
            'type' => (string)($r['type'] ?? ''),
            'customer_name' => (string)($r['a3'] ?? ''),
            'address' => (string)($r['a11'] ?? ''),
            'start_date' => $start,
            'end_date' => $end,
            'created_date' => $created,
            'stx' => (string)($r['stx'] ?? '0'),
            'status' => $status,
            'days_left' => $daysLeft,
            'booking_id' => $bookingId,
        ];
    }

    // If no contracts at all, allow creating the first one.
    if (count($rows) === 0) {
        $canCreateNew = true;
    }

    sendResponse(true, '', [
        'contracts' => $rows,
        'can_create_new' => $canCreateNew ? 1 : 0,
        'active_count' => $activeCount,
    ]);
}

/**
 * Latest signed maintenance PDF URL for preview in the app.
 */
function getMaintenanceContractPdf($input) {
    global $conx;
    $contractId = sanitize($input['contractId'] ?? '');
    $bookingId = sanitize($input['bookingId'] ?? ($input['bookId'] ?? ''));
    $uid = sanitize($input['uid'] ?? ($input['userId'] ?? ''));

    if ($contractId === '') {
        echo json_encode(['success' => false, 'message' => 'contractId required']);
        exit;
    }

    // Ownership check when uid provided
    if ($uid !== '') {
        $own = $conx->query(
            "SELECT id FROM contracts
             WHERE id = '$contractId' AND a30 = '$uid'
               AND (type = '4' OR type = '5')
             LIMIT 1"
        )->fetch_assoc();
        if (!$own) {
            echo json_encode(['success' => false, 'message' => 'غير مصرح']);
            exit;
        }
    }

    if ($bookingId === '') {
        $b = $conx->query(
            "SELECT id FROM bookings
             WHERE contract_id = '$contractId'
             ORDER BY id DESC LIMIT 1"
        )->fetch_assoc();
        if ($b) {
            $bookingId = (string)$b['id'];
        }
    }

    $pdfUrl = '';
    $folders = [
        'Maintenance_Contracts_New',
        'Maintenance Contracts New',
        'Maintenance_Contracts',
        'Maintenance Contracts',
    ];

    try {
        if (class_exists('S3Storage')) {
            $s3 = S3Storage::getInstance();
            foreach ($folders as $folder) {
                $prefix = "Mobile_App/contracts/{$folder}/contract_{$contractId}_";
                $files = $s3->listFiles($prefix, 100);
                $bestKey = '';
                $bestTs = -1;
                foreach ($files as $f) {
                    $key = is_array($f) ? (string)($f['Key'] ?? $f['key'] ?? '') : (string)$f;
                    if ($key === '') continue;
                    if (preg_match('/contract_' . preg_quote($contractId, '/') . '_(\d+)\.pdf$/i', $key, $m)) {
                        $ts = (int)$m[1];
                        if ($ts >= $bestTs) {
                            $bestTs = $ts;
                            $bestKey = $key;
                        }
                    }
                }
                if ($bestKey !== '') {
                    $pdfUrl = method_exists($s3, 'url')
                        ? $s3->url($bestKey)
                        : ('https://daltaliftstech.s3.ap-south-1.amazonaws.com/' . $bestKey);
                    break;
                }
            }
        }
    } catch (Throwable $e) {
        // fall through to regenerate
    }

    // Regenerate signed PDF if none found on S3
    if ($pdfUrl === '') {
        $batchQ = $bookingId !== '' ? ('&batchId=' . urlencode($bookingId)) : '';
        $genUrl = 'https://daltalifts.com/app2026/pdf/index.php?contractId='
            . urlencode($contractId) . '&sign=1&ktype=4' . $batchQ;
        $ctx = stream_context_create(['http' => ['timeout' => 60, 'ignore_errors' => true]]);
        $raw = @file_get_contents($genUrl, false, $ctx);
        $decoded = $raw ? json_decode($raw, true) : null;
        if (is_array($decoded) && !empty($decoded['success']) && !empty($decoded['url'])) {
            $pdfUrl = (string)$decoded['url'];
        }
    }

    if ($pdfUrl === '') {
        echo json_encode([
            'success' => false,
            'message' => 'تعذر العثور على ملف العقد الموقّع',
        ]);
        exit;
    }

    echo json_encode([
        'success' => true,
        'url' => $pdfUrl,
        'contractId' => $contractId,
        'bookingId' => $bookingId,
    ]);
    exit;
}

/**
 * get Labels Lifts
 */
function getLabelsLifts($input) {
    global $conx;
    $lblarr = array();
    $lblxQuery = "SELECT arb FROM labels WHERE typex = 'lifts'";
    $lblxResult = $conx->query($lblxQuery);
    while($rows=mysqli_fetch_assoc($lblxResult)) {$lblarr[] = $rows;}
    sendResponse(true, '',$lblarr);
}

/**
 * getLiftsDet
 */
function getLiftsDet($input) {
    global $conx;
    $idlift = sanitize($input['idlift']);
    $lftxarr = array();
    $lftxQuery = "SELECT a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16 FROM lifts WHERE id = '$idlift'";
    $lftxResult = $conx->query($lftxQuery);
    while($rows=mysqli_fetch_assoc($lftxResult)) {$lftxarr[] = $rows;}
    sendResponse(true, '',$lftxarr);
}

/**
 * updateProfile
 */
function updateProfile($input) {
    global $conx;
    $uid = sanitize($input['uid']);
    $name = sanitize($input['name']);
    $mobile = sanitize($input['mobile']);
    $conx->query("UPDATE cust_app SET a1 = '$name', a2 = '$mobile' WHERE a3 = '$uid' ");
    sendResponse(true, 'تم تحديث بياناتك بنجاح');
}

/**
 * Update display name only (cust_app.a1). Accepts userId or uid.
 */
function updateNameOnly($input) {
    global $conx;
    $userId = sanitize(isset($input['userId']) ? $input['userId'] : (isset($input['uid']) ? $input['uid'] : ''));
    $name = sanitize(isset($input['name']) ? $input['name'] : '');
    if ($userId === '' || $name === '') {
        sendResponse(false, 'بيانات ناقصة');
    }
    $conx->query("UPDATE cust_app SET a1 = '$name' WHERE a3 = '$userId' ");
    sendResponse(true, 'تم تحديث الاسم');
}

/**
 * addComplaint
 */
function addComplaint($input) {
    global $conx;
    $name = sanitize($input['name']);
    $mobile = sanitize($input['mobile']);
    $msg = sanitize($input['msg']);
    $userId = sanitize($input['userId']);
    $conx->query("INSERT INTO complaints(`name`, mobile, msg, userid) VALUES('$name', '$mobile', '$msg', '$userId')");
    sendResponse(true, 'تم إضافة شكوتك بنجاح');
}

/**
 * deleteAccount
 */
function deleteAccount($input) {
    global $conx;
    $userId = sanitize($input['userId']);
    $conx->query("DELETE FROM cust_app WHERE a3 = '$userId'");
    sendResponse(true, 'تم حذف حسابك بنجاح');
}

/**
 * deleteAccount
 */
function addMaintenRequest($input) {
    global $conx;
    $addressId = sanitize($input['addressId']);
    $descController = sanitize($input['descController']);
    $dateController = sanitize($input['dateController']);
    $timeController = sanitize($input['timeController']);
    $type = sanitize($input['type']);
    $uid = sanitize($input['uid']);
    $conx->query("INSERT INTO maintenance (a1, a2, a3, a4, a5, a6) VALUES('$addressId', '$descController', '$dateController', '$timeController', '$type', '$uid')");
    $mainid = $conx->insert_id;
    sendResponse(true, 'تم إضافة طلب صيانة جديد', ['mainId' => $mainid]);
}

/**
 * getMaintenances
 */
function getMaintenances($input) {
    global $conx;
    $uid = sanitize($input['uid']);
    $stx = "";
    if (isset($input['indexChanged']))
    {
        $indexChanged = sanitize($input['indexChanged']);
        switch ($indexChanged) {
            case '1':
                $stx = "AND maintenance.a5 = 'Normal'";
                break;
            case '2':
                $stx = "AND maintenance.a5 = 'Urgent'";
                break;
            default:
                $stx = "";
                break;
        }
    }
    $mainarr = array();
    if (isAppManagerUid($uid)) {
        // Managers see all maintenance tickets + client + address
        $mainQuery = "SELECT maintenance.id, maintenance.a1, maintenance.a2, maintenance.a3, maintenance.a4, maintenance.a5, maintenance.stx, maintenance.a6, maintenance.a7,
                             cust_app.a1 AS client_name,
                             addresses.city, addresses.zone, addresses.street, addresses.building,
                             addresses.latitude, addresses.longitude
                      FROM maintenance
                      LEFT JOIN cust_app ON maintenance.a6 = cust_app.a3
                      LEFT JOIN addresses ON maintenance.a1 = addresses.id
                      WHERE 1=1 $stx
                      ORDER BY maintenance.id DESC";
    } else {
        $mainQuery = "SELECT id, a1, a2, a3, a4, a5, stx FROM maintenance WHERE a6 = '$uid' $stx";
    }
    $mainResult = $conx->query($mainQuery);
    while($rows=mysqli_fetch_assoc($mainResult)) {$mainarr[] = $rows;}
    sendResponse(true, '',$mainarr);
}



/**
 * uploadImagesMain
 */
function uploadImagesMain($input) {
    global $conx;

    if (empty($_FILES['images'])) {
        echo json_encode(['success' => false, 'message' => 'لا توجد صور']);
        exit;
    }

    $upload_dir = '../erp2026/assets/Maintenance/Images/';
    if (!file_exists($upload_dir)) {
        mkdir($upload_dir, 0777, true);
    }

    // ✅ شيك على آخر رقم موجود في الفولدر
    $existingFiles = glob($upload_dir . '*.{jpg,jpeg,png,gif,webp}', GLOB_BRACE);
    $lastNumber = 0;
    foreach ($existingFiles as $file) {
        $name = pathinfo($file, PATHINFO_FILENAME); // يجيب الاسم بدون extension
        if (is_numeric($name)) {
            $lastNumber = max($lastNumber, (int)$name);
        }
    }

    $uploadedFiles = [];
    $files = $_FILES['images'];
    $fileCount = count($files['name']);

    for ($i = 0; $i < $fileCount; $i++) {
        if ($files['error'][$i] !== UPLOAD_ERR_OK) continue;

        $lastNumber++; // ✅ يكمل من بعد آخر رقم
        $ext      = pathinfo($files['name'][$i], PATHINFO_EXTENSION);
        $filename = $lastNumber . '.' . $ext;
        $filepath = $upload_dir . $filename;

        if (move_uploaded_file($files['tmp_name'][$i], $filepath)) {
            $fileUrl = 'assets/Maintenance/Images/' . $filename;
            $uploadedFiles[] = $fileUrl;
        }
    }

    if (count($uploadedFiles) > 0) {
        echo json_encode([
            'success' => true,
            'message' => 'تم رفع ' . count($uploadedFiles) . ' صورة',
            'data'    => ['uploaded' => $uploadedFiles]
        ]);
    } else {
        echo json_encode(['success' => false, 'message' => 'فشل رفع الصور']);
    }
    exit;
}

/**
 * searchItems
 */
function searchItems($input) {
    global $conx;
    $kval = sanitize($input['kval']);
    $mainarr = array();
    $mainQuery = "SELECT items.id ,   items.a1 , items.a2 , items.a3 , lifts.a1 AS a1x , lifts.a2 AS a2x , lifts.a3 AS a3x , lifts.a4 , lifts.a5 , lifts.a6 , lifts.a7 , lifts.a8 , lifts.a9 , lifts.a10 , lifts.a11 , lifts.a12 , lifts.a13 , lifts.a14 , lifts.a15 , lifts.a16 FROM items LEFT JOIN lifts ON items.a4 = lifts.id WHERE items.a1 != 'null' AND ( items.a1 LIKE '%$kval%' OR items.a2 LIKE '%$kval%' OR items.a3 LIKE '%$kval%')";
    $mainResult = $conx->query($mainQuery);
    while($rows=mysqli_fetch_assoc($mainResult)) {$mainarr[] = $rows;}
    sendResponse(true, '',$mainarr);
}

/**
 * Whether this app uid is an ERP mobile admin (cust_app.a29 or users.a29 by phone).
 */
function isAppManagerUid($uid) {
    global $conx;
    $uid = sanitize($uid);
    if ($uid === '') {
        return false;
    }
    $phoneRaw = '';
    $qRole = "SELECT a2, a29 FROM cust_app WHERE a3 = '$uid' LIMIT 1";
    $resRole = $conx->query($qRole);
    if ($resRole && ($rowRole = mysqli_fetch_assoc($resRole))) {
        $phoneRaw = isset($rowRole['a2']) ? (string)$rowRole['a2'] : '';
        if ((string)$rowRole['a29'] === '1') {
            return true;
        }
    }
    if ($phoneRaw === '') {
        return false;
    }
    $phoneCanon = custAppPhoneCanonical8($phoneRaw);
    if ($phoneCanon === '') {
        return false;
    }
    $phoneEsc = sanitize($phoneCanon);
    $qErp = "SELECT a29 FROM users
             WHERE REPLACE(REPLACE(REPLACE(TRIM(a5), '+', ''), ' ', ''), '-', '') LIKE '%$phoneEsc'
             LIMIT 1";
    $resErp = $conx->query($qErp);
    if ($resErp && ($rowErp = mysqli_fetch_assoc($resErp)) && (string)$rowErp['a29'] === '1') {
        return true;
    }
    return false;
}

function maintenanceStatusLabel($stx) {
    $stx = trim((string)$stx);
    if ($stx === '' || $stx === '0') {
        return array('key' => 'pending', 'label' => 'معلق');
    }
    if ($stx === '2' || $stx === '9') {
        return array('key' => 'done', 'label' => 'منتهي');
    }
    return array('key' => 'active', 'label' => 'جاري');
}

function bookingStatusLabel($stl, $stb = '') {
    $stb = trim((string)$stb);
    if ($stb === '4') {
        return array('key' => 'pending', 'label' => 'مرفوض');
    }
    $stl = trim((string)$stl);
    if ($stl === '9') {
        return array('key' => 'done', 'label' => 'منتهي');
    }
    if ($stl === '' || $stl === '0') {
        return array('key' => 'pending', 'label' => 'معلق');
    }
    return array('key' => 'active', 'label' => 'جاري');
}

function formatAdminLocation($row) {
    $locParts = array_filter(array(
        isset($row['city']) ? $row['city'] : '',
        isset($row['zone']) ? $row['zone'] : '',
        isset($row['street']) ? $row['street'] : '',
        !empty($row['building']) ? ('مبنى ' . $row['building']) : '',
    ));
    return implode(' - ', $locParts);
}

/**
 * Admin search: bookings + maintenance only (each with address).
 * Maintenance distinguishes Normal vs Urgent. Managers only.
 */
function searchAdmin($input) {
    global $conx;
    $uid = isset($input['uid']) ? trim((string)$input['uid']) : '';
    $raw = '';
    if (isset($input['query'])) {
        $raw = trim((string)$input['query']);
    } elseif (isset($input['kval'])) {
        $raw = trim((string)$input['kval']);
    }
    if ($uid === '' || !isAppManagerUid($uid)) {
        sendResponse(false, 'غير مصرح', array());
        return;
    }
    if ($raw === '') {
        sendResponse(true, '', array());
        return;
    }
    $kval = sanitize($raw);
    $results = array();

    // Bookings
    $bookSql = "SELECT b.id, b.date, b.stl, b.stb, b.orderId,
                       c.a1 AS client_name,
                       a.city, a.zone, a.street, a.building
                FROM bookings b
                LEFT JOIN cust_app c ON b.uid = c.a3
                LEFT JOIN addresses a ON b.addressId = a.id
                WHERE CAST(b.id AS CHAR) LIKE '%$kval%'
                   OR CAST(IFNULL(b.orderId, '') AS CHAR) LIKE '%$kval%'
                   OR IFNULL(c.a1, '') LIKE '%$kval%'
                   OR IFNULL(a.city, '') LIKE '%$kval%'
                   OR IFNULL(a.zone, '') LIKE '%$kval%'
                   OR IFNULL(a.street, '') LIKE '%$kval%'
                   OR IFNULL(a.building, '') LIKE '%$kval%'
                ORDER BY b.id DESC
                LIMIT 50";
    $bookRes = $conx->query($bookSql);
    if ($bookRes) {
        while ($row = mysqli_fetch_assoc($bookRes)) {
            $st = bookingStatusLabel(
                isset($row['stl']) ? $row['stl'] : '',
                isset($row['stb']) ? $row['stb'] : ''
            );
            $location = formatAdminLocation($row);
            $results[] = array(
                'type' => 'booking',
                'subtype' => '',
                'id' => (string)$row['id'],
                'title' => 'حجز #' . $row['id'],
                'client_name' => isset($row['client_name']) ? (string)$row['client_name'] : '',
                'location' => $location,
                'status' => $st['label'],
                'status_key' => $st['key'],
                'date' => isset($row['date']) ? (string)$row['date'] : '',
                'description' => '',
                'type_label' => 'حجز',
            );
        }
    }

    // Maintenance (Normal + Urgent)
    $maintSql = "SELECT m.id, m.a2, m.a3, m.a5, m.stx,
                        c.a1 AS client_name,
                        a.city, a.zone, a.street, a.building
                 FROM maintenance m
                 LEFT JOIN cust_app c ON m.a6 = c.a3
                 LEFT JOIN addresses a ON m.a1 = a.id
                 WHERE CAST(m.id AS CHAR) LIKE '%$kval%'
                    OR m.a2 LIKE '%$kval%'
                    OR IFNULL(c.a1, '') LIKE '%$kval%'
                    OR IFNULL(a.city, '') LIKE '%$kval%'
                    OR IFNULL(a.zone, '') LIKE '%$kval%'
                    OR IFNULL(a.street, '') LIKE '%$kval%'
                    OR IFNULL(a.building, '') LIKE '%$kval%'
                    OR IFNULL(m.a5, '') LIKE '%$kval%'
                 ORDER BY m.id DESC
                 LIMIT 50";
    $maintRes = $conx->query($maintSql);
    if ($maintRes) {
        while ($row = mysqli_fetch_assoc($maintRes)) {
            $st = maintenanceStatusLabel(isset($row['stx']) ? $row['stx'] : '');
            $location = formatAdminLocation($row);
            $isUrgent = (isset($row['a5']) && (string)$row['a5'] === 'Urgent');
            $subtype = $isUrgent ? 'Urgent' : 'Normal';
            $typeLabel = $isUrgent ? 'صيانة عاجلة' : 'صيانة عادية';
            $results[] = array(
                'type' => 'maintenance',
                'subtype' => $subtype,
                'id' => (string)$row['id'],
                'title' => $typeLabel . ' #' . $row['id'],
                'client_name' => isset($row['client_name']) ? (string)$row['client_name'] : '',
                'location' => $location,
                'status' => $st['label'],
                'status_key' => $st['key'],
                'date' => isset($row['a3']) ? (string)$row['a3'] : '',
                'description' => isset($row['a2']) ? (string)$row['a2'] : '',
                'type_label' => $typeLabel,
            );
        }
    }

    sendResponse(true, '', $results);
}

/**
 * getPromos
 */
function getPromos($input) {
    $s3 = S3Storage::getInstance();
    $getImages = $s3->listFiles('Mobile_App/app_promos');
    $promosarr = array_map(function($getImages) {
        return 'https://daltaliftstech.s3.ap-south-1.amazonaws.com/Mobile_App/app_promos/' . basename($getImages).'?k='.time();
    }, $getImages);
    
    sendResponse(true, '', $promosarr);
}

/**
 * getPlayerIds
 */
function getPlayerIds($input) {
    global $conx;
    $playersarr = array();
    $playersQuery = "SELECT a7 as player_id FROM users WHERE a7 != 'null'";
    $playersResult = $conx->query($playersQuery);
    while($rows=mysqli_fetch_assoc($playersResult)) {$playersarr[] = $rows;}
    sendResponse(true, '',$playersarr);
}

/**
 * getNotify
 */
function getNotify($input) {
    global $conx;
    $uid = sanitize($input['uid']);
    $notifyarr = array();
    $notifyQuery = "SELECT * FROM notifications_center WHERE uid = '".$uid."' ORDER BY id DESC";
    $notifyResult = $conx->query($notifyQuery);
    while($rows=mysqli_fetch_assoc($notifyResult)) {$notifyarr[] = $rows;}
    sendResponse(true, '',$notifyarr);
}

/**
 * delNotify
 */
function delNotify($input) {
    global $conx;
    $ss = "";
    $id = sanitize($input['id']);
    $uid = sanitize($input['uid']);
    if ($id) {
        $ss = "WHERE id = '".$id."'";
    }
    if ($uid) {
        $ss = "WHERE uid = '".$uid."'";
    }
    $conx->query("DELETE FROM notifications_center $ss");
    
}

/**
 * getUpdates
 */
function getUpdates($input) {
    global $conx;
    $sId = "";
    $platform = "";
    
    $platform = strtolower(sanitize($input['platform']));
    $sql = "SELECT * FROM AppUpdate";
    $result = $conx->query($sql);
    
    if ($result->num_rows > 0) {
        $stores = array();
        while($row = mysqli_fetch_assoc($result)) {
            $stores[] = $row;
        }
        // اختيار الإصدار المناسب حسب المنصة
        if ($platform == 'ios') {
            echo json_encode($stores[1]);
        } else if ($platform == 'huawei') {
            echo json_encode($stores[2]);
        } else {
            // android - أول واحد (الصف الأول)
            echo json_encode($stores[0]);
        }
    } else {
        echo json_encode(["error" => "No data found"]);
    }
}


function getPresignedUrlS3($input) {
    $contractId = $input['contractId'] ?? '';
    $contractType = (string)($input['contractType'] ?? '');
    $bookingId = sanitize($input['bookingId'] ?? ($input['bookId'] ?? ''));
    if ($contractId === '' || $contractId === null) {
        $contractId = $bookingId !== '' ? $bookingId : '';
    }
    $contract_type = "";
    switch ($contractType) {
        case '1':
            $contract_type = "IIP_Contracts";
            break;
        case '2':
            $contract_type = "Maintenance_Contracts";
            break;
        case '3':
            $contract_type = "IIP_Contracts_Delivery";
            break;
        case '4':
            // عقد صيانة العملاء الجدد (ktype=4)
            $contract_type = "Maintenance_Contracts_New";
            break;
        default:
            if ($bookingId !== '') {
                $contract_type = "Maintenance_Contracts_New";
            }
            break;
    }
    if ($contractId === '' || $contract_type === '') {
        echo json_encode(['success' => false, 'message' => 'contractId/contractType required']);
        return;
    }
    $s3 = S3Storage::getInstance();
    $key = "Mobile_App/signatures/".$contract_type."/signature_{$contractId}.png";
    $url = $s3->presignedUploadUrl($key, 'image/png');
    echo json_encode([
        'success' => true,
        'url' => $url,
        'key' => $key,
        'contractId' => (string)$contractId,
    ]);
}

function getPresignedPdfUrl($input) {
    $contractId = $input['contractId'];
    $contractType = $input['contractType'];
    $contract_type = "";
    switch ($contractType) {
      case '1':
        $contract_type = "IIP Contracts";
        break;
      case '2':
        $contract_type = "Maintenance Contracts";
        break;
      default:
        break;
    }
    $s3 = S3Storage::getInstance();
    $key = "Mobile_App/contracts/".$contract_type."/contract_{$contractId}.pdf";
    $url = $s3->presignedUploadUrl($key, 'application/pdf');
    echo json_encode(['success' => true, 'url' => $url, 'key' => $key]);
}

function SavePdfKey($input) {
    global $conx;
    $contractId = sanitize($input['contractId']);
    $bookingId = sanitize($input['bookingId']);
    $s3Key = sanitize($input['s3Key']);
    $s3Url = S3_BASE_URL . $s3Key;
    $conx->query("UPDATE bookings SET stt = '1', contract_id = '$contractId' WHERE id = '$bookingId'");
    echo json_encode(['success' => true]);
}

function updateMaintenanceContract($input) {
    global $conx;
    $contractId = sanitize($input['contractId']);
    $conx->query("UPDATE contracts SET stx = '1' WHERE id = '$contractId' AND type = '5'");
    echo json_encode(['success' => true]);
}

function getContract($input) {
    global $conx;
    $contractUserId = sanitize($input['contractUserId']);
    $contractarr = array();
    $cntQuery = "SELECT stx FROM contracts WHERE a30 = '".$contractUserId."' AND type = '5'";
    $contractResult = $conx->query($cntQuery);
    while($rows=mysqli_fetch_assoc($contractResult)) {$contractarr[] = $rows;}
    sendResponse(true, '',$contractarr);
}

function getPresignedMaintenanceImageUrl($input) {
    $maintenanceId = $input['maintenanceId'];
    $userId = $input['userId'];
    $index = $input['index'];
    $ext = $input['ext'] ?? 'jpg';
    $type = $input['type'];

    $s3 = S3Storage::getInstance();
    $key = "Mobile_App/Maintenance/{$type}/Images/{$userId}/{$maintenanceId}/{$index}.{$ext}";
    $url = $s3->presignedUploadUrl($key, 'image/jpeg');

    echo json_encode(['success' => true, 'url' => $url, 'key' => $key]);
}

/**
 * Presigned PUT for profile photo (cust_app.a6). Client uploads then calls updateProfilePhoto.
 */
function getPresignedProfilePhotoUrl($input) {
    $uid = isset($input['userId']) ? sanitize($input['userId']) : (isset($input['uid']) ? sanitize($input['uid']) : '');
    $extRaw = isset($input['ext']) ? $input['ext'] : 'jpg';
    $ext = preg_replace('/[^a-z0-9]/i', '', $extRaw);
    if ($ext === '') {
        $ext = 'jpg';
    }
    $ts = isset($input['ts']) ? sanitize($input['ts']) : (string)round(microtime(true) * 1000);
    if ($uid === '') {
        echo json_encode(['success' => false, 'message' => 'uid required']);
        exit;
    }
    $s3 = S3Storage::getInstance();
    $key = "Mobile_App/Profile/{$uid}/photo_{$ts}.{$ext}";
    $mime = (strtolower($ext) === 'png') ? 'image/png' : 'image/jpeg';
    $url = $s3->presignedUploadUrl($key, $mime);
    $publicUrl = $s3->url($key);
    echo json_encode(['success' => true, 'url' => $url, 'key' => $key, 'publicUrl' => $publicUrl]);
    exit;
}

/**
 * Save profile image public URL to cust_app.a6 (mysqli).
 */
function updateProfilePhoto($input) {
    global $conx;
    $uid = sanitize($input['uid'] ?? '');
    $photo = sanitize($input['photo'] ?? '');
    if ($uid === '' || $photo === '') {
        sendResponse(false, 'بيانات ناقصة');
    }
    $conx->query("UPDATE cust_app SET a6 = '$photo' WHERE a3 = '$uid'");
    sendResponse(true, 'تم تحديث الصورة');
}

function getMaintenanceImages($input) {
  $maintenance_id = $input['maintenance_id'] ?? '';
  $user_id        = $input['user_id'] ?? '';
  $type           = trim((string)($input['type'] ?? 'Normal'));
  if ($type === '') $type = 'Normal';
  
  if (!$maintenance_id || !$user_id) {
      echo json_encode(['images' => []]);
      exit;
  }
  
  $s3 = S3Storage::getInstance();
  $candidates = array($type);
  $lower = strtolower($type);
  if ($lower === 'normal' || $lower === 'urgent') {
      $candidates[] = ucfirst($lower);
      $candidates[] = strtoupper($lower);
      $candidates[] = $lower;
  }
  if ($lower === 'normal') $candidates[] = 'Urgent';
  if ($lower === 'urgent') $candidates[] = 'Normal';
  $candidates = array_values(array_unique($candidates));

  $images = array();
  foreach ($candidates as $folderType) {
      $prefix = "Mobile_App/Maintenance/{$folderType}/Images/{$user_id}/{$maintenance_id}/";
      $keys = $s3->listFiles($prefix);
      if (!empty($keys)) {
          $images = array_map(fn($key) => $s3->url($key), $keys);
          break;
      }
  }
  echo json_encode(['images' => $images]);
}

function getProcessingImages($input) {
  $bookId = $input['bookId'];
  $processType = $input['processType'];
  
  $prefix = "Mobile_App/Processing/{$bookId}/{$processType}/";
  
  $s3   = S3Storage::getInstance();
  $keys = $s3->listFiles($prefix);
  $images = array_map(fn($key) => $s3->url($key), $keys);
  echo json_encode(['images' => $images]);
}

/**
 * Admin upload for stage photos — same path as ERP upload_handler:
 * Mobile_App/Processing/{bookId}/{processType}/{index}.{ext}
 */
function getPresignedProcessingImageUrl($input) {
    $adminUid = sanitize($input['uid'] ?? '');
    if ($adminUid === '' || !isAppManagerUid($adminUid)) {
        echo json_encode(['success' => false, 'message' => 'غير مصرح']);
        return;
    }

    $bookId = intval($input['bookId'] ?? 0);
    $processType = preg_replace('/[^a-zA-Z0-9_\-]/', '', (string)($input['processType'] ?? ''));
    $allowedTypes = array('importing', 'installation', 'playing', 'completed', 'waiting');
    if ($bookId <= 0 || $processType === '' || !in_array($processType, $allowedTypes, true)) {
        echo json_encode(['success' => false, 'message' => 'بيانات غير صحيحة']);
        return;
    }

    $extRaw = isset($input['ext']) ? (string)$input['ext'] : 'jpg';
    $ext = strtolower(preg_replace('/[^a-z0-9]/i', '', $extRaw));
    if ($ext === '') $ext = 'jpg';

    $contentType = isset($input['contentType']) ? (string)$input['contentType'] : '';
    $mimeMap = array(
        'jpg' => 'image/jpeg',
        'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'webp' => 'image/webp',
        'gif' => 'image/gif',
        'mp4' => 'video/mp4',
        'mov' => 'video/quicktime',
        'm4v' => 'video/x-m4v',
        'webm' => 'video/webm',
    );
    if ($contentType === '' || !isset($mimeMap[$ext])) {
        $contentType = $mimeMap[$ext] ?? 'image/jpeg';
    }

    $index = intval($input['index'] ?? 0);
    $s3 = S3Storage::getInstance();
    $prefix = "Mobile_App/Processing/{$bookId}/{$processType}/";

    if ($index <= 0) {
        $keys = $s3->listFiles($prefix);
        $max = 0;
        foreach ($keys as $key) {
            $base = basename((string)$key);
            if (preg_match('/^(\d+)\./', $base, $m)) {
                $max = max($max, intval($m[1]));
            }
        }
        $index = $max + 1;
    }
    if ($index <= 0) $index = 1;

    $key = $prefix . $index . '.' . $ext;
    $url = $s3->presignedUploadUrl($key, $contentType);
    echo json_encode([
        'success' => true,
        'url' => $url,
        'key' => $key,
        'index' => $index,
    ]);
}

/**
 * Admin deletes a stage photo from S3 (same Processing path as ERP).
 */
function deleteProcessingImage($input) {
    $adminUid = sanitize($input['uid'] ?? '');
    if ($adminUid === '' || !isAppManagerUid($adminUid)) {
        echo json_encode(['success' => false, 'message' => 'غير مصرح']);
        return;
    }

    $bookId = intval($input['bookId'] ?? 0);
    $processType = preg_replace('/[^a-zA-Z0-9_\-]/', '', (string)($input['processType'] ?? ''));
    $imageUrl = trim((string)($input['imageUrl'] ?? ''));
    $allowedTypes = array('importing', 'installation', 'playing', 'completed', 'waiting');
    if ($bookId <= 0 || $processType === '' || $imageUrl === '' || !in_array($processType, $allowedTypes, true)) {
        echo json_encode(['success' => false, 'message' => 'بيانات غير صحيحة']);
        return;
    }

    $s3 = S3Storage::getInstance();
    $key = method_exists($s3, 'keyFromUrl') ? $s3->keyFromUrl($imageUrl) : '';
    if ($key === '') {
        $base = 'https://daltaliftstech.s3.ap-south-1.amazonaws.com/';
        $key = ltrim(str_replace($base, '', $imageUrl), '/');
    }
    // Strip query string if any
    $key = preg_replace('/\?.*$/', '', $key);

    $expectedPrefix = "Mobile_App/Processing/{$bookId}/{$processType}/";
    if (strpos($key, $expectedPrefix) !== 0) {
        echo json_encode(['success' => false, 'message' => 'مسار غير صالح']);
        return;
    }

    try {
        $s3->delete($key);
        echo json_encode(['success' => true, 'message' => 'تم حذف الصورة']);
    } catch (Exception $e) {
        echo json_encode(['success' => false, 'message' => 'فشل حذف الصورة']);
    }
}

function getRejectionReason($input) {
    global $conx;
    $bookId = intval($input['bookId']);
    $row = $conx->query(
        "SELECT rejection_reason FROM bookings WHERE id = '$bookId'"
    )->fetch_assoc();
    echo json_encode([
        'rejection_reason' => $row['rejection_reason'] ?? ''
    ]);
}

function getChatMessages($input) {
    global $conx;
    $bookId = intval($input['bookId']);
    $msgs = [];
    $result = $conx->query(
        "SELECT sender, message FROM booking_chat_messages WHERE bookingId = '$bookId' ORDER BY id ASC"
    );
    if ($result) {
        while ($row = mysqli_fetch_assoc($result)) {
            $msgs[] = $row;
        }
    }

    echo json_encode([
        'success' => true,
        'messages' => $msgs,
    ]);
}

function sendClientChatMsg($input) {
    global $conx;
    $bookId = intval($input['bookId']);
    $message = $conx->real_escape_string($input['message'] ?? '');
    $conx->query(
        "INSERT INTO booking_chat_messages (bookingId, sender, message) VALUES ('$bookId', 'client', '$message')"
    );
    $existing = $conx->query(
        "SELECT id FROM booking_chat WHERE bookingId = '$bookId' LIMIT 1"
    )->fetch_assoc();
    if (empty($existing)) {
        $conx->query("INSERT INTO booking_chat (bookingId) VALUES ('$bookId')");
    }
    echo json_encode(['success' => true]);
}

function ensureBookingTypingTable($conx) {
    $conx->query("CREATE TABLE IF NOT EXISTS booking_typing (
        bookingId INT PRIMARY KEY,
        typing_admin DATETIME NULL,
        typing_client DATETIME NULL
    )");
}

function sendTypingIndicator($input) {
    global $conx;
    ensureBookingTypingTable($conx);
    $bookId = intval($input['bookId']);
    $sender = ($input['sender'] ?? '') === 'admin' ? 'admin' : 'client';
    $col = 'typing_' . $sender;

    $existing = $conx->query(
        "SELECT bookingId FROM booking_typing WHERE bookingId = '$bookId' LIMIT 1"
    )->fetch_assoc();
    if (empty($existing)) {
        $conx->query("INSERT INTO booking_typing (bookingId) VALUES ('$bookId')");
    }

    $conx->query(
        "UPDATE booking_typing SET $col = NOW() WHERE bookingId = '$bookId'"
    );
    echo json_encode(['success' => true]);
}

function checkTyping($input) {
    global $conx;
    ensureBookingTypingTable($conx);
    $bookId = intval($input['bookId'] ?? 0);
    $col = ($input['checkRole'] ?? '') == 'admin' ? 'typing_admin' : 'typing_client';
    $row = $conx->query(
        "SELECT TIMESTAMPDIFF(SECOND, $col, NOW()) AS diff_seconds
         FROM booking_typing WHERE bookingId='$bookId'"
    )->fetch_assoc();
    $isTyping = false;
    if ($row !== null && $row['diff_seconds'] !== null) {
        $isTyping = (int)$row['diff_seconds'] < 4;
    }
    echo json_encode(['typing' => $isTyping]);
}

function updateCounterRequest($input) {
    global $conx;
    $bookId = sanitize($input['bookId']) ?? '';
    $floors = sanitize($input['floors']) ?? '';
    $persons = sanitize($input['persons']) ?? '';
    $stbx = "";
    $stb = null;
    
    if (isset($input['stb'])) {
        $stb = sanitize($input['stb']) ?? '';
        $stbx = ", stb = '$stb'";  // ← سيميكولون مش فاصلة
    }
    
    $conx->query("UPDATE bookings SET floors = '$floors', persons = '$persons' $stbx WHERE id = '$bookId'");
    echo json_encode(['success' => true, 'stb' => $stb]);
}

function updateQuotationStx($input) {
    global $conx;
    $bookId = sanitize($input['bookId']) ?? '';
    $stx = sanitize($input['stx']) ?? '';
    
    $conx->query("UPDATE bookings SET stx = '$stx' WHERE id = '$bookId'");
    echo json_encode(['success' => true, 'stx' => $stx]);
}

/**
 * Client approved the contract PDF and is ready to sign.
 * Do NOT attach an old contract_id by customer name (caused reused signatures).
 */
function approveContract($input) {
    global $conx;
    $bookId = intval($input['bookId'] ?? 0);
    if ($bookId <= 0) {
        echo json_encode(['success' => false, 'message' => 'بيانات غير كاملة']);
        return;
    }
    $conx->query("UPDATE bookings SET stt = '2', contract_id = NULL WHERE id = '$bookId'");
    echo json_encode(['success' => true]);
}

function updateEnterClient($input) {
    global $conx;
    $bookId = sanitize($input['bookId']) ?? '';
    $enter = sanitize($input['enter']) ?? '';
    
    $conx->query("UPDATE bookings SET enter = '$enter' WHERE id = '$bookId'");
    echo json_encode(['success' => true, 'enter' => $enter]);
}

function getEnterClient($input) {
    global $conx;
    $bookId = sanitize($input['bookId']) ?? '';
    $bokxarr = array();
    $bokxQuery = "SELECT cust_app.a1 , bookings.enter FROM bookings LEFT JOIN cust_app ON bookings.uid = cust_app.a3 WHERE bookings.id = '$bookId'";
    $bokxResult = $conx->query($bokxQuery);
    while($rows=mysqli_fetch_assoc($bokxResult)) {$bokxarr[] = $rows;}
    sendResponse(true, '',$bokxarr);
}

function getCurrentContractMaint($input) {
    global $conx;
    $userId = sanitize($input['userId']) ?? '';
    $contyxarr = array();
    $contyxResult = $conx->query("SELECT id FROM contracts WHERE `type` = '5' AND a30 = '$userId'");
    while($rows=mysqli_fetch_assoc($contyxResult)) {$contyxarr[] = $rows;}
    sendResponse(true, '',$contyxarr);
}

function getComplaints($input) {
    global $conx;
    $userId = sanitize($input['userId']) ?? '';
    $complxarr = array();
    $complxResult = $conx->query("SELECT * FROM complaints WHERE userid = '$userId'");
    while($rows=mysqli_fetch_assoc($complxResult)) {$complxarr[] = $rows;}
    sendResponse(true, '',$complxarr);
}

function getMaintenanceDetails($input) {
    global $conx;
    $maintenanceId = sanitize($input['maintenanceId']) ?? '';
    $maintarr = array();
    $maintResult = $conx->query("SELECT maintenance.id, maintenance.a2, maintenance.a3, maintenance.a4, maintenance.a5, maintenance.a6, maintenance.a7, maintenance.stx,
        contracts.id AS contract_id,
        addresses.city, addresses.zone, addresses.street, addresses.building,
        hrusers.a1 AS hr_name, hrusers.a3 AS hr_phone,
        cust_app.a1 AS client_name, cust_app.a2 AS client_phone
        FROM maintenance
        LEFT JOIN addresses ON maintenance.a1 = addresses.id
        LEFT JOIN hrusers ON maintenance.a7 = hrusers.id
        LEFT JOIN contracts ON maintenance.a6 = contracts.a30
        LEFT JOIN cust_app ON maintenance.a6 = cust_app.a3
        WHERE maintenance.id = '$maintenanceId'");
    while($rows=mysqli_fetch_assoc($maintResult)) {$maintarr[] = $rows;}
    sendResponse(true, '',$maintarr);
}

function _notifyMaintenanceCustomer($customerUid, $title, $content, $extra = array()) {
    return _notifyBookingCustomer($customerUid, $title, $content, $extra);
}

/**
 * In-app + OneSignal push to a customer (cust_app.a3 = uid).
 * Returns list of subscription ids that were targeted.
 */
function _notifyBookingCustomer($customerUid, $title, $content, $extra = array()) {
    global $conx;
    $customerUid = sanitize($customerUid);
    $sentTo = array();
    $GLOBALS['_notify_push_attempted'] = false;
    if ($customerUid === '') return $sentTo;

    $titleEsc = sanitize($title);
    $contentEsc = sanitize($content);
    $date = date('Y-m-d');
    $time = date('h:i A');
    $conx->query(
        "INSERT INTO notifications_center(title, content, uid, date, time)
         VALUES('$titleEsc', '$contentEsc', '$customerUid', '$date', '$time')"
    );

    $players = $conx->query(
        "SELECT a7 FROM cust_app
         WHERE a3 = '$customerUid'
           AND a7 IS NOT NULL AND TRIM(a7) != '' AND LOWER(TRIM(a7)) != 'null'"
    );
    if ($players) {
        while ($row = mysqli_fetch_assoc($players)) {
            $sub = trim((string)($row['a7'] ?? ''));
            if ($sub === '') continue;
            $sentTo[] = $sub;
        }
    }

    $onesignalPath = __DIR__ . '/../erp2026/xtras/Onesignalnotification.php';
    if (!file_exists($onesignalPath)) {
        return $sentTo;
    }
    include_once($onesignalPath);
    if (!class_exists('OneSignalNotification')) {
        return $sentTo;
    }

    $onesignal = new OneSignalNotification();
    $payloadExtra = array_merge(array(
        'headings' => array('en' => $title, 'ar' => $title),
        'contents' => array('en' => $content, 'ar' => $content),
    ), $extra);

    foreach ($sentTo as $sub) {
        $onesignal->sendToUser($sub, $title, $content, $payloadExtra);
    }

    // Fallback: external_id = customer app uid (if OneSignal Login linked)
    if (empty($sentTo)) {
        $onesignal->sendToExternalId($customerUid, $title, $content, $payloadExtra);
    }

    $GLOBALS['_notify_push_attempted'] = true;
    return $sentTo;
}

function updateMaintenanceStatus($input) {
    global $conx;
    $adminUid = sanitize($input['uid'] ?? '');
    $maintenanceId = intval($input['maintenanceId'] ?? 0);
    $stx = sanitize($input['stx'] ?? '');
    $allowed = array('0', '1', '2');
    if ($adminUid === '' || $maintenanceId <= 0 || !in_array($stx, $allowed, true)) {
        sendResponse(false, 'بيانات غير صحيحة');
        return;
    }
    if (!isAppManagerUid($adminUid)) {
        sendResponse(false, 'غير مصرح');
        return;
    }
    $row = $conx->query("SELECT id, a6 FROM maintenance WHERE id = '$maintenanceId' LIMIT 1")->fetch_assoc();
    if (!$row) {
        sendResponse(false, 'الطلب غير موجود');
        return;
    }
    $conx->query("UPDATE maintenance SET stx = '$stx' WHERE id = '$maintenanceId'");
    $titles = array(
        '0' => array('طلب الصيانة معلّق', 'طلب الصيانة بانتظار بدء التنفيذ من فريق دلتا'),
        '1' => array('بدء تنفيذ الصيانة', 'فريق الصيانة بدأ العمل على طلبك وسيتم التواصل معك'),
        '2' => array('اكتملت الصيانة', 'تم إكمال طلب الصيانة بنجاح. شكراً لثقتكم في دلتا للمصاعد'),
    );
    _notifyMaintenanceCustomer($row['a6'] ?? '', $titles[$stx][0], $titles[$stx][1]);
    sendResponse(true, 'تم تحديث حالة الصيانة', array('maintenanceId' => $maintenanceId, 'stx' => $stx));
}

function getHrTechnicians($input) {
    global $conx;
    $adminUid = sanitize($input['uid'] ?? '');
    if ($adminUid === '' || !isAppManagerUid($adminUid)) {
        sendResponse(false, 'غير مصرح');
        return;
    }
    $list = array();
    $res = $conx->query(
        "SELECT id, a1, a3 FROM hrusers
         WHERE TRIM(IFNULL(a1,'')) != ''
         ORDER BY a1 ASC"
    );
    if ($res) {
        while ($row = mysqli_fetch_assoc($res)) {
            $list[] = $row;
        }
    }
    sendResponse(true, '', $list);
}

function getTechnicianWorkZone($input) {
    global $conx;
    $uid = sanitize($input['uid'] ?? '');
    if ($uid === '' || !isAppManagerUid($uid)) {
        sendResponse(false, 'غير مصرح');
        return;
    }
    $name = '';
    $phoneRaw = '';
    $q = $conx->query("SELECT a1, a2 FROM cust_app WHERE a3 = '$uid' LIMIT 1");
    if ($q && ($row = mysqli_fetch_assoc($q))) {
        $name = isset($row['a1']) ? (string)$row['a1'] : '';
        $phoneRaw = isset($row['a2']) ? (string)$row['a2'] : '';
    }
    $jobTitle = '';
    $phoneCanon = custAppPhoneCanonical8($phoneRaw);
    if ($phoneCanon !== '') {
        $phoneEsc = sanitize($phoneCanon);
        $erp = $conx->query(
            "SELECT a4 FROM users
             WHERE REPLACE(REPLACE(REPLACE(TRIM(a5), '+', ''), ' ', ''), '-', '') LIKE '%$phoneEsc'
             LIMIT 1"
        );
        if ($erp && ($er = mysqli_fetch_assoc($erp))) {
            $jobTitle = isset($er['a4']) ? trim((string)$er['a4']) : '';
        }
    }
    $branchName = '';
    $branchAddress = '';
    $br = $conx->query(
        "SELECT a2, a4 FROM branches WHERE stx = '1' AND TRIM(IFNULL(a2,'')) != '' ORDER BY id ASC LIMIT 1"
    );
    if ($br && ($b = mysqli_fetch_assoc($br))) {
        $branchName = isset($b['a2']) ? trim((string)$b['a2']) : '';
        $branchAddress = isset($b['a4']) ? trim((string)$b['a4']) : '';
    }
    // No per-technician branch_id/zone column exists on users/cust_app/hrusers.
    sendResponse(true, '', array(
        'name' => $name,
        'job_title' => $jobTitle,
        'assigned_zone' => '',
        'has_personal_zone' => 0,
        'branch_name' => $branchName,
        'branch_address' => $branchAddress,
    ));
}

function assignMaintenanceTech($input) {
    global $conx;
    $adminUid = sanitize($input['uid'] ?? '');
    $maintenanceId = intval($input['maintenanceId'] ?? 0);
    $hrId = intval($input['hrId'] ?? 0);
    if ($adminUid === '' || $maintenanceId <= 0 || $hrId <= 0) {
        sendResponse(false, 'بيانات غير صحيحة');
        return;
    }
    if (!isAppManagerUid($adminUid)) {
        sendResponse(false, 'غير مصرح');
        return;
    }
    $row = $conx->query("SELECT id, a6, stx FROM maintenance WHERE id = '$maintenanceId' LIMIT 1")->fetch_assoc();
    if (!$row) {
        sendResponse(false, 'الطلب غير موجود');
        return;
    }
    $conx->query("UPDATE maintenance SET a7 = '$hrId' WHERE id = '$maintenanceId'");
    $stx = trim((string)($row['stx'] ?? ''));
    if ($stx === '' || $stx === '0') {
        $conx->query("UPDATE maintenance SET stx = '1' WHERE id = '$maintenanceId'");
    }
    $tech = $conx->query("SELECT a1, a3 FROM hrusers WHERE id = '$hrId' LIMIT 1")->fetch_assoc();
    $techName = $tech && !empty($tech['a1']) ? $tech['a1'] : 'فني الصيانة';
    $techPhone = $tech && !empty($tech['a3']) ? trim((string)$tech['a3']) : '';
    $title = 'تعيين فني الصيانة';
    $body = $techPhone !== ''
        ? "تم تعيين الفني $techName ورقمه $techPhone لمتابعة طلب الصيانة رقم #$maintenanceId"
        : "تم تعيين $techName لمتابعة طلب الصيانة رقم #$maintenanceId";
    $GLOBALS['_notify_push_attempted'] = false;
    $playerIds = _notifyMaintenanceCustomer(
        $row['a6'] ?? '',
        $title,
        $body,
        array(
            'data' => array(
                'type' => 'maintenance_tech',
                'maintenanceId' => (string)$maintenanceId,
            ),
        )
    );
    sendResponse(true, 'تم تعيين الفني', array(
        'maintenanceId' => $maintenanceId,
        'hrId' => $hrId,
        'title' => $title,
        'content' => $body,
        'playerIds' => $playerIds,
        'customerUid' => $row['a6'] ?? '',
        'techName' => $techName,
        'pushAttempted' => !empty($GLOBALS['_notify_push_attempted']) ? 1 : 0,
    ));
}

function getDeliveryStatus($input) {
    global $conx;
    $bookId = sanitize($input['bookId']);
    $result = $conx->query("SELECT delivery_contract_id FROM bookings WHERE id = '$bookId'");
    $row = mysqli_fetch_assoc($result);
    $signed = !empty($row['delivery_contract_id']);
    echo json_encode([
        'success' => true,
        'signed' => $signed,
        'contractId' => $row['delivery_contract_id'] ?? '',
    ]);
    exit;
}

function saveDeliveryContract($input) {
    global $conx;
    $bookId = sanitize($input['bookId']);
    $contractId = sanitize($input['contractId']);
    $conx->query("UPDATE bookings SET delivery_contract_id = '$contractId' WHERE id = '$bookId'");
    sendResponse(true, 'تم حفظ محضر التسليم');
}

/**
 * Admin advances elevator execution stage (bookings.stl) + notifies customer.
 * Same effect as ERP statusId/stIndex update.
 */
function updateBookingStage($input) {
    global $conx;
    $adminUid = sanitize($input['uid'] ?? '');
    $bookId = intval($input['bookId'] ?? 0);
    $stage = intval($input['stage'] ?? 0);

    if ($adminUid === '' || $bookId <= 0 || $stage < 1 || $stage > 9) {
        sendResponse(false, 'بيانات غير صحيحة');
        return;
    }
    if (!isAppManagerUid($adminUid)) {
        sendResponse(false, 'غير مصرح');
        return;
    }

    $book = $conx->query(
        "SELECT id, uid, date FROM bookings WHERE id = '$bookId' LIMIT 1"
    )->fetch_assoc();
    if (!$book) {
        sendResponse(false, 'الطلب غير موجود');
        return;
    }

    $titles = array(
        1 => array('مرحلة التعاقد', 'تم توقيع العقد وجاري مراجعة كافة البنود والمتطلبات'),
        2 => array('طلب المصعد من المصنع', 'تم إرسال طلب التصنيع للمصنع بكافة المواصفات المطلوبة'),
        3 => array('تصنيع المصعد', 'المصنع يقوم حالياً بتصنيع مصعدك وفق المواصفات المتفق عليها'),
        4 => array('شحن المصعد', 'تم الانتهاء من التصنيع وجاري شحن المصعد من المصنع إلى الموقع'),
        5 => array('توريد المصعد', 'وصل المصعد إلى الموقع وجاري استلام كافة المكونات والتحقق منها'),
        6 => array('تركيب المصعد ميكانيكياً', 'يقوم فريقنا الفني بتركيب جميع الأجزاء الميكانيكية للمصعد'),
        7 => array('انتظار دخول الكهرباء للعقار', 'اكتمل التركيب الميكانيكي وننتظر توصيل الكهرباء للعقار لاستكمال التشغيل'),
        8 => array('تشغيل المصعد', 'جاري تشغيل المصعد واختباره والتأكد من سلامة كافة الأنظمة'),
        9 => array('تسليم المصعد', 'تم تسليم المصعد بنجاح ويعمل بكفاءة تامة، نتمنى لكم تجربة موفقة'),
    );
    $title = $titles[$stage][0];
    $content = $titles[$stage][1];
    $customerUid = sanitize($book['uid'] ?? '');

    $conx->query("UPDATE bookings SET stl = '$stage' WHERE id = '$bookId'");

    $playerIds = array();
    if ($customerUid !== '') {
        $playerIds = _notifyBookingCustomer($customerUid, $title, $content, array(
            'data' => array(
                'type' => 'booking_stage',
                'bookId' => (string)$bookId,
                'stage' => (string)$stage,
            ),
        ));
    }

    sendResponse(true, 'تم إرسال المرحلة للعميل', array(
        'bookId' => $bookId,
        'stage' => $stage,
        'title' => $title,
        'content' => $content,
        'customerUid' => $customerUid,
        'playerIds' => $playerIds,
    ));
}

/**
 * Notify customer that stage media (photo/video) was uploaded by admin.
 */
function notifyProcessingMedia($input) {
    global $conx;
    $adminUid = sanitize($input['uid'] ?? '');
    $bookId = intval($input['bookId'] ?? 0);
    $processType = preg_replace('/[^a-zA-Z0-9_\-]/', '', (string)($input['processType'] ?? ''));
    $mediaKind = sanitize($input['mediaKind'] ?? 'image');

    if ($adminUid === '' || $bookId <= 0 || $processType === '') {
        sendResponse(false, 'بيانات غير صحيحة');
        return;
    }
    if (!isAppManagerUid($adminUid)) {
        sendResponse(false, 'غير مصرح');
        return;
    }

    $book = $conx->query(
        "SELECT id, uid FROM bookings WHERE id = '$bookId' LIMIT 1"
    )->fetch_assoc();
    if (!$book) {
        sendResponse(false, 'الطلب غير موجود');
        return;
    }

    $labels = array(
        'importing' => 'صور توريد المصعد',
        'installation' => 'صورة التركيب الميكانيكي',
        'playing' => 'فيديو تشغيل المصعد',
        'waiting' => 'مستندات مرحلة الكهرباء',
        'completed' => 'محضر الاستلام',
    );
    $label = $labels[$processType] ?? 'تحديث مرحلة التنفيذ';
    if ($mediaKind === 'video') {
        $title = 'فيديو جديد في مراحل التنفيذ';
        $content = 'تم إضافة ' . $label . ' لطلبك. افتح مراحل التنفيذ لمشاهدته الآن.';
    } else if ($mediaKind === 'delivery') {
        $title = 'محضر الاستلام جاهز';
        $content = 'تم تجهيز محضر الاستلام لطلبك. يمكنك مراجعته والتوقيع من مراحل التنفيذ.';
    } else {
        $title = 'صور جديدة في مراحل التنفيذ';
        $content = 'تم إضافة ' . $label . ' لطلبك. افتح مراحل التنفيذ لمشاهدتها الآن.';
    }

    $playerIds = _notifyBookingCustomer(
        $book['uid'] ?? '',
        $title,
        $content,
        array(
            'data' => array(
                'type' => 'processing_media',
                'bookId' => (string)$bookId,
                'processType' => $processType,
            ),
        )
    );

    sendResponse(true, 'تم إشعار العميل', array(
        'bookId' => $bookId,
        'processType' => $processType,
        'playerIds' => $playerIds,
    ));
}

/**
 * Contact card for technicians.
 *
 * NOTE: There is no supervisor_id (or similar) column on cust_app / users.
 * Do not add one without an explicit product decision. Until then we surface
 * an ERP mobile admin (users.a29 = 1), else a configured operations-office fallback.
 */
function getSupervisorContact($input) {
    global $conx;

    $fallback = array(
        'name' => 'مكتب العمليات — دلتا للمصاعد',
        'role' => 'الإدارة العامة',
        'phone' => '44440111',
        'photo' => '',
        'is_fallback' => 1,
        'source' => 'operations_office',
    );

    $uid = sanitize($input['uid'] ?? ($input['technician_id'] ?? ''));
    $myPhone8 = '';
    if ($uid !== '') {
        $me = $conx->query("SELECT a2 FROM cust_app WHERE a3 = '$uid' LIMIT 1");
        if ($me && ($rowMe = mysqli_fetch_assoc($me))) {
            $myPhone8 = custAppPhoneCanonical8($rowMe['a2'] ?? '');
        }
    }

    $pick = null;
    $admins = $conx->query(
        "SELECT a1, a5 FROM users WHERE a29 = '1' AND a5 IS NOT NULL AND TRIM(a5) != '' ORDER BY a1 ASC"
    );
    if ($admins) {
        $first = null;
        while ($row = mysqli_fetch_assoc($admins)) {
            $phone8 = custAppPhoneCanonical8($row['a5'] ?? '');
            if ($first === null) $first = $row;
            if ($myPhone8 !== '' && $phone8 === $myPhone8) {
                continue;
            }
            $pick = $row;
            break;
        }
        if ($pick === null) $pick = $first;
    }

    if (!$pick) {
        sendResponse(true, '', $fallback);
        return;
    }

    $name = trim((string)($pick['a1'] ?? ''));
    $phone = trim((string)($pick['a5'] ?? ''));
    if ($name === '' || $phone === '') {
        sendResponse(true, '', $fallback);
        return;
    }

    $photo = '';
    $phone8 = custAppPhoneCanonical8($phone);
    if ($phone8 !== '') {
        $phoneEsc = sanitize($phone8);
        $app = $conx->query(
            "SELECT a6 FROM cust_app
             WHERE REPLACE(REPLACE(REPLACE(TRIM(a2), '+', ''), ' ', ''), '-', '') LIKE '%$phoneEsc'
             LIMIT 1"
        );
        if ($app && ($rowApp = mysqli_fetch_assoc($app))) {
            $photo = trim((string)($rowApp['a6'] ?? ''));
        }
    }

    sendResponse(true, '', array(
        'name' => $name,
        'role' => 'مشرف / إدارة التطبيق',
        'phone' => $phone,
        'photo' => $photo,
        'is_fallback' => 0,
        'source' => 'erp_mobile_admin',
    ));
}

mysqli_close($conx);
?>