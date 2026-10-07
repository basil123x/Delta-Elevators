<?php
/**
 * New-client maintenance contract PDF body (ktype=4).
 * Signature must resolve by contracts.id (GET contractId), not only bookings.contract_id.
 */
include("../xtras/config.php");
if (!class_exists('S3Storage')) {
    @include_once(__DIR__ . '/../../erp2026/xtras/UploadS3.php');
}

$batchId = mysqli_real_escape_string($conx, (string)($_GET['batchId'] ?? ''));
$contractIdParam = trim((string)($_GET['contractId'] ?? ''));

$cont = null;
if ($batchId !== '') {
    $cont = $conx->query("
        SELECT bookings.date, bookings.id, bookings.contract_id, bookings.uid,
               addresses.building, addresses.zone, addresses.street, addresses.city,
               cust_app.a1, cust_app.a2
        FROM bookings
        LEFT JOIN addresses ON bookings.addressId = addresses.id
        LEFT JOIN cust_app ON bookings.uid = cust_app.a3
        WHERE bookings.id = '$batchId'
        LIMIT 1
    ")->fetch_assoc();
}

if (!$cont) {
    $cont = [
        'date' => date('Y-m-d'),
        'id' => $batchId,
        'contract_id' => $contractIdParam,
        'uid' => '',
        'building' => '',
        'zone' => '',
        'street' => '',
        'city' => '',
        'a1' => '',
        'a2' => '',
    ];
}

$days = [
    'Saturday'  => 'السبت',
    'Sunday'    => 'الأحد',
    'Monday'    => 'الاثنين',
    'Tuesday'   => 'الثلاثاء',
    'Wednesday' => 'الأربعاء',
    'Thursday'  => 'الخميس',
    'Friday'    => 'الجمعة',
];
$dayName = $days[date('l', strtotime((string)($cont['date'] ?? 'now')))] ?? '';

// Prefer the contract being generated (GET), then booking.contract_id, then booking id.
$signCandidates = array_values(array_unique(array_filter([
    $contractIdParam,
    trim((string)($cont['contract_id'] ?? '')),
    trim((string)($cont['id'] ?? '')),
    $batchId,
], function ($v) {
    return $v !== '' && $v !== '0' && strtolower($v) !== 'null';
})));

$folders = [
    'Maintenance_Contracts_New',
    'Maintenance_Contracts',
    '', // legacy bug path: Mobile_App/signatures//signature_X.png
];

$signLocal = '';
$signOk = false;

/**
 * Try to materialize a valid PNG signature into tmp for mPDF.
 */
$tryLoadSign = function ($key) use (&$signLocal, &$signOk) {
    $signLocal = __DIR__ . '/tmp/sign_maint_' . md5($key) . '.png';
    $bytes = false;

    // 1) Public URL
    $publicUrl = 'https://daltaliftstech.s3.ap-south-1.amazonaws.com/' . $key;
    $bytes = @file_get_contents($publicUrl);

    // 2) Authenticated S3 if public fails / XML error
    $looksBad = ($bytes === false)
        || strlen((string)$bytes) < 100
        || (stripos((string)$bytes, '<Error>') !== false)
        || (strpos(ltrim((string)$bytes), '<?xml') === 0);

    if ($looksBad && class_exists('S3Storage')) {
        try {
            $s3 = S3Storage::getInstance();
            if (method_exists($s3, 'exists') && !$s3->exists($key)) {
                return false;
            }
            if (method_exists($s3, 'presignedUrl')) {
                $tmpUrl = $s3->presignedUrl($key, 300);
                $bytes = @file_get_contents($tmpUrl);
            }
        } catch (Throwable $e) {
            $bytes = false;
        }
    }

    if ($bytes === false || strlen((string)$bytes) < 100) {
        return false;
    }
    if (stripos((string)$bytes, '<Error>') !== false || strpos(ltrim((string)$bytes), '<?xml') === 0) {
        return false;
    }

    @file_put_contents($signLocal, $bytes);
    $info = @getimagesize($signLocal);
    if (!is_array($info) || empty($info[0])) {
        @unlink($signLocal);
        return false;
    }
    $signOk = true;
    return true;
};

foreach ($signCandidates as $sid) {
    foreach ($folders as $folder) {
        $key = $folder === ''
            ? "Mobile_App/signatures/signature_{$sid}.png"
            : "Mobile_App/signatures/{$folder}/signature_{$sid}.png";
        // Also try the double-slash legacy key explicitly
        $keys = [$key];
        if ($folder === '') {
            $keys[] = "Mobile_App/signatures//signature_{$sid}.png";
        }
        foreach ($keys as $k) {
            if ($tryLoadSign($k)) {
                break 3;
            }
        }
    }
}

// If found on legacy path, also copy to canonical folder for ERP/system.
if ($signOk && $contractIdParam !== '' && class_exists('S3Storage')) {
    try {
        $canonical = "Mobile_App/signatures/Maintenance_Contracts_New/signature_{$contractIdParam}.png";
        $s3 = S3Storage::getInstance();
        if (!$s3->exists($canonical) && is_file($signLocal)) {
            $s3->upload($signLocal, $canonical, 'public-read');
        }
    } catch (Throwable $e) {
        // non-fatal
    }
}
?>

<div class="content" style="margin:0 43px;">
    <h2 style="text-align:center;">عقد صيانة مصعد</h2>

    <p style="font-weight:bold;">
        إنه في يوم <?= $dayName ?> الموافق
        <span dir="ltr"><?= htmlspecialchars((string)($cont['date'] ?? ''), ENT_QUOTES, 'UTF-8') ?></span> م
        تم الاتفاق فيما بين:
    </p>

    <p style="font-weight:bold;">أولاً: إلى الفاضل: <?= htmlspecialchars((string)($cont['a1'] ?? ''), ENT_QUOTES, 'UTF-8') ?></p>
    <p style="font-weight:bold;">العنوان: <?= htmlspecialchars((string)($cont['city'] ?? ''), ENT_QUOTES, 'UTF-8') ?> - <?= htmlspecialchars((string)($cont['zone'] ?? ''), ENT_QUOTES, 'UTF-8') ?> - مبنى <?= htmlspecialchars((string)($cont['building'] ?? ''), ENT_QUOTES, 'UTF-8') ?></p>
    <p style="font-weight:bold;">تليفون: <?= htmlspecialchars((string)($cont['a2'] ?? ''), ENT_QUOTES, 'UTF-8') ?></p>
    <p style="font-weight:bold; padding-bottom:20px;">- طرف أول</p>

    <p style="font-weight:bold;">ثانياً: السادة/ شركة دلتا لتكنولوجيا المصاعد ذ.م.م</p>
    <p style="font-weight:bold;">ويمثلها: المهندس/ محمد رأفت</p>
    <p style="font-weight:bold;">الدوحة - قطر</p>
    <p style="font-weight:bold;">تليفون: 77710600</p>
    <p style="font-weight:bold; padding-bottom:20px;">- طرف ثاني</p>

    <p style="font-weight:bold;">أن الطرف الثاني بصفته مسؤول صيانة المصعد يقدم للطرف الأول عقد صيانة للمصعد الخاص بهم.</p>
    <p style="font-weight:bold;">وقد اتفق الطرفان على الشروط التالية:</p>

    <p style="text-align:center; font-weight:bold;">بند (1)</p>
    <p style="font-weight:bold;">تعتبر الديباجة المتقدمة ذكرها جزءاً لا يتجزأ من هذا العقد.</p>

    <p style="text-align:center; font-weight:bold;">بند (2)</p>
    <p style="font-weight:bold;">يقوم الطرف الثاني بصيانة عدد (1) مصعد اعتباراً من بداية تاريخ التعاقد.</p>

    <p style="text-align:center; font-weight:bold;">بند (3)</p>
    <p style="font-weight:bold;">يلتزم الطرف الثاني خلال مدة العقد بالآتي:</p>
    <ol style="padding-right:20px; font-weight:bold; line-height:2;">
        <li>الكشف الدوري مرة كل شهر على جميع أجهزة المصعد.</li>
        <li>تنظيف مختلف الأدوات والمعدات والأجهزة الخاصة بالمصعد.</li>
        <li>القيام بجميع أعمال الضبط والتحكم والتدقيق اللازمة لحسن سير المصعد.</li>
        <li>تزييت وتشحيم جميع القطع المعرضة للاحتكاك.</li>
        <li>التأكد من أن جميع أجهزة الأمان بالمصاعد تعمل بانتظام.</li>
        <li>تصليح أي خلل يطرأ على المصعد وإعادته إلى حالته السليمة بمجرد الإبلاغ.</li>
        <li>تسليم تقارير الصيانة الشهرية للطرف الأول.</li>
        <li>تلبية الأعطال خلال فترة العقد — <strong>الصيانة العاجلة من 30 إلى 60 دقيقة.</strong></li>
    </ol>

    <p style="text-align:center; font-weight:bold;">بند (4)</p>
    <p style="font-weight:bold;">يلتزم الطرف الثاني بنظافة وتلميع كابينة وأبواب المصاعد.</p>

    <p style="text-align:center; font-weight:bold;">بند (5)</p>
    <p style="font-weight:bold;">يقر كل من الطرفين بأنه اتخذ له محلاً مختاراً على العنوان المبين قرين اسمه.</p>

    <p style="text-align:center; font-weight:bold;">بند (6)</p>
    <p style="font-weight:bold;">يلتزم الطرف الأول بدفع مبلغ (2000) ريال قطري سنوياً للمصعد.</p>
    <p style="font-weight:bold;">*عقد الصيانة يشمل الصيانة للمصعد + تبديل قطع الغيار*</p>

    <p style="font-weight:bold;">حرر هذا العقد من نسختين يحتفظ كل طرف بنسخة منه.</p>

    <div style="height:40px;"></div>

    <table width="100%" style="border-collapse:collapse;">
        <tr>
            <td width="50%" style="padding:8px; text-align:right; vertical-align:top;">
                <p style="font-weight:bold;">الطرف الأول:</p>
                <p style="font-weight:bold;">السيد: <?= htmlspecialchars((string)($cont['a1'] ?? ''), ENT_QUOTES, 'UTF-8') ?></p>
                <p style="font-weight:bold;">التوقيع:</p>
                <?php if (!empty($_GET['sign']) && $signOk && is_file($signLocal)): ?>
                <img src="<?= htmlspecialchars($signLocal, ENT_QUOTES, 'UTF-8') ?>"
                     width="100px" style="margin-top:4px; height:auto;">
                <?php else: ?>
                <p>_______________</p>
                <?php endif; ?>
            </td>
            <td width="50%" style="padding:8px; text-align:right; vertical-align:top;">
                <p style="font-weight:bold;">الطرف الثاني:</p>
                <p style="font-weight:bold;">دلتا لتكنولوجيا المصاعد والتجارة ذ.م.م</p>
                <p style="font-weight:bold;">التوقيع:</p>
            </td>
        </tr>
    </table>
</div>
