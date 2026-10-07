<?
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);
require_once 'vendor/autoload.php';

$mpdf = new \Mpdf\Mpdf([
    'mode'          => 'ar',
    'format'        => 'A4',
    'tempDir' => sys_get_temp_dir(),
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
    'margin_top'    => 40,
    'margin_bottom' => 25,
    'margin_left'   => 10,
    'margin_right'  => 10,
    'margin_header' => 5,
    'margin_footer' => 5,
]);

$mpdf->SetDirectionality('rtl');
$mpdf->SetWatermarkImage('img/logo.png', 0.1, [120, 120]);
$mpdf->showWatermarkImage = true;
// الهيدر والفوتر
$header = '<table width="100%" style=" padding-bottom:8px;"><tr><td><img src="img/header.png" height="100"/></td></tr></table>';
$footer = '<div style="border-top:2px solid #CE2020; text-align:center; font-family:cairo; font-size:9px; padding-top:5px; direction:rtl;">+974 4006 4365 | sales@deltatechnologys.com<br>Salwa Road, Building 32, Doha - Qatar</div>';

$mpdf->SetHTMLHeader($header);
$mpdf->SetHTMLFooter($footer);

// ← هنا بتجيب المحتوى من ملف خارجي
ob_start();
include('content.php');
$html = ob_get_clean();

$mpdf->WriteHTML($html);

// صور المصاعد في آخر عرض السعر فقط (ktype=2)
$ktype = $_GET['ktype'] ?? '';
$batchId = $_GET['batchId'] ?? '';
if ($ktype == '2' && $batchId !== '') {
    include(__DIR__ . '/../xtras/config.php');
    $bookRow = $conx->query("SELECT orderId FROM bookings WHERE id = '" . mysqli_real_escape_string($conx, $batchId) . "'")->fetch_assoc();
    $oid = $bookRow['orderId'] ?? '';
    if ($oid !== '') {
        $orderArr = [];
        $orderSql = $conx->query("SELECT itmid FROM orders WHERE oid = '" . mysqli_real_escape_string($conx, $oid) . "'");
        while ($rows = mysqli_fetch_assoc($orderSql)) {
            $orderArr[] = $rows;
        }
        if (!empty($orderArr)) {
            $mpdf->AddPage();
            $imagesHtml = '<div style="direction:rtl; font-family:cairo; text-align:center;">';
            $imagesHtml .= '<h3 style="margin-bottom:12px;">صور المصاعد المختارة</h3>';
            foreach ($orderArr as $img) {
                $itmid = htmlspecialchars($img['itmid']);
                $imagesHtml .= '<img src="https://daltaliftstech.s3.ap-south-1.amazonaws.com/Sys/items/' . $itmid . '/1.jpg" style="width:180mm; margin-bottom:10px;"/>';
                $imagesHtml .= '<br>';
            }
            $imagesHtml .= '</div>';
            $mpdf->WriteHTML($imagesHtml);
        }
    }
}

$mpdf->Output('contract.pdf', 'I');