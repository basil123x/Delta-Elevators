<?
error_reporting(E_ALL);
ini_set('display_errors', 1);
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
    case 'profile':
        getUserProfile($input);
        break;
    case 'updateProfile':
        updateProfile($input);
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
    case 'getMyBookingOne':
        getMyBookingOne($input);
        break;
    case 'getMyBookingDet':
        getMyBookingDet($input);
        break;
    case 'getMyBookingDet':
        getMyBookingDet($input);
        break;
    case 'addContract':
        addContract($input);
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
    case 'getMaintenanceImages':
        getMaintenanceImages($input);
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
    
    $phone = sanitize($input['phone']);
    $playerId = sanitize($input['playerId']);
    
    if (!preg_match('/^[0-9]{8}$/', $phone)) {
        sendResponse(false, 'رقم الهاتف يجب أن يكون 8 أرقام');
    }

    
    $userQuery = "SELECT id, a1, a2, a3, a4, a5, a6 FROM cust_app WHERE a2 = '$phone'";
    $userResult = mysqli_query($conx, $userQuery);
    
    // ✅ الإصلاح: التحقق من النتيجة
    if ($userResult && mysqli_num_rows($userResult) > 0) {
        $user = mysqli_fetch_assoc($userResult);
        $userIdQuery = $conx->query("SELECT id FROM cust_app WHERE a2 = '$phone'")->fetch_assoc();
        $idx = $userIdQuery['id'];
        $conx->query("UPDATE cust_app SET a7 = '$playerId' WHERE id = '$idx'");
        sendResponse(true, 'تم تسجيل الدخول بنجاح', $user);
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
    $phone = sanitize($input['phone']);
    $created_at = sanitize($input['created_at']);
    $uid = sanitize($input['uid']);
    $oid = sanitize($input['oid']);
    $playerId = sanitize($input['playerId']);
    


    
    $userQuery = "SELECT * FROM cust_app WHERE a2 = '$phone'";
    $userResult = $conx->query($userQuery);
    
    if ($userResult && mysqli_num_rows($userResult) > 0) {
        sendResponse(false, 'المستخدم موجود بالفعل');
    } else {
        $insertQuery = "INSERT INTO cust_app (a1, a2, a3, a4, a5, a7,  stx) VALUES ('$name', '$phone', '$uid', '$oid', '$created_at', '$playerId', '1')";
        if (mysqli_query($conx, $insertQuery)) {
            sendResponse(true, 'تم التسجيل بنجاح');
        } else {
            sendResponse(false, 'حدث خطأ أثناء التسجيل');
        }
    }
}

/**
 * checkUser
 */
function checkUser($input) {
    global $conx;

    $phone = sanitize($input['phone']);
    
    $userQuery = "SELECT * FROM cust_app WHERE a2 = '$phone'";
    $userResult = $conx->query($userQuery);
    
    if ($userResult && mysqli_num_rows($userResult) > 0) {
        sendResponse(true, 'تم التسجيل بنجاح');
    } else {
        sendResponse(false, 'المستخدم موجود بالفعل');
    }
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
    
    $userQuery = "SELECT a1, a2, a5 FROM cust_app WHERE a3 = '$uid'";
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
    $bookxQuery = "SELECT bookings.id , bookings.stt , bookings.stl , bookings.orderId , bookings.date , addresses.city , addresses.zone , addresses.street , addresses.building , addresses.latitude , addresses.longitude , cust_app.a1 , cust_app.a2 , addresses.uid , bookings.contract_id , contracts.a15 , contracts.a16 , contracts.a17 , contracts.a18 FROM bookings LEFT JOIN addresses ON bookings.addressId = addresses.id LEFT JOIN cust_app ON bookings.uid = cust_app.a3 LEFT JOIN contracts ON bookings.contract_id = contracts.id WHERE bookings.id = '$bookId'";
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
    $a16 = sanitize($input['a16']);
    $a17 = sanitize($input['a17']);
    $a18 = sanitize($input['a18']);
    $a19 = sanitize($input['a19']);
    $a20 = sanitize($input['a20']);
    $a15 = (int)$a16 + (int)$a17 + (int)$a18;
    $a30 = sanitize($input['a30']);
    
    $conx->query("INSERT INTO contracts(type, a2, a3, a15, a16, a17, a18, a19, a20, a30, clx) VALUES('$type', '$a2', '$a3', '$a15', '$a16', '$a17', '$a18','$a19','$a20', '$a30','1')");
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
 * addComplaint
 */
function addComplaint($input) {
    global $conx;
    $name = sanitize($input['name']);
    $mobile = sanitize($input['mobile']);
    $msg = sanitize($input['msg']);
    $conx->query("INSERT INTO complaints VALUES(NULL, '$name', '$mobile', '$msg')");
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
        return 'https://daltalifts.com/erp2026/assets/app_promos/' . basename($file).'?k='.time();
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
    $notifyQuery = "SELECT * FROM notifications_center WHERE uid = '$uid'";
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
    if ($id) {
        $ss = "WHERE id = '$id'";
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
    $sql = "SELECT * FROM AppUpdate ORDER BY id DESC LIMIT 2";
    $result = $conx->query($sql);
    
    if ($result->num_rows > 0) {
        $stores = array();
        while($row = mysqli_fetch_assoc($result)) {
            $stores[] = $row;
        }
        
        // اختيار الإصدار المناسب حسب المنصة
        if ($platform == 'ios') {
            echo json_encode($stores[0]);
        } else {
            // android - أول واحد (الصف الأول)
            echo json_encode($stores[1]);
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
    $cntQuery = "SELECT stx FROM contracts WHERE a30 = '$contractUserId' AND type = '5'";
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


mysqli_close($conx);
?>