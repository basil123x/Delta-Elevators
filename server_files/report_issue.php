<?php
/**
 * Technician issue reports API.
 * POST JSON: { action: reportIssue | getPresignedIssueAttachmentUrl, ... }
 */
ini_set('display_errors', 0);
error_reporting(E_ALL);
include(__DIR__ . '/xtras/config.php');
include(__DIR__ . '/../erp2026/xtras/UploadS3.php');

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
header('Content-Type: application/json; charset=utf-8');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

$input = json_decode(file_get_contents('php://input'), true);
if (!is_array($input)) {
    $input = $_POST;
}
$action = isset($input['action']) ? (string)$input['action'] : '';

function reportIssueSanitize($data) {
    global $conx;
    if ($data === null) $data = '';
    return mysqli_real_escape_string($conx, trim((string)$data));
}

function reportIssueRespond($success, $message, $data = null) {
    $out = ['success' => $success, 'message' => $message];
    if ($data !== null) $out['data'] = $data;
    echo json_encode($out, JSON_UNESCAPED_UNICODE);
    exit;
}

function ensureIssueReportsTable() {
    global $conx;
    $conx->query("CREATE TABLE IF NOT EXISTS issue_reports (
        id INT UNSIGNED NOT NULL AUTO_INCREMENT,
        technician_id VARCHAR(64) NOT NULL,
        issue_type VARCHAR(120) NOT NULL,
        description TEXT NOT NULL,
        location VARCHAR(512) NOT NULL DEFAULT '',
        attachments TEXT NULL,
        status VARCHAR(32) NOT NULL DEFAULT 'new',
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (id),
        KEY idx_tech (technician_id),
        KEY idx_status (status),
        KEY idx_created (created_at)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
}

function notifyManagersAboutIssue($title, $content) {
    global $conx;
    $date = date('Y-m-d');
    $time = date('h:i A');
    $titleEsc = reportIssueSanitize($title);
    $contentEsc = reportIssueSanitize($content);

    $uids = [];
    $players = [];

    // App managers (cust_app.a29 = 1)
    $q1 = $conx->query("SELECT a3, a7 FROM cust_app WHERE a29 = '1'");
    if ($q1) {
        while ($row = mysqli_fetch_assoc($q1)) {
            $uid = trim((string)($row['a3'] ?? ''));
            $sub = trim((string)($row['a7'] ?? ''));
            if ($uid !== '') $uids[$uid] = true;
            if ($sub !== '' && $sub !== 'null') $players[$sub] = true;
        }
    }

    // ERP users flagged as mobile admin
    $q2 = $conx->query("SELECT a7 FROM users WHERE a29 = '1' AND a7 IS NOT NULL AND a7 != '' AND a7 != 'null'");
    if ($q2) {
        while ($row = mysqli_fetch_assoc($q2)) {
            $sub = trim((string)($row['a7'] ?? ''));
            if ($sub !== '') $players[$sub] = true;
        }
    }

    foreach (array_keys($uids) as $uid) {
        $uidEsc = reportIssueSanitize($uid);
        $conx->query(
            "INSERT INTO notifications_center(title, content, uid, date, time)
             VALUES('$titleEsc', '$contentEsc', '$uidEsc', '$date', '$time')"
        );
    }

    $onesignalPath = __DIR__ . '/../erp2026/xtras/Onesignalnotification.php';
    if (!empty($players) && file_exists($onesignalPath)) {
        include_once($onesignalPath);
        if (class_exists('OneSignalNotification')) {
            $onesignal = new OneSignalNotification();
            foreach (array_keys($players) as $sub) {
                try {
                    $onesignal->sendToUser($sub, $title, $content);
                } catch (Throwable $e) {
                    // keep report saved even if push fails
                }
            }
        }
    }
}

/**
 * Same Telegram bot + internal group used by Complaints / Quotation / Contract flows.
 * Failures must never break the HTTP response.
 */
function sendIssueReportTelegram(array $payload) {
    $botToken = '8499367531:AAEnMG1yvNeAIanEgCbyYGlXWuYWImeTMyI';
    $chatId = '-1003877690157';

    $issueType = (string)($payload['issue_type'] ?? '');
    $techName = (string)($payload['technician_name'] ?? 'فني');
    $techId = (string)($payload['technician_id'] ?? '');
    $location = (string)($payload['location'] ?? '');
    $description = (string)($payload['description'] ?? '');
    $attachments = isset($payload['attachments']) && is_array($payload['attachments'])
        ? $payload['attachments']
        : [];
    $reportId = (int)($payload['report_id'] ?? 0);

    $shortDesc = function_exists('mb_substr')
        ? mb_substr($description, 0, 180)
        : substr($description, 0, 180);
    if (function_exists('mb_strlen')
        ? mb_strlen($description) > 180
        : strlen($description) > 180) {
        $shortDesc .= '…';
    }

    $when = date('d/m/Y h:i A');
    $attachCount = count($attachments);
    $attachNote = $attachCount > 0 ? ("يوجد {$attachCount} مرفق/مرفقات") : 'بدون مرفقات';

    $text = "🚨 *بلاغ مشكلة جديد*\n\n"
        . "🧾 *رقم البلاغ:* #{$reportId}\n"
        . "📂 *نوع البلاغ:* {$issueType}\n"
        . "👤 *اسم الفني:* {$techName}"
        . ($techId !== '' ? " (`{$techId}`)" : '') . "\n"
        . "📍 *الموقع:* {$location}\n"
        . "💬 *الوصف:*\n{$shortDesc}\n"
        . "📎 *المرفقات:* {$attachNote}\n"
        . "━━━━━━━━━━━━━━\n"
        . "🕐 {$when}";

    $firstImage = null;
    foreach ($attachments as $url) {
        $u = trim((string)$url);
        if ($u === '') continue;
        $lower = strtolower(parse_url($u, PHP_URL_PATH) ?: $u);
        if (preg_match('/\.(jpe?g|png|webp|gif)$/', $lower)) {
            $firstImage = $u;
            break;
        }
    }

    try {
        if ($firstImage) {
            $endpoint = "https://api.telegram.org/bot{$botToken}/sendPhoto";
            $post = [
                'chat_id' => $chatId,
                'photo' => $firstImage,
                'caption' => $text,
                'parse_mode' => 'Markdown',
            ];
        } else {
            $endpoint = "https://api.telegram.org/bot{$botToken}/sendMessage";
            $post = [
                'chat_id' => $chatId,
                'text' => $text,
                'parse_mode' => 'Markdown',
            ];
        }

        $ch = curl_init($endpoint);
        curl_setopt_array($ch, [
            CURLOPT_POST => true,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_CONNECTTIMEOUT => 4,
            CURLOPT_TIMEOUT => 8,
            CURLOPT_HTTPHEADER => ['Content-Type: application/json'],
            CURLOPT_POSTFIELDS => json_encode($post, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES),
        ]);
        $resp = curl_exec($ch);
        $err = curl_error($ch);
        curl_close($ch);
        if ($err) {
            error_log('issue_reports telegram curl: ' . $err);
            return;
        }
        $decoded = json_decode((string)$resp, true);
        if (!is_array($decoded) || empty($decoded['ok'])) {
            // Retry as plain text if Markdown parse failed
            $plain = str_replace(['*', '`'], '', $text);
            $ch2 = curl_init("https://api.telegram.org/bot{$botToken}/sendMessage");
            curl_setopt_array($ch2, [
                CURLOPT_POST => true,
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_CONNECTTIMEOUT => 4,
                CURLOPT_TIMEOUT => 8,
                CURLOPT_HTTPHEADER => ['Content-Type: application/json'],
                CURLOPT_POSTFIELDS => json_encode([
                    'chat_id' => $chatId,
                    'text' => $plain,
                ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES),
            ]);
            curl_exec($ch2);
            curl_close($ch2);
        }
    } catch (Throwable $e) {
        error_log('issue_reports telegram: ' . $e->getMessage());
    }
}

ensureIssueReportsTable();

switch ($action) {
    case 'getPresignedIssueAttachmentUrl': {
        $uid = reportIssueSanitize($input['technician_id'] ?? ($input['uid'] ?? ($input['userId'] ?? '')));
        if ($uid === '') {
            reportIssueRespond(false, 'معرّف الفني مطلوب');
        }
        $extRaw = isset($input['ext']) ? (string)$input['ext'] : 'jpg';
        $ext = strtolower(preg_replace('/[^a-z0-9]/i', '', $extRaw));
        if ($ext === '') $ext = 'jpg';

        $index = intval($input['index'] ?? 1);
        if ($index <= 0) $index = 1;
        $ts = isset($input['ts']) ? reportIssueSanitize($input['ts']) : (string)round(microtime(true) * 1000);

        $mimeMap = [
            'jpg' => 'image/jpeg',
            'jpeg' => 'image/jpeg',
            'png' => 'image/png',
            'webp' => 'image/webp',
            'gif' => 'image/gif',
            'mp4' => 'video/mp4',
            'mov' => 'video/quicktime',
            'm4v' => 'video/x-m4v',
            'webm' => 'video/webm',
        ];
        $contentType = isset($input['contentType']) ? (string)$input['contentType'] : '';
        if ($contentType === '' || !isset($mimeMap[$ext])) {
            $contentType = $mimeMap[$ext] ?? 'application/octet-stream';
        }

        $s3 = S3Storage::getInstance();
        $key = "Mobile_App/IssueReports/{$uid}/{$ts}_{$index}.{$ext}";
        $url = $s3->presignedUploadUrl($key, $contentType);
        $publicUrl = $s3->url($key);
        reportIssueRespond(true, 'OK', [
            'url' => $url,
            'key' => $key,
            'publicUrl' => $publicUrl,
            'contentType' => $contentType,
        ]);
        break;
    }

    case 'getMyIssueReports': {
        $technicianIdRaw = trim((string)($input['technician_id'] ?? ($input['uid'] ?? ($input['userId'] ?? ''))));
        $technicianId = reportIssueSanitize($technicianIdRaw);
        if ($technicianId === '') {
            reportIssueRespond(false, 'معرّف الفني مطلوب');
        }
        $list = [];
        $res = $conx->query(
            "SELECT id, technician_id, issue_type, description, location, attachments, status, created_at
             FROM issue_reports
             WHERE technician_id = '$technicianId'
             ORDER BY id DESC"
        );
        if ($res) {
            while ($row = mysqli_fetch_assoc($res)) {
                $list[] = $row;
            }
        }
        reportIssueRespond(true, '', $list);
        break;
    }

    case 'reportIssue': {
        $technicianIdRaw = trim((string)($input['technician_id'] ?? ($input['uid'] ?? ($input['userId'] ?? ''))));
        $issueTypeRaw = trim((string)($input['issue_type'] ?? ''));
        $descriptionRaw = trim((string)($input['description'] ?? ''));
        $locationRaw = trim((string)($input['location'] ?? ''));

        $technicianId = reportIssueSanitize($technicianIdRaw);
        $issueType = reportIssueSanitize($issueTypeRaw);
        $description = reportIssueSanitize($descriptionRaw);
        $location = reportIssueSanitize($locationRaw);

        $allowedTypes = [
            'عطل فني غير مخطط',
            'مشكلة أمان/خطورة بالموقع',
            'نقص أدوات أو معدات',
            'مشكلة في التطبيق (Bug)',
        ];
        if ($technicianId === '') {
            reportIssueRespond(false, 'معرّف الفني مطلوب');
        }
        if ($issueType === '' || !in_array($issueTypeRaw, $allowedTypes, true)) {
            reportIssueRespond(false, 'نوع البلاغ غير صالح');
        }
        if ($description === '') {
            reportIssueRespond(false, 'وصف المشكلة مطلوب');
        }
        if ($location === '') {
            reportIssueRespond(false, 'الموقع مطلوب');
        }

        $attachments = [];
        if (isset($input['attachments']) && is_array($input['attachments'])) {
            foreach ($input['attachments'] as $att) {
                $u = trim((string)$att);
                if ($u !== '' && preg_match('#^https?://#i', $u)) {
                    $attachments[] = $u;
                }
            }
        }
        $attachmentsJson = reportIssueSanitize(json_encode($attachments, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES));

        $ok = $conx->query(
            "INSERT INTO issue_reports (technician_id, issue_type, description, location, attachments, status)
             VALUES ('$technicianId', '$issueType', '$description', '$location', '$attachmentsJson', 'new')"
        );
        if (!$ok) {
            reportIssueRespond(false, 'فشل حفظ البلاغ');
        }
        $reportId = (int)$conx->insert_id;

        $notifyTitle = 'بلاغ مشكلة جديد';
        $shortDesc = function_exists('mb_substr')
            ? mb_substr($descriptionRaw, 0, 80)
            : substr($descriptionRaw, 0, 80);
        $notifyBody = $issueTypeRaw . ' — ' . $shortDesc;
        notifyManagersAboutIssue($notifyTitle, $notifyBody);

        // Telegram (internal group) — never fail the API response
        $techName = 'فني';
        try {
            $qName = $conx->query(
                "SELECT a1 FROM cust_app WHERE a3 = '$technicianId' LIMIT 1"
            );
            if ($qName && ($rowName = mysqli_fetch_assoc($qName))) {
                $n = trim((string)($rowName['a1'] ?? ''));
                if ($n !== '') $techName = $n;
            }
        } catch (Throwable $e) {}

        try {
            sendIssueReportTelegram([
                'report_id' => $reportId,
                'technician_id' => $technicianIdRaw,
                'technician_name' => $techName,
                'issue_type' => $issueTypeRaw,
                'location' => $locationRaw,
                'description' => $descriptionRaw,
                'attachments' => $attachments,
            ]);
        } catch (Throwable $e) {
            error_log('issue_reports telegram wrapper: ' . $e->getMessage());
        }

        reportIssueRespond(true, 'تم إرسال البلاغ بنجاح', [
            'id' => $reportId,
            'status' => 'new',
        ]);
        break;
    }

    default:
        reportIssueRespond(false, 'إجراء غير معروف');
}
