<?
ini_set('display_errors', 1);
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

// Get request data
$input = json_decode(file_get_contents('php://input'), true);

$action = isset($input['action']) ? $input['action'] : (isset($_POST['action']) ? $_POST['action'] : '');

function sanitize($data) {
    global $conx;
    return mysqli_real_escape_string($conx, trim($data));
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
    case 'search':
        searchItems($input);
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
    case 'updateCounterRequest':
        updateCounterRequest($input);
        break;
    case 'updateQuotationStx':
        updateQuotationStx($input);
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
    $bookxQuery = "SELECT bookings.*, addresses.city , addresses.zone , addresses.street , addresses.building , bookings.uid , bookings.orderId FROM addresses RIGHT JOIN bookings ON addresses.id = bookings.addressId WHERE bookings.uid = '$uid' $stx";
    $bookxResult = $conx->query($bookxQuery);
    while($rows=mysqli_fetch_assoc($bookxResult)) {$bookarr[] = $rows;}
    sendResponse(true, '',$bookarr);
}

/**
 * Home dashboard: active / completed bookings (same stl rules as getMyBookings) + last booking date.
 */
function getDashboard($input) {
    global $conx;
    $uidRaw = isset($input['uid']) ? trim((string)$input['uid']) : '';
    if ($uidRaw === '') {
        sendResponse(true, '', array(
            'active_orders' => 0,
            'completed_orders' => 0,
            'last_order_date' => '',
        ));
    }
    $uid = sanitize($uidRaw);

    $active = 0;
    $completed = 0;
    $lastDate = '';

    $qActive = "SELECT COUNT(*) AS c FROM bookings WHERE uid = '$uid' AND stl IN ('1','2','3','4','5','6','7','8')";
    $resA = $conx->query($qActive);
    if ($resA && ($rowA = mysqli_fetch_assoc($resA))) {
        $active = (int)$rowA['c'];
    }

    $qDone = "SELECT COUNT(*) AS c FROM bookings WHERE uid = '$uid' AND stl = '9'";
    $resD = $conx->query($qDone);
    if ($resD && ($rowD = mysqli_fetch_assoc($resD))) {
        $completed = (int)$rowD['c'];
    }

    $qLast = "SELECT MAX(`date`) AS last_date FROM bookings WHERE uid = '$uid'";
    $resL = $conx->query($qLast);
    if ($resL && ($rowL = mysqli_fetch_assoc($resL)) && $rowL['last_date'] !== null && $rowL['last_date'] !== '') {
        $lastDate = $rowL['last_date'];
    }

    sendResponse(true, '', array(
        'active_orders' => $active,
        'completed_orders' => $completed,
        'last_order_date' => $lastDate,
    ));
}

/**
 * get My Booking
 */
function getMyBookingOne($input) {
    global $conx;
    $bookid = sanitize($input['bookid']);
    $bookarr = array();
    $bookxQuery = "SELECT stx, stt, stl FROM bookings WHERE id = '$bookid'";
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
    $bookxQuery = "SELECT bookings.id , bookings.stt , bookings.stl , bookings.stb ,bookings.floors , bookings.persons , bookings.orderId , bookings.date , addresses.city , addresses.zone , addresses.street , addresses.building , addresses.latitude , addresses.longitude , cust_app.a1 , cust_app.a2 , addresses.uid , bookings.contract_id , contracts.a15 , contracts.a16 , contracts.a17 , contracts.a18 FROM bookings LEFT JOIN addresses ON bookings.addressId = addresses.id LEFT JOIN cust_app ON bookings.uid = cust_app.a3 LEFT JOIN contracts ON bookings.contract_id = contracts.id WHERE bookings.id = '$bookId'";
    $bookxResult = $conx->query($bookxQuery);
    while($rows=mysqli_fetch_assoc($bookxResult)) {$bookarr[] = $rows;}
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
    $contractId = sanitize($input['contractId']);

    // لو جاي s3Key يعني الرفع على S3
    if (!empty($input['s3Key'])) {
        $s3Key = sanitize($input['s3Key']);
        $s3Url = S3_BASE_URL . $s3Key;
        echo json_encode(['success' => true, 'message' => 'تم حفظ التوقيع']);
        exit;
    }

    // الكود القديم — لو جاي base64 (fallback)
    $signature = sanitize($input['signature']);
    if (empty($contractId) || empty($signature)) {
        echo json_encode(['success' => false, 'message' => 'بيانات غير كاملة']);
        exit;
    }
    $upload_dir = '../erp2026/assets/signatures/';
    if (!file_exists($upload_dir)) mkdir($upload_dir, 0777, true);
    $filename = 'signature_' . $contractId . '.png';
    $filepath = $upload_dir . $filename;
    $image_data = base64_decode($signature);
    if (file_put_contents($filepath, $image_data)) {
        echo json_encode(['success' => true, 'message' => 'تم حفظ التوقيع بنجاح']);
    } else {
        echo json_encode(['success' => false, 'message' => 'فشل في حفظ الصورة']);
    }
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
                $stx = "AND a5 = 'Normal'";
                break;
            case '2':
                $stx = "AND a5 = 'Urgent'";
                break;
            default:
                $stx = "";
                break;
        }
    }
    $mainarr = array();
    $mainQuery = "SELECT id, a1, a2, a3, a4, a5, stx FROM maintenance WHERE a6 = '$uid' $stx";
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
    $contractId = $input['contractId'];
    $contractType = $input['contractType'];
    $contract_type = "";
    switch ($contractType) {
        case '1':
            $contract_type = "IIP_Contracts";
            break;
        case '2':
            $contract_type = "Maintenance_Contracts";
            break;
        default:
            break;
    }
    $s3 = S3Storage::getInstance();
    $key = "Mobile_App/signatures/".$contract_type."/signature_{$contractId}.png";
    $url = $s3->presignedUploadUrl($key, 'image/png');
    echo json_encode(['success' => true, 'url' => $url, 'key' => $key]);
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
  $getMaintenanceImages = $input['getMaintenanceImages'] ?? '';
  $maintenance_id = $input['maintenance_id'] ?? '';
  $user_id        = $input['user_id'] ?? '';
  $type           = $input['type'] ?? 'Normal';
  
  if (!$maintenance_id || !$user_id) {
      echo json_encode(['images' => []]);
      exit;
  }
  
  $prefix = "Mobile_App/Maintenance/{$type}/Images/{$user_id}/{$maintenance_id}/";
  
  $s3   = S3Storage::getInstance();
  $keys = $s3->listFiles($prefix);
  $images = array_map(fn($key) => $s3->url($key), $keys);
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
    $maintResult = $conx->query("SELECT maintenance.id , maintenance.a2 , maintenance.a3 , maintenance.a4 , maintenance.a5 , contracts.id AS contract_id , addresses.city , addresses.zone , addresses.street , addresses.building , hrusers.a1 AS hr_name , hrusers.a3 AS hr_phone FROM maintenance LEFT JOIN addresses ON maintenance.a1 = addresses.id LEFT JOIN hrusers ON maintenance.a7 = hrusers.id LEFT JOIN contracts ON maintenance.a6 = contracts.a30 WHERE maintenance.id = '$maintenanceId'");
    while($rows=mysqli_fetch_assoc($maintResult)) {$maintarr[] = $rows;}
    sendResponse(true, '',$maintarr);
}

mysqli_close($conx);
?>