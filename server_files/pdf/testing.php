<?php
// ============================================================
// index.php - توليد PDF ورفعه على S3 وإرجاع الـ URL
// ============================================================

// --- إعدادات S3 ---
define('AWS_ACCESS_KEY_ID',     'AKIA2TX3R2QV52YOCKTF');
define('AWS_SECRET_ACCESS_KEY', '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');
define('AWS_REGION',            'me-south-1');          // مثال: me-south-1
define('AWS_BUCKET',            'delta-lifts');     // مثال: delta-lifts
define('AWS_PDF_FOLDER',        'Mobile_App/contracts/');           // المجلد جوا الـ bucket



// --- الاستجابة دايماً JSON ---
header('Content-Type: application/json');

// --- باراميترات الطلب ---
$contractId = $_GET['contractId'] ?? null;
$sign       = $_GET['sign']       ?? 0;

if (!$contractId) {
    echo json_encode(['success' => false, 'error' => 'contractId مطلوب']);
    exit;
}

// --- الاتصال بالداتابيز ---
include("../xtras/config.php"); // $conx موجود هنا

// --- جلب بيانات العقد ---
$contracts = $conx->query("SELECT * FROM contracts WHERE id='$contractId'")->fetch_assoc();
if (!$contracts) {
    echo json_encode(['success' => false, 'error' => 'العقد مش موجود']);
    exit;
}

// --- جلب بيانات المصعد ---
$lift_id  = $contracts['a7'] ?? null;
$liftData = [];
if ($lift_id) {
    $liftRes = $conx->query("SELECT * FROM lifts WHERE id='$lift_id'");
    if ($liftRes && mysqli_num_rows($liftRes) > 0) {
        $liftData = mysqli_fetch_assoc($liftRes);
    }
}

// ============================================================
// توليد الـ PDF بـ mPDF
// ============================================================
require_once __DIR__ . '/vendor/autoload.php';

$mpdf = new \Mpdf\Mpdf([
    'mode'          => 'ar',
    'format'        => 'A4',
    'tempDir'       => __DIR__ . '/tmp',
    'fontDir'       => [__DIR__ . '/fonts/'],
    'fontdata'      => [
        'cairo' => [
            'R'          => 'Cairo-Regular-fixed.ttf',
            'B'          => 'Cairo-Bold-fixed.ttf',
            'useOTL'     => 0xFF,
            'useKashida' => 75,
        ]
    ],
    'default_font'  => 'cairo',
    'margin_top'    => 42,
    'margin_bottom' => 28,
    'margin_left'   => 10,
    'margin_right'  => 10,
    'margin_header' => 5,
    'margin_footer' => 5,
]);

$mpdf->SetDirectionality('rtl');

// Watermark
$mpdf->SetWatermarkImage(__DIR__ . '/assets/logo.png', 0.08, [150, 150]);
$mpdf->showWatermarkImage = true;

// Header
$header = '
<table width="100%" style="border-bottom:2px solid #CE2020; padding-bottom:6px;">
    <tr>
        <td><img src="' . __DIR__ . '/assets/header.png" height="55"/></td>
    </tr>
</table>';

// Footer
$footer = '
<div style="border-top:1px solid #CE2020; text-align:center; font-family:cairo; font-size:8px; padding-top:4px; direction:rtl;">
    <span>sales@deltatechnologys.com &nbsp;|&nbsp; +974 6374 3000 &nbsp;|&nbsp; +974 4365 4006 +974</span><br>
    <span>Salwa Road, Building No: 32 - First Floor - Office No: 31 - Doha - Qatar</span>
</div>';

$mpdf->SetHTMLHeader($header);
$mpdf->SetHTMLFooter($footer);

// المحتوى من ملف خارجي
ob_start();
include(__DIR__ . '/content.php');
$html = ob_get_clean();

$mpdf->WriteHTML($html);

// احفظ الـ PDF في tmp مؤقتاً
$filename  = 'contract_' . $contractId . '_' . time() . '.pdf';
$localPath = __DIR__ . '/tmp/' . $filename;
$mpdf->Output($localPath, 'F');

// ============================================================
// رفع الـ PDF على S3
// ============================================================
$s3Url = uploadToS3($localPath, AWS_PDF_FOLDER . $filename);

// امسح الملف المؤقت
if (file_exists($localPath)) {
    unlink($localPath);
}

if ($s3Url) {
    echo json_encode([
        'success' => true,
        'url'     => $s3Url,
    ]);
} else {
    echo json_encode([
        'success' => false,
        'error'   => 'فشل الرفع على S3',
    ]);
}

// ============================================================
// دالة الرفع على S3 (بدون SDK - Pure PHP)
// ============================================================
function uploadToS3($filePath, $s3Key) {
    $bucket    = AWS_BUCKET;
    $region    = AWS_REGION;
    $accessKey = AWS_ACCESS_KEY_ID;
    $secretKey = AWS_SECRET_ACCESS_KEY;

    $host      = "$bucket.s3.$region.amazonaws.com";
    $url       = "https://$host/$s3Key";

    $fileContent = file_get_contents($filePath);
    $contentType = 'application/pdf';
    $dateShort   = gmdate('Ymd');
    $dateLong    = gmdate('Ymd\THis\Z');
    $payloadHash = hash('sha256', $fileContent);

    // Canonical Request
    $canonicalHeaders = "content-type:$contentType\nhost:$host\nx-amz-content-sha256:$payloadHash\nx-amz-date:$dateLong\n";
    $signedHeaders    = "content-type;host;x-amz-content-sha256;x-amz-date";

    $canonicalRequest = implode("\n", [
        'PUT',
        '/' . $s3Key,
        '',
        $canonicalHeaders,
        $signedHeaders,
        $payloadHash,
    ]);

    // String to Sign
    $credentialScope = "$dateShort/$region/s3/aws4_request";
    $stringToSign    = implode("\n", [
        'AWS4-HMAC-SHA256',
        $dateLong,
        $credentialScope,
        hash('sha256', $canonicalRequest),
    ]);

    // Signing Key
    $signingKey = hmacSha256(
        hmacSha256(
            hmacSha256(
                hmacSha256("AWS4$secretKey", $dateShort, true),
                $region, true
            ),
            's3', true
        ),
        'aws4_request', true
    );

    $signature    = hash_hmac('sha256', $stringToSign, $signingKey);
    $authorization = "AWS4-HMAC-SHA256 Credential=$accessKey/$credentialScope, SignedHeaders=$signedHeaders, Signature=$signature";

    // cURL PUT Request
    $ch = curl_init($url);
    curl_setopt_array($ch, [
        CURLOPT_CUSTOMREQUEST  => 'PUT',
        CURLOPT_POSTFIELDS     => $fileContent,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_HTTPHEADER     => [
            "Content-Type: $contentType",
            "x-amz-content-sha256: $payloadHash",
            "x-amz-date: $dateLong",
            "Authorization: $authorization",
            "Content-Length: " . strlen($fileContent),
        ],
    ]);

    $response   = curl_exec($ch);
    $httpCode   = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    if ($httpCode === 200) {
        return $url; // رجّع الـ URL العام
    }

    error_log("S3 Upload Error: HTTP $httpCode - $response");
    return false;
}

function hmacSha256($key, $data, $raw = false) {
    return hash_hmac('sha256', $data, $key, $raw);
}
?>